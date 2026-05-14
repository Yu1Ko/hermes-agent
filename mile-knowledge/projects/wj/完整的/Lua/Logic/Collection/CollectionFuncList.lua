-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CollectionFuncList
-- Date: 2024-01-30 19:29:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

CollectionFuncList = CollectionFuncList or {className = "CollectionFuncList"}
local self = CollectionFuncList
-------------------------------- 消息定义 --------------------------------
CollectionFuncList.Event = {}
CollectionFuncList.Event.XXX = "CollectionFuncList.Msg.XXX"

function CollectionFuncList.Excute(szFuncName)
    if not string.is_nil(szFuncName) and self[szFuncName] then
        self[szFuncName]()
    end
end

function CollectionFuncList.GoToYTG()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 607})
end

function CollectionFuncList.GoToZHGDJ()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 599})
end

function CollectionFuncList.GoToJTYY()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 623})
end

function CollectionFuncList.GoToLYQ()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 639})
end

function CollectionFuncList.GoToWSY()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 597})
end

function CollectionFuncList.GoToQLDT()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 659})
end

function CollectionFuncList.GoToJLD()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 668})
end

function CollectionFuncList.GoToJLDPT()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 669})
end

function CollectionFuncList.GoToJLDYX()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = 670})
end

function CollectionFuncList.GoToBZYWL()
UIMgr.Open(VIEW_ID.PanelBaizhanMain)
end

function CollectionFuncList.GoToLKX()
TravellingBagData.On_LangKeXing_UiAskIn()
end

function CollectionFuncList.GoToSLZD()
CrossingData.On_NewTrial_AllpyEnter()
end

function CollectionFuncList.OpenQianLiFaZhu()
UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
end

function CollectionFuncList.OpenJDMY()
    UIMgr.Open(VIEW_ID.PanelCampMap)
end

function CollectionFuncList.OpenZLZY()
    UIMgr.Open(VIEW_ID.PanelCampMap)
end

function CollectionFuncList.OpenZYGFZ()
-- ActivityData.LinkToActiveByIDList({706, 707}, "该时间段不能参加阵营攻防战")
    -- if ActivityData.IsActivityOn(706) or UI_IsActivityOn(706) or ActivityData.IsActivityOn(707) or UI_IsActivityOn(707) then
        local script = UIMgr.Open(VIEW_ID.PanelCampMap)
        script:ShowMapSelectInfoByTime()
    -- else
    --     local script = UIHelper.ShowConfirm(g_tStrings.STR_ACTIVITY_NOT_OPEN_TIP)
    --     script:HideButton("Cancel")
    -- end
end

function CollectionFuncList.GoToSJYZC()
BattleFieldData.CheckEnterNewPlayerBF()
end

function CollectionFuncList.OpenJJC()
UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, 2)
end

function CollectionFuncList.OpenCQ()
UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, 6, true)
end

function CollectionFuncList.OpenYangDao()
UIMgr.Open(VIEW_ID.PanelYangDaoMain)
end

function CollectionFuncList.OpenBattleField()
UIMgr.Open(VIEW_ID.PanelBattleFieldInformation)
end

function CollectionFuncList.OpenImpasseMatching()
UIMgr.Open(VIEW_ID.PanelImpasseMatching, nil, 8)
end

function CollectionFuncList.OpenPvPMatching()
UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, 2)
end

function CollectionFuncList.OpenHome()
UIMgr.Open(VIEW_ID.PanelHome)
end

function CollectionFuncList.OpenHomeIdentity()
UIMgr.Open(VIEW_ID.PanelHomeIdentity)
end

function CollectionFuncList.OpenXB()
ActivityData.LinkToActiveByID(104)
if TeachEvent.CheckCondition(35) then
    TeachEvent.TeachStart(35)
end
end

function CollectionFuncList.OpenKJ()
ActivityData.LinkToActiveByIDList({196, 197, 198}, "该时间段不能参加科举")
end

function CollectionFuncList.OpenWLTJGGRW()
ActivityData.LinkToActiveByID(499)
end

function CollectionFuncList.OpenYSHD()
ActivityData.LinkToActiveByID(368)
end

function CollectionFuncList.GoToNPS()
ActivityData.LinkToActiveByID(262)
end

function CollectionFuncList.GoToKL()
ActivityData.LinkToActiveByID(263)
end

