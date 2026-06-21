-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerView
-- Date: 2023-08-02 11:04:36
-- Desc: 斗地主界面
-- ---------------------------------------------------------------------------------

local UIDdzPokerView = class("UIDdzPokerView")
local m_nApplyFellowshipCardType = 6
local DataModel = {}
local tMessageType2FunName = {
	[DDZ_PLAYER_OPERATE_LAIZI_TIAN] = {szFunName = "SyncTianLaiZi", szDes = "天癞子"},
	[DDZ_PLAYER_OPERATE_LAIZI_DI] = {szFunName = "SyncDiLaiZi", szDes = "地癞子"},
	[DDZ_PLAYER_OPERATE_PLAYERHAND] = {szFunName = "SyncHandCard", szDes = "玩家初始手牌"},
	[DDZ_PLAYER_OPERATE_SYN_CASH] = {szFunName = "SyncMoney", szDes = "同步钱数"},
	[DDZ_PLAYER_OPERATE_JUMP] = {szFunName = "PassCard", szDes = "过牌"},
	[DDZ_PLAYER_OPERATE_CS_SEND] = {szFunName = "PlayCard", szDes = "出牌，跟牌值"},
	[DDZ_PLAYER_OPERATE_CUR_CARD] = {szFunName = "SyncPlayCard", szDes = "同步出牌值，服务器下发消息"},
	[DDZ_PLAYER_OPERATE_SET_CUR_PLAYER] = {szFunName = "SyncPrePlayer", szDes = "设置下一个操作者，playerID"},
	[DDZ_PLAYER_OPERATE_TABLE_END_ROUND] = {szFunName = "NextPlayerFree", szDes = "本轮出牌结束，下家可以自由打牌（1，下个出牌的玩家)"},
	[DDZ_PLAYER_OPERATE_TIME] = {szFunName = "SyncCountDown", szDes = "操作倒计时，跟时间"},
	[DDZ_PLAYER_OPERATE_ERROR] = {szFunName = "SyncError", szDes = "发送错误操作的操作码"},
	[DDZ_PLAYER_OPERATE_CHAIRMAN_TYPE] = {szFunName = "CallDiZhu", szDes = "玩家叫地主(1叫，2抢，5不叫)，客户端上行消息"},
	[DDZ_PLAYER_OPERATE_SET_CHAIRMAN] = {szFunName = "SyncDiZhu", szDes = "同步地主（playerID，地主类型：1叫、2抢、3叫地主结束、4抢地主结束、5不叫、6不抢），服务器下发消息"},
	[DDZ_PLAYER_OPERATE_DOUBLE_TYPE] = {szFunName = "CallDouble", szDes = "玩家加倍类型上传消息（1普通加倍，2超级加倍，3不加倍），客户端上行消息"},
	[DDZ_PLAYER_OPERATE_BOTTOM_CARD] = {szFunName = "SyncThreeCard", szDes = "广播底牌"},
	[DDZ_PLAYER_OPERATE_DOUBLE_PLAYER] = {szFunName = "SyncDouble", szDes = "玩家加倍广播（playerID，加倍类型），服务器下发消息"},
	[DDZ_PLAYER_OPERATE_CAERDS_TIMES] = {szFunName = "SyncDoubleTimes", szDes = "牌局番数消息（番数类型、番数增加值、总番数值）"},
	[DDZ_PLAYER_OPERATE_TABLE_STATE_BEGIN] = {szFunName = "SyncTableState", szDes = "同步牌桌开启状态"},
	[DDZ_PLAYER_OPERATE_TABLE_STATE_END] = {szFunName = "SyncTableStateEnd", szDes = "同步牌桌结束状态"},
	[DDZ_PLAYER_OPERATE_SET_AGENT] = {szFunName = "SyncHosting", szDes = "设置挂机"},
	[DDZ_PLAYER_OPERATE_GET_READY] = {szFunName = "SetPlayerReady", szDes = "玩家点准备（DDZ_CONST_TABLE_STATE_END_GAME状态才生效）"},
	[DDZ_PLAYER_OPERATE_MINGPAI] = {szFunName = "SetPlayerMingPai", szDes = "玩家明牌，客户端上行消息"},
	[DDZ_PLAYER_OPERATE_MINGPAI_END] = {szFunName = "SyncMingPai", szDes = "玩家明牌广播，服务器下发消息"},
	[DDZ_PLAYER_OPERATE_WAIT] = {szFunName = "", szDes = "第一轮等待出牌读秒读完"},
	[DDZ_PLAYER_OPERATE_DEBUG_SET_PLAYER_DATA] = {szFunName = "", szDes = "设置玩家数据"},
	[DDZ_PLAYER_OPERATE_SET_ACCENT] = {szFunName = "SyncAccent", szDes = "设置玩家口音"},
	[DDZ_PLAYER_OPERATE_OUT_OF_MONEY] = {szFunName = "SyncFail", szDes = "认输"},
	[DDZ_PLAYER_OPERATE_WINNER] = {szFunName = "SyncWin", szDes = "获胜"},
	[DDZ_PLAYER_OPERATE_CLOSE_UI] = {szFunName = "SyncOpenUI", szDes = "关闭斗地主UI"},
	[DDZ_PLAYER_OPERATE_ENDINNG_SPRING] = {szFunName = "SyncSpring",szDes = "春天结算"},
}

local tType2Sfx = {
	[DDZ_CONST_CARD_TYPE_SINGLE_LINE] = "AniSZ",
	[DDZ_CONST_CARD_TYPE_DOUBLE_LINE] = "AniLD",
	[DDZ_CONST_CARD_TYPE_TRIPLE_LINE] = "AniLD",
	[DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE] = "AniFJ",
	[DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE] = "AniFJ",
	[DDZ_CONST_CARD_TYPE_BOMB4] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB4_BIG] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB5] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB6] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB7] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB8] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB9] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB10] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB11] = "AniZD",
	[DDZ_CONST_CARD_TYPE_BOMB12] = "AniZD",
	[DDZ_CONST_CARD_TYPE_ROCKET] = "AniWZ",
}

local tType2Sound = {
	[DDZ_CONST_CARD_TYPE_SINGLE_LINE] = "szShunZi",
	[DDZ_CONST_CARD_TYPE_DOUBLE_LINE] = "szLianDui",
	[DDZ_CONST_CARD_TYPE_TRIPLE_LINE] = "szLianDui",
	[DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE] = "szFeiJi",
	[DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE] = "szFeiJi",
	[DDZ_CONST_CARD_TYPE_BOMB4] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB4_BIG] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB5] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB6] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB7] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB8] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB9] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB10] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB11] = "szBoom",
	[DDZ_CONST_CARD_TYPE_BOMB12] = "szBoom",
	[DDZ_CONST_CARD_TYPE_ROCKET] = "szRocket",
}

