-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: DdzPokerData
-- Date: 2023-08-02 11:04:17
-- Desc: 斗地主数据类
-- ---------------------------------------------------------------------------------
require("Lua/UI/Poker/DdzPokerIdentityCustomValueName.lua")
require("Lua/UI/Poker/DdzPoker3playersPlayerMgr.lua")
DdzPokerData = DdzPokerData or {className = "DdzPokerData"}
local self = DdzPokerData
DdzPokerData.szTitle = "斗地主"
DdzPokerData.TABLESTATE = {
	[DDZ_CONST_TABLE_STATE_INIT] = "牌桌初始化",
	[DDZ_CONST_TABLE_STATE_SHOW_LAIZI_TIAN] = "天癞子特效",
	[DDZ_CONST_TABLE_STATE_SEND_CARD] = "发牌阶段",
	[DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN] = "等待玩家叫地主",
	[DDZ_CONST_TABLE_STATE_SET_CHAIRMAN] = "等待玩家抢地主",
	[DDZ_CONST_TABLE_STATE_SHOW_CHAIRMAN] = "地主特效阶段",
	[DDZ_CONST_TABLE_STATE_SHOW_LAIZI_DI] = "地癞子特效",
	[DDZ_CONST_TABLE_STATE_DOUBLE] = "地癞子（开始出牌、最后一次明牌）",
	[DDZ_CONST_TABLE_STATE_SHUFFLE_MINGPAI] = "客户端发牌阶段，玩家可以选择明牌",
	[DDZ_CONST_TABLE_STATE_WAIT_CS_SEND] = "等待玩家出牌",
	[DDZ_CONST_TABLE_STATE_SETTLEMENT] = "春天结算",
	[DDZ_CONST_TABLE_STATE_END_GAME] = "结算界面",
	[DDZ_CONST_TABLE_STATE_KILL_DOUDIZHU] = "关闭小游戏",
}
DdzPokerData.PLAYER_STATE = {
	CAN_CALL 		= 1, 	--"可以叫地主",
	CAN_QIANG 		= 2, 	--"可以抢地主",
	CALL_ISDIZHU 	= 3,	--"叫地主后当前为地主",
	QIANG_ISDIZHU 	= 4,	--"抢地主后当前为地主"
	BU_CALL			= 5,	-- "不叫"
	BU_QIANG 		= 6,	--"不抢"
}

DdzPokerData.tDdzsound = {
	szBGM = "data\\sound\\专有\\小游戏\\斗地主音效\\斗地主音乐_普通音乐.mp3", --打牌全程背景音
	szFastBGM = "data\\sound\\专有\\小游戏\\斗地主音效\\斗地主音乐_紧张音乐.mp3",  --加快节奏版的背景音
	szWinBGM = "data\\sound\\专有\\小游戏\\麻将音效\\家园麻将胜利.ogg",  --结算时（赢钱）音乐
	szLoseBGM = "data\\sound\\专有\\小游戏\\麻将音效\\家园麻将未胡牌失败.wav",  --结算时（输钱）音乐
	szGetCard = "data\\sound\\专有\\小游戏\\斗地主音效\\发牌时音效.ogg",  --发牌时音效
	szConfirm = "data\\sound\\专有\\小游戏\\斗地主音效\\确定的音效.ogg",  --确定的音效
	szJiaBei = "data\\sound\\专有\\小游戏\\斗地主音效\\加倍.ogg",  --加倍
	szSuperJiaBei = "data\\sound\\专有\\小游戏\\斗地主音效\\超级加倍.ogg",  --超级加倍
	szPlayCard = "data\\sound\\专有\\小游戏\\斗地主音效\\出牌时音效.ogg",  --出牌时音效
	szChooseCard = "data\\sound\\专有\\小游戏\\斗地主音效\\选牌时音效.ogg",  --选牌时音效
	szLessCard = "data\\sound\\专有\\小游戏\\斗地主音效\\倒计时2张牌_Loop.ogg",  --倒计时2张牌
	szCountDown = "data\\sound\\专有\\小游戏\\斗地主音效\\出牌倒计时.ogg",  --出牌倒计时
	szShowCard = "data\\sound\\专有\\小游戏\\斗地主音效\\结束时摊牌.ogg",  --结束时摊牌
	szMoney = "data\\sound\\专有\\小游戏\\麻将音效\\扣钱.ogg",  --扣钱时
	szShunZi = "data\\sound\\专有\\小游戏\\斗地主音效\\顺子.ogg",  --顺子
	szLianDui = "data\\sound\\专有\\小游戏\\斗地主音效\\连对.ogg",  --连对
	szFeiJi = "data\\sound\\专有\\小游戏\\斗地主音效\\飞机.ogg",  --飞机
	szBoom = "data\\sound\\专有\\小游戏\\斗地主音效\\炸弹.ogg",  --炸弹
	szRocket = "data\\sound\\专有\\小游戏\\斗地主音效\\王炸.ogg",  --王炸
	szSpring = "data\\sound\\专有\\小游戏\\斗地主音效\\春天.ogg",  --春天
	szLaizi = "data\\sound\\专有\\小游戏\\斗地主音效\\赖子.ogg",  --癞子
}

DdzPokerData.BigJokerSymbol = "BigJoker"
DdzPokerData.LittleJokerSymbol = "LittleJoker"
DdzPokerData.tbPokerNumAtlasSymbol =
{
	"" ,"" ,"3" , "4" , "5" , "6" , "7" , "8" , "9" , "10" , "J" , "Q" , "K" ,"A" , "2" , DdzPokerData.LittleJokerSymbol  , DdzPokerData.BigJokerSymbol
}
DdzPokerData.tbPokerColorAtlasSymbol =
{
	CounterClub = "CounterClub",
	CounterDiamond = "CounterDiamond",
	CounterHeart = "CounterHeart",
	CounterSpade = "CounterSpade",
	GrayClub = "GrayClub",
	GrayDiamond = "GrayDiamond",
	GrayHeart = "GrayHeart",
	GraySpade = "GraySpade",
	CounterNum = "CounterNum",
}

DdzPokerData.HandCardColorMap =
{
	--[] = "UIAtlas2_Ddz_Poker_LaiCommon",
	[0] = "UIAtlas2_Ddz_Poker%s_SpadeCommon",
	[1] = "UIAtlas2_Ddz_Poker%s_HeartCommon",
	[2] = "UIAtlas2_Ddz_Poker%s_ClubCommon",
	[3] = "UIAtlas2_Ddz_Poker%s_DiamondCommon",
	[4] = "UIAtlas2_Ddz_Poker%s_LaiCommon",
	[DdzPokerData.LittleJokerSymbol] = "UIAtlas2_Ddz_Poker%s_LittleJoker",
	[DdzPokerData.BigJokerSymbol] = "UIAtlas2_Ddz_Poker%s_BigJoker",
}

DdzPokerData.szPokerAtlasPath = "UIAtlas2_Ddz_Poker_"

DdzPokerData.tbPokerCounterLaiziAtlas =
{
	"UIAtlas2_Ddz_PokerCounter_TianLaizi",
	"UIAtlas2_Ddz_PokerCounter_DiLaizi",
	"UIAtlas2_Ddz_PokerCounter_OneLaizi",
}
DdzPokerData.MAX_PLAYER_NUM = 3
DdzPokerData.TABLE_SLOT_STATE = {
	["LIVE"] = 0,
	["UNREADY"] = 1,
	["READY"] = 2,
	["MINGPAI_READY"] = 3,
	["READY_TO_UNREADY"] = 4,
	["LEAVE"] = 5,
}
DdzPokerData.CARD_START = 3
DdzPokerData.CARD_END = 17
DdzPokerData.DataModel = {}

