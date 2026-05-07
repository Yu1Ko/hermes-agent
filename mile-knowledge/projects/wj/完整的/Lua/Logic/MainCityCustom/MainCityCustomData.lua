-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: MainCityCustomData
-- Date: 2024-07-17 15:40:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

MainCityCustomData = MainCityCustomData or {className = "MainCityCustomData"}
local self = MainCityCustomData
-------------------------------- 消息定义 --------------------------------
MainCityCustomData.Event = {}
MainCityCustomData.Event.XXX = "MainCityCustomData.Msg.XXX"

function MainCityCustomData.Init()
	self.bSubsidiaryCustomState = false
	self.nCustomDpsBgOpacity = nil
	self.bHurtBgOpacityChanged = false
	
	self.bChatOpacityChanged = false
	self.bChatContentSizeChanged = false
	self.tbFontSizeType = {}

	self.nDevice = MainCityCustomData.GetDeviceType()
	self.RegEvent()
end

function MainCityCustomData.UnInit()
	self.bSubsidiaryCustomState = false
end

function MainCityCustomData.RegEvent()
	Event.Reg(self, EventType.OnAccountLogout, function ()
		self.bSubsidiaryCustomState = false
    end)
end

function MainCityCustomData.InitStorageDragNodeScale()
	local tbDefaultScaleInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], Storage.ControlMode.nMode)
	local tbType = {"nActionBar","nDbm","nDps", "nTeamNotice"}
	
	for k, szType in pairs(tbType) do
		if not Storage.MainCityNode.tbMaincityDragNodeScale[szType] then
			local nDefaultSize = clone(tbDefaultScaleInfo[szType])
			Storage.MainCityNode.tbMaincityDragNodeScale[szType] = nDefaultSize
		end
	end
	Storage.MainCityNode.Dirty()
end

function MainCityCustomData.EnterSubsidiaryCustom(bEnter)
	local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
	if not tbScript then return end
	local tbFakeNodeList = tbScript.tbFakeScriptList
	if tbFakeNodeList and not table.is_empty(tbFakeNodeList) then
		self.bSubsidiaryCustomState = bEnter
		for k, script in pairs(tbFakeNodeList) do
			UIHelper.SetVisible(script.ImgSelectZoneLight, not bEnter)
			UIHelper.SetVisible(script.ImgSelectZone, false)
			if k == CUSTOM_TYPE.MENU then
				script:UpdateSubsidiaryCustomState(bEnter)
			end
		end
		UIHelper.SetVisible(tbScript.BtnLeaveCustom, bEnter)
		local tbHintScript = UIMgr.GetViewScript(VIEW_ID.PanelHintSelectMode)
		if tbHintScript then
			UIHelper.SetVisible(tbHintScript._rootNode, not bEnter)
		end
		UIHelper.SetVisible(tbScript.WidgetMiddleInfo, bEnter)
		UIHelper.SetLocalZOrder(tbScript.WidgetMiddleInfo, 2)
		UIHelper.SetLocalZOrder(tbScript.ImgHintDrag, 3)
		UIHelper.SetVisible(tbScript.ImgHintDrag, bEnter)
		UIHelper.SetVisible(tbScript.LabelHintDrag2, bEnter)

		Event.Dispatch(EventType.OnUpdateDragNodeCustomState, self.bSubsidiaryCustomState)

		if not bEnter then
			tbScript:UpdateAllNodeOverLappingState(tbFakeNodeList, CUSTOM_BTNSTATE.ENTER)
		end
	end

end
function MainCityCustomData.IsDraggableNodePositionChanged()
	local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
	if not tbScript then return end
	local tbNodeList = {
        tbScript.WidgetDbm,
        tbScript.WidgetHurtStatistics,
		tbScript.WidgetTeamNotice,
    }
	for k, node in pairs(tbNodeList) do
		local script = UIHelper.GetBindScript(node)
		if script.bMoved then
			return true
		end
	end

	local targetNode = UIHelper.GetParent(tbScript.scriptWidgetMainCityActionBar._rootNode)
	local node = tbScript.scriptWidgetMainCityActionBar.BtnActionBar
	if targetNode and not table.is_empty(Storage.MainCityNode.tbMaincityNodePos) then
		local nX = UIHelper.GetWorldPositionX(node)
		local nY = UIHelper.GetWorldPositionY(node)
		local tbPositionInfo = Storage.MainCityNode.tbMaincityNodePos[targetNode:getName()]
		if tbPositionInfo.nX ~= nX or tbPositionInfo.nY ~= nY then
			return true
		end
	end
	return false
end

function MainCityCustomData.SaveDraggableNodePosition()
	Event.Dispatch(EventType.OnSaveDragNodePosition)
