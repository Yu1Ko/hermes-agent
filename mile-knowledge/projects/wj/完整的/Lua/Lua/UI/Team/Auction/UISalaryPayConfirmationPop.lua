-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISalaryPayConfirmationPop
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISalaryPayConfirmationPop = class("UISalaryPayConfirmationPop")

function UISalaryPayConfirmationPop:OnEnter(tData)
    if not tData then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tData = tData
    self:UpdateInfo()
end

function UISalaryPayConfirmationPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UISalaryPayConfirmationPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReject, EventType.OnClick, function ()
        if not self.tData.fOnRefuse then
            return
        end
        self.tData.fOnRefuse()
    end)

    UIHelper.BindUIEvent(self.BtnDetails, EventType.OnClick, function ()
        if not self.tData.fOnDetail then
            return
        end
        self.tData.fOnDetail()
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function ()
        if not self.tData.fOnAccept then
            return
        end
        self.tData.fOnAccept()
    end)
end

function UISalaryPayConfirmationPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISalaryPayConfirmationPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISalaryPayConfirmationPop:UpdateInfo()
    UIHelper.SetRichText(self.RichTextContent, self.tData.szRichText)
end

return UISalaryPayConfirmationPop