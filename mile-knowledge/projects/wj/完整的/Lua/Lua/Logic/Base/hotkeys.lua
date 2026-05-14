local SCREENSHOT_QUALITY = 100
local SCREENSHOT_SUFFIX = "jpg"
local lc_aAutoClose = {}
local lc_aAutoCloseTopmost = {}
local lc_aIndePentShow = {}
local m_tSpecialHorseOnJump
local byte = string.byte
local CameraDef = ControlDef

g_HotKey = {}

g_aVKeyToDesc =
{
--	0x0,		0x1,		0x2,		0x3,		0x4,		0x5,		0x6,		0x7,		0x8,		0x9,		0xA,		0xB,		0xC,		0xD,		0xE,		0xF,
				"LButton",	"RButton",	"Cancel",	"MButton",	"XButton1",	"XButton2",	"",			"Backspace","Tab",		"",			"",			"Clear",	"Enter",	"",			"",
	"Shift",	"Ctrl",		"Alt",		"Pause",	"CapLock",	"Hanguel",	"",			"Junja",	"Final",	"Kanji",	"",			"Esc",		"Convert",	"NonConvert","Accept",	"ModeChange",
	"Space",	"PageUp",	"PageDown",	"End",		"Home",		"Left",		"Up",		"Right",	"Down",		"Select",	"Print",	"Execute",	"PrintScreen",	"Insert",	"Delete",	"Help",
	"0",		"1",		"2",		"3",		"4",		"5",		"6",		"7",		"8",		"9",		"",			"",			"",			"",			"",			"",
	"",			"A",		"B",		"C",		"D",		"E",		"F",		"G",		"H",		"I",		"J",		"K",		"L",		"M",		"N",		"O",
	"P",		"Q",		"R",		"S",		"T",		"U",		"V",		"W",		"X",		"Y",		"Z",		"LWin",		"RWin",		"Apps",		"",			"",
	"Num0",		"Num1",		"Num2",		"Num3",		"Num4",		"Num5",		"Num6",		"Num7",		"Num8",		"Num9",		"Multiply",	"Add",		"Separator","Subtract",	"Decimal",	"Divide",
	"F1",		"F2",		"F3",		"F4",		"F5",		"F6",		"F7",		"F8",		"F9",		"F10",		"F11",		"F12",		"F13",		"F14",		"F15",		"F16",
	"F17",		"F18",		"F19",		"F20",		"F21",		"F22",		"F23",		"F24",		"",			"",			"",			"",			"",			"",			"",			"",
	"NumLock",	"ScrollLock","",		"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",
	"",			"",			"",			"",			"",			"",			"BrowserBack","BrowserForward","BrowserRefresh","BrowserStop","BrowserSearch","BrowserFavorites","BrowserHome","VolumeMute","VolumeDown","VolumeUp",
	"MediaNextTrack","MediaPrevTrack","MediaStop","MediaPlayPause","LaunchMail","LaunchMediaSelect","LaunchApp1","LaunchApp2","","","OEM1","OEMPlus","OEMComma","OEMMinus","OEMPeriod",	"OEM2",
	"OEM3",		"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",
	"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"[",		"\\",		"]",		"'",		"",
	"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",
	"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",			"",
	"MouseWheelUp","MouseWheelDown","MouseHover",""
};

function IsKeyDoubleDown()
	if Hotkey.IsKeyDoubleDown() then
		if Hotkey.GetKeyTimeInterval() < 250 then
			return true
		end
	end

	return false
end

--临时
CLASSICAL_MODE = 0
JOYSTICK_MODE = 1
LOCKED_MODE = 2
function GetOperationMode()
	return CLASSICAL_MODE
end

function IsPlayerFaceLocked()
	local player = GetControlPlayer()
	return player and (player.nFollowType == FOLLOW_TYPE.SIMMOVE or player.bLockedFace)
end
-- 轻功按键响应
local l_dwCurrentKungfuID
local l_dwCurrentSchoolID
local l_tDisplacementHotkeysDown
local l_tDisplacementHotkeysUp
local function DoesInfoRIDsMatchPlayer(aRIDGroups, tPlayerRIDs)
	local bMatch = true
	for _, tOneRpGroup in ipairs(aRIDGroups) do
		bMatch = true
		for nRpIndex, dwRpID in pairs(tOneRpGroup) do
			if tPlayerRIDs[nRpIndex] ~= dwRpID then
				bMatch = false
				break
			end
		end
		if bMatch then
			break
		end
	end
	
	return bMatch
end

local function DoesInfoRIDsNotMatchPlayer(aNotRIDGroups, tPlayerRIDs)
	local bMatch = true
	for _, tOneRpGroup in ipairs(aNotRIDGroups) do
		bMatch = true
		for nRpIndex, dwRpID in pairs(tOneRpGroup) do
			if tPlayerRIDs[nRpIndex] == dwRpID then
				bMatch = false
				break
			end
		end
		if not bMatch then
			break
		end
	end
	
	return bMatch
end

local function InitDisplacementHotkeys()
	local player = GetClientPlayer()
	if not player then
		return nil
	end

	local dwBitOPSchoolID = player.dwBitOPSchoolID
	local dwKungfuID = UI_GetPlayerMountKungfuID()
	local tBitOPSchoolIDs = {}
	local aSchool = player.GetSchoolList()
	for k, v in pairs(aSchool) do
		local aKungfu = player.GetKungfuList(v)
		for dwID, dwLevel in pairs(aKungfu) do
			local dwBitOPSchoolID = Kungfu_GetSchoolType(dwID)
			if dwBitOPSchoolID then
				tBitOPSchoolIDs[dwBitOPSchoolID] = true
			end
		end
	end

	if dwKungfuID ~= l_dwCurrentKungfuID or dwBitOPSchoolID ~= l_dwCurrentSchoolID then
		l_dwCurrentKungfuID      = dwKungfuID
		l_dwCurrentSchoolID		 = dwBitOPSchoolID
		l_tDisplacementHotkeysDown = {}
		l_tDisplacementHotkeysUp   = {}
		for _, ss in ilines(g_tTable.DisplacementHotkeys) do
			if tBitOPSchoolIDs[ss.dwBitOPSchoolID] or ss.dwBitOPSchoolID == -1 or ss.dwBitOPSchoolID == COMMON_SPRINT_SCHOOL_ID then
				local skill
				if ss.dwSkillID > 0 then
					skill = GetSkill(ss.dwSkillID, ss.nSkillLevel)
				end
				if skill then
					ss.bHoardSkill = skill.bHoardSkill
				end
				if ss.szRepresentIDGroups ~= "" then
					local aRpIDGroups = SplitString(ss.szRepresentIDGroups, "|")
					ss["aRepresentIDGroups"] = {} -- 映射表组成的数组
					for _, szOneRpGroup in ipairs(aRpIDGroups) do
						local aRpIDsInGroup = SplitString(szOneRpGroup, ";")
						local tOneRpGroup = {}
						for _, szOneRpIDInfo in ipairs(aRpIDsInGroup) do
							local t = SplitString(szOneRpIDInfo, ":") -- 得到一个二元数组
							local nRepresentIndex = tonumber(t[1])
							local dwRepresentID = tonumber(t[2])
							tOneRpGroup[nRepresentIndex] = dwRepresentID
						end
						table.insert(ss["aRepresentIDGroups"], tOneRpGroup)
					end
				end
				if ss.szNotRepresentIDGroups ~= "" then
					local aRpIDGroups = SplitString(ss.szNotRepresentIDGroups, "|")
					ss["aNotRepresentIDGroups"] = {} -- 映射表组成的数组
					for _, szOneRpGroup in ipairs(aRpIDGroups) do
						local aRpIDsInGroup = SplitString(szOneRpGroup, ";")
						local tOneRpGroup = {}
						for _, szOneRpIDInfo in ipairs(aRpIDsInGroup) do
							local t = SplitString(szOneRpIDInfo, ":") -- 得到一个二元数组
							local nRepresentIndex = tonumber(t[1])
							local dwRepresentID = tonumber(t[2])
							tOneRpGroup[nRepresentIndex] = dwRepresentID
						end
						table.insert(ss["aNotRepresentIDGroups"], tOneRpGroup)
					end
				end
				if ss.bHoardSkill
				or ss.nKeyState == -1 or ss.nKeyState == 1 then
					if not l_tDisplacementHotkeysUp[ss.szKey] then
						l_tDisplacementHotkeysUp[ss.szKey] = {}
					end
					table.insert(l_tDisplacementHotkeysUp[ss.szKey], ss)
				end
				if ss.nKeyState == -1 or ss.nKeyState == 0 then
					if not l_tDisplacementHotkeysDown[ss.szKey] then
						l_tDisplacementHotkeysDown[ss.szKey] = {}
					end
					table.insert(l_tDisplacementHotkeysDown[ss.szKey], ss)
				end
			end
		end
	end
end

local function CheckBuff(dwBuffID, nBuffLevel)
    if dwBuffID == -1 then
        return true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    local bHave = hPlayer.IsHaveBuff(dwBuffID, nBuffLevel) --Buff_Have(hPlayer, dwBuffID, nBuffLevel)
    return bHave
end

local nKeepUsingSkillID, nKeepUsingSkillLevel
local function KeepUsingSkill()
	local pPlayer = GetClientPlayer()
	if not pPlayer.bBirdMove then
		BreatheCall("KEEP_USING_SKILL", false)
		return
	end
	if nKeepUsingSkillID and pPlayer.nMoveState == MOVE_STATE.ON_BIRD_FLOAT then
		OnUseSkill(nKeepUsingSkillID, (nKeepUsingSkillID * (nKeepUsingSkillID % 10 + 1)), {_vir=true, nSkillLevel=nKeepUsingSkillLevel})
	end
end

local tDisplacementSkillSetting = {
	bForbidCastYCBX, --蓬莱逸尘步虚开关
}
function SetDisplacementSkillSetting(szName, value)
	tDisplacementSkillSetting[szName] = value
end

function GetDisplacementSkillSetting(szName)
	return tDisplacementSkillSetting[szName] or IsMobileKungfu()
end

