# -*- coding: utf-8 -*-

from CaseJX3Client import *
from BaseToolFunc import *
#
import pymongo
class CaseLocalCachedShaderUpload(CaseJX3Client):
    def __init__(self):
        super(CaseLocalCachedShaderUpload, self).__init__()

    def saveShaderInfo(self):
        szCachedShadersPath=os.path.join(self.CLIENT_PATH, 'CachedShaders')
        if not os.path.exists(szCachedShadersPath):
            return
        file_shaderfiles = os.listdir(szCachedShadersPath)
        myclient = pymongo.MongoClient("mongodb://10.11.80.122:27017/")
        mydb = myclient["CachedShadersInfo"]
        mycol = mydb["localShadersInfo"]
        for shaderfile in file_shaderfiles:
            if shaderfile.rfind('ini') == -1:
                continue
            filePath = os.path.join(szCachedShadersPath, shaderfile)
            szFileCreateDate = time.strftime('%Y-%m-%d', time.localtime(os.path.getctime(filePath)))
            szName = shaderfile.split('}')[0][1:]
            szInfo =szName  + ':' + szFileCreateDate + ':'
            szContent=''
            with open(filePath, 'rb') as f:
                while True:
                    line = f.readline()
                    if line == b'':
                        break
                    try:
                        line = str(line, encoding='gbk')
                    except:
                        line = str(line)
                    szContent=szContent+line
            szInfo = szInfo + szContent
            dic_data = {"shaderName": szName, "shaderCreateDate": szFileCreateDate, "shaderContent": szContent,
                        "shaderInfo": szInfo}
            try:
                if not mycol.find_one(dic_data):
                    mycol.insert_one(dic_data)
                filecontrol_deleteFileOrFolder(filePath)
                filecontrol_deleteFileOrFolder(os.path.join(szCachedShadersPath, shaderfile.split('.')[0]+'.bin'))
            except:
                str_notice="数据插入异常"
                IPv4 = machine_get_IPAddress()
                send_Subscriber_msg(IPv4, str_notice)
        filecontrol_deleteFileOrFolder(szCachedShadersPath)
        IPv4 = machine_get_IPAddress()
        str_notice = "编译了shader"
        send_Subscriber_msg(IPv4, str_notice)



    def run_local(self, dic_args):
        win32_kill_process('Xlauncher.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('JX3ClientX64.exe')
        self.check_dic_args(dic_args)
        self.saveShaderInfo()


    def teardown(self, dic_args):
        win32_kill_process('JX3ClientX64.exe')
        win32_kill_process('KGPK4_StreamDownloaderX64.exe')
        win32_kill_process('XLauncher.exe')
        win32_kill_process('XLauncherKernel.exe')
        win32_kill_process('XLauncherKernelClassic.exe')
        win32_kill_process('svn.exe')
        pass

if __name__ == '__main__':
    oob = CaseLocalCachedShaderUpload()
    oob.run_from_IQB()

