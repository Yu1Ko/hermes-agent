-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceAdjustTitleCell
-- Date: 2023-12-07 16:22:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceAdjustTitleCell = class("UIBuildFaceAdjustTitleCell")

function UIBuildFaceAdjustTitleCell:OnEnter(szTitle, fnResetCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.fnResetCallback = fnResetCallback
    self:UpdateInfo()
end

function UIBuildFaceAdjustTitleCell:OnExit()
    self.bInit = false
end

function UIBuildFaceAdjustTitleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        if self.fnResetCallback then
            self.fnResetCallback()
        end
    end)
end

function UIBuildFaceAdjustTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceAdjustTitleCell:UpdateInfo()
    UIHelper.SetString(self.LabelTittle, self.szTitle)
    UIHelper.SetVisible(self.BtnReset, IsFunction(self.fnResetCallback))
end


return UIBuildFaceAdjustTitleCell