function CollectionFuncList.OpenCSMW()
ActivityData.LinkToActiveByID(855)
end

function CollectionFuncList.OpenLXXJ()
ActivityData.LinkToActiveByID(858)
end

function CollectionFuncList.OpenFHLF()
ActivityData.LinkToActiveByID(819)
end

function CollectionFuncList.OpenLDGY()
ActivityData.LinkToActiveByID(860)
end

function CollectionFuncList.OpenBHHJ()
ActivityData.LinkToActiveByID(901)
end

function CollectionFuncList.OpenSLZD()
ActivityData.LinkToActiveByID(135)
end

function CollectionFuncList.OpenMW()
UIMgr.Open(VIEW_ID.PanelFame)
end

function CollectionFuncList.OpenSHJY()
    UIMgr.Open(VIEW_ID.PanelLifeMain)
end

function CollectionFuncList.OpenWLZBS()
    UIMgr.Open(VIEW_ID.PanelFactionChampionship)
end

function CollectionFuncList.OpenMJSL()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance)
end

function CollectionFuncList.GoToCGRC()
    ActivityData.LinkToActiveByID(967)
end

function CollectionFuncList.OpenWLTJ()
    UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {bRaid = true})
end

function CollectionFuncList.OpenQXBZ()
ActivityData.LinkToActiveByID(132)
end

function CollectionFuncList.OpenMasterJJC()
    UIMgr.Close(VIEW_ID.PanelRoadCollection)
    RemoteCallToServer("On_JJC_DaShiSaiEnter")
end

function CollectionFuncList.OpenSJSL()
    UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
    if not APIHelper.IsDid("TeachWorldBoss") then
        TeachBoxData.OpenTutorialPanel(61)
        APIHelper.Do("TeachWorldBoss")
    end
end

function CollectionFuncList.OpenSwitchServer()
    UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
end

function CollectionFuncList.SheJiao1()
UIMgr.Close(VIEW_ID.PanelRoadCollection)
UIMgr.Open(VIEW_ID.PanelChatSocial, 2)
TipsHelper.ShowImportantBlueTip("侠士可添加好友完成任务")
end

function CollectionFuncList.SheJiao2()
UIMgr.Close(VIEW_ID.PanelRoadCollection)
UIMgr.Open(VIEW_ID.PanelChatSocial, 2)
TipsHelper.ShowImportantBlueTip("侠士可以点击他人头像交互信息界面查看装备完成任务")
end

function CollectionFuncList.SheJiao3()
ActivityData.LinkToActiveByID(113)
TipsHelper.ShowImportantBlueTip("侠士可前往帮会食堂吃饭或打包完成任务")
end

function CollectionFuncList.SheJiao4()
UIMgr.Open(VIEW_ID.PanelApprenticeNew)
TipsHelper.ShowImportantBlueTip("侠士可以点击师父/师徒进行召请，需一名师父或徒弟方可完成任务")
end

function CollectionFuncList.JiaYuan1()
UIMgr.Close(VIEW_ID.PanelRoadCollection)
HomelandData.OpenHomeOverviewPanel()
TipsHelper.ShowImportantBlueTip("点击【种花种菜】前往家园种植，需获取家园后方可完成任务")
-- ActivityData.LinkToActiveByID(870)
end

function CollectionFuncList.JiaYuan2()
UIMgr.Close(VIEW_ID.PanelRoadCollection)
HomelandData.OpenHomeOverviewPanel()
TipsHelper.ShowImportantBlueTip("点击【每日许愿】前往许愿树祈福，需获取家园后方可完成任务")
-- ActivityData.LinkToActiveByID(870)
end

function CollectionFuncList.JiaYuan3()
UIMgr.Open(VIEW_ID.PanelTutorialLite, 35)
TipsHelper.ShowImportantBlueTip("侠士可根据指引完成垂钓任务")
end

function CollectionFuncList.WaiGuan1()
CoinShopData.Open()
end

function CollectionFuncList.QiYuan1()
UIMgr.Open(VIEW_ID.PanelQiYu)
end

function CollectionFuncList.OpenHCXY()
UIMgr.Open(VIEW_ID.PanelPartner)
end

function CollectionFuncList.QiYuan2()
UIMgr.Open(VIEW_ID.PanelPetMap)
TipsHelper.ShowImportantBlueTip("侠士可召唤宠物完成任务")
end