local HOSTING_STATE = {
	HOSTING = 1,
	CANCEL = 0,
}
local m_bIsHostingState = false
local m_bInReconnect= false
local LAIZI_CONFIRM_TIME = 1.8

local m_nQuestID = 21924

function UIDdzPokerView:OnEnter(tbPokerData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbPokerData = tbPokerData
    self:UpdateInfo()
end

function UIDdzPokerView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
	   	UIHelper.ShowConfirm(g_tStrings.STR_DDZ_CLOSE_PANEL, function ()
			self:Close()
	   	end)
    end)

    UIHelper.BindUIEvent(self.ToggleAutoPlay, EventType.OnClick, function ()
        if m_bIsHostingState then
            self:SetHosting(HOSTING_STATE.CANCEL)
        else
            self:SetHosting(HOSTING_STATE.HOSTING)
        end
        m_bIsHostingState = not m_bIsHostingState
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnSequence, EventType.OnClick, function ()
        if DdzPokerData.bLockHandCard then
            return
        end
        self.bIsAsc = not self.bIsAsc
		self:DownHandCards()
		DdzPokerData.ChangeCmp(self.bIsAsc)
		self.script_downPlayer:UpdateHandCards()
	    self:UpdateCmpButton()
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

	UIHelper.BindUIEvent(self.BtnRulePop, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelDdzRulePop)
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

	UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
		ChatHelper.Chat(UI_Chat_Channel.Near)
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

	UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function ()
		ShopData.OpenSystemShopGroup(1, 1242)
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)
end

function UIDdzPokerView:RegEvent()
    Event.Reg(self, DdzPokerData.tbEventID.OnChangeDdzRule, function (nRuleNum)
        if nRuleNum ~= DdzPokerData.DataModel.tRule.nRuleNum then
            DdzPokerData.InitRuleData(nRuleNum)
            self:UpdateRuleText()
            self:InitShowRule()
            self:UpdateShowRule(true)
        end
    end)
    Event.Reg(self, DdzPokerData.tbEventID.OnAddPlayer, function (tPlayerInfo)
        local bIsMy = false
        for k, v in pairs(tPlayerInfo) do
            if v[1] == UI_GetClientPlayerID() then
                bIsMy = true
            end
            PeekPlayerRemoteData(v[1], DDZ_CONST_DATAS_REMOTE_ID)
            if not DdzPokerData.DataModel.bStartGame then
                DdzPokerData.ClearPlayerData(k)
            end
            if v[2] == DdzPokerData.TABLE_SLOT_STATE.MINGPAI_READY then
                self.script_totalRuleTip:PlayTimesTipAni("MingPaiReady")
            end
        end
        DdzPokerData.InitGameData(tPlayerInfo)
        DdzPokerData.InitSinglePlayerReadyState(tPlayerInfo)
        DdzPokerData.ClearWinnerIndex()
        if not bIsMy then
            DdzPokerData.ApplyPlayerCardInfo(tPlayerInfo)
        else
            self:UpdateReadyButtom()
            DdzPokerData.InitDownPlayerCardInfo()
        end
        self:UpdatePlayerState()
        if DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_END_GAME then
            DdzPokerData.SyncGameEndMoney()
        end
        self:UpdatePlayerMoney()
    end)

	Event.Reg(self, "FELLOWSHIP_ROLE_ENTRY_UPDATE" , function ()
		DdzPokerData.InitLeftOrRightPlayerCardInfo()
		self:InitPlayerInfo()
		self:UpdatePlayerState()
    end)

    Event.Reg(self, "MINIGAME_OPERATE" , function ()
        local nGameType, nPlayerID, nOperationType = arg0, arg1, arg2
		if nGameType ~= 2 or not nOperationType then
			return
		end
		local tData = tMessageType2FunName[nOperationType]
		if not tData then
			return
		end
		if arg2 == DDZ_PLAYER_OPERATE_TABLE_STATE_BEGIN then
			DdzPokerData.DataModel.nTableState = arg3
		end
		if tData.szFunName and self[tData.szFunName] then
			self[tData.szFunName](self,arg1, arg2, arg3, arg4, arg5, arg6, arg7)
		end
    end)

	Event.Reg(self, "KG3D_PLAY_ANIMAION_FINISHED" , function ()
        self:PlayDiZhuSfxFinish()
    end)

    Event.Reg(self, DdzPokerData.tbEventID.OnPlayerLeave , function (nPlayerIndex)
        if DdzPokerData.DataModel.bStartGame then
            return
        end
        DdzPokerData.LeavePlayer(nPlayerIndex)
        self:InitPlayerInfo()
		self:UpdatePlayerState()
    end)

	Event.Reg(self, DdzPokerData.tbEventID.OnClickCombiChoose , function (tCardInfo)
		tCardInfo.nCmpNum = nil
		self:PlayCardSuccess(tCardInfo)
		self:UpdateCardChoose(false)
		DdzPokerData.bLockHandCard = false
    end)

	Event.Reg(self, DdzPokerData.tbEventID.OnPlay , function (tCardInfo)
		local szStartNum = ""
		for i = 1, DdzPokerData.MAX_PLAYER_NUM do
			local tPlayerData = DdzPokerData.GetPlayerDataByIndex(i)
			szStartNum = szStartNum .. (tPlayerData.nReady == DdzPokerData.TABLE_SLOT_STATE.MINGPAI_READY and 1 or 0)
		end
		szStartNum = DdzPokerData.DataModel.tRule.nRuleNum .. szStartNum
		self:SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_COST_OPERATE, DDZ_PLAYER_OPERATE_RESTART, tonumber(szStartNum))
    end)

	Event.Reg(self, "QUEST_FINISHED" , function (dwQuestID)
		if dwQuestID == m_nQuestID then
			self:UpdateTaskTips()
		end
    end)

	Event.Reg(self, "QUEST_DATA_UPDATE" , function (nQuestIndex)
		local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID and nQuestID == m_nQuestID then
			self:UpdateTaskTips()
        end
    end)
end

function UIDdzPokerView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIDdzPokerView:GetGameMgr()
    if not self.MiniGameMgr then
        self.MiniGameMgr = GetMiniGameMgr()
    end
    return self.MiniGameMgr
end

