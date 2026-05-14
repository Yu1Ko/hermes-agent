ShortcutInteractionData = { className = "ShortcutInteractionData" }
local self = ShortcutInteractionData
local DX_COMMON_SLOT_1 = 1001


-- 这个值是开启界面预制的ID描述
ShortcutInteractionData.IsEnableVisibleMode = false --true或false，为true时会显示槽位id
ShortcutInteractionData.IsEnableKeyBoard = true;
ShortcutInteractionData.IsReset = false
ShortcutInteractionData.IsSync = false
ShortcutInteractionData.tbIgnoreOnDisable = { "Esc" }
ShortcutInteractionData.SHORTCUT_FREQ = 500 -- 按键频率 单位（毫秒）
ShortcutInteractionData.tbOccupyKeyCodes = {
    Menu = {},
    Hotkey = {},
    Action = {},
}
-- 快捷交互按鍵状态
-- 状态切换时，更新按键
SHORTCUT_KEY_BOARD_STATE = {
    Common = 0, --共用
    Normal = 1,
    Fight = 2,
    Meditation = 3,
    Riding = 4,
    Sprint = 5,
    SimpleNormal = 6,
    SimpleSprint = 7,
    SimpleRiding = 8,
    Artist = 9,
    DXFight = 10,
}
-- 快捷交互按键类型 在ShortcutInteractionData._refreshActionKeyboardBind用于绑定快捷键
SHORTCUT_KEY_BOARD_TYPE = {
    SwitchSkill = 10, --切换技能

    SkillSlot1 = 11, --技能槽位1按键
    SkillSlot2 = 12, --技能槽位2按键
    SkillSlot3 = 13, --技能槽位3按键
    SkillSlot4 = 14, --技能槽位4按键
    SkillSlot5 = 15, --技能槽位5按键
    SkillSlot6 = 16, --技能槽位6按键
    SkillSlot7 = 17, --技能槽位7按键
    SkillSlot8 = 18, --技能槽位8按键
    SkillSlot9 = 19, --技能槽位9按键

    AutoForward = 20, --自动前进
    Meditation = 21, --打坐
    Riding = 22, --骑马
    Jump = 23, --跳跃
    Roll = 24, --滑翔，聂云
    Picker = 25, --单个拾取/交互
    ALLPicker = 26, --全部拾取
    Target = 27, --目标选择
    Sprint = 28, --轻功
    FuYao = 29, --扶摇
    SpecialSprint = 30, --门派轻功
    SkillAuto = 31, --助手
    Transfer = 32, --神行
    SkillQuick = 33, --技能快捷使用
    SkillSlot11 = 34, --动态技能栏额外槽位
    LockTarget = 201, --目标锁定

    ActionBar1 = 101, --快捷栏槽位1
    ActionBar2 = 102, --快捷栏槽位2
    ActionBar3 = 103, --快捷栏槽位3
    ActionBar4 = 104, --快捷栏槽位4
    ActionBar5 = 105, --快捷栏槽位5
    ActionBar6 = 106, --快捷栏槽位6
    ActionBar7 = 107, --快捷栏槽位7
    ActionBar8 = 108, --快捷栏槽位8
    ActionBar9 = 109, --快捷栏槽位9
    ActionBar10 = 110, --快捷栏槽位10
    ActionBarSwitch = 111, --快捷栏分页切换

    DXSkillSlot1 = 40,
    DXSkillSlot2 = 41,
    DXSkillSlot3 = 42,
    DXSkillSlot4 = 43,
    DXSkillSlot5 = 44,
    DXSkillSlot6 = 45,
    DXSkillSlot7 = 46,
    DXSkillSlot8 = 47,
    DXSkillSlot9 = 48,
    DXSkillSlot10 = 49,
    DXSkillSlot11 = 50,
    DXSkillSlot12 = 51,
    DXSkillSlot13 = 52,
    DXSkillSlot14 = 53,
    DXSkillSlot15 = 54,
    DXSkillSlot16 = 55,
    DXSkillSlot17 = 56,
    DXSkillSlot18 = 57,
    DXSkillSlot19 = 58,
    DXSkillSlot20 = 59,
    DXSkillSlot21 = 60,
    DXSkillSlot22 = 61,
    DXSkillSlot23 = 62,
    DXSkillSlot24 = 63,
    DXSkillSlot25 = 64,

    DXSkillHouChe = 65,
    DXSkillJump = 66,
    DXSkillFuYao = 67,
    DXSkillSlotNieYun = 68,
    DXSkillLingXiao = 69,
    DXSkillYaoTai = 70,
    DXSkillYingFeng = 71,

    DXSkillSlotQuickUse = 72,
    DXSkillSlotQuickMark = 73,

    DXBtnTargetLock = 84,
    --DXWidgetTargetSelect = 85,
    DXWidgetSwitchPage = 86,
    DXWidgetSkillAuto = 87,
    DXSkillQuickUse = 88,

    DXSkillSpecial1 = 300, --特殊技能槽位1
    DXSkillSpecial2 = 301, --特殊技能槽位2
    DXSkillSpecial3 = 302, --特殊技能槽位3
    DXSkillSpecial4 = 303, --特殊技能槽位4
    DXSkillSpecial5 = 304, --特殊技能槽位5
    DXSkillSpecial6 = 305, --特殊技能槽位6
    DXSkillSpecial7 = 306, --特殊技能槽位7
    DXSkillSpecial8 = 307, --特殊技能槽位8
    DXSkillSpecial9 = 308, --特殊技能槽位9
    DXSkillSpecial10 = 309, --特殊技能槽位10
    DXSkillSpecial11 = 310, --特殊技能槽位11
    DXSkillSpecial12 = 311, --特殊技能槽位12
    DXSkillSpecial13 = 312, --特殊技能槽位13
    DXSkillSpecial14 = 313, --特殊技能槽位14
    DXSkillSpecial15 = 314, --特殊技能槽位15
    DXSkillSpecial16 = 315, --特殊技能槽位16
}
local tbCanHideShortcutLabel = {
    PREFAB_ID.WidgetRightBottonFunction,
    PREFAB_ID.WidgetRightBottonFunctionDX,
    PREFAB_ID.WidgetSkillPanel,
    PREFAB_ID.WidgetSkillPanelDX,
    PREFAB_ID.WidgetJiangHuBaiTaiButton
}
-- 快捷键预制ID映射
-- 界面加载后会遍历节点底下挂靠有<UIShortcutInteraction>脚本的节点，然后依次按顺序填充ID
local SHORTCUT_PREFAB_ID_MAP = {
    VIEW = {
        [VIEW_ID.PanelMainCity] =
        {
            --["WidgetQuickUse"] = 20,
        },
        [VIEW_ID.PanelMainCityInteractive] =
        {
            ["BtnGetAll2"] = 21,
            ["WidgetInteractive1"] = 20,
            -- ["WidgetInteractive2"] = 20, --只在第一个交互按钮旁边显示快捷键
            -- ["WidgetInteractive3"] = 20,
            -- ["WidgetInteractive4"] = 20,
            ["BtnGetAll"] = 21,
        },
    },
    PREFAB = {
        --@ PREFAB_ID or VIEW_ID
        [PREFAB_ID.WidgetRightBottonFunction] =
        {
            ["FunctionSlot1"] = 1,
            ["FunctionSlot2"] = 2,
            ["FunctionSlot3"] = 3,
            ["FunctionSlot4"] = 4,
            ["FunctionSlot5"] = 5,
            ["FunctionSlot6"] = 6,
            ["FunctionSlot7"] = 7,
            ["FunctionSlot8"] = 8,
            ["FunctionSlot9"] = 9,
        },
        [PREFAB_ID.WidgetRightBottonFunctionDX] =
        {
            ["FunctionSlot1"] = DX_COMMON_SLOT_1,
            ["FunctionSlot2"] = 2,
            ["FunctionSlot3"] = 3,
            ["FunctionSlot4"] = 4,
            ["FunctionSlot5"] = 5,
            ["FunctionSlot6"] = 6,
            ["FunctionSlot7"] = 7,
            ["FunctionSlot8"] = 8,
            ["FunctionSlot9"] = 9,
        },
        [PREFAB_ID.WidgetSkillPanel] =
        {
            ["WidgetChange"] = 10,
            ["SkillSlot1"] = 11,
            ["SkillSlot2"] = 12,
            ["SkillSlot3"] = 13,
            ["SkillSlot4"] = 14,
            ["SkillSlot5"] = 15,
            ["SkillSlot6"] = 16,
            ["SkillSlot7"] = 22,
            ["SkillSlot8"] = 17,
            ["SkillSlot9"] = 24,
            ["SkillSlot11"] = 25,
            ["SkillSlot12"] = 23,
            ["SkillSlotQuickUse"] = 23,
            ["SkillSlotQuickMark"] = 23,
            ["WidgetSkillRoll"] = 18,
            ["WidgetTargetSelect"] = 19,
            ["WidgetQuickUse"] = 20,
            ["WidgetSkillAuto"] = 30,
            ["BtnTargetLock"] = 201,
        },

        [PREFAB_ID.WidgetSkillPanelDX] =
        {
            ["SkillSlot1"] = 50,
            ["SkillSlot2"] = 51,
            ["SkillSlot3"] = 52,
            ["SkillSlot4"] = 53,
            ["SkillSlot5"] = 54,
            ["SkillSlot6"] = 55,
            ["SkillSlot7"] = 56,
            ["SkillSlot8"] = 57,
            ["SkillSlot9"] = 58,
            ["SkillSlot10"] = 59,
            ["SkillSlot11"] = 60,
            ["SkillSlot12"] = 61,
            ["SkillSlot13"] = 62,
            ["SkillSlot14"] = 63,
            ["SkillSlot15"] = 64,
            ["SkillSlot16"] = 65,
            ["SkillSlot17"] = 66,
            ["SkillSlot18"] = 67,
            ["SkillSlot19"] = 68,
            ["SkillSlot20"] = 69,
            ["SkillSlot21"] = 70,
            ["SkillSlot22"] = 71,
            ["SkillSlot23"] = 72,
            ["SkillSlot24"] = 73,
            ["SkillSlot25"] = 74,
            --["SkillSlot26"] = 75,
            --["SkillSlot27"] = 76,
            --["SkillSlot28"] = 77, -- 轻功技能会动态更改这个ID 此处不需要设置
            ["SkillSlotCombine29"] = 78,

            --["SkillSlotQuickMark"] = 80,

            ["WidgetChange"] = 10,
            ["WidgetTargetSelect"] = 19,
            ["WidgetSkillAuto"] = 114,
            ["BtnTargetLock"] = 201,
            ["WidgetSwitchPage"] = 113,
            ["SkillSlotQuickUse"] = 116,
        },

        [PREFAB_ID.WidgetInteractive] =
        {
            -- ["BtnInteractive"] = 20,
        },
        [PREFAB_ID.WidgetJiangHuBaiTaiButton] =
        {
            ["FunctionSlot1"] = 40,
            ["FunctionSlot2"] = 41,
            ["FunctionSlot3"] = 42,
            ["FunctionSlot4"] = 43,
            ["FunctionSlot5"] = 44,
            ["FunctionSlot6"] = 45,
            ["FunctionSlot7"] = 46,
            ["FunctionSlot8"] = 47,
            ["FunctionSlot9"] = 48,
            ["FunctionSlot10"] = 49
        },
    }
}

