-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillShoutQuickCreatPop
-- Date: 2025-04-05 14:34:18
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_COUNT_LIMIT = 10
local tbFilterIndex2SkillType = {
    [1] = UISkillType.Common,
    [2] = UISkillType.Skill,
    [3] = UISkillType.SecSprint,
    [4] = UISkillType.Trigger,
}
local tbPublicImg = {
    Normal = "UIAtlas2_Public_PublicSchool_PublicSchool_W_DaXia",
    Selected = "UIAtlas2_Public_PublicSchool_PublicSchool_iocn_school_DaXia",
}
local UISkillShoutQuickCreatPop = class("UISkillShoutQuickCreatPop")

function UISkillShoutQuickCreatPop:OnEnter(bDxSkill)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bDxSkill = bDxSkill or false
    self.nFilterType = 0
    self.tbSelectedSkill = {}
    self:InitForceToggle()
    self:UpdateCount()
    UIHelper.SetOpacity(self.BtnScreen, bDxSkill and 0)
end

function UISkillShoutQuickCreatPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillShoutQuickCreatPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCreateSkillShoutName)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:OnClickConfirm()
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function(btn)
        local tips, _ = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_LEFT, FilterDef.SkillShoutList)
        local nWidth = UIHelper.GetWidth(self.BtnScreen)
        tips:SetOffset(-nWidth)
        tips:Update()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
			local szSearchText = UIHelper.GetString(self.EditKindSearch)
			self.szFilter = szSearchText
            self:UpdateSkillList()
		end)
	else
		UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
			local szSearchText = UIHelper.GetString(self.EditKindSearch)
			self.szFilter = szSearchText
            self:UpdateSkillList()
		end)
	end
end

function UISkillShoutQuickCreatPop:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.SkillShoutList.Key then
            return
        end

        self.nFilterType = tbInfo[1][1] - 1
        self:UpdateSkillList()
    end)
end

function UISkillShoutQuickCreatPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local _fnGetClientPlayerForceID = function ()
    local dwSchoolID = SCHOOL_TYPE.CHUN_YANG
    local player = g_pClientPlayer
    if not player then
        return dwSchoolID
    end

    dwSchoolID = player.dwSchoolID
    return dwSchoolID
end

function UISkillShoutQuickCreatPop:InitForceToggle()
    UIHelper.RemoveAllChildren(self.ScrollViewChildTab)
    UIHelper.RemoveAllChildren(self.WidgetArrowParent)

    local bIsFirst = true
    local tbForceOrderList = {0}
    local nClientdwSchoolID = _fnGetClientPlayerForceID()
    for _, nSchoolType in ipairs(SkillData.tSchoolTypeOrder) do
        if nClientdwSchoolID == nSchoolType then
            table.insert(tbForceOrderList, 1, nSchoolType)
        else
            table.insert(tbForceOrderList, nSchoolType)
        end
    end

    for _, nSchoolType in ipairs(tbForceOrderList) do
        local nForceID = SchoolTypeToForceID[nSchoolType]
        local szName = g_tStrings.tSchoolTitle[nSchoolType]
        if nSchoolType == 0 then
            szName = "江湖"
        end

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillSchoolSelect, self.ScrollViewChildTab)
        if script then
            UIHelper.SetString(script.LabelNormal, szName)
            UIHelper.SetString(script.LabelSelect, szName)
            UIHelper.SetSpriteFrame(script.ImgSchool_Normal, PlayerForceID2SchoolImg[nForceID] or SchoolID2SchoolImg[nSchoolType] or tbPublicImg.Normal)
            UIHelper.SetSpriteFrame(script.ImgSchool, PlayerForceID2SchoolImg2[nForceID] or SchoolID2SchoolImg2[nSchoolType] or tbPublicImg.Selected)
            UIHelper.BindUIEvent(script.ToggleChildNavigation, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected and nSchoolType ~= self.nSchoolType then
                    self.nSchoolType = nSchoolType
                    self:UpdateSkillList()
                end
            end)

            if bIsFirst then
                UIHelper.SetSelected(script.ToggleChildNavigation, true) -- 初始化左侧导航栏选中状态
                bIsFirst = false
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChildTab)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewChildTab, self.WidgetArrowParent)
end

