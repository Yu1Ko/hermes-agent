# coding=utf-8
from CaseJX3Client import *
from BaseToolFunc import *
import pymongo
from datetime import date,timedelta

class CaseMonitorCachedShadersFile(CaseJX3Client):
    def __init__(self):
        super(CaseMonitorCachedShadersFile, self).__init__()
        self.fileInfo={}
        self.fileInfo['count'] = {}
        self.fileInfo['content'] = {}

    def check_dic_args(self, dic_args):
        super(CaseMonitorCachedShadersFile, self).check_dic_args(dic_args)
        self.user = SVN_USER
        self.passw = SVN_PASS
        if 'vacation' in dic_args:
            self.vacation = dic_args['vacation']
        self.svnPath='https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/CachedShaders'
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
        self.dic_version = {}
        self.output_date={}
        self.date={}
        if vacation!=0:
            difference=-(vacation+1)
        for d in range(difference,0):
            str_today=(today + timedelta(days=d+1)).strftime("%Y%m%d")
            str_yesterday = (today + timedelta(days=d)).strftime("%Y%m%d")
            str_today_month=str((today + timedelta(days=d)).month)+'月'
            str_today_day = str((today + timedelta(days=d)).day) + '日'
            cmd = 'svn log {} -r {{{}}}:{{{}}}'.format(self.svnPath, str_yesterday, str_today)
            t = os.popen(cmd)
            list_info = t.readlines()
            self.dic_version[str_yesterday]=[]
            self.output_date[str_yesterday]=str_today_month+str_today_day
            self.date[str_yesterday]=(today + timedelta(days=d)).strftime("%Y-%m-%d")
            for line in list_info:
                if line[0] == 'r':
                    end = line.find(' ')
                    self.dic_version[str_yesterday].append(line[1:end])

    def monitor_startup(self):
        str_notice='\n'
        myclient = pymongo.MongoClient("mongodb://10.11.80.122:27017/")
        mydb = myclient["CachedShadersInfo"]
        mycol = mydb["shaderChangesInfo"]
        for str_date in self.dic_version:
            output_date=self.output_date[str_date]
            self.fileInfo['content'][str_date]={}
            self.fileInfo['count'][str_date]=0
            str_notice=str_notice+output_date+' '
            list_version=self.dic_version[str_date]
            for version in list_version:
                self.log.info('{}-{}-{}-{}'.format(self.svnPath, version, self.user, self.passw))
                if self.svnPath and self.user and self.passw:
                    cmd = 'svn log --verbose {} -r {} --username {} --password {}'.format(self.svnPath, version, self.user, self.passw)
                try:
                    t=os.popen(cmd)
                    list_content=t.readlines()
                    count = 0
                    self.fileInfo['content'][str_date][version]=list_content
                    for content in list_content:
                        if content.find('}.bin')!=-1:
                            count+=1
                    self.fileInfo['count'][str_date]+=count
                    self.log.info('日期:{},版本:{},文件内容:{}'.format(str_date,version,list_content))
                    self.log.info('日期:{},版本:{},文件数量:{}'.format(str_date,version,count))
                except Exception as e:
                    info = traceback.format_exc()
                    self.log.error(info)
            dic_data={"changeDate":self.date[str_date],"changeCount":self.fileInfo['count'][str_date]}
            try:
                if not mycol.find_one(dic_data):
                    mycol.insert_one(dic_data)
            except:
                str_error = "数据插入异常:  日期={},文件数量={}".format(dic_data["changeDate"],dic_data["changeCount"])
                IPv4 = machine_get_IPAddress()
                send_Subscriber_msg(IPv4, str_error)
                self.log.info(str_error)
            str_notice=str_notice+'文件变更次数: {}\n'.format(self.fileInfo['count'][str_date])
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
