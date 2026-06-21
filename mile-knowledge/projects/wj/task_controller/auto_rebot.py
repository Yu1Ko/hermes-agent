import hashlib
import json
import os
import traceback
import logging
import requests
import time
from PIL import ImageGrab
import urllib3,traceback
from tidevice import Device
urllib3.disable_warnings()
import datetime
from PIL import Image

try:
    JSONDecodeError = json.decoder.JSONDecodeError
except AttributeError:
    JSONDecodeError = ValueError

def getCurrentDate():
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return current_time

json_data = {
                "elements": [
                    {
                        "tag": "text",
                        "content": {
                            "type": "markdown",
                            "text": "**<font color='red'>【通知】测试内容</font>**"
                        }
                    },
                    {
                        "tag": "img",
                        "content": {
                            "pic_type": "image/jpg",
                            "store_key": "DD1AFB29YmV0YS9lYTliMjE4ZTNmNmM4MzJmZDlkNWNiNjc1MjliYzk0MTprczM6d29hLXN0YXRpYw==",
                            "store_key_sha1": "DD1AFB29YmV0YS9lYTliMjE4ZTNmNmM4MzJmZDlkNWNiNjc1MjliYzk0MTprczM6d29hLXN0YXRpYw=="
                        },
                    },
                ]
                }

send_text = ["任务开始","开始执行","基础采集","任务结束"]

def send_text_juege(msg):
    send_text = ["任务开始", "开始执行", "基础采集", "深度采集", "任务结束"]
    if any(text in msg for text in send_text):
        return True
    else:
        return False


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

