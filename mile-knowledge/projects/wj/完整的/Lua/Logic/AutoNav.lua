-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: AutoNav
-- Date: 2024-02-29 19:35:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

AutoNav = AutoNav or {
    className = "AutoNav",
    tNavEffect = {},
}

AutoNav.DefaultNavCutTailCellCount = 2

local kNavEffectFile = UTF8ToGBK("data/source/other/hd特效/其他/pss/x_寻路星01_黄01.pss")
local kNavEffectHeightOffset = 0.2 / Const.kMetreHeight     -- 特效向上偏移
local kNavEffectDuration = 2.5                              -- 移动时间(s)
local kNavEefctDisappear = 0.3                              -- 消失持续时间(s)
local kNavEffectOffset = 15                                 -- 特效起点相当于当前位置提前(多少cell)
local kNavEffectLength = 20                                 -- 特效的播放距离(cell个数)
local kNavEffectMinLen = 10                                 -- 特效的播放最短距离(cell个数)

local self = AutoNav
-------------------------------- 消息定义 --------------------------------
AutoNav.Event = {}
AutoNav.Event.XXX = "AutoNav.Msg.XXX"

AutoNav.PlanType = {
    Trading = 1
}

function AutoNav.Init()
    self._registerEvent()
    self._SprintCheckTimer = nil
end

function AutoNav.UnInit()

end

function AutoNav.OnLogin()

end

function AutoNav.OnFirstLoadEnd()

end

function AutoNav.NavTo(nMapID, nX, nY, nZ, nCutTailCellCount, szRemark)
    if nZ == 0 then
        nZ = -1
    end

    if g_pClientPlayer.bInNav then
        g_pClientPlayer.NavStop()
        Timer.AddCountDown(self, 1, function() end, function()
            self.NavTo(nMapID, nX, nY, nZ, nCutTailCellCount, szRemark)
        end)
        return
    end

    if g_pClientPlayer.nDisableMoveCtrlCounter > 0 then
        TipsHelper.ShowNormalTip("当前状态无法寻路，请稍后再试")
        return
    end


    if MapMgr.IsCurrentMap(nMapID) then
        nCutTailCellCount = nCutTailCellCount or 0

        self.tbPoint = {nMapID = nMapID, nX = nX, nY = nY, nZ = nZ}
        g_pClientPlayer.NavTo(nX, nY, nZ, nCutTailCellCount, szRemark)

        local nPlayerLevel = PlayerData.GetPlayerLevel()
        XGSDK_TrackEvent("game.nav.navto", "nav", {{"mapid", tostring(nMapID)}, {"level", tostring(nPlayerLevel)}})

        Event.Dispatch(EventType.ClientChangeAutoNavState, true)

        if UIMgr.GetView(VIEW_ID.PanelRenownRewordList) then
            Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)   -- 退出家具模型，防止声望奖励miniscene宕机
            Timer.AddFrame(self, 1, function ()
                UIMgr.CloseAllInLayer(UILayer.Page, IGNORE_TEACH_VIEW_IDS)--开启自动寻路，关闭所有界面
            end)
        else
            UIMgr.CloseAllInLayer(UILayer.Page, IGNORE_TEACH_VIEW_IDS)--开启自动寻路，关闭所有界面
        end
    else
        TipsHelper.ShowNormalTip("当前位置与目标不在同一地图，无法自动寻路")
    end
end

function AutoNav.StopNav()
    self.tbPoint = nil
    g_pClientPlayer.NavStop()
    Event.Dispatch(EventType.ClientChangeAutoNavState, false)
end

function AutoNav.GetNavPoint()
    return self.tbPoint
end

function AutoNav.IsNavQuest(nQuestID)
    local nMapID, tbPoints = QuestData.GetQuestMapIDAndPoints(nQuestID)
    if not nMapID or not tbPoints then
        return false
    end
    return self.IsCurNavPoint(nMapID, tbPoints[1], tbPoints[2], tbPoints[3])
end

function AutoNav.IsCurNavPoint(nMapID, nX, nY, nZ)
    return self.tbPoint and self.tbPoint.nMapID == nMapID and self.tbPoint.nX == nX and self.tbPoint.nY == nY and self.tbPoint.nZ == nZ