DdzPokerData.SkinImageAtlas =
{
	[12710] = "UIAtlas2_Ddz_PokerBack_BackNormal",
	[12788] = "UIAtlas2_Ddz_PokerBack_BackBG",
	[14142] = "UIAtlas2_Ddz_PokerBack_BackNY"
}

DdzPokerData.nOnePlayerMaxCardCount = 20

DdzPokerData.tPlayerDirection = {
    Left = "Left",
    Right = "Right",
    Down = "Down",
	Common = "Common"
}

DdzPokerData.DOUBLESTATE = {
	NORMAL = 0,
	JIABEI = 1,
	SUPER_JIABEI = 2,
	BU_JIABEI = 3,
}

DdzPokerData.DOUBLE_TIMES = {
	[DdzPokerData.DOUBLESTATE.NORMAL] = 1,
	[DdzPokerData.DOUBLESTATE.JIABEI] = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_NORMAL],
	[DdzPokerData.DOUBLESTATE.SUPER_JIABEI] = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_SUPER],
	[DdzPokerData.DOUBLESTATE.BU_JIABEI] = 1,
}

DdzPokerData.tbEventID = {
	OnChangeDdzRule = "Ddz_ChangeDdzRule",
	OnAddPlayer = "Ddz_OnAddPlayer",
	OnPlayerLeave = "Ddz_OnPlayerLeave",
	OnClickCombiChoose = "Ddz_OnClickCombiChoose",
	OnPlay = "Ddz_OnPlay"
}

DdzPokerData.nApplyFellowshipCardType = 6
DdzPokerData.bLockHandCard = false

DdzPokerData.LaiZiState =
{
	Tian = "Tian",
	Di = "Di",
	Single = "Single"
}

DdzPokerData.COUNTDOWN_TIME = 5

local CARD = {
	LAIZI = {
		[0] = "0",
		[1] = "1",
		[2] = "2",
	},
	COLOR = {
		[0] = "黑桃",
		[1] = "红桃",
		[2] = "梅花",
		[3] = "方片",
	},
	NUM =
	{
		[3] = "3",
		[4] = "4",
		[5] = "5",
		[6] = "6",
		[7] = "7",
		[8] = "8",
		[9] = "9",
		[10] = "10",
		[11] = "J",
		[12] = "Q",
		[13] = "K",
		[14] = "A",
		[15] = "2",
		[16] = "小王",
		[17] = "大王",
	},
}

local TIAN_LAIZI = 1
local DI_LAIZI = 2
local DEFAULT_LAIZI_COLOR = 4

--牌的正面皮肤
local DdzPokerCardResource ={
	--示例：[12710] = "_01"
}

--牌的背面皮肤
local DdzPockerBackCardResurce = {
	[12710] = {
		[DdzPokerData.tPlayerDirection.Down] = "UIAtlas2_Ddz_PokerBack_BackNormalMiddle",
		[DdzPokerData.tPlayerDirection.Left] = "UIAtlas2_Ddz_PokerBack_BackNormalLeft",
		[DdzPokerData.tPlayerDirection.Right] = "UIAtlas2_Ddz_PokerBack_BackNormalRight",
	},
	[11655] = {
		[DdzPokerData.tPlayerDirection.Down] = "UIAtlas2_Ddz_PokerBack_BackNormalMiddle",
		[DdzPokerData.tPlayerDirection.Left] = "UIAtlas2_Ddz_PokerBack_BackNormalLeft",
		[DdzPokerData.tPlayerDirection.Right] = "UIAtlas2_Ddz_PokerBack_BackNormalRight",
	},
	[12788] = {
		[DdzPokerData.tPlayerDirection.Down] = "UIAtlas2_Ddz_PokerBack_BackBGMiddle",
		[DdzPokerData.tPlayerDirection.Left] = "UIAtlas2_Ddz_PokerBack_BackBGLeft",
		[DdzPokerData.tPlayerDirection.Right] = "UIAtlas2_Ddz_PokerBack_BackBGRight",
	},
	[14142] = {
		[DdzPokerData.tPlayerDirection.Down] = "UIAtlas2_Ddz_PokerBack_BackNormalMiddle",
		[DdzPokerData.tPlayerDirection.Left] = "UIAtlas2_Ddz_PokerBack_BackNormalLeft",
		[DdzPokerData.tPlayerDirection.Right] = "UIAtlas2_Ddz_PokerBack_BackNormalRight",
	},
}

DdzPokerData.DOUBLE = {
	NORMAL = 0,
	JIABEI = 1,
	SUPER_JIABEI = 2,
	BU_JIABEI = 3,
}
DdzPokerData.TABLE_TYPE = {
	NORMAL = 1,
	NO_LAIZI = 2,
	SINGLE_LAIZI = 3,
	DOUBLE_LAIZI = 4,
}

DdzPokerData.DIZHU = {
	JIAO_DIZHU = 1,
	QIANG_DIZHU = 2,
	BU_JIAO = 5,
	BU_QIANG = 6,
}

local DOUBLE_TIMES = {
	[DdzPokerData.DOUBLE.NORMAL] = 1,
	[DdzPokerData.DOUBLE.JIABEI] = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_NORMAL],
	[DdzPokerData.DOUBLE.SUPER_JIABEI] = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_SUPER],
	[DdzPokerData.DOUBLE.BU_JIABEI] = 1,
}


local function GetDecimalPosNum(nNum, nPos)
	nNum = math.floor(nNum)
	local nRetNum = math.floor(nNum / math.pow(10, nPos - 1))
	nRetNum = nRetNum % 10
	return nRetNum
end

local function CmpDesc(tInfoA, tInfoB)
	if tInfoA[1] == tInfoB[1] then
		if tInfoA[3] == tInfoB[3] then
			return tInfoA[2] < tInfoB[2]
		end
		return tInfoA[3] > tInfoB[3]
	end
	return tInfoA[1] > tInfoB[1]
end

local function CmpAsc(tInfoA, tInfoB)
	if tInfoA[1] == tInfoB[1] then
		if tInfoA[3] == tInfoB[3] then
			return tInfoA[2] > tInfoB[2]
		end
		return tInfoA[3] < tInfoB[3]
	end
	return tInfoA[1] > tInfoB[1]
end

local function CmpMingPai(tInfoA, tInfoB)
	if tInfoA[1] == tInfoB[1] then
		if tInfoA[3] == tInfoB[3] then
			return tInfoA[2] < tInfoB[2]
		end
		return tInfoA[3] > tInfoB[3]
	end
	return tInfoA[1] < tInfoB[1]
end

local function CmpWithoutLaizi(tInfoA, tInfoB)
	if tInfoA[3] == tInfoB[3] then
		return tInfoA[2] < tInfoB[2]
	end
	return tInfoA[3] > tInfoB[3]
end
local function CmpTemp(tInfoA, tInfoB)
	if tInfoA[2] == tInfoB[2] then
		return tInfoA[1] > tInfoB[1]
	end
	return tInfoA[2] > tInfoB[2]
end

local fnCmp = CmpDesc

