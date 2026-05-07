LieXingXuJingData                          = LieXingXuJingData or {}
local self                                 = LieXingXuJingData

LieXingXuJingData.tLineColorStyle          = {
    Black = 1, --- 未点亮
    Yellow = 2, --- 当前选中装备
    Green = 3, --- 当前已购买装备
}

LieXingXuJingData.tLineColorStyleToColor   = {
    [LieXingXuJingData.tLineColorStyle.Black] = cc.c3b(41, 71, 69),
    [LieXingXuJingData.tLineColorStyle.Yellow] = cc.c3b(255, 249, 75),
    [LieXingXuJingData.tLineColorStyle.Green] = cc.c3b(91, 231, 117),
}

LieXingXuJingData.tLineDirection           = {
    Up = 1,
    Down = 2,
    Left = 3,
    Right = 4,
    Middle = 5,
}

--- 装备类别数目
LieXingXuJingData.EQUIPMENT_TYPE_NUM       = 6

--- 局内的装备栏与端游一样，使用固定的展示顺序
LieXingXuJingData.tInGameEquipmentSubOrder = {
    EQUIPMENT_INVENTORY.MELEE_WEAPON, -- 武器
    EQUIPMENT_INVENTORY.HELM, -- 帽子
    EQUIPMENT_INVENTORY.CHEST, -- 上衣
    EQUIPMENT_INVENTORY.WAIST, -- 腰带
    EQUIPMENT_INVENTORY.BANGLE, -- 护腕
    EQUIPMENT_INVENTORY.BOOTS, -- 鞋子
}

--- 获取装备栏的类型顺序列表，按此顺序在装备栏展示装备
--- @param bInGame boolean 是否处于局内
--- @param bInEditMode boolean 是否处于编辑模式
--- @param tEditEquipments MobaShopPrePurchase 编辑模式下的预设装备
--- @return number[]
function LieXingXuJingData.GetEquipListTypeOrderList(bInGame, bInEditMode, tEditEquipments)
    local tEquipmentSubOrderList

    if bInGame then
        --- 局内使用固定的顺序展示
        tEquipmentSubOrderList = self.tInGameEquipmentSubOrder
    else
        --- 局外使用当前的预设装备的顺序展示，若处于编辑模式下，则以编辑中的预设装备为准
        --- @type MobaShopPrePurchase
        local tEquipments
        if bInEditMode then
            tEquipments = tEditEquipments
        else
            tEquipments = self.GetPrePurchase()
        end

        tEquipmentSubOrderList                      = {}

        --- 某些位置可能没有装备，且不包含类别信息，则先使用一个特别的值，在最后将未使用的类别替换到这些位置
        local EMPTY_INDEX_EQUIPMENT_SUB_PLACEHOLDER = -1

        --- 无类别的空槽位序号列表
        local tEmptyIndexList                       = {}
        --- 当前未使用的类别列表
        local tNotUsedEquipmentSubList              = clone(self.tInGameEquipmentSubOrder)

        --- 根据预设装备列表，倒推出各个位置的装备类别
        for nIndex = 1, self.EQUIPMENT_TYPE_NUM do
            local nEquipmentSub

            local nID = tEquipments["nEquipmentLocalID" .. tostring(nIndex)]
            if nID then
                if nID > 0 then
                    --- 正数表明这个位子有设置装备，读配置表取其类别
                    local tInfo   = Table_GetMobaShopItemUIInfoByID(nID)
                    nEquipmentSub = tInfo.nEquipmentSub
                elseif nID < 0 then
                    --- 负数则表明这个位置在编辑时主动清除，会被设置为该位置之前装备的类别的相反数，这里取反即可获得类别
                    nEquipmentSub = -1 * nID
                end
            end

            if nEquipmentSub == nil then
                --- 标记为空位置，并记录下来
                nEquipmentSub = EMPTY_INDEX_EQUIPMENT_SUB_PLACEHOLDER
                table.insert(tEmptyIndexList, nIndex)
            else
                --- 从未使用类别中移除
                table.remove_value(tNotUsedEquipmentSubList, nEquipmentSub)
            end

            table.insert(tEquipmentSubOrderList, nEquipmentSub)
        end

        --- 如果有无法判定类别的空位置，则在这里将未使用的类别填充进去（以局内装备的顺序，这样可以确保每次处理都一样） 
        if table.get_len(tEmptyIndexList) > 0 then
            for i = 1, table.get_len(tEmptyIndexList) do
                local nEmptyIndex                   = tEmptyIndexList[i]
                local nNotUsedEquipmentSub          = tNotUsedEquipmentSubList[i]

                tEquipmentSubOrderList[nEmptyIndex] = nNotUsedEquipmentSub
            end
        end
    end

    return tEquipmentSubOrderList
end

--- 装备名称 -> 装备部位枚举
LieXingXuJingData.tEquipmentNames      = {
    Weapon = EQUIPMENT_INVENTORY.MELEE_WEAPON, -- 武器
    Helm = EQUIPMENT_INVENTORY.HELM, -- 帽子
    Clothes = EQUIPMENT_INVENTORY.CHEST, -- 上衣
    Waist = EQUIPMENT_INVENTORY.WAIST, -- 腰带
    Bangle = EQUIPMENT_INVENTORY.BANGLE, -- 护腕
    Boots = EQUIPMENT_INVENTORY.BOOTS, -- 鞋子
}

