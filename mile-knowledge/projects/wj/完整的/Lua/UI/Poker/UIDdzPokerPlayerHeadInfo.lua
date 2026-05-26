-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerPlayerHeadInfo
-- Date: 2023-08-11 10:45:01
-- Desc: 斗地主头像信息
-- ---------------------------------------------------------------------------------

local UIDdzPokerPlayerHeadInfo = class("UIDdzPokerPlayerHeadInfo")

function UIDdzPokerPlayerHeadInfo:OnEnter(szPlayerDirection)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szPlayerDirection = szPlayerDirection
    self:UpdateSkin()
end

function UIDdzPokerPlayerHeadInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerPlayerHeadInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAvatarBg2 , EventType.OnClick , function ()
        local uilabel = nil
        if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Left then
            UIHelper.SetVisible(self.WidgetInfoRight , true)
            uilabel = self.LableRightAll
        elseif self.szPlayerDirection == DdzPokerData.tPlayerDirection.Right then
            UIHelper.SetVisible(self.WidgetInfoLeft , true)
            uilabel = self.LableLeftAll
        else
            UIHelper.SetVisible(self.WidgetInfoDown , true)
            uilabel = self.LableDownAll
        end

        local nPlayerID = DdzPokerData.DataModel.tGameData[self.szPlayerDirection].nPlayerID
        if nPlayerID then
            local tRecordData = self:GetDdzRecordData(nPlayerID)
            if not tRecordData then
                UIHelper.SetString(uilabel , g_tStrings.STR_DDZ_NOT_RESULT_TIP)
            else
                local nWinRate = 0
                if tRecordData.nHisMatchCount > 0 then
                    nWinRate = math.ceil((tRecordData.nHisWinCount/tRecordData.nHisMatchCount)*100)
                end
                local szText = string.format(g_tStrings.STR_DDZ_RESULT_TIP, tRecordData.nHisMatchCount, tostring(nWinRate), 
                    tRecordData.nCurContinueWin, tRecordData.nHisContinueWin, tRecordData.nHisWinCount, tRecordData.nHisMaxCash)
                UIHelper.SetString(uilabel ,szText)
            end
        end
    end)
end

function UIDdzPokerPlayerHeadInfo:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Left then
            UIHelper.SetVisible(self.WidgetInfoRight , false)
        elseif self.szPlayerDirection == DdzPokerData.tPlayerDirection.Right then
            UIHelper.SetVisible(self.WidgetInfoLeft , false)
        else
            UIHelper.SetVisible(self.WidgetInfoDown , false)
        end
    end)

    UIHelper.SetTouchDownHideTips(self.BtnAvatarBg2 , false)
end

function UIDdzPokerPlayerHeadInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerPlayerHeadInfo:UpdateSkin()
	local szRootName = UIHelper.GetName(self._rootNode)
	local tbSkin = DdzPokerData.GetSkinInfoListByWidgetName(szRootName, false)
    if tbSkin then
        for nIndex, tbInfo in ipairs(tbSkin) do
            local node = self._rootNode:getChildByName(tbInfo.szMobileNode)
            if safe_check(node) then
                UIHelper.SetSpriteFrame(node, tbInfo.szMobilePath)
            end
        end
    end

	local tbSkinSFX = DdzPokerData.GetSkinInfoListByWidgetName(szRootName, true)
    if tbSkinSFX then
        for nIndex, tbInfo in ipairs(tbSkinSFX) do
            local node = self._rootNode:getChildByName(tbInfo.szMobileNode)
            if safe_check(node) then
                UIHelper.SetSFXPath(node, tbInfo.szMobilePath)
            end
	    end
    end

end


function UIDdzPokerPlayerHeadInfo:UpdateHeadInfo(tPlayerData)
    if tPlayerData.nReady ~= DdzPokerData.TABLE_SLOT_STATE.LIVE then
        UIHelper.SetVisible(self.ImgDizhu ,DdzPokerData.DataModel.nDiZhuIndex == tPlayerData.nIndex ) 
        UIHelper.SetString(self.TextName , UIHelper.GBKToUTF8(tPlayerData.szName))
        UIHelper.SetString(self.TextMoney , tPlayerData.nMoney)
        if tPlayerData.tPlayer then
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, tPlayerData.tPlayer.dwMiniAvatarID, self.SFXPlayerIcon, 
            self.AnimatePlayerIcon , tPlayerData.tPlayer.nRoleType , tPlayerData.tPlayer.dwForceID)
        end
    end

    UIHelper.SetVisible(self._rootNode  , tPlayerData.nReady ~= DdzPokerData.TABLE_SLOT_STATE.LIVE)
end


function UIDdzPokerPlayerHeadInfo:UpdateSettlementHeadInfo(tPlayerData)
    UIHelper.SetVisible(self.ImgDizhu ,DdzPokerData.DataModel.nDiZhuIndex == tPlayerData.nIndex ) 
    UIHelper.SetString(self.TextName , UIHelper.GBKToUTF8(tPlayerData.szName))
    UIHelper.SetString(self.LabelMoney , self:GetMoneyStr(tPlayerData.nDisMoney))
    UIHelper.SetString(self.LabelBeishu , tPlayerData.nDoubleTimes .. g_tStrings.STR_DDZ_TIMES)
    
    if tPlayerData.tPlayer then
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, tPlayerData.tPlayer.dwMiniAvatarID, self.SFXPlayerIcon, 
        self.AnimatePlayerIcon , tPlayerData.tPlayer.nRoleType , tPlayerData.tPlayer.dwForceID)
    end