local function SortCards(tCards, tCardType)
	local tCount = {}
	for i = 1, #tCards do
		if not tCount[tCards[i][3]] then
			tCount[tCards[i][3]] = 0
		end
		tCount[tCards[i][3]] = tCount[tCards[i][3]] + 1
	end
	local tSort = {}
	for nNum, nCount in pairs(tCount) do
		local tTemp = {nNum, nCount}
		if (tCardType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE or
		tCardType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE) and nCount > 3 then
			tTemp = {nNum, nCount - 3}
			table.insert(tSort, tTemp)
			tTemp = {nNum, 3}
		elseif (tCardType[1] == DDZ_CONST_CARD_TYPE_BOMB4_SINGLE or
		tCardType[1] == DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE) and nCount > 4 then
			tTemp = {nNum, nCount - 4}
			table.insert(tSort, tTemp)
			tTemp = {nNum, 4}
		end
		table.insert(tSort, tTemp)
	end
	table.sort(tSort, CmpTemp)
	local nPos = 1
	for i = 1, #tSort do
		local nCount = 0
		for j = nPos, #tCards do
			if tCards[j][3] == tSort[i][1] then
				tCards[j], tCards[nPos] = tCards[nPos], tCards[j]
				nPos = nPos + 1
				nCount = nCount + 1
			end
			if nCount >= tSort[i][2] then
				break
			end
		end
	end
end

local function GetServerCardData(tCards)
	local tRet = DDZ_UICards2Server(tCards)
	local tServerCards = DDZ_CardMSG2Talbe(tRet[1], tRet[2], tRet[3], tRet[4], tRet[5])
	return tServerCards
end

local function Card2String(tCards)
	local szInfo = ""
	for i = 1, #tCards do
		szInfo = szInfo ..
		CARD.COLOR[tCards[i][2]] ..
		CARD.NUM[tCards[i][3]] .. "  "
	end
	return szInfo
end
local function ProcCards(tCards, tType)
	if tType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE or
		tType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE or
		tType[1] == DDZ_CONST_CARD_TYPE_BOMB4_SINGLE or
		tType[1] == DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE then
		SortCards(tCards, tType)
	end
end

---------------------------------------------------DataModle---------------------------------------------------
function DdzPokerData.Init()
	DDZ_INIT()
end

function DdzPokerData.DataModleInit(nSkinID)
	local tmpDataModel = {}
    tmpDataModel.nFurnitureID = nil
	tmpDataModel.nSkinID = nSkinID
	tmpDataModel.bStartGame = false
	tmpDataModel.nTableState = nil
	tmpDataModel.nTableType = nil
	tmpDataModel.nDiZhuIndex = 0
	tmpDataModel.nTableDouble = 0
	tmpDataModel.tCountDown = {}
	tmpDataModel.tGameData = {}
	local tInfo = {
		nReady = DdzPokerData.TABLE_SLOT_STATE.LIVE,
		bIsMingPai = false,
		nDoubleTimes = 1,
		nDoubleType = nil,
		bIsHosting = false,
		szName = "",
		nMoney = 0,
		nCardNum = 0,
		tCards = {
			tSourceData = {},
			tUIData = {},
			nNum = 0,
		},
		nIndex = 0,
		nState = 0,
		tPlayer = nil,
		nPlayerID = nil,
		tPassedCards = {
			tSourceData = {},
			tUIData = {},
		},
		bIsJump = false,
		bIsWiner = false,
		bIsSpring = false,
		bLessCard = false,
		bChangeHosting = false,
	}
	tmpDataModel.tGameData["Left"] = clone(tInfo)
	tmpDataModel.tGameData["Right"] = clone(tInfo)
	tmpDataModel.tGameData["Down"] = clone(tInfo)
	tmpDataModel.tTianLaiZi = {
		tSourceData = 0,
		tUIData = {},
	}
	tmpDataModel.tDiLaiZi = {
		tSourceData = 0,
		tUIData = {},
	}
	tmpDataModel.tThreeCards = {
		tSourceData = {},
		tUIData = {},
	}
	tmpDataModel.tIndex2Direction = {
		[1] = "Down",
		[2] = "Left",
		[3] = "Right",
	}
	tmpDataModel.nPrePlayerIndex = 0
	tmpDataModel.nCurPlayerIndex = 0
	tmpDataModel.tPreCardType = nil
	tmpDataModel.tSkinInfo = DdzPokerData.InitDDZSkinTable(nSkinID)
	tmpDataModel.tSettlementSkinInfo = DdzPokerData.InitSettlementSkinInfo(UIHelper.GetName(self._rootNode))
	tmpDataModel.tRule = {}
	tmpDataModel.tCardCount = {}
	tmpDataModel.tPreOperateCards = {
		tSourceData = {},
		tUIData = {},
	}
	tmpDataModel.nInitDouble = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_INITIAL_CARDS]
	tmpDataModel.nDiZhuDoubleTimes = 1
	tmpDataModel.nDiPaiDouble = 1
	tmpDataModel.nBoomDouble = 1
	tmpDataModel.nNongMingDoubleTimes = 1
	tmpDataModel.nTotalDoubleTimes = 1
	tmpDataModel.nSpringDouble = 1
	tmpDataModel.nPublicTimes = 1
	tmpDataModel.nBottomType = nil
	tmpDataModel.nTableDouble = nil
	tmpDataModel.nSpringIndex = 0
	self.DataModel = tmpDataModel
end

function DdzPokerData.InitDDZSkinTable(nSkinID)
	local tbSkinInfo = {}
	for k, v in ilines(g_tTable.DDZSkin) do
		local tbData = clone(v)
		if nSkinID == tbData.nSkinID and tbData.szMobileNode ~= "" then
			local nIndex = string.find(tbData.szMobileNode, "/")
			if nIndex ~= nil then
				local szPanelName = string.sub(tbData.szMobileNode, 1, nIndex - 1)
				tbData.szMobileNode = string.sub(tbData.szMobileNode, nIndex + 1, string.len(tbData.szMobileNode))
				if not tbSkinInfo[szPanelName] then
					tbSkinInfo[szPanelName] = {}
					tbSkinInfo[szPanelName]["SkinSfx"] = {}
					tbSkinInfo[szPanelName]["Skin"] = {}
				end
				if tbData.bSfx then
					table.insert(tbSkinInfo[szPanelName]["SkinSfx"], tbData)
				else
					table.insert(tbSkinInfo[szPanelName]["Skin"], tbData)
				end
			end
		end
	end

	return tbSkinInfo
end

function DdzPokerData.InitSettlementSkinInfo(nSkinID)
	local tbSkinInfo = {}
	for k, v in ilines(g_tTable.DDZSettlementSkin) do
		local tbData = clone(v)
		if nSkinID == tbData.nSkinID and tbData.szMobileNode ~= "" then
			local nIndex = string.find(tbData.szMobileNode, "/")
			if nIndex ~= nil then
				local szPanelName = string.sub(tbData.szMobileNode, 1, nIndex - 1)
				tbData.szMobileNode = string.sub(tbData.szMobileNode, nIndex + 1, string.len(tbData.szMobileNode))
				if not tbSkinInfo[szPanelName] then
					tbSkinInfo[szPanelName] = {}
					tbSkinInfo[szPanelName]["SkinSfx"] = {}
					tbSkinInfo[szPanelName]["Skin"] = {}
				end
				if tbData.bSfx then
					table.insert(tbSkinInfo[szPanelName]["SkinSfx"], tbData)
				else
					table.insert(tbSkinInfo[szPanelName]["Skin"], tbData)
				end
			end
		end
	end
	return tbSkinInfo
end

function DdzPokerData.GetSkinInfoListByWidgetName(szRootName, bIsSfx)
	if not self.DataModel.tSkinInfo[szRootName] then
		return nil
	end
	if bIsSfx then
		return self.DataModel.tSkinInfo[szRootName]["SkinSfx"]
	end
	return self.DataModel.tSkinInfo[szRootName]["Skin"]
