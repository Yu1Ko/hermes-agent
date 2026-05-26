-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: MahjongData
-- Date: 2023-07-28 15:03:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

MahjongData = MahjongData or {className = "MahjongData"}
local self = MahjongData
-------------------------------- 消息定义 --------------------------------
MahjongData.Event = {}
MahjongData.Event.XXX = "MahjongData.Msg.XXX"

local nApplyFellowshipCardType = 5
local nGamePlayerNum = 4 --游戏人数
local nCardMaxNum = 4 --相同牌值张数
local nDiscardCountDownPlaySound = 5
local nBeatGapTime = 60  --与服务器心跳通讯时间，小游戏一定时间内不通讯，逻辑会强制关闭游戏
local nWeiTingPaiType = 100

local nSwapCardResultTime = 3 * 1000 --换牌结果显示延迟时间
local nSelectionLackTypeTime = nSwapCardResultTime + 2000 --定缺显示延迟时间


--摸牌顺序
local tDealSorte = {
    [1] = tDirectionType.East,
    [2] = tDirectionType.North,
    [3] = tDirectionType.West,
    [4] = tDirectionType.South,
}

--打牌顺序 逆时针
local tDiscardSorte = {
    [1] = tDirectionType.East,
    [2] = tDirectionType.South,
    [3] = tDirectionType.West,
    [4] = tDirectionType.North,
}

--骰子点数对应跳过墩数
local tDieDotToJumpStackNum = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6,
}




local tUIPosIndex2Name = {
	[tUIPosIndex.Down] = "Down",
	[tUIPosIndex.Left] = "Left",
	[tUIPosIndex.Up] = "Up",
	[tUIPosIndex.Right] = "Right",
}


local tAllDirection2PosIndex = {
	[tDirectionType.East] = {
		[tDirectionType.East]= tUIPosIndex.Down,
		[tDirectionType.North] = tUIPosIndex.Left,
		[tDirectionType.West]= tUIPosIndex.Up,
		[tDirectionType.South] = tUIPosIndex.Right,
	},
	[tDirectionType.North] = {
		[tDirectionType.North] = tUIPosIndex.Down,
		[tDirectionType.West]= tUIPosIndex.Left,
		[tDirectionType.South] = tUIPosIndex.Up,
		[tDirectionType.East]= tUIPosIndex.Right,
	},
	[tDirectionType.West] = {
		[tDirectionType.West]= tUIPosIndex.Down,
		[tDirectionType.South] = tUIPosIndex.Left,
		[tDirectionType.East]= tUIPosIndex.Up,
		[tDirectionType.North] = tUIPosIndex.Right,
	},
	[tDirectionType.South] = {
		[tDirectionType.South] = tUIPosIndex.Down,
		[tDirectionType.East]= tUIPosIndex.Left,
		[tDirectionType.North] = tUIPosIndex.Up,
		[tDirectionType.West]= tUIPosIndex.Right,
	},
}

--方向对应牌墩数
tDirection2CardStackNnm = {
    [tDirectionType.East] = 13,
    [tDirectionType.South] = 14,
    [tDirectionType.West] = 13,
    [tDirectionType.North] = 14,
}



local tMessageType2FunName = {
	[PLAYER_OPERATE_DICE] = {szFunName = "SyncDiceNum", szDes = "骰子点数"},
	[PLAYER_OPERATE_SET_CHAIRMAN] = {szFunName = "", szDes = "设置庄家"},
	[PLAYER_OPERATE_PRE_EXCHANGE] = {szFunName = "StartSwapCard", szDes = "开始换牌"},
	[PLAYER_OPERATE_EXCHANGE_CONFIRM] = {szFunName = "SwapOutCardResult", szDes = "换牌确认换出的牌"},
	[PLAYER_OPERATE_EXCHANGE] = {szFunName = "SwapInCardResult", szDes = "换牌结束得到的牌"},
	[PLAYER_OPERATE_PRE_LACK] = {szFunName = "StartSelectionLackType", szDes = "开始定缺"},
	[PLAYER_OPERATE_SET_LACK] = {szFunName = "LackTypeResult", szDes = "同步定缺结果"},
	[PLAYER_OPERATE_SC_SEND] = {szFunName = "GainCard", szDes = "同步发牌结果"},
	[PLAYER_OPERATE_CS_SEND] = {szFunName = "DisCardResult", szDes = "同步打牌结果"},
	[PLAYER_OPERATE_SYN_OPERATE_MASK] = {szFunName = "OperatePongKongWin", szDes = "当前可以的操作 碰杠胡"},
	[PLAYER_OPERATE_PENG] = {szFunName = "PongResult", szDes = "碰的结果"},
	[PLAYER_OPERATE_MING_GANG] = {szFunName = "KongResult", szDes = "明杠结果"},
	[PLAYER_OPERATE_AN_GANG] = {szFunName = "KongResult", szDes = "暗杠结果"},
	[PLAYER_OPERATE_GANG_AFTER_PENG] = {szFunName = "KongResult", szDes = "碰后杠结果"},
	[PLAYER_OPERATE_HU] = {szFunName = "WinResult", szDes = "胡牌结果"},
	[PLAYER_OPERATE_JUMP] = {szFunName = "PassCardResult", szDes = "过牌结果"},
	[PLAYER_OPERATE_TIME] = {szFunName = "SyncGameTime", szDes = ""}, --倒计时
	[PLAYER_OPERATE_MULTI_FIRE] = {szFunName = "MultipleWinResult", szDes = "一炮多响"},
	[PLAYER_OPERATE_SYN_CASH] = {szFunName = "SyncGradeOrHonor", szDes = "同步分数"},
	[PLAYER_OPERATE_SYN_CASH_HONOR] = {szFunName = "SyncGradeOrHonor", szDes = "同步荣誉点数"},
	--[PLAYER_OPERATE_TUISHUI] = {szFunName = "SyncDrawback", szDes = "退税"},
	--[PLAYER_OPERATE_CHECK_DAJIAO] = {szFunName = "SyncChaDaJiao", szDes = "查大叫"},
	--[PLAYER_OPERATE_CHECK_COLORPIG] = {szFunName = "SyncHuaZhu", szDes = "花猪"},
	[PLAYER_OPERATE_ERROR] = {szFunName = "", szDes = "返回错误码"},
	[PLAYER_OPERATE_TABLE_STATE] = {szFunName = "SyncGameState", szDes = "同步牌桌状态"},
	[PLAYER_OPERATE_SYN_CUR_CARD] = {szFunName = "SyncDisconnectedData", szDes = "获取当前可以操作的牌"},
	[PLAYER_OPERATE_SET_AGENT] = {szFunName = "SyncAgentState", szDes = "同步托管状态"},
}

local tbType2Name = {
	[PLAYER_OPERATE_MING_GANG] = {g_tStrings.tMahjongSettlemen[1], g_tStrings.tMahjongSettlemen[2]},
	[PLAYER_OPERATE_AN_GANG] = {g_tStrings.tMahjongSettlemen[1], g_tStrings.tMahjongSettlemen[2]},
	[PLAYER_OPERATE_GANG_AFTER_PENG] = {g_tStrings.tMahjongSettlemen[1], g_tStrings.tMahjongSettlemen[2]},  --碰后杠
	[PLAYER_OPERATE_HU] = {g_tStrings.tMahjongSettlemen[3], g_tStrings.tMahjongSettlemen[4]},
	[PLAYER_OPERATE_CHECK_COLORPIG] = {g_tStrings.tMahjongSettlemen[5], g_tStrings.tMahjongSettlemen[5]}, --花猪
	[PLAYER_OPERATE_TUISHUI] = {g_tStrings.tMahjongSettlemen[6], g_tStrings.tMahjongSettlemen[6]}, --退税
	[PLAYER_OPERATE_CHECK_DAJIAO] = {g_tStrings.tMahjongSettlemen[8], g_tStrings.tMahjongSettlemen[8]}, --查大叫
	[PLAYER_OPERATE_HU_1_PAO_N_XIANG] = {g_tStrings.tMahjongSettlemen[7], g_tStrings.tMahjongSettlemen[7]} --一炮多响
}

--音效配置
local tbMahjongSound = {
	szBGM = "data\\sound\\专有\\小游戏\\麻将音效\\家园麻将主题曲.mp3", --背景音
	szCountdown = "data\\sound\\专有\\小游戏\\麻将音效\\5秒倒计时.ogg",  --倒计时音
	szSwapCardOut = "data\\sound\\专有\\小游戏\\麻将音效\\换牌时弹出三张同色花牌音效.ogg", --换牌时，弹出3张同花色牌音效
	szSwapCardCourse = "data\\sound\\专有\\小游戏\\麻将音效\\换牌后转动音效.ogg", --换牌后_转动音效
	szSwapCardIn = "data\\sound\\专有\\小游戏\\麻将音效\\换牌后放置回三张牌到自己手中.ogg", --收到换回的牌
	szBtn = "data\\sound\\专有\\小游戏\\麻将音效\\通用确定按钮音效.ogg", --按钮
	szOnClickCard = "data\\sound\\专有\\小游戏\\麻将音效\\选择单张牌音效.ogg", --选择牌音效
	szWin = "data\\sound\\专有\\小游戏\\麻将音效\\家园麻将胜利.ogg", --结算时赢钱
	szLose = "data\\sound\\专有\\小游戏\\麻将音效\\家园麻将未胡牌失败.wav", --结算时输钱
	szKongCard = "data\\sound\\专有\\小游戏\\麻将音效\\杠.ogg", --杠牌
	--szPongCard = "", --碰牌
	szZiMo = "data\\sound\\专有\\小游戏\\麻将音效\\胡自摸.ogg", --自摸
	szKongKaiHua = "data\\sound\\专有\\小游戏\\麻将音效\\麻将杠上开花.ogg", --杠上开花
	szHiDiLaoYe = "data\\sound\\专有\\小游戏\\麻将音效\\麻将海底捞月.ogg", --海底捞月
	szFangPao = "data\\sound\\专有\\小游戏\\麻将音效\\胡放炮.ogg", --点炮胡
	szShakeDice = "data\\sound\\专有\\小游戏\\麻将音效\\麻将摇骰子.ogg", --摇骰子
	szCostItem = "data\\sound\\专有\\小游戏\\麻将音效\\扣钱.ogg", --扣钱
	szDisCard = "data\\sound\\专有\\小游戏\\麻将音效\\出牌音效c.ogg", --出牌音效
	--szOpenSettlementPanel = "", --结算界面弹出
	szLackType = "data\\sound\\专有\\小游戏\\麻将音效\\定缺.ogg", --定缺
	szFirstShowHandCard = "data\\sound\\专有\\小游戏\\麻将音效\\开场发牌音效.ogg", --开场发牌声音
	szShowAllHandCard = "data\\sound\\专有\\小游戏\\麻将音效\\结束时摊牌.ogg", --结束时摊牌
}


function MahjongData.Init()
    -- self._registerEvent()
