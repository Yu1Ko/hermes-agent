-- 聊天菜单Tips


ChatTips = ChatTips or {}



-- 显示玩家菜单
function ChatTips.ShowPlayerTips(widgetHead, tbChatData)
    if not widgetHead then return end
    if not tbChatData then return end

    local dwTalkerID = tbChatData.dwTalkerID
    local szName = tbChatData.szName
    local dwMiniAvatarID = tbChatData.dwMiniAvatarID
    local dwForceID = tbChatData.dwForceID
    local nLevel = tbChatData.nLevel or 100
    local nCamp = tbChatData.nCamp
    local nRoleType = tbChatData.nRoleType
    local szGlobalID = tbChatData.szGlobalID
    local bRoomChannel = tbChatData.nChannel == PLAYER_TALK_CHANNEL.ROOM

    local dwCenterID = tbChatData.dwCenterID

    local tbRoomMenus = RoomData.InsertRoomInviteMenu({}, szGlobalID)

    local tbAllMenuConfig = {
        {
            szName = "密聊",
            bCloseOnClick = true,
            callback = function()
                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID}
                ChatHelper.WhisperTo(szName, tbData)
            end
        },

        {
            szName = "组队",
            bCloseOnClick = true,
            callback = function()
                TeamData.InviteJoinTeam(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not TeamData.CanMakeParty()
            end
        },

        -- 房间按钮
        tbRoomMenus[1],

        {
            szName = "加为好友",
            bCloseOnClick = true,
            callback = function()
                FellowshipData.AddFellowship(UTF8ToGBK(szName))
            end,
            fnCheckShow = function () return not FellowshipData.IsFriend(szGlobalID) end,
        },

        {
            szName = "拜师收徒", bNesting = true, tbSubMenus =
            {
                { szName = "收徒", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyApprentice", UIHelper.UTF8ToGBK(szName))
                end },
                { szName = "拜师", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyMentor", UIHelper.UTF8ToGBK(szName))
                end },
                { szName = "拜亲传师父", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyDirectMentor", UIHelper.UTF8ToGBK(szName))
                end },
            }
        },

        {
            szName = "查看装备",
            bCloseOnClick = true,
            callback = function()
                local dwCenterID = GetRemoteChatSenderCenterID(UIHelper.UTF8ToGBK(szName))
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwTalkerID, dwCenterID, szGlobalID)
            end
        },

        {
            szName = "邀请入帮",
            bCloseOnClick = true,
            callback = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                TongData.InvitePlayerJoinTong(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                local bGuildDisable = (nLevel < 20 or g_pClientPlayer.dwTongID == 0)
                if g_pClientPlayer.IsPlayerInMyParty(dwTalkerID) then
                    local hTeam = GetClientTeam()
                    local tMemberInfo = hTeam.GetMemberInfo(dwTalkerID)
                    if not tMemberInfo.bIsOnLine then
                        bGuildDisable = true
                    end
                end
                return bGuildDisable
            end,
            bHideIfDisable = false
        },

        {
            szName = "加入名剑队", bNesting = true, tbSubMenus = {
                { szName = "2对2", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,
                callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "3对3", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "5对5", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "海选赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "名剑训练赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_PRACTICE, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
            }
        },

        {
            szName = "邀请加入团购",
            bCloseOnClick = true,
            bHideIfDisable = true,
            callback = function()
                GetHomelandMgr().BuyLandGrouponAddPlayerRequest(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not HomelandGroupBuyData.State or not HomelandGroupBuyData.State.bInGroupBuyState
                    or not HomelandGroupBuyData.IsGroupBuyOrganizer()
            end
        },

        {
            szName = "举报外挂",
            bCloseOnClick = true,
            callback = function()
                local targetPlayer = GetPlayer(dwTalkerID)
                local hScene = targetPlayer and targetPlayer.GetScene()
                local dwMapID, szMapName, fPosX, fPosY, fPosZ = nil, "", nil, nil, nil
                if hScene then
                    dwMapID = hScene.dwMapID
                    szMapName = Table_GetMapName(dwMapID)
                    fPosX, fPosY, fPosZ = targetPlayer and targetPlayer.GetAbsoluteCoordinate()
                end
                -- RemoteCallToServer("OnReportCheat", szName, "", dwMapID, fPosX, fPosY, fPosZ, targetPlayer.dwID)

                local tbSelectInfo =
                {
                    szName = UTF8ToGBK(szName),
                    szMapName = szMapName,
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.InformScript, tbSelectInfo, 1)
            end
        },

        {
            szName = "信誉举报",
            bCloseOnClick = true,
            callback = function()
                --战场举报/JJC举报
                local dwReportID = BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szName))
                if dwReportID then
                    RemoteCallToServer("On_XinYu_Jubao", dwReportID)
                end
            end,
            fnCheckShow = function()
                return BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szName))
            end
        },

        {
            szName = "反馈问题",
            bCloseOnClick = true,
            callback = function()
                local tbSelectInfo =
                {
                    nSelectIndex = 1,
                    tbParams = {}
                }
                local tbScript = UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
                TipsHelper.DeleteAllHoverTips()
            end
        },

        {
            szName = "屏蔽发言",
            bCloseOnClick = true,
            fnCheckShow = function() return not bRoomChannel and not FellowshipData.IsInBlackList(szGlobalID) end,
            callback = function()
                --FellowshipData.AddBlackList(UTF8ToGBK(szName), 0, 0)
                FellowshipData.AddRemoteBlack(szGlobalID, UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not UTF8ToGBK(szName)
            end
        },

        {
            szName = "取消屏蔽",
            bCloseOnClick = true,
            fnCheckShow = function() return FellowshipData.IsInBlackList(szGlobalID) end,
            callback = function()
                local nResultCode = FellowshipData.DelBlackList(szGlobalID)
                if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.SUCCESS then
                    Global.OnFellowshipMessage(nResultCode)
                end
            end
        },
    }

    local prefabID = PREFAB_ID.WidgetPlayerPop
    local tbPlayerCard = {
        dwMiniAvatarID = dwMiniAvatarID,
        nRoleType = nRoleType,
        dwForceID = dwForceID,
        nLevel = nLevel,
        szName = UTF8ToGBK(szName),
        nCamp = nCamp,
        dwCenterID = dwCenterID
    }

    --local tips, _ = TipsHelper.ShowNodeHoverTips(prefabID, widgetHead, dwTalkerID, tbAllMenuConfig, tbPlayerCard, nil, true)
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(prefabID, ChatHelper._getChatPanelTipsNode(widgetHead), TipsLayoutDir.RIGHT_CENTER, dwTalkerID or szGlobalID, tbAllMenuConfig, tbPlayerCard, nil, true)
    local w, h = UIHelper.GetContentSize(script._rootNode)
    tips:SetSize(w, h/2)
    --tips:SetOffset(0, 50)
    tips:Update()
