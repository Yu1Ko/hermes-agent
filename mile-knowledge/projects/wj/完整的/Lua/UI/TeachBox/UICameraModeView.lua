-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UICameraModeView
-- Date: 2024-02-29 14:53:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICameraModeView = class("UICameraModeView")
local tbSetting = {
	[1] = {
		[1] = {UISettingKey.CameraMode, GameSettingType.OperationMode.Traditional}
	},
	[2] = {
		[1] = {UISettingKey.CameraMode, GameSettingType.OperationMode.Joystick}
	},
	[3] = {
		[1] = {UISettingKey.CameraMode, GameSettingType.OperationMode.Locked}
	}
}

function UICameraModeView:OnEnter()
	self.nIndex = 2
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateSelectedTog()
end

function UICameraModeView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UICameraModeView:BindUIEvent()
	
	UIHelper.BindUIEvent(self.tbTogList[1], EventType.OnClick, function ()
		self.nIndex = 1
		self:UpdateSelectedTog()
	end)

	UIHelper.BindUIEvent(self.tbTogList[2], EventType.OnClick, function ()
		self.nIndex = 2
		self:UpdateSelectedTog()
	end)

	UIHelper.BindUIEvent(self.tbTogList[3], EventType.OnClick, function ()
		self.nIndex = 3
		self:UpdateSelectedTog()
	end)

	UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
		local tSetting = tbSetting[self.nIndex]
		for i, v in ipairs(tSetting) do
			GameSettingData.ApplyNewValue(v[1], v[2])
		end
		
		UIMgr.Close(self)
		TipsHelper.ShowNormalTip(string.format("已选择了%s，后续可在设置里进行更换", tSetting[1][4].szDec))
		if UIMgr.IsViewOpened(VIEW_ID.PanelGameSettings) then
			local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelGameSettings)
			tbScript:UpdateInfo()
		end
	end)
end

function UICameraModeView:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UICameraModeView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICameraModeView:UpdateInfo()

end

function UICameraModeView:UpdateSelectedTog()
	for i, tog in ipairs(self.tbTogList) do
		UIHelper.SetSelected(self.tbTogList[i], i == self.nIndex)
	end
end


return UICameraModeView