-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangPlayerView
-- Date: 2024-01-25 19:56:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangPlayerView = class("UIWidgetBahuangPlayerView")

function UIWidgetBahuangPlayerView:OnEnter(tbPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbPlayer = tbPlayer
    self:UpdateInfo()
end

function UIWidgetBahuangPlayerView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangPlayerView:BindUIEvent()
    
end

function UIWidgetBahuangPlayerView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangPlayerView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangPlayerView:UpdateInfo()
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg[self.tbPlayer[2]])
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.tbPlayer[1]))
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIWidgetBahuangPlayerView