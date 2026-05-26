-- ---------------------------------------------------------------------------------
-- Desc: 武林争霸赛 入口npc闻千瞬
-- Prefab: PanelFactionChampionship
-- ---------------------------------------------------------------------------------

local UIFactionChampionship = class("UIFactionChampionship")


local SIGN_UP_ACTIVITY_ID = 647
local TITLE = {
    FORMAL = 1,
    PRATICE = 2
}

local RANK_REWARD = {
    [1] = {dwTabType = 5, dwIndex = 24449},
    [2] = {dwTabType = 5, dwIndex = 24449},
    [3] = {dwTabType = 5, dwIndex = 24449},
}

local REWARD_HINT_COLOR = {
    [1] = {r = 112, g = 255, b = 187, a = 255},
    [2] = {r = 215, g = 246, b = 255, a = 153},
}

local RANK_DETAIL = {
    [CAMP.EVIL] = 472,
    [CAMP.GOOD] = 471,
    [CAMP.NEUTRAL] = 471,
}

local TONG_LEAGUE_RESULTIMAGEFRAME_STAGE = {
    [BF_TONG_LEAGUE_STAGE.BASE] = "UIAtlas2_Faction_FactionChampionship_Jifensai",
    [BF_TONG_LEAGUE_STAGE.SEMIFINALS] = "UIAtlas2_Faction_FactionChampionship_4",
    [BF_TONG_LEAGUE_STAGE.TOP8] = "UIAtlas2_Faction_FactionChampionship_8",
    [BF_TONG_LEAGUE_STAGE.TOP16] = "UIAtlas2_Faction_FactionChampionship_16",
    [BF_TONG_LEAGUE_STAGE.TOP32] = "UIAtlas2_Faction_FactionChampionship_32",
    [BF_TONG_LEAGUE_STAGE.TOP64] = "UIAtlas2_Faction_FactionChampionship_64",
    [BF_TONG_LEAGUE_STAGE.THIRD_PLACE] = "UIAtlas2_Faction_FactionChampionship_Jijun",
    [BF_TONG_LEAGUE_STAGE.FINALS] = "UIAtlas2_Faction_FactionChampionship_Juesai"
}

local TONG_LEAGUE_RESULTITITLE_STAGE = {
    [BF_TONG_LEAGUE_STAGE.BASE] = "海选",
    [BF_TONG_LEAGUE_STAGE.SEMIFINALS] = "4强",
    [BF_TONG_LEAGUE_STAGE.TOP8] = "8强",
    [BF_TONG_LEAGUE_STAGE.TOP16] = "16强",
    [BF_TONG_LEAGUE_STAGE.TOP32] = "32强",
    [BF_TONG_LEAGUE_STAGE.TOP64] = "64强",
}

local MATCH_STAGET_END = {
    [1] = "UIAtlas2_Faction_GuildLeagueMatches5_1",
    [2] = "UIAtlas2_Faction_GuildLeagueMatches5_2",
    [3] = "UIAtlas2_Faction_GuildLeagueMatches5_3",
    [8] = "UIAtlas2_Faction_GuildLeagueMatches6_8",
    [64] = "UIAtlas2_Faction_GuildLeagueMatches6_64",
    [0] = "UIAtlas2_Faction_GuildLeagueMatches6_100",
}

local TONG_LEAGUE_MATCHES_AWARDS =
{
    {nItemType = 5, nItemID = 85497, nNum = 200},
    {nItemType = 5, nItemID = 78294, nNum = 200},
    {nItemType = 5, nItemID = 38079, nNum = 1},
    {nItemType = 5, nItemID = 85496, nNum = 300},
}


local SIGN_UP_CD = 3
local KEY_TONGBATTLEFIELD_AGREE_CHECK = "KEY_TONGBATTLEFIELD_AGREE_CHECK"
-- ---------------------------------------------------------------------------------
-- DataModel
-- ---------------------------------------------------------------------------------
local DataModel = {}

function DataModel.Init(dwTongWarNpc)
    DataModel.dwTongWarNpc = dwTongWarNpc
    DataModel.bSignUpOpen = ActivityData.IsActivityOn(SIGN_UP_ACTIVITY_ID)
    DataModel.tAwardsInfo = {}
    local nRetCode = ApplyBFTongLeagueJoinInfo()
    DataModel.CheckErrorCodeTips(nRetCode)
end

-- 界面请求数据有CD，不能反初始化
function DataModel.UnInit()
    DataModel.dwTongWarNpc = nil
    DataModel.bSignUpOpen = nil
    DataModel.tTongLeagueJoinInfo = nil
    DataModel.tAwardsInfo = nil
end

-- 是否已报名
-- bBaseSignUp 只有海选赛需要手动报名的时候会为 true，晋级赛总是为 false
-- bBaseSign 为 false 不一定表示没报名，也可能是生成对战表后重置了数据
function DataModel.IsSignUp()
    local bSignUp = false
    local tInfo = DataModel.tTongLeagueJoinInfo
    if tInfo.bBaseSignUp or (not tInfo.bBaseSignUp and tInfo.nOfficialStartTime ~= 0) then
        bSignUp = true
    end
    return bSignUp
end

function DataModel.IsInSignUpTime()
    local nStartTime, nEndTime = DataModel.GetSignUpTime()
    local nCurrentTime = GetGSCurrentTime()
    return nCurrentTime >= nStartTime and nCurrentTime < nEndTime
end

-- 是否比赛中
function DataModel.IsRaceGoing()
    local bRaceGoing = false
    local nNextFightTime = DataModel.tTongLeagueJoinInfo.nOfficialStartTime
    if nNextFightTime ~= 0 then
        local nCurrentTime = GetGSCurrentTime()
        bRaceGoing = nCurrentTime >= nNextFightTime
    end
    return bRaceGoing
end

function DataModel.GetSignUpTimeText()
    local nStartTime, nEndTime = DataModel.GetSignUpTime()
    local szStartTime, szEndTime, szTextTime
    if nStartTime > 0 then
        szStartTime = TimeLib.GetDateTextMonthToMinute(nStartTime)
        szEndTime = string.format(os.date("%H:%M", nEndTime))
    end
    if szStartTime and szEndTime then
        -- szTextTime = g_tStrings.STR_TONGBATTLEFIELD_SIGNUP_TIME .. szStartTime .. " - " .. szEndTime
        szTextTime = szStartTime .. " - " .. szEndTime
    end
    return szTextTime or ""
end

function DataModel.GetSignUpTime()
    local nEndTime = DataModel.tTongLeagueJoinInfo.nBaseSignUpEndTime
    local nStartTime = nEndTime - 5 * 60 -- 报名时间5分钟
    return math.max(0, nStartTime), nEndTime
end

function DataModel.CheckErrorCodeTips(nResultCode)
    if nResultCode ~= BF_TONG_LEAGUE_ERROR_CODE.SUCCESS then
        DataModel.OnTongLeagueErrorCodeTips(nResultCode)
    end
end

