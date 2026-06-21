-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIItemTip
local UIItemTip = class("UIItemTip")

local MAX_SCROLL_VIEW_HEIGHT_NOT_GAP = 480
local MAX_SCROLL_VIEW_HEIGHT_HAVE_GAP = 300
local SHOW_SCROLL_GUILD_CRITICAL_VALUE = -30
local LAYOUT_PADDING_BOTTOM = 4
local tbBtnCount2Height = { -- 根据按钮数量获取Tips高度的最小值 [nUpBtnCount][nBottomBtnCount]
    [1] = { [0] = 107, [1] = 107, [2] = 107 },
    [2] = { [0] = 107, [1] = 107, [2] = 203 },
    [3] = { [0] = 203, [1] = 203, [2] = 299 },
    [4] = { [0] = 299, [1] = 299, [2] = 395 },
    [5] = { [0] = 395, [1] = 395, [2] = 491 },
    [6] = { [0] = 491, [1] = 491, [2] = 587 },
}

local function LocalGetSource(tSource, dwItemType, dwItemIndex, nShopNeedCount)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if not tSource then
        return
    end

    local bIsActivityOn = false
    if tSource.tActivity and tSource.tActivity[1] then
        local dwActivityID = tSource.tActivity[1]
        bIsActivityOn = UI_IsActivityOn(dwActivityID) or IsActivityOn(dwActivityID)
    else
        bIsActivityOn = true
    end

    local tbInfo = {}
    tbInfo[1] = {}

    ItemData.GetItemSourceActivity(tSource.tActivity, tbInfo)
    if bIsActivityOn then
        if dwItemType and dwItemIndex then
            ItemData.GetItemSourceShop(tSource.tShop, tbInfo, dwItemType, dwItemIndex, nShopNeedCount)
        end
        if not tSource.tShop or #tSource.tShop == 0 and (not tSource.tReputation or #tSource.tReputation == 0) then
            ItemData.GetSourceShopNpcTip(tSource.tSourceNpc, tbInfo)
        end
        ItemData.GetSourceQuestTip(tSource.tQuests, tbInfo, player)
    end

    if tSource.bTrades then
        if tSource.tLinkItem and #tSource.tLinkItem > 0 then
            local tLinkItemInfo = tSource.tLinkItem[1]
            if tLinkItemInfo then
                ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, tLinkItemInfo[1], tLinkItemInfo[2])
            end
        elseif dwItemType and dwItemIndex then
            ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, dwItemType, dwItemIndex)
        end
    end

    ItemData.GetSourceProduceTip(tSource.tSourceProduce, tbInfo)
    ItemData.GetSourceCollectD(tSource.tSourceCollectD, tbInfo)
    ItemData.GetSourceCollectN(tSource.tSourceCollectN, tbInfo)
    ItemData.GetSourceBossTip(tSource.tBoss, tbInfo)
    ItemData.GetSourceFromItemTip(tSource.tItems, tbInfo)
    ItemData.GetItemSourceCoinShop(tSource.tCoinShop, tbInfo)
    ItemData.GetItemSourceReputation(tSource.tReputation, tbInfo)
    ItemData.GetItemSourceAchievement(tSource.tAchievement, tbInfo)
    ItemData.GetItemSourceAdventure(tSource.tAdventure, tbInfo)
    ItemData.GetSourceOpenPanelTip(tSource.tFunction, tSource.tEventLink, tbInfo)
    return tbInfo
end

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIItemTip:_LuaBindList()
    self.LabelAttachStatus = self.LabelAttachStatus --- 收集状态
end

function UIItemTip:OnInit(nBox, nIndex, bAccountWareHouseItem, dwASPSource)
    if nBox == "CurrencyType" then
        self:OnInitCurrency(nIndex)
        return
    end
    self.nBox = nBox
    self.nIndex = nIndex
    self.dwItemID = nil
    self.nTabType = nil
    self.nTabID = nil
    self.dwEquipID = nil
    self.bItem = true
    self.bAccountWareHouseItem = bAccountWareHouseItem or false
    self.dwASPSource = dwASPSource
    self.nPlayerID = self.nPlayerID or PlayerData.GetPlayerID()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeatureMain1, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeatureSecondary1, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeatureMain2, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeatureSecondary2, false)
    end

    self:UpdateInfo()

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    self:PlayAni()
end

function UIItemTip:OnInitWithTabID(nTabType, nTabID)
    if nTabType == "CurrencyType" then
        self:OnInitCurrency(nTabID)
        return
    end
    if nTabType == "Effect" then
        self:OnInitEffect(nTabID)
        return
    end
    if nTabType == "EquipExterior" or nTabType == "WeaponExterior" then
        self:OnInitExterior(nTabType, nTabID)
        return
    end
    if nTabType == "Pet" then
        nTabType, nTabID = GetItemIndexByFellowPetIndex(nTabID)
        self:OnInitWithTabID(nTabType, nTabID)
        return
    end

    self.nTabType = nTabType
    self.nTabID = nTabID
    self.bItem = false
    self.dwItemID = nil
    self.nBox = nil
    self.nIndex = nil
    self.dwEquipID = nil
    self.bAccountWareHouseItem = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
    end

    self:UpdateInfo()

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    self:PlayAni()
end

function UIItemTip:OnInitCurrency(szName, nCount, bIsReputation)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false
    self.tbScript = self.tbScript or {}
    
    UIHelper.HideAllChildren(self.ScrollViewContent)
    self:UpdateCurrencyInfo(szName, nCount, bIsReputation)

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    if CurrencyData.tbTipGoTo[szName] and not UIMgr.GetView(VIEW_ID.PanelOutfitPreview) then
        self:SetBtnState({
            {
                OnClick = CurrencyData.tbTipGoTo[szName].fnGoto,
                szName = CurrencyData.tbTipGoTo[szName].szBtnName
            }
        })
    else
        self:SetBtnState({})
    end
    self.nTabType = "CurrencyType"
    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()

    self:PlayAni()
end

function UIItemTip:OnInitEffect(nTabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false

    self:UpdateEffectInfo(nTabID)

    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitSkillSkin(nSkillID, nSkinID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false

    self:UpdateSkillSkinInfo(nSkillID, nSkinID)
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitExterior(nTabType, nTabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false
    self.nTabType = nTabType
    self.nTabID = nTabID

    if nTabType == "WeaponExterior" then
        self:UpdateWeaponExteriorInfo(nTabType, nTabID)
    elseif nTabType == "EquipExterior" then
        self:UpdateExteriorInfo(nTabType, nTabID)
    end

    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitRideExterior(dwExteriorID, bEquip)
    local tInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
    if not tInfo then
        return
    end

    local szCollected = ""
    if tInfo.bHave then
        szCollected = g_tStrings.STR_HORSE_EXTERIOR_FILTER[2]
    elseif tInfo.bCollected then
        szCollected = g_tStrings.STR_HORSE_EXTERIOR_FILTER[3]
    elseif tInfo.bCollected == false then
        szCollected = g_tStrings.STR_HORSE_EXTERIOR_FILTER[4]
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end
    self.scriptItemIcon:OnInitWithRideExterior(dwExteriorID, bEquip, true)


    local szName = tInfo.szName
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, szCollected)

    local szQualityBGColor = ItemTipQualityBGColor[tInfo.nQuality + 1] or ItemTipQualityBGColor[1]
    UIHelper.SetSpriteFrame(self.ImgQuality, szQualityBGColor)

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, (tInfo.nQuality or 1) + 1)
    else
        self.scriptQualityBar:OnEnter((tInfo.nQuality or 1) + 1)
    end

    UIHelper.SetVisible(self._rootNode, true)

    if not self.scriptExteriorTopInfo then
        self.scriptExteriorTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    local szType = bEquip and g_tStrings.STR_HORSE_EQUIP_EXTERIOR or g_tStrings.STR_HORSE_EXTERIOR
    UIHelper.SetVisible(self.scriptExteriorTopInfo._rootNode, true)
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType1, szType)
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType2, "")
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType3, "")
    UIHelper.LayoutDoLayout(self.scriptExteriorTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptExteriorTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    UIHelper.SetVisible(self.scriptExteriorTopInfo.WidgetRow2, false)
    UIHelper.SetVisible(self.scriptExteriorTopInfo.WidgetRow3, false)
    UIHelper.LayoutDoLayout(self.scriptExteriorTopInfo.LayoutItemTipTopContent1)

    if not self.scriptExteriorInfo then
        self.scriptExteriorInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
        self.scriptExteriorInfo._rootNode:setName("scriptExteriorInfo")
    end
    UIHelper.SetVisible(self.scriptExteriorInfo._rootNode, false)
    local szInfo = ""
    if not tInfo.bHave then
        szInfo = szInfo .. string.format("<color=#33F3FF>%s</c>", g_tStrings.STR_HORSE_EXTERIOR_RECOMMEND .. "\n")
    end

    if (not tInfo.bHave) and (not tInfo.bCollected) then
        szInfo = szInfo .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_HORSE_EXTERIOR_SOURCE .. "\n")
        szInfo = szInfo .. string.format("<color=#D7F6FF>%s</c>", g_tStrings.STR_HORSE_EQUIP_EXTERIOR_SOURCE .. "\n")
    end

    if (not tInfo.bHave) and (tInfo.bCollected) then
        szInfo = szInfo .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_HORSE_EXTERIOR_PRICE) .. UIHelper.GetMoneyText({nGold = tInfo.nPrice}, 25)
        if tInfo.bOffer then
            szInfo = szInfo .. "\n" .. string.format("<color=#FFE26E>%s</c>", FormatString(g_tStrings.REWARDS_SHOP_DISCOUNT, tInfo.nNowDiscount / 10))
            if tInfo.nDisEndTime > -1 then
                szInfo = szInfo .. ","
				szInfo = szInfo .. string.format("<color=#FFE26E>%s</c>", FormatString(g_tStrings.STR_HORSE_EXTERIOR_PRICE_END, TimeLib.GetDateText(tInfo.nDisEndTime)))
			end
        end
    end

    if szInfo ~= "" then
        self.scriptExteriorInfo:OnEnter({szInfo})
        UIHelper.SetVisible(self.scriptExteriorInfo._rootNode, true)
    end

    local tbInfo = {}
    tbInfo[1] = {}

    ItemData.GetSourceFromItemTip(tInfo.tSourceItem, tbInfo)

    if not self.scriptItemSourceInfo then
        self.scriptItemSourceInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10, self.ScrollViewContent)
        self.scriptItemSourceInfo._rootNode:setName("scriptItemSourceInfo")
    end
    self.scriptItemSourceInfo:OnEnter(tbInfo)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    self:UpdateTipHeight()
    self:PlayAni()
end

local function _fnGetHairDyeTip(nHairID)
    local hPlayer                       = PlayerData.GetClientPlayer()
    local hHairShopClient               = GetHairShop()
    local hDyeingManager                = GetHairCustomDyeingManager()
    local tLogicHairColor        		= hDyeingManager.GetAllHairColor()
    local tHairPrice                    = hHairShopClient.GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.HAIR, nHairID)
    local dwForbidDyeingColorMask  		= tHairPrice.dwForbidDyeingColorMask
    local tNotShowCostType 				= {}
    local szMsg							= g_tStrings.STR_ITEM_HAIR_DYEING_TIP2
    local bFirst						= true

    if not tHairPrice.bCanDyeing then
        return g_tStrings.STR_ITEM_HAIR_NOT_DYEING_TIP2
    end

    if dwForbidDyeingColorMask == 0 then
        return ""
    end

    for k, v in pairs(tLogicHairColor) do
        local dwCostType                = v.nCostType
        if not tNotShowCostType[dwCostType] and kmath.is_logicbit1(dwForbidDyeingColorMask, dwCostType) then
            tNotShowCostType[dwCostType] 	= true
            local tInfo 					= Table_GetDyeingHairCostTypeInfo(dwCostType)
            if tInfo then
                if bFirst then
                    szMsg = table.concat({szMsg, tInfo.szCostTypeName and UIHelper.GBKToUTF8(tInfo.szCostTypeName)})
                else
                    szMsg = table.concat({szMsg, "、", tInfo.szCostTypeName and UIHelper.GBKToUTF8(tInfo.szCostTypeName)})
                end
                bFirst = false
            end
        end
    end

    if bFirst then
        return ""
    end

    return szMsg
end

function UIItemTip:OnInitHair(nHairID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end
    self.scriptItemIcon:OnInitWithIconID(10775, 2, 1)

    local szName = CoinShopHair.GetHairText(nHairID)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(szName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[3])
    local szHad = ""
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.HAIR, nHairID)
    szHad = g_tStrings.tCoinShopOwnType[nOwnType]
    UIHelper.SetString(self.LabelAttachStatus, szHad)

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 3)
    else
        self.scriptQualityBar:OnEnter(3)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    if not self.scriptHairTopInfo then
        self.scriptHairTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end
    local szDye = _fnGetHairDyeTip(nHairID) or ""

    UIHelper.SetVisible(self.scriptHairTopInfo._rootNode, true)
    UIHelper.SetString(self.scriptHairTopInfo.LabelEquipType1, "发型")
    UIHelper.SetString(self.scriptHairTopInfo.LabelEquipType2, szDye)
    UIHelper.SetString(self.scriptHairTopInfo.LabelEquipType3, "")
    UIHelper.LayoutDoLayout(self.scriptHairTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptHairTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    -- UIHelper.SetVisible(self.scriptHairTopInfo.LabelPlayType, false)
    -- UIHelper.SetVisible(self.scriptHairTopInfo.ImgPlayType, false)
    UIHelper.SetVisible(self.scriptHairTopInfo.WidgetRow2, false)
    UIHelper.SetVisible(self.scriptHairTopInfo.WidgetRow3, false)
    UIHelper.LayoutDoLayout(self.scriptHairTopInfo.LayoutItemTipTopContent1)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    self:UpdateTipHeight()
    self:PlayAni()
end

local function _GetFurnitureCollectedInfo(nFurnitureType, dwFurnitureID)
    local szCollected = ""
    if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		local bCollected = HomelandEventHandler.IsFurnitureCollected(dwFurnitureID)
		if bCollected then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_COLLECTED
		elseif bCollected == false then
			szCollected = g_tStrings.STR_FURNITURE_TIP_OWN_STATE_NOT_COLLECTED
		end
	end
    return szCollected
end

function UIItemTip:OnInitFurniture(nFurnitureType, dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false
    self.nFurnitureType = nFurnitureType
    self.dwFurnitureID = dwFurnitureID

    local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    if tUIInfo then
        UIHelper.SetVisible(self._rootNode, true)
    else
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    local szName = tUIInfo.szName
    if tUIInfo.szName then
        szName = UIHelper.GBKToUTF8(tUIInfo.szName)
    else
        szName = "???"
    end
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, _GetFurnitureCollectedInfo(nFurnitureType, dwFurnitureID))
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[(tUIInfo.nQuality or 1) + 1])

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, (tUIInfo.nQuality or 1) + 1)
    else
        self.scriptQualityBar:OnEnter((tUIInfo.nQuality or 1) + 1)
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end

    local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
    local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
    if tAddInfo then
        local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
        szPath = string.gsub(szPath, ".tga", ".png")
        self.scriptItemIcon:SetIconByTexture(szPath)
    end
    self.scriptItemIcon:SetItemQualityBg((tUIInfo.nQuality or 1))

    if not self.scriptFurnitureTopInfo then
        self.scriptFurnitureTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent2, self.WidgetTopContent)
    end

    UIHelper.SetVisible(self.scriptFurnitureTopInfo._rootNode, true)
    self.scriptFurnitureTopInfo:OnInitWithFurniture(self.nFurnitureType, self.dwFurnitureID)

    self:UpdateFurnitureInfoWithFurnitureID(self.nFurnitureType, self.dwFurnitureID)

    -- 添加来源信息
    if tAddInfo and tAddInfo.szFurnitureItemID and tAddInfo.szFurnitureItemID ~= "" then
        local tID = SplitString(tAddInfo.szFurnitureItemID, ";")
        if tID and #tID > 0 then
            local tList = {}
            if #tID > 1 then
                local tFlag = {}
                tList[1] = {}
                for _, v in ipairs(tID) do
                    local tbInfo = self:GetItemSource(nil, ITEM_TABLE_TYPE.HOMELAND, tonumber(v))
                    if tbInfo and not table_is_empty(tbInfo[1]) then
                        for _, tItem in ipairs(tbInfo[1]) do
                            if not tFlag[tItem.szLinkInfo] then
                                table.insert(tList[1], tItem)
                                tFlag[tItem.szLinkInfo] = true
                            end
                        end
                    end
                end
            else
                tList = self:GetItemSource(nil, ITEM_TABLE_TYPE.HOMELAND, tonumber(tID[1]))
            end
            self:ApplyItemSource(tList)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitWithItemID(dwItemID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
    end
    self.bItem = true
    self.dwItemID = dwItemID
    self.nBox = nil
    self.nIndex = nil
    self.nTabType = nil
    self.nTabID = nil
    self.dwEquipID = nil
    local item = GetItem(dwItemID)
    self:UpdateInfo(item)

    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitOperationBoxItem(tbBoxInfo, useCallback)
    self.tbBoxInfo = tbBoxInfo
    if not self.bInit then
        --UIHelper.BindUIEvent(self.BtnFeature, EventType.OnClick, function()
        --    if useCallback then
        --        useCallback(self.tbBoxInfo)
        --    end
        --end)
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false
    self:AddScrollViewSeat()
    self:UpdateOperationBoxItemInfo(tbBoxInfo, useCallback)

    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitEmotionActionTip(tEmotionAction, bUpdate)
    if not bUpdate then
        self.tEmotionAction = tEmotionAction
    elseif self.tEmotionAction.dwID ~= tEmotionAction.dwID then
        return
    end
    if not self.bInit then
        self.bInit = true
        UIHelper.HideAllChildren(self.WidgetTopContent)
        UIHelper.SetVisible(self.WidgetCompare, false)
        UIHelper.SetVisible(self.Eff_TipLight, false)
        local imgLine = self.ImgQuality:getChildByName("ImgLine")
        UIHelper.SetVisible(imgLine, false)
    end
    self.bItem = false
    self:UpdateEmotionActionTip(tEmotionAction)
    -- self:UpdateScrollGuild()

    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitPandentActionTip(itemIndex, nPart, tColor)
    if not self.bInit then
        self.bInit = true
        UIHelper.HideAllChildren(self.WidgetTopContent)
        UIHelper.SetVisible(self.WidgetCompare, false)
        local imgLine = self.ImgQuality:getChildByName("ImgLine")
        UIHelper.SetVisible(imgLine, false)
    end
    self.bItem = false
    self:UpdatePandentActionTip(itemIndex, nPart, tColor)
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitHeadEmotionTip(tHeadEmotion, bUpdate)
    if not bUpdate then
        self.tHeadEmotion = tHeadEmotion
    elseif self.tHeadEmotion.dwID ~= tHeadEmotion.dwID then
        return
    end
    if not self.bInit then
        self.bInit = true
        self.tbScript = self.tbScript or {}
        UIHelper.HideAllChildren(self.WidgetTopContent)
        UIHelper.SetVisible(self.WidgetCompare, false)
        local imgLine = self.ImgQuality:getChildByName("ImgLine")
        -- UIHelper.SetVisible(self.ScrollViewContent, false)
        UIHelper.SetVisible(imgLine, false)
        self.bForbidAutoShortTip = true
    end

    if self.scriptEmptySeat then
        UIHelper.RemoveFromParent(self.scriptEmptySeat._rootNode)
        self.scriptEmptySeat = nil
        self.tbScript["scriptEmptySeat"] = nil
    end

    self.bItem = false
    self:UpdateHeadEmotionTip(tHeadEmotion)
    -- self:UpdateScrollGuild()
    self:PlayAni()
end

function UIItemTip:OnInitWithCoinShopGoods(tbGoods)
    self.tbGoods = tbGoods

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
    end

    if not self.scriptExteriorInfo1 then
        self.scriptExteriorInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent4, self.ScrollViewContent)
    end

    if not self.scriptRewardShopTip then
        self.scriptRewardShopTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
        self.scriptRewardShopTip._rootNode:setName("scriptRewardShopTip")
    end

    if not self.scriptExteriorInfo2 then
        self.scriptExteriorInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent6, self.ScrollViewContent)
    end

    if tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.RENEW then
        self:OnInitExterior("EquipExterior", tbGoods.dwGoodsID)
        return
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        self:OnInitExterior("WeaponExterior", tbGoods.dwGoodsID)
        return
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
        self:OnInitHair(tbGoods.dwGoodsID)
        return
    elseif tbGoods.eGoodsType == COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION then
        self:OnInitPersonalDecoration(tbGoods.dwGoodsID)
        return
    end

    self.nTabType = self.tbGoods.dwTabType
    self.nTabID = self.tbGoods.dwTabIndex
    self.bItem = false
    self.bAccountWareHouseItem = false
    self:UpdateRewardsInfo()

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitWithFishInfo(tbFishInfo, nMaxCount)
    self.tbFishInfo = tbFishInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
    end

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetEquipCompare, false)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tbFishInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutRight)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)

    local szQualityBGColor = ItemTipQualityBGColor[tbFishInfo.nQuality + 1] or ItemTipQualityBGColor[1]
    UIHelper.SetSpriteFrame(self.ImgQuality, szQualityBGColor)

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, tbFishInfo.nQuality + 1)
    else
        self.scriptQualityBar:OnEnter(tbFishInfo.nQuality + 1)
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end
    self.scriptItemIcon:OnInitWithIconID(tbFishInfo.dwIconID, tbFishInfo.nQuality)

    self:UpdateFishDealInfo(tbFishInfo, nMaxCount)

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitIdleActionTip(dwActionID)
    if not self.bInit then
        self.bInit = true
        self.tbScript = self.tbScript or {}
        UIHelper.HideAllChildren(self.WidgetTopContent)
        UIHelper.SetVisible(self.WidgetCompare, false)
        local imgLine = self.ImgQuality:getChildByName("ImgLine")
        UIHelper.SetVisible(imgLine, false)
    end
    self.bItem = false
    self:UpdateIdleActionTip(dwActionID)
    self:UpdateTipHeight()
    self:PlayAni()
end

function UIItemTip:OnInitPersonalDecoration(dwDecorationID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
    end
    self.bItem = false

    self:UpdatePersonalCard(dwDecorationID)

    -- self:UpdateScrollGuild()
    self:UpdateTipHeight()
    self:PlayAni()
end





function UIItemTip:OnExit()
    for szScript, script in pairs(self.tbScript) do
        if script._keepmt then
            self.ScrollViewContent:addChild(script._rootNode)
            script._keepmt = false
            script._rootNode:release()
        end
    end

    if self.fnExit then
        self.fnExit()
        self.fnExit = nil
    end

    self.tbScript = nil
    Event.Dispatch(EventType.OnItemTipSwitchRing, nil, nil)

    self.bInit = false
end

function UIItemTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFeatureMore, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetMoreBtn, not UIHelper.GetVisible(self.WidgetMoreBtn))
    end)

    UIHelper.BindUIEvent(self.BtnEquipCompare, EventType.OnClick, function()
        if self.bItem then
            if self.dwItemID then
                UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.NormalByItemID, self.bItem, { dwItemID = self.dwItemID })
            elseif self.nBox == INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST then
                UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.NormalByBoxIndex, self.bItem, { nBox = self.nBox, nIndex = self.nIndex })
            else
                UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, self.bItem, { nBox = self.nBox, nIndex = self.nIndex })
            end
        else
            UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.NormalByTabID, self.bItem, { nTabID = self.nTabID, nTabType = self.nTabType })
        end
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        if UIMgr.GetView(VIEW_ID.PanelNormalConfirmation) then
            UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
        end
    end)

    UIHelper.BindUIEvent(self.TogRing1, EventType.OnClick, function()
        if self.nBox ~= INVENTORY_INDEX.EQUIP then
            return
        end
        if self.nIndex and self.nIndex == EQUIPMENT_INVENTORY.RIGHT_RING then
            self:OnInit(self.nBox, EQUIPMENT_INVENTORY.LEFT_RING)
            Event.Dispatch(EventType.OnItemTipSelectRing, self.nBox, EQUIPMENT_INVENTORY.LEFT_RING)
        end
    end)

    UIHelper.BindUIEvent(self.TogRing2, EventType.OnClick, function()
        if self.nBox ~= INVENTORY_INDEX.EQUIP then
            return
        end
        if self.nIndex and self.nIndex == EQUIPMENT_INVENTORY.LEFT_RING then
            self:OnInit(self.nBox, EQUIPMENT_INVENTORY.RIGHT_RING)
            Event.Dispatch(EventType.OnItemTipSelectRing, self.nBox, EQUIPMENT_INVENTORY.RIGHT_RING)
        end
    end)

    self:BindItemShare(self.BtnItemShare)

    UIHelper.SetToggleGroupIndex(self.TogRing1, ToggleGroupIndex.ItemTipsRingSwitch)
    UIHelper.SetToggleGroupIndex(self.TogRing2, ToggleGroupIndex.ItemTipsRingSwitch)

    UIHelper.SetTouchDownHideTips(self.BtnItemShare, false)
    UIHelper.SetTouchDownHideTips(self.BtnEquipCompare, false)
    UIHelper.SetTouchDownHideTips(self.TogRing1, false)
    UIHelper.SetTouchDownHideTips(self.TogRing2, false)
    UIHelper.SetTouchDownHideTips(self.ScrollviewName, false)
end

function UIItemTip:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIHelper.SetVisible(self.WidgetMoreBtn, false)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.WidgetOperation)
        self:UpdateTipHeight()
        Timer.AddFrame(self, 3, function()
            if self._hoverTips then
                self._hoverTips:SetNodeData()
                self._hoverTips:UpdatePosByNode()
            end
        end)
    end)

    Event.Reg(self, "ON_QUERY_ITEM_TRADING_INFO_RESPOND", function ()
        local  item = self:GetItem()
        self:UpdateWanBaoLouInfo(item, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        self:UpdateTipHeight()
    end)

    -- Event.Reg(self, "UPDATE_YUNSHI_VALUE", function(nLuckyValue, nID)
    --     local item = self:GetItem()
    --     self:UpdateItemBaseInfo(item, nLuckyValue, nID)
    --     UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    --     self:UpdateTipHeight()
    -- end)

end

function UIItemTip:PlayAni()
    if self.bDisablePlayAni then
        return
    end

    if UIHelper.GetVisible(self._rootNode) and not self.bPlayAni then
        self.bPlayAni = true
        UIHelper.SetOpacity(self._rootNode, 0) --设置初始状态，防止闪
        Timer.Add(self, 0.05, function()
            UIHelper.PlayAni(self, self._rootNode, "AniItemTip", function()
                self.bPlayAni = false
            end)
        end)

        Timer.AddFrame(self, 2, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end)
    end
end

function UIItemTip:BindExitFunc(fnFunc)
    if IsFunction(fnFunc) then
        self.fnExit = fnFunc
    end
end

function UIItemTip:SetPlayAniEnabled(bEnabled)
    self.bDisablePlayAni = not bEnabled
end

function UIItemTip:GetItem()
    local item

    if self.bItem then
        local player = GetClientPlayer()
        if self.nPlayerID then
            player = GetPlayer(self.nPlayerID)
        end
        item = ItemData.GetPlayerItem(player, self.nBox, self.nIndex,
                self.bAccountWareHouseItem and UI_BOX_TYPE.SHAREPACKAGE or nil, self.dwASPSource)
    elseif self.nTabType == "EquipExterior" or self.nTabType == "WeaponExterior" then
        local hExteriorClient = GetExterior()
        if not hExteriorClient then
            return item
        end

        if self.nTabType == "EquipExterior" then
            item = hExteriorClient.GetExteriorInfo(self.nTabID)
        elseif self.nTabType == "WeaponExterior" then
            item = CoinShop_GetWeaponExteriorInfo(self.nTabID, hExteriorClient)
        end
    elseif self.nTabType or self.nTabID then
        item = ItemData.GetItemInfo(self.nTabType, self.nTabID)
    end

    return item
end

function UIItemTip:UpdateInfo(item)
    item = item or self:GetItem()
    if self.nUpdateEquipEnchantAttribInfoTimerID then
        Timer.DelTimer(self, self.nUpdateEquipEnchantAttribInfoTimerID)
        self.nUpdateEquipEnchantAttribInfoTimerID = nil
    end

    if self.nTimeLimitTimerID then
        Timer.DelTimer(self, self.nTimeLimitTimerID)
        self.nTimeLimitTimerID = nil
    end

    if self.nReturnItemTimeLimitTimerID then
        Timer.DelTimer(self, self.nReturnItemTimeLimitTimerID)
        self.nReturnItemTimeLimitTimerID = nil
    end

    if self.nBuyBackItemTimeLimitTimerID then
        Timer.DelTimer(self, self.nBuyBackItemTimeLimitTimerID)
        self.nBuyBackItemTimeLimitTimerID = nil
    end

    if self.nCanTradeLimitTimerID then
        Timer.DelTimer(self, self.nCanTradeLimitTimerID)
        self.nCanTradeLimitTimerID = nil
    end

    self.tbScript = self.tbScript or {}
    self:RemoveAllChildren()

    -- 需求购买条件
    self:UpdateShopLimitInfo(item)
    self:UpdateItemRequireInfo(item)

    self:UpdateBaseInfo(item)
    self:UpdateTopInfo(item)
    self:UpdateItemIgnoreBindMaskInfo(item)
    -- self:UpdateItemBindInfo(item)

    --唯一性
    self:UpdateExistAmountInfo(item)

    -- 装备相关
    self:UpdateEquipCollectionInfo(item)
    self:UpdateEquipBaseInfo(item)
    self:UpdateEquipBoxTipsInfo(item)
    self:UpdateEquipRecommend(item)
    self:UpdateEquipBreakInfo(item)
    self:UpdateEquipMagicAttribInfo(item)
    self:UpdateEquipBaseAttribInfo(item)
    self:UpdateEquipEquipmentRecipeAttribInfo(item)
    self:UpdateEquipMountAttribInfo(item)
    self:UpdateEquipColorMountAttribInfo(item)
    self:UpdateEquipEnchantAttribInfo(item)
    self:UpdateEquipSuitAttribInfo(item)
    self:UpdateOrangeWeaponInfo(item)
    self:UpdateEquipDescInfo(item)
    self:UpdateEquipCustomNameTipInfo(item)
    self:UpdateEquipMiniAvatar(item)
    self:UpdateEquipExteriorInfo(item)
    self:UpdateEquipDisintegrateWarning(item)
    -- 道具相关
    self:UpdateItemBaseInfo(item)
    self:UpdateHairDyeWarning(item)
    self:UpdateSkillSkinWarning(item)   -- 无界殊影无法使用提醒
    self:UpdateSketchMapInfo(item)
    self:UpdateItemTitleTip(item)
    self:UpdateItemDescInfo(item)
    self:UpdateItemTimeLimit(item, true)
    self:UpdateReturnItemTimeLimit(item)
    self:UpdateBuyBackItemTimeLimit(item)
    self:UpdateTradeTimeLimit(item)
    self:UpdateItemCoolDownInfo(item)
    self:UpdateCustomTextInfo(item)

    --阅读相关
    self:UpdateBookBaseInfo(item)
    self:UpdateBookSource(item)

    --家园相关
    self:UpdateFurnitureInfo(item)

    -- 储物箱共享
    self:UpdateItemShareInfo(item)

    -- 更新马属性
    self:OnUpdateHorseAttribute(item)

    --商城相关
    self:UpdateCoinShopInfo(item)

    --获取途径
    self:UpdateItemSource(item)

    --万宝楼数据
    self:UpdateWanBaoLouInfo(item)

    -- --宝箱运势值数据
    -- self:UpdateYunShi(item)

    self:AddScrollViewSeat()
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    self:UpdateBtnState(item)
    self:UpdateTipHeight()
    -- self:UpdateScrollGuild()

end

local function GetItemName(item, nBookID, bItem)
    local szItemName = ""
    local nBookInfo = nil
    if bItem then
        szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
    else
        if item.nGenre == ITEM_GENRE.BOOK then
            nBookInfo = nBookID or item.nDurability
        end
        szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(item, nBookInfo))
    end
    return szItemName
end

