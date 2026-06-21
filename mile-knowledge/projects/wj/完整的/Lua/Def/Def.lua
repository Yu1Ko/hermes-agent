--[[
    Def.lua
    存放一些逻辑相关的枚举类型
    手写
]]

FORCE_TYPE = {
    JIANG_HU = 0, -- 江湖
    SHAO_LIN = 1, -- 少林
    WAN_HUA = 2, -- 万花
    TIAN_CE = 3, -- 天策
    CHUN_YANG = 4, -- 纯阳
    QI_XIU = 5, -- 七秀
    WU_DU = 6, -- 五毒
    TANG_MEN = 7, -- 唐门
    CANG_JIAN = 8, -- 藏剑
    GAI_BANG = 9, -- 丐帮
    MING_JIAO = 10, -- 明教
    CANG_YUN = 21, -- 苍云
    CHANG_GE = 22, -- 长歌
    BA_DAO = 23, -- 霸刀
    PENG_LAI = 24, -- 蓬莱
    LING_XUE = 25, -- 凌雪
    YAN_TIAN = 211, -- 衍天
    YAO_ZONG = 212, -- 药宗
    DAO_ZONG = 213, -- 刀宗
    WAN_LING = 214, -- 万灵
    DUAN_SHI = 215,--段式
    WU_XIANG  = 221, -- 无相
}

SCHOOL_TYPE =
{
    JIANG_HU  = 0 , -- 江湖
    TIAN_CE   = 1 , -- 天策
    CHUN_YANG = 2 , -- 纯阳
    SHAO_LIN  = 3 , -- 少林
    WAN_HUA   = 4 , -- 万花
    QI_XIU    = 5 , -- 七秀
    CANG_JIAN_WEN_SHUI = 6 , -- 藏剑问水
    CANG_JIAN_SHAN_JU = 7, -- 藏剑山居
    WU_DU     = 8 , -- 五毒
    TANG_MEN  = 9 , -- 唐门
    MING_JIAO = 10, -- 明教
    GAI_BANG  = 11 , -- 丐帮
    CANG_YUN  = 12, -- 苍云
    CHANG_GE  = 13, -- 长歌
    BA_DAO    = 14, -- 霸刀
    PENG_LAI  = 15, -- 蓬莱
    LING_XUE  = 16, -- 凌雪
    YAN_TIAN  = 17, -- 衍天
    YAO_ZONG  = 18, -- 药宗
    DAO_ZONG  = 19, -- 刀宗
    WAN_LING  = 20, -- 万灵
    DUAN_SHI  = 21,-- 段氏
    WU_XIANG  = 22, -- 无相
}

BELONG_SCHOOL_TYPE =
{
    JIANG_HU     = 0,     -- 江湖
    TIAN_CE     = 1,      -- 天策
    WAN_HUA     = 2,      -- 万花
    CHUN_YANG   = 3,      -- 纯阳
    QI_XIU      = 4,      -- 七秀
    SHAO_LIN    = 5,      -- 少林
    CANG_JIAN   = 6,      -- 藏剑
    GAI_BANG    = 7,      -- 丐帮
    MING_JIAO   = 8,      -- 明教
    WU_DU       = 9,      -- 五毒
    TANG_MEN    = 10,     -- 唐门
    CANG_YUN    = 18,     -- 苍云
    CHANG_GE    = 19,     -- 长歌
    BA_DAO      = 20,     -- 霸刀
    PENG_LAI    = 21,     -- 蓬莱
    LING_XUE    = 22,     -- 凌雪
    YAN_TIAN    = 23,     -- 衍天
    YAO_ZONG    = 24,     -- 药宗
    DAO_ZONG    = 26,     -- 刀宗
    WAN_LING    = 29,	  -- 万灵
    DUAN_SHI    = 38,	  -- 段氏
    WU_XIANG    = 39,	  -- 无相
}

ROLE_TYPE = {
    STANDARD_MALE = 1,
    STANDARD_FEMALE = 2,
    STRONG_MALE = 3,
    SEXY_FEMALE = 4,
    LITTLE_BOY = 5,
    LITTLE_GIRL = 6,
}

---用于创角
KUNGFU_ID = {
    JIANG_HU = 0, -- 江湖
    SHAO_LIN = 1, -- 少林
    WAN_HUA = 2, -- 万花
    TIAN_CE = 3, -- 天策
    CHUN_YANG = 4, -- 纯阳
    QI_XIU = 5, -- 七秀
    WU_DU = 6, -- 五毒
    TANG_MEN = 7, -- 唐门
    CANG_JIAN = 8, -- 藏剑
    GAI_BANG = 10, -- 丐帮
    MING_JIAO = 9, -- 明教
    CANG_YUN = 11, -- 苍云
    CHANG_GE = 12, -- 长歌
    BA_DAO = 13, -- 霸刀
    PENG_LAI = 14, -- 蓬莱
    LING_XUE = 15, -- 凌雪
    YAN_TIAN = 16, -- 衍天
    YAO_ZONG = 17, -- 药宗
    DAO_ZONG = 18, -- 刀宗
    WAN_LING = 19, --万灵
    DUAN_SHI = 20,--还不确定段式是否是20
}

KUNGFU_IDToSchool = {
    [KUNGFU_ID.SHAO_LIN] = "sl",
    [KUNGFU_ID.WAN_HUA] = "wh",
    [KUNGFU_ID.TIAN_CE] = "tc",
    [KUNGFU_ID.CHUN_YANG] = "cy",
    [KUNGFU_ID.QI_XIU] = "qx",
    [KUNGFU_ID.WU_DU] = "wd",
    [KUNGFU_ID.TANG_MEN] = "tm",
    [KUNGFU_ID.CANG_JIAN] = "cj",
    [KUNGFU_ID.GAI_BANG] = "gb",
    [KUNGFU_ID.MING_JIAO] = "mj",
    [KUNGFU_ID.CANG_YUN] = "cangyun",
    [KUNGFU_ID.CHANG_GE] = "changge",
    [KUNGFU_ID.BA_DAO] = "badao",
    [KUNGFU_ID.PENG_LAI] = "penglai",
    [KUNGFU_ID.LING_XUE] = "lxg",
    [KUNGFU_ID.YAN_TIAN] = "ytz",
    [KUNGFU_ID.YAO_ZONG] = "btyz",
    [KUNGFU_ID.DAO_ZONG] = "dz",
    [KUNGFU_ID.WAN_LING] = "wl",
    [KUNGFU_ID.DUAN_SHI] = "ds",
}

ForceTypeToSchool = {
    [FORCE_TYPE.SHAO_LIN] = "sl",
    [FORCE_TYPE.WAN_HUA] = "wh",
    [FORCE_TYPE.TIAN_CE] = "tc",
    [FORCE_TYPE.CHUN_YANG] = "cy",
    [FORCE_TYPE.QI_XIU] = "qx",
    [FORCE_TYPE.WU_DU] = "wd",
    [FORCE_TYPE.TANG_MEN] = "tm",
    [FORCE_TYPE.CANG_JIAN] = "cj",
    [FORCE_TYPE.GAI_BANG] = "gb",
    [FORCE_TYPE.MING_JIAO] = "mj",
    [FORCE_TYPE.CANG_YUN] = "cangyun",
    [FORCE_TYPE.CHANG_GE] = "changge",
    [FORCE_TYPE.BA_DAO] = "badao",
    [FORCE_TYPE.PENG_LAI] = "penglai",
    [FORCE_TYPE.LING_XUE] = "lxg",
    [FORCE_TYPE.YAN_TIAN] = "ytz",
    [FORCE_TYPE.YAO_ZONG] = "btyz",
    [FORCE_TYPE.DAO_ZONG] = "dz",
    [FORCE_TYPE.DUAN_SHI] = "ds",
}

SCHOOL_TYPE_TO_NAME = {
    [SCHOOL_TYPE.SHAO_LIN] = "sl",
    [SCHOOL_TYPE.WAN_HUA] = "wh",
    [SCHOOL_TYPE.TIAN_CE] = "tc",
    [SCHOOL_TYPE.CHUN_YANG] = "cy",
    [SCHOOL_TYPE.QI_XIU] = "qx",
    [SCHOOL_TYPE.WU_DU] = "wd",
    [SCHOOL_TYPE.TANG_MEN] = "tm",
    [SCHOOL_TYPE.CANG_JIAN_WEN_SHUI] = "cj",
    [SCHOOL_TYPE.CANG_JIAN_SHAN_JU] = "cj",
    [SCHOOL_TYPE.GAI_BANG] = "gb",
    [SCHOOL_TYPE.MING_JIAO] = "mj",
    [SCHOOL_TYPE.CANG_YUN] = "cangyun",
    [SCHOOL_TYPE.CHANG_GE] = "changge",
    [SCHOOL_TYPE.BA_DAO] = "badao",
    [SCHOOL_TYPE.PENG_LAI] = "penglai",
    [SCHOOL_TYPE.LING_XUE] = "lxg",
    [SCHOOL_TYPE.YAN_TIAN] = "ytz",
    [SCHOOL_TYPE.YAO_ZONG] = "btyz",
    [SCHOOL_TYPE.DAO_ZONG] = "dz",
    [SCHOOL_TYPE.DUAN_SHI] = "ds",
}

KUNGFU_ID_SCHOOL_TYPE = {
    [KUNGFU_ID.JIANG_HU] = SCHOOL_TYPE.JIANG_HU,
    [KUNGFU_ID.SHAO_LIN] = SCHOOL_TYPE.SHAO_LIN,
    [KUNGFU_ID.WAN_HUA] = SCHOOL_TYPE.WAN_HUA,
    [KUNGFU_ID.TIAN_CE] = SCHOOL_TYPE.TIAN_CE,
    [KUNGFU_ID.CHUN_YANG] = SCHOOL_TYPE.CHUN_YANG,
    [KUNGFU_ID.QI_XIU] = SCHOOL_TYPE.QI_XIU,
    [KUNGFU_ID.WU_DU] = SCHOOL_TYPE.WU_DU,
    [KUNGFU_ID.TANG_MEN] = SCHOOL_TYPE.TANG_MEN,
    [KUNGFU_ID.CANG_JIAN] = SCHOOL_TYPE.CANG_JIAN_WEN_SHUI,
    [KUNGFU_ID.GAI_BANG] = SCHOOL_TYPE.GAI_BANG,
    [KUNGFU_ID.MING_JIAO] = SCHOOL_TYPE.MING_JIAO,
    [KUNGFU_ID.CANG_YUN] = SCHOOL_TYPE.CANG_YUN,
    [KUNGFU_ID.CHANG_GE] = SCHOOL_TYPE.CHANG_GE,
    [KUNGFU_ID.BA_DAO] = SCHOOL_TYPE.BA_DAO,
    [KUNGFU_ID.LING_XUE] = SCHOOL_TYPE.LING_XUE,
    [KUNGFU_ID.YAN_TIAN] = SCHOOL_TYPE.YAN_TIAN,
    [KUNGFU_ID.YAO_ZONG] = SCHOOL_TYPE.YAO_ZONG,
    [KUNGFU_ID.DAO_ZONG] = SCHOOL_TYPE.DAO_ZONG,
    [KUNGFU_ID.WAN_LING] = SCHOOL_TYPE.WAN_LING,
    [KUNGFU_ID.PENG_LAI] = SCHOOL_TYPE.PENG_LAI,
    [KUNGFU_ID.DUAN_SHI] = SCHOOL_TYPE.DUAN_SHI,
}

