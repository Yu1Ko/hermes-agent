-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HuaELouData
-- Date: 2022-12-30 15:41:29
-- Desc: ?
-- ---------------------------------------------------------------------------------


HuaELouData = HuaELouData or {}
local self = HuaELouData
local UNTIL_SEASON_END         = true
local EXP_LEVEL                = 1000
local REMOTE_BATTLEPASS        = 1072
local MIN_QUEST_LINE           = 3
local QUEST_BORDER_FRAME_ATC   = 2
local QUEST_BORDER_FRAME_EMPTY = 18
local REWARD_LEVEL_REGION      = 10

local GONGZHAN_BUFF = 3219
local EX_PLAYER_RETURN = 403
local SIGN_IN_ID = 16
local EXTRAL_LEVEL = 10
local szTongBaoRichImg = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='36' height='36'/>"

HuaELouData.WEEK_CHIPS_LIMIT         = CommonDef.Activity.WEEK_CHIPS_LIMIT
HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE = CommonDef.Activity.WEEK_CHIPS_LIMIT_VISIBLE
HuaELouData.WEEK_CHIPS_ITEM_INDEX = CommonDef.Activity.WEEK_CHIPS_ITEM_INDEX
HuaELouData.ACCOUNT_EXP_POINT        = CommonDef.Activity.BP_ACCOUNT_EXP_EXPOINT
HuaELouData.ACCOUNT_EXP_PER_LEVEL    = 1000

-------------------------------- 消息定义 --------------------------------
HuaELouData.Event = {}
HuaELouData.Event.XXX = "HuaELouData.Msg.XXX"

HuaELouData.QuestType = {
    "EveryDay",
    "EveryWeek",
    "CyclicTask",
}

HuaELouData.QuestTypeName = {
    ["EveryDay"] = "日常",
    ["EveryWeek"] = "周常",
    ["CyclicTask"] = "循环",
}

HuaELouData.QuestFliterClass = {
    All = 1,    -- 全部
    ACT = 2,    -- 节庆
    PVX = 3,    -- 休闲
    PVP = 4,    -- 对抗
    PVE = 5,    -- 秘境
}

HuaELouData.tActiveTime = {}

HuaELouData.RewardGroupSize = 4 -- 多少档奖品被编为一组

--- 目前正式方案是通过实物订单来实现人民币直购
--- 最近几次测试可能会继续使用通宝来购买，这里先禁用直购
HuaELouData.PASS_USE_RMB        = true

-- 对于直购版本，移动版这边需要配置的东西如下
-- 1. 在 Logic/HuaELou/HuaELouData.lua 配置 tRMBBattlePassItem，也就是战令对应的实物商品的商品ID、道具Index、预购资格ID信息
--      前两者分别对应 settings/RewardsShop.tab 中的 ID 和 ItemTabIndex 字段，需要确保该道具是实物道具（IsReal字段为1）
-- 2. 在 Logic/PayData.lua 的 tBattlePassProductBuyItemWithRMB 表中配置战令的西瓜商品信息，同时确保里面的 dwItemType 和 dwItemIndex 配置为实物商品的道具type和index
--      分别对应 settings/RewardsShop.tab 中的 ItemTabType 和 ItemTabIndex 字段

HuaELouData.tBattlePassType     = {
    ---普通档
    Normal = 1,
    ---进阶档
    Advanced = 2,
    ---补差价档
    Middle = 3,
}

---@class BattlePassItem 战令配置
---@field dwIndex number 道具ID
---@field dwPreOrderID number 预购资格ID
---@field dwGoodsID number GoodsID

---@type BattlePassItem[] 通宝的每档战令配置
HuaELouData.tCoinBattlePassItem = {
    [HuaELouData.tBattlePassType.Normal] = { dwIndex = 85931, dwPreOrderID = 218, dwGoodsID = 6285 }, -- 58元档
    [HuaELouData.tBattlePassType.Middle] = { dwIndex = 85932, dwPreOrderID = 219, dwGoodsID = 6286 }, -- 100元档
    [HuaELouData.tBattlePassType.Advanced] = { dwIndex = 85933, dwPreOrderID = 220, dwGoodsID = 6287 }, -- 158元档
}

---@type BattlePassItem[] 直购的每档战令配置
HuaELouData.tRMBBattlePassItem  = {
    [HuaELouData.tBattlePassType.Normal] = { dwIndex = 85954, dwPreOrderID = 218, dwGoodsID = 6288 }, -- 58元档
    [HuaELouData.tBattlePassType.Middle] = { dwIndex = 85955, dwPreOrderID = 219, dwGoodsID = 6289 }, -- 100元档
    [HuaELouData.tBattlePassType.Advanced] = { dwIndex = 85956, dwPreOrderID = 220, dwGoodsID = 6290 }, -- 158元档
}

--- 通宝购买界面左侧的预览角色模型的替换外观配置，会将设置的这些部位的值覆盖到玩家身上
--- key为部位枚举 EQUIPMENT_REPRESENT，value为外观ID、发型ID、颜色ID等，
HuaELouData.tBattlePassPreviewRewardPlayerModelRepresentID = {
    [1] = 1936,--黑发发型
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 1643,--上衣（实际上整个礼盒的表现id）
    [6] = 0,
    [7] = 0,
    [16] = 0,
    [17] = 0,
    [18] = 0,
    [19] = 0,
    [20] = 0,
    [21] = 0,
    [22] = 0,
    [23] = 0,
    [24] = 0,
    [25] = 0,
    [31] = 0,
    [32] = 0,
    [33] = 0,
    [34] = 0,
    [35] = 0,
    [36] = 0,
    [37] = 0,
    [40] = 0,
    [41] = 0,
    [42] = 0,
    [43] = 0,
    [44] = 0,
    [45] = 0,
}

HuaELouData.tOperationInitFunc = {
    OperationWelcomeSignInData.InitOperation,
    OperationFriendRecruitData.InitOperation,
    OperationShopData.InitOperation,
    OperationSafeData.InitOperation,
    OperationGuideNewData.InitOperation,
    OperationMonthlyPurchaseData.InitOperation,
    OperationGuideRecallData.InitOperation,
}

HuaELouData.tOperationProcessor = {
}

function HuaELouData.RegisterProcessor(dwOperatActID, processor)
    HuaELouData.tOperationProcessor[dwOperatActID] = processor
end

function HuaELouData.GetBattlePassItemTable()
    if HuaELouData.PASS_USE_RMB then
        return HuaELouData.tRMBBattlePassItem
    else
        return HuaELouData.tCoinBattlePassItem
    end
end

function HuaELouData.Init()
	HuaELouData.tAllQuest = Table_GetActivityBattlePassQuest()
    HuaELouData.tRewardList, HuaELouData.tValuableReward = Table_GetActivityBattlePassReward()
    HuaELouData.nSelectValueIndex = 1
    HuaELouData.tCheckBoxClass =
    {
        [0] = { bCheck = true, szName = "CheckBox_SelectAll" },
        [1] = { bCheck = true, szName = "CheckBox_ACT", szClassName = "节庆"},
        [2] = { bCheck = true, szName = "CheckBox_PVX", szClassName = "休闲"},
        [3] = { bCheck = true, szName = "CheckBox_PVP", szClassName = "对抗"},
        [4] = { bCheck = true, szName = "CheckBox_PVE", szClassName = "秘境"},
    }
    HuaELouData.nLockRewardCanGet = 0

    if not HuaELouData.nExpNow then
        HuaELouData.nExpNow     = 0
    end
    if not HuaELouData.nWeekChipsNow then
        HuaELouData.nWeekChipsNow = 0
    end
    if not HuaELouData.nLevelNow then
        HuaELouData.nLevelNow = 0
    end

    HuaELouData.tReward = {}
    HuaELouData.tMonthlyRecharge = {}
    HuaELouData.tCustom = {}
    HuaELouData.tCheckActive = {}
    HuaELouData.tIgnoreShowActive = {}

    Event.Reg(self, EventType.On_Recharge_CheckRFirstCharge_CallBack, function(tbRewardInfo, bCanDo, dwID)
        if dwID == OPERACT_ID.REAL_FIRST_CHARGE then
            HuaELouData.tFirstChargeRewardInfo = tbRewardInfo
            HuaELouData.bFirstChargeRewardCanDo = bCanDo
            HuaELouData.tCheckActive[OPERACT_ID.REAL_FIRST_CHARGE] = bCanDo
        end
    end)

    Event.Reg(self, EventType.On_Recharge_GetRFirstChargeRwd_CallBack, function(tbRewardInfo, dwID)
        if dwID == OPERACT_ID.REAL_FIRST_CHARGE then
            HuaELouData.tFirstChargeRewardInfo = tbRewardInfo
        end
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
            HuaELouData.tReward = {}
            HuaELouData.tCustom = {}
            HuaELouData.tCheckActive = {}
            HuaELouData.tFirstChargeRewardInfo = nil
            HuaELouData.GetAllCheckActive()
            HuaELouData.Apply()
        end, true)
    end)

    Event.Reg(self, "LOADING_END", function()
        if HuaELouData.dwGeneralInvitationID and g_pClientPlayer.nLevel >= 108 then
            UIGlobalFunction["GeneralInvitation.Open"](HuaELouData.dwGeneralInvitationID)
            HuaELouData.dwGeneralInvitationID = nil
        end
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function()
        if HuaELouData.dwGeneralInvitationID and g_pClientPlayer.nLevel >= 108 then
            UIGlobalFunction["GeneralInvitation.Open"](HuaELouData.dwGeneralInvitationID)
            HuaELouData.dwGeneralInvitationID = nil
        end
    end)

    for _, initFunc in ipairs(HuaELouData.tOperationInitFunc) do
        initFunc()
    end
