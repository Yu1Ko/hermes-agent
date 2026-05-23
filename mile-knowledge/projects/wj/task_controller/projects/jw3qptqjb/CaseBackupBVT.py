# -*- coding: utf-8 -*- 
from CaseCommon import *
from BaseToolFunc import *
import logging
import traceback
import datetime

class CaseBackupBVT(CaseCommon):
    def __init__(self):
        super().__init__()

    def run_local(self,dic_args):
        try:
            #清老备份
            szBasePath = r'\\10.11.80.192\xsjqcres\mali\BACK\JX3BVT'
            for folder in os.listdir(szBasePath):
                dateFolder = datetime.datetime.strptime(folder, '%Y-%m-%d')
                dateToday = datetime.datetime.now()
                dateToRemove = dateToday - datetime.timedelta(days=15)
                if dateFolder < dateToRemove:
                    to_del_folder = szBasePath + '/' + folder
                    filecontrol_deleteFileOrFolder(to_del_folder)
                    
            #新备份
            szDate = date_get_szToday()
            szFoldernameBack = '{}'.format(szDate)
            src = r'\\10.11.68.11\FileShare\JX3BVT'
            dst = r'\\10.11.80.192\xsjqcres\mali\BACK\JX3BVT\{}'.format(szFoldernameBack)
            filecontrol_copyFileOrFolder(src, dst)

            

            
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

if __name__ == '__main__':
    oob = CaseBackupBVT()
    oob.run_from_IQB()

