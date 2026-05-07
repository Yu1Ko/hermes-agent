import urllib3
from CaseCommon import *  # 基类
from BaseToolFunc import *  # 提供了常用的功能函数封装，建议使用里面的函数，可提前阅读了解有哪些功能

# 此脚本的作用：AUTO_WEB接入了flask-profiler,但主要是为了统计每个接口的访问次数，
# 没有访问的接口不会被显示在统计页面，为了让其能被统计，用此脚本每天访问一次所有接口。
class SendRequest(CaseCommon):
    def __init__(self):
        super().__init__()  # 父类初始化
        # self.HOST = "10.11.80.233"
        # self.PORT = 5003
        self.HOST = ""
        self.PORT = ""
        self.iHour = ""
        self.iMin = ""
        self.oUrlPath = {'jx3hd': {},
                         'jx3classic': {},
                         'jx3x3d': {},
                         'jxsj3': {},
                         'mecha': {},
                         'TGAME': {},
                         'navigatConfig': {},
                         'navigatTitle': {},
                         'getPerfeyBVTTableHead': {"appkey": "jxsj3", "sRouter": "BVTTable_contrast_not_warning"},
                         'getPerfeyeTableData': {"appkey": "jx3classic", "sRouter": "BVTTable_contrast",
                                                 "today": "2023-03-07",
                                                 "yesterday": "2023-03-06"},
                         'getPerfeyBVTLine_head': {"appkey": "jx3hd", "sRouter": "BVTLine_trend"},
                         'getPerfeyeAppkey': {},
                         'getPerfeyeBVTlinedata': {"appkey": "jx3hd", "sRouter": "BVTLine_trend", "today": "2023-03-06",
                                                   "yesterday": "2022-09-02"},
                         'getfileSvnLogtable': {},
                         'getListTestpoint': {"appkey": "jx3hd", "url": "getListTestpoint"},
                         'getPics': {"appkey": "jx3hd", "url": "getPics", "ver1": "2023-03-02", "ver2": "2023-03-03"},
                         'getShaderData': {"today": "2023-03-02", "yesterday": "2023-01-31"},
                         'getSvnShaderData': {"today": "2023-03-01", "yesterday": "2023-01-30"},
                         'getFileCommitTableData': {"today": "2023-03-03", "yesterday": "2023-02-01"},
                         'getBVTTableExcel': {"appkey": "jxsj3", "sRouter": "BVTTable_contrast", "today": "2023-03-03",
                                              "yesterday": "2023-03-02"},
                         'abyss': {},
                         'jx1pocket': {},
                         'getWorkingDayList': {},
                         'isWorkingDay': {"date": "2023-03-07"},
                         'setWorkingDay': {"date": "2023-03-07"},
                         'setHoliday': {"date": "2023-03-06"},
                         'getPerfeyeReportInfo': {"id": "6406cedba1dcf0cc72ffae89"},
                         'jxsjorigin': {},
                         'CancelWarningData': {"shaderName": "dce89abd-46e2-f1ca-0000-000000000000",
                                               "time": "2022-10-31"},
                         'WarningData': {"shaderName": "dce89abd-46e2-f1ca-0000-000000000000", "time": "2022-10-31"}
                         }

    def fnSendRequest(self):
        Res = urllib3.PoolManager()  # 线程池生成请求
        for sUrlPath, oArgs in self.oUrlPath.items():
            try:
                res = Res.request('GET', f'{self.HOST}:{self.PORT}/{sUrlPath}', fields=oArgs)
                self.log.info(f'{sUrlPath}请求成功')
            except Exception as e:
                self.log.error(f'{sUrlPath}请求失败')
                continue

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        self.HOST = dic_args["Host"]
        self.PORT = dic_args["Port"]
        self.iHour = dic_args["hour"]
        self.iMin = dic_args["min"]
        while True:
            try:
                now_time = datetime.datetime.today()
                iNow_hour = int(now_time.hour)
                iNow_Min = int(now_time.minute)
                if iNow_hour == self.iHour and iNow_Min == self.iMin:
                    self.fnSendRequest()
                    time.sleep(60)
                time.sleep(10)
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
                time.sleep(70)
                continue


if __name__ == "__main__":
    obj = SendRequest()
    obj.run_from_IQB()