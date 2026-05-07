-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINpcGuildlinesView
-- Date: 2023-04-28 14:54:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINpcGuildlinesView = class("UINpcGuildlinesView")

function UINpcGuildlinesView:OnEnter(dwMapID, dwIndex, dwNpcID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwMapID = dwMapID
    self.dwIndex = dwIndex
    self.dwNpcID = dwNpcID
    self:UpdateInfo()
end

function UINpcGuildlinesView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UINpcGuildlinesView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UINpcGuildlinesView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINpcGuildlinesView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINpcGuildlinesView:UpdateInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupTabLeft)
    UIHelper.RemoveAllChildren(self.ScrollViewTabLeft)
    local tClassList = Table_GetNpcGuild(self.dwMapID, self.dwIndex)
    for i, tClass in ipairs(tClassList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetGuardTabList, self.ScrollViewTabLeft, tClass, function ()
            self:OnSelectClass(tClass)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTabLeft, script.TogTabList)
        if i == 1 then
            self:OnSelectClass(tClass)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTabLeft)
end

function UINpcGuildlinesView:OnSelectClass(tClass)
    UIHelper.SetString(self.LabelGuardGuideInfo, UIHelper.GBKToUTF8(tClass.szDesc))
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupTogList01)
    UIHelper.RemoveAllChildren(self.ScrollViewTogList01)
    for i, tSubClass in ipairs(tClass.tSublist) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogListCell, self.ScrollViewTogList01, tSubClass, function ()
            self:OnSelectSubClass(tSubClass)
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTogList01, script.TogList)
        if i == 1 then
            self:OnSelectSubClass(tSubClass)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTogList01)
end

function UINpcGuildlinesView:OnSelectSubClass(tSubClass)
    UIHelper.RemoveAllChildren(self.ScrollViewBtnList01)
    for _, tNpc in ipairs(tSubClass.tNpcList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBtnListCell, self.ScrollViewBtnList01, tNpc, function ()
            UIMgr.Open(VIEW_ID.PanelMiddleMap, self.dwMapID, self.dwIndex)
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tNpc.szTypeName), self.dwMapID, {tNpc.tPoint[1], tNpc.tPoint[2], tNpc.tPoint[3]})
            UIMgr.Close(self)
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBtnList01)
end

return UINpcGuildlinesView