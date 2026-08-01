-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIMainCityTrace
-- Date: 2022-11-26 22:28:35
-- Desc: ?
-- ---------------------------------------------------------------------------------
MAIN_CITY_TRACE_POINT = nil -- 给外面调用的

local UIMainCityTrace = class("UIMainCityTrace")

function UIMainCityTrace:OnEnter(nIndex)
    self.nIndex = nIndex or 1
    self.nAreaID = 0
    self.nTraceQuestID = nil
    self.tbTracePoint = nil

    self.bInFaceState = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nContentWidth, self.nContentHeight = UIHelper.GetContentSize(self.WidgetTraceRange)
        self.nWidth, self.nHeight = self.nContentWidth, self.nContentHeight

        self.nArrowY = UIHelper.GetPositionY(self.ImgArrow)
        self.nArrowBottomY = self.nArrowY + 20

        self.nWorldPosX, self.nWorldPosY = UIHelper.GetWorldPosition(UIHelper.GetParent(self.WidgetTraceRange))
        self.nWorldPosX = self.nWorldPosX - self.nWidth / 2
        self.nWorldPosY = self.nWorldPosY - self.nHeight / 2

        -- 防止重叠，往外扩大一点
        if self.nIndex == 2 then
            self.nWidth = self.nWidth + 100
            self.nHeight = self.nHeight + 100

            self.nWorldPosX = self.nWorldPosX - 50
            self.nWorldPosY = self.nWorldPosY - 50
        end
    end

    local szFrame = (self.nIndex == 1) and "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_mubiao" or "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_mubiao2"
    UIHelper.SetSpriteFrame(self.ImgTrace, szFrame)

    UIHelper.SetVisible(self.WidgetTrace, false)
    self:UpdateTracePoint()
end

function UIMainCityTrace:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TraceMgr.StopByScript(self)

    MAIN_CITY_TRACE_POINT = nil
end

function UIMainCityTrace:BindUIEvent()

end

function UIMainCityTrace:RegEvent()
    Event.Reg(self, "UPDATE_REGION_INFO", function(nAreaID)
        self.nAreaID = nAreaID
    end)

    Event.Reg(self, EventType.OnQuestTracingTargetChanged, function(nAreaID)
        self:UpdateTracePoint()
    end)

    Event.Reg(self,"QUEST_ACCEPTED", function(nQuestIndex, dwQuestID)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, "SET_QUEST_STATE", function(nQuestIndex)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, "QUEST_CANCELED", function(dwQuestID)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, "QUEST_FINISHED", function(dwQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        self:UpdateTracePoint()
    end)



    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self:UpdateTracePoint() --切地图玩家进入场景时刷新追踪状态
    end)

    -- Event.Reg(self, EventType.OnCameraZoom, function(nScale)
    --     self.nCameraZoom = nScale
    --     local fDragYawSpeed, fMaxCameraDistance = Camera_GetParams()
    --     -- print("------", tostring(fMaxCameraDistance * nScale))
	-- end)

    Event.Reg(self, "FOCUS_FACE_STATUS_CHANGE", function(bInFaceState)
        self.bInFaceState = bInFaceState
    end)

    Event.Reg(self, "Helper_SetQuestArrow", function(bShow)
        self:UpdateTracePoint()
    end)

    Event.Reg(self, EventType.OnQuestTraceFlyTo, function(nFlyTime, nFromWorldX, nFromWorldY, nToWorldX, nToWorldY)
        self:FlyTo(nFlyTime, nFromWorldX, nFromWorldY, nToWorldX, nToWorldY)
    end)
end

