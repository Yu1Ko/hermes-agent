-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIStudentInteractionView
-- Date: 2023-09-20 14:56:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIStudentInteractionView = class("UIStudentInteractionView")

local MODE_MENTOR 		= 1
local MODE_APPRENTICE	= 2
local tMode2RelationType = {[1] = 7, [2] = 8, [3] = 9}

function UIStudentInteractionView:OnEnter(szName, nMode, tInfo)
    if not tInfo then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = UIHelper.GBKToUTF8(szName)
    self.nMode = nMode
    self.tInfo = tInfo
    UIHelper.SetTouchDownHideTips(self.BtnCalloff, false)
    UIHelper.SetTouchDownHideTips(self.BtnOk, false)
    UIHelper.SetTouchDownHideTips(self.BtnGo, false)
    self:UpdateInfo()
end

function UIStudentInteractionView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIStudentInteractionView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        TeamData.InviteJoinTeam(UIHelper.UTF8ToGBK(self.szName))
    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelInteractActivityPop, self.szName, tMode2RelationType[self.nMode], self.tInfo.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIStudentInteractionView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIStudentInteractionView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIStudentInteractionView:UpdateInfo()
    local szText
    if self.nMode == MODE_MENTOR then
        szText = FormatString(g_tStrings.STR_MENTORMESSAGE_TEXT, g_tStrings.STR_MENTORMESSAGE_MENTOR, self.szName)
    elseif self.nMode == MODE_APPRENTICE then
        szText = FormatString(g_tStrings.STR_MENTORMESSAGE_TEXT, g_tStrings.STR_MENTORMESSAGE_APPRENTICE, self.szName)
    end
    szText = ParseTextHelper.ParseNormalText(szText, false)

    UIHelper.SetRichText(self.LabelHint, szText)
    -- UIHelper.SetVisible(self.BtnOk, self.nMode == MODE_APPRENTICE and self.tInfo.nRoleLevel < g_pClientPlayer.nMaxLevel)
    local headscript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetPlayerHead, self.tInfo.dwPlayerID)
    if headscript then
        headscript:SetHeadInfo(self.tInfo.dwPlayerID, self.tInfo.dwMiniAvatarID, self.tInfo.nRoleType, self.tInfo.dwForceID)
    end
end


return UIStudentInteractionView