-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMainCityDataCell
-- Date: 2022-12-30 15:01:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMainCityDataCell = class("UIArenaMainCityDataCell")

function UIArenaMainCityDataCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo or {}

    self.tbInfo.nTotalCount = self.tbInfo.nTotalCount or 0
    self.tbInfo.nWinCount = self.tbInfo.nWinCount or 0

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaMainCityDataCell:OnExit()
    self.bInit = false
end

function UIArenaMainCityDataCell:BindUIEvent()

end

function UIArenaMainCityDataCell:RegEvent()

end

function UIArenaMainCityDataCell:UpdateInfo()
    UIHelper.SetString(self.LabelSession, self.tbInfo.nTotalCount)
    UIHelper.SetString(self.LabelWinNum, self.tbInfo.nWinCount)
    UIHelper.SetString(self.LabelDefeatsNum, self.tbInfo.nTotalCount - self.tbInfo.nWinCount)
    if self.tbInfo.nTotalCount > 0 then
        UIHelper.SetString(self.LabelWinRateNum, string.format("%d%%", math.floor(self.tbInfo.nWinCount / self.tbInfo.nTotalCount * 100 + 0.5)))
    else
        UIHelper.SetString(self.LabelWinRateNum, "0%")
    end

    UIHelper.SetString(self.LabelTitle, self.tbInfo.szTitle)
    UIHelper.SetVisible(self.WidgetPersonageTip, self.tbInfo.bVK)
end


return UIArenaMainCityDataCell