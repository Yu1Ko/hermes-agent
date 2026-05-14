-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterSkillSkinPage_WXLSpecal
-- Date: 2024-09-06 10:01:15
-- Desc: 装扮秘鉴-笼外簿
-- ---------------------------------------------------------------------------------
local tIllusionLockInfo = {
    dwItemType = 5,
    dwItemIndex = 82090,
    nNum = 1,
}
local MAX_GROUP_MEMBER_COUNT = 6

local UICharacterSkillSkinPage_WXLSpecal = class("UICharacterSkillSkinPage_WXLSpecal")

function UICharacterSkillSkinPage_WXLSpecal:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local player = GetClientPlayer()
    if player and not player.HaveRemoteData(REMOTE_DATA.WXL_PUPPET) then
        player.ApplyRemoteData(REMOTE_DATA.WXL_PUPPET)
    end

    self:InitData()
end

function UICharacterSkillSkinPage_WXLSpecal:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function()
        if not self:CheckPlayerState() then
            return
        end

        local tSelectInfo = self.tbSelectData
        if tSelectInfo and tSelectInfo.dwID then
            RemoteCallToServer("On_LiuPai_WXFWChangeModel", tSelectInfo.dwID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnUnLock, EventType.OnClick, function()
        local tSelectInfo = self.tbSelectData
        if tSelectInfo and tSelectInfo.dwID then
            RemoteCallToServer("On_LiuPai_WXFWUnLockModel", tSelectInfo.dwID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnLook, EventType.OnClick, function()
        local tSelectInfo = self.tbSelectData
        if tSelectInfo and tSelectInfo.dwMapID then
            local dwMapID = tSelectInfo.dwMapID
            local tRecord = {
                dwMapID = dwMapID,
                -- dwDefaultBossIndex = tSelectInfo.dwNpcIndex,
            }
            
            if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonInfo, true) then
                UIMgr.Open(VIEW_ID.PanelDungeonInfo, tRecord)
            end
        end
    end)
    
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nCurPage >= self.nMaxPage then
            return
        end

        self.nCurPage = self.nCurPage + 1
        self:UpdateModelList()
        self:UpdateBtnState()
        self:UpdatePageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nCurPage <= 1 then
            return
        end

        self.nCurPage = self.nCurPage - 1
        self:UpdateModelList()
        self:UpdateBtnState()
        self:UpdatePageInfo()
    end)

        if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateModelList()
            self:UpdateBtnState()
        end)
    else
        Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function(editbox)
            if editbox ~= self.EditPaginate then return end
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateModelList()
            self:UpdateBtnState()
        end)

        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage)
            if not nPage or nPage <= 0 then
                nPage = self.nCurPage
            elseif nPage > self.nMaxPage then
                nPage = self.nMaxPage
            end

            UIHelper.SetString(self.EditPaginate, tostring(nPage))

            if nPage == self.nCurPage then
                return
            end

            self.nCurPage = nPage
            self:UpdateModelList()
            self:UpdateBtnState()
        end)
    end
end

function UICharacterSkillSkinPage_WXLSpecal:RegEvent()
    Event.Reg(self, EventType.OnCharacterPendantSelected, function(nPage)
        if nPage ~= AccessoryMainPageIndex.SkillSkin_WXLSpecal then
            return
        end
        self.nCurPage = self.nCurPage or 1
        self:UpdateCurrency()
        self:ShowWidgetSearch(false)
        self:ShowLabelGetTips(true)
        self:UpdateInfo()
    end)

    Event.Reg(self, "REMOTE_WXL_MODEL_EVENT", function()
        self:InitData()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ACQUIRE_BEAST_PET", function()
        self:InitData()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        UIMgr.Close(VIEW_ID.PanelAccessory)
    end)
end

