-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldEquipInfo
-- Date: 2023-05-30 14:40:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local _tEquipIndex2ImgIndex =
{
	[EQUIPMENT_INVENTORY.MELEE_WEAPON] = 1,
	[EQUIPMENT_INVENTORY.RANGE_WEAPON] = 10,
	[EQUIPMENT_INVENTORY.CHEST] = 2,
	[EQUIPMENT_INVENTORY.HELM] = 8,
	[EQUIPMENT_INVENTORY.AMULET] = 9,
	[EQUIPMENT_INVENTORY.LEFT_RING] = 11,
	[EQUIPMENT_INVENTORY.RIGHT_RING] = 12,
	[EQUIPMENT_INVENTORY.WAIST] = 5,
	[EQUIPMENT_INVENTORY.PENDANT] = 6,
	[EQUIPMENT_INVENTORY.PANTS] = 3,
	[EQUIPMENT_INVENTORY.BOOTS] = 4,
	[EQUIPMENT_INVENTORY.BANGLE] = 7,
}

local _tQualityColor = {
    [1] = cc.c3b(195, 195, 195),
    [2] = cc.c3b(138, 255, 164),
    [3] = cc.c3b(102, 213, 244),
    [4] = cc.c3b(190, 102, 244),
    [5] = cc.c3b(244, 150, 102),
}

local UITreasureBattleFieldEquipInfo = class("UITreasureBattleFieldEquipInfo")

function UITreasureBattleFieldEquipInfo:OnEnter(dwPlayerID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwPlayerID = dwPlayerID
    self:UpdateInfo()

    Timer.AddCycle(self, 2, function ()
        self:Tick()
    end)
end

function UITreasureBattleFieldEquipInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITreasureBattleFieldEquipInfo:BindUIEvent()

end

function UITreasureBattleFieldEquipInfo:RegEvent()
    Event.Reg(self, "ON_SYNC_OTHER_PLAYER_EQUIP_SIMPLE_INFO", function()
        if arg0 == self.dwPlayerID then
            self:UpdateEquipInfo(arg2, arg1)
        end
    end)
end

function UITreasureBattleFieldEquipInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldEquipInfo:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, false)
    PeekOtherPlayer(self.dwPlayerID)
    PeekOtherPlayerEquipSimpleInfo(self.dwPlayerID)
end

function UITreasureBattleFieldEquipInfo:UpdateEquipInfo(tEquipQualities, nTotalEquipScore)
    UIHelper.SetVisible(self._rootNode, true)
    for dwIndex, nImgName in pairs(_tEquipIndex2ImgIndex) do
        local nQuality = tEquipQualities[dwIndex]
        local img = self.tbEquipImg[nImgName]
        nQuality = math.max(nQuality, 1)
        local c3b = _tQualityColor[nQuality]
        UIHelper.SetColor(img, c3b)
	end

    if nTotalEquipScore >= 10000 then
        UIHelper.SetString(self.Label, string.format("%0.1f%s", nTotalEquipScore / 10000, "万"))
    else
        UIHelper.SetString(self.Label, nTotalEquipScore)
    end
end

function UITreasureBattleFieldEquipInfo:Tick()
    PeekOtherPlayerEquipSimpleInfo(self.dwPlayerID)
end

return UITreasureBattleFieldEquipInfo