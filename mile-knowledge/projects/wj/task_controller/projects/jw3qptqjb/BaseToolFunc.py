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
import requests

strOS = platform.system()
if strOS == 'Windows':
    import winreg
    from PIL import Image
    from PIL import ImageGrab
    import win32api, win32gui, win32con, win32process, win32ui
    import ctypes
    import wmi
    import pythoncom

# ---------global------------
strBaseFolder="Test"  #(Android-设备ID)
strWorkPath="Test"    #工作路径 (controller+strBaseFolder)
strScriptPath="Test"  #脚本路径(原来的py3)
strTEMPFOLDER="test"  #(controller+strBaseFolder+'TempFolder')

def GetBaseFolder():
    global strBaseFolder
    return strBaseFolder

def GetWorkPath():
    global strWorkPath
    return strWorkPath

def GetScriptPath():
    global strScriptPath
    return strScriptPath

def GetTEMPFOLDER():
    global strTEMPFOLDER
    return strTEMPFOLDER

def SetWorkPath(strBaseFolderTemp,strWorkPathTemp,strScriptPathTemp,strTEMPFOLDERTemp):
    # 设置相关路径

    global strBaseFolder, strWorkPath, strScriptPath, strTEMPFOLDER
    strBaseFolder = strBaseFolderTemp
    strWorkPath = strWorkPathTemp
    strScriptPath=strScriptPathTemp
    strTEMPFOLDER=strTEMPFOLDERTemp
    # 工作路径 (controller+strBaseFolder)
    if not filecontrol_existFileOrFolder(strWorkPath):
        filecontrol_createFolder(strWorkPath)
    # 脚本路径(原来的py3)
    strScriptPath = os.path.dirname(os.path.realpath(__file__))
    if not filecontrol_existFileOrFolder(strScriptPath):
        filecontrol_createFolder(strScriptPath)
    # (controller+strBaseFolder+'TempFolder')
    strTEMPFOLDER = os.path.join(strWorkPath, 'TempFolder')
    if not filecontrol_existFileOrFolder(strTEMPFOLDER):
        filecontrol_createFolder(strTEMPFOLDER)

if strOS == 'Windows':
    STRSEPARATOR = '\\'
    SERVER_BASE_PATH=r'\\10.11.85.148'
    SERVER_PATH = r'\\10.11.85.148\FileShare\liuzhu\JX3BVT'
    SERVER_DUMPRECORD = r"\\10.11.85.148\FileShare\DumpAnalyse"
    SCREENSHOT_PATH = r"\\10.11.85.148\FileShare\luoyan2\screenshot3"
elif strOS == "Linux":
    STRSEPARATOR = '/'
    SERVER_BASE_PATH = '/mnt/BaseShare/FileShare-85-148'
    SERVER_PATH = '/mnt/BaseShare/FileShare-85-148/liuzhu/JX3BVT'
    SERVER_DUMPRECORD = "/mnt/BaseShare/FileShare-85-148/DumpAnalyse"
    SCREENSHOT_PATH = "/mnt/BaseShare/FileShare-85-148/luoyan2/screenshot3"
elif strOS == 'Darwin':
    STRSEPARATOR = '/'
    SERVER_BASE_PATH = '/Volumes/FileShare'
    SERVER_PATH = '/Volumes/FileShare/liuzhu/JX3BVT'
    SERVER_DUMPRECORD = "/Volumes/FileShare/DumpAnalyse"
    SCREENSHOT_PATH = "/Volumes/FileShare/luoyan2/screenshot3"

SERVER_SEARCHPANEL = SERVER_PATH + f'{os.sep}SearchPanel'
SERVER_SVN = SERVER_PATH + f'{os.sep}svn'
SERVER_MAINSCRIPT = SERVER_PATH + f'{os.sep}MainScript'
SERVER_TOOLS = SERVER_PATH + f'{os.sep}Tools'
SERVER_LOG_PATH_PERFMON = SERVER_PATH + f'{os.sep}Logs{os.sep}PerfMon_Data'
SERVER_LOG_PATH_CLIENT = SERVER_PATH + f'{os.sep}Logs{os.sep}client'
SERVER_INI = SERVER_PATH + f'{os.sep}MainScript{os.sep}autoBVT.ini'
QCPROFILER = SERVER_PATH + f'{os.sep}QCProfiler'
LOCAL_INFO_FILE = f'{os.sep}RunMapResult'

TIMEOUT_SYNCHRODATA = 3
SaveDate=8  #文件默认保留8天  date_get_szToday()获取日期  cleanup_old_folders
WORK_PATH = os.getcwd()

SVN_USER = 'k_qc_pc_optimize'
SVN_PASS = 'aCc250DZ+18'

MONGO_USER='admin'
MONGO_PASS='chDjJeUrlLspJiK8yut'


# windows下使用findstr，非windows使用grep
# 什么系统用对应命令，储存在strSystemFindstr中，然后将下文命令行cmd代码使用findstr的全部替换成f‘{strSystemFindstr}’
strSystemFindstr = 'findstr' if platform.system().lower() == 'windows' else 'grep'


#用例异常消息
from enum import Enum
class ExceptionMsg(Enum):
    CRASH = 1,
    FLASHBACK = 2,
    TASKTIMEOUT = 3,
    PERF_NETERROR=4,
    PERF_UPLOADERROR=5,
    BATTERY_LOW=6,
    SERVER_DISCONNECT=7,
    PERF_STARTERROR = 8,

# 本svn帐号还需要找mali申请访问权限

# --------------log-------------
# 使用说明： 本log模块使用进程id来处理多进程写日志问题
# 直接初始化 initLog('test')
# 使用的时候可以获取logger = logging.getLogger(str(os.getpid()))
# logger.error('123')
# 如果是类，可以self.log = logging.getLogger(str(os.getpid()))
# self.log.error('321')

def GetSystemSeparator():
    strSeparator=''
    if sys.platform.startswith('win'):
        strSeparator='\\'
    else:
        strSeparator='/'
    return strSeparator

def initLog(uName, path=None):
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

    uName = uName.replace('|', '-').replace('\\', '-').replace('/', '-').replace(':', '-').replace('*', '-').replace(
        '?', '-') \
        .replace('"', '-').replace('<', '-').replace('>', '-')
    uLogPath = createLogPath(uName)
    #新平台一个任务为一个进程,单个任务有多个用例,logger持有的句柄不会释放,因此需要先释放
    unIniLog()
    logger = logging.getLogger(str(os.getpid()))
    print(logger)
    fmt = logging.Formatter("%(asctime)s - %(levelname)s - %(name)s - %(filename)s - %(lineno)d - %(message)s")
    ''''''
    if hasattr(logger, 'init'):
        handler_Timed_file = ConcurrentRotatingFileHandler(uLogPath, mode='a', maxBytes=100 * 1024 * 1024,backupCount=50, delay=0)  # 100*1024*1024
        handler_Timed_file.setFormatter(fmt)
        logger.addHandler(handler_Timed_file)
        return
    print(f'------------logger ini path:{uLogPath}-----------------')
    # print 'initLog',name, str(os.getpid())
    logger.setLevel(logging.INFO)
    fmt = logging.Formatter("%(asctime)s - %(levelname)s - %(name)s - %(filename)s - %(lineno)d - %(message)s")
    handler_Screen = logging.StreamHandler()  # 往屏幕上输出
    handler_Screen.setFormatter(fmt)  # 设置屏幕上显示的格式
    handler_Timed_file = ConcurrentRotatingFileHandler(uLogPath, mode='a', maxBytes=100 * 1024 * 1024,backupCount=50, delay=0)  # 100*1024*1024
    handler_Timed_file.setFormatter(fmt)
    print('--------------2---------------')
    handler_Socket = logging.handlers.DatagramHandler('10.11.80.122', 1231)
    handler_Socket.setFormatter(fmt)
    print('--------------3---------------')
    logger.addHandler(handler_Screen)
    logger.addHandler(handler_Timed_file)
    logger.addHandler(handler_Socket)
    logger.init = True
    return uLogPath

def unIniLog(fileName=None):
    logger = logging.getLogger(str(os.getpid()))
    # 关闭并移除所有handler
    for handler in logger.handlers[:]:
        if isinstance(handler, ConcurrentRotatingFileHandler):
            logger.removeHandler(handler)
            try:
                handler.close()
            except Exception as e:
                pass  # 文件已被删除也没关系

def formatTraceback(info):
    ll = info.split('\n')
    all = u''
    for line in ll:
        if '  File' in line:
            all = all + line.decode('gbk') + u'\n'
        else:
            all = all + line.decode('utf8') + u'\n'
    return all


# -----------wrapper-------------
def step(func):
    def wrapper(*args, **kwargs):
        print('Func:' + func.__name__ + str(args))
        result = func(*args, **kwargs)
        return result

    return wrapper


# -----------common-------------
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
    res = json.dumps(obj)  # , ensure_ascii=False)
    return res


def JsonLoad(strData):
    ret = json.loads(strData)
    return ret


#防止长时间sleep导致线程线程睡眠
def sleep_heartbeat(nMinite):
    bFlag=False
    for n in range(nMinite):
        time.sleep(60)
        bFlag=True


def window_capture(filename):
    hwnd = 0  # 窗口的编号，0号表示当前活跃窗口
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


def window_capture2(filename):
    hwnd = win32gui.FindWindow('Qt5152QWindowIcon', None)  # 窗口的编号，0号表示当前活跃窗口
    # 根据窗口句柄获取窗口的设备上下文DC（Divice Context）
    hwndDC = win32gui.GetWindowDC(hwnd)
    # 根据窗口的DC获取mfcDC
    mfcDC = win32ui.CreateDCFromHandle(hwndDC)
    # mfcDC创建可兼容的DC
    saveDC = mfcDC.CreateCompatibleDC()
    # 创建bigmap准备保存图片
    saveBitMap = win32ui.CreateBitmap()
    # 获取监控器信息
    # MoniterDev = win32api.EnumDisplayMonitors(None, None)
    # w = MoniterDev[0][2][2]
    # h = MoniterDev[0][2][3]
    left, top, right, bot = win32gui.GetWindowRect(hwnd)
    print(left, top, right, bot)
    w = right - left
    h = bot - top
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
        szDatetime = re.sub(r'[^0-9]', '', str(datetime.datetime.now()))
        filename = 'printscreen' + szDatetime
        absolutePath = path + r'/' + filename + '.bmp'
        # im.save(absolutePath, 'jpeg')
        window_capture(absolutePath)
        return absolutePath
    except Exception as e:
        logging.exception(e)
        return None

