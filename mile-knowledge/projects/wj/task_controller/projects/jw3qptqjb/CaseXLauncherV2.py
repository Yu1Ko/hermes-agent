# ver:3.6

from BaseToolFunc import *
from CaseJX3Client import *
import requests


class CaseUpdatePakV4Client2(CaseJX3Client):
    def __init__(self):
        super().__init__()

    def check_dic_args(self, dic_args):
        super().check_dic_args(dic_args)
        # if 'reconize_server' not in dic_args:
        #     raise Exception('dic_arg:reconize_server need set')


    # 截图工具
    def window_capture2(self, filename: str):
        hwnd = win32gui.FindWindow('Qt5152QWindowIcon', None)  # 窗口的编号，0号表示当前活跃窗口
        # 根据窗口句柄获取窗口的设备上下文DC（Divice Context）
        hwndDC = win32gui.GetWindowDC(hwnd)
        # 根据窗口的DC获取mfcDC
        mfcDC = win32ui.CreateDCFromHandle(hwndDC)
        # mfcDC创建可兼容的DC
        saveDC = mfcDC.CreateCompatibleDC()
        # 创建bigmap准备保存图片
        saveBitMap = win32ui.CreateBitmap()
        left, top, right, bot = win32gui.GetWindowRect(hwnd)
        print(left, top, right, bot)
        w = right - left
        h = bot - top
        # 为bitmap开辟空间
        saveBitMap.CreateCompatibleBitmap(mfcDC, int(w / 4.5), int(h / 6))
        # 高度saveDC，将截图保存到saveBitmap中
        saveDC.SelectObject(saveBitMap)
        # 截取从左上角（0，0）长宽为（w，h）的图片
        saveDC.BitBlt((0, 0), (int(w / 2), int(h / 4.5)), mfcDC, (int(w - w / 3.2), int(h - h / 6)), win32con.SRCCOPY)
        saveBitMap.SaveBitmapFile(saveDC, filename)
        # bmp2jpg(filename)
        # 释放内存，不然会造成资源泄漏
        win32gui.DeleteObject(saveBitMap.GetHandle())
        saveDC.DeleteDC()

    # 图像转为字节流工具
    def getImgByte(self, mypath):
        with open(mypath, 'rb') as f:
            img_byte = base64.b64encode(f.read())
        img_str = img_byte.decode('ascii')
        return img_str

    # 图像识别工具
    def recognize(self, dic_args):
        # 截图
        self.window_capture2("img.jpg")
        # 由其他机器提供EasyOCR服务，识别图片中的文字
        server_path = 'http://10.11.179.106:5000/up_image' #dic_args['reconize_server']

        img_set = self.getImgByte("img.jpg")
        post_json = json.dumps({'img_test': img_set})
        try:
            r = requests.post(server_path, data=post_json)
            return r.text
        except:
            info = traceback.format_exc()
            logging.warning(info)
            logging.error('EasyOCR网络服务异常')

    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        # win32_SetRegForPakv4Update(self.BASE_PATH, self.bEXP)
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('SeasunGame.exe')

        # 查找并运行客户端
        self.setClientPath(dic_args['clientType'])  # 指定客户端位
        self.loadDataFromLocalConfig(dic_args)
        self.BASE_PATH = r'f:/SeasunGame'
        if not os.path.exists(self.BASE_PATH):
            disks = psutil.disk_partitions()
            for disk in disks:
                path = disk.mountpoint + 'SeasunGame'
                if os.path.exists(path):
                    self.BASE_PATH = path
                    break
        exe = os.path.join(self.BASE_PATH, 'SeasunGame.exe')
        pp = win32_runExe_no_wait(exe, self.BASE_PATH)
        self.clientPID = pp.pid
        while not win32_findProcessByName('SeasunGame.exe'):
            time.sleep(2)
        time.sleep(10)
        self.process_threads_activeWindow()
        # 开始识别过程
        hwnd = win32gui.FindWindow('Qt5152QWindowIcon', None)
        while not hwnd:
            time.sleep(2)
            hwnd = win32gui.FindWindow('Qt5152QWindowIcon', None)
        time.sleep(10)

        # 开始识别文字(5分钟/次检查)
        nLastTime = time.time()
        # 从IQB平台输入关键字和输出对应的语句
        # key_word = dic_args['keyword']
        # key_word_answer = dic_args['keyword_answer']
        while True:
            result = self.recognize(dic_args)
            if result is None:
                time.sleep(600)
                continue
            if '更新中' in result:
                send_Subscriber_msg(machine_get_IPAddress(), f'【{self.clientType}】 Pakv4版本正在更新')
                # todo  写log，没大事不要发飞书。
                # 更新持续了半个小时
                if time.time() - nLastTime > 1800:
                    MachineID = self.strMachineName
                    send_Subscriber_msg(machine_get_IPAddress(), '%s: 半小时还在更新pakv4客户端,注意查看' % MachineID)
                    #todo 写log，只发飞书，要是漏看消息了，想通过log查问题都不知道发生了啥。
            elif '开始游戏' in result:
                send_Subscriber_msg(machine_get_IPAddress(), f'【{self.clientType}】 Pakv4版本已完成更新')
                break
            # 后续发现新状态可以在这里添加
            # elif "关键词" in result:
            #     send_Subscriber_msg(machine_get_IPAddress(), f'【{self.clientType}】 Pakv4版本')
            #     break
            else:
                info = 'XLauncherV2更新按钮出现了意外内容：{}'.format(result)
                self.log.error(info)
            time.sleep(10)

        # 非PAK客户端
        if not self.clientType == 'PAK':
            strpakUpdateTime = open(self.CLIENT_PATH + '/version.cfg', 'r').readlines()[1]
            listDate = re.findall(r'\w+|:', time.strftime("%a %b %d %H:%M:%S %Y", time.localtime()))
            del listDate[3:-1]  # 只保留日期,不要时间
            listpakUpdateTime = re.findall(r'\w+|:', strpakUpdateTime)
            listpakUpdateTime.remove('CST')  # 保持格式一致，所以去掉CST标识
            del listpakUpdateTime[3:-1]
            self.log.info(strpakUpdateTime)
            self.log.info(listDate)
            if listDate != listpakUpdateTime:
                if self.updateFlag:
                    send_Subscriber_msg(
                        machine_get_IPAddress(),
                        ('%s: %s Pakv4版本无更新, 稍后将每5分钟次尝试一次更新。' % (self.strMachineName, self.clientType)))
                    self.updateFlag = False
                time.sleep(300)
                self.run_local(dic_args)

        win32_kill_process('SeasunGame.exe')


if __name__ == '__main__':
    oob = CaseUpdatePakV4Client2()
    oob.run_from_IQB()
