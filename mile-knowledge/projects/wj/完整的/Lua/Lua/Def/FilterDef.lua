FilterType = {
    RadioButton     = "RadioButton",    -- 单选
    CheckBox        = "CheckBox",       -- 多选
    RangeInput      = "RangeInput",     -- 范围
}

FilterSubType = {
    Big     = "Big",    -- 大号
    Small   = "Small",  -- 小号
}









FilterDef = {}



-- 家园建造筛选和排序
FilterDef.HomelandBuildFurnitureList =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        szTitle = "是否拥有",
        tbList = {"已拥有", "未拥有"},
        tbDefault = {1, 2},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        szTitle = "物件来源",
        tbList = {"园宅币", "商城", "特殊获取"},
        tbDefault = {1, 2, 3},
    },

    [3] =
    {
        szType = FilterType.RangeInput,
        szTitle = "解锁等级",
        tbList = {"等级下限", "等级上限"},
        tbDefault = {"", ""},
    },

    [4] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = "排序（由高到低）",
        tbList = {"解锁等级", "品质", "评审分"},
        tbDefault = {1},
    },
}

FilterDef.HomelandBuildInteractionListType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Big,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "获取情况",
        tbList = {"仅查看已摆放分类"},
        tbDefault = {},
    },
    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "所有分类",
        tbList = {"床", "浴缸", "盥洗台", "灶台", "水井", "书桌", "梳妆台", "种植",
            "麻将桌", "茶桌", "钓鱼池", "宠物窝", "酒桶", "许愿树", "厕所", "机关"},
        tbDefault = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    },
}

FilterDef.HomelandBuildBlueprintType =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "蓝图类型",
        tbList = {"1280平", "2240平", "4032平", "7200平", "私邸宅园"},
        tbDefault = {1},
    },
}

FilterDef.HomelandBuildDigitalBlueprintType =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "蓝图类型",
        tbList = {"全部", "1280平", "2240平", "4032平", "6272平", "7200平", "11648平", "45792平", "私邸宅园"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "搜索类型",
        tbList = {"搜蓝图", "搜作者"},
        tbDefault = {1},
    },
}

--
FilterDef.WishItem =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = true,    -- 是否显示确认按钮
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = false,   -- 是否支持全选
        bDefaultSelectAll = false,
        nFontSize = 22,
        szTitle = "道具类型",
        tbList = {"全部","背部挂件","腰部挂件","面部挂件","头饰","眼饰","手饰","外观","披风","特效称号","宠物","坐骑","奇趣坐骑","马具","玩具","其他",},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = false,   -- 是否支持全选
        bDefaultSelectAll = false,
        nFontSize = 22,
        szTitle = "能否祈愿",
        tbList = {"全部","可祈愿","不可祈愿"},
        tbDefault = {1},
    },
}

-- 副本掉落列表
FilterDef.AuctionLootList =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = true,    -- 是否显示确认按钮
    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        nFontSize = 22,
        szTitle = "道具品质",
        tbList = {"灰色","白色","绿色","蓝色","紫色","橙色"},
        tbDefault = {1,2,3,4,5,6},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        nFontSize = 22,
        szTitle = "道具类型",
        tbList = {"装备", "道具"},
        tbDefault = {1,2},
    },
}

-- 百战异闻录
FilterDef.MonsterBook =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        nFontSize = 22,
        szTitle = "效果",
        tbList = {"全部", "伤害", "精神打击", "耐力打击", "伤害增益", "打断", "驱散敌方增益", "驱散友军减益", "恢复精神", "恢复耐力", "控制", "生存", "召唤", "解除控制", "防御"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "消耗",
        tbList = {"全部", "一星", "二星", "三星"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "颜色",
        tbList = {"全部", "白色", "黄色", "蓝色", "绿色", "红色", "紫色", "黑色"},
        tbDefault = {1},
    },

    [4] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "重数",
        tbList = {"全部", "一重", "二重", "三重", "四重", "五重", "六重", "七重", "八重", "九重", "十重"},
        tbDefault = {1},
    },

    [5] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "传授",
        tbList = {"全部", "可传授", "不可传授"},
        tbDefault = {1},
    },
}

-- 百战异闻录临时技能
FilterDef.MonsterBookDynamicSkill =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        nFontSize = 22,
        szTitle = "效果",
        tbList = {"全部", "伤害", "精神打击", "耐力打击", "伤害增益", "打断", "驱散敌方增益", "驱散友军减益", "恢复精神", "恢复耐力", "控制", "生存", "召唤", "解除控制", "防御"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "消耗",
        tbList = {"全部", "一星", "二星", "三星"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "颜色",
        tbList = {"全部", "白色", "黄色", "蓝色", "绿色", "红色", "紫色", "黑色"},
        tbDefault = {1},
    },
}

