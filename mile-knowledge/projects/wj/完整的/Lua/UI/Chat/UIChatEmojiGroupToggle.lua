-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmojiGroupToggle
-- Date: 2023-02-16 17:48:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatEmojiGroupToggle = class("UIChatEmojiGroupToggle")

function UIChatEmojiGroupToggle:OnEnter(tbGroupConf, bSelectedOnInit, bEnable)
    self.tbGroupConf = tbGroupConf
    self.nGroupID = self.tbGroupConf and self.tbGroupConf.nGroupID
    self.bSelectedOnInit = bSelectedOnInit
    self.bEnable = bEnable

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatEmojiGroupToggle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatEmojiGroupToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogExpression, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnChatEmojiGroupSelected, self.nGroupID)
            UIHelper.SetVisible(self.ImgRedpoint, false)
        end
    end)
end

function UIChatEmojiGroupToggle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatEmojiGroupToggle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmojiGroupToggle:UpdateInfo()
    local szGroupIcon = self.tbGroupConf and self.tbGroupConf.szGroupIcon
    UIHelper.SetSpriteFrame(self.ImgIcon, szGroupIcon)

    if self.bSelectedOnInit then
        UIHelper.SetSelected(self.TogExpression, true)
    else
        UIHelper.SetSelected(self.TogExpression, false)
    end

    UIHelper.SetVisible(self.ImgRedpoint, RedpointHelper.ChatEmotion_IsNew(self.nGroupID))

    UIHelper.SetEnable(self.TogExpression, self.bEnable)
    UIHelper.SetNodeGray(self.TogExpression, not self.bEnable, true)
end


return UIChatEmojiGroupToggle