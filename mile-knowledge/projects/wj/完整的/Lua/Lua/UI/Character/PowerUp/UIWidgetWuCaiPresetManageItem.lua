-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetWuCaiPresetManageItem
-- Date: 2023/11/9
-- Desc: UIWidgetWuCaiPresetManageItem
-- ---------------------------------------------------------------------------------

---@class UIWidgetWuCaiPresetManageItem
local UIWidgetWuCaiPresetManageItem = class("UIWidgetWuCaiPresetManageItem")

function UIWidgetWuCaiPresetManageItem:OnEnter(nWeaponIndex, bAdd)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nWeaponIndex = nWeaponIndex
        self.bAdd = bAdd

        self.tStoneScripts = {}

        self:InitStones()
        self:UpdateInfo()
    end
end

function UIWidgetWuCaiPresetManageItem:OnExit()
    self.bInit = false
end

function UIWidgetWuCaiPresetManageItem:BindUIEvent()
end

function UIWidgetWuCaiPresetManageItem:RegEvent()
    Event.Reg(self, "WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        self:UpdateInfo()
        if self.fnRefreshScrollView and self.bShouldUpdate then
            self.bShouldUpdate = false
            --Timer.AddFrame(self, 1, function()
            self.fnRefreshScrollView()
            --end)
        end
    end)
end

function UIWidgetWuCaiPresetManageItem:UpdateInfo()
    if not g_pClientPlayer then
        return
    end

    UIHelper.SetVisible(self.TogPreset, not self.bAdd)
    UIHelper.SetVisible(self.BtnAdd, self.bAdd)

    local nEquipIndex = EQUIPMENT_INVENTORY.MELEE_WEAPON
    local KCurrentWeaponItem = DataModel.GetEquipItem(nEquipIndex)
    if KCurrentWeaponItem then
        for k, v in pairs(DataModel.tBindWeaponInfo) do
            if v[1] == KCurrentWeaponItem.dwTabType and v[2] == KCurrentWeaponItem.dwIndex then
                self.nCurWeaponSlot = v[3]
                break
            end
        end
    end

    self.nCurWeaponSlot = 0
    self.nCurSlotIndex = g_pClientPlayer.GetColorDiamondCurrentConfigIndex()
    self.tBindInfo = DataModel.GetBindWeaponInfo(self.nWeaponIndex, nil)
    self.KCurrentWeaponItem = KCurrentWeaponItem
    self.nWeaponMountedEnchantID = KCurrentWeaponItem and KCurrentWeaponItem.GetMountFEAEnchantID() or 0

    --藏剑当前装备栏上五彩石未生效
    if not DataModel.IsEquipBoxColorDiamondApply() then
        self.nCurSlotIndex = 0
    end

    self:UpdateWeapon()
    self:UpdateSelectedStone()
    self:UpdateStones()

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetWuCaiPresetManageItem:UpdateWeapon()
    local tBindInfo = self.tBindInfo
    if tBindInfo then
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetWeaponItem) ---@type UIItemIcon
        itemScript:OnInitWithTabID(tBindInfo[1], tBindInfo[2])
        itemScript:SetClickNotSelected(true)
        itemScript:SetClickCallback(function()
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetWeaponItem, TipsLayoutDir.LEFT_CENTER)
            script:OnInitWithTabID(tBindInfo[1], tBindInfo[2])
        end)
        itemScript:SetRecallVisible(true)
        itemScript:SetRecallCallback(function()
            RemoveWeapon(tBindInfo[1], tBindInfo[2])
        end)

        UIHelper.SetParent(itemScript.BtnRecall, itemScript._rootNode)

        local pItemInfo = ItemData.GetItemInfo(tBindInfo[1], tBindInfo[2])
        local szName = UIHelper.GBKToUTF8(pItemInfo.szName)
        szName = UIHelper.LimitUtf8Len(szName, 7)
        UIHelper.SetString(self.LabelWeaponName, szName)
        UIHelper.SetString(self.LabelWeaponName1, szName)
    end
end

