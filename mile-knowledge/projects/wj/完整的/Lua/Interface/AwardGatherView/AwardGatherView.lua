AwardGatherView={}  -- 奖励收集
local bFlag = true
local RunMap = {}

-- 写死
AwardGatherView.nPages= 5  --页面长度
AwardGatherView.nPagesLine = 1 --当前页数
AwardGatherView.nLine = 2 
AwardGatherView.nPagesCount = 108  -- 每页的Tog总数  最后一页为 102
AwardGatherView.nCurrentTime = 0
AwardGatherView.nNextTime = 2

-- 摄像机旋转一周
CameraRotate ={}
CameraRotate.bCamera = false  -- 是否在旋转
CameraRotate.nCameraTime = 5 --默认5秒选旋转完
local nCameraX = 0

-- 选中物品格子 GoodId为格子 规律为2 5 8 11 依次加3
function AwardGatherView.SetGoods(nGoodsId)
    UINodeControl.TogTriggerByIndex("ScrollViewGoods",nGoodsId)
end


-- 翻页函数
function AwardGatherView.SetBtnRight()
    UINodeControl.BtnTrigger("BtnRight","WidgetPaginate")
end



-- 摄像机旋转秒数 几秒旋转完
function AwardGatherView.SetCameraTime(nCameraTime)
    CameraRotate.nCameraTime = nCameraTime
end



-- 摄像机旋转
function CameraRotate.FrameUpdate()
    -- 根据每帧来旋转参数
    if UITouchHelper._model ~=nil then
        if nCameraX >=6.3 then
            nCameraX = 0
            Timer.DelAllTimer(CameraRotate)
            CameraRotate.bCamera = false
        end
        local nGetFpS = GetHotPointReader().GetFrameDataInfo().FPS
        -- 摄像机旋转的角度
        local nCameraAngle = 6.3/CameraRotate.nCameraTime/nGetFpS
        UITouchHelper._model:SetYaw(nCameraX)
        nCameraX = nCameraX + nCameraAngle
    end
end


-- 帧函数
function AwardGatherView.FrameUpdate()
    if GetTickCount()-AwardGatherView.nCurrentTime>AwardGatherView.nNextTime*1000 then
        if not CameraRotate.bCamera  then
            if AwardGatherView.nLine <= AwardGatherView.nPagesCount then
                AwardGatherView.SetGoods(AwardGatherView.nLine)
                AwardGatherView.nLine = AwardGatherView.nLine + 3
                Timer.AddFrameCycle(CameraRotate,1,function ()
                    CameraRotate.FrameUpdate()
                end)
                CameraRotate.bCamera = true
            else
                if AwardGatherView.nPagesLine ~= AwardGatherView.nPages then
                    AwardGatherView.SetBtnRight()
                    AwardGatherView.nPagesLine = AwardGatherView.nPagesLine  + 1
                    AwardGatherView.nLine = 2
                else
                    Timer.DelAllTimer(AwardGatherView)
                    bFlag = true
                end
            end
        end
        AwardGatherView.nCurrentTime= GetTickCount()
    end
end

CMDinfo ={}
local nCMDLine = 1
-- 帧函数
function CMDinfo.CMDFrameUpdate()
    if nCMDLine  ~= 4 then
        if nCMDLine == 1 then
            SearchPanel.MyExecuteScriptCommand('UIMgr.Open(VIEW_ID.PanelAwardGather,PlayerData.GetPlayerID(),"data/source/maps/界面使用场景/界面使用场景.jsonmap")')
        end
        if nCMDLine == 2 then
            SearchPanel.MyExecuteScriptCommand('Event.Dispatch("OnUIPandentModel_ChangeScene",  "data/source/maps/界面使用场景/界面使用场景.jsonmap")')
        end
        if nCMDLine == 3 then
            SearchPanel.MyExecuteScriptCommand('Event.Dispatch("OnUIPandentModel_AddPrefab", "data/source/maps_source/Prefab/界面使用场景/水上花灯.prefab", 0.5)')
        end
        nCMDLine = nCMDLine + 1
    else
        Timer.DelAllTimer(CMDinfo)
        Timer.AddFrameCycle(AwardGatherView,1,function () AwardGatherView.FrameUpdate() end)
    end
end


-- 帧函数
function AwardGatherView.Start()
    Timer.AddCycle(CMDinfo,5,function () CMDinfo.CMDFrameUpdate() end)
end


--读取tab的内容 
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
        if string.find(szCmd,"AwardGatherView_start") then
            --启动切图帧更新函数
            AwardGatherView.Start()
            bFlag = false
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)