def bmpToPng(file_path):
    im = Image.open(file_path)
    if file_path.lower().endswith('.bmp'):
        file_path = file_path.replace('.bmp', '.png').replace('.BMP', '.png')
    im.save(file_path, 'png')

def window_capture_bmp(filename, appclass=None):
    hwnd = 0  # 窗口的编号，0号表示当前活跃窗口
    if appclass:
        hwnd = win32gui.FindWindow(appclass, None)
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
    if appclass:
        left, top, right, bot = win32gui.GetWindowRect(hwnd)
        # print(left, top, right, bot)
        w = right - left
        h = bot - top
    # 为bitmap开辟空间
    saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
    # 高度saveDC，将截图保存到saveBitmap中
    saveDC.SelectObject(saveBitMap)
    # 截取从左上角（0，0）长宽为（w，h）的图片
    saveDC.BitBlt((0, 0), (w, h), mfcDC, (0, 0), win32con.SRCCOPY)
    saveBitMap.SaveBitmapFile(saveDC, filename)
    # 释放内存，不然会造成资源泄漏
    win32gui.DeleteObject(saveBitMap.GetHandle())
    saveDC.DeleteDC()

def printscreen(path, appclass=None):
    try:
        if not path:
            return None
        if win32_get_lock_screen_status() == 0:
            return None  # 锁屏了
        if not os.path.exists(path):
            os.makedirs(path)
        szDatetime = re.sub(r'[^0-9]', '', str(datetime.datetime.now()))
        filename = 'printscreen' + szDatetime
        absolutePath = path + r'/' + filename + '.png'
        if appclass:
            window_capture_bmp(absolutePath, appclass)
            bmpToPng(absolutePath)
        else:
            im = ImageGrab.grab()  # ！！锁屏和远程最小化会导致这里执行失败，执行失败会导致内存泄露，RAMMAP中Session Private增长。
            im.save(absolutePath, 'png')
        return absolutePath
    except Exception:
        logger = logging.getLogger(str(os.getpid()))
        info = traceback.format_exc()
        logger.error(info)

def is_workTime(nStart=9,nEnd=22):

    nCurrentHour=datetime.datetime.now().hour
    bWorkTime=False
    if nCurrentHour>=nStart and nCurrentHour<=nEnd:
        bWorkTime=True
    return bWorkTime

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
        return os.path.dirname(os.path.realpath(sys.executable))  # for pyinstaller exe
    else:
        return os.path.dirname(os.path.abspath(__file__))


# -----------date---------------
def date_get_szToday():
    date_Today = datetime.date.today()
    szToday = "%s-%02d-%02d" % (date_Today.year, date_Today.month, date_Today.day)
    return szToday

#使用date_get_szToday()格式创建的文件夹  用这个接口保留几天的文件
def cleanup_date_folders(base_path,nSaveDateCount=8):
    if not nSaveDateCount or nSaveDateCount<=0:
        nSaveDateCount=SaveDate
    today = date_get_szToday()
    year, month, day = map(int, today.split('-'))
    # 创建一个datetime对象
    today = datetime.datetime(year, month, day)
    # 计算截止日期
    cutoff_date = (today - datetime.timedelta(days=nSaveDateCount)).strftime('%Y-%m-%d')
    # 遍历基础路径下的所有文件夹
    for folder_name in os.listdir(base_path):
        folder_path = os.path.join(base_path, folder_name)
        # 确保它是一个文件夹
        if os.path.isdir(folder_path):
            try:
                # 尝试解析文件夹名称为日期
                if folder_name < cutoff_date:
                    shutil.rmtree(folder_path, ignore_errors=True)
                    print(f"Deleted old folder: {folder_path}")
            except ValueError:
                # 文件夹名称不是日期格式，忽略
                continue

#避免重名路径覆盖文件夹
def sort_filePath(strFilePath):
    '''
    nIndex=1
    while filecontrol_existFileOrFolder(f"{strFilePath}_{nIndex}"):
        nIndex+=1
    strFilePath=f"{strFilePath}_{nIndex}"'''
    strTime=datetime.datetime.now().strftime("%H-%M-%S")
    strFilePath = f"{strFilePath}_{strTime}"
    return strFilePath

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


def date_get_szWeekday():  # Monday is 1 and Sunday is 7
    return str(datetime.datetime.now().isoweekday())


# ------------------ini----------------------

# 目前本ini接口只支持GBK编码和utf8编码（不包括utf8-BOM）的配置文件

class myConfigParser(configparser.ConfigParser):
    def __init__(self, defaults=None):
        configparser.ConfigParser.__init__(self, defaults=None)

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


def str_type(str):
    if type(eval(str)) == int:
        return int(str)
    elif type(eval(str)) == float:
        return float(str)


def tab_read(szPath):
    dict_json_data = {
        "datalist": []
    }
    with open(szPath, 'r') as f:
        read_table_conent = f.read()
    list_line_data = read_table_conent.split('\n')  # 获取每一行
    table_head_list = []
    length = len(list_line_data[0].split('\t'))
    for line_data_index in range(len(list_line_data)):
        list_row_data = list_line_data[line_data_index].split('\t')  # 将每一行内容按 \t分割，获取每一列的内容
        if len(list_row_data) < length:
            continue
        if line_data_index == 0:  # 如果是第一行，那就是表头,直接将表头作为 字典的key，初始话一个 空数组
            table_head_list = list_row_data
        else:
            # 如果 row_data_index大于0，那这里每行内容就是 测试数据了，按照顺序插入字典对应的key
            this_line_data = {}
            for table_head_index in range(len(table_head_list)):  # 按照表头数组的顺序，将数据 一一对应append 进dict
                this_line_data[table_head_list[table_head_index]] = str_type(list_row_data[table_head_index])
            dict_json_data["datalist"].append(this_line_data)
    return dict_json_data

#图像识别

def EasyOCR_remote(img_path):
    # 截图
    import requests
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
        img_base64_str = img_base64_byte.decode('ascii')
    # 由其他机器提供EasyOCR服务，识别图片中的文字
    server_path = 'http://10.11.179.106:5000/up_image'  # dic_args['reconize_server']
    post_json = json.dumps({'img_test': img_base64_str})

    try:
        r = requests.post(server_path, data=post_json)
        dicRes = json.loads(r.text)
        if 'analyse_text' in dicRes:
            return dicRes['analyse_text']
    except:
        logger = logging.getLogger(str(os.getpid()))
        info = traceback.format_exc()
        logger.error(info)

def paddleocr(img_path):
    import requests
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.78:8000/ocr'  # 13号机不太稳定
    server_path = 'http://10.11.181.236:8765/ocr'  # 2号机
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    r = requests.post(server_path, data=img_base64_byte, timeout=60)
    r.raise_for_status()  # 如果返回状态码不是200，则抛出异常
    res = r.json()
    result = res['result']
    text = ""
    for item in result:
        for i in item:
            text += i[1][0]

    return text

def paddleocr_socket(img_path):
    import requests
    logger = logging.getLogger(str(os.getpid()))
    with open(str(img_path), 'rb') as img_f:
        img_stream = img_f.read()
        image_base64 = str(base64.b64encode(img_stream), encoding='utf8')
    strServerIp="10.11.181.236"  #2号机器
    strServerIp = '10.11.177.218'  # 马力工作机2
    #win7第一次链接socket后 发送数据会失败，第二次会成功
    if isWin7():
        conn_temp=socket.socket()
        conn_temp.connect((strServerIp, 47690))
        time.sleep(2)
    conn = socket.socket()
    conn.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 655360)
    conn.connect((strServerIp, 47690))
    dic = {u'guid': machine_get_guid(), 'image_base64': image_base64}
    msg = json.dumps(dic)
    msg = bytes(msg, encoding='utf8')
    len_msg = len(msg)
    len_msg = struct.pack('i', len_msg)
    conn.sendall(len_msg)
    conn.sendall(msg)
    #接收服务端处理完成的数据

    conn.settimeout(30)
    data = conn.recv(4)
    if not data:
        logger.warning("recv data error")
        return
    len_msg = struct.unpack('i', data)[0]
    recevied_size = 0
    received_data = bytearray()
    bDataComplete = True
    while recevied_size < len_msg:
        data = conn.recv(len_msg - recevied_size)
        if not data:
            logger.warning('recv no data')
            bDataComplete = False
            break
        recevied_size += len(data)
        # recevied_data += data
        received_data.extend(data)
    if len_msg != recevied_size:
        info = '{},recv 数据包 长度错误. len_msg:{},recevied_size:{},差值:{}'.format(strServerIp, str(len_msg),str(recevied_size),str(recevied_size - len_msg))
        logger.error(info)
        return
    dic_recevied_data = JsonLoad(received_data)
    if 'result' not in dic_recevied_data:
        logger.info('receive data no result')
        return

    result = dic_recevied_data['result']
    text = ""
    for item in result:
        for i in item:
            text += i[1][0]
    return text

# --------------filecontrol-------------------
from pymobiledevice3 import usbmux
from pymobiledevice3.lockdown import create_using_usbmux
from pymobiledevice3.services.house_arrest import HouseArrestService
from pymobiledevice3.exceptions import AfcFileNotFoundError,ConnectionTerminatedError
def singleton(cls):
    instances = {}
    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]
    return get_instance

@singleton
class Pymobiledevice3Service: #用于优化pymobiledevice3相关服务的初始化
    def __init__(self,deviceID=None):
        #不填设备ID 默认用第一台连接设备,一台设备都未连接就报错
        if not deviceID:
            self.deviceID = usbmux.list_devices()[0].serial
        else:
            self.deviceID = deviceID
        self.lockdown_client = create_using_usbmux(self.deviceID)
        self.log = logging.getLogger(str(os.getpid()))
        self.HouseArrest=None #包内文件初始化
        self.nErrorCnt=0
        #self.ini_HouseArrestService()
    #包内文件处理初始化
    def ini_HouseArrestService(self,bundleID):
        if not self.HouseArrest:
            self.HouseArrest = HouseArrestService(self.lockdown_client, bundleID)

    def reConnect_HouseArrestService(self,bundleID):
        self.lockdown_client = create_using_usbmux(self.deviceID)
        self.HouseArrest = HouseArrestService(self.lockdown_client, bundleID)
        #self.nErrorCnt = self.nErrorCnt + 1
        #self.log.info(f"HouseArrestService try connect {self.nErrorCnt}")

def is_directory_symlink(path):
    return bool(os.path.isdir(path)
                and (win32api.GetFileAttributes(path) &
                     win32con.FILE_ATTRIBUTE_REPARSE_POINT))


