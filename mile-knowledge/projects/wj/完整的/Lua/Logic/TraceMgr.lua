-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: TraceMgr
-- Date: 2024-01-23 21:13:43
-- Desc: 箭头追踪管理
-- ---------------------------------------------------------------------------------

TraceMgr = TraceMgr or {className = "TraceMgr"}
local self = TraceMgr


local IS_LOW_FREQUENCY      = true         -- 是否是低频刷新 手游默认是true
local TICK_INTERVAL         = IS_LOW_FREQUENCY and 0.10 or 0.033      -- 刷新频率
local ANIM_DUARATION        = IS_LOW_FREQUENCY and 0.18 or 0.066      -- 动画缓动时间
local HIDE_TRACE_DISTANCE   = 2 * 64        -- 多少米之内隐藏箭头的
local SHOW_ON_FOOT_DISTANCE = 10000 * 64    -- 多少米之内显示在脚下


self.tbScriptToTraceMap = {}
self.tbRemotePointData = {}


Event.Reg(self, "LOADING_END", function()
    self._updateQuestTrace()
end)

Event.Reg(self, EventType.OnQuestTracingTargetChanged, function(nQuestID)
    self._updateQuestTrace()
end)

Event.Reg(self, EventType.OnMapUpdateNpcTrace, function(bNearAutoClear)
    self._updateNpcTrace()
end)

-- 远程调用让显示追踪箭头
-- tPoint = {fX = 0, fY = 0, fZ = 0}
Event.Reg(self, "OnRemoteAddNaviPoint", function(szKey, dwMapID, tPoint, nType, dwTemplateID)
    self.AddRemotePoint(szKey, dwMapID, tPoint, nType, dwTemplateID)
end)

-- 远程调用让删除追踪箭头
Event.Reg(self, "OnRemoteRemoveNaviPoint", function(szKey)
    TraceMgr.ClearRemotePoint(szKey)
end)

-- 远程调用让清除所有跟踪箭头
Event.Reg(self, "OnRemoteClearAllNaviPoint", function()
    TraceMgr.ClearAllRemotePoint()
end)

-- 账号退出和切角色的时候 要清空远程调用的追踪箭头
Event.Reg(self, EventType.OnAccountLogout, function()
    TraceMgr.ClearAllRemotePoint()
end)

function TraceMgr.AddRemotePoint(szKey, dwMapID, tPoint, nType, dwTemplateID)
    if string.is_nil(szKey) then return end
    if not dwMapID then return end
    if not tPoint then return end
    if not IsNumber(tPoint.fX) then return end
    if not IsNumber(tPoint.fY) then return end
    if not IsNumber(tPoint.fZ) then return end

    -- MapMgr.ClearTracePoint()
    local tbRemotePointData = {szKey = szKey, dwMapID = dwMapID, tPoint = tPoint, nType = nType, dwTemplateID = dwTemplateID}
    self._updateRemoteTrace(tbRemotePointData)
end


function TraceMgr.Start(scriptView, tbTargetPoint, visibleCheckFunc, stopCallback, nearCallback, szFrame, farCallback, dwTemplateID)
    if not scriptView then return end
    if not tbTargetPoint then return end
    if not tbTargetPoint[1] then return end
    if not tbTargetPoint[2] then return end
    if not tbTargetPoint[3] then return end

    local tbOneTrace = self.tbScriptToTraceMap[scriptView._rootNode]
    if tbOneTrace then
        tbOneTrace.tbTargetPoint = tbTargetPoint
        tbOneTrace.tbOrigTargetPoint = clone(tbTargetPoint)
        tbOneTrace.visibleCheckFunc = visibleCheckFunc
        tbOneTrace.stopCallback = stopCallback
        tbOneTrace.nearCallback = nearCallback
        tbOneTrace.farCallback = farCallback
        tbOneTrace.nLastX = 0
        tbOneTrace.nLastY = 0
        tbOneTrace.szFrame = szFrame
        tbOneTrace.dwTemplateID = dwTemplateID

        local nCTCID = tbOneTrace.nCTCID
        if nCTCID then CrossThreadCoor_Unregister(nCTCID) end
    else
        tbOneTrace =
        {
            scriptView = scriptView,
            tbTargetPoint = tbTargetPoint,
            tbOrigTargetPoint = clone(tbTargetPoint),
            visibleCheckFunc = visibleCheckFunc,
            stopCallback = stopCallback,
            nearCallback = nearCallback,
            farCallback = farCallback,
            nCTCID = nCTCID,
            dwTemplateID = dwTemplateID,

            nLastX = 0,
            nLastY = 0,

            szFrame = szFrame
        }

        self.tbScriptToTraceMap[scriptView._rootNode] = tbOneTrace
    end

    local nCTCID = CrossThreadCoor_Register(CTCT.GAME_WORLD_2_SCREEN_POS, tbTargetPoint[1], tbTargetPoint[2], tbTargetPoint[3])
    tbOneTrace.nCTCID = nCTCID

    Timer.DelAllTimer(scriptView)
    tbOneTrace.nTimerID = Timer.AddCycle(scriptView, TICK_INTERVAL, function()
        self._updateOneTrace(tbOneTrace)
    end)
