-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIRankListCell
-- Date: 2023-08-28 09:53:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRankListCell = class("UIRankListCell")

function UIRankListCell:OnEnter(szName, nNum, nIndex)
	self.szName = UIHelper.GBKToUTF8(szName)
	self.nNum = nNum
	self.nIndex = nIndex
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIRankListCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIRankListCell:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnRanking, EventType.OnClick, function()
		Event.Dispatch("SHOW_CONFIGSKILL_TIPS", self.nIndex, self.nNum)
	end)
end

function UIRankListCell:RegEvent()
	Event.Reg(self, "UPDATE_RANKCELL_SELECTED", function(nCurID)
		UIHelper.SetVisible(self.ImgRankingSelect, nCurID == self.nIndex)
		UIHelper.SetVisible(self.ImgRankingNormal, nCurID ~= self.nIndex)
    end)
end

function UIRankListCell:UnRegEvent()
	Event.UnReg(self, "UPDATE_RANKCELL_SELECTED")
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRankListCell:UpdateInfo()
	UIHelper.SetString(self.LabelRankingName, self.szName)
	UIHelper.SetString(self.LabelRankingNum, self.nNum)
end

function UIRankListCell:UpdateRankIcon(szIcon)
	if szIcon then
		UIHelper.SetVisible(self.ImgRankingListIcon, true)
		UIHelper.SetSpriteFrame(self.ImgRankingListIcon, szIcon)
	else
		UIHelper.SetVisible(self.ImgRankingListIcon, false)
	end

end

return UIRankListCell