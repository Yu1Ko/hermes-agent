import json
import requests


class SendMsgRobot(object):
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

    # markdown\(富文本)信息
    def push_interactive_report(self, ip_machine, case_name, msg_content, log_path):
        log_summary = ''
        with open(log_path, 'r') as f:
            log_content = f.readlines()
            for i in range(10):
                try:
                    log_summary += log_content[i]
                except IndexError:
                    break  # 文件行数不足时提前退出

        message = {
            "msgtype": "markdown",
            "markdown": {
                "text": "## <font color='red'>【" + ip_machine + "】" + case_name + "</font>\n\n" + "<at user_id=\"-1\">所有人</at>" + msg_content + "\n>" + log_summary,

            }
        }
        headers = {
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", self.web_hook, headers=headers, data=json.dumps(message))

if __name__ == "__main__":
    web_hook = r"https://xz.wps.cn/api/v1/webhook/send?key=8ec0c8a2b134fe7a9e0c77bebe3dc79d"
    test = SendMsgRobot(web_hook)
    test.push_report("10.11.144.71", "aaa")
