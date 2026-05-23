-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelVoiceRoomRulePop
-- Date: 2025-09-23 11:13:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelVoiceRoomRulePop = class("UIPanelVoiceRoomRulePop")

function UIPanelVoiceRoomRulePop:OnEnter(fnConfirm, fnCanCelFunc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnConfirm = fnConfirm
    self.fnCanCelFunc = fnCanCelFunc
    self:UpdateInfo()
end

function UIPanelVoiceRoomRulePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelVoiceRoomRulePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        RoomVoiceData.ChangeAgreenRule(true)  
        if self.fnConfirm then self.fnConfirm() end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        RoomVoiceData.ChangeAgreenRule(false)  
        if self.fnCanCelFunc then self.fnCanCelFunc() end
        UIMgr.Close(self)
    end)
end

function UIPanelVoiceRoomRulePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelVoiceRoomRulePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelVoiceRoomRulePop:UpdateInfo()
    UIHelper.SetRichText(self.RichTextContent, ParseTextHelper.ParseNormalText(g_tStrings.VOICE_ROOM_AGREEN_TEXT, false))
    UIHelper.LayoutDoLayout(self.LayoutBtns)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end


return UIPanelVoiceRoomRulePop