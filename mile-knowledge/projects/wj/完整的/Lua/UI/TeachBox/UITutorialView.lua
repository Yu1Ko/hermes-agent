-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITutorialView
-- Date: 2023-12-22 10:23:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITutorialView = class("UITutorialView")
local CURRENT_VIEW = {
    SERVICE = 1,
    TEACH_BOX = 2,
    SKILL = 3,
}

function UITutorialView:OnEnter(nSelectTab, tbSelectInfo, nTab, nPage)
    self.nSelectTab = nSelectTab or 1
    self.tbSelectInfo = tbSelectInfo
    self.tbScript = nil
    self.nCurView = nTab or CURRENT_VIEW.TEACH_BOX
    self.nPage = nPage or 1

    self.tToggleList = { self.TogNavigation01, self.TogNavigation02, self.TogNavigation03 }
    for _, toggle in ipairs(self.tToggleList) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, toggle)
    end
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(true)
end

function UITutorialView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITutorialView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogNavigation01, EventType.OnClick, function()
        if self.nCurView ~= CURRENT_VIEW.SERVICE then
            self.nCurView = CURRENT_VIEW.SERVICE
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigation02, EventType.OnClick, function()
        if self.nCurView ~= CURRENT_VIEW.TEACH_BOX then
            self.nCurView = CURRENT_VIEW.TEACH_BOX
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigation03, EventType.OnClick, function()
        if self.nCurView ~= CURRENT_VIEW.SKILL then
            self.nCurView = CURRENT_VIEW.SKILL
            self:UpdateInfo()
        end
    end)

end

function UITutorialView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITutorialView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITutorialView:UpdateInfo(bRefresh)
    if self.nCurView == CURRENT_VIEW.TEACH_BOX then
        self:UpdateTeachBox()
    elseif self.nCurView == CURRENT_VIEW.SERVICE then
        self:UpdateService()
    elseif self.nCurView == CURRENT_VIEW.SKILL then
        self:UpdateSkill()
    end
    if bRefresh then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.tToggleList[self.nCurView])
    end
end

function UITutorialView:UpdateService()
    UIHelper.RemoveAllChildren(self.WidgetContent)
    UIHelper.AddPrefab(PREFAB_ID.WidgetService, self.WidgetContent, self.nSelectTab, self.tbSelectInfo)
end

function UITutorialView:UpdateTeachBox()
    UIHelper.RemoveAllChildren(self.WidgetContent)
    UIHelper.AddPrefab(PREFAB_ID.WidgetTutorialCollection, self.WidgetContent)
end

function UITutorialView:UpdateSkill()
    UIHelper.RemoveAllChildren(self.WidgetContent)
    UIHelper.AddPrefab(PREFAB_ID.WidgetTutorialSkills, self.WidgetContent)
end

return UITutorialView