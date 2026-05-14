-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopCustomPendant
-- Date: 2024-01-24 20:29:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

-----------------------------DataModel------------------------------

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

local DataModel = {}

function DataModel.Init(nType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    DataModel.nType          = nType
    DataModel.nRoleType      = hPlayer.nRoleType
    DataModel.tNowCustomRepresentData = {}
    local nPendantType       = CoinShop_RepresentSubToPendantType(nType)
    DataModel.GetInitEquipType(hPlayer, nType, nPendantType)

    DataModel.UpdateChoosePos(nPendantType, nType)
    DataModel.LoadPendantPos()
end

function DataModel.SetMultiple(nType)
    DataModel.bMultiple = nType == EQUIPMENT_REPRESENT.HEAD_EXTEND
end

--多个头饰的时候选择一个有设置的槽位
function DataModel.GetInitEquipType(hPlayer, nType, nPendantType)
    if DataModel.bMultiple then
        local nIndex = ExteriorCharacter.GetTakeUpHeadPreviewPendant()
        if nIndex then
            nType = Exterior_BoxIndexToRepresentSub(nIndex)
            nPendantType = CoinShop_BoxIndexToPendantType(nIndex)
        end
    end
    DataModel.UpdateChoosePos(nPendantType, nType)
end

function DataModel.UpdateChoosePos(nPendantType, nType)
    DataModel.nType             = nType
    DataModel.nPendantType      = nPendantType
end

function DataModel.SetNoData()
    DataModel.bCanSet           = false
    DataModel.bChoosePendant    = false
    DataModel.bIsPendantChange  = false
    DataModel.tItem             = nil
    DataModel.hItemInfo         = nil
end

function DataModel.IsHavePendant(tData, hPlayer)
    local bHave
    if tData.tColorID then
        local tColorID = tData.tColorID
        bHave = hPlayer.IsColorPendentExist(tData.dwIndex, tColorID[1], tColorID[2], tColorID[3])
    else
        bHave = hPlayer.IsPendentExist(tData.dwIndex)
    end
    return bHave
end

function DataModel.InitChoosePendant()
    local nBoxIndex                 = Exterior_RepresentToBoxIndex(DataModel.nType)
    local tData                     = ExteriorCharacter.GetPreviewPendant(nBoxIndex)
    local hPlayer                   = GetClientPlayer()
    if not hPlayer then
        return
    end

    DataModel.SetNoData()
    if not tData or not tData.dwTabType or not tData.dwIndex then
        return
    end

    local bHave = DataModel.IsHavePendant(tData, hPlayer)
    if not bHave then
        return
    end

    DataModel.tItem                 = tData
    DataModel.bChoosePendant        = true
    DataModel.InitChooseItemInfo(hPlayer)
end

function DataModel.InitChooseItemInfo(hPlayer)
    local hItemInfo                 = GetItemInfo(DataModel.tItem.dwTabType, DataModel.tItem.dwIndex)
    DataModel.hItemInfo             = hItemInfo
    local nRepresentID              = hItemInfo.nRepresentID
    DataModel.bCanSet               = IsCustomPendantRepresentID(DataModel.nType, nRepresentID, DataModel.nRoleType)

    local hEquipRepresentSettings   = GetEquipRepresentSettings()
    if not hEquipRepresentSettings then
        return
    end

    DataModel.tCustomInfo           = hEquipRepresentSettings.GetCustomInfo(DataModel.nRoleType, DataModel.nType, nRepresentID)

    local hPlayer                   =  GetClientPlayer()
    if not hPlayer then
        return
    end

    DataModel.bIsPendantChange      = CoinShopPreview.IsPendantChange(DataModel.tItem, DataModel.nPendantType)
    local tCustomData
    -- if DataModel.bIsPendantChange then
        tCustomData                 = DataModel.GetCustomRepresentData(DataModel.nType, nRepresentID)
    -- else
    --     tCustomData                 = hPlayer.GetEquipCustomRepresentData(DataModel.nType)
    -- end

    DataModel.tCustomRepresentData  = clone(tCustomData)
    DataModel.tNowCustomRepresentData[DataModel.nType] = DataModel.tNowCustomRepresentData[DataModel.nType] or clone(tCustomData)

    if DataModel.nType == EQUIPMENT_REPRESENT.FACE_EXTEND and hPlayer.bHideFacePendent then
		hPlayer.SetFacePendentHideFlag(false)
    end

    if DataModel.nType == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND and hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)  then
		hPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, false)
    end
