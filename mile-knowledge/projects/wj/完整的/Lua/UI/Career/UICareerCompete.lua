-- WidgetCareerCompete

local UICareerCompete = class("UICareerCompete")

local COMPETE_TYPE = {
    ARENA_2V2           = 1,
    ARENA_3V3           = 2,
    ARENA_5V5           = 3,
    BATTLE_CUR          = 4,
    CAMP                = 5,
    BATTLE              = 6,
}

local COMPETE_TYPE_TO_TITLE = {
    [COMPETE_TYPE.ARENA_2V2]     = "名剑大会-2对2",
    [COMPETE_TYPE.ARENA_3V3]     = "名剑大会-3对3",
    [COMPETE_TYPE.ARENA_5V5]     = "名剑大会-5对5",
    [COMPETE_TYPE.BATTLE_CUR]    = "战场",
    [COMPETE_TYPE.CAMP]          = "阵营",
    [COMPETE_TYPE.BATTLE]        = "绝境战场",
}

local COMPETE_TYPE_TO_SCORE = {
    [COMPETE_TYPE.ARENA_2V2]     = "个人竞技分",
    [COMPETE_TYPE.ARENA_3V3]     = "个人竞技分",
    [COMPETE_TYPE.ARENA_5V5]     = "个人竞技分",
    [COMPETE_TYPE.BATTLE_CUR]    = "个人评分",
    [COMPETE_TYPE.CAMP]          = "当前战阶等级",
    [COMPETE_TYPE.BATTLE]        = "个人评分",
}

local COMPETE_TYPE_TO_TOTAL = {
    [COMPETE_TYPE.ARENA_2V2]     = "当前赛季场次",
    [COMPETE_TYPE.ARENA_3V3]     = "当前赛季场次",
    [COMPETE_TYPE.ARENA_5V5]     = "当前赛季场次",
    [COMPETE_TYPE.BATTLE_CUR]    = "总场次",
    [COMPETE_TYPE.CAMP]          = "伤敌人数",
    [COMPETE_TYPE.BATTLE]        = "历史总场次",
}

local COMPETE_TYPE_TO_PERSON = {
    [COMPETE_TYPE.ARENA_2V2]     = "胜场次数",
    [COMPETE_TYPE.ARENA_3V3]     = "胜场次数",
    [COMPETE_TYPE.ARENA_5V5]     = "胜场次数",
    [COMPETE_TYPE.BATTLE_CUR]    = "胜场次数",
    [COMPETE_TYPE.CAMP]          = "最佳助攻",
    [COMPETE_TYPE.BATTLE]        = "历史夺冠次数",
}

local tCampTitleImgPath =
{
    [1] = {
        [0] = "UIAtlas2_Pvp_HaoQi_icon_Badge_00.png",
        [1] = "UIAtlas2_Pvp_HaoQi_icon_Badge_01.png",
        [2] = "UIAtlas2_Pvp_HaoQi_icon_Badge_02.png",
        [3] = "UIAtlas2_Pvp_HaoQi_icon_Badge_03.png",
        [4] = "UIAtlas2_Pvp_HaoQi_icon_Badge_04.png",
        [5] = "UIAtlas2_Pvp_HaoQi_icon_Badge_05.png",
        [6] = "UIAtlas2_Pvp_HaoQi_icon_Badge_06.png",
        [7] = "UIAtlas2_Pvp_HaoQi_icon_Badge_07.png",
        [8] = "UIAtlas2_Pvp_HaoQi_icon_Badge_08.png",
        [9] = "UIAtlas2_Pvp_HaoQi_icon_Badge_09.png",
        [10] = "UIAtlas2_Pvp_HaoQi_icon_Badge_10.png",
        [11] = "UIAtlas2_Pvp_HaoQi_icon_Badge_11.png",
        [12] = "UIAtlas2_Pvp_HaoQi_icon_Badge_12.png",
        [13] = "UIAtlas2_Pvp_HaoQi_icon_Badge_13.png",
        [14] = "UIAtlas2_Pvp_HaoQi_icon_Badge_14.png",
    },
    [2] = {
        [0] = "UIAtlas2_Pvp_ERen_icon_Badge_00.png",
        [1] = "UIAtlas2_Pvp_ERen_icon_Badge_01.png",
        [2] = "UIAtlas2_Pvp_ERen_icon_Badge_02.png",
        [3] = "UIAtlas2_Pvp_ERen_icon_Badge_03.png",
        [4] = "UIAtlas2_Pvp_ERen_icon_Badge_04.png",
        [5] = "UIAtlas2_Pvp_ERen_icon_Badge_05.png",
        [6] = "UIAtlas2_Pvp_ERen_icon_Badge_06.png",
        [7] = "UIAtlas2_Pvp_ERen_icon_Badge_07.png",
        [8] = "UIAtlas2_Pvp_ERen_icon_Badge_08.png",
        [9] = "UIAtlas2_Pvp_ERen_icon_Badge_09.png",
        [10] = "UIAtlas2_Pvp_ERen_icon_Badge_10.png",
        [11] = "UIAtlas2_Pvp_ERen_icon_Badge_11.png",
        [12] = "UIAtlas2_Pvp_ERen_icon_Badge_12.png",
        [13] = "UIAtlas2_Pvp_ERen_icon_Badge_13.png",
        [14] = "UIAtlas2_Pvp_ERen_icon_Badge_14.png",
    },
}

