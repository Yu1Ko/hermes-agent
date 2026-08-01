-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryView
-- Date: 2023-04-10 11:26:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MULTI_DRAW_COUNT = 10

local LIMIT_ITEM_TYPE = 5
local LIMIT_ITEM_INDEX = 71914
local LIMIT_ITEM_COUNT = 15

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.nPoolIndex        = -1
    DataModel.nMaxDrawCount     = -1
    DataModel.nLeftCard         = 0
    DataModel.nSelectCardIndex  = nil
    DataModel.bIsLotteryAllowed = true
    DataModel.nPreviewPage      = 0
    DataModel.nLastGiftPage     = 0
    DataModel.nCostRewards      = nil
end

function DataModel.UnInit()
    DataModel.nPoolIndex        = nil
    DataModel.nMaxDrawCount     = nil
	DataModel.nLeftCard         = nil
    DataModel.nSelectCardIndex  = nil
    DataModel.bIsLotteryAllowed = nil
    DataModel.nPreviewPage      = nil
    DataModel.nLastGiftPage     = nil
    DataModel.nCostRewards      = nil
end

function DataModel.SetSelPoolIndex(nIndex)
    DataModel.nPoolIndex = nIndex

    local tPoolInfo = Table_GetPointsDrawPoolInfo(nIndex)
    if tPoolInfo then
        DataModel.nMaxDrawCount = tPoolInfo.nMaxDrawCount
    end
end

function DataModel.GetSelPoolIndex()
    return DataModel.nPoolIndex
end

function DataModel.GetSelPoolMaxDraw()
    return DataModel.nMaxDrawCount
end

function DataModel.SetCostRewards(nCostRewards)
    DataModel.nCostRewards = nCostRewards
end

function DataModel.GetCostRewards()
    return DataModel.nCostRewards
end

function DataModel.SetPreviewPage(nPage)
    DataModel.nPreviewPage = nPage
end

function DataModel.GetPreviewPage()
    return DataModel.nPreviewPage
end

function DataModel.IsPoolInOpenTime(nIndex)
    return CoinShopData.IsDrawPoolOnTime(nIndex)
end

function DataModel.IsFullDrawCount(nIndex)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tPoolInfo = Table_GetPointsDrawPoolInfo(nIndex)
    if not tPoolInfo then
        return
    end

    local nCount = On_DrawCardGetCount(pPlayer, nIndex)
    local nMaxDrawCount = tPoolInfo.nMaxDrawCount
    local bFullDrawCount = nCount >= nMaxDrawCount
    return bFullDrawCount
end

function DataModel.GetDateText(nTime)
    local tTime = TimeToDate(nTime)
	local szMinute = string.format("%02d", tTime.minute)
	local szText = FormatString(g_tStrings.STR_TIME_6, tTime.year, tTime.month, tTime.day, tTime.hour, szMinute)
	return szText
end

function DataModel.ApplyDrawGiftList(nDrawCount)
    local CoinShopDraw = GetCoinShopDraw()
    local nSelPoolIndex = DataModel.GetSelPoolIndex()
    return CoinShopDraw.DrawRequest(nSelPoolIndex, nDrawCount)
end

function DataModel.SetIsLotteryAllowed(bIsLotteryAllowed)
    DataModel.bIsLotteryAllowed = bIsLotteryAllowed
end

function DataModel.IsLotteryAllowed()
    return DataModel.bIsLotteryAllowed
end

function DataModel.SetCurrencyNum(nCoinNum, nTimeCardNum, nMonthCardNum)
    DataModel.nGetCoin      = nCoinNum
    DataModel.nTimeCardNum  = nTimeCardNum
    DataModel.nMonthCardNum = nMonthCardNum
end

function DataModel.GetCurrencyNum()
    return DataModel.nGetCoin, DataModel.nTimeCardNum, DataModel.nMonthCardNum
end

-----------------------------View------------------------------
local UICoinShopLotteryView = class("UICoinShopLotteryView")

function UICoinShopLotteryView:OnEnter()
    self.tPoolList = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)

    DataModel.Init()
    self:InitPoolList()
    self:InitCardList()
    self:UpdateInfo()

    local tStorageInfo = {}
    local tAllPool = Table_GetPointsDrawAllPoolInfo()
    for i, tLine in ipairs(tAllPool) do
        local nIndex = tLine.nIndex
        local tDrawSettings = GetCoinShopDraw().GetDrawSettings(nIndex)
        tStorageInfo[i] = {
            nStartTime = tDrawSettings.nStartTime,
            nEndTime = tDrawSettings.nEndTime,
        }
    end
    Storage.CoinShop.tbPointsDrawPoolInfo = tStorageInfo
    Storage.CoinShop.Flush()
    Event.Dispatch(EventType.OnCoinShopDrawStorageUpdate)
