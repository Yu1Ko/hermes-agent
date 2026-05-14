-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandRuleView
-- Date: 2023-11-14 10:15:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandRuleView = class("UIHomelandRuleView")

local PageIndex2RuleID = {
    [1] = 23,
    [2] = 24,
    [4] = 25,
}

local SubPageIndex2RuleID = {
    [1] = 25,
    [2] = 47,
}

local PageIndexHadSubPage = {
    [4] = true,
}

function UIHomelandRuleView:OnEnter(nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurPageIndex = 1
    self.nCurSubPageIndex = 1
    self.nLevel = nLevel
    self:UpdateInfo()
end

function UIHomelandRuleView:OnExit()
    self.bInit = false
end

function UIHomelandRuleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    for i, tog in ipairs(self.tbTogPage) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupHomeLandNav, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurPageIndex = i
            self:UpdateInfo()
        end)
    end

    for i, tog in ipairs(self.tbSubTogPage) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurSubPageIndex = i

            if i == 2 then
                Storage.HomeLand.bShowNewCommunityRule = true
                Storage.HomeLand.Dirty()
            end

            self:UpdateInfo()
        end)
    end
end

function UIHomelandRuleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandRuleView:UpdateInfo()
    self:UpdateWelfareInfo()
    self:UpdateRuleInfo()
    self:UpdateRedPointInfo()
end

function UIHomelandRuleView:UpdateWelfareInfo()
    local tbConfigs = Table_GetHomelandWelfareInfo()
    self.tbWelfareCells = self.tbWelfareCells or {}
    for i, tbConfig in ipairs(tbConfigs) do
        if not self.tbWelfareCells[i] then
            self.tbWelfareCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandPopCell, self.LayoutHomeLandWelfare)
            self.tbWelfareCells[i]:OnEnter(self.nLevel, tbConfig)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutHomeLandWelfare)
end

function UIHomelandRuleView:UpdateRuleInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewHomeLandActiveInfo)

    self.nRuleID = PageIndex2RuleID[self.nCurPageIndex]
    if not self.nRuleID then
        return
    end

    if PageIndexHadSubPage[self.nCurPageIndex] then
        self.nRuleID = SubPageIndex2RuleID[self.nCurSubPageIndex]
        if not self.nRuleID then
            return
        end
    end

    local tbConfig = TabHelper.GetUIRuleTab(self.nRuleID)
    if not tbConfig then
        return
    end

    UIHelper.SetString(self.LabelTitle, tbConfig.szTitle)

    local i = 1
    while tbConfig["nPrefabID"..i] and tbConfig["szDesc"..i] and tbConfig["nPrefabID"..i] > 0 and tbConfig["szDesc"..i] ~= "" do
        local cell = UIHelper.AddPrefab(tbConfig["nPrefabID"..i], self.ScrollViewHomeLandActiveInfo)
        if tbConfig["nPrefabID"..i] == PREFAB_ID.WidgetHelpContentCelll then
            -- 规则弹窗预制，这里会超框所以得处理下richtext的宽度
            local nWidth = UIHelper.GetWidth(self.ScrollViewHomeLandActiveInfo)
            UIHelper.SetWidth(cell.LabelContent, nWidth - 20)
        end
        cell:OnEnter(tbConfig["szDesc"..i], false)
        i = i + 1
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewHomeLandActiveInfo)
    UIHelper.ScrollToTop(self.ScrollViewHomeLandActiveInfo, 0)
end

function UIHomelandRuleView:UpdateRedPointInfo()
    UIHelper.SetVisible(self.ImgNew, not Storage.HomeLand.bShowNewCommunityRule)
end

return UIHomelandRuleView