end

function DataModel.UnInit()
    DataModel.nType                     = nil
    DataModel.nRoleType                 = nil
    DataModel.tCustomInfo               = nil
    DataModel.bCanSet                   = nil
    DataModel.tItem                     = nil
    DataModel.hItemInfo                 = nil
    DataModel.nRepresentID              = nil
    DataModel.bChoosePendant            = nil
    DataModel.nPendantType              = nil
    DataModel.bIsPendantChange          = nil
    DataModel.tCustomRepresentData      = nil
    DataModel.tNowCustomRepresentData   = nil
    DataModel.bParamsInit               = nil
end

function DataModel.LoadPendantPos()
    local  nCount = g_tTable.PendantPos:GetRowCount()
	DataModel.tPendantPos = {}
	for i = 2, nCount do
        local tLine = g_tTable.PendantPos:GetRow(i)
		if not DataModel.tPendantPos[tLine.dwClassID] then
			DataModel.tPendantPos[tLine.dwClassID] = {}
		end
        table.insert(DataModel.tPendantPos[tLine.dwClassID], tLine)
    end
end

function DataModel.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep)
	return nPos
end

function DataModel.UpdateNowData(szKey, nValue)
    DataModel.tNowCustomRepresentData[DataModel.nType][szKey] = nValue
end

function DataModel.ResetData(szKey)
    DataModel.tNowCustomRepresentData[DataModel.nType][szKey] = DataModel.tCustomRepresentData[szKey]
end

function DataModel.ResetAll()
    DataModel.tNowCustomRepresentData[DataModel.nType] = clone(DataModel.tCustomRepresentData)
end

function DataModel.GetHeadItemIndex(nPendantType)
    local hPlayer               = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nBoxIndex             = CoinShop_PendantTypeToBoxIndex(nPendantType)
    local tData                 = ExteriorCharacter.GetPreviewPendant(nBoxIndex)
    if tData and DataModel.IsHavePendant(tData, hPlayer) then
        return tData.dwIndex
    end
end

function DataModel.CancelNowChangePendant(hPlayer)
    if not hPlayer then
        hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
    end

    if DataModel.tNowCustomRepresentData then
        DataModel.tNowCustomRepresentData[DataModel.nType] = nil
    end
    DataModel.GetInitEquipType(hPlayer, DataModel.nType, DataModel.nPendantType) 
end

function DataModel.CancelFirstChangePendantData()
    DataModel.tNowCustomRepresentData[EQUIPMENT_REPRESENT.HEAD_EXTEND] = nil
end

function DataModel.CancelPreviewPendant(dwCancelIndex)
    if not DataModel.bMultiple then
        DataModel.CancelNowChangePendant()
        return
    end
    for nType, dwIndex in pairs(DataModel.tPendantList) do
        if dwIndex == dwCancelIndex then
            DataModel.tNowCustomRepresentData[nType] = nil
        end
    end
end

function DataModel.IsPendantChange()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if DataModel.bMultiple then
        for nType, nNowPendantIndex in pairs(DataModel.tPendantList) do
            local nPendantType     = CoinShop_RepresentSubToPendantType(nType)
            local dwIndex          = hPlayer.GetSelectPendent(nPendantType)
            if nNowPendantIndex ~= dwIndex then
                return true
            end
        end
    else
        return DataModel.bIsPendantChange
    end
end

function DataModel.GetCustomRepresentData(nType, nRepresentID)
    return CoinShopData.GetLocalCustomPendantData(nType, nRepresentID) or DEFAULT_CUSTOM_DATA    
end