--- 装备部位枚举 -> 空装备的图标
LieXingXuJingData.tEquipmentEmptyIcon  = {
    [EQUIPMENT_INVENTORY.MELEE_WEAPON] = "UIAtlas2_Shopping_ShoppingIcon_icon_19.png", -- 武器
    [EQUIPMENT_INVENTORY.HELM] = "UIAtlas2_Shopping_ShoppingIcon_icon_11.png", -- 帽子
    [EQUIPMENT_INVENTORY.CHEST] = "UIAtlas2_Shopping_ShoppingIcon_icon_12.png", -- 上衣
    [EQUIPMENT_INVENTORY.WAIST] = "UIAtlas2_Shopping_ShoppingIcon_icon_16.png", -- 腰带
    [EQUIPMENT_INVENTORY.BANGLE] = "UIAtlas2_Shopping_ShoppingIcon_icon_30.png", -- 护腕
    [EQUIPMENT_INVENTORY.BOOTS] = "UIAtlas2_Shopping_ShoppingIcon_icon_15.png", -- 鞋子
}

---@class MobaShopPrePurchase 商店预购方案
---@field nID number 预购方案ID
---@field nKungfuMountID number 适用的心法ID
---@field nEquipmentLocalID1 number 槽位1的moba装备ID
---@field nEquipmentLocalID2 number 槽位2的moba装备ID
---@field nEquipmentLocalID3 number 槽位3的moba装备ID
---@field nEquipmentLocalID4 number 槽位4的moba装备ID
---@field nEquipmentLocalID5 number 槽位5的moba装备ID
---@field nEquipmentLocalID6 number 槽位6的moba装备ID
---@field szName string 名称
---@field szNote string 备注

--- 当前局内手动设置的预购装备ID
LieXingXuJingData.nPlayerPrePurchaseID = nil

function LieXingXuJingData.InitPrePurchase(bResetInGamePrePurchase)
    if bResetInGamePrePurchase then
        self.nPlayerPrePurchaseID = nil
    end

    local nKungfuMountID = self.GetKungFuMountID()
    if not nKungfuMountID then
        return
    end

    --记录版本号
    local nVersion       = 1
    local bVersionUpdate = false
    if Storage.MobaShop_tPrePurchase.nVerson ~= nVersion then
        Storage.MobaShop_tPrePurchase.nVerson = nVersion
        Storage.MobaShop_tPrePurchase.Dirty()

        bVersionUpdate = true
    end

    if not Storage.MobaShop_tPrePurchase.tPlans[nKungfuMountID] or bVersionUpdate then
        Storage.MobaShop_tPrePurchase.tSelectingPlan[nKungfuMountID] = 1
        Storage.MobaShop_tPrePurchase.tPlans[nKungfuMountID]         = clone(TableGetMobaShopPrePurchase(nKungfuMountID))
        Storage.MobaShop_tPrePurchase.Dirty()
    end
end

function LieXingXuJingData.GetKungFuMountID()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nKungfuMountID = pPlayer.GetKungfuMountID()
    if not nKungfuMountID then
        return
    end

    if Kungfu_GetType(nKungfuMountID) == FORCE_TYPE.CANG_JIAN then
        nKungfuMountID = 10144 --藏剑内功特殊处理，两个内功当作一个
    end

    return nKungfuMountID
end

function LieXingXuJingData.GetPrePurchaseIndex()
    local nKungfuMountID    = self.GetKungFuMountID()
    local nPrePurchaseIndex = Storage.MobaShop_tPrePurchase.tSelectingPlan[nKungfuMountID]

    return nPrePurchaseIndex
end

---@return MobaShopPrePurchase
function LieXingXuJingData.GetPrePurchase()
    local nKungfuMountID    = self.GetKungFuMountID()
    local nPrePurchaseIndex = self.GetPrePurchaseIndex()
    local tPrePurchase      = Storage.MobaShop_tPrePurchase.tPlans[nKungfuMountID][nPrePurchaseIndex]

    return tPrePurchase
end

---@param tNewPrePurchase MobaShopPrePurchase
function LieXingXuJingData.SetPrePurchase(tNewPrePurchase)
    local nKungfuMountID                                                    = self.GetKungFuMountID()
    local nPrePurchaseIndex                                                 = self.GetPrePurchaseIndex()

    Storage.MobaShop_tPrePurchase.tPlans[nKungfuMountID][nPrePurchaseIndex] = clone(tNewPrePurchase)
end

function LieXingXuJingData.GetCurrentPrePurchaseID(nEquipmentSub)
    local tPrePurchase           = self.GetPrePurchase()

    --- 预设装备的栏位顺序可以任意调整，且可能有空位，因此先通过预先写好的函数获取一个当前状况的稳定栏位顺序，再定位到对应的预设装备ID
    local tEquipmentSubOrderList = self.GetEquipListTypeOrderList(false, false, nil)
    local _, nIndex              = table.find_if(tEquipmentSubOrderList, function(nType)
        return nType == nEquipmentSub
    end)

    local nPrePurchaseID         = tPrePurchase["nEquipmentLocalID" .. tostring(nIndex)]

    return nPrePurchaseID
end

