# -*- coding: utf-8 -*- 
from CaseCommon import * #基类
from BaseToolFunc import * #提供了常用的功能函数封装，建议使用里面的函数，可提前阅读了解有哪些功能

class CaseDemo(CaseCommon): #用例名字需要和文件名一致！ 所有用例需要继承CaseCommon类

    def __init__(self):
        super().__init__() #父类初始化

    def run_local(self, dic_args):  #用例的主体（入口）函数，dic_args是从IQB平台传来的参数字典

        with open('c:/CaseDemo.txt', 'w') as f:  #这里演示是在目标机器的c盘创建一个文件，运行完后，看看你的测试机是不是生成了这个文件？
            pass

        self.log.error('CaseDemo Test1')  # 故意写一条错误日志，可以在飞书接收到即时反馈，且本地运行目录下会写log
        send_Subscriber_msg(machine_get_guid(), 'CaseDemo给你发送一条微信消息') #在IQB订阅IP的机器后能收到此消息
        time.sleep(5)
        self.log.error('CaseDemo Test2')
        

# main函数，必不可少
if __name__ == '__main__':
    obj = CaseDemo() #对象初始化
    obj.run_from_IQB() #这是固定写法，当iqb启动此用例时，会自动传递参数
    # obj.run_local({}) #如果不通过iqb运行用例，可以使用本行方法自己传参数，用于本地调式
