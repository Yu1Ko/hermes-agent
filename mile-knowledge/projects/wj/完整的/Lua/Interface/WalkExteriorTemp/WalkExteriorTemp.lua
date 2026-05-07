WalkExterior = {}
TraverseExterior = {}
WalkExterior.nLine = 0
WalkExterior.bSwitch=true
local szHead="nSet\tszSetName\n"
local szFilePath=SearchPanel.szCurrentInterfacePath.."Exterior.tab"
local szContent=""
WalkExterior.nTime = 10000        -- 默认5000（毫秒）换装
WalkExterior.nstarTime = 0       -- 初始化时间
local list_RunMapCMD = {}
local list_RunMapTime = {}
local bFlag = true
local file=io.open(szFilePath,"w")
file:write(szHead)
file:close()
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
--SearchPanel.tbModule['AutoLogin'].SetAutoLoginInfo(nil,nil,'纯阳','成男')
-- 总长度
WalkExterior.nLine = 1

-- 角色自转
local PlayerTurnTo = {}
PlayerTurnTo.bSwitch = true
PlayerTurnTo.bCircle = false
PlayerTurnTo.Line = 20
PlayerTurnTo.nStartTime = 0
PlayerTurnTo.nNextTime = 5
function PlayerTurnTo.FrameUpdate()
    if PlayerTurnTo.Line == 280 then
        PlayerTurnTo.Line = 20
        return
    end
    TurnTo(PlayerTurnTo.Line)
    PlayerTurnTo.Line = PlayerTurnTo.Line + 2
end

-- 镜头调整 全身镜头->半身镜头->全身镜头
CameraPlayer={}
CameraPlayer.bSwitch = true
CameraPlayer.bFlag = false
CameraPlayer.nCameraLine = 1
CameraPlayer.nStartTime = 0
CameraPlayer.nNextTime = 1
CameraPlayer.tbPlayer = {1,0,1}
function CameraPlayer.FrameUpdate()
    if GetTickCount() - CameraPlayer.nStartTime >= CameraPlayer.nNextTime*1000 then --间隔1秒
        -- body
        if PlayerTurnTo.Line == 20 then
            if CameraPlayer.nCameraLine == #CameraPlayer.tbPlayer+1 then
                CameraPlayer.bFlag = false
                Timer.DelAllTimer(CameraPlayer)
                CameraPlayer.nCameraLine =1
                WalkExterior.nLine = WalkExterior.nLine + 1
                WalkExterior.nstarTime=GetTickCount()
                return
            end
            CameraMgr.Zoom(CameraPlayer.tbPlayer[CameraPlayer.nCameraLine])
            CameraPlayer.nCameraLine = CameraPlayer.nCameraLine + 1
            CameraPlayer.nStartTime = GetTickCount()
        end
    end
end

local nSetName
local nSetID
-- 更换外观
function WalkExterior.TraverseExterior()
    if not WalkExterior.bSwitch then
        return
    end
    if not PlayerTurnTo.bCircle then
        Timer.AddFrameCycle(PlayerTurnTo,1,function ()
            PlayerTurnTo.FrameUpdate()
        end)
        PlayerTurnTo.bCircle = true
    end
    local currentTime = GetTickCount() -- 单位毫秒
    if not CameraPlayer.bFlag and currentTime - WalkExterior.nstarTime >= WalkExterior.nTime then --间隔500毫秒
        if WalkExterior.nLine == 5 then
            bFlag = true
            Timer.DelAllTimer(TraverseExterior)
            TraverseExterior.IsRun=false
            AutoTestLog.INFO("TraverseExterior Stop")
        end
        WalkExterior.nstarTime = currentTime
        if CameraPlayer.bSwitch then
            Timer.AddFrameCycle(CameraPlayer,1,function ()
                CameraPlayer.FrameUpdate()
            end)
            CameraPlayer.bFlag = true
        end
    end
end

local nCurrentTime = GetTickCount()
local nNextTime=tonumber(30)
local nCurrentStep=1
local player=nil
local function FrameUpdate()
    if not WalkExterior.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    player = GetClientPlayer()

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
        if string.find(szCmd,"WalkExterior start") then
            --启动外装帧更新函数
            Timer.AddFrameCycle(TraverseExterior,1,function ()
                WalkExterior.TraverseExterior()
            end)
            bFlag = false
        end
        if string.find(szCmd,"abc") then
            --启动外装帧更新函数
            Timer.AddCycle(TraverseExterior,40,function ()
                SendGMCommand("player.DoEmotionAction(399);player.CastSkill(41589,1)")
            end)
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(WalkExterior,1,function ()
    FrameUpdate()
end)


return WalkExterior