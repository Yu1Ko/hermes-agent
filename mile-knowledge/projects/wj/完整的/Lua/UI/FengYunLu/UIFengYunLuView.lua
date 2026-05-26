---@class UIFengYunLuView
local UIFengYunLuView = class("UIFengYunLuView")

local tRankingLevel2 = {
    { nStartIndex = 1, nEndIndex = 10 },
    { nStartIndex = 11, nEndIndex = 30 },
    { nStartIndex = 31, nEndIndex = 100 },
    { nStartIndex = 101, nEndIndex = 200 },
    { nStartIndex = 201, nEndIndex = 300 },
    { nStartIndex = 301, nEndIndex = 500 },
}

local tRankingPage = {
    {
        szPage = "Page_Person",
        nTitlePrefabID = PREFAB_ID.WidgetPersonageListTitle,
        nRankingLevel = 4,
        nCategory = FengYunLuCategory.Normal
    },
    {
        szPage = "Page_HQGuild",
        nTitlePrefabID = PREFAB_ID.WidgetTongExploitsListTitle01,
        nRankingLevel = 3,
    },
    {
        szPage = "Page_ERGuild",
        nTitlePrefabID = PREFAB_ID.WidgetTongExploitsListTitle01,
        nRankingLevel = 3,
    },
    {
        szPage = "Page_Arena",
        szTitleList = "Handle_Title_Arena",
        szWnd = "Wnd_ARanking",
        szRankingList = "Handle_ArenaRanking_Content/Handle_RankingMes_Arena",
        szRankingTitle = "Handle_ARanking_Top/Text_ArenaRanking_Title",
        szRankingCheck = "CheckBox_RankingArena",
        szLevelImage = "Image_LevelBiaoShi_Arena",
        nTitlePrefabID = PREFAB_ID.WidgetMingJianDaShiListTitle,
        nRankingLevel = 6,
    },
    {
        szPage = "Page_Trials",
        nTitlePrefabID = PREFAB_ID.WidgetShiLianListTitle,
        nRankingLevel = 3,
    },
    {
        nTitlePrefabID = PREFAB_ID.WidgetJiangHuListTitle,
        nRankingLevel = 3,
        nCategory = FengYunLuCategory.JiangHu
    },
    {
        nTitlePrefabID = PREFAB_ID.WidgetMingJianDaShiListTitle,
        nRankingLevel = 6,
        tRankingLevel = tRankingLevel2,
        nCategory = FengYunLuCategory.ArenaMaster
    },
    {
        szPage = "Page_PveRougeLike",
        nRankingLevel = 6,
        nTitlePrefabID = PREFAB_ID.WidgetBaHuangListTitle,
    },
    {
        szPage = "Page_Pve1v1",
        nRankingLevel = 6,
        nTitlePrefabID = PREFAB_ID.WidgetSchool1V1Title,
        nCategory = FengYunLuCategory.School1V1
    },
    {
        szPage = "Page_GuildLeague",
        nRankingLevel = 4,
        nTitlePrefabID = PREFAB_ID.WidgetTongMatchTitle,
        nCategory = FengYunLuCategory.GuildLeague
    },
    {
        szPage = "Page_Pve3v3",
        nRankingLevel = 6,
        nTitlePrefabID = PREFAB_ID.WidgetSchool3V3Title,
        nCategory = FengYunLuCategory.School3V3
    }
}

local RANK_TYPE = {
    PERSON     = 0,  -- 个人排名
    TONG       = 1,  -- 帮会排名
    ARENA      = 2,  -- 竞技场
    SHI_LIAN   = 3,  -- 试炼
    JIANG_HU   = 7,  -- 江湖
    MASTER     = 8,  -- 大师赛
    BA_HUANG   = 9,  -- 八荒
    ONE_V_ONE  = 10, -- 1V1
    TONG_LEAGUE = 11, -- 帮会联盟
    THREE_V_THREE = 12, -- 3V3
}

local nRankTypeShowSelfRanking = { RANK_TYPE.PERSON, RANK_TYPE.TONG, RANK_TYPE.SHI_LIAN, RANK_TYPE.JIANG_HU, RANK_TYPE.BA_HUANG, RANK_TYPE.ONE_V_ONE, RANK_TYPE.THREE_V_THREE } -- 是否显示自身排名节点
local nRankTypeShowPaginate = { RANK_TYPE.PERSON, RANK_TYPE.TONG, RANK_TYPE.BA_HUANG }  -- 显示分页的排行榜
local nRankTypeShowDesc = { RANK_TYPE.PERSON, RANK_TYPE.TONG, RANK_TYPE.MASTER }

local CUSTOM_RANK_TYPES = { -- 使用自定义排行榜同步回调的类型
    [RANK_TYPE.SHI_LIAN] = true,
    [RANK_TYPE.JIANG_HU] = true,
    [RANK_TYPE.BA_HUANG] = true,
    [RANK_TYPE.ONE_V_ONE] = true,
    [RANK_TYPE.THREE_V_THREE] = true,
}

local l_tongcastle = {}

local MAX_PAGE_NUMBER = 50
local MAX_RANK_COUNT = 500

local MIN_RANK_LIMIT = 30
local MIN_TITLE_POINT = 1400000

local TONG_NAME_LIMIT_LEN = 8
local dwDesertStormMapID = 296
local bShowRankType = false
local tDesertStormRankTitle = {
    "绝境名士录",
    "龙门天命榜",
    "荒漠霸王榜",
    "独步尊者榜",
    "喋血枭雄榜",
    "佛系圣手榜",
    "瀚海兵甲榜",
}
local nPersonalScore = BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL

local tMilitaryRankTitle = {
    { szTitle = "本周浩气五十强", nRankType = 1 },
    { szTitle = "本周恶人五十强", nRankType = 2 },
    { szTitle = "赛季浩气五十强", nRankType = 3 },
    { szTitle = "赛季恶人五十强", nRankType = 4 },
    { szTitle = "上周浩气五十强", nRankType = 214 },
    { szTitle = "上周恶人五十强", nRankType = 215 },
}

local MILITARY_DESC = "帮会战阶积分决定了帮会在本阵营中的排名,也体现了帮会对阵营的贡献!"

local NUM_PER_PAGE = 100 -- 好友排行每页显示数量

local szCurrentWeekText = "温馨提示：每周帮会战功榜阵营排名前30或总战阶积分高于140万，则可保有所占据点，否则下周每日扣除3万帮会资金。若一周后仍未满足任一上述条件，则回收据点归阵营所有。（刷新间隔15分钟）"
local szLastWeekText = "温馨提示:1.排行前十的帮会均可获得嘉奖,第1~3名更可获得祭天石举办阵营出征祭祀；2.榜上战阶总和较少的阵营将公开招募一定名额的帮会、侠士;3.排行帮会可在逐鹿中原中,请阵营首领精英前来助战"

local nMilitaryTypeToHelpText = {
    [1] = szCurrentWeekText,
    [2] = szCurrentWeekText,
    [3] = "温馨提示:赛季结算时,1名帮会获得南屏山据点；2-10名及11-20名中的三个随机帮会,各获得限时一周的挑战道具。使用道具可优先挑战本阵营其余12处据点，一周后仍有据点未归属帮会,则该据点可被本阵营任一无据点帮会挑战并占领。",
    [4] = "温馨提示:赛季结算时,1名帮会获得昆仑据点；2-10名及11-20名中的三个随机帮会,各获得限时一周的挑战道具。使用道具可优先挑战本阵营其余12处据点，一周后仍有据点未归属帮会,则该据点可被本阵营任一无据点帮会挑战并占领。",
    [214] = szLastWeekText,
    [215] = szLastWeekText,
}

local ARENA_PAGE = 10
local ARENA_DESC = "统计名剑大会战队积分，并进行排名。"
local APPLY_TONG_LEAGUE_CD = 1

local tDataRange = {
    { nStart = 1, nEnd = 10 },
    { nStart = 11, nEnd = 50 },
    { nStart = 51, nEnd = 100 },
    { nStart = 101, nEnd = 150 },
    { nStart = 151, nEnd = 200 },
    { nStart = 201, nEnd = 250 },
    { nStart = 251, nEnd = 300 },
    { nStart = 301, nEnd = 350 },
    { nStart = 351, nEnd = 400 },
    { nStart = 401, nEnd = 450 },
    { nStart = 451, nEnd = 500 },
}

local tArenaType = {
    ["Arena_2V2"] = ARENA_UI_TYPE.ARENA_2V2,
    ["Arena_3V3"] = ARENA_UI_TYPE.ARENA_3V3,
    ["Arena_5V5"] = ARENA_UI_TYPE.ARENA_5V5,
    ["Arena_Master_3V3"] = ARENA_UI_TYPE.ARENA_MASTER_3V3,
}

local function CheckCD(a, b, cd)
    if a and b and cd then
        if a - b >= cd then
            return true
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GET_GLOBAL_RANKING_FAILED)
            return false
        end
    end
end

local function GetArenaRankKey(nArenaType)
    for k, v in pairs(tArenaType) do
        if v == nArenaType then
            return k
        end
    end
end

local function GetRankingTitle(dwID)
    local t = g_tTable.RankingTitle:Search(dwID)
    if t then
        return SplitString(t.szTitle, "|")
    end
end

local function GetHouseAddress(nMapID, nLandIndex, nIndex, bPH)
    if bPH then
        return UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
    elseif nIndex ~= 0 then
        return UIHelper.GBKToUTF8(Table_GetMapName(nMapID)) ..
                FormatString(g_tStrings.STR_LINK_ADDRESS, nIndex, nLandIndex)
    end
    return g_tStrings.STR_LINK_NOHOME
end