end

function DdzPokerData.GetSettlementSkinInfo(szRootName, bIsSfx)
	if not self.DataModel.tSettlementSkinInfo[szRootName] then
		return nil
	end
	if bIsSfx then
		return self.DataModel.tSettlementSkinInfo[szRootName]["SkinSfx"]
	end
	return self.DataModel.tSettlementSkinInfo[szRootName]["Skin"]
end


function DdzPokerData.InitDirection(tPlayerInfo)
	for i = 1, DdzPokerData.MAX_PLAYER_NUM do
		if tPlayerInfo[i] and tPlayerInfo[i][1] == UI_GetClientPlayerID() then
			local nDown = i - 1
			local nLeft = (nDown + 2) %  DdzPokerData.MAX_PLAYER_NUM
			local nRight = (nDown + 4) %  DdzPokerData.MAX_PLAYER_NUM
			self.DataModel.tIndex2Direction[nDown + 1] = "Down"
			self.DataModel.tGameData["Down"].nIndex = nDown + 1
			self.DataModel.tIndex2Direction[nLeft + 1] = "Left"
			self.DataModel.tGameData["Left"].nIndex = nLeft + 1
			self.DataModel.tIndex2Direction[nRight + 1] = "Right"
			self.DataModel.tGameData["Right"].nIndex = nRight + 1
			return
		end
	end
end

function DdzPokerData.InitGameData(tPlayerInfo)
	for i = 1,  DdzPokerData.MAX_PLAYER_NUM do
		if tPlayerInfo[i] then
			local tPlayerData = self.GetPlayerDataByIndex(i)
			tPlayerData.nMoney = tPlayerInfo[i][3]
			if tPlayerData.nMoney == 0 then
				tPlayerData.nMoney = DDZ_GetPlayerCashOrigin(i)
			end
			tPlayerData.nPlayerID = tPlayerInfo[i][1]
			tPlayerData.bIsMingPai =
				tPlayerInfo[i][2] == DdzPokerData.TABLE_SLOT_STATE.MINGPAI_READY
		end
	end
end

function DdzPokerData.InitDownPlayerCardInfo()
	local tPlayerData = self.DataModel.tGameData["Down"]
	local nPlayerID = tPlayerData.nPlayerID
	local szAvatarName = ""
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	local tPlayer = {nRoleType = pPlayer.nRoleType, dwMiniAvatarID = pPlayer.dwMiniAvatarID, dwForceID = pPlayer.dwForceID}
	szAvatarName = pPlayer.szName
	tPlayerData.tPlayer = tPlayer
	tPlayerData.szName = szAvatarName
end

function DdzPokerData.InitPlayerReadyState(tPlayerInfo)
	for i = 1, DdzPokerData.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		if tPlayerInfo[i] then
			tPlayerData.nReady = tPlayerInfo[i][2]
		else
			tPlayerData.nReady = DdzPokerData.TABLE_SLOT_STATE.LIVE
		end
	end
end

function DdzPokerData.InitRuleData(nRuleNum)
	self.DataModel.tRule.nRuleNum = nRuleNum
	self.DataModel.tRule.nDiFen = GetDecimalPosNum(nRuleNum, 3)
	self.DataModel.tRule.nWanFa = GetDecimalPosNum(nRuleNum, 2)
	self.DataModel.tRule.nXiPai = GetDecimalPosNum(nRuleNum, 1)
end

function DdzPokerData.InitCardCount()
	for i = self.CARD_START, self.CARD_END do
		self.DataModel.tCardCount[i] = 0
	end
end

function DdzPokerData.GetSoundPath(szSound)
	return UIHelper.UTF8ToGBK(self.tDdzsound[szSound])
end

function DdzPokerData.LeavePlayer(nPlayerIndex)
	DdzPokerData.ClearPlayerData(nPlayerIndex)
end

function DdzPokerData.ClearPlayerData(nPlayerIndex)
	local tInfo = {
		nReady = self.TABLE_SLOT_STATE.LIVE,
		bIsMingPai = false,
		nDoubleTimes = 1,
		nDoubleType = nil,
		bIsHosting = false,
		szName = "",
		nMoney = 0,
		nCardNum = 0,
		tCards = {
			tSourceData = {},
			tUIData = {},
			nNum = 0,
		},
		nIndex = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].nIndex,
		nState = 0,
		tPlayer = nil,
		nPlayerID = nil,
		tPassedCards = {
			tSourceData = {},
			tUIData = {},
		},
		bIsJump = false,
		bIsWiner = false,
		bIsSpring = false,
		bLessCard = false,
		bChangeHosting = false,
	}
	self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]] = nil
	self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]] = tInfo
end

function DdzPokerData.InitSinglePlayerReadyState(tPlayerInfo)
	for k, v in pairs(tPlayerInfo) do
		local tPlayerData = self.GetPlayerDataByIndex(k)
		tPlayerData.nReady = v[2]
	end
end

function DdzPokerData.ClearWinnerIndex()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.bIsWiner = false
	end
end

function DdzPokerData.ApplyPlayerCardInfo(tData)
	local tPlayerID = {}
	for i = 1, self.MAX_PLAYER_NUM do
		if tData[i] and tData[i][1] ~= nil then
			local player = GetPlayer(tData[i][1])
			if player then
				local globalID = player.GetGlobalID()
				table.insert(tPlayerID, globalID)
			end
		end
	end
	if tPlayerID and #tPlayerID > 0 then
		GetSocialManagerClient().ApplyRoleEntryInfo(tPlayerID)
		Event.Dispatch("FELLOWSHIP_ROLE_ENTRY_UPDATE")
	end
end

function DdzPokerData.SyncGameEndMoney()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nMoney = DDZ_GetPlayerCash(i)
	end
end

function DdzPokerData.InitLeftOrRightPlayerCardInfo()
	DdzPokerData.InitPlayerCardInfo(self.tPlayerDirection.Left)
	DdzPokerData.InitPlayerCardInfo(self.tPlayerDirection.Right)
end

function DdzPokerData.InitPlayerCardInfo(szDirection)
	local tPlayerData = self.DataModel.tGameData[szDirection]
	if tPlayerData.nPlayerID then
		local nPlayerID = tPlayerData.nPlayerID
		local tPlayer
		local szAvatarName = ""
		local player = GetPlayer(nPlayerID)
		if player then
			local globalID = player.GetGlobalID()
			local aCard = FellowshipData.GetRoleEntryInfo(globalID)
			if aCard then
				tPlayer = {nRoleType = aCard.nRoleType, dwMiniAvatarID = aCard.dwMiniAvatarID, dwForceID = aCard.nForceID}
				szAvatarName = aCard.szName
			end
		end

		tPlayerData.tPlayer = tPlayer
		tPlayerData.szName = szAvatarName
	end
end

function DdzPokerData.GetPreOpPlayerIndex(nIndex)
	local nRet = nIndex - 1
	if nRet == 0 then
		nRet = 3
	end
	return nRet
end

function DdzPokerData.GetPrePlayerIndex(nIndex)
	local nRet = nIndex - 1
	if nRet == 0 then
		nRet = 3
	end
	return nRet
end

function DdzPokerData.GetNextPlayerIndex(nIndex)
	local nRet = nIndex + 1
	if nRet == 4 then
		nRet = 1
	end
	return nRet
end

function DdzPokerData.IsPreMyOp()
	return DdzPokerData.GetPreOpPlayerIndex(DdzPokerData.DataModel.nCurPlayerIndex) == DdzPokerData.DataModel.tGameData["Down"].nIndex and DdzPokerData.DataModel.nPrePlayerIndex ~= 0
