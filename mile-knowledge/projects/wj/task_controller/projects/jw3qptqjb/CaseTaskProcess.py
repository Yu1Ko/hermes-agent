from CaseJX3SearchPanel import *


class CaseTaskProcess(CaseJX3SearchPanel):
    def __init__(self):
        super().__init__()
        # 执行任务的id
        self.strTaskName = None

        # 任务流程需要拷贝数据文件

    def processSearchPanelTab(self, dic_args):
        if self.runMapType == 'MainTask':
            self.strTaskName = dic_args['TaskName']
            strServerPath = SERVER_PATH + f'\XGame\RunTab\任务流程\{self.strTaskName}.tab'
            strLocalPath = f"{GetTEMPFOLDER()}{os.sep}Interface{os.sep}{self.runMapType}{os.sep}RunMapTask.tab"
            self.log.info(f"任务流程特定文件处理 server:{strServerPath},local:{strLocalPath}")
            filecontrol_copyFileOrFolder(strServerPath, strLocalPath)
        super().processSearchPanelTab(dic_args)

    def teardown(self):
        super().teardown()


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseTaskProcess()
    obj_test.run_from_uauto(dic_parameters)