function UIMainCityTrace:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMainCityTrace:UpdateTracePoint()
    local tbTraceQuestID = QuestData.GetTracingQuestIDList()
    self.nTraceQuestID = #tbTraceQuestID >= self.nIndex and tbTraceQuestID[self.nIndex] or 0
    local tbToNextInfo = self.nIndex == 1 and QuestData.CheckToNextPoint() or nil
    local tbPoints = tbToNextInfo and tbToNextInfo.tbPoints or nil

    self.tbTracePoint = tbPoints
    if  self.nTraceQuestID and self.nTraceQuestID ~= 0 then--有任务追踪就执行任务追踪
        self.tbTracePoint = self:_getTracePoint()
    end

    MAIN_CITY_TRACE_POINT = self.tbTracePoint

    if not self.tbTracePoint then
        TraceMgr.StopByScript(self)
        return
    end

    local dwTemplateID = self.tbTracePoint and self.tbTracePoint.dwTemplateID or nil
    TraceMgr.Start(self, self.tbTracePoint, function() return self:CheckVisible() end, function() end, function()
        if self.bFarFromTarget then
            Event.Dispatch(EventType.OnQuestNearTarget, self.nTraceQuestID)
            self.bFarFromTarget = false
        end
    end, nil, function()
        if not self.bFarFromTarget then
            Event.Dispatch(EventType.OnQuestLeaveTarget, self.nTraceQuestID)
            self.bFarFromTarget = true
        end
    end, dwTemplateID)
end

function UIMainCityTrace:CheckVisible()
    local bVisible = true

    if self.bInFaceState then
        bVisible = false
    end

    local bCanShowTrace = MapMgr.CanShowTrace()
    if not bCanShowTrace then
        bVisible = false
    end

    return bVisible
end

function UIMainCityTrace:_getTracePoint()
    -- local player = GetClientPlayer()
    -- local scene = player.GetScene()
    -- local dwMapID = scene.dwMapID
    local nQuestID = self.nTraceQuestID

	-- if not player or not scene or dwMapID == 0 or nQuestID == 0 --[[or not QuestData.IsInCurrentMap(nQuestID)]] then
	-- 	return
	-- end

    -- local nAreaID = self.nAreaID
    -- local tbQuestInfo = QuestData.GetQuestInfo(nQuestID)
    -- local tbQuestConf = QuestData.GetQuestConfig(nQuestID)
    -- local tbQuestTrace = player.GetQuestTraceInfo(nQuestID)
    -- local nQuestPhase = player.GetQuestPhase(nQuestID)

    -- local tbPoint = nil

    -- if tbQuestTrace.fail then
	-- 	tbPoint = self:GetQuestState("Failed", nQuestID, "accept", 0, nAreaID)
	-- 	--m_questvalue = updatequest_name(tQuestTrace, tQuestStringInfo)
	-- elseif tbQuestTrace.finish or nQuestPhase == 2 then
	-- 	tbPoint = self:GetQuestState("Finish", nQuestID, "finish", 0, nAreaID)
	-- 	--m_questvalue = updatequest_name(tQuestTrace, tQuestStringInfo)
    -- else
    --     for k, v in pairs(tbQuestTrace.quest_state) do
    --         if v.have < v.need then
    --             tbPoint = self:GetQuestState("UnFinish", nQuestID, "quest_state", v.i, nAreaID)
    --             --m_questvalue = updatequest_state(v, tQuestStringInfo, k)
    --             --m_multipoint = (v.need > 1)
    --             break
    --         end
    --     end

    --     for k, v in pairs(tbQuestTrace.kill_npc) do
    --         if v.have < v.need then
    --             tbPoint = self:GetQuestState("UnFinish", nQuestID, "kill_npc", v.i, nAreaID) or tbPoint
    --             --m_questvalue = updatequest_npc(v, k)
    --             --m_multipoint = (v.need > 1)
    --             -- break
    --         end
    --     end

    --     for k, v in pairs(tbQuestTrace.need_item) do
    --         if v.have < v.need then
    --             tbPoint = self:GetQuestState("UnFinish", nQuestID, "need_item", v.i, nAreaID) or tbPoint
    --             --m_questvalue = updatequest_item(v, k)
    --             --m_multipoint = (v.need > 1)
    --             -- break
    --         end
    --     end
    -- end

    local nMapID, tbPoint = QuestData.GetQuestMapIDAndPoints(nQuestID)
    local player = GetClientPlayer()
    if not player then return end
    local scene = player.GetScene()
    local dwMapID = scene.dwMapID
    if nMapID ~= dwMapID then return end
    return tbPoint
end


