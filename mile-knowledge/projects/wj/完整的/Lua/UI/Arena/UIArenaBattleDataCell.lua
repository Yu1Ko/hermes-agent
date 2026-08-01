-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaBattleDataCell
-- Date: 2022-12-14 21:18:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaBattleDataCell = class("UIArenaBattleDataCell")

function UIArenaBattleDataCell:OnEnter(tbInfo, bEnemy)
    self.tbInfo = tbInfo
    self.bEnemy = bEnemy

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaBattleDataCell:OnExit()
    self.bInit = false
end

function UIArenaBattleDataCell:BindUIEvent()

end

function UIArenaBattleDataCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaBattleDataCell:UpdateInfo()
    local player = PlayerData.GetPlayer(self.tbInfo.dwID)
    -- local item = player.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    -- LOG.ERROR("----------------item:%s", tostring(item))

    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(player.szName))
    UIHelper.SetSpriteFrame(self.ImgxinfaIcon, PlayerKungfuImg[self.tbInfo.dwMountKungfuID])

    UIHelper.SetVisible(self.ImgPlayerBg, self.tbInfo.dwID == PlayerData.GetPlayerID())
    UIHelper.SetVisible(self.ImgTeammate, not self.bEnemy and self.tbInfo.dwID ~= PlayerData.GetPlayerID())
    UIHelper.SetVisible(self.ImgEnemy, self.bEnemy and self.tbInfo.dwID ~= PlayerData.GetPlayerID())

    UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, self.tbInfo.dwID)
end


return UIArenaBattleDataCell