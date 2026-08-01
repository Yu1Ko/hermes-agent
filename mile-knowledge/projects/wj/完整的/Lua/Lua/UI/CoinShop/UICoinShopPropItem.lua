-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPropItem
-- Date: 2022-12-19 09:57:44
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_TIME_LABEL_WIDTH = 130
local TOUCH_THRESHOLD = 400

local UICoinShopPropItem = class("UICoinShopPropItem")

function UICoinShopPropItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopPropItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end

    if self.bChangeColor then
        self:OnSetExitChangeColor()
    end

    if self.bChangeHair then
        if self.tbSub then
            self:OnSubExitChangeHair()
        elseif self.tbSet then
            self:OnSetExitChangeHair()
        end
    end
end

function UICoinShopPropItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPetList, EventType.OnTouchBegan, function(node, x, y)
        self.nTouchBeganX = x
        self.nTouchBeganY = y
    end)

    UIHelper.BindUIEvent(self.TogPetList, EventType.OnTouchEnded, function (node, x, y)
        if not self.nTouchBeganX or not self.nTouchBeganY then
            return
        end
        local dx = x - self.nTouchBeganX
		local dy = y - self.nTouchBeganY
		local dx2 = dx * dx
		local dy2 = dy * dy
		if dx2 + dy2 > TOUCH_THRESHOLD then
            return
        end

        if self.tbRewardsItem then
            self:OnClickRewardsItem()
        elseif self.dwWeaponID then
            self:OnClickWeapon()
        elseif self.tbSet then
            self:OnClickSet()
        elseif self.tbSub then
            self:OnClickSub()
        elseif self.tbAdornmentSet then
            self:OnClickAdornmentSet()
        end
    end)

    UIHelper.BindUIEvent(self.BtnFurnitureDetail, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnCoinShopShowItemDetail, self.tbRewardsItem.dwIntroduceID)
    end)

    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        if self.tbSet then
            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end
            for _, dwID in pairs(self.tbSet.tSub) do
                hPlayer.SetExteriorHideFlag(dwID, EXTERIOR_HIDE_TYPE.HIDE)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function()
        if self.tbSet then
            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end
            for _, dwID in pairs(self.tbSet.tSub) do
                hPlayer.SetExteriorHideFlag(dwID, EXTERIOR_HIDE_TYPE.NOT_HIDE)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnInteraction, EventType.OnClick, function()
        if self.tbRewardsItem then
            local szAnimation = self.tbRewardsItem.szAnimation
            local bSheath = self.tbRewardsItem.bWeaponSheath
            if not szAnimation or szAnimation == "" then
                return
            end
            local nWeaponType = ExteriorCharacter.GetWeaponType()
            FireUIEvent("EXTERIOR_CHARACTER_UPDATE_WEAPON_POS", "CoinShop_View", "CoinShop", bSheath, nWeaponType)
            FireUIEvent("EXTERIOR_CHARACTER_PLAY_ANIMATION", "CoinShop_View", "CoinShop", "once", szAnimation)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClean, EventType.OnClick, function()
        if self.tbSet then
            local tbExteriorInfo = GetExterior().GetExteriorInfo(self.tbSet.tSub[1])
            local tbSetInfo = Table_GetExteriorSet(tbExteriorInfo.nSet)
            local szText = FormatString(g_tStrings.STR_DELETE_SET_EXTERIOR_SURE_TIP, UIHelper.GBKToUTF8(tbSetInfo.szSetName))
            UIHelper.ShowConfirm(szText, function()
                local hPlayer = GetClientPlayer()
                if not hPlayer then
                    return
                end
                for _, dwID in pairs(self.tbSet.tSub) do
                    hPlayer.SetExteriorHideFlag(dwID, EXTERIOR_HIDE_TYPE.DELETE)
                end
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChangeColor, EventType.OnClick, function()
        if not self.tbSet then
            return
        end
        if self.bChangeColor then
            self:OnSetExitChangeColor()
        else
            self:OnSetEnterChangeColor()
        end
    end)

    for i, tog in ipairs(self.tTogColor) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if not self.tbSet then
                return
            end
            if bSelected then
                if self.bInShopView then
                    if i <= #self.tSubGenre then
                        local tSet = self.tSubGenre[i]
                        local bPreviewHair = Storage.CoinShop.bPreviewMatchHair
                        if bPreviewHair then
                            local dwID = tSet.tSub[1]
                            local nMatchHair = CoinShop_GetMatchHair(dwID)
                            if nMatchHair then
                                FireUIEvent("PREVIEW_HAIR", nMatchHair, nil, true, true, false)
                            end
                        end
                        FireUIEvent("PREVIEW_SET", tSet.tSub)
                    end
                else
                    if i <= #self.tChangeColorList then
                        local tSet = self.tChangeColorList[i]
                        local dwSrcID = self.tbSet.tSub[1]
                        local dwDstID = tSet[1]
                        Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeColor, dwSrcID, dwDstID)
                    end
                end
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnChangeHair, EventType.OnClick, function()
        if self.tbSub and not self.bInShopView then
            if self.bChangeHair then
                self:OnSubExitChangeHair()
            else
                self:OnSubEnterChangeHair()
            end
        end
        if self.tbSet and not self.bInShopView then
            if self.bChangeHair then
                self:OnSetExitChangeHair()
            else
                self:OnSetEnterChangeHair()
            end
        end
    end)

    for i, tog in ipairs(self.tTogHair) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                if self.tbSub and not self.bInShopView then
                    local dwID = self.tbSub[1]
                    Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeHair, dwID, i-1)
                end
                if self.tbSet and not self.bInShopView then
                    local _, dwHatID = CoinShopExterior.GetSetDyeingInfo(self.tbSet.tSub)
                    Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeHair, dwHatID, i-1, self.tbSet.tSub)
                end
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnFound, EventType.OnClick, function()
        if not self.tbRewardsItem then
            return
        end
        local tbRewardsItem = self.tbRewardsItem
        local hItemInfo = tbRewardsItem.tItemInfo or GetItemInfo(tbRewardsItem.dwTabType, tbRewardsItem.dwIndex)
        if not hItemInfo then
            return
        end
        local szName = ItemData.GetItemNameByItemInfo(hItemInfo)
        WebUrl.OpenByID(WEBURL_ID.WAN_BAO_LOU_ITEM, nil, nil, szName)
    end)

    UIHelper.BindUIEvent(self.BtnFound2, EventType.OnClick, function()
        if not self.tbRewardsItem then
            return
        end
        local tbRewardsItem = self.tbRewardsItem
        UIHelper.ShowConfirm(g_tStrings.STR_COINSHOP_GO_TO_AUCTION_TIP, function()
            UIMgr.Close(VIEW_ID.PanelExteriorMain)
            local szLinkInfo = string.format("SourceTrade/%d/%d", tbRewardsItem.dwTabType, tbRewardsItem.dwIndex)
            Event.Dispatch("EVENT_LINK_NOTIFY", szLinkInfo)
        end)
    end)
end

