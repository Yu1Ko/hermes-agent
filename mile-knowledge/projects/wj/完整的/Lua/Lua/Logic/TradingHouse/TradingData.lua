local tSearchSort =
{
    ["全部"] = {
    	nSortID = 0,
    	tSubSort = {
    		["全部"] = nil,
    	},
    },
    ["武器"] =
    {
        nSortID = 1,
        tSubSort =
        {
            ["全部兵刃"] = 0,
            ["棍类"]   = 1,
            ["长兵"]   = 2,
            ["短兵类"] = 3,
            --["拳套"] = 4,
            ["双兵类"] = 5,
            ["笔类"]   = 6,
            ["重兵类"] = 7,
            ["虫笛类"] = 8,
            ["千机匣"] = 9,
            ["弯刀"] = 10,
            ["棒"] = 11,
            ["盾刀"] = 12,
            ["琴"] = 13,
            ["傲霜刀"] = 14,
            ["伞"] = 15,
            ["链刃"] = 16,
            ["魂灯"] = 17,
            ["百草卷"] = 18,
            ["横刀"] = 19,
            ["弓箭"] = 20,
            ["折扇"] = 21,
            ["牵丝轮"] = 22,
        },
    },
    ["暗器"] =
    {
        nSortID = 2,
        tSubSort =
        {
            ["全部暗器"] = 0,
            ["投掷"] = 1,
            -- ["弓弦"] = 2,
            --["机射"] = 3,
            ["弹药"] = 4,
        },
    },
    ["服饰"] =
    {
        nSortID = 3,
        tSubSort =
        {
            ["全部服饰"] = 0,
            ["上衣"] = 1,
            ["帽子"] = 2,
            ["腰带"] = 3,
            ["下装"] = 4,
            ["鞋子"] = 5,
            ["护腕"] = 6,
        },
    },
    ["饰物"] =
    {
        nSortID = 4,
        tSubSort =
        {
            ["全部饰物"] = 0,
            ["项链"] = 1,
            ["戒指"] = 2,
            ["腰坠"] = 3,
            --["腰部挂件"] = 4,
            --["背部挂件"] = 5,
            --["披风"] = 6,
            --["左肩饰"] = 7,
            --["右肩饰"] = 8,
        },
    },
    ["坐骑"] =
    {
        nSortID = 5,
        tSubSort =
        {
            ["全部坐骑"] = 0,
            ["坐骑"]     = 1,
            ["坐骑头饰"] = 2,
            ["坐骑胸饰"] = 3,
            ["坐骑足饰"] = 4,
            ["坐骑鞍具"] = 5,
            ["坐骑幼崽"] = 6,
        },
    },
    ["包裹"] = {nSortID = 6, tSubSort = {["包裹"] = nil}, },
    ["秘笈"] =
    {
        nSortID = 7,
        tSubSort =
        {
            ["全部秘笈"] = 0,
            ["纯阳秘笈"] = 1,
            ["天策秘笈"] = 2,
            ["少林秘笈"] = 3,
            ["七秀秘笈"] = 4,
            ["万花秘笈"] = 5,
            ["江湖秘笈"] = 6,
            ["藏剑秘笈"] = 7,
            ["五毒秘笈"] = 8,
            ["唐门秘笈"] = 9,
            ["明教秘笈"] = 10,
            ["丐帮秘笈"] = 11,
            ["苍云秘笈"] = 12,
            ["长歌秘笈"] = 13,
            ["霸刀秘笈"] = 14,
            ["蓬莱秘笈"] = 15,
            ["凌雪阁秘笈"] = 16,
            ["衍天宗秘笈"] = 17,
            ["药宗秘笈"] = 18,
        },
    },
    -- ["配方"] =
    -- {
    --     nSortID = 8,
    --     tSubSort =
    --     {
    --         ["全部配方"] = 0,
    --         ["缝纫配方"] = 1,
    --         ["烹饪配方"] = 2,
    --         ["医术配方"] = 3,
    --         ["铸造配方"] = 4,
    --         --["淬炼配方"] = 5,
    --     },
    -- },
    ["消耗品"] =
    {
        nSortID = 9,
        tSubSort =
        {
            ["全部消耗品"] = 0,
            ["食物"]     = 1,
            ["药品"]     = 2,
            --["物品强化"] = 3,
            ["礼品"]     = 4,
            ["饲料与零件"]     = 5,
            --["灵韵珠"]     = 6,
            --["装备祭炼"]     = 7,
            --["装备炼化"]     = 8,
        },
    },
    ["物品强化"] =
    {
        nSortID = 13,
        tSubSort =
        {
            ["全部物品强化"] = 0,
            ["帽子"] = 1,
            ["上衣"] = 2,
            ["下装"] = 3,
            ["腰带"] = 4,
            ["鞋子"] = 5,
            ["护腕"] = 6,
            ["武器"] = 7,
            ["饰品"] = 8,
        },
    },
    ["材料"] =
    {
        nSortID = 10,
        tSubSort =
        {
            ["全部材料"] = 0,
            ["采金"] = 1,
            ["神农"] = 2,
            ["医术"]   = 3,
            ["缝纫"] = 4,
            ["庖丁"] = 5,
            ["烹饪"] = 6,
            ["阅读"] = 7,
            ["特殊材料"] = 8,
            ["梓匠"] = 9,
            ["铸造"] = 10,
            ["旧物"] = 11,
        },
    },
    ["书籍"] =
    {
        nSortID = 12,
        tSubSort =
        {
            ["全部书籍"] = 0,
            ["杂集"] = 1,
            ["道学"] = 2,
            ["佛学"] = 3,
        },
    },
    ["宝石"] =
    {
        nSortID = 15,
        tSubSort =
        {
            ["全部宝石"] = 0,
            ["五行石"] = 1,
            --["木系五行石"] = 2,
            --["水系五行石"] = 3,
            --["火系五行石"] = 4,
            --["土系五行石"] = 5,
            ["五彩石"] = 6,
        },
    },
    ["宝箱"] =
    {
        nSortID = 16,
        tSubSort =
        {
            ["全部宝箱"] = 0,
            ["宝箱"] = 1,
            ["钥匙"] = 2,
        },
    },
    ["帮会产物"] =
    {
        nSortID = 14,
        tSubSort =
        {
            ["全部帮会产物"] = 0,
            ["瑰石"] = 1,
            ["其他"] = 2,
        },
    },
    ["其他"] =
    {
        nSortID = 20,
        tSubSort =
        {
            ["全部其他"] = 0,
            ["垃圾"] = 1,
            ["其他"] = 2,
        },
    },
    ["家具"] =
    {
        nSortID = 21,
        tSubSort =
        {
            ["全部家具"] = 0,
            ["建筑"] = 1,
            ["家具"] = 2,
            ["景观"] = 3,
            ["收集"] = 4,
            ["家具礼盒"] = 5,
        },
    },
    ["外观"] =
    {
        nSortID = 22,
        tSubSort =
        {
            ["全部外观"] = 0,
            ["成衣"] = 1,
            ["发型"] = 2,
            ["面部挂件"] = 3,
            ["背部挂件"] = 4,
            ["腰部挂件"] = 5,
            ["左肩饰"] = 6,
            ["右肩饰"] = 7,
            ["披风"] = 8,
            ["宠物"] = 9,
            ["挂宠"] = 10,
            ["外观礼盒"] = 11,
            ["小玩意"] = 12,
            ["其他"] = 13,
            ["头饰"] = 14,
        },
    },
    ["侠客养成"] =
    {
        nSortID = 24,
        tSubSort =
        {
            ["全部侠客养成"] = 0,
            --["通用"] = 0,
            --["装备匣"] = 1,
            ["秘籍"] = 2,
            ["丹药"] = 3,
            ["材料"] = 4,
        },
    },
    ["百战异闻录"] =
    {
        nSortID = 25,
        tFilter = {"tSearchQuality"},
        tSubSort =
        {
            --["通用"] = 0,
            ["全部"] = 0,
            ["招式要诀"] = 1,
            ["武技殊影图"] = 2,
        },
    },
    ["奇境寻宝"] =
    {
        nSortID = 26,
        tFilter = {"tSearchQuality"},
        tSubSort =
        {
            ["全部"] = 0,
            ["武器"] = 3,
            ["暗器"] = 4,
            ["头盔"] = 5,
            ["上装"] = 6,
            ["下装"] = 7,
            ["腰带"] = 8,
            ["护手"] = 9,
            ["鞋子"] = 10,
            ["项链"] = 11,
            ["腰坠"] = 12,
            ["戒指"] = 13,
            ["伪装"] = 14,
            ["其他"] = 15,
        },
    },
}

local function PackMoney(nGold, nSilver, nCopper)
	local t = {}
	t.nGold = nGold or 0
	t.nSilver = nSilver or 0
	t.nCopper = nCopper or 0
	return t
end

