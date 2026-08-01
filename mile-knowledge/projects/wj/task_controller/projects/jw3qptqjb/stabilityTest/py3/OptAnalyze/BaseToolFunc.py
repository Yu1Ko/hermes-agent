# -*- coding: utf-8 -*-

import sys
import os
import time
import subprocess
import configparser
import datetime
import shutil
import psutil
import logging, logging.handlers
from concurrent_log_handler import ConcurrentRotatingFileHandler
import platform
import json
import re
import sqlite3 as sql
import hashlib
import uuid
import threading, multiprocessing
import base64
from copy import deepcopy
import socket
import struct
import traceback

strOS = platform.system()
if strOS == 'Windows':
    import winreg
    from PIL import ImageGrab
    import win32api, win32gui, win32con, win32process, win32ui
    import ctypes
    import wmi
    import pythoncom


#---------global------------
SERVER_PATH = r'\\10.11.68.11\FileShare\JX3BVT'
SERVER_SEARCHPANEL = SERVER_PATH + r'\SearchPanel'
SERVER_SVN = SERVER_PATH + r'\svn'
SERVER_MAINSCRIPT = SERVER_PATH + r'\MainScript'
SERVER_TOOLS = SERVER_PATH + r'\Tools'
SERVER_LOG_PATH_PERFMON = SERVER_PATH + r'\Logs\PerfMon_Data'
SERVER_LOG_PATH_CLIENT = SERVER_PATH + r'\Logs\client'
SERVER_INI = SERVER_PATH + r'\MainScript\autoBVT.ini'
SCREENSHOT_PATH = r"//10.11.68.11//FileShare//luoyan2//screenshot3"
QCPROFILER = SERVER_PATH + r'\QCProfiler'
SERVER_DUMPRECORD = r"\\10.11.68.11\FileShare\DumpAnalyse"
LOCAL_INFO_FILE = 'C:\\RunMapResult'

TIMEOUT_SYNCHRODATA = 3
TASK_REBOOT_AND_RESET=4
TASK_RESET=5

WORK_PATH = os.getcwd()

SVN_USER = 'k_qc_pc_optimize'
SVN_PASS = 'aCc250DZ+2'
#本svn帐号还需要找mali申请访问权限

#--------------log-------------
# 使用说明： 本log模块使用进程id来处理多进程写日志问题
# 直接初始化 initLog('test')
# 使用的时候可以获取logger = logging.getLogger(str(os.getpid()))
# logger.error('123')
# 如果是类，可以self.log = logging.getLogger(str(os.getpid()))
# self.log.error('321')

def initLog(uName, path =None):
    def createLogPath(uName):
        if not path:
            strLogRootFile = os.path.join(os.getcwd(), 'log')
        else:
            strLogRootFile = os.path.join(path, 'log')
        if not os.path.exists(strLogRootFile):
            os.makedirs(strLogRootFile)
        time_now = datetime.datetime.now().strftime("%Y-%m-%d#%H-%M-%S")
        uLogPath = '{}_{}.txt'.format(uName, time_now)
        uLogPath = os.path.join(strLogRootFile, uLogPath)
        return uLogPath
    uName = uName.replace('|','-').replace('\\','-').replace('/','-').replace(':','-').replace('*','-').replace('?','-')\
        .replace('"', '-').replace('<','-').replace('>','-')
    uLogPath = createLogPath(uName)
    logger = logging.getLogger(str(os.getpid()))
    if hasattr(logger, 'init'):
        return
    # print 'initLog',name, str(os.getpid())
    logger.setLevel(logging.INFO)
    fmt = logging.Formatter("%(asctime)s - %(levelname)s - %(name)s - %(filename)s - %(lineno)d - %(message)s")
    handler_Screen = logging.StreamHandler()  # 往屏幕上输出
    handler_Screen.setFormatter(fmt)  # 设置屏幕上显示的格式
    handler_Timed_file = ConcurrentRotatingFileHandler(uLogPath, mode='a', maxBytes=100 * 1024 * 1024,
                                                       backupCount=50, delay=0)  # 100*1024*1024
    handler_Timed_file.setFormatter(fmt)
    handler_Socket = logging.handlers.DatagramHandler('10.11.80.122', 1231)
    handler_Socket.setFormatter(fmt)

    logger.addHandler(handler_Screen)
    logger.addHandler(handler_Timed_file)
    logger.addHandler(handler_Socket)
    logger.init = True

def formatTraceback(info):
    ll = info.split('\n')
    all = u''
    for line in ll:
        if '  File' in line:
            all = all + line.decode('gbk') + u'\n'
        else:
            all = all + line.decode('utf8') + u'\n'
    return all

#-----------wrapper-------------
def step(func):
    def wrapper(*args, **kwargs):
        print ('Func:' + func.__name__ + str(args))
        result = func(*args, **kwargs)
        return result
    return wrapper

#-----------common-------------
def gbk(string):
    try:
        s = string.decode('utf8').encode('gbk')
    except Exception as e:
        s = string
    return s

def utf8(string):
    try:
        s = string.decode('gbk').encode('utf8')
    except Exception as e:
        s = string
    return s

def format_space(space):
    if space < 10 ** 12:
        return str(int(round(space / 2 ** 30))) + "GB"
    else:
        return str(int(round(space / 10 ** 12))) + 'TB'

def timeout(timeout1):
    if time.time() < timeout1:
        return True
    else:
        return False

def JsonDump(obj):
    res = json.dumps(obj)#, ensure_ascii=False)
    return res

def JsonLoad(strData):
    ret = json.loads(strData)
    return ret

