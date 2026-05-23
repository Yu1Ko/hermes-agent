
# -*- encoding=utf8 -*-
__author__ = "admin"

from airtest.core.api import *
from airtest.core.error import TargetNotFoundError
import yace_case.snake_custom as snake_custom
import os
import traceback
from time import time, sleep
import base64
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import os.path
import random
import math
from functools import wraps

def safe_snapshot(filename):
    try:
        snapshot(filename=filename)
        return True
    except Exception as e:
        print(f"截图异常(将在2s后重试): {e}")
        # traceback.print_exc()
        sleep(2)
        return False

#region utils内私有函数

def _build_session(pool_size=4):
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=0.5,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("POST",),
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
        # requests 连接池会自动处理坏死的连接
        raise

def paddleocrOriginal(img_path, timeout=60):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.177.218:8765/ocr'  # 马力工作机2
    return _request_ocr(server_path, img_base64_byte, timeout=timeout)

def paddleocrOriginalV5(img_path, timeout=60):
    with open(img_path, 'rb') as f:
        img_base64_byte = base64.b64encode(f.read())
    server_path = 'http://10.11.176.168:8764/ocr'  # 马力工作机
    return _request_ocr(server_path, img_base64_byte, timeout=timeout)

def _ocr_to_bbox_xyxy(box_like):
        """
        统一把 bbox/points 转成 [x1, y1, x2, y2]
        - 支持: [x1,y1,x2,y2] 或 [[x,y], [x,y], [x,y], [x,y]]
        """
        if not box_like:
            return None
        # 已经是 xyxy
        if isinstance(box_like, (list, tuple)) and len(box_like) >= 4 and not isinstance(box_like[0], (list, tuple)):
            try:
                x1, y1, x2, y2 = box_like[:4]
                return [float(x1), float(y1), float(x2), float(y2)]
            except (TypeError, ValueError):
                return None
        # points: [[x,y], ...]
        if isinstance(box_like, (list, tuple)) and len(box_like) >= 4 and isinstance(box_like[0], (list, tuple)):
            try:
                xs = [float(p[0]) for p in box_like if isinstance(p, (list, tuple)) and len(p) >= 2]
                ys = [float(p[1]) for p in box_like if isinstance(p, (list, tuple)) and len(p) >= 2]
                if not xs or not ys:
                    return None
                return [min(xs), min(ys), max(xs), max(ys)]
            except (TypeError, ValueError):
                return None
        return None


def _ocr_normalize_item(raw_item):
    """
    兼容多种 OCR 返回:
    1) dict: {"text": "...", "score": 0.98, "bbox": [x1,y1,x2,y2] 或 points}
    2) paddleocr 常见格式: [points, [text, score]] 或 (points, (text, score))
    返回: (text, score, bbox_xyxy) or (None, None, None)
    """
    if raw_item is None:
        return None, None, None

    # dict 格式
    if isinstance(raw_item, dict):
        # 兼容“整包结果”误传进来（如: {"0": {...}, "1": {...}}），避免把它当作单条返回
        # 正常情况下应由 _ocr_iter_items 先把条目展开后再传入本函数。
        if "text" not in raw_item and "bbox" not in raw_item and "box" not in raw_item and "points" not in raw_item:
            return None, None, None
        text = raw_item.get("text", "") or ""
        score = raw_item.get("score", raw_item.get("confidence", 0)) or 0
        bbox = raw_item.get("bbox", raw_item.get("box", raw_item.get("points")))
        bbox_xyxy = _ocr_to_bbox_xyxy(bbox)
        try:
            score = float(score)
        except (TypeError, ValueError):
            score = 0
        return text, score, bbox_xyxy

    # list/tuple 格式: [points, [text, score]]
    if isinstance(raw_item, (list, tuple)) and len(raw_item) == 2:
        points = raw_item[0]
        payload = raw_item[1]
        if isinstance(payload, (list, tuple)) and len(payload) >= 2 and isinstance(payload[0], str):
            text = payload[0] or ""
            score = payload[1] or 0
            bbox_xyxy = _ocr_to_bbox_xyxy(points)
            try:
                score = float(score)
            except (TypeError, ValueError):
                score = 0
            return text, score, bbox_xyxy

    return None, None, None


def _ocr_is_paddle_item(x):
    # [points, [text, score]] 或 (points, (text, score))
    return (
        isinstance(x, (list, tuple))
        and len(x) == 2
        and isinstance(x[1], (list, tuple))
        and len(x[1]) >= 2
        and isinstance(x[1][0], str)
    )

