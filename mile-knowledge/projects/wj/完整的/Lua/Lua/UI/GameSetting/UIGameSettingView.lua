-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGameSettingView
-- Date: 2022-12-20 14:34:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local SKILL_BUTTON_NAME = "技能按键"

local PlatformEnum = {
    VK = "VK",
    DX = "DX",
}

local SettingType = {
    Operate = {
        tMainCategories = {
            OPERATE.MAIN, OPERATE.SPRINT
        }
    },
    Display = {
        tMainCategories = {
            DISPLAY.TARGET_LINE_CONNECT, DISPLAY.TARGET_ENHANCE, DISPLAY.FACING_ENHANCE,
            DISPLAY.TOP_HEAD, DISPLAY.OTHER_VISUAL, DISPLAY.SELF_LIFE_VISUAL, DISPLAY.TARGET_LIFE_VISUAL, DISPLAY.DOUQI
        }
    },
    General = {
        tMainCategories = {
            GENERAL.CAMERA, GENERAL.MOUSE_SETTING, GENERAL.SHIELD, GENERAL.PERFORMANCE, GENERAL.SERVER_SYNC, GENERAL.ADVANCED_ANIMATION, GENERAL.GAME_LOG
        }
    },
    BattleInfo = {
        tMainCategories = {
            BATTLE_INFO.MAIN, BATTLE_INFO.ACTIVE_ATTACK, BATTLE_INFO.DAMAGED,
        }
    },
    Focus = {
        tMainCategories = {
            FOCUS.MAIN, FOCUS.TARGET, FOCUS.AUTO, FOCUS.FOCUS_SETTING, FOCUS.WARNING
        }
    },
    Interface = {
        tMainCategories = {
            INTERFACE.LAYOUT, INTERFACE.FONT, INTERFACE.HEAD_TOP, INTERFACE.DISPLAY_SWITCH
        }
    },
    GamePad = {
        tMainCategories = {
            GAMEPAD_CATEGORY.OTHER
        }
    },
    Quality = {
        tMainCategories = {
            QUALITY.MAIN, QUALITY.RENDER_EFFICIENCY
        }
    },
    Sound = {
        tMainCategories = {
            SOUND_TITLE.MAIN, SOUND_TITLE.MUSIC, SOUND_TITLE.CHARACTER_SPEAK, SOUND_TITLE.REAL_TIME, SOUND_TITLE.MODIFY
        }
    },
    SkillEnhance = {
        tMainCategories = {
            SKILL_ENHANCE.MAIN, SKILL_ENHANCE.SPECIAL, SKILL_ENHANCE.CAST_CONTINUOUS, SKILL_ENHANCE.QI_CHANG
        }
    },
}

local tMultiKeyCodeSet = {
    ["Ctrl"] = true,
    ["Shift"] = true,
    ["Alt"] = true,
}

local tSubCategory2Title = {
    [QUALITY.MAIN] = "主要设置",
    [QUALITY.RENDER_EFFICIENCY] = "自定义选项",
    --[QUALITY.OTHER] = "其他设置",

    [OPERATE.MAIN] = "基础操作",
    [OPERATE.SPRINT] = "轻功",

    [GENERAL.CAMERA] = "镜头类型",
    [GENERAL.SHIELD] = "勿扰设置",
    [GENERAL.PERFORMANCE] = "性能优化策略",
    [GENERAL.ADVANCED_ANIMATION] = "综合动画设置",
    [GENERAL.GAME_LOG] = "游戏日志",
    [GENERAL.SERVER_SYNC] = "服务器同步（开启后同步到服务器，关闭则保存在本机）",
    --[GENERAL.FILTER_SETTING] = "时光漫游",
    [GENERAL.MOUSE_SETTING] = "鼠标设置",

    [DISPLAY.TOP_HEAD] = "头顶显示",
    [DISPLAY.OTHER_VISUAL] = "其他显示",
    [DISPLAY.SELF_LIFE_VISUAL] = "自身血条显示",
    [DISPLAY.TARGET_LIFE_VISUAL] = "目标血条显示",
    [DISPLAY.TARGET_LINE_CONNECT] = "目标连线显示",
    [DISPLAY.TARGET_ENHANCE] = "目标方位增强显示",
    [DISPLAY.FACING_ENHANCE] = "面向增强显示",
    [DISPLAY.DOUQI] = "聚劲显示",

    [BATTLE_INFO.MAIN] = "基础信息",
    [BATTLE_INFO.ACTIVE_ATTACK] = "我对目标造成的效果",
    [BATTLE_INFO.DAMAGED] = "目标对我造成的效果",

    [FOCUS.MAIN] = "焦点列表",
    [FOCUS.TARGET] = "目标设置",
    [FOCUS.AUTO] = "自动焦点配置",
    [FOCUS.FOCUS_SETTING] = "焦点设置",
    [FOCUS.WARNING] = "预警设置",

    [INTERFACE.LAYOUT] = "界面布局",
    [INTERFACE.FONT] = "通用字体",
    [INTERFACE.HEAD_TOP] = "头顶文字血条效果",
    [INTERFACE.DISPLAY_SWITCH] = "界面显示",

    [GAMEPAD_CATEGORY.OTHER] = "其他设置",

    [SOUND_TITLE.MAIN] = "主音量",
    [SOUND_TITLE.MUSIC] = "音乐音效",
    [SOUND_TITLE.CHARACTER_SPEAK] = "角色对话",
    [SOUND_TITLE.REAL_TIME] = "实时语音",
    [SOUND_TITLE.MODIFY] = "变声设置：原声",

    [SKILL_ENHANCE.MAIN] = "通用设定",
    [SKILL_ENHANCE.SPECIAL] = "特殊门派设定",
    [SKILL_ENHANCE.QI_CHANG] = "气场设定",
    [SKILL_ENHANCE.CAST_CONTINUOUS] = "技能释放方式",
}

---@class UIGameSettingView
local UIGameSettingView = class("UIGameSettingView")

function UIGameSettingView:OnEnter(szCategory, nSubSelectIndex)
    self:Init()

    self.nContainerIndex = 1
    self.szSelectedCategory = szCategory
    self.nSubSelectIndex = nSubSelectIndex or 1

    self.szSearchKey = ""
    self.bSearchState = false
    self.tbTempTotalGameConfig = clone(UIGameSettingConfigTab) -- 用于搜索设置
    self.tbTempTotalGameConfig[SettingCategory.ShortcutInteraction] = {} -- 特殊处理按键设置分类
    self.tbTempTotalGameConfig[SettingCategory.WordBlock] = {} -- 特殊处理屏蔽关键次设置分类
    self.tbSearchingUIGameConfig = self.tbTempTotalGameConfig -- 用于搜索设置

    self.bInFaceState = SceneMgr.IsInFaceState()
    if self.bInFaceState then
        rlcmd("bd enable focus face 0")  -- 如果开启怼脸效果则关闭，避免与引擎参数设置冲突
    end

    self.tCategoryInfoList = {
        [SettingCategory.General] = {
            szName = "综合设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.General)
            end
        },
        [SettingCategory.Sound] = {
            szName = "声音设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.Sound)
            end
        },
        [SettingCategory.Quality] = {
            szName = "画质设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.Quality)
            end,
            fnVisible = function()
                return not Channel.Is_WLColud()
            end
        },
        [SettingCategory.Interface] = {
            szName = "界面设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.Interface)
            end
        },
        [SettingCategory.Operate] = {
            szName = "操作设置",
            fnUpdate = function()
                SprintData.SyncServerSprintSetting()
                self:UpdateCategoryInfo(SettingCategory.Operate)
            end
        },
        [SettingCategory.ShortcutInteraction] = {
            szName = "按键设置",
            fnUpdate = function(bFromChildTog)
                self:UpdateShortcutInteractionInfo(bFromChildTog)
            end,
            fnVisible = function()
                return not Channel.Is_WLColud() and (not Platform.IsMobile() or KeyBoard.MobileHasKeyboard())
            end,
            fnTogListGenerate = function()
                local tTogList = {}
                table.insert(tTogList, SKILL_BUTTON_NAME)
                for nClassIndex, tClass in ipairs(UISettingStoreTab.tShortCutClassList) do
                    if tClass.szTitle ~= "角色动作" and tClass.szTitle ~= "技能相关" then
                        table.insert(tTogList, tClass.szTitle)
                    end
                end
                return tTogList
            end
        },
        [SettingCategory.GamePad] = {
            szName = "手柄设置",
            szCategory = SettingCategory.GamePad,
            fnUpdate = function()
                self:UpdateGamePadInfo()
            end,
            fnVisible = function()
                return GamepadData.IsGamepadMode()
            end,
            tChildTogs = {
                "手柄按键",
                "其他设置",
            }
        },
        [SettingCategory.Display] = {
            szName = "显示设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.Display)
            end
        },
        [SettingCategory.BattleInfo] = {
            szName = "战斗信息",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.BattleInfo)
            end
        },
        [SettingCategory.Focus] = {
            szName = "焦点列表",
            szCategory = SettingCategory.Focus,
            fnUpdate = function()
                self:UpdateFocusInfo()
            end,
            tChildTogs = {
                "综合设置",
                "永久焦点",
                "自定义",
            }
        },
        [SettingCategory.WordBlock] = {
            szName = "屏蔽关键词",
            fnUpdate = function()
                self:UpdateWordBlockInfo()
            end
        },
        [SettingCategory.SkillEnhance] = {
            szName = "技能设置",
            fnUpdate = function()
                self:UpdateCategoryInfo(SettingCategory.SkillEnhance)
            end,
        },
    }

    self.tOldQuality = self:_LogSetting()

    self.tShortcutPanel = UIHelper.AddPrefab(PREFAB_ID.WidegtSkillKeyboardSettingMain, self.WidegtAnchorSkillSetting, self)
    self.tFocusPanel = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanentList, self.WidegtAnchorFocusSetting)
    self.tFocusCustomPanel = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanentCustomList, self.WidgetAnchorFocusCustom)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true)

    self.tSpecialClass = {
        ["角色动作"] = self.tShortcutPanel.ScrollViewNomalList,
        ["技能相关"] = self.tShortcutPanel.ScrollViewFightList,
        ["动态快捷栏相关"] = self.tShortcutPanel.ScrollViewDynamicList
    }

    if QualityMgr.CanShow120Frame() then
        local bSupport = KG3DEngine.IsSupportGameFrc() -- 检查IRX状态
        if bSupport == false then
            GameSettingData.StoreNewValue(UISettingKey.IRXRenderBoost, false)
        end
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo_iOS_Keyboard()
    self:InitLeftTabTree(szCategory, nSubSelectIndex)