function DataModel.IsPendantDataChange()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if DataModel.bMultiple then
        for nType, dwIndex in pairs(DataModel.tPendantList) do
            if dwIndex ~= 0 then
                local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                local tCustomRepresentData = DataModel.GetCustomRepresentData(nType, hItemInfo.nRepresentID)
                if DataModel.tNowCustomRepresentData[nType] and not IsTableEqual(tCustomRepresentData, DataModel.tNowCustomRepresentData[nType]) then
                    return true
                end
            end
        end
    else
        return not IsTableEqual(DataModel.tCustomRepresentData, DataModel.tNowCustomRepresentData[DataModel.nType]) 
    end
    return false
end

function DataModel.SaveAndEquipPendant(nNowPendantIndex, nType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nSelectedPos = CoinShop_RepresentSubToPendantType(nType)
    local dwIndex = hPlayer.GetSelectPendent(nSelectedPos)
    local hItemInfo

    if nNowPendantIndex ~= 0 then
        hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, nNowPendantIndex)
        DataModel.OnSave(dwIndex ~= nNowPendantIndex, nType, hItemInfo.nRepresentID)
    end

    if dwIndex ~= nNowPendantIndex then
        hPlayer.SelectPendent(EQUIPMENT_SUB.HEAD_EXTEND, nNowPendantIndex, nSelectedPos)
        if nNowPendantIndex ~= 0 then
            CoinShopData.CustomPendantSetLocalDataToPlayer(nType, hItemInfo.nRepresentID)
        end
    end
end

function DataModel.OnSave(bIsPendantChange, nType, nRepresentID)
    if not nType then
        nType = DataModel.nType
    end
    if not nRepresentID then
        nRepresentID = DataModel.hItemInfo.nRepresentID
    end
    if bIsPendantChange == nil then
        bIsPendantChange = DataModel.bIsPendantChange
    end
    if bIsPendantChange then
        CoinShopData.CustomPendantOnSaveToLocal(nType, nRepresentID, DataModel.tNowCustomRepresentData[nType])
    else
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local nRetCode = hPlayer.SetEquipCustomRepresentData(nType, nRepresentID, DataModel.tNowCustomRepresentData[nType])
    end
end
-----------------------------View------------------------------
local UICoinShopCustomPendant = class("UICoinShopCustomPendant")

function UICoinShopCustomPendant:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopCustomPendant:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopCustomPendant:ClickSave()
    if DataModel.bMultiple then
        for nType, nNowPendantIndex in pairs(DataModel.tPendantList) do
            DataModel.SaveAndEquipPendant(nNowPendantIndex, nType)
        end
    else
        DataModel.SaveAndEquipPendant(DataModel.tItem.dwIndex, DataModel.nType)
    end
    self:UpdateAll()
end

function UICoinShopCustomPendant:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        local nCustomType = self:GetCustomType()
        if nCustomType == AccessoryMainPageIndex.Effect then
            self:ClickEffectSave()
        elseif nCustomType == AccessoryMainPageIndex.Pendant then
            self:ClickSave()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        local nCustomType = self:GetCustomType()
        local szTips = nCustomType == AccessoryMainPageIndex.Pendant and g_tStrings.STR_COINSHOP_CUSTOM_PENDANT_TIPS or g_tStrings.STR_COINSHOP_CUSTOM_EFFECT_TIPS
        szTips = string.format("<color=#FEFEFE>%s</color>", szTips)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, szTips)
        local nWidth, nHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nWidth, nHeight)
        tips:UpdatePosByNode(self.BtnRule)
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function()
        local nCustomType = self:GetCustomType()
        UIHelper.ShowConfirm(g_tStrings.STR_CUSTOM_PENDANT_RESET, function()
            if nCustomType == AccessoryMainPageIndex.Effect then
                self:ResetEffectAll()
            elseif nCustomType == AccessoryMainPageIndex.Pendant then
                self:ResetAll()
            end
        end)
    end)
end