-- 特殊符号转化
local SHORTCUT_KEY_BOARD_SPECIAL_NAME = {
    ["OEM1"] = ";",
    ["OEM2"] = "/",
    ["OEM3"] = "~",
    ["OEMPlus"] = "=",
    ["OEMMinus"] = "-",
    ["OEMComma"] = ",",
    ["OEMPeriod"] = "。",
    ["Space"] = "空格",
    ["Backspace"] = "退格",
}

-- 简化快捷键显示
local SHORTCUT_KEY_BOARD_SIMPLIFY_NAME = {
    ["Backspace"] = "Bs",
    ["Ctrl"] = "C",
    ["Shift"] = "S",
    ["Alt"] = "A",
    ["Pause"] = "Pa",
    ["CapLock"] = "CL",
    ["PageUp"] = "PU",
    ["PageDown"] = "PD",
    ["PrintScreen"] = "PS",
    ["NumLock"] = "NL",
    ["ScrollLock"] = "SL",
    ["Insert"] = "Ins",
    ["Delete"] = "Del",

    ["LButton"] = "LB",
    ["RButton"] = "RB",
    ["MButton"] = "MB",
    ["XButton1"] = "XB1",
    ["XButton2"] = "XB2",
    ["MouseWheelUp"] = "MU",
    ["MouseWheelDown"] = "MD",
}

