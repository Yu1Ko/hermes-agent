-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterCustomEffect
-- Date: 2025-03-03 19:37:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local DEFAULT_CUSTOM_DATA = {
    fScale = 1,
    nOffsetX = 0, nOffsetY = 0, nOffsetZ = 0,
    fRotationX = 0, fRotationY = 0, fRotationZ = 0,
}

local TEST_SFX_DATA = {
    MinScale = 1,
    MaxScale = 2,
    MinOffsetX = -5,
    MaxOffsetX = 5,
    MinOffsetY = -5,
    MaxOffsetY = 5,
    MinOffsetZ = -5,
    MaxOffsetZ = 5,
}

local REPRESENT_POS = {
    [EQUIPMENT_REPRESENT.HEAD_EXTEND] = 1,
    [EQUIPMENT_REPRESENT.HEAD_EXTEND1] = 2,
    [EQUIPMENT_REPRESENT.HEAD_EXTEND2] = 3,
}

local PendantDataModel = {}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.szType = "CircleBody"
    DataModel.nType = PLAYER_SFX_REPRESENT.SURROUND_BODY
    DataModel.bChoosePendant = false

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    DataModel.nRoleType = hPlayer.nRoleType
    DataModel.LoadPendantPos()
    DataModel.UpdateMyChoose()
end

function DataModel.UnInit()
    DataModel.dwEffectID = nil
    DataModel.nRoleType = nil
    DataModel.tPendantPos = nil
    DataModel.tCustomInfo = nil
    DataModel.bChoosePendant = false
    DataModel.tCustomEffectData = nil
    DataModel.tNowCustomEffectData = nil
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

function DataModel.UpdateMyChoose()
    local dwEffectID = CharacterEffectData.GetEffectEquipByType(DataModel.szType)
    if not dwEffectID then
        DataModel.bChoosePendant = false
        return
    end

    local tInfo = Table_GetPendantEffectInfo(dwEffectID)
    DataModel.dwEffectID = dwEffectID
    DataModel.dwRepresentID = tInfo.dwRepresentID
    DataModel.tEffectInfo = tInfo
    DataModel.bChoosePendant = true

    DataModel.tCustomInfo   = GetSFXCustomInfo(DataModel.nRoleType, dwEffectID)

    local tCustomData = CharacterEffectData.GetLocalCustomEffectDataEx(DataModel.nType, dwEffectID) or DEFAULT_CUSTOM_DATA
    DataModel.tCustomEffectData = clone(tCustomData)
    DataModel.tNowCustomEffectData = clone(tCustomData)
end

function DataModel.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep)
	return nPos
end

function DataModel.UpdateNowData(szKey, nValue)
    DataModel.tNowCustomEffectData[szKey] = nValue
end

function DataModel.ResetData(szKey)
    DataModel.tNowCustomEffectData[szKey] = DataModel.tCustomEffectData[szKey]
end

function DataModel.ResetAll()
    DataModel.tNowCustomEffectData = clone(DataModel.tCustomEffectData)
end

local UICharacterCustomEffect = class("UICharacterCustomEffect")

function UICharacterCustomEffect:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICharacterCustomEffect:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.bEnterPreview then
        self:EnterPreviewMode(false)
    end

    if self.bEnterCustomPreview then
        self:EnterCustomPreviewMode(false)
    end
end

function UICharacterCustomEffect:ClickPendantSave()
    if PendantDataModel.bMultiple then
        for nType, dwIndex in pairs(PendantDataModel.tPendantList) do
            if dwIndex ~= 0 then
                local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                self:OnPendantSave(nType, hItemInfo.nRepresentID)
            end
        end
    else
        self:OnPendantSave()
    end
end

function UICharacterCustomEffect:OnPendantSave(nType, nRepresentID)
    if not nType then
        nType = PendantDataModel.nType
    end
    if not nRepresentID then
        nRepresentID = PendantDataModel.hItemInfo.nRepresentID
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nRetCode = hPlayer.SetEquipCustomRepresentData(nType, nRepresentID, PendantDataModel.tNowCustomRepresentData[nType])
end

