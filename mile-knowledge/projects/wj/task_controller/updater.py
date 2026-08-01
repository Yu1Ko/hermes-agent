# -*- coding: utf-8 -*-
"""
程序更新器 - 单脚本方案

功能:
1. 从 HTTP 服务器下载 dicFileMD5.json 获取文件 MD5 列表
2. 对比本地文件 MD5，找出需要更新的文件
3. Kill 目标进程解除文件占用
4. 下载更新文件
5. 重新启动目标程序

依赖: BaseToolFunc.py (需放在同目录)
"""

import sys
import os
import time
import configparser

# 导入 BaseToolFunc 中的函数
from BaseToolFunc_py2exe import (
    filecontrol_downloadFileByHttp,
    md5File,
    win32_kill_process,
    win32_runExe_no_wait,
    JsonLoad
)

# ==================== 配置区 ====================
_DEFAULT_BASE_URL = 'http://10.11.80.122:8299/static'
PROCESS_NAME = 'main_py2exe.exe'
KILL_WAIT_SEC = 2
# ================================================


def get_script_dir():
    """获取脚本所在目录（支持 pyinstaller 打包后的 exe）"""
    if getattr(sys, 'frozen', False):
        return os.path.dirname(os.path.realpath(sys.executable))
    else:
        return os.path.dirname(os.path.abspath(__file__))


def load_base_url(script_dir):
    """从 ClientConfig.ini 读取 BASE_URL，如果没有则使用默认值"""
    ini_path = os.path.join(script_dir, 'ClientConfig.ini')
    if os.path.exists(ini_path):
        cfg = configparser.ConfigParser()
        cfg.read(ini_path, encoding='utf-8')
        if cfg.has_option('Update', 'BASE_URL'):
            url = cfg.get('Update', 'BASE_URL').strip()
            print(f'[INFO] 从 ClientConfig.ini 读取 BASE_URL: {url}')
            return url
    print(f'[INFO] 使用默认 BASE_URL: {_DEFAULT_BASE_URL}')
    return _DEFAULT_BASE_URL


def get_script_dir():
    """获取脚本所在目录（支持 pyinstaller 打包后的 exe）"""
    if getattr(sys, 'frozen', False):
        return os.path.dirname(os.path.realpath(sys.executable))
    else:
        return os.path.dirname(os.path.abspath(__file__))


def download_md5_json(temp_dir, md5_json_url):
    """下载 MD5 索引文件到临时目录"""
    temp_md5_path = os.path.join(temp_dir, 'dicFileMD5.json')
    print(f'[INFO] 正在下载 MD5 索引: {md5_json_url}')
    status = filecontrol_downloadFileByHttp(md5_json_url, temp_md5_path)
    if status != 200:
        raise Exception(f'下载 MD5 索引失败，HTTP 状态码: {status}')
    print(f'[INFO] MD5 索引下载成功: {temp_md5_path}')
    return temp_md5_path


def load_md5_dict(md5_file_path):
    """加载 MD5 字典"""
    with open(md5_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    return JsonLoad(content)


def get_files_to_update(script_dir, server_md5_dict):
    """对比本地和服务器 MD5，返回需要更新的文件列表"""
    files_to_update = []
    
    for filename, server_md5 in server_md5_dict.items():
        local_path = os.path.join(script_dir, filename)
        
        # 本地文件不存在，需要更新
        if not os.path.exists(local_path):
            print(f'[INFO] 本地文件不存在，需要更新: {filename}')
            files_to_update.append(filename)
            continue
        
        # 本地文件存在，对比 MD5
        local_md5 = md5File(local_path)
        if local_md5 != server_md5:
            print(f'[INFO] MD5 不匹配，需要更新: {filename} (本地: {local_md5}, 服务器: {server_md5})')
            files_to_update.append(filename)
        else:
            print(f'[INFO] MD5 匹配，跳过: {filename}')
    
    return files_to_update


def download_file(filename, script_dir, file_download_url):
    """下载单个文件"""
    file_url = f'{file_download_url}/{filename}'
    local_path = os.path.join(script_dir, filename)
    print(f'[INFO] 正在下载: {file_url} -> {local_path}')
    status = filecontrol_downloadFileByHttp(file_url, local_path)
    if status != 200:
        raise Exception(f'下载文件失败: {filename}, HTTP 状态码: {status}')
    print(f'[INFO] 下载成功: {filename}')


def main():
    print('=' * 50)
    print('程序更新器启动')
    print('=' * 50)
    
    script_dir = get_script_dir()
    print(f'[INFO] 工作目录: {script_dir}')
    
    # 读取 BASE_URL（优先从 ClientConfig.ini，否则用默认值）
    base_url = load_base_url(script_dir)
    md5_json_url = base_url + '/dicFileMD5.json'
    file_download_url = base_url + '/case'
    
    # 创建临时目录
    temp_dir = os.path.join(script_dir, 'temp_update')
    os.makedirs(temp_dir, exist_ok=True)
    
    try:
        # 步骤 1: 下载 MD5 索引
        md5_file_path = download_md5_json(temp_dir, md5_json_url)
        server_md5_dict = load_md5_dict(md5_file_path)
        print(f'[INFO] 服务器文件列表: {list(server_md5_dict.keys())}')
        
        # 步骤 2: 对比 MD5，找出需要更新的文件
        files_to_update = get_files_to_update(script_dir, server_md5_dict)
        
        if not files_to_update:
            print('[INFO] 所有文件都是最新的，无需更新')
            # 启动目标程序
            exe_path = os.path.join(script_dir, PROCESS_NAME)
            print(f'[INFO] 启动程序: {exe_path}')
            win32_runExe_no_wait(PROCESS_NAME, script_dir)
            print('[INFO] 程序已启动，更新器退出')
            return
        
        print(f'[INFO] 需要更新的文件: {files_to_update}')
        
        # 步骤 3: Kill 目标进程
        print(f'[INFO] 正在终止进程: {PROCESS_NAME}')
        win32_kill_process(PROCESS_NAME)
        print(f'[INFO] 进程已终止，等待 {KILL_WAIT_SEC} 秒...')
        time.sleep(KILL_WAIT_SEC)
        
        # 步骤 4: 下载更新文件
        print('[INFO] 开始下载更新文件...')
        for filename in files_to_update:
            download_file(filename, script_dir, file_download_url)
        print('[INFO] 所有文件更新完成')
        
        # 步骤 5: 重新启动目标程序
        exe_path = os.path.join(script_dir, PROCESS_NAME)
        print(f'[INFO] 启动程序: {exe_path}')
        win32_runExe_no_wait(PROCESS_NAME, script_dir)
        print('[INFO] 程序已启动，更新器退出')
        
    except Exception as e:
        print(f'[ERROR] 更新失败: {str(e)}')
        raise
    finally:
        # 清理临时文件
        try:
            import shutil
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
                print(f'[INFO] 清理临时目录: {temp_dir}')
        except Exception as e:
            print(f'[WARN] 清理临时目录失败: {str(e)}')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'[FATAL] 程序异常终止: {str(e)}')
        sys.exit(1)