end

function MahjongData.UnInit()

end

function MahjongData.OnLogin()

end

function MahjongData.OnFirstLoadEnd()

end

--------------------------------------------------------------------收到服务器信息 Start-------------------------------------------------------------
function MahjongData.OnEnterMahjongGame(tbPlayerData)

    self._registerEvent()
    self.tbPlayerData = tbPlayerData

    local tbPlayerID = self.GetAllPlayerID()
    self.ApplyAllRecordData(tbPlayerID)
    self.ApplyRoleEntryInfo(tbPlayerID)

    self.SetGameData("nBeatLastTime", GetCurrentTime())
    self.StartBreathTimer()
    self.SetGameData("nGameState", CONST_TABLE_STATE_INIT)

    if self.GetGameStart() then
        self.ParseData()
        self.InitGameState()
    end

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMahjongMain)
    if not scriptView then
        UIMgr.Open(VIEW_ID.PanelMahjongMain)
    else
        scriptView:OnEnter()
    end

end

function MahjongData.ApplyAllRecordData(tbPlayerID)
    for nIndex, nPlayerID in ipairs(tbPlayerID) do
		self.ApplyMahjongRecordData(nPlayerID)
	end
end

function MahjongData.InitGameState()
    local nGameState = self.GetGameData("nGameState")

    if nGameState == CONST_TABLE_STATE_EXCHANGE then
        local nOwnDirection = self.GetPlayerDataDirection()
        local tbData = GetPlayerExchangeCard(nOwnDirection)
        if tbData then
            self._updateSelectionCard(tbData[1], tbData[2], tbData[3])
        end
        self.SetGameData("bSwapCard", true)
    elseif nGameState == CONST_TABLE_STATE_WAIT_CS_SEND or
    nGameState == CONST_TABLE_STATE_WAIT_CS_SEND_1 or
    nGameState == CONST_TABLE_STATE_WAIT_OPERATE or
    nGameState == CONST_TABLE_STATE_WAIT_OPERATE_COMBO then--等待出牌
        self.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_SYN_CUR_CARD)
    elseif nGameState == CONST_TABLE_STATE_END_GAME then
        self.GameOver()
    end
end

function MahjongData.StartBreathTimer()
    self.RemoveBreathTimer()
    self.nBreathTimer = Timer.AddFrameCycle(self, 1, function()
        self.OnTimer()
    end)
end

function MahjongData.RemoveBreathTimer()
    if self.nBreathTimer then
        Timer.DelTimer(self, self.nBreathTimer)
        self.nBreathTimer = nil
    end
end

function MahjongData.OnTimer()
    local nGameTime = self.GetGameMgr().GetGameTime()
    local nCountDown = self.GetGameData("nCountDown")
    if nCountDown then
        local nCountDownDirection = self.GetGameData("nCountDownDirection")
        local nOwnDirection = self.GetPlayerDataDirection()
        local nCountDownType = self.GetGameData("nCountDownType")
        local nDiffTime = nCountDown - nGameTime
        local bPlaySoundCountDown = self.GetGameData("bPlaySoundCountDown")
        if nCountDownDirection and nCountDownDirection == nOwnDirection and nCountDownType and nCountDownType == CONST_TABLE_STATE_WAIT_CS_SEND_1
        and nDiffTime == nDiscardCountDownPlaySound and bPlaySoundCountDown then
            self.SetGameData("bPlaySoundCountDown", false)
            SoundMgr.PlaySound(SOUND.UI_SOUND, tbMahjongSound.szCountdown)
        end
        local szTime = nCountDown > nGameTime and tostring(nDiffTime) or ""
        Event.Dispatch(EventType.OnUpdateTime, szTime)
    end

    local nCurrTime = GetCurrentTime()
    local nBeatLastTime = self.GetGameData("nBeatLastTime")
	if nBeatLastTime and (nCurrTime - nBeatLastTime) > nBeatGapTime then
		self.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_HEART_BEAT)
        self.SetGameData("nBeatLastTime", nCurrTime)
	end

    self._onDelayCall()
end


function MahjongData.OnAddPlayerMahjongGame(tPlayerInfo)
    local tbPlayerIDList = {}
    local player = g_pClientPlayer
    for nDataDirection, tInfo in pairs(tPlayerInfo) do
        local tPlayerInfo = self.tbPlayerData.tPlayerInfo[nDataDirection]

		if not tPlayerInfo or tPlayerInfo[1] ~= tInfo[1] then
			if player.dwID ~= tInfo[1] then
				table.insert(tbPlayerIDList, tInfo[1])
			end
            self.ApplyMahjongRecordData(tInfo[1])
		end
		self.tbPlayerData.tPlayerInfo[nDataDirection] = tInfo
    end

    if #tbPlayerIDList > 0 then
		--增加新上线玩家
        self.ApplyRoleEntryInfo(tbPlayerIDList)
	else
        --更新玩家状态
        Event.Dispatch(EventType.OnUpdatePlayerInfo)
	end
end


function MahjongData.PlayerLeave(tPlayer)
    local player = g_pClientPlayer

    for k, v in pairs(tPlayer) do
		local nPlayerID = v[1]
		if nPlayerID ~= player.dwID then
			local nDataDirection = v[2]
			local tPlayerInfo = self.tbPlayerData.tPlayerInfo[nDataDirection]

			if tPlayerInfo and tPlayerInfo[1] == nPlayerID then
				if self.tbPlayerData.bStartGame then
					--离开状态
					self.tbPlayerData.tPlayerInfo[nDataDirection][2] = tPlayerState.nLeave
				else
					--游戏没开始
					self.tbPlayerData.tPlayerInfo[nDataDirection] = nil
				end
			end
		end
	end

    Event.Dispatch(EventType.OnUpdatePlayerInfo)
end

function MahjongData.PlayDice()
    self.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_DICE)
end

function MahjongData.StartSwapCard(nOperationType, nValue1, nValue2, nValue3)

    self.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_SET_ACCENT, 0)--默认普通话

    self.SetGameData("bSwapCard", true)
    self.ParseData(nValue1, nValue2, nValue3)
    self.SetGameStart(true)

end

function MahjongData.SwapInCardResult(nOperationType, nValue1, nValue2, nValue3)

    local nOwnDirection = self.GetPlayerDataDirection()
    local function SwapInCard()
        local tCardsInfo = {}
        tCardsInfo[1] = self.Card16ToCardInfo(nValue1)
        tCardsInfo[2] = self.Card16ToCardInfo(nValue2)
        tCardsInfo[3] = self.Card16ToCardInfo(nValue3)

        local tHandCards = self.GetMyHandCardInfo()

        table.insert(tHandCards, tCardsInfo[1])
        table.insert(tHandCards, tCardsInfo[2])
        table.insert(tHandCards, tCardsInfo[3])
        self.SetPlayerHandCardInfo(nOwnDirection, tHandCards)

        self.SetGameData("bSwapCard", false)

        Event.Dispatch(EventType.OnChangeCard)

        self.DelayCall("OnSwapInCardResult", nSwapCardResultTime, function()
            Event.Dispatch(EventType.OnSwapInCardResult)
        end)

    end

    local bSwapOutCard = self.IsSwapOutCard(nOwnDirection)
	if not bSwapOutCard then --删除
		local tbOutCard = self.GetSwapCardOutCard(nOwnDirection)
        self.SwapOutCardResult(0, tbOutCard[1], tbOutCard[2], tbOutCard[3], SwapInCard)
    else
        SwapInCard()
	end

end

function MahjongData.SwapOutCardResult(nOperationType, nCard1, nCard2, nCard3, funcCallBack)

    local tCardsInfo = {}
	tCardsInfo[1] = self.Card16ToCardInfo(nCard1)
	tCardsInfo[2] = self.Card16ToCardInfo(nCard2)
	tCardsInfo[3] = self.Card16ToCardInfo(nCard3)

    local tbIndex = {}
    table.insert(tbIndex, self.GetCardIndexInMyHandCards(tCardsInfo[1]))
    table.insert(tbIndex, self.GetCardIndexInMyHandCards(tCardsInfo[2]))
    table.insert(tbIndex, self.GetCardIndexInMyHandCards(tCardsInfo[3]))
    Event.Dispatch(EventType.OnSwapOutCardResult, tbIndex, funcCallBack)

    local nDataDirection = self.GetPlayerDataDirection()
    for index, nIndex in ipairs(tbIndex) do
        self.RemovePlayerHandCardInfo(nDataDirection, nIndex)
    end

end

function MahjongData.GameOver(nOperationType, nState)
	self.SetGameStart(false)
    self.SetGameData("tbTuiSuiData", self._getTuiSuiData())

    local tbPlayerInfo = self.GetPlayerInfoData()
    for k, tPlayerInfo in pairs(tbPlayerInfo) do
		tPlayerInfo[2] = tPlayerState.nNotReady
	end
    UIMgr.Open(VIEW_ID.PanelMahjongSettlementPop)
    Event.Dispatch(EventType.GameOver)
end


function MahjongData.StartSelectionLackType(nOperationType, nCardType)

    self.DelayCall("StartSelectionLackType", nSelectionLackTypeTime, function()
        local nOwnDirection = self.GetPlayerDataDirection()
        local tHandCards = self._getOwnHandCard(nOwnDirection)
        self.SetPlayerHandCardInfo(nOwnDirection, tHandCards)
        Event.Dispatch(EventType.StartSelectionLackType, nCardType)
    end)
end

function MahjongData.LackTypeResult(nOperationType, nDataDirection, nLackType)
    local nOwnDirection = self.GetPlayerDataDirection()
    if nDataDirection == nOwnDirection then
        self.SetGameData("nOwnLackType", nLackType)
        local tHandCards = self._getOwnHandCard(nDataDirection)
        self.SetPlayerHandCardInfo(nOwnDirection, tHandCards)
    end
    self.SetPlayerCardInfo("nLackType", nLackType, nDataDirection)
    --同步完最后一个玩家数据刷新界面
    if nDataDirection == tDirectionType.North then
        local nBankerDirection = self.GetGameData("nBankerDirection")
        if nBankerDirection == nOwnDirection then
            local nCard = GetChairManOperateCard(nBankerDirection)
            self.SetGameData("tbWaitCardInfo", self.Card16ToCardInfo(nCard))
            self.SetGameData("bDisCard", true)
        end
        Event.Dispatch(EventType.LackTypeResult)
    end

end

function MahjongData.GainCard(nOperationType, nDataDirection, nCard, nDealCardNum)
    self.SetGameData("nDealCardNum", nDealCardNum)
    if nDataDirection == self.GetPlayerDataDirection() then
        self.SetGameData("tbWaitCardInfo",  self.Card16ToCardInfo(nCard))
        self.SetGameData("bDisCard", true)
    else
        self.SetGameData("bDisCard", false)
        local nHandCardNum = self.GetPlayerCardInfo("nHandCardNum", nDataDirection)
        self.SetPlayerCardInfo("nHandCardNum", nHandCardNum + 1, nDataDirection)
    end
    Event.Dispatch(EventType.GainCard, nDataDirection)
