Storage = Storage or {}

--- 添加个辅助函数，方便ide自动提示存盘的两个接口
Storage.Helper = {
    Dirty = function(tStorage)
        tStorage.Dirty()
    end,
    Flush = function(tStorage)
        tStorage.Flush()
    end,
}

-- 字体相关 -----------------------------------
Storage.Font = {
    tbFontPath = {
        [0] = "mui/Fonts/Base/MiSans-Medium.ttf",
        [1] = "mui/Fonts/Base/fzjz.ttf",
    },
}
CustomData.Register(CustomDataType.Global, "Font", Storage.Font)

-- 登录相关 -----------------------------------
Storage.Login = {
    szAccount = "", -- 这个账号只在开发者登录模式下生效，其他不生效，切记
    szPassword = "", --TODO: 后续密码需要加密
    bIsRemAcc = false,
    --bIsConsent = false,
}
CustomData.Register(CustomDataType.Global, "Login", Storage.Login)

-- 最近登录服务器相关 -----------------------------------
Storage.RecentLogin = {
    tbServer = {}
}
CustomData.Register(CustomDataType.Global, "RecentLogin", Storage.RecentLogin)

-- 服务器角色数量 -----------------------------------
Storage.ServerRoleCount = {
    tbRoleCount = {
        --[[
            'szAccountKey' = {
                'szServer' = nRoleCount
            }
        --]]
    },
}
CustomData.Register(CustomDataType.Global, "ServerRoleCount", Storage.ServerRoleCount)

-- 下载相关 -----------------------------------
Storage.Download = {
    tbTaskTable = {
        [DOWNLOAD_STATE.DOWNLOADING] = {},
        [DOWNLOAD_STATE.QUEUE] = {},
        [DOWNLOAD_STATE.PAUSE] = {},
        [DOWNLOAD_STATE.COMPLETE] = {},
    },
    tbMutexIDTable = {},
    bShowDownloadBall = true,
    tbDownloadBallPos = nil,
    bResourcesDeleteHint_SLFY = false, --丝路风语
    bResourcesDeleteHint_TJML = false, --太极秘录
    bResourcesDeleteHint_SHYL = false, --山海源流
    bResourcesDeleteHint_AYQJ = false, --暗影千机
}
CustomData.Register(CustomDataType.Global, "Download", Storage.Download)

Storage.PriorityDownload = {
    tbPriority = {},
    tbDefault = {},
}
CustomData.Register(CustomDataType.Role, "PriorityDownload", Storage.PriorityDownload)

Storage.CoreDownload = {
    tbCore = {},
}
CustomData.Register(CustomDataType.Global, "CoreDownload", Storage.CoreDownload)

Storage.AutoDownload = {
    tbPackIDMap = {},
}
CustomData.Register(CustomDataType.Global, "AutoDownload", Storage.AutoDownload)

-- 任务相关 -----------------------------------
Storage.Quest = {
    -- nTracingQuestID = 0,
    tbTracingQuestID = {},
    tbProhibitTraceQuestID = {},--禁止追踪的任务
}
CustomData.Register(CustomDataType.Role, "Quest", Storage.Quest)

-- 活动相关 -----------------------------------
Storage.Activity = {
    tbLikeActivityID = {},
    bAutoCollect = true,
    tActivityRedDotVertion = {},    --新活动红点
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "Activity", Storage.Activity)

-- 帮会相关 -----------------------------------
Storage.Tong = {
    bReceiveJoinApplyMsg = true,
    WarData = {},
    League = {},
    ContractWarData = {},
}
CustomData.Register(CustomDataType.Role, "Tong", Storage.Tong)


-- 社交好友相关 -----------------------------------
Storage.Fellowship = {
    NameDisplayMode = 0,
}
CustomData.Register(CustomDataType.Role, "Fellowship", Storage.Fellowship)


-- 角色相关 -----------------------------------
Storage.Player = {
    AttribShowConfig = 0,
    bShowFightingNum = true,
    bShowPVPSkillScore = false,
    bShowTrace = nil,
}
CustomData.Register(CustomDataType.Role, "Player", Storage.Player)

-- 快速换装
Storage.SwitchEquipSuit = {
    tbEquipType1 = {},
    tbEquipType2 = {},
}
CustomData.Register(CustomDataType.Role, "Player", Storage.SwitchEquipSuit)


