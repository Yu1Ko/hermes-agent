-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSkinItem
-- Date: 2024-04-02 16:21:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldSkinItem = class("UITreasureBattleFieldSkinItem")

function UITreasureBattleFieldSkinItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureBattleFieldSkinItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSkinItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogImpasseSkillSkin, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and self.fnSelectedCallback then
            self.fnSelectedCallback()
        end
    end)
end

function UITreasureBattleFieldSkinItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldSkinItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSkinItem:UpdateInfo()

end

function UITreasureBattleFieldSkinItem:SetSelectedCallback(fn)
    self.fnSelectedCallback = fn
end


return UITreasureBattleFieldSkinItem