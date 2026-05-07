-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationImportExteriorPop
-- Date: 2025-10-12 16:11:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0,
    nOffsetY = 0,
    nOffsetZ = 0,
    fRotationX = 0,
    fRotationY = 0,
    fRotationZ = 0,
}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(tExterior)
    if tExterior then
        DataModel.tExteriorID = tExterior.tExteriorID
        DataModel.tDetail = tExterior.tDetail
    end

    DataModel.tSortData = ShareExteriorData.GetSortDataByExteriorData(tExterior)
end

function DataModel.UnInit()
    DataModel.tExteriorID = nil
    DataModel.tDetail = nil
    DataModel.tSortData = nil
end

function DataModel.IsInExteriorBoxList(tList, tExteriorBox)
    local bInList = false
    local eGoodsType = tExteriorBox.eGoodsType
    local nItemType = tExteriorBox.nItemType
    local dwItemIndex = tExteriorBox.dwItemIndex

    for _, v in ipairs(tList) do
        if v.eGoodsType == eGoodsType and v.nItemType == nItemType and v.dwItemIndex == dwItemIndex then
            bInList = true
            break
        end
    end
    
    return bInList
end

--是否包含礼盒类外观
function DataModel.GetPackTipFlag(tSortData)
    for nSort = SHARE_TERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        for _, v in ipairs(tSortData[nSort]) do
            if v.bPackItem then
                return true
            end
        end
    end
    return false
end
-----------------------------DataModel------------------------------

local UIShareStationImportExteriorPop = class("UIShareStationImportExteriorPop")

function UIShareStationImportExteriorPop:OnEnter(tExterior)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitDressUpList()
    DataModel.Init(tExterior)

    self:UpdateInfo()
end

function UIShareStationImportExteriorPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationImportExteriorPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        self:ApplyExterior()
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
        UIMgr.Close(self)
    end)
end

function UIShareStationImportExteriorPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShareStationImportExteriorPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationImportExteriorPop:InitDressUpList()
    self.tbDressUpWidget = {}
    self.tbDressUpItemLayout = {}
    self.tbDressUpToggle = {}

    for nSort = SHARE_EXTERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationDressUpCell, self.ScrollViewItemList)

        local szTitle = g_tStrings.STR_EXTERIOR_SHOP_STATE_TEXT[nSort]
        local szWarn = g_tStrings.STR_EXTERIOR_SHOP_STATE_TEXT_WARNING[nSort]
        if szWarn then
            UIHelper.SetVisible(script.WidgetWarn, true)
            UIHelper.SetRichText(script.LabelWarn, szWarn)
        end
        UIHelper.SetLabel(script.LabelTitle, szTitle)
        UIHelper.SetVisible(script.WidgetFlag, nSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_BIND or nSort == SHARE_EXTERIOR_SHOP_STATE.IN_BAG_UNBIND)
        self.tbDressUpWidget[nSort] = script._rootNode
        self.tbDressUpItemLayout[nSort] = script.LayoutCell
        self.tbDressUpToggle[nSort] = script.ToggleCell
    end

    for nSort, tog in ipairs(self.tbDressUpToggle) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(tog, bSelected)
            if not self.tbScriptExteriorItem then
                return
            end

            local tbItemScript = self.tbScriptExteriorItem[nSort] or {}
            for _, script in ipairs(tbItemScript) do
                UIHelper.SetSelected(script.ToggleSelect, bSelected, false)
                Timer.AddFrame(self, 1, function()
                    self:UpdateApplyBtnState()
                end)
            end
        end)
    end
end

function UIShareStationImportExteriorPop:UpdateInfo()
    self:UpdateExterior()
    self:UpdateApplyBtnState()
end

