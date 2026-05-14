-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSeasonChallengeBuyPop
-- Date: 2026-04-06 10:12:53
-- Desc: ?
-- ---------------------------------------------------------------------------------
local VIEW_SLOT_COUNT = 3
local CLASS_LIST =
{
	[1] = { szCurrencyName = "SeasonHonorXiuXian", nCurrencyCode = ShopData.CurrencyCode.SeasonHonorXiuXian, szRewardType = "HonorPanelPVX" },
	[2] = { szCurrencyName = "SeasonHonorMiJing", nCurrencyCode = ShopData.CurrencyCode.SeasonHonorMiJing, szRewardType = "HonorPanelPVE" },
	[3] = { szCurrencyName = "SeasonHonorPVP", nCurrencyCode = ShopData.CurrencyCode.SeasonHonorPVP, szRewardType = "HonorPanelPVP" },
}

local szHorseIconPath = "Resource/OperationCenter/FriendRecruit/Img_FriRecGift_FeiXingSaTa_Zu.png"
local UIPanelSeasonChallengeBuyPop = class("UIPanelSeasonChallengeBuyPop")

function UIPanelSeasonChallengeBuyPop:OnEnter(nClass)
    self.nClass = nClass
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local bCanGet, nSlot = CollectionData.HasCanGetHorse(nClass)
    if bCanGet and (Storage.ChallengeHorseSlot[nClass] or 0) ~= nSlot then
        Storage.ChallengeHorseSlot[nClass] = nSlot
        Storage.ChallengeHorseSlot.Dirty()
        Event.Dispatch("ChallengeHorseRedDotChange")
    end

    self:UpdateInfo(nClass)
end

function UIPanelSeasonChallengeBuyPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSeasonChallengeBuyPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSeasonChallengeBuyPop:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseCurrencyTip()
        self:CloseTip()
    end)

    Event.Reg(self, "CB_SH_ExchangeMount", function(nSlot)
        self:UpdateInfo(self.nClass)

        local tMountList = CollectionData.GetMountList(self.nClass)
        local tMount = tMountList[nSlot]
        if tMount then
            local tNewInfo = {}
            local tData = {}
            tData.nTabType = tMount.dwTabType
            tData.nTabID = tMount.dwIndex
            tData.nCount = 1 -- 兑换的奖励通常数量为1
            table.insert(tNewInfo, tData)
            TipsHelper.ShowRewardList(tNewInfo)
        end
    end)

    Event.Reg(self, "EVENT_LINK_NOTIFY", function ()
        local szLinkInfo = arg0
        local szLinkEvent, szLinkArg = szLinkInfo:match("(%w+)/(.*)")
        szLinkEvent = szLinkEvent or szLinkInfo
        if szLinkEvent == "SourceTrade" or szLinkEvent == "GameGuidePanel" then
            UIMgr.Close(self)
        end
    end)
end

function UIPanelSeasonChallengeBuyPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelSeasonChallengeBuyPop:UpdateInfo(nClass)
    UIHelper.RemoveAllChildren(self.LayouSeasonChallengeBugCell)
    self.tbCellScripts = {}

    for i = 1, VIEW_SLOT_COUNT do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonChallengeBuyCell, self.LayouSeasonChallengeBugCell)
        if tbScript then
            self.tbCellScripts[i] = tbScript
            self:UpdateSingleCell(i, tbScript)
        end
    end

    self:UpdateCurrency(nClass)
end