end

function MahjongData.DisCardResult(nOperationType, nDataDirection, nValue)
    local tbCardInfo = self.Card16ToCardInfo(nValue)
    self.AddPlayerDisCardInfo(nDataDirection, tbCardInfo)

    local bOwnDirection = nDataDirection == self.GetPlayerDataDirection()
    local nHandCardNum = 0
    local nIndex = nil
    if not bOwnDirection then
        nHandCardNum = self.GetPlayerCardInfo("nHandCardNum", nDataDirection)
        self.SetPlayerCardInfo("nHandCardNum", math.max(0, nHandCardNum - 1), nDataDirection)
    else
        self.SetGameData("bDisCard", false)
        self.SetPlayerHandCardInfo(nDataDirection, self._getOwnHandCard(nDataDirection))
        --需要手动更新自己手牌？？
        local tbWaitCardInfo = self.GetGameData("tbWaitCardInfo")
        nIndex = self.GetCardIndexInMyHandCards(tbWaitCardInfo)
        self.SetGameData("tbWaitCardInfo",  nil)
    end

    Event.Dispatch(EventType.DisCardResult, nDataDirection, nIndex)

end


function MahjongData.SyncGameTime(nOperationType, nDataDirection, nCountDown, nCountDownType)
    if self.GetGameData("nGameState") == CONST_TABLE_STATE_END_GAME then return end
    if nCountDownType == CONST_TABLE_STATE_WAIT_CS_SEND_1 or nCountDownType == CONST_TABLE_STATE_WAIT_CS_SEND_AGENT
    or nCountDownType == CONST_TABLE_STATE_WAIT_CS_SEND
    or nCountDownType == CONST_TABLE_STATE_WAIT_OPERATE or nCountDownType == CONST_TABLE_STATE_WAIT_OPERATE_COMBO then
        nCountDown = nCountDown - 1
    end
    self.SetGameData("nCountDown", nCountDown)
    self.SetGameData("nCountDownType", nCountDownType)
    self.SetGameData("nCountDownDirection", nDataDirection)
    self.SetGameData("bPlaySoundCountDown", true)
end

function MahjongData.OperatePongKongWin(nOperationType, nType, nCard)
    local nOwnDirection = nil
    if nType > 0 then
        nOwnDirection = self.GetPlayerDataDirection()
        self.SetGameData("tbCurrOperateCard", {nDataDirection = nOwnDirection, nValue = nCard, tCardInfo = self.Card16ToCardInfo(nCard)})
	end
    local tbOperateMask = nOwnDirection and GetPlayerOperateMask(nOwnDirection) or nil
    Event.Dispatch(EventType.OperatePongKongWin, nType, tbOperateMask)
end


function MahjongData.PongResult(nOperationType, nDataDirection, nCard)

    local nOwnDirection = self.GetPlayerDataDirection()
    if nOwnDirection ~= nDataDirection then
        local nHandCardNum = self.GetPlayerCardInfo("nHandCardNum", nDataDirection)
        nHandCardNum = math.max(nHandCardNum - 2, 0)
        self.SetPlayerCardInfo("nHandCardNum", nHandCardNum, nDataDirection)
    else
        self.SetPlayerHandCardInfo(nDataDirection, self._getOwnHandCard(nDataDirection))
        self.SetGameData("bDisCard", true)
    end
    Event.Dispatch(EventType.PongResult, nOperationType, nDataDirection, nCard)
end

function MahjongData.KongResult(nOperationType, nDataDirection, nCard)
    local nMaxNum = 3
    if nOperationType == PLAYER_OPERATE_GANG_AFTER_PENG then  --碰后杠
        nMaxNum = 1
    elseif nOperationType == PLAYER_OPERATE_AN_GANG then
        nMaxNum = 4
    end
    local nOwnDirection = self.GetPlayerDataDirection()
    if nOwnDirection ~= nDataDirection then
        local nHandCardNum = self.GetPlayerCardInfo("nHandCardNum", nDataDirection)
        nHandCardNum = math.max(nHandCardNum - nMaxNum, 0)
        self.SetPlayerCardInfo("nHandCardNum", nHandCardNum, nDataDirection)
    else
        --防止牌局最后一张牌杠牌后，游戏结束还可以点击打牌
        self.SetGameData("bDisCard", false)
        self.SetPlayerHandCardInfo(nDataDirection, self._getOwnHandCard(nDataDirection))
    end

    Event.Dispatch(EventType.KongResult, nOperationType, nDataDirection, nCard, nMaxNum)
    SoundMgr.PlaySound(SOUND.UI_SOUND, tbMahjongSound.szKongCard)
end

function MahjongData.WinResult(nOperationType, nValue, nCard, nWinMask)
    local nWinDirection, nLoseDirection, nPoints = self.PassWinData(nValue)
    local tbWinType = CalcHuMask(nWinMask)
	local tbCardInfo = self.Card16ToCardInfo(nCard)
    self.AddPlayerWinsCardInfo(nWinDirection, tbCardInfo)

    -- if nWinDirection ~= MahjongData.GetPlayerDataDirection() then
    --     local nHandCardNum = self.GetPlayerCardInfo("nHandCardNum", nWinDirection)
    --     nHandCardNum = math.max(nHandCardNum - 1, 0)
    --     self.SetPlayerCardInfo("nHandCardNum", nHandCardNum, nWinDirection)
    -- end

    Event.Dispatch(EventType.WinResult, nWinDirection, tbCardInfo, tbWinType)
end

function MahjongData.MultipleWinResult(nOperationType, nDataDirection1, nDataDirection2, nDataDirection3)
    MahjongData.SetGameData("bMultipleWin", true)
    Event.Dispatch(EventType.MultipleWinResult, nDataDirection1, nDataDirection2, nDataDirection3)
end

function MahjongData.PassCardResult(nOperationType, nDataDirection)
    Event.Dispatch(EventType.PassCardResult, nDataDirection)
end

function MahjongData.SyncGradeOrHonor(nOperationType, nDataDirection, nCurrGrade, nAddGrade)
    if nOperationType == PLAYER_OPERATE_SYN_CASH then
        local nGameState = self.GetGameData("nGameState")
		if nGameState == CONST_TABLE_STATE_TUISHUI or nGameState == CONST_TABLE_STATE_END_GAME then
			return
		end
        self.SetPlayerCardInfo("nGrade", nCurrGrade, nDataDirection)
    end
    Event.Dispatch(EventType.SyncGradeOrHonor, nOperationType, nDataDirection, nCurrGrade, nAddGrade)
end

function MahjongData.SyncGameState(nOperationType, nState)
   self.SetGameData("nGameState", nState)
    if nState == CONST_TABLE_STATE_END_GAME then
        --牌局结束
        self.SetGameData("nCountDown", 0)
        self.GameOver()
    end
    Event.Dispatch(EventType.SyncGameState, nState)
end

function MahjongData.SyncDisconnectedData(nOperationType, nDataDirection, nCard, nGameState)
    local  tbCardInfo = self.Card16ToCardInfo(nCard)
    local nOwnDirection = self.GetPlayerDataDirection()
    if nDataDirection == nOwnDirection then
        if nCard > 0 then
            self.SetGameData("tbWaitCardInfo", tbCardInfo)
        end
        self.SetGameData("bDisCard", true)
    end

    if nGameState == CONST_TABLE_STATE_WAIT_OPERATE or nGameState == CONST_TABLE_STATE_WAIT_OPERATE_COMBO then
		--等待玩家碰杠胡
		if nCard > 0 then
			if nDataDirection ~= nOwnDirection then
				--显示在弃牌区
                self.AddPlayerDisCardInfo(nDataDirection, tbCardInfo)
			end
            self.SetGameData("tbCurrOperateCard", {nDataDirection = nDataDirection, nValue = nCard, tCardInfo = self.Card16ToCardInfo(nCard)})
		end
	end
    Event.Dispatch(EventType.SyncDisconnectedData, nDataDirection, nCard, nGameState)
end

function MahjongData.SyncAgentState(nOperationType, nDataDirection, nState)
    local bAgent = nState == 1
    if bAgent then
		local tbWins = self.GetPlayerWinsCardInfoByDirection(nDataDirection) or {}
		local nGrade = self.GetPlayerCardInfo("nGrade", nDataDirection)
		if #tbWins > 0 or nGrade < 1 then
			bAgent = false
		end
	end
    self.SetAgentState(nDataDirection, bAgent)
end

---------------------------------------------------------------------------收到服务器信息 End-------------------------------------------------------------


------------------------------------------------------------------------------辅助函数 Start--------------------------------------------------------------


function MahjongData.GetCurrOperateCard(bParse)
    local tbCurrOperateCard = self.GetGameData("tbCurrOperateCard")
	if tbCurrOperateCard then
		if bParse then
			return tbCurrOperateCard.tCardInfo
		end
		return tbCurrOperateCard.nValue
	end
end

function MahjongData.PassWinData(nValue)
	--十位胡牌玩家、个位放炮玩家、千百位番数 注意：自摸 胡牌玩家 放炮玩家相等
	local nLoseDirection = nValue%10
	nValue = math.floor(nValue/10)
	local nWinDirection = nValue%10
	local nPoints = math.floor(nValue/10)
	return nWinDirection, nLoseDirection, nPoints
end

function MahjongData.GetMyHandCardIndex(tbCardInfo)
    local tbCardList = self.GetPlayerHandCardInfoByDirection(self.GetPlayerDataDirection())
	for nIndex, tbInfo in ipairs(tbCardList) do
        if tbCardInfo.nType == tbInfo.nType and tbCardInfo.nNumber == tbInfo.nNumber then
            return nIndex
        end
    end
    return nil
end

function MahjongData.GetGameMgr()
	if not self.MiniGameMgr then
		self.MiniGameMgr = GetMiniGameMgr()
	end
	return self.MiniGameMgr
end

function MahjongData.GetSwapCardOutCard(nDataDirection)
	local tCard = GetPlayerExchangeCard(nDataDirection)
	if not tCard or not next(tCard) then
		return
	end
	return tCard
end



function MahjongData.IsSwapOutCard(nDataDirection)
    local nValue = GetPlayerHaveCommitExchange(nDataDirection)
	return nValue > 0 or false
end

function MahjongData.SetPlayerHandCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerHandCardInfo then
        self.tbPlayerHandCardInfo = {}
    end
    self.tbPlayerHandCardInfo[nDataDirection] = tbInfo

end

function MahjongData.AddPlayerHandCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerHandCardInfo then
        self.tbPlayerHandCardInfo = {}
    end
    if not self.tbPlayerHandCardInfo[nDataDirection] then
        self.tbPlayerHandCardInfo[nDataDirection] = {}
    end
    table.insert(self.tbPlayerHandCardInfo[nDataDirection], tbInfo)

end