-- 百战异闻录技能排序
FilterDef.MonsterBookSkillSort =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "排序要素",
        tbList = {"重数", "颜色", "首领"},
        tbDefault = {1},
    },
}

-- 制造筛选
FilterDef.Manufacture =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "配方",
        tbList = {"全部", "已学会", "未学会"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "种类",
        tbList = {"全部", "普通配方", "专精配方"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "制作",
        tbList = {"全部", "材料充足", "可制作", "已收集", "未收集"},
        tbDefault = {1},
    },
}

FilterDef.ManufactureWithoutCollect =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "配方",
        tbList = {"全部", "已学会", "未学会"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "种类",
        tbList = {"全部", "普通配方", "专精配方"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "制作",
        tbList = {"全部", "材料充足", "可制作"},
        tbDefault = {1},
    },
}

-- 阅读筛选
FilterDef.SelfRead =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "分类",
        tbList = {"经传", "百家", "江湖", "秘籍", "图册"},
        tbDefault = {1,2,3,4,5},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "状态",
        tbList = {"不绑可售", "不绑不可售", "绑定可售", "绑定不可售"},
        tbDefault = {1,2,3,4},
    },

    [3] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "收录",
        tbList = {"已收录", "未收录"},
        tbDefault = {1,2},
    },
    [4] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "成就",
        tbList = {"已达成", "未达成"},
        tbDefault = {1,2},
    },
    [5] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "获取途径",
        tbList = {"任务奖励", "商店售卖", "野外掉落", "秘境掉落", "碑铭"},
        tbDefault = {1,2,3,4,5},
    },
}

-- 上缴书籍筛选
FilterDef.BookCommit =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "分类",
        tbList = {"经传", "百家", "江湖", "秘籍", "图册"},
        tbDefault = {1,2,3,4,5},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "奖励",
        tbList = {"饰品", "物品", "修为"},
        tbDefault = {1,2,3},
    },

    [3] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "收录",
        tbList = {"已收录", "未收录"},
        tbDefault = {1,2},
    },
}

-- 当前商店的实时筛选
FilterDef.Shop =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] = -- 商店的筛选项都是动态生成，这里只做为示例展示筛选结构
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        bDispatchChangedEvent = true, -- 是否在筛选状态发生变化时立即派发OnFilterSelectChanged事件
        bHideSingleOption = true, -- 该分类只有一个筛选项时，是否隐藏整个分类
        szTitle = "门派",
        tbList = {"纯阳宫", "天策府", "万花谷", },
        tbDefault = {1},
    },
}

-- 当前Boss掉落的实时筛选
FilterDef.BossDropDetail =
{
    bStorage = false,          -- 本地存储
    bRuntime = true,           -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] = -- 商店的筛选项都是动态生成，这里只做为示例展示筛选结构
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        bDispatchChangedEvent = false,
        szTitle = "门派",
        tbList = {"全部", "纯阳宫", "天策府", "万花谷", },
        tbDefault = {1},
    },
}

-- 红尘侠影侠客筛选 note: 选项将会在显示前动态修改，这里仅用作示例
FilterDef.Partner =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        Way = 1,
        KungfuIndex = 2,
    },

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        szTitle = "按获取途径",
        tbList = {"家园", "喝茶结交", "活动", "名望", "单人"},
        tbDefault = {},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        szTitle = "按类型",
        tbList = {"攻击", "防御", "治疗"},
        tbDefault = {},
    },
}

-- 侠客出行 侠客筛选
FilterDef.TravelPartner =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        Way = 1,
    },

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        szTitle = "侠客获取途径",
        tbList = {"家园", "喝茶结交", "活动", "名望"},
        tbDefault = {},
    },
}

-- 侠客出行的槽位筛选 note: 选项将会在显示前动态修改，这里仅用作示例
FilterDef.PartnerTravelSlot =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        QuestType = 1,
    },

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        szTitle = "按类型筛选",
        tbList = {"宠物奇缘", "往期茶馆", "往期名望", "公共任务"},
        tbDefault = {},
    },
}

-- 成就筛选 note: 选项将会在显示前动态修改，这里仅用作示例
FilterDef.Achievement =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        FinishStatus = 1,
        DlcId = 2,
    },

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = false,
        szTitle = "获得情况",
        tbList = {"全部显示"},
        tbProgressList = {"1/1"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = false,
        szTitle = "版本",
        tbList = {"家园"},
        tbProgressList = {"1/1"},
        tbDefault = {1},
    },
}

-- 成就筛选 note: 从其他系统跳转过来时，仅显示是否已完成
FilterDef.AchievementJumpFromOtherSystem =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        FinishStatus = 1,
    },

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = false,
        szTitle = "获得情况",
        tbList = {"全部显示"},
        tbProgressList = {"1/1"},
        tbDefault = {1},
    },
}