end

function UIDdzPokerPlayerHeadInfo:UpdatePlayerState(tPlayerData , bIsDown)
    UIHelper.SetVisible(self.ImgReady , tPlayerData.nReady == DdzPokerData.TABLE_SLOT_STATE.READY)
    UIHelper.SetVisible(self.ImgMPReady , tPlayerData.nReady == DdzPokerData.TABLE_SLOT_STATE.MINGPAI_READY)
    local settlement = DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_SETTLEMENT and DdzPokerData.DataModel.bStartGame
    UIHelper.SetVisible(self.ImgVictory , tPlayerData.bIsWiner and settlement)
    UIHelper.SetVisible(self.ImgLose , (not tPlayerData.bIsWiner) and settlement)
    UIHelper.SetVisible(self.ImgQuit , not bIsDown and tPlayerData.nReady == DdzPokerData.TABLE_SLOT_STATE.LEAVE)
end

function UIDdzPokerPlayerHeadInfo:UpdateJiaBeiState(tPlayerData)

    UIHelper.SetVisible(self.ImgJiaBei , tPlayerData.nDoubleType == DdzPokerData.DOUBLESTATE.JIABEI)
    UIHelper.SetVisible(self.ImgSuperJiaBei , tPlayerData.nDoubleType == DdzPokerData.DOUBLESTATE.SUPER_JIABEI)
    if tPlayerData.nDoubleType == DdzPokerData.DOUBLESTATE.JIABEI then
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szJiaBei"))
    end
    if tPlayerData.nDoubleType == DdzPokerData.DOUBLESTATE.SUPER_JIABEI then
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szSuperJiaBei"))
    end
end

function UIDdzPokerPlayerHeadInfo:UpdateDiZhuState(bIsDizhu)
    UIHelper.SetVisible(self.ImgDizhu ,bIsDizhu) 
end


function UIDdzPokerPlayerHeadInfo:UpdateMoney(nMoney)
    UIHelper.SetString(self.TextMoney , nMoney)
end

function UIDdzPokerPlayerHeadInfo:GetMoneyStr(nDisMoney)
	local szMoney = ""
	if nDisMoney > 0 then
		szMoney = g_tStrings.STR_ADD_SYMBOL .. tostring(nDisMoney)
	else
		szMoney = tostring(nDisMoney)
	end
	return szMoney
end


function UIDdzPokerPlayerHeadInfo:UpdatePlayerHostingSfx(bIsHosting)
    UIHelper.SetVisible(self.AniTG , bIsHosting)
    -- if bIsHosting then
    --     UIHelper.PlaySFX(self.AniTG)
    -- end
end

function UIDdzPokerPlayerHeadInfo:GetDdzRecordData(dwPlayerID)
	local player
	local playerOwn = GetClientPlayer()
	if playerOwn.dwID == dwPlayerID then
		player = playerOwn
	else
		player = GetPlayer(dwPlayerID)
	end
	
	if not player then
		return
	end
	local tData = {
		nCurContinueWin = 0, 
		nHisContinueWin = 0,  
		nHisMatchCount  = 0,
		nHisWinCount  = 0,
		nHisMaxCash  = 0,
	}

	tData.nCurContinueWin  = player.GetRemoteArrayUInt(DDZ_CONST_DATAS_REMOTE_ID, REMOTE_DOUDIZHU_DATAS.CUR_CONTINUE_WIN_COUNT[1], REMOTE_DOUDIZHU_DATAS.CUR_CONTINUE_WIN_COUNT[2]) or 0
	tData.nHisContinueWin = player.GetRemoteArrayUInt(DDZ_CONST_DATAS_REMOTE_ID, REMOTE_DOUDIZHU_DATAS.HISTORY_CONTINUE_WIN_COUNT[1], REMOTE_DOUDIZHU_DATAS.HISTORY_CONTINUE_WIN_COUNT[2]) or 0
	tData.nHisMatchCount = player.GetRemoteArrayUInt(DDZ_CONST_DATAS_REMOTE_ID, REMOTE_DOUDIZHU_DATAS.HISTORY_MATCH_COUNT[1], REMOTE_DOUDIZHU_DATAS.HISTORY_MATCH_COUNT[2]) or 0
	tData.nHisWinCount = player.GetRemoteArrayUInt(DDZ_CONST_DATAS_REMOTE_ID, REMOTE_DOUDIZHU_DATAS.HISTORY_WIN_COUNT[1], REMOTE_DOUDIZHU_DATAS.HISTORY_WIN_COUNT[2]) or 0
	tData.nHisMaxCash = player.GetRemoteArrayUInt(DDZ_CONST_DATAS_REMOTE_ID, REMOTE_DOUDIZHU_DATAS.HISTORY_MAX_CASH[1], REMOTE_DOUDIZHU_DATAS.HISTORY_MAX_CASH[2]) or 0
	return tData
end

return UIDdzPokerPlayerHeadInfo