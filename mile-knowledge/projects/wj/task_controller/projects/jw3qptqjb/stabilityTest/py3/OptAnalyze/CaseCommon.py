# -*- coding: utf-8 -*-

import time
import threading
import traceback
import queue
from BaseToolFunc import *


class CaseCommon(object):
    def __init__(self):
        self.initLogger()
        self.conn=None
    def initLogger(self):
        try:
            initLog(self.__class__.__name__)
            self.log = logging.getLogger(str(os.getpid()))
        except Exception:
            info = traceback.format_exc()
            print (info)
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
            print (conn)
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
            if dic_msg['task'] == 's2c_do_task':
                self.bRun_local = True
                self.args = dic_msg['args']

    def run_from_IQB(self):
        print('STDOUT')
        try:
            queue_msg = queue.Queue(maxsize=1000)
            obj_conn = Connect('127.0.0.1', 9528, queue_msg)
            obj_conn.connect(no_timeout=True)
            self.conn=obj_conn.conn
            dic_pid = {'pid':os.getpid()}
            self.send_msg_to_c(JsonDump(dic_pid))
            self.bRun_local = False
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

            self.run_local(self.args)

            dic_res = {'result': os.getpid()}
            self.send_msg_to_c(JsonDump(dic_res))

        except Exception:
            info = traceback.format_exc()
            self.log.error(info)

    def teardown(self, dic_args):
        #这里写上销毁清理工作，可以让工作线程安全退出的工作
        pass


    def run_local(self, dic_args):
        #用例的工作内容
        pass


if __name__ == '__main__':
    obj = CaseCommon()
    pass