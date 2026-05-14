-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TeamData
-- Date: 2022-11-21 17:47:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

TeamData = TeamData or {className = "TeamData"}
local self = TeamData

-- local RAID_LEAVE_STATE_TIME = 20 * 1000

local RAID_LEAVE_STATE_TIME = 10 * 60 * 1000

RAID_READY_CONFIRM_STATE = {
    Init = 0,
    Ok = 1,
    NotYet = 2,
}

TeamData.WORLD_MARK_SKILL = {
	[1] = 4871,
	[2] = 4872,
	[3] = 4873,
	[4] = 4874,
	[5] = 4875,
	[6] = 9313,
	[7] = 9314,
	[8] = 9315,
	[9] = 9316,
	[10] = 9317,
}

TeamData.WORLD_MARK_CLEAR_SKILL = 4906
TeamData.bWorldMarkOpen = false
TeamData.tbWorldMarkList = {}
TeamData.bDisableWorldMarkClearConfirm = false

TeamData.bRaidLeaveState = false

TeamData.bStartReadyConfirm = false
TeamData.tMemberReadyConfirm = {}

TeamData.TargetMarkIcon = {
	[1] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_01",
	[2] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_02",
	[3] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_03",
	[4] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_04",
	[5] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_05",
	[6] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_06",
	[7] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_07",
	[8] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_08",
	[9] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_09",
	[10] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_sign_10",
}

-------------------------------- 消息定义 --------------------------------
TeamData.Event = {}
TeamData.Event.XXX = "TeamData.Msg.XXX"



function TeamData.Init()
	Timer.DelTimer(self, self.nCheckTimerID)
	self.nCycleTimerID = Timer.AddCycle(self, 1, function()
		self.OnCycleUpdate()
	end)
end

function TeamData.UnInit()
	Timer.DelAllTimer(self)
end

function TeamData.OnLogin()

end

function TeamData.OnFirstLoadEnd()

end

function TeamData.IsInParty()
	if not g_pClientPlayer then
		return false
	end
	return g_pClientPlayer.IsInParty()
end

function TeamData.IsTeamLeader()
	if not g_pClientPlayer then
		return false
	end
    return g_pClientPlayer.IsPartyLeader()
end

function TeamData.IsSystemTeam()
	local bResult = false
	local hTeam = GetClientTeam()
	if hTeam and hTeam.bSystem then
		bResult = true
	end
	return bResult
end

function TeamData.IsPlayerInTeam(dwID)
	local bResult = false
	local hTeamClient = GetClientTeam()
	if hTeamClient then
		if dwID == nil and g_pClientPlayer then
			dwID = g_pClientPlayer.dwID
		end
		if dwID then
			bResult = hTeamClient.IsPlayerInTeam(dwID)
		end
	end
	return bResult
end

function TeamData.GetTeamID()
	local hTeamClient = GetClientTeam()
	return hTeamClient and hTeamClient.dwTeamID or 0
end

-- 获取队伍的实时语音房间ID
function TeamData.GetGVoiceRoomID()
	local szGVoiceRoomID = ""
	local hTeamClient = GetClientTeam()
    if hTeamClient then
        szGVoiceRoomID = hTeamClient.GetGVoiceRoomID()
    end
    return szGVoiceRoomID
end

-- 获取队伍成员的实时语音的OpenID
function TeamData.GetMemberGVoiceID(dwTeamMateMemberID)
	local teamMemberInfo = TeamData.GetMemberInfo(dwTeamMateMemberID)
	local szGVoiceID = teamMemberInfo and teamMemberInfo.szGVoiceID or ""
	return szGVoiceID
end

function TeamData.IsInMyGroup(dwMemberID)
    local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.IsInParty() then
		return
	end

	if not hPlayer.IsPlayerInMyParty(dwMemberID) then
		return
	end

	local hTeam = GetClientTeam()
	local nMyGroup = hTeam.GetMemberGroupIndex(hPlayer.dwID)
	local nMemberGroup = hTeam.GetMemberGroupIndex(dwMemberID)
	if hTeam.IsPlayerInTeam(dwMemberID) and nMyGroup == nMemberGroup then
		return true
	end
end

function TeamData.IsInRaid(hTeam)
	hTeam = hTeam or GetClientTeam()
	return hTeam.nGroupNum > 1
end

function TeamData.GetGroupInfo(nGroupID, hTeam)
    hTeam = hTeam or GetClientTeam()
	if hTeam.nGroupNum > 1 then
		return hTeam.GetGroupInfo(nGroupID)
	else
		local hPlayer = GetClientPlayer()
		local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
		return hTeam.GetGroupInfo(nGroupID)
	end
end

function TeamData.GetTeammateName(dwMemberID)
	local hTeam = GetClientTeam()
	local tbMemberInfo = self.GetMemberInfo(dwMemberID, hTeam)
	if tbMemberInfo then
		return tbMemberInfo.szName
	end
end

function TeamData.GetMemberInfo(dwMemberID, hTeam)
    hTeam = hTeam or GetClientTeam()
	return hTeam.GetMemberInfo(dwMemberID)
end

