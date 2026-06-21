-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatMonitorWordCell
-- Date: 2024-11-22 15:08:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatMonitorWordCell = class("UIChatMonitorWordCell")

function UIChatMonitorWordCell:OnEnter(tbData)
	self.tbData = tbData or {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UIChatMonitorWordCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChatMonitorWordCell:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnMonitorKeyWord, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelChatMonitorWordPop, self.tbData)
    end)
end

function UIChatMonitorWordCell:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIChatMonitorWordCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatMonitorWordCell:UpdateInfo()
	UIHelper.SetString(self.LabelMonitorKeyWord, self.tbData.szWord)
	UIHelper.SetString(self.LabelMonitorKeyWordOff, self.tbData.szWord)

	UIHelper.SetVisible(self.ImgMonitorKeyWordOff, not self.tbData.bMonitor)
	UIHelper.SetVisible(self.LabelMonitorKeyWordOff, not self.tbData.bMonitor)
	UIHelper.SetVisible(self.LabelMonitorKeyWord, self.tbData.bMonitor)
end


return UIChatMonitorWordCell