--别和AUCTION_ITEM_LIST_TYPE值冲突了
local AUCTION_ITEM_OPERATION_TYPE ={
    BID = 9,
}


local tLookupCDID = {
    [AUCTION_ITEM_LIST_TYPE.NORMAL_LOOK_UP] = 1204,
    [AUCTION_ITEM_LIST_TYPE.PRICE_LOOK_UP]  = 2007,
    [AUCTION_ITEM_LIST_TYPE.DETAIL_LOOK_UP] = 2008,
    [AUCTION_ITEM_LIST_TYPE.AVG_LOOK_UP]    = 2009,
    [AUCTION_ITEM_LIST_TYPE.SELL_LOOK_UP]   = 2010,
    [AUCTION_ITEM_OPERATION_TYPE.BID]   = 2342,
}
local APPLY_CD = 1000

local CD_TIME = 10
local NEAR_DUE_TIME = 600
local PAGE_NUM = 50
local MAX_RESELL_NUM = 15
local BUY_ITEM_CD = 1000
local MAX_STACK_NUM = 8
local CHARGE_RATE = 0.05
local MAX_CHARGE_COPPER = 200000000
local MAX_PRICE = PackMoney(50000000, 0, 0)
local MAX_PRICE_COPPER = 500000000000
local nLastPriceRecordValidTime = 0
local PER_DAY_FRESH_TIME = 7
local MAX_HISTORY_SEARCH_NUM = 10
local DELAY_BID_ADD_MONEY_PERCENTAGE = 0.05
local nNeutralActivityID = 885
local MAX_CONFIRM_GOLD = 1000

local tbSpecialWeaponSortID = {
    1,2,3,4
}

local tbSpecialSchoolSortID = {
    {25, 2}
}

-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TradingData
-- Date: 2023-03-06 16:34:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

TRADING_ITEM_PANEL =
{
    BUY = 1,
    SELL = 2,
    CHANGE = 3,
}

local APPLY_DATA_TYPE = {
    NORMAL = 1,
    DETAIL = 2,
    PRICE = 3,
    SELL = 4,
    AVG_PRICE = 5,
    BMLOOKUP = 6,
}

TradingData = TradingData or {className = "TradingData"}
local self = TradingData
-------------------------------- 消息定义 --------------------------------
TradingData.Event = {}
TradingData.Event.XXX = "TradingData.Msg.XXX"

function TradingData.Init()
    self._registerEvent()
end

function TradingData.UnInit()
    Timer.DelAllTimer(self)
end

--交易行
function TradingData.InitTradingHouse(dwTargetType, dwTargetID)

    if not self.bInit then
        self.tbNextApplyTime = {}
        self.bInit = true
    end

	self.dwTargetID = dwTargetID
	self.dwTargetType = dwTargetType


    self.InitData()

    self.BMLookup()
    UIMgr.Open(VIEW_ID.PanelTradingHouse)
    self.UpdateBusinessTypeInfo()
end

--限时拍卖
function TradingData.InitLimitAuction(dwTargetID)

    if not self.bInit then
        self.bInit = true
    end

	self.dwTargetID = dwTargetID

    UIMgr.Open(VIEW_ID.PanelWorldAuction)
end


function TradingData.InitData()
    self.nSellTotalCount = 0
    self.tbMyStateData = {}
    self.nSortID = 0
    self.nSubSortID = 0
    -- self.tBidCache = {}
end

-- function TradingData.GetCurrentOpenedActivityID()
-- 	for _, nActivityID in pairs(CAMP_AUCTION) do
-- 		if nActivityID ~= CAMP_AUCTION.ACTIVITY_ID_OF_PEACE then
-- 			if ActivityData.IsActivityOn(nActivityID) or UI_IsActivityOn(nActivityID) then
-- 				return nActivityID
-- 			end
-- 		end
-- 	end
-- 	return CAMP_AUCTION.ACTIVITY_ID_OF_ZHU_LU_ZHONG_YUAN
-- end

function TradingData.IsCommandAuctionRelativeActivityOpen(bNeuter)

    if (not bNeuter) and g_pClientPlayer.nCamp == CAMP.NEUTRAL then return false end

    local dwActivityID = nil
	--如果休战活动开启，就不显示拍卖按钮,优先级比其他活动高
	--if (IsActivityOn(CAMP_AUCTION.ACTIVITY_ID_OF_PEACE) or UI_IsActivityOn(CAMP_AUCTION.ACTIVITY_ID_OF_PEACE)) then
		--return bOpen
	--end

    if not self.tbAuctionActivityList then self.tbAuctionActivityList = Table_GetAuctionActivityList() end
	for _, nActivityID in pairs(self.tbAuctionActivityList) do
		if nActivityID ~= CAMP_AUCTION.ACTIVITY_ID_OF_PEACE then
            local tbActiveInfo = Table_GetAuctionActivityInfo(nActivityID)
			if not bNeuter and (not tbActiveInfo.bNeuter) and (IsActivityOn(nActivityID) or UI_IsActivityOn(nActivityID)) then
				dwActivityID = nActivityID
            elseif bNeuter and tbActiveInfo.bNeuter and (IsActivityOn(nActivityID) or UI_IsActivityOn(nActivityID)) then
                dwActivityID = nActivityID
			end
		end
	end

	return dwActivityID
end

function TradingData.IsFliterWeaponType(nSortID)
    return table.contain_value(tbSpecialWeaponSortID, nSortID)
end

function TradingData.IsFliterSchoolType(nSortID, nSubSortID)
    for _, tbInfo in ipairs(tbSpecialSchoolSortID) do
        if tbInfo[1] == nSortID and tbInfo[2] == nSubSortID then
            return true
        end
    end

    return false
end
---------------------------------------------------------------------------发送信息-------------------------------------------------------------


function TradingData.GetMaxStackNum(dwItemID)
    local AuctionClient = GetAuctionClient()
    return AuctionClient.GetMaxStackNum(dwItemID)
end

function TradingData.ApplyDetailLookUp(bFromButton, nStartIndex, Item, nDescendingOrder)
    if not Item then return false end
    if bFromButton and (not self._checkCanApplyData(AUCTION_ITEM_LIST_TYPE.DETAIL_LOOK_UP)) then return false end

    local nBookRecipeID = -1
    if Item.nGenre == ITEM_GENRE.BOOK then
        nBookRecipeID = Item.nBookID
    end

    local tbApplyInfo = {dwTargetID = self.dwTargetID,
    nRequestID = AUCTION_ITEM_LIST_TYPE.DETAIL_LOOK_UP,
    szSaleName = ItemData.GetItemNameByItem(Item),
    bDesc = nDescendingOrder,
    nStartIndex = nStartIndex,
    byOrderType = AUCTION_ORDER_TYPE.PRICE,
    dwItemTabType = Item.dwTabType,
    dwItemTabIndex = Item.dwIndex,
    nBookRecipeID = nBookRecipeID,
    nGold = g_pClientPlayer.GetMoneyLimitByGold() or 0}

    return self.ApplyAuctionInfo(tbApplyInfo)
end

function TradingData.ApplyPriceLookUp(bFromButton, tbItem, nStartIndex, nDescendingOrder)
    if bFromButton and (not self._checkCanApplyData(AUCTION_ITEM_LIST_TYPE.PRICE_LOOK_UP)) then return false end

    local nBookRecipeID = -1
    if tbItem.nGenre == ITEM_GENRE.BOOK then
        nBookRecipeID = tbItem.nBookID
    end

    local tbApplyInfo = {nRequestID = AUCTION_ITEM_LIST_TYPE.PRICE_LOOK_UP,
    byOrderType = AUCTION_ORDER_TYPE.PRICE, szSaleName = ItemData.GetItemNameByItem(tbItem), dwTargetID = self.dwTargetID,
    bDesc = nDescendingOrder, nStartIndex = nStartIndex, dwItemTabType = tbItem.dwTabType, dwItemTabIndex = tbItem.dwIndex, nBookRecipeID = nBookRecipeID}

	return self.ApplyAuctionInfo(tbApplyInfo)
end

function TradingData.ApplySellLookUp(bFromButton, nStartIndex)
    if bFromButton and (not self._checkCanApplyData(AUCTION_ITEM_LIST_TYPE.SELL_LOOK_UP)) then return false end
    local tbApplyInfo = {nRequestID = AUCTION_ITEM_LIST_TYPE.SELL_LOOK_UP,
    byOrderType = AUCTION_ORDER_TYPE.LEFT_TIME, dwTargetID = self.dwTargetID,
    bDesc = 0, nStartIndex = nStartIndex, dwSellerID = g_pClientPlayer.dwID}

	return self.ApplyAuctionInfo(tbApplyInfo)
end

