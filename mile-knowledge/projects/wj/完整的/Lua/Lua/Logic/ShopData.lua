ShopData = ShopData or {}

function ShopData.Init()

end

function ShopData.UnInit()

end

local m_tString = {
    "<text>text=", "</text>"
}

local FONT_SATISFY = "\n<color=#AFC1D4>%s</c>"
local FONT_NOT_SATISFY = "\n<color=#FF0000>%s</c>"
local CAMP_SHARD = "\n<color=#AED9E0>%s</c>"

local tconcat = table.concat

ShopData.szScreenImgActiving = "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing"
ShopData.szScreenImgDefault = "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen"
ShopData.szReturnPrevPanel = "UIAtlas2_Public_PublicButton_PublicButton1_btn_return_Other"
ShopData.szReturnMainPanel = "UIAtlas2_Public_PublicButton_PublicButton1_btn_return_main"
ShopData.dwEqupSetShopID = 1431 -- 系统商店唯一兑换牌商店的ShopID

ShopData.CurrencyCode = {
    Default = 1, -- 帮会资金
    Coin = 2, -- 通宝
    Prestige = 3, -- 威名点
    Justice = 4, -- 侠义值
    Architecture = 5, -- 园宅币
    TongFund = 6, -- 帮会资金
    ArenaCoin = 7, -- 名剑币
    MentorValue = 8, -- 师徒值
    Contribution = 9, -- 休闲点
    ExamPrint = 10, -- 奇境宝钞
    WeekPoints = 11, -- 周行令
    SeasonHonorXiuXian = 12, -- 赛季荣誉休闲碎片
    SeasonHonorMiJing = 13, --赛季荣誉秘境碎片
    SeasonHonorPVP = 14, --赛季荣誉对抗碎片
}

ShopData.MoneyIndex = {
    Brick   = 1,
    Gold    = 2,
    Sliver  = 3,
    Copper  = 4,
}

ShopData.MoneyIndex2Tex = {
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong.png"
}

ShopData.OtherInfo2CurrencyType = {
    --nActivityAward = CurrencyType.Prestige,
    nArchitecture = CurrencyType.Architecture,
    --nArenaAward = CurrencyType.Prestige,
    nArenaTowerAward = CurrencyType.ArenaTowerAward,
    nContribution = CurrencyType.Contribution,
    nDungeonTowerAward = CurrencyType.DungeonTowerAward,
    nExamPrint = CurrencyType.ExamPrint,
    nHomelandToken = CurrencyType.HomelandToken,
    nJustice = CurrencyType.Justice,
    nMentorAward = CurrencyType.MentorAward,
    nPrestige = CurrencyType.Prestige,
    nRover = CurrencyType.Rover,
    nSandstormAward = CurrencyType.FeiShaWand,
    nTongLeaguePoint = CurrencyType.TongLeaguePoint,
    nWeekAward = CurrencyType.WeekAward,
    nZhuiGanShopAward = CurrencyType.ZhuiGanShopAward,
    nTongFund = CurrencyType.GangFunds,
    nCoin = CurrencyType.Coin,
}

ShopData.CurrencyCode2Tex = {
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_WeiMingDian.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiaYiZhi.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_BangHui.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingJiFen.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShiTu.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_xiuxian.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_QiJing.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhouKe.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvxB.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PveB.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvpB.png",
}

ShopData.CurrencyCode2TexObj = {
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingLi",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_WeiMingDian",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_XiaYiZhi",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_BangHui",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JingJiFen",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ShiTu",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_xiuxian",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_QiJing",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_ZhouKe.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvxB.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PveB.png",
    "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_PvpB.png",
}

ShopData.CNameToColor = {
    ["白"] = cc.c3b(0xFF, 0xFF, 0xFF),
    ["黄"] = cc.c3b(0xFF, 0xE2, 0x6E),
    ["蓝"] = cc.c3b(0x84, 0xCA, 0xFF),
    ["绿"] = cc.c3b(0x95, 0xFF, 0x95),
    ["红"] = cc.c3b(0xFF, 0x75, 0x75),
    ["紫"] = cc.c3b(0xF7, 0xAB, 0xFF),
    ["黑"] = cc.c3b(0x00, 0x00, 0x00),
}

ShopData.SpringFestivalQualityBg = {
    [1] = "UIAtlas2_Festival_SpringFestivalStore_ItemQuality_White.png",
    [2] = "UIAtlas2_Festival_SpringFestivalStore_ItemQuality_Green.png",
    [3] = "UIAtlas2_Festival_SpringFestivalStore_ItemQuality_Blue.png",
    [4] = "UIAtlas2_Festival_SpringFestivalStore_ItemQuality_Purple.png",
    [5] = "UIAtlas2_Festival_SpringFestivalStore_ItemQuality_Orange.png",
}

ShopData.FullScreenQualityBg = {
    [1] = "UIAtlas2_Activity_ActivityStore_pzk_bai.png",
    [2] = "UIAtlas2_Activity_ActivityStore_pzk_lv.png",
    [3] = "UIAtlas2_Activity_ActivityStore_pzk_lan.png",
    [4] = "UIAtlas2_Activity_ActivityStore_pzk_zi.png",
    [5] = "UIAtlas2_Activity_ActivityStore_pzk_jin.png",
}

ShopData.tKungfuConfig = {
    [10175] = {}, --毒经
    [10176] = {}, --补天
    [10081] = {}, --冰心
    [10080] = {}, --云裳
    [10021] = {}, --花间
    [10028] = {}, --离经
    [10447] = {}, --莫问
    [10448] = {}, --相知
    [10144] = {}, --问水
    [10145] = {}, --山居
    [10026] = {}, --傲血
    [10062] = {}, --铁牢
    [10003] = {}, --易筋
    [10002] = {}, --洗髓
    [10390] = {}, --分山
    [10389] = {}, --铁骨
    [10242] = {}, --焚影
    [10243] = {}, --明尊
    [10224] = {}, --惊羽
    [10225] = {}, --天罗
    [10268] = {}, --笑尘
    [10014] = {}, --紫霞
    [10015] = {}, --太虚
    [10464] = {}, --北傲
    [10533] = {}, --凌海诀
    [10585] = {}, --隐龙诀
    [10615] = {}, --太玄经(衍天宗)
    [10626] = {}, --灵素
    [10627] = {}, --无方
    [10698] = {}, --孤锋诀

    [100389] = {bIsMoblie = true}, --移动端_太虚剑意
    [100398] = {bIsMoblie = true}, --移动端_紫霞功
    [100409] = {bIsMoblie = true}, --移动端_云裳心经
    [100410] = {bIsMoblie = true}, --移动端_冰心诀
    [100408] = {bIsMoblie = true}, --移动端_花间游
    [100411] = {bIsMoblie = true}, --移动端_离经易道
    [100406] = {bIsMoblie = true}, --移动端_傲血战意
    [100407] = {bIsMoblie = true}, --移动端_铁牢律
    [100069] = {bIsMoblie = true}, --移动端_洗髓经
    [100053] = {bIsMoblie = true}, --移动端_易筋经
    [100618] = {bIsMoblie = true}, --移动端_焚影圣决
    [100631] = {bIsMoblie = true}, --移动端_明尊琉璃体
    [100654] = {bIsMoblie = true}, --移动端_毒经
    [100655] = {bIsMoblie = true}, --移动端_补天决
    [100725] = {bIsMoblie = true}, --移动端_问水决（移动端无山居剑意）
    [100651] = {bIsMoblie = true}, --移动端_笑尘决
    [100636] = {bIsMoblie = true}, --移动端_天罗诡道
    [100638] = {bIsMoblie = true}, --移动端_惊羽决
    [100994] = {bIsMoblie = true}, --移动端_北傲决
    [101024] = {bIsMoblie = true}, --移动端_铁骨衣
    [101025] = {bIsMoblie = true}, --移动端_分山劲
    [101124] = {bIsMoblie = true}, --移动端_莫问
    [101125] = {bIsMoblie = true}, --移动端_相知
    [101090] = {bIsMoblie = true}, --移动端_凌海诀
}