end

function UICoinShopLotteryView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UICoinShopLotteryView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function ()
        local nIndex = DataModel.GetSelPoolIndex()
        UIMgr.Open(VIEW_ID.PanelActivityBanner, 2, nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnQuestion, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHelpPop, 7)
    end)

    UIHelper.BindUIEvent(self.BtnMenuChange, EventType.OnClick, function ()

    end)

    UIHelper.BindUIEvent(self.BtnConvert1, EventType.OnClick, function()
        self:OnClickOpenCard(1)
    end)

    UIHelper.BindUIEvent(self.BtnConvert10, EventType.OnClick, function ()
        self:OnClickOpenCard(self.nCanDrawCount)
    end)

    UIHelper.BindUIEvent(self.BtnGot, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
            return
        end
        local _, nTimeCardNum, nMonthCardNum = DataModel.GetCurrencyNum()
        UIMgr.Open(VIEW_ID.PanelWelfareReturnPop, nTimeCardNum, nMonthCardNum)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function ()
        -- UIMgr.Open(VIEW_ID.PanelExamineRewardPop)
    end)
end

function UICoinShopLotteryView:RegEvent()
    Event.Reg(self, "SYNC_REWARDS", function ()
        self:UpdateMyPoints()
        self:RefreshBtnState()
    end)

    Event.Reg(self, "ON_COIN_SHOP_DRAW_NOTIFY", function (arg0)
        self:OutputErrorMessage(arg0)
    end)

    Event.Reg(self, EventType.OnRewardsDrawGetCoin, function (nCoinNum, nTimeCardNum, nMonthCardNum)
        DataModel.SetCurrencyNum(nCoinNum, nTimeCardNum, nMonthCardNum)
        self:ShowCurrencyNum()
    end)

    Event.Reg(self, EventType.OnRewardsDrawGetRewardsList, function (nPoolIndex, tLevelList)
        self:GetRewardsListCallBack(nPoolIndex, tLevelList)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)
end

function UICoinShopLotteryView:UnRegEvent()
    Event.UnRegAll()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryView:InitPoolList()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    UIHelper.RemoveAllChildren(self.LayoutTab)
    self.tPoolList = {}
    local tAllPool = Table_GetPointsDrawAllPoolInfo()
    local tStorage
    local bSelCollect = false
    for i, tLine in ipairs(tAllPool) do
        local nIndex = tLine.nIndex
        if DataModel.IsPoolInOpenTime(nIndex) then
            if not self.tPoolList[i] then
                self.tPoolList[i] = {}
            end
            local tPool = self.tPoolList[i]
            if not tPool.tabScript then
                tPool.tabScript = UIHelper.AddPrefab(PREFAB_ID.WidgetIntegralLotteryTab, self.LayoutTab, function (bSelected)
                    if bSelected then
                        local nSelPoolIndex = DataModel.GetSelPoolIndex()
                        if tPool.nIndex == nSelPoolIndex then
                            return
                        end
                        DataModel.SetSelPoolIndex(tPool.nIndex)
                        self:InitCardList()
                        self:UpdateInfo()
                    end
                end)
            end
            UIHelper.SetString(tPool.tabScript.LabelNormal01, UIHelper.GBKToUTF8(tLine.szName))
            UIHelper.SetString(tPool.tabScript.LabelUp01, UIHelper.GBKToUTF8(tLine.szName))
            tPool.nIndex = nIndex
            tPool.bCollect = DataModel.IsFullDrawCount(nIndex)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tPool.tabScript.ToggleTab01)
            local nSelIndex = DataModel.GetSelPoolIndex()
            if (nSelIndex == -1) or (bSelCollect and not tPool.bCollect) then
                DataModel.SetSelPoolIndex(nIndex)
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, tPool.tabScript.ToggleTab01)
                bSelCollect = tPool.bCollect
            end
        end
    end
    self:UpdateAllPollItemState()
    UIHelper.LayoutDoLayout(self.LayoutTab)
end

function UICoinShopLotteryView:UpdateAllPollItemState()
    for nIndex, tPool in pairs(self.tPoolList) do
        tPool.bCollect = DataModel.IsFullDrawCount(nIndex)
        UIHelper.SetVisible(tPool.tabScript.ImgGet, tPool.bCollect)
    end
end

