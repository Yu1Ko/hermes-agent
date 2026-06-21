import os
from CaseJX3SearchPanel import CaseJX3SearchPanel
from CaseJX3Client import *
from PerfeyeCtrl import *
from HotPointMapCtrl import *
from XGameSocketClient import *


class engineStandardization(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()  # 父类初始化

    def copyEnvToClient(self):
        TEMP_FOLDER = os.path.join(GetTEMPFOLDER(), "mui")
        SFXconfigfile = r"\\10.11.85.148\FileShare\xiejieshi\RunTab\引擎标准化\特效数包外配置\mui"
        filecontrol_copyFileOrFolder(SFXconfigfile, TEMP_FOLDER)  # 先拷贝到本机
        self.log.info(f"{SFXconfigfile} 拷贝到 {TEMP_FOLDER}")
        # 导入画质配置文件到游戏客户端
        filecontrol_copyFileOrFolder(TEMP_FOLDER, self.CLIENT_PATH, self.deviceId, self.package)
        super().copyEnvToClient()


def AutoRun(dic_parameters):
    global obj_test
    obj_test = engineStandardization()
    obj_test.run_from_uauto(dic_parameters)


if __name__ == '__main__':
    obj_test = engineStandardization()
    obj_test.run_from_IQB()
