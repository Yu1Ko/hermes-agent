-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetImgLogoView
-- Date: 2023-07-25 10:16:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetImgLogoView = class("UIWidgetImgLogoView")

function UIWidgetImgLogoView:OnEnter(szImagePath)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szImagePath)
end

function UIWidgetImgLogoView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetImgLogoView:BindUIEvent()
    
end

function UIWidgetImgLogoView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetImgLogoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetImgLogoView:UpdateInfo(szImagePath)
    UIHelper.SetTexture(self.ImgLogo, UIHelper.UTF8ToGBK(szImagePath))
end


return UIWidgetImgLogoView