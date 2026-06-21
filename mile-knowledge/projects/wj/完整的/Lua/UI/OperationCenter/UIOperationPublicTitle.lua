-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationPublicTitle
-- Date: 2026-03-19 16:16:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationPublicTitle = class("UIOperationPublicTitle")

local tOperationID2BuffID = {
    [132] = 3219,
}

function UIOperationPublicTitle:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tInfo = OperationCenterData.GetOperationInfo(self.nOperationID)
    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateTime()
    end)
end

function UIOperationPublicTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationPublicTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationPublicTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationPublicTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        self:OnClickHelp()
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function()
        self:OnClickShare()
    end)
end

function UIOperationPublicTitle:UpdateInfo()
    local tInfo = self.tInfo
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetVisible(self.BtnHelp, tInfo.szActivityExplain ~= "")
    UIHelper.SetVisible(self.BtnShare, true)

    self:UpdateTime()

    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIOperationPublicTitle:OnClickHelp()
    local tInfo = self.tInfo
    local szTitle = tInfo.szName and UIHelper.GBKToUTF8(tInfo.szName) or ""
    UIMgr.Open(VIEW_ID.PanelHuaELouHelpPop, self.nOperationID, szTitle, tInfo.szActivityExplain)
end

function UIOperationPublicTitle:OnClickShare()
    local tInfo = self.tInfo
    local szName = tInfo.szName and UIHelper.GBKToUTF8(tInfo.szName) or ""
    local szLinkInfo = string.format("OperationCenter/%d", self.nOperationID)
    ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
end

function UIOperationPublicTitle:UpdateTime()
    local tInfo = self.tInfo
    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        self:UpdateWelcomeSignInLeftTime()
    elseif OperationShopData.CheckID(self.nOperationID) then
        self:UpdateShopLeftTime()
    elseif OperationMonthlyPurchaseData.CheckID(self.nOperationID) then
        self:UpdateMonthlyPurchaseTime()
    elseif self:CheckIsBuffTime() then
        self:UpdateBuffLeftTime()
    elseif OperationGuideRecallData.CheckID(self.nOperationID) then
        self:UpdateGuideRecallLeftTime()
    elseif OperationGuideNewData.CheckID(self.nOperationID) then
        UIHelper.SetVisible(self.LabelTimeHint, false)
    elseif self.nOperationID == OPERACT_ID.LEYOUJI then
        self:UpdateLeYouJiTime()
    elseif self.tInfo.nOperatMode == OPERACT_MODE.ACTIVITY_SIGN_IN then
        self:UpdateActivityTime(tInfo)
    else
        local szTimeText = ""
        if tInfo.szCustomTime and tInfo.szCustomTime ~= "" then
            szTimeText = UIHelper.GBKToUTF8(tInfo.szCustomTime)
        end
        UIHelper.SetString(self.LabelTimeHint, szTimeText or "")
        UIHelper.SetVisible(self.LabelTimeHint, szTimeText ~= "")
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIOperationPublicTitle:UpdateWelcomeSignInLeftTime()
    local tData = OperationWelcomeSignInData.GetCurrentData()
    if not tData then
        return
    end
    local nEndTime = tData.nEndTime or 0
    local nCurrentTime = GetCurrentTime()
    local nLeftTime    = nEndTime - nCurrentTime
    if nLeftTime <= 0 then
        nLeftTime = 0
    end
    local szLeftTime = UIHelper.GetHeightestTwoTimeText(nLeftTime)
    UIHelper.SetString(self.LabelTimeHint, "剩余" .. szLeftTime)
    UIHelper.SetVisible(self.LabelTimeHint, tData.bShowTime)
end

function UIOperationPublicTitle:UpdateMonthlyPurchaseTime()
    local szTimeText = OperationMonthlyPurchaseData.GetTimeText()
    UIHelper.SetString(self.LabelTimeHint, szTimeText)
    UIHelper.SetVisible(self.LabelTimeHint, szTimeText ~= "")
