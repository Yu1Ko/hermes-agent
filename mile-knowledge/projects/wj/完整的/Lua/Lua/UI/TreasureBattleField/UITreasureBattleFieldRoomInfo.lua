-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldRoomInfo
-- Date: 2025-01-07 14:36:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldRoomInfo = class("UITreasureBattleFieldRoomInfo")

function UITreasureBattleFieldRoomInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UITreasureBattleFieldRoomInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldRoomInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMatchingOut, EventType.OnClick, function()
        BattleFieldQueueData.DoLeaveBattleFieldQueue(TreasureBattleFieldData.tCurRoomInfo.dwFatherMapID)
    end)
end

function UITreasureBattleFieldRoomInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldRoomInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldRoomInfo:UpdateInfo()
    local tRoomInfo = TreasureBattleFieldData.tCurRoomInfo
    if not tRoomInfo then
        return
    end
    local dwRoomMapID = tRoomInfo.dwMapID
    local tMapInfo = Table_GetBFCustomRoomMapInfo(dwRoomMapID)
    if not tMapInfo then
        return
    end
    local nRoomType = tMapInfo.nRoomType
    UIHelper.SetSelected(self.tTogMode[1], nRoomType == TreasureBattleFieldData.ROOM_TYPE.NORMAL, false)
    UIHelper.SetSelected(self.tTogMode[2], nRoomType == TreasureBattleFieldData.ROOM_TYPE.SINGLE, false)
    UIHelper.SetSelected(self.tTogMode[3], nRoomType == TreasureBattleFieldData.ROOM_TYPE.SKILL, false)
    UIHelper.SetString(self.LabelMapName, UIHelper.GBKToUTF8(tMapInfo.szName))
    UIHelper.SetTexture(self.ImgMap, tMapInfo.szMobileMapPath)

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(dwRoomMapID)
    scriptDownload:OnInitWithPackID(nPackID)
end


return UITreasureBattleFieldRoomInfo