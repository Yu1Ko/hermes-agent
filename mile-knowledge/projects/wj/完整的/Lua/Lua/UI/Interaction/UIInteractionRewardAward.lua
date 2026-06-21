-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractionRewardAward
-- Date: 2023-02-21 17:29:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractionRewardAward = class("UIInteractionRewardAward")

function UIInteractionRewardAward:OnEnter(v)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(v)
end

function UIInteractionRewardAward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractionRewardAward:BindUIEvent()

end

function UIInteractionRewardAward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInteractionRewardAward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionRewardAward:UpdateInfo(v)
    local charCount, szTopChars = UIHelper.TruncateString(UIHelper.GBKToUTF8(v.szGoodsName), 5, "...")
    UIHelper.SetString(self.LabelTitle, szTopChars)
    UIHelper.SetString(self.LabelNum,v.nGoodsPrice)
    UIHelper.SetSpriteFrame(self.ImgAward,MentorValueGift[v.dwID] )
end


return UIInteractionRewardAward