end

function TraceMgr.Stop(tbOneTrace, bCallback)
    if not tbOneTrace then return end

    local scriptView = tbOneTrace.scriptView
    if scriptView and scriptView.IsNpcTrace and scriptView:IsNpcTrace() then return end

    self._setTraceVisible(tbOneTrace, false)

    local nCTCID = tbOneTrace.nCTCID
    if nCTCID then CrossThreadCoor_Unregister(nCTCID) end
    local nPrevCTCID = tbOneTrace.nPrevCTCID
    if nPrevCTCID then CrossThreadCoor_Unregister(nPrevCTCID) end

    if bCallback and IsFunction(tbOneTrace.stopCallback) then
        tbOneTrace.stopCallback()
    end

    if scriptView then
        UIHelper.StopAllActions(scriptView.WidgetTrace)
        UIHelper.SetPosition(scriptView.WidgetTrace, 0, 0)
        Timer.DelTimer(scriptView, tbOneTrace.nTimerID)
        self.tbScriptToTraceMap[scriptView._rootNode] = nil
    end
    tbOneTrace = nil
    Event.Dispatch(EventType.OnStopTraceGuild)
end

function TraceMgr.StopByScript(script, bCallback)
    if not script then return end
    if not script._rootNode then return end
    local tbOneTrace = self.tbScriptToTraceMap[script._rootNode]
    if tbOneTrace then
        self.Stop(tbOneTrace, bCallback)
    else
        Timer.DelAllTimer(script)
    end
end

function TraceMgr.ClearRemotePoint(szKey)
    if string.is_nil(szKey) or table.is_empty(self.tbRemotePointData) or not self.tbRemotePointData[szKey] then
        return
    end

    local script = self.tbRemotePointData[szKey].scriptTrace
    if script then
        UIHelper.RemoveFromParent(script._rootNode, true)
        self.tbRemotePointData[szKey] = nil
    end
end

function TraceMgr.ClearAllRemotePoint()
    for key, tbTrace in pairs(self.tbRemotePointData) do
        local script = tbTrace.scriptTrace
        if script then
            UIHelper.RemoveFromParent(script._rootNode, true)
        end
    end

    self.tbRemotePointData = {}
end