def _ocr_is_leaf_dict(x):
    """
    判断 dict 是否为“单条 OCR 结果条目”，而不是“容器 dict”。
    典型条目形态：
      {"text": "...", "score": 0.98, "bbox": [x1,y1,x2,y2]}
    也兼容 bbox 字段名为 box/points。
    """
    if not isinstance(x, dict):
        return False
    # 以 text 为核心标志；bbox/box/points 其一存在更稳，但有些 OCR 可能不返 bbox
    if "text" not in x:
        return False
    if ("bbox" in x) or ("box" in x) or ("points" in x):
        return True
    # 兜底：只要是 text + score/confidence 也视为条目
    return ("score" in x) or ("confidence" in x)


def _ocr_iter_items(obj):
    """
    把 ocr_result 里各种层级的容器递归展开，yield 真正的“识别条目”。
    兼容:
    - dict: 遍历 values
    - list/tuple: 可能是多层嵌套
    - 叶子: dict 或 [points,[text,score]]
    """
    if obj is None:
        return
    # 叶子：paddleocr item 或 “条目 dict”（如 {"text":..., "bbox":..., "score":...}）
    if _ocr_is_paddle_item(obj) or _ocr_is_leaf_dict(obj):
        yield obj
        return
    if isinstance(obj, dict):
        for v in obj.values():
            yield from _ocr_iter_items(v)
        return
    if isinstance(obj, (list, tuple)):
        for v in obj:
            yield from _ocr_iter_items(v)
        return

def _ocr_match_text(text, needle, fuzzy):
    if needle is None:
        return False
    if fuzzy:
        return needle in (text or "")
    return (text or "") == needle


def _ocr_center_and_size(bbox):
    x1, y1, x2, y2 = bbox[:4]
    cx = (x1 + x2) / 2
    cy = (y1 + y2) / 2
    w = max(1.0, (x2 - x1))
    h = max(1.0, (y2 - y1))
    return cx, cy, w, h

def _maybe_rotate_point_by_snapshot(pt, img_path):
    """
    解决“截图是竖图(h>w)，但内容实际是横屏旋转后塞进来的”导致 OCR 坐标点偏的问题。

    约定（适用于本项目横屏游戏场景）：
    - 当 now.png 的 (h > w) 时，认为图像是“横屏内容被旋转90°后保存”为竖图；
      将 OCR 点 (x, y) 从竖图坐标系转换为横屏坐标系：
        x_landscape = h - y
        y_landscape = x
    - 当 (h <= w) 时，不做处理。
    """
    try:
        x, y = pt
        x = float(x)
        y = float(y)
    except Exception:
        return pt

    try:
        from airtest import aircv
        img = aircv.imread(img_path)
        if img is None:
            return pt
        h, w = img.shape[:2]
    except Exception:
        return pt

    if h <= w:
        return pt

    return (float(h) - y, x)

def _get_screen_size():
    """
    获取当前设备屏幕分辨率 (w, h)。
    尽量兼容不同 Airtest 版本/不同设备实现。
    """
    try:
        # airtest.core.api.device()
        dev = device()
        if dev:
            try:
                w, h = dev.get_current_resolution()
                return float(w), float(h)
            except Exception:
                pass
            try:
                info = getattr(dev, "display_info", None) or {}
                w = info.get("width") or info.get("w")
                h = info.get("height") or info.get("h")
                if w and h:
                    return float(w), float(h)
            except Exception:
                pass
    except Exception:
        pass

    # 尝试从全局设备拿
    try:
        dev = getattr(G, "DEVICE", None)
        if dev:
            try:
                w, h = dev.get_current_resolution()
                return float(w), float(h)
            except Exception:
                pass
            try:
                info = getattr(dev, "display_info", None) or {}
                w = info.get("width") or info.get("w")
                h = info.get("height") or info.get("h")
                if w and h:
                    return float(w), float(h)
            except Exception:
                pass
    except Exception:
        pass

    return None, None

# 以锚点框为基准，按“方向 + 屏幕比例距离”限制 near 候选区域
def _ocr_in_anchor_expand_range(anchor_bbox, near_bbox, direction, anchor_expand_ratio, screen_w, screen_h):
    """
    anchor_expand_ratio: 以屏幕尺寸为基准的扩展比例（例如 0.2）。
    - right/left: 使用 screen_w 作为主轴距离上限
    - up/down: 使用 screen_h 作为主轴距离上限
    - any: 同时限制 |dx|<=ratio*screen_w 且 |dy|<=ratio*screen_h（矩形范围）
    """
    if anchor_expand_ratio is None:
        return True
    try:
        r = float(anchor_expand_ratio)
    except (TypeError, ValueError):
        raise ValueError("anchor_expand_ratio 必须是数字（例如 0.2）")
    if r <= 0:
        return False
    if not screen_w or not screen_h:
        raise RuntimeError("无法获取屏幕分辨率，不能使用 anchor_expand_ratio")

    direction = (direction or "right").lower().strip()
    ax1, ay1, ax2, ay2 = anchor_bbox[:4]
    nx1, ny1, nx2, ny2 = near_bbox[:4]

    # 以 bbox 边缘间距作为“往外拓展”的距离（更贴近人的直觉）
    if direction == "right":
        max_d = r * float(screen_w)
        d = max(0.0, float(nx1) - float(ax2))
        return d <= max_d
    if direction == "left":
        max_d = r * float(screen_w)
        d = max(0.0, float(ax1) - float(nx2))
        return d <= max_d
    if direction == "down":
        max_d = r * float(screen_h)
        d = max(0.0, float(ny1) - float(ay2))
        return d <= max_d
    if direction == "up":
        max_d = r * float(screen_h)
        d = max(0.0, float(ay1) - float(ny2))
        return d <= max_d
    if direction == "any":
        # 以中心点差值做矩形约束
        acx, acy, _, _ = _ocr_center_and_size(anchor_bbox)
        ncx, ncy, _, _ = _ocr_center_and_size(near_bbox)
        return (abs(ncx - acx) <= r * float(screen_w)) and (abs(ncy - acy) <= r * float(screen_h))

    return True

