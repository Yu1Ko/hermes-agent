-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShortcutInteraction
-- Date: 2023-01-10 16:14:36
-- Desc: 快捷方式交互脚本
-- ---------------------------------------------------------------------------------

-- 预制上绑定的参数
-- @ LabelName      快捷名称
-- @ nIndex         槽位ID
---@class UIShortcutInteraction
local UIShortcutInteraction = class("UIShortcutInteraction")

local DEFAULT_FONT_SIZE = 24
local MOBILE_FONT_SIZE = 24
local SMALL_FONT_SIZE = 20

function UIShortcutInteraction:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bIsHD = SkillData.IsUsingHDKungFu()
    end
    self.nFontSize = Platform.IsMobile() and MOBILE_FONT_SIZE or DEFAULT_FONT_SIZE
    UIHelper.SetFontSize(self.LabelKey, self.nFontSize)
    self:RefreshUI()
end

function UIShortcutInteraction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShortcutInteraction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShortcut, EventType.OnClick, function()
        self:OnKeyBoardClick()
    end)
end

function UIShortcutInteraction:RegEvent()
    if Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileSupportKeyboard() then
        Event.Reg(self, "OnClickKeyboardSetting", function(nKeyIndex)
            local szState = self.szForceState
            if szState then
                self.shortcutInfo = SHORTCUT_INTERACTION[szState][self.nIndex] or SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][self.nIndex]
                if self.shortcutInfo and nKeyIndex == self.shortcutInfo.nType then
                    self:OnKeyBoardClick(true)
                else
                    self:OnKeyBoardCancel()
                end
            end
        end)

        Event.Reg(self, EventType.HideAllHoverTips, function()
            if self.WidgetSelected then
                UIHelper.SetVisible(self.WidgetSelected, false)
            end

            if self.BtnShortcut and self.BtnShortcut.setSelected then
                UIHelper.SetSelected(self.BtnShortcut, false)
            end
        end)

        Event.Reg(self, EventType.OnShortcutInteractionMultiKeyDown, function(tbKeyNames, nKeybordLen)
            if self:isKeyEventInvalid(tbKeyNames) then
                return
            end

            -- 触发组合键位
            if self:checkKeyMatching(tbKeyNames, self.tbKeyNames, nKeybordLen) then
                ShortcutInteractionData.tbKeyboardUpVKNames = nil

                --若触发了组合键，则不触发单键
                ShortcutInteractionData.SwallowSingleKey(tbKeyNames)

                self:ParseCommand(true)
            end
        end)

        Event.Reg(self, EventType.OnShortcutInteractionSingleKeyDown, function(szVKName)
            if self:isKeyEventInvalid(szVKName) then
                return
            end

            -- 触发单键
            if self.shortcutInfo.szVKName == szVKName then
                ShortcutInteractionData.szLastKeyboardName = ""
                self:ParseCommand(true)
            end
        end)

        Event.Reg(self, EventType.OnShortcutInteractionMultiKeyUp, function(tbKeyNames, nKeybordLen)
            if self:isKeyEventInvalid(tbKeyNames) then
                return
            end

            -- 触发组合键位
            if not self:checkKeyMatching(ShortcutInteractionData.tbKeyboardUpVKNames, tbKeyNames, -1) then
                if self:checkKeyMatching(tbKeyNames, self.tbKeyNames, nKeybordLen) then
                    ShortcutInteractionData.tbKeyboardUpVKNames = tbKeyNames

                    --若触发了组合键，则不触发单键
                    ShortcutInteractionData.SwallowSingleKey(tbKeyNames)

                    if not self:ParseCommand(false) then
                        --用于打坐等按钮，在战斗按钮隐藏时快捷键也能生效的情况
                        LOG.INFO("FuncSlotMgr.ExecuteCommand By Shortcut, %s", tostring(self.shortcutInfo.interactionFunction))
                        FuncSlotMgr.ExecuteCommand(self.shortcutInfo.interactionFunction)
                    end
                end
            end
        end)

        Event.Reg(self, EventType.OnShortcutInteractionSingleKeyUp, function(szVKName)
            if self:isKeyEventInvalid(szVKName) then
                return
            end

            -- 触发单键
            if ShortcutInteractionData.szLastKeyboardName ~= szVKName and self.shortcutInfo.szVKName == szVKName then
                ShortcutInteractionData.szLastKeyboardName = szVKName
                if not self:ParseCommand(false) then
                    --用于打坐等按钮，在战斗按钮隐藏时快捷键也能生效的情况
                    LOG.INFO("FuncSlotMgr.ExecuteCommand By Shortcut, %s", tostring(self.shortcutInfo.interactionFunction))
                    FuncSlotMgr.ExecuteCommand(self.shortcutInfo.interactionFunction)
                end
            end
        end)
    end

    Event.Reg(self, EventType.OnShortcutInteractionChange, function()
        if self.bEnterCustomState and not self.bIsCustom and QTEMgr.IsInDynamicSkillState() then
            return
        end
        
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function(tbFontShow, nNodeType)
        if nNodeType == CUSTOM_TYPE.SKILL and self.bCanHide then
            UIHelper.SetVisible(self.LabelKey, tbFontShow[nNodeType])
        end
    end)

    Event.Reg(self, "OnMobileKeyboardConnected", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "OnMobileKeyboardDisConnected", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnGamepadTypeChanged, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_ENTER_CUSTOMIZATION", function (nMode, bEnter, bSave)
        self.bEnterCustomState = bEnter
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        self.bIsHD = SkillData.IsUsingHDKungFu()
    end)
