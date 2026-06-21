-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldMapSFX
-- Date: 2023-06-06 15:02:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldMapSFX = class("UITreasureBattleFieldMapSFX")

function UITreasureBattleFieldMapSFX:OnEnter(szSFXPath)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szSFXPath = szSFXPath
    UIHelper.SetSFXPath(self.SFXMap, szSFXPath, true)
end

function UITreasureBattleFieldMapSFX:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldMapSFX:BindUIEvent()

end

function UITreasureBattleFieldMapSFX:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldMapSFX:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldMapSFX:UpdateInfo()

end


return UITreasureBattleFieldMapSFX