--邮件相关
Storage.Email = {
    tbContacts = {},
    tbContactsTimes = {},
}
CustomData.Register(CustomDataType.Role, "Email", Storage.Email)

--商城
Storage.CoinShop = {
    tbOutfitList = {},
    tbPointsDrawPoolInfo = {},
    CustomPendantInfo = {},
    bPreviewMatchHair = false,
    tVisitedWelfare = {},
    tbNewExterior = {},
    tbNewWeaponExterior = {},
    tbNewPendantPet = {},
    tbNewFace = {},
    tbNewHair = {},
    tbNewBody = {},
    dwMaxHomeGoodsID = 0,
}
CustomData.Register(CustomDataType.Role, "CoinShop", Storage.CoinShop)

--商城推荐穿搭
Storage.CoinShopRecommend = {
    bSkipShareConfirm = false, -- 前往设计站不再提示
}
CustomData.Register(CustomDataType.Role, "CoinShopRecommend", Storage.CoinShopRecommend)

--聊天相关
Storage.Chat = {}
function Storage.Chat:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat[key] = val
    end
end
CustomData.Register(CustomDataType.Account, "Chat", Storage.Chat)

-- 弹幕设置
Storage.Chat_Bullet = {
    bInit = false,
    nOpacity = 100,
    bOpenFlag = true,
    nColorID = 1,  -- 1 白色
    nFontSize = 1, -- 0 大 1 小
    nShowMode = 3, -- 1 Top 2 Bottom 3 Roll
}
function Storage.Chat_Bullet:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat_Bullet[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "Chat_Bullet", Storage.Chat_Bullet)

Storage.Chat_AutoShout = {
    bInit = false,
}
function Storage.Chat_AutoShout:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat_AutoShout[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "Chat_AutoShout", Storage.Chat_AutoShout)

Storage.Chat_DeathShout = {
    bInit = false,
}
function Storage.Chat_DeathShout:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat_DeathShout[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "Chat_DeathShout", Storage.Chat_DeathShout)

Storage.Chat_KillShout = {
    bApplySingle = false,
    bApplyDaily = false,
    tDayStat = {}, -- 今日击杀数据
    tSingleStat = {}, -- 本次登录击杀数据
}
function Storage.Chat_KillShout:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat_KillShout[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "Chat_KillShout", Storage.Chat_KillShout)

Storage.Chat_SkillShout = {
    tbSkillList = {},
    tbChannelList = {},
    tbForbidMapList = {},
    bInit = false,
}
function Storage.Chat_SkillShout:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.Chat_SkillShout[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "Chat_SkillShout", Storage.Chat_SkillShout)

Storage.ShoutFilter = {
    tbForbidChannel = {},
    tbForbidType = {},
    tbForbidMap = {},
}
function Storage.ShoutFilter:OnLoaded(tLoad)
    for key, val in pairs(tLoad) do
        Storage.ShoutFilter[key] = val
    end
end
CustomData.Register(CustomDataType.Role, "ShoutFilter", Storage.ShoutFilter)

Storage.VoiceRoomFilter = {
    bFilterEnter = true,
    bFilterFuwuqi = false,
}
CustomData.Register(CustomDataType.Role, "VoiceRoomFilter", Storage.VoiceRoomFilter)

--战场相关
Storage.BattleField = {
    tbEnterState = {},
}
CustomData.Register(CustomDataType.Role, "BattleField", Storage.BattleField)

--阵营相关
Storage.Camp = {
    bEnableActivityPreset = false,
}
CustomData.Register(CustomDataType.Role, "Camp", Storage.Camp)

Storage.PanelCamp = {
    bNewLevel = false,
}
CustomData.Register(CustomDataType.Role, "PanelCamp", Storage.PanelCamp)

-- 新手引导 -----------------------------------
Storage.Teach = {
    tTeachState = {},
    tVariable = {},
}
CustomData.Register(CustomDataType.Role, "Teach", Storage.Teach)

Storage.QuickUse = {
    tbItemTypeList = {},
    tbItemTypeListInLKX = {},
    nMaxSlotCount = 9,

    tbSkillSlotTypeList = {}, -- 技能栏的道具快捷使用，可以玩家配置，可以由任务追踪添加
    tbSkillSlotTypeListInLKX = {},
    tbSkillSlotTypeListInTreasureBF = {},

    bTouchClose = true
}
CustomData.Register(CustomDataType.Role, "QuickUse", Storage.QuickUse)

