-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: QualityMgr
-- Date: 2022-12-30 17:22:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

---UIGpuRecommendQualityTab逻辑表表格均衡有引用此Enum
GameQualityType = {
    INVALID = -1, -- 非法
    LOW = 1, -- 简约
    MID = 2, -- 均衡
    HIGH = 3, -- 电影
    EXTREME_HIGH = 4, -- 极致
    CUSTOM = 5, -- 自定义
    BLUE_RAY = 6     -- 蓝光
}

QualityNameToTypeEnum = {
    ["低"] = GameQualityType.LOW,
    ["中"] = GameQualityType.MID,
    ["高"] = GameQualityType.HIGH,
    ["超高"] = GameQualityType.EXTREME_HIGH,
    ["蓝光Beta"] = GameQualityType.BLUE_RAY,
}

QualityTypeToName = {
    [GameQualityType.LOW] = "简约",
    [GameQualityType.MID] = "均衡",
    [GameQualityType.HIGH] = "电影",
    [GameQualityType.EXTREME_HIGH] = "极致",
    [GameQualityType.CUSTOM] = "自定义",
    [GameQualityType.BLUE_RAY] = "蓝光Beta",
}

QualityCategory = {
    Normal = "Normal",
    Dungeon = "Dungeon",
    Homeland = "Homeland",
}

FPS_OPTION_NAME_TO_VALUE = {
    [GameSettingType.FramePerSecond.Twenty.szDec] = 20,
    [GameSettingType.FramePerSecond.TwentyFive.szDec] = 25,
    [GameSettingType.FramePerSecond.Thirty.szDec] = 30,
    [GameSettingType.FramePerSecond.FortyFive.szDec] = 45,
    [GameSettingType.FramePerSecond.Sixty.szDec] = 60,
}

local szCustomSettingKey = "CustomQualitySetting"
local szCustomEngineOptionKey = "CustomEngineOption"
local szNormalSceneQualityTypeKey = "nNormalSceneQualityType"
local szQualityCategoryKey = "szCurrentCategory"
-- 镜头光特殊配置
local kFocusFaceConfig = "data/public/focus_face_env_params_android_10.json"                -- 特殊
local kFocusFaceConfigYun = "data/public/focus_face_env_params_android_10_yun.json"         -- 云端
local kFocusFaceCofnigYunUI = "data/public/focus_face_env_params_android_10_yun_ui.json"    -- 云端UI

local tCustomizableQuality = {
    --bCampUniform = {
    --    nMainCategory = "Quality",
    --    nSubCategory = QUALITY.RENDER_EFFICIENCY,
    --    szKey = "阵营同模",
    --},
    nRenderLimit = {
        szKey = UISettingKey.PlayersOnScreen,
    },
    nRenderNpcLimit = {
        szKey = UISettingKey.NPCsOnScreen,
    },
    nClientSFXLimit = {
        szKey = UISettingKey.EffectsOnScreen,
    },
    nClientOtherPlaySFXLimit = {
        szKey = UISettingKey.OtherPlayerEffects,
    },
    nShadowQuality = {
        szKey = UISettingKey.ShadowQuality,
        tChildKeys = { "eShadowLevel" },
        tQualityToDropBoxList = {
            GameSettingType.ShadowQuality.Low,
            GameSettingType.ShadowQuality.Medium,
            GameSettingType.ShadowQuality.High,
            GameSettingType.ShadowQuality.ExtremeHigh,
        }
    },
    nRenderPrecision = {
        szKey = UISettingKey.RenderPrecision,
        tChildKeys = { "fCullerGrassDensity", "fCullerTreeDensity", "fCullerAngleLimit", "eTerrainBakeLevel" },
        tQualityToDropBoxList = {
            GameSettingType.RenderPrecision.Low,
            GameSettingType.RenderPrecision.Medium,
            GameSettingType.RenderPrecision.High,
            GameSettingType.RenderPrecision.ExtremeHigh,
            GameSettingType.RenderPrecision.BlueRay,
        }
    },
    bEnableSSAO = {
        szKey = UISettingKey.AmbientOcclusion,
        tChildKeys = { "bEnableSSAO" },
    },
    bEnableBloom = {
        szKey = UISettingKey.BloomEffect,
        tChildKeys = { "bEnableBloom" },
    },
    nAntiAliasing = {
        szKey = UISettingKey.AntiAliasing,
        tQualityToDropBoxList = {}
    },
    nGsr = {
        szKey = UISettingKey.SuperResolutionOption,
        tQualityToDropBoxList = {}
    },
    nQualityLevel = {
        szKey = UISettingKey.RenderResolution,
        tChildKeys = { "nQualityLevel", "nResolutionLevel" },
        tQualityToDropBoxList = {
            GameSettingType.RenderResolution.Low,
            GameSettingType.RenderResolution.Medium,
            GameSettingType.RenderResolution.High,
            GameSettingType.RenderResolution.ExtremeHigh,
            GameSettingType.RenderResolution.BlueRay,
        }
    },
    nSelfEffectQuality = {
        szKey = UISettingKey.SelfEffectQuality,
        tChildKeys = { "nSelfEffectQuality" },
        tQualityToDropBoxList = {
            GameSettingType.SelfEffectQuality.Low,
            GameSettingType.SelfEffectQuality.Medium,
            GameSettingType.SelfEffectQuality.High,
        }
    },
    nOtherEffectQuality = {
        szKey = UISettingKey.OtherEffectQuality,
        tChildKeys = { "nOtherEffectQuality" },
        tQualityToDropBoxList = {
            GameSettingType.OtherEffectQuality.Low,
            GameSettingType.OtherEffectQuality.Medium,
            GameSettingType.OtherEffectQuality.High,
            GameSettingType.OtherEffectQuality.ExtremeHigh,
        }
    },
    bEnableFur = {
        szKey = UISettingKey.FurEffect,
        bInitialize = true,
    },
    bEnableWeather = {
        szKey = UISettingKey.WeatherSimulation,
        bInitialize = true,
    },
    bEnableApexClothing_new = {
        szKey = UISettingKey.ClothSimulation,
        bInitialize = true,
    }
}

local tFPSParam = {
    szKey = UISettingKey.FrameRateLimit,
    tQualityToDropBoxList = {}
}

GameQualitySetting = nil
DungeonQualitySetting = nil
HomelandQualitySetting = nil
IpadQualityTypeToSetting = require("Lua/Logic/Quality/GameQualitySetting_ios_ipad.lua")
if Platform.IsAndroid() then
    GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_android.lua")
    DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_android.lua")
    HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_android.lua")
elseif Platform.IsIos() then
    GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_ios.lua")
    DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_ios.lua")
    HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_ios.lua")
elseif Platform.IsMac() then
    GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_mac.lua")
    DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_mac.lua")
    HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_mac.lua")
elseif Platform.IsOHOS() then
    GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_ohos.lua")
    DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_ohos.lua")
    HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_ohos.lua")
else
    if Channel.Is_WLColud() then
        GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_wlcloud.lua")
        DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_wlcloud.lua")
        HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_wlcloud.lua")
    else
        GameQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_windows.lua")
        DungeonQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_dungeon_windows.lua")
        HomelandQualitySetting = require("Lua/Logic/Quality/GameQualitySetting_homeland_windows.lua")
    end
end

GameQualityTypeToSetting = {
    [GameQualityType.INVALID] = GameQualitySetting.LOW,
    [GameQualityType.LOW] = GameQualitySetting.LOW,
    [GameQualityType.MID] = GameQualitySetting.MID,
    [GameQualityType.HIGH] = GameQualitySetting.HIGH,
    [GameQualityType.EXTREME_HIGH] = GameQualitySetting.EXTREME_HIGH,
    [GameQualityType.BLUE_RAY] = GameQualitySetting.BLUE_RAY or GameQualitySetting.EXTREME_HIGH,
}

DungeonQualityTypeToSetting = {
    [GameQualityType.INVALID] = DungeonQualitySetting.LOW,
    [GameQualityType.LOW] = DungeonQualitySetting.LOW,
    [GameQualityType.MID] = DungeonQualitySetting.MID,
    [GameQualityType.HIGH] = DungeonQualitySetting.HIGH,
    [GameQualityType.EXTREME_HIGH] = DungeonQualitySetting.EXTREME_HIGH,
    [GameQualityType.BLUE_RAY] = DungeonQualitySetting.BLUE_RAY or GameQualitySetting.EXTREME_HIGH,
}