function UIDdzPokerView:SendServerOperate(nOperateType, nValue1, nValue2, nValue3, nValue4, nValue5, nValue6)

	self:GetGameMgr().Operate(nOperateType, nValue1 or 0, nValue2 or 0, nValue3 or 0, nValue4 or 0, nValue5 or 0, nValue6 or 0)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIDdzPokerView:UpdateInfo()
    SoundMgr.PlayUIBgMusic(DdzPokerData.GetSoundPath("szBGM"))
	-- if not bDisableSound then
	-- 	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	-- end
    self.bIsAsc = true
	m_bIsHostingState = false
    self.script_operations = UIHelper.GetBindScript(self.WidgetOperations)
    self.script_downPlayer = UIHelper.GetBindScript(self.WidgetPlayerDown)
    self.script_leftPlayer = UIHelper.GetBindScript(self.WidgetPlayerLeft)
    self.script_rightPlayer = UIHelper.GetBindScript(self.WidgetPlayerRight)
    self.script_downPlayer:SetDirection(DdzPokerData.tPlayerDirection.Down)
    self.script_leftPlayer:SetDirection(DdzPokerData.tPlayerDirection.Left)
    self.script_rightPlayer:SetDirection(DdzPokerData.tPlayerDirection.Right)
    self.script_totalRuleTip = UIHelper.GetBindScript(self.WidgetTotal)
	--self.script_ItemHint = UIHelper.AddPrefab(PREFAB_ID.WidgetGetItemHintArea , self.WidgetRewardShow)

    self.tbPlayerScriptMap =
    {
        [DdzPokerData.tPlayerDirection.Down] =  self.script_downPlayer,
        [DdzPokerData.tPlayerDirection.Left] =  self.script_leftPlayer,
        [DdzPokerData.tPlayerDirection.Right] =  self.script_rightPlayer,
    }
	self.script_cardCombiChoose = UIHelper.GetBindScript(self.WidgetCardCombiChoose)
    self:InitData()
    self:ApplyPlayerCardInfo(self.tbPokerData.tPlayerInfo)
    self:ApplyPlayerRecord(self.tbPokerData.tPlayerInfo)
    self:UpdateCardNum()
    self:UpdateAllHandCards()
    self:UpdateAllPassedCards()
    self.script_operations:Init(self)
    self:InitPlayerInfo()
    self:UpdatePlayerState()
    self:UpdateJiaBeiState()
    self:UpdateRuleText()
    self:UpdateCardCount()
    self:UpdateDiCard()
    self:UpdateCmpButton()
    self:UpdateLaiziState(false)
    self:UpdateDiCardTip(false)
    self:SetCardCountVisible(false)
    self:InitDoubleTimes()
    self:UpdateDiZhuPlayingTip(false)
    self:UpdateJiaBeiPlayingTip(false)
    self:UpdateYaoBuQiPlayingTip()
    self:EnableHostingCheck(false)
    if DdzPokerData.DataModel.bStartGame then
		self:Reconnect()
	else
		self:UpdateReadyButtom()
	end

    UIHelper.SetString(self.LabelTitle , DdzPokerData.szTitle)


    Timer.AddCycle(self , 0.5 , function ()
        local nCountDown = DdzPokerData.DataModel.tCountDown[1]
        if nCountDown then
            if self:GetGameMgr() then
                local nCurrTime = self:GetGameMgr().GetGameTime()
                if nCurrTime and nCountDown> nCurrTime and DdzPokerData.DataModel.bStartGame then
                    DdzPokerData.DataModel.nDiffTime = nCountDown - nCurrTime
                    self:InitTimer()
                    self:UpdateTimer(true)
                else
                    self:UpdateTimer(false)
                    if DataModel.bStartGame then
                         self:HideOp()
                    end
                    DdzPokerData.DelCountDown()
                    self:UpdateCardChoose(false)
                    self:PlayCardTimeEnd()
                    DdzPokerData.bLockHandCard = false
                end
            end
        else
            self:UpdateTimer(false)
        end
    end)

	self:UpdateTaskTips()
	self:UpdateSkin()
end

function UIDdzPokerView:UpdateSkin()
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


function UIDdzPokerView:UpdateTaskTips()
	local bIsProgressing = QuestData.IsProgressing(m_nQuestID)
	UIHelper.SetVisible(self.WidgetTaskTips , bIsProgressing)

	if bIsProgressing then

		local questTrace = g_pClientPlayer.GetQuestTraceInfo(m_nQuestID)
		local szTargetPro = ""
		for k, v in pairs(questTrace.quest_state) do
	
			v.have = math.min(v.have, v.need)
			szTargetPro = v.have.."/"..v.need
		end

		UIHelper.SetRichText(self.RichTextInfo , string.format("<color=#aed9e0>%s：%s</c>",g_tStrings.STR_QUEST_FINISH , szTargetPro)) 
	end
end

function UIDdzPokerView:Close(bMini , bDisableSound)
	if not bMini then
		DdzPokerData.SendReadyStartGame(DdzPokerData.TABLE_SLOT_STATE.LEAVE)
	end
	DdzPokerData.UnInit()
    SoundMgr.StopUIBgMusic(DdzPokerData.GetSoundPath("szBGM"))
    SoundMgr.StopSound()

	if not bMini then
		RemoteCallToServer("On_HomeLand_CloseDdz")
	end
	if not bDisableSound then
		--PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
    Timer.DelAllTimer(self)
    UIMgr.Close(self)
end

function UIDdzPokerView:InitData()
    self.tbLeftAndRightHandCardCells = nil
    DdzPokerData.DataModleInit(self.tbPokerData.nSkinID)
    DdzPokerData.DataModel.bStartGame = self.tbPokerData.bStartGame
    DdzPokerData.DataModel.nFurnitureID = self.tbPokerData.nFurnitureID
    DdzPokerData.InitDirection(self.tbPokerData.tPlayerInfo)
	DdzPokerData.InitGameData(self.tbPokerData.tPlayerInfo)
	DdzPokerData.InitDownPlayerCardInfo()
	DdzPokerData.InitPlayerReadyState(self.tbPokerData.tPlayerInfo)
	DdzPokerData.InitRuleData(self.tbPokerData.nRuleNum)
    DdzPokerData.InitCardCount()
    DdzPokerData.SetCmp(true)
    self.szIconFramePath = DdzPokerData.SkinImageAtlas[self.tbPokerData.nSkinID]
end

function UIDdzPokerView:ApplyPlayerCardInfo(tPlayerInfo)
    DdzPokerData.ApplyPlayerCardInfo(tPlayerInfo)
end

function UIDdzPokerView:ApplyPlayerRecord(tPlayerInfo)
	for i = 1, DdzPokerData.MAX_PLAYER_NUM do
		if tPlayerInfo[i] then
            PeekPlayerRemoteData(tPlayerInfo[i][1], DDZ_CONST_DATAS_REMOTE_ID)
		end
	end
end

function UIDdzPokerView:InitCardNum()
    self.script_leftPlayer:SetCardNum()
    self.script_rightPlayer:SetCardNum()
end

function UIDdzPokerView:UpdateCardNum()
    self.script_leftPlayer:UpdateCardNum()
    self.script_rightPlayer:UpdateCardNum()
end
-- ----------------------------------------------------------
-- 更新手牌
-- ----------------------------------------------------------
function UIDdzPokerView:UpdateAllHandCards()
    self.script_downPlayer:UpdateHandCards()
    self.script_leftPlayer:UpdateHandCards()
    self.script_rightPlayer:UpdateHandCards()