FORCE_TYPE_TO_KUNGFU_ID = {
    [FORCE_TYPE.JIANG_HU] = KUNGFU_ID.JIANG_HU,
    [FORCE_TYPE.SHAO_LIN] = KUNGFU_ID.SHAO_LIN,
    [FORCE_TYPE.WAN_HUA] = KUNGFU_ID.WAN_HUA,
    [FORCE_TYPE.TIAN_CE] = KUNGFU_ID.TIAN_CE,
    [FORCE_TYPE.CHUN_YANG] = KUNGFU_ID.CHUN_YANG,
    [FORCE_TYPE.QI_XIU] = KUNGFU_ID.QI_XIU,
    [FORCE_TYPE.WU_DU] = KUNGFU_ID.WU_DU,
    [FORCE_TYPE.TANG_MEN] = KUNGFU_ID.TANG_MEN,
    [FORCE_TYPE.CANG_JIAN] = KUNGFU_ID.CANG_JIAN,
    [FORCE_TYPE.GAI_BANG] = KUNGFU_ID.GAI_BANG,
    [FORCE_TYPE.MING_JIAO] = KUNGFU_ID.MING_JIAO,
    [FORCE_TYPE.CANG_YUN] = KUNGFU_ID.CANG_YUN,
    [FORCE_TYPE.CHANG_GE] = KUNGFU_ID.CHANG_GE,
    [FORCE_TYPE.BA_DAO] = KUNGFU_ID.BA_DAO,
    [FORCE_TYPE.LING_XUE] = KUNGFU_ID.LING_XUE,
    [FORCE_TYPE.YAN_TIAN] = KUNGFU_ID.YAN_TIAN,
    [FORCE_TYPE.YAO_ZONG] = KUNGFU_ID.YAO_ZONG,
    [FORCE_TYPE.DAO_ZONG] = KUNGFU_ID.DAO_ZONG,
    [FORCE_TYPE.WAN_LING] = KUNGFU_ID.WAN_LING,
    [FORCE_TYPE.DUAN_SHI] = KUNGFU_ID.DUAN_SHI,
}

KUNGFU_ID_FORCE_TYPE = {
    [KUNGFU_ID.JIANG_HU] = FORCE_TYPE.JIANG_HU,
    [KUNGFU_ID.SHAO_LIN] = FORCE_TYPE.SHAO_LIN,
    [KUNGFU_ID.WAN_HUA] = FORCE_TYPE.WAN_HUA,
    [KUNGFU_ID.TIAN_CE] = FORCE_TYPE.TIAN_CE,
    [KUNGFU_ID.CHUN_YANG] = FORCE_TYPE.CHUN_YANG,
    [KUNGFU_ID.QI_XIU] = FORCE_TYPE.QI_XIU,
    [KUNGFU_ID.WU_DU] = FORCE_TYPE.WU_DU,
    [KUNGFU_ID.TANG_MEN] = FORCE_TYPE.TANG_MEN,
    [KUNGFU_ID.CANG_JIAN] = FORCE_TYPE.CANG_JIAN,
    [KUNGFU_ID.GAI_BANG] = FORCE_TYPE.GAI_BANG,
    [KUNGFU_ID.MING_JIAO] = FORCE_TYPE.MING_JIAO,
    [KUNGFU_ID.CANG_YUN] = FORCE_TYPE.CANG_YUN,
    [KUNGFU_ID.CHANG_GE] = FORCE_TYPE.CHANG_GE,
    [KUNGFU_ID.BA_DAO] = FORCE_TYPE.BA_DAO,
    [KUNGFU_ID.LING_XUE] = FORCE_TYPE.LING_XUE,
    [KUNGFU_ID.YAN_TIAN] = FORCE_TYPE.YAN_TIAN,
    [KUNGFU_ID.YAO_ZONG] = FORCE_TYPE.YAO_ZONG,
    [KUNGFU_ID.DAO_ZONG] = FORCE_TYPE.DAO_ZONG,
    [KUNGFU_ID.WAN_LING] = FORCE_TYPE.WAN_LING,
    [KUNGFU_ID.PENG_LAI] = FORCE_TYPE.PENG_LAI,
    [KUNGFU_ID.DUAN_SHI] = FORCE_TYPE.DUAN_SHI,

}

POSE_TYPE = {
    SWORD = 1, --藏剑姿态
    SHIELD = 2,
    DOUBLE_BLADE = 1, --霸刀姿态
    BROADSWORD = 2,
    SHEATH_KNIFE = 3,
    SWORD_DANCE = 1, --七秀剑舞
    GAOSHANLIUSHUI = 1, --长歌曲风
    YANGCUNBAIXUE = 2,
    MEIHUASHANNONG = 3,
    PINGSHALUOYAN = 3,
    TIANRENHEYI = 2,
    SINGLEKNIFE = 1, --单刀
    DOUBLEKNIFE = 2, --双手持刀
    SINGLEKNIFEIN = 3, --刀在鞘里，显示单刀
    DOUBLEKNIFEIN = 4, --刀在鞘里，显示双手持刀
}

KUNGFU_TYPE = {
    TIAN_CE = 1, -- 天策内功
    WAN_HUA = 2, -- 万花内功
    CHUN_YANG = 3, -- 纯阳内功
    QI_XIU = 4, -- 七秀内功
    SHAO_LIN = 5, -- 少林内功
    CANG_JIAN = 6, -- 藏剑内功
    GAI_BANG = 7, -- 丐帮内功
    MING_JIAO = 8, -- 明教内功
    WU_DU = 9, -- 五毒内功
    TANG_MEN = 10, -- 唐门内功
    CANG_YUN = 18, -- 苍云内功
    CHANG_GE = 19, -- 长歌内功
    BA_DAO = 20, -- 霸刀内功
    PENG_LAI = 21, -- 蓬莱内功
    LING_XUE = 22, -- 凌雪内功
    YAN_TIAN = 23, -- 衍天内功
    YAO_ZONG = 24, -- 药宗内功
    DAO_ZONG = 26, -- 刀宗内功
    WAN_LING = 29, -- 万灵内功
    DUAN_SHI = 38, -- 段式内功
    WU_XIANG = 39, -- 无相内功
}

PLAYER_ATTRIB_ENUM = {
    "VITALITY",
    "SPIRIT",
    "STRENGTH",
    "AGILITY",
    "SPUNK",

    "THERAPY",

    "ATTACK",
    "HIT",
    "CRITICALSTRIKE",
    "CRITICALSTRIKE_DAMAGE",

    "SPEED",
    "OVERCOME",
    "STRAIN",
    "SURPLUS",

    "PHYSICS_SHIELD",
    "MAGIC_SHIELD",

    "DODGE",
    "COUNTERACT",
    "DEFENCE",

    "TOUGHNESS",
    "HUAJING",

    "LIFE_REPLENISH",
    "MANA_REPLENISH",

    "RUN_SPEED",
}

---@enum <> 技能释放方式
UISkillCastType = {
    Normal = 1, -- 走普通索敌，抬手释放
    Repeat = 3, -- 持续按住
    Down = 5, -- 按下就釋放

    Channel = 2, -- 暂时弃用
    Target = 4, -- 暂时弃用
}

SKILL_INFO_DESC_NUM = 300

---@enum <> 技能类型
UISkillType = {
    Common = 1, -- 普攻
    Skill = 2, -- 技能
    QiXue = 3, -- 奇穴
    Trigger = 4, -- 触发技
    Append = 5, -- 追加技
    SecSprint = 7, -- 小轻功
    Passive = 8, -- 被动
}

SkillPlatformType = {
    Common = 0, -- 普通攻击
    HD = 1,
    Mobile = 2
}

-- table表打开方式
TABLE_FILE_OPEN_MODE = {
    NORMAL = 0,
    MAPPING = 1,
    DEFAULT = 2
}

SKILL_SELECT_POINT_ABNORMAL = {
    nSkillID = 1919,
    nLevel = 1,
}

-- 逻辑表中配置的技能UI类型
-- 与UISkillType是两套配置（UISkillType特用于移动端技能配置）
SkillNUIType = {
    XinFa = 2, -- 技能
    UniqueSkill = 4, -- 大招
}

-- ForceToKungfu = {
--     [FORCE_TYPE.SHAO_LIN] = { 10002, 10003, },
--     [FORCE_TYPE.WAN_HUA] = { 10021, 10028, },
--     [FORCE_TYPE.TIAN_CE] = { 10026, 10062, },
--     [FORCE_TYPE.CHUN_YANG] = { 10014, 10015, },
--     [FORCE_TYPE.QI_XIU] = { 10080, 10081, },
--     [FORCE_TYPE.WU_DU] = { 10175, 10176, },
--     [FORCE_TYPE.TANG_MEN] = { 10224, 10225, },
--     [FORCE_TYPE.CANG_JIAN] = { 10144, 10145, },
--     [FORCE_TYPE.GAI_BANG] = { 10268, },
--     [FORCE_TYPE.MING_JIAO] = { 10242, 10243, },
--     [FORCE_TYPE.CANG_YUN] = { 10389, 10390, },
--     [FORCE_TYPE.CHANG_GE] = { 10447, 10448, },
--     [FORCE_TYPE.BA_DAO] = { 10464, },
--     [FORCE_TYPE.PENG_LAI] = { 10533, },
--     [FORCE_TYPE.LING_XUE] = { 10585, },
--     [FORCE_TYPE.YAN_TIAN] = { 10615, },
--     [FORCE_TYPE.YAO_ZONG] = { 10626, 10627 },
--     [FORCE_TYPE.DAO_ZONG] = { 10698 },
-- }

--资源下载，门派对应的门派场景id配置
ForceIDToMapID = {
    [FORCE_TYPE.SHAO_LIN] = 5,
    [FORCE_TYPE.WAN_HUA] = 2,
    [FORCE_TYPE.TIAN_CE] = 11,
    [FORCE_TYPE.CHUN_YANG] = 7,
    [FORCE_TYPE.QI_XIU] = 16,
    [FORCE_TYPE.WU_DU] = 102,
    [FORCE_TYPE.TANG_MEN] = 122,
    [FORCE_TYPE.CANG_JIAN] = 49,
    [FORCE_TYPE.GAI_BANG] = 159,
    [FORCE_TYPE.MING_JIAO] = 150,
    [FORCE_TYPE.CANG_YUN] = { 193, 197 },
    [FORCE_TYPE.CHANG_GE] = 213,
    [FORCE_TYPE.BA_DAO] = 243,
    [FORCE_TYPE.PENG_LAI] = 333,
    [FORCE_TYPE.LING_XUE] = { 419, 445 },
    [FORCE_TYPE.YAN_TIAN] = { 464, 513 },
    [FORCE_TYPE.YAO_ZONG] = 526,
    [FORCE_TYPE.DAO_ZONG] = 578,
    [FORCE_TYPE.WAN_LING] = 642,
    [FORCE_TYPE.DUAN_SHI] = 666,
}

RoleTypeToPackID = {
    [ROLE_TYPE.STANDARD_MALE] = 15,
    [ROLE_TYPE.LITTLE_BOY]= 14,
    [ROLE_TYPE.LITTLE_GIRL]= 12,
    [ROLE_TYPE.STANDARD_FEMALE]= 13,
}

-- !!!注意：新建UI_OBJECT_XXX时记得去`ui/Script/box.lua`中定义相关类型的更新参数和通用事件 --
UI_OBJECT = {
    NONE = -1, -- 空Box
    ITEM = 0, -- 身上有的物品。nUiId, dwBox, dwX, nItemVersion, nTabType, nIndex
    SHOP_ITEM = 1, -- 商店里面出售的物品 nUiId, dwID, dwShopID, dwIndex
    OTER_PLAYER_ITEM = 2, -- 其他玩家身上的物品 nUiId, dwBox, dwX, dwPlayerID
    ITEM_ONLY_ID = 3, -- 只有一个ID的物品。比如装备链接之类的。nUiId, dwID, nItemVersion, nTabType, nIndex
    ITEM_INFO = 4, -- 类型物品 nUiId, nItemVersion, nTabType, nIndex, nCount(书nCount代表dwRecipeID)
    SKILL = 5, -- 技能。dwSkillID, dwSkillLevel, dwOwnerID
    CRAFT = 6, -- 技艺。dwProfessionID, dwBranchID, dwCraftID
    SKILL_RECIPE = 7, -- 配方dwID, dwLevel
    SYS_BTN = 8, -- 系统栏快捷方式dwID
    MACRO = 9, -- 宏
    MOUNT = 10, -- 镶嵌
    ENCHANT = 11, -- 附魔
    NOT_NEED_KNOWN = 15, -- 不需要知道类型
    PENDANT = 16, -- 挂件
    PET = 17, -- 宠物
    MEDAL = 18, -- 宠物徽章
    BUFF = 19, -- BUFF
    MONEY = 20, -- 金钱
    TRAIN = 21, -- 修为
    EMOTION_ACTION = 22, -- 动作表情
    EXTERIOR = 23, -- 外装
    EXTERIOR_WEAPON = 24, -- 武器外观
    ITEM_INFO_PLAYER = 25, -- 类型物品 道具信息带playerID
    MOBA_ITEM = 26, -- Moba商店物品
    TOY = 27, --玩具箱物品
    BRIGHT_MARK = 28, --头顶亮标表情
    NPC_EQUIP = 29, --Npc助战装备
    SKILL_SKIN = 30,
}