function DataModel.OnTongLeagueErrorCodeTips(nResultCode)
    local szMessage = g_tStrings.STR_ONTONGLEAGUEERRORCODE_TIP[nResultCode]
    if szMessage then
        TipsHelper.ShowNormalTip(szMessage)
    end
end

function DataModel.GetTongRank(nCamp, dwCenterID, szTongName)
    if nCamp == CAMP.NEUTRAL then
        return
    end

    for i = 0, 63 do
        local tRankInfo = GetTongLeagueRankInfo(nCamp, i)
        if tRankInfo and tRankInfo.dwCenterID == dwCenterID and tRankInfo.szTongName == szTongName then
            return i + 1
        end
    end
end

function DataModel.IsRankRace()
    local hTongClient = GetTongClient()
    if not hTongClient then
        return
    end

    local dwTongID = hTongClient.dwTongID
    local nCamp    = hTongClient.nCamp
    local dwCenterID = GetCenterID() or 0
    local tRankInfo  = dwTongID ~= 0 and GetTongLeagueRank(nCamp, dwCenterID, dwTongID) or nil
    if not tRankInfo then
        return
    end
    return tRankInfo.nRank <= 64
end
-- ---------------------------------------------------------------------------------
-- VIEW
-- ---------------------------------------------------------------------------------

function UIFactionChampionship:_LuaBindList()
    self.TogFormalMatching              = self.TogFormalMatching --- 正赛的toggle
    self.TogPraticeMatching             = self.TogPraticeMatching --- 推荐赛的toggle
    self.ToggleGroupTab                 = self.ToggleGroupTab --- toggle group
    self.WidgetLayoutRight              = self.WidgetLayoutRight --- 右侧父组件

    self.WidgetAnchorMap                = self.WidgetAnchorMap -- 地图
    self.WidgetAnchorBefore             = self.WidgetAnchorBefore -- 未开赛的文本 唯一显示
    self.WidgetActivityAwardBefore      = self.WidgetActivityAwardBefore -- 未开赛奖励

    self.WidgetAnchorMid                = self.WidgetAnchorMid --- 帮会信息的顶层组件 练习赛隐藏
    self.WidgetMatchStageEnd            = self.WidgetMatchStageEnd -- 比赛结果 顶层
    self.LabelMatchStage                = self.LabelMatchStage -- 比赛结果 积分赛 十六强
    self.ImgMatchStageEnd               = self.ImgMatchStageEnd -- 比赛结果 图片

    self.ImgLeagueStageTitle            = self.ImgLeagueStageTitle --比赛状态文字上层组件
    self.LabelMatchStageTitle           = self.LabelMatchStageTitle --比赛状态文字
    self.ImgLeagueStage                 = self.ImgLeagueStage --比赛状态
    self.LabelFactionName               = self.LabelFactionName --- 帮会名字
    self.WidgetScore                    = self.WidgetScore -- 胜负次数顶层组件
    self.LabelWinScore                  = self.LabelWinScore --- 胜利场数
    self.LabelDefeatScore               = self.LabelDefeatScore --- 失败场数
    self.LabelFactionOwner              = self.LabelFactionOwner --- 帮主名字

    self.WidgetAnchorBtn                = self.WidgetAnchorBtn -- btn父节点
    self.BtnRule                        = self.BtnRule --- 规则btn
    self.BtnGuess                       = self.BtnGuess --- 竞猜btn 练习赛隐藏
    self.WidgetAnchorPraticeText        = self.WidgetAnchorPraticeText --- 练习赛text
    self.LayoutMatchingTime             = self.LayoutMatchingTime --- 时间Layout
    self.LabelMatchingTime              = self.LabelMatchingTime --- 比赛时间 or 已匹配
    self.LabelTimeNum                   = self.LabelTimeNum --- 时间
    self.LayoutNextMatch                = self.LayoutNextMatch -- 下一场比赛组件
    self.LabelNextMatchTime             = self.LabelNextMatchTime -- 下一场比赛时间
    self.BtnMatching                    = self.BtnMatching --- 匹配中btn
    self.LabelMatching                  = self.LabelMatching --- 匹配中label
    self.ImgMatching                    = self.ImgMatching --- 匹配中btn img
    self.LabelApplyAndEnter             = self.LabelApplyAndEnter ---报名label
    self.BtnApplyAndEnter               = self.BtnApplyAndEnter --- 报名btn
    self.ImgApplyAndEnter               = self.ImgApplyAndEnter --- 报名img

    self.BtnTeach                       = self.BtnTeach --- ？btn
    self.BtnClose                       = self.BtnClose
    self.WIdgetRightTop                 = self.WIdgetRightTop --- 右上角加载money

    self.TogConsent                     = self.TogConsent --- 同意报名的toggle
    self.BtnAgreement01                 = self.BtnAgreement01 --- 规范按钮
end

function UIFactionChampionship:OnEnter(dwTongWarNpc)
    self.m          = {}
    self.m.bShow    = false -- 官方比赛是否开始
    self.m.bIsGoing = true -- 个人比赛是否进行
    self.m.bBtnApplyLogicEnabled = true
    self.m.szBtnApplyDisableTip  = nil
    self.m.bBtnMatchLogicEnabled = true
    self.m.szBtnMatchDisableTip  = nil

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init(dwTongWarNpc)
    self.dwMapID = 689
    TongData.RequestBaseData()
    ApplyTongLeagueRankList(CAMP.GOOD, 0, 31)
    ApplyTongLeagueRankList(CAMP.GOOD, 32, 63)
    ApplyTongLeagueRankList(CAMP.EVIL, 0, 31)
    ApplyTongLeagueRankList(CAMP.EVIL, 32, 63)
    RemoteCallToServer("On_Tong_RankRewardCheckList")
    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID        = PakDownloadMgr.GetMapResPackID(self.dwMapID)
    scriptDownload:OnInitWithPackID(nPackID)

    self:InitView()
end

function UIFactionChampionship:OnExit()
    DataModel.UnInit()
    self.bInit = false
    self:UnRegEvent()
    self.m = nil
end

function UIFactionChampionship:BindUIEvent()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, self.TogFormalMatching)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, self.TogPraticeMatching)
    UIHelper.BindUIEvent(self.TogFormalMatching, EventType.OnClick, function()
        self.m.nSelTitle = TITLE.FORMAL
        self:UpdateView()
    end)

    UIHelper.BindUIEvent(self.TogPraticeMatching, EventType.OnClick, function()
        self.m.nSelTitle = TITLE.PRATICE
        self:UpdateView()
    end)

    UIHelper.SetSelected(self.TogFormalMatching, true)
    UIHelper.SetSelected(self.TogPraticeMatching, false)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        if Platform.IsWindows() or Platform.IsMac() then
            UIHelper.OpenWeb("https://jx3.xoyo.com/index/#/article-details?catid=2466&id=7212")
        else
            UIHelper.OpenWeb("https://jx3.xoyo.com/mobile/index/index.html#/article-details?catid=2466&id=7212", false, true) --这里是H5，如果有再换把
        end
    end)

    UIHelper.BindUIEvent(self.BtnGuess, EventType.OnClick, function()
        BattleFieldData.OpenTongWarGuessing()
    end)

    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.GuildLeague, nil, self.BtnRank.nDetail)
    end)

    UIHelper.BindUIEvent(self.BtnAddFaction, EventType.OnClick, function()
        TongData.OpenTongPanel()
    end)

    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(25, 1561)
    end)

    UIHelper.BindUIEvent(self.BtnAgreement01, EventType.OnClick, function()
        WebUrl.OpenByID(25)
    end)

    UIHelper.BindUIEvent(self.TogConsent, EventType.OnClick, function(_tog, bSelected)
        self:SetAgreeMathRule()
        self:UpdateButtonState()
    end)
