-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: NpcSpeechSoundBalloon
-- Date: 2023-01-07 16:57:11
-- Desc: NPC语音气泡显示
-- ---------------------------------------------------------------------------------

local NpcSpeechSoundBalloon = class("NpcSpeechSoundBalloon")
local tEscapeTable =
{
	['"'] = '\\"',
	['\\'] = '\\\\',
	['\n'] = '\n',
	['\t'] = '\\t'
}
local bShowSoundsIcon = {
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = false,
	[5] = false,
	[6] = false,
}
local MIN_SHOW_TIME = 3 -- 如果没有时间的情况下，最少显示3秒
function NpcSpeechSoundBalloon:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    return self:UpdateInfo(dwID)
end

function NpcSpeechSoundBalloon:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function NpcSpeechSoundBalloon:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        Lib.SafeCall(self.funcCloseOperationHint)
    end)
end

function NpcSpeechSoundBalloon:RegEvent()

	Event.Reg(self, "PLAY_SOUND_FINISHED", function()
		if self.nSoundID and arg0 == self.nSoundID then
			self:DoCloseCurOperationHint()
		end
	end)

	Event.Reg(self, "SYNC_SOUND_ID", function()
		if self.szSound and arg1 == self.szSound then
			self.nSoundID = arg0
			if self.nTime == nil and arg0 == 0 then
				self:DelayClose(3)
			end
		end
	end)

	Event.Reg(self, EventType.OnHideNpcSpeechSoundsBalloon, function()
		self:CloseRightNow()
	end)

	Event.Reg(self, EventType.OnCloseNpcSpeechSoundsBalloon, function()
		Lib.SafeCall(self.funcCloseOperationHint)
	end)
end

function NpcSpeechSoundBalloon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function NpcSpeechSoundBalloon:UpdateInfo(dwID)
	self.nTime = nil
    self.nNextID = nil
	if not dwID then return false end
    local tLine = Table_GetNPCSpeechSounds(dwID)
    if not tLine then return false end
    SoundMgr.StopSound()
    UIHelper.SetActiveAndCache(self , self._rootNode , true)
	self.nSoundID = nil
    self.nNextID = tLine.dwNextID
	local dwBgID = tLine.dwBgID or 0
	local szName = UIHelper.GBKToUTF8(tLine.szName)
	if szName == "PlayerName" then
		szName = UIHelper.GBKToUTF8(PlayerData.GetPlayerName())
	end
	local szContent = UIHelper.GBKToUTF8(self:EncodeString(tLine.szText))
    UIHelper.SetString(self.LabelNpcName, szName)
    UIHelper.SetString(self.LabelNpcVoiceContent, szContent)
	UIHelper.SetVisible(self.WidgetVoice, bShowSoundsIcon[dwBgID])
	UIHelper.SetTextColor(self.LabelNpcName, NPCSpeechSoundsBgID2C3b[dwBgID])
	UIHelper.SetSpriteFrame(self.ImgNpcVoiveBg1, NPCSpeechSoundsBgID2BgPath[dwBgID])

	self.nLastShowTime = os.time()

    if tLine.nCloseTime ~= -1 then
        self.nTime = tLine.nCloseTime
    end

	Timer.DelTimer(self, self.nTimeID)
	if self.nTime then--不填nCloseTime时，音频自动播放完才隐藏
		self:DelayClose(self.nTime)
	end
	self.szSound = tLine.szSound
    if tLine.szSound  ~= "" then
        self.nSoundID = SoundMgr.PlaySound(SOUND.CHARACTER_SPEAK,  tLine.szSound, true, 128, true)
	end
	tLine.szHeadPath = string.gsub(tLine.szHeadPath, '\\', '/')
	UIHelper.SetTexture(self.ImgNpc, tLine.szHeadPath)
	UIHelper.LayoutDoLayout(self.LayoutTitle)

	local funcCloseNpcSpeechVoice = function()
		local nElapsed = os.time() - self.nLastShowTime
		local nDelta = MIN_SHOW_TIME - nElapsed
        if nDelta > 0 then
			Timer.DelTimer(self, self.nExDelayTimerID)
			self.nExDelayTimerID = Timer.Add(self, nDelta, function()
				self:DoCloseCurOperationHint()
			end)
			return
		end

		Timer.DelAllTimer(self)
		self.nSoundID = nil
        if self.nNextID and self.nNextID ~= 0 then
			self:UpdateInfo(self.nNextID)
        else
            UIHelper.SetActiveAndCache(self, self._rootNode, false)
			TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        	TipsHelper.NextTip(TipsHelper.Def.Queue3)
        end
    end

    self:SetOperationHintInfo(funcCloseNpcSpeechVoice)

	if tLine.bSyncToChat then
		local szRawName = UIHelper.GBKToUTF8(tLine.szName)
		local bSelf = szRawName == "我" or szRawName == "PlayerName"
		local nChannel = bSelf and PLAYER_TALK_CHANNEL.STORY_PLAYER or PLAYER_TALK_CHANNEL.STORY_NPC
		local szChatName = bSelf and UIHelper.GBKToUTF8(PlayerData.GetPlayerName()) or szName
		ChatData.Append(szChatName.."："..szContent, 0, nChannel, false, "")
	end

	return true
