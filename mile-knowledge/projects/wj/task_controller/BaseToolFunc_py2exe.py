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
import urllib3
import requests
import telnetlib
import zipfile
import urllib.request
import urllib.parse

import openpyxl
import pandas
strOS = platform.system()
if strOS == 'Windows':
    import winreg
    from PIL import ImageGrab
    from PIL import Image
    import win32api, win32gui, win32con, win32process, win32ui
    import ctypes
    import wmi
    import pythoncom
    import pygetwindow as gw

# ---------global------------
SERVER_PATH = r'\\10.11.85.148\FileShare\JX3BVT'
SERVER_SEARCHPANEL = SERVER_PATH + r'\SearchPanel'
SERVER_IQB_FILES_FOR_NON_SVN = SERVER_PATH + '/IQB-files-for-non-svn'
SERVER_SVN = SERVER_PATH + r'\svn'
SERVER_MAINSCRIPT = SERVER_PATH + r'\MainScript'
SERVER_TOOLS = SERVER_PATH + r'\Tools'
SERVER_LOG_PATH_PERFMON = SERVER_PATH + r'\Logs\PerfMon_Data'
SERVER_LOG_PATH_CLIENT = SERVER_PATH + r'\Logs\client'
SERVER_INI = SERVER_PATH + r'\MainScript\autoBVT.ini'
SCREENSHOT_PATH = r"//10.11.181.242//FileShare//screenshot"
QCPROFILER = SERVER_PATH + r'\QCProfiler'
SERVER_DUMPRECORD = r"\\10.11.85.148\FileShare-181-242\DumpAnalyse"
SERVER_DUMPRECORD_XGAME = r"\\10.11.85.148\FileShare-181-242\DumpAnalyse_XGame"
LOCAL_INFO_FILE = r'\RunMapResult'

TIMEOUT_SYNCHRODATA = 3

WORK_PATH = os.getcwd()

SVN_USER = 'k_qc_pc_optimize'
SVN_PASS = 'aCc250DZ+15'

# ---------mongodb------------
MONGO_USER = "admin"
MONGO_PASSWORD = "chDjJeUrlLspJiK8yut"


# 本svn帐号还需要找mali申请访问权限

# --------------log-------------
# 使用说明： 本log模块使用进程id来处理多进程写日志问题
# 直接初始化 initLog('test')
# 使用的时候可以获取logger = logging.getLogger(str(os.getpid()))
# logger.error('123')
# 如果是类，可以self.log = logging.getLogger(str(os.getpid()))
# self.log.error('321')

class MyLogHandler(logging.Handler, object):
    """
    自定义日志handler
    """

    def __init__(self):
        logging.Handler.__init__(self)

    def emit(self, record):
        """
        emit函数为自定义handler类时必重写的函数，这里可以根据需要对日志消息做一些处理，比如发送日志到服务器

        发出记录(Emit a record)
        """
        try:
            msg = self.format(record)
            levelname = getattr(record, 'levelname')
            if levelname == 'ERROR':
                send_Subscriber_msg(None, msg, image=None)

        except Exception:
            self.handleError(record)


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
    # handler_Socket = logging.handlers.DatagramHandler('10.11.176.54', 1231)
    # handler_Socket.setFormatter(fmt)
    handler_my = MyLogHandler()
    fmt_no_time = logging.Formatter("%(levelname)s - %(name)s - %(filename)s - %(lineno)d - %(message)s")
    handler_my.setFormatter(fmt_no_time)

    logger.addHandler(handler_Screen)
    logger.addHandler(handler_Timed_file)
    # logger.addHandler(handler_Socket)
    logger.addHandler(handler_my)
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

def text_similarity(text1, text2):
    import difflib
    # 创建SequenceMatcher对象
    matcher = difflib.SequenceMatcher(None, text1, text2)
    # 计算相似度比例
    ratio = round(matcher.ratio(), 2)
    return ratio


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

def crop_and_scale_image(pic_path, pos_x, pos_y, width, height, scale):
    """
    截取图片的指定区域，并根据给定的比例进行缩放后保存。

    参数:
    pic_path: str, 要截取的图片的路径。
    pos_x: int, 原始尺寸下矩形区域的x坐标。
    pos_y: int, 原始尺寸下矩形区域的y坐标。
    width: int, 原始尺寸下矩形区域的宽度。
    height: int, 原始尺寸下矩形区域的高度。
    scale: float, 缩放比例。

    返回:
    缩放后的子区域图片的保存路径。
    """
    try:
        # 打开图片并获取原始尺寸
        with Image.open(pic_path) as img:
            original_width, original_height = img.size

            # 计算新的尺寸
            new_width = int(original_width * scale)
            new_height = int(original_height * scale)

            # 如果图片已经等比缩放，则需要调整截取区域的尺寸和位置
            if scale != 1:
                # 计算缩放后的坐标和尺寸
                scaled_pos_x = int(pos_x * scale)
                scaled_pos_y = int(pos_y * scale)
                scaled_width = int(width * scale)
                scaled_height = int(height * scale)

                # 截取图片的子区域
                cropped_img = img.crop((scaled_pos_x, scaled_pos_y, scaled_pos_x + scaled_width, scaled_pos_y + scaled_height))
            else:
                # 如果比例为1，则直接使用原始坐标和尺寸
                cropped_img = img.crop((pos_x, pos_y, pos_x + width, pos_y + height))

            # 保存缩放后的图片
            save_path = pic_path.rsplit('.', 1)[0] + f'_scaled_{scale}.' + pic_path.rsplit('.', 1)[1]
            cropped_img.save(save_path)
            return save_path
    except IOError:
        print("Error: 文件打开失败或路径错误。")
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
        return os.path.dirname(os.path.realpath(sys.executable))  # for pyinstaller exe
    else:
        return os.path.dirname(os.path.abspath(__file__))