end
-- ----------------------------------------------------------
-- 更新出牌
-- ----------------------------------------------------------
function UIDdzPokerView:UpdateAllPassedCards()
    self.script_downPlayer:UpdatePassedCards()
    self.script_leftPlayer:UpdatePassedCards()
    self.script_rightPlayer:UpdatePassedCards()
end

function UIDdzPokerView:UpdatePassedCards(szDirection)
    if szDirection == DdzPokerData.tPlayerDirection.Left then
        self.script_leftPlayer:UpdatePassedCards()
    elseif szDirection == DdzPokerData.tPlayerDirection.Right then
        self.script_rightPlayer:UpdatePassedCards()
    else
        self.script_downPlayer:UpdatePassedCards()
    end
end

function UIDdzPokerView:InitPlayerInfo()
    self.script_downPlayer:UpdatePlayerInfo()
    self.script_leftPlayer:UpdatePlayerInfo()
    self.script_rightPlayer:UpdatePlayerInfo()
end

function UIDdzPokerView:UpdatePlayerState()
    self.script_downPlayer:UpdatePlayerState()
    self.script_leftPlayer:UpdatePlayerState()
    self.script_rightPlayer:UpdatePlayerState()
end

function UIDdzPokerView:UpdateJiaBeiState()
    self.script_downPlayer:UpdateJiaBeiState()
    self.script_leftPlayer:UpdateJiaBeiState()
    self.script_rightPlayer:UpdateJiaBeiState()
end

function UIDdzPokerView:UpdateRuleText()
    self.script_totalRuleTip:UpdateRuleText()
end

function UIDdzPokerView:UpdateCardCount()
    self.script_totalRuleTip:UpdateCardCount()
end

function UIDdzPokerView:UpdateDiCard()
    self.script_totalRuleTip:UpdateDiCard()
end

function UIDdzPokerView:UpdateCmpButton()
    self.script_totalRuleTip:UpdateCmpButton()
end

function UIDdzPokerView:UpdateLaiziState(bVisible)
    self.script_totalRuleTip:UpdateLaiziState(bVisible)
end

function UIDdzPokerView:UpdateDiCardTip(bVisible)
    if g_tStrings.STR_DDZ_BOTTOMTYPE_TIP[DdzPokerData.DataModel.nBottomType] then
        self.script_totalRuleTip:UpdateDiCardTip(bVisible)
	else
		self.script_totalRuleTip:UpdateDiCardTip(false)
	end
end

function UIDdzPokerView:SetCardCountVisible(bVisible)
    self.script_totalRuleTip:SetCardCountVisible(bVisible)
end

function UIDdzPokerView:InitDoubleTimes()
    self.script_totalRuleTip:InitDoubleTimes()
end

function UIDdzPokerView:UpdateDiZhuPlayingTip(bShow)
    for i = 1, DdzPokerData.MAX_PLAYER_NUM, 1 do
        local szDirection = DdzPokerData.DataModel.tIndex2Direction[i]
        if szDirection == DdzPokerData.tPlayerDirection.Left then
            self.script_leftPlayer:ShowDizhuPlayingTip(bShow)
        elseif szDirection == DdzPokerData.tPlayerDirection.Right then
            self.script_rightPlayer:ShowDizhuPlayingTip(bShow)
        else
            self.script_downPlayer:ShowDizhuPlayingTip(bShow)
        end
    end
end

function UIDdzPokerView:UpdateJiaBeiPlayingTip(bShow)
    for i = 1, DdzPokerData.MAX_PLAYER_NUM, 1 do
        local szDirection = DdzPokerData.DataModel.tIndex2Direction[i]
        if szDirection == DdzPokerData.tPlayerDirection.Left then
            self.script_leftPlayer:ShowJiaBeiPlayingTip(bShow)
        elseif szDirection == DdzPokerData.tPlayerDirection.Right then
            self.script_rightPlayer:ShowJiaBeiPlayingTip(bShow)
        else
            self.script_downPlayer:ShowJiaBeiPlayingTip(bShow)
        end
    end
end

function UIDdzPokerView:UpdateYaoBuQiPlayingTip()
    for i = 1, DdzPokerData.MAX_PLAYER_NUM, 1 do
        local szDirection = DdzPokerData.DataModel.tIndex2Direction[i]
        if szDirection == DdzPokerData.tPlayerDirection.Left then
            self.script_leftPlayer:ShowYaoBuQiPlayingTip()
        elseif szDirection == DdzPokerData.tPlayerDirection.Right then
            self.script_rightPlayer:ShowYaoBuQiPlayingTip()
        else
            self.script_downPlayer:ShowYaoBuQiPlayingTip()
        end
    end
end

function UIDdzPokerView:EnableHostingCheck(bEnable)
	UIHelper.SetEnable(self.ToggleAutoPlay , bEnable)
end

function UIDdzPokerView:UpdateReadyButtom()
    self.script_operations:UpdateReadyButtom()
end

function UIDdzPokerView:UpdatePlayerMoney()
    self.script_downPlayer:UpdateMoney(DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Down].nMoney)
    self.script_leftPlayer:UpdateMoney(DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Left].nMoney)
    self.script_rightPlayer:UpdateMoney(DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Right].nMoney)
end

function UIDdzPokerView:HideOp()
    self.script_operations:HideOp()
end

function UIDdzPokerView:DownHandCards()
    self.script_downPlayer:UpdateCardClick(true)
end

function UIDdzPokerView:UpdateBuchuTip(bShow)
    self.script_operations:UpdateBuchuTip(bShow)
end

function UIDdzPokerView:PlayCardFail()
	self:UpdateBuchuTip(true)
	self:DownHandCards()
end

function UIDdzPokerView:PlayCardSuccess(tCards)
	self:HideOp()
	self:UpdateBuchuTip(false)
	local tReturn = DDZ_UICards2Server(tCards)
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DDZ_PLAYER_OPERATE_CS_SEND, tReturn[1], tReturn[2], tReturn[3], tReturn[4], tReturn[5])
end

function UIDdzPokerView:InitCardChoose(tInfo)
	self.script_cardCombiChoose:InitCardChoose(tInfo)
end

function UIDdzPokerView:UpdateCardChoose(bShow)
	self.script_cardCombiChoose:SetVisible(bShow)
end

function UIDdzPokerView:PlayPassedCardsAni(szDirection, fnAniEnd)

end

function UIDdzPokerView:UpdateChuPaiButton()
	if not DdzPokerData.IsMyRound() then
		return
	end
	local tPlayerData = DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Down]
	if DdzPokerData.IsFreePlay() then
		self.script_operations:ShowFreeChuButton()
		self.script_operations:UpdateBuchuTip(false)
	elseif tPlayerData.tUITipCards and (not table_is_empty(tPlayerData.tUITipCards)) then
		self.script_operations:ShowNextChuButton()
		self.script_operations:UpdateBuchuTip(false)
	else
		self.script_operations:ShowBuChuButton()
		self.script_operations:UpdateBuchuTip(true)
	end
