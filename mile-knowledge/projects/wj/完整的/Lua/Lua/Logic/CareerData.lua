-------------------------------------------------------------------------
-- 个人生涯数据
-------------------------------------------------------------------------
CareerData = CareerData or {className = "CareerData"}
local self = CareerData

local REMOTE_TRIAL_MAXLEVEL = 1035
local REMOTE_NEWTRIAL_CUSTOM = 1036
local AchievementListOfLangKe = {7146, 7147, 7148, 7149, 7150, 7151, 7152, 7153}
local AchievementListOfBaiZhan = {[1] = 10730, [2] = 10731, [3] = 10732, [4] = 10733, [5] = 10734, [6] = 10735, [7] = 10854}
local szBaiZhan = {
    [1] = "六十层",
    [2] = "五十层",
    [3] = "四十层",
    [4] = "三十层",
    [5] = "二十层",
    [6] = "十层",
    [7] = "一层",
}
local nKillBosskey = 10

local dwBattleMapID = 296
local dwBattleCurMapID = 52
local COMPETE_TYPE = {
    ARENA_2V2           = 1,
    ARENA_3V3           = 2,
    ARENA_5V5           = 3,
    BATTLE_CUR          = 4,
    CAMP                = 5,
    BATTLE              = 6,
}

function CareerData.Init()
	if not self.bInit then
		--[[ self:RegEvent()
        self:ApplyData() ]]
		self.bInit = true
	end
end

function CareerData.UnInit()
    self.bInit = false
end

function CareerData.ClearData()
    self.sGlobalID = nil
    self.tMainInfo = nil
    self.tReportInfo = nil
    self.tAllCompete = nil
    self.tDungeonsInfo = nil
end

function CareerData.RegEvent()
    --[[ --密档
    Event.Reg(self, "ON_GET_DOCUMENT", function(dwPlayerID, tInfo)
        self:UpdateReportData(tInfo)
        self:UpdateMainData()
    end)

    --战场
    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        self:UpdateBattleData(dwPlayerID, dwMapID, bUpdate, eType)
    end)

    --秘境
    Event.Reg(self, "CAREER_TRAIN_GYM_CUSTOM_DATA", function(dwPlayerID, nEventID)
        if not g_pClientPlayer or dwPlayerID ~= g_pClientPlayer.dwID or nEventID ~= REMOTE_NEWTRIAL_CUSTOM then
			return
        end
        self:UpdateDungeonsDataOfNewTrials()
    end)

    Event.Reg(self, "Get_Career_Trial_Maxlevel", function(nlevel)
        self:UpdateDungeonsDataOfTrials(nlevel)
    end) ]]
end

function CareerData.ApplyData()
    --[[ self:ApplyReportData()
    self:ApplyDungeonsDataOfNewTrials()
    self:ApplyBattleDataOfBattle()
    self:ApplyBattleDataOfBattleCur() ]]
end

function CareerData.UpdateGlobalID()
    if g_pClientPlayer then
        self.sGlobalID = g_pClientPlayer.GetGlobalID()
    end
end

-- 密档
function CareerData.ApplyReportData()
    if not g_pClientPlayer then
        return
    end
    if not self.tReportInfo then
        RemoteCallToServer("On_Achievement_GetDocumentInfo", g_pClientPlayer.dwID)
    end
end

function CareerData.UpdateReportData(tInfo)
    self.tReportInfo = tInfo
    self.tReportInfoTime = GetCurrentTime()
end

-- 主页
function CareerData.UpdateServerName(szName)
    self.szServerName = szName
end