function UICoinShopCustomPendant:RegEvent()
    -- Event.Reg(self, "CANCEL_PREVIEW_PENDANT", function()
    --     self:UpdateAll()
    -- end)

    Event.Reg(self, "PREVIEW_PENDANT", function()
        if DataModel.bMultiple and DataModel.nPendantNum == 3 then
            DataModel.CancelFirstChangePendantData()
        end

        if not DataModel.bMultiple then
            DataModel.CancelNowChangePendant()
        end

        self:UpdateAll()
    end)

    Event.Reg(self, EventType.OnCoinShopCustomPendantDataChanged, function()
        self:UpdateAll()
    end)

    Event.Reg(self, "ON_SYNC_PLAYER_SELECTED_PENDENT_NOTIFY", function()
        -- local nSelectedPos = arg0
        -- if DataModel.bMultiple and nSelectedPos == DataModel.nPendantType then
        --     local hPlayer = GetClientPlayer()
        --     local dwIndex  = hPlayer.GetSelectPendent(nSelectedPos)
        --     if dwIndex == 0 then
        --         DataModel.CancelNowChangePendant(hPlayer)
        --     end
        -- end
        self:UpdateAll()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_PENDANT", function()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local tCancelItem = arg0
        DataModel.CancelPreviewPendant(tCancelItem.dwIndex)

        if DataModel.bMultiple and DataModel.tItem and tCancelItem.dwTabType == DataModel.tItem.dwTabType and tCancelItem.dwIndex == DataModel.tItem.dwIndex then
            DataModel.GetInitEquipType(hPlayer, DataModel.nType, DataModel.nPendantType) 
        end
        self:UpdateAll()
    end)

    Event.Reg(self, "ON_CUSTOM_SFX_DATA_CHANGE", function()
        if arg0 == PLAYER_SFX_REPRESENT.SURROUND_BODY then
            CoinShopEffectCustom.UpdateMyChoose()
            self:UpdateEffectAll()
        end
    end)

    Event.Reg(self, "PLAYER_SFX_CHANGE", function()
        CoinShopEffectCustom.UpdateMyChoose()
        self:UpdateEffectAll()
    end)

    Event.Reg(self, "ACQUIRE_SFX", function()
        CoinShopEffectCustom.UpdateMyChoose()
        self:UpdateEffectAll()
    end)

    Event.Reg(self, "ON_EFFECT_CHANGED", function()
        if arg0 == PLAYER_SFX_REPRESENT.SURROUND_BODY  then
            CoinShopEffectCustom.UpdateMyChoose()
            self:UpdateEffectAll()
        end
    end)
end

function UICoinShopCustomPendant:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopCustomPendant:Open(nType)
    self:SetCustomType(AccessoryMainPageIndex.Pendant)
    self:SetVisible(true)
    DataModel.SetMultiple(nType)
    DataModel.Init(nType)
    self:UpdateAll()
    Event.Dispatch(EventType.OnCoinShopCustomPendantOpenClose, true)
end

function UICoinShopCustomPendant:Close()
    if not self:GetVisible() then
        return
    end
    self:SetVisible(false)
    Event.Dispatch(EventType.OnCoinShopCustomPendantOpenClose, false)
    local nCustomType = self:GetCustomType()
    if nCustomType == AccessoryMainPageIndex.Effect then
        CoinShopEffectCustom.ResetModel()
        CoinShopEffectCustom.UnInit()
    end
end

function UICoinShopCustomPendant:UpdateAll()
    if not self:GetVisible() then
        return
    end
    DataModel.InitChoosePendant()
    self:UpdateInfo()
    self:UpdateModel()
end

