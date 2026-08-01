-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityWidgetFreeSetting
-- Date: 2024-05-20 14:51:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMainCityWidgetFreeSetting = class("UIMainCityWidgetFreeSetting")
local tbNodeInfo = {
	[CUSTOM_TYPE.SKILL] = {
		szTitle = "技能模块",
		szType = "nSkill",
	},
	[CUSTOM_TYPE.MENU] = {
		szTitle = "地图菜单模块",
		szType = "nMap"
	},
	[CUSTOM_TYPE.CUSTOMBTN] = {
		szTitle = "快捷指令模块",
		szType = "nLeftBottom"
	},
	[CUSTOM_TYPE.CHAT] = {
		szTitle = "聊天模块",
		szType = "nChat",
	},
	[CUSTOM_TYPE.QUICKUSE] = {
		szTitle = "快捷使用模块",
		szType = "nQuickuse"
	},
	[CUSTOM_TYPE.BUFF] = {
		szTitle = "BUFF模块",
		szType = "nBuff"
	},
	[CUSTOM_TYPE.PLAYER] = {
		szTitle = "头像模块",
		szType = "nPlayer"
	},
	[CUSTOM_TYPE.TARGET] = {
		szTitle = "目标模块",
		szType = "nTarget"
	},
	[CUSTOM_TYPE.TASK] = {
		[1] = {
			szTitle = "任务模块",
			szType = "nTask"
		},
		[2] = {
			szTitle = "队伍模块",
			szType = "nTeam"
		},
	},
	[CUSTOM_TYPE.ENERGYBAR] = {
		szTitle = "能量条模块",
		szType = "nEnergyBar"
	},
	[CUSTOM_TYPE.SPECIALSKILLBUFF] = {
		szTitle = "技能监控模块",
		szType = "nSpecialSkillBuff"
	},
	[CUSTOM_TYPE.KILL_FEED] = {
		szTitle = "击伤播报模块",
		szType = "nKillFeed"
	},
}
local tbOffsetNode = {
	[MAIN_CITY_CONTROL_MODE.CLASSIC] = {
		[CUSTOM_TYPE.CHAT] = "nChatOffset",
		[CUSTOM_TYPE.BUFF] = "nBuffOffset",
		[CUSTOM_TYPE.TASK] = "nTaskOffset"
	},
	[MAIN_CITY_CONTROL_MODE.SIMPLE] = {
		[CUSTOM_TYPE.PLAYER] = "nPlayerOffset"
	}
}

local tbDragNodeInfo = {
	[DRAGNODE_TYPE.ACTIONBAR] = {
		szTitle = "动态技能",
		szType = "nActionBar"
	},
	[DRAGNODE_TYPE.DBM] = {
		szTitle = "DBM",
		szType = "nDbm"
	},
	[DRAGNODE_TYPE.DPS] = {
		szTitle = "战斗数据",
		szType = "nDps"
	},
	[DRAGNODE_TYPE.TEAMNOTICE] = {
		szTitle = "团队公告",
		szType = "nTeamNotice"
	},
}

local nMinScale = 0.5
local nMaxScale = 1.5

function UIMainCityWidgetFreeSetting:OnEnter(tbSizeInfo, nNodeType, nDevice, tbShowFont, nMode, bDefault)	--tbSizeInfo指当前所有节点的大小信息
	self.nNodeType = nNodeType
	self.tbSizeInfo = tbSizeInfo
	self.nDevice = nDevice
	self.tbShowFont = tbShowFont
	self.nMode = nMode
	self.bDefault = bDefault
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	UIHelper.SetTouchDownHideTips(self.BtnNon, false)
	self:GetNodeScaleInfo()	--获取当前节点大小信息
	self:UpdateInfo()
end