end

function UIDdzPokerView:UpdateLaiziCard(bShow)
	UIHelper.SetVisible(self.WidgetShowLaiziCard , bShow)
end

function UIDdzPokerView:InitDiCard()
	self.script_totalRuleTip:InitDiCard()
end

function UIDdzPokerView:InitTableThreeCard()
	self.script_totalRuleTip:InitTableThreeCard()
end

function UIDdzPokerView:UpdateTableThreeCard(bShow)
    self.script_totalRuleTip:UpdateTableThreeCard(bShow)
end

function UIDdzPokerView:UpdateHosting()
    local tPlayerData = DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Down]
	if tPlayerData.bIsHosting then
		self:HideOp()
		UIHelper.SetSelected(self.ToggleAutoPlay , true)
		m_bIsHostingState = true
        --self:EnableHostingCheck(true)
	else
        local nTableState = DdzPokerData.DataModel.nTableState
		if tPlayerData.bChangeHosting then
			if nTableState == DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN then
				if tPlayerData.nState == DdzPokerData.PLAYER_STATE.CAN_CALL then
					self.script_operations:ShowDemandButton()
				end
			elseif nTableState == DDZ_CONST_TABLE_STATE_SET_CHAIRMAN then
				if tPlayerData.nState == DdzPokerData.PLAYER_STATE.CAN_QIANG then
					self.script_operations:ShowGrabButton()
				end
			elseif nTableState == DDZ_CONST_TABLE_STATE_DOUBLE then
				if tPlayerData.nDoubleType == 0 then
                    self:ShowJiaBeiButton()
				end
			elseif nTableState == DDZ_CONST_TABLE_STATE_SHUFFLE_MINGPAI then
				if not tPlayerData.bIsMingPai then
                    self:ShowMingPiaButton()
				end
			elseif nTableState == DDZ_CONST_TABLE_STATE_WAIT_CS_SEND then
				self:UpdateChuPaiButton()
			elseif nTableState == DDZ_CONST_TABLE_STATE_END_GAME then
				self:UpdateReadyButtom()
			end
			UIHelper.SetSelected(self.ToggleAutoPlay , false)
			m_bIsHostingState = false
		end
	end
    self:UpdatePlayerHostingSfx()
end

function UIDdzPokerView:UpdatePlayerHostingSfx()
    self.script_downPlayer:UpdatePlayerHostingSfx()
    self.script_leftPlayer:UpdatePlayerHostingSfx()
    self.script_rightPlayer:UpdatePlayerHostingSfx()
end

function UIDdzPokerView:PlayTianLaiziSfx()
	SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szLaizi"))
	-- 播放天癞子特效
	self:InitLaiziCard(DdzPokerData.LaiZiState.Tian)
	-- 播放完才显示
    self:PlaySfx("AniLaiZiTian")
	Timer.Add(self , LAIZI_CONFIRM_TIME , function()
		self:UpdateLaiziCard(true)
	end)
end

function UIDdzPokerView:PlayDiLaiziSfx()
	-- 播放地癞子特效
	local hSfxCell
    if DdzPokerData.IsSingleLaiziTable() then
		hSfxCell = "AniLaiZi"
		self:InitLaiziCard(DdzPokerData.LaiZiState.Single)
	else
		hSfxCell = "AniLaiZiDi"
		self:InitLaiziCard(DdzPokerData.LaiZiState.Di)
	end
	SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szLaizi"))
	-- 播放完才显示
	self:PlaySfx(hSfxCell)
	Timer.Add(self , LAIZI_CONFIRM_TIME , function()
		self:UpdateLaiziCard(true)
	end)
end

function UIDdzPokerView:InitLaiziCard(eState)
    self.script_showLaiziCard = UIHelper.GetBindScript(self.WidgetShowLaiziCard)
    self.script_showLaiziCard:InitLaiziCard(eState)
end

function UIDdzPokerView:InitLaiziIcon()
    self.script_totalRuleTip:InitLaiziIcon()
end

function UIDdzPokerView:ThreeCardstoDown()
    self.script_downPlayer:ThreeCardstoDown()
end

function UIDdzPokerView:InitShowRule()
    self.script_totalRuleTip:InitShowRule()
end

function UIDdzPokerView:UpdateShowRule(bShow)
    self.script_totalRuleTip:UpdateShowRule(bShow)
end

function UIDdzPokerView:UpdateDiZhuIcon()
    for i = 1, DdzPokerData.MAX_PLAYER_NUM do
		local szDirection = DdzPokerData.DataModel.tIndex2Direction[i]
        self.tbPlayerScriptMap[szDirection]:UpdateDiZhuState(i == DdzPokerData.DataModel.nDiZhuIndex)
	end
end

function UIDdzPokerView:PlayCardCountSfx()
    self:UpdateCardCount()
	self:SetCardCountVisible(true)
end


function UIDdzPokerView:ShowJiaBeiButton()
    self.script_operations:ShowJiaBeiButton()
end

function UIDdzPokerView:ShowMingPiaButton()
    self.script_operations:ShowMingPiaButton()
end

function UIDdzPokerView:GameOver()
    self:HideOp()
	SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szShowCard"))
	DdzPokerData.GameOver()
	self:UpdateCardNum(false)
	self:UpdateAllHandCards()
	self:UpdatePlayerState()
end

function UIDdzPokerView:InitTimer()
    if not self.tbTimerScript then
        self.tbTimerScript = {}
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Left] = UIHelper.AddPrefab(PREFAB_ID.WidgetTimer , self.WidgetTimerLeft)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Right] = UIHelper.AddPrefab(PREFAB_ID.WidgetTimer , self.WidgetTimerRight)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Down] = UIHelper.AddPrefab(PREFAB_ID.WidgetTimer , self.WidgetTimerDown)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Common] = UIHelper.AddPrefab(PREFAB_ID.WidgetTimer , self.WidgetTimerCommon)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Left]:SetDirection(DdzPokerData.tPlayerDirection.Left)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Right]:SetDirection(DdzPokerData.tPlayerDirection.Right)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Down]:SetDirection(DdzPokerData.tPlayerDirection.Down)
        self.tbTimerScript[DdzPokerData.tPlayerDirection.Common]:SetDirection(DdzPokerData.tPlayerDirection.Common)
    end
    for k, v in pairs(self.tbTimerScript) do
        v:UpdateTimer()
    end
	self.script_cardCombiChoose:UpdateTimer()
end