-- function UIMainCityTrace:GetQuestState(szFinishState, m_quest_id, szType, nIndex, nAreaID)
-- 	local m_othermap = {}
-- 	local hPlayer = GetClientPlayer()
-- 	if not hPlayer then
-- 		return
-- 	end
-- 	local hScene = hPlayer.GetScene()
-- 	local dwMapID = hScene.dwMapID
--     local m_tracestate = ""

-- 	local m_tNearestRegion = nil
-- 	local m_tPoint, m_tRegion = TableQuest_GetFirstPoint(m_quest_id, szType, nIndex, dwMapID, nAreaID)
-- 	if m_tRegion and m_tRegion.type ~= "R" then
-- 		m_tRegion = nil
-- 	end

-- 	if m_tRegion then
-- 		m_tNearestRegion = m_tRegion[1]
-- 	end

-- 	local hQuestInfo = GetQuestInfo(m_quest_id)
-- 	local tQuestStringInfo = Table_GetQuestStringInfo(m_quest_id)

-- 	if m_tPoint then
-- 		m_othermap = {}
-- 		m_tracestate = szFinishState .. "_Target"
-- 		m_isTarget = true
-- 	end

-- 	--if m_tracestate == "UnFinish_Target" or m_tracestate == "Finish_Target" or m_tracestate == "Failed_Target" then
--     -- if m_tracestate == "Failed_Target" then
-- 	-- 	return
-- 	-- end

-- 	local tMapID = TableQuest_GetMapIDs(m_quest_id, szType, nIndex)
-- 	if not tMapID then
-- 		return
-- 	end

-- 	local bInDungeon = true
--     local bIsInScene = false
-- 	for _, k in pairs(tMapID) do
--         local _dwMapID = k[1]
-- 		local _, nMapType = GetMapParams(_dwMapID)
-- 		if nMapType ~= 1 then
-- 			bInDungeon = false
-- 		end
--         if not bIsInScene and _dwMapID == dwMapID then
--             bIsInScene = true
--         end
-- 	end

--     if not bIsInScene then
--         return
--     end

-- 	if not bInDungeon then
-- 		if m_tracestate == "UnFinish_Dungeon" then
-- 			m_othermap = {}
-- 		end

-- 		m_tracestate = szFinishState .. "_Carriage"
-- 		for _, k in pairs(tMapID) do
-- 			if not m_othermap[k] then
-- 				m_othermap[k] = true
-- 			end
-- 		end
-- 	end

-- 	--if m_tracestate == "UnFinish_Carriage" or m_tracestate == "Finish_Carriage" or m_tracestate == "Failed_Carriage" then
--     -- if m_tracestate == "Failed_Carriage" then
-- 	-- 	return
-- 	-- end

-- 	m_tracestate = szFinishState .. "_Dungeon"
-- 	for _, k in pairs(tMapID) do
-- 		if not m_othermap[k] then
-- 			m_othermap[k] = true
-- 		end
-- 	end

--     return m_tPoint
-- end

function UIMainCityTrace:FlyTo(nFlyTime, nFromWorldX, nFromWorldY, nToWorldX, nToWorldY)
    TraceMgr.StopByScript(self)

    UIHelper.SetVisible(self.WidgetTrace, true)
    UIHelper.SetVisible(self.WidgetArrow, false)
    UIHelper.SetString(self.LabelTrace, "")

    local tPosFrom = self.WidgetTraceRange:convertToNodeSpace({ x = nFromWorldX, y = nFromWorldY })
    local tPosTo = self.WidgetTraceRange:convertToNodeSpace({ x = nToWorldX, y = nToWorldY })
    local nFromNodeX, nFromNodeY = tPosFrom.x, tPosFrom.y
    local nToNodeX, nToNodeY = tPosTo.x, tPosTo.y

    local moveToStart = cc.MoveTo:create(0, tPosFrom)
    local moveToEnd = cc.MoveTo:create(nFlyTime or 0.3, tPosTo)
    local callback = cc.CallFunc:create(function()
        Event.Dispatch(EventType.OnQuestTraceFlyToFinish)
        self:UpdateTracePoint()
    end)

    local action = cc.Sequence:create(moveToStart, moveToEnd, callback)
    self.WidgetTrace:stopAllActions()
    self.WidgetTrace:runAction(action)
end




return UIMainCityTrace