function TradingData.ApplyNormalLookUp(bFromButton, nStartIndex, nSortID, nSubSortID, nQuality, szSaleName, bDescendingOrder, nKungfuMask)
    if bFromButton and (not self._checkCanApplyData(AUCTION_ITEM_LIST_TYPE.NORMAL_LOOK_UP)) then return false end

    if szSaleName and string.find(szSaleName, "%[") == 1 and string.find(szSaleName, "%]") == #szSaleName then
		szSaleName = string.match(szSaleName, "%[(.+)%]")
	end

    if szSaleName and szSaleName ~= "" then
        self.AddHistory(szSaleName)
    end

    local tbApplyInfo = {nRequestID = AUCTION_ITEM_LIST_TYPE.NORMAL_LOOK_UP,
    byOrderType = AUCTION_ORDER_TYPE.MINI_PRICE,
    dwTargetID = self.dwTargetID,
    bDesc = bDescendingOrder,
    nStartIndex = nStartIndex,
    nSortID = nSortID or self.nSortID,
    nSubSortID = nSubSortID or self.nSubSortID,
    nQuality = nQuality,
    -- nMinLevel = self.IsFliterType(nSortID) and nMinLevel or nil,
    -- nMaxLevel = self.IsFliterType(nSortID) and nMaxLevel or nil,
    szSaleName = (szSaleName and szSaleName ~= "") and UIHelper.UTF8ToGBK(szSaleName) or szSaleName,
    nKungfuMask = nKungfuMask,}--UTF8ToGBK手机端会将""转为nil

	return self.ApplyAuctionInfo(tbApplyInfo)
end

function TradingData.AddHistory(szItemName)
    local tbHistory = Storage.TradingHouse.tbSearchHistory
    for index, szName in ipairs(tbHistory) do
        if szName == szItemName then
            table.remove(tbHistory, index)
            break
        end
    end
    table.insert(tbHistory, szItemName)
    if #tbHistory > MAX_HISTORY_SEARCH_NUM then
        table.remove(tbHistory, 1)
    end
    Storage.TradingHouse.Dirty()
end

function TradingData.GetHistoryList()
    return Storage.TradingHouse.tbSearchHistory
end

function TradingData.ClearHistory()
    if #Storage.TradingHouse.tbSearchHistory == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_NO_HISTORY)
    end
    Storage.TradingHouse.tbSearchHistory = {}
    Storage.TradingHouse.Dirty()
end

function TradingData.DeleteHistoryByName(szItemName)
    for index, szName in ipairs(Storage.TradingHouse.tbSearchHistory) do
        if szName == szItemName then
            table.remove(Storage.TradingHouse.tbSearchHistory, index)
            break
        end
    end
    Storage.TradingHouse.Dirty()
end

function TradingData.ApplyAuctionInfo(tbApplyInfo)


	local t = tbApplyInfo
    local AuctionClient = GetAuctionClient()
	AuctionClient.ApplyLookup(
		t.dwTargetID, t.nRequestID, t.szSaleName or "", t.nSortID, t.nSubSortID,
		t.nLevelMin, t.nLevelMax, t.nQuality, t.szSellerName or "", t.dwSellerID,
		t.dwBidderID, t.nGold, t.nSilver, t.nCopper, (t.nStartIndex - 1) * PAGE_NUM, t.byOrderType,
		t.bDesc, t.dwItemTabType or 0, t.dwItemTabIndex or 0, t.nBookRecipeID, tostring(t.nKungfuMask) or "0"
	)
	return true
end

function TradingData.ApplyAvgPrice(bFromButton, dwItemID)
    if bFromButton and (not self._checkCanApplyData(AUCTION_ITEM_LIST_TYPE.AVG_LOOK_UP)) then return false end
    if not dwItemID then return end
    local AuctionClient = GetAuctionClient()
    return AuctionClient.AvgPricesLookup(self.dwTargetID, AUCTION_ITEM_LIST_TYPE.AVG_LOOK_UP, dwItemID)
end


--重新上架物品
function TradingData.ReShelfItem()

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "sell") then  return end
    if not self.tbReShelfItem then return end
    local AuctionClient = GetAuctionClient()
    for dwSaleID, tbSellInfo in pairs(self.tbReShelfItem) do
        self.SellItem(tbSellInfo)
    end
end


function TradingData.SellItem(tbSellInfo)
    if not ((tbSellInfo.nPriceGold == 0 and tbSellInfo.nPriceSilver == 0 and tbSellInfo.nPriceCopper == 0)
            or tbSellInfo.nLeftHour == 0
            or tbSellInfo.nSaleNum == 0) then
            local AuctionClient = GetAuctionClient()
            AuctionClient.Sell(self.dwTargetID, tbSellInfo.dwBox or 0, tbSellInfo.dwX or 0, tbSellInfo.nPriceGold, tbSellInfo.nPriceSilver,
            tbSellInfo.nPriceCopper, tbSellInfo.nLeftHour, tbSellInfo.nSaleNum or tbSellInfo.Num, tbSellInfo.bResell, tbSellInfo.dwSaleID,  tbSellInfo.dwItemID)
            Event.Dispatch(EventType.OnApplySellItem)
    end
end


function TradingData.BuyItem(tBuyInfo)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "buy") then return end
    local bCoolDown, nCD = self._checkCanApplyData(AUCTION_ITEM_OPERATION_TYPE.BID)
	if not bCoolDown then
        -- TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BUY_ITEM_COLD)
        Event.Dispatch(EventType.ON_AUCTION_BUY_RESPOND, false, nCD)--CD中，购买失败
		return
	end
    local AuctionClient = GetAuctionClient()
	AuctionClient.Bid(self.dwTargetID, tBuyInfo.dwItemID, tBuyInfo.nBidNum, tBuyInfo.nPriceGold,
	tBuyInfo.nPriceSilver, tBuyInfo.nPriceCopper)
    Event.Dispatch(EventType.OnApplyBuyItem)
end

--下架待售物品
function TradingData.CanCelItem(dwSaleID)
    UIHelper.ShowConfirm(g_tStrings.AuctionString.STR_CANCEL_CONFIRM, function()
        local AuctionClient = GetAuctionClient()
        AuctionClient.Cancel(self.dwTargetID, dwSaleID)
    end)
end

function TradingData.BMLookup(nCamp)
    local AuctionClient = GetAuctionClient()
    if nCamp then
        AuctionClient.BMLookup(self.dwTargetID, UIHelper.UTF8ToGBK(nCamp))
        return true
    end
    return false
end


--nBidMoney单位是金
function TradingData.BMBid(tbBMData, nBidMoney, nCamp)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "Bid") then
        return
    end

    if tbBMData.InDelayBid == 1 then
        if nBidMoney < math.ceil(tbBMData.StartPrice * DELAY_BID_ADD_MONEY_PERCENTAGE) then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_DELAY_ADD_MONEY_CHECK)
            return false
        end
    end
    if nBidMoney and nBidMoney > 0 then
        GetAuctionClient().BMBid(self.dwTargetID, tbBMData.ID, nBidMoney, nCamp)
        return true
    end
    return false
end


function TradingData.BMBidCanCel(tbBMData, nCamp)

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "Bid") then
		return
	end

	local szName   = ItemData.GetItemNameByItem(tbBMData.Item)
	local dwSellID = tbBMData.ID
    UIHelper.ShowConfirm(string.format(g_tStrings.AuctionString.STR_BM_CANCEL, UIHelper.GBKToUTF8(szName)), function()
        GetAuctionClient().BMBidCancel(self.dwTargetID, dwSellID, nCamp)
    end)

end


---------------------------------------------------------------------接收到消息-----------------------------------------------------

function TradingData.GetBusinessTypeInfo()
    local tbBusinessTypeInfo = {}
    for szSortName, tbData in pairs(tSearchSort) do
        local Info = {nSortID = tbData.nSortID, szName = szSortName, tbSub = {}}
        for szSubName, nSubSortID in pairs(tbData.tSubSort) do
            table.insert(Info.tbSub, {szSubName = szSubName, nSubSortID = nSubSortID})
        end
        table.sort(Info.tbSub, function(l, r)
            return l.nSubSortID < r.nSubSortID
        end)
        table.insert(tbBusinessTypeInfo, Info)
    end
    table.sort(tbBusinessTypeInfo, function(l, r)
        return l.nSortID < r.nSortID
    end)
    return tbBusinessTypeInfo
end


function TradingData.UpdateBusinessTypeInfo()
    local tbBusinessTypeInfo = self.GetBusinessTypeInfo()
    self.tbBusinessTypeInfo = tbBusinessTypeInfo
    Event.Dispatch(EventType.OnBusinessTypeInfoUpdate, tbBusinessTypeInfo)
end

function TradingData.ON_NORMAL_LOOK_UP_RES(nTotalCount, tbBusinessResultData)
    -- self.bCanApplyNormal = true
    Event.Dispatch(EventType.ON_NORMAL_LOOK_UP_RES, nTotalCount, tbBusinessResultData)
end