def window_capture(filename):
  hwnd = 0 # 窗口的编号，0号表示当前活跃窗口
  # 根据窗口句柄获取窗口的设备上下文DC（Divice Context）
  hwndDC = win32gui.GetWindowDC(hwnd)
  # 根据窗口的DC获取mfcDC
  mfcDC = win32ui.CreateDCFromHandle(hwndDC)
  # mfcDC创建可兼容的DC
  saveDC = mfcDC.CreateCompatibleDC()
  # 创建bigmap准备保存图片
  saveBitMap = win32ui.CreateBitmap()
  # 获取监控器信息
  MoniterDev = win32api.EnumDisplayMonitors(None, None)
  w = MoniterDev[0][2][2]
  h = MoniterDev[0][2][3]
  # print w,h　　　#图片大小
  # 为bitmap开辟空间
  saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
  # 高度saveDC，将截图保存到saveBitmap中
  saveDC.SelectObject(saveBitMap)
  # 截取从左上角（0，0）长宽为（w，h）的图片
  saveDC.BitBlt((0, 0), (w, h), mfcDC, (0, 0), win32con.SRCCOPY)
  saveBitMap.SaveBitmapFile(saveDC, filename)
  # bmp2jpg(filename)
  # 释放内存，不然会造成资源泄漏
  win32gui.DeleteObject(saveBitMap.GetHandle())
  saveDC.DeleteDC()

def printscreen2(path):
    try:
        if not path:
            return
        if not os.path.exists(path):
            os.makedirs(path)
        # im = ImageGrab.grab()
        szDatetime = re.sub(r'[^0-9]','',str(datetime.datetime.now()))
        filename = 'printscreen' + szDatetime
        absolutePath = path + r'/' + filename + '.bmp'
        # im.save(absolutePath, 'jpeg')
        window_capture(absolutePath)
        return absolutePath
    except Exception as e:
        logging.exception(e)
        return None

def printscreen(path):
    try:
        if not path:
            return None
        if win32_get_lock_screen_status() == 0:
            return None#锁屏了
        if not os.path.exists(path):
            os.makedirs(path)
        im = ImageGrab.grab() #！！锁屏和远程最小化会导致这里执行失败，执行失败会导致内存泄露，RAMMAP中Session Private增长。
        szDatetime = re.sub(r'[^0-9]','',str(datetime.datetime.now()))
        filename = 'printscreen' + szDatetime
        absolutePath = path + r'/' + filename + '.jpg'
        im.save(absolutePath, 'jpeg')
        return absolutePath
    except Exception as e:
        logging.exception(e)
        return None

def md5(str):
    md5 = hashlib.md5()
    md5.update(str)
    return md5.hexdigest()

def encryptedString(length):
    tmp = os.urandom(length)
    secret_key = base64.b64encode(tmp)
    return secret_key

def is_ipv4(ip):
    return True if [1] * 4 == [x.isdigit() and 0 <= int(x) <= 255 for x in str(ip).split(".")] else False

def get_this_file_root_path():
    # determine if application is a script file or frozen exe
    if getattr(sys, 'frozen', False):
        return os.path.dirname(os.path.realpath(sys.executable)) #for pyinstaller exe
    else:
        return os.path.dirname(os.path.abspath(__file__))

#-----------date---------------
def date_get_szToday():
    date_Today = datetime.date.today()
    szToday = "%s-%02d-%02d" % (date_Today.year, date_Today.month, date_Today.day)
    return szToday

def date_get_szToday_7():
    date_Today = datetime.date.today()
    H = int(time.strftime("%H", time.localtime()))
    if 0 <= H < 7:
        date_Today -= datetime.timedelta(days=1)
    szToday = "%s-%02d-%02d" % (date_Today.year, date_Today.month, date_Today.day)
    return szToday

def date_get_uToday_7():
    date_Today = datetime.date.today()
    H = int(time.strftime(u"%H", time.localtime()))
    if 0 <= H < 7:
        date_Today -= datetime.timedelta(days=1)
    uToday = u"%s-%02d-%02d" % (date_Today.year, date_Today.month, date_Today.day)
    return uToday

def date_get_szYesterday():
    date_Today = datetime.date.today()
    yesterday = date_Today - datetime.timedelta(days=1)
    szYesterday = "%s-%02d-%02d" % (yesterday.year, yesterday.month, yesterday.day)
    return szYesterday

def date_get_szDayBefore(delta):
    date_Today = datetime.date.today()
    yesterday = date_Today - datetime.timedelta(days=delta)
    szYesterday = "%s-%02d-%02d" % (yesterday.year, yesterday.month, yesterday.day)
    return szYesterday

def date_get_szWeekday():#Monday is 1 and Sunday is 7
    return str(datetime.datetime.now().isoweekday())

#------------------ini----------------------

# 目前本ini接口只支持GBK编码和utf8编码（不包括utf8-BOM）的配置文件

class myConfigParser(configparser.ConfigParser):
    def __init__(self,defaults=None):
        configparser.ConfigParser.__init__(self,defaults=None)
    def optionxform(self, optionstr):
        return optionstr

def ini_read(path, iniconf):
    try:
        iniconf.read(path, encoding='utf8')
        return 'utf8'
    except:
        iniconf.read(path, encoding='GBK')
        return 'GBK'

def ini_write(path, iniconf, encoding):
    iniconf.write(open(path, 'w', encoding=encoding), space_around_delimiters=False)