function UIDdzPokerView:UpdateTimer(bShow)
    if not self.tbTimerScript then
        self:InitTimer()
    end
    local tCountDown = DdzPokerData.DataModel.tCountDown
	local szDirection
	for i = 1, DdzPokerData.MAX_PLAYER_NUM do
		szDirection = DdzPokerData.DataModel.tIndex2Direction[i]
        self.tbTimerScript[szDirection]:SetVisible(tCountDown[2] == i and bShow)
	end

	if tCountDown[2] ~= 0 and DdzPokerData.DataModel.nDiffTime == DdzPokerData.COUNTDOWN_TIME and szDirection == DdzPokerData.tPlayerDirection.Down then
		SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szCountDown"))
	end


    self.tbTimerScript[DdzPokerData.tPlayerDirection.Common]:SetVisible(tCountDown[2] == 0 and bShow)
end

function UIDdzPokerView:PlayCardTimeEnd()
    if not DdzPokerData.IsMyRound() then
		return
	end
	self:PlayChuPaiCrad()
end

function UIDdzPokerView:PlayChuPaiCrad()
    local tChuPaiCards = self.script_downPlayer:GetChuPaiCrad()
    if #tChuPaiCards > 0 then
        self:PlayCard(tChuPaiCards)
    end
end

function UIDdzPokerView:UpdateTishi()
    self.script_downPlayer:UpdateTishi()
end

function UIDdzPokerView:SetHosting(nState)
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_COST_OPERATE, DDZ_PLAYER_OPERATE_SET_AGENT, nState)
end

function UIDdzPokerView:ClearSfx()
    -- 清除皮肤特效
end

function UIDdzPokerView:PlayDealCardSfx()
	if m_bInReconnect then
		return
	end
	-- 播放发牌动画
	self:PlaySfx("AniDealCard")
	self:PlaySfx("AniDealCardLeft")
	self:PlaySfx("AniDealCardRight")
	self:PlaySfx("AniDealCardDown")
	SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szGetCard"))
end

function UIDdzPokerView:HideDealCardSfx()
	-- 关闭发牌动画
	UIHelper.SetVisible(self.AniDealCard , false)
	UIHelper.SetVisible(self.AniDealCardLeft , false)
	UIHelper.SetVisible(self.AniDealCardRight , false)
	UIHelper.SetVisible(self.AniDealCardDown , false)
end

function UIDdzPokerView:PlayDiZhuSfx()
	if m_bInReconnect then
		return
	end
	-- 播放地主特效
	self:PlaySfx("AniDiZhuConfirm")
end

function UIDdzPokerView:PlayDiZhuSfxFinish()
	-- 地主特效关闭
	self:UpdateDiZhuIcon()
	UIHelper.SetVisible(self.AniDiZhuConfirm , false)
end

function UIDdzPokerView:PlayPlayerMingPaiSfx()
	if m_bInReconnect then
		return
	end
    -- 播放明牌动画
	for k, v in pairs(self.tbPlayerScriptMap) do
		v:PlayMingPaiSfx()
	end
end

function UIDdzPokerView:PlaySpringSfx()
    -- 播放春天动画
	self:PlaySfx("AniSpring")
end

function UIDdzPokerView:PlayCardTypeSfx(szDirection)
	if m_bInReconnect then
		return
	end
	if (not DdzPokerData.DataModel.tPreCardType) or (not tType2Sfx[DdzPokerData.DataModel.tPreCardType[1]]) then
		return
	end
	if DdzPokerData.DataModel.tPreCardType[1] >= DDZ_CONST_CARD_TYPE_BOMB4 then
		SoundMgr.PlayBgMusic( DdzPokerData.GetSoundPath("szFastBGM"))
	elseif DdzPokerData.DataModel.tPreCardType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE or
		DdzPokerData.DataModel.tPreCardType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE then
		if DdzPokerData.DataModel.tPreCardType[3] == 1 then
			return
		end
	end
	self.tbPlayerScriptMap[szDirection]:PlayCardTypeSfx(string.format(tType2Sfx[DdzPokerData.DataModel.tPreCardType[1]]))
	SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath(tType2Sound[DdzPokerData.DataModel.tPreCardType[1]]))
end

----------------------------------------------------------------------------------------------------------------------
-- Message Function
----------------------------------------------------------------------------------------------------------------------
function UIDdzPokerView:SyncTianLaiZi()
    DdzPokerData.SyncTianLaiZi()
    DdzPokerData.SyncTableType()
	DdzPokerData.CanelPlayerReadyState()
	self:UpdatePlayerState()
	if DdzPokerData.IsLaiZiTable() and (not DdzPokerData.IsSingleLaiziTable()) then
		self:PlayTianLaiziSfx()
	end
	self:InitLaiziIcon()
	self:UpdateLaiziState(true)
end

function UIDdzPokerView:SyncDiLaiZi()
    self:UpdateTableThreeCard(false)
    DdzPokerData.SyncDiLaiZi()
    if DdzPokerData.IsLaiZiTable() then
		self:PlayDiLaiziSfx()
	end
	DdzPokerData.SyncMingPaiHandCard()
    self.script_leftPlayer:UpdateHandCards()
    self.script_rightPlayer:UpdateHandCards()
	self:InitLaiziIcon()
	self:UpdateLaiziState(true)
	if DdzPokerData.DownIsDiZhu() and (not DdzPokerData.DownIsHosting()) then
		self:ThreeCardstoDown()
	end
end

function UIDdzPokerView:SyncHandCard()
    DdzPokerData.SyncHandCard()
	self:UpdateAllHandCards()
	self:InitCardNum()
	self:UpdateCardNum()
end

function UIDdzPokerView:SyncMoney(nPlayerIndex)
    DdzPokerData.SyncGameEndMoney()
	self:UpdatePlayerMoney()
end

function UIDdzPokerView:PassCard()
    self:HideOp()
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DDZ_PLAYER_OPERATE_JUMP)
end

function UIDdzPokerView:PlayCard(tCards)
    local nTableType = DdzPokerData.DataModel.nTableType
	local bLaiZi = DdzPokerData.IsLaiZiTable()
	local bFreePlay = DdzPokerData.IsFreePlay()
	local nNum = #tCards
	if bLaiZi then
		local tMerge, nCount = DdzPokerData.GetMergeTable(tCards, nTableType, bFreePlay)
		if nCount == 0 then
			self:PlayCardFail()
			return
		end
		self:UpdateBuchuTip(false)
		if nCount == 1 then
			for k, v in pairs(tMerge) do
				v[1].nCmpNum = nil
				self:PlayCardSuccess(v[1])
			end
		else
			self:InitCardChoose(tMerge)
			self:UpdateCardChoose(true)
			DdzPokerData.bLockHandCard = true
		end
	else
		if bFreePlay then
			local tType = DdzPokerData.GetCardType(tCards)
			if tType[1] > 0 and tType[1] < 255 then
				self:PlayCardSuccess(tCards)
				return
			else
				self:PlayCardFail()
				return
			end
		else
			local tPassedCards = DdzPokerData.DataModel.tPreOperateCards.tUIData
			local bCanPlay = DDZ_CompareCardTypeForUI(tPassedCards, tCards)
			if bCanPlay then
				self:PlayCardSuccess(tCards)
			else
				self:PlayCardFail()
				return
			end
		end
	end