#endregion

def touch_ratio(x_ratio=None, y_ratio=None, pos_ratio=None, clamp=True, **touch_kwargs):
    """
    按“屏幕比例”点击（适配多机型/不同分辨率）。

    用法：
    - touch_ratio(0.5, 0.5)               # 点击屏幕中心
    - touch_ratio(pos_ratio=(0.1, 0.9))   # 点击左下区域

    参数：
    - x_ratio/y_ratio: x/y 方向比例坐标，通常取值 [0, 1]（允许超出；clamp=True 时会裁剪）
    - pos_ratio: (x_ratio, y_ratio) 二元组，和 x_ratio/y_ratio 二选一
    - clamp: 是否把坐标裁剪到屏幕范围内（默认 True）
    - touch_kwargs: 透传给 airtest 的 touch()（如 times=2 / duration=0.01 等）
    """
    if pos_ratio is not None:
        try:
            x_ratio, y_ratio = pos_ratio
        except Exception:
            raise ValueError("pos_ratio 需要是 (x_ratio, y_ratio) 形式")

    if x_ratio is None or y_ratio is None:
        raise ValueError("touch_ratio 需要提供 x_ratio/y_ratio 或 pos_ratio")

    try:
        x_ratio = float(x_ratio)
        y_ratio = float(y_ratio)
    except (TypeError, ValueError):
        raise ValueError("x_ratio/y_ratio 必须是数字（例如 0.5, 0.8）")

    sw, sh = _get_screen_size()
    if not sw or not sh:
        raise RuntimeError("无法获取屏幕分辨率，不能使用比例点击 touch_ratio")

    x = x_ratio * sw
    y = y_ratio * sh
    if sh > sw:
        x, y = sh - y, x

    if clamp:
        # 允许边界 0~(w-1/h-1)，避免部分设备触发越界
        x = max(0.0, min(float(sw) - 1.0, float(x)))
        y = max(0.0, min(float(sh) - 1.0, float(y)))
    
    return touch((x, y), **touch_kwargs)

def swipe_ratio(start_ratio, end_ratio=None, vector_ratio=None, clamp=True, **swipe_kwargs):
    """
    按“屏幕比例”滑动（适配多机型/不同分辨率）。

    用法：
    - swipe_ratio((0.5, 0.5), (0.5, 0.2))               # 从屏幕中心上滑到顶部 20% 处
    - swipe_ratio((0.5, 0.5), vector_ratio=(0, -0.3))   # 从屏幕中心上滑 30% 屏幕高度

    参数：
    - start_ratio: 起点 (x_ratio, y_ratio)
    - end_ratio: 终点 (x_ratio, y_ratio)，与 vector_ratio 二选一
    - vector_ratio: 滑动向量 (dx_ratio, dy_ratio)
    - clamp: 是否把起点/终点坐标裁剪到屏幕范围内（默认 True）
    - swipe_kwargs: 透传给 airtest 的 swipe()（如 duration=0.5 / steps=5 等）
    """
    if start_ratio is None:
        raise ValueError("swipe_ratio 需要提供 start_ratio")

    if end_ratio is None and vector_ratio is None:
        raise ValueError("swipe_ratio 需要提供 end_ratio 或 vector_ratio")

    sw, sh = _get_screen_size()
    if not sw or not sh:
        raise RuntimeError("无法获取屏幕分辨率，不能使用 swipe_ratio")

    # 解析起点
    try:
        sx, sy = start_ratio
        x1 = sx * sw
        y1 = sy * sh
    except (TypeError, ValueError):
        raise ValueError("start_ratio 必须是 (x_ratio, y_ratio) 形式")

    if clamp:
        x1 = max(0.0, min(float(sw) - 1.0, float(x1)))
        y1 = max(0.0, min(float(sh) - 1.0, float(y1)))

    v1 = (x1, y1)
    v2 = None
    vec = None

    if end_ratio is not None:
        try:
            ex, ey = end_ratio
            x2 = ex * sw
            y2 = ey * sh
        except (TypeError, ValueError):
            raise ValueError("end_ratio 必须是 (x_ratio, y_ratio) 形式")

        if clamp:
            x2 = max(0.0, min(float(sw) - 1.0, float(x2)))
            y2 = max(0.0, min(float(sh) - 1.0, float(y2)))
        v2 = (x2, y2)

    elif vector_ratio is not None:
        try:
            vx, vy = vector_ratio
            # vector 为像素差值
            vec = (vx * sw, vy * sh)
        except (TypeError, ValueError):
            raise ValueError("vector_ratio 必须是 (dx_ratio, dy_ratio) 形式")

    return swipe(v1, v2=v2, vector=vec, **swipe_kwargs)

