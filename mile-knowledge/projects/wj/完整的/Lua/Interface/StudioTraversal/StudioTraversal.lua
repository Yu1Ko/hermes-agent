StudioTraversal = {}
ExteriorList={}
ExteriorList.nCount = 0
ExteriorList.Line =1
local tbExteriorData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."Exterior.tab",2)
ExteriorList.nCount = #tbExteriorData[1]
local bFlag = true
function ExteriorList.GetExterior()
    for i=1,ExteriorList.nCount do
        table.insert(ExteriorList,tbExteriorData[1][i])
    end
    SearchExterior.InitTools()
    SearchHair.InitTools()
    PlayerData.GetClientPlayer().HideHat(not false)
end

function ExteriorList.SetLine(nCount)
    ExteriorList.nCount = tonumber(nCount)
end


-- 切换场景 3
function StudioTraversal.SetScene(nIndexScene)
    if nIndexScene==1 then
        SendGMCommand("player.SetPosition(2027,1923,1048640)")
    elseif nIndexScene==2 then
        SendGMCommand("player.SetPosition(14347,2028,1048576)")
    elseif nIndexScene==3 then
        SendGMCommand("player.SetPosition(26686,2190,1048640)")
    end
end

-- 切换天气 0-2
function StudioTraversal.SetWeather(nIndex)
    SelfieData.ChangeDynamicWeather(nIndex, true)
end

-- 切换背景 6
function StudioTraversal.Setbackground(nIndexBackground)
    local szBackground = "set env preset "..tostring(nIndexBackground)
    rlcmd(szBackground)
end


-- 镜头拉远拉近
StudioTraversal.tbCameraZoom = {}
StudioTraversal.tbCameraZoom.nMax = 1.08
StudioTraversal.tbCameraZoom.nMin = 0.02
StudioTraversal.tbCameraZoom.nLine = 1.08
StudioTraversal.tbCameraZoom.nSpeed = 0.02
StudioTraversal.tbCameraZoom.bStart= true
function StudioTraversal.tbCameraZoom .FrameUpdate()
    if StudioTraversal.tbCameraZoom.nLine <= StudioTraversal.tbCameraZoom.nMin then
        StudioTraversal.tbCameraZoom.nLine = 1.08
        StudioTraversal.tbCameraZoom.bStart= false
        Timer.DelAllTimer(StudioTraversal.tbCameraZoom)
        return
    end
    CameraMgr.Zoom(StudioTraversal.tbCameraZoom.nLine)
    StudioTraversal.tbCameraZoom.nLine = StudioTraversal.tbCameraZoom.nLine - tbCameraZoom.nSpeed
end

-- 启动镜头拉远拉近
function StudioTraversal.tbCameraZoom.CameraZoomStart()
    if StudioTraversal.tbCameraZoom.bStart then
        Timer.AddFrameCycle(StudioTraversal.tbCameraZoom, 1, function ()
            StudioTraversal.tbCameraZoom .FrameUpdate()
        end)
    end
end


StudioTraversal.tbCircle={}
StudioTraversal.tbCircle.fStartIndex=2.2
StudioTraversal.tbCircle.fEndIndex=8.4
StudioTraversal.tbCircle.nIndex=StudioTraversal.tbCircle.fStartIndex
StudioTraversal.tbCircle.fStep=StudioTraversal.tbCircle.fEndIndex-StudioTraversal.tbCircle.fStartIndex
StudioTraversal.tbCircle.fStep=-StudioTraversal.tbCircle.fStep/150 --90帧限制
StudioTraversal.tbCircle.nAngle = 1083
StudioTraversal.tbCircle.nStart = true
function StudioTraversal.tbCircle.SetAngle(nAngleCount)
    StudioTraversal.tbCircle.nAngle = tonumber(nAngleCount)
end
function StudioTraversal.tbCircle.FrameUpdate()
    if StudioTraversal.tbCircle.nIndex >= StudioTraversal.tbCircle.fEndIndex then
        StudioTraversal.tbCircle.nIndex=StudioTraversal.tbCircle.fStartIndex
        StudioTraversal.tbCircle.nStart= false
        Timer.DelAllTimer(StudioTraversal.tbCircle)
        SetCameraStatus(1083,1,0.1,-0.1369)
        return
    end
    SetCameraStatus(StudioTraversal.tbCircle.nAngle,1,StudioTraversal.tbCircle.nIndex,-0.1369)
    StudioTraversal.tbCircle.nIndex=StudioTraversal.tbCircle.nIndex-StudioTraversal.tbCircle.fStep