-- 查看他人阅读筛选
FilterDef.AnotherRead =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"经传", "百家", "江湖", "秘籍", "图册"},
        tbDefault = {1,2,3,4,5},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "状态",
        tbList = {"不绑定", "绑定可出售", "绑定不可售"},
        tbDefault = {1,2,3},
    },
}

--家园日志
FilterDef.HomeLandLogFilter =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"不筛选", "社区", "私邸"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"不筛选", "互动", "苑圃之事", "宠物游历", "鱼塘养殖"},
        tbDefault = {1},
    },
}

-- 交易行左侧背包筛选
FilterDef.TradingLeftBag =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "常用",
        tbList = {"全部", "可账号共享", "可交易", "限时"},
        tbDefault = {3},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "装备类型",
        tbList = {"全部", g_tStrings.STR_ITEM_EQUIP_PVP, g_tStrings.STR_ITEM_EQUIP_PVE, g_tStrings.STR_ITEM_EQUIP_PVX},
        tbDefault = {1},
    },
}

-- 邮件左侧背包筛选
FilterDef.EmailLeftBag =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"全部", "装备", "药品", "材料", "书籍", "家具", "次品"},
        tbDefault = {1},
    },
}

-- 坐骑右侧背包筛选
FilterDef.HorseLeftBag =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"全部品质", "绿色品质", "蓝色品质", "紫色品质", "橙色品质"},
        tbDefault = {1},
    },
}

-- 面对面交易背包筛选
FilterDef.TransactionBag =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"全部", "任务", "装备", "药品", "材料", "书籍", "家具", "非绑定", "限时"},
        tbDefault = {1},
    },
}

-- 家园建造交互道具左侧背包筛选
FilterDef.HomelandInteractLeftBag =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"全部"},
        tbDefault = {1},
    },
}

-- 家园快捷购买房号多选     note: 选项将会在显示前动态修改，这里仅用作示例
FilterDef.HomelandEasyBuyHouse =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        szTitle = "房号筛选",
        tbList = {"1号", "2号", "3号", "4号", "5号", "6号", "7号", "8号", },
        tbDefault = {},
    },
}

-- 快速换装筛选
FilterDef.SwitchEquipSuitType =
{
    bStorage = true,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "配置第1、2套装备方案共用的部位",
        tbList = {"武器", "重兵类", "暗器", "上衣", "帽子", "项链", "戒指·一", "戒指·二", "腰带", "腰坠", "下装", "鞋子", "护腕", "暗器"},
        tbDefault = {},
    },
}

-- 装备比较类型筛选
FilterDef.EquipType =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"武器", "暗器", "帽子", "上衣", "腰带", "护腕", "下装", "鞋子", "项链", "腰坠", "戒指"},
        tbDefault = {1},
    },
}

-- 附魔界面装备比较类型筛选
FilterDef.EnchantEquipType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"全部显示","武器", "暗器", "帽子", "上衣", "腰带", "护腕", "下装", "鞋子", "项链", "腰坠", "戒指"},
        tbDefault = {1},
    },
}

-- 自定义装备类型筛选
FilterDef.CustomizedSetEquipType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"全部","竞技对抗","秘境挑战","休闲"},
        tbDefault = {1},
    },
}

FilterDef.CustomizedSetEquipType_DPS =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "主分类",
        tbList = {"PVE","PVP","PVX"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "子分类",
        tbList = {"会心流","破防流"},
        tbDefault = {},
    },
}

FilterDef.CustomizedSetEquipType_T =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"外功防御", "内功防御", "招架", "闪避"},
        tbDefault = {1},
    },
}

FilterDef.CustomizedSetEquipType_Heal =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "主分类",
        tbList = {"PVE","PVP","PVX"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "子分类",
        tbList = {"会心流","加速流"},
        tbDefault = {},
    },
}

-- 奇遇手记筛选
FilterDef.AdventureTryBook =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "分类",
        tbList = {"全部", "机缘成熟", "机缘未到"},
        tbDefault = {2},
    },
}

-- 绝境战场
FilterDef.TreasureBattleFieldSkill =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = {"任何品质"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "效果",
        tbList = {"任何效果"},
        tbDefault = {1},
    },
}

-- 绝境战场·寻宝模式 背包类型筛选

FilterDef.ExtractItem =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部", "药品", "食物", "武器", "防具", "饰品"},
        tbDefault = {1},
    },
}

FilterDef.ExtractWeaponPerset =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bCanSelectAll = true,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"近战", "远程"},
        tbDefault = {1, 2},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bCanSelectAll = true,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = {"蓝色", "紫色"},
        tbDefault = {1, 2},
    },
}


