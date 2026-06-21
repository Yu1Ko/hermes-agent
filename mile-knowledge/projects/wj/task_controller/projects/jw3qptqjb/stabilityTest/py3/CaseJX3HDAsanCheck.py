# -*- coding: utf-8 -*-
from CaseCommon import *
import os
import time
import datetime
import traceback
from SendAsanMsg import SendAsanMsg
from ctypes import cdll


def validate_dirName(caseName):
    rstr = r"[\/\\\:\*\?\"\<\>\|]"  # '/ \ : * ? " < > |'不能存在于文件夹名或文件名中,因此替换
    new_title = re.sub(rstr, "_", caseName)  # 替换为下划线
    new_title = re.sub(r"\s+", "", new_title)  # 去除空格（否则命令行会出错）
    return new_title


class CaseJX3HDAsanCheck(CaseCommon):
    def __init__(self):
        super().__init__()
        self.Save_Log_Path = None
        self.R3_LOG_PATH = None
        self.DX_LOG_PATH = None
        self.new_jx3_log_path = None
        self.JX3_LOG_PATH = None
        self.strCaseName = None
        self.BASE_R3_PATH = None
        self.R3ClientPID = None
        self.BIN_R3_PATH = None
        self.BIN64_NAME = 'bin64_Asan'
        self.saveTime = time.strftime("%Y%m%d", time.localtime())
        self.FileShare_PATH = r'\\10.11.181.242\FileShare\丁水娇\Asan问题日志'
        self.send_msg = SendAsanMsg()
        self.ASAN_KEYWORD = None
        self.DX_KEYWORD = None
        self.name = None
        self.dump_folder = [
            r'trunk',
        ]
        self.server_dumprecode = r"\\10.11.181.242\FileShare\丁水娇\Asan问题日志"
        self.list_minidump_folder = []
        self.list_log_path = []  # 列出客户端log的路径
        self.client_path = ''  # 客户端路径
        disks = psutil.disk_partitions()
        for disk in disks:
            for temp in self.dump_folder:
                path = disk.mountpoint + temp
                if os.path.exists(path):

                    path_log = ''
                    if temp == r'trunk':
                        path_log = path + r'\client\logs\JX3Client_2052-zhcn'
                        path += r'\client\bin64_Asan\minidump'
                        if not filecontrol_existFileOrFolder(self.server_dumprecode):
                            filecontrol_createFolder(self.server_dumprecode)
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

    def KeepAndRestoreSiteDump(self):
        # 发送几号机器有特殊宕机,提醒查看现场
        strMachineName = self.strMachineName
        IP = machine_get_IPAddress()
        strFeishuMachineName = '【{}|{}】'.format(strMachineName, IP)
        info = '{}发生了宕机,dump大小小于10MB'.format(strFeishuMachineName)
        send_Subscriber_msg(IP, info)
        restore_mark_file_path = os.path.join(self.client_path, 'restoreSite.txt')
        # 保留现场
        while not (os.path.exists(restore_mark_file_path)):
            time.sleep(5)
        # 删除标记恢复现场的文件，表示恢复现场。
        filecontrol_deleteFileOrFolder(restore_mark_file_path)

    def wait_for_close(self, filename):
        t_all = time.time()
        t = time.time()
        dump_size = 0
        while 1:
            time.sleep(5)
            if time.time() - t_all > 10 * 60:
                info = 'dump wait_for_close 已经10分钟了'
                self.log.error(info)
            if time.time() - t > 30:
                # 每30秒查看一次dump大小，如果大小没有变就认为写完了
                curr_size = os.path.getsize(filename)
                f_size = curr_size / float(1024 * 1024)
                if curr_size == dump_size and f_size < 10:
                    self.KeepAndRestoreSiteDump()
                if curr_size == dump_size:
                    return True
                dump_size = curr_size
                t = time.time()

    def loadDataFromLocalConfig(self, dic_args):
        self.ASAN_KEYWORD = "[" + machine_get_IPAddress() + "]" + "Asan内存安全检查"
        self.DX_KEYWORD = "[" + machine_get_IPAddress() + "]" + "DX验证层检查"

        self.pathLocalConfig = os.path.join(dic_args['pathClient'], 'LocalConfig.ini')
        try:
            self.strMachineName = ini_get('local', 'machine_id', self.pathLocalConfig)
        except:
            self.strMachineName = ''
        self.log.info(f'机器: {self.strMachineName}')

        self.BASE_R3_PATH = r'f:/R3MessageMonitor'
        if not os.path.exists(self.BASE_R3_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'R3MessageMonitor'
                if os.path.exists(path):
                    self.BASE_R3_PATH = path
                    break

        self.BIN_R3_PATH = self.BASE_R3_PATH + r'\bin'
        r3path = self.BIN_R3_PATH


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

    def save_log_file(self, log_path, type):
        # 获取用例名
        file = "CaseInfo.ini"
        self.strCaseName = ini_get('CaseInfo', 'CaseName', file)
        self.log.info(f'游戏用例:{self.strCaseName}')

        self.strMachineName = validate_dirName(self.strMachineName)  # 设备名称作为文件夹名，做下处理
        self.strCaseName = validate_dirName(self.strCaseName)  # 用例名称作为文件夹名，做下处理

        time1_str = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')

        dirNameServer = os.path.join(self.FileShare_PATH, self.saveTime, self.strMachineName, self.strCaseName,
                                     time1_str + "-{}".format(type))

        self.Save_Log_Path = dirNameServer
        shutil.copy(log_path, self.Save_Log_Path)  # 拷贝文件

    def find_new_file(self, find_dir_path):
        """查找目录下最新的文件夹"""
        dir_lists = os.listdir(find_dir_path)
        dir_lists.sort(key=lambda fn: os.path.getmtime(find_dir_path + r"/" + fn) if not os.path.isdir(
            find_dir_path + r"/" + fn) else 0)
        new_dir_path = os.path.join(find_dir_path, dir_lists[-1])
        '''查找目录下最新的log文件'''
        new_dir = os.listdir(new_dir_path)
        new_dir.sort(key=lambda fn: os.path.getmtime(new_dir_path + r"/" + fn))
        new_log_path = os.path.join(new_dir_path, new_dir[-1])
        return new_log_path

    def find_jx3_log(self):
        new_jx3_log_path = self.find_new_file(self.CLIENT_LOG_PATH)
        return new_jx3_log_path

    def findAsanLog(self):
        self.R3_LOG_PATH = os.path.join(self.BIN_R3_PATH, 'Asan_log')
        r3_log_path = self.find_new_file(self.R3_LOG_PATH)
        return r3_log_path

    def findDXLog(self):
        self.DX_LOG_PATH = self.BIN_R3_PATH + r'/DX_log'
        dx_log_path = self.find_new_file(self.DX_LOG_PATH)
        return dx_log_path

    def checkAsanLog(self, dic_args):
        check_type = "Asan"
        r3_log_path = self.findAsanLog()
        isempty = os.stat(r3_log_path).st_size == 0
        if isempty:
            pass
        else:
            '''存在问题：log保存到共享，并且同步信息'''
            self.save_log_file(r3_log_path, check_type)  # 保存r3log到共享文件夹
            self.save_log_file(self.find_jx3_log(), check_type)  # 保存jx3log到共享文件夹

            filepath, fullname = os.path.split(r3_log_path)
            fileshare_log_path = os.path.join(self.Save_Log_Path, fullname)

            errmsg = f'{self.ASAN_KEYWORD}\n日志保存路径：\\{fileshare_log_path}'
            self.log.info(errmsg)
            self.send_msg.push_markdown_report(self.strMachineName, self.strCaseName, errmsg, fileshare_log_path)

    def checkDXLog(self, dic_args):
        check_type = "DX"
        dx_log_path = self.findDXLog()
        isempty = os.stat(dx_log_path).st_size == 0
        if isempty:
            pass
        else:
            '''存在问题：log保存到共享，并且同步信息'''
            self.save_log_file(dx_log_path, check_type)  # 保存DXlog到共享文件夹
            self.save_log_file(self.find_jx3_log(), check_type)  # 保存jx3log到共享文件夹

            filepath, fullname = os.path.split(dx_log_path)
            fileshare_log_path = os.path.join(self.Save_Log_Path, fullname)

            errmsg = f'{self.DX_KEYWORD}\n日志保存路径：\\{fileshare_log_path}'
            self.log.info(errmsg)
            self.send_msg.push_markdown_report(self.strMachineName, self.strCaseName, errmsg, fileshare_log_path)

    def run_local(self, dic_args):
        self.loadDataFromLocalConfig(dic_args)
        while 1:
            time.sleep(2)
            try:
                self.checkAsanLog(dic_args)  # 检查ASAN日志
                self.checkDXLog(dic_args)  # 检查DX日志
                for folder in self.list_minidump_folder:
                    dump_full_path = self.getDumpInFolder(folder)
                    if not dump_full_path:
                        continue

                    strBin64Name='bin64'
                    self.server_dumprecode = self.Save_Log_Path
                    strFullPath=folder
                    dumpToolType='client'
                    #判断捕获宕机的工具类型
                    if 'Jx3Debugger' in folder:
                        dumpToolType = 'Jx3Debugger'
                        Jx3Debuger_config = os.path.join(folder, "config.ini")
                        strFullPath = ini_get("Debugger", "process_absolute_path", Jx3Debuger_config)

                    self.client_path = strFullPath.split(f'\\{strBin64Name}')[0]  # 获取宕机的客户端路径

                    # 发送几号机器有宕机
                    strMachineName = self.strMachineName
                    IP = machine_get_IPAddress()
                    strFeishuMachineName = '【{}|{}】'.format(strMachineName, IP)
                    info = '{}发生了宕机'.format(strFeishuMachineName)
                    send_Subscriber_msg(IP, info)
                    jpeg_fuul_path = printscreen(folder)

                    # 获取宕机日志
                    # dmp_log = self.getDumpLog()

                    # 创建一个标记文件，用于让运行游戏的用例等待本脚本处理完dump。
                    dumpFlagFilePath = os.path.join(folder, 'dumpIsProcessing')
                    with open(dumpFlagFilePath, 'w'):  # 创建一个标记文件。
                        pass

                    # time.sleep(5)
                    # 等待dmp文件写完
                    res = self.wait_for_close(dump_full_path)

                    win32_kill_process("DumpReport64.exe")
                    win32_kill_process("WerFault.exe")
                    win32_kill_process("PerformanceTool.exe")
                    win32_kill_process("PerfMon.exe")
                    win32_kill_process("JX3clientX64.exe")
                    win32_kill_process('JX3ClientX3DX64.exe')
                    win32_kill_process('JX3Debugger.exe')

                    dirNameServer = self.Save_Log_Path

                    # 剪切dmp和jpg文件到共享
                    if not os.path.exists(dirNameServer):
                        os.makedirs(dirNameServer)
                    filecontrol_copyFileOrFolder(dump_full_path, dirNameServer)
                    filecontrol_deleteFileOrFolder(dump_full_path)
                    if jpeg_fuul_path:
                        filecontrol_copyFileOrFolder(jpeg_fuul_path, dirNameServer)
                        filecontrol_deleteFileOrFolder(jpeg_fuul_path)

                    # 剪切日志到共享
                    # if dmp_log:
                    #     filecontrol_copyFileOrFolder(dmp_log, dirNameServer)

                    # 复制config到共享
                    config_path = os.path.join(self.client_path, 'config.ini')
                    filecontrol_copyFileOrFolder(config_path, dirNameServer)

                    # 标记文件删除，表示dump处理完毕。
                    filecontrol_deleteFileOrFolder(dumpFlagFilePath)

                    errmsg = f'{self.DX_KEYWORD}\ndump保存路径：\\{self.Save_Log_Path}'
                    self.log.info(errmsg)
                    self.send_msg.push_report(self.strMachineName,  errmsg)


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
    ob = CaseJX3HDAsanCheck()
    ob.run_from_IQB()