end

function UIFactionChampionship:RegEvent()
    Event.Reg(self, "ON_SIGN_UP_BF_TONG_LEAGUE", function(nResultCode, byType)
        if nResultCode == BF_TONG_LEAGUE_ERROR_CODE.SUCCESS then
            local nRetCode = ApplyBFTongLeagueJoinInfo() -- 报名成功刷新界面
            -- DataModel.CheckErrorCodeTips(nRetCode)
        else
            if nResultCode == BF_TONG_LEAGUE_ERROR_CODE.MATCH_TIME_OUT then
                local nRetCode = ApplyBFTongLeagueJoinInfo()
                -- DataModel.CheckErrorCodeTips(nRetCode)
            end
            DataModel.OnTongLeagueErrorCodeTips(nResultCode)
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_APPLY_BF_TONG_LEAGUE_JOIN_INFO", function(nResultCode)
        if nResultCode == BF_TONG_LEAGUE_ERROR_CODE.SUCCESS then
            DataModel.tTongLeagueJoinInfo = GetTongClient().GetTongLeagueJoinInfo()
        else
            DataModel.OnTongLeagueErrorCodeTips(nResultCode)
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_APPLY_BF_TONG_ONLINE_MEMBER_COUNT", function(nOnlineCount, nResultCode)
        if nResultCode == BF_TONG_LEAGUE_ERROR_CODE.SUCCESS then
            if DataModel.nSignUpType == BF_TONG_LEAGUE_SIGNUP_OPERATION.PRACTICE then
                local nRetCode = SignUpBFTongLeague(BF_TONG_LEAGUE_SIGNUP_OPERATION.PRACTICE)
                DataModel.CheckErrorCodeTips(nRetCode)
            elseif DataModel.nSignUpType == BF_TONG_LEAGUE_SIGNUP_OPERATION.OFFICIAL then
                self:ShowSignUpConfirm(nOnlineCount)
            end
            DataModel.nSignUpType = nil
        else
            DataModel.OnTongLeagueErrorCodeTips(nResultCode)
        end
    end)

    Event.Reg(self, "SYNC_TONG_LEAGUE_RANK_LIST", function ()
        self:UpdateTopRank()
        self:UpdateCompetitor()
    end)

    Event.Reg(self, "UpdateTongRankReward", function(nState1, nState2, nState3)
        DataModel.tRewardState = {nState1, nState2, nState3}
        self:UpdateRankReward()
    end)

    Event.Reg(self, "ON_CANCEL_BF_TONG_LEAGUE_SIGN_UP", function(nResultCode)
        if nResultCode == BF_TONG_LEAGUE_ERROR_CODE.SUCCESS then
            -- 取消报名成功刷新界面
            TipsHelper.ShowNormalTip(g_tStrings.STR_TONGBATTLEFIELD_CANCEL_SUCCESS)
            local nRetCode = ApplyBFTongLeagueJoinInfo()
            -- DataModel.CheckErrorCodeTips(nRetCode)
        else
            DataModel.OnTongLeagueErrorCodeTips(nResultCode)
        end
    end)
end

function UIFactionChampionship:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionChampionship:InitView()
    self.m.nSelTitle = TITLE.FORMAL
    self:UpdataAwardsStatic()
    self:UpdataAwardsStaticOfMiddle()
    self:UpdateView()

    Timer.AddFrame(self, 3, function()
        if DataModel.dwTongWarNpc then
            local hNpc = GetNpc(DataModel.dwTongWarNpc)
            if not hNpc or not hNpc.CanDialog(g_pClientPlayer) then
                UIMgr.Close(self)
            end
        end
    end)

    UIHelper.SetString(self.LabelMatching, "开始匹配对手")

    UIHelper.RemoveAllChildren(self.WIdgetRightTop)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WIdgetRightTop, CurrencyType.TongLeaguePoint)

    UIHelper.LayoutDoLayout(self.WIdgetRightTop)
end

function UIFactionChampionship:UpdateView() -- 正赛与练习赛的切换
    if self.m.nSelTitle == TITLE.FORMAL then
        UIHelper.SetVisible(self.WidgetAnchorPraticeText, false)
        UIHelper.SetVisible(self.BtnMatching, false)
        UIHelper.SetVisible(self.WidgetAnchorMid, true)
        UIHelper.SetVisible(self.BtnGuess, WebUrl.CanShow(WEBURL_ID.TONG_WAR_GUESSING))
        UIHelper.SetVisible(self.WidgetCampRank, true)
        --UIHelper.SetVisible(self.WidgetFactionRankAward, true)
        UIHelper.SetVisible(self.WidgetAnchorMap, false)
        UIHelper.SetVisible(self.WidgetNextOpponent, true)
        self:ShowAllDetail(true)
    else
        UIHelper.SetVisible(self.WidgetAnchorMid, false)
        UIHelper.SetVisible(self.WidgetAnchorMap, true)
        UIHelper.SetVisible(self.BtnGuess, false)
        UIHelper.SetVisible(self.WidgetAnchorPraticeText, true)
        UIHelper.SetVisible(self.LayoutMatchingTime, false)
        UIHelper.SetVisible(self.BtnApplyAndEnter, false)
        UIHelper.SetVisible(self.BtnMatching, true)
        UIHelper.SetVisible(self.WidgetAnchorBefore, false)
        UIHelper.SetVisible(self.LayoutNextMatch, false)
        UIHelper.SetVisible(self.WidgetNextOpponent, false)
        UIHelper.SetVisible(self.WidgetCampRank, false)
        UIHelper.SetVisible(self.WidgetFactionRankAward, false)
        UIHelper.SetVisible(self.WidgetAnchorBefore, false)
        UIHelper.LayoutDoLayout(self.WidgetAnchorBtn)
        UIHelper.LayoutDoLayout(self.WidgetLayoutRight)
    end
    self:UpdateInfo()
end

