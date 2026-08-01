PayData = PayData or {}

local self = PayData

PayData.RechargeTypeEnum = {
    szCoin = "通宝",
    szPointCard = "点卡",
    szMonthCard = "月卡",
    szBuyItemWithRMB = "实物订单直购",
}

--- 首次充值对应类别时赠送的描述
PayData.tbTypeToFirstRechargePresentDescription = {}
PayData.tbTypeToFirstRechargePresentDescription[PayData.RechargeTypeEnum.szCoin] = ""
PayData.tbTypeToFirstRechargePresentDescription[PayData.RechargeTypeEnum.szPointCard] = "首次充值游戏时长，可额外赠送<color=#f0dc82>2000</color>分钟游戏时长，每个账号仅赠送1次。"
PayData.tbTypeToFirstRechargePresentDescription[PayData.RechargeTypeEnum.szMonthCard] = "首次充值游戏时长，可额外赠送<color=#f0dc82>3</color>天游戏时长，每个账号仅赠送1次。"

---@class PayIntroductionInfo
---@field szTitleImgPath string 标题图路径
---@field szRichText string 富文本内容

--- 充值类别的介绍信息
--- @type table<string, PayIntroductionInfo>
PayData.tbTypeToRechargeTypeIntroduction = {
    [PayData.RechargeTypeEnum.szCoin] = {
        szTitleImgPath = "UIAtlas2_Shopping_ShoppingTopUp_img_tongbao.png",
        szRichText = [[
            <color=#e5e5e5>1.单价：1元=100通宝
2.可用于在</color><color=#ffe26e>外观商城消费、增值服务消费</color><color=#e5e5e5>（如角色改名、角色转服、角色分离）等</color>
        ]],
    },
    [PayData.RechargeTypeEnum.szPointCard] = {
        szTitleImgPath = "UIAtlas2_Shopping_ShoppingTopUp_img_dianka.png",
        szRichText = [[
            <color=#e5e5e5>1.点卡服务按秒计算，每秒为1点。
2.单价：</color><color=#ffe26e>1元=8000点（秒）</color>
            <color=#e5e5e5>3.计费方式：将以侠士在线时间计算，</color><color=#ffe26e>账号在线每1秒消耗1点</color><color=#e5e5e5>（停留在登录界面或角色选择界面不计费）</color>
            <color=#ffe26e>【计费顺序】</color><color=#e5e5e5>
现有充值时长计费逻辑顺序为：</color><color=#ffe26e>先扣月卡，再扣点卡</color>
        ]],
    },
    [PayData.RechargeTypeEnum.szMonthCard] = {
        szTitleImgPath = "UIAtlas2_Shopping_ShoppingTopUp_img_yueka.png",
        szRichText = [[
            <color=#e5e5e5>1.月卡服务按天（24小时）计算
2.单价：</color><color=#ffe26e>2元/天</color>
            <color=#e5e5e5>3.计费方式：</color><color=#ffe26e>将以侠士的充值时间作为起点开始计算消耗，无论您是否登录游戏</color>

            <color=#ffe26e>【计费顺序】</color><color=#e5e5e5>
现有充值时长计费逻辑顺序为：</color><color=#ffe26e>先扣月卡，再扣点卡</color>
        ]],
    },
}


---@class RechargeProductInfo 充值商品信息（通宝/点卡/月卡）
---@field szType string 商品类别，用于判断在哪类标签中展示：通宝/点卡/月卡
---@field szProductId string 商品ID，如果西瓜后台有商品配置则必须保持一致，必填
---@field nPrice number 价格，单位：元，必填
---@field szProductName string 游戏内商品名称，且必须为UTF-8，可支持中文，但不能包含特殊字符，如 # " & / ? $ ^ *:) \ < > , = 回车 换行 等，必填
---@field szProductDesc string 商品描述，其编码和格式要求与 product_name 保持一致，可为空
---@field nGainCoin number 购买获得的通宝数目，仅通宝商品需要填写，用于快速充值功能
---@field szIconPath string 图标路径，相对于mui目录
---@field szPresentTips string 赠送部分的描述，用于显示在购买界面上

