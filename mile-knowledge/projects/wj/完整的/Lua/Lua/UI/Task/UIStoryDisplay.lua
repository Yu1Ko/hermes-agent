
-- PrefabName:PanelStoryDisplay

-- 协议动画播放
local UIStoryDisplay = class("UIStoryDisplay")
-- 不能覆盖背景音效的动画列表？
local tNotStopSoundID = {61, 269, 270, 271, 263, 264}

---@enum 当前状态
local Status = {
    kNone = 0,
    kPrepare = 1,
    kPlaying = 2,
}
---@enum 播放模式
local Mode = {
    kNone = 0,
    kMovie = 1,
    kCamera = 2,
}

local LogicSpeedValueByIndex = 
{
    1,
    1.5,
    2,
    3
}

local UISpeedValueByIndex = 
{
    1,
    1,
    1.5,
    2
}

local function GetNpcNameImage(dwImageID)
	local tLine = g_tTable.NpcName_Image:Search(dwImageID)
	if tLine and tLine.szImage ~= "" then
        local szPath = tLine.szImage
        szPath = string.gsub(szPath, "ui\\Image", "Resource")
        szPath = string.gsub(szPath, "ui/Image", "Resource")
        szPath = string.gsub(szPath, ".tga", ".png")
        return szPath
	end
end

local function CheckCD(a, b, cd)
    if a and b and cd then
        if a - b >= cd then
            return true
        else
            return false
        end
    end
end

local SpeedCDTime = 1

local bEnableStory = true

function UIStoryDisplay:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.eStatus = Status.kPrepare
        self.eMode = Mode.kNone
        self.bFirstLoadingEnd = false
        self.nNormalEnd = false
    end

    self.bEnableAutoSkip= false
    self.nSpeedIndex = 1
    self.nCurSpeedCd = GetCurrentTime()
    UIHelper.SetVisible(self.labelTest, false)
    UIHelper.SetVisible(self.btnClose, false)
    UIHelper.SetVisible(self.nodeLoading, false)
    UIHelper.SetVisible(self.StoryWord, false)
    UIMgr.HideLayer(UILayer.Main)
    UIMgr.HideLayer(UILayer.Page)
    ShortcutInteractionData.SetEnableKeyBoard(false)
    self:UpdateSpeedState()


    UIHelper.SetVisible(self.BtnSpeedPlay, false)
    UIHelper.SetVisible(self.WidgetClick, false)
    UIHelper.SetVisible(self.BtnAutoPlay, false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIStoryDisplay:OnExit()
    self.bInit = false
    ShortcutInteractionData.SetEnableKeyBoard(true)
    self:restoreGameEnv()
    Scene_StopMovie()
    if self.fnEndCall then
        self.fnEndCall(self.bNormalEnd)
    end

    UIMgr.ShowLayer(UILayer.Main)
    UIMgr.ShowLayer(UILayer.Page)
end

function UIStoryDisplay:BindUIEvent()
    UIHelper.BindUIEvent(self.btnClose, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_COMFIRM_SKIP_STORY_DISPLAY, function ()
            UIMgr.Close(self)
        end)
    end)
    
    UIHelper.BindUIEvent(self.BtnSpeedPlay, EventType.OnClick, function ()
        local nTime = GetCurrentTime()
        if not CheckCD(nTime, self.nCurSpeedCd, SpeedCDTime) then
            return
        end
        self.nCurSpeedCd = nTime
        self.nSpeedIndex = self.nSpeedIndex + 1
        if self.nSpeedIndex > table.get_len(LogicSpeedValueByIndex) then
            self.nSpeedIndex = 1
        end
        rlcmd(string.format("movie set speed %f",LogicSpeedValueByIndex[self.nSpeedIndex]))
        self:UpdateSpeedState()
    end)

    
    UIHelper.BindUIEvent(self.BtnAutoPlay, EventType.OnClick, function ()
        self.bEnableAutoSkip = not self.bEnableAutoSkip
        self:UpdateAutoPlayState()
        rlcmd(string.format("movie auto skip wait jump %d",self.bEnableAutoSkip and 1 or 0))
    end)
    UIHelper.BindUIEvent(self.BtnClick, EventType.OnClick, function ()
        rlcmd("movie jump plot")
    end)
end

