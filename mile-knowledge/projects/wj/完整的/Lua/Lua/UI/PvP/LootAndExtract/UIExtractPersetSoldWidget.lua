-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetSoldWidget
-- Date: 2025-06-12 15:28:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractPersetSoldWidget = class("UIExtractPersetSoldWidget")

function UIExtractPersetSoldWidget:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIExtractPersetSoldWidget:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetSoldWidget:BindUIEvent()
    
end

function UIExtractPersetSoldWidget:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractPersetSoldWidget:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractPersetSoldWidget:SetState(bShow)
    self.bState = bShow
    self.tbList = {}
    self:UpdateInfo()
end

function UIExtractPersetSoldWidget:UpdateInfo(tbSoldItem)
    local nSlot = tbSoldItem
end


return UIExtractPersetSoldWidget