Storage.SkillAutoCustomize = {
    tKungFuCustomize = {},
    bIsAutoClosedAfterSprint = false,
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "SkillAutoCustomize", Storage.SkillAutoCustomize)

-- 武学套路名称
Storage.SkillSetNames = {
    [1] = "配置一",
    [2] = "配置二",
    [3] = "配置三",

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "SkillSetNames", Storage.SkillSetNames)

-- Debug -----------------------------------
Storage.Debug = {
    bShowDebugInfo = true,
    bPSMFlag = true,
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end,
}
CustomData.Register(CustomDataType.Global, "Debug", Storage.Debug)

--排队自动进入地图
Storage.MapQueue = {
    bShowSureNotice = false,
}
CustomData.Register(CustomDataType.Role, "MapQueue", Storage.MapQueue)

Storage.HurtStatisticSettings = {
    [STAT_TYPE.HATRED] = true,
    [STAT_TYPE.DAMAGE] = true,
    [STAT_TYPE.BE_DAMAGE] = true,
    [STAT_TYPE.THERAPY] = true,
    IsStatisticOpen = false,
    IsSeparatePartnerData = false,
    ShowParnterType = PARTNER_FIGHT_LOG_TYPE.SELF,
    IsSeeMeOpen = false,
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "HurtStatisticSettings", Storage.HurtStatisticSettings)

Storage.WorldMapData = {
    tbRecordList = {}
}
CustomData.Register(CustomDataType.Role, "WorldMap", Storage.WorldMapData)


-- 通用筛选与排序s
Storage.Filter = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "Filter", Storage.Filter)

--队伍
Storage.Team = {
    bEnableMainCityRaidMode = false,
    bEnableMainCityTeamMode = false,
    bEnableRoomAutoSyncToTeam = true,
    nRaidCountDown = 5,
}
CustomData.Register(CustomDataType.Role, "Team", Storage.Team)

--家园外
Storage.HomeLand = {
    bFlowerPriceFilterOwner = false,
    bShowNewCommunityRule = false,
    tbLikedSetID = {},
    dwLastOpenTime = 0,
}
CustomData.Register(CustomDataType.Role, "HomeLand", Storage.HomeLand)

--家园建造
Storage.HomeLandBuild = {
    tHistorySelectionItem = {},
}
CustomData.Register(CustomDataType.Role, "HomeLandBuild", Storage.HomeLandBuild)

--家园身份相关
Storage.HLIdentity = {
    bIsAutoGetFish = true,
}
CustomData.Register(CustomDataType.Role, "HLIdentity", Storage.HLIdentity)

--江湖百态艺人
Storage.ArtistSkills = {
    tbSkillList = {},
}
CustomData.Register(CustomDataType.Role, "ArtistSkillsData", Storage.ArtistSkills)


--是否做过某些事情
Storage.HasDidSomething = {
    tbToday = {}, -- 今天是否做过
    tbPermanent = {}, -- 永久的
}
CustomData.Register(CustomDataType.Role, "HasDidSomething", Storage.HasDidSomething)

--账号级别 是否做过某些事情
Storage.AccountHasDidSomething = {
    tbToday = {}, -- 今天是否做过
    tbPermanent = {}, -- 永久的
}
CustomData.Register(CustomDataType.Account, "AccountHasDidSomething", Storage.AccountHasDidSomething)

--设备级别 是否做过某些事情
Storage.GlobalHasDidSomething = {
    tbToday = {}, -- 今天是否做过
    tbPermanent = {}, -- 永久的
}
CustomData.Register(CustomDataType.Global, "GlobalHasDidSomething", Storage.GlobalHasDidSomething)

-- 角色相关
Storage.Character = {
    tbNewPendant = {},
    tbNewEffect = {},
    tbNewIdleAction = {},
    tbBodyName = {},
    tbNewFaceName = {},
    tbFaceName = {},
    tUseLifeFaceName = {},
    tbHairName = {},
    tbCustomEffectInfo = {},
    tWeaponExterior = {},
}
CustomData.Register(CustomDataType.Role, "Character", Storage.Character)

-- 角色设置相关
Storage.CharacterSetting = {
    nPlaySoundVersion = 0,
}
CustomData.Register(CustomDataType.Role, "CharacterSetting", Storage.CharacterSetting)

-- 称号相关
Storage.PersonalTitle = {
    tbNewPrefix = {}, -- 前缀（包括战阶、世界）
    tbNewPostfix = {}, -- 后缀
    dwNewGeneration = nil, -- 门派
}
CustomData.Register(CustomDataType.Role, "PersonalTitle", Storage.PersonalTitle)

