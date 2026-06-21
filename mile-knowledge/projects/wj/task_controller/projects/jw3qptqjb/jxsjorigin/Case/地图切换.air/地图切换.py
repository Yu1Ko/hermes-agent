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

# 地图切换
# 压测 ja7t94kh4a

# 凤翔府、襄阳城、云中镇、天王、青螺岛、临安城、老九洞、百花谷、塔林

def map_switch(target_name: str):
    # 打开地图
    Tool.ocr_touch("新消息", fuzzy=True, dx_ratio=0.18, timeout=30)
    Tool.ocr_touch("世界", timeout=30)
    # 滑动找地点
    swipe_list = [
        ((0.8, 0.8), (0.2, 0.2)), # 往右下
        ((0.2, 0.8), (0.8, 0.2)), # 往左下
        ((0.2, 0.2), (0.8, 0.8)), # 往左上
        ((0.8, 0.2), (0.2, 0.8)), # 往右上
    ]
    idx = 0
    while not Tool.ocr_exists(target_name, timeout=10):
        # 每次取一个方向滑动
        start_pt, end_pt = swipe_list[idx % len(swipe_list)]
        Tool.swipe_ratio(start_pt, end_pt, duration=0.5)
        sleep(1)
        idx += 1
        if idx >= len(swipe_list)+1:
            raise Exception(f"没有找到目标：{target_name}")
    Tool.ocr_touch(target_name, timeout=30)

def idle(idle_time: int = 2 *60):
    # 挂机
    swipe_list = [
        ((0.15, 0.75), (0.2, 0.75)), # 右
        ((0.15, 0.75), (0.1, 0.75)), # 左
        ((0.15, 0.75), (0.15, 0.65)), # 上
        ((0.15, 0.75), (0.15, 0.85)), # 下
    ]
    start_time = ttime.perf_counter()
    while ttime.perf_counter() - start_time < idle_time:
        start_pt, end_pt = random.choice(swipe_list)
        Tool.swipe_ratio(start_pt, end_pt, duration=0.01)
        sleep(10)

def before_run():
    try:
        Tool.snake_trriger("ja7t94kh4a", 100, 10, 30 * 60, 10)
        sleep(10)
    except Exception as e:
        print(f"{e}")
        raise e
    finally:
        Tool.snake_stop("ja7t94kh4a")
    
def main():
    try:
        target_list = [
            "凤翔府", "襄阳城", "云中镇", "天王", "青螺岛", "临安城", "九老洞", "百花谷", "塔林"
        ]
        for target in target_list:
            map_switch(target)
            sleep(5)
            idle()
    except Exception as e:
        print(f"{e}")
        raise e
    finally:
        Tool.snake_stop("ja7t94kh4a")

if __name__ == "__main__":
    login_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../登录账号.air"))
    using(login_path)
    import 登录账号  # type: ignore
    登录账号.main(new_character=True)
    before_run()
    main()