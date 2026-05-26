
from CaseJX3SearchPanel import *

class CaseJX3Point(CaseJX3SearchPanel):

    def Fill_in_dic_args(self, dic_args):  # 填参数
        dic_args['testpoint'] = 'point'
        dic_args['nTimeout'] = 600
        if 'classic' in dic_args['clientType']:
            dic_args['casename'] = 'Point_classic.tab'
        else:
            dic_args['casename'] = 'Point.tab'
        dic_args['mapid'] = self.map_id

    def check_dic_args(self, dic_args):
        def dealPointData(path):
            id = dic_args['id']
            pointinfo = {}
            if os.path.exists(path):
                with open(path, 'r', encoding='utf-8') as file:
                    file.readline()  #跳过第一行
                    for line in file:
                        setCameraStatus = line.split('"')[1]
                        setPosition = line.split('"')[3]
                        list_data = line.replace("\t", ",").strip().split(",")
                        pointinfo[list_data[0]] = (list_data[1], list_data[2], setCameraStatus, setPosition)
            self.map_id = pointinfo[id][1]
            self.setCameraStatus = pointinfo[id][2]
            self.setPosition = pointinfo[id][3]

        if 'id' in dic_args:
            pointdatapath = os.path.join('CaseJX3Client-Attachment', 'SearchPanel', 'PointData.tab')
            dealPointData(pointdatapath)
        else:
            self.setCameraStatus = dic_args['setCameraStatus']
            self.setPosition = dic_args['setPosition']
        self.Fill_in_dic_args(dic_args)
        super().check_dic_args(dic_args)
        if 'namePosition' in dic_args:  #地图地点名，当两个用例在同一个地图时使用
            self.mapname = dic_args['namePosition']

    def processSearchPanelTab(self, dic_args):
        super().processSearchPanelTab(dic_args)
        Position = self.setPosition
        CameraStatus = self.setCameraStatus

        sChange2 = []
        sChange2.append(['_Pos_', Position])
        sChange2.append(['_Cam_', CameraStatus])

        dst = os.path.join(self.SEARCHPANEL_PATH, 'RunMap.tab')

        for each_yield in sChange2:  # 修改'RunMap.tab'的内容，
            changeStrInFile(dst, each_yield[0], each_yield[1])

if __name__ == '__main__':
    obj_test = CaseJX3Point()
    obj_test.run_from_IQB()




