-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHintShuoShuRenCell
-- Date: 2024-02-28 20:55:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHintShuoShuRenCell = class("UIWidgetHintShuoShuRenCell")

function UIWidgetHintShuoShuRenCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetSpriteFrame(self.ImgIcon, "UIAtlas2_Public_PublicHint_PublicHint_ShuoShuRenBg1.png")
    end
    self:PlayAnimtion()
end

function UIWidgetHintShuoShuRenCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHintShuoShuRenCell:BindUIEvent()
    
end

function UIWidgetHintShuoShuRenCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHintShuoShuRenCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHintShuoShuRenCell:PlayAnimtion()
    UIHelper.PlayAni(self, self._rootNode, "AniShuoShuRen")
end


return UIWidgetHintShuoShuRenCell