-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipBtn
-- Date: 2022-11-17 21:15:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipBtn = class("UIItemTipBtn")

function UIItemTipBtn:OnEnter(tbInfo)
    self.funcClickCallback = tbInfo.OnClick
    self.szLabelName = tbInfo.szName
    self.bDisabled = tbInfo.bDisabled
    self.szDisableTip = tbInfo.szDisableTip

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetTouchDownHideTips(self.Btn, false)
    self:UpdateInfo()
end

function UIItemTipBtn:OnExit()
    self.bInit = false
end

function UIItemTipBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.Btn, EventType.OnClick, function ()
        self.funcClickCallback()
    end)
end

function UIItemTipBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipBtn:UpdateInfo()
    UIHelper.SetString(self.LabelText, self.szLabelName)

    if self.bDisabled then
        if self.szDisableTip then
            UIHelper.SetButtonState(self.Btn, BTN_STATE.Disable, self.szDisableTip)
        else
            UIHelper.SetButtonState(self.Btn, BTN_STATE.Disable)
        end
    else
        UIHelper.SetButtonState(self.Btn, BTN_STATE.Normal)
    end
end


return UIItemTipBtn