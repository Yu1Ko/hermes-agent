local UIGMConfigureAccount = class("UIGMConfigureAccount")

function UIGMConfigureAccount:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    self:RefreshSchoolInfo()
end

function UIGMConfigureAccount:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.Close(VIEW_ID.PanelConfigureCamp)
end

function UIGMConfigureAccount:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIGMConfigureAccount:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        UIHelper.ScrollViewDoLayout(self.WidgetAutoToping)
        UIHelper.ScrollToTop(self.WidgetAutoToping, 0)
    end)
end

function UIGMConfigureAccount:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMConfigureAccount:UpdateInfo()
    self.ScriptAutoToping = UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonAutoTopingTitle, self.WidgetAutoToping, "自动吸顶")
    UIHelper.ScrollViewDoLayout(self.WidgetAutoToping)
    UIHelper.ScrollToTop(self.WidgetAutoToping, 0)
    UIHelper.SetVisible(self.WidgetAutoToping, false)


    self.nScrollViewTitlePos = {}
    self:UpdateSchoolInfo()
end

function UIGMConfigureAccount:UpdateSchoolInfo()
    local tConfigs = ConfigureAccount.Config
    self.scriptTaskList = {}
    self.tSchoolConfigMap = {}
    self.nScrollViewTaskTotalHeight = 0
    UIHelper.RemoveAllChildren(self.ScrollViewTask)
    for idx =1,  #tConfigs do
        local szTitle = tConfigs[idx].szSchool
        local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetDungeonTaskTitle, self.ScrollViewTask, szTitle)
        self.nScrollViewTitlePos[szTitle] = self.nScrollViewTaskTotalHeight
        if scriptTitle then
            scriptTitle:SetSelectedCallBack(function (bSelected)
                UIMgr.Close(VIEW_ID.PanelConfigureCamp)
                if bSelected then
                    for _, otherScriptTitle in pairs(self.tSchoolConfigMap) do
                        if scriptTitle ~= otherScriptTitle then
                            otherScriptTitle.bSelected = false
                            UIHelper.SetSelected(otherScriptTitle.ToggleSelect, false)
                        end
                    end
                end
                scriptTitle.bSelected = bSelected
                self:RefreshSchoolInfo()
            end)
            scriptTitle.bSelected = false
            UIHelper.SetString(scriptTitle.LabelFolded, szTitle)
            UIHelper.SetString(scriptTitle.LabelStretched, szTitle)
            self.tSchoolConfigMap[szTitle] = scriptTitle
            self.nScrollViewTaskTotalHeight = self.nScrollViewTaskTotalHeight + UIHelper.GetHeight(scriptTitle._rootNode)
            for _, kungfu in ipairs(tConfigs[idx])do
                local scriptTask = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigureKungFu, self.ScrollViewTask, kungfu)
                if scriptTask then
                    scriptTask.szTitle = szTitle
                    table.insert(self.scriptTaskList, scriptTask)
                    self.nScrollViewTaskTotalHeight = self.nScrollViewTaskTotalHeight + UIHelper.GetHeight(scriptTask._rootNode)
                end
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTask)
    UIHelper.ScrollToTop(self.ScrollViewTask, 0)
end

function UIGMConfigureAccount:RefreshSchoolInfo()
    for _,scriptTask in ipairs(self.scriptTaskList) do
        local scriptTitle = self.tSchoolConfigMap[scriptTask.szTitle]
        UIHelper.SetVisible(scriptTask._rootNode, scriptTitle.bSelected)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTask)
    UIHelper.ScrollToTop(self.ScrollViewTask, 0)
end

return UIGMConfigureAccount