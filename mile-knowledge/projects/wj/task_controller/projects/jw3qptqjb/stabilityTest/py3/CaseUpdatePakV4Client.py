# ver:3.6
from BaseToolFunc import *
from CaseJX3Client import *

class CaseUpdatePakV4Client(CaseJX3Client):
    def __init__(self):
        CaseJX3Client.__init__(self)
        self.name = None
        self.updateFlag = True
        self.notify_show = False

    def run_local(self, dic_args):
        self.loadDataFromLocalConfig(dic_args)
        self.check_dic_args(dic_args)
        self.setClientPath(dic_args['clientType'])  # 指定客户端位置
        self.launcher_log_path = self.BASE_PATH + '/logs/XLauncher/'
        if not os.path.exists(self.launcher_log_path):
            if self.clientType == 'PAK_EXP_classic' or self.clientType == 'PAK_classic':
                self.launcher_log_path = self.BASE_PATH + '/XLauncherKernel/logs/XLauncherKernelClassic/'
            else:
                self.launcher_log_path = self.BASE_PATH + '/XLauncherKernel/logs/XLauncherKernel/'

        win32_SetRegForPakv4Update(self.BASE_PATH, self.bEXP)
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('XLauncher.exe')
        win32_kill_process('XLauncherKernel.exe')
        win32_kill_process('XLauncherKernelClassic.exe')

        old_f = getLastLogFile(self.launcher_log_path)
        exe = os.path.join(self.BASE_PATH, 'XLauncher.exe')
        win32_runExe_no_wait(exe, self.BASE_PATH)
        while not win32_findProcessByName('XLauncher.exe') and \
                not win32_findProcessByName('XLauncherKernel.exe') and \
                not win32_findProcessByName('XLauncherKernelClassic.exe'):
            time.sleep(1)
        time.sleep(10)
        f = getLastLogFile(self.launcher_log_path)
        # print self.launcher_log_path

        while old_f == f:
            time.sleep(2)
            f = getLastLogFile(self.launcher_log_path)
        start_game_line =0
        NotifyGameInfo_line = 0
        while f:
            isFoundStartGame, start_game_line = findStringInLog(f, 'Enable btn start game',start_game_line)
            if isFoundStartGame:
                info = 'Enable btn start game'
                self.log.info(info)
                time.sleep(5)
                break
            time.sleep(1)
            isFoundGameInfo,NotifyGameInfo_line =findStringInLog(f, '[UI] NotifyGameInfo',NotifyGameInfo_line)
            if isFoundGameInfo and not self.notify_show:
                self.notify_show = True
                send_Subscriber_msg(
                    machine_get_IPAddress(),
                    ('%s: %s Pakv4启动器有弹窗提示，可能会影响更新，请留意。' % (self.strMachineName, self.clientType))
                )
            f = getLastLogFile(self.launcher_log_path)


        if not self.clientType == 'PAK':
            strpakUpdateTime = open(self.CLIENT_PATH + '/version.cfg', 'r').readlines()[1]
            listDate = re.findall(r'\w+|:', time.strftime("%a %b %d %H:%M:%S %Y", time.localtime()))
            del listDate[3:-1]  # 只保留日期,不要时间
            listpakUpdateTime = re.findall(r'\w+|:', strpakUpdateTime)
            listpakUpdateTime.remove('CST')  # 保持格式一致，所以去掉CST标识
            del listpakUpdateTime[3:-1]
            if listDate != listpakUpdateTime:
                if self.updateFlag:
                    send_Subscriber_msg(
                        machine_get_IPAddress(),
                        ('%s: %s Pakv4版本无更新, 稍后将每5分钟次尝试一次更新。' % (self.strMachineName, self.clientType))
                    )
                    self.updateFlag = False
                time.sleep(300)
                self.run_local(dic_args)

            # 解除注释以下代码会等待机器人和服务器启动完毕后才开始运行
            # if self.clientType == 'PAK_EXP_classic':
            #     today = time.strftime("%Y-%m-%d", time.localtime())
            #     ServerStarted = False
            #     RobotStarted = False
            #     stateFile = open(r'\\10.11.68.11\FileShare\State\State.txt', 'r')
            #     for line in stateFile.readlines():
            #         if re.findall(r'(%s).+(ServerStarted---Finish)' % today, line):
            #             ServerStarted = True
            #         if re.findall(r'(%s).+(RobotStarted---Finish)' % today, line):
            #             RobotStarted = True
            #         pass
            #     stateFile.close()
            #     if not (ServerStarted and RobotStarted):
            #         if self.updateFlag:
            #             send_Subscriber_msg(machine_get_IPAddress(), '怀旧版每日快速BVT: 等待服务器和机器人启动。')
            #             self.updateFlag = False
            #         time.sleep(600)
            #         self.thread_task(dic_args)
            #     pass
        self.teardown(dic_args)


if __name__ == '__main__':
    oob = CaseUpdatePakV4Client()
    oob.run_from_IQB()