def ini_get(section, key, path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    return iniconf.get(section, key)

def ini_set(section, key, val, path):
    listSec = ini_getSections(path)
    if section not in listSec:
        ini_addSection(section, path)
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    if type(val) == int:
        val = str(val)
    iniconf.set(section, key, val)
    return ini_write(path, iniconf, encoding)

def ini_getOptions(section, path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    if section not in iniconf.sections():
        return None
    return iniconf.options(section)

def ini_getSections(path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    return iniconf.sections()

def ini_removeSection(section, path):
    listSec = ini_getSections(path)
    if section not in listSec:
        return
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    iniconf.remove_section(section)
    return ini_write(path, iniconf, encoding)

def ini_addSection(section, path):
    listSec = ini_getSections(path)
    if section in listSec:
        return
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    iniconf.add_section(section)
    return ini_write(path, iniconf, encoding)


#--------------filecontrol-------------------
def is_directory_symlink(path):
    return bool(os.path.isdir(path)
                and (win32api.GetFileAttributes(path) &
                     win32con.FILE_ATTRIBUTE_REPARSE_POINT))

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
                return (b[0])                                 # 返回类型值

def filecontrol_mklink(target, link):
    if not os.path.exists(target):
        print (target)
        raise Exception(u'filecontrol_mklink no target:{}'.format(target))
    if os.name == 'nt':
        if os.path.isfile(target):
            cmd = 'mklink "{}" "{}"'.format(link, target)
        else:
            cmd = 'mklink /J "{}" "{}"'.format(link, target)
        print (cmd)
        os.system(cmd)
    elif os.name == 'posix':
        cmd = 'ln -s {} {}'.format(target, link)
        os.system(cmd)


def filecontrol_deleteFileOrFolder(uFullPath):
    if 'sdcard/Android' in uFullPath:
        return adb_file_rm(uFullPath)
    if os.name == 'nt':
        filecontrol_deleteFileOrFolder_windows(uFullPath)
    else:
        filecontrol_deleteFileOrFolder_linux(uFullPath)

def filecontrol_deleteFileOrFolder_windows(uFullPath):
    if not os.path.exists(uFullPath):
        return False
    if uFullPath.find(u'/'):  # 使目录结构统一为反斜杠
        uFullPath = uFullPath.replace(u'/', u'\\')
    if os.path.isfile(uFullPath):
        cmd = u'DEL "' + uFullPath + u'" /F /Q'
        print (cmd)
        os.system(cmd)
        if os.path.exists(uFullPath):
            raise Exception(u'del file fail')
    else:
        if is_directory_symlink(uFullPath):
            # cmd = u'rmdir ' + uFullPath + u' /F /Q'
            # print cmd
            # os.system(cmd.encode('GBK'))
            os.rmdir(uFullPath)
        else:
            cmd = u'DEL ' + uFullPath + u' /F /S /Q'
            print (cmd)
            os.system(cmd)
            shutil.rmtree(uFullPath)
    return True

def filecontrol_deleteFileOrFolder_linux(uFullPath):
    if not os.path.exists(uFullPath):
        return False
    if os.path.islink(uFullPath):
        os.remove(uFullPath)
    else:
        if os.path.isfile(uFullPath):
            os.remove(uFullPath)
        else:
            # linux to del link??
            shutil.rmtree(uFullPath)
        return True

def filecontrol_copyFileOrFolder_linux(src, dst):
    bChange = 0
    src = src.replace('\\', '/')
    dst = dst.replace('\\', '/')
    mount_temp = u'mount_temp'
    mount_temp2 = u'mount_temp2'
    def changeUNCpath2MountPath(s, mount):
        split_count = len(s.split('/'))
        if split_count <= 4: # \\10.11.80.122\123 s最少层示例
            base_path = s
            last_path = u''
        else:
            base_path = s.rsplit('/', 1)[0]
            last_path = s.rsplit('/', 1)[1]
        if not os.path.exists(mount):
            os.makedirs(mount)
        os.system('umount {}'.format(mount))
        os.system('mount -t cifs {} {} -o password="",vers=2.0,iocharset=gb2312'.format(base_path, mount))
        return os.path.join(mount, last_path)
    if src.startswith('//'):
        src = changeUNCpath2MountPath(src, mount_temp)
        bChange = 1
    if dst.startswith('//'):
        dst = changeUNCpath2MountPath(dst, mount_temp2)
        bChange = 1
    if bChange == 1:
        filecontrol_copyFileOrFolder_linux(src, dst)

        os.system('umount {}'.format(mount_temp))
        os.system('umount {}'.format(mount_temp2))
        if os.path.exists(mount_temp):
            if not os.listdir(mount_temp):
                filecontrol_deleteFileOrFolder(mount_temp)
        if os.path.exists(mount_temp2):
            if not os.listdir(mount_temp2):
                filecontrol_deleteFileOrFolder(mount_temp2)
        return True
    if not os.path.exists(src):
        raise Exception(u'filecontrol_copyFileOrFolder_linux no src:{}'.format(src))
    dst_dirname = os.path.dirname(os.path.abspath(dst))
    if not os.path.exists(dst_dirname):
        os.makedirs(dst_dirname)
    if os.path.isfile(src):
        shutil.copy(src, dst)
    else:
        for fileorfloder in os.listdir(src):
            filecontrol_copyFileOrFolder(os.path.join(src, fileorfloder), os.path.join(dst, fileorfloder))
    return True

def filecontrol_copyFileOrFolder_windows(src, dst):
    if not os.path.exists(src):
        raise Exception(u'filecontrol_copyFileOrFolder_windows no src:{}'.format(src))
    dst_dirname = os.path.dirname(os.path.abspath(dst))
    if not os.path.exists(dst_dirname):
        os.makedirs(dst_dirname)
    if os.path.isfile(src):
        res = getFileOrFolderTypeInNT(src)
        if not res or len(res)!=2:
            shutil.copy(src, dst)
        else:
            link_target = res[1]
            filecontrol_mklink(link_target, dst)
    else:
        res = getFileOrFolderTypeInNT(src)
        if not res or len(res)!=2:
            for fileorfloder in os.listdir(src):
                filecontrol_copyFileOrFolder(os.path.join(src, fileorfloder), os.path.join(dst, fileorfloder))
        else:
            link_target = res[1]
            filecontrol_mklink(link_target, dst)
    return True

def filecontrol_push(src, dst):
    order = "adb push %s %s" %(src, dst)
    print (order)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res =  pi.stdout.read()
    if 'error' in res:
        raise Exception(res)
    print (res)

def filecontrol_pull(src, dst):
    order = "adb pull %s %s" %(src, dst)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res =  pi.stdout.read()
    if 'error' in res:
        raise Exception(res)
    print (res)

def adb_file_exist(file_path):
    file_path = file_path.replace('\\', '/')
    ''''adb shell ls / sdcard / Android / data / com.seasun.xgame.tako / files / version'''
    cmd = "adb shell ls %s" % (file_path)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    # ret_code = pi.returncode
    # print('filecontrol_file_exist: %s res= %s ret_code=%d ret_error=%s' % (cmd, res, 1, ret_error))
    # print('[DEBUG] %s [Res] %s' % (cmd, ret_error))
    if 'No such file or directory' in ret_error:
        return False
    else:
        return True

def filecontrol_existFileOrFolder(uPath):
    if 'sdcard/Android' in uPath:
        return adb_file_exist(uPath)
    return os.path.exists(uPath)

def adb_file_rm(file_path):
    file_path = file_path.replace('\\', '/')
    cmd = "adb shell rm %s" % (file_path)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    # if remove a not exist file with have blew errror info
    if 'No such file or directory' in ret_error:
        return False
    else:
        return True



def filecontrol_copyFileOrFolder(src, dst):
    # surport mobile
    if 'sdcard/Android' in src:
        src = src.replace('\\', '/')
        return filecontrol_pull(src, dst)
    if 'sdcard/Android' in dst:
        dst = dst.replace('\\', '/')
        return filecontrol_push(src, dst)
    #UNC Path to mount on linux
    if os.name == 'posix':
        return filecontrol_copyFileOrFolder_linux(src, dst)
    if os.name == 'nt':
        return filecontrol_copyFileOrFolder_windows(src, dst)

def md5File(filepath):
    md5_hash = hashlib.md5
    with open(filepath, 'rb') as f:
        data = f.read()
        return md5_hash(data).hexdigest()


def getStrListdir(case_path):
    thisCacheListdir = u''
    dirs = os.listdir(case_path)
    dirs.sort()
    for dir in dirs:
        fullpath = os.path.join(case_path, dir)
        if os.path.isdir(fullpath):
            str = getStrListdir(fullpath)
            thisCacheListdir = thisCacheListdir + dir.decode('gbk') + str
        else:
            thisCacheListdir = thisCacheListdir + dir.decode('gbk')
    return thisCacheListdir

#格式和前端约定
def getlistCaseFiles(case_path):
    listCaseFiles = []
    dirs = os.listdir(case_path)
    dirs.sort()
    for dir in dirs:
        dicCaseFile = {}
        dicCaseFile[u'label'] = dir.decode('gbk')
        fullpath = os.path.join(case_path, dir)
        if os.path.isdir(fullpath):
            listNextCaseFiles = getlistCaseFiles(fullpath)
            dicCaseFile[u'children'] = listNextCaseFiles
        listCaseFiles.append(dicCaseFile)
    return listCaseFiles

def getDicCaseFilesMD5(case_path):
    dicCaseFilesMD5 = {}
    dirs = os.listdir(case_path)
    # dirs.sort()
    for dir in dirs:
        fullpath = os.path.join(case_path, dir)
        if os.path.isfile(fullpath):
            if isinstance(fullpath, str):
                fullpath = fullpath
            key = fullpath.replace('/', '\\')
            dicCaseFilesMD5[key] = md5File(fullpath)
        else:
            dicCaseFilesMD5_next = getDicCaseFilesMD5(fullpath)
            dicCaseFilesMD5.update(dicCaseFilesMD5_next)
    return dicCaseFilesMD5

#-------------win32---------------------------
def win32_kill_process(process_name):
    while win32_findProcessByName(process_name):
        os.system('TASKKILL /F /t /IM %s' % process_name)

def win32_kill_process_by_cmd(process_name, szCmdLine = None):
    listP =  win32_findProcessByName(process_name, szCmdLine=szCmdLine)
    if listP:
        for p in listP:
            os.system('TASKKILL /F /t /pid %s' % p.pid)

def win32_reboot():
    # global logger
    # logger.info("reboot now!")
    os.system('shutdown.exe -r -f -t 0')

def win32_findProcessByPid(pid):
    for proc in psutil.process_iter():
        if proc.pid == pid:
            return proc
    return False

def win32_findProcessByName(name, szCmdLine = None):
    pids = psutil.pids()
    listP = []
    def assembleListCmd(listCmd):
        szCmd = ''
        for cmd in listCmd:
            szCmd = szCmd + ' ' + cmd
        szCmd = szCmd.strip()
        return szCmd
    for pid in pids:
        try:
            p = psutil.Process(pid)
            if p.name() == name:
                if not szCmdLine:
                    listP.append(p)
                else:
                    szCmd = assembleListCmd(p.cmdline())
                    if szCmdLine in szCmd:
                        listP.append(p)
        except Exception as msg:
            # logger.error(msg)
            # print msg
            continue
    if len(listP) > 0:
        return listP
    return False

# win32_kill_process_by_cmd('python.exe', szCmdLine = r'python \\10.11.130.75\share\JX3BVT\Tools\Focus\focus.py')

def win32_runExe(exe, path):
    proc = win32_runExe_no_wait(exe, path)
    proc.wait()


def win32_runExe_no_wait(exe, path):
    # os.chdir(path)
    # absolute_exe = path + '/' + exe
    proc = subprocess.Popen(exe, cwd = path, creationflags=subprocess.CREATE_NEW_CONSOLE)
    return proc

def win32_SetRegForPakv4Update(INSTPATH, bEXP = True):
    # try:
    if bEXP:
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE,r'Software',0,win32con.KEY_ALL_ACCESS)
        reg = winreg.CreateKey(key, r'JX3Installer_EXP')
        winreg.CloseKey(key)
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE,r'Software\JX3Installer_EXP',0,win32con.KEY_ALL_ACCESS)
        winreg.SetValueEx(key, 'InstPath', 0, win32con.REG_SZ, INSTPATH)
    else:
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE, r'Software', 0, win32con.KEY_ALL_ACCESS)
        reg = winreg.CreateKey(key, r'JX3Installer')
        winreg.CloseKey(key)
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE, r'Software\JX3Installer', 0, win32con.KEY_ALL_ACCESS)
        winreg.SetValueEx(key, 'InstPath', 0, win32con.REG_SZ, INSTPATH)
    # except Exception as e:
    #     print e

