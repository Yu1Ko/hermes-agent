SoundMgr = SoundMgr or {className = "SoundMgr"}

local self = SoundMgr
local BGM_UI_PRIORITY = 7

function SoundMgr.Init()
	Event.Reg(SoundMgr, "PLAY_BG_MUSIC", function(nMapID, nArea)
		local szMusic = MapHelper.GetMapAreaBgMusic(nMapID, nArea)
		if szMusic and szMusic ~= "" then
			SoundMgr.PlayBgMusic(szMusic)
		else
			SoundMgr.StopBgMusic()
		end
	end)

	Event.Reg(SoundMgr, "ON_DOODAD_BEGIN_PLAY_SOUND", function(doodadID, nSoundID, nOffsetTime)
		local tSound = g_tTable.RegionSound:Search(nSoundID)
		if tSound then
			SoundMgr.PlayBgMusicPriority(tSound.szPath, tSound.nPriority)
		end
	end)

	Event.Reg(SoundMgr, "ON_DOODAD_END_PLAY_SOUND", function(doodadID, nSoundID)
		local tSound = g_tTable.RegionSound:Search(nSoundID)
		if tSound then
			SoundMgr.StopBgMusicPriority(tSound.szPath, tSound.nPriority)
		end
	end)

	Event.Reg(SoundMgr, "LOADING_END", function()
		SoundMgr.PlayMapBgSound()

		if ArenaData.IsInArena() then --竞技场将他人音效设置成跟自身音效一样
			local fValue = GameSettingData.GetNewValue(UISettingKey.CurrentPlayerVolume)
			GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.OTHER_PLAYER, fValue)
			self.bOhterVolueChanged = true
		else
			if self.bOhterVolueChanged then
				local fValue = GameSettingData.GetNewValue(UISettingKey.OtherPlayerVolume)
				GameSettingData.ApplyActorTypeVolumeSetting(ACTOR_SOUND.OTHER_PLAYER, fValue)
				self.bOhterVolueChanged = false
			end
		end
	end)

	Event.Reg(SoundMgr, "SYNC_SOUND_ID", function(dwSoundID, szFileName)
		SoundMgr.dwPlayingSoundID = dwSoundID
		SoundMgr.szPlayingFileName = szFileName
	end)

	Event.Reg(SoundMgr, "UPDATE_REGION_INFO", function(nAreaID)
		local player = PlayerData.GetClientPlayer()
		if not player then
			return
		end
		local dwMapID  = player.GetMapID()
		local szMusic = MapHelper.GetMapAreaBgMusic(dwMapID, nAreaID)
		if szMusic and szMusic ~= "" then
			SoundMgr.PlayBgMusic(szMusic)
		else
			SoundMgr.StopBgMusic()
		end
	end)

	-- Event.Reg(SoundMgr, "QUEST_ACCEPTED", function()
	-- 	SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Invite)
	-- end)

	-- Event.Reg(SoundMgr, "QUEST_FINISHED", function()
	-- 	SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Complete)
	-- end)

	Event.Reg(SoundMgr, "DESTROY_ITEM", function()
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Destroy)
	end)
end

function SoundMgr.UnInit()

end

function SoundMgr.Reset()

end

function SoundMgr.PlayBgMusic(szName, nOffset, nLock, bDontSetLastBGM)
	LOG.INFO("SoundMgr.PlayBgMusic szName:"..GBKToUTF8(szName))

	if nLock == 2 then --先解锁，不然播不出来
		LockBgMusic(false)
	end

	if not bDontSetLastBGM then
		self.szLastBgMusic = szName
	end
	PlayBgMusic(szName, nOffset)

	if nLock == 1 then --播完锁定
		self.LockBgMusic(true)
	end
end

function SoundMgr.LockBgMusic(bLock)
	LockBgMusic(bLock)
end

function SoundMgr.StopBgMusic(bImmediately)
	LOG.INFO("SoundMgr.StopBgMusic")
	StopBgMusic(bImmediately)
end

function SoundMgr.PlayBgMusicPriority(szEvent, nPriority)
	AddBgMusic(szEvent, nPriority)
end

function SoundMgr.StopBgMusicPriority(...)
	DeleteBgMusic(...)
end

function SoundMgr.SetSoundState(szEvent, szState)
	SetSoundState(szEvent, szState)
end

function SoundMgr.PlayUIBgMusic(szEvent)
	SoundMgr.PlayBgMusicPriority(szEvent, BGM_UI_PRIORITY)
end