#region OCR公共函数

def ocr_wait(
    target_text,
    timeout=20,
    interval=0.5,
    min_confidence=0.7,
    fuzzy=True,
    ocr_func=paddleocrOriginal,
    wait_gone=False,
    gone_confirm=3,
):
    """
    截屏并循环识别：
    - wait_gone=False（默认）：直到找到目标文字或超时，返回文字中心坐标
    - wait_gone=True：在 timeout 内等待直到目标文字“不存在”（连续 gone_confirm 次都没识别到）
      成功返回 True；超时仍存在则抛 TargetNotFoundError
    """

    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout
    last_request_error = None
    had_successful_call = False
    miss_count = 0

    if gone_confirm is None:
        gone_confirm = 3
    try:
        gone_confirm = int(gone_confirm)
    except (TypeError, ValueError):
        gone_confirm = 3
    gone_confirm = max(1, gone_confirm)

    while time() < deadline:
        if not safe_snapshot(pic_path):
            continue
        try:
            remaining = max(0.5, deadline - time())
            req_timeout = min(60, remaining)
            try:
                ocr_result = ocr_func(pic_path, timeout=req_timeout) or {}
            except TypeError:
                ocr_result = ocr_func(pic_path) or {}
            had_successful_call = True
            last_request_error = None
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            last_request_error = exc
            sleep(interval)
            continue

        found = False
        for item in _ocr_iter_items(ocr_result):
            text, confidence, bbox = _ocr_normalize_item(item)

            if confidence < min_confidence or not bbox or len(bbox) < 4:
                continue

            matched = target_text in text if fuzzy else text == target_text
            if not matched:
                continue

            found = True
            if wait_gone:
                break

            x1, y1, x2, y2 = bbox[:4]
            x_center = (int(x1) + int(x2)) / 2
            y_center = (int(y1) + int(y2)) / 2
            return (x_center, y_center)

        if wait_gone:
            if found:
                miss_count = 0
            else:
                miss_count += 1
                if miss_count >= gone_confirm:
                    return True

        sleep(interval)

    if last_request_error is not None and not had_successful_call:
        if wait_gone:
            raise TargetNotFoundError(
                f"未在 {timeout}s 内等待到文本消失：{target_text}（OCR请求持续失败：{last_request_error}）"
            )
        raise TargetNotFoundError(f"未在 {timeout}s 内识别到文本：{target_text}（OCR请求持续失败：{last_request_error}）")

    if wait_gone:
        raise TargetNotFoundError(f"未在 {timeout}s 内等待到文本消失：{target_text}")
    raise TargetNotFoundError(f"未在 {timeout}s 内识别到文本：{target_text}")

def ocr_exists(target_text, timeout=20, interval=0.5, min_confidence=0.7, fuzzy=True, ocr_func=paddleocrOriginal):
    """
    判断目标文字是否存在（不抛异常）：存在返回 True，否则返回 False。
    适合用在“有则点/无则跳过”的流程里。
    """

    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout

    while time() < deadline:
        if not safe_snapshot(pic_path):
            continue
        try:
            remaining = max(0.5, deadline - time())
            req_timeout = min(60, remaining)
            try:
                ocr_result = ocr_func(pic_path, timeout=req_timeout) or {}
            except TypeError:
                ocr_result = ocr_func(pic_path) or {}
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            sleep(interval)
            continue

        for item in _ocr_iter_items(ocr_result):
            text, confidence, bbox = _ocr_normalize_item(item)
            if confidence < min_confidence or not bbox or len(bbox) < 4:
                continue
            matched = target_text in text if fuzzy else text == target_text
            if matched:
                return True

        sleep(interval)

    return False