end

function AutoNav.GetNavDestDistanceSq()
    if not g_pClientPlayer or not self.tbPoint then
        return 0
    end

    return GetDistanceSq(g_pClientPlayer.nX, g_pClientPlayer.nY, g_pClientPlayer.nZ, self.tbPoint.nX, self.tbPoint.nY, self.tbPoint.nZ)
end

function AutoNav._registerEvent()
    Event.Reg(self, "ON_NAV_RESULT", function (nCode)
        Log("AutoNav.ON_NAV_RESULT nCode:".. tostring(nCode))
        if nCode ~= NAV_RESULT_CODE.SUCCESS and nCode ~= NAV_RESULT_CODE.SUCCESS_TO_NEARBY and nCode ~= NAV_RESULT_CODE.COMPLETE then
            if self._NavPlan then
                self.StopNavPlan()
            end
        end

        if nCode ~= NAV_RESULT_CODE.SUCCESS and nCode ~= NAV_RESULT_CODE.SUCCESS_TO_NEARBY then
            self.tbPoint = nil
            self.tNavEffect.bStop = true
            self.stopAutoSprintTimer()
        else
            self.startAutoSprintTimer()
            self.clearNavEffect()
            self.playNavEffct()
        end
        Event.Dispatch(EventType.OnAutoNavResult, nCode == NAV_RESULT_CODE.SUCCESS or nCode == NAV_RESULT_CODE.SUCCESS_TO_NEARBY)
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function ()
        self.clearNavEffect()
        self.clearFadeoutEffect()
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.StopNavPlan()
    end)
end

function AutoNav.startAutoSprintTimer()
    if self._SprintCheckTimer then
        Timer.DelTimer(self, self._SprintCheckTimer)
        self._SprintCheckTimer = nil
    end

    self._SprintCheckTimer = Timer.AddFrameCycle(self, GLOBAL.GAME_FPS * 0.25, function()
        self.checkAutoSprint()
    end)
end

function AutoNav.stopAutoSprintTimer()
    if self._SprintCheckTimer then
        Timer.DelTimer(self, self._SprintCheckTimer)
        self._SprintCheckTimer = nil

        if SprintData.GetExpectSprint() or SprintData.GetSprintState() then
            SprintData.EndSprint(true, true)
        end
    end
end

function AutoNav.checkAutoSprint()
    if g_pClientPlayer and g_pClientPlayer.bInNav then
        local distanceSQ = self.GetNavDestDistanceSq()
        if  distanceSQ < (5 * 64) * (5 *64) then
            self.stopAutoSprintTimer()
        elseif g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY and (SprintData.GetExpectSprint() or SprintData.GetSprintState()) then
            SprintData.EndSprint(true)
        elseif AutoNav.NavCanStartSprint(distanceSQ) then
            SprintData.StartSprint(true)
        end
    end
end

function AutoNav.NavCanStartSprint(distanceSQ)
    return g_pClientPlayer.nSprintPower > g_pClientPlayer.nSprintPowerMax * 0.10 and
        g_pClientPlayer.nDisableSprintFlag == 0 and
        SprintData.CanSprint() and
        not g_pClientPlayer.bFightState and
        g_pClientPlayer.nMoveState ~= MOVE_STATE.ON_AUTO_FLY and
        not SprintData.GetSprintState() and
        distanceSQ > (20 * 64) * (20 *64)
end

function AutoNav.playNavEffct()
    local tPoints = GetNavResult()
    if not tPoints or #tPoints == 0 then
        return
    end

    -- 逻辑坐标转表现坐标
    for _, tPos in ipairs(tPoints) do
        tPos.nX, tPos.nY, tPos.nZ =
            SceneMgr.LogicPosToScenePos(tPos.nX, tPos.nY, tPos.nZ + kNavEffectHeightOffset)
    end

    local fnStep = self.playNavEffctCor(tPoints)
    local nNextTime = Timer.GetPassTime()
    -- 启动定时器
    self.tNavEffect.nTimerID = Timer.AddFrameCycle(self, 1, function()
        local nNow = Timer.GetPassTime()
        if nNow >= nNextTime then
            if not fnStep then
                self.clearNavEffect()
            end

            local nDur, fnNext = fnStep()
            fnStep = fnNext
            if not nDur and not fnNext then
                self.clearNavEffect()
            else
                nNextTime = nDur and (nNextTime + nDur) or nNow
            end
        end
    end)