end

function UIDdzPokerView:SyncPlayCard()

end

function UIDdzPokerView:SyncMingPaiHardCard()
	DdzPokerData.SyncMingPaiHandCard()
    self.script_leftPlayer:UpdateHandCards()
    self.script_rightPlayer:UpdateHandCards()
	self:InitCardNum()
	self:UpdateCardNum()
end

function UIDdzPokerView:SyncPrePlayer()
    DdzPokerData.SyncPlayCard()
	self:UpdateYaoBuQiPlayingTip()
	DdzPokerData.SyncPrePlayer()
	self:SyncMingPaiHardCard()
	if DdzPokerData.DataModel.nPrePlayerIndex ~= 0 then
		local szDirection = DdzPokerData.DataModel.tIndex2Direction[DdzPokerData.DataModel.nPrePlayerIndex]
        self:UpdatePassedCards(szDirection)
	end
	if DdzPokerData.DataModel.nCurPlayerIndex ~= 0 then
		local szDirection = DdzPokerData.DataModel.tIndex2Direction[DdzPokerData.DataModel.nCurPlayerIndex]
        self:UpdatePassedCards(szDirection)
	end
	local nPreOpPlayerIndex = DdzPokerData.GetPreOpPlayerIndex(DdzPokerData.DataModel.nCurPlayerIndex)
	if DdzPokerData.DataModel.nPrePlayerIndex == nPreOpPlayerIndex then
		self:PlayCardTypeSfx(DdzPokerData.DataModel.tIndex2Direction[nPreOpPlayerIndex])
		local szDirection = DdzPokerData.DataModel.tIndex2Direction[nPreOpPlayerIndex]
		self:PlayPassedCardsAni(szDirection)
	end
	if DdzPokerData.IsPreMyOp() then
		DdzPokerData.SyncHandCard()
        self.script_downPlayer:UpdateHandCards()
	end
	local nNum = DdzPokerData.GetPlayerCardNum(nPreOpPlayerIndex)
	if DdzPokerData.IsMyRound() and nNum > 0 then
		self:UpdateChuPaiButton()
	end
	DdzPokerData.UpdateCardCount()
	self:UpdateCardCount()
end

function UIDdzPokerView:NextPlayerFree()

end

function UIDdzPokerView:SyncCountDown()
    DdzPokerData.SyncCountDown()
end

function UIDdzPokerView:SyncError()
    self:DownHandCards()
	self:UpdateChuPaiButton()
end

function UIDdzPokerView:CallDiZhu(nState)
    self:HideOp()
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DDZ_PLAYER_OPERATE_CHAIRMAN_TYPE, nState)
end

function UIDdzPokerView:SyncDiZhu(nPlayerId, nMsg, nPlayerIndex)
    DdzPokerData.SyncDiZhu()
	self:UpdateDiZhuPlayingTip(true)
	local tPlayerData = DdzPokerData.DataModel.tGameData["Down"]
	if tPlayerData.nState == DdzPokerData.PLAYER_STATE.CAN_QIANG and DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_SET_CHAIRMAN then
		self.script_operations:ShowGrabButton()
	elseif tPlayerData.nState == DdzPokerData.PLAYER_STATE.CAN_CALL and DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN then
        self.script_operations:ShowDemandButton()
	else
		self:HideOp()
	end
	self:UpdateDiZhuIcon()
end

function UIDdzPokerView:CallDouble(nState)
    self:HideOp()
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DDZ_PLAYER_OPERATE_DOUBLE_TYPE, nState)
end

function UIDdzPokerView:SyncThreeCard()
    DdzPokerData.DelCountDown()
	DdzPokerData.SyncThreeCard()
	self:UpdateLaiziCard(false)
	self:UpdateDiZhuPlayingTip(false)
	self:InitDiCard()
	self:InitTableThreeCard()
	self:UpdateTableThreeCard(true)
	self:SyncMingPaiHardCard()
	-- if DataModel.nDiPaiDouble > 1 then
	-- --	View.PlayTimesTipAni("SpecialCard")
	-- end
end

function UIDdzPokerView:SyncDouble()
    DdzPokerData.UpdatePlayerDouble()
	self:UpdateJiaBeiState()
	self:UpdateJiaBeiPlayingTip(true)
end

function UIDdzPokerView:SyncDoubleTimes()
    DdzPokerData.SyncDoubleTimes()
	self:InitDoubleTimes()
	self.script_totalRuleTip:InitDiCardTip()
end

function UIDdzPokerView:SyncTableState()
    local nTableState = DdzPokerData.DataModel.nTableState

    if nTableState == DDZ_CONST_TABLE_STATE_INIT then
		self:UpdateShowRule(false)
		self:HideOp()
		DdzPokerData.SetStartGame(true)
		DdzPokerData.ClearWinnerIndex()
		DdzPokerData.UpdatePlayerMingPai()
		DdzPokerData.ClearTableData()
		DdzPokerData.DelCountDown()
		DdzPokerData.InitCardCount()
		self:UpdateAllHandCards()
		self:UpdateAllPassedCards()
		self:EnableHostingCheck(true)
		self:SetCardCountVisible(false)
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
		self:UpdateJiaBeiState()
		self:UpdateCardCount()
		self:UpdateCmpButton()
		self:UpdateLaiziState(false)
		self:UpdateDiCardTip(false)
		self:InitDoubleTimes()
		self:UpdateYaoBuQiPlayingTip()
		self:UpdateDiZhuIcon()
		self:ClearSfx()
		self:UpdateHosting()
	elseif nTableState == DDZ_CONST_TABLE_STATE_SEND_CARD then
		DdzPokerData.SyncTableType()
		self:UpdateLaiziCard(false)
		DdzPokerData.UpdatePlayerMoney()
		self:UpdatePlayerMoney()
		self:PlayDealCardSfx()
		self.script_downPlayer:HideHandCardState()
		self.script_leftPlayer:HideHandCardState()
		self.script_rightPlayer:HideHandCardState()
	elseif nTableState == DDZ_CONST_TABLE_STATE_DOUBLE then
		self:UpdateLaiziCard(false)
		self:ShowJiaBeiButton()
		self:UpdateDiZhuPlayingTip(false)
		if DdzPokerData.DownIsDiZhu() and (not DdzPokerData.DownIsHosting()) then
			self:ThreeCardstoDown()
		end
	elseif nTableState == DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN then
		self:HideDealCardSfx()
	elseif nTableState == DDZ_CONST_TABLE_STATE_SHOW_CHAIRMAN then
		self:PlayDiZhuSfx()
	elseif nTableState == DDZ_CONST_TABLE_STATE_SHUFFLE_MINGPAI then
		self:UpdateLaiziCard(false)
		DdzPokerData.UpdateCardCount()
		self:PlayCardCountSfx()
		local tPlayerData = DdzPokerData.DataModel.tGameData["Down"]
		if not tPlayerData.bIsMingPai then
			self:ShowMingPiaButton()
		end
		self:DownHandCards()
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
	elseif nTableState == DDZ_CONST_TABLE_STATE_WAIT_CS_SEND then
		DdzPokerData.SyncTableType()
		self:HideOp()
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
		self:UpdateTableThreeCard(false)
	elseif nTableState == DDZ_CONST_TABLE_STATE_SETTLEMENT then
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
		self:GameOver()
		DdzPokerData.DelCountDown()
		self:UpdateTimer(false)
		self:EnableHostingCheck(false)
		UIHelper.SetSelected(self.ToggleAutoPlay , false)
		m_bIsHostingState = false
		self.script_downPlayer:UpdatePlayerHostingSfx(false)
		DdzPokerData.SetStartGame(false)
	elseif nTableState == DDZ_CONST_TABLE_STATE_END_GAME then
		DdzPokerData.SyncGameEndMoney()
		self:UpdatePlayerMoney()
		self:UpdateReadyButtom()
        UIMgr.Open(VIEW_ID.PanelDdzSettlementPop , clone(DdzPokerData.GetSettlmentData()))
	elseif nTableState == DDZ_CONST_TABLE_STATE_KILL_DOUDIZHU then
		if DdzPokerData.DataModel.bStartGame then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GAMEOVER)
            UIMgr.Close(VIEW_ID.PanelDdzSettlementPop)
			self:Close()
			return
		end
	end