--- 获取玩家局内当前类别的预购装备，或者局外提前设置的预购装备
function LieXingXuJingData.GetInGamePlayerPrePurchaseIDOrPresetID(nEquipmentSub)
    -- 如果局内设置了该类别的装备，则优先使用该值
    if BattleFieldData.IsInMobaBattleFieldMap() and self.nPlayerPrePurchaseID then
        local tItemInfo = Table_GetMobaShopItemUIInfoByID(self.nPlayerPrePurchaseID)
        if tItemInfo and tItemInfo.nEquipmentSub == nEquipmentSub then
            return self.nPlayerPrePurchaseID
        end
    end

    -- 否则使用局外设置的
    return self.GetCurrentPrePurchaseID(nEquipmentSub)
end

function LieXingXuJingData.SetDefaultPrePurchase()
    local nKungfuMountID                                                    = self.GetKungFuMountID()
    local nPrePurchaseIndex                                                 = self.GetPrePurchaseIndex()

    Storage.MobaShop_tPrePurchase.tPlans[nKungfuMountID][nPrePurchaseIndex] = clone(TableGetMobaShopPrePurchase(nKungfuMountID)[nPrePurchaseIndex])
end

-- note: 复制自 scripts/Map/列星岛/include/CommonFunction.lua
--RemoteCallToClient(dwPlayerID, "ShowMobaBattleMsg", eMobaBattleMsgType, userdata)
--- MOBA战场战斗提示信息枚举类型定义
LieXingXuJingData.LUA_MOBA_BATTLE_MSG_TYPE = {
    --[[
        注意：下面的用于表示非玩家身份的index，通过目录ui\Scheme\Case\BattleField下的UI配置表
    MOBA_BattleNonPlayerInfo.tab
    来决定显示的图素和名字
    --]]

    BEGIN_BATTLE = 1, --- 双方阵营开始出兵；userdata： 无  @郭哥

    SELF_TOWER_UNDER_ATTACK = 2, --- 我方防御塔被攻击；userdata： nTowerIndex @PP

    --[[
        玩家摧毁防御塔；userdata： {bSelfTower, nTowerIndex, szPlayerName, nPlayerKungfuID}，
        分别表示是否为我方防御塔（true/false）、防御塔的index、摧毁敌方防御塔的玩家名字和心法ID（摧毁我方防御塔的玩家则不提供后两者）
    --]]
    PLAYER_DESTROY_TOWER = 3,

    --[[
        非玩家摧毁防御塔；userdata： {bSelfTower, nTowerIndex, nNonPlayerIndex}，
        bSelfTower表示是否为我方防御塔（true/false）；
        
        nNonPlayerIndex表示非玩家的index（含义见枚举类型开头的注释）
        （摧毁我方防御塔的玩家则不提供后两者）
    --]]
    NONPLAYER_DESTROY_TOWER = 4,

    --[[
        龙兽出现；userdata： nLongshouIndex，
        nLongshouIndex表示龙兽的index
    --]]
    LONGSHOU_REVIVED = 5, --@郭哥

    --[[
        玩家击杀龙兽；userdata： {bAllyKill, szPlayerName, nPlayerKungfuID, nLongshouIndex}，
        bAllyKill表示是被我方击杀还是被敌方击杀；
        szPlayerName表示摧毁龙兽的玩家名字；
        nPlayerKungfuID表示该玩家的心法ID；
        nLongshouIndex表示龙兽的index；
    --]]
    PLAYER_KILL_LONGSHOU = 6,

    --[[
        非玩家击杀龙兽；userdata： {bAllyKill, nNonPlayerIndex, nLongshouIndex}，
        bAllyKill表示是被我方击杀还是被敌方击杀；
        nNonPlayerIndex表示非玩家的index（含义见枚举类型开头的注释）；
        nLongshouIndex表示龙兽的index
    --]]
    NONPLAYER_KILL_LONGSHOU = 7,

    ACE = 8, --- 团灭；userdata： 1表示我方全灭，2表示敌方全灭

    --[[
        全场首杀；userdata： {bAllyKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, aAssistKungfuIDList}
        bAllyKill为true/false，表示是否是友军杀敌；
        szKillerName和szKilledName的区别是前者杀死了后者；
        nKillerKungfuID表示杀人者的心法ID；
        nKilledKungfuID表示被杀者的心法ID；
        aAssistKungfuIDList为助攻人员的门派心法ID列表，无则设为空表或不传
    --]]
    FIRST_KILL_PLAYER = 9,

    --[[
        各种单/多杀；userdata： {bAllyKill, nKillTimes, bMultiKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, bBreakOpponentKill, aAssistKungfuIDList}
        bAllyKill为true/false，表示是否是友军杀敌；
        nKillTimes为连杀/多杀次数，单杀时为1，连杀时为3~7，多杀时为2~5；
        bMultiKill为true/false，表示是多杀/连杀（若为单杀，则会忽略掉本元素）；
        szKillerName和szKilledName的区别是前者杀死了后者；
        nKillerKungfuID表示杀人者的心法ID；
        nKilledKungfuID表示被杀者的心法ID；
        bBreakOpponentKill为true表示打断了对方的杀戮（只有在后者的连杀数>=3时才成立）；
        aAssistKungfuIDList为助攻人员的门派心法ID列表，无则设为空表或不传
    --]]
    PLAYER_KILL_PLAYER = 10,

    --[[
        非玩家击杀玩家；userdata： {nNonPlayerIndex, bIsAllyPlayer, szKilledName, nKilledKungfuID}
        nNonPlayerIndex表示该非玩家的index（含义见枚举类型开头的注释）；
        bIsAllyPlayer为true/false，表示被杀的玩家是否是友军；
        szKilledName表示被杀的玩家名字；
        nKilledKungfuID表示被杀者的心法ID；
    --]]
    NONPLAYER_KILL_PLAYER = 11,
}
-- {bSelfTower, nTowerIndex, szPlayerName, nPlayerKungfuID}，
----RemoteCallToClient(player.dwID, "ShowMobaBattleMsg",3, {true, 4, player.szName, player.GetKungfuMountID()})