-- 坐骑
Storage.Horse = {
    bHasNewHorse = false, -- 是否有新坐骑
    tbNewRideHorse = {}, -- 新的普通坐骑
    tbNewQiquHorse = {}, -- 新的奇趣坐骑
}
CustomData.Register(CustomDataType.Role, "Horse", Storage.Horse)

-- 宠物
Storage.Pet = {
    tbNewPet = {}, -- 新宠物
}
CustomData.Register(CustomDataType.Role, "Pet", Storage.Pet)

-- 玩具箱
Storage.ToyBox = {
    tbNewToyBox = {}, -- 新玩具
}
CustomData.Register(CustomDataType.Role, "ToyBox", Storage.ToyBox)

-- 表情动作
Storage.Emotion = {
    tbNewEmotion = {},
    tbNewChatEmotion = {}, -- 新的聊天表情
}
CustomData.Register(CustomDataType.Role, "Emotion", Storage.Emotion)

-- 头顶表情
Storage.BrightMark = {
    tbNewBrightMark = {},
}
CustomData.Register(CustomDataType.Role, "BrightMark", Storage.BrightMark)

-- 公告相关
Storage.Bulletin = {
    --均为记录各类公告的MD5，用于对比公告是否更新
    tbBulletin = {}, --公告是否自动弹出 界面打开后刷新
    tbRedPointBulletin = {}, --红点是否显示 选中公告切页后刷新
}
CustomData.Register(CustomDataType.Global, "Bulletin", Storage.Bulletin)

-- 中地图相关
Storage.MiddleMapData = {
    tbTagList = {},
    tbTeamTagInfo = {
        nMapID = 0,
    },
    tbLikeMapList = {},
    tbLikeMap = {},
    tbCraftList = {},--已经勾选的采集列表
    bShowCraft = false,--是否显示采集
    bMiniMapShowCraft = true,--小地图是否显示采集
    bShowExploreFinish = true,--显示已完成探索
}
CustomData.Register(CustomDataType.Role, "MiddleMap", Storage.MiddleMapData)

-- TapTap问券相关
Storage.TapTap = {
    bSignInCompleted = false,
    bPayCompleted = false,
    bQiyuCompleted = false,
    bShouldShowQiyu = false,
    bShouldShowPay = false,
    nInitialSignInCount = -1,
    nVersion = -1
}
CustomData.Register(CustomDataType.Account, "TapTap", Storage.TapTap)

--  教程盒子相关
Storage.TeachBox = {
    bIsOldPlayer = nil,
    --tbNewTeachCell = {},
    bNew = true,
    tbNewTeachLine = {},
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "TeachBox", Storage.TeachBox)

-- 权限
Storage.Permission = {
    tbHasAsked = {}
}
CustomData.Register(CustomDataType.Global, "Permission", Storage.Permission)

--快捷界面宠物交互设置
Storage.QuickPetAction = {
    bPetShieldAction = true,
    bPartnerShieldAction = true,
}
CustomData.Register(CustomDataType.Role, "QuickPetAction", Storage.QuickPetAction)

--花萼楼
Storage.HuaELou = {
    bNewLevel = true,
    bClickTask_LangFengXuanCheng = false,
    tQuestLikeMap = {}
}
CustomData.Register(CustomDataType.Role, "HuaELou", Storage.HuaELou)

--竞技场相关
Storage.Arena = {
    bLocked = true,
    bHaveRedPoint = true,
    bFirstOpen = true
}
CustomData.Register(CustomDataType.Role, "Arena", Storage.Arena)

--百战异闻录相关
Storage.MonsterBook = {
    tActiveSkillTime = {},
    tSkillPresetName = {},
    bHasFirstTransSkill = false,
    bHasFirstLevelChoose = false,
    bHasFirstProgressPanel = false,
    bHasFirstSkillPanel = false,
    bHasFirstEnterScene = false,
    bHasFirstChooseLevel = false,
    bCheckSEDetailRedDot = false,
}
CustomData.Register(CustomDataType.Role, "MonsterBook", Storage.MonsterBook)

