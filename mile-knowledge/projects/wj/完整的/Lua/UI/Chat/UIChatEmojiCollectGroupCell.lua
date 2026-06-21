-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmojiCollectGroupCell
-- Date: 2022-12-24 17:20:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatEmojiCollectGroupCell = class("UIChatEmojiCollectGroupCell")

function UIChatEmojiCollectGroupCell:OnEnter(tbEmojiConf)
    self.tbEmojiConf = tbEmojiConf
    self.nID = self.tbEmojiConf.nID
    self.bIsFavorite = ChatData.CheckIsFavoriteEmoji(self.nID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatEmojiCollectGroupCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatEmojiCollectGroupCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnExpression, EventType.OnClick, function()
        if not self.bIsFavorite and ChatData.CheckIsFavoriteOverLimit() then
            TipsHelper.ShowNormalTip(g_tStrings.tEmotionFavorites[EMOTION_FAVORITES_RET_CODE.COUNT_LIMIT])
            return
        end

        ChatData.SetFavoriteEmoji(self.nID, not self.bIsFavorite)
    end)
end

function UIChatEmojiCollectGroupCell:RegEvent()
    Event.Reg(self, "REMOTE_EMOTION_FAVORITES_EVENT", function()
        self.bIsFavorite = ChatData.CheckIsFavoriteEmoji(self.nID)
        self:UpdateInfo_Favorite()
    end)
end

function UIChatEmojiCollectGroupCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmojiCollectGroupCell:UpdateInfo()
    local nSpriteAnimID = self.tbEmojiConf.nSpriteAnimID
    UIHelper.PlaySpriteFrameAnimtion(self.ImgExpression, nSpriteAnimID)
    UIHelper.SetSwallowTouches(self.BtnExpression, false)

    self:UpdateInfo_Favorite()
end

function UIChatEmojiCollectGroupCell:UpdateInfo_Favorite()
    UIHelper.SetVisible(self.ImgExpressionCollect, self.bIsFavorite)
end


return UIChatEmojiCollectGroupCell