function UISkillShoutQuickCreatPop:UpdateSkillList()
    if not self.nSchoolType then
        return
    end

    local bEmpty = true
    UIHelper.RemoveAllChildren(self.ScrollList)

    local tbSkillList = self:GetSkillList(self.nSchoolType)
    for _, nSkillID in ipairs(tbSkillList) do
        local tbSkill = TabHelper.GetUISkill(nSkillID)
        local tbDxSkill = Table_GetSkill(nSkillID, 1)
        local szSkillName = tbSkill and tbSkill.szName or tbDxSkill and UIHelper.GBKToUTF8(tbDxSkill.szName) or ""
        local nFilterType = self.nFilterType > 0 and tbFilterIndex2SkillType[self.nFilterType] or nil
        local bShow = (self.szFilter and string.find(szSkillName, self.szFilter) or not self.szFilter)
                        and (nFilterType and nFilterType == tbSkill.nType or not nFilterType)
        if bShow then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillListCell, self.ScrollList)
            if script then
                bEmpty = false
                script:OnEnter(nSkillID, function (bSelected)
                    if bSelected and table.GetCount(self.tbSelectedSkill) >= MAX_COUNT_LIMIT then
                        Timer.AddFrame(self, 1, function()
                            script:SetSelected(false, false)
                        end)
                        return
                    end

                    self.tbSelectedSkill[nSkillID] = bSelected or nil
                    self:UpdateCount()
                end)
                script:SetSelected(self.tbSelectedSkill[nSkillID], false)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollList)
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
end

function UISkillShoutQuickCreatPop:UpdateCount()
    local nCount = table.GetCount(self.tbSelectedSkill)
    local szCount = "已选择："..nCount.."/".. MAX_COUNT_LIMIT
    UIHelper.SetString(self.LabelSelected, szCount)
end

function UISkillShoutQuickCreatPop:OnClickConfirm()
    if not self.tbSelectedSkill or table.GetCount(self.tbSelectedSkill) <= 0 then
        return
    end

    local tbNewList = {}
    local tbSkillList = clone(Storage.Chat_SkillShout.tbSkillList) or {}
    local nInsertPos = #tbSkillList

    for nSkillID, _ in pairs(self.tbSelectedSkill) do
        local skill = TabHelper.GetUISkill(nSkillID)
        local szName = skill and skill.szName or ""
        if not skill then
            skill = Table_GetSkill(nSkillID, 1)
            szName = UIHelper.GBKToUTF8(skill.szName)
        end
        tbNewList[szName] = true
        table.insert(tbSkillList, {szSkillName = szName, bApplied = true})
    end
    ChatAutoShout.SaveSkillShout("tbSkillList", tbSkillList)

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSkillShoutSetting)
    if scriptView then
        scriptView:OnEnter(nInsertPos + 1, tbNewList)
    else
        UIMgr.Open(VIEW_ID.PanelSkillShoutSetting, nInsertPos + 1, tbNewList)
    end
    UIMgr.Close(self)
end

local function _GetPublicSkillList(bDxSkill)
    -- 主要是去除同名的技能
    local tProcessed = {}
    local tbPublicSkillList = clone(SkillData.GetPublicSkillList(bDxSkill)) or {}
    for key, nSkillID in ipairs(tbPublicSkillList) do
        local bNeedRemove = true
        local tbSkillInfo = TabHelper.GetUISkill(nSkillID)
        local szName = tbSkillInfo and tbSkillInfo.szName or ""
        if not tbSkillInfo then
            tbSkillInfo = Table_GetSkill(nSkillID, 1)
            szName = UIHelper.GBKToUTF8(tbSkillInfo.szName)
        end

        if not tProcessed[szName] then
            bNeedRemove = false
        end
        tProcessed[szName] = true

        if bNeedRemove then
            table.remove(tbPublicSkillList, key)
        end
    end
    return tbPublicSkillList
end