ShopData.MAX_WAIT_TIME = 60 -- 购买等回包最多等多少秒

function ShopData.CanMeUseThisItem(player, item)
    if item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return true
    end

    local requireAttrib = item.GetRequireAttrib()
    for k, v in pairs(requireAttrib) do
        if not player.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
            return false
        end
    end
    return true
end

function ShopData.GetSatisfyColor(bSatisfy)
    if bSatisfy then
        return 255, 255, 255
    else
        return 255, 0, 0
    end
end

local _GetItemInfo = GetItemInfo
local function GetItemInfo(...)
    local tArg = { ... }
    if #tArg ~= 2 then
        return
    end
    for i = 1, select("#", ...) do
        if not tArg[i] then
            return -- 省的刷LOG
        end
    end
    return _GetItemInfo(...)
end

function CopyTable(tab)
    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        end
        local new_table = {}
        for k, v in pairs(obj) do
            new_table[_copy(k)] = _copy(v)
        end
        return setmetatable(new_table, getmetatable(obj))
    end
    return _copy(tab)
end

local function GetDateTextHour(nTime)
    local tTime = TimeToDate(nTime)
    local szText = FormatString(g_tStrings.STR_DATE_HOUR, tTime.year, tTime.month, tTime.day, tTime.hour)
    return szText
end

local function GetBuyItemStartTime(aShopInfo)
    local nCurrentTime = GetCurrentTime()
    if aShopInfo and aShopInfo.nBeginSellTime and aShopInfo.nBeginSellTime > nCurrentTime then
        local szTip = FormatString(g_tStrings.SHOP_ITEM_WILL_SELL_AT, GetDateTextHour(aShopInfo.nBeginSellTime))
        szTip = string.gsub(szTip, "\n", "")
        szTip = string.format(FONT_NOT_SATISFY, szTip)

        return szTip
    end
end

local tRequireArenaLevel = { ARENA_TYPE.ARENA_2V2, ARENA_TYPE.ARENA_3V3, ARENA_TYPE.ARENA_5V5 }
local tRequireExcept2v2 = { ARENA_TYPE.ARENA_3V3, ARENA_TYPE.ARENA_5V5 }

local function GetShopBuyInfoTip(aShopInfo)
    local szTip = ""
    if aShopInfo.dwNeedLevel > 3 then
        local tRepuForceInfo = Table_GetReputationForceInfo(aShopInfo.dwNeedForce)
        local tRepuLevelInfo = Table_GetReputationLevelInfo(aShopInfo.dwNeedLevel)
        if tRepuForceInfo and tRepuLevelInfo then
            local szText = FormatString(g_tStrings.STR_LEARN_NEED_REPUT_BUY,
                    UIHelper.GBKToUTF8(tRepuForceInfo.szName), UIHelper.GBKToUTF8(tRepuLevelInfo.szName))
            szText = string.gsub(szText, "\n", "")

            if aShopInfo.bSatisfy then
                szTip = szTip .. string.format(FONT_SATISFY, szText)
            else
                szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
            end
        end
    end

    if aShopInfo.nRequireAchievementRecord and aShopInfo.nRequireAchievementRecord > 0 then
        local szText = FormatString(g_tStrings.STR_NEED_ACHIVEMENT_RECORD_BUY, aShopInfo.nRequireAchievementRecord)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bSatisfyAchievementRecord then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    -- if aShopInfo.bLimit then
    --     --全服限量
    --     if aShopInfo.bCustomLimit then
    --         local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_CUSTOM_LIMT, aShopInfo.nGobalLimitCount)
    --         if aShopInfo.nBuyCount >= aShopInfo.nGlobalLimt then
    --             szTip = szTip .. string.format(FONT_NOT_SATISFY, szLimit)
    --         else
    --             szTip = szTip .. string.format(FONT_SATISFY, szLimit)
    --         end
    --     else
    --         local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_LIMT, aShopInfo.nBuyCount, aShopInfo.nGlobalLimt)
    --         if aShopInfo.nBuyCount >= aShopInfo.nGlobalLimt then
    --             szTip = szTip .. string.format(FONT_NOT_SATISFY, szLimit)
    --         else
    --             szTip = szTip .. string.format(FONT_SATISFY, szLimit)
    --         end
    --     end
    -- end

    -- if aShopInfo.nPlayerBuyCount >= 0 then
    --     --个人限量
    --     local szLimit = FormatString(g_tStrings.SHOP_ITEM_PLAYER_LIMT, aShopInfo.nPlayerBuyCount, aShopInfo.nPlayerLimit)
    --     if aShopInfo.nPlayerBuyCount >= aShopInfo.nPlayerLimit then
    --         szTip = szTip .. string.format(FONT_NOT_SATISFY, szLimit)
    --     else
    --         szTip = szTip .. string.format(FONT_SATISFY, szLimit)
    --     end
    -- end

    if aShopInfo.nCampTitle and aShopInfo.nCampTitle > 0 then
        local szTitleLevel = FormatString(g_tStrings.STR_CAMP_TITLE_LEVEL, g_tStrings.STR_CAMP_TITLE_NUMBER[aShopInfo.nCampTitle])
        local szText = FormatString(g_tStrings.STR_NEED_CAMP_TITLE_BUY, szTitleLevel)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bShareCampTitle then
            szText = FormatString(g_tStrings.STR_SHARE_CAMP_TITLE_BUY, szTitleLevel)
            szText = string.gsub(szText, "\n", "")
            szTip = szTip .. string.format(CAMP_SHARD, szText)
        elseif aShopInfo.bSatisfyCampTitle then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    if aShopInfo.nRequireCorpsValue and aShopInfo.nRequireCorpsValue > 0 then
        local dwMask = aShopInfo.dwMaskCorpsNeedToCheck % (2 ^ ARENA_TYPE.ARENA_END)
        local szCorpsText = nil
        for i = ARENA_TYPE.ARENA_END - 1, ARENA_TYPE.ARENA_BEGIN, -1 do
            if dwMask >= 2 ^ i then
                if szCorpsText then
                    szCorpsText = g_tStrings.tCorpsType[i] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
                else
                    szCorpsText = g_tStrings.tCorpsType[i]
                end

                dwMask = dwMask - 2 ^ i;
            end
        end

        local szText = FormatString(g_tStrings.STR_NEED_COPRS_VALUE_BUY, szCorpsText, aShopInfo.nRequireCorpsValue)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bSatisfyCorpsValue then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    if aShopInfo.nRequireArenaLevel and aShopInfo.nRequireArenaLevel > 0 then
        local szCorpsText = nil
        for i = #tRequireArenaLevel, 1, -1 do
            local nType = tRequireArenaLevel[i]
            if szCorpsText then
                szCorpsText = g_tStrings.tCorpsType[nType] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
            else
                szCorpsText = g_tStrings.tCorpsType[nType]
            end
        end

        local szText = FormatString(g_tStrings.STR_NEED_ARENA_LEVEL_BUY, szCorpsText, aShopInfo.nRequireArenaLevel)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bSatisfyArenaLevel then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    if aShopInfo.nRequireArenaLevelExcept2v2 and aShopInfo.nRequireArenaLevelExcept2v2 > 0 then
        local szCorpsText = nil
        for i = #tRequireExcept2v2, 1, -1 do
            local nType = tRequireExcept2v2[i]
            if szCorpsText then
                szCorpsText = g_tStrings.tCorpsType[i] .. g_tStrings.TIP_COMMAND_OR .. szCorpsText
            else
                szCorpsText = g_tStrings.tCorpsType[i]
            end
        end

        local szText = FormatString(g_tStrings.STR_NEED_ARENA_LEVEL_BUY, szCorpsText, aShopInfo.nRequireArenaLevelExcept2v2)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bSatisfyArenaLevelE2v2 then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    if aShopInfo.bNeedFame then
        local szName = Table_GetFameName(aShopInfo.nFameID)
        szName = UIHelper.GBKToUTF8(szName)
        local szText = FormatString(g_tStrings.STR_SHOP_NEED_FAME, szName, aShopInfo.nFameNeedLevel)
        szText = string.gsub(szText, "\n", "")
        if aShopInfo.bFameSatisfy then
            szTip = szTip .. string.format(FONT_SATISFY, szText)
        else
            szTip = szTip .. string.format(FONT_NOT_SATISFY, szText)
        end
    end

    return szTip