-- !!!再次注意：新建UI_OBJECT_XXX时记得去`ui/Script/box.lua`中定义相关类型的更新参数和通用事件 --
----------------------------------------------------------------------------------------------
SOCIALPANEL_NAME_DISPLAY = { REMARK = 0, NICKNAME = 1, NICKNAME_AND_REMARK = 2, REMARK_AND_NICKNAME = 3 }

----------------------------------------------------------------------------------------------
CALENDER_EVENT_RESET = 1
CALENDER_EVENT_ALLDAY = 2
CALENDER_EVENT_START = 3
CALENDER_EVENT_LONG = 4
CALENDER_EVENT_DYNAMIC = 5
-------------------------------
INVENTORY_GUILD_BANK = INVENTORY_INDEX.TOTAL + 1 --帮会仓库界面虚拟一个背包位置

INVENTORY_GUILD_PAGE_SIZE = 100

-- \represent\common\global_effect.txt
TITLE_EFFECT_NONE = 0
PARTY_TITLE_MARK_EFFECT_LIST = { 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, [0] = TITLE_EFFECT_NONE }
------ coinshop type-------------------
DEF_COINSHOP_DISABLE = false -- 商城是否关闭
LIMIT_SALE_AD_SHOW = true
EXTERIOR_SUB_NUMBER = 5
HORSE_ADORNMENT_COUNT = 4
RIDE_BOX_COUNT = 6

HOME_TYPE = {
    HAIR = 1,
    FACE = 2,
    EXTERIOR = 3,
    REWARDS = 4,
    EXTERIOR_SET = 5,
    EXTERIOR_WEAPON = 6,
    --EXTERIOR_COLLECT = 7, 由于商城结构更改，该枚举废弃
    FACE_LIFT = 8,
    EFFECT_SFX = 9,
}

EXTERIOR_LABEL = {
    HOT = 1,
    NEW = 2,
    DISCOUNT = 3,
    TIME_LIMIT = 4,
    FREE_TRY_ON = 5,
    --VIP          = 6,
    --SUPER_VIP    = 7,
    PVP = 8,
    GAME_WORLD_START = 9,
    REWARDS = 100,
    FACELIFT_NEW = 200,
}

GET_STATUS = {
    INVALID = -100,
    COLLECTED = 1,
    NOT_COLLECTED = 2,
    COLLECTING = 3,
    SHOP = 4,
}

EXTERIOR_CLASS = {
    EXTERIOR = 1,
    COLLECT = 2
}

COINSHOP_TITLE_CLASS = {
    EXTERIOR = 3,
    HAIR_SHOP = 3,
}

UI_COINSHOP_GENERAL = {
    SHOP = 1,
    MY_ROLE = 2,
    BUILD_FACE = 3,
}

----------------------------------设计站----------------------------------
-- 分享数据状态码
SHARE_OPEN_STATUS = {
    PRIVATE = 0,         --私密
    PUBLIC = 1,          --公开
    FILE_ILLEGAL = 2,    --系统隐藏（文件审核不通过）
    COVER_ILLEGAL = 3,   --系统隐藏（封面审核不通过）
    INVISIBLE = 4,       --GM隐藏
    CHECKING_TO_PRIVATE = 5, --校验中转私密
    CHECKING_TO_PUBLIC = 6, --校验中转公开
    DELETE = 7,          --玩家删除
}

SHARE_STATION_UPLOAD_STEP = {
    SHOOT = 1,
    CUT = 2,
    UPLOAD = 3,
}

FACE_TYPE = {
    NEW = 1,
    OLD = 2,
}

SHARE_DATA_TYPE = {
    FACE = 1,
    BODY = 2,
    EXTERIOR = 3,
    PHOTO = 4,
}

--搜索类型
SHARE_SEARCH_TYPE = {
    NAME = 1,
    CODE = 2,
    USER = 3,
}

--上传的时间范围
SHARE_TIME_RANGE = {
    All = 1,
    DAY = 2,
    WEEK = 3,
    MONTH = 4,
    THREE_MONTH = 5,
}

SHARE_TIME_SORT_TYPE = {
    NEW = 1,
    OLD = 2,
}

--拍照地图类型
SHARE_PHOTO_MAP_TYPE = {
    NORMAL = 1,        -- 大世界
    SELFIE_STUDIO = 2, -- 摄影棚
}

--拍照封面尺寸
SHARE_PHOTO_SIZE_TYPE = {
    CARD = 1,       -- 名片
    HORIZONTAL = 2, -- 横版
    VERTICAL = 3,   -- 竖版
}

--穿搭外观商品类型
SHARE_EXTERIOR_SHOP_STATE = {
    HAVE = 1,           -- 已拥有
    IN_BAG_BIND = 2,    -- 已拥有（背包/仓库中）-不可交易
    IN_BAG_UNBIND = 3,  -- 已拥有（背包/仓库中）-可交易
    GOODS_SALE = 4,     -- 商城可购买
    OTHER = 5,          -- 其他
}

--------------------------------------------------------------------

-- 打赏类型
TIP_TYPE = {
    ShareStation = 0,
    GlobalID = 1,
    ObserveInstance = 2, -- 副本观战打赏
    ObserveInstance_Team = 3, -- 副本观战打赏，全团
}

REWARDS_CLASS = {
    LIMIT_TIME = 1,
    LIMIT = 2,
    CLOTH_PENDANT_CLOAK = 3,
    PENDANT_FACE = 4,
    PENDANT_BACK = 5,
    PENDANT_WAIST = 6,
    CLOTH_PENDANT_LSHOULDER = 8,
    CLOTH_PENDANT_RSHOULDER = 9,
    CLOTH_PENDANT_BAG = 12,
    ARENA_WEAPON = 14,
    FURNITURE = 19,
    HOMELAND_SKIN = 20,
    FURNITURE_PACKAGE = 21,
    PET = 61,
    GLASSES = 62,
    HORSE = 50,
    HORSE_RARE = 51,
    HORSE_ADORNMENT = 52,
    CLOTH_PENDANT_PET = 60,
    REAL_ITEM = 101,
    PUBLICATION = 106,
    LHAND = 63,
    RHAND = 64,
    HEAD_EXTEND = 65,
    EFFECT = 66,
}

COINSHOP_BOX_INDEX = {
    HELM = 1, -- 头部 2
    CHEST = 2, -- 上衣 5
    BANGLE = 3, -- 护手 11
    WAIST = 4, -- 腰带 8
    BOOTS = 5, -- 鞋子 14
    FACE_EXTEND = 6, -- 面部挂件
    BACK_EXTEND = 7, -- 背部挂件
    WAIST_EXTEND = 8, -- 腰部挂件
    ITEM = 9, -- 道具
    HAIR = 10, --发型
    FACE = 11, --脸型
    WEAPON = 12, -- 武器
    BIG_SWORD = 13, --重剑
    L_SHOULDER_EXTEND = 14, --左肩挂件
    R_SHOULDER_EXTEND = 15, --右肩挂件
    BACK_CLOAK_EXTEND = 16, --披风
    CHEST_EX = 17, -- 外装上衣
    BOOTS_EX = 18, -- 鞋子
    PANTS_EX = 19, -- 裤子
    PENDANT_PET = 20, --挂宠
    BAG_EXTEND = 21, --佩囊
    GLASSES_EXTEND = 22, --眼饰
    L_GLOVE_EXTEND = 23, --左手饰
    R_GLOVE_EXTEND = 24, --右手饰
    BODY = 25, --体型
    NEW_FACE = 26, --新脸型
    HEAD_EXTEND = 27, --头饰
    IDLE_ACTION = 28, -- 待机动作
    HEAD_EXTEND1 = 29, --头饰第二个位置
	HEAD_EXTEND2 = 30, --头饰第三个位置
    EFFECT_SFX = 31, --特效
}

EquipType2SlotCount = {
    -- 头部
    [EQUIPMENT_INVENTORY.HELM] = 2,
    -- 上衣
    [EQUIPMENT_INVENTORY.CHEST] = 2,
    -- 腰带
    [EQUIPMENT_INVENTORY.WAIST] = 2,
    -- 下装
    [EQUIPMENT_INVENTORY.PANTS] = 2,
    -- 鞋子
    [EQUIPMENT_INVENTORY.BOOTS] = 2,
    -- 护腕
    [EQUIPMENT_INVENTORY.BANGLE] = 2,
    -- 项链
    [EQUIPMENT_INVENTORY.AMULET] = 1,
    -- 腰坠
    [EQUIPMENT_INVENTORY.PENDANT] = 1,
    -- 戒指
    [EQUIPMENT_INVENTORY.LEFT_RING] = 0,
    -- 戒指
    [EQUIPMENT_INVENTORY.RIGHT_RING] = 0,
    -- 武器
    [EQUIPMENT_INVENTORY.MELEE_WEAPON] = 3,
    -- 重剑
    [EQUIPMENT_INVENTORY.BIG_SWORD] = 3,
    -- 远程武器
    [EQUIPMENT_INVENTORY.RANGE_WEAPON] = 1,
    -- 暗器
    [EQUIPMENT_INVENTORY.ARROW] = 0,
}

EquipCompareType = {
    NormalByItemID = 0,
    NormalByTabID = 1,
    Bag = 2,
    NormalByBoxIndex = 3,
}

COINSHOP_RIDE_BOX_INDEX = {
    HEAD_HORSE_EQUIP = 1,
    CHEST_HORSE_EQUIP = 2,
    FOOT_HORSE_EQUIP = 3,
    HANG_ITEM_HORSE_EQUIP = 4,
    HORSE = 5, -- 马
    ITEM = 6, --限量限时道具
}

FACELIFT_INDEX_START = 10001

COINSHOP_RECOMMEND_SOURCE = {
    COINSHOP = 0,
    ITEM = 1,
}

HAIR_SHOW_TYPE =
{
    ALL     = 1, --全部
    BLACK   = 2, --黑发
    WHITE   = 3, --白发
    GOLD    = 4, --金发
    GROUP   = 5, --套发
    RED     = 6, --红发
    COLOR   = 7, --异色发
    -- GIFT    = 8, --福袋发
    DYEING  = 8, --染色发型 -- 这个只需要放在最后就行，其它的需要对应HAIR_SHOW_TYPE
}

EFFECT_FILTER_TYPE = {
    FOOT = 1,   --脚印
    BODY = 2,   --环身
    LHAND = 3,  --左手
    RHAND = 4,  --右手
}

EffectTypeToFilterType = {
    [EFFECT_FILTER_TYPE.FOOT] = PLAYER_SFX_REPRESENT.FOOTPRINT,
    [EFFECT_FILTER_TYPE.BODY] = PLAYER_SFX_REPRESENT.SURROUND_BODY,
    [EFFECT_FILTER_TYPE.LHAND] = PLAYER_SFX_REPRESENT.LEFT_HAND,
    [EFFECT_FILTER_TYPE.RHAND] = PLAYER_SFX_REPRESENT.RIGHT_HAND,
}

UI_COIN_SHOP_GOODS_TYPE_OTHER = 0

UI_COIN_SHOP_OTHER_CLASS = {
    BODY = 1,
    NEW_FACE = 2,
}

NEWFACE_LABEL = {
	DISCOUNT = 1,
	NEW = 2,
}

---------------------------------------------
ACTIVITY_UI = {
    CALENDER = 1, -- 日历
    MONTH = 2, -- 月历，已经废弃了
    BUBBLE = 4, -- 泡泡提醒
    ISSUE = 8, -- 小地图热点
    WORLDMAP = 16, -- 世界地图
    CAMP = 32, -- 阵营界面
}

ACTIVITY_STATE = {
    UNDER_WAY = 1,
    NOT_START = 2,
    END = 3,
}