end

function HuaELouData.UnInit()

end

function HuaELouData.OnLogin()

end

function HuaELouData.OnFirstLoadEnd()

end

-------------------------------------------  江湖行记相关  -------------------------------------------------
function HuaELouData.UpdateAccountExp()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local nTotalExp = hPlayer.GetExtPoint(HuaELouData.ACCOUNT_EXP_POINT) or 0
	HuaELouData.nAccountLevel = math.floor(nTotalExp / HuaELouData.ACCOUNT_EXP_PER_LEVEL)
	HuaELouData.nAccountExp   = nTotalExp % HuaELouData.ACCOUNT_EXP_PER_LEVEL
end

function HuaELouData.UpdateExp()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    if not pPlayer.HaveRemoteData(REMOTE_BATTLEPASS) then
        return
    end

    HuaELouData.nExpNow           = pPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 0, 2)
    HuaELouData.nLockExtralCanGet = pPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 6, 1)
    HuaELouData.nWeekChipsNow     = pPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 10, 2)
    HuaELouData.nLockRewardCanGet = pPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 8, 1)
    HuaELouData.nLevelNow         = pPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 9, 1)
end

function HuaELouData.GetQuestList()
    local tClass = HuaELouData.tCheckBoxClass
    local tFiltedQuest = {}
    local nMaxCount = MIN_QUEST_LINE
    if HuaELouData.tAllQuest then
        for szModuleName, tQuests in pairs(HuaELouData.tAllQuest) do
            tFiltedQuest[szModuleName] = {}

            if tClass[0].bCheck then
                tFiltedQuest[szModuleName] = clone(tQuests)
            else
                for _, tInfo in pairs(tQuests) do
                    local nClass = tInfo.nClass
                    if tClass[nClass].bCheck then
                        table.insert(tFiltedQuest[szModuleName], tInfo)
                    end
                end

                table.sort(tFiltedQuest[szModuleName], function(a, b)
                    return a.dwID < b.dwID
                end)
            end

            local nColumnCount = #tFiltedQuest[szModuleName]
            if nMaxCount < nColumnCount then
                nMaxCount = nColumnCount
            end
        end
    end
    return tFiltedQuest, nMaxCount
end

--申请一下江湖行记的数据
function HuaELouData.Apply()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    --pPlayer.ApplySetCollection()
    pPlayer.ApplyRemoteData(REMOTE_BATTLEPASS)
end

--- 普通档是否已购买
function HuaELouData.IsGrandRewardUnlock()
    if HuaELouData.nLockRewardCanGet == 1 then
        return true
    else
        return false
    end
end

--- 进阶档是否已购买
function HuaELouData.IsExtralUnlock()
    if HuaELouData.nLockExtralCanGet == 1 then
        return true
    else
        return false
    end
end

function HuaELouData.GetLevel()
	return HuaELouData.nLevelNow
end

function HuaELouData.GetMaxLevel()
	return #HuaELouData.tRewardList
end

function HuaELouData.GetNearLevel()
    local nLevelNow = HuaELouData.GetLevel()
    local nLevelNear = (math.floor(nLevelNow / REWARD_LEVEL_REGION) + 1) * REWARD_LEVEL_REGION
    local nLevelMax = HuaELouData.GetMaxLevel()
    if nLevelNear > nLevelMax then
        nLevelNear = nLevelMax
    end
    return nLevelNear
end

function HuaELouData.GetTargetNearLevel(nLevelNow)
    local nLevelNear = (math.floor(nLevelNow / REWARD_LEVEL_REGION) + 1) * REWARD_LEVEL_REGION
    local nLevelMax = HuaELouData.GetMaxLevel()
    if nLevelNear > nLevelMax then
        nLevelNear = nLevelMax
    end
    return nLevelNear
end

function HuaELouData.GetMaxExpLimit()
	return EXP_LEVEL
end

function HuaELouData.GetToAwardCollectionCount()
    local nCount = 0
    for nLevel = 0, #HuaELouData.tRewardList do
        local tReward = HuaELouData.tRewardList[nLevel]
        local eSetState,_ = HuaELouData.GetCollectionState(tReward.dwSetID)
        if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
            nCount = nCount + 1
        elseif tReward.dwSetID2 and tReward.dwSetID2 > 0 then
            eSetState,_ = HuaELouData.GetCollectionState(tReward.dwSetID2)
            if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                nCount = nCount + 1
            end
        end
    end
	return nCount
end

function HuaELouData.GetCollectionState(dwSetID)
    if not dwSetID or dwSetID <= 0 then
        return
    end
    local tResult = GetClientPlayer().GetSetCollection(dwSetID)
    local eSetState, tUnitState
    if tResult then
        eSetState = tResult.eType
        tUnitState = tResult.tSetUnit
    end
    return eSetState, tUnitState
end

function HuaELouData.GetRewardDetatil(dwSetID)
    return GetSetCollectionConfig(dwSetID)
end

function HuaELouData.GetBattlePassRedPoint()
    return HuaELouData.GetToAwardCollectionCount() ~= 0
end

-- 全服周等级上限，和策划脚本的函数一致
function HuaELouData.TravelNotes_GetUpperLimitLV()--获得每周开放多少等级
    local tTravelNotesSettings = {
	    nStartTime = DateToTime(
            CommonDef.Activity.HuaELouNewVerStartTime.nYear, CommonDef.Activity.HuaELouNewVerStartTime.nMonth,
            CommonDef.Activity.HuaELouNewVerStartTime.nDay, CommonDef.Activity.HuaELouNewVerStartTime.nHour,
            CommonDef.Activity.HuaELouNewVerStartTime.nMinute, CommonDef.Activity.HuaELouNewVerStartTime.nSecond), -- 新版起始时间，开服前要改最后一次
	    nGiveLVPerWeek = 3,
    }
    local SECPERWEEK = 7 * 24 * 3600--每周的秒数
    local MAXLEVEL = 60
	local UpperLimitLV = tTravelNotesSettings.nGiveLVPerWeek + math.floor( (GetCurrentTime() - tTravelNotesSettings.nStartTime) / SECPERWEEK) * tTravelNotesSettings.nGiveLVPerWeek
	if UpperLimitLV >= MAXLEVEL then
		UpperLimitLV = MAXLEVEL
    elseif UpperLimitLV < 0 then
        UpperLimitLV = 0
	end

    local bExtralUnlock = false
	if g_pClientPlayer and g_pClientPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 6, 1) == 1 then
		bExtralUnlock = true
	end

    if bExtralUnlock then
		UpperLimitLV = math.min(UpperLimitLV + EXTRAL_LEVEL, MAXLEVEL)
	end

	return UpperLimitLV
end

-----------------------------------------------     花萼楼相关   -----------------------------------------------

