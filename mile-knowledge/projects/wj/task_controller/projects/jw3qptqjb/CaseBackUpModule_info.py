# -*- coding: utf-8 -*-
from CaseCommon import *


# 此用例每天6点更新一次
class CaseBackUpModule_info(CaseCommon):

    def __init__(self):
        super().__init__()

    def run_local(self, dic_args):
        while 1:
            time.sleep(1)

            #判断时间
            H = int(time.strftime("%H", time.localtime()))
            if (H < 6):
                continue
            # self.log.info('CaseBackUpModule_info work start')
            #检查版本
            inifile = SERVER_MAINSCRIPT + '\\updateInfo.ini'
            bUpHd = False
            bUpHdOuter = False
            bUpClassic = False
            bUpX3d = False
            strDateIni = ini_get('module_info', 'hd', inifile)
            if date_get_szToday() != strDateIni:
                bUpHd = True
            strDateIni = ini_get('module_info', 'classic', inifile)
            if date_get_szToday() != strDateIni:
                bUpClassic = True
            strDateIni = ini_get('module_info', 'x3d', inifile)
            if date_get_szToday() != strDateIni:
                # bUpX3d = True
                pass
            strDateIni = ini_get('module_info', 'hd-outer', inifile)
            if date_get_szToday() != strDateIni:
                bUpHdOuter = True


            #更新
            if bUpHd:
                self.log.info('up HD start')
                dstPath = SERVER_MAINSCRIPT + '\\module_info_hd.xml'
                filecontrol_deleteFileOrFolder(dstPath)
                filecontrol_deleteFileOrFolder(u'svnTemp')
                svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client/ui/module_info.xml'
                os.makedirs('svnTemp')
                svn_cmd_export(svn_module_info, None, 'svnTemp', SVN_USER, SVN_PASS)
                filecontrol_copyFileOrFolder('svnTemp/module_info.xml', dstPath)
                ini_set('module_info', 'hd', date_get_szToday(), inifile)
            if bUpHdOuter:
                self.log.info('up HD-outer start')
                dstPath = SERVER_MAINSCRIPT + '\\module_info_hd_outer.xml'
                filecontrol_deleteFileOrFolder(dstPath)
                filecontrol_deleteFileOrFolder(u'svnTemp')
                svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/sword3-products/branches-rel/b_jx3_released_zhcn_hd/client/ui/module_info.xml'
                os.makedirs('svnTemp')
                svn_cmd_export(svn_module_info, None, 'svnTemp', SVN_USER, SVN_PASS)
                filecontrol_copyFileOrFolder('svnTemp/module_info.xml', dstPath)
                ini_set('module_info', 'hd-outer', date_get_szToday(), inifile)
            if bUpClassic:
                self.log.info('up classic start')
                dstPath = SERVER_MAINSCRIPT + '\\module_info_classic.xml'
                filecontrol_deleteFileOrFolder(dstPath)
                filecontrol_deleteFileOrFolder(u'svnTemp')
                svn_module_info = 'https://xsjreposvr4.seasungame.com/svn/sword3-products_Classic/trunk/client/ui/module_info.xml'
                os.makedirs('svnTemp')
                svn_cmd_export(svn_module_info, None, 'svnTemp', SVN_USER, SVN_PASS)
                filecontrol_copyFileOrFolder('svnTemp/module_info.xml', dstPath)
                ini_set('module_info', 'classic', date_get_szToday(), inifile)
            if bUpX3d:
                self.log.info('up x3d start')
                dstPath = SERVER_MAINSCRIPT + '\\module_info_jx3x3d.xml'
                filecontrol_deleteFileOrFolder(dstPath)
                filecontrol_deleteFileOrFolder(u'svnTemp')
                svn_module_info = 'https://xsjreposvr5.seasungame.com/svn/sword3-m2-products/trunk/client/ui/module_info.xml'
                os.makedirs('svnTemp')
                svn_cmd_export(svn_module_info, None, 'svnTemp', SVN_USER, SVN_PASS)
                filecontrol_copyFileOrFolder('svnTemp/module_info.xml', dstPath)
                ini_set('module_info', 'x3d', date_get_szToday(), inifile)


if __name__ == "__main__":
    obj = CaseBackUpModule_info()
    obj.run_from_IQB()