-- 宠物筛选
FilterDef.Pet =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已拥有", "未拥有", "福缘"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "种类",
        tbList = {"所有种类", "水族", "走兽", "禽鸟", "机关"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "途径",
        tbList = {"全部途径", "宠物奇缘", "世界奇遇", "场景探索", "秘境掉落", "门派专属", "游戏活动", "运营活动", "积分回馈", "限时宠物"},
        tbDefault = {1},
    },

    [4] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "排序方式",
        tbList = {"获取难度", "宠物积分"},
        tbDefault = {1},
    },
}

-- 坐骑马具类型
FilterDef.HorseEquip =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已拥有", "未拥有"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"成就奖励", "秘境玩法", "对抗玩法", "休闲玩法", "商城充消", "其他途径"},
        tbDefault = {1, 2, 3, 4, 5, 6},
    },
}

-- 成就奖励收集筛选 note: 选项将会在显示前动态修改，这里仅用作示例
FilterDef.AchievementAwardGather =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    IndexDef = {
        CollectStatus = 1,
        GiftType = 2,
    },

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        szTitle = "获得情况",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        szTitle = "物品类型",
        tbList = {"全部"},
        tbDefault = {1},
    },
}

-- 庐园广记套装收集筛选
FilterDef.HomelandCollectionFilter =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "家具来源",
        tbList = {"全部", "大水南方令", "园宅币", "节日活动", "商城", "其他"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "收集状态",
        tbList = {"全部", "已领奖", "未领奖", "收集中", "未收集"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "难度",
        tbList = {"全部", "1星", "2星", "3星", "4星"},
        tbDefault = {1},
    },
}

-- 师徒筛选
FilterDef.Apprentice =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "门派",
        tbList = {"全部", "江湖", "少林", "万花", "天策", "纯阳", "七秀", "五毒", "唐门", "藏剑", "丐帮", "明教", "苍云", "长歌", "霸刀", "蓬莱", "凌雪", "衍天", "药宗", "刀宗", "万灵", "段氏"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "阵营",
        tbList = {"全部", "中立", "浩气", "恶人"},
        tbDefault = {1},
    },
}

-- 好友筛选
FilterDef.Friend =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "在线情况",
        tbList = {"全部", "在线", "离线"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "好友种类",
        tbList = {"全部", "双向", "单向"},
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "门派",
        tbList = {"全部", "江湖", "少林", "万花", "天策", "纯阳", "七秀", "五毒", "唐门", "藏剑", "丐帮", "明教", "苍云", "长歌", "霸刀", "蓬莱", "凌雪", "衍天", "药宗", "刀宗", "万灵", "段氏"},
        tbDefault = {1},
    },
}

FilterDef.ServerEquipFound =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = {"任何品质", "破败", "普通", "精巧", "卓越", "珍奇", "稀世"},
        tbDefault = {1},
    },
}


-- 称号筛选
FilterDef.Designation =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "称号类型",
        tbList = {}, -- 在 DesignationMgr 这里补全
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "拥有情况",
        tbList = {}, -- 在 DesignationMgr 这里补全
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "获取途径",
        tbList = {}, -- 在 DesignationMgr 这里补全
        tbDefault = {1},
    },

    -- [4] =
    -- {
    --     szType = FilterType.RadioButton,
    --     szSubType = FilterSubType.Small,
    --     bAllowAllOff = true,
    --     bResponseImmediately = false,
    --     szTitle = "资料片",
    --     tbList = {}, -- 在 DesignationMgr 这里补全
    --     tbDefault = {1},
    -- },
}

FilterDef.Designation_DLC =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "资料片",
        tbList = {}, -- 在 DesignationMgr 这里补全
        tbDefault = {1},
    },
}


-- 声望筛选
FilterDef.Reputation =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "地图",
        tbList = {}, -- 在 ReputationData 这里补全
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "等级",
        tbList = {}, -- 在 ReputationData 这里补全
        tbDefault = {1},
    },

    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "势力",
        tbList = {}, -- 在 ReputationData 这里补全
        tbDefault = {1},
    },

}

-- 钓鱼笔记
FilterDef.IdentityFishNote =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"全部", "小鱼", "大鱼", "白品", "绿品", "蓝品", "紫品", "橙品"},
        tbDefault = {1},
    },
}

-- 鱼篓
FilterDef.IdentityFishSell =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"全部", "白品", "绿品", "蓝品", "紫品", "橙品"},
        tbDefault = {1},
    },
}

-- 大唐藏品界面挂件类型筛选
FilterDef.Pendant =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = {"全部", "白品", "绿品", "蓝品", "紫品", "橙品"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "赛季",
        tbList = {"全部赛季", "白品", "绿品", "蓝品", "紫品", "橙品"},
        tbDefault = {1},
    },
}

