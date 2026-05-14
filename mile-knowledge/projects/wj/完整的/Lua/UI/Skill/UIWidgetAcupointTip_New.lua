-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local SPECIAL_ORDER = 11
local SHOW_SCROLL_GUILD_CRITICAL_VALUE = -30
local tIndexToName = {
    [1] = "壹式",
    [2] = "贰式",
    [3] = "叁式",
    [4] = "肆式",
    [5] = "伍式",
    [6] = "陆式",
}

---@class UIWidgetAcupointTip_New
local UIWidgetAcupointTip_New = class("UIWidgetAcupointTip_New")

function UIWidgetAcupointTip_New:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bShowButton = true

        UIHelper.SetButtonState(self.BtnEquipped, BTN_STATE.Disable)
        UIHelper.SetTouchDownHideTips(self.ScrollViewSkillDetailsList, false)
    end
    self:PlayAnim()
end

function UIWidgetAcupointTip_New:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.fnClose then
        self.fnClose()
    end
end

function UIWidgetAcupointTip_New:BindUIEvent()

end

function UIWidgetAcupointTip_New:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetAcupointTip)
    end)
end

function UIWidgetAcupointTip_New:UnRegEvent()
    --Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAcupointTip_New:UpdateInfo()

end

function UIWidgetAcupointTip_New:Init(tQiXueSlot, bSelected, fnChangeQiXue, fnClose, tEquippedSkillIds, nCurrentKungFuID)
    self.fnClose = fnClose
    self.tEquippedSkillIds = tEquippedSkillIds
    self.dwLevel = tQiXueSlot.dwSkillLevel
    self.dwID = tQiXueSlot.dwSkillID
    self.bSelected = bSelected
    self.fnChangeQiXue = fnChangeQiXue
    self.nCurrentKungFuID = nCurrentKungFuID
    self.nIndex = 1

    local tSkill
    if self.dwID and self.dwLevel and self.dwLevel ~= 0 then
        tSkill = GetSkill(self.dwID, self.dwLevel)
    end
    if not tSkill then
        LOG.ERROR("NewSkillPanel.OpenQixue no skill dwID = " .. self.dwID .. " dwLevel = " .. self.dwLevel)
        return
    end

    self.bIsPassiveSkill = tSkill.bIsPassiveSkill
    if not self.bIsPassiveSkill then
        UIHelper.SetHeight(self._rootNode, 738)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end

    self:UpdateSkillList(self.dwID)
    self:UpdateToggles()
    self:UpdateBasicInfo()
end

function UIWidgetAcupointTip_New:SetPlayer(targetPlayer)
    self.targetPlayer = targetPlayer
end