class FeiShutalkChatbot(object):
    def __init__(self, chatid=[],start_user=""):
        self.app_id = "AK20231113NQYOPI"
        self.app_key = "75ee7b4fc0f5111db56fd667b14b71d4"
        self.company_id = "dEZEXDnMDE" #西山居企业id
        self.openapi_host = "https://openapi.wps.cn"
        self.chatid = chatid
        self.width = None
        self.height = None
        self.company_uid = self.get_user(start_user)


    def _sig(self,content_md5, url, date):     #X-Auth参数的核心方法
        sha1 = hashlib.sha1(self.app_key.lower().encode('utf-8'))
        sha1.update(content_md5.encode('utf-8'))
        sha1.update(url.encode('utf-8'))
        sha1.update("application/json".encode('utf-8'))
        sha1.update(date.encode('utf-8'))

        return "WPS-3:%s:%s" % (self.app_id, sha1.hexdigest())

    def _request(self,method, host, uri, body=None, cookie=None, headers=None):  #应用机器人发送请求函数 跟旧飞书post一样的作用
        requests.packages.urllib3.disable_warnings()

        if method == "PUT" or method == "POST" or method == "DELETE":
            body = json.dumps(body)

        if method == "PUT" or method == "POST" or method == "DELETE":
            content_md5 = hashlib.md5(body.encode('utf-8')).hexdigest()
        else:
            content_md5 = hashlib.md5("".encode('utf-8')).hexdigest()

        date = time.strftime("%a, %d %b %Y %H:%M:%S GMT", time.gmtime())
        # print date
        header = {"Content-type": "application/json"}
        header['X-Auth'] = self._sig(content_md5, uri, date)
        header['Date'] = date
        header['Content-Md5'] = content_md5

        if headers != None:
            header = {}
            for key, value in headers.items():
                header[key] = value

        url = "%s%s" % (host, uri)
        r = requests.request(method, url, data=body,headers=header, cookies=cookie, verify=False,timeout=30)

        print("[response]: status=[%d],URL=[%s],data=[%s]" % (r.status_code, url, r.text))

        return r.status_code, r.text

    def get_company_token(self): #获取token授权凭证
        url = "/oauthapi/v3/inner/company/token?app_id=%s" % (self.app_id)
        print("[request] url:", url)

        status, rsp = self._request("GET", self.openapi_host, url, None, None, None)
        rsp = json.loads(rsp)
        print(rsp)
        if rsp.__contains__('company_token'):
            return rsp["company_token"]
        else:
            print("no company-token found in response, authorized failed")
            #exit(-1)

    def send_text(self, *msg):
        print(msg)
        if len(msg)==1:
            self.Send_message(msg[0])
        if len(msg)==2:
            self.Send_at_user(msg[0],msg[1])
        elif len(msg)==3:
            self.send_hyperlink(msg[0],msg[1],msg[2])
        else:
            print("暂时不支持其他参数")


    def send_siliao(self,text,useID):
        try:
            token = self.get_company_token()
            messages_url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
            body = {
                "to_users": {
                    "company_id": "dEZEXDnMDE",
                    "company_uids": [self.get_user(useID)]
                },
                "msg_type": 1,
                "app_id": "AK20231113NQYOPI",
                "content": {
                    "type": 1,
                    "style": "markdown",
                    "body": f"【时间】{getCurrentDate()}  \n{text}"
                }
            }
            return self._request("POST", self.openapi_host, messages_url, body, None, None)
        except Exception as e:
                print(e)


    def Send_message(self, msg):
        """
        消息类型为text类型
        :param msg: 消息内容
        :return: 返回消息发送结果

        """
        try:
            token = self.get_company_token()
            url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
            body = {
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                  },
                "to_chats": self.chatid,
                "msg_type": 1,
                "app_id": "AK20231113NQYOPI",
                "content": {
                    "type": 1,
                    "body": ""
                }
            }
            if send_text_juege(msg):
                if self.company_uid:
                    body["to_users"]["company_id"] = self.company_id
                    body["to_users"]["company_uids"] = [self.company_uid]
            if is_not_null_and_blank_str(msg):  # 传入msg非空
                body["content"]['body'] = f"【时间】{getCurrentDate()}  \n{msg}"
            else:
                logging.error("text类型，消息内容不能为空！")
                raise ValueError("text类型，消息内容不能为空！")
            return self._request("POST", self.openapi_host, url, body, None, None)
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
            token = self.get_company_token()
            url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
            body = {
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                },
                "to_chats": self.chatid,
                "msg_type": 1,
                "app_id": "AK20231113NQYOPI",
                "content": {
                    "type": 1,
                    "style": "markdown",
                    "body": ""
                }
            }
            user_str = ""
            if is_not_null_and_blank_str(msg):  # 传入msg非空
                if len(namelist) > 0:
                    for u in namelist:
                        if u == "所有人":
                            user_str = user_str + f"<at user_id=\"-1\">所有人</at>"
                        else:
                            user_str = user_str + f"<at email=\"{u}\"></at>"
                    body["content"]['body'] = f"【时间】{getCurrentDate()}  \n{user_str} {msg}"
            else:
                logging.error("text类型，消息内容不能为空！")
                raise ValueError("text类型，消息内容不能为空！")
            if send_text_juege(msg):
                if self.company_uid:
                    body["to_users"]["company_id"] = self.company_id
                    body["to_users"]["company_uids"] = [self.company_uid]
            logging.debug('text类型：%s' % body)
            return self._request("POST", self.openapi_host, url, body, None, None)
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
            token = self.get_company_token()
            messages_url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
            body = {
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                },
                "to_chats": self.chatid,
                "msg_type": 1,
                "app_id": "AK20231113NQYOPI",
                "content": {
                    "type": 1,
                    "style": "markdown",
                    "body": f"【时间】{getCurrentDate()}  \n{name} [{urlneme}]({url})"
                }
            }
            if send_text_juege(name):
                if self.company_uid:
                    body["to_users"]["company_id"] = self.company_id
                    body["to_users"]["company_uids"] = [self.company_uid]
            logging.debug('text类型：%s' % body)
            return self._request("POST", self.openapi_host, messages_url, body, None, None)
        except Exception as e:
            print(e)

    def send_text_msg(self, detail, messageUrl=None, urlName=None, *user):
        """魔改发送，无需三个方法"""
        # 常用发送消息格式，用于发送：单文本、@用户、链接
        user_str = ""
        if len(user) > 0:
            for u in user[0]:
                user_str = user_str + f"<at email=\"{u}\"></at>"
        token = self.get_company_token()
        url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        body = {
            "to_users": {
                "company_id": "",
                "company_uids": []
            },
            "to_chats": self.chatid,
            "msg_type": 1,
            "app_id": "AK20231113NQYOPI",
            "content": {
                "type": 1,
                "style": "markdown",
                "body": f"【时间】{getCurrentDate()}  \n{user_str}{detail}"
            }
        }
        if send_text_juege(detail):
            if self.company_uid:
                body["to_users"]["company_id"] = self.company_id
                body["to_users"]["company_uids"] = [self.company_uid]
        if not messageUrl is None:
            body["content"]['body'] = body["content"]['body'] + f"[{urlName}]({messageUrl})"
        return self._request("POST", self.openapi_host, url, body, None, None)

    def ret_img(self,device_os="PC",devices="",fasong =True):
        print("进入发送图片")
        devicesname=devices.split(":")[0].replace ('.','') if "10." in devices else devices
        img_name=f"stop_{devicesname}.jpg"
        if device_os == "harmonyOS":
            img_name = f"stop_{devicesname}.jpeg"
        if not os.path.exists(f"log_file/{img_name}"):
            with open(f"log_file/{img_name}", "w") as f:
                f.write("")
        try:
            if device_os=="PC":
                img = ImageGrab.grab()
                img.save(img_name)
                return self.send_img(img_name,fasong)
            elif device_os=="ios":
                device=Device(devices)
                device.screenshot().convert('RGB').save(f"log_file/{img_name}")
                return self.send_img(f"log_file/{img_name}",fasong)
                # pass
            elif device_os=="android":
                os.popen(f"adb -s {devices} shell screencap -p /sdcard/{img_name}").read()
                os.popen(f"adb -s {devices} pull /sdcard/{img_name} log_file/{img_name}").readline()
                return self.send_img(f"log_file/{img_name}",fasong)
            elif device_os=="harmonyOS":
                os.popen(f"hdc -t {devices} shell snapshot_display -f /data/local/tmp/{img_name}").read()
                os.popen(f"hdc -t {devices} file recv /data/local/tmp/{img_name} log_file/{img_name}").readline()
                return self.send_img(f"log_file/{img_name}",fasong)
        except:
            self.send_text(f"截图失败_{traceback.format_exc()}")


    def get_upload_info(self): #获取图片上传信息
        token = self.get_company_token()
        url = f"/kopen/woa/api/v2/developer/mime/upload?company_token={token}&service_key={self.app_id}&type=image&size=10"
        status, rsp = self._request("GET", self.openapi_host, url, None, None, None)
        r = json.loads(rsp)
        print(r)
        return r
    def upload_image(self,image_path): #上传图片到平台，返回store_key,store_key_sha1 类似get_img_key方法
        # 获取授权信息
        upload_info = self.get_upload_info()
        # 二进制文件
        with open(image_path, 'rb') as file:
            image_data = file.read()
        response = requests.put(upload_info['url'], data=image_data, headers=upload_info['headers'])
        if response.status_code == 200:
            print('请求成功')
            print('响应内容:', response.headers)
        else:
            print('请求失败')
            print('错误码:', response.status_code, response.text)
        return upload_info['store_key'], upload_info['store_key_sha1']

    def send_img(self,image_path,fasong=True):
        store_key,store_key_sha1=self.upload_image(image_path)
        token = self.get_company_token()
        url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        if fasong:
            width = self.width if self.width else 1080
            height = self.height if self.height else 1107
            body={
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                },
                "to_chats":self.chatid,
                "msg_type": 13,
                "app_key": self.app_id,
                "content": {
                    "width": width,
                    "height": height,
                    "pic_type": "image/jpg",
                    "pic": store_key,
                    "store_key_sha1": store_key_sha1
              }
            }
            if self.company_uid:
                body["to_users"]["company_id"] = self.company_id
                body["to_users"]["company_uids"] = [self.company_uid]
            return self._request("POST", self.openapi_host,url,body,None,None)
        else:
            return store_key,store_key_sha1

    def send_text_img(self, content,image_path): #发送图文，支持一张图片+文字
        store_key,store_key_sha1=self.upload_image(image_path)
        token = self.get_company_token()
        url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        body = {
            "to_users": {
                "company_id": "",
                "company_uids": []
            },
            "to_chats": self.chatid,
            "msg_type": 18,
            "app_id": "AK20231113NQYOPI",
            "content": {
                "type": 18,
                "elements": [
                  {
                    "tag": "img",
                    "content": {
                      "pic_type": "image/jpg",
                      "store_key": store_key,
                      "store_key_sha1": store_key_sha1
                    }
                  },
                  {
                    "tag": "text",
                    "content": {
                      "type": "text",
                      "text": content
                    }
                  }
                ]
              }
        }
        if send_text_juege(content):
            if self.company_uid:
                body["to_users"]["company_id"] = self.company_id
                body["to_users"]["company_uids"] = [self.company_uid]
        self._request("POST", self.openapi_host, url, body, None, None)


    def send_msg_card(self,msg,device_os,devices):
        """ 发送消息卡片
        :param card_content: 卡片内容，详情看文档[https://open-xz.wps.cn/pages/develop-guide/card/structure/]
            - 消息卡片搭建工具:[https://open-xz.wps.cn/admin/app/AK20230714VGCATY/api-send]
            - card_content是搭建工具 的json内容
        """
        print("进入发送卡片")
        retdata = json_data
        store_key,store_key_sha1 = self.ret_img(device_os,devices,fasong=False)
        token = self.get_company_token()
        url1 = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        msg = msg.replace('\n', '\n\n')
        retdata["elements"][0]["content"]["text"] = f"【时间】{getCurrentDate()}  \n{msg}"
        retdata["elements"][1]["content"]["store_key"] = store_key
        retdata["elements"][1]["content"]["store_key_sha1"] = store_key_sha1
        body = {
            "to_users": {
                "company_id": "",
                "company_uids": []
            },
            "to_chats": self.chatid,
            "msg_type": 23,
            "app_id": "AK20231113NQYOPI",
            "content": {
                "type": 23,
                "content": retdata
            }
        }
        if send_text_juege(msg):
            if self.company_uid:
                body["to_users"]["company_id"] = self.company_id
                body["to_users"]["company_uids"] = [self.company_uid]
        self._request("POST", self.openapi_host, url1, body, None, None)

    def upload_info(self,upload_file_url,file_path):  # 获取文件上传信息
        status, rsp = self._request("GET", self.openapi_host, upload_file_url, None, None, None)
        upload_info = json.loads(rsp)
        # 二进制文件
        with open(file_path, 'rb') as file:
            file_data = file.read()
        response = requests.put(upload_info['url'], data=file_data, headers=upload_info['headers'])
        if response.status_code == 200:
            print('响应内容:', response.headers)
        else:
            print('错误码:', response.status_code, response.text)
        return upload_info['store_key'], upload_info['store_key_sha1']

    def send_file_img(self, file_type, file_path):
        file_types = {'image': '10', 'file': '30'}
        if file_type not in file_types:
            print(f"文件类型必须是file或者image,当前file_type是{file_type}")
            return False
        file_size = os.path.getsize(file_path)
        if file_size / (1024 * 1024) > float(file_types[file_type]):
            print(f"文件大小大于{file_types[file_type]}")
            return False
        token = self.get_company_token()
        upload_file_url = f"/kopen/woa/api/v2/developer/mime/upload?company_token={token}&service_key={self.app_id}&type={file_type}&size={file_types[file_type]}"
        store_key, store_key_sha1 = self.upload_info(upload_file_url, file_path)
        url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        body = None
        if file_type == "image":
            with Image.open(file_path) as img:
                width, height = img.size
            body = {
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                },
                "to_chats": self.chatid,
                "msg_type": 13,
                "app_key": self.app_id,
                "content": {
                    "width": width,
                    "height": height,
                    "pic_type": "image/jpg",
                    "pic": store_key,
                    "store_key_sha1": store_key_sha1
                }
            }
        elif file_type == "file":
            body = {
                "to_users": {
                    "company_id": "",
                    "company_uids": []
                },
                "to_chats": self.chatid,
                "msg_type": 12,
                "app_key": self.app_id,
                "content": {
                    "file_name": file_path,
                    "file_size": file_size,
                    "store_key": store_key,
                    "store_key_sha1": store_key_sha1
                }
            }
        if self.company_uid:
            body["to_users"]["company_id"] = self.company_id
            body["to_users"]["company_uids"] = [self.company_uid]
        return self._request("POST", self.openapi_host, url, body, None, None)

    def get_user(self, email: str = "wenjingchao@thewesthill.net"):  # 根据邮箱地址获取用户
        try:
            if '@' in email:
                token = self.get_company_token()
                url = f"/oauthapi/v3/company/company_user/byemail?company_token={token}&email={email}&status=active"
                code,res = self._request("GET", self.openapi_host, url, None, None, None)
                return json.loads(res)['company_uid']
        except:
            return False

    # 获取群聊id
    def get_chat_id(self,query_name):
        token = self.get_company_token()
        url = f"/kopen/woa/api/v2/developer/app/chats?company_token={token}&page=1&count=100"
        status, response = self._request("GET", self.openapi_host, url, None, None, None)
        chats = json.loads(response).get("chats")
        print(chats)
        #遍历获取有无重复的群聊名
        duplicate_names = {}
        for item in chats:
            if item['name'] in duplicate_names:
                duplicate_names[item['name']].append(item['chat_id'])
            else:
                duplicate_names[item['name']] = [item['chat_id']]
        print(duplicate_names)
        messages_url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
        for name, chat_ids in duplicate_names.items():
            if name == query_name:
                result = f"存在重复的，群聊【{query_name}】的id为【{chat_ids}】" if len(chat_ids) > 1 else f"没有重复的，群聊【{query_name}】的id为【{chat_ids}】"
                body = {
                    "to_chats": chat_ids,
                    "msg_type": 1,
                    "app_id": "AK20231113NQYOPI",
                    "content": {
                        "type": 1,
                        "body": result
                    }
                }
                return self._request("POST", self.openapi_host, messages_url, body, None, None)
    def Send_log_message(self,msg,Chat_id,Project_name,Task_id,Task_name):
        """
        消息类型为text类型
        :param msg: 消息内容
        :return: 返回消息发送结果

        """
        try:
            token = self.get_company_token()
            url = f"/kopen/woa/v2/dev/app/messages?company_token={token}"
            body = {
                "to_chats": Chat_id,
                "msg_type": 1,
                "app_id": "AK20231113NQYOPI",
                "content": {
                    "type": 1,
                    "style": "markdown",
                    "body": f"【时间】{getCurrentDate()}  "
                }
            }
            body["content"]['body'] = body["content"]['body']+f"\n[{Task_name}]({f'https://uauto2.testplus.cn/project/{Project_name}/taskDetail?taskId={Task_id}'})\n"+f'\n{msg}\n'

            return self._request("POST", self.openapi_host, url, body, None, None)

        except Exception as e:
            print(e)


if __name__ == '__main__':
    # rebot = AutoReboot()
    """测试群5064301  我的群5573418"""
    bot = FeiShutalkChatbot()
    print('test')
    id=bot.get_chat_id("新自动化平台通知群")
    print('test')
    print(id)
    #bot.Send_message('123')
    #bot.send_siliao('ss','liuzhu2@kingsoft.com',)

    #bot.send_text(f"设备处于锁屏状态,请尽快解锁屏幕",['wenjingchao@kingsoft.com'])
    # bot.send_text('123','测试','https://uauto2.testplus.cn/project/jxsj3/setting/MachineManage')
    #bot.send_msg_card('测试',"","")
    # bot.send_text_img('123','./compare.jpg')
    # rebot.send_text_img("测试","./compare.jpg")