local fnBattleInfoNotification = function(bOpen)

end

local RenderResolutionToLevel = {
    [GameSettingType.RenderResolution.Low.szDec] = 1,
    [GameSettingType.RenderResolution.Medium.szDec] = 2,
    [GameSettingType.RenderResolution.High.szDec] = 3,
    [GameSettingType.RenderResolution.ExtremeHigh.szDec] = 4,
    [GameSettingType.RenderResolution.BlueRay.szDec] = 5,
}

--UISettingKey已移到Def/UISettingKey.lua中

SoundStorageKeyDict = {
    [SOUND.MAIN] = UISettingKey.MasterVolume,
    [SOUND.BG_MUSIC] = UISettingKey.BackgroundMusicVolume,
    [SOUND.UI_SOUND] = UISettingKey.UISoundVolume,
    [SOUND.SCENE_SOUND] = UISettingKey.SceneSoundVolume,
    [SOUND.CHARACTER_SOUND] = UISettingKey.CharacterSoundVolume,
    [SOUND.CHARACTER_SPEAK] = UISettingKey.CharacterSpeakVolume,
    [SOUND.SYSTEM_TIP] = UISettingKey.SystemTipVolume,
    [SOUND.MIC_VOLUME] = UISettingKey.MicVolume,
    [SOUND.SPEAKER_VOLUME] = UISettingKey.SpeakerVolume,
}

UISettingKey2SettingConfig = {} --UISettingKey到UIGameSettingConfigTab中设置项的映射表

