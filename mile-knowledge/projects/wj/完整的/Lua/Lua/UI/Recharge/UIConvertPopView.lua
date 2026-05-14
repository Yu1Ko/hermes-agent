-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIConvertPopView
-- Date: 2022-12-22 16:57:15
-- Desc: 通宝兑换点卡
-- ---------------------------------------------------------------------------------

local UIConvertPopView = class("UIConvertPopView")

---@class CHARGE_MODE
---@field MONTH_CARD number 月卡
---@field POINT_CARD number 点卡

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIConvertPopView:_LuaBindList()
    self.LabelDescriptionPointCard    = self.LabelDescriptionPointCard --- 点卡描述
    self.LabelDescriptionMonthCard    = self.LabelDescriptionMonthCard --- 月卡描述

    self.LabelMonthCardExpirationTime = self.LabelMonthCardExpirationTime --- 月卡截止时间
    self.LabelPointCardRemainingTime  = self.LabelPointCardRemainingTime --- 点卡剩余时间

    self.TogModel01                   = self.TogModel01 --- toggle 兑换模式-点卡
    self.TogModel02                   = self.TogModel02 --- toggle 兑换模式-月卡

    self.TogConvert01                 = self.TogConvert01 --- 选项1
    self.TogConvert02                 = self.TogConvert02 --- 选项2
    self.TogConvert03                 = self.TogConvert03 --- 选项3
    self.LabelNum01                   = self.LabelNum01 --- 选项1 数目
    self.LabelTime01                  = self.LabelTime01 --- 选项1 时间
    self.LabelNum02                   = self.LabelNum02 --- 选项2 数目
    self.LabelTime02                  = self.LabelTime02 --- 选项2 时间
    self.LabelNum03                   = self.LabelNum03 --- 选项3 数目
    self.LabelTime03                  = self.LabelTime03 --- 选项3 时间

    self.BtnClose                     = self.BtnClose --- 关闭按钮
    self.BtnCancel                    = self.BtnCancel --- 取消按钮
    self.BtnSure                      = self.BtnSure --- 确认按钮

    self.LayoutTimeInfo               = self.LayoutTimeInfo --- 剩余时间信息的上层layout
end

function UIConvertPopView:OnEnter()
    self.nChargeMode   = CHARGE_MODE.POINT_CARD

    self.tModeList     = {
        { nChargeMode = CHARGE_MODE.POINT_CARD, uiToggle = self.TogModel01 },
        { nChargeMode = CHARGE_MODE.MONTH_CARD, uiToggle = self.TogModel02 },
    }

    -- 参考 settings\GameCardInfo.tab 与 g_tStrings.POINT_CARD_TYPE
    -- 仅显示 nType 与 GetChargeMode() 接口返回值类型一致的条目，因为在 LuaExchangeCoinToTime 接口中会强制判断 pInfo->nType == g_pSO3World->m_nChargeMode
    self.tExchangeList = {
        -- note: 月卡取消前两档
        --{ dwID = 1, nCoin = 1500, szNum = "1500通宝", szTime = "7天12小时", nType = 1, uiToggle = self.TogConvert01, uiLabelNum = self.LabelNum01, uiLabelTime = self.LabelTime01 },
        --{ dwID = 2, nCoin = 3000, szNum = "3000通宝", szTime = "15天", nType = 1, uiToggle = self.TogConvert02, uiLabelNum = self.LabelNum02, uiLabelTime = self.LabelTime02 },
        --{ dwID = 3, nCoin = 5000, szNum = "5000通宝", szTime = "25天", nType = 1, uiToggle = self.TogConvert03, uiLabelNum = self.LabelNum03, uiLabelTime = self.LabelTime03 },
        { dwID = 1, nCoin = 5000, szNum = "5000通宝", szTime = "25天", nType = 1, uiToggle = self.TogConvert01, uiLabelNum = self.LabelNum01, uiLabelTime = self.LabelTime01 },

        { dwID = 3, nCoin = 1500, szNum = "1500通宝", szTime = "2000分钟", nType = 2, uiToggle = self.TogConvert01, uiLabelNum = self.LabelNum01, uiLabelTime = self.LabelTime01 },
        { dwID = 4, nCoin = 3000, szNum = "3000通宝", szTime = "4000分钟", nType = 2, uiToggle = self.TogConvert02, uiLabelNum = self.LabelNum02, uiLabelTime = self.LabelTime02 },
        { dwID = 5, nCoin = 5000, szNum = "5000通宝", szTime = "6667分钟", nType = 2, uiToggle = self.TogConvert03, uiLabelNum = self.LabelNum03, uiLabelTime = self.LabelTime03 },
    }

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIConvertPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIConvertPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        self:ExchangeCoinToTime()
    end)

    for _, tMode in ipairs(self.tModeList) do
        UIHelper.SetToggleGroupIndex(tMode.uiToggle, ToggleGroupIndex.CoinBuyTimeMode)

        UIHelper.BindUIEvent(tMode.uiToggle, EventType.OnClick, function()
            self.nChargeMode = tMode.nChargeMode

            self:SelectFirstExchangeItem()
            self:UpdateInfo()
        end)
    end

    for _, tMode in ipairs(self.tModeList) do
        if tMode.nChargeMode == self.nChargeMode then
            UIHelper.SetSelected(tMode.uiToggle, true)
        end
    end

    for _, tExchange in ipairs(self.tExchangeList) do
        UIHelper.SetToggleGroupIndex(tExchange.uiToggle, ToggleGroupIndex.CoinBuyTimeExchangeTime)
    end

    self:SelectFirstExchangeItem()

    -- 添加通宝信息
    local bAddBtnVisible = false
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutTimeInfo, CurrencyType.Coin, bAddBtnVisible)

    local nCurrentChargeMode = GetChargeMode()

    if nCurrentChargeMode == CHARGE_MODE.POINT_CARD then
        -- 纯点卡服不显示月卡的选项
        UIHelper.SetVisible(self.TogModel02, false)
        UIHelper.SetVisible(self.LabelDescriptionMonthCard, false)
        UIHelper.SetVisible(UIHelper.GetParent(self.LabelMonthCardExpirationTime), false)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTimeInfo, true, true)