function UIMainCityWidgetFreeSetting:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIMainCityWidgetFreeSetting:BindUIEvent()
	local tbDefaultSize = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], self.nMode)
	local tCellInfo = {
        [1] = tbDefaultSize.nBigSize,
        [2] = tbDefaultSize.nMediumSize,
        [3] = tbDefaultSize.nSmallSize,
        [4] = tbDefaultSize.nMiniSize,
    }
	local nDefaultIndex = 1
	local bTask = self.nNodeType == CUSTOM_TYPE.TASK
	local szType, szType2, bDragNode = self:GetNodeType()

	for i, tog in ipairs(self.tbFirstTogList) do
		UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
			if bSelected then
				self.nFirstSize = tCellInfo[i]
				self:UpdateSkillSizeSetting()
				if bDragNode then
					self:SetNodeSizeInfoByType(szType, tCellInfo[i])
					MainCityCustomData.tbFontSizeType = self.tbSizeInfo
					Event.Dispatch(EventType.OnSetDragNodeScale, self.tbSizeInfo)
				else
					if bTask then
						Event.Dispatch("ON_SHOW_FAKE_TASKINFO", false)
					end

					self:SetNodeSizeInfoByType(szType, tCellInfo[i])
					Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbSizeInfo)
				end
			end
		end)
	end

	if szType2 then
		for i, tog in ipairs(self.tbSecondTogList) do
			UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
				if bSelected then
					Event.Dispatch("ON_SHOW_FAKE_TEAMINFO", false)
					self:SetNodeSizeInfoByType(szType2, tCellInfo[i])
					Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbSizeInfo)
				end
			end)
		end
	end

	UIHelper.BindUIEvent(self.ToggleHideLabel, EventType.OnSelectChanged, function(_, bSelected)
		self:SetNodeFontVisible(bSelected)
		Event.Dispatch("ON_CHANGE_MAINCITY_FONT_VISLBLE", self.tbShowFont, self.nNodeType)
	end)

	UIHelper.BindUIEvent(self.BtnOK, EventType.OnClick, function()
		Event.Dispatch("ON_EXIT_CURRENT_NODE_CUSTOM")
		MainCityCustomData.EnterSubsidiaryCustom(false)
	end)

	UIHelper.BindUIEvent(self.BtnRestart, EventType.OnClick, function()
		if bDragNode then
			--重置节点位置和大小
			MainCityCustomData.ResetDragNodePosition(self.nNodeType, szType)
			MainCityCustomData.ResetDragNodeBgOpacity(self.nNodeType)
		else
			local tbDefaultSize = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], self.nMode)
			self:SetNodeSizeInfoByType(szType, tbDefaultSize[szType])
			if szType2 then
				self:SetNodeSizeInfoByType(szType2, tbDefaultSize[szType2])
			end
			Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbSizeInfo)	--重置大小

			local tbCanSetFontVisible = {CUSTOM_TYPE.CUSTOMBTN, CUSTOM_TYPE.MENU, CUSTOM_TYPE.SKILL}
			if table.contain_value(tbCanSetFontVisible, self.nNodeType) then
				self:SetNodeFontVisible(true)
				Event.Dispatch("ON_CHANGE_MAINCITY_FONT_VISLBLE", self.tbShowFont, self.nNodeType)
			end

			if self.nNodeType == CUSTOM_TYPE.CHAT then	--重置聊天框背景透明度
				local nDefaultOpacity = Storage.ControlMode.tbChatBgDefaultOpacity[self.nMode] or 75
				Event.Dispatch(EventType.OnSetChatBgOpacity, nDefaultOpacity)
			end
	
			Event.Dispatch("ON_RESET_CURRENT_NODE_POSITION", self.nMode, self.nNodeType)	--重置位置
		end

	end)

	UIHelper.BindUIEvent(self.SliderVolumeAdjustment, EventType.OnChangeSliderPercent, function(_slider, event)
        if  event == ccui.SliderEventType.percentChanged
            or event == ccui.SliderEventType.slideBallDown
            or event == ccui.SliderEventType.slideBallUp then
				local sliderValue = UIHelper.GetProgressBarPercent(self.SliderVolumeAdjustment)
				UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment , sliderValue)
				UIHelper.SetString(self.LabelVolumeNum, sliderValue)
				if event == ccui.SliderEventType.slideBallDown
				or event == ccui.SliderEventType.slideBallUp then
					if self.nNodeType == CUSTOM_TYPE.CHAT then
						MainCityCustomData.SetChatBgOpacityChanged(true)
					else
						MainCityCustomData.SetHurtBgOpacityChanged(true)
					end
				end
				if self.nNodeType == CUSTOM_TYPE.CHAT then
					Event.Dispatch(EventType.OnSetChatBgOpacity, sliderValue / 100 * 255)
				else
					local nOpacity = sliderValue / 100 * 255
					MainCityCustomData.SetHurtBgOpacity(nOpacity)
					Event.Dispatch(EventType.OnSetDragDpsBgOpacity, nOpacity)
				end
        end
	end)

	UIHelper.BindUIEvent(self.SliderSkillVolumeAdjustment, EventType.OnChangeSliderPercent, function(_slider, event)
		if self.nNodeType ~= CUSTOM_TYPE.SKILL then
			return
		end
		local szType, szType2, bDragNode = self:GetNodeType()
        if  event == ccui.SliderEventType.percentChanged
            or event == ccui.SliderEventType.slideBallDown
            or event == ccui.SliderEventType.slideBallUp then
				local sliderValue = UIHelper.GetProgressBarPercent(self.SliderSkillVolumeAdjustment)
				UIHelper.SetProgressBarPercent(self.BarSkillSizeAdjustment , sliderValue)
				local nNewSize = nMinScale + (nMaxScale - nMinScale) * (sliderValue / 100)
				UIHelper.SetString(self.LabelSizeNum, tostring(nNewSize))
				if event == ccui.SliderEventType.slideBallDown
				or event == ccui.SliderEventType.slideBallUp then
					for i, tog in ipairs(self.tbFirstTogList) do
						UIHelper.SetSelected(tog, false, false)
					end
				end
				self:SetNodeSizeInfoByType(szType, nNewSize)
				Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbSizeInfo, nil, self.nNodeType)
        end
	end)
