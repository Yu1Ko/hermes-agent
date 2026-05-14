-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityCartDetailPop
-- Date: 2024-01-24 14:27:48
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FRAME_MODE =
{
    SELL = 1,
    BUY  = 2,
}

local FRAME_SUFFIX =
{
    [FRAME_MODE.SELL] = "Sell",
    [FRAME_MODE.BUY]  = "Buy"
}

local MESSAGE_MODE = {
    EAT       = 1,     --食用
    PACKAGE   = 2,     --打包
    TAKE_BACK = 3,     --取回
    TAKE_BACK_ALL = 4, --取回全部
}
local MIN_NUM = 1
local UIHomeIdentityCartDetailPop = class("UIHomeIdentityCartDetailPop")

local DataModel = {}
function DataModel.Init(dwOwnerID, nIndex, tInfo)
    local dwPlayerID = UI_GetClientPlayerID()
    if dwOwnerID ~= dwPlayerID then
        DataModel.SetFrameMode(FRAME_MODE.BUY)
        DataModel.nCount     = 1
    else
        DataModel.SetFrameMode(FRAME_MODE.SELL)
        DataModel.nCount    = tInfo.nCount or 1
    end
    DataModel.dwOwnerID  = dwOwnerID
    DataModel.bFurniture = tInfo.bFurniture
    DataModel.tFoodData  = tInfo
    DataModel.dwID       = tInfo.dwID or 0
    DataModel.nIndex     = nIndex
    DataModel.nMoney     = tInfo.nMoney or 0
    DataModel.nMaxBuy    = tInfo.nCount or 0
    DataModel.nMaxSell   = tInfo.nCount or 0
    DataModel.tFoodInfo  = Table_GetAllHLCookFood()
    DataModel.tPackageIndex = GetPackageIndex()
end

function DataModel.SetFrameMode(nMode)
    DataModel.nFrameMode = nMode
end

function DataModel.GetFrameMode()
    return DataModel.nFrameMode
end

function DataModel.GetFoodData()
    return DataModel.tFoodData
end

function DataModel.GetFoodInfoByIndex(dwIndex)
    for _, v in pairs(DataModel.tFoodInfo) do
        if v.dwIndex == dwIndex then
            return v
        end
    end
end

function DataModel.GetFoodInfo(dwID)
    for _, v in pairs(DataModel.tFoodInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIHomeIdentityCartDetailPop:OnEnter(dwOwnerID, nIndex, tInfo, bAddNew)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bAddNew = bAddNew
    DataModel.Init(dwOwnerID, nIndex, tInfo)
    self:Init()
end

function UIHomeIdentityCartDetailPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityCartDetailPop:BindUIEvent()
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginateMoney, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginateNum, TextHAlignment.CENTER)
    UIHelper.SetEditBoxInputMode(self.EditPaginateMoney, cc.EDITBOX_INPUT_MODE_NUMERIC)
    UIHelper.SetEditBoxInputMode(self.EditPaginateNum, cc.EDITBOX_INPUT_MODE_NUMERIC)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetText(self.EditPaginateNum)) or 0
        UIHelper.SetText(self.EditPaginateNum, nCount + 1)
        self:CheckNumEditMax()
        self:UpdateEditInfo()
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetText(self.EditPaginateNum)) or 0
        nCount = math.max(nCount - 1, 1)
        UIHelper.SetText(self.EditPaginateNum, nCount)
        self:CheckNumEditMax()
        self:UpdateEditInfo()
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function ()
        self:CheckNumEditMax(true)
        self:UpdateEditInfo()
    end)

    UIHelper.BindUIEvent(self.BtnCorrection, EventType.OnClick, function ()
        if not self.bAddNew then
            return
        end
        self:SellNewFood()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelLeftBag)
    end)

    UIHelper.BindUIEvent(self.BtnEdible, EventType.OnClick, function ()
        local bSell = DataModel.GetFrameMode() == FRAME_MODE.SELL
        if bSell then
            self:UpdateSellFood()
            UIMgr.Close(self)
        else
            self:BuyFood(true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPack, EventType.OnClick, function ()
        local bSell = DataModel.GetFrameMode() == FRAME_MODE.SELL
        if bSell then
            self:TakeBackFood()
            UIMgr.Close(self)
        else
            self:BuyFood(false)
        end
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginateMoney, function ()
        self:UpdateEditInfo()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginateNum, function ()
        self:CheckNumEditMax()
        self:UpdateEditInfo()
    end)
end

function UIHomeIdentityCartDetailPop:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        self:CheckNumEditMax()
        self:UpdateEditInfo()
    end)
end

function UIHomeIdentityCartDetailPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomeIdentityCartDetailPop:Init()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
    UIHelper.SetText(self.EditPaginateNum, DataModel.nCount or 1)
    self:UpdateDealModeInfo()
    self:UpdateFoodItem()
    self:UpdateEditInfo()
end