HomelandQualityTypeToSetting = {
    [GameQualityType.INVALID] = HomelandQualitySetting.LOW,
    [GameQualityType.LOW] = HomelandQualitySetting.LOW,
    [GameQualityType.MID] = HomelandQualitySetting.MID,
    [GameQualityType.HIGH] = HomelandQualitySetting.HIGH,
    [GameQualityType.EXTREME_HIGH] = HomelandQualitySetting.EXTREME_HIGH,
    [GameQualityType.BLUE_RAY] = HomelandQualitySetting.BLUE_RAY or HomelandQualitySetting.EXTREME_HIGH,
}

IpadQualityTypeToSetting = {
    [GameQualityType.INVALID] = IpadQualityTypeToSetting.LOW,
    [GameQualityType.LOW] = IpadQualityTypeToSetting.LOW,
    [GameQualityType.MID] = IpadQualityTypeToSetting.MID,
    [GameQualityType.HIGH] = IpadQualityTypeToSetting.HIGH,
    [GameQualityType.EXTREME_HIGH] = IpadQualityTypeToSetting.EXTREME_HIGH,
    [GameQualityType.BLUE_RAY] = IpadQualityTypeToSetting.BLUE_RAY,
}

QualityMgr = QualityMgr or { className = "QualityMgr" }
local bIgnoreEvent = false
local self = QualityMgr
self.nCurQualityType = GameQualityType.INVALID
self.nRecommendQualityType = nil
self.tbCurQuality = nil
self.nLastQualityLevel = 0          -- 上次的引擎的画质等级（引擎参数）
self.szCurrentCategory = nil
self.bCanSwitchQuality = true       -- 是否可以切画质
self.bCanSwitchExtremeHighFrame = Platform.IsWindows() or Platform.IsMac() -- 是否可以选择超高帧率（Windows默认为true，其他平台默认为false）
self.bManual = false                -- 是否为玩家手动切换画质选项
self.bDisableCameraLight = nil      -- 是否关闭镜头光
self.bSupportIris = nil             -- 是否支持Iris（硬件插帧到120fps）
self.bForceCampUniform = false      -- 是否强制阵营同模
self.bHasLoadEnd = false            -- 场景是否已经加载完成
--TODO_xt: 2024.6.28 临时屏蔽mali的gpu的SSAO开关
self.bIsMaliGpu = nil

local function GetDefaultValue(szName, tInfo, nCurQualityType, szCurrentCategory)
    nCurQualityType = nCurQualityType or self.nCurQualityType
    local tbCurQuality = self.GetQualitySettingByType(nCurQualityType, szCurrentCategory)
    local tVal
    if szName == "nGsr" then
        tVal = GameSettingType.SuperResolution.None

        local bEnableGSR2 = tbCurQuality["bEnableGSR2"]
        local bEnableGSR2Performance = tbCurQuality["bEnableGSR2Performance"]
        local bEnableFSR = tbCurQuality["bEnableFSR"]
        local bEnableGSR = tbCurQuality["bEnableGSR"] -- FSR的性能版开关

        if bEnableFSR == true and bEnableGSR == false then
            tVal = GameSettingType.SuperResolution.FSRMode
        elseif bEnableFSR == true and bEnableGSR == true then
            tVal = GameSettingType.SuperResolution.FSRPerformanceMode
        elseif bEnableGSR2 == false and bEnableGSR2Performance == false then
            tVal = GameSettingType.SuperResolution.None
        elseif bEnableGSR2 == true and bEnableGSR2Performance == false then
            tVal = GameSettingType.SuperResolution.QualityMode
        elseif bEnableGSR2 == true and bEnableGSR2Performance == true then
            tVal = GameSettingType.SuperResolution.PerformanceMode
        end
    elseif szName == "nAntiAliasing" then
        if tbCurQuality["bEnableTAA"] == false and tbCurQuality["bEnableFXAA"] == false then
            tVal = GameSettingType.AntiAliasing.None
        elseif tbCurQuality["bEnableTAA"] == true and tbCurQuality["bEnableFXAA"] == false then
            tVal = GameSettingType.AntiAliasing.TAA
        elseif tbCurQuality["bEnableTAA"] == false and tbCurQuality["bEnableFXAA"] == true then
            tVal = GameSettingType.AntiAliasing.FXAA
        end
    elseif szName == "nFrame" then
        local nFrameVal = tbCurQuality["nFrame"]
        if nFrameVal == 20 then
            tVal = GameSettingType.FramePerSecond.Twenty
        elseif nFrameVal == 25 then
            tVal = GameSettingType.FramePerSecond.TwentyFive
        elseif nFrameVal == 30 then
            tVal = GameSettingType.FramePerSecond.Thirty
        elseif nFrameVal == 45 then
            tVal = GameSettingType.FramePerSecond.FortyFive
        elseif nFrameVal == 60 then
            tVal = GameSettingType.FramePerSecond.Sixty
        end
        tVal = QualityMgr.LimitFrameQuality(tVal) -- 限制帧率

    elseif szName == "nSelfEffectQuality" or szName == "nOtherEffectQuality" then
        local tEffectLevelToIndex = {
            [0] = 3,
            [1] = 2,
            [2] = 1,
        }
        local nEffectQuality = tbCurQuality[szName]
        local nIndex = tEffectLevelToIndex[nEffectQuality] -- 获取EffectQuality到设置选项的映射
        tVal = tInfo.tQualityToDropBoxList[nIndex]
    elseif tInfo.tQualityToDropBoxList == nil then
        return tbCurQuality[szName]
    elseif tInfo.tQualityToDropBoxList then
        local tOrderDict = {
            [GameQualityType.LOW] = 1,
            [GameQualityType.MID] = 2,
            [GameQualityType.HIGH] = 3,
            [GameQualityType.EXTREME_HIGH] = 4,
            [GameQualityType.BLUE_RAY] = 5,
        }
        local nOriginalQualityType = self.nCurQualityType == GameQualityType.CUSTOM and tbCurQuality.nQualityType or self.nCurQualityType
        local nOrder = tOrderDict[nOriginalQualityType]
        if (not nOrder or not tInfo.tQualityToDropBoxList[nOrder]) then
            if nOriginalQualityType == GameQualityType.BLUE_RAY then
                nOrder = tOrderDict[GameQualityType.EXTREME_HIGH]
                tVal = tInfo.tQualityToDropBoxList[nOrder]
            else
                LOG.ERROR(szName .. "Failed to get default value")
            end
        else
            tVal = tInfo.tQualityToDropBoxList[nOrder]
        end
    end
    return tVal
end

function QualityMgr.Init()
    QualityMgr.UpdateNewStorage()

    self.bManual = false
    -- 初始画质先从本地存储里去取，如果取不到则为第一次进入游戏进行初始化
    local nInitQualityType = GameSettingData.GetNewValue(UISettingKey.GraphicsQuality, false)
    local bVersionTooOld = false

    if nInitQualityType ~= nil then
        local tCustom = GameSettingData.GetNewValue(self.GetCustomEngineKey(QualityCategory.Normal))
        local nFileVersion = QualityMgr.GetFileVersion()
        local nSavedVersion = tCustom.Version
        if nSavedVersion == nil or nSavedVersion < nFileVersion then
            nInitQualityType = nil
        end
    end

    if nInitQualityType == nil or bVersionTooOld then
        nInitQualityType = QualityMgr.GetRecommendQualityType()
        self.OnFirstTimeInGame(nInitQualityType)
    else
        QualityMgr.UpdateSavedCustomQuality()
        self.szCurrentCategory = GameSettingData.GetNewValue(szQualityCategoryKey) -- 获取当前玩家是否在副本内
        QualityMgr.SetQualityByType(nInitQualityType)
    end

    if QualityMgr.GetRecommendQualityType() == GameQualityType.INVALID then
        LOG.ERROR("QualityMgr.Init, can not find recommend quality setting, gpu = %s, deviceModel = %s", GetDeviceGPU(), GetDeviceModel())
    end
    self.bManual = true

    if Platform.IsAndroid() then
        local nCameraLightLimit = self.getCameraLightLimit_Android()
        if nCameraLightLimit > 1 then
            self.bDisableCameraLight = true
        elseif nCameraLightLimit == 1 or Channel.Is_Tapyun() or self.checkForceFocusFaceConfig() then
            -- 2024.9.18，Android 10或是特定标注的机型
            -- 云端（抖音云通过判断是否Android 10来确认）
            -- UI、场景使用自定镜头光配置
            self.szCameraLightForUI = kFocusFaceCofnigYunUI
            rlcmd(string.format("mb set force focus face config %s", kFocusFaceConfigYun))
        end
    elseif Platform.IsIos() then
        self.bDisableCameraLight = self.checkDisableCameraLight_ios()
    end

    if Platform.IsMobile() then
        local szDeviceGPU = GetDeviceGPU()
        local nStart = Lib.StringFind(string.lower(szDeviceGPU), "mali")
        if nStart and nStart == 1 then
            self.bIsMaliGpu = true
        end
    end

    self.CanShow120Frame()
    self.InitResolutionConfig()
    self.Reg()
