from CaseCommon import *
from BaseToolFunc import *
from SendAsanMsg import SendAsanMsg

win = platform.system() == "Windows"


def remove_control_chars(text):  # 移除颜色控制符
    pattern = r'\x1B\[[0-?]*[-/]*[@-~]'
    return re.sub(pattern, '', text)


def validate_dirName(caseName):
    rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
    new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
    new_title = re.sub(r"\s+", "", new_title)  # 去除空格（否则命令行会出错）
    return new_title


class CaseXgameAsanMonitor(CaseCommon):
    def __init__(self):
        CaseCommon.__init__(self)  # 父类初始化
        self.log = None
        self.initLogger()
        self.deviceId = None        # 设备id
        self.log_path = None
        self.asan_log_dir = None   # 共享Asan日志目录
        self.log_dir_path = None   # 本地日志目录
        self.strClientLog=None  #本地客户日志位置
        self.strCaseName = None
        self.pathLocalConfig = None
        self.strMachineName = None
        self.package = None     
        self.output_Asan = r'\\10.11.181.242\FileShare\丁水娇\Xgame_Asan问题日志'
        self.send_msg = SendAsanMsg()
        self.ASAN_KEYWORD = None

    def loadDataFromLocalConfig(self, dic_args):
        # 获取配置文件中的相关信息
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        self.strMachineName = dic_args['machineName']
        self.log.info(f'机器: {self.strMachineName}')
        # 获取设备ID
        self.deviceId = dic_args['deviceId']
        self.log.info(f'设备id:{self.deviceId}')
        self.ASAN_KEYWORD = "[" + self.deviceId + "]" + "Asan内存安全检查"

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

    def get_jx3_log(self):
        self.log.info("============pull JX3ClientX3D log==================")
        BASE_PATH = r'/sdcard/Android/data/com.seasun.jx3/files'
        CLIENT_LOG_PATH = BASE_PATH + r'/logs/JX3ClientX3D'

        strDate = time.strftime(f"%Y_%m_%d", time.localtime())
        if filecontrol_existFileOrFolder(CLIENT_LOG_PATH):
            self.strClientLog = CLIENT_LOG_PATH+'/'+strDate
            # self.strClientLog = filecontrol_getFolderLastestFile(CLIENT_LOG_PATH+'/'+strDate, self.log_dir_path,self.deviceId,self.package)
            filecontrol_copyFileOrFolder(self.strClientLog, self.asan_log_dir)
        else:
            self.strClientLog='null'
            self.log.info("游戏客户端没有日志产出")  

    def parseAsan(self):
        current_time = datetime.datetime.now().strftime('%Y-%m-%d-%H_%M_%S')  # 当前时间
        device_path = os.path.abspath(os.path.join(os.getcwd(), "../../.."))
        symbols_path = device_path + r'\Pak_Xgame_Andriod_Asan'  # 符号地址
        Asan_log_name = 'output' + current_time + '.txt'
        asan_log_path = os.path.join(self.asan_log_dir, Asan_log_name)
        parse_asan_py = os.path.join(os.getcwd(), "android_asan_symbolize.py")

        cmd = f'python {parse_asan_py} --input {self.log_path} --symbols_dir {symbols_path} > {asan_log_path}'
        p = subprocess.Popen(args=cmd, shell=True,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out, err = p.communicate()  # 等待子进程结束
        self.log.info(f'解析完成：{asan_log_path}')

        strMsg = f'{self.ASAN_KEYWORD}\n解析结果：\\{asan_log_path}'
        self.send_msg.push_markdown_report(self.strMachineName, self.strCaseName, strMsg, asan_log_path)

    def logcat_Asan(self):
        self.log.info('LogcatAsan Start')
        current_date = datetime.datetime.now().strftime('%Y-%m-%d')  # 当前日期
        current_time = datetime.datetime.now().strftime('%Y-%m-%d-%H_%M_%S')  # 当前时间
        device_path = os.path.abspath(os.path.join(os.getcwd(), "../../.."))
        log_name = 'log' + current_time + '.txt'
        self.log_dir_path = os.path.join(device_path + r'\logcat', current_date)
        if not filecontrol_existFileOrFolder(self.log_dir_path):
            filecontrol_createFolder(self.log_dir_path)
        self.log_path = os.path.join(self.log_dir_path, log_name)  # 日志本地位置

        cmd = f'adb -s {self.deviceId} logcat wrap.sh *:S -v time'

        # 构造popen
        p = subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        asan_count = 0
        wait_count = 0
        bAsan = False
        # 执行
        with open(self.log_path, "a", encoding="utf-8") as f:
            self.log.info('Logcat...')
            for line in iter(p.stdout.readline, b''):
                line = line.decode('utf-8', 'ignore')
                # print(line.split("\n")[0])
                line = remove_control_chars(line)
                if '==ERROR: AddressSanitizer' in line:
                    asan_count = asan_count + 1
                    bAsan = True
                    self.log.info(f'检测到Asan信息:{bAsan}')
                if bAsan:
                    print(line.split("\n")[0])
                    f.write(line.split("\n")[0])
                    if "==ABORTING" in line:
                        self.log.info('ABORTING结束')
                        break
                    if 'wrap.sh terminated by exit' in line:
                        f.write('==1111==ABORTING')  # 自己加个结尾
                        self.log.info('游戏结束，加ABORTING')
                        break
                else:
                    if not self.runapp():  # 游戏结束
                        wait_count = wait_count + 1
                        if wait_count == 200:
                            self.log.info(f'当前游戏结束，没有检测到Asan:{bAsan}')
                            break

            p.stdout.close()

        if not bAsan:
            strMsg = f'游戏结束，没有检测到Asan信息'
        else:
            self.log.info("logcat to " + self.log_path)
            # 获取用例名
            file = "CaseInfo.ini"
            self.strCaseName = ini_get('CaseInfo', 'CaseName', file)
            self.log.info(f'游戏用例:{self.strCaseName}')

            self.strMachineName = validate_dirName(self.strMachineName)  # 设备名称作为文件夹名，做下处理
            self.strCaseName = validate_dirName(self.strCaseName)  # 用例名称作为文件夹名，做下处理
            self.asan_log_dir = os.path.join(self.output_Asan, current_date, self.strMachineName, self.strCaseName)
            if not filecontrol_existFileOrFolder(self.asan_log_dir):
                filecontrol_createFolder(self.asan_log_dir)
            filecontrol_copyFileOrFolder(self.log_path, self.asan_log_dir)
            logcat_share_path = os.path.join(self.asan_log_dir, log_name)
            strMsg = f'{self.ASAN_KEYWORD}\nAsan信息数量：{asan_count}, logcat: {logcat_share_path}, 解析中...'
            self.send_msg.push_report(self.strMachineName, strMsg)
            self.parseAsan()  # 解析Asan数据
            self.get_jx3_log()

        self.log.info('LogcatAsan Exit')

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        self.log.info('Asan Monitor 开始')
        self.loadDataFromLocalConfig(dic_args)
        self.log.info('Asan Monitor ')
        while True:
            if not self.runapp():
                time.sleep(3)
                continue
            try:
                self.logcat_clear()
                self.log.info('游戏启动成功，开始监控Asan日志')
                self.logcat_Asan()
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseXgameAsanMonitor()
    obj_test.run_from_uauto(dic_parameters)

if __name__ == '__main__':
    ob = CaseXgameAsanMonitor()
    ob.run_from_IQB()
