import json
import os
import re
import time
import traceback

import requests
from CaseCommon import *
from BaseToolFunc import *

web_hook = "https://xz.wps.cn/api/v1/webhook/send?key=3edc46bca2f07753d552b1981ba9f8a7"


def get_file_revise_time(filePath):
    t = os.path.getmtime(filePath)
    time_struct = time.localtime(t)
    times = time.strftime('%Y-%m-%d', time_struct)
    return times


def push_warn_info(info):  # 预警信息
    message = {
        "msgtype": "text",
        "text": {
            "content": info
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))


def push_info(added_folder, info):  # 提示（或常见模块和函数的宕机，不打印堆栈，只提示）
    msg = "新增宕机: " + added_folder
    message = {
        "msgtype": "text",
        "text": {
            "content": msg + "\n" + info
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))


def push_report(added_folder, ErrorCodeMsg, stack_msg):  # 新增宕机 （不常见的宕机、新增）
    msg = "新增宕机: \\" + added_folder
    message = {
        "msgtype": "markdown",
        "markdown": {
            "text": "<at user_id=\"-1\">所有人</at>" + "**" + msg + "**\n\n" +
                    "**<font color='red'>" + ErrorCodeMsg + "</font>**\n" +
                    stack_msg + "\n\n注：协作字数有限制，堆栈只取前15行，详细堆栈查看dump",
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))


class CaseBVTDumpMonitor(CaseCommon):  # 用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类

    def __init__(self, path):
        CaseCommon.__init__(self)  # 父类初始化
        self.ErrorCodeMsg = " "
        self.path_to_watch = path
        self.stack_content = []

        # ErrorCode 检查
        self.ErrorCode_moduleOrFunc = {
            "设备移除": ["887a0005", "887a0006", "887a0007"],
            "内存不足": ["badbadff", "8fffffffe", "8007000e"],
            "显卡驱动内部错误": ["887a0020"],
            "客户端异常退出": ["8fffffff"]
        }

        # 常见模块和函数
        self.common_moduleOrFunc = {
            "驱动模块宕机": ["nvwgf2umx", "igd10um64xe", "atidxx64", "igc64"],
            "gmesdk第三方库模块宕机": ["gmesdk"],
            "perfeye相关模块宕机": ["d3d11hook"],
            "Curl_verify_windows_version宕机": ["KGUIX64!Curl_verify_windows_version"]
        }
        self.dump_type = None

    def wait_for_close(self, analyzeFile):  # 等待analyze文件解析完成
        t_all = time.time()
        t = time.time()
        dump_size = 0
        while 1:
            time.sleep(5)
            if time.time() - t_all > 10 * 60:
                # 解析文件不存在
                if not os.path.exists(analyzeFile):
                    info = "提示：超过10分钟未生成analyze.txt文件,请自行检查dump"
                    push_info(analyzeFile, info)  # 提示查看dump消息，发送信息到飞书
                else:
                    # 解析文件存在
                    info = '提示：analyze 解析已经超过10分钟了'
                    push_info(analyzeFile, info)
                return False

            if time.time() - t > 30:
                # 每30秒查看一次analyze文件是否存在
                if not os.path.exists(analyzeFile):
                    continue
                # 每30秒查看一次analyze大小，如果大小没有变就认为写完了
                curr_size = os.path.getsize(analyzeFile)
                if curr_size == dump_size:
                    return True
                dump_size = curr_size
                t = time.time()

    def check_analyze_stack(self, analyze_path):  # 获取堆栈，初步分析常见宕机类型
        isStack = False
        with open(analyze_path, 'r') as f:
            lines = f.readlines()
            for i in range(1, len(lines)):
                if 'quit' in lines[i]:
                    break

                if '- code' in lines[i]:
                    self.ErrorCodeMsg = lines[i] + "\n"
                    for key in self.ErrorCode_moduleOrFunc.keys():
                        if any(substring in lines[i] for substring in self.ErrorCode_moduleOrFunc[key]):
                            self.dump_type = key

                if isStack:
                    stack_l = lines[i] + "\n"  # 协作消息排版问题，需要换行
                    self.stack_content.append(stack_l)
                    for key in self.common_moduleOrFunc.keys():
                        if any(substring in lines[i] for substring in self.common_moduleOrFunc[key]):
                            self.dump_type = key

                if 'Child-SP' in lines[i]:
                    isStack = True

    def send_msg(self, dir_name):  # 新增宕机消息，同步信息
        lines = 0  # 行数限制：协作太多字发不出去（取个前15行）
        stack_content = self.stack_content[0:15]

        if self.dump_type:
            info = "宕机类型：" + self.dump_type + "\n" + self.ErrorCodeMsg
            push_info(dir_name, info)  # 新增常见宕机，同步信息
        else:
            push_report(dir_name, self.ErrorCodeMsg, ''.join(stack_content))  # 新增宕机，同步信息，附带stack，@所有人
        self.dump_type = None
        self.stack_content = []

    def MonitorFolder(self):  # 监控文件夹
        before = dict([(f, None) for f in os.listdir(self.path_to_watch)])
        while 1:
            time.sleep(3)
            try:
                after = dict([(f, None) for f in os.listdir(self.path_to_watch)])
                added = [f for f in after if not f in before]
                if added:
                    many_added = []
                    for i in added:
                        current_time = time.strftime("%Y-%m-%d", time.localtime())
                        file_revise_time = get_file_revise_time(os.path.join(self.path_to_watch, i))
                        if current_time == file_revise_time:
                            many_added.append(i)

                    if many_added:  # 对新增加的宕机文件夹做处理
                        for add in many_added:
                            dir_name = os.path.join(self.path_to_watch, add)
                            self.log.info(f"新增宕机：{dir_name}")
                            time.sleep(180)  # 等待生成解析文件
                            analyze_file = os.path.join(dir_name, 'analyze.txt')

                            if not self.wait_for_close(analyze_file):  # 判断解析文件是否存在并且已经解析完成
                                continue

                            self.check_analyze_stack(analyze_file)  # 检查并获取崩溃堆栈

                            if self.dump_type == "Curl_verify_windows_version宕机":  # 单独处理curl宕机
                                add = "Curl_" + add
                                new_dir_name = os.path.join(self.path_to_watch, add)
                                os.rename(dir_name, new_dir_name)  # 修改文件夹名字
                                dir_name = new_dir_name
                                after[add] = None

                            self.send_msg(dir_name)  # 发送消息到群里
                before = after
            except Exception as e:
                info = traceback.format_exc()
                self.log.error(info)
                if type(e) is WindowsError:
                    error_code = int(re.findall(r"\[Error (\w+)]", str(e))[0])
                    codemap = {
                        1: '不正确的函数。',
                        2: '系统无法找到指定的文件。',
                        3: '系统无法找到指定的目录。',
                        4: '系统无法打开该文件。',
                        5: '访问被拒绝。',
                        19: '介质写入受保护',
                        53: '找不到网络路径',
                        64: '指定的网络名不再可用。',
                        65: '网络访问被拒绝。'
                    }
                    warn_info = machine_get_IPAddress() + (
                        "%s: 共享访问出错，请处理： \n%s") % (MACHINE_ID, codemap[error_code])
                    push_warn_info(warn_info)

    def run_local(self, dic_args):  # 用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典
        self.log.info(u'监控bvt宕机:{}'.format(self.path_to_watch))
        self.MonitorFolder()


if __name__ == '__main__':
    path_to_watch = r"\\10.11.181.242\FileShare\DumpAnalyse"  # 监控地址
    ob = CaseBVTDumpMonitor(path_to_watch)
    ob.run_from_IQB()
