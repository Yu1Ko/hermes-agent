-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangSettingTogGroupView
-- Date: 2024-01-01 20:52:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangSettingTogGroupView = class("UIWidgetBahuangSettingTogGroupView")

function UIWidgetBahuangSettingTogGroupView:OnEnter(tbSettingList)
    self.tbSettingList = tbSettingList
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetBahuangSettingTogGroupView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangSettingTogGroupView:BindUIEvent()
    for nIndex, tbSettingInfo in ipairs(self.tbSettingList) do
        UIHelper.BindUIEvent(self.tbTogSelectBg[nIndex], EventType.OnSelectChanged, function(_, bSelect)
            tbSettingInfo.funcSetting(bSelect)
        end)

    end
end

function UIWidgetBahuangSettingTogGroupView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangSettingTogGroupView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangSettingTogGroupView:UpdateInfo()
    local nDataLen = #self.tbSettingList
    for nIndex, widget in ipairs(self.tbWidgetBahuangSettingTog) do 
        UIHelper.SetVisible(widget, nIndex <= nDataLen)
        local tbSettingInfo = self.tbSettingList[nIndex]
        if tbSettingInfo then 
            UIHelper.SetString(self.tbLabelTogOpcion[nIndex], tbSettingInfo.szName)
            UIHelper.SetSelected(self.tbTogSelectBg[nIndex], tbSettingInfo.bVisible, false)
        end
        UIHelper.SetSwallowTouches(self.tbTogSelectBg[nIndex], false)
    end
end


return UIWidgetBahuangSettingTogGroupView