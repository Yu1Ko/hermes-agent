-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsMultipleChoiceBtn
-- Date: 2022-12-23 15:32:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsMultipleChoiceBtn = class("UIWidgetSettingsMultipleChoiceBtn")

function UIWidgetSettingsMultipleChoiceBtn:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local szName = tInfo.szName
    local func = tInfo.func
    local fnSelected = tInfo.fnSelected
    local bRecommend = tInfo.bRecommend
    local funcEnable = tInfo.funcEnable

    UIHelper.SetTouchDownHideTips(self.BtnSelect, false)

    UIHelper.SetString(self.LabelSelect, UIHelper.LimitUtf8Len(szName,16))
    UIHelper.SetVisible(self.ImgCheck, fnSelected())
    UIHelper.SetVisible(self.ImgRecommend, bRecommend)

    if funcEnable then
        local bState = funcEnable()
        UIHelper.SetNodeGray(self._rootNode,not bState ,true)
    end
    
    self.szName = szName
    self.func = func
    self.funcEnable = funcEnable
end

function UIWidgetSettingsMultipleChoiceBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsMultipleChoiceBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function()
        if IsFunction(self.funcEnable) then
            local bEnable, szErrorMsg = self.funcEnable()
            if not bEnable then
                if szErrorMsg then
                    TipsHelper.ShowNormalTip(szErrorMsg)
                end
                Event.Dispatch(EventType.HideAllHoverTips)
                return
            end
        end

        if self.func then
            self.func(self.szName)
        end
    end)
end

function UIWidgetSettingsMultipleChoiceBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettingsMultipleChoiceBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSettingsMultipleChoiceBtn:UpdateInfo()

end

return UIWidgetSettingsMultipleChoiceBtn