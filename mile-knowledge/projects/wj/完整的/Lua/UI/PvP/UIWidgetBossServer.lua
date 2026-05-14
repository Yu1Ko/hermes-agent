-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBossServer
-- Date: 2023-11-14 11:38:24
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

local UIWidgetBossServer = class("UIWidgetBossServer")

function UIWidgetBossServer:OnEnter(tbServerInfo, scriptParent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbServerInfo = tbServerInfo
    self.scriptParent = scriptParent
    self:UpdateInfo()
end

function UIWidgetBossServer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBossServer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSever, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self.scriptParent:OnChangeSelBossServer(self.tbServerInfo)
        end
    end)
end

function UIWidgetBossServer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBossServer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBossServer:UpdateInfo()
    local tbServerInfo = self.tbServerInfo 
    local nCrowdedDegree = tbServerInfo.nPeopleCount
    UIHelper.SetSpriteFrame(self.ImgSeverIcon, SERVER_STATE_IMG[nCrowdedDegree])

    local szName = UIHelper.GBKToUTF8(tbServerInfo.szName)
    UIHelper.SetString(self.LabelExplain, szName)

    UIHelper.SetVisible(self.WidgetTipRight, tbServerInfo.bCurServer)
    UIHelper.SetSelected(self.BtnSever, tbServerInfo.bSel, false)

    UIHelper.SetVisible(self.WidgetBossSchedule, tbServerInfo.bBossOpen)
    if tbServerInfo.nBossLife then
        UIHelper.SetProgressBarPercent(self.ImgSlider, tbServerInfo.nBossLife)
    end
    if tbServerInfo.szBossLife == g_tStrings.STR_SWITCH_SERVER_BOSS_DEAD then
        tbServerInfo.szBossLife = ""
    end
    UIHelper.SetString(self.LabelBossSchedule, tbServerInfo.szBossLife)
end


return UIWidgetBossServer