---------------------------------------------------------------------->
-- 脚本名称:	scripts/MiniGame/Mahjong/xueliuchenghe/IdentityCustomValueName.lua
-- 更新时间:	2020/4/14 16:09:17
-- 更新用户:	KING-20200219SB
-- 脚本说明:	日志标签、自定义数据空间、读写数据空间的内容
----------------------------------------------------------------------<

--**********************************************
--*******************血流成河*******************
--**********************************************

WRITE_LOG = false
DEBUG_MAHJONG = false
NO_SHUFFLE = false --无洗牌（绝不可外传）
NO_EXCHANGE = false --虚假换牌（绝不可外传）

DEBUG_FOR_YALI_TEST = false --true


-----------------------PRIVATE DATA----------------------
PRIVATE_DATA_BOOL_NEED_SETTLE_ACCOUNTS = 0 --是否需要结算流水(需要的时候置为1，结算完置为0，防止重复调用结算)
PRIVATE_DATA_BOOL_MINIGAME_PAUSE = PRIVATE_DATA_BOOL_NEED_SETTLE_ACCOUNTS + 1 --游戏是否暂停（debug用）

--PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT = 0
--PRIVATE_DATA_BYTE_ALLCARDS = PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT + 4
PRIVATE_DATA_BYTE_ALLCARDS = 0 --全牌堆数据（洗牌后存入，优化后只存后56张，前面的直接发给玩家）
PRIVATE_DATA_BYTE_OPERATE_RECORD = PRIVATE_DATA_BYTE_ALLCARDS + 108 --碰杠胡等玩家操作消息（先存储消息，再判断优先级，整体执行）
PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN = 5
PRIVATE_DATA_BYTE_FIRST_FIRE = PRIVATE_DATA_BYTE_OPERATE_RECORD + PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN * 4 --第一个一炮多响的放炮者（轮庄用）
PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT = PRIVATE_DATA_BYTE_FIRST_FIRE + 1 --出牌超时次数（超时两次自动挂机）
PRIVATE_DATA_BYTE_FIRST_WINNER = PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT + 4 --第一个胡牌玩家（轮庄用）
PRIVATE_DATA_BYTE_PLAYER_INCOME_MULTI = PRIVATE_DATA_BYTE_FIRST_WINNER + 1 --玩家本局所有赢的番数（计算雀神点数用）
PRIVATE_DATA_BYTE_CUR_OPERATE_CARD = PRIVATE_DATA_BYTE_PLAYER_INCOME_MULTI + 4 --当前操作的牌（发牌or出牌）
PRIVATE_DATA_BYTE_HU_COUNT = PRIVATE_DATA_BYTE_CUR_OPERATE_CARD + 1 --玩家体型设置
PRIVATE_DATA_BYTE_TEMP_PLAYER_ACCENT = PRIVATE_DATA_BYTE_HU_COUNT + 4 --玩家胡牌次数
PRIVATE_DATA_BYTE_PLAYER_IS_FIRST_CIRCLE = PRIVATE_DATA_BYTE_TEMP_PLAYER_ACCENT + 4 --玩家是否第一次抓牌
PRIVATE_DATA_BYTE_PLAYER_MAX_HU_NAMEID = PRIVATE_DATA_BYTE_PLAYER_IS_FIRST_CIRCLE + 4 --玩家历史最大番型

PRIVATE_DATA_SHORT_PLAYER_CONTINUE_CUR_WIN_COUNT = 0 --玩家当前连胜场数
PRIVATE_DATA_SHORT_PLAYER_CONTINUE_MAX_WIN_COUNT = PRIVATE_DATA_SHORT_PLAYER_CONTINUE_CUR_WIN_COUNT + 4 --玩家历史连胜场数

PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM = 0  --倒计时回调函数的参数存储（pasu恢复的时候执行onMiniGameTimer函数）
PRIVATE_DATA_INT_PLAYER_MAX_HU_CASH = PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM + 2  --玩家历史最大番数
PRIVATE_DATA_INT_PLAYER_MATCH_COUNT = PRIVATE_DATA_INT_PLAYER_MAX_HU_CASH + 4  --玩家总局数
PRIVATE_DATA_INT_PLAYER_WIN_COUNT = PRIVATE_DATA_INT_PLAYER_MATCH_COUNT + 4  --玩家胜场数
PRIVATE_DATA_INT_PLAYER_HIDE_SCORE_AVERAGE = PRIVATE_DATA_INT_PLAYER_WIN_COUNT + 4 --玩家隐藏分平均值（用来计算雀神点数的输赢权重）

-----------------------PLAYER DATA-----------------------

PLAYER_DATA_BOOL_OPERATE_MASKDATA = 0 --玩家可以做的碰杠胡操作，长度为6（PLAYER_OPERATE_JUMP至PLAYER_OPERATE_HU）
PLAYER_DATA_BOOL_HAVE_COMMIT_EXCHANGE = PLAYER_DATA_BOOL_OPERATE_MASKDATA + 6 --玩家是否已提交exchange

PLAYER_DATA_BYTE_PENG_COUNT = 0 --碰牌次数（碰的多了，喊话会变）
PLAYER_DATA_BYTE_CHAIRMAN_OPERATE_CARD = PLAYER_DATA_BYTE_PENG_COUNT + 1 --庄家发完14张之后，取出一张做operateCard，另存一份，方便客户端做显示处理
PLAYER_DATA_BYTE_GANG_OPERATE = PLAYER_DATA_BYTE_CHAIRMAN_OPERATE_CARD + 1 --可以操作的杠牌及类型
PLAYER_DATA_BYTE_EXCHANGE_CARD = PLAYER_DATA_BYTE_GANG_OPERATE + 8 --换牌数据（换出的）
PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK = PLAYER_DATA_BYTE_EXCHANGE_CARD + 3 --换牌数据（换回的）
PLAYER_DATA_BYTE_DATA_IN_HAND = PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK + 3 --手牌数据
PLAYER_DATA_BYTE_TING_LIST = PLAYER_DATA_BYTE_DATA_IN_HAND + 27 --胡牌后的听牌列表
PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN_PTR = PLAYER_DATA_BYTE_TING_LIST + 9 --杠牌流水指针（for退税）
PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN = PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN_PTR + 1  --杠牌流水（for退税） 最多暗杠/碰后杠4次 4*3 (玩家杠牌数据 player1, player2, player3)

PLAYER_DATA_INT_GANG_CASH_FLOW_IN = 0  --玩家杠牌收入（for退税） 长度4*3

-----------------------PUBLIC DATA------------------------

PUBLIC_DATA_BOOL_PLAYER_ALIVE = 0 --玩家是否认输
PUBLIC_DATA_BOOL_PLAYER_IS_LOCK_TING = PUBLIC_DATA_BOOL_PLAYER_ALIVE + 4 --玩家是否锁牌（胡过）
--PUBLIC_DATA_BOOL_PLAYER_IS_FIRST_CIRCLE = PUBLIC_DATA_BOOL_PLAYER_IS_LOCK_TING + 4 --是否是第一回合摸牌（算地胡）
PUBLIC_DATA_BOOL_PLAYER_IS_AGENT = PUBLIC_DATA_BOOL_PLAYER_IS_LOCK_TING + 4 --是否挂机
PUBLIC_DATA_BOOL_PLAYER_IS_TING = PUBLIC_DATA_BOOL_PLAYER_IS_AGENT + 4 --是否听牌（再来一张就胡牌）
PUBLIC_DATA_BOOL_PLAYER_IS_COLOR_PIG = PUBLIC_DATA_BOOL_PLAYER_IS_TING + 4 --是否是花猪

PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX = 0 --发牌指针
PUBLIC_DATA_BYTE_PLAYER_HAND_COUNT = PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX + 1 --玩家手牌张数
PUBLIC_DATA_BYTE_PLAYER_BONUS = PUBLIC_DATA_BYTE_PLAYER_HAND_COUNT + 4 --玩家碰杠区数据
PUBLIC_DATA_BYTE_EXCHANGE_PLAYERS = PUBLIC_DATA_BYTE_PLAYER_BONUS + 32 --提交换牌的玩家计数（用标志位保存）
PUBLIC_DATA_BYTE_LACK = PUBLIC_DATA_BYTE_EXCHANGE_PLAYERS + 1 --定缺数据
PUBLIC_DATA_BYTE_LACK_PLAYERS = PUBLIC_DATA_BYTE_LACK + 4 --提交定缺的玩家计数（用标志位保存）
PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX = PUBLIC_DATA_BYTE_LACK_PLAYERS + 1 --弃牌区指针
PUBLIC_DATA_BYTE_DICE = PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX + 1 --摇骰子结果
PUBLIC_DATA_BYTE_COUNT_DOWN_PLAYER_AND_TYPE = PUBLIC_DATA_BYTE_DICE + 1 --倒计时玩家及倒计时类型
--PUBLIC_DATA_BYTE_GANG_COUNT = PUBLIC_DATA_BYTE_DICE + 1 --全局杠牌数（我原以为杠的越多番数越大，跟斗地主一样。。。）
PUBLIC_DATA_BYTE_CUR_OPERATE_PLAYER = PUBLIC_DATA_BYTE_COUNT_DOWN_PLAYER_AND_TYPE + 1 --当前操作的玩家
PUBLIC_DATA_BYTE_CHAIRMAN = PUBLIC_DATA_BYTE_CUR_OPERATE_PLAYER + 1 --庄家
PUBLIC_DATA_BYTE_TABLE_MGR_STATE = PUBLIC_DATA_BYTE_CHAIRMAN + 1 --牌桌状态
PUBLIC_DATA_BYTE_LAST_GANG_PLAYER = PUBLIC_DATA_BYTE_TABLE_MGR_STATE + 1 --上一个杠牌的玩家，给下一个玩家发牌后清零（用来判定杠上开花/杠上炮）
PUBLIC_DATA_BYTE_HU_CARDS_INDEX = PUBLIC_DATA_BYTE_LAST_GANG_PLAYER + 1 --胡牌记录指针，将玩家ID和card拼接，方便客户端读取及显示（流水也可以查询，但是不直观）
PUBLIC_DATA_BYTE_HU_CARDS = PUBLIC_DATA_BYTE_HU_CARDS_INDEX + 1 --胡牌记录 68张牌：(27(九连)*3(花色) - 13(倒霉蛋手牌)) 高两位玩家ID，低六位牌值
PUBLIC_DATA_BYTE_ABANDON_CARDS = PUBLIC_DATA_BYTE_HU_CARDS + 68 --弃牌区数据：高两位玩家ID，低六位牌值
PUBLIC_DATA_BYTE_ALL_PLAYER_CASH_FLOW = PUBLIC_DATA_BYTE_ABANDON_CARDS + 56 --欢乐豆流水（复式记账） 224组数据：(23(九连)*3(花色) - 13(倒霉蛋手牌))*4(自摸) (玩家流水数据 nCastPlayer, nAimPlayer, card, type, nameID)
CONST_CASH_BYTE_FLOW_LEN = 5
PUBLIC_DATA_BYTE_DEBUG_PEEP_OTHERS_HAND = PUBLIC_DATA_BYTE_ALL_PLAYER_CASH_FLOW + 1120 --debug功能，将其他玩家手牌数据暂存在public数据块，方便client读取，客户端可以主动申请刷新，14张*4

PUBLIC_DATA_SHORT_ALL_PLAYER_CASH_FLOW_PTR = 0 --流水指针
PUBLIC_DATA_SHORT_ALL_PLAYER_MULTI_FLOW = PUBLIC_DATA_SHORT_ALL_PLAYER_CASH_FLOW_PTR + 1  --玩家流水（理论番数）224组数据：( 23(九连)*3(花色) - 13(倒霉蛋手牌) )*4(自摸) (玩家流水收入 理论番数)

PUBLIC_DATA_INT_CASH_BASE = 0 --底分（麻将桌传入）
PUBLIC_DATA_INT_COUNT_DOWN_TIME = PUBLIC_DATA_INT_CASH_BASE + 1 --当前倒计时结束的时间（方便client对时间戳，做倒计时显示）
PUBLIC_DATA_INT_PLAYER_CASH_ORIGIN = PUBLIC_DATA_INT_COUNT_DOWN_TIME + 1 --玩家原始欢乐豆（用来算本场输赢，记录战绩）
PUBLIC_DATA_INT_PLAYER_CASH = PUBLIC_DATA_INT_PLAYER_CASH_ORIGIN + 4 --玩家欢乐豆
PUBLIC_DATA_INT_PLAYER_CASH_HONOR = PUBLIC_DATA_INT_PLAYER_CASH + 4 --玩家雀神点数
PUBLIC_DATA_INT_PLAYER_HIDE_SCORE = PUBLIC_DATA_INT_PLAYER_CASH_HONOR + 4  --玩家隐藏分（用来计算雀神点数的增减权重）
PUBLIC_DATA_INT_ALL_PLAYER_CASH_FLOW = PUBLIC_DATA_INT_PLAYER_HIDE_SCORE + 4  --玩家流水（真实流水）224组数据：( 23(九连)*3(花色) - 13(倒霉蛋手牌) )*4(自摸) (玩家流水收入 cash)

-----------------------MSG---------------------------

PLAYER_OPERATE_JUMP = 0 --过牌
PLAYER_OPERATE_PENG = PLAYER_OPERATE_JUMP + 1 --碰牌，跟牌值
PLAYER_OPERATE_MING_GANG = PLAYER_OPERATE_PENG + 1 --明杠，跟牌值
PLAYER_OPERATE_AN_GANG = PLAYER_OPERATE_MING_GANG + 1 --暗杠，跟牌值
PLAYER_OPERATE_GANG_AFTER_PENG = PLAYER_OPERATE_AN_GANG + 1 --暗杠，跟牌值
PLAYER_OPERATE_HU = PLAYER_OPERATE_GANG_AFTER_PENG + 1 --胡牌，跟牌值
PLAYER_OPERATE_CS_SEND = PLAYER_OPERATE_HU + 1 --出牌，跟牌值
PLAYER_OPERATE_SC_SEND_13 = PLAYER_OPERATE_CS_SEND + 1 --发牌，跟牌值 *自己读手牌
PLAYER_OPERATE_SC_SEND = PLAYER_OPERATE_SC_SEND_13 + 1 --发牌，跟牌值
PLAYER_OPERATE_PRE_EXCHANGE = PLAYER_OPERATE_SC_SEND + 1 --系统默认给的三张换牌，跟牌值
PLAYER_OPERATE_EXCHANGE = PLAYER_OPERATE_PRE_EXCHANGE + 1 --确定换牌的三张（换回的三张），跟牌值
PLAYER_OPERATE_PRE_LACK = PLAYER_OPERATE_EXCHANGE + 1 --定缺，跟花色（0，1，2）
PLAYER_OPERATE_SET_LACK = PLAYER_OPERATE_PRE_LACK + 1 --定缺，跟花色（0，1，2）
PLAYER_OPERATE_SYN_CASH = PLAYER_OPERATE_SET_LACK + 1 --同步钱数，跟值，差值
PLAYER_OPERATE_SET_CUR_PLAYER = PLAYER_OPERATE_SYN_CASH + 1 --设置下一个操作者，playerID
PLAYER_OPERATE_SYN_OPERATE_MASK = PLAYER_OPERATE_SET_CUR_PLAYER + 1 --同步可做的操作，跟mask *如果可以杠牌，自己读杠牌的数据
PLAYER_OPERATE_SET_CHAIRMAN = PLAYER_OPERATE_SYN_OPERATE_MASK + 1 --设置庄家，playerID
PLAYER_OPERATE_DICE = PLAYER_OPERATE_SET_CHAIRMAN + 1 --摇色子，服务器返回会跟上结果（十位第一个色子，个第二个色子）
PLAYER_OPERATE_TIME = PLAYER_OPERATE_DICE + 1 --操作倒计时，跟时间
PLAYER_OPERATE_STEAL_CARD = PLAYER_OPERATE_TIME + 1 --偷牌，跟不要的牌，跟要偷的牌
PLAYER_OPERATE_SHUFFLE_CARD = PLAYER_OPERATE_STEAL_CARD + 1 --洗牌，暂时不用
PLAYER_OPERATE_TABLE_STATE = PLAYER_OPERATE_SHUFFLE_CARD + 1 --同步牌桌状态
PLAYER_OPERATE_MULTI_FIRE = PLAYER_OPERATE_TABLE_STATE + 1 --广播一炮多响
PLAYER_OPERATE_OUT_OF_MONEY = PLAYER_OPERATE_MULTI_FIRE + 1 --认输
PLAYER_OPERATE_TUISHUI = PLAYER_OPERATE_OUT_OF_MONEY + 1 --退税
PLAYER_OPERATE_CHECK_DAJIAO = PLAYER_OPERATE_TUISHUI + 1 --查大叫
PLAYER_OPERATE_CHECK_COLORPIG = PLAYER_OPERATE_CHECK_DAJIAO + 1 --查花猪
PLAYER_OPERATE_ERROR = PLAYER_OPERATE_CHECK_COLORPIG + 1 --发送错误操作的操作码
PLAYER_OPERATE_SYN_CUR_CARD = PLAYER_OPERATE_ERROR + 1 --保存当前操作的牌
PLAYER_OPERATE_SYN_CASH_HONOR = PLAYER_OPERATE_SYN_CUR_CARD + 1 --同步荣誉点数，跟值，差值
PLAYER_OPERATE_DEBUG_PEEP_OTHER_HAND = PLAYER_OPERATE_SYN_CASH_HONOR + 1 --申请获取其他玩家手牌，跟玩家ID
PLAYER_OPERATE_SET_AGENT = PLAYER_OPERATE_DEBUG_PEEP_OTHER_HAND + 1 --设置挂机
PLAYER_OPERATE_WAIT = PLAYER_OPERATE_SET_AGENT + 1 --第一轮等待出牌读秒读完
PLAYER_OPERATE_GET_READY = PLAYER_OPERATE_WAIT + 1 --玩家点准备（CONST_TABLE_STATE_END_GAME状态才生效）
PLAYER_OPERATE_DEBUG_SET_PLAYER_DATA = PLAYER_OPERATE_GET_READY + 1 --设置玩家数据
PLAYER_OPERATE_HU_1_PAO_N_XIANG = PLAYER_OPERATE_DEBUG_SET_PLAYER_DATA + 1 --一炮多响
PLAYER_OPERATE_HEART_BEAT = PLAYER_OPERATE_HU_1_PAO_N_XIANG + 1 --心跳协议
PLAYER_OPERATE_EXCHANGE_CONFIRM = PLAYER_OPERATE_HEART_BEAT + 1 --确认收到上行换牌数据
PLAYER_OPERATE_SET_ACCENT = PLAYER_OPERATE_EXCHANGE_CONFIRM + 1 --设置玩家口音
PLAYER_OPERATE_CLOSE_UI = PLAYER_OPERATE_SET_ACCENT + 1 --关闭麻将UI