end


function ChatTips.ShowSimplePlayerTips(node, szName)
    local tbAllMenuConfig = {
        {
            szName = "组队",
            bCloseOnClick = true,
            callback = function()
                TeamData.InviteJoinTeam(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not TeamData.CanMakeParty()
            end
        },

        {
            szName = "加为好友",
            bCloseOnClick = true,
            callback = function()
                FellowshipData.AddFellowship(UTF8ToGBK(szName))
            end
        },

        {
            szName = "拜师收徒", bNesting = true, tbSubMenus =
            {
                { szName = "收徒", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyApprentice", UIHelper.UTF8ToGBK(szName))
                end },
                { szName = "拜师", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyMentor", UIHelper.UTF8ToGBK(szName))
                end },
                { szName = "拜亲传师父", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyDirectMentor", UIHelper.UTF8ToGBK(szName))
                end },
            }
        },

        {
            szName = "邀请入帮",
            bCloseOnClick = true,
            callback = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                TongData.InvitePlayerJoinTong(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return g_pClientPlayer.dwTongID == 0
            end,
            bHideIfDisable = false
        },

        {
            szName = "加入名剑队", bNesting = true, tbSubMenus = {
                { szName = "2对2", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,
                callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "3对3", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "5对5", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "海选赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
                { szName = "名剑训练赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_PRACTICE, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szName), nCorpsID)
                end },
            }
        },

        {
            szName = "邀请加入团购",
            bCloseOnClick = true,
            bHideIfDisable = true,
            callback = function()
                GetHomelandMgr().BuyLandGrouponAddPlayerRequest(UTF8ToGBK(szName))
            end,
            fnDisable = function()
                return not HomelandGroupBuyData.State or not HomelandGroupBuyData.State.bInGroupBuyState
                    or not HomelandGroupBuyData.IsGroupBuyOrganizer()
            end
        },

        {
            szName = "举报外挂",
            bCloseOnClick = true,
            callback = function()
                local dwMapID = MapHelper.GetMapID()
                local tbSelectInfo =
                {
                    szName = UTF8ToGBK(szName),
                    szMapName = Table_GetMapName(dwMapID),
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.InformScript, tbSelectInfo, 1)
            end
        },

        {
            szName = "信誉举报",
            bCloseOnClick = true,
            callback = function()
                --战场举报/JJC举报
                local dwReportID = BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szName))
                if dwReportID then
                    RemoteCallToServer("On_XinYu_Jubao", dwReportID)
                end
            end,
            fnCheckShow = function()
                return BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szName))
            end
        },

        {
            szName = "反馈问题",
            bCloseOnClick = true,
            callback = function()
                local tbSelectInfo =
                {
                    nSelectIndex = 1,
                    tbParams = {}
                }
                local tbScript = UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
                TipsHelper.DeleteAllHoverTips()
            end
        },

        {
            szName = "屏蔽发言",
            bCloseOnClick = true,
            fnCheckShow = function()
                return true
            end,
            callback = function()
                FellowshipData.AddBlackList(UTF8ToGBK(szName), 0, 0)
            end,
            fnDisable = function()
                return not UTF8ToGBK(szName)
            end
        },
    }

    local prefabID = PREFAB_ID.WidgetPlayerPop
    local dwTalkerID = nil
    local tbPlayerCard = nil
    --local tips, script = TipsHelper.ShowNodeHoverTips(prefabID, node, dwTalkerID, tbAllMenuConfig, tbPlayerCard, nil, true)
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(prefabID, ChatHelper._getChatPanelTipsNode(node), TipsLayoutDir.RIGHT_CENTER, dwTalkerID, tbAllMenuConfig, tbPlayerCard, nil, true)
    script:ShowTop(false)
    script:ShowTopSimple(true, szName)
    local w, h = UIHelper.GetContentSize(script._rootNode)
    tips:SetSize(w, h/2)
    --tips:SetOffset(0, -150)
    tips:Update()
end