function UICoinShopPropItem:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownload()
    end)

    Event.Reg(self,  EventType.OnCoinShopEnterExteriorChangeColor, function (dwSrcID, dwDstID)
        if not self.tbSet or self.bInShopView then
            return
        end
        if self.tbSet.tSub[1] ~= dwSrcID then
            if self.bChangeColor then
                self:OnSetExitChangeColor(true)
            end
        end
    end)

    Event.Reg(self, EventType.OnCoinShopCancelExteriorChangeColor, function ()
        if not self.tbSet or self.bInShopView then
            return
        end
        if self.bChangeColor then
            self:OnSetExitChangeColor(true)
        end
    end)

    Event.Reg(self,  EventType.OnCoinShopEnterExteriorChangeHair, function (dwID, nDyeingID)
        if self.tbSub and not self.bInShopView then
            if self.tbSub[1] ~= dwID then
                if self.bChangeHair then
                    self:OnSubExitChangeHair(true)
                end
            end
        end
        if self.tbSet and not self.bInShopView then
            local _, dwHatID = CoinShopExterior.GetSetDyeingInfo(self.tbSet.tSub)
            if dwHatID ~= dwID then
                if self.bChangeHair then
                    self:OnSetExitChangeHair(true)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnCoinShopCancelExteriorChangeHair, function ()
        if self.tbSub and not self.bInShopView then
            if self.bChangeHair then
                self:OnSubExitChangeHair(true)
            end
        end
        if self.tbSet and not self.bInShopView then
            if self.bChangeHair then
                self:OnSetExitChangeHair(true)
            end
        end
    end)
end

function UICoinShopPropItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
-- 为了重用预制，把数据和节点状态改到一个默认状态
-- 没用OnPoolXXXX的原因是这个脚本其他界面也在用
function UICoinShopPropItem:OnInitAll()
    if self.tbRewardsItem then
        self.tbRewardsItem = nil
        self.bShop = nil
    elseif self.dwWeaponID then
        self.dwWeaponID = nil
        self.bShop = nil
    elseif self.tbSet then
        self.tbSet = nil
        self.bInShopView = nil
        self.tSubGenre = nil
        self.tChangeColorList = nil
        self.bChangeColor = false
        self.bChangeHair = false
    elseif self.tbSub then
        self.tbSub = nil
        self.bInShopView = nil
        self.bChangeHair = false
    elseif self.tbAdornmentSet then
        self.tbAdornmentSet = nil
    end
    self.tEquipList = nil
    self.tEquipSfxList = nil

    UIHelper.SetTouchEnabled(self.TogPetList, true)
    if self.itemIcon then
        self.itemIcon:SetEnable(true)
    end
    -- 详情/隐藏/还原/删除/换色
    UIHelper.SetVisible(self.BtnFurnitureDetail, false)
    UIHelper.SetVisible(self.BtnDel, false)
    UIHelper.SetVisible(self.BtnRevert, false)
    UIHelper.SetVisible(self.BtnClean, false)
    UIHelper.SetVisible(self.BtnChangeColor, false)
    UIHelper.SetVisible(self.BtnChangeHair, false)
    UIHelper.SetVisible(self.BtnInteraction, false)
    -- 打折/已收集/已购买
    UIHelper.SetVisible(self.ImgDiscount02, false)
    UIHelper.SetVisible(self.ImgCollectBg, false)
    UIHelper.SetVisible(self.ImgCollectBg02, false)
    UIHelper.SetVisible(self.ImgBuyBg, false)
    UIHelper.SetVisible(self.ImgBuyBg02, false)
    UIHelper.SetVisible(self.LabelNeedCollect, false)
    -- 价格
    UIHelper.SetVisible(self.LayoutPrice, false)
    UIHelper.SetVisible(self.LabelOriginalPrice, false)
    UIHelper.SetVisible(self.LayoutPrice02, false)
    UIHelper.SetVisible(self.LabelOriginalPrice02, false)
    UIHelper.SetVisible(self.ImgFreePrice, false)
    UIHelper.SetVisible(self.ImgFreePrice02, false)
    -- 限时文本
    UIHelper.SetVisible(self.ImgTimeBg, false)
    UIHelper.SetVisible(self.ImgTimeBg02, false)
    -- 标签图
    UIHelper.SetVisible(self.ImgCollected, false)
    UIHelper.SetVisible(self.ImgTimeLimit, false)
    UIHelper.SetVisible(self.ImgNew, false)
    UIHelper.SetVisible(self.ImgItemCollectBg, false)
    UIHelper.SetVisible(self.ImgLock, false)
    UIHelper.SetVisible(self.ImgFree, false)
    UIHelper.SetVisible(self.ImgRedDot, false)
    UIHelper.SetVisible(self.ImgGot, false)
    UIHelper.SetVisible(self.ImgCanChangeHair, false)
    -- 提示语
    UIHelper.SetVisible(self.LabelKeepTip, false)
    -- 换色详情
    UIHelper.SetVisible(self.WidgetSuit, false)
    UIHelper.SetVisible(self.WidgetSuitColor, false)
    UIHelper.SetVisible(self.WidgetHairColor, false)
    UIHelper.SetVisible(self.WidgetFound, false)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewSuitColor, false)
    UIHelper.LayoutDoLayout(self._rootNode)
    -- 外装下载
    UIHelper.SetVisible(self.WidgetDownloadShell, false)
    -- 组合道具购买提示
    UIHelper.SetVisible(self.ImgComboTipBg, false)
end

function UICoinShopPropItem:UpdateItemState()
    self:Update()
end

function UICoinShopPropItem:Update()
    if not self.bInit then
        return
    end
    if self.tbRewardsItem then
        self:UpdateRewardsItem()
    elseif self.dwWeaponID then
        self:UpdateWeapon()
    elseif self.tbSet then
        self:UpdateSet()
    elseif self.tbSub then
        self:UpdateSub()
    elseif self.tbAdornmentSet then
        self:UpdateAdornmentSet()
    end
end

function UICoinShopPropItem:OnInitWithRewardsItem(tbRewardsItem, bShop)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:OnInitAll()

    self.tbRewardsItem = tbRewardsItem
    self.bShop = bShop

    self:UpdateRewardsItem(true)
    self:UpdateDownloadEquipRes({{nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwID=self.tbRewardsItem.dwLogicID, dwType=COIN_SHOP_GOODS_TYPE.ITEM}})
end