ACTIVITY_ID = {
    CASTLE = 225,
    COINSHOP_SURPRISE_FREE = 508,
    GUILD_RETURN = 568,
    WBL = 571,
    PLAYERRETURN = 629, --回归活动
    ALLOW_EDIT = 692, -- 允许某些界面的输入
    AI_FACE = 760,
    BIGBATTLE_QUEUE = 490,
    ACTION = 573,
    ROUGE_LIKE = 901,
    SOLO_ARENA = 980, -- 插旗大王
    MASTER_ARENA = 395, -- 群英赛
    TREASURE_HUNT_SINGLE = 1014, --吃鸡寻宝单排
    TREASURE_HUNT_TEAM = 1015, --吃鸡寻宝组排
    TONG_LEAGUE_RANK = 662,	--帮会联赛排行榜
    AI_MOCAP = 1044, -- 幻境云图 AI 动捕（活动开关）
}
----------------------------
EXTERIOR_OPEN_SOURCE = {
    MINIMAP = 1,
    HOTKEY = 2,
    CHARACTER = 3,
    ADVERTIS_IMM_FREE = 4,
    ADVERTIS_QUEUE_FREE = 5,
    ADVERTIS_IMM_OTHER = 6,
    ADVERTIS_QUEUE_OTHER = 7,
    SERVER = 8,
}

FREE_TRYON_AD_OPERATION = {
    EXTERIOR = 1,
    CLOSE_BTN = 2,
    CLOSE_ESC = 3,
}
------------------mpak-------------
COINSHOP_MPAK_ID = 103
----------------------------------

OT_CSS = { --vk端无需配置维护，dx用到的内容
    NORMAL = 1, -- 普通UI
    GAIBANG = 2, -- 丐帮蓄力技能UI
    CANGYUN_SPRIT_GROUND = 3, -- 苍云地面轻功UI
    CANGYUN_SPRIT_SKY = 4, -- 苍云空中轻功UI
    CANGYUN_SKILL = 5, -- 苍云技能UI
    CHANGGE_SKILL = 6, -- 长歌技能UI
    BADAO_SKILL = 7, -- 霸刀技能UI
    QIXIU_SKILL = 8, -- 七秀技能UI
    SHAOLIN_SKILL = 9, -- 少林技能UI
    TANGMEN_SkILL = 10, -- 唐门技能UI
    MINGJIAO_SkILL = 11, -- 明教技能UI
    CANGJIAN_SkILL = 12, -- 藏剑技能UI
    TIANCE_SkILL = 13, -- 天策技能UI
    WANHUA_SkILL = 14, -- 万花技能UI
    CHUNYANG_SkILL = 15, -- 纯阳技能UI
    GAIBANG_SkILL = 16, -- 丐帮技能UI
    WUDU_SkILL = 17, -- 五毒技能UI
    PENGLAI_SKILL = 18, -- 蓬莱技能
    LINGXUE_SKILL = 19, -- 凌雪技能UI
    YANTIAN_SKILL = 20, -- 衍天技能UI
    YAOZONG_SKILL = 21, -- 药宗技能UI
    DAOZONG_SKILL = 22, -- 刀宗技能UI
}

-------------------------------
---@enum PLAYER_SHOW_MODE 角色显示模式
PLAYER_SHOW_MODE = {
    kAll = 1, -- 所有
    kParter = 2, -- 队友
    kNone = 3, -- 隐藏
}

---@enum HEAD_FLAG_OBJ 角色类型
HEAD_FLAG_OBJ = {
    CLIENTPLAYER = 1, -- 客户端自身角色
    OTHERPLAYER = 2, -- 客户端其它角色
    NPC = 3, -- Npc
}

---@enum HEAD_FLAG_TYPE 头顶显示类型
HEAD_FLAG_TYPE = {
    LIFE = 1, -- 血条
    GUILD = 2, -- 帮会
    TITLE = 3, -- 称号
    NAME = 4, -- 名字
    MARK = 5, -- 标记
}

SettingCategory = {
    General = "General",
    Quality = "Quality",
    Display = "Display",
    BattleInfo = "BattleInfo",
    Focus = "Focus",
    Sound = "Sound",
    Operate = "Operate",
    Custom = "Custom",
    ShortcutInteraction = "ShortcutInteraction",
    Resources = "Resources",
    Version = "Version",
    Interface = "Interface",
    GamePad = "GamePad",
    GamepadInteraction = "GamepadInteraction",
    WordBlock = "WordBlock",
    SkillEnhance = "SkillEnhance",
}

SOUND = {
    MAIN = -1, --主要音量
    BG_MUSIC = 0, --背景音乐
    UI_SOUND = 1, --界面音效
    UI_ERROR_SOUND = 2, --错误提示音
    SCENE_SOUND = 3, --环境音效
    CHARACTER_SOUND = 4, --角色音效,包括打击，特效的音效
    CHARACTER_SPEAK = 5, --角色对话
    FRESHER_TIP = 6, --新手提示音
    SYSTEM_TIP = 7, --系统提示音
    TREATYANI_SOUND = 8, --协议动画声音
    WARNING_SOUND = 9, --警告提示音
    MIC_VOLUME = 10, --麦克风音量
    SPEAKER_VOLUME = 11, --话筒音量
}

SOUND_TITLE = {
    MAIN = 201, --主音量
    MUSIC = 202, --音乐音效
    CHARACTER_SPEAK = 203, --角色对话
    REAL_TIME = 204, --实时语音
    MODIFY = 205, --变声设置：原声
}

QUALITY = {
    MAIN = 21, --主要设置
    RENDER_EFFICIENCY = 22, --渲染效率
}

OPERATE = {
    MAIN = 31,
    SPRINT = 32,
    --SPECIAL_FORCE = 33,
}

GENERAL = {
    CAMERA = 41, --镜头类型
    PERFORMANCE = 43, --性能优化策略
    ADVANCED_ANIMATION = 44, --高级动画效果
    GAME_LOG = 45, --游戏日志
    FONT = 46, --通用字体
    SHIELD = 47, --勿扰
    SERVER_SYNC = 48, --服务器同步
    --FILTER_SETTING = 49, --时光漫游
    MOUSE_SETTING = 50, --鼠标设置
}

DISPLAY = {
    TOP_HEAD = 51,
    OTHER_VISUAL = 52,
    SELF_LIFE_VISUAL = 53,
    TARGET_LIFE_VISUAL = 54,
    TARGET_LINE_CONNECT = 55,
    TARGET_ENHANCE = 56,
    FACING_ENHANCE = 57,
    DOUQI = 58,
}

BATTLE_INFO = {
    MAIN = 61,
    ACTIVE_ATTACK = 62,
    DAMAGED = 63,
}

RESOURCES = {
    DYNAMIC = 1, --外观资源
    MAP = 2, --地图资源
}

FOCUS = {
    TARGET = 71,
    AUTO = 72,
    FOCUS_SETTING = 73,
    MAIN = 74,
    WARNING = 75,
}

CUSTOM = {
    MAIN = 91,
}

INTERFACE = {
    LAYOUT = 101,
    FONT = 102,
    HEAD_TOP = 103,
    DISPLAY_SWITCH = 104,
}

GAMEPAD_CATEGORY = {
    KEY_SETTING = 111,
    OTHER = 112,
}

SKILL_ENHANCE = {
    MAIN = 121,
    SPECIAL = 122,
    QI_CHANG = 123,
    CAST_CONTINUOUS = 124,
}


-------------------------------
ARENA_HIGH_LEVEL_DIVIDE = 200

EXCELLENT_ID = {
    MVP = 1,
    WIN_COUNT = 2,
    BEST_COURSE = 3, --全程最佳

    ARENA_TOWER_MVP = 27, -- 扬刀大会MVP
}

-------------------------------
MENU_DIVIDER = { bDevide = true }
--------------------------------勿扰选项------------------------------

INVITE_FILTER = {
    PARTY_INVITE_REQUEST = 1,
    PARTY_APPLY_REQUEST = 2,
    ADD_FELLOWSHIP = 3,
    QUERY_MENTOR = 4,
    QUERY_APPRENTICE = 5,
    EMOTION_ACTION_REQUEST = 6,
    FOLLOW_INVITE = 7,
    TRADING_INVITE = 8,
    JOIN_TONG_REQUEST = 9,
    APPLY_DUEL = 10,
    INVITE_ARENA_CORPS = 11,
}

FELLOW_SHIP_PUSH_TYPE = {
    PUSH = 101,
    PVE = 1,
    PVP = 2,
    PVX = 3,
    AROUND = 102,
    IP = 103,
}

--------------------------装备面板------------------------------------
CASTING_MIN_LEVEL = 20

MAX_COLOR_DIAMOND_NUM = 4

MAIN_SLOT_NAME_FORMAT = "%s栏"
MAIN_SLOT_LEVEL_FORMAT = "当前已穿戴的装备品级：%d"
ENCHANT_LEVEL_FORMAT = "装备品级：%d"
MAIN_SLOT_QUALITY_FORMAT = "装备品级≤%d，精炼属性已生效"
MAIN_SLOT_QUALITY_INVALID_FORMAT = "装备品级>%d，强化属性未生效"

-----------------------生活技艺等级限制-----------------------------------
CRAFT_MIN_LEVEL = 20

-----------------入帮等级限制--------------------------
CAN_APPLY_JOIN_LEVEL = 10

----------------------新大侠之路--------------------------------
ROAD_CHIVALROUS_MODULE_STATE = {
    INACTIVATED = 1,
    INCOMPLETED = 2,
    COMPLETED_NOT_GOT_FINAL_REWARDS = 3,
    COMPLETED_GOT_FINAL_REWARDS = 4,
}

ROAD_CHIVALROUS_SUBMODULE_STATE = {
    INACTIVATED = 1,
    INCOMPLETED = 2,
    COMPLETED_NOT_GOT_REWARDS = 3,
    COMPLETED_GOT_REWARDS = 4,
}

ROAD_CHIVALROUS_MODULE_TYPE = {
    PVP = 1,
    PVE = 2,
    PVX = 3,
}

--1=不可领 2=可领未领 3=已领
ROAD_CHIVALROUS_AWARD_STATE = {
    CANNOT_GET_ROAD_AWARD = 1,
    CAN_GET_ROAD_AWARD = 2,
    GOT_ROAD_AWARD = 3,
}

ROAD_CHIVALROUS_SHARE_ONE_BILLION_AWARD_STATE = {
    CANT_GET = 0,
    CAN_GET = 1,
    GOT_ALREADY = 2,
}

------------------------玩法相关-------------------------
PlayEnterConfirmationType = {
    InQueue = 1,
    Enter = 2,
}

PlayType = {
    BattleField = 1,
    Arena = 2,
    TongBattleField = 3, -- 仅 PanelPvpEnterConfirmation 中使用，用于特殊处理帮会约战的确认框的逻辑
    CampWar = 4, --阵营大攻防
    JingHua = 5,
}

------------------------竞技场相关-----------------------
ARENA_UI_TYPE = {
    ------此处必须和逻辑导出的值同步----------
    ARENA_BEGIN         = ARENA_TYPE.ARENA_BEGIN,
    ARENA_2V2           = ARENA_TYPE.ARENA_2V2,
    ARENA_3V3           = ARENA_TYPE.ARENA_3V3,
    ARENA_5V5           = ARENA_TYPE.ARENA_5V5,
    ARENA_1V1		    = ARENA_TYPE.ARENA_MASTER_2V2,
    ARENA_MASTER_3V3    = ARENA_TYPE.ARENA_MASTER_3V3,
    ARENA_MASTER_5V5    = ARENA_TYPE.ARENA_MASTER_5V5,
    ARENA_END           = ARENA_TYPE.ARENA_END,
    -------逻辑不导出练习房模式的枚举值，UI自己定义---------
    ARENA_PRACTICE = 100, --设为100，避免与逻辑新增枚举值冲突
    ARENA_ROBOT = 101,
}

------------------------阵营相关-------------------------

CampFuncType = {
    Activity = 1, --活动日历
    CampMaps = 2, --战争沙盘
    SwitchServerPK = 3, --千里伐逐
    RankList = 4, --阵营英雄五十强
    BigThing = 5, --阵营大事记
}

CampRewardType = {
    Attribute = 1, --战阶属性奖励
    Equip = 2, --战阶商人解锁
    Extra = 3, --威名点周上限奖励
    Rank = 4, --战阶积分排名奖励
}

