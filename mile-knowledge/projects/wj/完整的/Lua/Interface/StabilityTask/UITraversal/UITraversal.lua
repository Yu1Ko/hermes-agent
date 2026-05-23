UITraversal={}
UITraversal.bSwitch=true
--读取UICMD文件
local tbUIData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."UITraversal/GMInstruct.tab",2)
local list_UICMD = tbUIData[1]
local list_UITime = tbUIData[2]
local nUIStartTime = 0
local nUINextTime=tonumber(5)
local nUILine=1
local NumberCycles = 1  -- 循环的次数
local nUINumber = 0     -- 遍历的轮数
function UITraversal.FrameUpdate()
    if not UITraversal.bSwitch then
        return
    end
    if GetTickCount()-nUIStartTime>nUINextTime*1000 then
        if nUILine==#list_UICMD+1 then
            if nUINumber == NumberCycles then
                -- 遍历完成后 关闭UI遍历帧函数
                Timer.DelAllTimer(UITraversal)
                StabilityController.bFlag = true
	            return
            end
            nUILine = 1
            nUINumber = nUINumber+1
        end
        --执行操作
        local szCmd=list_UICMD[nUILine]
        local nUITime=tonumber(list_UITime[nUILine])
        LoginMgr.Log("szCmd",UTF8ToGBK(szCmd))
        LoginMgr.Log("szCmd",nUILine)
        local bCmd = SearchPanel.RunCommand(szCmd)
        nUINextTime=nUITime
        nUIStartTime=GetTickCount()
        nUILine=nUILine+1
    end
end

function UITraversal.Start()
    Timer.AddFrameCycle(UITraversal,1,function ()
        UITraversal.FrameUpdate()
    end)
end