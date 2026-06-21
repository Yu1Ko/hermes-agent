import io
import os
import subprocess
import traceback

from fastapi.responses import StreamingResponse, UJSONResponse
from fastapi import Body, FastAPI, APIRouter, Query
import uvicorn
import wda
import uuid
from tidevice import Device
from extensions import logger
from starlette.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
router = APIRouter(tags=["远程控制"])

class MobileControl(object):
    def __init__(self):
        self._app = None
        self._router = None
        self._open_stream_client = {}
        self._open_stream_device = {}
        self._open_stream_port = {}
        self._open_stream_process = {}
        self._open_stream_session = {}
        self._stream_port_start = 30000

    def ping(self):
        return "pong"
    
    def get_useable_stream_port(self):
        port = self._stream_port_start
        while port in self._open_stream_port.values():
            port += 1
        return port
    
    def open_stream(self, device_uuid):
        if device_uuid in self._open_stream_port:
            logger.info(f"设备 {device_uuid} 的远程控制端口已开启 {self._open_stream_port[device_uuid]}")
            return -1
        try:
            use_port = self.get_useable_stream_port()
            p = subprocess.Popen(["tidevice", "-u", f"{device_uuid}", "relay", f"{use_port}", "9100"], shell=False)
            self._open_stream_process[device_uuid] = p
            self._open_stream_port[device_uuid] = use_port
            osret=os.popen(f'tidevice -u {device_uuid} applist | findstr WebDriverAgentRunner-Runner').read()
            wda_pack_name=osret.split()[0]
            c = wda.USBClient(udid=device_uuid, wda_bundle_id=wda_pack_name)
            self._open_stream_client[device_uuid] = c
            t = Device(udid = device_uuid)
            self._open_stream_device[device_uuid] = t
            return use_port
        except:
            logger.error(f"开启远程控制失败: {traceback.format_exc()}")
            self._open_stream_client.pop(device_uuid, None)
            self._open_stream_port.pop(device_uuid, None)
            self._open_stream_device.pop(device_uuid, None)
            p:subprocess.Popen = self._open_stream_process.pop(device_uuid, None)
            if p:
                p.kill()
            return None
        
    def close_stream(self, device_uuid):
        if device_uuid in self._open_stream_client:
            c:wda.USBClient =self._open_stream_client.pop(device_uuid, None)
            self._open_stream_port.pop(device_uuid, None)
            p:subprocess.Popen = self._open_stream_process.pop(device_uuid, None)
            self._open_stream_device.pop(device_uuid, None)
            if p:
                p.kill()
            if c:
                c.close()
            return "ok"
        
        return "stream not found"
    
    def action(self, device_uuid, action, params):
        logger.info(f"device {device_uuid} recv action {action}, params: {params}")
        retry_times = 3
        if device_uuid in self._open_stream_client:
            c:wda.USBClient = self._open_stream_client[device_uuid]
            for i in range(retry_times):
                try:
                    if action == "tap":
                        x = params.get("x", 0)
                        y = params.get("y", 0)
                        c.tap(x, y)
                        return "ok"
                    elif action == "swipe":
                        x1 = params.get("x1", 0)
                        y1 = params.get("y1", 0)
                        x2 = params.get("x2", 0)
                        y2 = params.get("y2", 0)
                        c.swipe(x1, y1, x2, y2)
                        return "ok"
                    elif action == "home":
                        c.home()
                        return "ok"
                    elif action == "lock":
                        c.lock()
                        return "ok"
                    elif action == "unlock":
                        c.unlock()
                        return "ok"
                    elif action == "double_tap":
                        x = params.get("x", 0)
                        y = params.get("y", 0)
                        c.double_tap(x, y)
                        return "ok"
                    elif action == "window_size":
                        return c.window_size()
                    elif action == "fill_text":
                        text = params.get("text", "")
                        input_element = c(className="XCUIElementTypeTextField")
                        if input_element.exists:
                            input_element.set_text(text)
                            return "ok"
                        return "input element not found"
                    elif action == "volume_up":
                        c.press("volumeUp")
                        return "ok"
                    elif action == "volume_down":
                        c.press("volumeDown")
                        return "ok"
                    elif action == "reboot":
                        d = self._open_stream_device[device_uuid]
                        d.reboot()
                        return "ok"
                except Exception as e:
                    logger.error(f"device {device_uuid} action {action} error: {e}, retry {i}")
                    if i == retry_times - 1:
                        return None
                    else:
                        continue
            
m = MobileControl()

def common_response(code = 0, msg = "ok", data = None):
    return {
        "code": code,
        "msg": msg,
        "data": data
    }

@router.get("/open_stream")
def open_stream(device_uuid:str=Query(...)):
    port = m.open_stream(device_uuid)
    if not port:
        return UJSONResponse(common_response(code=-1, msg="开启远程控制失败"))
    elif port == -1:
        return UJSONResponse(common_response(code=-2, msg="该设备已被其他用户开启远程控制"))
    else:
        return UJSONResponse(common_response(data=port))

@router.get("/close_stream")
def close_stream(device_uuid:str=Query(...)):
    return UJSONResponse(common_response(data=m.close_stream(device_uuid)))

@router.post("/action")
def action(device_uuid:str=Body(...), action:str=Body(...), params:dict=Body(...)):
    return UJSONResponse(common_response(data=m.action(device_uuid, action, params)))

@router.get("/screenshot")
def screenshot(device_uuid:str=Query(...)):
    if device_uuid in m._open_stream_device:
        d:Device = m._open_stream_device[device_uuid]
        image = d.screenshot()
        # 将Image对象转换为字节流
        byte_io = io.BytesIO()
        image.save(byte_io, format='JPEG', quality=50)
        byte_io.seek(0)

        return StreamingResponse(byte_io, media_type='image/jpeg')
    return UJSONResponse(common_response(code=-1, msg="device not found"))

app.include_router(router, prefix="/mobile_control/api")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=6677, log_level="info") # 只运行一个worker, 懒得整多进程的东西, 有性能问题再优化