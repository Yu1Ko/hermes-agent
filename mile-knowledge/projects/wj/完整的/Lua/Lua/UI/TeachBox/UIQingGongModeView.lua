-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIQingGongModeView
-- Date: 2023-12-13 14:30:22
-- Desc: PanelQingGongModePop
-- ---------------------------------------------------------------------------------

local UIQingGongModeView = class("UIQingGongModeView")
local tbSetting = {
	[1] = {
		[1] = {UISettingKey.SprintMode, GameSettingType.SprintMode.Simple}
	},
	[2] = {
		[1] = {UISettingKey.SprintMode, GameSettingType.SprintMode.Classic},
	},
	[3] = {
		[1] = {UISettingKey.SprintMode, GameSettingType.SprintMode.Common}
	}
}

function UIQingGongModeView:OnEnter()
	self.nIndex = 3
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UIQingGongModeView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIQingGongModeView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.TogSimplified, EventType.OnClick, function ()
		self.nIndex = 1
		UIHelper.SetSelected(self.TogClassic, false)
		UIHelper.SetSelected(self.TogSimplified, true)
		UIHelper.SetSelected(self.TogCommon, false)
	end)

	UIHelper.BindUIEvent(self.TogClassic, EventType.OnClick, function ()
		self.nIndex = 2
		UIHelper.SetSelected(self.TogSimplified, false)
		UIHelper.SetSelected(self.TogClassic, true)
		UIHelper.SetSelected(self.TogCommon, false)
	end)

	UIHelper.BindUIEvent(self.TogCommon, EventType.OnClick, function ()	--新增通用轻功
		self.nIndex = 3
		UIHelper.SetSelected(self.TogSimplified, false)
		UIHelper.SetSelected(self.TogClassic, false)
		UIHelper.SetSelected(self.TogCommon, true)
	end)

	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
		if g_pClientPlayer and g_pClientPlayer.bSprintFlag then
			UIMgr.Close(self)
			TipsHelper.ShowNormalTip(g_tStrings.STR_CHANGE_SPRINT_MODE_IN_SPRINT)
			return
		end

		local tSetting = tbSetting[self.nIndex]
		for i, v in ipairs(tSetting) do
			GameSettingData.ApplyNewValue(v[1], v[2])
		end
		
		UIMgr.Close(self)
		TipsHelper.ShowNormalTip(string.format("已选择了%s，后续可在设置里进行更换", tSetting[1][4].szDec))
	end)
end

function UIQingGongModeView:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIQingGongModeView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQingGongModeView:UpdateInfo()
	UIHelper.SetSelected(self.TogSimplified, false)
	UIHelper.SetSelected(self.TogClassic, false)
	UIHelper.SetSelected(self.TogCommon, true)
	UIHelper.SetString(self.LabelModeName02, "可在“菜单-设置-操作设置-轻功模式”中切换模式")
	UIHelper.SetString(self.LabelSimpleModeName02, "操作简单，适合刚接触的新玩家")
	UIHelper.SetString(self.LabelClassicModeName02, "轻功2.0，适合熟悉端游轻功的玩家")
end


return UIQingGongModeView