local SFX_TEAMWIPE                         = Table_GetSFXPath(10) -- 我方团灭
local SFX_ENEMY_TEAMWIPE                   = Table_GetSFXPath(11) -- 敌方团灭
local SFX_KILL_EFFECT_2                    = Table_GetSFXPath(12) -- 击杀通用特效02
local SFX_KILL_EFFECT_1                    = Table_GetSFXPath(13) -- 击杀通用特效01	
local SFX_QUADRA_KILL                      = Table_GetSFXPath(14) -- 我方四杀		
local SFX_PENTA_KILL                       = Table_GetSFXPath(15) -- 我方五杀		
local SFX_ENEMY_QUADRA_KILL                = Table_GetSFXPath(16) -- 敌方四杀
local SFX_ENEMY_PENTA_KILL                 = Table_GetSFXPath(17) -- 敌方五杀

local LUA_MOBA_BATTLE_MSG_TYPE             = LieXingXuJingData.LUA_MOBA_BATTLE_MSG_TYPE
local g2u                                  = UIHelper.GBKToUTF8

local function GeneralMsg(eMobaBattleMsgType, tCustomData)
    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.BEGIN_BATTLE then
        local szMsg       = "破阵兵勇开始出击！"
        local szBgImgPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png"
        Event.Dispatch(EventType.ShowMobaBattleMsgGeneralMsg, szMsg, szBgImgPath)
    else
        Log("ERROR! GeneralMsg的参数不合法：")
        UILog(eMobaBattleMsgType, tCustomData)
    end
end

local function GeneralMsgEx(eMobaBattleMsgType, tCustomData)
    --- 背景图
    local szBgImgPath
    --- 特效路径
    local szSfxPath
    --- 消息内容
    local szMessage

    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.ACE then
        local bSelf = tCustomData[1] == 1
        if bSelf then
            szBgImgPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobeAllDieY.png"
            szSfxPath   = SFX_TEAMWIPE
            szMessage   = "我方团灭"
        else
            szBgImgPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobeAllDieB.png"
            szSfxPath   = SFX_ENEMY_TEAMWIPE
            szMessage   = "敌方团灭"
        end
    else
        Log("ERROR! GeneralMsgEx的参数不合法：")
        UILog(eMobaBattleMsgType, tCustomData)
    end

    Event.Dispatch(EventType.ShowMobaBattleMsgGeneralMsgEx, szMessage, szBgImgPath, szSfxPath)
end

local function OneSidedMsg(eMobaBattleMsgType, tCustomData)
    --- 消息背景图
    local szMsgBgImgPath
    --- 消息内容
    local szMessage
    --- 头像框图片
    local szImgAvatarBgPath
    --- 头像图片
    local szImgAvatarPath
    --- 头像框右下角的小尾巴图片
    local szImgAvatarDecorPath

    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.SELF_TOWER_UNDER_ATTACK then
        local nTowerIndex = tCustomData[1]

        szMsgBgImgPath    = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaRedL.png"

        if nTowerIndex == 4 then
            szMessage = "我方 “朱雀” 圣像遭到攻击"
        elseif nTowerIndex == 5 then
            szMessage = "我方 “玄武” 圣像遭到攻击"
        else
            szMessage = "我方星辉塔遭到攻击"
        end

        szImgAvatarBgPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaRedK.png"

        if nTowerIndex == 4 then
            szImgAvatarPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba5_Big.png"
        elseif nTowerIndex == 5 then
            szImgAvatarPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba6_Big.png"
        else
            szImgAvatarPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba5_Big.png"
        end

        szImgAvatarDecorPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaRedK_Fire.png"
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.LONGSHOU_REVIVED then
        local nLongshouIndex = tCustomData[1]

        szMsgBgImgPath       = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaYellowL.png"

        if nLongshouIndex == 2 then
            szMessage = "煞星龙兽借星象之力重生"
        else
            szMessage = "凶星龙兽借星象之力重生"
        end

        szImgAvatarBgPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaYellowK.png"

        if nLongshouIndex == 2 then
            szImgAvatarPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba1_Big.png"
        else
            szImgAvatarPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_Moba2_Big.png"
        end

        szImgAvatarDecorPath = "UIAtlas2_Public_PublicHint_PublicSpecialHint_MobaYellowK_Fire.png"
    else
        Log("ERROR! OneSidedMsg的参数不合法：")
        UILog(eMobaBattleMsgType, tCustomData)
    end

    Event.Dispatch(EventType.ShowMobaBattleMsgOneSidedMsg, szMessage, szMsgBgImgPath, szImgAvatarPath, szImgAvatarBgPath, szImgAvatarDecorPath)
