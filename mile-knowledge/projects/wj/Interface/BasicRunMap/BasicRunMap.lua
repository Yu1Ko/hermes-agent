LoginMgr.Log("BasicRunmap","BasicRunmap imported")
local BasicRunMap={}
BasicRunMap.bSwitch=true
local list_RunMapTime = {}
local list_RunMapCMD = {}
local nNextTime=30
local nCurrentTime=GetTickCount()
local nCurrentStep=1
local bIsAutoFly=false
local bFlag = true
local tbAutoFlay={}
BasicRunMap.bCircleSwitch=false
BasicRunMap.bVideoSwitch=false

SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."BeginRunMap")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."perfeye_stop")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."circle_start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."videoswitch_start")

--cmd 运行函数
function PlayerAutoFly(nNode1,nNode2)
    tbAutoFlay.nNode1=nNode1
    tbAutoFlay.nNode2=nNode2
    SendGMCommand(string.format("player.AutoFly(%d, %d)", nNode1, nNode2))
end

--处理未知弹窗
Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)

local player=nil
--帧更新函数
local function FrameUpdate()
    if not BasicRunMap.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    player = GetClientPlayer()

    --时间戳到
    if  bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        LOG.INFO(szCmd)
        if string.find(szCmd,"PlayerAutoFly") then 
            bIsAutoFly=true
            tbAutoFlay.nCurrentTime=GetTickCount()
        else
            bIsAutoFly=false
        end

        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
 
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        elseif string.find(szCmd,"circle_start") then
            BasicRunMap.bCircleSwitch=true
            Timer.AddFrameCycle(tbCircle,1,function ()
                tbCircle.Circle()
            end)
        elseif string.find(szCmd,"videoswitch_start") then
            BasicRunMap.bVideoSwitch=true
            Timer.AddFrameCycle(tbVideoSwitch,1,function ()
                tbVideoSwitch.SwitchVideo()
            end)
        elseif string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
            if BasicRunMap.bCircleSwitch then
                Timer.DelAllTimer(tbCircle)
                BasicRunMap.bCircleSwitch=false
            end
            if BasicRunMap.bVideoSwitch then
                Timer.DelAllTimer(tbVideoSwitch)
                BasicRunMap.bVideoSwitch=false
            end
        end
        LOG.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        LOG.INFO("BasicRunmap :"..szCmd..' ok')
        nNextTime=nTime
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    elseif bFlag and bIsAutoFly then
        if GetTickCount()-tbAutoFlay.nCurrentTime>2*1000 and player.nMoveState ~= 15 then
            PlayerAutoFly(tbAutoFlay.nNode2,tbAutoFlay.nNode1)
            tbAutoFlay.nCurrentTime=GetTickCount()
        end
    end
end


--加载tab文件
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD=tbRunMapData[1]
list_RunMapTime=tbRunMapData[2]
--启动帧更新函数
Timer.AddFrameCycle(BasicRunMap,1,function ()
    FrameUpdate()
end)

LoginMgr.Log("BasicRunmap","BasicRunmap End")
return BasicRunMap