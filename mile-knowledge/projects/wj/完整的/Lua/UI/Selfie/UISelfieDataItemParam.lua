-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieDataItemParam
-- Date: 2025-10-23 11:49:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieDataItemParam = class("UISelfieDataItemParam")

local tDefaultIcon = {
    ["tFace"] = 10776,
    ["tBody"] = 18991,
    ["tAction"] = 25763,
    ["tFaceAction"] = 25763,
    ["tHair"] = 10775,
    ["tSFXPendant"] = 25762,
}

function UISelfieDataItemParam:OnEnter(tInfo, tItemInfo, tExterior, fnCheckBack)
    if not tInfo then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = tInfo.szTitle
    self.nResSub = tInfo.nResSub
    self.bDefault = tInfo.bDefault or false
    self.bImport = tInfo.bImport or false
    self.bHave = tInfo.bHave or false
    self.bCanUse = tInfo.bCanUse or false
    self.tItemInfo = tItemInfo
    self.tExterior = tExterior
    self.fnCheckBack = fnCheckBack
    -- self.tData = SelfieTemplateBase.GetTemplateData()
    -- if not self.tData or IsTableEmpty(self.tData) then
    --     return 
    -- end
    -- self.tPlayer = self.tData.tPlayerParam
    -- self.tExterior = self.tPlayer.tExterior

    self.tSelfieTitle = g_tStrings.tSelfieTitle
    -- self.tSelfieParam = g_tStrings.tSelfieParam
    self.tPlayerTitle = g_tStrings.tPlayerTitle
    -- self.tPlayerParam = g_tStrings.tPlayerParam
    self:UpdateInfo()
end

function UISelfieDataItemParam:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieDataItemParam:Show()
    UIHelper.SetVisible(self._rootNode , true)
end

function UISelfieDataItemParam:Hide()
    UIHelper.SetVisible(self._rootNode , false)
end

function UISelfieDataItemParam:TogSwitch(Tog)
    if self.bImport and not self.bHave and not self.bDefault then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "您未拥有该外观")
    elseif self.bImport then 
        local bSel = UIHelper.GetVisible(self.ImgSelect)
        UIHelper.SetVisible(self.ImgSelect, bSel)
        self.fnCheckBack()
    end
end

function UISelfieDataItemParam:BindUIEvent()
    UIHelper.BindUIEvent(self.TogInportItemList , EventType.OnClick , function ()
        if self.bImport then
            self:TogSwitch()
        end
    end)
end

function UISelfieDataItemParam:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieDataItemParam:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieDataItemParam:UpdateInfo()
    UIHelper.SetVisible(self.ImgItemCollectBg, false)
    if self.bDefault then
        self:UpdateDefaultItem()
    else 
        self:UpdateExteriorItem()
    end
    UIHelper.SetSwallowTouches(self.TogInportItemList, false)
    UIHelper.SetVisible(self.WidgetTiick, self.bImport)
end