function HuaELouData.On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
    if table.contain_key(HuaELouData.tReward, dwID) then
        HuaELouData.tReward[dwID] = nil
    end

    HuaELouData.tReward[dwID] = {{nLimit, nReward}}

    if table.contain_key(HuaELouData.tCheckActive, dwID) then
        HuaELouData.tCheckActive[dwID] = nil
    end
    if bActive ~= nil then
        HuaELouData.tCheckActive[dwID] = bActive
    end

    if table.contain_key(HuaELouData.tCustom, dwID) then
        HuaELouData.tCustom[dwID] = nil
    end
    HuaELouData.tCustom[dwID] = tCustom
end

function HuaELouData.On_Check_Operation_CallBack(dwID, tCustom)
    if table.contain_key(HuaELouData.tCheckActive, dwID) then
        HuaELouData.tCheckActive[dwID] = nil
    end

    if tCustom.bShow ~= nil then
        HuaELouData.tCheckActive[dwID] = tCustom.bShow
    end

    if table.contain_key(HuaELouData.tCustom, dwID) then
        HuaELouData.tCustom[dwID] = nil
    end
    HuaELouData.tCustom[dwID] = tCustom

    FireUIEvent("EVENT_RECHARGE_CUSTOM_DATA_UPDATE", dwID, tCustom)
end

function HuaELouData.On_Recharge_GetWelfareRwd_CallBack(dwID, nRewardID)
    if nRewardID then
        local tNowCustom = HuaELouData.tCustom[dwID]
        if tNowCustom and tNowCustom.tRewardState and tNowCustom.tRewardState[nRewardID] then
            tNowCustom.tRewardState[nRewardID] = OPERACT_REWARD_STATE.ALREADY_GOT
        end
        if tNowCustom and tNowCustom.tBtnState and tNowCustom.tBtnState[nRewardID] then
            tNowCustom.tBtnState[nRewardID] = 0
        end
    else
        if table.contain_key(HuaELouData.tReward, dwID) then
            local tReward = HuaELouData.tReward[dwID]
            for k, v in pairs(tReward) do
                tReward[k] = {1, 1}
            end
        end
    end
end

function HuaELouData.OnGetOperationReward(dwID, nRewardID)
    if nRewardID then
        local tNowCustom = HuaELouData.tCustom[dwID]
        if tNowCustom and tNowCustom.tRewardState and tNowCustom.tRewardState[nRewardID] then
            tNowCustom.tRewardState[nRewardID] = OPERACT_REWARD_STATE.ALREADY_GOT
        end
        if tNowCustom and tNowCustom.tBtnState and tNowCustom.tBtnState[nRewardID] then
            tNowCustom.tBtnState[nRewardID] = 0
        end
    else
        if table.contain_key(HuaELouData.tReward, dwID) then
            local tReward = HuaELouData.tReward[dwID]
            for k, v in pairs(tReward) do
                tReward[k] = {1, 1}
            end
        end
    end
end

function HuaELouData.On_Recharge_CheckProgress_CallBack(dwID, bActive, tCustom)
    if table.contain_key(HuaELouData.tCheckActive, dwID) then
        HuaELouData.tCheckActive[dwID] = nil
    end
    if bActive ~= nil then
        HuaELouData.tCheckActive[dwID] = bActive
        HuaELouData.tCustom[dwID] = tCustom
    end
end

function HuaELouData.On_Recharge_GetProgressReward_CallBack(dwID, nLevel)
    if table.contain_key(HuaELouData.tCustom, dwID) then
        local tReward = HuaELouData.tCustom[dwID].tRewardState
        tReward[nLevel] = OPERACT_REWARD_STATE.ALREADY_GOT
    end
end

function HuaELouData.On_Recharge_CheckOnSale_CallBack(dwID, tRewardInfo, nMoney, bCanDo)
    HuaELouData.tOperActyInfo = HuaELouData.tOperActyInfo or {}
    HuaELouData.tOperActyInfo[dwID] = {nMoney = nMoney or 0, tRewardInfo = tRewardInfo or {}, tRewardState = {}}
end

function HuaELouData.On_Recharge_GetOnSaleRwd_CallBack(dwID, tLevelInfo)
    for k, v in pairs(tLevelInfo) do
        HuaELouData.tOperActyInfo[dwID].tRewardInfo[k] = {1,1}
    end
end