end

function UIGameSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Event.Dispatch(EventType.SetKeyBoardGameSettingEnable, false)
    Event.Dispatch(EventType.SetGamepadGameSettingEnable, false)

    if self.bInFaceState then
        self.bInFaceState = false
        rlcmd("bd enable focus face 1")
        rlcmd("bd try enter focus face 1 0")
    end

    local tNewQuality = self:_LogSetting()
    for k, v in pairs(tNewQuality) do
        local new = v
        local old = self.tOldQuality[k]
        if k ~= "窗口分辨率" and v ~= old then
            DataReport.Report_QualityInfo() --画质选项有改动时进行上报
            break
        end
    end

    UISettingStoreTab.Flush()
    UISettingNewStorageTab.Flush()
end

function UIGameSettingView:BindUIEvent()
    if AppReviewMgr.IsReview() then
        UIHelper.SetVisible(self.BtnActivation, false)
    end
    UIHelper.BindUIEvent(self.BtnActivation, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelKeyExchangePop)
    end)

    UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            self:UpdateSearch()
        end
    end)

    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        self:UpdateSearch(true)
        UIHelper.SetSelected(self.TogSearch, false)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelGameSettings)
    end)
    UIHelper.BindUIEvent(self.BtnRenew, EventType.OnClick, function()
        if self:GetCurrentCategory() == SettingCategory.Quality and Device.IsUnderIOS15() and DungeonData.IsInDungeon() then
            TipsHelper.ShowNormalTip("副本内不能切换画质，需要切换画质请升级操作系统。")
            TipsHelper.DeleteAllHoverTips()
            return
        end

        UIHelper.ShowConfirm("请问是否需要将当前切页所有配置都重置为初始状态？", function()
            self:Reset()
            CustomData.Dirty(CustomDataType.Global)
            self:UpdateInfo()
        end)
    end)
    UIHelper.BindUIEvent(self.TogNetworkDownLoad, EventType.OnSelectChanged, function(_, bSelected)
        PakDownloadMgr.SetAllowNotWifiDownload(bSelected)
    end)
    UIHelper.BindUIEvent(self.BtnDownload, EventType.OnClick, function()
        UIMgr.OpenSingle(true, VIEW_ID.PanelResourcesDownload)
    end)

    UIHelper.BindUIEvent(self.BtnAgreement, EventType.OnClick, function()
        UIHelper.OpenWeb(tUrl.ConfigAgree)
    end)

    UIHelper.BindUIEvent(self.BtnPrivacy, EventType.OnClick, function()
        UIHelper.OpenWeb(tUrl.ConfigPrivacy)
    end)

    UIHelper.BindUIEvent(self.BtnChildPrivacy, EventType.OnClick, function()
        UIHelper.OpenWeb(tUrl.ConfigPersonalInfo)
    end)

    UIHelper.BindUIEvent(self.BtnShareList, EventType.OnClick, function()
        UIHelper.OpenWeb(tUrl.ConfigShare)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnBg, false)
    UIHelper.SetTouchDownHideTips(self.BtnDeleteKeyBoard, false)
    UIHelper.BindUIEvent(self.BtnDeleteKeyBoard, EventType.OnClick, function()
        if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
            return
        end

        local tInteraction
        if self:GetCurrentCategory() == SettingCategory.ShortcutInteraction then
            local szPreVKey = UISettingStoreTab.ShortcutInteraction[self.nKeyboardSelectedCode].VKey
            local szFinalKey = ""
            if szPreVKey == szFinalKey then
                return
            end

            self:OnFinished(szPreVKey, szFinalKey)
        elseif self:GetCurrentCategory() == SettingCategory.GamePad then
            local szPreVKey = UISettingStoreTab.GamepadInteraction[self.nKeyboardSelectedCode].VKey
            local szFinalKey = ""
            if szPreVKey == szFinalKey then
                return
            end

            self:OnGamepadFinished(szPreVKey, szFinalKey)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            self:UpdateSearch()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            self:UpdateSearch()
        end)
    end
end

function UIGameSettingView:RegEvent()
    Event.Reg(self, EventType.OnGameSettingsSliderChange, function(nType, fValue)
        GameSettingData.ApplySoundVolumeSetting(nType, fValue)
        GetGameSoundSetting(nType).Slider = fValue
        CustomData.Dirty(CustomDataType.Global)
    end)

    Event.Reg(self, EventType.OnGameSettingsTogSelectChange, function(nType, bSelected, nProgress)
        if GetGameSoundSetting(nType).TogSelect == bSelected then
            return
        end
        GameSettingData.ApplySoundEnableSetting(nType, not bSelected, nProgress)
        GetGameSoundSetting(nType).TogSelect = bSelected
        CustomData.Dirty(CustomDataType.Global)
    end)

    Event.Reg(self, EventType.OnKeyboardDownForGameSetting, function(nKeyCode, szKeyName)
        self:OnKeyboardDownForGameSetting(nKeyCode, szKeyName)
    end)

    Event.Reg(self, EventType.OnKeyboardUpForGameSetting, function(nKeyCode, szKeyName)
        self:OnKeyboardUpForGameSetting(nKeyCode, szKeyName)
    end)

    Event.Reg(self, EventType.OnGamepadKeyDownForGameSetting, function(szKeyName)
        self:OnGamepadKeyDownForGameSetting(szKeyName)
    end)

    Event.Reg(self, EventType.OnGamepadKeyUpForGameSetting, function(szKeyName)
        self:OnGamepadKeyUpForGameSetting(szKeyName)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CancelKeyboardSelectedState()
    end)

    Event.Reg(self, EventType.OnGameSettingsKeyboardReset, function(nShortcutID)
        if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
            return
        end

        local szPreVKey = UISettingStoreTab.ShortcutInteraction[self.nKeyboardSelectedCode].VKey

        local tConfig = UIShortcutInteractionTab[nShortcutID]
        local szOriginKey = tConfig and tConfig.VKey or ""
        if szPreVKey == szOriginKey then
            return TipsHelper.ShowImportantBlueTip("当前已是默认设置")
        end

        self:OnFinished(szPreVKey, szOriginKey)
    end)

    Event.Reg(self, EventType.OnGameSettingsKeyboardChange, function(nShortcutID, szPreVaule, szValue)
        if szPreVaule ~= szValue and not ShortcutInteractionData.GetIsReset() and not ShortcutInteractionData.GetIsSync() then
            local tShortCutInfo = UISettingStoreTab.ShortcutInteraction[nShortcutID]
            local szKeyViewName = ShortcutInteractionData.GetKeyViewName(szValue, false, SHORTCUT_ICON_TYPE.SETTING)
            if not string.is_nil(szKeyViewName) then
                TipsHelper.ShowNormalTip(string.format("【%s】的快捷键已改为[%s]", tShortCutInfo.szName, szKeyViewName), true)
            else
                TipsHelper.ShowNormalTip(string.format("【%s】的快捷键已清除", tShortCutInfo.szName), true)
            end
        end

        if not string.is_nil(szPreVaule) then
            self.VKeyToShortcutID[szPreVaule] = nil
        end
        if not string.is_nil(szValue) then
            self.VKeyToShortcutID[szValue] = nShortcutID
        end

        if ShortcutInteractionData.GetIsReset() then
            self.VKeyToShortcutID = {}
            self.VKeySpecialToShortcutID = {}

            for k, v in pairs(UISettingStoreTabDefault.ShortcutInteraction) do
                if v.nMaxKeyLen > 0 and not string.is_nil(v.VKey) then
                    if v.szPlatform == "" or self.szPlatformEnum == v.szPlatform then
                        self.VKeyToShortcutID[v.VKey] = k
                    else
                        self.VKeySpecialToShortcutID[v.VKey] = k
                    end
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnGameSettingsGamepadReset, function(nShortcutID)
        if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
            return
        end

        local szPreVKey = UISettingStoreTab.GamepadInteraction[self.nKeyboardSelectedCode].VKey

        local tConfig = UIGamepadInteractionTab[nShortcutID]
        local szOriginKey = tConfig and tConfig.VKey or ""
        if szPreVKey == szOriginKey then
            return TipsHelper.ShowImportantBlueTip("当前已是默认设置")
        end

        self:OnGamepadFinished(szPreVKey, szOriginKey)
    end)

    Event.Reg(self, EventType.OnGameSettingsGamepadChange, function(nShortcutID, szPreVaule, szValue)
        if szPreVaule ~= szValue and not ShortcutInteractionData.GetIsReset() and not ShortcutInteractionData.GetIsSync() then
            local tShortCutInfo = UISettingStoreTab.GamepadInteraction[nShortcutID]
            local szKeyViewName = ShortcutInteractionData.GetGamepadViewName(szValue)
            if not string.is_nil(szKeyViewName) then
                TipsHelper.ShowNormalTip(string.format("【%s】的手柄键位已改为[%s]", tShortCutInfo.szName, szKeyViewName), true)
            else
                TipsHelper.ShowNormalTip(string.format("【%s】的手柄键位已清除", tShortCutInfo.szName), true)
            end
        end

        if not string.is_nil(szPreVaule) then
            self.GamepadVKeyToShortcutID[szPreVaule] = nil
        end
        if not string.is_nil(szValue) then
            self.GamepadVKeyToShortcutID[szValue] = nShortcutID
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(arg0, arg1)
        -- 忽略最小化
        if arg0 ~= 0 and arg1 ~= 0 then
            Timer.AddFrame(self, 5, function()
                UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewGameSettings, true, true)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGameSettings)

                UIHelper.CascadeDoLayoutDoWidget(self.ScrollItemLeftTree, true, true)
                UIHelper.ScrollViewDoLayout(self.ScrollItemLeftTree)
            end)
            if self:GetCurrentCategory() == SettingCategory.Quality and self.tWindowsSizeScript then
                self.tWindowsSizeScript:SetSelectName(arg0 .. "x" .. arg1)
            end
        end
    end)

    Event.Reg(self, EventType.OnGameSettingViewUpdate, function()
        Timer.AddFrame(self, 1, function()
            local nX, nY = UIHelper.GetScrolledPosition(self.ScrollViewGameSettings)  -- 获取滑动Offset情况（默认以最底部进行计算）
            local _, nContainer = UIHelper.GetInnerContainerSize(self.ScrollViewGameSettings) -- 获取内部container高度
            local nHeight = UIHelper.GetHeight(self.ScrollViewGameSettings) -- 获取ScrollView高度
            local nLeft = nContainer - (nHeight - nY) --  ScrollView高度-滑动Offset可计算出当前内容总长度nTotal ;nContainer - nTotal 可计算出当前位置与离顶部的距离
            self:UpdateInfo()
            _, nContainer = UIHelper.GetInnerContainerSize(self.ScrollViewGameSettings)
            local nNewLeft = nLeft - (nContainer - nHeight) --  重新计算出与顶部的距离相同时的正确滑动位置
            UIHelper.SetScrolledPosition(self.ScrollViewGameSettings, nX, nNewLeft) --恢复ScrollView位置
        end)
    end)

    Event.Reg(self, EventType.OnGamepadTypeChanged, function(nGamepadType)
        if nGamepadType ~= GamePadType.NONE then
            TipsHelper.ShowNormalTip("检测到手柄接入，请重开界面刷新后选择手柄设置")
        end
    end)
