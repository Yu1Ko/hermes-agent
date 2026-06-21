# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
import os
import sys
import time
import random
import time as ttime

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import Tool

# auto_setup(__file__, devices=["Android://127.0.0.1:5037/e2f2a346"])
auto_setup(__file__)

# 压测 3eqgjced9f

def before_run():
    try:
        Tool.snake_trriger("3eqgjced9f", 100, 10, 30 * 60, 10)
        sleep(10)
        # GM进入宋金
        Tool.ocr_touch("GM", timeout=30)
        Tool.ocr_touch("All", fuzzy=True, timeout=30)
        Tool.ocr_swipe("主角", vector=[0, -0.75], timeout=30)
        Tool.ocr_touch_near("楼兰", "宋金", "up", timeout=30)
        Tool.ocr_touch_multiline("开启本服宋金", "报名", "执行", timeout=30)
        Tool.ocr_touch_near("本服宋金报名", "执行", timeout=30)
        Tool.ocr_touch_multiline("开启本服宋金", "战场", "执行", timeout=30)
        Tool.ocr_touch("GM", timeout=30)
    except Exception as e:
        print(f"{e}")
        raise e
    finally:
        Tool.snake_stop("3eqgjced9f")
    
def main():
    try:
        # 进入宋金战场
        Tool.ocr_touch("背包", fuzzy=False, dy_ratio=-0.25, timeout=30)
        touch(Template(r"宋金地图.png"))
        sleep(3)
        Tool.touch_ratio(0.05, 0.5)
        
        while Tool.ocr_exists("对战", interval=2, timeout=10):
            pass

        # 重置进入次数
        Tool.ocr_touch("GM", timeout=30)
        Tool.ocr_touch("All", fuzzy=True, timeout=30)
        Tool.ocr_swipe("主角", vector=[0, -0.75], timeout=30)
        Tool.ocr_touch_near("楼兰", "宋金", "up", timeout=30)
        Tool.ocr_swipe("取消人数检查", vector=[0, -0.75], timeout=30)
        Tool.ocr_touch_near("重置今日参与", "执行", "right", timeout=30)
        Tool.ocr_touch("GM", timeout=30)

        try:
            touch(Template(r"UI_取消.png")) # 有可能获得榜首
        except:
            pass
    except Exception as e:
        print(f"{e}")
        raise e
    finally:
        Tool.snake_stop("3eqgjced9f")

if __name__ == "__main__":
    login_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../登录账号.air"))
    using(login_path)
    import 登录账号  # type: ignore
    登录账号.main(new_character=True)
    before_run()
    main()