function UICoinShopCustomPendant:UpdateInfo()
    if DataModel.bMultiple then
        if not self.OldScrollViewAdjust then
            self.OldScrollViewAdjust = self.ScrollViewAdjust
        end
        self.ScrollViewAdjust = self.ScrollViewAdjustHead
        UIHelper.SetVisible(self.OldScrollViewAdjust, false)
    else
       if self.OldScrollViewAdjust then
            UIHelper.SetVisible(self.ScrollViewAdjust, false)
            self.ScrollViewAdjust = self.OldScrollViewAdjust or self.ScrollViewAdjust
        end
    end
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    UIHelper.SetVisible(self.ScrollViewAdjust, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    if not DataModel.bChoosePendant then
        self:Close()
    elseif not DataModel.bCanSet then
        UIHelper.SetVisible(self.WidgetEmpty, true)
    else
        UIHelper.SetVisible(self.ScrollViewAdjust, true)
        self:UpdateContainerInfo()
    end
    self:UpdateItemInfo()
    self:UpdateBtn()
    self:UpdateBtnText()
end

function UICoinShopCustomPendant:UpdateItemInfo()
    UIHelper.SetVisible(self.LayoutDiyDecorationHead, false)
    if DataModel.bMultiple then--刷新多个box
        UIHelper.SetVisible(self.LayoutDiyDecorationHead, true)
        self:UpdateToggleItemInfo()
    end
    if DataModel.bChoosePendant then
        local dwItemIndex = DataModel.tItem.dwIndex
        local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
        local szName = ItemData.GetItemNameByItemInfo(hItemInfo)
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szName))
        UIHelper.LayoutDoLayout(self.LayoutTitle)
    end
end

function UICoinShopCustomPendant:UpdateContainerInfo()
    local ScrollView = self.ScrollViewAdjust
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tScriptList = {}

    if DataModel.bCanSet then
        DataModel.bParamsInit = true
        local tValue = DataModel.tNowCustomRepresentData[DataModel.nType]
        for dwClass, tList in pairs(DataModel.tPendantPos) do
            local bEnable = false
            for k, tLine in ipairs(tList) do
                local fValueMax = DataModel.tCustomInfo[tLine.szMaxKey]
                local fValueMin = DataModel.tCustomInfo[tLine.szMinKey]
                if fValueMax ~= fValueMin then
                    bEnable = true
                    break
                end
            end
            if bEnable then
                local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceAdjustTittleCell, self.ScrollViewAdjust)
                scriptTitle:OnEnter(UIHelper.GBKToUTF8(tList[1].szClassName), function()
                    self:ResetClass(dwClass)
                end)
                self.tScriptList[dwClass] = {}
                for k, tLine in ipairs(tList) do
                    local fValueMax = DataModel.tCustomInfo[tLine.szMaxKey]
                    local fValueMin = DataModel.tCustomInfo[tLine.szMinKey]
                    if fValueMax ~= fValueMin then
                        local nStep = kmath.dcl_wpoint(tLine.nStep, 2)
                        local szKey = tLine.szKey
                        local nValue = tValue[tLine.szKey]
                        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjust)
                        scriptCell:OnEnter(8, {
                            nValueMin = fValueMin,
                            nValueMax = fValueMax,
                            nStep = nStep,
                            szName = tLine.szName,
                            fnCallback = function (_, nCurrentValue)
                                self:OnParamsUpdate(szKey, nCurrentValue)
                            end
                        }, nValue)
                        self.tScriptList[dwClass][k] = scriptCell
                    end
                end
            end
        end
        DataModel.bParamsInit = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICoinShopCustomPendant:UpdateToggleItemInfo()
    UIHelper.RemoveAllChildren(self.WidgetToggleItem)
    DataModel.nPendantNum = 0
    DataModel.tPendantList = {}
    for k, nPos in ipairs(PENDENT_HEAD_TYPE) do
        ---@type UIItemIcon
        local dwItemIndex = DataModel.GetHeadItemIndex(nPos) or 0
        local nEquipRepresent = CoinShop_PendantTypeToRepresentSub(nPos)
        DataModel.tPendantList[nEquipRepresent] = dwItemIndex
        if dwItemIndex ~= 0 then
            DataModel.nPendantNum = DataModel.nPendantNum + 1
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetToggleItem)
            local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
            itemIcon:OnInitWithTabID(dwTabType, dwItemIndex)

            itemIcon:SetToggleGroupIndex(ToggleGroupIndex.CharacterCustomItem)
            itemIcon:SetClickCallback(function()
                DataModel.UpdateChoosePos(nPos, nEquipRepresent)
                self:UpdateAll()
            end)
            UIHelper.SetSelected(itemIcon.ToggleSelect, nPos == DataModel.nPendantType)
        end
    end
end

function UICoinShopCustomPendant:OnParamsUpdate(szKey, nValue)
    DataModel.UpdateNowData(szKey, nValue)
    self:UpdateBtn()
    self:UpdateModel()
