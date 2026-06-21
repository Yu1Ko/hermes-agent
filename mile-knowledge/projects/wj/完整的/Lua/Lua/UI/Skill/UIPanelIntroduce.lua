-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIPanelIntroduce
local UIPanelIntroduce = class("UIPanelIntroduce")
local tSlotIndex = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

function UIPanelIntroduce:OnEnter(nCurrentKungFuID, nCurrentSetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nCurrentKungFuID = nCurrentKungFuID
        self.nCurrentSetID = nCurrentSetID
        self.bIsHD = TabHelper.IsHDKungfuID(self.nCurrentKungFuID)
    end
    self:InitXinFaInfo()
    self:UpdateInfo()
end

function UIPanelIntroduce:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelIntroduce:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBigSkill, EventType.OnClick, function()
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConfigurationAcupointTip, self.BtnBigSkill
        , TipsLayoutDir.TOP_CENTER, self.nCurrentKungFuID, self.nCurrentSetID)
    end)

    UIHelper.BindUIEvent(self.LayoutCoin, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.LayoutCoin, CurrencyType.Train)
    end)
    UIHelper.SetTouchEnabled(self.LayoutCoin, true)
end

function UIPanelIntroduce:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        LOG.WARN("UIPanelSkill UIPanelSkill ON_UPDATE_TALENT")
        self:UpdateInfo()
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        OutputMessage("MSG_ANNOUNCE_NORMAL", "心法切换成功")
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        --LOG.WARN("UIPanelSkillNew ON_SKILL_REPLACE")
        self:OnSkillReplace(arg0, arg1)
    end)

    Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
        print("UPDATE_TALENT_SET_SLOT_SKILL")
        self:UpdateInfo()
    end)

end

function UIPanelIntroduce:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelIntroduce:InitXinFaInfo()
    local playerKungFuList = NewSkillPanel_GetKungFuList(self.bIsHD)
    
    local tXinFaToggles = {}
    for i = 1, #playerKungFuList do
        local nSkillID = playerKungFuList[i] and playerKungFuList[i][1]
        if nSkillID then
            local t = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillNewLeftXinFa, self.LayoutSkillNewLeftXinFa, nSkillID)
            table.insert(tXinFaToggles, t)
        end
    end

    for index, script in ipairs(tXinFaToggles) do
        local tog = script:GetToggle()
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bState)
            if bState then
                self.nCurrentKungFuID = playerKungFuList[index][1]
                self:UpdateInfo()
            end
        end)

        if self.nCurrentKungFuID == playerKungFuList[index][1] then
            UIHelper.SetToggleGroupSelected(self.ToggleGroup, index - 1)
        end

        if #playerKungFuList <= 1 then
            UIHelper.LayoutDoLayout(self.LayoutBtn)
        end
    end
end

function UIPanelIntroduce:UpdateInfo()
    local nHDKungFuID = TabHelper.GetHDKungfuID(self.nCurrentKungFuID)
    local nPosType = PlayerKungfuPosition[nHDKungFuID] or KUNGFU_POSITION.DPS
    local szXinFaImg = SkillKungFuTypeImg[nPosType]
    UIHelper.SetSpriteFrame(self.ImgXinFaType, szXinFaImg)

    if not self.bIsHD then
        if g_pClientPlayer and g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL then
            UIHelper.SetSpriteFrame(self.ImgQiXueSkillBg, SZ_UNLOCKED_BIG_SKILL_BG_PATH) -- 解锁奇穴时触发技背景变更
        end

        local szIconPath = TabHelper.GetSkillIconPath(self.nCurrentKungFuID)
        UIHelper.SetTexture(self.ImgRecommend1, szIconPath)

        self:UpdatePlayerSkillData()
        self:UpdateSkillPanel()
    else
        self:UpdateInfoDX()
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewXinFaInfo)
    UIHelper.SetVisible(self.WidgetSkill, not self.bIsHD)
    UIHelper.SetVisible(self.WidgetSkillDX, self.bIsHD)
end

function UIPanelIntroduce:UpdateInfoDX()
    self:UpdateXinFaInfoDX()
    self:UpdateSkillListDX()
end

----------------------------------------------------------------