local SHORTCUT_KEY_ICON = {
    [SHORTCUT_ICON_TYPE.MAINCITY] = {
        ["LButton"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mouseleftclick",
        ["RButton"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mouserightclick",
        ["MButton"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mousewheelclick",
        ["XButton1"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mouseside1",
        ["XButton2"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mouseside2",
        ["MouseWheelUp"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mousewheelup",
        ["MouseWheelDown"] = "UIAtlas2_GameSetting_JoyStick_MainCityMouse_mousewheeldown",
    },
    [SHORTCUT_ICON_TYPE.SETTING] = {
        ["LButton"] = "UIAtlas2_GameSetting_JoyStick_PC_mouseleftclick",
        ["RButton"] = "UIAtlas2_GameSetting_JoyStick_PC_mouserightclick",
        ["MButton"] = "UIAtlas2_GameSetting_JoyStick_PC_mousewheelclick",
        ["XButton1"] = "UIAtlas2_GameSetting_JoyStick_PC_mouseside1",
        ["XButton2"] = "UIAtlas2_GameSetting_JoyStick_PC_mouseside2",
        ["MouseWheelUp"] = "UIAtlas2_GameSetting_JoyStick_PC_mousewheelup",
        ["MouseWheelDown"] = "UIAtlas2_GameSetting_JoyStick_PC_mousewheeldown",
    },
}

local SHORTCUT_KEY_FUNCTION_NAME = {
    Jump = "跳跃",
    SwitchFightMode = "攻击", --切换战斗/非战斗状态
    Roll = "蹑云",
    Action = "", --交互
    AllItemGet = "", --全部拾取
    Target = "", --选中目标
    skill0 = "",
    skill1 = "",
    skill2 = "",
    skill3 = "",
    skill4 = "",
    skill5 = "",
    skill7 = "",
    skill8 = "",
    skill9 = "",
    skill10 = "",
    FuYao = "扶摇",
    SkillAuto = "助手",
    SkillQuick = "",
    -- 自定义添加
}

ShortcutInteractionData.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Normal
ShortcutInteractionData.tbKeyboardUpVKNames = {}
ShortcutInteractionData.szLastKeyboardName = ""
SHORTCUT_INTERACTION = {
    --[按键状态KEY] =
    --{
    --      @ [快捷键槽位ID（对应SHORTCUT_PREFAB_ID_MAP 中的ID）] = {
    --        nType = 交互类型：SHORTCUT_KEY_BOARD_TYPE
    --        szVKName = 按键名称：UIShortcutInteractionTab中配置
    --        szFuncName = 功能名：可以不填写，由孔位功能传递
    --        interactionFunction = 按键触发事件
    --      }
    --}
    [SHORTCUT_KEY_BOARD_STATE.Common] = -- 共用快捷键
    {
        [-1] = nil, --空状态
        [20] = { nType = SHORTCUT_KEY_BOARD_TYPE.Picker, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Action, interactionFunction = "FastSceneInteract" }, --交互事件，单个物品拾取/任务/对话
        [21] = { nType = SHORTCUT_KEY_BOARD_TYPE.ALLPicker, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.AllItemGet, interactionFunction = "AllFastPick" }, --全部拾取
        [23] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillQuick, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillQuick, interactionFunction = "SkillQuick" }, --特殊道具/团队标记

        [101] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar1, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_1", bHide = false, nIconSize = 46 },
        [102] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar2, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_2", bHide = false, nIconSize = 46 },
        [103] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar3, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_3", bHide = false, nIconSize = 46 },
        [104] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar4, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_4", bHide = false, nIconSize = 46 },
        [105] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar5, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_5", bHide = false, nIconSize = 46 },
        [106] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar6, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_6", bHide = false, nIconSize = 46 },
        [107] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar7, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_7", bHide = false, nIconSize = 46 },
        [108] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar8, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_8", bHide = false, nIconSize = 46 },
        [109] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar9, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_9", bHide = false, nIconSize = 46 },
        [110] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBar10, szVKName = "", szFuncName = "", interactionFunction = "ActionBarSlot_10", bHide = false, nIconSize = 46 },
        [111] = { nType = SHORTCUT_KEY_BOARD_TYPE.ActionBarSwitch, szVKName = "", szFuncName = "", interactionFunction = "TargetLockFunc", bHide = false, nIconSize = 46 },

        [116] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillQuickUse, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillQuick, interactionFunction = "SkillQuick" }, --特殊道具/团队标记
        [201] = { nType = SHORTCUT_KEY_BOARD_TYPE.LockTarget, szVKName = "", szFuncName = "", interactionFunction = "TargetLockFunc", bHide = true },
    },
    [SHORTCUT_KEY_BOARD_STATE.Normal] = -- 普通状态
    {
        [1] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "AttackClicked" }, --攻击
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" }, --打坐
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.Transfer, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" }, --神行
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" }, --骑马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" }, --轻功
        [10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "SwitchSkill" }, --切换状态显示

        [12] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill1, interactionFunction = "Fight" }, --槽位1技能
        [13] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill2, interactionFunction = "Fight" }, --槽位2技能
        [14] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill3, interactionFunction = "Fight" }, --槽位3技能
        [15] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill4, interactionFunction = "Fight" }, --槽位4技能
        [16] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill5, interactionFunction = "Fight" }, --槽位5技能
        --[25] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot11, szVKName = "", szFuncName = "", interactionFunction = "Fight" }, --槽位11技能

        [18] = { nType = SHORTCUT_KEY_BOARD_TYPE.Roll, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Roll, interactionFunction = "" }, --蹑云逐月，滑翔
        [19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" }, --选中目标
        [22] = { nType = SHORTCUT_KEY_BOARD_TYPE.SpecialSprint, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill7, interactionFunction = "" }, --门派轻功
        [17] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "" }, --跳跃
        [24] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" }, --扶摇
        [30] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }, --助手

        [DX_COMMON_SLOT_1] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "AttackClicked" }, --攻击

    },
    [SHORTCUT_KEY_BOARD_STATE.Fight] = -- 战斗状态
    {
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "Meditation" }, --打坐
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.Transfer, szVKName = "", szFuncName = "", interactionFunction = "Transfer" }, --神行
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "RideHorse" }, --骑马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "StartSprint" }, --轻功
        [10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "SwitchSkill" }, --切换状态显示
        [11] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill0, interactionFunction = "MainViewBtnFuncSlot_1" }, --普攻
        [12] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill1, interactionFunction = "MainViewBtnFuncSlot_2" }, --槽位1技能
        [13] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill2, interactionFunction = "MainViewBtnFuncSlot_3" }, --槽位2技能
        [14] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill3, interactionFunction = "MainViewBtnFuncSlot_4" }, --槽位3技能
        [15] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill4, interactionFunction = "MainViewBtnFuncSlot_5" }, --槽位4技能
        [16] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill5, interactionFunction = "MainViewBtnFuncSlot_6" }, --槽位5技能
        [25] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot11, szVKName = "", szFuncName = "", interactionFunction = "SkillSlot_11" }, --槽位11技能
        [19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" }, --选中目标

        [18] = { nType = SHORTCUT_KEY_BOARD_TYPE.Roll, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Roll, interactionFunction = "" }, --蹑云逐月，滑翔
        [22] = { nType = SHORTCUT_KEY_BOARD_TYPE.SpecialSprint, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill7, interactionFunction = "" }, --门派轻功
        [17] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "" }, --跳跃
        [24] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" }, --扶摇
        [30] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }, --助手
    },
    [SHORTCUT_KEY_BOARD_STATE.Meditation] = -- 打坐状态
    {
        [1] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" }, --打坐起身
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" }, --传功

        [DX_COMMON_SLOT_1] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" }, --攻击
    },
    [SHORTCUT_KEY_BOARD_STATE.Riding] = -- 骑行状态
    {
        [1] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" }, --攻击
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" },
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" },
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" }, --下马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" }, --轻功
        [10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "SwitchSkill" }, --切换状态显示

        -- 2-双人同骑，3-下马牵行，不切换到技能页面
        [14] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill3, interactionFunction = "Fight" }, --槽位3技能
        [15] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill4, interactionFunction = "Fight" }, --槽位4技能
        [16] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill5, interactionFunction = "Fight" }, --槽位5技能

        [17] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "SkillJump" }, --跳跃
        [19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" }, --选中目标
        [24] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" }, --扶摇
        [30] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }, --助手

        [DX_COMMON_SLOT_1] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "MainViewBtnFuncSlot_1" }, --攻击
    },
    [SHORTCUT_KEY_BOARD_STATE.Sprint] = -- 轻功状态，由轻功模块自动设置对应键位
    {
        [1] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" },
        [2] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" },
        [3] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" },
        [4] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" },
        [5] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" },
        [6] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_6" },
        [7] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_7" },
        [8] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_8" },
        [9] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_9" },

        [DX_COMMON_SLOT_1] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" },
    },
    [SHORTCUT_KEY_BOARD_STATE.SimpleNormal] = -- 普通状态(简化轻功)
    {
        [1] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "AttackClicked" }, --攻击
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" }, --打坐
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.Transfer, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" }, --神行
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" }, --骑马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" }, --轻功
        [10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction="SwitchSkill"}, --切换状态显示

        [12] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill1, interactionFunction = "Fight" }, --槽位1技能
        [13] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill2, interactionFunction = "Fight" }, --槽位2技能
        [14] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill3, interactionFunction = "Fight" }, --槽位3技能
        [15] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill4, interactionFunction = "Fight" }, --槽位4技能
        [16] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill5, interactionFunction = "Fight" }, --槽位5技能

        [18] = { nType = SHORTCUT_KEY_BOARD_TYPE.Roll, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Roll, interactionFunction = "" }, --蹑云逐月，滑翔
        [19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" }, --选中目标
        [22] = { nType = SHORTCUT_KEY_BOARD_TYPE.SpecialSprint, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill7, interactionFunction = "" }, --门派轻功
        [17] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "" }, --跳跃
        [24] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" }, --扶摇
        [30] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }, --助手

        -- DX轻功技能槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 75~81  112~115

        [DX_COMMON_SLOT_1] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "AttackClicked" }, --攻击
    },
    [SHORTCUT_KEY_BOARD_STATE.SimpleSprint] = -- 简化轻功状态，由轻功模块自动设置对应键位
    {
        [1] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" },
        [2] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" },
        [3] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" },
        [4] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" },
        [5] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" },
        [6] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_6" },
        [7] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_7" },
        [8] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_8" },
        [9] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_9" },

        [DX_COMMON_SLOT_1] = { nType = nil, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" },
    },
    [SHORTCUT_KEY_BOARD_STATE.SimpleRiding] = -- 骑行状态(简化轻功)
    {
        [1] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_1" },
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_2" },
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_3" },
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_4" }, --下马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "MainViewBtnFuncSlot_5" }, --轻功
        [10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "SwitchSkill" }, --切换状态显示

        -- 2-双人同骑，3-下马牵行，不切换到技能页面
        [14] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill3, interactionFunction = "Fight" }, --槽位3技能
        [15] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill4, interactionFunction = "Fight" }, --槽位4技能
        [16] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.skill5, interactionFunction = "Fight" }, --槽位5技能

        [17] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "SkillJump" }, --跳跃
        [19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" }, --选中目标
        [24] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" }, --扶摇
        [30] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }, --助手

        [DX_COMMON_SLOT_1] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlot1, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "MainViewBtnFuncSlot_1" }, --攻击
    },

    [SHORTCUT_KEY_BOARD_STATE.Artist] = --艺人身份舞蹈状态
    {
        [40] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot1, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_1" },
        [41] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot2, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_2" },
        [42] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot3, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_3" },
        [43] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot4, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_4" },
        [44] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot5, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_5" },
        [45] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillSlot6, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_6" },
        [46] = { nType = SHORTCUT_KEY_BOARD_TYPE.SpecialSprint, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_7" },
        [47] = { nType = SHORTCUT_KEY_BOARD_TYPE.FuYao, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_8" },
        [48] = { nType = SHORTCUT_KEY_BOARD_TYPE.SkillAuto, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_9" },
        [49] = { nType = SHORTCUT_KEY_BOARD_TYPE.Jump, szVKName = "", szFuncName = "", interactionFunction = "ArtistIdentityFuncSlot_10" },
    },
    [SHORTCUT_KEY_BOARD_STATE.DXFight] = --旗舰武学战斗状态
    {
        [2] = { nType = SHORTCUT_KEY_BOARD_TYPE.Meditation, szVKName = "", szFuncName = "", interactionFunction = "Meditation" }, --打坐
        [3] = { nType = SHORTCUT_KEY_BOARD_TYPE.Transfer, szVKName = "", szFuncName = "", interactionFunction = "Transfer" }, --神行
        [4] = { nType = SHORTCUT_KEY_BOARD_TYPE.Riding, szVKName = "", szFuncName = "", interactionFunction = "RideHorse" }, --骑马
        [5] = { nType = SHORTCUT_KEY_BOARD_TYPE.Sprint, szVKName = "Shift", szFuncName = "", interactionFunction = "StartSprint" }, --轻功

        -- DX战斗技能槽位 1~25为非轻功槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 50~74
        -- DX轻功技能槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 75~81

        [113] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXWidgetSwitchPage, szVKName = "", szFuncName = "", interactionFunction = "SwitchPageSkill" },
    }
    -- 往下加
}

DX_SKILL_SHORTCUT_EVENT = "DXMainViewBtnFuncSlot_"
DX_DAOZONG_EVENT = "DX_DAOZONG_EVENT"

do
    -- 设置DX战斗技能槽位 1~25为非轻功槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 50~74
    local nStartIndex = 49
    for i = 1, 25, 1 do
        --[50] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlot1, szVKName = "", szFuncName = "", interactionFunction = "DXMainViewBtnFuncSlot_1" },
        SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.DXFight][nStartIndex + i] = {
            nType = SHORTCUT_KEY_BOARD_TYPE["DXSkillSlot" .. i], szVKName = "", szFuncName = "", interactionFunction = DX_SKILL_SHORTCUT_EVENT .. i
        }
    end

    -- 设置DX轮盘技能槽位 120~135
    local nSpecialStartIndex = 119
    for i = 1, 16, 1 do
        SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.DXFight][nSpecialStartIndex + i] = {
            nType = SHORTCUT_KEY_BOARD_TYPE["DXSkillSpecial" .. i], szVKName = "", szFuncName = "", interactionFunction = ""
        }
    end

    -- 设置DX轻功技能槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 75~81  112~115
    local tCategories = { SHORTCUT_KEY_BOARD_STATE.DXFight, SHORTCUT_KEY_BOARD_STATE.Normal, SHORTCUT_KEY_BOARD_STATE.SimpleNormal,
                          SHORTCUT_KEY_BOARD_STATE.Riding, SHORTCUT_KEY_BOARD_STATE.SimpleRiding}
    for _, nCategory in ipairs(tCategories) do
        local tData = SHORTCUT_INTERACTION[nCategory]
        tData[75] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillHouChe, szVKName = "", szFuncName = "", interactionFunction = "" } --后撤
        tData[77] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillFuYao, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.FuYao, interactionFunction = "" } --扶摇
        tData[78] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillSlotNieYun, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Roll, interactionFunction = "" } --聂云
        tData[79] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillLingXiao, szVKName = "", szFuncName = "", interactionFunction = "" } --凌霄揽胜
        tData[80] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillYaoTai, szVKName = "", szFuncName = "", interactionFunction = "" } --瑶台枕鹤
        tData[81] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillYingFeng, szVKName = "", szFuncName = "", interactionFunction = "" } --迎风回浪
    end

    -- 设置DX通用槽位 占用SHORTCUT_KEY_BOARD_STATE.DXFight中的下标 76 112~115
    local tCategories = { SHORTCUT_KEY_BOARD_STATE.DXFight, SHORTCUT_KEY_BOARD_STATE.Normal, SHORTCUT_KEY_BOARD_STATE.SimpleNormal,
                          SHORTCUT_KEY_BOARD_STATE.SimpleRiding, SHORTCUT_KEY_BOARD_STATE.Riding }
    for _, nCategory in ipairs(tCategories) do
        local tData = SHORTCUT_INTERACTION[nCategory]
        tData[76] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXSkillJump, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Jump, interactionFunction = "SkillJump" } --DX跳跃

        tData[10] = { nType = SHORTCUT_KEY_BOARD_TYPE.SwitchSkill, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SwitchFightMode, interactionFunction = "SwitchSkill" } --切换状态显示
        tData[19] = { nType = SHORTCUT_KEY_BOARD_TYPE.Target, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.Target, interactionFunction = "TargetSelect" } --选中目标
        tData[114] = { nType = SHORTCUT_KEY_BOARD_TYPE.DXWidgetSkillAuto, szVKName = "", szFuncName = SHORTCUT_KEY_FUNCTION_NAME.SkillAuto, interactionFunction = "SkillAuto" }   --DX武学助手
    end
end

