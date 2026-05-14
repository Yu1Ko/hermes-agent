-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPRankCell
-- Date: 2023-04-06 17:35:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPRankCell = class("UIHomelandPVPRankCell")

function UIHomelandPVPRankCell:OnEnter(nIndex, tbInfo)
    self.nIndex = nIndex
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPRankCell:OnExit()
    self.bInit = false
end

function UIHomelandPVPRankCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRanking, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRightPopRankingTips, self.TogRanking, TipsLayoutDir.BOTTOM_LEFT, self.tbInfo)
    end)
end

function UIHomelandPVPRankCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandPVPRankCell:UpdateInfo()
    UIHelper.SetVisible(self.ImgTag, self.tbInfo.nCenterID == GetCenterID())
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelRank, string.format("%d", self.nIndex))

    local nScore = 0
	for i = 1, 5 do
		nScore = nScore + (self.tbInfo["dwAttribute" .. i] or 0)
	end
    UIHelper.SetString(self.LabelYiRong, tostring(nScore))

end


return UIHomelandPVPRankCell