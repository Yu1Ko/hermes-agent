import time
import pyfeishu  

class Throw_Advice(object):
    _instance = None
    def __new__(self, *args, **kw):
        if self._instance is None:
            self._instance = object.__new__(self, *args, **kw)
            self._instance.init_data()
        return self._instance
    def __init__(self):
        pass
    def init_data(self):
        print("初始化参数")
        self.project="XX"
        self.device="XX"
        self.device_name="空"
        self.case_name="未开始"
        self.bot=None
        self.taskrunid=None
        self.taskname=""
        self.game_v='0'
        self.platform = ""
        
    def set_data(self,webhook,project,device,device_name,taskrunid,taskname,game_v,platform):
        self.project=project
        self.device=device
        self.device_name=device_name
        self.taskrunid=taskrunid
        self.taskname=taskname
        self.game_v=game_v
        self.platform = platform
        self.bot=pyfeishu.FeiShutalkChatbot(webhook)

    def set_casename(self,case_name):
        self.case_name=case_name

    def get_json_data(self, data, *user):
        try:
            user_str = ""
            pic_str = ""

            if len(user) > 0:
                for u in user:
                    if u == "所有人":
                        user_str = user_str + f"<at user_id=\"-1\">所有人</at>"
                    else:
                        user_str = user_str + f"<at email=\"{u}\"></at>"

            try:
                img_key = self.bot.get_img_key(self.device, self.platform)
            except:
                img_key = ""
                print("截图失败")
            print(img_key)
            if img_key != "":
                pic_str = f"\n\n   [截图]({img_key})"

            msg = {
                "msgtype": "markdown",
                "markdown": {
                    "text": f"# <font color='red'>【通知】{self.project}-任务异常</font>\n"
                            f"----  \n"
                            f"**🗂️ 任务：** {self.taskname}-GV_{self.game_v}  \n"
                            f"**🔢 案例：** {self.case_name}  \n"
                            f"**📋 设备：** {self.device_name}-{self.device}  \n"
                            f"**👤 通知人：** {user_str}  \n"
                            f"异常描述：{data}  \n"
                            f"--------------  \n"
                            f"{pic_str}  \n"
                            f"[跳转到自动化平台 查看详情](https://uauto2.testplus.cn/project/tgame/taskDetail?taskId={self.taskrunid})",
                }
            }
            print(msg)
            return self.bot.post(msg)
        except Exception as e:
            print("预警发送失败", e)

    def send_text(self, msg, users=None):
        if users != None and len(users) > 0 :
            atuser = users
        else:
            atuser = "所有人"
        if self.bot != None:
            data = self.get_json_data(msg, *atuser)
            print(data)
        else:
            print("金山协助模块未实例化")

# webhook="https://open.feishu.cn/open-apis/bot/v2/hook/c6bc19a5-611a-4b4d-b013-baa5dfec7a64"
# project="mecha"
# device="a426d6b5"
# device_name="测试机"
# taskrunid=5345
# taskname="测试"
# game_v="123"
# Throw_Advice().set_data(webhook,project,device,device_name,taskrunid,taskname,game_v,"PC") #初始化

# Throw_Advice().set_casename("测试案例")#更新测试案例
# print(Throw_Advice().send_text("xxxxxxxxxxx出现问题-请查看")) #调用发送接口
        
