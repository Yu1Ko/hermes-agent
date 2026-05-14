# -*- coding: utf-8 -*-

import ctypes
import threading
from BaseToolFunc import *
import pandas
import mmapfile as mmf
import struct


PERF_DIR = r'LOG'

x = os.path.realpath(__file__)
root = x.split('\\')[0]
PERFMON_PATH_LOCAL = os.path.join(root, os.sep, 'PerfMon3')
#custom_info.tab
def write_custom_info(result_dir, tags, subtags):
    f = open(result_dir + "/custom_info.tab", "w")
    f.write("Tags\tSubTags\n{0}\t{1}\n".format(tags, subtags))
    f.close()
    f = open(result_dir + '/' + 'Tags', 'w')
    f.write(subtags)
    f.close()
    return True

#sys_baseinfo.tab
def write_sys_baseinfo(result_dir, PAKV4_CLIENT, task_name = 'auto-bvt'):
    Gpu_Name = machine_get_VideoCardInfo()
    Gpu_Mem = ''
    Gpu_Clock = ''
    Gpu_Memory_Max_Freq = ''
    Gpu_Boost_Max_Freq = ''
    IP = machine_get_IPAddress()
    os_name = platform.platform()       #格式不太对
    os_type = platform.architecture()[0]   #格式不太对
    #处理器CPU
    Cpu_name = machine_get_CPUInfo()
    Cpu_core_num = machine_get_CPUCoreNum()
    #内存
    internal_mem = format_space(machine_get_PhysicalMemorySize())
    #硬盘
    disk_space = 0
    disk_space = format_space(disk_space)
    #剑网3版本
    version_cfg = configparser.ConfigParser()
    version_cfg.read(PAKV4_CLIENT + "/version.cfg")
    try:
        Sword3_versionex = version_cfg.get("Version", "Sword3.versionex")
        Sword3_version = version_cfg.get("Version", "Sword3.version")
    except Exception as e:
        Sword3_versionex = '1'
        Sword3_version = '1'


    all_info = [["Task", task_name],
                ["显存大小", Gpu_Mem],
                ["GPU Clock 最大频率(MHz)", Gpu_Clock],
                ["GPU Memory 最大频率(MHz)", Gpu_Memory_Max_Freq],
                ["GPU Boost 最大频率(MHz)", Gpu_Boost_Max_Freq],
                ["显卡名称", Gpu_Name],
                ["ip地址", IP],
                ["操作系统名称", os_name],
                ["操作系统类型", os_type],
                ["处理器名称", Cpu_name],
                ["逻辑核数量", Cpu_core_num],
                ["物理内存", internal_mem],
                ["磁盘空间", disk_space],
                ["Sword3_versionex", Sword3_versionex],
                ["Sword3_version", Sword3_version],
                ["报告日期", date_get_szToday_7()],
                ]
    f = open(result_dir + "/sys_baseinfo.tab", "w")
    f.write("\t".join([x[0] for x in all_info]))
    f.write('\n')
    # f.write("\t".join([x[1] for x in all_info]))
    for each in all_info:
        f.write(each[1] + '\t')
    f.write('\n')
    f.close()

def start_v4(pid, list_parse_args, perfmonPath = os.getcwd()):
    # 开始采集
    listCMD = []
    listCMD.append(perfmonPath + '/perfmon.exe')
    listCMD.append('--perf_id={}'.format(pid))
    for parse in list_parse_args:
        listCMD.append(parse)
    x = subprocess.Popen(listCMD, cwd=perfmonPath, creationflags=subprocess.CREATE_NEW_CONSOLE)



def openGPUZ(path):
    if win32_findProcessByName('GPU-Z.exe'):
        return
    exe = os.path.join(path, 'GPU-Z.exe')
    win32_runExe_no_wait(exe, path)

def start_v3(pid, InputScreenIntervelGet, perfmonPath = os.getcwd() ):
    #开始采集
    listCMD = []
    listCMD.append(perfmonPath +'/perfmon.exe')
    listCMD.append('--perf_id={}'.format(pid))
    listCMD.append('--perf_d3d11hook')
    listCMD.append('--perf_snapshot')
    listCMD.append('--perf_snapshot_intervel={}'.format(InputScreenIntervelGet))
    listCMD.append('--perf_gpuz')
    listCMD.append('--perf_logicFPShook')
    listCMD.append('--perf_sockethook')
    x = subprocess.Popen(listCMD, cwd=perfmonPath,creationflags=subprocess.CREATE_NEW_CONSOLE)

