-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBannerView
-- Date: 2023-03-22 11:04:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBannerView = class("UICoinShopBannerView")

function UICoinShopBannerView:OnEnter(nType, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nType = nType
    self.tData = tData
    self:UpdateInfo()
end

function UICoinShopBannerView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopBannerView:BindUIEvent()
end

function UICoinShopBannerView:RegEvent()
end

function UICoinShopBannerView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopBannerView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchorNew, self.nType == 1)
    UIHelper.SetVisible(self.WidgetAnchorActivityBanner, self.nType == 2)
    if self.nType == 1 then
        local script = UIHelper.GetBindScript(self.WidgetAnchorNew)
        script:OnEnter(self.tData)
    else
        local script = UIHelper.GetBindScript(self.WidgetAnchorActivityBanner)
        script:OnEnter(self.tData)
    end
end

return UICoinShopBannerView