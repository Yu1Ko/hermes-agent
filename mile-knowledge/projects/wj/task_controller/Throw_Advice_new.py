import json
import traceback
from io import BytesIO
import requests
from PIL import Image

import ad_ios
import auto_rebot
import datetime
#import checkpoint
import time

from minio import Minio

json_data = {
            "header": {
                    "title": {
                        "tag": "text",
                        "content": {
                            "type": "plainText",
                            "text": "标题"
                        }
                    },
                    "subtitle": {
                        "tag": "text",
                        "content": {
                            "type": "plainText",
                            "text": "副标题"
                        }
                    },
                    "template": "red"
                },
            "elements": [
                {
                    "tag": "div",
                    "fields": [
                        {
                            "tag": "text",
                            "content": {
                                "type": "markdown",
                                "text": "**🗂️ 案例：**  \n'测试用例'"
                            }
                        },
                        {
                            "tag": "text",
                            "content": {
                                "type": "markdown",
                                "text": "**📋 版本：**  \n'测试用例'"
                            }
                        }
                    ],
                    "division": "middle"
                },
                {
                    "tag": "div",
                    "fields": [
                        {
                            "tag": "text",
                            "content": {
                                "type": "markdown",
                                "text": "**💻 设备：**  \n'测试用例'"
                            }
                        },
                        {
                            "tag": "text",
                            "content": {
                                "type": "markdown",
                                "text": "**👤 通知：**  \n'测试用例'"
                            }
                        }
                    ],
                    "division": "middle"
                },
                {
                    "tag": "text",
                    "content": {
                        "type": "markdown",
                        "text": "通知人信息"
                    }
                },
                {
                    "tag": "text",
                    "content": {
                        "type": "markdown",
                        "text": "报错信息"
                    }
                },
                {
                    "tag": "img",
                    "content": {
                        "pic_type": "image/jpg",
                        "store_key": "DD1AFB29YmV0YS9lYTliMjE4ZTNmNmM4MzJmZDlkNWNiNjc1MjliYzk0MTprczM6d29hLXN0YXRpYw==",
                        "store_key_sha1": "DD1AFB29YmV0YS9lYTliMjE4ZTNmNmM4MzJmZDlkNWNiNjc1MjliYzk0MTprczM6d29hLXN0YXRpYw=="
                    }
                },
                {
                    "tag": "text",
                    "content": {
                        "type": "markdown",
                        "text": "\n[跳转到异常数据 查看详情]('https://open-xz.wps.cn/admin/app/AK20230714VGCATY/tpl-card-editor/editor')"
                    }
                }
            ]
            }

def getCurrentDate():
    current_time = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")
    return current_time


