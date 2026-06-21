-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiniGameHighLightBarView
-- Date: 2024-01-19 17:29:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMiniGameHighLightBarView = class("UIWidgetMiniGameHighLightBarView")

function UIWidgetMiniGameHighLightBarView:OnEnter(nStartPos, nLength)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nStartPos = nStartPos
    self.nLength = nLength
    self:UpdateInfo()
end

function UIWidgetMiniGameHighLightBarView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMiniGameHighLightBarView:BindUIEvent()
    
end

function UIWidgetMiniGameHighLightBarView:RegEvent()
  
end

function UIWidgetMiniGameHighLightBarView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMiniGameHighLightBarView:UpdateInfo()
    Timer.AddFrame(self, 1, function()
        UIHelper.SetPositionX(self._rootNode, self.nStartPos)
        UIHelper.SetWidth(self._rootNode, self.nLength)
        UIHelper.SetWidth(self.ImgBar, self.nLength + 36)
        UIHelper.SetPositionX(self.ImgBar, self.nLength / 2)
        self:UpdateState()
    end)
end

--1、normal 2、highlight 3、success
function UIWidgetMiniGameHighLightBarView:UpdateState(nState)
    self.nState = nState or self.nState
    UIHelper.SetSpriteFrame(self.ImgBar, tbMiniGameHighLightBar[self.nState])
end


return UIWidgetMiniGameHighLightBarView