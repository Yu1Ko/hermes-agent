-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGiftWithdrawView
-- Date: 2025-09-22 14:59:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGiftWithdrawView = class("UIGiftWithdrawView")

function UIGiftWithdrawView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()
end

function UIGiftWithdrawView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGiftWithdrawView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnWelfare, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSingleTextTips, self.BtnWelfare, g_tStrings.STR_WITHDRAW_WELFARE_TIPS)
    end)

    UIHelper.BindUIEvent(self.BtnLink, EventType.OnClick, function(btn)
        GiftHelper.Link2Certif()
    end)

    UIHelper.BindUIEvent(self.BtnLinkNew, EventType.OnClick, function(btn)
        GiftHelper.Link2Certif()
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
            return
        end
        if self.bBindPhone then
            -- SMS_CODE_STATUS.TOTAL
            UIMgr.Open(VIEW_ID.PanelVerifyCodePop, 1, function (nType, szSMSCode)
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
                    return
                end
                local szZhuan = UIHelper.GetText(self.EditBox_Zhuan)
                local szJin = UIHelper.GetText(self.EditBox_Jin)
                local nZhuan = tonumber(szZhuan) or 0
                local nJin = tonumber(szJin) or 0
                local nGold = nZhuan * 10000 + nJin

                local nRetCode = GiftHelper.WithdrawDeposit(szSMSCode, nGold)
                if nRetCode then
                    UIMgr.Close(VIEW_ID.PanelVerifyCodePop)
                    UIMgr.Close(self)
                end
            end)
        else
            TipsHelper.ShowNormalTip(g_tStrings.WITHDRAW_NOT_PHONE_BIND)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function(btn)
        self:OnClickBtnMax()
        self:UpdateBtnState()
    end)

    UIHelper.BindUIEvent(self.BtnMin, EventType.OnClick, function(btn)
        self:OnClickBtnMin()
        self:UpdateBtnState()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBox_Zhuan, function()
            self:UpdateEditBoxInfo()
            self:UpdateBtnState()
        end)
        UIHelper.RegisterEditBoxEnded(self.EditBox_Jin, function()
            self:UpdateEditBoxInfo()
            self:UpdateBtnState()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBox_Zhuan, function()
            self:UpdateEditBoxInfo()
            self:UpdateBtnState()
        end)
        UIHelper.RegisterEditBoxReturn(self.EditBox_Jin, function()
            self:UpdateEditBoxInfo()
            self:UpdateBtnState()
        end)
    end
end

function UIGiftWithdrawView:RegEvent()
    Event.Reg(self, "SYNC_NEW_EXT_POINT_END", function ()
        self:InitData()
        self:UpdateInfo()
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        if arg0 == EXT_POINT.CERTIFICATION or arg0 == EXT_POINT.REMIAN_QUOTA or arg0 == EXT_POINT.WITHDRAW_TIMES or arg0 == EXT_POINT.DAILY_QUOTA then
            self:InitData()
            self:UpdateInfo()
        end
    end)
end

function UIGiftWithdrawView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIGiftWithdrawView:InitData()
    self.bBindPhone = ServiceCenterData:IsPhoneBind()
    self.bCertified = GiftHelper.IsCertifiedCreator()
    self.tQuotaInfo = GiftHelper.GetDailyQuotaInfo(self.bCertified)
    self.nHaveQuota = GiftHelper.GetDailyHaveQuota()
    self.nRemainQuota = GiftHelper.GetRemainQuota()
end

function UIGiftWithdrawView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetVip, self.bCertified)
    UIHelper.SetVisible(self.WidgetHaveNoVIp, not self.bCertified)
    UIHelper.SetButtonState(self.BtnConfirm, self.bBindPhone and BTN_STATE.Normal or BTN_STATE.Disable, g_tStrings.WITHDRAW_NOT_PHONE_BIND)

    local szName = PlayerData.GetPlayerName()
    UIHelper.SetString(self.LabelBalanceTitle, UIHelper.GBKToUTF8(szName))
    self:UpdateQuotaInfo()
    self:UpdateWithdrawInfo()
    self:UpdateBtnState()
end

function UIGiftWithdrawView:UpdateQuotaInfo()
    if not self.tQuotaInfo then
        return
    end

    local nSingleMin = self.tQuotaInfo.nSingleMin
    local nSingleMax = self.tQuotaInfo.nSingleMax
    local nDailyMax = self.tQuotaInfo.nDailyMax
    local nHaveQuota = self.nHaveQuota

    UIHelper.SetString(self.LabelMoney_Jin, string.format("%d", nSingleMin))
    UIHelper.SetString(self.LabelMoney_Zhuan, string.format("≤单次提现金额≤%d", math.floor(nSingleMax / 10000)))
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetSingleLimitTotal, true, true)

    UIHelper.SetString(self.LabelMoney_Jin_Today, string.format("%d", nHaveQuota % 10000))
    UIHelper.SetString(self.LabelMoney_Zhuan_Today, string.format("%d", math.floor(nHaveQuota / 10000)))
    UIHelper.SetString(self.LabelMoney_Zhuan_TodayLimit, string.format("/%d", math.floor(nDailyMax / 10000)))
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetTodayTotal, true, true)
end