end

function UIShortcutInteraction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIShortcutInteraction:SetID(nID, szForceState, bCanHide, nShortcutType)
    self.ImgNumberBg = UIHelper.FindChildByName(self._rootNode, "ImgNumberBg")
    if self.ImgNumberBg then
        self.LabelKey = UIHelper.FindChildByName(self.ImgNumberBg, "LabelKey")
    end
    self.nIndex = nID
    self.szForceState = szForceState
    self.bCanHide = bCanHide
    self.nShortcutType = nShortcutType
end

function UIShortcutInteraction:RefreshUI()
    self:UpdateInfo()
    UIHelper.SetVisible(self.ImgNumberBg, not string.is_nil(self.szCurLabelContent))
    if self.bCanHide then
        UIHelper.SetVisible(self.LabelKey, Storage.ControlMode.tbFontShow[CUSTOM_TYPE.SKILL])
    end
end

function UIShortcutInteraction:SetKeyBoardProps(BtnShortcut, WidgetSelected)
    self.BtnShortcut = BtnShortcut
    self.WidgetSelected = WidgetSelected
    self:BindUIEvent()
end

function UIShortcutInteraction:OnKeyBoardClick(bFromEvent)
    local szState = self.szForceState or ShortcutInteractionData.szCurrentState
    self.shortcutInfo = SHORTCUT_INTERACTION[szState][self.nIndex] or SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][self.nIndex]

    local bSelected = false
    if self.BtnShortcut.setSelected then
        bSelected = UIHelper.GetSelected(self.BtnShortcut)
        if bFromEvent then
            UIHelper.SetSelected(self.BtnShortcut, true)
            if not UIHelper.GetHierarchyVisible(self._rootNode) then
                Event.Dispatch(EventType.OnKeyboardSettingSwitchPage)
            end
        end
    else
        bSelected = UIHelper.GetVisible(self.WidgetSelected)
        bSelected = not bSelected
        UIHelper.SetVisible(self.WidgetSelected, bSelected)
    end

    if self.shortcutInfo then
        if bFromEvent ~= true then
            local nType = self.nShortcutType == SHORTCUT_SHOW_TYPE.GAMEPAD and self.nIndex or self.shortcutInfo.nType
            Event.Dispatch("OnSkillSettingSelectChange", nType, bSelected)
        end
    else
        LOG.ERROR("no shortcut info " .. self.nIndex)
    end
end

function UIShortcutInteraction:OnKeyBoardCancel()
    if self.BtnShortcut.setSelected then
        UIHelper.SetSelected(self.BtnShortcut, false)
    else
        UIHelper.SetVisible(self.WidgetSelected, false)
    end
