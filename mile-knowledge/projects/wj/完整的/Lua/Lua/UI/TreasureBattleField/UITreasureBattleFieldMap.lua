-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldMap
-- Date: 2023-05-25 11:27:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local NCHOICELINEMAXNUM = 6

local MAP_LOWEST_OPACITY = 0.5
local MAP_SCALE_MARGIN = 1.2

local UITreasureBattleFieldMap = class("UITreasureBattleFieldMap")

local tChooseLineConfigID = {
	[1] = 21,
	[2] = 22,
	[3] = 23,
	[4] = 24,
	[5] = 25,
	[6] = 26,
}

local function OnShowMap(self, nArea)
    local nIndex = MapHelper.GetMapMiddleMapIndex(self.nMapID, nArea)
    self:InitMapData(self.nMapID, nIndex)
end

function UITreasureBattleFieldMap:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	local player = GetClientPlayer()
    if not player then
        return
    end
    self.nMapID = player.GetMapID()
	self.tMapCircleSFX = {}
    PostThreadCall(OnShowMap, self, "GetRegionInfoByGameWorldPos", self.nMapID, player.nX, player.nY)

	self.tTeamSelectMapData = {}
	self.tTeamSelectMapPlayerInfo = nil
    self:UpdateInfo()
end

function UITreasureBattleFieldMap:OnExit()
    self.bInit = false
    self:UnRegEvent()
	Timer.DelAllTimer(self)
end

function UITreasureBattleFieldMap:BindUIEvent()
	for i, tog in ipairs(self.tbTogLine) do
		UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
			if bSelected then
				self:ChooseLine(i)
			end
		end)
	end

	UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
		for i = 0, 100, 20 do
			if self.nCurrentValue < i then
				self.nCurrentValue = i
				UIHelper.SetProgressBarPercent(self.SliderNum, self.nCurrentValue)
				self:UpdateMapOpacity()
				break
			end
		end
	end)

	UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
		for i = 100, 0, -20 do
			if self.nCurrentValue > i then
				self.nCurrentValue = i
				UIHelper.SetProgressBarPercent(self.SliderNum, self.nCurrentValue)
				self:UpdateMapOpacity()
				break
			end
		end
	end)

	UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.SliderNum, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            UIHelper.SetProgressBarPercent(self.SliderNum, self.nCurrentValue)
			self:UpdateMapOpacity()
        end

        if self.bSliding then
            self.nCurrentValue = UIHelper.GetProgressBarPercent(self.SliderNum)
            self.nCurrentValue = math.min(self.nCurrentValue, 100)
            self.nCurrentValue = math.max(self.nCurrentValue, 0)
			self:UpdateMapOpacity()
        end
    end)

	UIHelper.BindUIEvent(self.TogFollow, EventType.OnSelectChanged, function(_, bSelected)
		self:FollowLeader(bSelected)
	end)
end