def start_jx3x3d_v3(pid, InputScreenIntervelGet, perfmonPath = os.getcwd() ):
    #开始采集
    listCMD = []
    listCMD.append(perfmonPath +'/perfmon.exe')
    listCMD.append('--perf_id={}'.format(pid))
    # listCMD.append('--perf_d3d11hook')
    listCMD.append('--perf_snapshot')
    listCMD.append('--perf_snapshot_intervel={}'.format(InputScreenIntervelGet))
    listCMD.append('--perf_gpuz')
    # listCMD.append('--perf_logicFPShook')
    listCMD.append('--perf_sockethook')
    x = subprocess.Popen(listCMD, cwd=perfmonPath,creationflags=subprocess.CREATE_NEW_CONSOLE)

def start_memtest_v3(pid, InputScreenIntervelGet, perfmonPath = os.getcwd() ):

    #开始采集
    listCMD = []
    listCMD.append(perfmonPath +'/perfmon.exe')
    listCMD.append('--perf_id={}'.format(pid))
    # listCMD.append('--perf_d3d11hook')
    # listCMD.append('--perf_snapshot')
    # listCMD.append('--perf_snapshot_intervel={}'.format(InputScreenIntervelGet))
    # listCMD.append('--perf_gpuz')
    # listCMD.append('--perf_logicFPShook')
    # listCMD.append('--perf_sockethook')
    x = subprocess.Popen(listCMD, cwd=perfmonPath,creationflags=subprocess.CREATE_NEW_CONSOLE)


def stop_V4(perfmonPid=-1, perfmonPath = os.getcwd()):
    close_file = perfmonPath + '\close_' + str(perfmonPid)
    with open(close_file, 'w') as f:
        pass

def stop_v3(perfmonPid=-1, perfmonPath = os.getcwd()):
    close_file = perfmonPath + '\close_' + str(perfmonPid)
    with open(close_file, 'w') as f:
        pass

def PerfMon_getFpsForSharedMemory(pid):
    nSMsize = 1424 #共享结构体大小  见Perfmon3脚本
    read_mmf = mmf.mmapfile(None, 'PerfMon_D3DHook_SM_' + str(pid), nSMsize)
    read_mmf.seek(0)
    buff = read_mmf.read(nSMsize)
    return (struct.unpack('f', buff[56:60]))[0]



def process_data(ImageQualityGet,TypeGet,ConfigGet,RunMapGet,InputPointGet,PathGet,perfmonLOGPath = os.getcwd()):
    perfmonLOGPath = perfmonLOGPath+'/LOG'
    tagEngineLevel = ImageQualityGet
    tagMachineType = TypeGet
    tagVideoCard = ConfigGet
    tagMapName = RunMapGet
    tagTestPoint = InputPointGet
    PAKV4_CLIENT = r'F:\JX3_EXP_inner\Game\JX3_EXP\bin\zhcn_exp' if (PathGet == 'default') else PathGet
    tags = '档次|机型|配置|地图|测试点|日期'
    subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(tagEngineLevel, tagMachineType, tagVideoCard, tagMapName, tagTestPoint,
                                               date_get_szToday_7())
    # 移动文件，数据、截图
    time.sleep(1)
    strWorkFolder = ''
    nFolder = 0
    pattern = re.compile(r"^\d+\d$")
    for subentry in os.listdir(perfmonLOGPath):
        if not pattern.match(subentry):
            continue
        if int(subentry) > nFolder:
            nFolder = int(subentry)
            strWorkFolder = subentry
    if len(strWorkFolder) == 0:
        return
    subpath = perfmonLOGPath + '/' + strWorkFolder
    if os.path.exists(subpath+ '/'+"process.done"):
        return
    if not os.path.exists(subpath + '/Printscreen'):
        os.mkdir(subpath + '/Printscreen')
    for entry in os.listdir(subpath):
        path =  subpath+ '/'+entry
        if not os.path.isfile(path):
            continue
        if entry.endswith(".txt"):  # txt
            shutil.move(path, subpath + "/sys_summary.tab")
        elif entry.endswith(".jpg"):  # jpg
            shutil.move(path, subpath + "/Printscreen/" + entry)
    write_custom_info(subpath, tags, subtags)
    write_sys_baseinfo(subpath, PAKV4_CLIENT)
    f= open(subpath+ '/'+"process.done",'w')
    f.close()