function TeamData.GetMemberInfoEvenNotInTeamForSelf(dwMemberID, hTeam)
    local info = TeamData.GetMemberInfo(dwMemberID, hTeam)

    if info == nil and g_pClientPlayer and dwMemberID == UI_GetClientPlayerID() and
            not TeamData.IsInParty() and not table.is_empty(PartnerData.GetCurrentTeamPartnerNpcList()) then
        -- 单人的时候，也要在队伍列表里显示下侠客和自己的信息，因此这里特别处理下
        local player  = g_pClientPlayer
        local hScene  = player.GetScene()
        local x, y, z = player.GetAbsoluteCoordinate()

        info          = {
            dwMemberID = player.dwID,
            szName = player.szName,
            nLevel = player.nLevel,
            bIsOnLine = true,
            bDeathFlag = player.nMoveState == MOVE_STATE.ON_DEATH,
            nCamp = player.nCamp,
            dwForceID = player.dwForceID,
            nMaxLife = player.nMaxLife,
            nCurrentLife = player.nCurrentLife,
            nMaxMana = player.nMaxMana,
            nCurrentMana = player.nCurrentMana,
            dwMapID = player.GetMapID(),
            nMapCopyIndex = hScene.nCopyIndex,
            nPosX = x,
            nPosY = y,
            nRoleType = player.nRoleType,
            nFormationCoefficient = 0,
            dwMiniAvatarID = player.dwMiniAvatarID,
            dwActualMountKungfuID = player.GetActualKungfuMountID(),
            dwMountKungfuID = player.GetKungfuMountID(),
            nVipType = player.nVipType,
            bIdentityVisiable = true,
            dwIdentityVisiable = true,
            nClientVersionType = player.nClientVersionType,
            szGVoiceID = "",
            szGlobalID = "",
        }
    end

    return info
end

function TeamData.Generator(fnGenerator)
	local player = g_pClientPlayer
	if not fnGenerator then
		return
	end
	if not player or not player.IsInParty() then
		return
	end
	local hTeam = GetClientTeam()
	local nGroupNum = hTeam.nGroupNum
	for i = 0, nGroupNum - 1 do
		local tGroupInfo = hTeam.GetGroupInfo(i)
		if tGroupInfo and tGroupInfo.MemberList then
			for _, dwID in pairs(tGroupInfo.MemberList) do
				local tMemberInfo = hTeam.GetMemberInfo(dwID)
				fnGenerator(dwID, tMemberInfo)
			end
		end
	end
end

function TeamData.CanMakeParty()
	local bCanMakeParty = true
	local player = GetClientPlayer()

	if not player then
		return false
	end

	if not player.CanTeamWork() then
		bCanMakeParty = false
	end

	if player.IsInParty() then
		if not player.IsPartyLeader() then
			bCanMakeParty = false
		elseif player.IsPartyFull() then
			bCanMakeParty = false
		end
	end

	return bCanMakeParty
end

function TeamData.InsertInviteTeamMenu(tbMenus, szTargetName)
	table.insert(tbMenus, {
		szName = "组队", callback = function()
			-- TODO: Station_IsInUserAction 是KGUI中提供的lua接口，在KMUI中暂时没有，先注释掉
			--if Station_IsInUserAction() then
			TeamData.InviteJoinTeam(szTargetName)
			--end
		end, fnDisable = function()
			return not TeamData.CanMakeParty()
		end
	})
end

function TeamData.InsertTeammateMenus(tbMenus, dwMemberID, bIncludeNormal, bIncludeMark)
    local hPlayer = GetClientPlayer()
	if not hPlayer.IsInParty() or not hPlayer.IsPlayerInMyParty(dwMemberID) then
		return
	end

    local hTeam = GetClientTeam()
    local tbMemberInfo = hTeam.GetMemberInfo(dwMemberID)
    local bOffline = not tbMemberInfo.bIsOnLine
	local nMemberGroupID = hTeam.GetMemberGroupIndex(dwMemberID)
	local nMyGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
	local tbMyGroupInfo = hTeam.GetGroupInfo(nMyGroupID)

	if bIncludeMark then
		self.InsertTeamMarkMenus(tbMenus, dwMemberID)
	end

    if hPlayer.IsPartyLeader() then
		table.insert(tbMenus, {
            szName = g_tStrings.STR_TEAMMATE_CHANGE_PARTY_LEADER,
            bCloseOnClick = true,
            callback = function()
                GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwMemberID)
            end,
            fnDisable = function()
                return bOffline
            end,
		})

        if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == dwMemberID then
            table.insert(tbMenus, {
                szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_DISTRIBUTE_RIGHT,
                bCloseOnClick = true,
                callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, GetClientPlayer().dwID)
                end,
                fnDisable = function()
                    return bOffline
                end
            })
        else
            table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_DISTRIBUTE_RIGHT,
                bCloseOnClick = true,
                callback = function()
                   GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwMemberID)
                end,
                fnDisable = function()
                    return bOffline
                end
			})
        end

		if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == dwMemberID then
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_MARK_RIGHT,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, GetClientPlayer().dwID)
                end,
                fnDisable = function()
                    return bOffline
                end
			})
		else
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_MARK_RIGHT,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMemberID)
                end,
                fnDisable = function()
                    return bOffline
                end
			})
		end

        if tbMyGroupInfo.dwFormationLeader == dwMemberID then
            table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_PARTY_LEADER,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetTeamFormationLeader(GetClientPlayer().dwID, nMyGroupID)
                end,
                fnDisable = function()
                    return bOffline
                end
			})
		else
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_PARTY_LEADER,
                bCloseOnClick = true,
                callback = function()
                    GetClientTeam().SetTeamFormationLeader(dwMemberID, nMemberGroupID)
                end,
				fnDisable = function()
					return bOffline
                    -- return bOffline or IsMobileClientVersionType(tbMemberInfo.nClientVersionType)
                end
			})
		end

        table.insert(tbMenus, {
			szName = g_tStrings.STR_TEAMMATE_KICKOUT_MENBER,
            bCloseOnClick = true,
			callback = function()
                local szContent = FormatString(g_tStrings.STR_MSG_KICKOUT_PARTY_MEMBER_CONFIRM, UIHelper.GBKToUTF8(tbMemberInfo.szName))
                local fnConfirm = function()
                    GetClientTeam().TeamKickoutMember(tbMemberInfo.szName)
                end
                UIHelper.ShowConfirm(szContent, fnConfirm, nil, false)
			end,
            fnDisable = function()
                return hTeam.bSystem
            end
		})
    else
        if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID then
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_DISTRIBUTE_RIGHT,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwMemberID)
                end
			})
		end

		if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == hPlayer.dwID then
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_MARK_RIGHT,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMemberID)
                end
			})
		end

		if tbMyGroupInfo.dwFormationLeader == hPlayer.dwID and nMyGroupID == nMemberGroupID then
			table.insert(tbMenus, {
				szName = g_tStrings.STR_LEADER_OPTION_CHANGE_PARTY_LEADER,
                bCloseOnClick = true,
				callback = function()
                    GetClientTeam().SetTeamFormationLeader(dwMemberID, nMemberGroupID)
                end,
				-- fnDisable = function()
				-- 	return IsMobileClientVersionType(tbMemberInfo.nClientVersionType)
				-- end
            })
		end
    end

	self.InsertRemoveFromMultiSteedMenu(tbMenus, dwMemberID)

	if bIncludeNormal then
		self.InsertNormalMenus(tbMenus, dwMemberID)
	end