function UITreasureBattleFieldMap:RegEvent()
	Event.Reg(self, "MIDDLE_MAP_JUEJING_GETLINEINFO", function ()
		if arg0 then
			self.tTeamSelectMapData = arg0
			self.tTeamSelectMapPlayerInfo = self:SetTeamSelectMapPlayerInfo(self.tTeamSelectMapData.tMateInfo)

			if self:IsTeamLeader() then
				UIHelper.SetVisible(self.LayoutMessageContent, true)
				UIHelper.SetVisible(self.ImgMessageContentBg, true)
				UIHelper.SetVisible(self.TogFollow, false)
			else
				if self.tTeamSelectMapPlayerInfo.bFollow then
					UIHelper.SetVisible(self.LayoutMessageContent, false)
					UIHelper.SetVisible(self.ImgMessageContentBg, false)
				else
					UIHelper.SetVisible(self.LayoutMessageContent, true)
					UIHelper.SetVisible(self.ImgMessageContentBg, true)
				end
				UIHelper.SetVisible(self.TogFollow, true)
				UIHelper.SetSelected(self.TogFollow, self.tTeamSelectMapPlayerInfo.bFollow, false)
			end

			if self.tTeamSelectMapPlayerInfo.nLine then
				self:ShowLootMode(self.tTeamSelectMapPlayerInfo.nLine)
			end

			self:ShowTeamSelectMapInformation()
		end
	end)

	Event.Reg(self, "MIDDLE_MAP_JUEJING_CHOOSELINE", function ()
		self.tTeamSelectMapData = arg0
		self.tTeamSelectMapPlayerInfo = self:SetTeamSelectMapPlayerInfo(self.tTeamSelectMapData.tMateInfo)
	end)

	Event.Reg(self, "MIDDLE_MAP_JUEJING_FOLLOWLEADER", function ()
		if arg1 then
			self.tTeamSelectMapData = arg0
			self.tTeamSelectMapPlayerInfo = self:SetTeamSelectMapPlayerInfo(self.tTeamSelectMapData.tMateInfo)

			if self.tTeamSelectMapPlayerInfo.bFollow then
				UIHelper.SetVisible(self.LayoutMessageContent, false)
				UIHelper.SetVisible(self.ImgMessageContentBg, false)
			else
				UIHelper.SetVisible(self.LayoutMessageContent, true)
				UIHelper.SetVisible(self.ImgMessageContentBg, true)
			end
			UIHelper.SetVisible(self.TogFollow, true)
			UIHelper.SetSelected(self.TogFollow, self.tTeamSelectMapPlayerInfo.bFollow, false)

			if self.tTeamSelectMapPlayerInfo and self.tTeamSelectMapPlayerInfo.nLine then
				self:ShowLootMode(self.tTeamSelectMapPlayerInfo.nLine)
			end

			self:ShowTeamSelectMapInformation()
		end
	end)

	Event.Reg(self, "MIDDLE_MAP_ON_JUEJING_STOPCHOOSELINE", function ()
		UIHelper.SetVisible(self.LayoutMessageContent, false)
		UIHelper.SetVisible(self.ImgMessageContentBg, false)
		UIHelper.SetVisible(self.WidgetMapLine, false)
		UIHelper.SetVisible(self.TogFollow, false)
	end)

	Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function ()
		if self:IsSelectLineMap() then
			self:GetLineInfo()
		end
	end)

	Event.Reg(self, EventType.OnClientPlayerLeave, function (nPlayerID)
		UIMgr.Close(self)
	end)

	Event.Reg(self, EventType.OnSceneTouchNothing, function ()
		UIMgr.Close(self)
	end)
end

function UITreasureBattleFieldMap:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldMap:UpdateInfo()
	self.nCurrentValue = 100
	UIHelper.SetProgressBarPercent(self.SliderNum, self.nCurrentValue)

	-- 线路相关
	UIHelper.SetSelected(self.TogFollow, false, false)
	UIHelper.SetVisible(self.TogFollow, false)
	UIHelper.SetVisible(self.WidgetMapLine, false)
	UIHelper.SetVisible(self.LayoutMessageContent, false)
	UIHelper.SetVisible(self.ImgMessageContentBg, false)
	UIHelper.SetVisible(self.ImgMapFlyLine, false)
	for index, img in ipairs(self.tbMapLine) do
		local tConfig = Table_GetMiddleMapLineConfig(tChooseLineConfigID[index])
		UIHelper.SetTexture(img, string.format("Resource/StormLine/%s.png", tConfig.szMobileImageLineName))
		UIHelper.SetVisible(img, true)
	end

	UIHelper.SetVisible(self.WidgetMark, false)
	UIHelper.PlayAni(self, self.AniAll, "AniRightShow")

	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
	for _, tog in ipairs(self.tbTogLine) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
	end
	if self:IsSelectLineMap() then
		self:GetLineInfo()
	end
	self:SelectLineMapAbnormalData()
    self:UpdatePassTime()
end