end

function DdzPokerData.GetPlayerCardNum(nPlayerIndex)
	local tPlayerData = self.GetPlayerDataByIndex(nPlayerIndex)
	return tPlayerData.tCards.nNum
end

function DdzPokerData.UpdateCardCount()
	self.DataModel.tCardCount = DDZ_GetPublicCardsLast2UI()
end

function DdzPokerData.GetDicardAtlasPath(nCardType)
	--self.szPokerAtlasPath .. self.tbPokerColorAtlasSymbol[xx]..nNum
end

function DdzPokerData.SetStartGame(bStart)
	self.DataModel.bStartGame = bStart
end


function DdzPokerData.UpdatePlayerMoney()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nMoney = DDZ_GetPlayerCashOrigin(i)
	end
end

function DdzPokerData.GameOver()
	self.bLockHandCard = true
	for k, v in pairs(self.DataModel.tGameData) do
		local tCards = {}
		if k == self.tPlayerDirection.Down then
			tCards = DDZ_GetPlayerHand(v.nIndex)
		else
			tCards = DDZ_GetPublicPlayerHandCards(v.nIndex)
			v.bIsMingPai = true
		end
		v.tCards.tSourceData = tCards
		tCards = DDZ_ServerCards2UI(tCards)
		table.sort(tCards, CmpDesc)
		v.tCards.tUIData = tCards
		v.bIsHosting = false
		v.bIsWiner = not (DDZ_GetPlayerWinnerBool(v.nIndex) == 0)
	end
end

function DdzPokerData.UnInit()
	self.DataModel.nTableState = nil
	self.DataModel.szDiZhu = nil
	self.DataModel.nType = nil
	self.DataModel.nTableDouble = nil
	self.DataModel.tGameData = nil
	self.DataModel.tCardCount = nil
	self.DataModel.nTianLaiZi = nil
	self.DataModel.nDiLaiZi = nil
	self.DataModel.tThreeCards = nil
	self.DataModel.tIndex2Direction = nil
end

function DdzPokerData.GetCardIconPath(tCards , isLaizi)
	local szSkin = self.GetCardSkin()
	local nNum = tCards[3]
    local nCoolor = (tCards[1] == TIAN_LAIZI or tCards[1] == DI_LAIZI) and DEFAULT_LAIZI_COLOR or tCards[2]
	if isLaizi then
		nCoolor = DEFAULT_LAIZI_COLOR
	end
    local szIconPath = ""
    local szNumSymbol = self.tbPokerNumAtlasSymbol[nNum]
    if self.IsJoker(nNum) then
        szIconPath = self.HandCardColorMap[szNumSymbol]
    else
        szIconPath = self.HandCardColorMap[nCoolor]..szNumSymbol
    end
	return string.format(szIconPath, szSkin)
end

function DdzPokerData.GetCardSkin()
	local szSkin = DdzPokerCardResource[self.DataModel.nSkinID]
	if not szSkin then szSkin = "" end
	return szSkin
end

function DdzPokerData.GetPlayerBackbyDirection(szDirection)
	local tbInfo = DdzPockerBackCardResurce[self.DataModel.nSkinID]
	if not tbInfo then
		tbInfo = DdzPockerBackCardResurce[12710]
	end
	return tbInfo[szDirection]
end


function DdzPokerData.ChangeCmp(bIsAsc)
	self.SetCmp(bIsAsc)
	local tCards = self.DataModel.tGameData["Down"].tCards.tUIData
	table.sort(tCards, fnCmp)
	if self.IsMyRound() then
		local tPlayerData = self.DataModel.tGameData["Down"]
		if tPlayerData.tUITipCards then
			for i = 1, #tPlayerData.tUITipCards do
				table.sort(tPlayerData.tUITipCards[i], fnCmp)
			end
		end
		tPlayerData.nTipCount = 1
	end
end

function DdzPokerData.SetCmp(bIsAsc)
	fnCmp = bIsAsc and CmpAsc or CmpDesc
end
----------------------------------------------------------------------------------------------------------------

function DdzPokerData.IsJoker(nNum)
	local szSymbol = DdzPokerData.tbPokerNumAtlasSymbol[nNum]
	if szSymbol == DdzPokerData.LittleJokerSymbol or szSymbol == DdzPokerData.BigJokerSymbol then
		return true
	end
	return false
end

function DdzPokerData.IsAsc()
	return fnCmp == CmpAsc
end

function DdzPokerData.DownIsHost()
	return self.DataModel.tGameData[self.tPlayerDirection.Down].nIndex == 1
end

function DdzPokerData.DownIsReady()
	local nReady = self.DataModel.tGameData[self.tPlayerDirection.Down].nReady
	return nReady == self.TABLE_SLOT_STATE.READY or nReady == self.TABLE_SLOT_STATE.MINGPAI_READY
end

function DdzPokerData.InGame()
	if self.DataModel.nTableState and
		(self.DataModel.nTableState < DDZ_CONST_TIMES_MINGPAI_STATE_INIT or
		self.DataModel.nTableState >= DDZ_CONST_TIMES_MINGPAI_STATE_SHUFFLE) then
		return true
	end
	return false
end

function DdzPokerData.DownIsHosting()
	return self.DataModel.tGameData[self.tPlayerDirection.Down].bIsHosting
end

function DdzPokerData.DownIsDiZhu()
	return self.DataModel.tGameData[self.tPlayerDirection.Down].nIndex == self.DataModel.nDiZhuIndex
end

function DdzPokerData.SendReadyStartGame(nPlayerState)
	GetHomelandMgr().ChangeLOSlot(self.DataModel.nFurnitureID, nPlayerState,
			UI_GetClientPlayerID(), self.DataModel.tGameData["Down"].nIndex)
end

function DdzPokerData.IsLaiZiTable()
	return self.DataModel.nTableType == self.TABLE_TYPE.SINGLE_LAIZI or
	self.DataModel.nTableType == self.TABLE_TYPE.DOUBLE_LAIZI
end

function DdzPokerData.IsSingleLaiziTable()
	return self.DataModel.nTableType == self.TABLE_TYPE.SINGLE_LAIZI
end

function DdzPokerData.IsFreePlay()
	return self.DataModel.nPrePlayerIndex == self.DataModel.tGameData["Down"].nIndex or
	self.DataModel.nPrePlayerIndex == 0
end

function DdzPokerData.IsMyRound()
	return self.DataModel.nCurPlayerIndex == self.DataModel.tGameData["Down"].nIndex
end

function DdzPokerData.IsExist(tInfo, tCard)
	for i = 1, #tInfo do
		if tCard.nCmpNum == tInfo[i].nCmpNum then
			return true
		end
	end
	return false
end
function DdzPokerData.GetTipCards()
	local tPlayerData = self.DataModel.tGameData["Down"]
	local tType = DDZ_GetCurOperateCardType()
	local nNum = #self.DataModel.tPreOperateCards.tUIData
	local tCards = {}
	local tSourceData = tPlayerData.tCards.tSourceData
	for k, v in pairs(tSourceData) do
		if v ~= 0 then
			table.insert(tCards, v)
		end
	end
	tPlayerData.tTipType, tPlayerData.tUITipCards = DDZ_OperateLaiziCard(tType, nNum, tCards, self.DataModel.tTianLaiZi.tSourceData, self.DataModel.tDiLaiZi.tSourceData, 1)
	tPlayerData.nTipCount = 1
	if tPlayerData.tUITipCards then
		for i = 1, #tPlayerData.tUITipCards do
			table.sort(tPlayerData.tUITipCards[i], fnCmp)
		end
	end