end

local function GetShopShared(item)
    local szTip = ""
    if item.bCanShared then
        if item.nGenre == ITEM_GENRE.EQUIPMENT then
            szTip = GetFormatText(g_tStrings.STR_EQUIP_SHARE, 198)
        else
            -- szTip = GetFormatText(g_tStrings.STR_ITEM_SHARE, 198)   可以分享的物品现在UIItemTips中有统一显示
        end
    end
    return szTip
end

function ShopData.GetShopBuyLimitTips(aShopInfo)
    local szTips = ""
    if not aShopInfo then return szTips end

    if aShopInfo.bLimit then
        --全服限量
        if aShopInfo.bCustomLimit then
            local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_CUSTOM_LIMT, aShopInfo.nGobalLimitCount)
            szTips = szTips..szLimit
        else
            local szLimit = FormatString(g_tStrings.SHOP_ITEM_GLOBAL_LIMT, aShopInfo.nBuyCount, aShopInfo.nGlobalLimt)
            szTips = szTips..szLimit
        end
    end
    if aShopInfo.nPlayerBuyCount >= 0 then
        if szTips ~= "" then szTips = szTips.."\n" end
        --个人限量
        local szLimit = FormatString(g_tStrings.SHOP_ITEM_PLAYER_LIMT, aShopInfo.nPlayerBuyCount, aShopInfo.nPlayerLimit)
        szTips = szTips..szLimit
    end
    return szTips
end

function ShopData.GetShopReturnItemLeftTimeTips(item)
    local szTip = ""
    local nLeftTime = ItemData.GetReturnItemLeftTime(item)
    if nLeftTime > 0 then
        local szLeftTime = UIHelper.GetDeltaTimeText(nLeftTime, false)
        szTip = string.format(g_tStrings.Shop.STR_RETURN_LTIME, szLeftTime)
    end
    return szTip
end

function ShopData.TrimLineBreak(szContent)
    local tStrings = string.split(szContent, '\n')
    local nStrCount = 0
    szContent = ""
    for nIndex, str in ipairs(tStrings) do
        if #str > 0 then
            if nStrCount == 0 then
                szContent = szContent..str
            else
                szContent = szContent..'\n'..str
            end
            nStrCount = nStrCount + 1
        end
    end

    return szContent
end

