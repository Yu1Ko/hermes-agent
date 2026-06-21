RemoteFunction = {className = "RemoteFunction"}

local kScreenShow =
{
    ["1st"] = {nLastTime = 2000, szPath = "\\ui\\Image\\Common\\1st.tga", szType = "BIG_TO_SMALL"},
    ["2nd"] = {nLastTime = 2000, szPath = "\\ui\\Image\\Common\\2nd.tga", szType = "BIG_TO_SMALL"},
    ["3rd"] = {nLastTime = 2000, szPath = "\\ui\\Image\\Common\\3rd.tga", szType = "BIG_TO_SMALL"},

    ["Begin"]   = {nLastTime = 500, szPath = "\\ui\\Image\\Common\\number_start.tga", szType = "BIG_TO_SMALL"},
    ["Win"]   = {nLastTime = 2000, szPath = "\\ui\\Image\\UICommon\\Win.tga", szType = "BIG_TO_SMALL"},
    ["Lose"]  = {nLastTime = 2000, szPath = "\\ui\\Image\\UICommon\\Lose.tga", szType = "BIG_TO_SMALL"},
}

-- 用于过滤掉一些特殊的确认框，dx允许重复打开但是VK不允许的
local tbOldConfirmFilter = {
    -- 开个table方便以后要查对应弹窗可以blame查相关提交
    [37] = true,
    [140] = true,
}

local tbFirstCallUIRemote =
{
    ["OutputMessage"] = "GBKToUTF8_OutputMessage",
    ["PlayBgMusic"] = "PlayBgMusic",
}

-- 忽略全局函数列表
local IGNORE_GLOBAL_FUNCTION =
{
    ["fnVideoSettingEX"] = true,
    ["OnSyncAccountSafe"] = true,
}


local function concatArgs(...)
    local args = {...}
    local len = #args
    if len == 0 then
        return ""
    end

    local s = ""
    for i = 1, len do
        s = s .. tostring(args[i]) .. ' ,'
    end
    return string.sub(s, 1, #s - 2)
end

function OnRemoteCall(szFunction, ...)
    if RemoteFunction[szFunction] then
        RemoteFunction[szFunction](...)
    else
        if not IGNORE_GLOBAL_FUNCTION[szFunction] then
            LOG.ERROR(string.format("OnRemoteCall.%s not exist.", szFunction))
        end
    end
end

--教学
function Helper_ServerEvent(szName)
    FireHelpEvent("OnServerEvent", szName)
end

---------- 函数名字不得超过 31 个字母

function RemoteFunction.RegisterUIGlobalFunction(szFunction, fnCallback)
    if not szFunction then return end
    if not IsFunction(fnCallback) then return end

    UIGlobalFunction[szFunction] = fnCallback
end

function RemoteFunction.UnRegisterUIGlobalFunction(szFunction)
    UIGlobalFunction[szFunction] = nil
end

function RemoteFunction.FireUIEvent(...)
    Event.Dispatch(...)
end

---------- msg

function RemoteFunction.OnCloseWarningMessage(szWarningType)
    --CloseWarningMessage(szWarningType)
    TipsHelper.SkipCurrentImportantTips()
end

function RemoteFunction.OnOutputWarningMessage(szWarningType, szText, nTime)
    szText = ParseTextHelper.DeleteOperationDesc(GBKToUTF8(szText))
    TipsHelper.OutputMessage(szWarningType, szText, false, nTime)
end

function RemoteFunction.OnOutputWarningMessageMutiText(szWarningType,nTime ,...)
    local tText = {...}
    local szText = ""
    for i = 1,select("#",...) do
        szText = szText..tText[i]
    end
    --OutputWarningMessage(szWarningType, szText, nTime)
    szText = GBKToUTF8(szText)
    TipsHelper.OutputMessage(szWarningType, szText, false, nTime)
end

-- 音效相关
function RemoteFunction.StopBgMusic(szAnnounce, szColor)
    StopBgMusic()
    if not szColor or type(szColor) ~= "string" then
        return
    end
    szColor = szColor:lower()
    if szColor == "red" then
        OutputMessage("MSG_ANNOUNCE_RED", szAnnounce)
    elseif szColor == "yellow" then
        OutputMessage("MSG_ANNOUNCE_YELLOW", szAnnounce)
    end
end

function RemoteFunction.On_Play_Sound(nType, szPath)
    PlaySound(nType, szPath, false, 0)
end

function RemoteFunction.SetSoundRtpc(szName, fValue)
    SetSoundRtpc(szName, fValue)
end

---------------------------BGM------------------------------------
function RemoteFunction.PlayBgMusicPriority(szEvent, nPriority)
    SoundMgr.PlayBgMusicPriority(szEvent, nPriority)
end

function RemoteFunction.StopBgMusicPriority(szEvent, nPriority)
    SoundMgr.StopBgMusicPriority(szEvent, nPriority)
end

function RemoteFunction.SetSoundState(szEvent, szState)
    SoundMgr.SetSoundState(szEvent, szState)
end

function RemoteFunction.ClearBGM()
    SoundMgr.ClearBGM()
end

function RemoteFunction.RefreshBGM()
    SoundMgr.RefreshBGM()
end
---------------------------BGM------------------------------------


function RemoteFunction.On_Castle_OpenRankEntrance()
    FireUIEvent("ON_CASTLE_OPEN_RANK_ENTRANCE")
end

function RemoteFunction.On_Castle_GetFightRankRequest(tRankList, tRetCastleInfo)
    FireUIEvent("ON_CASTLE_GET_FIGHT_RANK_REQUEST", tRankList, tRetCastleInfo)
end

--某据点 争夺结束后
function RemoteFunction.On_Castle_ChangeOwner(dwCastleID)
    FireUIEvent("ON_CASTLE_CHANGE_OWNER", dwCastleID)
end

--总活动 争夺结束后
function RemoteFunction.On_Castle_ActivityEnd(tMainUIMsgInfo, tMainWarInfo, tSneakUIMsgInfo, tSneakWarInfo, bCanReceiveReward, nContribution, tMoney)
    local tWarInfo = {}
    tMainWarInfo.tUIMsgInfo    = tMainUIMsgInfo
    if tSneakWarInfo then
        tSneakWarInfo.tUIMsgInfo   = tSneakUIMsgInfo
    end
    tWarInfo.tMainWarInfo	   = tMainWarInfo
    tWarInfo.tSneakWarInfo 	   = tSneakWarInfo
    tWarInfo.tMoney 		   = tMoney
    tWarInfo.nContribution 	   = nContribution
    tWarInfo.bCanReceiveReward = bCanReceiveReward
    FireUIEvent("ON_CASTLE_END_ACTIVITY", tWarInfo)
end

--获取沙盘据点的tip信息
function RemoteFunction.On_Castle_GetCastleTipsRespond(tCastleTips, nWillResetTime, tBusinessRoute)
    FireUIEvent("ON_CASTLE_GETTIPS_RESPOND", tCastleTips, nWillResetTime, tBusinessRoute)
end

--获取进攻路线
function RemoteFunction.On_Castle_GetWarSituation(tBattleLine)
    FireUIEvent("ON_CASTLE_GET_WARSITUAION_RESPOND", tBattleLine)
end

function RemoteFunction.OpenCreateTongPanel(dwID)
    local fnCallback = function(szTongName, bCancel)
        if bCancel then return end

        -- 请求创建帮会
        -- \client\scripts\script_server.lua
        RemoteCallToServer("OnCreateTongRespond", dwID, UIHelper.UTF8ToGBK(szTongName))
    end

    PlotMgr.ClosePanel(PLOT_TYPE.OLD)
    UIMgr.Open(VIEW_ID.PanelCreationFactionPop, fnCallback)
end

function RemoteFunction.On_Tong_AddLevelProgressRespond(bLevelUp, nCostFund)
    Event.Dispatch("ON_TONG_ADD_TONGLEVEL", bLevelUp, nCostFund)
end

function RemoteFunction.GetTongWeeklyPointRespond(nWeeklyDevelopmentRemain)
    local argSave0 = arg0
    arg0 = nWeeklyDevelopmentRemain
    TongData.SetWeeklyPoint(nWeeklyDevelopmentRemain)
    Event.Dispatch("ON_GET_TONG_WEEKLY_POINT")
    arg0 = argSave0
end

function RemoteFunction.On_SyncTongCustomData(tSyncTable)
    TongData.SetCustomData(tSyncTable)
    Event.Dispatch("ON_TONG_SYNC_CUSTOMDATA")
end

function RemoteFunction.OnSendTongEvent(data1, data2)
    local as0, as1 = arg0, arg1
    arg0, arg1 = data1, data2
    Event.Dispatch("TONG_EVENT_NOTIFY")
    arg0, arg1 = as0, as1
end

function RemoteFunction.On_Tong_WarCostRespond(tDeclarationParam)
    TongData.SetDeclarationParam(tDeclarationParam)
    Event.Dispatch("ON_TONG_WAR_COST_RESPOND", tDeclarationParam)
end


function RemoteFunction.On_Tong_DeclareWarRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_DeclareCastleWarRespond(nRetCode)
	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_LaunchCWRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_AgreeCWRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_CancalCWRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_LaunchAllyRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_AgreeAllyRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_RefuseAllyRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end

function RemoteFunction.On_Tong_StopAllianceRespond(nRetCode)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tXuanRequestResult[nRetCode])
end



function RemoteFunction.OnSetTongTechTreeRespond(nNodeIndex, nValue, bResult, nError)
    Event.Dispatch("SET_TONG_TECH_TREE_RESPOND", nNodeIndex, nValue, bResult, nError)
end

function RemoteFunction.OnSetTongTechTreeByListRespond(tNodeList, bResult, nError)
    Event.Dispatch("SET_TONG_TECH_TREE_BY_LIST_RESPOND", tNodeList, bResult, nError)
end

function RemoteFunction.On_Tong_GetActivityTimeRespond(tData)
    TongData.SetActivityTimeData(tData)
    Event.Dispatch("On_Tong_GetActivityTimeRespond")
end

function RemoteFunction.OnOpenGuildListPanel(dwNpcID, bADList)
    UIMgr.Open(VIEW_ID.PanelFactionList, bADList)
end

function RemoteFunction.On_Tong_DelApplyJoin(nRetCode)
    Event.Dispatch("On_Tong_DelApplyJoin", nRetCode)
end

function RemoteFunction.On_Tong_AddTopTenRespond(nRetCode)
    if nRetCode == TONG_PUBLICITY_RESULT_CODE.COMPETITIVERANKING_SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTongAddTopTongReult[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tTongAddTopTongReult[nRetCode] .. g_tStrings.STR_FULL_STOP .. "\n")
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTongAddTopTongReult[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tTongAddTopTongReult[nRetCode] .. g_tStrings.STR_FULL_STOP .. "\n")
    end
    FireUIEvent("ON_TONG_TOP_TEN_RESPOND", nRetCode)
end

function RemoteFunction.On_Tong_GetTopTenTongList(nCount, tTongArr)
    FireUIEvent("ON_GET_TOPTEN_TONGLIST", nCount, tTongArr)
end

function RemoteFunction.On_Tong_GetADTongList(nTotalCount, nCount, tTongArr)
    LOG.INFO("====> On_Tong_GetADTongList: " .. nCount)
    FireUIEvent("ON_GET_AD_TONGLIST", nTotalCount, nCount, tTongArr)
end

function RemoteFunction.On_Tong_ApplyJoinRespond(nRetCode)
    local szChannel = "MSG_ANNOUNCE_NORMAL"
    if nRetCode == TONG_APPLY_JOININ_RESULT_CODE.SUCCESS then
        szChannel = "MSG_ANNOUNCE_NORMAL"
    end

    local szMsg = g_tStrings.tTongApplyJoininResult[nRetCode]
    if szMsg then
        OutputMessage(szChannel, szMsg)
        --OutputMessage("MSG_SYS", szMsg .. g_tStrings.STR_FULL_STOP .. "\n")
    end

    Event.Dispatch("On_Tong_ApplyJoinRespond", nRetCode)
end

