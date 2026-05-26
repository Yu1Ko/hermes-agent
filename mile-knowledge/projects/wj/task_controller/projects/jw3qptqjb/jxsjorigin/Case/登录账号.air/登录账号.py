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
# auto_setup(__file__, devices=["ios:///127.0.0.1:8100/00008030-000E509E016A802E"])

def new_character_class_register(new_character_class=""):
    Tool.ocr_wait("进入江湖", timeout=120)
    # 进入到游戏，这里可以进行账号修改
    if Tool.ocr_exists("登录", timeout=10):
        Tool.ocr_touch("登录", timeout=30)
    sleep(5)
    Tool.ocr_touch("进入江湖", timeout=30)
    Tool.ocr_touch("创建角色", timeout=30)
    sleep(15)
    Tool.touch_ratio(0.5, 0.05) # 暂停任务
    Tool.ocr_touch("GM", timeout=30)
    Tool.ocr_touch("Quick", fuzzy=True, timeout=30)
    Tool.ocr_touch("门派", fuzzy=False, timeout=30)
    for _ in range(3):
        if Tool.ocr_exists(new_character_class, timeout=10):
            Tool.ocr_touch_near(new_character_class, new_character_class, timeout=30)
            break
        else:
            Tool.swipe_ratio((0.5, 0.7), (0.5, 0.3))
        

def main(new_character=False, new_character_class=""):
    try:
        if new_character_class != "":
            new_character_class_register(new_character_class)
        else:
            Tool.ocr_wait("进入江湖", timeout=120)
            # 进入到游戏，这里可以进行账号修改
            if Tool.ocr_exists("登录", timeout=10):
                Tool.ocr_touch("登录", timeout=30)
            sleep(5)
            # 这里可以选择服务器
            # 支付宝小程序可能直接进入了
            if Tool.ocr_exists("进入江湖", timeout=20):
                Tool.ocr_touch("进入江湖", timeout=20)
            if new_character:
                # 如果号里没有角色那就会自动创建角色
                if Tool.ocr_exists("创建角色", timeout=20):
                    Tool.ocr_touch("创建角色", timeout=30)
                sleep(5)
                Tool.touch_ratio(0.5, 0.05) # 暂停任务
            else:
                Tool.ocr_touch("进入游戏", timeout=30)
                if Tool.ocr_exists("挂机奖励", timeout=20):
                    Tool.ocr_touch("点击空白处关闭", dy_ratio=0.03, timeout=30)
    except Exception as e:
        print(f"{e}")
        raise e

if __name__ == "__main__":
    new_character_class_register(new_character_class="天王")
    # Tool.swipe_ratio((0.5, 0.7), (0.5, 0.3))
    # touch(Template(r"设置.png"))
    # Tool.ocr_touch("返回登录", dy_ratio=-0.02, timeout=30)