local _box = { _vir=true }
local l_nSprintHoardEndJumpCount
local _tKeyPressed = {}
function ResponseDisplacementHotkey(szKey, bDown, bDoubleClick)
	local player = GetClientPlayer()
	if not player then
		return false
	end
	local dwBitOPSchoolID = player.dwBitOPSchoolID
	-- if dwBitOPSchoolID ~= SCHOOL_TYPE.JIANG_HU then
	-- 	dwBitOPSchoolID = Kungfu_GetSchoolType(UI_GetPlayerMountKungfuID())
	-- end
	if FuncSlotMgr.bExecutingCommand and GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec == GameSettingType.SprintMode.Common.szDec then
        dwBitOPSchoolID = COMMON_SPRINT_SCHOOL_ID
    end
	if not bDown then
		_tKeyPressed[szKey] =  nil
	else
		_tKeyPressed[szKey] =  true
	end
	InitDisplacementHotkeys()
	local nCount, bStopAction = 0, false
	local bJumping = player.nMoveState ~= MOVE_STATE.ON_RUN
	local nJumpCount = bDown and player.nJumpCount or l_nSprintHoardEndJumpCount
	local bWeapon = GetPlayerWeaponType(player) == GetBitOPSchoolIDWeaponType(player.dwBitOPSchoolID)
	local bFighting = player.bFightState
	local bSprintFlag = player.bSprintFlag
	local bSlideSprintFlag = player.bSlideSprintFlag
	local nTargetType = player.GetTarget()
	local bFollowController = player.IsFollowController()
	local bRunOnWater = player.IsRunOnWater() == 1
	local bHangFlag = IsPlayerInHang()
	local bOnTowerFlag = player.bOnTowerFlag
	local bIgnoreGravity = player.bIgnoreGravity
	local bBirdMove = player.bBirdMove
	local nFlyFlag = player.nFlyFlag
	local bParkourFlag = player.bParkourFlag
	local tPlayerRIDs = player.GetRepresentID()
	local nOTActionState = player.GetOTActionState()
	local bIsHasValidTrack = SprintEx_HasValidTrack()
	local tssis
	if bDown then
		tssis = l_tDisplacementHotkeysDown[szKey]
		l_nSprintHoardEndJumpCount = player.nJumpCount
	else
		tssis = l_tDisplacementHotkeysUp[szKey]
		l_nSprintHoardEndJumpCount = nil
	end
	if tssis then
		for i, ssi in ipairs(tssis) do
			if  ((ssi.dwBitOPSchoolID == dwBitOPSchoolID or ssi.dwBitOPSchoolID == -1) or (ssi.bIgnoreCommonSprint and ssi.dwBitOPSchoolID == player.dwBitOPSchoolID))
			and ((ssi.nDoubleClick == 1) == bDoubleClick or ssi.nDoubleClick == -1)
			and ((ssi.bSlideSprintFlag == 1) == bSlideSprintFlag or ssi.bSlideSprintFlag == -1)
			and (ssi.nJumpCount == nJumpCount or ssi.nJumpCount == -1)
			and ((ssi.nJumping == 1) == bJumping or ssi.nJumping == -1)
			and ((ssi.nWeaponCheck == 1) == bWeapon or ssi.nWeaponCheck == -1)
			and ((ssi.nSprintFlag == 1) == bSprintFlag or ssi.nSprintFlag == -1)
			and ((ssi.nFollowController == 1) == bFollowController or ssi.nFollowController == -1)
			and (ssi.szTargetType == "" or (byte(ssi.szTargetType) == 33 and TARGET[ssi.szTargetType:sub(2)] ~= nTargetType) or TARGET[ssi.szTargetType] == nTargetType)
			and ((ssi.nFighting == 1) == bFighting or ssi.nFighting == -1)
			and ((ssi.nRunOnWater == 1) == bRunOnWater or ssi.nRunOnWater == -1)
			and ((ssi.nHangFlag == 1) == bHangFlag or ssi.nHangFlag == -1)
			and ((ssi.nOnTowerFlag == 1) == bOnTowerFlag or ssi.nOnTowerFlag == -1)
			and ((ssi.nIgnoreGravity == 1) == bIgnoreGravity or ssi.nIgnoreGravity == -1)
			and ((ssi.nBirdMove == 1) == bBirdMove or ssi.nBirdMove == -1)
			and (ssi.nFlyFlag == nFlyFlag or ssi.nFlyFlag == -1)
			and (ssi.szUISetting == "" or not GetDisplacementSkillSetting(ssi.szUISetting))
			and ((ssi.nParkourFlag == 1) == bParkourFlag or ssi.nParkourFlag == -1)
			and ((ssi.nIsHasValidTrack == 1) == bIsHasValidTrack or ssi.nIsHasValidTrack == -1)
			and CheckBuff(ssi.dwBuffID, ssi.nBuffLevel)
			and ((not ssi.aRepresentIDGroups) or (not tPlayerRIDs) or DoesInfoRIDsMatchPlayer(ssi.aRepresentIDGroups, tPlayerRIDs))
			and ((not ssi.aRepresentIDGroups) or (not tPlayerRIDs) or DoesInfoRIDsMatchPlayer(ssi.aRepresentIDGroups, tPlayerRIDs))
			and ((not ssi.aNotRepresentIDGroups) or (not tPlayerRIDs) or DoesInfoRIDsNotMatchPlayer(ssi.aNotRepresentIDGroups, tPlayerRIDs))
			and (ssi.nOTActionState < 0 or ssi.nOTActionState == nOTActionState)
			then
				if IsDebugClient() then
					Log("DisplacementHotkeys responsing: " .. ssi.szComment .. " nDoubleClick " .. ssi.nDoubleClick .. " szKey " .. ssi.szKey)
				end
				if ssi.bStopAction then
					bStopAction = true
				end
				nCount = nCount + 1
				if ssi.dwSkillID > 0 then
					if ssi.bContinual then
						if bDown then
							nKeepUsingSkillID = ssi.dwSkillID
							nKeepUsingSkillLevel = ssi.nSkillLevel
							BreatheCall("KEEP_USING_SKILL", 200, KeepUsingSkill)
						else
							BreatheCall("KEEP_USING_SKILL", false)
						end
					else
						local bCombination = ssi.szCombinationKeys and ssi.szCombinationKeys ~= ""
						local bCombinatonSuccess = true
						if bCombination then
							local szCombinationKeys = string.split(ssi.szCombinationKeys, '|')
							for i,v in pairs(szCombinationKeys) do
								if not _tKeyPressed[v] then
									bStopAction = false
									bCombinatonSuccess = false
									break
								end
							end
						end
						if not bCombination or (bCombination and bCombinatonSuccess) then
							_box.nSkillLevel = ssi.nSkillLevel
							if ssi.nFreeModeSkillID > 0 then
								OnUseSkill(ssi.nFreeModeSkillID, (ssi.nFreeModeSkillID * (ssi.nFreeModeSkillID % 10 + 1)), _box, bDown and ssi.bHoardSkill)
							else
								OnUseSkill(ssi.dwSkillID, (ssi.dwSkillID * (ssi.dwSkillID % 10 + 1)), _box, bDown and ssi.bHoardSkill)
							end
						end
					end
				end
			end
		end
	end
	return bStopAction, nCount
end

local m_tDirectionKeyState = setmetatable({}, {__index = function(k) return 0 end})
function ResponseWASDKey(szDirection, bDown, bDoubleClick)
	m_tDirectionKeyState[szDirection] = math.max(m_tDirectionKeyState[szDirection] + (bDown and 1 or -1), 0)

	-- DoubleDown
	-- if CanUseLeftRightSprint() then
	-- 	if szDirection == "TurnLeft" or szDirection == "StrafeLeft" then
	-- 		local dwSkillID = 6420
	-- 		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	-- 		return
	-- 	elseif szDirection == "TurnRight" or szDirection == "StrafeRight" then
	-- 		local dwSkillID = 6421
	-- 		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	-- 		return
	-- 	end
	-- end
	local retCode = false
	local me = GetClientPlayer()
	local bOnTowerFlag = me and me.bOnTowerFlag
	local szKey = szDirection:gsub("Turn", ""):gsub("Strafe", ""):upper()
	if ResponseDisplacementHotkey(szKey, bDown, bDoubleClick) then
		retCode = true
	end
	do -- apply current hanging direction
		--[[      0
		   7      y      1
		          |
		          |
		6 -----------------x 2
		          |
		   5      |      3

			      4
		]]
		local nX, nY = 0, 0
		if m_tDirectionKeyState.Forward > 0 then
			nY = nY + 1
		end
		if m_tDirectionKeyState.Backward > 0 then
			nY = nY - 1
		end
		if m_tDirectionKeyState.TurnLeft > 0
		or m_tDirectionKeyState.StrafeLeft > 0 then
			nX = nX - 1
		end
		if m_tDirectionKeyState.TurnRight > 0
		or m_tDirectionKeyState.StrafeRight > 0 then
			nX = nX + 1
		end
		local szKey = "MOVE_STOP"
		if     nX ==  0 and nY ==  0 then
			szKey = "MOVE_STOP"
		elseif nX ==  0 and nY ==  1 then
			szKey = "MOVE_FORWARD"
		elseif nX ==  1 and nY ==  1 then
			szKey = "MOVE_RIGHTFORWARD"
		elseif nX ==  1 and nY ==  0 then
			szKey = "MOVE_RIGHT"
		elseif nX ==  1 and nY == -1 then
			szKey = "MOVE_RIGHTBACKWARD"
		elseif nX ==  0 and nY == -1 then
			szKey = "MOVE_BACKWARD"
		elseif nX == -1 and nY == -1 then
			szKey = "MOVE_LEFTBACKWARD"
		elseif nX == -1 and nY ==  0 then
			szKey = "MOVE_LEFT"
		elseif nX == -1 and nY ==  1 then
			szKey = "MOVE_LEFTFORWARD"
		end
		if ResponseDisplacementHotkey(szKey, bDown, bDoubleClick) then
			retCode = true
		end
	end
	if bDown and ((bDoubleClick and GameSettingData.GetNewValue(UISettingKey.DoubleTapToSprint)) or bOnTowerFlag) and szDirection == "Forward" and not me.bBirdMove and not me.bHoldHorse then
		StartSprint()
	end
	return retCode
end

g_aDescToVKey = {[""] = 0 }
for index, value in pairs(g_aVKeyToDesc) do
	if value ~= "" then
		g_aDescToVKey[value] = index
	end
end

function GetKeyValue(szKey)
	return g_aDescToVKey[szKey]