-----------------------ERROR CODE---------------------------
--发生异常时向客户端发送的各种错误码
ERROR_CODE_PLAYER_INACTIVE_WHEN_INIT = 0
ERROR_CODE_PLAYER_CARD_NOT_EXIT_WHEN_CSSEND = 1
ERROR_CODE_PLAYER_CARDS_NOT_LEGAL_COUNT = 2
ERROR_CODE_PLAYER_CANOT_GANG = 3
ERROR_CODE_PLAYER_MASK_is0_OR_STATE_WRONG = 4
ERROR_CODE_PLAYER_DUPLICATE = 5
ERROR_CODE_PLAYER_CANOT_HU = 6
ERROR_CODE_PLAYER_CARD_VALUE_INLEGAL = 7


BONUS_GANG_MULTIPLE = {
	[PLAYER_OPERATE_MING_GANG] = 2,
	[PLAYER_OPERATE_AN_GANG] = 2,
	[PLAYER_OPERATE_GANG_AFTER_PENG] = 1
}--杠牌番数

-----------------------TABLE MGR STATE---------------------------
CONST_TABLE_STATE_INIT = 1 --牌桌初始化(下一状态：等待玩家换牌)
CONST_TABLE_STATE_EXCHANGE = 2 --等待玩家换牌
CONST_TABLE_STATE_SET_LACK = 3 --等待玩家定缺
CONST_TABLE_STATE_WAIT_CS_SEND = 4 --等待玩家出牌
CONST_TABLE_STATE_WAIT_OPERATE = 5 --等待玩家操作碰杠胡
CONST_TABLE_STATE_WAIT_OPERATE_COMBO = 6 --有人操作了碰杠胡，但是还有别的玩家可以操作
CONST_TABLE_STATE_TUISHUI = 7 --退税、查大叫、查花猪
CONST_TABLE_STATE_END_GAME = 8 --牌局结束
CONST_TABLE_STATE_WAIT_CS_SEND_1 = 9 --等待玩家出牌（第二轮等待）
CONST_TABLE_STATE_KILL_MAHJONG = 10 --关闭小游戏
CONST_TABLE_STATE_WAIT_CS_SEND_AGENT = 11 --托管出牌
CONST_TABLE_STATE_WAIT_OPERATE_LOCKTING = 12 --锁牌操作时间

-----------------------COUNT DOWN---------------------------
CONST_COUNT_DOWN_TIME = {
	[CONST_TABLE_STATE_INIT] = 1,
	[CONST_TABLE_STATE_EXCHANGE] = 19,--30,
	[CONST_TABLE_STATE_SET_LACK] = 20,--20,
	[CONST_TABLE_STATE_WAIT_CS_SEND] = 8,
	[CONST_TABLE_STATE_WAIT_OPERATE] = 8,
	[CONST_TABLE_STATE_WAIT_OPERATE_COMBO] = 3,--5,
	[CONST_TABLE_STATE_TUISHUI] = -1,
	[CONST_TABLE_STATE_END_GAME] = 300,
	[CONST_TABLE_STATE_WAIT_CS_SEND_1] = 8,
	[CONST_TABLE_STATE_WAIT_CS_SEND_AGENT] = 5,
	[CONST_TABLE_STATE_WAIT_OPERATE_LOCKTING] = 2
}--倒计时时间

-----------------------CARD CONST---------------------------
CONST_PLAYER_MAX = 4 --最大玩家数
CONST_CARDS_INHAND_MAX = 13 --最大手牌数
CONST_CARDS_NUM = 108 --全牌数组长度

-----------------------DEBUG PLAYER DATA--------------------
--debug功能，金手指修改玩家or牌桌数据
CONST_PLAYER_CASH = 1
CONST_PLAYER_CASH_HONOR = 2
CONST_PLAYER_HIDE_SCORE = 3
CONST_PLAYER_ACCENT = 4
CONST_PLAYER_SHAPE = 5
CONST_PLAYER_AGENT = 6
CONST_PAUSE = 7
CONST_RESTART_GAME = 8
CONST_FAST_END = 9
CONST_GUANXING = 10

--[[
连胜：
是否处于连胜状态 - byte 1
当前连胜场数 - short 2
历史最高连胜场数 - short 2

胜率：
总对局数 - int 4
总胜场数 - int 4

历史最大番数 - int 4
历史最大番型 - byte 1

隐藏分 - int 4
雀神点数 - int 4
--]]
MAHJONG_DATAS_REMOTE_ID = 1056
REMOTE_MAHJONG_DATAS = {
--	CUR_CONTINUE_WIN_STATE = {1, 1},
	CUR_CONTINUE_WIN_COUNT = {0, 2}, --当前连胜场次
	HISTORY_CONTINUE_WIN_COUNT = {2, 2}, --历史连胜记录
	HISTORY_MATCH_COUNT = {4, 4}, --历史总场次
	HISTORY_WIN_COUNT = {8, 4}, --历史总胜场数
	HISTORY_MAX_CASH = {12, 4}, --历史最大胡牌番数（番数是应收值）
	HISTORY_MAX_CASH_NAME = {16, 1}, --历史最大番名
	HIDE_SCORE = {17, 4}, --隐藏分
	HU_MATCH_COUNT = {21, 4} --胡牌局数
}

CONST_HUANLEDOU_ID = 35995
CONST_CASH_HONOR_ID = 36020


-- local miniGameMgr = GetMiniGameMgr()--时间太早，获取为nil

function CalcGangCashScore(type)
	return BONUS_GANG_MULTIPLE[type]
end

function SetNeedSettleAccounts(need)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BOOL, PRIVATE_DATA_BOOL_NEED_SETTLE_ACCOUNTS, need)
end

function GetNeedSettleAccounts()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BOOL, PRIVATE_DATA_BOOL_NEED_SETTLE_ACCOUNTS)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetIsMiniGamePause(isPause)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BOOL, PRIVATE_DATA_BOOL_MINIGAME_PAUSE, isPause)
end

function GetIsMiniGamePause()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BOOL, PRIVATE_DATA_BOOL_MINIGAME_PAUSE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetSingleCard(ptr, card)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_ALLCARDS + ptr - 1, card)
end

