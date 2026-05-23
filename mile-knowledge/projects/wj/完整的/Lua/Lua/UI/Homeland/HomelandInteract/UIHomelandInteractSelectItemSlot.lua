-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractSelectItemSlot
-- Date: 2023-08-08 14:41:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractSelectItemSlot = class("UIHomelandInteractSelectItemSlot")

function UIHomelandInteractSelectItemSlot:OnEnter(nIndex, tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self.nModuleID = tbInfo.nModuleID
    self:UpdateInfo()
end

function UIHomelandInteractSelectItemSlot:OnExit()
    self.bInit = false
end

function UIHomelandInteractSelectItemSlot:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChoose, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnSelectedHomelandInteractItemCell, self.nIndex, self.tbInfo, self.nModuleID)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local tSlotSelectionItem = HomelandMiniGameData.tSlotSelectionItem or {}
        local tItemInfo = tSlotSelectionItem[self.tbInfo.nID]
        if tItemInfo and not tItemInfo.nAddSlotID then return end

        local tbInfo = Lib.copyTab(self.tbInfo)
        tbInfo.nID = tItemInfo.nAddSlotID
        tbInfo.nBtnID = tItemInfo.nBtnID
        tbInfo.nCostType = tItemInfo.nCostType
        Event.Dispatch(EventType.OnSelectedHomelandInteractItemCell, self.nIndex, tbInfo, self.nModuleID)
    end)
end

