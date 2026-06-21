# coding:utf-8
import json
import optparse
import time

import requests
from requests.adapters import HTTPAdapter
from urllib3 import Retry

requests.packages.urllib3.disable_warnings()

SNAKE_URL = 'http://10.11.11.213:9966'

APPEND_API = 'api/v1'

TIMEOUT = 60

RELEASE_SERVER="10.11.67.110:19501"

MINIO_URL='https://minio-cluster.testplus.cn'

def usage():
    help = "python %prog"
    parser = optparse.OptionParser(help)
    parser.add_option('-z', '--org_id', dest='org_id', type='string', help='project_id file', default="7dszskqgkb")
    parser.add_option('-p', '--project_id', dest='project_id', type='string', help='project_id file', default="5pgo3ebrra")  # 案例工程id
    parser.add_option('-c', '--clients', dest='clients', type='int', help='clients file', default=50)
    parser.add_option('-n', '--haterace', dest='haterace', type='int', help='haterace file', default=10)
    parser.add_option('-l', '--loadmachines', dest='loadmachines', type='int', help='loadmachines file',
                      default=10)
    parser.add_option('-a', '--label', dest='label', type='string', help='loadmachines file', default='emefa7jyhk')
    parser.add_option('-d', '--label_name', dest='label_name', type='string', help='loadmachines file',
                      default='月影标签-内网')
    parser.add_option('-t', '--time', dest='times', type='int', help='time', default=600)
    parser.add_option('-e', '--email', dest='email', type='string', help='email',default="zengjiasu@thewesthill.net")
    options, args = parser.parse_args()

    # print("rule:", options.rule, options.__dict__)
    return options, args


# options, args = usage()
# 设置Session
sess = requests.Session()
email = "liuhongliang@kingsoft.com"
sess.mount(SNAKE_URL, HTTPAdapter(max_retries=10))
header = {
    "Content-Type": "application/json",
    'Authorization': f'Bearer {email}',
    'Cookie': f'email={email}'
}
sess.headers.update(header)
# 设置登录信息
sess.headers.update({
    'K-USER-EMAIL': "liuhongliang@kingsoft.com"
})


def start(projectId, clients, haterace, times, loadmachines, label="3gxkrnvxsd", label_name="公共标签-新"):
    global sess, header
    # 防呆：避免调用方参数顺序传错导致类型不符合接口校验
    loadmachines = int(loadmachines)
    label = str(label)
    label_name = str(label_name)
    start_data = {
        "casefile": "main.py",
        "clients": clients,
        "haterace": haterace,
        "label": label,
        "loadmachines": loadmachines,
        "label_name": label_name,
        "perf_type": "cpp",
        "projectid": projectId,
        "subtypes": ["python3"],
        "timeout": times,
        "numberrequests": 1
    }
    image_url = f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/prepare/start"
    # 该接口需要 query 参数 label_uuid
    start_type = sess.get(image_url, params={"label_uuid": label}, headers=header, verify=False).text
    print(image_url,start_type)
    if start_type != 'true':
        check_url = f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/prepareimage/check"
        while True:
            check_code = sess.get(check_url, headers=header, verify=False).text
            if check_code and check_code != "1":
                break
            time.sleep(2)
    start_url = f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/start"
    # print(start_url)
    s = sess.post(start_url, data=json.dumps(start_data), headers=header, verify=False)
    print(f"压测案例状态码: {s.status_code}, 文本: {s.text}")
    if s.status_code != 201:
        return None
    try:
        task_id = json.loads(s.text)["uuid"]
        return task_id
    except:
        return None

def stop(projectId):
    global sess
    sess.headers.update(header)
    print("request:", f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/stop")
    res = sess.post(f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/stop", verify=False)
    print(f"压测案例状态码: {res.status_code}, 文本: {res.text}")

def updateCustomCon(project_id, menpai="1",tixing="1",wuqi="1",jinneg = '1',count="5",zhanzhuang="2"):
    global sess
    url = f"{MINIO_URL}/snaketest/{project_id}/case/.snake/customCom.json"
    print("url",url)
    retry_strategy = Retry(total=10, backoff_factor=60, status_forcelist=[429, 500, 502, 503, 504])
    adapter = HTTPAdapter(max_retries=retry_strategy)
    sess.mount(url, adapter)
    CustomConData = sess.get(url,timeout=TIMEOUT, verify=False).text
    if CustomConData:
        update_data = json.loads(CustomConData)
        print(f"update_data1 -> {update_data}")
        for i in update_data:
            for key, value in i.items():
                if value == "门派":
                    i['value'] = menpai
                if value == '体型':
                    i['value'] = tixing
                if value == '武器id':
                    i['value'] = wuqi
                if value == '释放的技能（1技能1...普攻4）':
                    i['value'] = jinneg
                if value == '技能释放间隔（秒）':
                    i['value'] = count
                if value == '站桩（1：站桩）':
                    i['value'] = zhanzhuang
    else:
        raise Exception("获取自定义参数为空")
    print(f"update_data2 -> {update_data}")
    url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/file/presigned/url?file_name=.snake%2FcustomCom.json&ftype=case"
    result = sess.get(url, headers=header, verify=False)
    sess.mount(SNAKE_URL, HTTPAdapter(max_retries=10))
    if result.status_code == 200:
        custom_url = json.loads(result.text)
    update_url = custom_url["upload_url"]
    requests.put(update_url,
                 data=json.dumps(update_data),
                 verify=False)
    modify_url = custom_url["download_url"]
    modify_ree = requests.get(modify_url, timeout=TIMEOUT, verify=False)
    modify_text = json.loads(modify_ree.text)
    print(f"modify_text -> {modify_text}")

    if modify_text[0]["value"] != "true" and modify_ree.status_code != 200:
        return
    # 删除zip包，重新打包
    url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/minio/modify"
    result = requests.get(url, timeout=TIMEOUT, verify=False)
    print(f"result -> {result}")
    if result.status_code != 200:
        return

if __name__ == '__main__':
    # updateCustomCon("8e5qyaucpj")
    # start(projectId="5teyfdjvnd", clients=500, haterace=10, times=30 * 60, loadmachines=10, label="3gxkrnvxsd", label_name="公共标签-新")
    
    stop("5teyfdjvnd")
    # # 参数赋值
    # projectId = options.project_id
    # haterace = options.haterace
    # clients = options.clients
    # times = options.times
    # label = options.label
    # label_name = options.label_name
    # loadmachines = options.loadmachines
    # sess.headers.update(header)
    # case_id = start(projectId=projectId, clients=clients, haterace=haterace, loadmachines=loadmachines,
    #                 times=times,label=label,label_name = label_name)