function SetAllCards(data, offsetPtr)
--	-- local mgr = GetMiniGameMgr()
	local offset1 = PRIVATE_DATA_BYTE_ALLCARDS + offsetPtr
	local offset2 = offsetPtr
	for i = 1, 4 do
		GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
			offset1, data[offset2 + 1],
			offset1 + 1, data[offset2 + 2],
			offset1 + 2, data[offset2 + 3],
			offset1 + 3, data[offset2 + 4],
			offset1 + 4, data[offset2 + 5],
			offset1 + 5, data[offset2 + 6],
			offset1 + 6, data[offset2 + 7],
			offset1 + 7, data[offset2 + 8],
			offset1 + 8, data[offset2 + 9],
			offset1 + 9, data[offset2 + 10],
			offset1 + 10, data[offset2 + 11],
			offset1 + 11, data[offset2 + 12],
			offset1 + 12, data[offset2 + 13],
			offset1 + 13, data[offset2 + 14]
			)
		offset1 = offset1 + 14
		offset2 = offset2 + 14
	end
	
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX, offsetPtr)
--[[	
	local offset = 0
	for i = 1, 12 do
		offset = PRIVATE_DATA_BYTE_ALLCARDS + (i - 1) * 9
		GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
			offset, data[offset + 1],
			offset + 1, data[offset + 2],
			offset + 2, data[offset + 3],
			offset + 3, data[offset + 4],
			offset + 4, data[offset + 5],
			offset + 5, data[offset + 6],
			offset + 6, data[offset + 7],
			offset + 7, data[offset + 8],
			offset + 8, data[offset + 9]
			)
	end
--]]
--[[
	for i = PRIVATE_DATA_BYTE_ALLCARDS, PRIVATE_DATA_BYTE_ALLCARDS + 11 * 9, 9 do
		--TODO: 写入12组
		local result = GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
			i, data[i + 1],
			i + 1, data[i + 2],
			i + 2, data[i + 3],
			i + 3, data[i + 4],
			i + 4, data[i + 5],
			i + 5, data[i + 6],
			i + 6, data[i + 7],
			i + 7, data[i + 8],
			i + 8, data[i + 9]
			)
	end
--]]
end

function GetAllCards()
	local data = {}
	local count = 1
--	-- local mgr = GetMiniGameMgr()
	for i = PRIVATE_DATA_BYTE_ALLCARDS, PRIVATE_DATA_BYTE_ALLCARDS + 11 * 9, 9 do
		--TODO: 写入12组
		local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
				i,
				i + 1,
				i + 2,
				i + 3,
				i + 4,
				i + 5,
				i + 6,
				i + 7,
				i + 8
			)
		if temp == nil then
			return data
		end
		for j = 1, 9 do
			data[count] = temp[j]
			count = count + 1
		end
	end
	return data
end

function SetPlayerAliveAll(aliveData)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL,
		PUBLIC_DATA_BOOL_PLAYER_ALIVE, aliveData[1],
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 1, aliveData[2],
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 2, aliveData[3],
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 3, aliveData[4]
	)
end

function GetPlayerAliveAll()
	return GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL,
		PUBLIC_DATA_BOOL_PLAYER_ALIVE,
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 1,
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 2,
		PUBLIC_DATA_BOOL_PLAYER_ALIVE + 3
	)
end

function SetPlayerAlive(nPlayerIndex, alive)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_ALIVE + nPlayerIndex, alive)
end

function GetPlayerAlive(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_ALIVE + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function GetNextCard()
	local ptr = GetCurCardPtr()
	if ptr > CONST_CARDS_NUM then
		return 0
	end
	-- local mgr = GetMiniGameMgr()
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX, ptr + 1)
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX + ptr)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function Get13Card()
	local ptr = GetCurCardPtr()
	-- local mgr = GetMiniGameMgr()
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX, ptr + 13)
	local offset = PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX + ptr
	return GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
		offset,
		offset + 1,
		offset + 2,
		offset + 3,
		offset + 4,
		offset + 5,
		offset + 6,
		offset + 7,
		offset + 8,
		offset + 9,
		offset + 10,
		offset + 11,
		offset + 12
	)
end

function SetCurCardPtr(ptr)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX, ptr)
end

function GetCurCardPtr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_INDEX)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetExchangePlayers(mask)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_EXCHANGE_PLAYERS, mask)
end

function GetExchangePlayers()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_EXCHANGE_PLAYERS)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetLackPlayers(mask)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LACK_PLAYERS, mask)
end

function GetLackPlayers()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LACK_PLAYERS)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerOperateRecord(nPlayerIndex, nValue1, nValue2, nValue3, nValue4)
	nPlayerIndex = nPlayerIndex - 1
	local offset = PRIVATE_DATA_BYTE_OPERATE_RECORD + nPlayerIndex * PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
		offset, nPlayerIndex + 1,
		offset + 1, nValue1,
		offset + 2, nValue2,
		offset + 3, nValue3,
		offset + 4, nValue4
	)
end

function GetPlayerOperateRecord(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local offset = PRIVATE_DATA_BYTE_OPERATE_RECORD + nPlayerIndex * PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN
	return GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
			offset,
			offset + 1,
			offset + 2,
			offset + 3,
			offset + 4
		)
end

function SetFirstFire(nPlayerIndex)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_FIRST_FIRE, nPlayerIndex)
end

function GetFirstFire()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_FIRST_FIRE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerOverTimeCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT + nPlayerIndex, count)
end

function GetPlayerOverTimeCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_OVERTIME_COUNT + nPlayerIndex, count)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetFirstWinner(nPlayerIndex)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_FIRST_WINNER, nPlayerIndex)
end

function GetFirstWinner()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_FIRST_WINNER)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerIncomeMulti(nPlayerIndex, addCount)
	local count = GetPlayerIncomeMulti(nPlayerIndex)
	count = count + addCount
	if count > 30 then
		count = 30
	end
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_INCOME_MULTI + nPlayerIndex, count)
end

function GetPlayerIncomeMulti(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_INCOME_MULTI + nPlayerIndex, count)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function GetPlayerOperateRecordAll()
	local data = {}
	for i = 1, CONST_PLAYER_MAX do
		local temp = GetPlayerOperateRecord(i)
		if temp == nil then
			return data
		end

		if not (temp[1] == 0) then
			data[temp[1]] = {temp[1], temp[2], temp[3], temp[4], temp[5]}
		end
	end
	return data
end

function ClearPlayerOperateRecordAll()
	-- local mgr = GetMiniGameMgr()
	local offset = 0
	for i = 1, CONST_PLAYER_MAX do
		offset = PRIVATE_DATA_BYTE_OPERATE_RECORD + (i - 1) * PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN
		GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
			offset, 0,
			offset + 1, 0,
			offset + 2, 0,
			offset + 3, 0,
			offset + 4, 0
		)
	end
end

function CheckRecordExist()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE,
		PRIVATE_DATA_BYTE_OPERATE_RECORD,
		PRIVATE_DATA_BYTE_OPERATE_RECORD + PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN,
		PRIVATE_DATA_BYTE_OPERATE_RECORD + PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN * 2,
		PRIVATE_DATA_BYTE_OPERATE_RECORD + PRIVATE_DATA_BYTE_OPERATE_RECORD_LEN * 3
		)
	if temp == nil then
		return false
	end
	if temp[1] + temp[2] + temp[3] + temp[4] == 0 then
		return false
	end
	return true
end

function SetCashFlowPtr(ptr)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.SHORT, PUBLIC_DATA_SHORT_ALL_PLAYER_CASH_FLOW_PTR, ptr)
end

function GetCashFlowPtr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.SHORT, PUBLIC_DATA_SHORT_ALL_PLAYER_CASH_FLOW_PTR)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetCountDownTime(time, nTimeID, nPlayerIndex)
	-- local mgr = GetMiniGameMgr()
	if nPlayerIndex == -1 then
		nPlayerIndex = 0
	end
	local temp = nPlayerIndex * 0x10 + nTimeID
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_COUNT_DOWN_PLAYER_AND_TYPE, temp)

	if time > 0 then
		time = GetMiniGameMgr().GetGameTime() + time
	end
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_COUNT_DOWN_TIME, time)
	
	return time
end

function GetCountDownTime()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_COUNT_DOWN_TIME)
	if temp == nil then
		return {}
	end
	local temp1 = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_COUNT_DOWN_PLAYER_AND_TYPE)
	if temp1 == nil then
		return {}
	end
	return {temp[1], math.floor(temp1[1] / 0x10), temp1[1] % 0x10}
end

function SetCashBase(cashBase)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_CASH_BASE, cashBase)
end

function GetCashBase()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_CASH_BASE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerCashHonor(nPlayerIndex, cashHonor)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH_HONOR + nPlayerIndex, cashHonor)
end

function GetPlayerCashHonor(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH_HONOR + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerHideScore(nPlayerIndex, hideScore)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_HIDE_SCORE + nPlayerIndex, hideScore)
end

function GetPlayerHideScore(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_HIDE_SCORE + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerCash(nPlayerIndex, cash)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH + nPlayerIndex, cash)
end

function GetPlayerCash(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerCashOrigin(nPlayerIndex, cashOri)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH_ORIGIN + nPlayerIndex, cashOri)
end

