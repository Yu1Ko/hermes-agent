-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractTreasureItemRow
-- Date: 2025-03-25 16:40:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractTreasureItemRow = class("UIExtractTreasureItemRow")

function UIExtractTreasureItemRow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIExtractTreasureItemRow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractTreasureItemRow:BindUIEvent()
    
end

function UIExtractTreasureItemRow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractTreasureItemRow:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractTreasureItemRow:UpdateInfo()
    
end


return UIExtractTreasureItemRow