def process_data_v3(ImageQualityGet,TypeGet,ConfigGet,RunMapGet,InputPointGet,PathGet,perfmonLOGPath = os.getcwd()):


    tagEngineLevel = ImageQualityGet
    tagMachineType = TypeGet
    tagVideoCard = ConfigGet
    tagMapName = RunMapGet
    tagTestPoint = InputPointGet
    PAKV4_CLIENT = r'F:\JX3_EXP_inner\Game\JX3_EXP\bin\zhcn_exp' if (PathGet == 'default') else PathGet
    tags = '档次|机型|配置|地图|测试点|日期'
    subtags = '{0}|{1}|{2}|{3}|{4}|{5}'.format(tagEngineLevel, tagMachineType, tagVideoCard, tagMapName, tagTestPoint,
                                               date_get_szToday_7())
    # 移动文件，数据、截图
    time.sleep(1)
    strWorkFolder = ''
    nMaxTime = 0
    pattern = re.compile(r"\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}") #匹配日期格式
    for subentry in os.listdir(perfmonLOGPath):
        if not pattern.match(subentry):
            continue
        subentry_path = os.path.join(perfmonLOGPath, subentry)
        if os.path.isfile(subentry_path):
            continue
        timeArray = time.strptime(subentry, "%Y-%m-%d-%H-%M-%S")
        timeStamp = int(time.mktime(timeArray))
        if timeStamp > nMaxTime:
            nMaxTime = timeStamp
            strWorkFolder = subentry
    if len(strWorkFolder) == 0:
        return
    subpath = perfmonLOGPath + '/' + strWorkFolder
    if os.path.exists(subpath+ '/'+"process.done"):
        return

    write_custom_info(subpath, tags, subtags)
    write_sys_baseinfo(subpath, PAKV4_CLIENT)
    f= open(subpath+ '/'+'type', 'w')
    f.write('baseperf')
    f.close()
    # process performanceOutput
    perfPath = os.path.join(PAKV4_CLIENT, 'trewq.qwe')
    summaryPath = os.path.join(subpath, 'sys_summary.tab')
    if os.path.exists(perfPath):
        try:
            df = pandas.read_csv(perfPath, dtype=object, sep='\t')
            df_summaryPath = pandas.read_csv(summaryPath, dtype=object, sep='\t')
            df_merge = pandas.merge(df_summaryPath, df, how='left', on='Time')
            df_merge.to_csv(summaryPath, sep='\t', index=None)
        except Exception as e:
            logger = logging.getLogger(str(os.getpid()))
            logger.exception(e)
    f= open(subpath+ '/'+"process.done",'w')
    f.close()
    # 热力图数据处理
    playerInfoPath = os.path.join(PathGet, 'PlayerInfo.tab')
    if not os.path.exists(playerInfoPath):
        return
    summaryPath = os.path.join(subpath, 'sys_summary.tab')
    # df1 = pandas.read_csv(summaryPath, dtype=object, sep='\t')
    # # with open(playerInfoPath, 'r') as f:
    # #     x = f.read()
    # # with open(playerInfoPath, 'w') as f:
    # #     f.write(x)
    # df2 = pandas.read_csv(playerInfoPath, dtype=object, sep='\t')
    # df = pandas.merge(df1, df2, how='left', on='Time')
    # # index=None 不要把index写入文件
    # df.to_csv(summaryPath, sep='\t', index=None)