function UIFactionChampionship:ShowAllDetail(bShow) -- 是否开赛展示信息
    UIHelper.SetVisible(self.WidgetAnchorMid, bShow)
    -- UIHelper.SetVisible(self.ImgMessageBgMid, bShow)
    -- UIHelper.SetVisible(self.WidgetFactionInfoMid, bShow)
    -- UIHelper.SetVisible(self.WidgetAnchorMap, bShow and self.m.bIsGoing)
    -- UIHelper.SetVisible(self.BtnGuess, bShow)
    UIHelper.SetVisible(self.BtnRule, bShow)
    UIHelper.SetVisible(self.LayoutMatchingTime, bShow and self.m.bIsGoing and self.m.bShow)
    UIHelper.SetVisible(self.BtnApplyAndEnter, bShow and self.m.bIsGoing and self.m.bShow)
    UIHelper.SetVisible(self.WidgetAnchorBefore, not self.m.bShow)
    UIHelper.SetVisible(self.LayoutNextMatch, false)
    UIHelper.LayoutDoLayout(self.WidgetAnchorBtn)
    UIHelper.LayoutDoLayout(self.WidgetLayoutRight)
end

function UIFactionChampionship:ControlResultItemVisible(bFinished)
    UIHelper.SetVisible(self.WidgetScore, not bFinished)
    -- UIHelper.SetVisible(self.WidgetAnchorMap, not bFinished)
    UIHelper.SetVisible(self.LayoutMatchingTime, not bFinished)
    UIHelper.SetVisible(self.BtnApplyAndEnter, not bFinished)
end

function UIFactionChampionship:UpdateInfo()
    if DataModel.tTongLeagueJoinInfo then
        if self.m.nSelTitle == TITLE.FORMAL then
            self:UpdateOfficialStatic()
        else
            self:UpdataPracticeStatic()
        end
    else
        self:CanNotJoin(false)
    end
    self:UpdateBaseInfo()
    self:UpdateNotice()
    self:UpdateCompetitor()
    self:UpdateTopRank()
    self:UpdateRankReward()
    self:UpdateAwardList()

    self:UpdateButtonState()
    self:UpdateAgreeMathRule()
end

-- nNowStage：当前状态，会被修改。
-- nOfficialStage：比赛截止状态，没有加入名单的帮会该值会落后，即nNowStage > nOfficialStage，表示被淘汰。

function UIFactionChampionship:UpdateOfficialStatic()
    local tInfo = DataModel.tTongLeagueJoinInfo
    local nOfficialStage    = tInfo.nOfficialStage
    local nNowStage         = tInfo.nNowStage
    local bFinished         = false

    -- test
    -- nOfficialStage    = BF_TONG_LEAGUE_STAGE.BASE
    -- nNowStage         = BF_TONG_LEAGUE_STAGE.BASE


    if nOfficialStage == BF_TONG_LEAGUE_STAGE.INVALID and not DataModel.bSignUpOpen then --未开赛
        self.m.bShow = false
        self:ShowAllDetail(true)
        return
    else
        self.m.bShow = true
        self:ShowAllDetail(true)
        if nOfficialStage == BF_TONG_LEAGUE_STAGE.BASE or nOfficialStage == BF_TONG_LEAGUE_STAGE.BASE_EXT or DataModel.bSignUpOpen then -- 积分赛
            if nNowStage == BF_TONG_LEAGUE_STAGE.BASE or nNowStage == BF_TONG_LEAGUE_STAGE.BASE_EXT then -- 报名阶段和比赛中
                bFinished = false
            else -- 积分赛被淘汰
                bFinished = true
            end
        else -- 四强结束后会出现 12/13 的状态，单独处理
            if nNowStage == BF_TONG_LEAGUE_STAGE.THIRD_PLACE and nOfficialStage == BF_TONG_LEAGUE_STAGE.FINALS then
                bFinished = false
                nNowStage = BF_TONG_LEAGUE_STAGE.FINALS
                nOfficialStage = BF_TONG_LEAGUE_STAGE.THIRD_PLACE
            elseif nOfficialStage == nNowStage then
                bFinished = false
            else
                bFinished = true
            end
        end
    end

    self.m.bIsGoing = not bFinished
    self:ControlResultItemVisible(bFinished)
    if bFinished then
        self:ShowRaceResult(nOfficialStage)
    else
        self:UpdataOfficiaDetail(nNowStage)
    end
end

function UIFactionChampionship:ShowRaceResult(nOfficialStage)
    local pTongClient    = GetTongClient()
    local pPlayer        = GetClientPlayer()

    UIHelper.SetString(self.LabelMatchStage, g_tStrings.STR_TONG_LEAGUE_RESULT_STAGE_INFOR[nOfficialStage])
    -- UIHelper.SetVisible(self.LabelMatchStage, true)
    UIHelper.SetVisible(self.WidgetMatchStageEnd, true)
    UIHelper.SetVisible(self.ImgLeagueStage, false)
    UIHelper.SetVisible(self.ImgLeagueStageTitle, false)

    UIHelper.SetVisible(self.WidgetMatchRank1, false)
    UIHelper.SetVisible(self.WidgetMatchRank2, false)
    local TopNum = 0;
    if nOfficialStage == BF_TONG_LEAGUE_STAGE.FIRST then
        TopNum = 1
        UIHelper.SetVisible(self.WidgetMatchRank1, true)
    elseif nOfficialStage == BF_TONG_LEAGUE_STAGE.SECOND then
        TopNum = 2
        UIHelper.SetVisible(self.WidgetMatchRank2, true)
    elseif nOfficialStage == BF_TONG_LEAGUE_STAGE.THIRD then
        TopNum = 3
    elseif nOfficialStage >= BF_TONG_LEAGUE_STAGE.TOP8 then
        TopNum = 8
    elseif nOfficialStage >= BF_TONG_LEAGUE_STAGE.TOP64 then
        TopNum = 64
    end
    local MATHC_STAGET_EFF = {
        [1] = self.Eff_UI_HuiZhang06,
        [2] = self.Eff_UI_HuiZhang05,
        [3] = self.Eff_UI_HuiZhang04,
        [8] = self.Eff_UI_HuiZhang03,
        [64] = self.Eff_UI_HuiZhang02,
        [0] = self.Eff_UI_HuiZhang01,
    }
    UIHelper.SetVisible(MATHC_STAGET_EFF[TopNum], true)
    UIHelper.SetSpriteFrame(self.ImgMatchStageEnd, MATCH_STAGET_END[TopNum])
end

