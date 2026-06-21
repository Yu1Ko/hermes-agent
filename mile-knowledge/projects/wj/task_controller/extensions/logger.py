'''
Author: 涂阳墨 tuyangmo@kingsoft.com
Date: 2023-07-17 16:28:42
LastEditors: 涂阳墨 tuyangmo@kingsoft.com
LastEditTime: 2023-07-17 16:31:28
Description: 

Copyright (c) 2023 by Seasun, All Rights Reserved. 
'''

import os
import time
from loguru import logger

basedir = os.getcwd()

log_path = os.path.join(basedir, 'logs')

if not os.path.exists(log_path):
    os.mkdir(log_path)

t = time.strftime("%Y-%m-%d")
log_file_path = os.path.join(log_path, f"controller-{t}-{os.getpid()}.log")

logger.add(log_file_path, level='INFO',
           format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {module} {line} {message}",
           rotation="00:00", retention="7 days",  encoding="utf-8", enqueue=True, compression="zip")