function RemoteFunction.On_Tong_GetApplyJoinInList(tPlayerInfoList)
    LOG.INFO("====> On_Tong_GetApplyJoinInList: " .. #tPlayerInfoList)
    Event.Dispatch("ON_GET_APPLY_JOININ_TONGLIST", tPlayerInfoList)
end

function RemoteFunction.On_Tong_GetTopTenCost(nLastCost, nMyTongCost, nRanking)
    FireUIEvent("ON_GET_TOP_TEN_COST", nLastCost, nMyTongCost, nRanking)
end

function RemoteFunction.OnAddTongFundNotify(nFund, nAddResource)
    FireUIEvent("ON_ADD_TONG_FUND_NOTIFY", nFund, nAddResource)
end

function RemoteFunction.SetTitlePoint(nNewTitlePoint, nAddTitlePoint)
    Event.Dispatch("TITLE_POINT_UPDATE", nNewTitlePoint, nAddTitlePoint)
end

local _tTongDiplomacyRemindTypeToSubTabAndViewID = {
    -- 帮会宣战
    ["CastleWar"] = { 1, VIEW_ID.PanelBefightListPop },
    -- 帮会约战
    ["BattleInvited"] = { 2, VIEW_ID.PanelCompetitionInvitationPop },
    -- 帮会同盟
    ["Union"] = { 3, VIEW_ID.PanelLeagueInvitationPop },
}

function RemoteFunction.On_Tong_DiplomacyRemind(szParam)
    local fnOpenTongView = function ()
        ---@type UIPanelTongManager
        local script              = UIMgr.GetViewScript(VIEW_ID.PanelFactionManagement) or UIMgr.Open(VIEW_ID.PanelFactionManagement)

        local nDiplomacyMainTab   = 4
        local nSubTab, nPopViewID = table.unpack(_tTongDiplomacyRemindTypeToSubTabAndViewID[szParam])

        UIHelper.SetToggleGroupSelected(script.ToggleGroupNavigation, nDiplomacyMainTab - 1)
        UIHelper.SetToggleGroupSelected(script.ToggleGroupTab, nSubTab - 1)

        script:SwitchMainTab(nDiplomacyMainTab)
        script:SwitchSubTab(nSubTab)

        -- 并打开对应邀请信息页面
        _ = UIMgr.GetView(nPopViewID) or UIMgr.Open(nPopViewID)
    end

    TongData.RequestBaseData()
    BubbleMsgData.PushMsgWithType("TongDiplomacy", {
        szType = "TongDiplomacy", 		        -- 类型(用于排重)
        nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
        -- szTongDiplomacyRemindType = szParam,
        szAction = function ()
            fnOpenTongView()
        end,
        fnAutoClose = function()
            return table.is_empty(TongData.GetAllDiplomacyRelationList())
        end,
    })
end

-- 信用体系
function RemoteFunction.On_GetPrestigeInfo_Respond(dwPlayerID, tbInfo)
    Event.Dispatch(EventType.OnGetPrestigeInfoRespond, dwPlayerID, tbInfo)
end

function RemoteFunction.OnWillBeAddFoeNotify(szSrcName, dwSrcID, nLeftSeconds)
    local argSave0 = arg0
    local argSave1 = arg1
    local argSave2 = arg2
    arg0 = szSrcName
    arg1 = dwSrcID
    arg2 = nLeftSeconds

    if nLeftSeconds > 0 then
        Event.Dispatch(EventType.PLAYER_APPLY_BE_ADD_FOE, szSrcName, dwSrcID, nLeftSeconds)
    else
        Event.Dispatch(EventType.PLAYER_HAS_BE_ADD_FOE, szSrcName, dwSrcID, nLeftSeconds)
    end

    arg0 = argSave0
    arg1 = argSave1
    arg2 = argSave2
end

function RemoteFunction.OnWillBeAddFeudNotify(szSrcName, dwSrcID)
    Event.Dispatch(EventType.PLAYER_APPLY_BE_ADD_FEUD, szSrcName, dwSrcID)
end

function RemoteFunction.OnWillAddFoeNotify(szDestName, szDestGlobalID, nLeftSeconds)
    if nLeftSeconds > 0 then
        Event.Dispatch(EventType.PLAYER_ADD_FOE_BEGIN, szDestName, nLeftSeconds)
    else
        Event.Dispatch(EventType.PLAYER_ADD_FOE_END, szDestName, szDestGlobalID, nLeftSeconds)
    end
end

function RemoteFunction.OnPrepareAddFoeResult(nResult)
    Event.Dispatch(EventType.PREPARE_ADD_FOE_RESULT, nResult)
end

function RemoteFunction.OnAddFeudNotify(szDestName, szDestID, nLeftSeconds)
    Event.Dispatch(EventType.PLAYER_ADD_FEUD_NOTIFY, szDestName, szDestID, nLeftSeconds)
end

function RemoteFunction.OnPrepareAddFeudResult(nRetCode)
    local szMsg = g_tStrings.tFeudResult[nRetCode]
    if szMsg then
        OutputMessage("MSG_SYS", szMsg)
    end
end

function RemoteFunction.OnDeleteFeudResult(nRetCode)
    local szMsg = g_tStrings.tFeudResult[nRetCode]
    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
end

function RemoteFunction.CloseCampFlagResult(bResult, nLeftSeconds)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if bResult then
        player.nCloseCampFlagTime = 0
        if nLeftSeconds > 0 then
            local nCurrentTime = GetCurrentTime()
            player.nCloseCampFlagTime = nLeftSeconds + nCurrentTime
        end
    end

    CampData.WaitCloseCampFlag(bResult, nLeftSeconds)
end

function RemoteFunction.ShowGuildCampReverse(nCamp, nCountDownTime)
    UIMgr.Open(VIEW_ID.PanelFactionTransferConfirm, nCamp, nCountDownTime)
end

function RemoteFunction.On_Camp_CloseJoinCamp()
    UIMgr.Close(VIEW_ID.PanelPvPCampJoin)
end

function RemoteFunction.On_Camp_GetTitlePointRankInfo(tInfo)
    CampData.On_Camp_GetTitlePointRankInfo(tInfo)
end

function RemoteFunction.On_Camp_GetTitlePointRankReward(bSuccess)
    CampData.On_Camp_GetTitlePointRankReward(bSuccess)
end

function RemoteFunction.OnCampActiveInfoRespond(nWeek, dwActivityID, szInfo)
    FireUIEvent("CAMP_ACTIVE_INFO_RESOPND", nWeek, dwActivityID, szInfo)
end

function RemoteFunction.OnGetCampReverseInfo(nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
    FireUIEvent("ON_CAMP_GETCAMPREVERSEINFO", nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
end

-- TODO 这两个是啥？
-- function RemoteFunction.On_Camp_CheckWeeklyWinner(nWinner)
--     FireUIEvent("On_CAMP_CHECKWEEKLYWINNER", nWinner)
-- end
-- function RemoteFunction.On_Camp_CheckSeasonWinner(nWinner)
--     FireUIEvent("On_CAMP_CHECKSEASONWINNER", nWinner)
-- end

-- 攻防分流所有分线信息
function RemoteFunction.On_Camp_GetBranchInfo(tCastleInfo)
	FireUIEvent("On_Camp_GetBranchInfo", tCastleInfo)
end

function RemoteFunction.On_Camp_CastleFightMapList(tMapList)
	FireUIEvent("On_Camp_CastleFightMapList", tMapList)
end

function RemoteFunction.On_Can_Join_Camp(tCanJoin)
    FireUIEvent("ON_CAN_JOIN_CAMP", tCanJoin)
end

--千里伐逐界面
function RemoteFunction.On_OpenSwitchServerPanel()
    print("On_OpenSwitchServerPanel")
    --TODO
    UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
end

function RemoteFunction.On_GetRestAvailableZhanJie(nRestZhanJie)
    FireUIEvent("On_GetRestAvailableZhanJie", nRestZhanJie)
end

function RemoteFunction.OnActivityTipUpdate(dwActivityID, nTime, tValue)
    FireAddonUIEvent("ON_ACTIVITY_TIPS_UPDATE", dwActivityID, nTime, tValue)
    if dwActivityID == 26 or dwActivityID == 27 then --据点争夺的活动界面
        FireAddonUIEvent("ON_CASTLE_ACTIVITY_TIP_UPDATE", tValue)
    elseif dwActivityID == 22 then --铁血宝箱争夺活动，暂不开放了
        --FireAddonUIEvent("ON_WORLD_BOX_ACTIVITY_TIP_UPDATE", tValue[1], tValue[2])
    end
end

function RemoteFunction.OnActivityTipClose(dwActivityID)
    FireAddonUIEvent("ON_ACTIVITY_TIPS_CLOSE", dwActivityID)
end

--TODO Camp_GF是啥，帮会战吗?
--On_Camp_GFGetCastleInfo(tCastle)
--On_Camp_GFSetCommander(bCommander)
--On_Camp_GFDelMember(nRoleType)
--On_Camp_GFAssignItem(nType, tOKList, tNotMemberFail, tInDifMapFail, tOtherFail)
--On_Camp_GFAddMember(nRoleType, nLevel)
--On_Camp_GFGetCampInTong(tCampInfo)
--这是啥RemoteCallToServer("On_Camp_GFIsActivated", nActivateCount, nInterVal, nTotalSecend)
--On_Camp_OBGFGetPlayerInfo(tData)
--On_Camp_OBGFSetOB(szWarning)

function RemoteFunction.CallUIGlobalFunction(szFunction, ...)
    local proc = _G[szFunction]
    local szGlobalUIFunction = tbFirstCallUIRemote[szFunction]
    if szGlobalUIFunction and UIGlobalFunction[szGlobalUIFunction] then
        UIGlobalFunction[szGlobalUIFunction](...)
    elseif proc then
        proc(...)
        -- 临时代码
        if szFunction == "rlcmd" then
            local szCmd = ...
            if szCmd == "set env preset 1" then
                LOG.INFO("RemoteFunction Special Case: set env preset 1 enable chromatic aberration")
                KG3DEngine.SetPostRenderChromaticAberrationEnable(false)
            end
        end
    elseif UIGlobalFunction[szFunction] then
        UIGlobalFunction[szFunction](...)
    else
        if not IGNORE_GLOBAL_FUNCTION[szFunction] then
            LOG.ERROR(string.format("TODO（通用UI远程函数）: szFunction=%s args={%s}", UIHelper.GBKToUTF8(szFunction), concatArgs(...)))
        end
    end
end

function RemoteFunction.SetEnvPreset(nMapID, nPresetID)
    LOG.INFO("RemoteFunction.SetEnvPreset arrived on client nPresetID:%s, nMapID:%s", tostring(nPresetID), tostring(nMapID))

    if SceneMgr.IsLoading() and not SceneMgr.IsLoadingIsMainSubMap() then
        RemoteFunction.tbSetEnvPreset = RemoteFunction.tbSetEnvPreset or {}
        Event.Reg(RemoteFunction.tbSetEnvPreset, EventType.UILoadingFinish, function()
            Event.UnReg(RemoteFunction.tbSetEnvPreset, EventType.UILoadingFinish)
            RemoteFunction.SetEnvPreset(nMapID, nPresetID)
        end)
        LOG.INFO("RemoteFunction.SetEnvPreset client IsLoading nPresetID:%s, nMapID:%s", tostring(nPresetID), tostring(nMapID))
        return
    end

    if nMapID ~= SelfieData.GetCurrentMapID() then
        LOG.ERROR("RemoteFunction.SetEnvPreset not in current map nMapID:%s, current mapID:%s, nPresetID:%s", tostring(nMapID), tostring(SelfieData.GetCurrentMapID()), tostring(nPresetID))
        return
    end

    local bActivityPresetOn = CampData.IsActivityPresetOn(nMapID)
     if bActivityPresetOn then
        LOG.WARN("RemoteFunction.SetEnvPreset activity preset is on nPresetID:%s, nMapID:%s", tostring(nPresetID), tostring(nMapID))
        return
    end

    Storage.FilterParam.nFilterIndex = 0
    Storage.FilterParam.tbMapParams = Storage.FilterParam.tbMapParams or {}
    Storage.FilterParam.tbMapParams[nMapID] = {}
    Storage.FilterParam.tbParams = {}
    Storage.FilterParam.Dirty()

    SelfieData.ResetFilterFromStorage(true)

    LOG.INFO("RemoteFunction.SetEnvPreset set env preset nPresetID:%s", tostring(nPresetID))
    rlcmd(string.format("set env preset %d", nPresetID))
end

function RemoteFunction.OnRollCall(dwLeaderID)
    Event.Dispatch(EventType.OnRaidReadyConfirmReceiveQuestion, dwLeaderID)
end

function RemoteFunction.OnBeAllSet(dwPlayerID, nReadyState)
    Event.Dispatch(EventType.OnRaidReadyConfirmReceiveAnswer, dwPlayerID, nReadyState)
end

function RemoteFunction.OnOpenChapters(dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
    Event.Dispatch(EventType.OnOpenChapters, dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
end

function RemoteFunction.OnSyncEquipIDArray()
    Event.Dispatch("SYNC_EQUIPID_ARRAY")
end

function RemoteFunction.OnUnEquipAll(nResult)
    Event.Dispatch("UNEQUIPALL", nResult)
end

function RemoteFunction.CountDown(nLeftTime, szPanelName, dwDuration)
    TipsHelper.UpdateCountDown(nLeftTime, szPanelName, dwDuration)
end

--战场拭剑园相关
function RemoteFunction.OpenNewPlayerBF(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore, dwEndTime)
    Event.Dispatch(EventType.BF_OpenNewPlayerBF, dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore, dwEndTime)
end

function RemoteFunction.UpdateNewPlayerBFInfo(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
    Event.Dispatch(EventType.BF_UpdateNewPlayerBF, dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
end

function RemoteFunction.CloseNewPlayerBF()
    Event.Dispatch(EventType.BF_CloseNewPlayerBF)
end

--战场相关
function RemoteFunction.OnBattleFieldRewardRespond(nEnterTime, dwMapID, tResult)
    Event.Dispatch("ON_BATTLEFIELD_REWARD_DATA", nEnterTime, tResult, dwMapID)
end

function RemoteFunction.OnBattleFieldDoublePrestige(nWeekReveived, nWeekLimit)
    Event.Dispatch("ON_BATTLEFIELD_DOUBLE_PRESTIGE_DATA", nWeekReveived, nWeekLimit)
end

function RemoteFunction.GetTodayZhanchangRespond(tResult)
    Event.Dispatch("GET_TODAY_ZHANCHANG_RESPOND", tResult)
end

function RemoteFunction.OnFieldMarkStateUpdate(tMark)
    --LOG.DEBUG("[BattleField] OnFieldMarkStateUpdate")
    Event.Dispatch("ON_FIELD_MARK_STATE_UPDATE", tMark)
end

function RemoteFunction.OnBattleZhouChangNotify(dwMapID, bFinished, nValue, nMaxValue, tReward)
    Event.Dispatch("ON_BATTLE_ZHOU_CHANG_NOTIFY", dwMapID, bFinished, nValue, nMaxValue, tReward)
end

function RemoteFunction.OnFightProgressNotify(szType, fPercent)
    Event.Dispatch("OnFightProgressNotify", szType, fPercent)
end

function RemoteFunction.OnBattleTipNotify(param0, param1, param2)
    local szTip
    if param0 and g_tStrings.tBattleTip[param0] then
        szTip = FormatString(g_tStrings.tBattleTip[param0], param1 or "")
    end

    print("[BattleField] OnBattleTipNotify", param0, param1, param2, szTip)
    Event.Dispatch("OnBattleTipNotify", param0, param1, param2) --TODO?
end

--竞技场相关
function RemoteFunction.OnArenaEventNotify(szEvent, tbData, tbData1)
    Event.Dispatch(EventType.OnArenaEventNotify, szEvent, tbData, tbData1)
end

function RemoteFunction.On_JJC_ArenaWeeklyInfoRespond(nCorpsType, tInfo)
    Event.Dispatch("ON_ARENA_WEEKLY_INFO_UPDATE", nCorpsType, tInfo)
end

--扬刀大会相关
function RemoteFunction.On_ArenaTower_GetRobotList_Res(tRoundRobotList)
    Event.Dispatch("On_ArenaTower_GetRobotList_Res", tRoundRobotList)
end

function RemoteFunction.On_ArenaTower_ShopBuy_Respond()
    Event.Dispatch("On_ArenaTower_ShopBuy_Respond")
end

function RemoteFunction.On_ArenaTower_ApplyEnhanced_Res()
    Event.Dispatch("On_ArenaTower_ApplyEnhanced_Res")
end

function RemoteFunction.On_ArenaTower_OpenInsideShop()
    UIMgr.Open(VIEW_ID.PanelYangDaoBlessShop)
end

function RemoteFunction.On_ArenaTower_OpenEnhanced(nEnhancedPrice3, nEnhancedPrice4)
    local tEnhancedPrice = {
        [3] = nEnhancedPrice3,
        [4] = nEnhancedPrice4,
    } -- [nStar] = nEnhancedPrice
    UIMgr.Open(VIEW_ID.PanelYangDaoBlessUpgrade, tEnhancedPrice)
end

function RemoteFunction.On_ArenaTower_UpdateProgress()
    Event.Dispatch("On_ArenaTower_UpdateProgress")
end

function RemoteFunction.On_ArenaTower_UpdateRoundState(nBattleState)
    Event.Dispatch("On_ArenaTower_UpdateRoundState", nBattleState)
end

function RemoteFunction.On_ArenaTower_ChooseBonus_Res()
    Event.Dispatch("On_ArenaTower_ChooseBonus_Res")
end

function RemoteFunction.On_ArenaTower_EventNotify(szEvent, ...)
    Event.Dispatch("On_ArenaTower_EventNotify", szEvent, ...)
end

function RemoteFunction.On_ArenaTower_ButtonShow()
    Event.Dispatch("On_ArenaTower_ButtonShow")
end

function RemoteFunction.On_ArenaTower_UpdateCoinInGame()
    Event.Dispatch("On_ArenaTower_UpdateCoinInGame")
end

function RemoteFunction.On_ArenaTower_CardEvent(szEvent, nCardID, ...)
    Event.Dispatch("On_ArenaTower_CardEvent", szEvent, nCardID, ...)
end

function RemoteFunction.On_ArenaTower_CardNew(tCardList)
    Event.Dispatch("On_ArenaTower_CardNew", tCardList)
end

function RemoteFunction.On_ArenaTower_OpenJoinPage()
    UIMgr.Open(VIEW_ID.PanelYangDaoMain)
end

function RemoteFunction.On_ArenaTower_RefreshShop_Res()
    Event.Dispatch("On_ArenaTower_RefreshShop_Res")
end

function RemoteFunction.On_ArenaTower_RefreshBonus_Res()
    Event.Dispatch("On_ArenaTower_RefreshBonus_Res")
end

function RemoteFunction.On_ArenaTower_TransScreen(nMode, nRound)
    ArenaTowerData.OpenTransitionView(nMode, nRound)
end

------------------------------------------------------------------
-- 协议动画、视频相关
-- 网络视频播放全屏
function RemoteFunction.OnOpenNetworkVideo(szUrl)
    MovieMgr.PlayVideo(szUrl, {bNet = true}, {})
end

-- 播放本地视频文件
function RemoteFunction.OnPlayerUIMovie(szPath, nFadeInTime, bCannotCancel)
    --- 以前第二个参数这里写错，导致策划脚本里可能传入很大的数字；为了防止“将参数名字改正确而导致意外结果”，只能将错就错了
    MovieMgr.PlayVideo(szPath, {
            bNet = false,
            bCanStop = not bCannotCancel
        }, {
            szMoviePath = szPath
        },
        true
    )
end

--对应原来的接口，OnPlayerUIMovie，新的接口先检查本地是否有视频，有播放本地视频，否则打开网页播放
function RemoteFunction.OnPlayUIMovieEx(dwID, nFadeInTime, bCannotCancel)
    --- nFadeInTime 以前第二个参数这里写错，导致策划脚本里可能传入很大的数字；为了防止“将参数名字改正确而导致意外结果”，只能将错就错了
    local tInfo = Table_GetMoviePath(dwID)
    if not tInfo then
        LOG.ERROR("RemoteFunction call OnPlayUIMovieEx Error the dwID = " .. dwID .. " does not exist")
        return
    end

    local bNet = not Lib.IsFileExist(tInfo.szLocalPath)
    -- 特意做一层判断,VK是Bink
    if not bNet and string.find(tInfo.szLocalPath, ".mp4") then
        bNet = true
    end
    local szUrl = bNet and tInfo.szUrlPath or tInfo.szLocalPath
    MovieMgr.PlayVideo(szUrl, {
            bNet = bNet,
            bCanStop = not bCannotCancel,
            dwOldMovieID = dwID,
        }, {
            szMoviePath = szUrl,
            dwOldMovieID = dwID
        }
    )
end

-- 停止播放本地视频文件
function RemoteFunction.OnStopUIMovie()
    MovieMgr.StopVideo()
end

-- 停止播放视频文件
function RemoteFunction.OnStopUIMovieEx()
    MovieMgr.StopVideo()
end

-- bCannotCancel: 只适用于协议动画
-- nPlayType: 0（或者不传）表示代码自行决定，1表示强制播放协议动画，2表示强制播放url视频
function RemoteFunction.OnPlayUrlMovieOrProtocolMovie(dwID, bCannotCancel, nPlayType)
    if SceneMgr.IsLoading() then
        Event.Reg(RemoteFunction, EventType.UILoadingFinish, function()
            Event.UnReg(RemoteFunction, EventType.UILoadingFinish)
            MovieMgr.PlayUrlMovieOrProtocolMovie(dwID, bCannotCancel, nPlayType)
        end)
        return
    end

    MovieMgr.PlayUrlMovieOrProtocolMovie(dwID, bCannotCancel, nPlayType)
end

-- 尝试播放协议动画，但是会根据比较复杂的规则来决定是播放协议动画还是可能存在的对应的流媒体视频
function RemoteFunction.OnPlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
    MovieMgr.PlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
end

--- 强制播放协议动画（咸鱼端要调用这个接口的话，必须要保证没有用到任何高清资源）
function RemoteFunction.OnForcePlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
    local dwNewMovieID = Table_GetNewMovieIDByProtocolID(dwStoryID)
    if dwNewMovieID == 0 then
        dwNewMovieID = nil
    end

    MovieMgr.ForcePlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
end

--预加载协议动画
function RemoteFunction.OnPreLoadProtocolMovie(dwStoryID)
	MovieMgr.PreLoadProtocolMovie(dwStoryID)
end

function RemoteFunction.OpenSimpleDLCPanel()
    LOG.INFO("OpenSimpleDLCPanel")
    local player = GetClientPlayer()
    local bOpenSimple = player.nLevel < player.nMaxLevel
    if not bOpenSimple then
        LOG.ERROR("WARNING！尝试在满级后打开 SimpleDLCPanel 界面！")
    end
    UIMgr.Open(VIEW_ID.PanelChooseDLC)
end

function RemoteFunction.OnResetMapRespond(data)
    Event.Dispatch(EventType.OnResetMapRespond, data)
end

function RemoteFunction.OnApplyPlayerSavedCopysRespond(data)
    Event.Dispatch(EventType.OnApplyPlayerSavedCopysRespond, data)
end

-- OnUnStrengthEquipbox 剥离装备栏
function RemoteFunction.UnStrengthEquipboxRespond(nResult, nEquipInv)
    print("RemoteFunction.UnStrengthEquipboxRespond")
    Event.Dispatch("EQUIP_UNSTRENGTH", nResult, nEquipInv)
end

-- OnUnStrengthEquip 剥离装备
function RemoteFunction.UnStrengthEquipRespond(nResult, nEquipInv)
    Event.Dispatch("EQUIP_UNSTRENGTH", nResult, nEquipInv)
end

function RemoteFunction.OnUpdateDiamond(nResult)
    FireUIEvent("DIAMON_UPDATE", nResult)
end

-- OnUpdateColorDiamond 五彩石精炼
function RemoteFunction.UpdateColorDiamondRespond(nResult)
    FireUIEvent("UPDATE_COLOR_DIAMOND_RESPOND", nResult)
end

-- OnMountColorDiamond 五彩石熔嵌
function RemoteFunction.OnMountColorDiamond(nResult)
    FireUIEvent("MOUNT_COLOR_DIAMON", nResult)
end

--五彩石绑定武器方案
function RemoteFunction.OnWeaponBindColorDiamond(nResult)
    FireUIEvent("WEAPON_BIND_COLOR_DIAMOND", nResult)
end

--删除五彩石和武器绑定方案
function RemoteFunction.OnDeleteColorDiamondBind(nResult)
    FireUIEvent("DELETE_WEAPON_BIND_COLOR_DIAMOND", nResult)
end

-- OnMountDiamondBox 熔嵌装备栏
function RemoteFunction.OnMountDiamondBox(nResult)
    FireUIEvent("MOUNT_DIAMON", nResult)
end

-- OnStrengthEquipBox 精炼装备栏
function RemoteFunction.StrengthEquipRespond(nResult, nEquipInv)
    FireUIEvent("FE_STRENGTH_EQUIP", nResult, nEquipInv)
end

function RemoteFunction.OnApplyEnterMapInfoRespond(tEnterTimes, tLeftRefreshTime)
    -- arg2 为下次重置时间
    Event.Dispatch(EventType.OnMapEnterInfoNotify, tEnterTimes, tLeftRefreshTime)
end

--更新一个List
function RemoteFunction.OnApplyEnterMapInfoResByList(tEnterTimes, tLeftRefreshTime)
    -- arg2 为下次重置时间
    Event.Dispatch(EventType.OnMapEnterInfoNotifyList, tEnterTimes, tLeftRefreshTime)
end

function RemoteFunction.On_Update_StoryMode()
    Event.Dispatch("On_Update_StoryMode")
end

function RemoteFunction.On_FB_UseStoryMode(dwMapID)
    Event.Dispatch("On_FB_UseStoryMode", dwMapID)
end

-- OnQuickUpdateDiamond 快速精炼
function RemoteFunction.QuickUpdateDiamondRespond(nResult)
    FireUIEvent("QUICK_UPDATE_DIAMOND", nResult)
end

function RemoteFunction.OnUpdateTalentSkillListRespond(nRetCode, tResultTab)
    local player = GetClientPlayer()

    if not player then
        return
    end

    -- 	传递下来的Tab是已经成功的技能,无论最终是否失败都必须应用
    for k, v in ipairs(tResultTab) do
        local dwSkillID 	= v.dwSkillID
        local nSkillLevel	= v.nLevel

        player.UpdateTalentSkill(dwSkillID, nSkillLevel)
    end

    FireUIEvent("ON_UPDATE_TALENT_SKILL_LIST", nRetCode)
end

function RemoteFunction.On_Recharge_CheckRFirstCharge(tbRewardInfo, bCanDo, dwID) -- 首充豪礼
    Event.Dispatch(EventType.On_Recharge_CheckRFirstCharge_CallBack, tbRewardInfo, bCanDo, dwID)
end

function RemoteFunction.On_Recharge_GetRFirstChargeRwd(tbRewardInfo, dwID)--首充豪礼领取奖励反馈
    Event.Dispatch(EventType.On_Recharge_GetRFirstChargeRwd_CallBack, tbRewardInfo, dwID)
end

function RemoteFunction.On_Recharge_GetFriendsPoints(nLeftPoint) -- 好友召回剩余积分
    Event.Dispatch("On_Recharge_GetFriendsPoints_CallBack",nLeftPoint)
end

function RemoteFunction.On_Recharge_GetFriInvReward(nIndex, nCost) --好友召回奖励是否领取成功
    Event.Dispatch("On_Recharge_GetFriInvReward_CallBack",nIndex, nCost)
end

function RemoteFunction.On_Recharge_GetFriendInfo(dwFriendID, tFriendInfo)
    UIMgr.Open(VIEW_ID.PanelRecruitFriendPop,dwFriendID, tFriendInfo)
end

function RemoteFunction.On_Recharge_CheckOnSale(dwID, tRewardInfo, nMoney, bCanDo) --充值送豪礼
    HuaELouData.On_Recharge_CheckOnSale_CallBack(dwID, tRewardInfo, nMoney, bCanDo)
    Event.Dispatch("On_Recharge_CheckOnSale_CallBack", dwID, tRewardInfo, nMoney, bCanDo)
end

function RemoteFunction.On_Recharge_GetOnSaleRwd(dwID, tLevelInfo)
    HuaELouData.On_Recharge_GetOnSaleRwd_CallBack(dwID, tLevelInfo)
    Event.Dispatch("On_Recharge_GetOnSaleRwd_CallBack", dwID, tLevelInfo)
end

function RemoteFunction.On_Recharge_CheckOnSaleMonthly(dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
    HuaELouData.On_Recharge_CheckOnSaleMonthly_CallBack(dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
    Event.Dispatch("On_Recharge_CheckOnSaleMonthly_CallBack",dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
end

function RemoteFunction.On_Recharge_GetOnSaleMonthlyRwd(nMonthId, tLevelInfo)
    HuaELouData.On_Recharge_GetOnSaleMonthlyRwd_CallBack(nMonthId, tLevelInfo)
    Event.Dispatch("On_Recharge_GetOnSaleMonthlyRwd_CallBack",nMonthId, tLevelInfo)
end

--- 密保锁
function RemoteFunction.SafeLock_Unlock(nLockType)
    BankLock.CheckHaveLocked(nLockType)
end

-- 赛季展望活动领取
function RemoteFunction.OnRecvSeasonReward(nType, nIndex, bSuccess)
    Event.Dispatch("ON_RECVSEASON_REWARD", nType, nIndex, bSuccess)
end

-- 赛季任务达成
function RemoteFunction.OnSeasonMissionCompleted(tInfo)
    Event.Dispatch("ON_SEASON_MISSION_COMPLATED", tInfo)
end

---RemotePanel------------------------------------------
function RemoteFunction.OnOpenRemotePanel(szName, tData)
    if szName == "AprilFools" then
        local script = UIHelper.ShowConfirm("你没有和服务器断开连接...")
        script:SetButtonContent("Confirm", "返回游戏界面")
        script:HideButton("Cancel")
        Event.Reg(RemoteFunction, "LOADING_END", function()
            UIMgr.Close(script)
        end, true)
    end
end

-- function RemoteFunction.OnUpdateRemotePanel(szName, tData)
--     Event.Dispatch(EventType.OnUpdateRemotePanel, szName, tData)
-- end

function RemoteFunction.CloseRemotePanel(szName)
    Event.Dispatch(EventType.CloseRemotePanel, szName)
end

function RemoteFunction.On_NewDailySign_Refresh()
    FireUIEvent("ON_DAILY_SIGN_REFRESH")
end

function RemoteFunction.On_NewDailySign_Sign()
    FireUIEvent("ON_DAILY_SIGN_GET_AWARD")
end

function RemoteFunction.On_Recharge_BattlePassCheck(tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
    FireUIEvent("On_Recharge_BattlePassCheck", tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
end

function RemoteFunction.On_Recharge_BattlePassGetRwd(tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
    FireUIEvent("On_Recharge_BattlePassGetRwd", tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
end

function RemoteFunction.On_Recharge_CheckTongBaoGift(nMoney, nTotalTimes, nUsedTimes_Total, nTodayTimesLeft, tUsedTimes, tLotteryTimes, tRewardInfo, tExtraTimesInfo, nMaxExtraTimes, nDayIndex)
    HuaELouData.On_Recharge_CheckTongBaoGift_CallBack(nMoney, nTotalTimes, nUsedTimes_Total, nTodayTimesLeft, tUsedTimes, tLotteryTimes, tRewardInfo, tExtraTimesInfo, nMaxExtraTimes, nDayIndex)
    Event.Dispatch("On_Recharge_CheckTongBaoGift_CallBack")
end

function RemoteFunction.On_Recharge_GetTongBaoGiftRwd(tCardsList, bSuccess, tRewardInfo)
    HuaELouData.On_Recharge_GetTongBaoGiftRwd_CallBack(tCardsList, bSuccess, tRewardInfo)
    Event.Dispatch("On_Recharge_GetTongBaoGiftRwd_CallBack", tCardsList, bSuccess, tRewardInfo)
end

--老活动继续沿用On_Recharge_CheckWelfare
--新活动改为使用OnCheckOperation

--nLimit:是否可以领取奖励,nReward:是否领取了奖励,nMoney:充消金额,bActive:活动是否处于开启状态,bIsBespoke:是否预约
function RemoteFunction.On_Recharge_CheckWelfare(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
    HuaELouData.On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
    Event.Dispatch("On_Recharge_CheckWelfare_CallBack",nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
end

-- 回调客户端接口
-- dwID 活动ID
-- tCustom = {
--    bShow = true, --是否有资格显示活动
--    nSign = 0, --签到次数
      --（多档）奖励独立领取情况 1:已领 2:可领 3:无资格
--    tRewardState = {[1] = nState , [2] = nState, ...}
-- }
function RemoteFunction.OnCheckOperation(dwID, tCustom)
    HuaELouData.On_Check_Operation_CallBack(dwID, tCustom)
    Event.Dispatch("On_Check_Operation_CallBack",dwID, tCustom)
end

--老活动继续沿用On_Recharge_GetWelfareRwd
--新活动改为使用OnGetOperationReward
function RemoteFunction.On_Recharge_GetWelfareRwd(dwID, nRewardID)
    HuaELouData.On_Recharge_GetWelfareRwd_CallBack(dwID, nRewardID)
    Event.Dispatch("On_Recharge_GetWelfareRwd_CallBack",dwID, nRewardID)
end

--回调客户端接口
--dwID 活动ID
--nIndex 第几个奖励，若只有1个，不传此参数
function RemoteFunction.OnGetOperationReward(dwID, nIndex)
    HuaELouData.OnGetOperationReward(dwID, nIndex)
    Event.Dispatch("On_Get_Operation_Reward_CallBack", dwID, nIndex)
end

-- dwID     --活动ID
-- bActive  --是否开启活动
-- tCustom = {
--     nCurValue = 0, --当前进度
--     nTotalValue = 100,  --总进度
--     tRewardState = {[1] = nReward1 , [2] = nReward1, ...} --多档奖励独立领取情况 1:已领 2:可领 3:无资格
-- }
function RemoteFunction.On_Recharge_CheckProgress(dwID, bActive, tCustom) --通用活动模板数据初始化
	HuaELouData.On_Recharge_CheckProgress_CallBack(dwID, bActive, tCustom)
    Event.Dispatch("On_Recharge_CheckProgress_CallBack", dwID, bActive, tCustom)
end

-- dwID   活动ID
-- nLevel 第几档奖励
function RemoteFunction.On_Recharge_GetProgressReward(dwID, nLevel)
	HuaELouData.On_Recharge_GetProgressReward_CallBack(dwID, nLevel)
    Event.Dispatch("On_Recharge_GetProgressReward_CallBack", dwID, nLevel)
end

function RemoteFunction.OnSyncRechargeInfo(nRechargeType, nPointsAmount, nRMBAmount, nLeftTimeOfPoints, nLeftTimeOfDays, nEndDate, nEndTimeOfFee)
    LOG.DEBUG("[OnSyncRechargeInfo] nRechargeType=%d nPointsAmount=%d nRMBAmount=%d nEndTimeOfFee=%d",
            nRechargeType, nPointsAmount, nRMBAmount, nEndTimeOfFee
    )

    Login_SyncRechargeInfo(nRechargeType, nPointsAmount, nRMBAmount, nLeftTimeOfPoints, nLeftTimeOfDays, nEndDate, nEndTimeOfFee)

    -- 抛出事件，方便充值界面及时更新信息
    Event.Dispatch(EventType.OnSyncRechargeInfo, nRechargeType, nPointsAmount, nRMBAmount, nEndTimeOfFee)
end

function RemoteFunction.On_JJC_CanGetLevelAward(tInfo, nGotLevel)
    FireUIEvent("ON_JJC_LEVEL_AWARD_UPDATE", tInfo, nGotLevel)
end

function RemoteFunction.On_JJC_GetLevelAward(bSuccess)
    if bSuccess then
        FireUIEvent("LEVEL_AWARD_GET_SUCCESS")
    end
end

function RemoteFunction.On_JJC_MasterBuffCustomRes(nCustomValue)
    FireUIEvent("ON_JJC_GET_BUFF_CUSTOM_VALUE", nCustomValue)
end

--------- 钓鱼相关
function RemoteFunction.OnOpenFishPanel()
    LOG.ERROR('RemoteFunction.OnOpenFishPanel')
    --OpenFishPanel()
    local script = UIHelper.ShowConfirm("垂钓鱼竿", function()
        RemoteCallToServer("OnApplyShouGanRequest")
    end
    , function()
        RemoteCallToServer("OnApplyFangGanRequest")
    end)
    script:SetButtonContent("Cancel", "垂钓")
    script:SetButtonContent("Confirm", "收杆")
end

function RemoteFunction.OnFishHarvest(dwDoodadID)
    local hPlayer = g_pClientPlayer

    if hPlayer then
        local hDoodad = GetDoodad(dwDoodadID)
        if hDoodad then
            hPlayer.Open(dwDoodadID)
        end
    end
end

function RemoteFunction.OpenBoxRespond(bResult, dwBoxIndex, dwPos)
    if not bResult then
        return
    end
    UIMgr.Open(VIEW_ID.PanelBagChooseItem,dwBoxIndex, dwPos)
end
-- 许愿签相关
-- scripts/Map/节日春节/item/许愿笺.lua
-- RemoteCallToClient(player.dwID, "OnWishPanelRequest")
function RemoteFunction.OnWishPanelRequest(dwIndex)
	UIMgr.Open(VIEW_ID.PanelWishingPad, dwIndex)
end
-- 弹出的砸金蛋确认框
-- RemoteCallToClient(player.dwID, "OnMessageBoxRequest", nMessageID, szMessage, szOKText, szCancelText, param1)
function RemoteFunction.OnMessageBoxRequest(nMessageID, szMessage, szOKText, szCancelText, param1, bRichText, nOK, nCancel, bVisibleWhenCoinShop, bShowClose)
    -- local nHongFuDongTianRequestID = 24 -- 道具ID：26247 烟花鸿福齐天，策划脚本没给按钮文本，要特判补一下
    local nMobaSurrenderRequestID = 58
    if nMessageID == nMobaSurrenderRequestID then
        --- moba的投降请求使用右上角的倒计时组件来实现，类似组队邀请，避免全屏二次确认框影响玩家玩
        BattleFieldData.tSurrenderData = {
            nMessageID = nMessageID,
            szMessage = szMessage,
            szOKText = szOKText,
            szCancelText = szCancelText,
            param1 = param1,
            nOK = nOK,
            nCancel = nCancel,
            bVisibleWhenCoinShop = bVisibleWhenCoinShop,
        }
        TipsHelper.ShowMobaSurrenderTip()
        return
    -- elseif nMessageID == nHongFuDongTianRequestID then
    --     szOKText = UIHelper.UTF8ToGBK(szOKText or g_tStrings.STR_HOTKEY_SURE)
    --     szCancelText = UIHelper.UTF8ToGBK(szCancelText or g_tStrings.STR_HOTKEY_CANCEL)
    end

    if not RemoteFunction.tbMessageBoxRequest then
        RemoteFunction.tbMessageBoxRequest = {}
    end

    -- 有些比如：为避免你的暂离影响到队员的游戏体验，队长权限将在“{$countdown_s 30}秒”后移交给其他队员，你是否同意移交？
    -- 这种倒计时会一直弹的，要把老的先关掉先，不然界面会堆积很多这种二次确认框
    local oldDialog = RemoteFunction.tbMessageBoxRequest[nMessageID]
    if oldDialog then
        if tbOldConfirmFilter[nMessageID] then
            UIMgr.Close(oldDialog)
            RemoteFunction.tbMessageBoxRequest[nMessageID] = nil
        end
    end

    szMessage = UIHelper.GBKToUTF8(szMessage)
    szMessage = ParseTextHelper.ParseNormalText(szMessage)

    local dialog
    if bShowClose then
        dialog = UIHelper.ShowConfirm(szMessage, function ()
            RemoteCallToServer("OnMessageBoxRequest", nMessageID, true, param1)
            RemoteFunction.tbMessageBoxRequest[nMessageID] = nil
        end, function ()
        end, true)

		dialog:SetOtherButtonClickedCallback(function()
			RemoteCallToServer("OnMessageBoxRequest", nMessageID, false, param1)
            RemoteFunction.tbMessageBoxRequest[nMessageID] = nil
		end)

        dialog:SetCancelButtonContent("取消")

        if not string.is_nil(szCancelText) then
            dialog:SetOtherButtonContent(UIHelper.GBKToUTF8(szCancelText))
            dialog:SetOtherNormalCountDown(nCancel)
            dialog:ShowOtherButton()
        end

        if not string.is_nil(szOKText) then
            dialog:SetButtonContent("Confirm", UIHelper.GBKToUTF8(szOKText))
            dialog:SetConfirmNormalCountDown(nOK)
        else
            dialog:HideConfirmButton()
        end
    else
        -- 年兽陶罐 自动砸罐
        if (param1 == 6058 or param1 == 6060) and MY_Taoguan.D.bEnable then
            RemoteCallToServer("OnMessageBoxRequest", nMessageID, true, param1)
            return
        end

        dialog = UIHelper.ShowConfirm(szMessage, function ()
            RemoteCallToServer("OnMessageBoxRequest", nMessageID, true, param1)
            RemoteFunction.tbMessageBoxRequest[nMessageID] = nil
        end, function ()
            RemoteCallToServer("OnMessageBoxRequest", nMessageID, false, param1)
            RemoteFunction.tbMessageBoxRequest[nMessageID] = nil
        end, true)

        if not string.is_nil(szOKText) then
            dialog:SetButtonContent("Confirm", UIHelper.GBKToUTF8(szOKText))
            dialog:SetConfirmNormalCountDown(nOK)
        else
            dialog:HideConfirmButton()
        end

        if not string.is_nil(szCancelText) then
            dialog:SetButtonContent("Cancel", UIHelper.GBKToUTF8(szCancelText))
            dialog:SetCancelNormalCountDown(nCancel)
        else
            dialog:HideCancelButton()
        end
    end

    dialog:SetName("PlayerMessageBoxCommon")

    RemoteFunction.tbMessageBoxRequest[nMessageID] = dialog
end

function RemoteFunction.OnSendSystemAnnounce(szAnnounce, szColor)
    if not szColor or type(szColor) ~= "string" then
        return
    end
    szAnnounce = UIHelper.GBKToUTF8(szAnnounce)
    szColor = szColor:lower()
    if szColor == "red" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szAnnounce)
    elseif szColor == "yellow" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szAnnounce)
    end

    Event.Dispatch(EventType.OnSendSystemAnnounce, szAnnounce, szColor)
end

function RemoteFunction.OnBattleFiledMarkDataNotify(tData)
    FireUIEvent("ON_BATTLE_FIELD_MAKR_DATA_NOTIFY", tData)
end

function RemoteFunction.OnBattleFiledGainDataNotify(tData)
    FireUIEvent("ON_BATTLE_FIELD_GAIN_DATA_NOTIFY", tData)
end

function RemoteFunction.OnBattleFiledSFXDataNotify(aDataList)
    FireUIEvent("ON_BATTLE_FIELD_SFX_DATA_NOTIFY", aDataList)
end

--帮会联赛开启对战小悬浮弹窗
function RemoteFunction.On_TongWar_BattleInfo_Open(bIsOpen, nMapLevel)
    APIHelper.WaitLoadingFinishToDo(function()
        FireUIEvent("ON_OPENTONGWAR_BATTLEINFO_NOTIFY", bIsOpen, nMapLevel)
    end)
end

function RemoteFunction.On_OpenNpcInfo(tInfo)
    UIMgr.Open(VIEW_ID.PanelWinterCharacter, tInfo)
end

function RemoteFunction.UpdateNpcInfo(tInfo)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelWinterCharacter)
    if scriptView then
        scriptView:OnEnter(tInfo)
    end
end

function RemoteFunction.On_CloseNpcInfo()
    UIMgr.Close(VIEW_ID.PanelWinterCharacter)
end

function RemoteFunction.BreakEquipRespond(nResult)
    Event.Dispatch("FE_BREAK_EQUIP", nResult)
end

-- 师徒相关
function RemoteFunction.OnQueryApprentice(szMentorName)
    if IsFilterOperateEnable("OnQueryApprentice") then
        --FireUIEvent("FILTER_QUERY_APPRENTICE", szMentorName, Accept, Refuse, false)
        return
    end

    if IsFilterOperate("OnQueryApprentice") then
        return
    end

    if FellowshipData.IsInBlackListByName(szMentorName) then return end

    local szContent = FormatString(g_tStrings.MENTOR_AGREE_2, UIHelper.GBKToUTF8(szMentorName))
    local szBubContent = FormatString(g_tStrings.MENTOR_AGREE_2_BUBBLE, UIHelper.GBKToUTF8(szMentorName))
    BubbleMsgData.PushMsgWithType("ApprenticeInviteTip", {
        nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
        szContent = szBubContent,
        szAction = function()
            local dialog = UIHelper.ShowConfirm(szContent,function ()
                RemoteCallToServer("OnAnswerApprentice", szMentorName, "YES")
                BubbleMsgData.RemoveMsgWithSrcPlayerName("ApprenticeInviteTip", UIHelper.GBKToUTF8(szMentorName))
            end,function ()
                RemoteCallToServer("OnAnswerApprentice", szMentorName, "NO")
                BubbleMsgData.RemoveMsgWithSrcPlayerName("ApprenticeInviteTip", UIHelper.GBKToUTF8(szMentorName))
            end,false)

            dialog:SetButtonContent("Confirm", "接受")
            dialog:SetButtonContent("Cancel", "拒绝")
        end,
        fnConfirmAction = function ()
            RemoteCallToServer("OnAnswerApprentice", szMentorName, "YES")
            BubbleMsgData.RemoveMsgWithSrcPlayerName("ApprenticeInviteTip", UIHelper.GBKToUTF8(szMentorName))
        end,
		fnCancelAction = function ()
            RemoteCallToServer("OnAnswerApprentice", szMentorName, "NO")
            BubbleMsgData.RemoveMsgWithSrcPlayerName("ApprenticeInviteTip", UIHelper.GBKToUTF8(szMentorName))
        end,
		szPlayerName = UIHelper.GBKToUTF8(szMentorName),
    }, UIHelper.GBKToUTF8(szMentorName))
end

function RemoteFunction.OnQueryMentor(szApprenticeName)
    if IsFilterOperateEnable("OnQueryMentor") then
        --FireUIEvent("FILTER_QUERY_MENTOR", szApprenticeName, Accept, Refuse, false)
        return
    end

    if IsFilterOperate("OnQueryMentor") then
        return
    end

    if FellowshipData.IsInBlackListByName(szApprenticeName) then return end

    local szContent = FormatString(g_tStrings.MENTOR_AGREE_1, UIHelper.GBKToUTF8(szApprenticeName))
    local szBubContent = FormatString(g_tStrings.MENTOR_AGREE_1_BUBBLE, UIHelper.GBKToUTF8(szApprenticeName))
    BubbleMsgData.PushMsgWithType("MentorInviteTip", {
        nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
        szContent = szBubContent,
        szAction = function()
            local dialog = UIHelper.ShowConfirm(szContent,function ()
                RemoteCallToServer("OnAnswerMentor", szApprenticeName, "YES")
                BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
            end,function ()
                RemoteCallToServer("OnAnswerMentor", szApprenticeName, "NO")
                BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
            end,false)

            dialog:SetButtonContent("Confirm", "接受")
            dialog:SetButtonContent("Cancel", "拒绝")

        end,
        fnConfirmAction = function ()
            RemoteCallToServer("OnAnswerMentor", szApprenticeName, "YES")
            BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
        end,
		fnCancelAction = function ()
            RemoteCallToServer("OnAnswerMentor", szApprenticeName, "NO")
            BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
        end,
		szPlayerName = UIHelper.GBKToUTF8(szApprenticeName),
    }, UIHelper.GBKToUTF8(szApprenticeName))

end

function RemoteFunction.OnQueryDirectMentor(szApprenticeName)
    local Accept = function ()
        RemoteCallToServer("OnAnswerDirectMentor", szApprenticeName, "YES")
        BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
        UIHelper.ShowConfirm(FormatString(g_tStrings.DIRECT_MENTOR_ADD_FRIEND, UIHelper.GBKToUTF8(szApprenticeName)),function ()
            FellowshipData.AddFellowship(szApprenticeName)
        end,nil,false)
    end
    local Refuse = function ()
        RemoteCallToServer("OnAnswerDirectMentor", szApprenticeName, "NO")
        BubbleMsgData.RemoveMsgWithSrcPlayerName("MentorInviteTip", UIHelper.GBKToUTF8(szApprenticeName))
    end
    if IsFilterOperateEnable("OnQueryDirectMentor") then
        --FireUIEvent("FILTER_QUERY_MENTOR", szApprenticeName, Accept, Refuse, true)
        return
    end

    if IsFilterOperate("OnQueryDirectMentor") then
        return
    end

    if FellowshipData.IsInBlackListByName(szApprenticeName) then
        return
    end

    local szContent = FormatString(g_tStrings.DIRECT_MENTOR_AGREE_1, UIHelper.GBKToUTF8(szApprenticeName))
    local szBubContent = FormatString(g_tStrings.DIRECT_MENTOR_AGREE_1_BUBBLE, UIHelper.GBKToUTF8(szApprenticeName))
    BubbleMsgData.PushMsgWithType("MentorInviteTip", {
        nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
        szContent = szBubContent,
        szAction = function()
            local dialog = UIHelper.ShowConfirm(szContent,Accept,Refuse,false)
            dialog:SetButtonContent("Confirm", "接受")
            dialog:SetButtonContent("Cancel", "拒绝")
        end}, UIHelper.GBKToUTF8(szApprenticeName))
end

function RemoteFunction.OnMasterToDirectMaster(dwID, szPlayerName)
    if not dwID or not szPlayerName then
        return
    end
    UIHelper.ShowConfirm(FormatString(g_tStrings.STR_MASTER_TO_DIRECT_MASTER, UIHelper.GBKToUTF8(szPlayerName)),function ()
        RemoteCallToServer("OnApplyMentorToDirectMentor", dwID)
    end,nil,false)
end

function RemoteFunction.OnPromptBreakDirectMaster(szPlayerName)
    TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_PROMPT_BREAK_DIRECT_MASTER, UIHelper.GBKToUTF8(szPlayerName)))
end

function RemoteFunction.OnGetMentorListRespond(dwDstPlayerID, MentorList, bGradute)
    Event.Dispatch("ON_GET_MENTOR_LIST", dwDstPlayerID, MentorList, bGradute)
end

function RemoteFunction.OnGetDirectMentorListRespond(dwDstPlayerID, MentorList)
    Event.Dispatch("ON_GET_DIRECT_MENTOR_LIST", dwDstPlayerID, MentorList)
end

function RemoteFunction.OnGetApprenticeListRespond(dwDstPlayerID, ApprenticeList, nWeeklyMentorValueSum)
    Event.Dispatch("ON_GET_APPRENTICE_LIST", dwDstPlayerID, ApprenticeList, nWeeklyMentorValueSum)
end

function RemoteFunction.OnGetDirApprenticeListRespond(dwDstPlayerID, ApprenticeList)
    Event.Dispatch("ON_GET_DIRECT_APPRENTICE_LIST", dwDstPlayerID, ApprenticeList)
end

function RemoteFunction.OnIsAccountDirectApprentice(bApprentice)
    Event.Dispatch("ON_IS_ACCOUNT_DIRECT_APPRENTICE", bApprentice)
end

function RemoteFunction.OnGetDirectMentorRight(bCanBeDirectMentor, bCanBeDirectApprentice)
    Event.Dispatch("ON_GET_DIRECT_MENTOR_RIGHT", bCanBeDirectMentor, bCanBeDirectApprentice)
end

function RemoteFunction.OnIsFreeToDirectApprentice(bOnIsFreeToDirectApprentice)
    Event.Dispatch("ON_IS_FREE_TO_DIRECT_APPRENTICE", bOnIsFreeToDirectApprentice)
end

local nMaxMentorNameLen = 5
function RemoteFunction.OnMentorNotify(szEvent, param, tInfo)
    local szMsg = g_tStrings.MENTOR_MSG[szEvent] or ""
    local szChannel = "MSG_SYS"
    local szFont = GetMsgFontString(szChannel)
    local bRich = false

    if szEvent == "TAKE_APPRENTICE_SUCCESS" then -- 收徒成功
        local szApprenticeName = tInfo.szNameApprentice
        UIHelper.ShowConfirm(FormatString(g_tStrings.MENTOR_ADD_FRIEND, UIHelper.GBKToUTF8(szApprenticeName)),function ()
            FellowshipData.AddFellowship(szApprenticeName)
        end,nil,false)
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
        FellowshipData.SetAppremticeRedpoint(true)
    elseif szEvent == "TAKE_MENTOR_SUCCESS" then -- 拜师成功
        local szMentorName = tInfo.szNameMentor
        UIHelper.ShowConfirm(FormatString(g_tStrings.APPRENTICE_ADD_FRIEND, UIHelper.GBKToUTF8(szMentorName)),function ()
            FellowshipData.AddFellowship(szMentorName)
        end,nil,false)
        Event.Dispatch("NEED_REQUAIRE_MENTOR_LIST")
        FellowshipData.SetMentorRedpoint(true)
    elseif szEvent == "BREAK_MENTOR_RESULT" then -- 解除师父结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_BREAK_MENTOR_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_MENTOR_LIST")
    elseif szEvent == "BREAK_APPRENTICE_RESULT" then -- 解除徒弟结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_BREAK_APPRENTICE_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
    elseif szEvent == "BREAK_MENTOR_NOTIFY" then -- 解除师傅通知（通知师傅）
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
    elseif szEvent == "BREAK_APPRENTICE_NOTIFY" then -- 解除徒弟通知 （通知徒弟）
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("NEED_REQUAIRE_MENTOR_LIST")
    elseif szEvent == "CANCEL_BREAK_MENTOR_RESULT" then -- 取消解除师父结果 param = {dwID, nState, nEndTime}
        --Event.Dispatch("ON_CANCEL_BREAK_MENTOR_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
    elseif szEvent == "CANCEL_BREAK_APPRENTICE_RESULT" then -- 取消解除徒弟结果 param = {dwID, nState, nEndTime}
        --Event.Dispatch("ON_CANCEL_BREAK_APPRENTICE_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
    elseif szEvent == "CANCEL_BREAK_MENTOR_NOTIFY" then -- 取消解除师傅通知（通知师傅）
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
    elseif szEvent == "CANCEL_BREAK_APPRENTICE_NOTIFY" then -- 取消解除徒弟通知（通知徒弟）
        Event.Dispatch("NEED_REQUAIRE_APPRENTICE_LIST")
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_MAP_LIMIT" then -- 师父处在副本中，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_MOVE_STATE_LIMIT" then -- 师父当前的状态不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_INFIGHT" then -- 师傅处在战斗状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_DAOBAOZEI" then -- 师傅在追捕盗宝贼，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_CHUANGONG" then -- 师傅在被传功，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_ZAIJU" then -- 师傅在载具状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_YABIAO" then -- 师傅在押镖状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TONGALL_CD" then -- 在武林至尊CD状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_Quest_LIMIT" then -- 在苍云彩蛋任务状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_OTHER" then -- 其他不能被召请状态
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_TASK_TREASURE" then -- 携带有铁血宝箱，争夺状态不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_IN_SGY" then -- 在思过园不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_GRADUATED_NOTIFY" then
        Event.Dispatch("UPDATE_MENTOR_DATA", UI_GetClientPlayerID())
    elseif szEvent == "APPRENTICE_GRADUATED_NOTIFY" then -- 徒弟出师通知
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("UPDATE_APPRENTICE_DATA", UI_GetClientPlayerID())
    elseif szEvent == "APPRENTICE_GRADUATED_NOTIFY_ADD_NUM" then -- 徒弟毕业级可带徒弟数+1通知
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("UPDATE_APPRENTICE_DATA", UI_GetClientPlayerID())
    elseif szEvent == "ON_APPRENTICE_LEVELUP" then -- 徒弟升级啦 param = {szName, nLevel}
        -- szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param.szName)),true
        -- szMsg = string.gsub(szMsg,'<D1>',param.nLevel)
        Event.Dispatch("UPDATE_APPRENTICE_DATA", UI_GetClientPlayerID())
        return
    elseif szEvent == "ON_APPRENTICE_LEVELUP_TO_GRADUATE" then -- 徒弟满级了，可以去做出师任务了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ACQUIRE_MENTOR_VALUE_SUCCEED" then -- 师徒值转帮贡成功 param = nMentorValue
        szMsg = FormatString(szMsg, param, param * 5)
        Event.Dispatch("NEED_REQUAIRE_MENTOR_LIST")
    elseif szEvent == "ON_MENTOR_OFFLINE" then -- 师徒下线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_APPRENTICE_OFFLINE" then -- 徒弟下线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_APPRENTICE_ONLINE" then -- 徒弟上线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_MENTOR_ONLINE" then -- 师父上线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_YOU_BREAK_APPRENTICE" then -- 师父上线时 自己正和param徒弟解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_APPRENTICE_BREAK_YOU" then -- 师父上线时 param徒弟正和自己解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_MENTOR_BREAK_YOU" then -- 徒弟上线时 param徒弟正和自己解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_YOU_BREAK_MENTOR" then -- 徒弟上线时 自己正和param徒弟解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_TONG_NOT_AGREE" then -- 召唤帮众 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_QINGMINGJIE_ZUIYUAN_EVOKE_MSG_MSG" then -- 打醉猴召唤队友 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_PARTY_NOT_AGREE" then -- 召唤队友 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif  szEvent == "ON_TAKE_MENTOR_HE_HAVE_MENTOR" then -- 拜师，对方有师父
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif  szEvent == "ON_TAKE_APPRENTICE_HE_HAVE_APPRENTICE" then -- 收徒，对方有徒弟
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif  szEvent == "ON_TAKE_APPRENTICE_I_HAVE_MENTOR" then -- 收徒，自己有师傅
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_COHABIT_NOT_AGREE" then -- 召唤同居室友 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_COHABIT_OVERTIME" then -- 召唤同居室友 对方延时反应，已过期
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    end


    local szBubbleText = ""
    if szEvent == "ON_APPRENTICE_ONLINE" and tInfo then
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szBubbleText = FormatString(g_tStrings.STR_APPRENTICE_ONLINE,  szName)
        Event.Dispatch(EventType.OnUpdateMentorOnlineInfo, szBubbleText, param, 2, tInfo)
    elseif szEvent == "ON_MENTOR_ONLINE" and tInfo then
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szBubbleText = FormatString(g_tStrings.STR_MENTOR_ONLINE,  szName)
        Event.Dispatch(EventType.OnUpdateMentorOnlineInfo, szBubbleText, param, 1, tInfo)
    elseif szEvent == "ON_MENTOR_OFFLINE" then
        Event.Dispatch(EventType.OnUpdateMentorOfflineInfo, szMsg, param, 1, tInfo)
    elseif  szEvent == "ON_APPRENTICE_OFFLINE" then
        Event.Dispatch(EventType.OnUpdateMentorOfflineInfo, szMsg, param, 2, tInfo)
    end

    if szMsg and szMsg ~= "" then
        OutputMessage(szChannel, szMsg, bRich)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg, bRich)
    end
end

function RemoteFunction.OnDirectMentorNotify(szEvent, param, tInfo)
    local szMsg = g_tStrings.DIRECT_MENTOR_MSG[szEvent] or ""
    local szChannel = "MSG_SYS"
    local szFont = GetMsgFontString(szChannel)
    local bRich = false

    if szEvent == "TAKE_APPRENTICE_SUCCESS" then -- 收徒成功
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
        FellowshipData.SetAppremticeRedpoint(true)
    elseif szEvent == "TAKE_MENTOR_SUCCESS" then -- 拜师成功
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
        FellowshipData.SetMentorRedpoint(true)
    elseif szEvent == "BREAK_MENTOR_RESULT" then -- 解除师父结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_BREAK_DIRECT_MENTOR_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "BREAK_APPRENTICE_RESULT" then -- 解除徒弟结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_BREAK_DIRECT_APPRENTICE_RESULT", param)
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "BREAK_MENTOR_NOTIFY" then -- 解除师傅通知（通知师傅）
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
    elseif szEvent == "BREAK_APPRENTICE_NOTIFY" then -- 解除徒弟通知 （通知徒弟）
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "CANCEL_BREAK_MENTOR_RESULT" then -- 取消解除师父结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_CANCEL_BREAK_DIRECT_MENTOR_RESULT", param)
    elseif szEvent == "CANCEL_BREAK_APPRENTICE_RESULT" then -- 取消解除徒弟结果 param = {dwID, nState, nEndTime}
        --FireUIEvent("ON_CANCEL_BREAK_DIRECT_APPRENTICE_RESULT", param)
    elseif szEvent == "CANCEL_BREAK_MENTOR_NOTIFY" then -- 取消解除师傅通知（通知师傅）
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "CANCEL_BREAK_APPRENTICE_NOTIFY" then -- 取消解除徒弟通知（通知徒弟）
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_MAP_LIMIT" then -- 师父处在副本中，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_MOVE_STATE_LIMIT" then -- 师父当前的状态不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "MENTOR_INFIGHT" then -- 师傅处在战斗状态，不能被召请
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "APPRENTICE_GRADUATED_NOTIFY" then -- 徒弟毕业通知
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "APPRENTICE_GRADUATED_NOTIFY_ADD_NUM" then -- 徒弟毕业可带徒弟数+1通知
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_APPRENTICE_LEVELUP" then -- 徒弟升级啦 param = {szName, nLevel}
        -- szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param.szName)),true
        -- szMsg = string.gsub(szMsg,'<D1>',param.nLevel)
        return
    elseif szEvent == "ON_APPRENTICE_LEVELUP_TO_GRADUATE" then -- 徒弟升到满级了，可以去做出师任务了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ACQUIRE_MENTOR_VALUE_SUCCEED" then -- 师徒值转帮贡成功 param = nMentorValue
        szMsg = FormatString(szMsg, param, param * 5)
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "ON_MENTOR_OFFLINE" then -- 师徒下线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_APPRENTICE_OFFLINE" then -- 徒弟下线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_APPRENTICE_ONLINE" then -- 徒弟上线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_MENTOR_ONLINE" then -- 师父上线了 param = szName
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szMsg, bRich = string.gsub(szMsg,'<link 0>', szName),true
    elseif szEvent == "ON_YOU_BREAK_APPRENTICE" then -- 师父上线时 自己正和param徒弟解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_APPRENTICE_BREAK_YOU" then -- 师父上线时 param徒弟正和自己解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_MENTOR_BREAK_YOU" then -- 徒弟上线时 param徒弟正和自己解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "ON_YOU_BREAK_MENTOR" then -- 徒弟上线时 自己正和param徒弟解除关系
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_TONG_NOT_AGREE" then -- 召唤帮众 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_QINGMINGJIE_ZUIYUAN_EVOKE_MSG_MSG" then -- 打醉猴召唤队友 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "EVOKE_PARTY_NOT_AGREE" then -- 召唤队友 对方拒绝了
        szMsg, bRich = string.gsub(szMsg,'<link 0>',UIHelper.GBKToUTF8(param)),true
    elseif szEvent == "GRADUATE_BY_DIRECT_APPRENTICE_RESULT" then -- 徒弟提出出师结果 param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "GRADUATE_BY_DIRECT_APPRENTICE_NOTIFY" then -- 徒弟提出出师通知（通知师傅）param = {szName}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
    elseif szEvent == "GRADUATE_BY_DIRECT_MENTOR_RESULT" then -- 师傅提出出师结果 param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
    elseif szEvent == "GRADUATE_BY_DIRECT_MENTOR_NOTIFY" then -- 师傅提出出师通知 （通知徒弟）param = {szName}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "CANCEL_GRADUATE_BY_DIRECT_APPRENTICE_RESULT" then --徒弟取消出师结果 param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "CANCEL_GRADUATE_BY_DIRECT_APPRENTICE_NOTIFY" then --徒弟取消出师通知 (通知师傅) param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
    elseif szEvent == "CANCEL_GRADUATE_BY_DIRECT_MENTOR_RESULT" then --师傅取消出师结果 param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_APPRENTICE_LIST")
    elseif szEvent == "CANCEL_GRADUATE_BY_DIRECT_MENTOR_NOTIFY" then --师傅取消出师通知 (通知徒弟) param = {dwID, nState, nEndTime}
        Event.Dispatch("NEED_REQUAIRE_DIRECT_MENTOR_LIST")
    elseif szEvent == "MENTOR_NO_RIGHT" then -- 师傅没有资格

    elseif szEvent == "TRANSFORM_TO_MASTER" then --帐号状态转换为亲传师父成功
        Event.Dispatch("TRANSFORM_TO_MASTER")
    elseif szEvent == "TRANSFORM_TO_APPRENTICE" then --帐号状态免费转换为亲传徒弟成功
        Event.Dispatch("TRANSFORM_TO_APPRENTICE")
    elseif szEvent == "LOGIN_APPRENTICE_ACCOUNT_BREAK_MENTOR" then --登录时候处理的提示，亲传徒弟账号断掉亲传师父
        szMsg = FormatString(szMsg, param)
    elseif szEvent == "LOGIN_APPRENTICE_ACCOUNT_APPRENTICE" then --登录时候处理的提示，亲传徒弟账号断掉一个亲传徒弟
        szMsg = FormatString(szMsg, param)
    elseif szEvent == "LOGIN_MENTOR_ACCOUNT_BREAK_APPRENTICE" then --登录时候处理的提示，亲传师父账号断掉亲传徒弟
        szMsg = FormatString(szMsg, param)
    end

    local szBubbleText = ""
    if szEvent == "ON_APPRENTICE_ONLINE" and tInfo then
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szBubbleText = FormatString(g_tStrings.STR_DIRECT_APPRENTICE_ONLINE,  szName)
        Event.Dispatch(EventType.OnUpdateMentorOnlineInfo, szBubbleText, param, 2, tInfo)
    elseif szEvent == "ON_MENTOR_ONLINE" and tInfo then
        local szName = UIHelper.GBKToUTF8(param)
        szName = UIHelper.GetUtf8SubString(szName, 1, nMaxMentorNameLen)
        szBubbleText = FormatString(g_tStrings.STR_DIRECT_MENTOR_ONLINE,  szName)
        Event.Dispatch(EventType.OnUpdateMentorOnlineInfo, szBubbleText, param, 1, tInfo)
    elseif szEvent == "ON_MENTOR_OFFLINE" then
        Event.Dispatch(EventType.OnUpdateMentorOfflineInfo, szMsg, param, 1, tInfo)
    elseif  szEvent == "ON_APPRENTICE_OFFLINE" then
        Event.Dispatch(EventType.OnUpdateMentorOfflineInfo, szMsg, param, 2, tInfo)
    end

    if szMsg and szMsg ~= "" then
        OutputMessage(szChannel, szMsg, bRich)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg, bRich)
    end
end

function RemoteFunction.OnSyncMentorData(szType, param)
    if szType == "ALL" then
        -- player.nMaxApprenticeNum    = param[1];
        -- player.nAcquiredMentorValue = param[2];
        -- player.nLastEvokeMentorTime = param[3];
        -- player.nEvokeMentorCount    = param[4];
        -- player.nUsableMentorValue   = param[5];
        -- player.dwTAEquipsScore      = param[6];
        Event.Dispatch("ON_SYNC_MENTOR_DATA",param[1], param[2], param[3], param[4], param[5])
        Event.Dispatch("ON_SYNC_TA_EQUIPS_SCORE",param[6])
    elseif szType == "ACQUIRED_MVALUE" then
        -- player.nAcquiredMentorValue = param;
        -- Event.Dispatch("ON_SYNC_ACQUIRED_MVALUE",param)
    elseif szType == "LEFT_EVOKE_NUM" then
        -- player.nEvokeMentorCount = param;
        Event.Dispatch("ON_SYNC_LEFT_EVOKE_NUM",param)
    elseif szType == "MAX_APPRENTICE_NUM" then
        -- player.nMaxApprenticeNum = param;
        Event.Dispatch("ON_SYNC_MAX_APPRENTICE_NUM",param)
    --elseif szType == "USABLE_MVALUE" then
        -- player.nUsableMentorValue = param;
        -- Event.Dispatch("ON_SYNC_USABLE_MVALUE",param)
    elseif szType == "TA_EQUIPS_SCORE" then
        -- player.dwTAEquipsScore = param;
        Event.Dispatch("ON_SYNC_TA_EQUIPS_SCORE",param)
    end
end

function RemoteFunction.OnQueryEvoke(dwSrcPlayerID, szSrcPlayerName, dwMapID, szRelation)
    -- 询问是否接受传送到dwMapID的地图
    local szMapName = Table_GetMapName(dwMapID)
    local szBubbleDesc = ""
    local szMsg = "";
    szSrcPlayerName = UIHelper.GBKToUTF8(szSrcPlayerName)

    if szRelation == "A2M" then
        szMsg = g_tStrings.MENTOR_APPRENTICE_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.APPRENTICE_EVOKE_MSG
    elseif szRelation == "M2A" then
        szMsg = g_tStrings.MENTOR_MENTOR_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.MENTOR_EVOKE_MSG
    elseif szRelation == "FRIEND" then
        szMsg = g_tStrings.MENTOR_FRIEND_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.FRIEND_EVOKE_MSG
    elseif szRelation == "TONG" then
        szMsg = g_tStrings.MENTOR_TONG_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.TONG_EVOKE_MSG
    elseif szRelation == "TONGALL" then
        szMsg = g_tStrings.MENTOR_TONGALL_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.TONG_EVOKE_MSG
    elseif szRelation == "TONGALLS" then
        szMsg = g_tStrings.MENTOR_TONGALLS_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.TONG_EVOKE_MSG
    elseif szRelation == "ZUIYUAN" then
        szMsg = g_tStrings.MENTOR_QINGMINGJIE_ZUIYUAN_EVOKE_MSG_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.PARTY_EVOKE_MSG
    elseif szRelation == "PARTY" then
        szMsg = g_tStrings.MENTOR_PARTY_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.PARTY_EVOKE_MSG
    elseif szRelation == "PARTYS" then
        szMsg = g_tStrings.MENTOR_PARTY_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.PARTY_EVOKE_MSG
    elseif szRelation == "COHABIT" then
        szMsg = g_tStrings.MENTOR_COHABIT_EVOKE_MSG;
        szBubbleDesc = g_tStrings.tBubbleEvokeDesc.COHABIT_EVOKE_MSG
    else
        return;
    end

    local function funcConfirm()
        -- 地图资源下载检测拦截
        if PakDownloadMgr.UserCheckDownloadMapRes(dwMapID) then
            RemoteCallToServer("OnAnswerEvoke", dwSrcPlayerID, "YES", szRelation)
        else
            RemoteCallToServer("OnAnswerEvoke", dwSrcPlayerID, "NO", szRelation)
        end
        BubbleMsgData.RemoveMsgWithSrcPlayerName("QueryEvokeTip", szSrcPlayerName)
    end

    local function funcCancel()
        RemoteCallToServer("OnAnswerEvoke", dwSrcPlayerID, "NO", szRelation)
        BubbleMsgData.RemoveMsgWithSrcPlayerName("QueryEvokeTip", szSrcPlayerName)
    end

    -- UIHelper.ShowConfirm(FormatString(szMsg, szSrcPlayerName, UIHelper.GBKToUTF8(szMapName)), funcConfirm, funcCancel)

    BubbleMsgData.PushMsgWithType("QueryEvokeTip", {
    	nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
    	-- szContent = FormatString(szBubbleDesc, szSrcPlayerName, UIHelper.GBKToUTF8(szMapName)),
        szContent = "召请至[" .. UIHelper.GBKToUTF8(szMapName) .. "]",
    	szAction = function()
    		UIHelper.ShowConfirm(FormatString(szMsg, szSrcPlayerName, UIHelper.GBKToUTF8(szMapName)), funcConfirm, funcCancel)
    	end,
        fnConfirmAction = funcConfirm,
		fnCancelAction = funcCancel,
		nPlayerID = dwSrcPlayerID,
		szPlayerName = szSrcPlayerName,
    }, szSrcPlayerName)
end

function RemoteFunction.OnApprenticeLevelupPriseNotify(nLevel, szMentorName)
    local player = GetClientPlayer();
    if not player then
        return;
    end

    local NotifyContent = {{type = "text", text = UIHelper.UTF8ToGBK(FormatString(g_tStrings.LEVELUP_PRISE_NOTIFY, nLevel))}};

    Player_Talk(player, PLAYER_TALK_CHANNEL.WHISPER, szMentorName, NotifyContent, false);
end

-- 请求成就排名响应
function RemoteFunction.OnSyncRankingInfo(dwAchievement, tRankingInfo, bStatic)
    Event.Dispatch("ON_SYNC_RANKING_INFO", dwAchievement, tRankingInfo, bStatic)
end

function RemoteFunction.On_PQ_RequestDataReturn(tbPQID)
    Event.Dispatch("ON_PQ_REQUEST_DATA", tbPQID)
end

function RemoteFunction.FieldPQStateUpdate(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
    Event.Dispatch("FIELD_PQ_STATE_UPDATE", dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
end

function RemoteFunction.CloseFieldPQPanel(dwPQTemplateID)
    Event.Dispatch("CLOSE_FIELD_PQ_PANEL", dwPQTemplateID)
end

function RemoteFunction.On_PQ_OpenEndUI(tbReward)
    -- local tbReward = {
    --     nResult = 1, --结果。1：成功 2：失败
    --     nLevel = 3, --评价：0失败，1铜，2银 3金
    --     szText = "【重建杏花村】成功！",
    --     tItem = {{5, 19404, 10}, {5, 19310, 10}, {5, 2863, 10}, },
    --     tOtherReward = {},
    --     experience = 5,
    --     tSpecialItem = {{5, 1024, 1}, {5, 10086, 1},},
    -- }
    local nRewardType = REWARD_TYPE.GOLDEN
    if tbReward.nLevel == 0 then
        nRewardType = REWARD_TYPE.FAIL
    elseif tbReward.nLevel == 1 then
        nRewardType = REWARD_TYPE.COPPERY
    elseif tbReward.nLevel == 2 then
        nRewardType = REWARD_TYPE.SILVER
    end
    if tbReward.nResult == 2 then
        nRewardType = REWARD_TYPE.FAIL
    end
    if tbReward and tbReward.experience and tbReward.experience > 0 then
        tbReward.tOtherReward["experience"] = tbReward.experience
    end

    if tbReward.tSpecialItem then
        table.insert_tab(tbReward.tItem,  tbReward.tSpecialItem)
    end

    if tbReward and tbReward.tOtherReward and tbReward.tOtherReward["money"] and tbReward.tOtherReward["money"] > 0 then
        tbReward.tOtherReward["money"] = tbReward.tOtherReward["money"] * 10000--服务端数据为金，转换为铜
    end
    PublicQuestData.ApplyPQ()
    TipsHelper.ShowRewardHint(nRewardType, UIHelper.GBKToUTF8(tbReward.szText), tbReward.tItem, tbReward.tOtherReward, nil, nil, nil, nil, true, false, tbReward.tCustomTip)
end

function RemoteFunction.OnBankPasswordNotify(szEvent, nCode)
    -- note: nCode 目前仅绑定设备解锁方式失败时会传入，方便得知具体失败的原因
    if szEvent == "SECURITY_VERIFY_PASSWORD_SUCCESS" or szEvent == "VERIFY_BANK_PASSWORD_SUCCESS" or szEvent == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_SUCCESS" then
        BankLock.bBagAndTradeUnlocked = true
    end

    Event.Dispatch("BANK_LOCK_RESPOND", szEvent, nCode)
end

function RemoteFunction.SetBankPasswordVerified(bIsVerified)
    local player = GetClientPlayer()
    if not player then
        return
    end

    player.bIsBankPasswordVerified = bIsVerified
end

function RemoteFunction.SetBankPasswordResetTime(nTime)
    local player = GetClientPlayer()
    if not player then
        return
    end

    player.nBankPasswordResetEndTime = nTime
end

function RemoteFunction.SetBankPasswordExist(bExist)
    local player = GetClientPlayer()
    if not player then
        return
    end

    player.bBankPasswordExist = bExist
end

function RemoteFunction.SetBankPasswordQuestionID(nQuestionID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    player.nBankPasswordQuestionID = nQuestionID
end

function RemoteFunction.OnGetGlobalRanking(szType, tMsg, bSuccess, nStartIndex, nNextStartIndex, eQueryer)
    -- 参数nNextStartIndex等于0表示szType全部同步完了
    if eQueryer == 1 then
        FireUIEvent("ON_FENGYUNLU_GET_RANKING", szType, tMsg, bSuccess, nStartIndex, nNextStartIndex)
    elseif eQueryer == 2 then
        FireUIEvent("ON_MENTORSTONE_GET_RANKING", szType, tMsg, bSuccess, nStartIndex, nNextStartIndex)
    end
end

function RemoteFunction.OnGetWantedMinMoneyLimitRespond(szName, nMinLimit, nMaxLimit)
    FireUIEvent("ON_GET_WANTED_MIN_MONEY_LIMIT", szName, nMinLimit, nMaxLimit)
end

function RemoteFunction.OnOpenExamPanel(szQuestionList, nPromoteTime, nTestType)
    if not UIMgr.GetView(VIEW_ID.PanelExamination) then
        UIMgr.Open(VIEW_ID.PanelExamination,szQuestionList, nPromoteTime, nTestType)
    end
end

function RemoteFunction.OnCloseExamPanel()
    if UIMgr.GetView(VIEW_ID.PanelExamination) then
        Event.Dispatch("OnCloseExamPanel")
    end
end

function RemoteFunction.SynExamContent(nQuestionIndex, tExamContents)
    Event.Dispatch("SynExamContent", nQuestionIndex,tExamContents)
end

function RemoteFunction.SendExamAnswer()
    if UIMgr.GetView(VIEW_ID.PanelExamination) then
        Event.Dispatch("SendExamAnswer")
    end
end

function RemoteFunction.On_Prepare_Duel(dwSrcPlayerID, dwDstPlayerID, nEndFrame, bLeiTai, szName)
    FireUIEvent("SYS_MSG", "UI_OME_PREPARE_DUEL", dwSrcPlayerID, dwDstPlayerID, nEndFrame, bLeiTai, szName)
end

function RemoteFunction.OnSyncFengyunRankVersion(nVersion)
    FireUIEvent("ON_FENGYUNLU_GET_RANKING_VERSION", nVersion)
end

function RemoteFunction.StartNewFilterMask(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
    --OpenFilterMask(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)

    local szText = ""
    for i = 1, #tText do
        if #szText > 0 then
            szText = szText .. "\n"
        end
        szText = szText .. tText[i].szText
    end

    if UIHelper.GBKToUTF8(szText) == "偷得浮生半日闲\n素水清茶洗尘心" then
        UIMgr.Open(VIEW_ID.PanelPartnerMainTips, PartnerData.tTipsType.nDrawFailed, UIHelper.GBKToUTF8(szText), nil)
    else
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBlackScreen)
        if scriptView then
            scriptView:OnEnter(nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
        else
            UIMgr.Open(VIEW_ID.PanelBlackScreen, nFadeOutTime, nFadeInTime, nKeepTime, tFadeColor, bRENDER, bHideUI, tText, bCanEsc)
        end
    end
end

--打开红尘侠影界面指定分页
function RemoteFunction.On_Partner_OpenByPage(nPage)
    local tPageToOpenType = {
        [1] = PartnerViewOpenType.Default, -- 侠客
        [2] = PartnerViewOpenType.Morph, -- 配置
        [3] = PartnerViewOpenType.Travel, -- 出行
    }

    local nOpenType = tPageToOpenType[nPage]
    if nOpenType then
        ---@see UIPartnerView
        UIMgr.Open(VIEW_ID.PanelPartner, nil, nOpenType)
    end
end

--任务线界面
function RemoteFunction.On_Partner_StartTaskOpen(dwID)
    --StartTask.Open(dwID)
    -- note: 改用 UIPartnerXunFangView 来进行喝茶相关流程显示了
    --UIMgr.Open(VIEW_ID.PanelPartnerMainTips, PartnerData.tTipsType.nStartTask, "", dwID)
end

--结识界面
function RemoteFunction.On_Partner_GetNewNpcOpen(dwID)
    --GetNewPartner.Open(dwID)
    UIMgr.Open(VIEW_ID.PanelPartnerMainTips, PartnerData.tTipsType.nGetNewPartner, "", dwID)

    Partner_NewAddPartner(dwID)
end

--伙伴邀约
function RemoteFunction.On_PartnerMessage(dwID)
    if not dwID then
        return
    end

    local tInfo = Table_GetPartnerMessage(dwID)
    if not tInfo then
        return
    end

    local szGuide = UIHelper.GBKToUTF8(tInfo.szGuide)

    -- link="NPCGuide/2394"
    local szLink = szGuide:match("link=\"%a+/%d+\"")
    if not szLink then
        return
    end

    local szLinkEvent, szLinkArg = szLink:match("(%a+)/(%d+)")
    if szLinkEvent ~= "NPCGuide" then
        return
    end
    local nLinkID      = tonumber(szLinkArg)

    local szTextGuide = ParseTextHelper.ParseNormalText(szGuide)
    local szRichTextGuide = UIHelper.ConvertRichTextFormat(szGuide)

    local szMsgType = "PartnerMessage"
    BubbleMsgData.PushMsgWithType(szMsgType, {
        nBarTime = 0,
        szContent = szTextGuide,
        szAction = function()
            local dialog = UIHelper.ShowConfirm(szRichTextGuide, function()
                local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
                if #tAllLinkInfo > 0 then
                    local tLink  = tAllLinkInfo[1]

                    local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
                    MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
                    UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
                end

                BubbleMsgData.RemoveMsg(szMsgType)
            end, function()
                BubbleMsgData.RemoveMsg(szMsgType)
            end, true)

            dialog:SetConfirmButtonContent("前往")
            dialog:SetCancelButtonContent("关闭")
        end,
    })
end

--实时排行榜
function RemoteFunction.On_Castle_TongToCastleRequest(tRetCastleInfo)
    FireUIEvent("ON_CASTLE_TONG_CASTLE_RESPOND", tRetCastleInfo)
end

--积分抽奖已抽取货币
function RemoteFunction.On_RewardsDraw_GetCoin(nCoinNum, nTimeCardNum, nMonthCardNum)
    Event.Dispatch(EventType.OnRewardsDrawGetCoin, nCoinNum, nTimeCardNum, nMonthCardNum)
end

--积分抽奖奖品列表
function RemoteFunction.On_RewardsDraw_GetRewardsList(nPoolIndex, tLevelList)
    Event.Dispatch(EventType.OnRewardsDrawGetRewardsList, nPoolIndex, tLevelList)
end

function RemoteFunction.OnClearMapQueue()
    Event.Dispatch(EventType.OnClearMapQueue)
end

function RemoteFunction.EnterMonopolyGame()
	UIMgr.Open(VIEW_ID.PanelRichMan)
end

function RemoteFunction.On_QiYu_GetCurrentAdvInfo(tAdventureInfo)
    Event.Dispatch(EventType.OnGetCurrentAdventureInfo, tAdventureInfo)
end

function RemoteFunction.On_QiYu_GetCurrentTaskID(nCurrID)
    AdventureData.OnGetCurrentTaskID(nCurrID)
end

function RemoteFunction.On_QiYu_GetPetTryBook(tPetTryMap)
    Event.Dispatch(EventType.OnGetAdventurePetTryBook, tPetTryMap)
end

function RemoteFunction.OpenAdventure(nAdvID, bFinish)
    UIMgr.Open(VIEW_ID.PanelQiYuPop, nAdvID, bFinish)
    if bFinish then
        AdventureData.CloseTrace()
    end
end

function RemoteFunction.Update_Middle_Map_Circle(nIndex, fStartScale, fEndScale, nStartX, nStartY, nEndX, nEndY, nTime)
    FireUIEvent("UPDATE_MIDDLE_MAP_CIRCLE", nIndex, fStartScale, fEndScale, nStartX, nStartY, nEndX, nEndY, nTime)
end

function RemoteFunction.Clear_Middle_Map_Circle()
    FireUIEvent("CLEAR_MIDDLE_MAP_CIRCLE")
end

function RemoteFunction.Hide_Middle_Map_Circle(nIndex)
    FireUIEvent("HIDE_MIDDLE_MAP_CIRCLE", nIndex)
end

function RemoteFunction.On_JueJing_GetLineInfo(tInfo)
    FireUIEvent("MIDDLE_MAP_JUEJING_GETLINEINFO",tInfo)
end

function RemoteFunction.On_JueJing_StopChooseLine()
    FireUIEvent("MIDDLE_MAP_ON_JUEJING_STOPCHOOSELINE")
end

-- 吃鸡地图 客户端选择线路，服务端收到后返回tInfo，bSuccess，表示成功选择或未成功选择
function RemoteFunction.On_JueJing_ChooseLine(tInfo, bSuccess)
    FireUIEvent("MIDDLE_MAP_JUEJING_CHOOSELINE", tInfo, bSuccess)
end

--3、客户端选择是否跟随队长，服务端收到数据后返回是否成功选择
function RemoteFunction.On_JueJing_FollowLeader(tInfo,bSuccess)
    FireUIEvent("MIDDLE_MAP_JUEJING_FOLLOWLEADER", tInfo, bSuccess)
end

-- h
function RemoteFunction.Update_Middle_Map_Line(tLine)
    FireUIEvent("UPDATE_MIDDLE_MAP_LINE", tLine)
end

local nTreasureBFPlayerNumTimerID = nil
function RemoteFunction.OnRemotekillMessage(szKiller, dwKillerForceId, szTarget, dwTargetForceId , nTime, dwSkinID)
	local tUISKinInfo = Table_GetDesertStormSkinInfo()
    local szSFXPath = ""
    for _, v in pairs(tUISKinInfo) do
		if v and v.dwID == dwSkinID then
			szSFXPath = v.szSFXPath
            break
		end
	end
    Event.Dispatch("ShowMobaBattleMsg", UIHelper.GBKToUTF8(szKiller), UIHelper.GBKToUTF8(szTarget), szSFXPath)
    -- local szText = string.format("%s 重伤 %s", UIHelper.GBKToUTF8(szKiller), )
    -- TipsHelper.ShowNormalTip(szText, false)
    if BattleFieldData.IsInTreasureBattleFieldMap() then
        Timer.DelTimer(RemoteFunction, nTreasureBFPlayerNumTimerID)
        nTreasureBFPlayerNumTimerID = Timer.Add(RemoteFunction, 2, function ()
            Event.Dispatch(EventType.ShowTreasureBattleFieldPlayerNumHint)
        end)
    end
end

function RemoteFunction.On_DesertStorm_Skin_Update()
	Event.Dispatch(EventType.UpdateTreasureBattleFieldSkin)
end

function RemoteFunction.On_JueJing_UpdateSkill(nSkillID, nSkillLevel, bAdd)
	TreasureBattleFieldSkillData.UpdateSkill(nSkillID, nSkillLevel, bAdd)
end

function RemoteFunction.On_JueJing_SkillList(tSkill, bDragSkill, nKey)
	TreasureBattleFieldSkillData.UpdateSkillList(tSkill, bDragSkill, nKey)
end

function RemoteFunction.On_JueJing_SwitchSkillList(tNewSkill)
	TreasureBattleFieldSkillData.SwitchSkillList(tNewSkill)
end

function RemoteFunction.On_JueJing_SwitchSkill(nOldSkillID, nOldSkillLevel, nNewSkillID, nNewSkillLevel)
	TreasureBattleFieldSkillData.SwitchSkill(nOldSkillID, nOldSkillLevel, nNewSkillID, nNewSkillLevel)
end

function RemoteFunction.On_JueJing_BuyLackItems(tButList)
    UIMgr.Open(VIEW_ID.PanelXunBaoBuyLackItemPop, tButList)
end

function RemoteFunction.On_Mobile_GetSceneMarkNum(tInfo)
    Event.Dispatch(EventType.OnGetWorldMarkInfo, tInfo)
end

-- 家园-大唐家园相关-开始
function RemoteFunction.Home_ReqValidCommunityIndices(dwMapID)
    Timer.AddFrame(RemoteFunction, 1, function ()
        UIMgr.Open(VIEW_ID.PanelHome)
    end)
end

function RemoteFunction.Home_RequestSelfHouseInfo(userdata1, userdata2)
    HomelandEventHandler.RequestSelfHouseInfo(userdata1, userdata2)
end

function RemoteFunction.Home_OnGetBuyLandConditions(tConditions, dwMapID, nCopyIndex, nLandIndex)
    Event.Dispatch("Home_OnGetBuyLandConditions", tConditions, dwMapID, nCopyIndex, nLandIndex)
end

function RemoteFunction.Home_OnGetPrivateHomeCons(tConditions, dwMapID)
    Event.Dispatch("Home_OnGetPrivateHomeCons", tConditions, dwMapID)
end

function RemoteFunction.Home_OnGetPSubLandCons(tConditions, dwMapID)
    Event.Dispatch("Home_OnGetPSubLandCons", tConditions, dwMapID)
end

function RemoteFunction.HomeLandUpdateGrass(nGrass)
    HomelandEventHandler.UpdateGrass(nGrass)
end

function RemoteFunction.HomeLandGrasseEffectFurniture(nGrasseEffectFurniture)
    HomelandEventHandler.UpdateGrasseEffectFurniture(nGrasseEffectFurniture)
end

function RemoteFunction.HomeLandGetObjectTPCoord(nLandIndex, nInstID)
    LandObject_GetObjectTPPos(nLandIndex, nInstID)
end

function RemoteFunction.On_HL_GetDwellerCallUpCount(nCount)
    Event.Dispatch("On_HL_GetDwellerCallUpCount", nCount)
end

function RemoteFunction.EnterMahjongGame(tData)
    if tData and next(tData) then
        MahjongData.OnEnterMahjongGame(tData)
    end
end

function RemoteFunction.PlayDice()
    MahjongData.PlayDice()
end

function RemoteFunction.AddPlayerMahjongGame(tData)
    if tData and next(tData) then
        MahjongData.OnAddPlayerMahjongGame(tData)
    end
end

function RemoteFunction.HomeLand_Mahjong_PlayerLeave(tData)
    -- {{nPlayerID, nDirection},{nPlayerID, nDirection}}
    if tData and tData[1] then
        MahjongData.PlayerLeave(tData)
    end
end

function RemoteFunction.On_CloseHomelandLocker()
    if not UIMgr.GetView(VIEW_ID.PanelHalfWarehouse) then
        return
    end

    Event.Dispatch(EventType.OnCloseHomelandLocker)
end

-- 家园-大唐家园相关-结束

-----------------家园身份相关-------------------

--身份总览更新
function RemoteFunction.OnHLIdentityUpdate()
    Event.Dispatch(EventType.OnHomelandIdentityUpdate)
    -- HLIdentity.Update()
end

function RemoteFunction.On_FindYouShang()
    local player = GetClientPlayer()
    if not player or IsRemotePlayer(player.dwID) then
        return
    end
    UIMgr.Open(VIEW_ID.PanelMerchant)
end

--身份升级提示
function RemoteFunction.OnHLIdentityLevelUp(dwID, nLevel)
    -- HLIdentityLevelUp.Open(dwID, nLevel)
    if dwID == HLIDENTITY_TYPE.FISH and nLevel == 2 then
        Storage.HLIdentity.bIsAutoGetFish = true
        local scriptFishView = UIMgr.GetViewScript(VIEW_ID.PanelFish)
        if scriptFishView then
            scriptFishView:SetAutoFishing(Storage.HLIdentity.bIsAutoGetFish)
        end
    end
    Event.Dispatch(EventType.OnHomelandIdentityUpdate)
    HomelandIdentity.UpdatePanelHomeOrderInfo()
end

--身份奖励
function RemoteFunction.OnGetHLIdentityReward(dwID, dwRewardID)
    -- IdentityRewardList.OnGetReward(dwID, dwRewardID)
end

--刷新订单
function RemoteFunction.On_Flower_RefreshOrder()
    HomelandIdentity.UpdatePanelHomeOrderInfo()
end

--完成花匠订单
function RemoteFunction.On_Flower_CompleteOrder(nIndex, dwID)
    HomelandIdentity.UpdatePanelHomeOrderInfo()
    Event.Dispatch(EventType.OnHomelandIdentityUpdate)
    -- OrderPanel.OnFinishOrder(nIndex, dwID, HLORDER_TYPE.FLOWER)
    -- OrderMessage.OnCompleteOrder(nIndex, dwID, HLORDER_TYPE.FLOWER)
end

--发布协助订单
function RemoteFunction.On_Flower_PublishAssist(dwID, nMoney)
    HomelandIdentity.UpdatePanelHomeOrderInfo()

    local szName = PlayerData.GetClientPlayer().szName
    local aAllMyOwnHomeData, aAllPrivateHomeData = HomelandData.GetAllMyLandInfo()

    if aAllMyOwnHomeData and not table.is_empty(aAllMyOwnHomeData) then
        local tbInfo = aAllMyOwnHomeData[1]
        ChatHelper.SendLandToChat(tbInfo.nIndex, tbInfo.nMapID, tbInfo.nCopyIndex, tbInfo.nLandIndex)
    elseif aAllPrivateHomeData and not table.is_empty(aAllPrivateHomeData) then
        local tbInfo = aAllPrivateHomeData[1]
        ChatHelper.SendPrivateLandToChat(tbInfo.nSkinID or 0, tbInfo.nMapID, tbInfo.nCopyIndex)
    end

    ChatHelper.SendHomelandOrderToChat(dwID, nMoney, szName)
end

--完成协助订单
function RemoteFunction.On_Flower_AssistOrder()
    HomelandIdentity.UpdatePanelHomeOrderInfo()
    -- OrderMessage.OnCompleteAssist()
end

--取消协助订单
function RemoteFunction.On_Flower_CancelAssist()
    HomelandIdentity.UpdatePanelHomeOrderInfo()
end

--完成帮会订单
function RemoteFunction.On_Tong_CompleteOrder(nIndex, dwID, nTimes)
    HomelandIdentity.UpdatePanelHomeOrderInfo()
    HomelandIdentity.On_Tong_CompleteOrder(nIndex, dwID, nTimes)
    -- OrderPanel.OnFinishTongOrder(nIndex, dwID, nTimes)
    -- OrderMessage.OnCompleteTongOrder()
end

--获取帮会订单
function RemoteFunction.On_Tong_GetOrder(tInfo)
    HomelandIdentity.On_Tong_GetOrder(tInfo)
end

--完成掌柜订单
function RemoteFunction.On_Cook_CompleteOrder(nIndex, dwID)
    HomelandIdentity.UpdatePanelHomeOrderInfo()
end

--修改推车食物
function RemoteFunction.On_Cook_UpdateFoodList()
    Event.Dispatch(EventType.OnFoodCartUpdateFoodList)
end

-- 香水制作
function RemoteFunction.On_Perfume_GetMaterial(tInfo, nType)
    Event.Dispatch(EventType.OnHomeGetPerfumeMaterialInfo, tInfo, nType)
end

function RemoteFunction.On_Perfume_GetResult(tItem)
    Event.Dispatch(EventType.OnPerfumeGetAwardResult, tItem)
	Event.Dispatch(EventType.OnHomelandIdentityUpdate)	-- 顺便更新身份界面
end

-- 钓鱼展示与鱼图鉴

function RemoteFunction.On_GetFish_Open(tFish, nExp)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHomeFishGet)
    if scriptView then
        scriptView:UpdateInfo(tFish, nExp)
        return
    end
    if Storage.HLIdentity.bIsAutoGetFish then
        HomelandFishingData.OnAutoGetFish(tFish, nExp)
        return
    end
    UIMgr.Open(VIEW_ID.PanelHomeFishGet, tFish, nExp)
end

function RemoteFunction.On_FishHolder_Check(tItem)
    if tItem.nType == 1 then
        Event.Dispatch(EventType.OnGetFishGainRecordTips, tItem)
    else
        Event.Dispatch(EventType.OnUpdateFishNoteHolderInfo, tItem)
    end
end

--放生鱼
function RemoteFunction.OnReleaseFish()
    Event.Dispatch(EventType.OnUpdateFishBagInfo)
end

--卖鱼
function RemoteFunction.OnSellFish()
    Event.Dispatch(EventType.OnUpdateFishBagInfo)
end

--家园管家界面
--有问题找老徐~
function RemoteFunction.On_NPCServant_LevelUpSkill(ServantID, bSuccess, nSkillID, nNewLevel)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.UpdateLevelBySkillID(nSkillID, nNewLevel)
    end
end

function RemoteFunction.On_NPCServant_Open(tReturn)
    UIMgr.Close(VIEW_ID.PanelHalfBag)
    UIMgr.Open(VIEW_ID.PanelHouseKeep, tReturn)
end

function RemoteFunction.On_NPCServant_Close()
    UIMgr.Close(VIEW_ID.PanelHouseKeep)
end

function RemoteFunction.On_NPCServant_UnLoadSkill(ServantID, bSuccess, nSkillID)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.UnloadSkillBySkillID(nSkillID)
    end
end

function RemoteFunction.On_NPCServant_LoadSkill(ServantID, bSuccess, nSkillID)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.LoadSkillBySkillID(nSkillID)
    end
end

function RemoteFunction.On_NPCServant_UseSkill(ServantID, bSuccess, nSkillID)

end

--替换技能
function RemoteFunction.On_NPCServant_SwitchSkill(ServantID, bSuccess, nOldSkillID, nNewSkillID)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.ReplaceSkillBySkillID(nOldSkillID, nNewSkillID)
    end
end

function RemoteFunction.On_NPCServant_ReSetTalent(ServantID, bSuccess, nSkillID)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.ResetTalentBySkillID(nSkillID)
    end
end

function RemoteFunction.On_NPCServant_LevelUp(ServantID, bSuccess, tReturn)
    if HouseKeeperData.RemoteCallCheckThenAction(ServantID, bSuccess) then
        HouseKeeperData.UpgradeServant(tReturn)
    end
end

local function ItemInfos2ItemMsgString(tItemInfos)
    local tItemMsgString  = {}
    for k, tSingleItem in pairs(tItemInfos) do
        local dwTabType, dwIndex = tSingleItem.dwTabType, tSingleItem.dwIndex
        local KItemInfo = GetItemInfo(dwTabType, dwIndex)
        local szItemMsgString = string.format("<text>text=\"%s\" </text>",
            GetFormatText("["..UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(KItemInfo)).."]", 166, GetItemFontColorByQuality(KItemInfo.nQuality, false)))
        table.insert(tItemMsgString, szItemMsgString)
    end

    return tItemMsgString
end

function RemoteFunction.OnItemMessageBoxRequest(nMessageID, tItemInfos, szMessage, szOKText, szCancelText, param1, nOK, nCancel)
    szMessage = UIHelper.GBKToUTF8(szMessage)
    local tItemMsgString = ItemInfos2ItemMsgString(tItemInfos)
    local szFomattedMsg = FormatLinkString(szMessage, "font=162", unpack(tItemMsgString))
    szFomattedMsg = ParseTextHelper.ParseNormalText(szFomattedMsg, false)

    UIHelper.ShowConfirm(szFomattedMsg, function ()
        RemoteCallToServer("OnMessageBoxRequest", nMessageID, true, param1)
    end, function ()
        RemoteCallToServer("OnMessageBoxRequest", nMessageID, false, param1)
    end, true)
end

-------------------------------------------------------------------
--试炼之地
-------------------------------------------------------------------
function RemoteFunction.On_Trial_OpenCChoose(nLevel, tbData, nTotalScore)
    CrossingData.OpenChoosePanel(nLevel , tbData , nTotalScore)
end

function RemoteFunction.On_Trial_CloseCChoose()
    CrossingData.CloseChoosePanel()
end

function RemoteFunction.On_Trial_OpenCProcess(tData)
    CrossingData.OpenProcessPanel(tData)
end

function RemoteFunction.On_Trial_CloseCProcess()
    CrossingData.CloseProcessPanel()
end

function RemoteFunction.On_Trial_Mission_Complete()
    CrossingData.MissionComplete()
end

function RemoteFunction.On_Trial_Mission_Failed()
    CrossingData.MissionFailed()
end

function RemoteFunction.On_Trial_Screen_Black()
    if not UIMgr.IsViewOpened(VIEW_ID.PanelTransition) then
        UIMgr.Open(VIEW_ID.PanelTransition)
    end
    CrossingData.ScreenBlack()
end

function RemoteFunction.On_Trial_OpenCFinish(tData, nXiuWei, bVisible)
    CrossingData.OpenFinishPanel(tData, nXiuWei, bVisible)
end

function RemoteFunction.On_Trial_CloseCFinish()
    CrossingData.CloseFinishPanel()
end

function RemoteFunction.On_Trial_FlopCardReturn(tbData, nWeekRemainCard, bFirstPass, nLevelRemainCard)
    Event.Dispatch(EventType.On_Trial_FlopCardReturn , tbData, nWeekRemainCard, bFirstPass, nLevelRemainCard)
end

function RemoteFunction.On_Trial_OpenMobileHelpTips(tData)
    CrossingData.OpenMobileHelpTips(tData)
end

function RemoteFunction.On_Activity_OpenFlopCard(nType)
    -- 目前暂定翻牌是试炼之地
    if nType == 1 then
        CrossingData.OpenFlopCard(nType)
    end
end

function RemoteFunction.On_Activity_FlopCardReturn(tDate, nType)
    if nType == 3 then
        -- 其他卡牌
    else
        Event.Dispatch(EventType.On_Activity_FlopCardReturn , tDate, nType)
    end
end

function RemoteFunction.On_Trial_InitCChooseReturn(tLevelData)
    if CrossingData.tbTestPlaceData then
        CrossingData.tbTestPlaceData.tbLevelData = tLevelData
    end
    Event.Dispatch(EventType.On_Trial_InitCChooseReturn , tLevelData)
end
-------------------------------------------------------------------
--试炼之地
-------------------------------------------------------------------

-- 增加喜爱宠物
-- RemoteCallToClient(player.dwID, "On_FellowPet_AddPreferPet", nPetIndex)
function RemoteFunction.On_FellowPet_AddPreferPet(nPetIndex)
    FireUIEvent("ADD_PREFER_FELLOW_PET", nPetIndex)
end

-- 删除喜爱宠物
function RemoteFunction.On_FellowPet_DelPreferPet(nPetIndex)
    FireUIEvent("DEL_PREFER_FELLOW_PET", nPetIndex)
end

function RemoteFunction.On_Fellow_Pet_DateUpdate(dwPetIndex, dwMedalIndex, dwPageID)
    FireUIEvent("ON_FELLOW_PET_DATEUPDATAE", dwPetIndex, dwMedalIndex, dwPageID)
end

function RemoteFunction.On_DaXiaZhiLu_GetSubModuleGift()
    FireUIEvent("On_DaXiaZhiLu_GetSubModuleGift")
end

function RemoteFunction.On_DaXiaZhiLu_RestartSubModule()
    TipsHelper.ShowNormalTip(g_tStrings.RoadChivalrous.STR_RESTART_SUBMODULE)
end

function RemoteFunction.On_DaXiaZhiLu_AcceptSubModule()
    TipsHelper.ShowNormalTip(g_tStrings.RoadChivalrous.STR_ACCPET_SUBMODULE)
end

function RemoteFunction.GetMailCount(dwItemIndex)
    local nUnread, nTotal, nSysUnRead, nsysTotal = GetMailClient().CountMail()
    RemoteCallToServer("On_MailNumber_All", nTotal, dwItemIndex)
end

function RemoteFunction.OnActionBarSkillReplace(nOldSkillID, nNewSkillID, nNewSkillLevel)
    FireUIEvent("ON_ACTIONBAR_SKILL_REPLACE", nOldSkillID, nNewSkillID, nNewSkillLevel)
end

function RemoteFunction.On_LangkexingM_OpenStorehouse(tbtCurrentItem)
    UIMgr.Open(VIEW_ID.PanelWarehouse, tbtCurrentItem)
end

function RemoteFunction.On_LangkexingM_RefreshStore(tbtCurrentItem)
    FireUIEvent("On_LangkexingM_RefreshStore", tbtCurrentItem)
end

--寻宝
function RemoteFunction.OnJudgeHaveDigItem(bHave)
    if not bHave then
        FireUIEvent("ON_NOT_HAVE_DIG_ITEM")
    end
end

function RemoteFunction.OnHoroSysDataUpdate(tHoroSysData)
    Event.Dispatch("ON_HORO_SYS_DATA_UPDATE",tHoroSysData)
end

function RemoteFunction.OpenCompassPanel()
    Event.Dispatch(EventType.OnTogCompass,true)
end

function RemoteFunction.OpenSpringCompass()
    Event.Dispatch(EventType.OnTogCompass, not g_bCompassVisible)
end

function RemoteFunction.OnXunbaoAskForDigCount(nLevel, nCount)
    FireUIEvent("ON_XUNBAO_GET_FOR_DIG_COUNT", nLevel, nCount)
end

function RemoteFunction.UpdatePartyDigCount(nDigCount)
    FireUIEvent("ON_XUNBAO_GET_PARTY_DIG_COUNT", nDigCount)
end

function RemoteFunction.OnExchangeEquipBackUp(nResult)
    FireUIEvent("EQUIP_CHANGE", nResult)
end

-- RemoteCallToClient(player.dwID, "SceneSfx", "Insert", {key = "WIZARD_VISIABLE_OPEN", sfxid = "WIZARD_VISIABLE_OPEN", px =  - 0.5, py =  - 0.2, pw = 2.0, ph = 1.4, loop = false})
-- RemoteCallToClient(player.dwID, "SceneSfx", "Delete", "WIZARD_VISIABLE_OPEN")
function RemoteFunction.SceneSfx(szAct, opt)
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelSceneSfx)
    if not viewScript then
        viewScript = UIMgr.Open(VIEW_ID.PanelSceneSfx)
    end

    if szAct == "Insert" then
        viewScript:AddSfx(opt)
    elseif szAct == "Delete" then
        viewScript:RemoveSfx()
    end
end

function RemoteFunction.Homeland_OpenLocalBuilding()
    UIMgr.CloseAllInLayer("UIPageLayer")
    UIMgr.CloseAllInLayer("UIPopupLayer")

    Timer.Add(RemoteFunction, 2, function ()
        HLBOp_Main.Enter(BUILD_MODE.TEST)
    end)
end

function RemoteFunction.HomelandUpgradeResult(dwMapID, nCopyIndex, nLandIndex, nCode, nCurrLevel, nOldLevel)
    HomelandEventHandler.HomelandUpgradeResult(dwMapID, nCopyIndex, nLandIndex, nCode, nCurrLevel, nOldLevel)
end

function RemoteFunction.OnServerOpenBanishPanel(nSecond, szReason, bDisableSound, szTongName)
    BANISH_CODE.NOT_IN_MAP_OWNER_TONG_DIF = 101
    Global.OnBanishPlayer(BANISH_CODE.NOT_IN_MAP_OWNER_TONG_DIF, nSecond, szTongName)
end

function RemoteFunction.PlayerLoginScriptFinish()
    LOG.INFO("RemoteFunction.PlayerLoginScriptFinish")
    FireUIEvent("LOGIN_SCRIPT_FINISH")
end

function RemoteFunction.OnSetViewRespond()
    LOG.INFO("RemoteFunction.OnSetViewRespond")
    TurnToFaceDirection()
end

function RemoteFunction.OnCreateWebTokenRespond(tKey)
    LOG.INFO("RemoteFunction.OnCreateWebTokenRespond")
    --Output(tKey)
end

function RemoteFunction.OnSkillReplace(nOldSkillID, nNewSkillID, nNewSkillLevel, dwOrgSkillID)
    LOG.INFO("RemoteFunction.OnSkillReplace")
    FireUIEvent("ON_SKILL_REPLACE", nOldSkillID, nNewSkillID, nNewSkillLevel, dwOrgSkillID)
end

function RemoteFunction.On_Recharge_CloseSpeedRankPanel()
    LOG.INFO("RemoteFunction.On_Recharge_CloseSpeedRankPanel")
    -- SpeedRankPanel.Close()
end

function RemoteFunction.On_Recharge_CloseFBTimeRank()
    LOG.INFO("RemoteFunction.On_Recharge_CloseFBTimeRank")
    -- FBTimeRank.Close()
end

function RemoteFunction.OnSyncStoredGmAnnouncement(tGmAnnouncement)
    LOG.INFO("RemoteFunction.OnSyncStoredGmAnnouncement")
    -- for k, v in ipairs(tGmAnnouncement) do
    -- 	local argSave0 = arg0
    -- 	local argSave1 = arg1
    -- 	arg0 = v[2]
    -- 	arg1 = v[1]
    -- 	FireEvent("CHANNEL_GM_ANNOUNCE")
    -- 	arg0 = argSave0
    -- 	arg1 = argSave1
    -- end
end

function RemoteFunction.OnSpecialActiveStateRespond(tActiveList)
    FireUIEvent("ON_SPECIAL_ACTIVE_STATE_RESPOND", tActiveList)
end

--攻防 挂机太久加Buff
function RemoteFunction.AddRRCXBuffInCastle(nType)
    local tBuffList = {
        [1] = {8807, 1, 2},
        [2] = {10305, 1, 5},
    }
    nType = nType or 1
    if not tBuffList[nType] then
        return
    end
    local nBuffId = tBuffList[nType][1]

    local player = GetClientPlayer()
    if not player or not nBuffId then
        return
    end

    --TODO luwenhao1 GetIdleTime
    -- local nTime = Station.GetIdleTime()
    -- if nTime >= 5000 * 60 then
    -- 	if Buff_Have(player, nBuffId, 0)then
    -- 		return
    -- 	end
    -- --	OutputMessage("MSG_SYS", nTime .. "----------!!!!!\n")
    -- 	RemoteCallToServer("On_Castle_AddRRCXBuff", nType)
    -- end
end

function RemoteFunction.SetPendentBoxSize()
    LOG.INFO("RemoteFunction.SetPendentBoxSize()")
end

function RemoteFunction.StartFilterMask()
    LOG.INFO("RemoteFunction.StartFilterMask()")
end

local _torgvalue = {}
function RemoteFunction.CallGuardFun(setname, getname, ...)
    LOG("RemoteFunction.CallGuardFun(%s, %s)", setname, getname)
    if not _torgvalue[setname] then
        local t = {CallGlobalFun(getname)}
        _torgvalue[setname] = t
    end

    CallGlobalFun(setname, ...)
end

function RemoteFunction.RestoreGuard(setname)
    LOG("RemoteFunction.RestoreGuard(%s)", setname)
    if _torgvalue[setname] and type(_torgvalue[setname]) == "table" then
        CallGlobalFun(setname, unpack(_torgvalue[setname]))
        _torgvalue[setname] = nil
    end
end

local _cameraDis
function RemoteFunction.SetCameraDistance(fScale)
    local fOrgScale, fYaw, fPitch = Camera_GetRTParams()
    if not _cameraDis then
        _cameraDis = fOrgScale
    end
    Camera_SetRTParams(fScale, fYaw, fPitch)
end

function RemoteFunction.RestoreCameraDistance()
    if _cameraDis then
        local _, fYaw, fPitch = Camera_GetRTParams()
        Camera_SetRTParams(_cameraDis, fYaw, fPitch)
        _cameraDis = nil
    end
end

local _fSaveMaxCameraDistance
function RemoteFunction.SetMaxCameraDistance(fMaxDistance)
    if not _fSaveMaxCameraDistance then
        _fSaveMaxCameraDistance = CameraMgr.GetMaxDistance()
    end
    CameraMgr.SetMaxDistance(fMaxDistance)
end

function RemoteFunction.RestoreMaxCameraDistance()
    if not _fSaveMaxCameraDistance then
        return
    end

    CameraMgr.SetMaxDistance(_fSaveMaxCameraDistance)
    _fSaveMaxCameraDistance = nil
end

function RemoteFunction.CameraStatus(act, opt)
    if act == "Set" then
        CameraMgr.Status_Set(opt)
    elseif act == "Push" then
        CameraMgr.Status_Push(opt)
    elseif act == "Forward" then
        CameraMgr.Status_Forward(opt and opt.nStep)
    elseif act == "Backward" then
        CameraMgr.Status_Backward(opt and opt.nStep, opt)
    end
end

function RemoteFunction.CameraLockCHAndGJ(bLock, nMaxCameraDistance, nCameraAngle)
    LOG.INFO("RemoteFunction.CameraLockCHAndGJ(%s, %s, %s)", tostring(bLock), tostring(nMaxCameraDistance), tostring(nCameraAngle))
	CameraMgr.SetLockCHAndGJ(bLock, nMaxCameraDistance, nCameraAngle)
end

function RemoteFunction.OnCameraLockTarget(dwTargetID, nConfigID, nPriority, bIgnoreMoveStateLimit)
	CameraMgr.LockTarget(dwTargetID, nConfigID, nPriority, bIgnoreMoveStateLimit)
end

function RemoteFunction.SetEquipIDArray()
    LOG.INFO("RemoteFunction.SetEquipIDArray()")
end

--[[
    传入参数范围： [0, 255]
    转换后参数范围： [0.5*PI, -1.5*PI]，也可理解为[0, 2*PI]
--]]
function RemoteFunction.OnChangeCameraYaw(nAngle)
    --local fCameraToObjectEyeScale, _, fPitch = Camera_GetRTParams()
    local nDirection = (0.5  - nAngle / 128) * math.pi
    --Camera_SetRTParams(fCameraToObjectEyeScale, nDirection, fPitch)
    Camera_SetYaw(nDirection)
end

--[[
    传入参数范围： [0, 128]
    转换后参数范围： [0.5*PI, -0.5*PI]
--]]
function RemoteFunction.OnChangeCameraPitch(nAngle)
    nAngle = math.min(128, math.max(nAngle, 0))
    local fCameraToObjectEyeScale, fDirection, _ = Camera_GetRTParams()
    local fPitch = (0.5 - nAngle / 128) * math.pi
    Camera_SetRTParams(fCameraToObjectEyeScale, fDirection, fPitch)
end

function RemoteFunction.OnCheckPlayerCameraAngle(dwCannonID)
    local fCameraToObjectEyeScale, nCurrentAngle,fPitch = Camera_GetRTParams()
    local nCurrentDirection = (0.5 * 3.1416 - nCurrentAngle) / 3.1416 * 128
    RemoteCallToServer("On_Cannon_CheckCameraAngle",nCurrentDirection,dwCannonID,fCameraToObjectEyeScale,fPitch)
end

function RemoteFunction.SetDungeonEnvPresetByVideoLevel()
    LOG.INFO("RemoteFunction.SetDungeonEnvPresetByVideoLevel()")
end

-- 结算界面
function RemoteFunction.On_MonsterBook_OpenSettlement(tInfo, bCanDistribute)
    UIMgr.Open(VIEW_ID.PanelBaizhanSettlement, tInfo, bCanDistribute)
end
-- 个人技能分配
function RemoteFunction.On_MonsterBook_Distribute(bOpen, tInfo)
    if bOpen then
        UIMgr.Open(VIEW_ID.PanelBZSkillDistribute, false, tInfo)
    else
        UIMgr.Close(VIEW_ID.PanelBZSkillDistribute)
    end
end
-- 团队技能分配
function RemoteFunction.On_MonsterBook_MultiDistribute(bOpen, tInfo)
    if bOpen then
        UIMgr.Open(VIEW_ID.PanelBZSkillDistribute, true, tInfo)
    else
        UIMgr.Close(VIEW_ID.PanelBZSkillDistribute)
    end
end
-- 团队技能快速分配
function RemoteFunction.On_MonsterBook_QuickDistribute(tInfo)
    -- MonsterDistribute.QuickDistribute(tInfo)
end

-- 秘籍选择
function RemoteFunction.On_MonsterBook_OpenBuff(nBookIndex, nSum)
    Timer.Add(RemoteFunction, 3, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelTutorialLite) then
            UIMgr.Open(VIEW_ID.PanelBaizhanChooseBuff, nBookIndex, nSum)
        else
            UIMgr.SetCloseCallback(VIEW_ID.PanelTutorialLite, function ()
                UIMgr.Open(VIEW_ID.PanelBaizhanChooseBuff, nBookIndex, nSum)
            end)
        end
    end)
end

function RemoteFunction.On_LevelChoose_Open()
    LOG.INFO("RemoteFunction.On_LevelChoose_Open()")
end

-- 层数选择-打开界面
function RemoteFunction.On_MonsterEntrance_Open(bOpen, tInfo)
    if bOpen then
        UIMgr.Open(VIEW_ID.PanelLevelChoose, tInfo)
    else
        UIMgr.Close(VIEW_ID.PanelLevelChoose)
        UIMgr.Close(VIEW_ID.PanelLevelChooseResultPop)
    end
end
-- 层数选择-随机跃迁确认
function RemoteFunction.On_MonsterBook_GuessConfirm(nCurrentLevel, nGuessRange)
    Event.Dispatch(EventType.OnMonsterBookChooseLevelStep, 1, nCurrentLevel, nGuessRange)
end
-- 层数选择-投骰子
function RemoteFunction.On_MonsterBook_Roll(nResult1, nResult2, nHelpGuess)
    Event.Dispatch(EventType.OnMonsterBookChooseLevelStep, 2, nResult1, nResult2, nHelpGuess)
end
-- 层数选择-走步
function RemoteFunction.On_MonsterBook_Jump(nBegin, nEnd, nSpeed)
    Event.Dispatch(EventType.OnMonsterBookChooseLevelStep, 3, nBegin, nEnd, nSpeed)
end
-- 层数选择-显示预测结果
function RemoteFunction.On_MonsterBook_ShowEffect(tParam)
    Event.Dispatch(EventType.OnMonsterBookChooseLevelStep, 4, tParam)
end
-- 精神耐力
function RemoteFunction.On_SpiritEndurance_Open(bOpen)
    -- if bOpen then
    -- 	SpiritEndurancePanel.Open("SELF")
    -- else
    -- 	SpiritEndurancePanel.Close("SELF")
    -- end
end

function RemoteFunction.On_MonsterTeach_MBOpen(nID)
    LOG.INFO("RemoteFunction.On_MonsterTeach_MBOpen="..tostring(nID))
    UIMgr.Open(VIEW_ID.PanelTutorialLite, nID)
end

function RemoteFunction.ChangeSkillSurfaceNum(dwSkillID, nNum)
	FireUIEvent("CHANGE_SKILL_SURFACE_NUM", dwSkillID, nNum)
end

--- 拍团分配
function RemoteFunction.On_Team_TeamersPay(tPays)
    FireUIEvent("ON_SYNC_TEAMERS_PAY", tPays)
end

function RemoteFunction.On_Team_BidRule(tRule)
    FireUIEvent("ON_SYNC_BID_RULE", tRule)
end

function RemoteFunction.On_Team_TeamMoney(tPays)
    FireUIEvent("ON_SEND_TEAM_MONEY", tPays)
end

function RemoteFunction.On_Team_RecvDeletedRecords(aBidInfoIndicesToDelete)

end

--捐钱
function RemoteFunction.On_Team_ExtraMoney(playerid, dwMoney, szReason)
    FireUIEvent("ON_TEMA_EXTRAMONEY", playerid, dwMoney, szReason)
end

function RemoteFunction.On_Team_AuctionLog(tAucionLog)
    FireUIEvent("ON_TEMA_SYNC_RECORD", tAucionLog)
end

function RemoteFunction.OnOpenTongFarmPanel(dwNpcID, bEmpty, dwOwnerID, nHealth, nMature, nSeedItemID, nSoilLevel, nSoilExperience)
    ---@type UIFactionPlantingView
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelFactionPlanting)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelFactionPlanting)
    end

    scriptView:OnEnter(dwNpcID, bEmpty, dwOwnerID, nHealth, nMature, nSeedItemID, nSoilLevel, nSoilExperience)
end

-- 打开帮会天工树面板
function RemoteFunction.OnOpenTongTechTreePanel(dwNpcID)
    ---@type UIPanelTongManager
    local script              = UIMgr.GetViewScript(VIEW_ID.PanelFactionManagement) or UIMgr.Open(VIEW_ID.PanelFactionManagement)

    local nTechTreeMainTab   = 3
    local nSubTab = 1

    Event.Dispatch("Tong_SwitchTab", nTechTreeMainTab, nSubTab)
end

-- 入帮申请红点提示
function RemoteFunction.On_Tong_ApplyJoinRequestMaster()
    FireEvent("ON_APPLICATION_TO_TONG_READ_MSG")
end

function RemoteFunction.On_Tong_GetTongMap(nMapFlag)
    -- 0为没有领地，1为拥有领地，2为拥有过但被系统收回
    TongData.bIsDemesnePurchased = nMapFlag == 1
end

function RemoteFunction.OnActivityPasswordResult(szResult)
    TipsHelper.ShowNormalTip(g_tStrings.tActivityPasswordResult[szResult])
end

function RemoteFunction.GetSeaSonHighestRankScore(playerid, t)
    Event.Dispatch(EventType.OnUpdateArenaSeasonHighestRankScore, playerid, t)
end

--江湖百态
function RemoteFunction.GetIdentityArtistSkill(tArtistSkill)
    JiangHuData.tArtistSkill = tArtistSkill
end

function RemoteFunction.DisplayArtistSkillConfigure() --艺人技能配置未配置
    Timer.Add(RemoteFunction, 0.5, function()
        JiangHuData.InitInfo()
        local tbScript = UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, 1)
        tbScript:ShowArtistSkillConfig()
    end)
end

function RemoteFunction.OpenIdentityDynActBar(dwID) --开启身份
    JiangHuData.tbIdentitySkills = {}
    JiangHuData.UpdateCurIdentitySkill(dwID)
end

function RemoteFunction.CloseIdentityDynActBar() --关闭身份
    IdentitySkillData.OnSwitchDynamicSkillStateBySkills()
    Event.Dispatch("SHOW_CLOSE_IDENTITYBTN")
end

function RemoteFunction.OpenIdentityDynamicBar(nIdentityID, tSkills) --打开艺人技能
    JiangHuData.bIsArtist = true
    JiangHuData.nCurActID = nIdentityID
    Timer.AddFrame(RemoteFunction, 5, function()
        JiangHuData.tbIdentitySkills = {}
        table.insert(JiangHuData.tbIdentitySkills, {id = 16176, level = 1})
        local tbSkills = {CanCastSkill = true, canuserchange = false, tbSkilllist = JiangHuData.tbIdentitySkills}
        IdentitySkillData.OnSwitchDynamicSkillStateBySkills(tbSkills)
    end)
    Event.Dispatch("ON_ADDORDEL_ARTISTSKILLPANEL",true)
    Event.Dispatch("ON_HIDEORSHOW_SKILLPANEL", false)
    if QTEMgr.CanUserChange() then
        if QTEMgr.IsInDynamicSkillStateBySkills() then
            QTEMgr.OnSwitchDynamicSkillStateBySkills()
        else
            QTEMgr.ExitDynamicSkillState()
        end
    end
    --屏蔽所有交互按钮
    Event.Dispatch(EventType.OnInteractChangeVisible, false)
end

function RemoteFunction.SendIdentityArtistSkill()
    RemoteCallToServer("On_Identity_ArtistSkill", Storage.ArtistSkills.tbSkillList)
end

function RemoteFunction.CloseIdentityDynamicBar() --关闭动态技能
    JiangHuData.bIsArtist = false
    JiangHuData.tbIdentitySkills = {}
    Event.Dispatch("ON_HIDEORSHOW_SKILLPANEL", true)
    Event.Dispatch("ON_ADDORDEL_ARTISTSKILLPANEL", false)
    --恢复所有交互按钮
    Event.Dispatch(EventType.OnInteractChangeVisible, true)
end

function RemoteFunction.OpenIdentityUpGrade(nIdentityID)
    JiangHuData.UpdateIdentityUpGrade(nIdentityID)
end

function RemoteFunction.On_VowTree_Request(nType, dwIndex, bWrite, szVowText, szVowName)
    UIMgr.Open(VIEW_ID.PanelJiXinYu, nType, dwIndex, bWrite, szVowText, szVowName)
end

function RemoteFunction.OpenArtistReward(dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID) --向艺人打赏
    if not UIMgr.IsViewOpened(VIEW_ID.PanelRewardPop) then
        UIMgr.Open(VIEW_ID.PanelRewardPop, dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID)
    else
        local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelRewardPop)
        tbScript:UpdateInfo(dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID)
    end
end

function RemoteFunction.UpdateArtistExperience(nCurValue, nMaxValue)
    Event.Dispatch("UPDATE_ARTIST_EXP", nCurValue, nMaxValue)
end

function RemoteFunction.On_Identity_GetFlowerRankList(dwRequestID)
    if not JiangHuData.tSendFellowRank then
        return
    end

    local tRank  = {}
    for k, v in pairs(JiangHuData.tSendFellowRank) do
        if k <= 10 then
            table.insert(tRank, v)
        end
    end

    RemoteCallToServer("On_Identity_FlowerRankRespond", tRank, dwRequestID)
end

function RemoteFunction.On_Identity_FlowerRankRespond(tRank)
    if UIMgr.IsViewOpened(VIEW_ID.PanelRewardPop) then
        Event.Dispatch("UPDATE_ARTIST_RANK", tRank)
    end
end

function RemoteFunction.OpenArtistRewardAmount(nFellowNum, nTimeSlot) --打开艺人接受打赏界面
    JiangHuData.nArtistStartTime = GetCurrentTime()
    --UIMgr.Open(VIEW_ID.PanelGiftMainPop, nFellowNum, nTimeSlot)
    Event.Dispatch("ON_SHOW_WIDGETGIFTPOP", nFellowNum, nTimeSlot)
end

function RemoteFunction.On_Identity_ClearArtistRank()
    JiangHuData.tSendFellowRank = nil
end

function RemoteFunction.UpdateArtistRewardAmount(nFellowNum, tRank)
    --打赏艺人收到消息提示
    JiangHuData.UpdateSortPlayers(tRank)
    JiangHuData.UpdateBubbleMsgData(nFellowNum)
    Event.Dispatch("UPDATE_REWARDS_INCREASE", nFellowNum, tRank)
    JiangHuData.ShowSendFellowTip(tRank)
end

function RemoteFunction.CloseArtistRewardAmount() --关闭艺人接受打赏界面
    Event.Dispatch("ON_HIDE_WIDGETGIFTPOP")
    BubbleMsgData.RemoveMsg("ArtistGiftTips")
end

function RemoteFunction.InviteGuardJoinTeam(szGuardName)
    if TeamData.CheckInSingleFB(true) then
        return
    end
    GetClientTeam().InviteJoinTeam(3, 0, szGuardName) --nType=3 表示向镖师发起组队
end

function RemoteFunction.On_BiaoShiRequest(nMessageID, szMessage, szOKText, szCancelText, param1)
    szMessage = UIHelper.GBKToUTF8(szMessage)
    szMessage = ParseTextHelper.ParseNormalText(szMessage)
    local szBubMessage = szName.." "..g_tStrings.STR_JH_GUARD_HIRE_PLAYER_BUBBLE
    BubbleMsgData.PushMsgWithType("BiaoshiInviteTips", {
        nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
        szContent = szBubMessage,
        szAction = function()
            local Dialog = UIHelper.ShowConfirm(szMessage, function ()
                RemoteCallToServer("OnMessageBoxRequest", nMessageID, true, param1)
            end, function ()
                RemoteCallToServer("OnMessageBoxRequest", nMessageID, false, param1)
            end, true)
            local szConfirm = szOKText and UIHelper.GBKToUTF8(szOKText)
            Dialog:SetButtonContent("Confirm", szConfirm)
            local szCancel = szCancelText and UIHelper.GBKToUTF8(szCancelText)
            Dialog:SetButtonContent("Cancel", szCancel)
        end}, szName)
end

function RemoteFunction.OpenGuardPanelSure(dwGuardID, tPlayer, nGuardLevel, nType)
    if nType == 1 then
        RemoteCallToServer("On_Identity_BiaoshiTrade", dwGuardID, nType, true)
    elseif nType == 2 then
        local szName = UIHelper.GBKToUTF8(tPlayer.szName)
        local szNum 	= g_tStrings.STR_NUMBER[nGuardLevel]
        local szGuard 	= FormatString(g_tStrings.STR_JH_LEVEL_GUARD, szNum)
        local szMessage = szGuard.." "..szName.." "..g_tStrings.STR_JH_GUARD_PROMPT_INFO2
        local szBubMessage = szGuard.." "..szName.." "..g_tStrings.STR_JH_GUARD_PROMPT_INFO_BUBBLE

        BubbleMsgData.PushMsgWithType("BiaoshiTradeTips", {
            nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
            szContent = szBubMessage,
            szAction = function()
                local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
                    RemoteCallToServer("On_Identity_BiaoshiTrade", dwGuardID, nType, true)
                    BubbleMsgData.RemoveMsgWithSrcPlayerName("BiaoshiTradeTips", szName)
                end, function ()
                    RemoteCallToServer("On_Identity_BiaoshiTrade", dwGuardID, nType, false)
                    BubbleMsgData.RemoveMsgWithSrcPlayerName("BiaoshiTradeTips", szName)
                end)
                confirmDialog:SetButtonContent("Confirm", "雇佣")
                confirmDialog:SetButtonContent("Cancel", "放弃")
            end}, szName)
    end

end

function RemoteFunction.OpenGuardInfo(dwID, szName, nCount, nCurValue, nMaxValue) --打开护镖信息
    JiangHuData.dwBiaoShiID = dwID
    JiangHuData.szBiaoShiName = UIHelper.GBKToUTF8(szName)
    JiangHuData.nBiaoShiCount = nCount
    JiangHuData.nBiaoShiCurValue = nCurValue
    JiangHuData.nBiaoShiMaxValue = nMaxValue
    local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    if tbScript then
        if JiangHuData.bFirstOpen then
            TipsHelper.ShowHuBiaoTip(JiangHuData.dwBiaoShiID, JiangHuData.szBiaoShiName, JiangHuData.nBiaoShiCount, JiangHuData.nBiaoShiCurValue, JiangHuData.nBiaoShiMaxValue)
            local nCount = UIHelper.GetChildrenCount(tbScript.WidgetGiftPop)
            if nCount > 0 then
                JiangHuData.bFirstOpen = false
            end
        elseif JiangHuData.scriptHuBiao then
            Event.Dispatch(EventType.ShowHuBiaoTip, JiangHuData.dwBiaoShiID, JiangHuData.szBiaoShiName, JiangHuData.nBiaoShiCount, JiangHuData.nBiaoShiCurValue, JiangHuData.nBiaoShiMaxValue)
        end
    end
end

function RemoteFunction.CloseGuardInfo() --关闭护镖信息
    Event.Dispatch("ON_HIDE_WIDGETHUBIAOPOP")
    BubbleMsgData.RemoveMsg("BiaoShiInfoTips")
    JiangHuData.bFirstOpen = true
end

function RemoteFunction.OpenGuardList(tGuradList) --打开我的镖师
    JiangHuData.tGuradList = tGuradList
    if JiangHuData.bFirstListOpen or JiangHuData.scriptBiaoShi then
        TipsHelper.ShowBiaoShiTip(JiangHuData.tGuradList)
    end
end

function RemoteFunction.CloseGuardList() --关闭我的镖师
    Event.Dispatch("ON_HIDE_WIDGETBIAOSHIPOP")
    BubbleMsgData.RemoveMsg("BiaoShiListTips")
    JiangHuData.bFirstListOpen = true
end

function RemoteFunction.Set3DOption(key, value)
    LOG.INFO("RemoteFunction.Set3DOption")
end

--local bOldPostEffectEnable
function RemoteFunction.EnableColorShift(bEnable) --true 开启偏色， false 关闭偏色 --功能已经换了接口
    LOG.INFO("RemoteFunction.EnableColorShift")
end

function RemoteFunction.SetColorShift(dwID) --1,2,3,4,5,6,7,8  设置偏色
    LOG.INFO("RemoteFunction.SetColorShift")
end

---注:需要保证Save3DOption 和 Restore3DOption 调用顺序,无法递归-----------
function RemoteFunction.Save3DOption(szkey)
    LOG.INFO("RemoteFunction.Save3DOption")
end

function RemoteFunction.Restore3DOption(szkey)
    LOG.INFO("RemoteFunction.Restore3DOption")
end

function RemoteFunction.EnterDdzGame(tData)
    if tData and next(tData) then
        local script = UIMgr.GetViewScript(VIEW_ID.PanelPokerMain)
        if script then
            script:OnEnter(tData)
        else
            UIMgr.Open(VIEW_ID.PanelPokerMain , tData)
        end
    end
end

function RemoteFunction.ChangeDdzRule(nRuleNum)
    Event.Dispatch(DdzPokerData.tbEventID.OnChangeDdzRule, nRuleNum)
end

function RemoteFunction.AddPlayerDdzGame(tPlayerInfo)
    if tPlayerInfo and next(tPlayerInfo) then
        Event.Dispatch(DdzPokerData.tbEventID.OnAddPlayer, tPlayerInfo)
    end
end
function RemoteFunction.HomeLand_Ddz_PlayerLeave(tData)

    if tData and tData[1] then
        for i = 1, #tData do
            Event.Dispatch(DdzPokerData.tbEventID.OnPlayerLeave, tData[i][2])
        end
    end
end

function RemoteFunction.CloseDdzInterface(tData)
    local view = UIMgr.GetViewScript(VIEW_ID.PanelPokerMain)
    if view then
        view:Close()
    end
end

function RemoteFunction.DdzPlay()
    Event.Dispatch(DdzPokerData.tbEventID.OnPlay)
end

function RemoteFunction.On_Freeze_End()
    Event.Dispatch("ON_FREEZE_END")
end

function RemoteFunction.CloseCampFlagResult(bResult, nLeftSeconds)
    if not g_pClientPlayer then
        return
    end

    if bResult then
        g_pClientPlayer.nCloseCampFlagTime = 0;
        if nLeftSeconds > 0 then
            local nCurrentTime = GetCurrentTime();
            g_pClientPlayer.nCloseCampFlagTime = nLeftSeconds + nCurrentTime;
        end
    end

    if nLeftSeconds == 0 or not bResult then
        Timer.DelTimer(RemoteFunction, RemoteFunction.nCloseCampTimerID)
        ChatData.Append(g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG_FAIL, 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SYS_MSG_CLOSE_CAMP_FALG_FAIL)
        BubbleMsgData.RemoveMsg("CloseCampModeTip")
        return
    end

    local nEndTime = GetCurrentTime() + nLeftSeconds
    APIHelper.nCampEndTime = nEndTime
    local nLastCountdownIndex = nil
    local COUNTDOWN_TIME = { 60 * 5, 60 * 4, 60 * 3, 60 * 2, 60, 30 }

    BubbleMsgData.RemoveMsg("CloseCampModeTip")
    BubbleMsgData.PushMsgWithType("CloseCampModeTip", {
        nTotalTime = 300,
        nStartTime = GetCurrentTime(),
        nEndTime = nEndTime,
        bHideTimeSilder = true,
        bShowTimeLabel = true,
        szAction = function()
            local nLeftTime = math.max(nEndTime - GetCurrentTime(), 0)
            local szTime = TimeLib.GetTimeText(nLeftTime)
            local szContent = FormatString(g_tStrings.STR_SYS_MSG_WAIT_CLOSE_CAMP_FLAG, szTime)
            TipsHelper.ShowNormalTip(szContent)
        end})

    Timer.DelTimer(RemoteFunction, RemoteFunction.nCloseCampTimerID)
    RemoteFunction.nCloseCampTimerID = Timer.AddCycle(RemoteFunction, 1, function()
        local nCurTime = GetCurrentTime()
        if nCurTime >= nEndTime then
            Timer.DelTimer(RemoteFunction, RemoteFunction.nCloseCampTimerID)
            BubbleMsgData.RemoveMsg("CloseCampModeTip")
            return
        end

        local nLeftTime = nEndTime - nCurTime
        for nIndex, nTime in ipairs(COUNTDOWN_TIME) do
            if nLeftTime <= nTime and COUNTDOWN_TIME[nIndex + 1] and nLeftTime > COUNTDOWN_TIME[nIndex + 1] then
                if nLastCountdownIndex ~= nIndex then
                    local szTime = TimeLib.GetTimeText(nTime)
                    local szContent = FormatString(g_tStrings.STR_SYS_MSG_WAIT_CLOSE_CAMP_FLAG, szTime)
                    OutputMessage("MSG_ANNOUNCE_YELLOW", szContent)
                    ChatData.Append(szContent, 0, PLAYER_TALK_CHANNEL.GM_ANNOUNCE, false, "")
                    nLastCountdownIndex = nIndex
                end
                break
            end
        end
    end)
end

function RemoteFunction.UpdateMengXinShow(bShowMX)
	ChatData.UpdateMengXinShow(bShowMX)
end

-- 点卡退款通知
function RemoteFunction.OnRefundNotify(strChannel, strOrderSN, strOrderTime, nRechargeType, nRechargePointsAmount, nRechargeRMBAmount, nLeftTimeOfPoint, nLeftTimeOfDays, nEndDate, dwEndTimeOfFee)
    -- strChannel               订单渠道
    -- strOrderSN               订单号
    -- strOrderTime             充值时间
    -- nRechargeType            充值类型：1-月卡，2-点卡，6-通宝
    -- nRechargePointsAmount    充值获得的增量（月卡延长的截止时间，点卡增加的剩余点数，增加的通宝）
    -- nRechargeRMBAmount       充值花费的人民币（元）
    -- nLeftTimeOfPoint         当前退款操作完成后，新的剩余点卡
    -- nLeftTimeOfDays          当前退款操作完成后，新的剩余天卡天数
    -- nEndDate                 当前退款操作完成后，新的月卡截止时间
    -- dwEndTimeOfFee           综合计费截止时间

    LOG.DEBUG(
        "[OnRefundNotify] Channel:%s OrderSN:%s OrderTime:%s nRechargeType:%d PointsAmount:%d RMBAmount:%d LeftTimeOfPoint:%d LeftTimeOfDays:%d, EndDate:%d, EndTimeOfFee:%d",
        strChannel, strOrderSN, strOrderTime, nRechargeType, nRechargePointsAmount, nRechargeRMBAmount, nLeftTimeOfPoint, nLeftTimeOfDays, nEndDate, dwEndTimeOfFee)

    Login_UpdateFeeTime(nLeftTimeOfPoint, nLeftTimeOfDays, nEndDate, dwEndTimeOfFee)

    PayData.ShowRefundTip(strChannel, strOrderSN, strOrderTime, nRechargeType, nRechargePointsAmount, nRechargeRMBAmount, nLeftTimeOfPoint, nLeftTimeOfDays, nEndDate, dwEndTimeOfFee)
end

function RemoteFunction.ActivityList_StartGuide(nLinkID, bForbidMapOpen, dwMapID, bUseKindName)
    local tLinkInfo = Table_GetCareerLinkNpcInfo(nLinkID, dwMapID)
    if tLinkInfo then
        local dwMapID = dwMapID or tLinkInfo.dwMapID
        local szText = UIHelper.GBKToUTF8(bUseKindName and tLinkInfo.szKind or tLinkInfo.szNpcName)
        MapMgr.SetTracePoint(szText, dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})
        UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
    end
end

function RemoteFunction.OnUserInput(szTitle, szInput, dwNpcID)
    UIMgr.Open(VIEW_ID.PanelOrangeUpgradePop, szTitle, szInput)
end

function RemoteFunction.OnUserInputNumber(szInput, nDefault, nMin, nMax, szSource)
    Event.Dispatch(EventType.OnUserInputNumber, szInput, nDefault, nMin, nMax, szSource)
end

function RemoteFunction.On_OpenPostCard(nID)
    UIMgr.Open(VIEW_ID.PanelPicScroll, nID)
end

function RemoteFunction.On_Mobie_HeroEquipChoose(szTitle, tbItemList)
    UIMgr.Open(VIEW_ID.PanelOptionalRewardPop, szTitle, tbItemList)
end

function RemoteFunction.AddQuickUseItem(dwTabType, dwIndex, bFirstPos)
    if ItemData.IsInQuickUseList(dwTabType, dwIndex) then
        ItemData.RemoveQuickUseList(dwTabType, dwIndex)
    end

    ItemData.AddQuickUseList(dwTabType, dwIndex, bFirstPos)
end

-- 礼品卡输入密码
-- RemoteCallToClient(player.dwID, "OpenFortunetellingPanel", dwTargetID, "请输入一个名字，将为你计算命运：")
function RemoteFunction.OpenFortunetellingPanel(dwTargetID, szTitle,dwIndex)
    local SendName = function(szName)
        szName = UIHelper.UTF8ToGBK(szName)
        if dwTargetID and szName and #szName > 0 then
            if TextFilterCheck(szName) then
                if dwIndex and dwIndex == 380 then
                    --OnDemandSong(player, dwTargetID, szName)
                    RemoteCallToServer("OnDemandSong", dwTargetID, szName)
                elseif dwIndex and dwIndex == 381 then--元宵节许愿
                    RemoteCallToServer("OnWishingOfActYXJ", dwTargetID, szName)
                else
                    RemoteCallToServer("OnFortunetellingReceived", dwTargetID, szName)
                end
            else
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.FAMR_PANEL.FORTUNETELLING_ERROR)
                OutputMessage("MSG_NPC_NEARBY", g_tStrings.FAMR_PANEL.FORTUNETELLING_FILTER)
            end
        end
    end
    UIMgr.Open(VIEW_ID.PanelModifyNamePop, UIHelper.GBKToUTF8(szTitle), "", SendName, 31)
