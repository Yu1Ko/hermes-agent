-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMapQueueView
-- Date: 2023-04-24 14:24:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMapQueueView = class("UIMapQueueView")

function UIMapQueueView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tScriptList = {}
    self:UpdateInfo()
end

function UIMapQueueView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIMapQueueView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogAuto, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Storage.MapQueue.bShowSureNotice = false
        else
            Storage.MapQueue.bShowSureNotice = true
        end
        Storage.MapQueue.Dirty()
    end)

    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function ()
        MapQueueData.OnClearMapQueue()
        PVPFieldData.OnClearMapQueue()
    end)
end

function UIMapQueueView:RegEvent()
    Event.Reg(self, EventType.OnMapQueueDataUpdate, function ()
        self:UpdateInfo()
    end)
end

function UIMapQueueView:UnRegEvent()
   Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMapQueueView:UpdateInfo()
    local tQueueList = {}
    if MapQueueData.tQueueList then
        for _, tInfo in ipairs(MapQueueData.tQueueList) do
            table.insert(tQueueList, tInfo)
        end
    end

    if PVPFieldData.tQueueList then
        for _, tInfo in ipairs(PVPFieldData.tQueueList) do
            tInfo.bPVPField = true
            table.insert(tQueueList, tInfo)
        end
    end

    if table_is_empty(tQueueList) then
        UIMgr.Close(self)
        return
    end

    local hPVP = GetPVPFieldClient()

    UIHelper.RemoveAllChildren(self.ScrollViewLineUpList)
    UIHelper.SetSelected(self.TogAuto, not Storage.MapQueue.bShowSureNotice, false)
    for _, tInfo in ipairs(tQueueList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetMapLineUpCell, self.ScrollViewLineUpList, tInfo, function ()
            if tInfo.bPVPField then
                local szServer = hPVP.GetPVPFieldBindCenter(tInfo.mapid, tInfo.copyindex)
                local szMsg = FormatString(g_tStrings.STR_MAP_QUEUE_CANCEL, UIHelper.GBKToUTF8(szServer .. "-" .. Table_GetMapName(tInfo.mapid)))
                if hPVP then
                    local fnConfirm = function ()
                        hPVP.LeavePVPFieldQueue(tInfo.mapid, tInfo.copyindex)
                    end
                    UIHelper.ShowConfirm(szMsg, fnConfirm)
                end
            else
                local szMsg = FormatString(g_tStrings.STR_MAP_QUEUE_CANCEL, UIHelper.GBKToUTF8(Table_GetMapName(tInfo.mapid)))
                local fnConfirm = function ()
                    MapQueueData.StartLeaveMapQueue(tInfo.mapid, tInfo.copyindex)
                end
                UIHelper.ShowConfirm(szMsg, fnConfirm)
            end
        end)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewLineUpList)
    UIHelper.ScrollToTop(self.ScrollViewLineUpList, 0)
end

return UIMapQueueView