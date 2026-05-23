在RunMap.tab中设置进行前置操作和后置操作
/cmd CreateEmptyFile("SwitchMap start") -- 启动切图

在Config_SwitchMap.ini中增加地图坐标
[Count]
MapIDNum=34		-- 地图总数
[MapID]
1=1,6589, 36591,1076928	-- 切图点位编号
2=5,4839,16015,1048256 

在SwitchMap.ini设置切图时间和起始中止地图
[SwitchMap]
SwitchMapWaitTime=5    --切图等待时间
MapStart=1              --起始地图
MapEnd=10               --最终地图
OptionalMap=0           --是否启用自定义地图1是0否
[SwitchVideo]
VideoSwitch=1        --切换画质开关（0为关闭）
SwitchVideoWaitTime=20  --切画质等待时间
VideoMax=3              --切图画质可达的最高画质
VideoMin=1              --切图画质可达的最低画质