function MahjongData.RemovePlayerHandCardInfo(nDataDirection, nIndex)
    if nIndex <= 0 then return end
    local tbPlayerCardData = self.tbPlayerHandCardInfo[nDataDirection]
    if tbPlayerCardData and #tbPlayerCardData < nIndex then return end
    table.remove(self.tbPlayerHandCardInfo[nDataDirection] , nIndex)


end

function MahjongData.GetPlayerHandCardInfo()
    return self.tbPlayerHandCardInfo
end

function MahjongData.GetPlayerHandCardInfoByDirection(nDataDirection)
    return self.tbPlayerHandCardInfo and self.tbPlayerHandCardInfo[nDataDirection] or {}
end

function MahjongData.GetMyHandCardInfo()
    local nDataDirection = self.GetPlayerDataDirection()
    return self.GetPlayerHandCardInfoByDirection(nDataDirection)
    -- return self.CreateTestData()
end

function MahjongData.ClearPlayerHandCardInfo()
    self.tbPlayerHandCardInfo = nil
end


function MahjongData.SetPlayerDisCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerDisCardInfo then
        self.tbPlayerDisCardInfo = {}
    end
    self.tbPlayerDisCardInfo[nDataDirection] = tbInfo
end

function MahjongData.AddPlayerDisCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerDisCardInfo then
        self.tbPlayerDisCardInfo = {}
    end
    if not self.tbPlayerDisCardInfo[nDataDirection] then
        self.tbPlayerDisCardInfo[nDataDirection] = {}
    end
    table.insert(self.tbPlayerDisCardInfo[nDataDirection], tbInfo)
    tbInfo.nDataDirection = nDataDirection
    self.SetLastDisCardInfo(tbInfo)
end

function MahjongData.RemovePlayerDisCardInfo(nDataDirection, nIndex)
    if nIndex <= 0 then return end
    local tbDisCardData = self.tbPlayerDisCardInfo[nDataDirection]
    if tbDisCardData and #tbDisCardData < nIndex then return end
    table.remove(self.tbPlayerDisCardInfo[nDataDirection] , nIndex)
end

function MahjongData.GetPlayerDisCardInfo()
    return self.tbPlayerDisCardInfo
end

function MahjongData.GetPlayerDisCardInfoByDirection(nDataDirection)
    return self.tbPlayerDisCardInfo[nDataDirection]
end

function MahjongData.ClearPlayerDisCardInfo()
    self.tbPlayerDisCardInfo = nil
end

function MahjongData.SetLastDisCardInfo(tbDisCardInfo)
    self.tbLastDisCardInfo = tbDisCardInfo
end

function MahjongData.GetLastDisCardInfo()
    return self.tbLastDisCardInfo
end

function MahjongData.ClearLastDisCardInfo()
    self.tbLastDisCardInfo = nil
end



function MahjongData.SetPlayerWinsCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerWinsCardInfo then
        self.tbPlayerWinsCardInfo = {}
    end
    self.tbPlayerWinsCardInfo[nDataDirection] = tbInfo
    -- Event.Dispatch(EventType.OnPlayerWinsCardChange, nDataDirection, #self.tbPlayerWinsCardInfo[nDataDirection])
end

function MahjongData.AddPlayerWinsCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerWinsCardInfo then
        self.tbPlayerWinsCardInfo = {}
    end
    if not self.tbPlayerWinsCardInfo[nDataDirection] then
        self.tbPlayerWinsCardInfo[nDataDirection] = {}
    end
    table.insert(self.tbPlayerWinsCardInfo[nDataDirection], tbInfo)
    -- Event.Dispatch(EventType.OnPlayerWinsCardChange, nDataDirection, #self.tbPlayerWinsCardInfo[nDataDirection])
end

function MahjongData.RemovePlayerWinsCardInfo(nDataDirection, nIndex)
    if nIndex <= 0 then return end
    local tbWinsCardData = self.tbPlayerWinsCardInfo[nDataDirection]
    if tbWinsCardData and #tbWinsCardData < nIndex then return end
    table.remove(self.tbPlayerWinsCardInfo[nDataDirection] , nIndex)
end

function MahjongData.GetPlayerWinsCardInfo()
    return self.tbPlayerWinsCardInfo
end

function MahjongData.GetPlayerWinsCardInfoByDirection(nDataDirection)
    if self.tbPlayerWinsCardInfo then
        return self.tbPlayerWinsCardInfo[nDataDirection]
    else
        return {}
    end
end

function MahjongData.ClearPlayerWinsCardInfo()
    self.tbPlayerWinsCardInfo = nil
end



function MahjongData.SetPlayerPongKongCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerPongKongCardInfo then
        self.tbPlayerPongKongCardInfo = {}
    end
    self.tbPlayerPongKongCardInfo[nDataDirection] = tbInfo
end

function MahjongData.AddPlayerPongKongCardInfo(nDataDirection, tbInfo)
    if not self.tbPlayerPongKongCardInfo then
        self.tbPlayerPongKongCardInfo = {}
    end
    if not self.tbPlayerPongKongCardInfo[nDataDirection] then
        self.tbPlayerPongKongCardInfo[nDataDirection] = {}
    end
    table.insert(self.tbPlayerPongKongCardInfo[nDataDirection], tbInfo)
end

function MahjongData.RemovePlayerPongKongCardInfo(nDataDirection, nIndex)
    if nIndex <= 0 then return end
    local tbPongKongCardData = self.tbPlayerPongKongCardInfo[nDataDirection]
    if tbPongKongCardData and #tbPongKongCardData < nIndex then return end
    table.remove(self.tbPlayerPongKongCardInfo[nDataDirection] , nIndex)
end

function MahjongData.GetPlayerPongKongCardInfo()
    return self.tbPlayerPongKongCardInfo
    -- return {
    --     {},{},{},{
    --         {nType = 2, nNumber = 7, nMark = 4},
    --         {nType = 1, nNumber = 9, nMark = 1},
    --     }
    -- }
end

function MahjongData.GetPlayerPongKongCardInfoByDirection(nDataDirection)
    return self.tbPlayerPongKongCardInfo[nDataDirection]
end

function MahjongData.ClearPlayerPongKongCardInfo()
    self.tbPlayerPongKongCardInfo = nil
end




function MahjongData.SetPlayerOperateMask(nDataDirection, tbInfo)
    if not self.tbPlayerOperateMaskInfo then
        self.tbPlayerOperateMaskInfo = {}
    end
    self.tbPlayerOperateMaskInfo[nDataDirection] = tbInfo
end

function MahjongData.AddPlayerOperateMask(nDataDirection, tbInfo)
    if not self.tbPlayerOperateMaskInfo then
        self.tbPlayerOperateMaskInfo = {}
    end
    if not self.tbPlayerOperateMaskInfo[nDataDirection] then
        self.tbPlayerOperateMaskInfo[nDataDirection] = {}
    end
    table.insert(self.tbPlayerOperateMaskInfo[nDataDirection], tbInfo)
end

function MahjongData.RemovePlayerOperateMask(nDataDirection, nIndex)
    if nIndex <= 0 then return end
    local tbOperateMaskInfo = self.tbPlayerOperateMaskInfo[nDataDirection]
    if tbOperateMaskInfo and #tbOperateMaskInfo< nIndex then return end
    table.remove(self.tbPlayerOperateMaskInfo[nDataDirection] , nIndex)
end

function MahjongData.GetPlayerOperateMask()
    return self.tbPlayerOperateMaskInfo
end

function MahjongData.GetPlayerOperateMaskByDirection(nDataDirection)
    return self.tbPlayerOperateMaskInfo[nDataDirection]
end

function MahjongData.ClearPlayerOperateMask()
    self.tbPlayerOperateMaskInfo = nil
end

function MahjongData.SetAgentState(nDataDirection, bAgent)
    if not self.tbAgentState then self.tbAgentState = {} end
    local bOldAgent = self.tbAgentState and self.tbAgentState[nDataDirection] or nil
    if (not bOldAgent) or bOldAgent ~= bAgent then
        self.tbAgentState[nDataDirection] = bAgent
        Event.Dispatch(EventType.OnAgentStateChange, nDataDirection, bAgent)
    end
end

function MahjongData.GetAgentState(nDataDirection)
    return self.tbAgentState and self.tbAgentState[nDataDirection] or (GetPlayerIsAgent(nDataDirection) == 1 and true or false)
end

function MahjongData.ClearAgentState()
    self.tbAgentState = nil
end

--牌墙
function MahjongData.SetWalls(tbInfo)
    if not self.tbWalls then
        self.tbWalls = {}
    end
    self.tbWalls = tbInfo
end


function MahjongData.GetWalls()
    return self.tbWalls
end

function MahjongData.GetWallsByDirection(nDataDirection)
    return self.tbWalls and self.tbWalls[nDataDirection] or {}
end

function MahjongData.ClearWalls()
    self.tbWalls = nil
end



function MahjongData.SetPlayerCardInfo(szVarName, value, nDataDirection)
    if not self.tbPlayerCardInfo then
        self.tbPlayerCardInfo = {}
    end
    if not self.tbPlayerCardInfo[nDataDirection] then
        self.tbPlayerCardInfo[nDataDirection] = {}
    end
    self.tbPlayerCardInfo[nDataDirection][szVarName] = value
    Event.Dispatch(EventType.OnSetPlayerCardInfo, nDataDirection, szVarName, value)
end

function MahjongData.GetPlayerCardInfo(szVarName, nDataDirection)

    -- if szVarName == "nHandCardNum" then return 8 end
    if self.tbPlayerCardInfo and self.tbPlayerCardInfo[nDataDirection] then
        return self.tbPlayerCardInfo[nDataDirection][szVarName]
    else
        return nil
    end
end

function MahjongData.ClearPlayerCardInfo()
    self.tbPlayerCardInfo = nil
end

function MahjongData.SetRecordData(nPlayerID)
    if not self.bGetRecordData then self.bGetRecordData = {} end
    self.bGetRecordData[nPlayerID] = true
end

function MahjongData.GetRecordData(nPlayerID)
    return self.bGetRecordData and self.bGetRecordData[nPlayerID]
end

function MahjongData.ClearRecordData()
    self.bGetRecordData = nil
end

function MahjongData.SetGameData(szVarName, value)
    if not self.tbGameInfo then
        self.tbGameInfo = {}
    end
    self.tbGameInfo[szVarName] = value
end

function MahjongData.GetGameData(szVarName)
   return self.tbGameInfo and self.tbGameInfo[szVarName] or nil
end

function MahjongData.ClearGameData()
    self.tbGameInfo = nil
end

function MahjongData.SetSelectionSwapCard(tbSelectionSwapCard)
    self.tbSelectionSwapCard = tbSelectionSwapCard
end

function MahjongData.AddSwapCardInfo(tbCardInfo)
    if not self.tbSelectionSwapCard then self.tbSelectionSwapCard = {tbCard = {}, nCardNum = 0} end
    if self.tbSelectionSwapCard.nCardNum > 2 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAHJONG_SWAPCARD_MAX_NUM)
        return false
    end

    local nType = self.GetCardType(self.tbSelectionSwapCard.tbCard)
    if nType and nType ~= tbCardInfo.nType then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAHJONG_SWAPCARD_TYPE)
        return false
    end

    local nKey = self.CardCardInfoTo10(tbCardInfo)
    self.tbSelectionSwapCard.tbCard[nKey] = (self.tbSelectionSwapCard.tbCard[nKey] or 0) + 1
    self.tbSelectionSwapCard.nCardNum = self.tbSelectionSwapCard.nCardNum + 1

    return true
