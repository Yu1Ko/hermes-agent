-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetSkillRecommendDXCell
-- Date: 2025-10-21 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------
local function GetSkillLevel(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 0
    end
    local nLevel = hPlayer.GetSkillLevel(dwID) or 0
    return nLevel
end

---@class WidgetSkillRecommendDXCell
local WidgetSkillRecommendDXCell = class("WidgetSkillRecommendDXCell")

function WidgetSkillRecommendDXCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function WidgetSkillRecommendDXCell:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function WidgetSkillRecommendDXCell:BindUIEvent()

end

function WidgetSkillRecommendDXCell:RegEvent()

end

function WidgetSkillRecommendDXCell:InitQixue(szTitle, tQixueList, bPve)
    local hPlayer = GetClientPlayer()
    local fnShowTips = function(tQixueInfo, tog)
        local fnClose = function()
            return UIHelper.SetSelected(tog, false)
        end

        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, tog, TipsLayoutDir.BOTTOM_LEFT)
        script:Init(tQixueInfo, nil, nil, fnClose)
        script:HideButton()
    end

    UIHelper.SetLabel(self.LabelTittle, szTitle)

    for i, tQixue in ipairs(tQixueList) do
        local dwPointID = tQixue[1]
        local nIndex = tQixue[2]
        local tInfo = hPlayer.GetTalentInfoByPointID(dwPointID)
        local tQixueInfo = tInfo.SkillGroup[nIndex]
        local nSkill = tQixueInfo.dwSkillID
        local nLevel = GetSkillLevel(nSkill)
        local nShowLevel = math.max(nLevel, 1)
        local tSkill = GetSkill(nSkill, nShowLevel)

        local nPrefabID = tSkill.bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
        local script = UIHelper.AddPrefab(nPrefabID, self.LayoutDXAttributePreview)
        script:UpdateInfo(nSkill)
        script:ShowName(true)
        script:SetQixueBg(tQixueInfo.dwSkillColor)
        script:BindSelectFunction(function()
            fnShowTips(tQixueInfo, script.TogSkill)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutDXAttributePreview)

    if bPve then
        UIHelper.SetVisible(self.TogMultiFunction, true)
        UIHelper.SetSelected(self.TogMultiFunction, Storage.PanelSkill.bCheckTeach)
        UIHelper.BindUIEvent(self.TogMultiFunction, EventType.OnSelectChanged, function(toggle, bSelected)
            Storage.PanelSkill.bCheckTeach = bSelected
        end)
    end

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function()
        OnConfirmQixue(tQixueList)
    end)
end

function WidgetSkillRecommendDXCell:InitMiji(szTitle, tRecipeSkillList, szDesc)
    local hPlayer = GetClientPlayer()
    local fnShowTips = function(tQixueInfo, tog)
        local fnClose = function()
            return UIHelper.SetSelected(tog, false)
        end

        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, tog, TipsLayoutDir.BOTTOM_LEFT)
        script:Init(tQixueInfo, nil, nil, fnClose)
        script:HideButton()
    end

    UIHelper.SetLabel(self.LabelTittle, szTitle)

    local tSkillRecipeList = {}
    for i, dwSkillID in ipairs(tRecipeSkillList) do
        local nSkill = dwSkillID

        local nLevel = GetSkillLevel(nSkill)
        local nShowLevel = math.max(nLevel, 1)
        --local tSkill = GetSkill(nSkill, nShowLevel)

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.LayoutDXAttributePreview)
        script:UpdateInfo(nSkill)
        script:ShowName(true)
        script:UpdateMijiDot(true, true)

        script:BindSelectFunction(function()
            local panelScript = UIMgr.Open(VIEW_ID.PanelMijiSelectPop)
            panelScript:InitDxRecommend(nSkill)

            Timer.AddFrame(self, 1, function()
                UIHelper.SetSelected(script.TogSkill, false)
            end)
        end)
        local tRecipeList = GetSkillTeachRecipe(dwSkillID, nShowLevel)
        tSkillRecipeList[dwSkillID] = tRecipeList
    end

    UIHelper.LayoutDoLayout(self.LayoutDXAttributePreview)
    if szDesc then
        UIHelper.SetVisible(self.LayoutInfo2, true)
        UIHelper.SetLabel(self.RichTextInfo2, szDesc)
    end

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function()
        ConfirmCheckRecipe(tSkillRecipeList)
    end)
end

return WidgetSkillRecommendDXCell
