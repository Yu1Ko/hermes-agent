'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-11 18:28:30
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2023-07-13 20:19:36
Description: 事件定义

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''
class Event(object):
    def __init__(self, pid, event_id, is_call, func_name, *args, **kwargs):
        self._pid = pid
        self._event_id = event_id
        self._is_call = is_call
        self._func_name = func_name
        self._args = args
        self._kwargs = kwargs

class EventResponse(object):
    def __init__(self, pid, event_id, func_name, code=0, result=None, error=None):
        self._pid = pid
        self._event_id = event_id
        self._func_name = func_name
        self._code = code # 0:成功, 1:失败
        self._result = result
        self._error = error