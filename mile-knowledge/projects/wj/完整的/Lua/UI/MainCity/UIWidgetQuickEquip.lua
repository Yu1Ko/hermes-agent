-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetQuickEquip
-- Date: 2022-11-24 15:38:00
-- Desc: 快速穿新装备
-- ---------------------------------------------------------------------------------

local UIWidgetQuickEquip = class("UIWidgetQuickEquip")

function UIWidgetQuickEquip:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIWidgetQuickEquip:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetQuickEquip:BindUIEvent()
	
end

function UIWidgetQuickEquip:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIWidgetQuickEquip:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQuickEquip:UpdateInfo()
	
end


return UIWidgetQuickEquip