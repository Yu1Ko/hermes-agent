-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestAwardView
-- Date: 2022-11-17 19:29:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIQuestAwardView
local UIQuestAwardView = class("UIQuestAwardView")

local CurrencyNameToType =
{
    ["战阶"] = CurrencyType.TitlePoint,
    ["金钱"] = CurrencyType.Money,
    ["修为"] = CurrencyType.Train,
    ["精力"] = CurrencyType.Vigor,
    ["威名"] = CurrencyType.Prestige,
    ["威望"] = CurrencyType.Prestige,
    ["侠行点"] = CurrencyType.Justice,
    ["通宝"] = CurrencyType.Coin,
    ["商城积分"] = CurrencyType.StorePoint,
    ["帮会资金"] = CurrencyType.GangFunds,
    ["侠义值"] = CurrencyType.Justice,
    ["声望"] = CurrencyType.Reputation,
    ["载具资源"] = CurrencyType.TongResource,
    ["休闲点"] = CurrencyType.Contribution,
    -- ["方士身份阅历"] = CurrencyType.IdentityExp,
    ["鸣铮玉"] = CurrencyType.ArenaTowerAward,
    ["天机筹"] = CurrencyType.TianJiToken,
}

function UIQuestAwardView:OnEnter(szName, nCount, nItemTabType, nItemIndex, bMail, bReputation, nIconID, bClickNotSelected)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if szName and nCount then
        self.nItemTabType = nItemTabType
        self.nItemIndex = nItemIndex
        self.szName = szName
        self.nCount = nCount
        self.bMail = bMail or false
        self.bReputation = bReputation or false
        self.nIconID = nIconID
        self.bClickNotSelected = bClickNotSelected
        if bClickNotSelected == nil then self.bClickNotSelected = true end
        self:UpdateInfo()
    end
end

function UIQuestAwardView:OnExit()
    self.bInit = false
    if self.scriptItemIcon then
        UIHelper.RemoveFromParent(self.scriptItemIcon._rootNode, true)
    end
    self.scriptItemIcon = nil
    self:UnRegEvent()
end

function UIQuestAwardView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogItem, EventType.OnSelectChanged, function(_, bSelected)
        local nTabType, nTabID = nil, nil
        if self.nBox and self.nIndex then
            nTabType, nTabID = self.nBox, self.nIndex
        elseif self.nItemTabType and self.nItemIndex then
            nTabType, nTabID = self.nItemTabType, self.nItemIndex
        elseif self.nIconID then

        else
            nTabType, nTabID = "CurrencyType", self.szCurrencyName
        end
        if bSelected then
            if self.onClickCallback then self.onClickCallback(nTabType, nTabID, self.nCount) end
        else
            if self.onClickNotSelectCallBack then self.onClickNotSelectCallBack(nTabType, nTabID, self.nCount) end
        end
    end)

    UIHelper.BindUIEvent(self.TogItem, EventType.OnClick, function()
        local nTabType, nTabID = nil, nil
        if self.nBox and self.nIndex then
            nTabType, nTabID = self.nBox, self.nIndex
        elseif self.nItemTabType and self.nItemIndex then
            nTabType, nTabID = self.nItemTabType, self.nItemIndex
        elseif self.nIconID then

        else
            nTabType, nTabID = "CurrencyType", self.szCurrencyName
        end
        if self.fSingleClickCallBack then
            self.fSingleClickCallBack(nTabType, nTabID, self.nCount)
        end
    end)
end