function ShortcutInteractionData.Init()
    --进入/离开战斗状态
    Event.Reg(self, EventType.OnSprintFightStateChanged, function(bSprint)
        local player = GetClientPlayer()
        if not player then
            return
        end

        local bCanCastSkill = QTEMgr.CanCastSkill()
        local bShowSkill = (not bCanCastSkill) or (bCanCastSkill and not bSprint)

        if bShowSkill then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Fight
            if SkillData.IsUsingHDKungFu() then
                self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.DXFight
            end
        else
            local bSprintFlag = SprintData.GetSprintState()
            local bAutoFly = player.nMoveState == MOVE_STATE.ON_AUTO_FLY or player.nMoveState == MOVE_STATE.ON_START_AUTO_FLY
            --玩家实际切换到轻功状态再刷新标签显示，否则会导致跳跃闪避等按钮标签与按钮本身的显隐不同步
            if bSprintFlag or bAutoFly then
                self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Sprint
            elseif player.bOnHorse then
                self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Riding
            elseif player.nMoveState == MOVE_STATE.ON_SIT then
                self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Meditation
            else
                self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Normal
            end
            self.CheckSettingSprintMode()
            self._updateActionOccupyKeys()
        end

        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        if self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Fight or self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.DXFight then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end
        local bSprintFlag = SprintData.GetSprintState()
        local bAutoFly = player.nMoveState == MOVE_STATE.ON_AUTO_FLY or player.nMoveState == MOVE_STATE.ON_START_AUTO_FLY
        if bSprintFlag and tbAction or bAutoFly then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Sprint
        elseif player.bOnHorse then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Riding
        elseif player.nMoveState == MOVE_STATE.ON_SIT then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Meditation
        else
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Normal
        end

        self.CheckSettingSprintMode()
        self._updateActionOccupyKeys()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, "ON_PLAYER_JUMP", function()
        if self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Meditation then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Normal
            Event.Dispatch(EventType.OnShortcutInteractionChange)
        end
    end)

    Event.Reg(self, "ON_OPEN_ARTIST_SKILLPANEL", function()
        self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Artist
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        self.tbServerShortcutSetting = {}
    end)

    Event.Reg(self, EventType.OnGameSettingsKeyboardChange, function(nShortcutID, szOldKey, szNewKey)
        local settingInfo = UISettingStoreTab.ShortcutInteraction[nShortcutID]
        if settingInfo then
            --@"Menu"   = 菜单功能
            --@"Hotkey" = 全局热键
            --@"Action" = 右下角按钮交互
            --@"OSBind" = 系统绑定
            if settingInfo.szType =="Menu" then
                self._refreshMenuKeyboardBind(tonumber(settingInfo.paramArgs), szNewKey)
                self._updateMenuOccupyKeys(szOldKey, szNewKey)
            elseif settingInfo.szType == "Hotkey" then
                self._refreshHotkeyKeyboardBind(tonumber(settingInfo.paramArgs), szNewKey)
                self._updateHotkeyOccupyKeys(szOldKey, szNewKey)
            elseif settingInfo.szType == "Action" then
                self._refreshActionKeyboardBind(settingInfo.paramArgs, szNewKey)
                self._updateActionOccupyKeys()
                if not self.IsReset and not self.IsSync then
                    Event.Dispatch(EventType.OnShortcutInteractionChange)
                end
            elseif settingInfo.szType == "OSBind" then
                self._refreshOsKeyboardBind(settingInfo.paramArgs, szOldKey, szNewKey)
            end

            --服务器存盘
            --NOTE：注意OnGameSettingsKeyboardChange事件要在实际修改UISettingStoreTab.ShortcutInteraction表之前调用，
            --      否则self.IsServerShortcutSettingNeedUpdate()会永远返回true
            if GameSettingData.GetNewValue(UISettingKey.SyncShortcutSetting) and not self.IsServerShortcutSettingNeedUpdate() then
                if settingInfo.szDef and ShortcutDef[settingInfo.szDef] then
                    self.SetServerShortcutSetting(ShortcutDef[settingInfo.szDef], szNewKey)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnGameSettingsGamepadChange, function(nKeyCode, szOldKey, szNewKey)
        local settingInfo = UISettingStoreTab.GamepadInteraction[nKeyCode]
        if settingInfo and settingInfo.nModeState == GamepadMoveMode.Normal then
            self._refreshGamepadKeyboardBind(settingInfo.szDef, szNewKey)
            if not self.IsReset and not self.IsSync then
                Event.Dispatch(EventType.OnShortcutInteractionChange)
            end
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if SHORTCUT_PREFAB_ID_MAP.VIEW[nViewID] then
            -- 如果界面加载拥有，则进行节点遍历解析
            local scriptView = UIMgr.GetViewScript(nViewID)
            for i, v in pairs(SHORTCUT_PREFAB_ID_MAP.VIEW[nViewID]) do
                local cell = UIHelper.FindChildByName(scriptView._rootNode, i)
                if cell then
                    local widgetKeyBoard = UIHelper.FindChildByName(cell, "WidgetKeyBoardKey")
                    if widgetKeyBoard then
                        local script = UIHelper.GetBindScript(widgetKeyBoard)
                        script:SetID(v)
                    end
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnPrefabAdd, function(nPrefabID, scriptView)
        if SHORTCUT_PREFAB_ID_MAP.PREFAB[nPrefabID] then
            local bCanHide = false
            if table.contain_value(tbCanHideShortcutLabel, nPrefabID) then
                bCanHide = true
            end
            -- 如果界面加载拥有，则进行节点遍历解析
            for i, v in pairs(SHORTCUT_PREFAB_ID_MAP.PREFAB[nPrefabID]) do
                local cell = UIHelper.FindChildByName(scriptView._rootNode, i)
                if cell then
                    local widgetKeyBoard = UIHelper.FindChildByName(cell, "WidgetKeyBoardKey")
                    if widgetKeyBoard then
                        local script = UIHelper.GetBindScript(widgetKeyBoard)
                        script:SetID(v, nil, bCanHide)
                    end
                end
            end

            if SelfieData.IsInSelfieView() then
                Event.Dispatch(EventType.OnShortcutInteractionChange)
            end
        end
    end)

    --锁快捷键，教学用
    self.bEnableShortcut = true
    Event.Reg(self, EventType.SetShortcutEnable, function(bEnableShortcut, tbIgnoreShortcutOnDisable)
        self.bEnableShortcut = bEnableShortcut
        self.tbIgnoreShortcutOnDisable = tbIgnoreShortcutOnDisable -- {{Shift}, {Ctrl, G}, ...} etc.
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function (nKeyCode, szVKName)
        self.tbPressedKey = self.tbPressedKey or {} --按下的单键
        self.tbTriggeredKey = self.tbTriggeredKey or {} --按下的单键、{组合键}
        self.tbSwallowSingleKey = self.tbSwallowSingleKey or {}

        if not table.contain_value(self.tbPressedKey, szVKName) then
            table.insert(self.tbPressedKey, szVKName)
        end

        if self.IsEnableKeyBoard and g_pClientPlayer then
            for _, szKey in ipairs(self.tbPressedKey) do
                if self.isAssemblySymbol(szKey) ~= self.isAssemblySymbol(szVKName) then
                    local tbKeyNames = {szVKName, szKey} --组成组合键
                    if self._checkShortcutEnable(tbKeyNames) then
                        if not self._isShortcutTriggered(tbKeyNames) then
                            table.insert(self.tbTriggeredKey, tbKeyNames)
                            -- print_table("addTriggeredKey:" .. szVKName .. "," .. szKey, self.tbTriggeredKey)
                        end
                        local nKeyboardLen = table.get_len(tbKeyNames)
                        -- print("[ShortcutInteractionData] OnShortcutInteractionMultiKeyDown", tbKeyNames[1], tbKeyNames[2])
                        Event.Dispatch(EventType.OnShortcutInteractionMultiKeyDown, tbKeyNames, nKeyboardLen)
                    end
                end
            end

            if self._checkShortcutEnable(szVKName) and not self.CheckSingleKeySwallow(szVKName) then
                if not self._isShortcutTriggered(szVKName) then
                    table.insert(self.tbTriggeredKey, szVKName)
                    -- print_table("addTriggeredKey " .. szVKName, self.tbTriggeredKey)
                end
                --若触发了组合键，则不触发单键
                -- print("[ShortcutInteractionData] OnShortcutInteractionSingleKeyDown", szVKName)
                Event.Dispatch(EventType.OnShortcutInteractionSingleKeyDown, szVKName)
            end
        end
    end)

    -- 监听按下的按键名称
    Event.Reg(self, EventType.OnKeyboardUp, function (nKeyCode, szVKName)
        self.tbPressedKey = self.tbPressedKey or {}
        self.tbTriggeredKey = self.tbTriggeredKey or {}
        self.tbSwallowSingleKey = self.tbSwallowSingleKey or {}

        if self.IsEnableKeyBoard and g_pClientPlayer then
            for _, szKey in ipairs(self.tbPressedKey) do
                if self.isAssemblySymbol(szKey) ~= self.isAssemblySymbol(szVKName) then
                    local tbKeyNames = {szVKName, szKey} --组成组合键
                    local bContains, nIndex = self._isShortcutTriggered(tbKeyNames)
                    if bContains then
                        table.remove(self.tbTriggeredKey, nIndex)
                        -- print_table("removeTriggeredKey:" .. szVKName .. "," .. szKey, self.tbTriggeredKey)
                        if self._checkShortcutEnable(tbKeyNames) then
                            local nKeyboardLen = table.get_len(tbKeyNames)
                            -- print("[ShortcutInteractionData] OnShortcutInteractionMultiKeyUp", tbKeyNames[1], tbKeyNames[2])
                            Event.Dispatch(EventType.OnShortcutInteractionMultiKeyUp, tbKeyNames, nKeyboardLen)
                        end
                    end
                end
            end

            local bContains, nIndex = self._isShortcutTriggered(szVKName)
            if bContains then
                table.remove(self.tbTriggeredKey, nIndex)
                -- print_table("removeTriggeredKey:" .. szVKName, self.tbTriggeredKey)
                if self._checkShortcutEnable(szVKName) and (not self.CheckSingleKeySwallow(szVKName) or self._isSkillShortcutKey(szVKName)) then
                    --若触发了组合键，则不触发单键（除了技能键）
                    -- print("[ShortcutInteractionData] OnShortcutInteractionSingleKeyUp", szVKName)
                    Event.Dispatch(EventType.OnShortcutInteractionSingleKeyUp, szVKName)
                end
            end
        end

        table.remove_value(self.tbPressedKey, szVKName)
        table.remove_value(self.tbSwallowSingleKey, szVKName)
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self.tbPressedKey = {}
        self.tbTriggeredKey = {}
        self.tbSwallowSingleKey = {}
        self._clearHotkeyKeyboardDown()
    end)

    self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.Normal
    self.InitKeyBoardBind()
    self._InitServerShortcutSetting()
end

