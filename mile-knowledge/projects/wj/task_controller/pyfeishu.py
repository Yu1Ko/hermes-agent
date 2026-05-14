# -*- coding:utf-8 -*-
from urllib import parse

import requests
import json
import logging
import time
from PIL import Image
import pyscreenshot as ImageGrab
import os

from minio import Minio
from tidevice import Device
import urllib3,traceback
urllib3.disable_warnings()

from SubscriberClient import SubscriberClient

client = SubscriberClient()


file_type = {
    ".png": "image/png",
    ".jpg": "image/jpg"
}

try:
    JSONDecodeError = json.decoder.JSONDecodeError
except AttributeError:
    JSONDecodeError = ValueError


def is_not_null_and_blank_str(content):
    """
    非空字符串
    :param content: 字符串
    :return: 非空 - True，空 - False
    """
    if content and content.strip():
        return True
    else:
        return False

#默认机器人接口
webhook="https://xz.wps.cn/api/v1/webhook/send?key=2608b7d4999532a7896e836f0c1d622c"

class FeiShutalkChatbot(object):
    def __init__(self, webhook=webhook, secret=None, pc_slide=False, fail_notice=False):
        '''
        机器人初始化
        :param webhook: 协作群自定义机器人webhook地址
        :param secret: 机器人安全设置页面勾选“加签”时需要传入的密钥
        :param pc_slide: 消息链接打开方式，默认False为浏览器打开，设置为True时为PC端侧边栏打开
        :param fail_notice: 消息发送失败提醒，默认为False不提醒，开发者可以根据返回的消息发送结果自行判断和处理
        '''
        super(FeiShutalkChatbot, self).__init__()
        self.headers = {'Content-Type': 'application/json; charset=utf-8'}
        self.webhook = webhook
        self.secret = secret
        self.pc_slide = pc_slide
        self.fail_notice = fail_notice
    def send_text(self, *msg ):
        if len(msg)==1:
            self.Send_message(msg[0])
        if len(msg)==2:
            self.Send_at_user(msg[0],msg[1])
        elif len(msg)==3:
            self.send_hyperlink(msg[0],msg[1],msg[2])
        else:
            print("暂时不支持其他参数")
        print(msg)

    def send_card(self, Error_content, device_s, platform):
        """将多层连续的消息写成卡片的形式"""
        img = self.get_img_key(platform,device_s)
        msg = {
            "msgtype": "markdown",
            "markdown": {
                "text": f"# <font color='red'>【通知】{Error_content}</font>\n"
                        f"----  \n"
                        f"**报错信息：** {traceback.format_exc()}  \n"
                        f"[截图]({img})"
            }
        }

        return self.post(msg)

    def Send_message(self, msg):
        """
        消息类型为text类型
        :param msg: 消息内容
        :return: 返回消息发送结果
        """
        try:
            data = {"msgtype": "markdown", "markdown": {"text": ""}}
            if is_not_null_and_blank_str(msg):  # 传入msg非空
                data["markdown"]['text'] = msg
            else:
                logging.error("text类型，消息内容不能为空！")
                raise ValueError("text类型，消息内容不能为空！")

            logging.debug('text类型：%s' % data)
            return self.post(data)
        except Exception as e:
            print(e)

    def Send_at_user(self, msg, namelist=[]):
        """
        消息类型为text类型
        :param msg: 消息内容
        :namelist: 需要@的指定人 需要用户邮箱
        :return: 返回消息发送结果
        """
        try:
            data = {"msgtype": "markdown", "markdown": {"text": ""}}
            user_str = ""
            if is_not_null_and_blank_str(msg):  # 传入msg非空
                if len(namelist) > 0:
                    for u in namelist:
                        if u == "所有人":
                            user_str = user_str + f"<at user_id=\"-1\">所有人</at>"
                        else:
                            user_str = user_str + f"<at email=\"{u}\"></at>"
                    data["markdown"]['text'] = f"{user_str} {msg}"
            else:
                logging.error("text类型，消息内容不能为空！")
                raise ValueError("text类型，消息内容不能为空！")

            logging.debug('text类型：%s' % data)
            return self.post(data)
        except Exception as e:
            print(e)

    def send_hyperlink(self, name, urlneme, url):
        """
        消息类型为text类型
        :param msg: 消息内容
        :return: 返回消息发送结果
        """
        try:
            if not is_not_null_and_blank_str(url):  # 传入msg非空
                logging.error("text类型，消息内容不能为空！")
                raise ValueError("text类型，消息内容不能为空！")
            data = {"msgtype": "markdown", "markdown": {"text": f"{name} [{urlneme}]({url})"}}
            logging.debug('text类型：%s' % data)
            return self.post(data)
        except Exception as e:
            print(e)

    def post(self, msg):
        """消息发送到金山协助并返回结果"""
        result = requests.post(self.webhook, json=msg, headers={"Content-Type": "application/json"})
        return result

    def set_project_id(self,project_id):
        self.project_id = project_id

    def ret_img(self,device_os="PC",devices=""):
        devicesname=devices.split(":")[0].replace ('.','') if "10." in devices else devices
        img_name=f"stop_{devicesname}.jpg"
        if not os.path.exists(f"log_file/{img_name}"):
            with open(f"log_file/{img_name}", "w") as f:
                f.write("")
        try:
            if device_os=="PC":
                img = ImageGrab.grab()
                img.save(img_name)
                self.send_img(img_name)
            elif device_os=="ios":
                device=Device(devices)
                device.screenshot().convert('RGB').save(f"log_file/{img_name}")
                client.send_text_and_image(f"{self.project_id}异常图如下", f"log_file/{img_name}") #使用协作iqb平台发送图片
                self.send_img(f"log_file/{img_name}")
                # pass
            elif device_os=="android":
                os.popen(f"adb -s {devices} shell screencap -p /sdcard/{img_name}").read()
                os.popen(f"adb -s {devices} pull /sdcard/{img_name} log_file/{img_name}").readline()
                client.send_text_and_image(f"{self.project_id}异常图如下", f"log_file/{img_name}") #使用协作iqb平台发送图片
                self.send_img(f"log_file/{img_name}")
        except:
            self.send_text(f"截图失败_{traceback.format_exc()}")

    def get_img_key(self,devices,device_os):
        devicesname=devices.split(":")[0].replace ('.','') if "10." in devices else devices
        img_name=f"imgkey_{devicesname}.jpg"
        img_path=f"log_file/{img_name}"
        if not os.path.exists(img_path):
            with open(img_path, "w") as f:
                f.write("")
        try:
            if device_os=="PC":
                img = ImageGrab.grab()
                img.save(img_path)
                # self.send_img(img_name)
            elif device_os=="ios":
                device=Device(devices)
                device.screenshot().convert('RGB').save(img_path)
                # self.send_img(f"log_file/{img_name}")
                # pass
            elif device_os=="android":
                os.popen(f"adb -s {devices} shell screencap -p /sdcard/{img_name}").read()
                os.popen(f"adb -s {devices} pull /sdcard/{img_name} log_file/{img_name}").readline()

                # self.send_img(f"log_file/{img_name}")
            img = Image.open(img_path)
            img_width,img_height = img.size[:2]
            size = (int(img_width*0.5), int(img_height*0.5))
            img = img.resize(size ,Image.NEAREST)
            img = img.convert("RGB")
            img.save(img_path)
        except:
            self.send_text(f"截图失败_{traceback.format_exc()} ")
        image_key = self.upload_img_to_minio(img_path)
        return image_key

    def send_img(self, image_path):
        image_key = self.upload_img_to_minio(image_path)

        data = {"msgtype": "markdown",
                "markdown": {
                    "text" : f"[截图]({image_key})"
                }
                }
        return self.post(data)

    def upload_img_to_minio(self, img_path):
        """将图片上传到minio并返回图片路径"""
        img_name = os.path.split(img_path)[-1]
        # minioClient = Minio("10.11.81.196:9000", access_key="lin", secret_key="lin123$%^", secure=False)
        minioClient = Minio("10.11.144.160:9006", access_key="admin", secret_key="admin123", secure=False)

        content_type = "image/jpg"

        for type_name in list(file_type.keys()):
            if img_name.endswith(type_name):
                content_type = file_type[type_name]
                break

        minioClient.fput_object("pictures", img_name, img_path, content_type=content_type)
        # url = f"http://10.11.81.196:9000/pictures/{parse.quote(img_name)}"
        url = f"http://10.11.144.160:9006/pictures/{parse.quote(img_name)}"


        return url

