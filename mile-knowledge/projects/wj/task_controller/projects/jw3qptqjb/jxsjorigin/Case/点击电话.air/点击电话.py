# -*- encoding=utf8 -*-
__author__ = "kingsoft"

from airtest.core.api import *
from airtest.core.error import TargetNotFoundError
import os
from time import time, sleep
import base64
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

auto_setup(__file__)


def _build_session(pool_size=4):
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=0.5,
        status_forcelist=(429, 500, 502, 503, 504),
        raise_on_status=False,
    )
    adapter = HTTPAdapter(pool_connections=pool_size, pool_maxsize=pool_size, max_retries=retry)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


_http_session = _build_session()


def _request_ocr(server_path, img_base64_byte, timeout=60):
    global _http_session
    try:
        response = _http_session.post(
            server_path,
            data=img_base64_byte,
            timeout=timeout,
            headers={"Connection": "keep-alive"},
        )
        response.raise_for_status()
        return response.json().get("result", {})
    except requests.RequestException:
        try:
            _http_session.close()
        finally:
            _http_session = _build_session()
        raise

def paddleocrOriginal(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    return _request_ocr(server_path, img_base64_byte)

def paddleocrOriginalV5(img_path):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.168:8764/ocr'  # 马力工作机
    return _request_ocr(server_path, img_base64_byte)

def ocr_wait(target_text, timeout=20, interval=0.5, min_confidence=0.9, fuzzy=True, ocr_func=paddleocrOriginalV5):
    """
    截屏并循环识别，直到找到目标文字或超时，返回文字中心坐标
    """
    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout

    while time() < deadline:
        snapshot(filename=pic_path)
        try:
            ocr_result = ocr_func(pic_path) or {}
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            sleep(interval)
            continue

        if isinstance(ocr_result, dict):
            iterables = ocr_result.values()
        else:
            iterables = ocr_result

        for item in iterables:
            text = item.get("text", "")
            confidence = item.get("score", 0)
            bbox = item.get("bbox")

            if confidence < min_confidence or not bbox or len(bbox) < 4:
                continue

            matched = target_text in text if fuzzy else text == target_text
            if not matched:
                continue

            x1, y1, x2, y2 = bbox[:4]
            x_center = (int(x1) + int(x2)) / 2
            y_center = (int(y1) + int(y2)) / 2
            return (x_center, y_center)

        sleep(interval)

    raise TargetNotFoundError(f"未在 {timeout}s 内识别到文本：{target_text}")


def ocr_touch(target_text, **wait_kwargs):
    try:
        target_coords = ocr_wait(target_text, **wait_kwargs)
        touch(target_coords)
    except TargetNotFoundError:
        print(f"未找到目标文字：{target_text}")

        
auto_setup(__file__)

touch(Template(r"tpl1763519715841.png", record_pos=(-0.351, 0.896), resolution=(1080, 2374)))

ocr_touch("联系人", timeout=20)

ocr_touch("通话", timeout=20)
