#!/usr/bin/env python
# -*- coding: utf-8 -*-

""""Airtest图像识别专用."""

import os
import sys
import time
import types
import re
from six import PY3
from copy import deepcopy
import platform
from airtest import aircv
from airtest.aircv import cv2
#from airtest.core.helper import G, logwrap
from airtest.core.settings import Settings as ST  # noqa
from airtest.core.error import TargetNotFoundError, InvalidMatchingMethodError
from airtest.utils.transform import TargetPos
import subprocess
from airtest.aircv.template_matching import TemplateMatching
from airtest.aircv.keypoint_matching import KAZEMatching, BRISKMatching, AKAZEMatching, ORBMatching
from airtest.aircv.keypoint_matching_contrib import SIFTMatching, SURFMatching, BRIEFMatching
import numpy


MATCHING_METHODS = {
    "tpl": TemplateMatching,
    "kaze": KAZEMatching,
    "brisk": BRISKMatching,
    "akaze": AKAZEMatching,
    "orb": ORBMatching,
    "sift": SIFTMatching,
    "surf": SURFMatching,
    "brief": BRIEFMatching,
}


#@logwrap
def loop_find(query, timeout=ST.FIND_TIMEOUT, threshold=None, interval=0.5, intervalfunc=None,device_s = None):
    """
    Search for image template in the screen until timeout

    Args:
        query: image template to be found in screenshot
        timeout: time interval how long to look for the image template
        threshold: default is None
        interval: sleep interval before next attempt to find the image template
        intervalfunc: function that is executed after unsuccessful attempt to find the image template

    Raises:
        TargetNotFoundError: when image template is not found in screenshot

    Returns:
        TargetNotFoundError if image template not found, otherwise returns the position where the image template has
        been found in screenshot

    """
    #G.LOGGING.info("Try finding:\n%s", query)
    print('[INFO] Try finding:\n%s', query)
    start_time = time.time()
    while True:
        #截图，screen为cv图像对象 安卓使用adb的截图命令
        #screen = G.DEVICE.snapshot(filename=None, quality=ST.SNAPSHOT_QUALITY)
        if device_s == None:
            os.popen('adb shell screencap -p /sdcard/screen.png').read()
            os.popen(f'adb pull /sdcard/screen.png {os.getcwd()}').read()
        else:
            os.popen(f'adb -s {device_s} shell screencap -p /sdcard/screen.png').read()
            os.popen(f'adb -s {device_s} pull /sdcard/screen.png {os.getcwd()}').read()
        screen = aircv.imread("screen.png")
        
        if screen is None:
            #G.LOGGING.warning("Screen is None, may be locked")
            print("[ERROR] Screen is None, may be locked")
        else:
            #设置阀，默认为0.7
            if threshold:
                query.threshold = threshold
            #使用template的math_in方法先匹配到图像，再获取位置，默认是中心点
            match_pos = query.match_in(screen)
            if match_pos:
                #try_log_screen(screen)
                return match_pos
        #当屏幕截图为空时
        if intervalfunc is not None:
            intervalfunc()

        # 超时则raise，未超时则进行下次循环:
        if (time.time() - start_time) > timeout:
            #try_log_screen(screen)
            raise TargetNotFoundError('Picture %s not found in screen' % query)
        else:
            time.sleep(interval)

#获取设备方向 0：竖屏，1：横屏（顺时针90度为正常竖屏） 2：翻转竖屏  3：横屏（逆时针90度为正常竖屏）
def GetDevicesOrientation(device_s):
    SurfaceFlingerRE = re.compile('orientation=(\d+)')
    proc = subprocess.Popen(
            f'adb -s {device_s} shell dumpsys SurfaceFlinger',
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,)
    output, stderr = proc.communicate()
    #output = os.popen(f'adb -s {device_s} shell dumpsys SurfaceFlinger').read()
    
    m = SurfaceFlingerRE.search(output.decode())
    if m:
        return int(m.group(1))

    surfaceOrientationRE = re.compile('SurfaceOrientation:\s+(\d+)')

    proc = subprocess.Popen(
            f'adb -s {device_s} shell dumpsys input',
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,)
    output, stderr = proc.communicate()
    #output = os.popen(f'adb -s {device_s} shell dumpsys SurfaceFlinger').read()
    #output = os.popen(f'adb -s {device_s} shell dumpsys input').read()
    m = surfaceOrientationRE.search(output.decode())
    if m:
        return int(m.group(1))
    return 1


