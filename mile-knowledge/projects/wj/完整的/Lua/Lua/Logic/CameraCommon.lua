-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CameraCommon
-- Date: 2023-10-10 19:39:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

CameraCommon = CameraCommon or {className = "CameraCommon"}
local self = CameraCommon
-------------------------------- 消息定义 --------------------------------
CameraCommon.Event = {}
CameraCommon.Event.XXX = "CameraCommon.Msg.XXX"

local m_nScale
local m_nNowCamera_ID 		= nil
local m_nMatchTime 			= nil
local m_nSetPlayeViewTime 	= nil
local MATCH_CD 				= 1000
local SET_PLAYER_TIME 		= 15 * 1000
local m_bIsWatch
local m_bNotServer
local m_nSetPlayerViewTimerID = nil

function CameraCommon.Init()
	Event.Reg(CameraCommon, "LOADING_END", function ()
		if m_bIsWatch then
			CameraCommon.EndWatch()
		end
	end)
end

function CameraCommon.UnInit()
	Event.UnReg(CameraCommon, "LOADING_END")
end

function CameraCommon.setPlayerView(dwPlayerID)
	local hViewPlayer = GetPlayer(dwPlayerID)
    if not hViewPlayer then
		if m_bNotServer then
			return
		end
		if m_nSetPlayeViewTime then
			if GetTime() - m_nSetPlayeViewTime < SET_PLAYER_TIME then
                m_nSetPlayerViewTimerID = Timer.Add(self, 0.5, function()
                    self.setPlayerView(dwPlayerID)
                end)
			else
				self.setAllView()
			end
		end
        return
    end

	m_nNowCamera_ID = dwPlayerID
	FireUIEvent("ON_UPDATE_CAMERA_VIEW", m_nNowCamera_ID)
	local pPlayer = GetClientPlayer()
	if pPlayer then
		local dwTargetType, dwTargetID = pPlayer.GetTarget()
		if dwTargetType ~= TARGET.PLAYER or dwTargetID ~= m_nNowCamera_ID then
			SetTarget(TARGET.PLAYER, dwPlayerID)
		end
	end
	CameraMgr.Status_Set({
		scale = 1,
		yaw = 2 * math.pi - (hViewPlayer.nFaceDirection / 255 * math.pi * 2 - math.pi / 2),
		pitch = -math.pi / 10,
		--tick = 0,
		mode    = "remote camera",  -- 镜头模式 跟随视角
		remoteid = dwPlayerID,
		dis_ctrl = false,
	})
end

function CameraCommon.setViewSelf()
	m_nNowCamera_ID = UI_GetClientPlayerID()
	local pPlayer = GetClientPlayer()
	if pPlayer then
		local dwTargetType, dwTargetID = pPlayer.GetTarget()
		if dwTargetType ~= TARGET.PLAYER or dwTargetID ~= m_nNowCamera_ID then
			SetTarget(TARGET.PLAYER, m_nNowCamera_ID)
		end
	end
	local hPlayer = GetClientPlayer()
	if hPlayer then
		CameraMgr.Status_Set({
			mode    = "local camera",
			scale   = m_nScale or 0.9,
			yaw     = 2 * math.pi - (hPlayer.nFaceDirection / 255 * math.pi * 2 - math.pi / 2),
			pitch   = - math.pi / 12,
		})
	end
	FireUIEvent("ON_UPDATE_CAMERA_VIEW", m_nNowCamera_ID)
end

function CameraCommon.setAllView()
    local scale, yaw, _, SceneX, SceneY, SceneZ= Camera_GetRTParams()
    local x, y, z = Scene_ScenePositionToGameWorldPosition(SceneX , SceneY, SceneZ)
    CameraMgr.Status_Set({
		scale = math.max(0.80, scale),
		pitch = -math.pi / 8,
		yaw     = yaw,
		--tick     = 0,
		mode    = "god camera",
		x       = x,
		y       = y,
		z       = z,
		dis_ctrl= 1,
		Limit   = 1,
		limitx  = 500,
		limity  = 500,
		limitz  = 500,
    })
	m_nNowCamera_ID = nil

	local pPlayer = GetClientPlayer()
	if pPlayer then
		local dwTargetType, dwTargetID = pPlayer.GetTarget()
		if dwTargetType ~= TARGET.NO_TARGET then
			SelectTarget(TARGET.NO_TARGET, 0)
		end
	end

	FireUIEvent("ON_UPDATE_CAMERA_VIEW", m_nNowCamera_ID)
