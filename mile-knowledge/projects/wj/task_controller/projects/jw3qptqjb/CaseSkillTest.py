# -*- coding: utf-8 -*-
import os
import time
import sys

from CaseJX3SearchPanel import *


class CaseSkillTest(CaseJX3SearchPanel):

    def __init__(self):
        super().__init__()
        self.nKungfu = None
        self.nSkillID = None
        self.strMapCopyIndex = None
        self.nSkillType = 1  #切换vk-dx 1:vk 2:dx
        self.nSkillXinFa = 1  # 切换心法1、2、3
        self.strPreSkillId = ''  #部分技能释放需要释放前置技能
        # CtrlPerfMon.__init__(self)
        # key 地图id value  左下角  右上角

    def processSearchPanelTab(self, dic_args):
        self.nKungfu = int(dic_args['kungfu'])
        self.nSkillID = int(dic_args['skillID'])
        self.nSkillType = dic_args.get("skillType", 1)
        self.nSkillXinFa = dic_args.get("skillXinFa", 1)
        self.strPreSkillId = dic_args.get('preSkillID', "")
        #skilltype=2,xinfa>=2时  BtnSwitchXinFa=2,其余都为1
        nBtnSwitchXinFaIndex = 1
        if int(self.nSkillType) == 2 and int(self.nSkillXinFa) >= 2:
            nBtnSwitchXinFaIndex = 2

        # self.nMapIndex= int(dic_args['mapIndex']) 废弃
        # 现在每台手机一个副本地图，这里mapCopyIndex是1~8任意数字，目前只支持最多8台手机，需要扩展找叶海峰
        self.strMapCopyIndex = dic_args["devices_custom"]['skilltest']['mapCopyIndex']

        if int(self.strMapCopyIndex) not in [1, 2, 3, 4, 5, 6, 7, 8]:
            self.log.error('mapCopyIndex 配置有误')
            return

        # 获取本地python执行路径
        pyPath = sys.executable

        # 执行脚本
        snakeScript = os.path.join(os.getcwd(), "projects\jw3qptqjb\snake_runner_wujie.py")
        self.log.info(pyPath)
        self.log.info(snakeScript)
        strStand='fasle'
        if 'stand' in self.args and self.args['stand']:
            strStand='true'
        #stop一下
        requestMsg=subprocess.run([pyPath, snakeScript,
                        "-r", str(self.nKungfu),  # 机器人配置
                        "-s", str(self.nSkillID),  # 技能id
                        #"-i", str(self.strMapCopyIndex),  # 启动几线的机器人
                        "--cd", "10",  # 技能冷却时间 固定
                        "--stop", str(self.strMapCopyIndex),  # 停掉几线的机器人
                        "-t", "900",  # 机器人运行多久 让他自己停下来就行
                        '-c', "10",  # 拉起人数10
                        '--stand', strStand,  # 机器人是否站立不动, true为真, false为假
                        ])

        self.log.info(requestMsg)
        time.sleep(2)

        requestMsg=subprocess.run([pyPath, snakeScript,
                        "-r", str(self.nKungfu),  # 机器人配置
                        "-s", str(self.nSkillID),  # 技能id
                        "-i", str(self.strMapCopyIndex),  # 启动几线的机器人
                        "--cd", "10",  # 技能冷却时间 固定
                        # "--stop", str(self.strMapCopyIndex),  # 停掉几线的机器人
                        "-t", "900",  # 机器人运行多久 让他自己停下来就行
                        '-c', "10",  # 拉起人数10
                        '--stand', strStand,  # 机器人是否站立不动, true为真, false为假
                        ])

        # # 启动机器人
        # requestMsg = subprocess.run([pyPath, snakeScript,
        #                 "-r", str(self.nKungfu),  # 机器人配置
        #                 "-s", str(self.nSkillID),  # 技能id
        #                 "-i", str(self.strMapCopyIndex),  # 启动几线的机器人
        #                 "-t", "900",  # 机器人运行多久 默认15分钟
        #                 ])

        self.log.info(requestMsg)
        strSrc = os.path.join(SERVER_PATH, 'XGame', 'RunTab', dic_args['casename'])
        strTabPath = os.path.join(GetTEMPFOLDER(), 'Interface', self.runMapType)
        strTabPath = os.path.join(strTabPath, 'RunMap.tab')
        filecontrol_copyFileOrFolder(strSrc, strTabPath)
        changeStrInFile(strTabPath, '_mapIndex_', str(self.strMapCopyIndex))
        changeStrInFile(strTabPath, '_SkillId_', str(self.nSkillID))
        if self.strPreSkillId != '' or self.strPreSkillId != 0:
            changeStrInFile(strTabPath, '_preSkillId_', self.strPreSkillId)

        changeStrInFile(strTabPath, '_SkillType_', str(self.nSkillType))
        changeStrInFile(strTabPath, '_SkillXinFa_', str(self.nSkillXinFa))
        changeStrInFile(strTabPath, '_BtnSwitchXinFa_', str(nBtnSwitchXinFaIndex))

        super().processSearchPanelTab(dic_args)

    def teardown(self):
        try:
            # 获取本地python执行路径
            pyPath = sys.executable

            # 执行脚本
            snakeScript = os.path.join(os.getcwd(), "projects\jw3qptqjb\snake_runner_wujie.py")
            requestMsg = subprocess.run([pyPath, snakeScript,
                                         "-r", str(self.nKungfu),  # 机器人配置
                                         "-s", str(self.nSkillID),  # 技能id
                                         #"-i", str(self.strMapCopyIndex),  # 启动几线的机器人
                                         "--cd", "10",  # 技能冷却时间 固定
                                         "--stop", str(self.strMapCopyIndex),  # 停掉几线的机器人 最多等待5分钟
                                         "-t", "1200",  # 机器人运行多久 让他自己停下来就行
                                         '-c', "10",  # 拉起人数10
                                         '--stand', 'false',  # 机器人是否站立不动, true为真, false为假
                                         ])
            self.log.info(requestMsg)
        except:
            info = traceback.format_exc()
            self.log.info(info)
        # finally:
        #     sleep_heartbeat(4) #等待机器人停掉
        super().teardown()
        # 结束进程


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseSkillTest()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = CaseSkillTest()
    obj_test.run_from_IQB()
