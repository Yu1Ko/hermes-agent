# -*- coding: utf-8 -*-
import re
import time

import CaseCommon
from ftplib import FTP
from datetime import date, timedelta
from BaseToolFunc import *
from CaseJX3Client import *

class CaseClearCaseFile(CaseJX3Client):
    def __init__(self):
        super().__init__()


    def run_local(self, dic_args):
        self.check_dic_args(dic_args)
        self.loadDataFromLocalConfig(dic_args)
        list_folderName=['mui','RunMapResult']
        for strFolderName in list_folderName:
            filecontrol_deleteFileOrFolder(f'{self.CLIENT_PATH}/{strFolderName}',self.deviceId,self.package)

if __name__ == '__main__':
    oob = CaseClearCaseFile()
    oob.run_from_IQB()
    '''
    sf = ScanFiles('10.11.80.122', 21, "ftp1", "ftp+123", '/XGame-apk')
    sf.launch()
    sf.ini()
    sf.arrange_File()
    print(sf.dic_arrangedFileInfo)
'''