end

function GetKeyName(nKey)
	if nKey == 0 then
		return ""
	end
	return g_aVKeyToDesc[nKey]
end

function IsSpaceKey(nKey)
	return nKey == 0x8
end

function IsShiftKey(nKey)
	return nKey == 0x10
end

function IsCtrlKey(nKey)
	return nKey == 0x11
end

function IsAltKey(nKey)
	return nKey == 0x12
end

function IsSpaceKeyDown()
	return Hotkey.IsKeyDown(0x8)
end

function IsShiftKeyDown()
	return Hotkey.IsKeyDown(0x10)
end

function IsCtrlKeyDown()
	return Hotkey.IsKeyDown(0x11)
end

function IsAltKeyDown()
	return Hotkey.IsKeyDown(0x12)
end

function IsKeyDown(szKey)
	local nValue = GetKeyValue(szKey)
	if nValue and nValue ~= 0 then
		return Hotkey.IsKeyDown(nValue)
	end
	return false
end


function GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort)
	if bShort then
		local szMKey = g_tHotKey.taVKeyToShowDescShort[nKey]
		if not szMKey or szMKey == "" then
			return ""
		end
		local szKey = ""
		if bCtrl then
			szKey = szKey..g_tHotKey.taVKeyToShowDescShort[0x11].."+"
		end
		if bAlt then
			szKey = szKey..g_tHotKey.taVKeyToShowDescShort[0x12].."+"
		end
		if bShift then
			szKey = szKey..g_tHotKey.taVKeyToShowDescShort[0x10].."+"
		end
		return szKey..szMKey
	end

	local szMKey = g_tHotKey.taVKeyToShowDesc[nKey]
	if not szMKey or szMKey == "" then
		return ""
	end
	local szKey = ""
	if bCtrl then
		szKey = szKey..g_tHotKey.taVKeyToShowDesc[0x11].."+"
	end
	if bAlt then
		szKey = szKey..g_tHotKey.taVKeyToShowDesc[0x12].."+"
	end
	if bShift then
		szKey = szKey..g_tHotKey.taVKeyToShowDesc[0x10].."+"
	end
	return szKey..szMKey
end

function sheild_hotkey( key, sheild ) -- deprecated; use 'shield_hotkey' instead
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(key)
	if nKey then
		Hotkey.ModifyShield(sheild, nKey, bShift, bCtrl, bAlt)
	end
end

shield_hotkey = sheild_hotkey

---------------------------------------------------------------------------------------
local bStart = false
local bInCarrier = false
local m_bEnableSprint = true
function Hotkey_EnableSprint(bEnable)
	m_bEnableSprint = bEnable
end

local function EnableControlByOperMode(nDirect, bStart)
	if GetOperationMode() == CLASSICAL_MODE then
		Camera_EnableControl(nDirect, bStart)
	else
		FreeMoveControl(nDirect, bStart)
	end
end

local function IsSprintEnabled()
	return m_bEnableSprint and not Camera_IsClientControlDisabled()
end

local m_bEnableMoveBack = true
function Hotkey_EnableMoveBack(bEnable)
	m_bEnableMoveBack = bEnable
end

function MoveForwardStart()
	local hPlayer = GetClientPlayer()
	if hPlayer then
		hPlayer.HoldW(1) -- 通知逻辑W键松开，轻功状态用~
	end
	if bInCarrier then
		local dwSkillID = 3799
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	else
		EnableControlByOperMode(CameraDef.CONTROL_FORWARD, true)
		if IsSprintEnabled() and IsKeyDoubleDown() then
			ResponseWASDKey("Forward", true, true)
		else
			ResponseWASDKey("Forward", true, false)
		end
	end
end

function MoveForwardStop()
	local hPlayer = GetClientPlayer()
	if hPlayer then
		hPlayer.HoldW(0) -- 通知逻辑W键松开
	end
	if not ResponseWASDKey("Forward", false, false) then
		CheckEndSprint()
	end
	EnableControlByOperMode(CameraDef.CONTROL_FORWARD, false)
end

function MoveBackwardStart()
	if not m_bEnableMoveBack then
		return
	end

	if bInCarrier then
		local dwSkillID = 3800
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	else
		if IsKeyDoubleDown() then
			if not ResponseWASDKey("Backward", true, true) then
				EnableControlByOperMode(CameraDef.CONTROL_BACKWARD, true)
			end
		else
			if not ResponseWASDKey("Backward", true, false) then
				EnableControlByOperMode(CameraDef.CONTROL_BACKWARD, true)
				CheckEndSprint()
			end
		end
	end
end

function MoveBackwardStop()
	if not ResponseWASDKey("Backward", false, false) then
	end
	EnableControlByOperMode(CameraDef.CONTROL_BACKWARD, false)
end

local m_bEnableTurnLeft = true
local m_bEnableTurnRight = true
function Hotkey_EnableTurnLeft(bEnable)
	m_bEnableTurnLeft = bEnable
end

function Hotkey_EnableTurnRight(bEnable)
	m_bEnableTurnRight = bEnable
end

function TurnLeftStart()
	if not m_bEnableTurnLeft then
		return
	end
	if IsKeyDoubleDown() then
		if not ResponseWASDKey("TurnLeft", true, true) then
			EnableControlByOperMode(CameraDef.CONTROL_TURN_LEFT, true)
		end
	else
		if not ResponseWASDKey("TurnLeft", true, false) then
			EnableControlByOperMode(CameraDef.CONTROL_TURN_LEFT, true)
		end
	end
end

function TurnLeftStop()
	if not ResponseWASDKey("TurnLeft", false, false) then
	end
	EnableControlByOperMode(CameraDef.CONTROL_TURN_LEFT, false)
end

function TurnRightStart()
	if not m_bEnableTurnRight then
		return
	end
	if IsKeyDoubleDown() then
		if not ResponseWASDKey("TurnRight", true, true) then
			EnableControlByOperMode(CameraDef.CONTROL_TURN_RIGHT, true)
		end
	else
		if not ResponseWASDKey("TurnRight", true, false) then
			EnableControlByOperMode(CameraDef.CONTROL_TURN_RIGHT, true)
		end
	end
end

function TurnRightStop()
	if not ResponseWASDKey("TurnRight", false, false) then
	end
	EnableControlByOperMode(CameraDef.CONTROL_TURN_RIGHT, false)
end

local function IsShieldStrafeOpt()
	local player = GetClientPlayer()
	if player and player.nMoveState == MOVE_STATE.ON_FLY_JUMP and not player.bSprintFlag and not player.bOnHorse then
		return true
	end
end

function StrafeLeftStart()
	if GetOperationMode() ~= CLASSICAL_MODE then
		if not Camera_IsInFreeView() then
			TurnLeftStart()
		end

		return
	end

	if bInCarrier then
		local dwSkillID = 3801
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	else
		if IsShieldStrafeOpt() then
			return
		end
		if IsKeyDoubleDown() then
			if not ResponseWASDKey("StrafeLeft", true, true) then
				Camera_EnableControl(CameraDef.CONTROL_STRAFE_LEFT, true)
			end
		else
			if not ResponseWASDKey("StrafeLeft", true, false) then
				Camera_EnableControl(CameraDef.CONTROL_STRAFE_LEFT, true)
			end
		end
	end
end

function StrafeLeftStop()
	if GetOperationMode() ~= CLASSICAL_MODE then
		if not Camera_IsInFreeView() then
			TurnLeftStop()
		end
		return
	end

	if IsShieldStrafeOpt() then
		return
	end

	if not ResponseWASDKey("StrafeLeft", false, false) then
	end
	Camera_EnableControl(CameraDef.CONTROL_STRAFE_LEFT, false)
end

function StrafeRightStart()
	if GetOperationMode() ~= CLASSICAL_MODE then
		if not Camera_IsInFreeView() then
			TurnRightStart()
		end
		return
	end

	if bInCarrier then
		local dwSkillID = 3802
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	else
		if IsShieldStrafeOpt() then
			return
		end
		if IsKeyDoubleDown() then
			if not ResponseWASDKey("StrafeRight", true, true) then
				Camera_EnableControl(CameraDef.CONTROL_STRAFE_RIGHT, true)
			end
		else
			if not ResponseWASDKey("StrafeRight", true, false) then
				Camera_EnableControl(CameraDef.CONTROL_STRAFE_RIGHT, true)
			end
		end
	end
end

function StrafeRightStop()
	if GetOperationMode() ~= CLASSICAL_MODE then
		if not Camera_IsInFreeView() then
			TurnRightStop()
		end
		return
	end

	if IsShieldStrafeOpt() then
		return
	end

	if not ResponseWASDKey("StrafeRight", false, false) then
	end
	Camera_EnableControl(CameraDef.CONTROL_STRAFE_RIGHT, false)
end

function MoveUpStart()
	Camera_EnableControl(CameraDef.CONTROL_UP, true)
end

function MoveUpStop()
	Camera_EnableControl(CameraDef.CONTROL_UP, false)
end

function MoveDownStart()
	Camera_EnableControl(CameraDef.CONTROL_DOWN, true)
end

function MoveDownStop()
	Camera_EnableControl(CameraDef.CONTROL_DOWN, false)
end

