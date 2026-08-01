RedpoingConditions = RedpoingConditions or {}



-- 红点 ID = 1 红点测试
function RedpoingConditions.Excute_1(nID)
    return false
end

-- 红点 ID = 2 密聊
function RedpoingConditions.Excute_2(nID)
    local bResult, nLen = ChatRecentMgr.HasNewMsgRedPoint()
    return bResult, nLen
end

-- 红点 ID = 3 聊天表情
function RedpoingConditions.Excute_3(nID)
    local bResult, nLen = RedpointHelper.ChatEmotion_HasRedPoint()
    return bResult, nLen
end

-- 红点 ID = 4 离线消息
function RedpoingConditions.Excute_4(nID)
    local bResult = ChatRecentMgr.HasOffLineMsgRedPoint()
    return bResult
end

-- 红点 ID = 5 队伍频道红点
function RedpoingConditions.Excute_5(nID)
    local nCount = ChatHintMgr.GetCountByUIChannel(UI_Chat_Channel.Team)
    return nCount > 0, nCount
end

-- 红点 ID = 6 帮会频道红点
function RedpoingConditions.Excute_6(nID)
    local nCount = ChatHintMgr.GetCountByUIChannel(UI_Chat_Channel.Tong)
    return nCount > 0, nCount
end

-- 红点 ID = 7 侠缘频道红点
function RedpoingConditions.Excute_7(nID)
    local bResult = ChatAINpcMgr.HasUnRead()
    return bResult, 0
end

-- 红点 ID = 1001 花萼楼
function RedpoingConditions.Excute_1001(nID)
    local bResult = false

    -- 提审没有红点
    if AppReviewMgr.IsReview() then
        return false, 0
    end

    if g_pClientPlayer and g_pClientPlayer.nLevel < 102 then
        return false
    end

    bResult = HuaELouData.GetAllOperatActRedPoint()

    return bResult, 1
end

