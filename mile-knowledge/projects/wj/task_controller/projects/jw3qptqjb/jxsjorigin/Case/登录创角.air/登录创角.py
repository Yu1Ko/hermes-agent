# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
import os
import sys
import time

# 将项目根目录添加到 sys.path 以便导入 utils
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import utils

auto_setup(__file__)

# 登陆创角

def main():
    try:
        utils.ocr_wait("进入江湖", timeout=120)
        # 进入到游戏，这里可以进行账号修改
        utils.ocr_touch("登录", timeout=30)
        sleep(5)
        # 这里可以选择服务器
        utils.ocr_touch("进入江湖", timeout=30)
        utils.ocr_touch("创建角色", timeout=30)
        sleep(3)
        # 点一下姓名输入框，用识别太慢，会直接创角
        utils.touch_ratio(0.5, 0.88)
        sleep(1)
        # 取消输入法
        utils.touch_ratio(0.5, 0.05)
        utils.ocr_touch("男", timeout=30)
        utils.ocr_touch("女", timeout=30)
    except Exception as e:
        print(f"{e}")
        raise e

if __name__ == "__main__":
    main()
    # utils.touch_ratio(0.5, 0.05)