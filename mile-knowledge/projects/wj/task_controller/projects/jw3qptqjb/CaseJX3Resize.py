# -*- coding: utf-8 -*-
# import sys
# sys.path.append('..')
import time

from CaseXGameCrash import *
from PerfeyeCtrl import *
import  win32gui, win32con

class CaseJX3Resize(CaseXGameCrash):
    def __init__(self):
        super(CaseJX3Resize, self).__init__()

    def check_dic_args(self, dic_args):
        super(CaseJX3Resize, self).check_dic_args(dic_args)
        if 'bLoginPanel' in dic_args:
            self.bWaitLoginPanel=dic_args['bLoginPanel']

    def clearInfoFiles(self):
        super().clearInfoFiles()
        strFileName='resize_start'
        strBasePath = self.CLIENT_PATH + LOCAL_INFO_FILE
        filecontrol_deleteFileOrFolder(os.path.join(strBasePath,strFileName), self.deviceId, self.package)

    def windows_resize_animate(self,run_count=1,step=3):
        #窗口权柄
        handle = win32gui.FindWindow('KGWin32App', None)
        #播放列表 win32con.SW_MAXIMIZE 最大化  win32con.SW_SHOWNORMAL 缩小  win32con.SW_MINIMIZE 最小化
        animate = [win32con.SW_MAXIMIZE,win32con.SW_SHOWNORMAL,win32con.SW_MINIMIZE,win32con.SW_SHOWNORMAL]
        for _ in range(run_count):
            for ani in animate:
                win32gui.ShowWindow(handle, ani)
                time.sleep(step)

    def windows_resize(self,_win_x, _win_y, _win_width, _win_height):
        handle = win32gui.FindWindow('KGWin32App', None)
        if not handle:
            # 还在加载界面
            self.log.info("未到登录场景1")
            time.sleep(10)
            return
        win32gui.MoveWindow(handle, _win_x, _win_y, _win_width, _win_height, 1)

    def windows_resize_in_time(self,timeLimit):
        win_width = 800
        win_height = 450
        flag_width=16
        flag_height=9
        startTime=time.time()
        while True:
            # 控制放大缩小
            win_width += flag_width
            win_height += flag_height
            if win_width >= 1910:
                flag_width=-16
            if win_height >= 1070:
                flag_height=-9
            if win_height<450:
                flag_width=16
            if win_width<800:
                flag_height=9
            self.windows_resize(30, 30, win_width, win_height)

            # 控制时间
            if (time.time()-startTime)>=timeLimit :
                break


    def thread_resize_windows(self, dicSwitch, t_parent):
        self.log.info("thread_resize_windows start")
        nAllResizeTime=30*60 #一共要完成30分钟的缩放时间
        if 'RunTime' in dicSwitch:
            nAllResizeTime=int(dicSwitch['RunTime'])
        nTimerAllResize=0
        list_animate = [win32con.SW_MAXIMIZE,win32con.SW_SHOWNORMAL,win32con.SW_MINIMIZE,win32con.SW_SHOWNORMAL]
        nAnimateCnt=0
        nAnimateSetpTime=3
        nTimerAnimate=0

        nStepTime = 0.1
        nTimerRunMapEnd = 0
        nTimerKeepHeart = 0
        bAnimateFlag=True

        win_width = 800
        win_height = 450
        flag_width = 16
        flag_height = 9
        bCheckResizeFlag=False
        while t_parent.is_alive():
            # 检测app是否启动
            if not self.clientPID:
                time.sleep(10)
                continue
            elif not bCheckResizeFlag:
                if self.bWaitLoginPanel:
                    #登录界面缩放 不需要resize标志
                    nTimerAllResize = time.time()
                    bCheckResizeFlag = True
                    strFilepath = os.path.join(self.CLIENT_PATH + LOCAL_INFO_FILE, 'Perf')
                if self.checkRecvInfoFromSearchpanel('resize_start'):
                    nTimerAllResize=time.time()
                    bCheckResizeFlag=True
                time.sleep(10)
                continue
            elif not bAnimateFlag:
                win_width += flag_width
                win_height += flag_height
                if win_width >= 1910:
                    flag_width = -16
                if win_height >= 1070:
                    flag_height = -9
                if win_height < 450 or win_width<800:
                    flag_width = 16
                    flag_height = 9
                    bAnimateFlag = True
                self.windows_resize(30, 30, win_width, win_height)
            elif time.time()-nTimerAnimate > nAnimateSetpTime:
                # 窗口缩小放大
                nTimerAnimate = time.time()
                handle = win32gui.FindWindow('KGWin32App', None)
                if not handle:
                    # 还在加载界面
                    self.log.info("未到登录场景")
                    time.sleep(10)
                    continue
                win32gui.ShowWindow(handle, list_animate[nAnimateCnt % len(list_animate)])
                nAnimateCnt += 1
                if nAnimateCnt % len(list_animate) == 0:
                    self.log.info('test1')
                    bAnimateFlag = False

            #如果此处使用elif 前面花费时间超过0.2s  后续流程只会进入第一个判断 导致用例结束不了
            if time.time()-nTimerRunMapEnd > 0.2:
                # 0.2秒检查一次是否跑图结束
                nTimerRunMapEnd = time.time()
                if self.bRunMapEnd:
                    self.log.info("thread_resize_windows exit")
                    break
            if time.time()-nTimerAllResize>nAllResizeTime:
                nTimerAllResize=time.time()
                self.bExitGameFlag=True
                self.log.info(f"用例运行{nTimerAllResize}s 后结束")
                break
            if time.time()-nTimerKeepHeart > 120:
                # 120写一条日志
                nTimerKeepHeart = time.time()
                self.log.info('thread_resize_windows heart')
            time.sleep(nStepTime)

    def add_thread_for_searchPanel(self, dicSwitch):
        super().add_thread_for_searchPanel(dicSwitch)
        # 用例超时检查线程
        t = threading.Thread(target=self.thread_resize_windows,
                             args=(dicSwitch, threading.currentThread(),))
        self.listThreads_beforeStartClient.append(t)


if __name__ == '__main__':
    obj = CaseJX3Resize()
    obj.run_from_IQB()