function CareerData.UpdateMainData()
    if not g_pClientPlayer then
        return
    end
    local tPlayerPlayTime = {}
    local bHaveTime = false
    if self.tMainInfo and self.tMainInfo.tPlayerPlayTime then
        tPlayerPlayTime = self.tMainInfo.tPlayerPlayTime
        bHaveTime = true
    end

    self.tMainInfo  = g_pClientPlayer.GetCareerMainInfo()
    if bHaveTime then
        self.tMainInfo.tPlayerPlayTime = tPlayerPlayTime
    end

    local tGen = g_tTable.Designation_Generation:Search(g_pClientPlayer.dwForceID, g_pClientPlayer.GetDesignationGeneration())
    if tGen then
        self.tMainInfo.nDesignationNum = self.tMainInfo.nDesignationNum + 1
    end

    self.hFellow = GetSocialManagerClient()
    -- local aRoleEntry = self.hFellow.GetRoleEntryInfo(self.sGlobalID)
    -- self.tMainInfo.szSignature = ""
    -- if aRoleEntry then
    --     self.tMainInfo.szSignature = aRoleEntry.szSignature
    -- end

    self.tMainInfo.nPraiseCount = 0
    local aCard = self.hFellow.GetFellowshipCardInfo(self.sGlobalID)
    local tPraiseinfo = aCard and aCard.Praiseinfo
    for _, nNum in pairs(tPraiseinfo) do
        self.tMainInfo.nPraiseCount = self.tMainInfo.nPraiseCount + nNum
    end

    self.tMainInfo.nReputation = g_pClientPlayer.GetTotalReputation()
    --[[ local tTab = g_tTable.ReputationForceGroup
    local nTab = tTab:GetRowCount()
    for i = 1, nTab do
        local tRow = tTab:GetRow(i)
        local nNum = g_pClientPlayer.GetReputation(tRow.dwForceID)
        self.tMainInfo.nReputation = self.tMainInfo.nReputation + nNum
    end ]]

    self.tMainInfo.nFame = 0
    if g_pClientPlayer.IsAchievementAcquired(10443) then
        local nNowLevel, nMaxLevel, nProgressUp, nProgressDown = GDAPI_GetFameLevelInfo(g_pClientPlayer, 1)
        self.tMainInfo.nFame = nNowLevel
    end

    self.tMainInfo.szServerName = self.szServerName
end

function CareerData.UpdateMainDataOfAdventureNum()
    if self.tMainInfo then
        self.tMainInfo.nAdventureNum = self.tReportInfo.nAdventureCount
        self.tMainInfo.nCreateTime = self.tReportInfo.nCreateTime
    end
end

function CareerData.UpdateMainDataOfPlayTime(nDay, nHour, nMinute, nSecond)
    if self.tMainInfo then
        self.tMainInfo.tPlayerPlayTime = {}
        self.tMainInfo.tPlayerPlayTime.nDay     = nDay
        self.tMainInfo.tPlayerPlayTime.nHour    = nHour
        self.tMainInfo.tPlayerPlayTime.nMinute  = nMinute
        self.tMainInfo.tPlayerPlayTime.nSecond  = nSecond
        self.nMainInfoTime = GetCurrentTime()
    end
end

function CareerData.UpdateMainDataOfnPraiseCount()
    if self.tMainInfo then
        self.hFellow = GetSocialManagerClient()
        local aCard = self.hFellow.GetFellowshipCardInfo(self.sGlobalID)
        local tPraiseinfo = aCard and aCard.Praiseinfo
        self.tMainInfo.nPraiseCount = 0
        for _, nNum in pairs(tPraiseinfo) do
            self.tMainInfo.nPraiseCount = self.tMainInfo.nPraiseCount + nNum
        end
    end
end

-- 秘境
local tType2Index = {
    [1] = 12,
    [2] = 13,
    [3] = 14,
}
function CareerData.ApplyDungeonsDataOfNewTrials()
    if g_pClientPlayer then
        RemoteCallToServer("On_Career_Trial_Maxlevel")
        GetClientPlayer().ApplyRemoteData(REMOTE_NEWTRIAL_CUSTOM)
        GetFellowshipRankClient().RequestFellowshipRankData(nKillBosskey, {self.sGlobalID})
    end
end

function CareerData.UpdateDungeonsDataOfTrials(nlevel)
    if not self.tDungeonsInfo then
        self.tDungeonsInfo = {}
    end

    self.tDungeonsInfo.Trials = nlevel
    self.nDungeonsTime = GetCurrentTime()
end

function CareerData.UpdateDungeonsDataOfNewTrials()
    if not g_pClientPlayer then
        return
    end

    if not self.tDungeonsInfo then
        self.tDungeonsInfo = {}
    end
    local nType = g_pClientPlayer.GetRemoteDWordArray(REMOTE_NEWTRIAL_CUSTOM, 2)
    if nType >= 1 and nType <= 3 then
		self.tDungeonsInfo.NewTrials = g_pClientPlayer.GetRemoteDWordArray(REMOTE_NEWTRIAL_CUSTOM, tType2Index[nType])
	end
    RemoteCallToServer("On_Get_Career_Trial_Maxlevel")
    --self.tDungeonsInfo.Trials = g_pClientPlayer.GetRemoteDataByte(REMOTE_TRIAL_MAXLEVEL)