end

function MahjongData.RemoveSwapCardInfo(tbCardInfo)
    local nKey = self.CardCardInfoTo10(tbCardInfo)
    if self.tbSelectionSwapCard.tbCard[nKey] then
        self.tbSelectionSwapCard.tbCard[nKey] = self.tbSelectionSwapCard.tbCard[nKey] - 1
        self.tbSelectionSwapCard.nCardNum = self.tbSelectionSwapCard.nCardNum - 1
    end
end

function MahjongData.GetSelectionSwapCard()
    return self.tbSelectionSwapCard
end

function MahjongData.ClearSelectionSwapCard()
    self.tbSelectionSwapCard = nil
end


function MahjongData.GetPlayerData()
    return self.tbPlayerData
end

function MahjongData.GetPlayerInfoData()
    return self.tbPlayerData.tPlayerInfo
end

function MahjongData.GetPlayerInfoDataByDataDirection(nDataDirection)
    return self.tbPlayerData.tPlayerInfo[nDataDirection]
end

function MahjongData.ClearPlayerData()
    self.tbPlayerData = nil
end

function MahjongData.SetGameStart(bStartGame)
    self.tbPlayerData.bStartGame = bStartGame
    Event.Dispatch(EventType.OnGameStart)
end

function MahjongData.GetGameStart()
    return self.tbPlayerData.bStartGame
end

--转换PlayerInfo索引的方向为UI的方向，因为玩家需要一直处于下方
function MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nPlayerDirection = self.GetPlayerDataDirection()
    return tAllDirection2PosIndex[nPlayerDirection][nDataDirection]
end

function MahjongData.ConvertUIDirectionToDataDirection(nUIDirection)
    local nPlayerDirection = self.GetPlayerDataDirection()

    for nDataDirection, nDataDirection in pairs(tAllDirection2PosIndex[nPlayerDirection]) do
        if nDataDirection == nUIDirection then
            return nDataDirection
        end
    end
end

function MahjongData.ConvertUIDirectionToStringDataDirection(nUIDirection)
    return tUIPosIndex2Name[nUIDirection]
end

function MahjongData.GetCardType(tbCard)
    for nKey, nCount in pairs(tbCard or {}) do
		if nCount > 0 then
			return math.floor(nKey/10)
		end
	end
end

function MahjongData.CardCardInfoTo10(tbCard)
    if not tbCard then
		return
	end
	local nValue = tbCard.nType * 10 + tbCard.nNumber
	return nValue
end

function MahjongData.GetPlayerAvatar(szGlobalID)
    return self.tbPlayerAvatars and self.tbPlayerAvatars[szGlobalID] or nil
end

function MahjongData.GetMyAvatarData()
    local szGlobalID = g_pClientPlayer.GetGlobalID()
    return self.GetPlayerAvatar(szGlobalID)
end

function MahjongData.GetOtherAvatarDatas()
    local tbAvatars = {}
    local szMyGloabalID = g_pClientPlayer.GetGlobalID()
    for szGlobalID, tbData in pairs(self.tbPlayerAvatars) do
        if szMyGloabalID ~= szGlobalID then
            tbAvatars[szGlobalID] = tbData
        end
    end
    return tbAvatars
end

function MahjongData.GetThisGameGrade(tSettlementData)
	local nGrade = 0
	for k, tData in pairs(tSettlementData or {}) do
		nGrade = nGrade + tData[7]
	end
	return nGrade
end

function MahjongData.GetGradeText(tData)
	local nWinLosType, nHuCardType = self.GetHuCardType(tData[4])
	local nGrade = tData[7] or 0
	local szGradeText = ""
	if nGrade > 0 then
		szGradeText = FormatString("+<D0>", nGrade)
	elseif nGrade < 0 then
		szGradeText = FormatString("<D0>", nGrade)
	else
		if nWinLosType == 0 then
			szGradeText = FormatString("+<D0>", nGrade)
		else
			szGradeText = FormatString("-<D0>", nGrade)
		end
	end
	return szGradeText
end

function MahjongData.GetMultiplyText(nMultiply)
	nMultiply = nMultiply or 0
	local szMultiply = ""
	if nMultiply > 0 then
		szMultiply = FormatString("<D0><D1>", nMultiply, g_tStrings.STR_MAHJONG_MULTIPLY)
	end
	return szMultiply
end


function MahjongData.GetPlayerDataDirection()
    return self.GetPlayerDataDirectionByPlayerID(g_pClientPlayer.dwID)
end

function MahjongData.GetPlayerDataDirectionByPlayerID(nPlayerID)
    local nPlayerDirection = nil
    for nDataDirection, tbData in pairs(self.tbPlayerData.tPlayerInfo) do
        if tbData[1] == nPlayerID then
            nPlayerDirection = nDataDirection
            break
        end
    end
    return nPlayerDirection
end

function MahjongData.CherckCardEqual(tbCardInfo1, tbCardInfo2)
    return tbCardInfo1.nType == tbCardInfo2.nType and tbCardInfo1.nNumber == tbCardInfo2.nNumber
end

function MahjongData.GetMahjongTileInfo(szDirection, nType, nNumber)
	local nSkinID = self.tbPlayerData.nSkinID
    if szDirection == "Down" then
		szDirection = szDirection.."1"
	end
	return Table_GetMahjongTileInfo(nSkinID, szDirection, nType, nNumber)
end

function MahjongData.FormatNumber(nValue)
	return math.floor(nValue/10), nValue%10
end

function MahjongData.Card16ToCardInfo(nValue)
	nValue = ConvertCard16to10(nValue)
	if nValue < 1 then
		return
	end
	local nType, nNumber = self.FormatNumber(nValue)
	return {nType = nType, nNumber = nNumber}
end

function MahjongData.CountDirectionIndex(tDirectionSorte, nIndex)
    local nLength = #tDirectionSorte
    local nTemp = nIndex%nLength
    nIndex = (nTemp == 0) and nLength or nTemp
    return tDirectionSorte[nIndex]
end

--摸牌起始位置  拿牌顺时针
function MahjongData.GetFirstCardPos(nBankerDirection, nDieDot)
    assert(nDieDot > 0, "nDieDot not > 0")

    local tbFirstCardPos = self.GetGameData("tbFirstCardPos")
    if tbFirstCardPos then
    	return tbFirstCardPos.nDataDirection, tbFirstCardPos.nStackPos
    end

    local nIndex = 0
    for k, v in pairs(tDiscardSorte) do
        if nBankerDirection == v then
            nIndex = k
            break
        end
    end
    local nIndex = nIndex + nDieDot - 1 --1是自己
    local nDataDirection = self.CountDirectionIndex(tDiscardSorte, nIndex)
   -- local nDataDirection = tDiscardSorte[nIndex]

    local nStackPos = tDieDotToJumpStackNum[nDieDot] + 1

    self.SetGameData("tbFirstCardPos", {nDataDirection = nDataDirection, nStackPos = nStackPos})
    return nDataDirection, nStackPos
end

--计算牌位置 第几墩的第几张
function MahjongData.GetSecondDrawPos()
    local nBankerDirection = self.GetGameData("nBankerDirection")
    local nDieDot = self.GetGameData("nDieDot1")
    local nDealNum = self.GetGameData("nDealCardNum")

    local nDataDirection, nStackPos = self.GetFirstCardPos(nBankerDirection, nDieDot)
    local nStackNum = math.ceil(nDealNum/2)
    nStackNum = nStackNum + (nStackPos - 1)

    local nStackMax = tDirection2CardStackNnm[nDataDirection]
    nStackNum = nStackNum - nStackMax

    local nIndex = tDealSorte[nDataDirection]
    while nStackNum > 0 do
    	nIndex = nIndex + 1
        nDataDirection = self.CountDirectionIndex(tDealSorte, nIndex)
        nStackMax = tDirection2CardStackNnm[nDataDirection]
        nStackNum = nStackNum - nStackMax
    end

    if nStackNum == 0 then
        nStackNum = nStackMax
    elseif nStackNum < 0 then
        nStackNum = nStackMax + nStackNum
    end

    if (nDealNum%2) == 0 then
        nIndex = 2
    else
        nIndex = 1
    end
    return nDataDirection, nStackNum, nIndex
end


function MahjongData.CardCardInfoTo16(tbCard)
	if not tbCard then
		return
	end
	local nValue = tbCard.nType * 10 + tbCard.nNumber
	nValue = ConvertCard10to16(nValue)
	return nValue
end

function MahjongData.GetWaitCard()
	local nWaitCard = 0
	local nBankerDirection = GetChairMan()
    local nOwnDirection = self.GetPlayerDataDirection()
    local tbWaitCardInfo = self.GetGameData("tbWaitCardInfo")
	if not tbWaitCardInfo and nOwnDirection == nBankerDirection then
		nWaitCard = GetChairManOperateCard(nOwnDirection)
	else
		nWaitCard = self.CardCardInfoTo16(tbWaitCardInfo) or 0
	end
	return nWaitCard
end

function MahjongData.GetFutureWinPoints(tbDiscard)
	local tFutureWinCard = {} --
	local tPoints = {}  --番数列表 {牌值=番数,}
    local nOwnDirection = self.GetPlayerDataDirection()
	local tHandCards = GetPlayerHand(nOwnDirection)
	local nLackType = GetPlayerLack(nOwnDirection)
	local tBonus = GetPlayerBonus(nOwnDirection)
	if tbDiscard then
		local nDiscard = self.CardCardInfoTo16(tbDiscard)
		local nWaitCard = self.GetWaitCard()
		CheckTingAndScore(tFutureWinCard, tHandCards, nLackType, tBonus, nWaitCard, nDiscard, tPoints)
	else
		CheckTing(tFutureWinCard, tHandCards, nLackType, tBonus, true, tPoints)
	end
	return tPoints
end


function MahjongData.GetCanKongCard(nDataDirection) --可杠的牌
	local tData = GetPlayerGangOperate(nDataDirection)
	local tCanKongCard = {}
	local nTemp = 0
	for nValue, nOperateType in pairs(tData) do
		--nTemp = ConvertCard16to10(nValue)
		table.insert(tCanKongCard, {nOperateType, nValue})
	end
	return tCanKongCard
end