function UIStoryDisplay:RegEvent()
    Event.Reg(self, "UPDATE_MOVIE_LOADING_PROCESS", function(nProgress) self:onPreMoviesLoading(nProgress) end)
    Event.Reg(self, "PREPARE_PLAY_MOVIES", function(nTime) self:onPreStartMovies(nTime) end)
    Event.Reg(self, "PLAY_MOVIES", function(nMovieID) self:onStartMovies(nMovieID) end)
    Event.Reg(self, "FLASH_SUBTITLES", function(...) self:onStoryDisplayNotify(...) end)
    Event.Reg(self, "STOP_MOVIES", function (_, bNormalEnd) self:onMoviestop(bNormalEnd) end)
    Event.Reg(self, "BEGIN_CAMERA_ANIMATION", function(...) self:onStartCameraAni(...) end)
    Event.Reg(self, "END_CAMERA_ANIMATION", function (...) self:onCameraStop(...) end)
    Event.Reg(self, "FIRST_LOADING_END", function() self.bFirstLoadingEnd = true end)
    Event.Reg(self, EventType.OnStartPlayMovie, function(nMovieID) self:onStartMovies(nMovieID) end)

    Event.Reg(self, "MOVIE_UPDATE_BUTTON_STATE", function(...) self:onUpdateButtonState(...)  end)
    

end

function UIStoryDisplay:UpdateAutoPlayState()
    UIHelper.SetString(self.LabelAutoPlayName, self.bEnableAutoSkip and "取消自动" or "自动播放")
    UIHelper.SetVisible(self.MaskArrow, self.bEnableAutoSkip)
    if self.bEnableAutoSkip then
        UIHelper.PlayAni(self, self.BtnAutoPlay, "AniStoryDisplayAutoPlay", nil, -1, false, 1)
    else
        UIHelper.StopAni(self, self.BtnAutoPlay, "AniStoryDisplayAutoPlay")
    end
end

function UIStoryDisplay:UpdateSpeedState()
    UIHelper.SetString(self.LabelSpeedName, string.format("速度%.1fx",LogicSpeedValueByIndex[self.nSpeedIndex]))
    UIHelper.PlayAni(self, self.BtnSpeedPlay, "AniStoryDisplaySpeedPlay", nil, -1, false, UISpeedValueByIndex[self.nSpeedIndex])

    UIHelper.SetVisible(self.WidgetSpeed, self.nSpeedIndex > 1)
    UIHelper.SetVisible(self.ImgIcon, self.nSpeedIndex == 1)

end

-- 服务器端调用播放协议动画
function UIStoryDisplay:Play(nStoryID, tConfig, fnEndCall)
    self.nStoryID = nStoryID
    self.bNormalEnd = false
    self.tConfig = tConfig or {}
    self.fnEndCall = fnEndCall
    self.bFirstLoadingEnd = false
    self.tShowImage = {}
    self.tShowSfx = {}
    if tConfig.bCanStop then
        UIHelper.SetVisible(self.btnClose, true)
    end

    if not bEnableStory then
        UIMgr.Close(self)
        return
    end

    rlcmd("stop npc dialog")
    if tConfig.nOtherRoleID then
        rlcmd("play two player movie " .. nStoryID .. " " .. tConfig.nOtherRoleID)
    else
        rlcmd("play movie " .. nStoryID)
    end

    LOG("UIStoryDisplay:Play %s", nStoryID)
end

function UIStoryDisplay:startPlayMovie(nMovieID)
    self.bEnable3DOption = true

    if table.contain_value(tNotStopSoundID, nMovieID) then  -- 不中止音效
        if self.bEnableSound then
            self.bEnableSound = false
            --BgMusic_TryPlayLast()
        end
    else
        self.bEnableSound = true
    end
    self.bEnableWord = true

    self.eMode = Mode.kMovie
    --local frame = UIStoryDisplay.IsOpened()
    --if frame then
    --	LeaveWaiting(frame)
    --    Hotkey.Enable(true)
    --end

    self:enterStoryMode()
    rlcmd("ready to play movie " .. nMovieID)
end

function UIStoryDisplay:enterStoryMode()
    self:enableGameEnv()
    self:beginPlay()
    --FullScreenSFX.SetVisibleWhenUIHide(false)
    --FireUIEvent('ENTER_STORY_MODE', frame)
end

