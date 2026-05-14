-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityListTitle
-- Date: 2024-01-22 19:47:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local RANK_LIST_ID = 292
local tFishActivity = {
    [1] = 161,    --帮会钓鱼
    [2] = 899,    --野外钓鱼(工作日)
    [3] = 920,    --野外钓鱼(周末)
}
local UIHomelandIdentityListTitle = class("UIHomelandIdentityListTitle")

function UIHomelandIdentityListTitle:OnEnter(dwActiveID, tbFishPoint)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwActiveID  = dwActiveID
    self.tbFishPoint = tbFishPoint
    self:UpdateInfo()
end

function UIHomelandIdentityListTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityListTitle:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnGo, true)
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        if self.fn then
            self.fn()
        end
    end)
end

function UIHomelandIdentityListTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityListTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function GetTimeToHourMinuteSecond(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nHour   = math.floor(nTime / 3600)
    nTime         = nTime - nHour * 3600
    local nMinute = math.floor(nTime / 60)
    nTime         = nTime - nMinute * 60
    local nSecond = math.floor(nTime)
    return nHour, nMinute, nSecond
end

local function GetActivityTimeDesc(dwID)
    local tActiveInfo = Table_GetCalenderActivity(dwID)
    if not tActiveInfo then
        return
    end
    local szResult = ""
    local bOpen    = true
    local nCurTime = GetCurrentTime()
    local bShow, szTime, nStartTime, nEndTime = ActivityData.GetTimeText(tActiveInfo)
    szResult = szTime
    if szTime ~= g_tStrings.CALENDER_ALL_DAY then
        local nCurrentTime = GetCurrentTime()
        if tActiveInfo.nEvent == CALENDER_EVENT_DYNAMIC or (nCurrentTime >= nStartTime and nCurrentTime <= nEndTime) then
            szResult = g_tStrings.tActiveState[1]
        elseif nCurrentTime > nEndTime then
            bOpen = false
            szResult = g_tStrings.STR_ACTIVITY_TODAY_END
        elseif nCurrentTime < nStartTime then
            bOpen = false
            local nLeft = nStartTime - nCurrentTime
            local nHour, nMinute = GetTimeToHourMinuteSecond(nLeft)
            szResult = FormatString(g_tStrings.STR_ACTIVITY_CONUT_DOWN, nHour, nMinute)
        end
    end
    return szResult, bOpen
end

function UIHomelandIdentityListTitle:UpdateInfo()
    UIHelper.SetVisible(self.BtnGo, false)
    UIHelper.SetVisible(self.LabelTime, true)
    UIHelper.SetVisible(self.LayoutContent, false)
    local dwActiveID    = self.dwActiveID
    local tInfo         = Table_GetCalenderActivity(dwActiveID)
    local fn = function ()
        local szTime, bOpen = GetActivityTimeDesc(dwActiveID)
        UIHelper.SetRichText(self.LabelTime, "<color=#245460>"..szTime.."</color>")
        if bOpen and dwActiveID == tFishActivity[1] then
            UIHelper.SetVisible(self.BtnGo, true)
            UIHelper.SetVisible(self.LayoutContent, false)
            UIHelper.SetVisible(self.LabelTime, false)
        end
    end

    UIHelper.SetString(self.LabelTitleUp, UIHelper.GBKToUTF8(tInfo.szName))
    Timer.AddCycle(self, 1, function ()
        fn()
    end)
    fn()

    if self.dwActiveID ~= tFishActivity[1] then
        UIHelper.SetVisible(self.LayoutContent, true)
        local tFishPoint = self.tbFishPoint
        for _, tbInfo in ipairs(tFishPoint) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderListTitleCell, self.LayoutContent)
            script:OnEnter(tbInfo)
        end
        UIHelper.LayoutDoLayout(self.LayoutContent)
    else
        self.fn = function ()
            local enterTongMap = function()
                MapMgr.CheckTransferCDExecute(function()
                    UIMgr.CloseAllInLayer("UIPageLayer")
                    UIMgr.CloseAllInLayer("UIPopupLayer")
					RemoteCallToServer("On_Tong_ToTongMapDetection")
				end)
            end
            --地图资源下载检测拦截
            if not PakDownloadMgr.UserCheckDownloadMapRes(TongData.DEMESNE_MAP_ID, enterTongMap) then
                return
            end
            enterTongMap()
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIHomelandIdentityListTitle:SetClickCallback(fn)
    self.fn = fn
end

return UIHomelandIdentityListTitle