def find_files_in_folder(folder_name,nDepth=0):
    import string
    """根据文件夹名称找到该文件夹内所有文件的完整路径"""
    """根据文件夹名称遍历所有磁盘，找到第一个匹配的完整路径后立即返回"""
    drives = [f"{d}:/" for d in string.ascii_uppercase if os.path.exists(f"{d}:/")]

    for drive in drives:
        for root, dirs, _ in os.walk(drive, topdown=True, onerror=lambda e: None):
            # 计算当前深度（相对磁盘根目录）
            if nDepth:
                depth = root[len(drive):].count(os.sep)
                if depth > nDepth:  # 只遍历前3层（0、1、2）
                    dirs[:] = []  # 不再深入
                    continue

            for d in dirs:
                print(os.path.join(root, d))
                if d.lower() == folder_name.lower():
                    return os.path.join(root, d)
    return None


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


def filecontrol_deleteFileOrFolder(uFullPath, deviceID=None, bundleID=None):
    uFullPath=uFullPath.strip()
    if 'sdcard/Android' in uFullPath:
        return adb_file_rm(uFullPath, deviceID)
    elif '/Document' in uFullPath:
        #return tidevice_file_rm(uFullPath, bundleID, deviceID)
        return pymobiledevice3_file_rm(uFullPath, bundleID, deviceID)
    if strOS == "Windows":
        return filecontrol_deleteFileOrFolder_windows(uFullPath)
    elif strOS == "Linux":
        return filecontrol_deleteFileOrFolder_linux(uFullPath)
    elif strOS == 'Darwin':
        return filecontrol_deleteFileOrFolder_macos(uFullPath)


def filecontrol_deleteFileOrFolder_windows(uFullPath):
    if not os.path.exists(uFullPath):
        return False
    if uFullPath.find('/'):  # 使目录结构统一为反斜杠
        uFullPath = uFullPath.replace('/', '\\')
    if os.path.isfile(uFullPath):
        os.remove(uFullPath)
        #cmd = 'DEL "' + uFullPath + '" /F /Q'
        #print(cmd)
        #os.system(cmd)
        if os.path.exists(uFullPath):
            raise Exception(f'del file fail:{uFullPath}')
    else:
        if is_directory_symlink(uFullPath):
            # cmd = u'rmdir ' + uFullPath + u' /F /Q'
            # print cmd
            # os.system(cmd.encode('GBK'))
            os.rmdir(uFullPath)
        else:
            cmd = 'DEL ' + uFullPath + ' /F /S /Q'
            print(cmd)
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

def filecontrol_deleteFileOrFolder_macos(uFullPath):
    filecontrol_deleteFileOrFolder_linux(uFullPath)


def filecontrol_copyFileOrFolder_linux(src, dst):
    bChange = 0
    src = src.replace('\\', '/')
    dst = dst.replace('\\', '/')
    mount_temp = u'mount_temp'
    mount_temp2 = u'mount_temp2'

    def changeUNCpath2MountPath(s, mount):
        split_count = len(s.split('/'))
        if split_count <= 4:  # \\10.11.80.122\123 s最少层示例
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
        print(dst_dirname)
        os.makedirs(dst_dirname)
    if os.path.isfile(src):
        print(src)
        print(dst)
        shutil.copy(src, dst)
    else:
        for fileorfloder in os.listdir(src):
            filecontrol_copyFileOrFolder(os.path.join(src, fileorfloder), os.path.join(dst, fileorfloder))
    return True

def filecontrol_copyFileOrFolder_macos(src, dst):
    src = src.replace('\\', '/')
    dst = dst.replace('\\', '/')
    if not os.path.exists(src):
        raise Exception(u'filecontrol_copyFileOrFolder_macos no src:{}'.format(src))
    dst_dirname = os.path.dirname(os.path.abspath(dst))
    os.makedirs(dst_dirname,exist_ok=True)
    if os.path.isfile(src):
        shutil.copy(src,dst)
    else:
        #dst必须传文件夹路径否者会报错
        shutil.copytree(src,dst)
    return True

def filecontrol_copyFileOrFolder_windows(src, dst):
    if not os.path.exists(src):
        raise Exception(u'filecontrol_copyFileOrFolder_windows no src:{}'.format(src))
    dst_dirname = os.path.dirname(os.path.abspath(dst))
    #logger = logging.getLogger(str(os.getpid()))
    #logger.info(dst_dirname)
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
                filecontrol_copyFileOrFolder(os.path.join(src, fileorfloder), os.path.join(dst, fileorfloder))
        else:
            link_target = res[1]
            filecontrol_mklink(link_target, dst)
    return True


def adb_push(src, dst, deviceID=None):
    if deviceID:
        order = "adb -s %s push %s %s" % (deviceID, src, dst)
    else:
        order = "adb push %s %s" % (src, dst)
    print(order)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    print(res)


def tidevice_push(src, dst, bundleID, deviceID=None):
    if deviceID:
        order = f"tidevice -u %s fsync -B %s push %s %s" % (deviceID, bundleID, src, dst)
    else:
        order = f"tidevice fsync -B %s push %s %s" % (bundleID, src, dst)
    print(order)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    print(res)


def pymobiledevice3_push(src, dst, bundleID, deviceID=None):
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = True
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        # local to package
        if os.path.isdir(src):
            # src为文件夹:需要删除dst最后一个路径
            dst = os.path.dirname(dst)
        else:
            # src为文件: 需要创建路径
            py3Service.HouseArrest.makedirs(os.path.dirname(dst))

        py3Service.HouseArrest.push(src, dst)
    except ConnectionTerminatedError as e:
        #AFC服务报错
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_push(src, dst, bundleID, deviceID)
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return result

def adb_pull(src, dst, deviceID=None):
    if deviceID:
        order = "adb -s %s pull %s %s" % (deviceID, src, dst)
    else:
        order = "adb pull %s %s" % (src, dst)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    print(res)

def tidevice_pull(src, dst, bundleID, deviceID=None):
    if deviceID:
        order = f"tidevice -u %s fsync -B %s pull %s %s" % (deviceID, bundleID, src, dst)
    else:
        order = f"tidevice fsync -B %s pull %s %s" % (bundleID, src, dst)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    print(res)

def pymobiledevice3_pull(src, dst, bundleID, deviceID=None):
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = True
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if py3Service.HouseArrest.isdir(src):
            dst = os.path.dirname(dst)
        py3Service.HouseArrest.pull(src, dst)
    except ConnectionTerminatedError as e:
        #AFC服务报错
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_pull(src, dst, bundleID, deviceID)
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return result


def adb_findStringInLogcat(strKey,deviceID):
    if deviceID:
        cmd = f"adb -s %s logcat | {strSystemFindstr} '%s'" % (deviceID, strKey)
    else:
        cmd = f"adb logcat | {strSystemFindstr} '%s'" % (strKey)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)


def adb_find_apk(package, deviceID):
    cmd = f'adb -s {deviceID} shell "pm list packages -3 | grep {package}"'
    print(cmd)
    packagelist = os.popen(cmd).read().replace("\n", "")  # 拿包名
    if packagelist.find(package) != -1:
        return True
    return False


def tidevice_find_ipa(bundleID, deviceID=None):
    cmd = f'tidevice -u {deviceID} applist | {strSystemFindstr} {bundleID} '
    packagelist = os.popen(cmd).read()  # 拿包名
    if packagelist.find(bundleID) != -1:
        return True
    return False




def mobile_find_app(package, deviceID):
    if '-' in deviceID:
        return tidevice_find_ipa(package, deviceID)
    else:
        return adb_find_apk(package, deviceID)


# 获取测试机电池温度
def mobile_get_Battery_temperature(deviceID):
    if '-' in deviceID:
        return tidevice_get_Battery_temperature(deviceID)
    else:
        return adb_get_Battery_temperature(deviceID)

# 获取Android测试机电池温度
def adb_get_Battery_temperature(deviceID):
    cmd = f'adb -s {deviceID} shell "dumpsys battery"'
    result = os.popen(cmd).read().split('\n')
    temperateure = ''
    for line in result:
        if('temperature' in line):
            wendu = line.split(':')
            temperateure = int(wendu[1])/10.0
            break
    return round(temperateure, 1)

# 获取IOS测试机电池温度
def tidevice_get_Battery_temperature(UDID):
    cmd = f'tidevice -u {UDID} battery'
    with os.popen(cmd) as fp:
        bf = fp._stream.buffer.read()
    alldata = bf.decode().strip()
    dataList = alldata.split()
    temperateure = ''
    for index,value in enumerate(dataList):
        if value == '电池温度':
            temperateure = dataList[index+1]
    result = int(temperateure.split('/')[0])/100.0

    return round(result, 1)


def adb_start_apk(package, deviceID=None):
    #根据package获取activity
    if deviceID:
        cmd = f"adb -s %s shell dumpsys package %s | {strSystemFindstr} Activity" % (deviceID, package)
    else:
        cmd = f"adb shell dumpsys package %s | {strSystemFindstr} Activity" % (package)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    activity=res.split('\n')[1].lstrip().split(' ')[1]
    activity=activity.strip()
    #print(activity)
    if deviceID:
        cmd = "adb -s %s shell am start -n '%s'" % (deviceID, activity)
    else:
        cmd = "adb shell am start -n '%s'" % (activity)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)
    return res


def tidevice_start_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = "tidevice -u %s launch %s" % (deviceID, bundleID)
    else:
        cmd = "tidevice launch %s" % (bundleID)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)
    return res

def tidevice_start_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = "tidevice -u %s launch %s" % (deviceID, bundleID)
    else:
        cmd = "tidevice launch %s" % (bundleID)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)
    return res

def pymobiledevice3_start_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = f"pymobiledevice3 developer dvt launch {bundleID} --udid {deviceID}"
    else:
        cmd = f"pymobiledevice3 developer dvt launch {bundleID}"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)
    return res


def mobile_start_app(package, deviceID):
    if '-' in deviceID:
        #tidevice_start_ipa(package, deviceID)
        pymobiledevice3_start_ipa(package, deviceID)
    else:
        adb_start_apk(package,deviceID)


def adb_kill_apk(package, deviceID=None):
    if deviceID:
        cmd = 'adb -s %s shell am force-stop "%s"' % (deviceID, package)
    else:
        cmd = 'adb shell am force-stop "%s"' % (package)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)


def tidevice_kill_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s kill %s' % (deviceID, bundleID)
    else:
        cmd = 'tidevice kill %s' % (bundleID)
    #执行一次有一定概率失败 所有执行两次
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    time.sleep(2)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)