function UISkillShoutQuickCreatPop:GetSkillList(nSchoolType)
    local tbPublicSkillList = _GetPublicSkillList(self.bDxSkill)
    if nSchoolType == 0 then
        return tbPublicSkillList
    end

    self.tbKongFuSkillList = self.tbKongFuSkillList or {}
    if self.tbKongFuSkillList[nSchoolType] then
        return self.tbKongFuSkillList[nSchoolType]
    end

    local tKungFuList = Table_GetKungFuIDBySchool(nSchoolType, self.bDxSkill)

    if not self.bDxSkill then
        table.sort(tKungFuList, function(a, b)
            local tbOrderA = TabHelper.GetUISkill(a.dwKungfuID).tbOrder or {99}
            local tbOrderB = TabHelper.GetUISkill(b.dwKungfuID).tbOrder or {99}
            return tbOrderA[1] < tbOrderB[1]
        end)
    end


    local tbSkillList = {}
    local tProcessed = {}
    for _, tKungFu in ipairs(tKungFuList) do
        self:ProcessKungFuSkills(tKungFu, tbSkillList, tProcessed)
    end

    self.tbKongFuSkillList[nSchoolType] = tbSkillList
    return tbSkillList
end

function UISkillShoutQuickCreatPop:ProcessKungFuSkills(tKungFu, tbSkillList, tProcessed)
    local nKongFuID = tKungFu.dwKungfuID
    local nTalentGroup = tKungFu.nTalentGroup

    local tQiXueList = SkillData.GetQiXueByTalentGroup(nTalentGroup, self.bDxSkill)
    local tbSkills = self.bDxSkill and clone(SkillData.GetSchoolDxSkillList(self.nSchoolType, nKongFuID)) or clone(SkillData.GetSchoolSkillList(self.nSchoolType)) or {}

    if not self.bDxSkill then
        table.sort(tbSkills, function(a, b)
            local tbOrderA = a.tInfo.tbOrder or { [1] = 99 }
            local tbOrderB = b.tInfo.tbOrder or { [1] = 99 }
            return tbOrderA[1] < tbOrderB[1]  --根据order进行相应的排序
        end)

            -- 绝招
        for _, tInfo in ipairs(tQiXueList[4].SkillArray) do
            table.insert(tbSkills, 1, {
                nID = tInfo.dwSkillID,
            })
        end
    else
        for _, tInfo in ipairs(tQiXueList) do
            for k, v in pairs(tInfo.SkillArray) do
                local tSkill = GetSkill(v.dwSkillID, v.dwSkillLevel)
                if tSkill and not tSkill.bIsPassiveSkill then
                    table.insert(tbSkills, {
                        nID = v.dwSkillID,
                    })
                end
            end
        end
    end

    -- 普通技能列表
    self:ProcessSkillsRecursive(nKongFuID, tbSkills, tbSkillList, tProcessed)
end

function UISkillShoutQuickCreatPop:ProcessSkillsRecursive(nKongFuID, tbSkills, tbSkillList, tProcessed, bAppend)
    tProcessed = tProcessed or {}
    local tAppendSkillDict = SkillData.GetAppendSkillDict(nKongFuID, true, true)
    local tbPublicSkillList = clone(SkillData.GetPublicSkillList(self.bDxSkill)) or {}

    for _, tSkill in ipairs(tbSkills) do
        local nSkillID = tSkill.nID
        local tSkillInfo = tSkill.tInfo or TabHelper.GetUISkill(nSkillID) or Table_GetSkill(nSkillID, 1)
        if not table.contain_value(tbPublicSkillList, nSkillID) then
            if tSkillInfo and SkillData.IsSkillBelongToCurrentKungFu(nSkillID, 1, nKongFuID) then
                if not tProcessed[tSkillInfo.szName]
                    and (tSkillInfo.nType ~= UISkillType.Passive and tSkillInfo.nType ~= UISkillType.Append or bAppend)
                then
                    tProcessed[tSkillInfo.szName] = true
                    table.insert(tbSkillList, nSkillID)
                end
                -- 追加技
                if tAppendSkillDict[nSkillID] then
                    for _, nAppendSkillID in ipairs(tAppendSkillDict[nSkillID]) do
                        self:ProcessSkillsRecursive(nKongFuID,
                            {{nID = nAppendSkillID}},
                            tbSkillList, tProcessed, true)
                    end
                end
            end

        end
    end
end

return UISkillShoutQuickCreatPop