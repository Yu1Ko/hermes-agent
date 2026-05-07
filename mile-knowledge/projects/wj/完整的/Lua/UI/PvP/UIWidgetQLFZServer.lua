-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetQLFZServer
-- Date: 2023-11-14 10:06:40
-- Desc: ?
-- ---------------------------------------------------------------------------------
local SERVER_STATE = {
    NORMAL = 1,
    BUSY = 2,
    CROWDED = 3,
}

local SERVER_STATE_IMG = {
    [SERVER_STATE.NORMAL] = "UIAtlas2_Login_login_icon_fuwuqi_07.png",
    [SERVER_STATE.BUSY] = "UIAtlas2_Login_login_icon_fuwuqi_06.png",
    [SERVER_STATE.CROWDED] = "UIAtlas2_Login_login_icon_fuwuqi_05.png",
}


local UIWidgetQLFZServer = class("UIWidgetQLFZServer")

function UIWidgetQLFZServer:OnEnter(tbServerInfo, scriptParent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbServerInfo = tbServerInfo
    self.scriptParent = scriptParent
    self:UpdateInfo()
end

function UIWidgetQLFZServer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetQLFZServer:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSever, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self.scriptParent:OnChangeSelServer(self.tbServerInfo)
        end
    end)
end

function UIWidgetQLFZServer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetQLFZServer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQLFZServer:IsCeaseFireTime(nTime)
    local nCurrentTime = GetCurrentTime()
    local tDate
    if nTime then
        if nTime > nCurrentTime then -- 凌晨刚打完时，根据保护期时间计算是否休战
            tDate = TimeToDate(nTime)
        end
    end
    if not tDate then
        tDate = TimeToDate(nCurrentTime) -- 上午12点前则根据当前时间判断是否休战
    end
    return (tDate.hour >= 3 and tDate.hour <= 11)
end

function UIWidgetQLFZServer:UpdateInfo()
    local tbServerInfo = self.tbServerInfo
    local nCrowdedDegree = tbServerInfo.nCrowdedDegree
    UIHelper.SetSpriteFrame(self.ImgSeverIcon, SERVER_STATE_IMG[nCrowdedDegree])

    local szName = tbServerInfo.szName
    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelExplain, szName)

    local nCamp = tbServerInfo.nCamp
    UIHelper.SetVisible(self.ImgEvilBg, nCamp == CAMP.EVIL)
    UIHelper.SetVisible(self.ImgNeutralityBg, nCamp == CAMP.NEUTRAL)
    UIHelper.SetVisible(self.ImgJusticeBg, nCamp == CAMP.GOOD)


    UIHelper.SetVisible(self.WidgetTipLeft1, tbServerInfo.bDoubleServer)

    local tCrossMsg = PVPFieldData.GetCrossMsg()
    local tbCrossData = tCrossMsg[szName]
    self.tbCrossData = tbCrossData
    local nCurrentTime = GetCurrentTime()
    self:UpdateSliderPercent()

    local nLeftSec = tbCrossData.nPassTime
    if nLeftSec ~= 0 then
        nLeftSec = math.max(nLeftSec - nCurrentTime, 0)
    end

    if tbCrossData.nCurrentBoss == 3 then
        nLeftSec = "已占领"
    elseif self:IsCeaseFireTime(tbCrossData.nPassTime) then
        nLeftSec = "停战期"
    elseif nLeftSec ~= 0 then
        self.bShowTime = true
        nLeftSec = Timer.Format2RemainHourAndMinuteAndSecond(nLeftSec)
    elseif tbCrossData.nCurrentBoss < 3 then
        nLeftSec = "争夺中"
    end

    UIHelper.SetString(self.LabelTimeMessage, nLeftSec)
    if self.bShowTime ~= nil then
        self:UpdatePassTime()
    end

    UIHelper.SetVisible(self.WidgetTipRight, tbServerInfo.bCurServer)
    UIHelper.SetVisible(self.WidgetTipLeft2, tbServerInfo.bMyServer)

    UIHelper.SetSelected(self.TogSever, tbServerInfo.bSel, false)

    UIHelper.SetVisible(self.WidgetBossSchedule, tbServerInfo.bBossOpen)
    if tbServerInfo.nBossLife then
        UIHelper.SetProgressBarPercent(self.ImgSlider, tbServerInfo.nBossLife)
    end
    if tbServerInfo.szBossLife == g_tStrings.STR_SWITCH_SERVER_BOSS_DEAD then
        tbServerInfo.szBossLife = ""
    end
    UIHelper.SetString(self.LabelBossSchedule, tbServerInfo.szBossLife)
    self:StartTimer()
end

function UIWidgetQLFZServer:UpdatePassTime()
    if not self.bShowTime then return end
    local nCurrentTime = GetCurrentTime()
    local nPassTime = self.tbCrossData.nPassTime
    local nLeftSec = math.max(nPassTime - nCurrentTime, 0)
    UIHelper.SetString(self.LabelTimeMessage, Timer.Format2RemainHourAndMinuteAndSecond(nLeftSec))
end

function UIWidgetQLFZServer:UpdateSliderPercent()
    local tbCrossData = self.tbCrossData
    if tbCrossData.nCurrentBoss == 0 then return end
    local nCurrentTime = GetCurrentTime()
    for nIndex = 1, 3 do
        local nPercent = 1
        if nIndex <= tbCrossData.nCurrentBoss then 
            local nLeft = 180 - (nCurrentTime - tbCrossData["nBossTime"..nIndex])
            nPercent = math.max(0, nLeft / 180)
        end
        UIHelper.SetProgressBarPercent(self.tbSlider[nIndex], nPercent * 100)
    end
end

function UIWidgetQLFZServer:StopTimer()
    if self.nTimer then 
        Timer.DelTimer(self, self.nTimer) 
        self.nTimer = nil
    end
end

function UIWidgetQLFZServer:StartTimer()
    self:StopTimer()
    self.nTimer = Timer.AddFrameCycle(self, 3, function()
        self:UpdatePassTime()
        self:UpdateSliderPercent()
    end)
end

return UIWidgetQLFZServer