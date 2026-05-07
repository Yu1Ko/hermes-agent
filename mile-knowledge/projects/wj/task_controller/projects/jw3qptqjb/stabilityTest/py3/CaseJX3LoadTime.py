# -*- coding: utf-8 -*-
from CaseJX3Client import *
import re
import pymongo

pattern = re.compile(r'(?P<threadId>\d+) (?P<strTime>\d{4}/\d{2}/\d{2}_\d{2}:\d{2}:\d{2},\d{3}) (?P<level>\S+) +(?P<model>\[\S+\]) (?P<strLog>.*)')

class CaseJX3LoadTime(CaseJX3Client):

    def __init__(self):
        super(CaseJX3LoadTime, self).__init__()
        self.dicStartupTime = {}
        self.dicStartupTime['1'] = None
        self.dicStartupTime['2'] = None

    def connectMongo(self):
        dbName = "performance_analyse"
        colName = "loadtime_data"
        host = "10.11.80.122"
        port = 27017
        MongoClient = pymongo.MongoClient(host=host, port=port)  # 连接数据库
        db = MongoClient[dbName]
        self.collections = db[colName]

    def createDataAndUpdate(self, scene):
        pass
        loadtime_data = {}

        machine_info = createMachineInfo(None)
        loadtime_data['machine_info'] = machine_info

        custom_info = {}
        custom_info['appkey'] = self.AppKey
        custom_info['videoname'] = self.tagVideoCard
        custom_info['scene'] = scene
        custom_info['gamedisktype'] = ''
        loadtime_data['custom_info'] = custom_info
        loadtime_data['log1'] = self.dicStartupTime['1']
        loadtime_data['log2'] = self.dicStartupTime['2']

        dicStartupTime = self.dicStartupTime
        datetime2 = time.strptime(dicStartupTime['2']['strTime'], '%Y/%m/%d_%H:%M:%S,%f')
        datetime1 = time.strptime(dicStartupTime['1']['strTime'], '%Y/%m/%d_%H:%M:%S,%f')
        # print time.mktime(datetime2) - time.mktime(datetime1)
        loadtime_data['cost_time'] = int(time.mktime(datetime2) - time.mktime(datetime1))
        x = self.collections.update_one({'machine_info.DeviceIp':machine_info['DeviceIp'],
                                     'log1.strTime':self.dicStartupTime['1']['strTime']},
                                    {'$set' : loadtime_data}, upsert=True)
        # print x

    def recordFileAlreadyAnalyse(self, filename):
        temp = 'LoadTimeAlreadyAnalyse'
        if not os.path.exists(temp):
            os.makedirs(temp)
        filepath = os.path.join(temp, filename)
        with open(filepath, 'w') as f:
            pass

    def checkFileAlreadyAnalyse(self, filename):
        temp = 'LoadTimeAlreadyAnalyse'
        filepath = os.path.join(temp, filename)
        return os.path.exists(filepath)
        # return False

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)  # 处理传进来的参数
        self.setClientPath(dic_args['clientType'])  # 指定客户端位置
        self.loadDataFromLocalConfig(dic_args)
        self.connectMongo()
        dicStartupTime = self.dicStartupTime
        logPath = self.CLIENT_LOG_PATH
        if not os.path.exists(logPath):
            raise Exception('log folder not exist!')
        lastDaysNum = 30
        #遍历外层日期
        for n in range(lastDaysNum, -1, -1):
            szDate = date_get_szDayBefore(n).replace('-', '_')
            logFolder = os.path.join(logPath, szDate)
            if not os.path.exists(logFolder):
                continue
            for file in os.listdir(logFolder):
                # print file
                if self.checkFileAlreadyAnalyse(file):
                    continue
                filePath = os.path.join(logFolder, file)
                with open(filePath, 'rb') as f:
                    for line in f.readlines():
                        try:
                            line=str(line,encoding='gbk')
                        except:
                            line=str(line)
                        result = pattern.match(line)
                        if not result:
                            continue
                        dicLine = result.groupdict()
                        # 启动
                        if 'Build at' in dicLine['strLog']:
                            dicStartupTime['1'] = dicLine
                            dicStartupTime['2'] = None
                        if dicStartupTime['1'] and '[openini use time] LoginWaitServerList' in dicLine['strLog']:
                            dicStartupTime['2'] = dicLine
                        if dicStartupTime['1'] and dicStartupTime['2']:
                            # print dicStartupTime
                            # print '启动'
                            try:
                                self.createDataAndUpdate('启动')
                            except:
                                info = traceback.format_exc()
                                self.log.error(info)
                            dicStartupTime['1'] = dicStartupTime['2'] = None
                        #过图
                        if 'SCENE_BEGIN_LOAD' in dicLine['strLog']:
                            scene = dicLine['strLog'].split('\\')[-1]
                            dicStartupTime['1'] = dicLine
                            dicStartupTime['2'] = None
                        if dicStartupTime['1'] and 'LuaConfirmClientReady' in dicLine['strLog']:
                            dicStartupTime['2'] = dicLine
                        if dicStartupTime['1'] and dicStartupTime['2']:
                            # print scene
                            # print dicStartupTime
                            try:
                                self.createDataAndUpdate(scene)
                            except:
                                info = traceback.format_exc()
                                self.log.error(info)
                            dicStartupTime['1'] = dicStartupTime['2'] = None
                self.recordFileAlreadyAnalyse(file)





if __name__ == '__main__':
    obj_test = CaseJX3LoadTime()
    obj_test.run_from_IQB()