end

function AutoNav.playNavEffctCor(tPoints)
    local tNav = self.tNavEffect
    local nCurIdx = 1
    local fnAll
    fnAll = function ()
        if tNav.bStop then
            return                      -- 中断导航
        end

        if g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY then
            return 0.5, fnAll           -- 处于轻功状态则暂停特效
        end

        -- 根据当前角色速度调整特效移动速度, （角色的基准逻辑速度为320）
        local nDuration = kNavEffectDuration
        local nNavOffset = kNavEffectOffset
        if g_pClientPlayer.nVelocityXY > 0 then
            local nRatio = 320 / g_pClientPlayer.nVelocityXY
            nDuration = nDuration * nRatio
            nNavOffset = math.max(math.floor(nNavOffset / nRatio), kNavEffectOffset)
        end

        local tMovePts
        nCurIdx, tMovePts = self.findNavPointIndex(nCurIdx, nNavOffset, tPoints)
        if not nCurIdx then
            return                      -- 结束
        end

        local nLength = #tMovePts
        nDuration = nDuration * nLength / kNavEffectLength

        tNav.pModel = SceneMgr.CreateModel(
            kNavEffectFile,
            tMovePts[1].nX,
            tMovePts[1].nY,
            tMovePts[1].nZ
        )

        local nStartTime = Timer.GetPassTime()
        local fnMoveEffect
        fnMoveEffect = function()
            local nPercent = (Timer.GetPassTime() - nStartTime) / nDuration
            if nPercent > 0.99 then
                self.fadeoutNavEffect(tNav.pModel)
                tNav.pModel:SetTranslation(tMovePts[nLength].nX, tMovePts[nLength].nY, tMovePts[nLength].nZ)
                tNav.pModel = nil
                return kNavEefctDisappear + 0.2, fnAll
            end

            local nMoveCell = (nLength - 1) * nPercent
            local nIndex = math.floor(nMoveCell) + 1
            local nDelta = nMoveCell - math.floor(nMoveCell)
            local nX = tMovePts[nIndex].nX + (tMovePts[nIndex + 1].nX - tMovePts[nIndex].nX) * nDelta
            local nY = tMovePts[nIndex].nY + (tMovePts[nIndex + 1].nY - tMovePts[nIndex].nY) * nDelta
            local nZ = tMovePts[nIndex].nZ + (tMovePts[nIndex + 1].nZ - tMovePts[nIndex].nZ) * nDelta
            tNav.pModel:SetTranslation(nX, nY, nZ)
            return nil, fnMoveEffect
        end

        return nil, fnMoveEffect
    end
    return fnAll
end

function AutoNav.findNavPointIndex(nCurIdx, nOffset, tPoints)
    local nPtNum = #tPoints
    local nMinDis = 9999999
    local nX, nY, nZ = SceneMgr.LogicPosToScenePos(g_pClientPlayer.GetAbsoluteCoordinate())
    local nNextIdx
    for i = nCurIdx, nPtNum do
        local nDx = tPoints[i].nX - nX
        local nDy = tPoints[i].nY - nY
        local nDz = tPoints[i].nZ - nZ
        local nDis = nDx * nDx + nDy * nDy + nDz * nDz
        if nDis < nMinDis then
            nNextIdx = i
            nMinDis = nDis
        --elseif nDis > 400000 then
        --    break   -- 与角色超过20米则不再计算了
        end
    end

    if not nNextIdx or nPtNum - nNextIdx < 3 then
        return  -- 结束
    end

    local nLast = math.min(nNextIdx + nOffset + kNavEffectLength, nPtNum)   -- 特效播放距离
    local nFirst = math.max(nNextIdx, nLast - kNavEffectLength)             -- 起点往后延一定数量的cell
    for i = nFirst + 1, nLast do
        local nDx = tPoints[i].nX - tPoints[i - 1].nX
        local nDy = tPoints[i].nY - tPoints[i - 1].nY
        local nDz = tPoints[i].nZ - tPoints[i - 1].nZ
        local nDis = math.abs(nDx) + math.abs(nDy) + math.abs(nDz)
        if nDis > 500 then  -- 如果两个cell间的距离过大，则认为后续需走autofly(cm)，一般情况下不会出现两个autolfy紧挨在一起的情况
            nLast = i
            nFirst = math.max(nNextIdx, math.min(nFirst, nLast - kNavEffectMinLen))
            break
        end
    end

    -- 坐标平滑，取相邻3个坐标的平均值
    local tRet = { tPoints[nFirst] };
    for i = nFirst + 1, nLast - 1 do
        table.insert(tRet, {
            nX = (tPoints[i - 1].nX + tPoints[i].nX + tPoints[i + 1].nX) / 3,
            nY = (tPoints[i - 1].nY + tPoints[i].nY + tPoints[i + 1].nY) / 3,
            nZ = (tPoints[i - 1].nZ + tPoints[i].nZ + tPoints[i + 1].nZ) / 3
        })
    end
    table.insert(tRet, tPoints[nLast])
    return nFirst, tRet
