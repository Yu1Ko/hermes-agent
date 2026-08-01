# ver:3.6

from CaseCommon import *
import time
import sqlite3

def db_get_bvt_code_ver_hd():
    # try:
        PRODUCTVER = 0
        CODEVER = 1
        DATE = 2
        todayBVT = svn_get_bvt_version()
        if not todayBVT:
            return None
        todayBVT = todayBVT[1]

        conn = sql.connect(r"\\10.11.68.11\FileShare\JX3BVT\DB\CodeVer.db")
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM MainTable WHERE ProductVer = {}".format(todayBVT))
        data = cursor.fetchall()
        if len(data) == 0:
            return None
        ver = data[0][CODEVER]
        return int(ver)
    # except Exception as e:
    #
    #     info = traceback.format_exc()
    #     print info
# 查找svn日志需要的日期格式
def getnowdate2():
    return datetime.datetime.now().strftime('%Y-%#m-%#d')

# CodeVer.db数据库需要的日期格式
def getnowdate():
    return datetime.datetime.now().strftime('%Y{}%#m{}%#d{}').format('年', '月', '日')


# 查找svn日志需要的日期格式，获取昨天的日期
def getYesterday():
    today = datetime.date.today()
    oneday = datetime.timedelta(days=1)
    yesterday = (today - oneday).strftime('%Y-%#m-%#d')
    return yesterday
# 根据今天和昨天的日期获得今天的CodeVersion
def get_svnver_by_svnlog():
    res = os.popen(
        'svn log https://xsjreposvr1.seasungame.com/svn/sword3-products/trunk/client -r {' + str(getYesterday()) + '}:{' + str(getnowdate2()) + '}')
    res_str = res.read()
    Code_Ver_today = re.findall(r'(?<=CodeVersion : )\d+\.?\d*', res_str)[
        len(re.findall(r'(?<=CodeVersion : )\d+\.?\d*', res_str)) - 1]
    info =  "Code_Ver:{}".format(Code_Ver_today)
    return Code_Ver_today

def write_to_db(bvt_version, code_version):
    # try:
        conn = sqlite3.connect(r'\\10.11.68.11\FileShare\JX3BVT\DB\CodeVer.db')
        sql = r"insert into MainTable(ProductVer, CodeVer, Date) values(%d, %d,'%s')" % (
            bvt_version, code_version, getnowdate())
        conn.execute(sql)
        conn.commit()
        conn.close()
        # print 'write_to_db successfully'
    # except Exception as e:
    #     print 'connect CodeVer.db error'

class CaseBackUpIncludeForJx3Robot(CaseCommon):
    def __init__(self):
        super(CaseBackUpIncludeForJx3Robot, self).__init__()

    def run_local(self, dic_args):
        # 用例的工作内容
        while 1:
            time.sleep(2)
            #判断今天有没有生成include
            sztoday = date_get_szToday()
            checkpath = r'\\10.11.68.11\FileShare\IncludeForJx3Robot' + '\\' + sztoday
            if os.path.exists(checkpath):
                continue
            #检查今天客户端bvt出来了没有
            todayBVT = svn_get_bvt_version()
            if not todayBVT:
                continue
            #今天有没有code版本
            ver = db_get_bvt_code_ver_hd()
            if not ver:
                codever = get_svnver_by_svnlog()
                write_to_db(int(todayBVT[1]), int(codever)) #给邦戈用的？
                continue
            #生成include
            os.makedirs(checkpath)
            os.makedirs(checkpath + '\\Include')
            os.makedirs(checkpath + '\\BaseInclude')

            svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/Sword3/trunk/Include'
            filecontrol_deleteFileOrFolder(u'svnTemp')
            os.makedirs('svnTemp')
            svn_cmd_export(svn_module_info, ver, 'svnTemp', user_readini=True)
            filecontrol_copyFileOrFolder('svnTemp/Include', checkpath + '\\Include')

            svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/Base/trunk/Include'
            filecontrol_deleteFileOrFolder(u'svnTemp')
            os.makedirs('svnTemp')
            svn_cmd_export(svn_module_info, None, 'svnTemp', user_readini=True)
            filecontrol_copyFileOrFolder('svnTemp/Include', checkpath + '\\BaseInclude')

            svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/Sword3/trunk/Source/Common/SO3World/Src/KPlayerClient.cpp'
            filecontrol_deleteFileOrFolder(u'svnTemp')
            os.makedirs('svnTemp')
            svn_cmd_export(svn_module_info, None, 'svnTemp', user_readini=True)
            filecontrol_copyFileOrFolder('svnTemp/KPlayerClient.cpp', checkpath + '\\KPlayerClient.cpp')

            svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/Sword3/trunk/Source/Common/SO3World/Src/KPlayerServer.cpp'
            filecontrol_deleteFileOrFolder(u'svnTemp')
            os.makedirs('svnTemp')
            svn_cmd_export(svn_module_info, None, 'svnTemp', user_readini=True)
            filecontrol_copyFileOrFolder('svnTemp/KPlayerServer.cpp', checkpath + '\\KPlayerServer.cpp')

            svn_module_info = 'https://xsjreposvr1.seasungame.com/svn/Sword3/trunk/Source/Common/SO3World/Src/KHomelandMgr.cpp'
            filecontrol_deleteFileOrFolder(u'svnTemp')
            os.makedirs('svnTemp')
            svn_cmd_export(svn_module_info, None, 'svnTemp', user_readini=True)
            filecontrol_copyFileOrFolder('svnTemp/KHomelandMgr.cpp', checkpath + '\\KHomelandMgr.cpp')


if __name__ == '__main__':
    ob = CaseBackUpIncludeForJx3Robot()
    ob.run_from_IQB()