end

local function TwoSidedMsg(eMobaBattleMsgType, tCustomData)
    local tLeftInfo             = {} --- {bAlly, true, szPlayerName, nKungfuID} or {bAlly, false, nNonPlayerIndex}
    local tRightInfo            = {} --- {bAlly, true, szPlayerName, nKungfuID} or {bAlly, false, nNonPlayerIndex}
    local aAssistKillKungfuIDs  = {}

    --- 中间的红蓝背景图片
    local szCenterBgImgPath     = ""
    --- 上方的边框图片，比如三杀、四杀、五杀时分别使用不同夸张程度的边框
    --- note: 目前vk端击杀的背景框设计为只有一个，不同击杀次数都使用同一个样式的背景图，这个实际不用
    local szCenterTopImgPath    = ""
    --- 下方的边框图片，比如三杀、四杀、五杀时分别使用不同夸张程度的边框
    --- note: 目前vk端击杀的背景框设计为只有一个，不同击杀次数都使用同一个样式的背景图，这个实际不用
    local szCenterBottomImgPath = ""
    --- 中间文本内容
    local szMessage             = ""
    --- 特效 1
    local szSfxPath             = ""
    --- 特效 2
    local szSfx2Path            = ""

    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER
            or eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_DESTROY_TOWER then
        local bSelfTower, nTowerIndex = tCustomData[1], tCustomData[2]
        if bSelfTower then
            if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER then
                local szPlayerName, nPlayerKungfuID = tCustomData[3], tCustomData[4]
                szCenterBgImgPath                   = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintRed.png"
                szCenterTopImgPath                  = ""
                szCenterBottomImgPath               = ""

                tLeftInfo                           = { false, true, szPlayerName, nPlayerKungfuID }
            else
                local nNonPlayerIndex = tCustomData[3]
                szCenterBgImgPath     = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintRed.png"
                szCenterTopImgPath    = ""
                szCenterBottomImgPath = ""

                tLeftInfo             = { false, false, nNonPlayerIndex }
            end

            szMessage  = "摧毁"
            tRightInfo = { true, false, nTowerIndex }
        else
            if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER then
                local szPlayerName, nPlayerKungfuID = tCustomData[3], tCustomData[4]
                szCenterBgImgPath                   = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png"
                szCenterTopImgPath                  = ""
                szCenterBottomImgPath               = ""

                tLeftInfo                           = { true, true, szPlayerName, nPlayerKungfuID }
            else
                local nNonPlayerIndex = tCustomData[3]
                szCenterBgImgPath     = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png"
                szCenterTopImgPath    = ""
                szCenterBottomImgPath = ""

                tLeftInfo             = { true, false, nNonPlayerIndex }
            end

            szMessage  = "摧毁"
            tRightInfo = { false, false, nTowerIndex }
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_LONGSHOU then
        local bAllyKill, szPlayerName, nPlayerKungfuID, nLongshouIndex = tCustomData[1], tCustomData[2], tCustomData[3], tCustomData[4]

        szCenterBgImgPath                                              = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintRed.png"
        szCenterTopImgPath                                             = ""
        szCenterBottomImgPath                                          = ""
        szMessage                                                      = "重伤"

        tLeftInfo                                                      = { bAllyKill, true, szPlayerName, nPlayerKungfuID }
        tRightInfo                                                     = { nil, false, nLongshouIndex }
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_LONGSHOU then
        local bAllyKill, nNonPlayerIndex, nLongshouIndex = tCustomData[1], tCustomData[2], tCustomData[3]

        szCenterBgImgPath                                = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png"
        szCenterTopImgPath                               = ""
        szCenterBottomImgPath                            = ""
        szMessage                                        = "摧毁"

        tLeftInfo                                        = { bAllyKill, false, nNonPlayerIndex }
        tRightInfo                                       = { not bAllyKill, false, nLongshouIndex }
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.FIRST_KILL_PLAYER then
        local bAllyKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID = tCustomData[1], tCustomData[2],
        tCustomData[3], tCustomData[4], tCustomData[5]

        szCenterBgImgPath                                                             = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
        szCenterTopImgPath                                                            = ""
        szCenterBottomImgPath                                                         = ""
        szMessage                                                                     = "第一滴血！"

        tLeftInfo                                                                     = { bAllyKill, true, szKillerName, nKillerKungfuID }
        tRightInfo                                                                    = { not bAllyKill, true, szKilledName, nKilledKungfuID }
        aAssistKillKungfuIDs                                                          = tCustomData[6] or {}

        if bAllyKill then
            szSfxPath = SFX_KILL_EFFECT_2
        else
            szSfxPath = SFX_KILL_EFFECT_1
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_PLAYER then
        local bAllyKill, nKillTimes, bMultiKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, bBreakOpponentKill = tCustomData[1], tCustomData[2], tCustomData[3], tCustomData[4], tCustomData[5], tCustomData[6], tCustomData[7], tCustomData[8]
        if bBreakOpponentKill then
            szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
            szCenterTopImgPath    = ""
            szCenterBottomImgPath = ""
            szMessage             = "终结杀戮"
        else
            if nKillTimes <= 1 then
                szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                szCenterTopImgPath    = ""
                szCenterBottomImgPath = ""
                szMessage             = "杀敌"
            else
                if bMultiKill then
                    if nKillTimes == 2 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = -1
                        --nCenterBottomImgFrame = bAllyKill and 21 or 20
                        szMessage             = "双杀"
                    elseif nKillTimes == 3 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 22 or 14
                        --nCenterBottomImgFrame = bAllyKill and 23 or 15
                        szMessage             = "三杀"
                    elseif nKillTimes == 4 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 24 or 16
                        --nCenterBottomImgFrame = bAllyKill and 25 or 17
                        szMessage             = "四杀·众星显现"

                        if bAllyKill then
                            szSfx2Path = SFX_QUADRA_KILL
                        else
                            szSfx2Path = SFX_ENEMY_QUADRA_KILL
                        end
                    elseif nKillTimes == 5 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 26 or 18
                        --nCenterBottomImgFrame = bAllyKill and 27 or 19
                        szMessage             = "五杀·诸星斗阵"

                        if bAllyKill then
                            szSfx2Path = SFX_PENTA_KILL
                        else
                            szSfx2Path = SFX_ENEMY_PENTA_KILL
                        end
                    end
                else
                    if nKillTimes == 3 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        szMessage             = "大开杀戒"
                    elseif nKillTimes == 4 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = -1
                        --nCenterBottomImgFrame = bAllyKill and 21 or 20
                        szMessage             = "屠戮四方"
                    elseif nKillTimes == 5 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 22 or 14
                        --nCenterBottomImgFrame = bAllyKill and 23 or 15
                        szMessage             = "所向披靡"
                    elseif nKillTimes == 6 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 24 or 16
                        --nCenterBottomImgFrame = bAllyKill and 25 or 17
                        szMessage             = "神佛难挡"

                        if bAllyKill then
                            szSfx2Path = SFX_QUADRA_KILL
                        else
                            szSfx2Path = SFX_ENEMY_QUADRA_KILL
                        end
                    elseif nKillTimes == 7 then
                        szCenterBgImgPath     = bAllyKill and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
                        szCenterTopImgPath    = ""
                        szCenterBottomImgPath = ""
                        --nCenterTopImgFrame    = bAllyKill and 26 or 18
                        --nCenterBottomImgFrame = bAllyKill and 27 or 19
                        szMessage             = "杀入轮回"

                        if bAllyKill then
                            szSfx2Path = SFX_PENTA_KILL
                        else
                            szSfx2Path = SFX_ENEMY_PENTA_KILL
                        end
                    end
                end
            end
        end

        tLeftInfo            = { bAllyKill, true, szKillerName, nKillerKungfuID }
        tRightInfo           = { not bAllyKill, true, szKilledName, nKilledKungfuID }
        aAssistKillKungfuIDs = tCustomData[9] or {}

        if bAllyKill then
            szSfxPath = SFX_KILL_EFFECT_2
        else
            szSfxPath = SFX_KILL_EFFECT_1
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_PLAYER then
        local nNonPlayerIndex, bIsAllyPlayer, szKilledName, nKilledKungfuID = tCustomData[1], tCustomData[2],
        tCustomData[3], tCustomData[4]

        szCenterBgImgPath                                                   = (not bIsAllyPlayer) and "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgBlue.png" or "UIAtlas2_Public_PublicHint_PublicSpecialHint_BgRed.png"
        szCenterTopImgPath                                                  = ""
        szCenterBottomImgPath                                               = ""
        szMessage                                                           = "杀敌"

        tLeftInfo                                                           = { nil, false, nNonPlayerIndex }
        tRightInfo                                                          = { bIsAllyPlayer, true, szKilledName, nKilledKungfuID }
    else
        Log("ERROR！无法处理显示非法的MOBA战斗提示信息类型： " .. tostring(eMobaBattleMsgType))
    end

    Event.Dispatch(EventType.ShowMobaBattleMsgTwoSidedMsg,
                   tLeftInfo, tRightInfo, aAssistKillKungfuIDs,
                   szCenterBgImgPath, szCenterTopImgPath, szCenterBottomImgPath,
                   szMessage,
                   szSfxPath, szSfx2Path
    )
