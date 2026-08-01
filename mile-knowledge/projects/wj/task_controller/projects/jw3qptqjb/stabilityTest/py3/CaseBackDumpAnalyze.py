# coding=utf-8
from CaseCommon import *
from BaseToolFunc import *
import datetime
import os
import time
import threading
import sys
from ctypes import cdll
import psutil
# import pymysql


def code(str):
    return str
analyzing_dir = []  # 避免冲突加入的任务列表
path = code(r'z:')
cdbpath = "cdb"  # os.path.join("C:\\", "Program Files (x86)", "Windows Kits", "10", "Debuggers", "x64")
analyze_txt = 'analyze.txt'


def win32_findProcessByName(name):
    pids = psutil.pids()
    for pid in pids:
        try:
            p = psutil.Process(pid)
            if p.name() == name:
                return p
        except Exception as msg:
            continue
    return False





#写入数据库
# def write_db(dic_dumpheap):
#     conn = pymysql.connect(
#         host='10.11.80.122', user='root',
#         passwd='king+5688', db='bvt',
#         charset='utf8',
#         port=3306
#     )
#     cursor = conn.cursor()
#     heap = ""
#     for i in dic_dumpheap['heap']:
#         heap = heap + i
#     cursor.execute("INSERT into %s (ExceptionCode,heap,date) VALUES ('%s','%s','%s')" % (
#         "dumprecord", dic_dumpheap["ExceptionCode"], heap, datetime.datetime.now()))
#     conn.commit()
#     cursor.close()
#     conn.close()
#     cursor.close()


#处理读取analyze文件内容（为写库）
def read_analyze(file):
    f = open(file, 'r')
    flag = False
    heap = []
    ExceptionCode = ""
    for line in f.readlines():
        if flag == True:
            heap.append(line)
        if "ExceptionCode:" in line:
            ExceptionCode = line.replace("   ExceptionCode:", "").replace(" (Access violation)", "")
        elif "Child-SP          RetAddr           Call Site" in line:
            heap.append(line)
            flag = True
        elif "quit:" in line:
            break
    if len(heap) == 0 or ExceptionCode == "":
        # print "read_analyze failed"
        return False
    else:
        return {"ExceptionCode": ExceptionCode, "heap": heap}




class CaseBackDumpAnalyze(CaseCommon): #用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类

    def __init__(self):
        super().__init__()

    # 判断文件是否正在使用
    def wait_for_close(self, filename):
        while 1:
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

    # 调用cdb生成报告，调用read_analyze和write_db读数据并写库，调用前需要保证analyze空闲
    def thread_cdb_analyzed(self, dir, dmp_file):
        try:
            analyzing_dir.append(dir)  # 加入进行中的任务列表
            analyzeFile = os.path.join(dir, analyze_txt)
            os.system('echo %cd%')
            os.system(
                #'{0} -z {1} -lines -c ".reload /d;.lines -e;!analyze -v;k;q" -logo {2}'.format(
                '{0} -z {1} -lines -c ".reload /d;.lines -e;.ecxr;;kn;q" -logo {2}'.format(
                    cdbpath, dmp_file, analyzeFile
                )
            )
            time.sleep(2)

            # if os.path.exists(dmp_file):
            #     if is_open(analyzeFile) == False:
            #         print ('wait for write log finish..')
            #         dic_dumpheap = read_analyze(analyzeFile)
            #         if dic_dumpheap != False:
            #             write_db(dic_dumpheap)
            analyzing_dir.remove(dir)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)


    # path下如果不包含analyze.txt但有dmp，保证dmp文件空闲，添加线程执行
    def analyzeByPath(self, path):
        os.chdir(path)
        for dir in os.listdir(path):
            dmp_file = None
            analyzed = False
            if not os.path.isdir(dir):
                continue
            for entry in os.listdir(dir):
                if entry.endswith('.dmp'):
                    dmp_file = entry
                if entry == analyze_txt:
                    analyzed = True

            # 如果不包含analyze.txt但有dmp执行
            if not analyzed and dmp_file:
                abs_dir = os.path.join(path, dir)
                abs_dmp_path = os.path.join(abs_dir, dmp_file)
                if abs_dir in analyzing_dir:
                    # 检查文件夹是不是在任务中，如果在任务中就继续下一个
                    break
                self.wait_for_close(abs_dmp_path)
                # print '\n', abs_dmp_path
                t = threading.Thread(target=self.thread_cdb_analyzed, args=(abs_dir, abs_dmp_path))
                t.setDaemon(True)
                t.start()

    def run_local(self, dic_args):  #用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        while True:
            try:
                self.analyzeByPath(path)
                psutil.time.sleep(2)
                self.log.info('working...')
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)



if __name__ == '__main__':
    obj_test = CaseBackDumpAnalyze()
    obj_test.run_from_IQB()