-- 副本拍团相关
Storage.Auction = {
    tRedPointLootItemList = {}, -- {{dwDoodadID=1,nLootItemIndex=1}...}
    TagNameList = {},
    tDistributeRecords = {},
    tPricePreset = {},
    bPricePresetInit = false,
    nPricePresetID = 1,
    tNoPromotDoodadList = {},
}
CustomData.Register(CustomDataType.Role, "AuctionData", Storage.Auction)

-- 副本大全相关
Storage.Dungeon = {
    bRecommendOnly = true, -- 是否仅显示推荐秘境
    tCollection = {}, -- 收藏
}
CustomData.Register(CustomDataType.Role, "Dungeon", Storage.Dungeon)

-- 拾取设置相关
Storage.LootSetting = {
    bForbidBookHasRead = false,
    bForbidBookHasOwned = false,
    bAutoLootByQuality = false,
    tAutoLootQualityList = {true,true,true,true,true,true},
    tItemSettingList = {}, -- 0/1代表模糊匹配/全字匹配，自动拾取/禁止拾取
}
CustomData.Register(CustomDataType.Role, "MiniLootSetting", Storage.LootSetting)

-- 商店相关
Storage.Shop = {
    tbRedPointShopIDMap = {}, -- 商店是否有红点，true为有红点，false为红点被清除，nil则不存在红点规则
}
CustomData.Register(CustomDataType.Role, "Shop", Storage.Shop)

--八荒
Storage.BaHuang = {
    tbNpcNameSetting = {},
    tbAutoCastList = {},
    bEnableBreakFirstSkill = false,
    bHideSkillText = false,
    bAutoCastAllSkill = true,
}
CustomData.Register(CustomDataType.Role, "BaHuang", Storage.BaHuang)

--热点推送
Storage.HotSpotRole = {
    fPopVersion = 1.0,
}
CustomData.Register(CustomDataType.Role, "HotSpotRole", Storage.HotSpotRole)

Storage.HotSpotGlobal = {
    fWebVersion = 1.0,
}
CustomData.Register(CustomDataType.Global, "HotSpotGlobal", Storage.HotSpotGlobal)

--操作模式
Storage.ControlMode = {
    nMode = 2,
    bFontShow = true,
    tbMainCityNodeScaleType = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {
            nMap = 0,
            nSkill = 0,
            nChat = 0,
            nTask = 0,
            nTeam = 0,
            nBuff = 0,
            nQuickuse = 0,
            nPlayer = 0,
            nTarget = 0,
            nLeftBottom = 0,
            nEnergy = 0,
            nSpecialSkillBuff = 0,
            nDxSkill = 0,
            nKillFeed = 0,
        },
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {
            nMap = 0,
            nSkill = 0,
            nChat = 0,
            nTask = 0,
            nTeam = 0,
            nBuff = 0,
            nQuickuse = 0,
            nPlayer = 0,
            nTarget = 0,
            nLeftBottom = 0,
            nEnergy = 0,
            nSpecialSkillBuff = 0,
            nDxSkill = 0,
            nKillFeed = 0,
        },
    },

    tbFontShow = {
        [CUSTOM_TYPE.CUSTOMBTN] = true,
        [CUSTOM_TYPE.MENU] = true,
        [CUSTOM_TYPE.SKILL] = true,
    },
    tbClassicSize = nil,
    tbClassicPositionInfo = {},

    tbSimpleSize = nil,
    tbSimplePositionInfo = {},

    tbDefaultClassicSize = nil,
    tbDefaultClassicPositionInfo = {},

    tbDefaultSimpleSize = nil,
    tbDefaultSimplePositionInfo = {},

    tbChatContentSize = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {},
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {},
    },

    tbChatBtnSelectSize = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = {},
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = {},
    },

    nVersion = nil,

    tbDefaultPosition = {
        [MAIN_CITY_CONTROL_MODE.CLASSIC] = true,
        [MAIN_CITY_CONTROL_MODE.SIMPLE] = true,
    },

    tbVersion = {
        nMap = 0,
        nSkill = 0,
        nChat = 0,
        nTask = 0,
        nTeam = 0,
        nBuff = 0,
        nQuickuse = 0,
        nPlayer = 0,
        nTarget = 0,
        nLeftBottom = 0,
        nEnergy = 0,
        nSpecialSkillBuff = 0,
        nDxSkill = 0,
        nKillFeed = 0,
    },

    tbChatBgDefaultOpacity = {},

    tbChatBgOpacity = {},

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end,
}
CustomData.Register(CustomDataType.Account, "ControlMode", Storage.ControlMode)