function HuaELouData.On_Recharge_CheckOnSaleMonthly_CallBack(dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
    if dwID == OPERACT_ID.CHARGE_MONTHLY then
        local tActivityRewardInfo = {}
        if HuaELouData.tMonthlyRecharge[nMonthId] then
            tActivityRewardInfo = HuaELouData.tMonthlyRecharge[nMonthId]
        end
        tActivityRewardInfo.tRewardInfo = tRewardInfo or {}
        tActivityRewardInfo.nMoney = nMoney or 0
        HuaELouData.tMonthlyRecharge[nMonthId] = tActivityRewardInfo
    end
end

function HuaELouData.On_Recharge_GetOnSaleMonthlyRwd_CallBack(nMonthId, tLevelInfo)
    for k, _ in pairs(tLevelInfo) do
        HuaELouData.tMonthlyRecharge[nMonthId].tRewardInfo[k] = {1, 1}
    end
end

function HuaELouData.On_Recharge_CheckTongBaoGift_CallBack(nMoney, nTotalTimes, nUsedTimes_Total, nTodayTimesLeft, tUsedTimes, tLotteryTimes, tRewardInfo, tExtraTimesInfo, nMaxExtraTimes, nDayIndex)
    self.nMoney4 = nMoney or 0
    self.nTotalTimes4 = nTotalTimes or 0
    self.nUsedTimesTotal4 = nUsedTimes_Total or 0
    self.nTodayTimesLeft4 = nTodayTimesLeft or 0
    self.tRewardInfo4 = tRewardInfo or {}
    self.tUsedTimes4 = tUsedTimes or {}
    self.tLotteryTimes4 = tLotteryTimes or {}
    self.tExtraTimesInfo4 = tExtraTimesInfo or {}
    self.nMaxExtraTimes4 = nMaxExtraTimes or 0
    self.nDayIndex = nDayIndex
end

function HuaELouData.On_Recharge_GetTongBaoGiftRwd_CallBack(tCardsList, bSuccess, tRewardInfo)
    if bSuccess and (#tCardsList == 1 or #tCardsList == 10) then
        self.tRewardInfo4 = tRewardInfo or {}

        local nTodayAvailableTimes = HuaELouData.nTodayTimesLeft4 or 0
        local nMaxExtraTimes = HuaELouData.nMaxExtraTimes4 or 0
        local tExtraTimesInfo = HuaELouData.tExtraTimesInfo4 or {}
        local nExtraLeftTimes = math.max(0, (nMaxExtraTimes - #(tExtraTimesInfo)))

        if nExtraLeftTimes > 0 then
            local nTime = GetCurrentTime()
            local tData = HuaELouData.GetCalenderData()
            local nDayIndex = HuaELouData.GetDayCount(nTime, tData.nEnd)
            if nDayIndex <= tData.nDayCount then
                table.insert(tExtraTimesInfo, nDayIndex)
            end
        elseif nTodayAvailableTimes >= #tCardsList then
            HuaELouData.nTodayTimesLeft4 = nTodayAvailableTimes - #tCardsList

            local nTotalUsedTimeOfLottery = HuaELouData.nUsedTimesTotal4 or 0
            HuaELouData.nUsedTimesTotal4 = nTotalUsedTimeOfLottery + #tCardsList
        end
    end
end

--获得奖励领取状态
function HuaELouData.GetLevelRewardStateOfPlayerByLevel(tbRewardInfo, nLevel)
    if not tbRewardInfo then
		return OPERACT_REWARD_STATE.NON_GET
	end

	local tState = tbRewardInfo[nLevel]
	if not tState or IsTableEmpty(tState) then
		return OPERACT_REWARD_STATE.NON_GET
	end

	local nState = OPERACT_REWARD_STATE.NON_GET
	--tState[0] :是否可领, tState[1] : 是否已领
	if tState[1] == 1 and tState[2] == 0 then
		nState = OPERACT_REWARD_STATE.CAN_GET
	elseif tState[2] == 1 then
		nState = OPERACT_REWARD_STATE.ALREADY_GOT
	end

	return nState
end

--在每次登录成功之后，进行服务器脚本的活动检测
function HuaELouData.GetAllCheckActive()
    local tToCheckOperatID = {}
    local tToCheckProgressOperatID = {}

    for k, v in ipairs(UIHuaELouActivityTab) do
        local dwOperatActID = v.dwOperatActID
        if HuaELouData.CheackActivityOpen(dwOperatActID) then
            local tLine = Table_GetOperActyInfo(dwOperatActID)
            if tLine and tLine.bNeedRemoteCall then
                if tLine.nOperatMode == OPERACT_MODE.PROGRESS then
                    table.insert(tToCheckProgressOperatID, dwOperatActID)
                else
                    table.insert(tToCheckOperatID, dwOperatActID)
                end
            end

            if tLine and tLine.bUseExtPoint then
                local tInfo = GDAPI_CheckWelfare(dwOperatActID)

                if tInfo and tInfo.dwID ~= 0 then
                    if table.contain_key(HuaELouData.tCheckActive, dwOperatActID) then
                        table.remove(HuaELouData.tCheckActive, dwOperatActID)
                    end
                    if tInfo.bActive ~= nil then
                        table.insert(HuaELouData.tCheckActive, dwOperatActID, tInfo.bActive)
                    end
                end
            end

            if dwOperatActID == OPERACT_ID.MAIN_LINE_FREE_TO_FULL_LEVEL then
                local bActive = HuaELouData.GetToFullLevel()
                table.insert(HuaELouData.tCheckActive, dwOperatActID, bActive)
            elseif dwOperatActID == OPERACT_ID.CHARGE_MONTHLY then
                HuaELouData.SaleMonthlyCallToServer()
            elseif dwOperatActID == OPERACT_ID.ANNIVERSARY_FEEDBACK then
                RemoteCallToServer("On_Recharge_CheckOnSale", OPERACT_ID.ANNIVERSARY_FEEDBACK)
            elseif dwOperatActID == OPERACT_ID.DOUBLE_ELEVEN_LOTTERY then
                RemoteCallToServer("On_Recharge_CheckTongBaoGift")
            end

            if tLine and tLine.bNeedCustomDataRemoteCall then
                --RemoteCallToServer("On_Recharge_Custom_Request", dwOperatActID)
            end
        end
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end

    if not table.is_empty(tToCheckProgressOperatID) then
        RemoteCallToServer("On_Recharge_CheckProgress", tToCheckProgressOperatID)
    end

    if not HuaELouData.tFirstChargeRewardInfo then
        RemoteCallToServer("On_Recharge_CheckRFirstCharge", OPERACT_ID.REAL_FIRST_CHARGE)
    end
end

function HuaELouData.ShowByCustomRule(dwOperatActID)
    local bShow = true
    if g_pClientPlayer then
        if dwOperatActID == OPERACT_ID.SEASON_RETURN then
            local bHaveRegressionGrade = g_pClientPlayer.GetRegressionGradeID() > 0 and not g_pClientPlayer.RegressionFinished()
            if bHaveRegressionGrade then
                local bExtPointActivated = g_pClientPlayer.GetExtPoint(EX_PLAYER_RETURN) or 0
                bShow = bExtPointActivated and bExtPointActivated > 0
            else
                bShow = false
            end
        elseif dwOperatActID == OPERACT_ID.SEASON_GONGZHAN then
            bShow = g_pClientPlayer.IsHaveBuff(GONGZHAN_BUFF, 10)
        end
    end

    return bShow
end

--配置检测活动是否开启
function HuaELouData.CheackActivityOpen(dwOperatActID, nID)
    local tLine = Table_GetOperActyInfo(dwOperatActID)
    local nTime = GetCurrentTime()

    if tLine then
        local nPreTime = HuaELouData.tActiveTime[dwOperatActID].nPreTime
        local nResTime = HuaELouData.tActiveTime[dwOperatActID].nResTime

        local nStart = nPreTime > 0 and nPreTime or tLine.nStartTime
        local nEnd = nResTime > 0 and nResTime or tLine.nEndTime
        local IsShow = true
        if nStart and nEnd then
            IsShow = nTime >= nStart and nTime <= nEnd
        end

        local IsClientMatching = true
        if tLine.nClientType ~= 0 then
            IsClientMatching = GetAccountType() == tLine.nClientType -- WeGame = 10 或 云端 = 11
        end

        local bIsPlayerServerAllowed = tLine.szServerName == ""
        if tLine.szServerName ~= "" then
            local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
            local tbSelectServer = LoginServerList.GetSelectServer()

            -- local _, szUserSever = select(5, GetUserServer())
            local tServerNames = SplitString(tLine.szServerName, ";")
            for _, k in ipairs(tServerNames) do
                local utf = UIHelper.GBKToUTF8(k)
                if UIHelper.GBKToUTF8(k) == tbSelectServer.szRealServer then
                    bIsPlayerServerAllowed = true
                    break
                end
            end
        end

        if tLine.szForbiddenServer ~= "" then
            local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
            local tbSelectServer = LoginServerList.GetSelectServer()

            -- local _, szUserSever = select(5, GetUserServer())
            local tServerNames = SplitString(tLine.szForbiddenServer, ";")
            for _, k in ipairs(tServerNames) do
                if UIHelper.GBKToUTF8(k) == tbSelectServer.szRealServer then
                    bIsPlayerServerAllowed = false
                    break
                end
            end
        end

        local CheckActive = HuaELouData.GetCheckActive(dwOperatActID) and HuaELouData.CheackThereActivityOpen(dwOperatActID, nID)
        local bCustomRule = HuaELouData.ShowByCustomRule(dwOperatActID)

        local nLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 0
        local bShowLevel = nLevel >= tLine.nLevel

        local bShow = tLine.bShow
        if HuaELouData.tIgnoreShowActive[dwOperatActID] then
            bShow = HuaELouData.tIgnoreShowActive[dwOperatActID]
        end

        local processor = HuaELouData.tOperationProcessor[dwOperatActID]
        if processor and IsFunction(processor.CheckShow) then
            bShow = bShow and processor.CheckShow(dwOperatActID)
        end

        if OperationCenterData.IsParentOperation(dwOperatActID) then
            local tChildOperations = OperationCenterData.GetChildOperations(dwOperatActID)
            local bHasChildOpen = false
            for _, tChildInfo in ipairs(tChildOperations) do
                if HuaELouData.CheackActivityOpen(tChildInfo.dwID) then
                    bHasChildOpen = true
                    break
                end
            end
            bShow = bShow and bHasChildOpen
        end

        -- 屏蔽旧花萼楼
        local tActivity = TabHelper.GetHuaELouActivityByOperationID(dwOperatActID)
        if tActivity and tActivity.szPrefab ~= "" then
            local nPrefabID = PREFAB_ID[tActivity.szPrefab]
            if nPrefabID then
                local conf = TabHelper.GetUIPrefabTab(nPrefabID)
                local szPath = conf and conf["szFilePath"]
                if szPath and string.find(szPath, "Prefab/HuaELou") then
                    bShow = false
                end
            end
        end
        -- 屏蔽体服不上的
        if IsVersionExp() then
            if tLine.nCategoryID == 2 or dwOperatActID == OPERACT_ID.DAILY_SIGN or dwOperatActID == 235 or dwOperatActID == 230 or dwOperatActID == 116 then
                bShow = false
            end
        end

        return IsShow and IsClientMatching and bIsPlayerServerAllowed and CheckActive and bCustomRule and bShowLevel and bShow
    end

    return false
end

--检测服务器脚本的开启配置
function HuaELouData.GetCheckActive(dwOperatActID)
    local bResult = true
    if HuaELouData.tCheckActive[dwOperatActID] ~= nil then
        bResult = HuaELouData.tCheckActive[dwOperatActID]
    end

    return bResult
end

--检测vk端的ui表的开启配置
function HuaELouData.CheackThereActivityOpen(dwOperatActID, nID)
    if nID then
        return HuaELouData.CheackThereActivityOpenByID(nID)
    else
        return HuaELouData.CheackThereActivityOpenByOperatActID(dwOperatActID)
    end
end

function HuaELouData.CheackThereActivityOpenByID(nID)
    local tActivity = UIHuaELouActivityTab[nID]
    -- 先检查 tbCheckFunc 的配置
    local bCondition = true
    for i, szCondition in ipairs(tActivity.tbCheckFunc) do
        if not string.execute(szCondition) then
            bCondition = false
            break
        end
    end

    if not bCondition then
        return false
    end

    return true
end

function HuaELouData.CheackThereActivityOpenByOperatActID(dwOperatActID)
    for _, tActivity in ipairs(UIHuaELouActivityTab) do
        if tActivity.dwOperatActID == dwOperatActID then
            -- 先检查 tbCheckFunc 的配置
            local bCondition = true
            for i, szCondition in ipairs(tActivity.tbCheckFunc) do
                if not string.execute(szCondition) then
                    bCondition = false
                    break
                end
            end

            if bCondition then
                return true
            end
        end
    end

    --首充没在表里，如果没检测到屏蔽就默认不拦截
    if dwOperatActID == OPERACT_ID.REAL_FIRST_CHARGE then
        return true
    end

    return false
end

function HuaELouData.GetAllOperatActRedPoint()
    local bResult = false

    for k = 2401, 2500 ,1 do
        if not UIRedpointTab[k] then
            break
        end

        if bResult == true then
            break
        end

        if bResult == false then
            local szActionFunc = "RedpoingConditions.Excute_"..tostring(k).."()"
            bResult = string.execute(szActionFunc) or false
            if bResult then
                LOG.INFO("[HuaELouData] configID=%d has RedPoint", k)
            end
        end
    end

    -- 有问卷的时候，也显示红点
    if QuestionnaireData.bHasNew and not AppReviewMgr.IsReview() then
        bResult = true
    end

    -- 制作人的一封信 有效时间期间，且未打开过
    if HuaELouData.GetProducerLetterRedPoint() then
        bResult = true
    end

    if HuaELouData.GetTicketRedPoint() then
        bResult = true
    end

    if HuaELouData.GetTongWarGuessingRedPoint() then
        bResult = true
    end

    if HuaELouData.GetCompetitiveMatch2025RedPoint() then
        bResult = true
    end

    if HuaELouData.GetCompetitiveMatchGuess2025RedPoint() then
        bResult = true
    end

    if HuaELouData.GetTianXuanRedPoint() then
        bResult = true
    end

    if HuaELouData.GetJJCDateRedPoint() then
        bResult = true
    end

    if HuaELouData.GetTongRenExteriorRedPoint() or HuaELouData.GetEffectDailyRedPoint() or HuaELouData.GetTongRenWeaponRedPoint() then
        bResult = true
    end

    if not bResult then
        local tbHuaELouActivityTab = clone(UIHuaELouActivityTab) or {}
        for _, tActivity in ipairs(tbHuaELouActivityTab) do
            local bShow = HuaELouData.CheackActivityOpen(tActivity.dwOperatActID, tActivity.nID)
            local tLine = Table_GetOperActyInfo(tActivity.dwOperatActID)
            if bShow and tLine then
                if tActivity.nRedPointID == 0 then
                    bResult = OperationCenterData.IsShowNew(tActivity.dwOperatActID)
                    if bResult then
                        LOG.INFO("[HuaELouData] operationID=%d has NewPoint", tActivity.dwOperatActID)
                        break
                    end
                end
            end
        end
    end

    return bResult
end

--制作人的一封信 红点
HuaELouData.szDidKeyProducerLetter = "ProducerLetter"

function HuaELouData.GetProducerLetterRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.PRODUCER_LETTER) and not APIHelper.IsDid(HuaELouData.szDidKeyProducerLetter) then
        bRedPoint = true
    end

    return bRedPoint
end

--828门票开售 首次显示红点
HuaELouData.szTicketPurchaseEligibility = "TicketPurchaseEligibility"
function HuaELouData.GetTicketRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY) and not APIHelper.IsDid(HuaELouData.szTicketPurchaseEligibility) then
        bRedPoint = true
    end

    return bRedPoint
end

--828直播按钮 首次显示红点
HuaELouData.sz15AnniLiveStreaming = "sz15AnniLiveStreaming"
function HuaELouData.Get15AnniRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING) and not APIHelper.IsDid(HuaELouData.sz15AnniLiveStreaming) then
        bRedPoint = true
    end

    return bRedPoint
end

--帮会联赛竞猜 红点
HuaELouData.szDidKeyTongWarGuessing = "TongWarGuessing"

function HuaELouData.GetTongWarGuessingRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.TONG_WAR_GUESSING) and not APIHelper.IsDid(HuaELouData.szDidKeyTongWarGuessing) then
        bRedPoint = true
    end

    return bRedPoint