function UIHomelandInteractSelectItemSlot:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandInteractSelectItemSlot:UpdateInfo()
    local nType = self.tbInfo.nType
	local tSlotSelectionItem = HomelandMiniGameData.tSlotSelectionItem or {}
    local tItemInfo = tSlotSelectionItem[self.tbInfo.nID]

    local bHadItem = false
    if nType == PETS_SCREE_TYPE.ORDINARYPET then -- 宠物
        if tItemInfo then
            UIHelper.SetVisible(self.WidgetItemIcon, true)
            self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)

            local tPet = Table_GetFellowPet(tItemInfo.dwIndex)

            self.scriptItem:OnInitWithIconID(tPet.nIconID, tPet.nQuality)
            self.scriptItem:SetClickNotSelected(true)
            self.scriptItem:SetRecallVisible(not tItemInfo.bIsProduct)
            self.scriptItem:SetLabelCount(tItemInfo.nStackNum)
            self.scriptItem:SetRecallCallback(function ()
                HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
            end)
            self.scriptItem:SetClickCallback(function ()
                TipsHelper.ShowItemTips(self.scriptItem._rootNode, "Pet", tItemInfo.dwIndex, false)
            end)
            bHadItem = true
        else
            UIHelper.SetVisible(self.WidgetItemIcon, false)
        end
    elseif nType == PETS_SCREE_TYPE.ORDINARYMOUNT then -- 坐骑
        -- UpdateItemInfoBoxObject(hBox, 0, tModule1Item.dwTabType, tModule1Item.dwIndex, 1)
        if tItemInfo then
            UIHelper.SetVisible(self.WidgetItemIcon, true)
            self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
            self.scriptItem:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
            self.scriptItem:SetClickNotSelected(true)
            self.scriptItem:SetLabelCount(tItemInfo.nStackNum)
            self.scriptItem:SetRecallVisible(not tItemInfo.bIsProduct)
            if not tItemInfo.bIsProduct then
                self.scriptItem:SetRecallCallback(function ()
                    HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                end)
            end
            self.scriptItem:SetClickCallback(function ()
                local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemIcon, TipsLayoutDir.TOP_LEFT)
                scriptItemTip:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
                -- if tItemInfo.bIsProduct then
                --     scriptItemTip:SetBtnState({})
                -- else
                --     scriptItemTip:SetBtnState({
                --         {
                --             OnClick = function ()
                --                 HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                --                 TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                --                 Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                --             end,
                --             szName = g_tStrings.STR_UNDRESS
                --         }
                --     })
                -- end

            end)
            bHadItem = true
        else
            UIHelper.SetVisible(self.WidgetItemIcon, false)
        end
    elseif nType == PETS_SCREE_TYPE.HANGUPPET then -- 挂宠
        -- UpdateItemInfoBoxObject(hBox, 0, tModule1Item.dwTabType, tModule1Item.dwIndex, 1)
        if tItemInfo then
            UIHelper.SetVisible(self.WidgetItemIcon, true)
            self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
            self.scriptItem:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
            self.scriptItem:SetClickNotSelected(true)
            self.scriptItem:SetLabelCount(tItemInfo.nStackNum)
            self.scriptItem:SetRecallVisible(not tItemInfo.bIsProduct)
            if not tItemInfo.bIsProduct then
                self.scriptItem:SetRecallCallback(function ()
                    HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                end)
            end
            self.scriptItem:SetClickCallback(function ()
                local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemIcon, TipsLayoutDir.TOP_LEFT)
                scriptItemTip:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
                -- if tItemInfo.bIsProduct then
                --     scriptItemTip:SetBtnState({})
                -- else
                --     scriptItemTip:SetBtnState({
                --         {
                --             OnClick = function ()
                --                 HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                --                 TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                --                 Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                --             end,
                --             szName = g_tStrings.STR_UNDRESS
                --         }
                --     })
                -- end

            end)
            bHadItem = true
        else
            UIHelper.SetVisible(self.WidgetItemIcon, false)
        end
    elseif nType == PETS_SCREE_TYPE.WEAPON then -- 武器外装
        local nWeaponID = self.tbInfo.nWeaponID
        if nWeaponID and nWeaponID > 0 then
            UIHelper.SetVisible(self.WidgetItemIcon, true)
            self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
            self.scriptItem:OnInitWithTabID("WeaponExterior", nWeaponID)
            self.scriptItem:SetClickNotSelected(true)
            self.scriptItem:SetClickCallback(function ()
                Event.Dispatch(EventType.OnSelectedHomelandInteractItemCell, self.nIndex, self.tbInfo, self.nModuleID)
            end)
            bHadItem = true
        else
            UIHelper.SetVisible(self.WidgetItemIcon, false)
        end
    else
        if tItemInfo then
            UIHelper.SetVisible(self.WidgetItemIcon, true)
            self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItemIcon)
            self.scriptItem:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
            self.scriptItem:SetClickNotSelected(true)
            self.scriptItem:SetLabelCount(tItemInfo.nStackNum)
            self.scriptItem:SetRecallVisible(not tItemInfo.bIsProduct)
            if not tItemInfo.bIsProduct then
                self.scriptItem:SetRecallCallback(function ()
                    HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                end)
            end
            self.scriptItem:SetClickCallback(function ()
                local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemIcon, TipsLayoutDir.TOP_LEFT)
                scriptItemTip:OnInitWithTabID(tItemInfo.dwTabType, tItemInfo.dwIndex)
                -- if tItemInfo.bIsProduct then
                --     scriptItemTip:SetBtnState({})
                -- else
                --     scriptItemTip:SetBtnState({
                --         {
                --             OnClick = function ()
                --                 HomelandMiniGameData.tSlotSelectionItem[self.tbInfo.nID] = nil
                --                 TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                --                 Event.Dispatch(EventType.OnUpdateHomelandInteractItemData)
                --             end,
                --             szName = g_tStrings.STR_UNDRESS
                --         }
                --     })
                -- end

            end)
            bHadItem = true
        else
            UIHelper.SetVisible(self.WidgetItemIcon, false)
        end

        -- View.UpdateBoxSlot(hBox, tModule1Item, tModule1.tSlot.nType)
    end

    UIHelper.SetVisible(self.WiegetNcessaryIcon, self.tbInfo.nItemMinNum > 0 and not bHadItem)

    -- 特判种植加速标签
    UIHelper.SetVisible(self.WiegetTimeIcon, self.tbInfo.nID == 15)

    if tItemInfo and tItemInfo.nAddSlotID then
        UIHelper.SetVisible(self.BtnAdd, true)
    else
        UIHelper.SetVisible(self.BtnAdd, false)
    end
end


return UIHomelandInteractSelectItemSlot