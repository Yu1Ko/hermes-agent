-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopTradeCenterStorageItem
-- Date: 2023-04-12 20:38:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopTradeCenterStorageItem = class("UICoinShopTradeCenterStorageItem")

function UICoinShopTradeCenterStorageItem:OnEnter(dwStorageID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwStorageID = dwStorageID
    self:UpdateInfo()
end

function UICoinShopTradeCenterStorageItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopTradeCenterStorageItem:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
    --     local dwStorageID = self.dwStorageID
    --     local nRetCode = GetCoinShopClient().TakeStorageGoods(dwStorageID)
    --     if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
    --         OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
    --     end
    -- end)

    -- UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function ()
    --     local dwStorageID = self.dwStorageID
    --     local nRetCode = GetCoinShopClient().TakeStorageGoods(dwStorageID)
    --     if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
    --         OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
    --     end
    -- end)
end

function UICoinShopTradeCenterStorageItem:RegEvent()
end

function UICoinShopTradeCenterStorageItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopTradeCenterStorageItem:UpdateInfo()
    local tStorage = GetCoinShopClient().GetStorageGoodsInfo(self.dwStorageID)
    local szName = CoinShop_GetGoodsName(tStorage.eGoodsType, tStorage.dwGoodsID)
    local szType = g_tStrings.tGoodsType[tStorage.eGoodsType]
    UIHelper.SetString(self.LabelDetailsTitle, UIHelper.GBKToUTF8(szName))
    UIHelper.SetString(self.LabelChargeback01, szType)
    local bOverdue, szAnnonce = self:GetLimitTime(tStorage)
    szAnnonce = szAnnonce or ""
    UIHelper.SetString(self.LabelChargeback02, szAnnonce)
    UIHelper.SetVisible(self.BtnDel, bOverdue)
    UIHelper.SetVisible(self.BtnGet, not bOverdue)
    if not self.itemIconScript then
        self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    end
    CoinShopPreview.InitItemIcon(self.itemIconScript, tStorage)
end

function UICoinShopTradeCenterStorageItem:GetLimitTime(tStorage)
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local bOverdue = false
    local szTimeText = ""
    if tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR or
        tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE or
        tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM
    then
        return bOverdue
    end

    local bShop = false
    if tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        bShop = true
    end

    if tStorage.eTimeLimitType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT then
        szTimeText = g_tStrings.TRACE_CENTER_SEVEN_DAY
    elseif tStorage.eTimeLimitType == COIN_SHOP_TIME_LIMIT_TYPE.DEAD_LINE then
        local tExteriorInfo
        if bShop then
            tExteriorInfo = hExteriorClient.GetExteriorShopPrice(dwID)
        else
            tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
        end

        local nEndTime = tExteriorInfo.nLimitTime
        local nTime = GetGSCurrentTime()
        local nLeftTime = nEndTime - nTime
        if nLeftTime <= 0 then
            bOverdue = true
            szTimeText = g_tStrings.TRACE_CENTER_OVERDUE
        else
            local szTime = UIHelper.GetTimeText(nLeftTime, nil, true)
            szTimeText = FormatString(g_tStrings.TRACE_CENTER_DEAD_LINE, szTime)
        end
    end
    return bOverdue, szTimeText
end

function UICoinShopTradeCenterStorageItem:TakeStorageGoods()
    local dwStorageID = self.dwStorageID
    local nRetCode = GetCoinShopClient().TakeStorageGoods(dwStorageID)
    if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
    end
end

return UICoinShopTradeCenterStorageItem