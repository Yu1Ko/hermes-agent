import json

import requests


def push_report(ip_machine, msg_content):
    web_hook = "https://open.feishu.cn/open-apis/bot/v2/hook/bfafa1eb-a215-44c3-bd55-2eb034eddca5"
    msg = "【" + ip_machine + "】: " + msg_content
    message = {
        "msg_type": "text",
        "content": {
            "text": msg,
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))

    # print(response.text)


def push_rich_report(ip_machine, CaseName, msg_content):
    web_hook = "https://open.feishu.cn/open-apis/bot/v2/hook/bfafa1eb-a215-44c3-bd55-2eb034eddca5"
    # msg = "【" + ip_machine + "】: " + msg_content
    message = {
        "msg_type": "interactive",
        "card": {
            "elements": [{
                "tag": "div",
                "text": {
                    "content": msg_content,
                    "tag": "lark_md"
                }
            }],
            "header": {
                "template": "green",
                "title": {
                    "content": "【" + ip_machine + "】" + CaseName,
                    "tag": "plain_text"
                }
            }
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))


def push_interactive_report(ip_machine, CaseName, msg_content, log_path):
    with open(log_path, 'r') as f:
        log_content = f.read()

    web_hook = "https://open.feishu.cn/open-apis/bot/v2/hook/bfafa1eb-a215-44c3-bd55-2eb034eddca5"
    # msg = "【" + ip_machine + "】: " + msg_content
    message = {
        "msg_type": "interactive",
        "card": {
            "elements": [
                {
                    "tag": "div",
                    "text": {
                        "content": msg_content,
                        "tag": "lark_md"
                    }
                },
                {
                    "tag": "action",
                    "actions": [
                        {
                            "tag": "select_static",
                            "placeholder": {
                                "tag": "plain_text",
                                "content": "查看内容"
                            },
                            "options": [
                                {
                                    "text": {
                                        "tag": "lark_md",
                                        "content": log_content
                                    },
                                    "value": log_content
                                }
                            ]
                        }
                    ]
                }
            ],
            "header": {
                "template": "red",
                "title": {
                    "content": "【" + ip_machine + "】" + CaseName,
                    "tag": "plain_text"
                }
            }
        }
    }
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", web_hook, headers=headers, data=json.dumps(message))