function TraceMgr._updateOneTrace(tbOneTrace)
    if not tbOneTrace then return end

    local tbTargetPoint = tbOneTrace.tbTargetPoint
    if tbOneTrace.dwTemplateID and tbTargetPoint then
        local npc = GetNpcByTemplateID(tbOneTrace.dwTemplateID)
        if npc then
            local newX, newY, newZ = npc.nX, npc.nY, npc.nZ
            if newX ~= tbTargetPoint[1] or newY ~= tbTargetPoint[2] or newZ ~= tbTargetPoint[3] then
                tbTargetPoint[1], tbTargetPoint[2], tbTargetPoint[3] = newX, newY, newZ
                if tbOneTrace.nPrevCTCID then
                    CrossThreadCoor_Unregister(tbOneTrace.nPrevCTCID)
                end
                tbOneTrace.nPrevCTCID = tbOneTrace.nCTCID
                tbOneTrace.nCTCID = CrossThreadCoor_Register(CTCT.GAME_WORLD_2_SCREEN_POS, newX, newY, newZ)
            else
                if tbOneTrace.nPrevCTCID then
                    CrossThreadCoor_Unregister(tbOneTrace.nPrevCTCID)
                    tbOneTrace.nPrevCTCID = nil
                end
            end
        else
            local tbOrigTargetPoint = tbOneTrace.tbOrigTargetPoint
            local newX, newY, newZ = tbOrigTargetPoint[1], tbOrigTargetPoint[2], tbOrigTargetPoint[3]
            if newX ~= tbTargetPoint[1] or newY ~= tbTargetPoint[2] or newZ ~= tbTargetPoint[3] then
                tbTargetPoint[1], tbTargetPoint[2], tbTargetPoint[3] = newX, newY, newZ
                if tbOneTrace.nPrevCTCID then
                    CrossThreadCoor_Unregister(tbOneTrace.nPrevCTCID)
                    tbOneTrace.nPrevCTCID = nil
                end
                tbOneTrace.nCTCID = CrossThreadCoor_Register(CTCT.GAME_WORLD_2_SCREEN_POS, newX, newY, newZ)
            end
        end
    end

    local scriptView = tbOneTrace.scriptView
    local nCTCID = tbOneTrace.nPrevCTCID or tbOneTrace.nCTCID
    local visibleCheckFunc = tbOneTrace.visibleCheckFunc
    local nArrowBottomY = scriptView.nArrowBottomY
    local nArrowY = scriptView.nArrowY
    local nWidth = scriptView.nWidth
    local nHeight = scriptView.nHeight
    local ImgTraceIcon = scriptView.ImgTraceIcon
    local nContentWidth = tbOneTrace.scriptView.nContentWidth
    local nContentHeight = tbOneTrace.scriptView.nContentHeight
    local szFrame = tbOneTrace.szFrame

    if not tbTargetPoint then
        self.Stop(tbOneTrace, true)
        return
    end

    local nTargetX, nTargetY, nTargetZ = tbTargetPoint[1], tbTargetPoint[2], tbTargetPoint[3]
    if not nTargetX or not nTargetY or not nTargetZ then
        self.Stop(tbOneTrace, true)
        return
    end

    if not g_pClientPlayer then
        self.Stop(tbOneTrace, true)
        return
    end

    if IsFunction(visibleCheckFunc) then
        local bVisible = visibleCheckFunc()
        if not bVisible then
            self._setTraceVisible(tbOneTrace, false)
            return
        end
    end

    local nPlayerX, nPlayerY, nPlayerZ = g_pClientPlayer.nX, g_pClientPlayer.nY, g_pClientPlayer.nZ
    local n3DDistance = math.sqrt(math.pow(nPlayerX - nTargetX, 2) + math.pow(nPlayerY - nTargetY, 2) + math.pow((nPlayerZ - nTargetZ) / 8, 2))

    if n3DDistance < HIDE_TRACE_DISTANCE and not tbOneTrace.dwTemplateID then
        self._setTraceVisible(tbOneTrace, false)
        if IsFunction(tbOneTrace.nearCallback) then
            tbOneTrace.nearCallback()
        end
        return
    end

    local screenSize = UIHelper.GetScreenSize()
    local tb3DPosList = {{nPlayerX, nPlayerY, nPlayerZ}}
    local tb2DPosList = Scene_GameWorldPositionListToScreenPointList(tb3DPosList, #tb3DPosList, true)
    local nPlayerScreenX, nPlayerScreenY = tb2DPosList[1], tb2DPosList[2]
    local nTargetScreenX, nTargetScreenY, bTargetFront = CrossThreadCoor_Get(nCTCID)

    if not nTargetScreenX or not nTargetScreenY or
        not nPlayerScreenX or not nPlayerScreenY then
        self._setTraceVisible(tbOneTrace, false)
        return
    end

    if not bTargetFront then -- 在视野后方的让点永远显示在屏幕下方
        nTargetScreenX = screenSize.width - nTargetScreenX
        nTargetScreenY = math.abs(nTargetScreenY) + screenSize.height
    end

    -- print("------------")
    -- print("target: ", nTargetScreenX, nTargetScreenY, bTargetFront)
    -- print("player: ", nPlayerScreenX, nPlayerScreenY)
    -- print("n3DDistance: ", n3DDistance)

    if IsFunction(tbOneTrace.farCallback) then tbOneTrace.farCallback() end
    self._setTraceVisible(tbOneTrace, true)
    local nFloor3DDistance = math.floor(n3DDistance / 64)
    local szDistanceStr = (nFloor3DDistance == 0) and "" or string.format("%d%s", nFloor3DDistance, g_tStrings.STR_METER)
    UIHelper.SetString(scriptView.LabelTrace, szDistanceStr)

    if ImgTraceIcon and szFrame and tbOneTrace.szLastFrame ~= szFrame then
        UIHelper.SetSpriteFrame(ImgTraceIcon, szFrame)
        tbOneTrace.szLastFrame = szFram
    end

    local nX, nY = nil, nil
    local bTargetNotInView = not self._isTargetInView(nTargetScreenX, nTargetScreenY)
    local bTargetInRect = self._isTargetInRect(nTargetScreenX, nTargetScreenY, tbOneTrace)
    if n3DDistance > SHOW_ON_FOOT_DISTANCE or not bTargetFront or bTargetNotInView or not bTargetInRect then
    --if n3DDistance > SHOW_ON_FOOT_DISTANCE or not bTargetFront or bTargetNotInView then

        -- 计算Player自己是否在屏幕中，如果不在屏幕中，那就设置成屏幕中心点的最下方 (screenSize.width/2, 0)
        local bPlayerNotInView = not self._isPlayerInView(nPlayerScreenX, nPlayerScreenY)
        local _nPlayerScreenX = bPlayerNotInView and screenSize.width/2 or screenSize.width/2
        local _nPlayerScreenY = bPlayerNotInView and 0 or screenSize.height/2

        local _nTargetScreenX = nTargetScreenX
        local _nTargetScreenY = nTargetScreenY
        -- 当自己不在屏幕中时，target的位置要做相应处理
        if bPlayerNotInView then
            _nTargetScreenX = cc.clampf(nTargetScreenX, 0, screenSize.width)
            _nTargetScreenY = cc.clampf(nTargetScreenY, 0, screenSize.height)

            if _nTargetScreenY == 0 and _nPlayerScreenY == 0 then
                _nPlayerScreenY = screenSize.height/2
                _nTargetScreenY = 0--screenSize.height
            end
        end

        -- 在矩形边缘显示箭头
        local nRadian = math.atan2(_nPlayerScreenY - _nTargetScreenY, _nTargetScreenX - _nPlayerScreenX) --弧度

        local nAngle = -(nRadian * (180 / math.pi)) -- 角度
        if nAngle < 0 then nAngle = nAngle + 360 end

        UIHelper.SetRotation(scriptView.WidgetArrow, nAngle + 90)
        UIHelper.SetPositionY(scriptView.ImgArrow, (nAngle > 35 and nAngle < 145) and nArrowBottomY or nArrowY)
        self._setTraceArrowVisible(tbOneTrace, true)

        nX = (nWidth / 2) * math.cos(nRadian)
        nY = (nHeight / 2) * math.sin(nRadian)
    else
        -- 在target脚下显示箭头
        local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
        local nTargetScreenRealX, nTargetScreenRealY = nTargetScreenX / nScaleX, nTargetScreenY / nScaleY
        local tPos = cc.Director:getInstance():convertToGL({x = nTargetScreenRealX, y = nTargetScreenRealY})
        nX, nY = UIHelper.ConvertToNodeSpace(scriptView.WidgetTraceRange, tPos.x, tPos.y)
        self._setTraceArrowVisible(tbOneTrace, false)
    end

    if IS_LOW_FREQUENCY or bTargetNotInView then
        nX = (nX + nContentWidth / 2)
        nY = (nY + nContentHeight / 2)
    end

    local nDeltaX, nDeltaY = nX - tbOneTrace.nLastX, nY - tbOneTrace.nLastY
    if nX and nY and not(nDeltaX == 0 and nDeltaY == 0) then
        if IS_LOW_FREQUENCY then
            UIHelper.StopAllActions(scriptView.WidgetTrace)
            local moveTo = cc.MoveTo:create(ANIM_DUARATION, cc.p(nX, nY))
            scriptView.WidgetTrace:runAction(moveTo)
        else
            if bTargetNotInView then
                UIHelper.StopAllActions(scriptView.WidgetTrace)
                local moveTo = cc.MoveTo:create(ANIM_DUARATION, cc.p(nX, nY))
                scriptView.WidgetTrace:runAction(moveTo)
            else
                UIHelper.SetPosition(scriptView.WidgetTrace, nX, nY)
            end
        end

        tbOneTrace.nLastX, tbOneTrace.nLastY = nX, nY
    end
end

function TraceMgr._setTraceVisible(tbOneTrace, bVisible)
    if not tbOneTrace then return end
    local scriptView = tbOneTrace.scriptView
    if scriptView then
        UIHelper.SetActiveAndCache(scriptView, scriptView.WidgetTrace, bVisible)
    end
end

function TraceMgr._setTraceArrowVisible(tbOneTrace, bVisible)
    if not tbOneTrace then return end
    local scriptView = tbOneTrace.scriptView
    if scriptView then
        UIHelper.SetActiveAndCache(scriptView, scriptView.WidgetArrow, bVisible)
    end
end

-- target 是否在屏幕中
function TraceMgr._isTargetInView(nTargetScreenX, nTargetScreenY)
    local bResult = false

    if nTargetScreenX and nTargetScreenY then
        local screenSize = UIHelper.GetScreenSize()
        if nTargetScreenX > 0 and nTargetScreenX < screenSize.width and nTargetScreenY > 0 and nTargetScreenY < screenSize.height then
            bResult = true
        end
    end

    return bResult
end

-- 玩家自己 是否在屏幕中
function TraceMgr._isPlayerInView(nPlayerScreenX, nPlayerScreenY)
    local bResult = false

    if nPlayerScreenX and nPlayerScreenY then
        local screenSize = UIHelper.GetScreenSize()
        if nPlayerScreenX > 0 and nPlayerScreenX < screenSize.width and nPlayerScreenY > 0 and nPlayerScreenY < screenSize.height then
            bResult = true
        end
    end

    return bResult
end

-- target 是否在矩形框之内
function TraceMgr._isTargetInRect(nTargetScreenX, nTargetScreenY, tbOneTrace)
    local bResult = false

    if tbOneTrace and tbOneTrace.scriptView then
        local nWorldPosX = tbOneTrace.scriptView.nWorldPosX
        local nWorldPosY = tbOneTrace.scriptView.nWorldPosY
        local nWidth = tbOneTrace.scriptView.nWidth
        local nHeight = tbOneTrace.scriptView.nHeight

        if nTargetScreenX and nTargetScreenY then
            local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
            local nNpcScreenRealX, nNpcScreenRealY = nTargetScreenX / nScaleX, nTargetScreenY / nScaleY
            bResult = nNpcScreenRealX > nWorldPosX and nNpcScreenRealX < nWorldPosX + nWidth and nNpcScreenRealY > nWorldPosY and nNpcScreenRealY < nWorldPosY + nHeight
        end
    end

    return bResult
end




























-- 任务追踪箭头
function TraceMgr._updateQuestTrace()
    local mainScritView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local WidgetTraceAnchor = mainScritView and mainScritView.WidgetTraceAnchor

    if not WidgetTraceAnchor then return end

    -- 先停掉所有
    -- for i = 1, 5 do
    --     local szName = "WidgetTraceRange_"..i
    --     local oneTraceNode = UIHelper.GetChildByName(WidgetTraceAnchor, szName)
    --     if oneTraceNode then
    --         local script = UIHelper.GetBindScript(oneTraceNode)
    --         TraceMgr.StopByScript(script)
    --     end
    -- end

    local tbQuestIDs = QuestData.GetTracingQuestIDList()
    local nCount = math.max(1, #tbQuestIDs)

    for k = 1, nCount do
        local szName = "WidgetTraceRange_"..k

        local oneTraceNode = UIHelper.GetChildByName(WidgetTraceAnchor, szName)
        if oneTraceNode then
            local script = UIHelper.GetBindScript(oneTraceNode)
            TraceMgr.StopByScript(script)
            script:OnEnter(k)
        else
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTraceRange, WidgetTraceAnchor, k)
            UIHelper.SetName(script._rootNode, szName)
        end
    end

end

-- 中地图的NPC追踪箭头
function TraceMgr._updateNpcTrace()
    local mainScritView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local WidgetTraceAnchor = mainScritView and mainScritView.WidgetTraceAnchor

    local szName = "WidgetNpcTraceRange"
    local oneTraceNode = UIHelper.GetChildByName(WidgetTraceAnchor, szName)
    if oneTraceNode then
        local script = UIHelper.GetBindScript(oneTraceNode)
        script:OnEnter()
    else
        if WidgetTraceAnchor then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetNpcTraceRange, WidgetTraceAnchor)
            UIHelper.SetName(script._rootNode, szName)
        end
    end
end

-- 拆分远程标记，不和WidgetNpcTraceRange共用一个节点，方便切地图清除
function TraceMgr._updateRemoteTrace(tbRemotePointData)
    if not tbRemotePointData then
        return
    end

    local mainScritView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local WidgetTraceAnchor = mainScritView and mainScritView.WidgetTraceAnchor

    local szName = "WidgetRemoteTraceRange"
    local szKey = tbRemotePointData.szKey

    local scriptTrace
    if self.tbRemotePointData and self.tbRemotePointData[szKey] then
        scriptTrace = self.tbRemotePointData[szKey].scriptTrace
    end

    local _fnRegClearEvent = function(script)
        Event.Reg(script, "LOADING_END", function()
            TraceMgr.ClearRemotePoint(szKey)
        end)
    end

    if scriptTrace then
        scriptTrace:OnEnter(tbRemotePointData)
    else
        if WidgetTraceAnchor then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetNpcTraceRange, WidgetTraceAnchor, tbRemotePointData)
            UIHelper.SetName(script._rootNode, szName)
            _fnRegClearEvent(script)

            self.tbRemotePointData[tbRemotePointData.szKey] = {tbData = tbRemotePointData, scriptTrace = script}
        end
    end
end