function UIQuestAwardView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestAwardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestAwardView:UpdateInfo()

    local bMoney = self.szName == g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY

    UIHelper.SetString(self.LabelProp, self.szName, 6)
    UIHelper.SetVisible(self.WidgetItemNum, not bMoney)
    UIHelper.SetVisible(self.LayoutMoney, bMoney)

    local tItemInfo = nil
    if self.nItemTabType and self.nItemIndex then
        tItemInfo = ItemData.GetItemInfo(self.nItemTabType, self.nItemIndex)
    end
    local bBook = tItemInfo and tItemInfo.nGenre == ITEM_GENRE.BOOK
    UIHelper.SetVisible(self.LabelTxt, self.nCount ~= 0 and not bBook and not bMoney)--策划要求奖励为0不显示数量
    if bMoney then
        self:UpdateMoney()
    elseif not self.bShowEquipSubName then
        UIHelper.SetString(self.LabelTxt, tostring(self.nCount))
    elseif tItemInfo and tItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
        local szText = g_tStrings.tEquipTypeNameTable[tItemInfo.nSub]
        if tItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
            tItemInfo.nSub == EQUIPMENT_SUB.RANGE_WEAPON or
            tItemInfo.nSub == EQUIPMENT_SUB.ARROW
        then
            szText = g_tStrings.WeapenDetail[tItemInfo.nDetail] or g_tStrings.UNKNOWN_WEAPON
        end
        UIHelper.SetString(self.LabelTxt, szText)
    else
        UIHelper.SetString(self.LabelTxt, "")
    end

    if not self.scriptItemIcon then
        ---@type UIItemIcon
        self.scriptItemIcon = UIHelper.AddPrefab(self:GetWidgetItemPrefabId(), self.WidgetItemIcon)
    else
        self.scriptItemIcon:OnPoolRecycled()
    end
    if self.nItemTabType and self.nItemIndex then
        self.scriptItemIcon:OnInitWithTabID(self.nItemTabType, self.nItemIndex)
    elseif self.nBox and self.nIndex then
        self.scriptItemIcon:OnInit(self.nBox,self.nIndex)
    elseif self.nIconID then
        self.scriptItemIcon:OnInitWithIconID(self.nIconID)
    elseif bMoney then
        self.szCurrencyName = CurrencyType.Money
        self.scriptItemIcon:OnInitCurrency(self.szCurrencyName, self.nCount)
    else
        local convertTab = Currency_Base.GetCurrencyChineseNameToTypeTable()
        self.szCurrencyName = convertTab[self.szName] or CurrencyNameToType[self.szName] or self.szName
        self.scriptItemIcon:OnInitCurrency(self.szCurrencyName, self.nCount, self.bReputation)
    end

    if self.nCount == 0 then
        self.scriptItemIcon:SetLabelCount(nil)--策划要求奖励为0不显示数量
    end

    if self.bClickNotSelected then
        self:SetClickNotSelect(true)
    else
        self:SetIconClickNotSelect(true)
    end
    self.scriptItemIcon:SetToggleGroupIndex(ToggleGroupIndex.BagUpItem)
    self.scriptItemIcon:SetClickCallback(function(nTabType, nTabID)
        if not self.TogItem and self.onClickCallback then
            self.onClickCallback(nTabType, nTabID ,self.nCount)
        end
    end)

    --使点击道具图标时不会隐藏原先的Tip
    self.scriptItemIcon:SetTouchDownHideTips(false)
    self.scriptItemIcon:SetToggleSwallowTouches(false)

    local bSwallow = false
    if self.bToggleSwallow ~= nil then bSwallow = self.bToggleSwallow end
    UIHelper.SetSwallowTouches(self.TogItem, bSwallow)
end

function UIQuestAwardView:SetItemBoxAndX(nBox,nIndex)
    self.nBox = nBox
    self.nIndex = nIndex
end

function UIQuestAwardView:SetLabelText(szText)
    UIHelper.SetString(self.LabelTxt, szText)
end

function UIQuestAwardView:SetShowEquipSubName(bShowEquipSubName)
    self.bShowEquipSubName = bShowEquipSubName
end

function UIQuestAwardView:ClearItemClickCallback()
    if self.scriptItemIcon then
        self.scriptItemIcon:SetClickCallback(nil)
    end
end

function UIQuestAwardView:ShowBindIcon(bShow)
    if self.scriptItemIcon then
        self.scriptItemIcon:ShowBindIcon(bShow)
    end
end

function UIQuestAwardView:SetIconSwallowTouches(bSwallow)
    if self.scriptItemIcon then
        UIHelper.SetSwallowTouches(self.TogItem, bSwallow)
    else
        self.bToggleSwallow = bSwallow
    end
end

function UIQuestAwardView:SetCurrency(szCurrency, nCount)
    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(self:GetWidgetItemPrefabId(), self.WidgetItemIcon)
    end
    self.scriptItemIcon:SetIconBySpriteFrameName(CurrencyData.tbImageBigIcon[szCurrency])
    self.scriptItemIcon:SetLabelCount(nil)
    UIHelper.SetString(self.LabelProp, szCurrency, 6)
    UIHelper.SetString(self.LabelTxt, tostring(nCount))
    UIHelper.SetVisible(self.WidgetItemNum, true)
    UIHelper.SetVisible(self.LayoutMoney, false)
end

function UIQuestAwardView:SetIconCount(nCount)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetLabelCount(nCount)
    end
end