function UIShareStationImportExteriorPop:UpdateExterior()
    local tDetail = DataModel.tDetail
    local tSortData = DataModel.tSortData
    self.tbScriptExteriorItem = {}

    local tNotRepeatData = {}
    for nSort = SHARE_EXTERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        tNotRepeatData[nSort] = {}
        for _, v in ipairs(tSortData[nSort]) do
            local eGoodsType = v.eGoodsType
            local nItemType = v.nItemType
            local dwItemIndex = v.dwItemIndex
            
            --只有礼盒类道具需要判重
            if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and ShareExteriorData.IsPackExteriorItem(nItemType, dwItemIndex) then
                v.bPackItem = true
                if not DataModel.IsInExteriorBoxList(tNotRepeatData[nSort], v) then
                    table.insert(tNotRepeatData[nSort], v)
                end
            else
                table.insert(tNotRepeatData[nSort], v)
            end
        end
    end
    tSortData = tNotRepeatData

    for nSort = SHARE_EXTERIOR_SHOP_STATE.HAVE, SHARE_EXTERIOR_SHOP_STATE.OTHER do
        local tBoxList = tSortData[nSort]
        local widget = self.tbDressUpWidget[nSort]
        local layout = self.tbDressUpItemLayout[nSort]
        if #tBoxList > 0 then
            self.tbScriptExteriorItem[nSort] = {}
            UIHelper.RemoveAllChildren(layout)
            for _, tExteriorBox in ipairs(tBoxList) do
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, layout)
                script:SetToggleSwallowTouches(false)
                self:UpdateExteriorItem(script, tExteriorBox, tDetail, nSort)
                table.insert(self.tbScriptExteriorItem[nSort], script)
            end
            UIHelper.SetVisible(widget, true)
            UIHelper.SetVisible(layout, true)
            UIHelper.LayoutDoLayout(layout)
        else
            UIHelper.SetVisible(widget, false)
            UIHelper.SetVisible(layout, false)
        end
        UIHelper.SetSelected(self.tbDressUpToggle[nSort], true, false)
        if nSort == SHARE_EXTERIOR_SHOP_STATE.OTHER then
            UIHelper.SetNodeGray(widget, true, true)
            UIHelper.SetEnable(widget, false)
        end
    end

    UIHelper.SetSelected(self.tbDressUpToggle[SHARE_EXTERIOR_SHOP_STATE.OTHER], false, false)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewItemList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItemList)
end

local function IsOtherSchoolExterior(dwID, eGoodsType, nSort)
    local bOtherSchool = false
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return bOtherSchool
    end

    -- 非已拥有的外装/武器，检查是否非本门派
    if nSort ~= SHARE_EXTERIOR_SHOP_STATE.HAVE then
        if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then -- 校服
            local tInfo = GetExterior().GetExteriorInfo(dwID)
            if tInfo and tInfo.nGenre == EXTERIOR_GENRE.SCHOOL and tInfo.nForceID ~= pPlayer.dwForceID then
                bOtherSchool = true
            end
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
            local tInfo = CoinShop_GetWeaponExteriorInfo(dwID)
            local nForceMask = tInfo and tInfo.nForceMask or 0
            if nForceMask > 0 then
                bOtherSchool = not GetNumberBit(nForceMask, pPlayer.dwBitOPForceID + 1)
            end
        end
    end
    return bOtherSchool
end

local function IsCustomized(tDetail, nSub)
    if not nSub then
        return false
    end

    local tSubDetail = tDetail and tDetail[nSub]
    if not tSubDetail then
        return false
    end

    local bIsCustomized = false -- 自定义位置
    local bHideBackClock = false
    local bHaveColor = false -- 染色标记
    local bHasCustomData = false -- 是否有自定义数据

    if tSubDetail.tCustomData then
        local tCustomData = tSubDetail.tCustomData
        bHasCustomData = not IsTableEqual(tCustomData, DEFAULT_CUSTOM_DATA)
        bIsCustomized = bHasCustomData
    end

    if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND and tSubDetail then
        bHideBackClock = tSubDetail.bVisible == true
    end

    if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
        local nDyeingID = tSubDetail.nNowDyeingID
        bHaveColor = nDyeingID and nDyeingID > 0
    -- elseif nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then -- 披风
    --     local tColorID = tSubDetail.tColorID or {}
    --     local bDyeing = false
    --     for _, nColorID in pairs(tColorID) do
    --         if nColorID > 0 then
    --             bDyeing = true
    --             bHaveColor = true
    --             break
    --         end
    --     end
    end

    return bIsCustomized, bHideBackClock, bHaveColor, bHasCustomData
end

local function IsColorDye(nSub, tSubDetail)
    local bColorDye = false
    if not nSub or not tSubDetail then
        return false
    end

    -- 染色标记
    if nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
        local nDyeingID = tSubDetail.nNowDyeingID
        bColorDye = nDyeingID and nDyeingID > 0
    elseif nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then -- 披风
        local tColorID = tSubDetail.tColorID or {}
        local bDyeing = false
        for _, nColorID in pairs(tColorID) do
            if nColorID > 0 then
                bDyeing = true
                break
            end
        end
        bColorDye = bDyeing
    elseif nSub == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
        local tDyeingData = tSubDetail.tDyeingData
        if tDyeingData then
            bColorDye = true
        end
    end

    return bColorDye
end

local function IsCut(tSubDetail)
    return tSubDetail and tSubDetail.nFlag and tSubDetail.nFlag > 0 