function ShopData.GenerateShopInfo(nNpcID, nShopID, dwPlayerRemoteDataID, tbGoods)
    local aShopInfo = {}
    if not nNpcID then
        return
    end
    local tShopInfo = GetShop(nShopID)
	if not tShopInfo then
		return
	end

    if not tbGoods then
        return
    end

    local nBuyCount = 1
    local player = GetClientPlayer()
    local bNeedGray,_ = ShopData.CheckNeedGray(nNpcID, nShopID, tbGoods, 1)

    local item,bItem = ShopData.GetItemByGoods(tbGoods)
    if not bItem or not item then
        return
    end
    local tbShopItemInfo
    if type(tbGoods.nShopID) == "number" then
        tbShopItemInfo = GetShopItemInfo(tbGoods.nShopID, tbGoods.dwShopIndex)
        if tbShopItemInfo and tbShopItemInfo.nBeginSellTime > 0 then
            if tbShopItemInfo.nBeginSellTime > os.time() then
                bNeedGray = true
            end
        end
    end

    -- 数量堆叠
    local nStackCount = -1
    local nLimitCount = -1
    local nGobalLimitCount = -1
    local nPlayerBuyCount = -1
    local nPlayerLeftCount = -1
    local bGlobalLimit = false
    local bPlayerLimit = false
    local bNeedShowStackCount = true
    local bBackBackAdvanced = tbGoods.nShopID == 'BUY_BACK_ADVANCED'
    if tbGoods.nShopID == 'BUY_BACK' or tbGoods.nShopID == 'BUY_BACK_ADVANCED' then
        if item.bCanStack then
            nStackCount = item.nStackNum
        end
    else
        -- 限量
        nGobalLimitCount = GetShopItemCount(tbGoods.nShopID, tbGoods.dwShopIndex) --全服限量
        bGlobalLimit = nGobalLimitCount >= 0
        nLimitCount = nGobalLimitCount
        if tbShopItemInfo.nPlayerRemoteDataPos >= 0 then
            nPlayerBuyCount = player.GetRemoteArrayUInt(dwPlayerRemoteDataID, tbShopItemInfo.nPlayerRemoteDataPos, tbShopItemInfo.nPlayerRemoteDataLength)
            nPlayerLeftCount = tbShopItemInfo.nPlayerBuyLimit - nPlayerBuyCount
            if nGobalLimitCount >= 0 and nPlayerLeftCount then --钟琰需求：商店限量和个人限购同时存在时，道具左下角显示商店限量，个人限购通过购买报错来提示玩家。
                nLimitCount = nGobalLimitCount
            else
                nLimitCount = nPlayerLeftCount
            end
            bPlayerLimit = true
        end

        -- 堆叠
        if item.bCanStack then
            if bItem and nStackCount < 0 then
                if tbGoods.bCustomShop then
                    nStackCount = tbShopItemInfo.nDurability
                else
                    nStackCount = item.nCurrentDurability
                end
            end
            nStackCount = nStackCount or 1
            if item.nGenre == ITEM_GENRE.BOOK or nStackCount < 0 then
                bNeedShowStackCount = false
            end
        end
    end
    -- 价格
    if nStackCount > 0 and type(tbGoods.nShopID) == "number" then
        nStackCount = nBuyCount * nStackCount
    end

    -- 能不能购买
    local bReputeLimit = false
    if tbShopItemInfo and item and bItem then
        local bReputeLimit = false
        local player = GetClientPlayer()
        local nReputeLevel = GetShopItemReputeLevel(tbGoods.nShopID, tbGoods.dwShopIndex)
        local dwForceID = tShopInfo.dwRequireForceID
        if nNpcID > 0 then
            local npc = GetNpc(nNpcID)
            dwForceID = npc.dwForceID
        end

        local nPlayerReputeLevel = player.GetReputeLevel(dwForceID)
        if nPlayerReputeLevel < nReputeLevel then
            bReputeLimit = true
        end
        aShopInfo = {
            bSatisfy            = not bReputeLimit  ,
            dwNeedLevel         = nReputeLevel      ,
            dwNeedForce         = dwForceID         ,
            dwPlayerReputeLevel = nPlayerReputeLevel,
            bLimit              = bGlobalLimit ,
            bCustomLimit 		= tbShopItemInfo.nLimit ~= -1 and tbGoods.bCustomShop,
            nGobalLimitCount  	= nGobalLimitCount,
            nBuyCount           = tbShopItemInfo.nLimit - nGobalLimitCount,
            nGlobalLimt         = tbShopItemInfo.nLimit,
            nPlayerLimit        = tbShopItemInfo.nPlayerBuyLimit,
            nPlayerBuyCount     = nPlayerBuyCount,
            nPlayerLeftCount    = nPlayerLeftCount,
            nFameID             = tbGoods.nFameID,
            bNeedFame           = tbGoods.bNeedFame,
            bFameSatisfy        = tbGoods.bFameSatisfy,
            nFameNeedLevel      = tbGoods.nFameNeedLevel,
        }
    end

    local bSatisfy = true
    local player = GetClientPlayer()
    local nRequireAchievementRecord = nStackCount * tbShopItemInfo.nRequireAchievementRecord
    if nRequireAchievementRecord and nRequireAchievementRecord > 0 then
        aShopInfo.nRequireAchievementRecord = nRequireAchievementRecord
        aShopInfo.bSatisfyAchievementRecord = nRequireAchievementRecord <= player.GetAchievementRecord()
        bSatisfy = bSatisfy and aShopInfo.bSatisfyAchievementRecord
    end
    local nCampTitle = tbShopItemInfo.nRequireTitle
    if nCampTitle and nCampTitle > 0 then
		aShopInfo.nCampTitle = nCampTitle
		aShopInfo.bSatisfyCampTitle = nCampTitle <= player.nTitle
        bSatisfy = bSatisfy and aShopInfo.bSatisfyCampTitle
    end
    local nRequireCorpsValue = tbShopItemInfo.nRequireCorpsValue
    local dwMaskCorpsNeedToCheck = tbShopItemInfo.dwMaskCorpsNeedToCheck
    if nRequireCorpsValue and nRequireCorpsValue > 0 then
		aShopInfo.nRequireCorpsValue = nRequireCorpsValue
		aShopInfo.dwMaskCorpsNeedToCheck = dwMaskCorpsNeedToCheck
		aShopInfo.bSatisfyCorpsValue = false

		local dwMask = dwMaskCorpsNeedToCheck % (2 ^ ARENA_UI_TYPE.ARENA_END)
		for i = ARENA_UI_TYPE.ARENA_END - 1, ARENA_UI_TYPE.ARENA_BEGIN, -1 do
			if dwMask >= 2 ^ i then
				local nCorpsLevel = player.GetCorpsLevel(i)
				local nCorpsRoleLevel = player.GetCorpsRoleLevel(i)
				if nRequireCorpsValue <= nCorpsLevel and nRequireCorpsValue <= nCorpsRoleLevel then
					aShopInfo.bSatisfyCorpsValue = true
					break
				end
				dwMask = dwMask - 2 ^ i;
			end
		end
        bSatisfy = bSatisfy and aShopInfo.bSatisfyCorpsValue
    end
    local nRequireArenaLevel = tbShopItemInfo.nRequireArenaLevel
    if nRequireArenaLevel and nRequireArenaLevel > 0 then
		local level  = nRequireArenaLevel
		aShopInfo.nRequireArenaLevel = level
		if player.nArenaLevel2v2 >= level or player.nArenaLevel3v3 >= level or player.nArenaLevel5v5 >= level then
			aShopInfo.bSatisfyArenaLevel = true
		end
        bSatisfy = bSatisfy and aShopInfo.bSatisfyArenaLevel
	end
    local nRequireArenaLevelExcept2v2 = tbShopItemInfo.nRequireArenaLevelExcept2v2
    if nRequireArenaLevelExcept2v2 and nRequireArenaLevelExcept2v2 > 0 then
		local level  = nRequireArenaLevelExcept2v2
		aShopInfo.nRequireArenaLevelExcept2v2 = level
		if player.nArenaLevel3v3 >= level or player.nArenaLevel5v5 >= level then
			aShopInfo.bSatisfyArenaLevelE2v2 = true
		end
        bSatisfy = bSatisfy and aShopInfo.bSatisfyArenaLevelE2v2
	end
    local nBeginSellTime = tbShopItemInfo.nBeginSellTime
    if nBeginSellTime and nBeginSellTime > 0 then
        aShopInfo.nBeginSellTime = nBeginSellTime
    end

    return aShopInfo
