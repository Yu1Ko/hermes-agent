-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeGetNewHouseView
-- Date: 2023-04-14 10:18:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeGetNewHouseView = class("UIHomelandMyHomeGetNewHouseView")

function UIHomelandMyHomeGetNewHouseView:OnEnter(nMapID, nCopyIndex, nLandIndex)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeGetNewHouseView:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeGetNewHouseView:BindUIEvent()

end

function UIHomelandMyHomeGetNewHouseView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomeGetNewHouseView:UpdateInfo()
    local tInfo = Table_GetMapLandInfo(self.nMapID, self.nLandIndex)
    if not tInfo then
        LOG.ERROR("UIHomelandMyHomeGetNewHouseView:UpdateInfo not config! nMapID : %d, nLandIndex :%d", self.nMapID, self.nLandIndex)
        return
    end

    local szMapName = Table_GetMapName(self.nMapID)

    UIHelper.SetString(self.LabelHouseholder, UIHelper.GBKToUTF8(PlayerData.GetPlayerName(player)))
    UIHelper.SetString(self.LabelRepose, UIHelper.GBKToUTF8(tInfo.szState .. "  " .. szMapName))
    UIHelper.SetString(self.LabelSite, UIHelper.GBKToUTF8(tInfo.szLandIndex))
    UIHelper.SetString(self.LabelArea, UIHelper.GBKToUTF8(tInfo.szArea))
end


return UIHomelandMyHomeGetNewHouseView