# -----------date---------------
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


def date_get_szWeekday():  # Monday is 1 and Sunday is 7
    return str(datetime.datetime.now().isoweekday())


def isWorkingDayByHttp(szDate):
    return isWorkingDay(szDate)


def isWorkingDay(szDate):
    date1 = datetime.datetime.strptime(szDate, '%Y-%m-%d')
    Y = date1.year
    M = date1.month
    D = date1.day
    workday = datetime.date(Y, M, D).weekday()
    # workday 星期一是0，以此类推星期日是6
    if workday < 5:
        return True
    return False

# 获取百度日历
def getBaiDuAlmanac(szDate):
    # 获取年月日
    date_Today = datetime.datetime.strptime(szDate, '%Y-%m-%d')
    Y = date_Today.year
    M = date_Today.month
    D = date_Today.day

    query = f"{Y}年{M}月"
    # 发送请求
    url = f"https://opendata.baidu.com/data/inner?tn=reserved_all_res_tn&type=json&resource_id=52109&query={query}&apiType=yearMonthData&cb=jsonp_1738978283698_21243"
    payload = {}
    headers = {
      'Cookie': 'BAIDUID=81E16BBC91024A4967685263C7C789E6:FG=1'
    }
    response = requests.request("GET", url, headers=headers, data=payload)

    date_data = response.text
    if date_data.startswith("jsonp"):
        startIndex = date_data.find("(")
        endIndex = date_data.rfind(")")
        date_json = json.loads(date_data[startIndex + 1:endIndex])
    else:
        date_json = date_data

    almanac_list = date_json["Result"][0]["DisplayData"]["resultData"]["tplData"]["data"]["almanac"]

    return almanac_list

# 是否为法定节假日
def isLegalHoliday(szDate): # date_Today:2025-05-23
    almanac_list = getBaiDuAlmanac(szDate)

    for date in almanac_list:
        if date.get("status") == "1": # 1为法定节假日
            # print(f"{date.get('year')}年{date.get('month')}月{date.get('day')}日")
            holiday_date = datetime.datetime.strptime(f"{date.get('year')}-{date.get('month')}-{date.get('day')}", "%Y-%m-%d").strftime("%Y-%m-%d")
            if holiday_date == szDate:
                return True
    return False

# 是否补班
def isMakeUpClass(szDate): # date_Today:2025-05-23
    almanac_list = getBaiDuAlmanac(szDate)

    for date in almanac_list:
        if date.get("status") == "2": # 2为补班
            work_date = datetime.datetime.strptime(f"{date.get('year')}-{date.get('month')}-{date.get('day')}", "%Y-%m-%d").strftime("%Y-%m-%d")
            if work_date == szDate:
                return True
    return False

# 确定是否上班
def isFinalWorkingDay(szDate):
    try:
        if isLegalHoliday(szDate): # 判断法定节假日
            return False
        if isMakeUpClass(szDate): # 判断补班
            return True
        if isWorkingDay(szDate): # 判断周一至周五
            return True
        return False
    except Exception:
        return isWorkingDay(szDate)


def isWorkingTimeNow():
    now_time = time.strftime('%H', time.localtime(time.time()))
    try:
        now_time = int(now_time)
    except:
        print('强制转换错误!')
    if 9 <= now_time < 21:
        return True
    else:
        return False


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
    if type(val) == int or type(val) == float:
        val = str(val)
    iniconf.set(section, key, val)
    return ini_write(path, iniconf, encoding)


