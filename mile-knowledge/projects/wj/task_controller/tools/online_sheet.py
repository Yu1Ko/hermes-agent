import base64
import json
import os
from datetime import datetime
import requests


class LightTable:
    def __init__(self, sheet_name, file_share_link):
        self.sheet_name = sheet_name
        self.file_share_link = file_share_link
        self.HOST = "http://iqb.testplus.cn:5089"
        self.add_wps_sheet()  # 优先判断有没有表格，没有就添加

    def get_wps_table(self):
        api = "/api_online_file/get_wps_table"
        body = {
            "file_name": "",
            "group_name": "",
            "sheet_name": self.sheet_name,
            "file_share_link": self.file_share_link,
        }
        header = {
            "Content-Type": "application/json"
        }
        res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header)
        print(res.json())  # 返回数组字典格式：[{'名称':"111"}]

    def get_wps_sheet(self):
        api = "/api_online_file/get_wps_sheet"
        body = {
            "file_name": "",
            "group_name": "",
            "file_share_link": self.file_share_link,
            "table_col_info": False
        }
        header = {
            "Content-Type": "application/json"
        }
        res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header).json()
        for i in res:
            print(f"self.sheet_name -> {self.sheet_name},type:{type(i)},{i['name']},type:{type(i['name'])}")
            if self.sheet_name == i["name"]:
                return True
        return False

    def insert_wps_table(self, new_data):
        api = "/api_online_file/insert_wps_table"
        body = {
            "file_name": "",
            "group_name": "",
            "sheet_name": self.sheet_name,
            "file_share_link": self.file_share_link,
            "new_data": new_data
        }
        header = {
            "Content-Type": "application/json"
        }
        res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header)
        print(res.json())

    def upload_file_in_table(self, file_path, file_name, group_name):
        api = "/api_online_file/upload_file_in_table"
        file_data = base64.b64encode(open(file_path, 'rb').read()).decode('utf-8')
        body = {
            "file_name": file_name,
            "group_name": group_name,
            "filter_data": {"名称": "111"},
            "base64_data": file_data,
            "upload_file_name": os.path.basename(file_path),
            "col_name": "附件"
        }
        header = {
            "Content-Type": "application/json"
        }
        res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header)
        print(res.json())

    def delete_wps_table(self, filter_data):
        api = "/api_online_file/delete_wps_table_fast"
        body = {
            "sheet_name": self.sheet_name,
            "file_share_link": self.file_share_link,
            "filter_data": filter_data
        }
        header = {
            "Content-Type": "application/json"
        }
        res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header)
        print(res.json())

    def add_wps_sheet(self):
        if not self.get_wps_sheet():
            api = "/api_online_file/add_wps_sheet"
            body = {
                "file_name": "",
                "group_name": "",
                "sheet_name": self.sheet_name,
                "file_share_link": self.file_share_link,
                "fields": [
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '日期'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '客户端版本'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '平台'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '设备'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '案例'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': 'FPSTP90'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '内存峰值'},
                    {"type": "Url", 'displayText': "", 'name': '报告链接'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '报告时长'},
                    {"type": "MultiLineText", 'uniqueValue': False, 'name': '备注'},
                ]
            }
            header = {
                "Content-Type": "application/json"
            }
            res = requests.get(f"{self.HOST}{api}", data=json.dumps(body), headers=header)
            print(res.json())

    def perfeye_custom(self, taskid: str):
        """获取perfeye报告时长"""
        url = f"http://perfeye.console.testplus.cn/api/show/task/{taskid}"
        headers = {"Authorization": "Bearer mj6cltF&!L#yWX8k"}
        response = requests.post(url, headers=headers, timeout=(30, 15))
        rqp = json.loads(response.content.decode("utf-8"))["data"]
        nums = len(rqp["ImageList"])
        report_time = str(round(nums / 60, 2))
        TP90 = rqp["LabelInfo"]["All"]["LabelFPS"]["TP90"]
        PeakMemory = rqp["LabelInfo"]["All"]["LabelMemory"]["PeakMemory(MB)"]
        AppVersion = rqp["BaseInfo"]["AppVersion"]
        return report_time, TP90, PeakMemory, AppVersion

    def auto_insert(self, url, device_name, case_name, platform):
        taskid = url.split("/case/")[1].split("/")[0]
        report_time, TP90, PeakMemory, AppVersion = self.perfeye_custom(taskid)
        times = datetime.now().strftime('%Y/%m/%d %H:%M')
        new_data = [{"日期": times, "客户端版本": AppVersion, "平台":platform,"设备": device_name, "案例": case_name,
                     "FPSTP90": TP90, "内存峰值": PeakMemory, "报告链接": [{'address': url, 'displayText': '报告链接'}],
                     "报告时长": report_time, "备注": ""}]
        self.insert_wps_table(new_data)


if __name__ == '__main__':
    # res = sheet.add_wps_sheet()
    # sheet.get_wps_table()
    # sheet.get_wps_sheet()
    url = "https://perfeye.testplus.cn/case/680e815982d06029df149374/report?appKey=jxsj4"
    now = datetime.now().strftime('%Y%m%d')  # 20250428这种格式
    file_share_link = "https://365.kdocs.cn/l/csckPrs7nATf"
    light_table = LightTable(now, file_share_link)
    device_name = "i7-7700K-1080-省电"
    case_name = "热力图-大世界"
    platform = "PC"
    light_table.auto_insert(url,device_name,case_name,platform)