end

function TeamData.InsertTeamPlayerMenus(tbMenus)
    local player = GetClientPlayer()
    local hTeam = GetClientTeam()

	local dwDistribute = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	local dwMark = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)

	if dwMark == player.dwID then
		self.InsertTeamMarkMenus(tbMenus, player.dwID)
	end

    if player.IsPartyLeader() then
        if dwDistribute ~= player.dwID then
            table.insert(tbMenus, {
                szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_DISTRIBUTE_RIGHT,
                bCloseOnClick = true,
                callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, player.dwID)
                end
            })
        end

        if dwMark ~= player.dwID then
            table.insert(tbMenus, {
                szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_MARK_RIGHT,
                bCloseOnClick = true,
                callback = function()
                    GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, player.dwID)
                end
            })
        end

        local nGroupID = hTeam.GetMemberGroupIndex(player.dwID)
        local tbGroupInfo = hTeam.GetGroupInfo(nGroupID)
        if tbGroupInfo.dwFormationLeader ~= player.dwID then
            table.insert(tbMenus, {
                szName = g_tStrings.STR_LEADER_OPTION_TAKEBACK_PARTY_LEADER,
                bCloseOnClick = true,
                callback = function()
                    GetClientTeam().SetTeamFormationLeader(player.dwID, nGroupID)
                end
            })
        end
    end

    table.insert(tbMenus, {
        szName = g_tStrings.STR_LEAVE_PARTY,
        bCloseOnClick = true,
        callback = function()
            TeamData.RequestLeaveTeam()
        end,
        fnDisable = function()
            return hTeam.bSystem
        end
    })
end

function TeamData.InsertTeamMarkMenus(tbMenus, dwMemberID)
	if BattleFieldData.IsInXunBaoBattleFieldMap() then
		return
	end

	local player = GetClientPlayer()
    local hTeam = GetClientTeam()

	local dwMark = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
	if dwMark == player.dwID then
		table.insert(tbMenus, {
			szName = g_tStrings.STR_MARK_TARGET,
			bTeamMark = true,
			dwMemberID = dwMemberID,
		})
	end
end

function TeamData.InsertNormalMenus(tbMenus, dwMemberID)
    local hPlayer = GetClientPlayer()
    local hTeam = GetClientTeam()
    local tbMemberInfo = hTeam.GetMemberInfo(dwMemberID)
    local bOffline = not tbMemberInfo.bIsOnLine

    if dwMemberID ~= hPlayer.dwID then
		RoomData.InsertRoomInviteMenu(tbMenus, tbMemberInfo.szGlobalID)

		table.insert(tbMenus, {
			szName = "查看装备",
			bCloseOnClick = true,
			callback = function()
				UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwMemberID)
			end,
			fnDisable = function()
				return bOffline
			end
		})

        table.insert(tbMenus, {
			szName = "加为好友",
			bCloseOnClick = true,
			callback = function()
				FellowshipData.AddFellowship(tbMemberInfo.szName)
			end
        })

        table.insert(tbMenus, {
            szName = "邀请入帮",
            bCloseOnClick = true,
            fnDisable = function()
                local bGuildDisable = tbMemberInfo.nLevel < 20 or GetClientPlayer().dwTongID == 0
                return bOffline or bGuildDisable
            end,
            callback = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                TongData.InvitePlayerJoinTong(tbMemberInfo.szName)
            end,
			bHideIfDisable = false,
        })

        table.insert(tbMenus, {
            szName = "密聊",
            bCloseOnClick = true,
            callback = function()
                local szName = UIHelper.GBKToUTF8(tbMemberInfo.szName)
                local dwTalkerID = dwMemberID
                local dwForceID = tbMemberInfo.dwForceID
                local dwMiniAvatarID = tbMemberInfo.dwMiniAvatarID
                local nRoleType = tbMemberInfo.nRoleType
                local nLevel = tbMemberInfo.nLevel
				local szGlobalID = tbMemberInfo.szGlobalID
                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID}
                ChatHelper.WhisperTo(szName, tbData)
            end
        })

        table.insert(tbMenus, {
            szName = "屏蔽发言",
            bCloseOnClick = true,
            callback = function()
				FellowshipData.AddBlackList(tbMemberInfo.szName)
                OnCheckAddAchievement(981, "BlackList_First_Add")
            end
        })

		table.insert(tbMenus, {
			szName = "跟随",
			bCloseOnClick = true,
			callback = function()
                FollowTarget(TARGET.PLAYER, dwMemberID)
				OnCheckAddAchievement(1002, "Fellow")
			end,
			fnDisable = function()
				return not PlayerData.GetPlayer(dwMemberID)
			end
		})

		table.insert(tbMenus, {
            szName = "接收语音",
            bCloseOnClick = true,
			fnDisable = function()
                return not GVoiceMgr.IsMemberForbid(dwMemberID)
            end,
            callback = function()
                GVoiceMgr.ForbidMemberVoice(dwMemberID, false)
            end,
			bHideIfDisable = true,
        })

		table.insert(tbMenus, {
            szName = "拒听语音",
            bCloseOnClick = true,
			fnDisable = function()
                return GVoiceMgr.IsMemberForbid(dwMemberID)
            end,
            callback = function()
                GVoiceMgr.ForbidMemberVoice(dwMemberID, true)
            end,
			bHideIfDisable = true,
        })

		if BattleFieldData.IsInTreasureBattleFieldMap() or BattleFieldData.IsInMobaBattleFieldMap() then
			table.insert(tbMenus, {
				szName = "信誉举报",
				bCloseOnClick = true,
				callback = function()
					RemoteCallToServer("On_XinYu_Jubao", dwMemberID)
				end,
			})
		end
    end