function UIHomeIdentityCartDetailPop:UpdateDealModeInfo()
    UIHelper.SetVisible(self.WidgetCountInput, false)
    UIHelper.SetVisible(self.LayoutDeal, false)
    UIHelper.SetVisible(self.BtnCorrection, false)
    UIHelper.SetVisible(self.BtnEdible, false)
    UIHelper.SetVisible(self.BtnPack, false)
    UIHelper.SetVisible(self.WidgetUnivalenceNum, false)

    local nFrameMode = DataModel.GetFrameMode()
    if nFrameMode == FRAME_MODE.SELL then
        self:UpdateSellerPage()
    elseif nFrameMode == FRAME_MODE.BUY then
        self:UpdateConsumerPage()
    end

    if self.bAddNew then
        UIHelper.SetVisible(self.BtnCorrection, true)
    else
        UIHelper.SetVisible(self.BtnPack, true)
        UIHelper.SetVisible(self.BtnEdible, true)
    end
end

function UIHomeIdentityCartDetailPop:UpdateConsumerPage()
    local nMoney = DataModel.nMoney
    UIHelper.SetVisible(self.WidgetUnivalenceNum, true)
    UIHelper.SetVisible(self.BtnEdible, false)
    UIHelper.SetString(self.LabelProfit, "总价：")
    UIHelper.SetString(self.LabelEdible, "食用")
    UIHelper.SetString(self.LabelPack, "购买")
    UIHelper.SetString(self.LabelMoney, nMoney)
end

function UIHomeIdentityCartDetailPop:UpdateSellerPage()
    local nMoney = DataModel.nMoney
    UIHelper.SetVisible(self.WidgetCountInput, true)
    UIHelper.SetVisible(self.BtnEdible, true)
    UIHelper.SetVisible(self.LayoutDeal, true)
    UIHelper.SetString(self.LabelProfit, "总收益：")
    UIHelper.SetString(self.LabelPack, "取回食物")
    UIHelper.SetString(self.LabelEdible, "确认修改")
    UIHelper.SetText(self.EditPaginateMoney, nMoney)
end

--截取道具描述第一个<text></text>字段
local function GetFoodBuffDesc(tItemInfo)
    if not tItemInfo then
        return
    end
    local szDesc = ItemData.GetItemDesc(tItemInfo.nUiId)
    local nTail = string.find(szDesc, "</text>")
    szDesc = string.sub(szDesc, 1, nTail + 6)
    szDesc = ParseTextHelper.ParseNormalText(szDesc)
    return szDesc
end

function UIHomeIdentityCartDetailPop:UpdateFoodItem()
    local nFrameMode  = DataModel.GetFrameMode()
    local nBagCount   = self.GetItemCountInBag()
    local nStack      = GDAPI_GetMaxFoodStack()
    local nCount      = DataModel.nMaxBuy
    local tFoodData   = DataModel.GetFoodData()
    local tFoodInfo   = DataModel.GetFoodInfo(DataModel.dwID)

    DataModel.nMaxSell = math.min(nBagCount, nStack)
    DataModel.nMaxSell = math.max(DataModel.nMaxBuy, DataModel.nMaxSell)
    if not tFoodInfo then
        return
    end
    local dwTabType = tFoodInfo.dwItemType
    local dwIndex   = tFoodInfo.dwIndex
    local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    if tItemInfo then
        UIHelper.SetString(self.LabelCuisineExplain, GetFoodBuffDesc(tItemInfo))
        UIHelper.SetRichText(self.RichTextItemName, UIHelper.GBKToUTF8(tItemInfo.szName))

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        script:OnInitWithTabID(dwTabType, dwIndex)
        script:SetClearSeletedOnCloseAllHoverTips(true)
        script:SetClickCallback(function ()
            TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex, false)
        end)
    end
end

function UIHomeIdentityCartDetailPop.GetItemCountInBag()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 0
    end

    local dwID = DataModel.dwID
    local tInfo = DataModel.GetFoodInfo(dwID)
    if not tInfo then
        return 0
    end
    local nCount = hPlayer.GetItemAmountInPackage(tInfo.dwItemType, tInfo.dwIndex)
    local nLockerCount = GDAPI_GetLockerItemCount(HLORDER_TYPE.COOK, tInfo.dwItemType, tInfo.dwIndex)
    return nCount + nLockerCount
end

function UIHomeIdentityCartDetailPop:CheckNumEditMax(bSetMax)
    local nFrameMode = DataModel.GetFrameMode()
    local nMax = DataModel.nMaxBuy
    if nFrameMode == FRAME_MODE.SELL then
        local nStack    = GDAPI_GetMaxFoodStack()
        local nBagCount = self.GetItemCountInBag()
        DataModel.nMaxSell = math.min(nStack, nBagCount + DataModel.nMaxBuy)
        nMax = DataModel.nMaxSell
    end
    local nCount = tonumber(UIHelper.GetText(self.EditPaginateNum)) or 0
    if nCount > nMax or bSetMax then
        UIHelper.SetText(self.EditPaginateNum, nMax)
    end
end

