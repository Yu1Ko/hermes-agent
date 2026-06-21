-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationQRCode
-- Date: 2026-04-02 20:28:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationQRCode = class("UIOperationQRCode")

function UIOperationQRCode:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self.bMobileVisible = false

    self:UpdateInfo()
end

function UIOperationQRCode:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationQRCode:BindUIEvent()

end

function UIOperationQRCode:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationQRCode:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationQRCode:UpdateInfo()
    local tInfo = OperationCenterData.GetOperationInfo(self.nOperationID)
    self:UpdateByInfo(tInfo)
end

function UIOperationQRCode:UpdateByInfo(tInfo)
    if not tInfo then
        return
    end
    local szPath = tInfo.szQRCodePath
    if szPath ~= "" then
        szPath = string.gsub(szPath, "\\", "/")
        szPath = string.gsub(szPath, "ui/Image/UItimate/OperationCenter/SinglePicture", "Resource/OperationCenter")
        szPath = string.gsub(szPath, "tga", "png")
    end
    UIHelper.SetTexture(self.ImgIQRcode, szPath)

    local szText = tInfo.szQRCodeText
    UIHelper.SetString(self.LabelQRcode, UIHelper.GBKToUTF8(szText))
    UIHelper.WidgetFoceDoAlign(self)
    UIHelper.LayoutDoLayout(self.LayoutContent)

    self:UpdateVisible(true)
end

function UIOperationQRCode:SetMobileVisible(bVisible)
    self.bMobileVisible = bVisible
end

function UIOperationQRCode:UpdateVisible(bVisible)
    if Platform.IsMobile() then
        bVisible = bVisible and self.bMobileVisible
    end
    UIHelper.SetVisible(self._rootNode, bVisible)
end

return UIOperationQRCode