function UICharacterCustomEffect:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        local nCustomType = self:GetCustomType()
        if nCustomType == AccessoryMainPageIndex.Effect then
            self:Close()
        elseif nCustomType == AccessoryMainPageIndex.Pendant then
            self:ClosePendantCutom()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        local nCustomType = self:GetCustomType()
        if nCustomType == AccessoryMainPageIndex.Effect then
            CharacterEffectData.CustomEffectOnSaveToLocal(DataModel.nType, DataModel.dwEffectID, clone(DataModel.tNowCustomEffectData))
            CharacterEffectData.CustomEffectSetLocalDataToPlayer(DataModel.nType, DataModel.dwEffectID)
        elseif nCustomType == AccessoryMainPageIndex.Pendant then
            self:ClickPendantSave()
        end

    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        local nCustomType = self:GetCustomType()
        local szTips = nCustomType == AccessoryMainPageIndex.Effect and g_tStrings.STR_COINSHOP_CUSTOM_EFFECT_TIPS or "挂件位置自定义数据均会保存到本地角色数据中，仅当前装备的挂件数据会同步到服务器。"
        local szTips = string.format("<color=#FEFEFE>%s</color>", szTips)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, szTips)
        local nWidth, nHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nWidth, nHeight)
        tips:UpdatePosByNode(self.BtnRule)
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function()
        local nCustomType = self:GetCustomType()
        UIHelper.ShowConfirm(g_tStrings.STR_CUSTOM_PENDANT_RESET, function()
            if nCustomType == AccessoryMainPageIndex.Effect then
                self:ResetAll()
            elseif nCustomType == AccessoryMainPageIndex.Pendant then
                self:ResetPendantAll()
            end
        end)
    end)
end

function UICharacterCustomEffect:RegEvent()
    Event.Reg(self, "PLAYER_SFX_CHANGE", function()
        self:UpdateAll()
    end)

    Event.Reg(self, "ACQUIRE_SFX", function()
        self:UpdateAll()
    end)

    Event.Reg(self, "ON_CUSTOM_SFX_DATA_CHANGE", function()
        if arg0 == PLAYER_SFX_REPRESENT.SURROUND_BODY then
            self:UpdateAll()
        end
    end)

    Event.Reg(self, EventType.OpenCloseCharacterCustomEffect, function(bOpen, nType)
        if bOpen then
            self:Open()
        else
            self:Close()
        end
    end)

    Event.Reg(self, EventType.OpenCloseCharacterCustomPendant, function(bOpen, nRepresentType, nPendantType)
        if bOpen then
            self:OpenPendantCutom(nRepresentType, nPendantType)
        else
            self:ClosePendantCutom()
        end
    end)

    Event.Reg(self, "ON_CUSTOM_REPRESENT_DATA_CHANGE", function()
        self:UpdatePendant()
    end)
end

function UICharacterCustomEffect:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterCustomEffect:Open()
    self:SetCustomType(AccessoryMainPageIndex.Effect)
    self:SetVisible(true)
    Event.Dispatch(EventType.OnCharacterCustomEffectOpenClose, true)
    self:EnterPreviewMode(true)
    DataModel.Init()
    self:UpdateAll()
end

function UICharacterCustomEffect:Close()
    if not self:GetVisible() then
        return
    end
    self:SetVisible(false)
    Event.Dispatch(EventType.OnCharacterCustomEffectOpenClose, false)
    self:EnterPreviewMode(false)
end

function UICharacterCustomEffect:UpdateAll()
    if not self:GetVisible() then
        return
    end
    DataModel.UpdateMyChoose()
    self:UpdateInfo()
    self:UpdateModel()
end

