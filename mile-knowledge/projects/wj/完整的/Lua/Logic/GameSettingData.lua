GameSettingData = GameSettingData or { className = "GameSettingData", SelectedMap = {} }

--MAX_CLASS_SHORT_CUT_ID_NUM = 1000 -- 每个大类最多支持1000个
local KILL_SOUND_INTERVAL = GLOBAL.GAME_FPS / 10    -- 端游配置为100ms，这里转化为帧来判定
local KILL_INDEX_MAX = 5
local KILL_COUNT_INTERVAL = 7 * GLOBAL.GAME_FPS
local CLEAR_POOL_TIME = 7 * GLOBAL.GAME_FPS   -- 端游配置为7000ms，这里转化为帧来判定

local tKillSoundKeys = {
    UISettingKey.HitDialogue_1,
    UISettingKey.HitDialogue_2,
    UISettingKey.HitDialogue_3,
    UISettingKey.HitDialogue_4,
    UISettingKey.HitDialogue_5,
}

function GameSettingData.Init()
    Event.UnRegAll(GameSettingData)

    -- 提审版本不用离线存盘
    GameSettingData.bShouldInitSetting = false

    --TODO: 临时设置玩家特效数量限制
    --KG3DEngine.SetMobileEngineOption({nClientOtherPlaySFXLimit = 10})
    -- 开启特殊Npc的特效不参与裁减
    rlcmd("enable special npc sfx no clip 1")
    -- 播放声音时检测本地文件是否存在（避免边玩变下）
    rlcmd("play sound check file is exist in local 1")
    -- 开启隐藏的角色的技能冒字
    rlcmd("enable hidden character skill text 1")

    GameSettingData.InitKillSound()
    GameSettingData.InitVersionSetting()
    GameSettingData.InitSoundSetting()

    GameSettingData.StoreNewValue(UISettingKey.ToggleWalk, GameSettingType.ToggleRunOrWalk.ToggleRun)  -- 默认跑步状态
    GameSettingData.StoreNewValue(UISettingKey.PlayerDisplay, GameSettingType.PlayDisplay.All)-- 玩家显示在游戏启动时该默认为显示全部状态
    QualityMgr.Init()

    Event.Reg(GameSettingData, EventType.OnSprintFightStateChanged, function(bSprint)
        if bSprint then
            GameSettingData.ApplyNewValue(UISettingKey.ToggleWalk, GameSettingType.ToggleRunOrWalk.ToggleRun) -- 进入轻功状态自动取消走路
        end
    end)

    Event.Reg(GameSettingData, EventType.OnClientPlayerEnter, function(szRoleName)
        --LOG.INFO("EventType.OnClientPlayerEnter")
        GameSettingData.bShouldInitSetting = true
        local tGameSettingTypeList = {
            [GameSettingType.CharacterHitVoice.Male.nRoleType] = GameSettingType.CharacterHitVoice.Male,
            [GameSettingType.CharacterHitVoice.Female.nRoleType] = GameSettingType.CharacterHitVoice.Female,
            [GameSettingType.CharacterHitVoice.Boy.nRoleType] = GameSettingType.CharacterHitVoice.Boy,
            [GameSettingType.CharacterHitVoice.Girl.nRoleType] = GameSettingType.CharacterHitVoice.Girl
        }
        local nRoleType = GetClientPlayer().nRoleType
        if Storage.CharacterSetting.nPlaySoundVersion ~= UISettingNewStorageTab_Default.Version[SettingCategory.Sound] then
            Storage.CharacterSetting.nPlaySoundVersion = UISettingNewStorageTab_Default.Version[SettingCategory.Sound]
            GameSettingData.StoreNewValue(UISettingKey.DamageVocal, tGameSettingTypeList[nRoleType])
        end

        if GameSettingData.GetNewValue(UISettingKey.DamageVocal, false) == nil then
            GameSettingData.StoreNewValue(UISettingKey.DamageVocal, tGameSettingTypeList[nRoleType])
        end

        local tConfig = UISettingKey2SettingConfig[UISettingKey.DamageVocal]
        if tConfig then
            tConfig.defaultValue = tGameSettingTypeList[nRoleType]
        end

        Timer.Add(GameSettingData, 0.1, function()
            GameSettingData.InitSettingInGameByKey(SettingCategory.Display)
            GameSettingData.InitSettingInGameByKey(SettingCategory.Operate)
            GameSettingData.InitSettingInGameByKey(SettingCategory.Interface)
            GameSettingData.InitSettingInGameByKey(SettingCategory.GamePad)
            GameSettingData.InitSettingInGameByKey(SettingCategory.SkillEnhance)

            local bHideHat = GetClientPlayer().bHideHat  -- 隐藏帽子需要读取player身上的数据
            PlayerData.HideHat(bHideHat)

            GameSettingData.bShouldInitSetting = false

            UISettingStoreTab.Flush()
        end)
    end)

    Event.Reg(GameSettingData, "PLAY_SOUND_FINISHED", function(dwSoundID)
        GameSettingData.OnPlaySoundFinish(dwSoundID)
    end)

    Event.Reg(GameSettingData, "SYNC_SOUND_ID", function(dwSoundID, szSound)
        local tKillSoundData = GameSettingData.tKillSoundData

        if tKillSoundData and szSound == tKillSoundData.szSound then
            tKillSoundData.dwSoundID = dwSoundID
        end
    end)

    Event.Reg(GameSettingData, "CURL_REQUEST_RESULT", function()
        local szKey = arg0
        local bSuccess = arg1
        local szValue = arg2
        local uBufSize = arg3

        if szKey == "Post_GameLogReport" then

            if bSuccess and szValue == "OK" then
                TipsHelper.ShowNormalTip("上传日志成功")
                LOG.INFO("GameLogReport CURL_REQUEST_RESULT Success!")
                GameSettingData.bPostReport = true
            else
                TipsHelper.ShowNormalTip("上传日志失败")
                LOG.ERROR("GameLogReport CURL_REQUEST_RESULT Fail! %s, %s", tostring(bSuccess), szValue)
            end
        elseif szKey == "Post_OptickReport" then
            if bSuccess and szValue == "OK" then
                TipsHelper.ShowNormalTip("上传性能采集数据成功")
                LOG.INFO("OptickReport CURL_REQUEST_RESULT Success!")
                GameSettingData.bPostReport = true
            else
                TipsHelper.ShowNormalTip("上传性能采集数据失败")
                LOG.ERROR("OptickReport CURL_REQUEST_RESULT Fail! %s, %s", tostring(bSuccess), szValue)
            end
        end
    end)
    
    Event.Reg(GameSettingData, EventType.OnAccountLogout, function()
        if GetOptickCaptureState() == OptickCaptureState.Started then
            OptickStopCapture() -- 角色退出时停止收集流程
        end
    end)
