import json
import requests


class SendMsgToRobot(object):
    def __init__(self, web_hook):
        self.web_hook = web_hook

    # 简单的信息
    def push_report(self, ip_machine, msg_content):
        msg = "【" + ip_machine + "】: " + msg_content  # 【机器名】信息
        message = {
            "msgtype": "text",
            "text": {
                "content": "<at user_id=\"-1\">所有人</at>\n" + msg
            }
        }

        headers = {
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", self.web_hook, headers=headers, data=json.dumps(message))

        print(response.text)

    def push_msg_report(self, ip_machine, msg_content, log_path):
        log_summary = ''
        with open(log_path, 'r') as f:  # 读取共享上面的日志文件内容
            log_content = f.readlines()
            for line in range(0, 10):
                log_summary = log_summary + log_content[line]

        msg = "【" + ip_machine + "】: " + msg_content  # 【机器名】信息
        message = {
            "msgtype": "markdown",
            "markdown": {
                "text": "<at user_id=\"-1\">所有人</at>\n" + msg + log_path + "\n\n>" + log_summary
            }
        }

        headers = {
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", self.web_hook, headers=headers, data=json.dumps(message))

        print(response.text)

    # markdown\(富文本)信息
    def push_interactive_report(self, ip_machine, CaseName, msg_content, log_path):
        log_summary = ''
        with open(log_path, 'r') as f:  # 读取共享上面的日志文件内容
            log_content = f.readlines()
            for line in range(0, 10):
                log_summary = log_summary + log_content[line]

        message = {
            "msgtype": "markdown",
            "markdown": {
                "text": "## <font color='red'>【" + ip_machine + "】" + CaseName + "</font>\n\n" + "<at user_id=\"-1\">所有人</at>" + msg_content + "\n>" + log_summary,

            }
        }
        headers = {
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", self.web_hook, headers=headers, data=json.dumps(message))