end

function ShopData.GetShopTip(szTip, aShopInfo, item, bHaveCmp)
    local szStartTime = GetBuyItemStartTime(aShopInfo)
    if szStartTime then
        szTip = szTip .. szStartTime
    end

    if aShopInfo then
        szTip = szTip .. GetShopBuyInfoTip(aShopInfo)
    end

    if not item then
        return szTip
    end
    --szTip = szTip .. GetShopShared(item) -- 分享信息现在在UITips里面有统一tips

    szTip = ShopData.TrimLineBreak(szTip)
    return szTip
end

function ShopData.GetItemInfoByGoods(goods)
    return GetItemInfo(goods.nItemType, goods.nItemIndex)
end

function ShopData.GetItemByGoods(goods)
    if not goods then
        return
    elseif goods.nShopID == 'BUY_BACK' then
        return ItemData.GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.SOLD_LIST, goods.dwShopIndex), true
    elseif goods.nShopID == 'BUY_BACK_ADVANCED' then
        return ItemData.GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, goods.dwShopIndex), true
    else
        local dwItemID = GetShopItemID(goods.nShopID, goods.dwShopIndex)
        if dwItemID == 0 then
            return GetItemInfo(goods.nItemType, goods.nItemIndex), false
        end

        local item = GetItem(dwItemID)
        --第一次加载商店，商店物品还没创建，取不到信息
        if item then
            return item, true
        else
            return GetItemInfo(goods.nItemType, goods.nItemIndex), false
        end
    end
end

function ShopData.GetItemNameByGoods(goods)
    local KItem, bItem = ShopData.GetItemByGoods(goods)
    local szName
    if bItem then
        szName = ShopData.GetItemNameByItem(KItem)
    elseif KItem then
        szName = ItemData.GetItemNameByItemInfo(KItem, (GetShopItemInfo(goods.nShopID, goods.dwShopIndex) or EMPTY_TABLE).nDurability)
    end
    return szName or ""
end

function ShopData.GetItemNameByItem(item)
    if item.nGenre == ITEM_GENRE.BOOK then
        local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
        return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
    else
        return Table_GetItemName(item.nUiId)
    end
end

function ShopData.GetGoodsPrice(nNpcID, nShopID, goods)
    local tPrice

    if goods.nShopID == 'BUY_BACK' then
        local nPrice = GetShopItemSellPrice(nShopID, INVENTORY_INDEX.SOLD_LIST, goods.dwShopIndex)
        tPrice = FormatMoneyTab(nPrice)
    elseif goods.nShopID == 'BUY_BACK_ADVANCED' then
        local nPrice = GetShopItemSellPrice(nShopID, INVENTORY_INDEX.TIME_LIMIT_SOLD_LIST, goods.dwShopIndex)
        tPrice = FormatMoneyTab(nPrice)
    else
        tPrice = GetShopItemBuyPrice(goods.nShopID, goods.dwShopIndex)
    end

    return tPrice
end

function ShopData.CanBuyGoods(nNpcID, goods, nCount)
    if goods.nShopID == 'BUY_BACK' or goods.nShopID == 'BUY_BACK_ADVANCED' then
        return true
    else
        if goods.bNeedFame and not goods.bFameSatisfy then
            return false
        end
        local item, bItem = ShopData.GetItemByGoods(goods)
        if not item then
            return false
        end
        local nRetCode = CanMultiBuyItem(nNpcID, goods.nShopID, goods.dwShopIndex, nCount)
        return nRetCode == SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS
    end
end

function ShopData.CheckNeedGray(nNpcID, nShopID, goods, nCount)
	local bNeedGray = false
	local player = GetClientPlayer()
	local tPrice = ShopData.GetGoodsPrice(nNpcID, nShopID, goods)
    tPrice = MoneyOptMult(tPrice, nCount)
	local tbCurMoney = player.GetMoney()
    local bMoneyNotEnough = MoneyOptCmp(tPrice, tbCurMoney) > 0
	if not ShopData.CanBuyGoods(nNpcID, goods, nCount) or bMoneyNotEnough then
		bNeedGray = true
	end

	return bNeedGray, bMoneyNotEnough
end

function ShopData.CheckCurrencySatisfy(nPrice, otherInfo, tbShopItemInfo, nStackCount)
    if not nStackCount or nStackCount <= 0 then
        nStackCount = 1
    end
    local player = GetClientPlayer()
	local tbCurMoney = player.GetMoney()
	local nCurMoney = ItemData.MoneyFromGoldSilverAndCopper(0, tbCurMoney.nGold, tbCurMoney.nSilver, tbCurMoney.nCopper)
    if nPrice > nCurMoney then
        return false
    end
    if not otherInfo then
        return true
    end
    if otherInfo.nPrestige > player.nCurrentPrestige then
        return false
    end
    if otherInfo.nJustice > player.nJustice then
        return false
    end
    if otherInfo.nExamPrint > player.nExamPrint then
        return false
    end
    if otherInfo.nArenaAward > player.nArenaAward then
        return false
    end
    if otherInfo.nActivityAward > player.nActivityAward then
        return false
    end
    if otherInfo.nAchievementPoint > player.GetAchievementPoint() then
        return false
    end
    if otherInfo.nContribution > player.nContribution then
        return false
    end
    if otherInfo.nMentorAward > player.nMentorAward then
        return false
    end
    if otherInfo.nTongFund > GetTongClient().GetFundTodayRemainCanUse() then
        return false
    end
    if otherInfo.nArchitecture > player.nArchitecture then
        return false
    end

    if tbShopItemInfo then
        local nRequireAmount = nStackCount*tbShopItemInfo.nRequireAmount
        local dwTabType = otherInfo.dwTabType
        local dwIndex = otherInfo.dwIndex
        if dwTabType and dwTabType > 0 and dwIndex and dwIndex > 0 and nRequireAmount and nRequireAmount > 0 then
            if player.GetItemAmount(dwTabType, dwIndex) < nRequireAmount then
                return false
            end
        end
    end

    return true
end