function UIQuestAwardView:UpdateMoney()
    local nBullion, nGold, nSilver, nCopper = QuestData.MoneyToBullionGoldSilverAndCopper(self.nCount)
    if self.bMail then
        nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(self.nCount)
        if nGold >= 10000 then
            nBullion = math.floor(nGold/10000)
            nGold = nGold - (nBullion * 10000)
        end
    end
    local nUIIndex = 1


    local UI = nUIIndex <= #self.tbWidgetMoney and self.tbWidgetMoney[nUIIndex] or nil
    if nBullion ~= 0 and UI then
        nUIIndex = nUIIndex + 1
        UIHelper.SetVisible(UI, true)
        local scriptView = UIHelper.GetBindScript(UI)
        scriptView:OnEnter(nBullion, "Bullion")
        UIHelper.LayoutDoLayout(UI)
    end

    local UI = nUIIndex <= #self.tbWidgetMoney and self.tbWidgetMoney[nUIIndex] or nil
    if nGold ~= 0 and UI then
        nUIIndex = nUIIndex + 1
        UIHelper.SetVisible(UI, true)
        local scriptView = UIHelper.GetBindScript(UI)
        scriptView:OnEnter(nGold, "Gold")
        UIHelper.LayoutDoLayout(UI)
    end

    local UI = nUIIndex <= #self.tbWidgetMoney and self.tbWidgetMoney[nUIIndex] or nil
    if nSilver ~= 0 and UI then
        nUIIndex = nUIIndex + 1
        UIHelper.SetVisible(UI, true)
        local scriptView = UIHelper.GetBindScript(UI)
        scriptView:OnEnter(nSilver, "Silver")
        UIHelper.LayoutDoLayout(UI)
    end

    local UI = nUIIndex <= #self.tbWidgetMoney and self.tbWidgetMoney[nUIIndex] or nil
    if nCopper ~= 0 and UI then
        nUIIndex = nUIIndex + 1
        UIHelper.SetVisible(UI, true)
        local scriptView = UIHelper.GetBindScript(UI)
        scriptView:OnEnter(nCopper, "Copper")
        UIHelper.LayoutDoLayout(UI)
    end

    for nIndex = nUIIndex, #self.tbWidgetMoney do
        UIHelper.SetVisible(self.tbWidgetMoney[nIndex], false)
    end
    UIHelper.LayoutDoLayout(self.LayoutMoney)
end

function UIQuestAwardView:SetClickCallback(onClickCallback)
    self.onClickCallback = onClickCallback
end

function UIQuestAwardView:SetClickNotSelectCallback(onClickNotSelectCallBack)
    self.onClickNotSelectCallBack = onClickNotSelectCallBack
end

function UIQuestAwardView:SetSingleClickCallback(fSingleClickCallBack)
    self.fSingleClickCallBack = fSingleClickCallBack
end


function UIQuestAwardView:SetSelected(bSelectted)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetSelected(bSelectted)
    end
    UIHelper.SetSelected(self.TogItem, bSelectted)
end

function UIQuestAwardView:RawSetSelected(bSelectted)
    if self.scriptItemIcon then
        self.scriptItemIcon:RawSetSelected(bSelectted)
    end
    UIHelper.SetSelected(self.TogItem, bSelectted, false)
end

function UIQuestAwardView:GetScriptItemIcon()
    return self.scriptItemIcon
end

function UIQuestAwardView:SetIconGray(bGray)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetIconGray(bGray)
    end
end

function UIQuestAwardView:SetIconOpacity(nOpacity)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetIconOpacity(nOpacity)
    end
end

function UIQuestAwardView:SetClickNotSelect(bNotSelect)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetClickNotSelected(bNotSelect)
    end
    UIHelper.SetVisible(self.WidgetUpBg, not bNotSelect)
end

function UIQuestAwardView:SetIconClickNotSelect(bNotSelect)
    if self.scriptItemIcon then
        self.scriptItemIcon:SetClickNotSelected(bNotSelect)
    end
end

function UIQuestAwardView:SetLineVis(bShowLine)
    if self.ImgLine then
        UIHelper.SetVisible(self.ImgLine, bShowLine)
    end
end

function UIQuestAwardView:SetImgAwardBgVis(bShowAwardBg)
    if self.ImgAwardBg then
        UIHelper.SetVisible(self.ImgAwardBg, bShowAwardBg)
    end
end

function UIQuestAwardView:SetImgCHooseVis(bChoose)
    if self.ImgChoose then
        UIHelper.SetVisible(self.ImgChoose, bChoose)
    end
end

function UIQuestAwardView:AddToggleGroup(ToggleGroup)
    if ToggleGroup then
        UIHelper.ToggleGroupAddToggle(ToggleGroup, self.TogItem)
    end
end

function UIQuestAwardView:GetWidgetItemPrefabId()
    local nPrefabId = PREFAB_ID.WidgetItem_80

    if self._nPrefabID == PREFAB_ID.WidgetAwardItemPartner then
        -- 侠客出行的奖励使用60的脚本
        nPrefabId = PREFAB_ID.WidgetItem_60
    end
    
    return nPrefabId
end

return UIQuestAwardView