function UIItemTip:UpdateRightTopInfo(item)
    UIHelper.SetVisible(self.WidgetItemShare, not self.ForbidShowItemShare)

    local bShowRingSwitch = self:EquipRingCheck()
    local bShowCollected = self:UpdateCollectedInfo(item)  --挂件、玩具收集状态/坐骑饱食度
    local bShowEquipCompare = item.nGenre == ITEM_GENRE.EQUIPMENT and not self.bForbidShowEquipCompareBtn and self:ShowCompareBtnByType(item)

    -- UIHelper.SetVisible(self.ImgShareLine, bShowCollected or bShowEquipCompare or bShowRingSwitch)
    UIHelper.SetVisible(self.WidgetEquipCompare, bShowEquipCompare)
    UIHelper.LayoutDoLayout(self.LayoutRight)
end

function UIItemTip:UpdateBaseInfo(item)
    if item then
        self:UpdateRightTopInfo(item)  -- Tips右上角按钮处理

        UIHelper.SetVisible(self._rootNode, true)
        UIHelper.SetString(self.LabelItemName, GetItemName(item, self.nBookID, self.bItem))
        UIHelper.ScrollViewDoLayout(self.ScrollviewName)
        UIHelper.ScrollToLeft(self.ScrollviewName, 0)

        if item.nQuality then
            local szQualityBGColor = ItemTipQualityBGColor[item.nQuality + 1] or ItemTipQualityBGColor[1]
            UIHelper.SetSpriteFrame(self.ImgQuality, szQualityBGColor)

            if not self.scriptQualityBar then
                self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, item.nQuality + 1)
            else
                self.scriptQualityBar:OnEnter(item.nQuality + 1)
            end
        end

        if not self.scriptItemIcon then
            self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
            self.scriptItemIcon:SetSelectEnable(false)
            self.scriptItemIcon:SetLabelCountVisible(false)
            self.scriptItemIcon:EnableTimeLimitFlag(true)
        end

        if self.bItem then
            if self.nPlayerID then
                self.scriptItemIcon:SetPlayerID(self.nPlayerID)
            end
            if self.nBox and self.nIndex then
                self.scriptItemIcon:OnInit(self.nBox, self.nIndex, nil, self.bAccountWareHouseItem, self.dwASPSource)
            elseif self.bConductorMaterial then
                self.scriptItemIcon:UpdateInfo(item)
            else
                self.scriptItemIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
            end
        else
            self.scriptItemIcon:OnInitWithTabID(self.nTabType, self.nTabID)
        end

        if self.MailItemTips then
            self.scriptItemIcon:UpdateInfo(item)
        end

    else
        UIHelper.SetVisible(self._rootNode, false)
    end
end

function UIItemTip:UpdateTopInfo(item)
    UIHelper.HideAllChildren(self.WidgetTopContent)
    if not item then
        return
    end

    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        if not self.scriptEquipTopInfo then
            self.scriptEquipTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
        end

        UIHelper.SetVisible(self.scriptEquipTopInfo._rootNode, true)
        if self.bItem and self.nBox == 0 and not self.bAccountWareHouseItem then  -- 已装备的需要传入dwX来作为精炼栏位置获取信息
            self.scriptEquipTopInfo:OnEnter(item, self.bItem, self.szBindSource, self.nPlayerID, self.nIndex)
        else
            self.scriptEquipTopInfo:OnEnter(item, self.bItem, self.szBindSource, self.nPlayerID)
        end
    elseif item.nGenre == ITEM_GENRE.HOMELAND then
        if not self.scriptHomelandItemTopInfo then
            self.scriptHomelandItemTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent2, self.WidgetTopContent)
        end

        UIHelper.SetVisible(self.scriptHomelandItemTopInfo._rootNode, true)
        -- self:ShowCompareEquipTip(false)
        self.scriptHomelandItemTopInfo:OnEnter(item, self.bItem, self.szBindSource)
    else
        if not self.scriptItemTopInfo then
            self.scriptItemTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent4, self.WidgetTopContent)
        end

        UIHelper.SetVisible(self.scriptItemTopInfo._rootNode, true)
        -- self:ShowCompareEquipTip(false)
        self.scriptItemTopInfo:OnEnter(item, self.bItem, self.szBindSource, self.nBookID)
    end
end

function UIItemTip:UpdateCurrencyInfo(szName, nCount, bIsReputation)
    local bIsCurrency = Currency_Base.GetCurrencyTypeID(szName) ~= nil -- 非货币仍显示来源和用途描述
    local tCurrencyInfo = Table_GetCurrencyInfoByIndex(szName)
    local szCurrencyName = CurrencyData.GetCurrencyName(szName) 

    UIHelper.SetActiveAndCache(self, self.WidgetItemTipTopContent1, false)   -- 道具装备
    UIHelper.SetActiveAndCache(self, self.WidgetItemTipTopContent3, true)  -- 货币
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])
    UIHelper.SetString(self.LabelAttachStatus, "")
    UIHelper.SetString(self.LabelItemName, szCurrencyName or szName)
    
    
    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
        UIHelper.SetVisible(self.scriptItemIcon.LabelPolishCount, false)
    end

    if not self.scriptItemBaseInfo then
        self.scriptItemBaseInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end
    self.scriptItemBaseInfo:OnEnter({ "" })
    szName = bIsReputation and CurrencyType.Reputation or szName --声望需要转换一下名字
    if szName == CurrencyType.Money then
        self.scriptItemIcon:SetIconBySpriteFrameName(CurrencyData.GetCurCurrencyIconPath())
    else
        self.scriptItemIcon:SetIconBySpriteFrameName(CurrencyData.tbImageBigIcon[szName])
    end
    
    UIHelper.SetSpriteFrame(self.scriptItemIcon.ImgPolishCountBG, ItemQualityBGColor[6])
    self.scriptCurrencyDesc = self.scriptCurrencyDesc or {}
    if not self.scriptCurrencyDesc["Get"] and CurrencyData.tbGetLimit[szName] then
        self.scriptCurrencyDesc["Get"] = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent11, self.ScrollViewContent)
    end
    
    if not bIsCurrency then
        if not self.scriptCurrencyDesc["Source"] and  CurrencyData.tbSourceDesc[szName] then
            self.scriptCurrencyDesc["Source"] = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent11, self.ScrollViewContent)
        end
        if not self.scriptCurrencyDesc["Purpose"] and CurrencyData.tbPurposeDesc[szName] then
            self.scriptCurrencyDesc["Purpose"] = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent11, self.ScrollViewContent)
        end
    end
  
    local tSource = Table_GetCurrencySourceList(szName)
    local tList = LocalGetSource(tSource)
    self:ApplyItemSource(tList) -- 获取途径

    local tUseSource = Table_GetCurrencyShopUseList(szName)
    local tUse = ItemData.GetCurrencySourceShop(tUseSource)
    local useScript = self:AddPrefab("scriptUseInfo", PREFAB_ID.WidgetItemTipContent10)
    useScript:UpdateUseInfo(tUse)

    local tbInfo = {}
    if self.scriptCurrencyDesc["Get"] and CurrencyData.tbGetLimit[szName] then
        local szGet = CurrencyData.tbGetLimit[szName]
        if tCurrencyInfo and not tCurrencyInfo.bHideLimit and (szName ~= CurrencyType.Prestige) then
            szGet = szGet .. "\n" .. "<color=#AED6E0>本周还可获得：<color=#FFEA88>%s</c></c>"
        end
                
        tbInfo = {
            szTitle = CurrencyData.szGetDesc,
            szContent = string.format(szGet, CurrencyData.GetCurCurrencyLimit(szName))
        }
        self.scriptCurrencyDesc["Get"]:OnEnter(tbInfo)
    end

    if self.scriptCurrencyDesc["Source"] and CurrencyData.tbSourceDesc[szName] then
        tbInfo = {
            szTitle = CurrencyData.szSourceDesc,
            szContent = CurrencyData.tbSourceDesc[szName]
        }
        self.scriptCurrencyDesc["Source"]:OnEnter(tbInfo)
    end

    if self.scriptCurrencyDesc["Purpose"] and CurrencyData.tbPurposeDesc[szName] then
        tbInfo = {
            szTitle = CurrencyData.szPurposeDesc,
            szContent = CurrencyData.tbPurposeDesc[szName]
        }
        self.scriptCurrencyDesc["Purpose"]:OnEnter(tbInfo)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)

    if not self.scriptCurrencyTopInfo then
        self.scriptCurrencyTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent3, self.WidgetTopContent)
    end

    UIHelper.SetVisible(self.scriptCurrencyTopInfo._rootNode, true)
    self.scriptCurrencyTopInfo:OnEnter(szName, nCount)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UIItemTip:UpdateEffectInfo(nTabID)
    local tbInfo = Table_GetPendantEffectInfo(nTabID)
    if not tbInfo then
        return
    end

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tbInfo.szName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])
    UIHelper.SetString(self.LabelAttachStatus, "")

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    if not self.scriptEffectTopInfo then
        self.scriptEffectTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    if not self.scriptEffectInfo1 then
        self.scriptEffectInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptEffectInfo2 then
        self.scriptEffectInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    local tbInfo3 = {}
    local szImg = UIHelper.FixDXUIImagePath(tbInfo.szImgPath) or nil
    if Lib.IsFileExist(szImg) then
        tbInfo3[4] = szImg
    end
    if not self.scriptEffectInfo3 then
        self.scriptEffectInfo3 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
        self.scriptEffectInfo3._rootNode:setName("scriptEffectInfo3")
    end

    self.scriptEffectInfo1:OnEnter({ string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tbInfo.szDes)) })
    self.scriptEffectInfo2:OnEnter({ string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tbInfo.szSource)) })
    self.scriptEffectInfo3:OnEnter(tbInfo3)

    UIHelper.SetVisible(self.scriptEffectTopInfo._rootNode, true)

    UIHelper.SetString(self.scriptEffectTopInfo.LabelEquipType1, "特效")
    UIHelper.SetString(self.scriptEffectTopInfo.LabelEquipType2, "")
    UIHelper.SetString(self.scriptEffectTopInfo.LabelEquipType3, "")

    UIHelper.LayoutDoLayout(self.scriptEffectTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptEffectTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    UIHelper.SetVisible(self.scriptEffectTopInfo.LabelPlayType, false)
    UIHelper.SetVisible(self.scriptEffectTopInfo.ImgPlayType, false)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    -- self:UpdateScrollGuild()
end

function UIItemTip:UpdatePersonalCard(dwDecorationID)
    local tData = Table_GetPersonalCardByDecorationID(dwDecorationID)
    if not tData then
        return
    end

    local bHave = dwDecorationID == 0 and true or g_pClientPlayer.IsHaveShowCardDecoration(dwDecorationID)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tData.szName))
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION, dwDecorationID)
    local szHad = dwDecorationID == 0 and "已拥有" or g_tStrings.tCoinShopOwnType[nOwnType]
    if szHad then
        UIHelper.SetString(self.LabelAttachStatus, szHad)
    else
        UIHelper.SetString(self.LabelAttachStatus, bHave and "已解锁" or "未解锁") -- 右上角隐藏
    end
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    if not self.scriptPersonalCardInfo then
        self.scriptPersonalCardInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    if not self.scriptPersonalCardInfoPrice then
        self.scriptPersonalCardInfoPrice = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent4, self.ScrollViewContent)
        UIHelper.SetVisible(self.scriptPersonalCardInfoPrice._rootNode, tData.nSource == PERSONAL_CARD_SOURCE.SHOP and not bHave)
    end

    if not self.scriptPersonalCardInfoDiscount then
        self.scriptPersonalCardInfoDiscount = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent6, self.ScrollViewContent)
        UIHelper.SetVisible(self.scriptPersonalCardInfoDiscount._rootNode, tData.nSource == PERSONAL_CARD_SOURCE.SHOP and not bHave)
    end

    if tData.nSource == PERSONAL_CARD_SOURCE.SHOP then
        local hPriceInfoBase = GetShowCardDecorationSettings().GetPriceInfo(dwDecorationID)
        local tPrice = hPriceInfoBase.tPrice[COIN_SHOP_PAY_TYPE.COIN][COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT]
        local nPrice = tPrice.nPrice

        UIHelper.SetVisible(self.scriptPersonalCardInfoPrice.WidgetAttri1, false)
        UIHelper.SetVisible(self.scriptPersonalCardInfoPrice.RichTextAttri2, false)
        UIHelper.SetString(self.scriptPersonalCardInfoPrice.Label_Xianjia, nPrice)
        UIHelper.CascadeDoLayoutDoWidget(self.scriptPersonalCardInfoPrice._rootNode, true, true)

        local nDis = tPrice.nDiscount or 100
        local nRewards = GetGoodsRewards_UI(COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION, dwDecorationID, false, nDis)
        UIHelper.SetVisible(self.scriptPersonalCardInfoDiscount._rootNode, nRewards ~= 0 and not bHave)
        UIHelper.SetString(self.scriptPersonalCardInfoDiscount.Label_Bingjia, nRewards)
    end

    if not self.scriptPersonalCardInfoOther then
        self.scriptPersonalCardInfoOther = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
    end

    local tbInfo3 = {}
    local szImg = UIHelper.FixDXUIImagePath(tData.szVKSmallPath) or nil
    if Lib.IsFileExist(szImg) then
        tbInfo3[4] = szImg
    end
    if not self.scriptPersonalCardShow then
        self.scriptPersonalCardShow = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
        self.scriptPersonalCardShow._rootNode:setName("scriptPersonalCardShow")
    end
    self.scriptPersonalCardShow:OnEnter(tbInfo3)

    local szSource = tData.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP and g_tStrings.STR_PERSONAL_CARD_COIN_SHOP_TIP or UIHelper.GBKToUTF8(tData.szTip)
    UIHelper.SetVisible(self.scriptPersonalCardInfoOther._rootNode, szSource ~= "")
    if szSource ~= "" then
        self.scriptPersonalCardInfoOther:OnEnter({ string.format("<color=#FFE26E>%s</c>", "解锁途径：".. szSource) })
    end

    local tbInfo4 = {}
    if tData.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP then
        tbInfo4[1] = {}
        local dwLogicID = tData.dwLogicID
        ItemData.GetItemSourceCoinShop({dwLogicID}, tbInfo4)
    end

    if not self.scriptItemSourceInfo then
        self.scriptItemSourceInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10, self.ScrollViewContent)
        self.scriptItemSourceInfo._rootNode:setName("scriptItemSourceInfo")
    end
    self.scriptItemSourceInfo:OnEnter(tbInfo4)

    UIHelper.SetVisible(self.scriptPersonalCardInfo._rootNode, true)

    local szType = ""
    if tData.nDecorationType == SHOW_CARD_DECORATION_TYPE.DECAL then
        szType = "贴花"
    elseif tData.nDecorationType == SHOW_CARD_DECORATION_TYPE.SFX then
        szType = "特效"
    elseif tData.nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
        szType = "边框"
    end
    UIHelper.SetString(self.scriptPersonalCardInfo.LabelEquipType1, szType)
    UIHelper.SetVisible(self.scriptPersonalCardInfo.LabelEquipType2, false)
    UIHelper.SetVisible(self.scriptPersonalCardInfo.LabelEquipType3, false)

    UIHelper.LayoutDoLayout(self.scriptPersonalCardInfo.LayoutRow1)

    for i, img in ipairs(self.scriptPersonalCardInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    UIHelper.SetVisible(self.scriptPersonalCardInfo.LabelPlayType, false)
    UIHelper.SetVisible(self.scriptPersonalCardInfo.ImgPlayType, false)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIItemTip:UpdateOperationBoxItemInfo(tbBoxInfo, useCallback)
    local tbBtnInfo = {}
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetCompare, false)

    local player = PlayerData.GetClientPlayer()
    if not player then return end

	local bLevelToy = tbBoxInfo.nToyType == ToyBoxData.TOY_TYPE.LEVEL
    local szName = UIHelper.GBKToUTF8(tbBoxInfo.szName)
    local nMaxLevel = 0
	local nNowLevel = 0
	local tNextBoxInfo
    local bHad = ToyBoxData.GDAPI_IsToyHave(player, tbBoxInfo.dwID, tbBoxInfo.nCountDataIndex)
    if bLevelToy then
        local tTable = Table_GetToyBoxInfo()
		for k, v in pairs(tTable) do
            if v.nLevelGroup == tbBoxInfo.nLevelGroup then
				nMaxLevel = nMaxLevel + 1
				if v.dwID == tbBoxInfo.dwID then
					nNowLevel = nMaxLevel - 1
                    if bHad then
                        nNowLevel = nNowLevel + 1
                    end
				end
				if nMaxLevel == nNowLevel + 1 then
					tNextBoxInfo = v
				end
			end
		end

        if not bHad then
            nNowLevel = 0
        end

        szName = string.format("%s(当前%d级/共%d级)", szName, nNowLevel, nMaxLevel)
    end

    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, "")
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[tbBoxInfo.nQuality + 1])
    UIHelper.HideAllChildren(self.WidgetTopContent)
    if not self.scriptTopInfo then
        self.scriptTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent4, self.WidgetTopContent)
    end

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, tbBoxInfo.nQuality + 1)
    else
        self.scriptQualityBar:OnEnter(tbBoxInfo.nQuality + 1)
    end

    if not self.scriptToyIcon then
        self.scriptToyIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
    end
    self.scriptToyIcon:OnInitWithIconID(tbBoxInfo.nIcon, tbBoxInfo.nQuality)
    self.scriptToyIcon:SetSelectEnable(false)
    self.scriptToyIcon:SetLabelCountVisible(false)
    self.scriptToyIcon:EnableTimeLimitFlag(true)

    UIHelper.SetVisible(self.scriptTopInfo._rootNode, true)


    UIHelper.SetString(self.scriptTopInfo.LabelType1, "玩具")
    UIHelper.SetString(self.scriptTopInfo.LabelTitle2, "")
    UIHelper.SetString(self.scriptTopInfo.LabelNum2, "")

    UIHelper.SetVisible(self.scriptTopInfo.WidgetRow2, false)
    UIHelper.SetVisible(self.scriptTopInfo.WidgetRow3, false)

    UIHelper.LayoutDoLayout(self.scriptTopInfo.LayoutItemTipTopContent4)

    if not self.scriptToyInfo1 then
        self.scriptToyInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptTipInfo then
        self.scriptTipInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptToyInfo2 then
        self.scriptToyInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    local szTipContent = ToyBoxData.GetGetWayTipsDesc(tbBoxInfo)
    self.scriptTipInfo:OnEnter({string.format("<color=#FFE26E>%s</c>",szTipContent)})

    local szEffect = not string.is_nil(tbBoxInfo.szMobileEffect) and tbBoxInfo.szMobileEffect or tbBoxInfo.szEffect
    if not string.is_nil(szEffect) then
        self.scriptToyInfo1:OnEnter({ string.format("<color=#95FF95>效果：%s</c>", UIHelper.GBKToUTF8(szEffect)) })
    else
        self.scriptToyInfo1:OnEnter({})
    end

    if not string.is_nil(tbBoxInfo.szDesc) then
        self.scriptToyInfo2:OnEnter({ string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tbBoxInfo.szDesc)) })
    else
        self.scriptToyInfo2:OnEnter({})
    end

    if not self.scriptToyInfo3 then
        self.scriptToyInfo3 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end
    if bLevelToy and tNextBoxInfo and nMaxLevel ~= nNowLevel then
        local szNextDesc = "<color=#FFE26E>下一级</c>"
        local szNextName = UIHelper.GBKToUTF8(tNextBoxInfo.szName)
        local nNextMaxLevel = 0
        local nNextNowLevel = 0
        local tTable = Table_GetToyBoxInfo()
        for k, v in pairs(tTable) do
            if v.nLevelGroup == tNextBoxInfo.nLevelGroup then
                nNextMaxLevel = nNextMaxLevel + 1
                if v.dwID == tNextBoxInfo.dwID then
                    nNextNowLevel = nNextMaxLevel
                end
            end
        end

        if not bHad then
            nNextNowLevel = 1
        end

        szNextName = string.format("%s(当前%d级/共%d级)", szNextName, nNextNowLevel, nNextMaxLevel)
        szNextDesc = szNextDesc .. "\n" .. string.format("<color=#FFE26E>%s</c>", szNextName)

        local szEffectNext = not string.is_nil(tNextBoxInfo.szMobileEffect) and tNextBoxInfo.szMobileEffect or tNextBoxInfo.szEffect
        if not string.is_nil(szEffectNext) then
            szNextDesc = szNextDesc .. "\n" .. string.format("<color=#95FF95>效果：%s</c>", UIHelper.GBKToUTF8(szEffectNext))
        end

        local szNextGetWay = ToyBoxData.GetGetWayTipsDesc(tNextBoxInfo)
        if szNextGetWay ~= "" then
            szNextDesc = szNextDesc .. "\n" .. string.format("<color=#FFE26E>%s</c>", szNextGetWay)
        end

        if not string.is_nil(tNextBoxInfo.szDesc) then
            szNextDesc = szNextDesc .. "\n" .. string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tNextBoxInfo.szDesc))
        end

        self.scriptToyInfo3:OnEnter({szNextDesc})
    else
        self.scriptToyInfo3:OnEnter({})
    end

    UIHelper.SetString(self.LabelCompare, "")
    self.hasBuff = GetClientPlayer().IsHaveBuff(tbBoxInfo.nbuff, tbBoxInfo.nbuffLevel)
    if tbBoxInfo.bIsHave then
        local szToyName = self.hasBuff and "收回" or "使用"
        table.insert(tbBtnInfo, { szName = szToyName, OnClick = function()
            if useCallback then
                useCallback(self.tbBoxInfo)
            end
        end })
    end

    UIHelper.SetVisible(self.BtnFeature, false)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    -- -- 分享按钮  -- 现在已经提出到Tips右上角按钮
    -- table.insert(tbBtnInfo, { szName = g_tStrings.SEND_TO_CHAT, OnClick = function()
    --     Event.Dispatch(EventType.HideAllHoverTips)
    --     ChatHelper.SendToyBoxToChat(tbBoxInfo.dwID)
    -- end })

    --查看按钮
    local tLine = Table_GetToyBox(tbBoxInfo.dwID)
    if tLine.dwSetID > 0 then
        table.insert(tbBtnInfo, { szName = g_tStrings.STR_LOOK, OnClick = function()
            UIMgr.Open(VIEW_ID.PanelToyPuzzle, tLine.dwSetID)
        end })
    end
    --local useBtnCount = #tbBtnInfo
    --if useBtnCount == 2 then
    --    UIHelper.SetVisible(self.Widget2Btns, true)
    --    UIHelper.SetVisible(self.BtnFeatureMain1, tbBoxInfo.bIsHave)
    --    local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeatureMain1)
    --    scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
    --    local scriptBtn2 = UIHelper.GetBindScript(self.BtnFeatureSecondary1)
    --    scriptBtn2:OnEnter(tbBtnInfo[2].OnClick, tbBtnInfo[2].szName)
    --end
    --UIHelper.LayoutDoLayout(self.Widget2Btns)
    self:SetBtnState(tbBtnInfo)
end

function UIItemTip:UpdateEmotionActionTip(tEmotionAction)
    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    --UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bg06")
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tEmotionAction.szName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, "")

    if not self.emotionActionText then
        self.emotionActionText = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.WidgetTopContent2)
        self.emotionActionText._rootNode:setName("emotionActionText")
        UIHelper.SetVisible(self.emotionActionText.ImgLine, false)
    end
    if not self.emotionActionImg then
        UIHelper.RemoveAllChildren(self.ScrollViewContent)
        self.emotionActionImg = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
        self.emotionActionImg._rootNode:setName("emotionActionImg")
        UIHelper.SetVisible(self.emotionActionImg.RichTextAttri1, false)
        UIHelper.SetVisible(self.emotionActionImg.ImgLine, false)
    end

    local tipText = self.emotionActionText
    local tipImg = self.emotionActionImg

    local nCommon = EmotionData.GetEmotionCommonType()
    local nActionType = tEmotionAction.nActionType or nCommon
    local bFavi = EmotionData.IsFaviEmotionAction(tEmotionAction.dwID)

    if nActionType == nCommon then

        local szTarget = "有目标时：" .. UIHelper.GBKToUTF8(tEmotionAction.szTarget)
        local szNoTarget = "无目标时：" .. UIHelper.GBKToUTF8(tEmotionAction.szNoTarget)
        local szTip = szNoTarget .. "\n" .. szTarget
        if tEmotionAction.bInteract then
            szTip = szTip .. "\n" .. "该动作需要双人才能完成"
        end
        UIHelper.SetRichText(tipText.RichTextAttri1, szTip)
        UIHelper.SetVisible(tipText.RichTextAttri1, true)

        UIHelper.SetVisible(tipImg.ImgEmotionPose, false)

        UIHelper.SetString(self.LabelFeature, (bFavi and "取消快捷") or "加入快捷")
        UIHelper.SetVisible(self.BtnFeature, true)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    else
        local szTip = tEmotionAction.szTip
        szTip = string.gsub(szTip, '" font=105</text><text>text="\\', "")
        szTip = string.gsub(szTip, '" font=18</text>', "")
        szTip = string.gsub(szTip, '<text>text="', "")
        UIHelper.SetRichText(tipText.RichTextAttri1, UIHelper.GBKToUTF8(szTip))
        UIHelper.SetVisible(tipText.RichTextAttri1, true)

        if tipImg.ImgEmotionPose and tEmotionAction.szPath then
            local imgPath = string.gsub(tEmotionAction.szPath, 'ui\\Image', 'mui\\Resource')
            imgPath = string.gsub(imgPath, 'tga', 'png')
            tipImg:OnEnter({[3] = imgPath})
            -- UIHelper.SetTexture(tipImg.ImgEmotionPose, imgPath)
            -- UIHelper.SetVisible(tipImg.ImgEmotionPose, true)
        else
            UIHelper.SetVisible(tipImg.ImgEmotionPose, false)
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    end

    local btnInfo = {}
    if tEmotionAction.bLearned then
        table.insert(btnInfo, {szName = "使用", OnClick = function ()
            EmotionData.ProcessEmotionActionTemp(tEmotionAction.dwID, true)
        end})

        table.insert(btnInfo, {
            szName = (bFavi and "取消快捷") or "加入快捷",
            OnClick = function()
                if EmotionData.IsFaviEmotionActionbFull() and not bFavi then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_EMOTIONACTION_DIY_BE_FULL)
                else
                    local hPlayer = GetClientPlayer()
                    hPlayer.SetMobileEmotionActionDIYInfo(not bFavi, tEmotionAction.dwID)
                end
            end
        })
    end

    self:SetBtnState(btnInfo)
end

function UIItemTip:UpdateHeadEmotionTip(tHeadEmotion)
    --UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tHeadEmotion.szName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, "")

    local pattern = 'text="(.-)"'
    local szDesc = tHeadEmotion.szDesc:match(pattern)

    if not szDesc or szDesc == "" then
        if self.emotionActionText then
            UIHelper.SetVisible(self.emotionActionText._rootNode, false)
        end
    else
        if not self.emotionActionText then
            self.emotionActionText = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.WidgetTopContent)
            self.emotionActionText._rootNode:setName("emotionActionText")
            UIHelper.SetVisible(self.emotionActionText.ImgLine, false)
        end
        UIHelper.SetVisible(self.emotionActionText._rootNode, true)
        local tipText = self.emotionActionText

        UIHelper.SetRichText(tipText.RichTextAttri1, UIHelper.GBKToUTF8(szDesc) or "")
        UIHelper.SetVisible(tipText.RichTextAttri1, true)
    end

    local bFavi = HeadEmotionData.IsFaviHeadEmotion(tHeadEmotion.dwID)
    local bLike = HeadEmotionData.IsLikeHeadEmotion(tHeadEmotion.dwID)

    local szItemIndex = tHeadEmotion.szItemIndex
    if szItemIndex and szItemIndex ~= "" then
        local tList = {}
        local tItemList = SplitString(szItemIndex, ";")
        local dwDefaultIndex
        for _, szItem in ipairs(tItemList) do
            local dwItemIndex = tonumber(szItem)
            if dwItemIndex and dwItemIndex ~= 0 then
                if not dwDefaultIndex then
                    dwDefaultIndex = dwItemIndex
                    break
                end
            end
        end
        self:UpdateItemSource(nil, 5, dwDefaultIndex)
    else
        if self.scriptItemSourceInfo then
            UIHelper.SetVisible(self.scriptItemSourceInfo._rootNode, false)
        end
    end

    local btnInfo = {}

    if tHeadEmotion.bLearned then
        table.insert(btnInfo, {szName = "使用", OnClick = function ()
            HeadEmotionData.ProcessHeadEmotion(tHeadEmotion.dwID)
        end})

        table.insert(btnInfo, {
            szName = (bFavi and "取消快捷") or "加入快捷",
            OnClick = function()
                if HeadEmotionData.IsFaviEmotionActionbFull() and not bFavi then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HEADEMOTION_DIY_BE_FULL)
                else
                    local hPlayer = GetClientPlayer()
                    hPlayer.SetMobileHeadEmotionDIYInfo(not bFavi, tHeadEmotion.dwID)
                end
            end
        })
    end

    table.insert(btnInfo, {
        szName = (bLike and "取消收藏") or "加入收藏",
        OnClick = function()
            if not bLike then
                if HeadEmotionData.IsLikeHeadEmotionbFull() then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL",  "请先取消其他头顶表情的收藏")
                end
                RemoteCallToServer("On_HeadEmotion_StarEmotion", tHeadEmotion.dwID)
            else
                RemoteCallToServer("On_HeadEmotion_UnstarEmotion", tHeadEmotion.dwID)
            end
        end
    })
    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end
    self.scriptBtnList:OnEnter(btnInfo)
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    self:UpdateTmpTipHeight()
end

function UIItemTip:UpdateTmpTipHeight()
    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end

    if table_is_empty(UIHelper.GetChildren(self.WidgetAnchorQuantity)) then
        UIHelper.SetVisible(self.WidgetAnchorQuantity, false)
    end

    local nWidgetFixWidth = 0
    local bButtonGapIsAct = UIHelper.GetVisible(self.WidgetAnchorQuantity)
    --暂定有按钮操作时固定高度
    local fWidth = UIHelper.GetContentSize(self.ScrollViewContent)
    local innerContainer = self.ScrollViewContent:getInnerContainer()
    local nWidth, nHeight = UIHelper.GetContentSize(innerContainer)
    local nMinHeight = 0
    local nTopBtnCount, nBottomBtnCount= self.scriptBtnList:GetBtnCount()
    if nTopBtnCount and nTopBtnCount > 0 then
        nBottomBtnCount = nBottomBtnCount or 0
        nMinHeight = tbBtnCount2Height[nTopBtnCount][nBottomBtnCount]
        if nMinHeight and nMinHeight > nHeight then
            self:AddScrollViewSeat(nMinHeight - nHeight)
            nHeight = math.max(nHeight, nMinHeight)
        end
    end
    nHeight = math.min(nHeight, bButtonGapIsAct and MAX_SCROLL_VIEW_HEIGHT_HAVE_GAP or MAX_SCROLL_VIEW_HEIGHT_NOT_GAP)
    UIHelper.SetContentSize(self.ScrollViewContent, fWidth, nHeight)
    UIHelper.SetContentSize(self.WidgetArrowContent, fWidth, nHeight)
    UIHelper.SetPaddingLayoutBottom(self.LayoutContentAll, nHeight > 0 and LAYOUT_PADDING_BOTTOM or 0)
    UIHelper.SetTouchEnabled(self.LayoutContentAll, true)
    UIHelper.SetTouchDownHideTips(self.LayoutContentAll, false)

    UIHelper.LayoutDoLayout(self.LayoutContentAll)
    UIHelper.LayoutDoLayout(self._rootNode)

    self:UpdateWidgetBtnListHeight()
    Timer.AddFrame(self, 1, function()
        if self._hoverTips and UIHelper.GetVisible(self.WidgetOperation) then
            nWidgetFixWidth = 260
        end

        local fWidth, nHeight = UIHelper.GetContentSize(self.LayoutContentAll)
        UIHelper.SetContentSize(self._rootNode, fWidth + nWidgetFixWidth, nHeight)
        UIHelper.SetContentSize(self.WidgetAnchorContent, fWidth, nHeight)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, false)
        UIHelper.WidgetFoceDoAlign(self)

        if self._hoverTips then
            self._hoverTips:SetNodeData()
            self._hoverTips:UpdatePosByNode()
        end
        self:UpdateScrollGuild()
        self:UpdateWidgetBtnListHeight()
    end)
