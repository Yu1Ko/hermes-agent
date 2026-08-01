NewModule("FurnitureBuy")

local TIME_TYPE = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
local PAY_TYPE = COIN_SHOP_PAY_TYPE.COIN
local DEFAULT_DISCOUNT = 100

--------------------- 保管区 ---------------------------
function GetFurnitureStorageList()
	hCoinShop = GetCoinShopClient()
    assert(hCoinShop)
    local tStorageList = hCoinShop.GetStorageGoodsList()
    local tFurnitureStorageList = {}
    for _, dwStorageID in ipairs(tStorageList) do
        local tStorage = hCoinShop.GetStorageGoodsInfo(dwStorageID)
        if tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.FURNITURE then
            table.insert(tFurnitureStorageList, dwStorageID)
        end
    end
    return tFurnitureStorageList
end

function StorageGet(dwStorageID)
    local dwStorageID = dwStorageID
    local nRetCode = GetCoinShopClient().TakeStorageGoods(dwStorageID)
    if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopNotify[nRetCode])
    end
end

function GetFurnitureStorageCount()
	hCoinShop = GetCoinShopClient()
    assert(hCoinShop)
    local tStorageList = hCoinShop.GetStorageGoodsList()
    local nCount = 0
    for _, dwStorageID in ipairs(tStorageList) do
        local tStorage = GetCoinShopClient().GetStorageGoodsInfo(dwStorageID)
        if tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.FURNITURE then
            nCount = nCount + 1
        end
    end
    return nCount
end

function GetStorageGoodsInfo(dwStorageID)
	local tInfo = GetCoinShopClient().GetStorageGoodsInfo(dwStorageID)
	return tInfo
end

function IsFurnitrueGoods(dwStorageID)
    local tStorage = GetCoinShopClient().GetStorageGoodsInfo(dwStorageID)
    return tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.FURNITURE
end

------------------------获取信息-----------------------------------
function GetFurnitureInfo(dwFurnitureID)
    local tInfo = GetFurnitureShopInfo(dwFurnitureID)
    if tInfo then
        tInfo.tPrice = tInfo.tPrice[PAY_TYPE][TIME_TYPE]
        tInfo.ePayType = COIN_SHOP_PAY_TYPE.COIN
        tInfo.dwGoodsID = dwFurnitureID
        tInfo.eGoodsType = COIN_SHOP_GOODS_TYPE.FURNITURE
        tInfo.nCoin = tInfo.tPrice.nPrice
        if IsInDis(tInfo.tPrice.nDiscount, tInfo.tPrice.nDisStartTime, tInfo.tPrice.nDisEndTime) then
            tInfo.nFinalCoin = GetDisPrice(tInfo.nCoin, tInfo.tPrice.nDiscount)
        else
            tInfo.nFinalCoin = tInfo.nCoin
        end
        tInfo.bSell = IsInSell(tInfo.nStartTime, tInfo.nEndTime)
        return tInfo
    end
    return nil
end

function GetGold2ArchDiscount()
    local tConfig = GetHomelandMgr().GetConfig()
    local nRetDiscount, bRetInDiscount
    if IsInDis(tConfig.nBuyFurnitureMoneyDiscount, tConfig.nBuyFurnitureDiscountBeginTime, tConfig.nBuyFurnitureDiscountEndTime) then
        nRetDiscount, bRetInDiscount = tConfig.nBuyFurnitureMoneyDiscount, true
    else
        nRetDiscount, bRetInDiscount = DEFAULT_DISCOUNT, false
    end
    return nRetDiscount, bRetInDiscount
end

function GetArchBuyFurnitureDiscount(dwFurnitureID)
    local tConfig = GetHomelandMgr().GetFurnitureConfig(dwFurnitureID)
    local nRetDiscount, bRetInDiscount
    if IsInDis(tConfig.nDiscount, tConfig.nDiscountBeginTime, tConfig.nDiscountEndTime) then
        nRetDiscount, bRetInDiscount = tConfig.nDiscount, true
    else
        nRetDiscount, bRetInDiscount = DEFAULT_DISCOUNT, false
    end
    return nRetDiscount, bRetInDiscount
