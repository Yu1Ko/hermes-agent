Game = Game or {}

Event.Reg(Game, "CLIENT_LOADING_END", function()
    LoginMgr.Start()
    BGMStateMgr.Init()
    SoundMgr.Init()
    AppReviewMgr.Init()

    if Config.bGM then
        GMHelper.Init()

        if not UIMgr.GetView(VIEW_ID.PanelGMBall) then
            UIMgr.Open(VIEW_ID.PanelGMBall)
        end
    end

    --LoginMgr.GetModule(LoginModule.LOGIN_SCENE).PreLoadLoginScene()
end)

Event.Reg(Game, "GAME_EXIT", function()
    Game.UnInit()
end)

function Game.Init()
    LOG.INFO("---- Game.Init() -- Start!!! ----")

    --TODO_xt: 2024.9.25 创建必要目录，待下次换包版本删除
    if Platform.IsAndroid() then
        local fileUtil = cc.FileUtils:getInstance()
        if fileUtil then
            fileUtil:createDirectory("mui")
            fileUtil:createDirectory("mui/Config")
        end
    end

    -- 将部分大的表挪到启动loading过程中加载, 避免使用时加载导致UI长时间卡顿
    Game.loadStartupTabs()

    if Platform.IsWindows() then
        ClientTopMost()
        ccui.EditBox:setGameNumKeyboardEnableInWindows(false)
    else
        Game.updateLoadVideo()
    end

    Game.InitGameWord()

    CustomData.Init()
    Storage_Server.Init()
    Debug.Init()

    DebugDraw.Init()
    AsyncData.Init()
    KeyBoard.Init()
    GamepadData.Init()
    ReloadScript.Init()
    PrefabPool.Init()
    FontMgr.Init()

    UIMgr.Init()
    UIMutexMgr.Init()
    SceneMgr.Init()
    CameraMgr.Init()
    LoginMgr.Init()
    SkillMgr.Init()
    MapHelper.Init()

    NpcData.Init()
    PlayerData.Init()
    BagViewData.Init()
    ItemData.Init()
    EquipData.Init()
    EquipCodeData.Init()
    SprintData.Init()
    ItemSort.Init()
    FellowshipData.Init()
    PlayerPopData.Init()
    TargetMgr.Init()
    PlotMgr.Init()
    QuestData.Init()
    ShopData.Init()
    DungeonData.Init()
    DungeonSettleCardData.Init()
    AssistNewbieBase.Init()
    ActivityData.Init()
    BattleFieldQueueData.Init()
    BattleFieldData.Init()
    TreasureBattleFieldData.Init()
    TreasureBattleFieldSkillData.Init()
    PVPFieldData.Init()
    CommonPVPData.Init()
    ArenaData.Init()
    ArenaTowerData.Init()
    MonopolyInitializer.Init()
    PvpExtractData.Init()
    BubbleMsgData.Init()
    WaitingTipsData.Init()
    ChatData.Init()
    ChatVoiceMgr.Init()
    ChatHintMgr.Init()
    ChatAutoShout.Init()
    ChatAINpcMgr.Init()
    GiftHelper.Init()
    QTEMgr.Init()
    DivinationData.Init()
    TeachBoxData.Init()
    TeachEvent.Init()
    TradeData.Init()
    FurnitureData.Init()
    HomelandBuildData.Init()
    HomelandData.Init()
    PrivateHomeData.Init()
    HomelandEventHandler.Init()
    HomelandIdentity.Init()
    HomelandFlowerPriceData.Init()
    AutoBattle.Init()

    CampData.Init()
    OutMap.Init()
    TimelyMessagesBtnData.Init()

	UIBattleSkillSlot.Init()
    SceneHelper.Init()
	CraftData.Init()
    AuctionData.Init()

    PopMgr.Init()
    HuaELouData.Init()
    OperationCenterData.Init()
    WulintongjianDate.Init()
    PublicQuestData.Init()
    GVoiceMgr.Init()
    HotSpotData.Init()
    PakDownloadMgr.Init()
    PakEquipResData.Init()
    RecommendPakMutexMgr.Init()
    PakSizeQueryMgr.Init()
    CrossingData.Init()
    MapQueueData.Init()
    MonsterBookData.Init()
    AdventureData.Init()
    VideoData.Init()
    EmotionData.Init()
    TongData.Init()
    TradingData.Init()
    MahjongData.Init()
    ServiceCenterData.Init()
    GeneralProgressBarData.Init()
    ActivityTipData.Init()
    TraceInfoData.Init()
    DdzPokerData.Init()
    GameSettingData.Init()
    ShortcutInteractionData.Init()
    ResCleanData.Init()
    IdentitySkillData.Init()
    JiangHuData.Init()
    QuestionnaireData.Init()
    TapTapData.Init()
    PartnerData.Init()
    TeamMarkData.Init()
    JX_TargetList.Init()
    MY_Taoguan.Init()
    DesignationMgr.Init()
    BulletinData.Init()
    NetworkData.Init()
    DBMData.Init()
    MailMgr.Init()
    TeamData.Init()
    TeamBuilding.Init()
    SwordMemoriesData.Init()
    PSMMgr.Init()
    FrameMgr.Init()
    TouchMgr.Init()
    BahuangData.Init()
    DataReport.Init()
    PersonalCardData.Init()
    AutoNav.Init()
    CollectionData.Init()
    CollectionDailyData.Init()
    AchievementData.Init()
    FilterMgr.Init()
    WebUrl.Init()
    OutFitPreviewData.Init()
    CoinShopHair.Init()
    CampOBBaseData.Init()
    CommandBaseData.Init()
    TeamNotice.Init()
    RoomNotice.Init()
    FestivalActivities.Init()
    RedpointHelper.Init()
    HorseMgr.Init()
    ReviveMgr.Init()
    CustomTipsSizeData.Init()
    CameraCommon.Init()
    ShenBingUpgradeMgr.Init()
    BaiZhanDbmData.Init()
    MainCityCustomData.Init()
    AppointmentData.Init()
    WordBlockMgr.Init()
    TravellingBagData.Init()
    BankLock.Init()

    MatrixData.Init()
    ChatRecentMgr.Init()
    ChatMonitor.Init()
    ChatCollector.Init()
    SelfieData.Init()
    TuiLanData.Init()
    -- BuffMonitorData.Init()
    TopBuffData.Init()
    ArenaBonusData.Init()
    HeatMapData.Init()
    RoomVoiceData.Init()
    OBDungeonData.Init()
    TriggerMgr.Init()
    AIAgentChatRecordManager.Init()
    MatchThreeData.Init()
    H5Mgr.Init()
    if DEBUG_ZJQ then
        KeyStatus.Init()
    end

    APIHelper.SetWindowTitle()
    LOG.INFO(" ---- Game.Init() -- Success!!! ----")