function UISelfieDataItemParam:UpdateExteriorItem()
    local hPlayer = GetClientPlayer()
    if not hPlayer or not self.tExterior then
        return 
    end
    local dwID = self.tExterior.tExteriorID[self.nResSub]
    local tDetail = self.tExterior.tDetail[self.nResSub]
    UIHelper.SetString(self.LabelItemDsc, g_tStrings.tPlayerParam[self.nResSub])
    local tGoodsInfo = self.tItemInfo
    if dwID and dwID ~= 0 then
        if not self.ItemScript then
            -- if not SelfieTemplateBase.IsSelfiePendant(self.nResSub) and self.nResSub ~= EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then
                self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
                self.ItemScript:SetClickNotSelected(true)
            -- else
            --     self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
            -- end
        end

        local eGoodsType, szName
        if tGoodsInfo then
            eGoodsType = tGoodsInfo.eGoodsType            
        end
        local tbGoods = {
            eGoodsType = eGoodsType,
            dwGoodsID = dwID,
            dwTabType = tGoodsInfo.nItemType,
            dwTabIndex = tGoodsInfo.dwItemIndex,
        }
        if self.nResSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then
            local hItemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
            szName = UIHelper.GBKToUTF8(hItemInfo.szName)
            self.ItemScript:OnInitWithTabID(tGoodsInfo.nItemType, tGoodsInfo.dwItemIndex)
            self.ItemScript:SetClickCallback(function()
                TipsHelper.ShowItemTips(self.ItemScript._rootNode, tGoodsInfo.nItemType, tGoodsInfo.dwItemIndex, false)
            end)
        elseif SelfieTemplateBase.IsSelfiePendant(self.nResSub) then
            local nPendantType = GetCustomPendantType(self.nResSub)
            local nPendantPos = SelfieTemplateBase.GetPendantPosNew(nPendantType, self.nResSub)
            local hItemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
            szName = UIHelper.GBKToUTF8(hItemInfo.szName)
            self.ItemScript:OnInitWithTabID(tGoodsInfo.nItemType, tGoodsInfo.dwItemIndex)
            self.ItemScript:SetClickCallback(function()
                TipsHelper.ShowItemTips(self.ItemScript._rootNode, tGoodsInfo.nItemType, tGoodsInfo.dwItemIndex, false)
            end)
        elseif SelfieTemplateBase.IsSelfieSFXPendant(self.nResSub) then 
            local tInfo = Table_GetPendantEffectInfo(dwID)
            szName = UIHelper.GBKToUTF8(tInfo.szName)
            self.ItemScript:OnInitWithIconID(tDefaultIcon["tSFXPendant"], 2, 1)
            self.ItemScript:SetClickCallback(function()
                local _, scriptTips = TipsHelper.ShowItemTips(self.ItemScript._rootNode, "Effect", dwID, false)
                scriptTips:SetBtnState({})
            end)
        elseif self.nResSub == EQUIPMENT_REPRESENT.HAIR_STYLE then
            local nHairID = dwID
            szName = CoinShopHair.GetHairText(nHairID)
            szName = GBKToUTF8(szName)
            self.ItemScript:OnInitWithIconID(tDefaultIcon["tHair"], 2, 1)
            self.ItemScript:SetClickCallback(function()
                CoinShopPreview.InitItemTips(tbGoods, nil, self.ItemScript._rootNode)
            end)
        elseif self.nResSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or self.nResSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then
            local bCollect = CoinShop_GetCollectInfo(eGoodsType, dwID)
            if not bCollect then
                szName = CoinShop_GetGoodsName(eGoodsType, dwID)
            else
                local tUIInfo = g_tTable.CoinShop_Weapon:Search(dwID)
                szName = tUIInfo.szName
            end
            szName = GBKToUTF8(szName)
            local tInfo = clone(tGoodsInfo)
            tInfo.dwGoodsID = dwID
            CoinShopPreview.InitItemIcon(self.ItemScript, tInfo, nil, nil)
            self.ItemScript:SetClickCallback(function()
                CoinShopPreview.InitItemTips(tbGoods, nil, self.ItemScript._rootNode)
            end)
        else
            local bCollect = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
            if not bCollect then
                szName = CoinShop_GetGoodsName(eGoodsType, dwID)
                szName = UIHelper.GBKToUTF8(szName)
            else
                local hExteriorClient = GetExterior()
                if not hExteriorClient then
                    return
                end
                local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwID)
                local tbSet = Table_GetExteriorSet(tExteriorInfo.nSet)
                local szSub = g_tStrings.tExteriorSubNameGBK[tExteriorInfo.nSubType]
                szName = UIHelper.GBKToUTF8(tbSet.szSetName .. g_tStrings.STR_CONNECT_GBK .. szSub)
            end
            local tInfo = clone(tGoodsInfo)
            tInfo.dwGoodsID = dwID
            if tGoodsInfo.nItemType and tGoodsInfo.dwItemIndex then
                self.ItemScript:OnInitWithTabID(tGoodsInfo.nItemType, tGoodsInfo.dwItemIndex)
            else
                CoinShopPreview.InitItemIcon(self.ItemScript, tInfo, nil, nil)
            end
            self.ItemScript:SetClickCallback(function()
                CoinShopPreview.InitItemTips(tbGoods, nil, self.ItemScript._rootNode)
            end)
        end
        if szName then
            UIHelper.SetString(self.LabelItemName, UIHelper.LimitUtf8Len(szName, 7))
        end
        UIHelper.SetString(self.LabelItemDsc, g_tStrings.tPlayerParam[self.nResSub])
        
    end
    UIHelper.SetVisible(self.ImgItemCollectBg, self.bImport and not self.bHave)
    local bGrayItem = self.bImport and (not self.bHave or not self.bCanUse)
    local szGrayMsg = ""
    if bGrayItem then
        szGrayMsg = not self.bCanUse and "体型不一致或角色数据为空，角色参数不可用" or "您未拥有该" .. self.tPlayerTitle[self.szTitle]
    end
    UIHelper.SetCanSelect(self.TogInportItemList, not bGrayItem, szGrayMsg)