end

function UIItemTip:UpdateHeadEmotionSource(dwItemType, dwItemIndex)
    self:RemoveAllChildren()

    local player = GetClientPlayer()
    if not player then
        return
    end

    if not dwItemType or not dwItemIndex then
        return
    end

    local tSource = ItemData.GetItemSourceList(dwItemType, dwItemIndex)
    if not tSource then
        return
    end

    local bIsActivityOn = false
	if tSource.tActivity and tSource.tActivity[1] then
		local dwActivityID = tSource.tActivity[1]
		bIsActivityOn = UI_IsActivityOn(dwActivityID) or ActivityData.IsActivityOn(dwActivityID)
	else
		bIsActivityOn = true
	end


    local tbInfo = {}
    tbInfo[1] = {}

    ItemData.GetItemSourceActivity(tSource.tActivity, tbInfo)
    if bIsActivityOn then
		ItemData.GetItemSourceShop(tSource.tShop, tbInfo, dwItemType, dwItemIndex, self.nShopNeedCount)
		if not tSource.tShop or #tSource.tShop == 0 then
			ItemData.GetSourceShopNpcTip(tSource.tSourceNpc, tbInfo)
		end
		ItemData.GetSourceQuestTip(tSource.tQuests, tbInfo, player)
	end

    if tSource.bTrades then
		if tSource.tLinkItem and #tSource.tLinkItem > 0 then
			local tLinkItemInfo = tSource.tLinkItem[1]
			if tLinkItemInfo then
                ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, tLinkItemInfo[1], tLinkItemInfo[2])
			end
		else
            ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, dwItemType, dwItemIndex)
		end
	end

    ItemData.GetSourceProduceTip(tSource.tSourceProduce, tbInfo)
    ItemData.GetSourceCollectD(tSource.tSourceCollectD, tbInfo)
    ItemData.GetSourceCollectN(tSource.tSourceCollectN, tbInfo)
    ItemData.GetSourceBossTip(tSource.tBoss, tbInfo)
    ItemData.GetSourceFromItemTip(tSource.tItems, tbInfo)
	ItemData.GetItemSourceCoinShop(tSource.tCoinShop, tbInfo)
    ItemData.GetItemSourceReputation(tSource.tReputation, tbInfo)
	ItemData.GetItemSourceAchievement(tSource.tAchievement, tbInfo)
	ItemData.GetItemSourceAdventure(tSource.tAdventure, tbInfo)
	ItemData.GetSourceOpenPanelTip(tSource.tFunction, tSource.tEventLink, tbInfo)

    if not self.scriptItemSourceInfo then
        self.scriptItemSourceInfo = self:AddPrefab("scriptItemSourceInfo", PREFAB_ID.WidgetItemTipContent10)
        self.tbScript["scriptItemSourceInfo"] = self.scriptItemSourceInfo
    end
    self.scriptItemSourceInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateIdleActionTip(dwActionID)
    local player = GetClientPlayer()
    local tbInfo = Table_GetIdleAction(dwActionID)
    if not tbInfo or table.is_empty(tbInfo) or not player then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end
    self.nTabType, self.nTabID = tbInfo.dwItemType, tbInfo.dwItemID
    local item = self:GetItem()
    self:RemoveAllChildren()
    if not self.scriptIdleActionTopInfo then
        self.scriptIdleActionTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    UIHelper.SetVisible(self.LabelAttachStatus, false)
    UIHelper.SetVisible(self.scriptIdleActionTopInfo._rootNode, true)
    UIHelper.SetString(self.scriptIdleActionTopInfo.LabelEquipType1, "站姿")
    UIHelper.SetString(self.scriptIdleActionTopInfo.LabelEquipType2, "")
    UIHelper.SetString(self.scriptIdleActionTopInfo.LabelEquipType3, "")

    UIHelper.LayoutDoLayout(self.scriptIdleActionTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptIdleActionTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end
    UIHelper.SetVisible(self.scriptIdleActionTopInfo.LabelPlayType, false)
    UIHelper.SetVisible(self.scriptIdleActionTopInfo.ImgPlayType, false)

    local tbInfo2 = {}
    local szImg = CharacterIdleActionData.GetPreviewImgByID(dwActionID, player.nRoleType)
    if szImg and not string.is_nil(szImg) then
        tbInfo2[4] = szImg
    end

    if not self.scriptIdleAction then
        self.scriptIdleAction = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
    end

    self.scriptIdleAction:OnEnter(tbInfo2)
    self:UpdateItemSource(item)

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tbInfo.szActionName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    UIHelper.SetVisible(self._rootNode, true)
end

function UIItemTip:UpdatePandentActionTip(nTabID, nPart, tColor)
    self.nTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    self.nTabID = nTabID
    local item = self:GetItem()
    self:RemoveAllChildren()
    self:UpdateBaseInfo(item)
    self:UpdateTopInfo(item)
    self:UpdateEquipDescInfo(item)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)

    local _, dwUsingPendantID = CharacterPendantData.GetPendentInfo(nPart)
    local bFavi = dwUsingPendantID == nTabID
    local tbPendantInfo = { dwItemIndex = nTabID }
    if tColor and not table.is_empty(tColor) then
        tbPendantInfo.tData = tColor
    end

    local btnInfo = {
        {
            szName = (bFavi and "取消快捷") or "加入快捷",
            OnClick = function()
                if bFavi then
                    CharacterPendantData.EquipPendant(tbPendantInfo, nPart, false)
                else
                    CharacterPendantData.EquipPendant(tbPendantInfo, nPart, true)
                end
            end
        }
    }
    self:SetBtnState(btnInfo)
end

function UIItemTip:UpdateWeaponExteriorInfo(nTabType, nTabID)
    local item = self:GetItem()
    if not item then
        return
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end
    self.scriptItemIcon:OnInitWithTabID(nTabType, nTabID)

    local tUIInfo = g_tTable.CoinShop_Weapon:Search(nTabID)
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tUIInfo.szName))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])
    UIHelper.SetString(self.LabelAttachStatus, "")

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    if not self.scriptWeaponExteriorTopInfo then
        self.scriptWeaponExteriorTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    UIHelper.SetVisible(self.scriptWeaponExteriorTopInfo._rootNode, true)

    local hCoinShopClient = GetCoinShopClient()
    if hCoinShopClient then
        local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, nTabID)
        local szHaveString = g_tStrings.tCoinShopOwnType[nHaveType]
        UIHelper.SetString(self.scriptWeaponExteriorTopInfo.LabelEquipType1, "武器外装")
        UIHelper.SetString(self.scriptWeaponExteriorTopInfo.LabelEquipType2, "")
        UIHelper.SetString(self.scriptWeaponExteriorTopInfo.LabelEquipType3, "")
    end

    UIHelper.LayoutDoLayout(self.scriptWeaponExteriorTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptWeaponExteriorTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    -- UIHelper.SetVisible(self.scriptWeaponExteriorTopInfo.LabelPlayType, false)
    -- UIHelper.SetVisible(self.scriptWeaponExteriorTopInfo.ImgPlayType, false)
    UIHelper.SetVisible(self.scriptWeaponExteriorTopInfo.WidgetRow2, false)
    UIHelper.SetVisible(self.scriptWeaponExteriorTopInfo.WidgetRow3, false)
    UIHelper.LayoutDoLayout(self.scriptWeaponExteriorTopInfo.LayoutItemTipTopContent1)

    local szHad = ""
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, nTabID)
    szHad = g_tStrings.tCoinShopOwnType[nOwnType]
    UIHelper.SetString(self.LabelAttachStatus, szHad)
    local bHave = nOwnType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, nTabID)
    if bCollect then
        if not bHave then
            if not self.scriptExteriorInfo1 then
                self.scriptExteriorInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent4, self.ScrollViewContent)
            end
            if not self.scriptExteriorInfo2 then
                self.scriptExteriorInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent6, self.ScrollViewContent)
            end
            local tbInfo = CoinShop_GetWeaponPriceInfo(nTabID) or {}
            self.scriptExteriorInfo1:OnEnter(tbInfo)
            self.scriptExteriorInfo2:OnEnter(tbInfo, nTabType, nTabID)
        end
    else
        UIHelper.SetString(self.LabelAttachStatus, "未收集")

        if not self.scriptExteriorCollectInfo1 then
            self.scriptExteriorCollectInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent7, self.ScrollViewContent)
        end
        if not self.scriptExteriorCollectInfo2 then
            self.scriptExteriorCollectInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
            self.scriptExteriorCollectInfo2._rootNode:setName("scriptExteriorCollectInfo2")
        end

        local tbInfo = {}
        if nGold > 0 then
            table.insert(tbInfo, "金币" .. nGold)
        end
        self.scriptExteriorCollectInfo1:OnEnter(tbInfo)

        tbInfo = {}
        local tSrc = CoinShop_GetSrc(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, nTabID)
        local szContent = "<color=#FFE26E>外观出处</c>\n"
        for i, tInfo in ipairs(tSrc) do
            local tResult = EquipInquire_FormatData(tInfo)
            local szSource = EquipInquire_GetItemSourceDesc(tResult, true)
            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_ARMOR, tInfo.dwItemIndex)
            local szText = string.format("<color=%s>%s</c>", ItemQualityColor[hItemInfo.nQuality], UIHelper.GBKToUTF8(tInfo.szItemName))
            szText = szText .. "\n" .. UIHelper.GBKToUTF8(szSource)

            if i < #tSrc then
                szText = szText .. "\n"
            end

            szContent = szContent .. szText
        end
        if #tSrc <= 0 then
            szContent = GetFormatText(g_tStrings.COINSHOP_SOURCE_NULL)
        end

        table.insert(tbInfo, szContent)

        self.scriptExteriorCollectInfo2:OnEnter(tbInfo)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UIItemTip:UpdateExteriorInfo(nTabType, nTabID)
    local item = self:GetItem()
    if not item then
        return
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
        self.scriptItemIcon:SetSelectEnable(false)
        self.scriptItemIcon:SetLabelCountVisible(false)
        self.scriptItemIcon:EnableTimeLimitFlag(true)
    end
    self.scriptItemIcon:OnInitWithTabID(nTabType, nTabID)

    local szName = UIHelper.GBKToUTF8(Table_GetExteriorSetName(item.nGenre, item.nSet))
    szName = szName .. g_tStrings.STR_CONNECT .. g_tStrings.tExteriorSubName[item.nSubType]
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    if not self.scriptExteriorTopInfo then
        self.scriptExteriorTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end
    UIHelper.SetVisible(self.scriptExteriorTopInfo._rootNode, true)
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType1, "装备外装")
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType2, "")
    UIHelper.SetString(self.scriptExteriorTopInfo.LabelEquipType3, "")
    UIHelper.LayoutDoLayout(self.scriptExteriorTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptExteriorTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end

    -- UIHelper.SetVisible(self.scriptExteriorTopInfo.LabelPlayType, false)
    -- UIHelper.SetVisible(self.scriptExteriorTopInfo.ImgPlayType, false)
    UIHelper.SetVisible(self.scriptExteriorTopInfo.WidgetRow2, false)
    UIHelper.SetVisible(self.scriptExteriorTopInfo.WidgetRow3, false)
    UIHelper.LayoutDoLayout(self.scriptExteriorTopInfo.LayoutItemTipTopContent1)

    local player = PlayerData.GetClientPlayer()
    local nTimeType, nTime = player.GetExteriorTimeLimitInfo(nTabID)
    local szHad = ""
    local bShowPrice = true
    if nTimeType then
        if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT then
            szHad = g_tStrings.EXTERIOR_HAVE_PERMANENT
            bShowPrice = false
        else
            if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
                nTime = GetCoinShopClient().GetFreeTryOnEndTime()
            end
            local nLeftTime = nTime - GetCurrentTime()
            if nLeftTime < 0 then
                nLeftTime = 0
            end
            szHad = TimeLib.GetTimeText(nLeftTime, nil, true)
            szHad = FormatString(g_tStrings.EXTERIOR_HAVE, szHad)
        end
    else
        local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, nTabID)
        szHad = g_tStrings.tCoinShopOwnType[nOwnType]
    end

    UIHelper.SetString(self.LabelAttachStatus, szHad)

    local bCollect, nGold = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, nTabID)
    if bCollect then
        if bShowPrice then
            if not self.scriptExteriorInfo1 then
                self.scriptExteriorInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent4, self.ScrollViewContent)
            end
            if not self.scriptExteriorInfo2 then
                self.scriptExteriorInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent6, self.ScrollViewContent)
            end
            local tbInfo = CoinShop_GetExteriorPriceInfo(nTabID) or {}
            self.scriptExteriorInfo1:OnEnter(tbInfo)
            self.scriptExteriorInfo2:OnEnter(tbInfo, nTabType, nTabID)
        end
    else
        UIHelper.SetString(self.LabelAttachStatus, "未收集")

        if not self.scriptExteriorCollectInfo1 then
            self.scriptExteriorCollectInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent7, self.ScrollViewContent)
        end
        if not self.scriptExteriorCollectInfo2 then
            self.scriptExteriorCollectInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
            self.scriptExteriorCollectInfo2._rootNode:setName("scriptExteriorCollectInfo2")
        end

        local tbInfo = {}
        if nGold > 0 then
            table.insert(tbInfo, "金币" .. nGold)
        end
        self.scriptExteriorCollectInfo1:OnEnter(tbInfo)

        tbInfo = {}
        local tSrc = CoinShop_GetSrc(COIN_SHOP_GOODS_TYPE.EXTERIOR, nTabID)
        local szContent = "<color=#FFE26E>外观出处</c>\n"
        for i, tInfo in ipairs(tSrc) do
            local tResult = EquipInquire_FormatData(tInfo)
            local szSource = EquipInquire_GetItemSourceDesc(tResult, true)
            local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_ARMOR, tInfo.dwItemIndex)
            local szText = string.format("<color=%s>%s</c>", ItemQualityColor[hItemInfo.nQuality], UIHelper.GBKToUTF8(tInfo.szItemName))
            szText = szText .. "\n" .. UIHelper.GBKToUTF8(szSource)

            if i < #tSrc then
                szText = szText .. "\n"
            end

            szContent = szContent .. szText
        end
        if #tSrc <= 0 then
            szContent = GetFormatText(g_tStrings.COINSHOP_SOURCE_NULL)
        end

        table.insert(tbInfo, szContent)

        self.scriptExteriorCollectInfo2:OnEnter(tbInfo)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UIItemTip:UpdateRewardsInfo(item)
    UIHelper.HideAllChildren(self.WidgetTopContent)
    UIHelper.HideAllChildren(self.ScrollViewContent)

    self:UpdateInfo(item)

    if not self.tbGoods.dwGoodsID then
        return
    end

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

    local nHaveType = hCoinShopClient.CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.ITEM, self.tbGoods.dwGoodsID)
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE and nHaveType ~= COIN_SHOP_OWN_TYPE.FREE_TRY_ON
    if not bHave then
        if not self.scriptExteriorInfo1 then
            self.scriptExteriorInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent4, self.ScrollViewContent)
        end
        if not self.scriptExteriorInfo2 then
            self.scriptExteriorInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent6, self.ScrollViewContent)
        end
        local tbInfo = CoinShop_GetRewardsPriceInfo(self.tbGoods.dwGoodsID)
        self.scriptExteriorInfo1:OnEnter(tbInfo)
        self.scriptExteriorInfo2:OnEnter(tbInfo, "Rewards", self.tbGoods.dwGoodsID)
    end

    self:UpdateRewardShopTip()

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UIItemTip:SetMailItem()
    self.MailItemTips = true
end

-- 1. 如果有绑定关系，且不为0, 用绑定关系里面记录的五彩石
-- 2. 如果有绑定关系，且为0，如果武器上有五彩石, 用武器上的五彩石
-- 3. 如果有绑定关系, 且为0，并且武器上没有五彩石, 那就直接返回没有五彩石
-- 4. 如果没有绑定关系, 如果武器上有五彩石, 用武器上的五彩石
-- 5. 排除以上情况后（如果没有绑定关系）, 根据武器品级, 去装备栏里面从左往右找第一个符合融嵌条件的五彩石（品级）

--获取武器的五彩石附魔ID
local function GetWeaponFEAEnchantID(dwPlayerID, item, bItem)
    local nEnchantID = 0
    local dwTabType = 0
    local dwItemIndex = 0

    if bItem then
        dwTabType = item.dwTabType
        dwItemIndex = item.dwIndex or item.dwID
    else
        dwTabType = ITEM_TABLE_TYPE.CUST_WEAPON
        dwItemIndex = item.dwID
    end

    if not dwTabType or not dwItemIndex then
        return nEnchantID
    end

    local hPlayer = GetPlayer(dwPlayerID)
    if not hPlayer then
        return nEnchantID
    end
    --地图掩码不显示五彩石
    if item.dwMapBanEquipItemMask == 1 then
        return nEnchantID
    end

    --若装备栏中有五彩石
    local nSlotIndex = -1
    if hPlayer then
        local tBindInfo = hPlayer.GetColorDiamondSlotBindWeaponInfo()
        for k, v in pairs(tBindInfo) do
            if v[1] == dwTabType and v[2] == dwItemIndex then
                nSlotIndex = v[3]
                break
            end
        end
    end

    if nSlotIndex > 0 then
        --装备栏中有绑定关系且不为0,直接用绑定的五彩石
        local dwEnchantID, nCurrentLevel = hPlayer.GetColorDiamondSlotInfo(nSlotIndex)
        if dwEnchantID > 0 and nCurrentLevel >= item.nLevel then
            nEnchantID = dwEnchantID
        end
    else
        if bItem then
            --武器自身有五彩石
            nEnchantID = item.GetMountFEAEnchantID()
        end
        if not nEnchantID or nEnchantID <= 0 and nSlotIndex == -1 and hPlayer then
            --武器自身没用五彩石,且绑定方案没有,去装备栏里面从左往右找第一个符合融嵌条件的五彩石（品级）
            for i = 1, 4 do
                local dwEnchantID, nCurrentLevel = hPlayer.GetColorDiamondSlotInfo(i)
                if dwEnchantID > 0 and nCurrentLevel >= item.nLevel then
                    nEnchantID = dwEnchantID
                    break
                end
            end
        end
    end

    return nEnchantID
end

-- 装备分数
local function GetEquipScoreTip(item, bItem, nPlayerID, nEquipInv, tbPowerUpInfo)
    local szTip = ""
    if bItem then
        local nBaseScore = item.nBaseScore
        local nStrengthScore = 0
        local nStoneScore = item.nMountsScore
        nPlayerID = nPlayerID or PlayerData.GetPlayerID()

        if nPlayerID then
            local tInfo = EquipData.GetStrength(item, bItem, { dwPlayerID = nPlayerID, dwX = nEquipInv })
            nStrengthScore = item.CalculateStrengthScore(tInfo.nTrueLevel, item.nLevel)

            local player = GetPlayer(nPlayerID)
            if player then
                local nEquipInv = nEquipInv or EquipData.GetEquipInventory(item.nSub, item.nDetail)
                if item.nDetail and item.nDetail == WEAPON_DETAIL.BIG_SWORD and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
                    nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
                end

                local dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2 = 0, 0, 0, 0, 0, 0
                local dwFEAEnchangeID = GetWeaponFEAEnchantID(nPlayerID, item, bItem)

                dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2 = player.GetEquipBoxAllMountDiamondEnchantID(nEquipInv)
                nStoneScore = item.CalculateMountsScore(dwEnchantID0, nCurrentLevel0, dwEnchantID1, nCurrentLevel1, dwEnchantID2, nCurrentLevel2, dwFEAEnchangeID)
            end
        end

        if nBaseScore >= 0 then
            szTip = string.format("<color=#FFE26E>装备分数  %d</c>", nBaseScore)
            if nStrengthScore > 0 or nStoneScore > 0 then
                szTip = szTip .. string.format("<color=#70FFBB>（+%d+%d）</c>", nStrengthScore, nStoneScore)
            end
        end
    elseif tbPowerUpInfo then
        local nBaseScore = item.nBaseScore
        local nStrengthScore = 0
        local nStoneScore = 0
        if nBaseScore > 0 then
            szTip = string.format("<color=#FFE26E>装备分数  %d</c>", nBaseScore)
            nStrengthScore = item.CalculateStrengthScore(tbPowerUpInfo.nStrengthLevel or 0, item.nLevel)
            nStoneScore = EquipCodeData.GetCustomEquipStoneScore(tbPowerUpInfo)
            if nStrengthScore > 0 or nStoneScore > 0 then
                szTip = szTip .. string.format("<color=#70FFBB>（+%d+%d）</c>", nStrengthScore, nStoneScore)
            end
        end
    else
        local nBaseScore = item.nBaseScore
        if nBaseScore > 0 then
            szTip = string.format("<color=#FFE26E>装备分数  %d</c>", nBaseScore)
        end
    end
    return szTip
end

------------------唯一性-------------------
local function GetItemExistAmountTip(iteminfo)
    local szText = ""
    if iteminfo.nMaxExistAmount ~= 0 then
        if iteminfo.nMaxExistAmount == 1 then
            szText = "<color=#D7F6FF>" .. g_tStrings.STR_ITEM_H_UNIQUE .. "</c>"
        else
            -- szText = FormatString(g_tStrings.STR_ITEM_H_UNIQUE_MULTI, iteminfo.nMaxExistAmount)
        end
    end
    return szText
end

------------------品质等级 装备分数-------------------
local function GetQualityInfoTip(item, bItem, nPlayerID, nEquipInv, tbPowerUpInfo)
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return ""
    end

    local szTip = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)

    if bItem then
        local tInfo = EquipData.GetStrength(item, bItem, { dwPlayerID = nPlayerID, dwX = nEquipInv })
        local nStrengthQuality = ItemData.GetStrengthQualityLevel(item.nLevel, tInfo.nTrueLevel)
        if nStrengthQuality and nStrengthQuality > 0 then
            szTip = szTip .. string.format("<color=#70FFBB>（+%d）</c>", nStrengthQuality)
        end
    elseif tbPowerUpInfo and tbPowerUpInfo.nStrengthLevel then
        local nStrengthQuality = ItemData.GetStrengthQualityLevel(item.nLevel, tbPowerUpInfo.nStrengthLevel)
        szTip = szTip .. string.format("<color=#70FFBB>（+%d）</c>", nStrengthQuality)
    end
    ------------------装备分数-------------------
    if not UIItemTip:NotShowEquipStrength(item.nSub) then
        szTip = szTip .. "\n"
        szTip = szTip .. GetEquipScoreTip(item, bItem, nPlayerID, nEquipInv, tbPowerUpInfo)
    end
    return szTip
end

----需求属性--------------------------
local function GetRequireTip(item, bItem, tbGetIDs, szNormalColor, szNotSatisfyColor)
    local szTip = ""
    local szText = ""
    local nValue

    szNormalColor = szNormalColor or "#D7F6FF"
    szNotSatisfyColor = szNotSatisfyColor or "#FF4040"

    local requireAttrib = item.GetRequireAttrib()
    local player = PlayerData.GetClientPlayer()
    for k, v in pairs(requireAttrib or {}) do
        if bItem then
            nValue = v.nValue1
        else
            nValue = v.nValue
        end

        local bSatisfy = player.SatisfyRequire(v.nID, nValue)
        local szColor = szNormalColor
        if not bSatisfy then
            szColor = szNotSatisfyColor
        end

        if v.nID == 1 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要体质%d</c>", szColor, nValue)
        elseif v.nID == 2 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要力量%d</c>", szColor, nValue)
        elseif v.nID == 3 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要根骨%d</c>", szColor, nValue)
        elseif v.nID == 4 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要身法%d</c>", szColor, nValue)
        elseif v.nID == 5 and tbGetIDs[v.nID] then
            if player.nLevel < nValue or nValue >= 100 then
                szText = string.format("<color=%s>需要等级  %d</c>", szColor, nValue)
            end
        elseif v.nID == 6 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要门派%s</c>", szColor, Table_GetForceName(nValue))
        elseif v.nID == 7 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要性别%s</c>", szColor, g_tStrings.tGender[nValue])
        elseif v.nID == 8 and tbGetIDs[v.nID] then
            szText = string.format("<color=%s>需要体型%d</c>", szColor, nValue)
        end

        if szText ~= "" then
            if szTip == "" then
                szTip = szText
            else
                szTip = szTip .. "\n" .. szText
            end
            szText = ""
        end
    end
    return szTip
end

----耐久度-------------------------------------
local function GetDurabilityTip(item, bItem)
    local szTip = ""
    if ItemData.IsPendantItem(item) or
            item.nSub == EQUIPMENT_SUB.AMULET or
            item.nSub == EQUIPMENT_SUB.RING or
            item.nSub == EQUIPMENT_SUB.PENDANT or
            item.nSub == EQUIPMENT_SUB.BULLET or
            item.nSub == EQUIPMENT_SUB.HORSE or
            item.nSub == EQUIPMENT_SUB.MINI_AVATAR or
            item.nSub == EQUIPMENT_SUB.PET or
            item.nSub == EQUIPMENT_SUB.HORSE_EQUIP or
            item.nSub == EQUIPMENT_SUB.PENDENT_PET
    then
        --饰品(挂件),饰品没有耐久度
    elseif item.nSub == EQUIPMENT_SUB.PACKAGE then
        --包裹,包裹的耐久度用作格子大小

        local value = 0
        if bItem then
            value = item.nCurrentDurability
        else
            value = item.nMaxDurability
        end
        szTip = string.format("<color=#D7F6FF>背包大小</c> <color=#D7F6FF>  %d</c>", value)

    elseif item.nSub == EQUIPMENT_SUB.ARROW then
        --如果是远程武器弹药，则耐久度为数量
        if bItem then
            szTip = string.format("<color=#D7F6FF>数量</c> <color=#D7F6FF>  %d</c>", item.nStackNum)
        else
            szTip = string.format("<color=#D7F6FF>数量</c> <color=#D7F6FF>  %d</c>", item.nMaxDurability)
        end
    end
    return szTip
end

function UIItemTip:UpdateEquipBaseInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT and item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT then
        if self.scriptEquipBaseInfo then
            self.scriptEquipBaseInfo:OnEnter(tbInfo)
        end
        return
    end

    if item.nSub == EQUIPMENT_SUB.HORSE_EQUIP or
            item.nSub == EQUIPMENT_SUB.PET then
        --马具虽然属于装备，但是不显示装备分数精炼
        local szLevelTip = ""
        if item.nLevel > 0 then
            szLevelTip = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)
        end
        local szNeedLevelTip = GetRequireTip(item, self.bItem, { [5] = true })
        if szNeedLevelTip ~= "" and szLevelTip ~= "" then
            szNeedLevelTip = "\n" .. szNeedLevelTip
            tbInfo[1] = szLevelTip..szNeedLevelTip
        elseif szLevelTip ~= "" then
            tbInfo[1] = szLevelTip
        elseif szNeedLevelTip ~= "" then
            tbInfo[1] = szNeedLevelTip
        end
    elseif item.nGenre == ITEM_GENRE.NPC_EQUIPMENT then
        tbInfo[1] = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)
    elseif item.nSub == EQUIPMENT_SUB.MINI_AVATAR then
        --小头像只有品质等级
        tbInfo[1] = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)
    elseif self:IsExtendType(item.nSub) then
        local szLevelTip = ""
        if item.nLevel > 0 then
            szLevelTip = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)
        end
        local szNeedLevelTip = GetRequireTip(item, self.bItem, { [5] = true })
        if szNeedLevelTip ~= "" and szLevelTip ~= "" then
            szNeedLevelTip = "\n" .. szNeedLevelTip
            tbInfo[1] = szLevelTip..szNeedLevelTip
        elseif szLevelTip ~= "" then
            tbInfo[1] = szLevelTip
        elseif szNeedLevelTip ~= "" then
            tbInfo[1] = szNeedLevelTip
        end
    elseif item.nSub == EQUIPMENT_SUB.HORSE then
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        local szQualityInfoTip = GetQualityInfoTip(item, self.bItem, self.nPlayerID, nEquipInv, self.tbPowerUpInfo)
        local szRequireTip = GetRequireTip(item, self.bItem, { [5] = true })
        if szQualityInfoTip ~= "" and szRequireTip ~= "" then
            szRequireTip = "\n" .. szRequireTip
            tbInfo[1] = szQualityInfoTip..szRequireTip
        elseif szQualityInfoTip ~= "" then
            tbInfo[1] = szQualityInfoTip
        elseif szRequireTip ~= "" then
            tbInfo[1] = szRequireTip
        end
        tbInfo[3] = GetDurabilityTip(item, self.bItem)
    elseif item.nSub == EQUIPMENT_SUB.ARROW then
        --远程弹药
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        tbInfo[1] = GetQualityInfoTip(item, self.bItem, self.nPlayerID, nEquipInv, self.tbPowerUpInfo)
        tbInfo[2] = GetRequireTip(item, self.bItem, { [5] = true })
        if tbInfo[2] == "" then
            tbInfo[1] = tbInfo[1] .. "\n" .. GetDurabilityTip(item, self.bItem)
        else
            tbInfo[2] = tbInfo[2] .. "\n" .. GetDurabilityTip(item, self.bItem)
        end
    elseif item.nSub == EQUIPMENT_SUB.PACKAGE then
        --包裹
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        tbInfo[1] = GetQualityInfoTip(item, self.bItem, self.nPlayerID, nEquipInv, self.tbPowerUpInfo)
        tbInfo[2] = GetRequireTip(item, self.bItem, { [5] = true })
        if tbInfo[2] == "" then
            tbInfo[1] = tbInfo[1] .. "\n" .. GetDurabilityTip(item, self.bItem)
        else
            tbInfo[2] = tbInfo[2] .. "\n" .. GetDurabilityTip(item, self.bItem)
        end
    else
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        tbInfo[1] = GetQualityInfoTip(item, self.bItem, self.nPlayerID, nEquipInv, self.tbPowerUpInfo)
        tbInfo[2] = GetRequireTip(item, self.bItem, { [5] = true })
        tbInfo[3] = GetDurabilityTip(item, self.bItem)
        -- 判断哪些分类不显示精炼
        if not self:NotShowEquipStrength(item.nSub) and self.bItem then
            local player = PlayerData.GetClientPlayer()
            if self.nPlayerID then
                player = GetPlayer(self.nPlayerID)
            end
            local tbEquipStrengthInfo = EquipData.GetStrength(item, self.bItem, { dwPlayerID = player.dwID, dwX = nEquipInv })
            if tbEquipStrengthInfo then
                if tbEquipStrengthInfo.nBoxMaxLevel and tbEquipStrengthInfo.nEquipMaxLevel and tbEquipStrengthInfo.nEquipMaxLevel > 0 and item.nStrengthLevel and item.nStrengthLevel > 0 then
                    tbInfo[3] = tbInfo[3] .. "\n" .. string.format("<color=#D7F6FF>装备精炼</c><color=#D7F6FF>  %d/%d</c>", tbEquipStrengthInfo.nEquipLevel, tbEquipStrengthInfo.nEquipMaxLevel)
                end
            end
        end

    end

    if not self.scriptEquipBaseInfo then
        self.scriptEquipBaseInfo = self:AddPrefab("scriptEquipBaseInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipBaseInfo"] = self.scriptEquipBaseInfo
    end
    self.scriptEquipBaseInfo:OnEnter(tbInfo)
    self.scriptEquipBaseInfo.bTest = true
end