end

local function GetRideState(hPlayer)
	if not hPlayer then
		return
	end

	local tDriver = {}
	Buffer_GetByID(hPlayer, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_DRIVER, 1, tDriver)
	if tDriver.dwID then
		return { bDriver = true, dwDriverID = hPlayer.dwID }
	end

	local tPassenger = {}
	Buffer_GetByID(hPlayer, SPECIAL_BUFF_ID_LIST.GROUP_RIDE_PASSENGER, 1, tPassenger)
	if tPassenger.dwID then
		return { bPassenger = true, dwDriverID = tPassenger.dwSkillSrcID }
	end
end

local function CanRemoveFromMultiSteed(dwTargetID)
	local hPlayer = GetClientPlayer()
	if not hPlayer or not dwTargetID or dwTargetID == hPlayer.dwID then
		return false
	end

	if not hPlayer.IsInParty() or not hPlayer.IsPlayerInMyParty(dwTargetID) then
		return false
	end

	local hTarget = GetPlayer(dwTargetID)
	if not hTarget then
		return false
	end

	local tMyState = GetRideState(hPlayer)
	if not tMyState or not tMyState.bDriver then
		return false
	end

	local tTargetState = GetRideState(hTarget)
	if not tTargetState or not tTargetState.bPassenger then
		return false
	end

	return tTargetState.dwDriverID == tMyState.dwDriverID
end

function TeamData.InsertRemoveFromMultiSteedMenu(tMenu, dwTargetID)
	if not CanRemoveFromMultiSteed(dwTargetID) then
		return false
	end

	table.insert(tMenu, {
		szName = "请离坐骑",
		bCloseOnClick = true,
		callback = function()
			RemoteCallToServer("On_Team_RemoveFromMultiSteed", dwTargetID)
		end,
	})
	return true
end

function TeamData.EnableMainCityRaidMode(bEnable)
	if Storage.Team.bEnableMainCityRaidMode ~= bEnable then
		Storage.Team.bEnableMainCityRaidMode = bEnable
		Storage.Team.Flush()
		Event.Dispatch(EventType.OnEnableMainCityRaidMode, bEnable)
	end
end

function TeamData.EnableMainCityTeamMode(bEnable)
	if Storage.Team.bEnableMainCityTeamMode ~= bEnable then
		Storage.Team.bEnableMainCityTeamMode = bEnable
		Storage.Team.Flush()
		Event.Dispatch(EventType.OnEnableMainCityTeamMode, bEnable)
	end
end

function TeamData.GetQuickMarkSlotInfo(nMarkID)
	if not nMarkID then
		return nil
	end
	return {
		dwSkillID = TeamData.WORLD_MARK_SKILL[nMarkID],
		dwSkillLevel = 1,
		szIconPath = string.format("UIAtlas2_Team_Team1_Img_SceneMark%02d.png", nMarkID)
	}
end

function TeamData.SetWorldMarkOpen(bOpen)
	if not self.IsTeamLeader() and bOpen then
		return
	end
	if bOpen == TeamData.bWorldMarkOpen then
		return
	end
	TeamData.bWorldMarkOpen = bOpen
	Event.Dispatch(EventType.OnDXTeamMarkChanged)
	if bOpen then
		RemoteCallToServer("On_Mobile_GetSceneMarkNum")
	end
end

function TeamData.GetWorldMarkOpen(bOpen)
	return TeamData.bWorldMarkOpen
end

function TeamData.CheckWorldMarkID(nMarkID)
	for k, v in ipairs(TeamData.tbWorldMarkList) do
		if k > nMarkID then
			return false
		end
		if v == nMarkID then
			return true
		end
	end
	return false
end

function TeamData.CancelWorldMarkID(nMarkID)
	local dwSkillID = 36259
	local dwSkillLevel = nMarkID
	local box = {
		nSkillLevel = dwSkillLevel
	}
	OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)), box)
	RemoteCallToServer("On_Mobile_GetSceneMarkNum")
end