end

function Game.UnInit()
    Event.Dispatch(EventType.OnAppPreQuit)

    Debug.UnInit()
    DebugDraw.UnInit()

    PrefabPool.UnInit()

    KeyBoard.UnInit()
    GamepadData.UnInit()
    LoginMgr.UnInit()
    UIMutexMgr.UnInit()
    TipsHelper:UnInit()
    SceneMgr.UnInit()
    CameraMgr.UnInit()
    SkillMgr.UnInit()
    MapHelper.UnInit()
    BGMStateMgr.UnInit()
    SoundMgr.UnInit()

    PlayerData.UnInit()
    ItemData.UnInit()
    EquipData.UnInit()
    EquipCodeData.UnInit()
    SprintData.UnInit()
    ItemSort.UnInit()
    FellowshipData.UnInit()
    PlayerPopData.UnInit()
    TargetMgr.UnInit()
    PlotMgr.UnInit()
    QuestData.UnInit()
    ShopData.UnInit()
    DungeonData.UnInit()
    AssistNewbieBase.UnInit()
    ActivityData.UnInit()
    BattleFieldQueueData.UnInit()
    BattleFieldData.UnInit()
    TreasureBattleFieldData.UnInit()
    TreasureBattleFieldSkillData.UnInit()
    PVPFieldData.UnInit()
    ArenaData.UnInit()
    ArenaTowerData.UnInit()
    MonopolyInitializer.UnInit()
    BubbleMsgData.UnInit()
    WaitingTipsData.UnInit()
    ChatData.UnInit()
    ChatVoiceMgr.UnInit()
    ChatAINpcMgr.UnInit()
    QTEMgr.UnInit()
    DivinationData.UnInit()
    TeachEvent.UnInit()
    TradeData.UnInit()
    MahjongData.UnInit()
    SceneHelper.UnInit()
    GameSettingData.UnInit()
    ShortcutInteractionData.UnInit()
    CampData.UnInit()
    OutMap.UnInit()
    HuaELouData.UnInit()
    OperationCenterData.UnInit()
    WulintongjianDate.UnInit()
    FurnitureData.UnInit()
    HomelandBuildData.UnInit()
    HomelandData.UnInit()
    HomelandFlowerPriceData.UnInit()
    PrivateHomeData.UnInit()
    TimelyMessagesBtnData.UnInit()
    ResCleanData.UnInit()
    PakDownloadMgr.UnInit()
    PakEquipResData.UnInit()
    RecommendPakMutexMgr.UnInit()
    PakSizeQueryMgr.UnInit()
    CrossingData.UnInit()
    MapQueueData.UnInit()
    MonsterBookData.UnInit()
    AdventureData.UnInit()
    VideoData.UnInit()
    EmotionData.UnInit()
    TongData.UnInit()
    TradingData.UnInit()
    HotSpotData.UnInit()
    BulletinData.UnInit()
    NetworkData.UnInit()

    GeneralProgressBarData.UnInit()
	ActivityTipData.UnInit()
    TraceInfoData.UnInit()
    ServiceCenterData.UnInit()
    JiangHuData.UnInit()
    QuestionnaireData.UnInit()
    TapTapData.UnInit()
    PartnerData.UnInit()
    TeamMarkData.UnInit()
    JX_TargetList.UnInit()
    MY_Taoguan.UnInit()
    DBMData.UnInit()
    MailMgr.UnInit()
    TeamData.UnInit()
    TeamBuilding.UnInit()
    SwordMemoriesData.UnInit()
    BahuangData.UnInit()
    PersonalCardData.UnInit()
    AutoNav.UnInit()
    CollectionData.UnInit()
    CollectionDailyData.UnInit()
    CampOBBaseData.UnInit()
    CommandBaseData.UnInit()
    FilterMgr.UnInit()
    WebUrl.UnInit()
    Storage_Server.UnInit()
    TeamNotice.UnInit()
    RoomNotice.UnInit()
    FestivalActivities.UnInit()
    HorseMgr.UnInit()
    ReviveMgr.UnInit()
    CustomTipsSizeData.UnInit()
    FontMgr.UnInit()
    UIMgr.UnInit()
    CameraCommon.UnInit()
    ShenBingUpgradeMgr.UnInit()
    BaiZhanDbmData.UnInit()
    MainCityCustomData.UnInit()
    AppointmentData.UnInit()
    TravellingBagData.UnInit()
    SelfieData.UnInit()
    TuiLanData.UnInit()
    BankLock.UnInit()
    -- BuffMonitorData.UnInit()
    TopBuffData.UnInit()
    HeatMapData.UnInit()
    RoomVoiceData.UnInit()
    TriggerMgr.UnInit()

    H5Mgr.UnInit()

    ShareCodeData.ClearCacheData()
