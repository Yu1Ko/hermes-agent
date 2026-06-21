-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: TouchMgr
-- Date: 2024-07-26 20:39:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

TouchMgr = TouchMgr or {className = "TouchMgr"}
local self = TouchMgr

function TouchMgr.Init()
    Event.Reg(self, "ON_REMOTE_REPORT_NOTIFY", function(uType, _uValue)
        if uType == Const.ReportType.Touch then
            self._tbRecord = {}
            self._nReportCount = nil
            TouchMgr.Resume()
            if self._nTimerID then
                Timer.DelTimer(self, self._nTimerID)
            end
            self._nTimerID = Timer.Add(self, 60 * 2, function()
                if not self._nReportCount or #self._tbRecord > 0 then
                    local szRecord = JsonEncode(self._tbRecord)
                    DataReport.ReportTouch(szRecord)
                end

                TouchMgr.Pause()
                self._tbRecord = nil
                self._nReportCount = nil
                self._nTimerID = nil
            end)
        end
    end)
end

function TouchMgr.UnInit()

end

function TouchMgr.Pause()
    self._unRegisterEvent()
end

function TouchMgr.Resume()
    self._registerEvent()
end

function TouchMgr._registerEvent()
    self._unRegisterEvent()

    local layerWeb = UIMgr.GetLayer(UILayer.Web)
    if not self.touchListener then
        self.touchListener = cc.EventListenerTouchOneByOne:create()
        self.touchListener :registerScriptHandler(self._onTouchHandler, cc.Handler.EVENT_TOUCH_BEGAN)
        --self.touchListener :registerScriptHandler(self._onTouchHandler, cc.Handler.EVENT_TOUCH_MOVED)
        self.touchListener :registerScriptHandler(self._onTouchHandler, cc.Handler.EVENT_TOUCH_ENDED)
        self.touchListener :registerScriptHandler(self._onTouchHandler, cc.Handler.EVENT_TOUCH_CANCELLED)
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self.touchListener, layerWeb)
end

function TouchMgr._unRegisterEvent()
    if self.touchListener then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self.touchListener)
        self.touchListener = nil
    end
end

function TouchMgr._onTouchHandler(touch, event)
    local tPos = touch:getLocation()
    local nID = touch:getId()
    local nEvent = event:getEventCode()
    local nTickCount = GetTickCount()
    local tOutputPos = { x = math.floor(tPos.x), y = math.floor(tPos.y) }

    if nEvent == cc.EventCode.BEGAN then
        table.insert(self._tbRecord, { type = "began", time = nTickCount, id = nID, x = tOutputPos.x, y = tOutputPos.y});
        -- LOG.INFO("QH, b nID = %s, nX = %s, nY = %s", tostring(nID), tostring(tPos.x), tostring(tPos.y))
    elseif nEvent == cc.EventCode.MOVED then
        -- LOG.INFO("QH, m nID = %s, nX = %s, nY = %s", tostring(nID), tostring(tPos.x), tostring(tPos.y))
    elseif nEvent == cc.EventCode.ENDED then
        table.insert(self._tbRecord, { type = "ended", time = nTickCount, id = nID, x = tOutputPos.x, y = tOutputPos.y});
        -- LOG.INFO("QH, e nID = %s, nX = %s, nY = %s", tostring(nID), tostring(tPos.x), tostring(tPos.y))
    elseif nEvent == cc.EventCode.CANCELLED then
        table.insert(self._tbRecord, { type = "cancelled", time = nTickCount, id = nID, x = tOutputPos.x, y = tOutputPos.y});
        -- LOG.INFO("QH, c nID = %s, nX = %s, nY = %s", tostring(nID), tostring(tPos.x), tostring(tPos.y))
    end

    if #self._tbRecord >= 50 then
        self._nReportCount = self._nReportCount and (self._nReportCount + 1) or 1
        local szRecord = JsonEncode(self._tbRecord)
        DataReport.ReportTouch(szRecord)
        self._tbRecord = {}
    end

    return true
end
