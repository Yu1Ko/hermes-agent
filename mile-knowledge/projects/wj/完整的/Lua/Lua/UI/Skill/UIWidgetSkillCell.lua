-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tQixueColorFrame = {
    [1] = "UIAtlas2_Skill_SkillDX_qixue_fire",
    [2] = "UIAtlas2_Skill_SkillDX_qixue_lotus",
    [3] = "UIAtlas2_Skill_SkillDX_qixue_water",
    [4] = "UIAtlas2_Skill_SkillDX_qixue_cloud",
}

---@class UIWidgetSkillCell
local UIWidgetSkillCell = class("UIWidgetSkillCell")

local _nDragThreshold2 = 450

function UIWidgetSkillCell:OnEnter(nSkillID, nSkillLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        if nSkillID then
            self.nSkillID = nSkillID
            self.nSkillLevel = nSkillLevel
            self:UpdateInfo()
        end
    end
    self.tDXSlotData = nil
end

function UIWidgetSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillCell:BindUIEvent()

end

function UIWidgetSkillCell:RegEvent()
    Event.Reg(self, "SKILL_UPDATE", function(arg0, arg1)
        if self.nSkillID == arg0 then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "MYSTIQUE_ACTIVE_UPDATE", function(dwSkillID)
        if dwSkillID == self.nSkillID then
            self:UpdateTag()
            self:UpdateMijiDot()
        end
    end)
end

function UIWidgetSkillCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSkillCell:UpdateInfo(nSkillID)
    if nSkillID and IsNumber(nSkillID) then
        self.nSkillID = nSkillID
    end

    if self.nSkillID then
        local nSkillLevel = self.nSkillLevel or g_pClientPlayer.GetSkillLevel(self.nSkillID)
        if not nSkillLevel or nSkillLevel == 0 then
            nSkillLevel = 1
        end

        local tSkill
        if nSkillLevel and nSkillLevel and nSkillLevel ~= 0 then
            tSkill = GetSkill(self.nSkillID, nSkillLevel)
        end

        if not tSkill then
            return
        end

        if tSkill.nPlatformType == SkillPlatformType.Mobile then
            local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
            if tSkillInfo then
                self:SetLabel(self.LabelSkillName, tSkillInfo.szName)
            end
        else
            local szName = Table_GetSkillName(self.nSkillID, nSkillLevel)
            self:SetLabel(self.LabelSkillName, UIHelper.GBKToUTF8(szName))
        end

        local szImgPath = TabHelper.GetSkillIconPath(self.nSkillID) or
                TabHelper.GetSkillIconPathByIDAndLevel(self.nSkillID, nSkillLevel)
        if not string.find(szImgPath, "Resource/icon/") and not string.find(szImgPath, "Resource\\icon\\") then
            szImgPath = "Resource/icon/" .. szImgPath
        end

        local tMonsterBookSkillInfo = Table_GetMonsterSkillInfo(self.nSkillID)
        if #tMonsterBookSkillInfo > 0 then
            local szImgFramePath = MonsterBookData.GetEdgeRoundFramePath(tMonsterBookSkillInfo.nColor)
            UIHelper.SetSpriteFrame(self.ImgBaiZhanColor, szImgFramePath)
        end

        UIHelper.SetVisible(self.ImgSkillIcon, true)
        UIHelper.SetVisible(self.ImgSkillEmpty, false)
        UIHelper.SetTexture(self.ImgSkillIcon, szImgPath, true, function()
            UIHelper.UpdateMask(self.MaskSkill)
        end)

        UIHelper.SetVisible(self.ImgUpgrade, false)
        UIHelper.SetVisible(self.ImgBaiZhanColor, #tMonsterBookSkillInfo > 0)
        self:UpdateTag()
    end
end

---@param tSlotData DXSlotData
function UIWidgetSkillCell:UpdateInfoDX(tNewSlotData)
    self.tSlotData = tNewSlotData or self.tSlotData
    local nMaxNameLen = 4
    local tSlotData = self.tSlotData
    if self.tSlotData then
        if tSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            self:UpdateInfo(tSlotData.data1)
            self:UpdateMijiDot(true)
        elseif tSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
            self:UpdateByIconID(GetMacroIcon(tSlotData.data1), tSlotData.data1)
        elseif tSlotData.nType == DX_ACTIONBAR_TYPE.EQUIP or tSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
            local item = tSlotData.nType == DX_ACTIONBAR_TYPE.EQUIP and SkillData.GetDXSlotEquip(tSlotData) or
                    ItemData.GetItemInfo(tSlotData.data1, tSlotData.data2)
            if item then
                local bResult = UIHelper.SetItemIconByItemInfo(self.ImgSkillIcon, item, nil, true, function()
                    UIHelper.UpdateMask(self.MaskSkill)
                end)
                if not bResult then
                    UIHelper.ClearTexture(self.ImgSkillIcon)
                end

                self:SetLabel(self.LabelSkillName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(item.szName), nMaxNameLen))
            end
        end
    end
end

function UIWidgetSkillCell:UpdateByIconID(nIconID, nMacroID)
    local nMaxNameLen = 4
    local bResult = UIHelper.SetItemIconByIconID(self.ImgSkillIcon, nIconID, true, function()
        UIHelper.UpdateMask(self.MaskSkill)
    end)
    if not bResult then
        UIHelper.ClearTexture(self.ImgSkillIcon)
    end
    if nMacroID and GetMacroName(nMacroID) then
        self:SetLabel(self.LabelSkillName, UIHelper.LimitUtf8Len(GetMacroName(nMacroID), nMaxNameLen))
    end
end

function UIWidgetSkillCell:GetToggle()
    return self.TogSkill
end

function UIWidgetSkillCell:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nTouchBeganX, self.nTouchBeganY = nX, nY
        self.bDragging = false
        return true
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.bDragging then
            local dx = nX - self.nTouchBeganX
            local dy = nY - self.nTouchBeganY
            local dx2 = dx * dx
            local dy2 = dy * dy
            if dx2 + dy2 > _nDragThreshold2 then
                self.bDragging = fnDragStart(nX, nY)  -- 成功触发拖动
            end
        end

        if self.bDragging then
            fnDragMoved(nX, nY)
        end

    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.bDragging then
            fnDragEnd(nX, nY)
            self.bDragging = false
        end

    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchCanceled, function(btn, nX, nY)
        if self.bDragging then
            fnDragEnd(nX, nY)
            self.bDragging = false
        end
    end)