end

--群英赛 红点
HuaELouData.szDidKeyCompetitiveMatch2025 = "CompetitiveMatch2025"

function HuaELouData.GetCompetitiveMatch2025RedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH) and not APIHelper.IsDid(HuaELouData.szDidKeyCompetitiveMatch2025) then
        bRedPoint = true
    end

    return bRedPoint
end

--群英赛竞猜 红点
HuaELouData.szDidKeyCompetitiveMatchGuess2025 = "CompetitiveMatchGuess2025"

function HuaELouData.GetCompetitiveMatchGuess2025RedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH_GUESS) and not APIHelper.IsDid(HuaELouData.szDidKeyCompetitiveMatchGuess2025) then
        bRedPoint = true
    end

    return bRedPoint
end

--天选系列外观票选 首次显示红点
HuaELouData.szTianXuan = "szTianXuan"

function HuaELouData.GetTianXuanRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.TIAN_XUAN_VOTE) and not APIHelper.IsDid(HuaELouData.szTianXuan) then
        bRedPoint = true
    end

    return bRedPoint
end

--同人外装评选 首次显示红点
HuaELouData.szTongRenExterior = "szTongRenExterior"

function HuaELouData.GetTongRenExteriorRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.TONG_REN_EXTERIOR) and not APIHelper.IsDid(HuaELouData.szTongRenExterior) then
        bRedPoint = true
    end

    return bRedPoint
end

--特效每天一次红点
HuaELouData.szEffectDailyRedPoint = "szEffectDailyRedPoint"

function HuaELouData.GetEffectDailyRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.WEB_EFFECT) and not APIHelper.IsDid(HuaELouData.szEffectDailyRedPoint) then
        bRedPoint = true
    end

    return bRedPoint
end

--同人武器评选 首次显示红点
HuaELouData.szTongRenWeapon = "szTongRenWeapon"

function HuaELouData.GetTongRenWeaponRedPoint()
    local bRedPoint = false

    if WebUrl.CanShow(WEBURL_ID.TONG_REN_WEAPON) and not APIHelper.IsDid(HuaELouData.szTongRenWeapon) then
        bRedPoint = true
    end

    return bRedPoint
end

--jjc按钮红点儿 特效时间范围内显示点掉了就掉了
function HuaELouData.GetJJCDateRedPoint()
    local bRedPoint = false

    if not IsVersionTW() then
        local nTime = GetCurrentTime()
        local function ReturnDateToTime(szTime)
            local t = SplitString(szTime, ";")
            if #t >= 6 then
                return DateToTime(t[1], t[2], t[3], t[4], t[5], t[6])
            end
        end

        local tPVPLinkDate = Table_GetPVPLinkDate()
        for _, tLine in pairs(tPVPLinkDate) do
            local nStartShineTime = ReturnDateToTime(tLine.szStartShine)
			local nEndShineTime = ReturnDateToTime(tLine.szEndShine)

            if nTime > nStartShineTime and nTime < nEndShineTime then
                bRedPoint = not APIHelper.IsDid(UIHelper.GBKToUTF8(tLine.szTip))
            end
        end
    end

    return bRedPoint
end