function UIWidgetAcupointTip_New:UpdateBasicInfo()
    SkillData.ClearSpecialNoun()
    UIHelper.RemoveAllChildren(self.ScrollViewSkillDetailsList)
    UIHelper.RemoveAllChildren(self.WidgetSkillCell)

    local dwID = self.dwID
    local dwLevel = self.dwLevel
    local bIsPassiveSkill = self.bIsPassiveSkill

    local tSkillInfo = TabHelper.GetUISkill(dwID)
    local szSkillName = tSkillInfo and tSkillInfo.szName or UIHelper.GBKToUTF8(Table_GetSkillName(self.dwID, self.dwLevel))
    local szDesc = tSkillInfo and SkillData.ProcessSkillPlaceholder(tSkillInfo.szDesc) or nil
    local szCoreDesc = ""
    szDesc = szDesc and SkillData.FormSpecialNoun(tSkillInfo.szDesc, dwID)
    if not szDesc then
        local player = g_pClientPlayer
        szDesc, _, szCoreDesc = GetSkillDesc(self.dwID, self.dwLevel, nil, nil, false, player)
        szDesc = UIHelper.GBKToUTF8(szDesc)
        szCoreDesc = UIHelper.GBKToUTF8(szCoreDesc)

        local nSkillLevel = self.dwLevel or player.GetSkillLevel(self.dwID)
        local tRecipeKey = player.GetSkillRecipeKey(self.dwID, nSkillLevel)
        local nLevel = tRecipeKey.skill_level
        local tDescSkillInfo = Table_GetSkill(self.dwID, nSkillLevel)
        local szBasic = GetDxBasicTips(tRecipeKey.skill_id, nLevel, tDescSkillInfo, tRecipeKey, true, nil, player)
        if szBasic and szBasic ~= "" then
            szDesc = UIHelper.AttachTextColor(ParseTextHelper.ParseNormalText(szBasic), FontColorID.Text_Level2_Backup) .. "\n" .. szDesc
        end
    end

    local nPrefabID = bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
    local script = UIHelper.AddPrefab(nPrefabID, self.WidgetSkillCell, dwID, dwLevel) ---@type UIWidgetSkillCell
    script:SetSelectEnable(false)
    script:HideLabel(false)

    UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szDesc, nil, false)
    if szCoreDesc ~= "" then
        local script1 = UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList)
        script1:SetContent(UIHelper.AttachTextColor(szCoreDesc, FontColorID.ImportantRed))
    end
    

    UIHelper.SetString(self.LabelSkillName, szSkillName)
    UIHelper.SetVisible(self.WidgetInfo2, not bIsPassiveSkill)
    UIHelper.SetVisible(self.LabelSkillTime, not bIsPassiveSkill)
    UIHelper.SetString(self.LabelSkillLevel, string.format("等级 %d", dwLevel))

    if not bIsPassiveSkill then
        UIHelper.SetString(self.LabelSkillResult, "绝招")
        UIHelper.SetString(self.LabelSkillTime, SkillData.GetSkillCDDesc(dwID, dwLevel, self.targetPlayer))
        self:UpdateActiveSkillInfo(tSkillInfo)
    else
        self:UpdateDetailQiXueInfo(tSkillInfo, self.tEquippedSkillIds)
    end

    UIHelper.SetVisible(self.BtnEquipped, self.bShowButton and self.bSelected)
    UIHelper.SetVisible(self.BtnEquip, self.bShowButton and not self.bSelected)
    UIHelper.SetVisible(self.ImgTagBg, self.bSelected)

    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        UIHelper.SetButtonState(self.BtnEquip, BTN_STATE.Disable)
        if not self.fnChangeQiXue() then
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetAcupointTip)
        end
    end)

    if g_pClientPlayer and (g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH or g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY) then
        UIHelper.SetButtonState(self.BtnEquip, BTN_STATE.Disable, function()
            TipsHelper.ShowImportantBlueTip(g_tStrings.STR_DEAD_OR_AUTO_FLY)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkillInfo)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillDetailsList)
end

function UIWidgetAcupointTip_New:UpdateDetailQiXueInfo(tSkillInfo, tEquippedSkillIds)
    local tList = tSkillInfo and tSkillInfo.tbSkillEffectDescTalent or {}
    for _, szInfo in ipairs(tList) do
        local tSplit = string.split(szInfo, ":")
        local nSkillID = tonumber(tSplit[1])
        local szSkillName = TabHelper.GetUISkill(nSkillID).szName
        local nMijiID = tonumber(tSplit[2])
        local bSkillEquipped = table.contain_value(tEquippedSkillIds, nSkillID) or self.tTotalAppendSkillIDSet[nSkillID]

        local szMessage
        if nMijiID then
            local tRecipes, bActivated, nActivatedMijiID = SkillData.GetFinalRecipeList(nSkillID, self.targetPlayer)
            bSkillEquipped = bSkillEquipped and bActivated and nActivatedMijiID == nMijiID --设定了秘籍的需要判断当前技能秘籍是否对应
            local szFormat = "【%s】装配【%s】"
            local tSkillRecipe = Table_GetSkillRecipe(nMijiID, 1)
            local szMijiName = UIHelper.GBKToUTF8(tSkillRecipe.szName)
            szMijiName = string.gsub(szMijiName, "《(.-)》", "")
            szMessage = string.format(szFormat, szSkillName, szMijiName)
        else
            local szFormat = "【%s】"
            szMessage = string.format(szFormat, szSkillName)
        end

        UIHelper.AddPrefab(PREFAB_ID.WidgetListAttributeCell, self.ScrollViewSkillDetailsList, szMessage, _, bSkillEquipped)
    end