def win32_lock_screen():
    u = ctypes.windll.LoadLibrary('user32.dll')
    u.LockWorkStation()

def win32_get_lock_screen_status():
    u = ctypes.windll.LoadLibrary('user32.dll')
    result = u.GetForegroundWindow()
    return result    #0表示已锁屏

#---------------------linux---------------------------
def linux_findProcessByName(name, szCmdLine = None):
    return win32_findProcessByName(name, szCmdLine)



#---------read write file and log-----------

#adbShell = "adb shell logcat"
#logString = "lua"  # 定位关键字
#timeStamp = ''#time.mktime(time.strptime(str(datetime.date.today()), "%Y-%m-%d"))
def adb_findStringInLogcat(adbShell, logString, timeStamp):
    year = str(datetime.datetime.today().year)
    line_stamp = timeStamp

    # 开始执行adb命令
    p_obj = subprocess.Popen(
        args=adbShell,
        stdin=None, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, shell=False)

    # 实时监控并过滤每一行生成的日志里的关键字
    print("Logcat catching and filtering...")
    if p_obj:
        for line in p_obj.stdout:

            # 字节转字符串
            try:
                line = line.decode('ANSI')
            except:
                try:
                    line = line.decode('utf-8')
                except Exception as e:
                    print("编码问题！！！", e)

            # 过滤无效行
            if not re.match(r'\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d', line):
                continue

            # 过滤无效时间戳
            t = time.strptime(year + '-' + line[0:18], "%Y-%m-%d %H:%M:%S.%f")
            line_stamp = time.mktime(t)  # 当前行的时间戳
            if line_stamp < timeStamp:
                continue

            # 匹配logString
            if line.count(logString):
                print("Found %s" % logString)
                print("running adb bugreport to pull releated logs...pls wait")
                os.system("adb bugreport")  # 导出一次bugreport log压缩包
                return True, line_stamp

        return False, line_stamp