function UICharacterCustomEffect:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    UIHelper.SetVisible(self.ScrollViewAdjust, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    if not DataModel.bChoosePendant then
        self:Close()
    else
        UIHelper.SetVisible(self.ScrollViewAdjust, true)
        self:UpdateItemInfo()
        self:UpdateContainerInfo()
    end
    self:UpdateBtn()
    self:UpdateBtnText()
end

function UICharacterCustomEffect:UpdateItemInfo()
    local tInfo = DataModel.tEffectInfo
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UICharacterCustomEffect:UpdateContainerInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tScriptList = {}

    if DataModel.tCustomInfo then
        DataModel.bParamsInit = true
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
                        local nValue = DataModel.tCustomEffectData[tLine.szKey]
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

function UICharacterCustomEffect:OnParamsUpdate(szKey, nValue)
    DataModel.UpdateNowData(szKey, nValue)
    self:UpdateBtn()
    self:UpdateModel()
end

function UICharacterCustomEffect:EnterPreviewMode(bEnter)
    self.bEnterPreview = bEnter
    if bEnter then
        rlcmd("enable preview equipsfx 1")
    else
        rlcmd("enable preview equipsfx 0")
    end
end

function UICharacterCustomEffect:UpdateModel()
    if DataModel.dwRepresentID and DataModel.tNowCustomEffectData and DataModel.tCustomInfo then
        local tCustomData = DataModel.tNowCustomEffectData
        local OffsetMagnification = DataModel.tCustomInfo.OffsetMagnification or 1
        rlcmd(string.format("update preview equipsfx transform %d %.1f %.1f %.1f %f %f %f %.2f",
            DataModel.dwRepresentID,
            tCustomData.nOffsetX  * OffsetMagnification,
            tCustomData.nOffsetY * OffsetMagnification,
            tCustomData.nOffsetZ * OffsetMagnification,
            tCustomData.fRotationX, tCustomData.fRotationY, tCustomData.fRotationZ, tCustomData.fScale))
    end
end

function UICharacterCustomEffect:UpdateBtn()
   if IsTableEqual(DataModel.tCustomEffectData, DataModel.tNowCustomEffectData) then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
   else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
   end
end

function UICharacterCustomEffect:UpdateBtnText()
    -- if DataModel.bIsPendantChange then
    --     UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_SAVE_LOCAL)
    -- else
    --     UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_SAVE)
    -- end
    UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_SAVE)
end

function UICharacterCustomEffect:ResetClass(dwClass)
    local tList = DataModel.tPendantPos[dwClass]
    for k, tLine in ipairs(tList) do
        DataModel.ResetData(tLine.szKey)
        local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
        if scriptCell then
            scriptCell:SetCurCount(DataModel.tNowCustomEffectData[tLine.szKey])
        end
    end
    self:UpdateModel()
    self:UpdateBtn()
end

function UICharacterCustomEffect:ResetAll()
    DataModel.ResetAll()
    for dwClass, tList in pairs(DataModel.tPendantPos) do
        for k, tLine in ipairs(tList) do
            local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
            if scriptCell then
                scriptCell:SetCurCount(DataModel.tNowCustomEffectData[tLine.szKey])
            end
        end
    end
    self:UpdateModel()
    self:UpdateBtn()
end

function UICharacterCustomEffect:GetData(nType)
    if not self:GetVisible() then
        return
    end
    if not DataModel.nType or nType ~= DataModel.nType then
        return
    end
    return DataModel.tNowCustomEffectData
end

function UICharacterCustomEffect:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UICharacterCustomEffect:GetVisible()
    return UIHelper.GetVisible(self._rootNode)
end

