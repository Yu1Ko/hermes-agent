# import fcntl
import importlib
import os
import random
import re
import shutil
import time
import traceback
import sys
import tp.Testplus
from utils.tools import *
# from u3driver import AltrunUnityDriver, By
def getFileOrFolderTypeInNT(file_dire):
    if file_dire.find('/'):  # 使目录结构统一为反斜杠
        file_dire = file_dire.replace('/', '\\')

    (file_names, file_name) = os.path.split(file_dire)  # 分别获取文件的目录和文件名
    dir_cmd = 'dir ' + file_names
    file_text = os.popen(dir_cmd)  # 读取文件结构
    for demo in file_text:
        demo = demo
        if demo.count(file_name) > 0:
            a = re.compile(r"[<](.*?)[>]", re.S)
            b = re.findall(a, demo)
            if not b:
                return ('file')
            link_case = re.compile(r"[[](.*?)[]]", re.S)
            link_demo = re.findall(link_case, demo)  # 获取指定的链接地址
            if len(link_demo) > 0:  # 判断是否链接是否存在
                return (b[0], link_demo[0])
            else:
                return (b[0])  # 返回类型值

def filecontrol_mklink(target, link):
    if not os.path.exists(target):
        print(target)
        raise Exception(u'filecontrol_mklink no target:{}'.format(target))
    if os.name == 'nt':
        if os.path.isfile(target):
            cmd = 'mklink "{}" "{}"'.format(link, target)
        else:
            cmd = 'mklink /J "{}" "{}"'.format(link, target)
        print(cmd)
        os.system(cmd)
    elif os.name == 'posix':
        cmd = 'ln -s {} {}'.format(target, link)
        os.system(cmd)

def filecontrol_copyFileOrFolder_windows(src, dst):
    if not os.path.exists(src):
        raise Exception(u'filecontrol_copyFileOrFolder_windows no src:{}'.format(src))
    dst_dirname = os.path.dirname(os.path.abspath(dst))

    if not os.path.exists(dst_dirname):
        os.makedirs(dst_dirname)
    if os.path.isfile(src):
        res = getFileOrFolderTypeInNT(src)
        if not res or len(res) != 2:
            shutil.copy(src, dst)
        else:
            link_target = res[1]
            filecontrol_mklink(link_target, dst)
    else:
        res = getFileOrFolderTypeInNT(src)
        if not res or len(res) != 2:
            for fileorfloder in os.listdir(src):
                filecontrol_copyFileOrFolder_windows(os.path.join(src, fileorfloder), os.path.join(dst, fileorfloder))
        else:
            link_target = res[1]
            filecontrol_mklink(link_target, dst)
    return True


def copyPerfeye(PERFEYE_VER,deviceId=None):
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
            src = os.path.join(r'\\10.11.85.148\FileShare\liuzhu\JX3BVT\Tools', perfeye_zipfile_server)
            dst = path_local_perfeye
            filecontrol_copyFileOrFolder_windows(src, dst)
            import zipfile
            f = zipfile.ZipFile(path_local_perfeye, 'r')
            first_path = f.namelist()[0].strip('/')
            print(first_path)
            print(perfeye_folder_local)
            if first_path != perfeye_folder_local:
                os.makedirs(perfeye_folder_local)
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