---@class BattlePassRMBProductInfo 战令直购商品信息
---@field szType string 商品类别，仅方便区分
---@field szProductId string 商品ID，如果西瓜后台有商品配置则必须保持一致，必填
---@field nPrice number 价格，单位：元，必填
---@field szProductName string 游戏内商品名称，且必须为UTF-8，可支持中文，但不能包含特殊字符，如 # " & / ? $ ^ *:) \ < > , = 回车 换行 等，必填
---@field szProductDesc string 商品描述，其编码和格式要求与 product_name 保持一致，可为空
---@field dwItemType number 该商品关联的奖励道具type
---@field dwItemIndex number 该商品关联的奖励道具index

---@class RMBProductInfo 直购商品信息
---@field szType string 商品类别，仅方便区分
---@field szProductId string 商品ID，如果西瓜后台有商品配置则必须保持一致，必填
---@field nPrice number 价格，单位：元，必填
---@field szProductName string 游戏内商品名称，且必须为UTF-8，可支持中文，但不能包含特殊字符，如 # " & / ? $ ^ *:) \ < > , = 回车 换行 等，必填
---@field szProductDesc string 商品描述，其编码和格式要求与 product_name 保持一致，可为空
---@field dwItemType number 该商品关联的奖励道具type
---@field dwItemIndex number 该商品关联的奖励道具index
---@field dwGoodsID number 对应的商品ID，对应配置表 settings/RewardsShop.tab

--- 自定义充值的类型枚举
PayData.tCustomRechargeMode = {
    --- 自定义充值
    Custom = 1,
    --- 补差价
    BuChaJia = 2,
}

--- 自定义充值商品配置
---@type RechargeProductInfo
PayData.tCustomRechargeProduct = { szType = "通宝", szProductId = "com.jx3wj.Coin.20240902coin1000_10", nPrice = 10, szProductName = "1000通宝", szProductDesc="10元买1000通宝", nGainCoin = 1000, szIconPath = "", szPresentTips="" }

--- 补差价商品配置
---@type RechargeProductInfo
PayData.tBuChaJiaRechargeProduct = { szType = "通宝", szProductId = "com.jx3wj.Coin.20240902coin100_1", nPrice = 1, szProductName = "100通宝", szProductDesc="1元买100通宝", nGainCoin = 100, szIconPath = "", szPresentTips="" }