----------------------------挂件自定义-----------------------------------------
------------------------------DataModel----------------------------------
function PendantDataModel.Init(nRepresentType, nPendantType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    PendantDataModel.nType          = nRepresentType
    PendantDataModel.nRoleType      = hPlayer.nRoleType
    PendantDataModel.tNowCustomRepresentData = {}
    nRepresentType, nPendantType     = PendantDataModel.GetInitEquipType(hPlayer, nRepresentType, nPendantType)

    PendantDataModel.UpdateChoosePos(nPendantType, nRepresentType)
    PendantDataModel.LoadPendantPos()
end

function PendantDataModel.LoadPendantPos()
    local  nCount = g_tTable.PendantPos:GetRowCount()
	PendantDataModel.tPendantPos = {}
	for i = 2, nCount do
        local tLine = g_tTable.PendantPos:GetRow(i)
		if not PendantDataModel.tPendantPos[tLine.dwClassID] then
			PendantDataModel.tPendantPos[tLine.dwClassID] = {}
		end
        table.insert(PendantDataModel.tPendantPos[tLine.dwClassID], tLine)
    end
end

function PendantDataModel.SetMultiple(nType)
    PendantDataModel.bMultiple = nType == EQUIPMENT_REPRESENT.HEAD_EXTEND
end

--多个头饰的时候选择一个有设置的槽位
function PendantDataModel.GetInitEquipType(hPlayer, nType, nPendantType)
    if PendantDataModel.bMultiple then
        local _, nPendantPos = CharacterPendantData.GetSelectPendent(hPlayer, KPENDENT_TYPE.HEAD)
        nPendantType = nPendantPos
        if nPendantPos then
            nType = CoinShop_PendantTypeToRepresentSub(nPendantPos)
        end
    end
    return nType, nPendantType
end

function PendantDataModel.UpdateChoosePos(nPendantType, nType)
    PendantDataModel.nType             = nType
    PendantDataModel.nPendantType      = nPendantType
end

function PendantDataModel.SetNoData()
    PendantDataModel.bCanSet           = false
    PendantDataModel.bChoosePendant    = false
    PendantDataModel.bIsPendantChange  = false
    PendantDataModel.tItem             = nil
    PendantDataModel.hItemInfo         = nil
end

function PendantDataModel.InitChoosePendant()
    local hPlayer                   = GetClientPlayer()
    if not hPlayer then
        return
    end

    PendantDataModel.SetNoData()
    local tItem                 = {}
    tItem.dwTabType             = ITEM_TABLE_TYPE.CUST_TRINKET
    tItem.dwIndex               = hPlayer.GetSelectPendent(PendantDataModel.nPendantType)
    tItem.tColorID              = hPlayer.GetSelectedPendentColor(PendantDataModel.nPendantType)
    if not tItem.dwIndex or tItem.dwIndex == 0 then
        return
    end
    PendantDataModel.bChoosePendant    = true
    PendantDataModel.tItem             = tItem
    PendantDataModel.InitChooseItemInfo(hPlayer)
end

function PendantDataModel.InitChooseItemInfo(hPlayer)
    local hItemInfo                         = GetItemInfo(PendantDataModel.tItem.dwTabType, PendantDataModel.tItem.dwIndex)
    PendantDataModel.hItemInfo             = hItemInfo
    local nRepresentID                      = hItemInfo.nRepresentID
    PendantDataModel.bCanSet               = IsCustomPendantRepresentID(PendantDataModel.nType, nRepresentID, PendantDataModel.nRoleType)

    local hEquipRepresentSettings   = GetEquipRepresentSettings()
    if not hEquipRepresentSettings then
        return
    end

    PendantDataModel.tCustomInfo           = hEquipRepresentSettings.GetCustomInfo(PendantDataModel.nRoleType, PendantDataModel.nType, nRepresentID)
    local tCustomData                      = PendantDataModel.GetCustomRepresentData(PendantDataModel.nType, nRepresentID)
    
    PendantDataModel.tCustomRepresentData  = clone(tCustomData)
    PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType] = PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType] or clone(tCustomData)

    if PendantDataModel.nType == EQUIPMENT_REPRESENT.FACE_EXTEND and hPlayer.bHideFacePendent then
        hPlayer.SetFacePendentHideFlag(false)
    end

    if PendantDataModel.nType == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND and hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL) then
        hPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, false)
    end
end

function PendantDataModel.ResetAll()
    PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType] = clone(PendantDataModel.tCustomRepresentData)
end

function PendantDataModel.UpdateNowData(szKey, nValue)
    PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType][szKey] = nValue
end

function PendantDataModel.ResetData(szKey)
    PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType][szKey] = PendantDataModel.tCustomRepresentData[szKey]
end

function PendantDataModel.GetHeadItemIndex(nPendantType)
    local hPlayer               = GetClientPlayer()
    if not hPlayer then
        return
    end
    local dwIndex               = hPlayer.GetSelectPendent(nPendantType)
    return dwIndex
end

function PendantDataModel.GetCustomRepresentData(nType, nRepresentID)
    return CoinShopData.GetLocalCustomPendantData(nType, nRepresentID) or DEFAULT_CUSTOM_DATA    
end

