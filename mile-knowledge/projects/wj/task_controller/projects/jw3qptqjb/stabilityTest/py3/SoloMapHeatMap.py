#-*-coding=utf-8-*-
import os

#设置跑图间隔时间
nStepTime=0.2

nStepTimePos=1
#设置地图ID
#稻香村 1
#七秀   16
#万花   2
nMapId=16

#设置跑图间隔距离
nDistance=700

path=r"E:\trunk_mobile\client\mui\Lua\Result_稻香村.tab"

begin_string=u'''/cmd CreateEmptyFile("BeginRunMap")	1	标记：开始跑
/cmd KG3DEngine.SetMobileEngineOption(GameQualitySetting._video_)	5	设置画质
/cmd KG3DEngine.SetMobileEngineOption(GameQualitySetting._video1_)	5	切换原本画质
/gm player.SwitchMap(_mapid_, 0, 0, 0)	30	传送
/gm player.Revive()	5	复活
/gm player.Stop()	5	停止
/cmd CreateEmptyFile("HotPoint_Start")	5	信号：开始\n'''

end_string=u'''/cmd CreateEmptyFile("HotPoint_End")	20	信号：结束
/cmd CreateEmptyFile("ExitGame")	2	关闭游戏'''

Towards_string = u'''/cmd SetCameraStatus(2000, 1, 1.570, -0.217)	{x}	调整面向东
/cmd SetCameraStatus(2000, 1, 3.140, -0.217)	{x}	调整面向南
/cmd SetCameraStatus(2000, 1, 4.710, -0.217)	{x}	调整面向西
/cmd SetCameraStatus(2000, 1, 6.280, -0.217)	{x}	调整面向北\n'''.format(x=nStepTime)

def my_write(fp,tupe_1_1,tupe_max_max, tupe_distance):
    if  tupe_1_1[0]> tupe_max_max[0] or tupe_1_1[1]> tupe_max_max[1]:
        print('argument error!,first argument must 1*1 point')
        return

    #x_unit_length = int(( tupe_max_max[0] - tupe_1_1[0])/distance)
    #y_unit_length = int((tupe_max_max[1] - tupe_1_1[1])/distance)
    fp.write(begin_string)
    list_tab=tab_read(path)

    for index in range(len(list_tab[0])):
        fp.write("/gm player.SetPosition({x},{y},{z})	1	{x},{y}\n".format(x=list_tab[0][index], y=list_tab[1][index],z=list_tab[2][index]))
        fp.write(Towards_string)
        print(list_tab[0][index], list_tab[1][index], list_tab[2][index])

    fp.write(end_string)

def edit(tupe_1_1,tupe_max_max,distance):
    
    with open('SoloMap_heatmap.tab','w') as fp:
        my_write(fp,tupe_1_1,tupe_max_max, distance)

def computeSplitCount(tupe_min_x_y, tupe_max_x_y):
    xx = 0
    yy = 1
    split_x = (tupe_max_x_y[xx] - tupe_min_x_y[xx])/nDistance
    split_y = (tupe_max_x_y[yy] - tupe_min_x_y[yy])/nDistance
    print("x={x},y={y}".format(x=split_x,y=split_y))
    return (int(split_x), int(split_y))

def main(tupe_1_1,tupe_max_max):
    tupe_distance = computeSplitCount(tupe_1_1,tupe_max_max)
    print(tupe_distance)
    edit(tupe_1_1, tupe_max_max, tupe_distance)


def tab_read(szPath):
    dict_json_data = [[],[],[]]
    with open(szPath, 'r') as f:
        read_table_conent = f.read()
    list_line_data = read_table_conent.split('\n')  # 获取每一行
    length_line=len(list_line_data[0].split('\t'))
    for line_data_index in range(len(list_line_data)):
        list_row_data = list_line_data[line_data_index].split('\t')  # 将每一行内容按 \t分割，获取每一列的内容
        if len(list_row_data) < length_line:
            continue
        else:
            for index in range(length_line):  # 按照表头数组的顺序，将数据 一一对应append 进dict
                dict_json_data[index].append(int(list_row_data[index]))
    return dict_json_data

if __name__ == "__main__":
    #左下角和右上角边界
    #稻香村
    #main((1607, 7975),(28363,28898))
    #七秀
    main((2836,6864),(98944, 91624))