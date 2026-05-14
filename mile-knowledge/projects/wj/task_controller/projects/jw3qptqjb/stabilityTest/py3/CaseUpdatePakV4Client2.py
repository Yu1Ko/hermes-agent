# ver:3.6
import time
import pythoncom
import win32gui
from win32com import client
from BaseToolFunc import *
from CaseJX3Client import *

class CaseUpdatePakV4Client2(CaseJX3Client):
    def __init__(self):
        CaseJX3Client.__init__(self)
        self.name = None
        self.updateFlag = True
        self.notify_show = False

    def check_dic_args(self, dic_args):
        super(CaseUpdatePakV4Client2, self).check_dic_args(dic_args)
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
        win32_SetRegForPakv4Update(self.BASE_PATH, self.bEXP)
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')

        self.setClientPath(dic_args['clientType'])  # 指定客户端位
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)

        #获取SeasunGame.exe路径
        self.BASE_PATH=self.BASE_PATH+r'/SeasunGame'
        if self.initiator_version:
            self.BASE_PATH=r'f:/SeasunGame'
            if not os.path.exists(self.BASE_PATH):
                disks = psutil.disk_partitions()
                for disk in disks:
                    path = disk.mountpoint + 'SeasunGame'
                    if os.path.exists(path):
                        self.BASE_PATH = path
                        break
        exe = os.path.join(self.BASE_PATH, 'SeasunGame.exe')
        #根据clientType修改启动器默认项目
        strConfigPath=self.BASE_PATH+'/pre_settings.ini'
        dic_itmes={
            'PAK_EXP':'JX3_EXP',
            'PAK_EXP_classic': 'JX3_CLASSIC_EXP',
            'PAK': 'JX3',
            'PAK_classic': 'JX3_CLASSIC'
        }
        ini_set('DOWNLOAD', 'ChoseGame', dic_itmes[self.clientType],strConfigPath)
        self.log.info(dic_itmes[self.clientType])
        #运行启动器
        pp=win32_runExe_no_wait(exe, self.BASE_PATH)
        self.clientPID=pp.pid
        while not win32_findProcessByName('SeasunGame.exe'):
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
            try:
                pythoncom.CoInitialize()
                shell = client.Dispatch("WScript.Shell")
                shell.SendKeys('%')
                #win32gui.SetForegroundWindow(hwnd)
                left, top, right, bot = win32gui.GetWindowRect(hwnd)
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
                if not hwnd:
                    self.log.info("hwnd Error")
                return 
            x = right - 200
            y = bot - 70
            win32api.SetCursorPos([x, y])
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
            win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0)
            time.sleep(3)
            if win32_findProcessByName('JX3ClientX64.exe'):
                win32_kill_process('JX3ClientX64.exe')
                win32_kill_process('SeasunGame.exe')
                break
            if time.time()-nLastTime>1800:
                MachineID = self.strMachineName
                send_Subscriber_msg(machine_get_IPAddress(), '%s: 半小时还在更新pakv4客户端,注意查看' % MachineID)

        if not self.clientType == 'PAK':
            strpakUpdateTime = open(self.CLIENT_PATH + '/version.cfg', 'r').readlines()[1]
            listDate = re.findall(r'\w+|:', time.strftime("%a %b %d %H:%M:%S %Y", time.localtime()))
            del listDate[3:-1]  # 只保留日期,不要时间
            listpakUpdateTime = re.findall(r'\w+|:', strpakUpdateTime)
            listpakUpdateTime.remove('CST')  # 保持格式一致，所以去掉CST标识
            del listpakUpdateTime[3:-1]
            self.log.info(strpakUpdateTime)
            self.log.info(listDate)
            if listDate != listpakUpdateTime:
                if self.updateFlag:
                    send_Subscriber_msg(
                        machine_get_IPAddress(),
                        ('%s: %s Pakv4版本无更新, 稍后将每5分钟次尝试一次更新。' % (self.strMachineName, self.clientType))
                    )
                    self.updateFlag = False
                time.sleep(300)
                self.run_local(dic_args)

if __name__ == '__main__':
    oob = CaseUpdatePakV4Client2()
    oob.run_from_IQB()