-- 家园宠物窝-宠物筛选
FilterDef.HomelandPet =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "宠物分类",
        tbList = {"全部宠物", "两栖类", "鸟类", "肉食类", "机甲类", "啮齿类", "草食类", "异食类"},
        tbDefault = {1},
    },
}


-- 房间目标
FilterDef.RoomTarget =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "目标",
        tbList = {},
        tbDefault = {},
    },
}

-- 房间目标
FilterDef.RoomTarget2 =
{
    bStorage = false,    -- 本地存储
    bRuntime = false,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "目标",
        tbList = {},
        tbDefault = {},
    },
}

-- 捏脸码管理
FilterDef.FaceCodeType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部", "仅可用"},
        tbDefault = {2},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少男", "少女"},
        tbDefault = {1},
    },
}

-- 体型码管理
FilterDef.BodyCodeType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少男", "少女"},
        tbDefault = {1},
    },
}

-- 商城-我的外观-发型
FilterDef.CoinShowHairType =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "发型",
        tbList = {"全部", "黑发", "白发", "金发", "套发", "红发", "异色发", "已染色"},
        tbDefault = {1},
    },
}

-- 背包筛选
FilterDef.Bag =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "常用",
        tbList = {"全部", "可账号共享", "可交易", "限时"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "装备类型",
        tbList = {"全部", g_tStrings.STR_ITEM_EQUIP_PVP, g_tStrings.STR_ITEM_EQUIP_PVE, g_tStrings.STR_ITEM_EQUIP_PVX},
        tbDefault = {1},
    },
}

-- 仓库筛选
FilterDef.Storehouse =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储
    bHideConfirmBtn = false,    -- 是否显示确认按钮

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "常用",
        tbList = {"全部", "可账号共享", "可交易", "限时"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "装备类型",
        tbList = {"全部", g_tStrings.STR_ITEM_EQUIP_PVP, g_tStrings.STR_ITEM_EQUIP_PVE, g_tStrings.STR_ITEM_EQUIP_PVX},
        tbDefault = {1},
    },
}

-- 通用侧背包筛选
FilterDef.SideBag =
{
    bStorage = false,           -- 本地存储
    bRuntime = true,            -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "常用",
        tbList = {"全部", "可账号共享", "可交易", "限时"},
        tbDefault = {1},
    },

    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "装备类型",
        tbList = {"全部", g_tStrings.STR_ITEM_EQUIP_PVP, g_tStrings.STR_ITEM_EQUIP_PVE, g_tStrings.STR_ITEM_EQUIP_PVX},
        tbDefault = {1},
    },
}

-- 焦点列表筛选
FilterDef.FocusList = {
    bStorage = true, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "玩家筛选",
        tbList = { "全部", "友方", "敌方" },
        tbDefault = { 1 },
    },
    [2] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "列表排序方式",
        tbList = { "根据距离排序（显示血量）", "根据血量排序（显示血量）", "根据距离排序（显示距离）", "根据血量排序（显示距离）" },
        tbDefault = { 1 },
    }
}

-- 快速换装筛选
FilterDef.ToyBox = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储
    bHideConfirmBtn = true,

    [1] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true, -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "获得方式",
        tbList = g_tStrings.tToyBoxFilterName,
        tbDefault = { 1, 2, 3, 4, 5, 6, 7, 8 },
    },
    [2] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true, -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "资料片",
        tbList = {},
        tbDefault = { 1, 2, 3, 4, 5, 6, 7},
    },
    [3] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true, -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "类型",
        tbList = g_tStrings.tToyBoxTypeName,
        tbDefault = { 1, 2, 3, 4 },
    },
}

------------C界面饰物秘鉴相关------------
-- 挂件筛选
FilterDef.Accessory_Pendant =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "分类",
        tbList = {"全部显示", "特效挂件", "限时挂件", "绝版挂件"},
        tbDefault = {1},
    },
    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "获取途径",
        tbList = {"全部途径", "任务", "成就", "奇遇", "秘境玩法", "对抗玩法", "休闲玩法", "节日活动", "游戏活动", "运营活动", "商城", "其它"},
        tbDefault = {1},
    },
}

-- 特效筛选
FilterDef.Accessory_Effect =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "获取途径",
        tbList = {"全部途径", "称号", "成就", "运营活动", "商城购买"},
        tbDefault = {1},
    },
}

-- 头像筛选
FilterDef.Accessory_Avatar =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "获取途径",
        tbList = {"全部途径", "门派", "商店", "宝箱", "交易行", "商城", "玩法"},
        tbDefault = {1},
    },
}

-- 待机动作筛选
FilterDef.Accessory_IdleAction =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "获取途径",
        tbList = {"全部途径"},
        tbDefault = {1},
    },
}