end
function DdzPokerData.GetCardType(tCards)
	local tType = {DDZ_CONST_CARD_TYPE_ERROR, 0, 0}
	local tCardType = DDZ_OperateLaiziType(self.DataModel.nTableType, #tCards)
	if tCardType and #tCardType > 0 then
		local tServerCards = GetServerCardData(tCards)
		local tTypeTemp = DDZ_GetCardType(tServerCards)
		for i = 1, #tCardType do
			if tCardType[i][1] == tTypeTemp[1] then
				tType = tTypeTemp
				break
			end
		end
	end
	return tType
end

function DdzPokerData.GetMergeTable(tCards, nTableType, bFreePlay)
	local nCount = 0
	local nNum = #tCards
	local tServerCards = GetServerCardData(tCards)
	local tCardType = nil
	if bFreePlay then
		tCardType = DDZ_OperateLaiziType(nTableType, nNum)
	else
		tCardType = {DDZ_GetCurOperateCardType()}
	end
	local tMerge = {}
	for i = 1, #tCardType do
		local tResType, tCardSet =
		DDZ_OperateLaiziCard(tCardType[i], nNum, tServerCards, self.DataModel.tTianLaiZi.tSourceData, self.DataModel.tDiLaiZi.tSourceData, 0)
		if tResType then
			for k, v in ipairs(tResType) do
				if not tMerge[v[1]] then
					tMerge[v[1]] = {}
				end
				tCardSet[k].nCmpNum = v[2]
				if not self.IsExist(tMerge[v[1]], tCardSet[k]) then
					table.sort(tCardSet[k], CmpWithoutLaizi)
					ProcCards(tCardSet[k], v)
					table.insert(tMerge[v[1]], tCardSet[k])
					nCount = nCount + 1
				end
			end
		end
	end
	local tType = self.GetCardType(tCards)
	if bFreePlay and tType[1] > DDZ_CONST_CARD_TYPE_DUMP and
		tType[1] < DDZ_CONST_CARD_TYPE_ERROR then
		if not tMerge[tType[1]] then
			tMerge[tType[1]] = {}
		end
		tCards.nCmpNum = tType[2]
		if not self.IsExist(tMerge[tType[1]], tCards) then
			table.sort(tCards, CmpWithoutLaizi)
			ProcCards(tCards, tType)
			table.insert(tMerge[tType[1]], tCards)
			nCount = nCount + 1
		end
	end
	return tMerge, nCount
end

function DdzPokerData.GetPassedCards(nPlayerIndex)
	local szDirection = self.DataModel.tIndex2Direction[nPlayerIndex]
	Card2String(self.DataModel.tPreOperateCards.tUIData)
	self.DataModel.tGameData[szDirection].tPassedCards.tSourceData = self.DataModel.tPreOperateCards.tSourceData
	self.DataModel.tGameData[szDirection].tPassedCards.tUIData = self.DataModel.tPreOperateCards.tUIData
	local tCards = self.DataModel.tPreOperateCards.tUIData
	table.sort(tCards, CmpWithoutLaizi)
	ProcCards(tCards, self.DataModel.tPreCardType)
end

function DdzPokerData.UpdatePlayerJump()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.bIsJump = not (DDZ_GetPlayerOperateJump(i) == 0)
	end
end

function DdzPokerData.SyncMingPaiHandCard()
	local tDirection = {self.tPlayerDirection.Left, self.tPlayerDirection.Right}
	for k, v in ipairs(tDirection) do
		local tPlayerData = self.DataModel.tGameData[v]
		local nPreNum = tPlayerData.tCards.nNum
		if tPlayerData.bIsMingPai then
			tPlayerData.tCards.tSourceData = DDZ_GetPublicPlayerHandCards(tPlayerData.nIndex)
			tPlayerData.tCards.tUIData = DDZ_ServerCards2UI(tPlayerData.tCards.tSourceData)
			tPlayerData.tCards.nNum = #tPlayerData.tCards.tUIData
			table.sort(tPlayerData.tCards.tUIData, CmpMingPai)
		else
			tPlayerData.nCardNum = DDZ_GetPublicCardsNum(tPlayerData.nIndex)
			tPlayerData.tCards.nNum = tPlayerData.nCardNum
		end
		local nNowNum = tPlayerData.tCards.nNum
		if nNowNum <= 2 and nPreNum ~= 0 and nPreNum > 2 and nNowNum ~= 0 then
			tPlayerData.bLessCard = true
		else
			tPlayerData.bLessCard = false
		end
	end
end

function DdzPokerData.DelCountDown()
	self.DataModel.tCountDown = {}
end

function DdzPokerData.UpdatePlayerDouble()
	for i = 1, self.MAX_PLAYER_NUM do
		local nDoubleType = DDZ_GetPlayerDoubleType(i)
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nDoubleType = nDoubleType
	end
end
function DdzPokerData.GetPlayerTimes(nIndex)
	local nRet = DOUBLE_TIMES[DDZ_GetPlayerDoubleType(nIndex)]
	if nRet then
		return nRet
	else
		return 1
	end
end

function DdzPokerData.InitDoubleTimes()
	local nTimes = 1
	local nTemp = DDZ_GetPublicTimesTableState(DDZ_CONST_TIMES_BOTTOM_CARDS)
	for j = 1, nTemp do
		nTimes = nTimes * DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_BOTTOM_CARDS]
	end
	self.DataModel.nInitDouble = nTimes
	local START = DDZ_CONST_TIMES_MINGPAI_STATE_INIT
	local END = DDZ_CONST_TIMES_MINGPAI_STATE_SHUFFLE
	nTimes = 1
	for i = START, END do
		nTemp = DDZ_GetPublicTimesTableState(i)
		for j = 1, nTemp do
			nTimes = nTimes * DDZ_CONST_CAERDS_TIMES[i]
		end
	end
	self.DataModel.nMingPaiDouble = nTimes
	START = DDZ_CONST_TIMES_CHAIRMAN_CALL
	END = DDZ_CONST_TIMES_CHAIRMAN_ROB
	nTimes = 1
	for i = START, END do
		nTemp = DDZ_GetPublicTimesTableState(i)
		for j = 1, nTemp do
			nTimes = nTimes * DDZ_CONST_CAERDS_TIMES[i]
		end
	end
	self.DataModel.nDiZhuDouble = nTimes

	START = DDZ_CONST_TIMES_BOTTOM_CARDS_LINE
	END = DDZ_CONST_TIMES_BOTTOM_CARDS_FLUSH
	local tBottomType = {}
	for i = START, END do
		if DDZ_GetPublicTimesTableState(i) == 1 then
			table.insert(tBottomType, i)
		end
	end

	nTimes = 1
	local bSJoker = false
	local bBJoker = false
	for i = 1, #tBottomType do
		nTimes = nTimes * DDZ_CONST_CAERDS_TIMES[tBottomType[i]]
		if tBottomType[i] == DDZ_CONST_TIMES_BOTTOM_CARDS_BJOKER then
			bBJoker = true
		end
		if tBottomType[i] == DDZ_CONST_TIMES_BOTTOM_CARDS_SJOKER then
			bSJoker = true
		end
	end
	if #tBottomType >= 2 and bBJoker then
		self.DataModel.nBottomType = GD_BOTTOM_TYPE.CARDS_DOUBLE_BJOKER
	elseif #tBottomType >= 2 and bSJoker then
		self.DataModel.nBottomType = GD_BOTTOM_TYPE.CARDS_DOUBLE_SJOKER
	else
		self.DataModel.nBottomType = tBottomType[1]
	end

	self.DataModel.nDiPaiDouble = nTimes

	START = DDZ_CONST_TIMES_DOUBLE_BOMB_BIG
	END = DDZ_CONST_TIMES_DOUBLE_BOMB_ROCKET
	nTimes = 1
	for i = START, END do
		nTemp = DDZ_GetPublicTimesTableState(i)
		for j = 1, nTemp do
			nTimes = nTimes * DDZ_CONST_CAERDS_TIMES[i]
		end
	end
	self.DataModel.nBoomDouble = nTimes


	if self.DataModel.tGameData["Down"].bIsSpring then
		self.DataModel.nSpringDouble = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_ENDINNG_SPRING]
	end