end


















function Game.InitGameWord()
    LoadScene()
    LoadPlayer()
    LoadNpc()
    LoadNpcTemplate()
    LoadDoodad()
    LoadDoodadTemplate()
    --LoadDropDoodadInfo()
    --LoadRouteNode()
    if LoadItemHouse then
        LoadItemHouse()
    end
    LoadSkill()
    LoadProfession()
    --LoadRecipe()
    LoadQuestInfo()
    LoadShop()
    LoadTeamClient()
    LoadGameCardClient()
    LoadBuffInfo()
    LoadCastleData()

    rlcmd("use hd 1")
    rlcmd("use bd 0") -- X3D暂时不启用BD
    -- 部分攻击动作没有打伤害标签导致伤害文字无法显示，先强制关闭伤害标签功能
    rlcmd("EnableMergeDamage 1")

    if LoadInnerChargeCache then
        LoadInnerChargeCache()
    end

    if LoadPlayerIdentityManager then
        LoadPlayerIdentityManager()
    end

    if LoadPushFellowshipClient then
        LoadPushFellowshipClient()
    end

    if LoadSocialManagerClient then
        LoadSocialManagerClient()
    end

    if LoadFellowshipRankClient then
        LoadFellowshipRankClient()
    end

    if LoadQuestRewardClient then
        LoadQuestRewardClient()
    end

    if LoadAuctionClient then
        LoadAuctionClient()
    end

    if LoadScriptClient then
        LoadScriptClient();
    end

    if LoadCampInfo then
        LoadCampInfo()
    end

    if LoadTongClient then
        LoadTongClient()
    end

    if LoadMailClient then
        LoadMailClient()
    end

    if LoadMailInfo then
        LoadMailInfo()
    end

    if LoadActivityMgrClient then
        LoadActivityMgrClient()
    end

    if LoadHairShop then
        LoadHairShop()
    end

    if LoadExterior then
        LoadExterior()
    end

    if LoadDomesticate then
        LoadDomesticate()
    end

    if LoadMiniAvatar then
        LoadMiniAvatar()
    end

    if LoadRewardsShop then
        LoadRewardsShop()
    end

    if LoadCoinShopClient then
        LoadCoinShopClient()
    end

    if LoadPeerPayClient then
        LoadPeerPayClient()
    end

    if LoadFaceLiftManager then
        LoadFaceLiftManager()
    end

    if LoadChatManager then
        LoadChatManager()
    end

    if LoadVoiceRoomClient then
        LoadVoiceRoomClient()
    end

    if LoadCampPlantManager then
        LoadCampPlantManager()
    end

    if LoadCoinShopGrouponClient then
        LoadCoinShopGrouponClient()
    end

    if LoadTeamBiddingMgr then
        LoadTeamBiddingMgr()
    end

    if LoadHomelandMgr then
        LoadHomelandMgr()
    end

    if LoadMiniGameMgr then
        LoadMiniGameMgr()
    end

    if LoadAsuraClient then
        LoadAsuraClient()
    end

    if LoadCoinShopDraw then
        LoadCoinShopDraw()
    end

    if LoadNameCardClient then
        LoadNameCardClient()
    end

    if LoadPVPFieldClient then
        LoadPVPFieldClient()
    end

    if LoadPVPFieldBulletinData then
        LoadPVPFieldBulletinData()
    end

    if LoadNpcExteriorManager then
        LoadNpcExteriorManager()
    end

    if LoadBodyReshapingManager then
        LoadBodyReshapingManager()
    end

    if LoadEquipRepresentSettings then
        LoadEquipRepresentSettings()
    end

    if LoadGlobalRoomClient then
        LoadGlobalRoomClient()
    end

    if LoadGlobalRoomPushClient then
        LoadGlobalRoomPushClient()
    end

    if LoadShowCardCacheManager then
    	LoadShowCardCacheManager()
    end

    if LoadShowCardDecorationSettings then
        LoadShowCardDecorationSettings()
    end

    if LoadTradeMallClient then
        LoadTradeMallClient()
    end

    LoadNpcAssistedInfo()

    if LoadPlayerIdleActionSettings then
        LoadPlayerIdleActionSettings()
    end

    if LoadHorseExteriorManager then
        LoadHorseExteriorManager()
    end

    if LoadHairCustomDyeingManager then
        LoadHairCustomDyeingManager()
    end