--动态技能球等位置
Storage.MainCityNode = {
    -- WidgetActionbar = {}
    tbMaincityNodePos = {},
    tbMaincityDragNodeScale = {},
    tbDpsBgOpcity = {
        nDefault = nil,
        nOpacity = nil
    },

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end,
}
CustomData.Register(CustomDataType.Account, "MainCityNode", Storage.MainCityNode)

--主界面自定义红点
Storage.MainCityCustom = {
    bNew = true,
}
CustomData.Register(CustomDataType.Role, "MainCityCustom", Storage.MainCityCustom)

--自定义切换按钮
Storage.CustomBtn = {
    tbBtnDataList = {
        [1] = { 15, 16, 12 },
        [2] = { 15, 16, 12 },
        [3] = { 5, 12, 7 },
        [4] = { 5, 23, 26 },
    },
    nVersion = nil,
    nCurExteriorIndex = 0,
    bHaveFellowPet = false,
    nCurType = nil,

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end,
}
CustomData.Register(CustomDataType.Role, "CustomBtn", Storage.CustomBtn)

--moba预设装备
--ps：与端游一样，预设装备信息在本地保存，在实际开始玩法时再同步到服务器的对局中
Storage.MobaShop_tPrePurchase = {
    nVerson = 1,
    tPlans = {},
    tSelectingPlan = {}
}
CustomData.Register(CustomDataType.Role, "MobaShop.tPrePurchase", Storage.MobaShop_tPrePurchase)

--交易行
Storage.TradingHouse = {
    tbSearchHistory = {},
    tbBidCache = {},
    nLastEndTime = 0,
}
CustomData.Register(CustomDataType.Role, "TradingHouse", Storage.TradingHouse)

-- 玲珑密保锁绑定设备信息
Storage.LingLongMiBaoBindDevice = {
    --- 是否已绑定设备，仅当该值为true时，下面几个字段才有意义
    bBindDevice = false,

    --- 金山通行证账号
    szAccount = "",
    --- 西瓜uid
    szXiGuaUid = "",
    --- 绑定成功后返回的token，该token与设备id关联，可通过 XGSDK_GetDeviceId 接口来获取
    szToken = "",
    --- token过期时间戳
    nExpiredTimestamp = 0,
}
CustomData.Register(CustomDataType.Account, "LingLongMiBaoBindDevice", Storage.LingLongMiBaoBindDevice)

--背包视图
Storage.Bag = {
    nTabType = 0,
    bShowMoneyList = false,
    tbSelectedCurrencyNew = {
        [CurrencyType.Money] = true,
        [CurrencyType.Coin] = true,
    }
}
CustomData.Register(CustomDataType.Role, "Bag", Storage.Bag)

--焦点列表
Storage.FocusList = {
    _tFocusTargetData = {},
    _tCustomModData = {
        default = {
            {
                enable = false,
                data = {}
            },{
                enable = false,
                forceFilter = false,
                data = {},
                forceData = {},
            },{
                enable = false,
                data = {}
            }
        }
    },
}
CustomData.Register(CustomDataType.Role, "FocusList", Storage.FocusList)

-- 武学面板
Storage.PanelSkill = {
    bNewRecommend = true,
    bCheckTeach = true,
    bNewLiuPai_WuXiang = true,
    tKungFuRecommendVersion = {},
    tbEquipSetBinding = {},
}
CustomData.Register(CustomDataType.Role, "PanelSkill", Storage.PanelSkill)

Storage.QianLiFaZhu = {
    tbCrossData = {}
}
CustomData.Register(CustomDataType.Global, "QianLiFaZhu", Storage.QianLiFaZhu)

--- 帮会天工树-涅槃分支的方案数据
Storage.TongRebornTree = {
    --- 上次存盘时的本年周数，若该值与当前的周数不同，则将本周数据轮换到上周数据，并初始化本周数据
    ---     TimeLib.TimeToWeekCount(GetCurrentTime())
    nWeekIndexInYearWhenLastSave = -1,

    --- 本周的天工树方案 节点ID => 等级
    --- @type table<number, number>
    tThisWeekPlan = {},

    --- 上周的天工树方案 节点ID => 等级
    --- @type table<number, number>
    tLastWeekPlan = {},
}
CustomData.Register(CustomDataType.Role, "TongRebornTree", Storage.TongRebornTree)

-- 信息追踪相关
Storage.TraceInfo = {
    tbTraceData = {},
}
CustomData.Register(CustomDataType.Role, "TraceInfo", Storage.TraceInfo)