end

function UIMainCityWidgetFreeSetting:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIMainCityWidgetFreeSetting:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMainCityWidgetFreeSetting:UpdateInfo()

	for i, tog in ipairs(self.tbFirstTogList) do
		UIHelper.SetTouchDownHideTips(tog, false)
		UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.MainCityNodeSizeSelect)
	end
	if self.nNodeType == CUSTOM_TYPE.TASK then
		for i, tog in ipairs(self.tbSecondTogList) do
			UIHelper.SetTouchDownHideTips(tog, false)
			UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.TaskTeamSizeSelect)
		end
	end

	UIHelper.SetVisible(self.WidgetContent2, self.nNodeType == CUSTOM_TYPE.TASK)
	UIHelper.SetVisible(self.WidgetAlphaSetting, self.nNodeType == CUSTOM_TYPE.CHAT or self.nNodeType == DRAGNODE_TYPE.DPS)
	UIHelper.LayoutDoLayout(self.LayoutSize)
	UIHelper.LayoutDoLayout(self.LayoutSize2)
	UIHelper.SetTouchDownHideTips(self.ToggleHideLabel, false)
	UIHelper.SetTouchDownHideTips(self.BtnRestart, false)
	UIHelper.SetTouchDownHideTips(self.BtnOK, false)

	local nHeight = UIHelper.GetHeight(self._rootNode)
	UIHelper.SetHeight(self.BtnNon, nHeight)

	local tbDefaultSize = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], self.nMode)
	local tbSize = {
		[1] = tbDefaultSize.nBigSize,
		[2] = tbDefaultSize.nMediumSize,
		[3] = tbDefaultSize.nSmallSize,
		[4] = tbDefaultSize.nMiniSize
	}
	for i, v in ipairs(tbSize) do
		if self.nFirstSize == v then
			UIHelper.SetSelected(self.tbFirstTogList[i], true, false)
		end
	end

	if self.nNodeType == CUSTOM_TYPE.TASK then
		UIHelper.SetString(self.LabelSecondTitle, tbNodeInfo[self.nNodeType].szTitle)
		for i, v in ipairs(tbSize) do
			if self.nSecondSize == v then
				UIHelper.SetSelected(self.tbSecondTogList[i], true, false)
			end
		end
	end

	local bShowFont = self:GetNodeFontVisible()
	if bShowFont ~= nil then
		UIHelper.SetSelected(self.ToggleHideLabel, bShowFont, false)
	end

	self:UpdateSkillSizeSetting()
end

