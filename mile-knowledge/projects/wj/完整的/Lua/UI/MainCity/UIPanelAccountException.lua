-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UIPanelAccountException
-- Date: 2025-09-17 19:14:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelAccountException = class("UIPanelAccountException")

function UIPanelAccountException:OnEnter(nLimitType, nValue)
    if not nLimitType or not nValue then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLimitType = nLimitType
    self.nValue     = nValue
    if not self:CheckLimitType(nLimitType) then
        return
    end
    self:UpdateInfo()
end

function UIPanelAccountException:CheckLimitType(nLimitType)
    local tTypeList = LIMIT_TYPE
    for k, nType in pairs(tTypeList) do
        if self.nLimitType == nType then
            return true
        end
    end
    return false
end

function UIPanelAccountException:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelAccountException:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end) 

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end

        local pPlayer = GetClientPlayer()
        if pPlayer then
            RemoteCallToServer("On_Gift_QiangLiJianChan")
        end
    end) 
    
    UIHelper.BindUIEvent(self.BtnKnow, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIPanelAccountException:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.WidgetFoceDoAlign(self.WidgetAniMiddle)
    end)
end

function UIPanelAccountException:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAccountException:UpdateInfo()
    local szTitle = g_tStrings.STR_LIMIT_TIME_TITLE[self.nLimitType]
    UIHelper.SetLabel(self.LabelTitle, szTitle)

    if self.nLimitType == LIMIT_TYPE.MONEY_PRODUCTION then
        UIHelper.SetVisible(self.BtnKnow, false)
        UIHelper.SetVisible(self.BtnCancel, true)
        UIHelper.SetVisible(self.BtnAccept, true)
        UIHelper.SetVisible(self.hTextMoney, true)
        UIHelper.SetVisible(self.hTextTime, false)
        self:UpdateMoneyLimit()
    else
        UIHelper.SetVisible(self.BtnKnow, true)
        UIHelper.SetVisible(self.BtnCancel, false)
        UIHelper.SetVisible(self.BtnAccept, false)
        UIHelper.SetVisible(self.hTextMoney, false)
        UIHelper.SetVisible(self.hTextTime, true)
        self:UpdateTimeLimit()
    end
end

function UIPanelAccountException:UpdateMoneyLimit()
    local nDCGoldLimitLevel = self.nValue
    if nDCGoldLimitLevel > 0 then
        local nCost = 1000 * math.pow(2, nDCGoldLimitLevel - 1)
        UIHelper.SetLabel(self.LabelAchievementNum, nCost)
    end
end

function UIPanelAccountException:UpdateTimeLimit()
    local szDscText
    if self.nLimitType == LIMIT_TYPE.TIME_ACCOUNT then
        szDscText = g_tStrings.STR_LIMIT_TIME_ACCOUNT
    elseif self.nLimitType == LIMIT_TYPE.TIME_CHARACTER then
        szDscText = g_tStrings.STR_LIMIT_TIME_CHARACTER
    end
    UIHelper.SetLabel(self.LabelContent, szDscText)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollMainContentHelp)
    UIHelper.ScrollViewSetupArrow(self.ScrollMainContentHelp, self.WidgetArrow)
    
    local nCurrTime = GetCurrentTime()
    self.nLimitEnd = self.nValue
    self:UpdateTimeText()
    if self.nLimitEnd > nCurrTime then
        self:CycleBreatheSecond()
    end
end

function UIPanelAccountException:CycleBreatheSecond()
    Timer.AddCycle(self, 0.5, function()
        local nCurrTime = GetCurrentTime()
        if self.nLimitEnd and self.nLimitEnd > 0 then
            if self.nLimitEnd >= nCurrTime then
                self:UpdateTimeText()
            end
        end
    end)
end

function UIPanelAccountException:UpdateTimeText()
    if not self.nLimitEnd then
        return 
    end
    local nCurrTime = GetCurrentTime()
    local nSecTime = (self.nLimitEnd - nCurrTime) -- 秒
    local bAlreadyEnd = (nSecTime <= 0)
    local szTimeMsg
    if bAlreadyEnd then
        szTimeMsg = g_tStrings.STR_LIMIT_END_WARNING
    else
        if nSecTime > 60 then
            nSecTime = nSecTime + 60
        else
            nSecTime = 60
        end

        szTimeMsg = FormatString(g_tStrings.STR_LIMIT_TIME_MIN, TimeLib.GetTimeText(nSecTime, nil, nil, nil, nil, "Diable Second"))
    end
    
    UIHelper.SetLabel(self.LabelTimeText, szTimeMsg)
end

return UIPanelAccountException