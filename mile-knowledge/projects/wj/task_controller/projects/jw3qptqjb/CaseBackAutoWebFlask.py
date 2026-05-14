# coding=utf-8
from CaseCommon import *
from BaseToolFunc import *
# import AUTO_WEB_FLASK.flask_data_monitor
from AUTO_WEB_FLASK import flask_data_monitor



class CaseBackAutoWebFlask(CaseCommon): #用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类

    def __init__(self):
        super().__init__() #父类初始化

    def run_local(self, dic_args):  #用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        try:
            flask_data_monitor.main()
        except Exception as e:
            info = traceback.format_exc()
            logging.error(info)

if __name__ == '__main__':
    obj = CaseBackAutoWebFlask()
    obj.run_local({})


