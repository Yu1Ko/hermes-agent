-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaGuessPoolPop
-- Date: 2026-03-16 16:23:41
-- Desc: 竞猜奖励池弹窗（参考 ui/Config/Default/ArenaGuessPool.lua）
-- ---------------------------------------------------------------------------------

local UIArenaGuessPoolPop = class("UIArenaGuessPoolPop")

-- 商品格子 Toggle 互斥分组 ID
local TOGGLE_GROUP_GOODS = ToggleGroupIndex.ArenaGuessGoods

function UIArenaGuessPoolPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitGoodsItems()
    self:InitPreviewView()
end

function UIArenaGuessPoolPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIArenaGuessPoolPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelArenaActivity)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        self:BuySelectItem()
    end)

    UIHelper.BindUIEvent(self.BtnTryOn, EventType.OnClick, function()
        self:TryOnSelectItem()
    end)

    -- tbToggleItem 互斥选中，选中后记录对应商品索引
    for i = 1, 3 do
        local idx = i
        UIHelper.BindUIEvent(self.tbToggleItem[i], EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self:SelectItem(idx)
            end
        end)
    end
end

function UIArenaGuessPoolPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaGuessPoolPop:UnRegEvent()
    Event.UnRegAll(self)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-- 初始化3个商品格子及价格
function UIArenaGuessPoolPop:InitGoodsItems()
    self.tItemList = {}
    self.nSelectIndex = nil

    local _tSetting = ArenaBonusData.GetArenaGuessSetting()
    if not _tSetting or not _tSetting.tItemInfo then
        return
    end

    for i = 1, 3 do
        local szInfo = _tSetting.tItemInfo[i]
        if not szInfo then
            -- 没有对应配置，隐藏格子
            UIHelper.SetVisible(self.tbWidgetItemCell[i], false)
        else
            UIHelper.SetVisible(self.tbWidgetItemCell[i], true)
            local tInfo = string.split(szInfo, ",")
            local dwLogicID = tonumber(tInfo[1])
            local dwCounterID = tonumber(tInfo[2])

            local tShopInfo = GetRewardsShop().GetRewardsShopInfo(dwLogicID)
            if tShopInfo then
                local dwTabType = tShopInfo.dwItemTabType
                local dwIndex = tShopInfo.dwItemTabIndex

                UIHelper.RemoveAllChildren(self.tbWidgetItem[i])
                local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.tbWidgetItem[i])
                if scriptItem then
                    scriptItem:OnInitWithTabID(dwTabType, dwIndex)
                    scriptItem:SetSelectEnable(false)
                end
                -- 设置互斥分组，同组内只能选中一个
                UIHelper.SetToggleGroupIndex(self.tbToggleItem[i], TOGGLE_GROUP_GOODS)

                -- 设置价格
                local nPrice = CoinShop_GetPrice(dwLogicID, COIN_SHOP_GOODS_TYPE.ITEM)
                UIHelper.SetString(self.tbLabelMoney[i], nPrice)
                UIHelper.LayoutDoLayout(self.tbLayoutMoney[i])

                table.insert(self.tItemList, {
                    dwLogicID   = dwLogicID,
                    dwCounterID = dwCounterID,
                    dwTabType   = dwTabType,
                    dwIndex     = dwIndex,
                })
            end
        end
    end

    self:UpdateBuyBtnState()
end

-- 选择商品，记录选中索引并刷新按钮状态，同时展示道具 Tip
function UIArenaGuessPoolPop:SelectItem(nIndex)
    self.nSelectIndex = nIndex
    self:UpdateBuyBtnState()

    local tItem = self.tItemList and self.tItemList[nIndex]
    if tItem and self.tbWidgetItemCell[nIndex] then
        TipsHelper.ShowItemTips(self.tbWidgetItemCell[nIndex], tItem.dwTabType, tItem.dwIndex, false)
    end
end

-- 根据当前选中商品是否在售更新购买/试穿按钮状态
function UIArenaGuessPoolPop:UpdateBuyBtnState()
    local bCanBuy = false
    local nIndex = self.nSelectIndex
    if nIndex and self.tItemList[nIndex] then
        bCanBuy = CoinShop_GoodsShow(COIN_SHOP_GOODS_TYPE.ITEM, self.tItemList[nIndex].dwLogicID)
    end
    local eState = bCanBuy and BTN_STATE.Normal or BTN_STATE.Disable
    -- UIHelper.SetButtonState(self.BtnBuy, eState)
    UIHelper.SetButtonState(self.BtnTryOn, eState)
end

-- 购买选中的商品（弹出确认框后执行）
function UIArenaGuessPoolPop:BuySelectItem()
    local nIndex = self.nSelectIndex
    if not nIndex or not self.tItemList[nIndex] then
        TipsHelper.ShowNormalTip("请先选择想要购买的外观。")
        return
    end

    local tItem = self.tItemList[nIndex]
    local dwGoodsID = tItem.dwLogicID
    local eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
    local nPrice = CoinShop_GetPrice(dwGoodsID, eGoodsType)

    local hItemInfo = ItemData.GetItemInfo(tItem.dwTabType, tItem.dwIndex)
    local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo))
    local szMsg = string.format("确定花费 %d 购买「%s」？", nPrice, szName)

    UIHelper.ShowConfirm(szMsg, function()
        CoinShop_BuyItem(dwGoodsID, eGoodsType, 1)
    end)
end

function UIArenaGuessPoolPop:InitPreviewView()
    local script = UIHelper.GetBindScript(self.WidgetAnchorNew)
    if script then
        local tAllImages = ArenaBonusData.GetGuessImage()
        local nPlayerForceID = PlayerData.GetPlayerForceID() or 0

        local tImageList = {}
        for _, tRow in ipairs(tAllImages) do
            local nForceID = tRow.nForceID or 0
            if nForceID == -1 or nForceID == 0 or nForceID == FORCE_TYPE.WU_XIANG or nForceID == nPlayerForceID then
                table.insert(tImageList, tRow)
            end
        end
        script:OnEnter(tImageList)
    end
end

-- 跳转到商城对应商品页（试穿）
function UIArenaGuessPoolPop:TryOnSelectItem()
    local nIndex = self.nSelectIndex
    if not nIndex or not self.tItemList[nIndex] then
        TipsHelper.ShowNormalTip("请先选择想要试穿的外观。")
        return
    end
    local dwLogicID = self.tItemList[nIndex].dwLogicID
    local szLink = HOME_TYPE.REWARDS .. "/" .. dwLogicID
    CoinShopData.LinkGoods(szLink, true)
end


return UIArenaGuessPoolPop