-----------------------运营活动--------------------
--Oper_ation + Act_ivity
OPERACT_ID = {
    FIRST_CHARGE                  = 1,
    ANNIVERSARY_FEEDBACK          = 2,
    DOUBLE_ELEVEN_LOTTERY         = 4,
    FREE_TO_90                    = 5,
    DOUBLE_ELEVEN_DISCOUNT        = 9,
    DOUBLE_TWELVE_DISCOUNT        = 10,
    FRIENDS_RECRUIT               = 11,
    GIVE_DIANKA                   = 12,
    DAILY_SIGN                    = 16,
    PREORDER_BUY                  = 22,
    REAL_NAME_CERTIFY             = 33,
    DOWNLOAD_AWARD                = 36,
    WISH_GIFT                     = 37,
    COUPUTER_GIFT                 = 38,
    CHARGE_MONTHLY                = 39,
    WOMEN_DAY                     = 40,
    DOUBLE_ELEVEN_REBATE          = 42,
    NEWYEAR_GIFT                  = 44,
    ORDER_AND_RECEIVE_GIFT        = 45,
    ANNIVERSARY_PRESENT           = 50,
    BATTLE_PASS                   = 51,
    MAIN_LINE_FREE_TO_FULL_LEVEL  = 52,
    LUCKY_PERSON                  = 53,
    GIVE_MONTH_CARD               = 54,
    REAL_FIRST_CHARGE             = 55,
    KOI_GIFT                      = 58,
    EXTERIOR_LOTTERY              = 61,
    SEASON_DISTANCE               = 130,
    SEASON_RETURN                 = 131,
    SEASON_GONGZHAN               = 132,
    MingJianCuiFeng               = 183,
    NEW_YEAR                      = 184,
    WELCOME_NEWBIE_SIGNIN         = 225,
	WELCOME_BACK_SIGNIN           = 226,
	ACCOUNT_SAFE                  = 227,
	RECALL_GUIDE                  = 229,
	GUIDE_PERSON_MENGXIN          = 234,
	TANG_JIAN_ZHUAN               = 237, -- 唐简传
	LANG_FENG_XUAN_CHENG          = 238, -- 阆风悬城
    LEYOUJI                       = 252,  --乐游纪
}

OPERACT_MODE = {
    NORMAL = 0,
    ONE_PHOTO = 1,
    PROGRESS = 2,
    SHOP = 3,		--商店模板
	SIGN_IN = 4,	--签到模板
    SIMPLE_OPERATION = 5,
    ACTIVITY_SIGN_IN = 6,  --活动签到
}

OPERACT_REWARD_STATE = {
    ALREADY_GOT = 1,
    CAN_GET = 2,
    NON_GET = 3,
}

------------------------------------------------------
WEB_RQST = {
    MY_ADDRESS = 1,
    FILL_IN_ADDRESS = 2,
    LOOKUP_ADDRESS = 3,
    PAY_MONEY = 4,
    OPEN_AUTO_CHESS = 5,
}
WEB_DATA_SIGN_RQST = {
    REAL_ITEM_ORDER = 1,
    LOGIN = 2,
}
EMPTY_TABLE = {}

DIAMOND_MAX_LEVEL = 8
DIAMOND_MAX_STRENGTHEN_LEVEL = 6
COLOR_DIAMOND_MAX_LEVEL = 6
COLOR_DIAMOND_MAX_STRENGTHEN_LEVEL = GetMaxChangeColorDiamondLevel()

MAIN_SCENE_DOF_NEAR_MIN = 0
MAIN_SCENE_DOF_AWAY_MIN = 3000
MAIN_SCENE_DOF_AWAY_MAX = 80000
MAIN_SCENE_DOF_DIST_MIN = 50
MAIN_SCENE_DOF_DIST_MAX = 3000

------------------------------------------------------------
LEVEL_CAN_JOIN_CAMP = 18

-----------------------pendant---------------------------------------
MAX_WAIST_SIZE = 1024
MAX_BACK_SIZE = 1024
MAX_FACE_SIZE = 128
MAX_L_SHOULDER_SIZE = 1024
MAX_R_SHOULDER_SIZE = 1024
MAX_BACK_CLOAK_SIZE = 1024
MAX_BAG_PENDANT_SIZE = 1024

-----------------------UIItemShadow---------------------------------------
UI_ITEM_SHADOW_POS_TYPE = {
    TOP = 1,
    CENTER = 2,
    BOTTOM = 3,
}

------------------------------战术面板------------------------------------------
ENUM_MAP_WND_TYPE = {
    NPC = 1,
    CAR = 2,
    ARROW = 3,
    MARK = 4,
    NPC_BE_ATTACKED = 5,
}

COMMAND_BOARD = {
    MAX_ARROW = 15,
    MAX_MARK = 10,
    MAX_CAR = 10,
    MAX_GATHER = 1,
}

CAMP_OB_CONSTANT = {
    NUM_OF_COMMANDER = 5,
}

TYPE_ID_OF_CAR = 14 --必须和MiddleMapCommand.txt中的Car行的id对应

------------------------------阵营拍卖------------------------------------------
CAMP_AUCTION = {
    ACTIVITY_ID_OF_CAMP = 554, --阵营攻防
    ACTIVITY_ID_OF_ZHU_LU_ZHONG_YUAN = 555, --逐鹿中原
    ACTIVITY_ID_OF_PEACE = 523, -- 休战活动
    ACTIVITY_ID_OF_WORLD_BOSS = 752, --铁血宝箱战利品
    ACTIVITY_ID_OF_TEMP = 753, --铁血宝箱临时
}

------------------------------GVoice---------------------------------------

MIC_STATE = {
    NOT_AVIAL = 0,
    OPEN = 1,
    CLOSE = 2,
}

SPEAKER_STATE = {
    OPEN = 1,
    CLOSE = 2,
}

COMMAND_MODE_PLAYER_ROLE = {
    NORMAL = 1,
    VICE_COMMANDER = 2,
    SUPREME_COMMANDER = 3,
}

------------------------------Quest---------------------------------------
QUEST_PHASE = {
    ERROR = -1,
    UNACCEPT = 0, --未接受
    ACCEPT = 1, --接受
    DONE = 2, --完成未提交
    FINISH = 3, --提交
}

QuestType = {
    All = 1, --全部
    Course = 2, --历程(主线)
    Activity = 3, --活动
    Daily = 4, --日常
    Branch = 5, --支线
    Other = 6, --其它
    Top = 7, --置顶
}

--只用于任务面板分类
QuestTypeName = {
    [QuestType.All] = "全部",
    [QuestType.Course] = "主线",
    [QuestType.Activity] = "活动",
    [QuestType.Daily] = "日常",
    [QuestType.Branch] = "支线",
    [QuestType.Other] = "其它",
    [QuestType.Top] = "引导", --任务面板名称
}

--任务追踪最大数量
MAX_TRACE_QUEST_NUM = 2

QUEST_STATE_NO_MARK = 1
QUEST_STATE_YELLOW_QUESTION = 2
QUEST_STATE_BLUE_QUESTION = 3
QUEST_STATE_HIDE = 4
QUEST_STATE_WHITE_EXCLAMATION = 5
QUEST_STATE_YELLOW_EXCLAMATION = 6
QUEST_STATE_BLUE_EXCLAMATION = 7
QUEST_STATE_WHITE_QUESTION = 8
QUEST_STATE_DUN_DIA = 9
QUEST_WHITE_LEVEL = 10
QUEST_HIDE_LEVEL = 10
------------------------------副本---------------------------------------
FB_TYPE = {
    TEAM = 1,
    RAID = 2,
    MONSTER = 3,
}

-----------------------------------弹出网页配置---------------------------------------
WEBURL_TYPE = {
    EXPLORER = 0,
    SIMPLE_WEB = 1,
    INTERNETEXPLORER = 2,

}

WEBURL_ID = -- 对应WebURL.tab中的dwID字段
{
    INVITATION = 1, --请柬
    COMPETITIVE_MATCH = 5, --群英赛
    WEB_CHATBOT = 7, --阿甘机器人
    WAN_BAO_LOU = 9, --万宝楼
    SELF_BLUEPRINT_TEST = 11, --官方蓝图个人中心（测试）
    SELF_BLUEPRINT = 12, --官方蓝图个人中心
    CROSS_SERVER_FRIENDS = 16, --跨服好友
    INDEX_BLUEPRINT_TEST = 22,
    INDEX_BLUEPRINT = 23, --官方蓝图
    TONG_WAR_GUESSING = 24, --帮会联赛 竞猜
    PRODUCER_LETTER = 36, --制作人的一封信
    WAN_BAO_LOU_ITEM = 54, --万宝楼跳转商品
    TICKETS_PURCHASE_ELIGIBILITY = 56, --828门票购买资格入口（pc跳转）
    TICKETS_PURCHASE_ELIGIBILITY_MOBILE = 57, --828门票购买资格入口（移动端跳转）
    FIFTEEN_Anni_LIVE_STREAMING = 59, --828门票购买资格入口（pc跳转）
    FIFTEEN_Anni_LIVE_STREAMING_MOBILE = 60, --828门票购买资格入口（移动端跳转）
	CHAT_ROBOT = 69, --在线客服
    TIAN_XUAN_VOTE = 18, --天选系列外观票选（pc跳转）
    TIAN_XUAN_VOTE_MOBILE = 62, --天选系列外观票选（移动端跳转）
    TONG_REN_EXTERIOR = 15, --同人外装评选
    TONG_REN_WEAPON = 63, --同人武器评选
    COMPETITIVE_MATCH_GUESS = 64, --群英赛竞猜
    WEB_CHATBOT_VK = 67,
    WEB_CHATBOT_VK_MOBILE = 68,
    WEB_EFFECT = 76, --特效
    WEB_SERVICE_AREA = 77, --客服中心 - 其他 - 客服专区
}
------------------------登录---------------------
GANPEI_MONEY = 50

-------------------------login_logo---------------------
LOGIN_LOGO = {
    XSJ_LOGO = 1,
    CG = 2,
    CREATE = 3,
}

--------------------------创角战斗类型---------------------
COMBAT_TYPE =
{
	RANGED = 1,    -- 远程
    MELEE = 2,     -- 近战
    HEALER = 3,    -- 治疗
    TANK = 4       -- 坦克
}

--------------------------幻境云图分享界面---------------------------
SNS_BINDED_CODE = {
    BINDED = 1,
    NOT_BINDED = 2,
    REQUEST_FAILED = 3,
}

----------------------------举报面板(GMPanel)--------------------------------------------
REPORT_FROM_WHERE = {
    TEAM_BUILDING = 1, --团队招募
    MENTOR_PANEL_FIND_MENTOR = 2, --师徒面板找师傅
    MENTOR_PANEL_FIND_APPRENTICE = 3, --师徒面板找徒弟
}

----------------------------云端PC端相关（Streaming）--------------------------------------------
STREAM_GAME = {
    SMALL_USERDATA_CD = 5, --秒
}

----------------------------角色冻结--------------------------------------------
FREEZE_TYPE = {
    NO_FREEZE = 0, --未冻结
    GM = 1, --游戏管理冻结
    PAY = 2, --增值服务冻结
    PLUG_IN = 3, --工作室脚本行为冻结
    ACCOUNT_PRE_FREEZE = 4, --帐号分离冻结
    CONSIGN = 5, --角色出售冻结
}

---------------------------麻将枚举-----------------------------------------------
MahjongEffectType = {
    PENG = 1, --碰
    GANG = 2, --杠
    GSKH = 3, --杠上开花
    HDLY = 4, --海底捞月
    ZM = 5, --自摸
    HU = 6, --胡
    FP = 7, --放炮
    YPDX = 8, --一炮多响
    PASS = 9, --过牌
}

tUIPosIndex = {
    Down = 1,
    Left = 2,
    Up = 3,
    Right = 4,
}

tMahjongType = {
    Dot = 2, --筒
    Bamboo = 1, --条
    Character = 0, --万
}

tDirectionType = {
    East = 1,
    South = 2,
    West = 3,
    North = 4,
}

tPlayerState = {
    nDefault = 0,
    nNotReady = 1, --没有准备
    nReady = 2, --准备
    nLeave = 3, --离开
}

----------------------------斗地主枚举--------------------------------------------
GD_BOTTOM_TYPE = {
    CARDS_LINE = 3,
    CARDS_DOUBLE = 4,
    CARDS_TRIPLE = 5,
    CARDS_ROCKET = 6,
    CARDS_SJOKER = 7,
    CARDS_BJOKER = 8,
    CARDS_FLUSH = 9,
    CARDS_DOUBLE_SJOKER = 10,
    CARDS_DOUBLE_BJOKER = 11,
}

