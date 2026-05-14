# -*- coding: utf-8 -*-
import os
import time
import threading
import traceback
import queue
from BaseToolFunc import *

class CaseCommon(object):
    def __init__(self):
        #self.initLogger()
        self.conn = None
        self.nStartTimeSeconds=time.time()
        self.strSeparator=GetSystemSeparator()
        self.bExistLog=False
        self.bTeardown=False  #防止多次调用
        self.strExceptionFlag=None #异常标签
        self.bTeardownEnd=False #Teardown调用完成

    def initLogger(self):
        try:
            #设置日志文件名称
            self.caseLogPath=initLog(self.__class__.__name__,GetWorkPath())
            self.log = logging.getLogger(str(os.getpid()))
            self.log.info(self.__class__.__name__)
            self.log.info(self.caseLogPath)

        except Exception:
            info = traceback.format_exc()
            self.log.info(info)
            raise Exception('initLogger ERROR!!')

    def send_msg_to_c(self, msg):
        conn = self.conn
        if not conn:
            return
        try:
            msg = bytes(msg, encoding='utf8')
            len_msg = len(msg)
            self.log.info(len_msg)
            len_msg = struct.pack('i', len_msg)
            conn.send(len_msg)
            conn.send(msg)
            # liuzhu测试:
            self.log.info('send_msg_to_c')
            self.log.info(conn)
            self.log.info(msg)
            self.log.info(conn)
            self.log.info(msg)
        except Exception as e:
            self.log.exception(e)
            # self.obj_conn.closeConn()

    def thread_get_msg_from_queue(self, queue_msg, obj_conn):
        while 1:
            time.sleep(0.1)
            if not obj_conn.conn:
                os._exit(0)
            try:
                msg = queue_msg.get(block=False)
            except queue.Empty:
                continue
            dic_msg = JsonLoad(msg)
            # self.log.info('__handleMsg:', dic_msg)
            # 协议包含task 和 args （arg必需也是一个dic）
            if not ('task' in dic_msg and 'args' in dic_msg):
                self.log.warning('protocol error:miss task or args')
                continue
            if type(dic_msg['args']) != dict:
                self.log.warning('protocol error:args must be dict')
                continue
            self.log.info('task receive:{}'.format(dic_msg['task']))
            if dic_msg['task'] == 's2c_do_task':
                self.bRun_local = True
                self.args = dic_msg['args']
                #self.log.info(self.args)
            if dic_msg['task'] == 's2c_stop_task':
                self.bRun_stop = True

    def task_reset(self):
        dic_res = {'exceptionMsg': 'TASK_RUNTIME_RESET'}
        self.log.info('TASK_RUNTIME_RESET')
        self.strExceptionFlag='TASK_RUNTIME_RESET'

        #self.send_msg_to_c(JsonDump(dic_res))
        #while 1:
            #time.sleep(1)


    def task_run_next(self):
        dic_res = {'exceptionMsg': 'TASK_RUNTIME_RUN_NEXT'}
        self.log.info('TASK_RUNTIME_RUN_NEXT')
        self.strExceptionFlag='TASK_RUNTIME_RUN_NEXT'
        #self.send_msg_to_c(JsonDump(dic_res))
        #while 1:
            #time.sleep(1)

    def SetWorkPath(self,dic_args):
        # 设置相关路径
        dic_devices_data = dic_args["devices_custom"]
        #deviceId = dic_devices_data['local']['deviceId']
        deviceId = dic_args['device']
        # 获取机器类型 Ios Android PC
        list_strMachineType = ['Ios', 'Android', 'PC'] #平台
        tagMachineType=None
        for strMachineType in list_strMachineType:
            if strMachineType.lower()==dic_args["platform"].lower():
                tagMachineType=strMachineType
                break
        if not tagMachineType:
            raise Exception(f"设备类型错误:{self.args['platform']},必须为:'Ios', 'Android', 'PC'")

        strBaseFolder = f"{tagMachineType}-{deviceId}"
        #Android-7a04353e
        strWorkPath = os.path.join(os.getcwd(), strBaseFolder)
        # 工作路径 (controller+strBaseFolder)
        # 脚本路径(原来的py3)
        strScriptPath = os.path.dirname(os.path.realpath(__file__))
        # (controller+strBaseFolder+'TempFolder')
        strTEMPFOLDER = os.path.join(strWorkPath, 'TempFolder')
        SetWorkPath(strBaseFolder,strWorkPath,strScriptPath,strTEMPFOLDER)
        self.initLogger()
        self.log.info(f'strBaseFolder:{strBaseFolder}')
        self.log.info(f'strWorkPath:{strWorkPath}')
        self.log.info(f'strScriptPath:{strScriptPath}')
        self.log.info(f'strTEMPFOLDER:{strTEMPFOLDER}')

    def run_from_uauto(self, dic_parameters):
        #dic_parameters['wda_u2'] = wda_u2
        #dic_parameters['perfeye'] = perfeye
        #dic_parameters['func_add_custom_log_file'] = func_add_custom_log_file
        #参数列表信息:
        '''
         {'python': 'CaseXGameGetPackage.py', 'testpoint': 'getapk', 'saveDate': 4, 'mapid': '1', 'resourceVer': '0', 'file_version': '0', 'runmaptype': 'GetApk', 'casename': 'AutoFly.tab', 'overlay': True, 'nTimeout': 2000, 'auth': 'liuzhu', 'CaseName': 'XGame-Get-APK-IPA-liuzhu', 'account': {}, 'quality': 2, 'WDA_U2': <ad_ios.Wda_u2_operate object at 0x0000024DD87EB040>, 'feishu_bot': <auto_rebot.FeiShutalkChatbot object at 0x0000024DD8787D60>, 'package': 'com.seasun.jx3bvt',
         'device': '3062810644004Z3',
         'devices_custom': {'local': {'machine_id': 'XGame-临时测试-iqooz3', 'deviceId': '3062810644004Z3'}, 'perfmon_info': {'video_level': '4', 'machine_type': 'Android', 'video_card': '小米12'}, 'AutoLogin': {'account': 'qwet12', 'password': '123456', 'RoleName': '', 'school_type': '', 'role_type': '成男', 'StepTime': '10000', 'Switch': '1', 'szDisplayRegion': '测试', 'szDisplayServer': 'autotest', 'CoolTemperature': 50}}, 'appKey': 'jw3qptqjb', 'performance': {'perfeye': {'data_types': [8, 5, 12, 1, 14, 9, 3, 6, 33, 32, 2, 34, 35, 36, 17, 4, 10, 11, 23, 24, 25, 23, 24, 25]}},
         'perfeye_add_label': <bound method Perfeye.Label of <tp.TPlus.Perfeye object at 0x0000024DD87FDD30>>,
         'wda_u2': uiautomator2 object for 127.0.0.1:61996,
         'perfeye': <tp.TPlus.Perfeye object at 0x0000024DD87FDD30>,
         'platform'= #PC android ios
         'func_add_custom_log_file': <bound method Logmanage.add_custom_log_file of <LogManage.Logmanage object at 0x0000024DD8777EE0>>}
        '''
        if 'CaseObject' in dic_parameters:
            dic_parameters['CaseObject']=self
        self.args=dic_parameters
        self.SetWorkPath(dic_parameters)
        self.log.info(dic_parameters)
        self.overcoat_run_local(dic_parameters)

    def run_from_IQB(self):
        try:
            queue_msg = queue.Queue(maxsize=1000)
            str_port = sys.argv[1] if len(sys.argv) > 1 else 9528
            obj_conn = Connect('127.0.0.1', int(str_port), queue_msg)
            obj_conn.connect(no_timeout=True)
            self.conn = obj_conn.conn
            dic_pid = {'pid': os.getpid()}
            self.send_msg_to_c(JsonDump(dic_pid))
            self.bRun_local = False
            self.bRun_stop = False
            t = threading.Thread(target=self.thread_get_msg_from_queue, args=(queue_msg, obj_conn,))
            t.setDaemon(True)
            t.start()

            timeStartRun = time.time()
            while 1:
                time.sleep(0.1)
                if not self.bRun_local:
                    if time.time() - timeStartRun > 10:
                        raise Exception('time out:no do_task args')
                else:
                    break
            self.bSuccess_run_local = False
            t = threading.Thread(target=self.overcoat_run_local, args=(self.args,))
            t.setDaemon(True)
            t.start()
            while 1:
                time.sleep(0.1)
                if not t.is_alive():
                    if self.bSuccess_run_local:
                        # 通知client，用例正常退出
                        dic_res = {'result': os.getpid()}
                        self.send_msg_to_c(JsonDump(dic_res))
                    break
                elif self.bRun_stop:
                    break
            if not self.bTeardown:
                self.bTeardown=True
                self.teardown()
            self.log.info("run_from_IQB end")
            #防止client出现处理状态不同步的问题
            time.sleep(0.5)
            os._exit(0)

        except Exception:
            info = traceback.format_exc()
            self.log.error(info)
            os._exit(0)

    def Upload_Caselogs(self, strCaseName='test', strMachineName='test',strServerPath=r'/mnt/BaseShare/FileShare-181-242/liuzhu/JX3BVT/CaseLog'):
        try:
            if self.bExistLog:
                return
            if strOS == 'Windows':
                strServerPath = r'\\10.11.85.148\FileShare-181-242\liuzhu\JX3BVT\CaseLog'
            self.bExistLog = True
            strDate = date_get_szToday()
            work_dir = os.getcwd()
            TEMP_FOLDER = os.path.join(work_dir, 'TempFolder')
            case_log = os.path.join(work_dir, 'log')
            strCaseName = strCaseName.replace('|', '-')
            strDst = f"{strServerPath}{os.sep}{strDate}{os.sep}{strMachineName}{os.sep}{strCaseName}"
            strDst = sort_filePath(strDst)
            '''
            if not filecontrol_existFileOrFolder(strDst):
                filecontrol_createFolder(strDst)
            cleanup_date_folders(strServerPath)'''
            # 拷贝日志
            #strCaseLogPath=filecontrol_getFolderLastestFile(case_log, strDst)

            self.args['func_add_custom_log_file'](self.caseLogPath)
            #filecontrol_copyFileOrFolder(self.caseLogPath, strDst)
            self.log.info(f"LogPath:{self.caseLogPath}")
            #if filecontrol_existFileOrFolder(TEMP_FOLDER):
                #target_folder = f'{strDst}\TempFolder'
            #self.log.info(f'将用例日志和TempFolder文件夹都拷贝到:{strDst}')

            '''
            filecontrol_copyFileOrFolder(self.caseLogPath,strDst)'''
            '''
            if filecontrol_existFileOrFolder(TEMP_FOLDER):
                target_folder = f'{strDst}\TempFolder'
                filecontrol_copyFileOrFolder(TEMP_FOLDER,target_folder)
            self.log.info(f'将用例日志和TempFolder文件夹都拷贝到:{strDst}')'''
            # 发送通知消息
            #send_Subscriber_msg(self.strGuid, f"用例：{strCaseName}的用例日志和TempFolder文件夹的存放路径:{strDst}")'''
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)


    def teardown(self):
        # 这里写上销毁清理工作，可以让工作线程安全退出的工作
        self.log.info('CaseCommon_teardown')
        if self.strExceptionFlag is not None:
            strExceptionFlag = self.strExceptionFlag
            self.strExceptionFlag = None
            raise Exception(strExceptionFlag)
        self.bTeardownEnd=True
        pass

    def overcoat_run_local(self, dic_args):
        try:
            self.run_local(dic_args)
            self.bSuccess_run_local = True
            self.Upload_Caselogs(self.args['name'], self.args['device_name'])
            if not self.bTeardown:
                self.bTeardown=True
                self.teardown()
        except SystemExit as e:
            #用例取消
            self.bSuccess_run_local = False
            self.log.info("用例取消 执行清理操作")
            self.Upload_Caselogs(self.args['name'], self.args['device_name'])
            if not self.bTeardown:
                self.bTeardown = True
                self.teardown()
            #raise Exception(e)

        except Exception as e:
            self.bSuccess_run_local = False
            info = traceback.format_exc()
            #防止错误日志信息写不到文件里面去
            self.log.info(info)
            self.Upload_Caselogs(self.args['name'], self.args['device_name'])
            if not self.bTeardown:
                self.bTeardown = True
                self.teardown()
            raise Exception(e)
            #self.log.error(info)

    def run_local(self, dic_args):
        # 用例的工作内容
        #临时处理 避免client多线程调度问题
        time.sleep(1)
        pass


if __name__ == '__main__':
    obj = CaseCommon()
    pass