function ShortcutInteractionData.SwallowSingleKey(tbKeyNames)
    if not IsTable(tbKeyNames) or #tbKeyNames <= 1 then
        return
    end

    self.tbSwallowSingleKey = self.tbSwallowSingleKey or {}

    --若触发了组合键，则不触发单键
    for _, szVKName in pairs(tbKeyNames) do
        if not self.CheckSingleKeySwallow(szVKName) then
            table.insert(self.tbSwallowSingleKey, szVKName)
        end
    end
end

function ShortcutInteractionData.CheckSingleKeySwallow(szVKName)
    return table.contain_value(self.tbSwallowSingleKey, szVKName)
end

function ShortcutInteractionData.isAssemblySymbol(szKey)
    return szKey == "Ctrl" or szKey == "Alt" or szKey == "Shift"
end

function ShortcutInteractionData.UnInit()
    Event.UnRegAll(self)
end

function ShortcutInteractionData.SetEnableKeyBoard(enable)
    if self.IsEnableKeyBoard ~= enable then
        LOG.INFO("ShortcutInteractionData.SetEnableKeyBoard  %s", tostring(enable))
    end
    self.IsEnableKeyBoard = enable
    if enable then
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    else
        self.tbPressedKey = {}
        self.tbTriggeredKey = {}
        self.tbSwallowSingleKey = {}
        self._clearHotkeyKeyboardDown()
    end
end

function ShortcutInteractionData.GetEnableKeyBoard(szKeyCode)
    local bResult = self.IsEnableKeyBoard
    if table.contain_value(self.tbIgnoreOnDisable, szKeyCode) then
        bResult = true
    end
    return bResult
end

function ShortcutInteractionData.SetIsReset(bReset)
    self.IsReset = bReset
end

function ShortcutInteractionData.GetIsReset()
    return self.IsReset
end

function ShortcutInteractionData.GetIsSync()
    return self.IsSync
end

function ShortcutInteractionData.InitKeyBoardBind()
    -- 先绑定基础，在刷新保存的内容
    self._InitMenuKeyBoardBind()
    self._InitHotkeyKeyBoardBind()
    self._InitOsKeyBoardBind()
    self.tbOccupyKeyCodes.Menu = {}
    self.tbOccupyKeyCodes.Hotkey = {}
    self.tbOccupyKeyCodes.Action = {}

    self.tbShortcutInfoMap = {}
    self.tbGamepadInfoMap = {}

    self.tbSkillShortcutInfoMap = {}

    --初始化，跟KeyBoard.Bind相关的先UnBind全部，再Bind，避免UnBind把已经Bind好的解掉了
    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        local nID = tonumber(settingInfo.paramArgs)
        local info
        if settingInfo.szType =="Menu" then
            info = self.tbMenuKeyBoardInfo[nID]
        elseif settingInfo.szType =="Hotkey" then
            info = self.tbHotkeyKeyBoardInfo[nID]
        end

        if info then
            KeyBoard.UnBindKeyDown(info.tbKeyCodes)
        end
    end

    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        if ShortcutDef[settingInfo.szDef] then
            self.tbShortcutInfoMap[ShortcutDef[settingInfo.szDef]] = settingInfo
            if settingInfo.szPlatform ~= "" then
                self.tbSkillShortcutInfoMap[ShortcutDef[settingInfo.szDef]] = settingInfo
            end
        end

        if settingInfo.szType =="Menu" then
            self._refreshMenuKeyboardBind(tonumber(settingInfo.paramArgs), settingInfo.VKey, true)
            table.insert(self.tbOccupyKeyCodes.Menu, settingInfo.VKey)
        elseif settingInfo.szType =="Hotkey" then
            self._refreshHotkeyKeyboardBind(tonumber(settingInfo.paramArgs), settingInfo.VKey, true)
            table.insert(self.tbOccupyKeyCodes.Hotkey, settingInfo.VKey)
        elseif settingInfo.szType == "Action" then
            self._refreshActionKeyboardBind(settingInfo.paramArgs, settingInfo.VKey)
            table.insert(self.tbOccupyKeyCodes.Action, settingInfo.VKey)
        end
    end

    for k, settingInfo in pairs(UISettingStoreTab.GamepadInteraction) do
        if GamepadDef[settingInfo.szDef] then
            self.tbGamepadInfoMap[GamepadDef[settingInfo.szDef]] = settingInfo
        end

        if settingInfo.nModeState == GamepadMoveMode.Normal then
            self._refreshGamepadKeyboardBind(settingInfo.szDef, settingInfo.VKey)
        end
    end
end

local _TYPE_MOVE_DIRECTION_MAP = {} --Key:MOVE_DIRECTION_KEY_TYPE, Value: szKeyName

local _KEY_MOVE_DIRECTION_MAP = {} --Key:szKeyName, Value: MOVE_DIRECTION_KEY_TYPE

function ShortcutInteractionData._InitOsKeyBoardBind()
    for k, v in pairs(MOVE_DIRECTION_KEY_TYPE) do
        _TYPE_MOVE_DIRECTION_MAP[v] = ""
    end

    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        if settingInfo.szType == "OSBind" then
            _TYPE_MOVE_DIRECTION_MAP[settingInfo.paramArgs] = settingInfo.VKey
            _KEY_MOVE_DIRECTION_MAP[settingInfo.VKey] = settingInfo.paramArgs
        end
    end
end

---@return string|nil MOVE_DIRECTION_KEY_TYPE.XXX
function ShortcutInteractionData.GetDirectionKeyJoyStickType(szDirectionKey)
   if self._checkOccupy(szDirectionKey) then
        return nil
   end
   return _KEY_MOVE_DIRECTION_MAP[szDirectionKey]
end

function ShortcutInteractionData.IsMoveKey(szDirectionKey)
    return _KEY_MOVE_DIRECTION_MAP[szDirectionKey] and not self.IsJumpKey(szDirectionKey)
end

function ShortcutInteractionData.IsMoveLeftOrRightKey(szDirectionKey)
    if _KEY_MOVE_DIRECTION_MAP[szDirectionKey] and
       (_KEY_MOVE_DIRECTION_MAP[szDirectionKey] == MOVE_DIRECTION_KEY_TYPE.MoveLeft or
        _KEY_MOVE_DIRECTION_MAP[szDirectionKey] == MOVE_DIRECTION_KEY_TYPE.MoveRight) then
        return true
    end
    return false
end

function ShortcutInteractionData.IsJumpKey(szDirectionKey)
    if _KEY_MOVE_DIRECTION_MAP[szDirectionKey] and _KEY_MOVE_DIRECTION_MAP[szDirectionKey] == MOVE_DIRECTION_KEY_TYPE.Jump then
        return true
    end
    return false
end

function ShortcutInteractionData.GetJoyStickDirection(tDirection)
    local nX, nY = 0, 0
    if tDirection then
        local szKeyMoveUp = _TYPE_MOVE_DIRECTION_MAP[MOVE_DIRECTION_KEY_TYPE.MoveUp]
        local szKeyMoveDown = _TYPE_MOVE_DIRECTION_MAP[MOVE_DIRECTION_KEY_TYPE.MoveDown]
        local szKeyMoveLeft = _TYPE_MOVE_DIRECTION_MAP[MOVE_DIRECTION_KEY_TYPE.MoveLeft]
        local szKeyMoveRight = _TYPE_MOVE_DIRECTION_MAP[MOVE_DIRECTION_KEY_TYPE.MoveRight]
        if tDirection[szKeyMoveUp] and not self._checkOccupy(szKeyMoveUp) then
            nY = nY + 1
        end
        if tDirection[szKeyMoveDown] and not self._checkOccupy(szKeyMoveDown) then
            nY = nY - 1
        end
        if tDirection[szKeyMoveLeft] and not self._checkOccupy(szKeyMoveLeft) then
            nX = nX - 1
        end
        if tDirection[szKeyMoveRight] and not self._checkOccupy(szKeyMoveRight) then
            nX = nX + 1
        end
        if nX ~= 0 or nY ~= 0 then
            nX, nY = kmath.normalize2(nX, nY)
        end
    end
    return nX, nY
end

function ShortcutInteractionData.CheckSettingSprintMode()
    local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
    if szSprintMode == GameSettingType.SprintMode.Simple.szDec or szSprintMode == GameSettingType.SprintMode.Common.szDec then
        if self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Normal then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.SimpleNormal
        elseif self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Sprint then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.SimpleSprint
        elseif self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Riding then
            self.szCurrentState = SHORTCUT_KEY_BOARD_STATE.SimpleRiding
        end
    end
end



--DX版的键位绑定格式转换
local tDXBindingConvert = {
    ["MOVEFORWARD"] = ShortcutDef.Forward,
    ["MOVEBACKWARD"] = ShortcutDef.Backward,
    ["TURNLEFT"] = ShortcutDef.TurnLeft,
    ["TURNRIGHT"] = ShortcutDef.TurnRight,
    ["JUMP"] = ShortcutDef.Jump,
    ["RIDEHORSE"] = ShortcutDef.RideHorse,
    ["ROLL"] = ShortcutDef.NieYun, --新增
    ["TRANSFER"] = ShortcutDef.Transfer, --新增
    ["AUTOFORWARD"] = ShortcutDef.AutoForward, --新增

    ["TOGGLE_OPTION_PANEL"] = "Esc",
    ["SHIFT"] = "Shift",
    ["ALT"] = "Alt",
    ["CTRL"] = "Ctrl",
}
function ShortcutInteractionData.IsSprintState()
    return self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.Sprint or self.szCurrentState == SHORTCUT_KEY_BOARD_STATE.SimpleSprint
end
function ShortcutInteractionData.SetupSprintSlotInfo(nSlotIndex, tbBtnData)
    for nState, interType in pairs(SHORTCUT_INTERACTION) do
        for k, v in pairs(interType) do
            if k == nSlotIndex then
                v.szFuncName = tbBtnData.szDesc
                if nState == SHORTCUT_KEY_BOARD_STATE.Sprint or nState == SHORTCUT_KEY_BOARD_STATE.SimpleSprint then
                    v.szVKName = tbBtnData.tbKeyInfo
                end

                local tOtherSlot1 = interType[DX_COMMON_SLOT_1]
                if nSlotIndex == 1 and tOtherSlot1 then
                    tOtherSlot1.szFuncName = tbBtnData.szDesc -- 特殊处理DX轻功键位信息
                    if nState == SHORTCUT_KEY_BOARD_STATE.Sprint or nState == SHORTCUT_KEY_BOARD_STATE.SimpleSprint then
                        tOtherSlot1.szVKName = tbBtnData.tbKeyInfo
                    end
                end
            end
        end
    end
