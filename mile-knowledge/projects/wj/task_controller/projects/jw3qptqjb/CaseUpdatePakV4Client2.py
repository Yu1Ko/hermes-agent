# ver:3.6
import time
import pythoncom
from win32com import client
from BaseToolFunc import *
from CaseJX3Client import *

class CaseUpdatePakV4Client2(CaseJX3Client):
    def __init__(self):
        super().__init__()

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        self.user = SVN_USER
        self.passw = SVN_PASS
        self.svnPath='https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/CachedShaders'
        if 'user' in dic_args:
            self.user = dic_args['user']
        if 'passw' in dic_args:
            self.passw = dic_args['passw']
        if 'initiator_ver' in dic_args:
            self.initiator_version = dic_args['initiator_ver']
        self.ver = None


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        #self.loadDataFromLocalConfig()
        #win32_SetRegForPakv4Update(self.BASE_PATH, self.bEXP)
        win32_kill_process('JX3ClientX3DX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')
        win32_kill_process('JX3Debugger.exe')

        self.strClientType=dic_args['clientType']
        self.strClientLog='Test'
        self.setClientPath(self.strClientType)  # 指定客户端位

        dic_devices_data = dic_args["devices_custom"]
        # self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        self.strMachineName = dic_args['device_name']

        # 删除游戏客户端的插件环境 防止删除失败
        strMuiPath = self.CLIENT_PATH+r'/mui/Lua'
        bRet = filecontrol_deleteFileOrFolder(strMuiPath)
        self.log.info(f"释放成功删除插件环境:{strMuiPath}   bRet:{bRet}")
        while filecontrol_existFileOrFolder(strMuiPath):
            filecontrol_deleteFileOrFolder(strMuiPath)
            self.log.info("删除游戏客户端的插件环境")
            time.sleep(1)
        #获取SeasunGame.exe路径
        #self.BASE_PATH=self.BASE_PATH+r'/SeasunGame'
        '''
        if self.initiator_version:
            self.BASE_PATH=r'f:/SeasunGame'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'SeasunGame'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break'''
        exe = os.path.join(self.BASE_PATH, 'SeasunGame.exe')
        #根据clientType修改启动器默认项目
        strConfigPath=self.BASE_PATH+'/user_settings.ini'
        dic_itmes={
            'PAK_EXP':'JX3_EXP',
            'PAK_EXP_classic': 'JX3_CLASSIC_EXP',
            'PAK': 'JX3',
            'PAK_classic': 'JX3_CLASSIC',
            'XGame_VK':'JX3_WJ_EXP'
        }
        ini_set('DOWNLOAD', 'LastGame', dic_itmes[self.strClientType],strConfigPath)
        strConfigPath = self.BASE_PATH + '/user_settings.ini'
        self.log.info(dic_itmes[self.strClientType])
        #运行启动器
        pp=win32_runExe_no_wait(exe, self.BASE_PATH)
        self.clientPID=pp.pid
        while not win32_findProcessByName('SeasunGame.exe'):
            self.log.info("wait SeasunGame.exe")
            time.sleep(2)
        time.sleep(10)

        self.process_threads_activeWindow()
        hwnd=win32gui.FindWindow('Qt5152QWindowIcon', None)
        while not hwnd:
            time.sleep(2)
            hwnd = win32gui.FindWindow('Qt5152QWindowIcon', None)
        time.sleep(10)
        nLastTime=time.time()
        while True:
            time.sleep(1)
            pythoncom.CoInitialize()
            shell = client.Dispatch("WScript.Shell")
            shell.SendKeys('%')
            if win32gui.IsWindow(hwnd): #判断窗口句柄是否有效
                win32gui.SetForegroundWindow(hwnd)
                left, top, right, bot = win32gui.GetWindowRect(hwnd)
            else:
                info = "出现无效句柄，尝试重启用例"
                self.log.info(info)
                self.teardown()
                self.task_reset()
                time.sleep(600) #等待中重启了此用例
                os._exit(0)
                # screenPath = printscreen('./temp')
                # send_Subscriber_msg(machine_get_guid(), info, screenPath)
                # time.sleep(2)
                # filecontrol_deleteFileOrFolder(screenPath)
                # continue
            x = right - 200
            y = bot - 70
            win32api.SetCursorPos([x, y])
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)
            time.sleep(5)
            if win32_findProcessByName('JX3ClientX3DX64.exe'):
                self.log.info("点击授权")
                #点击授权弹窗
                hwnd = win32gui.FindWindow('KGWin32App', None)
                while not hwnd:
                    self.log.info('FindWindow(KGWin32App)')
                    time.sleep(5)
                    hwnd = win32gui.FindWindow('KGWin32App', None)
                '''
                win32gui.ShowWindow(hwnd, win32con.SW_MAXIMIZE)
                time.sleep(5)
                while True:
                    strScreenShotPath=self.Client_ScreenShot()
                    strRes=paddleocr(strScreenShotPath)
                    self.log.info(strRes)
                    if '同意' in strRes or '登录密码' in strRes or '登录账号' in strRes or '登录游戏' in strRes:
                        break
                    time.sleep(10)
                time.sleep(20)
                self.log.info('test1')
                pythoncom.CoInitialize()
                shell = client.Dispatch("WScript.Shell")
                shell.SendKeys('%')
                if win32gui.IsWindow(hwnd):  # 判断窗口句柄是否有效
                    self.log.info('test2')
                    win32gui.SetForegroundWindow(hwnd)
                    left, bot, right, top = win32gui.GetWindowRect(hwnd)
                    # screenPath = printscreen('./temp')
                    # send_Subscriber_msg(machine_get_guid(), info, screenPath)
                    # time.sleep(2)
                    # filecontrol_deleteFileOrFolder(screenPath)
                    # continue'''
                '''
                nLen = right - abs(left)
                nhet = top - abs(bot)
                x = right - int(440 * nLen / 1920)
                y = top - int(245 * nhet / 1200)
                win32gui.MoveWindow(hwnd, 30, 30, 1900, 1200, 1)
                time.sleep(10)
                x = 1900-430
                y = 1200-220
                win32api.SetCursorPos([x, y])
                win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
                win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)
                time.sleep(20)'''
                win32_kill_process('JX3ClientX3DX64.exe')
                win32_kill_process('SeasunGame.exe')
                self.log.info('test3')
                time.sleep(10)
                break
            if time.time()-nLastTime>1800:
                nLastTime=time.time()
                MachineID = self.strMachineName
                send_Subscriber_msg(machine_get_IPAddress(), '%s: 半小时还在更新pakv4客户端,注意查看' % MachineID)
        '''
        if not self.strClientType == 'PAK':
            strpakUpdateTime = open(self.CLIENT_PATH + '/version.cfg', 'r').readlines()[1]
            listDate = re.findall(r'\w+|:', time.strftime("%a %b %d %H:%M:%S %Y", time.localtime()))
            del listDate[3:-1]  # 只保留日期,不要时间
            listpakUpdateTime = re.findall(r'\w+|:', strpakUpdateTime)
            listpakUpdateTime.remove('CST')  # 保持格式一致，所以去掉CST标识
            del listpakUpdateTime[3:-1]
            self.log.info(strpakUpdateTime)
            # self.log.info(listDate)
            if listDate != listpakUpdateTime:
                info = 'Pakv5客户端今日没有制作新的版本, 稍后尝试再次更新。'
                self.log.error(info)
                time.sleep(300)
                self.task_reset()
                time.sleep(600)  # 等待中重启了此用例
                os._exit(0)'''

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseUpdatePakV4Client2()
    obj_test.run_from_uauto(dic_parameters)