function TradingData.ON_SELL_LOOK_UP_RES(nTotalCount, tbMyStateData)
    -- self.bCanApplySell = true
    self.nSellTotalCount = nTotalCount
    self.tbMyStateData = tbMyStateData
    Event.Dispatch(EventType.ON_SELL_LOOK_UP_RES, nTotalCount, tbMyStateData)
end

function TradingData.ON_PRICE_LOOK_UP(nTotalCount, tbGoodInfo)
    -- self.bCanApplyPrice = true
    self.nPriceTotalCount = nTotalCount
    self.tbGoodInfo = tbGoodInfo
    Event.Dispatch(EventType.ON_PRICE_LOOK_UP, nTotalCount, tbGoodInfo)
end

function TradingData.ON_DETAIL_LOOK_UP(nTotalCount, tItemInfo)
    -- self.bCanApplyDetail = true
    self.nDetailCount = nTotalCount
    self.tbDetailInfo = tItemInfo
    Event.Dispatch(EventType.ON_DETAIL_LOOK_UP, nTotalCount, tItemInfo)
end

function TradingData.ON_AVG_LOOK_UP_RES(nLength, tbPriceData, tbMinPrice, tbMaxPrice)
    -- self.bCanApplyAvg_Price = true
    local tbAvgPrice = {nGold = 0, nSilver = 0, nCopper = 0}
	local nCount = 0
	local nSumCopper = 0
	local nMaxCopper = 0
	local nMinCopper = 0
	for i = nLength, 1, -1 do
		if tbPriceData[i] and tbPriceData[i].Price then
			local nCopper = CovertMoneyToCopper(tbPriceData[i].Price)
			if nCopper ~= 0 then
				nSumCopper = nSumCopper + nCopper
				nCount = nCount + 1
				nMaxCopper = math.max(nMaxCopper, nCopper)
			end
		end
	end
	nMinCopper = nMaxCopper
	for i = nLength, 1, -1 do
		if tbPriceData[i] and tbPriceData[i].Price then
			local nCopper = CovertMoneyToCopper(tbPriceData[i].Price)
			if nCopper ~= 0 then
				nMinCopper = math.min(nMinCopper, nCopper)
			end
		end
	end
	if nCount > 0 then
		local nAvgCopper = math.ceil(nSumCopper / nCount)
		tbAvgPrice = CovertCopperToMoney(nAvgCopper)
	end

    self.tbPriceData = tbPriceData
    self.tbMinPrice = tbMinPrice
    self.tbMaxPrice = tbMaxPrice
    self.nMaxCopper = nMaxCopper
    self.nMinCopper = nMinCopper
    self.tbAvgPrice = tbAvgPrice
    Event.Dispatch(EventType.ON_AVG_LOOK_UP_RES, nLength, tbPriceData, tbMinPrice, tbMaxPrice, nMaxCopper, nMinCopper, self.tbAvgPrice)
end

function TradingData.ON_AUCTION_SELL_SUCCESS()
    Event.Dispatch(EventType.ON_AUCTION_SELL_SUCCESS)
end

function TradingData.ON_AUCTION_BID_RESPOND()
    Event.Dispatch(EventType.ON_AUCTION_BID_RESPOND)
end


------------------------------------------------------------------一些接口---------------------------

function TradingData.OnSelectClassify(nSortID, nSubSortID, nShowQuality, bDescendingOrder, nKungfuMask)
    local bApplySuccess = self.ApplyNormalLookUp(true, 1, nSortID, nSubSortID, nShowQuality, "", bDescendingOrder, nKungfuMask)
    if bApplySuccess then
        self.nSortID = nSortID
        self.nSubSortID = nSubSortID
    end
    return bApplySuccess
end

function TradingData.CanBMBid(tbBMData, nBidMoney)
    if tbBMData.InDelayBid == 1  and nBidMoney < math.ceil(tbBMData.StartPrice * DELAY_BID_ADD_MONEY_PERCENTAGE) then
        -- TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_DELAY_ADD_MONEY_CHECK)
        return false
    end

    local nLeastGold = self.GetMinBidPrice(tbBMData)

    if nBidMoney * 10000 < nLeastGold then
        -- TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_LESS_THAN_LEAST_BID)
        return false
    end

    local tbMyMoney = ItemData.GetMoney()
    local nMyMoney = UIHelper.BullionGoldSilverAndCopperToMoney(tbMyMoney.nBullion, tbMyMoney.nGold, tbMyMoney.nSilver, tbMyMoney.nCopper)
    if nMyMoney < nBidMoney * 10000 then
        -- TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_NOT_ENOUGH_MONEY)
        return false
    end

    if not nBidMoney or nBidMoney <= 0 then
        return false
    end
    return true
end

--添加准备重新上架的物品
function TradingData.AddReShelfItem(tbData)
    if not self.tbReShelfItem then
        self.tbReShelfItem = {}
        self.nReShelfItemNum = 0
    end

    if self.nReShelfItemNum >= MAX_RESELL_NUM then
        TipsHelper.ShowNormalTip(string.format(g_tStrings.AuctionString.STR_MAX_RESELL_ERROR, MAX_RESELL_NUM))
        -- return
    end

    local tbSellInfo = self._createSellItemInfo(tbData)
    if not self.tbReShelfItem[tbSellInfo.dwSaleID] then
        self.tbReShelfItem[tbSellInfo.dwSaleID] = tbSellInfo
        self.nReShelfItemNum = self.nReShelfItemNum + 1
    end
end

--删除准备重新上架的物品
function TradingData.DeleteReShelfItem(dwSaleID)
    if not self.tbReShelfItem then return end
    if self.tbReShelfItem[dwSaleID] then
        self.tbReShelfItem[dwSaleID] = nil
        self.nReShelfItemNum = self.nReShelfItemNum - 1
    end
end

function TradingData.ClearReShelfItem()
    self.tbReShelfItem = nil
    self.nReShelfItemNum = 0
end

function TradingData.GetBusinessResultData(tbBusinessResultData, nType)
    if not nType then
        return tbBusinessResultData
    else
        return self.FliterBusinessResultDataByType(tbBusinessResultData, nType)
    end
end

-- function TradingData.ScreenBusinessResultData(tbBusinessResultData, nQuality)
--     local tbRes = {}
--     if nQuality == -1 then return tbBusinessResultData end
--     if not tbBusinessResultData then return end
--     for index, tbData in ipairs(tbBusinessResultData) do
--         if tbData.Item.nQuality >= nQuality then
--             table.insert(tbRes, tbData)
--         end
--     end
--     return tbRes
-- end

function TradingData.FliterBusinessResultDataByType(tbBusinessResultData, nType)
    local tbRes = {}
    if nType == -1 then return tbBusinessResultData end
    if not tbBusinessResultData then return end
    for _, tbData in ipairs(tbBusinessResultData) do
        local item = tbData.Item
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        if bCanShowPVP and item.nEquipUsage == nType then
            table.insert(tbRes, tbData)
        end
    end
    return tbRes
end

function TradingData.GetDetailList()
   return self.tbDetailInfo
end

function TradingData.GetGoodInfo()
    return self.tbGoodInfo
 end

function TradingData.SortLookUpDataByPrice(tbLookUpData, bDescendingOrder)
    if not tbLookUpData then return end
    table.sort(tbLookUpData, function(l, r)
        local nLMoney = CovertMoneyToCopper(l.Price)
        local nRMoney = CovertMoneyToCopper(r.Price)
        if bDescendingOrder then
            return nLMoney > nRMoney
        else
            return nLMoney < nRMoney
        end
    end)
    return tbLookUpData
end

function TradingData.SortSellItemByTime(tbMyStateData, bUp)
    table.sort(tbMyStateData, function(l, r)
        if bUp then
            return l.LeftTime < r.LeftTime
        else
            return l.LeftTime > r.LeftTime
        end
    end)

    return tbMyStateData
    -- self.ON_SELL_LOOK_UP_RES(self.nSellTotalCount, self.tbMyStateData)
end

function TradingData.SortSellItemByPrice(tbMyStateData, bUp)
    table.sort(tbMyStateData, function(l, r)
        local nMoneyL = UIHelper.GoldSilverAndCopperToMoney(l.Price.nGold, l.Price.nSilver, l.Price.nCopper)
        local nMoneyR = UIHelper.GoldSilverAndCopperToMoney(r.Price.nGold, r.Price.nSilver, r.Price.nCopper)
        if bUp then
            return nMoneyL < nMoneyR
        else
            return nMoneyL > nMoneyR
        end
    end)

    return tbMyStateData
    -- self.ON_SELL_LOOK_UP_RES(self.nSellTotalCount, self.tbMyStateData)
end