GD_CARD_TYPE = {
    SINGLE = 1,
    SINGLE_LINE = 2,
    DOUBLE = 3,
    DOUBLE_LINE = 4,
    TRIPLE = 5,
    TRIPLE_LINE = 6,
    TRIPLE_SINGLE = 7,
    TRIPLE_DOUBLE = 8,
    BOMB4_SINGLE = 9,
    BOMB4_DOUBLE = 10,
    BOMB4_BIG = 11,
    BOMB4 = 12,
    BOMB5 = 13,
    BOMB6 = 14,
    BOMB7 = 15,
    BOMB8 = 16,
    BOMB9 = 17,
    BOMB10 = 18,
    BOMB11 = 19,
    BOMB12 = 20,
    ROCKET = 21,
}

----------------------------------效果性能枚举----------------------------------

VIDEO_SETTING_TABLE_COINSHOP_START = 14
VIDEO_SETTING_TABLE_LOGIN_START = 24
VIDEO_SETTING_TABLE_STORY_START = 34
VIDEO_SETTING_TABLE_HOMELAND_START = 44
VIDEO_SETTING_TABLE_DUNGEON_START = 57
VIDEO_SETTING_TABLE_828_START = 67

----------------------------获取新表情枚举--------------------------------------------
NEW_EMOTION_TYPE = {
    EMOTION_ACTION = 1,
    BRIGHT_MARK = 2,
}
--------------RemoteData---------------------
REMOTE_DATA = {
	COMMANDER_FLAG = 1030,   --主指挥标记
	TREASURE_HUNT  = 1183,   --吃鸡寻宝模式(塔科夫)
	TOY_BOX        = 1066,   --玩具箱
	WXL_PUPPET     = 1207,   --无相楼傀儡模型选择
}
-------------------------------
ARG_STR = (function()
    local c = {}
    return setmetatable({}, {
        __index = function(t, k)
            if not c[k] then
                c[k] = "arg" .. k
            end
            return c[k]
        end,
    })
end)()

-------------------- 自定义背包类型 -------------------

UI_BOX_TYPE = {
    SHAREPACKAGE = "SharePackage",
    BANK = "Bank",
    CALL_UP_SKILL = "CallUpSkillBox",
    ACTION_BAR = "ActionBarBox",
}

------------------------------家园------------------------------
HOMELAND_BUILDING_MESSAGEBOX_TYPE = {
    BUY = 1,
    DISMANTLE = 2,
    RUBBING = 3,
}

HOMELAND_CONSTRUCT_TYPE = {
    HOLDER = 1,
    VISTOR = 2,
    WANDER = 3,
    COHABIT = 4,
}

HLB_INPUT_TYPE = {
    MAK = 1,    -- MOUSE_AND_KEYBOARD
    TOUCH = 2,
    COLUD = 3,  -- 不一定用得上，先统一用TOUCH
}

----------------------------家园订单-----------------------------
HLORDER_TYPE = {
    FLOWER = 1, --花匠
    COOK = 2, --厨师
    TONG = 3, --帮会
}

HLORDER_EXP_NAME = {
    [1] = "FlowerExp", --花匠
    [2] = "SellerExp", --厨师
}

HLIDENTITY_TYPE = {
    FISH = 1, --钓鱼人
    FLOWER = 2, --花匠
    COOK = 3, --厨师
}

UI_MAX_FURNITURE_CATEGORY_LIMIT = 20

------------------------------二维码充值------------------------------
QRCODE_RECHARGE_TYPE = {
    MONTH = 1,
    POINT = 2,
    TONG_BAO = 6,
}

-- 重要：数字的含义？ SCREE 的意义？
-- 家园宠物窝道具筛选 -挂宠和普通坐骑
PETS_SCREE_TYPE = {
    ORDINARYPET = 1, -- 一般宠物
    HANGUPPET = 36, -- 挂宠
    ORDINARYMOUNT = 35, -- 普通坐骑
    WEAPON = 101, -- 武器外装
}

-- 家园马匹游戏玩法
HOME_HOUSEPLAY_MINIGAMEID = 14
HOME_NEWHOUSEPLAY_MINIGAMEID = 16
BATTLEMAPISSELECTLINEMAPID = 512  --是否是选线地图,自由选择路线 白龙绝境等

------------------------------战场地图类型------------------------------
BATTLEFIELD_MAP_TYPE = {
    BATTLEFIELD = 0, -- 神浓烟（普通战场）
    TONGBATTLE = 1, -- 雪原争锋（帮会约战）
    NEWCOMERBATTLE = 3, -- 拭剑园
    TREASUREBATTLE = 4, -- 绝境战场（吃鸡）
    ZOMBIEBATTLE = 5, -- 李渡鬼域
    MOBABATTLE = 6, -- 列星岛（列星虚境Moba）
    FBBATTLE = 7, -- 野狸岛
    TONGWAR = 8, -- 雪龙风原（帮会联赛）
    PLEASANTGOAT = 9, -- 羊村大作战
    ROUGE_LIKE = 10, --八荒
    TREASURE_HUNT = 11,	--寻宝
    ARENA_TOWER = 12, -- 扬刀大会（肉鸽JJC爬塔）
}

-- 帮会联赛相关CD处理
TONG_LEAGUE_CD_ID = {
    TongLeagueApplyPQCDID = 1947,
}

-- 帮会联赛核心指挥人员 -- 0不显示，1核心，2指挥
TONG_LEAGUE_KEYPERSONNEL_TYPE = {
    ORDINARY = 0,
    KEYPERSONNEL = 1,
    COMMANDER = 2,
}

ACTIVITY_TYPE = {
    RELAX = 1, --休闲
    TEAM = 2, --协作
    CONFRONT = 3, --对抗
    HOME = 4, --家园
    HISTORY = 5, --往事
    LIKE = 6, --收藏
}

EQUIP_REFINE_SLOT_TYPE = {
    MATERIAL_IN_BAG = 1, -- 背包材料展示槽
    MATERIAL_CHOSEN = 2, --玩家已选择材料槽
    ADD_MATERIAL = 3, --新增材料槽
    EMPTY = 4,
    DISPLAY = 5
}

GameSettingCellType = {
    Slider = 1,
    Check = 2, -- 废弃
    DropBox = 3,
    Layout = 4,
    DropBoxSimple = 5,
    SliderCell = 6,
    MultiDropBox = 7,
    Button = 8,
    FontCell = 9,
    SoundSlider = 10,
    BlankLine = 11,
    SoundSlider_Short = 12,
}

--- 隐元秘鉴的成就和五甲使用同一个预制，通过传入这个枚举来进行区分
---
--- ps: 这个值与端游中的成就和五甲的 dwGeneral 的取值一致
ACHIEVEMENT_PANEL_TYPE = {
    ACHIEVEMENT = 1, -- 成就
    TOP_RECORD = 2, -- 五甲
}

ACHIEVEMENT_CATEGORY_TYPE = {
    SHOW_ALL = -1, -- 显示全部大类别，用于五甲页面特殊处理
}

------------------------------技能------------------------------

KSKILL_CAST_MODE = {
    scmTargetSingle = 14
}

MAX_SKILL_RECIPE_COUNT = 1

FUYAO_SKILL_ID = 100004
FUYAO_PRESS_TIME = 0.5 --单位为秒

CHANGE_SPRINT_PRESS_TIME = 0.5 --单位为秒
SHOW_TIP_PRESS_TIME = 1 --单位为秒
SHOW_COMBO_PRESS_TIME = 0.3 --单位为秒

UI_SKILL_UNIQUE_SLOT_ID = 6
UI_SKILL_DOUQI_SLOT_ID = 11

------------------------------奖励------------------------------
AWARD_RESEAON = {
    Invalid = 0, -- 收到该码代表奖励发放结束
    ReturnItem = 1, -- 退货
}

------------------------------结算界面---------------------------------
REWARD_TYPE = {
    GOLDEN = 1,
    SILVER = 2,
    COPPERY = 3,
    FAIL = 4,
}

------------------------------网络---------------------------------
NET_MODE = {
    NONE = 0, --无网络
    WIFI = 1, --wifi
    CELLULAR = 2, --蜂窝网络
}


------------------------------相机---------------------------------
CAMERA_AUTHORIZE_STATE =
{
    NotDetermined = 0,
    Restricted    = 1,
    Denied        = 2,
    Authorized    = 3,
}

CAMERA_CAPTURE_STATE = {
    Stop = 0,
    Wait4Authorize = 1,
    Capturing = 2,
}

------------------------------下载---------------------------------

--Engine\PakV5\PakV5.h: DOWNLOAD_OBJECT_STATE
DOWNLOAD_OBJECT_STATE = {
    DOWNLOADED = 0, --已下载
    DOWNLOADING = 1, --下载中,没有暂停
    PAUSE = 2, --下载中,但是暂停
    NOTEXIST = 3, --本地不存在
}

--Engine\PakV5\PakV5.h: DOWNLOAD_OBJECT_RESULT
DOWNLOAD_OBJECT_RESULT = {
    SUCCESS = 0, --下载成功
    EXCEPTION = 1, --异常失败
    NO_SPACE_FAIL = 2, --没有足够磁盘空间
    NET_ERROR = 3, --网络问题
    RESOURCE_ERROR = 4, --资源没有通过检测验证
    DELETED_INTERRUPT = 5, --删除导致中断
    CANCEL_INTERRUPT = 6, --取消导致中断
}

DOWNLOAD_STATE = {
    NONE = 0, --无
    DOWNLOADING = 1, --下载
    QUEUE = 2, --排队
    PAUSE = 3, --暂停
    COMPLETE = 4, --完成
    FAILED = 5, --失败
}

TOTAL_DOWNLOAD_STATE = {
    NONE = 0, --无
    DOWNLOADING = 1, --下载中
    RETRYING = 2, --重试中
    PAUSING = 3, --暂停中
}

RESOURCE_EXIST_STATE = {
    REMOTE_EXIST = 0, -- 本地不存在，远端存在
    LOCAL_EXIST = 1, -- 本地存在
    NOT_EXIST = 2, -- 本地不存在，远端也不存在
}

RESOURCE_DELETE_STATE = {
    CAN_DELETE = 0, --可删除
    NOT_EXIST = 1, --不可删除-未下载
    DOWNLOADING = 2, --不可删除-正在下载
    BASIC_PACK = 3, --不可删除-基础包
    CORE_PACK = 4, --不可删除-核心包
    PRIORITY_PACK = 5, --不可删除-优先包
    CURRENT_MAP = 6, --不可删除-当前地图
}

TASK_TRIGGER_TYPE = {
    CORE = 1, --核心队列
    PRIORITY = 2, --优先队列
    DEFAULT = 3, --默认队列
}

---------------------------------------------------------------
STAT_TYPE = {
    DAMAGE = "伤害统计",
    THERAPY = "治疗统计",
    BE_DAMAGE = "承伤统计",
    BE_THERAPY = "承疗统计",
    HATRED = "Hatred"
}

DATA_TYPE = {
    TOTAL = 0,
    ONCE = 1,
}

LOGIN_SCENE_ID = 1000000

ControlDef = {
    CONTROL_FORWARD = 0,
    CONTROL_BACKWARD = 1,
    CONTROL_TURN_LEFT = 2,
    CONTROL_TURN_RIGHT = 3,
    CONTROL_STRAFE_LEFT = 4,
    CONTROL_STRAFE_RIGHT = 5,
    CONTROL_CAMERA = 6,
    CONTROL_OBJECT_STICK_CAMERA = 7,
    CONTROL_WALK = 8,
    CONTROL_JUMP = 9,
    CONTROL_AUTO_RUN = 10,
    CONTROL_FOLLOW = 11,
    CONTROL_UP = 12,
    CONTROL_DOWN = 13,
}

UI_FAILED_COLOR = "#ff7575"
UI_SUCCESS_COLOR = "#ECDF22"

------------------------------风云录界面---------------------------------

LAST_WEEK_RANK_TYPE_HQ = 214
LAST_WEEK_RANK_TYPE_ER = 215

-----------------------------限时拍卖--------------------------------------

CampToBlackMarketType = {
    [CAMP.GOOD] = BLACK_MARKET_TYPE.GOOD,
    [CAMP.EVIL] = BLACK_MARKET_TYPE.EVIL,
    [CAMP.NEUTRAL] = BLACK_MARKET_TYPE.NEUTRAL,
}