--通过活动id来检查可领取红点
function HuaELouData.GetOperatActRedPoint(dwOperatActID)
    local bRedPoint = false

    if HuaELouData.CheackActivityOpen(dwOperatActID) then
        local tLine = Table_GetOperActyInfo(dwOperatActID)
        if tLine and tLine.bUseExtPoint then
            bRedPoint = HuaELouData.GetExtPointRedPoint(dwOperatActID)
        end

        if tLine and tLine.bNeedRemoteCall then
            bRedPoint = HuaELouData.GetRemoteCallRedPoint(dwOperatActID, tLine.nOperatMode)
        end

        if dwOperatActID == OPERACT_ID.REAL_FIRST_CHARGE then
            bRedPoint = HuaELouData.GetFirstChargeRedPoint()
        elseif dwOperatActID == OPERACT_ID.SEASON_DISTANCE then
            bRedPoint = HuaELouData.GetSeasonDistanceRedPoint()
        elseif dwOperatActID == OPERACT_ID.CHARGE_MONTHLY then
            bRedPoint = HuaELouData.GetSaleMonthlyRedPoint()
        elseif dwOperatActID == OPERACT_ID.SEASON_RETURN then
            bRedPoint = HuaELouData.GetReturnGiftRedPoint()
        elseif dwOperatActID == OPERACT_ID.ANNIVERSARY_FEEDBACK then
            bRedPoint = HuaELouData.GetOnSaleRedPoint()
        elseif dwOperatActID == OPERACT_ID.DOUBLE_ELEVEN_LOTTERY then
            bRedPoint = HuaELouData.GetDoubleElevenRedPoint()
        end

        local processor = HuaELouData.tOperationProcessor[dwOperatActID]
        if processor and IsFunction(processor.HasRedPoint) then
            bRedPoint = processor.HasRedPoint(dwOperatActID) or bRedPoint
        end

        -- 如果是父活动，额外检查所有子活动
        if not bRedPoint and OperationCenterData.IsParentOperation(dwOperatActID) then
            local tChildOperations = OperationCenterData.GetChildOperations(dwOperatActID)
            for _, tChildInfo in ipairs(tChildOperations) do
                if HuaELouData.CheackActivityOpen(tChildInfo.dwID) and HuaELouData.GetOperatActRedPoint(tChildInfo.dwID) then
                    bRedPoint = true
                    break
                end
            end
        end
    end

    return bRedPoint
end

--通过拓展点检查可领取红点
function HuaELouData.GetExtPointRedPoint(dwOperatActID)
    local tReward = {}
    local bRedPoint = false

    local tInfo = GDAPI_CheckWelfare(dwOperatActID)
    if tInfo and tInfo.dwID ~= 0 then
        tReward = {{tInfo.nLimit, tInfo.nReward}}
    end

    local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, 1)
    if nState == OPERACT_REWARD_STATE.CAN_GET then
        bRedPoint = true
    end

    return bRedPoint
end

--通过远程调用检查可领取红点
function HuaELouData.GetRemoteCallRedPoint(dwOperatActID, nOperatMode)
    local tReward = {}
    local bRedPoint = false

    if table.contain_key(HuaELouData.tReward, dwOperatActID) then
        tReward = HuaELouData.tReward[dwOperatActID]
        local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, 1)
        if nState == OPERACT_REWARD_STATE.CAN_GET then
            bRedPoint = true
        end
    end

    if table.contain_key(HuaELouData.tCustom, dwOperatActID) then
        tReward = HuaELouData.tCustom[dwOperatActID].tRewardState
        for _, nState in ipairs(tReward) do
            if nState == OPERACT_REWARD_STATE.CAN_GET then
                bRedPoint = true
            end
        end
    end

    if not table.contain_key(HuaELouData.tReward, dwOperatActID) and
    not table.contain_key(HuaELouData.tCustom, dwOperatActID) then
        --HuaELouData.GetRemoteCallRedPointAgain(dwOperatActID, nOperatMode)
    end

    return bRedPoint
end

function HuaELouData.GetRemoteCallRedPointAgain(dwOperatActID, nOperatMode)
    local tToCheckOperatID = {}
    local tToCheckProgressOperatID = {}

    if nOperatMode == OPERACT_MODE.PROGRESS then
        table.insert(tToCheckProgressOperatID, dwOperatActID)
    else
        table.insert(tToCheckOperatID, dwOperatActID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end

    if not table.is_empty(tToCheckProgressOperatID) then
        RemoteCallToServer("On_Recharge_CheckProgress", tToCheckProgressOperatID)
    end
end

--首充有一个单独的远程调用
function HuaELouData.GetFirstChargeRedPoint()
    local bRedPoint = false

    local tbRewardInfoFromTable = HuaELouData.GetRewardLevelInfoByActivityID(OPERACT_ID.REAL_FIRST_CHARGE)

    for _, tbRewardInfo in ipairs(tbRewardInfoFromTable) do
        local nRewardState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(HuaELouData.tFirstChargeRewardInfo, tbRewardInfo.nLevel)
        if nRewardState == OPERACT_REWARD_STATE.CAN_GET then
            bRedPoint = true
            break
        end
    end

    if bRedPoint == false then
        local szKey = Table_GetOperActyDes(OPERACT_ID.REAL_FIRST_CHARGE)
        bRedPoint = not APIHelper.IsDid(szKey)
    end

    return bRedPoint
end

--赛季有一个单独的检查方式
function HuaELouData.GetSeasonDistanceRedPoint()
    local bRedPoint = false

    local tData = GDAPI_GetSeasonDistanceInfo()
    local tPvxRewardState = tData.tPvx and tData.tPvx.tRewardState or {}
    local tHomelandRewardState = tData.tHomeland and tData.tHomeland.tRewardState or {}
    for _, nState in ipairs(tPvxRewardState) do
        if nState == 0 then
            bRedPoint = true
            break
        end
    end
    for _, nState in ipairs(tHomelandRewardState) do
        if nState == 0 then
            bRedPoint = true
            break
        end
    end

    return bRedPoint
end

--赛季战力篇红点
function HuaELouData.GetSeasonDistancePvxRedPoint()
    local bRedPoint = false

    local tData = GDAPI_GetSeasonDistanceInfo()
    local tPvxRewardState = tData.tPvx and tData.tPvx.tRewardState or {}
    for _, nState in ipairs(tPvxRewardState) do
        if nState == 0 then
            bRedPoint = true
            break
        end
    end

    return bRedPoint
end

--赛季家园篇红点
function HuaELouData.GetSeasonDistanceHomelandRedPoint()
    local bRedPoint = false

    local tData = GDAPI_GetSeasonDistanceInfo()
    local tHomelandRewardState = tData.tHomeland and tData.tHomeland.tRewardState or {}
    for _, nState in ipairs(tHomelandRewardState) do
        if nState == 0 then
            bRedPoint = true
            break
        end
    end

    return bRedPoint
end

function HuaELouData.SaleMonthlyCallToServer()
    local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
    table.sort(tChongXiaoMon, function(tLeft, tRight)
		return tLeft[1].nEndTime < tRight[1].nStartTime
    end)

    local tPrevPageInfos, tCurPageInfos, tNextPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)

    RemoteCallToServer("On_Recharge_CheckOnSaleMonthly", OPERACT_ID.CHARGE_MONTHLY, tPrevPageInfos[1].dwID)
    RemoteCallToServer("On_Recharge_CheckOnSaleMonthly", OPERACT_ID.CHARGE_MONTHLY, tCurPageInfos[1].dwID)
end

--活动2充值返利的远程调用
function HuaELouData.GetOnSaleRedPoint()
    local bRedPoint = false

    if HuaELouData.tOperActyInfo and HuaELouData.tOperActyInfo[OPERACT_ID.ANNIVERSARY_FEEDBACK] then
        local tReward = HuaELouData.tOperActyInfo[OPERACT_ID.ANNIVERSARY_FEEDBACK].tRewardInfo

        for i, v in ipairs(tReward) do
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, i)
            if nState == OPERACT_REWARD_STATE.CAN_GET then
                return true
            end
        end
    end

    return bRedPoint
end

--活动4
function HuaELouData.GetDoubleElevenRedPoint()
    local bRedPoint = false

    if self.nTodayTimesLeft4 then
        local nTodayTotlaTimes = self.nTodayTimesLeft4 + math.max(0, (self.nMaxExtraTimes4 - #self.tExtraTimesInfo4))
        return nTodayTotlaTimes > 0
    end

    return bRedPoint
end

--月度冲消单独的远程调用
function HuaELouData.GetSaleMonthlyRedPoint()
    local bRedPoint = false

    local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
    table.sort(tChongXiaoMon, function(tLeft, tRight)
        return tLeft[1].nEndTime < tRight[1].nStartTime
    end)

    local tPrevPageInfos, tCurPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)

    local nMonthId = tCurPageInfos[1].dwID
    if HuaELouData.tMonthlyRecharge[nMonthId] then
        local tReward = HuaELouData.tMonthlyRecharge[nMonthId].tRewardInfo

        for k ,v in ipairs(tReward) do
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, tCurPageInfos[k + 1].nSubID)
            bRedPoint = bRedPoint or nState == OPERACT_REWARD_STATE.CAN_GET
            if bRedPoint then
                return bRedPoint
            end
        end
    end

    nMonthId = tPrevPageInfos[1].dwID
    if HuaELouData.tMonthlyRecharge[nMonthId] then
        local tReward = HuaELouData.tMonthlyRecharge[nMonthId].tRewardInfo

        for k ,v in ipairs(tReward) do
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, tPrevPageInfos[k + 1].nSubID)
            bRedPoint = bRedPoint or nState == OPERACT_REWARD_STATE.CAN_GET
            if bRedPoint then
                return bRedPoint
            end
        end
    end

    return bRedPoint