def focus_window(window_class:str = None,window_name:str = None):
    try:
        hWnd = win32gui.FindWindow(window_class,window_name) #窗口的类名可以用Visual Studio的SPY++工具获取
        win32gui.SetForegroundWindow(hWnd)
    except:
        print("[ERROR] Focus On Failure")

def screencap_window(window_class:str = None,window_name:str = None):
    import win32gui, win32ui, win32con,win32api
    have_window = False
    signedIntsArray = None
    if window_class != None or window_name != None:
        hWnd = win32gui.FindWindow(window_class,window_name) #窗口的类名可以用Visual Studio的SPY++工具获取
        if hWnd != None:
            have_window = True
            #获取句柄窗口的大小信息
            left, top, right, bot = win32gui.GetWindowRect(hWnd)
            width = right - left
            height = bot - top
            #返回句柄窗口的设备环境，覆盖整个窗口，包括非客户区，标题栏，菜单，边框
            hWndDC = win32gui.GetWindowDC(hWnd)
            #创建设备描述表
            mfcDC = win32ui.CreateDCFromHandle(hWndDC)
            #创建内存设备描述表
            saveDC = mfcDC.CreateCompatibleDC()
            #创建位图对象准备保存图片
            saveBitMap = win32ui.CreateBitmap()
            #为bitmap开辟存储空间
            saveBitMap.CreateCompatibleBitmap(mfcDC,width,height)
            #将截图保存到saveBitMap中
            saveDC.SelectObject(saveBitMap)
            #保存bitmap到内存设备描述表
            saveDC.BitBlt((0,0), (width,height), mfcDC, (0, 0), win32con.SRCCOPY)
            signedIntsArray = saveBitMap.GetBitmapBits(True)
            win32gui.DeleteObject(saveBitMap.GetHandle())
            saveDC.DeleteDC()
            mfcDC.DeleteDC()
            win32gui.ReleaseDC(hWnd,hWndDC)

    if have_window == False: 
        hdesktop = win32gui.GetDesktopWindow()
        # 分辨率适应
        width = win32api.GetSystemMetrics(win32con.SM_CXVIRTUALSCREEN)
        height = win32api.GetSystemMetrics(win32con.SM_CYVIRTUALSCREEN)
        left = win32api.GetSystemMetrics(win32con.SM_XVIRTUALSCREEN)
        top = win32api.GetSystemMetrics(win32con.SM_YVIRTUALSCREEN)
        right = width + left
        bot = height + top
        # 创建设备描述表
        desktop_dc = win32gui.GetWindowDC(hdesktop)
        img_dc = win32ui.CreateDCFromHandle(desktop_dc)
        # 创建一个内存设备描述表
        mem_dc = img_dc.CreateCompatibleDC()
        # 创建位图对象
        saveBitMap = win32ui.CreateBitmap()
        saveBitMap.CreateCompatibleBitmap(img_dc, width, height)
        mem_dc.SelectObject(saveBitMap)
        # 截图至内存设备描述表
        mem_dc.BitBlt((0, 0), (width, height), img_dc, (0, 0), win32con.SRCCOPY)
        # 将截图保存到文件中
        # saveBitMap.SaveBitmapFile(mem_dc, 'saveBitMap.bmp')
        signedIntsArray = saveBitMap.GetBitmapBits(True)
        win32gui.DeleteObject(saveBitMap.GetHandle())
        img_dc.DeleteDC()
        mem_dc.DeleteDC()

    im_opencv = numpy.frombuffer(signedIntsArray, dtype = 'uint8')
    im_opencv.shape = (height, width, 4)
    cv2.cvtColor(im_opencv, cv2.COLOR_BGRA2RGB)
    return im_opencv,(left,top,right,bot,width,height)
    

