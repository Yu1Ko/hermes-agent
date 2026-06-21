-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelPriceTrendChartPop
-- Date: 2023-06-06 09:41:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelPriceTrendChartPop = class("UIPanelPriceTrendChartPop")

function UIPanelPriceTrendChartPop:OnEnter(nLength, tbPriceData, nMaxPrice, nMinPrice, nAvgPrice)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nLength = nLength
    self.tbPriceData = tbPriceData
    self.nMaxPrice = nMaxPrice
    self.nMinPrice = nMinPrice
    self.nAvgPrice = nAvgPrice

    self:UpdateInfo()
end

function UIPanelPriceTrendChartPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelPriceTrendChartPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelPriceTrendChartPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIHelper.SetVisible(self.WidgetSelectDatePrice, false)
    end)
end

function UIPanelPriceTrendChartPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelPriceTrendChartPop:UpdateInfo()
    local nHistoryMax = self.nMaxPrice
    local nHistoryMin = self.nMinPrice
    local nAvgPrice = self.nAvgPrice

    --计算昨天价格
    -- local tbHistoryYD = self.nLength >= 1 and self.tbPriceData[1].Price or {["nGold"] = 0, ["nSilver"] = 0, ["nCopper"] = 0}
    -- local nHistoryYD = UIHelper.GoldSilverAndCopperToMoney(tbHistoryYD.nGold, tbHistoryYD.nSilver, tbHistoryYD.nCopper)

    local scriptViewMax = UIHelper.GetBindScript(self.WidgetMaxPrice)
    scriptViewMax:OnEnter(nHistoryMax)
    local scriptViewMin = UIHelper.GetBindScript(self.WidgetMinPrice)
    scriptViewMin:OnEnter(nHistoryMin)
    local scriptViewYd = UIHelper.GetBindScript(self.WidgetAverageYesterday)
    scriptViewYd:OnEnter(nAvgPrice)


    local nMoneyGap = nHistoryMax - nHistoryMin
    if self.tbPriceData then
        for index = 30, 1, -1 do
            local tbPriceData = self.tbPriceData[index]
            local nHistoryPrice = UIHelper.GoldSilverAndCopperToMoney(tbPriceData.Price.nGold, tbPriceData.Price.nSilver, tbPriceData.Price.nCopper)
            local nPercent = Lib.SafeDivision(nHistoryPrice, nHistoryMax)
            local color = self:GetPriceChartCellColor(nHistoryPrice, nHistoryMin, nMoneyGap, index, 30)
            UIHelper.AddPrefab(PREFAB_ID.WidgetPriceChartCell, self.LayoutListDetail, nPercent, color, function()
                self:ShowSelectPrice(nHistoryPrice)
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutListDetail)
    end

end

function UIPanelPriceTrendChartPop:ShowSelectPrice(nMoney)
    UIHelper.SetVisible(self.WidgetSelectDatePrice, true)
    local scriptView = UIHelper.GetBindScript(self.WidgetSelectDatePrice)
    scriptView:OnEnter(nMoney)
end

function UIPanelPriceTrendChartPop:GetPriceChartCellColor(nPrice, nMinMoney, nMoneyGap, nIndex, nLength)
    local nRate = nMoneyGap ~= 0 and (nPrice - nMinMoney) / nMoneyGap or 0
    if nMoneyGap == 0 then
        if nIndex ~= 1 then
            return cc.c3b(255, 255, 255) --Normal
		else
			return cc.c3b(239, 191, 88) --Orange
		end
    end
    local nRate =  (nPrice - nMinMoney) / nMoneyGap
    if nRate == 1 then
        return cc.c3b(225,133,125) --Red 
	elseif nRate == 0 then
        return cc.c3b(109, 191, 152) --Green
	elseif nCurrentDay == 1 then
        return cc.c3b(239, 191, 88) --Orange
	else
        return cc.c3b(255, 255, 255) --Normal 
	end
end


return UIPanelPriceTrendChartPop