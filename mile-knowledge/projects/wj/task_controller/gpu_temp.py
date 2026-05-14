import os
import threading
import time

import requests


class TempThread(threading.Thread):
    def __init__(self, target_func,  *args, **kwargs):
        super(TempThread, self).__init__()
        self._stop_event = threading.Event()
        self.target_func = target_func
        self.ip = args[0]
        self.case_name = args[1]

    def run(self):
        data = self.target_func(self.ip, self.case_name)

    def stop(self):
        self._stop_event.set()

    def stopped(self):
        return self._stop_event.is_set()

class GPUTemp():
    def __init__(self,device, case_name) -> None:
        self.device=device
        self.case_name=case_name
        self.tempThread = None
        self.is_capture = False

    def start_capture(self):
        if self.is_capture:
            self.stop_capture()

        self.is_capture = True
        self.start_time = int(time.time())
        self.case_name = self.case_name

        if not os.path.exists(os.path.join(os.getcwd(), "temp")):
            os.mkdir("temp")
        self.tempThread = TempThread(self.cap_temp, self.device, self.case_name)
        self.tempThread.start()

    def stop_capture(self):
        if self.is_capture:
            self.is_capture = False
            time.sleep(2)
            self.tempThread.stop()
            self.tempThread = None
            return {"file_path": os.path.join(os.getcwd(), "temp", f"{self.start_time}_{self.case_name}.txt")}
        return None

    def cap_temp(self, ip, case_name):
        sampler = 'thermal_battery,thermal_bms,thermal_pm8150_tz,thermal_gpuss-0-usr,thermal_gpuss-1-usr'
        last = int(time.time())
        try:
            r = requests.get(f"http://{ip}:8080/get/" + sampler)
        except Exception as e:
            os.popen("adb -s {}:5555 shell /data/local/tmp/gpu_temp64 \&".format(ip))
            time.sleep(3)
        with open(os.path.join(os.getcwd(), "temp", f"{self.start_time}_{case_name}.txt"), "w") as f:
            while True:
                if not self.is_capture:
                    break

                now = int(time.time())
                if now != last:
                    last = now

                    r = requests.get(f"http://{ip}:8080/get/" + sampler)
                    # print(r.content)

                    f.write(f"{now},{str(r.content, encoding='utf-8')[1:-1]}\n")
                    
                    # time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
                    f.flush()
                time.sleep(0.3)

if __name__ == '__main__':
    sampler = 'thermal_battery,thermal_bms,thermal_pm8150_tz,thermal_gpuss-0-usr,thermal_gpuss-1-usr'
    r = requests.get(f"http://10.11.242.37:8080/get/" + sampler)
    print(r.content)
        
    