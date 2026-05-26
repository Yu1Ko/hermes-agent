-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAddStudentPopView
-- Date: 2023-02-09 10:02:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAddStudentPopView = class("UIAddStudentPopView")

local function IsMsgEditAllowed()
    return UI_IsActivityOn(ACTIVITY_ID.ALLOW_EDIT) -- 此活动在时间上一直开启，通过策划调用指令来改变实际的开启状态
end

function UIAddStudentPopView:OnEnter(bFindMaster, bReOpen)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bFindMaster = bFindMaster
    self.bSentToWorld = true
    self.bReOpen = bReOpen

    if bReOpen then
        if self.bFindMaster then
            ApplyApprenticePushList(1, -1, -1)
        else
            ApplyMentorPushList(1, -1, -1)
        end
    end

    UIHelper.SetEnable(self.EditBox , IsMsgEditAllowed())
    self:UpdateInfo(bReOpen)
end

function UIAddStudentPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAddStudentPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        if self.bReOpen then
            Event.Dispatch(EventType.OnMentorRecall)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel1,EventType.OnClick,function ()
        Event.Dispatch(EventType.OnMentorRecall)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm,EventType.OnClick,function ()
        self:PublishInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRepublish,EventType.OnClick,function ()
        self:PublishInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRecall,EventType.OnClick,function ()
        if self.bFindMaster then
            UnRegisterApprenticePushInfo(g_pClientPlayer.dwID)
        else
            UnRegisterMentorPushInfo(g_pClientPlayer.dwID)
        end

        TipsHelper.ShowNormalTip(g_tStrings.MENTOR_RECALL_SUCCESS)

        Event.Dispatch(EventType.OnMentorRecall)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogCheck,EventType.OnSelectChanged,function (_,bSelected)
        self.bSentToWorld = bSelected
    end)

    --点击写入框
    for index,toggle in ipairs(self.tbTGSelect) do
        UIHelper.BindUIEvent(toggle,EventType.OnSelectChanged,function (_,bSelected)
            if bSelected then
                local szText = UIHelper.GetText(self.EditBox)
                if szText and szText ~= "" then
                    szText = szText.." "
                end
                szText = szText..UIHelper.GetString(self.tbTGLabel[index])
                --判断一下字数
                local _, szNumTitle = UIHelper.TruncateString(szText, 31)
                UIHelper.SetText(self.EditBox,szNumTitle)
                for i,toggle in ipairs(self.tbTGSelect) do
                    if i ~= index and UIHelper.GetSelected(toggle) then
                        UIHelper.SetSelected(toggle,false)
                    end
                end
            end
        end)
    end
    --超过31个字就写31
    UIHelper.RegisterEditBoxEnded(self.EditBox, function()
        local szCMD = UIHelper.GetString(self.EditBox)
        local _, szNumTitle = UIHelper.TruncateString(szCMD, 31)
        UIHelper.SetText(self.EditBox,szNumTitle)
    end)
end

function UIAddStudentPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY_INFO_SINGLE", function ()
        self:UpdateComment()
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY_INFO_SINGLE", function ()
        self:UpdateComment()
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        if dwActivityID == ACTIVITY_ID.ALLOW_EDIT then
            local bAllowed = IsMsgEditAllowed()
            if not bAllowed then
                UIMgr.Close(self)
            end
        end
    end)
end

function UIAddStudentPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAddStudentPopView:UpdateInfo(bReOpen)
    if self.bFindMaster then
        UIHelper.SetString(self.LabelTitle, g_tStrings.MENTOR_FIND_TITLE_1)
    else
        UIHelper.SetString(self.LabelTitle, g_tStrings.MENTOR_FIND_TITLE_3)
    end

    if bReOpen then
        UIHelper.SetVisible(self.WidgetBtnList01, false)
        UIHelper.SetVisible(self.WidgetBtnList02, true)
    end
end

function UIAddStudentPopView:UpdateComment()
    local szComment
    if self.bFindMaster then
        szComment = GetPushApprenticeList()[1].szComment
    else
        szComment = GetPushMentorList()[1].szComment
    end

    UIHelper.SetText(self.EditBox, UIHelper.GBKToUTF8(szComment))
end

function UIAddStudentPopView:PublishInfo()
    local szMsg = UIHelper.GetString(self.EditBox)
    if TextFilterCheck(szMsg) == false then
        _, szMsg = TextFilterReplace(szMsg)
    end

    local szSuffix
    if self.bFindMaster then
        RegisterApprenticePushInfo(UIHelper.UTF8ToGBK(szMsg))
        FellowshipData.dwFindMas = GetTickCount()
        szSuffix = g_tStrings.MENTOR_FIND_MASTER_PUBLISH
    else
        RegisterMentorPushInfo(UIHelper.UTF8ToGBK(szMsg));
        FellowshipData.dwFindA = GetTickCount()
        szSuffix = g_tStrings.MENTOR_FIND_APP_PUBLISH
    end

    if self.bSentToWorld then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end
        Player_Talk(g_pClientPlayer, PLAYER_TALK_CHANNEL.WORLD, "", {{ type = "text", text = UIHelper.UTF8ToGBK(szSuffix..szMsg .. "\n")}})
    end

    UIMgr.Close(self)
end

return UIAddStudentPopView