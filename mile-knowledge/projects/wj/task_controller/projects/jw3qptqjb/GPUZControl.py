# -*- coding: utf-8 -*-
# python 2.7
# author:郭智诚


import win32gui
import win32con
import win32api


class GPUZuiControl():
    def __init__(self,str_WindowText):
        # 初始化
        # 根据标题使用 FindWindow 获取主窗口句柄
        self.main_win_handle = win32gui.FindWindow(None, str_WindowText)
        # 根据类名使用 FindWindowEx 获取复选框子窗口句柄
        self.combobox_handle = win32gui.FindWindowEx(self.main_win_handle, None, 'ComboBox', None)
        # 使用 CB_GETCOUNT 消息统计 ComboBox 子项数，即获取显卡数
        self.box_count = win32gui.SendMessage(self.combobox_handle, win32con.CB_GETCOUNT, 0, 0)
        # 刷新按钮句柄置空
        self.refresh_button_handle = None
        # 刷新按钮标识符定义 (HEX)0x040D (DEC)1037
        self.refresh_button_ctrl_ID = 1037
        # 获取刷新按钮句柄函数
        self.get_refresh_button_handle()

    def enum_child_func_callback(self, _hwnd, _l_param):
        # 使用回调函数枚举子窗口句柄，通过比对标识符找到刷新按钮
        _ctrl_ID = win32gui.GetDlgCtrlID(_hwnd)
        if _ctrl_ID == self.refresh_button_ctrl_ID:
            self.refresh_button_handle = _hwnd
            return False
        return True

    def get_refresh_button_handle(self):
        # 使用回调函数枚举子窗口句柄，通过比对标识符找到刷新按钮
        win32gui.EnumChildWindows(self.main_win_handle, self.enum_child_func_callback, None)
        if self.refresh_button_handle is not None:
            print ('Find button handle!\n')
        else:
            print ('Failed to find button handle!\n')

    # 获取可选择的显卡列表
    def get_graphics_card_info(self):
        # 使用 for 循环枚举显卡数，具体原理见下方注释
        _card_name_list = []
        for i1 in range(self.box_count):
            # 通过 CB_SETCURSEL 切换显卡字符串，索引参数使用 for 循环枚举
            win32gui.SendMessage(self.combobox_handle, win32con.CB_SETCURSEL, i1, 0)
            buf_size = win32gui.SendMessage(self.combobox_handle, win32con.WM_GETTEXTLENGTH, 0, 0) +1  # 要加上截尾的字节
            buff = bytearray(buf_size)
            buf_addr = id(buff)
            str_buffer = win32gui.PyGetMemory(buf_addr, buf_size)  # 生成buffer对象
            # 使用 WM_GETTEXT 获取字符串
            win32gui.SendMessage(self.combobox_handle, win32con.WM_GETTEXT, buf_size, str_buffer)  # 获取buffer
            address, length = win32gui.PyGetBufferAddressAndLen(str_buffer)
            card_name = win32gui.PyGetString(address, length - 1)
            # card_name = str(str_buffer[:-1], encoding='utf8')
            # 将显卡字符串(显卡名)加入显卡 list 中
            _card_name_list.append(card_name)
        # 返回临时的显卡 list
        return _card_name_list

    # 设置选择哪个显卡   参数是在显卡列表里的位置下标
    def change_graphics_card(self, _card_index):
        # 使用 CB_SETCURSEL 改变 ComboBox 子项
        win32gui.SendMessage(self.combobox_handle, win32con.CB_SETCURSEL, _card_index, 0)
        _w_parm = win32con.BN_CLICKED
        _w_parm <<= 16
        _w_parm |= 1037
        # 使用 BN_CLICKED 对刷新按钮发送通知
        # 模拟按钮被点击，刷新显卡数据
        win32gui.SendMessage(self.main_win_handle, win32con.WM_COMMAND, _w_parm, self.refresh_button_handle)

# 写注册表，安装gpuz
def InstalledGPUZ():
    try:
        key = win32api.RegCreateKey(win32con.HKEY_CURRENT_USER, "SOFTWARE\\techPowerUp\\GPU-Z")
        # key=win32api.RegOpenKey(win32con.HKEY_CURRENT_USER,"SOFTWARE\\techPowerUp\\GPU-Z",0,win32con.KEY_SET_VALUE)
        win32api.RegSetValueEx(key, 'Install_Dir', 0, win32con.REG_SZ, 'no')
        # win32api.RegSetValueEx(key,'LastCardIndex',0,win32con.REG_SZ,'1')
        win32api.RegSetValueEx(key, 'NextCheck', 0, win32con.REG_SZ, '0')
        win32api.RegSetValueEx(key, 'WindowPos', 0, win32con.REG_SZ, '837,277')
        win32api.RegCloseKey(key)
    except Exception as e:
        print(e)

# 关闭检查站点安全证书的吊销信息显示
def closeCheckCertificate():
    key = win32api.RegOpenKey(win32con.HKEY_CURRENT_USER,
                              "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WinTrust\\Trust Providers\\Software Publishing",
                              0, win32con.KEY_SET_VALUE)
    win32api.RegSetValueEx(key, 'State', 0, win32con.REG_SZ, '23e00')
    win32api.RegCloseKey(key)

    key = win32api.RegOpenKey(win32con.HKEY_CURRENT_USER,
                              "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", 0,
                              win32con.KEY_SET_VALUE)
    win32api.RegSetValueEx(key, 'CertificateRevocation', 0, win32con.REG_SZ, '0')
    win32api.RegSetValueEx(key, 'SecureProtocols', 0, win32con.REG_SZ, '0a0')
    win32api.RegCloseKey(key)

def GPUZ_configBeforeRun():
    InstalledGPUZ()
    closeCheckCertificate()

def GPUZ_selectHighVideoCard():
    # 初始化设置gpu-z的标题  ，原因是因为版本不同，标题上的版本号也不同
    gpu_ui_control = GPUZuiControl('TechPowerUp GPU-Z 2.38.0')

    # 获取可选择的显卡列表，返回显卡名的列表
    card_name_list = gpu_ui_control.get_graphics_card_info()
    # print card_name_list

    if len(card_name_list) <= 1:
        return
    for i in range(len(card_name_list)):
        if 'NVIDIA' in card_name_list[i]:
            # 设置选择哪个显卡   参数是在显卡列表里的位置下标
            gpu_ui_control.change_graphics_card(i)

if __name__ == '__main__':
    # 初始化设置gpu-z的标题  ，原因是因为版本不同，标题上的版本号也不同
    gpu_ui_control = GPUZuiControl('TechPowerUp GPU-Z 2.38.0')
    # 获取可选择的显卡列表，返回显卡名的列表
    card_name_list = gpu_ui_control.get_graphics_card_info()

    print (card_name_list, type(card_name_list[0]))
    # 设置选择哪个显卡   参数是在显卡列表里的位置下标
    gpu_ui_control.change_graphics_card(0)
    # GPUZ_selectHighVideoCard()