end

-- ----------------------------------------------------------
-- Please write your own code below
-- ----------------------------------------------------------

function UIShortcutInteraction:isKeyEventInvalid(tbKeyNames)
    if not ShortcutInteractionData.IsEnableKeyBoard then
        return true
    end
    if not g_pClientPlayer then
        return true
    end
    if not self.shortcutInfo then
        return true
    end

    tbKeyNames = IsTable(tbKeyNames) and tbKeyNames or { tbKeyNames }
    for _, szVKName in pairs(tbKeyNames) do
        if szVKName == "MouseWheelDown" or szVKName == "MouseWheelUp" then
            local bHandled = cc.utils:getMouseWheelHandled()
            if bHandled then
                return true
            end
        end
    end

    return false
end

function UIShortcutInteraction:checkKeyMatching(tbTargetKeys, tbSrcKeys, nKeybordLen)
    if tbTargetKeys == nil then
        return false
    end
    if nKeybordLen == self.nKeyNameCount or nKeybordLen == -1 then
        for k, v in pairs(tbTargetKeys) do
            if not table.contain_value(tbSrcKeys, v) then
                return false
            end
        end
    else
        return false
    end
    return true
end

function UIShortcutInteraction:UpdateInfo()
    local szState = self.szForceState or ShortcutInteractionData.szCurrentState
    self.shortcutInfo = SHORTCUT_INTERACTION[szState][self.nIndex] or SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common][self.nIndex]
    if self.shortcutInfo then
        if ShortcutInteractionData.IsSprintState() and SHORTCUT_INTERACTION[ShortcutInteractionData.szCurrentState][self.nIndex] then
            local tbKeyInfo = IsTable(self.shortcutInfo.szVKName) and self.shortcutInfo.szVKName
            local szKeyName = "" --在UIWidgetRightBottonFunction中统一管理按键的触发 --ShortcutInteractionData.GetKeyByDXBinding(tbKeyInfo and tbKeyInfo.szKeyName or "")
            local szKeyDesc = string.gsub(tbKeyInfo and tbKeyInfo.szKeyDesc or "", "<([%w_]+)>", function(szKey)
                return ShortcutInteractionData.GetKeyByDXBinding(szKey)
            end)
            self:UpdateKeyInfo(szKeyName, szKeyDesc, self.shortcutInfo.szGamepadName, self.shortcutInfo.szFuncName, self.shortcutInfo.nIconSize)
        else
            self:UpdateKeyInfo(self.shortcutInfo.szVKName, self.shortcutInfo.szVKName, self.shortcutInfo.szGamepadName, self.shortcutInfo.szFuncName, self.shortcutInfo.nIconSize)
        end
        local bVisible = not self.shortcutInfo.bHide and (self.LabelKey.setXMLData ~= nil or not string.is_nil(UIHelper.GetString(self.LabelKey))) -- LabelKey 为RichText时显示
        UIHelper.SetVisible(self._rootNode, bVisible)
    else
        self.tbKeyNames = {}
        self.nKeyNameCount = 0
        UIHelper.SetVisible(self._rootNode, false)
    end
    if ShortcutInteractionData.IsEnableVisibleMode then
        UIHelper.SetLabel(self.LabelKey, self.nIndex)
        UIHelper.SetVisible(self._rootNode, true)
    end
    if self.bCanHide then
        UIHelper.SetVisible(self.LabelKey, Storage.ControlMode.tbFontShow[CUSTOM_TYPE.SKILL])
    end
end