function UIItemTip:UpdateEquipBoxTipsInfo(item)
    if not item then
        return
    end

    local tbInfo = {}
    if not self.bItem or self.nBox ~= INVENTORY_INDEX.EQUIP or item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) or self.bHideEquipBoxTipsInfo then
        if self.scriptEquipBoxTipsInfo then
            self.scriptEquipBoxTipsInfo:OnEnter(tbInfo)
        end
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player or (self.nPlayerID and self.nPlayerID ~= player.dwID) then
        if self.scriptEquipBoxTipsInfo then
            self.scriptEquipBoxTipsInfo:OnEnter(tbInfo)
        end
        return
    end

    local szTips = ""
    local tbEquipStrengthInfo = EquipData.GetEquipStrengthInfo(player, item, true, self.nIndex)
    if tbEquipStrengthInfo then

        if tbEquipStrengthInfo.bBoxQualityNotEnough then
            szTips = "<color=#ff7676>精炼等级对当前装备不生效</c>"
        end

        if EquipData.CheckIsEquipSlotQualityLower(item, self.nIndex) then
            if not string.is_nil(szTips) then
                szTips = szTips .. "\n"
            end
            szTips = szTips .. "<color=#ff7676>熔嵌的五行石对当前装备不生效</c>"
        end

        if EquipData.CheckIsWeaponNotActiveSlot(player, item, self.nIndex) then
            if not string.is_nil(szTips) then
                szTips = szTips .. "\n"
            end
            szTips = szTips .. "<color=#ff7676>当前武器未激活熔嵌的五彩石</c>"
        end

    end


    tbInfo[1] = szTips

    if not self.scriptEquipBoxTipsInfo then
        self.scriptEquipBoxTipsInfo = self:AddPrefab("scriptEquipBoxTipsInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipBoxTipsInfo"] = self.scriptEquipBoxTipsInfo
    end
    self.scriptEquipBoxTipsInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipBaseAttribInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        if self.scriptEquipBaseAttribInfo then
            self.scriptEquipBaseAttribInfo:OnEnter(tbInfo)
        end
        return
    end

    local szTip = ""
    local baseAttib = item.GetBaseAttrib()
    local tbAttribStr = {}
    local nWeaponDamageMin, nWeaponDamageMax, fWeaponSpeed = 0, 0, 0
    for k, v in pairs(baseAttib) do
        szText = ""
        if v.nID == ATTRIBUTE_TYPE.MELEE_WEAPON_ATTACK_SPEED_BASE or v.nID == ATTRIBUTE_TYPE.RANGE_WEAPON_ATTACK_SPEED_BASE then
            if self.bItem then
                --如果是武器速度,则转换参数
                v.nValue1, v.nValue2 = (v.nValue1 / GLOBAL.GAME_FPS), (v.nValue2 / GLOBAL.GAME_FPS)
                fWeaponSpeed = v.nValue1
            else
                v.nMin, v.nMax = (v.nMin / GLOBAL.GAME_FPS), (v.nMax / GLOBAL.GAME_FPS)
                fWeaponSpeed = v.nMin
            end
            break
        elseif v.nID == ATTRIBUTE_TYPE.MELEE_WEAPON_DAMAGE_BASE or v.nID == ATTRIBUTE_TYPE.RANGE_WEAPON_DAMAGE_BASE then
            if self.bItem then
                nWeaponDamageMin, nWeaponDamageMax = v.nValue1, v.nValue2
            else
                nWeaponDamageMin, nWeaponDamageMax = v.nMin, (v.nMin + v.nMin1)
            end
        end

        v.nMin1 = v.nMin1 or 0
        v.nMax1 = v.nMax1 or 0
        if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
            local value = v.nMin
            if self.bItem then
                value = v.nValue1
            end

            local skillEvent = g_tTable.SkillEvent:Search(value)
            if skillEvent then
                if self.bItem then
                    szText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
                else
                    szText = FormatString(skillEvent.szDesc, v.nMin, v.nMax, v.nMin + v.nMin1, v.nMax + v.nMax1)
                end
            else
                szText = "unknown skill event id:" .. value
            end
        elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
            if self.bItem then
                szText = GetEquipRecipeDesc(v.nValue1, v.nValue2)
            else
                szText = GetEquipRecipeDesc(v.nMin, v.nMin1)
            end
        else
            if self.bItem then
                szText = FormatString(Table_GetBaseAttributeInfo(v.nID, true), v.nValue1, v.nValue2)
            else
                szText = FormatString(Table_GetBaseAttributeInfo(v.nID, false), v.nMin, v.nMax, v.nMin + v.nMin1, v.nMax + v.nMax1)
            end
        end

        if szText ~= "" then
            table.insert(tbAttribStr, string.pure_text(UIHelper.GBKToUTF8(szText)))
        end
    end

    -- 武器速度
    if fWeaponSpeed and
            (item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
                    item.nSub == EQUIPMENT_SUB.RANGE_WEAPON) then
        tbInfo[4] = string.format("<color=#D7F6FF>速度%.1f</c>", fWeaponSpeed)
    end

    -------------武器DPS-----------------
    if item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or
            item.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
        local szDPS = ""
        if nWeaponDamageMin and nWeaponDamageMax and fWeaponSpeed then
            local fDps = (nWeaponDamageMin + nWeaponDamageMax) / 2 / fWeaponSpeed
            if fDps > 0 then
               szDPS = FixFloat(fDps, 1)
            end
        end

    if szDPS ~= "" then
           table.insert(tbAttribStr, string.format("每秒伤害%.1f", szDPS))
        end
    end

    for _, szAttrib in ipairs(tbAttribStr) do
        tbInfo[1] = tbInfo[1] or ""
        if tbInfo[1] == "" then
            tbInfo[1] = string.format("<color=#D7F6FF>%s</c>", szAttrib)
        else
            tbInfo[1] = tbInfo[1] .. string.format("\n<color=#D7F6FF>%s</c>", szAttrib)
        end
    end
    local tbMagicInfos = {}
    if not self.bItem then
        tbMagicInfos = EquipData.GetItemInfoMagicAttriTip(item, self.tbPowerUpInfo)
    else
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        tbMagicInfos = EquipData.GetMagicAttriTip(item, true, nEquipInv)
    end

    for _, tbMagicInfo in ipairs(tbMagicInfos) do
        if tbMagicInfo.bIsNormal then
            local szAttrib = UIHelper.GBKToUTF8(tbMagicInfo.szText)
            --print(tbMagicInfo.szText, szAttrib)
            if szAttrib then
                tbInfo[1] = tbInfo[1] or ""
                if tbInfo[1] == "" then
                    tbInfo[1] = string.format("<color=#D7F6FF>%s</c>", szAttrib)
                else
                    tbInfo[1] = tbInfo[1] .. string.format("\n<color=#D7F6FF>%s</c>", szAttrib)
                end
            end
        end
    end

    if not self.scriptEquipBaseAttribInfo then
        self.scriptEquipBaseAttribInfo = self:AddPrefab("scriptEquipBaseAttribInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipBaseAttribInfo"] = self.scriptEquipBaseAttribInfo
    end
    self.scriptEquipBaseAttribInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipBreakInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipBreakInfo then
            self.scriptEquipBreakInfo:OnEnter(tbInfo)
        end
        return
    end

    -- 这里塞入需求门派等相关信息
    local szNeedLevelTip = GetRequireTip(item, self.bItem, {
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [6] = true,
        [7] = true,
        [8] = true,
    })
    if szNeedLevelTip and szNeedLevelTip ~= "" then
        if tbInfo[1] then
            tbInfo[1] = tbInfo[1] .. "\n" .. szNeedLevelTip
        else
            tbInfo[1] = szNeedLevelTip
        end
    end

    if not self.scriptEquipBreakInfo then
        self.scriptEquipBreakInfo = self:AddPrefab("scriptEquipBreakInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipBreakInfo"] = self.scriptEquipBreakInfo
    end
    self.scriptEquipBreakInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipMagicAttribInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if (item.nGenre ~= ITEM_GENRE.EQUIPMENT and item.nGenre ~= ITEM_GENRE.NPC_EQUIPMENT) or ItemData.IsPendantItem(item) then
        if self.scriptEquipMagicAttribInfo then
            self.scriptEquipMagicAttribInfo:OnEnter(tbInfo)
        end
        return
    end
    local tbMagicInfos = {}
    if not self.bItem then
        tbMagicInfos = EquipData.GetItemInfoMagicAttriTip(item, self.tbPowerUpInfo)
    else
        local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
        if self.nBox == INVENTORY_INDEX.EQUIP then
            nEquipInv = self.nIndex
        end
        tbMagicInfos = EquipData.GetMagicAttriTip(item, true, nEquipInv)
    end
    for _, tbMagicInfo in ipairs(tbMagicInfos) do
        if not tbMagicInfo.bIsNormal and not tbMagicInfo.bIsEquipmentRecipe and not tbMagicInfo.bIsSkillEventHandler then
            local szAttrib = UIHelper.GBKToUTF8(tbMagicInfo.szText)
            if not string.is_nil(szAttrib) then
                if not tbInfo[1] then
                    tbInfo[1] = string.format("<color=#95FF95>%s</c>", szAttrib)
                else
                    tbInfo[1] = tbInfo[1] .. string.format("\n<color=#95FF95>%s</c>", szAttrib)
                end
            end
        end
    end
    if not self.scriptEquipMagicAttribInfo then
        self.scriptEquipMagicAttribInfo = self:AddPrefab("scriptEquipMagicAttribInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipMagicAttribInfo"] = self.scriptEquipMagicAttribInfo
    end
    self.scriptEquipMagicAttribInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipEquipmentRecipeAttribInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipEquipmentRecipeAttribInfo then
            self.scriptEquipEquipmentRecipeAttribInfo:OnEnter(tbInfo)
        end
        return
    end

    local nEquipInv = EquipData.GetEquipInventory(item.nSub, item.nDetail)
    if self.nBox == INVENTORY_INDEX.EQUIP then
        nEquipInv = self.nIndex
    end
    local tbMagicInfos = EquipData.GetMagicAttriTip(item, self.bItem, nEquipInv)

    if not self.bItem then
        tbMagicInfos = EquipData.GetItemInfoMagicAttriTip(item, self.tbPowerUpInfo)
    end

    local bShowSign = false
    local tbDXInfo = {}
    local tbVKInfo = {}
    for _, tbMagicInfo in ipairs(tbMagicInfos) do
        if not tbMagicInfo.bIsNormal and (tbMagicInfo.bIsEquipmentRecipe or tbMagicInfo.bIsSkillEventHandler) then
            if tbMagicInfo.bIsMobile then
                table.insert(tbVKInfo, tbMagicInfo)
            else
                table.insert(tbDXInfo, tbMagicInfo)
            end
            if tbMagicInfo.bShowSign then
                bShowSign = tbMagicInfo.bShowSign
            end
        end
    end

    if bShowSign and #tbVKInfo > 0 and #tbDXInfo > 0 then
		tbInfo[1] = string.format("<color=#FFE26E>%s%s</c>", EquipSuitPlatformType2Desc[2], "特殊属性效果")
        for _, tbMagicInfo in ipairs(tbVKInfo) do
            local szAttrib = UIHelper.GBKToUTF8(tbMagicInfo.szText)
            tbInfo[1] = tbInfo[1] .. string.format("\n<color=#FFE26E>%s</c>", szAttrib)
        end

        tbInfo[1] = tbInfo[1] .. string.format("\n<color=#FFE26E>%s%s</c>", EquipSuitPlatformType2Desc[1], "特殊属性效果")
        for _, tbMagicInfo in ipairs(tbDXInfo) do
            local szAttrib = UIHelper.GBKToUTF8(tbMagicInfo.szText)
            tbInfo[1] = tbInfo[1] .. string.format("\n<color=#FFE26E>%s</c>", szAttrib)
        end
    else
        for _, tbMagicInfo in ipairs(tbMagicInfos) do
            if not tbMagicInfo.bIsNormal and (tbMagicInfo.bIsEquipmentRecipe or tbMagicInfo.bIsSkillEventHandler) then
                local szAttrib = UIHelper.GBKToUTF8(tbMagicInfo.szText)
                if not tbInfo[1] then
                    tbInfo[1] = string.format("<color=#FFE26E>%s</c>", szAttrib)
                else
                    tbInfo[1] = tbInfo[1] .. string.format("\n<color=#FFE26E>%s</c>", szAttrib)
                end
            end
        end
    end

    if not self.scriptEquipEquipmentRecipeAttribInfo then
        self.scriptEquipEquipmentRecipeAttribInfo = self:AddPrefab("scriptEquipEquipmentRecipeAttribInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipEquipmentRecipeAttribInfo"] = self.scriptEquipEquipmentRecipeAttribInfo
    end
    self.scriptEquipEquipmentRecipeAttribInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipMountAttribInfo(item)
    if not item then
        return
    end

    if not self.scriptEquipMountAttribInfo then
        self.scriptEquipMountAttribInfo = self:AddPrefab("scriptEquipMountAttribInfo", PREFAB_ID.WidgetItemTipContent3)
        self.tbScript["scriptEquipMountAttribInfo"] = self.scriptEquipMountAttribInfo
    end

    local tbMountAttribInfos = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipMountAttribInfo then
            self.scriptEquipMountAttribInfo:OnEnter(tbMountAttribInfos)
        end
        return
    end

    tbMountAttribInfos = EquipData.GetEquipSlotTip(item, self.bItem, { bCmp = false, bLink = false, dwPlayerID = self.nPlayerID, tbPowerUpInfo = self.tbPowerUpInfo })

    self.scriptEquipMountAttribInfo:OnEnter(tbMountAttribInfos)
end

function UIItemTip:UpdateEquipColorMountAttribInfo(item)
    if not item then
        return
    end

    if not self.scriptEquipColorMountAttribInfo then
        self.scriptEquipColorMountAttribInfo = self:AddPrefab("scriptEquipColorMountAttribInfo", PREFAB_ID.WidgetItemTipContent3)
        self.tbScript["scriptEquipColorMountAttribInfo"] = self.scriptEquipColorMountAttribInfo
    end

    local tbMountAttribInfos = {}
    local bShowInfo = item.nGenre == ITEM_GENRE.EQUIPMENT and not ItemData.IsPendantItem(item)
    if self.bItem then
        bShowInfo = bShowInfo and item.CanMountColorDiamond()
    else
        bShowInfo = bShowInfo and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON
    end

    if not bShowInfo then
        if self.scriptEquipColorMountAttribInfo then
            self.scriptEquipColorMountAttribInfo:OnEnter(tbMountAttribInfos)
        end
        return
    end

    local nPlayerID = self.nPlayerID or PlayerData.GetPlayerID()
    tbMountAttribInfos = EquipData.GetColorDiamondTip(nPlayerID, item, self.bItem, self.nBox, self.nIndex, self.tbPowerUpInfo)
    self.scriptEquipColorMountAttribInfo:OnEnter(tbMountAttribInfos)
end

function UIItemTip:UpdateEquipEnchantAttribInfo(item)
    if not item or (not self.bItem and not self.tbPowerUpInfo) then
        return
    end

    local tbAttribInfos = {}
    local nNeedUpdate = false
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipEnchantAttribInfo then
            self.scriptEquipEnchantAttribInfo:OnEnter(tbAttribInfos)
        end
        return
    end

    if self.tbPowerUpInfo then
        self.tbPowerUpInfo.nTabType = self.nTabType
        self.tbPowerUpInfo.nTabID = self.nTabID
    end

    tbAttribInfos, nNeedUpdate = EquipData.GetEnchantAttribTip(item, nil, self.tbPowerUpInfo)
    if not self.scriptEquipEnchantAttribInfo then
        self.scriptEquipEnchantAttribInfo = self:AddPrefab("scriptEquipEnchantAttribInfo", PREFAB_ID.WidgetItemTipContent3)
        self.tbScript["scriptEquipEnchantAttribInfo"] = self.scriptEquipEnchantAttribInfo
    end
    self.scriptEquipEnchantAttribInfo:OnEnter(tbAttribInfos)

    if nNeedUpdate then
        self.nUpdateEquipEnchantAttribInfoTimerID = Timer.Add(self, 0.5, function()
            self:UpdateEquipEnchantAttribInfo(item)
        end)
    end
end

function UIItemTip:UpdateEquipSuitAttribInfo(item)
    if not item then
        return
    end

    local tbInfo = {}
    local tbAttribInfos = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipSuitAttribInfo then
            self.scriptEquipSuitAttribInfo:OnEnter(tbAttribInfos)
        end
        return
    end

    tbInfo[1] = "<color=#FFE26E>"
    local dwSetID
    if self.bItem then
        if item.dwSetID and item.dwSetID > 0 then
            dwSetID = item.dwSetID
        end
    else
        if item.nSetID and item.nSetID > 0 then
            dwSetID = item.nSetID
        end
    end
    if dwSetID then
        local player = PlayerData.GetClientPlayer()
        if self.nPlayerID and GetPlayer(self.nPlayerID) then
            player = GetPlayer(self.nPlayerID)
        end
        tbAttribInfos = EquipData.GetSetAttriTip(dwSetID, player.dwID, player.dwBitOPSchoolID, not self.bItem)
        for i, value in ipairs(tbAttribInfos) do
            if value.bActived == false or value.bEquiped == false then
                tbInfo[1] = tbInfo[1] .. "<color=#AFC1D4>" .. value.szTip .. "</c>"
            else
                tbInfo[1] = tbInfo[1] .. value.szTip
            end

            if i ~= #tbAttribInfos then
                tbInfo[1] = tbInfo[1] .. "\n"
            end
        end

        for _, szFrameName in ipairs(EquipSuitPlatformTypeIcon) do
            UIHelper.PreloadSpriteFrame(szFrameName)
        end
    end

    tbInfo[1] = tbInfo[1] .. "</c>"

    if not self.scriptEquipSuitAttribInfo then
        self.scriptEquipSuitAttribInfo = self:AddPrefab("scriptEquipSuitAttribInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipSuitAttribInfo"] = self.scriptEquipSuitAttribInfo
    end

    if table_is_empty(tbAttribInfos) then
        tbInfo[1] = nil
    end

    self.scriptEquipSuitAttribInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateBookBaseInfo(item)
    local tbInfo = {}
    if not item or item.nGenre ~= ITEM_GENRE.BOOK then
        if self.scriptBookBaseInfo then
            self.scriptBookBaseInfo:OnEnter(tbInfo)
        end
        return
    end
    local player = GetClientPlayer()
    local nBookID, nSegmentID = GlobelRecipeID2BookID(self.bItem and item.nBookID or self.nBookID)
    local recipe = GetRecipe(8, nBookID, nSegmentID)
    local szBookName = Table_GetSegmentName(nBookID, nSegmentID)
    -- local nSort = Table_GetBookSort(nBookID, nSegmentID)
    -- local szSortName = g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[nSort]
    local szReadMemory = "<color=#FFFFFF>未阅读</c>"
    if player.IsBookMemorized(nBookID, nSegmentID) then
        szReadMemory = "<color=#FF7676>已阅读</c>"
    end

    if szBookName and szBookName ~= "" then
        UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(szBookName))
        UIHelper.ScrollViewDoLayout(self.ScrollviewName)
        UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    end

    -- UIHelper.SetString(self.LabelEquipType2, szSortName)
    tbInfo[1] = ""

    if recipe then
        local szBookDesc = UIHelper.GBKToUTF8(Table_GetBookDesc(nBookID, nSegmentID))
        local szLevel = string.format("<color=#D7F6FF>适合阅读%d级</c>", recipe.dwRequireProfessionLevel)
        local szVigorTip = ""
        if recipe.nVigor > 0 then
            if player.IsVigorAndStaminaEnough(recipe.nVigor) then
                szVigorTip = string.format("\n<color=#FF7676>消耗精力%d点</c>", recipe.nVigor)
            else
                szVigorTip = string.format("\n<color=#D7F6FF>消耗精力%d点</c>", recipe.nVigor)
            end
        end
        tbInfo[1] = string.format("%s%s\n%s\n%s", szLevel, szVigorTip, szBookDesc, szReadMemory)
    end

    if not self.scriptBookBaseInfo then
        self.scriptBookBaseInfo = self:AddPrefab("scriptBookBaseInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptBookBaseInfo"] = self.scriptBookBaseInfo
    end
    self.scriptBookBaseInfo:OnEnter(tbInfo)
end

local function GetGoodsRewards_UI(eGoodsType, dwID, bDis, nDis, nRewards)
    if not nRewards then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        if hPlayer.dwForceID == FORCE_TYPE.CANG_JIAN then
            nRewards = GetFinalGoodsRewardsForCangjian(eGoodsType, dwID)
        else
            nRewards = GetFinalGoodsRewards(eGoodsType, dwID)
        end
    end
    if not nRewards then
        return 0
    end
    if bDis then
        nRewards = math.floor(nRewards * nDis / 100 + 0.5)
    end
    return nRewards
end

local function GetGoodsRewardsTip(dwGoodsType, dwGoodsID, tPrice)
    local bDis = CoinShop_IsDis(tPrice, dwGoodsType, dwGoodsID)
    local nDis = tPrice.nDiscount or 100
    local nRewards = GetGoodsRewards_UI(dwGoodsType, dwGoodsID, bDis, nDis)
    if nRewards == 0 then
        return ""
    else
        local szTip = GetFormatText(FormatString(g_tStrings.STR_ITEM_BUY_GET_REWARDS, nRewards), 18) .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JiFen' width='35' height='35' />"
        return szTip
    end
end

local function IsShowFurnitureSourceTip(tItemAddInfo)
	if not tItemAddInfo then
		return false
	end
	if tItemAddInfo.szFurnitureItemID == "" then
		return true
	end

	local tFurnitureItemID = SplitString(tItemAddInfo.szFurnitureItemID, ";")
	for _, szFurnitureItemID in ipairs(tFurnitureItemID) do
		local tSource = ItemData.GetItemSourceList(ITEM_TABLE_TYPE.HOMELAND, tonumber(szFurnitureItemID))
		if tSource then
			return false
		end
	end

	return true
end

function UIItemTip:UpdateFurnitureInfoWithFurnitureID(nFurnitureType, dwFurnitureID)
    if not nFurnitureType or not dwFurnitureID then
        LOG.ERROR("[UIItemTip.:UpdateFurnitureInfoWithFurnitureID] error get dwFurnitureID failed!")
        return
    end

    self.tbScript = self.tbScript or {}
    self:RemoveAllChildren()

    if self.dwItemID and self.dwItemID > 0 then
        local item = GetItem(self.dwItemID)
        self:UpdateShopLimitInfo(item)
        self:UpdateItemRequireInfo(item)
    end

    local tFurnitureConfig = FurnitureData.GetFurnitureConfig(nFurnitureType, dwFurnitureID)
    local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local dwUIFurnitureID = GetHomelandMgr().MakeFurnitureUIID(nFurnitureType, dwFurnitureID)
    local tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)

    -- 品质、需求宅园等级
    local tbInfo = {}
    if not self.scriptFurnitureNeedLevel then
        self.scriptFurnitureNeedLevel = self:AddPrefab("scriptFurnitureNeedLevel", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptFurnitureNeedLevel"] = self.scriptFurnitureNeedLevel
    end
    tbInfo[1] = string.format("<color=#FFE26E>品质  %d</c>", tFurnitureConfig.nQualityLevel)
    local nRequiredLevel = tFurnitureConfig.nLevelLimit
    if nRequiredLevel and nRequiredLevel > 0 then
        if nLandLevel and nLandLevel < nRequiredLevel then
            tbInfo[1] = tbInfo[1] .. "\n" .. string.format("<color=#FF4040>需求宅邸等级  %d</c>", nRequiredLevel)
        else
            tbInfo[1] = tbInfo[1] .. "\n" .. string.format("<color=#D7F6FF>需求宅邸等级  %d</c>", nRequiredLevel)
        end
    end
    self.scriptFurnitureNeedLevel:OnEnter(tbInfo)

    if self.bItem then
        if not self.scriptFurnitureItemUseTip then
            self.scriptFurnitureItemUseTip = self:AddPrefab("scriptFurnitureItemUseTip", PREFAB_ID.WidgetItemTipContent1)
            self.tbScript["scriptFurnitureItemUseTip"] = self.scriptFurnitureItemUseTip
        end
        tbInfo[1] = string.format("<color=#95FF95>%s</c>", g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE1)
        self.scriptFurnitureItemUseTip:OnEnter(tbInfo)
    end

    -- 套装
    if not self.scriptFurnitureSuit then
        self.scriptFurnitureSuit = self:AddPrefab("scriptFurnitureSuit", PREFAB_ID.WidgetItemTipContent9)
        self.tbScript["scriptFurnitureSuit"] = self.scriptFurnitureSuit
    end
    local dwSetID = tFurnitureConfig.nSetID
    local dwSetIndex = tFurnitureConfig.nSetIndex
    if dwSetID and dwSetID > 0 then
        local tSetInfo = Table_GetFurnitureSetInfoByID(dwSetID)
        if tSetInfo then
            local szName = string.format("套装  %s", UIHelper.GBKToUTF8(tSetInfo.szName))
            self.scriptFurnitureSuit:OnEnter(szName, tSetInfo.nStars)
        else
            self.scriptFurnitureSuit:OnEnter()
        end
    else
        self.scriptFurnitureSuit:OnEnter()
    end

    -- 属性
    tbInfo = {}
    if not self.scriptFurnitureAttrib then
        self.scriptFurnitureAttrib = self:AddPrefab("scriptFurnitureAttrib", PREFAB_ID.WidgetItemTipContent8)
        self.tbScript["scriptFurnitureAttrib"] = self.scriptFurnitureAttrib
    end
    local nValue = tFurnitureConfig.uRecord
    if nValue and nValue > 0 then
        table.insert(tbInfo, {
            szIcon = FurnitureItemTips8Icon[5],
            szDesc = FormatString(g_tStrings.STR_FURNITURE_TIP_SCORE1, nValue),
        })
    end
    self.scriptFurnitureAttrib:OnEnter(tbInfo)

    if tItemAddInfo and IsShowFurnitureSourceTip(tItemAddInfo) then
        -- 物品来源
        tbInfo = {}
        if not self.scriptFurnitureGetWay then
            self.scriptFurnitureGetWay = self:AddPrefab("scriptFurnitureGetWay", PREFAB_ID.WidgetItemTipContent1)
            self.tbScript["scriptFurnitureGetWay"] = self.scriptFurnitureGetWay
        end
        tbInfo[1] = string.format("<color=#D7F6FF>物品来源  %s</c>", UIHelper.GBKToUTF8(tItemAddInfo.szSource))
        self.scriptFurnitureGetWay:OnEnter(tbInfo)
    end

    -- 物品描述
    tbInfo = {}
    if not self.scriptFurnitureDesc then
        self.scriptFurnitureDesc = self:AddPrefab("scriptFurnitureDesc", PREFAB_ID.WidgetItemTipContent2)
        self.scriptFurnitureDesc._rootNode:setName("scriptFurnitureDesc")
        self.tbScript["scriptFurnitureDesc"] = self.scriptFurnitureDesc
    end

    if tItemAddInfo then
        local szDesc = UIHelper.GBKToUTF8(tItemAddInfo.szTip)
        if szDesc and szDesc ~= "" then
            tbInfo[1] = string.format("<color=#FFE26E>%s</c>", szDesc)
        end

        tbInfo[3] = UIHelper.FixDXUIImagePath(tItemAddInfo.szPath)
    end
    self.scriptFurnitureDesc:OnEnter(tbInfo)

    ------------------价格------------------
    tbInfo = {}
    if not self.scriptFurnitureCost then
        self.scriptFurnitureCost = self:AddPrefab("scriptFurnitureCost", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptFurnitureCost"] = self.scriptFurnitureCost
    end

    local szTip = ""
    local tCoinInfo = nil
    if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
        tCoinInfo = FurnitureBuy.GetFurnitureInfo(dwFurnitureID)
        local nArchitecture = tFurnitureConfig.nArchitecture
	    local nReBuyCost = tFurnitureConfig.nReBuyCost
        local nDisCoincount, bInCoinDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(dwFurnitureID)
        local nDisArchcount, bInArchDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(dwFurnitureID)
        if tCoinInfo then
            szTip = string.format("价格：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='35' height='35' />", tCoinInfo.nFinalCoin)
            if bInCoinDiscount then
                local szEndTime = ""
                if tCoinInfo.tPrice.nDisEndTime ~= -1 then
                    szEndTime = string.format("，优惠将在<color=#FFE26E>%s</c>结束", CoinShop_GetTimeText(tCoinInfo.tPrice.nDisEndTime))
                end
                szTip = szTip .. string.format("（原价：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='35' height='35' />，<color=#FFE26E>%d折</c>%s）", tCoinInfo.nCoin, FurnitureBuy.GetDiscountNum(nDisCoincount), szEndTime)
            end
            if tCoinInfo.nEndTime ~= -1 and tCoinInfo.bSell then
                szTip = szTip .. "\n" .. string.format("限时：<color=#FFE26E>%s</c>结售", CoinShop_GetTimeText(tCoinInfo.nEndTime))
            end
            if not tCoinInfo.bSell then
                szTip = szTip .. "\n" .. g_tStrings.STR_BUY_FURNITURE_SELL_END
            end
        elseif nReBuyCost and nReBuyCost > 0 then
            szTip = string.format("价格：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi' width='35' height='35' />", nReBuyCost)
        elseif nArchitecture and nArchitecture > 0 then
            --> 挂件家具没有资源点字段
            if bInArchDiscount then
                szTip = string.format("价格：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi' width='35' height='35' />", tFurnitureConfig.nFinalArchitecture)

                local szEndTime = ""
                if tFurnitureConfig.nDiscountEndTime ~= -1 then
                    szEndTime = string.format("，优惠将在<color=#FFE26E>%s</c>结束", CoinShop_GetTimeText(tFurnitureConfig.nDiscountEndTime))
                end
                szTip = szTip .. string.format("（原价：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi' width='35' height='35' />，<color=#FFE26E>%d折</c>%s）", tFurnitureConfig.nArchitecture, FurnitureBuy.GetDiscountNum(nDisArchcount), szEndTime)
            else
                szTip = string.format("价格：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi' width='35' height='35' />", nArchitecture)
            end
        end
    end

    tbInfo[1] = szTip
    self.scriptFurnitureCost:OnEnter(tbInfo)

    tbInfo = {}
    if not self.scriptFurnitureBuyDesc then
        self.scriptFurnitureBuyDesc = self:AddPrefab("scriptFurnitureBuyDesc", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptFurnitureBuyDesc"] = self.scriptFurnitureBuyDesc
    end

    -- 购买描述
    local szTip = ""
    szTip = ShopData.GetShopTip(szTip, self.aShopInfo, item, bHaveCmp)

    if bFromBuilding then
        if tCoinInfo then
            if not bLockedForLevel and tCoinInfo.bSell then
                szTip = szTip .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_HOMELAND_FURNITURE_TIP_CAN_BUY_WITH_COIN)
            end
        elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
            if not bLockedForLevel and HomelandEventHandler.CanBuyFurnitureWithArchitecture(dwFurnitureID, false, 1) then
                szTip = szTip .. GetFormatText("\n" .. g_tStrings.STR_HOMELAND_FURNITURE_TIP_CAN_BUY_WITH_ARCHITECTURE, 163)
            end
        elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
            if Homeland_CanIsotypePendant(dwFurnitureID) then
                local tLine = FurnitureData.GetPendantInfo(tUIInfo.nCatg1Index, tUIInfo.nCatg2Index)
                local szItemTip = tLine.szItemTip
                szTip = szTip .. GetFormatText("\n" .. szItemTip .. "\n", 163)
            end
        end
    end

    if item then
        szTip = szTip .. GetFormatText("\n") .. GetItemRewardsTip(item)
    elseif tCoinInfo and tCoinInfo.eGoodsType and tCoinInfo.dwGoodsID then
        szTip = szTip .. GetGoodsRewardsTip(tCoinInfo.eGoodsType, tCoinInfo.dwGoodsID, tCoinInfo.tPrice)
    end

    if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID) then
        szTip = szTip .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_AFTER_COLLECTED)
    elseif nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and FurnitureBuy.IsSpecialFurnitrueCanBuyNotHave(dwFurnitureID) then
        szTip = szTip .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_FURNITURE_TIP_SPECIAL_CANBUY_NEED_COLLECTED)
    end

    if nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
        local bCanDo, eErrType = Homeland_CanIsotypePendant(dwFurnitureID)
        if (not bCanDo) and eErrType == PENDANT_ERROR_TYPE.NOT_ACQUIRED then
            szTip = szTip .. string.format("<color=#FFE26E>%s</c>", g_tStrings.STR_HOMELAND_PENDANT_ITEM_STORAGE_USED_UP_4)
        end
    end

    tbInfo[1] = szTip
    self.scriptFurnitureBuyDesc:OnEnter(tbInfo)