def loop_find_image(source_query,aim_query,timeout=ST.FIND_TIMEOUT, threshold=None, interval=0.5):
    start_time = time.time()
    while True:
        if threshold:
            aim_query.threshold = threshold
        match_pos = aim_query.match_in(source_query._imread())
        if match_pos:
            #try_log_screen(screen)
            #print(f"find match pos: {match_pos}")
            return match_pos
        # 超时则raise，未超时则进行下次循环:
        if (time.time() - start_time) > timeout:
            #try_log_screen(screen)
            raise TargetNotFoundError('Picture %s not found in screen' % aim_query)
            #raise Exception("picture not found in screen")
        else:
            time.sleep(interval)

def loop_find_in_image_for_window(source_query,aim_query,window_class = None,window_name = None,timeout=ST.FIND_TIMEOUT, threshold=None, interval=0.5):
    start_time = time.time()
    match_pos_in_image = loop_find_image(source_query,aim_query,timeout,threshold,interval)
    source_query.target_pos = TargetPos.LEFTUP
    match_pos_in_window = loop_find_window(source_query,window_class,window_name,timeout,threshold,interval)
    if match_pos_in_image and match_pos_in_window:
        #try_log_screen(screen)
        #print(f"find match pos: {match_pos}")
        match_pos = (match_pos_in_image[0] + match_pos_in_window[0][0],match_pos_in_image[1] + match_pos_in_window[0][1])
        print(f"find match pos: {match_pos}")
        return match_pos
    else:
        raise "[EROOR] Source Image Not Found or Aim Image Not Found"

def loop_find_window(query,window_class = None,window_name = None,timeout=ST.FIND_TIMEOUT, threshold=None, interval=0.5):
    start_time = time.time()
    while True:
        screen,win_attribute = screencap_window(window_class,window_name)
        if screen is None:
            #G.LOGGING.warning("Screen is None, may be locked")
            print('[ERROR]screen is none')
        else:
            #设置阀，默认为0.7
            if threshold:
                query.threshold = threshold
            #使用template的math_in方法先匹配到图像，再获取位置，默认是中心点
            match_pos = query.match_in(screen)
            if match_pos:
                #try_log_screen(screen)
                #print(f"find match pos: {match_pos}")
                return match_pos,win_attribute
        # 超时则raise，未超时则进行下次循环:
        if (time.time() - start_time) > timeout:
            #try_log_screen(screen)
            raise TargetNotFoundError('Picture %s not found in screen' % query)
            #raise Exception("picture not found in screen")
        else:
            time.sleep(interval)