end

function GetCoinBuyFurnitureDiscount(dwFurnitureID)
    local tCoinInfo = GetFurnitureInfo(dwFurnitureID)
    local nRetDiscount, bRetInDiscount
    if tCoinInfo and IsInDis(tCoinInfo.tPrice.nDiscount, tCoinInfo.tPrice.nDisStartTime, tCoinInfo.tPrice.nDisEndTime) then
        nRetDiscount, bRetInDiscount = tCoinInfo.tPrice.nDiscount, true
    else
        nRetDiscount, bRetInDiscount = DEFAULT_DISCOUNT, false
    end
    return nRetDiscount, bRetInDiscount
end

function GetDisPrice(nPrice, nDiscount)
    local nPrice = math.ceil(nPrice * nDiscount / GLOBAL.COIN_PRICE_DISCOUNT_BASE)
    return nPrice
end

function IsInDis(nDiscount, nDisStartTime, nDisEndTime)
    local nCurrentTime = GetCurrentTime()
    if nDiscount >= GLOBAL.COIN_PRICE_DISCOUNT_BASE then
        return false
    end
    local bDis = (nDisStartTime == -1 or nCurrentTime >= nDisStartTime) and
                (nDisEndTime == -1 or nCurrentTime <= nDisEndTime)
    return bDis
end

function IsInSell(nSellStartTime, nSellEndTime)
    local nCurrentTime = GetCurrentTime()
    local bSell = (nSellStartTime == -1 or nCurrentTime >= nSellStartTime) and
                (nSellEndTime == -1 or nCurrentTime <= nSellEndTime)
    return bSell
end

function GetDiscountNum(nDiscount)
	if nDiscount % 10 > 0 then
		return nDiscount / 10
	else
		return math.floor(nDiscount / 10)
	end
end

function GetShowPrice(dwFurnitureID)
   local tInfo = GetFurnitureInfo(dwFurnitureID)
   local tPrice = tInfo.tPrice
   local nPrice, nOriginalPrice
   if tPrice then
        nOriginalPrice = tPrice.nPrice
        if IsInDis(tPrice.nDiscount, tPrice.nDisStartTime, tPrice.nDisEndTime) then
            nPrice = GetDisPrice(tPrice.nPrice, tPrice.nDiscount)
        else
            nPrice = tPrice.nPrice
        end
   end
   return nPrice, nOriginalPrice
end

function GetFurnitureWelfares()
    local tInfo = CoinShopData.GetWelfares(true)
    return tInfo
end

function CheckCanUseDisCouponForFurniture(tDisCoupon, tBuy)
	local me = GetClientPlayer()
	if not me.CheckDisCouponValid(tDisCoupon.dwDisCouponID) then
		return false
	end
	local nPrice = 0
	local bDis = false

	for _, tBuyItem in ipairs(tBuy) do
		if (not tBuyItem.bForbidDisCoupon)
		and me.CheckCanUseDisCouponForGoods(tDisCoupon.dwDisCouponID, tBuyItem.eGoodsType, tBuyItem.dwGoodsID) then
			if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
				return true
			elseif tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
				local nItemPrice = GetShowPrice(tBuyItem.dwGoodsID)
				nPrice = nPrice + nItemPrice * (tBuyItem.nBuyCount or 1)
				bDis = true
			end
		end
	end

	if bDis and tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
		if nPrice >= tDisCoupon.nFull then
			return true
		end
	end

	return false
end

function GetUsableFurnitureDisCouponList(tBuy)
    local tInfo = CoinShopData.GetWelfares(true)
    local tNewInfo = {}
    for k, v in pairs(tInfo) do
        if CheckCanUseDisCouponForFurniture(v, tBuy) then
            table.insert(tNewInfo, v)
        end
    end
    return tNewInfo