end
--根据DX版的键位绑定格式获取当前对应的键位
function ShortcutInteractionData.GetKeyByDXBinding(szDXBinding)
    local szName = tDXBindingConvert[szDXBinding]
    if szName then
        local tShortcutInfo = self.GetShortcutInfoByDef(szName)
        if tShortcutInfo then
            return tShortcutInfo.VKey
        end
        return szName
    end
    return szDXBinding
end

---@param nDef number ShortcutDef
function ShortcutInteractionData.GetShortcutInfoByDef(nShortcutDef)
    return self.tbShortcutInfoMap[nShortcutDef]
end

function ShortcutInteractionData.GetKeyViewName(szShortcutKey, bSimplify, nIconType, nIconSize)
    nIconType = nIconType or SHORTCUT_ICON_TYPE.NONE
    nIconSize = nIconSize or 54

    if not string.is_nil(szShortcutKey) then
        if SHORTCUT_KEY_ICON[nIconType] then
            for szKeyName, szPath in pairs(SHORTCUT_KEY_ICON[nIconType]) do
                local szImg = string.format("<img src='%s' width='%d' height='%d' />", szPath, nIconSize, nIconSize)
                szShortcutKey = string.gsub(szShortcutKey, szKeyName, szImg)
            end
        end
        if bSimplify then
            szShortcutKey = self.GetSimplifyKey(szShortcutKey)
        end
        for szKeyName, szKeyViewName in pairs(SHORTCUT_KEY_BOARD_SPECIAL_NAME) do
            szShortcutKey = string.gsub(szShortcutKey, szKeyName, szKeyViewName)
        end
    end
    return szShortcutKey
end

function ShortcutInteractionData.GetSimplifyKey(szShortcutKey)
    for szKeyViewName, szKeySimplifyName in pairs(SHORTCUT_KEY_BOARD_SIMPLIFY_NAME) do
        szShortcutKey = string.gsub(szShortcutKey, szKeyViewName, szKeySimplifyName)
    end
    return szShortcutKey
end

---@param nDef number GamepadDef
function ShortcutInteractionData.GetGamepadInfoByDef(nGamepadDef)
    return self.tbGamepadInfoMap[nGamepadDef]
end

function ShortcutInteractionData.GetGamepadViewName(szShortcutKey, bSmall)
    if string.find(szShortcutKey, '+') then
        local szSplits = string.split(szShortcutKey,'+')
        local szKey1 = szSplits[1]
        local szKey2 = szSplits[2]
        if bSmall then
            return GamepadData.GetGamepadRichTextIcon(szKey1, 36)..
                    "<img src='UIAtlas2_GameSetting_JoyStick_Normal_And' width='18' height='18' />"
                    ..GamepadData.GetGamepadRichTextIcon(szKey2, 36)
        else
            return GamepadData.GetGamepadRichTextIcon(szKey1)..
                    "<img src='UIAtlas2_GameSetting_JoyStick_Normal_And' width='22' height='22' />"
                    ..GamepadData.GetGamepadRichTextIcon(szKey2)
        end
    else
        return GamepadData.GetGamepadRichTextIcon(szShortcutKey)
    end
end

local MAX_SHORTCUT_SETTING_SERVER_COUNT = 199
ShortcutInteractionData.nMaxShortcutDef = 0
ShortcutInteractionData.nShortcutVersion = 0
ShortcutInteractionData.tbServerShortcutSetting = {}

function ShortcutInteractionData._InitServerShortcutSetting()
    local nMaxShortcutDef = 0
    for nShortcutDef, nIndex in pairs(ShortcutDef) do
        if nIndex > nMaxShortcutDef then
            nMaxShortcutDef = nIndex
        end
    end
    self.nMaxShortcutDef = nMaxShortcutDef
    self.nShortcutVersion = UISettingNewStorageTab.Version[SettingCategory.ShortcutInteraction]
    self.tbServerShortcutSetting = {}
end

function ShortcutInteractionData.SetServerShortcutSetting(nShortcutDef, szShortcutKey)
    if not nShortcutDef or nShortcutDef > MAX_SHORTCUT_SETTING_SERVER_COUNT then
        LOG.ERROR("ShortcutInteractionData.SetServerShortcutSetting Error, %s, %s", tostring(nShortcutDef), tostring(szShortcutKey))
        return
    end

    szShortcutKey = szShortcutKey or ""
    if self.tbServerShortcutSetting[nShortcutDef] == szShortcutKey then
        return
    end

    local tbKeyCodes, _ = self._getKeyInfo(szShortcutKey)

    --LOG.INFO("ShortcutInteractionData.SetServerShortcutSetting %s %s", tostring(nShortcutDef), tostring(szShortcutKey))
    Storage_Server.SetData("ShortcutSetting", nShortcutDef, tbKeyCodes[1] or 0, tbKeyCodes[2] or 0, tbKeyCodes[3] or 0)
    self.tbServerShortcutSetting[nShortcutDef] = szShortcutKey
end

function ShortcutInteractionData.GetServerShortcutSetting(nShortcutDef)
    if not nShortcutDef or nShortcutDef > MAX_SHORTCUT_SETTING_SERVER_COUNT then
        LOG.ERROR("ShortcutInteractionData.GetServerShortcutSetting Error, %s", tostring(nShortcutDef))
        return
    end

    if self.tbServerShortcutSetting[nShortcutDef] then
        return self.tbServerShortcutSetting[nShortcutDef]
    end

    local nKeyCode1, nKeyCode2, nKeyCode3 = Storage_Server.GetData("ShortcutSetting", nShortcutDef)
    local szShortcutKey = ""

    local function _addKey(nKeyCode)
        local szKey = KeyBoard._getKeyCodeNameByValue(nKeyCode)
        if not szKey then
            return
        end

        szShortcutKey = string.is_nil(szShortcutKey) and szKey or (szShortcutKey .. "+" .. szKey)
    end

    _addKey(nKeyCode1)
    _addKey(nKeyCode2)
    _addKey(nKeyCode3)

    self.tbServerShortcutSetting[nShortcutDef] = szShortcutKey
    return szShortcutKey
end

function ShortcutInteractionData.IsServerShortcutSettingNeedUpdate(bLog)
    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        if settingInfo.szDef and ShortcutDef[settingInfo.szDef] then
            local szShortcutKey = self.GetServerShortcutSetting(ShortcutDef[settingInfo.szDef])
            if szShortcutKey ~= settingInfo.VKey then
                if bLog then
                    LOG.INFO("ShortcutInteractionData.IsServerShortcutSettingNeedUpdate true, [%s] [%s]", tostring(szShortcutKey), tostring(settingInfo.VKey))
                end
                return true
            end
        end
    end
    return false
end

function ShortcutInteractionData.UploadServerShortcutSetting()
    LOG.INFO("ShortcutInteractionData.UploadServerShortcutSetting")
    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        if settingInfo.szDef and ShortcutDef[settingInfo.szDef] then
            self.SetServerShortcutSetting(ShortcutDef[settingInfo.szDef], settingInfo.VKey)
        end
    end
    Storage_Server.SetData("ShortcutMaxIndex", self.nMaxShortcutDef)
    Storage_Server.SetData("ShortcutVersion", self.nShortcutVersion)
end

function ShortcutInteractionData.SyncServerShortcutSetting()
    if not GameSettingData.GetNewValue(UISettingKey.SyncShortcutSetting) then
        return
    end

    local nMaxShortcutDef = Storage_Server.GetData("ShortcutMaxIndex")
    local nShortcutVersion = Storage_Server.GetData("ShortcutVersion")
    LOG.INFO("ShortcutInteractionData.SyncServerShortcutSetting, %s %s, %s %s",
        tostring(nMaxShortcutDef), tostring(self.nMaxShortcutDef),
        tostring(nShortcutVersion), tostring(self.nShortcutVersion))

    --若有新增快捷键，则直接上传到服务器
    if nMaxShortcutDef < self.nMaxShortcutDef then
        for nShortcutDef = nMaxShortcutDef, self.nMaxShortcutDef do
            local szShortcutKey = self.GetServerShortcutSetting(nShortcutDef) --服务器
            local tShortcutInfo = self.GetShortcutInfoByDef(nShortcutDef) --本地
            if string.is_nil(szShortcutKey) and tShortcutInfo and not string.is_nil(tShortcutInfo.VKey) then
                LOG.INFO("ShortcutInteractionData.SyncServerShortcutSetting UpdateShortcutMaxIndex, %s", tostring(tShortcutInfo.VKey))
                self.SetServerShortcutSetting(nShortcutDef, tShortcutInfo.VKey)
            end
        end
        Storage_Server.SetData("ShortcutMaxIndex", self.nMaxShortcutDef)
    end

    --若快捷键版本号有更新，则更新相关默认值
    if nShortcutVersion < self.nShortcutVersion then
        for _, tLine in ipairs(Default_Shortcut_Update) do
            local szShortcutKey = self.GetServerShortcutSetting(tLine.nShortcutDef) --服务器
            local tShortcutInfo = self.GetShortcutInfoByDef(tLine.nShortcutDef) --本地
            if nShortcutVersion < tLine.nVersion and szShortcutKey == tLine.szDefault then
                LOG.INFO("ShortcutInteractionData.SyncServerShortcutSetting UpdateShortcutVersion, %s->%s", tostring(szShortcutKey), tostring(tShortcutInfo.VKey))
                self.SetServerShortcutSetting(tLine.nShortcutDef, tShortcutInfo.VKey)
            end
        end
        Storage_Server.SetData("ShortcutVersion", self.nShortcutVersion)
    end

    if not self.IsServerShortcutSettingNeedUpdate(true) then
        return
    end

    local dialog = UIHelper.ShowSystemConfirm("本地快捷键配置与服务器存在差异，是否使用服务器配置覆盖本地配置或保留本地配置并上传到服务器？", function()
        self.IsSync = true
        for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
            if settingInfo.szDef and ShortcutDef[settingInfo.szDef] then
                local szShortcutKey = self.GetServerShortcutSetting(ShortcutDef[settingInfo.szDef])
                if szShortcutKey and settingInfo.VKey ~= szShortcutKey then
                    Event.Dispatch(EventType.OnGameSettingsKeyboardChange, k, settingInfo.VKey, szShortcutKey)
                    settingInfo.VKey = szShortcutKey
                end
            end
        end
        self.IsSync = false
        UISettingStoreTab.Flush()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end, function()
        -- GameSettingData.ApplyNewValue(UISettingKey.SyncShortcutSetting, false)
        -- Event.Dispatch(EventType.OnGameSettingViewUpdate)
    end)

    dialog:ShowOtherButton()
    dialog:SetOtherButtonClickedCallback(function()
        self.UploadServerShortcutSetting()
    end)

    dialog:SetConfirmButtonContent("使用服务器配置")
    dialog:SetCancelButtonContent("取消")
    dialog:SetOtherButtonContent("上传本地配置")