end

function UICoinShopCustomPendant:UpdateModel()
    local hModel = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if hModel then
	    hModel:UpdatePendantCustom(DataModel.nType, DataModel.tNowCustomRepresentData[DataModel.nType])
    end
end

function UICoinShopCustomPendant:UpdateBtn()
   if DataModel.IsPendantDataChange() or DataModel.IsPendantChange()then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
   else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
   end
end

function UICoinShopCustomPendant:UpdateBtnText()
    if DataModel.bMultiple then
        UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_MULTIPLE_EQUIP_SAVE)
    else
        UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_EQUIP_SAVE)
    end
end

function UICoinShopCustomPendant:ResetClass(dwClass)
    local tList = DataModel.tPendantPos[dwClass]
    for k, tLine in ipairs(tList) do
        DataModel.ResetData(tLine.szKey)
        local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
        if scriptCell then
            scriptCell:SetCurCount(DataModel.tNowCustomRepresentData[DataModel.nType][tLine.szKey])
        end
    end
    self:UpdateModel()
    self:UpdateBtn()
end

function UICoinShopCustomPendant:ResetAll()
    DataModel.ResetAll()
    for dwClass, tList in pairs(DataModel.tPendantPos) do
        for k, tLine in ipairs(tList) do
            local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
            if scriptCell then
                scriptCell:SetCurCount(DataModel.tNowCustomRepresentData[DataModel.nType][tLine.szKey])
            end
        end
    end
    self:UpdateModel()
    self:UpdateBtn()
end

function UICoinShopCustomPendant:GetData(nType)
    if not self:GetVisible() then
        return
    end
    -- if not DataModel.nType or nType ~= DataModel.nType then
    --     return
    -- end
    if not DataModel.tNowCustomRepresentData then
        return
    end
    return DataModel.tNowCustomRepresentData[nType]
end

function UICoinShopCustomPendant:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UICoinShopCustomPendant:GetVisible()
    return UIHelper.GetVisible(self._rootNode)
end



function UICoinShopCustomPendant:EffectOpen()
    self:SetCustomType(AccessoryMainPageIndex.Effect)
    self:SetVisible(true)
    CoinShopEffectCustom.Init()
    self:UpdateEffectAll()
    Event.Dispatch(EventType.OnCoinShopCustomPendantOpenClose, true)
end

function UICoinShopCustomPendant:ResetEffectAll()
    CoinShopEffectCustom.ResetAll()
    for dwClass, tList in pairs(CoinShopEffectCustom.tPendantPos) do
        for k, tLine in ipairs(tList) do
            local scriptCell = self.tEffectScriptList[dwClass] and self.tEffectScriptList[dwClass][k]
            if scriptCell then
                scriptCell:SetCurCount(CoinShopEffectCustom.tNowCustomEffectData[tLine.szKey])
            end
        end
    end
    self:UpdateEffectModel()
    self:UpdateEffectBtn()
end

function UICoinShopCustomPendant:SetCustomType(nType)
    self.nCustomType = nType
end

function UICoinShopCustomPendant:GetCustomType()
    return self.nCustomType
end

function UICoinShopCustomPendant:UpdateEffectAll()
    if not self:GetVisible() then
        return
    end
    CoinShopEffectCustom.UpdateMyChoose()
    self:UpdateEffectInfo()
    self:UpdateEffectModel()
end

function UICoinShopCustomPendant:UpdateEffectInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    UIHelper.SetVisible(self.ScrollViewAdjust, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    if not CoinShopEffectCustom.bChoosePendant then
        self:Close()
    else
        UIHelper.SetVisible(self.ScrollViewAdjust, true)
        self:UpdateEffectItemInfo()
        self:UpdateEffectContainerInfo()
    end
    self:UpdateEffectBtn()
    self:UpdateEffectBtnText()
end

function UICoinShopCustomPendant:UpdateEffectBtn()
    if IsTableEqual(CoinShopEffectCustom.tCustomEffectData, CoinShopEffectCustom.tNowCustomEffectData) then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
   else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
   end
end

function UICoinShopCustomPendant:UpdateEffectBtnText()
    UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_EQUIP_SAVE)