function UIFactionChampionship:UpdataOfficiaDetail(nNowStage)
    local pTongClient    = GetTongClient()
    local pPlayer        = GetClientPlayer()
    local tInfo          = DataModel.tTongLeagueJoinInfo or {}
    local nSignUpEndTime = tInfo.nBaseSignUpEndTime
    local nNextFightTime = tInfo.nOfficialStartTime
    local szSide         = ""
    local bHasOpponent   = tInfo.szOfficialTargetTongName and tInfo.szOfficialTargetTongName ~= "" or false

    if bHasOpponent then
        if tInfo.nOfficialMatchSide == 0 then
            szSide = "（蓝方）"
        elseif tInfo.nOfficialMatchSide == 1 then
            szSide = "（红方）"
        end
    end

    UIHelper.SetString(self.LabelWinScore, tostring(tInfo.nWinCount or 0))
    UIHelper.SetString(self.LabelDefeatScore, tostring(tInfo.nLoseCount or 0))

    -- UIHelper.SetVisible(self.LabelMatchStage, false)
    UIHelper.SetVisible(self.WidgetMatchStageEnd, false)
    local nImageFrame = TONG_LEAGUE_RESULTIMAGEFRAME_STAGE[nNowStage]
    if nImageFrame then
        UIHelper.SetSpriteFrame(self.ImgLeagueStage, nImageFrame)
        UIHelper.SetVisible(self.ImgLeagueStage, true)
    else
        UIHelper.SetVisible(self.ImgLeagueStage, false)
    end
    local szTitle = TONG_LEAGUE_RESULTITITLE_STAGE[nNowStage]
    if szTitle then
        UIHelper.SetVisible(self.ImgLeagueStageTitle, true)
        UIHelper.SetString(self.LabelMatchStageTitle, szTitle)
    else
        UIHelper.SetVisible(self.ImgLeagueStageTitle, false)
    end

    local bSignUp = DataModel.IsSignUp()
    local bRaceGoing = DataModel.IsRaceGoing()
    local bRankRace = DataModel.IsRankRace()
    local bCanEnter = bRaceGoing and nNextFightTime ~= 0
    local bCanCancel = not bRaceGoing and bSignUp and nSignUpEndTime ~= 0 and nNextFightTime == 0
    local bCanSignUp = not bRaceGoing and nSignUpEndTime ~= 0 and not bSignUp
    UIHelper.SetVisible(self.BtnApplyAndEnter, bCanEnter or bCanCancel or bCanSignUp)
    UIHelper.SetVisible(self.LabelApplyAndEnter, bCanEnter or bCanCancel or bCanSignUp)
    if bRaceGoing then
        UIHelper.SetVisible(self.LayoutMatchingTime, false)
        if bSignUp then -- 已开赛 已报名
            self.m.bBtnApplyLogicEnabled = true
            self.m.szBtnApplyDisableTip = nil
            if szSide ~= "" then
                UIHelper.SetVisible(self.LayoutNextMatch, true)
                UIHelper.SetString(self.LabelNextMatchTitle, "")
                UIHelper.SetString(self.LabelNextMatchTime, szSide)
                UIHelper.LayoutDoLayout(self.LayoutNextMatch)
            end
        else -- 已开赛 未报名。未报名不可能有开赛时间，所以不可能发生
            self.m.bBtnApplyLogicEnabled = false
            self.m.szBtnApplyDisableTip = nil
        end
        UIHelper.SetString(self.LabelApplyAndEnter, "进入比赛")
        UIHelper.BindUIEvent(self.BtnApplyAndEnter, EventType.OnClick, function()
            if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "九素云峰") then
                return
            end
            JoinBattleFieldQueue(self.dwMapID, 0, false, false)
        end)
    else
        if not bSignUp then -- 未开赛 未报名
            if tInfo.nNowStage == BF_TONG_LEAGUE_STAGE.BASE_EXT then -- 加赛
                UIHelper.SetString(self.LabelMatchingTime, g_tStrings.STR_TONGBATTLEFIELD_BASE_EXT)
                UIHelper.SetString(self.LabelTimeNum, "")
                UIHelper.LayoutDoLayout(self.LayoutMatchingTime)
            elseif nSignUpEndTime == 0 then
                UIHelper.SetVisible(self.LayoutMatchingTime, false)
            else
                UIHelper.SetString(self.LabelMatchingTime, "")
                local szSignUpTime = DataModel.GetSignUpTimeText()
                UIHelper.SetString(self.LabelTimeNum, "")
                UIHelper.LayoutDoLayout(self.LayoutMatchingTime)

                UIHelper.SetVisible(self.LayoutNextMatch, true)
                UIHelper.SetString(self.LabelNextMatchTitle, g_tStrings.STR_TONGBATTLEFIELD_SIGNUP_TIME)
                UIHelper.SetString(self.LabelNextMatchTime, szSignUpTime)
                UIHelper.LayoutDoLayout(self.LayoutNextMatch)
            end

            UIHelper.SetString(self.LabelApplyAndEnter, "报名参赛")
            if nSignUpEndTime ~= 0 then
                self.m.bBtnApplyLogicEnabled = true
                self.m.szBtnApplyDisableTip = nil
                UIHelper.BindUIEvent(self.BtnApplyAndEnter, EventType.OnClick, function()
                    local bCanSignUp = self:CheckSignUp() -- 点击后再开始判断是否可以报名
                    if not bCanSignUp then
                        return
                    end
                    DataModel.nSignUpType = BF_TONG_LEAGUE_SIGNUP_OPERATION.OFFICIAL
                    ApplyBFTongOnlineMemberCount()
                end)
            else
                self.m.bBtnApplyLogicEnabled = false
                self.m.szBtnApplyDisableTip = nil
            end
        else -- 未开赛 已报名
            if tInfo.bBaseSignUp and nNextFightTime == 0 then -- 报名结束前，等待匹配
                UIHelper.SetString(self.LabelMatchingTime, g_tStrings.STR_TONGBATTLEFIELD_SIGNUP_SUCCESS)
                UIHelper.SetString(self.LabelTimeNum, "")
                UIHelper.LayoutDoLayout(self.LayoutMatchingTime)
            elseif nNextFightTime ~= 0 then -- 报名结束后，生成对战表，显示下场比赛时间
                UIHelper.SetString(self.LabelMatchingTime, "")
                local szNextFightOSTime = string.format(os.date("%Y-%m-%d %H:%M:%S", nNextFightTime))
                UIHelper.SetString(self.LabelTimeNum, "")
                UIHelper.LayoutDoLayout(self.LayoutMatchingTime)

                UIHelper.SetVisible(self.LayoutNextMatch, true)
                UIHelper.SetString(self.LabelNextMatchTitle, g_tStrings.STR_TONGBATTLEFIELD_NEXTFIGHTOSTIMETEXT)
                UIHelper.SetString(self.LabelNextMatchTime, szNextFightOSTime .. szSide)
                UIHelper.LayoutDoLayout(self.LayoutNextMatch)
            else
                UIHelper.SetVisible(self.LayoutMatchingTime, false)
            end
            if nNextFightTime == 0 and nSignUpEndTime ~= 0 then
                UIHelper.SetString(self.LabelApplyAndEnter, "取消报名")
                self.m.bBtnApplyLogicEnabled = true
                self.m.szBtnApplyDisableTip = nil
                UIHelper.BindUIEvent(self.BtnApplyAndEnter, EventType.OnClick, function()
                    local bCanCancel = self:CheckCanCancel()
                    if bCanCancel then
                        local nRetCode = CancelBFTongLeagueSignUp()
                        DataModel.CheckErrorCodeTips(nRetCode)
                    end
                end)
            else
                UIHelper.SetString(self.LabelApplyAndEnter, "进入比赛")
                self.m.bBtnApplyLogicEnabled = false
                self.m.szBtnApplyDisableTip = "请于20:00进入比赛场地"
            end
        end
    end
end