def loop_find_android(query, timeout=ST.FIND_TIMEOUT, threshold=None, interval=0.5,device_s = None):
    """
    Search for image template in the screen until timeout

    Args:
        query: image template to be found in screenshot
        timeout: time interval how long to look for the image template
        threshold: default is None
        interval: sleep interval before next attempt to find the image template
        intervalfunc: function that is executed after unsuccessful attempt to find the image template

    Raises:
        TargetNotFoundError: when image template is not found in screenshot

    Returns:
        TargetNotFoundError if image template not found, otherwise returns the position where the image template has
        been found in screenshot

    """
    #G.LOGGING.info("Try finding:\n%s", query)
    start_time = time.time()
    while True:
        #截图，screen为cv图像对象 安卓使用adb的截图命令，截图后不要保存成为screen，可以保存为screen+设备号的形式，也可以不进行保存
        #screen = G.DEVICE.snapshot(filename=None, quality=ST.SNAPSHOT_QUALITY)
        #os.popen('adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:3').read()
        string_img = ""
        proc = None
        cmd = ""
        if device_s == None:
            #os.popen('adb shell screencap -p /sdcard/screen.png').read()
            #os.popen(f'adb pull /sdcard/screen.png {os.getcwd()}').read()
            cmd = f'adb shell /system/bin/screencap -p'
        else:
            #os.popen(f'adb -s {device_s} shell screencap -p /sdcard/screen.png').read()
            #os.popen(f'adb -s {device_s} pull /sdcard/screen.png {os.getcwd()}').read()
            cmd = f'adb -s {device_s} shell /system/bin/screencap -p'
        proc = subprocess.Popen(
            cmd,
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,)
        string_img, stderr = proc.communicate()
        # string_img = os.popen(cmd).read()
        if 'Linux' in platform.system():
            pass
        else:
            string_img = string_img.replace(b"\r\n",b"\n")  # 二进制流中的"\r\n" 替换为"\n"    
        if string_img == None or string_img == "":
            raise Exception("screencap error")
        
        screen = aircv.utils.string_2_img(string_img)
       
        #screen = aircv.imread("screen.png")
        # screen = aircv.rotate(screen,90, clockwise=False)
        # aircv.imwrite("screen.png",screen,10)
        h,w= screen.shape[:2]
        rotation = GetDevicesOrientation(device_s)
       
        #高度大于宽度，如何区分是要旋转还是拉伸呢？取决于SDK版本?还是安卓版本？
        #据最新测试得知，mix2 mi9无论方向如何，截屏的方向都是正确的，不会翻转和偏离
        #但redmi note7pro 会将高度拉伸，宽度压缩，不知道为什么出现这种情况
        #红米3 adb截屏仅仅会将图片翻转，而翻转的方向是与手机的翻转方向一致
        if h > w:
            model = os.popen(f'adb -s {device_s} shell getprop ro.product.model').read()
            if 'Redmi Note 7 Pro' in model or 'MI CC 9' in model:
                #高度压缩，宽度拉伸 
                screen = cv2.resize(screen,(h,w),interpolation = cv2.INTER_AREA)
                #cv2.imwrite('screen.png',screen)
            else:
                #翻转，不知道是90度还是270度，取决于手机的方向
                screen = aircv.rotate(screen,90 * rotation, clockwise=False)
                # aircv.imwrite("screen.png",screen,10)
            
        if screen is None:
            #G.LOGGING.warning("Screen is None, may be locked")
            print('[ERROR]screen is none,may be locked')
        else:
            #设置阀，默认为0.7
            if threshold:
                query.threshold = threshold
            #使用template的math_in方法先匹配到图像，再获取位置，默认是中心点
            match_pos = query.match_in_android(screen)
            if match_pos:
                #try_log_screen(screen)
                #print(f"find match pos: {match_pos}")
                return match_pos,rotation

        # 超时则raise，未超时则进行下次循环:
        if (time.time() - start_time) > timeout:
            #try_log_screen(screen)
            raise TargetNotFoundError('Picture %s not found in screen' % query)
            #raise Exception("picture not found in screen")
        else:
            time.sleep(interval)


#@logwrap
# def try_log_screen(screen=None):
#     """
#     Save screenshot to file

#     Args:
#         screen: screenshot to be saved

#     Returns:
#         None

#     """
#     if not ST.LOG_DIR:
#         return
#     if screen is None:
#         screen = G.DEVICE.snapshot(quality=ST.SNAPSHOT_QUALITY)
#     filename = "%(time)d.jpg" % {'time': time.time() * 1000}
#     filepath = os.path.join(ST.LOG_DIR, filename)
#     aircv.imwrite(filepath, screen, ST.SNAPSHOT_QUALITY)
#     return {"screen": filename, "resolution": aircv.get_resolution(screen)}