end

ShortcutInteractionData.tbMenuKeyBoardInfo = {}
function ShortcutInteractionData._InitMenuKeyBoardBind()
    self.tbMenuKeyBoardInfo = {}
    for i, v in ipairs(UISystemMenuTab) do
        local tbKeyCodes, tbKeyNames = self._getKeyInfo(v.szShortcutKey)
        local _info = {}
        _info.szShortcutKey = v.szShortcutKey
        _info.szDesc = v.szDesc
        _info.szAction = v.szAction
        _info.nSystemOpenID = v.nSystemOpenID
        _info.tbKeyCodes = tbKeyCodes
        _info.tbKeyNames = tbKeyNames
        self.tbMenuKeyBoardInfo[v.nID] = _info
        KeyBoard.BindKeyDown(tbKeyCodes, v.szDesc, function()
            if not g_pClientPlayer then return end
            --if not self.GetEnableKeyBoard(v.szShortcutKey) then return end --打开界面后再按快捷键可关闭
            if not self._checkShortcutEnable(tbKeyNames) then return end

            --若触发了组合键，则不触发单键
            self.SwallowSingleKey(tbKeyNames)

            local nNow = GetTickCount()
            if nNow - (self.nLastKeyDownTime or 0) < self.SHORTCUT_FREQ then return end

            self._bindMenuAction(v.szAction, v.szShortcutKey, v.nSystemOpenID)
            self.nLastKeyDownTime = nNow
        end)
    end
end

function ShortcutInteractionData._bindMenuAction(szAction, szShortcutKey, nSystemOpenID)
    if UIMgr.IsOpening() or UIMgr.IsCloseing() then
        return
    end

    local bHasPageOrPop, nPageLen, nPopLen, nSysPopLen, nMsgLen = self._hasPageOrPop()
    if not SystemOpen.IsSystemOpen(nSystemOpenID, not bHasPageOrPop) then
        return
    end

    TipsHelper.DeleteAllHoverTips()

    -- Esc 特殊处理
    -- NOTE: Esc不能关闭的界面配置在UIDef的ESC_CAN_NOT_CLOSE_VIEW_IDS
    if szShortcutKey == "Esc" then
        -- 如果正在处理西瓜的支付订单的时候，Esc就不生效
        if XGSDK.bNeedSuccessNotify then
            return
        end

        if UIMgr.GetView(VIEW_ID.PanelGM) then
            UIMgr.Close(VIEW_ID.PanelGM)
            return
        end

        if bHasPageOrPop then
            if nPageLen > 0 and nPopLen == 0 and nSysPopLen == 0 and nMsgLen == 0 then
                self._closeTopView()
            end
            return
        end

        local bSystemMenuIsOpen = UIMgr.GetView(VIEW_ID.PanelSystemMenu)
        if bSystemMenuIsOpen then
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        else
            local bSprint = SprintData.GetSprintState() and SprintData.GetExpectSprint()
            local bSpecialState = SprintData.GetSpecialState() ~= nil
            if not bSprint and not bSpecialState then
                UIMgr.Open(VIEW_ID.PanelSystemMenu)
            end
        end

        return
    else
        SceneMgr.ClearTouches()
        UIMgr.SetKeyboardMode(true)
        string.execute(szAction)
        UIMgr.SetKeyboardMode(false)
    end
end

function ShortcutInteractionData._hasPageOrPop()
    local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, table.AddRange({ VIEW_ID.PanelSystemMenu, VIEW_ID.PanelRevive }, IGNORE_TEACH_VIEW_IDS))
    local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup, IGNORE_TEACH_VIEW_IDS)
    local nSysPopLen = UIMgr.GetLayerStackLength(UILayer.SystemPop, table.AddRange({ VIEW_ID.PanelDownloadBall }, IGNORE_TEACH_VIEW_IDS))
    local nMsgLen = UIMgr.GetLayerStackLength(UILayer.MessageBox, IGNORE_TEACH_VIEW_IDS)
    local nLen = nPageLen + nPopLen + nMsgLen + nSysPopLen
    return nLen > 0, nPageLen, nPopLen, nSysPopLen, nMsgLen
end

function ShortcutInteractionData._closeTopView()
    local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
    if nTopViewID == VIEW_ID.PanelOldDialogue then
        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    elseif nTopViewID == VIEW_ID.PanelPlotDialogue then
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)
    else
        if not table.contain_value(ESC_CAN_NOT_CLOSE_VIEW_IDS, nTopViewID) then
            UIMgr.Close(nTopViewID)
        end
    end
    return
end

function ShortcutInteractionData._getKeyInfo(szKey)
    local shortcutKeyArray = string.split(szKey, "+")
    local tbKeyCodes, tbKeyNames = {}, {}
    for k, v in pairs(shortcutKeyArray) do
        table.insert(tbKeyCodes, KeyBoard.GetKeyCodeFromName(v))
        table.insert(tbKeyNames, v)
    end
    return tbKeyCodes, tbKeyNames
end

function ShortcutInteractionData._refreshMenuKeyboardBind(nID, szNewKey, bOnlyBind)
    local info = self.tbMenuKeyBoardInfo[nID]
    if info then
        if not bOnlyBind then
            KeyBoard.UnBindKeyDown(info.tbKeyCodes)
        end

        local tbKeyCodes, tbKeyNames = self._getKeyInfo(szNewKey)
        self.tbMenuKeyBoardInfo[nID].szShortcutKey = szNewKey
        self.tbMenuKeyBoardInfo[nID].tbKeyCodes = tbKeyCodes
        self.tbMenuKeyBoardInfo[nID].tbKeyNames = tbKeyNames
        KeyBoard.BindKeyDown(tbKeyCodes, info.szDesc, function()
            if not g_pClientPlayer then return end
            --if not self.GetEnableKeyBoard(info.szShortcutKey) then return end --打开界面后再按快捷键可关闭
            if not self._checkShortcutEnable(tbKeyNames) then return end

            --若触发了组合键，则不触发单键
            self.SwallowSingleKey(tbKeyNames)

            local nNow = GetTickCount()
            if nNow - (self.nLastKeyDownTime or 0) < self.SHORTCUT_FREQ then return end

            self._bindMenuAction(info.szAction, info.szShortcutKey, info.nSystemOpenID)
            self.nLastKeyDownTime = nNow
        end)
    end
end

ShortcutInteractionData.tbHotkeyKeyBoardInfo = {}
function ShortcutInteractionData._InitHotkeyKeyBoardBind()
    self.tbHotkeyKeyBoardInfo = {}
    for k, settingInfo in pairs(UISettingStoreTab.ShortcutInteraction) do
        if settingInfo.szType == "Hotkey" then
            local nID = tonumber(settingInfo.paramArgs)
            local tbKeyCodes, tbKeyNames = self._getKeyInfo(settingInfo.VKey)
            local _info = {}
            _info.szShortcutKey = settingInfo.VKey
            _info.szDesc = settingInfo.szTitle .. "-" .. settingInfo.szName
            _info.tbKeyCodes = tbKeyCodes
            _info.tbKeyNames = tbKeyNames
            self.tbHotkeyKeyBoardInfo[nID] = _info
        end
    end
end

function ShortcutInteractionData._refreshHotkeyKeyboardBind(nID, szNewKey, bOnlyBind)
    local info = self.tbHotkeyKeyBoardInfo[nID]
    if info then
        if not bOnlyBind then
            KeyBoard.UnBindKeyDown(info.tbKeyCodes)
            KeyBoard.UnBindKeyUp(info.tbKeyCodes[1])
        end

        local tbKeyCodes, tbKeyNames = self._getKeyInfo(szNewKey)
        self.tbHotkeyKeyBoardInfo[nID].szShortcutKey = szNewKey
        self.tbHotkeyKeyBoardInfo[nID].tbKeyCodes = tbKeyCodes
        self.tbHotkeyKeyBoardInfo[nID].tbKeyNames = tbKeyNames
        if self.CanHotkeyUseMultiKey(nID) then
            KeyBoard.BindKeyDown(tbKeyCodes, info.szDesc, function()
                if not g_pClientPlayer then return end
                if not self.GetEnableKeyBoard(info.szShortcutKey) then return end
                if not self._checkShortcutEnable(tbKeyNames) then return end

                --若触发了组合键，则不触发单键
                self.SwallowSingleKey(tbKeyNames)

                local nNow = GetTickCount()
                -- if nNow - (self.nLastKeyDownTime or 0) < self.SHORTCUT_FREQ then return end

                LOG.INFO("[Hotkey] ExecuteCommand: %s (%s)", tostring(nID), tostring(info.szDesc))
                HotkeyCommand.ExecuteKeyDownCommand(nID)
                self.nLastKeyDownTime = nNow
            end)
        else
            KeyBoard.BindKeyDown(tbKeyCodes, info.szDesc, function()
                if not g_pClientPlayer then return end
                if not self.GetEnableKeyBoard(info.szShortcutKey) then return end
                if not self._checkShortcutEnable(tbKeyNames) then return end

                info.bDown = true

                LOG.INFO("[Hotkey] ExecuteKeyDownCommand: %s (%s)", tostring(nID), tostring(info.szDesc))
                HotkeyCommand.ExecuteKeyDownCommand(nID)
            end)

            if tbKeyCodes[1] ~= nil then
                KeyBoard.BindKeyUp(tbKeyCodes[1], info.szDesc, function()
                    if not g_pClientPlayer then return end
                    if not self.GetEnableKeyBoard(info.szShortcutKey) then return end
                    if not self._checkShortcutEnable(tbKeyNames) then return end

                    info.bDown = false

                    LOG.INFO("[Hotkey] ExecuteKeyUpCommand: %s (%s)", tostring(nID), tostring(info.szDesc))
                    HotkeyCommand.ExecuteKeyUpCommand(nID)
                end)
            end

        end

    end

