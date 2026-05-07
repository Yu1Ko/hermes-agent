-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeCustomBuyIndexCell
-- Date: 2023-04-13 15:56:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeCustomBuyIndexCell = class("UIHomelandMyHomeCustomBuyIndexCell")

function UIHomelandMyHomeCustomBuyIndexCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomelandMyHomeCustomBuyIndexCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeCustomBuyIndexCell:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogAllot, false)
    UIHelper.BindUIEvent(self.TogAllot, EventType.OnClick, function ()
        self.fnClickCallback(self.tbInfo.nIndex)
    end)
end

function UIHomelandMyHomeCustomBuyIndexCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomeCustomBuyIndexCell:UpdateInfo()
    local nIndex = self.tbInfo.nIndex
    if nIndex == 0 then
        nIndex = "未分配"
    end
    UIHelper.SetString(self.LabelNum1, nIndex)
    UIHelper.SetString(self.LabelNum2, nIndex)
end

function UIHomelandMyHomeCustomBuyIndexCell:SetClickCallback(fnClickCallback)
    self.fnClickCallback = fnClickCallback
end


return UIHomelandMyHomeCustomBuyIndexCell