end

function GameSettingData.InitSettingInGameByKey(szType)
    for nSubCategory, tList in pairs(UIGameSettingConfigTab[szType]) do
        for _, tInfo in ipairs(tList) do
            if tInfo.bInvokeFuncOnReset ~= false then
                GameSettingData.InvokeCellFunc(tInfo)
            end
        end
    end
end

function GameSettingData.UnInit()

end

local fnCheckValidity = function(tValues)
    for nIndex, tInfo in pairs(tValues) do
        local nCurrentVal = GameSettingData.GetNewValue(tInfo.szKey)
        if nCurrentVal and IsNumber(nCurrentVal) and tInfo.szKey ~= UISettingKey.GraphicsQuality then
            local minValue = tInfo.nMinVal or 0 -- 找到对应的config, 检查数值范围
            local maxValue = GetGameSettingMaxVal(tInfo)
            if maxValue ~= nil and nCurrentVal < minValue or nCurrentVal > maxValue then
                GameSettingData.StoreNewValue(tInfo.szKey, tInfo.defaultValue)
            end
        end
    end
end

-- 用于初始化新版本设置项
local fnInitializeSetting = function(tValues, szMain, szSub)
    for nIndex, tVal in pairs(tValues) do
        -- 检查合法性
        if tVal.type ~= GameSettingCellType.Button and tVal.type ~= GameSettingCellType.BlankLine then
            if tVal.szKey == UISettingKey.GraphicsQuality or tVal.szKey == UISettingKey.DamageVocal then
                UISettingKey2SettingConfig[tVal.szKey] = tVal  --无需检查 因为她们默认值为nil
            elseif tVal.bDynamic or tVal.defaultValue == nil or tVal.szKey == nil then
                if not tVal.bDynamic then
                    LOG.ERROR("%s %s %s 没有配置新版key和defaultValue", szMain, szSub, tVal.szName) -- bDynamic为true时不需要报错
                end
            else
                if UISettingNewStorageTab[tVal.szKey] == nil then
                    -- 当新版本设置存储的值不存在时进行初始化
                    local currentVal
                    if szMain == SettingCategory.Sound then
                        currentVal = UISettingStoreTab.SOUND and UISettingStoreTab.SOUND[tVal.szName]
                        if currentVal == nil and tVal.nSoundType then
                            currentVal = UISettingStoreTab.SOUND and UISettingStoreTab.SOUND[tVal.nSoundType]
                        end
                    else
                        currentVal = UISettingStoreTab[szMain]
                                and UISettingStoreTab[szMain][szSub] and UISettingStoreTab[szMain][szSub][tVal.szName]
                    end
                    if currentVal ~= nil then
                        UISettingNewStorageTab[tVal.szKey] = currentVal --用旧版存储初始化
                    else
                        UISettingNewStorageTab[tVal.szKey] = clone(tVal.defaultValue) --用新版默认值初始化
                    end
                end
                UISettingKey2SettingConfig[tVal.szKey] = tVal
            end
        end
    end