end

function HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)
    local nCurTime = GetCurrentTime()

    local nCurPage = 0
    local nDefaultPage = 0
    for nIndex, tPageInfo in ipairs(tChongXiaoMon) do
        if nCurTime >= tPageInfo[1].nStartTime and nCurTime < tPageInfo[1].nEndTime then
            nCurPage = nIndex
            break
        end
        if tPageInfo[1].nEndTime <= nCurTime then
            nDefaultPage = nIndex
        end
    end
    if 0 == nCurPage then
        nCurPage = nDefaultPage
    end
    local nPrevPage, nCurPage, nNextPage = HuaELouData.GetPageMonth(nCurPage, nMaxIssue)
    local tPrevPageInfos = tChongXiaoMon[nPrevPage]
    local tCurPageInfos  = tChongXiaoMon[nCurPage]
    local tNextPageInfos = tChongXiaoMon[nNextPage]

    return tPrevPageInfos, tCurPageInfos, tNextPageInfos
end

function HuaELouData.GetPageMonth(nCurrIndex, nMaxIssue)
    local nMid  = nCurrIndex
    local nPrev = HuaELouData.AdjustPos(nMid - 1, nMaxIssue)
    local nNext = HuaELouData.AdjustPos(nMid + 1, nMaxIssue)

    return nPrev, nMid, nNext
end

function HuaELouData.AdjustPos(pos, count)
    if pos < 1 then
        pos = pos + count
    end

    if pos > count then
        pos = pos - count
    end

    return pos
end

--回归礼包检查可领取红点
function HuaELouData.GetReturnGiftRedPoint()
    local bRedPoint = false

    if g_pClientPlayer then
        local tRegressionData = g_pClientPlayer.GetRegressionData()
        for k,tData in ipairs(tRegressionData) do
            if tData.bAllUsed then
            elseif tData.bCanHave then
                bRedPoint = true
                break
            end
        end
    end

    return bRedPoint
end

-- 直升礼盒这个活动，每个服务器开服三天后开启，端游多个id来做的
-- 我们特殊处理为判断商城是否有售卖直升礼盒，有的话展示这个活动
function HuaELouData.GetToFullLevel()
    local dwGoodsID = 4721
    local tLine = Table_GetRewardsItem(dwGoodsID)
    if not tLine then
        return
    end

    local bShow = CoinShop_CheckRewardsTime(tLine.dwLogicID, tLine.nClass)

    return bShow
end

function HuaELouData.GetRewardLevelInfoByActivityID(nActivityID)
    if not HuaELouData.tbAllActivityRewardLevelInfo then
		HuaELouData.tbAllActivityRewardLevelInfo = Table_GetRewardLevelInfo()
	end
	return HuaELouData.tbAllActivityRewardLevelInfo[nActivityID]
end

function HuaELouData.GetTimeShowText(nStart, nEnd)
    if not nEnd then
		return
	end

	local tStart = TimeToDate(nStart)
	local tEnd = TimeToDate(nEnd)
	local szTime1 = ""
	local szTime2 = ""
	if tStart.year == tEnd.year then
		szTime1 = FormatString(g_tStrings.STR_TIME_9, tStart.month, tStart.day, tStart.hour, string.format("%02d", tStart.minute))
		szTime2 = FormatString(g_tStrings.STR_TIME_9, tEnd.month, tEnd.day, tEnd.hour, string.format("%02d", tEnd.minute))
	else
		szTime1 = FormatString(g_tStrings.STR_TIME_4, tStart.year, tStart.month, tStart.day, tStart.hour, string.format("%02d", tStart.minute))
		szTime2 = FormatString(g_tStrings.STR_TIME_4, tEnd.year, tEnd.month, tEnd.day, tEnd.hour, string.format("%02d", tEnd.minute))
	end

	return szTime1 .. "-" .. szTime2
end

function HuaELouData.GetShowReward(nID)
    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity or tActivity.szShowReward == "" then
        return
    end

    local tReward = {}

    local tShowReward = string.split(tActivity.szShowReward, ";")
    for k, v in ipairs(tShowReward) do
        local tItemInfo = string.split(v, "_")
        table.insert(tReward, {tItemInfo[1], tItemInfo[2], tItemInfo[3]})
    end

    return tReward
end

function HuaELouData.HandleJump(szLink, bIsEmbededExplorer)
    local szLinkEvent, szLinkArg = szLink:match("(%w+)/(.*)")
    if szLinkEvent == "NPCGuide" then
        local tLinkInfo = Table_GetCareerLinkNpcInfo(szLinkArg)
        local szText = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)

		MapMgr.SetTracePoint(szText, tLinkInfo.dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tLinkInfo.dwMapID, 0)
        return
    elseif szLinkEvent == "ShopPanel" then
        local tLinkArg = SplitString(szLinkArg, "/")
        local szShopID, szGroupID = tLinkArg[1], tLinkArg[2]
        local dwShopID = tonumber(szShopID)
        local dwGroupID = tonumber(szGroupID) or 1

        ShopData.OpenSystemShopGroup(dwGroupID, dwShopID)
    elseif szLinkEvent == "GuideTeleport" then
        local tLinkArg = SplitString(szLinkArg, "/")
        local nLinkID = tonumber(tLinkArg[1])
        local dwMapID = tonumber(tLinkArg[2])
        if nLinkID and dwMapID then
            HuaELouData.Teleport(nLinkID, dwMapID)
        end
    end

    if tUrl[szLink] and tUrl[szLink] ~= "" then
        if bIsEmbededExplorer then
            UIHelper.OpenWeb(tUrl[szLink])
        else
            UIHelper.OpenWebWithDefaultBrowser(tUrl[szLink])
        end
    else
        FireUIEvent("EVENT_LINK_NOTIFY", szLink)
    end
end

function HuaELouData.HandleJumpYunTu()
    if not APIHelper.IsDid("HandleJumpYunTu") then
        APIHelper.Do("HandleJumpYunTu")
        TeachBoxData.OpenTutorialPanel(142)
    end
    UIMgr.Close(VIEW_ID.PanelOperationCenter)
    Event.Dispatch(EventType.OpenCameraPanel)
end

function HuaELouData.HandleBuy(szLinkInfo)
    local tLinkInfo = {}
	if not szLinkInfo or szLinkInfo == "" or not string.find(szLinkInfo, "|") then
		return nil
	end

    local tInfo = SplitString(szLinkInfo, "-")
    local szBuyLinkInfo = tInfo[2]

	local tStringInfo = SplitString(szBuyLinkInfo, '|')
    local eGoodsType, dwGoodsID = tonumber(tStringInfo[1]), tonumber(tStringInfo[2])
	tLinkInfo.dwGoodsType = eGoodsType
	tLinkInfo.dwGoodsID = dwGoodsID

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") or CheckPlayerIsRemote() or
    not CheckAndProcessHandleOfBuy(tLinkInfo) then
        return
    end

    --目前支持购买单个商品
    local nCost = CoinShop_GetPrice(dwGoodsID, eGoodsType) or 0
    local tRewardsItem = Table_GetRewardsItem(dwGoodsID)
    local dwTabType, dwTabIndex = tRewardsItem.dwTabType, tRewardsItem.dwIndex
    local iteminfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
    local szItemName = string.format("<color=%s>%s</c>", ItemQualityColor[iteminfo.nQuality + 1], UIHelper.GBKToUTF8(iteminfo.szName))
    local szContent = string.format(g_tStrings.STR_JINXIU_BUY_1, nCost, szTongBaoRichImg, szItemName)

    local nBuyCount = 1

    UIHelper.ShowConfirm(szContent, function ()
        local nRetCode = CoinShop_BuyItem(dwGoodsID, eGoodsType, nBuyCount)
        if nRetCode == COIN_SHOP_ERROR_CODE.NOT_ENOUGH_COIN then
            local tProductList = PayData.GetAllPayConfigOfType(PayData.RechargeTypeEnum.szCoin)
            if not IsTableEmpty(tProductList) then
                UIMgr.Open(VIEW_ID.PanelTopUpMain)
            end
        end
    end, nil, true)