function MahjongData.ParseData(nValue1, nValue2, nValue3)
    -- local tTemp = {}

    --设置换牌信息
    if nValue1 and nValue2 and nValue3 then
        self._updateSelectionCard(nValue1, nValue2, nValue3)
    end

	local nDealCardNum = GetCurCardPtr()
    self.SetGameData("nDealCardNum", nDealCardNum)
	local nDieDot1, nDieDot2 = self._getDieDotNum()
    self.SetGameData("nDieDot1", nDieDot1)
    self.SetGameData("nDieDot2", nDieDot2)
    self.SetGameData("nGameState", GetTableMgrState())
    local nBankerDirection = GetChairMan()
    self.SetGameData("nBankerDirection", nBankerDirection)--庄家id
    self.SetGameData("nKongSum", 0)

	local tWinCardList = self._getWinCardList()
	local tDiscardLits = self._getDiscardLits()

	local player = g_pClientPlayer
	local nPlayerID = 0
	local tPlayerInfos = self.GetPlayerInfoData()

	for nDataDirection, tPlayerInfo in pairs(tPlayerInfos or {}) do

		nPlayerID = tPlayerInfo[1]

		local nLackType = GetPlayerLack(nDataDirection)
        self.SetPlayerCardInfo("nLackType", nLackType, nDataDirection)
        self.SetPlayerCardInfo("nDataDirection", nDataDirection, nDataDirection)
        self.SetPlayerCardInfo("bBanker", self.GetGameData("nBankerDirection") == nDataDirection, nDataDirection)
        self.SetPlayerCardInfo("bReadyWinCard", self._gerCanReadyWinCard(nDataDirection), nDataDirection)--是否停牌
        self.SetPlayerCardInfo("nIsAgent", GetPlayerIsAgent(nDataDirection), nDataDirection) --是否托管

        local tPongKongs, nKongNum = self._getLastPongKongCard(nDataDirection)
        -- self.SetPlayerCardInfo("nKongNum", nKongNum, nDataDirection)
        self.SetGameData("nKongSum", self.GetGameData("nKongSum") + nKongNum)

        self.SetPlayerPongKongCardInfo(nDataDirection, tPongKongs)

		if player.dwID == nPlayerID then
            self.SetPlayerHandCardInfo(nDataDirection, self._getOwnHandCard(nDataDirection, nLackType))
            self.SetGameData("nOwnLackType", nLackType)
		else
            self.SetPlayerCardInfo("nHandCardNum", GetPlayerHandCount(nDataDirection), nDataDirection)
		end

        self.SetPlayerDisCardInfo(nDataDirection, tDiscardLits[nDataDirection] or {})
        self.SetPlayerWinsCardInfo(nDataDirection, tWinCardList[nDataDirection] or {})
        self.SetPlayerOperateMask(nDataDirection, GetPlayerOperateMask(nDataDirection))
        self.SetPlayerCardInfo("nHonor", GetPlayerCashHonor(nDataDirection), nDataDirection)--荣誉值
        self.SetPlayerCardInfo("nGrade", GetPlayerCash(nDataDirection), nDataDirection)--叶子道具

	end
    self.SetWalls(self._formatWallData(nBankerDirection, nDieDot1, nDealCardNum, self.GetGameData("nKongSum")))
end

function MahjongData.DiscardCount(nValue)

    local tbDisCardInfo = self.GetPlayerDisCardInfo()
	if not tbDisCardInfo then
		return 0
	end
	local nTemp = 0
	for k, nDataDirection in pairs(tDirectionType) do
		local tbDiscards = tbDisCardInfo[nDataDirection] or {}
		for k, tbCardInfo in pairs(tbDiscards) do
			local nCard = self.CardCardInfoTo16(tbCardInfo)
			if nCard == nValue then
				nTemp = nTemp + 1
			end
		end
	end
	return nTemp
end

function MahjongData.CheckCardPongKong(nCard)
	for k, nDataDirection in pairs(tDirectionType or {}) do
		local tbDatas = GetPlayerBonus(nDataDirection)
		for k, tbData in pairs(tbDatas or {}) do
			if tbData[1] == nCard then
				local nCount = 4
				if tbData[2] == PLAYER_OPERATE_PENG then
					nCount = 3
				end
				return nCount
			end
		end
	end
	return 0
end

function MahjongData.GetOwnHandCardCount(nCard)
	local tbData = GetPlayerHandPure(self.GetPlayerDataDirection())
	local nTemp = 0
	for k, nValue in pairs(tbData) do  --nValue是16进制数
		if nValue == nCard then
			nTemp = nTemp + 1
		end
	end

	local nValue = self.GetWaitCard() --刚摸到的牌要单独算
	if nCard == nValue then
		nTemp = nTemp + 1
	end

	return nTemp
end

function MahjongData.GetHuCardType(nValue)
    local nWinLosType = math.floor(nValue/100) --0胡牌, 1放炮
	local nHuCardType = nValue%100
	return nWinLosType, nHuCardType
end

function MahjongData.GetWinCardNum(nCard)
	local nCount = 0
	local tTemp = {}  --缓存一炮多响的  注意一炮多响

	local tbData = GetCashFlow()
	for k, v in pairs(tbData) do
		local nValue = v[3]
		if nCard == nValue then
			local nWinLosType, nHuCardType = self.GetHuCardType(v[4])
			if nWinLosType == 0 and nHuCardType == PLAYER_OPERATE_HU then
				nCount = nCount + 1
			end

			if nWinLosType == 0 and nHuCardType == PLAYER_OPERATE_HU_1_PAO_N_XIANG then
				tTemp[nValue] = 1
			end
		end
	end

	if tTemp[nCard] then
		nCount = nCount + 1
	end
	return nCount
end

--nCard牌值 16进制
function MahjongData.GetUnknownCount(nCard)
    -- 还没出现的牌数 4 - (弃牌+碰杠胡+自己手牌)
    local nCount = self.DiscardCount(nCard)
	nCount = nCount + self.GetOwnHandCardCount(nCard)
	--碰
	nCount = nCount + self.CheckCardPongKong(nCard)
	--胡
	nCount = nCount + self.GetWinCardNum(nCard)
	local nCount = nCardMaxNum - nCount

	return nCount < 0 and 0 or nCount
end

function MahjongData.GetCashFlowData()
	local tbData = GetCashFlow()
	local tTemp = {}
	for k, v in pairs(tbData) do
		local nDirection = v[1]  -- {玩家1方向ID, 玩家2方向ID, 牌值(16进制), 类型, 胡牌称号ID, huMask, 玩家1的cash变化量}
		tTemp[nDirection] = tTemp[nDirection] or {}
		table.insert(tTemp[nDirection], v)
	end
	return tTemp
end

function MahjongData.GetAliasByDirection(nDirection)
	local nPosIndex = 1

	if nDirection ~= self.GetPlayerDataDirection() and nDirection ~= 0 then
		nPosIndex = self.ConvertDataDirectionToUIDirection(nDirection)
	end
	return g_tStrings.tMahjongPosAlias[nPosIndex]
end

function MahjongData.GetMahjongWinTitleName(nSkinID, nTitleID)
	local szName
	local tbData = Table_GetMahjongTitleInfo(nSkinID, nTitleID)
	if tbData then
		szName = tbData.szName
	end
	return UIHelper.GBKToUTF8(szName)
end

function MahjongData.GetCardIndexInMyHandCards(tbCardInfo)
    if not tbCardInfo then return 0 end
    local tbCardList = self.GetMyHandCardInfo()
    if tbCardList then
        for nIndex, tbInfo in ipairs(tbCardList) do
            if self.CherckCardEqual(tbInfo, tbCardInfo) then
                return nIndex
            end
        end
    end
    return 0--手牌中没有此牌
end

function MahjongData.GetBillContent(tData)
	local szText = ""
	local nWinLosType, nHuCardType = self.GetHuCardType(tData[4])
	local nGrade = tData[7] or 0

	local tName = tbType2Name[nHuCardType]
	if tName then
		local nIndex = nWinLosType == 0 and 1 or 2
		szText = tName[nIndex]
	end

	local nWinMask = tData[6]
	local tWinMask = CalcHuMask(nWinMask) or {}
	local nTitleID = tData[5]
	if nHuCardType == PLAYER_OPERATE_HU then
		local tTxt = {}
		if nTitleID > 0 then
			szName = self.GetMahjongWinTitleName(self.tbPlayerData.nSkinID, nTitleID)
			if szName then
				table.insert(tTxt, szName)
			end
		end

		if tWinMask[1] > 0 and tWinMask[2] > 0 then
			--杠上开花
			table.insert(tTxt, g_tStrings.tMahjongSettlemen[11])
		elseif tWinMask[1] > 0 and tWinMask[2] == 0 then
			--杠上炮
			table.insert(tTxt, g_tStrings.tMahjongSettlemen[10])
		end

		if tWinMask[3] > 0 then
			--海底捞月
			table.insert(tTxt, g_tStrings.tMahjongSettlemen[12])
		end

		if tWinMask[4] > 0 then
			--抢杠胡
			table.insert(tTxt, g_tStrings.tMahjongSettlemen[13])
		end

		if #tTxt > 0 then
			local szName = ""
			if #tTxt > 2 then --胡牌别称超过2种只显示2种
				szName = table.concat({tTxt[1], "、", tTxt[2], "..."})
			else
				szName = table.concat(tTxt, "、")
			end
			szText = FormatString("<D0>(<D1>)", szText, szName)
		end
	end
	return szText
end

function MahjongData.GetSettlementTitleSFXPath(tbSettlementData)
    if not tbSettlementData then
		return
	end
	local tTemp = {}
	for k, tData in pairs(tbSettlementData) do
		if tData[7] > 0 and tData[5] > 0 then --胡牌类型id越小越高级
			table.insert(tTemp, tData)
		end
	end

	local fnComp = function (a, b)
		return a[5] < b[5]
	end
	table.sort(tTemp, fnComp)

	if #tTemp > 0 then
		local nTitleID = tTemp[1][5]
		local tData = Table_GetMahjongTitleInfo(m_SkinID, nTitleID)
		if tData then
			return tData.szSFXPath
		end
	end
    return ""
end

function MahjongData.GetAllPlayerID()
    local tbPlayerID = {}
    local player = g_pClientPlayer
    if self.tbPlayerData.tPlayerInfo then
        for nDataDirection, tbPlayerInfo in pairs(self.tbPlayerData.tPlayerInfo) do
            local nPlayerID = tbPlayerInfo[1] or 0
            if nPlayerID > 0 then
                table.insert(tbPlayerID, nPlayerID)
            end
        end
    end
    return tbPlayerID
end

function MahjongData.CanDisCard()
    local bDisCard = self.GetGameData("bDisCard")
    if bDisCard == nil then bDisCard = false end
    return bDisCard
end


