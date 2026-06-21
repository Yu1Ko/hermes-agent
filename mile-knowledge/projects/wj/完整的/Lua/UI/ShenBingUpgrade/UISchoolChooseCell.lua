
local UISchoolChooseCell = class("UISchoolChooseCell")

function UISchoolChooseCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISchoolChooseCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISchoolChooseCell:BindUIEvent()
    
end

function UISchoolChooseCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISchoolChooseCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--TogType
--LabelTogName
--ImgType


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓�?
-- ----------------------------------------------------------

function UISchoolChooseCell:UpdateInfo()
    
end


return UISchoolChooseCell