def ocr_find_all(
    target_text=None,
    timeout=2,
    interval=0.5,
    min_confidence=0.7,
    fuzzy=True,
    ocr_func=paddleocrOriginal,
    max_results=None,
    return_raw_text=False,
):
    """
    获取“目标文字”在屏幕上出现的最高计数及对应中心点（至少取 3 次识别内的最高）。

    - target_text：必填，要统计的文字（支持 fuzzy）
    - return_raw_text=False：返回 (best_count, best_centers)
    - return_raw_text=True：返回 (best_count, best_centers, best_texts)
      - best_count: 最高出现次数
      - best_centers: 该次识别中所有匹配项的中心点列表 [(cx, cy), ...]
      - best_texts: 该次识别中所有匹配项的识别文本列表，与 best_centers 一一对应
    """
    if target_text is None:
        raise ValueError("ocr_find_all 现在必须传 target_text（例如 '前往'）")

    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout
    min_scans = 3
    scans_done = 0
    best_count = -1
    best_centers = []
    best_texts = []

    if max_results is not None:
        try:
            max_results = int(max_results)
        except (TypeError, ValueError):
            max_results = None
        if max_results is not None and max_results <= 0:
            max_results = None

    while scans_done < min_scans or time() < deadline:
        centers = []
        texts = [] if return_raw_text else None
        if not safe_snapshot(pic_path):
            continue
        try:
            remaining = max(0.5, deadline - time())
            req_timeout = min(60, remaining)
            try:
                ocr_result = ocr_func(pic_path, timeout=req_timeout) or {}
            except TypeError:
                ocr_result = ocr_func(pic_path) or {}
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            sleep(interval)
            scans_done += 1
            continue

        for item in _ocr_iter_items(ocr_result):
            text, conf, bbox = _ocr_normalize_item(item)
            if conf < min_confidence or not bbox or len(bbox) < 4:
                continue

            if not _ocr_match_text(text, target_text, fuzzy):
                continue

            cx, cy, _, _ = _ocr_center_and_size(bbox)
            centers.append((cx, cy))
            if return_raw_text:
                texts.append(text)
            if max_results is not None and len(centers) >= max_results:
                break

        scans_done += 1

        if len(centers) > best_count:
            best_count = len(centers)
            best_centers = centers
            if return_raw_text:
                best_texts = texts

        sleep(interval)

    if best_count < 0:
        best_count = 0
        if return_raw_text:
            best_texts = []

    if return_raw_text:
        return best_count, best_centers, (best_texts or [])
    return best_count, best_centers

def ocr_touch(
    target_text,
    dx_ratio=0,
    dy_ratio=0,
    offset_ratio=None,
    **wait_kwargs,
):
    """
    OCR 找到文字后点击；支持按屏幕比例做相对偏移（适配多机型）。

    - 默认：ocr_touch("前往")  点击识别到的文字中心点
    - 比例偏移：ocr_touch("前往", dx_ratio=0.05, dy_ratio=0)  向右偏移屏宽 5%
    - 或：  ocr_touch("前往", offset_ratio=(0.05, 0))
    """
    target_coords = ocr_wait(target_text, **wait_kwargs)
    # 如果截图 now.png 是竖图(h>w)，先把 OCR 坐标转回横屏坐标系
    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    target_coords = _maybe_rotate_point_by_snapshot(target_coords, pic_path)

    if offset_ratio is not None:
        try:
            dx_ratio, dy_ratio = offset_ratio
        except Exception:
            raise ValueError("offset_ratio 需要是 (dx_ratio, dy_ratio) 形式")

    sw, sh = _get_screen_size()
    if not sw or not sh:
        raise RuntimeError("无法获取屏幕分辨率，不能使用比例偏移")
    dx = dx_ratio * sw
    dy = dy_ratio * sh

    try:
        x, y = target_coords
    except Exception:
        # 兜底：如果 ocr_wait 返回的不是二元坐标，就直接 touch
        touch((x + dx, y + dy))
        return (x + dx, y + dy)

    touch((x + dx, y + dy))
    return (x + dx, y + dy)

def ocr_swipe(target_text, v2=None, vector=None, duration=0.5, steps=5, **wait_kwargs):
    """
    先 OCR 定位目标文字中心点作为起点，再执行 swipe。
    - 用法1（推荐）: ocr_swipe("GM", vector=[0, 0.3])
    - 用法2: ocr_swipe("文字A", v2="文字B")  # 从一个文字滑动到另一个文字（终点也用 OCR 定位）
    - 用法3: ocr_swipe("GM", v2=(x2, y2))
    """
    if v2 is None and vector is None:
        raise ValueError("ocr_swipe 需要提供 v2 或 vector 其一")
    start_coords = ocr_wait(target_text, **wait_kwargs)
    # v2 扩展：支持把终点也写成“可被 ocr_wait 解析的 target_text”（传入文字）
    # - str: "前往"
    # - dict: {"text":"前往","safe":{...}}（与 ocr_wait 的扩张区域筛选兼容）
    # - tuple/list: ("前往", {...})（与 ocr_wait 的 tuple 形式兼容）
    def _is_number(x):
        # bool 是 int 子类，这里排除掉
        return isinstance(x, (int, float)) and not isinstance(x, bool)

    def _is_point_like(obj):
        return (
            isinstance(obj, (list, tuple))
            and len(obj) >= 2
            and _is_number(obj[0])
            and _is_number(obj[1])
        )

    if v2 is not None and not _is_point_like(v2) and isinstance(v2, (str, dict, list, tuple)):
        v2 = ocr_wait(v2, **wait_kwargs)
    return swipe(start_coords, v2=v2, vector=vector, duration=duration, steps=steps)

