-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UITeachCell
-- Date: 2023-11-23 17:35:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeachCell = class("UITeachCell")

function UITeachCell:OnEnter(szName, nIndex)
	self.szName = szName
	self.nIndex = nIndex
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UITeachCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UITeachCell:BindUIEvent()
	UIHelper.BindUIEvent(self.ToggleTutorial,EventType.OnSelectChanged,function (_, bSelected)
		if bSelected then
			Event.Dispatch("ON_CHANGETEACHTITLE", self.szName, self.nIndex)
			Event.Dispatch("ON_SHOWFIRSTTEACHINFO")
		end
	end)
end

function UITeachCell:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UITeachCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeachCell:UpdateInfo()
	UIHelper.SetString(self.Label01 ,self.szName)
	UIHelper.SetString(self.Label02 ,self.szName)
	UIHelper.SetSwallowTouches(self.ToggleTutorial , false)
end


return UITeachCell