end

function RemoteFunction.OnAddPendent(dwItemIndex, nGenTime)
    if not dwItemIndex then return end
    Event.Dispatch(EventType.ON_ADD_PENDANT, dwItemIndex)
end

function RemoteFunction.LootBoxItemRespond()
    LOG.ERROR("RemoteFunction.LootBoxItemRespond not implemented.")
end

--通知客户端，打开红包参数设定界面
function RemoteFunction.OnCreateGiftRequest(bDisableCoin)
    UIMgr.Open(VIEW_ID.PanelGiveRedPacket , bDisableCoin)
end

--通知客户端，获得多少红包
function RemoteFunction.OnTakeGiftRequest(dwGiftID, nCoinType, nCurrency, szOwnerName)
    UIMgr.Open(VIEW_ID.PanelGetRedPacket , dwGiftID, nCoinType, nCurrency, szOwnerName ,nil , false)
end

--通知客户端，通用的获得红包
function RemoteFunction.OnGetGeneralGift(nCoinType, nCurrency, szOwnerName, szDesc)
    UIMgr.Open(VIEW_ID.PanelGetRedPacket , nil, nCoinType, nCurrency, szOwnerName ,szDesc, true)
end

--通知客户端，红包的发放情况
function RemoteFunction.OnGetGiftInfoRequest(dwNpcID, tInfo)
    -- local tInfo = {
    -- dwOwner        = XXXX,
    -- szOwnerName    = "XXXX",
    -- dwTongID       = XXXX,
    -- szTongName     = "XXXX",
    -- nGiftCount 	  = XXXX,
    -- nCurrency      = XXX,
    -- nCurrencyType  = XXXX,
    -- szComment      = "XXXX",
    -- nLimitType     = XXXX,
    -- bGetEnd        = XXXX,
    -- GetInfo = {
        -- [1] = {
        -- dwRoleID    = XXXX,
        -- szRoleName  = "XXXX",
        -- nCurrency   = XXXX,
        -- szComment   = "XXXX",
        -- dwRoleType  = XXXX,
        -- dwMiniAvatarID = XXXX
        -- }
        -- ...
    -- }
    UIMgr.Open(VIEW_ID.PanelGetRedPacketList , dwNpcID, tInfo)
end

function RemoteFunction.CloseLevelUpPanel(bClose)
    Event.Dispatch(EventType.CloseLevelUpPanel, bClose)
end

function RemoteFunction.On_MonsterBook_ActiveCallBack(bResult)
    Event.Dispatch("On_MonsterBook_ActiveCallBack", bResult)
end

function RemoteFunction.OnSyncFriendEvokeList(dwItemID, tEvokeList)
    if not UIMgr.GetView(VIEW_ID.PanelConveneList) then
        UIMgr.Open(VIEW_ID.PanelConveneList , dwItemID, tEvokeList , true)
    end
end

function RemoteFunction.OnSyncTongMemberEvokeList(dwItemID, tEvokeList)
    if not UIMgr.GetView(VIEW_ID.PanelConveneList) then
        UIMgr.Open(VIEW_ID.PanelConveneList ,dwItemID ,tEvokeList , false)
    end
end

function RemoteFunction.On_Assist_Quest_Msg(nQuestID, szNewbieName)
    FireUIEvent("QUEST_ASSISTED", nQuestID, szNewbieName)
end

function RemoteFunction.On_Help_GetType(nType)
	AssistNewbieBase.SetSubscribeType(nType)
end

function RemoteFunction.On_OpenQuestItem(nItemID, bOpen)
    if bOpen then
        ItemData.OpenQuestItem = { dwTabType = 5, dwIndex = nItemID, nOpType = ItemData.QuickUseOperateType.RemoteOpenQuestItem }

        Event.Dispatch(EventType.OnSkillSlotQuickUseChange)
    else
        if ItemData.OpenQuestItem and ItemData.OpenQuestItem.dwIndex == nItemID then
            ItemData.OpenQuestItem = nil

            Event.Dispatch(EventType.OnSkillSlotQuickUseChange)
        end
    end
end

function RemoteFunction.On_Boss_Focus(dwPlayerID, bFocus)
    FireUIEvent("ON_BOSS_FUCUS", dwPlayerID, bFocus)
end

function RemoteFunction.OnGetSystemItems()
    LOG.INFO("RemoteFunction.OnGetSystemItems")
end

function RemoteFunction.On_PlaySituaionMapAnimation(dwID)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSituationMapPop)
    if scriptView then
        scriptView:OnEnter(dwID)
    else
        UIMgr.Open(VIEW_ID.PanelSituationMapPop, dwID)
    end