function UICoinShopPropItem:UpdateRewardsItem(bInit)
    local tbRewardsItem = self.tbRewardsItem
    local bShop = self.bShop

    UIHelper.SetVisible(self.TogPetList, true)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hItemInfo = tbRewardsItem.tItemInfo or GetItemInfo(tbRewardsItem.dwTabType, tbRewardsItem.dwIndex)
    if not hItemInfo then
        return
    end

    local tbInfo = hRewardsShop.GetRewardsShopInfo(tbRewardsItem.dwLogicID)
    tbInfo.eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
    local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, tbRewardsItem.dwLogicID)
    local nPrice, nOriginalPrice, szImagePath, nFrame = CoinShop_GetShowPrice(tbInfo)
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local bStorage = nHaveType == COIN_SHOP_OWN_TYPE.STORAGE
    local szLeftTime = CoinShop_GetRewardsTime(tbRewardsItem.dwLogicID, true)
    local bCanBuy = CoinShop_RewardsCanBuy(tbRewardsItem.dwLogicID)

    local nCounterID = tbInfo.nGlobalCounterID
    local bLimitItem = nCounterID > 0
    local bShowBeforeTime = CoinShop_ShowBeforeTime(COIN_SHOP_GOODS_TYPE.ITEM, tbRewardsItem.nClass)
    local bGameWorldStart = tbInfo.nGameWorldStartInDuration > 0
    local bLimitTime = (szLeftTime ~= "" or bLimitItem or bShowBeforeTime or bGameWorldStart) and not tbRewardsItem.bOverdue
    local szCountDown = bLimitTime and CoinShop_GetCountDownInfo(tbInfo) or ""
    local bPreview = ExteriorCharacter.IsRewardsPreview(self.tbRewardsItem)

    if bInit then
        if not self.itemIcon then
            self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetProp)
        end
        self.itemIcon:SetClickNotSelected(true)
        self.itemIcon:SetToggleSwallowTouches(true)
        self.itemIcon:OnInitWithTabID(tbRewardsItem.dwTabType, tbRewardsItem.dwIndex)
        self.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tbRewardsItem.dwTabType,
                    dwTabIndex = tbRewardsItem.dwIndex,
                    dwGoodsID = tbRewardsItem.dwLogicID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        local szName =  ItemData.GetItemNameByItemInfo(hItemInfo)
        local szType = CoinShop_GetRewardsType(tbRewardsItem)
        UIHelper.SetString(self.LabelPetTitle, self:LimitTitleLen(UIHelper.GBKToUTF8(szName)))
        UIHelper.SetString(self.LabelPetTitle02, self:LimitTitleLen(UIHelper.GBKToUTF8(szName)))
        UIHelper.SetString(self.LabelPetName, szType)
        UIHelper.SetString(self.LabelPetName02, szType)
        UIHelper.SetSwallowTouches(self.BtnFurnitureDetail, true)
        UIHelper.SetVisible(self.BtnFurnitureDetail, tbRewardsItem.dwIntroduceID and tbRewardsItem.dwIntroduceID > 0)
        UIHelper.SetSwallowTouches(self.BtnInteraction, true)
        UIHelper.SetVisible(self.BtnInteraction, false)
    end

    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbInfo)
    UIHelper.SetVisible(self.ImgDiscount02, bDis and not bHave and not tbRewardsItem.bOverdue)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelFate, szDisTime)
    UIHelper.SetVisible(self.WidgetCollect, not bStorage)

    local szPriceIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png"
    if szImagePath then
        szPriceIcon = szImagePath
    end
    UIHelper.SetVisible(self.LayoutPrice, not bHave)
    UIHelper.SetString(self.LabelPrice, nPrice)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon, szPriceIcon)
    UIHelper.SetVisible(self.LabelOriginalPrice, bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalPrice)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine)
    UIHelper.SetVisible(self.LayoutPrice02, not bHave)
    UIHelper.SetString(self.LabelPrice02, nPrice)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon02, szPriceIcon)
    UIHelper.SetVisible(self.LabelOriginalPrice02, bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice02, nOriginalPrice)

    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine02)
    if szLeftTime ~= "" then
        UIHelper.SetVisible(self.ImgTimeLimit, true)
        UIHelper.SetSpriteFrame(self.ImgTimeLimit, "UIAtlas2_Shopping_ShoppingIcon_img_promotion03")
    elseif tbRewardsItem.nLabel == EXTERIOR_LABEL.NEW then
        UIHelper.SetVisible(self.ImgNew, true)
        UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_new")
    end

    local bShowSaleTime = tbRewardsItem.bOverdue and tbInfo.nStartTime >= 0
    local bShowLeftTime = szLeftTime ~= ""
    local bShowCountDown = szCountDown ~= ""
    UIHelper.SetVisible(self.ImgTimeBg, (bShowSaleTime or bShowLeftTime or bShowCountDown) and not bStorage and not bPreview)
    UIHelper.SetVisible(self.ImgTimeBg02, (bShowSaleTime or bShowLeftTime or bShowCountDown) and not bStorage and bPreview)
    UIHelper.SetFontSize(self.LabelTime, 20)
    UIHelper.SetFontSize(self.LabelTime02, 20)
    if bShowSaleTime then
        local nTime = tbInfo.nStartTime
        local tTime = TimeToDate(nTime)
        local szMonth = string.format("%02d", tTime.month)
        local szDay = string.format("%02d", tTime.day)
        local szSaleTime = FormatString(g_tStrings.COINSHOP_SALE_TIME2, tTime.year, szMonth, szDay)
        UIHelper.SetString(self.LabelTime, szSaleTime)
        UIHelper.SetString(self.LabelTime02, szSaleTime)
    elseif bShowLeftTime then
        UIHelper.SetString(self.LabelTime, "限" .. szLeftTime)
        UIHelper.SetString(self.LabelTime02, "限" .. szLeftTime)
    elseif bShowCountDown then
        local szText = CoinShop_GetCountDownInfo(tbInfo)
        local nLabelLen = UIHelper.GetUtf8Width(szText, 20)
        UIHelper.SetString(self.LabelTime, szText)
        UIHelper.SetString(self.LabelTime02, szText)
        if nLabelLen > MAX_TIME_LABEL_WIDTH and UIHelper.GetVisible(self.ImgDiscount02) then
            UIHelper.SetFontSize(self.LabelTime, 15)
            UIHelper.SetFontSize(self.LabelTime02, 15)
        end
    end
    UIHelper.SetVisible(self.LabelKeepTip, bStorage)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetCollect, true)

    if self.bShop and bHave then
        UIHelper.SetVisible(self.ImgGot, true)
    end

    if self.bShop and not bHave then
        UIHelper.SetVisible(self.ImgLock, tbRewardsItem.bOverdue or not bCanBuy)
    else
        UIHelper.SetVisible(self.ImgLock, false)
    end

    UIHelper.SetSelected(self.TogPetList, bPreview, false)
    UIHelper.SetSpriteFrame(self.ImgDetial, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_detail2" or "UIAtlas2_Shopping_ShoppingButton_btn_detail")
    UIHelper.SetSpriteFrame(self.ImgInteraction, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_interaction2" or "UIAtlas2_Shopping_ShoppingButton_btn_interaction")

    -- 道具组合购买提示
    local bShowComboTip = tbRewardsItem.nGroupLogicID ~= 0 and CoinShop_IsRewardsTimeOk(tbRewardsItem.nGroupLogicID)
    UIHelper.SetVisible(self.ImgComboTipBg, bShowComboTip)
    local szGroupTip = tbRewardsItem and tbRewardsItem.szGroupTip or ""
    UIHelper.SetString(self.LabelComboTip, GBKToUTF8(szGroupTip))

    -- 万宝楼交易行
    if bShop then
        local bNotBind = hItemInfo.nBindType == ITEM_BIND.BIND_ON_EQUIPPED or hItemInfo.nBindType == ITEM_BIND.NEVER_BIND
        local bShowTrade = bPreview and tbRewardsItem.bOverdue and not bGameWorldStart and bNotBind
        local bShowChanged = UIHelper.GetVisible(self.WidgetSuit) ~= bShowTrade
        if bShowChanged then
            UIHelper.SetVisible(self.WidgetSuit, bShowTrade)
            UIHelper.SetVisible(self.WidgetFound, bShowTrade)
            UIHelper.LayoutDoLayout(self._rootNode)
            if not bInit then
                Event.Dispatch(EventType.OnCoinShopListSizeChanged, true)
            end
        end
    end

    Timer.DelTimer(self, self.nTimer)
    if bShowLeftTime or bShowCountDown or (bDis and szDisTime ~= "" and not bHave) then
        self.nTimer = Timer.Add(self, 1, function()
            self:Update()
        end)
    end
end

function UICoinShopPropItem:OnClickRewardsItem()
    local hItemInfo = GetItemInfo(self.tbRewardsItem.dwTabType, self.tbRewardsItem.dwIndex)
    if hItemInfo.nGenre == ITEM_GENRE.HOMELAND then
        ExteriorCharacter.PreviewRewardsItem(self.tbRewardsItem)
    elseif hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.PET then
        ExteriorCharacter.PreviewRewardsItem(self.tbRewardsItem)
        FireUIEvent("COINSHOP_REFRESH_RECOMMEND_SHOP", COIN_SHOP_GOODS_TYPE.ITEM, self.tbRewardsItem.dwIndex)
    else
        local bPreview = ExteriorCharacter.IsRewardsPreview(self.tbRewardsItem)
        if bPreview then
            ExteriorCharacter.CancelPreviewRewards(self.tbRewardsItem)
            FireUIEvent("COINSHOP_CLEAR_RECOMMEND")
        else
            ExteriorCharacter.PreviewRewardsItem(self.tbRewardsItem)
            FireUIEvent("COINSHOP_REFRESH_RECOMMEND_SHOP", COIN_SHOP_GOODS_TYPE.ITEM, self.tbRewardsItem.dwIndex)
        end
    end
end

function UICoinShopPropItem:OnInitWithWeapon(dwID, bShop)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:OnInitAll()

    self.dwWeaponID = dwID
    self.bShop = bShop

    self:UpdateWeapon(true)
    self:UpdateDownloadEquipRes({{nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwID=dwID, dwType=COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR}})
end

function UICoinShopPropItem:UpdateWeapon(bInit)
    local dwID = self.dwWeaponID
    local bShop = self.bShop

    UIHelper.SetVisible(self.TogPetList, true)

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return hPlayer
    end

    local tbWeaponInfo = g_tTable.CoinShop_Weapon:Search(dwID)
    if not tbWeaponInfo then
        LOG.ERROR("error! CoinShop_Weapons.lua UpdateItem no weapon where dwID = " .. dwID .. ". please check WeaponUI.tab")
    end

    local tbInfo = CoinShop_GetWeaponExteriorInfo(dwID, hExteriorClient)

    local szLeftTime = CoinShop_GetTime(tbInfo)
    local bFreeTryOn = CoinShop_CanFreeTryOn(tbInfo)
    local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local bStorage = nHaveType == COIN_SHOP_OWN_TYPE.STORAGE
    local szOwn = g_tStrings.tCoinShopOwnType[nHaveType]
    local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
    local bPreview = ExteriorCharacter.IsWeaponPreview(dwID)

    if bInit then
        if not self.itemIcon then
            self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetProp)
        end
        self.itemIcon:SetClickNotSelected(true)
        self.itemIcon:SetToggleSwallowTouches(true)
        self.itemIcon:OnInitWithTabID("WeaponExterior", dwID)
        self.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR,
                    dwGoodsID = dwID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        local nDetail = tbInfo.nDetailType
        local szSub = g_tStrings.WeapenDetail[nDetail]
        UIHelper.SetString(self.LabelPetTitle, self:LimitTitleLen(UIHelper.GBKToUTF8(tbWeaponInfo.szName)))
        UIHelper.SetString(self.LabelPetTitle02, self:LimitTitleLen(UIHelper.GBKToUTF8(tbWeaponInfo.szName)))
        UIHelper.SetString(self.LabelPetName, szSub)
        UIHelper.SetString(self.LabelPetName02, szSub)
        UIHelper.SetVisible(self.BtnFurnitureDetail, false)
        if not self.bShop then
            UIHelper.SetVisible(self.ImgRedDot, RedpointHelper.WeaponExterior_IsNew(dwID))
        end
    end

    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbInfo)
    UIHelper.SetVisible(self.ImgDiscount02, bDis and not bHave)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelFate, szDisTime)
    UIHelper.SetVisible(self.WidgetCollect, not bStorage)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetCollect, true)

    local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tbInfo)

    local szShowPrice
    local szShowIcon
    if bCollect then
        szShowPrice = nPrice
        szShowIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png"
    else
        szShowPrice = "收集需" .. nGold
        szShowIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png"
    end
    UIHelper.SetVisible(self.LayoutPrice, not bHave and (bCollect or nGold >= 0))
    UIHelper.SetString(self.LabelPrice, szShowPrice)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon, szShowIcon)
    UIHelper.SetVisible(self.LabelOriginalPrice, bCollect and bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalPrice)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine)
    UIHelper.SetVisible(self.LayoutPrice02, not bHave and (bCollect or nGold >= 0))
    UIHelper.SetString(self.LabelPrice02, szShowPrice)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon02, szShowIcon)
    UIHelper.SetVisible(self.LabelOriginalPrice02, bCollect and bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice02, nOriginalPrice)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine02)
    UIHelper.SetVisible(self.LabelNeedCollect, not bHave and (not bCollect and nGold < 0))

    if self.bShop then
        if tbWeaponInfo.nLabel == EXTERIOR_LABEL.NEW then
            UIHelper.SetVisible(self.ImgNew, true)
            UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_new")
        elseif tbWeaponInfo.nLabel == EXTERIOR_LABEL.DISCOUNT then
            UIHelper.SetVisible(self.ImgNew, true)
            UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_discount")
        end
    end
    UIHelper.SetVisible(self.LabelKeepTip, bStorage)

    if self.bShop and bCollect and not bHave then
        UIHelper.SetVisible(self.ImgCollected, true)
    elseif self.bShop and bHave then
        UIHelper.SetVisible(self.ImgGot, true)
    end

    UIHelper.SetSelected(self.TogPetList, bPreview, false)

    Timer.DelTimer(self, self.nTimer)
    if szLeftTime ~= "" or (bDis and szDisTime ~= "" and not bHave) then
        self.nTimer = Timer.Add(self, 1, function()
            self:Update()
        end)
    end