function ShopData.CheckConditionSatisfy(aShopInfo)
    if not aShopInfo then
        return true
    end
    if aShopInfo.dwNeedLevel > 3 then
        local tRepuForceInfo = Table_GetReputationForceInfo(aShopInfo.dwNeedForce)
        local tRepuLevelInfo = Table_GetReputationLevelInfo(aShopInfo.dwNeedLevel)
        if tRepuForceInfo and tRepuLevelInfo then
            return false
        end
    end

    if aShopInfo.nRequireAchievementRecord and aShopInfo.nRequireAchievementRecord > 0 then
        return false
    end

    if aShopInfo.bLimit then
        --全服限量
        return false
    end

    if aShopInfo.nPlayerBuyCount >= 0 then
        --个人限量
        return false
    end

    if aShopInfo.nCampTitle and aShopInfo.nCampTitle > 0 then
        return false
    end

    if aShopInfo.nRequireCorpsValue and aShopInfo.nRequireCorpsValue > 0 then
        return false
    end

    if aShopInfo.nRequireArenaLevel and aShopInfo.nRequireArenaLevel > 0 then
        return false
    end

    if aShopInfo.nRequireArenaLevelExcept2v2 and aShopInfo.nRequireArenaLevelExcept2v2 > 0 then
        return false
    end

    if aShopInfo.bNeedFame then
        return false
    end
    return true
end

function ShopData.GetCurrencyCount(nPrice, tOtherInfo, nStackCount)
    local nCount = 0
    local nBrics,nGold,nSilver,nCopper = ItemData.GoldSilverAndCopperFromMoney(nPrice*nStackCount)
    local fCalcFunc = function (nTarget)
        if nTarget > 0 then
            nCount = nCount + 1
        end
    end
    fCalcFunc(nBrics)
    fCalcFunc(nGold)
    fCalcFunc(nSilver)
    fCalcFunc(nCopper)

    if tOtherInfo then
        fCalcFunc(tOtherInfo.nPrestige)
        fCalcFunc(tOtherInfo.nContribution)
        fCalcFunc(tOtherInfo.nTongFund)
        fCalcFunc(tOtherInfo.nJustice)
        fCalcFunc(tOtherInfo.nExamPrint)
        fCalcFunc(tOtherInfo.nArenaAward)
        fCalcFunc(tOtherInfo.nActivityAward)
        fCalcFunc(tOtherInfo.nMentorAward)
        fCalcFunc(tOtherInfo.nArchitecture)
        fCalcFunc(tOtherInfo.nCoin)
        fCalcFunc(tOtherInfo.dwTabType)
    end

    return nCount
end

function ShopData.GetItemNameWithColor(dwItemID, dwItemTabType, dwItemTabIndex, szDefault)
    local item, bItem
    if dwItemID then
        bItem = true
        item = GetItem(dwItemID)
    end

    if not item and dwItemTabType and dwItemTabIndex then
        bItem = false
        item = GetItemInfo(dwItemTabType, dwItemTabIndex)
    end

    if not item then
        return szDefault
    end
    local szName = szDefault
    if bItem then
        szName = ItemData.GetItemNameByItem(item)
    else
        szName = ItemData.GetItemNameByItemInfo(item)
    end
    szName = UIHelper.GBKToUTF8(szName)
    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    return szName, nDiamondR, nDiamondG, nDiamondB, bItem
end

function ShopData.GetPriceRichText(nBrics, nGold, nSilver, nCopper)
    local szMoney = ""
    if nBrics and nBrics > 0 then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='30' height='30'/>", nBrics)
    end
    if nGold and nGold > 0 then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='30' height='30'/>", nGold)
    end
    if nSilver and nSilver > 0 then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin' width='30' height='30'/>", nSilver)
    end
    if nCopper and nCopper > 0 then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='30' height='30'/>", nCopper)
    elseif szMoney == "" then
        szMoney = szMoney .. string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='30' height='30'/>", 0)
    end

    return szMoney
end

function ShopData.GetPlayerName(dwPlayerID, szDefaultName)
    local operatorPlayer = GetPlayer(dwPlayerID)
    local szOperatePlayerName = szDefaultName
    if operatorPlayer then
        szOperatePlayerName = UIHelper.GBKToUTF8(operatorPlayer.szName)
    end

    return szOperatePlayerName
end

function GetItemQualityCaption(nQuality, bText)
    local szText = ''
    if nQuality then
        if nQuality == 0 then
            szText = g_tStrings.STR_GRAY
        elseif nQuality == 1 then
            szText = g_tStrings.STR_WHITE
        elseif nQuality == 2 then
            szText = g_tStrings.STR_GREEN
        elseif nQuality == 3 then
            szText = g_tStrings.STR_BLUE
        elseif nQuality == 4 then
            szText = g_tStrings.STR_PURPLE
        elseif nQuality == 5 then
            szText = g_tStrings.NACARAT
        elseif nQuality == 6 then
            szText = g_tStrings.STR_GLODEN
        end
    end
    if bText then
        local r, g, b = GetItemFontColorByQuality(nQuality)
        szText = GetFormatText(szText, nil, r, g, b)
    end
    return szText
end

function GetItemFontColorByQuality(nQuality, bText)
    local r, g, b = 0xB6, 0XD4, 0XDC
    if nQuality then
        if nQuality == 1 then
            r, g, b = 0XFF, 0XFF, 0XFF
        elseif nQuality == 2 then
            r, g, b = 0X70, 0XFF, 0XBB
        elseif nQuality == 3 then
            r, g, b = 0XAB, 0XEE, 0XFF
        elseif nQuality == 4 then
            r, g, b = 0XFF, 0XC4, 0XF6
        elseif nQuality == 5 then
            r, g, b = 0XFF, 0XCF, 0X65
        end
    end
    if bText then
        return " r=" .. r .. " g=" .. g .. " b=" .. b .. " "
    end
    return r, g, b
end

function GetStringCharCountAndTopChars(str, topCharNum)
    local lenInByte = #str
    local charCount = 0
    local i = 1
    local szTopChars = ""
    while (i <= lenInByte)
    do
        local curByte = string.byte(str, i)
        local byteCount = 1;
        if curByte > 0 and curByte <= 127 then
            byteCount = 1                                               --1字节字符
        elseif curByte >= 192 and curByte <= 223 then
            byteCount = 2                                               --双字节字符
        elseif curByte >= 224 and curByte <= 239 then
            byteCount = 3                                               --汉字
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4                                               --4字节字符
        end

        local char = string.sub(str, i, i + byteCount - 1)
        if charCount<topCharNum then
            szTopChars = szTopChars..char
        end
        i = i + byteCount                                               -- 重置下一字节的索引
        charCount = charCount + 1                                       -- 字符的个数（长度）
    end
    return charCount, szTopChars
end

function GetStringCharCount(str)
    local lenInByte = #str
    local charCount = 0
    local i = 1
    while (i <= lenInByte)
    do
        local curByte = string.byte(str, i)
        local byteCount = GetCharByteCount(curByte)

        i = i + byteCount                                               -- 重置下一字节的索引
        charCount = charCount + 1                                       -- 字符的个数（长度）
    end
    return charCount
end