end

function UIShareStationImportExteriorPop:UpdateExteriorItem(script, tExteriorBox, tDetail, nSort)
    local dwID = tExteriorBox.dwID
    local eGoodsType = tExteriorBox.eGoodsType
    local nItemType = tExteriorBox.nItemType
    local dwItemIndex = tExteriorBox.dwItemIndex
    local bEffect = tExteriorBox.bEffect
    local nSub = tExteriorBox.nSub
    local bIsCustomized, bHideBackClock, bHaveColor, bHasCustomData = IsCustomized(tDetail, nSub)
    local bOtherSchool = IsOtherSchoolExterior(dwID, eGoodsType, nSort)
    local bColorDye = IsColorDye(nSub, tDetail[nSub])
    local bCut = IsCut(tDetail[nSub])
    local bHave = nSort == SHARE_EXTERIOR_SHOP_STATE.HAVE
    local bHide = false

    -- 披风隐藏开关
    if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        bHide = tDetail[nSub] and not tDetail[nSub].bVisible
    end

    script.tExteriorBox = tExteriorBox
    script.bOtherSchool = bOtherSchool
    script.bIsCustomized = bIsCustomized
    script.bColorDye = bColorDye
    script.nSort = nSort
    script.nSub = nSub

    if bEffect then --称号特效
        if nItemType and dwItemIndex then
            script:OnInitWithTabID(nItemType, dwItemIndex)
        else
            script:OnInitWithIconID(1241, 5, 1)
        end
    elseif eGoodsType then
        if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then -- 发型
            script:OnInitWithIconID(10775, 2, 1)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then -- 【成衣】或【外装收集部位】
            script:OnInitWithTabID("EquipExterior", dwID)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then -- 武器
            script:OnInitWithTabID("WeaponExterior", dwID)
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then -- 挂宠/普通挂件/其他道具
            script:OnInitWithTabID(nItemType, dwItemIndex)
        end
    end

    local scriptIcon = script.WidgetExteriorIcons and UIHelper.GetBindScript(script.WidgetExteriorIcons)
    if scriptIcon then
        UIHelper.SetVisible(scriptIcon.ImgHide, bHide)
        UIHelper.SetVisible(scriptIcon.ImgOtherSchool, bOtherSchool)

        UIHelper.SetVisible(scriptIcon.ImgCut, bCut and bHave)
        UIHelper.SetVisible(scriptIcon.ImgDye, bColorDye and bHave)
        UIHelper.SetVisible(scriptIcon.ImgDyeHat, bHaveColor and bHave)
        UIHelper.SetVisible(scriptIcon.ImgCustom, bIsCustomized and bHave)
        UIHelper.SetVisible(scriptIcon.ImgCutDisable, bCut and not bHave)
        UIHelper.SetVisible(scriptIcon.ImgDyeDisable, bColorDye and not bHave)
        UIHelper.SetVisible(scriptIcon.ImgDyeHatDisable, bHaveColor and not bHave)
        UIHelper.SetVisible(scriptIcon.ImgCustomDisable, bHasCustomData and not bHave)

        UIHelper.SetVisible(scriptIcon._rootNode, true)
        UIHelper.LayoutDoLayout(scriptIcon._rootNode)
        UIHelper.SetVisible(scriptIcon.ImgExteriorIconHide, bHideBackClock) -- 不在WidgetExteriorIcon里面，不需要一起doLayout
    end

    script:SetSelected(nSort ~= SHARE_EXTERIOR_SHOP_STATE.OTHER)
    script:SetSelectChangeCallback(function(_, bSelected)
        local tbGoods = {
            eGoodsType = eGoodsType,
            dwGoodsID = dwID,
            dwTabType = nItemType,
            dwTabIndex = dwItemIndex,
        }

        Timer.AddFrame(self, 1, function()
            self:UpdateApplyBtnState()
        end)
        if bEffect then
            local _, scriptTips = TipsHelper.ShowItemTips(script._rootNode, "Effect", dwID, false)
            scriptTips:SetBtnState({})
            return
        end

        CoinShopPreview.InitItemTips(tbGoods, nil, script._rootNode)
    end)
end