function GetPlayerCashOrigin(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT, PUBLIC_DATA_INT_PLAYER_CASH_ORIGIN + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetCashFlow(nCastPlayer, nAimPlayer, cash, card, type, nameID, huMask, multi)
	--TODO: 记录现金流水
	local ptr = GetCashFlowPtr()
	local offset = PUBLIC_DATA_BYTE_ALL_PLAYER_CASH_FLOW + ptr * CONST_CASH_BYTE_FLOW_LEN
	SetCashFlowPtr(ptr + 1)
	-- local mgr = GetMiniGameMgr()
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE,
		offset, nCastPlayer * 10 + nAimPlayer,
--		offset + 1, nAimPlayer,
		offset + 1, card,
		offset + 2, type,
		offset + 3, nameID,
		offset + 4, huMask
	)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.INT,
		PUBLIC_DATA_INT_ALL_PLAYER_CASH_FLOW + ptr, cash
	)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.SHORT,
		PUBLIC_DATA_SHORT_ALL_PLAYER_MULTI_FLOW + ptr, multi
	)

	if WRITE_LOG then
		local huMaskTable = CalcHuMask(huMask)
	--	Log(tostring("记录现金流水: " .. nCastPlayer .. " | " .. nAimPlayer .. " | " .. cash .. " | " .. card .. " | " .. type .. " | " .. nameID .. " | " .. huMask .. " | " .. multi))
		-- Log(string.format(GetEditorString(17, 155), nCastPlayer, nAimPlayer, cash, card, type, nameID, huMask, multi))
		for k, v in pairs(huMaskTable) do
		--	Log(tostring("SetCashFlow huMaskTable: k:" .. k .. " v:" .. v))
			Log(string.format("SetCashFlow huMaskTable: k: %d, v: %d", k, v))
		end
	end
end

CONST_CASH_FLOW_DATA_CASTPLAYER = 1
CONST_CASH_FLOW_DATA_AIMPLAYER = 2
CONST_CASH_FLOW_DATA_CARD = 3
CONST_CASH_FLOW_DATA_TYPE = 4
CONST_CASH_FLOW_DATA_NAMEID = 5
CONST_CASH_FLOW_DATA_CASH = 7
CONST_CASH_FLOW_DATA_MULTI = 8
function GetCashFlow()
	--TODO: 读取现金流水，估计不需要了，C端可以自己读
	local ptr = GetCashFlowPtr()
	local data = {}
	if ptr == 0 then
		return data
	end
	local offset = 0
	-- local mgr = GetMiniGameMgr()
	for i = 1, ptr do
		offset = PUBLIC_DATA_BYTE_ALL_PLAYER_CASH_FLOW + (i - 1) * CONST_CASH_BYTE_FLOW_LEN
		local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE,
				offset,
				offset + 1,
				offset + 2,
				offset + 3,
				offset + 4
			)

		if temp == nil then
			return data
		end
		data[i] = {math.floor(temp[1] / 10), temp[1] % 10, temp[2], temp[3], temp[4], temp[5]}

		local temp1 = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.INT,
			PUBLIC_DATA_INT_ALL_PLAYER_CASH_FLOW + i - 1
			)
		if temp1 == nil then
			return data
		end

		local temp2 = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.SHORT,
			PUBLIC_DATA_SHORT_ALL_PLAYER_MULTI_FLOW + i - 1
			)
		if temp2 == nil then
			return data
		end
		
		data[i][CONST_CASH_FLOW_DATA_CASH] = temp1[1]
		data[i][CONST_CASH_FLOW_DATA_MULTI] = temp2[1]
		-- if WRITE_LOG then
		--	Log(tostring("读出流水: " .. data[i][1] .. " | " .. data[i][2] .. " | " .. data[i][3] .. " | " .. data[i][4] .. " | " .. data[i][5] .. " | " .. data[i][6] .. " | " .. data[i][7] .. " | " .. data[i][8]))
			-- Log(string.format(GetEditorString(17, 156), data[i][1], data[i][2], data[i][3], data[i][4], data[i][5], data[i][6], data[i][7], data[i][8]))
		-- end
	end
	return data
end

function CalcHuMask(huMask)
	local huMask_HU_AFTER_GANG = huMask % 2
	huMask = math.floor(huMask / 2)
	local huMask_ZIMO = huMask % 2
	huMask = math.floor(huMask / 2)
	local huMask_MOON = huMask % 2
	huMask = math.floor(huMask / 2)
	local huMask_QIANG_GANG_HU = huMask % 2
	huMask = math.floor(huMask / 2)
	local huMask_1_PAO_N_XIANG = huMask % 2
	local huMask_GENS = math.floor(huMask / 2)

	local huMaskTable = {huMask_HU_AFTER_GANG, huMask_ZIMO, huMask_MOON, huMask_QIANG_GANG_HU, huMask_1_PAO_N_XIANG, huMask_GENS}
	return huMaskTable
end

function CalcMultiHuPlayers(huPlayers)
	local huPlayersTable = {}
	local count = 1
	while huPlayers > 0 do
		huPlayersTable[count] = huPlayers % 4
		huPlayers = math.floor(huPlayers / 4)
		count = count + 1
	end
end

function SetPlayerDebugPeepHand(nPlayerIndex)
	if nPlayerIndex < 1 or nPlayerIndex > 4 then
		return
	end
	local handCard = GetPlayerHandPure(nPlayerIndex)
	local count = #handCard
	local state = GetTableMgrState()
	if state == CONST_TABLE_STATE_WAIT_CS_SEND or state == CONST_TABLE_STATE_WAIT_CS_SEND_1 then
		local curPlayer = GetCurOperatePlayer()
		if curPlayer == nPlayerIndex then
			local curCard = GetCurOperateCard()
			count = count + 1
			handCard[count] = curCard
		end
	end
	local pos = PUBLIC_DATA_BYTE_DEBUG_PEEP_OTHERS_HAND + (nPlayerIndex - 1) * 14
	local temp = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0
	}
	for i = 1, count do
		temp[i] = handCard[i]
	end
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE,
		pos, temp[1],
		pos + 1, temp[2],
		pos + 2, temp[3],
		pos + 3, temp[4],
		pos + 4, temp[5],
		pos + 5, temp[6],
		pos + 6, temp[7],
		pos + 7, temp[8],
		pos + 8, temp[9],
		pos + 9, temp[10],
		pos + 10, temp[11],
		pos + 11, temp[12],
		pos + 12, temp[13],
		pos + 13, temp[14]
		)
end

function GetPlayerDebugPeepHand(nPlayerIndex)
	local pos = PUBLIC_DATA_BYTE_DEBUG_PEEP_OTHERS_HAND + (nPlayerIndex - 1) * 14
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE,
			pos,
			pos + 1,
			pos + 2,
			pos + 3,
			pos + 4,
			pos + 5,
			pos + 6,
			pos + 7,
			pos + 8,
			pos + 9,
			pos + 10,
			pos + 11,
			pos + 12,
			pos + 13
		)
	local data = {}
	if temp == nil then
		return data
	end
	local count = 1
	for i = 1, 14 do
		if temp[i] > 0 then
			data[count] = temp[i]
			count = count + 1
		end
	end
	return data
end

function SetPlayerHand(nPlayerIndex, data)
	--TODO: 获取玩家手牌
	nPlayerIndex = nPlayerIndex - 1
	local count = 0
	-- local mgr = GetMiniGameMgr()
	for i = 0, 2 do
		local offset1 = PLAYER_DATA_BYTE_DATA_IN_HAND + i * 9
		local offset2 = i * 0x10
		local temp = GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
				offset1, data[offset2 + 1],
				offset1 + 1, data[offset2 + 2],
				offset1 + 2, data[offset2 + 3],
				offset1 + 3, data[offset2 + 4],
				offset1 + 4, data[offset2 + 5],
				offset1 + 5, data[offset2 + 6],
				offset1 + 6, data[offset2 + 7],
				offset1 + 7, data[offset2 + 8],
				offset1 + 8, data[offset2 + 9]
			)

		for j = 1,9 do
			count = count + data[offset2 + j]
		end
	end
--	SetPlayerHandCount(nPlayerIndex + 1, count)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_PLAYER_HAND_COUNT + nPlayerIndex, count)
end