local function IsPageShow(dwSub)
    if dwSub == 39 and not GetActivityMgrClient().IsActivityOn(ACTIVITY_ID.MASTER_ARENA) then
        return false  --大师赛
    end

    if dwSub == 42 and not GetActivityMgrClient().IsActivityOn(ACTIVITY_ID.ROUGE_LIKE) then
        return false
    end

    if dwSub == 43 and not GetActivityMgrClient().IsActivityOn(ACTIVITY_ID.SOLO_ARENA) then
        return false
    end

    if dwSub == 44 and not GetActivityMgrClient().IsActivityOn(ACTIVITY_ID.TONG_LEAGUE_RANK) then
        return false
    end

    return true
end


--=======================================================================

local function GetMaxPageNum()
    if IsMobileStreamingEnable() then
        return MAX_PAGE_NUMBER_SM
    end

    return MAX_PAGE_NUMBER
end

local function GetPageRange(nPageIndex)
    local nMaxNum = GetMaxPageNum()
    local nStartIndex = 0
    local nEndIndex = 0
    if nPageIndex == 0 then
        nEndIndex = nPageIndex + nMaxNum + 3 - 1
    else
        nStartIndex = nPageIndex * nMaxNum + 3
        nEndIndex = nStartIndex + nMaxNum - 1
    end

    if nEndIndex >= MAX_RANK_COUNT then
        nEndIndex = MAX_RANK_COUNT - 1
    end
    return nStartIndex, nEndIndex
end

function UIFengYunLuView:OnEnter(nCategory, nInitialIndex, nSelectDetail)
    if not self.bInit then
        FriendRank.aFriend = nil

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tGlobalCustomRanking = {}
        self.tGlobalJueJingRanking = {}
        self.tGlobalRanking = {}
        self.tGlobalMasterRanking = {}
        self.nRankInfoType = nil

        self.cellScripts = {} ---@type UIWidgetTongExploitsListCell
        self.titleScript = nil

        self.nRankVersion = 0

        self.selectedPage = nil
        self.nCategory = nCategory or FengYunLuCategory.Normal
        self.nInitialIndex = nInitialIndex or 1
        self.nSelectDetail = nSelectDetail

        self.navigationScript = UIHelper.GetBindScript(self.WidgetVertical_Navigation)---@type UIWidgetScrollViewTree

        self.nShortOriginalWidth, self.nShortOriginalHeight = UIHelper.GetContentSize(self.ScrollViewList_Short)
        _, self.nPageOriginalHeight = UIHelper.GetContentSize(self.WidgetPaginate)
        self.nMineOriginY = UIHelper.GetPositionY(self.WidgetMine)

        UIHelper.SetEditBoxInputMode(self.EditPaginate, cc.EDITBOX_INPUT_MODE_NUMERIC)

        RemoteCallToServer("OnGetFengyunRankVersion")
        LoadMilitaryRankData()

        RemoteCallToServer("On_Castle_TongToCastleRequest")
    end

    self:Init()
end

function UIFengYunLuView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer()
end

function UIFengYunLuView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nCurrentPageIndex > self.nStartPage then
            self:UpdateCurrentPage(self.nCurrentPageIndex - 1)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nCurrentPageIndex < self.nEndPage then
            self:UpdateCurrentPage(self.nCurrentPageIndex + 1)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            self:UpdateCurrentPage(nPageIndex)
        end
    end)
end

function UIFengYunLuView:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(arg0)
        if self.nMainRankType == FengYunLuType.Military then
            self:OnSyncAllJHRankingInfo(arg0)
        end
        if CUSTOM_RANK_TYPES[self.nRankInfoType] then
            self:OnSyncCustomRankingInfo(arg0)
        end
    end)

    Event.Reg(self, "ON_FENGYUNLU_GET_RANKING", function(arg0, arg1, arg2, arg3, arg4)
        self:OnSyncGlobalRankingInfo(arg0, arg1, arg3, arg4)
    end)

    Event.Reg(self, "SYNC_ARENA_RANK_LIST", function(arg0, arg1, arg2, arg3, arg4)
        local nCorpsType = arg0
        local nPageIndex = arg1
        self:OnSyncMasterRankList(nCorpsType, nPageIndex)
    end)

    Event.Reg(self, "ON_FENGYUNLU_GET_RANKING_VERSION", function(arg0)
        self.nRankVersion = arg0
    end)

    Event.Reg(self, "SYNC_TONG_LEAGUE_RANK_LIST", function(arg0)
        self:OnSyncTongLeagueRankList()
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        UIMgr.Open(VIEW_ID.PanelFengYunLuRewardTitlePop, szUrl)
    end)

    Event.Reg(self, "SYNC_BF_RANK_LIST", function(arg0, arg1, arg2, arg3)
        bShowRankType = false

        local dwMapID = arg0
        local dwRankType = arg1
        local nStartIndex = arg2
        local nEndIndex = arg3
        --local nPageIndex = math.modf(nStartIndex / GetMaxPageNum())

        if self.nMainRankType == FengYunLuType.JueJing and self.nJueJingRankType == dwRankType then
            self:OnSyncJueJingRankList(dwRankType, nStartIndex, nEndIndex)
        end
    end)

    Event.Reg(self, "MILITARY_RANK_UPDATE", function(arg0, arg1, arg2, arg3)
        local nType, nTotalNum = arg0, arg1
        self:UpdateMilitaryRanking(nType)
    end)

    Event.Reg(self, "ON_CASTLE_TONG_CASTLE_RESPOND", function(arg0, arg1, arg2, arg3)
        l_tongcastle = arg0
    end)

    Event.Reg(self, "FELLOW_KEY_DATA_UPDATE", function(arg0)
        FriendRank.UpdateFellowInfo()
        self:UpdateFriendRankList(arg0)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(arg0, arg1)
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
            --self.navigationScript:UpdateInfo()
        end)
    end)

    Event.Reg(self, EventType.OnFengYunLuDisableArrow, function()
        self:SetPageIndexInfo(1, 1, 1, 10)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then
            return
        end

        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            self:UpdateCurrentPage(nPageIndex)
        end
    end)
end

function UIFengYunLuView:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFengYunLuView:Init()
    local dwGeneral = 3
    local tGeneral = g_tTable.AchievementGeneral:Search(dwGeneral)
    local tPageList = {}

    local navigationData = {}

    --- 遍历排名的大类 包括个人排名、竞技场等
    local nIndex = 1
    for szSub in string.gmatch(tGeneral.szSubs, "%d+") do
        local dwSub = tonumber(szSub)
        local bShow = IsPageShow(dwSub)
        local tPage = tRankingPage[nIndex]
        local hPage = {}
        hPage.bPageCheck = true
        hPage.nTitlePrefabID = tPage.nTitlePrefabID
        hPage.nCategory = tPage.nCategory
        hPage.dwGeneral = dwGeneral
        hPage.dwSub = dwSub
        nIndex = nIndex + 1

        if bShow then
            self:InitRankingSub(hPage, navigationData)
            table.insert(tPageList, hPage)
        end
    end

    self:InitJueJingSub(navigationData)
    self:InitMilitarySub(navigationData)
    self:InitFriendSub(navigationData)

    ---@param scriptContainer UIScrollViewTreeContainer
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
        --UIHelper.SetSwallowTouches(scriptContainer.ToggleSelect, false)
    end

    self.navigationScript:SetOuterInitSelect(false)
    UIHelper.SetupScrollViewTree(self.navigationScript, PREFAB_ID.WidgetFengYunLuTitle, PREFAB_ID.WidgetFengYunLuChildNavigation,
            func, navigationData, true)

    ---初次进入风云录面板时的初始分类
    Timer.AddFrame(self, 15, function()
        for _, tContainer in ipairs(self.navigationScript.tContainerList) do
            if self.nCategory and tContainer.tArgs.nCategory == self.nCategory then
                local scriptContainer = tContainer.scriptContainer
                UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
                for i, t in ipairs(tContainer.tItemList) do
                    if self.nSelectDetail and t.tArgs.dwDetail == self.nSelectDetail then
                        UIHelper.SetSelected(scriptContainer.tItemScripts[i].ToggleChildNavigation, true)
                    end
                end
            end
        end
    end)
end

function UIFengYunLuView:InitRankingSub(hPage, navigationData)
    local dwGeneral = hPage.dwGeneral
    local dwSub = hPage.dwSub
    local tSub = g_tTable.AchievementSub:Search(dwSub)

    local function Get1V1Sub()
        local function values(tbl)
            local i = 0
            return function()
                i = i + 1
                return tbl[i]
            end
        end

        local nCount = g_tTable.Ranking:GetRowCount()
        local tActivity = {}
        for i = 2, nCount do
            local tLine = g_tTable.Ranking:GetRow(i)

            if tLine.nType == FengYunLuCategory.School1V1 then
                local nEndIndex = string.find(tLine.szKey, "_")
                local nKungfu = tonumber(string.sub(tLine.szKey, nEndIndex + 1))
                if not TabHelper.IsHDKungfuID(nKungfu) then
                    table.insert(tActivity, tLine.dwID)
                end
            end
        end

        return values(tActivity)
    end

    local fnTitleSelected = function(bSelected, scriptContainer)
        if bSelected then
            local tRankingInfo = hPage and g_tTable.Ranking:Search(hPage.dwDetail)
            local nSubType = tRankingInfo and tRankingInfo.nType
            local tParam = {
                scriptContainer = scriptContainer,
                nMainRankType = FengYunLuType.Normal,
                hPage = hPage,
                nSubType = nSubType,
                nTitlePrefabID = hPage.nTitlePrefabID,
                bTimeTip = table.contain_value(nRankTypeShowDesc, nSubType),
                bDesc = false,
                bHelpToggle = false
            }
            self:SelectMainTitle(tParam)
        end
    end

    local szRankTitle = UIHelper.GBKToUTF8(tSub.szName)
    if szRankTitle ~= "江湖百态" then
        szRankTitle = string.gsub(szRankTitle, "江湖", "")
    end
    if szRankTitle ~= "个人排名" then
        szRankTitle = string.gsub(szRankTitle, "排名", "")
    end

    local titleData = { tArgs = { szTitle = szRankTitle, nCategory = hPage.nCategory }, fnSelectedCallback = fnTitleSelected, tItemList = { } }

    local fnIterator = hPage.nCategory ~= FengYunLuCategory.School1V1
            and string.gmatch(tSub.szDetails, "%d+") or Get1V1Sub() -- 插旗大王1v1的子类不在AchievementSub中，单独从Ranking表中获取
    for szGeneral in fnIterator do
        local dwDetail = tonumber(szGeneral)
        local tDetail = g_tTable.Ranking:Search(dwDetail)
        local bShow = true

        if bShow then
            if not hPage.dwDetail then
                hPage.dwDetail = dwDetail
            end

            local fnSubSelected = function(toggle, bState)
                if bState == true then
                    self:OnNormalRankingSubTitle(dwDetail)
                end
            end

            local subData = { tArgs = { szTitle = UIHelper.GBKToUTF8(tDetail.szName), onSelectChangeFunc = fnSubSelected ,dwDetail = dwDetail} }
            table.insert(titleData.tItemList, subData)
        end
    end

    table.insert(navigationData, titleData)
