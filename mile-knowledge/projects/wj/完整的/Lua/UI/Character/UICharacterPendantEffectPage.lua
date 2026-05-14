-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantEffectPage
-- Date: 2023-02-27 11:19:08
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@type UICharacterPendantPublicPage
---@class UICharacterPendantEffectPage : UICharacterPendantPublicPage
local UICharacterPendantEffectPage = class(UICharacterPendantPublicPage, "UICharacterPendantEffectPage")
function UICharacterPendantEffectPage:Init()
    self.nCurSelectedIndex = 1
    self:BindMainPageIndex(AccessoryMainPageIndex.Effect)
    self:BindDataModel(CharacterEffectData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    CharacterEffectData.Init(self.nCurSelectedIndex)
    self:InitFilter()
    self:UpdateInfo()
end

function UICharacterPendantEffectPage:OnExit()
    self.bInit = false
    CharacterEffectData.UnInit()
end

function UICharacterPendantEffectPage:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self.nCurSelectedIndex = i - 1
            self:SetNowCollectPage(self.nCurSelectedIndex == 0)
            Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, self.nCurSelectedIndex)
        end)
    end

    UIHelper.SetToggleGroupSelected(self.ToggleGroupRightNav, self.nCurSelectedIndex)
end

function UICharacterPendantEffectPage:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearSelect()
    end)

    Event.Reg(self, "REMOTE_PREFER_EFFECT_EVENT", function()
        CharacterEffectData.UpdateEffect("Star")
        self:ClearSelect()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ACQUIRE_SFX", function()
        self:ClearSelect()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PLAYER_SFX_CHANGE", function()
        self:ClearSelect()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_ACTIVE_SKILL_SKIN", function()
        self:ClearSelect()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if not self.tbFilter or szKey ~= self.tbFilter.Key then
            return
        end

        local nSelectFilterHave = tbInfo[1][1] - 1
        local nSelectFilterWay = tbInfo[2][1] - 1

        self.DataModel.SetCurrentPage(1)
        self.DataModel.UpdateFilter(nSelectFilterHave, nSelectFilterWay)
        self.DataModel.UpdateFilterList()
        self:UpdateButtonInfo()
        self:UpdateListInfo()
    end)

    Event.Reg(self, EventType.OnCharacterCustomEffectOpenClose, function(bOpen)
        if UIHelper.GetVisible(self._rootNode) == false then
            return
        end

        UIHelper.SetVisible(self.WidgetEffectList, not bOpen)
        UIHelper.SetVisible(self.WidgetEffectTitle, not bOpen)
        self:ShowPublic(not bOpen)
    end)
end

function UICharacterPendantEffectPage:InitFilter()
    self.scriptFilterTip = UIHelper.GetBindScript(self.WidgetAnchorSuitAccessoryTips)
    self.scriptFilterTip:OnEnter(function(nSelectFilterHave, nSelectFilterWay)
        CharacterEffectData.UpdateFilter(nSelectFilterHave, nSelectFilterWay)
        CharacterEffectData.SetCurrentPage(1)
        self:ClearSelect()
        self:UpdateListInfo()
    end)
end

function UICharacterPendantEffectPage:UpdateInfo()
    self:UpdateTitleInfo()
    self:UpdateListInfo()
    self:UpdateTogInfo()
    self:UpdateBtnInfo()
    Event.Dispatch(EventType.OpenCloseCharacterCustomEffect, false)
end

function UICharacterPendantEffectPage:UpdateBtnInfo()
    local bHadWear = UIHelper.GetVisible(self.tbIconTypeWear[self.nCurSelectedIndex + 1])
    self:ShowBtnFastTakeOff(bHadWear)
    self:ShowBtnCustom(bHadWear and CharacterEffectData.GetType(self.nCurSelectedIndex) == "CircleBody")
end

function UICharacterPendantEffectPage:UpdateTogInfo()
    for i, tog in ipairs(self.tbTogType) do
        -- 优先显示红点
        local ImgRedPoint = self.tbTogRedPoint[i]
        local bHasNew = RedpointHelper.Effect_HasNewByType(i - 1)
        UIHelper.SetVisible(ImgRedPoint, bHasNew)

        if not bHasNew then
            local szType = CharacterEffectData.GetType(i - 1)
            CharacterEffectData.UpdateEffect(szType)
            local tEffectList = CharacterEffectData.GetEffectList(szType)
            local dwUsingEffectID = 0
            for _, tbInfo in ipairs(tEffectList) do
                local dwEffectID = tbInfo.dwEffectID
                if CharacterEffectData.IsEffectUsing(dwEffectID, PlayerData.GetClientPlayer()) then
                    dwUsingEffectID = dwEffectID
                    break
                end
            end
            local imgIconWear = self.tbIconTypeWear[i]
            UIHelper.SetVisible(imgIconWear, dwUsingEffectID > 0)
        else
            UIHelper.SetVisible(imgIconWear, false)
        end
    end
end

function UICharacterPendantEffectPage:UpdateTitleInfo()
    local tbInfo = CharacterEffectData.GetTypeInfo(self.nCurSelectedIndex)

    self:SetImgAccessoryIcon(tbInfo.szIcon)
    self:SetImgTitle(tbInfo.szIcon2)
    self:SetLabelAccessory(tbInfo.szName)

    if tbInfo.szName == "收藏" then
        self:SetLabelEmpty("暂无收藏的特效")
    else
        self:SetLabelEmpty(string.format("暂无符合条件的%s", tbInfo.szName))
    end
