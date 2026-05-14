-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITongJianLeftCell
-- Date: 2023-05-16 16:38:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITongJianLeftCell = class("UITongJianLeftCell")

function UITongJianLeftCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITongJianLeftCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITongJianLeftCell:BindUIEvent()
    
end

function UITongJianLeftCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITongJianLeftCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITongJianLeftCell:UpdateInfo()
    
end


return UITongJianLeftCell