import hashlib
import json
import requests
import time


class AutoReboot(object):
    def __init__(self,chatid): #可以一次性发送几个群聊，chatid是列表
        self.app_id = "AK20231113NQYOPI" #机器人id
        self.app_key = "75ee7b4fc0f5111db56fd667b14b71d4" #机器人密钥
        self.openapi_host = "https://openapi.wps.cn" #请求链接前缀
        self.chatid = chatid if chatid else [5064301] #群聊“协作通知”的id


    def _sig(self,content_md5, url, date):
        """
        X-Auth参数的核心方法，获取签名
        签名参数说明 https://open-xz.wps.cn/pages/server/start/explain/
        """
        sha1 = hashlib.sha1(self.app_key.lower().encode('utf-8'))
        sha1.update(content_md5.encode('utf-8'))
        sha1.update(url.encode('utf-8'))
        sha1.update("application/json".encode('utf-8'))
        sha1.update(date.encode('utf-8'))
        return "WPS-3:%s:%s" % (self.app_id, sha1.hexdigest())

    def _request(self,method, host, uri, body=None, cookie=None, headers=None):  #发送请求函数
        requests.packages.urllib3.disable_warnings()

        if method == "PUT" or method == "POST" or method == "DELETE":
            body = json.dumps(body)

        if method == "PUT" or method == "POST" or method == "DELETE":
            content_md5 = hashlib.md5(body.encode('utf-8')).hexdigest()
        else:
            content_md5 = hashlib.md5("".encode('utf-8')).hexdigest()

        date = time.strftime("%a, %d %b %Y %H:%M:%S GMT", time.gmtime())
        header = {"Content-type": "application/json"}
        header['X-Auth'] = self._sig(content_md5, uri, date)
        header['Date'] = date
        header['Content-Md5'] = content_md5

        if headers != None:
            header = {}
            for key, value in headers.items():
                header[key] = value

        url = "%s%s" % (host, uri)
        r = requests.request(method, url, data=body,headers=header, cookies=cookie, verify=False)

        print("[response]: status=[%d],URL=[%s],data=[%s]" % (r.status_code, url, r.text))
        # print("+++\n")

        return r.status_code, r.text

    def get_company_token(self): #获取token授权凭证
        url = "/oauthapi/v3/inner/company/token?app_id=%s" % (self.app_id)
        print("[request] url:", url, "\n")

        status, rsp = self._request("GET", self.openapi_host, url, None, None, None)
        rsp = json.loads(rsp)

        if rsp.__contains__('company_token'):
            return rsp["company_token"]
        else:
            print("no company-token found in response, authorized failed")
            exit(-1)


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

    def chat_member(self):
        """根据群聊id获取群聊成员"""
        ids_str = ''.join(str(x) for x in self.chatid)
        token = self.get_company_token()
        url = f"/kopen/woa/api/v1/developer/app/chats/{ids_str}/members?company_token={token}&offset=0&limit=50&state=0"
        status, response = self._request("GET", self.openapi_host, url, None, None, None)
        print(status, response)

    def chat_info(self):
        """根据群聊id获取群聊信息"""
        ids_str = ''.join(str(x) for x in self.chatid)
        token = self.get_company_token()
        url = f"/kopen/woa/api/v1/developer/app/chats/info/{ids_str}?company_token={token}"
        status, response = self._request("GET", self.openapi_host, url, None, None, None)
        print(status, response)

    def company_info(self):
        """企业id company_id  dEZEXDnMDE  name 西山居
        https://open-xz.wps.cn/pages/server/contacts/company/
        """
        token = self.get_company_token()
        url = f"/plus/v1/company?company_token={token}"
        status, response = self._request("GET", self.openapi_host, url, None, None, None)
        print(status, response)

    # def role_info_by_company(self):
    #     url = f"/plus/v1/company/company_users?company_token={self.token}&offset=0&limit=100"
    #     status, response = self._request("GET", self.openapi_host, url, None, None, None)
    #     print(status, response)


    # def role_id_by_email(self,email):
    #     """通过邮箱获取用户id，不知道为何暂时用不了"""
    #     url = f"/oauthapi/v3/company/company_user/byemail?company_token={self.token}&email={email}"
    #     status, response = self._request("GET", self.openapi_host, url, None, None, None)
    #     print(status, response)


if __name__ == '__main__':
    bot = AutoReboot("")
    bot.get_chat_id('温景超的群聊')
    # bot.chat_info()
    # bot.role_id_by_email('wenjingchao@kingsoft.com')