end

function MainCityCustomData.ShowScaleSetTip(tbScript, nNodeType)
	local tbMaincityScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
	if not tbMaincityScript then return end
	local tbNodeList = {
        [DRAGNODE_TYPE.DBM] = tbMaincityScript.WidgetDbm,
        [DRAGNODE_TYPE.DPS] = tbMaincityScript.WidgetHurtStatistics,
		[DRAGNODE_TYPE.ACTIONBAR] = tbMaincityScript.scriptWidgetMainCityActionBar._rootNode,
		[DRAGNODE_TYPE.TEAMNOTICE] = tbMaincityScript.WidgetTeamNotice,
    }

	for k, node in pairs(tbNodeList) do
		local script = UIHelper.GetBindScript(node)
		if script then
			UIHelper.SetVisible(script.MaskLight, nNodeType == k)
		end
	end

	local tbShowFont = clone(Storage.ControlMode.tbFontShow)
	if not self.tbFontSizeType or table.is_empty(self.tbFontSizeType) then
		self.tbFontSizeType = clone(Storage.MainCityNode.tbMaincityDragNodeScale)
	end
    local tips, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipsFreeSetting, tbScript.ImgSelectZone, self.tbFontSizeType, nNodeType, self.nDevice, tbShowFont, Storage.ControlMode.nMode)

	Timer.AddFrame(self, 2, function ()
        local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(itemTips.ImgTipsBg)
        tips:SetSize(nTipsWidth, nTipsHeight)
        tips:Update()

		if nNodeType == DRAGNODE_TYPE.DPS then
			local tbScriptHurt = UIHelper.GetBindScript(tbNodeList[DRAGNODE_TYPE.DPS])
			if tbScriptHurt then
				local nOpacity = UIHelper.GetOpacity(tbScriptHurt.hurtStatisticsScript.ImgListBg)
				itemTips:UpdateAlphaSettingInfo(nOpacity)
			end
		end
    end)

end

function MainCityCustomData.IsDragNodeScaleChanged()
	for k, nScale in pairs(self.tbFontSizeType) do
		local nStorageScale = Storage.MainCityNode.tbMaincityDragNodeScale[k]
		if nScale ~= nStorageScale then
			return true
		end
	end
	return false
end

function MainCityCustomData.SaveDraggableNodeScale(bSave)
	if bSave then
		Storage.MainCityNode.tbMaincityDragNodeScale = clone(self.tbFontSizeType) or {}
		self.tbFontSizeType = {}
		Storage.MainCityNode.Dirty()
	else
		self.tbFontSizeType = clone(Storage.MainCityNode.tbMaincityDragNodeScale)
		Event.Dispatch(EventType.OnSetDragNodeScale, self.tbFontSizeType)
	end
end

local tbDefaultPositionList = {--默认世界坐标，1600 x 900下的世界坐标
	[DRAGNODE_TYPE.ACTIONBAR] = {620, 160},
	[DRAGNODE_TYPE.DBM] = {1161, 885},
	[DRAGNODE_TYPE.DPS] = {460, 750},
	[DRAGNODE_TYPE.TEAMNOTICE] = {460, 510}
}

function MainCityCustomData.ResetDragNodePosition(nType, szType)
	local tbDefaultScaleInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], Storage.ControlMode.nMode)
	self.tbFontSizeType[szType] = clone(tbDefaultScaleInfo[szType])
	Event.Dispatch(EventType.OnSetDragNodeScale, self.tbFontSizeType)
	Event.Dispatch(EventType.OnResetDragNodePosition, tbDefaultPositionList, nType)
end

function MainCityCustomData.ResetAllDragNodeScale()
	local tbDefaultScaleInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], Storage.ControlMode.nMode)
	local tbType = {"nActionBar","nDbm","nDps", "nTeamNotice"}
	self.tbFontSizeType = {}
	for k, szType in pairs(tbType) do
		local nDefaultSize = clone(tbDefaultScaleInfo[szType])
		self.tbFontSizeType[szType] = nDefaultSize
	end
	Event.Dispatch(EventType.OnSetDragNodeScale, self.tbFontSizeType)
end

function MainCityCustomData.GetCustomActionSkillData()
	local tbSkillList = {
		[1] = {4, 0, 5, 34187},
		[2] = {4, 0, 5, 33175},
		[3] = {4, 0, 5, 33047},
		[4] = {4, 0, 5, 33185},
		[5] = {4, 0, 5, 34187},
		[6] = {4, 0, 5, 33038},
		[7] = {4, 0, 5, 40212},
		[8] = {4, 0, 5, 40211},
		[9] = {4, 0, 5, 33404},
		[10] = {4, 0, 5, 33038}
	}
	return tbSkillList