end

function UIWidgetAcupointTip_New:UpdateActiveSkillInfo(tSkillInfo)
    if tSkillInfo then
        local nCount = 1
        for i = 1, SKILL_INFO_DESC_NUM do
            local szDesc = tSkillInfo.tbSkillEffectDesc[i]
            if szDesc then
                szDesc = SkillData.FormSpecialNoun(szDesc)
                UIHelper.AddPrefab(PREFAB_ID.WidgetListAttributeCell, self.ScrollViewSkillDetailsList, szDesc, nCount, true)
                nCount = nCount + 1
            end
        end
    end
end

function UIWidgetAcupointTip_New:GetToggle()
    return self.TogConfiguration
end

function UIWidgetAcupointTip_New:PlayAnim()
    if not self.bPlayAni then
        self.bPlayAni = true
        UIHelper.SetOpacity(self.AniTip, 0) --设置初始状态，防止闪
        Timer.Add(self, 0.05, function()
            UIHelper.PlayAni(self, self.AniTip, "AniItemTip", function()
                self.bPlayAni = false
            end)
        end)
    end

end

function UIWidgetAcupointTip_New:Hide()
    UIHelper.SetVisible(self._rootNode)
    if self.fnClose then
        self.fnClose()
    end
end

function UIWidgetAcupointTip_New:HideButton()
    self.bShowButton = false
    UIHelper.SetVisible(self.BtnEquipped, false)
    UIHelper.SetVisible(self.BtnEquip, false)
end

function UIWidgetAcupointTip_New:DisableButton()
    UIHelper.SetButtonState(self.BtnEquip, BTN_STATE.Disable, function()
        TipsHelper.ShowImportantBlueTip("应用本心法后可配置")
    end)
end

function UIWidgetAcupointTip_New:UpdateToggles()
    local tAvailableSkillList = self.tAvailableSkillList
    if #tAvailableSkillList > 0 then
        for nIndex, nSkillID in ipairs(tAvailableSkillList) do
            local nOrder = TabHelper.GetUISkillMap(nSkillID).nAppendSkillOrder
            local szName = nOrder >= SPECIAL_ORDER and "特殊" or tIndexToName[nIndex]
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillTipTog, self.LayoutToggle)
            UIHelper.SetToggleGroupIndex(script.TogFold, ToggleGroupIndex.TongList)
            UIHelper.SetTouchDownHideTips(script.TogFold, false)
            UIHelper.SetString(script.LabelSelect, szName)
            UIHelper.SetString(script.LabelFold, szName)
            UIHelper.BindUIEvent(script.TogFold, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.dwID = nSkillID
                    self.nIndex = nIndex
                    self:UpdateBasicInfo()
                end
            end)

            if nIndex == 1 then
                UIHelper.SetSelected(script.TogFold, true)
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutToggle)
    end
    UIHelper.SetVisible(self.WidgetTitleTog, #tAvailableSkillList > 0)
end

function UIWidgetAcupointTip_New:UpdateSkillList(dwSkillID)
    self.tAvailableSkillList = {}
    if self.nCurrentKungFuID then
        self.tAppendSkillDict = SkillData.GetAppendSkillDict(self.nCurrentKungFuID, true)
        self.tTotalAppendSkillIDSet = {}
        for _, tInfo in pairs(self.tAppendSkillDict) do
            for _, nAppendSkillID in pairs(tInfo) do
                self.tTotalAppendSkillIDSet[nAppendSkillID] = true
            end
        end

        local tAvailableSkillList = self.tAppendSkillDict[dwSkillID] or {}
        if #tAvailableSkillList > 0 then
            table.insert(tAvailableSkillList, 1, dwSkillID) -- 将主技能加入tog生成
        end
        self.tAvailableSkillList = tAvailableSkillList
    end
end

function UIWidgetAcupointTip_New:ShowQixueCost(nCost)
    if nCost and IsNumber(nCost) and nCost > 0 then
        UIHelper.SetVisible(self.WidgetXiuWei, true)
        UIHelper.SetLabel(self.LabelXiuWei, nCost)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
    end
end

return UIWidgetAcupointTip_New