function UIMainCityWidgetFreeSetting:GetNodeScaleInfo()
	local szType, szType2, bDragNode = self:GetNodeType()
	local szTitle1, szTitle2
	if bDragNode then
		self.nFirstSize = self:GetNodeSizeInfoByType(szType)
		self:SetNodeFontVisible(nil)
		szTitle1 = tbDragNodeInfo[self.nNodeType].szTitle
	else
		self.nFirstSize = self:GetNodeSizeInfoByType(szType)
		if szType2 then
			self.nSecondSize = self:GetNodeSizeInfoByType(szType2)
			self:SetNodeFontVisible(nil)
			szTitle1, szTitle2 = tbNodeInfo[self.nNodeType][1].szTitle, tbNodeInfo[self.nNodeType][2].szTitle
			Timer.AddFrame(self, 1, function ()
				UIHelper.SetString(self.LabelSecondTitle, szTitle2)
			end)
		else
			self.nFirstSize = self:GetNodeSizeInfoByType(szType)
			szTitle1 = tbNodeInfo[self.nNodeType].szTitle
		end
	end
	UIHelper.SetString(self.LabelTitle, szTitle1)

	local bShowFont = self:GetNodeFontVisible()
	UIHelper.SetVisible(self.WidgetLabelSetting, bShowFont ~= nil)
	Timer.AddFrame(self, 1, function ()
		UIHelper.LayoutDoLayout(self.LayoutContent)
		UIHelper.LayoutDoLayout(self.ImgTipsBg)
	end)
end

function UIMainCityWidgetFreeSetting:UpdateAlphaSettingInfo(nOpacity)
	if self.nNodeType == CUSTOM_TYPE.CHAT or self.nNodeType == DRAGNODE_TYPE.DPS then
		UIHelper.SetTouchDownHideTips(self.BarVolumeAdjustment, false)
		UIHelper.SetTouchDownHideTips(self.SliderVolumeAdjustment, false)
		local nPercent = math.ceil(nOpacity / 255 * 100)
		UIHelper.SetString(self.LabelVolumeNum, nPercent)
		UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, nPercent)
		UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, nPercent)
	end
end

function UIMainCityWidgetFreeSetting:UpdateSkillSizeSetting()
	UIHelper.SetVisible(self.WidgetSizeSetting, self.nNodeType == CUSTOM_TYPE.SKILL)
	local nSize = self.nFirstSize
	if self.nNodeType ~= CUSTOM_TYPE.SKILL or not nSize then
		return
	end

	UIHelper.SetTouchDownHideTips(self.BarSkillSizeAdjustment, false)
	UIHelper.SetTouchDownHideTips(self.SliderSkillVolumeAdjustment, false)
	local nPercent = math.ceil((nSize - nMinScale) / (nMaxScale - nMinScale) * 100)
	UIHelper.SetString(self.LabelSizeNum, nSize)
	UIHelper.SetProgressBarPercent(self.BarSkillSizeAdjustment, nPercent)
	UIHelper.SetProgressBarPercent(self.SliderSkillVolumeAdjustment, nPercent)
end

function UIMainCityWidgetFreeSetting:GetNodeFontVisible()
	return self.tbShowFont[self.nNodeType]
end

function UIMainCityWidgetFreeSetting:SetNodeFontVisible(bShow)
	self.tbShowFont[self.nNodeType] = bShow
end

function UIMainCityWidgetFreeSetting:SetNodeSizeInfoByType(szType, nSize)
	self.tbSizeInfo[szType] = nSize
end

function UIMainCityWidgetFreeSetting:GetNodeSizeInfoByType(szType)
	return self.tbSizeInfo[szType]
end

function UIMainCityWidgetFreeSetting:GetNodeType()
	local szType, szType2
	local bDragNode = false

	if table.contain_key(tbNodeInfo, self.nNodeType) then
		if self.nNodeType == CUSTOM_TYPE.TASK then
			szType = tbNodeInfo[self.nNodeType][1].szType
			szType2 = tbNodeInfo[self.nNodeType][2].szType
		elseif self.nNodeType == CUSTOM_TYPE.SKILL and SkillData.IsUsingHDKungFu() then
			szType = "nDxSkill"
		else
			szType = tbNodeInfo[self.nNodeType].szType
		end 
	elseif table.contain_key(tbDragNodeInfo, self.nNodeType) then
		szType = tbDragNodeInfo[self.nNodeType].szType
		bDragNode = true
	end

	return szType, szType2, bDragNode
end

return UIMainCityWidgetFreeSetting