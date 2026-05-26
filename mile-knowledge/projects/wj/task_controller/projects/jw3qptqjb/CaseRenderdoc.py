# -*- coding: utf-8 -*-
from CaseTDR import *
import getpass
import os
import time
from SnapshotTool_rdc.SnapshotTool_rdc import *

class CaseRenderdoc(CaseTDR):
    def __init__(self):
        super().__init__()
        self.name = None
        #self.bDumpCase=True #宕机用例
        self.autoRenderdoc=None
        self.svnPath="svn://10.11.8.138/jx3test/GPULabel/bin64_m_GPULabel"
        self.list_file=[
            'JX3ClientX3DX64.exe',
            'JX3ClientX3DX64.map',
            'JX3ClientX3DX64.lib',
            'JX3ClientX3DX64.exp'
        ]

    def process_tss(self):
        tss = self.CLIENT_PATH + r'\bin64\tss_api.dll'
        if os.path.exists(tss):
            os.remove(tss)

    def thread_PressEnterToLogin(self, dicSwitch, t_parent, old_f, RUN_CLIENT_LOG_PATH):
        pass

    def check_dic_args(self, dic_args):
        dic_args['nTimeout'] = 99999999
        self.needKillDeath = True
        super().check_dic_args(dic_args)
        #self.exename = 'JX3Debugger.exe'

    '''
    def processInterface(self, dic_args):
        #XGame临时处理
        # 拷贝Interface文件夹
        TEMP_FOLDER = 'TempFolder'
        filecontrol_deleteFileOrFolder(self.INTERFACE_PATH)
        filecontrol_copyFileOrFolder(SERVER_PATH + '/XGame/Interface', TEMP_FOLDER + '/Interface')
        ini_set("Interface","Type",self.runMapType,TEMP_FOLDER + '/Interface/SearchPanel/Interface.ini')
        self.log.info(self.runMapType)
        return
'''

    def processBin64_m(self):
        #checkout
        x = os.path.realpath(__file__)
        root = x.split('\\')[0]
        self.work_path = os.path.join(root, os.sep, 'bin64_m_GPULabel')
        self.ver=None
        self.user="liuzhu2"
        self.passw="*z4aR#Mpqc!LkpTBg3k"
        if not filecontrol_existFileOrFolder(self.svnPath):
            svn_cmd_checkout(self.svnPath, self.work_path, ver=self.ver, user=self.user, passw=self.passw)
        svn_cmd_cleanup(self.work_path)
        svn_cmd_update(self.work_path, ver=self.ver, user=self.user, passw=self.passw)

        self.log.info(f"work_path:{self.work_path}")
        for strfileName in self.list_file:
            self.log.info(f"copyfile {os.path.join(self.work_path,strfileName)}")

            if filecontrol_existFileOrFolder(os.path.join(self.CLIENT_PATH,self.BIN64_NAME,strfileName)):
                # 跑完后还原的文件 存放到中间文件夹
                filecontrol_copyFileOrFolder(os.path.join(self.CLIENT_PATH,self.BIN64_NAME,strfileName),os.path.join(GetTEMPFOLDER(),strfileName))
            filecontrol_copyFileOrFolder(os.path.join(self.work_path,strfileName),os.path.join(self.CLIENT_PATH,self.BIN64_NAME,strfileName))

    def start_client_test(self, dic_args):
        self.processBin64_m()
        if not self.bMobile:
            #初始化Renderdoc自动化工具
            game_path=os.path.join(self.CLIENT_PATH,self.BIN64_NAME)
            game_name=self.exename
            appkey="62baa3h2" #内网windows id
            self.args['AppKey']=appkey
            device_ip=machine_get_IPAddress()
            parameters=None
            platform="win"
            deviceName=self.strMachineName
            game_quality=self.tagVideoLevel
            localcase=self.strCaseName
            daily=""
            package_url=""
            autoRenderdoc = SnapshotTool(game_path, game_name, appkey, device_ip, parameters, platform, deviceName, game_quality,localcase, daily, package_url)
            autoRenderdoc.Start()
            self.autoRenderdoc=autoRenderdoc

            self.log.info(self.autoRenderdoc)
            # time.sleep(60)
            # autoRenderdoc.Grab("登录界面", "自动化测试用例", "1.0.0")
            # time.sleep(10)
            # autoRenderdoc.Stop()

            #self.process_threads_activeWindow()  # 让客户都安处于顶层
            time.sleep(1)
            while not self.clientPID:
                try:
                    self.clientPID = win32_findProcessByName(self.exename)[0].pid
                    self.log.info(f'Client pid:{self.clientPID}')
                except:
                    self.log.info("获取 client Pid中")
                    time.sleep(1)
                    pass
            #self.process_threads_activeWindow()  # 让客户都安处于顶层
            self.nClientStartTime = int(time.time())
        else:
            super().start_client_test(dic_args)

    #添加截帧线程检测
    # def add_thread_for_searchPanel(self, dicSwitch):
    #     # 截帧线程
    #     t = threading.Thread(target=self.thread_Renderdoc,args=(threading.currentThread(),))
    #     self.listThreads_beforeStartClient.append(t)
    #     super().add_thread_for_searchPanel(dicSwitch)

    def task_mobile(self):
        #需要等待截帧完成后 再检查游戏是否需要结束
        fTimer=0
        while True:
            try:
                time.sleep(1)
                if time.time()-fTimer > 120:
                    self.log.info("thread_Renderdoc heart")
                    fTimer=time.time()
                if self.checkRecvInfoFromSearchpanel('Renderdoc'):
                    self.log.info(f"Renderdoc Capture start")
                    # 截取-分析
                    res=self.autoRenderdoc.Grab(self.mapname, self.strCaseName, self.GetVersion())
                    self.args['RenderdocReport']=res
                    self.log.info(f"Renderdoc Capture stop")
                    break
            except Exception as e:
                self.log.info(e)
                break
        self.log.info('thread_Renderdoc end')
        super().task_mobile()


    def thread_Renderdoc(self, t_parent):
        self.log.info('thread_Renderdoc start')
        fTimer=time.time()
        while t_parent.is_alive():
            try:
                time.sleep(1)
                if time.time()-fTimer > 120:
                    self.log.info("thread_Renderdoc heart")
                    fTimer=time.time()
                if self.checkRecvInfoFromSearchpanel('Renderdoc'):
                    self.log.info(f"Renderdoc Capture start")
                    # 截取-分析
                    self.autoRenderdoc.Grab(self.mapname, self.strCaseName, self.GetVersion())
                    self.log.info(f"Renderdoc Capture stop")
                    break
            except Exception as e:
                self.log.info(e)
                break
        self.log.info('thread_Renderdoc end')

    def teardown(self):
        if not self.bMobile:
            #win32_kill_process('JX3Debugger.exe')
            if self.autoRenderdoc:
                self.autoRenderdoc.Stop()
            #还原修改的文件
            for strfileName in self.list_file:
                if filecontrol_existFileOrFolder(os.path.join(GetTEMPFOLDER(), strfileName)):
                    # 跑完后还原修改的文件
                    filecontrol_copyFileOrFolder(os.path.join(GetTEMPFOLDER(), strfileName),os.path.join(self.CLIENT_PATH, self.BIN64_NAME, strfileName))
        super().teardown()
        send_Subscriber_msg(self.strGuid, f"用例:{self.strCaseName} 运行时长: {int(self.nClientRunTime / 60)}分钟")


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseRenderdoc()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    pass
    #obj_test = CaseRenderdoc()
    #obj_test.run_from_IQB()