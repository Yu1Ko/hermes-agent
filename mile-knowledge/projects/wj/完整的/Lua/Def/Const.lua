
--[[
    Const.lua
    存放一些常量配置
    手写
]]

local GLOBAL = GLOBAL
local nMetreLength = GLOBAL.LOGICAL_CELL_CM_LENGTH / GLOBAL.CELL_LENGTH / 100
local nMetreHeight = GLOBAL.LOGICAL_CELL_CM_LENGTH / GLOBAL.CELL_LENGTH / 100 / 8

Const =
{
    ITEM_LEFT_HOUR = 48,
    ITEM_LIGHT_HINT_HOUR = 24,

    IntervalCastSkillTime = 1 / 16,

    -- 玩法进入倒计时
    MAX_AUTO_ENTER_FIELD_OVERTIME = 10,
    MAX_BATTLE_FIELD_OVERTIME = 30,
    MAX_TONG_BATTLE_FIELD_OVERTIME = 60, --秒

    BalloonFadeTime = 3,            -- 泡泡对话框显示时间
    kEnableDynTab = true,           -- 开启动态tab表（表项按需加载）

    -- UI背景模糊效果参数
    UIBgBlur = {
        bEnable = true,
        nScale = 0.2,       -- 截屏尺寸缩放：[0.1 ~ 1]
        nRadius = 12,       -- 高斯模糊半径：[1 ~ 5] 暂时解开限制
        nSampleNum = 12,    -- 高斯模糊采样：[1 ~ 5] 暂时解开限制
    },

    -- 逻辑高度单位与逻辑水平单位的转换系数
    kZpointToXy = 8,
    -- 逻辑水平距离转换为米
    kMetreLength = nMetreLength,
    -- 垂直距离转换为米
    kMetreHeight = nMetreHeight,

    --SkillCacheCDTime = 1,

    -- 特效关闭时间
    FullScreenSFXTime = {
        ["SFX_TRANSMISSION_GROUND1"] = 6.5,
    },

    -- 黑屏转场特效持续时间
    FullScreenTransitionTime = 1,

    -- 选点技能特效配置
    kAreaSelectSfxs = {
        [1] = {
            nDragSfxRadius = 5 / nMetreLength,          -- 特效半径
            nCircleSfxRadius = 10 / nMetreLength,       -- 圆圈范围半径
            szDragSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_圆_5米_蓝01_贴地.pss"),
            szCircleSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_圆_10米_蓝01.pss"),
        },
        [2] = {
            bRotate = true,                             -- 是否旋转
            bBoxArea = true,                            -- 是否矩形框
            nDragSfxLong = 10 / nMetreLength,           -- 特效长
            nDragSfxWidth = 2 / nMetreLength,           -- 特效宽
            nCircleSfxRadius = 10 / nMetreLength,       -- 圆圈范围半径
            szDragSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_刀墙_10米_蓝01.pss"),
            szCircleSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_圆_10米_蓝01.pss"),
        },
        [3] = {
            bRotate = true,                             -- 是否旋转
            bBoxArea = true,                            -- 是否矩形框
            nDragSfxLong = 2 / nMetreLength,            -- 特效长
            nDragSfxWidth = 10 / nMetreLength,          -- 特效宽
            nCircleSfxRadius = 10 / nMetreLength,       -- 圆圈范围半径
            szDragSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_刀墙_10米_蓝02.pss"),
            szCircleSfx = UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_圆_10米_蓝01.pss"),
        },
    },

    -- 警告框特效配置
    kWarningBox = {
        nCircleSfxRadius = 5 / nMetreLength,     -- 圆形特效半径(逻辑单位)
        nBoxSfxWidth = 10 / nMetreLength,        -- 方形特效宽度(逻辑单位)
        tSfxs = {
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_方_10米_蓝01.pss"),    -- 方形
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_圆_5米_蓝01.pss"),     -- 圆形
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_扇_60度_蓝01.pss"),    -- 60°弧形
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_扇_120度_蓝01.pss"),   -- 120°弧形
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_扇_180度_蓝01.pss"),   -- 180°弧形
            UTF8ToGBK("data/source/other/HD特效/技能/Pss/发招/X_选择_方_10米_蓝02.pss"),    -- 方形带箭头
        },
    },

    -- MiniScene镜头操作相关
    -- PC端
    MiniSceneDragFactorX = 1.0, --左右旋转的速度，越大越快
    MiniSceneZoomFactor = 0.5,  --每次滚轮滚动缩放比例
    -- 移动端
    MiniSceneMobileDragFactorX = 1.5, --左右旋转的速度，越大越快
    MiniSceneMobileZoomFactor = 1.5, -- 手指拉动摄像机缩放比例

    MiniScene = {
        -- 坐骑界面缩放值
        RideScale = 0.7,

        -- 秘境BOSS
        DungeonDetailView = {
            CameraConfig = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true},
            ModelPos = {0, 12, 0},
            fYaw = 0.8,
        },

        -- 成就奖励
        AwardGatherView = {
            -- 角色位置
            tbPos = {-120, 12, -30},
            --挂件镜头和角色旋转值
            tbModelPreviewInfo = {
                [ROLE_TYPE.STANDARD_MALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3, --默认nYaw，腰部nYaw，背部nYaw
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.STANDARD_FEMALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_BOY] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.9, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_GIRL] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 2.4, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
            },
            -- 家具位置默认值
            tbFurnitureModelPos = {0, 12, 0},
            -- 家具缩放默认值
            fFurnitureModelScale = 0.35,
            -- 家具旋转默认值
            fFurnitureModelYaw = 1.0,
            -- 家具镜头
            tbFurnitureCamare  = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },    --家具模型
        },

        -- 全屏商店
        StoreView = {
            -- 角色位置
            tbPos = {-120, 12, -30},
            --挂件镜头和角色旋转值
            tbModelPreviewInfo = {
                [ROLE_TYPE.STANDARD_MALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3, --默认nYaw，腰部nYaw，背部nYaw
                    tbCamere = { -400, 120, -110, 0, 1114, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.STANDARD_FEMALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3,
                    tbCamere = { -400, 120, -110, 0, 1114, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_BOY] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.9, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 120, -110, 0, 1114, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_GIRL] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 2.4, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 120, -110, 0, 1114, -30 , 0.79, 1.78, 20, 40000, true },
                },
            },
            -- 家具位置默认值
            tbFurnitureModelPos = {0, 12, 0},
            -- 家具缩放默认值
            fFurnitureModelScale = 0.35,
            -- 家具旋转默认值
            fFurnitureModelYaw = 1.0,
            -- 家具镜头
            tbFurnitureCamare  = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },    --家具模型

            -- 宠物
            tbPetPos = {0, 16, 0},
            fPetYaw = 0.8,
            tbPetCamare = { -400, 106, -110, 0, 100, -30 , 0.79, 1.78, 20, 40000, true},
        },

        -- 运营中心
        OperationCenter = {
            -- 角色位置
            tbPos = {-120, 12, -30},
            --挂件镜头和角色旋转值
            tbModelPreviewInfo = {
                [ROLE_TYPE.STANDARD_MALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3, --默认nYaw，腰部nYaw，背部nYaw
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.STANDARD_FEMALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_BOY] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.9, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_GIRL] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 2.4, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },
                },
            },
            -- 家具位置默认值
            tbFurnitureModelPos = {0, 12, 0},
            -- 家具缩放默认值
            fFurnitureModelScale = 0.35,
            -- 家具旋转默认值
            fFurnitureModelYaw = 1.0,
            -- 家具镜头
            tbFurnitureCamare  = { -400, 116, -110, 0, 106, -30 , 0.79, 1.78, 20, 40000, true },    --家具模型

            -- 宠物
            tbPetPos = {0, 16, 0},
            fPetYaw = 0.8,
            tbPetCamare = { -400, 106, -110, 0, 100, -30 , 0.79, 1.78, 20, 40000, true},
        },

        -- 声望奖励
        RewardView = {
            -- 知交位置
            tbAccompanyPos = {-70, 12, -40},
            -- 知交旋转
            fAccompanyYaw = 1.3,
            -- 知交镜头
            tbAccompanyCamare = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true},
            -- 角色位置
            tbPos = {-90, 12, -30},
            --挂件镜头和角色旋转值
            tbModelPreviewInfo = {
                [ROLE_TYPE.STANDARD_MALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3,  --默认nYaw，腰部nYaw，背部nYaw
                    tbCamere = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.STANDARD_FEMALE] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.7, [EQUIPMENT_SUB.BACK_EXTEND] = 4.3,
                    tbCamere = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_BOY] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 1.9, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },
                },
                [ROLE_TYPE.LITTLE_GIRL] = {
                    nYaw = 1.7, [EQUIPMENT_SUB.WAIST_EXTEND] = 2.4, [EQUIPMENT_SUB.BACK_EXTEND] = 4.5,
                    tbCamere = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },
                },
            },
            -- 家具位置默认值
            tbFurnitureModelPos = {0, 12, 0},
            -- 家具缩放默认值
            fFurnitureModelScale = 0.35,
            -- 家具旋转默认值
            fFurnitureModelYaw = 1.0,
            -- 家具镜头
            tbFurnitureCamare  = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },    --家具模型
        },

        -- 红尘侠影
        PartnerView = {
            -- 主界面镜头
            tbMainCamera = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },

            -- 共鸣配置初始位置
            tbFetterBasePos = {0, 12, 120},
            -- 共鸣配置Z轴偏移位置
            fFetterOffsetPosZ = -160,
            -- 共鸣配置初始旋转
            fFetterBaseYaw = 1.56,
            -- 共鸣配置偏移旋转
            fFetterOffsetYaw = 0.32,
            -- 共鸣配置镜头
            tbFetterCamera = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },

            -- 共鸣编队初始位置-单个编队
            tbTeamBasePos = {0, 12, -100},
            -- 共鸣编队初始位置-快捷编队
            tbQuickSetTeamBasePos = {0, 12, 0},
            -- 共鸣编队Z轴偏移位置
            fTeamOffsetPosZ = -120,
            -- 共鸣编队初始旋转
            fTeamBaseYaw = 1.56,
            -- 共鸣编队偏移旋转
            fTeamOffsetYaw = 0.32,
            -- 共鸣编队镜头
            tbTeamCamera = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },

            -- 助战镜头
            tbHelpCamera = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true },
        },

        -- 查看他人
        OtherCharacterView = {
            -- 角色位置、旋转、镜头
            tbPos = {10, 0, 0},
            fYaw = 0.12,
            tbCamare = { -50, 100, -772, 0, 80, 78, 0.34, 1.78, 20, 40000, true},

            -- 坐骑位置、镜头
            tbRidePos = {10, 0, 0},
            fRideYaw = 0.76,
            tbRideCamare = { -50, 100, -722, 0, 80, 78, 0.46, 1.78, 20, 40000, true},
        },

        -- 队伍面板
        TeamGroupView = {
            -- 根据屏幕宽高比配置3档角色坐标，按实际宽高比算差值得出最终角色坐标
            tbModelPos = {
                [1] = {
                    [1] = { 16, 12, 136, 1.1},
                    [2] = { 36, 12, 32, 1.3},
                    [3] = { 56, 12, -72, 1.5},
                    [4] = { 86, 12, -176, 1.7},
                    [5] = { 96, 12, -274, 1.7},
                    nFovy = 0.79,
                    nAspect = 2,
                },
                [2] = {
                    [1] = { 86, 12, 150, 1.1},
                    [2] = { 106, 12, 44, 1.3},
                    [3] = { 126, 12, -50, 1.5},
                    [4] = { 146, 12, -156, 1.7},
                    [5] = { 166, 12, -258, 1.7},
                    nFovy = 0.79,
                    nAspect = 1.5,
                },
                [3] = {
                    [1] = { 300, 12, 184, 1.1},
                    [2] = { 310, 12, 84, 1.3},
                    [3] = { 346, 12, -10, 1.5},
                    [4] = { 366, 12, -108, 1.7},
                    [5] = { 386, 12, -198, 1.7},
                    nFovy = 0.79,
                    nAspect = 1.0,
                },
            },
            tbCamare = { -400, 106, -110, 0, 100, -30, 0.79, 1.78, 20, 40000 },
        },

        -- 驯养
        DomesticateView = {
            -- 坐骑位置、镜头
            tbRidePos = {0, 12, 0},
            tbRideCamare = { -400, 106, -110, 0, 100, -30 , 0.79, 1.78, 20, 40000, true},

            -- 宠物
            tbPetPos = {0, 16, 0},
            fPetYaw = 0.8,
            tbPetCamare = { -400, 106, -110, 0, 100, -30 , 0.79, 1.78, 20, 40000, true},
        },

        -- 阵营首领简介
        CollectionDungeonView = {
            CameraConfig = { -400, 126, -110, 0, 116, -30 , 0.79, 1.78, 20, 40000, true},
            ModelPos = {0, 12, 0},
            fYaw = 0.8,
        },
    },

    -- 通用场景
    COMMON_SCENE = "data\\source\\maps\\mb_通用背景_001\\mb_通用背景_001.jsonmap",
    -- 商城场景
    SHOP_SCENE = "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap",
    -- 是否使用新的登录场景
    USE_NEW_LOGIN_SCENE = true,
    -- 是否显示快捷交互键位名
    bShowShortcutInterationKeyName = true,
    -- 是否开启GM场景双指交互
    bOpenGMSceneTouchInteration = false,
    -- 视频网络预加载帧数量（默认30，即1s）
    nVideoNetPreloadFrameCount = 30,
    -- 创角视频音量大小系数
    fCreateVideoVolume = 0.65,

    -- 商店相关
    Shop = {
        EquipmentShopInfo = {
            ["名剑商店"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_MingJian", nSystemOpenID = 59, bShowRecEquipBtn = true,},
            ["阵营商店"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_ZhanJie", nSystemOpenID = 60, bShowRecEquipBtn = true,},
            ["秘境商店"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_XiaXing", nSystemOpenID = 61, bShowRecEquipBtn = true,},
            ["龙门绝境"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_FeiShaLing", nSystemOpenID = 63, bShowRecEquipBtn = true,},
            ["浪客行商店"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_LangKeXing", nSystemOpenID = 64,},
            ["绝世装备"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_JueShiZhuangBei", nSystemOpenID = 65,},
            ["休闲商店"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_XiuXian", nSystemOpenID = 62, bShowRecEquipBtn = true,},
            ["家园"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_JiaYuan", nSystemOpenID = 0,},
            ["其他"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_QiTa", nSystemOpenID = 66,},
            ["活动"] = {szImg = "UIAtlas2_EquipmentShop_EquipmentShop_HuoDong", nSystemOpenID = 0,},
        }
    },
    -- 百战异闻录相关
    MonsterBook = {
        -- 需要显示收集按钮(点击打开百战技能界面)的道具
        UpgradeSkillItemMap = {
            [45845] = true,
            [50769] = true,
            [66154] = true,
            [75452] = true,
        },
    },

    ReportType = {
        Render = 1,
        Touch = 2,
    },
    EnableDesignationDecoration = false, -- 是否开启称号系统

}
