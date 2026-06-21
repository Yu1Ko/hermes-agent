local UIMiniSettingSingleOption = class("UIMiniSettingSingleOption")

function UIMiniSettingSingleOption:OnEnter(tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIMiniSettingSingleOption:OnExit()
    self.bInit = false
end

function UIMiniSettingSingleOption:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetAutoGetOption, EventType.OnSelectChanged, function (_, bSelected)
        local tbConfig = self.tbConfig
        if not tbConfig or not tbConfig.fnFunc then return end
        
        local bEnable = not tbConfig.fnEnable
        local szTips = ""
        if not bEnable then
            bEnable, szTips = tbConfig.fnEnable()
        end
        if not bEnable then
            UIHelper.SetVisible(self.ImgOption, false)
            TipsHelper.ShowNormalTip(szTips)
            return
        end

        self.tbConfig.fnFunc(bSelected)
    end)
end

function UIMiniSettingSingleOption:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniSettingSingleOption:UpdateInfo()
    local tbConfig = self.tbConfig
    if not tbConfig or not tbConfig.fnGetValue then return end

    UIHelper.SetString(self.LabelOption, tbConfig.szName)
    UIHelper.SetSelected(self.WidgetAutoGetOption, tbConfig.fnGetValue(), false)

    local bEnable = not tbConfig.fnEnable or tbConfig.fnEnable()
    UIHelper.SetVisible(self.ImgForbid, not bEnable)
    UIHelper.SetNodeGray(self.WidgetAutoGetOption, not bEnable, true)
    UIHelper.SetEnable(self.WidgetAutoGetOption, bEnable)
    if not bEnable then
        UIHelper.SetVisible(self.ImgOption, false)
    end
end

return UIMiniSettingSingleOption