function UIStoryDisplay:beginPlay()
    --PlotDialoguePanel.Close()
    --CloseQuestAcceptPanel()
    --Station.EnterShowMode("UIMovie")

    -- local cimgBG = frame:Lookup("", "Image_Bg")
    -- Animation_StopAni(cimgBG)

    -- if UIStoryDisplay.play_state == "prepare" and frame.need_loading then
    -- 	imageAni_stop(frame:Lookup("", "Handle_Map/Image_Load"))
    -- 	Animation_StopAni(frame:Lookup("", "Handle_Map"))

    -- 	frame:Lookup("", "Image_Bg"):Hide()
    -- 	local fnAction=function()
    -- 		if frame and frame:IsValid() then
    -- 			frame:BringToTop()
    -- 			frame:Lookup("", "Handle_Map"):Hide()
    -- 		end
    -- 	end
    -- 	_tAniTrack["FADE_OUT"].fTotalTime = 1500
    -- 	Animation_AppendLineAniEx(frame:Lookup("", "Handle_Map"),  _tAniTrack["FADE_OUT"] , {fnEnd=fnAction})
    -- else
    -- 	_tAniTrack["FADE_OUT"].fTotalTime = 1800
    -- 	Animation_AppendLineAniEx(cimgBG,  _tAniTrack["FADE_OUT"])
    -- end

    -- if _bEnableWord and not m_bHideShadow then
    -- 	frame:Lookup("", "Handle_Up"):Show()
    -- 	frame:Lookup("", "Handle_Down"):Show()
    -- else
    -- 	frame:Lookup("", "Handle_Up"):Hide()
    -- 	frame:Lookup("", "Handle_Down"):Hide()
    -- end

    -- if m_begin_func then
    -- 	m_begin_func()
    -- 	m_begin_func = nil
    -- end

    --UIStoryDisplay.UpdateTip(frame, _bCanStopPlay)
    self.eStatus = Status.kPlaying
    --UIStoryDisplay.UpdateSkipState(frame)
end

function UIStoryDisplay:enterWaiting()
    UIHelper.SetEnable(self.nodeLoading, true)
end

function UIStoryDisplay:leaveWaiting()
    UIHelper.SetEnable(self.nodeLoading, false)
end

function UIStoryDisplay:enableGameEnv()
    if self.tConfig.bEnable3DOption then
        self.tConfig.bModify3DOption = true
        --Login_Update3DOption(nil, false, _bEnableCMYK, _fCameraDistance, true)
    end

    --EnableSoundMinimize(true)
    --EnableSoundWhenLoseFocus(true)

    if self.tConfig.bEnableSound then
        SetVolume(SOUND.BG_MUSIC, 0)
    end
  
    Event.UnReg(self, EventType.OnKeyboardDown)
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_F or nKeyCode == cc.KeyCode.KEY_SPACE then
            rlcmd("movie jump plot")
        elseif nKeyCode == cc.KeyCode.KEY_ESCAPE then
            UIHelper.ShowConfirm(g_tStrings.STR_COMFIRM_SKIP_STORY_DISPLAY, function ()
                UIMgr.Close(self)
            end)
        end
    end)
end

function UIStoryDisplay:restoreGameEnv()
    if self.tConfig.bEnable3DOption and self.tConfig.bModify3DOption then
        self.tConfig.bModify3DOption = nil
        --Login_Restore3DOption()
    end

    --EnableSoundMinimize(false)
    --EnableSoundWhenLoseFocus(g_SoundSetting.bEnableLoseFocusPlay)

    if self.tConfig.bEnableSound then
        --SetVolume(SOUND.BG_MUSIC, GameSettingData.GetSoundSliderValue(SOUND.BG_MUSIC))
        -- 结束时，其他音效都重置一遍
        for k, v in pairs(SOUND) do
            local volume = GameSettingData.GetSoundSliderValue(v)
            if volume then
                SetVolume(v, volume)
            end
        end
    end
    Event.UnReg(self, EventType.OnKeyboardDown)
end

function UIStoryDisplay:onPreMoviesLoading(nProgress)
    if not self.bFirstLoadingEnd then
        return
    end

    self.eStatus = Status.kPrepare
    self.eMode = Mode.kMovie
    if type(arg0) == "string" then
        return
    end

    if nProgress == -1 then                         -- 加载失败
        UIMgr.Close(self)
    elseif nProgress < 1 and nProgress > 0 then     -- 正在加载
        self:enterWaiting()
    elseif nProgress == 1 then                      -- 加载完成
        self:leaveWaiting()
        --Hotkey.Enable(true)
    end
end

function UIStoryDisplay:onPreStartMovies(nTime)
    self.tConfig.bEnable3DOption = false
    self.tConfig.bEnableSound = true
    self.eMode = Mode.kMovie
    self.eStatus = Status.kPrepare

    self:enableGameEnv()
    --UIStoryDisplay.BeginLoad(frame, fTime)
end