class Throw_Advice(object):
    _instance = None

    def __new__(self, *args, **kw):
        if self._instance is None:
            self._instance = object.__new__(self, *args, **kw)
            self._instance.init_data()
        return self._instance

    def __init__(self):
        pass

    def init_data(self):
        print("初始化参数")
        self.project = "XX"
        self.device = "XX"
        self.device_name = "空"
        self.case_name = "未开始"
        self.bot = None
        self.taskrunid = None
        self.taskname = ""
        self.game_v = '0'
        self.account = ""
        self.format_exc = "" #获取消息卡片发送堆栈的信息

    def set_data(self, chat_id, project, device, device_name, taskrunid, taskname, game_v, platform,company_uid=""):
        self.project = project
        self.device = device
        self.device_name = device_name
        self.taskrunid = taskrunid
        self.taskname = taskname
        self.game_v = game_v
        self.platform = platform
        self.case_id = 0
        self.bot = auto_rebot.FeiShutalkChatbot(chat_id)
        self.gameversion = ""
        self.company_uid = company_uid

    def set_casename(self, case_name ,caseid=0):
        self.case_name = case_name
        self.case_id = caseid

    def set_gameversion(self, gameversion):
        self.gameversion = gameversion

    def set_account(self,account):
        self.account = account



    def upload_image_minio(self, img_name,case_name,device_name):
        """上传图片
        img_name : 截图本地存放路径
        filename : 云端存放文件名：2023-11-16T16:06:13-密斯之眼6V6-RLT1060

        tm : 2023-11-16T16:06:13
        case_name : 密斯之眼6V6
        device_name : RLT1060

        """
        tm = time.strftime('%Y-%m-%dT%H:%M:%S', time.localtime())
        filename = f"{tm}-{case_name}-{device_name}.jpg"

        bucketName = "mechapictures"
        object_name = filename
        # encoded_url = urllib.parse.quote(object_name)

        minioClient = Minio("auto-minio.testplus.cn:443", access_key="admin", secret_key="minio753269", secure=True)
        if minioClient.bucket_exists(bucket_name=bucketName):
            minioClient.fput_object(bucketName, f"{object_name}", img_name, content_type="image/jpeg")
        else:
            minioClient.fput_object(bucketName, f"{object_name}", img_name, content_type="image/jpeg")
        #url = f"https://minio-cluster.testplus.cn/vtune-profiler-file/{encoded_url}"
        url = f"https://auto-minio.testplus.cn:443/mechapictures/{object_name}"
        return url

    def get_json_data(self, data, user):
        try:
            user_str = ""
            if type(user) == list:
                for u in user:
                    user_str += f"<at email=\"{u}\"></at>"
            else:
                user_str = f"<at email=\"{user}\"></at>"
            img_path = ad_ios.capture_img(self.platform, self.device)
            retdata = json_data
            url_text = f"📝 [跳转到自动化平台 查看详情](https://uauto2.testplus.cn/project/{self.project}/taskDetail?taskId={self.taskrunid})"
            data = data.replace('\n', '\n\n')
            retdata["header"]['title']["content"]["text"] = f"{self.project}手游--任务异常：{self.taskname}"
            retdata["header"]['subtitle']["content"]["text"] = getCurrentDate()
            retdata["elements"][0]["fields"][0]["content"]["text"] = f"**🗂️ 案例：**  \n{self.case_name}"
            retdata["elements"][0]["fields"][1]["content"]["text"] = f"**📋 版本：**  \n{self.gameversion}"
            retdata["elements"][1]["fields"][0]["content"]["text"] = f"**💻 设备：**  \n{self.device_name}-{self.device}"
            retdata["elements"][1]["fields"][1]["content"]["text"] = f"**👤 账号：**  \n{self.account}"
            retdata["elements"][2]["content"]["text"] = f"**👤 通知：** {user_str}"
            retdata["elements"][3]["content"]["text"] = data
            store_key, store_key_sha1 = self.bot.send_img(img_path,False) #实时截取第一张
            retdata["elements"][4]["content"]["store_key"] = store_key
            retdata["elements"][4]["content"]["store_key_sha1"] = store_key_sha1
            retdata["elements"][5]["content"]["text"] = url_text
            # 在发送错误通知的时候同步一份到自动化平台 checkpoint
            '''
            try:
                # img_path = ad_ios.capture_img(self.platform, self.device)
                url = self.upload_image_minio(img_path, self.case_name, self.device_name)
                checkpoint.upload_checkpoint("任务异常", url, data)
            except:
                traceback.print_exc()'''
            return retdata
        except Exception as e:
            print("预警发送失败", e)
            print(traceback.format_exc())

    def send_text(self,msg,users=None):
        # atuser=self.bot.get_open_id(users,"interactive")
        if self.bot !=None:
            data=self.get_json_data(msg,users)
            resp=self.bot.Send_message(data)
            print(resp)
        else:
            print("飞书模块未实例化")

    def get_screenshots(self,): #调用api接口获取图片链接地址
        response = requests.get(f"https://automation-api.testplus.cn/api/device/screenshots", params={
            "deviceId": self.device_id,
            "count": 3,   #默认3张，iqb机器人最多只能轮播5张
        }, timeout=(10, 15))
        ret_url = json.loads(response.content)['data']
        screenshots_dict=[]
        for url in ret_url:
            print(url)
            store_key, store_key_sha1 = self.get_img_key(url)
            screenshots_dict.append({'store_key':store_key,'store_key_sha1':store_key_sha1})
        return screenshots_dict

    def send_msg_card(self, data,user="",chatid=None):
        """
        :param card_content: 卡片内容，详情看文档[https://open-xz.wps.cn/pages/develop-guide/card/structure/]
            - 消息卡片搭建工具:[https://open-xz.wps.cn/admin/app/AK20230714VGCATY/api-send]
            - card_content是搭建工具 的json内容
        """
        if not chatid:
            chatid = self.bot.chatid
        print("进入发送卡片")
        self.format_exc = data
        retdata = self.get_json_data(data, user)
        token = self.bot.get_company_token()
        url1 = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        body = {
            "to_users": {
                "company_id":"",
                "company_uids": []
            },
            "to_chats": chatid,
            "msg_type": 23,
            "app_id": "AK20231113NQYOPI",
            "content": {
                "type": 23,
                "content": retdata
            }
        }
        if self.company_uid:
            body["to_users"]["company_id"] = "dEZEXDnMDE"
            body["to_users"]["company_uids"] = [self.company_uid]
        self.bot._request("POST", self.bot.openapi_host, url1, body, None, None)

    def get_img_key(self, imgsource: str):
        try:
            print(imgsource)
            if imgsource.startswith("http"):
                # 根据链接下载图片，并转换为opencv格式
                img = self.getImageByUrl(imgsource).convert("RGB")
                img.save("compare.jpg")
                store_key, store_key_sha1 = self.bot.upload_image("compare.jpg")
            else:
                store_key, store_key_sha1 = self.bot.upload_image(imgsource)
            print(store_key, store_key_sha1)
            return store_key, store_key_sha1
        except:
            print(f"上传图片失败_{traceback.format_exc()} ")

    def getImageByUrl(self, url):
        # 根据图片url 获取图片对象
        html = requests.get(url, verify=False, timeout=(30, 30))
        image = Image.open(BytesIO(html.content))
        return image


if __name__ == '__main__':
    Throw_Advice().set_data(eval('[19982294]'), 'jxsjorigin', 'FMR0224122000428', 'FMR0224122000428',
                            '4562', '测试', '0.0.1', 'harmonyOS')
    Throw_Advice().set_casename('测试')
    Throw_Advice().set_account('测试')  # 添加账号信息
    Throw_Advice().send_msg_card('测试', '')