end

function UICoinShopPropItem:OnClickWeapon()
    local dwID = self.dwWeaponID
    local bPreview = ExteriorCharacter.IsWeaponPreview(dwID)
    if bPreview then
        FireUIEvent("CANCEL_PREVIEW_WEAPON", dwID)
    else
        FireUIEvent("PREVIEW_WEAPON", dwID, true)
    end
    if not self.bShop then
        if RedpointHelper.WeaponExterior_IsNew(dwID) then
            RedpointHelper.WeaponExterior_SetNew(dwID, false)
        end
        UIHelper.SetVisible(self.ImgRedDot, false)
    end
end

function UICoinShopPropItem:OnInitWithSet(tbSet, bInShopView, tSubGenre)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:OnInitAll()

    self.tbSet = tbSet
    self.bInShopView = bInShopView
    self.tSubGenre = tSubGenre

    self:UpdateSet(true)

    local tList = {}
    local tbSub = self.tbSet.tSub
    for _, dwSubID in ipairs(tbSub) do
        table.insert(tList, {nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwType=COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID=dwSubID})
    end
    self:UpdateDownloadEquipRes(tList)
end

function UICoinShopPropItem:UpdateSet(bInit)
    local tbSet = self.tbSet
    local bInShopView = self.bInShopView
    local tSubGenre = self.tSubGenre

    local bSimpleMode = tSubGenre and #tSubGenre > 1

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return hPlayer
    end

    local tbSub = self.tbSet.tSub
    local dwID = tbSub[1]
    local nCount = self.tbSet.nCount or #tbSub

    local tbExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
    local tbSetInfo = Table_GetExteriorSet(tbExteriorInfo.nSet)

    local nHave, nCoin, bShop, nCollected, nOriginalCoin, nDelete, bStorage = CoinShopExterior.GetSetInfo(tbSub)
    local bHave = nHave == nCount
    local bCollect = false
    local bDelete = nDelete > 0
    if not bShop then
        bCollect = nCollected == nCount
    end
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbExteriorInfo)
    local szLeftTime = CoinShop_GetExteriorTime(dwID)
    local bPreview = self:IsSetPreview()

    if bInit then
        local dwIconGoodsID = dwID
        for i = 2, #tbSub do
            local tInfo = GetExterior().GetExteriorInfo(tbSub[i])
            if tInfo.nSubType == EQUIPMENT_SUB.CHEST then
                dwIconGoodsID = tbSub[i]
                break
            end
        end
        if not self.itemIcon then
            self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetProp)
        end
        self.itemIcon:SetClickNotSelected(true)
        self.itemIcon:SetToggleSwallowTouches(true)
        self.itemIcon:OnInitWithTabID("EquipExterior", dwIconGoodsID)
        self.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR,
                    dwGoodsID = dwIconGoodsID
                }
                local tbCleanBtnInfo
                if not bInShopView then
                    local nFlag = CoinShopExterior.GetShowBySet(tbSub)
                    if nFlag == EXTERIOR_HIDE_TYPE.NOT_HIDE then
                        tbCleanBtnInfo = {
                            szName = "删除",
                            OnClick = function ()
                                local szMsg = string.format(g_tStrings.COIN_SHOP_HIDE_EXTERIOR_SURE, UIHelper.GBKToUTF8(tbSetInfo.szSetName))
                                UIHelper.ShowConfirm(szMsg, function()
                                    local hPlayer = GetClientPlayer()
                                    if not hPlayer then
                                        return
                                    end
                                    for _, _dwID in pairs(self.tbSet.tSub) do
                                        hPlayer.SetExteriorHideFlag(_dwID, EXTERIOR_HIDE_TYPE.HIDE)
                                    end
                                end)
                            end
                        }
                    end
                end
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods, tbCleanBtnInfo)
            end
        end)
        if bSimpleMode then
            local szSubGenreName = Table_GetExteriorSubGenreName(tbSetInfo.nSubGenre)
            UIHelper.SetString(self.LabelPetTitle, self:LimitTitleLen(UIHelper.GBKToUTF8(szSubGenreName) .. "(" .. #tbSub .. ")"))
            UIHelper.SetString(self.LabelPetTitle02, self:LimitTitleLen(UIHelper.GBKToUTF8(szSubGenreName) .. "(".. #tbSub .. ")"))
        else
            UIHelper.SetString(self.LabelPetTitle, self:LimitTitleLen(UIHelper.GBKToUTF8(tbSetInfo.szSetName) .. "(" .. #tbSub .. ")"))
            UIHelper.SetString(self.LabelPetTitle02, self:LimitTitleLen(UIHelper.GBKToUTF8(tbSetInfo.szSetName) .. "(".. #tbSub .. ")"))
        end

        UIHelper.SetString(self.LabelPetName, "套装")
        UIHelper.SetString(self.LabelPetName02, "套装")
        UIHelper.SetSwallowTouches(self.BtnDel, true)
        UIHelper.SetSwallowTouches(self.BtnRevert, true)
        UIHelper.SetSwallowTouches(self.BtnClean, true)
        UIHelper.SetSwallowTouches(self.BtnChangeColor, true)
        UIHelper.SetSwallowTouches(self.BtnChangeHair, true)
        UIHelper.ToggleGroupRemoveAllToggle(self.WidgetSuit)
        if not bInShopView then
            local nFlag = CoinShopExterior.GetShowBySet(tbSub)
            if nFlag == EXTERIOR_HIDE_TYPE.HIDE then
                UIHelper.SetVisible(self.BtnRevert, true)
                UIHelper.SetVisible(self.BtnClean, true)
            end

            local tChangeColorList = CoinShopExterior.GetChangeColorList(dwID)
            self.tChangeColorList = tChangeColorList
            -- 衣服染色
            local bCanChangeColor = nFlag == EXTERIOR_HIDE_TYPE.NOT_HIDE and #tChangeColorList > 0 and nFlag ~= EXTERIOR_HIDE_TYPE.HIDE
            UIHelper.SetVisible(self.BtnChangeColor, bCanChangeColor)
            -- 帽子染发色
            local bCanChangeHair = CoinShopExterior.GetSetDyeingInfo(self.tbSet.tSub) and nFlag ~= EXTERIOR_HIDE_TYPE.HIDE
            UIHelper.SetVisible(self.BtnChangeHair, bCanChangeHair)
            if bCanChangeColor then
                for i, tog in ipairs(self.tTogColor) do
                    UIHelper.ToggleGroupAddToggle(self.WidgetSuit, tog)
                    UIHelper.SetVisible(tog, tChangeColorList and i <= #tChangeColorList)
                end
                UIHelper.ScrollViewDoLayoutAndToLeft(self.ScrollViewSuitColor)
            elseif bCanChangeHair then
                for _, tog in ipairs(self.tTogHair) do
                    UIHelper.ToggleGroupAddToggle(self.WidgetSuit, tog)
                end
            end

            for _, dwID in ipairs(self.tbSet.tSub) do
                if RedpointHelper.Exterior_IsNew(dwID) then
                    UIHelper.SetVisible(self.ImgRedDot, true)
                    break
                end
            end
        else
            local bCanChangeHair = CoinShopExterior.GetSetDyeingInfo(self.tbSet.tSub)
            UIHelper.SetVisible(self.ImgCanChangeHair, bCanChangeHair)
            for i, tog in ipairs(self.tTogColor) do
                UIHelper.ToggleGroupAddToggle(self.WidgetSuit, tog)
                UIHelper.SetVisible(tog, tSubGenre and i <= #tSubGenre)
            end
            UIHelper.ScrollViewDoLayoutAndToLeft(self.ScrollViewSuitColor)
        end
    end

    UIHelper.SetVisible(self.ImgDiscount02, bDis and self.bInShopView and not bHave)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelFate, szDisTime)

    UIHelper.SetVisible(self.ImgCollectBg, not bShop and not bPreview and not bSimpleMode)
    UIHelper.SetString(self.LabelCollectNum, nCollected .. "/" .. nCount)
    UIHelper.SetVisible(self.ImgCollectBg02, not bShop and bPreview and not bSimpleMode)
    UIHelper.SetString(self.LabelCollectNum02, nCollected .. "/" .. nCount)
    UIHelper.SetVisible(self.WidgetCollect, not bStorage)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetCollect, true)

    local szShowPrice
    if self.bInShopView and CoinShopExterior.SetShow0YuanGou(self.tbSet.tSub) and not bHave then
        szShowPrice = 0
    else
        szShowPrice = nCoin
    end
    UIHelper.SetVisible(self.LayoutPrice, self.bInShopView and not bHave)
    UIHelper.SetString(self.LabelPrice, szShowPrice)
    UIHelper.SetVisible(self.ImgFreePrice, self.bInShopView and CoinShopExterior.SetShow0YuanGou(self.tbSet.tSub) and not bHave)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon, "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png")
    UIHelper.LayoutDoLayout(self.LayoutPrice)
    UIHelper.SetVisible(self.LabelOriginalPrice, bDis and self.bInShopView and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine)
    UIHelper.SetVisible(self.LayoutPrice02, self.bInShopView and not bHave)
    UIHelper.SetString(self.LabelPrice02, szShowPrice)
    UIHelper.SetVisible(self.ImgFreePrice02, self.bInShopView and CoinShopExterior.SetShow0YuanGou(self.tbSet.tSub) and not bHave)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon02, "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png")
    UIHelper.LayoutDoLayout(self.LayoutPrice02)
    UIHelper.SetVisible(self.LabelOriginalPrice02, bDis and self.bInShopView and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice02, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine02)

    if self.bInShopView and not bShop and bCollect and not bHave and not bSimpleMode then
        UIHelper.SetVisible(self.ImgCollected, true)
    elseif self.bInShopView and bHave and not bSimpleMode then
        UIHelper.SetVisible(self.ImgGot, true)
    end
    if self.bInShopView and szLeftTime ~= "" then
        UIHelper.SetVisible(self.ImgTimeLimit, true)
        UIHelper.SetSpriteFrame(self.ImgTimeLimit, "UIAtlas2_Shopping_ShoppingIcon_img_promotion03")
    elseif self.bInShopView and tbSetInfo.nLabel == EXTERIOR_LABEL.NEW then
        UIHelper.SetVisible(self.ImgNew, true)
        UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_new")
    end
    UIHelper.SetVisible(self.ImgFree, self.bInShopView and CoinShopExterior.SetShow0YuanGou(self.tbSet.tSub) and not bHave)

    UIHelper.SetVisible(self.LabelKeepTip, bStorage)

    UIHelper.SetSelected(self.TogPetList, bPreview, false)
    if not bInShopView then
        UIHelper.SetSpriteFrame(self.ImgDel, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_delete2" or "UIAtlas2_Shopping_ShoppingButton_btn_delete")
        UIHelper.SetSpriteFrame(self.ImgRevert, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_recall2" or "UIAtlas2_Shopping_ShoppingButton_btn_recall")
        UIHelper.SetSpriteFrame(self.ImgClean, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_clean2" or "UIAtlas2_Shopping_ShoppingButton_btn_clean")
        UIHelper.SetSpriteFrame(self.ImgChange, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_changeColor2" or "UIAtlas2_Shopping_ShoppingButton_btn_changeColor")
        UIHelper.SetSpriteFrame(self.ImgChangeHair, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_HairColor2" or "UIAtlas2_Shopping_ShoppingButton_btn_HairColor")
    end

    -- 收纳
    if bInShopView then
        local bShowColor = bSimpleMode and bPreview
        local bShowColorChanged = UIHelper.GetVisible(self.WidgetSuit) ~= bShowColor
        if bShowColor then
            for i, tog in ipairs(self.tTogColor) do
                if i <= #tSubGenre then
                    local bSubGenrePreview = ExteriorCharacter.IsSetPreview(tSubGenre[i].tSub)
                    UIHelper.SetSelected(tog, bSubGenrePreview, false)
 					-- 首次出现时如果超过第6套就拉到最后
                    if bShowColorChanged and i >= 7 and bSubGenrePreview then
                        UIHelper.ScrollToRight(self.ScrollViewSuitColor)
                    end
                end
            end
        end
        if bShowColorChanged then
            UIHelper.SetVisible(self.WidgetSuit, bShowColor)
            UIHelper.SetVisible(self.WidgetSuitColor, bShowColor)
            UIHelper.LayoutDoLayout(self._rootNode)
            if not bInit then
                Event.Dispatch(EventType.OnCoinShopListSizeChanged, true)
            end
        end
    end

    Timer.DelTimer(self, self.nTimer)
    if szLeftTime ~= "" or (bDis and szDisTime ~= "" and not bHave) then
        self.nTimer = Timer.Add(self, 1, function()
            self:Update()
        end)
    end
end

function UICoinShopPropItem:OnSetEnterChangeColor()
    if not self:IsSetPreview() then
        self:OnClickSet()
    end
    self.bChangeColor = true
    UIHelper.SetVisible(self.WidgetSuit, true)
    UIHelper.SetVisible(self.WidgetSuitColor, true)
    local tSet = self.tChangeColorList[1]
    local dwSrcID = self.tbSet.tSub[1]
    local dwDstID = tSet[1]
    UIHelper.SetToggleGroupSelected(self.WidgetSuit, 0)
    UIHelper.LayoutDoLayout(self._rootNode)
    Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeColor, dwSrcID, dwDstID)
end

function UICoinShopPropItem:OnSetExitChangeColor(bNotUpdate)
    self.bChangeColor = false
    UIHelper.SetVisible(self.WidgetSuit, false)
    UIHelper.SetVisible(self.WidgetSuitColor, false)
    UIHelper.LayoutDoLayout(self._rootNode)
    if self.bInit then
        Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    end
    if not bNotUpdate then
        Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeColor)
    end
end

function UICoinShopPropItem:OnSetEnterChangeHair()
    if not self:IsSetPreview() then
        self:OnClickSet()
    end
    self.bChangeHair = true
    UIHelper.SetVisible(self.WidgetSuit, true)
    UIHelper.SetVisible(self.WidgetHairColor, true)

    local _, dwHatID = CoinShopExterior.GetSetDyeingInfo(self.tbSet.tSub)
    local nDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwHatID)

    UIHelper.SetToggleGroupSelected(self.WidgetSuit, nDyeingID)
    UIHelper.LayoutDoLayout(self._rootNode)
    Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeHair, dwHatID, nDyeingID, self.tbSet.tSub)
end

function UICoinShopPropItem:OnSetExitChangeHair(bNotUpdate)
    self.bChangeHair = false
    UIHelper.SetVisible(self.WidgetSuit, false)
    UIHelper.SetVisible(self.WidgetHairColor, false)
    UIHelper.LayoutDoLayout(self._rootNode)
    if self.bInit then
        Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    end
    if not bNotUpdate then
        Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
    end
end

function UICoinShopPropItem:OnClickSet()
    local bPreview, tPreviewSet = self:IsSetPreview()
    local bPreviewHair = self.bInShopView and Storage.CoinShop.bPreviewMatchHair

    if bPreview then
        FireUIEvent("CANCEL_PREVIEW_SET", tPreviewSet)
        if bPreviewHair then
            FireUIEvent("RESET_HAIR")
        end
    else
        if bPreviewHair then
            local dwID = self.tbSet.tSub[1]
            local nMatchHair = CoinShop_GetMatchHair(dwID)
            if nMatchHair then
                FireUIEvent("PREVIEW_HAIR", nMatchHair, nil, true, true, false)
            end
        end
        FireUIEvent("PREVIEW_SET", self.tbSet.tSub)
    end

    if not self.bInShopView then
        for _, dwID in ipairs(self.tbSet.tSub) do
            if RedpointHelper.Exterior_IsNew(dwID) then
                RedpointHelper.Exterior_SetNew(dwID, false)
            end
        end
        UIHelper.SetVisible(self.ImgRedDot, false)
    end
end

function UICoinShopPropItem:IsSetPreview()
    local bPreview = false
    local tPreviewSub = nil
    if self.tSubGenre and #self.tSubGenre > 0 then
        for _, tSubGenreSet in ipairs(self.tSubGenre) do
            bPreview = ExteriorCharacter.IsSetPreview(tSubGenreSet.tSub)
            if bPreview then
                tPreviewSub = tSubGenreSet.tSub
                break
            end
        end
    else
        bPreview = ExteriorCharacter.IsSetPreview(self.tbSet.tSub)
        if bPreview then
            tPreviewSub = self.tbSet.tSub
        end
    end
    return bPreview, tPreviewSub
end

function UICoinShopPropItem:OnInitWithSub(tbSub, bInShopView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:OnInitAll()

    self.tbSub = tbSub
    self.bInShopView = bInShopView

    self:UpdateSub(true)

    UIHelper.SetString(self.LabelDownloadTip, "下载该外装资源")
    local dwID = tbSub[1]
    self:UpdateDownloadEquipRes({{nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwType=COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID=dwID}})
end

function UICoinShopPropItem:UpdateSub(bInit)
    local tbSub = self.tbSub
    local bInShopView = self.bInShopView

    local dwID = tbSub[1]
    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tbExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
    local bIsInShop = tbExteriorInfo.bIsInShop
    local tbSet = Table_GetExteriorSet(tbExteriorInfo.nSet)
    local szSub = g_tStrings.tExteriorSubNameGBK[tbExteriorInfo.nSubType]
    local szName = UIHelper.GBKToUTF8(tbSet.szSetName .. g_tStrings.STR_CONNECT_GBK .. szSub)

    local szLeftTime = CoinShop_GetExteriorTime(dwID)
    local bFreeTryOn = CoinShop_CanFreeTryOn(tbExteriorInfo)
    local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
    local szOwn = g_tStrings.tCoinShopOwnType[nHaveType]
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local bStorage = nHaveType == COIN_SHOP_OWN_TYPE.STORAGE
    local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
    local nCollected = 0
    if bCollect then
        nCollected = 1
    end
    local nHave = 0
    if bHave then
        nHave = 1
    end
    local nCoin, nOriginalCoin = CoinShop_GetShowPrice(tbExteriorInfo)
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbExteriorInfo)
    local bPreview = ExteriorCharacter.IsSubPreview(dwID)

    if bInit then
        if not self.itemIcon then
            self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetProp)
        end
        self.itemIcon:SetClickNotSelected(true)
        self.itemIcon:SetToggleSwallowTouches(true)
        self.itemIcon:OnInitWithTabID("EquipExterior", dwID)
        self.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR,
                    dwGoodsID = dwID
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        UIHelper.SetString(self.LabelPetTitle, self:LimitTitleLen(szName))
        UIHelper.SetString(self.LabelPetTitle02, self:LimitTitleLen(szName))
        UIHelper.SetString(self.LabelPetName, g_tStrings.tExteriorSub[tbExteriorInfo.nSubType])
        UIHelper.SetString(self.LabelPetName02, g_tStrings.tExteriorSub[tbExteriorInfo.nSubType])

        UIHelper.SetSwallowTouches(self.BtnChangeHair, true)
        UIHelper.ToggleGroupRemoveAllToggle(self.WidgetSuit)
        if not bInShopView then
            for _, tog in ipairs(self.tTogHair) do
                UIHelper.ToggleGroupAddToggle(self.WidgetSuit, tog)
            end
            if tbExteriorInfo.nDyeingIDUpperLimit > 0 then
                UIHelper.SetVisible(self.BtnChangeHair, true)
            end
            UIHelper.SetVisible(self.ImgRedDot, RedpointHelper.Exterior_IsNew(dwID))
        else
            if tbExteriorInfo.nDyeingIDUpperLimit > 0 then
                UIHelper.SetVisible(self.ImgCanChangeHair, true)
            end
        end
    end

    UIHelper.SetVisible(self.ImgDiscount02, bDis and bInShopView and not bHave)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelFate, szDisTime)

    UIHelper.SetVisible(self.ImgCollectBg, not bIsInShop and not bPreview)
    UIHelper.SetString(self.LabelCollectNum, nCollected .. "/1")
    UIHelper.SetVisible(self.ImgCollectBg02, not bIsInShop and bPreview)
    UIHelper.SetString(self.LabelCollectNum02, nCollected .. "/1")
    UIHelper.SetVisible(self.WidgetCollect, not bStorage)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetCollect, true)

    local szShowPrice
    local szShowIcon
    if bIsInShop or bCollect then
        if self.bInShopView and CoinShopExterior.SubShow0YuanGou(dwID) and not bHave then
            szShowPrice = "0"
        else
            szShowPrice = nCoin
        end
        szShowIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png"
    else
        szShowPrice = "收集需" .. nGold
        szShowIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png"
    end
    UIHelper.SetVisible(self.LayoutPrice, bInShopView and not bHave and (bIsInShop or bCollect or nGold >= 0))
    UIHelper.SetString(self.LabelPrice, szShowPrice)
    UIHelper.SetVisible(self.ImgFreePrice, self.bInShopView and CoinShopExterior.SubShow0YuanGou(dwID) and not bHave)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon, szShowIcon)
    UIHelper.LayoutDoLayout(self.LayoutPrice)
    UIHelper.SetVisible(self.LabelOriginalPrice, bDis and bInShopView and (bIsInShop or bCollect) and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine)
    UIHelper.SetVisible(self.LayoutPrice02, bInShopView and not bHave and (bIsInShop or bCollect or nGold >= 0))
    UIHelper.SetString(self.LabelPrice02, szShowPrice)
    UIHelper.SetVisible(self.ImgFreePrice02, self.bInShopView and CoinShopExterior.SubShow0YuanGou(dwID) and not bHave)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon02, szShowIcon)
    UIHelper.LayoutDoLayout(self.LayoutPrice02)
    UIHelper.SetVisible(self.LabelOriginalPrice02, bDis and bInShopView and (bIsInShop or bCollect) and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice02, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine02)
    UIHelper.SetVisible(self.LabelNeedCollect, bInShopView and not bHave and (not bIsInShop and not bCollect and nGold < 0))

    if bInShopView and not bIsInShop and bCollect and not bHave then
        UIHelper.SetVisible(self.ImgCollected, true)
    elseif bInShopView and bHave then
        UIHelper.SetVisible(self.ImgGot, true)
    end
    if self.bInShopView and szLeftTime ~= "" then
        UIHelper.SetVisible(self.ImgTimeLimit, true)
        UIHelper.SetSpriteFrame(self.ImgTimeLimit, "UIAtlas2_Shopping_ShoppingIcon_img_promotion03")
    elseif self.bInShopView and tbSet.nLabel == EXTERIOR_LABEL.NEW then
        UIHelper.SetVisible(self.ImgNew, true)
        UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_new")
    end
    UIHelper.SetVisible(self.ImgFree, self.bInShopView and CoinShopExterior.SubShow0YuanGou(dwID) and not bHave)
    UIHelper.SetVisible(self.LabelKeepTip, bStorage)

    UIHelper.SetSelected(self.TogPetList, bPreview, false)
    if not bInShopView then
        UIHelper.SetSpriteFrame(self.ImgChangeHair, bPreview and "UIAtlas2_Shopping_ShoppingButton_btn_HairColor2" or "UIAtlas2_Shopping_ShoppingButton_btn_HairColor")
    end

    Timer.DelTimer(self, self.nTimer)
    if szLeftTime ~= "" or (bDis and szDisTime ~= "" and not bHave) then
        self.nTimer = Timer.Add(self, 1, function()
            self:Update()
        end)
    end
end

function UICoinShopPropItem:OnSubEnterChangeHair()
    local dwID = self.tbSub[1]
    if not ExteriorCharacter.IsSubPreview(dwID) then
        self:OnClickSub()
    end
    self.bChangeHair = true
    UIHelper.SetVisible(self.WidgetSuit, true)
    UIHelper.SetVisible(self.WidgetHairColor, true)

    local nDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwID)

    UIHelper.SetToggleGroupSelected(self.WidgetSuit, nDyeingID)
    UIHelper.LayoutDoLayout(self._rootNode)
    Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    Event.Dispatch(EventType.OnCoinShopEnterExteriorChangeHair, dwID, nDyeingID)
end

function UICoinShopPropItem:OnSubExitChangeHair(bNotUpdate)
    self.bChangeHair = false
    UIHelper.SetVisible(self.WidgetSuit, false)
    UIHelper.SetVisible(self.WidgetHairColor, false)
    UIHelper.LayoutDoLayout(self._rootNode)
    if self.bInit then
        Event.Dispatch(EventType.OnCoinShopListSizeChanged, false)
    end
    if not bNotUpdate then
        Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
    end
end

function UICoinShopPropItem:OnClickSub()
    local dwID = self.tbSub[1]
    if ExteriorCharacter.IsSubPreview(dwID) then
        FireUIEvent("CANCEL_PREVIEW_SUB", dwID, true, nil, false)
    else
        FireUIEvent("PREVIEW_SUB", dwID, nil, true, false)
    end

    if not self.bInShopView then
        if RedpointHelper.Exterior_IsNew(dwID) then
            RedpointHelper.Exterior_SetNew(dwID, false)
        end
        UIHelper.SetVisible(self.ImgRedDot, false)
    end
end

function UICoinShopPropItem:OnInitWithAdornmentSet(tbSet)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:OnInitAll()

    self.tbAdornmentSet = tbSet
    self:UpdateAdornmentSet(true)
end

function UICoinShopPropItem:UpdateAdornmentSet(bInit)
    local tbSet = self.tbAdornmentSet


    local hRewardsShop = GetRewardsShop()
    if not hRewardsShop then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tbItem = tbSet.tList[1]
    local nCount = #tbSet.tList

    local nHave, nCoin, nOriginalCoin, bStorage = CoinShopRewards.GetAdornmentSetInfo(tbSet)
    local bHave = nHave == nCount

    local tbInfo =  hRewardsShop.GetRewardsShopInfo(tbItem.dwLogicID)
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbInfo)
    local szLeftTime = CoinShop_GetRewardsTime(tbItem.dwLogicID, true)
    local bPreview = ExteriorCharacter.IsHorseAdornmentSetPreview(tbSet.tList)

    if bInit then
        if not self.itemIcon then
            self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetProp)
        end
        self.itemIcon:SetClickNotSelected(true)
        self.itemIcon:SetToggleSwallowTouches(true)
        self.itemIcon:OnInitWithTabID(tbItem.dwTabType, tbItem.dwIndex)
        self.itemIcon:SetClickCallback(function(nParam1, nParam2)
            if nParam1 and nParam2 then
                local tbGoods = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
                    dwTabType = tbItem.dwTabType,
                    dwTabIndex = tbItem.dwIndex,
                    dwGoodsID = tbItem.dwLogicID,
                }
                Event.Dispatch(EventType.OnCoinShopShowItemTips, tbGoods)
            end
        end)
        local szName = CoinShop_GetAdornmentSetName(tbSet.nSetID)
        UIHelper.SetString(self.LabelPetTitle, UIHelper.GBKToUTF8(szName) .. "(" .. #tbSet.tList .. ")")
        UIHelper.SetString(self.LabelPetTitle02, UIHelper.GBKToUTF8(szName) .. "(".. #tbSet.tList .. ")")
        UIHelper.SetString(self.LabelPetName, "套装")
        UIHelper.SetString(self.LabelPetName02, "套装")
        UIHelper.SetVisible(self.BtnFurnitureDetail, false)
    end

    UIHelper.SetVisible(self.ImgDiscount02, bDis and not bHave)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelFate, szDisTime)
    UIHelper.SetVisible(self.WidgetCollect, not bStorage)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetCollect, true)

    UIHelper.SetVisible(self.LayoutPrice, not bHave)
    UIHelper.SetString(self.LabelPrice, nCoin)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon, "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png")
    UIHelper.SetVisible(self.LabelOriginalPrice, bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine)
    UIHelper.SetVisible(self.LayoutPrice02, not bHave)
    UIHelper.SetString(self.LabelPrice02, nCoin)
    UIHelper.SetSpriteFrame(self.ImgPriceIcon02, "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png")
    UIHelper.SetVisible(self.LabelOriginalPrice02, bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice02, nOriginalCoin)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgOriginalLine02)

    if bHave then
        UIHelper.SetVisible(self.ImgGot, true)
    end
    if szLeftTime ~= "" then
        UIHelper.SetVisible(self.ImgTimeLimit, true)
        UIHelper.SetSpriteFrame(self.ImgTimeLimit, "UIAtlas2_Shopping_ShoppingIcon_img_promotion03")
    elseif tbItem.nLabel == EXTERIOR_LABEL.NEW then
        UIHelper.SetVisible(self.ImgNew, true)
        UIHelper.SetSpriteFrame(self.ImgNew, "UIAtlas2_Shopping_ShoppingIcon_img_new")
    end
    UIHelper.SetVisible(self.LabelKeepTip, bStorage)

    UIHelper.SetSelected(self.TogPetList, bPreview, false)

    Timer.DelTimer(self, self.nTimer)
    if szLeftTime ~= "" or (bDis and szDisTime ~= "" and not bHave) then
        self.nTimer = Timer.Add(self, 1, function()
            self:Update()
        end)
    end