--- 安卓和windows的充值列表
---@type RechargeProductInfo[]
local tProductAndroidOrWindows = {
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin1500_15", nPrice = 15, szProductName = "1500通宝", szProductDesc="15元买1500通宝", nGainCoin = 1500, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift08.png", szPresentTips="" },
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin3000_30", nPrice = 30, szProductName = "3000通宝", szProductDesc="30元买3000通宝", nGainCoin = 3000, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift04.png", szPresentTips="" },
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin5000_50", nPrice = 50, szProductName = "5000通宝", szProductDesc="50元买5000通宝", nGainCoin = 5000, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift02.png", szPresentTips="" },
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin10000_100", nPrice = 100, szProductName = "10000通宝", szProductDesc="100元买10000通宝", nGainCoin = 10000, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift09.png", szPresentTips="" },
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin30000_300", nPrice = 300, szProductName = "30000通宝", szProductDesc="300元买30000通宝", nGainCoin = 30000, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift01.png", szPresentTips="" },
    { szType = "通宝", szProductId = "com.jx3ht.Coin.20240201coin50000_500", nPrice = 500, szProductName = "50000通宝", szProductDesc="500元买50000通宝", nGainCoin = 50000, szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift10.png", szPresentTips="" },

    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint2000_15", nPrice = 15, szProductName = "2000分钟", szProductDesc="15元买2000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint4000_30", nPrice = 30, szProductName = "4000分钟", szProductDesc="30元买4000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint8000_60", nPrice = 60, szProductName = "8000分钟", szProductDesc="60元买8000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint16600_120", nPrice = 120, szProductName = "16000分钟", szProductDesc="120元买16600分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送600分钟" },
    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint24900_180", nPrice = 180, szProductName = "24000分钟", szProductDesc="180元买24900分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送900分钟" },
    { szType = "点卡", szProductId = "com.jx3ht.TP.20240201TimePoint49800_360", nPrice = 360, szProductName = "48000分钟", szProductDesc="360元买49800分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送1800分钟" },

    { szType = "月卡", szProductId = "com.jx3ht.MC.20240201MonthCard30_60", nPrice = 60, szProductName = "30天", szProductDesc="60元买30天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.MC.20240201MonthCard60_120", nPrice = 120, szProductName = "60天", szProductDesc="120元买60天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.MC.20240201MonthCard90_180", nPrice = 180, szProductName = "90天", szProductDesc="180元买90天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.MC.20240201MonthCard180_360", nPrice = 360, szProductName = "180天", szProductDesc="360元买180天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
}

--- iOS的充值列表
---@type RechargeProductInfo[]
local tProductIOS = {
    { szType = "点卡", szProductId = "com.jx3wj.ios.20240104timepoint2000_15", szCloudIOSProductId = "com.jx3wj.ios.forcloud.timepoint2000_15", nPrice = 15, szProductName = "2000分钟", szProductDesc="15元买2000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3wj.ios.20240104timepoint4000_30", szCloudIOSProductId = "com.jx3wj.ios.forcloud.timepoint4000_30", nPrice = 30, szProductName = "4000分钟", szProductDesc="30元买4000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3wj.ios.20240104timepoint8000_60", szCloudIOSProductId = "com.jx3wj.ios.forcloud.timepoint8000_60", nPrice = 60, szProductName = "8000分钟", szProductDesc="60元买8000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
}

-- 抖音联运的充值列表
---@type RechargeProductInfo[]
local tProductDYLY = {
    { szType = "点卡", szProductId = "com.jx3wj.douyin.20240104timepoint2000_15", nPrice = 15, szProductName = "2000分钟", szProductDesc="15元买2000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3wj.douyin.20240104timepoint4000_30", nPrice = 30, szProductName = "4000分钟", szProductDesc="30元买4000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3wj.douyin.20240104timepoint8000_60", nPrice = 60, szProductName = "8000分钟", szProductDesc="60元买8000分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="" },
    { szType = "点卡", szProductId = "com.jx3ht.douyin.20240616TimePoint16600_120", nPrice = 120, szProductName = "16000分钟", szProductDesc="120元买16600分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送600分钟" },
    { szType = "点卡", szProductId = "com.jx3ht.douyin.20240616TimePoint24900_180", nPrice = 180, szProductName = "24000分钟", szProductDesc="180元买24900分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送900分钟" },
    { szType = "点卡", szProductId = "com.jx3ht.douyin.20240616TimePoint49800_360", nPrice = 360, szProductName = "48000分钟", szProductDesc="360元买49800分钟", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift07_1.png", szPresentTips="赠送1800分钟" },

    { szType = "月卡", szProductId = "com.jx3ht.douyin.20240616MonthCard30_60", nPrice = 60, szProductName = "30天", szProductDesc="60元买30天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.douyin.20240616MonthCard60_120", nPrice = 120, szProductName = "60天", szProductDesc="120元买60天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.douyin.20240616MonthCard90_180", nPrice = 180, szProductName = "90天", szProductDesc="180元买90天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
    { szType = "月卡", szProductId = "com.jx3ht.douyin.20240616MonthCard180_360", nPrice = 360, szProductName = "180天", szProductDesc="360元买180天", szIconPath = "UIAtlas2_Shopping_ShoppingTopUp_img_gift06_1.png", szPresentTips="" },
}

--- 战令直购信息，需要按 HuaELouData 中相关说明规则去配置，具体可以搜索： 对于直购版本
---@type BattlePassRMBProductInfo[]
local tBattlePassProductBuyItemWithRMB = {
    --{ szType = "实物订单直购", szProductId = "com.jx3wj.ios.20240104battlepass_188", nPrice = 188, szProductName = "江湖行记", szProductDesc="江湖行记", dwItemType = 5, dwItemIndex = 66440 },
    { szType = "实物订单直购", szProductId = "com.jx3wj.ios.20240425battlepass_58", szCloudIOSProductId = "com.jx3wj.ios.forcloud.battlepass_58", nPrice = 58, szProductName = "豪侠秘礼", szProductDesc="豪侠秘礼", dwItemType = 5, dwItemIndex = 85954 },
    { szType = "实物订单直购", szProductId = "com.jx3wj.ios.20240425battlepass_100", szCloudIOSProductId = "com.jx3wj.ios.forcloud.battlepass_100", nPrice = 100, szProductName = "豪侠盛馈", szProductDesc="豪侠盛馈", dwItemType = 5, dwItemIndex = 85955 },
    { szType = "实物订单直购", szProductId = "com.jx3wj.ios.20240425battlepass_158", szCloudIOSProductId = "com.jx3wj.ios.forcloud.battlepass_158", nPrice = 158, szProductName = "豪侠盛馈", szProductDesc="豪侠盛馈", dwItemType = 5, dwItemIndex = 85956 },
}

--- 其他直购条目，必须要填写商品表（settings/RewardsShop.tab）中对应的商品的道具type和index，从而将游戏商品与这里的西瓜商品关联起来，需要确保该道具是实物道具（IsReal字段为1）
---@type RMBProductInfo[]
local tProductBuyItemWithRMB = {
    { szType = "实物订单直购", szProductId = "com.jx3wj.ios.20240830gift_48", szCloudIOSProductId = "com.jx3wj.ios.forcloud.20240830gift_48", nPrice = 48, szProductName = "惊喜福袋", szProductDesc="惊喜福袋", dwItemType = 5, dwItemIndex = 66517, dwGoodsID = 5285, szMapProductId = "com.jx3wj.ios.20240830gift_48",  },
}

function PayData.CheckSwitchProductId()
    local tbAlliOSProduct = {tProductIOS, tBattlePassProductBuyItemWithRMB, tProductBuyItemWithRMB}
    if Platform.WLCloudIsIos() then
        for _, tbProductList in ipairs(tbAlliOSProduct) do
            for _, v in ipairs(tbProductList) do
                if not v.szDefaultProductId then
                    v.szDefaultProductId = v.szProductId
                end
                v.szProductId = v.szCloudIOSProductId
            end
        end
    else
        for _, tbProductList in ipairs(tbAlliOSProduct) do
            for _, v in ipairs(tbProductList) do
                if v.szDefaultProductId then
                    v.szProductId = v.szDefaultProductId
                end
            end
        end
    end
end

Event.Reg(PayData, EventType.XGSDK_OnLoginSuccess, function()
    PayData.CheckSwitchProductId()
end)

---@return RechargeProductInfo[]
function PayData.GetAllPayConfig()
    local tProduct

    if Platform.IsWindows() or Platform.IsMac() then
        if Platform.WLCloudIsIos() then
            tProduct = tProductIOS
        else
            tProduct = tProductAndroidOrWindows
        end
    elseif Platform.IsAndroid() then
        if Channel.Is_dylianyunyun() then
            tProduct = tProductDYLY
        else
            tProduct = tProductAndroidOrWindows
        end
    elseif Platform.IsIos() then
        tProduct = tProductIOS
    else
        tProduct = {}
    end

    return tProduct
end

---@return RechargeProductInfo[]
function PayData.GetAllPayConfigOfType(szType)
    local tProduct = {}

    for _, tRechargeConfig in ipairs(PayData.GetAllPayConfig()) do
        if tRechargeConfig.szType == szType then
            table.insert(tProduct, tRechargeConfig)
        end
    end

    return tProduct
end

---@return RechargeProductInfo | BattlePassRMBProductInfo | RMBProductInfo
function PayData.GetPayConfig(szProductId)
    for _, cfg in ipairs(PayData.GetAllPayConfig()) do
        if cfg.szProductId == szProductId then
            return cfg
        end
    end

    -- 特殊处理下不展示的直购的商品
    for _, tOtherProductList in ipairs({tBattlePassProductBuyItemWithRMB, tProductBuyItemWithRMB}) do
        for _, cfg in ipairs(tOtherProductList) do
            if cfg.szProductId == szProductId then
                return cfg
            end
        end
    end

    -- 其余一些特定用途的商品，如自定义充值、补差价
    for _, cfg in ipairs({PayData.tCustomRechargeProduct, PayData.tBuChaJiaRechargeProduct}) do
        if cfg.szProductId == szProductId then
            return cfg
        end
    end

    return nil
end

---@return string
function PayData.GetRMBItemProductID(dwItemType, dwItemIndex)
    for _, tOtherProductList in ipairs({tBattlePassProductBuyItemWithRMB, tProductBuyItemWithRMB}) do
        for _, cfg in ipairs(tOtherProductList) do
            if cfg.dwItemType == dwItemType and cfg.dwItemIndex == dwItemIndex then
                return cfg.szProductId
            end
        end
    end

    return ""
end

---@return BattlePassRMBProductInfo
function PayData.GetBattlePassRMBItemProductID(dwItemType, dwItemIndex)
    for _, cfg in ipairs(tBattlePassProductBuyItemWithRMB) do
        if cfg.dwItemType == dwItemType and cfg.dwItemIndex == dwItemIndex then
            return cfg.szProductId
        end
    end

    return ""
end

---@return RMBProductInfo
function PayData.GetRMBPayConfig(szProductId)
    for _, cfg in ipairs(tProductBuyItemWithRMB) do
        if cfg.szProductId == szProductId or cfg.szMapProductId == szProductId then
            return cfg
        end
    end

    return nil
end

--- 基于实物订单实现的直购流程
function PayData.BuyRMBProduct(szProductId)
    local hPlayer = GetClientPlayer()
    if not hPlayer or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
        return
    end

    local tConfig = self.GetRMBPayConfig(szProductId)
    if not tConfig then
        LOG.ERROR("未找到对应的直购商品配置 szProductId=%s", szProductId)
        return
    end

    if self.IsRMBProductInStorageArea(szProductId) then
        LOG.DEBUG("当前保管区内有该直购商品，不允许再购买，需要先去保管区内领取")
        TipsHelper.ShowImportantRedTip("当前保管区内有对应商品未领取，请先前往商城-保管领取后再尝试购买", false, 5)
        return
    end

    local nCoin = ItemData.GetCoin()
    if nCoin < 0 then
        TipsHelper.ShowNormalTip("当前通宝数量不符合购买条件", false)
        return
    end

    local nTabIndex = tConfig.dwItemIndex
    local nGoodsId  = tConfig.dwGoodsID

    LOG.DEBUG("购买直购商品 szProductId=%s nTabIndex=%d nGoodsId=%d", szProductId, nTabIndex, nGoodsId)

    local szMsgTemplate = g_tStrings.Reward.REWARDSR_BUY_SURE_RMB
    LOG.DEBUG("[直购] 使用实物道具来实现直购流程 nTabIndex=%d nGoodsId=%d", nTabIndex, nGoodsId)

    local tInfo = CoinShop_GetPriceInfo(nGoodsId, COIN_SHOP_GOODS_TYPE.ITEM)
    if not tInfo.bIsReal then
        LOG.ERROR("[直购] nGoodsId=%d 不是实物道具", nGoodsId)
    end

    local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nTabIndex)
    local nBookInfo
    if itemInfo.nGenre == ITEM_GENRE.BOOK then
        nBookInfo = itemInfo.nDurability
    end
    local szName = ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
    szName       = UIHelper.GBKToUTF8(szName)
    local nPrice = CoinShop_GetPrice(nGoodsId, COIN_SHOP_GOODS_TYPE.ITEM)
    local szMsg  = string.format(szMsgTemplate, szName, nPrice)

    UIHelper.ShowConfirm(szMsg, function()
        local tData = g_pClientPlayer.GetBuyItemOrderList() or {}
        for _, tOrder in pairs(tData) do
            if tOrder.nState == BUY_ITEM_ORDER_STATE.WAITING_FOR_PAYMENT then
                -- 目前实物订单最多只能有一个处于未支付状态，这里需要特殊处理下
                LOG.DEBUG("[直购] 已有未支付的实物订单 szOrderSN=%s dwItemType=%d dwItemIndex=%d",
                          tOrder.szOrderSN, tOrder.dwItemType, tOrder.dwItemIndex
                )
                if tOrder.dwItemType == ITEM_TABLE_TYPE.OTHER and tOrder.dwItemIndex == nTabIndex then
                    -- 是当前商品，则跳过下订单流程，走签名步骤
                    --UIHelper.SetVisible(self.WidgetBuyingMask, true)
                    g_pClientPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.REAL_ITEM_ORDER, tOrder.szOrderSN)
                else
                    -- 是其他道具，则提示一下
                    TipsHelper.ShowImportantRedTip("侠士在30分钟内存在同类型订单未支付，请在冷却时间（30分钟）后再尝试购买")
                end

                -- 这种情况不再触发实物订单下单流程
                return
            end
        end

        --UIHelper.SetVisible(self.WidgetBuyingMask, true)
        ---@see 搜索：实物订单通知 ，在Global.lua中可找到实物订单后续流程的逻辑
        local nRetCode = CoinShop_BuyItem(nGoodsId, COIN_SHOP_GOODS_TYPE.ITEM, 1)
        if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
            --UIHelper.SetVisible(self.WidgetBuyingMask, false)
        end
    end, nil, true)
end

--- 该直购商品是否已在保管区内
function PayData.IsRMBProductInStorageArea(szProductId)
    local bInStorage   = false

    local tConfig      = self.GetRMBPayConfig(szProductId)

    local tStorageList = CoinShopData.GetStorageGoodsList()
    for _, dwStorageID in ipairs(tStorageList) do
        local tStorage = GetCoinShopClient().GetStorageGoodsInfo(dwStorageID)

        if tStorage and tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and tStorage.dwGoodsID == tConfig.dwGoodsID then
            bInStorage = true
            LOG.DEBUG("直购商品 szProductId=%s dwGoodsID=%d 在保管区内", szProductId, tConfig.dwGoodsID)
            break
        end
    end

    return bInStorage
end

--- 是否可以购买直购商品
--- 满足以下条件之一则可以购买
--- 1. 配置了预购id，且对应预购次数仍未用完
--- 2. 在待支付的实物订单列表中
function PayData.CanBuyRMBProduct(szProductId, nPreOrderID)
    if not g_pClientPlayer then
        LOG.DEBUG("玩家对象不存在")
        return false
    end

    local tConfig = self.GetRMBPayConfig(szProductId)
    if not tConfig then
        LOG.DEBUG("无法找到商品配置 %s", szProductId)
        return false
    end

    local nTabIndex = tConfig.dwItemIndex
    local nGoodsId  = tConfig.dwGoodsID

    local bCanBuy = false

    if nPreOrderID and nPreOrderID > 0 and GetClientPlayer().GetCoinShopPreOrderCount(nPreOrderID) > 0 then
        --- 仍有预购次数，允许购买
        bCanBuy = true
    else
        -- 若当前商品处于待支付的实物订单状态，则也允许点击购买
        local tData = g_pClientPlayer.GetBuyItemOrderList() or {}
        for _, tOrder in pairs(tData) do
            -- 目前实物订单最多只能有一个处于未支付状态，这里需要特殊处理下
            if tOrder.nState == BUY_ITEM_ORDER_STATE.WAITING_FOR_PAYMENT then
                if tOrder.dwItemType == ITEM_TABLE_TYPE.OTHER and tOrder.dwItemIndex == nTabIndex then
                    bCanBuy = true
                end

                break
            end
        end
    end

    return bCanBuy
end

function PayData.Pay(szProductId, szCustomInfo, szOrderSN, nBuyCount)
    return XGSDK.Pay(szProductId, szCustomInfo, szOrderSN, nBuyCount)
end

PayData.ServerTypeEnum = {
    Others = 0,
    DianKa = 1,
    DianYueKa = 2,
}

function PayData.GetServerType()
    local nCurrentChargeMode = GetChargeMode()
    if nCurrentChargeMode == CHARGE_MODE.POINT_CARD then
        return PayData.ServerTypeEnum.DianKa
    else
        return PayData.ServerTypeEnum.DianYueKa
    end
end

function PayData.IsPlayerMeetCompensationCondition()
    local nTimeRefresh = DateToTime(2019, 7, 10, 7, 0, 0)
    return Login_GetZoneChargeFlag() and (Login_GetExtPoint(0) == 0) and (Login_GetExtPoint(1) > nTimeRefresh) and (Login_GetExtPoint(2) == 0)
end

function PayData.GetActualPointLeftTime(nPointLeftTimeWhenLastSync, nMonthCardEndTime)
    if nPointLeftTimeWhenLastSync <= 0 then
        return nPointLeftTimeWhenLastSync
    end

    -- 登录时间点
    local nLoginTime = Login_GetLoginTime()

    -- 当前点卡剩余时间（秒）会在每次登录时从服务器同步全量
    -- 充值：玩的过程中充值点卡，会同步包含新增值的点卡剩余时间过来
    -- 扣除：在登出时才会扣除
    -- 因此，中途通知过来的点卡时间只会包含新充值的数目，不会包含已度过的时间，估算余额时的基准时间为登录的时间点
    -- 根据 月卡截止时间 t1 与 登录时间 t2、当前时间 t3 的相对关系，当前预估上次同步后使用的点卡数目的计算方式如下
    --  1. t1<t2<t3     此时消耗时长为 t3-t2
    --  2. t2<t1<t3     此时消耗时长为 t3-t1
    --  3. t2<t3<t1     此时消耗时长为 t3-t3(=0)
    --
    -- PS: t2必定小于t3,因为上次同步必定在当前之前
    local t1 = nMonthCardEndTime
    local t2 = nLoginTime
    local t3 = GetCurrentTime()

    -- 开始使用点卡的时间点
    local tStartUsePointCardTimePoint = t3
    if t1 < t2 then
        -- 上次同步时，月卡已过期，此时开始使用点卡
        tStartUsePointCardTimePoint = t2
    elseif t2 <= t1 and t1 < t3 then
        -- 月卡在上次同步和当前时间之前过期，从月卡过期的时间点开始使用点卡
        tStartUsePointCardTimePoint = t1
    else
        -- 当前月卡尚未过期，不消耗点卡，也就是尚未开始使用点卡
        tStartUsePointCardTimePoint = t3
    end

    -- 上次同步后，新使用的点卡时长
    local nUsedPointCardTime = t3 - tStartUsePointCardTimePoint

    -- 预估的剩余点卡数
    local nPointLeftTime = nPointLeftTimeWhenLastSync - nUsedPointCardTime
    if nPointLeftTime < 0 then
        nPointLeftTime = 0
    end

    LOG.DEBUG("GetActualPointLeftTime t1=%d t2=%d t3=%d nUsedPointCardTime=%d nPointLeftTimeWhenLastSync=%d nPointLeftTime=%d",
              t1, t2, t3, nUsedPointCardTime, nPointLeftTimeWhenLastSync, nPointLeftTime)

    return nPointLeftTime
end

function PayData.FormatPointTime(nPointLeftTime)
    local szPointLeftTime = ""

    -- 先确保时间为正数，否则负数除法会与预期不一样
    if nPointLeftTime < 0 then
        nPointLeftTime = -nPointLeftTime
        szPointLeftTime = szPointLeftTime .. "-"
    end

    szPointLeftTime = szPointLeftTime .. math.floor(nPointLeftTime / 3600) .. g_tStrings.STR_TIME_HOUR ..
            math.floor((nPointLeftTime % 3600) / 60) .. g_tStrings.STR_TIME_MINUTE ..
            (nPointLeftTime % 60) .. g_tStrings.STR_TIME_SECOND

    return szPointLeftTime
end

function PayData.ShowRefundTip(strChannel, strOrderSN, strOrderTime, nRechargeType, nRechargePointsAmount, nRechargeRMBAmount, nLeftTimeOfPoint, nLeftTimeOfDays, nEndDate, dwEndTimeOfFee)
    -- 预处理下金额
    if nRechargeRMBAmount < 0 then
        -- 退款时金额会是负数，显示的时候使用正数
        nRechargeRMBAmount = -nRechargeRMBAmount
    end
    -- 金额单位为元（之前为分，先继续这么写）
    local nRechargeRMBAmountYuan = nRechargeRMBAmount

    -- 构造提示信息
    local szTip = "退款信息\n"
    szTip = szTip .. string.format("订单渠道：%s 订单时间：%s\n", strChannel, strOrderTime)
    szTip = szTip .. string.format("订单单号：%s\n", strOrderSN)

    local szTipType   = ""
    local szTipAmount = ""
    local szTipDesc = ""
    if nRechargeType == 1 then
        szTipType = "月卡"
        szTipAmount = string.format("充值时长：%d分钟", nRechargePointsAmount / 60)

        local dateMonthEndTime = TimeToDate(nEndDate)
        local szEndTime = string.format("%d-%02d-%02d %02d:%02d:%02d",
                                        dateMonthEndTime.year, dateMonthEndTime.month, dateMonthEndTime.day,
                                        dateMonthEndTime.hour, dateMonthEndTime.minute, dateMonthEndTime.second
        )
        szTipDesc = string.format("该订单已完成退款，现已扣除该订单包含的游戏时长\n当前月卡截止时间为%s", szEndTime)
    elseif nRechargeType == 2 then
        szTipType = "点卡"
        szTipAmount = string.format("充值时长：%d分钟", nRechargePointsAmount / 60)

        local szPointLeftTime = PayData.FormatPointTime(nLeftTimeOfPoint)
        szTipDesc = string.format("该订单已完成退款，现已扣除该订单包含的游戏时长\n当前剩余时长为%s", szPointLeftTime)
    elseif nRechargeType == 6 then
        szTipType = "通宝"
        szTipAmount = string.format("充值数目：%d通宝", nRechargePointsAmount)
        szTipDesc = string.format("该订单已完成退款，现已扣除该订单包含的通宝\n当前剩余通宝为%d通宝", ItemData.GetCoin())
    end

    szTip = szTip .. string.format("充值金额：%s元 充值类型：%s %s\n", nRechargeRMBAmountYuan, szTipType, szTipAmount)

    szTip = szTip .. string.format("%s\n", szTipDesc)

    local scriptView = UIHelper.ShowConfirm(szTip)
    scriptView:HideButton("Cancel")
end