end

function LieXingXuJingData.DecideShowFunction(eMobaBattleMsgType, userdata)
    local fnShow
    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.BEGIN_BATTLE then
        fnShow = GeneralMsg
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.SELF_TOWER_UNDER_ATTACK then
        fnShow = OneSidedMsg
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.LONGSHOU_REVIVED then
        fnShow = OneSidedMsg
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.ACE then
        fnShow = GeneralMsgEx
    else
        fnShow = TwoSidedMsg
    end

    return fnShow
end

function LieXingXuJingData.DecideChatMsgContent(eMobaBattleMsgType, userdata)
    local szMsg = ""
    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.BEGIN_BATTLE then
        szMsg = szMsg .. g_tStrings.STR_MOBA_BATTLE_MSG_BEGIN_BATTLE
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.SELF_TOWER_UNDER_ATTACK then
        local nTowerIndex = userdata[1]
        szMsg             = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_SELF_TOWER_UNDER_ATTACK, g2u(Table_GetMobaBattleNonPlayerInfo(nTowerIndex).szName))
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER
            or eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_DESTROY_TOWER then
        local bSelfTower, nTowerIndex = userdata[1], userdata[2]
        if bSelfTower then
            szMsg = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_SELF_TOWER_DESTROYED, g2u(Table_GetMobaBattleNonPlayerInfo(nTowerIndex).szName))
        else
            if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER then
                local szPlayerName, nPlayerKungfuID = userdata[3], userdata[4]
                szMsg                               = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_DESTROY_ENEMY_TOWER, g2u(szPlayerName), g2u(Table_GetMobaBattleNonPlayerInfo(nTowerIndex).szName))
            else
                local nNonPlayerIndex = userdata[3]
                szMsg                 = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_DESTROY_ENEMY_TOWER, g2u(Table_GetMobaBattleNonPlayerInfo(nNonPlayerIndex).szName),
                                                              g2u(Table_GetMobaBattleNonPlayerInfo(nTowerIndex).szName))
            end
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.LONGSHOU_REVIVED then
        local nLongshouIndex = userdata[1]
        szMsg                = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_LONGSHOU_REVIVED, g2u(Table_GetMobaBattleNonPlayerInfo(nLongshouIndex).szName))
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_LONGSHOU then
        local bAllyKill, szPlayerName, nPlayerKungfuID, nLongshouIndex = userdata[1], userdata[2], userdata[3], userdata[4]
        szMsg                                                          = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_SOMEONE_KILL_LONGSHOU, g2u(szPlayerName), g2u(Table_GetMobaBattleNonPlayerInfo(nLongshouIndex).szName))
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_LONGSHOU then
        local bAllyKill, nNonPlayerIndex, nLongshouIndex = userdata[1], userdata[2], userdata[3]
        szMsg                                            = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_SOMEONE_KILL_LONGSHOU, g2u(Table_GetMobaBattleNonPlayerInfo(nNonPlayerIndex).szName),
                                                                                 g2u(Table_GetMobaBattleNonPlayerInfo(nLongshouIndex).szName))
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.ACE then
        local bSelf = userdata[1] == 1
        szMsg       = szMsg .. g_tStrings.tStrMobaBattleMsgWipedOut[bSelf and 1 or 2]
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.FIRST_KILL_PLAYER then
        local bAllyKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, aAssistKungfuIDList = userdata[1], userdata[2],
        userdata[3], userdata[4], userdata[5], userdata[6]
        szMsg                                                                                              = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_FIRST_KILL, g2u(szKillerName), g2u(szKilledName))
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_PLAYER then
        local bAllyKill, nKillTimes, bMultiKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, bBreakOpponentKill, aAssistKungfuIDList = userdata[1], userdata[2], userdata[3], userdata[4], userdata[5], userdata[6], userdata[7], userdata[8], userdata[9]
        if bBreakOpponentKill then
            szMsg = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_BREAK_KILL, g2u(szKillerName), g2u(szKilledName))
        else
            if nKillTimes <= 1 then
                szMsg = szMsg .. FormatString(g_tStrings.tStrMobaBattleMsgSingleKill[bAllyKill and 1 or 2], g2u(szKillerName), g2u(szKilledName))
            else
                local szMsgToAppend
                if bMultiKill then
                    szMsgToAppend = g_tStrings.tStrMobaBattleMsgMultiKill[nKillTimes]
                    if not szMsgToAppend then
                        Log("ERROR！多杀的计数(" .. tostring(nKillTimes) .. ")不合法！")
                        return szMsg
                    end
                    szMsg = szMsg .. FormatString(szMsgToAppend, g2u(szKillerName), g2u(szKilledName))
                else
                    szMsgToAppend = g_tStrings.tStrMobaBattleMsgContinuousKill[nKillTimes]
                    if not szMsgToAppend then
                        Log("ERROR！连杀的计数(" .. tostring(nKillTimes) .. ")不合法！")
                        return ""
                    end
                    szMsg = szMsg .. FormatString(szMsgToAppend, g2u(szKillerName), g2u(szKilledName))
                end
            end
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_PLAYER then
        local nNonPlayerIndex, bIsAllyPlayer, szKilledName, nKilledKungfuID = userdata[1], userdata[2],
        userdata[3], userdata[4]
        szMsg                                                               = szMsg .. FormatString(g_tStrings.STR_MOBA_BATTLE_MSG_NONPLAYER_KILL_PLAYER, g2u(Table_GetMobaBattleNonPlayerInfo(nNonPlayerIndex).szName), g2u(szKilledName))
    else
        Log("ERROR！无法处理显示非法的MOBA战斗提示信息类型： " .. tostring(eMobaBattleMsgType))
    end

    return szMsg
