# -*- coding: utf-8 -*- 
from CaseCommon import *
from BaseToolFunc import *
import logging
import traceback


class CaseBackupMysql(CaseCommon):
    def __init__(self):
        super().__init__()

    def delExpireFiles(self, path):
        # 删除掉过期的文件，期限是15天
        del_time = time.time() - 3600 * 24 * 15
        for root, dirs, files in os.walk(path):
            for i in files:
                fileName = root + "\\" + i
                if os.path.getmtime(fileName) < del_time:
                    try:
                        if os.path.isfile(fileName):
                            os.remove(fileName)
                    except Exception as error:
                        print (error)

    def run_local(self,dic_args):
        try:
            szDate = date_get_szToday()
            szFilenameBack = 'MySqlBackUp_{}.sql'.format(szDate)
            cmd = 'mysqldump -uroot -pking+5688 --all-databases > d:/MysqlBackupLocal/{}'.format(szFilenameBack)
            os.system(cmd)
            src = 'd:/MysqlBackupLocal/' + szFilenameBack
            dst = r'\\10.11.80.192\xsjqcres\mali\BACK\Mysql\{}'.format(szFilenameBack)
            filecontrol_copyFileOrFolder(src, dst)

            self.delExpireFiles('d:/MysqlBackupLocal/')
            self.delExpireFiles(r'\\10.11.80.192\xsjqcres\mali\BACK\Mysql')
            
            #备份AUTO_BVT数据库
            szFilenameBack = 'Bvt_atuoData_{}.db'.format(szDate)
            src = 'd:/AUTO_BVT/Bvt_atuoData.db'
            dst = r'\\10.11.80.192\xsjqcres\mali\BACK\AUTO_BVT_DB\{}'.format(szFilenameBack)
            filecontrol_copyFileOrFolder(src, dst)
            self.delExpireFiles(r'\\10.11.80.192\xsjqcres\mali\BACK\AUTO_BVT_DB')
            
            
        except Exception as e:
            info = traceback.format_exc()
            self.log.error(info)

if __name__ == '__main__':
    oob = CaseBackupMysql()
    oob.run_from_IQB()

