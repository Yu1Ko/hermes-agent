local UIChatJiangHuCell = class("UIChatJiangHuCell")

function UIChatJiangHuCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatJiangHuCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatJiangHuCell:BindUIEvent()
    
end

function UIChatJiangHuCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatJiangHuCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatJiangHuCell:UpdateInfo()
    
end


return UIChatJiangHuCell