-- 待机动作筛选
FilterDef.Accessory_SkillSkin =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {"全部显示", "已收集", "未收集"},
        tbDefault = {1},
    },
}

--坐骑外观筛选
FilterDef.RideExterior =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储
    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "类型",
        tbList = {g_tStrings.STR_HORSE_EXTERIOR_FILTER[1], g_tStrings.STR_HORSE_EXTERIOR_FILTER[2], g_tStrings.STR_HORSE_EXTERIOR_FILTER[3], g_tStrings.STR_HORSE_EXTERIOR_FILTER[4]},
        tbDefault = {1},
    },
}
------------C界面挂饰密鉴结束------------

-- 浪客行仓库筛选
FilterDef.LKXWareHouse = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "仓库筛选",
        tbList = { "全部", "药品", "材料", "装备"},
        tbDefault = { 1 },
    },
}

-- 浪客行仓库筛选
FilterDef.LKXWareHouse = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        szTitle = "仓库筛选",
        tbList = { "全部", "药品", "材料", "装备"},
        tbDefault = { 1 },
    },
}

-- 交易行购买武器、暗器、饰物筛选
FilterDef.TradingBuyHouse = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = { "全部", "破败", "普通", "精巧", "卓越", "珍奇", "稀世"},
        tbColorList = {cc.c4b(215, 246, 255, 255), ItemQualityColorC4b[1], ItemQualityColorC4b[2], ItemQualityColorC4b[3],
        ItemQualityColorC4b[4], ItemQualityColorC4b[5], ItemQualityColorC4b[6]},
        tbDefault = { 1 },
    },

    [2] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "装备类型",
        tbList = { "全部套装", "竞技对抗", "秘境挑战", "休闲"},
        tbDefault = { 1 },
        funcCheckVis = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelTradingHouse)
            if script then
                return script:CanShowWeaponType()
            end
            return false
        end
    },

    [3] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "心法",
        tbList = {"易筋经", "洗髓经", "花间游", "离经易道", "傲血战意", "铁牢律", "紫霞功", "太虚剑意", "冰心诀", "云裳心经", "毒经", "补天诀", "天罗诡道", "惊羽诀", "问水诀", "山居剑意", "笑尘诀", "焚影圣诀", "明尊琉璃体", "分山劲", "铁骨衣", "莫问", "相知", "北傲诀", "凌海诀", "隐龙诀", "太玄经", "无方", "灵素", "孤锋诀", "山海心诀", "周天功", "幽罗引"},
        tbDefault = { },
        funcCheckVis = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelTradingHouse)
            if script then
                return script:CanShowWeaponType()
            end
            return false
        end
    },

    [4] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szDynMakeListFuncName = "MakeSchoolNameList", -- 动态生成门派列表
        szTitle = "门派/流派",
        tbList = {},
        tbDefault = {},
        funcCheckVis = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelTradingHouse)
            if script then
                return script:CanShowSchoolType()
            end
            return false
        end
    },
}

-- 交易行购买武器、暗器、饰物筛选
FilterDef.TradingSearchItem = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "装备类型",
        tbList = { "全部套装", "竞技对抗", "秘境挑战", "休闲"},
        tbDefault = { 1 },
        funcCheckVis = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelSearchItem)
            if script then
                return script:CanShowWeaponType()
            end
            return false
        end
    },

    [2] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "心法",
        tbList = {"易筋经", "洗髓经", "花间游", "离经易道", "傲血战意", "铁牢律", "紫霞功", "太虚剑意", "冰心诀", "云裳心经", "毒经", "补天诀", "天罗诡道", "惊羽诀", "问水诀", "山居剑意", "笑尘诀", "焚影圣诀", "明尊琉璃体", "分山劲", "铁骨衣", "莫问", "相知", "北傲诀", "凌海诀", "隐龙诀", "太玄经", "无方", "灵素", "孤锋诀", "山海心诀", "周天功", "幽罗引"},
        tbDefault = { },
        funcCheckVis = function()
            local script = UIMgr.GetViewScript(VIEW_ID.PanelSearchItem)
            if script then
                return script:CanShowWeaponType()
            end
            return false
        end
    },
}


FilterDef.QiYuBox =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "品质",
        tbList = {"全部", "机缘成熟", "机缘未到", "等待探索"},
        tbDefault = {1},
    },
}

FilterDef.SkillShoutList = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "技能类型",
        tbList = {"全部", "傍身招式", "对阵招式", "轻功招式", "绝技招式"},
        tbDefault = {1},
    }
}

FilterDef.OptionalBox =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "拥有",
        tbList = {"全部", "已拥有", "未拥有"},
        tbDefault = {1},
    },
}