function TeamData.CancelWorldMarkAll()
	if not TeamData.tbWorldMarkList or IsTableEmpty(TeamData.tbWorldMarkList) then
		TipsHelper.ShowNormalTip("当前暂无世界标记点")
		return
	end

	local funcConfirm = function()
		local dwSkillID = TeamData.WORLD_MARK_CLEAR_SKILL
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
		RemoteCallToServer("On_Mobile_GetSceneMarkNum")
	end

	local funcOption = function(bOption)
		TeamData.bDisableWorldMarkClearConfirm = bOption
	end

	if not TeamData.bDisableWorldMarkClearConfirm then
        local script = UIHelper.ShowConfirm("确定要清空所有已摆放的世界标记点吗？", function(bOption)
           	funcConfirm()
			funcOption(bOption)
        end, function(bOption)
			funcOption(bOption)
        end)
        script:ShowTogOption("本次启动不再提示", TeamData.bDisableWorldMarkClearConfirm)
        script:SetTogSelectedFunc(function(bOption)
			funcOption(bOption)
        end)
    else
        funcConfirm()
    end
end

function TeamData.GetMemberClientVersionType(dwMemberID)
	local memberInfo = GetClientTeam().GetMemberInfo(dwMemberID)
	if memberInfo then
		return memberInfo.nClientVersionType
	end
	return CLIENT_VERSION_TYPE.NORMAL
end


function TeamData.CheckRaidLeaveState()
	if not self.nLastTouchTime then
		return
	end
	local nDeltaTime = (os.time() - self.nLastTouchTime) * 1000
	if nDeltaTime >= RAID_LEAVE_STATE_TIME then
		if not self.bRaidLeaveState then
			self.bRaidLeaveState = true
			if GetClientPlayer() and GetClientPlayer().dwID == GetClientTeam().dwTeamLeader then
				RemoteCallToServer("On_Team_AFKAction")
			end
		end
	else
		if self.bRaidLeaveState then
			self.bRaidLeaveState = false
		end
	end
end

function TeamData.RequestLeaveTeam()
	local hTeam = GetClientTeam()
	if hTeam.bSystem then
		TipsHelper.ShowNormalTip("当前状态无法退出队伍")
		return
	end
	local nInComeMoney = hTeam.nInComeMoney
	if nInComeMoney > 0 then
		UIHelper.ShowConfirm(g_tStrings.STR_LEAVE_TEAM1, function()
			hTeam.RequestLeaveTeam()
		end)
		return
	end
	UIHelper.ShowConfirm(g_tStrings.STR_MSG_LEAVE_PARTY_CONFIRM, function()
		hTeam.RequestLeaveTeam()
	end)
end

function TeamData.OnCycleUpdate()
	self.CheckRaidLeaveState()
end

function TeamData.SelectTeammate(nSelIndex)	--选择队友从1开始
	local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.IsInParty() then
		return
	end

	local hTeam = GetClientTeam()
	local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
	local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
	local nIndex = 1
	for _, dwID in pairs(tGroupInfo.MemberList) do
		if dwID ~= hPlayer.dwID then
			if nIndex == nSelIndex then
				SelectTarget(TARGET.PLAYER, dwID)
				return
			end
			nIndex = nIndex + 1
		end
	end
end

local bSyncTeamFightData = true
function TeamData.IsSyncTeamFightData()
	return bSyncTeamFightData
end

function TeamData.SetSyncTeamFightDataState(bState)
	bSyncTeamFightData = bState
end

function TeamData.OpenConfirmTime(nVoteType, nLeftTime, dwPlayerId, szGlobalID)
	if nVoteType == 1 or nVoteType == 3 then
		local scriptRecrodView = UIMgr.GetViewScript(VIEW_ID.PanelAuctionRecord)
		local tParam = {
			tVoteInfo = {
				nVoteType = nVoteType,
				nLeftTime = nLeftTime,
				dwPlayerId = dwPlayerId,
				szGlobalID = szGlobalID,
			}
		}
		if not scriptRecrodView then
			UIMgr.Open(VIEW_ID.PanelAuctionRecord, tParam)
		else
			scriptRecrodView:OnEnter(tParam)
		end
	else
		UIMgr.Open(VIEW_ID.PanelVoteConfirmation, nVoteType, nLeftTime, dwPlayerId, szGlobalID)
	end
end

function TeamData.EnvokeAllTeammates()
	if not TeamData.IsTeamLeader() then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_TEAM_CALL_ONLY_LEADER)
		return
	end

	UIHelper.ShowConfirm(g_tStrings.STR_TEAM_CALL_EVOKE_CONFIRM, function()
		RemoteCallToServer("On_Team_CallInToPlayerList")
	end)
end

function TeamData.GetSignPostPos()
	if TeamData.nSignPostX and TeamData.nSignPostY then
		if GetTickCount() - TeamData.nSignPostTime < 6000 then
			return TeamData.nSignPostX, TeamData.nSignPostY
		end
		TeamData.nSignPostX, TeamData.nSignPostY = nil, nil
	end
	return nil, nil
end

function TeamData.RequestRecruitInfo()
	if not g_pClientPlayer then
		return
	end
	if not TeamData.IsInParty() then
		return
	end
	local hTeam = GetClientTeam()
	local dwTeamLeader = hTeam.dwTeamLeader
	self.dwTeamRecruitLinkID = dwTeamLeader
    if self.dwTeamRecruitLinkID then
        ApplyTeamPushSingle(self.dwTeamRecruitLinkID)
    end
end

local SINGLE_FB_BUFFID = 27896
function TeamData.CheckInSingleFB(bNotify)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return true
	end
	local bInSingleFB = hPlayer.IsHaveBuff(SINGLE_FB_BUFFID, 1)
	if bInSingleFB then
		if bNotify then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CANNOT_JOINTEAM_IN_SINGLEFB)
		end
		return true
	end
	return false