function UIFactionChampionship:UpdateBaseInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hTongClient = GetTongClient()
    if not hTongClient then
        return
    end

    local dwTongID    = hPlayer.dwTongID
    local nCamp       = hTongClient.nCamp
    local szTongName  = dwTongID > 0 and hTongClient.ApplyGetTongName(hPlayer.dwTongID) or ""
    local tMasterInfo = hTongClient.GetMemberInfo(hTongClient.dwMaster) or {}
    local szCampIcon  = CampData.GetCampImgPath(nCamp)
    if dwTongID ~= 0 and (nCamp == CAMP.GOOD or nCamp == CAMP.EVIL) then
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, szCampIcon)
    else
        UIHelper.SetVisible(self.ImgCamp, false)
    end
    UIHelper.SetString(self.LabelFactionName, UIHelper.GBKToUTF8(szTongName))
    UIHelper.SetString(self.LabelFactionOwner, UIHelper.GBKToUTF8(tMasterInfo.szName or ""))
end

--对手
function UIFactionChampionship:UpdateCompetitor()
    local tInfo        = DataModel.tTongLeagueJoinInfo or GetTongClient().GetTongLeagueJoinInfo()
    local nRank        = DataModel.GetTongRank(tInfo.nOfficialTargetCamp, tInfo.dwOfficialTargetCenterID, tInfo.szOfficialTargetTongName)
    local szRecord     = FormatString(g_tStrings.STR_ARENA_V_L3, tInfo.nOfficialTargetWinCount or 0, tInfo.nOfficialTargetLoseCount or 0)
    local szCampIcon   = CampData.GetCampImgPath(tInfo.nOfficialTargetCamp)
    local szServerName = tInfo.dwOfficialTargetCenterID > 0 and GetCenterNameByCenterID(tInfo.dwOfficialTargetCenterID) or ""

    if tInfo.szOfficialTargetTongName == "" then
        UIHelper.SetOpacity(self.WidgetNextOpponent, 0)
        return
    else
        UIHelper.SetOpacity(self.WidgetNextOpponent, 255)
    end
    if nRank then
        UIHelper.SetString(self.LabelOpponentRank, FormatString(g_tStrings.STR_GUILD_RANK, nRank))
    else
        UIHelper.SetString(self.LabelOpponentRank, g_tStrings.STR_GUILD_NOT_IN_RANK)
    end
    if not szCampIcon then
        UIHelper.SetVisible(self.ImgOpponentCamp, false)
    else
        UIHelper.SetVisible(self.ImgOpponentCamp, true)
        UIHelper.SetSpriteFrame(self.ImgOpponentCamp, szCampIcon)
    end
    UIHelper.SetString(self.LabelOpponentServer, UIHelper.GBKToUTF8(szServerName))
    UIHelper.SetString(self.LabelOpponentRecord, szRecord)
    UIHelper.SetString(self.LabelOpponentName, UIHelper.GBKToUTF8(tInfo.szOfficialTargetTongName))
    UIHelper.SetString(self.LabelOpponentMaster, UIHelper.GBKToUTF8(tInfo.szOfficialTargetMasterName))
end

--排名奖励
function UIFactionChampionship:UpdateRankReward()
    --[[
    local tRewardItem = CommonDef.TONG_LEAGUE_RANK_REWARD
    local bHasReward = false
    for i = 1, 3 do
        local LabelHint  = self.RankRewardHint[i]
        local WidgetItem = self.RankRewardItem[i]
        if WidgetItem then
            local hBox     = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, WidgetItem)
            local nState  = DataModel.tRewardState and DataModel.tRewardState[i] or 3
            local bCanGet = nState == 2
            hBox.bCanGet = bCanGet
            hBox.nRankRewardIndex = i
            hBox:SetItemReceived(nState == 1)
            hBox:SetClickNotSelected(true)
            hBox:OnInitWithTabID(tRewardItem[i].dwTabType, tRewardItem[i].dwIndex)
            hBox:SetLabelCount(tRewardItem[i].nCount)
            hBox:SetClickCallback(function ()
                if hBox.bCanGet then
                    RemoteCallToServer("On_Tong_RankRewardGiveReWard", hBox.nRankRewardIndex)
                    return
                end
                TipsHelper.ShowItemTips(hBox._rootNode, tRewardItem[i].dwTabType, tRewardItem[i].dwIndex, false)
            end)
            if nState == 1 then
                UIHelper.SetString(LabelHint, "已领")
                UIHelper.SetTextColor(LabelHint, REWARD_HINT_COLOR[1])
                UIHelper.SetOpacity(LabelHint, 153)
            elseif nState == 2 then
                UIHelper.SetString(LabelHint, "可领")
                UIHelper.SetTextColor(LabelHint, REWARD_HINT_COLOR[1])
                UIHelper.SetOpacity(LabelHint, 153)
                bHasReward = true
            elseif nState == 3 then
                UIHelper.SetString(LabelHint, "未达成")
                UIHelper.SetTextColor(LabelHint, REWARD_HINT_COLOR[2])
                UIHelper.SetOpacity(LabelHint, 255)
            end
        end
    end
    UIHelper.SetVisible(self.LabelAwardTime, bHasReward)
    ]]
end

function UIFactionChampionship:UpdateAwardList()
    for i = 1, 4 do
        local WidgetItem = self.tbWidgetAwardList[i]
        if WidgetItem then
            if TONG_LEAGUE_MATCHES_AWARDS[i] then
                local nItemType = TONG_LEAGUE_MATCHES_AWARDS[i].nItemType
                local nItemID = TONG_LEAGUE_MATCHES_AWARDS[i].nItemID
                local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, WidgetItem)
                scriptItem:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem)
                scriptItem:OnInitWithTabID(nItemType, nItemID)
                scriptItem:SetLabelCount(TONG_LEAGUE_MATCHES_AWARDS[i].nNum)
                scriptItem:SetClickCallback(function(nBox, nIndex)
                    local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptItem._rootNode, TipsLayoutDir.TOP_CENTER)
                    scriptItemTip:OnInitWithTabID(nItemType, nItemID)
                    scriptItemTip:SetBtnState({})
                    scriptItem:SetSelected(false)
                end)

                UIHelper.SetVisible(WidgetItem, true)
            else
                UIHelper.SetVisible(WidgetItem, false)
            end
        end
    end
end

