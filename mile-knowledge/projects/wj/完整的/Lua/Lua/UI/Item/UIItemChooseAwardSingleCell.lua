-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: UIItemChoosAwardSingleCell
-- Date: 2023-10-31 10:36:18
-- Desc: 不做逻辑处理，只做挂靠预制提取
-- ---------------------------------------------------------------------------------

local UIItemChoosAwardSingleCell = class("UIItemChoosAwardSingleCell")

function UIItemChoosAwardSingleCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIItemChoosAwardSingleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemChoosAwardSingleCell:BindUIEvent()
    
end

function UIItemChoosAwardSingleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemChoosAwardSingleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--TogType
--LabelTogName
--ImgType


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemChoosAwardSingleCell:UpdateInfo()
    
end


return UIItemChoosAwardSingleCell