function TradingData.GetMaxItemNum(Item, tbPerItemPrice, nPanelType)
    local nMaxNum = 0
    local AuctionClient = GetAuctionClient()
	if Item then
		local nMaxStackNum = AuctionClient.GetMaxStackNum(Item.dwID) or 0
		nMaxStackNum = math.max(1, nMaxStackNum)
		nMaxNum = nMaxStackNum * MAX_STACK_NUM
		if nPanelType == TRADING_ITEM_PANEL.SELL then
			local hPlayer = GetClientPlayer()
			if not hPlayer then
				return
			end

			local nBagNum
			if Item.nGenre == ITEM_GENRE.BOOK then
				nBagNum = hPlayer.GetItemAmountInPackage(Item.dwTabType, Item.dwIndex, Item.nStackNum, true)
			else
			 	nBagNum = hPlayer.GetItemAmountInPackage(Item.dwTabType, Item.dwIndex, -1, true)
			end
			if nMaxNum > nBagNum then
				nMaxNum = nBagNum
			end
		end

		if self.CheckItemSellLimited(Item) then
			nMaxNum = 1
		end

		if tbPerItemPrice then
			nMaxNum = math.min(math.floor(MAX_PRICE_COPPER / CovertMoneyToCopper(tbPerItemPrice)), nMaxNum)
		end
	end
    return nMaxNum
end

function TradingData.CheckItemSellLimited(Item)
    if Item.nGenre == ITEM_GENRE.EQUIPMENT then
        if Item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or Item.nSub == EQUIPMENT_SUB.RANGE_WEAPON or Item.nSub == EQUIPMENT_SUB.CHEST or
            Item.nSub == EQUIPMENT_SUB.HELM or Item.nSub == EQUIPMENT_SUB.AMULET or Item.nSub == EQUIPMENT_SUB.RING or
            Item.nSub == EQUIPMENT_SUB.WAIST or Item.nSub == EQUIPMENT_SUB.PENDANT or Item.nSub == EQUIPMENT_SUB.PANTS or
            Item.nSub == EQUIPMENT_SUB.BOOTS or Item.nSub == EQUIPMENT_SUB.BANGLE then
            return true
        end
    end
    return false
end


function TradingData.TryBuyItem(nBuyNum, tbPerItemPrice, nTotalCost, tbItem)
    if self._checkBuyInfo(nBuyNum, nTotalCost, tbPerItemPrice) then

        local szMoneyText = UIHelper.GetMoneyText(nTotalCost)
        local szItemName = string.format("<color=%s>", ItemQualityColor[tbItem.nQuality + 1])..UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(tbItem)).."</color>"
        local szContent =  string.format(g_tStrings.AuctionString.STR_BUY_AFFIRM, szMoneyText, nBuyNum, szItemName).."\n"..g_tStrings.AuctionString.STR_BUY_ITEM_TIP

        local scriptView = UIHelper.ShowConfirm(szContent, function ()
            local tbBuyInfo = {}
            tbBuyInfo.nBidNum = nBuyNum
            tbBuyInfo.nPriceGold, tbBuyInfo.nPriceSilver, tbBuyInfo.nPriceCopper = UnpackMoney(tbPerItemPrice)
            tbBuyInfo.dwItemID = tbItem.dwID
            TradingData.BuyItem(tbBuyInfo)
        end, function()end, true)

        if nTotalCost >= 100000000 then
            scriptView:SetButtonCountDown(3)
        end
    end
end

function TradingData.TrySellItem(nBox, nIndex, tbPerItemPrice, nSellNum, nSaveMoney, nInCome, nSaveTime)
    local fnAction = function()
        local tbItem = ItemData.GetItemByPos(nBox, nIndex)
        if self._checkSellOrChangeInfo(tbItem, tbPerItemPrice, nSellNum, nSaveMoney, nInCome) then
            PlaySound(SOUND.UI_SOUND, g_sound.Trade)
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "sell") then
                return
            end
            local tbSellInfo = {}
            tbSellInfo.nLeftHour = nSaveTime
            tbSellInfo.nSaleNum = nSellNum
            tbSellInfo.dwBox = nBox
            tbSellInfo.dwX = nIndex
            tbSellInfo.dwItemID = tbItem.dwID
            tbSellInfo.bResell = 0
            tbSellInfo.nPriceGold, tbSellInfo.nPriceSilver, tbSellInfo.nPriceCopper = UnpackMoney(tbPerItemPrice)
            tbSellInfo.Item = ItemData.GetPlayerItem(g_pClientPlayer, tbSellInfo.dwBox, tbSellInfo.dwX)
            self.UpdateLastSellInfo(tbItem, tbPerItemPrice)

            local nAucGenre = 0
            if tbSellInfo.Item then
                nAucGenre = tbSellInfo.Item.nAucGenre
            end

            if nAucGenre == AUC_GENRE.CLOTH then
                self.ShowSellConfirm(tbSellInfo, function()
                    self.SellItem(tbSellInfo)
                end)
            elseif nAucGenre == AUC_GENRE.CAN_NOT_AUC then
                TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_ITEM_CAN_NOT_AUC)
            else
                self.SellItem(tbSellInfo)
            end
        end
    end
    self.ShowSellMessageBox(fnAction, tbPerItemPrice.nGold)
end

function TradingData.ChangeItemPrice(tbItem, tbPerItemPrice, nSellNum, nSaveMoney, nInCome, nSaveTime, dwSaleID)
    local fnAction = function()
        if self._checkSellOrChangeInfo(tbItem, tbPerItemPrice, nSellNum, nSaveMoney, nInCome) then
            PlaySound(SOUND.UI_SOUND, g_sound.Trade)
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.AUCTION, "sell") then
                return
            end
            local tSellInfo = {}
            tSellInfo.dwSaleID       = dwSaleID
            tSellInfo.nSaleNum       = nSellNum
            tSellInfo.nLeftHour      = nSaveTime
            tSellInfo.PerItemPrice   = tbPerItemPrice
            tSellInfo.nPriceGold     = tbPerItemPrice.nGold
            tSellInfo.nPriceSilver   = tbPerItemPrice.nSilver
            tSellInfo.nPriceCopper   = tbPerItemPrice.nCopper
            tSellInfo.dwTargetID     = self.dwTargetID
            tSellInfo.bResell        = 1
            tSellInfo.dwItemID       = tbItem.dwID
            tSellInfo.Item = tbItem

            self.UpdateLastSellInfo(tbItem, tbPerItemPrice)

            local nAucGenre = 0
            if tSellInfo.Item then
                nAucGenre = tSellInfo.Item.nAucGenre
            end

            if nAucGenre == AUC_GENRE.CLOTH then
                self.ShowSellConfirm(tSellInfo, function()
                    self.SellItem(tSellInfo)
                end)
            else
                self.SellItem(tSellInfo)
            end
        end
    end
    self.ShowSellMessageBox(fnAction, tbPerItemPrice.nGold)
end

function TradingData.ShowSellMessageBox(func, nPriceGold)
    local tPriceYesterday = self.tbPriceData[1].Price
    local tPriceMin = self.tbMinPrice
    local nMaxGold = math.max(tPriceYesterday.nGold, tPriceMin.nGold)
    local nLimitGold = nMaxGold * 0.9
    if nMaxGold > MAX_CONFIRM_GOLD and nPriceGold < nLimitGold then
        UIHelper.ShowConfirm(ParseTextHelper.ParseNormalText(g_tStrings.AuctionString.STR_PRICE_CONFIRM_BEYOND, false), func, nil, true)
    else
        func()
    end
end


function TradingData.ShowSellConfirm(tbSellInfo, funcConfirm)

    local Item = nil
    if tbSellInfo.Item then
        Item = tbSellInfo.Item
    elseif tbSellInfo.dwItemID then
        Item = ItemData.GetItem(tbSellInfo.dwItemID)
    elseif  tbSellInfo.dwBox and tbSellInfo.dwX then
        Item = ItemData.GetPlayerItem(g_pClientPlayer, tbSellInfo.dwBox, tbSellInfo.dwX)
    end

    local szItemName = "物品"
    if Item then
        szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(Item))
    end

    local szMoneyText = UIHelper.GetMoneyText({nGold = tbSellInfo.nPriceGold, nSilver = tbSellInfo.nPriceSilver, nCopper = tbSellInfo.nPriceCopper})
    local szText = string.format(g_tStrings.STR_AUCTION_SELL_SURE, szMoneyText, tbSellInfo.nSaleNum, szItemName)

    local scriptView = UIHelper.ShowConfirm(ParseTextHelper.ParseNormalText(szText, false), funcConfirm, nil, true)
    scriptView:SetButtonCountDown(CD_TIME)
end

function TradingData.GetItemIsFirstSellToday(tbItem)
    local tbSellInfo = self.GetLastSellInfo(tbItem)
    return  #tbSellInfo == 0
end

