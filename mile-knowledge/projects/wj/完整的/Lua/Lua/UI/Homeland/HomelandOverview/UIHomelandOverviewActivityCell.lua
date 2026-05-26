-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverviewActivityCell
-- Date: 2024-01-29 17:37:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOverviewActivityCell = class("UIHomelandOverviewActivityCell")

function UIHomelandOverviewActivityCell:OnEnter(tbInfo, tbData, nCommunityCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.tbData = tbData
    self.nCommunityCount = nCommunityCount
    self.bLock = false
    self:UpdateInfo()
end

function UIHomelandOverviewActivityCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOverviewActivityCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnActivity, EventType.OnClick, function()
        self:OnClick()
    end)
end

function UIHomelandOverviewActivityCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandOverviewActivityCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverviewActivityCell:UpdateInfo()
    local tbInfo            = self.tbInfo
    local tbData            = self.tbData
    local nCommunityCount   = self.nCommunityCount
    local bNowPrivate       = HomelandData.IsNowPrivateHomeMap()
    local szName            = UIHelper.GBKToUTF8(tbInfo.szName)
    local szBgPath          = HomelandOverviewImg[tbInfo.dwID]
    local nMaxComplete      = tbInfo.nMaxComplete
    local nCommunityLimit   = tbInfo.nCommunityLimit
    self.bLock              = tbInfo.bPrivate and bNowPrivate ~= tbInfo.bPrivate

    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetString(self.LabelActiveNum, tbInfo.nWeeklyActivityValue)
    UIHelper.SetSpriteFrame(self.ImgPic, szBgPath)
    UIHelper.SetVisible(self.WidgetDouble, tbInfo.bDouble)
    UIHelper.SetVisible(self.WidgetRec, tbInfo.bRecommend)
    UIHelper.SetVisible(self.WidgetLocked, self.bLock)

    UIHelper.LayoutDoLayout(self.LayoutTag)
    local nMax = nMaxComplete
    if nCommunityCount <= 0 then
        nMax = nCommunityLimit
    end
    if nMax < 0 then
        UIHelper.SetVisible(self.LabelUnlocked, false)
    elseif nMax == 0 then
        UIHelper.SetString(self.LabelUnlocked, g_tStrings.STR_HOMELNAD_OVERVIEW_CAN_REDO)
    else
        local szState = g_tStrings.STR_ACHIEVEMENT_PERCENT..FormatString(g_tStrings.STR_NEW_PQ_TYPE2, tbData.nCompleteNum, nMax)
        UIHelper.SetString(self.LabelUnlocked, szState)
    end
    UIHelper.SetVisible(self.WidgetFinished, nMax > 0 and tbData.nCompleteNum == nMax)
end

function UIHomelandOverviewActivityCell:OnClick()
    if self.bLock then
        TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(self.tbInfo.szLockTips))
        return
    end
    local dwID          = self.tbInfo.dwID
    local tbMenuInfo    = clone(self.tbInfo.tMenuInfo)
    if dwID == 1 then
        UIMgr.Close(VIEW_ID.PanelHomeOverview)
        UIMgr.Open(VIEW_ID.PanelHomeIdentity)
        return
    end
    tbMenuInfo.dwID = dwID
    Event.Dispatch(EventType.OnClickOverviewActivityCell, tbMenuInfo)
end


return UIHomelandOverviewActivityCell