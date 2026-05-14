-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetIndentityContainer
-- Date: 2024-09-04 15:51:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetIndentityContainer = class("UIWidgetIndentityContainer")

function UIWidgetIndentityContainer:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIWidgetIndentityContainer:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetIndentityContainer:BindUIEvent()
	
end

function UIWidgetIndentityContainer:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIWidgetIndentityContainer:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetIndentityContainer:UpdateInfo()
	
end


return UIWidgetIndentityContainer