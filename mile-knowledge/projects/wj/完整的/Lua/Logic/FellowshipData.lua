FellowshipData = FellowshipData or {className = "FellowshipData"}
local self = FellowshipData
local ERROR_CODE = { --这个序号对应string.lua里tFindAppErrorCode等表格，来提示玩家为什么不能拜师或者收徒
    NORMAL = 0,
    ONE = 1,
    TWO = 2,
    THREE = 3,
}

FellowshipData.tMode2RelationType = {[1] = 7, [2] = 8, [3] = 9}

function FellowshipData.Init()
    FellowshipData.OPPOSITE_CAMP_SHOW_WHERE_NEED_ATTRACTION = 100
    FellowshipData.PLAYER_LIST_SHOW_NUM = 3
    FellowshipData.nDefaultPushType = FELLOW_SHIP_PUSH_TYPE.PUSH

    FellowshipData.tbRelationType = {
        nFriend = 1,
        nFoe = 2,
        nBlack = 3,
        nFeud = 4,
        nAroundPlayer = 6,
        nMaster = 7, --师父
        nApprentice = 8,  --徒弟
        nSameApp = 9, --同门
        nPush = 10, -- 推荐好友
        nTong = 11,
        nRecent = 12,
        nNpc = 13, -- 侠缘
    }

    FellowshipData.tbRelationShowType = {
        nContacts = 2, -- 联系人
        nApprentice = 3, -- 师徒
        nTong = 4, -- 帮会
    }

    FellowshipData.tApplySocialList = {}
    FellowshipData.tEntryInfoTime = {}

    FellowshipData.dwFindMas = 0
    FellowshipData.dwFindApp = 0

    Event.Reg(FellowshipData, "PLAYER_FELLOWSHIP_CHANGE", function(nRespondCode, dwPlayerID, dwValue1, dwValue2, szName)
        if nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD then
            local szMsg = g_tStrings.tFellowshipString[PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD]
            TipsHelper.ShowNormalTip(szMsg)
        elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD_FOE then
            local szMsg = g_tStrings.tFellowshipString[PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD_FOE]
            TipsHelper.ShowNormalTip(szMsg)
        elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD_BLACK_LIST then
            local szMsg = g_tStrings.tFellowshipString[PLAYER_FELLOWSHIP_RESPOND.SUCCESS_ADD_BLACK_LIST]
            TipsHelper.ShowNormalTip(szMsg)
        elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_DEL then
            -- local szMsg = string.format(g_tStrings.tFellowshipString[PLAYER_FELLOWSHIP_RESPOND.SUCCESS_DEL], szName, FellowshipData.GetFellowshipNameUTF8(dwValue1))
            -- TipsHelper.ShowNormalTip(szMsg)
        end
        FellowshipData.ApplyRoleEntryInfo({dwPlayerID})
        FellowshipData.ApplyRoleOnlineFlag({dwPlayerID})
    end)

    -- Event.Reg(FellowshipData, "ON_DEL_FOE_NOTIFY", function (dwPlayerID)
    --     TipsHelper.ShowNormalTip(g_tStrings.FELLOWSHIP_SUCCESS_DEL_FOE1)
    -- end)

    Event.Reg(FellowshipData, EventType.PLAYER_ADD_FOE_BEGIN, function(szDestName, nLeftSeconds)
        TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_ADD_FOE_BEGIN,
                UIHelper.GBKToUTF8(szDestName), nLeftSeconds), false)

        Timer.AddCountDown(FellowshipData, nLeftSeconds, function (nRemain)
            if nRemain ~= 0 then
                TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_ADD_FOE_BEGIN,
                    UIHelper.GBKToUTF8(szDestName), nRemain), false)
            end
        end, nil)
    end)

    Event.Reg(FellowshipData, EventType.PLAYER_ADD_FOE_END, function(szDestName, szDestGlobalID, nLeftSeconds)
        TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_ADD_FOE_END,
                UIHelper.GBKToUTF8(szDestName)))

        if FellowshipData.IsFriend(szDestGlobalID) then
            FellowshipData.DelFellowship(szDestGlobalID)
        end
    end)

    Event.Reg(FellowshipData, EventType.PLAYER_DEL_BEGIN, function(nLeftTime)
        TipsHelper.ShowNormalTip(string.format(g_tStrings.FELLOWSHIP_PREPARE_DEL_FOE, nLeftTime))

        FellowshipData.nDelFoeTimer = Timer.AddCountDown(FellowshipData, nLeftTime, function (nRemain)
            if g_pClientPlayer.bFightState then
                TipsHelper.ShowNormalTip(g_tStrings.FELLOWSHIP_FAILED_DEL_FOE)

                Timer.DelTimer(FellowshipData, FellowshipData.nDelFoeTimer)
                FellowshipData.nDelFoeTimer = nil
            else
                if nRemain ~= 0 then
                    TipsHelper.ShowNormalTip(string.format(g_tStrings.FELLOWSHIP_PREPARE_DEL_FOE, nRemain), false)
                end
            end
        end)
    end)

    Event.Reg(FellowshipData, EventType.PREPARE_ADD_FOE_RESULT, function(nRespondCode)
        if g_tStrings.tFellowshipPrepareFoeString[nRespondCode] then
            TipsHelper.ShowNormalTip(g_tStrings.tFellowshipPrepareFoeString[nRespondCode])
        end
    end)

    Event.Reg(FellowshipData, EventType.PLAYER_ADD_FEUD_NOTIFY, function (szDestName, szDestID, nLeftSeconds)
        if nLeftSeconds > 0 then
            TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_ADD_FEUD_BEGIN, UIHelper.GBKToUTF8(szDestName), nLeftSeconds), false)

            Timer.AddCountDown(FellowshipData, nLeftSeconds, function (nRemain)
                if nRemain ~= 0 then
                    TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_ADD_FEUD_BEGIN, UIHelper.GBKToUTF8(szDestName), nRemain), false)
                end
            end, function()
                RemoteCallToServer("On_AddFeud_Start", szDestID)
            end)
        else
            if FellowshipData.IsFriend(szDestID) then
                FellowshipData.DelFellowship(szDestID)
            end
        end
    end)

    Event.Reg(FellowshipData, EventType.PLAYER_APPLY_BE_ADD_FOE, function(szSrcName, dwSrcID, nLeftSeconds)
        TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_APPLY_BE_ADD_FOE,
                UIHelper.GBKToUTF8(szSrcName), nLeftSeconds), false)

        Timer.AddCountDown(FellowshipData, nLeftSeconds, function (nRemain)
            if nRemain ~= 0 then
                TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_APPLY_BE_ADD_FOE,
                    UIHelper.GBKToUTF8(szSrcName), nRemain), false)
            end
        end, nil)
    end)

    Event.Reg(FellowshipData, EventType.PLAYER_APPLY_BE_ADD_FEUD, function(szSrcName, dwSrcID)
        local function AcceptAddFeud(dwSrcID, bAccept)
            RemoteCallToServer("On_AddFeud_Ask", dwSrcID, bAccept)
        end
        local szMessage = string.format(g_tStrings.STR_IS_BE_ADD_FEUD, UIHelper.GBKToUTF8(szSrcName))
        local szBubMessage = string.format(g_tStrings.STR_IS_BE_ADD_FEUD_BUBBLE, UIHelper.GBKToUTF8(szSrcName))
        BubbleMsgData.PushMsgWithType("AddFeudInvite", {
            nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
            szContent = szBubMessage,
            szAction = function()
                UIHelper.ShowConfirm(szMessage, function()
                    Timer.AddFrame(FellowshipData, 1, function ()
                        FellowshipData.AddFeudComfirm(AcceptAddFeud, dwSrcID, true)
                    end)
                    BubbleMsgData.RemoveMsg("AddFeudInvite")
                end, function()
                    AcceptAddFeud(dwSrcID, false)
                    BubbleMsgData.RemoveMsg("AddFeudInvite")
                end)
            end})
    end)

    -- Event.Reg(FellowshipData, "FIRST_LOADING_END", function()
    --     FellowshipData.InitFriendInfo()
    -- end)

    --消息盒子添加好友
    Event.Reg(FellowshipData, "PLAYER_BE_ADD_FELLOWSHIP", function(nRespondCode, dwPlayerID, szName, szGlobalID, dwCenterID)
        if not IsRegisterEvent("PLAYER_BE_ADD_FELLOWSHIP") then
            return
        end
        if IsFilterOperate("PLAYER_BE_ADD_FELLOWSHIP") then
            return
        end

        if not g_pClientPlayer or dwPlayerID ~= g_pClientPlayer.dwID then return end

        if FellowshipData.IsInBlackList(szGlobalID) then--在黑名单
            return
        end

        if nRespondCode == PLAYER_FELLOWSHIP_RESPOND.SUCCESS_BE_ADD_FRIEND then

            self.tbBeAddFriendPlayerEntryInfo = self.tbBeAddFriendPlayerEntryInfo or {}
            self.tbBeAddFriendCenterID = self.tbBeAddFriendCenterID or {}

            local tEntryInfo = FellowshipData.GetRoleEntryInfo(szGlobalID)
            self.tbBeAddFriendPlayerEntryInfo[szGlobalID] = tEntryInfo or {}
            self.tbBeAddFriendCenterID[szGlobalID] = dwCenterID

            if not tEntryInfo then
                FellowshipData.ApplyRoleEntryInfo({szGlobalID})
            end

            self.UpdateBeAddFellowship()
        end
    end)

    --消息盒子添加敌对
    Event.Reg(self, "PLAYER_HAS_BE_ADD_FOE", function(szSrcName, dwSrcID, nLeftSeconds)
        TipsHelper.ShowNormalTip(string.format(g_tStrings.STR_HAS_BE_ADD_FOE,
                UIHelper.GBKToUTF8(szSrcName), dwSrcID, nLeftSeconds))

        local tFoeInfo = GetSocialManagerClient().GetFoeInfo()
        for _, v in ipairs(tFoeInfo) do
            if v.id == dwSrcID then
                return
            end
        end

        if IsFilterOperate("HAS_BE_ADD_FOE") then
            return
        end


        if BossCondition_0(g_pClientPlayer) then
            return
        end

        if CheckPlayerIsRemote() or CheckPlayerIsRemote(dwSrcID) then
            return
        end

        self.UpdateBeAddFoeTips(szSrcName)
    end)

    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
        if table.contain_key(self.tbBeAddFriendPlayerEntryInfo, szGlobalID) then
            local aCard = FellowshipData.GetRoleEntryInfo(szGlobalID)
            self.tbBeAddFriendPlayerEntryInfo[szGlobalID] = aCard
        end
    end)

    Event.Reg(self, "APPLY_SOCIAL_INFO_RESPOND", function(tPlayerID)
        for _, dwPlayerID in ipairs(tPlayerID) do
            if FellowshipData.tApplySocialList and FellowshipData.tApplySocialList[dwPlayerID] then
                FellowshipData.tApplySocialList[dwPlayerID] = nil
            end

            local tSocialInfo = FellowshipData.GetSocialInfo(dwPlayerID)
            FellowshipData.tApplySocialList[dwPlayerID] = tSocialInfo

            Event.Dispatch(EventType.OnUpdateFellowShip)
        end
	end)

    Event.Reg(self, "ON_GET_MENTOR_LIST", function (_, MentorList)
        FellowshipData.ApplyMentorSocialInfo(MentorList)
    end)

    Event.Reg(self, "ON_GET_DIRECT_MENTOR_LIST", function (_, MentorList)
        FellowshipData.ApplyMentorSocialInfo(MentorList)
    end)

    Event.Reg(self, "ON_GET_APPRENTICE_LIST", function (_, aMyApprentice)
        FellowshipData.ApplyMentorSocialInfo(aMyApprentice)
    end)

    Event.Reg(self, "ON_GET_DIRECT_APPRENTICE_LIST", function (_, aMyDirectApprentice)
        FellowshipData.ApplyMentorSocialInfo(aMyDirectApprentice)
    end)

    Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function ()
        local tbMemberIDList = TongData.GetMemberList(true, TongData.tbSortType.Score, false, -1, -1)

        local tID = {}
        for k,v in ipairs(tbMemberIDList) do
            table.insert(tID, v)
        end

        if #tID > 0 then
            GetSocialManagerClient().ApplySocialInfo(tID)
        end
    end)

    Event.Reg(self, "ON_UPDATE_FELLOWSHIP_NOTIFY", function (type, szGlobalID)
        local szMsg = ""
        if type == FELLOWSHIP_OPERATE_TYPE.DEL_FRIEND then
            local szName = FellowshipData.GetRoleEntryInfo(szGlobalID).szName
            local nCenterID = FellowshipData.GetRoleEntryInfo(szGlobalID).dwCenterID
            szMsg = "[".. GBKToUTF8(RoomData.GetGlobalName(szName, nCenterID)) .."]"..g_tStrings.FELLOWSHIP_SUCCESS_DEL
        elseif type == FELLOWSHIP_OPERATE_TYPE.DEL_BLACK then
            local szName = FellowshipData.GetRoleEntryInfo(szGlobalID).szName
            local nCenterID = FellowshipData.GetRoleEntryInfo(szGlobalID).dwCenterID
            szMsg = "[".. GBKToUTF8(RoomData.GetGlobalName(szName, nCenterID)) .."]"..g_tStrings.FELLOWSHIP_SUCCESS_DEL_BLACK_LIST
        elseif type == FELLOWSHIP_OPERATE_TYPE.DEL_FOE then
            szMsg = g_tStrings.FELLOWSHIP_SUCCESS_DEL_FOE1
        elseif type == FELLOWSHIP_OPERATE_TYPE.ADD_FRIEND then
            szMsg = g_tStrings.FELLOWSHIP_SUCCESS_ADD
            RemoteCallToServer("On_Daily_FinishCourse", GAME_GUIDE_DAILY_QUEST.ADD_FRIEND)
        end
        if szMsg ~= "" then
            TipsHelper.ShowNormalTip(szMsg)
        end

    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        FellowshipData.bDefaultPersonal = true
        FellowshipData.nVisiblePlayerPop = 0
        FellowshipData.bApprentice = false
        FellowshipData.bMentorRedpoint = false
    end)