def _ocr_collect_boxes(ocr_result, min_confidence=0.7):
    """
    把 OCR 返回统一转换为 boxes 列表，供 near/multiline 等逻辑复用。
    box 格式：
      {"text","conf","bbox","cx","cy","w","h"}
    """
    boxes = []
    for item in _ocr_iter_items(ocr_result):
        text, conf, bbox = _ocr_normalize_item(item)
        if conf < min_confidence or not bbox or len(bbox) < 4:
            continue
        cx, cy, w, h = _ocr_center_and_size(bbox)
        boxes.append(
            {
                "text": text,
                "conf": conf,
                "bbox": bbox,
                "cx": cx,
                "cy": cy,
                "w": w,
                "h": h,
            }
        )
    return boxes

def ocr_wait_near(
    anchor_text,
    near_text="执行",
    direction="right",
    timeout=20,
    interval=0.5,
    min_confidence=0.7,
    fuzzy_anchor=True,
    fuzzy_near=True,
    ocr_func=paddleocrOriginal,
    align_tol_ratio=0.6,
    anchor_expand_ratio=None,
):
    """
    等待“anchor_text 附近的 near_text”出现并返回 near_text 的中心点坐标（不点击）。
    典型场景：列表左侧是描述文字，右侧是「执行」按钮（按钮里也有文字）。
    """

    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout
    last_request_error = None
    had_successful_call = False

    direction = (direction or "right").lower().strip()
    if direction not in ("right", "left", "up", "down", "any"):
        raise ValueError(f"direction 不支持：{direction}")

    sw = sh = None
    if anchor_expand_ratio is not None:
        sw, sh = _get_screen_size()

    while time() < deadline:
        if not safe_snapshot(pic_path):
            continue
        try:
            remaining = max(0.5, deadline - time())
            req_timeout = min(60, remaining)
            try:
                ocr_result = ocr_func(pic_path, timeout=req_timeout) or {}
            except TypeError:
                ocr_result = ocr_func(pic_path) or {}
            had_successful_call = True
            last_request_error = None
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            last_request_error = exc
            sleep(interval)
            continue

        boxes = _ocr_collect_boxes(ocr_result, min_confidence=min_confidence)

        anchors = [b for b in boxes if _ocr_match_text(b["text"], anchor_text, fuzzy_anchor)]
        nears = [b for b in boxes if _ocr_match_text(b["text"], near_text, fuzzy_near)]

        best = None
        best_score = None

        for a in anchors:
            for n in nears:
                dx = n["cx"] - a["cx"]
                dy = n["cy"] - a["cy"]

                # 方向约束
                if direction == "right" and dx <= 0:
                    continue
                if direction == "left" and dx >= 0:
                    continue
                if direction == "down" and dy <= 0:
                    continue
                if direction == "up" and dy >= 0:
                    continue

                # 距离范围约束
                if anchor_expand_ratio is not None:
                    if not _ocr_in_anchor_expand_range(a["bbox"], n["bbox"], direction, anchor_expand_ratio, sw, sh):
                        continue

                if direction in ("right", "left"):
                    tol = max(a["h"], n["h"]) * align_tol_ratio
                    if abs(dy) > tol:
                        continue
                    score = (dx * dx) + ((dy * 2) * (dy * 2))
                elif direction in ("up", "down"):
                    tol = max(a["w"], n["w"]) * align_tol_ratio
                    if abs(dx) > tol:
                        continue
                    score = (dy * dy) + ((dx * 2) * (dx * 2))
                else:
                    score = (dx * dx) + (dy * dy)

                # 轻微偏向更高置信度
                score = score / max(0.1, (n["conf"] + a["conf"]) / 2)

                if best_score is None or score < best_score:
                    best_score = score
                    best = n

        if best:
            return (best["cx"], best["cy"])

        sleep(interval)

    if last_request_error is not None and not had_successful_call:
        raise TargetNotFoundError(
            f"未在 {timeout}s 内匹配到：anchor={anchor_text} near={near_text}（OCR请求持续失败：{last_request_error}）"
        )
    raise TargetNotFoundError(f"未在 {timeout}s 内匹配到：anchor={anchor_text} near={near_text}")