function UIHomeIdentityCartDetailPop:UpdateEditInfo()
    local nTotalMoney, nIncome = 0, 0
    local tbTaxMoney, tbMoney = {}, {}
    local nFrameMode = DataModel.GetFrameMode()
    local bSell = nFrameMode == FRAME_MODE.SELL
    local LabelMoney = bSell and self.EditPaginateMoney or self.LabelMoney

    DataModel.nMoney = tonumber(UIHelper.GetString(LabelMoney)) or 0
    DataModel.nCount = tonumber(UIHelper.GetString(self.EditPaginateNum)) or 0
    nTotalMoney = DataModel.nMoney * DataModel.nCount

    if bSell then
        nTotalMoney, nIncome = GDAPI_CalculateIncome(nTotalMoney)
    else
        nTotalMoney = nTotalMoney * 10000
    end

    tbTaxMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nIncome)}
    tbMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nTotalMoney)}

    for i = 1, 3, 1 do
        UIHelper.SetString(self.tbTexLabel[i], tbTaxMoney[i])
        UIHelper.SetString(self.tbProfitLabel[i], tbMoney[i])
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrencyProfit, true, false)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrencyTex, true, false)
    UIHelper.SetText(self.EditPaginateNum, DataModel.nCount)    --再设置一下去掉开头多余的0
    UIHelper.SetText(self.EditPaginateMoney, DataModel.nMoney)
end

function UIHomeIdentityCartDetailPop:SellNewFood()
    local dwOwnerID  = DataModel.dwOwnerID
    local dwID       = DataModel.dwID
    local nIndex     = DataModel.nIndex
    local nMoney     = DataModel.nMoney
    local nCount     = DataModel.nCount
    local bFurniture = DataModel.bFurniture
    if not dwID or dwID == 0 then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_NEED_FOOD)
        return
    end

    if nMoney < 10 then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_MONEY_LEGAL)
        return
    end

    if nCount <= 0 then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_COUNT_LEGAL)
        return
    end

    if bFurniture then
        RemoteCallToServer("On_HomeLand_SellLandFood", nIndex, dwID, nCount, nMoney)
    else
        RemoteCallToServer("On_HomeLand_SellNewFood", nIndex, dwID, nCount, nMoney)
    end
end

function UIHomeIdentityCartDetailPop:UpdateSellFood()
    local dwOwnerID = DataModel.dwOwnerID
    local dwID      = DataModel.dwID
    local nIndex    = DataModel.nIndex
    local nMoney    = DataModel.nMoney
    local nCount    = DataModel.nCount

    if nMoney < 10 then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_MONEY_LEGAL)
        return
    end

    if nCount <= 0 then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_COUNT_LEGAL)
        return
    end

    RemoteCallToServer("On_HomeLand_UpdateSellFood", nIndex, dwID, nCount, nMoney)
end

function UIHomeIdentityCartDetailPop:BuyFood(bEatNow)
    local dwOwnerID  = DataModel.dwOwnerID
    local dwID       = DataModel.dwID
    local nIndex     = DataModel.nIndex
    local nCount     = DataModel.nCount
    local nMoney     = DataModel.nMoney
    local bFurniture = DataModel.bFurniture

    local szMsg  = "是否确认消耗%s进行购买%sx %d？"
    if bEatNow then
        szMsg  = "是否确认消耗%s进行食用%sx %d？"
    end

    local tFoodInfo   = DataModel.GetFoodInfo(dwID)
    if not tFoodInfo then
        return
    end
    local dwTabType = tFoodInfo.dwItemType
    local dwIndex   = tFoodInfo.dwIndex
    local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    if tItemInfo then
        local szName = string.format("<color=%s>【%s】</c>", ItemQualityColor[tItemInfo.nQuality], UIHelper.GBKToUTF8(tItemInfo.szName))
        local szMoneyText = UIHelper.GetMoneyText(nMoney * nCount * 10000, nil, nil, false)
        szMsg = string.format(szMsg, szMoneyText, szName, nCount)
    end

    UIHelper.ShowConfirm(szMsg, function ()
        if bFurniture then
            if bEatNow then
                RemoteCallToServer("On_HomeLand_EatLandFood", dwOwnerID, nIndex, dwID, nCount, nMoney)
            else
                RemoteCallToServer("On_HomeLand_PackageLandFood", dwOwnerID, nIndex, dwID, nCount, nMoney)
            end
        else
            if bEatNow then
                RemoteCallToServer("On_HomeLand_EatFood", dwOwnerID, nIndex, dwID, nCount, nMoney)
            else
                RemoteCallToServer("On_HomeLand_PackageFood", dwOwnerID, nIndex, dwID, nCount, nMoney)
            end
        end
        UIMgr.Close(VIEW_ID.PanelDiningCarCuisinePop)
    end, nil, true)
end

--取回推车食物
function UIHomeIdentityCartDetailPop:TakeBackFood()
    local dwID      = DataModel.dwID
    local nIndex    = DataModel.nIndex
    if not dwID or not nIndex then
        return
    end
    RemoteCallToServer("On_HomeLand_TakeBackFood", nIndex, dwID)
end
return UIHomeIdentityCartDetailPop