end

function GameSettingData.InitVersionSetting()
    local szIgnoreTabs = { SettingCategory.ShortcutInteraction, SettingCategory.Custom, SettingCategory.Version, SettingCategory.GamepadInteraction }

    -- 初始化新版本设置项
    for szMain, v in pairs(UIGameSettingConfigTab) do
        if not table.contain_value(szIgnoreTabs, szMain) and IsTable(v) then
            for szSub, tValues in pairs(v) do
                fnInitializeSetting(tValues, szMain, szSub)
                fnCheckValidity(tValues) --检查数值合法性
            end
        end
    end

    --旧版存盘文件版本号导入，导入后清除旧版版本号，以后就都用新的
    if UISettingStoreTab.Version then
        for szMain, nVersion in pairs(UISettingNewStorageTab.Version or {}) do
            UISettingNewStorageTab.Version[szMain] = UISettingStoreTab.Version[szMain] or 1
        end
        UISettingStoreTab.Version = nil
    end

    --检查版本号
    for szMain, _ in pairs(SettingCategory) do
        if szMain ~= SettingCategory.Version then
            local nOldVer = UISettingNewStorageTab.Version and UISettingNewStorageTab.Version[szMain]
            local nNewVer = UISettingNewStorageTab_Default.Version and UISettingNewStorageTab_Default.Version[szMain]

            local fnComparer = GameSetting_Version_Comparer[szMain] or function(nOldVer, nNewVer)
                return nNewVer and (not nOldVer or nNewVer > nOldVer)
            end

            local fnUpdater = GameSetting_Version_Updater[szMain] or function()
                GameSettingData.ResetSettingCategoryToDefault(szMain)
            end

            if fnComparer(nOldVer, nNewVer) then
                UISettingNewStorageTab.Version = UISettingNewStorageTab.Version or {}
                UISettingNewStorageTab.Version[szMain] = nNewVer
                fnUpdater(nOldVer, nNewVer)
            end
        end
    end

    GameSettingData.GenerateShortCutClass(UISettingStoreTab)
    GameSettingData.GenerateShortCutClass(UISettingStoreTabDefault)
end

function GameSettingData.InitSoundSetting(bFirstInit)
    -- 鸿蒙暂时无法使用wwise，故跳过音量设置
    if Platform.IsOHOS() then
        GameSettingData.InitSettingInGameByKey(SettingCategory.Sound)
        return
    end

    for nSoundType, szStorageKey in pairs(SoundStorageKeyDict) do
        local v = GameSettingData.GetNewValue(szStorageKey)
        if IsTable(v) then
            GameSettingData.ApplySoundVolumeSetting(nSoundType, v.Slider)
            GameSettingData.ApplySoundEnableSetting(nSoundType, not v.TogSelect)
            if bFirstInit and AppReviewMgr.IsOpenGlobalAudioMute() and nSoundType == SOUND.MAIN then
                v.TogSelect = App_GetMute()
            end
        end
    end

    GameSettingData.InitSettingInGameByKey(SettingCategory.Sound)
end

function GameSettingData.InvokeCellFunc(tCellInfo)
    if tCellInfo.type == GameSettingCellType.Button or tCellInfo.type == GameSettingCellType.SoundSlider 
            or tCellInfo.type == GameSettingCellType.MultiDropBox or tCellInfo.type == GameSettingCellType.BlankLine
            or tCellInfo.type == GameSettingCellType.SoundSlider_Short then
        return
    end

    if tCellInfo.bDynamic then
        return
    end

    local tVal = GameSettingData.GetNewValue(tCellInfo.szKey)
    if tCellInfo.type == GameSettingCellType.Slider or tCellInfo.type == GameSettingCellType.SliderCell then
        if tCellInfo.fnFunc then
            tCellInfo.fnFunc(tVal)
        else
            LOG.WARN("没有fnFunc %s", tCellInfo.szName)
        end
    elseif tCellInfo.type == GameSettingCellType.Check
            or tCellInfo.type == GameSettingCellType.DropBoxSimple or tCellInfo.type == GameSettingCellType.FontCell then
        if tCellInfo.fnFunc then
            tCellInfo.fnFunc(tVal)
        else
            LOG.WARN("没有fnFunc %s", tCellInfo.szName)
        end
    elseif tCellInfo.type == GameSettingCellType.DropBox then
        local nFuncIndex = tVal and tVal.nFuncIndex
        if nFuncIndex then
            GameSettingType.Func[nFuncIndex].fn()
        elseif tCellInfo.fnFunc then
            tCellInfo.fnFunc(tVal)
        else
            LOG.WARN("没有fnFunc %s", tCellInfo.szName)
        end
        --elseif tCellInfo.type == GameSettingCellType.Layout then
        --    for _, childCheck in ipairs(tCellInfo.childChecks) do
        --        if childCheck.fnFunc then
        --            childCheck.fnFunc(tSettingDict[childCheck.szName])
        --        else
        --            LOG.WARN("没有fnFunc %s", childCheck.szName)
        --        end
        --    end
    else
        LOG.WARN("Invalid")
        LOG.TABLE(tCellInfo)
    end