end

function UIItemTip:UpdateFurnitureInfo(item)
    if not item then
        return
    end

    if self.bItem and (item.nGenre ~= ITEM_GENRE.HOMELAND or item.dwTabType ~= ITEM_TABLE_TYPE.HOMELAND) then
        return
    end

    local nFurnitureType, dwFurnitureID = FurnitureData.GetTypeAndIDWithItem(item, self.bItem)
    if nFurnitureType == 0 and dwFurnitureID == 0 then
        return
    end

    self:UpdateFurnitureInfoWithFurnitureID(nFurnitureType, dwFurnitureID)
end

function UIItemTip:UpdatePendantGuideInfo(szGuide)
    local tbInfo = {}

    if not string.is_nil(szGuide) then
        szGuide = string.pure_text(szGuide)
        tbInfo[1] = string.format("<color=#FFE26E>%s%s</c>", g_tStrings.STR_PENDANT_GUIDETIP, szGuide)
    end

    if not self.scriptPendantGuideInfo then
        self.scriptPendantGuideInfo = self:AddPrefab("scriptPendantGuideInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptPendantGuideInfo._rootNode:setName("scriptPendantGuideInfo")
        self.tbScript["scriptPendantGuideInfo"] = self.scriptPendantGuideInfo
    end
    self.scriptPendantGuideInfo:OnEnter(tbInfo)

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    self:UpdateTipHeight()
end

function UIItemTip:UpdateItemBaseInfo(item, nLuckyValue, nID)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre == ITEM_GENRE.EQUIPMENT or item.nGenre == ITEM_GENRE.HOMELAND or item.nGenre == ITEM_GENRE.NPC_EQUIPMENT then
        if self.scriptItemBaseInfo then
            self.scriptItemBaseInfo:OnEnter(tbInfo)
        end
        return
    end
    local player = PlayerData.GetClientPlayer()
    local hItemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item

    local szLevelTip = ""
    if item.nLevel and item.nLevel > 0 then
        szLevelTip = string.format("<color=#FFE26E>品质等级  %d</c>", item.nLevel)
    end

    local szNeedLevelTip = GetRequireTip(item, self.bItem, { [5] = true })
    if szNeedLevelTip == "" then
        hItemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
        local nRequireLevel = (((hItemInfo and hItemInfo.nRequireLevel) and hItemInfo.nRequireLevel > 0) and hItemInfo.nRequireLevel or 1)
        local bEnoughLV = player.nLevel >= hItemInfo.nRequireLevel
        if not bEnoughLV then
            szNeedLevelTip = "<color=#FF9696>需要等级  " .. nRequireLevel .. "</c>"
        else
            szNeedLevelTip = "<color=#D7F6FF>需要等级  " .. nRequireLevel .. "</c>"
        end
    end
    if szLevelTip ~= "" then
        tbInfo[1] = string.format("%s\n%s", szLevelTip, szNeedLevelTip)
    else
        tbInfo[1] = szNeedLevelTip
    end

    if not self.scriptItemBaseInfo then
        self.scriptItemBaseInfo = self:AddPrefab("scriptItemBaseInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemBaseInfo"] = self.scriptItemBaseInfo
    end


    -- 运势值
    -- local dwTabType, dwIndex
    -- if self.bItem then
    --     dwTabType, dwIndex = item.dwTabType, item.dwIndex
    -- else
    --     dwTabType, dwIndex = self.nTabType, self.nTabID
    -- end

    -- local nBoxID = TreasureBoxData.GetBoxIDByTab(dwTabType, dwIndex)
    -- if nBoxID and nBoxID < 8 then
    --     if nLuckyValue and nID == nBoxID then
    --         tbInfo[2] = "运势值：" .. nLuckyValue
    --     else
    --         tbInfo[2] = "运势值：" .. 0
    --         RemoteCallToServer("On_BoxOpenUI_GetBoxLuckyValue", nBoxID)
    --     end
    -- end

    self.scriptItemBaseInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateHairDyeWarning(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM or item.nSub ~= EQUIPMENT_SUB.HELM then
        if self.scriptHairDyeWarning then
            self.scriptHairDyeWarning:OnEnter(tbInfo)
        end
        return
    end

    local hPlayer = PlayerData.GetClientPlayer()
    local hHairShopClient = GetHairShop()
    local hDyeingManager = GetHairCustomDyeingManager()
    if not hDyeingManager or not hHairShopClient or not hPlayer then
        if self.scriptHairDyeWarning then
            self.scriptHairDyeWarning:OnEnter(tbInfo)
        end
        return
    end
    local tLogicHairColor        		= hDyeingManager.GetAllHairColor()
    local nHair 						= item.nDetail
    local tHairPrice                    = hHairShopClient.GetHairPrice(hPlayer.nRoleType, HAIR_STYLE.HAIR, nHair)
    local dwForbidDyeingColorMask  		= tHairPrice.dwForbidDyeingColorMask
    local tNotShowCostType 				= {}
    local szMsg							= g_tStrings.STR_ITEM_HAIR_DYEING_TIP
    local bFirst						= true

    if dwForbidDyeingColorMask == 0 then
        if self.scriptHairDyeWarning then
            self.scriptHairDyeWarning:OnEnter(tbInfo)
        end
        return
    end

    for k, v in pairs(tLogicHairColor) do
        local dwCostType                = v.nCostType
        if not tNotShowCostType[dwCostType] and kmath.is_logicbit1(dwForbidDyeingColorMask, dwCostType) then
            tNotShowCostType[dwCostType] 	= true
            local tInfo 					= Table_GetDyeingHairCostTypeInfo(dwCostType)
            if tInfo then
                if bFirst then
                    szMsg = table.concat({szMsg, tInfo.szCostTypeName and UIHelper.GBKToUTF8(tInfo.szCostTypeName)})
                else
                    szMsg = table.concat({szMsg, "、", tInfo.szCostTypeName and UIHelper.GBKToUTF8(tInfo.szCostTypeName)})
                end
                bFirst = false
            end
        end
    end

    if bFirst then
        if self.scriptHairDyeWarning then
            self.scriptHairDyeWarning:OnEnter(tbInfo)
        end
        return
    end

    tbInfo[1] = "<color=#FF9696>"..szMsg.."</c>"
    if not self.scriptHairDyeWarning then
        self.scriptHairDyeWarning = self:AddPrefab("scriptHairDyeWarning", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptHairDyeWarning"] = self.scriptHairDyeWarning
    end

    self.scriptHairDyeWarning:OnEnter(tbInfo)
end

function UIItemTip:UpdateSkillSkinWarning(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.MATERIAL or item.nSub ~= MATERIAL_SUB_TYPE.SKILL_SKIN then
        if self.scriptSkillSkinWarning then
            self.scriptSkillSkinWarning:OnEnter(tbInfo)
        end
        return
    end

    local tbSkinItemList = CharacterSkillSkinData.GetSkinItemList()
    local dwItemIndex = self.bItem and item.dwIndex or self.nTabID
    if tbSkinItemList[dwItemIndex] then
        if self.scriptSkillSkinWarning then
            self.scriptSkillSkinWarning:OnEnter(tbInfo)
        end
        return
    end

    tbInfo[1] = "<color=#FF4040>"..g_tStrings.STR_SKILL_SKIN_WARNING.."</c>"

    if not self.scriptSkillSkinWarning then
        self.scriptSkillSkinWarning = self:AddPrefab("scriptSkillSkinWarning", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptSkillSkinWarning"] = self.scriptSkillSkinWarning
    end

    self.scriptSkillSkinWarning:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemBindInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    local szBind = self:GetBindInfo(item)
    if string.is_nil(szBind) then
        if self.scriptItemBindInfo then
            self.scriptItemBindInfo:OnEnter(tbInfo)
        end
        return
    end

    tbInfo[1] = szBind
    if not self.scriptItemBindInfo then
        self.scriptItemBindInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end
    self.scriptItemBindInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemIgnoreBindMaskInfo(item)
    local tbInfo = {}

    if not item then
        return
    end
    local szBind = self:GetIgnoreBindMaskInfo(item)
    if string.is_nil(szBind) then
        if self.scriptItemIgnoreBindMaskInfo then
            self.scriptItemIgnoreBindMaskInfo:OnEnter(tbInfo)
        end
        return
    end

    tbInfo[1] = szBind
    if not self.scriptItemIgnoreBindMaskInfo then
        self.scriptItemIgnoreBindMaskInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end
    self.scriptItemIgnoreBindMaskInfo:OnEnter(tbInfo)
end

----存在类型----------------
local function GetDeltaTimeText(nTime)
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H
    end
    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M
    end
    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S
    end
    return szText
end

function UIItemTip:UpdateItemTimeLimit(item, bInit)
    if not item then
        return
    end
    local tbInfo = {}

    local itemInfo = self.bItem and GetItemInfo(item.dwTabType, item.dwIndex) or item
    local nLeftTime = 0
    if self.bItem then
        nLeftTime = item.GetLeftExistTime()
    end
    local szTimeLimit = nil

    if itemInfo.nExistType == ITEM_EXIST_TYPE.INVALID then
        if self.scriptItemTimeLimitInfo then
            self.scriptItemTimeLimitInfo:OnEnter(tbInfo)
        end
        return
    end

    if itemInfo.nExistType == ITEM_EXIST_TYPE.OFFLINE then
        if nLeftTime > 0 then
            local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
            szTimeLimit = string.format(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
            if self.bIsPlayStore then
                local nFullTime = math.ceil(nLeftTime / 86400) * 86400
                local szTime = GetDeltaTimeText(nFullTime)
                szTimeLimit = string.format(g_tStrings.STR_ITEM_TIME_OVER_SYS_SHOP, szTime)
            end
        else
            szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE1
        end
    elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINE then
        if nLeftTime > 0 then
            local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
            szTimeLimit = string.format(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
            if self.bIsPlayStore then
                local nFullTime = math.ceil(nLeftTime / 86400) * 86400
                local szTime = GetDeltaTimeText(nFullTime)
                szTimeLimit = string.format(g_tStrings.STR_ITEM_TIME_OVER_SYS_SHOP, szTime)
            end
        else
            szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE2
        end
    elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE or itemInfo.nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
        if nLeftTime > 0 then
            local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
            szTimeLimit = string.format(g_tStrings.STR_ITEM_TIME_OVER, szTime)
            if itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE and self.bIsPlayStore then
                local nFullTime = math.ceil(nLeftTime / 86400) * 86400
                local szTime = GetDeltaTimeText(nFullTime)
                szTimeLimit = string.format(g_tStrings.STR_ITEM_TIME_OVER_SYS_SHOP, szTime)
            end
        else
            szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE3
        end
    end


    if szTimeLimit then
        table.insert(tbInfo, szTimeLimit)
        if self.bItem then
            local nItemID = item.dwID
            self.nTimeLimitTimerID = self.nTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime, function()
                local hItem = ItemData.GetItem(nItemID)
                self:UpdateItemTimeLimit(hItem)
            end, function()
                self.nTimeLimitTimerID = nil
            end)
        end
    end

    if bInit then
        self.scriptItemTimeLimitInfo = self:AddPrefab("scriptItemTimeLimitInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptItemTimeLimitInfo._rootNode:setName("scriptItemTimeLimitInfo")
        self.tbScript["scriptItemTimeLimitInfo"] = self.scriptItemTimeLimitInfo
    else
        self.scriptItemTimeLimitInfo = self.scriptItemTimeLimitInfo or self:AddPrefab("scriptItemTimeLimitInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptItemTimeLimitInfo._rootNode:setName("scriptItemTimeLimitInfo")
        self.tbScript["scriptItemTimeLimitInfo"] = self.scriptItemTimeLimitInfo
    end

    self.scriptItemTimeLimitInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateReturnItemTimeLimit(item)
    if not item or not self.bItem then
        return
    end
    local nLeftTime = ItemData.GetReturnItemLeftTime(item)
    if self.scriptReturnItemTimeLimitInfo then
        UIHelper.SetVisible(self.scriptReturnItemTimeLimitInfo._rootNode, nLeftTime > 0)
    end
    if nLeftTime <= 0 then
        return
    end
    local szLeftTime = UIHelper.GetDeltaTimeText(nLeftTime, false)
    local szTimeLimit = string.format(g_tStrings.Shop.STR_RETURN_LTIME, szLeftTime)

    local nItemID = item.dwID
    self.nReturnItemTimeLimitTimerID = self.nReturnItemTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime, function()
        local hItem = ItemData.GetItem(nItemID)
        self:UpdateReturnItemTimeLimit(hItem)
    end, function()
        self.nReturnItemTimeLimitTimerID = nil
    end)

    if not self.scriptReturnItemTimeLimitInfo then
        self.scriptReturnItemTimeLimitInfo = self:AddPrefab("scriptReturnItemTimeLimitInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptReturnItemTimeLimitInfo._rootNode:setName("scriptReturnItemTimeLimitInfo")
        self.tbScript["scriptReturnItemTimeLimitInfo"] = self.scriptReturnItemTimeLimitInfo
    end
    self.scriptReturnItemTimeLimitInfo:OnEnter({ szTimeLimit })
end

function UIItemTip:UpdateBuyBackItemTimeLimit(item)
    if not item or not self.bItem then
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nLeftTime = player.GetTimeLimitSoldListInfoLeftTime(item.dwID)
    if nLeftTime <= 0 then
        return
    end
    local szLeftTime = UIHelper.GetDeltaTimeText(nLeftTime, false)
    local szTimeLimit = string.format(g_tStrings.Shop.STR_BUY_BACK_LTIME, szLeftTime)

    self.nBuyBackItemTimeLimitTimerID = self.nBuyBackItemTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime, function()
        local hItem = self:GetItem()
        self:UpdateBuyBackItemTimeLimit(hItem)
    end, function()
        self.nBuyBackItemTimeLimitTimerID = nil
    end)

    if not self.scriptBuyBackItemTimeLimitInfo then
        self.scriptBuyBackItemTimeLimitInfo = self:AddPrefab("scriptBuyBackItemTimeLimitInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptBuyBackItemTimeLimitInfo._rootNode:setName("scriptBuyBackItemTimeLimitInfo")
        self.tbScript["scriptBuyBackItemTimeLimitInfo"] = self.scriptBuyBackItemTimeLimitInfo
    end
    self.scriptBuyBackItemTimeLimitInfo:OnEnter({ szTimeLimit })
end

function UIItemTip:UpdateTradeTimeLimit(item)
    if not item or not self.bItem then
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nLeftTime = player.GetTradeItemLeftTime(item.dwID)
    if nLeftTime <= 0 then
        return
    end
    local szLeftTime = UIHelper.GetDeltaTimeText(nLeftTime, false)
    local szTimeLimit = "<color=#95FF95>" .. string.format(g_tStrings.Shop.STR_TRADE_LTIME, szLeftTime) .. "</color>"

    self.nCanTradeLimitTimerID = self.nCanTradeLimitTimerID or Timer.AddCountDown(self, nLeftTime, function()
        local hItem = self:GetItem()
        self:UpdateTradeTimeLimit(hItem)
    end, function()
        self.nCanTradeLimitTimerID = nil
    end)

    if not self.scriptTradeTimeLimitInfo then
        self.scriptTradeTimeLimitInfo = self:AddPrefab("scriptTradeTimeLimitInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptTradeTimeLimitInfo._rootNode:setName("scriptTradeTimeLimitInfo")
        self.tbScript["scriptTradeTimeLimitInfo"] = self.scriptTradeTimeLimitInfo
    end
    self.scriptTradeTimeLimitInfo:OnEnter({ szTimeLimit })
end

function UIItemTip:GetItemSource(item, dwItemType, dwItemIndex)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tSource = ItemData.GetItemSourceList(dwItemType, dwItemIndex)
    if not tSource then
        return
    end

    return LocalGetSource(tSource, dwItemType, dwItemIndex, self.nShopNeedCount)
end

function UIItemTip:ApplyItemSource(tbInfo)
    if not self.scriptItemSourceInfo then
        self.scriptItemSourceInfo = self:AddPrefab("scriptItemSourceInfo", PREFAB_ID.WidgetItemTipContent10)
        self.tbScript["scriptItemSourceInfo"] = self.scriptItemSourceInfo
    end
    self.scriptItemSourceInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemSource(item, dwItemType, dwItemIndex)
    if SelfieData.IsInSelfieView() then
        return
    end

    if dwItemType and dwItemIndex then
    else
        if not item or item.nGenre == ITEM_GENRE.BOOK then
            return
        end
        if self.bItem then
            dwItemType, dwItemIndex = item.dwTabType, item.dwIndex
        else
            dwItemType, dwItemIndex = self.nTabType, self.nTabID
        end

        if not dwItemType or not dwItemIndex then
            return
        end
    end

    local tbInfo = self:GetItemSource(item, dwItemType, dwItemIndex)
    if not tbInfo or not tbInfo[1] or table_is_empty(tbInfo[1]) then
        if self.scriptItemSourceInfo then
            UIHelper.SetVisible(self.scriptItemSourceInfo._rootNode, false)
        end
        return
    end

    self:ApplyItemSource(tbInfo)
end

local function CheckBookHaveSource(tBook)
    if #tBook.tQuests > 0 or #tBook.tDoodad > 0 or #tBook.tSourceMap > 0 or #tBook.tSourceNpc > 0 or #tBook.tBoss > 0 or tBook.bSourceTrade then
        return true
    end
end

function UIItemTip:UpdateBookSource(item)
    if not item or item.nGenre ~= ITEM_GENRE.BOOK then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    self.tBooks = self.tBooks or ItemData.GetAllBookInfo()
    if table_is_empty(self.tBooks) then
        return
    end

    local nBookID
    if self.bItem then
        nBookID = item.nBookID
    else
        nBookID = self.nBookID
    end

    local tBook = self.tBooks[nBookID]
    if not tBook or table_is_empty(tBook) or not CheckBookHaveSource(tBook) then
        return
    end

    local tbInfo = {}
    tbInfo[1] = {}
    -- tbInfo[1] = g_tStrings.STR_BOOK_TIP_GET_WAY1
    ItemData.GetBookSourceTradeTip(tBook.bSourceTrade, tbInfo, nBookID)
    ItemData.GetSourceShopNpcTip(tBook.tSourceNpc, tbInfo)
    ItemData.GetSourceDoodadTip(tBook.tDoodad, tbInfo)
    ItemData.GetSourceQuestTip(tBook.tQuests, tbInfo, player)
    ItemData.GetSourceBossTip(tBook.tBoss, tbInfo)
    ItemData.GetSourceMapTip(tBook.tSourceMap, tbInfo)

    local szItemDesc = Table_GetItemDesc(item.nUiId)
    if szItemDesc and szItemDesc ~= "" then
        szItemDesc = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szItemDesc), false)
    end

    -- tbInfo[1] = string.format("%s%s", tbInfo[1], szItemDesc)

    if not self.scriptBookDescInfo then
        self.scriptBookDescInfo = self:AddPrefab("scriptBookDescInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptBookDescInfo"] = self.scriptBookDescInfo
    end
    self.scriptBookDescInfo:OnEnter({ szItemDesc })

    if not self.scriptBookSourceInfo then
        self.scriptBookSourceInfo = self:AddPrefab("scriptBookSourceInfo", PREFAB_ID.WidgetItemTipContent10)
        self.tbScript["scriptBookSourceInfo"] = self.scriptBookSourceInfo
    end
    self.scriptBookSourceInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemTitleTip(item)
    if not item then
        return
    end
    local tbInfo = {}
    local itemInfo
    if self.bItem then
        itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    else
        itemInfo = item
    end

    local szItemDesc = ItemData.GetTitleTips(itemInfo)
    if szItemDesc and szItemDesc ~= "" then
        tbInfo[1] = "<color=#95FF95>" .. szItemDesc .. "</color>"
    end

    if not self.scriptTitleTipInfo then
        self.scriptTitleTipInfo = self:AddPrefab("scriptTitleTipInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptTitleTipInfo"] = self.scriptTitleTipInfo
    end
    self.scriptTitleTipInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemDescInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        if self.scriptItemDescInfo then
            self.scriptItemDescInfo:OnEnter(tbInfo)
        end
        return
    elseif item.nGenre == ITEM_GENRE.BOOK then
        if self.scriptItemDescInfo then
            self.scriptItemDescInfo:OnEnter(tbInfo)
        end
        return
    end

    local szItemDesc = ItemData.GetItemDesc(item.nUiId) --Table_GetItemDesc(item.nUiId)
    if szItemDesc and szItemDesc ~= "" then
        if item.nGenre == ITEM_GENRE.BOX then
            tbInfo[1] = "<color=#95FF95>" .. ParseTextHelper.ParseFrameDesc(szItemDesc, 24) .. "</color>"
        elseif item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
            tbInfo[1] = ParseTextHelper.ParseNormalText(szItemDesc, false)
            tbInfo[1] = string.gsub(tbInfo[1], "\\", "")
        else
            tbInfo[1] = ParseTextHelper.ParseNormalText(szItemDesc, false)
        end
        --LOG.WARN(ParseTextHelper.ParseNormalText(szItemDesc))
    end

    if not self.scriptItemDescInfo then
        self.scriptItemDescInfo = self:AddPrefab("scriptItemDescInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemDescInfo"] = self.scriptItemDescInfo
    end
    self.scriptItemDescInfo:OnEnter(tbInfo)

    --self:UpdateFuShiInfo(item)
end

--一个特殊的处理，砆石vk要显示一条历练信息
function UIItemTip:UpdateFuShiInfo(item)
    if item.nUiId == 290603 then
        if g_pClientPlayer.GetRemoteArrayUInt(1072, 7, 1) < HuaELouData.WEEK_CHIPS_LIMIT then
            local tbInfo = {}
            local nCount = g_pClientPlayer.GetRemoteArrayUInt(1072, 2, 2) - 210 * g_pClientPlayer.GetRemoteArrayUInt(1072, 7, 1)
            local szText = "还需%s历练值可再获得1枚玉灵淬石"
            tbInfo[1] = string.format(szText, tostring(210 - nCount))

            if not self.scriptFushiDescInfo then
                self.scriptFushiDescInfo = self:AddPrefab("scriptFushiDescInfo", PREFAB_ID.WidgetItemTipContent1)
                self.tbScript["scriptFushiDescInfo"] = self.scriptFushiDescInfo
            end
            self.scriptFushiDescInfo:OnEnter(tbInfo)
        end
    end
end

local function GetRewardsTip(dwTabType, dwIndex)
    local szRewardsTip = ""
    local nRewards = GetFinalItemRewards(dwTabType, dwIndex)  --使用后获取商城积分
    if not nRewards or nRewards <= 0 then
        return ""
    end
    local szFrame = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JiFen' width='35' height='35' />"
    szRewardsTip = FormatString(g_tStrings.STR_ITEM_GET_REWARDS, nRewards)
    szRewardsTip = szRewardsTip .. szFrame
    return szRewardsTip
end

function UIItemTip:UpdateItemCoolDownInfo(item)
    if not item then
        return
    end

    local itemInfo
    if self.bItem then
        itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
    else
        itemInfo = item
    end
    if not itemInfo then
        return
    end

    local tbInfo = {}

    local nRestTime = GetItemCoolDown(itemInfo.dwSkillID, itemInfo.dwSkillLevel, itemInfo.dwCoolDownID);
    if nRestTime and nRestTime ~= 0 and nRestTime ~= 16 then
        tbInfo[1] = FormatString(g_tStrings.STR_ITEM_USE_TIME1, UIHelper.GetDeltaTimeText(nRestTime, true))
    end

    if not self.scriptItemCoolDownInfo then
        self.scriptItemCoolDownInfo = self:AddPrefab("scriptItemCoolDownInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemCoolDownInfo"] = self.scriptItemCoolDownInfo
    end
    self.scriptItemCoolDownInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateCustomTextInfo(item)
    local tbInfo = {}
    if not self.scriptItemCustomTextInfo then
        self.scriptItemCustomTextInfo = self:AddPrefab("scriptItemCustomTextInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemCustomTextInfo"] = self.scriptItemCustomTextInfo
    end

    if not item then
        self.scriptItemCustomTextInfo:OnEnter(tbInfo)
        return
    end

    if not self.bItem then
        self.scriptItemCustomTextInfo:OnEnter(tbInfo)
        return
    end

    local szCText = item.GetCustomText()
    if szCText and szCText ~= "" then
        local szTips = string.pure_text(FormatString(g_tStrings.STR_SIGNATURE, UIHelper.GBKToUTF8(szCText)))
        tbInfo[1] = string.format("<color=#95FF95>%s</c>", szTips)
    end

    self.scriptItemCustomTextInfo:OnEnter(tbInfo)
end

local function IsTradeMallFilter(pItem, bItem)
    if not bItem then
        return
    end

    local pItemInfo = GetItemInfo(pItem.dwTabType, pItem.dwIndex)
    if not pItemInfo then
        return
    end
    local bFilter = pItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT or pItem.bBind
    return IsTradeMallItem(pItem.dwTabType, pItem.dwIndex) and not bFilter
end

function UIItemTip:UpdateCoinShopInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    local szTip = ""

    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = self.nTabType, self.nTabID
    end

    local szRewardsTip = GetRewardsTip(dwTabType, dwIndex)
    szTip = szTip .. szRewardsTip
    if IsTradeMallFilter(item, self.bItem) then
        local szWBLSell = string.is_nil(szTip) and g_tStrings.STR_ITEM_H_WBLSELL or "\n" .. g_tStrings.STR_ITEM_H_WBLSELL
        szTip = szTip .. szWBLSell
    end

    if string.is_nil(szTip) then
        return
    end
    tbInfo[1] = szTip
    if not self.scriptItemCoinShopInfo then
        self.scriptItemCoinShopInfo = self:AddPrefab("scriptItemCoinShopInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemCoinShopInfo"] = self.scriptItemCoinShopInfo
    end
    self.scriptItemCoinShopInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateWanBaoLouInfo(item, bTradeRespondEvent)
    if not item then
        return
    end

    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = self.nTabType, self.nTabID
    end
    if not IsTradeMallFilter({dwTabType = dwTabType, dwIndex = dwIndex}, true) then
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    if not self.scriptItemWanBaoLouInfo then
        self.scriptItemWanBaoLouInfo = self:AddPrefab("scriptItemWanBaoLouInfo", PREFAB_ID.WidgetItemTipContent13)
        self.tbScript["scriptItemWanBaoLouInfo"] = self.scriptItemWanBaoLouInfo
    end
    self.scriptItemWanBaoLouInfo:OnEnter(dwTabType, dwIndex, bTradeRespondEvent)
end

function UIItemTip:UpdateEquipDescInfo(item)
    if not item then
        return
    end
    local tbInfo = {}

    if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        if self.scriptEquipDescInfo then
            self.scriptEquipDescInfo:OnEnter(tbInfo)
        end
        return
    end

    local szItemDesc = Table_GetItemDesc(item.nUiId)
    if szItemDesc and szItemDesc ~= "" then
        local szDesc = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szItemDesc), false)
        if szDesc ~= "" then
            tbInfo[1] = string.format("<color=#FFE26E>%s</c>", szDesc)
        else
            tbInfo[1] = szDesc
        end
    end

    if not self.scriptEquipDescInfo then
        self.tbScript = self.tbScript or {}
        self.scriptEquipDescInfo = self:AddPrefab("scriptEquipDescInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptEquipDescInfo._rootNode:setName("scriptEquipDescInfo")
        self.tbScript["scriptEquipDescInfo"] = self.scriptEquipDescInfo
    end
    self.scriptEquipDescInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipCustomNameTipInfo(item)
    if not item or not self.nPlayerID then
        return
    end

    local tbInfo = {}
    local dwItemIndex = self.bItem and item.dwIndex or self.nTabID
    -- local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
	-- if not itemInfo then
    --     if self.scriptEquipCustomNameInfo then
    --         self.scriptEquipCustomNameInfo:OnEnter(tbInfo)
    --     end
    --     return
	-- end
    local szTip = ""
    local player = GetPlayer(self.nPlayerID)
    if not player then
        if self.scriptEquipCustomNameInfo then
            self.scriptEquipCustomNameInfo:OnEnter(tbInfo)
        end
        return
    end
    if self.nPlayerID and self.nPlayerID > 0 and not (IsRemotePlayer(UI_GetClientPlayerID()) or IsRemotePlayer(self.nPlayerID)) then
        ItemData.SetQixiRingOwnerID(self.nPlayerID)
    end
    if ItemData.IsPendantItem(item) then
        --七夕君心问情--3年
        if dwItemIndex == 13937 and not IsRemotePlayer(player.dwID) and ItemData.GetQixiRingOwnerID() and not IsRemotePlayer(ItemData.GetQixiRingOwnerID()) and ItemData.GetQiXiInscriptionInfo(ItemData.GetQixiRingOwnerID()) then
            local tInfo = ItemData.GetQiXiInscriptionInfo(ItemData.GetQixiRingOwnerID())
            if tInfo and tInfo[1] and tInfo[1].szName and tInfo.t3Year and tInfo.t3Year.szName then
                local szTipGroupName = "QIXI_TIPS3YEAR"
                local szTipQixiRing = g_tStrings[szTipGroupName].TITLE..g_tStrings[szTipGroupName].MARK[1].."%s"..g_tStrings[szTipGroupName].AND.."%s"..g_tStrings[szTipGroupName].TAIL
                szTipQixiRing = szTipQixiRing:format(UIHelper.GBKToUTF8(tInfo[1].szName), UIHelper.GBKToUTF8(tInfo.t3Year.szName))
                szTip = szTip..szTipQixiRing
            end
        end
        --七夕香雪流霞2015
        if dwItemIndex == 13938 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 9, "QIXI_TIPS2015")
        end
        --2016桃华夭夭
        if dwItemIndex == 18348 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 10, "QIXI_TIPS2016")
        end
        --2017夜雨沁荷
        if dwItemIndex == 19533 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 12, "QIXI_TIPS2017")
        end
        --2018伶雀飞花
        --[[要修改的内容说明：
        1. dwItemIndex，这是每年的挂件ID
        2. tInfo[i]中的i，这个i与scripts/Map/节日七夕/include/QiXi_GetLianLiID.lua中的tLoverIDPos、tName、tLoverItem_Year、tIgnoreLoverPos有关联，它们通用一套顺序
        *这一套顺序是所有刻字的挂件按制作先后顺序排列的，因此本脚本上边2016年用的是tInfo[10]而2017年用的是tInfo[12]，中间跳过的11是刻字挂件但不是七夕情缘挂件
        *为什么数字对不上？因为tInfo最前面有一个玩家ID等其他占位占位，但没有写在QiXi_GetLianLiID.lua的tLoverIDPos、tName表里，所以正常情况下按该顺序顺延序号即可
        3. g_tStrings.QIXI_TIPS2018，其具体内容是在\client\ui\String\string.lua中定义的]]
        if dwItemIndex == 19837 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 13, "QIXI_TIPS2018")
        end
        --2019佳偶天成
        if dwItemIndex == 25237 or dwItemIndex == 25238 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 14, "QIXI_TIPS2019")
        end
        --2020蝶恋花
        if dwItemIndex == 25494 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 15, "QIXI_TIPS2020")
        end
        --2021玲珑相思子
        if dwItemIndex == 25768 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 16, "QIXI_TIPS2021")
        end
        --七夕银心铃
        --	local tQixiTongXinSuo = {[11800] = true,}
        if dwItemIndex == 11800 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 7, "QIXI_TIPS4")
        end
        --三尺青锋
        local tQiYuSanChiQingFeng = {[13796] = true,}
        if tQiYuSanChiQingFeng[dwItemIndex] then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 8, "QY_SCQF")
        end
        --2022年情人节
        if dwItemIndex == 25894 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 17, "QIXI_TIPS2022QRJ")
        end
        --2022年七夕背挂
        if dwItemIndex == 26017 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 18, "QIXI_TIPS2022")
        end
        --2023年七夕背挂
        if dwItemIndex == 36800 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 19, "QIXI_TIPS2023")
        end
        --2024年七夕背挂
        if dwItemIndex == 37052 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 20, "QIXI_TIPS2024")
        end
        --2025年七夕背挂
        if dwItemIndex == 37559 then
            szTip = szTip .. ItemData.GetCustomNameTip(player, 21, "QIXI_TIPS2025")
        end
    end
    local tQixiRings = {[1899] = true, [1900] = true, [1901] = true, [1902] = true, [1903] = true, [1904] = true, [1905] = true, [1906] = true, [1907] = true, [1908] = true, [1909] = true, [1910] = true, [1911] = true, [1912] = true, [1913] = true, [1914] = true, [1915] = true, }
	if not IsRemotePlayer(player.dwID) and ItemData.GetQixiRingOwnerID() and not IsRemotePlayer(ItemData.GetQixiRingOwnerID()) and ItemData.GetQiXiInscriptionInfo(ItemData.GetQixiRingOwnerID()) and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.RING and tQixiRings[dwItemIndex] then
		local tInfo = ItemData.GetQiXiInscriptionInfo(ItemData.GetQixiRingOwnerID())
		if (tInfo and tInfo[1] and tInfo[1].szName) then
            local szTipGroupName = "QIXI_TIPS"
            local szTipQixiRing = ""
			if tInfo[2] and tInfo[2].szName and tInfo[3] and tInfo[3].szName then
                local szTipQixiRing = g_tStrings[szTipGroupName].TITLE..g_tStrings[szTipGroupName].MARK[1].."%s"..g_tStrings[szTipGroupName].AND.."%s"..g_tStrings[szTipGroupName].MARK[2].."%s"..g_tStrings[szTipGroupName].TAIL
                szTipQixiRing = szTipQixiRing:format(UIHelper.GBKToUTF8(tInfo[1].szName), UIHelper.GBKToUTF8(tInfo[2].szName), UIHelper.GBKToUTF8(tInfo[3].szName))
			elseif tInfo[2] and tInfo[2].szName then
                local szTipQixiRing = g_tStrings[szTipGroupName].TITLE..g_tStrings[szTipGroupName].MARK[1].."%s"..g_tStrings[szTipGroupName].AND.."%s"..g_tStrings[szTipGroupName].TAIL
                szTipQixiRing = szTipQixiRing:format(UIHelper.GBKToUTF8(tInfo[1].szName), UIHelper.GBKToUTF8(tInfo[2].szName))
			elseif tInfo[3] and tInfo[3].szName then
				local szTipQixiRing = g_tStrings[szTipGroupName].TITLE..g_tStrings[szTipGroupName].MARK[1].."%s"..g_tStrings[szTipGroupName].AND.."%s"..g_tStrings[szTipGroupName].TAIL
                szTipQixiRing = szTipQixiRing:format(UIHelper.GBKToUTF8(tInfo[1].szName), UIHelper.GBKToUTF8(tInfo[3].szName))
			end
			szTip = szTip .. szTipQixiRing
		end
	end
	--七夕连理枝
	local tQixiPendants = {[4196] = true, [4197] = true, [4198] = true, [4199] = true, [4200] = true, [4201] = true, [4202] = true, [4203] = true, [4204] = true, [4205] = true, [4206] = true, [4207] = true, [4208] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PENDANT and tQixiPendants[dwItemIndex] then
		szTip = szTip .. ItemData.GetCustomNameTip(player, 4, "QIXI_TIPS2")
	end
	--七夕同心锁
	local tQixiTongXinSuo = {[5848] = true, [5849] = true, [5850] = true, [5851] = true, [5852] = true, [5853] = true, [5854] = true, [5855] = true, [5856] = true, [5857] = true, [5858] = true, [5859] = true, [5860] = true, [5861] = true, [5862] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.AMULET and tQixiTongXinSuo[dwItemIndex] then
		szTip = szTip .. ItemData.GetCustomNameTip(player, 5, "QIXI_TIPS3")
	end
	--七夕无棱
	local tQixiTongXinSuo = {[10320] = true, [10321] = true, [10322] = true, [10323] = true, [10324] = true, [10325] = true,}
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.RING and tQixiTongXinSuo[dwItemIndex] then
		szTip = szTip .. ItemData.GetCustomNameTip(player, 6, "QIXI_TIPS3")
	end
		-- 师徒武器
	local tShiTuWuQi = {
		[15413] = true,
		[15414] = true,
		[15415] = true,
		[15416] = true,
		[15417] = true,
		[15418] = true,
		[15419] = true,
		[15420] = true,
		[15421] = true,
		[15422] = true,
		[15423] = true,
		[15424] = true,
		[15425] = true,
		[15426] = true,
		[15427] = true,
		[15428] = true,
		[15429] = true,
		[15430] = true,
		[15431] = true,
		[15432] = true,
		[15433] = true,
		[15434] = true,
		[15435] = true,
		[15436] = true,
    }
	if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.MELEE_WEAPON and tShiTuWuQi[dwItemIndex] then
		szTip = szTip .. ItemData.GetCustomNameTip(player, 11, "SHITU")
	end

    if szTip ~= "" then
        tbInfo[1] = string.format("<color=#FFE26E>%s</c>", szTip)
    else
        tbInfo[1] = szTip
    end
    if not self.scriptEquipCustomNameInfo then
        self.tbScript = self.tbScript or {}
        self.scriptEquipCustomNameInfo = self:AddPrefab("scriptEquipCustomNameInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptEquipCustomNameInfo._rootNode:setName("scriptEquipCustomNameInfo")
        self.tbScript["scriptEquipCustomNameInfo"] = self.scriptEquipCustomNameInfo
    end
    self.scriptEquipCustomNameInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipCollectionInfo(item)
    if not item then return end

    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = self.nTabType, self.nTabID
    end
    local bRecommend, szRecommendTitle, nIndex = EquipCodeData.CheckIsRoleRecommendEquip(dwTabType, dwIndex)
    if not bRecommend then return end

    szRecommendTitle = string.format("<color=#FFEA88>%s</c>", szRecommendTitle)
    if not self.scriptCollectionInfo then
        self.tbScript = self.tbScript or {}
        self.scriptCollectionInfo = self:AddPrefab("scriptCollectionInfo", PREFAB_ID.WidgetItemTipContent14)
        self.scriptCollectionInfo._rootNode:setName("scriptCollectionInfo")
        self.tbScript["scriptCollectionInfo"] = self.scriptCollectionInfo
    end

    self.scriptCollectionInfo:OnEnter(szRecommendTitle, function ()
        UIMgr.Open(VIEW_ID.PanelCustomizedSetShell, 1, nIndex)
    end)

    self.scriptCollectionInfo:SetBtnVisible(not UIMgr.IsViewOpened(VIEW_ID.PanelCustomizedSetShell))
end

function UIItemTip:UpdateOrangeWeaponInfo(item)
    if not item then
        return
    end
    local tbInfo = {}

    if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        if self.scriptOrangeWeaponInfo then
            self.scriptOrangeWeaponInfo:OnEnter(tbInfo)
        end
        return
    end

    local szImg = "Resource/item_pic/" .. item.nUiId .. ".png"
    if Lib.IsFileExist(szImg) then
        tbInfo[4] = szImg
    end

    if not self.scriptOrangeWeaponInfo then
        self.tbScript = self.tbScript or {}
        self.scriptOrangeWeaponInfo = self:AddPrefab("scriptOrangeWeaponInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptOrangeWeaponInfo._rootNode:setName("scriptOrangeWeaponInfo")
        self.tbScript["scriptOrangeWeaponInfo"] = self.scriptOrangeWeaponInfo
    end
    self.scriptOrangeWeaponInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateSkillSkinInfo(nSkillID, nSkinID)
    local tbInfo = {}
    local szName = ""
    if nSkinID and nSkinID > 0 then
        tbInfo = Table_GetSkillSkinInfo(nSkinID)
        szName = UIHelper.GBKToUTF8(tbInfo.szName)
    else
        szName = Table_GetSkillName(nSkillID, 1)
        szName = UIHelper.GBKToUTF8(szName).."·".."默认"
    end

    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgQuality, ItemTipQualityBGColor[6])
    UIHelper.SetString(self.LabelAttachStatus, "")

    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 6)
    else
        self.scriptQualityBar:OnEnter(6)
    end

    if not self.scriptSkillSkinTopInfo then
        self.scriptSkillSkinTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, self.WidgetTopContent)
    end

    UIHelper.SetVisible(self.scriptSkillSkinTopInfo._rootNode, true)
    UIHelper.SetString(self.scriptSkillSkinTopInfo.LabelEquipType1, "武技殊影图")
    UIHelper.SetString(self.scriptSkillSkinTopInfo.LabelEquipType2, "")
    UIHelper.SetString(self.scriptSkillSkinTopInfo.LabelEquipType3, "")

    UIHelper.LayoutDoLayout(self.scriptSkillSkinTopInfo.LayoutRow1)

    for i, img in ipairs(self.scriptSkillSkinTopInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(img, false)
    end
    UIHelper.SetVisible(self.scriptSkillSkinTopInfo.LabelPlayType, false)
    UIHelper.SetVisible(self.scriptSkillSkinTopInfo.ImgPlayType, false)

    if not self.scriptSkillSkinInfo1 then
        self.scriptSkillSkinInfo1 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptSkillSkinInfo2 then
        self.scriptSkillSkinInfo2 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    local tbInfo3 = {}
    local szImg
    if nSkinID and nSkinID > 0 then
        local tbUISkinInfo = TabHelper.GetUISkillSkinInfo(nSkillID, nSkinID)
        szImg = tbUISkinInfo and UIHelper.FixDXUIImagePath(tbUISkinInfo.szImgPath) or nil
        if szImg and Lib.IsFileExist(szImg) then
            tbInfo3[4] = szImg
        end
    else
        szImg = SKILL_SKIN_CONFIG_IMG[nSkillID]
        if szImg and Lib.IsFileExist(szImg) then
            tbInfo3[4] = szImg
        end
    end

    if not self.scriptSkillSkinInfo3 then
        self.scriptSkillSkinInfo3 = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
    end

    if tbInfo.szDesc and tbInfo.szDesc ~= "" then
        self.scriptSkillSkinInfo1:OnEnter({ string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tbInfo.szDesc)) })
    else
        self.scriptSkillSkinInfo1:OnEnter({string.format("<color=#FFE26E>%s</c>", "穿戴切换至招式初始。")})
    end

    if tbInfo.szSource and tbInfo.szSource ~= "" then
        self.scriptSkillSkinInfo2:OnEnter({ string.format("<color=#FFE26E>%s</c>", UIHelper.GBKToUTF8(tbInfo.szSource)) })
    else
        self.scriptSkillSkinInfo2:OnEnter({})
    end

    self.scriptSkillSkinInfo3:OnEnter(tbInfo3)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIItemTip:UpdateSketchMapInfo(item)
    if not item then
        return
    end
    local tbInfo = {}

    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        if self.scriptSketchMapInfo then
            self.scriptSketchMapInfo:OnEnter(tbInfo)
        end
        return
    end

    local szImg = "Resource/item_pic/" .. item.nUiId .. ".png"
    if Lib.IsFileExist(szImg) then
        tbInfo[4] = szImg
    end

    if not self.scriptSketchMapInfo then
        self.tbScript = self.tbScript or {}
        self.scriptSketchMapInfo = self:AddPrefab("scriptSketchMapInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptSketchMapInfo._rootNode:setName("scriptSketchMapInfo")
        self.tbScript["scriptSketchMapInfo"] = self.scriptSketchMapInfo
    end
    self.scriptSketchMapInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipMiniAvatar(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nSub ~= EQUIPMENT_SUB.MINI_AVATAR then
        if self.scriptEquipMiniAvatar then
            self.scriptEquipMiniAvatar:OnEnter(tbInfo)
        end
        return
    end

    tbInfo[1] = " "
    tbInfo[2] = item.nRepresentID
    if not self.scriptEquipMiniAvatar then
        self.scriptEquipMiniAvatar = self:AddPrefab("scriptEquipMiniAvatar", PREFAB_ID.WidgetItemTipContent2)
        self.scriptEquipMiniAvatar._rootNode:setName("scriptEquipMiniAvatar")
        self.tbScript["scriptEquipMiniAvatar"] = self.scriptEquipMiniAvatar
    end
    self.scriptEquipMiniAvatar:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipRecommendAndExteriorInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipRecommendAndExteriorInfo then
            self.scriptEquipRecommendAndExteriorInfo:OnEnter(tbInfo)
        end
        return
    end

    local itemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
    local szTips = EquipData.GetEquipRecommendAndExteriorTip(itemInfo)
    if szTips ~= "" then
        tbInfo[1] = string.format("<color=#AFC1D4>%s</c>", szTips)
    end

    if not self.scriptEquipRecommendAndExteriorInfo then
        self.scriptEquipRecommendAndExteriorInfo = self:AddPrefab("scriptEquipRecommendAndExteriorInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipRecommendAndExteriorInfo"] = self.scriptEquipRecommendAndExteriorInfo
    end
    self.scriptEquipRecommendAndExteriorInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipRecommend(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipRecommend then
            self.scriptEquipRecommend:OnEnter(tbInfo)
        end
        return
    end

    local itemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
    local szTips = EquipData.GetEquipRecommendTip(itemInfo)
    if szTips ~= "" then
        tbInfo[1] = string.format("<color=#AFC1D4>%s</c>", szTips)
    end

    if not self.scriptEquipRecommend then
        self.scriptEquipRecommend = self:AddPrefab("scriptEquipRecommend", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipRecommend"] = self.scriptEquipRecommend
    end
    self.scriptEquipRecommend:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipExteriorInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT or ItemData.IsPendantItem(item) then
        if self.scriptEquipExterior then
            self.scriptEquipExterior:OnEnter(tbInfo)
        end
        return
    end

    local itemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
    local szTips = EquipData.GetExteriorTip(itemInfo)
    if szTips ~= "" then
        tbInfo[1] = string.format("<color=#AFC1D4>%s</c>", szTips)
    end

    if not self.scriptEquipExterior then
        self.scriptEquipExterior = self:AddPrefab("scriptEquipExterior", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipExterior"] = self.scriptEquipExterior
    end
    self.scriptEquipExterior:OnEnter(tbInfo)
end

function UIItemTip:UpdateEquipDisintegrateWarning(item)
    if not item then
        return
    end
    local tbInfo = {}
    local itemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
    if self.bItem and itemInfo and item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub ~= EQUIPMENT_SUB.PACKAGE and item.nSub ~= EQUIPMENT_SUB.HORSE
            and (not itemInfo.bCanBreak or not itemInfo.bCanTrade) then
        if not ItemData.IsPendantItem(itemInfo) then
            tbInfo[1] = string.format("<color=#FF4040>%s</c>", g_tStrings.STR_ITEM_H_CAN_NOT_BREAK1)
        end
    end

    if not self.scriptEquipDisintegrate then
        self.scriptEquipDisintegrate = self:AddPrefab("scriptEquipDisintegrate", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEquipDisintegrate"] = self.scriptEquipDisintegrate
    end
    self.scriptEquipDisintegrate:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemRequireInfo(item)
    if not item then
        return
    end
    local tbInfo = {}
    local szText = ""

    if self.szShopTip then
        szText = szText .. self.szShopTip
    end

    if self.nExpireTime then
        local nLeftTime = self.nExpireTime - os.time()
        if nLeftTime > 0 then
            local nDay = math.floor(nLeftTime / 3600 / 24)
            nLeftTime = nLeftTime - nDay * 3600 * 24
            local nHour = math.floor(nLeftTime / 3600)
            nLeftTime = nLeftTime - nHour * 3600
            local nMin = math.floor(nLeftTime / 60)
            nLeftTime = nLeftTime - nMin * 60
            local nSec = nLeftTime

            local szLeftTime = tostring(nDay) .. "天" .. tostring(nHour) .. "小时" .. tostring(nMin) .. "分钟" .. tostring(nSec) .. "秒后过期"
            szText = szText .. "<div><color=#FF7676>" .. szLeftTime .. "</c>"
        end
    end

    table.insert(tbInfo, szText)
    if not self.scriptItemRequireInfo then
        self.scriptItemRequireInfo = self:AddPrefab("scriptItemRequireInfo", PREFAB_ID.WidgetItemTipContent2)
        self.scriptItemRequireInfo._rootNode:setName("scriptItemRequireInfo")
        self.tbScript["scriptItemRequireInfo"] = self.scriptItemRequireInfo
    end

    self.scriptItemRequireInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateShopLimitInfo(item)
    if not item or not self.aShopInfo then
        return
    end
    local tbInfo = {}
    local aShopInfo = self.aShopInfo
    if not aShopInfo.bCustomLimit and aShopInfo.nGlobalLimt > 0 then
        tbInfo[1] = {
            szTitle = "全服限购",
            szText = string.format("<color=#FFFFFF>%d</c><color=#AED9E0>/%d</color>", aShopInfo.nBuyCount, aShopInfo.nGlobalLimt)
        }
    end
    if aShopInfo.bCustomLimit and aShopInfo.nGobalLimitCount > 0 then
        tbInfo[2] = {
            szTitle = "商店限量",
            szText = string.format("<color=#FFFFFF>%d</c>", aShopInfo.nGobalLimitCount)
        }
    end
    if aShopInfo.nPlayerBuyCount >= 0 then
        tbInfo[3] = {
            szTitle = "个人限购",
            szText = string.format("<color=#FFFFFF>%d</c><color=#AED9E0>/%d</color>", aShopInfo.nPlayerBuyCount, aShopInfo.nPlayerLimit)
        }
    end
    if not self.scriptShopLimitInfo then
        self.scriptShopLimitInfo = self:AddPrefab("scriptShopLimitInfo", PREFAB_ID.WidgetItemTipContent12)
        self.scriptShopLimitInfo._rootNode:setName("scriptShopLimitInfo")
        self.tbScript["scriptShopLimitInfo"] = self.scriptShopLimitInfo
    end

    self.scriptShopLimitInfo:OnEnter(tbInfo)
end

function UIItemTip:UpdateItemShareInfo(item)
    if not item or not self.bItem then
        return
    end
    local tbInfo = {}

    if item.bCanShared then
        local szTip = ""
        if item.nGenre == ITEM_GENRE.EQUIPMENT then
            szTip = string.format("<color=#95FF95>%s</c>", g_tStrings.STR_EQUIP_SHARE1)
        else
            szTip = string.format("<color=#95FF95>%s</c>", g_tStrings.STR_ITEM_SHARE1)
        end
        table.insert(tbInfo, szTip)
    end

    if not self.scriptItemShareInfo then
        self.scriptItemShareInfo = self:AddPrefab("scriptItemShareInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptItemShareInfo"] = self.scriptItemShareInfo
    end

    self.scriptItemShareInfo:OnEnter(tbInfo)
end

function UIItemTip:SetShopTips(szShopTip)
    self.szShopTip = szShopTip
end

function UIItemTip:SetShopInfo(aShopInfo)
    self.aShopInfo = aShopInfo
end

function UIItemTip:SetShopNeedCount(nShopNeedCount)
    self.nShopNeedCount = nShopNeedCount
end

function UIItemTip:SetExpireTime(nExpireTime)
    self.nExpireTime = nExpireTime
end

function UIItemTip:SetBtnState(tbBtnInfo)
    if self.nTabType == "CurrencyType" then
        return
    end
    local nBtnCount = #tbBtnInfo

    UIHelper.SetVisible(self.BtnFeature, false)
    UIHelper.SetVisible(self.Widget2Btns, false)
    UIHelper.SetVisible(self.Widget3Btns, false)
    UIHelper.SetVisible(self.WidgetCompare, self.bShowCompareEquipTip)

    if self.bShowCompareEquipTip then
        UIHelper.LayoutDoLayout(self.LayoutContentAll)
        return
    end

    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end

    local item = self:GetItem()
    if item and nBtnCount == 0 then
        local dwTabType = self.nTabType or item.dwTabType
        local dwIndex = self.nTabID or item.dwIndex
        if not self.bHidePreviewBtn then    --物品预览
            if OutFitPreviewData.CanPreview(dwTabType, dwIndex) then
                local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(dwTabType, dwIndex)
                if not table.is_empty(tbPreviewBtn) then
                    table.insert(tbBtnInfo, tbPreviewBtn[1])
                end
            end

            -- 宝箱奖励界面
            TreasureBoxData.GetPreviewBtn(tbBtnInfo, dwTabType, dwIndex)
        end

        -- -- 分享按钮
        -- table.insert(tbBtnInfo, { szName = g_tStrings.SEND_TO_CHAT, OnClick = function()
        --     Event.Dispatch(EventType.HideAllHoverTips)
        --     ChatHelper.SendToyBoxToChat(item.dwIndex)
        -- end })
    end


    self.scriptBtnList:OnEnter(tbBtnInfo)
    self:UpdateTipHeight()

    --[[    if nBtnCount == 1 then
            UIHelper.SetVisible(self.BtnFeature, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeature)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
        elseif nBtnCount == 2 then
            UIHelper.SetVisible(self.Widget2Btns, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeatureMain1)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
            local scriptBtn2 = UIHelper.GetBindScript(self.BtnFeatureSecondary1)
            scriptBtn2:OnEnter(tbBtnInfo[2].OnClick, tbBtnInfo[2].szName)
        elseif nBtnCount > 2 then
            UIHelper.SetVisible(self.Widget3Btns, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeatureMain2)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
            local scriptBtn2 = UIHelper.GetBindScript(self.BtnFeatureSecondary2)
            scriptBtn2:OnEnter(tbBtnInfo[2].OnClick, tbBtnInfo[2].szName)

            local tbMoreBtnInfo = Lib.copyTab(tbBtnInfo)
            table.remove(tbMoreBtnInfo, 1)
            table.remove(tbMoreBtnInfo, 1)

            if not self.scriptMoreBtnList then
                self.scriptMoreBtnList = UIHelper.AddPrefab(PREFAB_ID.WidgetTipMoreOper, self.WidgetMoreBtn)
            end

            self.scriptMoreBtnList:OnEnter(tbMoreBtnInfo)
        end
    --]]
    -- self:UpdateTipHeight()
end

function UIItemTip:UpdateBtnState(item)
    if not item then
        return
    end

    local dwItemID = item.dwID
    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end
    UIHelper.SetVisible(self.BtnFeature, false)
    UIHelper.SetVisible(self.Widget2Btns, false)
    UIHelper.SetVisible(self.Widget3Btns, false)
    UIHelper.SetVisible(self.WidgetCompare, self.bShowCompareEquipTip)
    UIHelper.SetVisible(self.WidgetOperation, false)
    UIHelper.SetVisible(self.WidgetAnchorQuantity, false)
    if self.bShowCompareEquipTip then
        return
    end

    if self.bShowReceiveEmailItemTip then
        return
    end

    if self.bForbidInitWithBtn then
        return
    end
    if self.scriptWidgetSellItem then
        UIHelper.RemoveFromParent(self.scriptWidgetSellItem._rootNode, true)
        self.scriptWidgetSellItem = nil
    end
    UIHelper.RemoveAllChildren(self.WidgetAnchorQuantity)
    if self.bShowPlacementBtn then
        UIHelper.SetVisible(self.WidgetAnchorQuantity, true)
        local placementScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipQuantityController_Placement, self.WidgetAnchorQuantity, self.nBox, self.nIndex, self.nCount, self.nCurCount)
        if self.fnPlacementCallback then
            placementScript:SetCallback(self.fnPlacementCallback)
        end
        UIHelper.LayoutDoLayout(self.LayoutContentAll)

        if self.szPlacementBtnText then
            placementScript:SetConfirmBtnText(self.szPlacementBtnText)
        end
        if self.szPlacementCountTitle then
            placementScript:SetCountTitleText(self.szPlacementCountTitle)
        end
        self.placementScript = placementScript
        return
    elseif self.bShowSplitWidget then
        UIHelper.SetVisible(self.WidgetAnchorQuantity, true)
        local splitScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipSplit, self.WidgetAnchorQuantity, self.nBox, self.nIndex)
        splitScript:SetCallback(function(bSplitOrCancel, nPreGroupNum, nGroupCount)
            if not bSplitOrCancel then
                self.bShowSplitWidget = false
                self:UpdateInfo(item)
                return
            end
            ItemData.SplitItem(self.nBox, self.nIndex, nPreGroupNum, nGroupCount)
        end)
        UIHelper.LayoutDoLayout(self.LayoutContentAll)
        return
    elseif self.bShowMulitUseWidget then
        local nTotleAmount = ItemData.GetItemAmountInPackage(item.dwTabType, item.dwIndex)
        UIHelper.SetVisible(self.WidgetAnchorQuantity, true)
        local mulitUseScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipQuantityController_Placement, self.WidgetAnchorQuantity, self.nBox, self.nIndex, nTotleAmount, nTotleAmount)
        mulitUseScript:SetCallback(function(nCurCount, nBox, nIndex)
            if item.nGenre ~= ITEM_GENRE.EQUIPMENT and
                    item.nGenre ~= ITEM_GENRE.TASK_ITEM and
                    BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem")
            then
                return
            end

            ItemData.MultiUse(nBox, nIndex, nCurCount)
            Event.Dispatch(EventType.HideAllHoverTips)
        end)

        if item.dwTabType == ITEM_TABLE_TYPE.HOMELAND then
            mulitUseScript:SetCountTitleText("储存数量：")
            mulitUseScript:SetConfirmBtnText("储存")
        else
            mulitUseScript:SetCountTitleText("使用数量：")
            mulitUseScript:SetConfirmBtnText("使用")
        end
        UIHelper.LayoutDoLayout(self.LayoutContentAll)
        return
    elseif self.bShowSellWidget then
        UIHelper.SetVisible(self.WidgetAnchorQuantity, true)
        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
        local nStackNum = ItemData.GetItemStackNum(item)
        self.scriptWidgetSellItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSellItemController, self.WidgetAnchorQuantity, 0, 1232, nBox, nIndex)
        UIHelper.LayoutDoLayout(self.WidgetAnchorQuantity)
        UIHelper.LayoutDoLayout(self.LayoutContentAll)
        -- self:SetFunctionButtons({})
        if self.scriptWidgetSellItem then
            self.scriptWidgetSellItem:SetSelectChangeCallback(function(nSellCount)
                ItemData.SellOutItem(item, dwItemID, nSellCount)
            end)
        end
        return
    end

    local tbBtnInfo = {}
    if self.tbFuncButtons then
        tbBtnInfo = self.tbFuncButtons
    else
        local bEquiped = self.nBox and self.nBox == 0
        if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub ~= EQUIPMENT_SUB.PACKAGE and self.bItem then
            if ItemData.IsBanUseItem(item) then
                table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                    ItemData.OnUseBanItem(self.nBox, self.nIndex)
                end })
            elseif ItemData.IsPendantItem(item) then
                table.insert(tbBtnInfo, { szName = "装备", OnClick = function()
                    ItemData.UsePendantItem(self.nBox, self.nIndex)
                end })
            elseif item.nSub == EQUIPMENT_SUB.PENDENT_PET then
                table.insert(tbBtnInfo, { szName = "装备", OnClick = function()
                    ItemData.UsePendantPetItem(self.nBox, self.nIndex)
                end })
            elseif self.nBox == INVENTORY_INDEX.EQUIP then
                -- 装备
                table.insert(tbBtnInfo, { szName = "替换", OnClick = function()
                    if PropsSort.IsBagInSort() then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                        return
                    end
                    Event.Dispatch(EventType.OnShowCharacterChangeEquipList, self.nBox, self.nIndex)
                end })--MINI_AVATAR
            elseif item.nSub == EQUIPMENT_SUB.HORSE or item.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
                --下面是丢弃装备，展开分享
                table.insert(tbBtnInfo, { szName = "装备", OnClick = function()
                    ItemData.EquipHorseOrHorseEquip(self.nBox, self.nIndex)
                end })
            elseif item.nSub == EQUIPMENT_SUB.MINI_AVATAR then
                --小头像tips
                table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                    ItemData.OnUseMiniAvatarItem(self.nBox, self.nIndex)
                end })
            elseif item.nSub == EQUIPMENT_SUB.PET then
                --宠物
                table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                    ItemData.OnUseFollowPetItem(self.nBox, self.nIndex)
                end })
            elseif item.nSub == EQUIPMENT_SUB.NAME_CARD_SKIN then
                --名帖挂件
                table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                    ItemData.OnUseNameCardSkinItem(self.nBox, self.nIndex)
                end })
            else
                local bIsMasterEquipMap = false
                local player = PlayerData.GetClientPlayer()
                if player then
                    local dwMapID = player.GetMapID()
                    bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
                end

                if not bIsMasterEquipMap then
                    local szBtn = "穿戴"
                    local bIsBullet = ItemData.IsTangMenBullet(item)
                    if ItemData.CheckEquipIndexHadEquipedWithItem(player, item) then
                        szBtn = "替换"
                    end

                    table.insert(tbBtnInfo, { szName = szBtn, OnClick = function()
                        if bIsBullet then
                            ItemData.StoreTangMenBullet(self.nBox, self.nIndex)
                        else
                            ItemData.EquipItem(self.nBox, self.nIndex)
                        end
                    end })
                end
            end

            if self:NotShowEquipRefine(item.nSub) and item.bCanDestroy and self.bItem then
                table.insert(tbBtnInfo, { szName = "丢弃", bNormalBtn = true, OnClick = function()
                    local discardItem = ItemData.GetItem(dwItemID)

                    if item.nQuality > 0 then
                        local bItemLocked = false
                        do
                            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                            local dwBoxType = g_pClientPlayer.GetBoxType(nBox)
                            if dwBoxType == INVENTORY_TYPE.BANK then
                                bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
                            end
                        end
                        if not bItemLocked then
                            bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy")
                        end
                        if bItemLocked then
                            return
                        end
                    end

                    local confirmDiscard = function(nCount)
                        local szConfirmContain = string.format(g_tStrings.tbItemString.DISCARD_ITEM_CONFIRM, UIHelper.GBKToUTF8(discardItem.szName))
                        local confirmDialog = UIHelper.ShowConfirm(szConfirmContain, function()
                            local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                            ItemData.DestroyItem(nBox, nIndex, nCount)
                        end, nil)

                        confirmDialog:SetButtonContent("Confirm", g_tStrings.tbItemString.DISCARD_ITEM_CONFIRM_DIALOG_BUTTON_NAME)
                    end

                    local nStackNum = ItemData.GetItemStackNum(item)
                    -- 吃鸡不确认全丢了
                    local bTreasureBF = BattleFieldData.IsInTreasureBattleFieldMap()
                    if bTreasureBF then
                        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                        ItemData.DestroyItem(nBox, nIndex, nStackNum)
                        return
                    end

                    if nStackNum > 1 then
                        self:ShowPlacementBtn(true, nStackNum, nStackNum, g_tStrings.STR_DISCARD, g_tStrings.STR_DISCARD_COUNT, confirmDiscard)
                        self:UpdateInfo(item)
                    else
                        confirmDiscard(nil)
                    end
                end })
            elseif not ItemData.IsPendantItem(item) and not ItemData.IsPendantPetSub(item.nSub) then
                local bIsMasterEquipMap = false
                local player = PlayerData.GetClientPlayer()
                if player then
                    local dwMapID = player.GetMapID()
                    bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
                end

                if not bIsMasterEquipMap then
                    table.insert(tbBtnInfo, { szName = "强化", OnClick = function()
                        if PlayerData.GetPlayerLevel() < 20 then
                            TipsHelper.ShowNormalTip("侠士达到20级后开启强化", false)
                            return
                        end

                        if PropsSort.IsBagInSort() then
                            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                            return
                        end

                        UIMgr.Open(VIEW_ID.PanelPowerUp, PREFAB_ID.WidgetEquipBarRefine, self.nBox, self.nIndex)
                    end })
                end
            end

            if self.nBox == INVENTORY_INDEX.EQUIP then
                table.insert(tbBtnInfo, { szName = "卸下", OnClick = function()
                    ItemData.UnEquipItem(self.nBox, self.nIndex)
                end })

                table.insert(tbBtnInfo, { szName = "推荐", OnClick = function()
                    local nEquipIndex = EQUIPMENT_INVENTORY.MELEE_WEAPON
                    if item then
                        nEquipIndex = self.nIndex or EquipData.GetEquipInventory(item.nSub, item.nDetail)
                    end
                    UIMgr.Open(VIEW_ID.PanelEquipCompare, EquipCompareType.Bag, true, {nBox = self.nBox, nIndex = self.nIndex}, true, nEquipIndex)
                end })

                local skill
                if item and item.dwSkillID and item.dwSkillID ~= 0 then
                    skill = GetSkill(item.dwSkillID, item.dwSkillLevel);
                end

                if skill then
                    local mode = skill.nCastMode
                    table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
                            return
                        end

                        ItemData.UseItemWithMode(self.nBox, self.nIndex, mode)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end })
                end
            elseif self.bItem and EquipData.CanBreak(self.nBox, self.nIndex) then
                table.insert(tbBtnInfo, { szName = "拆解", bNormalBtn = true, OnClick = function()
                    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
                        return
                    end

                    local player = PlayerData.GetClientPlayer()

                    if player.nLevel < 110 then
                        TipsHelper.ShowNormalTip("侠士达到110级后方可拆解装备")
                        return
                    end

                    local nNeedVigor =  GDAPI_BreakEquipCostVigor(1)
                    local nHaveVigor = GetPlayerVigorAndStamina(player)
                    local tbItemList = player.ShowBreakEquipProduct(self.nBox, self.nIndex)
                    local szNeedVigor = nNeedVigor >= nHaveVigor and string.format("<color=#FF0000>%d</color>", nNeedVigor) or string.format("<color=#FFFFFF>%d</color>", nNeedVigor)
                    local szConfirmContain = string.format(g_tStrings.tbItemString.BREAK_ITEM_CONFIRM, UIHelper.GBKToUTF8(item.szName), szNeedVigor)
                    local nBox, nIndex = self.nBox, self.nIndex
                    local confirmDialog = UIHelper.ShowConfirmWithItemList(szConfirmContain, tbItemList, function()
                        ItemData.BreakEquip(nBox, nIndex)
                    end)

                    confirmDialog:SetButtonContent("Confirm", g_tStrings.tbItemString.BREAK_ITEM_CONFIRM_DIALOG_BUTTON_NAME)

                end })
            end
        elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PACKAGE then
            -- 背包
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
                    return
                end
                -- local scriptBagUp = nil
                --if UIMgr.IsViewOpened(VIEW_ID.PanelBagUp2) then
                --    scriptBagUp = UIMgr.GetViewScript(VIEW_ID.PanelBagUp2)
                --    scriptBagUp:OnEnter(item.dwID)
                --else
                --    scriptBagUp = UIMgr.Open(VIEW_ID.PanelBagUp2, item.dwID)
                --    Event.Dispatch("ON_HIDEBOTTOMBTN")
                --end
                --
                --if scriptBagUp then
                --    scriptBagUp:ExchangPackage()
                --end
                Event.Dispatch("TRY_EXCHANGE_PACKAGE", item.dwID)

            end })
        elseif item.nGenre == ITEM_GENRE.BOOK and self.bItem then
            table.insert(tbBtnInfo, { szName = "阅读", OnClick = function()
                local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
                local nBookID, nSubID = GlobelRecipeID2BookID(item.nBookID)
                local scriptView = UIMgr.Open(VIEW_ID.PanelBookInfo, nBookID, nSubID, item.nBookID, item.dwID)
                scriptView:OnEnter(nBookID, nSubID, item.nBookID, item.dwID)
            end })
        elseif item.dwSkillID and item.dwSkillID ~= 0 and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                local useItem = ItemData.GetItem(dwItemID)
                local skill = GetSkill(useItem.dwSkillID, useItem.dwSkillLevel)
                if skill then
                    local nMode = skill.nCastMode
                    if nMode == SKILL_CAST_MODE.POINT_AREA or nMode == SKILL_CAST_MODE.POINT then
                        TipsHelper.ShowNormalTip(g_tStrings.USE_ITEM_IN_QUICK_USE_SKILL_SLOT)
                    elseif nMode == SKILL_CAST_MODE.ITEM then
                        if item.nGenre == ITEM_GENRE.ENCHANT_ITEM then
                            UIMgr.Open(VIEW_ID.PanelPowerUp, PREFAB_ID.WidgetEnchant, item)
                            return
                        end

                        local tbTargetItemList, bLevelImproveItem = ItemData.GetUseItemTargetItemList(nBox, nIndex)
                        tbTargetItemList = tbTargetItemList or {}
                        if #tbTargetItemList == 0 then
                            if bLevelImproveItem then
                                TipsHelper.ShowNormalTip("当前使用的装备和背包中未找到可使用的装备")
                                return
                            end
                        end
                        if self.funcUseItemToItem then
                            self.funcUseItemToItem(nBox, nIndex)
                        else
                            UIMgr.Open(VIEW_ID.PanelUseItemToItem, nBox, nIndex, function(dwTargetBox, dwTargetX)
                                ItemData.UseItemToItem(nBox, nIndex, dwTargetBox, dwTargetX)
                            end)
                        end
                    elseif nMode == SKILL_CAST_MODE.CASTER_SINGLE then
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                            return
                        end

                        ItemData.UseItem(nBox, nIndex)
                        UIMgr.Close(self)
                    else
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                            return
                        end

                        ItemData.UseItemWithMode(nBox, nIndex, nMode)
                        UIMgr.Close(self)
                    end
                end
            end })
        elseif item.nGenre == ITEM_GENRE.BOX and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end

                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                ItemData.UseBoxItem(nBox, nIndex)
            end })
        elseif item.nGenre == ITEM_GENRE.DESIGNATION and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end

                if not item.bBind then
                    local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
                    local szText = string.format("<color=%s>%s</c>", ItemQualityColor[item.nQuality], szItemName)
                    UIHelper.ShowConfirm(string.format(g_tStrings.STR_MSG_EQUIP_BIND_DESIGNATION_SURE, szText), function()
                        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                        ItemData.UseItem(nBox, nIndex)
                    end, nil, true)
                else
                    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                    ItemData.UseItem(nBox, nIndex)
                end
            end })
        elseif item.nGenre == ITEM_GENRE.DIAMOND and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if PlayerData.GetPlayerLevel() < 20 then
                    TipsHelper.ShowNormalTip("侠士达到20级后开启强化", false)
                    return
                end
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                UIMgr.Open(VIEW_ID.PanelPowerUp, PREFAB_ID.WidgetEquipBarRefine)
            end })
        elseif item.nGenre == ITEM_GENRE.COLOR_DIAMOND and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if PlayerData.GetPlayerLevel() < 20 then
                    TipsHelper.ShowNormalTip("侠士达到20级后开启强化", false)
                    return
                end
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                UIMgr.Open(VIEW_ID.PanelPowerUp, PREFAB_ID.WidgetFusionInsert, self.nBox, self.nIndex)
            end })
        elseif item.nGenre == ITEM_GENRE.HOMELAND and self.bItem then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end
                local dwMapID = g_pClientPlayer.GetMapID()
                if not HomelandData.IsHomelandMap(dwMapID) then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_FURNITURE_USE_ERROR)
                    return
                end
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end

                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                if ItemData.CanMultiUse(item) then
                    local item = self:GetItem()
                    self.bShowMulitUseWidget = true
                    self:OnInit(nBox, nIndex)
                    Event.Dispatch(EventType.OnClickMultUseBtn, self.nBox, self.nIndex)
                else
                    ItemData.OnUseFurnitureItem(nBox, nIndex)
                end
            end })
        elseif item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == MATERIAL_SUB_TYPE.SKILL_SKIN then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end

                local nIndex = self.bItem and item.dwIndex
                if CharacterSkillSkinData.GetSkinItemList()[nIndex] then
                    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                    ItemData.UseSkillSkin(nBox, nIndex)
                    return
                end

                UIHelper.ShowConfirm(g_tStrings.STR_SKILL_SKIN_USE_CONFIRM, function()
                    local player = GetClientPlayer()
                    if not player then
                        return
                    end
                    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                    ItemData.UseSkillSkin(nBox, nIndex)
                end)
            end })
        elseif item.nGenre == ITEM_GENRE.MATERIAL and item.nSub == MATERIAL_SUB_TYPE.SET then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                ShopData.RedirectToSetShop(item.dwTabType, item.dwIndex)
            end })
        elseif self.bItem and ItemData.CanMultiUse(item) then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                self.bShowMulitUseWidget = true
                self:OnInit(self.nBox, self.nIndex)
                Event.Dispatch(EventType.OnClickMultUseBtn, self.nBox, self.nIndex)
            end })
        elseif self.bItem and item.HasScript() then
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if item.nGenre ~= ITEM_GENRE.EQUIPMENT
                        and item.nGenre ~= ITEM_GENRE.TASK_ITEM
                        and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                    return
                end

                local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                local bHandleCub = self:OnHandleCubItem(item)
                if not bHandleCub then
                    if Table_GetItemCanMutiUse(item.nUiId) then
                        ItemData.MultiUse(nBox, nIndex, 1)
                    else
                        ItemData.UseItem(nBox, nIndex)
                    end
                    Event.Dispatch(EventType.HideAllHoverTips)
                end
            end })
        elseif self.bItem and IsJinXiuNiChangItem(item.dwTabType, item.dwIndex) then
            table.insert(tbBtnInfo, { szName = "兑换", OnClick = function()
                HuaELouData.Open(OPERACT_ID.BATTLE_PASS)
            end ,
            bNormalBtn = false,
            bFobidCheckBtnType = true,
            })
        elseif self.bItem and item.dwTabType == ITEM_TABLE_TYPE.OTHER and item.dwIndex == 71562 then
            -- VK特判补充烨阳焰晶（71562）的使用跳转橙色戒指系统商店按钮 新赛季直接维护到最新道具
            table.insert(tbBtnInfo, { szName = "使用", OnClick = function()
                if PropsSort.IsBagInSort() then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                    return
                end
                local player = GetClientPlayer()
                if not player then
                    return
                end
                if player.bFightState then  -- 因为是VK特判的，所以得山寨一下使用道具的处理
                    Global.OnUseItemRespond(USE_ITEM_RESULT_CODE.IN_FIGHT)
                    return
                end

                CampData.OnUseCampWeeklyItem()
            end})
        end

        if self.bItem and item.dwTabType == ITEM_TABLE_TYPE.OTHER and Const.MonsterBook.UpgradeSkillItemMap[item.dwIndex] then
            table.insert(tbBtnInfo, { szName = "收集", OnClick = function()
                UIMgr.Open(VIEW_ID.PanelBaizhanMain, 2)
            end})
        end

        if self.bItem and item.dwTabType == ITEM_TABLE_TYPE.OTHER and (item.dwIndex == 6058 or item.dwIndex == 6060) then
            -- VK特判年兽砸罐活动小银锤/小金锤（6058/6060）的新增自动砸罐按钮跳转到自动砸罐界面
            table.insert(tbBtnInfo, { szName = "自动砸罐", OnClick = function()
                UIMgr.Open(VIEW_ID.PanelNianShouTaobaoGuanSetting)
            end})
        end

        if item.bCanDestroy and not self:NotShowEquipRefine(item.nSub) and not bEquiped and self.bItem then
            --展开没有丢弃，放在强化的位置
            table.insert(tbBtnInfo, { szName = "丢弃", bNormalBtn = true, OnClick = function()
                local discardItem = ItemData.GetItem(dwItemID)

                if item.nQuality > 0 then
                    local bItemLocked = false
                    do
                        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                        local dwBoxType = g_pClientPlayer.GetBoxType(nBox)
                        if dwBoxType == INVENTORY_TYPE.BANK then
                            bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
                        end
                    end
                    if not bItemLocked then
                        bItemLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "destroy")
                    end
                    if bItemLocked then
                        return
                    end
                end

                local confirmDiscard = function(nCount)
                    local szConfirmContain = string.format(g_tStrings.tbItemString.DISCARD_ITEM_CONFIRM, UIHelper.GBKToUTF8(discardItem.szName))
                    local confirmDialog = UIHelper.ShowConfirm(szConfirmContain, function()
                        local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                        ItemData.DestroyItem(nBox, nIndex, nCount)
                    end, nil)

                    confirmDialog:SetButtonContent("Confirm", g_tStrings.tbItemString.DISCARD_ITEM_CONFIRM_DIALOG_BUTTON_NAME)
                end

                local nStackNum = ItemData.GetItemStackNum(item)
                 -- 吃鸡直接不确认全丢了
                local bTreasureBF = BattleFieldData.IsInTreasureBattleFieldMap()
                if bTreasureBF then
                    local nBox, nIndex = ItemData.GetItemPos(dwItemID)
                    ItemData.DestroyItem(nBox, nIndex, nStackNum)
                    return
                end

                if nStackNum > 1 then
                    self:ShowPlacementBtn(true, nStackNum, nStackNum, g_tStrings.STR_DISCARD, g_tStrings.STR_DISCARD_COUNT, confirmDiscard)
                    self:UpdateInfo(item)
                else
                    confirmDiscard(nil)
                end
            end })
        end

        if (ItemData.IsCanTimeReturnItem(item) or item.bCanTrade) and self.bItem and table.contain_value(ItemData.BoxSet.Bag, self.nBox) and self.bItem then
            table.insert(tbBtnInfo, { szName = "出售", bNormalBtn = true, OnClick = function()
                if g_pClientPlayer and g_pClientPlayer.bFightState then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SELL_IN_FIGHT, false)
                    return
                end

                OpenShopRequest(1232, 0)
                local discardItem = ItemData.GetItem(dwItemID)
                local itemName = ItemData.GetItemNameByItem(discardItem)
                itemName = UIHelper.GBKToUTF8(itemName)
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "sell") then
                    return
                end

                local nStackNum = ItemData.GetItemStackNum(item)
                if nStackNum > 1 then
                    self.bShowSellWidget = true
                    self:UpdateInfo(item)
                else
                    ItemData.SellOutItem(item, dwItemID, nStackNum)
                end
            end })
        end

        -- table.insert(tbBtnInfo, { szName = g_tStrings.SEND_TO_CHAT, OnClick = function()
        --     Event.Dispatch(EventType.HideAllHoverTips)
        --     ChatHelper.SendItemToChat(item.dwID)
        -- end })

        local nStackNum = self.bItem and ItemData.GetItemStackNum(item) or nil
        if nStackNum and nStackNum > 1 and self.nBox ~= INVENTORY_INDEX.EQUIP then
            table.insert(tbBtnInfo, { szName = "拆分", OnClick = function()
                self.bShowSplitWidget = true
                self:UpdateInfo(item)
            end })
        end

        if self.bItem then
            if not self.bHidePreviewBtn then    --物品预览
                if OutFitPreviewData.CanPreview(item.dwTabType, item.dwIndex) then
                    local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(item.dwTabType, item.dwIndex)
                    if not table.is_empty(tbPreviewBtn) then
                        table.insert(tbBtnInfo, tbPreviewBtn[1])
                    end
                end
            end

            if self.bShowAuctionSellBtn and self.bItem and TradingData.GetItemCanSell(self.nBox, self.nIndex) then
                if SystemOpen.IsSystemOpen(SystemOpenDef.TradingHouse, false) then
                    local tbSellingBtn = TradingData.GetAuctionSellingBtn(self.nBox, self.nIndex)
                    if not table.is_empty(tbSellingBtn) then
                        table.insert(tbBtnInfo, tbSellingBtn)
                    end
                end
            end
        end

        -- 宝箱奖励界面
        if not self.bHidePreviewBtn then
            local dwBoxTabType, dwBoxIndex
            if self.bItem then
                dwBoxTabType, dwBoxIndex = item.dwTabType, item.dwIndex
            else
                dwBoxTabType, dwBoxIndex = self.nTabType, self.nTabID
            end
            TreasureBoxData.GetPreviewBtn(tbBtnInfo, dwBoxTabType, dwBoxIndex)
        end

        if self.bItem and Table_GetEatingItem(item.dwTabType, item.dwIndex) then
            table.insert(tbBtnInfo, { szName = "五味诀", bNormalBtn = true, OnClick = function()
                UIMgr.Open(VIEW_ID.PanelWuWeiJuePop)
            end})
        end
    end

    ---@type UIItemTipBtnList
    self.scriptBtnList:OnEnter(tbBtnInfo)
    --尝试使用侧边栏按钮
    --[[local useBtnCount = #tbBtnInfo
        if useBtnCount == 1 then
            UIHelper.SetVisible(self.BtnFeature, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeature)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
        elseif useBtnCount == 2 then
            UIHelper.SetVisible(self.Widget2Btns, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeatureMain1)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
            local scriptBtn2 = UIHelper.GetBindScript(self.BtnFeatureSecondary1)
            scriptBtn2:OnEnter(tbBtnInfo[2].OnClick, tbBtnInfo[2].szName)
        elseif useBtnCount > 2 then
            UIHelper.SetVisible(self.Widget3Btns, true)
            local scriptBtn1 = UIHelper.GetBindScript(self.BtnFeatureMain2)
            scriptBtn1:OnEnter(tbBtnInfo[1].OnClick, tbBtnInfo[1].szName)
            local scriptBtn2 = UIHelper.GetBindScript(self.BtnFeatureSecondary2)
            scriptBtn2:OnEnter(tbBtnInfo[2].OnClick, tbBtnInfo[2].szName)

            local tbMoreBtnInfo = Lib.copyTab(tbBtnInfo)
            table.remove(tbMoreBtnInfo, 1)
            table.remove(tbMoreBtnInfo, 1)

            if not self.scriptMoreBtnList then
                self.scriptMoreBtnList = UIHelper.AddPrefab(PREFAB_ID.WidgetTipMoreOper, self.WidgetMoreBtn)
            end

            self.scriptMoreBtnList:OnEnter(tbMoreBtnInfo)
        end]]--