----------------------------动态技能球------------------------------------
ACTION_BAR_STATE = {
    COMMON = 1, --通用
    MARK = 2, --标记
    SWORDSMAN = 3, --侠客
    IDENTITY = 4, --身份
    TREASUREBATTLE = 5, -- 吃鸡
    BAIZHAN = 6, --百战
    CUSTOM = 7, --自定义
    TOY = 8,    --玩具
    FLYSTAR = 9, --唐门飞星
    DXTEAMMARK = 10, --DX团队标记
    DXYAOZONGPLANT = 11, --DX药宗
    ARENATOWER = 12, --扬刀大会
}
----------------------------玩法集成-----------------------------------------

CLASS_MODE = {
    DEFAULT = 0,
    FB = 1, --秘境
    CAMP = 2, --阵营
    CONTEST = 3, --竞技
    RELAXATION = 4, --休闲
}
CLASS_TYPE = {
    NORMAL = 0, --普通/常驻
    SPECIAL = 1, --特殊/限时
    JJC = 3,
    BATTLEFIELD = 4,
    DESERTSTORM = 5,
    HOME = 6,
    REST = 7,
}

HONOR_CHALLENGE_PAGE = {
    REST = 1,
    SECRET = 2,
    ATHLETICS = 3,
}

LOAD_LOGIN_REASON = {
    KICK_OUT_BY_GM = 1,
    KICK_OUT_BY_OTHERS = 2,
    KICK_OUT_FOR_UNDERAGE_LIMIT = 3,
}

COLLECTION_PAGE_TYPE = {
    DAY = 1, --日课
    SECRET = 2, --秘境
    ATHLETICS = 3, --竞技
    CAMP = 4, --阵营
    REST = 5, --休闲
}

DX2VK_COLLECTION_PAGE_TYPE = {
    ["Page_Daily"]  = COLLECTION_PAGE_TYPE.DAY,
    ["Page_FB"]     = COLLECTION_PAGE_TYPE.SECRET,
    ["Page_Contest"]  = COLLECTION_PAGE_TYPE.ATHLETICS,
    ["Page_Camp"]   = COLLECTION_PAGE_TYPE.CAMP,
    ["Page_Leisure"]  = COLLECTION_PAGE_TYPE.REST,

}

SHOW_TIP_EVENT_LIST = {
    EventType.ShowNormalTip,
    EventType.ShowImportantTip,
    EventType.ShowPlaceTip,
    EventType.PlayProgressBarTip,
    EventType.ShowLevelUpTip,
    EventType.ShowNewAchievement,
    EventType.ShowNewDesignation,
    EventType.ShowQuickEquipTip,
    EventType.ShowEquipScore,
    EventType.ShowQuestComplete,
    EventType.ShowAnnounceTip,
    EventType.ShowRewardListTip,
    EventType.PlayCountDown,
    EventType.UpdateCountDown,
    EventType.ShowNewFeatureTip,
    EventType.OnSendSystemAnnounce,
    EventType.ShowLikeTip,
    EventType.ShowInteractTip,
    EventType.ShowTeamTip,
    EventType.ShowMobaSurrenderTip,
    EventType.ShowRoomTip,
    EventType.ShowBiaoShiTip,
    EventType.ShowHuBiaoTip,
    EventType.UpdateDeathNotify,
    EventType.ShowTradeTip,
    EventType.ShowCampHint,
    EventType.ShowHintSFX,
    EventType.RefreshAltar,
    EventType.RefreshBoss,
    EventType.OnStartEvent,
    EventType.ShowAssistNewbieInviteTip,
    EventType.ShowTeamReadyConfirmTip,
}

CURSOR_PATH = {
    DEFAULT = "./ui/Image/cursor/normal_mb.cur",
    SELL = "./ui/Image/cursor/sell_mb.cur",
    UNABLE_SELL = "./ui/Image/cursor/unablesell_mb.cur",
    FLOWER = "./ui/Image/cursor/flower_mb.cur", -- 采花
    UNABLE_FLOWER = "./ui/Image/cursor/unableflower_mb.cur", -- 不能采花
    MINERAL = "./ui/Image/cursor/mine_mb.cur", -- 采矿
    UNABLE_MINERAL = "./ui/Image/cursor/unablemine_mb.cur", -- 不能采矿
    SEARCH = "./ui/Image/cursor/search_mb.cur", -- 庖丁
    UNABLE_SEARCH = "./ui/Image/cursor/unablesearch_mb.cur", -- 不能庖丁
    ATTACK = "./ui/Image/cursor/attack_mb.cur", -- 攻击
    UNABLE_ATTACK = "./ui/Image/cursor/unableattack_mb.cur", -- 不能攻击
    READ = "./ui/Image/cursor/read_mb.cur", -- 阅读
    UNABLE_READ = "./ui/Image/cursor/unableread_mb.cur", -- 不能阅读
    SPEAK = "./ui/Image/cursor/speak_mb.cur", -- 说话
    UNABLE_SPEAK = "./ui/Image/cursor/unablespeak_mb.cur", -- 不能说话
    LOOT = "./ui/Image/cursor/loot1_mb.cur", -- 拾取
    UNABLE_LOOT = "./ui/Image/cursor/unableloot1_mb.cur", -- 不能拾取
    LOCK = "./ui/Image/cursor/lock_mb.cur", -- 开锁
    UNABLE_LOCK = "./ui/Image/cursor/unablelock_mb.cur", -- 不能开锁
}

ACTOR_SOUND = {
    NPC = 0,
    PLAYER = 1,
    OTHER_PLAYER = 2,
    CLOAK = 3,
}

-- 主城场景ID列表
MAIN_CITY_MAP_IDS = {6, 108, 194, 332}
-- 多人场景ID列表
MULTI_PLAYER_MAP_IDS =
{
    9, 13, 21, 22, 23, 25, 27, 30, 35, 38, 48, 50, 52, 100, 101, 103, 104,
    105, 135, 139, 153, 186, 214, 215, 216, 217, 330, 334, 411, 444, 473,
    474, 475, 488, 580, 648, 296, 297, 301, 410, 426, 452, 482, 518, 532,
    559, 573, 627, 645, 677, 676, 579, 581, 582, 586, 621, 636, 656, 668,
    686, 689, 695, 673, 697, 709, 715, 712, 713, 718
}
-- 新副本列表（不进行角度裁剪）
MODEL_CULL_DUNGEON_MAP_IDS = {
    706, 707, 708, 710, 711, 722, 723, 724, 725, 726, 793, 794, 795
}

LKX_MAP_IDS = {
    421, 422, 423, 424, 425, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 461, 527, 528}

SKILL_RESTRICTION_LEVEL = 106

UNLOCK_ANITYPE = {
    MENU = 1,
    RIGHTTOP = 2
}

--这些界面在时不允许弹出热点图
HOTSPOT_VIEW_LIST ={
    VIEW_ID.PanelVideoPlayer,
    VIEW_ID.PanelPlotDialogue,
    VIEW_ID.PanelTask,
    VIEW_ID.PanelMiddleMap,
    VIEW_ID.PanelHotSpotBanner,
    VIEW_ID.PanelPvpJJCInherit,
    VIEW_ID.PanelCareerOpenPop,
    VIEW_ID.PanelCareer,
}

EnchantCategory = {
    Normal = 1, -- 普通附魔
    Season = 2, -- 赛季大附魔
    Limit = 3, -- 限时大附魔
}

CUSTOM_RANGE = {
    LEFT = 1,
    RIGHT = 2,
    FULL = 3,
    CHAT = 4
}

CUSTOM_TYPE = {
    TASK = 9,
    TARGET = 2,
    MENU = 6,
    CUSTOMBTN = 3,
    CHAT = 8,
    PLAYER = 1,
    QUICKUSE = 4,
    SKILL = 7,
    BUFF = 5,
    ENERGYBAR = 13,
    SPECIALSKILLBUFF = 14,
    KILL_FEED = 15,
}

CUSTOM_BTNSTATE = {
    COMMON = 1, --非编辑状态
    ENTER = 2,  --编辑前的白框状态
    CONFLICT = 3, --重叠状态
    OTHER = 4,   --已进入其他节点的编辑状态
    EDIT = 5    --进入当前节点的编辑状态
}

CUSTOM_VERSION = 4

CUSTOM_MODULE_VERSION = {
    TASK = 0,
    TEAM = 0,
    TARGET = 0,
    MENU = 0,
    CUSTOMBTN = 1,
    CHAT = 1,
    PLAYER = 0,
    QUICKUSE = 0,
    SKILL = 0,
    BUFF = 0,
    ENERGYBAR = 0,
    SPECIALSKILLBUFF = 0,
    KILL_FEED = 0,
}

DRAGNODE_TYPE = {
    ACTIONBAR = 10,
    DBM = 11,
    DPS = 12,
    TEAMNOTICE = 16,
}

CurrencyType =
{
    None = "None",
    Prestige = "Prestige",
    Justice  = "Justice",
    Architecture = "Architecture",
    FeiShaWand = "SandstormAward",
    MentorAward = "MentorAward",
    Contribution = "Contribution",
    ExamPrint = "ExamPrint",
    HomelandToken = "HomelandToken",
    DungeonTowerAward = "DungeonTowerAward",
    Rover = "Rover",
    ArenaTowerAward = "ArenaTowerAward",
    TongLeaguePoint = "TongLeaguePoint",
    WeekAward = "WeekAward",
    SeasonHonorXiuXian = "SeasonHonorXiuXian",
    SeasonHonorMiJing = "SeasonHonorMiJing",
    SeasonHonorPVP = "SeasonHonorPVP",
    SandstormAward = "SandstormAward",
    ZhuiGanShopAward = "ZhuiGanShopAward",

    Money = "金钱",
    Train = "修为",
    Vigor = "精力值",
    Experience = "阅历",
    TitlePoint = "战阶积分",
    Coin     = "通宝",
    StorePoint = "商城积分",
    GangFunds = "帮会资金·个人",
    CoinShopVoucher = "佟仁银票",
    AchievementPoint = "江湖资历",
    Reputation = "声望",
    TongResource = "载具物资",
    NormalFragment = "结庐点数",
    FishExp = "垂钓客阅历",
    FlowerExp = "调香师阅历",
    SellerExp = "大掌柜阅历",
    PersonAthScore = "个人竞技分",
    WinItem = "昭武符·日",
    LeYouBi = "乐游币",
    FaceVouchers = "通宝代金币",
    PrestigeLimit = "威名点周上限",
    TianJiToken = "天机筹",
    MonopolyCoin = "大富翁代币",
    MonopolyMoney = "大富翁现金",
    MonopolyPoint = "大富翁点券",
    TotalGangFunds = "帮会资金",
}

--跨服显示PQ图标应用地图
SHOW_PQ_MAP =
{
	[579] = true,
	[580] = true,
	[581] = true,
	[582] = true,
	[647] = true,
    [673] = true,
    [713] = true,
}


-- 扩展点定义枚举
EXT_POINT =
{
    BAR_MITZVAH            = 505,   -- 18岁成年
    COINSHOP_FISSION       = 744,   -- 商城裂变活动总优惠券数量
    COINSHOP_FISSION_STATE = 745,   -- 商城裂变活动奖励领取状态
    CERTIFICATION          = 796,   -- 认证创作者
    REMIAN_QUOTA           = 799,   -- 剩余提现额度
    WITHDRAW_TIMES         = 797,   -- 上次提现周期
    DAILY_QUOTA            = 800,   -- 周期提现额度
}

--逻辑未导出 以后慢慢加
AUC_GENRE = {
	CLOTH = 22,
	CAN_NOT_AUC = 99,--不能上架交易行
	DESERT = 26, --沙漠吃鸡
}

--获取途径分类
ITEM_SOURCE_TYPE = {
	CRAFT 		 = 1,  --生活技能
	BOSS 		 = 2,  --秘境掉落
	ACTIVITY 	 = 3,  --活动
	SHOP 		 = 4,  --商店
	TREASURE_BOX = 5,  --宝箱
	QUEST 		 = 6,  --任务
	TRADE		 = 7,  --交易行
	COINSHOP 	 = 8,  --商城
	REPUTATION   = 9,  --声望
	ACHIEVEMENT  = 10, --成就
	ADVENTURE	 = 11, --奇遇
	LINK 		 = 12, --玩法
}

--预约地图状态
MAP_APPOINTMENT_SATE = {
	CANNOT_BOOK    = 0,  --不能预约
	CAN_BOOK       = 1,  --可以预约
	ALREADY_BOOKED = 2,  --预约中

}

