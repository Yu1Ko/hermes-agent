import sys
import os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
from CaseCommon import *
from BaseToolFunc import *
from SendMsgRobot import *
from CaseXGameCrash import *

win = platform.system() == "Windows"


def remove_control_chars(text):  # 移除颜色控制符
    pattern = r'\x1B\[[0-?]*[-/]*[@-~]'
    return re.sub(pattern, '', text)


def validate_dirName(caseName):
    rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
    new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
    new_title = re.sub(r"\s+", "", new_title)  # 去除空格（否则命令行会出错）
    return new_title


class CaseVKAsanCheck(CaseXGameCrash):
    def __init__(self):
        CaseXGameCrash.__init__(self)  # 父类初始化
        self.deviceId = None        # 设备id
        self.log_path = None
        self.asan_log_dir = None   # 共享Asan日志目录
        self.log_dir_path = None   # 本地日志目录
        self.strClientLog=None  #本地客户日志位置
        self.strCaseName = None
        self.pathLocalConfig = None
        self.strMachineName = None
        self.package = None
        self.output_Asan = r'\\10.11.85.148\FileShare-181-242\FileShare\stabilityTest\XGameAsan检测日志'
        self.webhook = r"https://xz.wps.cn/api/v1/webhook/send?key=61190de268bad1ac14cff24ff9693b6c"
        self.send_msg = SendMsgRobot(self.webhook)
        self.ASAN_KEYWORD = None
        self.strWorkPath = None
        self.symbols_asan_path = None
        self.tagMachineType = None
        self.bAsan = False
        self.log_name = None
        self.current_date = None
        self.asan_count = 0
        self.parse_asan_py = None


    def SetWorkPath(self,dic_args):
        # 设置相关路径
        dic_devices_data = dic_args["devices_custom"]
        #deviceId = dic_devices_data['local']['deviceId']
        deviceId = dic_args['device']
        # 获取机器类型 Ios Android PC
        tagMachineType = dic_devices_data['perfmon_info']['machine_type']
        # 检测设备类型合法性
        list_strMachineType = ['Ios', 'Android', 'PC']
        if tagMachineType not in list_strMachineType:
            raise Exception(f"设备类型错误:{tagMachineType},必须为:Ios Android PC")
        strBaseFolder = f"{tagMachineType}-{deviceId}"
        #Android-7a04353e
        strWorkPath = os.path.join(os.getcwd(), strBaseFolder)
        # 工作路径 (controller+strBaseFolder)
        # 脚本路径(原来的py3)
        strScriptPath = os.path.dirname(os.path.realpath(__file__))
        # (controller+strBaseFolder+'TempFolder')
        strTEMPFOLDER = os.path.join(strWorkPath, 'TempFolder')
        SetWorkPath(strBaseFolder,strWorkPath,strScriptPath,strTEMPFOLDER)
        super().SetWorkPath(dic_args)
        self.strWorkPath = strWorkPath # 工作目录
        self.symbols_asan_path = self.strWorkPath + r'\Pak_Xgame_Andriod_Asan' # 符号文件目录
        self.log.info(f'ASAN符号路径:{self.symbols_asan_path}')
        self.tagMachineType = tagMachineType # 机器类型
        self.ASAN_KEYWORD = "[" + self.tagMachineType + "]" + "Asan内存安全检查"
        self.log.info(f'ASAN关键字:{self.ASAN_KEYWORD}')

        # 获取脚本文件所在的绝对路径
        script_path = os.path.abspath(__file__)
        # 获取脚本所在目录
        script_dir = os.path.dirname(script_path)
        self.parse_asan_py = os.path.join(script_dir, "android_asan_symbolize.py")
        self.log.info(f'解析Asan的工具路径：{self.parse_asan_py}')


    def runapp(self):
        self.package = 'com.seasun.jx3'
        cmd = f'adb -s {self.deviceId} shell pidof {self.package}'
        p = subprocess.Popen(args=cmd, shell=True,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        output = p.communicate()[0]
        return output

    def logcat_clear(self):
        # 清空缓存
        self.log.info('Logcat clear')
        cmd = f'adb -s {self.deviceId} logcat -c'
        pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output = pi.communicate()[0]


    def thread_Asan_check(self, dicSwitch, t_parent):
        while t_parent.is_alive():
            # 检测游戏客户端是否启动
            if not self.clientPID:
                time.sleep(3)
                continue
            else:
                self.log.info('thread_Asan_check:游戏客户端已启动')
                break
        self.log.info('thread_Asan_check:游戏启动成功，开始检测Asan')
        self.logcat_clear()
        self.current_date = datetime.datetime.now().strftime('%Y-%m-%d')  # 当前日期
        current_time = datetime.datetime.now().strftime('%Y-%m-%d-%H_%M_%S')  # 当前时间
        self.log_name = 'log' + current_time + '.txt'
        self.log_dir_path = os.path.join(self.strWorkPath + r'\logcat', self.current_date)
        if not filecontrol_existFileOrFolder(self.log_dir_path):
            filecontrol_createFolder(self.log_dir_path)
        self.log_path = os.path.join(self.log_dir_path, self.log_name)  # 日志本地位置

        cmd = f'adb -s {self.deviceId} logcat wrap.sh *:S -v time'

        # 构造popen
        p = subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        self.asan_count = 0
        wait_count = 0
        self.bAsan = False
        # 执行
        with open(self.log_path, "a", encoding="utf-8") as f:
            self.log.info('Logcat...')
            for line in iter(p.stdout.readline, b''):
                line = line.decode('utf-8', 'ignore')
                # print(line.split("\n")[0])
                # self.log.info(line.split("\n")[0])
                line = remove_control_chars(line)
                if '==ERROR: AddressSanitizer' in line:
                    self.asan_count = self.asan_count + 1
                    self.bAsan = True
                    self.log.info(f'检测到Asan信息:{self.bAsan}')
                if self.bAsan:
                    print(line.split("\n")[0])
                    f.write(line.split("\n")[0])
                    if "==ABORTING" in line:
                        self.log.info('ABORTING结束')
                        continue
                    if 'wrap.sh terminated by exit' in line:
                        f.write('==1111==ABORTING')  # 自己加个结尾
                        self.log.info('游戏结束，加ABORTING')
                        break
                else:
                    if not self.runapp():  # 游戏结束
                        wait_count = wait_count + 1
                        if wait_count == 200:
                            self.log.info(f'当前游戏结束，没有检测到Asan:{self.bAsan}')
                            break

            p.stdout.close()
        self.log.info(f'LogcatAsan Exit,return:{self.bAsan}')
        return self.bAsan

    def check_logcat_log(self):
        if not self.bAsan:
            self.log.info(f'thread_Asan_check:当前游戏结束，没有检测到Asan:{self.bAsan}')
        else:
            self.log.info("logcat to " + self.log_path)
            self.strMachineName = validate_dirName(self.strMachineName)  # 设备名称作为文件夹名，做下处理
            self.strCaseName = validate_dirName(self.strCaseName)  # 用例名称作为文件夹名，做下处理
            self.asan_log_dir = os.path.join(self.output_Asan, self.current_date, self.strMachineName, self.strCaseName)
            if not filecontrol_existFileOrFolder(self.asan_log_dir):
                filecontrol_createFolder(self.asan_log_dir)
            filecontrol_copyFileOrFolder(self.log_path, self.asan_log_dir)
            logcat_share_path = os.path.join(self.asan_log_dir, self.log_name)
            strMsg = f'{self.ASAN_KEYWORD}\nAsan信息数量：{self.asan_count}, logcat: {logcat_share_path}, 解析中...'
            self.log.info(f'{strMsg}')
            self.send_msg.push_report(self.strMachineName, strMsg)

            self.log.info(f'开始解析Asan日志')
            current_time = datetime.datetime.now().strftime('%Y-%m-%d-%H_%M_%S')  # 当前时间
            asan_log_name = 'output' + current_time + '.txt'
            asan_log_path = os.path.join(self.asan_log_dir, asan_log_name)

            cmd = f'python {self.parse_asan_py} --input {self.log_path} --symbols_dir {self.symbols_asan_path} > {asan_log_path}'
            self.log.info(f'{cmd}')
            p = subprocess.Popen(args=cmd, shell=True,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            out, err = p.communicate()  # 等待子进程结束
            self.log.info(f'解析完成：{asan_log_path}')

            strMsg = f'{self.ASAN_KEYWORD}\n解析结果：\\{asan_log_path}'
            self.send_msg.push_interactive_report(self.strMachineName, self.strCaseName, strMsg, asan_log_path)

            # 获取游戏日志
            if filecontrol_existFileOrFolder(self.strClientLog):
                filecontrol_copyFileOrFolder(self.strClientLog, self.asan_log_dir)
                self.log.info(f'游戏客户端日志位置:{self.strClientLog}')
            else:
                self.log.info("找不到游戏日志")

            strLocalPath = GetTEMPFOLDER() + os.sep + 'configHttpFile.ini'
            if filecontrol_existFileOrFolder(strLocalPath):
                filecontrol_copyFileOrFolder(strLocalPath, self.asan_log_dir)
                self.log.info(f'configHttpFile.ini位置:{strLocalPath}')
            else:
                self.log.info("找不到configHttpFile")


    def add_thread_for_searchPanel(self, dicSwitch):
        if not self.bMobile:
            # perfeye线程
            # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
            #                      args=(dicSwitch, threading.currentThread(),))
            # self.listThreads_beforeStartClient.append(t)

            #用例超时检查线程
            t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #异常处理线程
            t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #图像处理线程
            t = threading.Thread(target=self.thread_CheckScreenShot,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            # 游戏客户端运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
        else:
            #Asan检测线程
            t = threading.Thread(target=self.thread_Asan_check,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #perfeye线程
            # t = threading.Thread(target=self.thread_SearchPanelPerfEyeCtrl,
            #                      args=(dicSwitch, threading.currentThread(),))
            # self.listThreads_beforeStartClient.append(t)
            #游戏客户端运行状态监控与宕机线程
            t = threading.Thread(target=self.thread_CheckAppRunStateAndCrash,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #用例超时检查和perfeye_start超时检查 线程
            t = threading.Thread(target=self.thread_CheckTaskTimeOut,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #异常处理线程
            t = threading.Thread(target=self.thread_DealWith_ExceptionMsg,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            # 电量监控线程
            t = threading.Thread(target=self.thread_DeviceBatteryMonitor,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)

            #图像处理线程
            t = threading.Thread(target=self.thread_CheckScreenShot,
                                 args=(dicSwitch, threading.currentThread(),))
            self.listThreads_beforeStartClient.append(t)
            #处理设备弹窗
            #t = threading.Thread(target=self.mobile_device.thread_DealWithMobileWindow,
                                 #args=(threading.currentThread(),))
            #self.listThreads_beforeStartClient.append(t)
    def start_client_test(self, dic_args):
        # if self.clientType == 'PAK_EXP_classic':
        #     win32_runExe("JX3ClientX64.exe DOTNOTSTARTGAMEBYJX3CLIENT.EXE", self.CLIENT_PATH + "/" + self.BIN64_NAME)
        #     return  测试用的，注释掉
        self.log.info("start_client_test")
        if self.bMobile:
            #设备清除后台
            #self.mobile_device.clear_background()
            # 关闭app
            #mobile_kill_app(self.package,self.deviceId)
            self.mobile_device.kill_app()
            time.sleep(15)
            #ret=mobile_start_app(self.package,self.deviceId)
            #app 三次运行失败 用例执行失败
            nReStartCounter=4
            #移动端 此处等待Perfeye线程获取applist后再启动app
            # while not self.bCanStartClient: #Asan测试，不用等
            #     time.sleep(1)
            for i in range(nReStartCounter):
                if i==nReStartCounter-1:
                    raise Exception(f"{nReStartCounter-1}次启动app失败,用例执行失败退出")
                elif i==nReStartCounter-2:
                    #ios端 有可能使用tidevice 启动app报错了 需要使用wda启动app
                    self.mobile_device.start_app_wda()
                if self.mobile_device.determine_runapp():
                    break
                else:
                    ret = self.mobile_device.start_app()
                    self.log.info(ret)
                    time.sleep(15)
            self.log.info(f"app start temperature:{self.mobile_device.get_Battery_temperature()}")
            self.clientPID = "mobile"
        else:
            if 'memtest' in dic_args and dic_args['memtest'] == True:
                # 修改mem_jx3hd.cmd文件里的
                root = os.path.realpath(__file__).split('\\')[0]
                CPPMEMCMD = root + '/CppMemCmd'
                exe = os.path.join(CPPMEMCMD, "mem_jx3hd.cmd")
                pp = win32_runExe_no_wait(exe, CPPMEMCMD)
                listP = win32_findProcessByName(self.exename)
                while not listP:
                    listP = win32_findProcessByName(self.exename)
                    time.sleep(1)
                p2 = listP[0]
                self.clientPID = p2.pid
                self.process_threads_activeWindow()
            else:
                path = os.path.join(self.CLIENT_PATH, self.BIN64_NAME)
                exe = os.path.join(path, self.exename)
                self.log.info(exe)
                self.log.info(path)
                pp = win32_runExe_no_wait(exe, path)
                self.clientPID = pp.pid
                self.process_threads_activeWindow() #让客户端处于顶层
                nSetMaxWindow=0
                try:
                    nSetMaxWindow=dic_args["devices_custom"]['perfmon_info']['MaxWindow']
                    if nSetMaxWindow:
                        self.SetMaxWindow()
                except:
                    pass
        self.log.info("start_client_test_success")
        self.nClientStartTime = int(time.time())

    def teardown(self):
        super().teardown()
        self.check_logcat_log()

def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseVKAsanCheck()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = CaseVKAsanCheck()
    obj_test.run_from_IQB()