function UIPanelIntroduce:UpdateXinFaInfoDX()
    local hPlayer = g_pClientPlayer
    local nSkillLevel = math.max(1, hPlayer.GetSkillLevel(self.nCurrentKungFuID))
    local hSkill = Table_GetSkill(self.nCurrentKungFuID, nSkillLevel)
    UIHelper.SetString(self.LabelXinFaName, UIHelper.GBKToUTF8(hSkill.szName))

    local aSkill = hPlayer.GetSkillList(self.nCurrentKungFuID)
    local tInfo = {}
    for dwSubID, dwSubLevel in pairs(aSkill) do
        local fSort = Table_GetSkillSortOrder(dwSubID, dwSubLevel);
        table.insert(tInfo, { dwID = dwSubID, dwLevel = dwSubLevel, fSort = fSort })
    end
    table.sort(tInfo, function(tA, tB)
        return tA.fSort < tB.fSort
    end)

    local szDesc1 = GetSkillDesc(self.nCurrentKungFuID, nSkillLevel, nil, nil, false)
    szDesc1 = UIHelper.GBKToUTF8(szDesc1)

    local szFinal = ""
    for _, tData in pairs(tInfo) do
        local dwSkillID, dwLevel = tData.dwID, tData.dwLevel
        if Table_IsSkillShow(dwSkillID, dwLevel) then
            local szTip = GetSkillDesc(dwSkillID, dwLevel, nil, nil, false)
            szFinal = szDesc1 .. "\n" .. UIHelper.GBKToUTF8(szTip)
        end
    end

    szFinal = SkillData.FormSpecialNoun(szFinal)
    szFinal = szFinal == "" and "习得该心法后可查看心法详情" or szFinal
    UIHelper.SetRichText(self.LabelXinFaInfo, UIHelper.AttachTextColor(szFinal, FontColorID.Text_Level2))
end

function UIPanelIntroduce:UpdateSkillListDX()
    UIHelper.RemoveAllChildren(self.ScrollViewSkillListDX)

    if not self.bIsHD then
        return
    end
    self.tLeftSkillScripts = {}
    local hPlayer = g_pClientPlayer
    local bIsEquippedKungFu = self.nCurrentKungFuID == hPlayer.GetActualKungfuMountID()

    local fnInitCell = function(script)
        script:ShowName(true)
        script:SetToggleGroup(self.ToggleGroupRight)
        script:BindSelectFunction(function(nSkillID)
            local fnExit = function()
                UIHelper.SetSelected(script.TogSkill, false)
            end

            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, script.TogSkill, TipsLayoutDir.LEFT_CENTER,
                    nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
            tipsScriptView:BindExitFunc(fnExit)
        end)

        UIHelper.SetScale(script._rootNode, 0.9, 0.9)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0.5) -- 锚点和Layout保持一致
        table.insert(self.tLeftSkillScripts, script)
    end

    local fnInitSkill = function(lst, parent)
        for _, tSkill in pairs(lst) do
            local dwID = tSkill[1]
            local dwLevel = tSkill[2]
            local bCommon, bCurrent, bMelee = SkillData.IsCommonDXSkill(dwID)
            if (not bCommon or bCurrent) and NewSkillPanel_IsShowSkill(dwID, dwLevel) then
                dwID = bIsEquippedKungFu and SkillData.CheckDXSkillReplace(dwID) or dwID -- 应用DX替换逻辑
                dwLevel = math.max(1, dwLevel)
                local bPassive = SkillData.IsPassiveSkill(dwID, dwLevel)
                local nPrefabID = bPassive and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
                local script = UIHelper.AddPrefab(nPrefabID, parent)
                local tSlotData = { nType = DX_ACTIONBAR_TYPE.SKILL, data1 = dwID }
                script:UpdateInfoDX(tSlotData)
                fnInitCell(script, not bPassive)
            end
        end
    end

    ------------------遍历对阵技能------------------
    local tKungfu = Table_GetMKungfuList(self.nCurrentKungFuID)
    for nIndex, dwID in ipairs(tKungfu) do
        local dwLevel = hPlayer.GetSkillLevel(dwID)
        local dwShowLevel = dwLevel
        if dwLevel == 0 then
            dwShowLevel = 1
        end
        if Table_IsSkillShow(dwID, dwShowLevel) then
            local lst = SkillData.GetDXSkillList(self.nCurrentKungFuID, dwID)
            local finalList = {}
            for nIndex, tGroup in ipairs(lst) do
                for _, tSkill in pairs(tGroup) do
                    local dwID = tSkill[1]
                    local dwLevel = tSkill[2]
                    local bLearned = dwLevel > 0
                    local bCommon, bCurrent, bMelee = SkillData.IsCommonDXSkill(dwID)
                    local hSkill = GetSkill(dwID, math.max(1, dwLevel))
                    local bMatchSelectMount = NewSkillPanel_IsMatchSelectMount(hSkill, self.nCurrentKungFuID)
                    if bMatchSelectMount and (not bCommon or bCurrent) and NewSkillPanel_IsShowSkill(dwID, dwLevel) then
                        table.insert(finalList, tSkill)
                    end
                end
            end

            if #finalList > 0 then
                local listScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListDXCell, self.ScrollViewSkillListDX)
                local szName = Table_GetSkillName(dwID, dwShowLevel)
                UIHelper.SetLabel(listScript.LabelSkillTypeTitle, UIHelper.GBKToUTF8(szName))
                fnInitSkill(finalList, listScript.LayoutSkillDXCell)
            end
        end
    end

    UIHelper.SetOpacity(self.ScrollViewSkillListDX, 0)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewSkillListDX, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillListDX)
    Timer.AddFrame(self, 1, function()
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewSkillListDX, false, true) -- 标题栏挂靠刷新
        UIHelper.SetOpacity(self.ScrollViewSkillListDX, 255)
    end)
end

--------------------------心法相关--------------------------------