function UICharacterSkillSkinPage_WXLSpecal:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterSkillSkinPage_WXLSpecal:InitData()
    self.tbData = Table_GetWXPuppetList()

    local player = GetClientPlayer()
    if not player then
        return
    end

    local nSelectIllusion = player.GetRemoteArrayUInt(REMOTE_DATA.WXL_PUPPET, 0, 1)

    local nSelectIndex = 1
    local nCollect = 0
    for nIndex, tIllusion in ipairs(self.tbData) do
        local bExist = player.IsBeastPetAcquired(tIllusion.dwID)
        tIllusion.bExist = bExist
        if bExist then
            nCollect = nCollect + 1
        end
        if nSelectIllusion == tIllusion.dwID then
            nSelectIndex = nIndex
        end
    end

    self.nMaxPage = math.max(1, math.ceil(#self.tbData / MAX_GROUP_MEMBER_COUNT))
    self.nCurPage = math.ceil(nSelectIndex / MAX_GROUP_MEMBER_COUNT)
    self.nSelectIllusion = nSelectIllusion
    self.nCollect = nCollect
end

function UICharacterSkillSkinPage_WXLSpecal:UpdateInfo()
    self:UpdateModelList()
    self:UpdateBtnState()
    self:UpdatePageInfo()
end

function UICharacterSkillSkinPage_WXLSpecal:UpdateCurrency()
    local widget = self:ShowWidgetCurrency(true)
    UIHelper.RemoveAllChildren(widget)

    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, widget, tIllusionLockInfo.dwItemType, tIllusionLockInfo.dwItemIndex, true)
    UIHelper.LayoutDoLayout(widget)
end

function UICharacterSkillSkinPage_WXLSpecal:UpdateModelList()
    self.tbSelectData = nil
    self.tbScriptModelCell = {}
    UIHelper.RemoveAllChildren(self.ScrollViewPresetList)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupPresetCell)

    for nIndex = 1, MAX_GROUP_MEMBER_COUNT do
        local tIllusion = self.tbData[(self.nCurPage - 1) * MAX_GROUP_MEMBER_COUNT + nIndex]
        if tIllusion then
            local tbInfo = {}
            local bEquiped = self.nSelectIllusion and tIllusion.dwID == self.nSelectIllusion
            tbInfo.szName = UIHelper.GBKToUTF8(tIllusion.szName)
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetPresetListItem, self.ScrollViewPresetList)
            scriptCell:OnEnter(tbInfo)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupPresetCell, scriptCell.TogPreset)

            table.insert(self.tbScriptModelCell, scriptCell)
            UIHelper.SetVisible(scriptCell.ImgEquipped, bEquiped)
            UIHelper.LayoutDoLayout(scriptCell.LayoutIcon)
            if bEquiped then
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupPresetCell, scriptCell.TogPreset)
            end
            scriptCell:SetClickCallback(function()
                self:OnClickModelCell(tIllusion)
            end)

            if self.nSelectIllusion and tIllusion.dwID == self.nSelectIllusion then
                self.tbSelectData = tIllusion
            end
            self.tbSelectData = self.tbSelectData or tIllusion
        end
    end
    
    UIHelper.SetString(self.LabelExteriorNumber, string.format("%d/%d", self.nCollect, #self.tbData))
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPresetList)
end

function UICharacterSkillSkinPage_WXLSpecal:UpdatePageInfo()
    UIHelper.SetString(self.EditPaginate, tostring(self.nCurPage))
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", self.nMaxPage))
end

function UICharacterSkillSkinPage_WXLSpecal:OnClickModelCell(tIllusion)
    self.tbSelectData = tIllusion
    self:UpdateBtnState()
end

function UICharacterSkillSkinPage_WXLSpecal:UpdateBtnState()
    local bCanPreview = self.tbSelectData and self.tbSelectData.dwMapID
    UIHelper.SetButtonState(self.BtnLook, bCanPreview and BTN_STATE.Normal or BTN_STATE.Disable)
    if not self.tbSelectData then
        UIHelper.SetButtonState(self.BtnSet, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnUnLock, BTN_STATE.Disable)
        UIHelper.SetVisible(self.BtnUnLock, false)
        UIHelper.SetVisible(self.BtnSet, false)
        UIHelper.LayoutDoLayout(self.WidgetAnchorRightBotton)
        return
    end

    local nUnlockItemNum = ItemData.GetItemAmountInPackage(tIllusionLockInfo.dwItemType, tIllusionLockInfo.dwItemIndex)

    local bExist = self.tbSelectData.bExist
    local bCanLock = not bExist and nUnlockItemNum >= tIllusionLockInfo.nNum
    UIHelper.SetVisible(self.BtnSet, bExist)
    UIHelper.SetButtonState(self.BtnSet, bExist and BTN_STATE.Normal or BTN_STATE.Disable, "未解锁")

    UIHelper.SetVisible(self.BtnUnLock, not bExist)
    UIHelper.SetButtonState(self.BtnUnLock, bCanLock and BTN_STATE.Normal or BTN_STATE.Disable, "所需道具不足。")
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightBotton)
end



-- function UICharacterSkillSkinPage_WXLSpecal:ClearSelect()
--     if self.tbScriptModelCell then
--         for i, scriptCell in ipairs(self.tbScriptModelCell) do
--             scriptCell:SetSelected(false)
--         end
--     end
-- end

function UICharacterSkillSkinPage_WXLSpecal:ShowWidgetSearch(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.WidgetSearch, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
end

function UICharacterSkillSkinPage_WXLSpecal:ShowLabelGetTips(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.LabelGetTips, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
end

function UICharacterSkillSkinPage_WXLSpecal:ShowWidgetCurrency(bShow)
    local scriptPublic = UIHelper.GetBindScript(self.WidgetAnchorRight_Public)
    if not scriptPublic then
        return
    end
    UIHelper.SetVisible(scriptPublic.WidgetCurrency, bShow)
    UIHelper.LayoutDoLayout(scriptPublic.LayoutRightTop)
    return scriptPublic.WidgetCurrency
end

function UICharacterSkillSkinPage_WXLSpecal:CheckPlayerState()
    if IsInFight() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        OutputMessage("MSG_SYS", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        return false
    end
    return true
end

return UICharacterSkillSkinPage_WXLSpecal