end

function UICharacterPendantEffectPage:UpdateListInfo()
    local nBegin, nEnd, tFiltedSearchList, dwMaxPageCount, dwCurrentPage = CharacterEffectData.GetSelectList(self.nCurSelectedIndex)
    self.tbScriptEffectCell = self.tbScriptEffectCell or {}

    for i, scriptCell in ipairs(self.tbScriptEffectCell) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end

    self:ShowWidgetEmpty(table.is_empty(tFiltedSearchList))
    -- UIHelper.SetVisible(self.WidgetEffectPaginate, not table.is_empty(tFiltedSearchList))

    local nCellIndex = 1
    local nMaxNum = #tFiltedSearchList
    for i = nBegin, nEnd, 1 do
        if i > nMaxNum then
            break
        end

        local tbInfo = tFiltedSearchList[i]
        local scriptCell = self.tbScriptEffectCell[nCellIndex]
        if not scriptCell then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryEffect, self.ScrollViewEffectList)
            table.insert(self.tbScriptEffectCell, scriptCell)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupEffectList, scriptCell.TogAccessoryEffect)
        end

        scriptCell:OnEnter(tbInfo, self.nCurSelectedIndex)
        -- scriptCell:SetClickCallback(function(nTabType, nTabID)
        --     UIHelper.SetSelected(self.TogSift, false)

        --     if nTabType and nTabID then
        --         self.nCurSelectedEffectID = nTabID
        --     end

        --     local player = PlayerData.GetClientPlayer()

        --     if CharacterEffectData.IsEffectAcquired(tbInfo.dwEffectID, player) then
        --         if CharacterEffectData.IsEffectUsing(tbInfo.dwEffectID, player) then
        --             self:OnEquipEffect(tbInfo.dwEffectID)
        --         else
        --             self:OnEquipEffect(tbInfo.dwEffectID)
        --         end
        --     else
        --         TipsHelper.ShowNormalTip("暂未获得，无法穿戴，长按可查看详情")
        --         UIHelper.SetSelected(scriptCell.TogAccessoryEffect, false)
        --     end
        -- end)
        scriptCell:SetClickCallback(function(nTabType, nTabID)
            UIHelper.SetSelected(self.TogSift, false)

            if nTabType and nTabID then
                self.nCurSelectedEffectID = nTabID
            end

            local player = PlayerData.GetClientPlayer()

            if not self.scriptItemTip then
                 self.scriptItemTip = self:GetItemTips()
             end

             if self.nCurSelectedEffectID == nTabID then
                self.scriptItemTip:OnInitWithTabID("Effect", tbInfo.dwEffectID)
                local tbBtnState = {}

                if CharacterEffectData.IsEffectAcquired(tbInfo.dwEffectID, player) then
                    if CharacterEffectData.IsEffectUsing(tbInfo.dwEffectID, player) then
                        table.insert(tbBtnState, {szName = "脱下", OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            self:OnEquipEffect(tbInfo.dwEffectID)
                        end})
                        if CharacterEffectData.GetType(self.nCurSelectedIndex) == "CircleBody" then
                            table.insert(tbBtnState, {szName = "自定义", OnClick = function()
                                Event.Dispatch(EventType.HideAllHoverTips)
                                Event.Dispatch(EventType.OpenCloseCharacterCustomEffect, true)
                            end})
                        end
                    else
                        table.insert(tbBtnState, {szName = "穿戴", OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            self:OnEquipEffect(tbInfo.dwEffectID)
                        end})
                    end
                end

                if CharacterEffectData.IsPreferEffect(tbInfo.dwEffectID) then
                    table.insert(tbBtnState, {szName = g_tStrings.STR_PENDANT_UNSTAR, OnClick = function ()
                        Event.Dispatch(EventType.HideAllHoverTips)
                        RemoteCallToServer("On_Pendent_UnstarEffect", tbInfo.dwEffectID)
                    end})
                else
                    table.insert(tbBtnState, {szName = g_tStrings.STR_PENDANT_STAR, OnClick = function ()
                        Event.Dispatch(EventType.HideAllHoverTips)
                        RemoteCallToServer("On_Pendent_StarEffect", tbInfo.dwEffectID)
                    end})
                end

                self.scriptItemTip:SetBtnState(tbBtnState)
             end
        end)
        UIHelper.SetVisible(scriptCell._rootNode, true)

        nCellIndex = nCellIndex + 1
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEffectList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewEffectList, self.WidgetArrow)

    self:ClearSelect()

    RedpointHelper.Effect_ClearByType(self.nCurSelectedIndex)
end

function UICharacterPendantEffectPage:OnEquipEffect(nEffectID)
    CharacterEffectData.EquipEffect(nEffectID)
end

function UICharacterPendantEffectPage:ClearSelect()
    if self.tbScriptEffectCell then
        for i, scriptCell in ipairs(self.tbScriptEffectCell) do
            scriptCell:SetSelected(false)
        end
    end
end

function UICharacterPendantEffectPage:OnClickBtnFastTakeOff()
    local player = PlayerData.GetClientPlayer()
    for index, tbInfo in ipairs(CharacterEffectData.tEffectFiltedList) do
        if CharacterEffectData.IsEffectUsing(tbInfo.dwEffectID, player) then
            CharacterEffectData.EquipEffect(tbInfo.dwEffectID)
        end
    end
end

return UICharacterPendantEffectPage