def getLastLogFile(log_floder_path):
    # global logger
    last_create_file = None
    last_create_time = 0
    log_path = log_floder_path + r'/' + time.strftime('%Y_%m_%d', time.localtime())
    # print log_path
    if not os.path.exists(log_path):
        # logger.info( 'not find '+log_path)
        return False    #没找到LOG文件夹，不算卡死（可能在更新）
    for entry in os.listdir(log_path):  #找到最新创建的日志
        filepath = log_path + '/' + entry
        if os.path.getctime(filepath) > last_create_time:
            last_create_file = filepath
            last_create_time = os.path.getctime(filepath)
    if last_create_file is None:    #今天没有日志文件，不算卡死（可能在更新）
        return False
    return last_create_file


def findStringInLog(file, logString, offset = 0):
    f = open(file, 'rb')
    f.seek(offset)
    while 1:
        line = f.readline()
        if line == b'':
            break
        try:
            line =  str(line, encoding='gbk')
        except:
            line =  str(line)
        if line.find(logString) != -1:
            offset = f.tell()
            f.close()
            return True, offset
    offset = f.tell()
    f.close()
    return False, offset

def changeStrInFile(file, old_str, new_str):
    with open(file, 'r+') as f:
        all_lines = f.readlines()
        f.seek(0)
        f.truncate()
        for line in all_lines:
            line = line.replace(old_str, new_str)
            f.write(line)

def WriteRunMapResult(testpoint, mapid):
    uTodday7 = date_get_uToday_7()
    folder = u'c:\\RunMapResult\\' + uTodday7
    if not os.path.exists(folder):
        os.makedirs(folder)
    filename = u'{}_{}_{}'.format(str(mapid), testpoint, uTodday7)
    with open(folder+'\\'+filename, u'w') as f:
        pass

#-------------machine info------------------

def getWinregValue(hkey, subdir, key):
    handle = winreg.OpenKey(hkey, subdir)
    value = winreg.QueryValueEx(handle, key)[0]
    return value