end

function UIGameSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIGameSettingView:Init()
    self.VKeyToShortcutID = {}
    self.VKeySpecialToShortcutID = {}
    local bIsHD = SkillData.IsUsingHDKungFu()
    self.szPlatformEnum = bIsHD and PlatformEnum.DX or PlatformEnum.VK

    for k, v in pairs(UISettingStoreTab.ShortcutInteraction) do
        if v.nMaxKeyLen > 0 and not string.is_nil(v.VKey) then
            if v.szPlatform == "" or self.szPlatformEnum == v.szPlatform then
                self.VKeyToShortcutID[v.VKey] = k
            else
                self.VKeySpecialToShortcutID[v.VKey] = k
            end
        end
    end

    self.GamepadVKeyToShortcutID = {}
    for k, v in pairs(UISettingStoreTab.GamepadInteraction) do
        if v.nMaxKeyLen > 0 and not string.is_nil(v.VKey) then
            self.GamepadVKeyToShortcutID[v.VKey] = k
        end
    end

    if not PakDownloadMgr.IsEnabled() or Channel.Is_WLColud() then
        UIHelper.SetVisible(self.BtnDownload, false)
        UIHelper.SetVisible(self.ImgBtnLine, false)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollItemLeftTree)
    UIHelper.SetSelected(self.TogNetworkDownLoad, PakDownloadMgr.GetAllowNotWifiDownload(), false)
end

local tbSettingLeftTabOrder_ObMode = {
    SettingCategory.General,
    SettingCategory.Sound,
    SettingCategory.Quality,
}

function UIGameSettingView:InitLeftTabTree(szInitialCategory, nSubSelectIndex)
    if not self.navigationScript then
        self.navigationScript = UIHelper.GetBindScript(self.WidgetAnchorLeft)---@type UIWidgetScrollViewTree
        self.navigationScript:SetOuterInitSelect(false)
    end
    self.navigationScript:ClearContainer()

    local navigationData = {}
    local nCount = 0
    local nInitContainerIndex = 1

    local tbSettingLeftTabOrder = {
        SettingCategory.General,
        SettingCategory.Sound,
        SettingCategory.Quality,
        SettingCategory.Interface,
        SettingCategory.Operate,
        SettingCategory.ShortcutInteraction,
        SettingCategory.GamePad,
        SettingCategory.Display,
        SettingCategory.SkillEnhance,
        SettingCategory.BattleInfo,
        SettingCategory.Focus,
        SettingCategory.WordBlock,
    }

    if OBDungeonData.IsPlayerInOBDungeon() then
        tbSettingLeftTabOrder = tbSettingLeftTabOrder_ObMode
    end

    for nIndex, szCategory in ipairs(tbSettingLeftTabOrder) do
        local tInfo = self.tCategoryInfoList[szCategory]
        if tInfo and self.tbSearchingUIGameConfig[szCategory] and (not tInfo.fnVisible or tInfo.fnVisible()) then
            nCount = nCount + 1 -- 主要分类可见且在搜索列表内

            local nLocalIndex = nCount
            local fnTitleSelected = function(bSelected, scriptContainer)
                if not bSelected then
                    return
                end

                self.nContainerIndex = nLocalIndex
                self.nSubSelectIndex = 1
                self.szSelectedCategory = szCategory
                if scriptContainer.tItemScripts[1] then
                    for i, v in ipairs(scriptContainer.tItemScripts) do
                        UIHelper.SetSelected(v.ToggleChildNavigation, i == 1, false) -- 选中第一个子节点
                    end
                else
                    UIHelper.SetVisible(scriptContainer.ImgLine, false)
                end
                self:UpdateInfo()
            end
            local titleData = { tArgs = { szTitle = tInfo.szName }, fnSelectedCallback = fnTitleSelected }

            if tInfo.fnTogListGenerate and IsFunction(tInfo.fnTogListGenerate) then
                tInfo.tChildTogs = tInfo.fnTogListGenerate() -- 动态生成子节点
            end

            if tInfo.tChildTogs then
                titleData.tItemList = { }
                for nSubIndex, szName in ipairs(tInfo.tChildTogs) do
                    local fnSubSelected = function(toggle, bState)
                        if bState == true and self.nSubSelectIndex ~= nSubIndex then
                            self.nSubSelectIndex = nSubIndex
                            self:UpdateInfo(true)
                        end
                    end
                    local subData = { tArgs = { szTitle = szName, onSelectChangeFunc = fnSubSelected } }
                    table.insert(titleData.tItemList, subData)
                end
            end

            table.insert(navigationData, titleData)
            if szCategory == szInitialCategory then
                nInitContainerIndex = nCount -- 动态决定初始分页
            end
        end
    end

    ---@param scriptContainer UIScrollViewTreeContainer
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)
    end

    UIHelper.SetupScrollViewTree(self.navigationScript, PREFAB_ID.WidgetFengYunLuTitle, PREFAB_ID.WidgetFengYunLuChildNavigation,
            func, navigationData, true)
    Timer.AddFrame(self, 5, function()
        UIHelper.ScrollViewSetupArrow(self.ScrollItemLeftTree, self.WidgetArrowParent)
    end)

    -- 初始分页加载
    if self.navigationScript.tContainerList[nInitContainerIndex] then
        local scriptContainer = self.navigationScript.tContainerList[nInitContainerIndex].scriptContainer
        Timer.AddFrame(self, 2, function()
            UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
            if nSubSelectIndex and nSubSelectIndex ~= 1 and scriptContainer.tItemScripts[nSubSelectIndex] then
                UIHelper.SetSelected(scriptContainer.tItemScripts[nSubSelectIndex].ToggleChildNavigation, true)
            end
        end)
    end
end

function UIGameSettingView:UpdateInfo(bFromChildTog)
    self:ResetContent()

    local tCategoryInfo = self.tCategoryInfoList[self.szSelectedCategory]
    local fnUpdateFunction = tCategoryInfo and tCategoryInfo.fnUpdate
    if fnUpdateFunction then
        fnUpdateFunction(bFromChildTog)
    end

    Event.Dispatch(EventType.SetKeyBoardGameSettingEnable, self:GetCurrentCategory() == SettingCategory.ShortcutInteraction
            or self:GetCurrentCategory() == SettingCategory.GamePad)
end

