-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PlayerPopData
-- Date: 2024-04-13 10:33:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

PlayerPopData = PlayerPopData or {className = "PlayerPopData"}
local self = PlayerPopData
local PERSONAL_CARD_REPORT_CD = 60
-------------------------------- 消息定义 --------------------------------
PlayerPopData.Event = {}
PlayerPopData.Event.XXX = "PlayerPopData.Msg.XXX"

function PlayerPopData.Init()

    PlayerPopData.tMenuConfig = {
        AddFriend = { szName = "加为好友", callback = function()
            local targetPlayer = self.targetPlayer
            FellowshipData.AddFellowship(targetPlayer.szName)
        end,},

        Chat = { szName = "密聊", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local szName = UIHelper.GBKToUTF8(targetPlayer.szName)
                local dwTalkerID = targetPlayer.dwID
                local dwForceID = targetPlayer.dwForceID
                local dwMiniAvatarID = targetPlayer.dwMiniAvatarID
                local nRoleType = targetPlayer.nRoleType
                local nLevel = targetPlayer.nLevel
                local szGlobalID = self.szGlobalID--targetPlayer.szGlobalID
                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID}

                ChatHelper.WhisperTo(szName, tbData)
            end
        },

        Group = {
            szName = "组队", callback = function()
                local targetPlayer = self.targetPlayer
                TeamData.InviteJoinTeam(targetPlayer.szName)
            end, fnDisable = function()
                return not TeamData.CanMakeParty()
            end
        },

        Room = {
            szName = "房间", bCloseOnClick = true,
            callback = function()
                local szGlobalID = self.szGlobalID
                if RoomData.IsRoomOwner() then
                    if szGlobalID then
                        GetGlobalRoomClient().InviteJoinGlobalRoom(szGlobalID)
                    end
                else
                    if szGlobalID then
                        GetGlobalRoomClient().JoinGlobalRoom(szGlobalID)
                    end
                end
            end,
            fnDisable = function()
                return CheckPlayerIsRemote(nil, "")
            end
        },

        PeekMore = { szName = "查看更多", bNesting = true, tbSubMenus = {
            { szName = "查看名剑队",  bCloseOnClick = true, callback = function()
                if SystemOpen.IsSystemOpen(SystemOpenDef.PvPArena, true) then
                    SyncCorpsList(self.dwTargetPlayerId)
                    ArenaData.SetPlayerIDByPeek(self.dwTargetPlayerId)
                    UIMgr.Open(VIEW_ID.PanelPvPArena, self.dwTargetPlayerId)
                end
            end },
            { szName = "查看信誉", callback = function()
                RemoteCallToServer("On_XinYu_GetInfo", self.dwTargetPlayerId)
            end },
            { szName = "查看奇穴", bCloseOnClick = true, callback = function()
                PeekOtherPlayerTalentSetSlotSkillList(self.dwTargetPlayerId)
                PeekOtherPlayerSkillRecipe(self.dwTargetPlayerId)
                PeekOtherPlayerTalent(self.dwTargetPlayerId)
            end, fnDisable = function()
                return not GetPlayer(self.dwTargetPlayerId)
            end
            },
            { szName = "查看宠物秘鉴", bCloseOnClick = true, callback = function()
                UIMgr.Open(VIEW_ID.PanelPetMap, self.dwTargetPlayerId)
            end },
            { szName = "查看社区家园", bCloseOnClick = true, callback = function()
                if not CheckPlayerIsRemote(self.dwTargetPlayerId, g_tStrings.STR_REMOTE_NOT_TIP1) then
                    GetHomelandMgr().ApplyLandCard(self.dwTargetPlayerId)
                end
            end },
            { szName = "查看隐元秘鉴", bCloseOnClick = true, callback = function()
                ApplyAchievementData(self.dwTargetPlayerId)
                UIMgr.Open(VIEW_ID.PanelAchievementMian, self.dwTargetPlayerId)
            end },
            { szName = "查看阅读", callback = function()
                PeekOtherPlayerBook(self.dwTargetPlayerId)
            end },
            { szName = "查看百战信息", callback = function()
                local targetPlayer = self.targetPlayer
                local szGlobalID = self.targetPlayer and targetPlayer.GetGlobalID()
                local dwCenterID = self.tbRoleEntryInfo and self.tbRoleEntryInfo.dwCenterID
                MonsterBookData.CheckMonsterBookInfo(self.dwTargetPlayerId, dwCenterID, szGlobalID)
            end },
            -- { szName = "查看隐元秘鉴", callback = function()
            --     TipsHelper.ShowPlaceYellowTip("TODO（隐元秘鉴）: 查看他人隐元秘鉴 " .. UIHelper.GBKToUTF8(targetPlayer.szName))
            -- end },
            { szName = "查看侠客", bCloseOnClick = true, callback = function()
                UIMgr.Open(VIEW_ID.PanelPartner, self.dwTargetPlayerId)
            end, fnDisable = function()
                return not GetPlayer(self.dwTargetPlayerId)
            end
            },
        } },

        PeekEquip = { szName = "查看装备", bCloseOnClick = true, callback = function()
            local targetPlayer = self.targetPlayer
            local szGlobalID = self.targetPlayer and targetPlayer.GetGlobalID()
            local dwCenterID = self.tbRoleEntryInfo and self.tbRoleEntryInfo.dwCenterID
            UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.dwTargetPlayerId, dwCenterID, szGlobalID)
        end },

        Invite = { szName = "邀请", bNesting = true, tbSubMenus = {
            { szName = "邀请入帮", callback = function()
                    local targetPlayer = self.targetPlayer
                    if targetPlayer.dwTongID and targetPlayer.dwTongID ~= 0 then
                        -- 目标已有帮会
                        OutputMessage("MSG_ANNOUNCE_NORMAL", "对方已有帮会")
                    else
                        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                            return
                        end

                        TongData.InvitePlayerJoinTong(targetPlayer.szName)
                    end
                    --end
                end, fnDisable = function()
                    local targetPlayer = self.targetPlayer
                    local bGuildDisable = (targetPlayer.nLevel < 20 or GetClientPlayer().dwTongID == 0)
                    if GetClientPlayer().IsPlayerInMyParty(targetPlayer.dwID) then
                        local hTeam = GetClientTeam()
                        local tMemberInfo = hTeam.GetMemberInfo(targetPlayer.dwID)
                        if not tMemberInfo.bIsOnLine then
                            bGuildDisable = true
                        end
                    end
                    bGuildDisable = bGuildDisable and g_pClientPlayer.nLevel > 1
                    return bGuildDisable or CrossMgr.IsCrossing(nil,false)
                end, bHideIfDisable = false },
            { szName = "加入修罗队", callback = function()
                    local targetPlayer = self.targetPlayer
                    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE) then
                        return
                    end
                    GetAsuraClient().InvitePlayerJoinAsuraTeam(targetPlayer.szName)
                end, fnDisable = function()
                    local IsJoined = function()
                        local pPlayer = GetClientPlayer()
                        if pPlayer and pPlayer.dwAsuraTeamID and pPlayer.dwAsuraTeamID ~= 0 then
                            return true
                        else
                            return false
                        end
                    end

                    local IsMaster = function(dwMemberID)
                        if not dwMemberID then
                            dwMemberID = GetClientPlayer().dwID
                        end
                        return GetAsuraClient().dwMasterID == dwMemberID
                    end

                    return (not IsJoined() or not IsMaster() or CrossMgr.IsCrossing(nil,false))
                end },
            { szName = "加入名剑队", bNesting = true, tbSubMenus = {
                { szName = "2对2", fnDisable = function()
                    SyncCorpsList(GetClientPlayer().dwID)
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,
                callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local targetPlayer = self.targetPlayer
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, GetClientPlayer().dwID)
                    InvitationJoinCorps(targetPlayer.szName, nCorpsID)
                end },
                { szName = "3对3", fnDisable = function()
                    SyncCorpsList(GetClientPlayer().dwID)
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local targetPlayer = self.targetPlayer
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, GetClientPlayer().dwID)
                    InvitationJoinCorps(targetPlayer.szName, nCorpsID)
                end },
                { szName = "5对5", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local targetPlayer = self.targetPlayer
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, GetClientPlayer().dwID)
                    InvitationJoinCorps(targetPlayer.szName, nCorpsID)
                end },
                { szName = "海选赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, GetClientPlayer().dwID)
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local targetPlayer = self.targetPlayer
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, GetClientPlayer().dwID)
                    InvitationJoinCorps(targetPlayer.szName, nCorpsID)
                end },
                { szName = "名剑训练赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing(nil,false)
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local targetPlayer = self.targetPlayer
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_PRACTICE, GetClientPlayer().dwID)
                    InvitationJoinCorps(targetPlayer.szName, nCorpsID)
                end },
            } },
        } },

        Trading = { szName = "交易", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local dwBanTradeItemMask = GetClientPlayer().GetScene().dwBanTradeItemMask
                local player = GetClientPlayer()
                if player and player.nLevel < 108  then
                    TipsHelper.ShowNormalTip("侠士达到108级后方可邀请交易")
                    return
                elseif targetPlayer.nLevel < 108 then
                    TipsHelper.ShowNormalTip("对方等级低于108级，不能邀请交易")
                    return
                else
                    if
                    --Station_IsInUserAction() and
                    IsEnableTradeMap(dwBanTradeItemMask) then
                        TradingInviteToPlayer(targetPlayer.dwID)
                    end
                end
            end, fnDisable = function()
                local dwBanTradeItemMask = GetClientPlayer().GetScene().dwBanTradeItemMask
                local targetPlayer = self.targetPlayer
                return not targetPlayer or (
                    (targetPlayer.nMoveState and targetPlayer.nMoveState == MOVE_STATE.ON_DEATH) or
                                not GetClientPlayer().CanDialog(targetPlayer)
                                or not IsEnableTradeMap(dwBanTradeItemMask)
                )
            end,
            nCheckDisableInterval = 0.5
        },

        Mentor = { szName = "师徒", bNesting = true, tbSubMenus = {
            { szName = "收徒", callback = function()
                    local targetPlayer = self.targetPlayer
                    RemoteCallToServer("OnApplyApprentice", targetPlayer.szName)
                end, fnDisable = function ()
                    return CrossMgr.IsCrossing(nil,false)
                end
            },
            { szName = "拜师", callback = function()
                    local targetPlayer = self.targetPlayer
                    RemoteCallToServer("OnApplyMentor", targetPlayer.szName)
                end, fnDisable = function ()
                    return CrossMgr.IsCrossing(nil,false)
                end
            },
            { szName = "拜亲传师父", callback = function()
                    local targetPlayer = self.targetPlayer
                    RemoteCallToServer("OnApplyDirectMentor", targetPlayer.szName)
                end, fnDisable = function ()
                    return CrossMgr.IsCrossing(nil,false)
                end
            }, }
        },

        TransmissionPower = { szName = "传功", bCloseOnClick = true,
            callback = function()
                --拦截已移到FuncSlotCommands.TransmissionPower内
                FuncSlotMgr.ExecuteCommand("TransmissionPower")
            end,
            fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not GetPlayer(targetPlayer.dwID)
            end
        },

        Biaoshi = { szName = "镖师", bNesting = true, tbSubMenus = {
            { szName = "雇佣镖师", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                RemoteCallToServer("On_Identity_AskForBiaoshi", targetPlayer.dwID)
            end, fnDisable = function()
                local me  = GetClientPlayer()
                local targetPlayer = self.targetPlayer
                return not me or not targetPlayer.szName or IsRemotePlayer(UI_GetClientPlayerID()) or IsRemotePlayer(targetPlayer.dwID) or (targetPlayer.nLevel and targetPlayer.nLevel < me.nMaxLevel) or me.nLevel < 20
            end },
            { szName = "申请做镖师", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                RemoteCallToServer("On_Identity_BeBiaoShi", targetPlayer.dwID)
            end, fnDisable = function()
                local me  = GetClientPlayer()
                local targetPlayer = self.targetPlayer
                return not me or not targetPlayer.szName or IsRemotePlayer(UI_GetClientPlayerID()) or IsRemotePlayer(targetPlayer.dwID) or (targetPlayer.nLevel and targetPlayer.nLevel < me.nMaxLevel) or me.nLevel < 20
            end }, }
        },

        Follow = { szName = "跟随", bCloseOnClick = true, callback = function()
            -- TODO: Station_IsInUserAction 是KGUI中提供的lua接口，在KMUI中暂时没有，先注释掉
            --if Station_IsInUserAction() then
            FollowTarget(TARGET.PLAYER, self.dwTargetPlayerId)
            OnCheckAddAchievement(1002, "Fellow")
            --end
        end, fnDisable = function()
            local targetPlayer = self.targetPlayer
            return not PlayerData.GetPlayer(targetPlayer.dwID)
        end },

        Foe = { szName = "劲敌", bNesting = true, tbSubMenus = {
            { szName = "加为敌对", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local szFormat = FellowshipData.IsFriend(targetPlayer.szName) and g_tStrings.STR_ADD_FRIEND_TO_ENEMY_SURE or g_tStrings.STR_ADD_TO_ENEMY_SURE
                local szContent = string.format(szFormat, UIHelper.GBKToUTF8(targetPlayer.szName))
                UIHelper.ShowConfirm(szContent, function ()
                    FellowshipData.PrepareAddFoe(targetPlayer.szName)
                end, nil, false)
            end, fnDisable = function()
                return not FellowshipData.CanAddFoe() or CrossMgr.IsCrossing(nil,false)
            end },

            { szName = "加为宿敌", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local szFormat = FellowshipData.IsFriend(targetPlayer.szName) and g_tStrings.STR_ADD_FRIEND_TO_FEUD_SURE or g_tStrings.STR_ADD_TO_FEUD_SURE
                local szContent = string.format(szFormat, UIHelper.GBKToUTF8(targetPlayer.szName))
                UIHelper.ShowConfirm(szContent, function ()
                    FellowshipData.AddFeudComfirm(FellowshipData.PrepareAddFeud, self.szGlobalID)
                end, nil, false)
            end, fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not targetPlayer.szName or not targetPlayer.dwID or GetClientPlayer().bFightState or CrossMgr.IsCrossing(nil,false)
            end },

            { szName = "发布决斗", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local tar = GetPlayer(targetPlayer.dwID)
                if tar then
                    PlayerPopData.OpenWantsPublish(UIHelper.GBKToUTF8(targetPlayer.szName), tar.nLevel)
                end
            end, fnDisable = function()
                local me = GetClientPlayer()
                local targetPlayer = self.targetPlayer
                local nTargetLevel = targetPlayer.nLevel
                local szName = targetPlayer.szName or szName
                return not me or not szName
                        or IsRemotePlayer(GetClientPlayer().dwID) or IsRemotePlayer(targetPlayer.dwID)
                        or (nTargetLevel and nTargetLevel < me.nMaxLevel) or me.nLevel < 20
            end },
        } },

        Duel = { szName = "切磋", callback = function()
            --if not Station_IsInUserAction() then
            --    return
            --end
            local targetPlayer = self.targetPlayer
            if GetClientPlayer().nLevel < 108 then
                TipsHelper.ShowNormalTip("侠士达到108级后方可与对方切磋")
                return
            elseif targetPlayer.nLevel < 108 then
                TipsHelper.ShowNormalTip("对方等级低于108级，不能切磋")
                return
            else
                GetClientPlayer().ApplyDuel(targetPlayer.dwID)
            end
            end, fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not (GetPlayer(targetPlayer.dwID) and GetClientPlayer().CanApplyDuel(targetPlayer.dwID))
            end
        },

        BlackList = { szName = "屏蔽发言", bCloseOnClick = true,
            fnCheckShow = function()
                local targetPlayer = self.targetPlayer
                return not FellowshipData.IsInBlackList(self.szGlobalID) end,
            callback = function()
                local targetPlayer = self.targetPlayer
                FellowshipData.AddRemoteBlack(self.szGlobalID, targetPlayer.szName)
            end,
            fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not targetPlayer.szName
            end
        },

        CancelBlackList = { szName = "取消屏蔽", bCloseOnClick = true,
            fnCheckShow = function()
                local targetPlayer = self.targetPlayer
                return FellowshipData.IsInBlackList(self.szGlobalID)
            end,
            callback = function()
                local targetPlayer = self.targetPlayer
                local nResultCode = FellowshipData.DelBlackList(self.szGlobalID)
                if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.SUCCESS then
                    Global.OnFellowshipMessage(nResultCode)
                end
            end
        },

        RideTogether = { szName = "双人同骑", bCloseOnClick = true,
            callback = function()
                FuncSlotMgr.ExecuteCommand("RideTogether")
            end,
            fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not GetPlayer(targetPlayer.dwID)
            end
        },

        Feedback = { szName = "问题反馈", bNesting = true, tbSubMenus = {
            { szName = "举报外挂", bCloseOnClick = true,
            callback = function()
                local targetPlayer = self.targetPlayer
                local szName = targetPlayer.szName

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
                    szName = szName,
                    szMapName = szMapName,
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.InformScript, tbSelectInfo, 1)
            end},
            { szName = "举报名片", bCloseOnClick = true, callback = function()
                local nTime = GetGSCurrentTime()
                if self.nReportTime and nTime - self.nReportTime < PERSONAL_CARD_REPORT_CD then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_PERSONALCARD_REPORT_ERROR)
                    OutputMessage("MSG_SYS", g_tStrings.STR_PERSONALCARD_REPORT_ERROR)
                else
                    self.nReportTime = nTime
                    local tNowTime = TimeToDate(nTime)
                    local szTime = FormatString(g_tStrings.STR_TIME_2, tNowTime.year, tNowTime.month, tNowTime.day, tNowTime.hour, tNowTime.minute, tNowTime.second)
                    local szContent = "(" .. g_tStrings.tReportType[9] .. ")" .. szTime

                    local szPlatform = "vkWin"
                    if Platform.IsAndroid() then
                        szPlatform = "Android"
                    elseif Platform.IsIos() then
                        szPlatform = "Ios"
                    end

                    RemoteCallToServer("OnReportTrick", self.targetPlayer.szName, szContent, "", self.targetPlayer.GetGlobalID(), szPlatform)
                    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_PERSONALCARD_REPORT_SUCCESS)
                    OutputMessage("MSG_SYS", g_tStrings.STR_PERSONALCARD_REPORT_SUCCESS)
                end
            end},
            { szName = "信誉举报", bCloseOnClick = true,
            callback = function()
                local targetPlayer = self.targetPlayer
                local szName = targetPlayer.szName

                --战场举报/JJC举报
                if BattleFieldData.IsCanReportPlayer(szName) or ArenaData.IsCanReportPlayer(szName) then
                    RemoteCallToServer("On_XinYu_Jubao", targetPlayer.dwID)
                end
            end,
            fnCheckShow = function()
                local targetPlayer = self.targetPlayer
                local szName = targetPlayer.szName
                return BattleFieldData.IsCanReportPlayer(szName) or ArenaData.IsCanReportPlayer(szName)
            end},
            { szName = "反馈bug", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local player = GetPlayer(targetPlayer.dwID)
                if not player then
                    return false
                end
                local tbSelectInfo =
                {
                    nSelectIndex = 7,
                    tbParams =
                    {
                        player.szName,
                        g_tStrings.tRoleTypeFormalName[player.nRoleType]
                    }
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo, 1)
            end},
            },
        },

        DoubleSprint = { szName = "双人轻功", bCloseOnClick = true,
            callback = function()
                if GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec == GameSettingType.SprintMode.Common.szDec then
                    TipsHelper.ShowNormalTip("通用轻功下暂不支持双人轻功，可在设置中切回简化或经典轻功再使用")
                    return
                end
                Event.Dispatch(EventType.OnAutoDoubleSprint)
            end,
            fnDisable = function()
                local targetPlayer = self.targetPlayer
                return not GetPlayer(targetPlayer.dwID)
            end
        },

        TransSkill = { szName = "传授", bCloseOnClick = true,
            fnCheckShow = function() return GetClientPlayer().GetScene().dwMapID == MonsterBookData.PLAY_MAP_ID end,
            callback = function()
                local targetPlayer = self.targetPlayer
                UIMgr.Open(VIEW_ID.PanelBZTransSkill, targetPlayer)
            end
        },

        TeamMenu = {},

        MarkMenus = {},

        ObMenu = {},
    }
