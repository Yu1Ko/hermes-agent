CommonPVPData = CommonPVPData or {className = "ArenaData"}
local self = CommonPVPData

function CommonPVPData.Init()
    self.bAutoShowModelArena = false
    self.bAutoShowModelBattlefield = false
    self.bAutoShowModelTreasureBattleField = false

    self.bLock = false
    self.bHideNpc = nil
    self.bHidePlayer = nil
    self.bShowParty = nil

    Event.Reg(CommonPVPData, "ON_REPRESENT_CMD", function(szCmd)
        if self.bLock then
            return
        end

        if szCmd == 'show npc' or szCmd == 'hide npc' then
            self.bHideNpc = szCmd == 'hide npc'
        elseif szCmd == 'show player' or szCmd == 'hide player' then
            self.bHidePlayer = szCmd == 'hide player'
        elseif szCmd == 'show or hide party player 0' or szCmd == 'show or hide party player 1' then
            self.bShowParty = szCmd == 'show or hide party player 1'
        end
    end)

    Event.Reg(CommonPVPData, "LOADING_END", function()
		if not self.bAutoShowModelArena and not self.bAutoShowModelBattlefield and not self.bAutoShowModelTreasureBattleField then
            return
        end

        if (ArenaData.IsInArena() and self.bAutoShowModelArena) or
            (BattleFieldData.IsInBattleField() and self.bAutoShowModelBattlefield) or
            (BattleFieldData.IsInTreasureBattleFieldMap() and self.bAutoShowModelTreasureBattleField) then
            self.bLock = true
            rlcmd('show npc')
            rlcmd('show player')
            rlcmd('show or hide party player 0')
        else
            self.bLock = true

            if self.bHideNpc then
                rlcmd('hide npc')
            else
                rlcmd('show npc')
            end

            if self.bHidePlayer then
                rlcmd('hide player')
            else
                rlcmd('show player')
            end

            if self.bShowParty then
                rlcmd('show or hide party player 1')
            else
                rlcmd('show or hide party player 0')
            end

            self.bLock = false
        end
    end)
end

function CommonPVPData.UnInit()
    self.bAutoShowModelArena = false
    self.bAutoShowModelBattlefield = false
    self.bAutoShowModelTreasureBattleField = false

    self.bLock = false
    self.bHideNpc = nil
    self.bHidePlayer = nil
    self.bShowParty = nil

    Event.UnReg(self)
end

function CommonPVPData.SetAutoShowModelArena(bOpen)
    self.bAutoShowModelArena = bOpen
end

function CommonPVPData.SetAutoShowModelBattlefield(bOpen)
    self.bAutoShowModelBattlefield = bOpen
end

function CommonPVPData.SetAutoShowModelTreasureBattleField(bOpen)
    self.bAutoShowModelTreasureBattleField = bOpen
end