function UIShareStationImportExteriorPop:ApplyExterior()
    if not self.tbScriptExteriorItem then
        return
    end

    FireUIEvent("COINSHOP_INIT_ROLE", true, true)
    -- 如果导入的数据包含头饰，为避免数据重复，需要先清空所有头饰
    local tHeadPendantSub = ShareExteriorData.GetHeadPendantResSub()
    local bHeadPendant = false
    for _, tbScript in ipairs(self.tbScriptExteriorItem) do
        for k, scriptItem in pairs(tbScript) do
            local tExteriorBox = scriptItem.tExteriorBox
            if table.contain_value(tHeadPendantSub, tExteriorBox.nSub) then
                bHeadPendant = true
                break
            end
        end
    end
    if bHeadPendant then
        for _, nHeadSub in ipairs(tHeadPendantSub) do
            ExteriorCharacter.ClearPendant(nHeadSub)
        end
        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
    end

    for nSort, tbScript in pairs(self.tbScriptExteriorItem) do
        for _, scriptItem in ipairs(tbScript) do
            local bApply = false
            bApply = scriptItem:GetSelected()

            if bApply then
                local nSort = scriptItem.nSort
                local tExteriorBox = scriptItem.tExteriorBox
                local bIsCustomized = scriptItem.bIsCustomized

                local dwID = tExteriorBox.dwID
                local eGoodsType = tExteriorBox.eGoodsType
                local nItemType = tExteriorBox.nItemType
                local dwItemIndex = tExteriorBox.dwItemIndex
                if nSort == SHARE_EXTERIOR_SHOP_STATE.HAVE then --只有已拥有的挂件/挂宠才允许不在商城售卖也能切换
                    self:ApplyHaveExterior(tExteriorBox, bIsCustomized)
                    Timer.Add(ShareExteriorData, 0.1, function()
                        FireUIEvent("COINSHOP_UPDATE_ROLE")
                    end)
                elseif eGoodsType and nSort ~= SHARE_EXTERIOR_SHOP_STATE.OTHER then
                    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
                        local tGoods = Table_GetRewardsGoodItem(nItemType, dwItemIndex)
                        if tGoods then
                            CoinShop_PreviewGoods(eGoodsType, tGoods.dwLogicID, true)
                        end
                    elseif dwID then --发型/外装/武器
                        CoinShop_PreviewGoods(eGoodsType, dwID, true)
                    end
                end
            end
        end
    end
end

function UIShareStationImportExteriorPop:ApplyHaveExterior(tExteriorBox, bIsCustomized)
    local pPlayer = GetClientPlayer()
    if not pPlayer then 
        return
    end

    local nSub = tExteriorBox.nSub
    local dwID = tExteriorBox.dwID
    local eGoodsType = tExteriorBox.eGoodsType
    local nItemType = tExteriorBox.nItemType
    local dwItemIndex = tExteriorBox.dwItemIndex
    local bEffect = tExteriorBox.bEffect
    local tSubDetail = DataModel.tDetail and DataModel.tDetail[nSub] or {}

    if bEffect then --称号特效
        if not pPlayer.IsEquipSFX(dwID) then
            pPlayer.SetCurrentSFX(dwID)
        end

        --应用特效自定义
        local tCustomData = tSubDetail and tSubDetail.tCustomData
        if not tCustomData or not bIsCustomized then
            tCustomData = ShareExteriorData.GetDefaultSFXCustomData(dwID)
        end
        local nEffectType = CharacterEffectData.GetLogicTypeByEffectType(nSub)
        if tCustomData then
            if nEffectType then
                pPlayer.SetEquipCustomSFXData(nEffectType, tCustomData)
            end
        end

        if nEffectType then
            FireUIEvent("PREVIEW_PENDANT_EFFECT_SFX", nEffectType, dwID)
            ExteriorCharacter.UpdateEffectPos(CoinShopEffectCustom.nType)
        end
    elseif eGoodsType then
        if nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND1 or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND2 then
            local tItem = {
                dwTabType = nItemType,
                dwIndex = dwItemIndex,
                tColorID = tSubDetail.tColorID
            }
            local tCustomData = tSubDetail and tSubDetail.tCustomData
            if not tCustomData or not bIsCustomized then
                tCustomData = ShareExteriorData.GetDefaultPendantCustomData(nSub, dwItemIndex)
            end
            if tCustomData then
                self:ApplyPendantCustom(nSub, tCustomData, dwItemIndex)
                local nPos = CoinShop_RepresentSubToPendantPos(nSub)
                FireUIEvent("PREVIEW_PENDANT", tItem, false, false, nPos)
            end
        elseif eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
            if nItemType == ITEM_TABLE_TYPE.CUST_TRINKET then
                local tItem = {
                    dwTabType = nItemType,
                    dwIndex = dwItemIndex,
                    tColorID = tSubDetail.tColorID
                }
                --应用挂件自定义
                local tCustomData = tSubDetail and tSubDetail.tCustomData
                if not tCustomData or not bIsCustomized then
                    tCustomData = ShareExteriorData.GetDefaultPendantCustomData(nSub, dwItemIndex)
                end
                if tCustomData then
                    self:ApplyPendantCustom(nSub, tCustomData, dwItemIndex)
                    local tGoods = Table_GetRewardsGoodItem(nItemType, dwItemIndex)
                    if tGoods then
                        CoinShop_PreviewGoods(eGoodsType, tGoods.dwLogicID, true)
                    end
                end

                if IsPendantPetItemByIndex(nItemType, dwItemIndex) then
                    tItem.nPos = tSubDetail.nPetPos or 0
                    FireUIEvent("PREVIEW_PENDANT_PET", tItem, false, false)
                else
                    FireUIEvent("PREVIEW_PENDANT", tItem, false, false)
                end

                --应用披风隐藏开关
                if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
                    local bVisible = tSubDetail.bVisible
                    pPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, bVisible)
                end
            else
                local tGoods = Table_GetRewardsGoodItem(nItemType, dwItemIndex)
                if tGoods then
                    CoinShop_PreviewGoods(eGoodsType, tGoods.dwLogicID, true)
                end
            end
        elseif dwID then --发型/外装/武器
            CoinShop_PreviewGoods(eGoodsType, dwID, true)
            --应用发型/成衣裁剪数据
            local nHideFlag = tSubDetail.nFlag
            if nHideFlag then
                if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
                    pPlayer.SetHairSubsetHideFlag(dwID, nHideFlag)
                elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
                    pPlayer.SetExteriorSubsetHideFlag(dwID, nHideFlag)
                end
            end

            --应用发型染色数据
            if eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
                local tDyeingData = tSubDetail.tDyeingData or {}
                local tList = pPlayer.GetHairCustomDyeingList(dwID) or {}
                for nIndex, tMyDyeintData in ipairs(tList) do
                    if IsTableEqual(tMyDyeintData, tDyeingData) then
                        ShareExteriorData.ChangeHairDyeingIndex(dwID, nIndex)
                    end
                end
            end
        end
    end