end

function UIItemTip:UpdateScrollGuild()
    local bCanSlide = UIHelper.GetScrollViewSlide(self.ScrollViewContent, _, SHOW_SCROLL_GUILD_CRITICAL_VALUE)
    self.bFirstSlide = self.bFirstSlide or true
    UIHelper.SetVisible(self.WidgetArrow, false)
    if self.tbArrowType then
        UIHelper.SetTabVisible(self.tbArrowType, false)

        if self.nScrollGuildArrowType and self.tbArrowType[self.nScrollGuildArrowType] then
            UIHelper.SetVisible(self.tbArrowType[self.nScrollGuildArrowType], true)
        else
            UIHelper.SetVisible(self.tbArrowType[1], true)
        end
    end

    if bCanSlide and self.bFirstSlide then
        UIHelper.SetVisible(self.WidgetArrow, true)
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
        UIHelper.BindUIEvent(self.ScrollViewContent, EventType.OnScrollingScrollView, function(_, eventType)
            -- local nScrollPercent = UIHelper.GetScrollPercent(self.ScrollViewContent)
            if eventType == ccui.ScrollviewEventType.scrollToBottom then
                UIHelper.SetVisible(self.WidgetArrow, false)
                self.bFirstSlide = false
            end
            UIHelper.UnBindUIEvent(self.ScrollViewContent, EventType.OnScrollingScrollView)
        end)
    end