end

function UIFengYunLuView:InitJueJingSub(navigationData)
    local fnTitleSelected = function(bSelected, scriptContainer)
        if bSelected then
            local tParam = {
                scriptContainer = scriptContainer,
                nMainRankType = FengYunLuType.JueJing,
                nTitlePrefabID = PREFAB_ID.WidgetJueJingListTitle,
                bTimeTip = false,
                bDesc = false,
                bHelpToggle = false
            }
            self:SelectMainTitle(tParam)
        end
    end

    local titleData = { tArgs = { szTitle = "绝境战场", nCategory = FengYunLuCategory.JueJing }, fnSelectedCallback = fnTitleSelected, tItemList = { } }

    for index, szSubName in ipairs(tDesertStormRankTitle) do
        local fnSubSelected = function(toggle, bState)
            local dwRankType = index
            if bState == true then
                UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
                UIHelper.RemoveAllChildren(self.WidgetMineParent)
                UIHelper.SetVisible(self.ImgNotInRanking, true)
                self.cellScripts = {}

                local nPageIndex = 0
                local nStartIndex = 1

                self.nJueJingRankType = dwRankType
                UIHelper.SetString(self.LabelContentTitle, szSubName)
                self:SetIntroduceText("   ")

                self:SetPageIndexInfo(1, 1, 50, 10) -- 设定翻页范围
                self:RefreshPaginate()

                self:UpdateJueJingRankList(dwRankType, nStartIndex, nStartIndex + self.nCountOfEachPage - 1)
            end
        end

        local subData = { tArgs = { szTitle = szSubName, onSelectChangeFunc = fnSubSelected } }
        table.insert(titleData.tItemList, subData)
    end

    table.insert(navigationData, titleData)
end

function UIFengYunLuView:InitMilitarySub(navigationData)
    local fnTitleSelected = function(bSelected, scriptContainer)
        if bSelected then
            local tParam = {
                scriptContainer = scriptContainer,
                nMainRankType = FengYunLuType.Military,
                bTimeTip = true,
                bDesc = false,
                bHelpToggle = true
            }
            self:SelectMainTitle(tParam)
        end
    end

    local titleData = { tArgs = { szTitle = "帮会战功", nCategory = FengYunLuCategory.Military }, fnSelectedCallback = fnTitleSelected, tItemList = { } }
    for index, tData in ipairs(tMilitaryRankTitle) do
        local fnSubSelected = function(toggle, bState)
            local dwRankType = index
            if bState == true then
                UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
                UIHelper.RemoveAllChildren(self.WidgetMineParent)
                UIHelper.SetVisible(self.ImgNotInRanking, true)

                UIHelper.SetString(self.LabelContentTitle, tData.szTitle)
                UIHelper.LayoutDoLayout(self.LayoutTitle)

                self:SetIntroduceText(MILITARY_DESC)

                UIHelper.RemoveAllChildren(self.FengYunLuTitleParent)
                local bLastWeek = index == 5 or index == 6
                self.titleScript = UIHelper.AddPrefab(bLastWeek and PREFAB_ID.WidgetTongExploitsListTitle02
                        or PREFAB_ID.WidgetTongExploitsListTitle01, self.FengYunLuTitleParent)

                UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function()
                    local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
                    , self.TogHelp, TipsLayoutDir.LEFT_CENTER, nMilitaryTypeToHelpText[tData.nRankType])

                    local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
                    tips:SetSize(x, y)
                    tips:Update()
                end)

                self.cellScripts = {}
                self:ApplyMilitaryRankList(tData.nRankType)
            end
        end

        local subData = { tArgs = { szTitle = tData.szTitle, onSelectChangeFunc = fnSubSelected } }
        table.insert(titleData.tItemList, subData)
    end

    table.insert(navigationData, titleData)
end

function UIFengYunLuView:InitFriendSub(navigationData)
    local fnTitleSelected = function(bSelected, scriptContainer)
        if bSelected then
            local tParam = {
                scriptContainer = scriptContainer,
                nMainRankType = FengYunLuType.Military,
                nTitlePrefabID = PREFAB_ID.WidgetHaoYouListTitle,
                bTimeTip = true,
                bDesc = true,
                bHelpToggle = false
            }
            self:SelectMainTitle(tParam)
        end
    end

    local titleData = { tArgs = { szTitle = "好友排名", nCategory = FengYunLuCategory.Friend }, fnSelectedCallback = fnTitleSelected, tItemList = { } }

    local tMainType, tCatalog = Table_GetFriendRankCatalog()
    for _, name in ipairs(tMainType) do
        local info = tCatalog[name]
        for _, v in ipairs(info) do
            local szName = UIHelper.GBKToUTF8(v.name)
            local fnSubSelected = function(toggle, bState)
                if bState == true then
                    UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
                    UIHelper.RemoveAllChildren(self.WidgetMineParent)
                    UIHelper.SetVisible(self.ImgNotInRanking, true)

                    UIHelper.SetString(self.LabelContentTitle, szName)
                    self:SetIntroduceText("  ")

                    UIHelper.SetString(self.titleScript.LabelChangable, szName)

                    self.nFriendPage = 1
                    self.nFriendAscend = v.ascend

                    self.cellScripts = {}

                    self:ApplyFriendRankList(v.key)
                end
            end

            local subData = { tArgs = { szTitle = szName, onSelectChangeFunc = fnSubSelected } }
            table.insert(titleData.tItemList, subData)
        end
    end

    table.insert(navigationData, titleData)
end

--------------------------Title初始化------------------------------------

function UIFengYunLuView:SelectMainTitle(tParam)
    local scriptContainer = tParam.scriptContainer
    local hPage = tParam.hPage

    self:SwitchContainer(tParam.nMainRankType, tParam.nSubType)

    UIHelper.RemoveAllChildren(self.FengYunLuTitleParent)
    UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
    UIHelper.RemoveAllChildren(self.WidgetMineParent)

    self.nMainRankType = tParam.nMainRankType
    self.selectedPage = hPage
    self.cellScripts = {}
    self.titleScript = tParam.nTitlePrefabID and UIHelper.AddPrefab(tParam.nTitlePrefabID, self.FengYunLuTitleParent)

    UIHelper.SetVisible(self.WidgetEmpty, false)
    self:SetInfoNodeVisible(tParam.bTimeTip, tParam.bDesc, tParam.bHelpToggle)

    local nIndex = self.nInitialIndex or 1
    UIHelper.SetSelected(scriptContainer.tItemScripts[nIndex].ToggleChildNavigation, true)

    self.nInitialIndex = nil
end

---@param dwDetail number 排名详情 ID
function UIFengYunLuView:OnNormalRankingSubTitle(dwDetail)
    UIHelper.SetVisible(self.ImgNotInRanking, true)
    UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
    UIHelper.RemoveAllChildren(self.WidgetMineParent)

    local tRankingInfo = g_tTable.Ranking:Search(dwDetail)
    self.selectedPage.dwDetail = dwDetail
    self.selectedPage.szKey = tRankingInfo.szKey

    self.cellScripts = {}

    if tRankingInfo.nType == RANK_TYPE.JIANG_HU or tRankingInfo.nType == RANK_TYPE.SHI_LIAN or tRankingInfo.nType == RANK_TYPE.MASTER
            or tRankingInfo.nType == RANK_TYPE.ARENA or tRankingInfo.nType == RANK_TYPE.ONE_V_ONE or tRankingInfo.nType == RANK_TYPE.THREE_V_THREE then
        -- Event.Dispatch(EventType.OnFengYunLuDisableArrow) -- 禁用翻页
    elseif tRankingInfo.nType == RANK_TYPE.BA_HUANG then
        self:SetPageIndexInfo(1, 1, 40, 10) -- 八荒上限40
        self:RefreshPaginate()
    elseif tRankingInfo.nType == RANK_TYPE.TONG_LEAGUE then
        self:SetPageIndexInfo(1, 1, 1, 64)
        self:RefreshPaginate()
    else
        local nEndIndex = tRankingInfo.szKey == "Rank_Role_CollectFurniture" and 10 or 5
        self:SetPageIndexInfo(1, 1, nEndIndex, 10)
        self:RefreshPaginate()
    end

    if tRankingInfo.nType == RANK_TYPE.MASTER or tRankingInfo.nType == RANK_TYPE.ARENA then
        self:SetContentTree(tRankingInfo.nType, tRankingInfo.szKey)
    end
    self:UpdateSelectRanking(self.selectedPage)
end

--------------------------绝境信息获取相关------------------------------------