function GetPlayerHand(nPlayerIndex)
	--TODO: 获取玩家手牌
	nPlayerIndex = nPlayerIndex - 1
	local data = {}
	-- local mgr = GetMiniGameMgr()
	for i = 0, 2 do
		local offset1 = PLAYER_DATA_BYTE_DATA_IN_HAND + i * 9
		local offset2 = i * 0x10
		local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
				offset1,
				offset1 + 1,
				offset1 + 2,
				offset1 + 3,
				offset1 + 4,
				offset1 + 5,
				offset1 + 6,
				offset1 + 7,
				offset1 + 8
			)
		if temp == nil then
			return data
		end
		for j = 1, 9 do
			data[offset2 + j] = temp[j]
		end
	end
	return data
end

function GetPlayerHandPure(nPlayerIndex)
	local data = {}
	local temp = GetPlayerHand(nPlayerIndex)
	if temp == nil then
		return data
	end
	local count = 1
	for color = 0x00, 0x20, 0x10 do
		for card = color + 0x01, color + 0x09 do
			while temp[card] and temp[card] > 0 do
				temp[card] = temp[card] - 1
				data[count] = card
				count = count + 1
			end
		end
	end
	if WRITE_LOG then
	--	Log(tostring("*# PlayerIndex: " .. nPlayerIndex))
		Log(string.format("*# PlayerIndex: %d", nPlayerIndex))
		for k, v in pairs(data) do
		--	Log(tostring("*#GetPlayerHandPure: k: " .. k .. " v: " .. string.format("%#x", v)))
			Log(string.format("*#GetPlayerHandPure: k: %d, v: %#x", k, v))
		end
	end
	return data
end

function SetPlayerHandCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_PLAYER_HAND_COUNT + nPlayerIndex, count)
end

function GetPlayerHandCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_PLAYER_HAND_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerBonus(nPlayerIndex, bonusTable)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 设置玩家碰杠区
	local temp = {}
	local count = 1
	-- local mgr = GetMiniGameMgr()
	for i = 1, 4 do
		temp[i * 2 - 1] = bonusTable[i][1]
		temp[i * 2] = bonusTable[i][2]
	end
	local offset = PUBLIC_DATA_BYTE_PLAYER_BONUS + nPlayerIndex * 8
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE,
		offset, temp[1],
		offset + 1, temp[2],
		offset + 2, temp[3],
		offset + 3, temp[4],
		offset + 4, temp[5],
		offset + 5, temp[6],
		offset + 6, temp[7],
		offset + 7, temp[8]
	)
end

function GetPlayerBonus(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 获取玩家碰杠区
	local offset = PUBLIC_DATA_BYTE_PLAYER_BONUS + nPlayerIndex * 8
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE,
		offset,
		offset + 1,
		offset + 2,
		offset + 3,
		offset + 4,
		offset + 5,
		offset + 6,
		offset + 7
		)
	local data = {}
	if temp == nil then
		return data
	end
	for i = 1, 4 do
		data[i] = {}
		data[i][1] = temp[i * 2 - 1]
		data[i][2] = temp[i * 2]
	end
	return data
end

function SetPlayerTingList(nPlayerIndex, table)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 获取玩家听牌列表
	local count = 1
	local temp = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	for k, v in pairs(table) do
		temp[count] = v
		count = count + 1
	end
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_TING_LIST, temp[1],
		PLAYER_DATA_BYTE_TING_LIST + 1, temp[2],
		PLAYER_DATA_BYTE_TING_LIST + 2, temp[3],
		PLAYER_DATA_BYTE_TING_LIST + 3, temp[4],
		PLAYER_DATA_BYTE_TING_LIST + 4, temp[5],
		PLAYER_DATA_BYTE_TING_LIST + 5, temp[6],
		PLAYER_DATA_BYTE_TING_LIST + 6, temp[7],
		PLAYER_DATA_BYTE_TING_LIST + 7, temp[8],
		PLAYER_DATA_BYTE_TING_LIST + 8, temp[9]
		)
end

function GetPlayerTingList(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 获取玩家听牌列表
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_TING_LIST,
		PLAYER_DATA_BYTE_TING_LIST + 1,
		PLAYER_DATA_BYTE_TING_LIST + 2,
		PLAYER_DATA_BYTE_TING_LIST + 3,
		PLAYER_DATA_BYTE_TING_LIST + 4,
		PLAYER_DATA_BYTE_TING_LIST + 5,
		PLAYER_DATA_BYTE_TING_LIST + 6,
		PLAYER_DATA_BYTE_TING_LIST + 7,
		PLAYER_DATA_BYTE_TING_LIST + 8
	)
	local data = {}
	if temp == nil then
		return data
	end
	for i = 1, 9 do
		if not (temp[i] == 0) then
			data[temp[i]] = temp[i]
		end
	end
	return data
end

function SetPlayerGangCash(nPlayerIndex, player1, cash1, player2, cash2, player3, cash3)
	nPlayerIndex = nPlayerIndex - 1
	-- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN_PTR)
	local ptr = temp[1]
	local offset = ptr * 3
	local offset1 = PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN + ptr * 3
	local offset2 = PLAYER_DATA_INT_GANG_CASH_FLOW_IN + ptr * 3
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		offset1, player1,
		offset1 + 1, player2,
		offset1 + 2, player3,
		PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN_PTR, ptr + 1
		)
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.INT,
		offset2, cash1,
		offset2 + 1, cash2,
		offset2 + 2, cash3
		)
end

function GetPlayerGangCash(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	-- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN_PTR)
	local data = {}
	if temp == nil then
		return data
	end
	local ptr = temp[1]
	local offset1 = 0
	local offset2 = 0
--	local aliveData = GetPlayerAliveAll()
	for i = 0, ptr - 1 do
		offset1 = PLAYER_DATA_BYTE_GANG_CASH_FLOW_IN + i * 3
		temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
				offset1,
				offset1 + 1,
				offset1 + 2
			)
--		for j = 1, 3 do
--			if (not(temp[j] == 0)) and aliveData[temp[j]] == 0 then
--				temp[j] = 0
--			end
--		end
		if temp == nil then
			return data
		end
		data[i+1] = {[1] = temp[1], [3] = temp[2], [5] = temp[3]}

		offset2 = PLAYER_DATA_INT_GANG_CASH_FLOW_IN + i * 3
		temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.INT,
			offset2,
			offset2 + 1,
			offset2 + 2
			)
		if temp == nil then
			return data
		end
		data[i+1][2] = temp[1]
		data[i+1][4] = temp[2]
		data[i+1][6] = temp[3]
	end
	-- if WRITE_LOG then
		-- for k, v in pairs(data) do
		--	Log(tostring(" 杠cash： k: " .. k .. "v：" .. v[1] .. " | " .. v[2] .. " | " .. v[3] .. " | " .. v[4] .. " | " .. v[5] .. " | " .. v[6]))
			-- Log(string.format(GetEditorString(17, 157), k, v[1], v[2], v[3], v[4], v[5], v[6]))
	-- 	end
	-- end
	return data
end

function SetPlayerOperateMask(nPlayerIndex, maskData, needSetOperateCount)
	if WRITE_LOG then
		Log(string.format("SetPlayerOperateMask: nPlayerIndex: %d, maskDataLenth: %d", nPlayerIndex, #maskData))
	end
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 设置玩家操作mask
	local data = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
	local operateCount = 0
	for k, v in pairs(maskData) do
		data[k] = 1
		operateCount = 1
	end
	-- local mgr = GetMiniGameMgr()
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BOOL,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA, data[0],
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 1, data[1],
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 2, data[2],
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 3, data[3],
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 4, data[4],
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 5, data[5]
		)
	if needSetOperateCount then
		GetMiniGameMgr().ChangePlayerOperateCount(nPlayerIndex, operateCount)
	end
end

function GetPlayerOperateMask(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 获取玩家操作mask
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BOOL,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 1,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 2,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 3,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 4,
		PLAYER_DATA_BOOL_OPERATE_MASKDATA + 5
		)
	local data = {}
	if temp == nil then
		return data
	end
	for i = 1, 6 do
		data[i-1] = temp[i]
	end
	return data
end

function SetPlayerHaveCommitExchange(nPlayerIndex, isCommit)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BOOL, PLAYER_DATA_BOOL_HAVE_COMMIT_EXCHANGE, isCommit)
end

function GetPlayerHaveCommitExchange(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BOOL, PLAYER_DATA_BOOL_HAVE_COMMIT_EXCHANGE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerPengCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_PENG_COUNT, count)
end

function GetPlayerPengCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_PENG_COUNT)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetChairManOperateCard(nPlayerIndex, card)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_CHAIRMAN_OPERATE_CARD, card)
end