function CollectionFuncList.QiYuan3()
    UIMgr.Open(VIEW_ID.PanelPartner)
end

function CollectionFuncList.JiYi1()
UIMgr.Open(VIEW_ID.PanelLifeMain)
TipsHelper.ShowImportantBlueTip("侠士可前往生活技艺-采集/制作完成任务")
end

function CollectionFuncList.JiYi2()
UIMgr.Open(VIEW_ID.PanelLifePage, {nDefaultCraftPanel = CRAFT_PANEL.Demosticate,})
TipsHelper.ShowImportantBlueTip("侠士可前往抓马或在生活技艺-驯养喂养马驹完成任务")
end

function CollectionFuncList.JiYi3()
ActivityData.LinkToActiveByID(104)
if TeachEvent.CheckCondition(35) then
    TeachEvent.TeachStart(35)
end
end

function CollectionFuncList.XiuXian1()
UIMgr.Open(VIEW_ID.PanelFame)
TipsHelper.ShowImportantBlueTip("侠士需解锁名望方可前往参与事件地图参与公共任务")
end

function CollectionFuncList.XiuXian2()
	JiangHuData.InitInfo()
	local nIndex = JiangHuData.nCurActID ~= 0 and JiangHuData.tbShowID[JiangHuData.nCurActID] or 1

	UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, nIndex)
TipsHelper.ShowImportantBlueTip("侠士请激活任意身份并完成相应玩法完成任务")
end

function CollectionFuncList.MiJing1()
TravellingBagData.On_LangKeXing_UiAskIn()
TipsHelper.ShowImportantBlueTip("侠士可在浪客行的普通或挑战模式中度过一个时辰，即可完成任务")
end

function CollectionFuncList.MiJing2()
    local scriptView = UIMgr.Open(VIEW_ID.PanelDungeonEntrance)
    if scriptView then
        TipsHelper.ShowImportantBlueTip("侠士可以击败任意秘境首领完成任务")
    end
end

function CollectionFuncList.ZhenYing1()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
         UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
	 	TipsHelper.ShowImportantBlueTip("侠士需加入阵营后方可完成阵营矿车日常任务")
    else
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
	 	TipsHelper.ShowImportantBlueTip("侠士可以前往阵营矿车日常完成任务")
    end
end

function CollectionFuncList.ZhenYing2()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
		TipsHelper.ShowImportantBlueTip("侠士需加入阵营后方可查看沙盘完成任务")
    else
        UIMgr.Open(VIEW_ID.PanelCampMap)
    end
end

function CollectionFuncList.JingJi1()
UIMgr.Open(VIEW_ID.PanelBattleFieldInformation)
TipsHelper.ShowImportantBlueTip("侠士可参加一次战场完成任务")
end

function CollectionFuncList.JingJi2()
    local scriptView = UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, 2)
    if scriptView then
        TipsHelper.ShowImportantBlueTip("侠士可参与名剑大会完成任务")
    end
end

function CollectionFuncList.JingJi3()
UIMgr.Open(VIEW_ID.PanelImpasseMatching, nil, 8)
TipsHelper.ShowImportantBlueTip("侠士可参加绝境战场完成任务")
end

function CollectionFuncList.OpenHomelandOverview()
    HomelandData.OpenHomeOverviewPanel()
    -- ActivityData.LinkToActiveByID(870)
end

function CollectionFuncList.GoToMonsterBookByTip()
UIMgr.Open(VIEW_ID.PanelBaizhanMain)
end

function CollectionFuncList.OpenFBList()
UIMgr.Open(VIEW_ID.PanelDungeonEntrance)
end

function CollectionFuncList.GoToDesertStorm()
UIMgr.Open(VIEW_ID.PanelImpasseMatching)
end

function CollectionFuncList.GoToVagabond()
TravellingBagData.On_LangKeXing_UiAskIn()
end

function CollectionFuncList.GoToJJC()
UIMgr.Open(VIEW_ID.PanelPvPMatching, nil, 2)
end

function CollectionFuncList.GoToBattleField()
UIMgr.Open(VIEW_ID.PanelBattleFieldInformation)
end