function UIPanelSeasonChallengeBuyPop:UpdateSingleCell(nSlot, tbScript)
    local nClass = self.nClass
    local nFragment = GDAPI_SH_GetMountFragmentCount(nClass)
    local _, tRewardLv = GDAPI_SH_GetBaseInfo(nClass)
    local tMountList = CollectionData.GetMountList(nClass)

    local tMount = tMountList[nSlot]
    local tPreMount = nSlot > 1 and tMountList[nSlot - 1] or nil
    local dwTabType = tMount.dwTabType
    local dwIndex = tMount.dwIndex
    local tState = CollectionData.GetMountState(nClass, nSlot, tRewardLv, nFragment, tMountList)
    local szRewardType = CLASS_LIST[nClass] and CLASS_LIST[nClass].szRewardType or ""
    local tbImgInfoList = Table_GetSeasonReward(szRewardType)
    local tItemInfo = GetItemInfo(dwTabType, dwIndex)
    local szName = tItemInfo and UIHelper.GBKToUTF8(tItemInfo.szName) or ""
    local szBtnText = tState.bReceived and g_tStrings.STR_HONOR_CHALLENGE_EXCHANGE
                        or tState.bUnlocked and g_tStrings.STR_ARENA_LOCK
                        or tState.bCanExchange and g_tStrings.STR_HONOR_CHALLENGE_EXCHANGE_NOW
                        
    local szCost = string.format("%s/%s", nFragment, tState.nCost)
    local szLockTips = tbImgInfoList and tbImgInfoList[nSlot] and tbImgInfoList[nSlot].szLockTips or ""
    UIHelper.SetTexture(tbScript.ImgIcon, tbImgInfoList and tbImgInfoList[nSlot] and tbImgInfoList[nSlot].szMobilePath or "")
    UIHelper.SetString(tbScript.LabelName, szName)
    UIHelper.SetString(tbScript.LabelAll, szBtnText)
    UIHelper.SetEnable(tbScript.BtnBuy, tState.bCanExchange)
    UIHelper.SetNodeGray(tbScript.BtnBuy, not tState.bCanExchange, true)
    UIHelper.SetString(tbScript.LabelInfo, szCost)
    -- UIHelper.SetVisible(tbScript.imgBgHint, bLock)
    UIHelper.SetString(tbScript.LabelHint, UIHelper.GBKToUTF8(szLockTips))

    -- 处理货币图标（避免重复创建导致重叠）
    UIHelper.RemoveAllChildren(tbScript.WidgetCurrency)
    local tFragmentScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, tbScript.WidgetCurrency)
    local szCurrencyName = CLASS_LIST[nClass].szCurrencyName
    tFragmentScript:OnInitCurrency(szCurrencyName, tState.nCost)
    tFragmentScript:SetToggleSwallowTouches(false)
    tFragmentScript:SetClickCallback(function()
        self:OpenCurrencyTip(tFragmentScript, nClass)
    end)
    tFragmentScript:SetToggleGroupIndex(ToggleGroupIndex.SeasonFragment)
    if tPreMount then
        UIHelper.SetVisible(tbScript.ImgAdd, true)
        UIHelper.SetVisible(tbScript.WidegtItem44, true)
        local tbPreItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, tbScript.WidegtItem44)
        local dwPreTabType = tPreMount.dwTabType
        local dwPreIndex = tPreMount.dwIndex
        tbPreItem:OnInitWithTabID(dwPreTabType, dwPreIndex)
        local tItemInfo = GetItemInfo(dwPreTabType, dwPreIndex)
        local nIconID = Table_GetItemIconID(tItemInfo.nUiId)
        UIHelper.SetItemIconByIconID(tbPreItem.ImgIcon, nIconID)
        tbPreItem:SetClickCallback(function()
            self:OpenTip(tbPreItem, dwPreTabType, dwPreIndex)
        end)
        tbPreItem:SetToggleGroupIndex(ToggleGroupIndex.SeasonFragment)
    else
        UIHelper.SetVisible(tbScript.ImgAdd, false)
        UIHelper.SetVisible(tbScript.WidegtItem44, false)
    end
    Timer.AddFrame(self, 2, function ()
        UIHelper.LayoutDoLayout(tbScript.LayoutMoney)
    end)

    
    UIHelper.BindUIEvent(tbScript.BtnBuy, EventType.OnClick, function()
        local szMessage = string.format("确定兑换[%s]吗?", szName)
        UIHelper.ShowConfirm(szMessage, function()
            RemoteCallToServer("On_SH_ExchangeMount", nClass, nSlot)
        end)
    end)

    UIHelper.BindUIEvent(tbScript.BtnIcon, EventType.OnClick, function()
        local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, tbScript._rootNode)
        scriptItemTip:OnInitWithTabID(dwTabType, dwIndex)
        scriptItemTip:SetBtnState({})
    end)
end

function UIPanelSeasonChallengeBuyPop:OpenCurrencyTip(tFragmentScript, nClass)
    self:CloseCurrencyTip()
    local nCurrencyCode = CLASS_LIST[nClass].nCurrencyCode
    CurrencyData.ShowCurrencyHoverTips(tFragmentScript._rootNode, ShopData.GetCurrencyCodeToType(nCurrencyCode))
    self.scriptCurrencyIcon = tFragmentScript
end

function UIPanelSeasonChallengeBuyPop:CloseCurrencyTip()
    if self.scriptCurrencyIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptCurrencyIcon:RawSetSelected(false)
        self.scriptCurrencyIcon = nil
    end
end

function UIPanelSeasonChallengeBuyPop:OpenTip(scriptView, nTabType, nTabID)
    self:CloseTip()
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.TOP_CENTER)
    scriptItemTip:OnInitWithTabID(nTabType, nTabID)
    scriptItemTip:SetBtnState({})
    self.scriptIcon = scriptView
end

function UIPanelSeasonChallengeBuyPop:CloseTip()
    if self.scriptIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptIcon:RawSetSelected(false)
        self.scriptIcon = nil
    end
end

function UIPanelSeasonChallengeBuyPop:UpdateCurrency(nClass)
    UIHelper.RemoveAllChildren(self.LayoutCurrency)
    local nCurrencyCode = CLASS_LIST[nClass].nCurrencyCode
    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, nCurrencyCode)
end

return UIPanelSeasonChallengeBuyPop