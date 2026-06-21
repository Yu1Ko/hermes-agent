# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
from airtest.core.error import TargetNotFoundError
import os
import sys
from time import time, sleep
import base64
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import os.path
import random

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import Tool

auto_setup(__file__)
# auto_setup(__file__, devices=["Android://127.0.0.1:5037/e2f2a346"])
# auto_setup(__file__, devices=["ios:///127.0.0.1:8100/00008030-000E509E016A802E"])

def main():
    Tool.touch_ratio(0.15, 0.25)

    Tool.ocr_touch("可领奖",min_confidence=0.8, timeout=330)
    sleep(7.0)

    touch(Template(r"tpl1765873317584.png"))
    sleep(5.0)
    Tool.ocr_touch("自动精铸", timeout=30)
    sleep(5.0)
    touch(Template(r"tpl1763365178168.png", target_pos=4))
    sleep(4.0)
    touch(Template(r"tpl1763365178168.png", target_pos=4))
    sleep(3.0)

    Tool.ocr_wait("挑战提升挂机效率", fuzzy=False, timeout=300)
    touch(Template(r"tpl1765873803769.png", record_pos=(0.285, -0.041), resolution=(2400, 1080)))
    sleep(30.0)
    Tool.ocr_touch("可领奖", min_confidence=0.8, timeout=60)
    sleep(6.0)

    Tool.ocr_wait("侠路引", timeout=180)

if __name__ == "__main__":
    # login_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../登录账号.air"))
    # using(login_path)
    # import 登录账号  # type: ignore
    # 登录账号.main(new_character=True, new_character_class="天王")
    main()


