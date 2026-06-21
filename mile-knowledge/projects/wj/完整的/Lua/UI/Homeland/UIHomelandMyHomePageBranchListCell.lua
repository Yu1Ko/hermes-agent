-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePageBranchListCell
-- Date: 2023-04-12 21:02:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePageBranchListCell = class("UIHomelandMyHomePageBranchListCell")

function UIHomelandMyHomePageBranchListCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomePageBranchListCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomePageBranchListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTipsInfo, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnClickHomelandMyHomeRankListIndex, self.tbInfo.nIndex)
    end)

    UIHelper.SetSwallowTouches(self.BtnTipsInfo, false)
end

function UIHomelandMyHomePageBranchListCell:RegEvent()
    Event.Reg(self, EventType.OnClickHomelandMyHomeRankListIndex, function (nIndex)
        self:SetSelected(nIndex)
    end)
end

function UIHomelandMyHomePageBranchListCell:UpdateInfo()
    UIHelper.SetVisible(self.ImgRecommend, self.tbInfo.bRecommend)
    UIHelper.SetVisible(self.LabelLiveness, self.tbInfo.nCurrentRankType ~= COMMUNITY_RANK_TYPE.NORMAL)
    UIHelper.SetString(self.LabelBranching, self.tbInfo.szMapName .. tostring(self.tbInfo.nIndex))
    UIHelper.SetString(self.LabelLiveness, tostring(self.tbInfo.nRankValue))

end

function UIHomelandMyHomePageBranchListCell:SetSelected(nCurSelectIndex)
    if self.tbInfo and self.tbInfo.nIndex then
        UIHelper.SetSelected(self.ToggleTipsInfo, self.tbInfo.nIndex == nCurSelectIndex)
    end
end


return UIHomelandMyHomePageBranchListCell