end

function DdzPokerData.UpdatePlayerMingPai()
	for i = 1, self.MAX_PLAYER_NUM do
		local bNowIsMingPai = DDZ_GetPublicMingPaiState(i) > 0
		local tPlayerData = self.GetPlayerDataByIndex(i)
		local bPreIsMingPai = tPlayerData.bIsMingPai
		if bNowIsMingPai and (not bPreIsMingPai) then
			tPlayerData.bShowMingPaiSfx = true
		else
			tPlayerData.bShowMingPaiSfx = false
		end
		tPlayerData.bIsMingPai = bNowIsMingPai
	end
end

function DdzPokerData.SyncTableType()
	self.DataModel.nTableType = DDZ_GetTableSettingType()
end

function DdzPokerData.CanelPlayerReadyState()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nReady = self.TABLE_SLOT_STATE.UNREADY
	end
end

function DdzPokerData.ClearPlayerGameData(nPlayerIndex)
	local tInfo = {
		nReady = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].nReady,
		bIsMingPai = false,
		nDoubleTimes = 1,
		nDoubleType = nil,
		bIsHosting = false,
		szName = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].szName,
		nMoney = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].nMoney,
		nCardNum = 0,
		tCards = {
			tSourceData = {},
			tUIData = {},
			nNum = 0,
		},
		nIndex = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].nIndex,
		nState = 0,
		tPlayer = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].tPlayer,
		nPlayerID = self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]].nPlayerID,
		tPassedCards = {
			tSourceData = {},
			tUIData = {},
		},
		bIsJump = false,
		bIsWiner = false,
		bIsSpring = false,
		bLessCard = false,
		bChangeHosting = false,
	}
	self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]] = nil
	self.DataModel.tGameData[self.DataModel.tIndex2Direction[nPlayerIndex]] = tInfo
end

function DdzPokerData.ClearTableData()
	self.DataModel.nTableState = nil
	self.DataModel.nTableType = nil
	self.DataModel.nDiZhuIndex = 0
	self.DataModel.nTableDouble = 0
	self.DataModel.tCountDown = {}
	self.DataModel.tTianLaiZi = {
		tSourceData = 0,
		tUIData = {},
	}
	self.DataModel.tDiLaiZi = {
		tSourceData = 0,
		tUIData = {},
	}
	self.DataModel.tThreeCards = {
		tSourceData = {},
		tUIData = {},
	}
	self.DataModel.nPrePlayerIndex = 0
	self.DataModel.nCurPlayerIndex = 0
	self.DataModel.tPreCardType = nil
	self.DataModel.tCardCount = {}
	self.DataModel.tPreOperateCards = {
		tSourceData = {},
		tUIData = {},
	}
	self.DataModel.nInitDouble = DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_INITIAL_CARDS]
	self.DataModel.nDiZhuDoubleTimes = 1
	self.DataModel.nDiPaiDouble = 1
	self.DataModel.nBoomDouble = 1
	self.DataModel.nNongMingDoubleTimes = 1
	self.DataModel.nTotalDoubleTimes = 1
	self.DataModel.nSpringDouble = 1
	self.DataModel.nPublicTimes = 1
	self.DataModel.nBottomType = nil
	self.DataModel.nTableDouble = nil
	self.DataModel.nSpringIndex = 0
end

function DdzPokerData.GetSettlmentData()
	local tData = {}
	for i = 1, self.MAX_PLAYER_NUM do
		local szDirection = self.DataModel.tIndex2Direction[i]
		local tPlayerData = self.DataModel.tGameData[szDirection]
		local nTempDoubleTimes = DDZ_GetPublicCardsTimes() * self.GetPlayerTimes(self.DataModel.nDiZhuIndex)
		if tPlayerData.nIndex == self.DataModel.nDiZhuIndex then
			nTempDoubleTimes = nTempDoubleTimes *
				(self.GetPlayerTimes(self.GetPrePlayerIndex(self.DataModel.nDiZhuIndex)) +
				self.GetPlayerTimes(self.GetNextPlayerIndex(self.DataModel.nDiZhuIndex)))
		else
			nTempDoubleTimes = nTempDoubleTimes * self.GetPlayerTimes(tPlayerData.nIndex)
		end
		local nMingPaiState = DDZ_GetPublicMingPaiState(tPlayerData.nIndex)
		tData[szDirection] = {
			szName = tPlayerData.szName,
			nDisMoney = DDZ_GetPlayerCash(tPlayerData.nIndex) -
				DDZ_GetPlayerCashOrigin(tPlayerData.nIndex),
			nIndex = tPlayerData.nIndex,
			tPlayer = clone(tPlayerData.tPlayer),
			bIsMingPai = tPlayerData.bIsMingPai,
			bIsMingPaiReady = (nMingPaiState == DDZ_CONST_TABLE_STATE_INIT),
			bSuperDouble = (tPlayerData.nDoubleType == DdzPokerData.DOUBLE.SUPER_JIABEI),
			bIsSpring = tPlayerData.bIsSpring,
			nDoubleTimes = nTempDoubleTimes,
			bIsWiner = tPlayerData.bIsWiner,
			bIsLimit = (DDZ_GetPublicCardsTimes() == DDZ_CONST_MAX_TIMES),
		}
	end
	tData.nDiZhuIndex = self.DataModel.nDiZhuIndex
	tData.bShowRuleSetting = self.DownIsHost()
	tData.nSkinID = self.DataModel.nSkinID
	return tData
end


function DdzPokerData.GetPlayerDataByIndex(nIndex)
	return self.DataModel.tGameData[self.DataModel.tIndex2Direction[nIndex]]
end

----------------------------------------------------------------------------------------------------------------------
-- Message Function
----------------------------------------------------------------------------------------------------------------------
function DdzPokerData.SyncTianLaiZi()
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nReady = self.TABLE_SLOT_STATE.UNREADY
	end
	local tLaiZi = DDZ_GetPublicLaiZi()
	if tLaiZi then
		self.DataModel.tTianLaiZi.tSourceData = tLaiZi[1]
		self.DataModel.tTianLaiZi.tUIData = DDZ_ServerCards2UI({self.DataModel.tTianLaiZi.tSourceData})[1]
	end
end

function DdzPokerData.SyncDiLaiZi()
	local tLaiZi = DDZ_GetPublicLaiZi()
	if tLaiZi then
		self.DataModel.tDiLaiZi.tSourceData = tLaiZi[2]
		self.DataModel.tDiLaiZi.tUIData = DDZ_ServerCards2UI({self.DataModel.tDiLaiZi.tSourceData})[1]
	end
end