function PendantDataModel.IsPendantDataChange()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if PendantDataModel.bMultiple then
        for nType, dwIndex in pairs(PendantDataModel.tPendantList) do
            if dwIndex ~= 0 then
                local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
                local tCustomRepresentData = PendantDataModel.GetCustomRepresentData(nType, hItemInfo.nRepresentID)
                if PendantDataModel.tNowCustomRepresentData[nType] and not IsTableEqual(tCustomRepresentData, PendantDataModel.tNowCustomRepresentData[nType]) then
                    return true
                end
            end
        end
    else
        return not IsTableEqual(PendantDataModel.tCustomRepresentData, PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType]) 
    end
    return false
end

function UICharacterCustomEffect:OpenPendantCutom(nRepresentType, nPendantType)
    self:SetCustomType(AccessoryMainPageIndex.Pendant)
    self:SetVisible(true)
    Event.Dispatch(EventType.OnCharacterCustomPandentOpenClose, true)
    PendantDataModel.SetMultiple(nRepresentType)
    self:EnterCustomPreviewMode(true)
    PendantDataModel.Init(nRepresentType, nPendantType)
    self:UpdatePendant()
end

function UICharacterCustomEffect:ClosePendantCutom()
    if not self:GetVisible() then
        return
    end
    self:SetVisible(false)
    Event.Dispatch(EventType.OnCharacterCustomPandentOpenClose, false)
    self:EnterCustomPreviewMode(false)
end

function UICharacterCustomEffect:SetCustomType(nType)
    self.nCustomType = nType
end

function UICharacterCustomEffect:GetCustomType()
    return self.nCustomType
end

function UICharacterCustomEffect:EnterCustomPreviewMode(bEnter)
    self.bEnterCustomPreview = bEnter
    local szCMD = "enable preview local player equip"
    if bEnter then
        szCMD = table.concat({szCMD, " 1"})
    else
        szCMD = table.concat({szCMD, " 0"})
    end
    if PendantDataModel.bMultiple then
        for i = 1, 3 do
            local szString = table.concat({szCMD, " ", i})
            rlcmd(szString)
        end
    else
        rlcmd(szCMD)
    end
end

function UICharacterCustomEffect:UpdatePendant()
    if not self:GetVisible() then
        return
    end
    PendantDataModel.InitChoosePendant()
    self:UpdatePendantInfo()
    self:UpdatePendantModel()
end

function UICharacterCustomEffect:UpdatePendantInfo()
    if PendantDataModel.bMultiple then
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
    
    if not PendantDataModel.bChoosePendant then
        self:ClosePendantCutom()
    elseif not PendantDataModel.bCanSet then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        self:UpdateItemInfo()
    else
        UIHelper.SetVisible(self.ScrollViewAdjust, true)
        self:UpdatePendantContainerInfo()
    end
    self:UpdatePendantItemInfo()
    self:UpdatePendantBtn()
    self:UpdatePendantBtnText()
end

function UICharacterCustomEffect:UpdatePendantItemInfo()
    UIHelper.SetVisible(self.LayoutDiyDecorationHead, false)
    if PendantDataModel.bMultiple then--刷新多个box
        UIHelper.SetVisible(self.LayoutDiyDecorationHead, true)
        self:UpdateToggleItemInfo()
    end
    if PendantDataModel.bChoosePendant then
        local dwItemIndex = PendantDataModel.tItem.dwIndex
        local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwItemIndex)
        local szName = ItemData.GetItemNameByItemInfo(hItemInfo)
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szName))
        UIHelper.LayoutDoLayout(self.LayoutTitle)
    end
end