class Template(object):
    """
    picture as touch/swipe/wait/exists target and extra info for cv match
    filename: pic filename
    target_pos: ret which pos in the pic
    record_pos: pos in screen when recording
    resolution: screen resolution when recording
    rgb: 识别结果是否使用rgb三通道进行校验.
    """

    def __init__(self, filename, threshold=None, target_pos=TargetPos.MID, record_pos=None, resolution=(), rgb=False):
        self.filename = filename
        self._filepath = None
        self.threshold = threshold or ST.THRESHOLD
        self.target_pos = target_pos
        self.record_pos = record_pos
        self.resolution = resolution
        self.rgb = rgb
        self.match_result = None

    @property
    def filepath(self):
        '''
        文件路径
        '''
        if self._filepath:
            return self._filepath
        # for dirname in G.BASEDIR:
        #     filepath = os.path.join(dirname, self.filename)
        #     if os.path.isfile(filepath):
        #         self._filepath = filepath
        #         return self._filepath
        return self.filename

    def __repr__(self):
        filepath = self.filepath if PY3 else self.filepath.encode(sys.getfilesystemencoding())
        return "Template(%s)" % filepath

    def match_in(self, screen):
        #进入cv匹配
        match_result = self._cv_match(screen)
        #print("match result: %s", match_result)
        print('[INFO] match result: %s',match_result)
        if not match_result:
            return None
        #根据返回的结果获取目标点
        self.match_result = match_result
        focus_pos = TargetPos().getXY(match_result, self.target_pos)
        return focus_pos
    
    def match_in_android(self,screen):
        #进入cv匹配
        match_result = self._cv_match(screen)
        #print("match result: %s", match_result)
        if not match_result:
            return None
        #根据返回的结果获取目标点
        self.match_result = match_result
        focus_pos = TargetPos().getXY(match_result, self.target_pos)
        return focus_pos

    def match_all_in(self, screen):
        image = self._imread()
        image = self._resize_image(image, screen, ST.RESIZE_METHOD)
        return self._find_all_template(image, screen)

    #@logwrap
    def _cv_match(self, screen):
        # in case image file not exist in current directory:
        #将目标图像转换为cv2图片处理格式
        image = self._imread()
        #分辨率不同的情况下需要适配
        image = self._resize_image(image, screen, ST.RESIZE_METHOD)
        ret = None
        for method in ST.CVSTRATEGY:
            # get function definition and execute:
            func = MATCHING_METHODS.get(method, None)
            if func is None:
                raise InvalidMatchingMethodError("Undefined method in CVSTRATEGY: '%s', try 'kaze'/'brisk'/'akaze'/'orb'/'surf'/'sift'/'brief' instead." % method)
            else:
                #实际上是执行了SURFMatching，TemplateMatching，BRISKMatching类的find_best_result方法
                ret = self._try_match(func, image, screen, threshold=self.threshold, rgb=self.rgb)
            if ret:
                break
        return ret


    @staticmethod
    def _try_match(func, *args, **kwargs):
        print("[INFO] try match with %s" % func.__name__)
        try:
            ret = func(*args, **kwargs).find_best_result()
        except aircv.NoModuleError as err:
            print("[ERROR] 'surf'/'sift'/'brief' is in opencv-contrib module. You can use 'tpl'/'kaze'/'brisk'/'akaze'/'orb' in CVSTRATEGY, or reinstall opencv with the contrib module.")
            return None
        except aircv.BaseError as err:
            print("[ERROR] ",repr(err))
            return None
        else:
            return ret

    def _imread(self):
        return aircv.imread(self.filepath)

    def _find_all_template(self, image, screen):
        return TemplateMatching(image, screen, threshold=self.threshold, rgb=self.rgb).find_all_results()

    def _find_keypoint_result_in_predict_area(self, func, image, screen):
        if not self.record_pos:
            return None
        # calc predict area in screen
        image_wh, screen_resolution = aircv.get_resolution(image), aircv.get_resolution(screen)
        xmin, ymin, xmax, ymax = Predictor.get_predict_area(self.record_pos, image_wh, self.resolution, screen_resolution)
        # crop predict image from screen
        predict_area = aircv.crop_image(screen, (xmin, ymin, xmax, ymax))
        if not predict_area.any():
            return None
        # keypoint matching in predicted area:
        ret_in_area = func(image, predict_area, threshold=self.threshold, rgb=self.rgb)
        # calc cv ret if found
        if not ret_in_area:
            return None
        ret = deepcopy(ret_in_area)
        if "rectangle" in ret:
            for idx, item in enumerate(ret["rectangle"]):
                ret["rectangle"][idx] = (item[0] + xmin, item[1] + ymin)
        ret["result"] = (ret_in_area["result"][0] + xmin, ret_in_area["result"][1] + ymin)
        return ret

    def _resize_image(self, image, screen, resize_method):
        """模板匹配中，将输入的截图适配成 等待模板匹配的截图."""
        # 未记录录制分辨率，跳过
        if not self.resolution:
            return image
        screen_resolution = aircv.get_resolution(screen)
        # 如果分辨率一致，则不需要进行im_search的适配:
        if tuple(self.resolution) == tuple(screen_resolution) or resize_method is None:
            return image
        if isinstance(resize_method, types.MethodType):
            resize_method = resize_method.__func__
        # 分辨率不一致则进行适配，默认使用cocos_min_strategy:
        h, w = image.shape[:2]
        w_re, h_re = resize_method(w, h, self.resolution, screen_resolution)
        # 确保w_re和h_re > 0, 至少有1个像素:
        w_re, h_re = max(1, w_re), max(1, h_re)
        # 调试代码: 输出调试信息.
        print("[INFO] resize: (%s, %s)->(%s, %s), resolution: %s=>%s" % (
                        w, h, w_re, h_re, self.resolution, screen_resolution))
        # 进行图片缩放:
        image = cv2.resize(image, (w_re, h_re))
        return image