function UIStoryDisplay:onStartMovies(nMovieID)
    if not MovieMgr.bPlayMovie then
        return
    end
    self:startPlayMovie(nMovieID)
end

function UIStoryDisplay:onMoviestop(bNormalEnd)
    self.bNormalEnd = bNormalEnd
    UIMgr.Close(self)
end

function UIStoryDisplay:onStoryDisplayNotify(...)
    local szType = arg0
    if szType == "Name" or szType == "SFX" then
		local t =
		{
			nX = arg2,
			nY = arg3,
			nTime = arg4,
			nWidth = arg5,
			nHeight = arg6,
			obj_id = arg7,
			rotate = arg8,
			alpha = arg9,
			nPriority = arg10,
			nSourceW = arg11,
			nSourceH = arg12,
			fScaleX = arg13,
			fScaleY = arg14,
			fScaleZ = arg15,
			fPlaySpeed = arg16,
			bIsQTESFX = arg17,
			szDescHotKeyName = arg18,
			nHotKeyState = arg19,
			fQTELength = arg20,
            nSfxPlayType = arg21,
		}

		if szType == "Name" then
			t.dwImageID = arg1
		else
			t.szSfxFile = arg1
		end

		if not t.bIsQTESFX then
			self:DoShowImage(t)
		end
    elseif szType == "Word" and self.bEnableWord then
        self:DoWord(arg1, arg2, arg3, arg4)
	end
end

function UIStoryDisplay:onUpdateButtonState(...)
    local nButtonType = arg0
    local bShow = arg1
    if nButtonType == MOVIE_BUTTON_TYPE.CHANGE_SPEED then
        UIHelper.SetVisible(self.BtnSpeedPlay, bShow)
        self:UpdateSpeedState()
    elseif nButtonType == MOVIE_BUTTON_TYPE.JUMP_PLOT  then
        UIHelper.SetVisible(self.WidgetClick, bShow)
    elseif nButtonType == MOVIE_BUTTON_TYPE.AUTO_SKIP_WAIT_JUMP  then
        UIHelper.SetVisible(self.BtnAutoPlay, bShow)
        self:UpdateAutoPlayState()
    end
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


function UIStoryDisplay:DoWord(szWord, nTime, bIsPlayerSubtitle, pszSpeakerName)

    UIHelper.SetVisible(self.WidgetContentNew, true)
    UIHelper.SetString(self.LabelStoryWord, UIHelper.GBKToUTF8(szWord))
    local playerName = ""
    if bIsPlayerSubtitle then
        local player = PlayerData.GetClientPlayer()
        if  player then
            playerName = UIHelper.GBKToUTF8(PlayerData.GetPlayerName(player))
        end
    else
        playerName = UIHelper.GBKToUTF8(pszSpeakerName)
    end

    UIHelper.SetString(self.LabelPlayerName, playerName)
    UIHelper.SetVisible(self.WidgetName, playerName ~= "")
    if self.scheduleHandle then
        Timer.DelTimer(self, self.scheduleHandle)
        self.scheduleHandle = nil
    end
    -- self.scheduleHandle = Timer.Add(self, nTime / 1000, function()
    --     self:HideWord()
    -- end)
end

function UIStoryDisplay:HideWord()
    UIHelper.SetVisible(self.WidgetContentNew, false)
    UIHelper.SetString(self.LabelStoryWord, "")
end

