-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMRightCell
-- Date: 2022-11-15 14:50:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMRightCell = class("UIGMRightCell")

function UIGMRightCell:OnEnter(tbGMPanelRight, tbSelectCell)
    if not tbSelectCell then return end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbGMPanelRight = tbGMPanelRight
    self.tbSelectCell = tbSelectCell
    self.tBtnStatus = tbSelectCell.tBtnStatus
    self.tBtnLabel = tbSelectCell.tBtnLabel
    if self.tbSelectCell.tBtnStatus then
        self.BtnOperate:setVisible(self.tBtnStatus.BtnOperate)
        self.BtnOperate1:setVisible(self.tBtnStatus.BtnOperate1)
        self.BtnOperate2:setVisible(self.tBtnStatus.BtnOperate2)
        self.BtnOperate3:setVisible(self.tBtnStatus.BtnOperate3)
        self.BtnOperate4:setVisible(self.tBtnStatus.BtnOperate4)
    end
    self:UpdateInfo()
end

function UIGMRightCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMRightCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOperate, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnOperate(self.tbSelectCell)
    end)

    UIHelper.BindUIEvent(self.BtnOperate1, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnOperate1(self.tbSelectCell)
    end)

    UIHelper.BindUIEvent(self.BtnOperate2, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnOperate2(self.tbSelectCell)
    end)

    UIHelper.BindUIEvent(self.BtnOperate3, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnOperate3(self.tbSelectCell)
    end)

    UIHelper.BindUIEvent(self.BtnOperate4, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnOperate4(self.tbSelectCell)
    end)
end

function UIGMRightCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMRightCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMRightCell:UpdateInfo()
    if not self.tbSelectCell then return end
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.tbSelectCell.Name))
    UIHelper.SetString(self.LabelButton, self.tbSelectCell.ButtonLabel)
    if self.tBtnLabel then
        UIHelper.SetString(self.LabelOperate1, self.tBtnLabel.LabelOperate1)
        UIHelper.SetString(self.LabelOperate2, self.tBtnLabel.LabelOperate2)
        UIHelper.SetString(self.LabelOperate3, self.tBtnLabel.LabelOperate3)
        UIHelper.SetString(self.LabelOperate4, self.tBtnLabel.LabelOperate4)
    end
end

return UIGMRightCell