function UIWidgetWuCaiPresetManageItem:UpdateStones()
    local tBindInfo = self.tBindInfo
    local nWeaponIndex = self.nWeaponIndex
    local nCurWeaponSlot = self.nCurWeaponSlot
    local nCurSlotIndex = self.nCurSlotIndex
    local tToggleToActivate = nil
    local bHasActivated = false

    for nStoneIndex = 1, MAX_COLOR_DIAMOND_NUM do
        local script = self.tStoneScripts[nStoneIndex] ---@type UIWidgetWuCaiPresetCell LayoutDetail中可选择的五彩石预制
        local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(nStoneIndex)
        local bActive = false
        if dwEnchantID > 0 then
            local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(dwEnchantID)
            if dwTabType and dwTabIndex then
                script:OnInit(dwTabType, dwTabIndex)
            end
        end
        if (tBindInfo and tBindInfo[3] == nStoneIndex) or
                (nWeaponIndex == 0 and ((nCurWeaponSlot == nStoneIndex) or (nCurWeaponSlot == 0 and nCurSlotIndex == nStoneIndex))) then
            bActive = true
            bHasActivated = true
            tToggleToActivate = script.TogPreset
        end

        script:SetActive(bActive)
    end

    --根据激活状态正确设置选中状态
    if tToggleToActivate == nil then
        local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroup)
        local tog = UIHelper.ToggleGroupGetToggleByIndex(self.ToggleGroup, nIndex)
        UIHelper.SetSelected(tog, false)
    else
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, tToggleToActivate)
    end

    self.tStoneScripts[5]:OnInitCancelBtn()
    UIHelper.SetVisible(self.LayoutOldPreset, bHasActivated)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutWuCaiPresetSlot, true, false)
end

--更新选中五彩石的图标和相关信息
function UIWidgetWuCaiPresetManageItem:UpdateSelectedStone()
    UIHelper.RemoveAllChildren(self.WidgetItem)

    local tBindInfo = self.tBindInfo
    local nEnchantID = 0
    for nStoneIndex = 1, MAX_COLOR_DIAMOND_NUM do
        local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(nStoneIndex)
        if tBindInfo and tBindInfo[3] == nStoneIndex then
            if dwEnchantID > 0 then
                nEnchantID = dwEnchantID
                break
            end
        end
    end

    local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
    if dwTabType and dwTabIndex then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem)
        script:OnInitWithTabID(dwTabType, dwTabIndex)
        script:SetSelectEnable(false)

        local pItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
        local szName = GetFormatText("【" .. UIHelper.GBKToUTF8(pItemInfo.szName) .. "】", nil, nDiamondR, nDiamondG, nDiamondB)
        UIHelper.SetVisible(self.ImgInlaidFrame, true)
        UIHelper.SetRichText(self.RichTextDetail, szName .. "\n" .. GetColorDiamondInfo(pItemInfo.dwEnchantID))
        return
    end

    UIHelper.SetVisible(self.ImgInlaidFrame, false)
    UIHelper.SetRichText(self.RichTextDetail, "<color=#AED9E0>未激活五彩石效果</color>")
end

function UIWidgetWuCaiPresetManageItem:InitStones()
    local nWeaponIndex = self.nWeaponIndex

    for nStoneIndex = 1, MAX_COLOR_DIAMOND_NUM do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPreset, self.LayoutCurrentPresets) ---@type UIWidgetWuCaiPresetCell
        table.insert(self.tStoneScripts, script)

        script:AddToggleGroup(self.ToggleGroup)
        script:BindClickFunc(function()
            local dwEnchantID = g_pClientPlayer.GetColorDiamondSlotInfo(nStoneIndex)
            if dwEnchantID <= 0 then
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowImportantYellowTip(g_tStrings.tActivation.NEED_COLOR_DIAMOND)
                    self:UpdateStones()  --选择绑定方案中空的五彩石格子时，确保toggle的正确选中态
                end)
            else
                self.bShouldUpdate = true
                SelectColorDiamond(true, nStoneIndex, nWeaponIndex)
            end
        end)
    end

    local deleteAllScript = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPreset, self.LayoutOldPreset, false, true)---@type UIWidgetWuCaiPresetCell
    deleteAllScript:AddToggleGroup(self.ToggleGroup)
    deleteAllScript:BindDeactivateFunc(function()
        self.bShouldUpdate = true
        SelectColorDiamond(false, 0, nWeaponIndex)
    end)
    table.insert(self.tStoneScripts, deleteAllScript)
end


---------------------------------------------------------------

function UIWidgetWuCaiPresetManageItem:BindAddFunc(fnFunc)
    if IsFunction(fnFunc) then
        UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, fnFunc)
    end
end

function UIWidgetWuCaiPresetManageItem:BindScrollViewRefresh(fnFunc)
    if IsFunction(fnFunc) then
        self.fnRefreshScrollView = fnFunc
        UIHelper.BindUIEvent(self.TogPreset, EventType.OnClick, function()
            UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
            fnFunc()
        end)
    end
end

return UIWidgetWuCaiPresetManageItem