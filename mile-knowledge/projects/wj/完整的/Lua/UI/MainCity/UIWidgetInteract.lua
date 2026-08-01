
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetInteractItem
-- Date: 2022-11-02 16:40:08
-- Desc: 场景可交互列表item
-- ---------------------------------------------------------------------------------
local UIWidgetInteractItem = class("UIWidgetInteractItem")

function UIWidgetInteractItem:OnEnter()
	self.m = {}
	
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

end

function UIWidgetInteractItem:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self.m = nil
end

function UIWidgetInteractItem:BindUIEvent()
	
end

function UIWidgetInteractItem:RegEvent()
	--Event.Reg(self, EventType.XXX, func)	
end

function UIWidgetInteractItem:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetInteractItem:UpdateInfo()
end

function UIWidgetInteractItem:UpdateList()
end

function UIWidgetInteractItem:InitData()
end


return UIWidgetInteractItem