def pymobiledevice3_kill_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = f'pymobiledevice3 developer dvt pkill --bundle {bundleID} --udid {deviceID}'
    else:
        cmd = f'pymobiledevice3 developer dvt pkill --bundle {bundleID}'
    #执行一次有一定概率失败 所有执行两次
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    time.sleep(2)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)


def mobile_kill_app(package, deviceID):
    if '-' in deviceID:
        #tidevice_kill_ipa(package, deviceID)
        pymobiledevice3_kill_ipa(package, deviceID)
    else:
        adb_kill_apk(package,deviceID)


def adb_screenshot(savepath, deviceID=None):
    strDevicePath = '/sdcard/screenshot.png'
    if deviceID:
        cmd = 'adb -s %s shell screencap -p %s' % (deviceID, strDevicePath)
        order = "adb -s %s pull %s %s" % (deviceID, strDevicePath, savepath)
    else:
        cmd = 'adb shell screencap -p %s' % (strDevicePath)
        order = "adb pull %s %s" % (strDevicePath, savepath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)


def tidevice_screenshot(savepath, deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s screenshot %s' % (deviceID, savepath)
    else:
        cmd = 'tidevice screenshot %s' % (savepath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)

def pymobiledevice3_screenshot(savepath, deviceID=None):
    if deviceID:
        cmd = f'pymobiledevice3 developer dvt screenshot {savepath} --udid {deviceID}'
    else:
        cmd = f'pymobiledevice3 developer dvt screenshot {savepath}'
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)

def mobile_screemshot(savepath, deviceID):
    if '-' in deviceID:
        #tidevice_screenshot(savepath, deviceID)
        pymobiledevice3_screenshot(savepath, deviceID)
    else:
        adb_screenshot(savepath, deviceID)


def adb_install_apk(strPackagepath, deviceID=None):
    strPackagepath = strPackagepath.replace('/', '\\')
    if deviceID:
        cmd = 'adb -s %s install -g "%s"' % (deviceID, strPackagepath)
    else:
        cmd = 'adb install -g "%s"' % (strPackagepath)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)
    try:
        ret_error = str(res, encoding='gbk')
    except:
        ret_error = str(res, encoding='utf8')
    logger.info(ret_error)


def tidevice_install_ipa(strPackagepath, deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s install %s' % (deviceID, strPackagepath)
    else:
        cmd = 'tidevice install "%s"' % (strPackagepath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    print(res)
    print(ret_error)
    try:
        ret_error = str(res, encoding='gbk')
    except:
        ret_error = str(res, encoding='utf8')
    logger.info(ret_error)

def pymobiledevice3_install_ipa(strPackagepath, deviceID=None):
    if deviceID:
        cmd = f'pymobiledevice3 apps install {strPackagepath} --udid {deviceID}'
    else:
        cmd = f'pymobiledevice3 apps install {strPackagepath}'

    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    print(res)
    print(ret_error)
    try:
        ret_error = str(res, encoding='gbk')
    except:
        ret_error = str(res, encoding='utf8')
    logger.info(ret_error)


def mobile_install_app(strPackagepath,deviceID):
    if '-' in deviceID:
        #tidevice_install_ipa(strPackagepath, deviceID)
        pymobiledevice3_install_ipa(strPackagepath, deviceID)
    else:
        adb_install_apk(strPackagepath, deviceID)


def adb_uninstall_apk(package, deviceID=None):
    if deviceID:
        cmd = 'adb -s %s uninstall %s' % (deviceID, package)
    else:
        cmd = 'adb uninstall %s' % (package)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)


def tidevice_uninstall_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s uninstall %s' % (deviceID, bundleID)
    else:
        cmd = 'tidevice uninstall %s' % (bundleID)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)

def pymobiledevice3_uninstall_ipa(bundleID, deviceID=None):
    if deviceID:
        cmd = f'pymobiledevice3 apps uninstall {bundleID} --udid {deviceID}'
    else:
        cmd = f'pymobiledevice3 apps uninstall {bundleID}'
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)

def mobile_uninstall_app(package, deviceID):
    if '-' in deviceID:
        #tidevice_uninstall_ipa(package, deviceID)
        pymobiledevice3_uninstall_ipa(package, deviceID)
    else:
        adb_uninstall_apk(package, deviceID)



def adb_file_exist(file_path, deviceID=None):
    file_path = file_path.replace('\\', '/')
    ''''adb shell ls / sdcard / Android / data / com.seasun.xgame.tako / files / version'''
    if deviceID:
        cmd = "adb -s %s shell ls %s" % (deviceID, file_path)
    else:
        cmd = "adb shell ls %s" % (file_path)
    print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    print(res)
    ret_error = pi.stderr.readline()
    print(ret_error)
    # ret_code = pi.returncode
    # print('filecontrol_file_exist: %s res= %s ret_code=%d ret_error=%s' % (cmd, res, 1, ret_error))
    # print('[DEBUG] %s [Res] %s' % (cmd, ret_error))
    if 'No such file or directory' in str(ret_error, encoding='gbk'):
        return False
    else:
        return True


def tidevice_file_exist(file_path, bundleID, deviceID=None):
    file_path = file_path.replace('\\', '/')
    ''''adb shell ls / sdcard / Android / data / com.seasun.xgame.tako / files / version'''
    if deviceID:
        cmd = "tidevice -u %s fsync -B %s ls %s" % (deviceID, bundleID, file_path)
    else:
        cmd = "tidevice fsync -B %s ls %s" % (bundleID, file_path)
    # print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    # print(res)
    ret_error = pi.stderr.readline()
    if file_path.split('/')[-1] not in str(res, encoding='gbk'):
        return False
    else:
        return True


def pymobiledevice3_file_exist(file_path, bundleID, deviceID=None):
    file_path = file_path.replace('\\', '/')
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = False
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        result = py3Service.HouseArrest.exists(file_path)
    except ConnectionTerminatedError as e:
        #AFC服务报错
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_file_exist(file_path, bundleID, deviceID)
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return result


def filecontrol_existFileOrFolder(uPath, deviceID=None, bundleID=None):
    uPath=uPath.strip()
    #logger = logging.getLogger(str(os.getpid()))
    #logger.info(uPath)
    if 'sdcard/Android' in uPath:
        return adb_file_exist(uPath, deviceID)
    elif '/Documents' in uPath:
        #return tidevice_file_exist(uPath, bundleID, deviceID)
        return pymobiledevice3_file_exist(uPath, bundleID, deviceID)
    else:
        return os.path.exists(uPath)

#结束adb设备端口
def adb_forward_remove(deviceID=None):
    if deviceID:
        cmd = "adb -s %s  forward --remove-all" % (deviceID)
    else:
        cmd = "adb forward --remove-all"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def adb_file_rm(file_path, deviceID=None):
    file_path = file_path.replace('\\', '/')
    list_content = file_path.split('/')
    if deviceID:
        cmd = "adb -s %s shell rm %s" % (deviceID, file_path)
    else:
        cmd = "adb shell rm %s" % (file_path)
    if '.' not in list_content[len(list_content) - 1]:
        if deviceID:
            cmd = "adb -s %s shell rm -r %s" % (deviceID, file_path)
        else:
            cmd = "adb shell rm -r %s" % (file_path)
    #print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    # if remove a not exist file with have blew errror info
    #
    #print(res)
    #print(ret_error)
    if 'No such file or directory' in str(ret_error, encoding='gbk'):
        return False
    else:
        return True


def tidevice_file_rm(file_path, bundleID, deviceID=None):
    file_path = file_path.replace('\\', '/')
    list_content = file_path.split('/')
    if deviceID:
        cmd = "tidevice -u %s fsync -B %s rmtree %s" % (deviceID, bundleID, file_path)
    else:
        cmd = "tidevice fsync -B %s rmtree %s" % (bundleID, file_path)
    if '.' in list_content[len(list_content) - 1]:
        if deviceID:
            cmd = "tidevice -u %s fsync -B %s rm  %s" % (deviceID, bundleID, file_path)
        else:
            cmd = "tidevice fsync -B %s rm %s" % (bundleID, file_path)
    print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    print(res)
    ret_error = pi.stderr.readline()
    # if remove a not exist file with have blew errror info
    #
    if 'No such file or directory' in str(ret_error, encoding='gbk'):
        return False
    else:
        return True

def pymobiledevice3_file_rm(file_path, bundleID, deviceID=None):
    file_path = file_path.replace('\\', '/')
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = True
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        py3Service.HouseArrest.rm(file_path)
    except AfcFileNotFoundError as e:
        pass
    except ConnectionTerminatedError as e:
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_file_rm(file_path, bundleID, deviceID)
        pass
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return result


def adb_GetDeviceID():
    cmd = 'adb devices'
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    res = res.decode('utf-8')
    res=res.split('\n')[1].split('\t')[0]
    res=res.strip()
    return res


def adb_determine_runapp(package, deviceID=None):
    if deviceID:
        cmd = f"adb -s %s shell dumpsys activity activities | {strSystemFindstr} mResumedActivity" % (deviceID)
    else:
        cmd = f"adb shell dumpsys activity activities | {strSystemFindstr} mResumedActivity"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    # print(res)
    # print(ret_error)
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    if package in res:
        return True
    return False


