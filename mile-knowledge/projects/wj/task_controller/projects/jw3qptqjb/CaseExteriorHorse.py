from CaseJX3SearchPanel import *


class CaseExteriorHorse(CaseJX3SearchPanel):

    def __init__(self):
        super().__init__()

    def processSearchPanelTab(self, dic_args):
        strSrc = os.path.join(SERVER_PATH, 'XGame', 'RunTab', dic_args['casename'])
        strTabPath = os.path.join(GetTEMPFOLDER(), 'Interface', self.runMapType)
        strTabPath = os.path.join(strTabPath, 'RunMap.tab')
        filecontrol_copyFileOrFolder(strSrc, strTabPath)
        # 修改RunMap里面_itemId_值
        changeStrInFile(strTabPath, "_itemId_", str(dic_args['ItemId']))
        super().processSearchPanelTab(dic_args)

    def teardown(self):
        super().teardown()


def AutoRun(dic_parameters):
    global obj_test
    obj_test = CaseExteriorHorse()
    obj_test.run_from_uauto(dic_parameters)