function UIFengYunLuView:GetJueJingRankingValue(nRankType, nStartIndex, nEndIndex)
    local a = self.tGlobalJueJingRanking[nRankType]
    local nTime = GetCurrentTime()

    local GetInfo = function()
        self:SetLoading(true)
        GetBFRankList(dwDesertStormMapID, nRankType, nStartIndex - 1, nEndIndex - 1)
    end

    local nCDTime = 0.3
    if not a or not a.nQueryTime then
        GetInfo()
        self.tGlobalJueJingRanking[nRankType] = { nQueryTime = nTime }
        return {}
    elseif not a and a.nQueryTime and CheckCD(nTime, a.nQueryTime, nCDTime) then
        GetInfo()
        a.nQueryTime = nTime
        return a.tRanking or {}
    elseif (not a.tRanking or IsTableEmpty(a.tRanking)) and CheckCD(nTime, a.nQueryTime, nCDTime) then
        return {}
    end

    if a.tRanking and a.tSyncPage and not a.tSyncPage[self.nCurrentPageIndex] and CheckCD(nTime, a.nQueryTime, nCDTime) then
        GetInfo()
        a.nQueryTime = nTime
    end

    return a.tRanking or {}
end

function UIFengYunLuView:OnSyncJueJingRankList(nRankType, nStartIndex, nEndIndex)
    self.tGlobalJueJingRanking[nRankType] = self.tGlobalJueJingRanking[nRankType] or {}

    local tGlobalKey = self.tGlobalJueJingRanking[nRankType]

    tGlobalKey.tRanking = tGlobalKey.tRanking or {}
    tGlobalKey.nQueryTime = tGlobalKey.nQueryTime or GetCurrentTime()

    tGlobalKey.tSyncPage = tGlobalKey.tSyncPage or {}
    tGlobalKey.tSyncPage[self.nCurrentPageIndex] = true

    for i = nStartIndex, nEndIndex do
        local tInfo = GetBFRankRoleInfo(dwDesertStormMapID, nRankType, i)
        tGlobalKey.tRanking[i + 1] = tInfo
    end

    self:UpdateJueJingRankList(nRankType, nStartIndex + 1, nEndIndex + 1)
    self:SetLoading(false)
end

function UIFengYunLuView:UpdateJueJingRankList(dwRankType, nStartIndex, nEndIndex)
    UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
    self.cellScripts = {}

    local tRankData = self:GetJueJingRankingValue(dwRankType, nStartIndex, nEndIndex)
    if not tRankData then
        return
    end

    local initCellData = function(script, tRankInfo, nIndex)
        local nConvertedIndex = nIndex - 1
        local szCenterName = Table_GetServerName(tRankInfo.nCenterID)
        local nBattleRounds = GetBFRankRoleScore(dwDesertStormMapID, dwRankType, nConvertedIndex, BF_MAP_ROLE_INFO_TYPE.BATTLE_ROUNDS)
        local nTopCount = GetBFRankRoleScore(dwDesertStormMapID, dwRankType, nConvertedIndex, BF_MAP_ROLE_INFO_TYPE.TOP_COUNT)
        local nDSScore = GetBFRankRoleScore(dwDesertStormMapID, dwRankType, nConvertedIndex, nPersonalScore)

        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tRankInfo.szName))
        UIHelper.SetSpriteFrame(script.ImgSchool, PlayerForceID2SchoolImg2[tRankInfo.byForceID])
        UIHelper.SetString(script.LabelTongName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tRankInfo.szTongName), TONG_NAME_LIMIT_LEN))
        UIHelper.SetString(script.LabelServer, UIHelper.GBKToUTF8(szCenterName))
        UIHelper.SetString(script.LabelPersonalRationg, nDSScore)
        UIHelper.SetString(script.LabelCrownNum, nTopCount)
        UIHelper.SetString(script.LabelSession, nBattleRounds)
    end

    local bHasData = false
    for nIndex = nStartIndex, nEndIndex, 1 do
        local tInfo = tRankData[nIndex] or GetBFRankRoleInfo(dwDesertStormMapID, dwRankType, nIndex - 1)  -- 原Index下表从0开始
        if not tInfo or tonumber(tInfo.uGlobalRoleID) == 0 then
            break
        end
        tRankData[nIndex] = tInfo
        bHasData = true
    end


    local fnMineCheck = function(tInfo)
        return tInfo.szName == g_pClientPlayer.szName
    end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetJueJingListCell, tRankData, nStartIndex, nEndIndex, initCellData, fnMineCheck)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFengYunLuList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFengYunLuList, self.WidgetArrow)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasData)
end

--------------------------帮会战功排行榜信息相关------------------------------------

local function IsCastleRecycling(info)
    --print(info.nRankID, MIN_RANK_LIMIT, info.nTitlePoint, MIN_TITLE_POINT)
    return l_tongcastle[info.dwTongID] and info.nRankID > MIN_RANK_LIMIT and info.nTitlePoint < MIN_TITLE_POINT
end

function UIFengYunLuView:ApplyMilitaryRankList(rankType)
    self:SetLoading(true)
    if rankType == LAST_WEEK_RANK_TYPE_ER or rankType == LAST_WEEK_RANK_TYPE_HQ then
        self:UpdateMilitaryRanking_LastWeek(rankType)
    else
        GetMilitaryRankListClient().ApplyMilitaryRankList(rankType)
    end
end

function UIFengYunLuView:UpdateMilitaryRanking(rankType)
    self:SetLoading(false)

    local ranklist = GetMilitaryRankListClient().GetMilitaryRankList(rankType).GetRankList()
    local selftongid = GetClientPlayer().dwTongID

    local initCellData = function(script, tInfo)
        local szTongName = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo.szTongName), TONG_NAME_LIMIT_LEN)
        UIHelper.SetString(script.LabelTongName, szTongName)
        UIHelper.SetString(script.LabelTongMasterName, UIHelper.GBKToUTF8(tInfo.szMasterName))
        UIHelper.SetString(script.LabelRecruitNum, tInfo.nMemberCount .. "/" .. tInfo.nMaxMemberCount)
        UIHelper.SetString(script.LabelScore, tInfo.nTitlePoint)

        local castleName = l_tongcastle[tInfo.dwTongID]
        castleName = castleName and UIHelper.GBKToUTF8(castleName) or "--"
        UIHelper.SetString(script.LabelStrongholdAttridution, castleName)

        if IsCastleRecycling(tInfo) then
            script:ShowWarning()
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, not (ranklist and #ranklist > 0))
    for i, tInfo in ipairs(ranklist) do
        tInfo.nRankID = i
    end

    local fnMineCheck = function(tInfo)
        return selftongid == tInfo.dwTongID
    end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetTongExploitsListCell01, ranklist, 1, 50, initCellData, fnMineCheck)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFengYunLuList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFengYunLuList, self.WidgetArrow)
end

function UIFengYunLuView:UpdateMilitaryRanking_LastWeek(rankType)
    self.nJHType = rankType
    local ranklist = self:GetJHMilitaryRankingValue(rankType)

    local initCellData = function(script, tInfo)
        UIHelper.SetString(script.LabelTongName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo.szTongName), TONG_NAME_LIMIT_LEN))
        UIHelper.SetString(script.LabelTongMasterName, UIHelper.GBKToUTF8(tInfo.szMasterName))
        UIHelper.SetString(script.LabelScore, tInfo.nKey)
    end

    UIHelper.SetVisible(self.WidgetEmpty, not (ranklist and #ranklist > 0))

    local fnMineCheck = function(tInfo)
        return TongData.GetName() == tInfo.szTongName
    end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetTongExploitsListCell02, ranklist, 1, 50, initCellData, fnMineCheck)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFengYunLuList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFengYunLuList, self.WidgetArrow)
end

function UIFengYunLuView:GetJHMilitaryRankingValue(nType)
    if not self.bApplyAllJHRankInfo then
        self:SetLoading(true)
        ApplyCustomRankList(nType)
    end

    local tRanking = self.tGlobalCustomRanking[nType] or {}
    return tRanking
end

