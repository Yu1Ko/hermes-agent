-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelCreateTong
-- Date: 2022-12-19 16:33:37
-- Desc: 创建帮会面板
-- ---------------------------------------------------------------------------------

local UIPanelCreateTong = class("UIPanelCreateTong")

function UIPanelCreateTong:OnEnter(fnCallback)
	self.m = {}
	self.m.fnCallback = fnCallback

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIPanelCreateTong:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self.m = nil
end

function UIPanelCreateTong:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		self.m.bCancel = true
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
		self.m.bCancel = true
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
		self.m.szName = UIHelper.GetString(self.EditBoxFactionSearch)
		self:Close()		
	end)		
end

function UIPanelCreateTong:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIPanelCreateTong:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCreateTong:UpdateInfo()
	
end


function UIPanelCreateTong:Close()
	local fnCallback = self.m.fnCallback
	if fnCallback then
		fnCallback(self.m.szName, self.m.bCancel)
	end
	UIMgr.Close(self)
end

return UIPanelCreateTong