function MahjongData.ConfirmSwapCard()
    local tbCardInfo = self.GetSelectionSwapCard()
    local tbCard = nil
    if tbCardInfo then
        tbCard = tbCardInfo.tbCard
    end

    if not tbCard then return end

    local i = 0
    local tTemp = {0, 0, 0}

    for k, v in pairs(tbCard) do
        if v then
            for j = 1, v do
                i = i + 1
                tTemp[i] = ConvertCard10to16(k)
            end
        end
    end
    if i < 3 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAHJONG_SWAPCARD_TIP)
        return false
    end
    self.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_EXCHANGE, tTemp[1], tTemp[2], tTemp[3])
    return true
end

function MahjongData.GetMahjongRecordData(dwPlayerID)
    local player
	local playerOwn = g_pClientPlayer
	if playerOwn.dwID == dwPlayerID then
		player = playerOwn
	else
		player = GetPlayer(dwPlayerID)
	end

	if not player then
		return
	end
	local tbData = {
		nCurrStreakWin = 0,  --当前连胜场次
		nHistoryStreakWin = 0,  --历史连胜场次
		nHistoryAllCount = 0,  --历史总场次
		nHistoryAllWin = 0,  --历史总胜场次
		nHistoryMaxWinMultiple = 0, --历史最大胡牌番数
		nHistoryMaxWinType = 0, --历史最大胡牌类型
		--nHideScore = 0,	 --隐藏分
        --nHonorScore = 0, --雀神点数
	}

	tbData.nCurrStreakWin = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.CUR_CONTINUE_WIN_COUNT[1], REMOTE_MAHJONG_DATAS.CUR_CONTINUE_WIN_COUNT[2]) or 0
	tbData.nHistoryStreakWin = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HISTORY_CONTINUE_WIN_COUNT[1], REMOTE_MAHJONG_DATAS.HISTORY_CONTINUE_WIN_COUNT[2]) or 0
	tbData.nHistoryAllCount = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HISTORY_MATCH_COUNT[1], REMOTE_MAHJONG_DATAS.HISTORY_MATCH_COUNT[2]) or 0
	tbData.nHistoryAllWin = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HISTORY_WIN_COUNT[1], REMOTE_MAHJONG_DATAS.HISTORY_WIN_COUNT[2]) or 0
	tbData.nHistoryMaxWinMultiple = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HISTORY_MAX_CASH[1], REMOTE_MAHJONG_DATAS.HISTORY_MAX_CASH[2]) or 0
	tbData.nHistoryMaxWinType = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HISTORY_MAX_CASH_NAME[1], REMOTE_MAHJONG_DATAS.HISTORY_MAX_CASH_NAME[2]) or 0
	--tbData.nHideScore = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.HIDE_SCORE[1], REMOTE_MAHJONG_DATAS.HIDE_SCORE[2])
	--tbData.nHonorScore = player.GetRemoteArrayUInt(MAHJONG_DATAS_REMOTE_ID, REMOTE_MAHJONG_DATAS.CASH_HONOR[1], REMOTE_MAHJONG_DATAS.CASH_HONOR[2])
	return tbData
end

function MahjongData.GetMahjongRecordText(nPlayerID)
    local bGetRecordData = self.GetRecordData(nPlayerID)
    if not bGetRecordData then
		return g_tStrings.STR_MAHJONG_NOT_RESULT_TIP
	end
	local tRecordData = self.GetMahjongRecordData(nPlayerID)
	if not tRecordData then
		return g_tStrings.STR_MAHJONG_NOT_RESULT_TIP
	end
	local szWinType = self.GetMahjongWinTitleName(self.tbPlayerData.nSkinID, tRecordData.nHistoryMaxWinType) or ""
	local nWinRate = 0
	if tRecordData.nHistoryAllCount > 0 then
		nWinRate = math.ceil((tRecordData.nHistoryAllWin/tRecordData.nHistoryAllCount)*100)
	end
	local szWinRate = FormatString("<D0>%", nWinRate)
	local szText = FormatString(g_tStrings.STR_MAHJONG_RESULT_TIP, tRecordData.nHistoryAllCount, szWinRate, tRecordData.nHistoryStreakWin,
		tRecordData.nHistoryAllWin, tRecordData.nHistoryMaxWinMultiple, szWinType)
	return szText
end

function MahjongData.DelayCall(szKey, nInterval, func)
    if not self.tbTimerFunc then self.tbTimerFunc = {} end
    if type(nInterval) == 'boolean' then
        self.__removeDelayCall(szKey)
        return
    end
    local tbInfo = {}
    tbInfo.szKey = szKey
    tbInfo.nCallTime = Timer.RealMStimeSinceStartup() + nInterval
    tbInfo.func = func
    self.tbTimerFunc[szKey] = tbInfo
end

function MahjongData.OnExit()
    self.SendReadyStartGame(tPlayerState.nLeave)
    self.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_CLOSE_UI)
	RemoteCallToServer("On_HomeLand_CloseMaJiang")
    UIMgr.Close(VIEW_ID.PanelMahjongMain)
    UIMgr.Close(VIEW_ID.PanelMahjongSettlementPop)
    self.ClearData()
end

function MahjongData.ClearData()
    self.ClearPlayerData()
    self.ClearReGameData()
    self.RemoveBreathTimer()
    self.ClearRecordData()
    Event.UnRegAll(self)
end


function MahjongData.ClearReGameData()
    self.ClearAgentState()
    self.ClearGameData()
    self.ClearLastDisCardInfo()
    self.ClearPlayerCardInfo()
    self.ClearPlayerDisCardInfo()
    self.ClearPlayerHandCardInfo()
    self.ClearPlayerOperateMask()
    self.ClearPlayerPongKongCardInfo()
    self.ClearPlayerWinsCardInfo()
    self.ClearSelectionSwapCard()
    self.ClearWalls()

    Event.Dispatch(EventType.OnClearGameData)
end

function MahjongData.GetCardImg(szTex, nFrame)
    local nTex = tonumber(string.match(szTex, "(%d+).UITex"))
    if not nTex then
        LOG.INFO("======GetCardImg Failed %s %s=====", tostring(szTex), debug.traceback())
    end
    local szImage = HomeLandMahjongDownModImg[nFrame]
    if nTex ~= 1 then
        local szTex = string.format("%02d", nTex)
        szImage = string.gsub(szImage, "UIAtlas2_Mahjong_MahjongIcon_", "UIAtlas2_Mahjong_MahjongIcon_"..szTex .."_")
    end
    return szImage
end

function MahjongData.GetBackCardImg(nUIDirection)
    local nSkinID = MahjongData.GetSkinInfoID("Panel")
    local szSkinID = nSkinID == 2 and "_" .. string.format("%02d", nSkinID) .. "_" or "_"
    local szUIDirection = (nUIDirection == tUIPosIndex.Down or nUIDirection == tUIPosIndex.Up) and "Vertical" or "Horizontal"
    if nSkinID == 3 then
        szUIDirection = szUIDirection .. "BG"
    end
    return "UIAtlas2_Mahjong_MahjongIcon" .. szSkinID .. szUIDirection
end

function MahjongData.GetSkinInfoID(szType)
    if not self.tbPlayerData then
        return
    end
    local nSkinID = self.tbPlayerData.nSkinID
    return Table_GetMahjongSkinID(nSkinID, szType)
end
------------------------------------------------------------------------------辅助函数 End------------------------------------------------------------



------------------------------------------------------------------------------发协议 Start------------------------------------------------------------
function MahjongData.SendReadyStartGame(nPlayerState)
    local player = g_pClientPlayer
	if player then
        local nOwnDirection = self.GetPlayerDataDirection()
		GetHomelandMgr().ChangeLOSlot(self.tbPlayerData.nFurnitureID, nPlayerState, player.dwID, nOwnDirection)
	end
end

function MahjongData.ApplyRoleEntryInfo(tbPlayerID)
    if tbPlayerID and #tbPlayerID > 0 then

        local tbGlobalID = {}
        for nIndex, nPlayerID in ipairs(tbPlayerID) do
            local player = GetPlayer(nPlayerID)
            if player then
                local szGlobalID = player.GetGlobalID()
                local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(szGlobalID)
                if tbRoleEntryInfo then--数据存在则更新，不存在加入数组再次拉取
                    self._updatePlayerAvatarData(tbRoleEntryInfo, szGlobalID)
                else
                    table.insert(tbGlobalID, szGlobalID)
                end
            end
        end

        if #tbGlobalID == 0 then
            Event.Dispatch(EventType.OnUpdatePlayerInfo)
        else
            GetSocialManagerClient().ApplyRoleEntryInfo(tbGlobalID)
        end
	end
end

function MahjongData.SendServerOperate(nOperateType, nValue1, nValue2, nValue3, nValue4)
    self.GetGameMgr().Operate(nOperateType, nValue1 or 0, nValue2 or 0, nValue3 or 0, nValue4 or 0)
end

function MahjongData.ApplyMahjongRecordData(nPlayerID)
    PeekPlayerRemoteData(nPlayerID, MAHJONG_DATAS_REMOTE_ID)
end
------------------------------------------------------------------------------发协议 End------------------------------------------------------------


------------------------------------------------------------------------------内部函数 Start------------------------------------------------------------
function MahjongData._updateSelectionCard(nValue1, nValue2, nValue3)
    local tbCardInfo = {}
    self._setCardInfo(tbCardInfo, nValue1)
    self._setCardInfo(tbCardInfo, nValue2)
    self._setCardInfo(tbCardInfo, nValue3)
    self.SetSelectionSwapCard({tbCard = tbCardInfo, nCardNum = 3})
end


--停牌
function MahjongData._gerCanReadyWinCard(nDataDirection)
	local nValue = GetPlayerIsLockTing(nDataDirection)
	return nValue > 0 or false
end

--获取历史胡牌数据
function MahjongData._getWinCardList()
	local tData = GetHuRecord()  --{座位号, 牌值, 座位号, 牌值, 座位号, 牌值...}
	local tTemp = {}
	local nDataDirection
	for k, v in ipairs(tData) do
		if (k % 2) > 0 then
			nDataDirection = v
		else
			tTemp[nDataDirection] = tTemp[nDataDirection] or {}
			local tCardInfo = self.Card16ToCardInfo(v)
			table.insert(tTemp[nDataDirection], tCardInfo)
		end
	end
	return tTemp
end


function MahjongData._getDiscardLits()
	local tTemp = {}
	local tData = GetPublicAbandonCard(false)  --传false取全部值
	local nDataDirection
	for k, v in ipairs(tData) do
		if (k % 2) > 0 then
			nDataDirection = v
		else
			tTemp[nDataDirection] = tTemp[nDataDirection] or {}
			local tCardInfo = self.Card16ToCardInfo(v)
			table.insert(tTemp[nDataDirection], tCardInfo)
		end
	end
	return tTemp
end


