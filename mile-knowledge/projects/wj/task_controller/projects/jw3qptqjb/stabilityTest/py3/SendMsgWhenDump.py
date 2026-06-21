import json

import requests

web_hook = "https://open.feishu.cn/open-apis/bot/v2/hook/c1b7b045-7deb-4005-bd91-42e0c2b2f003"


# 简单的信息
def push_report(ip_machine, info):
    msg = ip_machine + info
    message = {
    "msg_type": "text",
    "content": {
        "text": "<at user_id='all'>所有人</at>" + msg
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))

    print(response.text)