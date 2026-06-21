-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSkinDetail
-- Date: 2024-04-02 17:09:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldSkinDetail = class("UITreasureBattleFieldSkinDetail")

function UITreasureBattleFieldSkinDetail:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureBattleFieldSkinDetail:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSkinDetail:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
        if self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UITreasureBattleFieldSkinDetail:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldSkinDetail:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSkinDetail:UpdateInfo()

end

function UITreasureBattleFieldSkinDetail:SetClickCallback(callback)
    self.fnClickCallback = callback
end


return UITreasureBattleFieldSkinDetail