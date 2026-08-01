-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelMahjongSettlementPopView
-- Date: 2023-08-08 10:59:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelMahjongSettlementPopView = class("UIPanelMahjongSettlementPopView")

function UIPanelMahjongSettlementPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelMahjongSettlementPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMahjongSettlementPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        MahjongData.ClearReGameData()
        UIMgr.Close(self)
    end)
end

function UIPanelMahjongSettlementPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelMahjongSettlementPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMahjongSettlementPopView:UpdateInfo()
    local tbSettlementDatas = MahjongData.GetCashFlowData()
    local tbMyAvatarData = MahjongData.GetMyAvatarData()
    UIHelper.AddPrefab(PREFAB_ID.WidgetSettlementHead, self.WidgetSettlementHead, tbMyAvatarData, tbSettlementDatas)
    local tbOtherAvatarDatas = MahjongData.GetOtherAvatarDatas()
    for szGlobalID, tbData in pairs(tbOtherAvatarDatas) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetSettlementHead, self.LayoutSettlementHead, tbData, tbSettlementDatas)
    end
    UIHelper.LayoutDoLayout(self.LayoutSettlementHead)

    local nDataDirection = tbMyAvatarData.nDataDirection
    local tbSettlementData = tbSettlementDatas[nDataDirection]
    local nGrade = MahjongData.GetThisGameGrade(tbSettlementData)
    local szGrade = nGrade >= 0 and FormatString("+<D0>", nGrade) or FormatString("<D0>", nGrade)
    UIHelper.SetString(self.LabelMoney, szGrade)

    local szSFXPath = MahjongData.GetSettlementTitleSFXPath(tbSettlementData)
    if not string.is_nil(szSFXPath) then
        UIHelper.SetSFXPath(self.AniMyTitleSFX, szSFXPath, true)
    end
    UIHelper.SetVisible(self.AniMyTitleSFX, not string.is_nil(szSFXPath))

    for nIndex, tbData in pairs(tbSettlementData) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBillTotal, self.ScrollViewBillTotal, tbData)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewBillTotal)
    UIHelper.ScrollToTop(self.ScrollViewBillTotal)

end






return UIPanelMahjongSettlementPopView