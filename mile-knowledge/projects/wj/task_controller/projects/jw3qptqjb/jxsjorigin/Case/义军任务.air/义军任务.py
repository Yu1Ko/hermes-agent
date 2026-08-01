# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
import os
import sys
import time

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import Tool

auto_setup(__file__)

def main():
    try:
        # TODO GM加钱
        if Tool.ocr_exists("义军任务", timeout=20):
            Tool.ocr_touch("义军任务", timeout=30)
        else:
            raise Exception("该号义军任务已完成或ocr识别失败")
        # 挂机等完成
        while Tool.ocr_exists("义军任务", timeout=20):
            pass
    except Exception as e:
        print(f"{e}")
        raise e
            

if __name__ == "__main__":
    # 引入登录脚本
    login_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../登录账号.air"))
    using(login_path)
    import 登录账号  # type: ignore
    登录账号.main()
    main()






