function UIFengYunLuView:OnSyncAllJHRankingInfo(nType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    --print("UIFengYunLuView:OnSyncAllJHRankingInfo")

    self.tGlobalCustomRanking[nType] = GetCustomRankList(nType)
    self.bApplyAllJHRankInfo = true

    if not self.nJHType or self.nJHType ~= nType
            or not (nType == LAST_WEEK_RANK_TYPE_ER or nType == LAST_WEEK_RANK_TYPE_HQ) then
        return
    end

    self:SetLoading(false)
    self:UpdateMilitaryRanking_LastWeek(nType)

    self.bApplyAllJHRankInfo = false
end

--------------------------好友排名排行榜信息获取相关------------------------------------

function UIFengYunLuView:ApplyFriendRankList(key)
    self:SetLoading(true)
    FriendRank.RqstKey(key)
end

function UIFengYunLuView:UpdateFriendRankList(key)
    self:SetLoading(false)

    local start = (self.nFriendPage - 1) * NUM_PER_PAGE + 1
    SortFellowshipRankData(key, self.nFriendAscend)

    local FellowClient = GetFellowshipRankClient()
    local res = FellowClient.GetFellowshipRankDataInfo(key, start - 1, NUM_PER_PAGE)
    res = res or {}

    UIHelper.SetVisible(self.WidgetEmpty, not (res and #res > 0))

    local fellows = FriendRank.GetFellowInfo()
    local initCellData = function(script, tInfo)
        local fellowInfo = fellows[tInfo.ID]
        if fellowInfo then
            UIHelper.SetString(script.LabelPlayerName, fellowInfo.name and UIHelper.GBKToUTF8(fellowInfo.name) or " ")
            UIHelper.SetSpriteFrame(script.ImgSchool, PlayerForceID2SchoolImg2[fellowInfo.forceid])
            UIHelper.SetString(script.LabelSchool, Table_GetForceName(fellowInfo.forceid))
            script:SetEnable(true)
        end
        UIHelper.SetString(script.LabelScore, tInfo.Value)
    end

    local fnMineCheck = function(tInfo)
        local playerGlobalID = g_pClientPlayer.GetGlobalID()
        return fellows[tInfo.ID] and tInfo.ID == playerGlobalID
    end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetHaoYouListCell, res, 1, #res, initCellData, fnMineCheck)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFengYunLuList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFengYunLuList, self.WidgetArrow)
end

--------------------------通用排名方法------------------------------------

--- 设置内容树（竞技场系列/大师赛）
---@param nType number 排行榜类型
---@param szKey string 排行榜 key
function UIFengYunLuView:SetContentTree(nType, szKey)
    self.tGlobalMasterRanking = {} --TODO:临时解决竞技场系列数据加载问题

    self.contentTreeData = {}
    ---@param scriptContainer UIScrollViewTreeContainer
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
    end

    for _, tRange in ipairs(tDataRange) do
        if nType == RANK_TYPE.ARENA and tRange.nStart > 200 then
            -- 竞技场上限为200
            break
        end

        local fnTitleSelected = function(bSelected, scriptContainer)
            if bSelected then
                local nStartPageIndex = math.floor(tRange.nStart / ARENA_PAGE)
                local nStartPageEnd = math.floor((tRange.nEnd - 1) / ARENA_PAGE)
                --print("asdjksadjk", szKey, nStartPageIndex, nStartPageEnd)
                self:SetMasterRankingInfo(nStartPageIndex, nStartPageEnd, szKey)
                self:GetMasterRankingValue(szKey, nStartPageIndex, true)
            end
        end

        local szTitle1 = tRange.nStart .. '-' .. tRange.nEnd
        local titleData = { tArgs = { szTitle = szTitle1, nIndex = _ }, fnSelectedCallback = fnTitleSelected,
                            tItemList = {} }

        table.insert(self.contentTreeData, titleData)
    end

    self.largeContentScript:ClearContainer()
    UIHelper.SetupScrollViewTree(self.largeContentScript, PREFAB_ID.WidgetFYLListMoreTitle, nil,
            func, self.contentTreeData)

    --Timer.AddFrame(self, 1, function()
    --    local scriptContainer = self.largeContentScript.tContainerList[1].scriptContainer
    --    scriptContainer:SetSelected(true,false)
    --end)
end

--- 更新选中排行榜
---@param hPage table|nil 页配置，默认使用 self.selectedPage
function UIFengYunLuView:UpdateSelectRanking(hPage)
    UIHelper.RemoveAllChildren(self.ScrollViewFengYunLuList)
    self.cellScripts = {}

    local RANKING_UPDATE_STRATEGY = {
        [RANK_TYPE.PERSON]      = self.UpdatePersonRanking,
        [RANK_TYPE.TONG]        = self.UpdateTongRanking,
        [RANK_TYPE.SHI_LIAN]    = self.UpdateShiLianRanking,
        [RANK_TYPE.JIANG_HU]    = self.UpdateJiangHuRanking,
        [RANK_TYPE.BA_HUANG]    = self.UpdateBaHuangRanking,
        [RANK_TYPE.ONE_V_ONE]   = self.Update1V1Ranking,
        [RANK_TYPE.TONG_LEAGUE] = self.UpdateTongLeagueRanking,
        [RANK_TYPE.THREE_V_THREE] = self.Update3V3Ranking,
    }

    hPage = hPage or self.selectedPage
    local tRankingInfo = g_tTable.Ranking:Search(hPage.dwDetail)
    if tRankingInfo.szName then
        local szTextTitle = UIHelper.GBKToUTF8(tRankingInfo.szName)
        UIHelper.SetString(self.LabelContentTitle, szTextTitle)
    end

    if tRankingInfo.nType == RANK_TYPE.ARENA then
        self:SetIntroduceText(ARENA_DESC)
    elseif tRankingInfo.szDesc then
        if tRankingInfo.szMobileDesc and tRankingInfo.szMobileDesc ~= "" then
            local szTextTip = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tRankingInfo.szMobileDesc))
            self:SetIntroduceText(szTextTip)
        else
            local szTextTip = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tRankingInfo.szDesc))
            self:SetIntroduceText(szTextTip)
        end
    end

    local nStart = self.nCountOfEachPage * (self.nCurrentPageIndex - 1) + 1
    local nEnd = nStart + self.nCountOfEachPage - 1

    self.nRankInfoType = tRankingInfo.nType
    local updateFunc = RANKING_UPDATE_STRATEGY[tRankingInfo.nType]
    if updateFunc then
        updateFunc(self, tRankingInfo, nStart, nEnd) -- 更展示信息
    elseif not (tRankingInfo.nType == RANK_TYPE.ARENA or tRankingInfo.nType == RANK_TYPE.MASTER) then
        LOG.WARN("未实现的排行榜类型: " .. tostring(tRankingInfo.nType))
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFengYunLuList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFengYunLuList, self.WidgetArrow)
end

--- 更新帮会排行榜
---@param tRankingInfo table 排行榜信息
---@param nStart number 起始索引
---@param nEnd number 结束索引
function UIFengYunLuView:UpdateTongRanking(tRankingInfo, nStart, nEnd)
    local tRanking = self:GetGlobalRankingValue(tRankingInfo.szKey, nStart) or {}
    UIHelper.SetString(self.titleScript.LabelChangable, UIHelper.GBKToUTF8(tRankingInfo.szValueName))
    UIHelper.SetVisible(self.titleScript.LabelStrongholdAttridution, false)

    local initCellData = function(script, tInfo)
        UIHelper.SetString(script.LabelTongName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo[1]), TONG_NAME_LIMIT_LEN))
        UIHelper.SetString(script.LabelTongMasterName, UIHelper.GBKToUTF8(tInfo[2]))
        UIHelper.SetString(script.LabelRecruitNum, tInfo[4])
        UIHelper.SetString(script.LabelScore, tInfo[5])

        UIHelper.BindUIEvent(script.BtnList, EventType.OnClick, function()
            local tips, _ = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFengYunLuOperationPop, script.LabelRecruitNum, TipsLayoutDir.BOTTOM_RIGHT,
                    {
                        szTongName = tInfo[1],
                        bPerson = false
                    }, function()
                        UIHelper.SetSelected(script.BtnList, false)
                    end)
            tips:SetOffset(0, nil)
            tips:Update()
        end)
        UIHelper.SetVisible(script.LabelStrongholdAttridution, false)
    end

    UIHelper.SetVisible(self.WidgetEmpty, not tRanking or IsTableEmpty(tRanking))
    local fnMineCheck = function(tInfo) return tInfo[1] == TongData.GetName() end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetTongExploitsListCell01, tRanking, nStart, nEnd, initCellData, fnMineCheck)
end

--- 更新个人排行榜
---@param tRankingInfo table 排行榜信息
---@param nStart number 起始索引
---@param nEnd number 结束索引
function UIFengYunLuView:UpdatePersonRanking(tRankingInfo, nStart, nEnd)
    local tPreFix = SplitString(tRankingInfo.szDesignation, ";")
    local pHlMgr = GetHomelandMgr()
    local tRanking = self:GetGlobalRankingValue(tRankingInfo.szKey, nStart) or {}
    UIHelper.SetVisible(self.WidgetEmpty, not tRanking or IsTableEmpty(tRanking))

    local initCellData = function(script, tInfo, i)
        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tInfo[1]))
        UIHelper.SetString(script.LabelGrade, tInfo[4])
        UIHelper.SetString(script.LabelCamp, g_tStrings.STR_GUILD_CAMP_NAME[tInfo[6]])
        UIHelper.SetString(script.LabelScore, tInfo[7])
        UIHelper.SetString(script.LabelTongName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo[2]), TONG_NAME_LIMIT_LEN))
        UIHelper.SetSpriteFrame(script.ImgSchool, PlayerForceID2SchoolImg2[tInfo[5]])

        if tRankingInfo.szKey == "Rank_Role_CollectFurniture" then
            local bPHMap = pHlMgr.IsPrivateHomeMap(tInfo[9])
            local HouseAddress = GetHouseAddress(tInfo[9], tInfo[11], tInfo[12], bPHMap)
            UIHelper.SetString(script.LabelCamp, tInfo[7])
            UIHelper.SetString(script.LabelScore, HouseAddress)
        end

        self:InitDesignationRichText(script.LabelDesignation, tPreFix, i, tRankingInfo.szDesignation)

        local fnClose = function() UIHelper.SetSelected(script.BtnList, false) end
        UIHelper.BindUIEvent(script.BtnList, EventType.OnClick, function()
            if UIMgr.GetView(VIEW_ID.PanelFengYunLuRewardTitlePop) then return end
            local tips, _ = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFengYunLuOperationPop, script.LabelCamp, TipsLayoutDir.BOTTOM_RIGHT,
                    { szName = tInfo[1], bPerson = true }, fnClose)
            tips:SetOffset(0, nil)
            tips:Update()
        end)
    end

    if tRankingInfo.szKey ~= "Rank_Role_CollectFurniture" then
        UIHelper.SetString(self.titleScript.LabelChangable, UIHelper.GBKToUTF8(tRankingInfo.szValueName))
        UIHelper.SetString(self.titleScript.LabelCamp, g_tStrings.CAMP)
    else
        UIHelper.SetString(self.titleScript.LabelChangable, g_tStrings.STR_LINK_HOMENAME)
        UIHelper.SetString(self.titleScript.LabelCamp, UIHelper.GBKToUTF8(tRankingInfo.szValueName))
    end

    local fnMineCheck = function(tInfo) return tInfo[1] == g_pClientPlayer.szName end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetPersonageListCell, tRanking, nStart, nEnd, initCellData, fnMineCheck)
end

