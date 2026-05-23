local UIWuWeiJueKungfuToggle = class("UIWuWeiJueKungfuToggle")

function UIWuWeiJueKungfuToggle:Enter()
end

function UIWuWeiJueKungfuToggle:Exit()
    
end

function UIWuWeiJueKungfuToggle:UpdateInfo(szName, dwKungfuID)
    UIHelper.SetLabel(self.LabelNormal, szName)
    UIHelper.SetLabel(self.LabelUp, szName)

    local szIcon = PlayerKungfuImg[dwKungfuID] or ""

    UIHelper.SetSpriteFrame(self.ImgNormal, szIcon)
    UIHelper.SetSpriteFrame(self.ImgSelected, szIcon)
end

function UIWuWeiJueKungfuToggle:SetSelected(bSelected)
    UIHelper.SetVisible(self.LabelNormal, not bSelected)
    UIHelper.SetVisible(self.WidgetUpAll, bSelected)
end

return UIWuWeiJueKungfuToggle