# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
import os
import sys
import time

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import Tool

auto_setup(__file__)

boss_list = [
    "柔小翠",
    "张善德",
    "贾逸山",
    "乌山青",
    "陈无命",
    "神枪方晚",
    "赵应仙",
    "香玉仙",
    "蛮僧不戒和尚",
    "南郭儒"
]

def extract_top_region_from_ocr(centers, texts, left_mark="对", right_mark="的"):
    """
    从 ocr_find_all 返回的 centers/texts 中：
    1) 从最下面（y 最大）开始往上检查 text
    2) 若该 text 不包含“对”和“的”（无法解析），则继续检查下一条
    3) 截取成功时返回：最后一个“对”到其后第一个“的”之间的内容
    例：'[系统]邝春芷对塔林的拓跋山渊造成了第一击！' -> '塔林'
    返回：区域字符串或 None
    """
    if not centers or not texts:
        return None
    n = min(len(centers), len(texts))
    if n <= 0:
        return None

    items = []
    for i in range(n):
        try:
            y = float(centers[i][1])
        except Exception:
            continue
        items.append((y, i))

    # 从最下面（y 最大）开始
    items.sort(key=lambda x: x[0], reverse=True)

    for _, i in items:
        s = str(texts[i] or "")
        li = s.rfind(left_mark)
        if li < 0:
            continue
        ri = s.find(right_mark, li + len(left_mark))
        if ri < 0:
            continue
        region = s[li + len(left_mark):ri].strip()
        if region:
            return region
    return None

def before_run():
    Tool.snake_trriger("5teyfdjvnd", 100, 10, 30 * 60, 10)
    # 等机器人准备好
    sleep(60)

def main(testplus=None, serial=None):
    try:
        
        Tool.ocr_touch("GM", timeout=30)
        Tool.ocr_touch("Quick", fuzzy=True, dy_ratio=0.1, timeout=20)
        Tool.ocr_touch_near("主角", "技能", direction="down", timeout=30)
        Tool.ocr_touch_near("GM强力buff", "执行", timeout=30)
        # # 装备
        # Tool.ocr_touch("道具", timeout=30)
        # Tool.ocr_swipe("清空背包", vector=[0, -1.25], timeout=20, min_confidence=0.7)
        # sleep(3)
        # Tool.ocr_touch_near("发一套基础", "执行", timeout=20)
        # # 头衔
        # Tool.ocr_touch("主角", timeout=30)
        # Tool.ocr_swipe("远程lua", vector=[0, -0.5], timeout=20)
        # sleep(3)
        # Tool.ocr_touch_near("添加头衔", "执行", timeout=20)
        Tool.ocr_swipe("主角", vector=[0, -1.25], timeout=20, min_confidence=0.7)
        sleep(3)
        # 仅进入第一个boss
        Tool.ocr_touch("武林高手", fuzzy=False, timeout=30)
        Tool.ocr_touch_near("开启1", "执行", timeout=30)
        Tool.ocr_touch_near("然后", "执行", timeout=20)
        # 等会机器人开打
        sleep(10)
        
        touch(Template(r"tpl1766133841604.png", record_pos=(0.345, -0.183), resolution=(2400, 1080)))
        sleep(3)

        # 获取机器人信息
        Tool.touch_ratio(0.5, 0.9)
        Tool.ocr_touch("世界", fuzzy=False, dy_ratio=-0.15, timeout=30)
        count, centers, texts = Tool.ocr_find_all("的", timeout=40, return_raw_text=True)
        region = extract_top_region_from_ocr(centers, texts)
        Tool.touch_ratio(0.5, 0.9)

        # 通过感叹号参加
        touch(Template(r"tpl1766387346140.png", record_pos=(-0.112, 0.141), resolution=(2400, 1080)))
        Tool.ocr_touch_near("武林高手", "前往", timeout=20)
        if region:
            print(f"去 {region}")
            Tool.ocr_touch_near(region, "前往", "down", timeout=20,align_tol_ratio=10, anchor_expand_ratio=0.2)
        else:
            print("未识别到第一击，单人模式")
            Tool.ocr_touch("前往", timeout=20)
        
        Tool.ocr_wait("锁定目标", timeout=30)
        Tool.ocr_wait("锁定目标", timeout=60*30, wait_gone=True, interval=3)

        # 关闭活动
        Tool.ocr_touch("GM", timeout=30)
        Tool.ocr_touch("Quick", fuzzy=True, dy_ratio=0.1, timeout=20)
        if not Tool.ocr_exists("武林高手", timeout=5):
            Tool.ocr_swipe("主角", vector=[0, -1.25], timeout=20, min_confidence=0.7)
            sleep(3)
        sleep(5)
        Tool.ocr_touch("武林高手", fuzzy=False, timeout=30)
        Tool.ocr_touch_near("关闭", "执行", timeout=20)
        Tool.ocr_touch("GM", fuzzy=False, timeout=30)

    except Exception as e:
        print(f"{e}")
        raise e
    finally:
        Tool.snake_stop("5teyfdjvnd")
            

if __name__ == "__main__":
    # 引入登录脚本
    login_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../登录账号.air"))
    using(login_path)
    import 登录账号  # type: ignore
    登录账号.main()
    before_run()
    main()

    # count, centers, texts = Tool.ocr_find_all("的", timeout=40, return_raw_text=True)
    # region = extract_top_region_from_ocr(centers, texts)
    # Tool.touch_ratio(0.5, 0.9)
    # print(region)






