function UICoinShopLotteryView:InitCardList()
    self.tCardScriptList = {}
    UIHelper.RemoveAllChildren(self.ScrollviewContent)
    local nPoolIndex = DataModel.GetSelPoolIndex()
    if not nPoolIndex or nPoolIndex == -1 then
        return
    end
    local tRewardList =  Table_GetPointsDrawGiftInfo(nPoolIndex)
    local nDrawCount = On_DrawCardGetCount(g_pClientPlayer, nPoolIndex)
    local nLastItem = 0
    for _, tGift in ipairs(tRewardList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetIntegrallotteryPropCell2, self.ScrollviewContent, tGift)
        local bGet = nDrawCount >= tGift.nLevel
        script:SetGet(bGet, false)
        table.insert(self.tCardScriptList, script)
        if bGet then
            nLastItem = tGift.nLevel
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollviewContent)
    if nLastItem then
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollToIndex(self.ScrollviewContent, nLastItem)
        end)
    else
        UIHelper.ScrollToTop(self.ScrollviewContent)
    end
end

function UICoinShopLotteryView:UpdateInfo()
    self.nCanDrawCount = nil
    local nSelIndex = DataModel.GetSelPoolIndex()
    local tPoolInfo = Table_GetPointsDrawPoolInfo(nSelIndex)
    if not tPoolInfo then
        return
    end
    self:UpdateAllPollItemState()
    local tDrawSettings = GetCoinShopDraw().GetDrawSettings(nSelIndex)
    if not tDrawSettings then
        return
    end
    DataModel.SetCostRewards(tDrawSettings.nCostRewards)
    self:UpdateMyPoints()
    self:UpdateExtraGiftProgress()
    RemoteCallToServer("On_RewardsDraw_GetCoin")

    UIHelper.SetVisible(self.ImgRole, true)
    UIHelper.SetVisible(self.ImgNormalTitle, false)
    local szPath = tPoolInfo.szImgExteriorPath
    szPath = string.gsub(szPath, "ui/Image", "Resource")
    szPath = string.gsub(szPath, ".tga", ".png")
    UIHelper.SetTexture(self.ImgRole, szPath)
    local szTime = ""
    if tDrawSettings.nStartTime ~= -1 and tDrawSettings.nEndTime ~= -1 then
        szTime = DataModel.GetDateText(tDrawSettings.nStartTime) .. g_tStrings.STR_POINTS_DRAW_TO .. DataModel.GetDateText(tDrawSettings.nEndTime)
    end
    UIHelper.SetString(self.LabellIntegralLotteryTime, szTime)
    self:RefreshBtnState()
end

function UICoinShopLotteryView:UpdateMyPoints()
    local nRewards = g_pClientPlayer.GetRewards()
    self.RewardsScript:SetLableCount(nRewards)

    local nCostRewards = DataModel.GetCostRewards()
    local nPointsCanDrawTime = math.floor(nRewards / nCostRewards)
    local nPoolRestTime = 0
    local nSelIndex = DataModel.GetSelPoolIndex()
    if nSelIndex ~= -1 then
        local nCount = On_DrawCardGetCount(g_pClientPlayer, nSelIndex)
        local nMaxDrawCount = DataModel.GetSelPoolMaxDraw()
        nPoolRestTime = math.max(nMaxDrawCount - nCount, 0)
    end
    local nRestDrawTime = math.min(nPointsCanDrawTime, nPoolRestTime)
    local szText = string.format("<color=#5f4e3a>每次兑换消耗</c><color=#5f4e3a>%d</color><color=#5f4e3a>积分，本期可兑换</c><color=#ffe26e>%d</color><color=#5f4e3a>次</color>", nCostRewards, nRestDrawTime)
    UIHelper.SetRichText(self.LabellIntegralLotteryConvertTips, szText)

    UIHelper.SetString(self.LabelAvailableTimes, "可兑换次数：" .. nRestDrawTime)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true)
end