class Predictor(object):
    """
    this class predicts the press_point and the area to search im_search.
    """

    DEVIATION = 100

    @staticmethod
    def count_record_pos(pos, resolution):
        """计算坐标对应的中点偏移值相对于分辨率的百分比."""
        _w, _h = resolution
        # 都按宽度缩放，针对G18的实验结论
        delta_x = (pos[0] - _w * 0.5) / _w
        delta_y = (pos[1] - _h * 0.5) / _w
        delta_x = round(delta_x, 3)
        delta_y = round(delta_y, 3)
        return delta_x, delta_y

    @classmethod
    def get_predict_point(cls, record_pos, screen_resolution):
        """预测缩放后的点击位置点."""
        delta_x, delta_y = record_pos
        _w, _h = screen_resolution
        target_x = delta_x * _w + _w * 0.5
        target_y = delta_y * _w + _h * 0.5
        return target_x, target_y

    @classmethod
    def get_predict_area(cls, record_pos, image_wh, image_resolution=(), screen_resolution=()):
        """Get predicted area in screen."""
        x, y = cls.get_predict_point(record_pos, screen_resolution)
        # The prediction area should depend on the image size:
        if image_resolution:
            predict_x_radius = int(image_wh[0] * screen_resolution[0] / (2 * image_resolution[0])) + cls.DEVIATION
            predict_y_radius = int(image_wh[1] * screen_resolution[1] / (2 * image_resolution[1])) + cls.DEVIATION
        else:
            predict_x_radius, predict_y_radius = int(image_wh[0] / 2) + cls.DEVIATION, int(image_wh[1] / 2) + cls.DEVIATION
        area = (x - predict_x_radius, y - predict_y_radius, x + predict_x_radius, y + predict_y_radius)
        return area