end

function GameSettingData.ApplySoundVolumeSetting(nType, fValue)
    if nType == -1 then
        SetTotalVolume(fValue)
    else
        if nType == SOUND.BG_MUSIC then
            SetVolume(SOUND.BG_MUSIC, fValue)
        elseif nType == SOUND.CHARACTER_SOUND then
            SetVolume(SOUND.CHARACTER_SOUND, fValue)
        elseif nType == SOUND.SCENE_SOUND then
            SetVolume(SOUND.SCENE_SOUND, fValue)
        elseif nType == SOUND.UI_SOUND then
            SetVolume(SOUND.UI_SOUND, fValue)
        elseif nType == SOUND.SYSTEM_TIP then
            SetVolume(SOUND.SYSTEM_TIP, fValue)
        elseif nType == SOUND.MIC_VOLUME then
            GVoiceMgr.SetMicVolume(fValue)
        elseif nType == SOUND.SPEAKER_VOLUME then
            GVoiceMgr.SetSpeakerVolume(fValue)
        elseif nType == SOUND.CHARACTER_SPEAK then
            SetVolume(SOUND.CHARACTER_SPEAK, fValue)
        end
    end
end

function GameSettingData.ApplyActorTypeVolumeSetting(nType, fValue, bEnable)
    if nType == ACTOR_SOUND.PLAYER or nType == ACTOR_SOUND.OTHER_PLAYER or nType == ACTOR_SOUND.NPC then
        SetActorTypeVolume(nType, fValue)
        if nType == ACTOR_SOUND.PLAYER then
            local bEnableCloak = GameSettingData.GetNewValue(UISettingKey.EnableCloakSound)
            SetActorTypeVolume(ACTOR_SOUND.CLOAK, bEnableCloak and fValue or 0)
        end
    elseif nType == ACTOR_SOUND.CLOAK then
        if bEnable then
            local fSetValue = GameSettingData.GetNewValue(UISettingKey.CurrentPlayerVolume)
            SetActorTypeVolume(nType, fSetValue)
        else
            SetActorTypeVolume(nType, 0)
        end
    end
end

function GameSettingData.ApplySoundEnableSetting(nType, bSelected, nProgress)
    if nType == -1 then
        EnableAllSound(bSelected)
    else
        if nType == SOUND.BG_MUSIC then
            EnableSound(SOUND.BG_MUSIC, bSelected)
        elseif nType == SOUND.CHARACTER_SOUND then
            EnableSound(SOUND.CHARACTER_SOUND, bSelected)
        elseif nType == SOUND.SCENE_SOUND then
            EnableSound(SOUND.SCENE_SOUND, bSelected)
        elseif nType == SOUND.UI_SOUND then
            EnableSound(SOUND.UI_SOUND, bSelected)
        elseif nType == SOUND.SYSTEM_TIP then
            EnableSound(SOUND.SYSTEM_TIP, bSelected)
        elseif nType == SOUND.MIC_VOLUME then
            local nMax = nProgress and nProgress or 1
            GVoiceMgr.SetMicVolume(bSelected and nMax or 0)
        elseif nType == SOUND.SPEAKER_VOLUME then
            local nMax = nProgress and nProgress or 1
            GVoiceMgr.SetSpeakerVolume(bSelected and nMax or 0)
        end
    end
end

function GameSettingData.GenerateShortCutClass(tSettingStoreTab)
    local tShortCutClassList = {}
    local tClassName2ClassIndex = {}
    for nSubIndex, tShortCutInfo in ipairs(tSettingStoreTab.ShortcutInteraction) do
        if not tClassName2ClassIndex[tShortCutInfo.szTitle] then
            table.insert(tShortCutClassList, {
                szTitle = tShortCutInfo.szTitle,
                tShortCutList = {},
            })
            tClassName2ClassIndex[tShortCutInfo.szTitle] = #tShortCutClassList
        end
        local nClassIndex = tClassName2ClassIndex[tShortCutInfo.szTitle]
        local tClass = tShortCutClassList[nClassIndex]
        table.insert(tClass.tShortCutList, nSubIndex)
    end

    tSettingStoreTab.tShortCutClassList = tShortCutClassList