def process_data_v4(subtags, PathGet, perfmonLOGPath = os.getcwd()):
    perfmonLOGPath = perfmonLOGPath+'/DATA'
    PAKV4_CLIENT = r'F:\JX3_EXP_inner\Game\JX3_EXP\bin\zhcn_exp' if (PathGet == 'default') else PathGet
    tags = '档次|机型|配置|地图|测试点|日期'

    # 移动文件，数据、截图
    time.sleep(1)
    strWorkFolder = ''
    nMaxTime = 0
    pattern = re.compile(r"\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}") #匹配日期格式
    for subentry in os.listdir(perfmonLOGPath):
        if not pattern.match(subentry):
            continue
        subentry_path = os.path.join(perfmonLOGPath, subentry)
        if os.path.isfile(subentry_path):
            continue
        timeArray = time.strptime(subentry, "%Y-%m-%d-%H-%M-%S")
        timeStamp = int(time.mktime(timeArray))
        if timeStamp > nMaxTime:
            nMaxTime = timeStamp
            strWorkFolder = subentry
    if len(strWorkFolder) == 0:
        return
    subpath = perfmonLOGPath + '/' + strWorkFolder
    if os.path.exists(subpath+ '/'+"process.done"):
        return

    write_custom_info(subpath, tags, subtags)
    write_sys_baseinfo(subpath, PAKV4_CLIENT)
    f= open(subpath+ '/'+'type', 'w')
    f.write('baseperf')
    f.close()
    # process performanceOutput
    perfPath = os.path.join(PAKV4_CLIENT, 'trewq.qwe')
    summaryPath = os.path.join(subpath, 'sys_summary.tab')
    if os.path.exists(perfPath):
        try:
            df = pandas.read_csv(perfPath, dtype=object, sep='\t')
            df_summaryPath = pandas.read_csv(summaryPath, dtype=object, sep='\t')
            df_merge = pandas.merge(df_summaryPath, df, how='left', on='Time')
            df_merge.to_csv(summaryPath, sep='\t', index=None)
        except Exception as e:
            logger = logging.getLogger(str(os.getpid()))
            logger.exception(e)
    f= open(subpath+ '/'+"process.done",'w')
    f.close()
    # 热力图数据处理
    playerInfoPath = os.path.join(PathGet, 'PlayerInfo.tab')
    if not os.path.exists(playerInfoPath):
        return
    summaryPath = os.path.join(subpath, 'sys_summary.tab')
    df1 = pandas.read_csv(summaryPath, dtype=object, sep='\t')
    with open(playerInfoPath, 'r') as f:
        x = f.read()
    with open(playerInfoPath, 'w') as f:
        f.write(x)
    df2 = pandas.read_csv(playerInfoPath, dtype=object, sep='\t')
    df = pandas.merge(df1, df2, how='left', on='Time')
    # index=None 不要把index写入文件
    df.to_csv(summaryPath, sep='\t', index=None)


def process_data_picmonitor(listPicsPath, appKey, testpoint, Version):
    datetime2path = time.strftime("%Y-%m-%d-%H-%M-%S",time.localtime())
    dataPath = os.path.join(PERFMON_PATH_LOCAL, 'DATA', datetime2path)
    os.makedirs(dataPath)
    for pic in listPicsPath:
        filecontrol_copyFileOrFolder(pic, dataPath)
    with open(os.path.join(dataPath, 'Testpoint'), 'w') as f:
        f.write(testpoint)
    with open(os.path.join(dataPath, 'AppKey'), 'w') as f:
        f.write(appKey)
    with open(os.path.join(dataPath, 'Version'), 'w') as f:
        f.write(Version)
    with open(os.path.join(dataPath, 'type'), 'w') as f:
        f.write('picturemonitor')


def upload(strPerfmonPath = os.getcwd(), strPerfDir = PERF_DIR, key = 'jx3hd'):
    listCMD = []
    listCMD.append(strPerfmonPath+'/PerfReporterX86.exe')
    listCMD.append('-l')
    listCMD.append('1')
    listCMD.append('-u')
    listCMD.append('http://jxrp.testplus.cn/uploadperf')
    listCMD.append('-d')
    listCMD.append(strPerfDir)
    listCMD.append('-k')
    listCMD.append(key)
    p = subprocess.Popen(listCMD, cwd=strPerfmonPath,creationflags=subprocess.CREATE_NEW_CONSOLE)
    # p.wait()
    # upload_new(strPerfmonPath, strPerfDir, key)


def upload_new(strPerfmonPath = PERFMON_PATH_LOCAL, strPerfDir = 'DATA', key = 'jx3hd'):
    logger = logging.getLogger(str(os.getpid()))
    logger.warning(u'test')
    # 寻找最新的那个目录  new upload
    logger = logging.getLogger(str(os.getpid()))
    strWorkFolder = None
    nMaxTime = 0
    pattern = re.compile(r"\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}")  # 匹配日期格式
    strPerfDirFull = os.path.join(strPerfmonPath, strPerfDir)
    for subentry in os.listdir(strPerfDirFull):
        if not pattern.match(subentry):
            continue
        subentry_path = os.path.join(strPerfDirFull, subentry)
        if os.path.isfile(subentry_path):
            continue
        timeArray = time.strptime(subentry, "%Y-%m-%d-%H-%M-%S")
        timeStamp = int(time.mktime(timeArray))
        if timeStamp > nMaxTime:
            nMaxTime = timeStamp
            strWorkFolder = subentry
    if not strWorkFolder:
        logger.warning(u'no upload path')
        return
    logger.warning(u'test2')
    strUploadPathFull = os.path.join(strPerfDirFull, strWorkFolder)
    logger.warning(strUploadPathFull)
    appkeyPath = os.path.join(strUploadPathFull, 'AppKey')
    if not os.path.exists(appkeyPath):
        with open(appkeyPath, 'w') as f:
            f.write(key)
    listCMD = []
    listCMD.append(strPerfmonPath + '/UploadClient.exe')
    listCMD.append('--absdir')
    listCMD.append(strUploadPathFull)
    listCMD.append('--serverurl')
    listCMD.append('http://10.11.86.120:5000/uploadperf')
    p = subprocess.Popen(listCMD, cwd=strPerfmonPath, creationflags=subprocess.CREATE_NEW_CONSOLE)
    p.wait()

