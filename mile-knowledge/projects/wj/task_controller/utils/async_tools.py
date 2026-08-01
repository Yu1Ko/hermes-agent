'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-24 16:34:11
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2023-07-24 17:06:32
Description: 

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''
import asyncio
import contextvars
import functools

async def to_thread(func, *args, **kwargs):
    loop = asyncio.get_event_loop()
    ctx = contextvars.copy_context()
    func_call = functools.partial(ctx.run, func, *args, **kwargs)
    return await loop.run_in_executor(None, func_call)