function UIStoryDisplay:DoShowImage(t)
    local nX 			= t.nX or 0
	local nY 			= t.nY or 0
	local nTime 		= t.nTime
	local rotate 		= t.rotate or 0
	local alpha 		= t.alpha or 1.0
    local dwImageID 	= t.dwImageID
	local nWidth 		= t.nWidth or 0
	local nHeight 		= t.nHeight or 0
	local nPriority 	= t.nPriority or 0
    local nSourceW      = t.nSourceW
    local nSourceH      = t.nSourceH


    local deviceSize = UIHelper.DeviceScreenSize()

    local canvasW, canvasH  = UIHelper.GetContentSize(self.NpcName)
    -- 视频坐标 → 设备屏幕坐标
    -- 计算设备分辨率与视频分辨率，按真实高度适配的缩放比例
    local realScale = deviceSize.height / nSourceH
    local realVideoW = nSourceW * realScale
    local realVideoH = nSourceH * realScale
    local realCropOffsetX = (realVideoW - deviceSize.width) / 2
    local realX = nX * realScale - realCropOffsetX
    local realY = deviceSize.height - (nY * realScale)
    local realW = nWidth * realScale
    local realH = nHeight * realScale

    --真实屏幕坐标 → 画布坐标
    local canvasScale = deviceSize.height / canvasH
    local realCanvasW = canvasW * canvasScale
    local realCanvasH = canvasH * canvasScale
    local canvasOffsetX = (realCanvasW - deviceSize.width) / 2

    -- 计算出适配后的位置
    local adjPosX = (realX - canvasOffsetX) / canvasScale
    local adjPosY = realY / canvasScale 

    -- if not self.tShowImage[t.obj_id] then
    --     LOG.INFO("DoShowImage name:%s OrgPos:(%d,%d),OrgSize:(%d,%d),OrgScreenSize:(%d,%d),adhPos:(%f,%f),deviceSize:(%d,%d)",tostring(t.obj_id),nX,nY,nWidth,nHeight,nSourceW,nSourceH,adjPosX,adjPosY,deviceSize.width,deviceSize.height)
    -- end
    if t.dwImageID then
        if self.tShowImage[t.obj_id] then
            local image = self.tShowImage[t.obj_id]
            image:setOpacity(alpha * 255)
            if nSourceW == nWidth and nSourceH == nHeight then
                image:setContentSize(canvasW, canvasH)
                image:setAnchorPoint(cc.p(0, 0))
                image:setPosition(0,  0)
            else
                image:setContentSize(nWidth * realScale, nHeight * realScale)
                image:setAnchorPoint(cc.p(0, 1))
                image:setPosition(adjPosX, adjPosY)
            end
        else
            local szImage = GetNpcNameImage(t.dwImageID)
            if szImage then
                local image = cc.Sprite:create(szImage)
                if image then
                    image:setName(t.obj_id)
                    self.NpcName:addChild(image)
                    image:setOpacity(alpha * 255)
                    if nSourceW == nWidth and nSourceH == nHeight then
                        image:setContentSize(canvasW, canvasH)
                        image:setAnchorPoint(cc.p(0.5, 0.5))
                        image:setPosition(0,  0)
                    else
                        image:setContentSize(nWidth * realScale, nHeight * realScale)
                        image:setAnchorPoint(cc.p(0, 1))
                        image:setPosition(adjPosX, adjPosY)
                    end
                    self.tShowImage[t.obj_id] = image

                    local removeSelf = cc.CallFunc:create(function()
                        UIHelper.SetVisible(image, false)
                        UIHelper.RemoveFromParent(image)
                        self.tShowImage[t.obj_id] = nil
                    end)
                    image:runAction(cc.Sequence:create(cc.DelayTime:create(nTime / 1000), removeSelf))
                end
            end
        end
    end

	if t.szSfxFile then
        if self.tShowSfx[t.obj_id] then
            local sfx = self.tShowSfx[t.obj_id]
            sfx:setOpacity(alpha * 255)
            sfx:SetModelScale(t.fScaleX)
            sfx:setAnchorPoint(cc.p(0, 1))
            sfx:setPosition(adjPosX, adjPosY)
        else
            local sfx = cc.CCSFX:create()
            if sfx then
                sfx:setName(t.obj_id)
                self.Eff_All:addChild(sfx)
                sfx:setContentSize(UIHelper.GetContentSize(self.Eff_All))
                UIHelper.SetSFXPath(sfx, t.szSfxFile, t.nSfxPlayType ~= 2, alpha * 255, rotate)
                sfx:setOpacity(alpha * 255)
                sfx:SetModelScale(t.fScaleX)
                sfx:setAnchorPoint(cc.p(0, 1))
                sfx:setPosition(adjPosX, adjPosY)
                UIHelper.PlaySFX(sfx)
                self.tShowSfx[t.obj_id] = sfx

                local removeSelf = cc.CallFunc:create(function()
                    UIHelper.SetVisible(sfx, false)
                    UIHelper.RemoveFromParent(sfx)
                    self.tShowSfx[t.obj_id] = nil
                end)
                sfx:runAction(cc.Sequence:create(cc.DelayTime:create(nTime / 1000), removeSelf))
            end
        end
    end
end

function UIStoryDisplay:onStartCameraAni(nID, bHideUI, bEnableWord)
    if not bHideUI then
        return
    end

    self.tConfig.bEnable3DOption = false
    self.tConfig.bEnableSound = false
    self.tConfig.bCanStop = false
    self.tConfig.bEnableWord = bEnableWord
    self.eMode = Mode.kCamera
    self:enterStoryMode();
end

function UIStoryDisplay:onCameraStop()
    UIMgr.Close(self)
end


return UIStoryDisplay