UIGameSettingConfigTab = {
    OnReload = function()

    end,
    General = {
        [GENERAL.CAMERA] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "镜头模式",
                szKey = UISettingKey.CameraMode,
                defaultValue = GameSettingType.OperationMode.Joystick,
                options = {
                    GameSettingType.OperationMode.Traditional,
                    GameSettingType.OperationMode.Joystick,
                    GameSettingType.OperationMode.Locked
                },
                fnFunc = function(tInfo)
                    SetOperationMode()
                end,
                szHelpText = "3D追随模式：让玩家能够更好地代入角色，身临其境地感受游戏世界\n3D普通模式：传统自由3D视角，可全方位观察周围情况\n2.5D固定模式：固定视角，可进行缩放视角，视野会受到限制"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "镜头类型",
                szKey = UISettingKey.CameraType,
                defaultValue = GameSettingType.CameraType.NeverFollow,
                options = {
                    GameSettingType.CameraType.NeverFollow,
                    GameSettingType.CameraType.AlwaysFollow,
                    GameSettingType.CameraType.SmartFollow,
                },
                fnFunc = function(tInfo)
                    local tDict = {
                        [GameSettingType.CameraType.NeverFollow.szDec] = 0,
                        [GameSettingType.CameraType.AlwaysFollow.szDec] = 2,
                        [GameSettingType.CameraType.SmartFollow.szDec] = 1,
                    }
                    local nVal = tDict[tInfo.szDec]
                    CameraMgr.SetFollowMode(nVal)
                end,
                fnVisible = function()
                    return false --不显示在界面上，但是需要应用相关默认数值
                end,
                szHelpText = "可以在前进/站立不动的时候，始终保持您的视角位于身后\n（调整镜头旋转后会自动恢复镜头）\n从不追随：\n跑动/站立中调整镜头，均不自动归位\n总是追随：\n跑动/站立中调整镜头，均自动归位\n智能追随：\n只有跑动中调整镜头，自动归位"
            },
            {
                type = GameSettingCellType.Slider,
                szName = "镜头最大距离",
                szKey = UISettingKey.CameraMaxDistance,
                defaultValue = Platform.IsWindows() and 1083 or 833,
                nMaxVal = 2000,
                nMinVal = 167,
                fnFormat = function(value)
                    return ("%.02f"):format((value * 2400 / 2000) / 100)
                end,
                fnEnable = function()
                    return not CameraMgr.IsLockCHAndGJ()
                end,
                fnFunc = function(nVal)
                    CameraMgr.SetMaxDistance(nVal)
                end,
                tConfirm = {
                    szMessage = "当前选择的镜头最大距离较大，会进一步增加性能负载，若再出现发热或卡顿，可适当缩小。是否确定要选择？",
                    fnCanShowConfirm = function(nVal)
                        return Platform.IsMobile() and nVal >= 1500
                    end,
                }
            },
            {
                type = GameSettingCellType.Slider,
                szName = "镜头灵敏度",
                szKey = UISettingKey.CameraSensitivity,
                defaultValue = 10,
                nMaxVal = 20,
                fnFormat = function(value)

                    local nMidStep = math.floor(20 / 2 + 0.00001)
                    local nMinValue = 1 / 3

                    if value <= nMidStep then
                        return ("%.02f"):format((nMinValue * (nMidStep - value) + value) / nMidStep)
                    else
                        local nAddStep = value - nMidStep
                        return ("%.02f"):format(1 + (nAddStep * (3 - 1) / nMidStep))
                    end
                end,
                fnFunc = function(nVal)
                    local nMidStep = math.floor(20 / 2 + 0.00001)
                    local nMinValue = 1 / 3
                    local fDragSpeed

                    if nVal <= nMidStep then
                        fDragSpeed = (nMinValue * (nMidStep - nVal) + nVal) / nMidStep
                    else
                        local nAddStep = nVal - nMidStep
                        fDragSpeed = 1 + (nAddStep * (3 - 1) / nMidStep)
                    end

                    CameraMgr.SetDragSpeed(fDragSpeed)
                end
            },
            {
                type = GameSettingCellType.Slider,
                szName = "广角",
                szKey = UISettingKey.WideAngle,
                defaultValue = Platform.IsWindows() and 50 or 45,
                nMaxVal = 60,
                nMinVal = math.ceil(VideoData.Get3DEngineOptionCaps().fMinCameraAngle * 180 / math.pi),
                fnFunc = function(nVal)
                    local fCameraAngle = nVal / 180 * math.pi
                    CameraMgr.SetCameraFov(fCameraAngle)
                end,
                fnEnable = function()
                    return not CameraMgr.IsLockCHAndGJ()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "屏幕震动",
                szKey = UISettingKey.ScreenShake,
                defaultValue = true,
                fnFunc = function(bOpen)
                    KG3DEngine.SetMobileEngineOption({ bCameraShake = bOpen })
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "特写镜头",
                szKey = UISettingKey.CloseUpShot,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --LOG.WARN("特写镜头")
                    if bOpen then
                        CameraMgr.SetSegmentConfig(nil, nil, nil, true)
                    else
                        CameraMgr.SetSegmentConfig(nil, nil, nil, false)
                    end
                end,
                szHelpText = "拉近镜头会自动调整至特定位置"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "眼神跟随",
                szKey = UISettingKey.EyeTracking,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --LOG.WARN("眼神跟随")
                    if bOpen then
                        rlcmd("enable auto lookat 1")
                    else
                        rlcmd("enable auto lookat 0")
                    end
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "左右平移操作仅旋转镜头",
                szKey = UISettingKey.OnlyRotateCamera,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
                fnVisible = function()
                    return Platform.IsWindows() or (Platform.IsMobile() and KeyBoard.MobileHasKeyboard())
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "战斗反馈",
                szKey = UISettingKey.SkillFeedBack,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if bOpen then
                        rlcmd("DisableAniTagCameraShake 0")
                        rlcmd("DisableAniTagCameraAngle 0")
                    else
                        rlcmd("DisableAniTagCameraShake 1")
                        rlcmd("DisableAniTagCameraAngle 1")
                    end
                end,
                szHelpText = "勾选后，战斗中可触发技能反馈效果，如镜头抖动、镜头变化等",
                fnVisible = function()
                    return not IsMobileKungfu()
                end
            }
        },
        [GENERAL.MOUSE_SETTING] = {
            {
                type = GameSettingCellType.Slider,
                szName = "鼠标指针缩放",
                szKey = UISettingKey.MouseSize,
                defaultValue = 10,
                nMaxVal = 20,
                nMinVal = 10,
                fnFormat = function(nValue)
                    local nVal = math.min(40, nValue)
                    nVal = math.max(10, nVal)
                    nVal = nVal / 10

                    return ("%.01f"):format(nVal)
                end,
                fnFunc = function()
                    UpdateCursorSize()
                end,
                fnVisible = function()
                    return Platform.IsWindows()  -- 目前仅windows支持
                end
            },
        },
        [GENERAL.SHIELD] = {
            {
                type = GameSettingCellType.Button,
                szName = "勿扰选项",
                szBtnLabelName = "前往",
                fnFunc = function()
                    UIMgr.Open(VIEW_ID.PanelShieldPop)
                end
            },
            {
                type = GameSettingCellType.DropBox,
                bInvokeFuncOnReset = true,
                szName = "新人援助",
                szKey = UISettingKey.NewbieAssist,
                defaultValue = GameSettingType.AssistNewbieOption.NoMatter,
                options = {
                    GameSettingType.AssistNewbieOption.NoMatter,
                    GameSettingType.AssistNewbieOption.NotBeHelper,
                    GameSettingType.AssistNewbieOption.FavorNotMaxLevel,
                    GameSettingType.AssistNewbieOption.FavorMaxLevel,
                },
                fnFunc = function()
                    local nType = GameSettingData.GetNewValue(UISettingKey.NewbieAssist).nType
                    RemoteCallToServer("On_Help_UpdateType", nType)
                end,
                szHelpText = "设置接收哪些类型的新人援助"
            },
        },
        [GENERAL.PERFORMANCE] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "家园自动优化策略",
                szKey = UISettingKey.HomeAutomationOptimizationStrategy,
                defaultValue = true,
                fnFunc = function(bOpen)
                end,
                szHelpText = "开启后，进入家园场景时，自动调整性能优化配置以改善性能，离开家园则会自动还原相关调整\n关闭则在家园中可能会带来较大客户端性能压力"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "秘境自动优化策略",
                szKey = UISettingKey.DungeonOptimizationStrategy1,
                bInvokeFuncOnReset = false,
                defaultValue = true,
                fnFunc = function(bOpen)
                    QualityMgr.UpdateDungeonOptimization()
                end,
                szHelpText = "进入秘境场景时，自动调整性能优化配置以改善战斗效果，离开秘境则会自动还原相关调整"
            }
        },
        [GENERAL.ADVANCED_ANIMATION] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "动作融合",
                szKey = UISettingKey.ActionFusion,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --LOG.WARN("SIM_ChangeAnimationBlend")
                    SIM_ChangeAnimationBlend(bOpen)
                end,
                szHelpText = "开启后，角色动作之间的动作切换会更加流畅自然"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动跳过副本动画",
                szKey = UISettingKey.AutoSkipDungeonAnimation,
                defaultValue = false,
                fnFunc = function(tInfo)

                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "眨眼动画",
                szKey = UISettingKey.BlinkAnimation,
                defaultValue = true,
                fnFunc = function(bValue)
                    if bValue then
                        rlcmd("enable localeyes animation 1")
                    else
                        rlcmd("enable localeyes animation 0")
                    end
                end,
            },
        },
        [GENERAL.GAME_LOG] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "开启日志（影响性能）",
                szKey = UISettingKey.EnableLogging,
                defaultValue = false,
                bCommit = true, -- 只有日志上报会用到的配置项
                fnFunc = function(bOpen, script)
                    if script and script.BtnCommit then
                        UIHelper.SetVisible(script.BtnCommit, bOpen)
                    end
                    GameSettingData.OnOpenLogReport(bOpen)
                end,
            },
            {
                type = GameSettingCellType.BlankLine,
                szName = "分隔",
            },
            {
                type = GameSettingCellType.Button,
                szName = "性能数据采集",
                fnBtnLabelName = function()
                    return GetOptickCaptureState() == OptickCaptureState.Started and "录制中" or "开始采集"
                end,
                tEnable = {
                    fnEnable = function()
                        return GetOptickCaptureState() ~= OptickCaptureState.Stopped and GetOptickCaptureState() ~= OptickCaptureState.Started
                    end,
                },
                fnVisible = function()
                    return IsOptickEnable()
                end,
                szHelpText = "当出现卡顿、帧率抖动时，可开启性能数据采集。\n开启后，将开始采集相关数据，数据采集结束后，请上传数据并联系客服。\n数据文件达到20m后，会自动停止采集，也可提前手动结束采集。",
                fnFunc = function()
                    GameSettingData.StartOptick()
                end
            },
        },
        [GENERAL.SERVER_SYNC] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "武学分页绑定设置",
                szKey = UISettingKey.SyncSkillEquipBinding,
                defaultValue = true,
                fnFunc = function()
                    if Storage_Server.IsReady() then
                        SkillData.SyncSkillEquipBinding()
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "快捷键设置",
                szKey = UISettingKey.SyncShortcutSetting,
                defaultValue = true,
                fnFunc = function()
                    if not GameSettingData.bShouldInitSetting and Storage_Server.IsReady() then
                        ShortcutInteractionData.SyncServerShortcutSetting()
                    end
                end,
                fnVisible = function()
                    return Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileSupportKeyboard()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "聊天栏设置",
                szKey = UISettingKey.SyncChatSetting,
                defaultValue = true,
                fnFunc = function()
                    if not GameSettingData.bShouldInitSetting and Storage_Server.IsReady() then
                        ChatData.SyncChatSetting()
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "轻功设置",
                szKey = UISettingKey.SyncSprintSetting,
                defaultValue = true,
                fnFunc = function()
                    if not GameSettingData.bShouldInitSetting and Storage_Server.IsReady() then
                        SprintData.SyncServerSprintSetting()
                    end
                end,
            },
        },
    },
    Quality = {
        [QUALITY.MAIN] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "画质设置",
                szKey = UISettingKey.GraphicsQuality,
                defaultValue = nil,
                options = {
                    GameQualityType.LOW,
                    GameQualityType.MID,
                    GameQualityType.HIGH,
                    GameQualityType.EXTREME_HIGH,
                    GameQualityType.CUSTOM,
                },
                szHelpText = "建议使用推荐画质选项\n如遇发热/卡顿，请适当选择更低的选项",
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "窗口分辨率",
                szKey = UISettingKey.WindowResolution,
                defaultValue = GameSettingType.FrameSize.Eighth,
                options = {
                    GameSettingType.FrameSize.First,
                    GameSettingType.FrameSize.Second,
                    GameSettingType.FrameSize.Third,
                    GameSettingType.FrameSize.Fourth,
                    GameSettingType.FrameSize.Fifth,
                    GameSettingType.FrameSize.Sixth,
                    GameSettingType.FrameSize.Seventh,
                    GameSettingType.FrameSize.Eighth,
                    GameSettingType.FrameSize.Ninth,
                    GameSettingType.FrameSize.Tenth,
                    GameSettingType.FrameSize.Eleventh,
                    GameSettingType.FrameSize.Twelfth,
                    GameSettingType.FrameSize.Thirteenth,
                    GameSettingType.FrameSize.Fourteenth,
                    GameSettingType.FrameSize.Fifteenth,
                    GameSettingType.FrameSize.Sixteenth,
                },
                fnFunc = function(tInfo)
                    QualityMgr.UpdateFrameSize()
                end,
                fnVisible = function()
                    return Platform.IsWindows() -- Mac不显示
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "帧率上限",
                szKey = UISettingKey.FrameRateLimit,
                defaultValue = GameSettingType.FramePerSecond.Thirty,
                options = {
                    GameSettingType.FramePerSecond.Twenty,
                    GameSettingType.FramePerSecond.TwentyFive,
                    GameSettingType.FramePerSecond.Thirty,
                    GameSettingType.FramePerSecond.FortyFive,
                    GameSettingType.FramePerSecond.Sixty,
                },
                fnFunc = function()
                    QualityMgr.UpdateFramePerSecond()
                end,
                fnVisible = function()
                    local bIs120FrameEnabled = GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost)
                    return not bIs120FrameEnabled
                end,
                tConfirm = {
                    szMessage = "当前选择的帧率上限性能负载较高，如遇到发热/卡顿，请适当降低帧率上限，是否确定要选择？",
                    fnCanShowConfirm = function(tTargetInfo)
                        return Platform.IsMobile() and tTargetInfo.szDec == GameSettingType.FramePerSecond.Sixty.szDec
                    end,
                },
                tDisable = {
                    szMessage = "当前设备不兼容超高帧率",
                    fnDisable = function(tTargetInfo)
                        local bDisable = Platform.IsMobile() and not QualityMgr.CanSwitchExtremeHighFrame()
                        local bExtreme = tTargetInfo.szDec == GameSettingType.FramePerSecond.Sixty.szDec
                        return bExtreme and bDisable -- 返回true则选项变为Disable状态
                    end,
                },
                szHelpText = "游戏帧率越高，画面更流畅，可能会增加能耗和发热"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "可变着色率",
                szKey = UISettingKey.VRSLevel,
                defaultValue = GameSettingType.VRSOption.Closed,
                bInvokeFuncOnReset = true,
                szHelpText = "通过调整不同区域的着色率，降低gpu消耗",
                options = {
                    GameSettingType.VRSOption.Closed,
                    GameSettingType.VRSOption.Balance,
                    GameSettingType.VRSOption.Performance,
                },
                fnFunc = function(tOption)
                    local tConvert = {
                        [GameSettingType.VRSOption.Closed.szDec] = 0,
                        [GameSettingType.VRSOption.Balance.szDec] = 1,
                        [GameSettingType.VRSOption.Performance.szDec] = 2,
                    }
                    KG3DEngine.SetVRSLevel(tConvert[tOption.szDec])
                end,
                fnVisible = function()
                    return KG3DEngine.IsSupportVRS()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "IRX渲染加速120帧",
                szKey = UISettingKey.IRXRenderBoost,
                defaultValue = false,
                szHelpText = "渲染加速引擎启动独显芯片，实现低功耗高帧率游戏体验",
                fnFunc = function(bValue)
                    if not bValue then
                        QualityMgr.UpdateGameFrc() -- 不需要在启用时立刻更新,防止设置界面滑动卡顿
                    end
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                fnVisible = QualityMgr.CanShow120Frame,
                tConfirm = {
                    szMessage = "是否开启IRX渲染加速120帧？",
                    fnCanShowConfirm = function(bTargetValue)
                        return bTargetValue == true -- 开启本选项时显示二次确认提示框
                    end,
                },
                tEnable = {
                    szMessage = "设备发热或处于分屏、浮窗等状态，暂时无法开启此功能",
                    fnEnable = function()
                        local bSupport = KG3DEngine.IsSupportGameFrc()
                        return bSupport
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "臻彩显示",
                szKey = UISettingKey.TrueColorDisplay,
                defaultValue = false,
                bInvokeFuncOnReset = true,
                fnFunc = function(bVal)
                    if Platform.IsIos() then
                        if bVal then
                            QualityMgr._EnableIosColorGrade()
                        else
                            QualityMgr._DisableIosColorGrade()
                        end
                    end
                end,
                fnVisible = function()
                    return Platform.IsIos()
                end,
            },
        },
        [QUALITY.RENDER_EFFICIENCY] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "阵营同模",
                szKey = UISettingKey.FactionModel,
                defaultValue = false,
                bInvokeFuncOnReset = true,
                fnFunc = function(bVal)
                    QualityMgr.UpdateCampUniformState()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                tEnable = {
                    szMessage = "当前场景正在开启活动，暂时不可关闭同模效果。",
                    bDisableValue = true, -- 无效时默认值
                    fnEnable = function()
                        return not QualityMgr.IsForceCampUniform()
                    end,
                },
                szHelpText = "开启后，其他玩家会显示同一模型，这能有助于提升游戏在战斗过程中的流畅度"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "毛发效果",
                szKey = UISettingKey.FurEffect,
                defaultValue = false,
                fnFunc = function(bVal)
                    QualityMgr.ModifyCurQuality("bEnableFur", bVal, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "强化显示但会降低运行效率，请谨慎使用"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "布料效果",
                szKey = UISettingKey.ClothSimulation,
                bInvokeFuncOnReset = true,
                defaultValue = false,
                fnFunc = function(bVal)
                    QualityMgr.ModifyCurQuality("bEnableApexClothing_new", bVal, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)

                    -- 调用表现命令，触发重新加载主角模型
                    if bVal then
                        rlcmd("enable apex clothing 1")
                    else
                        rlcmd("enable apex clothing 0")
                    end
                end,
                tEnable = {
                    szMessage = "当前设备不兼容布料效果",
                    fnEnable = function()
                        return QualityMgr.CanEnableClothSimulation(true)
                    end,
                },
                tConfirm = {
                    szMessage = "当前开启的布料效果性能负载较高，是否确定要开启？",
                    fnCanShowConfirm = function(bTarget)
                        return bTarget
                    end,
                },
                szHelpText = "目前布料效果仅在地图场景中生效，开启布料效果后将影响性能效果",
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "雨雪效果",
                szKey = UISettingKey.WeatherSimulation,
                bInvokeFuncOnReset = true,
                defaultValue = false,
                fnFunc = function(bVal)
                    if bVal then
                        rlcmd("Play dynamicWeather_RainSnow")
                    else
                        rlcmd("Stop dynamicWeather_RainSnow")
                    end
                    QualityMgr.ModifyCurQuality("bEnableWeather", bVal, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)

                    --手机端修改后会把预设还原，这里恢复一下
                    SelfieData.ResetFilterFromStorage(true)
                end,
                tConfirm = {
                    szMessage = "当前开启的雨雪效果性能负载较高，是否确定要开启？",
                    fnCanShowConfirm = function(bTarget)
                        return bTarget
                    end,
                },
                szHelpText = "目前雨雪效果仅在特定气候区域地图场景中呈现，开启雨雪效果后将影响性能效果",
            },
            {
                type = GameSettingCellType.BlankLine,
                szName = "分隔",
            },
            {
                type = GameSettingCellType.Button,
                szName = "隐藏其他玩家技能召唤物",
                szBtnLabelName = "前往",
                fnFunc = function()
                    NpcData.OpenEmployeeHidePanel(false)
                end
            },
            {
                type = GameSettingCellType.Button,
                szName = "隐藏自身技能召唤物",
                szBtnLabelName = "前往",
                fnFunc = function()
                    NpcData.OpenEmployeeHidePanel(true)
                end
            },

            {
                type = GameSettingCellType.Slider,
                szName = "同屏玩家数",
                szKey = UISettingKey.PlayersOnScreen,
                defaultValue = 30,
                nMaxVal = 30,
                bInvokeFuncOnReset = true,
                fnFunc = function()
                    SetScreenVisibleCount()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
            },
            {
                type = GameSettingCellType.Slider,
                szName = "同屏NPC数",
                szKey = UISettingKey.NPCsOnScreen,
                defaultValue = 30,
                nMaxVal = 30,
                bInvokeFuncOnReset = true,
                fnFunc = function()
                    SetScreenVisibleCount()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,

            },
            {
                type = GameSettingCellType.Slider,
                szName = "同屏特效数",
                szKey = UISettingKey.EffectsOnScreen,
                defaultValue = 30,
                nMinVal = 20,
                nMaxVal = 100,
                fnFunc = function(val)
                    QualityMgr.ModifyCurQuality("nClientSFXLimit", val, false)
                    QualityMgr.ModifyCurQuality("nClientUnderWaterSFXLimit", val, true)
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
            },
            {
                type = GameSettingCellType.Slider,
                szName = "其他玩家特效数",
                szKey = UISettingKey.OtherPlayerEffects,
                defaultValue = 10,
                nMinVal = 0,
                nMaxVal = 30,
                fnFunc = function(val)
                    QualityMgr.ModifyCurQuality("nClientOtherPlaySFXLimit", val, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                bInvokeFuncOnReset = true,
                szName = "自身特效质量",
                szKey = UISettingKey.SelfEffectQuality,
                defaultValue = GameSettingType.SelfEffectQuality.High,
                options = {
                    GameSettingType.SelfEffectQuality.Low,
                    GameSettingType.SelfEffectQuality.Medium,
                    GameSettingType.SelfEffectQuality.High,
                },
                fnFunc = function()
                    QualityMgr.UpdateVisualEffectQuality()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "质量越高，自身的特效品质越丰富"
            },
            {
                type = GameSettingCellType.SliderCell,
                bInvokeFuncOnReset = true,
                szName = "自身特效透明度",
                szKey = UISettingKey.SelfEffectTransparency,
                defaultValue = 0.8,
                nMaxVal = 1,
                nMinVal = 0.1,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%.2f"):format(value)
                end,
                fnFunc = function()
                    UpdateSfxIntensity()
                end,
            },
            {
                type = GameSettingCellType.SliderCell,
                bInvokeFuncOnReset = true,
                szName = "自身特效明暗度",
                szKey = UISettingKey.SelfEffectBrightness,
                defaultValue = 0.8,
                nMaxVal = 1,
                nMinVal = 0.1,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%.2f"):format(value)
                end,
                fnFunc = function()
                    UpdateSfxIntensity()
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                bInvokeFuncOnReset = true,
                szName = "其他玩家特效质量",
                szKey = UISettingKey.OtherEffectQuality,
                defaultValue = GameSettingType.OtherEffectQuality.High,
                options = {
                    GameSettingType.OtherEffectQuality.Low,
                    GameSettingType.OtherEffectQuality.Medium,
                    GameSettingType.OtherEffectQuality.High,
                    GameSettingType.OtherEffectQuality.ExtremeHigh,
                },
                fnFunc = function()
                    QualityMgr.UpdateVisualEffectQuality()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "质量越高，其他玩家的特效品质越丰富"
            },
            {
                type = GameSettingCellType.SliderCell,
                bInvokeFuncOnReset = true,
                szName = "其他特效透明度",
                szKey = UISettingKey.OtherEffectTransparency,
                defaultValue = 0.8,
                nMaxVal = 1,
                nMinVal = 0.1,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%.2f"):format(value)
                end,
                fnFunc = function()
                    UpdateSfxIntensity()
                end,
            }, {
                type = GameSettingCellType.SliderCell,
                bInvokeFuncOnReset = true,
                szName = "其他特效明暗度",
                szKey = UISettingKey.OtherEffectBrightness,
                defaultValue = 0.8,
                nMaxVal = 1,
                nMinVal = 0.1,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%.2f"):format(value)
                end,
                fnFunc = function()
                    UpdateSfxIntensity()
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "渲染分辨率",
                szKey = UISettingKey.RenderResolution,
                defaultValue = GameSettingType.RenderResolution.High,
                options = {
                    GameSettingType.RenderResolution.Low,
                    GameSettingType.RenderResolution.Medium,
                    GameSettingType.RenderResolution.High,
                    GameSettingType.RenderResolution.ExtremeHigh,
                    GameSettingType.RenderResolution.BlueRay,
                },
                fnFunc = function(tInfo)
                    QualityMgr.UpdateQualitySettingByKey("nQualityLevel")
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "渲染分辨率高可以提高画质清晰度，但可能降低游戏流畅度\n开低后会降低画质，有利于优化流畅性，保证游戏性能",
                tConfirm = {
                    szMessage = "当前选择的渲染分辨率性能负载较高，可能会造成发热或卡顿，是否继续更换？",
                    fnCanShowConfirm = function(tTargetInfo)
                        local nLevel = RenderResolutionToLevel[tTargetInfo.szDec]
                        local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
                        if nLevel - nRecommendQualityType >= 2 then
                            return true
                        end
                        return false
                    end,
                }

            },
            {
                type = GameSettingCellType.DropBox,
                szName = "渲染精度",
                szKey = UISettingKey.RenderPrecision,
                defaultValue = GameSettingType.RenderPrecision.High,
                options = {
                    GameSettingType.RenderPrecision.Low,
                    GameSettingType.RenderPrecision.Medium,
                    GameSettingType.RenderPrecision.High,
                    GameSettingType.RenderPrecision.ExtremeHigh,
                    GameSettingType.RenderPrecision.BlueRay,
                },
                fnFunc = function(tInfo)
                    QualityMgr.UpdateQualitySettingByKey("nRenderPrecision")
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "渲染精度高能提升游戏画质，但可能降低游戏流畅度\n开低后会降低画质，有利于优化流畅性，保证游戏性能"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "阴影质量",
                szKey = UISettingKey.ShadowQuality,
                defaultValue = GameSettingType.ShadowQuality.High,
                options = {
                    GameSettingType.ShadowQuality.Low,
                    GameSettingType.ShadowQuality.Medium,
                    GameSettingType.ShadowQuality.High,
                    GameSettingType.ShadowQuality.ExtremeHigh,
                },
                fnFunc = function(tInfo)
                    QualityMgr.UpdateQualitySettingByKey("nShadowQuality")
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                fnVisible = function()
                    if Device.IsHuaWei() or Device.IsHonor() then
                        return false
                    end
                    return Platform.IsWindows() or Platform.IsMac() or Platform.IsAndroid()
                end,
                szHelpText = "控制游戏角色和环境的阴影渲染质量\n注意，选择较高的设置会对游戏运行的流畅度产生较大影响"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "环境遮蔽",
                szKey = UISettingKey.AmbientOcclusion,
                defaultValue = false,
                fnFunc = function(bOpen)
                    QualityMgr.ModifyCurQuality("bEnableSSAO", bOpen, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                fnVisible = function()
                    return Platform.IsWindows() or Platform.IsMac() or Platform.IsAndroid()
                end,
                szHelpText = "可以增强场景的视觉效果，使物体看起来更加立体和真实"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "泛光效果",
                szKey = UISettingKey.BloomEffect,
                defaultValue = false,
                fnFunc = function(bOpen)
                    QualityMgr.ModifyCurQuality("bEnableBloom", bOpen, false)
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                szHelpText = "使图像中的明亮区域产生一种发光的效果，增强画面的真实感和艺术感"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "抗锯齿",
                szKey = UISettingKey.AntiAliasing,
                defaultValue = GameSettingType.AntiAliasing.None,
                options = {
                    GameSettingType.AntiAliasing.None,
                    GameSettingType.AntiAliasing.TAA,
                    GameSettingType.AntiAliasing.FXAA,
                },
                fnFunc = function()
                    QualityMgr.UpdateAntiAliasing()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "超分",
                szKey = UISettingKey.SuperResolutionOption,
                defaultValue = GameSettingType.SuperResolution.None,
                options = {
                    GameSettingType.SuperResolution.None,
                    GameSettingType.SuperResolution.FSRMode,
                    GameSettingType.SuperResolution.FSRPerformanceMode,
                    GameSettingType.SuperResolution.QualityMode,
                    GameSettingType.SuperResolution.PerformanceMode,
                },
                fnFunc = function()
                    QualityMgr.UpdateSuperResolution()
                    Event.Dispatch(EventType.OnQualitySettingChange)
                end,
                tConfirm = {
                    szMessage = "开启超分可能会造成发热或卡顿，是否继续开启？",
                    fnCanShowConfirm = function(tTargetInfo)
                        local tValue = GameSettingData.GetNewValue(UISettingKey.SuperResolutionOption)
                        if tValue.szDec == GameSettingType.SuperResolution.None.szDec and
                                tTargetInfo.szDec ~= GameSettingType.SuperResolution.None.szDec then
                            return true -- 开启时显示提示
                        end
                        return false
                    end,
                },
                szHelpText = "开启后，在保证优化的前提下，利用算法将图像提升分辨率，尽可能恢复更多细节和清晰度"
            },
        },
    },
    Display = {
        [DISPLAY.TARGET_LINE_CONNECT] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "目标选择连线",
                szKey = UISettingKey.TargetSelectionLine,
                defaultValue = GameSettingType.TargetLink.Certain,
                options = {
                    GameSettingType.TargetLink.All,
                    GameSettingType.TargetLink.Certain,
                    GameSettingType.TargetLink.None,
                },
                fnFunc = function(tInfo)
                    JX_TargetLink.RefreshLine()
                end,
                szHelpText = "开启后，可以查看与目标之间的连线"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "目标的目标连线",
                szKey = UISettingKey.TargetOfTargetLine,
                defaultValue = false,
                fnFunc = function(bOpen)
                    JX_TargetLink.RefreshLine()
                end,
                szHelpText = "开启后，可以查看当前目标的目标之间的连线"
            },
        },
        [DISPLAY.TARGET_ENHANCE] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示NPC方位",
                szKey = UISettingKey.ShowNPCDirection,
                defaultValue = false,
                fnFunc = function()
                    SetTargetBraceParam()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示玩家方位",
                szKey = UISettingKey.ShowPlayerDirection,
                defaultValue = true,
                fnFunc = function()
                    SetTargetBraceParam()
                end
            },
        },
        [DISPLAY.FACING_ENHANCE] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "敌对目标",
                szKey = UISettingKey.HostileTarget,
                defaultValue = false,
                fnFunc = function(bOpen)
                    LOG.INFO("敌对目标 %s", bOpen and "开启" or "关闭")
                    EnableTargetFace()
                end,
                szHelpText = "开启后，选中敌对目标可以查看目标的面向"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "非敌对目标",
                szKey = UISettingKey.NonHostileTarget,
                defaultValue = false,
                fnFunc = function(bOpen)
                    LOG.INFO("非敌对目标 %s", bOpen and "开启" or "关闭")
                    EnableTargetFace()
                end,
                szHelpText = "开启后，选中非敌对目标可以查看目标的面向"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "非目标首领",
                szKey = UISettingKey.NonTargetBoss,
                defaultValue = false,
                fnFunc = function(bOpen)
                    LOG.INFO("非目标首领 %s", bOpen and "开启" or "关闭")
                    EnableTargetFace()
                end,
                szHelpText = "开启后，选中非目标首领可以查看目标的面向"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "特效角度",
                szKey = UISettingKey.EffectAngle,
                defaultValue = GameSettingType.FacingSFXAngle.Second,
                options = {
                    GameSettingType.FacingSFXAngle.First,
                    GameSettingType.FacingSFXAngle.Second,
                    GameSettingType.FacingSFXAngle.Third,
                    GameSettingType.FacingSFXAngle.Fourth,
                    GameSettingType.FacingSFXAngle.Fifth,
                },
            },
            {
                type = GameSettingCellType.Slider,
                szName = "特效大小",
                szKey = UISettingKey.EffectSize,
                defaultValue = 0.5,
                nMaxVal = 1.5,
                nMinVal = 0.5,
                bShouldCeil = false,
                fnFunc = function(nVal)
                    SetTargetFaceParam()
                end
            },
            {
                type = GameSettingCellType.Slider,
                szName = "特效透明度",
                szKey = UISettingKey.EffectTransparency,
                defaultValue = 255,
                nMaxVal = 255,
                nMinVal = 0,
                fnFunc = function(nVal)
                    SetTargetFaceParam()
                end
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "特效样式",
                szKey = UISettingKey.EffectStyle,
                defaultValue = GameSettingType.FacingSFXType.Solid,
                options = {
                    GameSettingType.FacingSFXType.Solid,
                    GameSettingType.FacingSFXType.Hollow,
                }
            },
        },
        [DISPLAY.TOP_HEAD] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自己名字",
                szKey = UISettingKey.ShowSelfName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.NAME, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自己血条",
                szKey = UISettingKey.ShowSelfHealthBar,
                defaultValue = false,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.LIFE, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示其他玩家名字",
                szKey = UISettingKey.ShowOtherPlayerName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.NAME, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示其他玩家血条",
                szKey = UISettingKey.ShowOtherPlayerHealthBar,
                defaultValue = false,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.LIFE, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示NPC名字",
                szKey = UISettingKey.ShowNPCName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.NPC, HEAD_FLAG_TYPE.NAME, bOpen)
                    Global_UpdateHeadTopPosition()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示NPC血条",
                szKey = UISettingKey.ShowNPCHealthBar,
                defaultValue = false,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.NPC, HEAD_FLAG_TYPE.LIFE, bOpen)
                    Global_UpdateHeadTopPosition()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示召唤物名字",
                szKey = UISettingKey.ShowSummonName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    ShowEmployeeCaption("name", bOpen)
                end,
                tEnable = {
                    fnEnable = function()
                        return GameSettingData.GetNewValue(UISettingKey.ShowNPCName)
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示召唤物血条",
                szKey = UISettingKey.ShowSummonHealthBar,
                defaultValue = true,
                fnFunc = function(bOpen)
                    ShowEmployeeCaption("life", bOpen)
                end,
                tEnable = {
                    fnEnable = function()
                        return GameSettingData.GetNewValue(UISettingKey.ShowNPCHealthBar)
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示角色距离",
                szKey = UISettingKey.ShowCharacterDistance,
                defaultValue = false,
                fnFunc = function(bOpen)
                    ShowCharacterDistance(bOpen)
                end,
                szHelpText = "勾选后会在战场、竞技场、秘境场景内显示与玩家角色、非玩家角色的距离\n需勾选“显示其他玩家名字”或“显示NPC名字”方能生效，全勾选则全部生效"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自己称号",
                szKey = UISettingKey.ShowSelfTitle,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.TITLE, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自己的帮会名称",
                szKey = UISettingKey.ShowSelfGuildName,
                defaultValue = false,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.GUILD, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示其他玩家称号",
                szKey = UISettingKey.ShowOtherPlayerTitle,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.TITLE, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示他人的帮会名称",
                szKey = UISettingKey.ShowOtherGuildName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.GUILD, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示NPC称号",
                szKey = UISettingKey.ShowNPCTitle,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.NPC, HEAD_FLAG_TYPE.TITLE, bOpen)
                    Global_UpdateHeadTopPosition()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自己头顶的悬赏标识",
                szKey = UISettingKey.ShowOwnWwantedSign,
                defaultValue = true,
                fnFunc = function(bOpen)
                    UpdatePlayerTitleWantedEffect()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示他人头顶的悬赏标识",
                szKey = UISettingKey.ShowOtherPlayerWantedSign,
                defaultValue = true,
                fnFunc = function(bOpen)
                    UpdatePlayerTitleWantedEffect()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "智能血条显示",
                szKey = UISettingKey.SmartHealthBarDisplay,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetGlobalTopIntelligenceLife(bOpen)
                end,
                szHelpText = "战斗时显示敌我双方血条，退出战斗时隐藏"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示他人战斗轻功标识",
                szKey = UISettingKey.ShowOtherCombatSprintIdentifier,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetPlayerBirdFloatTitle(bOpen)
                end,
                szHelpText = "开启后，可以显示其他玩家在战斗中使用轻功的标识"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示采集物名字",
                szKey = UISettingKey.ShowGatherableObjectName,
                defaultValue = true,
                fnFunc = function(bOpen)
                    Event.Dispatch(EventType.OnGameSettingShowDoodadName, bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示头顶重要气劲",
                szKey = UISettingKey.ShowDungeonHeadBuff,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if not bOpen then
                        Event.Dispatch(EventType.OnHideCharacterHeadBuff)
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "头顶增减益效果",
                szKey = UISettingKey.ShowArenaHeadBuff,
                defaultValue = true,
                fnFunc = function(bOpen)
                    Event.Dispatch(EventType.OnChangeTopBuffSetting)
                end,
                fnExtra = function()
                    UIMgr.Close(VIEW_ID.PanelGameSettings)
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelSystemMenu, function()
                        UIMgr.Open(VIEW_ID.PanelSceneFontSetting, "TopBuffSetting")
                    end)
                end
                -- szHelpText = " 开启后名剑大会玩法中，队友或敌人受到各类控制、禁疗气劲时，头顶将额外显示受到的气劲效果；同时队友名称颜色会更为突出"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "置顶自己的名字和血条",
                szKey = UISettingKey.TopPriority,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetSelfTopPriority(bOpen)
                end,
            },
        },
        [DISPLAY.OTHER_VISUAL] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示他人的家园",
                szKey = UISettingKey.ShowOthersHome,
                defaultValue = true,
                fnFunc = function(bOpen)
                    GetHomelandMgr().SetBlockOtherLand(not bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示玩家对话泡泡",
                szKey = UISettingKey.ShowPlayerDialogueBubble,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --ShowPlayerBalloon(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示NPC对话泡泡",
                szKey = UISettingKey.ShowNPCDialogueBubble,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --ShowPlayerBalloon(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示/隐藏NPC",
                szKey = UISettingKey.ShowHideNPC,
                defaultValue = true,
                fnFunc = function(bOpen)
                    RLEnv.GetLowerVisibleCtrl():ShowNpc(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示气力值",
                szKey = UISettingKey.ShowSprintEnergyValue,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "附近敌对玩家提示",
                szKey = UISettingKey.NearbyHostilePlayerAlert,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if JX_TargetList then
                        JX_TargetList.bEnemyWarning = bOpen
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示教学",
                szKey = UISettingKey.ShowTutorial,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if not bOpen then
                        TeachEvent.CloseAllTeach()
                    end
                    TeachEvent.bEnabled = bOpen
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "滚动公告",
                szKey = UISettingKey.ScrollingAnnouncement,
                defaultValue = true,
                fnFunc = function(bOpen)
                    Event.Dispatch(EventType.OnGameSettingDisplaySystemAnnouncement, bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自身脚印",
                szKey = UISettingKey.ShowSelfFootprints,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if bOpen then
                        rlcmd("show footprint 1 0 0")
                    else
                        rlcmd("show footprint 0 0 0")
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示目标锁定按钮",
                szKey = UISettingKey.ShowTargetLockButton,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if not bOpen then
                        TargetMgr.Attention(false) -- 关闭时取消注视状态
                    end
                    Event.Dispatch(EventType.OnSearchTargetChanged)
                end,
            },
        },
        [DISPLAY.SELF_LIFE_VISUAL] = {
            {
                type = GameSettingCellType.DropBox,
                szKey = UISettingKey.SelfHealthBarDisplay,
                defaultValue = GameSettingType.PlayerLifeVisual.Simple,
                szName = "自身血条显示",
                options = {
                    GameSettingType.PlayerLifeVisual.Percent,
                    GameSettingType.PlayerLifeVisual.Simple,
                },
                fnFunc = function()
                    Event.Dispatch(EventType.OnPlayerSettingChange)
                end,
            },
        },
        [DISPLAY.TARGET_LIFE_VISUAL] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "目标血条显示",
                szKey = UISettingKey.TargetHealthBarDisplay,
                defaultValue = GameSettingType.TargetLifeVisual.Simple,
                options = {
                    GameSettingType.TargetLifeVisual.Percent,
                    GameSettingType.TargetLifeVisual.Simple,
                },
                fnFunc = function()
                    Event.Dispatch(EventType.OnTargetSettingChange)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "目标首领内力值百分比显示",
                szKey = UISettingKey.TargetBossManaBarDisplay,
                defaultValue = true,
                fnFunc = function()
                    Event.Dispatch(EventType.OnTargetBossManaBarChange)
                end,
            },
        },
        [DISPLAY.DOUQI] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示自身聚劲",
                szKey = UISettingKey.ShowDouqi,
                defaultValue = true,
                fnFunc = function()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示目标聚劲",
                szKey = UISettingKey.ShowDouqiTarget,
                defaultValue = true,
                fnFunc = function()
                end,
            },
        },
    },
    BattleInfo = {
        [BATTLE_INFO.MAIN] = {
            {
                type = GameSettingCellType.FontCell,
                szName = "字体样式",
                szKey = UISettingKey.BattleFontStyle,
                defaultValue = GameSettingType.FontStyle.FZJZ,
                options = {
                    GameSettingType.FontStyle.Default,
                    GameSettingType.FontStyle.FZHT,
                    GameSettingType.FontStyle.XMSANS,
                    GameSettingType.FontStyle.FZJZ,
                },
                fnFunc = function(tInfo)
                    FontMgr.ChangeFontWithGameSettingDesc(FontID.BattleInfo, tInfo.szDec)
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                szHelpText = "切换字体样式后需要重启游戏才能生效"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "字体大小",
                szKey = UISettingKey.BattleFontSize,
                defaultValue = GameSettingType.BattleFontSize.Small,
                options = {
                    GameSettingType.BattleFontSize.ExtremeSmall,
                    GameSettingType.BattleFontSize.Small,
                    GameSettingType.BattleFontSize.Middle,
                    GameSettingType.BattleFontSize.Large,
                },
                fnFunc = function(tInfo)
                    Event.Dispatch(EventType.OnBattleInfoSettingChange, tInfo)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "子弹击中目标时出现浮动信息",
                szKey = UISettingKey.BattleFloatingInfo,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.Button,
                szName = "字体颜色设置",
                szBtnLabelName = "修改",
                fnFunc = function()
                    UIMgr.Open(VIEW_ID.PanelFightLabelColorSettings)
                end
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "战斗浮动信息数字单位",
                szKey = UISettingKey.BattleInfoNumberMeasureUnit,
                defaultValue = GameSettingType.BattleInfoNumberMeasureUnit.NoUnit,
                options = {
                    GameSettingType.BattleInfoNumberMeasureUnit.NoUnit,
                    GameSettingType.BattleInfoNumberMeasureUnit.TenThousand,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "屏蔽侠客的浮动信息",
                szKey = UISettingKey.DisablePartnerBattleInfo,
                defaultValue = false,
            },
        },
        [BATTLE_INFO.ACTIVE_ATTACK] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "伤害值",
                szKey = UISettingKey.ActiveAttackDamageValue,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "治疗值",
                szKey = UISettingKey.ActiveAttackHealingValue,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "拆招",
                szKey = UISettingKey.ActiveAttackDisarm,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "闪躲",
                szKey = UISettingKey.ActiveAttackDodge,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "偏离",
                szKey = UISettingKey.ActiveAttackMiss,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "识破",
                szKey = UISettingKey.ActiveAttackDetect,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "化解",
                szKey = UISettingKey.ActiveAttackResolve,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "免疫",
                szKey = UISettingKey.ActiveAttackImmune,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "抵消",
                szKey = UISettingKey.ActiveAttackCounteract,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "技能名字",
                szKey = UISettingKey.ActiveAttackSkillName,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
        },
        [BATTLE_INFO.DAMAGED] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "伤害值",
                szKey = UISettingKey.DamagedDamageValue,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "治疗值",
                szKey = UISettingKey.DamagedHealingValue,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "拆招",
                szKey = UISettingKey.DamagedDisarm,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "闪躲",
                szKey = UISettingKey.DamagedDodge,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "偏离",
                szKey = UISettingKey.DamagedMiss,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "识破",
                szKey = UISettingKey.DamagedDetect,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "化解",
                szKey = UISettingKey.DamagedResolve,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "免疫",
                szKey = UISettingKey.DamagedImmune,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "抵消",
                szKey = UISettingKey.DamagedCounteract,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "技能名字",
                szKey = UISettingKey.DamagedSkillName,
                defaultValue = true,
                fnFunc = fnBattleInfoNotification
            },
        },
    },
    Focus = {
        [FOCUS.MAIN] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示焦点列表",
                szKey = UISettingKey.ShowFocusList,
                defaultValue = false,
                fnFunc = function()
                    Event.Dispatch(EventType.SwitchFocusVisibility, true)
                end,
            },
        },
        [FOCUS.TARGET] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "优先显示近处目标",
                szKey = UISettingKey.PrioritizeNearbyTargets,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示血量进度条",
                szKey = UISettingKey.ShowHealthProgressBar,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.Slider,
                szName = "优先显示近处目标距离",
                szKey = UISettingKey.NearbyTargetDistance,
                defaultValue = 22,
                nMinVal = 0,
                nMaxVal = 100,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "隐藏已加焦点的目标",
                szKey = UISettingKey.HideAlreadyFocusedTargets,
                defaultValue = false,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "后置重伤玩家",
                szKey = UISettingKey.DeprioritizeInjuredPlayers,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            --{
            --    type = GameSettingCellType.DropBoxSimple,
            --    szName = "屏蔽指定NPC显示",
            --    fnFunc = function()
            --        JX_TargetList.UpdateSetting()
            --    end,
            --},
        },
        [FOCUS.AUTO] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动焦点竞技场内对方玩家",
                szKey = UISettingKey.AutoFocusArenaOpponents,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动焦点阵营BOSS",
                szKey = UISettingKey.AutoFocusFactionBoss,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动焦点副本BOSS",
                szKey = UISettingKey.AutoFocusDungeonBoss,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动焦点牛车/世界首领等",
                szKey = UISettingKey.AutoFocusWorldBoss,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
        },
        [FOCUS.FOCUS_SETTING] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "焦点过远则变暗",
                szKey = UISettingKey.DimDistantFocus,
                defaultValue = false,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示顶部锁定焦点",
                szKey = UISettingKey.ShowTopLockedFocus,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.Slider,
                szName = "焦点过远则变暗距离",
                szKey = UISettingKey.DimDistantFocusDistance,
                defaultValue = 27,
                nMinVal = 0,
                nMaxVal = 100,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "接收队友同步的焦点",
                szKey = UISettingKey.ReceiveTeammateFocus,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "快捷喊话焦点发布集火",
                szKey = UISettingKey.QuickFocusFireAnnouncement,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
        },
        [FOCUS.WARNING] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "出现敌对侠士时预警",
                szKey = UISettingKey.HostilePlayerWarning,
                defaultValue = true,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "小地图显示敌对侠士标记",
                szKey = UISettingKey.ShowHostilePlayerOnMinimap,
                defaultValue = false,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "出现敌对侠士时设置为目标",
                szKey = UISettingKey.SetHostilePlayerAsTarget,
                defaultValue = false,
                tEnable = {
                    fnEnable = function()
                        return GameSettingData.GetNewValue(UISettingKey.HostilePlayerWarning)
                    end,
                },
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "目标重新进入视野时自动选择",
                szKey = UISettingKey.AutoSelectTargetReentered,
                defaultValue = false,
                fnFunc = function()
                    JX_TargetList.UpdateSetting()
                end,
            },
        }
    },
    Sound = {
        [SOUND_TITLE.MAIN] = {
            {
                type = GameSettingCellType.SoundSlider,
                szName = "音量",
                szKey = UISettingKey.MasterVolume,
                defaultValue = {
                    Slider = 1.0,
                    TogSelect = false
                },
                nSoundType = SOUND.MAIN,
            },
        },
        [SOUND_TITLE.MUSIC] = {
            {
                type = GameSettingCellType.SoundSlider,
                szName = "背景音乐",
                szKey = UISettingKey.BackgroundMusicVolume,
                defaultValue = {
                    Slider = 0.5,
                    TogSelect = false,
                },
                nSoundType = SOUND.BG_MUSIC,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "背景音乐循环播放",
                szKey = UISettingKey.LoopBackgroundMusic,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetBgMusicLoop(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "失去焦点时播放背景音乐",
                szKey = UISettingKey.PlayBackgroundMusicWhenLostFocus,
                defaultValue = true,
                fnFunc = function(bOpen)
                    EnableSoundWhenLoseFocus(bOpen)
                end,
            },
            {
                type = GameSettingCellType.SoundSlider,
                szName = "角色音效",
                szKey = UISettingKey.CharacterSoundVolume,
                defaultValue = {
                    Slider = 0.5,
                    TogSelect = false
                },
                nSoundType = SOUND.CHARACTER_SOUND,
            },
            {
                type = GameSettingCellType.SliderCell,
                szName = "个人音效",
                szKey = UISettingKey.CurrentPlayerVolume,
                defaultValue = 1,
                nActorSoundType = ACTOR_SOUND.PLAYER,
                nMaxVal = 1,
                nMinVal = 0,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%d"):format(value * 100)
                end,

                fnFunc = function(nVal)
                    GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.PLAYER, nVal)
                end,
            },
            {
                type = GameSettingCellType.SliderCell,
                szName = "他人音效",
                szKey = UISettingKey.OtherPlayerVolume,
                defaultValue = 0.6,
                nActorSoundType = ACTOR_SOUND.OTHER_PLAYER,
                nMaxVal = 1,
                nMinVal = 0,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%d"):format(value * 100)
                end,
                fnFunc = function(nVal)
                    GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.OTHER_PLAYER, nVal)
                end,
            },
            {
                type = GameSettingCellType.SliderCell,
                szName = "NPC音效",
                szKey = UISettingKey.NPCVolume,
                defaultValue = 0.8,
                nActorSoundType = ACTOR_SOUND.NPC,
                nMaxVal = 1,
                nMinVal = 0,
                bShouldCeil = false,
                fnFormat = function(value)
                    return ("%d"):format(value * 100)
                end,
                fnFunc = function(nVal)
                    GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.NPC, nVal)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "披风音效",
                szKey = UISettingKey.EnableCloakSound,
                defaultValue = true,
                szHelpText = "开启时，自己和他人的披风、包身等外观的常态待机特效音量与个人音效相同；\n关闭时，自己和他人的披风、包身等外观的常态待机特效音量为0",
                fnFunc = function(bOpen)
                    GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.CLOAK, nil, bOpen)
                end,
            },
            {
                type = GameSettingCellType.SoundSlider,
                szName = "场景音效",
                szKey = UISettingKey.SceneSoundVolume,
                defaultValue = {
                    Slider = 0.85,
                    TogSelect = false
                },
                nSoundType = SOUND.SCENE_SOUND,
            },
            {
                type = GameSettingCellType.SoundSlider,
                szName = "界面音效",
                szKey = UISettingKey.UISoundVolume,
                defaultValue = {
                    Slider = 0.35,
                    TogSelect = false
                },
                nSoundType = SOUND.UI_SOUND,
            },
            {
                type = GameSettingCellType.SoundSlider,
                szName = "系统提示",
                szKey = UISettingKey.SystemTipVolume,
                defaultValue = {
                    Slider = 0.68,
                    TogSelect = false,
                },
                nSoundType = SOUND.SYSTEM_TIP,
            },
        },
        [SOUND_TITLE.CHARACTER_SPEAK] = {
            {
                type = GameSettingCellType.SoundSlider,
                szName = "角色对话",
                szKey = UISettingKey.CharacterSpeakVolume,
                defaultValue = {
                    Slider = 1,
                    TogSelect = false
                },
                nSoundType = SOUND.CHARACTER_SPEAK,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "击伤配音",
                szKey = UISettingKey.DamageVocal,
                defaultValue = nil,
                options = {
                    GameSettingType.CharacterHitVoice.Male,
                    GameSettingType.CharacterHitVoice.Female,
                    GameSettingType.CharacterHitVoice.Boy,
                    GameSettingType.CharacterHitVoice.Girl,
                }
            },
            {
                type = GameSettingCellType.MultiDropBox,
                szName = "击伤台词·连伤一人",
                szKey = UISettingKey.HitDialogue_1,
                defaultValue = {},
                options = {
                    --GameSettingType.CharacterHitWord[1][1]
                    --GameSettingType.CharacterHitWord[1][2]
                }
            },
            {
                type = GameSettingCellType.MultiDropBox,
                szName = "击伤台词·连伤二人",
                szKey = UISettingKey.HitDialogue_2,
                defaultValue = {},
                options = {
                    --GameSettingType.CharacterHitWord[2][1]
                }
            },
            {
                type = GameSettingCellType.MultiDropBox,
                szName = "击伤台词·连伤三人",
                szKey = UISettingKey.HitDialogue_3,
                defaultValue = {},
                options = {
                    --GameSettingType.CharacterHitWord[2][1]
                }
            },
            {
                type = GameSettingCellType.MultiDropBox,
                szName = "击伤台词·连伤四人",
                szKey = UISettingKey.HitDialogue_4,
                defaultValue = {},
                options = {
                    --GameSettingType.CharacterHitWord[2][1]
                }
            },
            {
                type = GameSettingCellType.MultiDropBox,
                szName = "击伤台词·连伤五人",
                szKey = UISettingKey.HitDialogue_5,
                defaultValue = {},
                options = {
                    --GameSettingType.CharacterHitWord[2][1]
                }
            },
        },
        [SOUND_TITLE.REAL_TIME] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "语音输入",
                bDynamic = true, --动态显示选项
                fnDynamicOption = function()
                    return GVoiceMgr.GetMicListForSetting()
                end,
                fnDynamicName = function()
                    return GVoiceMgr.GetCurMicName()
                end,
                fnDynamicSelected = function(tInfo)
                    return GVoiceMgr.IsCurMic(tInfo)
                end,
                fnVisible = function()
                    return Platform.IsWindows() -- windows PC专用
                end,
                fnFunc = function(info)
                    if info then
                        GVoiceMgr.SelectMic(info.szDeviceID)
                    end
                end
            },
            {
                type = Platform.IsWindows() and GameSettingCellType.SoundSlider_Short or GameSettingCellType.SoundSlider,
                szName = "麦克风",
                szKey = UISettingKey.MicVolume,
                defaultValue = {
                    Slider = 0.75,
                    TogSelect = false,
                    VoiceType = 0,
                },
                nSoundType = SOUND.MIC_VOLUME,
            },
        },
        [SOUND_TITLE.MODIFY] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "语音输出",
                bDynamic = true, --动态显示选项
                fnDynamicOption = function()
                    return GVoiceMgr.GetSpeakerListForSetting()
                end,
                fnDynamicName = function()
                    return GVoiceMgr.GetCurSpeakerName()
                end,
                fnDynamicSelected = function(tInfo)
                    return GVoiceMgr.IsCurSpeaker(tInfo)
                end,
                fnVisible = function()
                    return Platform.IsWindows() -- windows PC专用
                end,
                fnFunc = function(info)
                    if info then
                        GVoiceMgr.SelectSpeaker(info.szDeviceID)
                    end
                end
            },
            {
                type = Platform.IsWindows() and GameSettingCellType.SoundSlider_Short or GameSettingCellType.SoundSlider,
                szName = "扬声器",
                szKey = UISettingKey.SpeakerVolume,
                defaultValue = {
                    Slider = 0.75,
                    TogSelect = false
                },
                nSoundType = SOUND.SPEAKER_VOLUME,
            },
        },
    },
    Operate = {
        [OPERATE.MAIN] = {
            {
                type = GameSettingCellType.DropBox,
                szKey = UISettingKey.MainViewLayout,
                defaultValue = GameSettingType.MainOperateMode.Classic,
                options = {
                },
                szName = "主界面布局",
                fnFunc = function()
                end,
                fnVisible = function()
                    return false -- 不显示，仅用于主界面布局的特殊存储
                end
            },

            {
                type = GameSettingCellType.DropBox,
                szName = "玩家显示",
                szKey = UISettingKey.PlayerDisplay,
                defaultValue = GameSettingType.PlayDisplay.All,
                options = {
                    GameSettingType.PlayDisplay.All,
                    GameSettingType.PlayDisplay.OnlyPartyPlay,
                    GameSettingType.PlayDisplay.HideAll
                },
                fnFunc = function(tInfo)
                    local tDict = {
                        [GameSettingType.PlayDisplay.All.szDec] = PLAYER_SHOW_MODE.kAll,
                        [GameSettingType.PlayDisplay.OnlyPartyPlay.szDec] = PLAYER_SHOW_MODE.kParter,
                        [GameSettingType.PlayDisplay.HideAll.szDec] = PLAYER_SHOW_MODE.kNone,
                    }
                    local nType = tDict[tInfo.szDec]
                    RLEnv.GetLowerVisibleCtrl():ShowPlayer(nType)
                    Event.Dispatch(EventType.OnGameSettingPlayDisplayChanged)
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "关闭武学助手时，中断当前武学运功状态",
                szKey = UISettingKey.AutoStopChannelSkill,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "名剑大会中自动取消屏蔽角色模型",
                szKey = UISettingKey.AutoShowModelArena,
                defaultValue = true,
                fnFunc = function(bOpen)
                    CommonPVPData.SetAutoShowModelArena(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "阵营战场中自动取消屏蔽角色模型",
                szKey = UISettingKey.AutoShowModelBattlefield,
                defaultValue = false,
                fnFunc = function(bOpen)
                    CommonPVPData.SetAutoShowModelBattlefield(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "绝境战场中自动取消屏蔽角色模型",
                szKey = UISettingKey.AutoShowModelTreasureBattleField,
                defaultValue = false,
                fnFunc = function(bOpen)
                    CommonPVPData.SetAutoShowModelTreasureBattleField(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "切换走路",
                szKey = UISettingKey.ToggleWalk,
                defaultValue = GameSettingType.ToggleRunOrWalk.ToggleRun,
                options = {
                    GameSettingType.ToggleRunOrWalk.ToggleRun,
                    GameSettingType.ToggleRunOrWalk.ToggleWalk,
                },
                fnFunc = function(tInfo)
                    local bSettingRun = tInfo.szDec == GameSettingType.ToggleRunOrWalk.ToggleRun.szDec
                    if (bSettingRun and g_pClientPlayer.bWalk) or (not bSettingRun and not g_pClientPlayer.bWalk) then
                        ToggleRun()
                        Event.Dispatch("OnWalkModeChanged")
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "目标选择",
                szKey = UISettingKey.TargetSelection,
                defaultValue = GameSettingType.SearchTargetType.PlayerFirst,
                options = {
                    GameSettingType.SearchTargetType.PlayerFirst,
                    GameSettingType.SearchTargetType.OtherFirst,
                }
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "选敌优先级",
                szKey = UISettingKey.EnemySelectionPriority,
                defaultValue = GameSettingType.SearchTargetPriority.OnlyNearDis,
                fnEnable = function()
                    return not TargetMgr.IsSearchTargetLocked()
                end,
                options = {
                    GameSettingType.SearchTargetPriority.Weakness,
                    GameSettingType.SearchTargetPriority.OnlyNearDis,
                }
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "开启锁定后切换目标时也锁定",
                szKey = UISettingKey.LockOnSwitchTargetWhenLocked,
                defaultValue = false,
                fnFunc = function(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "降低宠物/影子选择",
                szKey = UISettingKey.LowerPetShadowSelection,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetPlayerPriority(bOpen)
                end,
                szHelpText = "开启后，目标选择优先选中敌对的玩家，而不会优先选中他/她的宠物或影子"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "目标选择策略(新版)",
                szKey = UISettingKey.TargetSelectionStrategy,
                defaultValue = true,
                fnFunc = function(bOpen)
                    if bOpen then
                        SearchTarget_SetOtherSetting("nVersion", 2, "Enmey")
                        SearchTarget_SetOtherSetting("nVersion", 2, "Ally")
                    else
                        SearchTarget_SetOtherSetting("nVersion", 1, "Enmey")
                        SearchTarget_SetOtherSetting("nVersion", 1, "Ally")
                    end
                end,
                szHelpText = "开启后会采用新版的目标选择策略\n新版策略以玩家朝向为中轴分3个不同大小，不同优先级的扇形搜索区域\n默认优先高优先级区域的目标，然后优先距离近的目标\n注:若你不习惯新版的策略，关闭就会启用默认选择策略"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动自我运功",
                szKey = UISettingKey.AutoSelfChanneling,
                defaultValue = true,
                fnFunc = function(bOpen)
                    SetSelfCastSkill(bOpen)
                end,
                szHelpText = "当你没有目标的时候，运功会直接对自己产生效果"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "摇杆显示",
                szKey = UISettingKey.JoystickDisplay,
                defaultValue = true,
                fnFunc = function()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                    Event.Dispatch(EventType.OnJoystickSettingChange)
                end,
                fnVisible = function()
                    return Channel.Is_WLColud() or Platform.IsMobile()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示摇杆", -- VKPC专用设置项
                szKey = UISettingKey.DisplayJoystick,
                defaultValue = false,
                fnFunc = function()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                    Event.Dispatch(EventType.OnJoystickSettingChange)
                end,
                fnVisible = function()
                    return not Channel.Is_WLColud() and not Platform.IsMobile()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "固定摇杆",
                szKey = UISettingKey.FixedJoystick,
                defaultValue = false,
                fnFunc = function()
                    Event.Dispatch(EventType.OnJoystickSettingChange)
                end,
                tEnable = {
                    fnEnable = function()
                        if Channel.Is_WLColud() or Platform.IsMobile() then
                            return GameSettingData.GetNewValue(UISettingKey.JoystickDisplay)
                        else
                            return GameSettingData.GetNewValue(UISettingKey.DisplayJoystick)
                        end
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动全部拾取",
                szKey = UISettingKey.AutoLootAll,
                defaultValue = false,
                fnFunc = function(bOpen)
                end,
                fnExtra = function()
                    UIMgr.Open(VIEW_ID.PanelAutoGetSettings, LootSetting)
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "背包整理确认",
                szKey = UISettingKey.InventorySortConfirmation,
                defaultValue = true,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "技能预输入",
                szKey = UISettingKey.SkillQueueing,
                defaultValue = true,
                szHelpText = "开启后，释放技能时可以提前输入下一次按键指令",
                fnFunc = function(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "登录自动开启同城好友",
                szKey = UISettingKey.LoginAutoPushByIP,
                defaultValue = g_pClientPlayer and g_pClientPlayer.bRegisterIPToFellowshipByLogin or false,
                fnFunc = function(bOpen)
                    FellowshipData.SetRegisterIPToFellowByLoginFlag(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "Windows操作模式",
                szKey = UISettingKey.MacScrollUseWindowsMode,
                defaultValue = false,
                szHelpText = "开启后，鼠标滚轮的缩放和Windows操作习惯保持一致",
                fnFunc = function(bOpen)
                    cc.utils:setMacScrollUseWindowsMode(bOpen)
                end,
                fnVisible = function()
                    return Platform.IsMac()
                end,
            }
        },
        [OPERATE.SPRINT] = {
            {
                type = GameSettingCellType.DropBox,
                szName = "轻功模式",
                szKey = UISettingKey.SprintMode,
                defaultValue = GameSettingType.SprintMode.Common,
                options = {
                    GameSettingType.SprintMode.Classic,
                    GameSettingType.SprintMode.Simple,
                    GameSettingType.SprintMode.Common,
                },
                szHelpText = "经典轻功：轻功2.0，适合熟悉端游轻功的玩家\n简化轻功：操作简单，适合刚接触的新玩家\n通用轻功：操作便利，容易上手，适合希望轻功操纵更为简洁的玩家。"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "特殊轻功",
                szKey = UISettingKey.SpecialSprint,
                defaultValue = GameSettingType.SpecialSprint.None,
                options = {
                    GameSettingType.SpecialSprint.None,
                    GameSettingType.SpecialSprint.ReFly,
                    GameSettingType.SpecialSprint.Dash,
                },
                szHelpText = "续飞：\n设置后，轻功操作时会出现一个额外的“续飞”按钮。\n当您在轻功落地前，只要在恰当时机点击“续飞”按钮，将会在空中重新进入纵跃段，从而避免直接降落到地面，实现更长时间的滞空。\n\n连冲：\n设置后，轻功操作时会出现一个额外的“连冲”按钮。\n当您在使用轻功时，点击“连冲”按钮能够让角色在空中保持向前冲刺的状态，无需手动连续进行各段轻功操作，实现不间断的空中冲刺。"
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "急降",
                szKey = UISettingKey.SprintDrop,
                defaultValue = GameSettingType.SprintDrop.Common,
                options = {
                    GameSettingType.SprintDrop.School,
                    GameSettingType.SprintDrop.Common,
                },
                szHelpText = "门派：经典急降操作，为部分门派轻功独有，特色鲜明，使用可快捷降落至地面。\n通用：通用急降操作，江湖侠客惯用的轻功套路，使用可快捷降落至地面。"
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "双击前进进入轻功",
                szKey = UISettingKey.DoubleTapToSprint,
                defaultValue = true,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "松开摇杆退出轻功",
                szKey = UISettingKey.ReleaseJoystickToExitSprint,
                defaultValue = Platform.IsWindows(),
                fnFunc = function(bOpen)
                    Event.Dispatch(EventType.OnSprintSettingChange)

                    --松开摇杆退出轻功关闭时，自动登顶关闭
                    if not GameSettingData.bShouldInitSetting then
                        if not bOpen then
                            GameSettingData.ApplyNewValue(UISettingKey.AutoClimb, false)
                            Event.Dispatch(EventType.OnGameSettingViewUpdate)
                        end
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "轻功镜头",
                szKey = UISettingKey.SprintCamera,
                defaultValue = true,
                fnFunc = function(bOpen)
                    --LOG.WARN("轻功镜头")
                    if not bOpen then
                        rlcmd("close sprint camera")
                    else
                        rlcmd("open sprint camera 1")
                    end
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动登顶",
                szKey = UISettingKey.AutoClimb,
                defaultValue = false,
                fnFunc = function(bOpen)
                    local player = GetClientPlayer()
                    if not player or player.dwForceID == 0 then
                        return
                    end

                    local nOpen = bOpen and 1 or 0
                    rlcmd("enable summit point " .. nOpen)
                    player.SetCanOnTowerFlag(nOpen)

                    if bOpen then
                        TipsHelper.ShowNormalTip("自动登顶将在重新上线或切换场景后生效")
                    end

                    --打开自动登顶时，松开摇杆退出轻功开启
                    if not GameSettingData.bShouldInitSetting then
                        if bOpen then
                            GameSettingData.ApplyNewValue(UISettingKey.ReleaseJoystickToExitSprint, true)
                            Event.Dispatch(EventType.OnGameSettingViewUpdate)
                        end
                    end
                end,
                szHelpText = "开启后，使用轻功时在登顶点附近松开按键将会自动登顶",
                tEnable = {
                    szMessage = "通用轻功暂不支持该功能，可切回简化/经典轻功进行设置",
                    fnEnable = function()
                        local bOpen = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec ~= GameSettingType.SprintMode.Common.szDec
                        return bOpen
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "爬墙",
                szKey = UISettingKey.WallClimb,
                defaultValue = false,
                fnFunc = function(bOpen)
                    EnableIgnoreGravity(bOpen)
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "跨地",
                szKey = UISettingKey.CrossTerrain,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
                tEnable = {
                    szMessage = "通用轻功暂不支持该功能，可切回简化/经典轻功进行设置",
                    fnEnable = function()
                        local bOpen = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec ~= GameSettingType.SprintMode.Common.szDec
                        return bOpen
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "滑行",
                szKey = UISettingKey.Gliding,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
                szHelpText = "开启后，使用轻功时可进入滑行轻功状态",
                tEnable = {
                    szMessage = "通用轻功暂不支持该功能，可切回简化/经典轻功进行设置",
                    fnEnable = function()
                        local bOpen = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec ~= GameSettingType.SprintMode.Common.szDec
                        return bOpen
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "轻功披风特效",
                szKey = UISettingKey.SprintCloakEffect,
                defaultValue = true,
                fnFunc = function(bOpen)
                    local player = GetClientPlayer()
                    if not player then
                        return
                    end
                    player.HideBackCloakSprintSFX(not bOpen)
                end,
            },
        },
    },
    Interface = {
        [INTERFACE.LAYOUT] = {
            {
                type = GameSettingCellType.Button,
                szName = "主界面布局",
                szBtnLabelName = "修改",
                fnFunc = function()
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelGameSettings, function()
                        UIMgr.Close(VIEW_ID.PanelSystemMenu)
                        UIMgr.Open(VIEW_ID.PanelHintSelectMode)
                    end)
                    --Event.Dispatch(EventType.PlayAnimMainCityShow)
                end
            },
            {
                type = GameSettingCellType.Button,
                szName = "主界面自定义",
                szBtnLabelName = "前往",
                fnFunc = function()
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelGameSettings, function()
                        UIMgr.Close(VIEW_ID.PanelSystemMenu)
                        local script = UIMgr.Open(VIEW_ID.PanelHintSelectMode)
                        script:EnterCustomMode()
                    end)
                    --Event.Dispatch(EventType.PlayAnimMainCityShow)
                end
            },
        },
        [INTERFACE.FONT] = {
            {
                type = GameSettingCellType.FontCell,
                szName = "字体样式",
                szKey = UISettingKey.InterfaceFontStyle,
                defaultValue = GameSettingType.FontStyle.XMSANS,
                options = {
                    GameSettingType.FontStyle.Default,
                    GameSettingType.FontStyle.FZHT,
                    GameSettingType.FontStyle.XMSANS,
                },
                fnFunc = function(tInfo)
                    FontMgr.ChangeFontWithGameSettingDesc(FontID.Default, tInfo.szDec)
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                szHelpText = "切换字体样式后需要重启游戏才能生效"
            },
        },
        [INTERFACE.HEAD_TOP] = {
            {
                type = GameSettingCellType.Button,
                szName = "头顶文字血条效果设置",
                szBtnLabelName = "修改",
                fnFunc = function()
                    UIMgr.Close(VIEW_ID.PanelGameSettings)
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelSystemMenu, function()
                        UIMgr.Open(VIEW_ID.PanelSceneFontSetting, "HeadTopBarSetting")
                    end)
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "关怀模式",
                szKey = UISettingKey.ColorBlindMode,
                defaultValue = false,
                szHelpText = "开启后，头顶文字及血条将调整为更高对比度和特定配色方案，以适应部分玩家的阅读习惯",
                fnFunc = function(bOpen)
                    if bOpen then
                        rlcmd("enable care mode 1")
                    else
                        rlcmd("enable care mode 0")
                    end
                end
            }
        },
        [INTERFACE.DISPLAY_SWITCH] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "战斗数据",
                szKey = UISettingKey.ShowFightData,
                defaultValue = false,
                fnFunc = function()
                    if not GameSettingData.bShouldInitSetting then
                        Event.Dispatch(EventType.SwitchStatistVisibility)
                    end
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "谁在看我",
                szKey = UISettingKey.ShowWhoSeeMe,
                defaultValue = false,
                fnFunc = function()
                    if not GameSettingData.bShouldInitSetting then
                        Event.Dispatch(EventType.SwitchWhoSeeMeVisibility)
                    end
                end,
            }
        }
    },
    GamePad = {
        [GAMEPAD_CATEGORY.OTHER] = {
            {
                type = GameSettingCellType.Slider,
                szName = "光标灵敏度",
                szKey = UISettingKey.GamePadCursorSensitivity,
                defaultValue = 20,
                nMinVal = 0,
                nMaxVal = 40,
                fnFunc = function(nVal)
                    GamepadData.SetCursorSensitivity(nVal)
                end
            },
            {
                type = GameSettingCellType.Slider,
                szName = "镜头旋转灵敏度（左右）",
                szKey = UISettingKey.GamePadRotationSensitivity_Horizontal,
                defaultValue = 5,
                nMinVal = 0,
                nMaxVal = 20,
                fnFunc = function(nVal)
                    GamepadData.SetCameraSensitivityX(nVal)
                end
            },
            {
                type = GameSettingCellType.Slider,
                szName = "镜头旋转灵敏度（上下）",
                szKey = UISettingKey.GamePadRotationSensitivity_Vertical,
                defaultValue = 4,
                nMinVal = 0,
                nMaxVal = 20,
                fnFunc = function(nVal)
                    GamepadData.SetCameraSensitivityY(nVal)
                end
            },
            {
                type = GameSettingCellType.Slider,
                szName = "右摇杆界面滚动灵敏度",
                szKey = UISettingKey.GamePadInterfaceScrollSensitivity,
                defaultValue = 10,
                nMinVal = 0,
                nMaxVal = 20,
                fnFunc = function(nVal)
                    GamepadData.SetWheelSensitivity(nVal)
                end
            },
        },
    },
    Resources = {
        [RESOURCES.DYNAMIC] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动清理",
                szKey = UISettingKey.AutoCleanDynamicResource,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "外观资源",
                szKey = UISettingKey.CleanEquipResourceInterval,
                defaultValue = GameSettingType.DynamicResources.None,
                options = {
                    GameSettingType.DynamicResources.None,
                    GameSettingType.DynamicResources.OneMonth,
                    GameSettingType.DynamicResources.ThreeMonth,
                },
                szHelpText = "已拥有的外观资源每次在世界场景和功能界面内有显示，则视为最新一次已加载；未拥有的外观资源仅首次下载使用时视为已加载。\n外观扩展包下载完成后，无法使用智能清理功能。",
            },
        },
        [RESOURCES.MAP] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动清理",
                szKey = UISettingKey.AutoCleanMapResource,
                defaultValue = false,
                fnFunc = function(bOpen)

                end,
            },
            {
                type = GameSettingCellType.DropBox,
                szName = "地图资源",
                szKey = UISettingKey.CleanMapResourceInterval,
                defaultValue = GameSettingType.MapResources.None,
                options = {
                    GameSettingType.MapResources.None,
                    GameSettingType.MapResources.TwoWeek,
                    GameSettingType.MapResources.OneMonth,
                },
                --szHelpText = XXX,
            },
        },
    },
    SkillEnhance = {
        [SKILL_ENHANCE.MAIN] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示技能范围提示",
                szKey = UISettingKey.ShowSkillRangeHint,
                defaultValue = true,
                fnFunc = function()
                end,
            },
        },
        [SKILL_ENHANCE.SPECIAL] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "唐门千机变放脚下",
                szKey = UISettingKey.QianJiBianToMe,
                defaultValue = false,
                fnFunc = function(bVal)
                    SpecialSettings.QianJiBianToMe(g_tUIConfig.SkillQianJiBian, bVal)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.TANG_MEN and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示丐帮连招",
                szKey = UISettingKey.ShowGaiBangCombo,
                defaultValue = true,
                fnFunc = function(bVal)
                    SpecialSettings.SetComboPanel(bVal)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.GAI_BANG and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "影子放在自身脚下",
                szKey = UISettingKey.ShadowToMe,
                defaultValue = false,
                fnFunc = function(bVal)
                    SpecialSettings.ShadowToMe(g_tUIConfig.SkillShadow, bVal)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHANG_GE and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动释放阳春白雪",
                szKey = UISettingKey.StartAutoCGSkill,
                defaultValue = false,
                fnFunc = function(bVal)
                    SpecialSettings.SetAutoCGSkillInOTABar(bVal)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHANG_GE and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "手动施展赤日轮和幽月轮",
                szKey = UISettingKey.StopAutoMJSkill,
                defaultValue = false,
                fnFunc = function(bVal)
                    SpecialSettings.SetStopAutoMJSkill(bVal)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.MING_JIAO and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "显示战斗范围辅助圈",
                szKey = UISettingKey.ShowLXGFightCircle,
                defaultValue = true,
                fnFunc = function(bShow)
                    SkillData.ShowLXGFightCircleBySetting(bShow)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.LING_XUE and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "禁止快捷键释放风尽浮生",
                szKey = UISettingKey.WanLingCast,
                defaultValue = false,
                fnFunc = function(bVal)
                    if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.WAN_LING then
                        SetDisplacementSkillSetting("bForbidCastYCBX", bVal)
                    end
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.WAN_LING and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "禁止快捷键释放逸尘步虚 地面",
                szKey = UISettingKey.PengLaiCast,
                defaultValue = false,
                fnFunc = function(bVal)
                    if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.PENG_LAI then
                        SetDisplacementSkillSetting("bForbidCastYCBX", bVal)
                    end
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.PENG_LAI and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "禁止快捷键释放逸尘步虚 浮空",
                szKey = UISettingKey.PengLaiFlyCast,
                defaultValue = false,
                fnFunc = function(bVal)
                    if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.PENG_LAI then
                        SetDisplacementSkillSetting("bForbidSkyCastYCBX", bVal)
                    end
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.PENG_LAI and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "禁止快捷键释放烟雨行",
                szKey = UISettingKey.GaiBangCast,
                defaultValue = false,
                fnFunc = function(bVal)
                    if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.GAI_BANG then
                        SetDisplacementSkillSetting("bForbidCastYCBX", bVal)
                    end
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.GAI_BANG and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "七秀自动施展剑舞",
                szKey = UISettingKey.QiXiuAutoSwordDance,
                defaultValue = true,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.QI_XIU
                end,
                fnFunc = function(bOpen)
                end
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "剑舞状态下自身不再开启剑舞动作",
                szKey = UISettingKey.NotAutoOpenSwordDanceAction,
                defaultValue = false,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.QI_XIU
                end,
                fnFunc = function(bOpen)
                    if bOpen then
                        rlcmd("show or hide local buff animation 0 62022")
                        rlcmd("show or hide local skill buff 0 62022")
                    else
                        rlcmd("show or hide local buff animation 1 62022")
                        rlcmd("show or hide local skill buff 1 62022")
                    end
                end
            },
        },
        [SKILL_ENHANCE.CAST_CONTINUOUS] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "长按连放",
                szKey = UISettingKey.SkillLongPressAutoCast,
                defaultValue = false,
                fnFunc = function()
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                szHelpText = "仅在秘境、主城、帮会领地生效",
                fnVisible = function()
                    return not IsMobileKungfu()
                end,
            },
            {
                type = GameSettingCellType.BlankLine,
                fnVisible = function()
                    return not IsMobileKungfu()
                end,
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "自动连放",
                szKey = UISettingKey.SkillAutoCastWithoutPressing,
                defaultValue = false,
                fnFunc = function(bVal)
                    if not bVal then
                        Event.Dispatch(EventType.OnSkillAutoCastDisabled)
                    end
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                szHelpText = "长按技能槽位3秒进入自动连放状态，可在战斗中自动连续释放技能，再次按下可退出该状态",
                fnVisible = function()
                    return not IsMobileKungfu()
                end,
                tEnable = {
                    fnEnable = function()
                        return GameSettingData.GetNewValue(UISettingKey.SkillLongPressAutoCast)
                    end,
                },
            },
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "脱战保持自动连放",
                szKey = UISettingKey.KeepAutoCastWithoutFight,
                defaultValue = false,
                fnFunc = function(bVal)
                end,
                szHelpText = "勾选后，脱离战斗仍会保持自动连放状态，需勾选自动连放才能生效",
                fnVisible = function()
                    return not IsMobileKungfu()
                end,
                tEnable = {
                    fnEnable = function()
                        return GameSettingData.GetNewValue(UISettingKey.SkillLongPressAutoCast) and
                                GameSettingData.GetNewValue(UISettingKey.SkillAutoCastWithoutPressing)
                    end,
                },
            },
        },
        [SKILL_ENHANCE.QI_CHANG] = {
            {
                type = GameSettingCellType.DropBoxSimple,
                szName = "仅对自身施展气场",
                szKey = UISettingKey.QiChangToMe,
                defaultValue = true,
                fnFunc = function(bVal)
                    SpecialSettings.ApplyQiChangeToMe(g_tUIConfig.SkillQiChang, bVal)
                    Event.Dispatch(EventType.OnGameSettingViewUpdate)
                end,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHUN_YANG and not IsMobileKungfu()
                end
            },
            {
                type = GameSettingCellType.BlankLine,
                fnVisible = function()
                    return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHUN_YANG and not IsMobileKungfu()
                end
            },
        },
    },
}

-----------------纯阳气场设置-------------------------------------------------
do
    local tParentTable = UIGameSettingConfigTab[SettingCategory.SkillEnhance][SKILL_ENHANCE.QI_CHANG]
    for dwQiChangSkillID, tQiChangInfo in pairs(g_tUIConfig.SkillQiChang) do
        local tInsert = {
            type = GameSettingCellType.DropBoxSimple,
            szName = tQiChangInfo.szName,
            szKey = tQiChangInfo.storage,
            defaultValue = true,
            fnFunc = function(bVal)
                if GameSettingData.GetNewValue(UISettingKey.QiChangToMe) then
                    SetSkillCastToMe(dwQiChangSkillID, bVal)
                end
            end,
            fnVisible = function()
                return g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHUN_YANG and not IsMobileKungfu()
            end,
            tEnable = {
                fnEnable = function()
                    return GameSettingData.GetNewValue(UISettingKey.QiChangToMe)
                end,
            },
        }
        table.insert(tParentTable, tInsert)
    end
end