function UITreasureBattleFieldMap:InitMapData(nMapID, nIndex)
	self.nMapID = nMapID
	self.nIndex = nIndex
	self.CurPosComponent = require("Lua/UI/Map/Component/UIPositionComponent"):CreateInstance()
	self.RefPosComponent = require("Lua/UI/Map/Component/UIPositionComponent"):CreateInstance()
	self.tbMemberScripts = require("Lua/UI/Map/Component/UIPrefabComponent"):CreateInstance()
	self.tbMemberScripts:Init(self.WidgetTeammate, PREFAB_ID.WidgetTeammate)
	self.tbMarkScripts = require("Lua/UI/Map/Component/UIPrefabComponent"):CreateInstance()
	self.tbMarkScripts:Init(self.WidgetOtherMark, PREFAB_ID.WidgetTeammate)
	self.tbGainScripts = require("Lua/UI/Map/Component/UIPrefabComponent"):CreateInstance()
	self.tbGainScripts:Init(self.WidgetOtherMark, PREFAB_ID.WidgetTeammate)

	local szName = GBKToUTF8(Table_GetMapName(self.nMapID))
	local szPath = MapMgr.GetMapParams_UIEx(self.nMapID)
	local tbMapInfo = MapHelper.tbMiddleMapInfo[self.nMapID]
	if tbMapInfo and tbMapInfo[self.nIndex] then
		local tb = tbMapInfo[self.nIndex]
		if tb.name then
            szName = tb.name
        end
        self.LabelInformation:setString(szName)
		self.CurPosComponent:Init(tb.width, tb.height, tb.startx, tb.starty, tb.scale, self.nMapID)
		self.RefPosComponent:Init(tb.width, tb.height, tb.startx, tb.starty, tb.scale, self.nMapID)
		local szImage = szPath .. "minimap_mb\\" .. tb.image
		if Platform.IsMobile() then szImage = UIHelper.ConvertToMBPath(szImage) end
		UIHelper.SetTexture(self.ImgMap, szImage, false)
		UIHelper.UpdateMask(self.MaskMap)

		UIHelper.SetVisible(self.WidgetMark, true)
		self.OriScale = UIHelper.GetScale(self.ImgMap)

		self:ScaleToCircle()
		self:UpdateAll()
		Timer.AddCycle(self, 0.5, function ()
			self:UpdateAll()
		end)
	end
end

function UITreasureBattleFieldMap:SetTeamSelectMapPlayerInfo(arg0)
	local hPlayer = GetClientPlayer()
	local dwPlayerID = hPlayer.dwID

	for _,v in pairs(arg0) do
		if v.dwID == dwPlayerID then
			return v
		end
	end
end

function UITreasureBattleFieldMap:IsTeamLeader()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	if hPlayer.IsPartyLeader() then
		return true
	else
		return false
	end
end

-- 吃鸡地图 选择线路请求
function UITreasureBattleFieldMap:FollowLeader(bFollow)
	RemoteCallToServer("On_JueJing_FollowLeader", bFollow)
end

function UITreasureBattleFieldMap:ChooseLine(nLineID)
	RemoteCallToServer("On_JueJing_ChooseLine", nLineID)
end

function UITreasureBattleFieldMap:GetLineInfo()
	RemoteCallToServer("On_JueJing_GetLineInfo")
end

function UITreasureBattleFieldMap:IsSelectLineMap()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local scene = hPlayer.GetScene()
	if scene and scene.dwMapID == BATTLEMAPISSELECTLINEMAPID then
		return true
	else
		return false
	end
end

function UITreasureBattleFieldMap:SelectLineMapAbnormalData(isOpen)
	self:UpdateFlyLine(TreasureBattleFieldData.tLine)
end

function UITreasureBattleFieldMap:ShowLootMode(index)
	-- 显示自己的选线
	UIHelper.SetToggleGroupSelected(self.ToggleGroup, index-1)
	UIHelper.SetVisible(self.WidgetMapLine, true)

	if index and tonumber(index) ~= 0 and tonumber(index) <= NCHOICELINEMAXNUM then
		for i = 1, NCHOICELINEMAXNUM do
			if tonumber(index) == i then
				UIHelper.SetNodeGray(self.tbMapLine[i], false, false)
			else
				UIHelper.SetNodeGray(self.tbMapLine[i], true, false)
			end
		end
	end
end

function UITreasureBattleFieldMap:ShowTeamSelectMapInformation()
	local nSelfLineID = self.tTeamSelectMapPlayerInfo.nLine

	for _, v in pairs(self.tTeamSelectMapData.tMateInfo) do
		if v and v.nLine and v.nLine ~= 0 then
			if nSelfLineID == v.nLine then
			end
		end
	end
end