function UIShortcutInteraction:UpdateKeyInfo(szKeyName, szKeyDesc, szGamepadName, szFuncName, nIconSize)
    self.tbKeyNames = string.split(szKeyName, "+")
    self.nKeyNameCount = table.get_len(self.tbKeyNames)
    local nKeyDescCount = table.get_len(string.split(szKeyDesc, "+"))

    if not self.LabelKey then
        return
    end

    local bGamepadMode = self.nShortcutType == SHORTCUT_SHOW_TYPE.GAMEPAD or (not self.nShortcutType and GamepadData.IsGamepadMode())
    local bKeyboardMode = self.nShortcutType == SHORTCUT_SHOW_TYPE.KEYBOARD or (not self.nShortcutType and not Channel.Is_WLColud() and (Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileHasKeyboard()))


    local szLabelName
    if Const.bShowShortcutInterationKeyName then
        if bGamepadMode and not string.is_nil(szGamepadName) and self.LabelKey.setXMLData then
            local bLongFuncName = GetStringCharCount(szFuncName) > 2
            local tSplit = string.split(szGamepadName,'+')
            local bMultiKey = tSplit and #tSplit > 1
            szLabelName = string.format("%s%s", szFuncName, ShortcutInteractionData.GetGamepadViewName(szGamepadName, bLongFuncName and bMultiKey))
        elseif bKeyboardMode and not string.is_nil(szKeyDesc) then
            szLabelName = string.format("%s[%s]", szFuncName, ShortcutInteractionData.GetKeyViewName(szKeyDesc, self.nKeyNameCount > 1 or nKeyDescCount > 1, SHORTCUT_ICON_TYPE.MAINCITY, nIconSize))
        else
            szLabelName = szFuncName
        end

        if not string.is_nil(szLabelName) then
            local szPureText = string.gsub(szLabelName, "<.->", "____") --图标换为占位符，用于计算文本长度
            local nWidth = UIHelper.GetUtf8RichTextWidth(szPureText, Platform.IsMobile() and MOBILE_FONT_SIZE or DEFAULT_FONT_SIZE)
            local nFontSize
            if nWidth > 150 and not self.bIsHD then
                nFontSize = SMALL_FONT_SIZE
            elseif Platform.IsMobile() then
                nFontSize = MOBILE_FONT_SIZE
            else
                nFontSize = DEFAULT_FONT_SIZE
            end
            if nFontSize ~= self.nFontSize then
                self.nFontSize = nFontSize
                UIHelper.SetFontSize(self.LabelKey, self.nFontSize)
                nWidth = UIHelper.GetUtf8RichTextWidth(szPureText, self.nFontSize)
            end
            UIHelper.SetWidth(self.LabelKey, nWidth + 24)
            UIHelper.LayoutDoLayout(self.ImgNumberBg)
        end
    end

    if string.is_nil(szLabelName) then
        szLabelName = szFuncName
    end
    self.szCurLabelContent = szLabelName
    if self.LabelKey.setXMLData then
        szLabelName = string.format("<outline=#121E27&2>%s</u>", szLabelName) --描边
    end

    UIHelper.SetLabel(self.LabelKey, szLabelName)
    UIHelper.SetVisible(self.ImgNumberBg, not string.is_nil(self.szCurLabelContent))
end

function UIShortcutInteraction:SetLabelKey(szLabelName)
    UIHelper.SetLabel(self.LabelKey, szLabelName)
end

