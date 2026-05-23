-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamNoticeEditPop
-- Date: 2024-05-14 09:51:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamNoticeEditPop = class("UITeamNoticeEditPop")

function UITeamNoticeEditPop:OnEnter(bRoomSetUp)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bRoomSetUp = bRoomSetUp
    self.tbBallScript = tbBallScript
    UIHelper.SetNodeSwallowTouches(self.BtnEditBoxTheme, false, true)
    self:InitNoticePop()
end

function UITeamNoticeEditPop:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UITeamNoticeEditPop:BindUIEvent()
    self.EditBoxCentre:registerScriptEditBoxHandler(function(szType, _editbox)
        self.bEditText = true
        if szType == "changed" then
            self:UpdateEditBoxText()
        elseif szType == "ended" then
            UIHelper.SetVisible(self.EditBoxCentre, false)
            UIHelper.SetVisible(self.ScrollViewContent, true)
            UIHelper.SetString(self.LabelContent, self.szContent)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBoxTitle, function()
        self.bEditText = true
        self:UpdateEditBoxTitle()
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end

        self.bEditText = false

        local szTitle = UIHelper.UTF8ToGBK(self.szTitle)
        local szContent = UIHelper.UTF8ToGBK(self.szContent)
        if szTitle == "" and szContent == "" then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "内容不能为空!")
            return
        end
        if self.bRoomSetUp then
            SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, "ROOM_NOTICE", {szTitle, szContent}, "")
        else
            SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_NOTICE", {szTitle, szContent}, "")
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.bEditText then
            local szContent = g_tStrings.STR_CLOSE_TEAMSETUP_1
            if self.bRoomSetUp then
                szContent = g_tStrings.STR_CLOSE_TEAMSETUP_2
            end

            UIHelper.ShowConfirm(szContent, function ()
                Timer.AddFrame(self, 4, function ()
                    UIMgr.Close(VIEW_ID.PanelTeamNoticeEditPop)
                end)
            end,function ()
            end)
        else
            UIMgr.Close(VIEW_ID.PanelTeamNoticeEditPop)
        end
    end)

    UIHelper.BindUIEvent(self.BtnEditBoxTheme, EventType.OnClick, function()
        self.EditBoxCentre:openKeyboard()
        UIHelper.SetVisible(self.ScrollViewContent, false)
    end)
end

function UITeamNoticeEditPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function ()
        if self.bRoomSetUp then
            UIMgr.Close(self)
        end
    end)
end

function UITeamNoticeEditPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamNoticeEditPop:InitNoticePop()
    if self.bRoomSetUp then
        UIHelper.SetString(self.EditBoxCentre, RoomNotice.szContent)
        UIHelper.SetString(self.EditBoxTitle, RoomNotice.szTitle)
        UIHelper.SetString(self.LabelContent, RoomNotice.szContent)
        if RoomNotice.szContent ~= "" then
            UIHelper.SetVisible(self.EditBoxCentre, false)
        end
    else
        UIHelper.SetString(self.EditBoxCentre, TeamNotice.szContent)
        UIHelper.SetString(self.EditBoxTitle, TeamNotice.szTitle)
        UIHelper.SetString(self.LabelContent, TeamNotice.szContent)
        if TeamNotice.szContent ~= "" then
            UIHelper.SetVisible(self.EditBoxCentre, false)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    self:UpdateEditBoxText()
    self:UpdateEditBoxTitle()
end

function UITeamNoticeEditPop:UpdateEditBoxText()
    self.szContent = UIHelper.GetString(self.EditBoxCentre)
    local nCharNum, szContent = GetStringCharCountAndTopChars(self.szContent, 200)
    if nCharNum > 200 then
        nCharNum = 200
    end

    self.szContent = szContent
    UIHelper.SetString(self.EditBoxCentre, szContent)
    UIHelper.SetString(self.LableLimit, ""..nCharNum.."/200")
end

function UITeamNoticeEditPop:UpdateEditBoxTitle()
    self.szTitle = UIHelper.GetString(self.EditBoxTitle) or ""
    self.szTitle = string.gsub(self.szTitle, "\n", "")
    self.szTitle = string.gsub(self.szTitle, "\r", "")

    local nCharNum, szTitle = GetStringCharCountAndTopChars(self.szTitle, 14)
    if nCharNum > 14 then
        nCharNum = 14
    end

    self.szTitle = szTitle
    UIHelper.SetString(self.EditBoxTitle, szTitle)
    UIHelper.SetString(self.LableLimitTitle, ""..nCharNum.."/14")
end

return UITeamNoticeEditPop