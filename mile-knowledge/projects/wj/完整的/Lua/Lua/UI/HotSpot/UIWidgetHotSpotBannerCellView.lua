-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHotSpotBannerCellView
-- Date: 2023-06-15 16:04:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHotSpotBannerCellView = class("UIWidgetHotSpotBannerCellView")

function UIWidgetHotSpotBannerCellView:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbData then
        self.tbData = tbData
        self:UpdateInfo()
    end
end

function UIWidgetHotSpotBannerCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHotSpotBannerCellView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBannerCell, EventType.OnClick, function()
        local szUrl = self.tbData.tTab.szUrl
        local szLink = self.tbData.tTab.szLink
        if szUrl and szUrl ~= "" then
            UIHelper.OpenWebWithDefaultBrowser(szUrl)
        elseif szLink and szLink ~= "" then
            string.execute(szLink)
			UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
        end
    end)
end

function UIWidgetHotSpotBannerCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHotSpotBannerCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHotSpotBannerCellView:UpdateInfo()
    local szLink = self.tbData.tTab.szLink
    if self.tbData.tTab.szImage then
        UIHelper.SetTexture(self.ImgBanner, self.tbData.tTab.szImage, false)
    elseif self.tbData.tTab.szInPakPath and self.tbData.tTab.szInPakFrame then
        local szInPakPath = self.tbData.tTab.szInPakPath
        if not Platform.IsWindows() then
            local szExt = string.sub(szInPakPath, -4, -1)
            if szExt == ".png" then
                szInPakPath = string.sub(szInPakPath, 1 , -5)..".mpng"
            end
        end
        UIHelper.SetTexture(self.ImgBanner, szInPakPath, false)
    end
end


return UIWidgetHotSpotBannerCellView