end

function UISelfieDataItemParam:UpdateDefaultItem()
    if not self.ItemScript then
        self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.ItemScript:SetClickNotSelected(true)
    end

    local szName, szDsc, nIconID = self:GetDefaultNameAndDsc()
    if nIconID then
        self.ItemScript:OnInitWithIconID(nIconID, 2, 1) 
    end
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.SetString(self.LabelItemDsc, szDsc)
    UIHelper.SetCanSelect(self.TogInportItemList, not self.bImport or self.bCanUse, "体型不一致或角色数据为空，角色参数不可用")
end

function UISelfieDataItemParam:GetDefaultNameAndDsc()
    local szName, szDsc, nIconID
    if self.szTitle == "tAction" then
        local tAction = self.tItemInfo
        local dwID = tAction.dwAnimationID
        local tInfo = SelfieTemplateBase.GetActionInfo(dwID)
        if not tInfo or IsTableEmpty(tInfo) then
            return
        end
        local bUpdateBox
        szName, szDsc, bUpdateBox = SelfieTemplateBase.UpdateActionBoxInfo(tAction.dwAnimationID, self.ItemScript, self.tExterior.tExteriorID)
        -- local nType, dwLogicID = SelfieTemplateBase.GetActionType(dwID)
        -- szDsc = g_tStrings.tActionType[nType]
        -- szName = szDsc
        szName = UIHelper.LimitUtf8Len(szName, 7)
        if not bUpdateBox then
            nIconID = tDefaultIcon[self.szTitle]
        end
    elseif self.szTitle == "tFaceAction" then
        local tFaceAction = self.tItemInfo
        local dwID = tFaceAction.dwFaceMotionID
        szDsc  = g_tStrings.tPlayerTitle[self.szTitle]
        local tInfo = EmotionData.GetFaceMotion(dwID)
        if not tInfo then
            return
        end
        szName = UIHelper.GBKToUTF8(tInfo.szName)
        nIconID = tInfo.nIconID
    else
        szName = self.tPlayerTitle[self.szTitle]
        szDsc = self.tPlayerTitle[self.szTitle]
        nIconID = tDefaultIcon[self.szTitle]
    end
    return szName, szDsc, nIconID
end

function UISelfieDataItemParam:SetSelectState(bSelect, bDefault)

    if not self.bHave and not bDefault and bSelect then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "您未拥有该外观")
        return false
    end
    UIHelper.SetSelected(self.TogInportItemList , bSelect)
    UIHelper.SetVisible(self.ImgSelect, bSelect)
    -- UIHelper.SetVisible(self.ImgSelect, bSelect)
    return true
end

function UISelfieDataItemParam:GetSelectState()
    local bSelect = UIHelper.GetSelected(self.TogInportItemList)
    return bSelect
end

return UISelfieDataItemParam