def isWin7():
    subDir = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    os_ProductName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'ProductName')
    if('Windows 7' in os_ProductName):
        return True
    else:
        return False

def machine_get_OSInfo():
    strOS = platform.system()
    if strOS == "Windows":
        os_type = platform.architecture()[0]
        # ProductName: Windows 10 Pro
        # DisplayVersion:21H2
        # such as: Windows 10 Pro(64bit) 21H2
        subDir = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        os_ProductName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'ProductName')
        os_DisplayVersion = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'DisplayVersion')
        return '{}({}) {}'.format(os_ProductName, os_type, os_DisplayVersion)
    elif strOS == "Linux":
        os_name = platform.platform()
        os_type = platform.architecture()[0]
        return '{}({})'.format(os_name, os_type)


def machine_get_IPAddress():
    # try:
        strOS = platform.system()
        if strOS == "Windows":
            pythoncom.CoInitialize()
            machine = wmi.WMI()
            return str(machine.Win32_NetworkAdapterConfiguration(IPEnabled=1)[0].IPAddress[0])

        elif strOS == "Linux":
            mess_ip = os.popen('hostname -I')
            mess = mess_ip.readlines()
            mes = mess[0].split(' ')
            ip = mes[0]
            return ip
        # return str(socket.gethostbyname(socket.getfqdn(socket.gethostname())))
    # except Exception as e:
    #     print (e)
    #     return 'machine_get_IPAddress_ERROR'

def machine_get_IPAddress_all():
    strOS = platform.system()
    if strOS == "Windows":
        hostname = socket.gethostname()
        hostname, aliaslist, ipaddrlist = socket.gethostbyname_ex(hostname)
        count_ip = len(ipaddrlist)
        strIp = ''
        for i in range(count_ip):
            if strIp == '':
                strIp = ipaddrlist[i]
            else:
                strIp = '{} | {}'.format(strIp, ipaddrlist[i])
        return strIp

    elif strOS == "Linux":
        mess_ip = os.popen('hostname -I')
        mess = mess_ip.readlines()
        mes = mess[0].split(' ')
        ip = mes[0]
        return ip

def machine_get_VideoCardInfo():
    strOS = platform.system()
    if strOS == "Windows":
        pythoncom.CoInitialize()
        machine = wmi.WMI()
        listCardName = []
        for card in machine.Win32_VideoController():
            listCardName.append(card.caption)
        returncard = listCardName[0]
        for cardName in listCardName:
            if u'NVIDIA' in cardName:
                returncard = cardName
                break
        return returncard
    # gpus = wmi.WMI(moniker="winmgmts:{impersonationLevel=impersonate}").InstancesOf("Win32_VideoController")
    # for gpu in gpus:
    #     Gpu_Name = gpu.VideoProcessor
    elif strOS == "Linux":
        return "Linux"

def machine_get_VideoCardInfo_v2():
    strOS = platform.system()
    if strOS == "Windows":
        pythoncom.CoInitialize()
        machine = wmi.WMI()
        strCardName = None
        listCardName = []
        for card in machine.Win32_VideoController():
            if not strCardName:
                strCardName = card.caption
            else:
                strCardName = strCardName + ' | ' + card.caption
        return strCardName
    # gpus = wmi.WMI(moniker="winmgmts:{impersonationLevel=impersonate}").InstancesOf("Win32_VideoController")
    # for gpu in gpus:
    #     Gpu_Name = gpu.VideoProcessor
    elif strOS == "Linux":
        return "Linux"

def machine_get_CPUCoreNum():
    strOS = platform.system()
    if strOS == "Windows":
        return str(int(multiprocessing.cpu_count()/2))
    elif strOS == "Linux":
        return 0

def machine_get_CPUInfo():
    strOS = platform.system()
    if strOS == "Windows":
        pythoncom.CoInitialize()
        machine = wmi.WMI()
        return str(machine.Win32_Processor()[0].Name.strip())
    elif strOS == "Linux":
        with open('/proc/cpuinfo') as f:
            for line in f:
                # Ignore the blank line separating the information between
                # details about two processing units
                if line.strip():
                    if line.rstrip('\n').startswith('model name'):
                        model_name = line.rstrip('\n').split(':')[1]
        return model_name

def machine_get_CPUInfo_v2():
    strOS = platform.system()
    if strOS == "Windows":
        coreNum = machine_get_CPUCoreNum()
        subDir = r'HARDWARE\DESCRIPTION\System\CentralProcessor\0'
        cpuName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'ProcessorNameString')
        return '{} ({} core)'.format(cpuName, coreNum)
    elif strOS == "Linux":
        with open('/proc/cpuinfo') as f:
            for line in f:
                # Ignore the blank line separating the information between
                # details about two processing units
                if line.strip():
                    if line.rstrip('\n').startswith('model name'):
                        model_name = line.rstrip('\n').split(':')[1]
        return model_name

def machine_get_DeviceName():
    strOS = platform.system()
    if strOS == "Windows":
        # pythoncom.CoInitialize()
        # machine = wmi.WMI()
        # return str(machine.Win32_Processor()[0].SystemName)
        subDir = r'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
        ComputerName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'ComputerName')
        return ComputerName
    elif strOS == "Linux":
        return 'Linux'

def machine_get_PhysicalMemorySize(): #Byte
    mem = psutil.virtual_memory()
    return mem.total