function UITreasureBattleFieldMap:UpdateFlyLine(tLine)
	if tLine and tLine[1] then
		local tConfig = Table_GetMiddleMapLineConfig(tLine[1])
		UIHelper.SetTexture(self.ImgMapFlyLine, string.format("Resource/StormLine/%s.png", tConfig.szMobileImageLineName))
		UIHelper.SetVisible(self.ImgMapFlyLine, true)
	else
		UIHelper.SetVisible(self.ImgMapFlyLine, false)
	end
end

function UITreasureBattleFieldMap:UpdatePassTime()
	local _, _, nBeginTime, nEndTime = GetBattleFieldPQInfo()
	local nCurrentTime = GetCurrentTime()
    if nBeginTime and nBeginTime > 0 then
		local nTime = 0
		if nEndTime ~= 0 and nCurrentTime > nEndTime then
			nTime = nEndTime - nBeginTime
		else
			nTime = nCurrentTime - nBeginTime
		end
		local szTime = string.format("%02d:%02d", math.floor(nTime / 60), math.floor(nTime % 60))
		UIHelper.SetString(self.LabelTime, szTime) --已用时间
	else
		UIHelper.SetString(self.LabelTime, "未开始") --已用时间
	end
end

function UITreasureBattleFieldMap:UpdateCircleInfo()
	local player = g_pClientPlayer
	if not player then
		return
	end
	local szNumText = "已刷圈："
	local tCircle
	local nIndexSafe = TreasureBattleFieldData.tSafeMapCircle[player.GetMapID()]
	if nIndexSafe then
        tCircle = TreasureBattleFieldData.tCircle[nIndexSafe]
    end
	local tSafeCircleRadius = TreasureBattleFieldData.tSafeCircleRadius
	if not tCircle then
		szNumText = szNumText .. 0 .. "/" .. #tSafeCircleRadius
	else
		for i = #tSafeCircleRadius, 1, -1 do
			if tCircle.fEndtDistance <= (tSafeCircleRadius[i]/64) + 5 then -- 加个5尺的容错
				szNumText = szNumText .. i .. "/" .. #tSafeCircleRadius
				break
			end
		end
	end
	UIHelper.SetString(self.LabelUpdate, szNumText)
end

function UITreasureBattleFieldMap:UpdateMapAll()
	local player = GetClientPlayer()
    if not player then
        return
    end

    local nRotation = MapMgr.GetPlayerRotation(player)
    self.ImgSelf:setRotation(nRotation)

    nRotation = MapMgr.GetCameraRotation()
    self.WidgetSelfCameraDirection:setRotation(nRotation)

    local imgX, imgY = self.CurPosComponent:LogicPosToMapPos(player.nX, player.nY)
    UIHelper.SetWorldPosition(self.WidgetLocation, imgX, imgY)
    self:UpdateTeamate(player)
	self:UpdateMarkNodes()
	self:UpdateGainNodes()
	self:UpdateCircleSFX()
end

function UITreasureBattleFieldMap:UpdateCircleSFX()
	for _, scriptSFX in pairs(self.tMapCircleSFX) do
		UIHelper.SetVisible(scriptSFX._rootNode, false)
	end
	for i, circle in pairs(TreasureBattleFieldData.tCircle) do
		local tInfo = circle.tInfo
		local scriptSFX = self.tMapCircleSFX[i]
		if not scriptSFX then
			scriptSFX = UIHelper.AddPrefab(PREFAB_ID.WidgetMapSfx, self.WidgetMapSFX, tInfo.szCirclePath)
			self.tMapCircleSFX[i] = scriptSFX
		elseif scriptSFX.szSFXPath ~= tInfo.szCirclePath then
			UIHelper.RemoveFromParent(scriptSFX._rootNode)
			scriptSFX = UIHelper.AddPrefab(PREFAB_ID.WidgetMapSfx, self.WidgetMapSFX, tInfo.szCirclePath)
			self.tMapCircleSFX[i] = scriptSFX
		end
		UIHelper.SetVisible(scriptSFX._rootNode, true)

		local fPercent = math.min(1, (GetLogicFrameCount() - circle.nStartFrame) / circle.nTotalFrame)
		local fDistance = fPercent * (circle.fEndtDistance - circle.fStartDistance) + circle.fStartDistance

		local nX = circle.nStartX + fPercent * (circle.nEndX - circle.nStartX)
		local nY = circle.nStartY + fPercent * (circle.nEndY - circle.nStartY)

		local nScale = fDistance * 64 * 2 * self.CurPosComponent.nScale / tInfo.nCircleDiameter
		scriptSFX.SFXMap:setScale(nScale)

		local imgX, imgY = self.CurPosComponent:LogicPosToMapPos(nX, nY)
		UIHelper.SetWorldPosition(scriptSFX.SFXMap, imgX, imgY)
	end