end

function UIItemTip:SetScrollGuildArrowType(nType)
    self.nScrollGuildArrowType = nType
    self:UpdateScrollGuild()
end

function UIItemTip:EquipRingCheck()
    local bShowRingSwitch = false
    UIHelper.SetVisible(self.WidgetRingSwitch, false)
    if not self.bItem or not self.nBox or not self.nIndex or self.nBox ~= INVENTORY_INDEX.EQUIP then
        Event.Dispatch(EventType.OnItemTipSwitchRing, nil, nil)
        return bShowRingSwitch
    end
    local item = self:GetItem()
    if not item or item.nSub ~= EQUIPMENT_SUB.RING then
        return bShowRingSwitch
    end
    self.bShowRingSwitch = self.bShowRingSwitch or false

    local hAnotherRing  --item
    if self.nIndex == EQUIPMENT_INVENTORY.LEFT_RING then
        UIHelper.SetSelected(self.TogRing1, true)
        UIHelper.SetSelected(self.TogRing2, false)
        hAnotherRing = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RIGHT_RING)
    elseif self.nIndex == EQUIPMENT_INVENTORY.RIGHT_RING then
        UIHelper.SetSelected(self.TogRing2, true)
        UIHelper.SetSelected(self.TogRing1, false)
        hAnotherRing = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.LEFT_RING)
    end

    bShowRingSwitch = self.bShowRingSwitch and (not self.bCheckAnotherRing or not not hAnotherRing)
    UIHelper.SetVisible(self.WidgetRingSwitch, bShowRingSwitch)
    if not hAnotherRing then
        --用于更换戒指
        Event.Dispatch(EventType.OnItemTipSwitchRing, nil, nil)
    elseif not not hAnotherRing then
        -- 装备了另外一个戒指的情况
        Event.Dispatch(EventType.OnItemTipSwitchRing, self.nBox, self.nIndex)
    end

    return bShowRingSwitch
end

function UIItemTip:SetBeginSellTime(nBeginSellTime)
    self.nBeginSellTime = nBeginSellTime
    if nBeginSellTime == 0 then
        return
    end
    local date = os.date("*t", nBeginSellTime)
    local szMsg = date.year .. "年" .. date.month .. "月" .. date.day .. "日" .. date.hour .. "时" .. date.min .. "分开售"
    UIHelper.SetString(self.LabelCompare, szMsg)
    UIHelper.SetVisible(self.WidgetCompare, true)
end

function UIItemTip:SetComparePreviewLabel()
    local szText = "当前预览"
    UIHelper.SetString(self.LabelCompare, szText)
end

function UIItemTip:SetBookID(nBookID)
    self.nBookID = nBookID
end

function UIItemTip:ShowCompareEquipTip(bShow)
    if self.bShowCompareEquipTip == bShow then
        return
    end
    self.bShowCompareEquipTip = bShow
end

function UIItemTip:ShowAuctionSellBtn(bShow)
    self.bShowAuctionSellBtn = bShow
end

-- 试穿、宝箱奖励预览
function UIItemTip:HidePreviewBtn(bHide)
    self.bHidePreviewBtn = bHide
end

function UIItemTip:ShowPlacementBtn(bShow, nCount, nCurCount, szBtnText, szLabelCountTitle, fnPlacementCallback)
    self.bShowPlacementBtn = bShow
    self.nCount = nCount
    self.nCurCount = nCurCount
    self.szPlacementBtnText = szBtnText
    self.szPlacementCountTitle = szLabelCountTitle
    self.fnPlacementCallback = fnPlacementCallback
end

function UIItemTip:ShowSplitWidget(bShow)
    self.bShowSplitWidget = bShow
end

function UIItemTip:ShowMulitUseWidget(bShow)
    self.bShowMulitUseWidget = bShow
end

function UIItemTip:ShowSellWidget(bShow)
    self.bShowSellWidget = bShow
end

function UIItemTip:ShowReceiveEmailItemTip(bShow)
    self.bShowReceiveEmailItemTip = bShow
end

function UIItemTip:GetBindInfo(item)
    if not item then
        return
    end

    local szTips = g_tStrings.STR_ITEM_H_NOT_BIND
    if self.bItem and item.bBind then
        szTips = g_tStrings.STR_ITEM_H_HAS_BEEN_BIND
    else
        local itemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
        if itemInfo.nGenre == ITEM_GENRE.DESIGNATION then
            szTips = g_tStrings.DESGNATION_ITEM
        end
        if itemInfo.nGenre == ITEM_GENRE.TASK_ITEM then
            szTips = g_tStrings.STR_ITEM_H_QUEST_ITEM
        elseif itemInfo.nBindType == ITEM_BIND.INVALID then
        elseif itemInfo.nBindType == ITEM_BIND.NEVER_BIND then
        elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_EQUIPPED then
            szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_EQUIP
        elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_PICKED then
            szTips = g_tStrings.STR_ITEM_H_BIND_AFTER_PICK
        elseif itemInfo.nBindType == ITEM_BIND.BIND_ON_TIME_LIMITATION then
            szTips = g_tStrings.STR_ITEM_H_BIND_TIME_LIMITATION1
        end
    end

    return szTips
end

function UIItemTip:GetIgnoreBindMaskInfo(item)
    if not item then
        return
    end

    local szTips = ""

    if self.bItem then
        -- 绑定的特殊可交易物品
        if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.MENTOR) then
            local nLeftTime = item.GetLeftExistTime()
            nLeftTime = nLeftTime or 0
            if nLeftTime > 0 then
                szTips = string.pure_text(g_tStrings.STR_TRADE_MENTOR1)
            else
                szTips = string.pure_text(g_tStrings.STR_TRADE_MENTOR)
            end
        end

        if item.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.TONG) then
            local nLeftTime = item.GetLeftExistTime()
            nLeftTime = nLeftTime or 0
            if nLeftTime > 0 then
                szTips = string.pure_text(g_tStrings.STR_TRADE_TONG1)
            else
                szTips = string.pure_text(g_tStrings.STR_TRADE_TONG)
            end
        end
    end

    return szTips
end

--{{ szName = "使用", OnClick = function() end}}
function UIItemTip:SetFunctionButtons(tbFuncButtons)
    self.tbFuncButtons = tbFuncButtons
end

function UIItemTip:SetUseItemToItemCallback(funcUseItemToItem)
    self.funcUseItemToItem = funcUseItemToItem
end

-- 是否为挂件类型
function UIItemTip:IsExtendType(nSubType)
    if nSubType == EQUIPMENT_SUB.WAIST_EXTEND or
            nSubType == EQUIPMENT_SUB.BACK_EXTEND or
            nSubType == EQUIPMENT_SUB.FACE_EXTEND or
            nSubType == EQUIPMENT_SUB.L_SHOULDER_EXTEND or
            nSubType == EQUIPMENT_SUB.R_SHOULDER_EXTEND or
            nSubType == EQUIPMENT_SUB.BACK_CLOAK_EXTEND or
            nSubType == EQUIPMENT_SUB.GLASSES_EXTEND or
            nSubType == EQUIPMENT_SUB.L_GLOVE_EXTEND or
            nSubType == EQUIPMENT_SUB.R_GLOVE_EXTEND or
            nSubType == EQUIPMENT_SUB.PENDENT_PET or
            nSubType == EQUIPMENT_SUB.HEAD_EXTEND
            then
        return true
    end
    return false
end

function UIItemTip:NotShowEquipRefine(nSubType)
    if nSubType == EQUIPMENT_SUB.HORSE_EQUIP or
            nSubType == EQUIPMENT_SUB.HORSE or
            nSubType == EQUIPMENT_SUB.MINI_AVATAR or
            nSubType == EQUIPMENT_SUB.PET or
            nSubType == EQUIPMENT_SUB.NAME_CARD_SKIN then
        return true
    end

    return false
end

function UIItemTip:NotShowEquipStrength(nSubType)
    if nSubType == EQUIPMENT_SUB.ARROW or
            nSubType == EQUIPMENT_SUB.HORSE or
            nSubType == EQUIPMENT_SUB.PACKAGE then
        return true
    end

    return false
end

function UIItemTip:UpdateScrollViewHeight(fHeight)
    local fWidth = UIHelper.GetContentSize(self.ScrollViewContent)
    local innerContainer = self.ScrollViewContent:getInnerContainer()
    local nWidth, nHeight = UIHelper.GetContentSize(innerContainer)
    if nHeight < fHeight then
        self:AddScrollViewSeat(fHeight - nHeight)
    end
    UIHelper.SetContentSize(self.ScrollViewContent, fWidth, fHeight)
    UIHelper.LayoutDoLayout(self.LayoutContentAll)
    Timer.AddFrame(self, 1, function()
        self:UpdateWidgetBtnListHeight()
        UIHelper.WidgetFoceDoAlign(self)
    end)
end

function UIItemTip:UpdateWidgetBtnListHeight()
    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end
    local innerContainer = self.scriptBtnList.ScrollViewNegativeOp:getInnerContainer()

    local _, nHeight = UIHelper.GetContentSize(self.LayoutContentAll)
    local _, nUpListHeight = UIHelper.GetContentSize(innerContainer)
    local nListWidth = UIHelper.GetContentSize(self.scriptBtnList._rootNode)
    local nUpListWidth = UIHelper.GetContentSize(self.scriptBtnList.ScrollViewNegativeOp)
    -- local nBottomListWidth, nBottomListHeight = UIHelper.GetContentSize(self.scriptBtnList.ScrollViewCommonOp)
    UIHelper.SetContentSize(self.scriptBtnList._rootNode, nListWidth, nHeight)
    UIHelper.SetContentSize(self.scriptBtnList.ImgBgOp, nListWidth, nHeight)
    UIHelper.SetContentSize(self.scriptBtnList.ScrollViewNegativeOp, nUpListWidth, nUpListHeight)
    UIHelper.WidgetFoceDoAlign(self.scriptBtnList)
    UIHelper.CascadeDoLayoutDoWidget(self.scriptBtnList._rootNode, true, true)
end

function UIItemTip:UpdateTipHeight()
    if not self.scriptBtnList then
        self.scriptBtnList = UIHelper.GetBindScript(self.WidgetOperation)
    end

    if table_is_empty(UIHelper.GetChildren(self.WidgetAnchorQuantity)) then
        UIHelper.SetVisible(self.WidgetAnchorQuantity, false)
    end

    local nWidgetFixWidth = 0
    local bButtonGapIsAct = UIHelper.GetVisible(self.WidgetAnchorQuantity)

    if self.bIsPlayStore then
        --doNothing 商店界面不更新高度，其他界面对Itemtips有特殊规则的也可以设置bIsPlayStore
    elseif not self.bForbidAutoShortTip then
        --暂定有按钮操作时固定高度
        local fWidth = UIHelper.GetContentSize(self.ScrollViewContent)
        local innerContainer = self.ScrollViewContent:getInnerContainer()
        local nWidth, nHeight = UIHelper.GetContentSize(innerContainer)
        -- if UIHelper.GetVisible(self.WidgetOperation) then
            -- nHeight = math.max(nHeight, MIN_SCROLL_VIEW_HEIGHT)
        -- end
        if nHeight ~= 0 then
            -- local nMinHeight = MIN_SCROLL_VIEW_HEIGHT
            local nMinHeight = 0
            local nTopBtnCount, nBottomBtnCount= self.scriptBtnList:GetBtnCount()
            if nTopBtnCount and nTopBtnCount > 0 then
                nBottomBtnCount = nBottomBtnCount or 0
                nMinHeight = tbBtnCount2Height[nTopBtnCount][nBottomBtnCount]
                if nMinHeight and nMinHeight > nHeight then
                    self:AddScrollViewSeat(nMinHeight - nHeight)
                    nHeight = math.max(nHeight, nMinHeight)
                end
            end
            nHeight = math.min(nHeight, bButtonGapIsAct and MAX_SCROLL_VIEW_HEIGHT_HAVE_GAP or MAX_SCROLL_VIEW_HEIGHT_NOT_GAP)
            UIHelper.SetContentSize(self.ScrollViewContent, fWidth, nHeight)
            UIHelper.SetContentSize(self.WidgetArrowContent, fWidth, nHeight)
        end
        UIHelper.SetVisible(self.WidgetArrowContent, nHeight > 0)
        UIHelper.SetPaddingLayoutBottom(self.LayoutContentAll, nHeight > 0 and LAYOUT_PADDING_BOTTOM or 0)
    end
    UIHelper.SetTouchEnabled(self.LayoutContentAll, true)
    UIHelper.SetTouchDownHideTips(self.LayoutContentAll, false)

    UIHelper.LayoutDoLayout(self.WidgetTopContent)
    UIHelper.LayoutDoLayout(self.LayoutContentAll)
    UIHelper.LayoutDoLayout(self._rootNode)

    self:UpdateWidgetBtnListHeight()
    Timer.AddFrame(self, 1, function()
        if self._hoverTips and UIHelper.GetVisible(self.WidgetOperation) then
            local nBtnListWidth, _ = UIHelper.GetContentSize(self.WidgetOperation)
            nWidgetFixWidth = nBtnListWidth
        end

        local fWidth, nHeight = UIHelper.GetContentSize(self.LayoutContentAll)
        UIHelper.SetContentSize(self._rootNode, fWidth + nWidgetFixWidth, nHeight)
        UIHelper.SetContentSize(self.WidgetAnchorContent, fWidth, nHeight)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, false)
        UIHelper.WidgetFoceDoAlign(self)

        if self._hoverTips then
            self._hoverTips:SetNodeData()
            self._hoverTips:UpdatePosByNode()
        end
        self:UpdateScrollGuild()
        self:UpdateWidgetBtnListHeight()
    end)
