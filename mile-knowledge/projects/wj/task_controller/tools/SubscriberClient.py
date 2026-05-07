# ********************************
# DESCRIPTION: python 订阅api
# version: 1.1
# date: 2024.01.09
# ********************************
import json
import socket
import threading
import struct
import base64


class SubscriberClient:
    """
    订阅客户端
    """

    def __init__(self, server_ip: str = "iqb.testplus.cn", server_port: int = 12501):
        """
        初始化客户端

        :param server_ip: 服务端运行IP
        :param server_port: 服务端运行端口
        """
        self.ipv4 = server_ip
        self.port = server_port

    def _msg_content_inspect(self, msg: dict):
        """
        检查消息内容格式
            - 不符合要求时，抛出异常
        :param msg: 消息内容
        """
        if 'msg_type' not in msg or 'content' not in msg:
            raise Exception("消息格式错误，必须包含msg_type和content字段")
        pass

    def _send(self, msg: dict):
        """
        发送消息到服务端

        :param msg: 字典类型，固定两个字段
            - msg_type: 消息类型，int类型 or str类型，当为int类型时，则默认自定义使用官网的消息类型，服务端不会对msg内容做任何处理
            如果是str类型，则服务端会根据规定的类型做不同的处理
            - content: 消息内容，不同消息类型有不同格式，详情看文档 [https://open-xz.wps.cn/pages/server/msg-and-group/sendmsgV2/#243d2a90]
        :return:
        """
        self._msg_content_inspect(msg)
        server_address = (self.ipv4, self.port)
        message = json.dumps(msg).encode('utf-8')
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        def _thread_send():
            """
            发送数据

            [WinError 10061]异常： 连接被拒绝，服务端可能已被关闭或此客户端已被加入黑名单,请注意发送频率
            """
            # 连接到服务器
            client_socket.connect(server_address)

            # 发送数据长度
            msg_length = len(message)
            client_socket.send(struct.pack('i', msg_length))

            # 发送数据
            total_sent = 0
            while total_sent < msg_length:
                sent = client_socket.send(message[total_sent:])
                if sent == 0:
                    raise RuntimeError("socket connection broken")
                total_sent += sent
            print("Data sent successfully.")
            client_socket.close()

        thread1 = threading.Thread(target=_thread_send, daemon=True)
        thread1.start()
        thread1.join()

    def send_text_and_image(self, text: str, image_path: str = None, image_base64: str = None):
        """
        发送图文混排消息

        :param text: 文字消息
        :param image_path: 本地图片路径
        :param image_base64: 图片base64
        """
        send_data = {
            "msg_type": "text_image",
            "content": {
                "text": text
            }
        }
        if image_path:
            with open(image_path, 'rb')as f:
                image_binary = f.read()
                image_base64 = base64.b64encode(image_binary).decode('utf-8')
        if not image_base64:
            raise ValueError("image_base64 和 image_path 必须提供其中一个")
        send_data['content']['image_base64'] = image_base64
        self._send(send_data)

    def send_text(self, text):
        """
        发送纯文本消息

        :param text: 文本消息
        """
        self.send_custom_content(1, {
            "type": 1,
            "body": text
        })
        pass

    def send_msg_card(self, card_content):
        """
        发送消息卡片

        :param card_content: 卡片内容，详情看文档[https://open-xz.wps.cn/pages/develop-guide/card/structure/]
            - 消息卡片搭建工具:[https://open-xz.wps.cn/admin/app/AK20230714VGCATY/api-send]
            - card_content是搭建工具 的json内容
        """
        send_msg = {
            "msg_type": 23,
            "content": {
                "type": 23,
                "content": card_content
            }
        }
        self._msg_content_inspect(send_msg)
        self._send(send_msg)
        pass

    def send_custom_content(self, msg_type: int, msg_content: dict):
        """
        发送自定义消息

        :param msg_type: 消息类型，此处只能是协作规定的消息类型 - [https://open-xz.wps.cn/pages/server/msg-and-group/sendmsgV2/#243d2a90]
        :param msg_content: 消息内容，也要符合规定类型的格式
        """
        _msg_types = [1, 2, 12, 13, 18, 19, 20, 23]  # 官网消息类型
        if msg_type not in _msg_types:
            raise Exception(f"未知消息类型:{msg_type}")
        if type(msg_content) != dict:
            raise Exception(f"消息内容只能是字典:{msg_content}")

        send_msg = {
            "msg_type": msg_type,
            "content": msg_content
        }
        self._send(send_msg)


if __name__ == '__main__':
    client = SubscriberClient()
    # client.send_text("Hello World")
    client.send_text_and_image("剑侠世界4","img.png")