end

function UITreasureBattleFieldMap:UpdateTeamate(player)
    local nIndex = 1
    TeamData.Generator(function(dwID, tMemberInfo)
        if dwID == player.dwID or not tMemberInfo.bIsOnLine or tMemberInfo.dwMapID ~= self.nMapID then
            return
        end
		if tMemberInfo.bDeathFlag or player.nBattleFieldSide == BattleFieldData.OB_BATTLE_FIELD_SIDE then
			return
		end
        local script = self.tbMemberScripts:Alloc(nIndex)
		script:UpdateFrame("UIAtlas2_Public_PublicIcon_PublicIcon1_img_teammate.png")
        script:UpdatePosition(self.CurPosComponent, tMemberInfo.nPosX, tMemberInfo.nPosY)
        nIndex = nIndex + 1
    end)
    self.tbMemberScripts:Clear(nIndex)
end

function UITreasureBattleFieldMap:UpdateMarkNodes()
    local tMarkData = TreasureBattleFieldData.tMarkData or {}
    for i, v in ipairs(tMarkData) do
        local tBattleData = MapMgr.Table_GetBattleFieldData()
        local tParam = tBattleData[v.nType]

        local script = self.tbMarkScripts:Alloc(i)
        local x, y = unpack(v.aPoint)
        -- local szFrame = UIHelper.GBKToUTF8(tParam.szFrame)
		local szFrame = MapMgr.GetBattleFieldDataImage(v.nType)
        script:UpdateFrame(szFrame)
        script:UpdatePosition(self.CurPosComponent, x, y)
    end
    self.tbMarkScripts:Clear(#tMarkData + 1)
end

function UITreasureBattleFieldMap:UpdateGainNodes()
    local tGainData = TreasureBattleFieldData.tGainData or {}
    for i, v in ipairs(tGainData) do
        local tBattleData = MapMgr.Table_GetBattleFieldData()
        local tParam = tBattleData[v.nType]

        local script = self.tbGainScripts:Alloc(i)
        local x, y = unpack(v.aPoint)
        -- local szFrame = UIHelper.GBKToUTF8(tParam.szFrame)
		local szFrame = MapMgr.GetBattleFieldDataImage(v.nType)
        script:UpdateFrame(szFrame)
        script:UpdatePosition(self.CurPosComponent, x, y)
    end
    self.tbGainScripts:Clear(#tGainData + 1)
end

function UITreasureBattleFieldMap:UpdateMapScale()
	-- local player = GetClientPlayer()
    -- if not player then
    --     return
    -- end

	-- local imgRefX, imgRefY = self.RefPosComponent:LogicPosToMapPos(player.nX, player.nY)

	-- local nScale = (self.nCurrentValue / 100.0 + 1) * self.OriScale
	-- UIHelper.SetScale(self.ImgMap, nScale, nScale)
	-- self.CurPosComponent:Update(self.ImgMap)

	-- local imgX, imgY = self.CurPosComponent:LogicPosToMapPos(player.nX, player.nY)
	-- local nLastMapX, nLastMapY = UIHelper.GetWorldPosition(self.ImgMap)
	-- UIHelper.SetWorldPosition(self.ImgMap, nLastMapX-(imgX-imgRefX), nLastMapY-(imgY-imgRefY))
	-- self.CurPosComponent:Update(self.ImgMap)
	-- self:UpdateMapAll()
end

function UITreasureBattleFieldMap:ScaleToCircle(nTargetScale)
	local player = g_pClientPlayer
	if not player then
		return
	end

	local circle
	local nIndexSafe = TreasureBattleFieldData.tSafeMapCircle[player.GetMapID()]
	if nIndexSafe then
        circle = TreasureBattleFieldData.tCircle[nIndexSafe]
    end
	if not circle then
		return
	end

	local fPercent = math.min(1, (GetLogicFrameCount() - circle.nStartFrame) / circle.nTotalFrame)
	local fDistance = fPercent * (circle.fEndtDistance - circle.fStartDistance) + circle.fStartDistance

	local nX = circle.nStartX + fPercent * (circle.nEndX - circle.nStartX)
	local nY = circle.nStartY + fPercent * (circle.nEndY - circle.nStartY)

	local nRadius = fDistance * 64

	local nStartX, nEndX = self.RefPosComponent.nStartX, self.RefPosComponent.nStartX + self.RefPosComponent.nWidth / self.RefPosComponent.nScale
	local nStartY, nEndY = self.RefPosComponent.nStartY, self.RefPosComponent.nStartY + self.RefPosComponent.nHeight / self.RefPosComponent.nScale

	local nMinX, nMaxX = math.max(nStartX, math.min(nX - nRadius, player.nX)), math.min(nEndX, math.max(nX + nRadius, player.nX))
	local nMinY, nMaxY = math.max(nStartY, math.min(nY - nRadius, player.nY)), math.min(nEndY, math.max(nY + nRadius, player.nY))

	local nScaleX = math.max(1, (nEndX - nStartX) / (nMaxX - nMinX) / MAP_SCALE_MARGIN)
	local nScaleY = math.max(1, (nEndY - nStartY) / (nMaxY - nMinY) / MAP_SCALE_MARGIN)

	local nMaxScale = math.max(math.min(math.min(nScaleX, nScaleY), 10), 1)
	self.nMaxScale = self.nMaxScale or nMaxScale

	local nTargetScale = nTargetScale or nMaxScale
	nTargetScale = math.max(math.min(nMaxScale, nTargetScale), 1)

	UIHelper.SetScale(self.ImgMap, self.OriScale * nTargetScale, self.OriScale * nTargetScale)
	self.CurPosComponent:Update(self.ImgMap)

	local nAnchorX = (nMinX - nStartX) / ((nMinX - nStartX) + (nEndX - nMaxX))
	local nAnchorY = (nMinY - nStartY) / ((nMinY - nStartY) + (nEndY - nMaxY))
	local nDisX = (nEndX - nStartX) / nTargetScale - (nMaxX - nMinX)
	local nDisY = (nEndY - nStartY) / nTargetScale - (nMaxY - nMinY)
	local nCenterX = ((nMinX + nMaxX) + nDisX * (1 - 2 * nAnchorX)) / 2
	local nCenterY = ((nMinY + nMaxY) + nDisY * (1 - 2 * nAnchorY)) / 2

	local nMapCenterX, nMapCenterY = self.CurPosComponent:LogicPosToMapPos(nCenterX, nCenterY)
	local nMaskMinX, nMaskMaxX, nMaskMinY, nMaskMaxY = UIHelper.GetNodeEdgeXY(self.MaskMap)
	local nOffsetX, nOffsetY =  (nMaskMinX + nMaskMaxX) / 2 - nMapCenterX, (nMaskMinY + nMaskMaxY) / 2 - nMapCenterY
	local nMapPosX, nMapPosY = UIHelper.GetWorldPosition(self.ImgMap)
	UIHelper.SetWorldPosition(self.ImgMap, nMapPosX + nOffsetX, nMapPosY + nOffsetY)
	self.CurPosComponent:Update(self.ImgMap)
	self:UpdateMapAll()
end

function UITreasureBattleFieldMap:UpdateMapOpacity()
	-- local nLowest = MAP_LOWEST_OPACITY
	-- local opacity = math.floor(((self.nCurrentValue / 100.0) * (1 - nLowest) + nLowest) * 255)
	-- UIHelper.SetOpacity(self._rootNode, opacity)
	if not self.nMaxScale then
		return
	end
	local nTargetScale = (self.nMaxScale - 1) / 100.0 * self.nCurrentValue + 1
	self:ScaleToCircle(nTargetScale)
end

function UITreasureBattleFieldMap:UpdateAll()
	self.CurPosComponent:Update(self.ImgMap)
	self.RefPosComponent:Update(self.ImgMap)
    self:UpdatePassTime()
	self:UpdateCircleInfo()
	self:UpdateMapAll()
end

return UITreasureBattleFieldMap