end

function UIWidgetSkillCell:BindSelectFunction(fnFunction)
    if IsFunction(fnFunction) then
        UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(toggle, bSelected)
            if bSelected then
                fnFunction(self.nSkillID)
            end
        end)
    end
end

function UIWidgetSkillCell:BindExchangeFunction(fnFunction)
    if IsFunction(fnFunction) then
        UIHelper.SetVisible(self.BtnExchange, true)
        UIHelper.BindUIEvent(self.BtnExchange, EventType.OnClick, function()
            fnFunction(self.nSkillID)
        end)
    end
end

function UIWidgetSkillCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogSkill, bSelected)
end

function UIWidgetSkillCell:SetSelectEnable(bEnable)
    self.TogSkill:setEnabled(bEnable)
end

function UIWidgetSkillCell:SetToggleGroup(togGroup)
    UIHelper.ToggleGroupAddToggle(togGroup, self.TogSkill)
end

function UIWidgetSkillCell:SetUsed(bVisible)
    UIHelper.SetVisible(self.ImgUsed, bVisible)
end

function UIWidgetSkillCell:SetHighlight(bVisible)
    UIHelper.SetVisible(self.ImgHighLight, bVisible)
end

function UIWidgetSkillCell:ShowName(bEnable, nMaxLen)
    UIHelper.SetVisible(self.LabelSkillName, bEnable)

    if nMaxLen and IsNumber(nMaxLen) then
        local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
        self:SetLabel(self.LabelSkillName, UIHelper.LimitUtf8Len(tSkillInfo.szName, nMaxLen))
    end
end

function UIWidgetSkillCell:SetNewName(szName)
    self:ShowName(true)
    self:SetLabel(self.LabelSkillName, szName)
end

function UIWidgetSkillCell:HideLabel()
    UIHelper.SetVisible(self.ImgTypeBg, false)
    UIHelper.SetVisible(self.LabelSkillName, false)
    UIHelper.SetVisible(self.ImgQushan, false)