function Jump()
	Event.Dispatch(EventType.OnClientCastSkill, UI_SKILL_JUMP_ID)
	if bInCarrier then
		local dwSkillID = 3779
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	else
		local player = GetClientPlayer()
		if not player then
			return
		end

		local nMoveState = player.nMoveState
		local bOnHorse = player.bOnHorse
		local nFlyFlag = player.nFlyFlag
		local nMapType = MapHelper.GetBattleFieldType()

		if nMoveState == MOVE_STATE.ON_DEATH and CameraCommon.IsWatch() then
			CameraCommon.Match(true)
			return
		elseif nMoveState == MOVE_STATE.ON_DEATH and (BattleFieldData.IsInTreasureBattleFieldMap() or BattleFieldData.IsInMobaBattleFieldMap()) then
            BattleFieldData.Match(true)
			return
		elseif player.bBirdMove and player.nFlyFlag > 0 then
			ResponseDisplacementHotkey("SPACE", true, IsKeyDoubleDown()) --非起跳，用于空战镜头控制
		elseif player.bOnHorse then
			Event.Dispatch("ON_ONHORSE_JUMP")

			local itemH = player.GetEquippedHorse()
			m_tSpecialHorseOnJump = m_tSpecialHorseOnJump or Table_GetSpecialHorseOnJump()

			if itemH and m_tSpecialHorseOnJump[itemH.dwIndex] then
				if nFlyFlag == 0 and nMoveState == MOVE_STATE.ON_RUN then
				   local dwSkillID = 13951
					OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				elseif nFlyFlag == 0 and (nMoveState == MOVE_STATE.ON_STAND) then
					local dwSkillID = 13618
					OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				end

				if nFlyFlag ~= 1 then
					if nMoveState ~= MOVE_STATE.ON_JUMP then
						Camera_EnableControl(CameraDef.CONTROL_JUMP, true)
					end
				end

				return
			end

			if itemH and itemH.dwIndex == 13784 then
				if nFlyFlag == 0 and nMoveState == MOVE_STATE.ON_RUN then
				   local dwSkillID = 13951
					OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				end

				if nFlyFlag ~= 1 then
					if nMoveState ~= MOVE_STATE.ON_JUMP then
						Camera_EnableControl(CameraDef.CONTROL_JUMP, true)
					end
				end

				return
			end

			if itemH and itemH.dwIndex == 13148 then
				if nFlyFlag == 0 and (nMoveState == MOVE_STATE.ON_STAND or IsCharacterMoving(CameraDef.CONTROL_BACKWARD) or nMoveState == MOVE_STATE.ON_ENTRAP) then
					local dwSkillID = 13618
					OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				end
				return
			end

			if nFlyFlag == 0 and (nMoveState == MOVE_STATE.ON_STAND or nMoveState == MOVE_STATE.ON_FLOAT or IsCharacterMoving(CameraDef.CONTROL_BACKWARD)) then
				local dwSkillID = 13618
				OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
			else
				local dwSkillID = 44565
				OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				Camera_EnableControl(CameraDef.CONTROL_JUMP, true)
			end
		else
			--FireEvent("ON_PLAYER_JUMP")
			Event.Dispatch("ON_PLAYER_JUMP")

			local dwTargetType, dwTargetID = player.GetTarget()
			-- if dwTargetType == TARGET.NPC or
			-- (dwTargetType == TARGET.PLAYER and dwTargetID ~= player.dwID) or
			if (not ResponseDisplacementHotkey("SPACE", true, false)) --[[尝试释放轻功蓄能技 如果有蓄力技能则不起跳--]] then

				if (nMoveState == MOVE_STATE.ON_RUN
				or nMoveState == MOVE_STATE.ON_WALK
				or nMoveState == MOVE_STATE.ON_STAND)
				and IsCharacterMoving(CameraDef.CONTROL_BACKWARD) then
					Camera_LockControl(8)
					local dwSkillID = 9007
					OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
				else
					if not player.bSlideSprintFlag then
						Camera_EnableControl(CameraDef.CONTROL_JUMP, true)
					end
				end
			end
		end
	end
end

function RideHorse()
	local player = GetClientPlayer()
	if not player.GetEquippedHorse() and not player.IsFollower() then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.DIS_NOT_EQUIP_HORSE)
		return
	elseif player.GetSkillLevel(605) < 1 and not player.IsFollower() then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.DID_NOT_LEARN_RIDE)
		return
	end

	if player.bSprintFlag then
		local item = g_pClientPlayer.GetEquippedHorse()
		local tHorse1002 = GetTableFromSpecial(tSpecialHorse[item.dwIndex])
		if tHorse1002 and not tHorse1002.bSprint then
			TipsHelper.ShowNormalTip("当前坐骑不可使用轻功")
			return
		end
	end

	if player.bOnHorse or player.IsFollower() then
		local dwGroup = player.GetDynamicSkillGroup()
		if dwGroup > 0 then
			local dwSkillID = 54
			local tSkills = GetDynamicSkillGroupSkills(dwGroup)
			if not tSkills.CanCastSkill then
				dwSkillID = 9020
				if dwGroup == 526 then
					dwSkillID = 22023
				end
			end
			OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
		else
			local dwSkillID = 54
			OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
		end
	else
		local dwSkillID = 53
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	end
end

function DownHorse()
end

function EndJump()
	ResponseDisplacementHotkey("SPACE", false, false) -- 结束轻功蓄能技
	Camera_EnableControl(CameraDef.CONTROL_JUMP, false)
end

function MoveAction_StopAll()
	MoveForwardStop()
	MoveBackwardStop()
	TurnLeftStop()
	TurnRightStop()
	StrafeLeftStop()
	StrafeRightStop()
	EndJump()
	StopAutoRun()
end

function AutoInteract()
	AutoSearch_Interact()
end

function ToggleAutoRun()
	Camera_ToggleControl(CameraDef.CONTROL_AUTO_RUN)
end

function StopAutoRun()
	Camera_EnableControl(CameraDef.CONTROL_AUTO_RUN, false)
end

local m_bEnableToggleSheath = true
function Hotkey_EnableToggleSheath(bEnable)
	m_bEnableToggleSheath = bEnable
end

function ToggleSheath()
	local player = GetClientPlayer()
	local nMoveState = player.nMoveState

	if nMoveState == MOVE_STATE.ON_SIT
	or nMoveState == MOVE_STATE.ON_DEATH
	or player.bFightState
	or player.bBirdMove
	or player.bHoldHorse
	or player.bOnTowerFlag
	or Player_IsBuffExist(10951, player, 1) then
		return false
	end

	if not m_bEnableToggleSheath then
		return false
	end

	if player.bSheathFlag then
		player.SetSheath(0)
	else
		player.SetSheath(1)
	end

	if GetPlayerWeaponType(player) == WEAPON_DETAIL.HEPTA_CHORD then
		rlcmd("force update sheath " .. player.dwID .. " 0")
	end
	return true
end

function ToggleSitDown()
	local player=GetClientPlayer()
	if player.nMoveState == MOVE_STATE.ON_SIT then
		player.Stand()
	else
		local dwSkillID = 17 --打坐技能
		OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
	end
end

function CameraSetView(fAngle)
	CameraMgr.Status_Set({
		mode    = "local camera",
		scale   = 1,
		yaw     = (2 * math.pi - (GetClientPlayer().nFaceDirection / 255 * math.pi * 2 + math.pi / 2)) + fAngle / 180 * math.pi,
		pitch   = -0.2,
		tick    = 700,
	})
	-- Camera_SetView(fAngle)
end

local m_bEnableToggleRun = true
function Hotkey_EnableToggleRun(bEnable)
	m_bEnableToggleRun = bEnable
end

function ToggleRun()
	local pPlayer = GetClientPlayer()
	if pPlayer and pPlayer.bHoldHorse then --当玩家在牵马状态的时候，不能切换走/跑
		return
	end

	if not m_bEnableToggleRun then
		return
	end
	Camera_ToggleControl(CameraDef.CONTROL_WALK)

end

function ActionButtonDown(nGroupID, nButtonID)
	ActionBar_ButtonDown(nGroupID, nButtonID)
end

function ActionButtonUp(nGroupID, nButtonID)
	ActionBar_ButtonUp(nGroupID, nButtonID)
end

function ChangeActionBarPage(nPage)
	SelectMainActionBarPage(nPage)
end

function ActionBar_PageDown()
	SelectMainActionBarPage(GetMainActionBarPage() + 1)
end

function ActionBar_PageUp()
	SelectMainActionBarPage(GetMainActionBarPage() - 1)
end

function LockOrUnlockActionBar()
	if IsActionBarLocked() then
		LockActionBar(false)
	else
		LockActionBar(true)
	end
end

local m_bForbidSelectPlayer
function SetForbidSelectPlayer(bForbid)
 	m_bForbidSelectPlayer = bForbid
end

function SelectPlayer()
	if m_bForbidSelectPlayer then
		return 1
	end
	local hPlayer = GetClientPlayer()
	local nMapType = MapHelper.GetBattleFieldType()
	if (nMapType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE or nMapType == BATTLEFIELD_MAP_TYPE.MOBABATTLE) and (hPlayer and hPlayer.nMoveState == MOVE_STATE.ON_DEATH) then --沙漠风暴战场玩家观战处理
		return 1
	end
	if OBDungeonData.IsPlayerInOBDungeon() then
		return 1
	end
	SelectSelf()
end