function MahjongData._getWinCardNum(nCard)
	local nCount = 0
	local tTemp = {}  --缓存一炮多响的  注意一炮多响

	local tData = GetCashFlow()
	for k, v in pairs(tData) do
		local nValue = v[3]
		if nCard == nValue then
			local nWinLosType, nHuCardType = self.GetHuCardType(v[4])
			if nWinLosType == 0 and nHuCardType == PLAYER_OPERATE_HU then
				nCount = nCount + 1
			end

			if nWinLosType == 0 and nHuCardType == PLAYER_OPERATE_HU_1_PAO_N_XIANG then
				tTemp[nValue] = 1
			end
		end
	end

	if tTemp[nCard] then
		nCount = nCount + 1
	end
	return nCount
end

function MahjongData._getTuiSuiData()
	local tbData = GetCashFlow()
	local tTemp = {}
	local tTuiSuiType = { --退税显示内容
		[nWeiTingPaiType] = 1,
		[PLAYER_OPERATE_TUISHUI] = 1,
		[PLAYER_OPERATE_CHECK_COLORPIG] = 1,
		[PLAYER_OPERATE_CHECK_DAJIAO] = 1,
	}

	for k, v in pairs(tbData) do
		local nWinLosType, nHuCardType = self.GetHuCardType(v[4])
		if tTuiSuiType[nHuCardType] then
			tTemp[nHuCardType] = tTemp[nHuCardType] or {}
			local nDataDirection = v[1]
			if nHuCardType == PLAYER_OPERATE_TUISHUI and v[7] < 0 then  --退税要显示未听牌特效
				tTemp[nWeiTingPaiType] = tTemp[nWeiTingPaiType] or {}
				tTemp[nWeiTingPaiType][nDataDirection] = 0
			end
			tTemp[nHuCardType][nDataDirection] = (tTemp[nHuCardType][nDataDirection] or 0) + v[7]
		end
	end
	return tTemp
end


--获取历史碰杠数据
function MahjongData._getLastPongKongCard(nDataDirection)
	local nTemp = 0
	local nType, nNumber
	local tPongKongs = {}
	local nKongNum = 0

	local tDatas = GetPlayerBonus(nDataDirection)
	for k, tData in pairs(tDatas) do --[1] = {牌值, 类型},
		nTemp = ConvertCard16to10(tData[1])
		nType, nNumber = self.FormatNumber(nTemp)
		if nNumber > 0 then
			if tData[2] == PLAYER_OPERATE_MING_GANG or tData[2] == PLAYER_OPERATE_AN_GANG
				or tData[2] == PLAYER_OPERATE_GANG_AFTER_PENG then
				nKongNum = nKongNum + 1
			end
			table.insert(tPongKongs, {nType = nType, nNumber = nNumber, nMark = tData[2]})
		end
	end
	return tPongKongs, nKongNum
end

function MahjongData._getDieDotNum()
	local nValue = GetDiceNum()
	return math.floor(nValue/10), nValue%10
end

function MahjongData._getFirstCardPos(nBankerDirection, nDieDot)
    -- assert(nDieDot > 0, "nDieDot not > 0")

    local tbFirstCardPos = self.GetGameData("tbFirstCardPos")
    if tbFirstCardPos then
    	return tbFirstCardPos.nDataDirection, tbFirstCardPos.nStackPos
    end

    local nIndex = 0
    for k, v in pairs(tDiscardSorte) do
        if nBankerDirection == v then
            nIndex = k
            break
        end
    end
    local nIndex = nIndex + nDieDot - 1 --1是自己
    local nDataDirection = self.CountDirectionIndex(tDiscardSorte, nIndex)
   -- local nDataDirection = tDiscardSorte[nIndex]

    local nStackPos = (tDieDotToJumpStackNum[nDieDot] or 0) + 1
    self.SetGameData("tbFirstCardPos", {nDataDirection = nDataDirection, nStackPos = nStackPos})
    return nDataDirection, nStackPos
end


function MahjongData._formatWallData(nBankerDirection, nDieDot, nDiscardNum, nKongSum) --杠牌从最后面摸 待加逻辑
	local nStartDirection, nStackPos = self._getFirstCardPos(nBankerDirection, nDieDot)
	local tTemp = {}
	local nCount = 0
	local tState
	local nStartIndex = tDealSorte[nStartDirection]
	local nEndIndex = tDealSorte[nStartDirection] + 4 - 1
	local nDataDirection = 0
	local nDiscardStack = math.ceil(nDiscardNum/2) --打出去的墩数
	for i = nStartIndex, nEndIndex do
		nDataDirection = self.CountDirectionIndex(tDealSorte, i)
		tTemp[nDataDirection] = tTemp[nDataDirection] or {}
		local nNum = tDirection2CardStackNnm[nDataDirection] --方位->墩数
		for j = 1, nNum do
			if i == nStartIndex and j < nStackPos then
				tState = {true, true}
			else
				nCount = nCount + 1

				if nCount > nDiscardStack then
					tState = {true, true}
				elseif nCount == nDiscardStack and (nDiscardNum%2) > 0 then
					tState = {false, true}
				else
					tState = {false, false}
				end
			end

			table.insert(tTemp[nDataDirection], tState)

		end
	end
	return tTemp
end

function MahjongData._setCardInfo(tbCardInfo, nValue)
    local nValue = ConvertCard16to10(nValue)
	if tbCardInfo[nValue] then
		tbCardInfo[nValue]= tbCardInfo[nValue] + 1
	else
		tbCardInfo[nValue] = 1
	end
end

 --获取自己手牌
function MahjongData._getOwnHandCard(nDataDirection, nLackType)
    local tData = GetPlayerHandPure(nDataDirection)
    local nOwnLackType = self.GetGameData("nOwnLackType")
    if not nLackType and nOwnLackType then
            nLackType = nOwnLackType
    end
    local tHandCard = {}
    local nTemp = 0
    local nType, nNumber
    for k, nValue in pairs(tData) do  --nValue是16进制数
        nTemp = ConvertCard16to10(nValue)
        nType, nNumber = self.FormatNumber(nTemp)
        local nSort = nTemp
        if nLackType and nLackType == nType then
            nSort = nTemp * 30
        end
        table.insert(tHandCard, {nType = nType, nNumber = nNumber, nSort = nSort})
    end

    local nBankerDirection = GetChairMan()
    local nDealCardNum = GetCurCardPtr()
    local tData = GetPublicAbandonCard(false) or {}
    if nDataDirection == nBankerDirection and (#tData) == 0 then
        --庄家在换牌后，出第一次打牌前 只能获取到13张牌，第14张牌需要额外取
        local nValue = GetChairManOperateCard(nDataDirection)
        if nValue > 0 then
            nTemp = ConvertCard16to10(nValue)
            nType, nNumber = self.FormatNumber(nTemp)
            local nSort = nTemp
            if nLackType and nLackType == nType then
                nSort = nTemp * 30
            end
            table.insert(tHandCard, {nType = nType, nNumber = nNumber, nSort = nSort})
        end
    end

    self._cardSort(tHandCard)
    return tHandCard
end

function MahjongData._cardSort(tCards)
	local fnComp = function(a, b)
		return a.nSort < b.nSort
	end

	table.sort(tCards, fnComp)
end

function MahjongData._updatePlayerAvatarData(tbRoleEntryInfo, szGlobalID)

    if not self.tbPlayerAvatars then self.tbPlayerAvatars = {} end

    -- local nDataDirection = self.GetPlayerDataDirectionByPlayerID(tbRoleEntryInfo.dwPlayerID)

    local tPlayer = nil
    if tbRoleEntryInfo then
        tPlayer = {dwPlayerID = tbRoleEntryInfo.dwPlayerID, nRoleType = tbRoleEntryInfo.nRoleType, dwMiniAvatarID = tbRoleEntryInfo.dwMiniAvatarID,
        dwForceID = tbRoleEntryInfo.nForceID, szName = tbRoleEntryInfo.szName, nDataDirection = self._findDirection(tbRoleEntryInfo.dwPlayerID)}
    end

    self.tbPlayerAvatars[szGlobalID] = tPlayer
end

function MahjongData._findDirection(nPlayerID)
    if not self.tbPlayerData then return nil end
    for nDataDirection, tbData in pairs(self.tbPlayerData.tPlayerInfo) do
        local playerID = tbData[1]
        if nPlayerID == playerID then
            return nDataDirection
        end
    end
    return nil
end

function MahjongData._registerEvent()
    Event.Reg(self, "FELLOWSHIP_ROLE_ENTRY_UPDATE", function(szGlobalID)
        local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(szGlobalID)
        self._updatePlayerAvatarData(tbRoleEntryInfo, szGlobalID)
        Event.Dispatch(EventType.OnUpdatePlayerInfo)
    end)

    Event.Reg(self, "MINIGAME_OPERATE", function()
        local nGameType, nPlayerID, nOperationType = arg0, arg1, arg2
		if nGameType ~= 1 or not nOperationType then
			return
		end

        local tPlayerInfo = self.tbPlayerData and self.tbPlayerData.tPlayerInfo or {}
		if  #tPlayerInfo < nGamePlayerNum then
			return
		end

        if not self.tbPlayerData.bStartGame and nOperationType ~= PLAYER_OPERATE_PRE_EXCHANGE then
			return
		end

        local tData = tMessageType2FunName[nOperationType]
		if tData then
			if tData.szFunName and MahjongData[tData.szFunName] then
				MahjongData[tData.szFunName](arg2, arg3, arg4, arg5)
			end
		end
    end)

    Event.Reg(self, "REMOTE_DATA_MAHJONG", function()
        local nPlayerID, nType = arg0, arg1
		if MAHJONG_DATAS_REMOTE_ID == nType then
            self.SetRecordData(nPlayerID)
		end
    end)

end



function MahjongData.__removeDelayCall(szKey)
    if self.tbTimerFunc[szKey] then
        self.tbTimerFunc[szKey] = nil
    end
end

function MahjongData._callError(err)
    LOG.INFO("--------_callError: %s\n-------", tostring(err))
    LOG.INFO(debug.traceback())
end

function MahjongData._onDelayCall()
    local nTime = Timer.RealMStimeSinceStartup()
    for szKey, tbInfo in pairs(self.tbTimerFunc) do
        if tbInfo and tbInfo.nCallTime <= nTime then
            xpcall(tbInfo.func, self._callError)
            self.__removeDelayCall(tbInfo.szKey)
        end
    end
end

------------------------------------------------------------------------------内部函数 End------------------------------------------------------------

function MahjongData.CreateTestData()
    return {
        {nType = 1, nNumber = 1},
        {nType = 2, nNumber = 1},
        {nType = 3, nNumber = 1},
        {nType = 1, nNumber = 2},
        {nType = 2, nNumber = 2},
        {nType = 3, nNumber = 2},
        {nType = 1, nNumber = 3},
        {nType = 2, nNumber = 3},
        {nType = 3, nNumber = 3},
        {nType = 1, nNumber = 4},
        {nType = 2, nNumber = 4},
        {nType = 3, nNumber = 4},
        {nType = 1, nNumber = 5},
        -- {nType = 2, nNumber = 5},
        -- {nType = 3, nNumber = 5},
    }
end