end

--- 将旧版本的画质数据转换至新版本
function QualityMgr.UpdateNewStorage()
    if not UISettingStoreTab.Custom then
        return
    end

    if GameSettingData.GetNewValue(szQualityCategoryKey, false) == nil then
        local nOldValue = GetGameSetting(SettingCategory.Custom, CUSTOM.MAIN, szQualityCategoryKey)
        nOldValue = nOldValue or QualityCategory.Normal
        GameSettingData.StoreNewValue(szQualityCategoryKey, nOldValue) -- 记录画质类型
    end

    if GameSettingData.GetNewValue(szNormalSceneQualityTypeKey, false) == nil then
        local nOldValue = GetGameSetting(SettingCategory.Custom, CUSTOM.MAIN, szNormalSceneQualityTypeKey)
        nOldValue = nOldValue or QualityMgr.GetRecommendQualityType
        GameSettingData.StoreNewValue(szNormalSceneQualityTypeKey, nOldValue)
    end

    for _, szCategory in pairs(QualityCategory) do
        local szEngine = self.GetCustomEngineKey(szCategory)
        local szSetting = self.GetCustomSettingKey(szCategory)

        if GameSettingData.GetNewValue(szEngine, false) == nil then
            local nOldValue = GetGameSetting(SettingCategory.Custom, CUSTOM.MAIN, szEngine)
            if nOldValue then
                GameSettingData.StoreNewValue(szEngine, nOldValue)
            end
        end

        if GameSettingData.GetNewValue(szSetting, false) == nil then
            local tTab = {}
            local tOldTab = GetGameSetting(SettingCategory.Custom, CUSTOM.MAIN, szSetting)
            if tOldTab then
                for nIndex, tInfo in ipairs(UIGameSettingConfigTab.Quality[QUALITY.RENDER_EFFICIENCY]) do
                    if tInfo.szKey and tInfo.szName and tOldTab then
                        tTab[tInfo.szKey] = tOldTab[tInfo.szName]
                    end
                end
                GameSettingData.StoreNewValue(szSetting, tTab)
            end
        end
    end
end

--- 在画质配置文件（如GameQualitySetting_windows）有新增的配置项时，将该项更新至本地已存储的的自定义配置中
function QualityMgr.UpdateSavedCustomQuality()
    for szCategory, value in pairs(QualityCategory) do
        local szKey = QualityMgr.GetCustomEngineKey(szCategory)
        local tCustomEngineOption = GameSettingData.GetNewValue(szKey)
        local nCustomQualityType = tCustomEngineOption and tCustomEngineOption.nQualityType

        if nCustomQualityType then
            local tLatestEngineOption = QualityMgr.GetQualitySettingByType(nCustomQualityType, szCategory)
            for szOption, nValue in pairs(tLatestEngineOption) do
                if tCustomEngineOption[szOption] == nil then
                    tCustomEngineOption[szOption] = nValue

                    local tCustomData = tCustomizableQuality[szOption]  -- 若该项需要暴露为可自定义的设置项，则对该设置项进行相应的初始化
                    if tCustomData and tCustomData.bInitialize then
                        local szKey = QualityMgr.GetCustomSettingKey(szCategory)
                        local tCustomSettingOption = GameSettingData.GetNewValue(szKey)
                        local tDefaultValue = GetDefaultValue(szOption, tCustomData, tCustomEngineOption.nQualityType, szCategory)
                        tCustomSettingOption[tCustomData.szKey] = tDefaultValue
                    end
                end
            end
        end
    end
end

function QualityMgr.InitResolutionConfig()
    local tResolutionInfo
    for _, tInfo in ipairs(UIGameSettingConfigTab[SettingCategory.Quality][QUALITY.MAIN]) do
        if tInfo.szName == "窗口分辨率" then
            tResolutionInfo = tInfo
        end
    end

    local nWidth, nHeight = GetRealMonitorSize()
    if nWidth >= 2560 then
        local tList = { GameSettingType.FrameSize.TwoK_First, GameSettingType.FrameSize.TwoK_Second,
                        GameSettingType.FrameSize.TwoK_Third, GameSettingType.FrameSize.TwoK_Fourth }
        table.insert_tab(tList, tResolutionInfo.options)
        tResolutionInfo.options = tList
    end

    if nWidth >= 3840 then
        local tList = { GameSettingType.FrameSize.FourK_First, GameSettingType.FrameSize.FourK_Second }
        table.insert_tab(tList, tResolutionInfo.options)
        tResolutionInfo.options = tList
    end

    table.insert(tResolutionInfo.options, 1, GameSettingType.FrameSize.NoBoarderFullScreen)
end

function QualityMgr.Reg()
    Event.UnRegAll(QualityMgr)
    Event.Reg(QualityMgr, EventType.OnQualitySettingChange, function()
        if not bIgnoreEvent then
            QualityMgr.UpdateQuality()
        end
    end)

    Event.Reg(QualityMgr, EventType.OnRoleLogin, function()
        self.szCurrentCategory = nil  -- 玩家进入游戏时 清除当前地图类型标志符
    end)

    Event.Reg(self, EventType.OnSetUIScene, function(nSceneID)
        if nSceneID then
            local szPlayerCategory = QualityMgr.GetPlayerQualityCategory()
            self.UpdateQualityWhenSceneChange(szPlayerCategory)
            self.UpdateDungeonOptimization()
        end
    end)

    Event.Reg(self, "UPDATE_REGION_INFO", function(nAreaID)
        local scene = GetClientScene()
        if not scene then
            return
        end

        local nMapID = scene.dwMapID

        -- 进入新稻香村地宫 设置一次
        if nMapID == 653 and nAreaID == 50 then
            if self.nLastMapID ~= nMapID or self.nLastAreaID ~= nAreaID then
                QualityMgr.UpdateQuality()
            end
            -- 离开新稻香村地宫 设置一次
        else
            if self.nLastMapID == 653 and self.nLastAreaID == 50 then
                QualityMgr.UpdateQuality()
            end
        end

        self.nLastMapID = nMapID
        self.nLastAreaID = nAreaID
    end)

    Event.Reg(self, EventType.OnViewOpen, function()
        if GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost) then
            local tbStack = UIMgr.tMapLayerStacks[UILayer.Page] or {}
            if #tbStack == 1 then
                QualityMgr.UpdateGameFrc(false)
            end
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost) then
            local tbStack = UIMgr.tMapLayerStacks[UILayer.Page] or {}
            if #tbStack == 0 then
                QualityMgr.UpdateGameFrc(true)
            end
        end

        if nViewID == VIEW_ID.PanelGameSettings then
            QualityMgr.ReportSuperResolutionOption()
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self._UpdateForceCampUniform()
        self.bHasLoadEnd = false
    end)
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        if self.bForceCampUniform then
            self.bForceCampUniform = false
            self.UpdateCampUniformState()
        end

        if self.nForceCampUniforTimer then
            Timer.DelTimer(self, self.nForceCampUniforTimer)
            self.nForceCampUniforTimer = nil
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self.bHasLoadEnd = true
        if Platform.IsIos() and not SceneMgr.IsReuseScene() then
            -- 美术同学让IOS端设置统一的ColorGrade参数
            -- 与场景的加载时序有冲突，需延迟到场景加载完成在设置一次
            -- 储存旧的相关画质参数
            local tColorGrade = KG3DEngine.GetColorGradeParams()
            self.tOldColorGrade = {}
            self.tOldColorGrade["FilmSlope"] = tColorGrade["FilmSlope"]
            self.tOldColorGrade["FilmToe"] = tColorGrade["FilmToe"]
            self.tOldColorGrade["FilmShoulder"] = tColorGrade["FilmShoulder"]
            self.tOldColorGrade["WhiteBalanceTemp"] = tColorGrade["WhiteBalanceTemp"]

            if GameSettingData.GetNewValue(UISettingKey.TrueColorDisplay) then
                self._EnableIosColorGrade()
            end
        end

        QualityMgr.ReportSuperResolutionOption()
    end)
end

function QualityMgr.UnInit()
    Event.UnReg(QualityMgr)
end

