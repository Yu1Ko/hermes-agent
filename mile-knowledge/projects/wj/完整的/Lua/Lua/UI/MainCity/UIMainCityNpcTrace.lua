local UIMainCityNpcTrace = class("UIMainCityNpcTrace")

local tbKeyToFrame =
{
    ["TreasurePoint"] = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_xunbao"
}

function UIMainCityNpcTrace:OnEnter(tbRemotePointData)
    self.tbRemotePointData = tbRemotePointData

    self.tPoint = nil

    if not self.bInit then
        self:RegisterEvent()
        self.bInit = true

        self.nContentWidth, self.nContentHeight = UIHelper.GetContentSize(self.WidgetTraceRange)
        self.nWidth, self.nHeight = self.nContentWidth, self.nContentHeight

        self.nArrowY = UIHelper.GetPositionY(self.ImgArrow)
        self.nArrowBottomY = self.nArrowY + 20

        self.nWorldPosX, self.nWorldPosY = UIHelper.GetWorldPosition(UIHelper.GetParent(self.WidgetTraceRange))
        self.nWorldPosX = self.nWorldPosX - self.nWidth / 2
        self.nWorldPosY = self.nWorldPosY - self.nHeight / 2
    end

    UIHelper.SetActiveAndCache(self, self.WidgetTrace, false)

    self:UpdateTracePoint()
end

function UIMainCityNpcTrace:OnExit()
    TraceMgr.StopByScript(self)
end

function UIMainCityNpcTrace:RegisterEvent()
    Event.Reg(self, EventType.OnMapUpdateNpcTrace, function()
        self:UpdateTracePoint()
    end)
end

function UIMainCityNpcTrace:UpdateTracePoint()
    if self.tbRemotePointData and self.tbRemotePointData.dwMapID and self.tbRemotePointData.tPoint then
        self.nMapID = self.tbRemotePointData.dwMapID

        local tbRemotePoint = self.tbRemotePointData.tPoint
        self.tPoint = {tbRemotePoint.fX, tbRemotePoint.fY, tbRemotePoint.fZ}

        local szKey = self.tbRemotePointData and self.tbRemotePointData.szKey or ""
        self.szFrame = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwuWC_hui"
        if tbKeyToFrame[szKey] then
            self.szFrame = tbKeyToFrame[szKey]
        elseif string.sub(szKey, 1, 2) == "Re" and self.tbRemotePointData.nType == 1 then
            self.szFrame = "UIAtlas2_MainCity_MainCity1_TeamHeart"
        end
    else
        local _, nMapID, tPoint, szUID, szFrame = MapMgr.GetTraceInfo()
        self.nMapID = nMapID
        self.tPoint = tPoint
        self.szFrame = szFrame
    end

    if self.nMapID and self.tPoint then
        local dwTemplateID = self.tbRemotePointData and self.tbRemotePointData.dwTemplateID or nil
        TraceMgr.Start(self, self.tPoint, function() return self:IsMapVaild() end,
        function()
            TraceMgr.ClearRemotePoint()
            MapMgr.ClearTracePoint()
        end,
        function()
            MapMgr.ClearTracePoint(true)
        end, self.szFrame, nil, dwTemplateID)
    else
        TraceMgr.StopByScript(self)
    end
end

function UIMainCityNpcTrace:IsMapVaild(player)
    player = player or g_pClientPlayer
    local scene = player and player.GetScene()
    local nMapID = scene and scene.dwMapID
    local bCanShowTrace = MapMgr.CanShowTrace(true)
    if nMapID ~= self.nMapID or not bCanShowTrace then
        return false
    end
    return true
end

function UIMainCityNpcTrace:IsNpcTrace()
    return true
end

return UIMainCityNpcTrace