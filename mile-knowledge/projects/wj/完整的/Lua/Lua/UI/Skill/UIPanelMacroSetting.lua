-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelMacroSetting
-- Date: 2025-7-24 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local _tUtf8Mask = { 0, 0xc0, 0xe0, 0xf0 }
local function GetUtf8Substring_128(szUtf8)
    if string.is_nil(szUtf8) then
        return ""
    end
    local nCodeSpecialR = string.byte("\r")
    local nLeft = string.len(szUtf8)
    local nLen = 0
    local nMaxLimit = 128
    while nLeft > 0 do
        local code = string.byte(szUtf8, -nLeft)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nLeft = nLeft - i
                break
            end
        end
        if code == nCodeSpecialR then
            nMaxLimit = nMaxLimit + 1
        else
            nLen = nLen + 1
        end

        if nLen >= nMaxLimit then
            break
        end
    end
    return UIHelper.GetUtf8SubString(szUtf8, 1, math.max(1, nLen))
end

local aIcon = {
    402, 403, 404, 405, 407, 408, 410, 411, 413, 414, 416,
    417, 418, 419, 420, 421, 422, 423, 424, 426, 427, 428,
    430, 432, 433, 434, 436, 437, 438, 440, 441, 607, 608,
    609, 610, 630, 631, 621, 617, 620, 621, 622, 623, 624,
    625, 626, 629, 630, 631, 634, 635, 636, 637, 638, 640,
    641, 642, 643, 644, 646, 647, 648, 649, 650, 652, 653,
    654, 655, 656, 886, 891, 892, 894, 895, 896, 897, 898,
    899, 900, 901, 902, 903, 904, 905, 906, 907, 908, 912,
    913, 914, 915, 1438, 1439, 1440, 1441, 1442, 1443, 1444, 1445,
    1446, 1447, 1448, 1449, 1450, 1452, 1453, 1454, 1455, 1456, 1482,
    1483, 1484, 1485, 1486, 1488, 1489, 1490, 1491, 1492, 1496, 1497,
    1498, 1499, 1500, 1501, 1502, 1503, 1504, 1505, 1506, 1507, 1508,
    1509, 1510, 1511, 1513, 1514, 1515, 1516, 1517, 1518, 1519, 1520,
    2240, 2242, 2247, 2249, 2256, 2259, 2264, 2269, 2274, 2276, 2271,
}

local nDescLimit = 60
local nMacroLimit = 128
local nMaxMacroCount = 11

local MacroSettingPanel = {}
function MacroSettingPanel.GetNewMacroName()
    local nIndex = 1
    local szName = FormatString(g_tStrings.MACRO_NEW_I, nIndex)
    while true do
        local bOk = true
        for k, v in pairs(g_Macro) do
            if IsNumber(k) and GetMacroName(k) == szName then
                nIndex = nIndex + 1
                szName = FormatString(g_tStrings.MACRO_NEW_I, nIndex)
                bOk = false
                break
            end
        end
        if bOk then
            break
        end
    end
    return szName
end

---@class UIPanelMacroSetting
local UIPanelMacroSetting = class("UIPanelMacroSetting")

function UIPanelMacroSetting:OnEnter(nCurrentKungFuID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nSelectedMacroID = nil
        self.nCurrentKungFuID = nCurrentKungFuID
    end

    self.tIConID2Script = {}
    for nIndex, nIconID in ipairs(aIcon) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.ScrollViewHongIcon)
        UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
        UIHelper.SetPositionY(script._rootNode, 0)
        script:UpdateByIconID(nIconID)
        script:SetToggleGroup(self.ToggleGroupRight)
        UIHelper.BindUIEvent(script.TogSkill, EventType.OnSelectChanged, function(toggle, bSelected)
            if bSelected then
                self.nIconID = nIconID
                self:UpdateApplyButtonState()
            end
        end)
        script.nOrder = nIndex - 1
        self.tIConID2Script[nIconID] = script
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHongIcon)

    UIHelper.SetMaxLength(self.EditHongName, 8)
    UIHelper.SetMaxLength(self.EditHongDescribe, 60)
    UIHelper.SetMaxLength(self.EditHongContent, 256)

    UIHelper.SetNodeSwallowTouches(self.BtnEditBoxTheme, false, true)

    Timer.AddFrame(self, 1, function()
        self:UpdateInfo()
    end)
end

function UIPanelMacroSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMacroSetting:BindUIEvent()
    local fnRegisterEditBox = function(editBox, fnCallBack)
        if Platform.IsWindows() or Platform.IsMac() then
            UIHelper.RegisterEditBoxChanged(editBox, fnCallBack)
        else
            UIHelper.RegisterEditBoxReturn(editBox, fnCallBack)
        end
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCreateNew, EventType.OnClick, function()
        self:AddNewMacro()
    end)
    UIHelper.BindUIEvent(self.BtnCreateNew1, EventType.OnClick, function()
        self:AddNewMacro()
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function()
        self:AppleMacroContent()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self:DeleteMacro()
    end)

    fnRegisterEditBox(self.EditHongDescribe, function()
        local szText = UIHelper.GetText(self.EditHongDescribe)
        UIHelper.SetString(self.LabelDescLimit, UIHelper.GetUtf8Len(szText) .. "/" .. nDescLimit)
        self:UpdateApplyButtonState()
    end)

    fnRegisterEditBox(self.EditHongName, function()
        self:UpdateApplyButtonState()
    end)

    --fnRegisterEditBox(self.EditHongContent, function()
    --    self:UpdateHongContentState()
    --    self:UpdateApplyButtonState()
    --end)

    UIHelper.BindUIEvent(self.BtnEditBoxTheme, EventType.OnClick, function()
        self.EditHongContent:openKeyboard()
        UIHelper.SetVisible(self.ScrollViewContent, false)
    end)

    self.EditHongContent:registerScriptEditBoxHandler(function(szType, _editbox)
        local bPhone = szType == "changed" and (Platform.IsWindows() or Platform.IsMac())
        local bKeyboard = szType == "return" and not (Platform.IsWindows() or Platform.IsMac())
        if bPhone or bKeyboard then
            self:UpdateHongContentState()
            self:UpdateApplyButtonState()
        elseif szType == "ended" then
            self:UpdateEditBoxTextEnd()
        end
    end)
end

function UIPanelMacroSetting:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.SetOpacity(self.ScrollViewHongIcon, 0)
        Timer.DelAllTimer(self)
        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutHongInfo)
            local iconScript = self.tIConID2Script[self.nIconID]
            if iconScript then
                UIHelper.ScrollLocateToPreviewItem(self.ScrollViewHongIcon, iconScript._rootNode, Locate.TO_CENTER)
            end
            UIHelper.SetOpacity(self.ScrollViewHongIcon, 255)
        end)
    end)
end

function UIPanelMacroSetting:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function GetMacroTotalNum()
    local nCount = 0
    for k, tMacro in pairs(g_Macro) do
        if IsNumber(k) and not IsMacroRemoved(k) then
            nCount = nCount + 1
        end
    end
    return nCount
end

function UIPanelMacroSetting:UpdateInfo()
    UIHelper.SetButtonState(self.BtnCreateNew, GetMacroTotalNum() < nMaxMacroCount and BTN_STATE.Normal or BTN_STATE.Disable,
            function()
                TipsHelper.ShowImportantYellowTip("宏数量已达最大上限")
            end)
    local nMacroNum = GetMacroTotalNum()
    UIHelper.SetVisible(self.WidgetCreateNewHong_empty, nMacroNum == 0)
    UIHelper.SetVisible(self.WidgetHongSettingList, nMacroNum > 0)
    UIHelper.SetVisible(self.LabelHongDescribeTitle, not Platform.IsWindows())
    UIHelper.SetVisible(self.LabelHongDescribeTitlePC, Platform.IsWindows())

    self:UpdateMacroList()
    self:UpdateMacroInfo()
end

function UIPanelMacroSetting:UpdateMacroList()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupLeft)
    UIHelper.RemoveAllChildren(self.ScrollViewHongSettingList)

    local nodeToScroll = nil
    local nCount = 0
    for k, tMacro in pairs(g_Macro) do
        if IsNumber(k) and not IsMacroRemoved(k) then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHongSettingTogCell, self.ScrollViewHongSettingList, k)
            script:SetToggleGroup(self.ToggleGroupLeft)
            script:BindSelectFunc(function(tog, bSelected)
                if bSelected then
                    self.nSelectedMacroID = k
                    self:UpdateMacroInfo()
                end
            end)

            if self.nSelectedMacroID == nil then
                self.nSelectedMacroID = k
            end
            if self.nSelectedMacroID == k then
                UIHelper.SetToggleGroupSelected(self.ToggleGroupLeft, nCount)
                nodeToScroll = script._rootNode
            end

            nCount = nCount + 1
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHongSettingList)
    UIHelper.ScrollLocateToPreviewItem(self.ScrollViewHongSettingList, nodeToScroll, Locate.TO_CENTER)
end