end

function UICoinShopCustomPendant:UpdateEffectItemInfo()
    local tInfo = CoinShopEffectCustom.tEffectInfo
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UICoinShopCustomPendant:UpdateEffectContainerInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tEffectScriptList = {}

    if CoinShopEffectCustom.tCustomInfo then
        CoinShopEffectCustom.bParamsInit = true
        for dwClass, tList in pairs(CoinShopEffectCustom.tPendantPos) do
            local bEnable = false
            for k, tLine in ipairs(tList) do
                local fValueMax = CoinShopEffectCustom.tCustomInfo[tLine.szMaxKey]
                local fValueMin = CoinShopEffectCustom.tCustomInfo[tLine.szMinKey]
                if fValueMax ~= fValueMin then
                    bEnable = true
                    break
                end
            end
            if bEnable then
                local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceAdjustTittleCell, self.ScrollViewAdjust)
                scriptTitle:OnEnter(UIHelper.GBKToUTF8(tList[1].szClassName), function()
                    self:ResetEffectClass(dwClass)
                end)
                self.tEffectScriptList[dwClass] = {}
                for k, tLine in ipairs(tList) do
                    local fValueMax = CoinShopEffectCustom.tCustomInfo[tLine.szMaxKey]
                    local fValueMin = CoinShopEffectCustom.tCustomInfo[tLine.szMinKey]
                    if fValueMax ~= fValueMin then
                        local nStep = kmath.dcl_wpoint(tLine.nStep, 2)
                        local szKey = tLine.szKey
                        local nValue = CoinShopEffectCustom.tCustomEffectData[tLine.szKey]
                        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjust)
                        scriptCell:OnEnter(8, {
                            nValueMin = fValueMin,
                            nValueMax = fValueMax,
                            nStep = nStep,
                            szName = tLine.szName,
                            fnCallback = function (_, nCurrentValue)
                                self:OnEffectParamsUpdate(szKey, nCurrentValue)
                            end
                        }, nValue)
                        self.tEffectScriptList[dwClass][k] = scriptCell
                    end
                end
            end
        end
        CoinShopEffectCustom.bParamsInit = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICoinShopCustomPendant:ResetEffectClass(dwClass)
    local tList = CoinShopEffectCustom.tPendantPos[dwClass]
    for k, tLine in ipairs(tList) do
        CoinShopEffectCustom.ResetData(tLine.szKey)
        local scriptCell = self.tEffectScriptList[dwClass] and self.tEffectScriptList[dwClass][k]
        if scriptCell then
            scriptCell:SetCurCount(CoinShopEffectCustom.tNowCustomEffectData[tLine.szKey])
        end
    end
    self:UpdateEffectModel()
    self:UpdateEffectBtn()
end

function UICoinShopCustomPendant:UpdateEffectModel()
    ExteriorCharacter.UpdateEffectPos(CoinShopEffectCustom.nType)
end

function UICoinShopCustomPendant:OnEffectParamsUpdate(szKey, nValue)
    CoinShopEffectCustom.UpdateNowData(szKey, nValue)
    self:UpdateEffectBtn()
    self:UpdateEffectModel()
end

function UICoinShopCustomPendant:ClickEffectSave()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    CharacterEffectData.CustomEffectOnSaveToLocal(CoinShopEffectCustom.nType, CoinShopEffectCustom.dwEffectID, clone(CoinShopEffectCustom.tNowCustomEffectData))
    CharacterEffectData.CustomEffectSetLocalDataToPlayer(CoinShopEffectCustom.nType, CoinShopEffectCustom.dwEffectID)
    local dwEquip = CharacterEffectData.GetEffectEquipByTypeLogic(CoinShopEffectCustom.nType)
    if dwEquip ~= CoinShopEffectCustom.dwEffectID then
        pPlayer.SetCurrentSFX(CoinShopEffectCustom.dwEffectID)
    end   
    self:UpdateEffectAll()
end

return UICoinShopCustomPendant