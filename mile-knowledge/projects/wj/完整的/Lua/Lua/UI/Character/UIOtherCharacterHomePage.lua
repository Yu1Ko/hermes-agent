-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCharacterHomePage
-- Date: 2024-03-26 15:35:58
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_NUM = 10000

local UIOtherCharacterHomePage = class("UIOtherCharacterHomePage")
local DataModel = {}
DataModel.Init = function (nPlayerID)
    DataModel.nPlayerID 	        = nPlayerID
    DataModel.nRecord 		        = 0
    DataModel.tCommHomeInfo 		= {}
    DataModel.tPrivHomeInfo         = {}
end

DataModel.UnInit = function ()
    DataModel.nPlayerID 	        = nil
    DataModel.nRecord 		        = nil
    DataModel.tCommHomeInfo 		= nil
    DataModel.tPrivHomeInfo         = nil
end

DataModel.GetHomelandRecordInfo = function ()
    local pPlayer = GetPlayer(DataModel.nPlayerID)
    DataModel.nRecord = pPlayer.GetHomelandRecord()
end

DataModel.GetHomelandBaseInfo = function ()
    local pPlayer = GetPlayer(DataModel.nPlayerID)
    if not pPlayer then
        return
    end
    DataModel.tHomeInfo = GetHomelandMgr().GetPeekInfo(DataModel.nPlayerID)
    local tHomeInfo = DataModel.tHomeInfo
    if tHomeInfo.szCommunityLandID ~= "0" then
        local nMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(tHomeInfo.szCommunityLandID)
        DataModel.tCommHomeInfo.nMapID = nMapID
        DataModel.tCommHomeInfo.nCopyIndex = nCopyIndex
        DataModel.tCommHomeInfo.nLandIndex = nLandIndex
        local bIsSelling, bPrepareToSale, bIsOpen, nLevel, nAllyCount, eMarketType = GetHomelandMgr().GetLandState(nMapID, nCopyIndex, nLandIndex)
        DataModel.tCommHomeInfo.eMarketType = eMarketType
    end
    if tHomeInfo.szPrivateHomeID ~= "0" then
        local dwSkinID, nCopyIndex, nMapID = GetHomelandMgr().ConvertLandID(tHomeInfo.szPrivateHomeID)
        GetHomelandMgr().ApplyPrivateHomeInfo(nMapID, nCopyIndex)
        DataModel.tPrivHomeInfo.nMapID = nMapID
        DataModel.tPrivHomeInfo.nCopyIndex = nCopyIndex
        DataModel.tPrivHomeInfo.dwSkinID = dwSkinID
        GetHomelandMgr().ApplyLandInfo(nMapID, nCopyIndex, 1)
    end
end

function UIOtherCharacterHomePage:OnEnter(nPlayerID, nCenterID, szGlobalRoleID)
    if not self.bInit then
        DataModel.Init(nPlayerID)
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nPlayerID = nPlayerID
    self.nCenterID = nCenterID
    self.szGlobalRoleID = szGlobalRoleID

    self:Init()
end

function UIOtherCharacterHomePage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOtherCharacterHomePage:BindUIEvent()
    
end

function UIOtherCharacterHomePage:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.PLAYER_HOMELAND_INFO_SYNC_OVER then
            if arg1 == self.nPlayerID then
                DataModel.GetHomelandBaseInfo()
                self:UpdateInfo()
            end
        elseif nResultType == HOMELAND_RESULT_CODE.PLAYER_HOMELAND_RECORD_SYNC_OVER then
            if arg1 == self.nPlayerID then
                DataModel.GetHomelandRecordInfo()
                self:UpdateHomelandRecordInfo()
            end
        elseif nResultType == HOMELAND_RESULT_CODE.APPLY_PRIVATE_HOME_INFO_RESPOND then
            local nMapID, nCopyIndex = arg1, arg2
			if nMapID == DataModel.tPrivHomeInfo.nMapID and nCopyIndex == DataModel.tPrivHomeInfo.nCopyIndex then
				local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(nMapID, nCopyIndex)
                DataModel.tPrivHomeInfo.dwSkinID = tPrivateInfo.dwSkinID
                self:UpdateInfo()
            end
        elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then
            local nMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
            if nMapID == DataModel.tPrivHomeInfo.nMapID and nCopyIndex == DataModel.tPrivHomeInfo.nCopyIndex then
				local tInfo = GetHomelandMgr().GetLandInfo(nMapID, nCopyIndex, nLandIndex)
                if not tInfo then
                    return
                end
                DataModel.tPrivHomeInfo.eMarketType = tInfo.uMarketType
                self:UpdateInfo()
            end
        end
    end)
end

function UIOtherCharacterHomePage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOtherCharacterHomePage:Init()
    local nPlayerID = self.nPlayerID
    if not CheckPlayerIsRemote(nPlayerID) then
        PeekOtherPlayerHomelandRecord(nPlayerID)
        PeekOtherPlayerHomelandInfo(nPlayerID)
	end

    self:UpdatePlayerInfo()
    self:UpdateHomelandRecordInfo()
    self:UpdateInfo()
end

function UIOtherCharacterHomePage:UpdatePlayerInfo()
    local targetPlayer = self:GetPlayer()
    if not targetPlayer or targetPlayer.IsInMorph() then
        return
    end

    UIHelper.SetString(self.LabelName, GBKToUTF8(targetPlayer.szName))
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg[targetPlayer.dwForceID])
    UIHelper.SetString(self.LabelLevel, targetPlayer.nLevel .. "级")
    UIHelper.SetString(self.LabelCamp, g_tStrings.STR_GUILD_CAMP_NAME[targetPlayer.nCamp])
end

function UIOtherCharacterHomePage:UpdateHomelandRecordInfo()
    local nRecord = DataModel.nRecord or 0
    local szText = nRecord
    local fData = nRecord
    if fData > MAX_SHOW_NUM then
        fData = math.floor(fData / MAX_SHOW_NUM * 100) / 100
        szText = FormatString(g_tStrings.MPNEY_TENTHOUSAND, fData)
    end
    UIHelper.SetString(self.LabelScoreNum, szText)
end

function UIOtherCharacterHomePage:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutHomeInfoShell)
    self:UpdatePrivateHomelandInfo()
    self:UpdateCommunutyHomelandInfo()
end

function UIOtherCharacterHomePage:UpdateCommunutyHomelandInfo()
    local tCommHomeInfo = DataModel.tCommHomeInfo
    tCommHomeInfo.dwPlayerID = self.nPlayerID

    self.scriptCommunutyHome = UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterHomeCell, self.LayoutHomeInfoShell)
    self.scriptCommunutyHome:OnEnter(tCommHomeInfo, true, true)
end

function UIOtherCharacterHomePage:UpdatePrivateHomelandInfo()
    local tPrivHomeInfo = DataModel.tPrivHomeInfo
    tPrivHomeInfo.dwPlayerID = self.nPlayerID

    self.scriptPrivateHome = UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterHomeCell, self.LayoutHomeInfoShell)
    self.scriptPrivateHome:OnEnter(tPrivHomeInfo, false, true)
end

function UIOtherCharacterHomePage:GetPlayer()
    if self.nPlayerID then
        local player = GetPlayer(self.nPlayerID)
        return player
    end

    if self.szGlobalRoleID then
        local player = GetPlayerByGlobalID(self.szGlobalRoleID)
        return player
    end
end

return UIOtherCharacterHomePage