end

function ShortcutInteractionData.CanHotkeyUseMultiKey(nID)
    local info = self.tbHotkeyKeyBoardInfo[nID]
    if info then
        --若存在KeyUp function，则仅支持单键快捷键
        return not HotkeyCommand.GetKeyUpCommand(nID)
    end
    return true
end

function ShortcutInteractionData._clearHotkeyKeyboardDown()
    --lost focus etc.
    for nID, info in pairs(self.tbHotkeyKeyBoardInfo) do
        if info.bDown then
            info.bDown = false

            LOG.INFO("[Hotkey] ExecuteKeyUpCommand (Clear): %s (%s)", tostring(nID), tostring(info.szDesc))
            HotkeyCommand.ExecuteKeyUpCommand(nID)
        end
    end
end

function ShortcutInteractionData._refreshActionKeyboardBind(paramArgs, szNewKey)
    -- paramArgs:状态所在的位置
    local index = tonumber(paramArgs) or SHORTCUT_KEY_BOARD_TYPE[paramArgs]
    for i, stateInfo in pairs(SHORTCUT_INTERACTION) do
        for k, keyInfo in pairs(stateInfo) do
            if keyInfo.nType == index then
                SHORTCUT_INTERACTION[i][k].szVKName = szNewKey
            end
        end
    end
end

function ShortcutInteractionData._refreshGamepadKeyboardBind(szDef, szNewKey)
    for i, stateInfo in pairs(SHORTCUT_INTERACTION) do
        for slotId, keyInfo in pairs(stateInfo) do
            if SlotId2GamepadDef[slotId] == GamepadDef[szDef] then
                SHORTCUT_INTERACTION[i][slotId].szGamepadName = szNewKey
            end
        end
    end
end

function ShortcutInteractionData._refreshOsKeyboardBind(keyType, szOldKey, szNewKey)
    if _TYPE_MOVE_DIRECTION_MAP[keyType] then
        _TYPE_MOVE_DIRECTION_MAP[keyType] = szNewKey
        if not string.is_nil(szNewKey) then
            _KEY_MOVE_DIRECTION_MAP[szNewKey] = keyType
        end
        if _KEY_MOVE_DIRECTION_MAP[szOldKey] == keyType and szOldKey ~= szNewKey then
            _KEY_MOVE_DIRECTION_MAP[szOldKey] = nil
        end
    else
        local tbKeyCodes, tbKeyNames = self._getKeyInfo(szOldKey)
        KeyBoard.UnBindKeyDown(tbKeyCodes)
        local hotKey = KeyBoard._getHotKeyByKeyCodes(tbKeyCodes)
        tbKeyCodes, tbKeyNames = self._getKeyInfo(szNewKey)
        KeyBoard.BindKeyDown(tbKeyCodes, hotKey.szBindDes, function()
            if not g_pClientPlayer then return end
            -- if not self._checkShortcutEnable(tbKeyNames) then return end

            if IsFunction(hotKey.callback) then
                hotKey.callback()
            end
        end)
    end
end

function ShortcutInteractionData._checkOccupy(szKey)
    for k, v in pairs(self.tbOccupyKeyCodes) do
        if table.contain_value(v, szKey) then
            return true
        end
    end
    -- if self.CheckSingleKeySwallow(szKey) then
    --     return true
    -- end
   return false
end

function ShortcutInteractionData._updateMenuOccupyKeys(szOldKey, szNewKey)
    for k, v in pairs(self.tbOccupyKeyCodes.Menu) do
        if v == szOldKey then
            self.tbOccupyKeyCodes.Menu[k] = szNewKey
            break
        end
    end
end

function ShortcutInteractionData._updateHotkeyOccupyKeys(szOldKey, szNewKey)
    for k, v in pairs(self.tbOccupyKeyCodes.Hotkey) do
        if v == szOldKey then
            self.tbOccupyKeyCodes.Hotkey[k] = szNewKey
            break
        end
    end
end

function ShortcutInteractionData._updateActionOccupyKeys()
    self.tbOccupyKeyCodes.Action = {}
    for k, v in pairs(SHORTCUT_INTERACTION[self.szCurrentState]) do
        table.insert(self.tbOccupyKeyCodes.Action, v.szVKName)
    end
    for k, v in pairs(SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Common]) do
        table.insert(self.tbOccupyKeyCodes.Action, v.szVKName)
    end
end

local tPageForbiShortcut = {
    ShortcutDef.Interaction,
}

function ShortcutInteractionData._isShortcutMatch(tbKeyNames, tbOtherKeyNames)
    if #tbKeyNames == #tbOtherKeyNames then
        local bMatch = true
        for _, szKeyName in pairs(tbOtherKeyNames) do
            if not table.contain_value(tbKeyNames, szKeyName) then
                bMatch = false
                break
            end
        end
        if bMatch then
            return true
        end
    end
    return false
end

function ShortcutInteractionData._checkShortcutEnable(tbCurKeyNames)
    tbCurKeyNames = IsTable(tbCurKeyNames) and tbCurKeyNames or {tbCurKeyNames}
    local nKeyLen = #tbCurKeyNames

    --全屏界面禁用部分快捷键
    local tbIgnoreViewIDs = IGNORE_KEYBOARD_VIEW_IDS
	local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, tbIgnoreViewIDs)
	if nPageLen > 0 then
        for _, szName in pairs(tPageForbiShortcut) do
            local tShortcutInfo = self.GetShortcutInfoByDef(szName)
            local szKey = tShortcutInfo and tShortcutInfo.VKey or szName
            local _, tbKeyNames = self._getKeyInfo(szKey)
            if self._isShortcutMatch(tbKeyNames, tbCurKeyNames) then
                return false
            end
        end
    end

    if self.bEnableShortcut then
        return true
    end

    for _, tbKeyNames in pairs(self.tbIgnoreShortcutOnDisable or {}) do
        if self._isShortcutMatch(tbKeyNames, tbCurKeyNames) then
            return true
        end
    end
    return false
end

function ShortcutInteractionData._isShortcutTriggered(curKeyNames)
    -- keyName可以是table或string
    if IsTable(curKeyNames) then
        for i, keyName in ipairs(self.tbTriggeredKey) do
            if IsTable(keyName) and self._isShortcutMatch(keyName, curKeyNames) then
                return true, i
            end
        end
    elseif IsString(curKeyNames) then
        for i, tbKeyName in ipairs(self.tbTriggeredKey) do
            if IsString(tbKeyName) and tbKeyName == curKeyNames then
                return true, i
            end
        end
    end
    return false
end

function ShortcutInteractionData._isDXSkillShortcutkey(szDef)
    return string.sub(szDef, 1, 7) == "DXSkill"
end

function ShortcutInteractionData._isSkillShortcutKey(tbCurKeyNames)
    tbCurKeyNames = IsTable(tbCurKeyNames) and tbCurKeyNames or {tbCurKeyNames}
    for szDef, tShortcutInfo in pairs(self.tbSkillShortcutInfoMap) do
        local _, tbKeyNames = self._getKeyInfo(tShortcutInfo.VKey)
        if self._isShortcutMatch(tbKeyNames, tbCurKeyNames) then
            return true
        end
    end
    return false
end

local shortcutStateList = { SHORTCUT_KEY_BOARD_STATE.Fight, SHORTCUT_KEY_BOARD_STATE.Normal, SHORTCUT_KEY_BOARD_STATE.SimpleNormal,
                            SHORTCUT_KEY_BOARD_STATE.Common, SHORTCUT_KEY_BOARD_STATE.DXFight, SHORTCUT_KEY_BOARD_STATE.Riding, SHORTCUT_KEY_BOARD_STATE.SimpleRiding }

function ShortcutInteractionData.ChangeSkillShortcutInfo(nShortcutIndex, szName, szFunctionName)
    if nShortcutIndex and IsNumber(nShortcutIndex) then
        for _, nType in ipairs(shortcutStateList) do
            local tShortcutInfo = SHORTCUT_INTERACTION[nType][nShortcutIndex]
            if tShortcutInfo then
                tShortcutInfo.szFuncName = szName
                if szFunctionName then
                    tShortcutInfo.interactionFunction = szFunctionName
                end
            end
        end
    end
end

function ShortcutInteractionData.ClearDXSkillShortcutInfo(nShortcutIndex)
    if nShortcutIndex and IsNumber(nShortcutIndex) then
        for _, nType in ipairs(shortcutStateList) do
            local tShortcutInfo = SHORTCUT_INTERACTION[nType][nShortcutIndex]
            if tShortcutInfo then
                tShortcutInfo.szFuncName = ""
                tShortcutInfo.interactionFunction = ""
            end
        end
    end
end

function ShortcutInteractionData.IsPressingMultiKey()
    if self.tbPressedKey then
        local tFinalList = {}
        for _, szKeyCode in ipairs(self.tbPressedKey) do
            if not (szKeyCode == "LButton" or szKeyCode == "RButton") then
                table.insert(tFinalList, szKeyCode) -- 排除鼠标左右键
            end
        end
        return #tFinalList > 1
    end
    return false
end

-- 特殊符号按键逻辑配置
-- OEM1是;
-- OEMPlus是+
-- OEMComma是，
-- OEMMinus是-
-- OEMPeriod是。
-- OEM2是/
-- OEM3是~

-- 功能
-- MainViewBtnFuncSlot_1 ~ MainViewBtnFuncSlot_9 （1-9个孔的调用）
-- AttackClicked 攻击（切换到技能）
-- FastSceneInteract   -- 单个物品拾取/任务/对话/
-- AllFastPick         -- 全部物品拾取
-- SkillRoll 滑翔
-- SkillJump 跳
-- SkillAuto 助手
-- SkillQuick 特殊道具/团队标记