function UICoinShopLotteryView:UpdateExtraGiftProgress()
    local nIndex = DataModel.GetSelPoolIndex()
    UIHelper.SetVisible(self.WidgetAnchorBotton, true)   -- 如果普通也出现，大概率是动画问题
    local nCurDrawCount = On_DrawCardGetCount(g_pClientPlayer, nIndex)
    UIHelper.SetRichText(self.LabelRedeemedNum, string.format("<color=#5F4E3A>已兑换</c><color=#ffffff>%d</c><color=#5F4E3A>次</color>", nCurDrawCount))
    if not self.tExtraGiftScriptList then
        self.tExtraGiftScriptList = {}
        for _, widget in ipairs(self.tbWidgetItemIcon) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widget)
            itemScript:SetClickNotSelected(true)
            table.insert(self.tExtraGiftScriptList, itemScript)
        end
    end
    local tExtraGift = Table_GetPointsDrawPreviewGift(nIndex)
    local tProgressLen = {87.23, 252.23, 417.23, 582.23}
    for i = 1, #tExtraGift do
        local tGiftInfo = tExtraGift[i]
        local itemScript = self.tExtraGiftScriptList[i]
        itemScript:OnInitWithTabID(tGiftInfo.nType, tGiftInfo.dwIndex)
        itemScript:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tips, itemTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                itemTips:OnInitWithTabID(tGiftInfo.nType, tGiftInfo.dwIndex)
                itemTips:SetBtnState({})
                -- local _, nTotalHeight = UIHelper.GetContentSize(itemTips._rootNode)
                -- local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(itemTips.LayoutContentAll)
                tips:SetDisplayLayoutDir(TipsLayoutDir.TOP_CENTER)
                -- tips:SetAnchor(0.5, (nTipsHeight-nTotalHeight*0.5)/nTipsHeight)     --
                -- tips:SetSize(nTipsWidth, nTipsHeight)
                -- tips:UpdatePosByNode(itemScript._rootNode)
            end
        end)

        UIHelper.SetVisible(self.tbWidgetItemGet[i], nCurDrawCount >= tGiftInfo.nDrawCount)
        UIHelper.SetLocalZOrder(self.tbWidgetItemGet[i], 2)
        local nPrevCount = 0
        if tExtraGift[i - 1] then
            local tLastGift = tExtraGift[i - 1]
            nPrevCount = tLastGift.nDrawCount
        end
        if nCurDrawCount >= nPrevCount and nCurDrawCount <= tGiftInfo.nDrawCount then
            local nTotalLen = tProgressLen[#tProgressLen]
            local nPrevLen = tProgressLen[i-1] or 0
            local nNextLen = tProgressLen[i] or nTotalLen
            local nPercent = (nPrevLen + (nCurDrawCount-nPrevCount) * (nNextLen - nPrevLen) / (tGiftInfo.nDrawCount-nPrevCount)) / nTotalLen
            UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, nPercent * 100)
        end
    end
    UIHelper.SetVisible(self.WidgetItemGet1, DataModel.IsFullDrawCount(nIndex))
    UIHelper.LayoutDoLayout(self.LayoutItemIcon)
end

function UICoinShopLotteryView:OnClickOpenCard(nGetCount)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nLimitCount = pPlayer.GetItemAmountInPackage(LIMIT_ITEM_TYPE, LIMIT_ITEM_INDEX)
    if nLimitCount >= LIMIT_ITEM_COUNT then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_POINTS_AWARDS_DRAW_BOX_NUM_MAX)
        TipsHelper.OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_POINTS_AWARDS_DRAW_BOX_NUM_MAX)
        return
    end

    local nCodeRewards = DataModel.GetCostRewards()
    local nCostPoints = nCodeRewards * nGetCount
    local nRewards = pPlayer.GetRewards()
    if nRewards < nCostPoints then
        local szMessage = g_tStrings.STR_POINTS_DRAW[COIN_SHOP_DRAW_ERROR_CODE.NOT_ENOUGH_REWARDS]
        TipsHelper.OutputMessage("MSG_SYS", szMessage)
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", szMessage)
        return
    end

    local szMessage = FormatString(g_tStrings.STR_POINTS_DRAW_OPENALL_CONFIRM, nCostPoints, nGetCount)
    UIHelper.ShowConfirm(szMessage, function()
        self:ApplyOpenCard(nGetCount)
    end)
end

function UICoinShopLotteryView:ApplyOpenCard(nCount)
    if not DataModel.IsLotteryAllowed() then
        return
    end
    DataModel.SetIsLotteryAllowed(false)
    self:RefreshBtnState()

    local nRetCode, szMessage
    nRetCode = DataModel.ApplyDrawGiftList(nCount)
    if nRetCode ~= COIN_SHOP_DRAW_ERROR_CODE.SUCCESS then
        szMessage = g_tStrings.STR_POINTS_DRAW[nRetCode]
        DataModel.SetIsLotteryAllowed(true)
        self:RefreshBtnState()
        TipsHelper.OutputMessage("MSG_SYS", szMessage)
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", szMessage)
    end
end