end

function RemoteFunction.On_CloseSituationMap()
    UIMgr.Close(VIEW_ID.PanelSituationMapPop)
end

--- BEGIN: 空格小游戏
function RemoteFunction.On_SpacebarGame_Open(tbInfo, bRepeat, szSource)
    UIMgr.Open(VIEW_ID.PanelMiniGameProgress, tbInfo, bRepeat, szSource)
end

function RemoteFunction.On_SpacebarGame_BeginSure()
    FireUIEvent("UI_ON_SPACEBARGAME_BEGIN")
end

function RemoteFunction.On_SpacebarGame_Result(bResult, nRound, nRegion)
    FireUIEvent("UI_ON_SPACEBARGAME_RESULT", bResult, nRound, nRegion)
end

function RemoteFunction.OnGetVoteFlamesOfWar(nTitlePoint, nNeedPoint, nCanGet, nHasGot, nLeft)
    local szMsg = FormatString(g_tStrings.STR_GET_VOTE_FLAMES, nTitlePoint, nNeedPoint, nCanGet, nHasGot)
    if nLeft >= 1 then
        szMsg = szMsg .. FormatString(g_tStrings.STR_GET_VOTE_FLAMES_LEFT, nLeft)
        UIHelper.ShowConfirm(szMsg, function() RemoteCallToServer("On_Vote_RealityGetVoteFlower") end)
    else
        szMsg = szMsg .. g_tStrings.STR_GET_VOTE_FLAMES_NO
        UIHelper.ShowConfirm(szMsg)
    end