-- 招募筛选
FilterDef.TeamRecruit = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        szTitle = "排序方式",
        tbList = {"装分从高到低", "装分从低到高"},
        tbDefault = {1},
    },
    [2] = {
        szType = FilterType.CheckBox,
        bAllowAllOff = true,
        szSubType = FilterSubType.Small,
        bCanSelectAll = true,
        bDefaultSelectAll = true,
        szTitle = "门派",
        tbList = {},
        tbDefault = {},
    },
    [3] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bCanSelectAll = true,
        bDefaultSelectAll = true,
        szTitle = "定位",
        tbList = {},
        tbDefault = {},
    },
}

FilterDef.CoinShopGoodsExterior = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.CoinShopGoodsWeapon = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.CoinShopGoodsHorse = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.CoinShopWardrobeExterior = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.CoinShopWardrobeWeapon = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.CoinShopWardrobeEffect = {
    bStorage = false,
    bRuntime = true,

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "特效",
        tbList = {"脚印", "环身", "左手", "右手"},
        tbDefault = {1},
    },
}

FilterDef.CoinShopGoodsItem = {
    bStorage = false,
    bRuntime = true,
}

FilterDef.ShareStationFilter =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少女", "少男"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "发布时间",
        tbList = {"全部", "今日", "七日内", "三十日内", "九十日内"},
        tbDefault = {1},
    },
    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"全部", "旗舰端", "无界端"},
        tbDefault = {1},
    },
    [4] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        nMaxSelectedCount = 5,
        szTitle = "标签",
        tbList = {}, -- 动态加载 Table_GetShareStationTagList
        tbDefault = {},
    },
}

FilterDef.ShareStationFilter_Exterior =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少女", "少男"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "发布时间",
        tbList = {"全部", "今日", "七日内", "三十日内", "九十日内"},
        tbDefault = {1},
    },
    [3] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"全部", "旗舰端", "无界端"},
        tbDefault = {1},
    },
    [4] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "自定义数据",
        tbList = {"仅看染发"},
        tbDefault = {},
    },
    [5] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        nMaxSelectedCount = 5,
        szTitle = "标签",
        tbList = {}, -- 动态加载 Table_GetShareStationTagList
        tbDefault = {},
    },
}

FilterDef.ShareStationFilter_NoneTime =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少女", "少男"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"全部", "旗舰端", "无界端"},
        tbDefault = {1},
    },
    [3] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        nMaxSelectedCount = 5,
        szTitle = "标签",
        tbList = {}, -- 动态加载 Table_GetShareStationTagList
        tbDefault = {},
    },
}

FilterDef.ShareStationFilter_NoneTime_Exterior =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "体型",
        tbList = {"全部", "成男", "成女", "少女", "少男"},
        tbDefault = {1},
    },
    [2] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "来源",
        tbList = {"全部", "旗舰端", "无界端"},
        tbDefault = {1},
    },
    [3] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        szTitle = "自定义数据",
        tbList = {"仅看染发"},
        tbDefault = {},
    },
    [4] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        nMaxSelectedCount = 5,
        szTitle = "标签",
        tbList = {}, -- 动态加载 Table_GetShareStationTagList
        tbDefault = {},
    },
}

FilterDef.ShareStationHeatRank =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "排序",
        tbList = {"总热度", "三十日热度", "七日热度", "最新"},
        tbDefault = {1},
    },
}

FilterDef.ShareStationTimeRange =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "上传时间",
        tbList = {"从新到旧", "从旧到新"},
        tbDefault = {1},
    },
}

FilterDef.ShareStationTimeRange_Author =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "排序",
        tbList = {"总热度", "最新"},
        tbDefault = {1},
    },
}

FilterDef.CameraSize =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Big,
        bAllowAllOff = false,
        bResponseImmediately = false,
        szTitle = "尺寸",
        tbList = {"全屏", "9:16", "1:1", "16:9", "3:4"},
        tbDefault = {1},
    },
}

FilterDef.CoinShopSubSet = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = true,
        bCanSelectAll = false,   -- 是否支持全选
        szTitle = "包身状态切换",
        szSubTitle = "（仅预览）",
        tbList = { "包身状态", "散件状态"},
        tbDefault = { 1 },
        funcCheckVis = function()
            return CoinShopData.GetCanReplace()
        end
    },

    [2] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true,   -- 是否支持全选
        szTitle = "上衣部件显示",
        tbList = {"飘带一", "飘带二", "衣袖一", "衣袖二", "衣袖三", "装饰一", "装饰二", "装饰三"},
        tbDefault = { },
        funcCheckVis = function()
            local bCanHideChest, bCanHideHair = ExteriorCharacter.GetCanHideSubsetFlag()
            return bCanHideChest
        end
    },

    [3] = {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = true,
        bCanSelectAll = true,   -- 是否支持全选
        szTitle = "发型部件显示",
        tbList = {"发冠一", "发冠二", "发冠三", "发冠四", "发冠五", "发饰一", "发饰二", "发饰三"},
        tbDefault = { },
        funcCheckVis = function()
            local bCanHideChest, bCanHideHair = ExteriorCharacter.GetCanHideSubsetFlag()
            return bCanHideHair
        end
    },
}