end

-- 废弃 请用GetNewValue
function GameSettingData.GetGameSetting(nMainCategory, nSubCategory, szKey)
    return GetGameSetting(nMainCategory, nSubCategory, szKey)
end

-- 废弃 请用ApplyNewValue
function GameSettingData.ApplyGameSetting(nMainCategory, nSubCategory, szKey, tVal)
    SetGameSetting(nMainCategory, nSubCategory, szKey, tVal)
    CustomData.Dirty(CustomDataType.Global)

    if IsTable(tVal) and tVal.nFuncIndex then
        local fnFunc = GameSettingType.Func[tVal.nFuncIndex] and GameSettingType.Func[tVal.nFuncIndex].fn
        if fnFunc then
            fnFunc()
        else
            LOG.WARN("nFuncIndex 不存在 %s %d", tVal.szDec, tVal.nFuncIndex)
        end
    else
        local tCategory = UIGameSettingConfigTab[nMainCategory] and UIGameSettingConfigTab[nMainCategory][nSubCategory]
        for _, tInfo in pairs(tCategory) do
            if tInfo.szName == szKey then
                if tInfo.fnFunc then
                    tInfo.fnFunc(tVal)
                end
                return
            end
        end
    end
end

-- @nSoundType: SOUND.XXX, -1是主音量
-- @return: nVolumn(0~1)
function GameSettingData.GetSoundSliderValue(nSoundType)
    local tSetting = GetGameSoundSetting(nSoundType)
    if tSetting then
        return tSetting.Slider
    end
end

-------------------------------------新版设置------------------------------

function GameSettingData.StoreNewValue(szConfigKey, value)
    if szConfigKey and value ~= nil then
        Event.Dispatch(EventType.OnBeforeStoreNewSetting, szConfigKey, value)
        UISettingNewStorageTab[szConfigKey] = value
        Event.Dispatch(EventType.OnAfterStoreNewSetting, szConfigKey, value)
    elseif szConfigKey then
        LOG.ERROR("StoreNewValue 新配置出现key错误 %s", szConfigKey)
    end
end

function GameSettingData.ApplyNewValue(szConfigKey, value)
    if not szConfigKey or value == nil then
        LOG.ERROR("GameSettingData.ApplyNewValue Error, %s, %s", tostring(szConfigKey), tostring(value))
        return
    end

    local tInfo = UISettingKey2SettingConfig[szConfigKey]
    if not tInfo then
        LOG.ERROR("GameSettingData.ApplyNewValue Error, Invalid UISettingKey %s, %s", tostring(szConfigKey), tostring(value))
        return
    end

    GameSettingData.StoreNewValue(szConfigKey, value)

    if IsTable(value) and value.nFuncIndex then
        local fnFunc = GameSettingType.Func[value.nFuncIndex] and GameSettingType.Func[value.nFuncIndex].fn
        if fnFunc then
            fnFunc()
        else
            LOG.WARN("nFuncIndex 不存在 %s %d", tInfo.szDec, tInfo.nFuncIndex)
        end
    elseif tInfo.fnFunc then
        tInfo.fnFunc(value)
    end
end

function GameSettingData.GetNewValue(szConfigKey, bShouldNotBeEmpty)
    if bShouldNotBeEmpty == nil then
        bShouldNotBeEmpty = true
    end

    if szConfigKey and UISettingNewStorageTab[szConfigKey] ~= nil then
        return UISettingNewStorageTab[szConfigKey]
    elseif szConfigKey and bShouldNotBeEmpty then
        LOG.ERROR("GetNewValue 新配置出现key错误 %s", szConfigKey)
    end
end

function GameSettingData.ResetNewValue(tCellInfo)
    if tCellInfo.szKey and tCellInfo.defaultValue ~= nil then
        GameSettingData.StoreNewValue(tCellInfo.szKey, clone(tCellInfo.defaultValue))
    end
end

function GameSettingData.ResetSettingCategoryToDefault(szMain)
    if UIGameSettingConfigTab[szMain] then
        for k, category in pairs(UIGameSettingConfigTab[szMain]) do
            for _, tConfig in ipairs(category) do
                GameSettingData.ResetNewValue(tConfig)
                GameSettingData.InvokeCellFunc(tConfig)
            end
        end
    end