local dwBattleMapID = 296
local dwBattleCurMapID = 52

function UICareerCompete:OnEnter()
    self.player = GetClientPlayer()
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tSelected = {[1] = false, [2] = false, [3] = false, [4] = false, [5] = false, [6] = false}
    end
    self:UpdateData()
    self:SelectData(self.tSelected)
    self:UpdateInfo()
end

function UICareerCompete:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCompete:Init()
    --
end

function UICareerCompete:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetUp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelShowSetUpPop, self.tSelected)
    end)
end

function UICareerCompete:RegEvent()
    Event.Reg(self, "CareerCompeteFliter", function(tSelected)
        self:SelectData(tSelected)
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        self:UpdateBattleData(dwPlayerID, dwMapID, bUpdate, eType)
        self:SelectData(self.tSelected)
        self:UpdateInfo()
    end)
end

function UICareerCompete:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCompete:UpdateData()
    self.tAllCompete = {}

    for i = 1, 6, 1 do
        self.tAllCompete[i] = {}
        self.tAllCompete[i].szTitle     = COMPETE_TYPE_TO_TITLE[i]
        self.tAllCompete[i].szScore     = COMPETE_TYPE_TO_SCORE[i]
        self.tAllCompete[i].szTotal     = COMPETE_TYPE_TO_TOTAL[i]
        self.tAllCompete[i].szPerson    = COMPETE_TYPE_TO_PERSON[i]
    end

    self:ApplyBattleData()

    if self.player then
        for i = 1, 3, 1 do
            local nArenaLevel = ArenaData.GetArenaLevel(self.player.dwID, ArenaData.tbCorpsList[i])
            local tbUIConfig  = TabHelper.GetUIArenaRankLevelTab(nArenaLevel) assert(tbUIConfig)
            self.tAllCompete[i].imgPath = tbUIConfig.szBigIcon
    
            local szLevel = Conversion2ChineseNumber(nArenaLevel)
            local tbArenaLevelConfig = ArenaData.GetLevelInfo(nArenaLevel) assert(tbArenaLevelConfig)
            self.tAllCompete[i].szGrade = string.format("%s%s%s%s", szLevel, g_tStrings.STR_DUAN, g_tStrings.STR_CONNECT, UIHelper.GBKToUTF8(tbArenaLevelConfig.title))
    
            local tbArenaInfo = ArenaData.GetCorpsRoleInfo(self.player.dwID, ArenaData.tbCorpsList[i])
            self.tAllCompete[i].nScore      = tbArenaInfo.nMatchLevel or 1000
            self.tAllCompete[i].nTotal      = tbArenaInfo.dwSeasonTotalCount or 0
            self.tAllCompete[i].nPerson     = tbArenaInfo.dwSeasonWinCount or 0
        end

        if self.player.nCamp and self.player.nCamp ~= 0 and self.player.nTitle then
            self.tAllCompete[COMPETE_TYPE.CAMP].imgPath = tCampTitleImgPath[self.player.nCamp][self.player.nTitle]
        end
        local szTitleLevel, szTitle, szTitleBuff = CampData.GetPlayerTitleDesc(self.player.nTitle)
        if self.player.nTitle > 0 then
            self.tAllCompete[COMPETE_TYPE.CAMP].szGrade = szTitleLevel .. "·" .. szTitle
        end
        --self.tAllCompete[COMPETE_TYPE.CAMP].nScore = self.player.nTitlePoint
        self.tAllCompete[COMPETE_TYPE.CAMP].nScore = szTitleLevel
        self.tAllCompete[COMPETE_TYPE.CAMP].nTotal = self.player.dwKillCount
        self.tAllCompete[COMPETE_TYPE.CAMP].nPerson = self.player.dwBestAssistKilledCount
    end

