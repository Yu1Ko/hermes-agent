-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetArtistSkillCell
-- Date: 2024-09-04 16:18:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetArtistSkillCell = class("UIWidgetArtistSkillCell")

function UIWidgetArtistSkillCell:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIWidgetArtistSkillCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetArtistSkillCell:BindUIEvent()
	
end

function UIWidgetArtistSkillCell:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIWidgetArtistSkillCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetArtistSkillCell:UpdateInfo()
	
end


return UIWidgetArtistSkillCell