end

---------------------击杀音效-------------------------
function GameSettingData.InitKillSound()
    local tKillSoundData = {}
    tKillSoundData.nLastFrame = 0
    tKillSoundData.nLastKillCount = 0
    tKillSoundData.bPlayingSound = false
    tKillSoundData.tKillPool = {}
    tKillSoundData.tKillSound = {}
    local tab = g_tTable.KillSound

    for i = 2, tab:GetRowCount() do
        local tSound = tab:GetRow(i)
        tSound.szDesc = UIHelper.GBKToUTF8(tSound.szDesc)
        tKillSoundData.tKillSound[tSound.nGroup] = tKillSoundData.tKillSound[tSound.nGroup] or {}
        tKillSoundData.tKillSound[tSound.nGroup][tSound.nIndex] = tSound
        if not GameSettingType.CharacterHitWord[tSound.nGroup] then
            GameSettingType.CharacterHitWord[tSound.nGroup] = {

            }
        end
        local tWord = GameSettingType.CharacterHitWord[tSound.nGroup]
        tWord[tSound.nIndex] = {
            szDec = tSound.szDesc,
            nFuncIndex = 34,
            tFuncParam = tSound.dwID
        }
        -- local szKey = tKillSoundKeys[tSound.nGroup]
        local tConfig = UIGameSettingConfigTab.Sound[SOUND_TITLE.CHARACTER_SPEAK][tSound.nGroup + 2]
        local tValue = GameSettingData.GetNewValue(tConfig.szKey, false)
        if not tValue or #tValue == 0 then
            GameSettingData.StoreNewValue(tConfig.szKey, { tWord[tSound.nIndex] })
        end
        if not tConfig.defaultValue or #tConfig.defaultValue == 0 then
            tConfig.defaultValue = { tWord[tSound.nIndex] }
        end
        tConfig["options"][tSound.nIndex] = tWord[tSound.nIndex] -- 加到选项里
    end

    GameSettingData.tKillSoundData = tKillSoundData
end

function GameSettingData.PlayKillSound()
    local tKillSoundData = GameSettingData.tKillSoundData
    if #tKillSoundData.tKillPool == 0 then
        return
    end
    if tKillSoundData.bPlayingSound then
        return
    end

    local nKillCount = tKillSoundData.tKillPool[1]
    tKillSoundData.szSound = GameSettingData.GetSound(nKillCount) or ""

    if tKillSoundData.szSound ~= "" then
        tKillSoundData.bPlayingSound = true
        tKillSoundData.dwSoundID = PlaySound(SOUND.CHARACTER_SPEAK, tKillSoundData.szSound, true, 0, true)
        --LOG.INFO(string.format("GameSettingData.PlayKillSound szSound=%s", UIHelper.GBKToUTF8(tKillSoundData.szSound)))
    else
        table.remove(tKillSoundData.tKillPool, 1)
    end
end

function GameSettingData.AddKillCount()
    local tKillSoundData = GameSettingData.tKillSoundData
    local nCurLogicFrame = GetLogicFrameCount()
    if nCurLogicFrame - tKillSoundData.nLastFrame <= KILL_COUNT_INTERVAL then
        tKillSoundData.nLastKillCount = math.min(KILL_INDEX_MAX, tKillSoundData.nLastKillCount + 1)
        table.insert(tKillSoundData.tKillPool, tKillSoundData.nLastKillCount)
    else
        table.insert(tKillSoundData.tKillPool, 1)
        tKillSoundData.nLastKillCount = 1
    end
    tKillSoundData.nLastFrame = nCurLogicFrame
    GameSettingData.PlayKillSound()

    -- CLEAR_POOL_TIME 后清空剩下的
    tKillSoundData.nClearTimerID = tKillSoundData.nClearTimerID or Timer.AddCycle(GameSettingData, 1, function()
        nCurLogicFrame = GetLogicFrameCount()
        if nCurLogicFrame - tKillSoundData.nLastFrame <= CLEAR_POOL_TIME then
            return
        end
        local nCount = #tKillSoundData.tKillPool
        if nCount <= 1 then
            return
        end
        for i = 2, nCount do
            tKillSoundData.tKillPool[i] = nil
        end
    end)
end