end

function StudioTraversal.tbCircle.CircleStart()
    if StudioTraversal.tbCircle.nStart then
        Timer.AddFrameCycle(StudioTraversal.tbCircle, 1, function ()
            StudioTraversal.tbCircle.FrameUpdate()
        end)
    end
end




local Init = BaseState:New("Init")
function Init:OnEnter()

end

function Init:OnUpdate()
    fsm:Switch("Scene")
end

function Init:OnLeave()                               

end


local Exterior = BaseState:New("Exterior")
function Exterior:OnEnter()

end


function Exterior:OnUpdate()
    if ExteriorList.Line == #ExteriorList+1  then
        ExteriorList.Line = 1
        fsm:Switch("Scene")
        return
    end
    print(ExteriorList[ExteriorList.Line])
    SearchExterior.Apply_ByName(ExteriorList[ExteriorList.Line],false)
    ExteriorList.Line = ExteriorList.Line + 1
    fsm:Switch("CameraZoom")
end

function Exterior:OnLeave()                               
    
end


local CameraZoom = BaseState:New("CameraZoom")
function CameraZoom:OnEnter()

end


function CameraZoom:OnUpdate()
    if StudioTraversal.tbCameraZoom.bStart then
        StudioTraversal.tbCameraZoom.CameraZoomStart()
    else
        fsm:Switch("CameraCircle")
    end
end

function CameraZoom:OnLeave()                               
    StudioTraversal.tbCameraZoom.bStart = true
end



local CameraCircle = BaseState:New("CameraCircle")
function CameraCircle:OnEnter()

end


function CameraCircle:OnUpdate()
    if StudioTraversal.tbCircle.nStart then
        StudioTraversal.tbCircle.CircleStart()
    else
        fsm:Switch("Exterior")
    end
end

function CameraCircle:OnLeave()                               
    StudioTraversal.tbCircle.nStart = true
end





local Scene = BaseState:New("Scene")
local nSecneLine = 1 --场景
local nWeatherLine = 0 --天气
local nBackgroundLine = 1 --背景
function Scene:OnEnter()

end

function Scene:OnUpdate()
    print(nSecneLine,nBackgroundLine,nWeatherLine)
    if nWeatherLine == 3 then
        -- 处理最高优先级的中断条件
        if nSecneLine == 3 and nBackgroundLine == 6 then
            bFlag = true
            Timer.DelAllTimer(StudioTraversal)
            return -- 全部达到上限时终止
        end
        
        -- 分步处理进位逻辑
        if nBackgroundLine == 6 then
            -- 场景线进位操作
            nSecneLine = nSecneLine + 1
            StudioTraversal.SetScene(nSecneLine)
            nBackgroundLine = 1
        else
            -- 背景线常规进位
            StudioTraversal.Setbackground(nBackgroundLine)
            nBackgroundLine = nBackgroundLine + 1
        end

        -- 重置天气线（无论是否进位都需要重置）
        nWeatherLine = 0
    else
        StudioTraversal.SetWeather(nWeatherLine)
        -- 最基础的天气线进位
        nWeatherLine = nWeatherLine + 1
    end
    fsm:Switch("Exterior")
end

function Scene:OnLeave()                               

end



function StudioTraversal.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    fsm.curState:OnUpdate()
end


function StudioTraversal.Start()
    ExteriorList.GetExterior()
    fsm = FsmMachine:New()
    fsm:AddState(Scene)
    fsm:AddState(Exterior)
    fsm:AddState(CameraCircle)
    fsm:AddState(CameraZoom)
    fsm:AddInitState(Init)
    Timer.AddCycle(StudioTraversal,1,function ()
        StudioTraversal.FrameUpdate()
    end)
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
        if string.find(szCmd,"StudioTraversal") then
            --启动切图帧更新函数
            StudioTraversal.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)