function UIGiftWithdrawView:UpdateWithdrawInfo()
    local nRemainQuota = self.nRemainQuota
    local nSingleMin = self.tQuotaInfo.nSingleMin

    UIHelper.SetString(self.LabelMoney_Jin_Balance, string.format("%d", nRemainQuota % 10000))
    UIHelper.SetString(self.LabelMoney_Zhuan_Balance, string.format("%d", math.floor(nRemainQuota / 10000)))

    UIHelper.SetText(self.EditBox_Jin, nRemainQuota >= nSingleMin and nSingleMin or 0)
    UIHelper.SetText(self.EditBox_Zhuan, "")
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCost, true, true)
end

function UIGiftWithdrawView:UpdateBtnState()
    if not self.tQuotaInfo then
        return
    end

    local nSingleMin = self.tQuotaInfo.nSingleMin
    local nSingleMax = self.tQuotaInfo.nSingleMax
    local nDailyMax = self.tQuotaInfo.nDailyMax
    local nHaveQuota = self.nHaveQuota
    local nRemainQuota = self.nRemainQuota

    local szTip = ""
    local nCurJin = tonumber(UIHelper.GetText(self.EditBox_Jin)) or 0
    local nCurZhuan = tonumber(UIHelper.GetText(self.EditBox_Zhuan)) or 0
    local nTotalInput = nCurJin + nCurZhuan * 10000
    local bCanConfirm = nTotalInput >= nSingleMin and nTotalInput <= nSingleMax
    szTip = "未满足单次提现要求。"

    if bCanConfirm then
        bCanConfirm = nTotalInput <= nRemainQuota
        szTip = "通行证余额不足"
    end

    if bCanConfirm then
        bCanConfirm = (nTotalInput + nHaveQuota) <= nDailyMax
        szTip = "超过今日提现额度"
    end

    local nMaxWithdraw = math.min(nRemainQuota, nDailyMax - nHaveQuota)
    if nMaxWithdraw < nSingleMin then
        UIHelper.SetVisible(self.WidgetErrorMessage, true)
        UIHelper.SetString(self.LabelErrorMessage, g_tStrings.WITHDRAW_MAX_NUM_NOT_ENOUGH .. nMaxWithdraw)
        szTip = "可提现余额不足"
    end

    UIHelper.SetButtonState(self.BtnConfirm, bCanConfirm and BTN_STATE.Normal or BTN_STATE.Disable, szTip)
end

function UIGiftWithdrawView:UpdateEditBoxInfo()
    if not self.tQuotaInfo then
        return
    end

    local nSingleMin = self.tQuotaInfo.nSingleMin
    local nSingleMax = self.tQuotaInfo.nSingleMax
    local nDailyMax = self.tQuotaInfo.nDailyMax
    local nHaveQuota = self.nHaveQuota
    local nRemainQuota = self.nRemainQuota

    local nMaxGold = math.min(nRemainQuota, nSingleMax, nDailyMax - nHaveQuota)
    local nCurJin = tonumber(UIHelper.GetText(self.EditBox_Jin)) or 0
    local nCurZhuan = tonumber(UIHelper.GetText(self.EditBox_Zhuan)) or 0
    if nCurJin >= 10000 then
        nCurZhuan = nCurZhuan + math.floor(nCurJin / 10000)
        nCurJin = nCurJin % 10000
    end

    if nCurJin + nCurZhuan * 10000 > nMaxGold then
        self:OnClickBtnMax()
        return
    elseif nCurJin + nCurZhuan * 10000 < nSingleMin then
        self:OnClickBtnMin()
        return
    end

    UIHelper.SetText(self.EditBox_Zhuan, string.format("%d", nCurZhuan))
    UIHelper.SetText(self.EditBox_Jin, string.format("%d", nCurJin))
end

function UIGiftWithdrawView:OnClickBtnMax()
    if not self.tQuotaInfo then
        return
    end

    local nSingleMin = self.tQuotaInfo.nSingleMin
    local nSingleMax = self.tQuotaInfo.nSingleMax
    local nDailyMax = self.tQuotaInfo.nDailyMax
    local nHaveQuota = self.nHaveQuota
    local nRemainQuota = self.nRemainQuota

    local nMaxGold = math.min(nRemainQuota, nSingleMax, nDailyMax - nHaveQuota)
    local nJin = nMaxGold % 10000
    local nZhuan = math.floor(nMaxGold / 10000)
    if nJin + nZhuan * 10000 < nSingleMin then
        self:OnClickBtnMin()
        return
    end

    UIHelper.SetText(self.EditBox_Jin, string.format("%d", nJin))
    UIHelper.SetText(self.EditBox_Zhuan, string.format("%d", nZhuan))
end

function UIGiftWithdrawView:OnClickBtnMin()
    local nSingleMin = self.tQuotaInfo.nSingleMin
    local nJin = nSingleMin
    local nZhuan = 0

    UIHelper.SetText(self.EditBox_Jin, string.format("%d", nJin))
    UIHelper.SetText(self.EditBox_Zhuan, string.format("%d", nZhuan))
end

return UIGiftWithdrawView