function GameSettingData.GetSound(nGroup)
    local tKillSoundData = GameSettingData.tKillSoundData
    local tGroup = tKillSoundData.tKillSound[nGroup]
    if not tGroup then
        return
    end

    local tRoleInfo = GameSettingData.GetNewValue(UISettingKey.DamageVocal)
    local nRoleType = tRoleInfo and tRoleInfo.nRoleType
    if not nRoleType then
        return
    end

    local szKey = tKillSoundKeys[nGroup]
    local tWordList = GameSettingData.GetNewValue(szKey)
    if not tWordList or #tWordList == 0 then
        return
    end

    local nRVal = math.random(#tWordList)
    local tWord = tWordList[nRVal]
    if not tWord then
        return
    end

    local dwSoundID = tWord.tFuncParam
    local tSound = g_tTable.KillSound:Search(dwSoundID)
    if not tSound then
        return
    end

    return tSound["szSound" .. nRoleType]
end

function GameSettingData.OnPlaySoundFinish(dwSoundID)
    local tKillSoundData = GameSettingData.tKillSoundData
    if tKillSoundData.dwSoundID == dwSoundID then
        Timer.AddFrame(GameSettingData, KILL_SOUND_INTERVAL, function()
            table.remove(tKillSoundData.tKillPool, 1)
            tKillSoundData.bPlayingSound = false
            GameSettingData.PlayKillSound()
            GameSettingData.nIntervalID = nil
        end)
    end
end

---------------------日志&性能采集-------------------------

function GameSettingData.OnOpenLogReport(bOpen)
    local nLevel = 0
    if bOpen then
        nLevel = 255
    end

    if nLevel == KGLog_GetLevel() then
        return
    end

    KGLog_SetLevel(nLevel)
    local folder = GetFullPath("config")
    CPath.MakeDir(folder)
    if Platform.IsWindows() then
        folder = UIHelper.GBKToUTF8(folder)
    end
    local szLogContent = string.format("[Log]\nLevel=%d", nLevel)
    local filePath = folder .. "/log.ini"
    SaveDataToFile(szLogContent, filePath)
end

function GameSettingData.IsOpenLogReport()
    local logLevel = KGLog_GetLevel()
    return logLevel > 0
end

function GameSettingData.OnLogReport()
    -- local timeOut = 2*60*1000

    -- if GameSettingData.nLastReportLog and (GetTickCount() - GameSettingData.nLastReportLog < timeOut) then
    --     local remainTime = math.floor((timeOut - GetTickCount() + GameSettingData.nLastReportLog) / 1000)
    --     TipsHelper.ShowNormalTip( string.format("请等待%d秒后尝试",remainTime))
    --     return
    -- end
    if GameSettingData.bPostReport then
        TipsHelper.ShowNormalTip("日志已上报，无需重复上传")
        return
    end

    local nNetMode = App_GetNetMode()
    if nNetMode == NET_MODE.WIFI then
        GameSettingData.PostReportLogFile()
    elseif nNetMode == NET_MODE.CELLULAR then
        local szContent = "上传日志会导致少量的流量消耗，是否继续上传？"
        local dialog = UIHelper.ShowSystemConfirm(szContent, function()
            GameSettingData.PostReportLogFile()
        end)
    end
end

function GameSettingData.PostReportLogFile()
    GameSettingData.nLastReportLog = GetTickCount()
    local logFolder = GetFullPath("logs")
    if Platform.IsWindows() then
        logFolder = UIHelper.GBKToUTF8(logFolder)
    end
    logFolder = string.gsub(logFolder, "\\", "/")
    local tFilesList = Lib.ListFiles(logFolder .. "/JX3ClientX3D", true)
    local tNewFileList = {}
    for k, v in pairs(tFilesList) do
        local state = string.find(v, ".log", 1, true)
        if state then
            local fileName = CPath.GetFileName(v)
            local filePath = v
            if Platform.IsMobile() and not string.find(filePath, logFolder) then
                filePath = logFolder .. string.gsub(filePath, "logs", "")
            end
            local fileSplitStrs = string.split(string.gsub(fileName, "JX3ClientX3D_", ""), "_")
            if table.get_len(fileSplitStrs) >= 6 then
                local fileTime1 = fileSplitStrs[1] .. fileSplitStrs[2] .. fileSplitStrs[3]
                local fileTime2 = fileSplitStrs[4] .. fileSplitStrs[5] .. fileSplitStrs[6]
                table.insert(tNewFileList, { nTime1 = tonumber(fileTime1), nTime2 = tonumber(fileTime2), szPath = filePath, szFileName = fileName })
            end
        end
    end
    -- 升序排列
    table.sort(tNewFileList, function(a, b)
        if a and b then
            if a.nTime1 == b.nTime1 then
                return a.nTime2 < b.nTime2
            end
            return a.nTime1 < b.nTime1
        end
    end)

    local szUrl = "https://dasxgfile11.xoyo.com:10443/file/v1/upload/200001158"
    local count = #tNewFileList

    local onUploadFile = function(fileConfig)
        if not fileConfig then
            return
        end
        local deviceID = XGSDK_GetDeviceId()
        local fileName = fileConfig.szFileName .. ".log"
        local filePath = Platform.IsMac() and GetFullPath(fileConfig.szPath) or fileConfig.szPath
        local szAccount = Login_GetAccount()
        local szPostUrl = string.format("%s?deviceid=%s&uid=%s&filename=%s&mod=client.log",
                szUrl,
                string.is_nil(deviceID) and "User_Device_Unknown" or deviceID,
                string.is_nil(szAccount) and "User_Account_Unknown" or szAccount,
                fileName)
        local tbParams = {
            upload_file = {
                key = "file",
                content_type = "multipart/form-data",
                file = filePath,
                filename = fileConfig.szFileName .. ".log",
            }
        }

        CURL_HttpPost("Post_GameLogReport", szPostUrl, tbParams, true, 60, 60, { "Content-Type:multipart/form-data" })
        LOG.INFO("Post_GameLogReport : filePath:%s", filePath)
    end
    onUploadFile(tNewFileList[count - 1])
    onUploadFile(tNewFileList[count - 2])
    TipsHelper.ShowNormalTip("开始上传日志，请稍后")
end

local szOptickFileName = "optick_report.opt"

function GameSettingData.StartOptick()
    local nState = GetOptickCaptureState()
    if  nState == OptickCaptureState.Stopped or GetOptickCaptureState() == OptickCaptureState.Started then
        return
    end
    
    local cacheFolder = GetFullPath("cache")
    if Platform.IsWindows() then
        cacheFolder = UIHelper.GBKToUTF8(cacheFolder)
    end
    cacheFolder = string.gsub(cacheFolder, "\\", "/")

    -- 第一个参数是帧会被采集的最小耗时 比如现在是只采集60ms以上的帧 第二个是文件大小上限 单位为mb
    if OptickStartCapture(cacheFolder .. "/" .. szOptickFileName, 60, 100) then
        local nRecordSecond = 30
        local tData = {
            fnAutoClose = function()
                return GetOptickCaptureState() == OptickCaptureState.Invalid
                        or GetOptickCaptureState() == OptickCaptureState.Saved or GetOptickCaptureState() == OptickCaptureState.SavedButNoFrames
            end,
            bFromBubbleIcon = false,
        }
        local tEvent = {
            EventType.ShowOptickRecordTip, -- [1] 事件类型
            tData, -- [2] 数据
            nil, -- [3] 可选：要隐藏的事件类型
        }
        tEvent.nEndTime = nRecordSecond + GetCurrentTime()
        tEvent.bPutBackToQueue = true
        TipsHelper.PushEvent(TipsHelper.Def.Queue3, tEvent)
        UIMgr.Close(VIEW_ID.PanelGameSettings)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end
end

function GameSettingData.UploadOptick()
    local nState = GetOptickCaptureState()
    if nState == OptickCaptureState.SavedButNoFrames then
        TipsHelper.ShowImportantYellowTip("未采集到性能数据")
        return
    end

    if nState == OptickCaptureState.Saved then
        local onUploadFile = function()
            local cacheFolder = GetFullPath("cache")
            if Platform.IsWindows() then
                cacheFolder = UIHelper.GBKToUTF8(cacheFolder)
            end
            cacheFolder = string.gsub(cacheFolder, "\\", "/")

            local szUrl = "https://dasxgfile11.xoyo.com:10443/file/v1/upload/200001158"
            local deviceID = XGSDK_GetDeviceId()
            local szAccount = Login_GetAccount()
            local filePath = cacheFolder .. "/" .. szOptickFileName

            deviceID = string.is_nil(deviceID) and "User_Device_Unknown" or deviceID
            szAccount = string.is_nil(szAccount) and "User_Account_Unknown" or szAccount

            local szPostUrl = string.format("%s?deviceid=%s&uid=%s&filename=%s&mod=client.opt",
                    szUrl, deviceID, szAccount, string.format("optick_report_%s_%s.opt", deviceID, szAccount))
            local tbParams = {
                upload_file = {
                    key = "file",
                    content_type = "multipart/form-data",
                    file = filePath,
                    filename = szOptickFileName,
                }
            }

            CURL_HttpPost("Post_OptickReport", szPostUrl, tbParams, true, 60, 60, { "Content-Type:multipart/form-data" })
            LOG.INFO("Post_OptickReport : filePath:%s", filePath)
        end

        local scriptView = UIHelper.ShowConfirm("性能数据采集完成，是否上传？\n（在非WiFi环境下，上传将产生部分流量）", onUploadFile)
        if scriptView then
            scriptView:SetConfirmButtonContent("上传")
        end
    end
end

--------------------------------------------------------
function GameSettingData.OnReload()
end