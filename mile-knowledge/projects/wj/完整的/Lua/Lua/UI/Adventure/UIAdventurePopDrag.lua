-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventurePopDrag
-- Date: 2026-01-26 15:29:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdventurePopDrag = class("UIAdventurePopDrag")

function UIAdventurePopDrag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAdventurePopDrag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventurePopDrag:BindUIEvent()

end

function UIAdventurePopDrag:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdventurePopDrag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventurePopDrag:UpdateInfo()

end


return UIAdventurePopDrag