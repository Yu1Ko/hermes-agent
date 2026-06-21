FameData = FameData or {}

local function GetLockStatus(tQuestIDs, nExtPointIndex, nExtPointBitIndex, nExtPointLength)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return true
    end
    return hPlayer.GetExtPointByBits(nExtPointIndex, nExtPointBitIndex, nExtPointLength) == 0
end

---@class FameInfo 侠客信息
-------------- 配置表字段 --------------
---@field dwID number ID
---@field szName string 名称
---@field dwAchievementID number 成就ID
---@field nExtPointIndex number 扩展点index
---@field nExtPointBitIndex number 扩展点bit index
---@field nExtPointLength number 扩展点长度
---@field szMapQuest string 地图与任务信息 map;quest|map;quest...
---@field szDec string 描述
---@field szLevelTips string 等级信息
---@field szLogoPath string logo路径
---@field nLogoFrame number logo帧
---@field szFameBgPath string 背景图路径
---@field nFameBgFrame number 背景图帧
---@field nFameSelectedFrame number 选中帧
---@field szLockBgPath string 锁定背景图
---@field nLockBgPath number 锁定背景图帧
---@field szBgInfo string 背景图信息
---@field szMapTipsInfo string 地图提示信息
---@field szRewardNPCInfo string 奖励NPC信息
---@field szRewardItemInfo string 奖励道具信息
---@field szVKImagePath string vk的背景图
---@field nVKRuleId number vk的规则ID
-------------- 后期解析出的字段 --------------
---@field tRewardNPCInfo table 奖励NPC信息
---@field tRewardInfo table 奖励信息
---@field tMapIDs number[] 地图列表
---@field tQuestIDs number[] 任务列表
---@field tMainChapter number[] 剑侠录章节
---@field tBgInfo table 背景图信息
---@field tMapTipsInfo table 地图提示信息
---@field bLocked boolean 是否锁定
---@field nNowLevel number 现在等级
---@field nMaxLevel number 最大等级
---@field nProgressUp number 当前等级进度（分子）
---@field nProgressDown number 当前等级最大进度（分母）

---@return FameInfo[]
function FameData.GetFameInfoList()
    local tInfoList = Table_GetFameInfo()
    local hPlayer   = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tResult
    for k, v in ipairs(tInfoList) do
        tResult          = SplitString(v.szRewardShopInfo, "|")
        v.tRewardNPCInfo = tResult
        tResult          = SplitString(v.szRewardItemInfo, "|")
        v.tRewardInfo    = tResult
        tResult          = SplitString(v.szMapChapter, "|")
        v.tMapIDs        = {}
        v.tQuestIDs      = {}
        v.tMainChapter   = {}
        for nIndex, tInfo in ipairs(tResult) do
            local tTemp            = SplitString(tInfo, ";")
            v.tMapIDs[nIndex]      = tTemp[1]
            v.tQuestIDs[nIndex]    = tonumber(tTemp[2])
            v.tMainChapter[nIndex] = tonumber(tTemp[3])
        end
        tResult        = SplitString(v.szBgInfo, "|")
        v.tBgInfo      = tResult
        tResult        = SplitString(v.szMapTipsInfo, "|")
        v.tMapTipsInfo = tResult
        if #v.tMapIDs ~= #v.tBgInfo or #v.tMapTipsInfo ~= #v.tBgInfo then
            UILog("检查配表")
        end
        v.bLocked                                                = GetLockStatus(v.tQuestIDs, v.nExtPointIndex, v.nExtPointBitIndex, v.nExtPointLength)
        v.nNowLevel, v.nMaxLevel, v.nProgressUp, v.nProgressDown = 0, 0, 0, 0
        if not v.bLocked then
            v.nNowLevel, v.nMaxLevel, v.nProgressUp, v.nProgressDown = GDAPI_GetFameLevelInfo(hPlayer, v.dwID)
        end
    end

    local function fnADegree(a, b)
        return a.dwID > b.dwID
    end

    table.sort(tInfoList, fnADegree)

    return tInfoList
end

function FameData.GetFameInfo(dwID)
    local tInfoList = FameData.GetFameInfoList()
    for _, tInfo in ipairs(tInfoList) do
        if tInfo.dwID == dwID then
            return tInfo
        end
    end
end