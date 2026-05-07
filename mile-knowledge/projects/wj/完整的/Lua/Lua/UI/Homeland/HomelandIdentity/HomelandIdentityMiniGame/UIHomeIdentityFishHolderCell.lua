-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishHolderCell
-- Date: 2024-01-25 16:03:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishHolderCell = class("UIHomeIdentityFishHolderCell")

function UIHomeIdentityFishHolderCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomeIdentityFishHolderCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishHolderCell:BindUIEvent()
    
end

function UIHomeIdentityFishHolderCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityFishHolderCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishHolderCell:UpdateInfo()
    
end


return UIHomeIdentityFishHolderCell