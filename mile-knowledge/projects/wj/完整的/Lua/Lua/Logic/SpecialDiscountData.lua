-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: SpecialDiscountData
-- Date: 2023-08-02 14:52:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

SpecialDiscountData = SpecialDiscountData or {}
local self = SpecialDiscountData
-------------------------------- 消息定义 --------------------------------
SpecialDiscountData.Event = {}
SpecialDiscountData.Event.XXX = "SpecialDiscountData.Msg.XXX"

g_tNewLimit = {}
function SpecialDiscountData.Init()
	
end

function SpecialDiscountData.UnInit()
	
end

function SpecialDiscountData.OnLogin()
	
end

function SpecialDiscountData.OnFirstLoadEnd()
	
end

function SpecialDiscountData.LimitedSaleOpen(nType, tTable, bAdd, dwShowID)
	if nType == 1 or nType == 2 then
		local tList = {}
        if not bAdd then
            tList = {}
        end
        for _, t in ipairs(tTable) do
            local tInfo = self.InitSaleInfo(t)
			if self.IsInTime(tInfo.nEndTime) and not self.LimitedSaleHaveGoods(tInfo.tGoods) then
				table.insert(tList,tInfo)
				if not g_tNewLimit[tInfo.dwID] then
					g_tNewLimit[tInfo.dwID] = true
				end
			end
        end
		if #tList == 0 then
			BubbleMsgData.RemoveMsg("SpecialDiscountTips")
			return
		end
        if nType == 1 then
            SpecialDiscountData.OpenPanelSpecialDiscountPop(tList, dwShowID)
        end

		--直升110级气泡
		local nShowIndex = SpecialDiscountData.GetCenterIndex(tList,1)
		local tLine = tList[nShowIndex]
        BubbleMsgData.PushMsgWithType("SpecialDiscountTips",{
            nBarTime = SpecialDiscountData.GetLeftTime(tLine.nEndTime), 							-- 显示在气泡栏的时长, 单位为秒
            szContent = "购买直升豪礼，勇闯江湖！",
            szAction = function ()
                SpecialDiscountData.OpenPanelSpecialDiscountPop(tList, nShowIndex)
            end,
            nLifeTime = SpecialDiscountData.GetLeftTime(tLine.nEndTime), 						-- 存在时长, 单位为秒
        })
    end
    if nType == 3 then  --隐藏气泡入口
        BubbleMsgData.RemoveMsg("SpecialDiscountTips")
    end
end

function SpecialDiscountData.InitSaleInfo(t)
	local dwID 		= t[1]
	local nEndTime 	= t[2]
	local tLine = Table_GetLimitedSale(dwID)
	tLine.nEndTime = nEndTime
	return tLine
end

function SpecialDiscountData.IsInTime(nTime)
	if nTime <= 0 then
		return true
	end
	local nTime = nTime + GetTimezone()
	local nCurrentTime = GetCurrentTime()
	if nCurrentTime < nTime then
		return true
	end
end

function SpecialDiscountData.LimitedSaleHaveGoods(tGoods)
	local nAllCount = 0
	local nBuyCount = 0
	for _, tGood in ipairs(tGoods) do
		nAllCount = nAllCount + 1
		local nOwnType = GetCoinShopClient().CheckAlreadyHave(tGood.eGoodsType, tGood.dwGoodsID)
		if nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE then
			nBuyCount = nBuyCount + 1
		end
	end
	if nAllCount == nBuyCount then
		return true
	end
end

function SpecialDiscountData.GetLeftTime(nTime)
	if nTime <= 0 then
		return true
	end
	local nLeftTime = nTime + GetTimezone() - GetCurrentTime()
	return nLeftTime
end

function SpecialDiscountData.OpenPanelSpecialDiscountPop(tList, nShowIndex)
	UIMgr.Open(VIEW_ID.PanelSpecialDiscountPop , tList, nShowIndex)
end

function SpecialDiscountData.GetCenterIndex(tList, dwShowID)
	if dwShowID then
		for k, v in ipairs(tList) do
			if v.dwID == dwShowID then
				return k
			end
		end
	end
end