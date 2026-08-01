-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTeammateInfo
-- Date: 2024-05-11 17:47:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTeammateInfo = class("UIWidgetTeammateInfo")

function UIWidgetTeammateInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTeammateInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTeammateInfo:BindUIEvent()
    
end

function UIWidgetTeammateInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTeammateInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTeammateInfo:Show(szName, nX, nY, szFrame)
    self:UpdateInfo(szName, nX, nY, szFrame)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTeammateInfo:UpdateInfo(szName, nX, nY, szFrame)
    UIHelper.SetPosition(self._rootNode, nX, nY)
    UIHelper.SetString(self.LabelNormal01, szName)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSpriteFrame(self.ImgIcon, szFrame)
end


return UIWidgetTeammateInfo