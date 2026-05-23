import random
import time

import openpyxl
import pandas
import zipfile
from testplus import *
from BaseToolFunc import *
PERF_DIR = r'LOG'
PERFEYE_VER = 'Perfeye-3.3.5-release'
logger = logging.getLogger(str(os.getpid()))

#日志解析
#python D:\GitHubProject\JX3\perfeye_decode.py -f  \\10.11.85.148\FileShare\liuzhu\新自动化平台问题处理\Perfeye_2025_11_03_160144.119982.log >F:\test1.txt

def copyPerfeye(PERFEYE_VER,deviceId=None,publicShare=False):
    if sys.platform.startswith('win'):
        perfeye_folder_server = PERFEYE_VER
        perfeye_folder_local = PERFEYE_VER
        if deviceId:
            perfeye_folder_local=f"{perfeye_folder_local}-{deviceId}"

        perfeye_zipfile_server = perfeye_folder_server + '.zip'
        perfeye_zipfile_local=perfeye_folder_local + '.zip'
        root = os.path.realpath(__file__).split('\\')[0]
        root = os.path.join(root, os.sep)
        path_local_perfeye = os.path.join(root, perfeye_zipfile_local)
        print(f'perfeye_path:{path_local_perfeye}')
        path_local_perfeye_folder = os.path.join(root, perfeye_folder_local)
        if os.path.exists(path_local_perfeye_folder):
            pass
        else:
            if os.path.exists(path_local_perfeye):
                os.remove(path_local_perfeye)
            if not publicShare:
                src = os.path.join(r'\\10.11.85.148\FileShare\liuzhu\JX3BVT\Tools', perfeye_zipfile_server)
            else:
                src = os.path.join(r'\\xsjqcres.kingsoft.cn\xsjqcres\liuzhu\Tools', perfeye_zipfile_server)
            dst = path_local_perfeye
            filecontrol_copyFileOrFolder_windows(src, dst)
            import zipfile
            f = zipfile.ZipFile(path_local_perfeye, 'r')
            first_path = f.namelist()[0].strip('/')
            print(first_path)
            print(perfeye_folder_local)
            if first_path != perfeye_folder_local:
                os.makedirs(perfeye_folder_local,exist_ok=True)
                root = path_local_perfeye_folder
            for file in f.namelist():
                print(file, root)
                f.extract(file, root)
        #设置内网数据上传
        strPerfIniPath = os.path.join(path_local_perfeye_folder, "configs.ini")
        if os.path.exists(strPerfIniPath):
            strPerUploadUrl = '"http://10.11.80.126/api/upload"'
            #strPerUploadUrl = '"https://perfeye.testplus.cn/api/upload"'
            #strPerUploadUrl = '"https://perfeye.console.testplus.cn/api/upload"'
            strSection = "Server"
            strKey = "upload_url"
            strUrl = ini_get(strSection, strKey, strPerfIniPath)
            if strUrl != strPerUploadUrl:
                ini_set(strSection, strKey, strPerUploadUrl, strPerfIniPath)
                print(f"perfeye上传地址替换为内网:{strPerUploadUrl} 原始地址:{strUrl}")
            else:
                print(f"perfeye上传地址已经是内网:{strPerUploadUrl}")
        else:
            print(f"未找到perfeye配置文件:{strPerfIniPath}")



