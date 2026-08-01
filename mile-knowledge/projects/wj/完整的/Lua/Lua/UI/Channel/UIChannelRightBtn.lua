-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChannelRightBtn
-- Date: 2024-07-08 16:54:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChannelRightBtn = class("UIChannelRightBtn")

function UIChannelRightBtn:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIChannelRightBtn:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChannelRightBtn:BindUIEvent()
	
end

function UIChannelRightBtn:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIChannelRightBtn:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChannelRightBtn:UpdateInfo()
	
end


return UIChannelRightBtn