end

function UICoinShopPropItem:OnClickAdornmentSet()
    local tbSet = self.tbAdornmentSet
    local bPreview = ExteriorCharacter.IsHorseAdornmentSetPreview(tbSet.tList)
    if bPreview then
        ExteriorCharacter.CancelPreviewHorseAdornmentSet(tbSet.tList)
    else
        ExteriorCharacter.PreviewHorseAdornmentSet(tbSet.tList)
    end
end

function UICoinShopPropItem:PlayAni()
    UIHelper.PlayAni(self, self.AniAll, "AniPropItemCell")
end

function UICoinShopPropItem:LimitTitleLen(szTitle)
    return UIHelper.LimitUtf8Len(szTitle, 9)
end

function UICoinShopPropItem:UpdateDownloadEquipRes(tList)
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, tList)
    self.tEquipList, self.tEquipSfxList = tEquipList, tEquipSfxList
    self:UpdateDownload()
end

function UICoinShopPropItem:UpdateDownload()
    local tEquipList, tEquipSfxList = self.tEquipList, self.tEquipSfxList
    if not tEquipList or not tEquipSfxList then
        return
    end
    local tConfig = {}
    tConfig.bCoinShop = true
    tConfig.nTouchWidth, tConfig.nTouchHeight = UIHelper.GetContentSize(self.TogPetList)
    tConfig.bSwallowTouch =  false
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetShowCondition(function ()
        return UIHelper.GetSelected(self.TogPetList)
    end)
    scriptMask:SetVisibleChangedCallback(function (bVisible)
        UIHelper.SetTouchEnabled(self.TogPetList, not bVisible)
        UIHelper.SetSwallowTouches(self.TogPetList, false)
        if self.itemIcon then
            self.itemIcon:SetEnable(not bVisible)
        end
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UICoinShopPropItem