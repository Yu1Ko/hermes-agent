
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetGetItemHint
-- Date: 2022-11-08
-- Desc: 获取物品提示cell
-- ---------------------------------------------------------------------------------
local UIWidgetGetItemHint = class("UIWidgetGetItemHint")

function UIWidgetGetItemHint:OnEnter()
	self.m = {}
	
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

end

function UIWidgetGetItemHint:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self.m = nil
end

function UIWidgetGetItemHint:BindUIEvent()
	
end

function UIWidgetGetItemHint:RegEvent()
	--Event.Reg(self, EventType.XXX, func)	
end

function UIWidgetGetItemHint:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetGetItemHint:UpdateInfo()
end

function UIWidgetGetItemHint:UpdateList()
end

function UIWidgetGetItemHint:InitData()
end


return UIWidgetGetItemHint