end

function AutoNav.fadeoutNavEffect(pModel)
    self.clearFadeoutEffect()

    local tNav = self.tNavEffect
    local nStartTime = Timer.GetPassTime()

    tNav.pFadeout = pModel
    tNav.nFadeoutTimerID = Timer.AddFrameCycle(self, 1, function()
        local nPercent = (Timer.GetPassTime() - nStartTime) / kNavEefctDisappear
        if nPercent >= 1.0 then
            self.clearFadeoutEffect()
        else
            pModel:SetAlpha(1.0 - nPercent)
        end
    end)
end

function AutoNav.clearNavEffect()
    local tNav = self.tNavEffect
    if tNav.nTimerID then
        Timer.DelTimer(self, tNav.nTimerID)
        tNav.nTimerID = nil
    end

    if tNav.pModel then
        tNav.pModel:SetTranslation(0, 0, 0)
        SceneMgr.DestoryModel(tNav.pModel)
        tNav.pModel = nil
    end

    tNav.bStop = nil
end

function AutoNav.clearFadeoutEffect()
    local tNav = self.tNavEffect
    if tNav.nFadeoutTimerID then
        Timer.DelTimer(self, tNav.nFadeoutTimerID)
        tNav.nFadeoutTimerID = nil
    end

    if tNav.pFadeout then
        SceneMgr.DestoryModel(tNav.pFadeout)
        tNav.pFadeout = nil
    end
end

--------------导航到服务器下发的追踪点-------------------------
-- 远程调用让显示追踪箭头
-- tPoint = {fX = 0, fY = 0, fZ = 0}
Event.Reg(AutoNav, "OnRemoteAddNaviPoint", function(szKey, dwMapID, tPoint, nType)
    if not dwMapID then return end
    if not tPoint then return end
    if not IsNumber(tPoint.fX) then return end
    if not IsNumber(tPoint.fY) then return end
    if not IsNumber(tPoint.fZ) then return end
    self.tbRemotePointData = self.tbRemotePointData or {}
    self.tbRemotePointData[szKey] = {szKey = szKey, dwMapID = dwMapID, tPoint = tPoint, nType = nType}
end)

-- 远程调用让删除追踪箭头
Event.Reg(AutoNav, "OnRemoteRemoveNaviPoint", function(szKey)
    if not self.tbRemotePointData then return end
    self.tbRemotePointData[szKey] = nil
end)

-- 远程调用让清除所有跟踪箭头
Event.Reg(self, "OnRemoteClearAllNaviPoint", function()
    self.tbRemotePointData = nil
end)

-- 账号退出和切角色的时候 要清空远程调用的追踪箭头
Event.Reg(AutoNav, EventType.OnRoleLogin, function()
    self.tbRemotePointData = nil
end)

function AutoNav.StartNav_RemotePoint(szKey)
    if not self.tbRemotePointData then
        return false
    end

    local remotePoint = self.tbRemotePointData[szKey]
    if not remotePoint or not g_pClientPlayer or remotePoint.dwMapID ~= g_pClientPlayer.GetScene().dwMapID then
        return false
    end

    self.NavTo(remotePoint.dwMapID, remotePoint.tPoint.fX, remotePoint.tPoint.fY, remotePoint.tPoint.fZ, 2)
    return true