end

function TeamData.InviteJoinTeam(szName)
	if not szName then
		return
	end
	if TeamData.CheckInSingleFB(true) then
		return
	end
	GetClientTeam().InviteJoinTeam(szName)
end

function TeamData.RespondTeamInvite(szInviter, bAgree)
	if not szInviter or bAgree == nil then
		return
	end
	if bAgree == 1 and TeamData.CheckInSingleFB(true) then
		return
	end
	GetClientTeam().RespondTeamInvite(szInviter, bAgree)
end


-------------------- 团队确认 --------------------
function TeamData.SetConfirmState(nState)
	TeamData.tMemberReadyConfirm = {}
	TeamData.Generator(function(dwID, tMemberInfo)
		TeamData.tMemberReadyConfirm[dwID] = nState
	end)
end

function TeamData.StartReadyConfirm()
    TeamData.bStartReadyConfirm = true
    TeamData.SetConfirmState(RAID_READY_CONFIRM_STATE.NotYet)

    local hPlayer = GetClientPlayer()
    TeamData.tMemberReadyConfirm[hPlayer.dwID] = RAID_READY_CONFIRM_STATE.Ok

    RemoteCallToServer("OnStartRollCall")
	Event.Dispatch(EventType.UpdateStartReadyConfirm)
end

function TeamData.ResetReadyConfirm()
	TeamData.bStartReadyConfirm = false
	TeamData.SetConfirmState(RAID_READY_CONFIRM_STATE.Init)
	Event.Dispatch(EventType.UpdateStartReadyConfirm)
end

function TeamData.IsStartReadyConfirm()
	return TeamData.bStartReadyConfirm
end

function TeamData.GetMemberReadyConfirm(dwID)
	if not TeamData.bStartReadyConfirm then
		return TeamData.tMemberReadyConfirm[dwID] or RAID_READY_CONFIRM_STATE.Init
	else
		return TeamData.tMemberReadyConfirm[dwID] or RAID_READY_CONFIRM_STATE.NotYet
	end
end

function TeamData.StartRaidCountDown(nCountDown)
	Storage.Team.nRaidCountDown = nCountDown
	Storage.Team.Dirty()

	if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
		return
	end

    if not TeamData.IsTeamLeader() then
        return
    end

    SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_COUNTDOWN", nCountDown)
end

function TeamData.GetTeamAndRoomNoticeState()
	return self.bTeamNoticeOpen, self.bRoomNoticeOpen
end

function TeamData.SetTeamAndRoomNoticeState(bTeamNoticeOpen, bRoomNoticeOpen)
	self.bTeamNoticeOpen = bTeamNoticeOpen
	self.bRoomNoticeOpen = bRoomNoticeOpen
end

-------------------- 队伍事件 -----------------------
Event.Reg(self, "LOADING_END", function()
	SetTeamSkillEffectSyncOption(bSyncTeamFightData)
end)

Event.Reg(self, "PARTY_INVITE_REQUEST", function(szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam)
    if not IsRegisterEvent("PARTY_INVITE_REQUEST") then
		--FireUIEvent("FILTER_PARTY_INVITE_REQUEST", arg0, arg1, arg2, arg3, arg4, arg5)
        return
    end

    if nType == 2 then
		TeamData.RespondTeamInvite(szInviteSrc, 1)
		return
	end
end)

Event.Reg(self, "PARTY_APPLY_REQUEST", function ()
end)

Event.Reg(self, "FIGHT_HINT", function(bFight)
	if bFight then
		TeamData.ResetReadyConfirm()
	end
end)

Event.Reg(self, EventType.OnRaidReadyConfirmReceiveQuestion, function (dwLeaderID)
	local hPlayer = GetClientPlayer()
	if hPlayer.dwID == dwLeaderID then
		return
	end
	local hTeam = GetClientTeam()
	local info = TeamData.GetMemberInfo(dwLeaderID, hTeam)
	local szName = info and UIHelper.GBKToUTF8(info.szName) or ""
	local szContent = string.pure_text(FormatString(g_tStrings.STR_RAID_MSG_READY_CONFIRM, szName))
	local fnConfirm = function ()
		RemoteCallToServer("OnVerifyReady", dwLeaderID, RAID_READY_CONFIRM_STATE.Ok)
	end
	local fnCancel = function ()
		RemoteCallToServer("OnVerifyReady", dwLeaderID, RAID_READY_CONFIRM_STATE.NotYet)
	end

	PSMMgr.ExitPSMMode()
	local dialog = UIHelper.ShowConfirm(szContent, fnConfirm, fnCancel, false)
	dialog:ShowOtherButton()
	dialog:SetOtherButtonContent("挂起")
	dialog:SetOtherButtonClickedCallback(function()
		TipsHelper.ShowTeamReadyConfirmTip({
			nCancel = 60,
			dwLeaderID = dwLeaderID,
		})
	end)
end)

Event.Reg(self, EventType.OnRaidReadyConfirmReceiveAnswer, function(dwPlayerID, nReadyState)
	if TeamData.bStartReadyConfirm then
		TeamData.tMemberReadyConfirm[dwPlayerID] = nReadyState
		Event.Dispatch(EventType.UpdateMemberReadyConfirm, dwPlayerID)

		if nReadyState == RAID_READY_CONFIRM_STATE.Ok then
			local bAllOk = true
			TeamData.Generator(function (dwID, tMemberInfo)
				if TeamData.tMemberReadyConfirm[dwID] ~= RAID_READY_CONFIRM_STATE.Ok then
					bAllOk = false
				end
			end)
			if bAllOk then
				TeamData.ResetReadyConfirm()
			end
		end
	end
end)