function TogglePanel(szFrame)
	-- if StoryDisplay.IsPlaying() then
	-- 	StoryDisplay.ExitPlay()
	-- 	return
	-- end

	-- if IsUIMovieOpened() then
	-- 	if UIMovie.OnResopneEsc() then
	-- 		return
	-- 	end
	-- end

	if szFrame == "OPTION" then				--系统菜单
		if IsModuleLoaded("StoryDisplay") and StoryDisplay.IsPlaying() then
			StoryDisplay.ExitPlay()
			return
		end

		if UIMovie and IsUIMovieOpened() then
			if UIMovie.OnResopneEsc() then
				return
			end
		end

		--注意：用户按ESC的时候可能还要做其它事情，比如，取消技能等.
		if IsModuleLoaded("Teaching") and Teaching.IsOpened() then
			Teaching.Close()
			return
		end

		if IsModuleLoaded("ScreenShotPanel") and ScreenShotPanel.IsShoting() then
			ScreenShotPanel.End(true)
			return
		end

		if IrrigatePanel and IrrigatePanel.frameSelf and IrrigatePanel.frameSelf:IsVisible() then
			IrrigatePanel.ClosePanel()
			return
		end
		------------退出自拍界面------------------------
		if IsModuleLoaded("Selfie") and Selfie.IsOpened() then
			Selfie.Close()
			return
		end

		------------退出家园建造界面------------------------
		if IsModuleLoaded("HLBView_Main") and HLBView_Main.IsOpened() then
			HLBView_Main.ConfirmQuit()
			return
		end

		if IsModuleLoaded("CoinShop") and CoinShop_Cutscene.IsOpened() then
			return
		end

		if IsModuleLoaded("CoinShop") and CoinShop_Main.IsHaveOperate() then
			CoinShop_Main.Operate()
			return
		end

		--------------退出英雄助战界面--------------------
		if IsModuleLoaded("Partner") and Partner.IsHaveOperate() then
			Partner.Operate()
			return
		end

		------------退出奇遇NPC对话界面------------------
		if IsModuleLoaded("LuckyMeetingDialogue") and LuckyMeetingDialogue.IsOpened() then
			LuckyMeetingDialogue.Close(true)
			return
		end

		-------------取消MessageBox--------------
		if CloseLastMessageBox() then
			return
		end

		------------退出直播界面------------------------
		if IsModuleLoaded("PVPShowPanel") and PVPShowPanel.IsOpened() then
			ExecuteWithThis(PVPShowPanel.IsOpened(), "OnFrameKeyDown")
			return
		end
		if IsModuleLoaded("PVPShowFinal") and PVPShowFinal.IsOpened() then
			PVPShowFinal.Close()
			return
		end

		if IsModuleLoaded("DesertStormOB") and DesertStormOB.IsOpened() then
			ExecuteWithThis(DesertStormOB.IsOpened(), "OnFrameKeyDown")
			return
		end

		-- if IsVideoSettingPanelOpened() then
		-- 	CloseVideoSettingPanel()
		-- 	return
		-- end

		if IsModuleLoaded("BattleFieldAndArenaBase") and (IsBattleFieldOpen() or IsArenaFinalOpen()) then --战场和JJC结算流程所有的界面
			return
		end

		if IsModuleLoaded("ACC_TreasureFinal") and ACC_TreasureFinal.IsOpened() then
			return
		end

		for _, ac in ipairs_r(lc_aIndePentShow) do
			if ac.fnCondition and ac.fnCondition() then
				if ac.fnEscAction then
					ac.fnEscAction()
					return
				end
			end
		end

		---------------退出幻化状态---------------------
		local player = GetClientPlayer()
		if player and player.IsInMorph() then
			Partner_EndMorph()
			return
		end

		------------取消隐藏界面------------------------
		if not Station.IsVisible() then
			if IsChaptersOpen() then
				return
			end

			if FilterMask and FilterMask.bHideUI then
				return
			end
			Station.Show()
			return
		end

		-----------关闭弹出菜单---------------
		if IsPopupMenuOpened() then
			ClosePopupMenu()
		end


		-----------关闭退出游戏确认面板---------------
		if IsExitPanelOpened() then
			CloseExitPanel()
			return
		end

		-------------关闭帮会重命名面板------------------
		if IsGuildRenameOpened() then
			CloseGuildRename()
			return
		end

		--------------关闭奖励通用面板-----------------
		if IsItemBoxOpened() then
			CloseItemBox()
			return
		end

		-----------关闭世界地图，以及相关---------------
		if IsTrafficSurepanelOpened() then
			CloseTrafficSurepanel()
			return
		end

		if IsWorldMapOpend() then
			CloseWorldMap()
			return
		end

		-----------关闭召唤面板------------------
		if IsCallFriendPannelOpened() then
			CloseCallFriendPannel()
			return
		end

		if IsCallGuildMemberPannelOpened() then
			CloseCallGuildMemberPannel()
			return
		end

		------------关闭中地图,以及相关------------------
		if IsEditMiddleMapFlagOpened()  then
			CloseEditMiddleMapFlag()
			return
		end

		if IsMiddleMapOpened() then
			CloseMiddleMap()
			return
		end

		if IsUICustomModePanelOpened() then
			CloseUICustomModePanel()
			return
		end


		if IsOpenEmotionManagePanel() then
			CloseEmotionManagePanel()
			return
		end

		if IsOpenEmotionPanel() then
			CloseEmotionPanel()
			return
		end

		----------取消手上的物品和其他鼠标状态----------------
		if not Hand_IsEmpty() then
			Hand_Clear()
			return
		end

		for _, ac in ipairs_r(lc_aAutoCloseTopmost) do
			if ac.fnCondition and ac.fnCondition() then
				ac.fnAction()
				return
			end
		end

		-------------取消输入数字,和输入名字的面板----------
		local bProcessed = false
		if CloseGetNamePanel() then
			bProcessed = true
		end
		if CloseGetNumberPanel() then
			bProcessed = true
		end
		if CloseGetPricePanel() then
			bProcessed = true
		end
		if bProcessed then
			return
		end

		-------------关闭副本提示面板------------
		--[[
		-------------关闭经脉面板--------------
		if IsChannelsPanelOpened() then
			CloseChannelsPanel()
			return
		end
		--]]
		--------------盘扎寨界面--------------------
		if PanzhazhaiPanel.IsOpened() then
			PanzhazhaiPanel.Close()
			return
		end

		--------------IE面板--------------------
		if IsModuleLoaded("InternetExplorer") and InternetExplorer.CloseLast() then
			return
		end

		--------------Esc菜单上的面板------------
		if CloseOptionAndOptionChildPanel() then
			return
		end

		-------------历程界面----------------------------
		if IsCouresOpened() and CanCloseCouresPanel() then
			CloseCoures()
			return
		end

		-------------问卷界面----------------------------
		if IsQuestionnairePanelOpened() then
			CloseQuestionnairePanel()
			return
		end

		---------------江湖指南---------------------------
		if IsModuleLoaded("Cyclopaedia") and Cyclopaedia.IsOpened() then
			Cyclopaedia.Close()
			return
		end

		-----------------活动日历---------------------------
		if IsModuleLoaded("ActivityList") and ActivityList.IsOpened() then
			ActivityList.Close()
			return
		end

		-----------------装备大全---------------------------
		if IsModuleLoaded("EquipInquire") and EquipInquire.IsOpened() then
			EquipInquire.Close()
			return
		end

		-----------------帮会擂台------------------------
		if IsTongArenaOpened() then
			CloseTongArena()
			return
		end

		--------------GM面板--------------------
		if IsGMPanelOpened() then
			CloseGMPanel()
			return
		end

		--------------科举面板--------------------
		if ExaminationPanel.IsOpened() then
			ExaminationPanel:ClosePanel()
			return
		end


		if IsFishPanelOpened() then
			CloseFishPanel()
			return
		end

		if IsTongFarmPanelOpened() then
			CloseTongFarmPanel()
			return
		end

		if IsPayPathPanelOpened() then
			ClosePayPathPanel()
			return
		end

		if IsGuildListPanelOpened() then
			CloseGuildListPanel()
			return
		end

		if IsGuildMainPanelOpened() then
			CloseGuildMainPanel()
			return
		end

		------------关闭所有ItemLink--------------------
		bProcessed = false
		if CloseLinkTipPanel() then
			bProcessed = true
		end

		if CloseAllAchievementTip() then
			bProcessed = true
		end
		if bProcessed then
			return
		end

		------------关闭拾取面板----------------
		if IsLootListOpened() then
			CloseLootList()
			return
		end

		if IsGoldTeamLootListOpened() then
			CloseGoldTeamLootList(false, true)
		end

		if IsManualDropListPanelOpened() then
			CloseManualDropListPanel()
			return
		end

		if IsModuleLoaded("BattleFieldAndArenaBase") and IsBattleFieldOpen() then
			CloseBattleFieldFinal()
			return
		end

		if IsTwoDungeonRewardOpened() then
			CloseTwoDungeonReward()
			return
		end

		if IsRandomRewardPanelOpened() then
			CloseRandomRewardPanel()
			return true
		end

		--------------二级菜单上的面板----------
		local bProcessed = false
		if CorrectAutoPosFrameEscClose() then
			bProcessed = true
		end

		-------------背包---------------------
		if not IsAllBagPanelClosed() then
			CloseAllBagPanel()
			bProcessed = true
		end

		if HomelandLocker.IsOpened() then
			HomelandLocker.Close()
			bProcessed = true
		end
		-------------商店---------------------
		if IsShopOpened() then
			CloseShop()
			bProcessed = true
		end
		if bProcessed then
			return
		end

		if NewBattleFieldQueue.IsOpened() then
			NewBattleFieldQueue.Close()
		end

		----------取消玩家正释放的技能等其他行为--------
		local me = GetClientPlayer()
		if me.StopCurrentAction() then
			return
		end

		if IsCursorInExclusiveMode() then
			Cursor.Switch(CURSOR.NORMAL)
			return
		end

		----------W没有按下时取消玩家爬墙轻功--------
		if m_tDirectionKeyState.Forward == 0 -- W键没有按下
		-- and not me.bIgnoreGravity -- 这个标记在爬墙时为true
		and CheckEndSprint(true) then -- 退出轻功成功
			return
		end
		--------------取消target-----------------
		if IsTargetPanelOpened() then
			CloseTargetPanel()
			return
		end


		if IsWeaponBagOpen() and not CharacterPanel_IsCharacterOpen() then
			CloseWeaponBag()
			return
		end

		for _, ac in ipairs_r(lc_aAutoClose) do
			if ac.bIsParamNeeded then
				if ac.fnCondition and ac.fnCondition(ac.szKey) then
					ac.fnAction(ac.szKey)
					return
				end
			else
				if ac.fnCondition and ac.fnCondition() then
					ac.fnAction()
					return
				end
			end
		end

		----------打开Esc面板-----------
		OpenOptionPanel()
	elseif szFrame == "GM" then
		if IsGMPanelOpened() then
			CloseGMPanel()
		else
			OpenGMPanel("GMCenter")
		end
	elseif szFrame == "EQUIP" then  		--装备
		if IsCharacterPanelOpened() then
			CloseCharacterPanel()
		else
			OpenCharacterPanel()
		end
	elseif szFrame == "FRIEND" then		--好友
		SocialPanel.Toggle()
	elseif szFrame == "GUILD" then --帮会
		if IsGuildMainPanelOpened() then
			CloseGuildMainPanel()
		else
			OpenGuildMainPanel()
		end
	elseif szFrame == "PRODUCT" then
		if CastingPanel.IsOpened() then
			CastingPanel.Close()
		else
			CastingPanel.Open()
		end
	elseif szFrame == "QUEST" then		--任务
		if IsQuestPanelOpened() then
			CloseQuestPanel()
		else
			OpenQuestPanel()
		end
	elseif szFrame == "SKILL" then		--技能
		if IsNewSkillPanelOpened() then
			CloseNewSkillPanel()
		else
			OpenNewSkillPanel()
		end
		--[[
	elseif szFrame == "CHANNEL" then --经脉
		if IsChannelsPanelOpened() then
			CloseChannelsPanel()
		else
			OpenChannelsPanel()
		end
		--]]
	elseif szFrame == "HOMELAND" then	--家园
		if DaTangJiaYuan.IsOpened() then
			DaTangJiaYuan.Close()
		else
			DaTangJiaYuan.Open()
		end
	elseif szFrame == "CRAFT" then		--生活技能
		if IsCraftPanelOpened() then
			CloseCraftPanel()
		else
			OpenCraftPanel()
		end
	elseif szFrame == "STUDY" then		--阅读
		if IsCraftReadManagePanelOpened() then
			CloseCraftReadManagePanel()
		else
			OpenCraftReadManagePanel()
		end
	elseif szFrame == "UI_CUSTOM_MODE" then
		if IsUICustomModePanelOpened() then
			CloseUICustomModePanel()
		else
			OpenUICustomModePanel()
		end
	elseif szFrame == "FOUNDRY" then
	elseif szFrame == "FPS" then 	--FPS
		Wnd.ToggleWindow("FPS")
	elseif szFrame == "DEBUG" then
		Wnd.ToggleWindow("Debug")
		Wnd.ToggleWindow("DebugNpcPortrait")
	elseif szFrame == "SCENE" then
		SceneMain_ToggleVisible()
	elseif szFrame == "SCENE_MINI" then
		--Wnd.ToggleWindow("SceneMini")
	elseif szFrame == "ACHIEVEMENT" then
		if AchievementPanel.IsOpened() then
			AchievementPanel.Close()
		else
			AchievementPanel.Open()
		end
	elseif szFrame == "MENTOR" then
		if IsMentorPanelOpened() then
			CloseMentorPanel()
		else
			OpenMentorPanel()
		end
		--[[
	elseif szFrame == "PARTY_RECRUIT" then
		if IsPartyRecruitPanelOpened() then
			ClosePartyRecruitPanel()
		else
			OpenPartyRecruitPanel()
		end
		]]
		--[[
	elseif szFrame == "TALENT" then
		if IsZhenPaiSkillOpened() then
			CloseZhenPaiSkill()
		else
			OpenZhenPaiSkill()
		end
		--]]
	elseif szFrame == "ARENA_PANEL" then
		if IsModuleLoaded("ArenaCorpsPanel") and ArenaCorpsPanel.IsOpened() then
			ArenaCorpsPanel.Close()
		else
			ArenaCorpsPanel.Open()
		end
	elseif szFrame == "TOGGLE_CAMPMAP_PANEL" then
		if CampMaps.IsOpened() then
			CampMaps.Close()
		else
			CampMaps.Open()
		end
	elseif szFrame == "EXTERIOR_PANEL" then
		CoinShop_Main.Toggle(EXTERIOR_OPEN_SOURCE.HOTKEY, "Home")
	elseif szFrame == "FELLOWPET" then
		if NewPet.IsOpened() then
			NewPet.Close()
		else
			NewPet.Open()
		end
	elseif szFrame == "LANDSCAPE" then
		if FeatureSpotPanel.IsOpened() then
			FeatureSpotPanel.Close()
		else
			FeatureSpotPanel.Open()
		end
	elseif szFrame == "TEAMBUILD" then
		if TeamBuilding.IsOpened() then
			TeamBuilding.Close()
		else
			TeamBuilding.Open()
		end
	elseif szFrame == "HORSE" then
		if HorsePanel.IsOpened() then
			HorsePanel.Close()
		else
			HorsePanel.Open()
		end
	elseif szFrame == "ADVENTURE" then
		if LuckyMeeting.IsOpened() then
			LuckyMeeting.Close()
		else
			LuckyMeeting.Open()
		end
	elseif szFrame == "SELFIE" then
		if IsModuleLoaded("Selfie") and Selfie.IsOpened() then
			Selfie.Close()
		elseif not (
			(IsModuleLoaded("DesertStormOB") and DesertStormOB.IsOpened()) or
			(IsModuleLoaded("PVPShowPanel") and PVPShowPanel.IsOpened()) or
			(IsModuleLoaded("PVPShowFinal") and PVPShowFinal.IsOpened()) or
			--IsVideoSettingPanelOpened() or
			(IsModuleLoaded("BattleFieldAndArenaBase") and (IsBattleFieldOpen() or IsArenaFinalOpen())) or
			(IsModuleLoaded("ACC_TreasureFinal") and ACC_TreasureFinal.IsOpened())) then
			for _, ac in ipairs_r(lc_aIndePentShow) do
				if ac.fnCondition and ac.fnCondition() then
					return
				end
			end
			Selfie.Open()
		end
	elseif szFrame == "SNS" then
		SnsPanel.Toggle()
	elseif szFrame == "CYCLOPAEDIA" then
		Cyclopaedia.Toggle()
	elseif szFrame == "PAY" then
		OpenInternetExplorer(tUrl.Recharge, true)
	elseif szFrame == "CALENDAR" then
		if not ActivityList.IsOpened() then
			ActivityList.Open()
		else
			ActivityList.Close()
		end
	elseif szFrame == "COINCHANGE" then
		if IsPayPathPanelOpened() then
			ClosePayPathPanel()
		else
			OpenPayPathPanel()
		end
	elseif szFrame == "FB" then
		if FBlist.IsOpened() then
			FBlist.Close()
		else
			FBlist.Open()
		end
	elseif szFrame == "SHOWEQUIP" then
		if EquipInquire.IsOpened() then
			EquipInquire.Close()
		else
			EquipInquire.Open()
		end
	elseif szFrame == "RANK" then
		if IsRankingPanelOpened() then
			CloseRankingPanel()
		else
			OpenRankingPanel()
		end
	elseif szFrame == "REPUTATION" then
		if ReputationPanel.IsWindowOpen() then
			ReputationPanel.CloseWindow()
		else
			ReputationPanel.OpenWindow()
		end
	elseif szFrame == "DLC" then
		if DLCPanel.IsOpened() then
			DLCPanel.Close()
		else
			DLCPanel.Open()
		end
	elseif szFrame == "WANTED" then
		if IsWantedPanelOpened() then
			CloseWantedPanel()
		else
			OpenWantedPanel()
		end
	elseif szFrame == "COMPASS" then
		if CompassPanel.IsOpened() then
			CompassPanel.ClosePanel()
		else
			CompassPanel.OpenPanel()
		end
	elseif szFrame == "DOMESTICATE" then
		if DomesticatePanel.IsOpened() then
			DomesticatePanel.Close()
		else
			DomesticatePanel.Open()
		end
	elseif szFrame == "COINSHOP_OUTFIT" then
		if not CoinShop_Main.IsOpened() then
			CoinShop_Outfit.Toggle(true, false)
		end
	elseif szFrame == "RECHARGE" then
		OpenInternetExplorer(tUrl.Recharge, true)
	elseif szFrame == "IDENTITY" then
		if IdentityPanel.IsOpened() then
			IdentityPanel.Close()
		else
			IdentityPanel.Open()
		end
	elseif szFrame == "DESERTSTORM" then
		if DesertStormInfoPanel.IsOpened() then
			DesertStormInfoPanel.Close()
		else
			DesertStormInfoPanel.Open()
		end
	elseif szFrame == "VAMPIRECOUNTPANEL" then
		if VampireCountPanel.IsOpened() then
			VampireCountPanel.Close()
		else
			VampireCountPanel.Open()
		end
	elseif szFrame == "PARTNER" then
		if Partner.IsOpened() then
			Partner.Close()
		else
			Partner.Open()
		end
	elseif szFrame == "SWITCH_SERVER" then
		if SwitchServerDLC.IsOpened() then
			SwitchServerDLC.Close()
		else
			SwitchServerDLC.Open()
		end
	end