function DdzPokerData.SyncHandCard()
	for k, v in pairs(self.DataModel.tGameData) do
		if k == self.tPlayerDirection.Down then
			v.tCards.tSourceData = DDZ_GetPlayerHand(v.nIndex)
			v.tCards.tUIData = DDZ_ServerCards2UI(v.tCards.tSourceData)
			v.tCards.nNum = #v.tCards.tUIData
			table.sort(v.tCards.tUIData, fnCmp)
		elseif v.bIsMingPai then
			v.tCards.tSourceData = DDZ_GetPublicPlayerHandCards(v.nIndex)
			v.tCards.tUIData = DDZ_ServerCards2UI(v.tCards.tSourceData)
			v.tCards.nNum = #v.tCards.tUIData
			table.sort(v.tCards.tUIData, CmpMingPai)
		else
			v.nCardNum = DDZ_GetPublicCardsNum(v.nIndex)
			v.tCards.nNum = v.nCardNum
		end
	end
end

function DdzPokerData.SyncMoney(nPlayerIndex)
    for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nMoney = DDZ_GetPlayerCashOrigin(nPlayerIndex)
	end
end

function DdzPokerData.SyncPlayCard()
    local tCards = DDZ_GetCurOperateCard()
	self.DataModel.nPrePlayerIndex = DDZ_GetCardOwner()
	self.DataModel.nCurPlayerIndex = DDZ_GetCurOperatePlayer()
	self.DataModel.tPreCardType = DDZ_GetCurOperateCardType()
	self.DataModel.tPreOperateCards.tSourceData = tCards
	self.DataModel.tPreOperateCards.tUIData = DDZ_ServerCards2UI(tCards)
	local nPlayerIndex = self.DataModel.nCurPlayerIndex
	local tPlayerData = self.DataModel.tGameData["Down"]
	if not self.IsFreePlay() and self.IsMyRound() then
		self.GetTipCards()
		if not self.DownIsHosting() then
			self.bLockHandCard = false
		end
	end
	nPlayerIndex = DDZ_GetCardOwner()
	if nPlayerIndex > 0 then
		self.GetPassedCards(nPlayerIndex)
	end
	DdzPokerData.UpdatePlayerJump()
	if self.DataModel.nCurPlayerIndex ~= 0 and self.DataModel.nTableState < DDZ_CONST_TABLE_STATE_SETTLEMENT then
		local tPlayerData = self.GetPlayerDataByIndex(self.DataModel.nCurPlayerIndex)
		tPlayerData.tPassedCards.tSourceData = {}
		tPlayerData.tPassedCards.tUIData = {}
	end
end

function DdzPokerData.SyncPrePlayer()
    self.SyncPlayCard()
	self.DataModel.nPrePlayerIndex = DDZ_GetCardOwner()
	self.DataModel.nCurPlayerIndex = DDZ_GetCurOperatePlayer()
end

function DdzPokerData.SyncCountDown()
    local tCountDown = DDZ_GetCountDownTime()
	if tCountDown then
		tCountDown[1] = tCountDown[1] - 1 --��һ�뿼���ӳ�
		self.DataModel.tCountDown = tCountDown
	end
end

function DdzPokerData.SyncDiZhu()
    local tState = DDZ_GetPubicChairManType()
	local szLog = ""
	for i = 1, self.MAX_PLAYER_NUM do
		self.DataModel.tGameData[self.DataModel.tIndex2Direction[i]].nState = tState[i]
	end
	self.DataModel.nDiZhuIndex = DDZ_GetChairMan()
end

function DdzPokerData.SyncThreeCard()
    local tThreeCards = DDZ_GetPublicBottomCards()
	self.DataModel.tThreeCards.tSourceData = tThreeCards
	self.DataModel.tThreeCards.tUIData = DDZ_ServerCards2UI(tThreeCards)
	table.sort(self.DataModel.tThreeCards.tUIData, CmpDesc)
end

function DdzPokerData.SyncDoubleTimes()
	self.DataModel.nDiZhuDoubleTimes = 1
	self.DataModel.nNongMingDoubleTimes = 1
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.nDoubleType = DDZ_GetPlayerDoubleType(i)
	end
	self.DataModel.nDiZhuDoubleTimes = self.GetPlayerTimes(self.DataModel.nDiZhuIndex)
	local tPlayerData = self.DataModel.tGameData["Down"]
	if tPlayerData.nIndex == self.DataModel.nDiZhuIndex then
		self.DataModel.nNongMingDoubleTimes = self.GetPlayerTimes(DdzPokerData.GetPrePlayerIndex(self.DataModel.nDiZhuIndex)) +
		self.GetPlayerTimes(DdzPokerData.GetNextPlayerIndex(self.DataModel.nDiZhuIndex))
	else
		self.DataModel.nNongMingDoubleTimes = self.GetPlayerTimes(tPlayerData.nIndex)
	end
	self.DataModel.nPublicTimes = DDZ_GetPublicCardsTimes()
	self.DataModel.nTableDouble = DDZ_GetPublicCardsTimes()
	self.InitDoubleTimes()
end

function DdzPokerData.SyncTableState()
    local nTableState = DDZ_GetTableMgrState()
	self.DataModel.nTableState = nTableState
end

function DdzPokerData.SyncHosting()
    local tPlayerData = self.DataModel.tGameData[self.tPlayerDirection.Down]
	local bPre = tPlayerData.bIsHosting
	for i = 1, self.MAX_PLAYER_NUM do
		local tPlayerData = self.GetPlayerDataByIndex(i)
		tPlayerData.bIsHosting = not (DDZ_GetPlayerIsAgent(i) == 0)
	end
	local bNow = tPlayerData.bIsHosting
	self.bLockHandCard = tPlayerData.bIsHosting
	tPlayerData.bChangeHosting = (bPre ~= bNow)
end

function DdzPokerData.SyncMingPaiHandCard()
    local tDirection = {self.tPlayerDirection.Left, self.tPlayerDirection.Right}
	for k, v in ipairs(tDirection) do
		local tPlayerData = self.DataModel.tGameData[v]
		local nPreNum = tPlayerData.tCards.nNum
		if tPlayerData.bIsMingPai then
			tPlayerData.tCards.tSourceData = DDZ_GetPublicPlayerHandCards(tPlayerData.nIndex)
			tPlayerData.tCards.tUIData = DDZ_ServerCards2UI(tPlayerData.tCards.tSourceData)
			tPlayerData.tCards.nNum = #tPlayerData.tCards.tUIData
			table.sort(tPlayerData.tCards.tUIData, CmpMingPai)
		else
			tPlayerData.nCardNum = DDZ_GetPublicCardsNum(tPlayerData.nIndex)
			tPlayerData.tCards.nNum = tPlayerData.nCardNum
		end
		local nNowNum = tPlayerData.tCards.nNum
		if nNowNum <= 2 and nPreNum ~= 0 and nPreNum > 2 and nNowNum ~= 0 then
			tPlayerData.bLessCard = true
		else
			tPlayerData.bLessCard = false
		end
	end
end



function DdzPokerData.SyncSpring()
    self.DataModel.nSpringIndex = DDZ_GetSpringPlayerIndex()
	if self.DataModel.nSpringIndex == self.DataModel.nDiZhuIndex then
		local tPlayerData = self.GetPlayerDataByIndex(self.DataModel.nDiZhuIndex)
		tPlayerData.bIsSpring = true
	else
		local tPlayerData = self.GetPlayerDataByIndex(DdzPokerData.GetNextPlayerIndex(self.DataModel.nDiZhuIndex))
		tPlayerData.bIsSpring = true
		local tPlayerData = self.GetPlayerDataByIndex(DdzPokerData.GetPrePlayerIndex(self.DataModel.nDiZhuIndex))
		tPlayerData.bIsSpring = true
	end
end