end

function CameraCommon.SetView(dwPlayerID)
	m_nSetPlayeViewTime = nil
    if m_nSetPlayerViewTimerID then
	    Timer.DelTimer(self, m_nSetPlayerViewTimerID)
        m_nSetPlayerViewTimerID = nil
    end
	if dwPlayerID and dwPlayerID ~= 0 then
		if dwPlayerID == UI_GetClientPlayerID() then
			self.setViewSelf()
		else
			m_nSetPlayeViewTime = GetTime()
			self.setPlayerView(dwPlayerID)
		end
	else
		self.setAllView()
	end
end

function CameraCommon.Match(bNext, bSecond)
	local hTeam 		= GetClientTeam()
	local nTime 		= GetTime()
	local tMembers  	= {}

	local hPlayer = GetClientPlayer()
	if not CameraCommon.IsWatch() then
		return
	end
	hTeam.GetTeamMemberList(tMembers)
	for _, dwMemberID in pairs(tMembers) do
		if not bNext then
			local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
			if (not tMemberInfo.bDeathFlag) and dwMemberID ~= UI_GetClientPlayerID() then
				--调用切视角的
				if m_nMatchTime and nTime - m_nMatchTime <= MATCH_CD then
					OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_TREASURE_MATCH_CD)
					return
				end
				m_nMatchTime = nTime
				if m_bNotServer then
					CameraCommon.SetView(dwMemberID)
				else
					CameraCommon.SetViewServer(dwMemberID)
				end
				return
			end
		end
		if m_nNowCamera_ID == dwMemberID and bNext then
			bNext = nil
		end
	end

	if not bSecond then
		--再遍历一边
		self.Match(nil, true)
	else--切回自己
		local hPlayer = GetClientPlayer()
		if hPlayer then
			if m_nNowCamera_ID then --之前镜头在别人身上才提示
				OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_TREASURE_MATCH2)
			end
			RemoteCallToServer("On_Camera_WatchAll")
		end
	end
end

function CameraCommon.UpdateSelectTarget()
	local pPlayer = GetClientPlayer()
	if pPlayer then
		local dwTargetType, dwTargetID = pPlayer.GetTarget()
		 if dwTargetType == TARGET.PLAYER then
			local hTarget = GetPlayer(dwTargetID)
			if IsParty(dwTargetID, UI_GetClientPlayerID()) and hTarget and hTarget.nMoveState ~= MOVE_STATE.ON_DEATH then
				if dwTargetID ~= m_nNowCamera_ID then
					if m_bNotServer then
						CameraCommon.SetView(dwTargetID)
					else
						CameraCommon.SetViewServer(dwTargetID)
					end
				end
			end
		end
	end
end

function CameraCommon.SetViewServer(dwTargetID)
	if dwTargetID then
		if m_nNowCamera_ID ~= dwTargetID then
			RemoteCallToServer("On_Camera_WatchPlayer", dwTargetID)
		end
	else
		if m_nNowCamera_ID then
			RemoteCallToServer("On_Camera_WatchAll")
		end
	end
end

function CameraCommon.StartWatch(bNotServer)
	if ArenaData.IsJJCInjury() then
		local scale, yaw, pitch, t1, t2, t3 = Camera_GetRTParams()
		m_nScale = scale
		if not m_bIsWatch then
			Event.Reg(CameraCommon, EventType.OnTargetChanged, function ()
				CameraCommon.UpdateSelectTarget()
			end)
		end
		m_bIsWatch = true
		m_bNotServer = bNotServer
	end
end

function CameraCommon.EndWatch()
	if m_bIsWatch then
		Event.UnReg(CameraCommon, EventType.OnTargetChanged)
		CameraCommon.setViewSelf()
		if m_nSetPlayerViewTimerID then
			Timer.DelTimer(self, m_nSetPlayerViewTimerID)
			m_nSetPlayerViewTimerID = nil
		end
	end
	m_bIsWatch = false
	m_bNotServer = nil
	m_nNowCamera_ID = nil
end

function CameraCommon.IsWatch()
	return m_bIsWatch
end