end

function Game.Exit()
    UIMgr.ReportOpenedViewList()
    LogoutGame()
    Event.Dispatch("PLAYER_LEAVE_GAME");

    if Platform.IsWindows() --[[or Platform.IsMac()]] then
        Config.SaveVideoSetting()
    end

    PakDownloadMgr.PauseAllPack() --退出时暂停所有下载，否则退出会退很久

    App_Quit()
end

---comment 启动时加载的表(1. 部分加载耗时的表, 2. 标记动态加载的表)
function Game.loadStartupTabs()
    local nTime = Timer.GetPassTime()
    g_tTable.LoadStartupTabs()      -- 加载启动需要初始化的表, 一般指加载比较耗时的表
    Table_GenerateAllSceneQuest()   -- 这个函数第一次调用会加载整个Quests表产生大量耗时，暂时放在加载流程防止界面打开时卡顿
    Table_GetBindNpcQuestList()
    g_tTable.ClearDynTabCache()     -- 清理DynTab表的缓存
    LOG("[tab] load startup table cost time:%0.1f(ms)", (Timer.GetPassTime() - nTime) * 1000)
end

---comment 更新启动界面视频文件
function Game.updateLoadVideo()
    local fileUtil = cc.FileUtils:getInstance()
    local kInfoFile = "temp/video_info.data"
    local tInfo = str2var(fileUtil:getDataFromFile(kInfoFile) or "")
    local bDirty = false

    local kVideoFile = "mui/Video/load_video.mp4"
    local nVideoHash = GetFileContentHash(kVideoFile)
    if nVideoHash ~= 0 and (not tInfo.nVideoHash or tInfo.nVideoHash ~= nVideoHash) then
        if CopyPakFile(kVideoFile, kVideoFile .. ".tmp") then
            fileUtil:removeFile(kVideoFile)
            fileUtil:renameFile(kVideoFile .. ".tmp", kVideoFile)
            tInfo.nVideoHash = nVideoHash
            bDirty = true
        end
    end

    local kAudioFile = "mui/Music/load_bgm.mp3"
    local nAudioHash = GetFileContentHash(kAudioFile)
    if nAudioHash ~= 0 and (not tInfo.nAudioHash or tInfo.nAudioHash ~= nAudioHash) then
        if CopyPakFile(kAudioFile, kAudioFile .. ".tmp") then
            fileUtil:removeFile(kAudioFile)
            fileUtil:renameFile(kAudioFile .. ".tmp", kAudioFile)
            tInfo.nAudioHash = nAudioHash
            bDirty = true
        end
    end

    if bDirty then
        local s = "return " .. var2str(tInfo, "\t", nil, true)
        fileUtil:writeStringToFile(s, kInfoFile)
    end
end