function SoundMgr.StopUIBgMusic(szEvent, bRefresh)
	SoundMgr.StopBgMusicPriority(szEvent, BGM_UI_PRIORITY, bRefresh)
end

function SoundMgr.ClearBGM()
	ClearBgMusic()
end

function SoundMgr.RefreshBGM()
	RefreshBgMusic()
end

function SoundMgr.PauseBGMEvent(szEvent, fDuration)
	PauseEvent(1, szEvent, fDuration)
end

function SoundMgr.ResumeBGMEvent(szEvent, fDuration)
	ResumeEvent(1, szEvent, fDuration)
end

function SoundMgr.StopBGMImmediately()
	StopBgmImmediately()
end

-- 播放上次的背景音乐
function SoundMgr.PlayLastBgMusic()
	if self.szLastBgMusic then
		self.PlayBgMusic(self.szLastBgMusic)
	end
end

function SoundMgr.PlayBackBgMusic()
	SoundMgr.PlayMapBgSound()
end


function SoundMgr.PlaySound(nSoundType, szSoundKey, nPriority, bCallBackStop)
	nPriority = nPriority or 128

	if not bCallBackStop then
		bCallBackStop = false
	end

	return PlaySound(nSoundType, szSoundKey, true, nPriority, bCallBackStop)
end

function SoundMgr.StopSound(nSoundID, bImmediately)
	nSoundID = nSoundID or SoundMgr.dwPlayingSoundID
	if bImmediately == nil then
		bImmediately = true
	end

	if not nSoundID then
		return
	end

	StopSound(nSoundID, bImmediately)

	SoundMgr.dwPlayingSoundID = nil
	SoundMgr.szPlayingFileName = nil
end

local function _fnOnAreaIDRespond(dwAreaID)
	if not dwAreaID then
		return
	end

	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end

	local dwMapID  = player.GetMapID()
	local szMusic = MapHelper.GetMapAreaBgMusic(dwMapID, dwAreaID)
	if szMusic and szMusic ~= "" then
		SoundMgr.PlayBgMusic(szMusic)
	else
		SoundMgr.StopBgMusic()
	end
end

function SoundMgr.PlayMapBgSound()
	local player = PlayerData.GetClientPlayer()
	if not player then
		return
	end
	local dwMapID  = player.GetMapID()
	local dwNewMapID  = GetMapID_UIEx(dwMapID)
	PostThreadCall(_fnOnAreaIDRespond, nil, "GetRegionInfoByGameWorldPos", dwNewMapID, player.nX, player.nY)
end

function SoundMgr.PlayItemSound(nUiId)
	local nSound = Table_GetItemSoundID(nUiId)
	if nSound == 0 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Ornamental)
	elseif nSound == 1 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupArmer)
	elseif nSound == 2 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupChina)
	elseif nSound == 3 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupCloth)
	elseif nSound == 4 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupHerb)
	elseif nSound == 5 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupIron)
	elseif nSound == 6 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
	elseif nSound == 7 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupPaper)
	elseif nSound == 8 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupRing)
	elseif nSound == 9 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupRock)
	elseif nSound == 10 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupWeapon01)
	elseif nSound == 11 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupWeapon02)
	elseif nSound == 12 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupWeapon03)
	elseif nSound == 13 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupWeapon04)
	elseif nSound == 14 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupWater)
	elseif nSound == 15 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupMeat)
	elseif nSound == 16 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupFood)
	elseif nSound == 17 then
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.PickupPill)
	else
		SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Ornamental)
	end
end

function SoundMgr.OnSceneTypeChange(szCategory)
	if szCategory == QualityCategory.Dungeon then
		Storage.DungeonOptimize.nOtherPlayerVolume = GameSettingData.GetNewValue(UISettingKey.OtherPlayerVolume) -- 进入副本时 存储他人音效初始值
		
		local fValue = GameSettingData.GetNewValue(UISettingKey.CurrentPlayerVolume)
		local nValue = fValue * 0.25
		if nValue < Storage.DungeonOptimize.nOtherPlayerVolume then
			GameSettingData.ApplyNewValue(UISettingKey.OtherPlayerVolume, nValue) -- 将“他人音效”调整为“自身音效”的25%（比现有值更小的情况下才会调整）
		end
	elseif szCategory == QualityCategory.Normal and Storage.DungeonOptimize.nOtherPlayerVolume then
		GameSettingData.ApplyNewValue(UISettingKey.OtherPlayerVolume, Storage.DungeonOptimize.nOtherPlayerVolume) -- 还原“他人音效”副本外设置
		Storage.DungeonOptimize.nOtherPlayerVolume = nil
	end
end