end


function RemoteFunction.On_EightWastes_SKillBacklist(tList)
    BahuangData.OnGetSkillList(tList)
end

function RemoteFunction.On_EightWastes_SceneBacklist(tbResult)
    UIMgr.Open(VIEW_ID.PanelBahuangResult, tbResult, false)
    BahuangData.StopTimer()
    BahuangData.ClearSkillTip()
end

function RemoteFunction.On_EightWastes_LastTimeBacklist(nLastTime)
    BahuangData.UpdateBattleInfoList("nLastTime", nLastTime)
end

function RemoteFunction.On_EightWastes_ReviveBack(nLastLife)
    BahuangData.UpdateBattleInfoList("nLastLife", nLastLife)
end

function RemoteFunction.On_EightWastes_ConfigBackList(tData)
    BahuangData.UpdateBattleInfoList("nSceneLevel", tData.nSceneLevel > 0 and tData.nSceneLevel or 1)
end

function RemoteFunction.On_EightWastes_Restart()
    BahuangData.ClearBattleInfoList()
    TipsHelper.OnStartEvent()
    BahuangData.StartTimer()
end

function RemoteFunction.On_EightWastes_LastDataBacklist(tbData)
    BahuangData.OnLastGameDataUpdate(tbData)
end

function RemoteFunction.On_EightWastes_AltarBacklist(szAltar, tbNumber, tbTime, bStart)
    TipsHelper.ShowRefreshAltar(szAltar, tbNumber, tbTime, bStart)