function GetCharByteCount(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    end

    return 1
end

function UTF8SubString(str, nStartIndex, nLength)
    local subStr, _ = GetUTF8SubStringAndEndIndex(str, nStartIndex, nLength)
    return subStr
end

function GetUTF8SubStringAndEndIndex(str, nStartIndex, nLength)
    local startIndex = 1
    while nStartIndex > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + GetCharByteCount(char)
        nStartIndex = nStartIndex - 1
    end

    local currentIndex = startIndex

    while nLength > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + GetCharByteCount(char)
        nLength = nLength -1
    end
    return str:sub(startIndex, currentIndex - 1), currentIndex - 1
end

function GetUTF8SubStringList(str, nLength)
    local tSubStringList = {}
    local nStartIndex = 1
    local nTotalLength = GetStringCharCount(str)
    while nStartIndex <= nTotalLength do
        local szSubString, _ = GetUTF8SubStringAndEndIndex(str, nStartIndex, nLength)
        table.insert(tSubStringList, szSubString)
        nStartIndex = nStartIndex + nLength
    end
    return tSubStringList
end

-- cocos 目前不兼容 <text>text= xxx r=255 g=255 b=255 </text>
-- 暂时改成当前兼容的richText颜色格式
function GetFormatText(szText, nFont, nR, nG, nB, nEvent, szScript, szName, dwUserData, szLinkInfo, nFontAlpha, w, h, nHAlign, nVAlign, nPosType)
    if nR == nil or nG == nil or nB == nil then
        return szText
    end
    return string.format("<color=#%02X%02X%02X>%s</c>", nR, nG, nB, szText)
    --local t = {}
    --t[#t + 1] = m_tString[1]
    --t[#t + 1] = szText
    --if nFont then
    --	if type(nFont) == "string" then
    --		t[#t + 1] =  nFont
    --	else
    --		t[#t + 1] = " font="
    --		t[#t + 1] = nFont
    --	end
    --end
    --
    --if nFontAlpha then
    --	t[#t + 1] = " Alpha="
    --	t[#t + 1] = nFontAlpha
    --end
    --
    --if nR and nG and nB then
    --	t[#t + 1] = " r="
    --	t[#t + 1] = nR
    --	t[#t + 1] = " g="
    --	t[#t + 1] = nG
    --	t[#t + 1] = " b="
    --	t[#t + 1] = nB
    --end
    --
    --if nEvent then
    --	t[#t + 1] = " eventid="
    --	t[#t + 1] = nEvent
    --end
    --
    --if szScript then
    --	t[#t + 1] = " script="
    --	t[#t + 1] = szScript
    --end
    --
    --if szName then
    --	t[#t + 1] = " name="
    --	t[#t + 1] = szName
    --end
    --
    --if dwUserData then
    --	t[#t + 1] = " userdata="
    --	t[#t + 1] = dwUserData
    --end
    --
    --if szLinkInfo then
    --	t[#t + 1] = " link="
    --	t[#t + 1] = szLinkInfo
    --end
    --
    --if w and h then
    --	t[#t + 1] = " w="
    --	t[#t + 1] = w
    --	t[#t + 1] = " h="
    --	t[#t + 1] = h
    --end
    --
    --if nHAlign then
    --	t[#t + 1] = " halign="
    --	t[#t + 1] = nHAlign
    --end
    --
    --if nVAlign then
    --	t[#t + 1] = " valign="
    --	t[#t + 1] = nVAlign
    --end
    --
    --if nPosType then
    --	t[#t + 1] = " postype="
    --	t[#t + 1] = nPosType
    --end
    --
    --t[#t + 1] = m_tString[2]
    --return tconcat(t)
end


function ShopData.GetCurrencyCodeToType(code)
    if not ShopData.tbCurrencyCodeToType then
        ShopData.tbCurrencyCodeToType = {
            [ShopData.CurrencyCode.Default] = CurrencyType.GangFunds,
            [ShopData.CurrencyCode.Coin] = CurrencyType.Coin,
            [ShopData.CurrencyCode.Prestige] = CurrencyType.Prestige,
            [ShopData.CurrencyCode.Justice] = CurrencyType.Justice,
            [ShopData.CurrencyCode.Architecture] = CurrencyType.Architecture,
            [ShopData.CurrencyCode.TongFund] = CurrencyType.GangFunds,
            [ShopData.CurrencyCode.ArenaCoin] = CurrencyType.Prestige,
            [ShopData.CurrencyCode.MentorValue] = CurrencyType.MentorAward,
            [ShopData.CurrencyCode.Contribution] = CurrencyType.Contribution,
            [ShopData.CurrencyCode.ExamPrint] = CurrencyType.ExamPrint,
            [ShopData.CurrencyCode.WeekPoints] = CurrencyType.WeekAward,
            [ShopData.CurrencyCode.SeasonHonorXiuXian] = CurrencyType.SeasonHonorXiuXian,
            [ShopData.CurrencyCode.SeasonHonorMiJing] = CurrencyType.SeasonHonorMiJing,
            [ShopData.CurrencyCode.SeasonHonorPVP] = CurrencyType.SeasonHonorPVP,
        }
    end
    return ShopData.tbCurrencyCodeToType[code]
end

function ShopData.ShortcutOpenSystemShop()
    if UIMgr.IsViewOpened(VIEW_ID.PanelEquipStore) then
        UIMgr.Close(VIEW_ID.PanelEquipStore)
    else
        ShopData.OpenSystemShopGroup(1)
    end
end

function CheckSystemShopCanShow(tInfo, nCamp)
	local bShow = true
	local szMsg = ""
	if tInfo.dwActivityID and tInfo.dwActivityID > 0 then
		if not GetActivityMgrClient().IsActivityOn(tInfo.dwActivityID) or UI_IsActivityOn(tInfo.dwActivityID) == false then
			bShow = false
			szMsg = g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_ACTIVITY
		end
	end
	if tInfo.nCamp > 0 and nCamp > 0 and tInfo.nCamp ~= nCamp then
		bShow = false
		szMsg = g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_CAMP
	end

	return bShow, szMsg
end

local OPEN_SYSTEM_SHOP_MIN_LEVEL = 108
function ShopData.OpenSystemShopGroup(dwGroupID, dwDefaultShopID, dwTabType, dwIndex, nNeedCount, bEquipSet)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

    if pPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        TipsHelper.ShowImportantRedTip(g_tStrings.ASP_PLAYER_IS_DEAD)
		return
    end

	local dwMapID = pPlayer.GetMapID()
    local _, nMapType = GetMapParams(dwMapID)
	if Table_IsSystemShopBanMapID(dwMapID) then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_MAP)
		return
	end
	if pPlayer.bFightState then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_FIGHT)
		return
	end
	if pPlayer.bSprintFlag then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_SPRINT)
		return
	end
	if pPlayer.nLevel < OPEN_SYSTEM_SHOP_MIN_LEVEL then
        local szLimit = string.format(g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_LEVEL, OPEN_SYSTEM_SHOP_MIN_LEVEL)
        TipsHelper.ShowImportantRedTip(szLimit)
		return
	end
    if nMapType == MAP_TYPE.BATTLE_FIELD then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_MAP)
		return
	end
	local nCamp = pPlayer.nCamp
	local tSystemShopInfo = Table_GetSystemShopGroup(dwGroupID) or {}
    if dwDefaultShopID then
		local tShop = Table_GetSystemShopByID(dwGroupID, dwDefaultShopID)
		if not tShop then
            TipsHelper.ShowImportantRedTip("无法打开目标商店")
			return
		end

		local bShow, szMsg = CheckSystemShopCanShow(tShop, nCamp)
		if not bShow then
			TipsHelper.ShowImportantRedTip(szMsg)
			return
		end
	end

	for i, tGroup in ipairs(tSystemShopInfo) do
		for ii, tClass in ipairs(tGroup) do
			for iii, tInfo in ipairs(tClass) do
				if tInfo.nCamp > 0 and nCamp > 0 and tInfo.nCamp ~= nCamp then
					tInfo.bShow = false
				else
					tInfo.bShow = true
				end

				if dwDefaultShopID and dwDefaultShopID == tInfo.nShopID then
					if tInfo.nCamp > 0 and nCamp > 0 and tInfo.nCamp ~= nCamp then
						OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SYSTEM_SHOP_CANT_OPEN_IN_CAMP)
						return
					end
				end
			end
		end
	end

    TipsHelper.DeleteAllHoverTips()
    if not dwDefaultShopID then
        if UIMgr.GetView(VIEW_ID.PanelEquipStore) then
            UIMgr.CloseWithCallBack(VIEW_ID.PanelEquipStore, function ()
                UIMgr.Open(VIEW_ID.PanelEquipStore, tSystemShopInfo)
            end)
        else
            UIMgr.Open(VIEW_ID.PanelEquipStore, tSystemShopInfo)
        end
    else
        for _, tGroup in ipairs(tSystemShopInfo) do
            for nClassID, tClass in ipairs(tGroup) do
                for _, tShop in ipairs(tClass) do
                    if tShop.bShow and dwDefaultShopID == tShop.nShopID then
                        tGroup.nDefaultClassID = nClassID
                        tGroup.nDefaultShopID = tShop.nShopID
                        tGroup.dwDefaultTabType = dwTabType
                        tGroup.dwDefaultIndex = dwIndex
                        tGroup.bEquipSet = bEquipSet
                        tGroup.nNeedCount = nNeedCount

                        if UIMgr.GetView(VIEW_ID.PanelPlayStore) then
                            UIMgr.CloseWithCallBack(VIEW_ID.PanelPlayStore, function()
                                UIMgr.Open(VIEW_ID.PanelPlayStore, 0, tGroup, tSystemShopInfo.nFullScreen)
                            end)
                        else
                            UIMgr.Open(VIEW_ID.PanelPlayStore, 0, tGroup, tSystemShopInfo.nFullScreen)
                        end
                        return
                    end
                end
            end
        end
    end
end

function ShopData.OnSourceOpenSystemShop(szLinkArg)
    local tStrList = string.split(szLinkArg, "/") or {}
    if #tStrList == 4 then
        szLinkArg = szLinkArg .. "/0"
    end
    local szGroupID, szShopID, szItemType, szItemIndex, szNeedCount = szLinkArg:match("(%w+)/(%w+)/(%w+)/(%w+)/(%w+)")
    local nGroupID = tonumber(szGroupID)
    local nShopID = tonumber(szShopID)
    local nItemType = tonumber(szItemType)
    local nItemIndex = tonumber(szItemIndex)
    local nNeedCount = tonumber(szNeedCount)
    if nNeedCount == 0 then nNeedCount = nil end

    local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page)
    if nTopViewID == VIEW_ID.PanelPlayStore then
        UIMgr.CloseWithCallBack(VIEW_ID.PanelPlayStore, function ()
            --可重复跳转
            ShopData.OpenSystemShopGroup(nGroupID, nShopID, nItemType, nItemIndex, nNeedCount)
        end)
        return
    end

    ShopData.OpenSystemShopGroup(nGroupID, nShopID, nItemType, nItemIndex, nNeedCount)
end

-- 重定位到牌子商店
function ShopData.RedirectToSetShop(dwTabType, dwIndex)
    ShopData.OpenSystemShopGroup(1, ShopData.dwEqupSetShopID, dwTabType, dwIndex, 0, true)
end

function ShopData.IsMobileKungFu(dwKungfuID)
    local nMobileID = GetMobileKungfuID(dwKungfuID)
    local nHDID = ShopData.GetHDKungfuID(dwKungfuID)
    return nMobileID == 0 and nHDID > 0
end

-- 遍历查询耗时太长，这里做个缓存优化一下速度
function ShopData.GetHDKungfuID(dwKungfuID)
    if not ShopData.BD2HDMap then
        ShopData.BD2HDMap = {}
    end
    local dwHDID = ShopData.BD2HDMap[dwKungfuID]
    if not dwHDID then
        dwHDID = GetHDKungfuID(dwKungfuID)
        ShopData.BD2HDMap[dwKungfuID] = dwHDID
    end

    return dwHDID
end

function ShopData.BuyItem(nNpcID, nShopID, dwShopIndex, nBuyCount)
    ShopData.nLastBuyTime = os.time()
    BuyItem(nNpcID, nShopID, dwShopIndex, nBuyCount)
end

function ShopData.InBuyCD()
    return ShopData.nLastBuyTime and (ShopData.nLastBuyTime + ShopData.MAX_WAIT_TIME > os.time())
end
-- tItemList = {
--    [1] = {dwTabType = 5, dwIndex = 10086, nBookID = 25},
--    [2] = {dwTabType = 5, dwIndex = 10087},
-- }
function ShopData.ForceToppingBagItem(tItemList)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPlayStore)
    if not scriptView then return end
    scriptView:ForceToppingBagItem(tItemList)
end

function ShopData.TryShowRedPoint()
    local tSystemShopInfo = Table_GetSystemShopGroup(1) or {}
    for _, tGroup in ipairs(tSystemShopInfo) do
        local szGroupName = GBKToUTF8(tGroup.szGroupName or "")
        if szGroupName == "活动" then
            for nClassID, tClass in ipairs(tGroup) do
                for nIndex, tInfo in ipairs(tClass) do
                    -- 由于切换分类首项都会自动选中，所以首项不给红点
                    if RedpointHelper.SystemShop_HasRedPoint(tInfo.nShopID) == nil then
                        RedpointHelper.SystemShop_SetNew(tInfo.nShopID, true)
                    end
                end
            end
        end
    end
end

Event.Reg(ShopData, EventType.OnClientPlayerEnter, function ()
    ShopData.TryShowRedPoint()
end)