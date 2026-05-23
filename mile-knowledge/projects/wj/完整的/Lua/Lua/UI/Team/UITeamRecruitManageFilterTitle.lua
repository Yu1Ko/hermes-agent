-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitManageFilterTitle
-- Date: 2023-02-14 17:26:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamRecruitManageFilterTitle = class("UITeamRecruitManageFilterTitle")

function UITeamRecruitManageFilterTitle:OnEnter(tbConfig, fnSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbConfig = tbConfig
    self.fnSelect = fnSelect
    self.tbFilterItems = {}
    self:UpdateInfo()
end

function UITeamRecruitManageFilterTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamRecruitManageFilterTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg03, EventType.OnSelectChanged, function (_, bSelected)
        self:SetSelected(bSelected)
    end)
end

function UITeamRecruitManageFilterTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitManageFilterTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitManageFilterTitle:UpdateInfo()
    local fnSelect = function (curScript, bSelected)
        local bAllSame = true
        for _, item in ipairs(self.tbFilterItems) do
            if item ~= curScript and item:GetSelected() ~= bSelected then
                bAllSame = false
                break
            end
        end
        if bAllSame then
            UIHelper.SetSelected(self.TogPitchBg03, bSelected, false)
        else
            UIHelper.SetSelected(self.TogPitchBg03, false, false)
        end
        local tbChecked = {}
        if bSelected then
            table.insert(tbChecked, curScript.tbConfig)
        end
        for _, item in ipairs(self.tbFilterItems) do
            if item ~= curScript and item:GetSelected() then
                table.insert(tbChecked, item.tbConfig)
            end
        end
        self.fnSelect(tbChecked)
    end
    for _, tbSub in ipairs(self.tbConfig) do
        local filterItem = UIHelper.AddPrefab(PREFAB_ID.WidgetRecruitSelectOptiomTips, self.LayoutScreenOptiom)
        filterItem:OnEnter(tbSub, fnSelect)
        table.insert(self.tbFilterItems, filterItem)
    end
    UIHelper.SetString(self.LabelTitle, self.tbConfig.szName)
    UIHelper.LayoutDoLayout(self.LayoutScreenOptiom)
    UIHelper.LayoutDoLayout(self.LayoutRecruitScreenSelectTips)
end

function UITeamRecruitManageFilterTitle:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogPitchBg03, bSelected, false)
    local tbChecked = {}
    for _, item in ipairs(self.tbFilterItems) do
        item:SetSelected(bSelected)
        if bSelected then
            table.insert(tbChecked, item.tbConfig)
        end
    end
    self.fnSelect(tbChecked)
end

function UITeamRecruitManageFilterTitle:GetSelected()
    return UIHelper.GetSelected(self.TogPitchBg03)
end


return UITeamRecruitManageFilterTitle