def wda_determine_runapp(package, deviceID,wc=None):
    if not wc:
        import wda
        wc = wda.USBClient(deviceID, port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
    bRes = False
    if wc.app_current()['bundleId']==package:
        bRes = True
    wc.close()
    return bRes


def mobile_determine_runapp(package, deviceID,uiControl=None):
    if '-' in deviceID:
        return wda_determine_runapp(package, deviceID,uiControl)
    else:
        return adb_determine_runapp(package, deviceID)


def adb_check_crash(bundleID, deviceID=None):
    if deviceID:
        cmd = f"adb -s %s shell dumpsys activity | {strSystemFindstr} %s" % (deviceID,bundleID)
    else:
        cmd = f"adb shell dumpsys activity | {strSystemFindstr} %s" % (bundleID)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res=pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    for strLine in res.split('\n'):
        if 'crashed' in strLine.lower():
            return True
    return False


def tidevice_check_crash(bundleID, deviceID = None):
    if deviceID:
        cmd = "tidevice -u %s applist" % (deviceID)
    else:
        cmd = "tidevice applist"
    strAppName = ''
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    for strAppInfo in res.split('\n'):
        if bundleID in strAppInfo:
            strAppName = strAppInfo.split(' ')[1].lower()
            break
    strTempPath = os.path.join(os.getcwd(),'Crash')
    if filecontrol_existFileOrFolder(strTempPath):
        filecontrol_deleteFileOrFolder(strTempPath)
    filecontrol_createFolder(strTempPath)

    #保留系统宕机原始文件
    print("crash")
    print(strTempPath)
    if deviceID:
        cmd = "tidevice -u %s crashreport %s" % (deviceID, strTempPath)
    else:
        cmd = "tidevice crashreport %s" % (strTempPath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    bCrashFlag = False
    for fileName in os.listdir(strTempPath):
        if strAppName in fileName.lower():
            bCrashFlag = True
            break
    return bCrashFlag



def mobile_check_crash(bundleID, deviceID):
    if '-' in deviceID:
        return tidevice_check_crash(bundleID,deviceID)
    else:
        return adb_check_crash(bundleID,deviceID)


def u2_switch_background(deviceID,strScreenShotPath,d=None):
    if not d:
        import uiautomator2 as u2
        d = u2.connect_usb(deviceID)
    d.healthcheck()
    d(resourceId="com.android.systemui:id/recent_apps").click()
    time.sleep(3)
    d.screenshot().save(strScreenShotPath)
    time.sleep(3)
    d(resourceId="com.android.systemui:id/recent_apps").click()
    time.sleep(1)


def wda_switch_background(deviceID,strScreenShotPath,wc=None):
    if not wc:
        import wda
        wc = wda.USBClient(deviceID, port=8100, wda_bundle_id='com.facebook.WebDriverAgentRunner.xctrunner')
    w, h = wc.window_size()
    wc.double_tap(int(w * 0.91), int(h * 0.95))
    time.sleep(3)
    wc.screenshot(strScreenShotPath)
    time.sleep(2)
    wc.healthcheck()
    time.sleep(1)
    wc.healthcheck()
    wc.close()

def mobile_switch_background(deviceID,strScreenShotPath,uiControl=None):
    #ios端不用切换后台
    if '-' in deviceID:
        #wda_switch_background(deviceID,strScreenShotPath,uiControl)
        tidevice_screenshot(deviceID,strScreenShotPath)
    else:
        u2_switch_background(deviceID,strScreenShotPath,uiControl)

def tidevice_get_battery(deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s battery' % (deviceID)
    else:
        cmd = 'tidevice battery'
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    for strBatteryInfo in res.split('\r\n'):
        list_BatteryInfo=strBatteryInfo.split(' ')
        strInfo=list_BatteryInfo[-1]
        if '%' in strInfo:
            #print(strInfo)
            return int(strInfo.split('%')[0])
    #print(res)

def adb_get_battery(deviceID=None):
    if deviceID:
        cmd = f"adb -s %s shell dumpsys battery |{strSystemFindstr} level" % (deviceID)
    else:
        cmd = f"adb shell dumpsys battery |{strSystemFindstr} level"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res=pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    #print(res)
    return int(res.split(' ')[-1])

def mobile_get_battery(deviceID):
    if '-' in deviceID:
        #wda_switch_background(deviceID,strScreenShotPath)
        return tidevice_get_battery(deviceID)
    else:
        return adb_get_battery(deviceID)



def adb_logcat_clear(deviceID=None):
    if deviceID:
        cmd = "adb -s %s logcat -c" % (deviceID)
    else:
        cmd = "adb logcat -c"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    #res=pi.stdout.read()
    return

def tidevice_logcat_clear(deviceID=None):
    strTempPath = os.path.join(os.getcwd(), 'Crash')
    if filecontrol_existFileOrFolder(strTempPath):
        filecontrol_deleteFileOrFolder(strTempPath)
    filecontrol_createFolder(strTempPath)
    # 保留系统宕机原始文件
    # print("crash")
    # print(strTempPath)
    if deviceID:
        cmd = f"tidevice -u {deviceID} crashreport {strTempPath}"
    else:
        cmd = f"tidevice crashreport {strTempPath}"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    filecontrol_deleteFileOrFolder(strTempPath)
    return

def mobile_logcat_clear(deviceID=None):
    if '-' in deviceID:
        return tidevice_logcat_clear(deviceID)
    else:
        return adb_logcat_clear(deviceID)

def adb_get_address(deviceID):
    if deviceID:
        cmd = f"adb -s %s shell ip -f inet addr|{strSystemFindstr} wlan0" % (deviceID)
    else:
        cmd = f"adb -s shell ip -f inet addr|{strSystemFindstr} wlan0"
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res=pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    for strLine in res.split('\n'):
        if 'inet' in strLine:
            return strLine.split(' ')[5].split('/')[0]
    return 'error'

def wda_get_address(deviceID,wc=None):
    if not wc:
        import wda
        #临时测试
        if deviceID == '00008110-000930A414D9801E':
            wdaName = 'com.facebook.WebDriverAgentRunner.xctrunner.xctrunner'
            # self.packageName='com.seasun.jx3'
        else:
            wdaName = 'com.facebook.WebDriverAgentRunner.xctrunner'
        wc = wda.USBClient(deviceID, port=8100,wda_bundle_id=wdaName)
    strAddress=wc.status()['ios']['ip']
    wc.close()
    return strAddress

def mobile_get_address(deviceID,uiControl=None):
    strAddress=''
    if '-' in deviceID:
        strAddress=wda_get_address(deviceID,uiControl)
    else:
        strAddress=adb_get_address(deviceID)
    return strAddress

def adb_mkdir(strPath, deviceID):
    if deviceID:
        cmd = "adb -s %s shell mkdir %s" % (deviceID, strPath)
    else:
        cmd = "adb shell mkdir %s" % (strPath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    print(cmd)
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)


def tidevice_mkdir(strPath, bundleID, deviceID=None):
    if deviceID:
        cmd = "tidevice -u %s fsync -B %s mkdir %s" % (deviceID, bundleID, strPath)
    else:
        cmd = "tidevice fsync -B %s mkdir %s" % (bundleID, strPath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    print(res)

def pymobiledevice3_mkdir(strPath, bundleID, deviceID=None):
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = True
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        py3Service.HouseArrest.makedirs(strPath)
    except ConnectionTerminatedError as e:
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_mkdir(strPath, bundleID, deviceID)
        pass
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return result

def filecontrol_createFolder(dst, deviceID=None, bundleID=None):
    dst=dst.strip()
    if 'sdcard/Android' in dst:
        # 安卓以files文件夹为base文件夹
        dst = dst.replace('\\', '/')
        strBasePath = dst[:dst.find('files') + 5]
        strMkDir = dst[len(strBasePath) + 1:]
        list_Mkdir = strMkDir.split('/')
        for dir in list_Mkdir:
            strBasePath = strBasePath + '/' + dir
            if not adb_file_exist(strBasePath, deviceID):
                adb_mkdir(strBasePath, deviceID)
    elif '/Documents' in dst:
        # ios以Documents文件夹为base文件夹
        #支持ios>=17
        pymobiledevice3_mkdir(dst, bundleID, deviceID)
        '''
        strBasePath = dst[:dst.find('Documents') + 9]
        strMkDir = dst[len(strBasePath) + 1:]
        list_Mkdir = strMkDir.split('/')
        print(list_Mkdir)
        for dir in list_Mkdir:
            strBasePath = strBasePath + '/' + dir
            if not tidevice_file_exist(strBasePath, bundleID, deviceID):
                tidevice_mkdir(strBasePath, bundleID, deviceID)'''
    else:
        os.makedirs(dst, exist_ok=True)


def adb_getFolderLastestFile(src,dst,deviceID=None):
    if deviceID:
        cmd = 'adb -s %s shell "ls -t %s | head -n 1"' % (deviceID,src)
    else:
        cmd = 'adb shell "ls -t %s | head -n 1"' % (src)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    res=res.split('\n')[0]
    res=res.strip()
    src=src+'/'+res
    dst=os.path.join(dst,res)

    if deviceID:
        cmd = "adb -s %s pull %s %s" % (deviceID, src, dst)
    else:
        cmd = "adb pull %s %s" % (src, dst)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    #print(res)
    return dst

def tidevice_getFolderLastestFile(src,dst,deviceID=None,bundleID=None):
    if deviceID:
        cmd = "tidevice -u %s fsync -B %s ls %s" % (deviceID, bundleID, src)
    else:
        cmd = "tidevice fsync -B %s ls %s" % (bundleID, src)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    #strLastestFileInfo = res.split('\n')[0]
    #print(strLastestFileInfo)
    #list_lastestFileInfo = strLastestFileInfo.split('  ')
    #strFileName = list_lastestFileInfo[-1]
    #print(strFileName)
    strFileName=res.split('\n')[0].split('  ')[-1]
    strFileName=strFileName.strip()
    dst = os.path.join(dst, strFileName)
    src=src+'/'+strFileName
    if deviceID:
        cmd = f"tidevice -u %s fsync -B %s pull %s %s" % (deviceID, bundleID, src, dst)
    else:
        cmd = f"tidevice fsync -B %s pull %s %s" % (bundleID, src, dst)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    #print(res)
    return dst

def pymobiledevice3_getFolderLastestFile(src, dst, deviceID=None, bundleID=None):
    py3Service = Pymobiledevice3Service(deviceID)
    #py3Service.ini_HouseArrestService(bundleID)
    result = True
    try:
        py3Service.reConnect_HouseArrestService(bundleID)
        list_fileName = py3Service.HouseArrest.listdir(src)
        dic_fileInfo = {}
        for strFileName in list_fileName:
            info = py3Service.HouseArrest.stat(f"{src}/{strFileName}")
            dic_fileInfo[strFileName] = info['st_mtime']
        # print(dic_fileInfo)

        now = datetime.datetime.now()

        # 找到与当前时间最近的那个键
        strLastestFileName = min(dic_fileInfo, key=lambda k: abs((dic_fileInfo[k] - now).total_seconds()))
        src = f"{src}/{strLastestFileName}"

        if '.' in os.path.basename(dst):
            # dst为文件
            os.makedirs(os.path.dirname(dst), exist_ok=True)
        else:
            # dst为文件夹
            os.makedirs(dst, exist_ok=True)
            dst = os.path.join(dst, strLastestFileName)
        # print(src)
        # print(dst)
        py3Service.HouseArrest.pull(src, dst)
    except ConnectionTerminatedError as e:
        py3Service.reConnect_HouseArrestService(bundleID)
        pymobiledevice3_getFolderLastestFile(src, dst, deviceID, bundleID)
        pass
    except Exception:
        result = False
        info = traceback.format_exc()
        print(info)
    return dst

def win_getFolderLastestFile(src,dst):
    list_strFileName = os.listdir(src)
    strFileName = max(list_strFileName, key=lambda x: os.path.getmtime(os.path.join(src, x)))
    src= os.path.join(src, strFileName)
    dst=os.path.join(dst, strFileName)
    filecontrol_copyFileOrFolder_windows(src,dst)
    return dst

def linux_getFolderLastestFile(src,dst):
    list_strFileName = os.listdir(src)
    strFileName = max(list_strFileName, key=lambda x: os.path.getmtime(os.path.join(src, x)))
    src = os.path.join(src, strFileName)
    dst = os.path.join(dst, strFileName)
    filecontrol_copyFileOrFolder_linux(src, dst)
    return dst

def macos_getFolderLastestFile(src,dst):
    list_strFileName = os.listdir(src)
    strFileName = max(list_strFileName, key=lambda x: os.path.getmtime(os.path.join(src, x)))
    src= os.path.join(src, strFileName)
    dst=os.path.join(dst, strFileName)
    filecontrol_copyFileOrFolder_macos(src,dst)
    return dst

def filecontrol_getFolderLastestFile(src,dst, deviceID=None, bundleID=None):
    #获取 src文件夹中的最新文件到 dst文件夹
    strRetFilePath=None
    src=src.strip()
    dst=dst.strip()
    dst = dst.replace('/', '\\')

    if 'sdcard/Android' in src:
        # 安卓以files文件夹为base文件夹
        src = src.replace('\\', '/')
        strRetFilePath=adb_getFolderLastestFile(src,dst,deviceID)
    elif '/Documents' in src:
        # ios以Documents文件夹为base文件夹
        src = src.replace('\\', '/')
        #strRetFilePath=tidevice_getFolderLastestFile(src,dst,deviceID,bundleID)
        strRetFilePath = pymobiledevice3_getFolderLastestFile(src, dst, deviceID, bundleID)
    elif strOS == 'Darwin':
        strRetFilePath=macos_getFolderLastestFile(src,dst)
    elif strOS == 'Linux':
        strRetFilePath=linux_getFolderLastestFile(src,dst)
    else:
        strRetFilePath=win_getFolderLastestFile(src,dst)
    return strRetFilePath


def filecontrol_find_folder_path(root, foldername):
    list_FileName=[]
    for dirpath, dirnames, filenames in os.walk(root):
        if foldername in dirnames:
            folder_path = os.path.join(dirpath, foldername)
            list_FileName.append(folder_path)
    return list_FileName

def copyFileOrFolder_adb(src, dst, deviceID=None):
    print(src + ' :   ' + dst)
    # android12以上版本必须先逐级创建路径
    if '.' in src:
        adb_push(src, dst, deviceID)
        return
    if not adb_file_exist(dst,deviceID):
        adb_mkdir(dst, deviceID)
    for file in os.listdir(src):
        copyFileOrFolder_adb(src + os.sep + file, dst + '/' + file, deviceID)


def copyFileOrFolder_tidevice(src, dst, bundleID, deviceID=None):
    print(src + ' :   ' + dst)
    if '.' in src:
        tidevice_push(src, dst, bundleID, deviceID)
        return
    if not tidevice_file_exist(dst, bundleID, deviceID):
        tidevice_mkdir(dst, bundleID, deviceID)
    for file in os.listdir(src):
        copyFileOrFolder_tidevice(src + os.sep + file, dst + '/' + file, bundleID, deviceID)

def copyFileOrFolder_pymobiledevice3(src, dst, bundleID, deviceID=None):
    print(src + ' :   ' + dst)
    if '.' in src:
        tidevice_push(src, dst, bundleID, deviceID)
        return
    if not tidevice_file_exist(dst, bundleID, deviceID):
        tidevice_mkdir(dst, bundleID, deviceID)
    for file in os.listdir(src):
        copyFileOrFolder_tidevice(src + os.sep + file, dst + '/' + file, bundleID, deviceID)



def filecontrol_copyFileOrFolder(src, dst, deviceID=None, bundleID=None):
    # surport mobile
    src=src.strip()
    dst=dst.strip()
    if 'sdcard/Android' in src:
        src = src.replace('\\', '/')
        return adb_pull(src, dst, deviceID)
    if 'sdcard/Android' in dst:
        dst = dst.replace('\\', '/')
        # android12以上版本必须先逐级创建路径 因为如果为文件 没有路径会报错
        strPath = dst[:dst.find(dst.split('/')[-1]) - 1]
        filecontrol_createFolder(strPath, deviceID)
        copyFileOrFolder_adb(src, dst, deviceID)
        return True

    if '/Documents' in src:
        src = src.replace('\\', '/')
        #return tidevice_pull(src, dst, bundleID, deviceID)
        return pymobiledevice3_pull(src, dst, bundleID, deviceID)
    if '/Documents' in dst:
        dst = dst.replace('\\', '/')
        # ios可直接创建路径
        '''
        strPath = dst[:dst.find(dst.split('/')[-1]) - 1]
        # print("strPath1: " + strPath)
        filecontrol_createFolder(strPath, deviceID, bundleID)
        # print("strPath2: " + strPath)
        copyFileOrFolder_tidevice(src, dst, bundleID, deviceID)'''
        #支持ios>=17
        pymobiledevice3_push(src, dst, bundleID, deviceID)

        return True
    if strOS == "Windows":
        return filecontrol_copyFileOrFolder_windows(src, dst)
    elif strOS == "Linux":
        return filecontrol_copyFileOrFolder_linux(src, dst)
    elif strOS == 'Darwin':
        return filecontrol_copyFileOrFolder_macos(src,dst)


def md5File(filepath):
    md5_hash = hashlib.md5
    with open(filepath, 'rb') as f:
        data = f.read()
        return md5_hash(data).hexdigest()


def getListAllFiles(case_path):
    listAllFiles = []
    g = os.walk(case_path)
    for path, dir_list, file_list in g:
        for file_name in file_list:
            file_path = os.path.join(path, file_name)
            listAllFiles.append(file_path)
    return listAllFiles


# def getStrListdir(case_path):
#     thisCacheListdir = ''
#     dirs = os.listdir(case_path)
#     dirs.sort()
#     for dir in dirs:
#         fullpath = os.path.join(case_path, dir)
#         if os.path.isdir(fullpath):
#             str = getStrListdir(fullpath)
#             thisCacheListdir = thisCacheListdir + dir + str
#         else:
#             thisCacheListdir = thisCacheListdir + dir
#     return thisCacheListdir


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


#--------------macos--------------------------
def macos_kill_process(process_name):
    subprocess.run(["pkill", process_name])

def macos_kill_process_family_by_pid(pid):
    os.killpg(os.getpgid(int(pid)), 9)

def macos_findProcessByPid(pid):
    process = psutil.Process(pid)
    return process


def macos_findProcessByName(process_name, szCmdLine=None):
    for process in psutil.process_iter(['pid', 'name']):
        if process.info['name'] == process_name:
            return process
    return False


def macos_runExe(path):
    process = win32_runExe_no_wait(path)
    process.wait()

def macos_runExe_no_wait(path):
    # os.chdir(path)
    # absolute_exe = path + '/' + exe
    #path = '/Applications/YourApp.app'  # 替换为应用程序的路径
    process =subprocess.Popen(['open', path])
    return process

# -------------win32---------------------------
def win32_kill_process(process_name):
    while win32_findProcessByName(process_name):
        os.system('TASKKILL /F /t /IM %s' % process_name)

def kill_process_if_cmd_contains(*keywords):
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmd = ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
            # 同时包含所有关键字才结束
            if all(k.lower() in cmd.lower() for k in keywords):
                print(f"Killing {proc.info['pid']} {proc.info['name']}  {cmd}")
                proc.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

def win32_kill_process_by_cmd(process_name, szCmdLine=None):
    listP = win32_findProcessByName(process_name, szCmdLine=szCmdLine)
    if listP:
        for p in listP:
            os.system('TASKKILL /F /t /pid %s' % p.pid)

def win32_kill_process_by_pid(nPid):
    os.system('TASKKILL /F /t /pid %s' % nPid)


def win32_reboot():
    # global logger
    # logger.info("reboot now!")
    os.system('shutdown.exe -r -f -t 0')


def win32_findProcessByPid(pid):
    for proc in psutil.process_iter():
        if proc.pid == pid:
            return proc
    return False


def win32_findProcessByName(name, szCmdLine=None):
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
    proc = subprocess.Popen(exe, cwd=path, creationflags=subprocess.CREATE_NEW_CONSOLE)
    return proc


def win32_SetRegForPakv4Update(INSTPATH, bEXP=True):
    # try:
    if bEXP:
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE, r'Software', 0, win32con.KEY_ALL_ACCESS)
        reg = winreg.CreateKey(key, r'JX3Installer_EXP')
        winreg.CloseKey(key)
        key = winreg.OpenKey(win32con.HKEY_LOCAL_MACHINE, r'Software\JX3Installer_EXP', 0, win32con.KEY_ALL_ACCESS)
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
    return result  # 0表示已锁屏


# ---------------------linux---------------------------
def linux_findProcessByName(name, szCmdLine=None):
    return win32_findProcessByName(name, szCmdLine)





# ---------read write file and log-----------

# adbShell = "adb shell logcat"
# logString = "lua"  # 定位关键字
# timeStamp = ''#time.mktime(time.strptime(str(datetime.date.today()), "%Y-%m-%d"))
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
        return False  # 没找到LOG文件夹，不算卡死（可能在更新）
    for entry in os.listdir(log_path):  # 找到最新创建的日志
        filepath = log_path + '/' + entry
        if os.path.getctime(filepath) > last_create_time:
            last_create_file = filepath
            last_create_time = os.path.getctime(filepath)
    if last_create_file is None:  # 今天没有日志文件，不算卡死（可能在更新）
        return False
    return last_create_file


def findStringInLog(file, logString, offset=0):
    f = open(file, 'rb')
    f.seek(offset)
    while 1:
        line = f.readline()
        if line == b'':
            break
        try:
            line = str(line, encoding='gbk')
        except:
            line = str(line)
        if line.find(logString) != -1:
            offset = f.tell()
            f.close()
            return True, offset
    offset = f.tell()
    f.close()
    return False, offset


def changeStrInFile(file, old_str, new_str):
    try:
        with open(file, 'r+',encoding='gbk') as f:
            all_lines = f.readlines()
            f.seek(0)
            f.truncate()
            for line in all_lines:
                line = line.replace(old_str, new_str)
                f.write(line)
    except:
        with open(file, 'r+',encoding='utf8') as f:
            all_lines = f.readlines()
            f.seek(0)
            f.truncate()
            for line in all_lines:
                line = line.replace(old_str, new_str)
                f.write(line)

def insert_after_keyword(input_file: str, output_file: str, keyword: str, insert_line: str, encoding: str = "gbk"):
    """
    在输入文件中查找包含关键字的行，并在其后插入指定的新行。

    参数：
        input_file : 输入文件路径
        output_file: 输出文件路径
        keyword    : 需要匹配的关键字
        insert_line: 要插入的新行内容（不含换行符）
        encoding   : 文件编码，默认为 GBK
    """
    with open(input_file, "r", encoding=encoding) as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        new_lines.append(line)
        if keyword in line:  # 如果发现关键字
            new_lines.append(insert_line + "\n")  # 插入新行

    with open(output_file, "w", encoding=encoding) as f:
        f.writelines(new_lines)

def insert_before_keyword(input_file: str,output_file: str,keyword: str,insert_line: str,encoding: str = "gbk"):
    """
    在输入文件中查找包含关键字的行，
    在其上方插入指定的新行，并写入输出文件。

    :param input_file:  输入文件路径
    :param output_file: 输出文件路径
    :param keyword:     要查找的关键字
    :param insert_line: 要插入的新行内容
    :param encoding:    文件编码（默认 GBK）
    """
    with open(input_file, 'r', encoding=encoding) as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if keyword in line:
            new_lines.append(insert_line + '\n')
        new_lines.append(line)

    with open(output_file, 'w', encoding=encoding) as f:
        f.writelines(new_lines)



def WriteRunMapResult(testpoint, mapid):
    uTodday7 = date_get_uToday_7()
    folder = u'c:\\RunMapResult\\' + uTodday7
    if not os.path.exists(folder):
        os.makedirs(folder)
    filename = u'{}_{}_{}'.format(str(mapid), testpoint, uTodday7)
    with open(folder + '\\' + filename, u'w') as f:
        pass


# -------------machine info------------------

def getWinregValue(hkey, subdir, key):
    handle = winreg.OpenKey(hkey, subdir)
    value = winreg.QueryValueEx(handle, key)[0]
    return value


def isWin7():
    subDir = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    os_ProductName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'ProductName')
    if ('Windows 7' in os_ProductName):
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
        try:
            os_DisplayVersion = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'DisplayVersion')
        except:
            os_DisplayVersion = ''
        return '{}({}) {}'.format(os_ProductName, os_type, os_DisplayVersion)
    elif strOS == "Linux":
        os_name = platform.platform()
        os_type = platform.architecture()[0]
        return '{}({})'.format(os_name, os_type)
    elif strOS == 'Darwin':
        ver = platform.mac_ver()[0]
        return f'MacOS {ver}'

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
    elif strOS == 'Darwin':
        result = subprocess.run(['ipconfig', 'getifaddr', 'en0'], capture_output=True, text=True)
        return result.stdout.strip()
    # return str(socket.gethostbyname(socket.getfqdn(socket.gethostname())))


# except Exception as e:
#     print (e)
#     return 'machine_get_IPAddress_ERROR'

def machine_get_IPAddress_all():
    strOS = platform.system()
    if strOS == "Windows":
        # socket有中文兼容个问题
        # hostname = socket.gethostname()
        # hostname, aliaslist, ipaddrlist = socket.gethostbyname_ex(hostname)
        # count_ip = len(ipaddrlist)
        # strIp = ''
        # for i in range(count_ip):
        #     if strIp == '':
        #         strIp = ipaddrlist[i]
        #     else:
        #         strIp = '{} | {}'.format(strIp, ipaddrlist[i])
        strIp = ''
        pythoncom.CoInitialize()
        machine = wmi.WMI()
        obj_Win32_NetworkAdapter = machine.Win32_NetworkAdapterConfiguration(IPEnabled=1)
        count_ip = len(obj_Win32_NetworkAdapter)  # [0].IPAddress
        for i in range(count_ip):
            if strIp == '':
                strIp = obj_Win32_NetworkAdapter[i].IPAddress[0]  # [1]is ipv6
            else:
                strIp = '{} | {}'.format(strIp, obj_Win32_NetworkAdapter[i].IPAddress[0])
        return strIp

    elif strOS == "Linux":
        mess_ip = os.popen('hostname -I')
        mess = mess_ip.readlines()
        mes = mess[0].split(' ')
        ip = mes[0]
        return ip
    elif strOS == 'Darwin':
        result = subprocess.run(['ifconfig'], capture_output=True, text=True)
        output = result.stdout
        ips = [line.split('inet ')[1].split(' ')[0] for line in output.split('\n') if 'inet ' in line]
        return '|'.join(ips)


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
        return str(int(multiprocessing.cpu_count() / 2))
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


def machine_get_PhysicalMemorySize():  # Byte
    mem = psutil.virtual_memory()
    return mem.total


def machine_get_PhysicalDiskInfo():  # Byte
    disks = psutil.disk_partitions()
    dicDiskInfo = {}
    for disk in disks:
        try:
            disk_usage = psutil.disk_usage(disk.mountpoint)
            dicDiskInfo[disk.mountpoint] = {'total': disk_usage.total, 'free': disk_usage.free,
                                            'percent': disk_usage.percent}
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
    # 先判断是不是虚拟client
    # 如果是用例运行，通过获取路径中的case，来定位client的目录
    client_folder = os.path.realpath(__file__).split('case')[0].strip(os.sep).split(os.sep)[-1]
    if 'Android' in client_folder or 'IOS' in client_folder:
        return client_folder
    # 如果是运行的client，通过判断是否有配置文件来定位client的目录
    current_script_path = os.path.split(os.path.realpath(__file__))[0]
    key_file = os.path.join(current_script_path, 'ClientConfig.ini')
    if os.path.exists(key_file):
        client_folder = current_script_path.split(os.sep)[-1]
        if 'Android' in client_folder or 'IOS' in client_folder:
            return client_folder
    # 非虚拟client
    strOS = platform.system()
    if strOS == "Windows":
        key = win32api.RegOpenKey(win32con.HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Cryptography", 0,
                                  win32con.KEY_READ)
        guid = win32api.RegQueryValueEx(key, 'MachineGuid')[0]
        win32api.RegCloseKey(key)
        return guid
    elif strOS == "Linux" or strOS == 'Darwin':
        uuid_path = os.path.join(os.path.expanduser('~'), 'iqb-uuid')

        def creat_uuid():
            uuid = get_a_uuid()
            os.makedirs(uuid_path)
            with open(os.path.join(uuid_path, uuid), 'w'):
                pass
            return uuid

        if not os.path.exists(uuid_path):
            return creat_uuid()
        else:
            list_file = os.listdir(uuid_path)
            if len(list_file) < 1:
                return creat_uuid()
            elif len(list_file) > 1:
                raise Exception('iqb-uuid too many uuid')
            return list_file[0]

        # cmd = "dmidecode -s system-uuid | tr 'A-Z' 'a-z'"
        # result = os.popen(cmd)
        # guid = result.read().replace("\n", "")
        return uuid


# except Exception as e:
#     print ('get guid error')
#     return None

def get_a_uuid():
    return str(uuid.uuid4())


def machine_reload_guid():
    # try:
    strOS = platform.system()
    if strOS == "Windows":
        key = win32api.RegOpenKey(win32con.HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Cryptography", 0,
                                  win32con.KEY_ALL_ACCESS)
        guid = get_a_uuid()
        win32api.RegSetValueEx(key, 'MachineGuid', 0, win32con.REG_SZ, guid)
        win32api.RegCloseKey(key)
    elif strOS == "Linux":
        pass


# except Exception as e:
#     print ('reload guid error')
#     return None

def getMachineInfoString():
    strMachineInfo = '{}<br/>{}<br/>{}<br/>{}<br/>{}<br/>{}<br/>{}'.format(
        machine_get_DeviceName(),
        machine_get_CPUInfo_v2(),
        machine_get_VideoCardInfo_v2(),
        'RAM {}GB'.format(round(machine_get_PhysicalMemorySize() / 1024.0 / 1024 / 1024)),
        machine_get_IPAddress_all(),
        machine_get_OSInfo(),
        machine_get_DiskDriveInfo()
    )
    return strMachineInfo


# --------------svn----------------
def get_package_list(folder_path: str, file_info_separator: str, file_date_separator: str, sort_reverse=True,
                     sort_func=None):
    # 排序函数
    def SortByMinutes_dic(dic_info):
        # logger.info(dic_info)
        return dic_info['strDate'] + file_info_separator + dic_info['strTime']

    list_fileInfo = []
    sort_func = sort_func if sort_func is not None else SortByMinutes_dic

    for _root, dirs, files in os.walk(folder_path):
        for strFileName in files:
            dic_content = {}
            strDate = strFileName[:-4].split(file_info_separator)[-2]
            strTime = strFileName[:-4].split(file_info_separator)[-1]

            dic_content['strDate'] = strDate
            dic_content['strTime'] = strTime
            # 路径
            dic_content['strContent'] = os.path.join(_root, strFileName)
            dic_content['strSize'] = os.path.getsize(dic_content['strContent'])
            dic_content['strFileName'] = strFileName
            dic_content['strVersion'] = \
                strFileName.split(file_info_separator)[0].split(file_date_separator)[-1]
            list_fileInfo.append(dic_content)
    list_fileInfo.sort(reverse=sort_reverse, key=sort_func)
    return list_fileInfo


def get_package_version(strMachineType,folder_path=os.path.join("..", "..", "..", "..", "LocalPackage")):
    if strMachineType == 'Android':
        file_type = 'apk'
        strFileDateSeparator = '-'
        strFileInfoSeparator = '_'
    elif strMachineType == 'Ios':
        file_type = 'ipa'
        strFileDateSeparator = '_'
        strFileInfoSeparator = '-'
    else:
        raise Exception(f"设备类型错误:{strMachineType},必须为:Ios Android")
    local_package_path = os.path.join(folder_path, file_type)  # 本地包存放路径
    return get_package_list(local_package_path,strFileInfoSeparator,strFileDateSeparator)[0]['strVersion']

def get_package_version():
    strPath=os.path.join("..", "..", "..", "xgame_package_version.ini")
    if not os.path.isfile(strPath):
        return None
    return ini_get('Package','version',strPath)

def svn_get_bvt_version_xgame():
    # try:
    conn = sql.connect(r"\\10.11.36.142\BranchManagerPlus_Svn1.9\RevisionConfig.db")
    cursor = conn.cursor()
    bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()[1]  # 获取今日BVT的信息
    today_date = list(map(int, date_get_szToday().split('-')))
    today_format = "%d/%d/%d" % (today_date[0], today_date[1], today_date[2])
    print(bvt_date)
    today_db = bvt_date[1].split()[0]
    if len(bvt_date) > 0 and today_db == today_format:
        server = bvt_date[2]
        client = bvt_date[3]
        print("today_BVT revision: server {}, client {}".format(server, client))
        return(server, client)
    else:
        return None


# except Exception as e:
#     print ('connect db error')
#     return None

def svn_get_bvt_version_classic():
    # try:
    conn = sql.connect(r"\\10.11.36.142\BranchManagerPlusForClassic\RevisionConfig.db")
    cursor = conn.cursor()
    bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()[0]  # 获取今日BVT的信息
    today_date = list(map(int, date_get_szToday().split('-')))
    if len(bvt_date) > 0 and str(bvt_date[2].split()[0]) == "%d/%d/%d" % (today_date[0], today_date[1], today_date[2]):
        server, client = bvt_date[:2]
        print("today_BVT revision: server {}, client {}".format(server, client))
        return (server, client)
    else:
        return None


# except Exception as e:
#     print ('connect db error')
#     return None


#XGame获取不重复账号
def xgame_generate_account():
    import pymongo
    def increment_account(account):
        account_list = list(account)
        for i in range(len(account_list) - 1, -1, -1):
            if account_list[i] != '9':
                if account_list[i] == 'z':
                    account_list[i] = '0'
                else:
                    account_list[i] = chr(ord(account_list[i]) + 1)
                break
            else:
                account_list[i] = 'a'
                if i == 0:
                    account_list.insert(0, 'a')
        return ''.join(account_list)

    try:
        while True:
            client = pymongo.MongoClient(f"mongodb://{MONGO_USER}:{MONGO_PASS}@10.11.80.122:27017/")
            db = client["XGame_Account"]
            collection = db["accounts"]
            last_account = collection.find_one({"name": "last_account"})
            last_account_value = last_account["value"] if last_account else "aaaaa"

            generated_account = increment_account(last_account_value)

            collection.replace_one(
                {"name": "last_account"},
                {"name": "last_account", "value": generated_account},
                upsert=True
            )
            if len(generated_account) >= 13:
                return False,'账户号长度已达上限'
            if generated_account == last_account_value:
                time.sleep(1)
                continue
            collection.insert_one({"account": generated_account})
            return True,generated_account
    except Exception as e:
        return False,f"生成账号失败: {e}"

def xgame_get_resource_version(platform,Date=None):
    pt = ['Ios', 'Android', 'PC']
    if platform not in pt:
        raise Exception(f"设备类型错误:{pt},必须为:Ios Android PC")
    url = "http://10.11.39.60/v5/%s/big/"
    api = url % (platform.lower()+"_bvt")
    if platform == "PC":
        api = url % "vk_exp"
    data = requests.get(api)
    data.raise_for_status()
    label_lists = data.text.split("\r\n")
    Date = Date or datetime.datetime.now().strftime("%Y-%m-%d")
    today_version_list = []
    for label in label_lists:
        if "href" in label:
            result = re.search(r'<a href=".*/">(.*?)/</a>.*?\s+(\d+-\w+-\d+\s+\d+:\d+)', label)
            if result:
                version_number = result.group(1)
                time_str = result.group(2)
                time_obj = datetime.datetime.strptime(time_str, '%d-%b-%Y %H:%M')
                if Date == time_obj.strftime("%Y-%m-%d"):
                    today_version_list.append(version_number)
    if today_version_list:
        return today_version_list[-1]
    return None

def svn_get_bvt_version():
    # try:
    conn = sql.connect(r"\\10.11.36.142\BranchManagerPlus_Svn1.9\RevisionConfig.db")
    cursor = conn.cursor()
    bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()[0]  # 获取今日BVT的信息
    today_date = list(map(int, date_get_szToday().split('-')))
    today_format = "%d/%d/%d" % (today_date[0], today_date[1], today_date[2])
    print(bvt_date)
    today_db = bvt_date[1].split()[0]
    if len(bvt_date) > 0 and today_db == today_format:
        server = bvt_date[2]
        client = bvt_date[3]
        print("today_BVT revision: server {}, client {}".format(server, client))
        return(server, client)
    else:
        return None


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

    print(cmd)
    tupRes = get_svn_loacl_info()
    if tupRes and user_readini:
        user = tupRes[0]
        passw = tupRes[1]
    if ver:
        cmd = cmd + ' -r {}'.format(ver)
    if user and passw:
        cmd = cmd + ' --username {} --password {}'.format(user, passw)
    logger.info(cmd)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()
    result = pi.returncode
    #logger.info(result)
    logger.info(f'cmd result:{result}')
    # 文件冲突
    if result != 0:
        ret_error = pi.stderr.readline()
        logger.info(f'cmd ret_error:{ret_error}')
        if "warning: W195024" in ret_error:
            svn_cmd_revert(path)
            return
        raise Exception('svn_cmd_update fail:{}'.format(str(ret_error, encoding='gbk')))
    return result


def svn_cmd_revert(path):
    path = path.replace('\\', '/')
    list_content = path.split('/')
    if '.' not in list_content[len(list_content) - 1]:
        cmd = 'svn revert -R {}'.format(path)
    else:
        cmd = 'svn revert {}'.format(path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()
    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_revert fail:{}'.format(str(ret_error, encoding='gbk')))
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
    if date[0] == 1 and date[2] == -1:
        return True


def os_popen(cmd, readline = False) -> str:
    """
    执行popen, 返回结果
    """
    with os.popen(cmd) as p:
        try:
            if readline:
                return p.readline()
            else:
                return p.read()
        except:
            return 'decode error'


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


# ------------------------
# 参数说明：
# uGuid指机器的guid，可用machine_get_guid()接口获取。
# uGuid可以直接填写ip地址，内部会自动转化为guid，但是需要机器纳入IQB平台管理。
# 机器纳入IQB平台，可订阅飞书信息。

def send_Subscriber_msg(guid, msginfo, image=None):
    def thread_send():
        try:
            image_base64 = None
            if image:
                try:
                    with open(str(image), 'rb') as img_f:
                        img_stream = img_f.read()
                        image_base64 = str(base64.b64encode(img_stream), encoding='utf8')
                except:
                    pass

            conn = socket.socket()
            conn.connect(('10.11.80.26', 8090))
            # 客户端版本，直接取guid
            if guid:
                strGUID=guid
            else:
                strGUID=machine_get_guid()
            dic = {u'guid': strGUID, u'msg': msginfo, 'image_base64': image_base64}
            msg = json.dumps(dic)
            msg = bytes(msg, encoding='utf8')
            len_msg = len(msg)
            len_msg = struct.pack('i', len_msg)
            conn.send(len_msg)
            conn.send(msg)
        except Exception as e:
            print('ERROR:(send_Subscriber_msg)')
            print(e)
            # info = traceback.format_exc()
            # initLog(u'send_Subscriber_msg')
            # logger = logging.getLogger(str(os.getpid()))
            # logger.error(info)

    t1 = threading.Thread(target=thread_send, args=())
    t1.setDaemon(True)
    t1.start()


def is_valid_ip(strIp):
    try:
        import ipaddress
        ipaddress.ip_address(strIp)
        return True
    except ValueError:
        return False

class TDRRobot:
    def __init__(self):
        self.dbConfig = {
            "url": f"mongodb://{MONGO_USER}:{MONGO_PASS}@10.11.80.122:27017/",
            "databaseName": "XGame_RobotAccount",
            "collectionName": "accounts",
            "freeCollection":"freePool",
            "runCollection":"runPool"
        }
        self.apiUrl = "http://10.11.80.233:8110/"

        self.szKey = None

    def __getCollection(self,name):
        import pymongo
        self.__client = pymongo.MongoClient(self.dbConfig["url"])
        database = self.__client.get_database(self.dbConfig["databaseName"])
        collection = database.get_collection(name)
        return collection

    def mallocRobot(self,robotNum):
        r = requests.get(self.apiUrl+"mallocRobot", params={"robotNum": 24})
        r.raise_for_status()
        data = r.json()["data"]
        if isinstance(data,str):
            raise Exception(data)
        szKey, szName, nStartIndex, nEndIndex = data["szKey"], data["szName"], data["nStartIndex"], data["nEndIndex"]
        self.szKey = szKey
        logger = logging.getLogger(str(os.getpid()))
        logger.info(f'Robot key:{self.szKey}')
        return szName, nStartIndex, nStartIndex+robotNum-1

    def releaseRobot(self):
        r = requests.get(self.apiUrl + "releaseRobot", params={"szKey": self.szKey})
        r.raise_for_status()
        data = r.json()["data"]
        if data:
            raise Exception(data)

    def restore(self): #谨慎调用,重置账号池
        free_pool = self.__getCollection(self.dbConfig["freeCollection"])
        run_pool = self.__getCollection(self.dbConfig["runCollection"])
        accounts = self.__getCollection(self.dbConfig["collectionName"])
        free_pool.delete_many({})
        run_pool.delete_many({})
        free_pool.insert_many(accounts.find())

class Connect(object):
    def __init__(self, serverIP, port, queue_msg):
        self.conn = None
        self.serverIP = serverIP
        self.port = port
        self.queue_msg = queue_msg
        self.bThreadRecv = True
        self.log = logging.getLogger(str(os.getpid()))

    def connect(self, no_timeout=False):
        try:
            obj = socket.socket()
            if not no_timeout:
                obj.settimeout(30)
            obj.connect((self.serverIP, self.port))
            self.conn = obj
            # obj.settimeout(30)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)
            print(self.serverIP + '|' + str(self.port))
            return
        # 收包线程
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
                # print '**************'
                # print len_msg
                # print '**************'
                received_size = 0
                received_data = bytearray()
                while received_size < len_msg:
                    data = self.conn.recv(len_msg - received_size)
                    if not data:
                        break
                    received_size += len(data)
                    # recevied_data += data
                    received_data.extend(data)
                # print 'recevied_size:'+str(recevied_size)
                # print 'recevied_data'+str(recevied_data)
                recevied_data = str(received_data, encoding='utf8')
                self.queue_msg.put(recevied_data)
            except Exception:
                self.conn = None
                info = traceback.format_exc()
                if '10038' in info:  # 在一个非套接字上尝试了一个操作
                    self.log.warning(info)
                else:
                    self.log.error(info)
                break
        self.log.warning('thread_recv exit')
        self.closeConn()