function TradingData.UpdateLastSellInfo(tbItem, tbPrice)
    if not tbItem then return end
    local tSellInfo = self.GetLastSellInfo(tbItem)
	local nBookRecipieID
	if tbItem.nGenre == ITEM_GENRE.BOOK then
		nBookRecipieID = tbItem.nStackNum
	end

	if not tSellInfo then
        if not self.tbLastSellInfo then
            self.tbLastSellInfo = {}
        end
		table.insert(self.tbLastSellInfo, {dwTabType = tbItem.dwTabType, dwIndex = tbItem.dwIndex, nBookRecipieID = nBookRecipieID, tbPrice = tbPrice})
	else
		tSellInfo.tbPrice = tbPrice
	end
end

function TradingData.GetLastSellInfo(tbItem)
    if not self.tbLastSellInfo or #self.tbLastSellInfo == 0 then return {} end
    for index, tbInfo in ipairs(self.tbLastSellInfo) do
        if tbItem.nGenre ~= ITEM_GENRE.BOOK and tbItem.dwTabType == tbInfo.dwTabType and tbItem.dwIndex == tbInfo.dwIndex  then
			return tbInfo
		elseif tbItem.nGenre == ITEM_GENRE.BOOK and tbItem.dwTabType == tbInfo.dwTabType and tbItem.dwIndex == tbInfo.dwIndex and tbItem.nStackNum == tbInfo.nBookRecipieID then
			return tbInfo
		end
    end
end

function TradingData.GetSellItemCount(tbItem)
    if not tbItem then return 0 end
    local nCount = 1
	if tbItem.nGenre == ITEM_GENRE.EQUIPMENT then
		if tbItem.nSub == EQUIPMENT_SUB.ARROW then
			nCount = tbItem.nCurrentDurability
		end
	elseif tbItem.bCanStack then
		nCount = tbItem.nStackNum
	end
	if tbItem.nSub == EQUIPMENT_SUB.BULLET then
		nCount = tbItem.nMaxDurability
	end
	return nCount
end

function TradingData.GetItemCanSell(nBox, nIndex)
    if not table.concat(ItemData.BoxSet.Bag, nBox) then
        return false
    end

    local tbItem = ItemData.GetItemByPos(nBox, nIndex)
    if tbItem.nAucGenre == AUC_GENRE.CAN_NOT_AUC then
        return false
    end

    if tbItem and (tbItem.bBind or GetItemInfo(tbItem.dwTabType, tbItem.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT) then
        return false
    end

    return true
end

function TradingData.GetAuctionSellingBtn(nBox, nIndex)
    -- 交易行寄卖按钮
    local tbBtn = {
            szName = g_tStrings.STR_AUCTION_TIPS_SELL,
            OnClick = function()
                local hPlayer = g_pClientPlayer
                if not hPlayer then
                    return
                end

                if IsRemotePlayer(hPlayer.dwID) then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_REMOTE_NOT_TIP)
                    return
                end

                local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSellItem)
                if not scriptView then
                    scriptView = UIMgr.Open(VIEW_ID.PanelSellItem, TRADING_ITEM_PANEL.SELL)
                end
                scriptView:InitSell(nBox, nIndex)
            end
        }
    return tbBtn
end

function TradingData.ComputeSaveMoney(nShopPrice, nSellNum, nSaveTime)
    local tSaveCost = PackMoney(0, 0, 0)
    if nShopPrice and nSellNum and nSaveTime then
        tSaveCost = MoneyOptDiv(MoneyOptMult(nShopPrice, nSellNum * nSaveTime * 2), 12 * 5)
	end

	if MoneyOptCmp(tSaveCost, 10) < 0 then
		tSaveCost = PackMoney(0, 0, 10)
	end
	return CovertMoneyToCopper(tSaveCost)
end

function TradingData.ComputeChargeMoney(tbPerItemPrice, nSellNum)
	local tChargeMoney = MoneyOptMult(tbPerItemPrice, nSellNum * CHARGE_RATE)
	if CovertMoneyToCopper(tChargeMoney) > MAX_CHARGE_COPPER then
		tChargeMoney = PackMoney(20000, 0, 0)
	end
	return CovertMoneyToCopper(tChargeMoney)
end


function TradingData.ComputeInCome(tbPerItemPrice, nSellNum, nSaveMoney, nChargeMoney)
    return math.max(0, CovertMoneyToCopper(tbPerItemPrice) * nSellNum - nSaveMoney - nChargeMoney)
end


function TradingData.NewDayUpdate()
    local nCurrentTime = GetCurrentTime()
	if nCurrentTime > nLastPriceRecordValidTime then
		local szYear, szMonth, szDay, szHour = string.match(os.date("%Y-%m-%d-%H", nCurrentTime), "(%d+)-(%d+)-(%d+)-(%d+)")
		local nYear, nMonth, nDay, nHour = tonumber(szYear), tonumber(szMonth), tonumber(szDay), tonumber(szHour)
		nLastPriceRecordValidTime = os.time({day = nDay, month = nMonth, year = nYear, hour = PER_DAY_FRESH_TIME, minute = 0, second = 0})
		if nHour >= PER_DAY_FRESH_TIME then
			nLastPriceRecordValidTime = nLastPriceRecordValidTime + 24 * 60 * 60
		end
		self.tbLastSellInfo = {}
	end
end

function TradingData.GetPriceListMaxPage()
    return self.nPriceTotalCount
end

function TradingData.ClearPriceList()
    self.nPriceTotalCount = nil
    self.tbGoodInfo = nil
end

function TradingData.GetBoxItem()
    local tbItemList = ItemData.GetItemList(ItemData.BoxSet.Bag)

    for index = #tbItemList, 1, -1 do
        local tbItem = ItemData.GetItemByPos(tbItemList[index].nBox, tbItemList[index].nIndex)
        if not tbItem then
            table.remove(tbItemList, index)
        end
        if tbItem and (tbItem.bBind or GetItemInfo(tbItem.dwTabType, tbItem.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT or tbItem.nAucGenre == AUC_GENRE.CAN_NOT_AUC) then
            table.remove(tbItemList, index)
        end
    end
    return tbItemList
end


function TradingData.GetBidData(tbBMData)
    local item        = tbBMData.Item

	local nMyBid      = tbBMData.MyBidPrice
	local nHighestBid = tbBMData.HighestBidPrice
	local nBaseBid    = tbBMData.StartPrice
	local dwPlayerID  = g_pClientPlayer.dwID

	if dwPlayerID == tbBMData.HighestBidderID then
		Storage.TradingHouse.tbBidCache[tbBMData.ID] = nil
	end
	local bOrgBid = (Storage.TradingHouse.tbBidCache and Storage.TradingHouse.tbBidCache[tbBMData.ID]) or false

	if tbBMData.HighestBidderID == 0 then
		nHighestBid = nBaseBid
	end
	return nHighestBid * 10000, nMyBid * 10000, nBaseBid * 10000, bOrgBid
end

function TradingData.GetBidState(tbBMData, nCamp, bWorldBossActivity, bNeuterActivity)
	local szState1, szState2 = "Hide", ""
	local szHighestBidder = tbBMData.HighestBidderName
	local nHighestBid, nMyBid = self.GetBidData(tbBMData)

    if nCamp ~= BLACK_MARKET_TYPE.NEUTRAL then--限时拍卖
        if not g_pClientPlayer or (not bNeuterActivity and not bWorldBossActivity and nCamp ~= CampToBlackMarketType[g_pClientPlayer.nCamp]) then
            return szState1, szState2
        end
    end

	if nMyBid > 0 then
		if szHighestBidder ~= g_pClientPlayer.szName then
			szState1 = "CanCancel"
		end
		szState2 = "AddMoney"
	else
		szState2 = "FirstBid"
	end
	return szState1, szState2
end

function TradingData.GetMinBidPrice(tbBMData)
    if tbBMData.BidderCount == 0 then
		return tbBMData.StartPrice * 10000
	end

	if tbBMData.InDelayBid == 1 then
		if tbBMData.HighestBidderID ==  g_pClientPlayer.dwID then
			return math.ceil(tbBMData.StartPrice * DELAY_BID_ADD_MONEY_PERCENTAGE) * 10000
		else
			return math.max(math.ceil(tbBMData.StartPrice * DELAY_BID_ADD_MONEY_PERCENTAGE), tbBMData.HighestBidPrice + 100 - tbBMData.MyBidPrice) * 10000
		end
	else
		return (tbBMData.HighestBidPrice + 100 - tbBMData.MyBidPrice) * 10000
	end
end

function TradingData.FormatAuctionLeftTime(nTime)
    if nTime == 0 then
        return g_tStrings.AuctionString.STR_ITEM_VOID
    end
    if nTime < NEAR_DUE_TIME then
        return g_tStrings.AuctionString.STR_AUCTION_NEAR_DUE
    end
    local szText = ""
    local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime, false)
    if nH and nH > 0 then
        if (nM and nM > 0) or (nS and nS > 0) then
            nH = nH + 1
        end
        szText = szText .. nH .. g_tStrings.STR_BUFF_H_TIME_H
    else
        nM = nM or 0
        nS = nS or 0
        if nM == 0 and nS == 0 then
            return szText
        end

        if nS > 0 then
            nM = nM + 1
        end

        if nM >= 60 then
            szText = szText .. math.ceil(nM / 60) .. g_tStrings.STR_BUFF_H_TIME_H
        else
            szText = szText .. nM .. g_tStrings.STR_BUFF_H_TIME_M
        end
    end
    return szText