function QualityMgr.OnFirstTimeInGame(nRecommendQualityType)
    GameSettingData.StoreNewValue(UISettingKey.GraphicsQuality, nRecommendQualityType)
    self.nCurQualityType = nRecommendQualityType

    for key, value in pairs(QualityCategory) do
        self.szCurrentCategory = value
        self.tbCurQuality = QualityMgr.GetQualitySettingByType(nRecommendQualityType)
        QualityMgr.SyncQualitySettingOption() -- 不使用SetQualityByType以避免画质项的非必要应用
        QualityMgr.SaveCustomSetting()  --初始化各个档位的自定义画质初始值
    end

    self.szCurrentCategory = QualityMgr.GetPlayerQualityCategory()
    QualityMgr.SetQualityByType(nRecommendQualityType)
    GameSettingData.StoreNewValue(szQualityCategoryKey, self.szCurrentCategory) -- 初始化画质类型
    CustomData.Dirty(CustomDataType.Global)

    local szName = "nFrame" -- 切换画质时不改变帧率,因此进行相应的初始化
    local nVal = GetDefaultValue(szName, tFPSParam)
    GameSettingData.ApplyNewValue(tFPSParam.szKey, nVal)

    --LOG.WARN("QualityMgr.Init gpu = %s, deviceModel = %s", GetDeviceGPU(), GetDeviceModel())
    --LOG.WARN("QualityMgr GetRecommendQualityType %s", tostring(nInitQualityType))
end

function QualityMgr.OnReload()
end

---comment 获取画质影相关联的帧率
---@return integer
function QualityMgr.GetCurrentFps()
    return self.nCurrentFps
end

---comment 是否开启了IRX渲染加速120帧
---@return boolean
function QualityMgr.IsIRX120Fps()
    return self.bSupportIris and GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost)
end

function QualityMgr.UpdateQuality()
    if QualityMgr.IsQualityCustomized() then
        if self.nCurQualityType ~= GameQualityType.CUSTOM then
            self.nCurQualityType = GameQualityType.CUSTOM
            GameSettingData.StoreNewValue(UISettingKey.GraphicsQuality, GameQualityType.CUSTOM)
            GameSettingData.StoreNewValue(szNormalSceneQualityTypeKey, GameQualityType.CUSTOM) -- 记录进入副本前的画质等级
            Event.Dispatch(EventType.OnChangeToCustomQuality)
        end
        QualityMgr.SaveCustomSetting()
    end

    if self.tbCurQuality then
        for szKey, hook in pairs(GameQualityHook) do
            if IsFunction(hook) then
                self.tbCurQuality[szKey] = hook()
            end
        end
    end

    --TODO_xt: 2024.6.28 临时屏蔽mali的GPU的SSAO开关
    if self.bIsMaliGpu then
        self.tbCurQuality["bEnableSSAO"] = false
    end

    -- 当在Windows端且开启了TAA时，同时开启SSPR抗锯齿（修复水面倒影闪烁问题 @蒙占志）
    if Platform.IsWindows() then
        self.tbCurQuality["bEnableSSPRAnti"] = self.tbCurQuality["bEnableTAA"]
    end

    KG3DEngine.SetMobileEngineOption(self.tbCurQuality)

    --TODO_xt: 2024.6.11 处理特殊场景远景距离
    if g_pClientPlayer and g_pClientPlayer.GetMapID() == 655 then
        local scene = SceneMgr.GetGameScene()
        if scene then
            scene:SetCameraPerspective(nil, nil, nil, 400000)
        end
    end

    if self.nLastQualityLevel ~= self.tbCurQuality.nQualityLevel then
        self.nLastQualityLevel = self.tbCurQuality.nQualityLevel
        Event.Dispatch(EventType.OnEngineQualityLevelChange, self.tbCurQuality.nQualityLevel)
    end
end

function QualityMgr.GetCurQualityType()
    return self.nCurQualityType
end

--获取当前画质的基础画质类型（若当前为自定义画质，仍可返回变为自定义之前的基础画质
function QualityMgr.GetBasicQualityType()
    if not self.tbCurQuality or not self.tbCurQuality.nQualityType then
        return GameQualityType.INVALID
    end
    return self.tbCurQuality.nQualityType
end

function QualityMgr.IsQualityCustomized(bForced)
    if not bForced and self.nCurQualityType == GameQualityType.CUSTOM then
        return true
    end

    local tbOriginalSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetBasicQualityType())
    for szName, tInfo in pairs(tCustomizableQuality) do
        local tValue = GameSettingData.GetNewValue(tInfo.szKey)
        if IsTable(tInfo) and tInfo.tQualityToDropBoxList then
            if tValue ~= GetDefaultValue(szName, tInfo) then
                return true
            end
        elseif tValue ~= tbOriginalSetting[szName] then
            return true
        end
    end

    return false
end

function QualityMgr.SyncQualitySettingOption()
    if self.nCurQualityType ~= GameQualityType.CUSTOM then
        for szName, tInfo in pairs(tCustomizableQuality) do
            local nVal = GetDefaultValue(szName, tInfo)
            GameSettingData.StoreNewValue(tInfo.szKey, nVal)
        end
    end
end

--应用与引擎Option无关的设置项
function QualityMgr.ApplySetting()
    local tSubCategories = { QUALITY.MAIN, QUALITY.RENDER_EFFICIENCY }
    for _, nSubCategory in ipairs(tSubCategories) do
        for i, rowCell in ipairs(UIGameSettingConfigTab[SettingCategory.Quality][nSubCategory]) do
            if rowCell.bInvokeFuncOnReset then
                GameSettingData.InvokeCellFunc(rowCell)
            end
        end
    end

    QualityMgr._UpdateIK()
    QualityMgr._UpdateBlurSize()
    QualityMgr._UpdateCASCoeff()
    QualityMgr._UpdateHDFaceCount()
end

function QualityMgr.ModifyCurQuality(szKey, value, bUpdate)
    if string.is_nil(szKey) then
        return
    end

    -- 这个值要克隆出来
    if self.tbCurQuality[szKey] ~= nil then
        self.tbCurQuality[szKey] = value
    end

    if bUpdate ~= false then
        QualityMgr.UpdateQuality()
    end
end

--应用新画质画质
function QualityMgr.SetQualityByType(nType, tExtraSetting)

    if not nType then
        return
    end

    local tbSetting = QualityMgr.GetQualitySettingByType(nType)
    if nType == GameQualityType.CUSTOM then
        local tVal = clone(GameSettingData.GetNewValue(self.GetCustomSettingKey(self.szCurrentCategory)))
        for szKey, tVal in pairs(tVal) do
            GameSettingData.StoreNewValue(szKey, tVal)
        end
    end

    if not tbSetting then
        return
    end

    if tExtraSetting then
        for k, v in pairs(tExtraSetting) do
            if tbSetting[k] then
                tbSetting[k] = v
            end
        end
    end

    self.nCurQualityType = nType
    self.tbCurQuality = tbSetting

    if self.szCurrentCategory == QualityCategory.Normal then
        GameSettingData.StoreNewValue(szNormalSceneQualityTypeKey, self.nCurQualityType) -- 记录普通场景的画质等级
    end
    rlcmd("update quality type " .. nType)

    bIgnoreEvent = true -- 防止ApplySetting时产生的事件回调
    QualityMgr.SyncQualitySettingOption()
    QualityMgr.ApplySetting()
    QualityMgr.UpdateQuality()
    bIgnoreEvent = false

    SetVideoQualityLevel(nType)
end

function QualityMgr.GetQualityNameByType(nType)
    local szName = QualityTypeToName[nType]
    return szName or ""
end

function QualityMgr.GetQualitySettingByType(nType, szCurrentCategory)
    szCurrentCategory = szCurrentCategory or self.szCurrentCategory

    -- 自定义画质从UISettingStoreTab均衡获取，默认为电影画质
    if nType == GameQualityType.CUSTOM then
        return Lib.copyTab(GameSettingData.GetNewValue(self.GetCustomEngineKey(self.szCurrentCategory)))
    else
        local tQualityParams = Lib.copyTab(GameQualityTypeToSetting[nType])
        local tModifiers = {}
        if szCurrentCategory == QualityCategory.Normal then
            if Device.IsIPad() then
                tModifiers = IpadQualityTypeToSetting[nType]
            end
        elseif szCurrentCategory == QualityCategory.Dungeon then
            tModifiers = DungeonQualityTypeToSetting[nType]
        elseif szCurrentCategory == QualityCategory.Homeland then
            tModifiers = HomelandQualityTypeToSetting[nType]
        end
        for key, value in pairs(tModifiers) do
            tQualityParams[key] = value
        end
        return tQualityParams
    end
end

