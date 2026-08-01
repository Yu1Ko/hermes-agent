# coding=utf-8
from CaseJX3Client import *
from BaseToolFunc import *
import pymongo
from datetime import date,timedelta

class CaseMonitorCachedShadersFile(CaseJX3Client):
    def __init__(self):
        super(CaseMonitorCachedShadersFile, self).__init__()
        self.dic_info={}
        # {日期:{版本号1:{"Reversion":version,"Author":author, "Time":time,"Message":message,"Content":list_content}}

    def check_dic_args(self, dic_args):
        super(CaseMonitorCachedShadersFile, self).check_dic_args(dic_args)
        self.user = SVN_USER
        self.passw = SVN_PASS
        if 'vacation' in dic_args:
            self.vacation = dic_args['vacation']
        self.svnPath='https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/data/source/maps'
        if 'user' in dic_args:
            self.user = dic_args['user']
        if 'passw' in dic_args:
            self.passw = dic_args['passw']
        self.ver = None

    def findVersion(self,y=None,t=None):
        today=date.today()
        str_weak_today=today.strftime("%A")
        difference=-1
        if str_weak_today=='Monday':
            difference=-3
        vacation=self.vacation
        self.output_date={}
        if vacation!=0:
            difference=-(vacation+1)
        for d in range(difference,0):
            str_today=(today + timedelta(days=d+1)).strftime("%Y%m%d")
            str_yesterday = (today + timedelta(days=d)).strftime("%Y%m%d")
            str_today_year = str((today + timedelta(days=d)).year) + '年'
            str_today_month = str((today + timedelta(days=d)).month) + '月'
            str_today_day = str((today + timedelta(days=d)).day) + '日'
            self.output_date[str_yesterday]=str_today_year+str_today_month+str_today_day
            cmd = 'svn log {} -r {{{}}}:{{{}}}'.format(self.svnPath, str_yesterday, str_today)
            t = os.popen(cmd)
            list_info = t.readlines()
            self.dic_info[str_yesterday]={}
            nIndex=0
            for line in list_info:
                if line[0] == 'r' and list_info[nIndex + 2].find('场景资源提交') != -1:
                    end = line.find(' ')
                    list_versionInfo=line.split('|')
                    str_version=list_versionInfo[0][1:-1]
                    self.dic_info[str_yesterday][str_version]={}
                    self.dic_info[str_yesterday][str_version]["Message"]=list_info[nIndex+2].split('\n')[0]
                    self.dic_info[str_yesterday][str_version]["Author"]=list_versionInfo[1].split(' ')[1]
                    list_time = list_versionInfo[2].split(' ')
                    self.dic_info[str_yesterday][str_version]["Time"] = list_time[1]+' '+list_time[2]

                nIndex += 1

    def monitor_startup(self):
        str_notice='\n'
        myclient = pymongo.MongoClient("mongodb://10.11.80.122:27017/")
        mydb = myclient["FileMonitorInfo"]
        mycol = mydb["MapFileInfo"]
        for str_date in self.dic_info:
            dic_version_info=self.dic_info[str_date]
            str_notice+=self.output_date[str_date]
            for version in dic_version_info:
                self.log.info('{}-{}-{}-{}'.format(self.svnPath, version, self.user, self.passw))
                if self.svnPath and self.user and self.passw:
                    cmd = 'svn log --verbose {} -r {} --username {} --password {}'.format(self.svnPath, version, self.user, self.passw)
                try:
                    t=os.popen(cmd)
                    list_content=t.readlines()
                    list_content = list_content[3:len(list_content) - 3]
                    list_result=[]
                    for content in list_content:
                        list_result.append(content[5:len(content) - 1])
                    dic_version_info[version]["MapName"]=list_result[0].split('/')[6]
                    str_notice +=("\n{ 版本号: "+version+"    地图: "+dic_version_info[version]["MapName"]+"}")
                    self.log.info("版本号={},提交人={},时间={},提信息={}".format(version, dic_version_info[version]["Author"],dic_version_info[version]["Time"],dic_version_info[version]["Message"]))
                    self.log.info(list_result)
                    dic_data = {"Reversion": version, "Author": dic_version_info[version]["Author"], "Time": dic_version_info[version]["Time"],
                                "Message": dic_version_info[version]["Message"], "Content": list_result, "MapName":  dic_version_info[version]["MapName"]}
                except Exception as e:
                    info = traceback.format_exc()
                    self.log.error(info)
                try:
                    if not mycol.find_one(dic_data):
                        mycol.insert_one(dic_data)
                except:
                    str_error = "数据插入异常:  版本号={},提交人={},时间={},提信息={}".format(version, dic_version_info[version]["Author"],dic_version_info[version]["Time"],dic_version_info[version]["Message"])
                    IPv4 = machine_get_IPAddress()
                    send_Subscriber_msg(IPv4, str_error)
                    self.log.info(str_error)
            str_notice+='\n'
        IPv4 = machine_get_IPAddress()
        send_Subscriber_msg(IPv4, str_notice)
    def run_local(self, dic_args):
        win32_kill_process('Xlauncher.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('JX3ClientX64.exe')
        self.check_dic_args(dic_args)
        self.findVersion()
        self.monitor_startup()


    def teardown(self, dic_args):
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('XLauncher.exe')
        win32_kill_process('XLauncherKernel.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('svn.exe')
        pass

if __name__ == '__main__':
    oob = CaseMonitorCachedShadersFile()
    oob.run_from_IQB()
