# coding:utf-8
import json
import optparse

import requests
from requests.adapters import HTTPAdapter

requests.packages.urllib3.disable_warnings()

SNAKE_URL = 'http://10.11.11.213:9966'

APPEND_API = 'api/v1'

# 设置Session
sess = requests.Session()
sess.mount(SNAKE_URL, HTTPAdapter(max_retries=10))
header = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Safari/537.36",
    "Authorization": "Bearer zhangpengfei@kingsoft.com",
    "Cookie":"email=zhangpengfei@kingsoft.com"
}

TIMEOUT = 60


def updateCustomCon(project_id, robot_index, skillid, SkillCastCD, num, stand):
    headers = sess.headers
    sess.headers = {}
    update_data = [
        {
            "name": "Configure",
            "value": "@true@"
        },
        {
            "label": "机器人类型",
            "name": "robot_index",
            "value": robot_index if robot_index else "21",
            "type": "Input"
        },
        {
            "label": "技能",
            "name": "skill_id",
            "value": skillid if skillid else "101141",
            "type": "Input"
        },
        {
            "label": "技能CD",
            "name": "SkillCastCD",
            "value": SkillCastCD,
            "type": "Input"
        },
        {
            "label": "拉起人数",
            "name": "Runner",
            "value": num,
            "type": "Input"
        },
        {
            "label": "是否站立不动",
            "name": "Stail",
            "value": stand,
            "type": "Input"
        }
    ]
    url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/file/presigned/url?file_name=.snake%2FcustomCom.json&ftype=case"
    result = sess.get(url, headers=header, verify=False)
    if result.status_code != 200:
        return False
    custom_url = json.loads(result.text)
    update_url = custom_url["upload_url"]
    result = sess.put(update_url,
                      data=str(update_data).replace("\'", "\"").replace("\"@", "").replace("@\"", "").encode("utf-8"),
                      verify=False,
                      )
    if result.status_code != 200:
        return False

    modify_url = custom_url["download_url"]
    result = sess.get(modify_url, timeout=TIMEOUT, verify=False)
    if result.status_code != 200:
        return False

    # 删除zip包，重新打包
    url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/minio/modify"
    result = sess.get(url, timeout=TIMEOUT, verify=False)
    if result.status_code != 200:
        return False

    sess.headers = headers
    print("updateCustomCon Success")
    return True


def usage():
    help = "python %prog"
    parser = optparse.OptionParser(help)
    # parser.add_option('-p', '--project_id', dest='project_id', type='string', help='project_id file', default="bvmtheclmu")  # 案例工程id
    parser.add_option('-c', '--clients', dest='clients', type='int', help='clients file', default=10) # 人数
    # parser.add_option('-n', '--haterace', dest='haterace', type='int', help='haterace file', default=10) # 上人速度
    # parser.add_option('-l', '--loadmachines', dest='loadmachines', type='int', help='loadmachines file', default=10) # 节点数量
    # parser.add_option('-a', '--label', dest='label', type='string', help='loadmachines file', default='3gxkrnvxsd') # 标签id
    parser.add_option('-t', '--time', dest='times', type='int', help='time', default=600)
    # parser.add_option('-e', '--email', dest='email', type='string', help='email', default="zhangpengfei@kingsoft.com")
    parser.add_option('-r', '--robotindex', dest='robot_index', type='string', help='robot_index', default="26")
    parser.add_option('-s', '--skillid', dest='skill_id', type='string', help='skill_id', default="101456")
    parser.add_option('-i', '--nMapCopyIndex', dest='map_copy_index', type='string', help='nMapCopyIndex', default="4")
    parser.add_option('--stand', '--stand', dest='stand', type='string', help='stand', default="false")
    parser.add_option('--cd', '--SkillCastCD', dest='SkillCastCD', type='int', help='SkillCastCD', default="2")
    parser.add_option('--stop', '--stop', dest='stop', type='string', help='stop', default="")
    options, args = parser.parse_args()

    # print("rule:", options.rule, options.__dict__)
    return options, args


options, args = usage()



def start(project_id, clients, haterace, loadmachines,  times, label, label_name, case_id="", monitor_logs="",
          monitor_logs_keys="",monitorservers="",):
    global sess, header
    if monitor_logs and monitor_logs_keys:
        start_data = {
            "casefile": "main.py",
            "clients": clients,
            "haterace": haterace,
            "label": label,
            "label_name": label_name,
            "loadmachines": loadmachines,
            "monitor_logs": monitor_logs,
            "monitor_logs_keys": monitor_logs_keys,
            "monitorservers": monitorservers,
            # "perf_type": "cpp",
            "projectid": project_id,
            "subtypes": [],
            "task_note": case_id,
            "timeout": times,
            "numberrequests": 1
        }
    else:
        start_data = {
            "casefile": "main.py",
            "clients": clients,
            "haterace": haterace,
            "label": label,
            "label_name": label_name,
            "loadmachines": loadmachines,
            "monitorservers": monitorservers,
            "perf_type": "cpp",
            "projectid": project_id,
            "subtypes": ["python3"],
            "task_note": case_id,
            "timeout": times,
            "numberrequests": 1
        }

    if not monitorservers:
        start_data.pop("monitorservers")
    image_url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/prepare/start"
    start_type = sess.get(image_url, headers=header, verify=False).text
    if start_type != 'true':
        check_url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/prepareimage/check"
        while True:
            check_code = sess.get(check_url, headers=header, verify=False).text
            if check_code and check_code != "1":
                break
            gevent.sleep(2)
    start_url = f"{SNAKE_URL}/{APPEND_API}/project/{project_id}/start"
    print({
        "request": start_url,
        "headers": header,
        "data": start_data,
        "sess.headers": sess.headers,
    })
    s = sess.post(start_url, data=json.dumps(start_data), headers=header, verify=False)
    print({
        "rsp:": (s.status_code, s.text)
    })
    if s.status_code != 201:
        return None
    try:
        task_id = json.loads(s.text)["uuid"]
        return task_id
    except:
        return None


def stop(sess,projectId):
    print("request:", f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/stop")
    res = sess.post(f"{SNAKE_URL}/{APPEND_API}/project/{projectId}/stop", verify=False)
    print("给你停掉了",{
        "rsp:": (res.status_code, res.text)
    })


if __name__ == '__main__':
    stop_judge = options.stop if options.stop else False
    map_copy_index = options.map_copy_index
    robot_index = options.robot_index
    skillid = options.skill_id
    map_copy_index_dict = {
        "1":"bvmtheclmu",
        "2": "4zvy4t4pzc",
        "3": "8tvc5fgda2",
        "4": "djjecfipyg",
        "5": "avym53i2by",
        "6": "8asavnlm4w",
        "7": "faanv8znpt",
        "8": "c29rzxeqyc",
    }
    # 参数赋值
    projectId = map_copy_index_dict[map_copy_index]
    haterace = 10
    clients = options.clients
    times = options.times
    label = "kigkgu3ubc"
    loadmachines = 2
    sess.headers.update(header)
    # 设置登录信息
    sess.headers.update({
        'K-USER-EMAIL': "zhangpengfei@kingsoft.com"
    })
    if stop_judge:
        stop(sess,map_copy_index_dict[map_copy_index])
    else:
        updateCustomCon(projectId, robot_index, skillid, options.SkillCastCD, clients, options.stand)
        case_id = start(project_id=projectId, clients=clients, haterace=haterace, loadmachines=loadmachines, times=times, label=label,label_name="高配节点")
