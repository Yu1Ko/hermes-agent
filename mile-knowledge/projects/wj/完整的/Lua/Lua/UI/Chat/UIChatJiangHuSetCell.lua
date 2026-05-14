local UIChatJiangHuSetCell = class("UIChatJiangHuSetCell")

function UIChatJiangHuSetCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatJiangHuSetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatJiangHuSetCell:BindUIEvent()
    
end

function UIChatJiangHuSetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatJiangHuSetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatJiangHuSetCell:UpdateInfo()
    
end


return UIChatJiangHuSetCell