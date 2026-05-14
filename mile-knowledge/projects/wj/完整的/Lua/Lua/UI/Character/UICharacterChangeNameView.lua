-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterChangeNameView
-- Date: 2023-02-16 16:44:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterChangeNameView = class("UICharacterChangeNameView")

function UICharacterChangeNameView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false, nil, true)
    self:UpdateInfo()

    if AppReviewMgr.IsReview() then
        UIHelper.SetVisible(self.BtnWebsite, false)
        UIHelper.SetVisible(self.BtnRecharge, false)
    end
end

function UICharacterChangeNameView:OnExit()
    self.bInit = false
end

function UICharacterChangeNameView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    -- UIHelper.BindUIEvent(self.BtnWebsite, EventType.OnClick, function()
    --     UIMgr.Close(self)
    --     UIHelper.OpenWebWithDefaultBrowser("https://jx3.xoyo.com/")
    -- end)

    UIHelper.BindUIEvent(self.BtnBackLogin, EventType.OnClick, function()
        --返回角色
        UIMgr.Close(self)
        if GetClientPlayer().bFightState then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.OPTION_RETURNCHOOSE_NOT_IN_FIGHT)
        else
            Global.BackToLogin(true)
        end
    end)


    UIHelper.BindUIEvent(self.BtnRecharge, EventType.OnClick, function()
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
            return
        end

        local player = PlayerData.GetClientPlayer()
		local nPrice = GetRoleRenameChanceCoinPrice()
		local nCoin = player.nCoin

		if nCoin < nPrice then
			TipsHelper.ShowNormalTip(g_tStrings.tCoinBuyRespond[COIN_BUY_RESPOND_CODE.NOT_ENOUGH_COIN])
            return
		end

        UIHelper.ShowConfirm(g_tStrings.STR_BUY_ROLE_RENAME_CONFIRM, function ()
            local player = PlayerData.GetClientPlayer()
            player.BuyRoleRenameChance(1)

            -- 弱网络处理，点击购买后就限制点击
            UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
        end)
    end)
end

function UICharacterChangeNameView:RegEvent()
    Event.Reg(self, "ON_UPDATE_ROLE_RENAME_CHANCE_COUNT", function()
        self:UpdateInfo()

        -- 弱网络处理，等这里刷新后再放开点击
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    end)

    Event.Reg(self, "ON_COIN_BUY_RESPOND", function()
        TipsHelper.ShowNormalTip(g_tStrings.tCoinBuyRespond[arg0])
    end)
end

function UICharacterChangeNameView:UpdateInfo()
    local player = PlayerData.GetClientPlayer()
    local nPrice = GetRoleRenameChanceCoinPrice()
    local nCoin = player.nCoin

    UIHelper.SetString(self.LabelCoin, tostring(nCoin))
    UIHelper.SetString(self.LabelTongBaoCost, tostring(nPrice))
    UIHelper.SetString(self.LabelChanceLeftNum, tostring(player.nRenameChanceCount))

end


return UICharacterChangeNameView