function UIGameSettingView:Reset()
    ShortcutInteractionData.SetIsReset(true)

    local tIgnoreCategory = {
        [SettingCategory.Quality] = true,
        [SettingCategory.ShortcutInteraction] = true,
    }
    local szType = self:GetCurrentCategory()
    if szType and not tIgnoreCategory[szType] then
        GameSettingData.ResetSettingCategoryToDefault(szType)
    end

    if szType == SettingCategory.Sound then
        GameSettingData.InitSoundSetting(false)
    elseif szType == SettingCategory.Quality then
        QualityMgr.ResetToDefaultQuality()
    elseif szType == SettingCategory.ShortcutInteraction then
        for k, v in ipairs(UISettingStoreTab.ShortcutInteraction) do
            Event.Dispatch(EventType.OnGameSettingsKeyboardChange, k, v.VKey, UISettingStoreTabDefault.ShortcutInteraction[k].VKey)
            UISettingStoreTab.ShortcutInteraction[k].VKey = UISettingStoreTabDefault.ShortcutInteraction[k].VKey
        end
        -- UISettingStoreTab.ShortcutInteraction = clone(UISettingStoreTabDefault.ShortcutInteraction)
        UISettingStoreTab.Flush()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    elseif szType == SettingCategory.GamePad then
        for k, v in ipairs(UISettingStoreTab.GamepadInteraction) do
            Event.Dispatch(EventType.OnGameSettingsGamepadChange, k, v.VKey, UISettingStoreTabDefault.GamepadInteraction[k].VKey)
            UISettingStoreTab.GamepadInteraction[k].VKey = UISettingStoreTabDefault.GamepadInteraction[k].VKey
        end
        -- UISettingStoreTab.GamepadInteraction = clone(UISettingStoreTabDefault.GamepadInteraction)
        UISettingStoreTab.Flush()
        GamepadData.UpdateKey2Func()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end

    ShortcutInteractionData.SetIsReset(false)
end

local lastSettingSwitchRowScript = nil ---@type UIWidgetSettingsSwitchRow
local lastSoundRowScript = nil ---@type UIWidgetSettingsSwitchRow
local lastFontRowScript = nil ---@type UIWidgetSettingFont
local function AddCellToScrollView(tScrollView, tCellInfo, nMainCategory)
    local SetVal = function(targetVal)
        if tCellInfo.szKey then
            GameSettingData.StoreNewValue(tCellInfo.szKey, targetVal)
            return
        end
    end
    local GetVal = function()
        if tCellInfo.szKey then
            return GameSettingData.GetNewValue(tCellInfo.szKey)
        end
    end

    local tConfirm = tCellInfo.tConfirm
    local tDisable = tCellInfo.tDisable
    local tSettingVal = GetVal()
    local script

    local ShowConfirm = function(tConfirm, fnApply, fnCancel)
        local dialog = UIHelper.ShowConfirm(tConfirm.szMessage, fnApply, fnCancel)
        if tConfirm.fnOtherApply then
            dialog:ShowOtherButton()
            dialog:SetOtherButtonClickedCallback(tConfirm.fnOtherApply)
            if tConfirm.szOther then
                dialog:SetOtherButtonContent(tConfirm.szOther)
            end
            --dialog:SetCancelButtonContent("取消")
        end

        if tConfirm.szConfirm then
            dialog:SetConfirmButtonContent(tConfirm.szConfirm)
        end
    end

    local fnSlideEndBack = function(nCurrentVal)
        local bRefresh = false
        local fnSliderApply = function()
            SetVal(nCurrentVal)
            CustomData.Dirty(CustomDataType.Global)

            if tCellInfo.fnFunc then
                tCellInfo.fnFunc(nCurrentVal)
            else
                LOG.WARN("没有fnFunc %s", tCellInfo.szName)
            end
            Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelGameSettings, tCellInfo.szName)

            if bRefresh then
                Event.Dispatch(EventType.OnGameSettingViewUpdate) -- 有弹窗时 进行刷新
            end
        end

        local fnCancel = function()
            if bRefresh then
                Event.Dispatch(EventType.OnGameSettingViewUpdate) -- 有弹窗时 进行刷新
            end
        end

        if tConfirm and tConfirm.fnCanShowConfirm(nCurrentVal) then
            bRefresh = true
            ShowConfirm(tConfirm, fnSliderApply, fnCancel)
        else
            fnSliderApply()
        end
    end

    if tCellInfo.fnVisible and not tCellInfo.fnVisible() then
        return -- 若当前设置不应被展示，则直接跳过
    end

    if tCellInfo.type == GameSettingCellType.Slider then
        script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsSlider, tScrollView, tCellInfo, tSettingVal, fnSlideEndBack)
        script:SetName(tCellInfo.szName)
    elseif tCellInfo.type == GameSettingCellType.SoundSlider or tCellInfo.type == GameSettingCellType.SoundSlider_Short then
        local nSoundType = tCellInfo.nSoundType
        if nSoundType and tSettingVal then
            local nPrefabID = tCellInfo.type == GameSettingCellType.SoundSlider and PREFAB_ID.WidgetSettingsVolume or PREFAB_ID.WidgetSettingsVolume_short
            script = UIHelper.AddPrefab(nPrefabID, tScrollView, tSettingVal, nSoundType)
            script:SetName(tCellInfo.szName)
        end
    elseif tCellInfo.type == GameSettingCellType.SliderCell then
        if not lastSoundRowScript or lastSoundRowScript:IsFull() then
            lastSoundRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingVolume_Sub, tScrollView)
        end
        lastSoundRowScript:AddSwitch(tCellInfo, tSettingVal, fnSlideEndBack)
    elseif tCellInfo.type == GameSettingCellType.Button then
        if not lastSettingSwitchRowScript or lastSettingSwitchRowScript:IsFull() then
            lastSettingSwitchRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingSwitch, tScrollView) -- 为了挂靠的正确显示 提前在一行中摆好两个预制
        end
        lastSettingSwitchRowScript:AddButton(tCellInfo)
    elseif tCellInfo.type == GameSettingCellType.DropBox then
        script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsMultipleChoice, tScrollView, false, tCellInfo)
        script:SetName(tCellInfo.szName)
        script:SetHelpText(tCellInfo.szHelpText)

        local tOptionList = (tCellInfo.bDynamic and tCellInfo.fnDynamicOption) and tCellInfo.fnDynamicOption() or tCellInfo["options"]
        for _, tInfo in ipairs(tOptionList) do
            local bVisible = true
            if tInfo.fnVisible and IsFunction(tInfo.fnVisible) then
                bVisible = tInfo.fnVisible()
            end

            if bVisible then
                local fnSelected = function()
                    if tCellInfo.bDynamic and tCellInfo.fnDynamicSelected then
                        return tCellInfo.fnDynamicSelected(tInfo) -- 显示动态信息
                    else
                        local tCurrentVal = GetVal()
                        if tCurrentVal == nil then
                            return false
                        end
                        return tInfo.szDec == tCurrentVal.szDec
                    end
                end

                local fnApply = function()
                    script:SetSelectName(tInfo.szDec)

                    SetVal(tInfo)
                    CustomData.Dirty(CustomDataType.Global)

                    local nFunc = tInfo.nFuncIndex and GameSettingType.Func[tInfo.nFuncIndex].fn
                    if nFunc then
                        nFunc(tInfo.tFuncParam)
                    end

                    if tCellInfo.fnFunc then
                        tCellInfo.fnFunc(tInfo)
                    end
                    --Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelGameSettings, tCellInfo.szName) --改为点击按钮时触发，而非选中后才触发
                end

                local fnFunc = function()
                    if tDisable and tDisable.fnDisable(tInfo) then
                        local script = UIHelper.ShowConfirm(tDisable.szMessage, fnApply)
                        script:HideButton("Confirm")
                    elseif tConfirm and tConfirm.fnCanShowConfirm(tInfo) then
                        ShowConfirm(tConfirm, fnApply)
                    else
                        fnApply()
                    end
                end

                local fnEnable = tInfo.tEnable and tInfo.tEnable.fnEnable
                script:AddSelectButton(tInfo.szDec, fnSelected, fnFunc, false, fnEnable)
            end
        end

        if tCellInfo.bDynamic and tCellInfo.fnDynamicName then
            script:SetSelectName(tCellInfo.fnDynamicName()) -- 显示动态信息
        elseif tSettingVal and tSettingVal.szDec then
            script:SetSelectName(tSettingVal.szDec)
        end
    elseif tCellInfo.type == GameSettingCellType.DropBoxSimple then
        if not lastSettingSwitchRowScript or lastSettingSwitchRowScript:IsFull() then
            lastSettingSwitchRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingSwitch, tScrollView) -- 为了挂靠的正确显示 提前在一行中摆好两个预制
        end
        local fnApply = function(bSelected, script)
            SetVal(bSelected)
            CustomData.Dirty(CustomDataType.Global)

            if tCellInfo.fnFunc then
                tCellInfo.fnFunc(bSelected, script)
            else
                LOG.WARN("没有fnFunc %s", tCellInfo.szName)
            end
            Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelGameSettings, tCellInfo.szName)
        end
        local fnFunc = function(bSelected, toggle, script)
            if tConfirm and tConfirm.fnCanShowConfirm(bSelected) then
                local fnConfirmApply = function()
                    fnApply(bSelected, script)
                end
                local fnCancel = function()
                    UIHelper.SetSelected(toggle, not bSelected)
                end
                ShowConfirm(tConfirm, fnConfirmApply, fnCancel)
            else
                fnApply(bSelected, script)
            end
        end
        local bSelected = tSettingVal
        lastSettingSwitchRowScript:AddSwitch(tCellInfo, fnFunc, bSelected, nMainCategory)

    elseif tCellInfo.type == GameSettingCellType.MultiDropBox then
        script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsMultipleChoice, tScrollView, true, tCellInfo)
        script:SetName(tCellInfo.szName)
        script:SetHelpText(tCellInfo.szHelpText)

        local szSelectName = ""
        local nSelectCount = 0
        for _, tInfo in ipairs(tCellInfo["options"]) do
            local bVisible = true
            if tInfo.fnVisible and IsFunction(tInfo.fnVisible) then
                bVisible = tInfo.fnVisible()
            end

            if bVisible then
                local fnSelected = function()
                    for _, tWord in pairs(tSettingVal) do
                        if tInfo.szDec == tWord.szDec then
                            return true
                        end
                    end
                    return false
                end

                local fnApply = function()
                    local bActive = not table.contain_value_CheckByFunction(tSettingVal, function(tWord)
                        return tInfo.szDec == tWord.szDec
                    end)
                    if bActive then
                        table.insert(tSettingVal, tInfo)
                    else
                        for idx, tWord in ipairs(tSettingVal) do
                            if tInfo.szDec == tWord.szDec then
                                table.remove(tSettingVal, idx)
                            end
                        end
                    end

                    CustomData.Dirty(CustomDataType.Global)

                    if bActive then
                        local nFunc = tInfo.nFuncIndex and GameSettingType.Func[tInfo.nFuncIndex].fn
                        if nFunc then
                            nFunc(tInfo.tFuncParam)
                        end
                    end

                    if tCellInfo.fnFunc then
                        tCellInfo.fnFunc(tInfo)
                    end

                    local szName = ""
                    local nCount = table.GetCount(tSettingVal)
                    if nCount > 1 then
                        szName = "多个随机"
                    elseif nCount == 1 then
                        szName = tSettingVal[1].szDec
                    else
                        szName = ""
                    end
                    script:SetSelectName(szName)
                    --Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelGameSettings, tCellInfo.szName) --改为点击按钮时触发，而非选中后才触发
                end

                local fnFunc = function()
                    if tConfirm and tConfirm.fnCanShowConfirm(tInfo) then
                        ShowConfirm(tConfirm, fnApply)
                    else
                        fnApply()
                    end
                end

                script:AddSelectButton(tInfo.szDec, fnSelected, fnFunc, false)
                if fnSelected() then
                    szSelectName = tInfo.szDec
                    nSelectCount = nSelectCount + 1
                end
            end
        end

        if nSelectCount == 0 then
            script:SetSelectName("")
        elseif nSelectCount == 1 then
            script:SetSelectName(szSelectName)
        else
            script:SetSelectName("多个随机")
        end
    elseif tCellInfo.type == GameSettingCellType.FontCell then
        local toggleGroup
        local nSelectedIndex = 1
        for nIndex, tValue in ipairs(tCellInfo.options) do
            local fnApply = function()
                SetVal(tValue)
                CustomData.Dirty(CustomDataType.Global)

                if tCellInfo.fnFunc then
                    tCellInfo.fnFunc(tValue)
                end
            end

            if not lastFontRowScript or lastFontRowScript:IsFull() then
                lastFontRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingFont, tScrollView)
                if not toggleGroup then
                    toggleGroup = lastFontRowScript.TogGroup
                end
            end
            if tSettingVal and tValue.szDec == tSettingVal.szDec then
                nSelectedIndex = nIndex
            end
            lastFontRowScript:AddFont(tValue, toggleGroup, fnApply)
        end
        UIHelper.SetToggleGroupSelected(toggleGroup, nSelectedIndex - 1)
    elseif tCellInfo.type ~= GameSettingCellType.BlankLine then
        LOG.WARN("Invalid")
        LOG.TABLE(tCellInfo)
    end

    if not (tCellInfo.type == GameSettingCellType.DropBoxSimple or tCellInfo.type == GameSettingCellType.Button) then
        lastSettingSwitchRowScript = nil
    end

    if tCellInfo.type ~= GameSettingCellType.SliderCell then
        lastSoundRowScript = nil
    end
    if tCellInfo.type ~= GameSettingCellType.FontCell then
        lastFontRowScript = nil
    end

    if tCellInfo.type == GameSettingCellType.BlankLine then
        lastSettingSwitchRowScript = nil
        lastSoundRowScript = nil
        lastFontRowScript = nil
    end

    return script