end

function MainCityCustomData.SetHurtBgOpacity(nOpacity)
	self.nCustomDpsBgOpacity = nOpacity
end

function MainCityCustomData.GetHurtBgOpacity()
	return self.nCustomDpsBgOpacity
end

function MainCityCustomData.SetHurtBgOpacityChanged(bChanged)
	self.bHurtBgOpacityChanged = bChanged
end

function MainCityCustomData.GetHurtBgOpacityChanged()
	return self.bHurtBgOpacityChanged
end

function MainCityCustomData.SaveHurtBgOpacity(bSave)
	local nOpacity = MainCityCustomData.GetHurtBgOpacity()
	if bSave and nOpacity then
		Storage.MainCityNode.tbDpsBgOpcity.nOpacity = nOpacity
	else
		Event.Dispatch(EventType.OnSetDragDpsBgOpacity, Storage.MainCityNode.tbDpsBgOpcity.nOpacity or Storage.MainCityNode.tbDpsBgOpcity.nDefault)
	end
	self.SetHurtBgOpacityChanged(false)
	self.SetHurtBgOpacity(nil)
end

function MainCityCustomData.ResetDragNodeBgOpacity(nNodeType)
	if nNodeType == DRAGNODE_TYPE.DPS then
		local nOpacity = clone(Storage.MainCityNode.tbDpsBgOpcity.nDefault) or 160
		self.SetHurtBgOpacity(nOpacity)
		Event.Dispatch(EventType.OnSetDragDpsBgOpacity, nOpacity)
	end
end
-------------------------主界面自定义------------------------------
function MainCityCustomData.UpdateMainCitySkillBoxNonVisible()
	local tbDefaultPositionInfo = {
		nX = 1590,
		nY = 25,
		width = 1600,
		height = 900
	}
	local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
	if not tbScript then return end
	local size = UIHelper.GetCurResolutionSize()
	if not tbScript.scriptSkill then return end
	local nX, nY = UIHelper.GetWorldPosition(tbScript.scriptSkill._rootNode)
	local nRadioX, nRadioY = size.width / tbDefaultPositionInfo.width, size.height / tbDefaultPositionInfo.height
	local nDefaultX, nDefaultY = tbDefaultPositionInfo.nX * nRadioX, tbDefaultPositionInfo.nY * nRadioY
	if math.abs(nDefaultX - nX) > 125 or math.abs(nDefaultY - nY) > 125 then
		UIHelper.SetVisible(tbScript.scriptSkill.BoxNon, false)
	else
		UIHelper.SetVisible(tbScript.scriptSkill.BoxNon, true)
	end
end

function MainCityCustomData.GetNodeOverLapping(nMx1, nMy1, width, height, node)
	if not node then
		return false
	end
	--获取node左上角坐标和宽高
	local nXmin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(node, true)
	local nTx1, nTy1 = nXmin, nYMax
	local nTargetWidth, nTargetHeight = UIHelper.GetScaledContentSize(node)
	local nOverWidth = math.max(0, math.min(nMx1 + width, nTx1 + nTargetWidth) - math.max(nMx1, nTx1))
	local nOverHeight = math.max(0, math.min(nMy1, nTy1) - math.max(nMy1 - height, nTy1 - nTargetHeight))
	local area = nOverWidth * nOverHeight
	return area > 0, nOverWidth, nOverHeight
end

function MainCityCustomData.GetMainCityNodeOverLappingByNode(tbFirstNode, tbSecondNode)
	if not tbFirstNode or not tbSecondNode then
		return false
	end
		--获取node左上角坐标和宽高
	local nXmin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(tbFirstNode, true)
	local nTx1, nTy1 = nXmin, nYMax
	local nTargetWidth, nTargetHeight = UIHelper.GetScaledContentSize(tbFirstNode)

	local nMx1, _, _, nMy1 = UIHelper.GetNodeEdgeXY(tbSecondNode, true)
	local width, height = UIHelper.GetScaledContentSize(tbSecondNode)
	local nOverWidth = math.max(0, math.min(nMx1 + width, nTx1 + nTargetWidth) - math.max(nMx1, nTx1))
	local nOverHeight = math.max(0, math.min(nMy1, nTy1) - math.max(nMy1 - height, nTy1 - nTargetHeight))
	local area = nOverWidth * nOverHeight
	return area > 0
end