--- 更新大师赛排行榜
---@param tRankingInfo table 排行榜信息
---@param nStart number|nil 起始索引
---@param nEnd number|nil 结束索引
function UIFengYunLuView:UpdateMasterRanking(tRankingInfo, nStart, nEnd)
    local nPageIndex = nStart and math.floor(nStart / ARENA_PAGE) or self.nMasterPageStart

    local szKey = tRankingInfo.szKey
    local tRanking = self:GetMasterRankingValue(szKey, nPageIndex) or {}

    if nStart == nil or nEnd == nil then
        return
    end

    local nContainerIndex = 1
    for index, range in ipairs(tDataRange) do
        if nStart >= range.nStart and nStart <= range.nEnd then
            nContainerIndex = index
        end
    end

    for i = nStart, nEnd do
        if tRanking[i] then
            local tInfo = tRanking[i]
            self.largeContentScript:AddItemToContainer(nContainerIndex, PREFAB_ID.WidgetMingJianDaShiListCell,
                    { nRankLevel = i, tInfo = tInfo })
        end
    end
end

--- 更新江湖排行榜
---@param tRankingInfo table 排行榜信息
function UIFengYunLuView:UpdateJiangHuRanking(tRankingInfo)
    local szIdentity, szType = string.match(tRankingInfo.szKey, "([%d]+)_([%d]+)")
    local nIdentity = tonumber(szIdentity)
    local nJHType = tonumber(szType)
    self.nCustomType = nJHType
    local tRanking = self:GetCustomRankingValue(nJHType) or {}
    local tIdentity = Table_GetOneIdentityInfo(nIdentity)
    local tPreFix = nil
    if tIdentity then
        tPreFix = SplitString(tIdentity.szPreFix, ";")
    end
    local szLink = tIdentity.szPreFix

    UIHelper.SetVisible(self.WidgetEmpty, not (tRanking and #tRanking > 0))

    local tTitle = GetRankingTitle(tRankingInfo.dwID)
    if tTitle then
        UIHelper.SetString(self.titleScript.LabelChangable, UIHelper.GBKToUTF8(tTitle[3]))
    end

    local initCellData = function(script, tInfo, i)
        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tInfo.szName))
        UIHelper.SetString(script.LabelTrap, tInfo.nScore)
        UIHelper.SetString(script.LabelCamp, g_tStrings.STR_GUILD_CAMP_NAME[tInfo.nCamp])
        UIHelper.SetString(script.LabelTongName, self:GetTongDisplayName(tInfo.nTongID))

        self:InitDesignationRichText(script.LabelPrestige, tPreFix, i, szLink)
    end

    local nStart = 1
    local nEnd = tRanking and #tRanking or 0
    local fnMineCheck = function(tInfo) return tInfo.szName == g_pClientPlayer.szName end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetJiangHuListCell, tRanking, nStart, nEnd, initCellData, fnMineCheck)
end

--- 更新八荒排行榜
---@param tRankingInfo table 排行榜信息
---@param nStart number 起始索引
---@param nEnd number 结束索引
function UIFengYunLuView:UpdateBaHuangRanking(tRankingInfo, nStart, nEnd)
    local nCustomType = tonumber(tRankingInfo.szKey)
    self.nCustomType = nCustomType
    local tRanking = self:GetCustomRankingValue(nCustomType) or {}

    UIHelper.SetVisible(self.WidgetEmpty, not (tRanking and #tRanking > 0))
    local initCellData = function(script, tInfo)
        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tInfo[1]))
        UIHelper.SetString(script.LabelHurt, tInfo.nKey)
        UIHelper.SetString(script.LabelFightingNum, tInfo[3])

        local szKungFuImgPath = PlayerKungfuImg[tInfo[2]]
        if szKungFuImgPath then
            UIHelper.SetSpriteFrame(script.ImgSchool, szKungFuImgPath)
        end
    end

    local fnMineCheck = function(tInfo) return tInfo[1] == g_pClientPlayer.szName end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetBaHuangListCell, tRanking, nStart, nEnd, initCellData, fnMineCheck)
end

--- 更新试炼排行榜
---@param tRankingInfo table 排行榜信息
function UIFengYunLuView:UpdateShiLianRanking(tRankingInfo)
    local nCustomType = tonumber(tRankingInfo.szKey)
    self.nCustomType = nCustomType
    local tRanking = self:GetCustomRankingValue(nCustomType) or {}

    UIHelper.SetVisible(self.WidgetEmpty, not (tRanking and #tRanking > 0))

    local initCellData = function(script, tInfo)
        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tInfo[1]))
        UIHelper.SetString(script.LabelCheckpoint, tInfo[2])
        UIHelper.SetString(script.LabelScore, tInfo[3])
        UIHelper.SetString(script.LabelEquipmentNum, tInfo[4])
    end

    local nEnd = tRanking ~= nil and #tRanking or 0
    local fnMineCheck = function(tInfo) return tInfo[1] == g_pClientPlayer.szName end
    self:AddRankingCellWithMineCheck(PREFAB_ID.WidgetShiLianListCell, tRanking, 1, nEnd, initCellData, fnMineCheck)
end

--- 更新帮会联盟排行榜
---@param tRankingInfo table 排行榜信息
---@param nStart number 起始索引
---@param nEnd number 结束索引
function UIFengYunLuView:UpdateTongLeagueRanking(tRankingInfo, nStart, nEnd)
    local nCamp = tonumber(tRankingInfo.szKey)
    self:ApplyTongLeagueRankList(nCamp, 1, 32)
    self:ApplyTongLeagueRankList(nCamp, 33, 64)
    local initCellData = function(script, tInfo)
        local nTime        = math.min(tInfo.nLastMatchTime or 0, 2700)
        local szTime       = TimeLib.GetClockTimeText(nTime)
        local szRecord     = FormatString(g_tStrings.STR_ARENA_V_L3, tInfo.nWin, tInfo.nLose)
        local szCenterName = UIHelper.GBKToUTF8(tInfo.dwCenterID > 0 and GetCenterNameByCenterID(tInfo.dwCenterID) or "")
        UIHelper.SetString(script.LabelTongName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo.szTongName), TONG_NAME_LIMIT_LEN))
        UIHelper.SetString(script.LabelTongMasterName, UIHelper.GBKToUTF8(tInfo.szMasterName))
        UIHelper.SetString(script.LabelCamp, string.format("%s", g_tStrings.STR_GUILD_CAMP_NAME[tInfo.eCamp]))
        UIHelper.SetString(script.LabelScore, tInfo.nScore)
        UIHelper.SetString(script.LabelRecord, szRecord)
        UIHelper.SetString(script.LabelDuration, szTime)
        UIHelper.SetString(script.LabelTongServer, szCenterName)
    end

    local nCount = 0
    for i = nStart, nEnd do
        local tInfo = GetTongLeagueRankInfo(nCamp, i - 1)
        if tInfo and tInfo.dwTongID ~= 0 then
            nCount = nCount + 1
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTongMatchCell, self.ScrollViewFengYunLuList, i)
            initCellData(script, tInfo)
        end
    end
    UIHelper.SetVisible(self.ImgNotInRanking, false)
    UIHelper.SetVisible(self.WidgetEmpty, nCount == 0)
end

--- 更新1V1排行榜
---@param tRankingInfo table 排行榜信息
function UIFengYunLuView:Update1V1Ranking(tRankingInfo)
    self:UpdateArenaNvNRanking(tRankingInfo, 50, PREFAB_ID.WidgetSchool1V1Cell, true)
end

--- 更新3V3排行榜
---@param tRankingInfo table 排行榜信息
function UIFengYunLuView:Update3V3Ranking(tRankingInfo)
    self:UpdateArenaNvNRanking(tRankingInfo, 100, PREFAB_ID.WidgetSchool3V3Cell)
end

--------------------------个人、帮会排行榜信息获取相关------------------------------------

--- 获取全局排行榜数据
---@param szKey string 排行榜 key
---@param nStartIndex number 起始索引
---@return table 排行榜数据
function UIFengYunLuView:GetGlobalRankingValue(szKey, nStartIndex)
    local a = self.tGlobalRanking[szKey]
    local nVersion = self.nRankVersion or 0

    local fnStartSync = function()
        self:SetLoading(true)
        RemoteCallToServer("OnQueryGlobalRanking", szKey, nStartIndex, 1)
    end

    LOG.INFO("UIFengYunLuView:GetGlobalRankingValue %s", szKey)
    if (not a or not a.nVersion) or nVersion > a.nVersion or a.tRanking[nStartIndex] == nil then
        fnStartSync()
        return {}
    end

    return a.tRanking
end

--- 同步全局排行榜信息回调
---@param szKey string 排行榜 key
---@param tMsg table 排行榜数据
---@param nStartIndex number 起始索引
---@param nNextIndex number 下一索引
function UIFengYunLuView:OnSyncGlobalRankingInfo(szKey, tMsg, nStartIndex, nNextIndex)
    print("OnSyncGlobalRankingInfo", szKey, tMsg, nStartIndex, nNextIndex)
    self:SetLoading(false)

    if nNextIndex == 1 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GET_GLOBAL_RANKING_FAILED) --当前查询处于冷却状态
    end

    self.nNextIndex = nNextIndex
    if nNextIndex ~= 1 then
        local bIsDataEmpty = #tMsg == 0 --判断当前排行榜是否无数据

        local tGlobalKey = self.tGlobalRanking[szKey]
        if not tGlobalKey or not tGlobalKey.tRanking then
            self.tGlobalRanking[szKey] = { nVersion = 0, tRanking = {} }
            tGlobalKey = self.tGlobalRanking[szKey]
        end
        tGlobalKey.nVersion = self.nRankVersion or 0

        local tRanking = tGlobalKey.tRanking
        for nIndex, v in ipairs(tMsg) do
            tRanking[nStartIndex + nIndex - 1] = v
        end

        local nCount = #tMsg
        if self.selectedPage.szKey == szKey and not bIsDataEmpty then
            self:UpdateSelectRanking(self.selectedPage)
        end
    end
