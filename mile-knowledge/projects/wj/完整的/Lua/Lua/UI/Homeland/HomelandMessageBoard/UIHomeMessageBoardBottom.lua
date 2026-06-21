-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeMessageBoardBottom
-- Date: 2024-01-10 17:15:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeMessageBoardBottom = class("UIHomeMessageBoardBottom")

function UIHomeMessageBoardBottom:OnEnter(bIsHouseOwner, uPermission)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bIsHouseOwner = bIsHouseOwner
    self.uPermission = uPermission
    self.bIsOpenEdit = bIsHouseOwner or uPermission == 1
    self:UpdateInfo()
end

function UIHomeMessageBoardBottom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeMessageBoardBottom:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeMessageBoardDeleteMsg, false)
    end)

    UIHelper.BindUIEvent(self.TogChooseAll, EventType.OnSelectChanged, function (tog,bSelected)
        Event.Dispatch(EventType.OnHomeMessageBoardSelectAllMsg, bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnEmoji, EventType.OnClick, function()
        self:ShowEmoji()
    end)

    UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function ()
        local szContent = UIHelper.GetText(self.EditBox03)
        Event.Dispatch(EventType.OnHomeMessageBoardSendMsg, szContent, 1)
        UIHelper.SetText(self.EditBox03, "")
    end)

    UIHelper.RegisterEditBoxBegan(self.EditBox03, function()
        if not self.bIsOpenEdit then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_MESSAGE_PERMISSION)
            return
        end
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox03, function()
        if not self.bIsOpenEdit then
            UIHelper.SetText(self.EditBox03, "")
            return
        end
    end)
end

function UIHomeMessageBoardBottom:RegEvent()
    Event.Reg(self, EventType.OnHomeMessageBoardDeleteMsg, function (bEnterDeleteMode)
        UIHelper.SetVisible(self.WidgetDelete, bEnterDeleteMode)
        UIHelper.SetVisible(self.WidgetInput, not bEnterDeleteMode)
    end)

    Event.Reg(self, EventType.OnChatEmojiClosed, function()
        self:HideEmoji()
    end)

    Event.Reg(self, EventType.OnChatEmojiSelected, function(tbEmojiConf)
        self:HideEmoji()

        if not tbEmojiConf then
            return
        end

        if not self.bIsOpenEdit then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_MESSAGE_PERMISSION)
            return
        end

        local nID = tbEmojiConf.nID
        local szEmoji = string.format("[%s]", tbEmojiConf.szName)

        if nID == -1 then
            UIMgr.Open(VIEW_ID.PanelCollectEmoticons)
        else
            self:AppendInput(szEmoji)
        end
    end)
end

function UIHomeMessageBoardBottom:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeMessageBoardBottom:UpdateInfo()
    UIHelper.SetSelected(self.TogChooseAll, false)
    if not self.bIsOpenEdit then
        UIHelper.SetPlaceHolder(self.EditBox03, g_tStrings.STR_HOMELAND_MESSAGE_PERMISSION)
        UIHelper.SetButtonState(self.BtnSend, BTN_STATE.Disable, g_tStrings.STR_HOMELAND_MESSAGE_PERMISSION, true)
    end
end

function UIHomeMessageBoardBottom:ShowEmoji()
    if not self.scriptEmoji then
        self.scriptEmoji = UIHelper.AddPrefab(PREFAB_ID.WidgetChatExpression, self.WidgetChatExpressionShell)
    else
        if self.scriptEmoji.nCurGroupID == -1 then
            self.scriptEmoji:UpdateInfo_EmojiList()
        end
    end
    UIHelper.SetVisible(self.WidgetChatExpressionShell, true)
end

function UIHomeMessageBoardBottom:HideEmoji()
    UIHelper.SetVisible(self.WidgetChatExpressionShell, false)
end

function UIHomeMessageBoardBottom:AppendInput(szContent)
    if string.is_nil(szContent) then
        return
    end
    local szMsg = UIHelper.GetString(self.EditBox03)..szContent
    UIHelper.SetString(self.EditBox03, szMsg)
end

return UIHomeMessageBoardBottom