end

function ToggleBag(nBagID)
	if IsBagPanelOpened(nBagID) then
		CloseBagPanel(nBagID)
	else
		OpenBagPanel(nBagID)
	end
end

function OpenOrCloseAllBags()
	if IsAllBagPanelOpened() then
		CloseAllBagPanel()
	else
		OpenAllBagPanel()
	end
end

function ToggleToyBox()
	if ToyBox.IsOpened() then
		ToyBox.Close()
	else
		ToyBox.Open()
	end
end

function TakeScreenshot()
	if SM_IsEnable() then
		return
	end
	local szFilePath = ScreenShot(SCREENSHOT_SUFFIX, SCREENSHOT_QUALITY)
	if szFilePath then
		OutputMessage("MSG_ANNOUNCE_NORMAL",g_tStrings.SCREENSHOT)

		local szScreenshot = g_tStrings.SCREENSHOT_MSG .. szFilePath .. "\n"
		OutputMessage("MSG_SYS", szScreenshot)
	end
end

function NextView()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:NextView()\n")
	--TODO:
end

function PrevView()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:PrevView()\n")
	--TODO:
end

local _enableZoom = true
function EnableCameraZoom(enable)
	_enableZoom = enable
end

function IsCameraZoomEnabled()
	return _enableZoom
end


function CameraZoomIn()
	if _enableZoom then
		Camera_Zoom(0.9)
	end
end

function CameraZoomOut()
	if _enableZoom then
		Camera_Zoom(1.1)
	end
end

function MoveViewInStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewInStart()\n")
	--TODO:
end

function MoveViewInStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewInStop()\n")
	--TODO:
end

function MoveViewOutStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewOutStart()\n")
	--TODO:
end

function MoveViewOutStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewOutStop()\n")
	--TODO:
end

function MoveViewLeftStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewLeftStart()\n")
	--TODO:
end

function MoveViewLeftStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewLeftStop()\n")
	--TODO:
end

function MoveViewRightStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewRightStart()\n")
	--TODO:
end

function MoveViewRightStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewRightStop()\n")
	--TODO:
end

function MoveViewUpStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewUpStart()\n")
	--TODO:
end

function MoveViewUpStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewUpStop()\n")
	--TODO:
end

function MoveViewDownStart()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewDownStart()\n")
	--TODO:
end

function MoveViewDownStop()
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:MoveViewDownStop()\n")
	--TODO:
end

function SetView(nViewIndex)
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:SetView()\n")
	--TODO:
end

function SaveView(nViewIndex)
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:SaveView()\n")
	--TODO:
end

function ResetView(nViewIndex)
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:ResetView()\n")
	--TODO:
end

function FlipCameraYaw(nAngle)
	OutputMessage("MSG_ANNOUNCE_NORMAL","TODO:FlipCameraYaw()\n")
	--TODO:
end

function CameraOrSelectOrMoveStart(stickyFlag)
	Ctrl_CameraOrSelectOrMoveStart(stickyFlag)