end

function RemoteFunction.On_EightWastes_BossBack()
    TipsHelper.ShowRefreshBoss()
end

function RemoteFunction.RequestBlueprintNameAndAuthor(szGlobalID, nType)
	Homeland_GetDigitalBlueprintNameAndAuthor(szGlobalID, nType)
end

function RemoteFunction.OnSceneDisableModelSTCull(bDisable)
    local scene = SceneMgr.GetGameScene()
    if scene then
        scene:DisableModelSTCull(bDisable)
    end
end

function RemoteFunction.OpenMonsterLocker()
    UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
    UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.BaiZhan)
end

function RemoteFunction.OnPersonalCardGetAllDataRespond(data)
    Event.Dispatch(EventType.OnPersonalCardGetAllDataRespond, data)
end

function RemoteFunction.On_Partner_EnableDraw(nMaxDrawCount)
    Event.Dispatch("On_Partner_EnableDraw", nMaxDrawCount)
end

function RemoteFunction.On_Partner_UpdateMeetState(nHeroID, nMeetTimes, nState, bFinish)
    Event.Dispatch("On_Partner_UpdateMeetState", nHeroID, nMeetTimes, nState, bFinish)
end

function RemoteFunction.On_Partner_StopDraw(dwPartnerID, nMeetTimes, nState)
    Event.Dispatch("On_Partner_StopDraw", dwPartnerID, nMeetTimes, nState)
