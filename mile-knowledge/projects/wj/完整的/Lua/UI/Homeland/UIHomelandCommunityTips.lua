-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandCommunityTips
-- Date: 2023-04-03 17:10:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandCommunityTips = class("UIHomelandCommunityTips")

function UIHomelandCommunityTips:OnEnter(dwCenterID, nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nMapID = nMapID
    self.dwCenterID = dwCenterID
    self:UpdateInfo()
end

function UIHomelandCommunityTips:OnExit()
    self.bInit = false
end

function UIHomelandCommunityTips:BindUIEvent()

end

function UIHomelandCommunityTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandCommunityTips:UpdateInfo()

    UIHelper.RemoveAllChildren(self.ScrollViewHomeCutMap)

    local scriptTitle1 = UIHelper.AddPrefab(PREFAB_ID.WidgetCommunityTilte, self.ScrollViewHomeCutMap)
    scriptTitle1:OnEnter("服务器")

    local tbCenterList = GetHomelandMgr().GetRelationCenter(GetCenterID())
    for _, v in ipairs(tbCenterList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeCutMapTog, self.ScrollViewHomeCutMap)
        script:OnEnter(UIHelper.GBKToUTF8(v.szCenterName), nil, function()
            if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ON_GROUPON_BUY_TIPS)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
                return
            end
            Event.Dispatch(EventType.OnReInitHomelandCenterID, v.dwCenterID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
            UIMgr.Close(VIEW_ID.PanelCustomBuyPop)
        end)
        script:SetSelected(v.dwCenterID == self.dwCenterID)
    end

    local scriptTitle2 = UIHelper.AddPrefab(PREFAB_ID.WidgetCommunityTilte, self.ScrollViewHomeCutMap)
    scriptTitle2:OnEnter("社区地图")

    local tMapList = Table_GetCommunityMapList()
    for _, nMapID in ipairs(tMapList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeCutMapTog, self.ScrollViewHomeCutMap)
        local szName = Table_GetMapName(nMapID)
        script:OnEnter(UIHelper.GBKToUTF8(szName), nMapID, function()
            if UIMgr.GetView(VIEW_ID.PanelCustomBuyPop) then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_ON_GROUPON_BUY_TIPS)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
                return
            end
            Event.Dispatch(EventType.OnSelectHomelandMyHomeMap, nMapID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCommunityTips)
            UIMgr.Close(VIEW_ID.PanelCustomBuyPop)
        end)
        script:SetSelected(nMapID == self.nMapID)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewHomeCutMap)
    UIHelper.ScrollToTop(self.ScrollViewHomeCutMap, 0)

    UIHelper.SetTouchDownHideTips(self.ScrollViewHomeCutMap, false)

end


return UIHomelandCommunityTips