function MainCityCustomData.ResetCustomStorageData()
	Storage.ControlMode.tbMainCityNodeScaleType = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {
            nMap = 0,
            nSkill = 0,
            nChat = 0,
            nTask = 0,
            nTeam = 0,
            nBuff = 0,
            nQuickuse = 0,
            nPlayer = 0,
            nTarget = 0,
            nLeftBottom = 0,
			nEnergyBar = 0,
			nSpecialSkillBuff = 0,
			nDxSkill = 0,
            nKillFeed = 0,
        },
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {
            nMap = 0,
            nSkill = 0,
            nChat = 0,
            nTask = 0,
            nTeam = 0,
            nBuff = 0,
            nQuickuse = 0,
            nPlayer = 0,
            nTarget = 0,
            nLeftBottom = 0,
			nEnergyBar = 0,
			nSpecialSkillBuff = 0,
			nDxSkill = 0,
            nKillFeed = 0,
        },
    }

    Storage.ControlMode.tbFontShow = {
        [CUSTOM_TYPE.CUSTOMBTN] = true,
        [CUSTOM_TYPE.MENU] = true,
        [CUSTOM_TYPE.SKILL] = true,
    }
    Storage.ControlMode.tbClassicSize = nil
    Storage.ControlMode.tbClassicPositionInfo = {}

    Storage.ControlMode.tbSimpleSize = nil
    Storage.ControlMode.tbSimplePositionInfo = {}

    Storage.ControlMode.tbDefaultClassicSize = nil
    Storage.ControlMode.tbDefaultClassicPositionInfo = {}

    Storage.ControlMode.tbDefaultSimpleSize = nil
    Storage.ControlMode.tbDefaultSimplePositionInfo = {}

    Storage.ControlMode.tbChatContentSize = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {},
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {},
    }

    Storage.ControlMode.tbChatBtnSelectSize = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {},
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {},
    }

    Storage.ControlMode.tbDefaultPosition = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = true,
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = true,
    }

    Storage.ControlMode.nVersion = CUSTOM_VERSION
    Storage.ControlMode.Flush()
end

function MainCityCustomData.UpdateIOSChatOffSetY(nMode, szName, nOffsetY)
	local nResult = nOffsetY
	if Platform.IsIos() then
		if nMode == MAIN_CITY_CONTROL_MODE.CLASSIC and (szName == "nChat" or szName == "nQuickuse") then
			nResult = nOffsetY + Device.GetHomeIndicatorHeight() / 2
		end
	end

	return nResult
end

function MainCityCustomData.UpdateFontSizeTabByOverLap(tbMaincityScript)
	local tbMapScript = UIHelper.GetBindScript(tbMaincityScript.WidgetRightTopMapCopy)
	local tbTargetScript = UIHelper.GetBindScript(tbMaincityScript.WidgetTargetInfoAnchorCopy)
	if not tbMapScript or not tbTargetScript then
		return
	end
	if self.GetMainCityNodeOverLappingByNode(tbMapScript.BtnSelectZone, tbTargetScript.BtnSelectZone) and self.nDevice == DEVICE_TYPE.PHONE then
		for k, tbInfo in pairs(UIFontSizeTab) do
			if tbInfo.szDevice == "Phone" then
				local nSmallSize = clone(tbInfo.nSmallSize)
				UIFontSizeTab[k].nMap = nSmallSize
				UIFontSizeTab[k].nTarget = nSmallSize
			end
		end
	end
end

function MainCityCustomData.SetChatBgOpacityChanged(bChanged)
	if self.bChatOpacityChanged == bChanged then
		return
	end
	self.bChatOpacityChanged = bChanged
end

function MainCityCustomData.GetChatBgOpacityChanged()
	return self.bChatOpacityChanged
end

function MainCityCustomData.SetChatContentSizeChanged(bChanged)
	if self.bChatContentSizeChanged == bChanged then
		return
	end
	self.bChatContentSizeChanged = bChanged
end

function MainCityCustomData.GetChatContentSizeChanged()
	return self.bChatContentSizeChanged
end

function MainCityCustomData.GetDeviceType()
	local nDevice = DEVICE_TYPE.PC
    if Platform.IsWindows() or Platform.IsMac() then
        nDevice = DEVICE_TYPE.PC
        if Channel.Is_WLColud() then
            nDevice = DEVICE_TYPE.PHONE
        end
    elseif Platform.IsMobile() then
        nDevice = DEVICE_TYPE.PHONE
        if Device.IsIPad() or Device.IsPad() then
            nDevice = DEVICE_TYPE.PAD
        end
    end

	return nDevice
end

function MainCityCustomData.GetFontSizeInfo()
	if not self.tbFontSizeType or table.is_empty(self.tbFontSizeType) then
		return Storage.MainCityNode.tbMaincityDragNodeScale
	end
	return self.tbFontSizeType
end