end

function FellowshipData.UnInit()
    Event.UnRegAll(FellowshipData)
end


function FellowshipData.SetSignature(szSignature)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    SMClient.SetSignature(szSignature)
end

function FellowshipData.GetSocialInfo(dwRoleID)
    local SMClient = GetSocialManagerClient()
    if not SMClient or not dwRoleID then return end
    return SMClient.GetSocialInfo(dwRoleID)
end

function FellowshipData.ApplyMentorSocialInfo(MentorList)
    local tID = {}
    for k,v in ipairs(MentorList) do
        table.insert(tID, v.dwID)
    end

    if #tID > 0 then
        GetSocialManagerClient().ApplySocialInfo(tID)
    end
end

function FellowshipData.ApplyMasterInfo()
    local dwNow = GetTickCount()
    if not FellowshipData.dwLast or dwNow - FellowshipData.dwLast > 1000 then
        FellowshipData.dwLast = dwNow
		RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
		RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
		RemoteCallToServer("OnGetDirectMentorListRequest", g_pClientPlayer.dwID)
		RemoteCallToServer("OnGetDirApprenticeListRequest", g_pClientPlayer.dwID)
		RemoteCallToServer("OnApplyEvokeMentorCount")
    end
    RemoteCallToServer("OnGetDirectMentorRight")							   --取角色的亲传师徒权限
    RemoteCallToServer("OnIsAccountDirectApprentice")                          --远程调用帐号的状态，是不是亲传师徒