--阵营管理
TEAM_MEMBER_TYPE = {
	["invalid"] = 0,
	["member"] = 1,
	["leader"] = 2,
}

-- 五行石索引
WU_XING_STONE_ITEM_ID = {
    [1] = 24423,
    [2] = 24424,
    [3] = 24425,
    [4] = 24426,
    [5] = 24427,
    [6] = 24428,
    [7] = 24429,
    [8] = 24430,
}

-- 配置表缓存清理阶段
KCACHE_CLEAR_STAGE = {
    ccsSwitchMap = 0,   -- 切换场景
    ccsResetGame = 1,   -- 重置游戏（如：登出场景）
}

-- 小型设置弹窗界面内含组件的类型
MINI_SETTING_COM_TYPE = {
    SWITCH = 0, -- 带文字描述的开关
    OPTION_S = 1, -- 带文字描述的小型复选框
    OPTION_L = 2, -- 带文字描述的大型复选框
}

BAG_CONTAIN_TYPE = {
	CASTING = 1,    --石矿
	MEDICAL = 2,    --草药
	BOOK    = 4,    --书
}

PRAISE_TYPE = {
	TEAM_LEADER = 0,  -- 好团长
	MASTER = 1,       -- 好师父
	BIAO_SHI = 2,     -- 镖师
	GREAT_LEADER = 3, -- 当前版本的副本团长点赞
	WAR_LEADER = 4,   -- 好指挥
	ARENA = 5,        -- 竞技场
	BATTLE_FIELD = 6, -- 战场
	HELPER = 7,       -- 友爱之人
	PERSONAL_CARD = 8,-- 名片
}

TREASURE_BOX_TYPE = {
    RANDOM = 1,   --随机宝箱
    OPTIONAL = 3, --自选宝箱
    QIYU = 2,     --奇遇宝箱
}

--伤害统计
HURT_STAT_TYPE = {
    BALL = 1, -- 伤害统计悬浮球
    PANEL = 2, -- 伤害统计页
}

DUNGEON_FIGHT_DATA = {
	DAMAGE     = 0,
	THERAPY    = 1,
	BE_DAMAGE  = 2,
	BE_THERAPY = 3,
}

STAT_TYPE2ID = {
    [STAT_TYPE.DAMAGE] = DUNGEON_FIGHT_DATA.DAMAGE,
    [STAT_TYPE.THERAPY] = DUNGEON_FIGHT_DATA.THERAPY,
    [STAT_TYPE.BE_DAMAGE] = DUNGEON_FIGHT_DATA.BE_DAMAGE,
    [STAT_TYPE.BE_THERAPY] = DUNGEON_FIGHT_DATA.BE_THERAPY,
}

EXCELLENT_SHOW_TYPE = {
    ARENA   = 1, -- FINAL_TYPE.ARENA
    BF      = 2, -- FINAL_TYPE.BF
    DUNGEON = 3,
}

QIXUE_TYPE = {
    OTHER_POP = 0,
    PVP_SHOW = 1,
}

DUNGEON_EXCELLENT_ID = {
	DAMAGE = 1,  -- 最佳输出
	THERAPY = 2, -- 最佳治疗
	BE_DAMAGE = 3, -- 最佳承伤
	GREAT_LEADER = 4, -- 优秀团长
	GREAT_DAMAGE = 5, -- 最佳输出（没有团长版）
}

JX_KUNGFU_TYPE = {
    DPS = 1,
    HPS = 2,
    TANK = 3,
    OTHER = 4,
}

SWORDMEMORIY_SEASONIDLIST = {
    1,2,3,4,5,6,7,8
}

CAMP_PQID = {
    473,474,475,476
}

SHOW_TRAFFIC_DUNGEON_MAP =
{
    [451] ={735},
}

---@enum ACTOR_FLITER_TYPE 角色显示过滤类型
ACTOR_FLITER_TYPE = {
    ACTOR_FLITER_TYPE_SHOW                 = 1,
    ACTOR_FLITER_TYPE_RIDE                 = 2,
    ACTOR_FLITER_TYPE_MOVIE_SHOW           = 4,
    ACTOR_FLITER_TYPE_LOCAL_EMPLOYEE       = 8,
    ACTOR_FLITER_TYPE_MOVIE_BODY_RESHAPING = 16,
    ACTOR_FLITER_TYPE_SCREEN_SHOOT         = 32,
}

OBJ_TYPE ={
	NPC = 1,
	DOODAD = 2,
	ITEM = 3,
	FURNITURE = 4,
	COMPASS = 5,
	WORKBENCH = 6,
	PETACTION = 7,
}

PARTNER_FIGHT_LOG_TYPE = {
    NONE = "none",
    SELF = "self",
    ALL = "all",
}

PARTNER_TRAVEL_TYPE = {
    AVAILABLE = 1,
    ARRANGED = 2,
    INTRAVEL = 3,
    UNKNOWN = 4,
}

FORCE_USE_EMBEDDED_WEBPAGES_IN_WINDOWS_ID = {
    [66] = true,
}

MAX_BLOCK_BOX_COUNT = 25

-- 手机端强制开启同模效果
MOBILE_FORCE_CAMP_UNIFORM_MAPS = {
    38, 48, 50, 52, 135, 186, 712
}

PENDENT_HEAD_TYPE =
{
    PENDENT_SELECTED_POS.HEAD,
    PENDENT_SELECTED_POS.HEAD1,
    PENDENT_SELECTED_POS.HEAD2,
}

ForceIDToMountType = {
    [FORCE_TYPE.TIAN_CE] = KUNGFU_TYPE.TIAN_CE,
    [FORCE_TYPE.WAN_HUA] = KUNGFU_TYPE.WAN_HUA,
    [FORCE_TYPE.CHUN_YANG] = KUNGFU_TYPE.CHUN_YANG,
    [FORCE_TYPE.QI_XIU] = KUNGFU_TYPE.QI_XIU,
    [FORCE_TYPE.SHAO_LIN] = KUNGFU_TYPE.SHAO_LIN,
    [FORCE_TYPE.CANG_JIAN] = KUNGFU_TYPE.CANG_JIAN,
    [FORCE_TYPE.GAI_BANG] = KUNGFU_TYPE.GAI_BANG,
    [FORCE_TYPE.MING_JIAO] = KUNGFU_TYPE.MING_JIAO,
    [FORCE_TYPE.WU_DU] = KUNGFU_TYPE.WU_DU,
    [FORCE_TYPE.TANG_MEN] = KUNGFU_TYPE.TANG_MEN,
    [FORCE_TYPE.CANG_YUN] = KUNGFU_TYPE.CANG_YUN,
    [FORCE_TYPE.CHANG_GE] = KUNGFU_TYPE.CHANG_GE,
    [FORCE_TYPE.BA_DAO] = KUNGFU_TYPE.BA_DAO,
    [FORCE_TYPE.PENG_LAI] = KUNGFU_TYPE.PENG_LAI,
    [FORCE_TYPE.LING_XUE] = KUNGFU_TYPE.LING_XUE,
    [FORCE_TYPE.YAN_TIAN] = KUNGFU_TYPE.YAN_TIAN,
    [FORCE_TYPE.YAO_ZONG] = KUNGFU_TYPE.YAO_ZONG,
    [FORCE_TYPE.DAO_ZONG] = KUNGFU_TYPE.DAO_ZONG,
    [FORCE_TYPE.WAN_LING] = KUNGFU_TYPE.WAN_LING,
    [FORCE_TYPE.DUAN_SHI] = KUNGFU_TYPE.DUAN_SHI,
}

SchoolTypeToForceID =
{
    [SCHOOL_TYPE.TIAN_CE] = FORCE_TYPE.TIAN_CE,
    [SCHOOL_TYPE.WAN_HUA] = FORCE_TYPE.WAN_HUA,
    [SCHOOL_TYPE.CHUN_YANG] = FORCE_TYPE.CHUN_YANG,
    [SCHOOL_TYPE.QI_XIU] = FORCE_TYPE.QI_XIU,
    [SCHOOL_TYPE.SHAO_LIN] = FORCE_TYPE.SHAO_LIN,
    [SCHOOL_TYPE.CANG_JIAN_WEN_SHUI] = FORCE_TYPE.CANG_JIAN,
    [SCHOOL_TYPE.CANG_JIAN_SHAN_JU] = FORCE_TYPE.CANG_JIAN,
    [SCHOOL_TYPE.GAI_BANG] = FORCE_TYPE.GAI_BANG,
    [SCHOOL_TYPE.MING_JIAO] = FORCE_TYPE.MING_JIAO,
    [SCHOOL_TYPE.WU_DU] = FORCE_TYPE.WU_DU,
    [SCHOOL_TYPE.TANG_MEN] = FORCE_TYPE.TANG_MEN,
    [SCHOOL_TYPE.CANG_YUN] = FORCE_TYPE.CANG_YUN,
    [SCHOOL_TYPE.CHANG_GE] = FORCE_TYPE.CHANG_GE,
    [SCHOOL_TYPE.BA_DAO] = FORCE_TYPE.BA_DAO,
    [SCHOOL_TYPE.PENG_LAI] = FORCE_TYPE.PENG_LAI,
    [SCHOOL_TYPE.LING_XUE] = FORCE_TYPE.LING_XUE,
    [SCHOOL_TYPE.YAN_TIAN] = FORCE_TYPE.YAN_TIAN,
    [SCHOOL_TYPE.YAO_ZONG] = FORCE_TYPE.YAO_ZONG,
    [SCHOOL_TYPE.DAO_ZONG] = FORCE_TYPE.DAO_ZONG,
    [SCHOOL_TYPE.WAN_LING] = FORCE_TYPE.WAN_LING,
    [SCHOOL_TYPE.DUAN_SHI] = FORCE_TYPE.DUAN_SHI,
}

MountTypeToSchoolType =
{
    [KUNGFU_TYPE.TIAN_CE] = SCHOOL_TYPE.TIAN_CE,
    [KUNGFU_TYPE.WAN_HUA] = SCHOOL_TYPE.WAN_HUA,
    [KUNGFU_TYPE.CHUN_YANG] = SCHOOL_TYPE.CHUN_YANG,
    [KUNGFU_TYPE.QI_XIU] = SCHOOL_TYPE.QI_XIU,
    [KUNGFU_TYPE.SHAO_LIN] = SCHOOL_TYPE.SHAO_LIN,
    [KUNGFU_TYPE.CANG_JIAN] = SCHOOL_TYPE.CANG_JIAN_WEN_SHUI,
    [KUNGFU_TYPE.GAI_BANG] = SCHOOL_TYPE.GAI_BANG,
    [KUNGFU_TYPE.MING_JIAO] = SCHOOL_TYPE.MING_JIAO,
    [KUNGFU_TYPE.WU_DU] = SCHOOL_TYPE.WU_DU,
    [KUNGFU_TYPE.TANG_MEN] = SCHOOL_TYPE.TANG_MEN,
    [KUNGFU_TYPE.CANG_YUN] = SCHOOL_TYPE.CANG_YUN,
    [KUNGFU_TYPE.CHANG_GE] = SCHOOL_TYPE.CHANG_GE,
    [KUNGFU_TYPE.BA_DAO] = SCHOOL_TYPE.BA_DAO,
    [KUNGFU_TYPE.PENG_LAI] = SCHOOL_TYPE.PENG_LAI,
    [KUNGFU_TYPE.LING_XUE] = SCHOOL_TYPE.LING_XUE,
    [KUNGFU_TYPE.YAN_TIAN] = SCHOOL_TYPE.YAN_TIAN,
    [KUNGFU_TYPE.YAO_ZONG] = SCHOOL_TYPE.YAO_ZONG,
    [KUNGFU_TYPE.DAO_ZONG] = SCHOOL_TYPE.DAO_ZONG,
    [KUNGFU_TYPE.WAN_LING] = SCHOOL_TYPE.WAN_LING,
    [KUNGFU_TYPE.DUAN_SHI] = SCHOOL_TYPE.DUAN_SHI,
    [KUNGFU_TYPE.WU_XIANG] = SCHOOL_TYPE.WU_XIANG,
}

----------------------------------账号/角色限制----------------------------------
LIMIT_TYPE = {
	MONEY_PRODUCTION = 1, -- 限制金钱产出
	TIME_ACCOUNT = 2,     -- 限制账号时间
	TIME_CHARACTER = 3,   -- 限制角色时间
}