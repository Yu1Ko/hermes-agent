# -*- coding: utf-8 -*-

import time
import threading
import traceback
import queue
from BaseToolFunc import *

class CaseCommon(object):
    def __init__(self):
        self.initLogger()
        self.conn = None
        self.nStartTimeSeconds=time.time()
        self.strSeparator=GetSystemSeparator()
        self.bExistLog=False
        self.bTeardown=False  #防止多次调用

    def initLogger(self):
        try:
            self.caseLogPath=initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))

        except Exception:
            info = traceback.format_exc()
            print(info)
            raise Exception('initLogger ERROR!!')

    def send_msg_to_c(self, msg):
        conn = self.conn
        if not conn:
            return
        try:
            msg = bytes(msg, encoding='utf8')
            len_msg = len(msg)
            print(len_msg)
            len_msg = struct.pack('i', len_msg)
            conn.send(len_msg)
            conn.send(msg)
            # liuzhu测试:
            self.log.info('send_msg_to_c')
            self.log.info(conn)
            self.log.info(msg)
            print(conn)
            print(msg)
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
            # print('__handleMsg:', dic_msg)
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
        self.send_msg_to_c(JsonDump(dic_res))
        while 1:
            time.sleep(1)

    def task_run_next(self):
        dic_res = {'exceptionMsg': 'TASK_RUNTIME_RUN_NEXT'}
        self.log.info('TASK_RUNTIME_RUN_NEXT')
        self.send_msg_to_c(JsonDump(dic_res))
        while 1:
            time.sleep(1)

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
                if not t.isAlive():
                    if self.bSuccess_run_local:
                        # 通知client，用例正常退出
                        ''''''
                        if not self.bTeardown:
                            self.bTeardown = True
                            self.teardown()
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

    def Upload_Caselogs(self, strCaseName, strMachineName,strServerPath=r'\\10.11.85.148\FileShare-181-242\liuzhu\JX3BVT\CaseLog'):
        try:
            if self.bExistLog:
                return
            self.bExistLog = True
            strDate = date_get_szToday()
            work_dir = os.getcwd()
            TEMP_FOLDER = os.path.join(work_dir, 'TempFolder')
            case_log = os.path.join(work_dir, 'log')
            strCaseName = strCaseName.replace('|', '-')
            strDst = f"{strServerPath}\{strDate}\{strMachineName}\{strCaseName}"
            strDst=sort_filePath(strDst)
            if not filecontrol_existFileOrFolder(strDst):
                filecontrol_createFolder(strDst)
            cleanup_date_folders(strServerPath)
            # 拷贝日志
            #strCaseLogPath=filecontrol_getFolderLastestFile(case_log, strDst)
            filecontrol_copyFileOrFolder(self.caseLogPath,strDst)
            self.log.info(f"LogPath:{self.caseLogPath}")
            '''
            if filecontrol_existFileOrFolder(TEMP_FOLDER):
                target_folder = f'{strDst}\TempFolder'
                filecontrol_copyFileOrFolder(TEMP_FOLDER,target_folder)'''
            self.log.info(f'将用例日志和TempFolder文件夹都拷贝到:{strDst}')
            # 发送通知消息
            #send_Subscriber_msg(self.strGuid, f"用例：{strCaseName}的用例日志和TempFolder文件夹的存放路径:{strDst}")
        except Exception:
            info = traceback.format_exc()
            self.log.error(info)


    def teardown(self):
        # 这里写上销毁清理工作，可以让工作线程安全退出的工作
        self.log.info('CaseCommon_teardown')
        pass

    def overcoat_run_local(self, dic_args):
        try:
            self.run_local(dic_args)
            self.bSuccess_run_local = True
        except Exception:
            self.bSuccess_run_local = False
            info = traceback.format_exc()
            #防止错误日志信息写不到文件里面去
            self.log.info(info)
            self.Upload_Caselogs(self.args['CaseName'], ini_get('local', 'machine_id',os.path.join(self.args['pathClient'],'LocalConfig.ini')))
            self.teardown()
            self.log.error(info)

    def run_local(self, dic_args):
        # 用例的工作内容
        #临时处理 避免client多线程调度问题
        time.sleep(1)
        pass


if __name__ == '__main__':
    obj = CaseCommon()
    pass
