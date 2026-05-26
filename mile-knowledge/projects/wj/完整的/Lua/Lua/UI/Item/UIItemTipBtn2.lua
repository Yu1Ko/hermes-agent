-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipBtn2
-- Date: 2022-11-17 21:15:04
-- Desc: ?
-- ---------------------------------------------------------------------------------
local BASE_FONT_SIZE = 20
local UIItemTipBtn2 = class("UIItemTipBtn2")
function UIItemTipBtn2:OnEnter(tbInfo)
    self.funcClickCallback = tbInfo.OnClick
    self.szLabelName = tbInfo.szName
    self.bDisabled = tbInfo.bDisabled
    self.szDisableTip = tbInfo.szDisableTip
    self.bNormalBtn = true
    self.bFobidCheckBtnType = tbInfo.bFobidCheckBtnType or false

    if tbInfo.bNormalBtn ~= nil then self.bNormalBtn = tbInfo.bNormalBtn end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipBtn2:OnExit()
    self.bInit = false
end

function UIItemTipBtn2:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTipOperation, EventType.OnClick, function ()
        if self.funcClickCallback then
            self.funcClickCallback()
        end
    end)
    UIHelper.SetSwallowTouches(self.BtnTipOperation, false)
    UIHelper.SetTouchDownHideTips(self.BtnTipOperation, false)
end

function UIItemTipBtn2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipBtn2:UpdateInfo()
    local szKeyName = self.szLabelName
    local bImportentBtn = not self.bNormalBtn

    if table.contain_value(ITEMTIPS_IMPORTANT_BTN, szKeyName) and not self.bFobidCheckBtnType then
        bImportentBtn = true
    end
    local label = bImportentBtn and self.LabelCommon or self.LabelText
    UIHelper.SetVisible(self.WidgetCommon, bImportentBtn)
    UIHelper.SetVisible(self.WidgetOther, not bImportentBtn)

    local nLen = UIHelper.GetUtf8Len(szKeyName)
    if nLen >= 5 then
        UIHelper.SetFontSize(label, 16)
        label:setLineHeight(16)
        UIHelper.SetContentSize(label, 16, 100)
    end

    UIHelper.SetString(label, szKeyName)
    if self.bDisabled then
        if self.szDisableTip then
            UIHelper.SetButtonState(self.BtnTipOperation, BTN_STATE.Disable, self.szDisableTip)
        else
            UIHelper.SetButtonState(self.BtnTipOperation, BTN_STATE.Disable)
        end
    else
        UIHelper.SetButtonState(self.BtnTipOperation, BTN_STATE.Normal)
    end
end


return UIItemTipBtn2