function UICharacterCustomEffect:UpdatePendantContainerInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tScriptList = {}

    if PendantDataModel.bCanSet then
        PendantDataModel.bParamsInit = true
        local tValue = PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType]
        for dwClass, tList in pairs(PendantDataModel.tPendantPos) do
            local bEnable = false
            for k, tLine in ipairs(tList) do
                local fValueMax = PendantDataModel.tCustomInfo[tLine.szMaxKey]
                local fValueMin = PendantDataModel.tCustomInfo[tLine.szMinKey]
                if fValueMax ~= fValueMin then
                    bEnable = true
                    break
                end
            end
            if bEnable then
                local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceAdjustTittleCell, self.ScrollViewAdjust)
                scriptTitle:OnEnter(UIHelper.GBKToUTF8(tList[1].szClassName), function()
                    self:ResetPendantClass(dwClass)
                end)
                self.tScriptList[dwClass] = {}
                for k, tLine in ipairs(tList) do
                    local fValueMax = PendantDataModel.tCustomInfo[tLine.szMaxKey]
                    local fValueMin = PendantDataModel.tCustomInfo[tLine.szMinKey]
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
                                self:OnParamsPendantUpdate(szKey, nCurrentValue)
                            end
                        }, nValue)
                        self.tScriptList[dwClass][k] = scriptCell
                    end
                end
            end
        end
        PendantDataModel.bParamsInit = false
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICharacterCustomEffect:UpdateToggleItemInfo()
    UIHelper.RemoveAllChildren(self.WidgetToggleItem)
    PendantDataModel.tPendantList = {}
    for k, nPos in ipairs(PENDENT_HEAD_TYPE) do
        ---@type UIItemIcon
        local dwItemIndex = PendantDataModel.GetHeadItemIndex(nPos) or 0
        local nEquipRepresent = CoinShop_PendantTypeToRepresentSub(nPos)
        PendantDataModel.tPendantList[nEquipRepresent] = dwItemIndex
        if dwItemIndex ~= 0 then
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetToggleItem)
            local dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
            itemIcon:OnInitWithTabID(dwTabType, dwItemIndex)

            itemIcon:SetToggleGroupIndex(ToggleGroupIndex.CharacterCustomItem)
            itemIcon:SetClickCallback(function()
                PendantDataModel.UpdateChoosePos(nPos, CoinShop_PendantTypeToRepresentSub(nPos))
                self:UpdatePendant()
            end)
            UIHelper.SetSelected(itemIcon.ToggleSelect, nPos == PendantDataModel.nPendantType)
        end
    end
end

function UICharacterCustomEffect:UpdatePendantBtn()
    if PendantDataModel.IsPendantDataChange()then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
   else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
   end
end

function UICharacterCustomEffect:UpdatePendantBtnText()
    if PendantDataModel.bMultiple then
        UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_MULTIPLE_SAVE)
    else
        UIHelper.SetString(self.LabelSave, g_tStrings.STR_CUSTOM_PENDANT_SAVE)
    end
end

function UICharacterCustomEffect:UpdatePendantModel()
    if PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType] then
        local nRepresentID = 0
        if PendantDataModel.hItemInfo then
            nRepresentID = PendantDataModel.hItemInfo.nRepresentID
        end

        local tInfo = PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType]
        local szCMD = string.format("update preview local player equip transform %d %d %.1f %.1f %.1f %f %f %f %.2f", 
        PendantDataModel.nType, nRepresentID, tInfo.nOffsetX, tInfo.nOffsetY, tInfo.nOffsetZ, tInfo.fRotationX, tInfo.fRotationY, tInfo.fRotationZ, tInfo.fScale)
        if PendantDataModel.bMultiple then
            local nRepresentPos = REPRESENT_POS[PendantDataModel.nType]
            szCMD = table.concat({szCMD, " ", nRepresentPos})
        end
        rlcmd(szCMD)
    end
end

function UICharacterCustomEffect:ResetPendantAll()
    PendantDataModel.ResetAll()
    for dwClass, tList in pairs(PendantDataModel.tPendantPos) do
        for k, tLine in ipairs(tList) do
            local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
            if scriptCell then
                scriptCell:SetCurCount(PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType][tLine.szKey])
            end
        end
    end
    self:UpdatePendantModel()
    self:UpdatePendantBtn()
end

function UICharacterCustomEffect:ResetPendantClass(dwClass)
    local tList = PendantDataModel.tPendantPos[dwClass]
    for k, tLine in ipairs(tList) do
        PendantDataModel.ResetData(tLine.szKey)
        local scriptCell = self.tScriptList[dwClass] and self.tScriptList[dwClass][k]
        if scriptCell then
            scriptCell:SetCurCount(PendantDataModel.tNowCustomRepresentData[PendantDataModel.nType][tLine.szKey])
        end
    end
    self:UpdatePendantModel()
    self:UpdatePendantBtn()
end

function UICharacterCustomEffect:OnParamsPendantUpdate(szKey, nValue)
    PendantDataModel.UpdateNowData(szKey, nValue)
    self:UpdatePendantModel()
    self:UpdatePendantBtn()
end

return UICharacterCustomEffect