class PerfeyeControl(object):
    def __init__(self, deviceId, bPerfeyeTest=False, strMachineTag='Test',nScreenshot_Interval=2,strPackageName=None,strAppKey='yizhiban',strOsVersion=None,Perfeye_ver=None,publicShare=False):
        self.initLogger()
        self.deviceId=deviceId
        self.bPerfeyeTest=bPerfeyeTest
        self.strMachineTag=strMachineTag
        self.strPackageName=strPackageName
        self.testplus=None
        self.nScreenshot_Interval=nScreenshot_Interval
        self.bMobile=True
        self.strAppKey=strAppKey
        self.bPerfeyeStop=False
        self.bPerfeyeStopComplete = False
        self.bPerfeyeSave=False
        self.strOsVersion=strOsVersion
        self.dic_result = {'ret': False, 'data': None}
        self.strException=None
        if self.strMachineTag=='PC':
            self.bMobile=False
        if not Perfeye_ver:
            self.Perfeye_ver = PERFEYE_VER
        else:
            self.Perfeye_ver = Perfeye_ver
        if self.strMachineTag == 'Ios' and self.strOsVersion:
            osVersion = self.strOsVersion.split(".")[0]
            if int(osVersion)>=17:
                #Perfeye_ver = 'Perfeye-3.1.1-release'
                self.Perfeye_ver="Perfeye-3.3.5-release"

        if self.bMobile:
            copyPerfeye(self.Perfeye_ver, self.deviceId,publicShare)
        else:
            copyPerfeye(self.Perfeye_ver,publicShare)

        # 临时Perfey测试环境
        if self.bPerfeyeTest:
            self.Perfeye_ver = "Perfeye-2.1.3-release-test"
        elif self.strMachineTag == 'Test':
            self.Perfeye_ver = self.Perfeye_ver + '-' + self.deviceId
        elif self.bMobile:
            self.Perfeye_ver = self.Perfeye_ver + '-' + self.deviceId
        else:
            self.Perfeye_ver = self.Perfeye_ver

        self.PerfeyeClear()

    def initLogger(self):
        try:
            #initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))
        except Exception:
            info = traceback.format_exc()
            # print(info)
            raise Exception('initLogger ERROR!!')

    def PerfeyeClear(self):
        if not self.bMobile:
            return
        #强制清除相关perfeye进程 防止perfeye残留
        try:
            kill_process_if_cmd_contains(self.Perfeye_ver)
        except Exception:
            info = traceback.format_exc()
            self.log.info(info)

    def PerfeyeCreate(self):
        # Step 1. 打开TPT客户端
        if sys.platform.startswith('win'):
            x = os.path.realpath(__file__)
            root = x.split('\\')[0]
            perfeye_exe_path = os.path.join(root, os.sep, self.Perfeye_ver, 'Perfeye.exe')
            self.testplus = Testplus(perfeye_path=perfeye_exe_path)
        else:
            perfeye_exe_path = filecontrol_find_folder_path('/', 'perfeye-linux')[0]
            self.testplus = Testplus(perfeye_path=perfeye_exe_path,
                                python=os.path.join(perfeye_exe_path, 'venv', 'bin', 'python3'))
        self.log.info(perfeye_exe_path)
        result, error = self.testplus.launch(port=random.randint(10000, 60000), headless=True, timeout=100)

        if not result:
            self.testplus.kill()
            raise Exception('perfeye CreateTPTClient error:{}'.format(error))

    def PerfeyePid(self):
        if self.testplus:
            return self.testplus.pid()
        else:
            return -1

    def PerfeyeConnect(self):
        # Step 3. 获取设备列表
        result, error = self.testplus.get_device_list()
        if not result:
            self.testplus.kill()
            raise Exception('perfeye GetDeviceList error:{}'.format(error))
        self.log.info('perfeye GetDeviceList:{}'.format(result))
        # Step 4. 连接手机
        # PC端package_name必须传None
        dic_configs={}
        if not self.bMobile:
            #PC端采集 Vulkan引擎数据
            dic_configs={"old_jank_counter": False,"graphics_api": 0}
        result, error = self.testplus.connect(self.deviceId, self.strPackageName,configs=dic_configs)
        self.log.info('perfeye connect:{}'.format(result))
        if not result:
            self.testplus.kill()
            raise Exception('perfeye Connect error:{}'.format(error))



        #self.PerfeyeCheckDevice()  2.1.1默认采集CPU温度

    def PerfeyeCheckDevice(self):
        #目前只有android需要调用该接口用于采集cpu温度  需要在Perfeyestart前调用
        if self.strMachineTag=='Android':
            self.testplus.android_check_device(self.deviceId)

    def PerfeyeStart(self,nPid=None):
        '''
        Android
```json
  {
      CPU_USAGE               : 1,  // cpu使用率
      CORE_FREQUENCY          : 2,  // cpu频率
      GPU_USAGE               : 3,  // gpu使用率
      GPU_FREQ                : 4,  // gpu频率
      FPS                     : 5,  // 帧率(必须项)
      NETWORK_USAGE           : 6,  // 网络
      SCREEN_SHOT             : 8,  // 截图
      MEMORY                  : 9,  // 内存
      BATTERY                 : 10, // 电池数据
      CPU_TEMPERATURE         : 11, // cpu温度
      FRAME_TIME              : 12, // 帧间隔(必须项)
      ANDROID_MEMORY_DETAIL   : 13, // 内存详情
      CORE_USAGE              : 14, // cpu多核使用率
      BATTERY_TEMPERATURE     : 19  // 电池温度
      GPU_TEMPERATURE         : 35, // gpu温度
  }
```
iOS
```json
  {
      CPU_USAGE               : 1,  // cpu使用率
      FPS                     : 5,  // 帧率(必须项)
      NETWORK_USAGE           : 6,  // 网络
      SCREEN_SHOT             : 8,  // 截图
      MEMORY                  : 9,  // 内存
      FRAME_TIME              : 12, // 帧间隔(必须项)
      IOS_GPU_USAGE           : 17, // IOS gpu使用率
      CTX_SWITCH              : 15, // IOS SWITCH
      WAKEUP                  : 16, // IOS 唤醒次数
      IOS_ENERGY_USAGE        : 18, // IOS 能耗
      BATTERY_TEMPERATURE     : 19, // IOS 电池温度
      IOS_IO                  : 10001, //IOS  IO读写使用
  }
```

win
```json
  {
      CPU_USAGE               : 1,  // cpu使用率
      CORE_FREQUENCY          : 2,
      GPU_USAGE               : 3,
      GPU_FREQ                : 4,  // gpu频率
      FPS                     : 5,  // 帧率(必须项)
      NETWORK_USAGE           : 6,  // 网络
      SCREEN_SHOT             : 8,  // 截图
      MEMORY                  : 9,  // 内存
      CPU_TEMPERATURE         : 11, // cpu温度
      FRAME_TIME              : 12, // 帧间隔(必须项)
      CORE_USAGE              : 14,
      RENDERER                : 32,
      IO                      : 33,
      LOGIC_FPS               : 34,
      GPU_TEMPERATURE         : 35,
      BOARD_POWER_DRAW        : 36,
      DRAM_BANDWIDTH          : 37, // DRAM_BANDWIDTH
      CPU_CORE_IPC            : 38, // CPU_Core_IPC
      CPU_CORE_FREQ           : 39, // CPU_Core_Freq
      CPU_CORE_CACHE_MISS     : 40, // CPU_CORE_CACHE_MISS
      CPU_CORE_CACHE_HIT_RATIO: 41, // CPU_CORE_CACHE_HIT_RATIO
      CPU_CORE_CACHE_MPI      : 42, // CPU_CORE_CACHE_MPI
      CPU_CORE_TEMP           : 43, // CPU_Core_Temp
      CPU_ENERGY              : 44, // CPU_Energy
      GPA_RENDERER            : 46 // GPA_RENDERER
  }
        '''
        # Step 5. 开始测试
        if self.nScreenshot_Interval:
            nScreenshot_Interval=self.nScreenshot_Interval
        else:
            nScreenshot_Interval = 2
        if self.strMachineTag=='Android':
            data_types = [1, 2, 3, 4, 5, 6, 8, 9,10, 11, 12, 13, 14,19,35]
            # ios端30采集截图
        elif self.strMachineTag == 'Ios':
            #17,18,19,10001
            if not self.nScreenshot_Interval:
                nScreenshot_Interval = 15
            data_types = [1,5, 8, 9, 12,15,16,18,17,19]
        else:
            data_types = [1, 2, 3, 4, 5, 8, 9, 11, 12, 14, 32, 33,34, 35, 36,47]

        if self.bMobile:
            result, error = self.testplus.start(self.deviceId, package_name=self.strPackageName,data_types=data_types ,screenshot_interval=nScreenshot_Interval)
        else:
            result, error = self.testplus.start(self.deviceId, pid=nPid,data_types=data_types,screenshot_interval=nScreenshot_Interval)

        self.log.info('perfeye start:{}'.format(result))
        if not result:
            self.testplus.kill()
            raise Exception('perfeye Start error:{}'.format(error))

    def PerfeyeSetTimeNode(self):
        result, error = self.testplus.start_test_case(self.deviceId,'')
        self.log.info('perfeye start_test_case:{}'.format(result))
        if not result:
            raise Exception('perfeye start_test_case error:{}'.format(error))

    def PerfeyeStop(self):
        # Step 7. 停止测试
        if self.bPerfeyeStop:
            while not self.bPerfeyeStopComplete:
                time.sleep(5)
            return
        self.bPerfeyeStop=True
        result, error = self.testplus.stop(self.deviceId)
        self.log.info('perfeye stop:{}'.format(result))
        self.bPerfeyeStopComplete=True
        if not result:
            print('error:', error)

    def PerfeyeKill(self):
        # 结束进程
        if self.testplus:
            self.testplus.kill()
            # 结束adb设备端口
            if '-' not in self.deviceId and self.deviceId != 'localhost':
                adb_forward_remove(self.deviceId)


    def PerfeyeSave(self,subtags, extraData={}, BVT=True,nMaxRetransmissionCount=3,strVersion='1.0.0'):
        if self.bPerfeyeSave:
            return self.dic_result['ret'], self.dic_result['data']
        #未Save过  先判断一下Stop
        self.PerfeyeStop()
        if not self.strException==None:
            raise Exception(self.strException)

        #等待perfeye_stop完成
        self.bPerfeyeSave=True
        if extraData and not extraData["datalist"]:
            extraData = {}
        if self.strAppKey == 'jx3hd':
            self.strAppKey = 'JX3'
        elif self.strAppKey == 'jx3classic':
            self.strAppKey = 'JX3CLASSIC'
        # Step 8. 保存数据
        folder_datetime = time.strftime('%Y-%m-%d-%H-%M-%S', time.localtime(time.time()))
        if sys.platform.startswith('win'):
            root = os.path.realpath(__file__).split(STRSEPARATOR)[0]
            folder_path = os.path.join(root, os.sep, 'PerfeyeDataSave', folder_datetime)
        else:
            folder_path = os.path.join('/home/test', 'PerfeyeDataSave', folder_datetime)

        if not os.path.exists(folder_path):
            os.makedirs(folder_path)
        report_file_path = os.path.join(folder_path, 'report.xlsx')
        listTags = subtags.split('|')  # subtags such as:10|PC|RTX2080|藏剑山庄_乱世|campfight|2022-08-16
        if len(listTags)>3:
            myScenes = '{}|{}'.format(listTags[3], listTags[4])
        else:
            myScenes =listTags[0]
        self.log.info("saveStart:{}".format(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())))
        #strVersion=get_package_version()
        result=False
        iRetransmissionCount = 0
        #nMaxRetransmissionCount = 3
        nRetSaveData=''
        nRetUploadData=''
        error=''
        while True:
            if not result:
                ''''''
                nRetSaveData = error.find('保存数据成功')
                nRetUploadData = error.find('上传数据成功')
                if nRetUploadData != -1:
                    break
                else:
                    if iRetransmissionCount >= nMaxRetransmissionCount:
                        logger.info('perfeye Save error:{}'.format(error))
                        break
                    if nMaxRetransmissionCount!=1 and iRetransmissionCount == nMaxRetransmissionCount-1:
                        extraData={}
                    iRetransmissionCount += 1
                    if iRetransmissionCount>1:
                        self.log.info('重传次数:{}'.format(iRetransmissionCount))
                    time.sleep(30 * iRetransmissionCount)
                    strTime = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                    logger.info("saveStart retry{}:{}".format(iRetransmissionCount, strTime))
                    result, error = self.testplus.save(self.deviceId, case_name=subtags, scenes=myScenes,  # picture_quality='画质',
                                                  report_file_path=report_file_path,
                                                  need_save=False, need_upload=True, appKey=self.strAppKey, do_upload=BVT,
                                                  extra_data=extraData,version=strVersion)
                    self.log.info("saveEnd retry{}:{}".format(iRetransmissionCount,
                                                            time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())))
            else:
                break
            ret = result
            data = error
            self.dic_result['ret'] = ret
            self.dic_result['data'] = data

        self.log.info("saveEnd:{}".format(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())))
        # processDataForPerfmon(folder_path)
        self.PerfeyeKill()
        return self.dic_result['ret'], self.dic_result['data']
        pass