function GetChairManOperateCard(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE, PLAYER_DATA_BYTE_CHAIRMAN_OPERATE_CARD)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerGangOperate(nPlayerIndex, gangData)
	nPlayerIndex = nPlayerIndex - 1
	local data = {0, 0, 0, 0, 0, 0, 0, 0}
	local count = 1
	for k, v in pairs(gangData) do
		data[count] = k
		data[count + 1] = v
		count = count + 2
	end
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_GANG_OPERATE, data[1],
		PLAYER_DATA_BYTE_GANG_OPERATE + 1, data[2],
		PLAYER_DATA_BYTE_GANG_OPERATE + 2, data[3],
		PLAYER_DATA_BYTE_GANG_OPERATE + 3, data[4],
		PLAYER_DATA_BYTE_GANG_OPERATE + 4, data[5],
		PLAYER_DATA_BYTE_GANG_OPERATE + 5, data[6],
		PLAYER_DATA_BYTE_GANG_OPERATE + 6, data[7],
		PLAYER_DATA_BYTE_GANG_OPERATE + 7, data[8]
		)
	-- if WRITE_LOG then
	--	Log(tostring("写入gangData: " .. data[1] .. "|" .. data[2] .. "|" .. data[3] .. "|" .. data[4] .. "|" .. data[5] .. "|" .. data[6] .. "|" .. data[7] .. "|" .. data[8]))
		-- Log(string.format(GetEditorString(17, 158), data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]))
	-- end
end

function GetPlayerGangOperate(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_GANG_OPERATE,
		PLAYER_DATA_BYTE_GANG_OPERATE + 1,
		PLAYER_DATA_BYTE_GANG_OPERATE + 2,
		PLAYER_DATA_BYTE_GANG_OPERATE + 3,
		PLAYER_DATA_BYTE_GANG_OPERATE + 4,
		PLAYER_DATA_BYTE_GANG_OPERATE + 5,
		PLAYER_DATA_BYTE_GANG_OPERATE + 6,
		PLAYER_DATA_BYTE_GANG_OPERATE + 7	
		)
	local gangData = {}
	if temp == nil then
		return gangData
	end
	for i = 1, 7, 2 do
		if not (temp[i] == 0) then
			gangData[temp[i]] = temp[i + 1]
		end
	end
	-- if WRITE_LOG then
	--	Log(tostring("读出gangData: " .. temp[1] .. "|" .. temp[2] .. "|" .. temp[3] .. "|" .. temp[4] .. "|" .. temp[5] .. "|" .. temp[6] .. "|" .. temp[7] .. "|" .. temp[8]))
		-- Log(string.format(GetEditorString(17, 159), temp[1], temp[2], temp[3], temp[4], temp[5], temp[6], temp[7], temp[8]))
	-- end
	return gangData
end

function SetPlayerLack(nPlayerIndex, lack)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 设置玩家lack
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LACK + nPlayerIndex, lack)
end

function GetPlayerLack(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 获取玩家lack
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LACK + nPlayerIndex)
	if temp == nil then
		return 255
	end
	return temp[1]
end

function ClearPlayerLack()
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LACK, 255, PUBLIC_DATA_BYTE_LACK + 1, 255, PUBLIC_DATA_BYTE_LACK + 2, 255, PUBLIC_DATA_BYTE_LACK + 3, 255)
end

function SetPlayerIsLockTing(nPlayerIndex, isLockTing)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_LOCK_TING + nPlayerIndex, isLockTing)
end

function GetPlayerIsLockTing(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_LOCK_TING + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

--[[
function SetPlayerIsFirstCircle(nPlayerIndex, isFirst)
	Log(string.format("SetPlayerIsFirstCircle nPlayerIndex: %d, isFirst: %d", nPlayerIndex, isFirst))
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_FIRST_CIRCLE + nPlayerIndex, isFirst)
end

function GetPlayerIsFirstCircle(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_FIRST_CIRCLE + nPlayerIndex)
	if temp == nil then
		return 0
	end
	Log(string.format("GetPlayerIsFirstCircle nPlayerIndex: %d, isFirst: %d", nPlayerIndex + 1, temp[1]))
	return temp[1]
end
--]]
function SetPlayerIsAgent(nPlayerIndex, isAgent)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_AGENT + nPlayerIndex, isAgent)
	if WRITE_LOG then
	--	Log(tostring("SetPlayerIsAgent：" .. nPlayerIndex .. "|" .. isAgent))
		Log(string.format("SetPlayerIsAgent: %d, isAgent: %d", nPlayerIndex + 1, isAgent))
	end
end

function GetPlayerIsAgent(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_AGENT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	if WRITE_LOG then
		Log(string.format("GetPlayerIsAgent: nPlayerIndex: %d, isAgent: %d", nPlayerIndex + 1, temp[1]))
	end
	return temp[1]
end

function SetPlayerIsTing(nPlayerIndex, isTing)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_TING + nPlayerIndex, isTing)
end

function GetPlayerIsTing(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_TING + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerIsColorPig(nPlayerIndex, isColorPig)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_COLOR_PIG + nPlayerIndex, isColorPig)
end

function GetPlayerIsColorPig(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BOOL, PUBLIC_DATA_BOOL_PLAYER_IS_COLOR_PIG + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerExchangeCard(nPlayerIndex, card1, card2, card3)
	--TODO: 设置玩家换牌
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_EXCHANGE_CARD, card1,
		PLAYER_DATA_BYTE_EXCHANGE_CARD + 1, card2,
		PLAYER_DATA_BYTE_EXCHANGE_CARD + 2, card3
		)
end

function GetPlayerExchangeCard(nPlayerIndex)
	--TODO: 获取玩家换牌
	nPlayerIndex = nPlayerIndex - 1
	return GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_EXCHANGE_CARD,
		PLAYER_DATA_BYTE_EXCHANGE_CARD + 1,
		PLAYER_DATA_BYTE_EXCHANGE_CARD + 2
	)
end

function SetPlayerExchangeCardBack(nPlayerIndex, card1, card2, card3)
	--TODO: 设置玩家换牌
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK, card1,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK + 1, card2,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK + 2, card3
		)
end

function GetPlayerExchangeCardBack(nPlayerIndex)
	--TODO: 获取玩家换牌
	nPlayerIndex = nPlayerIndex - 1
	return GetMiniGameMgr().GetPlayerData(nPlayerIndex, MINI_GAME_DATA_SIZE.BYTE,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK + 1,
		PLAYER_DATA_BYTE_EXCHANGE_CARD_BACK + 2
	)
end

function SetCurOperateCard(card)
	--TODO: 设置当前操作的牌
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_CUR_OPERATE_CARD, card)
end

function GetCurOperateCard()
	--TODO: 获取当前操作的牌
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_CUR_OPERATE_CARD)
	if temp == nil then
		return 0
	end
	return temp[1]
end

--[[
function SetPlayerShape(nPlayerIndex, shape)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_TEMP_PLAYER_SHAPE + nPlayerIndex, shape)
end

function GetPlayerShape(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_TEMP_PLAYER_SHAPE + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end
--]]

function AddPlayerHuCount(nPlayerIndex)
	SetPlayerHuCount(nPlayerIndex, GetPlayerHuCount(nPlayerIndex) + 1)
end

function SetPlayerHuCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_HU_COUNT + nPlayerIndex, count)
end

function GetPlayerHuCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_HU_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerAccent(nPlayerIndex, accent)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_TEMP_PLAYER_ACCENT + nPlayerIndex, accent)
end

function GetPlayerAccent(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_TEMP_PLAYER_ACCENT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerIsFirstCircle(nPlayerIndex, isFirst)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_IS_FIRST_CIRCLE + nPlayerIndex, isFirst)
end

function GetPlayerIsFirstCircle(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_IS_FIRST_CIRCLE + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerMaxHuNameID(nPlayerIndex, nameID)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_MAX_HU_NAMEID + nPlayerIndex, nameID)
end

function GetPlayerMaxHuNameID(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.BYTE, PRIVATE_DATA_BYTE_PLAYER_MAX_HU_NAMEID + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerCurWinCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.SHORT, PRIVATE_DATA_SHORT_PLAYER_CONTINUE_CUR_WIN_COUNT + nPlayerIndex, count)
end

function GetPlayerCurWinCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.SHORT, PRIVATE_DATA_SHORT_PLAYER_CONTINUE_CUR_WIN_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerMaxWinCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.SHORT, PRIVATE_DATA_SHORT_PLAYER_CONTINUE_MAX_WIN_COUNT + nPlayerIndex, count)
end

function GetPlayerMaxWinCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.SHORT, PRIVATE_DATA_SHORT_PLAYER_CONTINUE_MAX_WIN_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetMiniGameTimerParam(nValue1, nValue2)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM, nValue1, PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM + 1, nValue2)
end