end

function CameraOrSelectOrMoveStop(stickyFlag)
	Ctrl_CameraOrSelectOrMoveStop(stickyFlag)
end

function CameraReset()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local nCameraYaw = pPlayer.nFaceDirection - 64
    if nCameraYaw < 0 then
        nCameraYaw = nCameraYaw + 256
    end
    nCameraYaw = ((256 - nCameraYaw) / 256) * math.pi * 2
	Camera_SetForceReset(nCameraYaw, math.pi / -12, 1)
end

function TakeKinescope()
	if SM_IsEnable() then
		return
	end
	if IsMovieRecord() then
		FinishMovieRecord()
	else
		local nWidth, nHeight = Station.GetClientSize()
		local tMsg =
		{
			x = nWidth / 2, y = nHeight / 2,
			bVisibleWhenHideUI = true, --在隐藏UI的模式下仍然显示。
			szMessage = g_tStrings.MSG_SLOWER_AFTER_OPEN_MOVIE,
			szName = "IsOpenMovie",
			szAlignment = "CENTER",
			{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() StartMovieRecord() end},
			{szOption = g_tStrings.STR_HOTKEY_CANCEL, fnAction = function() end}
		}
		MessageBox(tMsg)
	end
end

function OnCaptureHotkey()
	local nKey, bShift, bCtrl, bAlt = Hotkey.GetCaptureKey()
	HotkeyPanel_SetHotkey(nKey, bShift, bCtrl, bAlt)
end

function OnCancelHotkeySetting()
	HotkeyPanel_CancelSetHotkey()
end

function ToggleUI()
	if IsUILockedMode() then
		return
	end

	if IsModuleLoaded("CoinShop") and CoinShop_Main and CoinShop_Main.IsOpened() then
		local bShow = CoinShop_IsModuleFrameShow()
		CoinShop_ModuleFrameShow(not bShow)
		return
	end

	if IsModuleLoaded("HLBView_Main") and HLBView_Main.IsOpened() then
		local hFrame = HLBView_Main.ToggleShow()
		return
	end

	if Station.IsVisible() then
		Station.Hide()
	else
		if FilterMask and FilterMask.bHideUI then
			return
		end
		if IsModuleLoaded("PVPShowPanel") and PVPShowPanel.IsOpened() then
			return
		end
		if IsModuleLoaded("PVPShowFinal") and PVPShowFinal.IsOpened() then
			return
		end
		if IsModuleLoaded("DesertStormOB") and DesertStormOB.IsOpened() then
			return
		end
		if VideoSettingPanel and IsVideoSettingPanelOpened() then
			return
		end
		if IsModuleLoaded("BattleFieldAndArenaBase") and (IsBattleFieldOpen() or IsArenaFinalOpen()) then
			return
		end
		if IsModuleLoaded("ACC_TreasureFinal") and ACC_TreasureFinal.IsOpened() then
			return
		end
		for _, ac in ipairs_r(lc_aIndePentShow) do
			if ac.fnCondition and ac.fnCondition() then
				return
			end
		end
		Station.Show()
	end
end

--控制中地图
function ToggleMiddleMap()
	if IsWorldMapOpend() then
		CloseWorldMap()
	elseif IsMiddleMapOpened() then
		CloseMiddleMap()
	else
		OpenMiddleMap()
	end
end

function ToggleWorldMap()
	if IsWorldMapOpend() then
		CloseWorldMap()
	else
		if IsMiddleMapOpened() then
			CloseMiddleMap(true)
		end
		OpenWorldMap()
	end
end

function OpenChatEditBox()
	OpenEditBox()
end

function AttackTarget()
	CastCommonSkill(true)
end

function ShortCutReply()
	local szName = EditBox.GetLastReply()
	if szName then
		EditBox_TalkToSomebody(szName)
	end
end

function FollowTarget(dwType, dwTargetID)
	local player = GetClientPlayer()
	if player then
		if not dwType or not dwTargetID then
			dwType, dwTargetID = player.GetTarget()
		end

		if MapHelper.IsRemotePvpMap() and dwType == TARGET.PLAYER then
			TipsHelper.ShowImportantRedTip("当前区域内无法跟随玩家")
			return -- 跨服PVP场景 可以跟随NPC 不能跟随玩家
		end

		if dwType == TARGET.NPC then
			local KNpc = GetNpc(dwTargetID)
			if KNpc and KNpc.dwEmployer ~= 0 then
				return -- 不能跟随玩家的宠物、侠客等玩家相关的NPC
			end
		end
		SprintData.SetAutoForward(false)
		StartFollow(dwType, dwTargetID)
		if not DungeonData.IsInDungeon() then
			AutoBattle.Stop()
		end
	end
end

function EquipKongfu(dwID)
	--[[
	local player = GetClientPlayer()
	if player then
		local dwLevel = player.GetSkillLevel(dwID)
		if dwLevel and dwLevel > 0 then
			player.MountKungfu(dwID, dwLevel, true)
		end
	end
	]]
	RemoteCallToServer("On_MountKungfu_1", dwID)
end

function CastSkillByKeyDown(szType)
	local dwID = 0;
	if szType == "SKILL_CAST_FORWARD" then
		dwID = 9003
	elseif szType == "SKILL_CAST_BACK" then
		dwID = 9004
	elseif szType == "SKILL_CAST_LEFT" then
		dwID = 9005
	elseif szType == "SKILL_CAST_RIGHT" then
		dwID = 9006
	end

	local player = GetClientPlayer()
	if player then
		local dwLevel = player.GetSkillLevel(dwID)
		if dwLevel and dwLevel > 0 then
			OnUseSkill(dwID, (dwID * (dwID % 10 + 1)))
		end
	end
end

function ToggleNpc(bShow)
	local bShowing = RLEnv.GetLowerVisibleCtrl().bShowNpc
	if bShow ~= nil and (bShow == false) == bShowing then
		return
	end
	Event.Dispatch("OnNpcDisplayChanged")
	GameSettingData.ApplyNewValue(UISettingKey.ShowHideNPC, not bShowing)
end

-- _g_HidePlayerType = false  --- 是否隐藏了除自己外的所有玩家
-- function TogglePlayer(bShow, bIgnoreOptimization)
-- 	if bShow ~= nil and (bShow == false) == _g_HidePlayerType then
-- 		return
-- 	end
-- 	if _g_HidePlayerType then
-- 		rlcmd("show player")
-- 		_g_HidePlayerType = false
-- 		if not bIgnoreOptimization then
-- 			RemoteCallToServer("OnSetOptimizationNetworkFlag", 0)
-- 		end
-- 		--FireUIEvent('TOGGLE_PLAYER', true)
-- 	else
-- 		rlcmd("hide player")
-- 		_g_HidePlayerType = true
-- 		if not bIgnoreOptimization then
-- 			RemoteCallToServer("OnSetOptimizationNetworkFlag", 1)
-- 		end

-- 		--FireUIEvent('TOGGLE_PLAYER', false)
-- 	end
-- end

-- local _RELATION_PLAYER_TYPE =
-- {
-- 	FOE = 1,
-- 	ENEMY = 2,
-- 	NEUTRALITY = 3,
-- 	PARTY = 4,  --- 将要废弃，以后用 rlcmd("show or hide party player 1") 来隐藏队友
-- 	ALLY = 5,
-- 	SELF = 6,
-- 	NONE = 7,
-- 	ALL = 8,
-- }

-- _g_HidePartyPlayerType = true -- 是否隐藏队友
-- --not StorageServer.GetData("UISetting_BoolValues2", "SHOW_PARTY_PLAYER_TYPE")
-- function TogglePartyPlayer(bShow)
-- 	if bShow ~= nil and (bShow == false) == _g_HidePartyPlayerType then
-- 		return
-- 	end
-- 	if _g_HidePartyPlayerType then
-- 		rlcmd("show or hide party player 1")
-- 		rlcmd("show relation player " .. _RELATION_PLAYER_TYPE["PARTY"])
-- 		_g_HidePartyPlayerType = false
-- 		FireUIEvent('TOGGLE_PARTY', true)
-- 		--StorageServer.SetData("UISetting_BoolValues2", "SHOW_PARTY_PLAYER_TYPE", true)
-- 	else
-- 		rlcmd("show or hide party player 0")
-- 		rlcmd("hide relation player " .. _RELATION_PLAYER_TYPE["PARTY"])
-- 		_g_HidePartyPlayerType = true
-- 		FireUIEvent('TOGGLE_PARTY', false)
-- 		--StorageServer.SetData("UISetting_BoolValues2", "SHOW_PARTY_PLAYER_TYPE", false)
-- 	end
-- end

--[[ local function fnUpdateHidePartyPlayerType()
	UnRegisterEvent("SYNC_USER_PREFERENCES_END", fnUpdateHidePartyPlayerType)
	_g_HidePartyPlayerType = not StorageServer.GetData("UISetting_BoolValues2", "SHOW_PARTY_PLAYER_TYPE")
	TogglePartyPlayer(not _g_HidePartyPlayerType)
end
RegisterEvent("SYNC_USER_PREFERENCES_END", fnUpdateHidePartyPlayerType) ]]

-- function ChangePlayerDisplayMode()
-- 	if _g_HidePlayerType then
-- 		local pPlayer = GetClientPlayer()
-- 		if pPlayer and pPlayer.IsInParty() and _g_HidePartyPlayerType then
-- 			--只显示队友
-- 			TogglePartyPlayer(true)
-- 		else
-- 			--显示所有
-- 			if not _g_HidePartyPlayerType then
-- 				TogglePartyPlayer(true)
-- 			end
-- 			TogglePlayer(true)
-- 		end
-- 	else
-- 		--隐藏所有玩家
-- 		TogglePlayer(false)
-- 		TogglePartyPlayer(false)
-- 	end
-- end

--[[
_g_HideAllies = false --- 需要好好处理与 _g_HidePartyPlayerType 的关系 ---- 或许直接不用这个接口了，用 TogglePartyPlayer()！
function ToggleParty(bShow)  --- 这个接口目前只在幻境云图里用（等以后表现逻辑方面进行接口改进）
	if bShow ~= nil and (bShow == false) == _g_HideAllies then
		return
	end
	if _g_HideAllies then
		rlcmd("show or hide party player 1")
		---rlcmd("show relation player " .. _RELATION_PLAYER_TYPE["PARTY"])
		_g_HideAllies = false
		FireUIEvent('TOGGLE_PARTY', true)
	else
		rlcmd("show or hide party player 0")
		---rlcmd("hide relation player " .. _RELATION_PLAYER_TYPE["PARTY"])
		_g_HideAllies = true
		FireUIEvent('TOGGLE_PARTY', false)
	end
end
--]]