end

function UIShareStationImportExteriorPop:ApplyEffectCustom(szSub, tCustomData)
    local pPlayer = GetClientPlayer()
    if not pPlayer or not tCustomData then
        return
    end

    local nEffectType = CharacterEffectData.GetLogicTypeByEffectType(szSub)
    if not nEffectType then
        return
    end

    pPlayer.SetEquipCustomSFXData(nEffectType, tCustomData)
end

function UIShareStationImportExteriorPop:ApplyPendantCustom(nSub, tCustomData, dwItemIndex)
    local pPlayer = GetClientPlayer()
    if not pPlayer or not tCustomData then
        return
    end

    local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
    if not hItemInfo then
        return
    end

    local nRepresentID = hItemInfo.nRepresentID
    local nSelectedPos = CoinShop_RepresentSubToPendantType(nSub)
    local nEquippedIndex = pPlayer.GetSelectPendent(nSelectedPos)
    -- CoinShop_View.UpdateRole 通过 CoinShop_CustomPendant 从本地缓存读取挂件自定义数据，
    -- 所以先写本地，保证 COINSHOPVIEW_ROLE_DATA_UPDATE 能拿到 custom data
    CoinShopData.CustomPendantOnSaveToLocal(nSub, nRepresentID, tCustomData)
    if nEquippedIndex ~= dwItemIndex then
        local nShowPos = DealwithPendantPosToShow(nSelectedPos)
        local nEquipSub = GetEquipSubByPendantType(nShowPos)
        pPlayer.SelectPendent(nEquipSub, dwItemIndex, nSelectedPos)
        pPlayer.SetEquipCustomRepresentData(nSub, nRepresentID, tCustomData)
    else
        pPlayer.SetEquipCustomRepresentData(nSub, nRepresentID, tCustomData)
    end
end

function UIShareStationImportExteriorPop:UpdateApplyBtnState()
    local bCanApply = true
    local nUnableApplySort = SHARE_EXTERIOR_SHOP_STATE.OTHER -- 其他分类的外观不允许应用

    for nSort, tbScript in pairs(self.tbScriptExteriorItem) do
        for _, scriptItem in ipairs(tbScript) do
            if scriptItem.nSort == nUnableApplySort and scriptItem:GetSelected() then
                bCanApply = false
                break
            end
        end
    end

    UIHelper.SetButtonState(self.BtnAccept, bCanApply and BTN_STATE.Normal or BTN_STATE.Disable)
end

return UIShareStationImportExteriorPop