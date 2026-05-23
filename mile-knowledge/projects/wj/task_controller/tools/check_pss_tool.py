import ctypes
import datetime
import json
import os
import re
import threading
import time
import traceback
import requests



class monitor_pss():
    def __init__(self,devices,package_name,project_id,device_name,case,version,udriver,device_ip,device_model,devices_custom):
        self.devices = devices
        self.package_name = package_name
        self.stop_event = threading.Event()
        self.project_id = project_id
        self.err = False
        self.device_name = device_name
        self.devices_custom = devices_custom
        self.pss_stander = self.set_pss_staner()
        self.case = case
        self.version = version
        self.udriver = udriver
        self.device_ip = device_ip
        self.device_model = device_model
        self.capture = None


    def extract_pss_total(self,dumpsys_output):
        match = re.search(r'TOTAL\s+(\d+)', dumpsys_output)
        if match:
            pss_total = match.group(1)
            return round(int(pss_total)/ 1024, 2)
        else:
            raise ValueError("PSS TOTAL not found in the output.")


    def set_pss_staner(self):
        PSS = self.devices_custom["PSS"]
        pss_stander = float(PSS[0]-PSS[1])
        return pss_stander



    def set_cap_snap(self,capture):
        self.capture = capture

    def set_auto_run_thread_id(self,case_excute_thread):
        self.case_excute_thread = case_excute_thread


    def monitor_memory_usage(self):
        while not self.stop_event.is_set():
            command = f"adb -s {self.devices} shell dumpsys meminfo {self.package_name}"
            output = os.popen(command).read()
            pss_total = self.extract_pss_total(output)
            print(f"pss_total -> {pss_total}")
            if float(pss_total) > self.pss_stander:
                self.err = True
                print("开始停止AutoRun线程")
                ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(self.case_excute_thread), ctypes.py_object(SystemExit))
                print("内存监控开始截取内存快照")
                try:
                    if self.project_id == "yycs":
                        self.capture.Grab(f'{self.case["name"]}-结束',f'{self.case["name"]}-结束',self.version)
                    else:
                        # jxsj4特殊处理
                        current_date = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
                        file_name = f"{self.device_model}_{self.case['english_name']}_{current_date}_end"
                        print(f"发送自定义接口TakeSnapshot -> {file_name}")
                        res_snap = self.udriver.custom_interface("TakeSnapshot", f"{file_name}")
                        if "unknown" not in res_snap:
                            response = requests.post(
                                f"http://10.11.67.131:8888/api/track/{self.project_id}/Android/memory-profiler",
                                json={
                                    "ip": self.device_ip,
                                    "casename": self.case["name"],
                                    "version": self.version,
                                    "snap": f"http://10.11.10.147:9000/snapshot/{file_name}.zip",
                                    "tags": []
                                }, timeout=(10, 15))
                            ret = json.loads(response.content)
                            print( f"调用发送内存采集接口{ret['msg']}，内存采集接口地址为-> http://10.11.10.147:9000/snapshot/{file_name}.zip")
                except Exception as e:
                    print(f"中途出现异常 -{e}")
                    print(traceback.format_exc())
                finally:
                    self.udriver.stop()
                    raise Exception("主动抛出异常结束游戏")
            time.sleep(1)

    def start(self):
        print("start_monitor_pss")
        self.monitor_thread = threading.Thread(target=self.monitor_memory_usage, args=())
        self.monitor_thread.start()

    def stop(self):
        print("尝试停止monitor_pss")
        if not self.err:
            self.stop_event.set()
            self.monitor_thread.join()

def perfeye_pss(taskid: str = "67b3f5e51dc9b4a1e5afba06"):
    """获取perfeye内存峰值"""
    url = f"http://perfeye.console.testplus.cn/api/show/task/{taskid}"
    headers = {"Authorization": "Bearer mj6cltF&!L#yWX8k"}
    response = requests.post(url, headers=headers, timeout=(30, 15))
    rqp = json.loads(response.content.decode("utf-8"))["data"]
    pss = float(rqp["LabelInfo"]["All"]["LabelMemory"]["PeakMemory(MB)"])
    return pss


def get_package_detail(project_id,platform,branch,build_type):
    # 获取最新包体
    url = f"https://automation-api.testplus.cn/api/package/list?projectId={project_id}&platform={platform}&branch={branch}&buildType={build_type}"
    res = requests.get(url)
    package_id = int(res.json()["data"][0]["packageId"])
    print(package_id)
    return package_id

def manual_trigger(project_id,platform,branch,build_type,userId,name,parameters,device_id,case_id,token):
    packageId = get_package_detail(project_id,platform,branch,build_type)
    if packageId:
        build_json = {
          "pipelineId": 0,
          "userId": userId,
          "model": {
            "baseInfo": {
              "name": name,
              "packageId": packageId,
              "platform": platform,
              "parameters": parameters,
            },
            "machine": {
              "type": "appoint",
              "machineNum": 1,
              "machineList": [device_id]
            },
            "cases": [
              {
                "caseId": case_id,
                "runningTimes": 1,
                "retryTimes": 1
              }
            ],
            "notify": {
              "controller": {
                "token": token
              },
              "server": {
                "type": "email",
                "users": []
              }
            }
          }
        }
        url = f"https://automation-api.testplus.cn/api/build/execute?projectId={project_id}"
        res = requests.post(url, json=build_json)
        print(f"触发内存快照任务 -> {res.json()}")

if __name__ == '__main__':
    project_id = "jxsj3"
    platform = "android"
    branch = "分支"
    build_type = "Release"
    userId = "wenjingchao@thewesthill.net"
    name = "测试触发任务1"
    device_id = 134
    case_id = 2787
    token = "[6234418]"
    parameters = f"{{\"appKey\":\"{project_id}\",\"notifier\":\"{userId}\",\"performance\":{{\"perfeye\":{{}}}}}}"
    print(parameters)
    # manual_trigger(project_id,platform,branch,build_type,userId,name,parameters,device_id,case_id,token)