end

function CheckAndProcessHandleOfBuy(tLinkInfo)
    local bPass = true

    local eGoodsType, dwGoodsID = tLinkInfo.dwGoodsType, tLinkInfo.dwGoodsID
	if not IsHavePreOrder(eGoodsType, dwGoodsID) then
        bPass = false
    end

    return bPass
end

function IsJinXiuNiChangItem(dwTabType, dwIndex)
    local bResult = false

    if HuaELouData.CheackActivityOpen(OPERACT_ID.BATTLE_PASS) then
        local szUserData = Table_GetOperationActUserData(OPERACT_ID.BATTLE_PASS)
        local tUserData = SplitString(szUserData, '|')

        local tItemInfo = {}
        --字符串 %d;%d 商城商品type,商城商品id
        for i, tItemData in ipairs(tUserData) do
            local tGoodData = SplitString(tItemData, ';')
            tItemInfo[i] = {}
            tItemInfo[i].dwGoodsType = tonumber(tGoodData[1])
            tItemInfo[i].dwGoodsID 	 = tonumber(tGoodData[2])
            tItemInfo[i].nIconFrame  = tonumber(tGoodData[3])
        end

        local tInfo = {}
        for i, Item in ipairs(tItemInfo) do
            tInfo[i] = GetRewardsShop().GetRewardsShopInfo(Item.dwGoodsID)
        end

        for k, v in ipairs(tInfo) do
            if dwTabType == tInfo[k].dwItemTabType and tInfo[k].dwItemTabIndex == dwIndex then
                bResult = true
            end
        end
    end

    return bResult
end

function HuaELouData.IgnoreOperacShow(dwOperatActID)
    HuaELouData.tIgnoreShowActive[dwOperatActID] = true
    return true
end

function HuaELouData.Open(dwID)
    --首充被单独拿出来了
    if dwID == 55 then
        UIMgr.Open(VIEW_ID.PanelBenefits)
        return
    else
        for k, v in ipairs(UIHuaELouActivityTab) do
            if dwID == v.dwOperatActID then
                if UIMgr.GetView(VIEW_ID.PanelOperationCenter) then
                    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelOperationCenter)
                    scriptView:OnEnter(dwID)
                else
                    UIMgr.Open(VIEW_ID.PanelOperationCenter, dwID)
                end

                return
            end
        end
    end

    LOG.INFO("UIHuaELouActivityTab表里没配这个id的活动，请检查一下配置表")
end

function HuaELouData.Teleport(nLinkID, dwMapID, dwActivityID)
    -- 地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, nil, nil, true) then
        return
    end

    if HomelandData.CheckIsHomelandMapTeleportGo(nLinkID, dwMapID, dwActivityID, nil, function ()
            UIMgr.Close(VIEW_ID.PanelOperationCenter)
        end) then
        return
    end
    MapMgr.CheckTransferCDExecute(function()
        RemoteCallToServer('On_Teleport_Go', nLinkID, dwMapID, dwActivityID)
        UIMgr.Close(VIEW_ID.PanelOperationCenter)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPublicTraceTip)
    end, dwMapID)
end

--唐简传传送
function HuaELouData.TangJianZhuanTeleport()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if hPlayer.nLevel < 130 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_TANG_JIAN_TP_FORBIDDEN)
        return
    end

    local dwMapID = nil
    local nLinkID = nil

    if hPlayer.GetQuestPhase(28942) == 1 then
        nLinkID = 2795
        dwMapID = 789
    else
        if hPlayer.dwForceID == 7 then
            if hPlayer.GetQuestPhase(28908) == 0 or hPlayer.GetQuestPhase(28919) == 2 then
                nLinkID = 2794
                dwMapID = 122
            else
                nLinkID = 138
                dwMapID = 122
            end
        else
            if hPlayer.GetQuestPhase(28960) == 0 or hPlayer.GetQuestPhase(28921) == 2 then
                nLinkID = 2794
                dwMapID = 122
            else
                nLinkID = 138
                dwMapID = 122
            end
        end
    end

    if not dwMapID or not nLinkID then
        return
    end

    if dwMapID == 789 and hPlayer.IsInParty() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_TANG_JIAN_TP_PARTY_FORBIDDEN)
        return
    end

    --true:不需要消耗神行CD
    local bSafeCity = false
    if dwMapID and IsHomelandCommunityMap(dwMapID) then
        bSafeCity = GDAPI_Homeland_SafeCity()
    end

    local fnTeleport = function()
        local bCD, _ = MapMgr.GetTransferSkillInfo()
        if not bCD or bSafeCity then
            MapMgr.BeforeTeleport()
            RemoteCallToServer("On_Teleport_Go", nLinkID, dwMapID)
            UIMgr.Close(VIEW_ID.PanelOperationCenter)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPublicTraceTip)
		else
			MapMgr.CheckTransferCDExecute(function()
                MapMgr.BeforeTeleport()
                RemoteCallToServer("On_Teleport_Go", nLinkID, dwMapID)
                UIMgr.Close(VIEW_ID.PanelOperationCenter)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPublicTraceTip)
			end)
		end
    end

    -- 地图资源下载检测拦截
    local tMapIDList = {122, 789}
    local szName = GBKToUTF8(Table_GetMapName(dwMapID))
    if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, function()
        fnTeleport()
    end, "地图资源文件下载完成，" .. string.format(g_tStrings.TRANSFER_CONFIRM, szName)) then
        return
    end

    fnTeleport()
end

function HuaELouData.CheckHuaELouBubble()
    return g_pClientPlayer.nLevel < 108 or AppReviewMgr.IsReview()
end

local function GetEndTime() -- 结束时间，如果 UNTIL_SEASON_END 为true则不显示
    return DateToTime(0, 0, 0, 0, 0, 0)
end

function HuaELouData.GetCalenderData()
    local tLine = Table_GetOperActyInfo(OPERACT_ID.DOUBLE_ELEVEN_LOTTERY) assert(tLine)
    local tData = {}

    tData.nStart = tLine.nStartTime
    tData.nEnd = tLine.nEndTime
    tData.nDayCount = HuaELouData.GetDayCount(tData.nStart, tData.nEnd) - 1

    return tData
end

local function BigIntSub(nLeft, nRight)
    return nLeft - nRight
end

function HuaELouData.GetTargetList(dwActivityID, szTPLink)
    local tInfo = Table_GetOperActyInfo(dwActivityID) or {}
    local tTargetList = {}

    local szLinkMap = tInfo.szTPLink or ""
    if szLinkMap == "" and szTPLink then
        szLinkMap = szTPLink
    end
    if szLinkMap and szLinkMap ~= "" then
        local tLinkMap     = SplitString(szLinkMap, ";")
        for _, v in pairs(tLinkMap) do
            local tArgs = SplitString(v, "_")
            local nLinkID = tonumber(tArgs[1])
            local dwMapID = tonumber(tArgs[2])
            local tAllLinkInfo = {}
            if nLinkID and not dwMapID then
                tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            elseif nLinkID and dwMapID then
                local tInfo = Table_GetCareerLinkNpcInfo(nLinkID, dwMapID)
                table.insert(tAllLinkInfo, tInfo)
            end

            for _, tInfo in pairs(tAllLinkInfo) do
                local bCanShow = ActivityData.CanTPLinkShow(tInfo)
                if bCanShow then
                    table.insert(tTargetList, tInfo)
                end
            end
        end
    end

    return tTargetList
end

--计算nStart,nEnd之间的天数间隔
function HuaELouData.GetDayCount(nStart, nEnd)
    local tStart = TimeToDate(nStart)
    local tEnd = TimeToDate(nEnd)
    local nTrueStart = DateToTime(tStart.year, tStart.month, tStart.day, 0, 0, 1)
    local nTrueEnd = DateToTime(tEnd.year, tEnd.month, tEnd.day, 23, 59, 59)
    local nCount = math.ceil(BigIntSub(nTrueEnd, nTrueStart) / (24 * 3600))
    return nCount
end