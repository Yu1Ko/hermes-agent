-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UISkillTutorials
-- Date: 2024-7-2 17:35:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillTutorials = class("UISkillTutorials")

function UISkillTutorials:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szSearchFiler = ""
    self.tAcupointCellScripts = {}
    for i = 1, 4 do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationAcupointDX, self.LayoutAcupoint, i) ---@type UIWidgetAcupointCell
        table.insert(self.tAcupointCellScripts, script)
    end
    self:UpdateInfo()
end

function UISkillTutorials:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillTutorials:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelTutorialCollection)
    end)

    UIHelper.BindUIEvent(self.BtnWuXueMessage, EventType.OnClick, function()
        self:UpdateXinFaInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRecommend, EventType.OnClick, function()
        if self.nCurrentKungFuID then
            local script = UIMgr.Open(VIEW_ID.PanelSkillRecommend)
            script:InitDisplayOnly(self.nCurrentKungFuID, self.tQiXueList)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function()
        UIHelper.SetText(self.EditKindSearch, "")
        self:UpdateSearchFiler()
    end)
end

function UISkillTutorials:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillAttributeTips)
        local tCursor = Platform.IsWindows() and GetViewCursorPoint() or GetCursorPoint()
        TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillAttributeTips, tCursor.x, tCursor.y, szUrl, SkillData.tTotalNoun)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            self:UpdateSearchFiler()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            self:UpdateSearchFiler()
        end)
    end
end

function UISkillTutorials:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillTutorials:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewToggle)
    UIHelper.RemoveAllChildren(self.WidgetArrowParent)

    local bIsFirst = true
    for _, nSchoolType in ipairs(SkillData.tSchoolTypeOrder) do
        local szName = g_tStrings.tSchoolTitle[nSchoolType]
        if string.is_nil(self.szSearchFiler) or string.find(szName, self.szSearchFiler) then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTutorialNaviCell, self.ScrollViewToggle)
            if script then
                script:UpdateInfo(szName)
                UIHelper.SetSpriteFrame(script.WidgetImgIcon,  UIHelper.GetSchoolIcon(nSchoolType))
                UIHelper.BindUIEvent(script.ToggleNavigation, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected and nSchoolType ~= self.dwForceID then
                        self.dwForceID = nSchoolType
                        self:UpdateForce()
                    end
                end)

                if bIsFirst then
                    UIHelper.SetSelected(script.ToggleNavigation, true) -- 初始化左侧导航栏选中状态
                    bIsFirst = false
                end
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewToggle)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewToggle, self.WidgetArrowParent)
end

function UISkillTutorials:UpdateForce()
    if self.dwForceID then
        UIHelper.RemoveAllChildren(self.LayoutSkillNewLeftXinFa)
        UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupXinFa)

        local tKungFuList = Table_GetKungFuIDBySchool(self.dwForceID) -- dwKungfuID,nTalentGroup
        table.sort(tKungFuList, function(a, b)
            local nSkillIDA = a.dwKungfuID
            local nSkillIDB = b.dwKungfuID
            local tbOrderA = TabHelper.GetUISkill(nSkillIDA).tbOrder or { [1] = 99 }
            local tbOrderB = TabHelper.GetUISkill(nSkillIDB).tbOrder or { [1] = 99 }
            return tbOrderA[1] < tbOrderB[1]  --根据技能类型和order进行相应的排序
        end)

        for i = 1, 2 do
            local nSkillID = tKungFuList[i] and tKungFuList[i].dwKungfuID
            if nSkillID then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillTeachTog, self.LayoutSkillNewLeftXinFa, nSkillID, true)
                local tog = script:GetToggle()
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupXinFa, tog)
                UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bState)
                    if bState then
                        self:UpdateKungFu(tKungFuList[i])
                    end
                end)
            end
        end

        UIHelper.LayoutDoLayout(self.LayoutSkillNewLeftXinFa)
        UIHelper.SetToggleGroupSelected(self.ToggleGroupXinFa, 0)

        self:UpdateKungFu(tKungFuList[1])
    end
end

function UISkillTutorials:UpdateKungFu(tKungfu)
    self.nCurrentKungFuID = tKungfu.dwKungfuID
    self.tKungfuInfo = tKungfu
    if self.tKungfuInfo then
        self.tQiXueList = SkillData.GetQiXueByTalentGroup(self.tKungfuInfo.nTalentGroup)
        self:UpdateQiXue()
        self:UpdateSkills()
    end
end