--rlcmd("show npc")
--rlcmd("show player")
--rlcmd("show self")
--rlcmd("show allies")
--rlcmd("show or hide party player 0")

function PlayerChangeSuit(index)
	OnSuitChangeHotkey(index)
end

function StartSprint()
	local hPlayer = GetClientPlayer()
	if hPlayer then
		if hPlayer.bIgnoreGravity then
			return
		end
		bStart = true

		if hPlayer.dwJumpType == SCHOOL_TYPE.GAI_BANG then
			local dwSkillID = 6754
			OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
		end

		hPlayer.Sprint(true)
	end
end

function CheckEndSprint(bForce)
	if bStart then
		EndSprint(bForce)
		return true
	end
end

function EndSprint(bForce)
	local me = GetClientPlayer()
	if me and (not me.bIgnoreGravity or bForce) then
		bStart = false
		local nHavePos, nPosX, nPosY, nPosZ = MapMgr.SprintGetSummitID()
		me.SetSprintTopPoint(nPosX, nPosY, nPosZ)
		me.Sprint(false)
	end
end

function UnregisterAutoClose(szKey)
	for i, ac in ipairs_r(lc_aAutoClose) do
		if ac.szKey == szKey then
			table.remove(lc_aAutoClose, i)
		end
	end
end

function RegisterAutoClose(szKey, fnCondition, fnAction, bIsParamNeeded)
	UnregisterAutoClose(szKey)
	if fnAction then
		table.insert(lc_aAutoClose, {
			szKey       	= szKey      ,
			fnCondition 	= fnCondition,
			fnAction    	= fnAction   ,
			bIsParamNeeded 	= bIsParamNeeded ,
		})
	end
end

function UnregisterAutoClose_Topmost(szKey)
	for i, ac in ipairs_r(lc_aAutoCloseTopmost) do
		if ac.szKey == szKey then
			table.remove(lc_aAutoCloseTopmost, i)
		end
	end
end

function RegisterAutoClose_Topmost(szKey, fnCondition, fnAction)
	UnregisterAutoClose_Topmost(szKey)
	if fnAction then
		table.insert(lc_aAutoCloseTopmost, {
			szKey       = szKey      ,
			fnCondition = fnCondition,
			fnAction    = fnAction   ,
		})
	end
end

local function FindIndePent(szKey)
	for i, ac in ipairs_r(lc_aIndePentShow) do
		if ac.szKey == szKey then
			return ac, i
		end
	end
end

function RegisterIndePentShowPanel(szKey, fnCondition, fnEscAction, szGroup)
	UnRegisterIndePentShowPanel(szKey)
	table.insert(lc_aIndePentShow, {
			szKey       	= szKey      ,
			fnCondition 	= fnCondition,
			fnEscAction    	= fnEscAction,
			szGroup			= szGroup or szKey,
	})
end

function UnRegisterIndePentShowPanel(szKey)
	local _, index = FindIndePent(szKey)
	if index then
		table.remove(lc_aIndePentShow, index)
	end
end

function IsIndePentShowPanelsOpen(szGroup)
	for _, ac in ipairs_r(lc_aIndePentShow) do
		if (not szGroup or ac.szGroup ~= szGroup) and ac.fnCondition and ac.fnCondition() then
			return true
		end
	end
	return false
end

function CloseIndePentShowPanels(szKeepKey)
	for _, ac in ipairs_r(lc_aIndePentShow) do
		if ac.szKey ~= szKeepKey and ac.fnCondition and ac.fnCondition() then
			if ac.fnEscAction then
				ac.fnEscAction()
			end
		end
	end
	return false
end

function EnterOrLeaveCarrier(szEvent)
	if szEvent == "CHANGE_CARRIER_STATE" then
		bInCarrier = arg0
	end
end

function ResponseSepcialKey(szEvent)
	if szEvent ~= "SPECIAL_KEY_MSG" then
		return
	end

	local nKey, bDown = arg0, arg1
	if IsShiftKey(nKey) then
		if bDown then
			if IsPlayerInSprint() and not ResponseDisplacementHotkey("SHIFT", true, false) then
			else
				--PostThreadCall(OnThreadStartSprint, nil, "Camera_IsRunForward")
			end
		else
			ResponseDisplacementHotkey("SHIFT", false, false)
		end
	elseif IsAltKey(nKey) then
		if bDown then
			if IsPlayerInSprint() and not ResponseDisplacementHotkey("ALT", true, false) then
			end
		else
			ResponseDisplacementHotkey("ALT", false, false)
		end
	end
end

function GVOpenMicphone()
	if GVoiceBase_IsInKeySay() then
		GVoiceBase_OpenMic()
	end
end

function GVCloseMicphone()
	if GVoiceBase_IsInKeySay() then
		GVoiceBase_CloseMic()
	end
end

function ShowUIMessage()
	FireUIEvent("SPECIAL_KEY_MSG", 0x5D, true)
end

function OnThreadStartSprint(bRunForward)
	if bRunForward then
		StartSprint()
	end
end

function IsPlayerInSprint()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	return hPlayer.bSprintFlag
end

function IsPlayerInHang()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	return hPlayer.bHangFlag
end

function CanUseLeftRightSprint()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local bRetCode = hPlayer.bSprintFlag and
					 hPlayer.nMoveState == MOVE_STATE.ON_RUN and
					 not hPlayer.IsFollowController() and
					 hPlayer.dwJumpType == SCHOOL_TYPE.GAI_BANG
	return bRetCode

end

local _OccupancyHotkeys = {}
function OccupancyHotkey(key, shift, ctrl, alt, szContext, fnDown, fnUp)
	if Hotkey.IsUsed(key, shift, ctrl, alt, szContext) then
		local fnOrgDown, fnOrgUp = Hotkey_GetBindingFun(key, shift, ctrl, alt)

		if fnDown then
			Hotkey_ModifyBindingFun(fnDown, true, key, shift, ctrl, alt)
		end

		if fnUp then
			Hotkey_ModifyBindingFun(fnUp, false, key, shift, ctrl, alt)
		end

		table.insert(_OccupancyHotkeys, {key, shift, ctrl, alt, fnOrgDown, fnOrgUp})
	else
		local szName = "Occupancy"..(#_OccupancyHotkeys + 1)
		Hotkey.AddBinding(szName, szName, "", fnDown, fnUp)
		Hotkey.Set(szName, 1, key, shift, ctrl, alt, szContext)
		table.insert(_OccupancyHotkeys, szName)
	end
end

function RestoreOccupancyHotkey()
	local len = #_OccupancyHotkeys
	if len == 0 then
		return
	end

	local t = _OccupancyHotkeys[len]
	if type(t) == "string" then
		local cnt = Hotkey.GetBindingCount()
		if cnt > 0 then
			local cmd = Hotkey.GetCommand(cnt - 1)
			if cmd == t then
				Hotkey.PopbackBinding()
			end
		end
	else
		if t[5] then
			Hotkey_ModifyBindingFun(t[5], true, t[1], t[2], t[3], t[4])
		end

		if t[6] then
			Hotkey_ModifyBindingFun(t[6], false, t[1], t[2], t[3], t[4])
		end
	end

	table.remove(_OccupancyHotkeys, len)
end

local _paintingEnable
local function OnNotifyPainting()
	local bEnable = arg0

	if (bEnable and _paintingEnable) or (not bEnable and not _paintingEnable) then
		return
	end

	if bEnable then
		OccupancyHotkey(GetKeyValue("MouseWheelDown"), false, false, false, "",
			function()
				rlcmd("set paint scale -0.03")
			end
		)

		OccupancyHotkey(GetKeyValue("MouseWheelUp"), false, false, false, "",
			function()
				rlcmd("set paint scale 0.03")
			end
		)
		_paintingEnable = true
	else
		RestoreOccupancyHotkey()
		RestoreOccupancyHotkey()
		_paintingEnable = nil
	end
end

--RegisterEvent("CHANGE_CARRIER_STATE", function(szEvent) EnterOrLeaveCarrier(szEvent) end)
--RegisterEvent("SPECIAL_KEY_MSG", function(szEvent) ResponseSepcialKey(szEvent) end)
--
--RegisterEvent("NOTIFY_PAINTING", OnNotifyPainting)



----------------------------Context History-------------------------------------------------

local tContextHistory = {}
function Hotkey_EnterContext(szName)
	if Hotkey.GetCurContext() == szName then
		return
	end
	Hotkey.SetCurContext(szName)
	table.insert(tContextHistory, szName)
end

function Hotkey_ExitContext(szName)
	if szName == "" then
		return
	end
	local szCurContext =  Hotkey.GetCurContext()
	if szCurContext == szName then
		table.remove(tContextHistory)
		local szContext = ""
		if #tContextHistory > 0 then
			szContext = tContextHistory[#tContextHistory]
		end
		Hotkey.SetCurContext(szContext)
	else
		local nCount = #tContextHistory
		for k = nCount, 1, -1 do
			local v = tContextHistory[k]
			if v == szName then
				table.remove(tContextHistory, v)
				break
			end
		end
	end
end

function Hotkey_ResetContext()
	tContextHistory = {}
	Hotkey.SetCurContext("")
end

--RegisterEvent("FIRST_LOADING_END", Hotkey_ResetContext)
----------------------------Context History-------------------------------------------------
--- 切换阵营同模开关
function ToggleUniform(bShow)
	local bCampUniform = QualityMgr.IsCampUniform()
	if bShow ~= nil and (bShow == false) == bCampUniform then
		return
	end

	if QualityMgr.SwitchCampUniform(not bCampUniform) then
		TipsHelper.ShowNormalTip(bCampUniform and "关闭阵营同模" or "开启阵营同模")
	else
		TipsHelper.ShowNormalTip("当前场景正在开启活动，暂时不可关闭同模效果。")
	end
end

Event.Reg(g_HotKey, EventType.OnClientPlayerLeave, function()
	m_bEnableToggleRun = true
end)
