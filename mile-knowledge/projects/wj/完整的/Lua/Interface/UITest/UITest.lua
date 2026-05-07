UITest={}
local tbUI ={1305,1306,800001}
local bFlag = true
UITest.nLine = 1
UITest.nNext = 1
UITest.nTimeCount=0
function UITest.FrameUpdate()
    if UITest.nTimeCount == 3600 then
        Timer.DelAllTimer(UITest)
        bFlag=true
        return
    end
    if UITest.nNext == 1 then
        if UITest.nLine == 3 then
           TipsHelper.ShowClickHoverTips(1, 10, 12)
        else
            UIMgr.Open(tbUI[UITest.nLine])
        end
        UITest.nNext = 2
    else
        UIMgr.Close(tbUI[UITest.nLine])
        UITest.nNext = 1
        if UITest.nLine == 3 then
            UITest.nLine = 1
        else
            UITest.nLine = UITest.nLine + 1
        end
    end
    UITest.nTimeCount = UITest.nTimeCount + 5
end



--读取tab的内容 
local RunMap = {}
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

-- 切图的前后置操作 这部分实现模块化后直接去除
function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"UITest") then
            --启动切图帧更新函数
            Timer.AddCycle(UITest,5,function ()
                UITest.FrameUpdate()
            end)
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)