end

function NpcSpeechSoundBalloon:EncodeString(szInfo)
	local _, aInfo = GWTextEncoder_Encode(szInfo)
	if not aInfo then
		return
	end
	local nFont = 22
	local hPlayer = GetClientPlayer()

	local szText = ""
	for  k, v in pairs(aInfo) do
		if v.name == "text" then --普通文本
			szText = szText..self:EncodeComponentsString(v.context)
        elseif v.name == "N" then -- NPC对玩家的自定义称呼
            local szName = ""
            local nID = tonumber(v.context)
            if nID then
                szName = Table_GetNpcCallMe(nID)
            else
                szName = hPlayer.szName
            end
            szText = szText..self:EncodeComponentsString(szName)
		elseif v.name == "C" then	--自己的体型对应的称呼
			szText = szText..self:EncodeComponentsString(g_tStrings.tRoleTypeToName[hPlayer.nRoleType])
		elseif v.name == "F" then	--字体
			szText = szText..self:EncodeComponentsString(v.attribute.text)
		elseif v.name == "T" then	--图片
			szText = szText.."<image>path=\"fromiconid\" frame="..v.attribute.picid.."</image>"
		elseif v.name == "A" then	--动画
		elseif v.name == "H" then	--控制行高，如果高度大于当前行高，调整为这个高度，否则，不变
			szText = szText
		elseif v.name == "G" then	--4个英文空格
			local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
			if v.attribute.english then
				szSpace = "    "
			end
			szText = szText..szSpace
		elseif v.name == "J" then	--金钱
			local nM = tonumber(v.attribute.money)
			local nF = nFont
			if v.attribute.compare then
				if MoneyOptCmp(nM, hPlayer.GetMoney()) > 0 then
					nF = 20
				end
			end
			szText = szText..GetMoneyText(nM, "font="..nF)
		elseif v.name == "AT" then --动作
		elseif v.name == "SD" then --声音
		elseif v.name == "WT" then --延迟
		else --错误的解析，还原文本
			if v.context then
				szText = szText..self:EncodeComponentsString("<"..v.context..">")
			end
		end
	end
	return szText
end



function NpcSpeechSoundBalloon:EncodeComponentsString(string)
	return  string.gsub(string, "[\"\\\n\t]", tEscapeTable)
end

function NpcSpeechSoundBalloon:SetOperationHintInfo(funcCloseOperationHint)
    self.funcCloseOperationHint = funcCloseOperationHint
end


function NpcSpeechSoundBalloon:DoCloseCurOperationHint()
    Lib.SafeCall(self.funcCloseOperationHint)
end

function NpcSpeechSoundBalloon:CloseRightNow()
	Timer.DelAllTimer(self)
	UIHelper.SetActiveAndCache(self, self._rootNode, false)
end

function NpcSpeechSoundBalloon:DelayClose(nTime)
	if self.nTimeID then
		Timer.DelTimer(self, self.nTimeID)
		self.nTimeID = nil
	end
	self.nTimeID = Timer.Add(self, nTime, function()
		self:DoCloseCurOperationHint()
	end)
end

return NpcSpeechSoundBalloon