-- 红点 ID = 1101 挂饰秘鉴-挂件
function RedpoingConditions.Excute_1101(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    return RedpointHelper.Pendant_HasRedpoint()
end

-- 红点 ID = 1102 挂饰秘鉴-特效
function RedpoingConditions.Excute_1102(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    return RedpointHelper.Effect_HasRedpoint()
end

-- 红点 ID = 1103 挂饰秘鉴-小头像
function RedpoingConditions.Excute_1103(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    return RedpointHelper.Avatar_HasNew()
end

-- 红点 ID = 1104 挂饰秘鉴-待机动作
function RedpoingConditions.Excute_1104(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    return RedpointHelper.IdleAction_HasRedpoint()
end

-- 红点 ID = 1105 挂饰秘鉴-武技殊影
function RedpoingConditions.Excute_1105(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    return RedpointHelper.SkillSkin_HasRedpoint()
end

-- 红点 ID = 1201 公告-更新日志
function RedpoingConditions.Excute_1201(nID)
    return RedpointHelper.Bulletin_HasRedpoint(BulletinType.UpdateLog)
end

-- 红点 ID = 1202 公告-游戏公告
function RedpoingConditions.Excute_1202(nID)
    return RedpointHelper.Bulletin_HasRedpoint(BulletinType.Announcement)
end

-- 红点 ID = 1203 公告-系统公告
function RedpoingConditions.Excute_1203(nID)
    return RedpointHelper.Bulletin_HasRedpoint(BulletinType.System)
end

-- 红点 ID = 1204 公告-充值返还
function RedpoingConditions.Excute_1204(nID)
    return RedpointHelper.Bulletin_HasRedpoint(BulletinType.Recharge)
end

-- 红点 ID = 1205 公告-技改公告
function RedpoingConditions.Excute_1205(nID)
    return RedpointHelper.Bulletin_HasRedpoint(BulletinType.SkillUpdate)
end

-- 红点 ID = 1301 公告-获得称号
function RedpoingConditions.Excute_1301(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PersonalTitle) then
        return false
    end
    return RedpointHelper.PersonalTitle_HasRedpoint()
end

-- 红点 ID = 1401 坐骑-普通坐骑
function RedpoingConditions.Excute_1401(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Horse) then
        return false
    end
    return RedpointHelper.Horse_Ride_HasRedPoint()
end

-- 红点 ID = 1402 坐骑-奇趣坐骑
function RedpoingConditions.Excute_1402(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Horse) then
        return false
    end
    return RedpointHelper.Horse_Qiqu_HasRedPoint()
end

-- 红点 ID = 1501 宠物
function RedpoingConditions.Excute_1501(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PetMap) then
        return false
    end
    return RedpointHelper.Pet_HasRedPoint()
end

-- 红点 ID = 1601 玩具箱
function RedpoingConditions.Excute_1601(nID)
    return RedpointHelper.ToyBox_HasRedPoint()
end

-- 红点 ID = 1602 表情动作
function RedpoingConditions.Excute_1602(nID)
    return RedpointHelper.Emotion_HasRedPoint()
end

-- 红点 ID = 1603 头顶表情
function RedpoingConditions.Excute_1603(nID)
    return RedpointHelper.BrightMark_HasRedPoint()
end

-- 红点 ID = 1701 主界面右上角-气泡消息
function RedpoingConditions.Excute_1701(nID)
    return BubbleMsgData.GetHasRedPoint()
end

-- 红点 ID = 1801 行记-入口
function RedpoingConditions.Excute_1801(nID)
    local bResult = false

    bResult = RedpoingConditions.Excute_2801()

    if bResult == false then
        bResult = RedpoingConditions.Excute_2802()
    end

    return bResult, 1
end

-- 红点 ID = 1901 武学面板-未装备秘籍
function RedpoingConditions.Excute_1901()
    return RedpointHelper.PanelSkill_HasRedPoint()
end

-- 红点 ID = 1902 武学面板-推荐面板
function RedpoingConditions.Excute_1902()
    return RedpointHelper.PanelSkill_IsRecommendNew()
end

-- 红点 ID = 1903 武学推荐-秘境
function RedpoingConditions.Excute_1903()
    return RedpointHelper.PanelSkill_ShowApplyButtonRedPoint()
end

-- 红点 ID = 1904 武学推荐-竞技
function RedpoingConditions.Excute_1904()
    return RedpointHelper.PanelSkill_ShowApplyButtonRedPoint(true)
end

-- 红点 ID = 1905 流派提示
function RedpoingConditions.Excute_1905()
    return RedpointHelper.PanelSkill_IsLiuPaiKungFuNew()
end

-- 红点 ID = 2001 商城-福袋
function RedpoingConditions.Excute_2001(nID)
    local bResult = false
    local tAllPool = Table_GetPointsDrawAllPoolInfo()
    for i, tLine in ipairs(tAllPool) do
        local nIndex = tLine.nIndex
        local bOnTime = CoinShopData.IsDrawPoolOnTime(nIndex)
        local tDrawSettings = GetCoinShopDraw().GetDrawSettings(nIndex)
        local tInfo = Storage.CoinShop.tbPointsDrawPoolInfo[i]
        if bOnTime and (not tInfo or tInfo.nStartTime ~= tDrawSettings.nStartTime or tInfo.nEndTime ~= tDrawSettings.nEndTime) then
            bResult = true
            break
        end
    end
    return bResult, 1
end

-- 红点 ID = 2002 商城-优惠券
function RedpoingConditions.Excute_2002(nID)
    local bResult = false
    local tList = CoinShopData.GetNewWelfares()
    bResult = tList and #tList > 0
    return bResult, 1
end

-- 红点 ID = 2003 商城-保管
function RedpoingConditions.Excute_2003(nID)
    local bResult = false
    local nCount = CoinShopData.StorageCount()
    bResult = nCount > 0
    return bResult, 1
end

-- 红点 ID = 2004 商城-福利返还
function RedpoingConditions.Excute_2004(nID)
    local bResult = false
    local tWelfareList = GetInnerChargeCache().GetAvailableInnerChargeInfo()
    bResult = tWelfareList and #tWelfareList > 0
    return bResult, 1
end

function RedpoingConditions.Excute_2007(nID)
    local bResult = false
    bResult = bResult or RedpointHelper.Pendant_HasRedpoint()
    bResult = bResult or RedpointHelper.Exterior_HasRedpoint()
    bResult = bResult or RedpointHelper.WeaponExterior_HasRedpoint()
    bResult = bResult or RedpointHelper.PendantPet_HasRedpoint()
    bResult = bResult or RedpointHelper.Hair_HasRedpoint()
    bResult = bResult or RedpointHelper.Face_HasRedpoint()
    bResult = bResult or RedpointHelper.Body_HasRedpoint()
    bResult = bResult or RedpointHelper.IdleAction_HasRedpoint()
    return bResult, 1
end

function RedpoingConditions.Excute_2008(nID)
    local bResult = false
    bResult = RedpointHelper.CoinShop_Has0YuanGou()
    return bResult, 1
end

function RedpoingConditions.Excute_2101(nID)
    local bResult = false
    local nApplyCount = TeamBuilding.GetApplyCount()
    bResult = nApplyCount and nApplyCount > 0
    return bResult, 1
end

function RedpoingConditions.Excute_2201(nID)
    local bResult = false
    bResult = WulintongjianDate.GetDLCRewardRedPoint()

    return bResult, 1
end

function RedpoingConditions.Excute_2301(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Email) then
        return false
    end
    local bResult = false

    local unReadMail = GetMailClient().GetMailList("unread") or {}
    local nUnReadCount = #(unReadMail)

    bResult = nUnReadCount and nUnReadCount > 0
    return bResult, nUnReadCount
end

--签到
function RedpoingConditions.Excute_2401(nID)
    local bResult = false

    if g_pClientPlayer and g_pClientPlayer.nLevel >= 14 and not g_pClientPlayer.bContinuousLoginRewardFlag then
        bResult = true
    end

    return bResult, 1
end

--花萼楼119活动 多段签到
function RedpoingConditions.Excute_2402(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(119)

    return bResult, 1
end

--花萼楼月度冲消
function RedpoingConditions.Excute_2403(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.CHARGE_MONTHLY)

    return bResult, 1
end

--花萼楼赛季展望
function RedpoingConditions.Excute_2404(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.SEASON_DISTANCE)

    return bResult, 1
end

--花萼楼活动48
function RedpoingConditions.Excute_2405(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(48) or
    HuaELouData.GetOperatActRedPoint(156)

    return bResult, 1
end

--花萼楼回归活动
function RedpoingConditions.Excute_2406(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.SEASON_RETURN)

    return bResult, 1
end

--花萼楼活动154
function RedpoingConditions.Excute_2407(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(154)

    return bResult, 1
end

--花萼楼活动86
function RedpoingConditions.Excute_2408(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(86)

    return bResult, 1
end

--花萼楼活动72
function RedpoingConditions.Excute_2409(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(72)

    return bResult, 1
end

--花萼楼活动157
function RedpoingConditions.Excute_2410(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(157)

    return bResult, 1
end

--花萼楼活动160
function RedpoingConditions.Excute_2411(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(160)

    return bResult, 1
end

--花萼楼活动155
function RedpoingConditions.Excute_2412(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(155)

    return bResult, 1
end

--花萼楼活动165
function RedpoingConditions.Excute_2413(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(165)

    return bResult, 1
end

--花萼楼168活动 多段签到
function RedpoingConditions.Excute_2414(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(168)

    return bResult, 1
end

--花萼楼2活动 充值返利
function RedpoingConditions.Excute_2415(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.ANNIVERSARY_FEEDBACK)

    return bResult, 1
end

--花萼楼105活动
function RedpoingConditions.Excute_2416(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(105)

    return bResult, 1
end

--花萼楼169活动
function RedpoingConditions.Excute_2417(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(169)

    return bResult, 1
end

--花萼楼120活动
function RedpoingConditions.Excute_2418(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(120)

    return bResult, 1
end

--花萼楼4活动
function RedpoingConditions.Excute_2419(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.DOUBLE_ELEVEN_LOTTERY)

    return bResult, 1
end

--花萼楼103活动
function RedpoingConditions.Excute_2420(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(180)

    return bResult, 1
end

--花萼楼180活动
function RedpoingConditions.Excute_2421(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(103)

    return bResult, 1
end

--花萼楼185活动
function RedpoingConditions.Excute_2422(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(185)

    return bResult, 1
end

--花萼楼187活动
function RedpoingConditions.Excute_2423(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(187)

    return bResult, 1
end

--花萼楼186活动
function RedpoingConditions.Excute_2424(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(186)

    return bResult, 1
end

--花萼楼188活动
function RedpoingConditions.Excute_2425(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(188)

    return bResult, 1
end

--花萼楼91活动
function RedpoingConditions.Excute_2426(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(91)

    return bResult, 1
end

--花萼楼40活动
function RedpoingConditions.Excute_2427(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(40)

    return bResult, 1
end

--花萼楼196活动
function RedpoingConditions.Excute_2428(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(196)

    return bResult, 1
end

--花萼楼198活动
function RedpoingConditions.Excute_2429(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(198)

    return bResult, 1
end

--花萼楼90活动
function RedpoingConditions.Excute_2430(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(90)

    return bResult, 1
end

--花萼楼199活动
function RedpoingConditions.Excute_2431(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(199)

    return bResult, 1
end

--花萼楼204活动
function RedpoingConditions.Excute_2432(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(204)

    return bResult, 1
end

--花萼楼203活动
function RedpoingConditions.Excute_2433(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(203)

    return bResult, 1
end

--花萼楼209活动
function RedpoingConditions.Excute_2434(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(209)

    return bResult, 1
end

--花萼楼211活动
function RedpoingConditions.Excute_2435(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(211)

    return bResult, 1
end

--花萼楼213活动
function RedpoingConditions.Excute_2436(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(213)

    return bResult, 1
end

--花萼楼214活动
function RedpoingConditions.Excute_2437(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(214)

    return bResult, 1
end

--花萼楼215活动
function RedpoingConditions.Excute_2438(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(215)

    return bResult, 1
end

--花萼楼218活动
function RedpoingConditions.Excute_2439(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(218)

    return bResult, 1
end

--花萼楼219活动
function RedpoingConditions.Excute_2440(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(219)

    return bResult, 1
end

--花萼楼220活动
function RedpoingConditions.Excute_2441(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(220)

    return bResult, 1
end

--花萼楼221活动
function RedpoingConditions.Excute_2442(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(221)

    return bResult, 1
end

function RedpoingConditions.Excute_2443(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.WELCOME_NEWBIE_SIGNIN)

    return bResult, 1
end

function RedpoingConditions.Excute_2444(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.WELCOME_BACK_SIGNIN)

    return bResult, 1
end

function RedpoingConditions.Excute_2445(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.FRIENDS_RECRUIT)

    return bResult, 1
end

function RedpoingConditions.Excute_2446(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(OPERACT_ID.GUIDE_PERSON_MENGXIN)

    return bResult, 1
end

function RedpoingConditions.Excute_2447(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(250)

    return bResult, 1
end

function RedpoingConditions.Excute_2448(nID)
    local bResult = false

    bResult = HuaELouData.GetOperatActRedPoint(251)

    return bResult, 1
end

--阵营排行奖励
function RedpoingConditions.Excute_2501(nID)
    local bResult = false

    local tbRewardInfo = CampData.GetTitlePointRankRewardInfo()

    return tbRewardInfo and tbRewardInfo.Receive, 1
end

function RedpoingConditions.Excute_2502(nID)
    local player = GetClientPlayer()
    if not player then
        return false
    end

    return RedpointHelper.PanelCamp_IsLevelNew()
end

--竞技场解锁
function RedpoingConditions.Excute_2601(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PvPArena) then
        return false
    end
    return RedpointHelper.Arena_HasRedPoint()
end

--日课奖励
function RedpoingConditions.Excute_2701(nID)
    return CollectionDailyData.CanGetReward()
end

--周课奖励
function RedpoingConditions.Excute_2703(nID)
    return CollectionDailyData.CanGetWeekReward()
end

--荣誉挑战
function RedpoingConditions.Excute_2702(nID)
    return CollectionData.AllTaskHasCanGet() or CollectionData.AllChallengeRewardHasCanGet()
end

--赛季段位-每日
function RedpoingConditions.Excute_2704(nID)
    local tRankList = CollectionDailyData.GetRankList()
    
    for i = 1, 3 do
        local tRank = tRankList[i]
		if not tRank then
			return
		end

        local nClass = tRank.nClass
        if CollectionData.SeasonLevelHasCanGet(nClass) then
            return true
        end
    end
end

--赛季段位-秘境
function RedpoingConditions.Excute_2705(nID)
    return CollectionData.SeasonLevelHasCanGet(1)
end

--赛季段位-阵营
function RedpoingConditions.Excute_2706(nID)
    return CollectionData.SeasonLevelHasCanGet(2)
end

--赛季段位-竞技
function RedpoingConditions.Excute_2707(nID)
    return CollectionData.SeasonLevelHasCanGet(3) or CollectionData.SeasonLevelHasCanGet(4) or CollectionData.SeasonLevelHasCanGet(5)
end

--赛季段位-休闲
function RedpoingConditions.Excute_2708(nID)
    return CollectionData.SeasonLevelHasCanGet(6) or CollectionData.SeasonLevelHasCanGet(7)
end

--荣誉挑战-坐骑
function RedpoingConditions.Excute_2709(nID)
    return CollectionData.CheckAllChallengeHorseRedDot()
end

--行记-首充
function RedpoingConditions.Excute_2801(nID)
    local bResult = false

    bResult = not AppReviewMgr.IsReview() and HuaELouData.bFirstChargeRewardCanDo and HuaELouData.GetOperatActRedPoint(OPERACT_ID.REAL_FIRST_CHARGE)

    return bResult, 1
end

--行记-江湖行记
function RedpoingConditions.Excute_2802(nID)
    local bResult = false

    if SystemOpen.IsSystemOpen(SystemOpenDef.JiangHuXingJiBP) then
        bResult = HuaELouData.GetBattlePassRedPoint()
    end

    return bResult, 1
end

--小橙武升级活动
function RedpoingConditions.Excute_2901(nID)
    local bResult = false

    bResult =  g_pClientPlayer.nLevel == 120 and not APIHelper.IsDid("OrangeWeaponUpg.Open")
    or ShenBingUpgradeMgr.CheckUpgrade()

    return bResult, 1
end

--帮会-申请列表
function RedpoingConditions.Excute_3001(nID)
    local bResult = false

    if SystemOpen.IsSystemOpen(SystemOpenDef.Tong) then
        bResult = TongData.HasApplyRedPoint()
    end

    return bResult, 1
end

--花萼楼赛季展望-战力篇
function RedpoingConditions.Excute_3101(nID)
    local bResult = false

    bResult = HuaELouData.GetSeasonDistancePvxRedPoint()

    return bResult, 1
end

--花萼楼赛季展望-家园篇
function RedpoingConditions.Excute_3102(nID)
    local bResult = false

    bResult = HuaELouData.GetSeasonDistanceHomelandRedPoint()

    return bResult, 1
end

-- 校服裂变活动
function RedpoingConditions.Excute_2006(nID)
    return RedpointHelper.CoinShopSchool_HasRedPoint()
end

-- 教程盒子
function RedpoingConditions.Excute_3201(nID)
    return RedpointHelper.TeachBox_IsNew()
end

-- 师徒-菜单入口
function RedpoingConditions.Excute_3301(nID)
    local bResult = false

    bResult = FellowshipData.GetAppremticeRedpoint()
    or FellowshipData.GetMentorRedpoint()

    return bResult, 1
end

-- 师徒-拜师成功
function RedpoingConditions.Excute_3302(nID)
    local bResult = false

    bResult = FellowshipData.GetMentorRedpoint()

    return bResult, 1
end

-- 师徒-收徒成功
function RedpoingConditions.Excute_3303(nID)
    local bResult = false

    bResult = FellowshipData.GetAppremticeRedpoint()

    return bResult, 1
end

-- 界面自定义
function RedpoingConditions.Excute_3401(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.MainCityCustom) then
        return false
    end
    return RedpointHelper.MainCityCustom_IsNew()
end


-- 名剑段位奖励
function RedpoingConditions.Excute_3501(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PvPArena) then
        return false
    end
    return RedpointHelper.ArenaLevelReward_HasRedPoint(ARENA_UI_TYPE.ARENA_2V2)
end

function RedpoingConditions.Excute_3502(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PvPArena) then
        return false
    end
    return RedpointHelper.ArenaLevelReward_HasRedPoint(ARENA_UI_TYPE.ARENA_3V3)
end

function RedpoingConditions.Excute_3503(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.PvPArena) then
        return false
    end
    return RedpointHelper.ArenaLevelReward_HasRedPoint(ARENA_UI_TYPE.ARENA_5V5)
end

-- 寻宝模式领奖
function RedpoingConditions.Excute_3504(nID)
    return RedpointHelper.ExtractReward_HasRedPoint()
end

-- 红点 ID = 3601 日历活动
function RedpoingConditions.Excute_3601(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint()
end

-- 红点 ID = 3602 日历收藏活动
function RedpoingConditions.Excute_3602(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.LIKE)
end

-- 红点 ID = 3603 日历休闲活动
function RedpoingConditions.Excute_3603(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.RELAX)
end

-- 红点 ID = 3604 日历协作活动
function RedpoingConditions.Excute_3604(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.TEAM)
end

-- 红点 ID = 3605 日历对抗活动
function RedpoingConditions.Excute_3605(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.CONFRONT)
end

-- 红点 ID = 3606 日历家园活动
function RedpoingConditions.Excute_3606(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.HOME)
end

-- 红点 ID = 3607 日历往事活动
function RedpoingConditions.Excute_3607(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.ActivityCalendar) then
        return false
    end
    return RedpointHelper.Activity_HasRedPoint(ACTIVITY_TYPE.HISTORY)
end

--红尘侠影-是否可领取今日茶饼
function RedpoingConditions.Excute_3701(nID)
    local bResult = false

    local bDailyTeaTaken = PartnerData.IfGetHeroDailyTea()
    bResult = not bDailyTeaTaken

    return bResult, 1
end

--红尘侠影-侠客出行是否有可领取的奖励
function RedpoingConditions.Excute_3702(nID)
    local bResult = false

    bResult = PartnerData.PartnerTravel_IsAnySlotInState(PartnerTravelState.Finished)

    return bResult, 1
end

function RedpoingConditions.Excute_3608(nID)
    return BahuangData.IsShowRedPoint()
end

--家园-是否可升级
function RedpoingConditions.Excute_3801(nID)
    local bResult = false

    local dwCurrMapID, nCurrCopyIndex, nCurrLandIndex = HomelandBuildData.GetMapInfo()
    local tbLandInfo = GetHomelandMgr().GetLandInfo(dwCurrMapID, nCurrCopyIndex, nCurrLandIndex)
    if not tbLandInfo then
		return bResult
	end

    local nLevel = tbLandInfo.nLevel
	local tbConfig = GetHomelandMgr().GetLevelUpConfig(nLevel)
    if not tbConfig then
        return bResult
    end

    local player = GetClientPlayer()
    if not player then
        return bResult
    end

    local nScore = player.GetHomelandRecord()
    if nScore >= tbConfig.Record and tbConfig.Currency > 0 and player.nArchitecture >= tbConfig.Currency then
        bResult = true
    end

    -- local bTodayShow = APIHelper.IsDidToday("RedPointExcute_3801")
    -- bResult = not bTodayShow and bResult

    return bResult
end

--家园-总览是否可领取活跃奖励
function RedpoingConditions.Excute_3802(nID)
    local bResult = false

    local pHomelandMgr  = GetHomelandMgr()
    if not pHomelandMgr then
        return bResult
    end

    local tTemp = pHomelandMgr.GetAllMyLand()
    if not tTemp then
        return bResult
    end

    local nCommunityCount = 0
    for i = 1, #tTemp do
        if not tTemp[i].bPrivateLand then
            nCommunityCount = nCommunityCount + 1
        end
    end

    local tData = GDAPI_GetHomelandOverviewInfo(nCommunityCount > 0)
    if not tData then
        return bResult
    end

    bResult = tData.bCanRequestReward

    return bResult
end

--家园-庐园广记可领取套装奖励
function RedpoingConditions.Excute_3803(nID)
    local bResult = false

    bResult = HomelandData.IsFurnitureSetCanAward()
    return bResult
end

--家园-结庐江湖可领奖
function RedpoingConditions.Excute_3804(nID)
    local bResult = false
	local pPlayer = GetClientPlayer()
    if not pPlayer then
        return bResult
    end

    local tFurnitureSet = Homeland_GetFurnitureSet()
    local tUSetID = tFurnitureSet[1]
	for i = 1, 9, 1 do
		local eType = pPlayer.GetSetCollection(tUSetID[i]).eType
		if eType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
			bResult = true
			break
		end
	end

    return bResult
end

--家园-新日志消息提醒
function RedpoingConditions.Excute_3805(nID)
    local bResult = false

    bResult = HomelandData.IsNewHomelandLog()
    return bResult
end

function RedpoingConditions.Excute_3901(nID)
    local bResult = false

    for _, szInfoType in pairs(TraceInfoType) do
        if RedpointHelper.TraceInfo_HasRedPoint(szInfoType) then
            bResult = true
            break
        end
    end

    return bResult, 1
end

--预约-逐鹿中原
function RedpoingConditions.Excute_4001(nID)
    local bResult = false

    bResult = RedpointHelper.MapAppointment_HasRedPoint(941)

    return bResult, 1
end

--预约-阵营攻防
function RedpoingConditions.Excute_4002(nID)
    local bResult = false

    bResult = RedpointHelper.MapAppointment_HasRedPoint(942) or RedpointHelper.MapAppointment_HasRedPoint(943)

    return bResult, 1
end

--系统菜单商店红点，暂时屏蔽
function RedpoingConditions.Excute_4101(nID)
    local bResult = false

   -- bResult = RedpointHelper.SystemShop_HasRedPoint()

    return bResult
end

--系统菜单剑侠录红点
function RedpoingConditions.Excute_4201(nID)
    local bResult = false

   bResult = SwordMemoriesData.IsShowRedPoint()

    return bResult
end

--客服中心绑定微信小管家查看红点
function RedpoingConditions.Excute_4301(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.TeachBox) then
        return false
    end
    return not Storage.ServerCenter.bLookWechatGM
end

--名片生日设置红点
function RedpoingConditions.Excute_4399(nID)
    if not SystemOpen.IsSystemOpen(SystemOpenDef.Accessory) then
        return false
    end
    local tData = GDAPI_GetBirthDayData()
    local bSetted = false
    if tData.nMonth and tData.nDay and tData.nMonth > 0 and tData.nDay > 0 then
        bSetted = true
    end
    if bSetted == true then
        Storage.Birthday.bShowRedPoint = false
        Storage.Birthday.Dirty()
    end
    return Storage.Birthday.bShowRedPoint
end

function RedpoingConditions.Excute_4401(nID)
    if HuaELouData.CheackActivityOpen(238) then
        return not Storage.HuaELou.bClickTask_LangFengXuanCheng
    end

    return false
end