function UISkillTutorials:UpdateSkills()
    local currentKungFuID = self.nCurrentKungFuID
    self.skillInfoList = clone(SkillData.GetSchoolSkillList(self.dwForceID))
    for nIndex, tInfo in ipairs(self.tQiXueList[4].SkillArray) do
        table.insert(self.skillInfoList, 1, { nID = tInfo.dwSkillID, tInfo = TabHelper.GetUISkill(tInfo.dwSkillID) })
    end

    table.sort(self.skillInfoList, function(a, b)
        local tbOrderA = a.tInfo.tbOrder or { [1] = 99 }
        local tbOrderB = b.tInfo.tbOrder or { [1] = 99 }
        return tbOrderA[1] < tbOrderB[1]  --根据order进行相应的排序
    end)

    self.commonSkillList = {}
    self.secSprintSkillList = {}
    self.normalSkillList = {}
    self.uniqueSkillList = {}

    for _, tSkill in ipairs(self.skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo and SkillData.IsSkillBelongToCurrentKungFu(nSkillID, 1, currentKungFuID) then
            if skillInfo.nType == UISkillType.Common then
                table.insert(self.commonSkillList, nSkillID)
            elseif skillInfo.nType == UISkillType.Skill then
                table.insert(self.normalSkillList, nSkillID)
            elseif skillInfo.nType == UISkillType.SecSprint then
                table.insert(self.secSprintSkillList, nSkillID)
            elseif skillInfo.nType == UISkillType.Trigger then
                table.insert(self.uniqueSkillList, nSkillID)
            elseif skillInfo.nType == UISkillType.Passive and skillInfo.nDamageParentID == currentKungFuID then
                self.nPassiveSkill = nSkillID
            end
        end
    end

    self:UpdateSkillGroup(self.commonSkillList, self.commonSkillParents)
    self:UpdateSkillGroup(self.secSprintSkillList, self.sprintSkillParents)
    self:UpdateSkillGroup(self.normalSkillList, self.LayoutSkillCell)
    self:UpdateSkillGroup(self.uniqueSkillList, self.uniqueSkillParents)
end

function UISkillTutorials:UpdateQiXue()
    local tList = self.tQiXueList
    for nIndex, script in ipairs(self.tAcupointCellScripts) do
        local fnClose = function()
            script:UnSelectAll()
        end

        script:SetTitle(QixueTitleList[nIndex])
        script:UpdateInfo(tList[nIndex], true)
        script:HideEquipHint()
        script:BindClickEvent(function(nSubIndex)
            local fnChangeQiXue = function()
            end

            local tSkill = tList[nIndex].SkillArray[nSubIndex]
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, self.LayoutAcupoint, TipsLayoutDir.RIGHT_CENTER)
            script:Init(tSkill, false, fnChangeQiXue, fnClose, {}, self.nCurrentKungFuID)
            script:HideButton()
        end)
    end
end

function UISkillTutorials:UpdateSkillGroup(skillIDList, parentList)
    if IsTable(parentList) then
        for index, parent in ipairs(parentList) do
            UIHelper.RemoveAllChildren(parent)
            local skillID = skillIDList[index]
            if skillID then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent, skillID)
                script:ShowName(true)
                self:SetSkillToggle(script:GetToggle(), skillID)
            end
        end
    else
        local layout = parentList
        UIHelper.RemoveAllChildren(layout)
        for index, skillID in ipairs(skillIDList) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout, skillID)
            script:ShowName(true)
            self:SetSkillToggle(script:GetToggle(), skillID)
        end
    end
end

function UISkillTutorials:SetSkillToggle(toggle, nSkillID)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRight, toggle)
    UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
        local fnExit = function()
            UIHelper.SetSelected(toggle, false)
        end

        if bSelected then
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, toggle, TipsLayoutDir.LEFT_CENTER)
            tipsScriptView:InitDisplayOnly(nSkillID, self.nCurrentKungFuID)
            tipsScriptView:BindExitFunc(fnExit)
        end
    end)
end

function UISkillTutorials:UpdateSearchFiler()
    local szSearchFiler = UIHelper.GetText(self.EditKindSearch)
    if self.szSearchFiler ~= szSearchFiler then
        self.szSearchFiler = szSearchFiler
        self:UpdateInfo()
    end
end

function UISkillTutorials:UpdateXinFaInfo()
    SkillData.ClearSpecialNoun()
    local tSkillInfo = TabHelper.GetUISkill(self.nPassiveSkill)
    local nSkillLevel = 14 -- 显示满级状态
    local szDesc = tSkillInfo.tbExtraDescText[nSkillLevel]
    local szSplitted = string.split(szDesc, "\n")
    local szFinal = ""
    for _, line in ipairs(szSplitted) do
        if line ~= "" then
            line = "· " .. line .. "\n"
            szFinal = szFinal .. line
        end
    end
    szFinal = SkillData.FormSpecialNoun(szFinal)
    TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnWuXueMessage, TipsLayoutDir.RIGHT_CENTER, szFinal)
    --UIHelper.SetRichText(self.LabelXinFaInfo, UIHelper.AttachTextColor(szFinal, FontColorID.Text_Level2))
end

return UISkillTutorials