def ini_getOptions(section, path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    if section not in iniconf.sections():
        return None
    return iniconf.options(section)  # a list


def ini_getSections(path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    return iniconf.sections()  # a list


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


# --------------filecontrol-------------------
def is_directory_symlink(path):
    path = path.strip()
    return bool(os.path.isdir(path)
                and (win32api.GetFileAttributes(path) &
                     win32con.FILE_ATTRIBUTE_REPARSE_POINT))


def getFileOrFolderTypeInNT(file_dire):
    file_dire = file_dire.strip()
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
    target = target.strip()
    link = link.strip()
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


def filecontrol_deleteFileOrFolder(uFullPath, deviceID=None):
    uFullPath = uFullPath.strip()
    if 'sdcard/Android' in uFullPath:
        return adb_file_rm(uFullPath, deviceID)
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
        print(cmd)
        os.system(cmd)
        # time.sleep(2)
        repass = 10
        while True:
            try:
                if os.path.exists(uFullPath):
                    raise Exception(u'del file fail')
                else:
                    break
            except:
                time.sleep(1)
                repass -= 1
                if repass == 0:
                    raise Exception(u'del file fail')
                pass
    else:
        if is_directory_symlink(uFullPath):
            # cmd = u'rmdir ' + uFullPath + u' /F /Q'
            # print cmd
            # os.system(cmd.encode('GBK'))
            os.rmdir(uFullPath)
        else:
            cmd = u'DEL ' + uFullPath + u' /F /S /Q'
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

def win_getFolderLastestFile(src,dst):
    list_strFileName = os.listdir(src)
    strFileName = max(list_strFileName, key=lambda x: os.path.getmtime(os.path.join(src, x)))
    src= os.path.join(src, strFileName)
    dst=os.path.join(dst, strFileName)
    filecontrol_copyFileOrFolder_windows(src,dst)
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
        strRetFilePath=tidevice_getFolderLastestFile(src,dst,deviceID,bundleID)
    else:
        strRetFilePath=win_getFolderLastestFile(src,dst)
    return strRetFilePath

def filecontrol_push(src, dst, deviceID=None):
    if deviceID:
        order = "adb -s %s push %s %s" % (deviceID, src, dst)
    else:
        order = "adb push %s %s" % (src, dst)
    print(order)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    # if 'error' in res:
    # raise Exception(res)
    print(res)


def filecontrol_pull(src, dst, deviceID=None):
    if deviceID:
        order = "adb -s %s pull %s %s" % (deviceID, src, dst)
    else:
        order = "adb pull %s %s" % (src, dst)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    # if 'error' in res:
    # raise Exception(res)
    print(res)


def adb_install_apk(strPackagepath, deviceID=None):
    if deviceID:
        cmd = 'adb -s %s install -g "%s"' % (deviceID, strPackagepath)
    else:
        cmd = 'adb install -g "%s"' % (strPackagepath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)


def adb_uninstall_apk(strPackageName, deviceID=None):
    if deviceID:
        cmd = 'adb -s %s uninstall %s' % (deviceID, strPackageName)
    else:
        cmd = 'adb uninstall %s' % (strPackageName)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    print(res)
    print(ret_error)


def adb_file_exist(file_path, deviceID=None):
    file_path = file_path.replace('\\', '/')
    ''''adb shell ls / sdcard / Android / data / com.seasun.xgame.tako / files / version'''
    if deviceID:
        cmd = "adb -s %s shell ls %s" % (deviceID, file_path)
    else:
        cmd = "adb shell ls %s" % (file_path)
    # print(cmd)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    # print(res)
    ret_error = pi.stderr.readline()
    # print(ret_error)
    # ret_code = pi.returncode
    # print('filecontrol_file_exist: %s res= %s ret_code=%d ret_error=%s' % (cmd, res, 1, ret_error))
    # print('[DEBUG] %s [Res] %s' % (cmd, ret_error))
    if 'No such file or directory' in str(ret_error, encoding='gbk'):
        return False
    else:
        return True


def filecontrol_existFileOrFolder(uPath, deviceID=None):
    uPath = uPath.strip()
    if 'sdcard/Android' in uPath:
        return adb_file_exist(uPath, deviceID)
    return os.path.exists(uPath)


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
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    ret_error = pi.stderr.readline()
    # if remove a not exist file with have blew errror info
    #
    if 'No such file or directory' in str(ret_error, encoding='gbk'):
        return False
    else:
        return True


def adb_GetDeviceID():
    cmd = 'adb devices'
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    res = res.decode('utf-8')
    return res.split('\n')[1].split('\t')[0]


def adb_mkdir(strPath, deviceID):
    if deviceID:
        cmd = "adb -s %s shell mkdir %s" % (deviceID, strPath)
    else:
        cmd = "adb shell mkdir %s" % (strPath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    res = pi.stdout.read()
    print(res)


def filecontrol_createFolder(dst, deviceID=None):
    if 'sdcard/Android' in dst:
        # 安卓以files文件夹为base文件夹
        dst = dst.replace('\\', '/')
        strBasePath = dst[:dst.find('files') + 5]
        strMkDir = dst[len(strBasePath) + 1:]
        list_Mkdir = strMkDir.split('/')
        for dir in list_Mkdir:
            strBasePath = strBasePath + '/' + dir
            adb_mkdir(strBasePath, deviceID)
    else:
        os.makedirs(dst)


def copyFileOrFolder_android(src, dst, deviceID=None):
    print(src + ' :   ' + dst)
    # android12以上版本必须先逐级创建路径
    if '.' in src:
        filecontrol_push(src, dst, deviceID)
        return
    adb_mkdir(dst, deviceID)
    for file in os.listdir(src):
        copyFileOrFolder_android(src + '/' + file, dst + '/' + file, deviceID)


def filecontrol_copyFileOrFolder(src, dst, deviceID=None):
    src = src.strip()
    dst = dst.strip()
    # surport mobile
    if 'sdcard/Android' in src:
        src = src.replace('\\', '/')
        return filecontrol_pull(src, dst, deviceID)
    if 'sdcard/Android' in dst:
        dst = dst.replace('\\', '/')
        # android12以上版本必须先逐级创建路径
        strPath = dst[:dst.find(dst.split('/')[-1]) - 1]
        filecontrol_createFolder(strPath, deviceID)
        copyFileOrFolder_android(src, dst, deviceID)
        return True
        # return filecontrol_push(src, dst)
    # UNC Path to mount on linux
    if os.name == 'posix':
        return filecontrol_copyFileOrFolder_linux(src, dst)
    if os.name == 'nt':
        return filecontrol_copyFileOrFolder_windows(src, dst)

def telnet_test(ip, port):
    """是否telnet上对应机器"""
    try:
        connection = telnetlib.Telnet(ip, port, timeout=3)
        connection.close()
        return True
    except:
        return False



def filecontrol_downloadFileByHttp(sUrl: str, sStorePath: str):
    """下载单个文件, sPath-> 服务器文件路径，sStorePath->保存路径(路径携带文件名)"""
    req = urllib3.PoolManager().request("GET", sUrl)
    if req.status == 200:
        bContent = req.data
    else:
        return req.status
    sStorePath = sStorePath.replace('\\', '/')
    dir_temp = sStorePath.rsplit('/', 1)[0]
    if not os.path.exists(dir_temp):
        os.makedirs(dir_temp)
    with open(sStorePath, 'wb') as f:  # 保存文件
        f.write(bContent)
        f.close()
    return req.status

def filecontrol_downloadFromMinioServer(sUrl: str, sStorePath: str):
    """下载单个文件, sPath-> 服务器文件路径，sStorePath->保存路径(路径携带文件名)"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    drive_root = os.path.splitdrive(script_dir)[0] + os.sep
    temp = os.path.join(drive_root, 'temp_zip')
    if not os.path.exists(temp):
        os.makedirs(temp)
    temp_zip = os.path.join(temp, 'temp_zip.zip')
    if os.path.exists(temp_zip):
        filecontrol_deleteFileOrFolder(temp_zip)
    filecontrol_downloadFileByHttp(sUrl, temp_zip)
    extract_to = sStorePath
    with zipfile.ZipFile(temp_zip, 'r') as zip_ref:
        zip_ref.extractall(extract_to)

def filecontrol_get_svn_file_download_url_FromMinioServer(svn_path, svn_version):
    params = {
        'svn_path': svn_path,
        'svn_version': svn_version
    }
    query_string = urllib.parse.urlencode(params)

    base_url = "http://10.11.80.122:5001/test"  # 这里换成你的真实接口地址
    full_url = f'{base_url}?{query_string}'

    # 换成你要请求的地址
    with urllib.request.urlopen(full_url) as resp:
        body = resp.read().decode('utf-8').strip()
        dic_data = json.loads(body)
        return dic_data
        # self.log.info(f'请求bin64返回信息:{body}')
        # if dic_data['result'] == 'wait':
        #     wait_time = int(dic_data['data'])
        #     time.sleep(wait_time)
        # elif dic_data['result'] == 'url':
        #     self.download_url = dic_data['data']
        #     break

def filecontrol_get_svn_file_download_url_FromMinioServer_sync(svn_path, svn_version, wait_time_arg = None, timeout = None):
    time_start = time.time()
    logger = logging.getLogger(str(os.getpid()))
    while 1:
        if timeout and time.time() - time_start > timeout:
            return None
        dic_data = filecontrol_get_svn_file_download_url_FromMinioServer(svn_path, svn_version)
        logger.info(f'请求filecontrol_get_svn_file_download_url_FromMinioServer返回信息:{dic_data}')
        if dic_data['result'] == 'wait':
            if wait_time_arg:
                wait_time = wait_time_arg
            else:
                wait_time = int(dic_data['data'])
            time.sleep(wait_time)
        elif dic_data['result'] == 'url':
            return dic_data['data']


def md5File(filepath):
    md5_hash = hashlib.md5
    with open(filepath, 'rb') as f:
        data = f.read()
        return md5_hash(data).hexdigest()


def getListAllFiles(case_path, filter=None):
    listAllFiles = []
    g = os.walk(case_path)
    for path, dir_list, file_list in g:
        for file_name in file_list:
            file_path = os.path.join(path, file_name)
            if filter and filter in file_path:
                continue
            listAllFiles.append(file_path)
    return listAllFiles


def getListAllFilesAndPath(case_path):
    listAllFiles = []
    g = os.walk(case_path)
    for path, dir_list, file_list in g:
        for file_name in file_list:
            file_path = os.path.join(path, file_name)
            listAllFiles.append(file_path)
        listAllFiles.append(path)
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
            key = fullpath.replace('\\', '/')
            dicCaseFilesMD5[key] = md5File(fullpath)
        else:
            dicCaseFilesMD5_next = getDicCaseFilesMD5(fullpath)
            dicCaseFilesMD5.update(dicCaseFilesMD5_next)
    return dicCaseFilesMD5


# -------------win32---------------------------
def win32_kill_process(process_name):
    while win32_findProcessByName(process_name):
        os.system('TASKKILL /F /t /IM %s' % process_name)


def win32_kill_process_by_cmd(process_name, szCmdLine=None):
    listP = win32_findProcessByName(process_name, szCmdLine=szCmdLine)
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

def win32_get_system_dpi_scaling():
    # 尝试使用ctypes获取缩放设置
    try:
        # 调用GetSystemMetricsForDPI函数
        ctypes.windll.user32.SetProcessDPIAware()
        dpi = ctypes.windll.user32.GetDpiForSystem()
        default_dpi = 96  # Windows默认DPI
        scaling_factor = dpi / default_dpi
        return round(scaling_factor * 100)
    except AttributeError:
        pass  # 如果ctypes调用失败，尝试使用winreg方法
        print('如果ctypes调用失败，尝试使用winreg方法')

    # 使用winreg获取缩放设置
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Control Panel\Desktop', 0, winreg.KEY_READ)
        value, _ = winreg.QueryValueEx(key, 'LogPixels')
        winreg.CloseKey(key)
        # 计算缩放百分比
        scaling_factor = value / 96 * 100  # 96是默认的DPI值
        return scaling_factor
    except FileNotFoundError:
        return 100  # 如果没有找到值，返回默认值100%

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

def win32_get_window_position(title):
    try:
        # 根据窗口标题获取窗口对象
        window = gw.getWindowsWithTitle(title)[0]
        # 获取窗口的左上角坐标
        position = (window.left, window.top)
        return position
    except IndexError:
        # 如果没有找到窗口，返回None
        return None


def win32_get_lock_screen_status():
    u = ctypes.windll.LoadLibrary('user32.dll')
    result = u.GetForegroundWindow()
    return result  # 0表示已锁屏


# ---------------------linux---------------------------
def linux_findProcessByName(name, szCmdLine=None):
    return win32_findProcessByName(name, szCmdLine)


def linux_kill_process_by_pid(pid):
    os.system('kill -9 {}'.format(pid))


# ---------------------public os--------------------
def force_kill_process_family_by_pid(pid):
    pid = str(pid)
    print(pid)
    strOS = platform.system()
    if strOS == "Windows":
        os.system('TASKKILL /F /t /pid {}'.format(pid))
    elif strOS == 'Linux':
        os.system('kill -9 -{}'.format(pid))


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
        f = open(file, 'r+')
        all_lines = f.readlines()
    except:
        f = open(file, 'r+', encoding='gbk')
        all_lines = f.readlines()
    f.seek(0)
    f.truncate()
    for line in all_lines:
        line = line.replace(old_str, new_str)
        f.write(line)
    f.close()


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

        # DisplayVersion:21H2
        # such as: Windows 10 Pro(64bit) 21H2

        try:
            # ProductName: Windows 10 专业版
            subDir = r'SYSTEM\Setup\MoSetup\Volatile'
            os_ProductName = getWinregValue(winreg.HKEY_LOCAL_MACHINE, subDir, 'DownlevelProductName')
        except:
            # ProductName: Windows 10 Pro
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
    elif strOS == "Linux":
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
def svn_get_bvt_version(bvt_project='DX11客户端'):
    # try:
    conn = sql.connect(r"\\10.11.36.142\BranchManagerPlus_Svn1.9\RevisionConfig.db")
    cursor = conn.cursor()
    bvt_date = cursor.execute("SELECT * FROM TodayBVT").fetchall()  # 获取今日BVT的信息
    # bvt_date:
    # [('Vulkan客户端', '2023/8/21 9:3:42', 1232167, 1232167), ('DX11客户端', '2023/8/21 9:49:47', 1232167, 1232167)]
    bvt_date_one = bvt_date[0]
    if bvt_project != bvt_date_one[0]:
        bvt_date_one  = bvt_date[1]
    if bvt_project != bvt_date_one[0]:
        return None
    print(bvt_date_one)
    today_date = list(map(int, date_get_szToday().split('-')))
    today_format = "%d/%d/%d" % (today_date[0], today_date[1], today_date[2])

    today_db = bvt_date_one[1].split()[0]
    if today_db == today_format:
        server = bvt_date_one[2]
        client = bvt_date_one[3]
        print("today_BVT revision: server {}, client {}".format(server, client))
        return (server, client)
    else:
        return None

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


def svn_get_bvt_version_xgame():
    return svn_get_bvt_version(bvt_project='Vulkan客户端')

def svn_get_local_revision(path):
    # try:
    cmd = r'svn info ' + path
    outText = "".join(os.popen(cmd).readlines())
    return int(re.findall(r'Revision: (\d+)', outText)[0])

def svn_get_local_last_changed_revision(path):
    # try:
    cmd = r'svn info ' + path
    outText = "".join(os.popen(cmd).readlines())
    return int(re.findall(r'Last Changed Rev: (\d+)', outText)[0])


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
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    # 文件冲突
    if result != 0:
        ret_error = pi.stderr.readline()  # 为bytes类型
        ret_error = ret_error.decode('gbk')  # 转为str类型,默认windows中文操作系统
        if "warning: W195024" in ret_error:
            svn_cmd_revert(path)
            return
        # raise Exception('svn_cmd_update fail:{}'.format(str(ret_error,encoding='gbk')))
        raise Exception('svn_cmd_update fail:{}'.format(ret_error))
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

def svn_cmd_set_exclude(path):
    cmd = 'svn up  {} --set-depth exclude'.format(path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_set_exclude fail:{}'.format(str(ret_error, encoding='gbk')))
    return result

def svn_cmd_set_empty(path):
    cmd = 'svn up  {} --set-depth empty'.format(path)
    logger = logging.getLogger(str(os.getpid()))
    logger.info(cmd)
    pi = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE)
    pi.wait()

    result = pi.returncode
    if result != 0:
        ret_error = pi.stderr.readline()
        raise Exception('svn_cmd_set_empty fail:{}'.format(str(ret_error, encoding='gbk')))
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
    cmd = 'svn export {} --non-interactive'.format(url)
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
        raise Exception('svn_cmd_export fail:{}'.format(str(ret_error, encoding='gbk')))
    return result


def svn_get_locked_status(path):
    # try:
    conn = sql.connect(os.path.join(path, '.svn', 'wc.db'))
    cursor = conn.cursor()
    date = cursor.execute("SELECT * FROM WC_LOCK").fetchall()[0]
    if date[0] is 1 and date[2] is -1:
        return True


def xgame_get_resource_version(platform,Date=None):
    pt = ['Ios', 'Android', 'PC']
    if platform not in pt:
        raise Exception(f"设备类型错误:{pt},必须为:Ios Android PC")
    url = "http://10.11.39.60/v5/%s/v/"
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

#
# # 金山协作消息订阅系统
# class SubscriberClient:
#     """
#     订阅客户端
#     """
#
#     def __init__(self, server_ip: str, server_port: int):
#         """
#         初始化客户端
#
#         :param server_ip: 服务端运行IP
#         :param server_port: 服务端运行端口
#         """
#         self.ipv4 = server_ip
#         self.port = server_port
#
#     def _msg_content_inspect(self, msg: dict):
#         """
#         检查消息内容格式
#             - 不符合要求时，抛出异常
#         :param msg: 消息内容
#         """
#         if 'msg_type' not in msg or 'content' not in msg:
#             raise Exception("消息格式错误，必须包含msg_type和content字段")
#         pass
#
#     def _send(self, msg: dict):
#         """
#         发送消息到服务端
#
#         :param msg: 字典类型，固定两个字段
#             - msg_type: 消息类型，int类型 or str类型，当为int类型时，则默认自定义使用官网的消息类型，服务端不会对msg内容做任何处理
#             如果是str类型，则服务端会根据规定的类型做不同的处理
#             - content: 消息内容，不同消息类型有不同格式，详情看文档 [https://open-xz.wps.cn/pages/server/msg-and-group/sendmsgV2/#243d2a90]
#         :return:
#         """
#         self._msg_content_inspect(msg)
#         server_address = (self.ipv4, self.port)
#         message = json.dumps(msg).encode('utf-8')
#         client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#
#         def _thread_send():
#             try:
#                 # 连接到服务器
#                 client_socket.connect(server_address)
#
#                 # 发送数据长度
#                 msg_length = len(message)
#                 client_socket.send(struct.pack('i', msg_length))
#
#                 # 发送数据
#                 total_sent = 0
#                 while total_sent < msg_length:
#                     sent = client_socket.send(message[total_sent:])
#                     if sent == 0:
#                         raise RuntimeError("socket connection broken")
#                     total_sent += sent
#
#                 print("Data sent successfully.")
#             except ConnectionRefusedError as e:
#                 if "[WinError 10061]" in str(e):
#                     print("[WinError 10061] 连接被拒绝，服务端可能已被关闭或此客户端已被加入黑名单,请注意发送频率")
#                     exit(-1)
#             finally:
#                 # 关闭连接
#                 client_socket.close()
#
#         thread1 = threading.Thread(target=_thread_send)
#         thread1.start()
#
#     def send_text_and_image(self, text: str, image_path: str):
#         """
#         发送图文混排消息
#
#         :param text: 文字消息
#         :param image_path: 本地图片路径
#         """
#         send_data = {
#             "msg_type": "text_image",
#             "content": {
#                 "text": text
#             }
#         }
#         with open(image_path, 'rb')as f:
#             image_binary = f.read()
#             image_base64 = base64.b64encode(image_binary).decode('utf-8')
#             send_data['content']['image_base64'] = image_base64
#         self._send(send_data)
#
#     def send_text(self, text):
#         """
#         发送纯文本消息
#
#         :param text: 文本消息
#         """
#         send_msg = {
#             "msg_type": 1,
#             "content": {
#                 "type": 1,
#                 "body": text
#             }
#         }
#         self._msg_content_inspect(send_msg)
#         self._send(send_msg)
#         pass
#
#     def send_msg_card(self, card_content):
#         """
#         发送消息卡片
#
#         :param card_content: 卡片内容，详情看文档[https://open-xz.wps.cn/pages/develop-guide/card/structure/]
#             - 消息卡片搭建工具:[https://open-xz.wps.cn/admin/app/AK20230714VGCATY/api-send]
#             - card_content是搭建工具 的json内容
#         """
#         send_msg = {
#             "msg_type": 23,
#             "content": {
#                 "type": 23,
#                 "content": card_content
#             }
#         }
#         self._msg_content_inspect(send_msg)
#         self._send(send_msg)
#         pass
#


# ------------------------
# 参数说明：
# uGuid指机器的guid，可用machine_get_guid()接口获取。
# uGuid可以直接填写ip地址，内部会自动转化为guid，但是需要机器纳入IQB平台管理。
# image为要发的图片地址。
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
            dic = {u'guid': machine_get_guid(), u'msg': msginfo, 'image_base64': image_base64}
            msg = json.dumps(dic)
            msg = bytes(msg, encoding='utf8')
            len_msg = len(msg)
            len_msg = struct.pack('i', len_msg)
            conn.sendall(len_msg)
            conn.sendall(msg)
            # 金山协作订阅系统
            # o = SubscriberClient('10.11.144.176', 12500)
            # if image:
            #     o.send_text_and_image(msginfo, image)
            # else:
            #     o.send_text(msginfo)
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

class Connect(object):
    def __init__(self, serverIP, port, queue_msg):
        self.conn = None
        self.serverIP = serverIP
        self.port = port
        self.queue_msg = queue_msg
        self.bThreadRecv = True
        self.log = logging.getLogger(str(os.getpid()))
        self.threadRecv = None

    def connect(self, no_timeout=False):
        try:
            if self.threadRecv and self.threadRecv.isAlive():
                time.sleep(1)
                return
            obj = socket.socket()
            # obj.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 655360)
            # obj.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 655360)
            bufsize = obj.getsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF)
            self.log.info('socket发送缓冲区的值为：{}'.format(bufsize))
            bufsize = obj.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)
            self.log.info('socket接收缓冲区的值为：{}'.format(bufsize))
            if not no_timeout:
                obj.settimeout(30)
            obj.connect((self.serverIP, self.port))
            self.conn = obj
            # obj.settimeout(30)
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)
            self.log.info(self.serverIP + '|' + str(self.port))
            time.sleep(1)
            return
        # 收包线程
        self.bThreadRecv = True
        self.threadRecv = threading.Thread(target=self.thread_recv, args=())
        self.threadRecv.setDaemon(True)
        self.threadRecv.start()

    def closeConn(self):
        self.bThreadRecv = False
        if self.conn:
            try:
                self.conn.shutdown(socket.SHUT_RDWR)
            except:
                info = traceback.format_exc()
                self.log.warning(info)
            self.conn.close()
            # print(self.conn)
            self.conn = None
            time.sleep(1)

    def thread_recv(self):
        while self.bThreadRecv:
            try:
                data = self.conn.recv(4)
                if not data:
                    self.log.warning('thread_recv head no data')
                    break
                len_msg = struct.unpack('i', data)[0]

                # print '**************'
                # print len_msg
                # print '**************'
                received_size = 0
                received_data = bytearray()
                bDataComplete = True
                while received_size < len_msg:
                    data = self.conn.recv(len_msg - received_size)
                    if not data:
                        self.log.warning('thread_recv no data')
                        bDataComplete = False
                        break
                    received_size += len(data)
                    # recevied_data += data
                    received_data.extend(data)
                if not bDataComplete:
                    self.log.warning('thread_recv data not complete')
                    self.log.warning(str(received_data))
                    self.log.warning('len_msg:{};received_size:{}'.format(len_msg, received_size))
                    break
                # print 'recevied_size:'+str(recevied_size)
                # print 'recevied_data'+str(recevied_data)
                # if len_msg > 10000:
                #     self.log.warning('len_msg:{};received_size:{}'.format(len_msg, received_size))
                #     self.log.warning(str(received_data))

                recevied_data = str(received_data, encoding='utf8')
                self.queue_msg.put(recevied_data)
            except Exception:
                info = traceback.format_exc()
                if '10038' in info:  # 在一个非套接字上尝试了一个操作
                    self.log.warning(info)
                else:
                    self.log.error(info)
                break
        self.log.warning('thread_recv exit')
        self.closeConn()