end

function FellowshipData.CheckGroupName(szName)
    local tbGroupInfo = FellowshipData.GetFellowshipGroupInfo() or {}
    for _, tbInfo in pairs(tbGroupInfo) do
        if tbInfo.name == szName then
            return false
        end
    end

    return true
end

function FellowshipData.GetFellowshipGroupInfo()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    local tbGroup = SMClient.GetFellowshipGroupInfo() --{{id = 1, name = "好友1组"}}
    table.insert(tbGroup, 1, {id = 0, name = UIHelper.UTF8ToGBK(g_tStrings.STR_FRIEND_DEFAULT_FRIEND_GROUP_NAME)})
    return tbGroup
end

function FellowshipData.GetFellowshipInfoList()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.GetFellowshipInfoList() --{{id = 1, name = "好友1组", attraction = 1, viptype = 1, viplevel = 0, isyear = false, isonline = true, istwoway = true, remark = "111"}}
end

function FellowshipData.GetFellowshipInfoListByGroup(dwGroupID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    local tbPalyerInfoList = SMClient.GetFellowshipInfo(dwGroupID) --{{id = 1, name = "好友1组", groupid = 0, attraction = 1, viptype = 1, viplevel = 0, isyear = false, isonline = true, istwoway = true, remark = "111", isapponline = true, isautochessonline = true}}
    return tbPalyerInfoList
end

function FellowshipData.AddFriendByName(szPlayerName, dwCenterID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.AddFriendByName(szPlayerName, dwCenterID)
end

function FellowshipData.AddFellowship(szPlayerName)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.AddFellowship(szPlayerName)
end

function FellowshipData.DelFellowship(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    FireUIEvent("DELETE_FELLOWSHIP", dwGlobalID)

    return SMClient.DelFellowship(dwGlobalID)
end

function FellowshipData.IsFriend(dwGlobalID)
    if string.is_nil(dwGlobalID) then
        return false
    end
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    if APIHelper.IsSelfByGlobalID(dwGlobalID) then
        return false
    end
    return SMClient.IsFriend(dwGlobalID)
end

function FellowshipData.SetFellowshipRemark(dwGlobalID, szRemark)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.SetFellowshipRemark(dwGlobalID, szRemark)
end

function FellowshipData.AddBlackList(szPlayerName)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    local result = SMClient.AddBlackList(szPlayerName)

    OnCheckAddAchievement(981, "BlackList_First_Add")

    return result
end

function FellowshipData.AddRemoteBlack(szGlobalID, szPlayerName)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    SMClient.AddRemoteBlack(szGlobalID, szPlayerName)

    OnCheckAddAchievement(981, "BlackList_First_Add")
end

function FellowshipData.DelBlackList(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.DelBlackList(dwGlobalID)
end

function FellowshipData.IsInBlackList(dwPlayerID)
    local tbBlackList = FellowshipData.GetBlackListInfo() or {}
    for _, tbBlackInfo in ipairs(tbBlackList) do
        if tbBlackInfo.id == dwPlayerID then
            return true
        end
    end
    return false
end

function FellowshipData.IsInBlackListByPlayerID(dwPlayerID)
    local tbBlackList = FellowshipData.GetBlackListInfo() or {}
    for _, tbBlackInfo in ipairs(tbBlackList) do
        local tbRoleInfo = FellowshipData.GetRoleEntryInfo(tbBlackInfo.id)
        if tbRoleInfo and tbRoleInfo.dwPlayerID == dwPlayerID then
            return true
        end
    end
    return false
end

function FellowshipData.IsInBlackListByName(szName)
    local tbBlackList = FellowshipData.GetBlackListInfo() or {}
    for _, tbBlackInfo in ipairs(tbBlackList) do
        local tbRoleInfo = FellowshipData.GetRoleEntryInfo(tbBlackInfo.id)
        if tbRoleInfo and tbRoleInfo.szName == szName then
            return true
        end
    end
    return false
end

function FellowshipData.GetBlackListInfo()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.GetBlackListInfo() -- {{id = 1, name = "名字"}}
end

function FellowshipData.GetFoeInfo()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.GetFoeInfo() -- {{id = 1, name = "名字", isonline = true}}
end

function FellowshipData.CanAddFoe()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.CanAddFoe()
end

function FellowshipData.PrepareAddFoe(szTarget)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.FELLOWSHIP, "") then
        return
    end

    RemoteCallToServer("OnPrepareAddFoe", szTarget)
end

function FellowshipData.DelFoe(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.DelFoe(dwGlobalID)
end

function FellowshipData.AddFeudComfirm(fnFunc, variables1, variables2, variables3)
    local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "", g_tStrings.STR_ADD_FEUD_COMFIRM, function(szInput)
        if szInput == g_tStrings.STR_ADD_DECIDE_FEUD then
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
               return
            end

            fnFunc(variables1, variables2, variables3)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CANCEL_ADD_FEUD)
        end
    end)

    if editBox then
        editBox:SetTitle(g_tStrings.STR_ADD_FEUD)
        -- editBox:SetPlaceHolder(g_tStrings.STR_ADD_DECIDE_FEUD)
        editBox:SetPlaceHolder("")
    end
end

function FellowshipData.PrepareAddFeud(szTargetGlobalID)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.FELLOWSHIP, "") then
        return
    end

    RemoteCallToServer("On_AddFeud_SuDi", szTargetGlobalID)
end

function FellowshipData.DelFeud(dwGlobalID, szEnemyName)
    local player = GetClientPlayer()
    if not player then return end
    RemoteCallToServer("On_AddFeud_Delete", dwGlobalID, szEnemyName)
end

function FellowshipData.GetFeudInfo()
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end
    return SMClient.GetFeudInfo() -- {{id = 1, name = "名字", isonline = true, feudTime = 111}}
end

function FellowshipData.AddFellowshipGroup(szGroupName)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    return SMClient.AddFellowshipGroup(szGroupName)
end

function FellowshipData.DelFellowshipGroup(dwGroupID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    return SMClient.DelFellowshipGroup(dwGroupID)
end

function FellowshipData.RenameFellowshipGroup(dwGroupID, szGroupName)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    return SMClient.RenameFellowshipGroup(dwGroupID, szGroupName)
end

function FellowshipData.SetFellowshipGroup(dwGroupID, dwOldGroupID, dwNewGroupID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then return end

    return SMClient.SetFellowshipGroup(dwGroupID, dwOldGroupID, dwNewGroupID)
end

function FellowshipData.GetFellowshipCardInfo(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    return SMClient.GetFellowshipCardInfo(dwGlobalID)
end

function FellowshipData.ApplyFellowshipCard(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient or not dwGlobalID then
        return
    end
    SMClient.ApplyFellowshipCard(dwGlobalID)
end

function FellowshipData.GetRoleEntryInfo(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient or not dwGlobalID then
        return
    end

    local tRoleEntryInfo = SMClient.GetRoleEntryInfo(dwGlobalID)
    if tRoleEntryInfo and tRoleEntryInfo.dwCenterID > 0 then
        tRoleEntryInfo.dwCenterID = GetNowCenterIDByCenterID(tRoleEntryInfo.dwCenterID) --2024.7.25合服时centerid开服前未转换做特殊处理
    end

    return tRoleEntryInfo
end

function FellowshipData.ApplyRoleEntryInfo(tbPlayerIDList)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    SMClient.ApplyRoleEntryInfo(tbPlayerIDList)
end

function FellowshipData.ApplyRoleOnlineFlag(tbPlayerIDList)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    SMClient.ApplyRoleOnlineFlag(tbPlayerIDList)
end

function FellowshipData.ApplyRoleMapID(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    SMClient.ApplyRoleMapID(dwGlobalID)
end

function FellowshipData.GetFellowshipMapID(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    return SMClient.GetFellowshipMapID(dwGlobalID)
end

function FellowshipData.IsRemoteFriend(dwGlobalID)
    local tMyRoleEntryInfo = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
    local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(dwGlobalID)
    if tbRoleEntryInfo and tMyRoleEntryInfo then
        local nFriendCenterID = tbRoleEntryInfo.dwCenterID
        local nMyCenterID = tMyRoleEntryInfo.dwCenterID
        if nFriendCenterID ~= 0 and nMyCenterID ~= nFriendCenterID then
            return true
        else
            return false
        end
    end
    return false
end

function FellowshipData.IsOnline(dwGlobalID)
    local SMClient = GetSocialManagerClient()
    if not SMClient then
        return
    end
    return SMClient.IsRoleOnline(dwGlobalID)
end

function FellowshipData.SetRegisterIPToFellowByLoginFlag(enable)
    local player = GetClientPlayer()
    if not player then return end

    player.SetRegisterIPToFellowByLoginFlag(enable)
end

function FellowshipData.GetRegisterIPToFellowByLoginFlag()
    local player = GetClientPlayer()
    if not player then return end

    return player.bRegisterIPToFellowshipByLogin
end

function FellowshipData.GetFellowshipPush(nType)
    if nType == FELLOW_SHIP_PUSH_TYPE.PUSH then
        if not IsRemotePlayer(UI_GetClientPlayerID()) then
            GetPushFellowshipClient().ApplyFellowshipPushList()
        end
    elseif nType == FELLOW_SHIP_PUSH_TYPE.AROUND then
        FellowshipData._ApplyAroundPlayerType()
    elseif nType == FELLOW_SHIP_PUSH_TYPE.IP then
        FellowshipData.GetFellowshipPushByIP()
    elseif nType then
        if not IsRemotePlayer(UI_GetClientPlayerID()) then
            GetPushFellowshipClient().ApplyFellowshipPreferList(nType, 0)
        end
    end
end

function FellowshipData.GetFellowshipPushByIP()
    local player = GetClientPlayer()
    if not player then return end
    return player.GetFellowshipPushByIP()
end

function FellowshipData._ApplyAroundPlayerType()
	local tAroundPlayer = GetClientPlayer().GetAroundPlayerID()
	local nAroundNum = #tAroundPlayer
	if nAroundNum == 0 then
		-- TODO:tips
		return
	end
	local nRandom = math.random(1, nAroundNum)
	for i = 1, FellowshipData.PLAYER_LIST_SHOW_NUM do
		if i > nAroundNum then
			break
		end
		local nNum = i + nRandom
		if nNum > nAroundNum then
			nNum = nNum - nAroundNum
		end
		GetPushFellowshipClient().ApplyFellowshipType(tAroundPlayer[nNum])
	end
end

function FellowshipData.GetFellowshipPushList(nPrefer)
    if nPrefer ~= 0 then
        return GetPushFellowshipClient().GetFellowshipPreferList() -- {dwPlayerID = 111, szName = "推荐好友" dwFellowshipType = 1, dwSubType = 1, dwMiniAvatarID = 0, dwForceID = 1, nCamp = 1, nRoleType = 1, nLevel = 100}
    else
        return GetPushFellowshipClient().GetFellowshipPushList() -- {dwPlayerID = 111, szName = "推荐好友" dwFellowshipType = 1, dwSubType = 1, dwMiniAvatarID = 0, dwForceID = 1, nCamp = 1, nRoleType = 1, nLevel = 100}
    end
end

function FellowshipData.GetAttractionLevel(attraction)
	local nLevel, fP = 1, 0
	if attraction <= 100 then
		nLevel, fP = 1, math.max(attraction / 100, 0)
	elseif attraction <= 200 then
		nLevel, fP = 2, (attraction - 100) / 100
	elseif attraction <= 300 then
		nLevel, fP = 3, (attraction - 200) / 100
	elseif attraction <= 500 then
		nLevel, fP = 4, (attraction - 300) / 200
	elseif attraction <= 800 then
		nLevel, fP = 5, (attraction - 500) / 300
	else
		nLevel, fP = 6, math.min(1, (attraction - 800) / 200)
	end
	return nLevel, fP
end

function FellowshipData.GetWhereDesc(nMapID, tbRoleEntryInfo, attraction)
    local szTextWhere
    if tbRoleEntryInfo.bOnline == false then
        szTextWhere = g_tStrings.STR_FRIEND_CANNOT_KNOW_WHAT_MAP
    else
        if (g_pClientPlayer.nCamp == 1 and tbRoleEntryInfo.nCamp == 2) or (g_pClientPlayer.nCamp == 2 and tbRoleEntryInfo.nCamp == 1) then
            if attraction < FellowshipData.OPPOSITE_CAMP_SHOW_WHERE_NEED_ATTRACTION then
                szTextWhere = string.format(g_tStrings.STR_FRIEND_NEED_ATTRACTION_TO_KNOW_MAP, FellowshipData.OPPOSITE_CAMP_SHOW_WHERE_NEED_ATTRACTION)
            else
                szTextWhere = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
            end
        elseif nMapID and nMapID == 0 then
            szTextWhere = g_tStrings.STR_SINGLE_FRIEND_CANNOT_KNOW_MAP

        elseif nMapID then
            szTextWhere = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
        end
    end

    return szTextWhere
end

function FellowshipData.OnclickBeAddFellowshipInfo(scriptView)
    if table.is_empty(self.tbBeAddFriendPlayerEntryInfo) then
        BubbleMsgData.RemoveMsg("NewAddFellowshipTips")
        UIMgr.Close(VIEW_ID.PanelInvitationMessagePop)
    else
        local tbMessageInfo = FellowshipData.OnclickBeAddFellowship(scriptView)
        if scriptView then
            scriptView:SetInvitationInfo(tbMessageInfo)
        end
    end
end

function FellowshipData.OnclickBeAddFellowship(scriptView)
    local tbInfo = {}
    for k, tbPlayerCard in pairs(self.tbBeAddFriendPlayerEntryInfo) do
        table.insert(tbInfo, {
            szTitle = g_tStrings.STR_FRIEND_NEED_ADD_FRIEND_TITLE,
            tbPlayerCard = tbPlayerCard,
            funcConfirm = function ()
                FellowshipData.AddFellowship(tbPlayerCard.szName)
                self.tbBeAddFriendPlayerEntryInfo[k] = nil
                FellowshipData.OnclickBeAddFellowshipInfo(scriptView)
            end,
            funcCancel = function ()
                self.tbBeAddFriendPlayerEntryInfo[k] = nil
                FellowshipData.OnclickBeAddFellowshipInfo(scriptView)
            end
        })
    end
    return tbInfo
end

function FellowshipData.UpdateBeAddFellowship()
    local player = g_pClientPlayer
    if not player then
        return
    end

    -- 这里要取最新的消息用于展示在及时消息TimelyHint里
    local szGlobalID
    for k, tbInfo in pairs(self.tbBeAddFriendPlayerEntryInfo) do
        szGlobalID = k
    end

    BubbleMsgData.PushMsgWithType("NewAddFellowshipTips", {
        nBarTime = 0,
        szContent = g_tStrings.MSG_FRIEND_BE_ADD_FRIEND,
        szAction = function()
            if not table.is_empty(self.tbBeAddFriendPlayerEntryInfo) then
                local scriptView = UIMgr.Open(VIEW_ID.PanelInvitationMessagePop)
                if scriptView then
                    local tbInfo = FellowshipData.OnclickBeAddFellowship(scriptView)
                    scriptView:SetInvitationInfo(tbInfo)
                end
            end
        end,
        szGlobalID = szGlobalID,
        fnConfirmAction = function ()
            local targetplayer = GetPlayerByGlobalID(szGlobalID) or FellowshipData.tbBeAddFriendPlayerEntryInfo[szGlobalID]
            if not targetplayer then
                return
            end

            FellowshipData.AddFriendByName(targetplayer.szName, self.tbBeAddFriendCenterID[szGlobalID])
            self.tbBeAddFriendCenterID[szGlobalID] = nil
            self.tbBeAddFriendPlayerEntryInfo[szGlobalID] = nil
            FellowshipData.OnclickBeAddFellowshipInfo()
        end,
        fnCancelAction = function ()
            self.tbBeAddFriendCenterID[szGlobalID] = nil
            self.tbBeAddFriendPlayerEntryInfo[szGlobalID] = nil
            FellowshipData.OnclickBeAddFellowshipInfo()
        end,
    })
end

function FellowshipData.UpdateBeAddFoeTips(szSrcName)
    local player = g_pClientPlayer
    if not player then
        return
    end

    BubbleMsgData.PushMsgWithType("NewAddFoeTips", {
        nBarTime = 0,
        szContent = g_tStrings.MSG_FRIEND_BE_ADD_FOE,
        szAction = function()
            local szContent = string.format(g_tStrings.STR_ADD_TO_ENEMY_SURE, UIHelper.GBKToUTF8(szSrcName))
            if FellowshipData.IsFriend(szSrcName) then
                szContent = string.format(g_tStrings.STR_ADD_FRIEND_TO_ENEMY_SURE, UIHelper.GBKToUTF8(szSrcName))
            end

            UIHelper.ShowConfirm(szContent, function ()
                FellowshipData.PrepareAddFoe(szSrcName)
            end)

            BubbleMsgData.RemoveMsg("NewAddFoeTips")
        end,
    })
end

function FellowshipData.TimeToDay(nTime)
    if not nTime or nTime == "" then return "" end
    local nCurrentTime = GetCurrentTime()
    local tTodayDate = TimeToDate(nCurrentTime)
    local nDayTime = 60 * 60 *24
    local nStartTime = DateToTime(tTodayDate.year, tTodayDate.month, tTodayDate.day, 0, 0, 0) + nDayTime
    local nDeltaTime = nStartTime - nTime

    local tDays = {1, 2, 3, 7, 30, 183, 365, 365 * 100}
    for i, day in ipairs(tDays) do
        local nSeconds = nDayTime * day
        if nDeltaTime < nSeconds then
            return g_tStrings.tOffLineTime[nSeconds]
        end
    end
end

--获得同门列表
function FellowshipData.GetMasterApprenticeList(tList, dwPlayerID, aMyApprentice, bDirect)
    table.sort(aMyApprentice, function (a, b) return a.nCreateTime < b.nCreateTime end)
    local szName = g_pClientPlayer.szName
    local tID 		= {}
    for _, v in pairs(tList) do
        if v.dwID == dwPlayerID then
            local bOlder = true
            for k, v in pairs(aMyApprentice) do
                v.bOnLine = v.nOfflineTime == 0
                v.bDelete = not v.szName or v.szName == ""

                if v.szName == szName then
                    v.szRelation = ""
                    v.bOnLine = true
                    v.bSelf = true
                    bOlder = false
                else
                    v.bDirect = bDirect
                    if bOlder then
                        if IsRoleMale(v.nRoleType) then
                            v.szRelation = bDirect and g_tStrings.aApprentice5 or g_tStrings.aApprentice1[k]
                        else
                            v.szRelation = bDirect and g_tStrings.aApprentice6 or g_tStrings.aApprentice2[k]
                        end
                    else
                        if IsRoleMale(v.nRoleType) then
                            v.szRelation = bDirect and g_tStrings.aApprentice7 or g_tStrings.aApprentice3[k]
                        else
                            v.szRelation = bDirect and g_tStrings.aApprentice8 or g_tStrings.aApprentice4[k]
                        end
                    end
                end
                if v.bDelete then
                    v.szName = g_tStrings.MENTOR_DELETE_ROLE
                else
                    table.insert(tID, v.dwID)
                end
            end
            if bDirect then
                v.aDirectApprentice = aMyApprentice
            else
                v.aApprentice = aMyApprentice
            end

            break
        end
    end

    if #tID > 0 then
        GetSocialManagerClient().ApplySocialInfo(tID)
    end
    return tList
end

function FellowshipData.GetMyApprenticeList(tbMyApprentice, bDirect)
    local tID = {}
    for k,v in ipairs(tbMyApprentice) do
        v.bOnLine = v.nOfflineTime == 0
        v.bDelete = not v.szName or v.szName == ""
        v.bDirectA = bDirect
        v.szRelation = bDirect and g_tStrings.STR_DIRECT_APPRENTICE or g_tStrings.aApprentice9[k]
        if v.bDelete then
            v.szName = g_tStrings.MENTOR_DELETE_ROLE
        else
            table.insert(tID, v.dwID)
        end
    end

    if #tID > 0 then
        GetSocialManagerClient().ApplySocialInfo(tID)
    end
    return tbMyApprentice
end

--获得师父的列表
function FellowshipData.GetMyMasterList(tbMyMaster,bDirect)
    local tID = {}
    for k,v in ipairs(tbMyMaster) do
        if v.bOnLine == nil then
            v.bOnLine = v.nOfflineTime == 0
        end

        if v.bDelete == nil then
            v.bDelete = not v.szName or v.szName == ""
        end

        v.szRelation = bDirect and g_tStrings.DIRECT_MASTER or g_tStrings.STR_MENTORMESSAGE_MENTOR
        v.bDirectM = bDirect
        if v.bDelete then
            v.szName = g_tStrings.MENTOR_DELETE_ROLE
        else
            RemoteCallToServer("OnGetApprenticeListRequest", v.dwID)
            RemoteCallToServer("OnGetDirApprenticeListRequest", v.dwID)
            table.insert(tID, v.dwID)
        end
    end

    if #tID > 0 then
        GetSocialManagerClient().ApplySocialInfo(tID)
    end
    return tbMyMaster
end



function FellowshipData.GetFindDirectMasterData(bAccountDirectMentor, aMyDirectMaster)
    if bAccountDirectMentor then
        FellowshipData.m_CanFindDirectMasterNum = 0
        FellowshipData.m_FindDirectMasterErrorCode = ERROR_CODE.ONE
    elseif aMyDirectMaster and #aMyDirectMaster > 0 then
        FellowshipData.m_CanFindDirectMasterNum = -2 --已满
        FellowshipData.m_FindDirectMasterErrorCode = ERROR_CODE.TWO
    else
        FellowshipData.m_CanFindDirectMasterNum = 1
        FellowshipData.m_FindDirectMasterErrorCode = ERROR_CODE.NORMAL
    end

    return FellowshipData.m_CanFindDirectMasterNum > 0 and FellowshipData.m_CanFindDirectMasterNum or 0
end

function FellowshipData.GetFindMasterData(aMyDirectApprentice, aMyApprentice, aMyMaster, m_bGraduate)
    if aMyDirectApprentice and #aMyDirectApprentice > 0 then
        FellowshipData.m_CanFindMasterNum = 0
        FellowshipData.m_FindMasterErrorCode = ERROR_CODE.ONE
    elseif not aMyApprentice or #aMyApprentice > 0 then
        FellowshipData.m_CanFindMasterNum = 0
        FellowshipData.m_FindMasterErrorCode = ERROR_CODE.ONE
    elseif aMyMaster and #aMyMaster == 3 then
        FellowshipData.m_CanFindMasterNum = -2
        FellowshipData.m_FindMasterErrorCode = ERROR_CODE.TWO
    elseif m_bGraduate then --满级且已经出师
        FellowshipData.m_CanFindMasterNum = -1
        FellowshipData.m_FindMasterErrorCode = ERROR_CODE.THREE
    else
        FellowshipData.m_CanFindMasterNum = 3 - #aMyMaster
        FellowshipData.m_FindMasterErrorCode = ERROR_CODE.NORMAL
    end

    return FellowshipData.m_CanFindMasterNum > 0 and FellowshipData.m_CanFindMasterNum or 0
end

function FellowshipData.GetFindDirectApprenticeData(bAccountDirectMentor, aMyDirectApprentice)
    if  g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel then
        FellowshipData.m_CanFindDirectAppNum = 0
        FellowshipData.m_FindDirectAppErrorCode = ERROR_CODE.ONE
    elseif not bAccountDirectMentor then
        FellowshipData.m_CanFindDirectAppNum = 0
        FellowshipData.m_FindDirectAppErrorCode = ERROR_CODE.TWO
    elseif #(aMyDirectApprentice) == g_pClientPlayer.GetMaxDirectApprenticeNum() then
        FellowshipData.m_CanFindDirectAppNum = -2 --已满
        FellowshipData.m_FindDirectAppErrorCode = ERROR_CODE.THREE
    else
        FellowshipData.m_CanFindDirectAppNum = 2 - #aMyDirectApprentice
        FellowshipData.m_FindDirectAppErrorCode = ERROR_CODE.NORMAL
    end

    return FellowshipData.m_CanFindDirectAppNum > 0 and FellowshipData.m_CanFindDirectAppNum or 0
end

function FellowshipData.GetFindApprenticeData(aMyMaster, aMyApprentice)
    if g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel then
        FellowshipData.m_CanFindAppNum = 0
        FellowshipData.m_FindAppErrorCode = ERROR_CODE.ONE
    elseif not aMyMaster or #aMyMaster > 0  then
        FellowshipData.m_CanFindAppNum = 0
        FellowshipData.m_FindAppErrorCode = ERROR_CODE.TWO
    elseif #aMyApprentice == 10 then
        FellowshipData.m_CanFindAppNum = -2 --已满
        FellowshipData.m_FindAppErrorCode = ERROR_CODE.THREE
    else
        FellowshipData.m_CanFindAppNum = 10 - #aMyApprentice
        FellowshipData.m_FindAppErrorCode = ERROR_CODE.NORMAL
    end

    return FellowshipData.m_CanFindAppNum > 0 and FellowshipData.m_CanFindAppNum or 0
end

function FellowshipData.IsTowWayFriend(szGlobalID)
    local bResult = false
    local tbCardInfo = FellowshipData.GetFellowshipCardInfo(szGlobalID)
    if tbCardInfo then
        bResult = tbCardInfo.bIsTwoWayFriend == 1
    end
    return bResult
end

function FellowshipData.GetEntryInfoCD(nRelationType, interval)
    local nowTime = GetTickCount()
    interval = interval or 10000

    local lastTime = FellowshipData.tEntryInfoTime[nRelationType]
    if not lastTime or nowTime - lastTime > interval then
        FellowshipData.tEntryInfoTime[nRelationType] = nowTime
        return true
    end

    return false
end

function FellowshipData.SetAppremticeRedpoint(bVisible)
    if FellowshipData.bApprentice ~= bVisible then
        FellowshipData.bApprentice = bVisible
        Event.Dispatch(EventType.OnUpdateMentorRedpoint)
    end
end

function FellowshipData.SetMentorRedpoint(bVisible)
    if FellowshipData.bMentorRedpoint ~= bVisible then
        FellowshipData.bMentorRedpoint = bVisible
        Event.Dispatch(EventType.OnUpdateMentorRedpoint)
    end
end

function FellowshipData.GetAppremticeRedpoint()
    return FellowshipData.bApprentice
end

function FellowshipData.GetMentorRedpoint()
    return FellowshipData.bMentorRedpoint
end

-----------------------------------FriendRank----------------------------------------------------------

FriendRank = {}

---------------------------------------------------------------
-- 辅助函数
---------------------------------------------------------------

function SortFellowshipRankData(key, ascend)
    local FellowClient = GetFellowshipRankClient()
    if ascend then
        FellowClient.SortFellowshipRankDataLess(key)
    else
        FellowClient.SortFellowshipRankDataGreater(key)
    end
end

function Table_GetFriendRankCatalog()
    local tRes = {}
    local tMainType = {}
    local tab = g_tTable.FriendRank
    local count = tab:GetRowCount()
    for i = 2, count do
        local tLine = tab:GetRow(i)
        if not tRes[tLine.main_key] then
            tRes[tLine.main_key] = {}
            table.insert(tMainType, tLine.main_key)
        end
        table.insert(tRes[tLine.main_key], tLine)
    end
    return tMainType, tRes
end

function Table_GetFriendRank()
    local tRes = {}
    local tab = g_tTable.FriendRank
    local count = tab:GetRowCount()
    for i = 2, count do
        local tLine = tab:GetRow(i)
        table.insert(tRes, tLine)
    end
    return tRes
end

local function table_getkeyinfo(key)
    local tab = g_tTable.FriendRank
    local count = tab:GetRowCount()
    for i = 2, count do
        local tLine = tab:GetRow(i)
        if tLine.key == key then
            return tLine
        end
    end
end

local function get_rqstids()
    local SocialClient = GetSocialManagerClient()
    local ids = {}
    local aGroup = SocialClient.GetFellowshipGroupInfo()
    aGroup = aGroup or {}
    table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })

    for _, v in pairs(aGroup) do
        local aFriend = SocialClient.GetFellowshipInfo(v.id) or {}
        for _, data in pairs(aFriend) do
            table.insert(ids, data.id)
        end
    end

    table.insert(ids, UI_GetClientPlayerGlobalID())
    return ids
end

local function is_time_limit(lasttime, nowtime, interval)
    interval = interval or 10000
    if not lasttime or nowtime - lasttime > interval then
        return false
    end
    return true
end

---------------------------------------------------------------
-- 请求状态机
---------------------------------------------------------------

local _rqst = {
    rqst_time = {},
    waiting = {},
}

function _rqst.is_time_limit(key, nowtime)
    return is_time_limit(_rqst.rqst_time[key], nowtime)
end

function _rqst.is_error(nowtime)
    if not _rqst.state then
        return
    end

    nowtime = nowtime or GetTickCount()
    local keynum = #_rqst.keys
    local idnum = #_rqst.ids

    local cost = math.floor(idnum + 9 / 10) * 10000
    cost = cost * keynum
    cost = math.max(60000, cost)
    cost = math.min(600000, cost)

    if (nowtime - _rqst.start_time) > cost then
        return true
    end
end

function _rqst.resettime(key)
    _rqst.rqst_time[key] = nil
end

function _rqst.needupdate(idnum)
    return (_rqst.last_idnum ~= idnum)
end

function _rqst.run_state()
    return _rqst.state
end

function _rqst.on_keys_respond(key)
    if key ~= _rqst.keys[_rqst.index] then
        return
    end

    FireUIEvent("FELLOW_KEY_DATA_UPDATE", key)

    _rqst.index = _rqst.index + 1
    local len = #_rqst.keys
    if _rqst.index > len then
        _rqst.finish()
        return
    end

    local nextkey = _rqst.keys[_rqst.index]
    _rqst.rqstkey(nextkey, _rqst.ids)
end

function _rqst.rqstkey(key, ids)
    local nowtime = GetTickCount()
    if _rqst.is_time_limit(key, nowtime) then
        _rqst.on_keys_respond(key)
        return
    end

    _rqst.rqst_time[key] = nowtime

    local FellowClient = GetFellowshipRankClient()
    FellowClient.RequestFellowshipRankData(key, ids)
end

function _rqst.start(ids, keys, state)
    _rqst.state = state
    _rqst.index = 1
    _rqst.ids = ids
    _rqst.keys = keys

    _rqst.last_idnum = #ids
    _rqst.start_time = GetTickCount()
    _rqst.rqst_time[state] = _rqst.start_time

    _rqst.rqstkey(keys[_rqst.index], ids)
end

function _rqst.finish(error)
    local state = _rqst.state

    _rqst.state = nil
    _rqst.index = nil
    _rqst.ids = nil
    _rqst.keys = nil

    if state == "all" and not error then
        FireEvent("ALL_EFFORT_DATA_GET")
    end
    _rqst.active_waiting()
end

function _rqst.active_waiting()
    if _rqst.waiting.all then
        local forceupdate = (_rqst.waiting.all == "forceupdate")
        _rqst.waiting.all = nil
        FriendRank.RqstAllKeys(forceupdate)
        return
    end

    if _rqst.waiting.keys and #_rqst.waiting.keys > 0 then
        local ids = get_rqstids()
        local keys = {}
        local flag = {}
        for _, key in pairs(_rqst.waiting.keys) do
            if not flag[key] then
                flag[key] = true
                table.insert(keys, key)
                _rqst.resettime(key)
            end
        end

        _rqst.waiting.keys = nil
        _rqst.start(ids, keys, "single")
        return
    end
end

---------------------------------------------------------------
-- FriendRank 公共接口
---------------------------------------------------------------

function FriendRank.RqstingTreat(state, forceupdate, ids, key)
    if _rqst.is_error() then
        _rqst.finish(true)
    end

    local runstate = _rqst.run_state()
    local ret = (runstate ~= nil)
    if not ret then
        return ret
    end

    local updateids = _rqst.needupdate(#ids)
    local nowtime = GetTickCount()

    if not forceupdate and not updateids then
        if state == "all" and _rqst.is_time_limit(state, nowtime) then
            FireEvent("ALL_EFFORT_DATA_GET")
            return ret
        elseif state == "single" and _rqst.is_time_limit(key, nowtime) then
            FireUIEvent("FELLOW_KEY_DATA_UPDATE", key)
            return ret
        end
    end

    if state == "all" then
        _rqst.waiting.all = _rqst.waiting.all or true
        if forceupdate then
            _rqst.waiting.all = "forceupdate"
        end
    else
        if runstate == "single" and not updateids then
            local exist = false
            for _, v in pairs(_rqst.keys) do
                if v == key then
                    exist = true
                    break
                end
            end

            if not exist then
                if forceupdate then
                    _rqst.resettime(key)
                end
                table.insert(_rqst.keys, key)
            end
        else
            _rqst.waiting.keys = _rqst.waiting.keys or {}
            table.insert(_rqst.waiting.keys, key)
        end
    end
    return ret
end

function FriendRank.RqstKey(key, forceupdate)
    local ids = get_rqstids()
    local state = "single"

    if FriendRank.RqstingTreat(state, forceupdate, ids, key) then
        return
    end

    local idnum = #ids
    local nowtime = GetTickCount()
    if forceupdate or _rqst.needupdate(idnum) and idnum > 0 then
        _rqst.resettime(key)
    end

    if idnum > 0 then
        _rqst.start(ids, { key }, state)
    end
end

function FriendRank.RqstAllKeys(forceupdate)
    local ids = get_rqstids()
    local state = "all"
    if FriendRank.RqstingTreat(state, forceupdate, ids) then
        return
    end

    local idnum = #ids
    local nowtime = GetTickCount()
    if not forceupdate and not _rqst.needupdate(idnum) and _rqst.is_time_limit(state, nowtime) then
        FireEvent("ALL_EFFORT_DATA_GET")
        return
    end

    local keys = {}
    local ranks = Table_GetFriendRank()
    for _, v in pairs(ranks) do
        table.insert(keys, v.key)
    end

    if #keys > 0 and idnum > 0 then
        _rqst.start(ids, keys, state)
    end
end

function FriendRank.GetFellowInfo()
    if not FriendRank.aFriend then
        FriendRank.UpdateFellowInfo()
    end

    return FriendRank.aFriend, FriendRank.friend_num
end

function FriendRank.UpdateFellowInfo()
    local friend_num = 0
    local tFriends = {}
    local player = GetClientPlayer()
    local SocialClient = GetSocialManagerClient()

    if not player then
        LOG.ERROR("player is nil")
        return
    end

    if not SocialClient then
        LOG.ERROR("SocialClient is nil")
        return
    end
    local aGroup = SocialClient.GetFellowshipGroupInfo()
    aGroup = aGroup or {}
    table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })

    for _, v in pairs(aGroup) do
        local aFriend = SocialClient.GetFellowshipInfo(v.id) or {}
        for _, data in pairs(aFriend) do
            local aRoleEntry = FellowshipData.GetRoleEntryInfo(data.id)
            if aRoleEntry then
                tFriends[data.id] = data
                data.name = aRoleEntry.szName
                data.forceid = aRoleEntry.nForceID
                data.level = aRoleEntry.nLevel
                friend_num = friend_num + 1
            else
                LOG.ERROR(string.format("aRoleEntry is nil, id = %d", data.id))
            end
        end
    end
    local GlobalID = UI_GetClientPlayerGlobalID()
    if not GlobalID then
        LOG.ERROR("GlobalID is nil")
        return
    end
    tFriends[GlobalID] = { name = player.szName, forceid = player.dwForceID, level = player.nLevel }
    FriendRank.aFriend = tFriends
    FriendRank.friend_num = friend_num + 1
end

--- 暴露 _rqst.on_keys_respond 供外部事件回调使用
function FriendRank.OnKeysRespond(key)
    _rqst.on_keys_respond(key)
end

Event.Reg(FriendRank, "UpdateFellowshipRankData", function(arg0, arg1, arg2, arg3)
    FriendRank.OnKeysRespond(arg0)
end)
