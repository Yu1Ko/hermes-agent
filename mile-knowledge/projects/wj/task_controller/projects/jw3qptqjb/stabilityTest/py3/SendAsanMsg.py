from SubscriberClient import *

ASAN_KEYWORDS = "Asan内存安全检查"  # 订阅的关键字


class SendAsanMsg(SubscriberClient):
    def __init__(self):
        super().__init__()

    def push_report(self, ip_machine, msg_content):   # 文本
        message = "<at user_id=\"-1\">所有人</at>\n" + "【" + ip_machine + "】: " + msg_content
        self.send_text(message)

    def push_markdown_report(self, ip_machine, CaseName, msg_content, log_path):  # markdown
        log_summary = ''
        with open(log_path, 'r') as f:  # 读取共享上面的日志文件内容
            log_content = f.readlines()
            for line in range(0, 10):
                log_summary = log_summary + log_content[line]

        message = "## <font color='red'>【" + ip_machine + "】" + CaseName + "</font>\n\n" + "<at user_id=\"-1\">所有人</at>" + msg_content + "\n>" + log_summary
        self.send_text(message, markdown=True)

#     def run_send_msg(self):
#         push_interactive_report()
#
#
# if __name__ == '__main__':
#     oob = SendAsanMsg()
#     oob.run_send_msg()