end

function PlayerPopData.UnInit()

end

function PlayerPopData.OnLogin()

end

function PlayerPopData.OnFirstLoadEnd()

end

function PlayerPopData.SetTarget(targetPlayer, szGlobalID, dwTargetPlayerId, tbRoleEntryInfo)
    self.targetPlayer = targetPlayer
    self.szGlobalID = szGlobalID
    self.dwTargetPlayerId = dwTargetPlayerId
    self.tbRoleEntryInfo = tbRoleEntryInfo
end

function PlayerPopData.GetTargetMenuConfig()
    local tMenuConfig

    -- OB模式下直接使用ObMenu
    if not table_is_empty(PlayerPopData.tMenuConfig.ObMenu) and
    OBDungeonData.IsPlayerInOBDungeon() then
        return PlayerPopData.tMenuConfig.ObMenu
    end

    --组队标记权限都无
    if table_is_empty(PlayerPopData.tMenuConfig.TeamMenu) and
    table_is_empty(PlayerPopData.tMenuConfig.MarkMenus) then
        tMenuConfig = {
            PlayerPopData.tMenuConfig.Chat,      PlayerPopData.tMenuConfig.Group,
            PlayerPopData.tMenuConfig.Room,      PlayerPopData.tMenuConfig.AddFriend,
            PlayerPopData.tMenuConfig.PeekMore,  PlayerPopData.tMenuConfig.PeekEquip,
            PlayerPopData.tMenuConfig.Invite,    PlayerPopData.tMenuConfig.Trading,
            PlayerPopData.tMenuConfig.Mentor,    PlayerPopData.tMenuConfig.TransmissionPower,
            PlayerPopData.tMenuConfig.Biaoshi,   PlayerPopData.tMenuConfig.Follow,
            PlayerPopData.tMenuConfig.Foe,       PlayerPopData.tMenuConfig.Duel,
            PlayerPopData.tMenuConfig.Feedback,  PlayerPopData.tMenuConfig.RideTogether,
            PlayerPopData.tMenuConfig.BlackList, PlayerPopData.tMenuConfig.CancelBlackList,  PlayerPopData.tMenuConfig.DoubleSprint,
            PlayerPopData.tMenuConfig.TransSkill,
        }
    --有标记权限没有队伍权限
    elseif table_is_empty(PlayerPopData.tMenuConfig.TeamMenu) and
    not table_is_empty(PlayerPopData.tMenuConfig.MarkMenus) then
        tMenuConfig = {
            PlayerPopData.tMenuConfig.Chat,       PlayerPopData.tMenuConfig.Group,
            PlayerPopData.tMenuConfig.MarkMenus,  PlayerPopData.tMenuConfig.AddFriend,
            PlayerPopData.tMenuConfig.Room,       PlayerPopData.tMenuConfig.PeekEquip,
            PlayerPopData.tMenuConfig.PeekMore,   PlayerPopData.tMenuConfig.Trading,
            PlayerPopData.tMenuConfig.Invite,     PlayerPopData.tMenuConfig.TransmissionPower,
            PlayerPopData.tMenuConfig.Mentor,     PlayerPopData.tMenuConfig.Follow,
            PlayerPopData.tMenuConfig.Biaoshi,    PlayerPopData.tMenuConfig.Duel,
            PlayerPopData.tMenuConfig.Foe,        PlayerPopData.tMenuConfig.RideTogether,
            PlayerPopData.tMenuConfig.Feedback,   PlayerPopData.tMenuConfig.DoubleSprint,
            PlayerPopData.tMenuConfig.BlackList,  PlayerPopData.tMenuConfig.CancelBlackList,   PlayerPopData.tMenuConfig.TransSkill,
        }
    --有队伍权限没有标记权限
    elseif not table_is_empty(PlayerPopData.tMenuConfig.TeamMenu) and
    table_is_empty(PlayerPopData.tMenuConfig.MarkMenus) then
        tMenuConfig = {
            PlayerPopData.tMenuConfig.TeamMenu,  PlayerPopData.tMenuConfig.Chat,
            PlayerPopData.tMenuConfig.Room,      PlayerPopData.tMenuConfig.AddFriend,
            PlayerPopData.tMenuConfig.PeekMore,  PlayerPopData.tMenuConfig.PeekEquip,
            PlayerPopData.tMenuConfig.Invite,    PlayerPopData.tMenuConfig.Trading,
            PlayerPopData.tMenuConfig.Mentor,    PlayerPopData.tMenuConfig.TransmissionPower,
            PlayerPopData.tMenuConfig.Biaoshi,   PlayerPopData.tMenuConfig.Follow,
            PlayerPopData.tMenuConfig.Foe,       PlayerPopData.tMenuConfig.Duel,
            PlayerPopData.tMenuConfig.Feedback,  PlayerPopData.tMenuConfig.RideTogether,
            PlayerPopData.tMenuConfig.BlackList, PlayerPopData.tMenuConfig.CancelBlackList,  PlayerPopData.tMenuConfig.DoubleSprint,
            PlayerPopData.tMenuConfig.TransSkill,
        }
    --两个权限都有
    else
        tMenuConfig = {
            PlayerPopData.tMenuConfig.TeamMenu,   PlayerPopData.tMenuConfig.Chat,
            PlayerPopData.tMenuConfig.MarkMenus,  PlayerPopData.tMenuConfig.AddFriend,
            PlayerPopData.tMenuConfig.Room,       PlayerPopData.tMenuConfig.PeekEquip,
            PlayerPopData.tMenuConfig.PeekMore,   PlayerPopData.tMenuConfig.Trading,
            PlayerPopData.tMenuConfig.Invite,     PlayerPopData.tMenuConfig.TransmissionPower,
            PlayerPopData.tMenuConfig.Mentor,     PlayerPopData.tMenuConfig.Follow,
            PlayerPopData.tMenuConfig.Biaoshi,    PlayerPopData.tMenuConfig.Duel,
            PlayerPopData.tMenuConfig.Foe,        PlayerPopData.tMenuConfig.RideTogether,
            PlayerPopData.tMenuConfig.Feedback,   PlayerPopData.tMenuConfig.DoubleSprint,
            PlayerPopData.tMenuConfig.BlackList,  PlayerPopData.tMenuConfig.CancelBlackList,   PlayerPopData.tMenuConfig.TransSkill,
        }
    end

    return tMenuConfig
