EventType =
{
    OnAppPreQuit = "OnAppPreQuit",  -- App准备退出, 做一些必要清理操作

    -- 账号
    OnAccountLogin = "OnAccountLogin",
    OnAccountLogout = "OnAccountLogout",
    OnRoleLogin = "OnRoleLogin",
    OnCreateRoleName = "OnCreateRoleName",
    OnRoleSelected = "OnRoleSelected",
    OnTestSchoolConfirm = "OnTestSchoolConfirm",
    OnRestoreBuildFaceCacheData = "OnRestoreBuildFaceCacheData",
    OnRestoreBuildFaceCacheDataStep2 = "OnRestoreBuildFaceCacheDataStep2",

    OnViewOpen = "OnViewOpen",
    OnViewClose = "OnViewClose",
    OnViewShow = "OnViewShow",
    OnViewHide = "OnViewHide",
    OnViewDestroy = "OnViewDestroy",
    OnViewPlayShowAnimBegin = "OnViewPlayShowAnimBegin",
    OnViewPlayShowAnimFinish = "OnViewPlayShowAnimFinish",
    OnViewPlayHideAnimBegin = "OnViewPlayHideAnimBegin",
    OnViewPlayHideAnimFinish = "OnViewPlayHideAnimFinish",
    OnViewMutexPlayShowAnimBegin = "OnViewMutexPlayShowAnimBegin",
    OnViewMutexPlayShowAnimFinish = "OnViewMutexPlayShowAnimFinish",
    OnViewMutexPlayHideAnimBegin = "OnViewMutexPlayHideAnimBegin",
    OnViewMutexPlayHideAnimFinish = "OnViewMutexPlayHideAnimFinish",

    OnTouchMaskShow = "OnTouchMaskShow",
    OnTouchMaskHide = "OnTouchMaskHide",
    OnBlackMaskEnter = "OnBlackMaskEnter",
    OnBlackMaskExit = "OnBlackMaskExit",
    OnBlackMaskEnterFinish = "OnBlackMaskEnterFinish",
    OnBlackMaskExitFinish = "OnBlackMaskExitFinish",
    OnTouchMaskWithTipsShow = "OnTouchMaskWithTipsShow",
    OnTouchMaskWithTipsHide = "OnTouchMaskWithTipsHide",

    PlayAnimMainCityShow = "PlayAnimMainCityShow",
    PlayAnimMainCityHide = "PlayAnimMainCityHide",
    PlayAnimMainCityLeftShow = "PlayAnimMainCityLeftShow",
    PlayAnimMainCityLeftHide = "PlayAnimMainCityLeftHide",
    PlayAnimMainCityRightShow = "PlayAnimMainCityRightShow",
    PlayAnimMainCityRightHide = "PlayAnimMainCityRightHide",
    PlayAnimMainCityBottomShow = "PlayAnimMainCityBottomShow",
    PlayAnimMainCityBottomHide = "PlayAnimMainCityBottomHide",
    PlayAnimMainCityMiddleShow = "PlayAnimMainCityMiddleShow",
    PlayAnimMainCityMiddleHide = "PlayAnimMainCityMiddleHide",
    PlayAnimMainCityFullScreenShow = "PlayAnimMainCityFullScreenShow",
    PlayAnimMainCityFullScreenHide = "PlayAnimMainCityFullScreenHide",
    PlayAnimMainCityOtherShow = "PlayAnimMainCityOtherShow",
    PlayAnimMainCityOtherHide = "PlayAnimMainCityOtherHide",


    OnClick = "OnClick",
    OnTouchBegan = "OnTouchBegan",
    OnTouchMoved = "OnTouchMoved",
    OnTouchEnded = "OnTouchEnded",
    OnTouchCanceled = "OnTouchCanceled",
    OnSelectChanged = "OnSelectChanged",
    OnLongPress = "OnLongPress",
    OnPersistentPress = "OnPersistentPress",
    OnDragOver = "OnDragOver",
    OnDragOut = "OnDragOut",
    OnClickToHide = "OnClickToHide",

    OnWidgetTouchDown = "OnWidgetTouchDown",

    OnChangeSliderPercent = "OnChangeSliderPercent",
    OnTurningPageView = "OnTurningPageView",
    OnScrollingScrollView = "OnScrollingScrollView",

    OnToggleGroupSelectedChanged = "OnToggleGroupSelectedChanged",

    OnVideoStateChanged = "OnVideoStateChanged",

    OnKeyboardDown = "OnKeyboardDown",
    OnKeyboardUp = "OnKeyboardUp",
    OnKeyboardDownForGameSetting = "OnKeyboardDownForGameSetting",
    OnKeyboardUpForGameSetting = "OnKeyboardUpForGameSetting",
    OnGamepadKeyDownForGameSetting = "OnGamepadKeyDownForGameSetting",
    OnGamepadKeyUpForGameSetting = "OnGamepadKeyUpForGameSetting",
    OnChangeToCustomQuality = "OnChangeToCustomQuality",
    OnChangeTopBuffSetting = "OnChangeTopBuffSetting",
    OnKeyboardSettingSwitchPage = "OnKeyboardSettingSwitchPage",

    OnWindowsSetFocus = "OnWindowsSetFocus",
    OnWindowsLostFocus = "OnWindowsLostFocus",
    OnWindowsSizeChanged = "OnWindowsSizeChanged",
    OnWindowsMouseWheel = "OnWindowsMouseWheel", --func(nDelta, bHandled), 其中bHandled表示鼠标滚轮先触发鼠标所在位置的ScrollView的滚动
    OnWindowsMouseWheelForScrollList = "OnWindowsMouseWheelForScrollList", --比OnWindowsMouseWheel早触发，用于ScrollList
    OnSetScreenPortrait = "OnSetScreenPortrait",
    OnSwipeTouchPad = "OnSwipeTouchPad",

    OnApplicationDidFinishLaunching = "OnApplicationDidFinishLaunching",
    OnApplicationDidEnterBackground = "OnApplicationDidEnterBackground",
    OnApplicationWillEnterForeground = "OnApplicationWillEnterForeground",

    OnSceneTouchBegan = "OnSceneTouchBegan",
    OnSceneTouchMoved = "OnSceneTouchMoved",
    OnSceneTouchEnded = "OnSceneTouchEnded",
    OnSceneTouchCancelled = "OnSceneTouchCancelled",
    OnSceneTouchsBegan = "OnSceneTouchsBegan",
    OnSceneTouchsMoved = "OnSceneTouchsMoved",
    OnSceneTouchsEnded = "OnSceneTouchsEnded",
    OnSceneTouchsCancelled = "OnSceneTouchsCancelled",
    OnSceneTouchNothing = "OnSceneTouchNothing",
    OnSceneTouchTarget = "OnSceneTouchTarget",
    OnSceneTouchWithoutMove = "OnSceneTouchWithoutMove",

    OnTouchViewBackGround = "OnTouchViewBackGround",
    OnCaptureScreenFailed = "OnCaptureScreenFailed",
    OnCaptureScreenIng = "OnCaptureScreenIng",
    OnCaptureScreenFinished = "OnCaptureScreenFinished",
    OnCaptureScreenSaveFinished = "OnCaptureScreenSaveFinished",
    OnCaptureNodeFinished = "OnCaptureNodeFinished",
    BeforeCaptureScreen = "BeforeCaptureScreen",
    AfterCaptureScreen = "AfterCaptureScreen",

    OnCameraZoom = "OnCameraZoom",
    OnHotkeyCameraZoom = "OnHotkeyCameraZoom",

    OnRichTextOpenUrl = "OnRichTextOpenUrl",
    ShowNormalTip = "ShowNormalTip",
    ShowImportantTip = "ShowImportantTip",
    ShowPlaceTip = "ShowPlaceTip",
    ShowCampHint = "ShowCampHint",
    HideAllHoverTips = "HideAllHoverTips",
    OnHoverTipsDeleted = "OnHoverTipsDeleted",
    PlayProgressBarTip = "PlayProgressBarTip",
    StopProgressBarTip = "StopProgressBarTip",
    ShowLevelUpTip = "ShowLevelUpTip",
    ShowNewAchievement = "ShowNewAchievement",
    ShowNewDesignation = "ShowNewDesignation",
    ShowQuickEquipTip = "ShowQuickEquipTip",
    ShowEquipScore = "ShowEquipScore",
    ShowQuestComplete = "ShowQuestComplete",
    ShowAnnounceTip = "ShowAnnounceTip",
    ShowRewardListTip = "ShowRewardListTip",
    OnCloseTip = "OnCloseTip",
    PlayCountDown = "PlayCountDown",
    StopCountDown = "StopCountDown",
    UpdateCountDown = "UpdateCountDown",
    ShowNewFeatureTip = "ShowNewFeatureTip",
    OnSendSystemAnnounce = "OnSendSystemAnnounce",
    ShowLikeTip = "ShowLikeTip",
    ShowInteractTip = "ShowInteractTip",
    ShowMessageBubble = "ShowMessageBubble",
    ShowTeamTip = "ShowTeamTip",
    ShowOptickRecordTip = "ShowOptickRecordTip",
    ShowAssistNewbieInviteTip = "ShowAssistNewbieInviteTip",
    ShowMobaSurrenderTip = "ShowMobaSurrenderTip",
    ShowTeamReadyConfirmTip = "ShowTeamReadyConfirmTip",
    ShowRoomTip = "ShowRoomTip",
    ShowBiaoShiTip = "ON_SHOW_WIDGETBIAOSHIPOP",
    ShowHuBiaoTip = "ON_SHOW_WIDGETHUBIAOPOP",
    OnTimelyHintTipsSwitchToSmall = "OnTimelyHintTipsSwitchToSmall",
    UpdateDeathNotify = "UpdateDeathNotify",
    ShowTradeTip = "ShowTradeTip",
    ShowHintSFX = "ShowHintSFX",
    CloseNewAchievement = "CloseNewAchievement",
    CloseNewDesignation = "CloseNewDesignation",
    CloseTimelyMessageBubble = "CloseTimelyMessageBubble",
    OnHideNpcSpeechSoundsBalloon = "OnHideNpcSpeechSoundsBalloon",
    OnCloseNpcSpeechSoundsBalloon = "OnCloseNpcSpeechSoundsBalloon",
    OnCloseQuickEquipTip = "OnCloseQuickEquipTip",
    OnQuickEquipTipClosed = "OnQuickEquipTipClosed",
    OnShieldTip = "OnShieldTip",
    OnUnShieldTip = "OnUnShieldTip",
    OnShowSwimmingProgress = "OnShowSwimmingProgress",
    OnHideSwimmingProgress = "OnHideSwimmingProgress",
    RefreshAltar = "RefreshAltar",
    RefreshBoss = "RefreshBoss",
    OnStartEvent = "OnStartEvent",
    ShowRewardHint = "ShowRewardHint",
    ShowNewEmotionTip = "ShowNewEmotionTip",
    OnOpenRemotePanel = "OnOpenRemotePanel",
    OnUpdateRemotePanel = "OnUpdateRemotePanel",
    CloseRemotePanel = "CloseRemotePanel",
    OpenSpecailGift = "OpenSpecailGift",
    ShowCueWords = "ShowCueWords",

    BubbleMsg = "BubbleMsg",
    BubbleMsgRemove = "BubbleMsgRemove",

    EquipRefineSelectChanged = "EquipRefineSelectChanged",
    EnchantItemSelectChanged = "EnchantItemSelectChanged",
    ShowWinterFestivalTip = "ShowWinterFestivalTip",
    --邮件
    BagItemLongPress = "BagItemLongPress",
    EmailBagItemSelected = "EmailBagItemSelected",
    EmailFriendSelectChanged = "EmailFriendSelectChanged",
    EmailForward = "EmailForward",
    EmailReply = "EmailReply",
    MailNotEnoughRoom = "MailNotEnoughRoom",
    MailItemAmountLimit = "MailItemAmountLimit",
    MailMoneyLimit = "MailMoneyLimit",
    OnEditSendName = "OnEditSendName",

    --坐骑
    HorseSlotSelectItem = "HorseSlotSelectItem",
    EquipHorseEquipBySetID = "EquipHorseEquipBySetID",
    HorseEquipSelect = "HorseEquipSelect",
    ShowHorseEquipTips = "ShowHorseEquipTips",
    UpdateHorseEquipBag = "UpdateHorseEquipBag",

    --头像
    PreviewAvator="PreviewAvator",

    --名片
    OnLookUpPersonalCard = "OnLookUpPersonalCard",
    OnUpdateBirthdaySetRedPoint = "OnUpdateBirthdaySetRedPoint",

    Login_UpdateState = "Login_UpdateState",
    Login_RegionUpdate = "Login_RegionUpdate",
    Login_SelectServer = "Login_SelectServer",
    XGSDK_OnLoginSuccess = "XGSDK_OnLoginSuccess",
    XGSDK_OnLoginCancel = "XGSDK_OnLoginCancel",
    XGSDK_OnLoginFail = "XGSDK_OnLoginFail",
    XGSDK_OnLogoutSuccess = "XGSDK_OnLogoutSuccess",
    XGSDK_OnLogoutFail = "XGSDK_OnLogoutFail",
    XGSDK_OnGetAccountInfoSuccess = "XGSDK_OnGetAccountInfoSuccess",
    XGSDK_OnGetAccountInfoFail = "XGSDK_OnGetAccountInfoFail",
    XGSDK_OnGetUidInfoSuccess = "XGSDK_OnGetUidInfoSuccess",
    XGSDK_OnGetUidInfoFail = "XGSDK_OnGetUidInfoFail",
    XGSDK_OnExit = "XGSDK_OnExit",
    XGSDK_OnNoChannelExit = "XGSDK_OnNoChannelExit",
    PakDownload_OnStart = "PakDownload_OnStart",
    PakDownload_OnQueue = "PakDownload_OnQueue",
    PakDownload_OnPause = "PakDownload_OnPause",
    PakDownload_OnProgress = "PakDownload_OnProgress",
    PakDownload_OnFileDownloaded = "PakDownload_OnFileDownloaded",
    PakDownload_OnStateUpdate = "PakDownload_OnStateUpdate",
    PakDownload_OnComplete = "PakDownload_OnComplete",
    PakDownload_OnDelete = "PakDownload_OnDelete",
    PakDownload_OnCancel = "PakDownload_OnCancel",
    PakDownload_OnBasicStart = "PakDownload_OnBasicStart",
    PakDownload_OnBasicComplete = "PakDownload_OnBasicComplete",
    PakDownload_OnDownloadStart = "PakDownload_OnDownloadStart",
    PakDownload_OnDownloadEnd = "PakDownload_OnDownloadEnd",
    PakDownload_OnResClean = "PakDownload_OnResClean",
    PakDownload_OnCanDownloadAllUpdate = "PakDownload_OnCanDownloadAllUpdate",
    PakDownload_OnGetMultiDlcRealSize = "PakDownload_OnGetMultiDlcRealSize",
    PakDownload_OnGetMultiDlcDeleteSize = "PakDownload_OnGetMultiDlcDeleteSize",

    OnCleanResourcesUpdate = "OnCleanResourcesUpdate",

    -- 捏脸相关
    OnChangeBuildFaceAttribSliderValueBegin = "OnChangeBuildFaceAttribSliderValueBegin",
    OnChangeBuildFaceAttribSliderValue = "OnChangeBuildFaceAttribSliderValue",
    OnChangeBuildFaceAttribSliderValueEnd = "OnChangeBuildFaceAttribSliderValueEnd",
    OnChangeBuildFaceDefault = "OnChangeBuildFaceDefault",
    OnChangeBuildFaceSubPrefab = "OnChangeBuildFaceSubPrefab",
    OnChangeBuildHairValue = "OnChangeBuildHairValue",
    OnChangeBuildMakeupPrefab = "OnChangeBuildMakeupPrefab",
    OnChangeBuildMakeupValue = "OnChangeBuildMakeupValue",
    OnChangeBuildMakeupColor = "OnChangeBuildMakeupColor",
    OnChangeBuildMakeupDetailAdjust = "OnChangeBuildMakeupDetailAdjust",
    OnChangeBuildOldMakeupPrefab = "OnChangeBuildOldMakeupPrefab",
    OnChangeBuildOldMakeupDecoration = "OnChangeBuildOldMakeupDecoration",
    OnChangeBuildOldMakeupColor = "OnChangeBuildOldMakeupColor",
    OnChangeBuildOldMakeupValue = "OnChangeBuildOldMakeupValue",
    OnChangeBuildBodyDefault = "OnChangeBuildBodyDefault",
    OnUpdateBuildFaceModle = "OnUpdateBuildFaceModle",
    OnUpdateBuildBodyModle = "OnUpdateBuildBodyModle",
    OnUpdateBuildHairModle = "OnUpdateBuildHairModle",

    OnUpdateBuildFaceModule = "OnUpdateBuildFaceModule",
    OnShareCodeRsp = "OnShareCodeRsp",
    OnUpdateSelfShareCodeList = "OnUpdateSelfShareCodeList",
    OnUpdateShareCodeListCell = "OnUpdateShareCodeListCell",
    OnSelectShareStationCell = "OnSelectShareStationCell",
    OnSelectPhotoCodeListCell = "OnSelectPhotoCodeListCell",
    OnSelectDelFaceCodeListCell = "OnSelectDelFaceCodeListCell",
    OnDownloadShareCodeData = "OnDownloadShareCodeData",
    OnDownloadShareCodeCover = "OnDownloadShareCodeCover",
    OnDeleteShareCodeData = "OnDeleteShareCodeData",
    OnShowFaceCodeBtn = "OnShowFaceCodeBtn",
    OnSelfieGetLocalAnimationSuccess = "OnSelfieGetLocalAnimationSuccess",
    OnShareStationChangeHelmDye = "OnShareStationChangeHelmDye",
    OnApplyToSetActionByFile = "OnApplyToSetActionByFile",

    OnTipsGiftSuccess = "OnTipsGiftSuccess",

    OnOpenShareStation = "OnOpenShareStation",
    OnCloseShareStation = "OnCloseShareStation",
    OnGetShareStationList = "OnGetShareStationList",
    OnGetShareStationCreatorList = "OnGetShareStationCreatorList",
    OnGetShareStationRecommendList = "OnGetShareStationRecommendList",
    OnGetShareStationUploadConfig = "OnGetShareStationUploadConfig",
    OnClickShareStationAuthorCell = "OnClickShareStationAuthorCell",
    OnFilterShareStationExterior = "OnFilterShareStationExterior",
    OnFilterShareStationMap = "OnFilterShareStationMap",
    OnUpdateFaceCodeInfo = "OnUpdateFaceCodeInfo",
    OnCollectShareCode = "OnCollectShareCode",
    OnUnCollectFaceCode = "OnUnCollectFaceCode",
    OnUpdateCollectShareCodeList = "OnUpdateCollectShareCodeList",
    OnFaceCheckValidSuccess = "OnFaceCheckValidSuccess",

    OnStartDoUploadShareData = "OnStartDoUploadShareData",
    OnStartDoUpdateShareData = "OnStartDoUpdateShareData",
    OnStartBatchDelShareCode = "OnStartBatchDelShareCode",
    OnEndBatchDelShareCode = "OnEndBatchDelShareCode",

    OnBodyCodeRsp = "OnBodyCodeRsp",
    OnUpdateBodyCodeList = "OnUpdateBodyCodeList",
    OnUpdateBodyCodeListCell = "OnUpdateBodyCodeListCell",
    OnSelectBodyCodeListCell = "OnSelectBodyCodeListCell",
    OnSelectDelBodyCodeListCell = "OnSelectDelBodyCodeListCell",
    OnDownloadBodyCodeData = "OnDownloadBodyCodeData",
    OnShowBodyCodeBtn = "OnShowBodyCodeBtn",

    OnSelectDelPhotoCodeListCell = "OnSelectDelPhotoCodeListCell",

    -- 乐谱相关
    OnPressInstrumentKey = "OnPressInstrumentKey",
    OnInstrumentCodeRsp = "OnInstrumentCodeRsp",
    OnGetInstrumentList = "OnGetInstrumentList",
    OnDownloadMusicCodeData = "OnDownloadMusicCodeData",
    OnInstrumentRecordStart = "OnInstrumentRecordStart",
    OnInstrumentRecordStop = "OnInstrumentRecordStop",
    OnSelectInstrumentMusic = "OnSelectInstrumentMusic",
    OnInstrumentPlayingStart = "OnInstrumentPlayingStart",
    OnInstrumentPlayingStop = "OnInstrumentPlayingStop",
    OnShowInstrumentList = "OnShowInstrumentList",

    -- 技能槽位配置相关
    OnSkillSlotChanged = "OnSkillSlotChanged",
    OnDXSkillSlotChanged = "OnDXSkillSlotChanged",
    OnUpdateSkillPanel = "OnUpdateSkillPanel",
    OnSetBottomRightAnchorVisible = "OnSetBottomRightAnchorVisible",
    OnSkillPressDown = "OnSkillPressDown",
    OnHideSkillCancel = "OnHideSkillCancel",

    OnPoseChange = "OnPoseChange",
    OnDXMacroUpdate = "OnDXMacroUpdate",

    -- 目标相关
    OnTargetChanged = "OnTargetChanged",
    OnSearchTargetChanged = "OnSearchTargetChanged",            -- 搜索目标变化, nCharacterID
    OnOtherPlayerRevive = "OTHER_PLAYER_REVIVE",

    --角色相关
    OnChangeCharacterAttribShowConfig = "OnChangeCharacterAttribShowConfig",
    OnSelectedMoreDetailTog1 = "OnSelectedMoreDetailTog1",        --详细属性展开
    OnSelectedMoreDetailTog2 = "OnSelectedMoreDetailTog2",        --详细属性展开2
    OnShowCharacterChangeEquipList = "OnShowCharacterChangeEquipList",
    OnSprintFightStateChanged = "OnSprintFightStateChanged",
    OnPlayerSprintStateChanged = "OnPlayerSprintStateChanged",  --玩家轻功状态更改
    OnFuncSlotChanged = "OnFuncSlotChanged",                    --轻功槽位变化
    OnAutoDoubleSprint = "OnAutoDoubleSprint",                  --自动双人轻功开启
    OnQuickMenuSprintChange = "OnQuickMenuSprintChange",
    OnLeftBottomSprintChange = "OnLeftBottomSprintChange",
    OnClickWantedRankCell = "OnClickWantedRankCell",
    OnClickHunterRankCell = "OnClickHunterRankCell",
    OnClientPlayerEnter = "OnClientPlayerEnter",                  -- 客户端主操角色进入场景
    OnClientPlayerLeave = "OnClientPlayerLeave",                  -- 客户端主操角色离开场景

    -- 装备相关
    OnSelectedEquipCompareToggle = "OnSelectedEquipCompareToggle",
    OnEnterEquipComparePanel = "OnEnterEquipComparePanel",
    OnItemTipSwitchRing = "OnItemTipSwitchRing",
    OnItemTipSelectRing = "OnItemTipSelectRing",

    OnSelectCustomizedSet = "OnSelectCustomizedSet",
    OnUpdateCustomizedSetList = "OnUpdateCustomizedSetList",
    OnUpdateCustomizedSetEquipFilter = "OnUpdateCustomizedSetEquipFilter",
    OnSelectCustomizedSetEquipFilterItemCell = "OnSelectCustomizedSetEquipFilterItemCell",
    OnDoSelectCustomizedSetRecommendCell = "OnDoSelectCustomizedSetRecommendCell",
    OnSelectCustomizedSetRecommendCell = "OnSelectCustomizedSetRecommendCell",
    OnSelectCustomizedSetRecommendCellEnd = "OnSelectCustomizedSetRecommendCellEnd",
    OnSelectCustomizedSetPowerUpSelectItemTipsCell = "OnSelectCustomizedSetPowerUpSelectItemTipsCell",
    OnUpdateCustomizedSetEquipList = "OnUpdateCustomizedSetEquipList",
    OnSelectCustomizedSetMaterialCell = "OnSelectCustomizedSetMaterialCell",
    OnSelectCustomizedSetWuCaiCell = "OnSelectCustomizedSetWuCaiCell",
    OnSelectCustomizedSetImportCell = "OnSelectCustomizedSetImportCell",
    OnClassTitleChanged = "OnClassTitleChanged",

    OnEquipCodeRsp = "OnEquipCodeRsp",
    OnUpdateEquipCodeList = "OnUpdateEquipCodeList",
    OnSelectEquipCodeListCell = "OnSelectEquipCodeListCell",
    OnSelectDelEquipCodeListCell = "OnSelectDelEquipCodeListCell",

    -- 地图相关
    OnOpenMiddleMapPanel     = "OnOpenMiddleMapPanel",
    OnMapUpdatePlayerMarks   = "OnMapUpdatePlayerMarks",
    OnMapOpenTraffic         = "OnMapOpenTraffic",
    OnMapTraceZoning         = "OnMapTraceZoning",
    OnMapUpdateNpcTrace      = "OnMapUpdateNpcTrace",
    OnMapMarkUpdate      = "OnMapMarkUpdate",
    OnPvpMapUpdate = "OnPvpMapUpdate",
    OnHomeLandMapMarkUpdate = "OnHomeLandMapMarkUpdate",
    OnLeaderChangeTeamTag  = "OnLeaderChangeTeamTag",
    OnLikeMapListChange = "OnLikeMapListChange",
    OnDeleteTeamMark = "OnDeleteTeamMark",
    OnClickSearchList = "OnClickSearchList",
    UpdateMinimapHover = "UpdateMinimapHover",
    ON_MAPMAR_ACTIVITYLIST_UPDATE = "ON_MAPMAR_ACTIVITYLIST_UPDATE",
    OnHeatMapDataUpdate = "OnHeatMapDataUpdate",
    OnSelectCampCell = "OnSelectCampCell",
    OnKillerPosUpdate = "OnKillerPosUpdate",
    OnSelectHeatMapMode = "OnSelectHeatMapMode",
    OnRefreshHuntEvent = "OnRefreshHuntEvent",
    ON_UPDATE_MIDDLE_MAP_LINE = "ON_UPDATE_MIDDLE_MAP_LINE",
    ON_MAP_DRAW_LINE_DELETE = "ON_MAP_DRAW_LINE_DELETE",
    ON_MAP_DRAW_LINE_ADD = "ON_MAP_DRAW_LINE_ADD",
    OnStopTraceGuild = "OnStopTraceGuild",

    -- 战场相关
    BF_OpenNewPlayerBF = "BattleField_OpenNewPlayerBF",
    BF_UpdateNewPlayerBF = "BattleField_UpdateNewPlayerBF",
    BF_CloseNewPlayerBF = "BattleField_CloseNewPlayerBF",
    BF_WidgetPlayerUpdate = "BF_WidgetPlayerUpdate",
    BF_WidgetPlayerHideTips = "BF_WidgetPlayerHideTips",
    BF_WidgetPlayerReportSwitch = "BF_WidgetPlayerReportSwitch",
    BF_WidgetPlayerUpdatePraiseInfo = "BF_WidgetPlayerUpdatePraiseInfo",

    -- 吃鸡寻宝模式相关
    UpdateTBFWareHouse = "UpdateTBFWareHouse",
    OnTBFUpdateAllView = "OnTBFUpdateAllView",
    OnUpdateExtractRewardRedPoint = "OnUpdateExtractRewardRedPoint",
    OnExtractOpenEquipChoosePage = "OnExtractOpenEquipChoosePage",
    ShowExtractSettlement = "ShowExtractSettlement",
    OnTreasureHuntInfoOpen = "OnTreasureHuntInfoOpen",
    OnTreasureHuntInfoClose = "OnTreasureHuntInfoClose",

    -- 任务
    OnChooseQuestEvent = "OnChooseQuestEvent",
    OnQuestTracingTargetChanged = "OnQuestTracingTargetChanged",
    OnNewQuestCanTracing = "OnNewQuestCanTracing",
    OnQuestRespond = "OnQuestRespond",
    OnQuestTraceFlyTo = "OnQuestTraceFlyTo",
    OnQuestTraceFlyToFinish = "OnQuestTraceFlyToFinish",
    OnQuestNearTarget = "OnQuestNearTarget",
    OnQuestLeaveTarget = "OnQuestLeaveTarget",

    --剑侠录
    OnSwordMemoriesSoundChanged = "OnSwordMemoriesSoundChanged",
    OnShowAllSection = "OnShowAllSection",
    UpdateMainStoryReward = "UpdateMainStoryReward",
    OnRewardStateChanged = "OnRewardStateChanged",--领奖状态变化


    -- 他人交互
    OnGetPrestigeInfoRespond = "OnGetPrestigeInfoRespond",
    PLAYER_APPLY_BE_ADD_FOE = "PLAYER_APPLY_BE_ADD_FOE",
    PLAYER_HAS_BE_ADD_FOE = "PLAYER_HAS_BE_ADD_FOE",
    PLAYER_APPLY_BE_ADD_FEUD = "PLAYER_APPLY_BE_ADD_FEUD",

    PLAYER_ADD_FOE_BEGIN = "PLAYER_ADD_FOE_BEGIN",
    PLAYER_ADD_FOE_END = "PLAYER_ADD_FOE_END",
    PREPARE_ADD_FOE_RESULT = "PREPARE_ADD_FOE_RESULT",
    PLAYER_ADD_FEUD_NOTIFY = "PLAYER_ADD_FEUD_NOTIFY",
    PLAYER_DEL_BEGIN = "PLAYER_DEL_BEGIN",

    ApplyPlayerPopPrestige = "ApplyPlayerPopPrestige",
    DeletePlayerPop = "DeletePlayerPop",

    -- 商店相关
    OnShopGoodsSelectChanged = "OnShopGoodsSelectChanged",
    OnShopSelectorSelectChanged = "OnShopSelectorSelectChanged",
    OnShopBuyGoodsSure = "OnShopBuyGoodsSure",
    OnShopClassSelectChanged = "OnShopClassSelectChanged",
    OnSubShopSelectChanged = "OnSubShopSelectChanged",
    OnShopOpen = "OnShopOpen",
    OnBuyBackItemTimeOut = "OnBuyBackItemTimeOut",
    OnShopRedPointChanged = "OnShopRedPointChanged",

    -- 秘境相关
    OnDungeonTaskSelectChanged = "OnDungeonTaskSelectChanged",
    OnMapEnterInfoNotify = "OnMapEnterInfoNotify",
    OnMapEnterInfoNotifyList = "OnMapEnterInfoNotifyList",
    OnApplyPlayerSavedCopysRespond = "OnApplyPlayerSavedCopysRespond",
    OnResetMapRespond = "ON_RESET_MAP_RESPOND",
    OnDungeonFliterSelectChanged = "OnDungeonFliterSelectChanged",
    OnDungeonBossItemSelectChanged = "OnDungeonBossItemSelectChanged",
    OnDungeonDifficultySelectChanged = "OnDungeonDifficultySelectChanged",
    OnAuctionPreparation = "OnAuctionPreparation",
    OnEditAuctionRecord = "OnEditAuctionRecord",
    OnSalaryDataChanged = "OnSalaryDataChanged",
    OnSalaryDispatched = "OnSalaryDispatched",
    OnMonsterBookChooseLevelStep = "OnMonsterBookChooseLevelStep",
    OnMonsterBookLevelChange = "OnMonsterBookLevelChange",
    OnMonsterBookSelectTempSkillChange = "OnMonsterBookSelectTempSkillChange",
    OnSpiritEnduranceChanged = "OnSpiritEnduranceChanged",
    OnAuctionTagChanged = "OnAuctionTagChanged",
    OnAuctionLootListRedPointChanged = "OnAuctionLootListRedPointChanged",
    OnMonsterBookSchemeNameChange = "OnMonsterBookSchemeNameChange",

    -- 生活技艺相关
    OnManufactureTitleSelect = "OnManufactureTitleSelect",
    OnManufactureCellSelect = "OnManufactureCellSelect",
    OnBookItemSelect = "OnBookItemSelect",
    OnBookItemCellSelect = "OnBookItemCellSelect",
    OPEN_BOOK_NOTIFY = "OPEN_BOOK_NOTIFY",

    -- 小型设置弹窗相关
    OnMiniSettingAllUpdate = "OnMiniSettingAllUpdate",
    OnMiniSettingAllRefresh = "OnMiniSettingAllRefresh",
    OnMiniSettingRefreshButton = "OnMiniSettingRefreshButton",
    -- 剧情
    OnPlotChanged = "OnPlotChanged",
    OnSelectOptions = "OnSelectOptions",
    OnOpenChapters = "OnOpenChapters",
    OnQuestAwardPreview = "OnQuestAwardPreview",
    OnDialogChange = "OnDialogChange",
    OnDialogueDataReady = "OnDialogueDataReady",
    OnItemDataListReady = "OnItemDataListReady",
    OnStartNewQuestDialogue = "OnStartNewQuestDialogue",
    OnStartQiYuDialogue = "OnStartQiYuDialogue",
    OnSelectAward = "OnSelectAward",
    SelectAwardSuccess = "SelectAwardSuccess",
    CloseDialoguePanel = "CloseDialoguePanel",

    -- 组队
    OnRaidCellToggleSelected = "OnRaidCellToggleSelected",
    OnRaidCellToggleSelectedByPos = "OnRaidCellToggleSelectedByPos",
    OnRaidCellTouchMoved = "OnRaidCellTouchMoved",
    OnRaidCellTouchEnded = "OnRaidCellTouchEnded",
    OnRaidCellTouchCanceled = "OnRaidCellTouchCanceled",
    OnRaidReadyConfirmReceiveQuestion = "OnRaidReadyConfirmReceiveQuestion",
    OnRaidReadyConfirmReceiveAnswer = "OnRaidReadyConfirmReceiveAnswer",
    UpdateStartReadyConfirm = "UpdateStartReadyConfirm",
    UpdateMemberReadyConfirm = "UpdateMemberReadyConfirm",
    OnSelectedTaskTeamViewToggle = "OnSelectedTaskTeamViewToggle",
    OnTeamSelected = "OnTeamSelected",
    OnTeamVoiceForbided = "OnTeamVoiceForbided",
    OnEnableMainCityRaidMode = "OnEnableMainCityRaidMode",
    OnEnableMainCityTeamMode = "OnEnableMainCityTeamMode",
    StartEndWorldMark = "StartEndWorldMark",
    OnGetWorldMarkInfo = "OnGetWorldMarkInfo",
    UpdateMarkData    =  "UpdateMarkData",--动态技能球切换到标记

    -- 招募
    OnRecruitPushTeam = "OnRecruitPushTeam",
    OnSyncApplyPlayerList = "OnSyncApplyPlayerList",
    OnSyncPlayerApplyList = "OnSyncPlayerApplyList",
    OnRecruitUpdatePraise = "OnRecruitUpdatePraise",
    OnRecruitApplyCountUpdate = "OnRecruitApplyCountUpdate",
    OnRecruitLocate = "OnRecruitLocate",

    -- 房间
    OnRoomCellToggleSelectedByPos = "OnRoomCellToggleSelectedByPos",
    OnRoomCellTouchMoved = "OnRoomCellTouchMoved",
    OnRoomCellTouchEnded = "OnRoomCellTouchEnded",
    OnRoomCellTouchCanceled = "OnRoomCellTouchCanceled",
    OnSetMainCityRoom = "OnSetMainCityRoom",

    -- 商城
    OnCoinShopSearch = "OnCoinShopSearch",
    OnCoinShopLink = "OnCoinShopLink",
    OnCoinShopLinkTitle = "OnCoinShopLinkTitle",
    OnCoinShopLinkFace = "OnCoinShopLinkFace",
    OnCoinShopLinkHair = "OnCoinShopLinkHair",
    OnCoinShopLinkPendant = "OnCoinShopLinkPendant",
    OnCoinShopPreviewBoxLinkTitle = "OnCoinShopPreviewBoxLinkTitle",
    OnCoinShopClearTips = "OnCoinShopClearTips",
    OnCoinShopEnterReplaceOutfit = "OnCoinShopEnterReplaceOutfit",
    OnCoinShopCancelReplaceOutfit = "OnCoinShopCancelReplaceOutfit",
    OnCoinShopSelectedReplaceOutfit = "OnCoinShopSelectedReplaceOutfit",
    OnCoinShopEnterExteriorChangeColor = "OnCoinShopEnterExteriorChangeColor",
    OnCoinShopCancelExteriorChangeColor = "OnCoinShopCancelExteriorChangeColor",
    OnCoinShopEnterExteriorChangeHair = "OnCoinShopEnterExteriorChangeHair",
    OnCoinShopCancelExteriorChangeHair = "OnCoinShopCancelExteriorChangeHair",
    OnCoinShopShowItemTips = "OnCoinShopShowItemTips",
    OnCoinShopShowItemDetail = "OnCoinShopShowItemDetail",
    OnCoinShopClickBuyBtn = "OnCoinShopClickBuyBtn",
    OnCoinShopShowBuildFaceSideTog = "OnCoinShopShowBuildFaceSideTog",
    OnCoinShopFilterMutexChanged = "OnCoinShopFilterMutexChanged",
    OnCoinShopPreviewBoxLinkEffect = "OnCoinShopPreviewBoxLinkEffect",
    OnFinishLinkToFace = "OnFinishLinkToFace",

    OnCoinShopWardrobeUpdateHairList = "OnCoinShopWardrobeUpdateHairList",
    OnCoinShopWardrobeUpdateBodyList = "OnCoinShopWardrobeUpdateBodyList",
    OnCoinShopWardrobeUpdateNewFaceList = "OnCoinShopWardrobeUpdateNewFaceList",
    OnCoinShopWardrobeUpdateFaceList = "OnCoinShopWardrobeUpdateFaceList",
    OnCoinShopStartBuildHairDye = "OnCoinShopStartBuildHairDye",

    OnRewardsDrawGetCoin = "OnRewardsDrawGetCoin",
    OnRewardsDrawGetRewardsList = "OnRewardsDrawGetRewardsList",
    OnCoinShopDrawStorageUpdate = "OnCoinShopDrawStorageUpdate",
    OnCoinShopCustomPendantOpenClose = "OnCoinShopCustomPendantOpenClose",
    OnCoinShopHairDyeCaseOpenClose = "OnCoinShopHairDyeCaseOpenClose",
    OnCoinShopRecommendOpenClose = "OnCoinShopRecommendOpenClose",
    OnCoinShopOpenRecommend = "OnCoinShopOpenRecommend",
    OnCoinShopCustomPendantDataChanged = "OnCoinShopCustomPendantDataChanged",
    OnCoinShopLayoutPetUpdate = "OnCoinShopLayoutPetUpdate",
    OnCoinShopListSizeChanged = "OnCoinShopListSizeChanged",

    OnCoinShopSetEffectTogSelected = "OnCoinShopSetEffectTogSelected",

    OnEquipPakResourceDownload = "OnEquipPakResourceDownload",

    ON_UPDATE_EXTERIOR_NEW = "ON_UPDATE_EXTERIOR_NEW",
    ON_UPDATE_WEAPON_EXTERIOR_NEW = "ON_UPDATE_WEAPON_EXTERIOR_NEW",
    ON_UPDATE_PENDANT_PET_NEW = "ON_UPDATE_PENDANT_PET_NEW",
    ON_UPDATE_HAIR_NEW = "ON_UPDATE_HAIR_NEW",
    ON_UPDATE_FACE_NEW = "ON_UPDATE_FACE_NEW",
    ON_UPDATE_BODY_NEW = "ON_UPDATE_BODY_NEW",

    CoinShopSchoolExteriorUpdateFissionInfo = "CoinShopSchoolExteriorUpdateFissionInfo",

    -- 地图排队
    OnClearMapQueue = "OnClearMapQueue",
    OnMapQueueDataUpdate = "OnMapQueueDataUpdate",
    OnBigBattleQueueActivityChanged = "OnBigBattleQueueActivityChanged",

    -- 奇遇
    OnGetCurrentAdventureInfo = "OnGetCurrentAdventureInfo",
    OnGetAdventurePetTryBook = "OnGetAdventurePetTryBook",
    OnSelectAdventureTryBookCell = "OnSelectAdventureTryBookCell",

    -- 绝境战场
    OnTreasureBattleFieldHideTime = "OnTreasureBattleFieldHideTime",
    OnTreasureBattleFieldHideInfoBar = "OnTreasureBattleFieldHideInfoBar",
    OnTreasureBattleFieldHidePlayerNum = "OnTreasureBattleFieldHidePlayerNum",
    OnTreasureBattleFieldUpdateFrameTime = "OnTreasureBattleFieldUpdateFrameTime",
    OnTreasureBattleFieldUpdateInfoBar = "OnTreasureBattleFieldUpdateInfoBar",
    OnTreasureBattleFieldUpdateFramePlayerNum = "OnTreasureBattleFieldUpdateFramePlayerNum",
    UpdateTreasureBattleFieldActionBar = "UpdateTreasureBattleFieldActionBar",
    UpdateTreasureBattleFieldSkin = "UpdateTreasureBattleFieldSkin",
    ShowTreasureBattleFieldHint = "ShowTreasureBattleFieldHint",
    ShowTreasureBattleFieldPlayerNumHint = "ShowTreasureBattleFieldPlayerNumHint",
    UpdateTreasureBattleFieldRoomInfo = "UpdateTreasureBattleFieldRoomInfo",

    OnEnterTreasureBattleFieldDynamic = "OnEnterTreasureBattleFieldDynamic",
    OnLeaveTreasureBattleFieldDynamic = "OnLeaveTreasureBattleFieldDynamic",
    OnUpdateTreasureBattleFieldSkill = "OnUpdateTreasureBattleFieldSkill",

    OnOpenActionBar = "OnOpenActionBar",
    OnCloseActionBar = "OnCloseActionBar",
    OnActionBarSwitchState = "OnActionBarSwitchState",
    OnActionBarBtnClick = "OnActionBarBtnClick",

    -- 竞技场相关
    OnArenaStateUpdate          = "OnArenaStateUpdate",
    OnArenaPlayerUpdate         = "ON_ARENA_PLAYER_UDPATE",
    OnArenaEventNotify          = "OnArenaEventNotify",
    OnArenaClickRewardItem      = "OnArenaClickRewardItem",
    OnArenaFinishDataReport     = "OnArenaFinishDataReport",
    OnArenaFinishDataReportSwitch = "OnArenaFinishDataReportSwitch",
    OnUpdateArenaSeasonHighestRankScore = "OnUpdateArenaSeasonHighestRankScore",
    OnUpdateArenaFinishDataFriendPraiseList = "OnUpdateArenaFinishDataFriendPraiseList",
    OnUpdateArenaRedPoint = "OnUpdateArenaRedPoint",

    -- 扬刀大会相关
    OnShowBlessDetailDesc = "OnShowBlessDetailDesc",
    OnArenaTowerOverviewMapScale = "OnArenaTowerOverviewMapScale",
    OnArenaTowerOverviewLevelDetail = "OnArenaTowerOverviewLevelDetail",
    OnArenaTowerReport = "OnArenaTowerReport",
    OnTogArenaTowerElementInfo = "OnTogArenaTowerElementInfo",
    OnArenaTowerDataUpdate = "OnArenaTowerDataUpdate",
    OnArenaTowerDiffProgressUpdate = "OnArenaTowerDiffProgressUpdate",
    OnArenaTowerApplyMemberRemoteData = "OnArenaTowerApplyMemberRemoteData",
    OnArenaTowerPlayerUpdate = "OnArenaTowerPlayerUpdate",
    OnArenaTowerUpdateRoundState = "OnArenaTowerUpdateRoundState",
    OnArenaTowerUpdateLevelInfo = "OnArenaTowerUpdateLevelInfo",
    OnArenaTowerCardEventAniEnd = "OnArenaTowerCardEventAniEnd",
    UpdateArenaTowerActionBar = "UpdateArenaTowerActionBar",

    --活动
    OnActivitySelect = "OnActivitySelect",
    OnSelectLeaveForBtn = "OnSelectLeaveForBtn",

    --声望
    OnUpdateReputationRank = "OnUpdateReputationRank",
    OnRenownRewordOpen = "OnRenownRewordOpen",
    --科举
    OnSelectQuestion = "OnSelectQuestion",
    OnSelectAnswer = "OnSelectAnswer",

    -- 聊天
    OnReceiveChat = "OnReceiveChat",
    OnSelectChatViewChannel = "OnSelectChatViewChannel",
    OnChatViewChannelChanged = "OnChatViewChannelChanged",
    OnChatSettingChanged = "OnChatSettingChanged",
    OnChatSettingSaved = "OnChatSettingSaved",
    OnChatSettingSyncServerData = "OnChatSettingSyncServerData",
    OnChatEmojiSelected = "OnChatEmojiSelected",
    OnChatEmojiClosed = "OnChatEmojiClosed",
    OnChatEmojiGroupSelected = "OnChatEmojiGroupSelected",
    OnChatWhisperSelected = "OnChatWhisperSelected",
    OnChatWhisperDeleted = "OnChatWhisperDeleted",
    OnChatAINpcSelected = "OnChatAINpcSelected",
    OnChatAINpcDeleted = "OnChatAINpcDeleted",
    OnChatAINpcWaiting = "OnChatAINpcWaiting",
    OnChatAINpcFiltering = "OnChatAINpcFiltering",
    OnChatAINpcUnReadChange = "OnChatAINpcUnReadChange",
    OnChatAINpcFetchDoneChange = "OnChatAINpcFetchDoneChange",
    OnChatContentCopy = "OnChatContentCopy",
    OnChatWhisperUnreadAdd = "OnChatWhisperUnreadAdd",
    OnChatWhisperUnreadRemove = "OnChatWhisperUnreadRemove",
    OnChatMiniChannelSelected = "OnChatMiniChannelSelected",
    OnChatSendChannelChanged = "OnChatSendChannelChanged",
    OnChatVoiceRecordSuccessed = "OnChatVoiceRecordSuccessed",
    OnChatVoiceRecordFailed = "OnChatVoiceRecordFailed",
    OnChatVoicePlaySuccessed = "OnChatVoicePlaySuccessed",
    OnChatVoicePlayFailed = "OnChatVoicePlayFailed",
    OnChatVoiceDownloadSuccessed = "OnChatVoiceDownloadSuccessed",
    OnChatVoiceDownloadFailed = "OnChatVoiceDownloadFailed",
    OnChatVoiceUploadSuccessed = "OnChatVoiceUploadSuccessed",
    OnChatVoiceUploadFailed = "OnChatVoiceUploadFailed",
    OnChatVoiceToTexSuccessed = "OnChatVoiceToTexSuccessed",
    OnChatVoiceToTextFailed = "OnChatVoiceToTextFailed",
    OnChatEmojiAdd = "OnChatEmojiAdd",
    OnChatEmojiRemove = "OnChatEmojiRemove",
    OnChatUIChannelNicknameChanged = "OnChatUIChannelNicknameChanged",
    OnChatSyncMiniChat = "OnChatSyncMiniChat",
    OnChatWhisperNameChanged = "OnChatWhisperNameChanged",
    OnChatHintMsgUpdate = "OnChatHintMsgUpdate",
    OnChatAutoShoutSettingUpdate = "OnChatAutoShoutSettingUpdate",
    OpenAutoShoutSettingView = "OpenAutoShoutSettingView",
    OnSkillShoutSaved = "OnSkillShoutSaved",
    OnChatGameGuideSelected = "OnChatGameGuideSelected",
    OnChatRecentWhisperUnreadAdd = "OnChatRecentWhisperUnreadAdd",
    OnChatRecentWhisperUnreadRemove = "OnChatRecentWhisperUnreadRemove",
    OnChatWhisperMiBaoUnLockSuccessed = "OnChatWhisperMiBaoUnLockSuccessed",
    OnChatMengXinShow = "OnChatMengXinShow",
    OnChatBulletSettingUpdate = "OnChatBulletSettingUpdate",

    --战斗数据统计
    SwitchStatistVisibility = "SwitchStatistVisibility",
    SwitchFocusVisibility = "SwitchFocusVisibility",
    SwitchWhoSeeMeVisibility = "SwitchWhoSeeMeVisibility",

    --师徒
    OnClearSelectedState = "OnClearSelectedState",
    OnSelectChangedMentor = "OnSelectChangedMentor",
    OnSelectedPlayerMessage = "OnSelectedPlayerMessage",
    MentorActivityDetail = "MentorActivityDetail",
    OnShowFriendGroup = "OnShowFriendGroup",
    OnUpdateMentorOnlineInfo = "OnUpdateMentorOnlineInfo",
    OnUpdateMentorOfflineInfo = "OnUpdateMentorOfflineInfo",
    OnUpdateFellowShip = "OnUpdateFellowShip",
    OnSelectedAppprenticeMessage = "OnSelectedAppprenticeMessage",
    OnMentorRecall = "OnMentorRecall",
    OnUpdateMentorRedpoint = "OnUpdateMentorRedpoint",

    --系统设置
    OnGameSettingsSliderChange = "OnGameSettingsSliderChange",
    OnGameSettingsTogSelectChange = "OnGameSettingsTogSelectChange",
    OnGameSettingsKeyboardChange = "OnGameSettingsKeyboardChange",
    OnGameSettingsKeyboardReset = "OnGameSettingsKeyboardReset",
    OnGameSettingsGamepadChange = "OnGameSettingsGamepadChange",
    OnGameSettingsGamepadReset = "OnGameSettingsGamepadReset",
    OnQualitySettingChange = "OnQualitySettingChange",
    OnEngineQualityLevelChange = "OnEngineQualityLevelChange",  -- 引擎的画质等级参数修改
    OnSprintSettingChange = "OnSprintSettingChange",
    OnJoystickSettingChange = "OnJoystickSettingChange",
    OnShowNpcHeadBalloon = "OnShowNpcHeadBalloon", -- 调出NPC头顶对话
    OnShowCharacterHeadBuff = "OnShowCharacterHeadBuff", -- 副本内显示头顶Buff
    OnHideCharacterHeadBuff = "OnHideCharacterHeadBuff", -- 隐藏副本内显示头顶Buff
    OnShowSpecialEnhanceBuff = "OnShowSpecialEnhanceBuff", -- 隐藏副本内显示头顶Buff
    SetNpcHeadBallonVisible = "SetNpcHeadBallonVisible", -- 显示或隐藏NPC头顶对话
    OnGameSettingDiscardRes = "OnGameSettingDiscardRes",
    OnGameSettingDiscardResSelected = "OnGameSettingDiscardResSelected",
    OnGameSettingPlayDisplayChanged = "OnGameSettingPlayDisplayChanged",
    OnGameSettingViewUpdate = "OnGameSettingViewUpdate",
    OnActorTypeVolumeSliderChange = "OnActorTypeVolumeSliderChange",
    OnGameSettingDisplaySystemAnnouncement = "OnGameSettingDisplaySystemAnnouncement",
    OnGameSettingShowDoodadName = "OnGameSettingShowDoodadName",    -- 是否显示可采集doodad的名字
    OnMultiTogPopRefresh = "OnMultiTogPopRefresh",
    OnBeforeStoreNewSetting = "OnBeforeStoreNewSetting",
    OnAfterStoreNewSetting = "OnAfterStoreNewSetting",
    OnShowArenaTopBuff = "OnShowArenaTopBuff",
    OnHideArenaTopBuff = "OnHideArenaTopBuff",
    OnTopBuffSetting = "OnTopBuffSetting",

    OnUpdateGaibangComboVisible = "OnUpdateGaibangComboVisible",

    --自动战斗
    OnAutoBattleStateChanged = "OnAutoBattleStateChanged",

    --花萼楼
    On_Recharge_CheckRFirstCharge_CallBack = "On_Recharge_CheckRFirstCharge_CallBack",
    On_Recharge_GetRFirstChargeRwd_CallBack = "On_Recharge_GetRFirstChargeRwd_CallBack",
    OnSelectItem = "OnSelectItem",
    OnEnterBattlePassQuestPanel = "OnEnterBattlePassQuestPanel",
    OnExitBattlePassQuestPanel = "OnExitBattlePassQuestPanel",

    -- 充值
    OnSyncRechargeInfo = "OnSyncRechargeInfo",

    --动态技能
    ON_CHANGE_DYNAMIC_SKILL_GROUP = "ON_CHANGE_DYNAMIC_SKILL_GROUP",
    ON_DYNAMIC_BUTTON_HIGHLIGHT = "ON_DYNAMIC_BUTTON_HIGHLIGHT",
    ON_QTEPANEL_SHOW = "ON_QTEPANEL_SHOW",
    FIRST_ENTER_NORMAL_DYNAMIC = "FIRST_ENTER_NORMAL_DYNAMIC",
    ON_ENTER_HIDE_ACTION_DYNAMIC_SKILL = "ON_ENTER_HIDE_ACTION_DYNAMIC_SKILL",
    ON_DYNAMIC_SKILL_CHANGE = "ON_DYNAMIC_SKILL_CHANGE",

    -- 新手教学
    OnTeachNodeClicked = "OnTeachNodeClicked",
    OnTeachAnyClicked = "OnTeachAnyClicked",
    OnSkipCurTeach = "OnSkipCurTeach",
    OnTeachButtonClick = "OnTeachButtonClick",
    OnTeachButtonShow = "OnTeachButtonShow",
    OnSearchTeachBox = "OnSearchTeachBox",

    OnTeachStart = "OnTeachStart",
    OnTeachAction = "OnTeachAction",
    OnTeachClose = "OnTeachClose",
    OnTeachComplete = "OnTeachComplete",
    OnOpenTeachView = "OnOpenTeachView",
    OnCloseTeachView = "OnCloseTeachView",
    OnHideTeachView = "OnHideTeachView",
    OnShowTeachView = "OnShowTeachView",

    OnCloseItemTeach = "OnCloseItemTeach",

    -- 交互列表变化
    OnInteractListUpdate = "OnInteractListUpdate",
    OnShowNpcSpeechSoundsBalloon = "OnShowNpcSpeechSoundsBalloon",
    OnInteractChangeVisible = "OnInteractChangeVisible",
    OnRightButtonInteract = "OnRightButtonInteract",
    CloseLootList = "CloseLootList",

    --帮会
    TongGroupSelectPeople = "TongGroupSelectPeople",
    TongGroupSelectPermission = "TongGroupSelectPermission",
    TongClickOpenActivity = "TongClickOpenActivity",

    SwitchFactionSpecificActivityShowStatus = "SwitchFactionSpecificActivityShowStatus",
    OnClickBtnFactionActivityDetailReturn = "OnClickBtnFactionActivityDetailReturn",

    SetKeyBoardEnable = "SetKeyBoardEnable",
    SetKeyBoardEnableByCustomState = "SetKeyBoardEnableByCustomState",
    SetShortcutEnable = "SetShortcutEnable",
    SetKeyBoardGameSettingEnable = "SetKeyBoardGameSettingEnable",
    SetGamepadGameSettingEnable = "SetGamepadGameSettingEnable",
    SetJoyStickEnable = "SetJoyStickEnable",
    OnGamepadJoyStickMove = "OnGamepadJoyStickMove",
    OnGamepadCameraRotateStart = "OnGamepadCameraRotateStart",
    OnGamepadCameraRotateEnd = "OnGamepadCameraRotateEnd",
    OnGamepadTypeChanged = "OnGamepadTypeChanged",
    OnGamepadKeyExecute = "OnGamepadKeyExecute",
    SetGamepadEnable = "SetGamepadEnable",

    OnJoyStickStart = "OnJoyStickStart",
    OnJoyStickEnd = "OnJoyStickEnd",
    OnHomelandJoyStickStart = "OnHomelandJoyStickStart",
    OnHomelandJoyStickEnd = "OnHomelandJoyStickEnd",

    OnShortcutInteractionChange = "OnShortcutInteractionChange",
    OnMainViewButtonSlotClick = "OnMainViewButtonSlotClick",
    OnSceneInteractByHotkey = "OnSceneInteractByHotkey",
    OnShortcutUseSkillSelect = "OnShortcutUseSkillSelect",
    OnShortcutTargetSelect = "OnShortcutTargetSelect",
    OnShortcutSwitchSkill = "OnShortcutSwitchSkill",
    OnShortcutSkillAuto = "OnShortcutSkillAuto",
    OnShortcutAttention= "OnShortcutAttention",
    OnShortcutSkillQuick = "OnShortcutSkillQuick",
    OnShortcutUseQuickItem = "OnShortcutUseQuickItem",
    OnShortcutSwitchPageSkill = "OnShortcutSwitchPageSkill",

    OnSwitchQuickUseTip = "OnSwitchQuickUseTip",
    OnQuickUseListChanged = "OnQuickUseListChanged",
    OnQuickUseListCfgEnd = "OnQuickUseListCfgEnd",
    OnQuickUseSuccess = "OnQuickUseSuccess",
    OnSkillSlotQuickUseChange = "OnSkillSlotQuickUseChange",
    OnQuickUseAddItemChanged = "OnQuickUseAddItemChanged",

    --道具格子
    OnClearUICommonItemSelect = "OnClearUICommonItemSelect",
    OnClearUIItemIconSelect = "OnClearUIItemIconSelect",
    OnSetUIItemIconChoose = "OnSetUIItemIconChoose",
    OnLeftBagSelectItem = "OnLeftBagSelectItem", --通用左侧边栏背包PanelLeftBag
    OnGuideItemSource = "OnGuideItemSource", --Content10TraceCell 获取途径导航
    OnClickMultUseBtn = "OnClickMultUseBtn",
    OnBagRowRecycled = "OnBagRowRecycled",
    OnShowIteminfoLinkTips = "OnShowIteminfoLinkTips",
    OnBoxSelectChanged = "OnBoxSelectChanged",
    OnBoxLockChanged = "OnBoxLockChanged",

    --背包
    OnItemSortEnd = "OnItemSortEnd",
    OnBagViewOpen = "OnBagViewOpen",
    OnCurrencyChange = "OnCurrencyChange",
    OnWareHouseUseExpandItem = "OnWareHouseUseExpandItem",

    --阵营
    OnUpdateCampRewardTips = "OnUpdateCampRewardTips",
    OnCampWarStateChanged = "OnCampWarStateChanged",
    OnCameInfoUpdate = "OnCameInfoUpdate",
    OnUpdateRankEntrance = "OnUpdateRankEntrance",

    --阵营管理
    AddMemberToRemoveList = "AddMemberToRemoveList",
    RemoveMemberFromRemoveList = "RemoveMemberFromRemoveList",
    OnBatchAddPlayer = "OnBatchAddPlayer",
    OnBatchAddFaction = "OnBatchAddFaction",
    On_Camp_GFGetCampInTong = "On_Camp_GFGetCampInTong",

    --公共任务
    On_PQ_RequestDataReturn = "On_PQ_RequestDataReturn",

    --家园订单
    OnHomeOrderSelectedCell = "OnHomeOrderSelectedCell",
    OnHomeOrderSelectedCellIndex = "OnHomeOrderSelectedCellIndex",
    OnGetTongOrder = "OnGetTongOrder",
    OnSubmitHomelandOrder = "OnSubmitHomelandOrder",
    OnHomelandOrderUpdate = "OnHomelandOrderUpdate",

    --家园身份
    OnHomeIdentityOpenDetailsPop = "OnHomeIdentityOpenDetailsPop",
    OnHomeIdentityCloseDetailsPop = "OnHomeIdentityCloseDetailsPop",
    OnHomeIdentityOpenTips = "OnHomeIdentityOpenTips",
    OnHomeGetPerfumeMaterialInfo = "OnHomeGetPerfumeMaterialInfo",
    OnPerfumeGetAwardResult = "OnPerfumeGetAwardResult",
    OnPrefumeAddMaterial = "OnPrefumeAddMaterial",
    OnFoodCartUpdateFoodList = "OnFoodCartUpdateFoodList",
    OnFoodCartOpenDetailPop = "OnFoodCartOpenDetailPop",
    OnFoodCartSelectEmptyFood = "OnFoodCartSelectEmptyFood",
    OnFishNoteOpenDetailPop = "OnFishNoteOpenDetailPop",
    OnFishDealOpenFishTips = "OnFishDealOpenFishTips",
    OnUpdateFishNoteHolderInfo = "OnUpdateFishNoteHolderInfo",
    OnGetFishGainRecordTips = "OnGetFishGainRecordTips",
    OnUpdateFishBagInfo = "OnUpdateFishBagInfo",
    OnFishHooked = "OnFishHooked",
    OnGetFishTips = "OnGetFishTips",

    --家园 外部
    OnSelectHomelandMainPage = "OnSelectHomelandMainPage",
    OnSelectHomelandMyHomeArea = "OnSelectHomelandMyHomeArea",
    OnSelectHomelandMyHomeMap = "OnSelectHomelandMyHomeMap",
    OnUpdateHomelandMyHomeRankList = "OnUpdateHomelandMyHomeRankList",
    OnClickHomelandMyHomeRankListIndex = "OnClickHomelandMyHomeRankListIndex",
    OnReInitHomelandCenterID = "OnReInitHomelandCenterID",
    OnUpdateHomelandLandInfo = "OnUpdateHomelandLandInfo",
    OnHomeMessageBoardSelectAllMsg = "OnHomeMessageBoardSelectAllMsg",
    OnHomeMessageBoardChooseMsg = "OnHomeMessageBoardChooseMsg",
    OnHomeMessageBoardDeleteMsg = "OnHomeMessageBoardDeleteMsg",
    OnHomeMessageBoardSendMsg = "OnHomeMessageBoardSendMsg",
    OnHomelandGroupBuySelectMember = "OnHomelandGroupBuySelectMember",
    OnHomelandGroupBuyInviteFriend = "OnHomelandGroupBuyInviteFriend",
    OnHomelandShowSetRedDot = "OnHomelandShowSetRedDot",

    --家园 内部
    OnUpdateHomelandEntranceState = "OnUpdateHomelandEntranceState", -- Params[bShow]
    OnUpdateHomelandFurnitureList = "OnUpdateHomelandFurnitureList",
    OnGotoHomelandFurnitureListOneItem = "OnGotoHomelandFurnitureListOneItem",
    OnSelectedHomelandBuildErrorListCell = "OnSelectedHomelandBuildErrorListCell",
    OnChangeHomelandBuildCustomBrushData = "OnChangeHomelandBuildCustomBrushData",
    OnUpdateHomelandBuildInteractionListData = "OnUpdateHomelandBuildInteractionListData",
    OnSelectedHomelandBuildInteractionListCell = "OnSelectedHomelandBuildInteractionListCell",
    OnSelectedHomelandBuildExchangeListCell = "OnSelectedHomelandBuildExchangeListCell",
    OnSelectCustomBrushFloorItem = "OnSelectCustomBrushFloorItem",
    OnStartBuyFurniture = "OnStartBuyFurniture",
    OnHomelandAddBuildCD = "OnHomelandAddBuildCD",
    OnHomeLandBuildResponseKey = "OnHomeLandBuildResponseKey",

    OnHomelandEnterMultiChoose = "OnHomelandEnterMultiChoose",
    OnHomelandExitMultiChoose = "OnHomelandExitMultiChoose",
    OnHomelandBuildTypeTog = "OnHomelandBuildTypeTog",
    OnHomelandMultiSelectEnd = "OnHomelandMultiSelectEnd",
    OnHomelandResetCameraMode = "OnHomelandResetCameraMode",
    OnHomeWarehouseUpdate = "OnHomeWarehouseUpdate",
    OnSelelctHLWarehouseFilter = "OnSelelctHLWarehouseFilter",
    OnCloseHomelandLocker = "OnCloseHomelandLocker",

    OnWarehouseFilterTextUpdate = "OnWarehouseFilterTextUpdate",
    OnWarehouseDragEnd = "OnWarehouseDragEnd",
    OnWarehouseExpireItemUpdate = "OnWarehouseExpireItemUpdate",
    OnWarehouseCancelTouch = "OnWarehouseCancelTouch",
    OnBankBagCompareUpdate = "OnBankBagCompareUpdate",
    OnWareHouseBatchNumberChange = "OnWareHouseBatchNumberChange",
    --OnWareHouseBatchStateUpdate = "OnWareHouseBatchStateUpdate",

    GetHomelandServantItemTab = "GetHomelandServantItemTab",

    OnSelectedHouseKeeperSkillCell = "OnSelectedHouseKeeperSkillCell",
    OnSelectedHouseKeeperChangeSkillCell = "OnSelectedHouseKeeperChangeSkillCell",
    OnUpdateHouseKeeperData = "OnUpdateHouseKeeperData",

    OnSelectedHomelandInteractItemCell = "OnSelectedHomelandInteractItemCell",
    OnUpdateHomelandInteractItemData = "OnUpdateHomelandInteractItemData",

    OnUpdateHLWebBlueprintList = "OnUpdateHLWebBlueprintList",
    OnSelectUploadBlueprintTagCell = "OnSelectUploadBlueprintTagCell",
    OnChoiceBlueprintCell = "OnChoiceBlueprintCell",

    OnTryTransferToFurniture = "OnTryTransferToFurniture",

    OnClickOverviewActivityCell = "OnClickOverviewActivityCell",
    OnEnterOverviewRewardList = "OnEnterOverviewRewardList",
    OnExitOverviewRewardList = "OnExitOverviewRewardList",
    OnClearOverviewRewardListSelected = "OnClearOverviewRewardListSelected",
    OnHomelandIdentityUpdate = "OnHomelandIdentityUpdate",

    OnSelectedHomeCollectionLaunchTog = "OnSelectedHomeCollectionLaunchTog", --点击庐园广记左侧子Toggle
    OnSelectedHomeCollectionSellFurniture = "OnSelectedHomeCollectionSellFurniture", --点击庐园广记右侧选择家具购买
    OnClickHomeCollectionLikeSetTog = "OnClickHomeCollectionLikeSetTog", --点击庐园广记收藏按钮

    OnHomeAchievementRightPopOpen = "OnHomeAchievementRightPopOpen", --结庐江湖右侧弹窗
    OnHomeAchievementInput = "OnHomeAchievementInput",
    OnHomeAchievementToAward = "OnHomeAchievementToAward", --结庐江湖领奖
    --交易行
    OnBusinessTypeInfoUpdate = "OnBusinessTypeInfoUpdate",--界面左边的物品类别信息
    ON_NORMAL_LOOK_UP_RES = "ON_NORMAL_LOOK_UP_RES",--搜索物品的结果
    ON_SELL_LOOK_UP_RES = "ON_SELL_LOOK_UP_RES",--我上架的物品
    ON_PRICE_LOOK_UP = "ON_PRICE_LOOK_UP",
    ON_AVG_LOOK_UP_RES = "ON_AVG_LOOK_UP_RES",
    OnSelectGoodsForSale = "OnSelectGoodsForSale",--勾选待售物品
    ON_AUCTION_SELL_SUCCESS = "ON_AUCTION_SELL_SUCCESS",--重新上架成功
    OnSelectPriceListCell = "OnSelectPriceListCell",--点击价格填充
    ON_AUCTION_CANCEL_RESPOND = "ON_AUCTION_CANCEL_RESPOND",--下架物品成功
    ON_DETAIL_LOOK_UP = "ON_DETAIL_LOOK_UP",
    ON_AUCTION_BID_RESPOND = "ON_AUCTION_BID_RESPOND",
    ON_SHOW_TRADE_ITEM_CELL_TIP = "ON_SHOW_TRADE_ITEM_CELL_TIP",--显示待售物品或购买物品列表tip
    ON_AUCTION_BUY_RESPOND = "ON_AUCTION_BUY_RESPOND",
    ON_AUCTION_SELL_RESPOND = "ON_AUCTION_SELL_RESPOND",
    -- ON_BM_LOOKUP_SUCCEED = "ON_BM_LOOKUP_SUCCEED",
    OnSearchItemClose = "OnSearchItemClose",
    OnBuyItemClose = "OnBuyItemClose",
    OnApplyBuyItem = "OnApplyBuyItem",
    OnApplySellItem = "OnApplySellItem",
    -- OnEditItemPriceClose = "OnEditItemPriceClose",

    --阵营、活动拍卖
    OnAuctionStateChanged = "OnAuctionStateChanged",

    -- 副本拍卖
    OnRollItemTimeOut = "OnRollItemTimeOut",
    OnLootInfoChanged = "OnLootInfoChanged",
    OnLootInfoTimeOut = "OnLootInfoTimeOut",

    -- 百战异闻录
    OnEnterMonsterBookScene = "OnEnterMonsterBookScene",
    OnExitMonsterBookScene = "OnExitMonsterBookScene",
    OnMonsterBookSkillChanged = "OnMonsterBookSkillChanged",
    OnMonsterBookSkillSurfaceNumChanged = "OnMonsterBookSkillSurfaceNumChanged",

    --试炼之地
    OnOpenTestPlaceInfoPop = "OnOpenTestPlaceInfoPop",
    OnChangeCellState = "OnChangeCellState",
    OnChangeCardState = "OnChangeCardState",

    -- 主界面消息按钮
    OnUpdateMessageBtnInfo = "OnUpdateMessageBtnInfo",

    -- 唐门飞星
    OnTangMenHiddenChanged = "OnTangMenHiddenChanged",

    -- DX团队标记
    OnDXTeamMarkChanged = "OnDXTeamMarkChanged",

    -- DX药宗植物
    OnDXYaoZongPlantChanged = "OnDXYaoZongPlantChanged",

    --宠物相关
    OnSelectPet = "OnSelectPet",
    OnAddOrDelectPreferFellowPet = "OnAddOrDelectPreferFellowPet",
    OnSelectPetMedal = "OnSelectPetMedal",

    On_Activity_FlopCardReturn = "On_Activity_FlopCardReturn",
    On_Trial_OpenCProcess = "On_Trial_OpenCProcess",
    On_Trial_CloseCProcess = "On_Trial_CloseCProcess",
    On_Trial_FlopCardReturn = "On_Trial_FlopCardReturn",
    On_Trial_InitCChooseReturn = "On_Trial_InitCChooseReturn",

    --浪客行
    OnSelectTogGroupLeft = "OnSelectTogGroupLeft",

    --开关寻宝罗盘
    OnTogCompass = "OnTogCompass",
    OnCompassStateChanged = "OnCompassStateChanged",

    -- 动态信息Tip
    OnTogActivityTip = "OnTogActivityTip",
    OnActivityTipUpdate = "OnActivityTipUpdate",

    -- 左侧Widget内容显示
    OnSetTraceInfoPriority = "OnSetTraceInfoPriority",
    OnTogTraceInfo = "OnTogTraceInfo",
    OnUpdateTraceInfoRedPoint = "OnUpdateTraceInfoRedPoint",

    -- 菜单
    OnSetSystemMenuCloseBtnEnabled = "OnSetSystemMenuCloseBtnEnabled",

    -- 侠客
    UpdatePartnerMorphShowState = "UpdatePartnerMorphShowState",
    ShowPartnerMorph = "ShowPartnerMorph",
    HidePartnerMorph = "HidePartnerMorph",
    OnPartnerNpcListChanged = "OnPartnerNpcListChanged",
    OpenPartnerSummonPanelForSummon = "OpenPartnerSummonPanelForSummon",
    On_Partner_TankAttack = "On_Partner_TankAttack",

    On_Update_GeneralProgressBar = "On_Update_GeneralProgressBar",
    On_Delete_GeneralProgressBar = "On_Delete_GeneralProgressBar",

    On_TimeBuffData_Update = "On_TimeBuffData_Update",
    OnSelfieCameraSettingExit = "OnSelfieCameraSettingExit",
    OnSelfieServantCellSelect = "OnSelfieServantCellSelect",
    OnSelfieStuidoCellSelect = "OnSelfieStuidoCellSelect",

    -- 设置
    OnPlayerSettingChange = "OnPlayerSettingChange",
    OnTargetSettingChange = "OnTargetSettingChange",
    OnBattleInfoSettingChange = "OnBattleInfoSettingChange",
    OnTargetBossManaBarChange = "OnTargetBossManaBarChange",

    OnFengYunLuDisableArrow = "OnFengYunLuDisableArrow",

    OnSetUIScene = "OnSetUIScene",

    OnFilter = "OnFilter",
    OnFilterSelectChanged = "OnFilterSelectChanged",
    OnSelfieServantChange = "OnSelfieServantChange",
    SelfieCameraFocusOpen = "SelfieCameraFocusOpen",
    SelfieEyeFocusOpen = "SelfieEyeFocusOpen",
    OnCameraCaptureStateChanged = "OnCameraCaptureStateChanged",

    CloseSubOrSeriesAchievement = "CloseSubOrSeriesAchievement",
    CloseAchievementCategoryDetail = "CloseAchievementCategoryDetail",

    --制作人员名单
    OnSelectVersion = "OnSelectVersion",

    --家园麻将
    OnUpdatePlayerInfo = "OnUpdatePlayerInfo",
    UpdateMyCards = "UpdateMyCards",
    OnGameStart = "OnGameStart",
    OnSwapOutCardResult = "OnSwapOutCardResult",
    OnSwapInCardResult = "OnSwapInCardResult",
    StartSelectionLackType = "StartSelectionLackType",
    LackTypeResult = "LackTypeResult",
    GainCard = "GainCard",
    DisCardResult = "DisCardResult",
    OnUpdateTime = "OnUpdateTime",
    OperatePongKongWin = "OperatePongKongWin",
    PongResult = "PongResult",
    KongResult = "KongResult",
    WinResult = "WinResult",
    PassCardResult = "PassCardResult",
    SyncGradeOrHonor = "SyncGradeOrHonor",
    SyncGameState = "SyncGameState",
    OnSetPlayerCardInfo = "OnSetPlayerCardInfo",
    OnAgentStateChange = "OnAgentStateChange",
    OnChangeCard = "OnChangeCard",
    GameOver = "GameOver",
    OnClearGameData = "OnClearGameData",
    OnSelectMyHandCard = "OnSelectMyHandCard",
    SyncDisconnectedData = "SyncDisconnectedData",
    MultipleWinResult = "MultipleWinResult",

    OnPrefabAdd = "OnPrefabAdd",

    --幻境云图
    OpenCameraPanel = "OpenCameraPanel",
    EnterSelfieMode = "EnterSelfieMode",    -- 进入/离开环境云图模式
    OnSetWindData = "OnSetWindData",
    OnSetLightData = "OnSetLightData",
    OnSetBaseData = "OnSetBaseData",
    OnSetFilterData = "OnSetFilterData",
    OnActionDataUseState = "OnActionDataUseState",

    -- UIScrollList
    OnUIScrollListTouchBegan = "OnUIScrollListTouchBegan",
    OnUIScrollListTouchMove = "OnUIScrollListTouchMove",
    OnUIScrollListTouchEnd = "OnUIScrollListTouchEnd",
    OnUIScrollListScroll = "OnUIScrollListScroll",
    OnUIScrollListMouseWhell = "OnUIScrollListMouseWhell",
    OnUIScrollListAddCell = "OnUIScrollListAddCell",

    -- MiniScene
    OnMiniSceneLoadProgress = "OnMiniSceneLoadProgress",

    OnLeftBagClose = "OnLeftBagClose",

    OnUpdateLikeMessage = "OnUpdateLikeMessage",
    OnCloseLikeTip = "OnCloseLikeTip",
    OnDoSomethingToday = "OnDoSomethingToday",
    OnDoSomething = "OnDoSomething",
    OnAccountDoSomethingToday = "OnAccountDoSomethingToday",
    OnAccountDoSomething = "OnAccountDoSomething",
    OnGlobalDoSomethingToday = "OnGlobalDoSomethingToday",
    OnGlobalDoSomething = "OnGlobalDoSomething",

    OnUseBoxItemToOpenBox = "OnUseBoxItemToOpenBox",

    -- Pendant
    ON_ADD_PENDANT = "ON_ADD_PENDANT",
    ON_UPDATE_PENDANT_NEW = "ON_UPDATE_PENDANT_NEW",

    -- HurtStatistic
    OnFightHistoryUpdate = "OnFightHistoryUpdate",
    OnHurtStatisticPartnerTypeChanged = "OnHurtStatisticPartnerTypeChanged",

    -- Effect
    ON_UPDATE_EFFECT_NEW = "ON_UPDATE_EFFECT_NEW",

    -- IdleAction
    ON_UPDATE_IDLEACTION_NEW = "ON_UPDATE_IDLEACTION_NEW",

    -- SkillSkin
    ON_UPDATE_SKILLSKIN_NEW = "ON_UPDATE_SKILLSKIN_NEW",
    OnUpdateSkillSkinLike = "OnUpdateSkillSkinLike",

    -- 挂饰秘鉴通用事件
    ON_UPDATE_CURRENT_PENDANT = "ON_UPDATE_CURRENT_PENDANT",

    OnCharacterPendantSelected = "OnCharacterPendantSelected",
    OnCharacterPendantSelectedSubPage = "OnCharacterPendantSelectedSubPage",
    OnCharacterPendantPageItemSelected = "OnCharacterPendantPageItemSelected",
    OnBulletinUpdate = "OnBulletinUpdate",
    OnBulletinRedPointUpdate = "OnBulletinRedPointUpdate",
    OnDesignationNewUpdate = "OnDesignationNewUpdate",
    OpenCloseCharacterCustomEffect = "OpenCloseCharacterCustomEffect",
    OnCharacterCustomEffectOpenClose = "OnCharacterCustomEffectOpenClose",
    OpenCloseCharacterCustomPendant = "OpenCloseCharacterCustomPendant",
    OnCharacterCustomPandentOpenClose = "OnCharacterCustomPandentOpenClose",

    OnSkillAutoCastDisabled = "OnSkillAutoCastDisabled",
    OnDxSkillBarIndexChange = "OnDxSkillBarIndexChange",
    OnHorseNewUpdate = "OnHorseNewUpdate",
    OnPetNewUpdate = "OnPetNewUpdate",
    OnToyBoxNewUpdate = "OnToyBoxNewUpdate",
    OnEmotionActionNewUpdate = "OnEmotionActionNewUpdate",
    OnBrightMarkNewUpdate = "OnBrightMarkNewUpdate",

    OnShowPageBottomBar = "OnShowPageBottomBar",
    OnHidePageBottomBar = "OnHidePageBottomBar",

    OnQuestionnaireInfoChanged = "OnQuestionnaireInfoChanged",

    OnCameraHidePlayer = "OnCameraHidePlayer",
    OnUpdateMainCityLeftBottom = "OnUpdateMainCityLeftBottom",
    OnMainCityCustomSizeChanged = "OnMainCityCustomSizeChanged",
    OnSwitchCampRightTopState = "OnSwitchCampRightTopState",

    CloseLevelUpPanel = "CloseLevelUpPanel",

    OnNpcEnterScene = "OnNpcEnterScene",
    OnNpcLeaveScene = "OnNpcLeaveScene",

    OnUpdateHuaELouRedPoint = "OnUpdateHuaELouRedPoint",
    OnUpdateBenefitsRedPoint = "OnUpdateBenefitsRedPoint",

    OnClickLangFengXuanChengTask = "OnClickLangFengXuanChengTask",

    OnOperationShopDataUpdate = "OnOperationShopDataUpdate",
    OnOperationRecruitSelectReward = "OnOperationRecruitSelectReward",
    OnOperationMonthlyPurchaseSelectReward = "OnOperationMonthlyPurchaseSelectReward",
    OnOperationSelectBtnImgLink = "OnOperationSelectBtnImgLink",
    OnOperationSelectFameBtn = "OnOperationSelectFameBtn",

    UILoadingStart = "UILoadingStart",
    UILoadingFinish = "UILoadingFinish",
    UILoadingProgressBegin = "UILoadingProgressBegin",
    OnShortcutInteractionSingleKeyDown = "OnShortcutInteractionSingleKeyDown",
    OnShortcutInteractionMultiKeyDown = "OnShortcutInteractionMultiKeyDown",
    OnShortcutInteractionSingleKeyUp = "OnShortcutInteractionSingleKeyUp",
    OnShortcutInteractionMultiKeyUp = "OnShortcutInteractionMultiKeyUp",

    --八荒
    OnSelectSkillSetting = "OnSelectSkillSetting",
    OnGetSkillList = "OnGetSkillList",
    OnEnterBahuangDynamic = "OnEnterBahuangDynamic",--技能进入八荒技能状态
    OnLeaveBahuangDynamic = "OnLeaveBahuangDynamic",--技能退出八荒技能状态
    OnExChangeBahuangSkill = "OnExChangeBahuangSkill",--交换八荒技能
    OnUpdateBattleInfoList = "OnUpdateBattleInfoList",--更新八荒战斗信息
    OnClearBattleInfo = "OnClearBattleInfo",--清空八荒战斗信息
    OnLastGameDataUpdate = "OnLastGameDataUpdate",--上一句数据更新
    OnChangeMultiStageSkill = "OnChangeMultiStageSkill",
    SetBaHuangSkillRedPoint = "SetBaHuangSkillRedPoint",
    OnMoveBahungSkill = "OnMoveBahungSkill",

    -- 游戏内数字键盘
    OnGameNumKeyboardOpen = "OnGameNumKeyboardOpen",
    OnGameNumKeyboardClose = "OnGameNumKeyboardClose",
    OnGameNumKeyboardChanged = "OnGameNumKeyboardChanged",
    OnGameNumKeyboardConfirmed = "OnGameNumKeyboardConfirmed",
    OnGameNumKeyboardCanceled = "OnGameNumKeyboardCanceled",

    OnPersonalCardGetAllDataRespond = "OnPersonalCardGetAllDataRespond",

    ClientChangeAutoNavState = "ClientChangeAutoNavState",
    OnAutoNavResult = "OnAutoNavResult",

    On_Get_Daily_Allinfo = "On_Get_Daily_Allinfo",
    On_GameGuide_RefreshDailyInfo = "On_GameGuide_RefreshDailyInfo",
    On_GameGuide_UpdateWeeklyInfo = "On_GameGuide_UpdateWeeklyInfo",
    On_GameGuide_NxWkLoginInfo = "On_GameGuide_NxWkLoginInfo",

    --动态技能球
    OnActionBarInit = "OnActionBarInit",

    --分线窗口
    OnSelectLineType = "OnSelectLineType",

    -- 省电模式
    OnEnterPowerSaveMode = "OnEnterPowerSaveMode",
    OnExitPowerSaveMode = "OnExitPowerSaveMode",
    DoExitPowerSaveMode = "DoExitPowerSaveMode",

    -- 焦点列表
    OnFocusCampCountUpdate = "OnFocusCampCountUpdate",

    OrangeWeaponUpgRedPoint = "OrangeWeaponUpgRedPoint",
    OnBuildFacePresetToggleSelect = "OnBuildFacePresetToggleSelect",

    OnServerListReqSuccessed = "OnServerListReqSuccessed",

    AutoSelectSwitchMapWindow = "AutoSelectSwitchMapWindow",

    PLAYER_MINI_AVATAR_UPDATE = "PLAYER_MINI_AVATAR_UPDATE",

    OnUserInputNumber = "OnUserInputNumber",

    OnPlayerMove = "OnPlayerMove",

    OnSelectCollectionAwardChanged = "OnSelectCollectionAwardChanged",
    OnShowCollectionMoreReward = "OnShowCollectionMoreReward",

    RefreshHotSpotData = "RefreshHotSpotData",

    AnnouncementShow = "AnnouncementShow",
    AnnouncementHide = "AnnouncementHide",

    OnGetChatMsg = "OnGetChatMsg",

    --主界面自定义
    OnSetChatBgOpacity = "OnSetChatBgOpacity",
    OnSetDragInfoDefault = "OnSetDragInfoDefault",
    OnSetDragNodeScale = "OnSetDragNodeScale",
    OnSetDragDpsBgOpacity = "OnSetDragDpsBgOpacity",
    OnUpdateQuickUseTipPosByNewPos = "OnUpdateQuickUseTipPosByNewPos",

    OnUpdateDragNodeCustomState = "OnUpdateDragNodeCustomState",
    OnSaveDragNodePosition = "OnSaveDragNodePosition",
    OnResetDragNodePosition = "OnResetDragNodePosition",
    OnSliderSetSkillScale = "OnSliderSetSkillScale",

    -- moba局内消息
    ShowMobaBattleMsgGeneralMsg = "ShowMobaBattleMsgGeneralMsg",
    ShowMobaBattleMsgGeneralMsgEx = "ShowMobaBattleMsgGeneralMsgEx",
    ShowMobaBattleMsgOneSidedMsg = "ShowMobaBattleMsgOneSidedMsg",
    ShowMobaBattleMsgTwoSidedMsg = "ShowMobaBattleMsgTwoSidedMsg",

    -- 帮会联赛局内消息
    ShowTongBattleTips = "ShowTongBattleTips",
    ShowTongBattledragonTips = "ShowTongBattledragonTips",

    OnAvatarNewUpdate = "OnAvatarNewUpdate",
    OnMapAppointmentNewUpdate = "OnMapAppointmentNewUpdate",
    On_UI_OpenAdvancedDof = "On_UI_OpenAdvancedDof",
    On_UI_ShowGamepadCursor = "On_UI_ShowGamepadCursor",

    FancySkating_StartSkaingPair = "FancySkating_StartSkaingPair",
    FancySkating_CloseSkatingPair = "FancySkating_CloseSkatingPair",
    FancySkating_PairsCancel = "FancySkating_PairsCancel",
    On_FancySkating_Record = "On_FancySkating_Record",
    FancySkating_OnButtonDown = "FancySkating_OnButtonDown",
    FancySkating_OnButtonUp = "FancySkating_OnButtonUp",
    OnEnterFancySkating = "OnEnterFancySkating",
    OnExitFancySkating = "OnExitFancySkating",

    OnStartPlayMovie = "OnStartPlayMovie",

    ResetSkillAndJoystick = "ResetSkillAndJoystick",

    OnEnterWordBlockDelAll = "OnEnterWordBlockDelAll",
    OnExitWordBlockDelAll = "OnExitWordBlockDelAll",
    OnWordBlockChanged = "OnWordBlockChanged",
    OnWordBlockSelected = "OnWordBlockSelected",

    OnClientCastSkill = "OnClientCastSkill",
    On_Trial_GetWeekRemainCard = "On_Trial_GetWeekRemainCard",
    OnCheckVerifyWechatManager = "OnCheckVerifyWechatManager",

    OnWordMonitorChanged = "OnWordMonitorChanged",
    OnAddChatMonitor = "OnAddChatMonitor",
    OnSelfieWebCodeRsp = "OnSelfieWebCodeRsp",
    OnSelfieFrameFreezeState = "OnSelfieFrameFreezeState",

    OnMYTaoguanStateChanged = "OnMYTaoguanStateChanged",
    OnMYTaoguanScoreLimitChanged = "OnMYTaoguanScoreLimitChanged",

    --玩具
    UpdateActionToySkillState = "UpdateActionToySkillState",

    OnSkillConfigurationCompleted = "OnSkillConfigurationCompleted",
    OnSelfieWindSwitchEnable = "OnSelfieWindSwitchEnable",
    OnSelfieFabricEnableEnable = "OnSelfieFabricEnableEnable",
    OnSelfieClothWindResetData = "OnSelfieClothWindResetData",
    OnSelfieStudioLineCellSelect = "OnSelfieStudioLineCellSelect",
    OnSelfieStudioLineCellEnable = "OnSelfieStudioLineCellEnable",
    OnSelfieStudioWeatherChange = "OnSelfieStudioWeatherChange",
    OnSelfieCameraAniSelected = "OnSelfieCameraAniSelected",
    OnSelfieCameraBGMSelected = "OnSelfieCameraBGMSelected",
    OnSelfieCameraBGMPlay = "OnSelfieCameraBGMPlay",
    OnSelfieCameraBGMPause = "OnSelfieCameraBGMPause",
    OnSelfieCameraBGMEditor = "OnSelfieCameraBGMEditor",
    OnSelfieCameraBGMCustomDeleted = "OnSelfieCameraBGMCustomDeleted",
    OnSelfieCameraBGMCustomSaved = "OnSelfieCameraBGMCustomSaved",

    OnUpdateWuLinTongJianRedpoint = "OnUpdateWuLinTongJianRedpoint",

    TryCloseBubbleMsgOnly = "TryCloseBubbleMsgOnly",
    SelfieFilterSettingReset = "SelfieFilterSettingReset",

    UpdateFBCountDown = "UpdateFBCountDown",

    --语音房间
    BackToVoiceRoom = "BackToVoiceRoom",
    OnMemberLeaveVoiceRoom = "OnMemberLeaveVoiceRoom",
    OnMemberJoinVoiceRoom = "OnMemberJoinVoiceRoom",
    OnMemberMicStateChanged = "OnMemberMicStateChanged",
    ON_SYNC_VOICE_PERMISSION_INFO = "ON_SYNC_VOICE_PERMISSION_INFO",
    ON_SYNC_VOICE_ROOM_INFO = "ON_SYNC_VOICE_ROOM_INFO",
    ON_JOIN_VOICE_ROOM = "ON_JOIN_VOICE_ROOM",
    ON_SYNC_ROLE_VOICE_ROOM_LIST = "ON_SYNC_ROLE_VOICE_ROOM_LIST",
    ON_VOICE_ROOM_RECORD_UPDATE = "ON_VOICE_ROOM_RECORD_UPDATE",
    ON_LIVE_STREAM_INFO_UPDATE = "ON_LIVE_STREAM_INFO_UPDATE",
    ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI = "ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI",
    ON_DUNGEON_OB_PLAYERS_POS_INFO_UPDATE_UI = "ON_DUNGEON_OB_PLAYERS_POS_INFO_UPDATE_UI",
    ON_TEAM_DUNGEON_OB_SET_MARK_UI = "ON_TEAM_DUNGEON_OB_SET_MARK_UI",
    ON_TEAM_DUNGEON_OB_AUTHORITY_CHANGED_UI = "ON_TEAM_DUNGEON_OB_AUTHORITY_CHANGED_UI",
    ON_OB_SELECT_PLAYER_CHANGED = "ON_OB_SELECT_PLAYER_CHANGED",
    ON_OB_SET_VIEW = "ON_OB_SET_VIEW",
    OnOperateListChange = "OnOperateListChange",
    OnLikeRoomChanged = "OnLikeRoomChanged",
    OnGMEMicStateChanged = "OnGMEMicStateChanged",
    OnGMESpeakerStateChanged = "OnGMESpeakerStateChanged",
    OnAgreenRuleChanged = "OnAgreenRuleChanged",
    OnNeedToUpdateTopRecommendList = "OnNeedToUpdateTopRecommendList",

    -- 小游戏
    OnMiniGameStart = "OnMiniGameStart",
    OnMiniGameOpenGuide = "OnMiniGameOpenGuide",
    OnMiniGameCloseGuide = "OnMiniGameCloseGuide",
    OnMiniGameUpdateJigsaw = "OnMiniGameUpdateJigsaw",

    -- 大富翁
    OnMonopolyLotteryBegin = "OnMonopolyLotteryBegin",
    OnMonopolyLotteryUpdataPlayerChoosen = "OnMonopolyLotteryUpdataPlayerChoosen",
    OnMonopolyLotterySwitchToResultStage = "OnMonopolyLotterySwitchToResultStage",
    OnMonopolyShopRefreshAfterBuy = "OnMonopolyShopRefreshAfterBuy",
    OnMonopolyShopRefreshAfterSell = "OnMonopolyShopRefreshAfterSell",
    OnMonopolyUpdatePlayerMoney = "OnMonopolyUpdatePlayerMoney",
    OnMonopolyUpdatePlayerPointNum = "OnMonopolyUpdatePlayerPointNum",
    OnMonopolyRightEventOpen = "OnMonopolyRightEventOpen",
    OnMonopolyRightEventClose = "OnMonopolyRightEventClose",
    OnMonopolySetAuctionState = "OnMonopolySetAuctionState",

    OnMonopolyCurrentPlayerChanged = "OnMonopolyCurrentPlayerChanged",
    OnMonopolyOperateDownprepareReady = "OnMonopolyOperateDownprepareReady",
    OnMonopolySwitchSubPanels = "OnMonopolySwitchSubPanels",
    OnMonopolyOperateDownCountDown = "OnMonopolyOperateDownCountDown",
    OnMonopolyBeginDiceShow = "OnMonopolyBeginDiceShow",
    OnMonopolyCardListUpdateSelectCard = "OnMonopolyCardListUpdateSelectCard",
    OnMonopolyCardListUpdateCardList = "OnMonopolyCardListUpdateCardList",
    OnMonopolyPlayerListOnChangeBuff = "OnMonopolyPlayerListOnChangeBuff",
    OnMonopolyInfoRoundChanged = "OnMonopolyInfoRoundChanged",

    -- 头顶文字
    OnCharacterHeadTip = "OnCharacterHeadTip",

    OnPhotoShareWidgetShow = "OnPhotoShareWidgetShow",

    -- 远程调用 禁言刷新
    OnRemoteBanInfoUpdate = "OnRemoteBanInfoUpdate",
    OnOpenMicButBaned = "OnOpenMicButBaned",

    OnSelfieUpdateAIUploadRemainCount = "OnSelfieUpdateAIUploadRemainCount",
}