end

function UIGameSettingView:AddQualitySpecialCell(tCellInfo)
    if not tCellInfo then
        return false
    end
    
    local szWindowFrameSize = "窗口分辨率"
    if tCellInfo.szKey == UISettingKey.GraphicsQuality then
        local tOptionList = QualityMgr.GetSettingOptionList()
        local titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsMultipleChoice, self.ScrollViewGameSettings)
        titleScript:SetName(tCellInfo.szName)

        for i, nQualityType in ipairs(tOptionList) do
            local szName = QualityMgr.GetQualityNameByType(nQualityType)
            local fnSelected = function()
                local tVal = GameSettingData.GetNewValue(tCellInfo.szKey)
                if tVal == nil then
                    return false
                end
                return nQualityType == tVal
            end
            local bRecommend = nQualityType == QualityMgr.GetRecommendQualityType()

            titleScript:AddSelectButton(szName, fnSelected, function(label, toggle)
                local _doChangeQuality = function(_nQualityType)
                    QualityMgr.SetQualityByType(_nQualityType)
                    GameSettingData.StoreNewValue(tCellInfo.szKey, _nQualityType)
                    CustomData.Dirty(CustomDataType.Global)
                    self:UpdateCategoryInfo(SettingCategory.Quality)
                end

                local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
                if nRecommendQualityType ~= GameQualityType.INVALID then
                    if Platform.IsMobile() and nQualityType ~= GameQualityType.CUSTOM
                            and (nQualityType - nRecommendQualityType >= 2 or nQualityType == GameQualityType.BLUE_RAY) then
                        UIHelper.ShowConfirm("当前选择的画质性能负载较高，可能会造成发热或卡顿，是否继续更换画质？",
                                function()
                                    _doChangeQuality(nQualityType)
                                end,
                                function()
                                    local nCurQualityType = QualityMgr.GetCurQualityType()
                                    UIHelper.SetString(label, QualityMgr.GetQualityNameByType(nCurQualityType))
                                end)
                        return
                    else
                        _doChangeQuality(nQualityType)
                    end
                end
            end, bRecommend, function()
                local bResult = true
                local szMsg = nil

                if not QualityMgr.CanSwitchQuality() then
                    bResult = false
                    szMsg = "该机型不能切换画质"
                end

                if Device.IsUnderIOS15() and DungeonData.IsInDungeon() then
                    bResult = false
                    szMsg = "副本内不能切换画质，需要切换画质请升级操作系统"
                end

                if nQualityType == GameQualityType.BLUE_RAY and not QualityMgr.CanShowBlueRay() then
                    bResult = false
                    szMsg = "当前设备不兼容所选设置"
                end

                -- 手机 ios4G用户不能切到极致画质
                if Platform.IsIos() then
                    if nQualityType == GameQualityType.EXTREME_HIGH then
                        if Device.GetDeviceTotalMemorySize(true) < 4.1 then
                            bResult = false
                            szMsg = "该机型不能切换到该画质"
                        end
                    end
                end

                -- PC 的 2G显存以下机器，只能最简画质，不让切其他画质
                if Platform.IsWindows() then
                    if Device.IsWinGPUMemoryGBLowUnder2GB() then
                        bResult = false
                        szMsg = "该机型不能切换到该画质"
                    end
                end

                return bResult, szMsg
            end)

        end

        local fnSetQualityName = function()
            local nCurQualityType = QualityMgr.GetCurQualityType()
            local szQualityName = QualityMgr.GetQualityNameByType(nCurQualityType)
            titleScript:SetSelectName(szQualityName)
        end
        fnSetQualityName()

        Event.UnReg(self, EventType.OnQualitySettingChange)
        Event.Reg(self, EventType.OnQualitySettingChange, function()
            fnSetQualityName()
        end)
        return true
    elseif tCellInfo.szName == szWindowFrameSize then
        local script = AddCellToScrollView(self.ScrollViewGameSettings, tCellInfo)
        self.tWindowsSizeScript = script ---@type UIWidgetSettingsMultipleChoice
        if Platform.IsWindows() and self.tWindowsSizeScript then
            local tSize = GetFrameSize()  --窗口分辨率选项的值为当前窗口大小
            if tSize then
                self.tWindowsSizeScript:SetSelectName(tSize.width .. "x" .. tSize.height)
            end
        end
        return true
    end
    return false
end

function UIGameSettingView:UpdateCategoryInfo(szCategory)
    self:ClearScrollView()

    local tInfo = SettingType[szCategory]
    local tCategory = tInfo.tMainCategories
    for _, nMainCategory in pairs(tCategory) do
        lastSettingSwitchRowScript = nil
        lastSoundRowScript = nil
        lastFontRowScript = nil

        local lst = self.tbSearchingUIGameConfig[szCategory] and self.tbSearchingUIGameConfig[szCategory][nMainCategory]

        if lst then
            local titleScript
            if nMainCategory == SOUND_TITLE.MODIFY then
                titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetVoiceType, self.ScrollViewGameSettings, GetGameSoundSetting(SOUND.MIC_VOLUME))
            else
                titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsWordageTitle, self.ScrollViewGameSettings)
                titleScript:SetTitle(tSubCategory2Title[nMainCategory])
                if nMainCategory == INTERFACE.FONT or nMainCategory == BATTLE_INFO.MAIN then
                    titleScript:SetDesc(FontMgr.CheckFontChange(nMainCategory))
                end
            end

            local bHasCell = false
            for index, rowCell in ipairs(lst) do
                if not rowCell.fnVisible or rowCell.fnVisible() then
                    bHasCell = true -- 检查显示状态
                end

                if nMainCategory ~= QUALITY.MAIN or not self:AddQualitySpecialCell(rowCell) then
                    AddCellToScrollView(self.ScrollViewGameSettings, rowCell, nMainCategory)
                end
            end

            if not bHasCell then
                UIHelper.RemoveFromParent(titleScript._rootNode, true)
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewGameSettings)
    UIHelper.ScrollToTop(self.ScrollViewGameSettings, 0)
