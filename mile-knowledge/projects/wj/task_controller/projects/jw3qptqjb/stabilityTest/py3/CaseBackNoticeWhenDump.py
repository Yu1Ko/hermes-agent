# -*- coding: utf-8 -*-
from CaseCommon import *
import os
import time
import datetime
import traceback
from ctypes import cdll


# class Sms():
#     '''由来信码提供付费服务http://imlaixin.cn
#     要先在微信号上绑定手机号，发送消息优先发送来信码app，如果没有发送绑定微信，最后发送短信'''
#     accesskey = "5776"
#     secretkey = "9ec1433a93043ec3fb9daaf8da78f86c3ca8fc45"

#     def sms_send_to(self, phone, content):
#         url = "http://imlaixin.cn/Api/send/data/json?accesskey=" + self.accesskey + "&secretkey=" + self.secretkey + "&mobile=" + phone + "&content=" + content
#         req = urllib2.Request(url)
#         resp = urllib2.urlopen(req)
#         str = resp.read()

class CaseBackNoticeWhenDump(CaseCommon):
    def __init__(self):
        super().__init__()
        self.name = None
        self.dump_folder = [
            r'Jx3Debugger',
            r'JX3_EXP_inner',
            r'trunk_mobile',
            r'JX3YQ_EXP_inner'
        ]
        self.list_minidump_folder = []
        self.list_log_path = []  # 列出客户端log的路径
        disks = psutil.disk_partitions()
        for disk in disks:
            for temp in self.dump_folder:
                path = disk.mountpoint + temp
                if os.path.exists(path):

                    path_log = ''
                    if temp == r'JX3_EXP_inner':
                        path_log = path + r'\Game\JX3_EXP\bin\zhcn_exp\logs\JX3Client_2052-zhcn'
                    if temp == r'trunk_mobile':
                        path_log = path + r'\client\logs\JX3Client_2052-zhcn'
                    if temp == r'JX3YQ_EXP_inner':
                        path_log = path + r'\Game\JX3_CLASSIC_EXP\bin\Classic_exp\logs\JX3Client_2052-classic'

                    if temp == r'JX3_EXP_inner':
                        path += r'\Game\JX3_EXP\bin\zhcn_exp\bin64\minidump'
                    elif temp == r'trunk_mobile':
                        path += r'\client\bin64\minidump'
                    elif temp == r'JX3YQ_EXP_inner':
                        path += r'\Game\JX3_CLASSIC_EXP\bin\Classic_exp\bin64\minidump'

                    self.list_minidump_folder.append(path)
                    self.list_log_path.append(path_log)
                else:
                    continue

    def getDumpInFolder(self, folderpath):
        if not os.path.exists(folderpath):
            return False
        items = os.listdir(folderpath)
        for names in items:
            if names.endswith(".dmp") and len(names) > 4:
                return os.path.join(folderpath, names)
        return None

    def wait_for_close(self, filename):
        # _sopen = cdll.msvcrt._sopen
        # _close = cdll.msvcrt._close
        # _SH_DENYRW = 0x10
        # if not os.access(filename, os.F_OK):
        #     print ("file doesn't exist")
        #     return False # file doesn't exist
        # while 1:
        #     time.sleep(1)
        #     h = _sopen(filename, 0, _SH_DENYRW, 0)
        #     if h == 3:
        #         _close(h)
        #         return False # file is not opened by anyone else
        # return True # file is already open
        t = time.time()
        while 1:
            if time.time() - t > 60:
                info = 'time out! wait_for_close:{}'.format(filename)
                self.log.info(info)
                os._exit(0)
            time.sleep(1)
            if os.path.getsize(filename) == 0:
                info = 'wait_for_close:{}, size is 0'.format(filename)
                self.log.info(info)
                continue
            try:
                with open(filename, 'r+') as f:
                    return
            except:
                info = traceback.format_exc()
                self.log.warning(info)
            info = 'wait_for_close:{}'.format(filename)
            self.log.info(info)

    def loadDataFromLocalConfig(self, dic_args):
        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        try:
            self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
        except:
            self.strMachineName = ''

    # 获取宕机日志
    def getDumpLog(self):
        for path_log in self.list_log_path:
            current_data = datetime.datetime.now().strftime('%Y_%m_%d')
            path_log = os.path.join(path_log, current_data)
            if os.path.exists(path_log):
                lists = os.listdir(path_log)
                num = len(lists)
                if num > 0:
                    lists.sort(key=lambda fn: os.path.getmtime(path_log + "\\" + fn))
                    path_log = os.path.join(path_log, lists[-1])
                    return path_log
                else:
                    return ''

    def run_local(self, dic_args):
        self.loadDataFromLocalConfig(dic_args)
        while 1:
            time.sleep(2)
            try:
                for folder in self.list_minidump_folder:
                    dump_full_path = self.getDumpInFolder(folder)
                    if not dump_full_path:
                        continue
                    if 'Jx3Debugger' in folder:
                        dumpToolType = 'Jx3Debugger'
                    else:
                        dumpToolType = 'client'
                    # 发送几号机器有宕机
                    strMachineName = self.strMachineName
                    IP = machine_get_IPAddress()
                    strFeishuMachineName = '【{}|{}】'.format(strMachineName, IP)
                    info = '{}发生了宕机'.format(strFeishuMachineName)
                    send_Subscriber_msg(IP, info)
                    jpeg_fuul_path = printscreen(folder)

                    # 获取宕机日志
                    dmp_log = self.getDumpLog()

                    # 创建一个标记文件，用于让运行游戏的用例等待本脚本处理完dump。
                    dumpFlagFilePath = os.path.join(folder, 'dumpIsProcessing')
                    with open(dumpFlagFilePath, 'w'):  # 创建一个标记文件。
                        pass

                    # time.sleep(5)
                    # 等待dmp文件写完
                    self.wait_for_close(dump_full_path)

                    win32_kill_process("DumpReport64.exe")
                    win32_kill_process("WerFault.exe")
                    win32_kill_process("PerformanceTool.exe")
                    win32_kill_process("PerfMon.exe")
                    win32_kill_process("JX3clientX64.exe")
                    win32_kill_process('JX3ClientX3DX64.exe')
                    win32_kill_process('JX3Debugger.exe')

                    time1_str = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')

                    MACHINE_ID = ini_get('local', 'id', self.pathLocalConfig)
                    if 'clientType' in dic_args:
                        dirNameServer = os.path.join(SERVER_DUMPRECORD,time1_str + "-{}-{}-{}".format(MACHINE_ID, dumpToolType,dic_args['clientType']))
                    else:
                        dirNameServer = os.path.join(SERVER_DUMPRECORD,time1_str + "-{}-{}".format(MACHINE_ID, dumpToolType))
                    # 剪切dmp和jpg文件到共享
                    if not os.path.exists(dirNameServer):
                        os.makedirs(dirNameServer)
                    filecontrol_copyFileOrFolder(dump_full_path, dirNameServer)
                    filecontrol_deleteFileOrFolder(dump_full_path)
                    if jpeg_fuul_path:
                        filecontrol_copyFileOrFolder(jpeg_fuul_path, dirNameServer)
                        filecontrol_deleteFileOrFolder(jpeg_fuul_path)

                    # 剪切日志到共享
                    if dmp_log:
                        filecontrol_copyFileOrFolder(dmp_log, dirNameServer)

                    # 标记文件删除，表示dump处理完毕。
                    filecontrol_deleteFileOrFolder(dumpFlagFilePath)



            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
                if type(e) is WindowsError:
                    error_code = int(re.findall(r"\[Error (\w+)]", str(e))[0])
                    codemap = {
                        1: '不正确的函数。',
                        2: '系统无法找到指定的文件。',
                        3: '系统无法找到指定的目录。',
                        4: '系统无法打开该文件。',
                        5: '访问被拒绝。',
                        64: '指定的网络名不再可用。',
                        65: '网络访问被拒绝。'
                    }
                    send_Subscriber_msg(machine_get_IPAddress(), (
                        "%s: 共享访问出错，宕机分析上传失败，请处理： \n%s") % (MACHINE_ID, codemap[error_code]))
                break


if __name__ == '__main__':
    ob = CaseBackNoticeWhenDump()
    ob.run_from_IQB()