Event.Reg(self, "PARTY_MESSAGE_NOTIFY", function()
	-- 队友战斗统计数据
	if arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED or arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED then
		TeamData.SetSyncTeamFightDataState(true)
		SetTeamSkillEffectSyncOption(true)
		TeamData.ResetReadyConfirm()
	end

	local szMsg = ""
	if arg0 == PARTY_NOTIFY_CODE.PNC_PLAYER_INVITE_NOT_EXIST or
		arg0 == PARTY_NOTIFY_CODE.PNC_PLAYER_APPLY_NOT_EXIST or
		arg0 == PARTY_NOTIFY_CODE.PNC_CAMP_ERROR then
		PlaySound(SOUND.UI_SOUND,g_sound.ActionFailed)

	elseif arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED then
		FireUIEvent("CREATE_PLAYER_PARTY", true)
		Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, true)
	elseif arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED then
		FireUIEvent("JOINED_PLAYER_PARTY")
		Event.Dispatch(EventType.OnSelectedTaskTeamViewToggle, true)
	end
	szMsg = FormatString(g_tStrings.tFellowShipState[arg0], UIHelper.GBKToUTF8(arg1))
	TipsHelper.OutputMessage("MSG_SYS", szMsg)
end)

Event.Reg(self, "PARTY_DISBAND", function()
	TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_YOUR_PARTY_DISBAND)
end)

Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function()
	if not arg4 then --仅加入队伍的时候需要下面的提示
		return
	end

	if arg2 == PARTY_LOOT_MODE.FREE_FOR_ALL then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_LOOTMODE, g_tStrings.STR_LOOTMODE_FREE_FOR_ALL))
	elseif arg2 == PARTY_LOOT_MODE.DISTRIBUTE then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_LOOTMODE, g_tStrings.STR_LOOTMODE_DISTRIBUTE))
		TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_DISTRIBUTE_WARNING)
	elseif arg2 == PARTY_LOOT_MODE.BIDDING then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_LOOTMODE, g_tStrings.STR_LOOTMODE_GOLD_BID_RAID))
		TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_GOLD_BID_WARNING)
	elseif arg2 == PARTY_LOOT_MODE.GROUP_LOOT then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_LOOTMODE, g_tStrings.STR_LOOTMODE_GROUP_LOOT))
	else
		LOG.ERROR("PARTY_LOOT_MODE_CHANGED changed to a unkown mode!\n")
	end

	if arg3 == 2 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_ROLLQUALITY, g_tStrings.STR_ROLLQUALITY_GREEN))
	elseif arg3 == 3 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_ROLLQUALITY, g_tStrings.STR_ROLLQUALITY_BLUE))
	elseif arg3 == 4 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_ROLLQUALITY, g_tStrings.STR_ROLLQUALITY_PURPLE))
	elseif arg3 == 5 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_CURRENT_ROLLQUALITY, g_tStrings.STR_ROLLQUALITY_NACARAT))
	else
		LOG.ERROR("PARTY_ROLL_QUALITY_CHANGED changed to a unkown ROLLQUALITY!\n")
	end

	local hTeam = GetClientTeam()
	if hTeam.nCamp ~= CAMP.NEUTRAL then
		TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_TEAM_CAMP_MSG_NEW)
	end
end)

Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function()
	if arg1 == PARTY_LOOT_MODE.FREE_FOR_ALL then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LOOTMODE_CHANGED, g_tStrings.STR_LOOTMODE_FREE_FOR_ALL))
	elseif arg1 == PARTY_LOOT_MODE.DISTRIBUTE then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LOOTMODE_CHANGED, g_tStrings.STR_LOOTMODE_DISTRIBUTE))
		TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_DISTRIBUTE_WARNING)
	elseif arg1 == PARTY_LOOT_MODE.BIDDING then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LOOTMODE_CHANGED, g_tStrings.STR_LOOTMODE_GOLD_BID_RAID))
		TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_MSG_GOLD_BID_WARNING)
	elseif arg1 == PARTY_LOOT_MODE.GROUP_LOOT then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LOOTMODE_CHANGED, g_tStrings.STR_LOOTMODE_GROUP_LOOT))
	else
		LOG.ERROR("PARTY_LOOT_MODE_CHANGED changed to a unkown mode!\n")
	end
end)

Event.Reg(self, "PARTY_ROLL_QUALITY_CHANGED", function()
	if arg1 == 2 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_ROLLQUALITY_CHANGED, g_tStrings.STR_ROLLQUALITY_GREEN))
	elseif arg1 == 3 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_ROLLQUALITY_CHANGED, g_tStrings.STR_ROLLQUALITY_BLUE))
	elseif arg1 == 4 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_ROLLQUALITY_CHANGED, g_tStrings.STR_ROLLQUALITY_PURPLE))
	elseif arg1 == 5 then
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_ROLLQUALITY_CHANGED, g_tStrings.STR_ROLLQUALITY_NACARAT))
	else
		LOG.ERROR("PARTY_ROLL_QUALITY_CHANGED changed to a unkown ROLLQUALITY!\n")
	end