end

function UIItemTip:UpdateCollectedInfo(item)
    local szCollected = ""
    local colorType = cc.c3b(0x86, 0XAE, 0XB4)
    UIHelper.SetVisible(self.LabelAttachStatus, false)

    if ItemData.IsPendantItem(item) then
        --挂件收集状态：已收集/未收集
        szCollected = ItemData.GetPendantOwnInfo(self.bItem and item or self.nTabID, self.bItem)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and ItemData.IsPendantPetItem(item) then
        --挂宠收集状态：已收集/未收集
        szCollected = ItemData.GetPendantPetCollectTip(self.bItem and item.dwIndex or self.nTabID)
    elseif item.nGenre == ITEM_GENRE.TOY then
        --玩具收集状态：已收集/未收集
        szCollected = ItemData.GetToyCollectTip(self.bItem and item.dwIndex or self.nTabID)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
        --宠物收集状态：已收集/未收集
        szCollected = ItemData.GetPetCollectTip(self.bItem and item.dwIndex or self.nTabID)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.HORSE then
        --坐骑饱食度
        szCollected, colorType = EquipData.GetHorseMeasureState(item, self.bItem)
    elseif item.nGenre == ITEM_GENRE.HOMELAND then
        --家具收集状态：已收集/未收集
		local nFurnitureType = item.nFurnitureType or HS_FURNITURE_TYPE.FURNITURE
        szCollected = _GetFurnitureCollectedInfo(nFurnitureType, item.dwFurnitureID)
    end

    if not string.is_nil(szCollected) then
        UIHelper.SetString(self.LabelAttachStatus, szCollected)
        UIHelper.SetTextColor(self.LabelAttachStatus, colorType)
        UIHelper.SetVisible(self.LabelAttachStatus, true)
        return true
    end
    return false
end

function UIItemTip:UpdateExistAmountInfo(item)
    if not item then
        return
    end
    if not self.scriptExistAmountInfo then
        self.scriptExistAmountInfo = self:AddPrefab("scriptExistAmountInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptExistAmountInfo"] = self.scriptExistAmountInfo
    end

    local tbInfo = {}
    local hItemInfo = self.bItem and ItemData.GetItemInfo(item.dwTabType, item.dwIndex) or item
    local szItemExistAmountTip = GetItemExistAmountTip(hItemInfo)---唯一性
    if not string.is_nil(szItemExistAmountTip) then
        tbInfo[1] = string.gsub(szItemExistAmountTip, "\n", "")
        self.scriptExistAmountInfo:OnEnter(tbInfo)
    else
        if self.scriptExistAmountInfo then
            self.scriptExistAmountInfo:OnEnter({})
        end
    end
end

function UIItemTip:ShowWareHouseSlider(nCount, nCurCount, szBtnText, szLabelCountTitle, fnPlacementCallback, tbFuncButtons)
    if nCount == 1 then
        self.tbFuncButtons = tbFuncButtons or {} -- 如果当前物品个数为1，则显示按钮而非进度条
        -- table.insert(self.tbFuncButtons, { szName = g_tStrings.SEND_TO_CHAT, OnClick = function()
        --     local item = self:GetItem()
        --     if self.bItem then
        --         ChatHelper.SendItemToChat(item.dwID)
        --     else
        --         ChatHelper.SendItemInfoToChat(nil, self.nTabType, self.nTabID)
        --     end
        --     Event.Dispatch(EventType.HideAllHoverTips)
        -- end })
        table.insert(self.tbFuncButtons, { szName = szBtnText, OnClick = function()
            if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
                TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
                return
            end
            fnPlacementCallback(1, self.nBox, self.nIndex)
        end })
    end
    self:ShowPlacementBtn(nCount ~= 1, nCount, nCurCount, szBtnText, szLabelCountTitle, fnPlacementCallback)
end

function UIItemTip:ShowWareHousePreviewSlider(dwTabType, dwIndex)
     if not self.bHidePreviewBtn and dwTabType and dwIndex and OutFitPreviewData.CanPreview(dwTabType, dwIndex) then
        local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(dwTabType, dwIndex)
        if not table.is_empty(tbPreviewBtn) then
            table.insert(self.tbFuncButtons, tbPreviewBtn[1])
        end
     end
end

function UIItemTip:UpdateEffectStackInfo(item)
    if not item then
        return
    end
    if not self.scriptEffectStackInfo then
        self.scriptEffectStackInfo = self:AddPrefab("scriptEffectStackInfo", PREFAB_ID.WidgetItemTipContent1)
        self.tbScript["scriptEffectStackInfo"] = self.scriptEffectStackInfo
    end

    local tbInfo = {}
    local szItemEffectStackTip
    if item.nGenre == ITEM_GENRE.POTION and (item.nSub == 2 or item.nSub == 3) then
        szItemEffectStackTip = "<color=#D7F6FF>" .. g_tStrings.UNABLE_TO_STACK_SIMILAR_EFFECT .. "</c>"
    elseif item.nGenre == ITEM_GENRE.FOOD and (item.nSub == 2 or item.nSub == 3) then
        szItemEffectStackTip = "<color=#D7F6FF>" .. g_tStrings.UNABLE_TO_STACK_SIMILAR_EFFECT .. "</c>"
    end
    if not string.is_nil(szItemEffectStackTip) then
        tbInfo[1] = szItemEffectStackTip
        self.scriptExistAmountInfo:OnEnter(tbInfo)
    else
        if self.scriptExistAmountInfo then
            self.scriptExistAmountInfo:OnEnter({})
        end
    end
end

function UIItemTip:GetWareHouseButton()
    return self.placementScript and self.placementScript.BtnConfirm or nil
end

function UIItemTip:ShowCompareBtnByType(item)
    if
    item.nSub == EQUIPMENT_SUB.AMULET or
            item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or -- "近身武器"
            item.nSub == EQUIPMENT_SUB.RANGE_WEAPON or -- "远程武器"
            item.nSub == EQUIPMENT_SUB.HELM or -- "帽子"
            item.nSub == EQUIPMENT_SUB.CHEST or -- "上衣"
            item.nSub == EQUIPMENT_SUB.WAIST or -- "腰带"
            item.nSub == EQUIPMENT_SUB.BANGLE or -- "护腕"
            item.nSub == EQUIPMENT_SUB.PANTS or -- "下装"
            item.nSub == EQUIPMENT_SUB.BOOTS or -- "鞋子"
            item.nSub == EQUIPMENT_SUB.AMULET or -- "项链"
            item.nSub == EQUIPMENT_SUB.PENDANT or -- "腰坠"
            item.nSub == EQUIPMENT_SUB.RING     -- "戒指"
    then
        return true
    else
        return false
    end
end

function UIItemTip:ShowRingSwitch(bShow, bCheckAnotherRing)
    if bCheckAnotherRing == nil then
        bCheckAnotherRing = true
    end

    self.bShowRingSwitch = bShow
    self.bCheckAnotherRing = bCheckAnotherRing
end

function UIItemTip:ShowCurEquipImg(bShow)
    if self.bItem and self.nBox == INVENTORY_INDEX.EQUIP then
        UIHelper.SetVisible(self.ImgCurrentEquip, bShow)
    end
end

function UIItemTip:SetPlayerID(nPlayerID)
    self.nPlayerID = nPlayerID
end

function UIItemTip:IsPlayStore(bIsPlayStore)
    self.bIsPlayStore = bIsPlayStore
end

function UIItemTip:SetForbidInitWithBtn(bForbidInitWithBtn)
    self.bForbidInitWithBtn = bForbidInitWithBtn
end

function UIItemTip:SetForbidAutoShortTip(bForbidAutoShortTip)
    self.bForbidAutoShortTip = bForbidAutoShortTip
    self:UpdateTipHeight()
end

function UIItemTip:SetForbidShowEquipCompareBtn(bForbid)
    self.bForbidShowEquipCompareBtn = bForbid
    self:UpdateBaseInfo()
end

function UIItemTip:SetForbidShowItemShare(bForbid)
    self.bForbidShowItemShareBtn = bForbid
    self:UpdateBaseInfo()
end

function UIItemTip:SetOnClickItemShare(fnOnClickItemShare)
    self.fnOnClickItemShare = fnOnClickItemShare
end

function UIItemTip:SetCustomizedSetEquipPowerUpInfo(tbPowerUpInfo)
    self.tbPowerUpInfo = tbPowerUpInfo
end

function UIItemTip:OnHandleCubItem(item)
    if item and item.nGenre == ITEM_GENRE.CUB then
        UIMgr.Open(VIEW_ID.PanelLifePage, {
            nDefaultCraftPanel = CRAFT_PANEL.Demosticate,
            dwDemesticateBox = self.nBox,
            dwDemesticateIndex = self.nIndex,
        })
        return true
    end
    return false
end

function UIItemTip:OnUpdateHorseAttribute(item)
    if not item then
        return
    end
    if item.nSub ~= EQUIPMENT_SUB.HORSE then
        return
    end
    local tAllAttr = {}
    local baseAttib, magicAttib,nRepresentID

    if self.bItem then
        baseAttib = item.GetBaseAttrib()
        magicAttib = item.GetMagicAttrib()
        nRepresentID = item.nRepresentID
    else
        baseAttib = item.GetHorseBaseAttribByFullLevel(FULL_LEVEL.FULL)
        magicAttib = item.GetHorseMagicAttribByFullLevel(FULL_LEVEL.FULL)
        nRepresentID = item.nRepresentID or 0
    end

    for _, v in pairs(baseAttib) do
        local nID = v.nID
        local nValue1 = v.nValue1 or v.nMin
        local nValue2 = v.nValue2 or v.nMax
        local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
        table.insert(tAllAttr, { dwID, dwLevel, nValue })
    end
    for _, v in pairs(magicAttib) do
        local nID = v.nID
        local nValue1 = v.nValue1 or v.Param0
        local nValue2 = v.nValue2 or v.Param2
        local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
        table.insert(tAllAttr, { dwID, dwLevel, nValue })
    end

    local szBaseAttrTips = ""
    for idx, tab in ipairs(tAllAttr) do
        local dwID, nLevel, nValue = tab[1], tab[2], tab[3]
        local tAttr = Table_GetHorseChildAttr(dwID, nLevel)
        if tAttr and tAttr.nType == 0 then
            tAttr.nValue = nValue
            tAttr.nLevel = nLevel
            if szBaseAttrTips == "" then
                szBaseAttrTips = self:OutputHorseChildAttrTip(tAttr)
            else
                szBaseAttrTips = szBaseAttrTips .. "\n" .. self:OutputHorseChildAttrTip(tAttr)
            end
        elseif tAttr and tAttr.nType == 1 then
            tAttr.nValue = nValue
            tAttr.nLevel = nLevel
            local szName, szAttrTips = self:OutputHorseChildAttrTip(tAttr, true)
            if not self["scriptHorseAttriContent" .. idx] then
                self["scriptHorseAttriContent" .. idx] = self:AddPrefab("scriptHorseAttriContent" .. idx, PREFAB_ID.WidgetLevelContent, szName, szAttrTips, tAttr.nIconID)
                self.tbScript["scriptHorseAttriContent" .. idx] = self["scriptHorseAttriContent" .. idx]
            end
            self["scriptHorseAttriContent" .. idx]:OnEnter(szName, szAttrTips, tAttr.nIconID)
            UIHelper.SetVisible(self["scriptHorseAttriContent" .. idx]._rootNode, true)
            UIHelper.LayoutDoLayout(self["scriptHorseAttriContent" .. idx]._rootNode)
        end
    end
    Timer.Add(self, 0.1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    end)
end

function UIItemTip:OutputHorseChildAttrTip(tAttr, bMagic)
    if not tAttr then
        return
    end
    local player = g_pClientPlayer
    if not player then
        return
    end
    if not bMagic then
        local szChildTip = UIHelper.GBKToUTF8(FormatString(tAttr.szTip, tAttr.nValue)) or ""
        if szChildTip ~= "" then
            szChildTip = string.match(szChildTip, '\".-\"')
            szChildTip = string.gsub(szChildTip, '\"', "")
        end
        return szChildTip
    elseif bMagic then
        local szName = UIHelper.GBKToUTF8(tAttr.szName)
        local szChildTip = UIHelper.GBKToUTF8(FormatString(tAttr.szTip, tAttr.nValue)) or ""
        local nLevel = tAttr.nLevel
        if szChildTip then
            szChildTip = string.match(szChildTip, '\".-\"')
            szChildTip = string.gsub(szChildTip, '\"', "")
        end
        return szName .. "  " .. nLevel .. "级", szChildTip
    end
end

function FromHMagicInfo_To_HSkill_ID_lv(dwMagicID, dwValue1, dwValue2,nRepresentID)
    local dwHSkillID
    local dwHSkilllv
    local dwHSkillValue

    if dwMagicID == ATTRIBUTE_TYPE.HORSE_ATTRIBUTE then
        --坐骑卡槽属性
        dwHSkillID = math.floor(dwValue2 / 1000)
        dwHSkilllv = math.floor(dwValue2 % 1000)
        if dwHSkillID == 4 or dwHSkillID == 5 or dwHSkillID == 6 or dwHSkillID == 12 or dwHSkillID == 13 or dwHSkillID == 29 then
            dwHSkilllv = 0
        end
    end
    --============================================================================================
    if dwMagicID == ATTRIBUTE_TYPE.MOVE_SPEED_PERCENT then
        --坐骑速度属性
        dwHSkillID = 1
        dwHSkilllv = math.floor(dwValue1 * 5 / 256 - 11 + 0.5)
        dwHSkillValue = math.floor(dwValue1 * 100 / 1024 + 0.5)
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end
    if dwMagicID == ATTRIBUTE_TYPE.ENABLE_DOUBLE_RIDE then
        --atEnableDoubleRide
        --能否双人同骑，value1值应该为1，value2没意义
        dwHSkillID = 3
        dwHSkilllv = 0
    end
    if dwMagicID == ATTRIBUTE_TYPE.HORSE_CAN_SWIM then
        --atHorseCanSwim
        --能否能凫水，value1值应该为1，value2没意义
        dwHSkillID = 2
        dwHSkilllv = 0
    end
    --============================================================================================
    if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_MAX then
        --atAddHorseSprintPowerMax
        --增加马术气力值最大值，value1增加的值，value2没意义
        --气力值属性最终值需除以100来还原。
        dwHSkillID = 7
        dwHSkilllv = math.floor((dwValue1 / 100 - 8) / 16)
        dwHSkillValue = math.floor(dwValue1 / 100)
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end
    if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_COST then
        --atAddHorseSprintPowerCost
        --增加马术气力值每帧消耗速率，value1增加的值，value2没意义
        --气力值属性最终值需除以100来还原。
        dwHSkillID = 9
        dwHSkilllv = math.abs(math.floor(dwValue1 * 16 / 100))
        dwHSkillValue = math.abs(math.floor(dwValue1 * 16 / 100))
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end
    if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_REVIVE then
        --atAddHorseSprintPowerRevive
        --增加马术气力值每帧恢复速率，value1增加的值，value2没意义
        --气力值属性最终值需除以100来还原。
        dwHSkillID = 8
        dwHSkilllv = math.floor(dwValue1 * 16 / 100)
        dwHSkillValue = math.floor(dwValue1 * 16 / 100)
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end

    if dwMagicID == ATTRIBUTE_TYPE.ADD_SPRINT_POWER_REVIVE then
        --atAddSprintPowerRevive
        --轻功气力值恢复速度，value1值应该为1，value2没意义
        dwHSkillID = 10
        dwHSkilllv = math.floor(dwValue1 * 16 / 100)
        dwHSkillValue = math.floor(dwValue1 * 16 / 100)
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end
    if dwMagicID == ATTRIBUTE_TYPE.DROP_DEFENCE then
        -- atDropDefence
        --抗摔伤系数
        dwHSkillID = 11
        dwHSkilllv = math.floor((dwValue1 - 110) / 35)
        dwHSkillValue = dwValue1
        if dwHSkilllv <= 0 then
            dwHSkilllv = 1
        end
    end
    --============================================================================================
    if dwHSkillValue then
        return dwHSkillID, dwHSkilllv, dwHSkillValue
    else
        if dwHSkillID == 14 then
			if nRepresentID == 362 or nRepresentID == 372 then
				dwHSkillID = 48
			end
		end
        return dwHSkillID, dwHSkilllv
    end
end

function UIItemTip:UpdateFishDealInfo(tbFishInfo, nMaxCount)
    if not self.scriptTopInfo then
        self.scriptTopInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent4, self.WidgetTopContent)
        UIHelper.SetVisible(self.scriptTopInfo.LabelType1, false)
        UIHelper.SetVisible(self.scriptTopInfo.LabelType2, false)
        UIHelper.SetVisible(self.scriptTopInfo.LabelType3, false)
        UIHelper.SetVisible(self.scriptTopInfo.WidgetRow3, false)
    end

    if not self.scriptNeedLevelInfo then
        self.scriptNeedLevelInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptDescInfo then
        self.scriptDescInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptSourceInfo then
        self.scriptSourceInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    if not self.scriptValueInfo then
        self.scriptValueInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent1, self.ScrollViewContent)
    end

    local szUse = "<color=#95FF95>"..UIHelper.GBKToUTF8(tbFishInfo.szUse).."</c>\n<color=#FFE26E>"..UIHelper.GBKToUTF8(tbFishInfo.szDesc).."</c>"
    local szNeedLevelTip = "<color=#D7F6FF>"..FormatString(g_tStrings.STR_HOMELAND_FISH_NEED_LEVEL, tbFishInfo.nIdenLv).."</c>"
    local szSourceTip = "<color=#D7F6FF>"..g_tStrings.STR_BOOK_TIP_GET_WAY1.."</c><color=#95FF95>"..UIHelper.GBKToUTF8(tbFishInfo.szRegion).."</c>"
    local szMoneyTip = ""
    if tbFishInfo.nMoney ~= 0 or tbFishInfo.nMeat ~= 0 or tbFishInfo.nArchitecture ~= 0 then
		szMoneyTip =  "<color=#D7F6FF>"..g_tStrings.STR_HOMELAND_FISH_PRICE.."</c>"
	end

	if tbFishInfo.nMoney ~= 0 then
		szMoneyTip = szMoneyTip .. UIHelper.GetMoneyText(tbFishInfo.nMoney, nil, nil, false)
	end

	if tbFishInfo.nArchitecture ~= 0 then
        local szArchitectureIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi"
		szMoneyTip = szMoneyTip..UIHelper.GetFundText(tbFishInfo.nArchitecture, 26, szArchitectureIcon)
	end

	if tbFishInfo.nMeat ~= 0 then
		szMoneyTip = szMoneyTip.." 或 ".."鱼肉X"..tbFishInfo.nMeat
	end

    UIHelper.SetString(self.scriptTopInfo.LabelNum1, nMaxCount)
    self.scriptDescInfo:OnEnter({szUse})
    self.scriptNeedLevelInfo:OnEnter({szNeedLevelTip})
    self.scriptSourceInfo:OnEnter({szSourceTip})
    self.scriptValueInfo:OnEnter({szMoneyTip})

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UIItemTip:UpdateRewardShopTip()
    if not self.tbGoods or not self.tbGoods.dwGoodsID then
        return
    end

    local tCardItem = Table_GetRewardsItem(self.tbGoods.dwGoodsID)
    if tCardItem and not string.is_nil(tCardItem.szTip) then
        local szRewardShopTips = UIHelper.GBKToUTF8(tCardItem.szTip)
        szRewardShopTips = ParseTextHelper.ParseNormalText(szRewardShopTips, false)
        szRewardShopTips = "<color=#FFE26E>"..szRewardShopTips.."</c>"
        if not self.scriptRewardShopTip then
            self.scriptRewardShopTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewContent)
            self.scriptRewardShopTip._rootNode:setName("scriptRewardShopTip")
        end
        self.scriptRewardShopTip:OnEnter({szRewardShopTips})
    end
end

function UIItemTip:AddScrollViewSeat(nHeight)  -- 填满至scrollview最小高度而加入的空白节点
    self.tbScript = self.tbScript or {}
    if self.scriptEmptySeat then
        UIHelper.RemoveFromParent(self.scriptEmptySeat._rootNode)
        self.scriptEmptySeat = nil
        self.tbScript["scriptEmptySeat"] = nil 
    end

    if not nHeight or nHeight <= 0 or self.bHideBackGround then
        return
    end
    self.scriptEmptySeat = self:AddPrefab("scriptEmptySeat", PREFAB_ID.WidgetItemTipContent2)
    self.scriptEmptySeat._rootNode:setName("scriptEmptySeat")
    self.tbScript["scriptEmptySeat"] = self.scriptEmptySeat

    local nWidth = UIHelper.GetContentSize(self.scriptEmptySeat._rootNode)
    UIHelper.SetVisible(self.scriptEmptySeat.RichTextAttri1, false)
    UIHelper.SetPaddingLayoutTop(self.scriptEmptySeat.LayoutContent1, nHeight)
    UIHelper.SetContentSize(self.scriptEmptySeat._rootNode, nWidth, 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

-- 主要是为了保证显示顺序正确的同时提高节点的复用
function UIItemTip:AddPrefab(szScript, nPrefabID, ...)
    if self.tbScript[szScript] and self.tbScript[szScript]._rootNode then
        self.ScrollViewContent:addChild(self.tbScript[szScript]._rootNode)
        if self.tbScript[szScript]._keepmt then
            self.tbScript[szScript]._keepmt = false
            self.tbScript[szScript]._rootNode:release()
        end
        return self.tbScript[szScript]
    else
        local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewContent, ...)
        return script
    end
end

function UIItemTip:RemoveAllChildren()
    for szScript, script in pairs(self.tbScript) do
        if self[szScript] and not self[szScript]._keepmt then
            self[szScript]._keepmt = true
            self[szScript]._rootNode:retain()
            self[szScript]._rootNode:removeFromParent(false)
            self[szScript] = nil
        end
    end
end

function UIItemTip:OnInitConductorMaterialsTip(nIndex, bRight)
    self.tbScript = self.tbScript or {}
    self.bItem = true
    self.bConductorMaterial = true

    local dwID = CommandBaseData.tGoodsInitSetting[nIndex].dwID
    local tInfo = CommandBaseData.tGoodsSetting[nIndex]
    local itemInfo = GetItemInfo(5, dwID)

    self:UpdateBaseInfo(itemInfo)
    self:UpdateItemDescInfo(itemInfo)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)

    UIHelper.BindUIEvent(self.BtnItemShare, EventType.OnClick, function()
        ChatHelper.SendItemInfoToChat(nil, 5, dwID)
        Event.Dispatch(EventType.HideAllHoverTips)
    end)

    local btnInfo = {}
    if bRight == true then
        btnInfo = {
            {
                szName = "购买",
                -- bDisabled = not tInfo.bCanBuy,
                OnClick = function()
                    UIMgr.Open(VIEW_ID.PanelBuyCampMaterialPop, nIndex, itemInfo)
                end
            },
            {
                szName = "分配",
                -- bDisabled = tInfo.nAllot >= tInfo.nBuy,
                OnClick = function()
                    UIMgr.Open(VIEW_ID.PanelAllotMaterialsPop, nIndex)
                end

            }
        }
    end

    self:SetBtnState(btnInfo)
end

function UIItemTip:OnInitSchoolSplitTip(nTabType, nTabID)
    self.nTabType = nTabType
    self.nTabID = nTabID
    self.bItem = false
    self.dwItemID = nil
    self.nBox = nil
    self.nIndex = nil
    self.dwEquipID = nil
    self.bAccountWareHouseItem = false

    self.tbScript = self.tbScript or {}

    local itemInfo = self:GetItem()
    self:SetBtnState({})
    self:RemoveAllChildren()
    self:UpdateBaseInfo(itemInfo)
    self:UpdateTopInfo(itemInfo)
    self:UpdateItemDescInfo(itemInfo)
    self:UpdateItemCoolDownInfo(itemInfo)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    self:UpdateTipHeight()
end

function UIItemTip:OnInitRoleAvatarTip(dwID, bIsDesignation)
    if not self.bInit then
        self.bInit = true
    end
    self.bItem = false

    local tInfo =  nil
    if bIsDesignation then
        tInfo = Table_GetDesignationDecorationInfo(dwID)
    else
        tInfo = Table_GetRoleAvatarInfo(dwID)
    end
    if not tInfo then
		return
	end

    UIHelper.SetVisible(self._rootNode, true)
    local szName = "称号装饰"
    if not bIsDesignation then
        if tInfo.dwForceID ~= 0 or dwID == 0 then
            szName = "门派头像"
        else
            szName = "江湖头像"
        end
    end
   
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, "")
    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 5)
    else
        self.scriptQualityBar:OnEnter(5)
    end

    UIHelper.SetSpriteFrame(self.ImgQuality, "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bg04.png")


    if bIsDesignation then
        if not self.scriptDecorationInfo then
            self.scriptDecorationInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetDecorationCell, self.WidgetTopContent)
            self.scriptDecorationInfo:Adjust(self.WidgetTopContent)
        end
        if self.scriptAvatarInfo then
            UIHelper.SetVisible(self.scriptAvatarInfo._rootNode, false)
        end
        self.scriptDecorationInfo:OnEnter(tInfo)
    else
        if not self.scriptAvatarInfo then
            self.scriptAvatarInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent, self.WidgetTopContent)
            UIHelper.SetNodeSwallowTouches(self.scriptAvatarInfo._rootNode, false, true)
            self.scriptAvatarInfo:OnlyShow()
        end
        if self.scriptDecorationInfo then
            UIHelper.SetVisible(self.scriptDecorationInfo._rootNode, false)
        end
        self.scriptAvatarInfo:OnEnter(dwID, tInfo, false)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    self:UpdateTipHeight()
end

function UIItemTip:OnInitSpecialRoleAvatarTip(dwID, nTabType, nTabID, bIsDesignation)

	self.nTabType = nTabType
    self.nTabID = nTabID
    self.bItem = false
    self.dwItemID = nil
    self.nBox = nil
    self.nIndex = nil
    self.dwEquipID = nil
    self.bAccountWareHouseItem = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
        UIHelper.SetTouchDownHideTips(self.BtnFeature, false)
    end

    self.tbScript = self.tbScript or {}
    self:RemoveAllChildren()

    local item = item or self:GetItem()
    local tInfo =  nil
    if bIsDesignation then
        tInfo = Table_GetDesignationDecorationInfo(dwID)
    else
        tInfo = Table_GetRoleAvatarInfo(dwID)
    end
    if not tInfo then
		return
	end

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelItemName, GetItemName(item, nil, false))
    UIHelper.ScrollViewDoLayout(self.ScrollviewName)
    UIHelper.ScrollToLeft(self.ScrollviewName, 0)
    UIHelper.SetString(self.LabelAttachStatus, "")
    if not self.scriptQualityBar then
        self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetPublicQualityBar, 5)
    else
        self.scriptQualityBar:OnEnter(5)
    end

    UIHelper.SetSpriteFrame(self.ImgQuality, "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bg04.png")

    if bIsDesignation then
        if not self.scriptDecorationInfo then
            self.scriptDecorationInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetDecorationCell, self.WidgetTopContent)
            self.scriptDecorationInfo:Adjust(self.WidgetTopContent)
        end
        if self.scriptAvatarInfo then
            UIHelper.SetVisible(self.scriptAvatarInfo._rootNode, false)
        end
        self.scriptDecorationInfo:OnEnter(tInfo)
    else
        if not self.scriptAvatarInfo then
            self.scriptAvatarInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent, self.WidgetTopContent)
            self.scriptAvatarInfo:OnlyShow()
            UIHelper.SetNodeSwallowTouches(self.scriptAvatarInfo._rootNode, false, true)
        end
        if self.scriptDecorationInfo then
            UIHelper.SetVisible(self.scriptDecorationInfo._rootNode, false)
        end
        self.scriptAvatarInfo:OnEnter(dwID, tInfo, false)
    end

    --获取途径
    self:RemoveAllChildren()
    self:UpdateItemSource(item)

    self:AddScrollViewSeat()
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    self:UpdateBtnState(item)
    self:UpdateTipHeight()

    UIHelper.SetVisible(self.WidgetMoreBtn, false)
    self:PlayAni()
end

function UIItemTip:UpdateYunShi(item)
    if not item then
        return
    end

    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = self.nTabType, self.nTabID
    end

    local nBoxID = TreasureBoxData.GetBoxIDByTab(dwTabType, dwIndex)
    if nBoxID and nBoxID < 8 then
        RemoteCallToServer("On_BoxOpenUI_GetBoxLuckyValue", nBoxID)
        return
    end
end


function UIItemTip:SetYunShi(item, nLuckyValue, nID)
    if not item then
        return
    end

    local dwTabType, dwIndex
    if self.bItem then
        dwTabType, dwIndex = item.dwTabType, item.dwIndex
    else
        dwTabType, dwIndex = self.nTabType, self.nTabID
    end

    local nBoxID = TreasureBoxData.GetBoxIDByTab(dwTabType, dwIndex)
    if nBoxID and nBoxID == nID then
        local tbInfo = {}
        tbInfo[1] = "运势值：" .. nLuckyValue
        if not self.scriptYunShiInfo then
            self.scriptYunShiInfo = self:AddPrefab("scriptYunShiInfo", PREFAB_ID.WidgetItemTipContent1)
            self.tbScript["scriptYunShiInfo"] = self.scriptYunShiInfo
        end
        self.scriptYunShiInfo:OnEnter(tbInfo)
    end
end

function UIItemTip:SetHideEquipBoxTipsInfo(bHide)
    self.bHideEquipBoxTipsInfo = bHide
end

function UIItemTip:BindItemShare(btn)
    if not btn then
        return
    end
    
    UIHelper.BindUIEvent(btn, EventType.OnClick, function()
        local item = self:GetItem()
        if self.fnOnClickItemShare then -- 目前没有用到，先留着
            self.fnOnClickItemShare(item)
            return
        end

        if self.dwItemID then
            item = GetItem(self.dwItemID)
            ChatHelper.SendItemInfoToChat(nil, item.dwTabType, item.dwIndex)
        elseif self.bItem then
            ChatHelper.SendItemToChat(item.dwID)
        elseif self.nBookID and self.nBookID > 0 then
            ChatHelper.SendBookToChat(self.nBookID)
        else
            ChatHelper.SendItemInfoToChat(nil, self.nTabType, self.nTabID)
        end
        Event.Dispatch(EventType.HideAllHoverTips)
    end)
end

function UIItemTip:GetSpecificContent()
    local tInfo ={
        szName = UIHelper.GetString(self.LabelItemName),
        szCollected = UIHelper.GetVisible(self.LabelAttachStatus) and UIHelper.GetString(self.LabelAttachStatus) or "",
    }
    return tInfo
end

function UIItemTip:HideAllBackground()
    UIHelper.SetVisible(self.ImgQuality, false)
    UIHelper.SetVisible(self.WidgetPublicQualityBar, false)
    UIHelper.SetVisible(self.ScrollviewName, false)
    UIHelper.SetVisible(self.LayoutRight, false)
    UIHelper.SetVisible(self.WidgetItemIcon, false)

    self.bHideBackGround = true
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, true)
    self.LayoutContentAll:removeBackGroundImage()
end

function UIItemTip:HideSource()
    for szScript, script in pairs(self.tbScript) do
        if self[szScript] then
            local root = self[szScript]._rootNode
            local firstLayerChild = UIHelper.GetChildren(root)
            for _, node in ipairs(firstLayerChild) do
                if node.removeBackGroundImage then
                    node:removeBackGroundImage() -- 去除底图
                end
            end
        end
    end
    
    if self.scriptItemSourceInfo and UIHelper.GetVisible(self.scriptItemSourceInfo._rootNode) then
        UIHelper.SetVisible(self.scriptItemSourceInfo._rootNode, false)
    end

    if self.scriptBookSourceInfo and UIHelper.GetVisible(self.scriptBookSourceInfo._rootNode) then
        UIHelper.SetVisible(self.scriptBookSourceInfo._rootNode, false)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContentAll, true, false)
end

return UIItemTip