end

function GetFurnitureWelfare(dwDisCouponID)
    local tInfo = CoinShopData.GetWelfares(true)
    for _, tDisCoupon in ipairs(tInfo) do
        if tDisCoupon.dwDisCouponID == dwDisCouponID then
            return tDisCoupon
        end
    end
    return nil
end

function GetDisCouponPrice(tBuy, tDisCoupon)
    local nDiscount = 0
	local nPrice = 0
	local bDis = false
    local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end

    for _, tBuyItem in ipairs(tBuy) do
		if hCoinShopClient.CheckCouponCanUseForFurniture(tDisCoupon.dwDisCouponID)
		    and not tBuyItem.bForbidDisCoupon then
			local nItemPrice = GetShowPrice(tBuyItem.dwGoodsID)
			if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT then
				nPrice = nPrice + nItemPrice * (tBuyItem.nBuyCount or 1)
				bDis = true
			elseif tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.DISCOUNT then
				nDiscount = nDiscount + nItemPrice * (100 - tDisCoupon.nDiscount) / 100 * (tBuyItem.nBuyCount or 1)
			end
		end
	end

    if tDisCoupon.nType == COIN_SHOP_DISCOUNT_TYPE.FULL_CUT and bDis then
		if nPrice >= tDisCoupon.nFull then
			nDiscount = tDisCoupon.nCut
		end
	end
	return nDiscount
end

function IntelligentSelectDisCouponEx(tBuy)
    local hCoinShopClient = GetCoinShopClient()
	if not hCoinShopClient then
		return
	end
	local dwDisCouponID = -1
	local nMaxDiscount = 0
    local bIsAccountLevel = false
    local tDisCouponInfo = GetUsableFurnitureDisCouponList(tBuy)
	for _, tDisCoupon in ipairs(tDisCouponInfo) do
		if hCoinShopClient.CheckCouponCanUseForFurniture(tDisCoupon.dwDisCouponID) then
			local nDiscount = GetDisCouponPrice(tBuy, tDisCoupon)
			if (nDiscount > nMaxDiscount) or (nDiscount == nMaxDiscount and bIsAccountLevel and not tDisCoupon.bIsAccountLevel) then
				nMaxDiscount = nDiscount
				dwDisCouponID = tDisCoupon.dwDisCouponID
                bIsAccountLevel = tDisCoupon.bIsAccountLevel
			end
		end
	end
	return dwDisCouponID
end

function GetMoneyDetail(nMoney)
    local nZhuan = math.floor(nMoney / 10000 / 100)
    local nGlod = math.floor((nMoney - nZhuan * 10000 * 100) / 100)
    local nSilver = nMoney % 100
    return nZhuan, nGlod, nSilver
end

function ArchExSilver(nArchitecture)
    local tConfig = GetHomelandMgr().GetConfig()
    local nBuyFurnitureMoneyRate = tConfig.nBuyFurnitureMoneyRate
    local nBuyFurnitureMoneyDiscount = tConfig.nBuyFurnitureMoneyDiscount
    local nBuyFurnitureDiscountBeginTime = tConfig.nBuyFurnitureDiscountBeginTime
    local nBuyFurnitureDiscountEndTime = tConfig.nBuyFurnitureDiscountEndTime
    local nMoney --银
    if IsInDis(nBuyFurnitureMoneyDiscount, nBuyFurnitureDiscountBeginTime, nBuyFurnitureDiscountEndTime)
        and (not bNotDis) then
        nMoney = math.ceil((nArchitecture * nBuyFurnitureMoneyDiscount) / nBuyFurnitureMoneyRate)
    else
        nMoney = math.ceil(nArchitecture * 100 / nBuyFurnitureMoneyRate)
    end
    return nMoney
end

function ArchExMoneyDetail(nArchitecture)
    local nMoney = ArchExSilver(nArchitecture)
    return GetMoneyDetail(nMoney)
end

