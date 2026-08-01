-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventurePartType
-- Date: 2023-05-08 16:05:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdventurePartType = class("UIAdventurePartType")

function UIAdventurePartType:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAdventurePartType:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventurePartType:BindUIEvent()
    
end

function UIAdventurePartType:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdventurePartType:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventurePartType:UpdateInfo()
    
end


return UIAdventurePartType