import flask,json
from flask import request
import os
server = flask.Flask(__name__)

@server.route('/getlog',methods=['get'])
def getlog():
    taskid = request.values.get('taskid')
    devices=request.values.get('devices')
    if "10." in devices:
        devices=devices.split(":")[0].replace ('.','')
    path= os.path.dirname(__file__)
    fill_name=f'{path}/log_file/task{taskid}_{devices}.txt'
    if os.path.exists(fill_name):
        if taskid and devices:
            fobj = open(fill_name,'r')
            line =fobj.readlines()[-1000:]
            fobj.close()
            pdata= "</p><p>".join(line)
            data='<!DOCTYPE html><html><meta http-equiv="refresh" content="5"><style type="text/css">body{background-color:#404040;color:#999999 ;}p{margin:0}</style><head><meta charset="utf-8"></head>'+f'<body><h1>{taskid}_{devices}</h1><p>{ pdata}</p></body></html>'
            return data
        else:
            resu={'code':1001,'message':'参数不能为空'}
    else:
        resu={'code':1001,'message':'log文件不存在，请核对参数'}
    return json.dumps(resu,ensure_ascii=False)
@server.route('/excuteCommand',methods=['get'])
def excuteCommand():
    command = request.values.get('command')
    p = os.popen("adb -s "+command)
    return p.read()


if __name__== '__main__':
    server.run(debug=True,port = 8800,host='0.0.0.0')