function DiscountSilver(nArchitecture)
    local tConfig = GetHomelandMgr().GetConfig()
    local nBuyFurnitureMoneyRate = tConfig.nBuyFurnitureMoneyRate
    local nBuyFurnitureMoneyDiscount = tConfig.nBuyFurnitureMoneyDiscount
    local nBuyFurnitureDiscountBeginTime = tConfig.nBuyFurnitureDiscountBeginTime
    local nBuyFurnitureDiscountEndTime = tConfig.nBuyFurnitureDiscountEndTime
    local nMoney1 --银
    local nMoney2 --银
    if not IsInDis(nBuyFurnitureMoneyDiscount, nBuyFurnitureDiscountBeginTime, nBuyFurnitureDiscountEndTime) then
        return 0, 0, 0
    else
        nMoney2 = math.ceil((nArchitecture * nBuyFurnitureMoneyDiscount) / nBuyFurnitureMoneyRate)
        nMoney1 = math.ceil(nArchitecture * 100 / nBuyFurnitureMoneyRate)
    end
    return nMoney1 - nMoney2
end

function GetNewWelfares()
    local tInfo = CoinShop_Welfare.GetNewWelfares(true)
    return tInfo
end

function IsFurnitureCollected(dwFurnitureID)
    local _FURNITURE_COLLECT_ACTIVE_ID = 2
	local pHlMgr = GetHomelandMgr()
	local tLogicInfo = pHlMgr.GetFurnitureConfig(dwFurnitureID)
	local pPlayer = GetClientPlayer()
	if tLogicInfo then
		local dwSetID = tLogicInfo.nSetID
		if dwSetID > 0 then -- 0表示无效值
			local nSetIndex = tLogicInfo.nSetIndex
			local tSetConfig = pPlayer.GetSetCollection(dwSetID)
			if pPlayer.HaveSetCollectionData() then -- 现在其实必定成立
				local bCollected = tSetConfig.tSetUnit[nSetIndex] == 1
				return bCollected
			end
		end
	end
	return false
end

function IsSpecialFurnitrueCanBuy(dwFurnitureID)
    local hlMgr = GetHomelandMgr()
    local tConfig = hlMgr.GetFurnitureConfig(dwFurnitureID)
    if tConfig.nReBuyCost > 0 and tConfig.nArchitecture == 0 and
        tConfig.nSetID > 0 and tConfig.nSetIndex > 0 and
        IsFurnitureCollected(dwFurnitureID) then
        return true
    end
    return false
end

function IsSpecialFurnitrueCanBuyNotHave(dwFurnitureID)
    local hlMgr = GetHomelandMgr()
    local tConfig = hlMgr.GetFurnitureConfig(dwFurnitureID)
    if tConfig.nReBuyCost > 0 and tConfig.nArchitecture == 0 and
        tConfig.nSetID > 0 and tConfig.nSetIndex > 0 then
        return true
    end
    return false
end

function GetSpecialFurnitrueMoneyDetail(nTotalGold)
    local nZhuan = math.floor(nTotalGold / 10000)
	local nGold = nTotalGold % 10000
	local nSilver = 0
	return nZhuan, nGold, nSilver
end

function BuyPendant(dwFurnitureID)
    RemoteCallToServer("On_HomeLand_BuyPendant", dwFurnitureID)
end

function RecycleFurniture(dwFurnitureID, nNum)
    local hlMgr = GetHomelandMgr()
    local nCurAmount = hlMgr.GetFurniture(dwFurnitureID)
    if nCurAmount >= nNum then
        hlMgr.RecycleFurniture(dwFurnitureID, nNum)
    end
end

------------------------------- 购买 --------------------------------

function CoinBuy(tItemList, dwDisCouponID, fnIsOpened, fnChooseNewDisCoupon, fnFailed)
    CoinShop_BuyItemList(tItemList, PAY_TYPE, dwDisCouponID, nil, fnChooseNewDisCoupon, fnFailed)
end