function QualityMgr.SaveCustomSetting(szCurrentCategory)
    szCurrentCategory = szCurrentCategory or self.szCurrentCategory
    self.tbCurQuality.Version = QualityMgr.GetFileVersion() -- 存储当前版本号

    local tTab = {} --存储当前画质设置
    for nIndex, tInfo in ipairs(UIGameSettingConfigTab.Quality[QUALITY.RENDER_EFFICIENCY]) do
        if tInfo.szKey then
            tTab[tInfo.szKey] = GameSettingData.GetNewValue(tInfo.szKey)
        end
    end

    GameSettingData.StoreNewValue(self.GetCustomEngineKey(szCurrentCategory), clone(self.tbCurQuality)) --存储当前画质具体参数
    GameSettingData.StoreNewValue(self.GetCustomSettingKey(szCurrentCategory), tTab) --存储当前画质为自定义画质

    CustomData.Dirty(CustomDataType.Global)
end

function QualityMgr.ResetToDefaultQuality()
    for k, category in pairs(UIGameSettingConfigTab[SettingCategory.Quality]) do
        for _, tConfig in ipairs(category) do
            GameSettingData.ResetNewValue(tConfig)
        end
    end

    local nInitQualityType = QualityMgr.GetRecommendQualityType()
    self.OnFirstTimeInGame(nInitQualityType)
end

function QualityMgr.UpdateQualityWhenSceneChange(szCategory)
    local bOptimizeHomeland = GameSettingData.GetNewValue(UISettingKey.HomeAutomationOptimizationStrategy)
    if (not bOptimizeHomeland and szCategory == QualityCategory.Homeland) or szCategory == QualityCategory.Dungeon then
        szCategory = QualityCategory.Normal --关闭优化策略时 将对应场景视为普通场景
    end

    local bLoginScene = SceneMgr.GetCurSceneID() == LOGIN_SCENE_ID
    if not bLoginScene and szCategory ~= self.szCurrentCategory then
        self.bManual = false
        self.szCurrentCategory = szCategory
        GameSettingData.StoreNewValue(szQualityCategoryKey, self.szCurrentCategory) -- 记录画质类型

        --进入副本或家园
        if szCategory ~= QualityCategory.Normal then
            self.nCurQualityType = self.nCurQualityType == GameQualityType.CUSTOM
                    and self.GetRecommendQualityType() or self.nCurQualityType -- 如果当前为自定义画质则切换为推荐画质等级

            if Device.IsUnderIOS15() and DungeonData.IsInDungeon() then
                self.nCurQualityType = GameQualityType.MID
            end

            self.SetQualityByType(self.nCurQualityType)
        else
            --退出副本
            local nSavedQualityType = GameSettingData.GetNewValue(szNormalSceneQualityTypeKey) -- 恢复为进入副本前的画质等级
            self.nCurQualityType = nSavedQualityType or QualityMgr.GetRecommendQualityType()
            self.SetQualityByType(self.nCurQualityType)
        end
        GameSettingData.StoreNewValue(UISettingKey.GraphicsQuality, self.nCurQualityType)
        self.bManual = true
    else
        -- 这里可以设置每次场景切换时都需要应用的一些画质参数更新
        self.UpdateQuality()
        self._UpdateBlurSize() -- 需要每次进场景都设置一下
        self._UpdateCASCoeff()
        self._UpdateHDFaceCount()
    end
end

-- 新版秘境优化流程
function QualityMgr.UpdateDungeonOptimization()
    local szCategory = QualityMgr.GetPlayerQualityCategory()
    local bOptimizeDungeon = GameSettingData.GetNewValue(UISettingKey.DungeonOptimizationStrategy1)
    if (not bOptimizeDungeon and szCategory == QualityCategory.Dungeon) or szCategory == QualityCategory.Homeland then
        szCategory = QualityCategory.Normal --关闭优化策略时 将对应场景视为普通场景
    end
    if self.szSceneCategory ~= szCategory then
        self.szSceneCategory = szCategory

        local szHide = "set hide all employee npc 1"
        local szShow = "set hide all employee npc 0"
        rlcmd(szCategory == QualityCategory.Dungeon and szHide or szShow)

        SoundMgr.OnSceneTypeChange(szCategory)

        -- 进副本应用
        if szCategory == QualityCategory.Dungeon then
            Storage.DungeonOptimize.nLastQualityType = GameSettingData.GetNewValue(UISettingKey.GraphicsQuality)
            Storage.DungeonOptimize.tOtherEffQuality = GameSettingData.GetNewValue(UISettingKey.OtherEffectQuality) -- 进入副本时存储 其他玩家特效质量
            GameSettingData.ApplyNewValue(UISettingKey.OtherEffectQuality, GameSettingType.OtherEffectQuality.Low) -- 将“其他玩家特效质量”调整为低

            local nMapID = g_pClientPlayer and g_pClientPlayer.GetMapID()
            local tSpecialMapIDList = { 793, 794, 795 }
            local bForceResolution = Device.GetDeviceTotalMemorySize(true) < 4.1 and Platform.IsIos() and table.contain_value(tSpecialMapIDList, nMapID)
            if bForceResolution then
                Storage.DungeonOptimize.tLastRenderResolution = GameSettingData.GetNewValue(UISettingKey.RenderResolution) -- 小于极致的画质进入副本时渲染分辨率改为低
                GameSettingData.StoreNewValue(UISettingKey.RenderResolution, GameSettingType.RenderResolution.Low)
                KG3DEngine.SetMobileEngineOption({ nQualityLevel = 1, nResolutionLevel = 1 })

                Storage.DungeonOptimize.nLastPlayersOnScreen = GameSettingData.GetNewValue(UISettingKey.PlayersOnScreen)
                GameSettingData.ApplyNewValue(UISettingKey.PlayersOnScreen, 3)
            end

        -- 出副本还原
        elseif szCategory == QualityCategory.Normal and Storage.DungeonOptimize.tOtherEffQuality then
            local tTarget = Storage.DungeonOptimize.tOtherEffQuality
            GameSettingData.ApplyNewValue(UISettingKey.OtherEffectQuality, tTarget) -- 还原“其他玩家特效质量”副本外设置

            if not QualityMgr.IsQualityCustomized(true) and Storage.DungeonOptimize.nLastQualityType then
                QualityMgr.SetQualityByType(Storage.DungeonOptimize.nLastQualityType)-- 还原“其他玩家特效质量”副本外画质等级
            end

            if Platform.IsIos() and Storage.DungeonOptimize.tLastRenderResolution then
                GameSettingData.ApplyNewValue(UISettingKey.RenderResolution, Storage.DungeonOptimize.tLastRenderResolution)
            end

            if Platform.IsIos() and Storage.DungeonOptimize.nLastPlayersOnScreen then
                GameSettingData.ApplyNewValue(UISettingKey.PlayersOnScreen, Storage.DungeonOptimize.nLastPlayersOnScreen)
            end

            Storage.DungeonOptimize.tLastRenderResolution = nil
            Storage.DungeonOptimize.tOtherEffQuality = nil
            Storage.DungeonOptimize.nLastQualityType = nil
            Storage.DungeonOptimize.nLastPlayersOnScreen = nil
        end
    end
end

--脚步贴地修正数量根据不同画质档次来控制不同的数量
function QualityMgr._UpdateIK()
    local szKey = "nSimIK"
    local tValue = self.tbCurQuality[szKey]

    if tValue then
        SIM_SetIKCount(tValue)
    else
        LOG.WARN("_UpdateIK Error %d ", self.nCurQualityType)
    end
end

--镜头景深模糊值
function QualityMgr._UpdateBlurSize()
    local szKey = "nDofGatherBlurSize"
    local nBlurSize = self.tbCurQuality[szKey]

    if nBlurSize then
        KG3DEngine.SetPostRenderDofGatherBlurSize(nBlurSize)
    else
        LOG.WARN("_UpdateBlurSize Error %d ", self.nCurQualityType)
    end
end

function QualityMgr._UpdateCASCoeff()
    local szKey = "nCASCoeff"
    local nCASCoeff = self.tbCurQuality[szKey]
    if nCASCoeff then
        KG3DEngine.SetCASCoff(nCASCoeff)
    end
end

function QualityMgr.GetHDFaceCount()
    if APIHelper.IsMultiPlayerScene() or DungeonData.IsInDungeon() then
        return 0
    end
    return self.tbCurQuality["nHDFaceCount"] or 0
end

function QualityMgr._UpdateHDFaceCount()
    local nCount = self.GetHDFaceCount()
    RLEnv.GetLowerVisibleCtrl():SetHDFaceCount(nCount)
end

function QualityMgr._EnableIosColorGrade()
    if self.bHasLoadEnd and self.tOldColorGrade then
        local tColorGrade = KG3DEngine.GetColorGradeParams()
        tColorGrade["FilmSlope"] = 0.96
        tColorGrade["FilmToe"] = 0.6
        tColorGrade["FilmShoulder"] = 0.40
        tColorGrade["WhiteBalanceTemp"] = self.tOldColorGrade["WhiteBalanceTemp"] - 500
        KG3DEngine.SetColorGradeParams(tColorGrade)
    end