end

function UIConvertPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "EXCHANGE_COIN_TO_TIME_RESPOND", function(byCode)
        if byCode == GAME_CARD_RESPOND_CODE.SUCCEED then
            TipsHelper.ShowNormalTip(g_tStrings.STR_BUY_TIME_RESPOND[byCode])

            UIMgr.Close(self)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_BUY_TIME_RESPOND[byCode])
        end

        ShopData.nLastExchangeCoinTime = nil
    end)
end

function UIConvertPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIConvertPopView:UpdateInfo()
    local nCurrentChargeMode                                       = self.nChargeMode

    local nMonthEndTime, nPointLeftTime, nDayLeftTime, nFeeEndTime = Login_GetTimeOfFee()

    nPointLeftTime                                                 = PayData.GetActualPointLeftTime(nPointLeftTime, nMonthEndTime)

    local szPointLeftTime                                          = PayData.FormatPointTime(nPointLeftTime)

    UIHelper.SetString(self.LabelPointCardRemainingTime, szPointLeftTime)

    local dateMonthEndTime = TimeToDate(nMonthEndTime)
    UIHelper.SetString(self.LabelMonthCardExpirationTime, string.format("%d-%02d-%02d %02d:%02d", dateMonthEndTime.year, dateMonthEndTime.month, dateMonthEndTime.day, dateMonthEndTime.hour, dateMonthEndTime.minute))
    -- 未充值时的默认值为 2004-01-01 00:00:00，在这种情况下不予显示
    UIHelper.SetVisible(self.ImgMonthCard, nMonthEndTime > 1072886400)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTimeInfo, true, true)

    -- 更新选项
    local tToggleList = {
        self.TogConvert01,
        self.TogConvert02,
        self.TogConvert03,
    }
    for _, uiToggle in ipairs(tToggleList) do
        UIHelper.SetVisible(uiToggle, false)
    end
    for _, tExchange in ipairs(self.tExchangeList) do
        if tExchange.nType == nCurrentChargeMode then
            UIHelper.SetVisible(tExchange.uiToggle, true)
            
            UIHelper.SetString(tExchange.uiLabelNum, tExchange.szNum)
            UIHelper.SetString(tExchange.uiLabelTime, tExchange.szTime)
        end
    end
end

local MAX_WAIT_TIME = 5 -- 购买等回包最多等多少秒

function UIConvertPopView:ExchangeCoinToTime()
    -- 确保弱网络环境下连续点击不会触发多次购买
    if ShopData.nLastExchangeCoinTime and (GetCurrentTime() < ShopData.nLastExchangeCoinTime + MAX_WAIT_TIME) then
        TipsHelper.ShowNormalTip("购买操作太频繁，请稍后再试")
        return
    end

    local nCurrentChargeMode = self.nChargeMode

    local tConfig            = nil
    for _, info in ipairs(self.tExchangeList) do
        if info.nType == nCurrentChargeMode and UIHelper.GetSelected(info.uiToggle) then
            tConfig = info
            break
        end
    end

    if tConfig == nil then
        TipsHelper.ShowNormalTip("请先选择要兑换的时长")
        return
    end

    if g_pClientPlayer.nCoin < tConfig.nCoin then
        -- 通宝不够
        TipsHelper.ShowNormalTip(string.format("通宝不足，当前拥有%d，需要%d", g_pClientPlayer.nCoin, tConfig.nCoin))
        return
    end

    local szMode = nCurrentChargeMode == CHARGE_MODE.POINT_CARD and g_tStrings.STR_CARD_COINBUY_CONFIRM_POINT_CARD or g_tStrings.STR_CARD_COINBUY_CONFIRM_MONTH_CARD
    local szContent = FormatString(szMode, tConfig.nCoin, 
					tConfig.szTime)
    UIHelper.ShowConfirm(szContent, function()
        -- 兑换对应点卡
        LOG.DEBUG("ExchangeCoinToTime id=%d desc=%s %s", tConfig.dwID, tConfig.szNum, tConfig.szTime)
        GetGameCardClient().ExchangeCoinToTime(tConfig.dwID)
    end)

    ShopData.nLastExchangeCoinTime = GetCurrentTime()
end

function UIConvertPopView:SelectFirstExchangeItem()
    for _, tExchange in ipairs(self.tExchangeList) do
        if tExchange.nType == self.nChargeMode then
            UIHelper.SetSelected(tExchange.uiToggle, true)
            break
        end
    end
end

return UIConvertPopView