end

function UIDdzPokerView:SyncTableStateEnd()
    DdzPokerData.DataModel.nTableState = nil
end

function UIDdzPokerView:SyncHosting()
    local tPlayerData = DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Down]
	local bPreHosting =  tPlayerData.bIsHosting
	DdzPokerData.SyncHosting()
	self:UpdateHosting()
	local bNowHosting = tPlayerData.bIsHosting
	if bPreHosting ~= bNowHosting then
		self.script_downPlayer:UpdateHandCards()
	end
end

function UIDdzPokerView:SetPlayerReady()
    LOG.ERROR("SetPlayerReady")
end

function UIDdzPokerView:SetPlayerMingPai()
    self:HideOp()
	self:SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DDZ_PLAYER_OPERATE_MINGPAI)
end

function UIDdzPokerView:SyncMingPai(nPlayerId, nMsg, nPlayerIndex)
    DdzPokerData.UpdatePlayerMingPai()
	DdzPokerData.SyncMingPaiHandCard()
	self:UpdateAllHandCards()
	self:InitCardNum()
	self:UpdateCardNum()
	self:PlayPlayerMingPaiSfx()
end

function UIDdzPokerView:SyncAccent()
    LOG.ERROR("SyncAccent")
end

function UIDdzPokerView:SyncFail()
    LOG.ERROR("SyncFail")
end

function UIDdzPokerView:SyncWin()
    LOG.ERROR("SyncWin")
end

function UIDdzPokerView:SyncOpenUI()
    LOG.ERROR("SyncOpenUI")
end

function UIDdzPokerView:SyncSpring()
    DdzPokerData.SyncSpring()
    if DdzPokerData.DataModel.nSpringIndex >= 1 and DdzPokerData.DataModel.nSpringIndex <= 3 then
		DdzPokerData.SyncDoubleTimes()
		self:InitDoubleTimes()
		self:PlaySpringSfx()
	end
end


function UIDdzPokerView:Reconnect()
	DdzPokerData.SyncTableState()
    local nTableState = DdzPokerData.DataModel.nTableState
	if not nTableState then
		return
	end
	if nTableState == DDZ_CONST_TABLE_STATE_END_GAME then
		self:UpdateReadyButtom()
		return
	end
	m_bInReconnect = true
	if nTableState >= DDZ_CONST_TABLE_STATE_INIT then
		self:HideOp()
		self:SyncDouble()
		self:SyncCountDown()
		DdzPokerData.SetStartGame(true)
		self:EnableHostingCheck(true)
		for i = 1, DdzPokerData.MAX_PLAYER_NUM do
			DdzPokerData.ClearPlayerGameData(i)
			local tPlayerData = DdzPokerData.GetPlayerDataByIndex(i)
			tPlayerData.bIsMingPai = DDZ_GetPublicMingPaiState(i) > 0
		end
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_SEND_CARD then
		self:SyncDoubleTimes()
		DdzPokerData.UpdatePlayerMoney()
		self:UpdatePlayerMoney()
		self:SyncHosting()
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN then
		self:SyncMoney()
		self:SyncHandCard()
		self:SyncTianLaiZi()
		self:SyncDiZhu()
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_SET_CHAIRMAN then
		self:SyncDiZhu()
		self:SyncDiLaiZi()
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_DOUBLE then
		self:SyncDiZhu()
		self:SyncThreeCard()
		if DdzPokerData.DataModel.tGameData["Down"].nDoubleType == 0 then
			self:ShowJiaBeiButton()
		end
		self:UpdateDiZhuIcon()
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateTableThreeCard(false)
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_SHUFFLE_MINGPAI then
		self:SyncMingPai()
		DdzPokerData.UpdateCardCount()
		self:PlayCardCountSfx()
		local tPlayerData = DdzPokerData.DataModel.tGameData["Down"]
		if not tPlayerData.bIsMingPai then
			self:ShowMingPiaButton()
		end
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_WAIT_CS_SEND then
		self:SyncCountDown()
		DdzPokerData.SyncTableType()
		self:HideOp()
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
		self:UpdateTableThreeCard(false)
		self:SyncPrePlayer()
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_SETTLEMENT then
		self:HideOp()
		DdzPokerData.SyncSpring()
		self:UpdateDiZhuPlayingTip(false)
		self:UpdateJiaBeiPlayingTip(false)
		self:UpdateAllPassedCards()
		self:GameOver()
		DdzPokerData.DelCountDown()
		self:UpdateTimer(false)
		self:EnableHostingCheck(false)
		DdzPokerData.SetStartGame(false)
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_END_GAME then
		self:HideOp()
		DdzPokerData.SyncGameEndMoney()
		self:UpdatePlayerMoney()
		self:UpdateReadyButtom()
	end
	if nTableState >= DDZ_CONST_TABLE_STATE_KILL_DOUDIZHU then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GAMEOVER)
		self:Close()
	end
	m_bInReconnect = false
end

function UIDdzPokerView:PlaySfx(sfxCell)
	UIHelper.SetVisible(self[sfxCell] , true)
	UIHelper.PlaySFX(self[sfxCell])
end

return UIDdzPokerView