def machine_get_PhysicalDiskInfo(): #Byte
    disks = psutil.disk_partitions()
    dicDiskInfo = {}
    for disk in disks:
        try:
            disk_usage = psutil.disk_usage(disk.mountpoint)
            dicDiskInfo[disk.mountpoint] = {'total': disk_usage.total, 'free': disk_usage.free, 'percent': disk_usage.percent}
        except Exception as e:
            info = traceback.format_exc()
            logger = logging.getLogger(str(os.getpid()))
            logger.warning(info)
    return dicDiskInfo

def machine_get_DiskDriveInfo():
    strOS = platform.system()
    if strOS == "Windows":
        pythoncom.CoInitialize()
        machine = wmi.WMI()
        drivers = machine.Win32_DiskDrive()
        info = None
        for d in drivers:
            if not info:
                info = d.Caption
            else:
                info = info + ' | ' + d.Caption
        return info
    elif strOS == "Linux":
        return 'Linux'

def machine_get_guid():
    # try:
        strOS = platform.system()
        if strOS == "Windows":
                key = win32api.RegOpenKey(win32con.HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Cryptography",0,win32con.KEY_READ)
                guid=win32api.RegQueryValueEx(key,'MachineGuid')[0]
                win32api.RegCloseKey(key)
                return guid
        elif strOS == "Linux":
            cmd="dmidecode -s system-uuid | tr 'A-Z' 'a-z'"
            result = os.popen(cmd)
            guid = result.read().replace("\n","")
            return guid
    # except Exception as e:
    #     print ('get guid error')
    #     return None

def get_a_uuid():
    return str(uuid.uuid4())

def machine_reload_guid():
    # try:
        strOS = platform.system()
        if strOS == "Windows":
                key = win32api.RegOpenKey(win32con.HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Cryptography",0,win32con.KEY_ALL_ACCESS)
                guid=get_a_uuid()
                win32api.RegSetValueEx(key,'MachineGuid',0,win32con.REG_SZ,guid)
                win32api.RegCloseKey(key)
        elif strOS == "Linux":
            pass
    # except Exception as e:
    #     print ('reload guid error')
    #     return None

def getMachineInfoString():
    strMachineInfo = '{}\n{}\n{}\n{}\n{}\n{}\n{}'.format(
        machine_get_DeviceName(),
        machine_get_CPUInfo_v2(),
        machine_get_VideoCardInfo_v2(),
        'RAM {}GB'.format(round(machine_get_PhysicalMemorySize() / 1024.0 / 1024 / 1024)),
        machine_get_IPAddress_all(),
        machine_get_OSInfo(),
        machine_get_DiskDriveInfo()
    )
    return strMachineInfo


#--------------svn----------------
def svn_get_bvt_version():
    # try:
        conn = sql.connect(r"\\10.11.36.142\BranchManagerPlus\RevisionConfig.db")
        cursor = conn.cursor()
        bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()[0]   #获取今日BVT的信息
        today_date = list(map(int, date_get_szToday().split('-')))
        print (str(bvt_date[2].split()[0]))
        print (today_date)
        if len(bvt_date) >0 and str(bvt_date[2].split()[0]) == "%d/%d/%d" % (today_date[0], today_date[1], today_date[2]):
            server, client = bvt_date[:2]
            print ("today_BVT revision: server {}, client {}".format(server, client))
            return (server, client)
        else:
            return None
    # except Exception as e:
    #     print ('connect db error')
    #     return None

def svn_get_bvt_version_classic():
    # try:
        conn = sql.connect(r"\\10.11.36.142\BranchManagerPlusForClassic\RevisionConfig.db")
        cursor = conn.cursor()
        bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()[0]   #获取今日BVT的信息
        today_date = list(map(int, date_get_szToday().split('-')))
        if len(bvt_date) >0 and str(bvt_date[2].split()[0]) == "%d/%d/%d" % (today_date[0], today_date[1], today_date[2]):
            server, client = bvt_date[:2]
            print ("today_BVT revision: server {}, client {}".format(server, client))
            return (server, client)
        else:
            return None
    # except Exception as e:
    #     print ('connect db error')
    #     return None

def svn_get_local_revision(path):
    # try:
        cmd = r'svn info ' + path
        outText = "".join(os.popen(cmd).readlines())
        return int(re.findall(r'Revision: (\d+)', outText)[0])
    # except BaseException as e:
    #     print (e)


def svn_get_last_changed_date(path):
    # try:
        cmd = r'svn info ' + path
        outText = "".join(os.popen(cmd).readlines())
        return re.findall(r'Last Changed Date: (.+)', outText)[0][:10]
    # except BaseException as e:
    #     print (e)

def get_svn_loacl_info():
    svn_path = u'c:\\svn_acc'
    if os.path.exists(u'c:\\svn_acc'):
        user = ini_get('svn', 'user', u'c:\\svn_acc')
        passw = ini_get('svn', 'passw', u'c:\\svn_acc')
        return (user, passw)
    else:
        return None


def svn_cmd_update(path, ver=None, user=None, passw=None, user_readini=None):
    cmd = 'svn update {} --accept theirs-full --non-interactive'.format(path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    tupRes = get_svn_loacl_info()
    if tupRes and user_readini:
        user = tupRes[0]
        passw = tupRes[1]
    if ver:
        cmd = cmd + ' -r {}'.format(ver)
    if user and passw:
        cmd = cmd + ' --username {} --password {}'.format(user, passw)
    pi = subprocess.Popen(cmd, shell=True,  stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_update fail:{}'.format(str(ret_error,encoding='gbk')))
    return result

def svn_cmd_cleanup(path):
    cmd = 'svn cleanup {}'.format(path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_update fail:{}'.format(str(ret_error, encoding='gbk')))
    return result

def svn_cmd_checkout(url, path, ver=None, user=None, passw=None, user_readini=None):
    cmd = 'svn co {} {} --non-interactive'.format(url, path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    tupRes = get_svn_loacl_info()
    if tupRes and user_readini:
        user = tupRes[0]
        passw = tupRes[1]
    if ver:
        cmd = cmd + ' -r {}'.format(ver)
    if user and passw:
        cmd = cmd + ' --username {} --password {}'.format(user, passw)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()
    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_update fail:{}'.format(str(ret_error, encoding='gbk')))
    return result

def svn_cmd_export(url, ver, path, user=None, passw=None, user_readini=None):
    if path:
        old_cwd = os.getcwd()
        os.chdir(path)
    tupRes = get_svn_loacl_info()
    if tupRes and user_readini:
        user = tupRes[0]
        passw = tupRes[1]
    cmd = 'svn export {}'.format(url)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    if ver:
        cmd = cmd + ' -r {}'.format(ver)
    if user and passw:
        cmd = cmd + ' --username {} --password {}'.format(user, passw)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    if path:
        os.chdir(old_cwd)
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_update fail:{}'.format(str(ret_error, encoding='gbk')))
    return result

def svn_get_locked_status(path):
    # try:
        conn = sql.connect(os.path.join(path, '.svn', 'wc.db'))
        cursor = conn.cursor()
        date = cursor.execute("SELECT * FROM WC_LOCK").fetchall()[0]
        if date[0] is 1 and date[2] is -1:
            return True
    # except Exception as e:
    #     if 'list index out of range' in e:
    #         return False
    #     raise e

def vnc_disconnectall():
    exeTightVNC = r'C:\Program Files (x86)\TightVNC\tvnserver.exe'
    if os.path.exists(exeTightVNC):
        cmd = '"{}" -controlservice -disconnectall'.format(exeTightVNC)
        subprocess.Popen(cmd)
        # os.system(cmd)
    exeTightVNC = r'C:\Program Files\TightVNC\tvnserver.exe'
    if os.path.exists(exeTightVNC):
        cmd = '"{}" -controlservice -disconnectall'.format(exeTightVNC)
        subprocess.Popen(cmd)
        # os.system(cmd)

#------------------------
# 参数说明：
# uGuid指机器的guid，可用machine_get_guid()接口获取。
# uGuid可以直接填写ip地址，内部会自动转化为guid，但是需要机器纳入IQB平台管理。
# 机器纳入IQB平台，可订阅飞书信息。

def send_Subscriber_msg(uGuid, uMsg):
    def thread_send():
        try:
            conn = socket.socket()
            conn.connect(('10.11.80.122', 8090))
            dic = {u'guid':uGuid, u'msg':uMsg}
            msg = json.dumps(dic)
            msg = bytes(msg, encoding='utf8')
            len_msg = len(msg)
            len_msg = struct.pack('i', len_msg)
            conn.send(len_msg)
            conn.send(msg)
        except Exception as e:
            print (e)
            # info = traceback.format_exc()
            # initLog(u'send_Subscriber_msg')
            # logger = logging.getLogger(str(os.getpid()))
            # logger.error(info)

    t1 = threading.Thread(target=thread_send, args=())
    t1.setDaemon(True)
    t1.start()

class Connect(object):
    def __init__(self, serverIP, port, queue_msg):
        self.conn = None
        self.serverIP = serverIP
        self.port = port
        self.queue_msg = queue_msg
        self.bThreadRecv = True
        self.log = logging.getLogger(str(os.getpid()))

    def connect(self, no_timeout = False):
        try:
            obj = socket.socket()
            if not no_timeout:
                obj.settimeout(30)
            obj.connect((self.serverIP, self.port))
            self.conn = obj
            # liuzhu测试:
            self.log.info('connect')
            self.log.info(self.conn)
            # obj.settimeout(30)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)
            self.log.info(self.serverIP +'|'+ str(self.port))
            return
        #收包线程
        self.bThreadRecv = True
        t1 = threading.Thread(target=self.thread_recv, args=())
        t1.setDaemon(True)
        t1.start()

    def closeConn(self):
        self.bThreadRecv = False
        if self.conn:
            self.conn.shutdown(socket.SHUT_RDWR)
            self.conn.close()
            # print(self.conn)
            self.conn = None

    def thread_recv(self):
        while self.bThreadRecv:
            try:
                data = self.conn.recv(4)
                if not data:
                    break
                len_msg = struct.unpack('i', data)[0]
                #self.log.info('thread_recv_start1')
                #self.log.info(len_msg)
                # print '**************'
                # print len_msg
                # print '**************'
                received_size = 0
                received_data = bytearray()
                i=0
                while received_size < len_msg:
                    #self.log.info('thread_recv_start2')
                    data = self.conn.recv(len_msg - received_size)
                    if not data:
                        break
                    received_size += len(data)
                    # recevied_data += data
                    received_data.extend(data)
                # print 'recevied_size:'+str(recevied_size)
                # print 'recevied_data'+str(recevied_data)
                recevied_data = str(received_data, encoding='utf8')
                # liuzhu测试:
                #self.log.info('thread_recv')
                #self.log.info(recevied_data)
                self.queue_msg.put(recevied_data)
                self.log.info(recevied_data)
            except Exception:
                self.conn = None
                info = traceback.format_exc()
                if '10038' in info:#在一个非套接字上尝试了一个操作
                    self.log.warning(info)
                else:
                    self.log.error(info)
                break
        self.log.warning('thread_recv exit')
        self.closeConn()