-- 过图自动喂马配置
Storage.HorseFeed = {
    bAutoFeed = false, --是否开启
    nQuality = 4, -- 设置自动喂的品质的等级（默认紫色）
    nPercent = 0.7,  -- 饱食度低于多少自动喂
    bBindLimit = true,  -- 是否只消耗绑定物品
    tBanFeedItem = {},  -- 禁用的饲料列表
}
CustomData.Register(CustomDataType.Role, "HorseFeed", Storage.HorseFeed)

-- 小头像
Storage.Avatar = {
    tbNewAvatar = {},
}
CustomData.Register(CustomDataType.Role, "Avatar", Storage.Avatar)

-- 头顶血条文字
Storage.HeadTopBarSetting = {
    nFontLevel = HeadTopDefaultInfo.nFontLevel.nDefault,
    nHealthBarSize = HeadTopDefaultInfo.nHealthBarSize.nDefault,
    nBorderWidth = HeadTopDefaultInfo.nBorderWidth.nDefault,
    nSpan = HeadTopDefaultInfo.nSpan.nDefault,
    nBorderColorRGB = HeadTopDefaultInfo.nBorderColorRGB.nDefault,
}
CustomData.Register(CustomDataType.Global, "HeadTopBarSetting", Storage.HeadTopBarSetting)

-- 头顶Buff
Storage.TopBuffSetting = {
    nIconSize = TopBuffDefaultInfo.nIconSize.nDefault,
    nIconPosition = TopBuffDefaultInfo.nIconPosition.nDefault,
}
CustomData.Register(CustomDataType.Global, "TopBuffSetting", Storage.TopBuffSetting)

--地图排队预约
Storage.MapAppointment = {
    tbNewAppointment = {},
}
CustomData.Register(CustomDataType.Role, "MapAppointment", Storage.MapAppointment)

-- 隐藏其他玩家技能召唤物
Storage.HiddenEmployees = {
    tbData = {},
    tbSelfData = {},
}
CustomData.Register(CustomDataType.Global, "HiddenEmployees", Storage.HiddenEmployees)

-- 侠客助战编队方案名称
Storage.PartnerAssistTeamPlanNames = {
    [1] = "助战编队一",
    [2] = "助战编队二",
    [3] = "助战编队三",
    [4] = "助战编队四",

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "PartnerAssistTeamPlanNames", Storage.PartnerAssistTeamPlanNames)

Storage.tHairDyeingName = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "tHairDyeingName", Storage.tHairDyeingName)

-- 战斗文字颜色
Storage.BattleFontColor = {
    Active = {
        [SKILL_RESULT_TYPE.PHYSICS_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.PHYSICS_DAMAGE],
        [SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE],
        [SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE],
        [SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE],
        [SKILL_RESULT_TYPE.POISON_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.POISON_DAMAGE],
        [SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE],
        [SKILL_RESULT_TYPE.THERAPY] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.THERAPY],
        [SKILL_RESULT_TYPE.STEAL_LIFE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.STEAL_LIFE],
        [SKILL_RESULT_TYPE.ABSORB_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.ABSORB_DAMAGE],
        [SKILL_RESULT_TYPE.ABSORB_THERAPY] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.ABSORB_THERAPY],
        [SKILL_RESULT_TYPE.PARRY_DAMAGE] = DAMAGE_TYPE_COLOR_ACTIVE[SKILL_RESULT_TYPE.PARRY_DAMAGE],
        DEFAULT = DAMAGE_TYPE_COLOR_ACTIVE['DEFAULT'],
    }
}
CustomData.Register(CustomDataType.Global, "BattleFontColor", Storage.BattleFontColor)

-- 帮会群密历史记录
---@type string[]
Storage.TongWhisperHistory = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}


CustomData.Register(CustomDataType.Role, "TongWhisperHistory", Storage.TongWhisperHistory)


-- 屏蔽关键字
Storage.WordBlock = {
    bIsOpen = true,
    tbWordBlockList = {},
}
CustomData.Register(CustomDataType.Global, "WordBlock", Storage.WordBlock)

-- 幻境云图
Storage.Selfie = {
    bAcceptARConsent = false,
    bSwitchUI = false,
}
CustomData.Register(CustomDataType.Global, "Selfie", Storage.Selfie)