end

function UICareerCompete:ApplyBattleData()
    if not CareerData.tAllCompete then
        CareerData.ApplyBattleDataOfBattle()
        CareerData.ApplyBattleDataOfBattleCur()
    elseif not CareerData.tAllCompete[COMPETE_TYPE.BATTLE] then
        CareerData.ApplyBattleDataOfBattle()
    elseif not CareerData.tAllCompete[COMPETE_TYPE.BATTLE_CUR] then
        CareerData.ApplyBattleDataOfBattleCur()
    else
        self.tAllCompete[COMPETE_TYPE.BATTLE].nScore  = CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nScore
        self.tAllCompete[COMPETE_TYPE.BATTLE].nTotal  = CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nTotal
        self.tAllCompete[COMPETE_TYPE.BATTLE].nPerson = CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nPerson

        self.tAllCompete[COMPETE_TYPE.BATTLE_CUR].nScore = CareerData.tAllCompete[COMPETE_TYPE.BATTLE_CUR].nScore
    end
end

function UICareerCompete:UpdateBattleData(dwPlayerID, dwMapID, bUpdate, eType)
    if not CareerData.tAllCompete then
        CareerData.tAllCompete = {}
    end

    if dwMapID == dwBattleMapID then
        local tInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
        self.tAllCompete[COMPETE_TYPE.BATTLE].nScore = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
        self.tAllCompete[COMPETE_TYPE.BATTLE].nTotal = tInfo[BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS]
        self.tAllCompete[COMPETE_TYPE.BATTLE].nPerson = tInfo[BF_MAP_ROLE_INFO_TYPE.TOP_COUNT]

        CareerData.tAllCompete[COMPETE_TYPE.BATTLE] = {}
        CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nScore = self.tAllCompete[COMPETE_TYPE.BATTLE].nScore
        CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nTotal = self.tAllCompete[COMPETE_TYPE.BATTLE].nTotal
        CareerData.tAllCompete[COMPETE_TYPE.BATTLE].nPerson = self.tAllCompete[COMPETE_TYPE.BATTLE].nPerson
    elseif dwMapID == dwBattleCurMapID then
        local tInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
        self.tAllCompete[COMPETE_TYPE.BATTLE_CUR].nScore = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]

        CareerData.tAllCompete[COMPETE_TYPE.BATTLE_CUR] = {}
        CareerData.tAllCompete[COMPETE_TYPE.BATTLE_CUR].nScore = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
    end
end

function UICareerCompete:SelectData(tbSelected)
    self.tCompete = {}
    self.tSelected = tbSelected
    local nIndex = 1
    for i = 1, 6 do
        if self.tSelected[i] == false then
            self.tCompete[nIndex] = self.tAllCompete[i]
            nIndex = nIndex + 1
        end
    end
end

function UICareerCompete:UpdateInfo()
    if #self.tCompete == 0 then
        self:UpdateEmpty()
    else
        self:UpdateView()
    end
end

function UICareerCompete:UpdateEmpty()
    UIHelper.SetVisible(self.ScrollViewCompeteList, false)
    UIHelper.SetVisible(self.WidgetWareHouseEmpty, true)
end

function UICareerCompete:UpdateView()
    UIHelper.SetVisible(self.ScrollViewCompeteList, true)
    UIHelper.SetVisible(self.WidgetWareHouseEmpty, false)
    UIHelper.RemoveAllChildren(self.ScrollViewCompeteList)
    for i = 1, #self.tCompete do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCareerCompeteListCell, self.ScrollViewCompeteList) assert(script)
        script:OnEnter(self.tCompete[i])
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewCompeteList)
    UIHelper.ScrollToLeft(self.ScrollViewCompeteList, 0)
end

return UICareerCompete