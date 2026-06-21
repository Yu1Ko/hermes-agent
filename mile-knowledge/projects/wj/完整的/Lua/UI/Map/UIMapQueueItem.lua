-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMapQueueItem
-- Date: 2023-04-24 17:01:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMapQueueItem = class("UIMapQueueItem")

function UIMapQueueItem:OnEnter(tInfo, fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self.fnCallback = fnCallback
    self:UpdateInfo()
end

function UIMapQueueItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIMapQueueItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function ()
        self.fnCallback(self.tInfo)
    end)
end

function UIMapQueueItem:RegEvent()
    Event.Reg(self,  EventType.OnBigBattleQueueActivityChanged, function()
        self:UpdateInfo()
    end)
end

function UIMapQueueItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMapQueueItem:UpdateInfo()
    local mapid = self.tInfo.mapid
    local copyindex = self.tInfo.copyindex
    local queuetype = self.tInfo.queuetype
    local camp = self.tInfo.camp
    local rank = self.tInfo.rank
    local bAppointment = self.tInfo.bAppointment
    local szMapName
    local szCamp
    if camp then
        szCamp = g_tStrings.STR_CAMP_TITLE[camp]
        local hPVP          = GetPVPFieldClient()
        local szServer      = hPVP.GetPVPFieldBindCenter(mapid, copyindex)
        szMapName     = UIHelper.GBKToUTF8(szServer) .. "-" .. MapQueueData.GetMapName(mapid, copyindex)
    else
        if queuetype == MAP_QUEUE_TYPE.NEUTRAL then
            szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL]
        elseif queuetype == MAP_QUEUE_TYPE.GOOD then
            szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD]
        elseif queuetype == MAP_QUEUE_TYPE.EVIL then
            szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL]
        else
            szCamp = g_tStrings.tMapQueueType[queuetype]
        end

        szMapName = MapQueueData.GetMapName(mapid, copyindex)
    end

    local szName = string.format("[%s]%s", szCamp, szMapName)
    UIHelper.SetString(self.LabelMapName, szName)

    local szRankTip
    if not MapQueueData.BeBigBattle(mapid) and not bAppointment then
        szRankTip = string.format("排队人数  %d", rank)
    else
        szRankTip = "排队中"
    end
    UIHelper.SetString(self.LabelLineUp, szRankTip)
end

return UIMapQueueItem