class Perfeye:

    def __init__(self, Perfeye_ver = 'Perfeye-2.1.11-release',deviceId=None):
        module=importlib.reload(tp.Testplus)
        #print("Perfeye存在-ttttttttttttttttttt")
        if sys.platform.startswith('win'):
            x = os.path.realpath(__file__)
            root = x.split('\\')[0]
            #处理perfeye版本 没有就重新拷贝
            copyPerfeye(Perfeye_ver,deviceId)
            if deviceId:
                Perfeye_ver=f"{Perfeye_ver}-{deviceId}"
            perfeye_exe_path = os.path.join(root, os.sep, Perfeye_ver, 'Perfeye.exe')
            self.testplus = module.Testplus(perfeye_path=perfeye_exe_path)

        else:
            self.perfeye_path = '/root/perfeye' if os.path.exists("/root/perfeye/") else "/home/perfeye"
            if os.path.exists(self.perfeye_path):
                pass
            else:
                self.perfeye_path = ''
            if os.path.exists(f"{self.perfeye_path}/venv/bin/python"):
                self.testplus = module.Testplus(perfeye_path=f"{self.perfeye_path}/basicprof",python=f"{self.perfeye_path}/venv/bin/python")
            else:
                self.testplus = module.Testplus(perfeye_path=f"{self.perfeye_path}/basicprof",python=f"/basicprof/venv/bin/python")

        self.serial = ""
        self.perfeye_is_run = False
        self.app_info = None
        self.data_types = None
        self.dic_extraData = {}
        self.bPerfeyeStop = False
        self.bPerfeyeSave = False
        self.dic_result = {'ret':False,'data':None}
        self.nScreenshot_Interval = 2
        self.bMobile=True
        self.strPackageName=None
        random.seed(time.time())

    def set_platform(self, platform):
        self.platform = platform
        if self.platform=='PC':
            self.bMobile=False

    def set_extraData(self, dic_extraData):
        self.dic_extraData = dic_extraData

    def set_Paramter(self, casename, scenes=None, picture_quality=None, do_upload=True, appKey=None, IsFlashBack=False,
                     version=None, timeout=600, parameters=None, Android_IOS=None):
        print('Perfeye: set_Paramter')
        self.casename = casename
        self.scenes = scenes
        self.picture_quality = picture_quality
        self.do_upload = do_upload
        self.appKey = appKey
        self.version = version
        self.timeout = timeout
        self.parameters = parameters
        self.Android_IOS = Android_IOS


    def set_SaveDataParamter(self, casename, scenes=None, picture_quality=None, do_upload=True, version=None):
        self.casename = casename
        self.scenes = scenes
        self.picture_quality = picture_quality
        self.do_upload = do_upload
        self.version = version

    def PreInit(self, appium_driver, port, package_name=None, dict={}):
        self.serial = appium_driver
        self.data_types = dict['data_types']
        self.strPackageName=package_name
        client = self.testplus.launch(port=port, headless=True)
        launch = client
        result, error = launch
        driver = appium_driver
        print('************设备号***************\n', driver)
        print(result)
        print(error)
        # result, error = testplus.launch(port=random.randint(9132, 9936), headless=True)
        if not result:
            print("Error: %s" % error)
            self.testplus.kill()
            raise Exception("perfeye:tp模块启动失败")
        nRetryCnt=3
        for itimes in range(nRetryCnt):
            # Step 1. 打开TPT客户端
            if itimes == nRetryCnt-1:
                self.testplus.kill()
                raise Exception(f"重复{nRetryCnt}次仍不能初始化perfeye")

            # # Step 2. 登录
            # result, error = self.testplus.login(user="yuanpanpan", password="YPP521314.")
            # print('login', result)
            # if not result:
            #     print('error:', error)
            #     if not result:
            #         feishu().send_text(driver+'login:False')
            #     self.testplus.kill()
            #     continue

            '''
            device_ready = False

            device_list, error = self.testplus.get_device_list()
            if device_list == None:
                time.sleep(6)
                continue

            for device in device_list:
                if device["serial"] == self.serial:
                    device_ready = True
                    break

            if not device_ready:
                time.sleep(6)
                continue'''

            # Step 4. 连接手机
            print(f"testplus.connect deviceID:{self.serial}")
            print(package_name)
            dic_configs = {}
            if not self.bMobile:
                # PC端采集 Vulkan引擎数据
                dic_configs = dict['dic_configs']
                pass
            result, error, app_info = self.testplus.connect(self.serial, package_name,configs=dic_configs)
            self.app_info = app_info
            print(f"testplus.connect result:{result} error:{error} appinfo{app_info}")
            time.sleep(2)
            if not result:
                print('error:', error)
                # self.testplus.kill()
                continue
            break
        '''
        try:
            if self.platform == 'android':
                result, data = self.testplus.android_check_device(self.serial)
                msg = data['result']['msg']
                if "QComGpuCounter" in msg and msg["QComGpuCounter"]:
                    self.data_types.extend([23, 24, 25])
                elif "PVRGpuCounter" in msg and msg["PVRGpuCounter"]:
                    self.data_types.extend([26, 27, 28])
                elif "MaliGpuCounter" in msg and msg["MaliGpuCounter"]:
                    self.data_types.extend([20, 21, 22, 45])
        except Exception as e:
            print(e)'''

    def Start(self, screenshottime):
        # Step 5. 开始测试

        result, error = self.testplus.start(self.serial, data_types=self.data_types, app_info=self.app_info,
                                            screenshot_interval=screenshottime)

        print('start', result)
        if not result:
            print('error:', error)
            self.testplus.kill()
            raise Exception(f"采集初始化失败")
        extra_data = {
            "baseinfo": {},
            "datalist": [],
        }
        print("wait for testing", end="")
        i = 0
        while i < 10:
            print(".", end="", flush=True)
            i += 1
            time.sleep(1)
        print("")
        self.perfeye_is_run = True

    def set_StartParamter(self,data_types=None,nScreenshot_Interval=None,bMoblile=None):
        # Step 5. 开始测试
        if data_types:
            self.data_types=data_types
        if nScreenshot_Interval:
            self.nScreenshot_Interval=nScreenshot_Interval
        if bMoblile is not None:
            self.bMoblile=bMoblile

    def PerfeyeStart(self, nPid=None,data_types=None,nScreenshot_Interval=None,bMobile=None):

        # Step 5. 开始测试
        if data_types:
            self.data_types = data_types
        if nScreenshot_Interval:
            self.nScreenshot_Interval = nScreenshot_Interval

        if bMobile is not None:
            self.bMobile=bMobile

        if self.bMobile:
            result, error = self.testplus.start(self.serial, package_name=self.strPackageName,data_types=self.data_types,
                                                screenshot_interval=self.nScreenshot_Interval)
        else:
            result, error = self.testplus.start(self.serial, pid=nPid, data_types=self.data_types,screenshot_interval=self.nScreenshot_Interval)

        print('perfeye start:{}'.format(result))
        if not result:
            self.testplus.kill()
            raise Exception('perfeye Start error:{}'.format(error))
        self.perfeye_is_run = True


    def GetPid(self):
        if self.testplus:
            return self.testplus.pid()

    def Label(self, label):
        # Step 增加label
        result, error = self.testplus.add_label(self.serial, label)
        print('add_label', result)
        if not result:
            print('error:', error)
            # self.testplus.kill()
            raise Exception(f"{label}-打点失败")

    def PerfeyeSetTimeNode(self):
        result, error = self.testplus.start_test_case(self.serial, '')
        print('perfeye start_test_case:{}'.format(result))
        if not result:
            raise Exception('perfeye start_test_case error:{}'.format(error))

    def PerfeyeStop(self):
        # Step 7. 停止测试
        if self.bPerfeyeStop:
            return
        self.bPerfeyeStop = True
        result, error = self.testplus.stop(self.serial)
        print('perfeye stop:{}'.format(result))
        if not result:
            raise Exception('perfeye Stop error:{}'.format(error))

    def PerfeyeSave(self, subtags, extraData={}, picture_quality="低", BVT=True, strVersion='1.0.0',bPerfeyeDataSave=False,nMaxRetransmissionCount = 3):
        # Step 6. 停止测试
        result = None
        error = "闪退检测"
        self.casename = subtags
        self.do_upload = BVT
        self.version = strVersion
        self.picture_quality = picture_quality
        if self.perfeye_is_run:
            if self.bPerfeyeSave:
                return
            # 未Save过  先判断一下Stop
            self.PerfeyeStop()
            self.bPerfeyeSave = True
            print('stop', result)
            print(error)
            listTags = subtags.split('|')  # subtags such as:10|PC|RTX2080|藏剑山庄_乱世|campfight|2022-08-16
            myScenes = '{}|{}'.format(listTags[3], listTags[4])
            self.scenes=myScenes

            result = False
            iRetransmissionCount = 0
            # nMaxRetransmissionCount = 3
            nRetSaveData = ''
            nRetUploadData = ''
            error = ''
            try:
                while True:
                    if not result:
                        ''''''
                        nRetSaveData = error.find('保存数据成功')
                        nRetUploadData = error.find('上传数据成功')
                        if nRetUploadData != -1:
                            break
                        else:
                            if iRetransmissionCount >= nMaxRetransmissionCount:
                                print('perfeye Save error:{}'.format(error))
                                break
                            if nMaxRetransmissionCount != 1 and iRetransmissionCount == nMaxRetransmissionCount - 1:
                                extraData = {}
                            iRetransmissionCount += 1
                            if iRetransmissionCount > 1:
                                print('重传次数:{}'.format(iRetransmissionCount))
                            time.sleep(30 * iRetransmissionCount)
                            strTime = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                            print("saveStart retry{}:{}".format(iRetransmissionCount, strTime))
                            result, error = self.testplus.save(self.serial, case_name=self.casename, scenes=self.scenes,
                                                               # picture_quality='画质',
                                                               need_save=False, need_upload=True, appKey=self.appKey,
                                                               do_upload=self.do_upload,
                                                               extra_data=extraData, version=strVersion)
                            print("saveEnd retry{}:{}".format(iRetransmissionCount,time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())))
                    else:
                        break

                ret = result
                data = error
                print('save', result)
                if not result:
                    print('error:', error)
                    # shutil.copyfile(f'{self.perfeye_path}/basicprof/data/report/{serial}.v2.db',f'{self.perfeye_path}/basicprof/data/report/{serial}_{time.time()}.v2.db')
                # Step 8. 断开手机连接
                result, error = self.testplus.disconnect(self.serial)
                print('disconnect', result)
                if not result:
                    print('error:', error)
                time.sleep(3)
                self.testplus.kill()
                self.dic_result['ret'] = ret
                self.dic_result['data'] = data
                return ret, data
            except Exception as e:
                info = traceback.format_exc()
                print(info)
                self.testplus.kill()
        else:
            print("未开始采集不需要上传数据")
            #time.sleep(3)
            self.testplus.kill()
            self.dic_result['ret'] = True
            self.dic_result['data'] = ""
            return True, ""

    # stop和save合并了
    def Stop(self, casename, scenes=None, picture_quality=None, do_upload=None, appKey=None, IsFlashBack=False,
             version=None, timeout=600, parameters=None, Android_IOS=None):

        # Step 6. 停止测试
        result = None
        error = "闪退检测"
        if self.perfeye_is_run:
            if self.bPerfeyeSave:
                return self.dic_result['ret'], self.dic_result['data']
            # 未Save过  先判断一下Stop
            self.PerfeyeStop()
            self.bPerfeyeSave = True
            print('stop', result)
            print(error)

            try:
                result, error = self.testplus.save(self.serial, case_name=self.casename, scenes=self.scenes,
                                                   picture_quality=self.picture_quality, do_upload=self.do_upload, appKey=self.appKey,
                                                   version=self.version, timeout=self.timeout, parameters=self.parameters,
                                                   Android_IOS=self.Android_IOS, extra_data=self.dic_extraData)
                ret = result
                data = error
                print('save', result)
                if not result:
                    print('error:', error)
                    # shutil.copyfile(f'{self.perfeye_path}/basicprof/data/report/{serial}.v2.db',f'{self.perfeye_path}/basicprof/data/report/{serial}_{time.time()}.v2.db')
                # Step 8. 断开手机连接
                result, error = self.testplus.disconnect(self.serial)
                print('disconnect', result)
                if not result:
                    print('error:', error)
                time.sleep(3)
                print(f'testplus.kill start')
                self.testplus.kill()
                print(f'testplus.kill stop')
                self.dic_result['ret'] = ret
                self.dic_result['data'] = data
                return ret, data
            except Exception as e:
                info = traceback.format_exc()
                print(info)
                self.testplus.kill()

        else:
            print("未开始采集不需要上传数据")
            time.sleep(3)
            self.testplus.kill()
            self.dic_result['ret'] = False
            self.dic_result['data'] = ""
            return False, ""


    def PerfeyeKill(self):
        # 结束进程
        if self.testplus:
            self.testplus.kill()
            # 结束adb设备端口
            #if '-' not in self.deviceId and self.deviceId != 'localhost':
                #adb_forward_remove(self.deviceId)