end

function LieXingXuJingData.GetSoundID(eMobaBattleMsgType, userdata)
    local szID
    if eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.BEGIN_BATTLE then
        szID = "BeginBattle"
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.SELF_TOWER_UNDER_ATTACK then
        local nTowerIndex = userdata[1]
        szID = "SelfTowerUnderAttack" .. nTowerIndex
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_DESTROY_TOWER
            or eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_DESTROY_TOWER then
        local bSelfTower, nTowerIndex = userdata[1], userdata[2]
        if bSelfTower then
            szID = "SelfTowerDestroyed" .. nTowerIndex
        else
            szID = "DestroyedEnemyTower" .. nTowerIndex
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.LONGSHOU_REVIVED then
        local nLongshouIndex = userdata[1]
        szID = ""
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_LONGSHOU then
        local bAllyKill, szPlayerName, nPlayerKungfuID, nLongshouIndex = userdata[1], userdata[2], userdata[3], userdata[4]
        szID = ""
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_LONGSHOU then
        local bAllyKill, nNonPlayerIndex, nLongshouIndex = userdata[1], userdata[2], userdata[3]
        szID = ""
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.ACE then
        local bSelf = userdata[1] == 1
        if bSelf then
            szID = "SelfWipedOut"
        else
            szID = "EnemyWipedOut"
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.FIRST_KILL_PLAYER then
        szID = "FirstKill"
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.PLAYER_KILL_PLAYER then
        local bAllyKill, nKillTimes, bMultiKill, szKillerName, nKillerKungfuID, szKilledName, nKilledKungfuID, bBreakOpponentKill, aAssistKungfuIDList =
        userdata[1], userdata[2], userdata[3], userdata[4], userdata[5], userdata[6], userdata[7], userdata[8], userdata[9]
        if bBreakOpponentKill then
            szID = "BreakKill"
        else
            if nKillTimes <= 1 then
                if bAllyKill then
                    szID = "AllySingleKillPlayer"
                else
                    szID = "EnemySingleKillPlayer"
                end
            else
                if bMultiKill then
                    local tNumberToWord =
                    {
                        [2] = "Double",
                        [3] = "Triple",
                        [4] = "Quadruple",
                        [5] = "Quintuple",
                    }

                    if not tNumberToWord[nKillTimes] then
                        Log("ERROR！多杀的计数(" .. tostring(nKillTimes) .. ")不合法！")
                        return ""
                    end
                    szID = tNumberToWord[nKillTimes] .. "Kill"
                else
                    local tNumberToWord =
                    {
                        [3] = "Three",
                        [4] = "Four",
                        [5] = "Five",
                        [6] = "Six",
                        [7] = "Seven",
                    }

                    if not tNumberToWord[nKillTimes] then
                        Log("ERROR！连杀的计数(" .. tostring(nKillTimes) .. ")不合法！")
                        return ""
                    end
                    szID = tNumberToWord[nKillTimes] .. "Liansha"
                end
            end
        end
    elseif eMobaBattleMsgType == LUA_MOBA_BATTLE_MSG_TYPE.NONPLAYER_KILL_PLAYER then
        local nNonPlayerIndex, bIsAllyPlayer, szKilledName, nKilledKungfuID = userdata[1], userdata[2],
        userdata[3], userdata[4]
        szID = ""
    else
        Log("ERROR！无法处理显示非法的MOBA战斗提示信息类型： " .. tostring(eMobaBattleMsgType))
    end

    return szID