function UIPanelIntroduce:UpdatePlayerSkillData()
    local currentKungFuID = self.nCurrentKungFuID
    local tSkillInfo = TabHelper.GetUISkill(currentKungFuID)

    self:UpdateSkillList()

    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    self.uniqueSkillList = {} --从奇穴列表中获取第四重奇穴主动技能信息
    local tQixue = tList[4]
    if tQixue then
        local nSelectIndex = tQixue.nSelectIndex
        local tSkillArray = tQixue.SkillArray

        if nSelectIndex > 0 then
            local tSkill = tSkillArray[nSelectIndex]
            table.insert(self.uniqueSkillList, tSkill.dwSkillID)
        end
    end

    UIHelper.SetString(self.LabelXinFaName, tSkillInfo.szName)
    UIHelper.SetTexture(self.ImgXinFa, TabHelper.GetSkillIconPath(currentKungFuID))

    --UIHelper.SetString(self.LabelXinFaInfo, tSkillInfo.szDesc)
end

function UIPanelIntroduce:UpdateSkillList()
    local currentKungFuID = self.nCurrentKungFuID
    local tKungFuSkill = GetSkill(currentKungFuID, 1)
    local nMountType = tKungFuSkill.dwMountType
    local skillInfoList = IsNoneSchoolKungfu(currentKungFuID) and SkillData.GetSchoolSkillList(MountTypeToSchoolType[nMountType]) or
            SkillData.GetCurrentPlayerSkillList(currentKungFuID)

    self.commonSkillList = {}
    self.secSprintSkillList = {}
    self.normalSkillList = {}

    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Common then
            table.insert(self.commonSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.Skill then
            table.insert(self.normalSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.SecSprint then
            table.insert(self.secSprintSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.Passive and skillInfo.nDamageParentID == currentKungFuID then
            self:UpdatePassiveSkill(nSkillID) -- 被动技能只能通过nDamageParentID判断心法归属
        end
    end

    self.tSlotToSkillID = {}
    self.tEquippedSkillIds = {}
    for i = 1, #tSlotIndex do
        local slotIndex = tSlotIndex[i]
        local nSkillID = slotIndex ~= UI_SKILL_UNIQUE_SLOT_ID and SkillData.GetSlotSkillID(slotIndex, currentKungFuID, self.nCurrentSetID)
                or SkillData.GetUniqueSkillID(self.nCurrentKungFuID, self.nCurrentSetID)
        self.tSlotToSkillID[slotIndex] = nSkillID
        table.insert(self.tEquippedSkillIds, nSkillID)
    end
end

function UIPanelIntroduce:UpdatePassiveSkill(nSkillID)
    self.nPassiveSkill = nSkillID or self.nPassiveSkill
    SkillData.ClearSpecialNoun()
    local tSkillInfo = TabHelper.GetUISkill(self.nPassiveSkill)
    local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nCurrentKungFuID)
    local szDesc = tSkillInfo.tbExtraDescText[nSkillLevel]
    local szSplitted = string.split(szDesc, "\n")
    local szFinal = ""
    for _, line in ipairs(szSplitted) do
        if line ~= "" then
            line = "· " .. line .. "\n"
            szFinal = szFinal .. line
        end
    end
    szFinal = SkillData.FormSpecialNoun(szFinal, nSkillID)
    szFinal = szFinal == "" and "习得该心法后可查看心法详情" or szFinal
    UIHelper.SetRichText(self.LabelXinFaInfo, UIHelper.AttachTextColor(szFinal, FontColorID.Text_Level2))
end

function UIPanelIntroduce:UpdateSkillPanel()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupRight)

    self:UpdateSkillGroup(self.commonSkillList, self.commonSkillParents)
    self:UpdateSkillGroup(self.secSprintSkillList, self.sprintSkillParents)
    self:UpdateSkillGroup(self.normalSkillList, self.LayoutSkillCell)
    self:UpdateSkillGroup(self.uniqueSkillList, { self.WIdgetSkillCell06 })

end

function UIPanelIntroduce:UpdateSkillGroup(skillIDList, parentList)
    if IsTable(parentList) then
        for index, parent in ipairs(parentList) do
            UIHelper.RemoveAllChildren(parent)
            local skillID = skillIDList[index]
            if skillID then
                local x = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent, skillID)
                x:ShowName(true)
                self:SetSkillToggle(x:GetToggle(), skillID)
            end
        end
    else
        local layout = parentList
        UIHelper.RemoveAllChildren(layout)
        for index, skillID in ipairs(skillIDList) do
            local x = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout, skillID)
            x:ShowName(true)
            self:SetSkillToggle(x:GetToggle(), skillID)
        end
    end
end

function UIPanelIntroduce:SetSkillToggle(toggle, nSkillID)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRight, toggle)
    UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
        local fnExit = function()
            self:UpdatePassiveSkill()
            UIHelper.SetSelected(toggle, false)
        end

        if bSelected then
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, toggle, TipsLayoutDir.LEFT_CENTER,
                    nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
            tipsScriptView:BindExitFunc(fnExit)
        end
    end)
end

return UIPanelIntroduce