end

function UIOperationPublicTitle:UpdateShopLeftTime()
    local tData = GDAPI_CanOperationShopShow(self.nOperationID)
     local nEndTime = tData.nEndTime or 0
    local nCurrentTime = GetCurrentTime()
    local nLeftTime    = nEndTime - nCurrentTime
    if nLeftTime <= 0 then
        nLeftTime = 0
    end
    local szLeftTime = UIHelper.GetHeightestTwoTimeText(nLeftTime)
    UIHelper.SetString(self.LabelTimeHint, "剩余" .. szLeftTime)
    UIHelper.SetVisible(self.LabelTimeHint, tData.bShowTime)
end

function UIOperationPublicTitle:CheckIsBuffTime()
    local nBuffID = tOperationID2BuffID[self.nOperationID]
    return not not nBuffID
end

function UIOperationPublicTitle:UpdateGuideRecallLeftTime()
    local tData = GDAPI_NewSignInGetInfo(self.nOperationID)
    local nEndTime = tData.nEndTime or 0
    local nCurrentTime = GetCurrentTime()
    local nLeftTime    = nEndTime - nCurrentTime
    if nLeftTime <= 0 then
        nLeftTime = 0
    end
    local szLeftTime = UIHelper.GetHeightestTwoTimeText(nLeftTime)
    UIHelper.SetString(self.LabelTimeHint, "剩余" .. szLeftTime)
    UIHelper.SetVisible(self.LabelTimeHint, tData.bShowTime)
end

function UIOperationPublicTitle:UpdateBuffLeftTime()
    local nBuffID = tOperationID2BuffID[self.nOperationID]
    local tBuffTimeData = Buffer_GetTimeData(nBuffID)

    local nTime = tBuffTimeData.nEndFrame and BuffMgr.GetLeftFrame(tBuffTimeData) or tBuffTimeData.nLeftTime
    if tBuffTimeData.nEndFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local szTime
    if nTime >= 3600 then
        local nHour = math.floor(nTime / 3600)
        local nMin = math.floor(nTime % 3600 / 60)
        local nSec = math.floor(nTime % 60)
        szTime = string.format("%d小时%d分钟%d秒", nHour, nMin, nSec)
    elseif nTime >= 60 then
        local nMin = math.floor(nTime / 60)
        local nSec = math.floor(nTime % 60)
        szTime = string.format("%d分钟%d秒", nMin, nSec)
    else
        szTime = string.format("%d秒", math.floor(nTime))
    end
    UIHelper.SetString(self.LabelTimeHint, "剩余时间：" .. szTime)
    UIHelper.SetVisible(self.LabelTimeHint, true)
end

function UIOperationPublicTitle:UpdateLeYouJiTime()
    local tInfo    = OperationCenterData.GetOperationInfo(OPERACT_ID.LEYOUJI)
    local nEndTime = tInfo and tInfo.nEndTime or 0
    local nLeftSec = nEndTime - GetCurrentTime()
    if nLeftSec <= 0 then
        UIHelper.SetString(self.LabelTimeHint, "活动已结束")
    else
        UIHelper.SetString(self.LabelTimeHint, "剩余时间：" .. UIHelper.GetHeightestTwoTimeText(nLeftSec, nil, 3))
    end
     UIHelper.SetVisible(self.LabelTimeHint, true)
end

function UIOperationPublicTitle:UpdateActivityTime(tInfo)
    local nEndTime = tInfo.nEndTime or 0
    local nCurrentTime = GetCurrentTime()
    local nLeftTime    = nEndTime - nCurrentTime
    if nLeftTime <= 0 then
        nLeftTime = 0
    end
    local szLeftTime = UIHelper.GetHeightestTwoTimeText(nLeftTime)
    UIHelper.SetString(self.LabelTimeHint, "剩余时间：" .. szLeftTime)
    UIHelper.SetVisible(self.LabelTimeHint, true)
end

return UIOperationPublicTitle