end

function UIWidgetSkillCell:ShowEffect()
    UIHelper.SetVisible(self.Eff_UI_WuXuePeiZhi, true)
    UIHelper.PlaySFX(self.Eff_UI_WuXuePeiZhi, false)
end

function UIWidgetSkillCell:SetRed(bVisible)
    UIHelper.SetVisible(self.ImgHintRed, bVisible)

end

function UIWidgetSkillCell:SetRedPoint(bVisible)
    UIHelper.SetVisible(self.ImgRedPoint, bVisible)

end

function UIWidgetSkillCell:GetSkillID()
    return self.nSkillID
end

function UIWidgetSkillCell:UpdateTag()
    if not self.nSkillID then
        return
    end
    local nTagType, bActive = SkillData.GetSpecialTag(self.nSkillID)
    local szPath = SkillTagInfo[nTagType] and SkillTagInfo[nTagType][bActive]
    if szPath then
        UIHelper.SetSpriteFrame(self.ImgQushan, szPath)
    end
    UIHelper.SetVisible(self.ImgQushan, szPath ~= nil)
end

function UIWidgetSkillCell:SetGrey(bGrey)
    UIHelper.SetNodeGray(self.ImgSkillIcon, bGrey)
end

function UIWidgetSkillCell:ShowEmptyState()
    UIHelper.SetVisible(self.ImgSkillIcon, false)
    UIHelper.SetVisible(self.ImgSkillEmpty, true)
end

function UIWidgetSkillCell:HideSkillBg()
    UIHelper.SetVisible(self.ImgSkillFrame1, false)
end

local tSkillID2FightIndex = {
    [UI_SKILL_DASH_ID] = 18,
    [UI_SKILL_FUYAO_ID] = 24,
    [UI_SKILL_JUMP_ID] = 17,
}

local nSpecialSprintShortcutSlot = 22

function UIWidgetSkillCell:ShowShortcutAndType(nSlotID)
    if not self.nSkillID then
        return
    end

    local nIndex = SkillData.tSlotId2FightIndex[nSlotID]
    local bSprint = false

    -- nIndex为空则当前槽位为轻功槽位
    if nIndex == nil then
        nIndex = tSkillID2FightIndex[self.nSkillID] or nSpecialSprintShortcutSlot
        bSprint = true
    end

    local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
    if not tSkillInfo then
        return
    end
    --UIHelper.SetVisible(self.ImgTypeBg, true)
    UIHelper.SetVisible(self.LabelSkillName, true)
    self:SetLabel(self.LabelSkillName, tSkillInfo.szSkillDefinition)

    local shortcutInfo = SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Fight][nIndex]
    local szFuncName = tSkillInfo and tSkillInfo.szSkillDefinition or ""
    local szVK = shortcutInfo.szVKName
    local szGamepad = shortcutInfo.szGamepadName
    local tbKeyNames = string.split(szVK, "+")
    local nKeyNameCount = table.get_len(tbKeyNames)

    local bGamepadMode = GamepadData.IsGamepadMode()
    local bKeyboardMode = Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileHasKeyboard()

    local szLabelName
    if Const.bShowShortcutInterationKeyName then
        if bGamepadMode and not string.is_nil(szGamepad) and self.LabelSkillName.setXMLData then
            szLabelName = string.format("%s%s", szFuncName, ShortcutInteractionData.GetGamepadViewName(szGamepad))
        elseif bKeyboardMode and not string.is_nil(szVK) then
            szLabelName = string.format("%s[%s]", szFuncName, ShortcutInteractionData.GetKeyViewName(szVK, nKeyNameCount > 1, SHORTCUT_ICON_TYPE.MAINCITY))
        end
    end

    if string.is_nil(szLabelName) then
        szLabelName = szFuncName
    end
    
    self:SetLabel(self.LabelSkillName, szLabelName)