end

local tCommonSubName = {
    ShortcutDef.SkillSlot1, --技能槽位1
    ShortcutDef.Jump, --跳跃
    ShortcutDef.SwitchSkill, --切换技能栏
    ShortcutDef.SpecialSprint, --门派轻功
    ShortcutDef.FuYao, --扶摇
    ShortcutDef.NieYun, --蹑云逐月/前飘
    ShortcutDef.SkillAuto, --助手
    ShortcutDef.SkillQuick, --特殊道具/团队标记
    ShortcutDef.SelectEnemy, --选择敌人
    ShortcutDef.LockTarget, --目标锁定
    --ShortcutDef.SkillSlot11, -- 动态技能栏额外槽位

    ShortcutDef.DXSkillAuto, -- DX跳跃
    ShortcutDef.DXSkillJump, -- DX跳跃
    ShortcutDef.DXSkillSlot1, -- DX技能槽位1
    ShortcutDef.DXSkillSlotNieYun, -- DX蹑云
    ShortcutDef.DXSkillLingXiao, -- DX凌霄揽胜
    ShortcutDef.DXSkillYaoTai, -- DX瑶台枕鹤
    ShortcutDef.DXSkillYingFeng, -- DX迎风回浪
    ShortcutDef.DXSkillFuYao, -- DX扶摇
    ShortcutDef.DXSkillHouChe, -- DX扶摇
}

function UIGameSettingView:UpdateShortcutInteractionInfo(bFromChildTog)
    if not bFromChildTog and Storage_Server.IsReady() then
        ShortcutInteractionData.SyncServerShortcutSetting()
    end

    self.tShortcutPanel:Clear()
    for nClassIndex, tClass in ipairs(UISettingStoreTab.tShortCutClassList) do
        local tParent = self.tSpecialClass[tClass.szTitle]
        if tParent then
            local tSubIndex = {}
            for _, nSubIndex in ipairs(tClass.tShortCutList) do
                table.insert(tSubIndex, nSubIndex)
            end
            if tClass.szTitle ~= "动态快捷栏相关" then
                for _, szName in ipairs(tCommonSubName) do
                    local tShortcutInfo = ShortcutInteractionData.GetShortcutInfoByDef(szName)
                    if tShortcutInfo and not table.contain_value(tSubIndex, tShortcutInfo.nID) then
                        table.insert(tSubIndex, tShortcutInfo.nID)
                    end
                end
            end

            local bIsHD = SkillData.IsUsingHDKungFu()
            local szPlatformEnum = bIsHD and PlatformEnum.DX or PlatformEnum.VK
            for _, nSubIndex in ipairs(tSubIndex) do
                local tShortCutInfo = UISettingStoreTab.ShortcutInteraction[nSubIndex]
                if tShortCutInfo.szPlatform == "" or tShortCutInfo.szPlatform == szPlatformEnum then
                    local nPrefabID = PREFAB_ID.WidgetSkillKeyboardSettingList
                    local script = UIHelper.AddPrefab(nPrefabID, tParent, nSubIndex, tShortCutInfo.szName, tShortCutInfo.VKey, SHORTCUT_SETTING_TYPE.SKILL)
                    script.tParent = tParent
                    script:SetSelectCallback(function(bSelected, bShouldScrollToNode)
                        if bSelected and self.nKeyboardSelectedCode ~= nSubIndex then
                            self:CancelKeyboardSelectedState()
                            self:StartKeyboardSelectedState(nSubIndex, tShortCutInfo, script, bShouldScrollToNode)
                        elseif not bSelected and self.nKeyboardSelectedCode == nSubIndex then
                            self:CancelKeyboardSelectedState()
                            self.nKeyboardSelectedCode = nil
                        end
                    end)
                    UIHelper.SetCanSelect(script.BtnKeybord, tShortCutInfo.nMaxKeyLen > 0, "当前功能快捷键不可更改", true)

                    local nShortcutID = SHORTCUT_KEY_BOARD_TYPE[tShortCutInfo.paramArgs]
                    script:SetKeyIndex(nShortcutID)
                    --print(nShortcutID)
                end
            end
        end
    end

    self:UpdateShortcutChild()
end

-- 角色动作 技能相关 动态快捷栏相关 三个分类以外的分类被选中时由本函数加载相应的界面
function UIGameSettingView:UpdateShortcutChild()
    if self.nSubSelectIndex then
        local tSubTogList = self.navigationScript.tContainerList[self.nContainerIndex].scriptContainer.tItemScripts
        local szSubName = tSubTogList[self.nSubSelectIndex]:GetName()

        local bIsNormal = false
        self:ClearScrollView()
        for nClassIndex, tClass in ipairs(UISettingStoreTab.tShortCutClassList) do
            if tClass.szTitle == szSubName then
                local tParent = self.tSpecialClass[tClass.szTitle]
                if not tParent then
                    bIsNormal = true
                    local titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingsWordageTitle, self.ScrollViewGameSettings)
                    titleScript:SetTitle(tClass.szTitle)

                    for _, nSubIndex in ipairs(tClass.tShortCutList) do
                        local tShortCutInfo = UISettingStoreTab.ShortcutInteraction[nSubIndex]
                        if self:_shortcutChildVisibleCheck(nSubIndex) then
                            local nPrefabID = PREFAB_ID.WidgetKeybordSetting
                            local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewGameSettings, nSubIndex, tShortCutInfo.szName, tShortCutInfo.VKey, SHORTCUT_SETTING_TYPE.NORMAL)
                            script:SetSelectCallback(function(bSelected)
                                if bSelected and self.nKeyboardSelectedCode ~= nSubIndex then
                                    self:CancelKeyboardSelectedState()
                                    self:StartKeyboardSelectedState(nSubIndex, tShortCutInfo, script)
                                elseif not bSelected and self.nKeyboardSelectedCode == nSubIndex then
                                    self:CancelKeyboardSelectedState()
                                    self.nKeyboardSelectedCode = nil
                                end
                            end)
                            UIHelper.SetCanSelect(script.BtnKeybord, tShortCutInfo.nMaxKeyLen > 0, "当前功能快捷键不可更改", true)
                        end
                    end
                end
            end
        end

        if bIsNormal then
            UIHelper.ScrollViewDoLayout(self.ScrollViewGameSettings)
            UIHelper.ScrollToTop(self.ScrollViewGameSettings, 0)
        end

        self.tShortcutPanel:UpdateInfo(szSubName ~= SKILL_BUTTON_NAME)
        UIHelper.SetVisible(self.WidegtAnchorSkillSetting, not bIsNormal)
        UIHelper.SetVisible(self.ScrollViewGameSettings, bIsNormal)
    end
end

function UIGameSettingView:UpdateFocusInfo()
    UIHelper.SetVisible(self.WidgetAnchorFocusCustom, self.nSubSelectIndex == 3)
    UIHelper.SetVisible(self.WidegtAnchorFocusSetting, self.nSubSelectIndex == 2)
    UIHelper.SetVisible(self.ScrollViewGameSettings, self.nSubSelectIndex == 1)

    if self.nSubSelectIndex == 1 then
        self:UpdateCategoryInfo(SettingCategory.Focus)
    end
end

function UIGameSettingView:UpdateGamePadInfo()
    UIHelper.SetVisible(self.WidgetAnchorGamePad, self.nSubSelectIndex == 1)
    UIHelper.SetVisible(self.ScrollViewGameSettings, self.nSubSelectIndex == 2)

    self.tGamePadPanel = self.tGamePadPanel or UIHelper.AddPrefab(PREFAB_ID.WidegtSkillKeyboardSettingMain, self.WidgetAnchorGamePad, self, true)
    self.tGamePadScript = self.tGamePadPanel.gamePadScript
    self.tGamePadScript:Clear()
    if self.nSubSelectIndex == 2 then
        self:UpdateCategoryInfo(SettingCategory.GamePad)
    end
end

function UIGameSettingView:ClearScrollView()
    UIHelper.RemoveAllChildren(self.ScrollViewGameSettings)
    lastSettingSwitchRowScript = nil
    lastSoundRowScript = nil
    lastFontRowScript = nil
end

function UIGameSettingView:ResetContent()
    UIHelper.SetVisible(self.WidegtAnchorSkillSetting, false)
    UIHelper.SetVisible(self.WidegtAnchorFocusSetting, false)
    UIHelper.SetVisible(self.WidgetAnchorFocusCustom, false)
    UIHelper.SetVisible(self.WidgetAnchorGamePad, false)
    UIHelper.SetVisible(self.WidgetAnchorProhibitWord, false)
    UIHelper.SetVisible(self.ScrollViewGameSettings, true)
    UIHelper.SetVisible(self.WidgetNormal, true)
    self.nKeyboardSelectedCode = nil