end

--------------------------江湖信息获取相关------------------------------------

local function fSortCustomRankList(tList)
    if not tList or #tList <= 0 then
        return {}
    end
    local tRanking = {}
    local nRank = 1
    repeat
        local tTempList = {}
        local tInfo = nil
        for i, v in ipairs(tList) do
            --下一个排名
            if tInfo and tInfo.nTeamDamage > v.nKey then
                break
            end
            --防止相同伤害不同的队伍出现
            if not tInfo or (tInfo and tInfo.nTeamDamage == v.nKey and tInfo.dwTeamID == v.dwTeamID) then
                tInfo = v
                tInfo.nTeamDamage = v.nKey
                tInfo.nRank = nRank
                table.insert(tRanking, tInfo)
                table.insert(tTempList, i)
            end
        end
        for nCount, index in pairs(tTempList) do
            table.remove(tList, index - nCount + 1)
        end
        nRank = nRank + 1
    until #tList <= 0
    return tRanking
end

--- 检查并排序自定义排行榜
---@param nType number 自定义排行榜类型
function UIFengYunLuView:CheckSortCustomRankList(nType)
    if nType == 281 then
        local tList = self.tGlobalCustomRanking[nType]
        self.tGlobalCustomRanking[nType] = fSortCustomRankList(tList)
    end
end

--- 获取自定义排行榜数据
---@param nType number 自定义排行榜类型
---@return table 排行榜数据
function UIFengYunLuView:GetCustomRankingValue(nType)
    if not self.bApplyAllJHRankInfo and not self.tGlobalCustomRanking[nType] then
        self:SetLoading(true)
        ApplyCustomRankList(nType)
    end

    local tRanking = self.tGlobalCustomRanking[nType] or {}
    return tRanking
end

--- 同步自定义排行榜信息回调
---@param nType number 自定义排行榜类型
function UIFengYunLuView:OnSyncCustomRankingInfo(nType)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    self.tGlobalCustomRanking[nType] = GetCustomRankList(nType)
    self.bApplyAllJHRankInfo = true
    self:CheckSortCustomRankList(nType)

    if not self.nCustomType or self.nCustomType ~= nType then
        return
    end

    self:SetLoading(false)
    self:UpdateSelectRanking(self.selectedPage)

    self.bApplyAllJHRankInfo = false
end

----------------------------帮会联盟排行榜信息获取相关------------------------------------

--- 申请帮会联盟排行榜列表
---@param nCamp number 阵营
---@param nBeginIndex number 起始索引
---@param nEndIndex number 结束索引
function UIFengYunLuView:ApplyTongLeagueRankList(nCamp, nBeginIndex, nEndIndex)
    local nCurrentTime = GetCurrentTime()
    if not self.tLastApplyTongLeague then
        self.tLastApplyTongLeague = {}
        self.tLastApplyTongLeague[CAMP.GOOD] = {}
        self.tLastApplyTongLeague[CAMP.EVIL] = {}
    end
    local nLastApply = self.tLastApplyTongLeague[nCamp][nBeginIndex] or 0
    if nCurrentTime - nLastApply < APPLY_TONG_LEAGUE_CD then
        return
    end
    --逻辑index从0开始，需要-1
    ApplyTongLeagueRankList(nCamp, nBeginIndex - 1, nEndIndex - 1)
    self.tLastApplyTongLeague[nCamp][nBeginIndex] = nCurrentTime
end

--- 同步帮会联盟排行榜列表回调
function UIFengYunLuView:OnSyncTongLeagueRankList()
    self:UpdateSelectRanking()
end

--------------------------大师赛、竞技场信息获取相关------------------------------------

--- 获取大师赛排行榜数据
---@param szKey string 排行榜 key
---@param nPageIndex number 页索引
---@param bNoCache boolean|nil 是否不使用缓存
---@return table 排行榜数据
function UIFengYunLuView:GetMasterRankingValue(szKey, nPageIndex, bNoCache)
    nPageIndex = nPageIndex or 0

    local a = self.tGlobalMasterRanking[szKey]
    local nTime = GetCurrentTime()
    local nArenaType = tArenaType[szKey]

    local GetInfo = function()
        print("UIFengYunLuView:GetMasterRankingValue", szKey, nPageIndex)
        self:SetLoading(true)
        GetArenaRankList(nArenaType, nPageIndex)
    end

    local nCDTime = 2
    local szKey = GetArenaRankKey(nArenaType)
    if not a or not a.nQueryTime then
        GetInfo()
        self.tGlobalMasterRanking[szKey] = { nQueryTime = nTime }
        return {}
    elseif not a and a.nQueryTime and CheckCD(nTime, a.nQueryTime, nCDTime) then
        GetInfo()
        a.nQueryTime = nTime
        return a.tRanking or {}
    elseif (not a.tRanking or IsTableEmpty(a.tRanking)) and CheckCD(nTime, a.nQueryTime, nCDTime) then
        -- self:OnSyncMasterRankList(nArenaType, nPageIndex)
        return {}
    end

    if a.tRanking and a.tSyncPage and not a.tSyncPage[nPageIndex] and CheckCD(nTime, a.nQueryTime, nCDTime) then
        GetInfo()
        a.nQueryTime = nTime
    end

    return a.tRanking or {}
end

--- 设置大师赛排行榜页信息
---@param nPageStart number|nil 起始页
---@param nPageEnd number|nil 结束页
---@param szKey string 排行榜 key
function UIFengYunLuView:SetMasterRankingInfo(nPageStart, nPageEnd, szKey)
    if nPageStart ~= nil and nPageEnd ~= nil then
        local nPageMax = szKey == "Arena_Master_3V3" and 49 or 29
        nPageEnd = math.min(nPageEnd, nPageMax)
        if nPageStart > nPageEnd then
            nPageStart = nil
            nPageEnd = nil
        end
    end
    self.nMasterPageStart = nPageStart
    self.nMasterPageEnd = nPageEnd
end

--- 同步大师赛排行榜列表回调
---@param nCorpsType number 竞技场类型
---@param nPageIndex number 页索引
function UIFengYunLuView:OnSyncMasterRankList(nCorpsType, nPageIndex)
    local szKey = GetArenaRankKey(nCorpsType)

    self.tGlobalMasterRanking[szKey] = self.tGlobalMasterRanking[szKey] or {}
    local tGlobalKey = self.tGlobalMasterRanking[szKey]

    tGlobalKey.tRanking = tGlobalKey.tRanking or {}
    tGlobalKey.nQueryTime = tGlobalKey.nQueryTime or GetCurrentTime()

    tGlobalKey.tSyncPage = tGlobalKey.tSyncPage or {}
    tGlobalKey.tSyncPage[nPageIndex] = true

    local nStartIndex = nPageIndex * ARENA_PAGE + 1 -- nPageIndex start from 0
    local nEndIndex = (nPageIndex + 1) * ARENA_PAGE -- nPageIndex start from 0
    for i = nStartIndex, nEndIndex do
        local tInfo = GetArenaCorpsInfo(nCorpsType, i - 1)
        tGlobalKey.tRanking[i] = nil
        if tInfo and tInfo.dwCorpsID ~= 0 then
            tGlobalKey.tRanking[i] = tInfo
        end
    end

    self:UpdateMasterRanking(self.selectedPage, nStartIndex, nEndIndex)

    if self.nMasterPageEnd and nPageIndex < self.nMasterPageEnd then
        GetArenaRankList(nCorpsType, nPageIndex + 1)
    else
        local nContainerIndex = 1
        for nIndex, tRange in ipairs(tDataRange) do
            if tRange.nEnd == nEndIndex then
                nContainerIndex = nIndex
            end
        end
        self.largeContentScript:UpdateInfo()
        self:SetMasterRankingInfo(nil, nil, nil)

        Timer.AddFrame(self, 2, function()
            UIHelper.CascadeDoLayoutDoWidget(self.largeContentScript._rootNode, true, true)
            self.largeContentScript:SetContainerSelected(nContainerIndex, true, true)
            self:SetLoading(false)
        end)
    end
end

--------------------------通用接口------------------------------------

function UIFengYunLuView:SetLoading(bState)
    if self.nLoadingTimerID then
        Timer.DelTimer(self, self.nLoadingTimerID)
    end

    UIHelper.SetVisible(self.WidgetLoading, bState)

    if bState then
        self.nLoadingTimerID = Timer.Add(self, 2, function()
            UIHelper.SetVisible(self.WidgetLoading, false) ---数据获取不到时，两秒内结束加载状态
        end)
    end
end

--- 配置列表布局：自身排名、分页、尺寸、箭头定位
function UIFengYunLuView:SetupListLayout(bSelfRanking, bUsePaginate)
    UIHelper.SetVisible(self.ScrollViewList_Large, not bSelfRanking)
    UIHelper.SetVisible(self.ScrollViewList_Short, bSelfRanking)
    UIHelper.SetVisible(self.WidgetMine, bSelfRanking)
    UIHelper.SetVisible(self.WidgetPaginate, bUsePaginate)

    local nYOffset = not bUsePaginate and self.nPageOriginalHeight or 0
    UIHelper.SetContentSize(self.ScrollViewList_Short, self.nShortOriginalWidth, self.nShortOriginalHeight + nYOffset)
    UIHelper.SetPositionY(self.WidgetMine, self.nMineOriginY - nYOffset)

    self.ScrollViewFengYunLuList = bSelfRanking and self.ScrollViewList_Short or self.ScrollViewList_Large

    -- 箭头定位到 ScrollView 底部
    local nPosY = UIHelper.GetPositionY(self.ScrollViewFengYunLuList)
    local nHeight = UIHelper.GetHeight(self.ScrollViewFengYunLuList)
    local _, nAnchPosY = UIHelper.GetAnchorPoint(self.ScrollViewFengYunLuList)
    UIHelper.SetPositionY(self.WidgetArrow, nPosY - nHeight * nAnchPosY)