function UICoinShopLotteryView:GetRewardsListCallBack(nPoolIndex, tLevelList)
    if not nPoolIndex or not tLevelList then
        TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_POINTS_AWARDS_DRAW_FAIL)
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_POINTS_AWARDS_DRAW_FAIL)
        DataModel.SetIsLotteryAllowed(true)
        self:UpdateInfo()
        return
    end


    local nSelPoolIndex = DataModel.GetSelPoolIndex()
    if nSelPoolIndex ~= nPoolIndex then
        return
    end
    local nLastItem
    for _, nLevel in ipairs(tLevelList) do
        local script = self.tCardScriptList[nLevel]
        if script then
            script:SetGet(true, true)
            nLastItem = nLevel
        end
    end
    if nLastItem then
        Timer.Add(self, 1.5, function()
            UIHelper.ScrollToIndex(self.ScrollviewContent, nLastItem)
        end)
    end
    TipsHelper.OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_POINTS_AWARDS_DRAW_SUCCESS)
    DataModel.SetIsLotteryAllowed(true)
    self:UpdateInfo()
end

function UICoinShopLotteryView:RefreshBtnState()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nDrawCostRewards = DataModel.GetCostRewards()
    if not nDrawCostRewards then
        return
    end
    local nSelIndex = DataModel.GetSelPoolIndex()
    local tPoolInfo = Table_GetPointsDrawPoolInfo(nSelIndex)
    if not tPoolInfo then
        return
    end
    local nCount = On_DrawCardGetCount(pPlayer, nSelIndex)
    local nMaxDrawCount = DataModel.GetSelPoolMaxDraw()
    local nLeftCount = math.max(nMaxDrawCount - nCount, 0)
    local bCanDraw
    if nLeftCount == 0 then
        bCanDraw = false
    elseif nLeftCount < MULTI_DRAW_COUNT then
        UIHelper.SetString(self.LabelConvert10, string.format("兑换%d次", nLeftCount))
        bCanDraw = true
    else
        UIHelper.SetString(self.LabelConvert10, string.format("兑换%d次", MULTI_DRAW_COUNT))
        bCanDraw = true
    end
    UIHelper.SetVisible(self.WidgetBtns, bCanDraw)
    UIHelper.SetVisible(self.LabelFinish, not bCanDraw)
    local nCanDrawCount = math.min(nLeftCount, MULTI_DRAW_COUNT)
    local nCostPoints = nDrawCostRewards * nCanDrawCount
    local nRewards = pPlayer.GetRewards()
    UIHelper.SetString(self.LabelPrice1, nDrawCostRewards)
    UIHelper.LayoutDoLayout(self.LayoutConvert1)
    UIHelper.SetString(self.LabelPrice10, nCostPoints)
    UIHelper.LayoutDoLayout(self.LayoutConvert10)
    if bCanDraw and nRewards >= nCostPoints and DataModel.IsLotteryAllowed() then
        UIHelper.SetButtonState(self.BtnConvert10, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConvert10, BTN_STATE.Disable)
    end
    if bCanDraw and nRewards >= nDrawCostRewards and DataModel.IsLotteryAllowed() then
        UIHelper.SetButtonState(self.BtnConvert1, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConvert1, BTN_STATE.Disable)
    end
    self.nCanDrawCount = nCanDrawCount
end

function UICoinShopLotteryView:OutputErrorMessage(nRetCode)
    if nRetCode ~= COIN_SHOP_DRAW_ERROR_CODE.SUCCESS then
        local szMessage = g_tStrings.STR_POINTS_DRAW[nRetCode]
        DataModel.SetIsLotteryAllowed(true)
        self:RefreshBtnState()
        TipsHelper.OutputMessage("MSG_SYS", szMessage)
        TipsHelper.OutputMessage("MSG_ANNOUNCE_RED", szMessage)
    end
end

function UICoinShopLotteryView:ShowCurrencyNum()
    local nCoinNum, nTimeCardNum, nMonthCardNum = DataModel.GetCurrencyNum()
    UIHelper.SetRichText(self.LabelPointCard, string.format("<color=#eebf58>%d</c><color=#c1cfd2>元点卡</color>", nTimeCardNum))
    UIHelper.SetRichText(self.LabelMonthCard, string.format("<color=#eebf58>%d</c><color=#c1cfd2>元月卡</color>", nMonthCardNum))
end

function UICoinShopLotteryView:ClearSelect()
    if self.tCardScriptList then
        for _, cardScript in ipairs(self.tCardScriptList) do
            if cardScript.itemScript then
                cardScript.itemScript:RawSetSelected(false)
            end
        end
    end
    if self.tExtraGiftScriptList then
        for _, giftScript in ipairs(self.tExtraGiftScriptList) do
            giftScript:RawSetSelected(false)
        end
    end
end

return UICoinShopLotteryView