end

function PlayerPopData.SetTeamAndMaskMenu()
    local targetPlayer = self.targetPlayer
    PlayerPopData.tMenuConfig.TeamMenu = {}
    PlayerPopData.tMenuConfig.MarkMenus = {}

    local tbTeamMenus = {}
    local me = GetClientPlayer()
    if me.IsInParty() and me.IsPlayerInMyParty(targetPlayer.dwID) then
        TeamData.InsertTeammateMenus(tbTeamMenus, targetPlayer.dwID)
    end

    if not table_is_empty(tbTeamMenus) then
        PlayerPopData.tMenuConfig.TeamMenu = {
            szName = "队伍权限", bNesting = true, tbSubMenus = tbTeamMenus
        }
    end

    -- 标记菜单
    local tbMarkMenus = {}
    TeamData.InsertTeamMarkMenus(tbMarkMenus, targetPlayer.dwID)
    if not table_is_empty(tbMarkMenus) then
        PlayerPopData.tMenuConfig.MarkMenus = tbMarkMenus[1]
    end

    -- OB菜单
    PlayerPopData.tMenuConfig.ObMenu = {}
    if OBDungeonData.IsPlayerInOBDungeon() then
        PlayerPopData.tMenuConfig.ObMenu = {
            { szName = "查看装备", bCloseOnClick = true, callback = function()
                local targetPlayer = self.targetPlayer
                local szGlobalID = self.targetPlayer and targetPlayer.GetGlobalID()
                local dwCenterID = self.tbRoleEntryInfo and self.tbRoleEntryInfo.dwCenterID
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.dwTargetPlayerId, dwCenterID, szGlobalID)
            end },
            { szName = "查看奇穴", bCloseOnClick = true, callback = function()
                PeekOtherPlayerTalentSetSlotSkillList(self.dwTargetPlayerId)
                PeekOtherPlayerSkillRecipe(self.dwTargetPlayerId)
                PeekOtherPlayerTalent(self.dwTargetPlayerId)
            end },
        }
    end
end


local function LimitMapType()
	local dwCurrentMapID = GetClientPlayer().GetMapID()
	local _, nMapType = GetMapParams(dwCurrentMapID)
	if nMapType == MAP_TYPE.BIRTH_MAP or nMapType == MAP_TYPE.NORMAL_MAP then
		return true
	end
	return false
end

function PlayerPopData.OpenWantsPublish(szName, nLevel)
    local hPlayer = GetClientPlayer()
    if hPlayer.nLevel < 110 then
        TipsHelper.ShowNormalTip("侠士达到110级后方可发布决斗")
        return
    elseif nLevel < 110 then
        TipsHelper.ShowNormalTip("对方等级低于110级，不能发布决斗")
        return
    elseif not LimitMapType() then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_LIMIT_MAP_TYPE)
		return
	elseif CheckPlayerIsRemote(nil, "") then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_SELF_REMOTE_LIMIT)
		return
	elseif hPlayer.bFreeLimitFlag then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_FREE_LIMIT)
		return
	elseif hPlayer.nLevel < 20 then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_LEVEL_LIMIT)
		return
	end

    UIMgr.Open(VIEW_ID.PanelReleaseRewardPop, szName)
end