def UploadClient(strPerfmonPath = PERFMON_PATH_LOCAL, strPerfDir = 'DATA', serverurl = 'http://10.11.86.120:5000/uploadperf',
                 type = 'baseperf'):
    # type
    type_file = os.path.join(strPerfDir, 'type')
    with open(type_file, 'w') as f:
        f.write(type)
    listCMD = []
    listCMD.append(strPerfmonPath + '/UploadClient.exe')
    listCMD.append('--absdir')
    listCMD.append(strPerfDir)
    listCMD.append('--serverurl')
    listCMD.append(serverurl)
    p = subprocess.Popen(listCMD, cwd=strPerfmonPath, creationflags=subprocess.CREATE_NEW_CONSOLE)
    p.wait()

def createMachineInfo(strPerfDir):
    dicMachineInfo = {}
    dicMachineInfo['DeviceName'] = machine_get_DeviceName()
    dicMachineInfo['CPUInfo'] = machine_get_CPUInfo_v2()
    dicMachineInfo['GPUType'] = machine_get_VideoCardInfo_v2()
    dicMachineInfo['RAMSize'] = '{}GB'.format(round(machine_get_PhysicalMemorySize() / 1024.0 / 1024 /1024))
    dicMachineInfo['DeviceIp'] = machine_get_IPAddress()
    dicMachineInfo['OSInfo'] = machine_get_OSInfo()
    dicMachineInfo['DiskInfo'] = machine_get_DiskDriveInfo()
    if strPerfDir:
        jsonMachineInfo = os.path.join(strPerfDir, 'machine_info.json')
        with open(jsonMachineInfo, 'w') as f:
            json.dump(dicMachineInfo, f, ensure_ascii=False)
    return dicMachineInfo

def createCustomInfoForjx3Moblie(strPerfDir, appkey = 'jx3x3d', tags = '空'):
    dicCustomInfo = {}
    dicCustomInfo['appkey'] = appkey
    dicCustomInfo['tags'] = tags
    jsonCustomInfo = os.path.join(strPerfDir, 'custom_info.json')
    with open(jsonCustomInfo, 'w') as f:
        json.dump(dicCustomInfo, f, ensure_ascii=False)


#------------------------PerfMonForBVT ver3-------------------
def perfMonCtrl_start_v3(pid, strSnapshot_intervel):
    start_v3(pid, str(strSnapshot_intervel), PERFMON_PATH_LOCAL)

def perfMonCtrl_start_jx3x3d_v3(pid, strSnapshot_intervel):
    start_jx3x3d_v3(pid, str(strSnapshot_intervel), PERFMON_PATH_LOCAL)

def perfMonCtrl_start_memtest_v3(pid, strSnapshot_intervel):
    start_memtest_v3(pid, str(strSnapshot_intervel), PERFMON_PATH_LOCAL)

def perfMonCtrl_stop_v3(perfmonPid):
    stop_v3(perfmonPid, PERFMON_PATH_LOCAL)

def perfMonCtrl_process_data_v3(video_level, machine_type, video_card, mapname, testpoint, client_path):
    process_data_v3(video_level,machine_type,video_card,mapname,testpoint,client_path,PERFMON_PATH_LOCAL)

def perfMonCtrl_process_data_v4(subtags, client_path):
    process_data_v4(subtags, client_path, PERFMON_PATH_LOCAL)

def perfMonCtrl_upload_v3(key = 'jx3hd', path = 'DATA'):
    upload(PERFMON_PATH_LOCAL, path, key)
#------------------------PerfMonForBVT ver3-------------------end

if __name__ == '__main__':
    pass