end

function RemoteFunction.On_Partner_IsGetDailyTeaSuccess(bFlag)
    Event.Dispatch("On_Partner_IsGetDailyTeaSuccess", bFlag)
end

function RemoteFunction.On_Partner_GetTaskID(dwTaskID)
    Event.Dispatch("On_Partner_GetTaskID", dwTaskID)
end

function RemoteFunction.On_Partner_OpenCountNpcScore()
    if not Partner_GetShowRecommend() then
        return
    end

    --- 服务器判断有更强的配置，让玩家选择是否应用新的配置
    UIHelper.ShowConfirm(g_tStrings.STR_PARTNER_COUNT_ALL_SCORE, function()
        Partner_CountAllNpcEquipScore(true)
    end)
end

function RemoteFunction.On_GameGuide_UpdateDailyInfo(tbQuestList, nGetRewardLv, nReachLv, dwRewardIndex)
    CollectionDailyData.Update(tbQuestList, nGetRewardLv, nReachLv, dwRewardIndex)
    Event.Dispatch(EventType.On_Get_Daily_Allinfo, tbQuestList, nGetRewardLv, nReachLv, dwRewardIndex)
end

function RemoteFunction.On_GameGuide_RefreshDailyInfo(nCardPos, tbCardInfo, nGetRewardLv, nReachLv)
    CollectionDailyData.UpdateSingleDailyInfo(nCardPos, tbCardInfo, nGetRewardLv, nReachLv)
    Event.Dispatch(EventType.On_GameGuide_RefreshDailyInfo, nCardPos, tbCardInfo, nGetRewardLv, nReachLv)
end

function RemoteFunction.On_GameGuide_UpdateWeeklyInfo(nPoint, nGetRewardLv)
    CollectionDailyData.UpdateWeekly(nPoint, nGetRewardLv)
    Event.Dispatch(EventType.On_GameGuide_UpdateWeeklyInfo, nPoint, nGetRewardLv)
end

function RemoteFunction.On_GameGuide_NxWkLoginInfo(nCan, nClaimed)
    CollectionDailyData.UpdateNextWeek(nCan, nClaimed)
    Event.Dispatch(EventType.On_GameGuide_NxWkLoginInfo, nCan, nClaimed)
end


------ 滤镜设置相关
--- 策划开关
function RemoteFunction.BeginRemoteSetFilter(nDurationInSeconds)
    LOG.INFO("RemoteFunction.BeginRemoteSetFilter, nDurationInSeconds = "..tostring(nDurationInSeconds))

    APIHelper.WaitLoadingFinishToDo(function()
        if nDurationInSeconds then
            assert(type(nDurationInSeconds) == "number")
        end

        FilterMgr.LockUserSetting(nDurationInSeconds)
    end)
end

function RemoteFunction.EndRemoteSetFilter()
    LOG.INFO("RemoteFunction.EndRemoteSetFilter")

    APIHelper.WaitLoadingFinishToDo(function()
        FilterMgr.UnlockUserSetting()
        FilterMgr.SafeChangeFilter(0)
    end)
end

function RemoteFunction.SetPostRenderFilter(nFilterIndex)  -- 从0开始（先设置这个再设置具体的参数）‘
    LOG.INFO("RemoteFunction.SetPostRenderFilter, nFilterIndex = "..tostring(nFilterIndex))

    APIHelper.WaitLoadingFinishToDo(function()
        FilterMgr.RemoteSetPostRenderFilter(nFilterIndex)
    end)
end

--[[
	传递一个三元素数组，形式为{击杀数, 协杀数, 重伤数}
--]]
function RemoteFunction.Moba_GetPlayerKillData(tData)
    assert(#tData >= 3)
    local nKills, nAssistKills, nDeaths = tData[1], tData[2], tData[3]
    Event.Dispatch("Moba_UpdatePlayerKillData", nKills, nAssistKills, nDeaths)
end

--- 两个ID的含义是UI配置表MobaShopItemInfo.txt的第一列；
--- 可以传4个参数、2个参数或不传参数，如果不传参数则关闭界面
function RemoteFunction.Moba_OnShowAffordableEquip(dwID1, nCost1, dwID2, nCost2)
    Event.Dispatch("Moba_OnShowAffordableEquip", dwID1, nCost1, dwID2, nCost2)
end

--[[
	userdata与eMobaBattleMsgType的关系参见策划公用脚本中枚举类型LUA_MOBA_BATTLE_MSG_TYPE的注释
--]]
function RemoteFunction.ShowMobaBattleMsg(eMobaBattleMsgType, userdata)
    if eMobaBattleMsgType then
        if type(userdata) ~= "table" then
            userdata = {userdata}
        end
        LieXingXuJingData.ShowMobaBattleMsg(eMobaBattleMsgType, userdata)
    else
        Log("ERROR! RemoteFunction.ShowMobaBattleMsg()的第一个参数不合法！")
    end
end

function RemoteFunction.ShowBindPhoneMsgBox()
    Event.Dispatch("ShowBindPhoneMsgBox")
end

function RemoteFunction.OnASApplySendVerifySMSRespond(nCode)
	Event.Dispatch("ON_ASAPPLY_SENDVERITY_RESPOND", nCode)
end

function RemoteFunction.OnDynamicSkillHighlightChanged(nIndex, bHightLight, nType)
    if not nType or nType == 0 then
        FireUIEvent("DYNAMIC_SKILL_HIGHLIGHT_CHANGED", nIndex, bHightLight)
    -- elseif nType == 1 then
        -- FireUIEvent("WEAPON_SKILL_HIGHLIGHT_CHANGED", nIndex, bHightLight)
    end
end

--- 刺客任务卷轴
function RemoteFunction.On_AssassinateTask_OpenScroll(nID, bShowContent)
    local script = UIMgr.GetViewScript(VIEW_ID.PanelAssassinationPaint)
    if not script then
        UIMgr.Open(VIEW_ID.PanelAssassinationPaint, nID, bShowContent)
    else
        script:OnEnter(nID, bShowContent)
    end
end

function RemoteFunction.OnASUserUnlockFailed(nResultCode)
	FireUIEvent("ON_ACCOUNT_SECURITY_USER_UNLOCK_FAILED", nResultCode)
end

function RemoteFunction.On_Activity_HZJClickButton(tFlowerInfo)
    if UIMgr.GetView(VIEW_ID.PanelFlowerFestival) then
        Event.Dispatch("ON_UPDATE_FLOWERPANEL_INFO", tFlowerInfo)
    end
end

function RemoteFunction.OpenConflatePanel(dwSetID,dwItemID)
    local script = UIMgr.GetViewScript(VIEW_ID.PanelToyPuzzle)
    if not script then
        UIMgr.Open(VIEW_ID.PanelToyPuzzle, dwSetID,dwItemID)
    else
        script:OnEnter(dwSetID,dwItemID)
    end
end

function RemoteFunction.On_Camp_GFSetCommander(bCommander)
	if bCommander then
		CommandBaseData.SetRoleType(COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER)
	else
		CommandBaseData.SetRoleType(COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER)
	end
end

function RemoteFunction.On_Camp_GFDelMember(nRoleType)
	CommandBaseData.SetRoleType(nRoleType)
    CommandBaseData.ControlBtn()
end

function RemoteFunction.On_Camp_GFAddMember(nRoleType, nLevel)
	CommandBaseData.SetRoleType(nRoleType)
	CommandBaseData.SetRoleLevel(nLevel)
    CommandBaseData.ControlBtn()
    -- TipsHelper.ShowNormalTip("剑网3无界端暂未开放阵营指挥管理，敬请期待！")
end

function RemoteFunction.On_Camp_OBGFGetPlayerInfo(tData)
	CampOBBaseData.OnRemoteDataReturn(tData)
end

function RemoteFunction.OnOpennActivityPasswordPanel()
    UIMgr.Open(VIEW_ID.PanelKeyExchangePop)
end

function RemoteFunction.OnActivitySymbolRespond(dwMapID, dwSymbol)
    -- 先存储数据到 MapHelper，这样即使中地图界面未打开，数据也能被保存
    MapHelper.dwActivitySymbolMapID = dwMapID
    MapHelper.dwActivitySymbolSymbol = dwSymbol
    local argSave0, argSave1 = arg0, arg1
    arg0, arg1 = dwMapID, dwSymbol
    FireEvent("ACTIVITY_SYMBOL_RESPOND")
    arg0, arg1 = argSave0, argSave1
end

function RemoteFunction.On_Camp_GFAssignItem(nType, tOKList, tNotMemberFail, tInDifMapFail, tOtherFail)
	RemoteCallToServer("On_Camp_GFDoAssignItem", nType, tOKList)
end

function RemoteFunction.On_Arena_GetSeasonInheritLevel(nInheritLevel2, nCurLevel2, nInheritLevel3, nCurLevel3, nInheritLevel5, nCurLevel5)
	local aOldLevels = {nInheritLevel2, nInheritLevel3, nInheritLevel5}
	local aNewLevels = {nCurLevel2, nCurLevel3, nCurLevel5}

	UIMgr.Open(VIEW_ID.PanelPvpJJCInherit, aOldLevels, aNewLevels)

    if UIMgr.GetView(VIEW_ID.PanelHotSpotBanner) then
        UIMgr.Close(VIEW_ID.PanelHotSpotBanner)
    end
end

--小橙武升级回调
function RemoteFunction.OnUpgradeOrangeWeapon()
    -- OrangeWeaponUpg.OnUpgradeCallback()
    Event.Dispatch("On_Upgrade_OrangeWeapon")
end

function RemoteFunction.On_Camp_GFGetCastleInfo(tCastle)
    Event.Dispatch("On_Camp_GFGetCastleInfo", tCastle)
end

function RemoteFunction.OpenFamePanel(dwID)
    UIMgr.Open(VIEW_ID.PanelFame, dwID)
end

function RemoteFunction.OpenTapTapMailPop()
    UIMgr.Open(VIEW_ID.PanelTapTapMailPop, TapEventType.Mail)
end

function RemoteFunction.ClientConfirmDialog(szType, dwRemoteIndex, dwMapID, dwMapCopyIndex, ...)
    -- print("ClientConfirmDialog", szType, dwRemoteIndex, dwMapID, dwMapCopyIndex, ...)

    if szType == "CheckMapPakEnterScene" then
        if dwMapID == 565 then
            --约定私宅的皮肤ID用dwMapCopyIndex传过来
            local dwSkinID = dwMapCopyIndex
            if PakDownloadMgr.UserCheckDownloadHomelandRes(dwMapID, dwSkinID) then
                RemoteCallToServer("ClientConfirmDialogRsp", szType, dwRemoteIndex, 0, ...) -- 0 进入、1 取消
            else
                RemoteCallToServer("ClientConfirmDialogRsp", szType, dwRemoteIndex, 1, ...) -- 0 进入、1 取消
            end
        else
            if PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, nil, nil, true) then
                RemoteCallToServer("ClientConfirmDialogRsp", szType, dwRemoteIndex, 0, ...) -- 0 进入、1 取消
            else
                RemoteCallToServer("ClientConfirmDialogRsp", szType, dwRemoteIndex, 1, ...) -- 0 进入、1 取消
            end
        end
    end
end


function RemoteFunction.OnMbLangKeXingDie(szText, szType, nMessageID)
    if not UIMgr.IsViewOpened(VIEW_ID.PanelLKXRevive, true) then
        UIMgr.Open(VIEW_ID.PanelLKXRevive, szText, szType, nMessageID)
    end
end

function RemoteFunction.OnMbLangKeXingRevive()
    if UIMgr.IsViewOpened(VIEW_ID.PanelLKXRevive, true) then
        UIMgr.Close(VIEW_ID.PanelLKXRevive)
    end
end

function RemoteFunction.OnInscriptionNameClientRecive(dwTargetID, tInscriptionID, tInscriptionName)
	if not dwTargetID or not tInscriptionID or not tInscriptionName then
		return
	end

	for i = 1, #tInscriptionID do
		ItemData.InsertQiXiInscriptionInfo(dwTargetID, i, {dwID = tInscriptionID[i], szName = tInscriptionName[i]})
	end
	if tInscriptionID.n3YearID and tInscriptionName.sz3YearName then
		ItemData.InsertQiXiInscriptionInfo(dwTargetID, "t3Year", {dwID = tInscriptionID.n3YearID, szName =tInscriptionName.sz3YearName})
	end

		--{dwID = tInscriptionID[1], szName = tInscriptionName[1]},
	--	{dwID = tInscriptionID[2], szName = tInscriptionName[2]},
	--	{dwID = tInscriptionID[3], szName = tInscriptionName[3]},
		--{dwID = tInscriptionID[4], szName = tInscriptionName[4]},
	--	{dwID = tInscriptionID[5], szName = tInscriptionName[5]},
	--	{dwID = tInscriptionID[6], szName = tInscriptionName[6]},
	--}
