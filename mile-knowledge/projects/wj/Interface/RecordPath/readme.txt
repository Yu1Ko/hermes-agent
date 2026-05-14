
控制台输入	RecordPath.Start()  开启采集  该指令会删除之前采集的数据 请将数据文件备份后再处理
控制人物移动  此时就开始采集坐标 每隔200m采集一次坐标  可通过RecordPath.nRecordDistance自定义距离
控制台输入  RecordPath.Pause()  采集暂停
控制台输入  RecordPath.continue()  采集继续
控制台输入	RecordPath.Stop()   停止采集 
采集坐标结束  会在当前文件夹下看到  地图ID.tab文件  此文件就是采集的坐标