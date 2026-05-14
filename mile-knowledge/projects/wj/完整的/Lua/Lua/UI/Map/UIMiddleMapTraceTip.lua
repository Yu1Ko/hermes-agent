local UIMiddleMapTraceTip = class("UIMiddleMapTraceTip")

local GREEN = {157, 255, 166}
local RED = {255, 226, 110}

function UIMiddleMapTraceTip:UpdateInfo()
    self.szNpcName, self.nMapID = select(1, MapMgr.GetTraceInfo())
    local bCanShowTrace = MapMgr.CanShowTrace()
    if self.szNpcName and bCanShowTrace then
        self:Show()
    else
        self:Hide()
    end
end

function UIMiddleMapTraceTip:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        MapMgr.ClearTracePoint()
        self:Hide()
    end)

    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        if self.nShowMapID ~= self.nMapID then
            UIMgr.Close(VIEW_ID.PanelWorldMap)
            if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
                UIMgr.Open(VIEW_ID.PanelMiddleMap)
            end
            Event.Dispatch("ON_MIDDLE_MAP_REFRESH", self.nMapID, 0)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChangeWalk, EventType.OnClick, function()
        local szName, nMapID, tbPoint = MapMgr.GetTraceInfo()
        AutoNav.NavTo(nMapID, tbPoint[1], tbPoint[2], tbPoint[3])
    end)

    Event.Reg(self, EventType.OnMapUpdateNpcTrace, function()
        self:UpdateInfo()
    end)
end

function UIMiddleMapTraceTip:OnEnter()
    self:RegisterEvent()
    self:UpdateInfo()
end

function UIMiddleMapTraceTip:OnExit()
end

function UIMiddleMapTraceTip:Show()
    UIHelper.SetVisible(self._rootNode, true)

    local szMap = GBKToUTF8(Table_GetMapName(self.nMapID))
    local tbColor = cc.c3b(unpack(RED))

    if MapMgr.IsCurrentMap(self.nMapID) then
        szMap = g_tStrings.STR_TRAFFIC_CURRENT_MAP
        tbColor = cc.c3b(unpack(GREEN))
    end

    local szText = string.format(g_tStrings.STR_TRAFFIC_PREFIX, szMap)

    UIHelper.SetColor(self.LabelPlace, tbColor)
    UIHelper.SetString(self.LabelPlace, szText)
    UIHelper.SetString(self.LabelNormalBlue, self.szNpcName)
    UIHelper.LayoutDoLayout(self.LayoutLabelTrace)

    local szFrame = select(-1, MapMgr.GetTraceInfo())
    UIHelper.SetSpriteFrame(self.ImgTrace, szFrame)
end

function UIMiddleMapTraceTip:UpdateShowMap(nShowMapID)
    self.nShowMapID = nShowMapID
    self:UpdateInfo()
end

function UIMiddleMapTraceTip:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

return UIMiddleMapTraceTip