# ---------AI-------------------

def EasyOCR_remote(img_path):
    # 截图
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

def paddleocrOriginal(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.78:8000/ocr'  # 13号机不太稳定
    server_path = 'http://10.11.181.236:8765/ocr'  # 2号机
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    r = requests.post(server_path, data=img_base64_byte, timeout=60)
    r.raise_for_status()  # 如果返回状态码不是200，则抛出异常
    res = r.json()
    result = res['result']
    return result

def paddleocr(img_path):
    result = paddleocrOriginal(img_path)
    text = ""
    for item in result:
        for i in item:
            text += i[1][0]

    return text

def paddleocr_socket(img_path):
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


# --------------tidevice----------------
def tidevice_list():
    # return such as:
    # [
    #     {
    #         "udid": "00008101-00160CDE116A001E",
    #         "serial": "F19F26BE0DYQ",
    #         "name": "iPhone",
    #         "market_name": "iPhone 12",
    #         "product_version": "16.4.1",
    #         "conn_type": "usb"
    #     }
    # ]
    try:
        listCMD = []
        listCMD.append('tidevice')
        listCMD.append('list')
        listCMD.append('--json')
        p = subprocess.Popen(listCMD, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        bContent = p.stdout.read()
        strContent = str(bContent, encoding='gbk')
        strContent = strContent[:strContent.rfind(']') + 1]
        return json.loads(strContent)
    except:
        info = traceback.format_exc()
        content = str(bContent)
        if 'WinError 2' in info:  # 没有安装tidevice
            return None
        if 'Errno 111' in content:  # ubuntu connection refused, no ios insert usb
            return None
        logger = logging.getLogger(str(os.getpid()))
        logger.error(info)
        logger.error(content)
        return None


def tidevice_get_market_name_by_udid(udid):
    try:
        listDevice = tidevice_list()
        if not listDevice:
            return 'Error when get name'
        for device in listDevice:
            if device['udid'] == udid:
                return device['market_name']
        return 'Error when get name'
    except:
        logger = logging.getLogger(str(os.getpid()))
        info = traceback.format_exc()
        logger.error(info)
        return 'Error when get name'


def tidevice_get_UDID_by_serial(serial):
    try:
        listDevice = tidevice_list()
        if not listDevice:
            return 'Error when get UDID'
        for device in listDevice:
            if device['serial'] == serial:
                return device['udid']
        return 'Error when get UDID'
    except:
        logger = logging.getLogger(str(os.getpid()))
        info = traceback.format_exc()
        logger.error(info)
        return 'Error when get UDID'


# ------------手机截图
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
    print(res)
    pi = subprocess.Popen(order, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    print(res)


def tidevice_screenshot(savepath, deviceID=None):
    if deviceID:
        cmd = 'tidevice -u %s screenshot %s' % (deviceID, savepath)
    else:
        cmd = 'tidevice screenshot %s' % (savepath)
    pi = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    print(res)


def mobile_screemshot(deviceType, savepath, deviceID=None):
    if 'android' in deviceType.lower():
        adb_screenshot(savepath, deviceID)
    else:
        tidevice_screenshot(savepath, deviceID)

class TDRRobot:
    def __init__(self,dbName="XGame_RobotAccount",serverIP="10.11.68.52",GameType="vk"):
        self.dbConfig = {
            "url": f"mongodb://{MONGO_USER}:{MONGO_PASSWORD}@10.11.80.122:27017/",
            "databaseName": dbName,
            "collectionName": "accounts",
            "freeCollection":"freePool",
            "runCollection":"runPool"
        }
        self.apiUrl = "http://10.11.80.233:8110/"
        import pymongo
        # self.apiUrl = "http://10.11.146.73:8110/"
        self.__client = pymongo.MongoClient(self.dbConfig["url"])
        self.szKey = None
        self.serverIP = serverIP
        self.GameType = GameType

    def __getCollection(self,name):
        database = self.__client.get_database(self.dbConfig["databaseName"])
        collection = database.get_collection(name)
        return collection

    def mallocRobot(self,robotNum):
        r = requests.get(self.apiUrl+"mallocRobot", params={"robotNum": robotNum,"serverIP":self.serverIP,"GameType":self.GameType})
        r.raise_for_status()
        data = r.json()["data"]
        if isinstance(data,str):
            raise Exception(data)
        szKey, szName, nStartIndex, nEndIndex = data["szKey"], data["szName"], data["nStartIndex"], data["nEndIndex"]
        self.szKey = szKey
        return szName, nStartIndex, nEndIndex

    def releaseRobot(self):
        r = requests.get(self.apiUrl + "releaseRobot", params={"szKey": self.szKey,"GameType":self.GameType})
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

class Tab:
    def __init__(self, filename, dest_file=None):#文件路径,保存文件得路径
        self.filename = filename
        if not dest_file:
            self.dest_file = filename
        else:
            self.dest_file = dest_file
        self.filehandle = None
        self.initflag = False
        self.column = 0 #列总数
        self.row = 0 #行总数
        self.data = []
        self.__head= {  #这里保存第一行的key和相对应的索引

        }
        self.Init()

    def Init(self): #初始化加载数据
        try:
            if os.path.exists(self.filename):
                self.filehandle = open(self.filename, 'r')
                self.initflag = self._load_file()
            else:
                print("%s tab file is not exist" % self.filename)
        except:
            pass
        else:
            self.initflag = True
        return self.initflag

    def UnInit(self):
        if self.initflag:
            self.filehandle.close()

    def _load_file(self):
        if self.filehandle:
            content = self.filehandle.readlines()
            self.row = len(content)
            head = content[0].rstrip().split('\t')
            self.column = len(head)
            for i in range(len(head)):
                self.__head[head[i]] =i
            for line in content:
                # 这里需要去掉末尾的换行
                line = line.rstrip().split('\t')
                if len(line) < self.column:  #如果行大小跟 列长度不相同,则添加空字符串补齐长度
                    line.extend([''] * (self.column - len(line)))
                self.data.append(line)
            return True
        else:
            return False

    def GetValue(self, row, column):  #row传入行索引(从0开始),column可以传入列的key，或者列的索引(索引从0开始)
        if 0 < row < self.row:
            if type(column) == str:
                if not column in self.__head:
                    return None
                return self.data[row][self.__head[column]]
            elif 0 < column < self.column:
                return self.data[row][column]
            else:
                print("invalid column by",column)
        else:
            print("invalid rowIndex by", row)
        return None

    def SetValue(self, row, column, value): #row传入行索引(从0开始),column可以传入列的key，或者列的索引(索引从0开始)
        if not type(value) == str:
            value = str(value)
        if 0 < row < self.row:
            if type(column) == str:
                if not column in self.__head:
                    print ("%s not in %s head" %(column,self.filename))
                    return False
                self.data[row][self.__head[column]] = value
            elif 0 < column < self.column:
                self.data[row][column] = value
        return True

    def AddValue(self,value,column):
        if not type(value) == str:
            value = str(value)
        if type(column) == str:
            if not column in self.__head:
                print("%s not in %s head" % (column, self.filename))
                return False
            colIndex = self.__head[column]
        elif 0 < column < self.column:
            colIndex = column
        else:
            return False
        for rowIndex,rowData in enumerate(self.data):
            if not rowData[colIndex]:
                self.data[rowIndex][colIndex] = value
                return True
        newRow = [''] * self.column
        newRow[colIndex] = value
        self.data.append(newRow)
        self.row = len(self.data)

    def AddColumn(self,colName):
        if not type(colName) == str:
            print("column name should be str not %s" % type(colName))
            return False
        if colName in self.data[0]:
            print("column %s is existed" % colName)
            return False
        for rowIndex,_ in enumerate(self.data):
            if rowIndex == 0:
                self.data[rowIndex].append(colName)
            else:
                self.data[rowIndex].append("")
        self.column = len(self.data[0])
        self.__head[colName] = self.column-1

    def SaveToFile(self):
        if not os.path.exists(self.dest_file):
            return False
        filewrite = open(self.dest_file, 'w')
        sep_char = '\t'
        for line in self.data:
            filewrite.write(sep_char.join(line) + '\n')
        filewrite.close()
        return True