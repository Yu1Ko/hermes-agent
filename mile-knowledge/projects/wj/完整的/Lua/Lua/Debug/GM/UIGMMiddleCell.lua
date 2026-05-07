-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMMiddleCell
-- Date: 2022-11-15 14:50:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMMiddleCell = class("UIGMMiddleCell")

function UIGMMiddleCell:OnEnter(tbGMView, tbSelectCell)
    if not tbGMView or not tbSelectCell then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbGMView = tbGMView
    self.tbCellLeft = tbSelectCell.tbCellLeft
    self.tbCellRight = tbSelectCell.tbCellRight
    self.BtnCellLeft:setVisible(true)
    self.BtnCellRight:setVisible(true)
    self:UpdateInfo()
end

function UIGMMiddleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMMiddleCell:BindUIEvent()
    -- 左侧点击调用左侧Cell表中的点击方法
    UIHelper.BindUIEvent(self.BtnCellLeft, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelGMRightExpansion)
        UIMgr.Close(VIEW_ID.PanelConfigureAccount)
        -- self.tbGMView.PanelRightView:setVisible(true)
        self.tbGMView:InitLayOut()
        self.tbCellLeft:OnClick(self.tbGMView)
    end)

    -- 右侧点击调用右侧侧Cell表中的点击方法
    UIHelper.BindUIEvent(self.BtnCellRight, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelGMRightExpansion)
        UIMgr.Close(VIEW_ID.PanelConfigureAccount)
        -- self.tbGMView.PanelRightView:setVisible(true)
        self.tbGMView:InitLayOut()
        self.tbCellRight:OnClick(self.tbGMView)
    end)
end

function UIGMMiddleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMMiddleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMMiddleCell:UpdateInfo()
    if not self.tbCellLeft then
        self.BtnCellLeft:setVisible(false)
    else
        UIHelper.SetString(self.LabelSelectLeft, self.tbCellLeft.text)
    end

    if not self.tbCellRight then
        self.BtnCellRight:setVisible(false)
    else
        UIHelper.SetString(self.LabelSelectRight, self.tbCellRight.text)
    end
end

return UIGMMiddleCell