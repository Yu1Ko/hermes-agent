# -*- coding: utf-8 -*-
import json
import logging

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
    "成都": ["120000|120000", "30000|30000,100000|100000"]
}

def HotPointMapUpLoadData(AppKey,JsonPath,Model,Scene_Name,Version):
    #szJsonPath = r"E:\trunk_moblie\client\mui\Lua\Result.json"
   #"appkey": "jw3qptqjb"
    #"spacing": 64 * 40

    with open(JsonPath, 'r') as f:
        data = json.loads(f.read())
    verdata = {
        "appkey": AppKey,
        "fileType": "scene",
        "model": Model,
        "scene_name": Scene_Name,
        "version": Version,
        "maxpos": dic_HotPointMapPos[Scene_Name][0],
        "rect": dic_HotPointMapPos[Scene_Name][1]
    }
    data["dataTitles"] = "SetPassCall,DrawCall,Vertices,Triangles,Memory,Fps,Ms,GM"
    szOuputPath = "TempFolder/Data.json"
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
    szImgPathTmp='TempFolder/middlemap.png'
    filecontrol_copyFileOrFolder(szImgPathSrc,szImgPathTmp)
    rf = open(szImgPathTmp, 'rb')
    r1 = requests.put(uploadUrl, rf)
    if r1.status_code!=200:
        raise Exception('HotPointMap_Img Error :{}'.format(r1.status_code))