function CollectionFuncList.GoToArenaTower()
    if g_pClientPlayer and g_pClientPlayer.GetMapID() == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN then
        TipsHelper.ShowNormalTip("侠士已经在玩法地图内")
        return
    end
    UIMgr.Open(VIEW_ID.PanelYangDaoMain)
end

function CollectionFuncList.OpenCampMap()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
    else
        UIMgr.Open(VIEW_ID.PanelCampMap)
    end
end

function CollectionFuncList.OpenSwitchServer()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
    else
        UIMgr.Open(VIEW_ID.PanelCampMap)
    end
end

function CollectionFuncList.LinkWeeklyTeamDungeon()
    UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {bLinkWeeklyTeamDungeon = true})
end

function CollectionFuncList.OpenCastingPanel()
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelPowerUp)
    if not viewScript then
        UIMgr.Open(VIEW_ID.PanelPowerUp,PREFAB_ID.WidgetRefineUpgrade)
    else
        viewScript:OnEnter(PREFAB_ID.WidgetRefineUpgrade)
    end
    Event.Dispatch(EventType.HideAllHoverTips) --在强化界面内通过UIItemTips进入五行石升级玩法时，关闭侧面板
end

function CollectionFuncList.OpenPerfumePanel()
UIMgr.Open(VIEW_ID.PanelConfigurationPop)
end

function CollectionFuncList.GoToNewTrial()
    UIHelper.ShowConfirm(FormatString(g_tStrings.STR_GAME_GUIDE_CONFIRM, g_tStrings.STR_GAME_GUIDE_NEWTRIAL), function()
        local hPlayer = g_pClientPlayer
        if not hPlayer then
            return
        end

        --打坐中站起
        if hPlayer.nMoveState == MOVE_STATE.ON_SIT then
            hPlayer.Stand()
        end

        RemoteCallToServer("On_NewTrial_AllpyEnter")
    end)
end

function CollectionFuncList.OpenFurnitureCollect()
    HomelandData.OpenHomelandPanel(4)
end

function CollectionFuncList.OpenYouShangWithOverview()
    HomelandData.OpenHomeOverviewPanel()
    UIMgr.Open(VIEW_ID.PanelMerchant)
end

function CollectionFuncList.OpenSheJiZhan1()
    ShareStationData.OpenShareStation(SHARE_DATA_TYPE.FACE)
end

function CollectionFuncList.OpenSheJiZhan2()
    ShareStationData.OpenShareStation(SHARE_DATA_TYPE.BODY)
end

function CollectionFuncList.OpenSheJiZhan3()
    ShareStationData.OpenShareStation(SHARE_DATA_TYPE.EXTERIOR)
end

function CollectionFuncList.OpenRoadChivalrousPVE()
    local script = UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.SECRET)
end

function CollectionFuncList.OpenRoadChivalrousPVP1()
    local script = UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.ATHLETICS)
end

function CollectionFuncList.OpenRoadChivalrousPVP2()
    if not g_pClientPlayer then return end
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
        UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
        return
    end
    local script = UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.CAMP)
end

function CollectionFuncList.OpenRoadChivalrousPVX()
    local script = UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.REST)
end

function CollectionFuncList.OpenMailPanel()
    local script = UIMgr.Open(VIEW_ID.PanelEmail)
end

function CollectionFuncList.OpenBigBagPanel()
    local script = UIMgr.Open(VIEW_ID.PanelHalfBag)
end

function CollectionFuncList.OpenSeasonRank()
    UIMgr.Open(VIEW_ID.PanelSeasonLevel)
end

function CollectionFuncList.GotoHonorChallengePanel1()
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelSeasonChallenge)
    if not viewScript then
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.REST)
    else
        viewScript:OnEnter(HONOR_CHALLENGE_PAGE.REST)
    end
end

function CollectionFuncList.GotoHonorChallengePanel2()
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelSeasonChallenge)
    if not viewScript then
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.SECRET)
    else
        viewScript:OnEnter(HONOR_CHALLENGE_PAGE.SECRET)
    end
end

function CollectionFuncList.GotoHonorChallengePanel3()
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelSeasonChallenge)
    if not viewScript then
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.ATHLETICS)
    else
        viewScript:OnEnter(HONOR_CHALLENGE_PAGE.ATHLETICS)
    end
end

function CollectionFuncList.OpenRead()
    UIMgr.Open(VIEW_ID.PanelReadMain)
end