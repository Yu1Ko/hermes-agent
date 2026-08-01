import io
import subprocess
import threading
import time
import socket
import imageio
import tidevice
import os
import wda

class SocketBuffer:
    """ Since I can't find a lib that can buffer socket read and write, so I write a one """
    def __init__(self, sock: socket.socket):
        self._sock = sock
        self._buf = bytearray()
    def _drain(self):
        _data = self._sock.recv(1024)
        if _data is None:
            raise IOError("socket closed")
        self._buf.extend(_data)
        return len(_data)
    def read_until(self, delimeter: bytes) -> bytes:
        """ return without delimeter """
        while True:
            index = self._buf.find(delimeter)
            if index != -1:
                _return = self._buf[:index]
                self._buf = self._buf[index + len(delimeter):]
                return _return
            self._drain()
    def read_bytes(self, length: int) -> bytes:
        while length > len(self._buf):
            self._drain()
        _return, self._buf = self._buf[:length], self._buf[length:]
        return _return
    def write(self, data: bytes):
        return self._sock.sendall(data)

# 接入ad_ios/Android_IOS中传入platform（设备型号如ios）
class screen_recording(object):
    def __init__(self,task_running_id,device_name,platform,device_s,name,c=None):
        self.task_running_id = task_running_id
        self.device_name = device_name
        self.platform = platform
        self.process = None
        self.END = False
        self.transcribe_threading = None
        self.device_s = device_s
        self.video_name = f"{self.task_running_id}{self.device_name}{name}.mp4"
        self.video_storage_URL = '/root/video'
        if not os.path.exists(self.video_storage_URL):
            os.makedirs(self.video_storage_URL)
        if platform == "ios":
            devices = self.device_s.split(":")[0].replace('.', '') if "10." in self.device_s else self.device_s
            # c = self.Android_IOS.WDA_U2  对应ios的wda连接
            self.c = c
            self.t = tidevice.Device(devices)

    def _video(self):
        # 启动scrcpy并录制屏幕到指定文件
        print(f"self.video_name = {self.video_name}")
        try:

            if self.platform == "ios":
                print("进入ios视频录制分支")
                self._old_fps = self.c.appium_settings()['mjpegServerFramerate']
                _fps = 10
                self.c.appium_settings({"mjpegServerFramerate": _fps})
                # Read image from WDA mjpeg server
                pconn = self.t.create_inner_connection(9100)  # default WDA mjpeg server port
                sock = pconn.get_socket()
                buf = SocketBuffer(sock)
                buf.write(b"GET / HTTP/1.0\r\nHost: localhost\r\n\r\n")
                buf.read_until(b'\r\n\r\n')
                print("ios视频录制准备完成")
                self.wr = imageio.get_writer(f"{self.video_storage_URL}/{self.video_name}", fps=_fps)
                while True:
                    # read http header
                    length = None
                    while True:
                        line = buf.read_until(b'\r\n')
                        if line.startswith(b"Content-Length"):
                            length = int(line.decode('utf-8').split(": ")[1])
                            break
                    while True:
                        if buf.read_until(b'\r\n') == b'':
                            break
                    imdata = buf.read_bytes(length)
                    im = imageio.imread(io.BytesIO(imdata))
                    if self.END:
                        self.wr.close()
                        break
                    self.wr.append_data(im)
            else:
                print("进入安卓视频录制分支")
                self.process = subprocess.Popen(f"adb -s {self.device_s} shell \"screenrecord /sdcard/video.mp4\"", shell=True)
                while not self.END:
                    time.sleep(0.5)
                self.process.terminate()
                while self.process.poll() is None:
                    time.sleep(0.5)
        except Exception as e:
            raise e


    def start_video(self):
        """开始录制"""
        print("开始录制视频")
        self.END = False
        self.transcribe_threading = threading.Thread(target=self._video)
        self.transcribe_threading.start()

    def stop_video(self):
        print("结束录制视频")
        self.END = True
        if self.transcribe_threading:
            self.transcribe_threading.join()

    def video_synthesis(self):
        try:
            if self.platform == "ios":
                pass
            else:
                print("安卓视频上传至PC")
                subprocess.run(f"adb -s {self.device_s} pull /sdcard/video.mp4 {self.video_storage_URL}/{self.video_name}",shell=True)
        except Exception as e:
            raise e

        return f"{self.video_storage_URL}/{self.video_name}"


if __name__ == "__main__":
    video = screen_recording("Android","t4dunz7xlfyxqww4")
    video.start_video()
    time.sleep(10)
    video.stop_video()
    print(video.video_synthesis())