end

function RemoteFunction.OnCoinShopPackNotify(nErrorCode)
    FireUIEvent("COIN_SHOP_PACK_NOTIFY", nErrorCode)
end

function RemoteFunction.OpenUILink(szLink)
	FireUIEvent("EVENT_LINK_NOTIFY", szLink)
end


function RemoteFunction.On_Team_CallInToPlayerRelity(dwSrcPlayerID, szSrcPlayerName, dwMapID, nCopyIndex)
    if string.is_nil(szSrcPlayerName) then
        LOG.ERROR("RemoteFunction.On_Team_CallInToPlayerRelity, szSrcPlayerName is nil.")
        return
    end

    local confirmYesFunc = function()
        local dwSwitchMapID = 0
        local tbInfo = Table_GetDungeonSwitchMapInfo(dwMapID)
        if tbInfo then
            dwSwitchMapID = tbInfo.dwID
        end

        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_Team_AnswerEvoke", dwSrcPlayerID, "YES", dwMapID, nCopyIndex, dwSwitchMapID)
        end, dwMapID)
    end

    local szMapName = Table_GetMapName(dwMapID) or ""
    local szContent = FormatString(g_tStrings.STR_TEAM_CALL_EVOKE_MSG, GBKToUTF8(szSrcPlayerName), GBKToUTF8(szMapName))

    local dialog = UIHelper.ShowConfirm(szContent,
    function()
        confirmYesFunc()
    end,
    function()
        RemoteCallToServer("On_Team_AnswerEvoke", dwSrcPlayerID, "NO")
    end)

    dialog:SetConfirmButtonContent(g_tStrings.STR_ACCEPT)
    dialog:SetCancelButtonContent(g_tStrings.STR_REFUSE)
end

function RemoteFunction.On_OpenPanelAtEnterGame(nID, szOpenPanelfuntion)
    if szOpenPanelfuntion == "BarMitzvah.Open" then
        APIHelper.WaitLoadingFinishToDo(function()
            UIMgr.OpenSingle(false, VIEW_ID.Panel18Congratulation)
        end)
    elseif szOpenPanelfuntion == "ReadMailPanel.Open" then
        APIHelper.WaitLoadingFinishToDo(function()
            UIMgr.Open(VIEW_ID.PanelMasterMail)
        end)
    end
end

function RemoteFunction.On_Recharge_GetCurrentGrowInfo(nItemNewID, nMaxValue, nCurrentValue) --- nItemNewID 表示奇趣坐骑的 dwItemIndex
    Event.Dispatch("UPDATE_GROW_VALUE", nItemNewID, nMaxValue, nCurrentValue)
end

function RemoteFunction.On_Recharge_GetGrowedID(nItemNewID)
    Event.Dispatch("UPDATE_GROWED_INFO", nItemNewID)
end

function RemoteFunction.On_Mobile_DBMPause()
    Event.Dispatch("ON_PAUSE_BAIZHAN_DBM", true)
end

function RemoteFunction.On_Mobile_DBMRestart()
    Event.Dispatch("ON_PAUSE_BAIZHAN_DBM", false)
end

function RemoteFunction.On_Mobile_DBMChange(nID)
    Event.Dispatch("ON_BAIZHAN_DBMCHANGE", nID)
end

function RemoteFunction.On_Mobile_DBMOpen(nBOSSID)
    Event.Dispatch("ON_ENTER_BAIZHAN_DBM", true, nBOSSID)
end

function RemoteFunction.On_Mobile_DBMClose(nBOSSID)
    Event.Dispatch("ON_ENTER_BAIZHAN_DBM", false, nBOSSID)
end

function RemoteFunction.On_Mobile_BAIZHANDBM_ADD(tbDbmIdList)
    Event.Dispatch("ON_ADD_BAIZHAN_DBM", tbDbmIdList)
end

function RemoteFunction.On_Mobile_BAIZHANDBM_REMOVE(tbDbmIdList)
    Event.Dispatch("ON_REMOVE_BAIZHAN_DBM", tbDbmIdList)
end

function RemoteFunction.On_Mobile_BAIZHANDBM_CHANGE_CD(nID, nTime)
    Event.Dispatch("ON_CHANGE_BAIZHAN_DBM_CD", nID, nTime)
end

function RemoteFunction.On_BAIZHANDBM_CHANGE_ICONINFO(nOldID, nNewID)
    Event.Dispatch("ON_CHANGE_BAIZHAN_DBM_ICONINFO", nOldID, nNewID)
end

function RemoteFunction.On_BAIZHANDBM_PauseByID(tbDbmIdList)
    Event.Dispatch("ON_PAUSE_BAIZHAN_DBM_ByID", true, tbDbmIdList)
end

function RemoteFunction.On_BAIZHANDBM_RestartByID(tbDbmIdList)
    Event.Dispatch("ON_PAUSE_BAIZHAN_DBM_ByID", false, tbDbmIdList)
end

function RemoteFunction.OnBaiZhanDbmCalibrateByID(nID, nTime)
    Event.Dispatch("ON_CALIBRATE_BAIZHAN_DBM_CD", nID, nTime)
end

function RemoteFunction.OnSkillBoxFlash(nSkillID, bStart, nCount)
    Event.Dispatch("OnSkillBoxFlash", nSkillID, bStart, nCount)
end

function RemoteFunction.OnGetSceneProgressRespond(dwMapID, nMapCopyIndex, tbProgress)
    DungeonData.UpdateSceneProgress(dwMapID, nMapCopyIndex, tbProgress)
end

function RemoteFunction.On_UpdateWishItem()
	FireUIEvent("UPDATE_WISH_ITEM")
end

function RemoteFunction.On_UpdateWishCollectItem()
	FireUIEvent("UPDATE_WISH_COLLECT_ITEM_LIST")
end

function RemoteFunction.On_Channel_GetInfo(tInfo, nItemNum)
    Event.Dispatch("ON_CHANNEL_GETINFO", tInfo, nItemNum)
end

function RemoteFunction.OnReportNotify(uType, uValue)
    Event.Dispatch("ON_REMOTE_REPORT_NOTIFY", uType, uValue)
end

function RemoteFunction.On_Camp_GFGetCampInTong(tCampInfo)
	CommandBaseData.SetGuildMemberCampInfo(tCampInfo)
    Event.Dispatch(EventType.On_Camp_GFGetCampInTong)
end

function RemoteFunction.On_FancySkating_Record(tPersonalRecord, tRankList, tItem, tOtherData)
    --NOTE: 若前面参数为nil，会导致Event.Dispatch后参数数量获取不正确，这里or个空表保底一下
    Event.Dispatch(EventType.On_FancySkating_Record, tPersonalRecord or {}, tRankList or {}, tItem or {}, tOtherData)
end

function RemoteFunction.OpenWulinShenghuiDuizhen(nContestPhase)
    UIMgr.Open(VIEW_ID.PanelHeroRanking, nContestPhase)
end


function RemoteFunction.UpdateMinimapHover(dwHoverID)
	local tLine = {szType = "Remote", szImagePath = nil}
	if dwHoverID ~= 0 then
		tLine = Table_GetMinimapHover(dwHoverID)
	end
	-- UpdateMinimapHover(tLine.szType, tLine.szImagePath, tLine.nFrame)
    Event.Dispatch(EventType.UpdateMinimapHover, tLine)
end

function RemoteFunction.On_PersonalCard_AddPraiseRes(bAddSuccess, szMsg, szGlobalID)
    Event.Dispatch("ON_UPDATE_SHOW_CARD_PRAISE_DATA", bAddSuccess, szMsg, szGlobalID)
end

function RemoteFunction.OnGetLangKeXingSQSkillID(nSKillID, nSkillLevel)
    TravellingBagData.OnTBSKillUpdate(nSKillID, nSkillLevel)
end

function RemoteFunction.On_TresureBox_OpenRewardPanel(tInfo, dwBoxID, dwAwardSeriesID)
    if not tInfo or table.is_empty(tInfo) then
    else
        local bHaveBig = false
        for _, tItem in ipairs(tInfo) do
            if tItem.bFlag == true then
                bHaveBig = true
                break
            end
        end

        if bHaveBig then
            UIMgr.Open(VIEW_ID.PanelTreasureBoxRewardPop, tInfo, dwBoxID, dwAwardSeriesID)
        else
            local tNewInfo = {}
            for _, tItem in ipairs(tInfo) do
                if tItem.bFlag == false then
                    local tData = {}
                    tData.nTabType = tItem.nRewardType
                    tData.nTabID = tItem.nRewardIndex
                    tData.nCount = tItem.nRewardNum
                    table.insert(tNewInfo, tData)
                end
            end
            TipsHelper.ShowRewardList(tNewInfo)
        end

        -- Event.Dispatch("TreasureBoxViewUpdate")
    end
end

function RemoteFunction.UpdateMainStoryReward()
	Event.Dispatch(EventType.UpdateMainStoryReward)
end

function RemoteFunction.On_BoxLuckyValue_Respond(nLuckyValue, nBoxID)
    Event.Dispatch("UPDATE_YUNSHI_VALUE", nLuckyValue, nBoxID)
end

function RemoteFunction.OpenGeneralInvitation(dwID)
    if not SceneMgr.IsLoading() then
        UIGlobalFunction["GeneralInvitation.Open"](dwID)
    else
        HuaELouData.dwGeneralInvitationID = dwID
    end
end

function RemoteFunction.On_Trial_GetWeekRemainCard(nWeekResetCard)
    Event.Dispatch(EventType.On_Trial_GetWeekRemainCard,nWeekResetCard)
end

function RemoteFunction.SceneNpcRename(tTable)
    LOG.INFO("RemoteFunction.SceneNpcRename")
    if not tTable then
        return
    end
	local player = GetClientPlayer()
	if not player then
		return
	end
	local scene = player.GetScene()
	if not scene then
		return
	end
	for _, tInfo in pairs(tTable) do
		local dwTemplateID = tInfo[1]
		local szText = tInfo[2]
		scene.NpcRename(dwTemplateID, szText)
	end
end

function RemoteFunction.On_OpenMoGaoKuPanel(nType)
    UIMgr.Open(VIEW_ID.PanelToyJingBianTu, nType)
end

function RemoteFunction.OnShowHeroTravelReaward(tInfoList)
    Event.Dispatch("PartnerTravel_AfterTakeReward")

    if UIMgr.GetView(VIEW_ID.PanelPartnerTravelInfoPop) then
        Event.Dispatch("OnShowHeroTravelReaward", tInfoList)
    else
        ---@type UIPartnerTravelInfoPopView
        local view = UIMgr.Open(VIEW_ID.PanelPartnerTravelInfoPop)
        view:ShowRewardList(tInfoList)
    end
end

-- 侠客是否出行成功的回调
function RemoteFunction.On_Partner_StartTravelCallBack(bSuccess)
    Event.Dispatch("On_Partner_StartTravelCallBack", bSuccess)
end

function RemoteFunction.On_Activity_GetPotPoint(nPoint)
    Event.Dispatch("On_Activity_GetPotPoint", nPoint)
end

function RemoteFunction.WaitGSResponseDone(dwResponseIndex)
    Event.Dispatch("WaitGSResponseDone", dwResponseIndex)
end

function RemoteFunction.OnJJCEquipChange()
	Event.Dispatch("ON_JJC_EQUIP_CHANGE")
end

function RemoteFunction.OnSendMessage(szMsgType, szMsg)
    OutputMessage(szMsgType, GBKToUTF8(szMsg))
end

function RemoteFunction.SetEnvPresetByNotInSelfie(nValue)
    if not SelfieData.IsInSelfieView() then
        LOG.INFO("RemoteFunction.SetEnvPresetByNotInSelfie set env preset nValue:%s", tostring(nValue))
        rlcmd("set env preset " .. nValue)
    end
end

local function ShowMessagePro(tMsg)
    local tbInfo = Table_GetMessageBoxProInfo(tMsg.nMessageID)

    if tMsg.tItemList then
        UIMgr.Open(VIEW_ID.PanelReviveBoxPop, tMsg, tbInfo)
    else
        UIMgr.Open(VIEW_ID.PanelRevivePop, tMsg, tbInfo)
    end
end

function RemoteFunction.OnMessageBoxProRequest(tMsg)
    if SceneMgr.IsLoading() then
        Event.Reg(RemoteFunction, "LOADING_END", function()
            ShowMessagePro(tMsg)
        end, true)
    else
        ShowMessagePro(tMsg)
    end
end

--攻防活动Tip个人贡献详情中的阵营平均装分
function RemoteFunction.OnUpdateCampAvgEquipScore(nActivityID, nScore, bLegal)
    Event.Dispatch("OnUpdateCampAvgEquipScore", nActivityID, nScore, bLegal)
end

--数据中心冻结资产标记推送
function RemoteFunction.OnUpdateDCAssetFreeze(bDCAssetFreeze)
    DCAssetFreezeData.UpdateDCAssetFreeze(bDCAssetFreeze)
end

--tbRewardInfo =   {
    --nActivityID = 活动ID,
    --szText = "字符串/标题",
    --bReceived = true/false,  -- 奖励是否领取
    --tItem = {{dwTabType, dwIndex, Number}，{5, 19404, 10}，}, -- 物品奖励
    --tOtherRewards = {prestige = 150, money = 200, },               -- 货币奖励
    --tSpecialRewards = {{dwTabType, dwIndex, Number}，{5, 19404, 10}，}, -- 特殊奖励
--}
function RemoteFunction.OnUpdateActReward(tbRewardInfo)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelFestivalRewardPop)
    if scriptView then
        scriptView:OnEnter(tbRewardInfo)
        return
    end
    if SceneMgr.IsLoading() then
        Event.Reg(RemoteFunction, "LOADING_END", function()
            UIMgr.Open(VIEW_ID.PanelFestivalRewardPop, tbRewardInfo)
        end, true)
    else
        UIMgr.Open(VIEW_ID.PanelFestivalRewardPop, tbRewardInfo)
    end
end

function RemoteFunction.OnUpdateActRewardCollect(nActivityID)
    ActivityData.OpenFestivalStampPop(nActivityID)
end

function RemoteFunction.RefreshHuntEvent(tInfo)
	MapMgr.RefreshHuntEvent(tInfo)
end

function RemoteFunction.ClearHuntEvent(nPQID, bNewPQ)
    MapMgr.ClearHuntEvent(nPQID, bNewPQ)
end

function RemoteFunction.OpenQuickEatingPanel()
    UIMgr.Open(VIEW_ID.PanelWuWeiJuePop)
end

function RemoteFunction.OnGetTreasureHuntReward()
    Event.Dispatch("OnGetTreasureHuntReward")
end



--更新击杀者的位置
function RemoteFunction.UpdateKillerPos(tList)
    -- MiddleMap.UpdateKillerPos(tList)
    Event.Dispatch(EventType.OnKillerPosUpdate, tList)
end

--地图画线
function RemoteFunction.AppendDrawLine(dwMapID, szKey, tbPointStart, tbPointEnd)
	MapMgr.AppendDrawLine(dwMapID, szKey, tbPointStart, tbPointEnd)
end


--根据key删线
function RemoteFunction.DeleteDrawLineByKey(dwMapID, szKey)
	MapMgr.DeleteDrawLineByKey(dwMapID, szKey)
end

--根据dwMapID删线
function RemoteFunction.DeleteDrawLineByMapID(dwMapID)
	MapMgr.DeleteDrawLineByMapID(dwMapID)
end

function RemoteFunction.UpdateTongRankReward(nState1, nState2, nState3)
	Event.Dispatch("UpdateTongRankReward", nState1, nState2, nState3)
end

function RemoteFunction.OnGetNewTalentCommentRespond(dwMKungfuID, nSetID, tComment)
	Event.Dispatch("ON_NEWTALENT_COMMENT_RESPOND", dwMKungfuID, nSetID, tComment)
end

function RemoteFunction.OnSetPuppetTemplateID(dwNpcTemplateID)
    Event.Dispatch("OPEN_PUPPET_ACTIONBAR", dwNpcTemplateID)
end

function RemoteFunction.OnRemovePuppetTemplateID(dwNpcTemplateID)
	Event.Dispatch("REMOVE_PUPPET_TEMPLATEID")
end

function RemoteFunction.OpenTianZongSoullampBar(tLampList)
    Event.Dispatch("OpenTianZongSoullampBar", tLampList)
end

function RemoteFunction.CloseTianZongSoullampBar()
    Event.Dispatch("CloseTianZongSoullampBar")
end

function RemoteFunction.OpenChangGeShadowBar(tShadowList)
	Event.Dispatch("OPEN_CHANGGE_SHADOWBAR", tShadowList)
end

function RemoteFunction.CloseChangGeShadowBar()
	Event.Dispatch("CLOSE_CHANGGE_SHADOWBAR")
end

function RemoteFunction.OnSetPetTemplateID(dwNpcTemplateID)
    Event.Dispatch("OpenPetActionBar", dwNpcTemplateID)
end

function RemoteFunction.OnRemovePetTemplateID(dwNpcTemplateID)
	Event.Dispatch("REMOVE_PET_TEMPLATEID")
end

function RemoteFunction.OpenTangMenHiddenBar(tShadowList)
    Event.Dispatch("OPEN_TM_HIDDEN", tShadowList)
end

function RemoteFunction.CloseTangMenHiddenBar()
    Event.Dispatch("CLOSE_TM_HIDDEN")
end

function RemoteFunction.On_Add_Buff_Monitor(dwTargetID, dwBuffID)
	Event.Dispatch("ON_ADD_BUFF_MONITOR", dwTargetID, dwBuffID)
end

function RemoteFunction.On_Remove_Buff_Monitor(dwBuffID)
	Event.Dispatch("ON_REMOVE_BUFF_MONITOR", dwBuffID)
end

function RemoteFunction.OnUpdateDCGoldLimitLevel(nLimitType, nValue)
    local fnOpenExceptionView = function ()
        local nType = nLimitType
        local nValue = nValue
        UIMgr.Open(VIEW_ID.PanelAccountException, nType, nValue)
    end
    BubbleMsgData.PushMsgWithType("AccountException",{
        szType = "AccountException",
        szTitle = UIHelper.GBKToUTF8("风控状态解除"),
        szBarTitle = UIHelper.GBKToUTF8("风控状态解除"),
        nBarTime = 0,
        bShowAdventureBar = true,
        szAction = function ()
            fnOpenExceptionView()
        end,
    })
    BubbleMsgData.SetGoldLimitValue(nLimitType, nValue)
end

function RemoteFunction.On_Respond_QiangLiJianChan(bSuccessRemove)
	if bSuccessRemove then
        BubbleMsgData.RemoveMsg("AccountException")
        UIMgr.Close(VIEW_ID.PanelAccountException)
        BubbleMsgData.SetGoldLimitValue(nil, nil)
	end
end

function RemoteFunction.On_Liupai_UnLockFinished()
    Event.Dispatch("On_Liupai_UnLockFinished")
end

function RemoteFunction.OpenSkillPanel(dwKungFuID)
    UIMgr.OpenSingle(true, VIEW_ID.PanelSkillNew, dwKungFuID)
end

function RemoteFunction.OnUpdateCYGas(tInfo)
    Event.Dispatch("OnUpdateCYGas", tInfo)
end

function RemoteFunction.On_Tong_UpdateVoiceRoom(szRoomID)
	RoomVoiceData.OpenTongVoiceRoom(szRoomID)
end

function RemoteFunction.OnBirthdaySetState()
	FireUIEvent("ON_BIRTHDAY_SET_SUCCESS")
end

function RemoteFunction.OnOpenDungeonExcellentCard(bPassDungeon, nDelayTime)
	DungeonSettleCardData.UpdateExcellentCard(bPassDungeon, nDelayTime)
end

function RemoteFunction.OnOpenNewRewardPanel(szType, tInfo)
	if szType == "SpecialGift" and tInfo and tInfo.dwID then
        TipsHelper.OpenSpecailGift(tInfo.dwID)
    elseif szType == "WishFall" and tInfo and tInfo.tItemList then
        local tItem = tInfo.tItemList[1]
        if tItem and tItem.dwTabType and tItem.dwIndex then
            TipsHelper.OnOpenRemotePanel("JYPlayReward", tInfo)
        end
    elseif szType == "JYPlayReward" and tInfo then
        TipsHelper.OnOpenRemotePanel("JYPlayReward", tInfo)
    end
end

function RemoteFunction.SwitchSpringCompass(bOpen)
	-- if bOpen then
	-- 	CompassPanel.OpenPanel()
	-- else
	-- 	CompassPanel.ClosePanel()
	-- end
end

function RemoteFunction.OnCharacterHeadTip(dwCharacterID, szTip, szParam, tColor)
    Event.Dispatch(EventType.OnCharacterHeadTip, dwCharacterID, GBKToUTF8(szTip), szParam, tColor)
end

function RemoteFunction.OpenCrosshair(tParam)
    Event.Dispatch("OPEN_CROSSHAIR", tParam)
end

function RemoteFunction.CloseCrosshair()
    Event.Dispatch("CLOSE_CROSSHAIR")
end


function RemoteFunction.OnUnlockCouplet(tInfo)
    Event.Dispatch("OnUnlockCouplet", tInfo)
end

function RemoteFunction.OnAddtionalBuffDescribe(szMessage, nBuffID, nBuffLevel)
    Event.Dispatch("OnAddtionalBuffDescribe", szMessage, nBuffID, nBuffLevel)
end

function RemoteFunction.SetBanInfo(nBanChatEndTime, nBanShowCardOperateEndTime)
    LOG.INFO("RemoteFunction.SetBanInfo, nBanChatEndTime = %s, nBanShowCardOperateEndTime = %s", tostring(nBanChatEndTime), tostring(nBanShowCardOperateEndTime))
    Event.Dispatch(EventType.OnRemoteBanInfoUpdate, nBanChatEndTime, nBanShowCardOperateEndTime)
end

function RemoteFunction.On_AIUploadTimes_Respond(nRemainTimes)
    Event.Dispatch(EventType.OnSelfieUpdateAIUploadRemainCount, nRemainTimes)
end

function RemoteFunction.PlayAIAction(szAIActionPath)
    local dwCharacterID = UI_GetClientPlayerID()
    local bEnable = 1
    rlcmd(string.format("play ai animation %d %d %s", dwCharacterID, bEnable, szAIActionPath))
end

function RemoteFunction.On_Trial_ContinueFlopReturn()
    Event.Dispatch("On_Trial_ContinueFlopReturn")
end

function RemoteFunction.OnPlayOneClickAction(bSuccess)
    Event.Dispatch("OnPlayOneClickAction_CallBack", bSuccess)
end

function RemoteFunction.CB_SH_TaskRewardGranted(szKey)
    Event.Dispatch("CB_SH_TaskRewardGranted", szKey)
end

function RemoteFunction.OnUpdateSimpleReward(tSendList)
    Event.Dispatch("OnUpdateSimpleReward", tSendList)
end

function RemoteFunction.CB_SH_ExchangeMount(nSlot)
    Event.Dispatch("CB_SH_ExchangeMount", nSlot)
end

function RemoteFunction.CB_SH_SetPersonReward(tSendList, nNewRewardLv)
    Event.Dispatch("CB_SH_SetPersonReward")
end

function RemoteFunction.CB_SA_TeShuRenWu(szKey)
    Event.Dispatch("CB_SA_TeShuRenWu", szKey)
end

function RemoteFunction.CB_SA_TaskUpdate() 
    Event.Dispatch("CB_SA_TaskUpdate")
end

function RemoteFunction.CB_SA_SetPersonReward()
	Event.Dispatch("CB_SA_SetPersonReward")
end 


function RemoteFunction.OnSeasonTaskProgressMessage(nType, szKey, nP, nM)
    local szTip
    if nType == 1 then
        local tInfo = Table_GetTaskInfoByKey(szKey)
        szTip = string.format(g_tStrings.STR_SEASON_RANK_MESSAGE, UIHelper.GBKToUTF8(tInfo.szTitle), nP, nM)
        TipsHelper.ShowNormalTip(szTip)
        OutputMessage("MSG_SYS", szTip) 
    elseif nType == 2 then
        local tInfo = Table_GetSeasonHonorInfoByKey(szKey)
        szTip = string.format(g_tStrings.STR_SEASON_HONOR_MESSAGE, UIHelper.GBKToUTF8(tInfo.szTitle), nP, nM)
        TipsHelper.ShowNormalTip(szTip)
        OutputMessage("MSG_SYS", szTip)
        Event.Dispatch("OnSeasonTaskProgressMessage", nType, szKey, nP, nM)
    end
end

-- szType: Weakness/OnlyNearDis/MidAxisFirst对应设置的三个策略
function RemoteFunction.SearchTargetLock(bLock, szType)
    LOG.INFO("RemoteFunction.SearchTargetLock, bLock = %s, szType = %s", tostring(bLock), tostring(szType))

    local tType = nil

    if bLock and not string.is_nil(szType) then
        -- DX 有3个，但是VK设置里只有2个，所以就这样兼容下
        if szType == "Weakness" then
            tType = GameSettingType.SearchTargetPriority.Weakness
        else
            tType = GameSettingType.SearchTargetPriority.OnlyNearDis
        end
    end

    TargetMgr.SearchTargetLock(bLock, tType)
end