end

function UIGameSettingView:StartKeyboardSelectedState(nSubIndex, tShortCutInfo, selectedScript, bShouldScrollToNode, bGamepad)
    self.nKeyboardSelectedCode = nSubIndex
    self.selectedScript = selectedScript

    self.tSelectedKeys = {}
    self.bHideHoverTipsEventFlag = false

    UIHelper.SetString(self.LabelHoverTips, string.format("*请按下【%s】的新快捷键；点击空白处取消修改", tShortCutInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutKeyBoardDes)

    if bShouldScrollToNode then
        UIHelper.ScrollLocateToPreviewItem(selectedScript.tParent, selectedScript._rootNode, Locate.TO_CENTER)
    end

    self.bHideHoverTipsEventFlag = true
    if not UIHelper.GetVisible(self.WidgetAnchorKeybordSetting) then
        UIHelper.SetVisible(self.WidgetAnchorKeybordSetting, true)
    end
end

function UIGameSettingView:CancelKeyboardSelectedState()
    if self.bHideHoverTipsEventFlag then
        -- 事件时序:OnSelectChanged->HideAllHoverTips*(1 or 2)->下一帧执行的函数()
        self.bHideHoverTipsEventFlag = false
        UIHelper.SetVisible(self.WidgetAnchorKeybordSetting, false)
        if not self.bForbidKeyboardChange and self.nKeyboardSelectedCode then
            if self.selectedScript then
                UIHelper.SetSelected(self.selectedScript.BtnKeybord, false)
                self.selectedScript.func(false)
                self.selectedScript = nil
            end
        end
    end
end

function UIGameSettingView:_FormSelectedKeysString()
    local szCombination = self.tSelectedKeys[1]
    for i = 2, #self.tSelectedKeys do
        szCombination = szCombination .. "+" .. self.tSelectedKeys[i]
    end
    return szCombination
end

-- 禁用的按键
local tForbiShortcutKey = {
    "Esc",
    "Enter",
    "LButton",
    "RButton",
    -- "MouseWheelUp",
    -- "MouseWheelDown",
}

-- 无法保持按下状态的按键
local tForbiOSBindKey = {
    "MouseWheelUp",
    "MouseWheelDown",
}

local tForbidKeyCode = {
    ["抬起镜头"] = { tbKeyCodeList = { "MouseWheelUp", "MouseWheelDown" }, szTip = "暂不支持设置滚轮抬起镜头" },
    ["低下镜头"] = { tbKeyCodeList = { "MouseWheelUp", "MouseWheelDown" }, szTip = "暂不支持设置滚轮低下镜头" },
}

function UIGameSettingView:CheckCanSetKeyCode(szName, szKeyName)
    if not szName or not szKeyName then
        return true
    end

    local tForbidKey = tForbidKeyCode[szName]
    if tForbidKey and table.contain_value(tForbidKey.tbKeyCodeList, szKeyName) then
        TipsHelper.ShowNormalTip(tForbidKey.szTip)
        return false
    end

    return true
end

function UIGameSettingView:OnKeyboardDownForGameSetting(nKeyCode, szKeyName)
    if self:GetCurrentCategory() ~= SettingCategory.ShortcutInteraction then
        return
    end

    if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
        return
    end

    if table.contain_value(tForbiShortcutKey, szKeyName) then
        return
    end

    local tShortCutInfo = UISettingStoreTab.ShortcutInteraction[self.nKeyboardSelectedCode]
    if not self:CheckCanSetKeyCode(tShortCutInfo.szName, szKeyName) then
        return
    end

    if tShortCutInfo.szType == "OSBind" and table.contain_value(tForbiOSBindKey, szKeyName) then
        return
    end

    if tShortCutInfo.nMaxKeyLen <= 0 then
        local szKeyViewName = ShortcutInteractionData.GetKeyViewName(szKeyName, false, SHORTCUT_ICON_TYPE.SETTING)
        TipsHelper.ShowImportantYellowTip(string.format("快捷键[%s]被系统定义为不可更改快捷键", szKeyViewName), true)
        return
    end

    if tMultiKeyCodeSet[szKeyName] then
        if tShortCutInfo.nMaxKeyLen == 2 and #self.tSelectedKeys >= 1 then
            TipsHelper.ShowImportantYellowTip("仅允许在Shift/Ctrl/Alt中选择一个用于组合键")
            return
        elseif tShortCutInfo.nMaxKeyLen == 3 and #self.tSelectedKeys >= 2 then
            TipsHelper.ShowImportantYellowTip("仅允许在Shift/Ctrl/Alt中选择两个用于组合键")
            return
        end
        table.insert(self.tSelectedKeys, szKeyName) --为组合键
        return
    end

    table.insert(self.tSelectedKeys, szKeyName)

    local szFinalKey = self:_FormSelectedKeysString()
    local szPreVKey = tShortCutInfo.VKey
    if szPreVKey == szFinalKey then
        table.remove_value(self.tSelectedKeys, szKeyName)
        return
    end

    if tShortCutInfo.nMaxKeyLen == 1 and #self.tSelectedKeys > 1 then
        --主界面右下角区域的按钮的快捷键设置只允许单键设置，不能设置为组合键
        TipsHelper.ShowImportantYellowTip("此快捷键仅允许设置单键")
        return
    end

    self:OnFinished(szPreVKey, szFinalKey)
end

function UIGameSettingView:OnKeyboardUpForGameSetting(nKeyCode, szKeyName)
    if self:GetCurrentCategory() ~= SettingCategory.ShortcutInteraction then
        return
    end

    if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
        return
    end

    table.remove_value(self.tSelectedKeys, szKeyName)
end

function UIGameSettingView:OnFinished(szPreVKey, szFinalKey)
    local tShortCutInteractionSetting = UISettingStoreTab.ShortcutInteraction
    local tShortCutInfo = tShortCutInteractionSetting[self.nKeyboardSelectedCode]
    if not string.is_nil(szFinalKey) and (self.VKeyToShortcutID[szFinalKey] or self.VKeySpecialToShortcutID[szFinalKey] and tShortCutInfo.szPlatform == "") then
        local nShortcutID = self.VKeyToShortcutID[szFinalKey] or self.VKeySpecialToShortcutID[szFinalKey]
        local tCurShortCutInfo = tShortCutInteractionSetting[nShortcutID]
        local szKeyViewName = ShortcutInteractionData.GetKeyViewName(szFinalKey, false, SHORTCUT_ICON_TYPE.SETTING)
        local szContent = string.format("快捷键[%s]已被占用，是否清除【%s】的快捷键？", szKeyViewName, tCurShortCutInfo.szName)

        local nSpecialShortcutID = nil
        local tSpecialCurShortCutInfo = nil
        if self.VKeyToShortcutID[szFinalKey] and self.VKeySpecialToShortcutID[szFinalKey] and tShortCutInfo.szPlatform == "" then   --非技能按键同时占用vk和dx快捷键的情况
            nShortcutID = self.VKeyToShortcutID[szFinalKey]
            nSpecialShortcutID = self.VKeySpecialToShortcutID[szFinalKey]
            tCurShortCutInfo = tShortCutInteractionSetting[nShortcutID]
            tSpecialCurShortCutInfo = tShortCutInteractionSetting[nSpecialShortcutID]
            szContent = string.format("快捷键[%s]已被占用，是否清除【%s】和【%s】的快捷键？", szKeyViewName, tCurShortCutInfo.szName, tSpecialCurShortCutInfo.szName)
        end

        UIHelper.ShowConfirm(szContent, function()
            Event.Dispatch(EventType.OnGameSettingsKeyboardChange, self.VKeyToShortcutID[szFinalKey], tCurShortCutInfo.VKey, "")
            tCurShortCutInfo.VKey = ""

            if tSpecialCurShortCutInfo then
                Event.Dispatch(EventType.OnGameSettingsKeyboardChange, self.VKeySpecialToShortcutID[szFinalKey], tSpecialCurShortCutInfo.VKey, "")
                tSpecialCurShortCutInfo.VKey = ""
            end

            Event.Dispatch(EventType.OnGameSettingsKeyboardChange, self.nKeyboardSelectedCode, tShortCutInfo.VKey, szFinalKey)
            tShortCutInfo.VKey = szFinalKey

            self.bForbidKeyboardChange = false
            self.bHideHoverTipsEventFlag = true
            self:CancelKeyboardSelectedState()

            UISettingStoreTab.Flush()
        end, function()
            self.bForbidKeyboardChange = false
            self.bHideHoverTipsEventFlag = true
            self:CancelKeyboardSelectedState()
        end, true)

        self.bForbidKeyboardChange = true
        self.bHideHoverTipsEventFlag = false -- 弹出二次确认框时屏蔽点空白隐藏HoverTips
    else
        Event.Dispatch(EventType.OnGameSettingsKeyboardChange, self.nKeyboardSelectedCode, tShortCutInfo.VKey, szFinalKey)
        tShortCutInfo.VKey = szFinalKey
        self:CancelKeyboardSelectedState()

        UISettingStoreTab.Flush()
    end
end

local tForbiGamepadKey = {
    "OPTIONS",
}

function UIGameSettingView:OnGamepadKeyDownForGameSetting(szKeyName)
    if self:GetCurrentCategory() ~= SettingCategory.GamePad then
        return
    end

    if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
        return
    end

    if table.contain_value(tForbiGamepadKey, szKeyName) then
        return
    end

    self.bMultiKeyDown = #self.tSelectedKeys > 0

    local tShortCutInfo = UISettingStoreTab.GamepadInteraction[self.nKeyboardSelectedCode]
    if tShortCutInfo.nMaxKeyLen <= 0 then
        local szKeyViewName = ShortcutInteractionData.GetGamepadViewName(szKeyName)
        TipsHelper.ShowImportantYellowTip(string.format("手柄键位[%s]被系统定义为不可更改快捷键", szKeyViewName), true)
        return
    end

    if table.contain_value(GamepadData.tbCombinationSymbol, GamepadKeyName2Code[szKeyName]) then
        if tShortCutInfo.nMaxKeyLen == 2 and #self.tSelectedKeys >= 1 then
            TipsHelper.ShowImportantYellowTip("仅允许在左右扳机键中选择一个用于组合键")
            return
        end
        table.insert(self.tSelectedKeys, szKeyName) --为组合键
        return
    end

    table.insert(self.tSelectedKeys, szKeyName)

    local szFinalKey = self:_FormSelectedKeysString()
    local szPreVKey = tShortCutInfo.VKey
    if szPreVKey == szFinalKey then
        table.remove_value(self.tSelectedKeys, szKeyName)
        self:CancelKeyboardSelectedState()
        return
    end

    if tShortCutInfo.nMaxKeyLen == 1 and #self.tSelectedKeys > 1 then
        --主界面右下角区域的按钮的快捷键设置只允许单键设置，不能设置为组合键
        TipsHelper.ShowImportantYellowTip("此手柄键位仅允许设置单键")
        return
    end

    self:OnGamepadFinished(szPreVKey, szFinalKey)
end

function UIGameSettingView:OnGamepadKeyUpForGameSetting(szKeyName)
    if self:GetCurrentCategory() ~= SettingCategory.GamePad then
        return
    end

    if not self.nKeyboardSelectedCode or self.bForbidKeyboardChange then
        return
    end

    --若就按了单组合键，弹下提示
    if not self.bMultiKeyDown and table.contain_value(self.tSelectedKeys, szKeyName) and table.contain_value(GamepadData.tbCombinationSymbol, GamepadKeyName2Code[szKeyName]) then
        TipsHelper.ShowImportantYellowTip("左右扳机键仅可用作组合键，不可单独设置")
    end

    table.remove_value(self.tSelectedKeys, szKeyName)
end

function UIGameSettingView:OnGamepadFinished(szPreVKey, szFinalKey)
    local tShortCutInteractionSetting = UISettingStoreTab.GamepadInteraction
    local tShortCutInfo = tShortCutInteractionSetting[self.nKeyboardSelectedCode]
    if not string.is_nil(szFinalKey) and self.GamepadVKeyToShortcutID[szFinalKey] then
        local tCurShortCutInfo = tShortCutInteractionSetting[self.GamepadVKeyToShortcutID[szFinalKey]]
        local szKeyViewName = ShortcutInteractionData.GetGamepadViewName(szFinalKey)
        local szContent = string.format("手柄键位[%s]已被占用，是否清除【%s】的手柄键位？", szKeyViewName, tCurShortCutInfo.szName)
        UIHelper.ShowConfirm(szContent, function()
            Event.Dispatch(EventType.OnGameSettingsGamepadChange, self.GamepadVKeyToShortcutID[szFinalKey], tCurShortCutInfo.VKey, "")
            Event.Dispatch(EventType.OnGameSettingsGamepadChange, self.nKeyboardSelectedCode, tShortCutInfo.VKey, szFinalKey)

            tShortCutInfo.VKey = szFinalKey
            tCurShortCutInfo.VKey = ""

            self.bForbidKeyboardChange = false
            self.bHideHoverTipsEventFlag = true
            self:CancelKeyboardSelectedState()

            UISettingStoreTab.Flush()
            GamepadData.UpdateKey2Func()
        end, function()
            self.bForbidKeyboardChange = false
            self.bHideHoverTipsEventFlag = true
            self:CancelKeyboardSelectedState()
        end, true)

        self.bForbidKeyboardChange = true
        self.bHideHoverTipsEventFlag = false -- 弹出二次确认框时屏蔽点空白隐藏HoverTips
    else
        Event.Dispatch(EventType.OnGameSettingsGamepadChange, self.nKeyboardSelectedCode, tShortCutInfo.VKey, szFinalKey)
        tShortCutInfo.VKey = szFinalKey
        self:CancelKeyboardSelectedState()

        UISettingStoreTab.Flush()
        GamepadData.UpdateKey2Func()
    end

    Event.Dispatch(EventType.SetGamepadGameSettingEnable, false)
end

function UIGameSettingView:_LogSetting()
    local tQualityLog = {}

    for k, category in pairs(UIGameSettingConfigTab[SettingCategory.Quality]) do
        for _, tConfig in ipairs(category) do
            if tConfig.szKey then
                local tVal = GameSettingData.GetNewValue(tConfig.szKey)
                tQualityLog[tConfig.szName] = IsTable(tVal) and tVal.szDec or tVal
            end
        end
    end
    return tQualityLog
end

-- iOS端特殊提示
function UIGameSettingView:UpdateInfo_iOS_Keyboard()
    Timer.DelTimer(self, self.nIOSKTimerID)
    self.nIOSKTimerID = Timer.Add(self, 1, function()
        if not Platform.IsIos() then
            UIHelper.SetVisible(self.BtnJoyStickTips, false)
            UIHelper.LayoutDoLayout(self.LayoutBtn)
            return
        end

        if not KeyBoard.MobileHasKeyboard() then
            return
        end

        local szKey = "GameSeting_IOS_Keyboard"
        local szUrl = tUrl.szIosKeyboardHelp

        UIHelper.SetVisible(self.BtnJoyStickTips, true)
        UIHelper.LayoutDoLayout(self.LayoutBtn)

        UIHelper.BindUIEvent(self.BtnJoyStickTips, EventType.OnClick, function()
            UIHelper.OpenWeb(szUrl)
        end)

        if not APIHelper.IsDid(szKey) then
            local dialog = UIHelper.ShowConfirm("检测到您已连接蓝牙设备，\n苹果设备需要额外进行鼠标相关的系统设置方可正常使用", function()
                UIHelper.OpenWeb(szUrl)
            end)
            dialog:SetButtonContent("Confirm", "查看说明")
            APIHelper.Do(szKey)
        end
    end)
end

function UIGameSettingView:GetCurrentCategory()
    return self.szSelectedCategory or SettingCategory.General
end

function UIGameSettingView:UpdateSearch(bExit)
    local szContent = bExit and "" or UIHelper.GetString(self.EditKindSearch)
    szContent = string.upper(szContent)
    if szContent ~= self.szSearchKey then
        self.szSearchKey = szContent

        local tbSearch = {}
        local bFound = false
        local tbIgnoredCategory = {
            [SettingCategory.Version] = 1,
            [SettingCategory.GamepadInteraction] = 1,
            [SettingCategory.ShortcutInteraction] = 1,
        }
        if self.szSearchKey and self.szSearchKey ~= "" then
            for _, szKey in pairs(SettingCategory) do
                if not tbIgnoredCategory[szKey] then
                    local tbMainCategoryList = UIGameSettingConfigTab[szKey]
                    for szSub, tSubList in pairs(tbMainCategoryList) do
                        local szSubTitle = tSubCategory2Title[szSub]
                        if szSubTitle then
                            if string.find(szSubTitle, self.szSearchKey) then
                                tbSearch[szKey] = tbSearch[szKey] or {}
                                tbSearch[szKey][szSub] = clone(tSubList)
                                bFound = true
                            else
                                for _, tInfo in ipairs(tSubList) do
                                    if tInfo.szName and string.find(tInfo.szName, self.szSearchKey)
                                            and (not tInfo.fnVisible or tInfo.fnVisible()) then
                                        tbSearch[szKey] = tbSearch[szKey] or {}
                                        tbSearch[szKey][szSub] = tbSearch[szKey][szSub] or {}
                                        table.insert(tbSearch[szKey][szSub], tInfo)
                                        bFound = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        UIHelper.SetVisible(self.WidgetEmpty, self.szSearchKey ~= "" and not bFound)
        self.tbSearchingUIGameConfig = self.szSearchKey == "" and self.tbTempTotalGameConfig or tbSearch
        self.bSearchState = bFound
        if bFound then
            self.szSelectedCategory = nil
        end

        self:ResetContent()
        self:ClearScrollView()
        self:InitLeftTabTree(self.szSelectedCategory)
    end
end

function UIGameSettingView:UpdateWordBlockInfo()
    UIHelper.SetVisible(self.WidgetAnchorProhibitWord, true)
    UIHelper.SetVisible(self.WidgetNormal, false)

    self.scriptWordBlock = self.scriptWordBlock or UIHelper.AddPrefab(PREFAB_ID.WidgetSettingProhibitWord, self.WidgetAnchorProhibitWord)
end

function UIGameSettingView:_shortcutChildVisibleCheck(nSubIndex)
    local bVisible = true

    local tShortCutCfg = UIShortcutInteractionTab[nSubIndex]
    if tShortCutCfg then
        if not table.is_empty(tShortCutCfg.tbDisplayCheckFunc) then
            for k, szCondition in ipairs(tShortCutCfg.tbDisplayCheckFunc) do
                if not string.is_nil(szCondition) then
                    if not string.execute(szCondition) then
                        bVisible = false
                        break
                    end
                end
            end
        end
    end

    return bVisible
end

return UIGameSettingView