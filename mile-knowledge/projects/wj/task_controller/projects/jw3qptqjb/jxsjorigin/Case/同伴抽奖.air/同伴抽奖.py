# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
import os
import sys
import time

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import Tool

auto_setup(__file__)
# auto_setup(__file__, devices=["Android://127.0.0.1:5037/e2f2a346"])

def main():
    try:
        # GM加钱
        Tool.ocr_touch("GM", timeout=30)
        Tool.ocr_touch("Quick", fuzzy=True, timeout=30)
        pt = Tool.ocr_touch_near("元宝", "Add", timeout=20)
        for _ in range(5):
            touch(pt)
            time.sleep(0.5)
        pt = Tool.ocr_touch_near("银两", "Add", timeout=20)
        for _ in range(50):
            touch(pt)
            time.sleep(0.5)
        Tool.ocr_touch("GM", timeout=30)

        # 进入同伴招募
        Tool.ocr_touch("同伴", fuzzy=False, timeout=30)
        if Tool.ocr_exists("招募", timeout=20):
            Tool.ocr_touch("招募", fuzzy=False, timeout=30)

        # 元宝招募
        Tool.ocr_touch("元宝", fuzzy=False, timeout=30)
        for _ in range(10):
            Tool.ocr_touch("招募十次", fuzzy=False, timeout=30)
            if Tool.ocr_exists("确定", timeout=10):
                Tool.ocr_touch("确定", fuzzy=False, timeout=30)
            sleep(10)
            Tool.touch_ratio(0.05, 0.5)

        # 银两招募
        Tool.ocr_touch("银两", fuzzy=False, timeout=30)
        for _ in range(10):
            Tool.ocr_touch("招募十次", fuzzy=False, timeout=30)
            sleep(10)
            Tool.touch_ratio(0.05, 0.5)
        touch(Template(r"UI_取消.png"))
        sleep(3)
        try:
            touch(Template(r"UI_取消.png"))
        except:
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






























