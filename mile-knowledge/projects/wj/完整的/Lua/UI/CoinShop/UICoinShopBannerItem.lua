-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBannerItem
-- Date: 2023-03-22 11:18:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBannerItem = class("UICoinShopBannerItem")

function UICoinShopBannerItem:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICoinShopBannerItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopBannerItem:BindUIEvent()
end

function UICoinShopBannerItem:RegEvent()
end

function UICoinShopBannerItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopBannerItem:UpdateInfo()
    local szBgPath = self.tbInfo.szImagePath
    if szBgPath then
        szBgPath = string.gsub(szBgPath, "ui/Image", "Resource")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        self.ImgActivityBanner01:setTexture(szBgPath, false)
    end
    UIHelper.SetVisible(self.BtnGo, false)
    UIHelper.SetVisible(self.LayoutLimit, false)
    UIHelper.SetVisible(self.LabelActivityBannerTime01, false)
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.LayoutBannerMoney, false)
end

function UICoinShopBannerItem:SetGet(bGet)
    UIHelper.SetVisible(self.ImgGot, bGet)
end

return UICoinShopBannerItem