end
-------------------------------------------------------------

--------------跨场景导航规划--------------------------------
function AutoNav.StartNavPlan_Trading()
    if self._NavPlan then
        self.StopNavPlan()
    end

    Log("AutoNav.StartNavPlan_Trading")
    local szMarketName, nX, nY, nZ, dwMapID = MapMgr.GetMarkInfo()
    if szMarketName ~= g_tStrings.TRADING_MARK_NAME then
        return true
    end

    if not g_pClientPlayer or g_pClientPlayer.bInNav then
        return true
    end

    self._NavPlan = AutoNav.PlanType.Trading
    if self._NavPlanTimer then
        self._NavPlanTimer = Timer.DelTimer(self, self._NavPlanTimer)
        self._NavPlanTimer = nil
    end

    self._NavPlanTimer = Timer.AddFrameCycle(self, GLOBAL.GAME_FPS, function()
        if not g_pClientPlayer or not g_pClientPlayer.GetScene() or g_pClientPlayer.bInNav then
            return
        end

        if UIMgr.GetView(VIEW_ID.PanelLoading) then
            return
        end

        if not g_pClientPlayer.bInNav and g_pClientPlayer.nMoveState == MOVE_STATE.ON_RUN then
            self.StopNavPlan()
            return
        end

        local szMarketName, nX, nY, nZ, dwMapID = MapMgr.GetMarkInfo()
        if szMarketName ~= g_tStrings.TRADING_MARK_NAME then
            return
        end

        local nCurMapID = g_pClientPlayer.GetScene().dwMapID
        if dwMapID ~= nCurMapID then
            return
        end

        if self._NavPlanMapID == nCurMapID then
            return
        end
        self._NavPlanMapID = nCurMapID

        Log("AutoNav.DoNavTo in Map:" .. tostring(self._NavPlanMapID))
        self.NavTo(dwMapID, nX, nY, nZ, 0)
    end)

    return true
end

function AutoNav.StopNavPlan()
    if self._NavPlanTimer then
        self._NavPlanTimer = Timer.DelTimer(self, self._NavPlanTimer)
        self._NavPlanTimer = nil
    end

    self._NavPlan = nil
    self._NavPlanMapID = nil
    Log("AutoNav.StopNavPlan")
end
---------------------------------------------------------

--------------查询据点贸易的下一个场景ID--------------------
function AutoNav.OnOpenSwitchMapWindow()
    if self._NavPlan == AutoNav.PlanType.Trading then
        Timer.Add(self, 1, function()
            RemoteCallToServer("OnGetNextCastleTradeMap")
        end)
    end
end
---------------------------------------------------------

----------------跨场景后自动寻路目标点------------------
function AutoNav.StartAutoNavPoint(nMapID, nX, nY, nZ, nCutTailCellCount)--角色被锁住时，在一段时间内进行检测状态，解锁后自动寻路
    self.StopAutoNavPoint()
    if g_pClientPlayer.nDisableMoveCtrlCounter <= 0 then
        self.NavTo(nMapID, nX, nY, nZ, nCutTailCellCount)
    else
        local nStartTime = Timer.GetPassTime()
        self.nStartAutoNavTimer = Timer.AddFrameCycle(self, GLOBAL.GAME_FPS, function()
            local nCurTime = Timer.GetPassTime()
            if nCurTime - nStartTime > 2 then--2秒后停止检测
                self.StopAutoNavPoint()
            end

            if g_pClientPlayer.bInNav then
                return
            end
            if g_pClientPlayer.nDisableMoveCtrlCounter > 0 then
                return
            end

            self.NavTo(nMapID, nX, nY, nZ, nCutTailCellCount)
            self.StopAutoNavPoint()
        end)
    end
end

function AutoNav.StopAutoNavPoint()
    if self.nStartAutoNavTimer then
        Timer.DelTimer(self, self.nStartAutoNavTimer)
        self.nStartAutoNavTimer = nil
    end
end

---------------------------------------------------------