end

function QualityMgr._DisableIosColorGrade()
    if self.bHasLoadEnd and self.tOldColorGrade then
        local tColorGrade = KG3DEngine.GetColorGradeParams()
        for k, v in pairs(self.tOldColorGrade) do
            tColorGrade[k] = v
        end
        KG3DEngine.SetColorGradeParams(tColorGrade)
    end
end

-- 将 19:30:20 转换为 19*3600 + 30*60 + 20
local function _toDayTime(sz)
    local t = string.split(sz, ':')
    return
    (t[1] and tonumber(t[1]) * 3600 or 0) +
            (t[2] and tonumber(t[2]) * 60 or 0) +
            (t[3] and tonumber(t[3]) or 0)
end

-- 手机端强制开启同模效果
function QualityMgr._UpdateForceCampUniform()
    local nMapID = g_pClientPlayer.GetMapID()
    if Platform.IsMobile() and table.contain_value(MOBILE_FORCE_CAMP_UNIFORM_MAPS, nMapID) then
        self.bForceCampUniform = true
        self.UpdateCampUniformState()
        return
    end

    local tTimeBlocks = {}
    for _, t in pairs(UIForceCampUniform) do
        if t.nMapID == nMapID then
            -- nWeekDay=1~7, but TimeLib.GetTodayTime() will get {0~6}
            table.insert(tTimeBlocks, { t.nWeekDay % 7, _toDayTime(t.szBeginTime), _toDayTime(t.szEndTime) })
        end
    end
    if #tTimeBlocks == 0 then
        return
    end

    local fnCheck = function()
        local tTime = TimeLib.GetTodayTime()
        local nWeekDay = tTime.weekday
        local nDayTime = tTime.hour * 3600 + tTime.minute * 60 + tTime.second
        for _, t in ipairs(tTimeBlocks) do
            if nWeekDay == t[1] and nDayTime >= t[2] and nDayTime < t[3] then
                return true
            end
        end
        return false
    end

    local fnTimer = function()
        local bForce = fnCheck()
        if self.bForceCampUniform == bForce then
            return
        end

        if bForce then
            self.bForceCampUniform = true
            self.UpdateCampUniformState()
        else
            self.bForceCampUniform = false
            self.UpdateCampUniformState()
        end
    end
    fnTimer()
    self.nForceCampUniforTimer = Timer.AddCycle(self, 5, fnTimer)
end

----------------内部函数------------------
function QualityMgr.GetCustomSettingKey(szCurrentCategory)
    return szCurrentCategory .. szCustomSettingKey
end

function QualityMgr.GetCustomEngineKey(szCurrentCategory)
    return szCurrentCategory .. szCustomEngineOptionKey
end

----------------UIGameSettingConfigTab相关接口------------------

function QualityMgr.UpdateQualitySettingByKey(szQualityKey)
    local tParam = tCustomizableQuality[szQualityKey]
    local tKeys = tParam.tChildKeys
    if not tKeys then
        LOG.ERROR("QualityMgr.UpdateQualitySettingByKey Error %s, there is no tChildKeys", szQualityKey)
        return
    end
    local tValue = GameSettingData.GetNewValue(tParam.szKey)
    local nType = QualityNameToTypeEnum[tValue.szDec]
    local tSetting = QualityMgr.GetQualitySettingByType(nType)

    for _, szParamKey in ipairs(tKeys) do
        local nTargetVal = tSetting[szParamKey]
        if nTargetVal ~= nil then
            QualityMgr.ModifyCurQuality(szParamKey, nTargetVal, false)
        else
            LOG.ERROR("UpdateShadowQuality Error %s %s", tParam.szKey, szParamKey)
        end
    end
    --QualityMgr.UpdateQuality()
end

-- 获取设置界面选中的ShadowLevel
function QualityMgr.GetOptionShadowLevel()
    local tParam = tCustomizableQuality and tCustomizableQuality.nShadowQuality
    local nType = nil
    if tParam then
        local tValue = GameSettingData.GetNewValue(tParam.szKey)
        if tValue then
            nType = QualityNameToTypeEnum[tValue.szDec]
        end
    end

    if nType == nil then
        local nCurQualityType = QualityMgr.GetCurQualityType()
        local tbSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
        nType = tbSetting.eShadowLevel
    end

    return nType
end

function QualityMgr.UpdateAntiAliasing()
    local tParam = tCustomizableQuality.nAntiAliasing

    local tValue = GameSettingData.GetNewValue(tParam.szKey)
    if tValue.szDec == GameSettingType.AntiAliasing.None.szDec then
        QualityMgr.ModifyCurQuality("bEnableFXAA", false, false)
        QualityMgr.ModifyCurQuality("bEnableTAA", false)
    elseif tValue.szDec == GameSettingType.AntiAliasing.FXAA.szDec then
        QualityMgr.ModifyCurQuality("bEnableFXAA", true, false)
        QualityMgr.ModifyCurQuality("bEnableTAA", false)
    elseif tValue.szDec == GameSettingType.AntiAliasing.TAA.szDec then
        QualityMgr.ModifyCurQuality("bEnableFXAA", false, false)
        QualityMgr.ModifyCurQuality("bEnableTAA", true)
    else
        LOG.ERROR("UpdateShadowQuality Error %s", tParam.szKey)
    end
end