end)

Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
	local szMsg = nil
	local szName = TeamData.GetTeammateName(arg3)
	if arg0 == TEAM_AUTHORITY_TYPE.LEADER then
		szMsg = FormatString(g_tStrings.STR_MSG_PARTY_LEADER_CHANGED, UIHelper.GBKToUTF8(szName))
		if g_pClientPlayer and arg3 == g_pClientPlayer.dwID and self.bRaidLeaveState then
			RemoteCallToServer("On_Team_AFKAction")
		end
		-- if IsInZombieBattleFieldMap() and arg3 == GetClientPlayer().dwID then
		-- 	GetClientTeam().LevelUpRaid()
		-- end
	elseif arg0 == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
		szMsg = FormatString(g_tStrings.STR_MSG_PARTY_SET_DISTRIBUTE_MAN, UIHelper.GBKToUTF8(szName))
	elseif arg0 == TEAM_AUTHORITY_TYPE.MARK then
		szMsg = FormatString(g_tStrings.STR_MSG_PARTY_SET_MARK_MAN, UIHelper.GBKToUTF8(szName))
	end
	if szMsg then
		TipsHelper.OutputMessage("MSG_SYS", szMsg)
	end

	if arg0 == TEAM_AUTHORITY_TYPE.LEADER then
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end
		if hPlayer.dwID == arg2 or hPlayer.dwID == arg3 then
			self.SetWorldMarkOpen(false)
			TeamData.ResetReadyConfirm()
		end
	end
end)

Event.Reg(self, "PARTY_SET_FORMATION_LEADER", function()
	if TeamData.IsInMyGroup(arg0) then
		local szName = TeamData.GetTeammateName(arg0)
		TipsHelper.OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_PARTY_SET_FORMATION_LEADER, UIHelper.GBKToUTF8(szName)))
	end
end)

Event.Reg(self, "PARTY_ADD_MEMBER", function()
	-- TODO 这是啥？
	-- local hPlayer 	= GetClientPlayer()
	-- local hTeam 	= GetClientTeam()
	--两个人组队时，队伍信息还没同步该事件便会被捕捉到,而且只有队长捕捉到该事件
	-- if  IsInZombieBattleFieldMap() and
	-- 	(
	-- 		hTeam.GetTeamSize() == 2 or
	-- 		( hPlayer.IsInParty() and hPlayer.IsPartyLeader() )
	-- 	)
	-- then
	-- 	local dwNewTeamMemberId = arg1
	-- 	RemoteCallToServer("On_Vampire_JoinTeam", dwNewTeamMemberId)
	-- end

	local tbMemberInfo = TeamData.GetMemberInfo(arg1)
	TipsHelper.ShowNormalTip(string.format("【%s】已加入队伍", UIHelper.GBKToUTF8(tbMemberInfo.szName)))
end)

Event.Reg(self, EventType.StartEndWorldMark, function()
	TeamData.SetWorldMarkOpen(not TeamData.bWorldMarkOpen)
end)

Event.Reg(self, EventType.OnGetWorldMarkInfo, function(tInfo)
	table.sort(tInfo)
	TeamData.tbWorldMarkList = clone(tInfo)
end)

Event.Reg(self, EventType.OnClientPlayerEnter, function()
	self.SetWorldMarkOpen(false)
	TeamData.ResetReadyConfirm()
end)

Event.Reg(self, EventType.OnSceneTouchBegan, function()
	self.nLastTouchTime = os.time()
	self.CheckRaidLeaveState()
end)

Event.Reg(self, EventType.OnWidgetTouchDown, function()
	self.nLastTouchTime = os.time()
	self.CheckRaidLeaveState()
end)

Event.Reg(TeamData, "TEAM_VOTE_REQUEST", function()
	local nLeftTime = 30
	local hTeam = GetClientTeam()
	local hPlayer = GetClientPlayer()

	if not hTeam or not hPlayer then
		return
	end

	if arg0 == 0 then
		if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID then
			hTeam.Vote(arg0, 1)
		else
			TeamData.OpenConfirmTime(arg0, nLeftTime, arg1)
		end
	elseif arg0 == 1 then
		if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID then
			hTeam.Vote(arg0, 1)
		else
			TeamData.OpenConfirmTime(arg0, nLeftTime, arg1)
		end
	elseif arg0 == 2 then
		if RoomData.IsRoomOwner() then
			hTeam.Vote(arg0, 1)
		else
			TeamData.OpenConfirmTime(arg0, nLeftTime, nil, arg4)
		end
	elseif arg0 == 3 then
		if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == hPlayer.dwID then
			hTeam.Vote(arg0, 1)
		else
			TeamData.OpenConfirmTime(arg0, nLeftTime, arg1)
		end
	end
end)

Event.Reg(TeamData, "TEAM_VOTE_RESPOND", function()
	-- TeamData.OnTeamVoteRespond()
end)

Event.Reg(TeamData, "PARTY_NOTIFY_SIGNPOST", function()
	TeamData.nSignPostX, TeamData.nSignPostY = arg0, arg1
	TeamData.nSignPostTime = GetTickCount()
	SoundMgr.PlaySound(SOUND.UI_SOUND,g_sound.MapHit)
end)


Event.Reg(self, "ON_PUSH_TEAM_NOTIFY", function()
    if arg0 ~= "single" then
		return
	end
    if not self.dwTeamRecruitLinkID then
        return
    end

    local tInfo = GetTeamPushInfoSingle(self.dwTeamRecruitLinkID)
	if tInfo then
        UIMgr.Open(VIEW_ID.PanelTeam, 1, self.dwTeamRecruitLinkID)
    else
        TipsHelper.ShowNormalTip("当前队伍未开启招募")
	end
    self.dwTeamRecruitLinkID = nil
end)

Event.Reg(self, "ON_BG_CHANNEL_MSG", function (szKey, nChannel, dwTalkerID, szName, aParam)
	if szKey == "RAID_COUNTDOWN" and nChannel == PLAYER_TALK_CHANNEL.RAID then
		if aParam and aParam[1] then
			TipsHelper.PlayCountDown(aParam[1])
		end
	end
end)