--排行榜
function UIFactionChampionship:UpdateTopRank()
    local hTongClient  = GetTongClient()
    if not hTongClient then
        return
    end

    local nCamp    = hTongClient.nCamp
    local dwTongID = hTongClient.dwTongID

    self.BtnRank.nDetail = RANK_DETAIL[nCamp]

    for i = 1, 3 do
        local tRankInfo    = nCamp ~= CAMP.NEUTRAL and GetTongLeagueRankInfo(nCamp, i - 1) or {}
        local dwCenterID   = tRankInfo.dwCenterID or 0
        local szCenterName = dwCenterID ~= 0 and GetCenterNameByCenterID(dwCenterID) or ""

        UIHelper.SetString(self.TongRankName[i], UIHelper.GBKToUTF8(tRankInfo.szTongName) or "")
        UIHelper.SetString(self.TongRankScore[i], (tRankInfo.nScore or 0) .. g_tStrings.STR_TIME_MINUTE)
        UIHelper.SetString(self.TongRankServer[i], UIHelper.GBKToUTF8(szCenterName))
        if not tRankInfo.dwTongID or tRankInfo.dwTongID == 0 then
            UIHelper.SetString(self.TongRankName[i], g_tStrings.STR_WAIT_SOMEBODY)
        end
    end

    --本帮排名
    local dwCenterID = GetCenterID() or 0
    local tRankInfo  = GetTongLeagueRank(nCamp, dwCenterID, dwTongID)
    local szRank     = g_tStrings.STR_GUILD_NOT_IN_RANK
    if tRankInfo and tRankInfo.nRank > 0 then
        szRank = FormatString(g_tStrings.STR_GUILD_RANK, tRankInfo.nRank)
    end
    UIHelper.SetString(self.LabelMyRank, szRank)
end

function UIFactionChampionship:CanNotJoin(bShow)
    UIHelper.SetVisible(self.BtnApplyAndEnter, bShow)
    UIHelper.SetVisible(self.LabelApplyAndEnter, bShow)
    UIHelper.SetVisible(self.LayoutMatchingTime, bShow)
    UIHelper.SetVisible(self.WidgetAnchorBefore, not bShow and self.m.nSelTitle == TITLE.FORMAL)
end

function UIFactionChampionship:UpdateNotice()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hTongClient = GetTongClient()
    if not hTongClient then
        return
    end

    local bShow  = not DataModel.bSignUpOpen
    local szNotice = ""
    UIHelper.SetVisible(self.BtnAddFaction, false)
    if hPlayer.dwTongID == 0 then
        szNotice = g_tStrings.STR_PLAYER_NO_TONG
        UIHelper.SetVisible(self.BtnAddFaction, true)
    elseif hTongClient.nCamp ~= CAMP.GOOD and hTongClient.nCamp ~= CAMP.EVIL then
        szNotice = g_tStrings.STR_TONG_NATURAL
    end

    if szNotice ~= "" then
        UIHelper.SetString(self.LabelAddFaction, szNotice)
        UIHelper.SetVisible(self.WidgetFactionInfo, false)
        UIHelper.SetVisible(self.WidgetAddFaction, true)
    else
        UIHelper.SetVisible(self.WidgetFactionInfo, true)
        UIHelper.SetVisible(self.WidgetAddFaction, false)
    end
end

function UIFactionChampionship:UpdataPracticeStatic()
    local tInfo = DataModel.tTongLeagueJoinInfo
    local nPracticeStartTime = tInfo.nPracticeStartTime
    self.m.bBtnMatchLogicEnabled = true

    if nPracticeStartTime == -1 then --未报名
        UIHelper.SetString(self.LabelMatching, "开始匹配对手")
        UIHelper.SetSpriteFrame(self.ImgMatching, "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_Normal")
        UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
            if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "九素云峰") then
                return
            end

            local nCurTime = GetCurrentTime()
            local nLastClick = self.BtnMatching.nLastClick
            if nLastClick and nCurTime - nLastClick < SIGN_UP_CD then
                DataModel.CheckErrorCodeTips(BF_TONG_LEAGUE_ERROR_CODE.BUSY_REQUEST)
                return
            end

            self.BtnMatching.nLastClick = nCurTime
            self:SignUpPractice()
        end)
    elseif nPracticeStartTime == 0 then --匹配中
        UIHelper.SetString(self.LabelMatching, "正在匹配中")
        UIHelper.SetSpriteFrame(self.ImgMatching, "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_Normal")
        self.m.bBtnMatchLogicEnabled = false
        self.m.szBtnMatchDisableTip = nil
        -- Timer.Add(self, 50, function()
        --     ApplyBFTongLeagueJoinInfo()
        -- end)
    elseif nPracticeStartTime > 0 then --匹到对手
        UIHelper.SetString(self.LabelMatching, "进入比赛")
        UIHelper.SetSpriteFrame(self.ImgMatching, "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_tuijian")
        UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
            JoinBattleFieldQueue(self.dwMapID, 0, false,true)
        end)
    end
end

function UIFactionChampionship:ShowSignUpConfirm(nOnlineCount)
    local szMessage1 = "当前帮会在线"
    local szMessage2 = "人,系统将根据此人数进行匹配，在线人数若有变更请重新报名。\n精英场：&lt;25人，胜利无积分;\n大师场：≥25人，且&lt;50人，胜利积分+2;\n巅峰场：≥50人，胜方最低积分+5，败方最低积分+2。"
    local szMessage = szMessage1 .. tostring(nOnlineCount or 0) .. szMessage2

    local nEndTime = DataModel.tTongLeagueJoinInfo.nBaseSignUpEndTime - 5
    local nNowTime = GetGSCurrentTime()
    local nCountDown = nEndTime - nNowTime

    local confirm = UIHelper.ShowConfirm(szMessage, function ()
            local nRetCode = SignUpBFTongLeague(BF_TONG_LEAGUE_SIGNUP_OPERATION.OFFICIAL)
            DataModel.CheckErrorCodeTips(nRetCode)
        end, nil, true)
    confirm:SetDynamicTextCountDown("报名剩余时间：", nCountDown)
    -- confirm:SetCancelNormalCountDown(nCountDown)
end

--检测报名时间
function UIFactionChampionship:CheckSignUp()
    local hPlayer     = GetClientPlayer()
    local hTongClient = GetTongClient()

    if not hPlayer or not hTongClient then
        return false
    end

    --服务端限制1帧申请10次，所以有小概率帮会数据没有申请到
    if hTongClient and hTongClient.dwMaster == 0 then
        hTongClient.ApplyTongInfo()
        TipsHelper.ShowNormalTip(g_tStrings.STR_SYNC_INFO)
        return false
    end

    --不是帮主或核心成员
    if not hTongClient.CanMemberBaseOperate(hPlayer.dwID, TONG_OPERATION_INDEX.TONG_LEAGUE_CORE) then
        DataModel.OnTongLeagueErrorCodeTips(BF_TONG_LEAGUE_ERROR_CODE.NO_RIGHT_TO_SIGN_UP)
        return false
    end

    --报名时间未到
    if not DataModel.bSignUpOpen or not DataModel.IsInSignUpTime() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_SIGNUP_TIME_FAILED)
        return false
    end
    return true
end