-- 时光漫游
Storage.FilterParam = {
    nFilterIndex = 0,
    tbParams = {},
    tbMapParams = {},
    nPresetIndex = 0,
    tbCustomPresets = {}, -- 最大十个预设
}
CustomData.Register(CustomDataType.Global, "FilterParam", Storage.FilterParam)

--侠客相关设置
Storage.PartnerSetting = {
    bShowRecommend = true,
}
CustomData.Register(CustomDataType.Role, "PartnerSetting", Storage.PartnerSetting)

--密聊联系人
Storage.ChatWhisper = {
    bInit = false,
    tbPlayerList = {}
}
CustomData.Register(CustomDataType.Role, "ChatWhisper", Storage.ChatWhisper)

--AI Npc 列表
Storage.ChatAINpc = {
    bInit = false,
    tbAINpcList = {},
    bDeepThink = false,
}
CustomData.Register(CustomDataType.Role, "ChatAINpc", Storage.ChatAINpc)

-- 客服中心
Storage.ServerCenter = {
    bLookWechatGM = false,
}

CustomData.Register(CustomDataType.Role, "ServerCenter", Storage.ServerCenter)

-- 聊天监控
Storage.ChatMonitor = {
    tbKeyWord = {},  --关键词
    tbChatData = {} --监控到的聊天内容
}
CustomData.Register(CustomDataType.Role, "ChatMonitor", Storage.ChatMonitor)

-- 照片分享
Storage.PhotoShare = {
    bShareXHS = false,-- 是否分享小红书
}
CustomData.Register(CustomDataType.Role, "PhotoShare", Storage.PhotoShare)

Storage.ShareStationRule = {
    bShowRule = false,
}
CustomData.Register(CustomDataType.Role, "ShareStationRule", Storage.ShareStationRule)

-- 五味诀
Storage.FastEnchanting = {
    tbConfig = {}, -- 快捷配置
}
CustomData.Register(CustomDataType.Role, "FastEnchanting", Storage.FastEnchanting)

--寻宝模式相关
Storage.XunBaoSkillSlotInfo = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "XunBaoSkillSlotInfo", Storage.XunBaoSkillSlotInfo)

-- 乐器演奏说明
Storage.InstrumentRule = {
    bShowRule = false,-- 是否展示规则
}
CustomData.Register(CustomDataType.Role, "InstrumentRule", Storage.InstrumentRule)

Storage.Wangted = {
    bOnlyShowOnline = false,
}
CustomData.Register(CustomDataType.Role, "Wangted", Storage.Wangted)

--奇遇
Storage.Adventure = {
    nFilterClass = 1,
}
CustomData.Register(CustomDataType.Role, "Adventure", Storage.Adventure)

--语音房间
Storage.RoomVoice = {
    tbLikeList = {},
    bAgreenRule = false,
}
CustomData.Register(CustomDataType.Role, "RoomVoice", Storage.RoomVoice)

-- 生日名片红点
Storage.Birthday = {
    bShowRedPoint = true,
}
CustomData.Register(CustomDataType.Role, "Birthday", Storage.Birthday)

-- 宏
g_Macro = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "Macro", g_Macro)

Storage.MatchThreeGame = {
    bShowStartHint = true,
    bShowSoundTips = true,
}
CustomData.Register(CustomDataType.Role, "MatchThreeGame", Storage.MatchThreeGame)

Storage.SpringFestivalFirstEnter = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Role, "SpringFestivalFirstEnter", Storage.SpringFestivalFirstEnter)

-- 储存秘境策略优化的必要数据
Storage.DungeonOptimize = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
CustomData.Register(CustomDataType.Global, "DungeonOptimize", Storage.DungeonOptimize)

Storage.XiaoChengWuBuffTips = {
    tbTipsList = {}
}
CustomData.Register(CustomDataType.Role, "MatchThreeGame", Storage.XiaoChengWuBuffTips)

Storage.QingMingEffect = {
    tShownEffect = {},
    bChapterEffectShown = false
}
CustomData.Register(CustomDataType.Role, "QingMingEffect", Storage.QingMingEffect)

--江湖快报
Storage.OperationCenter = {
    tRedDotVersion = {},
}
CustomData.Register(CustomDataType.Role, "OperationCenter", Storage.OperationCenter)

--荣誉挑战红点
Storage.ChallengeHorseSlot = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
}
CustomData.Register(CustomDataType.Role, "ChallengeHorseSlot", Storage.ChallengeHorseSlot)