function QualityMgr.UpdateSuperResolution()
    -- local bOpened = false
    local tValue = GameSettingData.GetNewValue(UISettingKey.SuperResolutionOption)
    if tValue.szDec == GameSettingType.SuperResolution.None.szDec then
        QualityMgr.ModifyCurQuality("bEnableFSR", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2Performance", false)
    elseif tValue.szDec == GameSettingType.SuperResolution.FSRMode.szDec then
        QualityMgr.ModifyCurQuality("bEnableFSR", true, false)
        QualityMgr.ModifyCurQuality("bEnableGSR", false, false)

        QualityMgr.ModifyCurQuality("bEnableGSR2", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2Performance", false)
    elseif tValue.szDec == GameSettingType.SuperResolution.FSRPerformanceMode.szDec then
        QualityMgr.ModifyCurQuality("bEnableFSR", true, false)
        QualityMgr.ModifyCurQuality("bEnableGSR", true, false)

        QualityMgr.ModifyCurQuality("bEnableGSR2", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2Performance", false)
    elseif tValue.szDec == GameSettingType.SuperResolution.QualityMode.szDec then
        QualityMgr.ModifyCurQuality("bEnableFSR", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2", true, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2Performance", false)
        bOpened = true
    elseif tValue.szDec == GameSettingType.SuperResolution.PerformanceMode.szDec then
        QualityMgr.ModifyCurQuality("bEnableFSR", false, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2", true, false)
        QualityMgr.ModifyCurQuality("bEnableGSR2Performance", true)
        bOpened = true
    else
        LOG.ERROR("UpdateGSR Error")
    end

    ---- 打开GSR时需要关闭FSR，关闭GSR时还原FSR
    --local szFSRKey = "bEnableFSR"
    --local bEnableFSR = self.tbCurQuality[szFSRKey]
    --if bOpened then
    --    if bEnableFSR ~= false then
    --        QualityMgr.ModifyCurQuality(szFSRKey, false)  -- 打开GSR时需要关闭FSR
    --    end
    --else
    --    local nCurQualityType = QualityMgr.GetBasicQualityType() -- 查真实画质
    --    local tbDefaultSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
    --    local bOriginalEnableFSR = tbDefaultSetting[szFSRKey]
    --    if bOriginalEnableFSR == true then
    --        QualityMgr.ModifyCurQuality(szFSRKey, true)
    --    end
    --end
end

function QualityMgr.UpdateFramePerSecond()
    if QualityMgr.IsIRX120Fps() and not self.bManual then
        return -- 渲染加速120帧开启时不允许自动改变帧率
    end

    local tParam = tFPSParam
    local tValue = GameSettingData.GetNewValue(tParam.szKey)
    if tValue and tValue.szDec then
        local nTargetFrame = FPS_OPTION_NAME_TO_VALUE[tValue.szDec]

        if APIHelper.IsMultiPlayerScene() and Platform.IsMobile() then
            nTargetFrame = math.min(nTargetFrame, 30) --如果为多人场景 则帧率不能超过30帧
        end
        QualityMgr.nCurrentFps = nTargetFrame
        FrameMgr.SetFrameLimit(nTargetFrame)
    else
        LOG.ERROR("UpdateFrame Error %s", tParam.szKey)
    end
end

---comment 是否强制阵营同模
---@return boolean
function QualityMgr.IsForceCampUniform()
    return self.bForceCampUniform
end

---comment 是否开启阵营同模
---@return boolean
function QualityMgr.IsCampUniform()
    if self.bForceCampUniform then
        return true
    end

    return GameSettingData.GetNewValue(UISettingKey.FactionModel)
end

---comment 切换阵营同模开关标记
---@param bUniform boolean 是否同模
---@return boolean
function QualityMgr.SwitchCampUniform(bUniform)
    if self.bForceCampUniform then
        return false
    end

    GameSettingData.ApplyNewValue(UISettingKey.FactionModel, bUniform)
    return true
end

---comment 更新阵营同模状态
function QualityMgr.UpdateCampUniformState()
    local bVal = self.IsCampUniform()
    if bVal then
        rlcmd("uniform player by camp 1")
    else
        rlcmd("uniform player by camp 0")
    end
    Event.Dispatch("OnCampUniformChanged")
end

-- 自身、其他玩家特效数量
function QualityMgr.UpdateVisualEffectQuality()
    local tEffectQualityConvert = {
        ["超高"] = 0,
        ["高"] = 0,
        ["中"] = 1,
        ["低"] = 2,
    }

    local szSelfEffectQuality = GameSettingData.GetNewValue(UISettingKey.SelfEffectQuality).szDec
    local szOtherEffectQuality = GameSettingData.GetNewValue(UISettingKey.OtherEffectQuality).szDec

    local nSelf = tEffectQualityConvert[szSelfEffectQuality]
    local nOther = tEffectQualityConvert[szOtherEffectQuality]
    if nSelf and nOther then
        rlcmd("set sfx lod " .. nSelf .. " " .. nOther)
        --LOG.WARN("set sfx lod " .. nSelf .. " " .. nOther)
    else
        LOG.ERROR("UpdateVisualEffectQuality Error")
    end
end

function QualityMgr.UpdateFrameSize()
    if UISafeAreaTab[Config.szSimulateDeviceModel] then
        return -- 如果有匹配在PC上模拟移动设备的话就不往下执行
    end

    local tValue = GameSettingData.GetNewValue(UISettingKey.WindowResolution)
    if tValue.bNoBoarderFullScreen then
        SetFrameSize(12000, 12000) --
        return
    end
    if tValue.szDec then
        local tList = string.split(tValue.szDec, "x")
        local nWidth = tonumber(tList[1])
        local nHeight = tonumber(tList[2])
        if IsNumber(nWidth) and IsNumber(nHeight) then
            LOG.INFO("QualityMgr.UpdateFrameSize")

            Wnd_SetAspectRatio(nWidth / nHeight) -- 更新需要保持的宽高比
            SetFrameSize(nWidth, nHeight)
        end
    else
        LOG.WARN("UpdateFrameSize Error %s %s %s %s", tParam.nMainCategory,
                tParam.nSubCategory, tParam.szKey)
    end
end

function QualityMgr.UpdateGameFrc(bValue)
    if not self.CanShow120Frame() then
        return -- 仅在手机平台执行
    end

    if bValue == nil then
        bValue = GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost)
    end

    KG3DEngine.SetGameFrcState(bValue)

    if bValue then
        QualityMgr.nCurrentFps = 40
        FrameMgr.SetFrameLimit(40) -- 开启渲染加速时限制为40帧
    elseif self.bManual then
        QualityMgr.UpdateFramePerSecond() -- 玩家手动关闭渲染加速时恢复原来帧率
    end
end

----------------------------------

function QualityMgr.GetRecommendQualityType()
    if not self.nRecommendQualityType then
        local nRecommendQualityType = GameQualityType.INVALID

        if Platform.IsWindows() then
            nRecommendQualityType = QualityMgr.GetRecommendQualityType_windows()
        elseif Platform.IsAndroid() then
            nRecommendQualityType = QualityMgr.GetRecommendQualityType_android()
        elseif Platform.IsIos() then
            nRecommendQualityType = QualityMgr.GetRecommendQualityType_ios()
        elseif Platform.IsMac() then
            nRecommendQualityType = QualityMgr.GetRecommendQualityType_mac()
        elseif Platform.IsOHOS() then
            nRecommendQualityType = QualityMgr.GetRecommendQualityType_ohos()
        end
        self.nRecommendQualityType = nRecommendQualityType
    end

    return self.nRecommendQualityType
end

-- windows默认电影画质
function QualityMgr.GetRecommendQualityType_windows()
    local tScoreTab = Table_GetVideoCardScoreInfo()
    local nDefaultQualityType = tScoreTab[1].nVKPCType --第一行是推荐行
    local szCurGPUName = GetDeviceGPU()

    local nMaxNameLength = 0
    local nRecommendQualityType = nDefaultQualityType
    for _, tInfo in ipairs(tScoreTab) do
        local nStart = string.find(szCurGPUName, tInfo.szGPUName)
        if nStart and string.len(tInfo.szGPUName) > nMaxNameLength then
            nMaxNameLength = string.len(tInfo.szGPUName)
            nRecommendQualityType = tInfo.nVKPCType
        end
    end

    if nRecommendQualityType < GameQualityType.LOW or nRecommendQualityType > GameQualityType.EXTREME_HIGH then
        nRecommendQualityType = nDefaultQualityType --未找到推荐或推荐画质等级非法时，返回默认画质
    end
    return nRecommendQualityType
end

-- android先根据deviceModel来取，再根据GPU来取
function QualityMgr.GetRecommendQualityType_android()
    local szDeviceModel = GetDeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        return tbConf.nRecommendQuality
    end

    local szDeviceGPU = GetDeviceGPU()
    tbConf = UIGpuRecommendQualityTab[szDeviceGPU]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        return tbConf.nRecommendQuality
    end

    -- 如果以上都找不到，那就遍历，大小写不敏感，并且对GPU做模糊匹配
    local szGPULower = string.lower(szDeviceGPU)
    local nMaxRecommendQuality = nil
    for k, v in pairs(UIGpuRecommendQualityTab) do
        local nStart, nEnd = Lib.StringFind(szGPULower, string.lower(k))
        if nStart == 1 then
            self.bCanSwitchQuality = v.bCanSwitchQuality
            self.bCanSwitchExtremeHighFrame = v.bCanSwitchExtremeHighFrame
            if nMaxRecommendQuality == nil or v.nRecommendQuality > nMaxRecommendQuality then
                nMaxRecommendQuality = v.nRecommendQuality
            end
        end
    end
    if nMaxRecommendQuality then
        return nMaxRecommendQuality
    end

    return GameQualityType.MID
end

-- ios根据deviceModel来取
function QualityMgr.GetRecommendQualityType_ios()
    local nQualityType = GameQualityType.HIGH
    local szDeviceModel = GetDeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        nQualityType = tbConf.nRecommendQuality
    end
    return nQualityType
end

-- mac根据GPU来取，默认电影画质
function QualityMgr.GetRecommendQualityType_mac()
    local szDeviceGPU = GetDeviceGPU()
    tbConf = UIGpuRecommendQualityTab[szDeviceGPU]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        return tbConf.nRecommendQuality
    end

    return GameQualityType.MID
end

-- harmonyos先根据deviceModel来取，再根据GPU来取
function QualityMgr.GetRecommendQualityType_ohos()
    local szDeviceModel = GetDeviceModel()

    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        return tbConf.nRecommendQuality
    end

    local szDeviceGPU = GetDeviceGPU()

    tbConf = UIGpuRecommendQualityTab[szDeviceGPU]
    if tbConf then
        self.bCanSwitchQuality = tbConf.bCanSwitchQuality
        self.bCanSwitchExtremeHighFrame = tbConf.bCanSwitchExtremeHighFrame
        return tbConf.nRecommendQuality
    end

    -- 如果以上都找不到，那就遍历，大小写不敏感，并且对GPU做模糊匹配
    local szGPULower = string.lower(szDeviceGPU)
    local nMaxRecommendQuality = nil
    for k, v in pairs(UIGpuRecommendQualityTab) do
        local nStart, nEnd = Lib.StringFind(szGPULower, string.lower(k))
        if nStart == 1 then
            self.bCanSwitchQuality = v.bCanSwitchQuality
            self.bCanSwitchExtremeHighFrame = v.bCanSwitchExtremeHighFrame
            if nMaxRecommendQuality == nil or v.nRecommendQuality > nMaxRecommendQuality then
                nMaxRecommendQuality = v.nRecommendQuality
            end
        end
    end
    if nMaxRecommendQuality then
        return nMaxRecommendQuality
    end

    return GameQualityType.MID
end

function QualityMgr.CanSwitchQuality()
    return self.bCanSwitchQuality
end

function QualityMgr.CanSwitchExtremeHighFrame()
    return self.bCanSwitchExtremeHighFrame
end

function QualityMgr.IsExtremeHighFrame()
    return GameSettingData.GetNewValue(UISettingKey.FrameRateLimit).szDec == GameSettingType.FramePerSecond.Sixty.szDec
end

function QualityMgr.CanShow120Frame()
    if Platform.IsMobile() then
        self.bSupportIris = KG3DEngine.GetIrisGeneration() > 0
    end
    return self.bSupportIris
end

local tFrameQualityList = { GameSettingType.FramePerSecond.Twenty, GameSettingType.FramePerSecond.TwentyFive, GameSettingType.FramePerSecond.Thirty,
                            GameSettingType.FramePerSecond.FortyFive, GameSettingType.FramePerSecond.Sixty }
-- 机型配置表里新增一列，改画质时强制改为这个帧率（仅允许小于等于），手动调帧率不受影响
function QualityMgr.LimitFrameQuality(tVal)
    if Platform.IsWindows() or Platform.IsMac() then
        return tVal
    end
    local nFrameQuality = 0
    local szDeviceModel = GetDeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf then
        nFrameQuality = tbConf.nFramQuality
    end

    if nFrameQuality >= 1 and nFrameQuality <= #tFrameQualityList then
        local tNewVal = tFrameQualityList[nFrameQuality]
        if FPS_OPTION_NAME_TO_VALUE[tVal.szDec] > FPS_OPTION_NAME_TO_VALUE[tNewVal.szDec] then
            return tNewVal
        end
    end

    return tVal
end

function QualityMgr.GetFileVersion()
    return GameQualitySetting.Version
end

--脚步贴地修正数量根据不同画质档次来控制不同的数量
function QualityMgr.GetIK()
    if self.tbCurQuality then
        local szKey = "nSimIK"
        return self.tbCurQuality[szKey]
    end
    return 0
end

function QualityMgr.isUnderAndroid10()
    local szOS = Device.OS() or ""
    local nVer = tonumber(string.match(szOS, "Android (%d+)")) or 0
    return nVer <= 10
end

function QualityMgr.checkForceFocusFaceConfig()
    if self.isUnderAndroid10() then
        return true
    end

    -- 华为平板、小米10等的显卡驱动版本较低，暂使用指定的镜头光配置
    local szDevice = Device.DeviceModel()
    local szLimits = { "Xiaomi Mi 10", "HUAWEI DMG%-W00", "HUAWEI TGR%-W10" }
    for _, d in ipairs(szLimits) do
        if string.match(szDevice, d) then
            return true
        end
    end
end

function QualityMgr.getCameraLightLimit_Android()
    local szDeviceModel = Device.DeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf and tbConf.bDisableCameraLight then
        return 2
    end

    local szDeviceGPU = Device.GPU()
    local tbConf = UIGpuRecommendQualityTab[szDeviceGPU]
    if tbConf and tbConf.nCameraLightLimit > 0 then
        return tbConf.nCameraLightLimit
    end

    -- 如果以上都找不到，那就遍历，大小写不敏感，并且对GPU做模糊匹配
    local szGPULower = string.lower(szDeviceGPU)
    local tbMaxQualityConf = nil
    for k, v in pairs(UIGpuRecommendQualityTab) do
        local nStart, nEnd = Lib.StringFind(szGPULower, string.lower(k))
        if nStart == 1 then
            if tbMaxQualityConf == nil or v.nRecommendQuality > tbMaxQualityConf.nRecommendQuality then
                tbMaxQualityConf = v
            end
        end
    end
    if tbMaxQualityConf and tbMaxQualityConf.nCameraLightLimit > 0 then
        return tbMaxQualityConf.nCameraLightLimit
    end

    return 0
end

function QualityMgr.checkDisableCameraLight_ios()
    local szDeviceModel = Device.DeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf and tbConf.bDisableCameraLight then
        return true
    end
end

function QualityMgr.GetSettingOptionList()
    local tOptionList = { GameQualityType.LOW,
                          GameQualityType.MID,
                          GameQualityType.HIGH,
                          GameQualityType.EXTREME_HIGH,
                          GameQualityType.CUSTOM,
    }

    if Platform.IsIos() then
        -- IOS去掉简约画质，不可见此档画质，安卓不变还是有简约画质
        tOptionList = {
            GameQualityType.MID,
            GameQualityType.HIGH,
            GameQualityType.EXTREME_HIGH,
            GameQualityType.BLUE_RAY,
            GameQualityType.CUSTOM,
        }
    end

    if Platform.IsAndroid() then
        tOptionList = {
            GameQualityType.LOW,
            GameQualityType.MID,
            GameQualityType.HIGH,
            GameQualityType.EXTREME_HIGH,
            GameQualityType.BLUE_RAY,
            GameQualityType.CUSTOM,
        }
    end
    return tOptionList
end

-- 本机型是否能展示蓝光画质
function QualityMgr.CanShowBlueRay()
    if Platform.IsWindows() then
        return false
    end

    if Channel.IsCloud() then
        return true
    end

    local szDeviceModel = GetDeviceModel()
    local tbConf = UIDeviceModelRecommendQualityTab[szDeviceModel]
    if tbConf then
        if tbConf.bHasBlueRay ~= nil then
            return tbConf.bHasBlueRay
        end
        if tbConf.bHasBluRay ~= nil then
            return tbConf.bHasBluRay
        end
    end

    local szDeviceGPU = GetDeviceGPU()
    local tbConf = UIGpuRecommendQualityTab[szDeviceGPU]
    if tbConf then
        if tbConf.bHasBlueRay ~= nil then
            return tbConf.bHasBlueRay
        end
        if tbConf.bHasBluRay ~= nil then
            return tbConf.bHasBluRay
        end
    end

    return false
end

-- 是否设备是否支持开启布料
function QualityMgr.CanEnableClothSimulation()
    if Platform.IsWindows() then
        return true   -- Windows都可以开
    end

    if Platform.IsAndroid() then
        return QualityMgr.GetRecommendQualityType() >= GameQualityType.EXTREME_HIGH -- 安卓蓝光、极致可开，其他不可开
    end

    if Platform.IsIos() then
        return QualityMgr.CanShowBlueRay() -- ios蓝光可开，其他不可开
    end

    return false
end

---comment 在切场景的过程中尝试切换下引擎参数，预处理场景中的材质信息
function QualityMgr.TrySwitchEngineOptions()
    local tOption = KG3DEngine.GetMobileEngineOption()
    if not tOption.bEnableTAA then
        KG3DEngine.SetMobileEngineOption({ bEnableTAA = true })

        Timer.Add(self, 0.5, function()
            if not self.tbCurQuality or not self.tbCurQuality.bEnableTAA then
                KG3DEngine.SetMobileEngineOption({ bEnableTAA = false })
            end
        end)
    end
end

---comment 超分上报处理
function QualityMgr.ReportSuperResolutionOption()
    local tValue = GameSettingData.GetNewValue(UISettingKey.SuperResolutionOption) or {}
    local szValue = "--"

    if tValue.szDec == GameSettingType.SuperResolution.None.szDec then
        szValue = "0" -- 关闭
    elseif tValue.szDec == GameSettingType.SuperResolution.FSRMode.szDec then
        szValue = "1" -- FSR
    elseif tValue.szDec == GameSettingType.SuperResolution.FSRPerformanceMode.szDec then
        szValue = "2" -- FSR性能
    elseif tValue.szDec == GameSettingType.SuperResolution.QualityMode.szDec then
        szValue = "3" -- GSR
    elseif tValue.szDec == GameSettingType.SuperResolution.PerformanceMode.szDec then
        szValue = "4" -- GSR性能
    end

    AddCrasheyeExtraData("SuperResolutionOption", szValue)
end

-- 是否激活布料效果
function QualityMgr.IsEnbaleApexClothing()
    if self.tbCurQuality then
        return self.tbCurQuality["bEnableApexClothing_new"]
    end
    return false
end

function QualityMgr.GetPlayerQualityCategory()
    if g_pClientPlayer then
        local dwMapID = g_pClientPlayer.GetMapID()
        local bDungeon = DungeonData.IsInDungeon()
        local bHomeLand = HomelandData.IsHomelandMap(dwMapID) or HomelandData.IsHomelandCommunityMap(dwMapID)
        if bDungeon then
            return QualityCategory.Dungeon
        elseif bHomeLand then
            return QualityCategory.Homeland
        end
    end
    return QualityCategory.Normal
end