import sys
import threading
import datetime
import inspect

# 添加锁
rlock = threading.RLock()

class FakeOut (object):

    def __init__(self, log_lock):
        # 储存数据流键值对
        self.Output_stream=dict()
        self.origin = sys.stdout
        self.log_lock = log_lock
        self.default_out = None

    def add_output(self,ident,File_devices):

        self.Output_stream[ident]=File_devices
        if self.default_out is None:
            self.default_out = File_devices

        return True

    def write(self,s):
        #加锁

        # haslock = rlock.acquire(timeout=10)
        with self.log_lock:
            try:
                out_stream = self.default_out
                if threading.current_thread().ident in self.Output_stream:
                    out_stream = self.Output_stream[threading.current_thread().ident]
                if out_stream is not None:
                    #输出文件
                    out_stream.write(s)
                    #刷新文件
                    out_stream.flush()
            except:
                pass
        # if haslock:
        #     try:
        #         #输出文件
        #         self.Output_stream[threading.current_thread().ident].write(s)
        #         #刷新文件
        #         self.Output_stream[threading.current_thread().ident].flush()
        #     except:
        #         pass
        #     #解锁
        # try:
        #     rlock.release()
        # except:
        #     pass

    def flush(self):
        #刷新文件
        out_stream = self.default_out
        if threading.current_thread().ident in self.Output_stream:
            out_stream = self.Output_stream[threading.current_thread().ident]
        if out_stream is not None:
            out_stream.flush()

    def clear_current_output(self):
        """
        清空当前线程所绑定的输出文件内容。
        """
        with self.log_lock:
            ident = threading.current_thread().ident
            out_stream = self.Output_stream.get(ident, self.default_out)
            if out_stream and hasattr(out_stream, 'truncate'):
                try:
                    out_stream.seek(0)
                    out_stream.truncate(0)
                except Exception as e:
                    pass

    def clear_all_outputs(self):
        """
        清空所有已绑定的输出文件内容。
        """
        with self.log_lock:
            for out_stream in set(self.Output_stream.values()):
                if out_stream and hasattr(out_stream, 'truncate'):
                    try:
                        out_stream.seek(0)
                        out_stream.truncate(0)
                    except Exception:
                        pass

    def fileno(self):
        return self.origin.fileno()