function GetMiniGameTimerParam()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM, PRIVATE_DATA_INT_NIMIGAME_TIMER_PARAM + 1)
	if temp == nil then
		return {}
	end
	return temp
end

function SetPlayerMaxHuCash(nPlayerIndex, cash)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_MAX_HU_CASH + nPlayerIndex, cash)
end

function GetPlayerMaxHuCash(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_MAX_HU_CASH + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerMatchCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_MATCH_COUNT + nPlayerIndex, count)
end

function GetPlayerMatchCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_MATCH_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetPlayerWinCount(nPlayerIndex, count)
	nPlayerIndex = nPlayerIndex - 1
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_WIN_COUNT + nPlayerIndex, count)
end

function GetPlayerWinCount(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_WIN_COUNT + nPlayerIndex)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetAverageHideScore(score)
	GetMiniGameMgr().SetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_AVERAGE_HIDE_SCORE, count)
end

function GetAverageHideScore()
	local temp = GetMiniGameMgr().GetPrivateData(MINI_GAME_DATA_SIZE.INT, PRIVATE_DATA_INT_PLAYER_AVERAGE_HIDE_SCORE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetCurOperatePlayer(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	--TODO: 设置当前操作的玩家
	-- local mgr = GetMiniGameMgr()
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_OPERATE_PLAYER, nPlayerIndex)
	GetMiniGameMgr().ChangePlayerOperateCount(nPlayerIndex, 1)
end

function GetCurOperatePlayer()
	--TODO: 获取当前操作的玩家
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_OPERATE_PLAYER)
	if temp == nil then
		return 0
	end
	return temp[1] + 1
end

function SetLastGangPlayer(nPlayerIndex)
	-- if WRITE_LOG then
		-- Log(string.format(GetEditorString(17, 160), nPlayerIndex))
	-- end
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LAST_GANG_PLAYER, nPlayerIndex)
end

function GetLastGangPlayer()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_LAST_GANG_PLAYER)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetTableMgrState(state)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_TABLE_MGR_STATE, state)
end

function GetTableMgrState()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_TABLE_MGR_STATE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetChairMan(nPlayerIndex)
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CHAIRMAN, nPlayerIndex)
end

function GetChairMan()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CHAIRMAN)
	if temp == nil then
		return 0
	end
	return temp[1]
end

--[[
function AddGangCout()
	-- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_GANG_COUNT)
	if not(temp == nil) then
		GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_GANG_COUNT, temp[1] + 1)
	end
end
--]]

function SetDiceNum(diceNum)
	-- if WRITE_LOG then
		-- Log(string.format(GetEditorString(17, 161), diceNum))
	-- end
	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_DICE, diceNum)
end

function GetDiceNum()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_DICE)
	if temp == nil then
		return 0
	end
	return temp[1]
end

function SetHuRecord(nPlayerIndex, huCard)
	local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_HU_CARDS_INDEX)
	if not(temp == nil) then
		local ptr = temp[1]
		local hucardPlus = huCard + (nPlayerIndex - 1) * 0x40
		GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE,
			PUBLIC_DATA_BYTE_HU_CARDS_INDEX, ptr + 1,
			PUBLIC_DATA_BYTE_HU_CARDS + ptr, hucardPlus
		)
	end
end

function GetHuRecord()
	-- -- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_HU_CARDS_INDEX)
	local data = {}

	if temp == nil then
		return data
	end
	if temp[1] == 0 then
		return data
	end

	local n = math.ceil(temp[1] / 16)
	local m = temp[1] % 16
	local offset = 0
	local tempData = {}
	local count = 1
	for i = 1, n do
		offset = PUBLIC_DATA_BYTE_HU_CARDS + (i - 1) * 0x10
		tempData = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE,
					offset,
					offset + 1,
					offset + 2,
					offset + 3,
					offset + 4,
					offset + 5,
					offset + 6,
					offset + 7,
					offset + 8,
					offset + 9,
					offset + 10,
					offset + 11,
					offset + 12,
					offset + 13,
					offset + 14,
					offset + 15
				)
		if tempData == nil then
			return data
		end
		if i == n then
			if m > 0 then
				for j = 1, m do
					data[count] = math.floor(tempData[j] / 0x40) + 1
					data[count + 1] = (tempData[j] % 0x40)
					count = count + 2
				end
			end
		else
			for j = 1, 16 do
				data[count] = math.floor(tempData[j] / 0x40) + 1
				data[count + 1] = (tempData[j] % 0x40)
				count = count + 2
			end
		end
	end
	return data
end

function SetPublicAbandonCard(nPlayerIndex, card)
	-- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX)
	if not(temp == nil) then
		local cardAbandon = card + (nPlayerIndex - 1) * 0x40
		GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX, temp[1] + 1, PUBLIC_DATA_BYTE_ABANDON_CARDS + temp[1], cardAbandon)
	end
end

function GetPublicAbandonCard(current)
--	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX)
--	GetMiniGameMgr().SetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX, temp[1] + 1, PUBLIC_DATA_BYTE_ABANDON_CARDS + temp[1], card)
	-- local mgr = GetMiniGameMgr()
	local temp = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_CUR_ALLCARDS_ABANDON_INDEX)
	local data = {}

	if temp == nil then
		return data
	end
	if temp[1] == 0 then
		return data
	end
	
	local tempData = {}
	local count = 1
	if current then
		tempData = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE, PUBLIC_DATA_BYTE_ABANDON_CARDS + temp[1] - 1)
		if tempData == nil then
			return data
		end
		data[count] = math.floor(tempData[1] / 0x40) + 1
		data[count + 1] = (tempData[1] % 0x40)
	else
		local n = math.ceil(temp[1] / 16)
		local m = temp[1] % 16
		local offset = 0
		if n > 0 then
			for i = 1, n do
				offset = PUBLIC_DATA_BYTE_ABANDON_CARDS + (i - 1) * 0x10
				tempData = GetMiniGameMgr().GetPublicData(MINI_GAME_DATA_SIZE.BYTE,
							offset,
							offset + 1,
							offset + 2,
							offset + 3,
							offset + 4,
							offset + 5,
							offset + 6,
							offset + 7,
							offset + 8,
							offset + 9,
							offset + 10,
							offset + 11,
							offset + 12,
							offset + 13,
							offset + 14,
							offset + 15
					)
				if tempData == nil then
					return data
				end
				if i == n then
					if m > 0 then
						for j = 1, m do
							data[count] = math.floor(tempData[j] / 0x40) + 1
							data[count + 1] = (tempData[j] % 0x40)
							count = count + 2
						end
					end
				else
					for j = 1, 16 do
						data[count] = math.floor(tempData[j] / 0x40) + 1
						data[count + 1] = (tempData[j] % 0x40)
						count = count + 2
					end
				end
			end
		end
	end
	return data
end

function ConvertCard16to10(card)
	return (card % 16) + math.floor(card / 16) * 10
end

function ConvertCard10to16(card)
	return (card % 10) + math.floor(card / 10) * 16
end

function GetPlayerOperateCount(nPlayerIndex)
	return GetMiniGameMgr().GetPlayerOperateCount(nPlayerIndex - 1)
end

function SetPlayerOperateCount(nPlayerIndex, count)
	-- local mgr = GetMiniGameMgr()
	if nPlayerIndex == -1 then
		for i = 1, CONST_PLAYER_MAX do
			GetMiniGameMgr().ChangePlayerOperateCount(i - 1, count)
			-- if WRITE_LOG then
				-- Log(string.format(GetEditorString(17, 162), i, count))
			-- end
		end
	else
		GetMiniGameMgr().ChangePlayerOperateCount(nPlayerIndex - 1, count)
		-- if WRITE_LOG then
		--	Log(tostring("玩家操作设置：nPlayerIndex：" .. nPlayerIndex .. " 次数：" .. count))
			-- Log(string.format(GetEditorString(17, 163), nPlayerIndex, count))
		-- end
	end
end

function GetPlayerDWID(nPlayerIndex)
	nPlayerIndex = nPlayerIndex - 1
	return GetMiniGameMgr().GetPlayerID(nPlayerIndex)
end

--[[
function MgrClearData()
	GetMiniGameMgr().ClearData()
end

function MgrOperate(nPlalyerIndex, nValue1, nValue2, nValue3, nValue4)
	GetMiniGameMgr().Operate(nPlayerIndex, nValue1, nValue2, nValue3, nValue4)
end

function MgrEndGame()
	GetMiniGameMgr().EndGame()
end

function MgrSetTimer(time, nTimeID, nPlayerID)
	GetMiniGameMgr().SetTimer(time, nTimeID, nPlayerID)
end

function MgrSetTimer()
	GetMiniGameMgr().SetTimer()
end
--]]