end
function UIWidgetSkillCell:ShowShortcutDX(nSlotID)
    local nIndex = SkillData.tDXSlotID2FightIndex[nSlotID]
    if nIndex == nil and self.nSkillID then
        nIndex = SkillData.tDXSkillID2FightIndex[self.nSkillID]
    end

    if not nIndex then
        return
    end

    local shortcutInfo = SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.DXFight][nIndex]
    local szFuncName = UIHelper.GetLabel(self.LabelSkillName) or ""
    local szVK = shortcutInfo.szVKName
    local szGamepad = shortcutInfo.szGamepadName
    local tbKeyNames = string.split(szVK, "+")
    local nKeyNameCount = table.get_len(tbKeyNames)

    local bGamepadMode = GamepadData.IsGamepadMode()
    local bKeyboardMode = Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileHasKeyboard()

    local szLabelName
    if Const.bShowShortcutInterationKeyName then
        if bGamepadMode and not string.is_nil(szGamepad) then
            szLabelName = string.format("%s%s", szFuncName, ShortcutInteractionData.GetGamepadViewName(szGamepad))
        elseif bKeyboardMode and not string.is_nil(szVK) then
            szLabelName = string.format("%s[%s]", szFuncName, ShortcutInteractionData.GetKeyViewName(szVK, nKeyNameCount > 1, SHORTCUT_ICON_TYPE.MAINCITY))
        end
    end

    if string.is_nil(szLabelName) then
        szLabelName = szFuncName
    end

    self:SetLabel(self.LabelSkillName, szLabelName)
    UIHelper.SetVisible(self.LabelSkillName, true)
end

function UIWidgetSkillCell:ShowLearnLevel(nLevel)
    if nLevel then
        UIHelper.SetVisible(self.ImgTypeBg, false)
        UIHelper.SetVisible(self.LabelSkillName, true)

        self:SetLabel(self.LabelSkillName, nLevel .. "级学习")
    end
end

function UIWidgetSkillCell:ShowQuest(bShowTrace)
    if bShowTrace == nil then
        bShowTrace = true
    end
    
    UIHelper.SetVisible(self.ImgTypeBg, false)
    UIHelper.SetVisible(self.LabelSkillName, true)
    UIHelper.SetVisible(self.ImgTrace, bShowTrace)

    self:SetLabel(self.LabelSkillName, bShowTrace and g_tStrings.SKILL_LEARN_QUEST or g_tStrings.TALENT_LOCK_BY_QUEST)
end

function UIWidgetSkillCell:UpdateInfoWanLing(szFrame)
    if not szFrame then
        return
    end

    UIHelper.SetSpriteFrame(self.ImgSkillIcon, szFrame)
end

function UIWidgetSkillCell:SetQixueBg(nColorID)
    UIHelper.SetSpriteFrame(self.ImgQixueType, tQixueColorFrame[nColorID])
    UIHelper.SetVisible(self.ImgQixueType, nColorID ~= 0)
end

function UIWidgetSkillCell:SetLabel(node, szText)
    if node and node.setXMLData and szText then
        szText = string.format("<shadow=#121E27&2&-2>%s</u>", szText) --阴影
    end

    UIHelper.SetLabel(node, szText)
end

function UIWidgetSkillCell:UpdateLabelSize()
    local nScale = UIHelper.GetScale(self._rootNode)
    if nScale ~= 1 then
        nScale = 1 / nScale
        UIHelper.SetScale(self.WidgetExchange, nScale, nScale)
        UIHelper.SetScale(self.ImgTypeBg, nScale, nScale)
        UIHelper.SetScale(self.LabelSkillName, nScale, nScale)
    end
end

function UIWidgetSkillCell:UpdateMijiDot(bShow, bFake)
    if bShow ~= nil then
        self.bShowMijiDot = bShow
    end

    if self.bShowMijiDot and self.tMijiDots then
        local tList = SkillData.GetFinalRecipeList(self.nSkillID, g_pClientPlayer)
        local nActivated = 0
        for _, tRecipe in ipairs(tList) do
            if tRecipe.active then
                nActivated = nActivated + 1
            end
        end

        if bFake then
            nActivated = 4
        end

        for i = 1, #self.tMijiDots do
            local node = self.tMijiDots[i]
            UIHelper.SetVisible(node, nActivated >= i)
        end
        UIHelper.SetVisible(self.WidgetMijiDot, #tList > 0)
    else
        UIHelper.SetVisible(self.WidgetMijiDot, false)
    end
end

return UIWidgetSkillCell