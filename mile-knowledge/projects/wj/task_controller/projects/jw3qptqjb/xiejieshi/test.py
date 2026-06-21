import datetime

def wait(self, dic_args):
    while True:
        # 获取当前时间
        current_time = datetime.datetime.today()
        # 结束时间
        end_time_str = dic_args.get("end_time")
        if not end_time_str:
            self.log.info("end_time 参数未提供")
            return
        end_time = datetime.datetime.strptime(end_time_str, "%H:%M:%S").time()
        
        # 打印当前时间
        print(f"当前时间: {current_time}")
        self.log.info(f"当前时间: {current_time}")
        
        # 
        if current_time.time() > end_time:
            print(f"当前时间已超过{end_time_str}，结束循环。")
            self.log.info(f"当前时间已超过{end_time_str}，结束循环。")
            break

wait(1,{"end_time": "16:00:00"})