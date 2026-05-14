-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmojiCell
-- Date: 2022-12-24 19:10:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatEmojiCell = class("UIChatEmojiCell")

function UIChatEmojiCell:OnEnter(tbEmojiConf)
    self.tbEmojiConf = tbEmojiConf

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatEmojiCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatEmojiCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnExpression, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnChatEmojiSelected, self.tbEmojiConf)
    end)
    
end

function UIChatEmojiCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatEmojiCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmojiCell:UpdateInfo()
    local nSpriteAnimID = self.tbEmojiConf and self.tbEmojiConf.nSpriteAnimID or 0
    UIHelper.PlaySpriteFrameAnimtion(self.imgExpressionIcon, nSpriteAnimID)
end


return UIChatEmojiCell