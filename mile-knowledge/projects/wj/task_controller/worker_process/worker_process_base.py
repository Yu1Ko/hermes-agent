'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-11 19:37:14
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2023-12-04 09:58:56
Description: 

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''
import threading
import time
import aioprocessing
import os
from utils.event_defined import *
from extensions import logger
import platform
strOS = platform.system() #系统

class ProcessLockedException(Exception):
    pass

class WorkerProcessBase(object):
    def __init__(self, uuid, event_queue:aioprocessing.AioQueue, event_queue_lock:aioprocessing.Lock):
    #def __init__(self, uuid, event_queue: aioprocessing.AioQueue):
        self._event_queue = event_queue
        self._event_response_queue = aioprocessing.AioQueue()
        self._event_queue_write_lock = event_queue_lock
        self._event_id = 0  # 递增的事件id
        self._uuid = uuid   # 该进程的uuid
        self._queue_lock = aioprocessing.AioManager().Value('b', False)
        self._response_map = {} # 事件id和事件返回值的映射
        self._response_signal_map = {} # 事件返回值信号映射
        self._response_time_map = {} # 事件返回值时间映射
        
        self._p = None
    
    def start(self):
        self._p = aioprocessing.AioProcess(target=self.run, daemon=True)
        self._p.start()
        self.pid = self._p.pid

    def join(self, timeout = None):
        self._p.join(timeout)

    def is_alive(self):
        return self._p.is_alive()
    
    def terminate(self):
        self._p.terminate()
    
    def kill(self):
        '''由于python3.6没有kill方法, 使用os.kill方法替代'''
        if strOS == 'Linux':
            os.kill(self.pid, 9)
        else:
            os.system('TASKKILL /F /t /pid %s' % self.pid)

    def run(self):
        self.process_init()
        self.process_run()
    
    def process_run(self):
        '''子类需要实现的方法'''
        raise NotImplementedError("子类需要实现process_run方法!")

    def get_uuid(self):
        return self._uuid

    def get_response_queue(self):
        return self._event_response_queue
    
    def lock_event_queue(self):
        '''锁定事件队列, 在销毁进程前调用'''
        self._queue_lock.value = True

    def process_init(self):
        '''进程初始化, 应该在进程启动后立即调用'''
        self._thread_lock = threading.Lock()
        self._response_write_lock = threading.Lock()
        threading.Thread(target=self.recv_response_loop, daemon=True).start()

    def new_event_id(self):
        with self._thread_lock:
            self._event_id += 1
            return self._event_id

    def recv_response_loop(self):
        '''接收事件返回值的循环'''
        while True:
            event_response:EventResponse = self._event_response_queue.get()
            event_id = event_response._event_id
            logger.info(f" recv_response_loop start: {event_id}")
            with self._response_write_lock:
                self._response_map[event_id] = event_response
                self._response_time_map[event_id] = time.time()
                logger.info(f" recv_response_loop write: {event_id}")
                if len(self._response_time_map) > 20:
                    # 清理掉过期事件
                    keys = list(self._response_time_map.keys())
                    for k in keys:
                        if self._response_time_map[k] < time.time() - 60:
                            self._response_map.pop(k, None)
                            self._response_signal_map.pop(k, None)
                            self._response_time_map.pop(k, None)
                            logger.info(f"清理过期事件: {k}")
                self._response_signal_map[event_id].set()
            logger.info(f" recv_response_loop end: {event_id}")

    
    def call_event(self, func_name, *args, **kwargs):
        '''调用事件, 阻塞方法, 会等待事件循环返回'''
        if self._queue_lock.value:
            raise ProcessLockedException('event queue is locked')
        my_event_id = self.new_event_id()
        event_single = threading.Event()
        self._response_signal_map[my_event_id] = event_single
        event:Event = Event(self._uuid, my_event_id, True, func_name, *args, **kwargs)
        with self._event_queue_write_lock:
            self._event_queue.put(event)
        event_single.wait(timeout=300)
        with self._response_write_lock:
            #strInfo = f"func_name异常 {my_event_id}:signal_map-{self._response_signal_map.get(my_event_id)} time_map-{self._response_time_map.get(my_event_id)}"
            #logger.warning(strInfo)
            my_response: EventResponse = self._response_map.pop(my_event_id)
            self._response_signal_map.pop(my_event_id)
            self._response_time_map.pop(my_event_id)

        if my_response._code != 0:
            raise Exception(my_response._error)
        return my_response._result
        
    def send_event(self, func_name, *args, **kwargs):
        '''发送事件, 非阻塞方法, 不会等待事件循环返回'''
        my_event_id = self.new_event_id()
        event:Event = Event(self._uuid, my_event_id, False, func_name, *args, **kwargs)
        with self._event_queue_write_lock:
            self._event_queue.put(event)