end

function CareerData.UpdateDungeonsDataOfKillBoss()
    if not g_pClientPlayer then
        return
    end

    if not self.tDungeonsInfo then
        self.tDungeonsInfo = {}
    end
    local nTmpIndex = 0
    nTmpIndex, self.tDungeonsInfo.nKillBossNum = GetFellowshipRankClient().GetFellowshipRankDataValue(self.sGlobalID, nKillBosskey)
    if not self.tDungeonsInfo.nKillBossNum then
        self.tDungeonsInfo.nKillBossNum = 0
    end
end

function CareerData.UpdateDungeonsData()
    if not g_pClientPlayer then
        return
    end

    if not self.tDungeonsInfo then
        self.tDungeonsInfo = {}
    end

    --self.tDungeonsInfo.Trials = g_pClientPlayer.GetRemoteDataByte(REMOTE_TRIAL_MAXLEVEL)
    --self.tDungeonsInfo.NewTrials = g_pClientPlayer.GetRemoteDWordArray(REMOTE_NEWTRIAL_CUSTOM, 12)

    self.tDungeonsInfo.LangKe = 0
    for _, dwID in ipairs(AchievementListOfLangKe) do
        local bGet = g_pClientPlayer.IsAchievementAcquired(dwID)
        if bGet then
            self.tDungeonsInfo.LangKe = self.tDungeonsInfo.LangKe + 1
        end
    end

    local bBaizhan = false
    for i = 0, 6 do
        local bGet = g_pClientPlayer.IsAchievementAcquired(AchievementListOfBaiZhan[7 - i])
        if bGet then
            self.tDungeonsInfo.szBaizhan = szBaiZhan[i + 1]
            bBaizhan = true
            break
        end
    end
    if bBaizhan == false then
        self.tDungeonsInfo.szBaizhan = "0层"
    end
end

-- 收集

-- 战场
function CareerData.ApplyBattleDataOfBattle()
    if not g_pClientPlayer then
        return
    end

    if CanApplyBFRoleData(BF_ROLE_DATA_TYPE.THIS_WEEK, dwBattleMapID) then
        ApplyBFRoleData(g_pClientPlayer.dwID, dwBattleMapID, false, BF_ROLE_DATA_TYPE.THIS_WEEK)
    end
end

function CareerData.ApplyBattleDataOfBattleCur()
    if not g_pClientPlayer then
        return
    end

    if CanApplyBFRoleData(BF_ROLE_DATA_TYPE.HISTORY, dwBattleCurMapID) then
		ApplyBFRoleData(g_pClientPlayer.dwID, dwBattleCurMapID, false, BF_ROLE_DATA_TYPE.HISTORY)
	end
end

function CareerData.UpdateBattleData(dwPlayerID, dwMapID, bUpdate, eType)
    if not self.tAllCompete then
        self.tAllCompete = {}
    end

    if dwMapID == dwBattleMapID then
        local tInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
        self.tAllCompete[COMPETE_TYPE.BATTLE] = {}
        self.tAllCompete[COMPETE_TYPE.BATTLE].nScore = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
        self.tAllCompete[COMPETE_TYPE.BATTLE].nTotal = tInfo[BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS]
        self.tAllCompete[COMPETE_TYPE.BATTLE].nPerson = tInfo[BF_MAP_ROLE_INFO_TYPE.TOP_COUNT]
    elseif dwMapID == dwBattleCurMapID then
        local tInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
        self.tAllCompete[COMPETE_TYPE.BATTLE_CUR] = {}
        self.tAllCompete[COMPETE_TYPE.BATTLE_CUR].nScore = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
    end
end

-- 江湖无限

function CareerData.UpdateOverViewData()
    self.tOverViewInfo = GDAPI_GetSeasonSummaryInfo()
end

function CareerData.UpdateSeasunTagInfo()
    self.tSeasonTagInfo = Table_GetAllSeasonTagInfo()
end

function CareerData.GetOverViewInfo(dwID)
    if not self.tSeasonTagInfo then
        self:UpdateSeasunTagInfo()
    end
    return self.tSeasonTagInfo[dwID]
end