end

function UIFengYunLuView:SwitchContainer(nFengYunLu, nType)
    if self.largeContentScript == nil then
        local compLuaBind = self.WidgetContent_Navigation:getComponent("LuaBind")
        self.largeContentScript = compLuaBind and compLuaBind:getScriptObject() ---@type UIWidgetScrollViewTree
    end

    UIHelper.SetVisible(self.WidgetMine, false)
    UIHelper.SetVisible(self.WidgetPaginate, false)

    if nFengYunLu ~= FengYunLuType.Normal and nFengYunLu ~= FengYunLuType.Military and nFengYunLu ~= FengYunLuType.JueJing then
        return
    end

    local bShowTree = nType == RANK_TYPE.MASTER or nType == RANK_TYPE.ARENA
    if bShowTree then
        UIHelper.SetVisible(self.WidgetContent_Navigation, true)
        UIHelper.SetVisible(self.ScrollViewList_Large, false)
        UIHelper.SetVisible(self.ScrollViewList_Short, false)
        UIHelper.SetVisible(self.WidgetArrow, false)
    else
        UIHelper.SetVisible(self.WidgetContent_Navigation, false)
        UIHelper.SetVisible(self.WidgetArrow, true)

        local bSelfRanking = nFengYunLu == FengYunLuType.Military or nFengYunLu == FengYunLuType.JueJing or table.contain_value(nRankTypeShowSelfRanking, nType)
        local bUsePaginate = nFengYunLu == FengYunLuType.JueJing or table.contain_value(nRankTypeShowPaginate, nType)
        self:SetupListLayout(bSelfRanking, bUsePaginate)
    end
end

function UIFengYunLuView:SetIntroduceText(szText)
    local szIntroduceColor = "#d7f6ff"
    UIHelper.SetRichText(self.RichTextIntroduce, string.format("<color=%s>%s</c>", szIntroduceColor, szText))
end

function UIFengYunLuView:SetInfoNodeVisible(bTimeTip, bDesc, bHelpToggle)
    UIHelper.SetVisible(self.LabelFriendUpdateTime, bTimeTip)
    UIHelper.SetVisible(self.LabelFriendUpdateDesc, bDesc)
    UIHelper.SetVisible(self.TogHelp, bHelpToggle)
end

function UIFengYunLuView:SetPageIndexInfo(nCurrentPageIndex, nStartPage, nEndPage, nCountOfEachPage)
    self.nCurrentPageIndex = nCurrentPageIndex
    self.nStartPage = nStartPage
    self.nEndPage = nEndPage
    self.nCountOfEachPage = nCountOfEachPage

    UIHelper.SetString(self.LabelMaxPage, "/" .. nEndPage)
end

function UIFengYunLuView:UpdateCurrentPage(nVal)
    nVal = math.max(nVal, self.nStartPage)
    nVal = math.min(nVal, self.nEndPage)

    if nVal ~= self.nCurrentPageIndex then
        self.nCurrentPageIndex = nVal
        if self.nMainRankType == FengYunLuType.Normal then
            self:UpdateSelectRanking()
        end

        if self.nMainRankType == FengYunLuType.JueJing then
            local nStartIndex = (nVal - 1) * self.nCountOfEachPage + 1
            self:UpdateJueJingRankList(self.nJueJingRankType, nStartIndex, nStartIndex + self.nCountOfEachPage - 1)
        end
    end

    self:RefreshPaginate()
end

function UIFengYunLuView:RefreshPaginate(bShowNext)
    UIHelper.SetString(self.EditPaginate, self.nCurrentPageIndex)
    --UIHelper.SetVisible(self.BtnLeft, self.nCurrentPageIndex > 1)
    --UIHelper.SetVisible(self.BtnRight, bShowNext ~= false and (self.nCurrentPageIndex < self.nEndPage))
end

--- 创建排行榜 cell 循环，自动检查并创建"我的排名" cell
--- 消除 28 处重复的 "for → AddPrefab → initCellData → if mine → AddPrefab mine" 模式
---@param nPrefabID number Prefab ID
---@param tRanking table 排行榜数据数组
---@param nStart number 起始索引
---@param nEnd number 结束索引
---@param fnInitCell fun(script, tInfo, i) cell 初始化回调
---@param fnMineCheck fun(tInfo): boolean 判断是否为自己记录的回调
---@return table 更新后的 cellScripts
function UIFengYunLuView:AddRankingCellWithMineCheck(nPrefabID, tRanking, nStart, nEnd, fnInitCell, fnMineCheck)
    local cellScripts = self.cellScripts or {}
    for i = nStart, nEnd do
        local tInfo = tRanking[i]
        if not tInfo then
            break
        end

        local script = cellScripts[i]
        if not script then
            script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewFengYunLuList, i)
            cellScripts[i] = script
        end
        fnInitCell(script, tInfo, i)

        if fnMineCheck(tInfo) then
            local mineScript = UIHelper.AddPrefab(nPrefabID, self.WidgetMineParent, i)
            UIHelper.SetVisible(self.ImgNotInRanking, false)
            fnInitCell(mineScript, tInfo, i)
        end
    end
end

--- 称号/Designation 富文本初始化
--- 消除 4 处重复的称号前缀查询 + 品质颜色 + href 格式化
---@param script table cell script
---@param szLabelName string 富文本 Label 名称（如 "LabelDesignation" 或 "LabelPrestige"）
---@param tPreFix table 称号前缀 ID 数组
---@param i number 当前索引
---@param szLink string href 链接内容
---@param dwForceID number|nil 门派 ID（1V1/3V3 使用）
function UIFengYunLuView:InitDesignationRichText(tLabel, tPreFix, i, szLink, dwForceID)
    local aDesignation
    if tPreFix[i] then
        if dwForceID then
            aDesignation = Table_GetDesignationPrefixByID(tPreFix[i], dwForceID)
        else
            aDesignation = Table_GetDesignationPrefixByID(tPreFix[i])
        end
    end

    local szDesignation = ""
    if aDesignation then
        szDesignation = UIHelper.GBKToUTF8(aDesignation.szName)
        local r, g, b = GetItemFontColorByQuality(aDesignation.nQuality, false)
        szDesignation = GetFormatText(szDesignation, nil, r, g, b)

        if dwForceID then
            szDesignation = string.format("<href=%s-%d>%s</href>", szLink, dwForceID, szDesignation)
        else
            szDesignation = string.format("<href=%s>%s</href>", szLink, szDesignation)
        end
    end
    UIHelper.SetRichText(tLabel, szDesignation)
end

--- 格式化帮会名称（含长度限制）
---@param nTongID number 帮会 ID
---@return string 格式化后的帮会名称
function UIFengYunLuView:GetTongDisplayName(nTongID)
    local szTongName = "--"
    if nTongID and nTongID ~= 0 then
        szTongName = TongData.GetName(nTongID, 4) or ""
    end
    return UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szTongName), TONG_NAME_LIMIT_LEN)
end

--- 格式化胜负战绩
---@param nWin number 胜场数
---@param nTotal number 总场数
---@return string "W-L" 格式字符串
function UIFengYunLuView:FormatWinLose(nWin, nTotal)
    return string.format("%d-%d", nWin, nTotal - nWin)
end

--- 统一的竞技场 NvN 排名更新（合并原 1V1 和 3V3 两个 95% 相同的函数）
---@param tRankingInfo table 排行榜信息
---@param nEnd number 结束排名
---@param nPrefabID number Cell Prefab ID
---@param bUseHDTransform boolean|nil 是否对功夫 ID 做 HD 转换（1V1 使用）
function UIFengYunLuView:UpdateArenaNvNRanking(tRankingInfo, nEnd, nPrefabID, bUseHDTransform)
    local tPreFix = SplitString(tRankingInfo.szDesignation, ";")
    local dwForceID
    local tRanking = {}
    local szCustomType, szKungfuID = string.match(tRankingInfo.szKey, "([%d]+)_([%d]+)")
    if szCustomType and szKungfuID then
        self.nCustomType = tonumber(szCustomType)
        local nKungfuID = tonumber(szKungfuID)
        if bUseHDTransform then
            nKungfuID = TabHelper.GetHDKungfuID(nKungfuID)
        end
        dwForceID = Kungfu_GetType(nKungfuID) or 0
        tRanking = self:GetCustomRankingValue(self.nCustomType) or {}
    end

    UIHelper.SetVisible(self.WidgetEmpty, not (tRanking and #tRanking > 0))

    local initCellData = function(script, tInfo, i)
        local szUTF8Name = UIHelper.GBKToUTF8(tInfo.szName)
        local szUTF8TongName = UIHelper.GBKToUTF8(tInfo.szTongName)

        UIHelper.SetString(script.LabelPlayerName, UIHelper.LimitUtf8Len(szUTF8Name, 7))
        UIHelper.SetString(script.LabelCheckpoint, tInfo.dwMaxLevel)
        UIHelper.SetString(script.LabelScore, tInfo.nKey)
        UIHelper.SetString(script.LabelCamp, g_tStrings.STR_GUILD_CAMP_NAME[tInfo.nCamp])
        UIHelper.SetString(script.LabelTong, UIHelper.LimitUtf8Len(szUTF8TongName, 7))
        UIHelper.SetString(script.LabelTotal, tInfo.nTotalCount)
        UIHelper.SetString(script.LabelWinLose, self:FormatWinLose(tInfo.nWinCount, tInfo.nTotalCount))

        self:InitDesignationRichText(script.LabelDesignation, tPreFix, i, tRankingInfo.szDesignation, dwForceID)
    end

    local fnMineCheck = function(tInfo)
        return tInfo.szName == g_pClientPlayer.szName
    end

    self:AddRankingCellWithMineCheck(nPrefabID, tRanking, 1, nEnd, initCellData, fnMineCheck)
end

return UIFengYunLuView