def ocr_wait_multiline_near(
    line1_text,
    line2_text,
    near_text="执行",
    direction="right",
    timeout=20,
    interval=0.5,
    min_confidence=0.7,
    fuzzy_line1=True,
    fuzzy_line2=False,
    fuzzy_near=True,
    ocr_func=paddleocrOriginal,
    align_tol_ratio=0.6,
    anchor_expand_ratio=None,
    x_align_ratio=2.0,
    y_gap_ratio=3.0,
):
    """
    等待“由两行文字组成的锚点(line1_text 在上，line2_text 在下) 附近的 near_text”出现并返回 near_text 中心点。
    典型场景：列表项的描述被换行拆成两条 OCR 结果，且两条都可能在别的项里重复出现。

    说明：
    - line1_text 默认模糊匹配（包含即可），line2_text 默认精确匹配（防止误命中更长文本）
    - 通过“上下关系 + x 对齐 + 行间距”先组成复合锚点，再复用 near 的方向/对齐/距离约束挑选 near_text。
    """
    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    deadline = time() + timeout
    last_request_error = None
    had_successful_call = False

    direction = (direction or "right").lower().strip()
    if direction not in ("right", "left", "up", "down", "any"):
        raise ValueError(f"direction 不支持：{direction}")

    sw = sh = None
    if anchor_expand_ratio is not None:
        sw, sh = _get_screen_size()

    while time() < deadline:
        if not safe_snapshot(pic_path):
            continue
        try:
            remaining = max(0.5, deadline - time())
            req_timeout = min(60, remaining)
            try:
                ocr_result = ocr_func(pic_path, timeout=req_timeout) or {}
            except TypeError:
                ocr_result = ocr_func(pic_path) or {}
            had_successful_call = True
            last_request_error = None
        except requests.RequestException as exc:
            print(f"请求失败：{exc}")
            last_request_error = exc
            sleep(interval)
            continue

        boxes = _ocr_collect_boxes(ocr_result, min_confidence=min_confidence)
        l1s = [b for b in boxes if _ocr_match_text(b["text"], line1_text, fuzzy_line1)]
        l2s = [b for b in boxes if _ocr_match_text(b["text"], line2_text, fuzzy_line2)]
        nears = [b for b in boxes if _ocr_match_text(b["text"], near_text, fuzzy_near)]

        # 先组成复合锚点
        anchors = []
        for b1 in l1s:
            for b2 in l2s:
                # b2 必须在 b1 下方
                y_diff = b2["cy"] - b1["cy"]
                if y_diff <= 0:
                    continue
                # x 近似对齐（用行高做经验容差，和旧版 ocr_touch_multiline 一致）
                tol_x = max(b1["h"], b2["h"]) * float(x_align_ratio)
                if abs(b1["cx"] - b2["cx"]) > tol_x:
                    continue
                # 行距约束：不能离得太远
                tol_y = max(b1["h"], b2["h"]) * float(y_gap_ratio)
                if y_diff > tol_y:
                    continue

                # union bbox 作为锚点范围，用于 anchor_expand_ratio 约束
                x1 = min(b1["bbox"][0], b2["bbox"][0])
                y1 = min(b1["bbox"][1], b2["bbox"][1])
                x2 = max(b1["bbox"][2], b2["bbox"][2])
                y2 = max(b1["bbox"][3], b2["bbox"][3])
                bbox = [x1, y1, x2, y2]
                cx, cy, w, h = _ocr_center_and_size(bbox)
                anchors.append(
                    {
                        "text": f"{b1['text']}\\n{b2['text']}",
                        "conf": min(b1["conf"], b2["conf"]),
                        "bbox": bbox,
                        "cx": cx,
                        "cy": cy,
                        "w": w,
                        "h": h,
                        # 用于优先级（越近越像同一项）
                        "_pair_gap": y_diff,
                    }
                )

        if not anchors or not nears:
            sleep(interval)
            continue

        # 优先保留“间距更合理/置信度更高”的少量 anchor，避免极端情况下组合爆炸
        anchors.sort(key=lambda a: (a.get("_pair_gap", 999999), -a.get("conf", 0)))
        anchors = anchors[:30]

        best = None
        best_score = None

        for a in anchors:
            for n in nears:
                dx = n["cx"] - a["cx"]
                dy = n["cy"] - a["cy"]

                # 方向约束
                if direction == "right" and dx <= 0:
                    continue
                if direction == "left" and dx >= 0:
                    continue
                if direction == "down" and dy <= 0:
                    continue
                if direction == "up" and dy >= 0:
                    continue

                # 距离范围约束
                if anchor_expand_ratio is not None:
                    if not _ocr_in_anchor_expand_range(a["bbox"], n["bbox"], direction, anchor_expand_ratio, sw, sh):
                        continue

                if direction in ("right", "left"):
                    tol = max(a["h"], n["h"]) * align_tol_ratio
                    if abs(dy) > tol:
                        continue
                    score = (dx * dx) + ((dy * 2) * (dy * 2))
                elif direction in ("up", "down"):
                    tol = max(a["w"], n["w"]) * align_tol_ratio
                    if abs(dx) > tol:
                        continue
                    score = (dy * dy) + ((dx * 2) * (dx * 2))
                else:
                    score = (dx * dx) + (dy * dy)

                # 轻微偏向更高置信度
                score = score / max(0.1, (n["conf"] + a["conf"]) / 2)

                if best_score is None or score < best_score:
                    best_score = score
                    best = n

        if best:
            return (best["cx"], best["cy"])

        sleep(interval)

    if last_request_error is not None and not had_successful_call:
        raise TargetNotFoundError(
            f"未在 {timeout}s 内匹配到：multiline=({line1_text}+{line2_text}) near={near_text}（OCR请求持续失败：{last_request_error}）"
        )
    raise TargetNotFoundError(f"未在 {timeout}s 内匹配到：multiline=({line1_text}+{line2_text}) near={near_text}")