end

function TradingData.GetAuctionTypeName(Item)
    if not Item.nAucGenre then
		return ItemData.GetEquipTypeName(Item)
	end
	for szName, t in pairs(tSearchSort) do
		if t.nSortID == Item.nAucGenre then
			for szSubName, nID in pairs(t.tSubSort) do
				if nID == Item.nAucSub then
					return szSubName
				end
			end
		end
	end
end

function TradingData.SetDefaultBMData(tbData, nTime)
    self.tbData, self.nTime = tbData, nTime
end

function TradingData.GetDefaultBMData()
    return self.tbData, self.nTime
end

--当前BMLookUP请求的是哪个界面：①、NEUTRAL私货②、Good：阵营拍卖浩气盟③、Evil：阵营拍卖恶人谷
function TradingData.SetBidCache(nSaleID, nValue)
    if nSaleID then
        Storage.TradingHouse.tbBidCache[nSaleID] = nValue
    else
        Storage.TradingHouse.tbBidCache = {}
    end
    Storage.TradingHouse.Dirty()
end

function TradingData.SetBlackMarketEndTime(nEndTime)
    Storage.TradingHouse.nLastEndTime = nEndTime
    Storage.TradingHouse.Dirty()
end

function TradingData.GetHighestID()
    return self.nHighestID
end

function TradingData.CombineLogicDataWithTableData(tAllItemData, nCamp)
    if not nCamp or nCamp == BLACK_MARKET_TYPE.NEUTRAL then return end --私货不用处理
    local tAllTableData = Table_GetCampAuctionInfo()
	for k, tItemData in ipairs(tAllItemData) do
		local item = tItemData.Item
		local nItemID  = item.dwID
		local nItemTabType = item.dwTabType
		local nItemIndex = item.dwIndex
		local szKey = nItemTabType .. nItemIndex

		local tTableData = tAllTableData[szKey]
		if tTableData then
			tItemData.nRareness = tTableData.nRareness
		else
			tItemData.nRareness = 0
		end
	end
end

function TradingData.OpenSourceTradeSearchPanel(szLinkArg)
    local szItemType, szItemIndex = szLinkArg:match("(%w+)/(%w+)")
	local dwItemType = tonumber(szItemType)
	local dwItemIndex = tonumber(szItemIndex)
    local ItemInfo = GetItemInfo(dwItemType, dwItemIndex)
    local szName = UIHelper.GBKToUTF8(ItemInfo.szName)
    -- TradingData.InitTradingHouse()
    if UIMgr.GetView(VIEW_ID.PanelSearchItem) then
        TipsHelper.ShowNormalTip("已跳转至交易行")
        return
    end

    TradingData.InitData()
    UIMgr.Open(VIEW_ID.PanelSearchItem, szName)
end

function TradingData.OpenSourceTradeSearchPanelWithName(szName)
    -- TradingData.InitTradingHouse()
    if UIMgr.GetView(VIEW_ID.PanelSearchItem) then
        TipsHelper.ShowNormalTip("已跳转至交易行")
        return
    end

    TradingData.InitData()
    UIMgr.Open(VIEW_ID.PanelSearchItem, szName)
end

-----------------------------------------------------------------内部辅助函数---------------------------------------------------------
function TradingData._checkColdTime(nRequestID)
    local nTime = GetTickCount()
    if not self.tbNextApplyTime[nRequestID] or nTime >= self.tbNextApplyTime[nRequestID] then
        self.tbNextApplyTime[nRequestID] = nTime + 1000
		return true
    end
    return false
end


function TradingData._registerEvent()
    Event.Reg(self, "AUCTION_LOOKUP_RESPOND", function(nRespondCode, nApplyType)
        local nRespondCode = arg0
        if nRespondCode ~= AUCTION_RESPOND_CODE.SUCCEED then return end
        local nApplyType = arg1
        local AuctionClient = GetAuctionClient()
        local nTotalCount, tItemInfo = AuctionClient.GetLookupResult(nApplyType)
        if nApplyType == AUCTION_ITEM_LIST_TYPE.NORMAL_LOOK_UP then
            self.ON_NORMAL_LOOK_UP_RES(nTotalCount, tItemInfo)
        elseif nApplyType == AUCTION_ITEM_LIST_TYPE.SELL_LOOK_UP then
            self.ON_SELL_LOOK_UP_RES(nTotalCount, tItemInfo)
        elseif nApplyType == AUCTION_ITEM_LIST_TYPE.PRICE_LOOK_UP then
            if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
				self.ON_PRICE_LOOK_UP(nTotalCount, tItemInfo)
			end
        elseif nApplyType == AUCTION_ITEM_LIST_TYPE.AVG_LOOK_UP then
			if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
                local nLength, tbPriceData, tbMinPrice, tbMaxPrice = AuctionClient.GetAvgPricesResult()
                self.ON_AVG_LOOK_UP_RES(nLength, tbPriceData, tbMinPrice, tbMaxPrice)
			end
        elseif nApplyType == AUCTION_ITEM_LIST_TYPE.DETAIL_LOOK_UP then
            if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
                self.ON_DETAIL_LOOK_UP(nTotalCount, tItemInfo)
			end
        end
    end)


    Event.Reg(self, "AUCTION_CANCEL_RESPOND", function(nRespondCode)
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then--下架成功
            local nTotalCount, tItemInfo = GetAuctionClient().GetLookupResult(AUCTION_ITEM_LIST_TYPE.SELL_LOOK_UP)
            self.ON_SELL_LOOK_UP_RES(nTotalCount, tItemInfo)
			Event.Dispatch(EventType.ON_AUCTION_CANCEL_RESPOND)
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_AUCTION_CANCEL_SUCCESS)
        else
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionRespond[nRespondCode])
		end
    end)

    Event.Reg(self, "AUCTION_SELL_RESPOND", function(nRespondCode)
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_AUCTION_SELL_SUCCESS)
            self.ON_AUCTION_SELL_SUCCESS()
            FireEvent("BUY_AUCTION_ITEM")
        else
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionRespond[arg0])
		end
        Event.Dispatch(EventType.ON_AUCTION_SELL_RESPOND, nRespondCode == AUCTION_RESPOND_CODE.SUCCEED)
    end)

    Event.Reg(self, "AUCTION_BID_RESPOND", function(nRespondCode)
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then
            FireEvent("SELL_AUCTION_ITEM")
			-- self.ApplyPriceLookUp()
            self.ON_AUCTION_BID_RESPOND()
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_AUCTION_BID_SUCCESS)
            self.nLastBuyTime = GetTickCount()
        else
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionRespond[arg0])
		end
        Event.Dispatch(EventType.ON_AUCTION_BUY_RESPOND, nRespondCode == AUCTION_RESPOND_CODE.SUCCEED)
    end)

    Event.Reg(self, "AUCTION_ERROR_CODE_NOTIFY", function()
        if arg0 and g_tStrings.AuctionString.tAuctionErrorCode[arg0] then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionErrorCode[arg0])
		end
    end)



    -- Event.Reg(self, "BM_LOOKUP_RESPOND", function()
    --     self.bCanApplyBm_LookUp= true
    --     if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
    --         local tbData, nEndTime = self.GetBMDataList()
    --         self.CombineLogicDataWithTableData(tbData)
    --         self.SetDefaultBMData(tbData, nEndTime)
    --         Event.Dispatch(EventType.ON_BM_LOOKUP_SUCCEED, tbData, nEndTime)
    --     elseif arg0 == AUCTION_RESPOND_CODE.BM_CLOSEID then

    --     else

	-- 	end
    -- end)

    -- Event.Reg(self, "BM_BID_RESPOND", function()
    --     if arg0 == AUCTION_RESPOND_CODE.SUCCEED then
    --         TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BLACK_MARKET_BID_SUCCESS)
    --         local nSellID = arg1
	-- 		local tItem = self.GetBidItem(nSellID)
	-- 		if tItem then
	-- 			local szName = g_pClientPlayer.szName
	-- 			if szName == tItem.HighestBidderName then
	-- 				self.tBidCache[nSellID] = nil
	-- 			else
	-- 				self.tBidCache[nSellID] = true
	-- 			end
	-- 		end
    --     elseif arg0 == AUCTION_RESPOND_CODE.PRICE_TOO_LOW then
    --         TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BID_LOW)
    --     else
    --         TipsHelper.ShowNormalTip(g_tStrings.AuctionString.tAuctionRespond[arg0])
	-- 	end

    --     self.BMLookup()
    -- end)

    -- Event.Reg(self, "BM_BID_CANCEL_RESPOND", function()
    --     if arg1 then
	-- 		self.tBidCache[arg1] = nil
	-- 	end
    --     self.BMLookup()
    -- end)


    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self._checkShowCommandAuctionBtn()
        self.nCheckShowCABtnTimer = Timer.AddCycle(self, 10, function()
            self._checkShowCommandAuctionBtn()
        end)
        if GetGSCurrentTime() > Storage.TradingHouse.nLastEndTime then
            self.SetBidCache(nil, nil)
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        Timer.DelTimer(self, self.nCheckShowCABtnTimer)
        self.ClearActivityList()
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        self._checkShowCommandAuctionBtn()
    end)
