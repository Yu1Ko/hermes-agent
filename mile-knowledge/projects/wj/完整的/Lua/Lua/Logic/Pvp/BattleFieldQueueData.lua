BattleFieldQueueData = BattleFieldQueueData or {className = "BattleFieldQueueData"}
local self = BattleFieldQueueData

local tbNotifyList = {}
local tbTongBattleFieldNotifyList = {}
local bBlacklist = false
local nBlacklistLastTime = 0

local tbMutexBattleMapID = { 322, 296 }

--2024.3.14 新需求
local tExtraMapID = {
    [BATTLE_FIELD_MAP_ID.FU_XIANG_QIU] = BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG,
    [BATTLE_FIELD_MAP_ID.SHEN_NONG_YIN] = BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG,
}

BattleFieldQueueData.szTempPersonalScore = nil

function BattleFieldQueueData.Init()
    self.RegEvent()
end

function BattleFieldQueueData.UnInit()
    Event.UnRegAll(self)
end

function BattleFieldQueueData.RegEvent()
    Event.Reg(self, "BATTLE_FIELD_NOTIFY", function(nType, nAvgQueueTime, nPassTime, dwMapID,
        nCopyIndex, nCenterID, nGroupID, dwJoinValue, bTeamJoin, dwBattlefieldRound, bGlobalRoomJoin, bChaosFight, nRoomKey, nRoomVisitKey, nRoomRoleCount, nRoomVisitRoleCount, bRoomOnwer)

        self.OnBattleFieldNotify(dwMapID, nType, nAvgQueueTime, nPassTime,
        nCopyIndex, nCenterID, nGroupID, dwJoinValue, bTeamJoin, dwBattlefieldRound, bGlobalRoomJoin, bChaosFight, nRoomKey, nRoomVisitKey, nRoomRoleCount, nRoomVisitRoleCount, bRoomOnwer)
    end)

    Event.Reg(self, "TONG_BATTLE_FIELD_NOTIFY", function(nType, nPassTime, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
        self.OnTongBattleFieldNotify(nType, nPassTime, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
    end)

    --加入战场队列
    Event.Reg(self, "JOIN_BATTLE_FIELD_QUEUE", function(dwMapID, nCode, dwRoleID, szRoleName)
        self.Log("JOIN_BATTLE_FIELD_QUEUE", dwMapID, nCode, dwRoleID, UIHelper.GBKToUTF8(szRoleName))
        self.OnJoinBattleFieldQueue(dwMapID, nCode, dwRoleID, szRoleName)
    end)

    --离开战场队列
    Event.Reg(self, "LEAVE_BATTLE_FIELD_QUEUE", function(dwMapID)
        self.Log("LEAVE_BATTLE_FIELD_QUEUE", dwMapID)
        self.OnLeaveBattleFieldQueue(dwMapID)
    end)

    --山寨做法，由于跨服的时候收不到LEAVE_BLACK_LIST消息,玩家出来后不会刷新
    Event.Reg(self, "LOADING_END", function()
        if not BattleFieldData.IsInBattleField() then
            Event.Dispatch("BATTLE_FIELD_NOTIFY", BATTLE_FIELD_NOTIFY_TYPE.LEAVE_BLACK_LIST)
        end
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        tbNotifyList = {}
    end)
end

function BattleFieldQueueData.OnBattleFieldNotify(dwMapID, nNotifyType, nAvgQueueTime, nPassTime, nCopyIndex, nCenterIndex, nGroupID, dwJoinValue, bTeamJoin, dwBattlefieldRound, bGlobalRoomJoin, bChaosFight, nRoomKey, nRoomVisitKey, nRoomRoleCount, nRoomVisitRoleCount, bRoomOnwer)
    -- self.Log("BattleFieldQueueData.OnBattleFieldNotify ", dwMapID, nNotifyType, nAvgQueueTime, nPassTime, nCopyIndex, nCenterIndex, nGroupID, dwJoinValue, bTeamJoin, dwBattlefieldRound, bGlobalRoomJoin)
    -- update data
    local nRelJoinMapID = dwMapID
    local dwFatherMapID = BattleFieldData.GetBattleFieldFatherID(dwMapID)
    if dwFatherMapID ~= 0 then
        dwMapID = dwFatherMapID
    end

    if nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO
    or nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
        local bFirst = false
        local tbNotify = tbNotifyList[dwMapID]
        if not tbNotify then
            tbNotify = {}
            tbNotifyList[dwMapID] = tbNotify
            bFirst = true
        end
        local nOldType = tbNotify.nNotifyType
        tbNotify.nNotifyType = nNotifyType
        tbNotify.nAvgQueueTime = nAvgQueueTime
        tbNotify.nPassTime = nPassTime
        tbNotify.bTeamJoin = bTeamJoin
        tbNotify.bGlobalRoom = bGlobalRoomJoin
        tbNotify.bChaosFight = bChaosFight == 1
        --随机地图的加入值传什么就用什么
        tbNotify.dwRelJoinMapID = nRelJoinMapID
        if nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
            tbNotify.nCopyIndex = nCopyIndex
            tbNotify.nCenterIndex = nCenterIndex
        end

        tbNotify.nGroupID = nGroupID
        tbNotify.dwJoinValue = dwJoinValue
        if nOldType == nNotifyType then
            Event.Dispatch("BATTLE_FIELD_UPDATE_TIME")
        end

        if bFirst then
            local szName = UIHelper.GBKToUTF8(self.GetBattleFieldQueueName(dwMapID))
            local dwQueueMapID = dwMapID
            local tbInfo = {
                szTitle = szName .. "排队中",
                onClickCancelQueue = function()
                    self.DoLeaveBattleFieldQueue(dwQueueMapID)
                end
            }

            BubbleMsgData.PushMsgWithType("BattleFieldQueueTips", {
                szTitle = szName .. "排队中",
                nBarTime = 0,                       -- 显示在气泡栏的时长, 单位为秒
                szContent = function()
                    local nPassTime, nAvgQueueTime = self.GetQueueTime()
                    local szContent = string.format("预计排队：%s\n已排队%s", self.FormatBattleFieldTime(nAvgQueueTime), self.FormatBattleFieldTime(nPassTime))
                    return szContent, 0.5
                end,
                szAction = function()
                    PvpEnterConfirmationData.OpenView(PlayEnterConfirmationType.InQueue, PlayType.BattleField, tbInfo)
                end,
            })

            Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
        end
    elseif nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.LEAVE_BATTLE_FIELD then
        tbNotifyList[dwMapID] = nil
        BubbleMsgData.RemoveMsg("BattleFieldQueueTips")
        Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    elseif nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.IN_BLACK_LIST then
        bBlacklist = true
        nBlacklistLastTime = nPassTime
        Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    elseif nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.LEAVE_BLACK_LIST then
        bBlacklist = false
        nBlacklistLastTime = nil
        Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    end

    if nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
        local tbNotify = tbNotifyList[dwMapID]
        if not tbNotify.bRemind then
            tbNotify.bRemind = true
            tbNotify.dwStartTime = GetTickCount()
            tbNotify.nBattleEnterCount = Const.MAX_BATTLE_FIELD_OVERTIME
            local dialog = nil
            local szName = UIHelper.GBKToUTF8(self.GetBattleFieldQueueName(dwMapID))
            local tbInfo = {
                szTitle = szName .. "匹配成功",
                nStartTime = tbNotify.dwStartTime,
                nTotalCountDown = Const.MAX_BATTLE_FIELD_OVERTIME,
                onClickEnter = function()
                    self.DoAcceptJoinBattleField(tbNotify.nCenterIndex, dwMapID,
                    tbNotify.nCopyIndex, tbNotify.nGroupID, tbNotify.dwJoinValue)
                    UIMgr.CloseAllInLayer("UIPageLayer")
                    UIMgr.CloseAllInLayer("UIPopupLayer")
                    if dialog then
                        UIMgr.Close(dialog)
                    end
                end,
                onClickGiveUp = function()
                    local szMsg = FormatString(g_tStrings.STR_BATTLEFIELD_MESSAGE_SURE_LEAVE, szName)
                    dialog = UIHelper.ShowConfirm(szMsg, function()
                        RemoteCallToServer("On_Zhanchang_NotEnter", dwMapID)
                        self.DoLeaveBattleFieldQueue(dwMapID)
                        PvpEnterConfirmationData.CloseView(PlayType.BattleField)
                    end)
                end,
            }

            PSMMgr.ExitPSMMode()
            PvpEnterConfirmationData.OpenView(PlayEnterConfirmationType.Enter, PlayType.BattleField, tbInfo)

            BubbleMsgData.RemoveMsg("BattleFieldQueueTips")
            BubbleMsgData.PushMsgWithType("PVPMatchSuccessTips", {
                nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
                szContent = "已匹配成功",
                nStartTime = GetCurrentTime(),
                nEndTime = Const.MAX_BATTLE_FIELD_OVERTIME + GetCurrentTime(),
                nTotalTime = Const.MAX_BATTLE_FIELD_OVERTIME,
                bShowTimeLabel = true,
                bHideTimeSilder = true,
                szAction = function ()
                    PvpEnterConfirmationData.ShowView(PlayType.BattleField)
                end,
            })
        end
        Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    end

    if bChaosFight == 1 then
        TreasureBattleFieldData.UpdateRoomInfo({
			dwMapID = nRelJoinMapID,
			dwFatherMapID = dwFatherMapID,
			bChaosFight == bChaosFight == 1,
			nRoomKey = nRoomKey,
			nRoomVisitKey = nRoomVisitKey,
			nRoomRoleCount = nRoomRoleCount,
			nRoomVisitRoleCount = nRoomVisitRoleCount,
			bRoomOnwer = bRoomOnwer == 1,
		})
    end
end

function BattleFieldQueueData.OnTongBattleFieldNotify(nNotifyType, nPassTime, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
    self.Log("BattleFieldQueueData.OnTongBattleFieldNotify ", nNotifyType, nPassTime, dwMapID, nCopyIndex, nGroupID, dwJoinValue)

    if dwMapID == 0 then
        dwMapID = 149
    end

    if nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO
    or nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
        local bFirst = false
        local tbNotify = tbTongBattleFieldNotifyList[dwMapID]
        if not tbNotify then
            tbNotify = {}
            tbTongBattleFieldNotifyList[dwMapID] = tbNotify
            bFirst = true
        end
        local nOldType = tbNotify.nNotifyType
        tbNotify.nNotifyType = nNotifyType
        tbNotify.nPassTime = nPassTime

        if nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
            tbNotify.nCopyIndex = nCopyIndex
        end

        tbNotify.nGroupID = nGroupID
        tbNotify.dwJoinValue = dwJoinValue
        if nOldType == nNotifyType then
            Event.Dispatch("TONG_BATTLE_FIELD_UPDATE_TIME")
        end

        if bFirst then
            do
                local szName = UIHelper.GBKToUTF8(self.GetBattleFieldQueueName(dwMapID))
                local dwQueueMapID = dwMapID
                local tbInfo = {
                    szTitle = szName .. "排队中",
                    onClickCancelQueue = function()
                        self.DoLeaveTongBattleFieldQueue(dwQueueMapID)
                    end
                }

                BubbleMsgData.PushMsgWithType("TongBattleFieldQueueTips", {
                    szTitle = szName .. "排队中",
                    nBarTime = 0,                       -- 显示在气泡栏的时长, 单位为秒
                    szContent = function()
                        local nCurrentPassTime = self.GetTongBattleFieldQueueTime()
                        local szContent = string.format("已排队%s", self.FormatBattleFieldTime(nCurrentPassTime))
                        return szContent, 0.5
                    end,
                    szAction = function()
                        PvpEnterConfirmationData.OpenView(PlayEnterConfirmationType.InQueue, PlayType.TongBattleField, tbInfo)
                    end,
                })
            end

            Event.Dispatch("TONG_BATTLE_FIELD_STATE_UPDATE")
        end
    elseif nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.LEAVE_BATTLE_FIELD then
        --CloseMessageBox("BattleField_Enter_" .. dwMapID)
        BubbleMsgData.RemoveMsg("TongBattleFieldQueueTips")

        tbTongBattleFieldNotifyList[dwMapID] = nil
        Event.Dispatch("TONG_BATTLE_FIELD_STATE_UPDATE")
    end

    if nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
        local tbNotify = tbTongBattleFieldNotifyList[dwMapID]
        if not tbNotify.bRemind then
            tbNotify.bRemind = true

            do
                --TongBattleField_MessageBoxCanEnter(dwMapID)
                local dwStartTime = GetTickCount()

                local tbInfo = {
                    szTitle = UIHelper.GBKToUTF8(self.GetBattleFieldQueueName(dwMapID)) .. "匹配成功",
                    nStartTime = dwStartTime,
                    nTotalCountDown = Const.MAX_TONG_BATTLE_FIELD_OVERTIME,
                    onClickEnter = function()
                        AcceptJoinTongBattleField(dwMapID,
                                                  tbNotify.nCopyIndex, tbNotify.nGroupID, tbNotify.dwJoinValue)
                        UIMgr.CloseAllInLayer("UIPageLayer")
                        UIMgr.CloseAllInLayer("UIPopupLayer")
                    end
                }

                PSMMgr.ExitPSMMode()
                PvpEnterConfirmationData.OpenView(PlayEnterConfirmationType.Enter, PlayType.TongBattleField, tbInfo)
                BubbleMsgData.RemoveMsg("TongBattleFieldQueueTips")
            end
        end
        Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    end
end

function BattleFieldQueueData.IsInBattleFieldQueue(dwMapID)
    if tbNotifyList[dwMapID] and tbNotifyList[dwMapID].nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO then
        if tbNotifyList[dwMapID].bGlobalRoom == 1 then
            return true, false, true
        elseif tbNotifyList[dwMapID].bTeamJoin == 1 then
            return true, false, false
        else
            return true, true, false
        end
    end
    return false, false, false;
end

function BattleFieldQueueData.GetBattleFieldNotify(dwMapID)
    return tbNotifyList[dwMapID]
end

function BattleFieldQueueData.IsInTongBattleFieldQueue(dwMapID)
    if  tbTongBattleFieldNotifyList[dwMapID] and
        tbTongBattleFieldNotifyList[dwMapID].nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO then
        return true
    end
    return false
end

function BattleFieldQueueData.IsCanEnterTongBattleField()
    if not tbTongBattleFieldNotifyList then
        return false
    end

    for dwMapID, t in pairs(tbTongBattleFieldNotifyList) do
        if t and t.nNotifyType == TONG_BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD then
            return true;
        end
    end
    return false;
end

function BattleFieldQueueData.GetBattleFieldBlackCoolTime()
    return nBlacklistLastTime
end

--战场时间获取
function BattleFieldQueueData.GetJoinBattleQueueTime(nMapID)
    for dwMapID, tData in pairs(tbNotifyList) do
        if tData.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO and dwMapID == nMapID then
            return tData.nPassTime
        end
    end
end

function BattleFieldQueueData.GetJoinTongBattleQueueTime(nMapID)
    for dwMapID, tData in pairs(tbTongBattleFieldNotifyList) do
        if tData.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO and dwMapID == nMapID then
            return tData.nPassTime
        end
    end
end

function BattleFieldQueueData.GetBattleFieldQueueName(dwMapID)
    return Table_GetBattleFieldName(dwMapID)
end

function BattleFieldQueueData.IsInBattleFieldBlackList()
    return bBlacklist
end

function BattleFieldQueueData.GetQueueTime()
    local nPassTime, nAvgQueueTime = 0, 0
    for _, tbInfo in pairs(tbNotifyList) do
        if tbInfo.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO then
            nPassTime, nAvgQueueTime = tbInfo.nPassTime, tbInfo.nAvgQueueTime
            break
        end
    end

    return nPassTime, nAvgQueueTime
end

function BattleFieldQueueData.GetTongBattleFieldQueueTime()
    local nPassTime = 0
    for _, tbInfo in pairs(tbTongBattleFieldNotifyList) do
        if tbInfo.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.QUEUE_INFO then
            nPassTime = tbInfo.nPassTime
            break
        end
    end

    return nPassTime
end

-------------------------------- 战场排队相关 --------------------------------

--判断寻宝能否匹配
function BattleFieldQueueData.CheckCanJoinQueue(dwMapID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    -- local bLegal    = false
    -- local szText    = ""
    -- local nCurMoney = hPlayer.nExamPrint
    -- local nCurValue, nNormalValue, nHardValue, nTicket = GDAPI_TbfWarePreValue()

    -- if dwMapID == 709 then
    --     bLegal = nCurValue <= nNormalValue
    --     szText = FormatString(g_tStrings.STR_TREASURE_HUNT_VALUE_OUT_OF_LIMITED, nNormalValue)
    -- elseif dwMapID == 715 then
    --     bLegal = nCurValue >= nHardValue
    --     szText = FormatString(g_tStrings.STR_TREASURE_HUNT_VALUE_NOT_ENOUGH, nHardValue)

    --     if bLegal then
    --         bLegal = nCurMoney >= nTicket
    --         szText = FormatString(g_tStrings.STR_TREASURE_HUNT_MONEY_NOT_ENOUGH, nTicket)
    --     end
    -- end

    -- if not bLegal then
    --     TipsHelper.ShowNormalTip(szText)
    --     return
    -- end
    return true
end

function BattleFieldQueueData.OperateBattleFieldQueue(dwMapID, nType, bTeam, bRoom)
    local bInQueue = self.IsInBattleFieldQueue(dwMapID)
    if bInQueue then
        self.DoLeaveBattleFieldQueue(dwMapID)
    else
        self.EnterBattleFieldQueue(dwMapID, nType, bTeam, bRoom)
    end
end

--加入匹配
function BattleFieldQueueData.EnterBattleFieldQueue(dwMapID, nType, bTeam, bRoom, bPractice)
    local player = GetClientPlayer()
    local nGroupID = 0 -- 齐物阁战场是0
    if nType == 0 and player.nCamp == CAMP.NEUTRAL then
        OutputMessage("MSG_SYS", g_tStrings.STR_BATTLEFIELD_NETURAL_NOT_ENTER)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BATTLEFIELD_NETURAL_NOT_ENTER)
        return
    end
    if not dwMapID then
        return
    end

    if CheckIsInTable(tbMutexBattleMapID, dwMapID) then
        for _, dwMutexMapID in pairs(tbMutexBattleMapID) do
            if self.IsInBattleFieldQueue(dwMutexMapID) and dwMutexMapID ~= dwMapID then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BATTLE_MUTEXMAP_ENTER)
                return
            end
        end
    end

    local fnJoinBattleFieldQueue = function()
        if bRoom then
            --房主排队
            if Table_IsTreasureBattleFieldMap(dwMapID) then	--吃鸡GroupID只能是0
                nGroupID = 0
            else
                nGroupID = Random(GetTickCount()) % 2
            end
            self.Log("On_Zhanchang_RoomBattlefield", dwMapID, nGroupID, bPractice or false)
            RemoteCallToServer("On_Zhanchang_RoomBattlefield", dwMapID, nGroupID, bPractice or false)
            return
        end

        --战场排队修改为全部随机选边
        nGroupID = nType == 0 and (Random(GetTickCount()) % 2) or nGroupID

        self.Log("JoinBattleFieldQueue", dwMapID, nGroupID, bTeam, bPractice)
        JoinBattleFieldQueue(dwMapID, nGroupID, bTeam, bPractice)
    end

    --寻宝模式判断装备价值是否满足
    if Table_IsTreasureHuntMap(dwMapID) then
        local nCurValue, nNormalValue, nHardValue, nTicket = GDAPI_TbfWarePreValue()
        local bHasManaItem = GDAPI_TbfWareCheckManaItem()
        if nCurValue == 0 then
            local fnComfirm = function() ExtractWareHouseData.OpenExtractPersetPanel() end
            local fnCancel = function()
                if BattleFieldQueueData.CheckCanJoinQueue(dwMapID) then
                    fnJoinBattleFieldQueue()
                end
            end

            local scriptHuntTip = UIHelper.ShowConfirm(g_tStrings.STR_TREASURE_HUNT_NO_PRESET, fnComfirm, fnCancel)
            scriptHuntTip:SetButtonContent("Confirm", g_tStrings.STR_TREASURE_HUNT_DO_PRESET)
            scriptHuntTip:SetButtonContent("Cancel", g_tStrings.STR_TREASURE_HUNT_CONTINUE_QUEUE)
            return
        elseif not bHasManaItem then
            local fnComfirm = function() ShopData.OpenSystemShopGroup(27, 1536) end
            local fnCancel = function()
                if BattleFieldQueueData.CheckCanJoinQueue(dwMapID) then
                    fnJoinBattleFieldQueue()
                end
            end

            local scriptHuntTip = UIHelper.ShowConfirm(g_tStrings.STR_TREASURE_HUNT_NO_MANA_ITEM, fnComfirm, fnCancel)
            scriptHuntTip:SetButtonContent("Confirm", g_tStrings.STR_TREASURE_HUNT_GO_SHOPPING)
            scriptHuntTip:SetButtonContent("Other", g_tStrings.STR_TREASURE_HUNT_DO_PRESET)
            scriptHuntTip:SetButtonContent("Cancel", g_tStrings.STR_TREASURE_HUNT_CONTINUE_QUEUE)
            scriptHuntTip:ShowOtherButton()
            scriptHuntTip:SetOtherButtonClickedCallback(function()
                ExtractWareHouseData.OpenExtractPersetPanel()
            end)
            return
        end

        if not BattleFieldQueueData.CheckCanJoinQueue(dwMapID) then
            return
        end
    end

    fnJoinBattleFieldQueue()
    return true
end

function BattleFieldQueueData.DoAcceptJoinBattleField(nCenterIndex, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
    if not tbNotifyList[dwMapID] then return end

    local nRelJoinMapID = tbNotifyList[dwMapID].dwRelJoinMapID
    tbNotifyList[dwMapID] = nil
    Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")
    AcceptJoinBattleField(nCenterIndex, nRelJoinMapID, nCopyIndex, nGroupID, dwJoinValue)
end

function BattleFieldQueueData.DoLeaveBattleFieldQueue(dwMapID)
    if not tbNotifyList[dwMapID] then return end

    local nRelJoinMapID = tbNotifyList[dwMapID].dwRelJoinMapID
    tbNotifyList[dwMapID] = nil
    Event.Dispatch("BATTLE_FIELD_STATE_UPDATE")

    self.Log("LeaveBattleFieldQueue", nRelJoinMapID)
    LeaveBattleFieldQueue(nRelJoinMapID)
end

function BattleFieldQueueData.DoLeaveTongBattleFieldQueue(dwMapID)
    if not tbTongBattleFieldNotifyList[dwMapID] then return end

    tbTongBattleFieldNotifyList[dwMapID] = nil
    Event.Dispatch("TONG_BATTLE_FIELD_STATE_UPDATE")

    self.Log("LeaveTongBattleFieldQueue")
    LeaveTongBattleFieldQueue()
end

function BattleFieldQueueData.OnJoinBattleFieldQueue(dwMapID, nCode, dwRoleID, szRoleName)
    if nCode == BATTLE_FIELD_RESULT_CODE.SUCCESS then
        OutputMessage("MSG_SYS", g_tStrings.STR_BATTLEFIELD_JOIN_QUEUE[nCode])
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BATTLEFIELD_JOIN_QUEUE[nCode])

        local tMapList = {dwMapID, tExtraMapID[dwMapID]}
        if Table_IsTreasureBattleFieldMap(dwMapID) then
            tMapList = TreasureBattleFieldData.GetDownloadMapIDList()
        end
        for _, dwMapID in ipairs(tMapList) do
            local nState, dwTotalSize, dwDownloadedSize = PakDownloadMgr.GetMapResPackState(dwMapID)
            if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED and dwDownloadedSize < dwTotalSize then
                TipsHelper.ShowNormalTip("未下载场景资源，玩法中途下载将影响游戏体验")
                break
            end
        end
    else
        local szName = szRoleName
        local player = GetClientPlayer()
        local szTip = g_tStrings.STR_BATTLEFIELD_JOIN_QUEUE[nCode]

        if szTip then
            if not string.is_nil(szName) and szName ~= player.szName then
                szTip = FormatString(szTip, g_tStrings.STR_BATTLE_JION_QUEUE_TIP1 .. "[" .. UIHelper.GBKToUTF8(szName) .. "]")
            else
                szTip = FormatString(szTip, g_tStrings.STR_BATTLE_JION_QUEUE_TIP)
            end

            OutputMessage("MSG_ANNOUNCE_RED", szTip);
            OutputMessage("MSG_SYS", szTip);
        end
    end
    if nCode == BATTLE_FIELD_RESULT_CODE.SUCCESS then
        PlayTipSound("018")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.FAILED then
        PlayTipSound("019")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.IN_BLACK_LIST then
        PlayTipSound("020")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.LEVEL_ERROR then
        PlayTipSound("021")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.FORCE_ERROR then
        PlayTipSound("022")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.TEAM_MEMBER_ERROR then
    elseif nCode == BATTLE_FIELD_RESULT_CODE.TEAM_SIZE_ERROR then
        PlayTipSound("023")
    elseif nCode == BATTLE_FIELD_RESULT_CODE.TOO_MANY_JOIN then
    elseif nCode == BATTLE_FIELD_RESULT_CODE.CAMP_ERROR then
    elseif nCode == BATTLE_FIELD_RESULT_CODE.TIME_ERROR then
    elseif nCode == BATTLE_FIELD_RESULT_CODE.IN_DUNGEON_QUEUE then
    elseif nCode == BATTLE_FIELD_RESULT_CODE.MAX_PARTY_SIZE_ERROR then
    end

    if nCode == BATTLE_FIELD_RESULT_CODE.SUCCESS then
        local tInfo = Table_GetBFCustomRoomMapInfo(dwMapID)
        if tInfo and tInfo.nRoomType > 0 then
            TreasureBattleFieldData.UpdateRoomNotify(dwMapID)
        end
    end
end

function BattleFieldQueueData.OnLeaveBattleFieldQueue(dwMapID)
    OutputMessage("MSG_SYS", g_tStrings.STR_BATTLEFIELD_LEAVE_QUEUE)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BATTLEFIELD_LEAVE_QUEUE)
    Event.Dispatch("BATTLE_FIELD_NOTIFY", BATTLE_FIELD_NOTIFY_TYPE.LEAVE_BATTLE_FIELD, nil, nil, dwMapID)

    local tInfo = Table_GetBFCustomRoomMapInfo(dwMapID)
    if tInfo and tInfo.nRoomType > 0 then
        TreasureBattleFieldData.UpdateRoomInfo(nil)
        TreasureBattleFieldData.UpdateRoomNotify(nil)
    end
end

-------------------------------- 杂项 --------------------------------

function BattleFieldQueueData.FormatBattleFieldTime(nTime)
    local szTime
    if nTime > 60 then
        szTime = math.floor(nTime / 60) .. g_tStrings.STR_BUFF_H_TIME_M
    else
        szTime = nTime .. g_tStrings.STR_BUFF_H_TIME_S
    end
    return szTime
end

function BattleFieldQueueData.NumberBattleFieldTime(nTime)
    local szTime
    if nTime > 60 then
        szTime = math.floor(nTime / 60) .. ":"
        if math.floor(nTime % 60) < 10 then
            szTime = szTime .. "0" .. math.floor(nTime % 60)
        else
            szTime = szTime .. math.floor(nTime % 60)
        end
    else
        szTime = "00:"
        if nTime < 10 then
            szTime = szTime .. "0" .. nTime
        else
            szTime = szTime .. nTime
        end
    end
    return szTime
end

function BattleFieldQueueData.GetExtraMapID(dwMapID)
    return tExtraMapID[dwMapID]
end

function BattleFieldQueueData.Log(...)
    local len = select('#', ...)
    local tbMsg = {...}
    local str = ""
    for i = 1, len do
        local msg = tbMsg[i]
        if msg ~= nil then
            str = str .. tostring(msg)
        else
            str = str .. "nil"
        end
        if i ~= len then
            str = str .. "\t"
        end
    end

    LOG.INFO("[BattleFieldQueueData] %s", str)
end