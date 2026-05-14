# - *- coding: utf- 8 - *-


import os
import json
from urllib.request import urlopen
from urllib.error import URLError, HTTPError
from urllib.parse import quote
import hashlib
import traceback
from extensions import logger


def filecontrol_downloadFileByHttp(sUrl: str, sStorePath: str):
    """下载单个文件, sUrl-> 服务器文件URL，sStorePath->保存路径(路径携带文件名)"""
    try:
        # 使用官方库urllib的urlopen发送GET请求
        with urlopen(sUrl) as response:
            # 获取响应状态码
            status_code = response.getcode()

            if status_code == 200:
                # 读取文件内容
                bContent = response.read()
            else:
                return status_code
    except HTTPError as e:
        # 处理HTTP错误（如404, 500等）
        return e.code
    except URLError as e:
        # 处理URL错误（如无法连接）
        # 返回一个负数表示非HTTP错误
        return -1
    except Exception as e:
        # 处理其他异常
        return -2

    # 处理保存路径
    sStorePath = sStorePath.replace('\\', '/')
    dir_temp = sStorePath.rsplit('/', 1)[0]

    # 创建目录（如果不存在）
    if not os.path.exists(dir_temp):
        os.makedirs(dir_temp)

    # 保存文件
    with open(sStorePath, 'wb') as f:
        f.write(bContent)

    return status_code

def getListAllFiles(case_path, filter=None):
    listAllFiles = []
    g = os.walk(case_path)
    for path, dir_list, file_list in g:
        for file_name in file_list:
            file_path = os.path.join(path, file_name)
            if filter and filter in file_path:
                continue
            listAllFiles.append(file_path)
    return listAllFiles

def md5File(filepath):
    md5_hash = hashlib.md5
    with open(filepath, 'rb') as f:
        data = f.read()
        return md5_hash(data).hexdigest()


HTTP_PREFIX = 'http://10.11.80.122:8199/FilesServerFolder'

class FileSyncModel:
    def __init__(self, target_folder):
        dicFileMD5_http = os.path.join(HTTP_PREFIX, 'dicFileMD5.json').replace('\\', '/')
        filecontrol_downloadFileByHttp(dicFileMD5_http, './dicFileMD5.json')
        self.dicFileMD5 = json.load(open('dicFileMD5.json', 'r', encoding='utf-8'))
        self.target_folder = target_folder
        self.log = logger

    def file_sync_model(self):
        dicFileMD5 = self.dicFileMD5
        target_folder = self.target_folder

        listAllFilesLocal = getListAllFiles(target_folder)
        dicFileMD5_local = {}
        for file_path_local in listAllFilesLocal:
            key_local = file_path_local.split(target_folder)[1].strip('\\').strip('/').replace('\\', '/')
            dicFileMD5_local[key_local] = md5File(file_path_local)

        for key in dicFileMD5:
            md5_http = dicFileMD5[key]
            if key not in dicFileMD5_local:
                encoded_key = quote(key, safe='/')
                download_file_path = os.path.join(HTTP_PREFIX, 'case', encoded_key).replace('\\', '/')
                try:
                    filecontrol_downloadFileByHttp(download_file_path, os.path.join(target_folder, key))
                    dicFileMD5_local[key] = md5_http
                except:
                    self.log.info(f'download_file_path:{download_file_path}')
                    info = traceback.format_exc()
                    self.log.error(info)

                continue
            if md5_http != dicFileMD5_local[key]:
                download_file_path = os.path.join(HTTP_PREFIX, 'case', key).replace('\\', '/')
                try:
                    filecontrol_downloadFileByHttp(download_file_path, os.path.join(target_folder, key))
                    dicFileMD5_local[key] = md5_http
                except:
                    self.log.info(f'download_file_path:{download_file_path}')
                    info = traceback.format_exc()
                    self.log.error(info)
                continue



if __name__ == '__main__':
    FILE_FOLDER_local = 'FilesServerFolder_local'
    obj = FileSyncModel(FILE_FOLDER_local)
    obj.file_sync_model()