end

function TradingData._checkShowCommandAuctionBtn()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local nActivityID1 = not IsRemotePlayer(hPlayer.dwID) and self.IsCommandAuctionRelativeActivityOpen(false)
    local nActivityID2 = not IsRemotePlayer(hPlayer.dwID) and self.IsCommandAuctionRelativeActivityOpen(true)
    if nActivityID1 then
        self.AddActivityID(nActivityID1)
    end
    if nActivityID2 then
        self.AddActivityID(nActivityID2)
    end

    if not nActivityID1 or not nActivityID2  then
        self.RemoveActivityID()
    end
end

--请求最先开启的活动的倒计时作为气泡倒计时
function TradingData.BMLookUpCampData()
    local nActivityID = self.tbActivityList[1]
    if not nActivityID then return end
    local nCamp = nil
    if nActivityID == nNeutralActivityID then
        nCamp = BLACK_MARKET_TYPE.ACTIVITY
    else
        nCamp = g_pClientPlayer.nCamp
    end
    self.BMLookup(nCamp)
    return nCamp
end

function TradingData.GetActivityList()
    return self.tbActivityList
end

function TradingData.AddActivityID(nActivityID)
    if not self.tbActivityList then self.tbActivityList = {} end
    if not table.contain_value(self.tbActivityList, nActivityID) then
        table.insert(self.tbActivityList, nActivityID)
        Event.Dispatch(EventType.OnAuctionStateChanged)
        self.PushBubbleMsg()
    end
end

function TradingData.RemoveActivityID()
    if not self.tbActivityList then return end
    for nIndex, dwActivityID in ipairs(self.tbActivityList) do
        if not (IsActivityOn(dwActivityID) or UI_IsActivityOn(dwActivityID)) then
            table.remove(self.tbActivityList, nIndex)
            Event.Dispatch(EventType.OnAuctionStateChanged)
            break
        end
    end
    if #self.tbActivityList == 0 then
        self.RemoveBubbleMsg()
    end
end

function TradingData.ClearActivityList()
    self.tbActivityList = {}
    self.RemoveBubbleMsg()
end

function TradingData.RemoveBubbleMsg()
    if self.bBubbleMsgExist then
        self.bBubbleMsgExist = false
        BubbleMsgData.RemoveMsg("CommandAuctionOpening")
    end
end

function TradingData.PushBubbleMsg()
    if self.bBubbleMsgExist then return end
    BubbleMsgData.PushMsgWithType("CommandAuctionOpening", {
        nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
        szContent = function ()
            local szContent = "当前可以开启阵营拍卖"
            return szContent, 0.5
        end,
        szAction = function ()
            self.InitLimitAuction(0)
        end,
    })
    self.bBubbleMsgExist = true
end

function TradingData.GetBidItem(nSellID, nCamp)
	local nCount, t = GetAuctionClient().GetBMLookupResult(nCamp)
	for k, v in ipairs(t) do
		if v.ID == nSellID then
			return v
		end
	end
end

function TradingData.GetBMDataList(nCamp, nHighestID, bSort)
    local AuctionClient = GetAuctionClient()
    local nCount, tbData = AuctionClient.GetBMLookupResult(nCamp)
    local nEndTime = AuctionClient.GetBMOverTime(nCamp)
    local nIndex = 1
    nCount = 0
    for k, v in ipairs(tbData) do
        if v.BidderCount > nCount or
            (nHighestID and nHighestID == v.ID and v.BidderCount == nCount) then
            nCount = v.BidderCount
            nIndex = k
        end
    end

    if nIndex and tbData[nIndex] then
        local tFind = tbData[nIndex]
        nHighestID = tFind.ID
        table.remove(tbData, nIndex)
        table.insert(tbData, 1, tFind)
    end
    self.CombineLogicDataWithTableData(tbData, nCamp)

    --如果是世界拍卖或活动拍卖，排序
    if bSort then
        table.sort(tbData, function(left, right)
            if left.nRareness ~= right.nRareness then
                return left.nRareness > right.nRareness
            else
                local _, _, nLeftStartMoney = self.GetBidData(left)
                local _, _, nRightStartMoney = self.GetBidData(right)
                if nLeftStartMoney ~= nRightStartMoney then
                    return nLeftStartMoney > nRightStartMoney
                end
            end
        end)
    end

    return tbData, nEndTime, nHighestID
end

function TradingData._createSellItemInfo(tbData)
    local Info 			= {}
    Info.dwSaleID 		= tbData.ID
    Info.Num  			= tbData.StackNum
    Info.nLeftHour  	= tbData.LastDurationTime
    Info.PerItemPrice	= tbData.Price
    Info.nPriceGold 	= tbData.Price.nGold
    Info.nPriceSilver 	= tbData.Price.nSilver
    Info.nPriceCopper 	= tbData.Price.nCopper
    Info.dwTargetID 	= self.dwTargetID
    Info.bResell 		= 1
    Info.dwItemID 		= tbData.Item.dwID
    Info.Item           = tbData.Item
    return Info
end



function TradingData._checkBuyInfo(nBuyNum, nTotalCost, tbPerItemPrice)
    if not nBuyNum or nBuyNum <= 0 then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_BUY_NUM_ERROR)
        return false
    end

    local hPlayer = g_pClientPlayer
	if not hPlayer then return end
    local tMoney = hPlayer.GetMoney()

	if CovertMoneyToCopper(tMoney) < nTotalCost then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_INCOME_MONEY_ERROR[-1])
		return false
	end


    local nPerItemPrice = CovertMoneyToCopper(tbPerItemPrice)
	if nPerItemPrice <= 0 then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_PERITEM_PRICE_ERROR)
		return false
	end
	return true
end


function TradingData._checkSellOrChangeInfo(tbItem, tbPerItemPrice, nSellNum, nSaveMoney, nInCome)
    if not self._checkIsValidSellNum(nSellNum) then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_SELL_NUM_ERROR)
        return false
    end

    if not self._checkIsEnoughSaveMoney(nSaveMoney) then
        -- View.UpdateSaveMoney()
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_CHARGE_MONEY_ERROR)
        return false
    end

    local nResCode = self._checkValidInCome(tbItem, tbPerItemPrice, nSellNum, nInCome)
	if nResCode < 0 then
        -- View.UpdateInComeMoney(DataModel.tSaveCost)
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_INCOME_MONEY_ERROR[nResCode])
        return false
    end

    local nPerItemPrice = CovertMoneyToCopper(tbPerItemPrice)
	if nPerItemPrice <= 0 then
        TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_PERITEM_PRICE_ERROR)
		return false
	end

    return true

end

function TradingData._checkIsEnoughSaveMoney(nSaveMoney)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
	local tMoney = hPlayer.GetMoney()
    local nMoney = CovertMoneyToCopper(tMoney)
	return nMoney >= nSaveMoney
end

function TradingData._checkIsValidSellNum(nSellNum)
    return  nSellNum and nSellNum > 0
end

function TradingData._checkValidInCome(tbItem, tbPerItemPrice, nSellNum, nInCome)
    local nResCode = 1
    if tbItem then
        local nPerItemCopper = CovertMoneyToCopper(tbPerItemPrice)
        local nNum = nSellNum
        local nSellCopper = nPerItemCopper * nNum

        local nValidNum = math.max(nNum, 1)
        if CovertMoneyToCopper(MoneyOptDiv(MAX_PRICE, nValidNum)) < nPerItemCopper then
            nResCode = -3
            return nResCode
        end

        if nInCome < 0 then
            nResCode = 0
        end

        if nSellCopper > MAX_PRICE_COPPER then
            nResCode = -2
        end
    end
    return nResCode
end

--是否在CD中
function TradingData._checkCanApplyData(nRequestID)
    local bOk = false
    local player = GetClientPlayer()
    local nCD = 0
    if player then
        if tLookupCDID[nRequestID] then
            local nLeftCooldown, nCDCount = player.GetCDLeft(tLookupCDID[nRequestID])
            nCD = nLeftCooldown / GLOBAL.GAME_FPS
            if nLeftCooldown == 0 then
                return true, nCD
            end
        end
    end

    TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_CD_ERROR)
    return false, nCD
end