function UIShortcutInteraction:MainViewBtnFuncSlot_1(bIsDown)
    self:_BtnSlotFunction(1, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_2(bIsDown)
    self:_BtnSlotFunction(2, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_3(bIsDown)
    self:_BtnSlotFunction(3, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_4(bIsDown)
    self:_BtnSlotFunction(4, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_5(bIsDown)
    self:_BtnSlotFunction(5, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_6(bIsDown)
    self:_BtnSlotFunction(6, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_7(bIsDown)
    self:_BtnSlotFunction(7, true, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_8(bIsDown)
    self:_BtnSlotFunction(8, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end
function UIShortcutInteraction:MainViewBtnFuncSlot_9(bIsDown)
    self:_BtnSlotFunction(9, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight, bIsDown)
end

function UIShortcutInteraction:SkillSlot_7(bIsDown)
    self:_BtnSlotFunction(7, true, bIsDown)
end
function UIShortcutInteraction:SkillSlot_8(bIsDown)
    self:_BtnSlotFunction(8, true, bIsDown)
end
function UIShortcutInteraction:SkillSlot_9(bIsDown)
    self:_BtnSlotFunction(9, true, bIsDown)
end
function UIShortcutInteraction:SkillSlot_10(bIsDown)
    self:_BtnSlotFunction(10, true, bIsDown)
end
function UIShortcutInteraction:SkillSlot_11(bIsDown)
    self:_BtnSlotFunction(11, true, bIsDown)
end

function UIShortcutInteraction:ParseCommand(bIsDown)
    if self[self.shortcutInfo.interactionFunction] then
        LOG.INFO("Execute interactionFunction: %s (%s)", tostring(self.shortcutInfo.interactionFunction), bIsDown and "DOWN" or "UP")
        self[self.shortcutInfo.interactionFunction](self, bIsDown)
        return true
    end

    local szFuncName = self.shortcutInfo.interactionFunction
    if string.starts(szFuncName, DX_SKILL_SHORTCUT_EVENT) then
        local tSpilt = string.split(szFuncName, DX_SKILL_SHORTCUT_EVENT)
        local nSlotIndex = tonumber(tSpilt[2])
        self:DXMainViewExecution(nSlotIndex, bIsDown)
        return true
    end

    if string.starts(szFuncName, DX_DAOZONG_EVENT) then
        local tSpilt = string.split(szFuncName, DX_DAOZONG_EVENT)
        local nSlotIndex = tonumber(tSpilt[2])
        Event.Dispatch(DX_DAOZONG_EVENT, nSlotIndex, bIsDown)
        return true
    end
    
    return false
end

function UIShortcutInteraction:DXMainViewExecution(nSlotIndex, bIsDown)
    if table.contain_value(SkillData.tDXSprintSlots, nSlotIndex) or nSlotIndex >= SpecialDXSkillData.GetBaseSlot() then
        self:_BtnSlotFunction(nSlotIndex, true, bIsDown)
    else
        self:_BtnSlotFunction(nSlotIndex, ShortcutInteractionData.szCurrentState == SHORTCUT_KEY_BOARD_STATE.DXFight, bIsDown)
    end
end

function UIShortcutInteraction:ActionBarSlot_1(bIsDown)
    self:_BtnActionBarSlotFunction(1, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_2(bIsDown)
    self:_BtnActionBarSlotFunction(2, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_3(bIsDown)
    self:_BtnActionBarSlotFunction(3, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_4(bIsDown)
    self:_BtnActionBarSlotFunction(4, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_5(bIsDown)
    self:_BtnActionBarSlotFunction(5, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_6(bIsDown)
    self:_BtnActionBarSlotFunction(6, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_7(bIsDown)
    self:_BtnActionBarSlotFunction(7, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_8(bIsDown)
    self:_BtnActionBarSlotFunction(8, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_9(bIsDown)
    self:_BtnActionBarSlotFunction(9, bIsDown)
end
function UIShortcutInteraction:ActionBarSlot_10(bIsDown)
    self:_BtnActionBarSlotFunction(10, bIsDown)
end

function UIShortcutInteraction:ActionBarSwitch(bIsDown)
    Event.Dispatch(EventType.OnActionBarSwitchState)
end

function UIShortcutInteraction:TargetLockFunc(bIsDown)
    if not bIsDown then
        Event.Dispatch(EventType.OnShortcutAttention)
    end
end

function UIShortcutInteraction:_BtnActionBarSlotFunction(nIndex, bIsDown)
    Event.Dispatch(EventType.OnActionBarBtnClick, nIndex, bIsDown)
end

function UIShortcutInteraction:AttackClicked(bIsDown)
    if bIsDown then
        return
    end
    SprintData.SetViewState(false)
end
function UIShortcutInteraction:_BtnSlotFunction(nSlotIndex, bFight, bIsDown)
    if bFight then
        Event.Dispatch(EventType.OnShortcutUseSkillSelect, nSlotIndex, bIsDown and 1 or 3)
    else
        Event.Dispatch(EventType.OnMainViewButtonSlotClick, nSlotIndex, bIsDown)
    end
end
-- 滑翔
function UIShortcutInteraction:SkillRoll(bIsDown)
    self:_BtnSlotFunction(10, true, bIsDown)
end

-- 跳跃
function UIShortcutInteraction:SkillJump(bIsDown)
    if bIsDown then
        Jump()
    else
        EndJump()
    end
end
-- 单个物品拾取/任务/对话/
function UIShortcutInteraction:FastSceneInteract(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnSceneInteractByHotkey, false)
end
-- 全部物品拾取
function UIShortcutInteraction:AllFastPick(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnSceneInteractByHotkey, true)
end

function UIShortcutInteraction:TargetSelect(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnShortcutTargetSelect)
end

function UIShortcutInteraction:FuYao(bIsDown)
    if bIsDown then
        return
    end
    SkillMgr.FuYao()
end

function UIShortcutInteraction:SkillAuto(bIsDown)
    if bIsDown then
        return
    end
    Event.Dispatch(EventType.OnShortcutSkillAuto)
end

function UIShortcutInteraction:SkillQuick(bIsDown)
    Event.Dispatch(EventType.OnShortcutSkillQuick, bIsDown and 1 or 3)
end

function UIShortcutInteraction:Transfer(bIsDown)
    if bIsDown then
        return
    end
    --神行（在浪客行中则为回城）
    if TravellingBagData.IsInTravelingMap() then
        FuncSlotMgr.ExecuteCommand("LangKeXingReturnCity")
    else
        FuncSlotMgr.ExecuteCommand("Transfer")
    end
end

function UIShortcutInteraction:RideHorse(bIsDown)
    if bIsDown then
        return
    end
    --骑马（在浪客行中则为一键上马）
    if TravellingBagData.IsInTravelingMap() then
        FuncSlotMgr.ExecuteCommand("LangKeXingRideHorse")
    else
        FuncSlotMgr.ExecuteCommand("RideHorse")
    end
end

function UIShortcutInteraction:ArtistIdentityFuncSlot_1(bIsDown)
    self:_BtnArtistSlotFunction(1, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_2(bIsDown)
    self:_BtnArtistSlotFunction(2, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_3(bIsDown)
    self:_BtnArtistSlotFunction(3, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_4(bIsDown)
    self:_BtnArtistSlotFunction(4, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_5(bIsDown)
    self:_BtnArtistSlotFunction(5, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_6(bIsDown)
    self:_BtnArtistSlotFunction(6, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_7(bIsDown)
    self:_BtnArtistSlotFunction(7, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_8(bIsDown)
    self:_BtnArtistSlotFunction(8, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_9(bIsDown)
    self:_BtnArtistSlotFunction(9, bIsDown)
end
function UIShortcutInteraction:ArtistIdentityFuncSlot_10(bIsDown)
    self:_BtnArtistSlotFunction(10, bIsDown)
end

local ARTIST_SELECT_SKILL_TYPE = {
    SKILL = 1,
    PENDANT = 2,
    EMOTION = 3
}
function UIShortcutInteraction:_BtnArtistSlotFunction(nIndex, bIsDown)
    if bIsDown then
        return
    end
    local tSelSkill = Storage.ArtistSkills.tbSkillList
    local tbBtnData = tSelSkill[nIndex]
    if tbBtnData then
        if tbBtnData.nLevel and tbBtnData.nSkill then
            --技能
            Event.Dispatch("ON_USE_ARTIST_SKILL", ARTIST_SELECT_SKILL_TYPE.SKILL, nIndex, tbBtnData.nSkill, tbBtnData.nLevel)
        elseif tbBtnData.nTabType and tbBtnData.nTabIndex then
            Event.Dispatch("ON_USE_ARTIST_SKILL", ARTIST_SELECT_SKILL_TYPE.PENDANT, nIndex, tbBtnData.nTabType, tbBtnData.nTabIndex)
        elseif tbBtnData.nEmotionID then
            local actionData = EmotionData.GetEmotionAction(tbBtnData.nEmotionID)
            Event.Dispatch("ON_USE_ARTIST_SKILL", ARTIST_SELECT_SKILL_TYPE.EMOTION, nIndex, actionData.dwID)
        end
    end
end
function UIShortcutInteraction:SetCustomState(bCustom)
    self.bIsCustom = bCustom
end

return UIShortcutInteraction