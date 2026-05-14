-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelTaskView
-- Date: 2023-11-27 15:29:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelTaskView = class("UIPanelTaskView")

function UIPanelTaskView:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    nIndex = nIndex or 1
    self:UpdateInfo(nIndex)
end

function UIPanelTaskView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTaskView:BindUIEvent()
    for nIndex, toggle in ipairs(self.tbTogNavgation) do
        if nIndex == 3 then
            local bSystemOpen = SystemOpen.IsSystemOpen(SystemOpenDef.RoadChivalrous)
            local szDesc = SystemOpen.GetSystemOpenDesc(SystemOpenDef.RoadChivalrous)
            if not bSystemOpen then
                local szTips = szDesc
                UIHelper.SetCanSelect(toggle, false, szTips)
            end
        end

        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                self:SetCurPageIndex(nIndex)
            end
        end)
    end
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSwordMemories, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSwordMemories)
    end)
end

function UIPanelTaskView:RegEvent()

end

function UIPanelTaskView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTaskView:UpdateInfo(nIndex)

    for nIndex, toggle in ipairs(self.tbTogNavgation) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, toggle)
    end

    self.tbTitleList = {}
    for nIndex, label in ipairs(self.tbLabelSelectNavigation) do
        table.insert(self.tbTitleList, UIHelper.GetString(label))
    end

    self.scriptViewTask = UIHelper.AddPrefab(PREFAB_ID.WidgetTask, self.WidgetPageContent)
    -- self.scriptViewSword = UIHelper.AddPrefab(PREFAB_ID.WidgetSwordMemories, self.WidgetPageContent)
    -- self.scriptViewRoadChivalrous = UIHelper.AddPrefab(PREFAB_ID.WidgetRoadChivalrous, self.WidgetPageContent)

    self:SetCurPageIndex(nIndex)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, nIndex - 1)
end

function UIPanelTaskView:SetCurPageIndex(nPageIndex)
    self.nPageIndex = nPageIndex
    UIHelper.SetVisible(self.scriptViewTask._rootNode, nPageIndex == 1)
    -- UIHelper.SetVisible(self.scriptViewSword._rootNode, nPageIndex == 2)
    -- UIHelper.SetVisible(self.scriptViewRoadChivalrous._rootNode, nPageIndex == 3)
    UIHelper.SetString(self.LabelTitle, self.tbTitleList[nPageIndex])

    if nPageIndex == 1 then
        self.scriptViewTask:OnVisible()
    end

    -- if nPageIndex == 2 then
    --     self.scriptViewSword:OnVisible()
    -- end

    -- if nPageIndex == 3 then
    --     self.scriptViewRoadChivalrous:OnVisible()
    -- end
end


return UIPanelTaskView