def ocr_exists_near(
    anchor_text,
    near_text="执行",
    direction="right",
    timeout=2,
    interval=0.5,
    min_confidence=0.7,
    fuzzy_anchor=True,
    fuzzy_near=True,
    ocr_func=paddleocrOriginal,
    align_tol_ratio=0.6,
):
    """
    判断“anchor_text 附近的 near_text”是否存在（不抛异常）：存在返回 True，否则返回 False。
    典型场景：列表左侧是描述文字，右侧是「执行」按钮。
    """
    try:
        ocr_wait_near(
            anchor_text,
            near_text=near_text,
            direction=direction,
            timeout=timeout,
            interval=interval,
            min_confidence=min_confidence,
            fuzzy_anchor=fuzzy_anchor,
            fuzzy_near=fuzzy_near,
            ocr_func=ocr_func,
            align_tol_ratio=align_tol_ratio,
        )
        return True
    except TargetNotFoundError:
        return False


def ocr_touch_near(
    anchor_text,
    near_text="执行",
    direction="right",
    timeout=20,
    interval=0.5,
    min_confidence=0.7,
    fuzzy_anchor=True,
    fuzzy_near=True,
    ocr_func=paddleocrOriginal,
    align_tol_ratio=0.6,
    anchor_expand_ratio=None,
):
    """
    场景：列表左侧是描述文字，右侧是「执行」按钮（按钮里也有文字）。
    功能：先识别到 anchor_text，然后在其附近（默认右侧同一行）找到 near_text 并点击。

    参数：
    - anchor_text: 作为“行锚点”的文字（例如「武林高手」或更长的描述片段）
    - near_text: 要点击的目标文字（默认「执行」）
    - direction: "right" | "left" | "up" | "down" | "any"
    - align_tol_ratio: 对齐容差比例。right/left 时用 y 对齐；up/down 时用 x 对齐。
      容差 = max(anchor_h, near_h) * align_tol_ratio（或对应宽度）
    """
    pt = ocr_wait_near(
        anchor_text,
        near_text=near_text,
        direction=direction,
        timeout=timeout,
        interval=interval,
        min_confidence=min_confidence,
        fuzzy_anchor=fuzzy_anchor,
        fuzzy_near=fuzzy_near,
        ocr_func=ocr_func,
        align_tol_ratio=align_tol_ratio,
        anchor_expand_ratio=anchor_expand_ratio,
    )
    pic_path = os.path.join(os.path.dirname(__file__), "now.png")
    pt2 = _maybe_rotate_point_by_snapshot(pt, pic_path)
    touch(pt2)
    return pt

def ocr_touch_multiline(line1_text, line2_text, action_text="执行", timeout=10):
    """
    查找竖直排列的两行文字，找到后点击其右侧的按钮。
    :param line1_text: 第一行文字，如 "开启本服宋金"
    :param line2_text: 第二行文字，如 "报名"
    :param action_text: 目标按钮文字，如 "执行"
    """
    try:
        pt = ocr_wait_multiline_near(
            line1_text,
            line2_text,
            near_text=action_text,
            direction="right",
            timeout=timeout,
            interval=0.5,
            min_confidence=0.6,
            fuzzy_line1=True,
            fuzzy_line2=False,
        )
        pic_path = os.path.join(os.path.dirname(__file__), "now.png")
        pt2 = _maybe_rotate_point_by_snapshot(pt, pic_path)
        touch(pt2)
        return True
    except TargetNotFoundError:
        print(f"未找到组合: {line1_text} + {line2_text}")
        return False

#endregion

def snake_trriger(snake_case,client,haterace,timeout,loadmachines):
    result = snake_custom.start(snake_case,client,haterace,timeout,loadmachines)
    if not result:
        raise Exception("压测机器人拉起失败")
    return True

def snake_stop(projectId):
    snake_custom.stop(projectId)