function UIPanelMacroSetting:UpdateMacroInfo()
    local tMacro = GetMacro(self.nSelectedMacroID)
    if tMacro then
        UIHelper.SetText(self.EditHongName, tMacro.szName)
        UIHelper.SetText(self.EditHongDescribe, tMacro.szDesc)
        UIHelper.SetText(self.EditHongContent, tMacro.szMacro)
        self.nIconID = tMacro.nIcon
        self.tMacro = tMacro
        self.szMacroText = tMacro.szMacro

        local iconScript = self.tIConID2Script[tMacro.nIcon]
        if iconScript then
            UIHelper.SetToggleGroupSelected(self.ToggleGroupRight, iconScript.nOrder)
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewHongIcon, iconScript._rootNode, Locate.TO_CENTER)
        end

        UIHelper.SetString(self.LabelDescLimit, (tMacro.szDesc and UIHelper.GetUtf8Len(tMacro.szDesc) or 0) .. "/" .. nDescLimit)
        UIHelper.SetString(self.LabelMacroLimit, (tMacro.szDesc and UIHelper.GetUtf8Len(tMacro.szMacro) or 0) .. "/" .. nMacroLimit)
    end
    
    UIHelper.SetVisible(self.WidgetMacroInfo, tMacro ~= nil)
    UIHelper.SetVisible(self.WidgetEmpty, tMacro == nil)
    UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable)

    self:UpdateHongContentState()
    self:UpdateEditBoxTextEnd()
end

function UIPanelMacroSetting:AddNewMacro()
    if GetMacroTotalNum() >= nMaxMacroCount then
        return
    end

    local szName = ""
    local szDesc = ""
    local szContent = ""
    local nIconID = nil

    if szName == "" then
        szName = MacroSettingPanel.GetNewMacroName()
    end
    if not nIconID then
        nIconID = aIcon[math.random(1, #(aIcon))]
    end

    self.nSelectedMacroID = AddMacro(szName, nIconID, szDesc, szContent)
    self:UpdateInfo()
    Event.Dispatch(EventType.OnDXMacroUpdate, self.nSelectedMacroID)
end

function UIPanelMacroSetting:DeleteMacro()
    local nMacroIDToRemove = self.nSelectedMacroID

    local nPreviousID = nil
    self.nSelectedMacroID = nil
    for k, tMacro in pairs(g_Macro) do
        if IsNumber(k) and not IsMacroRemoved(k) then
            if k == nMacroIDToRemove then
                self.nSelectedMacroID = nPreviousID
            end
            nPreviousID = k
        end
    end
    RemoveMacro(nMacroIDToRemove)
    Event.Dispatch(EventType.OnDXMacroUpdate, nMacroIDToRemove)
    self:UpdateInfo()
end

function UIPanelMacroSetting:AppleMacroContent()
    local szName = UIHelper.GetText(self.EditHongName)
    local szDesc = UIHelper.GetText(self.EditHongDescribe)
    local szContent = self.szMacroText
    local nIconID = self.nIconID

    if szName == "" then
        szName = MacroSettingPanel.GetNewMacroName()
    end

    SetMacro(self.nSelectedMacroID, szName, nIconID, szDesc, szContent)
    UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable)
    Event.Dispatch(EventType.OnDXMacroUpdate, self.nSelectedMacroID)

    self.tMacro = GetMacro(self.nSelectedMacroID)
end

function UIPanelMacroSetting:UpdateHongContentState()
    local szText = UIHelper.GetText(self.EditHongContent)

    local sztruncate = GetUtf8Substring_128(szText)
    local tsplit = string.split(sztruncate, "\r\n")

    local len = UIHelper.GetUtf8Len(szText)
    local nDiff = math.max(0, (#tsplit - 1))
    if len + #tsplit > nMacroLimit then
        UIHelper.SetMaxLength(self.EditHongContent, nMacroLimit + nDiff)
        szText = UIHelper.GetUtf8SubString(szText, 1, nMacroLimit + nDiff)
        UIHelper.SetText(self.EditHongContent, szText)
    end

    UIHelper.SetString(self.LabelMacroLimit, UIHelper.GetUtf8Len(szText) - nDiff .. "/" .. nMacroLimit)
end

function UIPanelMacroSetting:UpdateApplyButtonState()
    if self.tMacro then
        local bIdentical = true

        local szName = UIHelper.GetText(self.EditHongName)
        local szDesc = UIHelper.GetText(self.EditHongDescribe)
        local szContent = UIHelper.GetText(self.EditHongContent)

        bIdentical = bIdentical and szName == self.tMacro.szName
        bIdentical = bIdentical and szDesc == self.tMacro.szDesc
        bIdentical = bIdentical and szContent == self.tMacro.szMacro
        bIdentical = bIdentical and self.nIconID == self.tMacro.nIcon
        UIHelper.SetButtonState(self.BtnApply, not bIdentical and BTN_STATE.Normal or BTN_STATE.Disable)
        return
    end
    UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable)
end

function UIPanelMacroSetting:UpdateEditBoxTextEnd()
    UIHelper.SetVisible(self.EditHongContent, false)
    UIHelper.SetVisible(self.ScrollViewContent, true)

    local szContent = UIHelper.GetString(self.EditHongContent)
    self.szMacroText = szContent
    UIHelper.SetString(self.LabelContent, szContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

return UIPanelMacroSetting