# -*- coding: utf-8 -*-
import json
import logging
import time

import requests
from BaseToolFunc import *

#upload_ip = u'10.11.86.138'  # 上传ip 测试环境
upload_ip = u'10.11.66.69'  # 上传ip 正式环境

dic_HotPointMapPos={
    "稻香村":["42207|38075","2000|8000,35000|35000"],
    "万花":["85745|75603","7345|6656,83345|72656"],
    "扬州":["95220|96308","7634|7321,91634 93321"],
    "七秀":["98944|91624","2836|6864,96836|88864"],
    "楚州":["120000|120000","2000|20000,100000|100000"],
    "万灵山庄": ["120000|120000", "2000|20000,100000|100000"],
    "银霜口": ["120000|120000", "2000|20000,100000|100000"],
    "成都": ["120000|120000", "30000|30000,100000|100000"],
    "烂柯山": ["120000|120000", "3000|9000,100000|120000"],
    "润扬": ["120000|120000", "2000|8000,100000|100000"],
    "少林_乱世": ["120000|120000", "3000|10000,100000|120000"],
    "太原": ["120000|120000", "15000|20000,120000|120000"],
    "万花_乱世": ["110000|110000", "16000|30000,90000|108000"],
    "长安": ["120000|120000", "10000|8000,100000|120000"],
    "稻香村_桃园非梦": ["80000|120000", "40000|40000,75000|100300"]
}


def HotPointMapUpLoadData(AppKey,JsonPath,Model,Scene_Name,Version,strTag=''):
    #szJsonPath = r"E:\trunk_moblie\client\mui\Lua\Result.json"
   #"appkey": "jw3qptqjb"
    #"spacing": 64 * 40

    try:
        with open(JsonPath, 'r') as f:
            data = json.loads(f.read())
    except:
        time.sleep(10)
        with open(JsonPath, 'r') as f:
            data = json.loads(f.read())

    with open(os.path.join(GetTEMPFOLDER(), Scene_Name), 'r') as f:
        strContent = f.read()
        list_mapInfo=strContent.split('\n')
    #睡眠多少秒跳转下一个点
    strSleepType=list_mapInfo[2].lstrip()
    verdata = {
        "appkey": AppKey,
        "fileType": "scene",
        "model": Model,
        "custom_type":strSleepType+strTag,
        "scene_name": Scene_Name,
        "version": Version,
        "spacing": list_mapInfo[3].lstrip(),
        "maxpos":list_mapInfo[0].lstrip(),
        "rect": list_mapInfo[1].lstrip()
    }
    '''
    verdata = {
        "appkey": AppKey,
        "fileType": "scene",
        "model": Model,
        "scene_name": Scene_Name,
        "version": Version,
        "maxpos": dic_HotPointMapPos[Scene_Name][0],
        "rect": dic_HotPointMapPos[Scene_Name][1]
    }'''
    data["dataTitles"] = "SetPassCall,DrawCall,DrawBatch,Vertices,Triangles,Memory,Fps,Ms,GM"
    szOuputPath = f"{GetTEMPFOLDER()}/Data.json"
    with open(szOuputPath, 'w+') as f:
        f.write(json.dumps(data))

    print(data)
    r = requests.post("http://{}/api/file/upload/url".format(upload_ip), json=verdata)
    print(r)
    uploadArg = json.loads(r.text)
    reportId = uploadArg["data"]["report_id"]
    uploadUrl = uploadArg["data"]["upload_url"]
    rf = open(szOuputPath, 'rb')
    r1 = requests.put(uploadUrl, rf)
    if r1.status_code == 200:
        r2 = requests.post("http://{}/api/file/uploaded?reportId={}".format(upload_ip, reportId))
        if r2.status_code!=200:
            raise Exception('HotPointMap_data PosError :{}'.format(r2.status_code))
    else:
        raise Exception('HotPointMap_data PutError :{}'.format(r1.status_code))
    #filecontrol_deleteFileOrFolder(szOuputPath)
    return reportId

def HotPointMapUpLoadImg(AppKey,Scene_Name,reportId=None):
    if reportId:
        verdata = {"appkey": AppKey, "scene_name": Scene_Name, 'reportId': reportId}
    else:
        verdata = {"appkey": AppKey, "scene_name": Scene_Name}
    r = requests.post("http://{}/api/file/image/upload".format(upload_ip), json=verdata)
    uploadArg = json.loads(r.text)
    uploadUrl = uploadArg["data"]["upload_url"]
    szImgPathSrc = SERVER_PATH+"/XGame/minimap/"+Scene_Name+".png"
    szImgPathTmp=f'{GetTEMPFOLDER()}/middlemap.png'
    filecontrol_copyFileOrFolder(szImgPathSrc,szImgPathTmp)
    rf = open(szImgPathTmp, 'rb')
    r1 = requests.put(uploadUrl, rf)
    if r1.status_code!=200:
        raise Exception('HotPointMap_Img Error :{}'.format(r1.status_code))


#上传perfeye绑定到热力图平台
def HotPointMapPerfeyeUid(reportId=None,perfeyeUid=None):
    verdata = {'reportId': reportId,"perfeyeUid":perfeyeUid}
    r = requests.post("{}api/file/report/perfeye-url/update".format(upload_ip), json=verdata)
    print(r)

def PrintComplianceRate(JsonPath):
    nTriggleBase=700000
    nDrawBatchBase = 400
    nTriggleAllCnt=0
    nDrawBatchAllCnt = 0

    nTriggleCnt=0
    nDrawBatchCnt = 0

    fTriggleRate=0
    fDrawBatchRate = 0
    try:
        with open(JsonPath, 'r') as f:
            data = json.loads(f.read())
    except:
        time.sleep(10)
        with open(JsonPath, 'r') as f:
            data = json.loads(f.read())
    print(data)
    d=data["performanceData"]
    n=1
    for key in d:
        print(key)
        list_pointInfo=d[key]
        if "testGM" in list_pointInfo[0]:
            continue
        for angleInfo in list_pointInfo:
            print(angleInfo)
            nTriggleAllCnt+=1
            nDrawBatchAllCnt+=1

            #angleInfo="(0.00, 0.00, 0.00),0,227,252,0,1226346,460,30,33.3"
            #SetPassCall,DrawCall,DrawBatch,Vertices,Triangles,Memory,Fps,Ms,GM
            nTriggle=int(angleInfo.split(',')[7])
            nDrawBatch = int(angleInfo.split(',')[5])
            print(nTriggle)
            print(nDrawBatch)
            if nTriggle>=nTriggleBase:
                nTriggleCnt+=1
            if nDrawBatch>nDrawBatchBase:
                nDrawBatchCnt+=1


    print("Triangles超标比例:")
    percent = (nTriggleCnt / nTriggleAllCnt) * 100
    formatted_percent = "{:.2f}%".format(percent)
    print(formatted_percent)

    print("DrawBatch超标比例:")
    percent = (nDrawBatchCnt / nTriggleAllCnt) * 100
    formatted_percent = "{:.2f}%".format(percent)
    print(formatted_percent)

if __name__ == '__main__':
# 设置内网数据上传
    #JsonPath="E:\BrowserDownLoad\DataRecord (10).json"
    #PrintComplianceRate(JsonPath)
    pass