function UIFactionChampionship:UpdataAwardsStatic()
    local tInfo = DataModel.tAwardsInfo
    local tWidgetList = self.WidgetItemList
    if tInfo then
        UIHelper.SetVisible(self.WidgetActivityAward, true)
    else
        UIHelper.SetVisible(self.WidgetActivityAward, false)
        return
    end
    for i = 1, #tInfo do
        local tItem = tInfo[i]
        local pBuff = Player_GetBuff(tItem.nBuffID)
        local bGet = false
        if pBuff then
            if tItem.bEqual then
                bGet = pBuff[tItem.szValueName] == tItem.nRequireNum
            else
                bGet = pBuff[tItem.szValueName] >= tItem.nRequireNum
            end
        end
        -- bGet = true
        if tWidgetList[i] then
            local nCount = #tItem.tBoxList
            UIHelper.RemoveAllChildren(tWidgetList[i])
            for j = 1, nCount do
                local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, tWidgetList[i])
                scriptItem:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem) -- 用一个其他的 不同页面不影响
                scriptItem:OnInitWithTabID(tItem.tBoxList[j].nItemType, tItem.tBoxList[j].nItemID)
                scriptItem:SetLabelCount(tItem.tBoxList[j].nNum)
                -- UIHelper.SetScale(scriptItem._rootNode, 0.8, 0.8)
                scriptItem:SetClickCallback(function(nBox, nIndex)
                    local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptItem._rootNode, TipsLayoutDir.TOP_CENTER)
                    scriptItemTip:OnInitWithTabID(tItem.tBoxList[j].nItemType, tItem.tBoxList[j].nItemID)
                    scriptItemTip:SetBtnState({})
                end)
                scriptItem:SetItemReceived(bGet)
            end
            UIHelper.LayoutDoLayout(tWidgetList[i])
        end
    end
end

function UIFactionChampionship:UpdataAwardsStaticOfMiddle() --未开赛时middle版
    local tInfo = DataModel.tAwardsInfo
    local MAX_ITEM_NUM = 4
    local tWidget = {
        [1] = self.WidgetAwardInBefore,
        [2] = self.WidgetAwardWinBefore
    }
    if tInfo then
        UIHelper.SetVisible(self.WidgetActivityAwardBefore, true)
    else
        UIHelper.SetVisible(self.WidgetActivityAwardBefore, false)
        return
    end
    for i = 1, #tInfo do
        local tItem = tInfo[i]
        local widgetList = tWidget[i]
        if widgetList then
            for j = 1, MAX_ITEM_NUM do
                if widgetList[j] then
                    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, widgetList[j])
                    scriptItem:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem) -- 用一个其他的 不同页面不影响
                    scriptItem:OnInitWithTabID(tItem.tBoxList[j].nItemType, tItem.tBoxList[j].nItemID)
                    scriptItem:SetLabelCount(tItem.tBoxList[j].nNum)
                    -- UIHelper.SetScale(scriptItem._rootNode, 0.8, 0.8)
                    scriptItem:SetClickCallback(function(nBox, nIndex)
                        local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptItem._rootNode, TipsLayoutDir.TOP_CENTER)
                        scriptItemTip:OnInitWithTabID(tItem.tBoxList[j].nItemType, tItem.tBoxList[j].nItemID)
                        scriptItemTip:SetBtnState({})
                    end)
                end
            end
        end
    end
end

--检测能否取消报名
function UIFactionChampionship:CheckCanCancel()
    local hPlayer     = GetClientPlayer()
    local hTongClient = GetTongClient()

    if not hPlayer or not hTongClient then
        return false
    end

    --不是帮主或核心成员
    if not hTongClient.CanMemberBaseOperate(hPlayer.dwID, TONG_OPERATION_INDEX.TONG_LEAGUE_CORE) then
        DataModel.OnTongLeagueErrorCodeTips(BF_TONG_LEAGUE_ERROR_CODE.NO_RIGHT_TO_SIGN_UP)
        return false
    end
    return true
end

function UIFactionChampionship:SignUpPractice()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hTongClient = GetTongClient()
    if not hTongClient then
        return
    end

    --不是帮主或核心成员
    if not hTongClient.CanMemberBaseOperate(hPlayer.dwID, TONG_OPERATION_INDEX.TONG_LEAGUE_CORE) then
        DataModel.OnTongLeagueErrorCodeTips(BF_TONG_LEAGUE_ERROR_CODE.NO_RIGHT_TO_SIGN_UP)
        return false
    end
    DataModel.nSignUpType = BF_TONG_LEAGUE_SIGNUP_OPERATION.PRACTICE
    ApplyBFTongOnlineMemberCount()
end

function UIFactionChampionship:UpdateButtonState()
    local bAgreed = APIHelper.IsDid(KEY_TONGBATTLEFIELD_AGREE_CHECK)

    -- BtnApplyAndEnter: agree checkbox AND business logic
    if self.m.bBtnApplyLogicEnabled and bAgreed then
        UIHelper.SetButtonState(self.BtnApplyAndEnter, BTN_STATE.Normal)
    else
        local szTip = self.m.szBtnApplyDisableTip
        if not bAgreed then
            szTip = g_tStrings.STR_TONGBATTLEFIELD_AGREE_FIRST
        end
        UIHelper.SetButtonState(self.BtnApplyAndEnter, BTN_STATE.Disable, szTip)
    end

    -- BtnMatching: agree checkbox AND master check AND business logic
    local bIsMaster = false
    local hPlayer = GetClientPlayer()
    local hTongClient = GetTongClient()
    if hPlayer and hTongClient then
        bIsMaster = hPlayer.dwID == hTongClient.dwMaster
    end
    if self.m.bBtnMatchLogicEnabled and bAgreed then
        UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Normal)

        if not TongData.HavePlayerJoinedTong() then
            local szTips = g_tStrings.STR_ONTONGLEAGUEERRORCODE_TIP[BF_TONG_LEAGUE_ERROR_CODE.NO_TONG]
            UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable, szTips)
        elseif TongData.GetCamp() == CAMP.NEUTRAL then
            local szTips = g_tStrings.STR_ONTONGLEAGUEERRORCODE_TIP[BF_TONG_LEAGUE_ERROR_CODE.NOT_CAMP]
            UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable, szTips)
        end
    else
        local szTip = self.m.szBtnMatchDisableTip
        if not bAgreed then
            szTip = g_tStrings.STR_TONGBATTLEFIELD_AGREE_FIRST
        end
        UIHelper.SetButtonState(self.BtnMatching, BTN_STATE.Disable, szTip)
    end
end

function UIFactionChampionship:IsAgreeMathRule(bWithoutTips)
    local bSelected = APIHelper.IsDid(KEY_TONGBATTLEFIELD_AGREE_CHECK)
    if not bSelected and not bWithoutTips then
        TipsHelper.ShowNormalTip(g_tStrings.STR_TONGBATTLEFIELD_AGREE_FIRST)
    end
    return bSelected
end

function UIFactionChampionship:SetAgreeMathRule()
    local bSelected = APIHelper.IsDid(KEY_TONGBATTLEFIELD_AGREE_CHECK)
    if bSelected then
        APIHelper.Do(KEY_TONGBATTLEFIELD_AGREE_CHECK, true)
    else
        APIHelper.Do(KEY_TONGBATTLEFIELD_AGREE_CHECK, false)
    end
end

function UIFactionChampionship:UpdateAgreeMathRule()
    UIHelper.SetClickInterval(self.TogConsent, 0)
    UIHelper.SetSelected(self.TogConsent, APIHelper.IsDid(KEY_TONGBATTLEFIELD_AGREE_CHECK))
end

return UIFactionChampionship