FilterDef.PhotoExteriorData = {
    bStorage = false, -- 本地存储
    bRuntime = true, -- 运行时存储

    [1] = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bAllowAllOff = false,
        bResponseImmediately = false,
        bCanSelectAll = false,   -- 是否支持全选
        szTitle = "筛选",
        tbList = { "全部", "已拥有", "背包中", "商城可购买", "其他"},
        tbDefault = { 1 },
    },
}

-- 扬刀大会-祝福卡
FilterDef.BlessCard =
{
    bStorage = false,    -- 本地存储
    bRuntime = true,    -- 运行时存储

    [1] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "星级",
        tbList = { "四星", "三星", "二星", "一星" },
        tbDefault = {1, 2, 3, 4},
    },

    [2] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "技能类型",
        tbList = { "主动技能", "被动技能" },
        tbDefault = {1, 2},
    },

    [3] =
    {
        szType = FilterType.CheckBox,
        szSubType = FilterSubType.Small,
        bAllowAllOff = true,
        bResponseImmediately = false,
        bCanSelectAll = true,   -- 是否支持全选
        bDefaultSelectAll = true,
        szTitle = "卦象类型",
        tbList = { "单灵卦象", "双灵重卦" },
        tbDefault = {1, 2},
    },

    [4] =
    {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        bResponseImmediately = false,
        szTitle = "卦象状态",
        tbList = { "全部", "可赋灵", "已赋灵" },
        tbDefault = {1},
    },
}




























































for szKey, oneDef in pairs(FilterDef) do
    oneDef = setmetatable(oneDef, {
         __index = {
            Key = szKey,

            Reset = function()
                -- 清除运行时
                oneDef.tbRuntime = nil
            end,

            GetRunTime = function()
                return oneDef.tbRuntime
            end,

            SetRunTime = function(tbSelected)
                if oneDef.bRuntime then
                    oneDef.tbRuntime = tbSelected
                end
            end,

            ReadFromStorage = function()
                local tbStorage = Storage.Filter[szKey]
                return tbStorage
            end,

            WriteToStorage = function(tbSelected)
                if oneDef.bStorage then
                    Storage.Filter[szKey] = tbSelected
                    Storage.Filter.Flush()
                end
            end,
         }
    })
end




function FilterDef.MakeForceNameList()
    if FilterDef.tbForceNameList then
        return FilterDef.tbForceNameList
    end

    FilterDef.tbForceNameList = {}
    FilterDef.tbForceIDList = {}
    local tForceList = Table_GetAllForceUI()
    for nForceID, v in pairs(tForceList) do
        table.insert(FilterDef.tbForceNameList, v.szName)
        table.insert(FilterDef.tbForceIDList, nForceID)
    end

    return FilterDef.tbForceNameList
end

function FilterDef.GetForceIDByIndex(nIndex)
    if not FilterDef.tbForceIDList then
        FilterDef.MakeForceNameList()
    end
    return FilterDef.tbForceIDList[nIndex] or 0
end


function FilterDef.MakeSchoolNameList()
    if FilterDef.tbSchoolNameList then
        return FilterDef.tbSchoolNameList
    end

    FilterDef.tbSchoolNameList = {}
    FilterDef.tbSchoolTypeList = {}

    local tbSortedSchoolType = {}
    for nSchoolType, v in pairs(SCHOOL_TYPE) do
        table.insert(tbSortedSchoolType, nSchoolType)
    end
    table.sort(tbSortedSchoolType, function(a, b)
        return a < b
    end)

    for nSchoolType, v in ipairs(tbSortedSchoolType) do
        -- 江湖和藏剑山居不加入筛选
        if nSchoolType ~= SCHOOL_TYPE.JIANG_HU and nSchoolType ~= SCHOOL_TYPE.CANG_JIAN_SHAN_JU then
            table.insert(FilterDef.tbSchoolNameList, g_tStrings.tSchoolTitle[nSchoolType])
            table.insert(FilterDef.tbSchoolTypeList, nSchoolType)
        end
    end

    return FilterDef.tbSchoolNameList
end

function FilterDef.GetSchoolTypeByIndex(nIndex)
    if not FilterDef.tbSchoolTypeList then
        FilterDef.MakeSchoolNameList()
    end
    return FilterDef.tbSchoolTypeList[nIndex] or 0
end
