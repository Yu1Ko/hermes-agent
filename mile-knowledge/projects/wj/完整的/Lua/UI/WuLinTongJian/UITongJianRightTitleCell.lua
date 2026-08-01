-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITongJianRightTitleCell
-- Date: 2023-05-16 17:53:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITongJianRightTitleCell = class("UITongJianRightTitleCell")

function UITongJianRightTitleCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITongJianRightTitleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITongJianRightTitleCell:BindUIEvent()
    
end

function UITongJianRightTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITongJianRightTitleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITongJianRightTitleCell:UpdateInfo()
    
end


return UITongJianRightTitleCell