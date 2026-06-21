# coding=utf-8
from CaseCommon import *
from BaseToolFunc import *
import pymongo
import urllib
import urllib.request as urllib2

requests_ip = u'http://perfeye.console.testplus.cn'  # perfeye_ip 正式环境
requests_flask_ip = 'http://10.11.144.176:5003'  # 请求flask平台链接
requests_flask_ip = 'http://10.11.80.122:5003'  # 请求flask平台链接

MONGO_NAME = "performance_analyse"
MONGO_PERFEYE_COLNAME = "perfeye_data_list"  # perfeye平台数据集合
# MONGO_HOST = "10.11.80.73" #  正式数据库
MONGO_HOST = "10.11.80.122"  # 测试数据库
MONGO_PORT = 27017


class PerfeyeMongo(CaseCommon):
    i_DefaultInterval = 7  # 默认日期间隔,这里默认7天
    date_NowDateTime = ''  # datetime 类型 格式化 such as 2022-10-17 23:59:59
    date_IntervalDateTime = ''  # datetime 的日期间隔对象 将 i_DefaultInterval 转换成datetime
    date_StarDateTime = '',  # 格式化 such as 2022-10-10 00:00:00
    client_MonGoClientGeneralDetail = '',  # perfeye 数据库游标对象
    dict_AppKey = {}  # 需要请求和写入数据库的appkey

    def __init__(self):
        super().__init__()
        pass

    def run_local(self, dic_args):
        self.client_MonGoClientGeneralDetail = self.fn_init_mongodb()
        self.i_DefaultInterval = dic_args['DateInterval']
        self.fn_update_Perfeye_data()
        # threading.Thread(target=self.fn_update_Perfeye_data).start()

    def fn_time_type_conversion(self, target, conversion_format='%Y-%m-%d %H:%M:%S'):
        # 日期类型转换，给字符串返回datetime类型
        # 给datetime类型 返回字符串
        # conversion_format 为日期格式 such as: '%Y-%m-%d %H:%M:%S','%Y-%m-%d'
        TargetType = type(target)
        if TargetType == str:
            return datetime.datetime.strptime(target, conversion_format)
        elif TargetType == datetime.datetime:
            return datetime.datetime.strftime(target, conversion_format)
        pass

    def fn_init_mongodb(self, host=MONGO_HOST, port=MONGO_PORT, db_name=MONGO_NAME, col_name=MONGO_PERFEYE_COLNAME):
        # 连接mongo数据库，并返回 集合 连接
        try:
            MongoClient = pymongo.MongoClient(host=host, port=port)  # 连接数据库
            db = MongoClient[db_name]
            collections = db[col_name]
            return collections
        except Exception as e:
            self.log('mongodb连接失败:{}'.format(e))
            return None

    def fn_update_time(self):
        # 获取今天的日期 DateTime类型 such as :2022-08-15 23:59:59
        self.date_NowDateTime = self.fn_time_type_conversion(
            '{} 23:59:59'.format(datetime.datetime.now().strftime('%Y-%m-%d')), '%Y-%m-%d %H:%M:%S')
        # 获取日期间隔 DateTime类型
        self.date_IntervalDateTime = datetime.timedelta(days=self.i_DefaultInterval)
        # 获取开始日期 DateTime类型
        self.date_StarDateTime = self.fn_time_type_conversion(
            '{} 00:00:00'.format((self.date_NowDateTime - self.date_IntervalDateTime).strftime('%Y-%m-%d')),
            '%Y-%m-%d %H:%M:%S')

    def fn_update_Perfeye_data(self):
        # 自动获取今日到 interval内的 Perfeye平台数据
        # interval 为 日期间隔，单位为天，如果传入7，就是获取今天至7天前的数据,int 类型
        try:
            while 1:
                self.fn_update_time()  # 重新获取日期
                self.fn_get_appkey()  # 重新需要请求的 Appkey
                StarDateString = '{} 00:00:00'.format(
                    self.date_StarDateTime.strftime('%Y-%m-%d'))  # such as :2022-08-12 00:00:00
                NowDateString = '{} 23:59:59'.format(
                    self.date_NowDateTime.strftime('%Y-%m-%d'))  # such as :2022-08-12 23:59:59
                for sAppkey in self.dict_AppKey:
                    time_star = time.time()
                    self.log.info('开始请求perfeye平台,appkey={}'.format(sAppkey))
                    requests_Perfeye_Data = self.fn_request_perfeye(self.dict_AppKey[sAppkey],
                                                                    StarDateString,
                                                                    NowDateString)
                    # print(requests_Perfeye_Data)
                    time_end = time.time()
                    self.log.info(
                        u'请求Perfeye平台完成 app={}, time=({} - {}),耗时:{}s'.format(sAppkey, StarDateString, NowDateString,
                                                                              time_end - time_star))
                    if 'errmsg' in requests_Perfeye_Data:
                        # 如果 有errmsg 字段，就说明 Perfeye平台请求会报错，这里就跳过
                        continue

                    insert_Mongo_data = list(
                        filter(lambda res_data: res_data['AppKey'] == self.dict_AppKey[sAppkey],
                               requests_Perfeye_Data))
                    self.fn_insert_Mongo(insert_Mongo_data, sAppkey)
                time.sleep(10)
                pass
        except Exception as e:
            self.log.error(e)

    def fn_get_appkey(self):
        # 请求flask，获取需要写入的 perfeye平台的appkey
        try:
            req = urllib2.Request("{}/getPerfeyeAppkey".format(requests_flask_ip))
            response = urllib2.urlopen(req, timeout=10)
            self.dict_AppKey = json.loads(response.read())
        except Exception as e:
            self.log.error('flask平台请求异常: {}'.format(e))
            return {'errmsg': u'flask平台请求异常'}
        pass

    def fn_request_perfeye(self, AppKey, StartTime, EndTime):
        # 请求perfeye平台 获取id和baseinfo和计算后的数据，最后会限制对应的appkey和 CaseName限制为‘IQB_AUTO’
        data = {
            "AppKey": AppKey,
            "StartTime": StartTime,
            "EndTime": EndTime
        }
        try:
            req = urllib2.Request("{}/api/admin/tasks".format(requests_ip),
                                  urllib.parse.urlencode(data).encode(encoding='UTF8'))
            response = urllib2.urlopen(req, timeout=10)
            requests_res = json.loads(response.read())
        except urllib2.URLError as e:
            if isinstance(e.reason, socket.timeout):
                self.log.error('perfeye平台请求超时')
            else:
                self.log.error('perfeye平台请求异常，msg:{}'.format(e))
            return {'errmsg': u'perfeye平台请求异常'}
        except Exception as e:
            self.log.error('perfeye平台请求异常: {}'.format(e))
            return {'errmsg': u'perfeye平台请求异常'}

        # 在这里限制 返回的appkey
        requests_res = filter(lambda res_data: res_data['AppKey'] == AppKey, requests_res)
        requests_res = list(requests_res)
        return requests_res

    def fn_insert_Mongo(self, insert_data, sAppKey):
        try:
            time_start = time.time()
            count = 0
            for insert_data_item in insert_data:
                # 这里先查找一下 ID，如果数据库里有了，就不在插入
                self.client_MonGoClientGeneralDetail.update({'ID': insert_data_item['ID']},
                                                            dict(insert_data_item, **{
                                                                'ReportTime': self.fn_time_type_conversion(
                                                                    insert_data_item['ReportTime'], '%Y-%m-%d %H:%M:%S')
                                                            }), True)
                count += 1
                pass
            time_end = time.time()
            self.log.info(
                'appkey:{},写入更新{}条数据,耗时:{}秒'.format(sAppKey, count, time_end - time_start))
            return
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)


if __name__ == '__main__':
    PerfeyeMongo = PerfeyeMongo()
    PerfeyeMongo.run_local({'DateInterval': 7})
