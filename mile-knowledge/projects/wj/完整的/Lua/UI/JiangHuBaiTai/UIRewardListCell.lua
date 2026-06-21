-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIRewardListCell
-- Date: 2023-08-25 14:45:11
-- Desc: WidgetRewardListCell
-- ---------------------------------------------------------------------------------

local UIRewardListCell = class("UIRewardListCell")

function UIRewardListCell:OnEnter(szName, nNum)
	self.szName = UIHelper.GBKToUTF8(szName)
	self.nNum = nNum
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIRewardListCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIRewardListCell:BindUIEvent()
	
end

function UIRewardListCell:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIRewardListCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRewardListCell:UpdateInfo()
	UIHelper.SetString(self.LabelRankingName, self.szName, 7)
	UIHelper.SetString(self.LabelRankingNum, self.nNum)
end

function UIRewardListCell:UpdateRankIcon(szIcon)
	if szIcon then
		UIHelper.SetVisible(self.ImgRankingListIcon, true)
		UIHelper.SetSpriteFrame(self.ImgRankingListIcon, szIcon)
	else
		UIHelper.SetVisible(self.ImgRankingListIcon, false)
	end

end

return UIRewardListCell