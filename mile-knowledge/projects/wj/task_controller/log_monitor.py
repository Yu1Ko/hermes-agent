import sys
import threading
import time

from pyfeishu import FeiShutalkChatbot


class log_monitor_thread(threading.Thread):
    def __init__(self, target_func,  *args, **kwargs):
        super(log_monitor_thread, self).__init__(*args, **kwargs)
        self._stop_event = threading.Event()
        self.target_func = target_func

    def run(self):
        self.target_func()

    def stop(self):
        self._stop_event.set()

    def stopped(self):
        return self._stop_event.is_set()

class log_monitor:
    def __init__(self, buff_length = 5, timeout = 300):
        self.buff = []
        self.console = sys.stdout
        self.buff_length = buff_length
        self.last_update = time.time()
        self.timeout = timeout
        self.notice = False
        self.running = False
        self.thread = None
        self.info = {}


        sys.stdout = self

    def write(self, output_str):

        # 更新时间
        self.last_update = time.time()
        self.notice = False

        if(len(self.buff) == self.buff_length):
            self.buff.pop(0)

        if len(output_str.strip()) > 0:
            self.buff.append(output_str)

        # 使用控制台输出打印 log
        self.console.write(output_str)

    def start(self, info = {}):
        self.info = info
        self.last_update = time.time()
        self.running = True
        self.thread = log_monitor_thread(self.check)
        self.thread.start()

    def stop(self):
        self.running = False
        time.sleep(2)
        self.thread.stop()
        self.thread = None

    def check(self):
        while True:
            if not self.running:
                break

            if not self.notice and time.time() - self.last_update > self.timeout:
                error_info = f"log 超过 {self.timeout} 秒没有更新，最近 {self.buff_length} 条 log 为：{self.buff}，额外信息：{self.info}"
                self.console.write(error_info + "\n")
                FeiShutalkChatbot().send_text(error_info)
                self.notice = True

            time.sleep(1)

    def flush(self):
        self.buff=[]