end

function LieXingXuJingData.ShowMobaBattleMsg(eMobaBattleMsgType, userdata)
    local fnShow = self.DecideShowFunction(eMobaBattleMsgType, userdata)
    fnShow(eMobaBattleMsgType, userdata)
    
    local szSoundID = self.GetSoundID(eMobaBattleMsgType, userdata)
    if szSoundID ~= "" then
        SoundMgr.PlaySound(SOUND.UI_SOUND, Table_GetMobaBattleVoiceFilePath(szSoundID))
    else
        Log("WARNING! MOBA战场战斗信息枚举值(" .. tostring(eMobaBattleMsgType) .. ")找不到对应的语音文件！")
    end

    local szMsg = self.DecideChatMsgContent(eMobaBattleMsgType, userdata)
    if szMsg ~= "" then
        OutputMessage("MSG_SYS", szMsg .. "\n")
    end
end

--- ------------------------- 局内装备 -------------------------

---@class MobaPlayerEquippedItemInfo moba玩家已穿戴装备信息
---@field nEquipmentSub number 部位枚举
---@field nItemID number 道具Index
---@field nItemType number 道具类别
---@field nUiId number 图标id
---@field nGenre number 类别
---@field nQuality number 品质
---
---@field nID number 装备模板ID
---@field nSellingPrice number 出售价格

function LieXingXuJingData.UpdatePlayerEquipment()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    ---@type table<number, MobaPlayerEquippedItemInfo>
    self.tPlayerEquipment = {}
    for _, nType in pairs(self.tEquipmentNames) do
        if self.tPlayerEquipment[nType] == nil then
            self.tPlayerEquipment[nType] = {}
        end
        ---@type KGItem
        local pItemInfo = ItemData.GetPlayerItem(pPlayer, INVENTORY_INDEX.EQUIP, nType)
        if pItemInfo then
            self.tPlayerEquipment[nType].nEquipmentSub = nType
            self.tPlayerEquipment[nType].nItemID       = pItemInfo.dwIndex
            self.tPlayerEquipment[nType].nItemType     = pItemInfo.dwTabType
            self.tPlayerEquipment[nType].nUiId         = pItemInfo.nUiId
            self.tPlayerEquipment[nType].nGenre        = pItemInfo.nGenre
            self.tPlayerEquipment[nType].nQuality      = pItemInfo.nQuality

            local tItemInfo                            = Table_GetMobaShopItemInfo(pItemInfo.dwTabType, pItemInfo.dwIndex)
            if tItemInfo then
                self.tPlayerEquipment[nType].nID           = tItemInfo.nID
                self.tPlayerEquipment[nType].nSellingPrice = tItemInfo.nSellingPrice
            end
        end
    end
end
