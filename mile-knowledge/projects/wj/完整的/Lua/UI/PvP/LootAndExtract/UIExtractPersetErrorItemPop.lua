-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetErrorItemPop
-- Date: 2025-03-27 14:55:54
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nCountOfRow = 2
local UIExtractPersetErrorItemPop = class("UIExtractPersetErrorItemPop")
function UIExtractPersetErrorItemPop:OnEnter(tbItemList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbItemList = tbItemList
    self:UpdateInfo()
end

function UIExtractPersetErrorItemPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetErrorItemPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        self:DoQuickBuy()
    end)
end

function UIExtractPersetErrorItemPop:RegEvent()

end

function UIExtractPersetErrorItemPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractPersetErrorItemPop:UpdateInfo()
    if not self.tbItemList then
        return
    end

    UIHelper.SetString(self.LabelLackItem, tostring(#self.tbItemList))
    self:UpdateList()
    self:UpdateQuickBuyCost()
end

function UIExtractPersetErrorItemPop:UpdateList()

    UIHelper.RemoveAllChildren(self.ScrollViewContentSelect01)
    for nIndex, v in ipairs(self.tbItemList) do
        local nType, dwIndex, nNeedCount = v[1], v[2], v[3]
        local nCoin, nMoney = v[4], v[5]
        local nWareType, nSlot = v[6], v[7]

        self.tbItemList[nIndex].nCount = nNeedCount
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoBuyLackItemCell, self.ScrollViewContentSelect01)
        script:OnEnter(v)
        script:SetOnChangeEditCountCallBack(function(nCount)
            self.tbItemList[nIndex].nCount = nCount
            self:UpdateQuickBuyCost()
        end)

        -- script:SetOnClickCancelCallBack(function()
        --     UIHelper.RemoveFromParent(script._rootNode, true)
        --     UIHelper.ScrollViewDoLayout(self.ScrollViewContentSelect01)
        --     UIHelper.ScrollToIndex(self.ScrollViewContentSelect01, nIndex - 1)

        --     table.remove(self.tbItemList, nIndex)
        --     self:UpdateQuickBuyCost()
        -- end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect01)
end

function UIExtractPersetErrorItemPop:DoQuickBuy()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local function funcConfirm()
        local tBuyList = {}
        for index, v in ipairs(self.tbItemList) do
            local nCount = v.nCount
            if nCount and nCount ~= 0 then
                table.insert(tBuyList, {v[1], v[2], nCount, v[6], v[7]})
            end
        end

        RemoteCallToServer("On_JueJing_BuyLastGameIni", tBuyList)
        UIMgr.Close(self)
    end

    local nCost = 0
    local nMoney = 0
    for _, tbInfo in pairs(self.tbItemList) do
        local nAmount = tbInfo.nCount or 0
        local nCoin = tbInfo[4] or 0
        local nGold = tbInfo[5] or 0
        nCost = nCost + (nAmount * nCoin)
        nMoney = nMoney + (nAmount * nGold)
    end

    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney * 10000))
    local bCoinEnough = nCost <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
	local bMoneyEnough = MoneyOptCmp(player.GetMoney(), tPrice) > 0

    local szText = ""
    if nCost and nCost > 0 then
        local szIcon = CurrencyData.tbImageSmallIcon[CurrencyType.ExamPrint]
        szIcon = string.gsub(szIcon, ".png", "")
        local szContent = UIHelper.GetCurrencyText(nCost, szIcon, 26)
        if not bCoinEnough then
            szContent = "<color=#ff7676>" .. szContent .."</color>"
        end
        szText = szText..szContent
    end

    if nMoney and nMoney > 0 then
        local szContent = UIHelper.GetGoldText(nMoney)
        if not bMoneyEnough then
            szContent = "<color=#ff7676>" .. szContent .."</color>"
        end
        szText = szText..(szText ~= "" and "+" or "")..szContent
    end

    local szContent = string.format("您确定花费%s购买剩余物品吗？", szText)
    local scriptTips = UIHelper.ShowConfirm(szContent, funcConfirm, nil, true)
end

function UIExtractPersetErrorItemPop:UpdateQuickBuyCost()
    local nCost = 0
    local nMoney = 0
    for _, tbInfo in pairs(self.tbItemList) do
        local nAmount = tbInfo.nCount or 0
        local nCoin = tbInfo[4] or 0
        local nGold = tbInfo[5] or 0
        nCost = nCost + (nAmount * nCoin)
        nMoney = nMoney + (nAmount * nGold)
    end

    local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney * 10000))
    local bCoinEnough = nCost <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
	local bMoneyEnough = MoneyOptCmp(g_pClientPlayer.GetMoney(), tPrice) > 0
    local bEnough = bCoinEnough and bMoneyEnough

    UIHelper.SetString(self.LabelCoinNum, nCost)
    UIHelper.SetString(self.LabelMoneyNum, nMoney)

    UIHelper.SetColor(self.LabelCoinNum, bCoinEnough and cc.WHITE or cc.c3b(255, 118, 118))
    UIHelper.SetColor(self.LabelMoneyNum, bMoneyEnough and cc.WHITE or cc.c3b(255, 118, 118))
    UIHelper.SetButtonState(self.BtnBuy, bEnough and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.SetVisible(self.LabelMoneyNum, nMoney > 0)
    UIHelper.SetVisible(self.WidgetMoney, nMoney > 0)
    UIHelper.SetVisible(self.LabelCoinNum, nCost > 0)
    UIHelper.SetVisible(self.WidgetCoin, nCost > 0)
    UIHelper.LayoutDoLayout(self.LayoutCost)
end

return UIExtractPersetErrorItemPop