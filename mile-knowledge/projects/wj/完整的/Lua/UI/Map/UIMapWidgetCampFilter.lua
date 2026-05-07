-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMapWidgetCampFilter
-- Date: 2025-03-19 14:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CAMP_LIST = {
    [1] = HEAT_MAP_MODE.SHOW_ALL,
    [2] = HEAT_MAP_MODE.SHOW,
    [3] = HEAT_MAP_MODE.HIDE,
}

local tbName = {
    [HEAT_MAP_MODE.SHOW_ALL] = "显示统计点/数字",
    [HEAT_MAP_MODE.SHOW] = "仅显示统计点",
    [HEAT_MAP_MODE.HIDE] = "不显示统计",
}

local UIMapWidgetCampFilter = class("UIMapWidgetCampFilter")

function UIMapWidgetCampFilter:OnEnter(nDefaultMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nDefaultMode = nDefaultMode
    self:UpdateInfo()
end

function UIMapWidgetCampFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMapWidgetCampFilter:BindUIEvent()
    
end

function UIMapWidgetCampFilter:RegEvent()
    Event.Reg(self, EventType.OnSelectHeatMapMode, function(nIndex)
        UIHelper.SetString(self.LabelCampType, tbName[nIndex])
    end)
end

function UIMapWidgetCampFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMapWidgetCampFilter:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutCampFilter)
    for nIndex, nValue in ipairs(CAMP_LIST) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetMidShuntFilter, self.LayoutCampFilter, nil, nil, nil, true, {szTitle = tbName[nValue], nIndex = nValue}, self.nDefaultMode)
    end
    UIHelper.LayoutDoLayout(self.LayoutCampFilter)
    UIHelper.SetString(self.LabelCampType, tbName[self.nDefaultMode])
end


return UIMapWidgetCampFilter