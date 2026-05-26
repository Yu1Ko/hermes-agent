---------------------------------------------------------------------->
-- 脚本名称:	scripts/MiniGame/DouDiZhu/for3players/doudizhu3playersPlayerMgr.lua
-- 更新时间:	2021/6/1 21:42:39
-- 更新用户:	caoqing-PC
-- 脚本说明:	
----------------------------------------------------------------------<

-------------------牌形 CARD_TYPE-------------------

DDZ_CONST_CARD_TYPE_DUMP = 0 --空牌
DDZ_CONST_CARD_TYPE_SINGLE = 1 --单牌
DDZ_CONST_CARD_TYPE_SINGLE_LINE = 2 --单连
DDZ_CONST_CARD_TYPE_DOUBLE = 3 --对牌
DDZ_CONST_CARD_TYPE_DOUBLE_LINE = 4 --连对
DDZ_CONST_CARD_TYPE_TRIPLE = 5 --三张
DDZ_CONST_CARD_TYPE_TRIPLE_LINE = 6 --三连
DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE = 7 --三带一单
DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE = 8 --三带一对
DDZ_CONST_CARD_TYPE_BOMB4_SINGLE = 9 --四带二（单）
DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE = 10 --四带二（对）		注意枚举顺序，炸弹逻辑依赖该顺数判定
DDZ_CONST_CARD_TYPE_BOMB4 = 11 -- 四星炸
DDZ_CONST_CARD_TYPE_BOMB4_BIG = 12 --四星硬炸
DDZ_CONST_CARD_TYPE_BOMB5 = 13 --五星炸
DDZ_CONST_CARD_TYPE_BOMB6 = 14 --六星炸
DDZ_CONST_CARD_TYPE_BOMB7 = 15 --七星炸
DDZ_CONST_CARD_TYPE_BOMB8 = 16 --八星炸
DDZ_CONST_CARD_TYPE_BOMB9 = 17 --九星炸
DDZ_CONST_CARD_TYPE_BOMB10 = 18 --十星炸
DDZ_CONST_CARD_TYPE_BOMB11 = 19 --十一星炸
DDZ_CONST_CARD_TYPE_BOMB12 = 20 --十二星炸
DDZ_CONST_CARD_TYPE_ROCKET = 21 --王炸
DDZ_CONST_CARD_TYPE_ERROR = 255 --牌型异常

DDZ_CONST_BIG_BOMB = {
	[4] = DDZ_CONST_CARD_TYPE_BOMB4,
	[5] = DDZ_CONST_CARD_TYPE_BOMB5,
	[6] = DDZ_CONST_CARD_TYPE_BOMB6,
	[7] = DDZ_CONST_CARD_TYPE_BOMB7,
	[8] = DDZ_CONST_CARD_TYPE_BOMB8,
	[9] = DDZ_CONST_CARD_TYPE_BOMB9,
	[10] = DDZ_CONST_CARD_TYPE_BOMB10,
	[11] = DDZ_CONST_CARD_TYPE_BOMB11,
	[12] = DDZ_CONST_CARD_TYPE_BOMB12
}

--------------------------------------------
local DouDiZhuBase = {}

DouDiZhuBase.CARD_COUNT = 13
DouDiZhuBase.KING_CARD_COUNT = 15

DouDiZhuBase.NORMAL_CARD_VALUE = {
	[1] = 0x1, [2] = 0x2, [3] = 0x3, [4] = 0x4, [5] = 0x5, [6] = 0x6, [7] = 0x7, [8] = 0x8, [9] = 0x9, [10] = 0xa, [11] = 0xb, [12] = 0xc, [13] = 0xd, [14] = 0xe, [15] = 0xf
}

DouDiZhuBase.LAIZI_CARD_VALUE = {
	[1] = {[1] = 0xa1, [2] = 0xa2, [3] = 0xa3, [4] = 0xa4, [5] = 0xa5, [6] = 0xa6, [7] = 0xa7, [8] = 0xa8, [9] = 0xa9, [10] = 0xaa, [11] = 0xab, [12] = 0xac, [13] = 0xad, },
	[2] = {[1] = 0xb1, [2] = 0xb2, [3] = 0xb3, [4] = 0xb4, [5] = 0xb5, [6] = 0xb6, [7] = 0xb7, [8] = 0xb8, [9] = 0xb9, [10] = 0xba, [11] = 0xbb, [12] = 0xbc, [13] = 0xbd, }
}

DDZ_tCardsAll = {
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
	0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D,
	0x0E, 0x0F
}

--普通洗牌
function DDZ_NormalShuffle()
	local cards = {}

	for i = 1, DDZ_CONST_CARDS_NUM do
		cards[i] = DDZ_tCardsAll[i]
	end

	local temp
	local x
	for i = 1, DDZ_CONST_CARDS_NUM - 1 do
		x = math.random(i, DDZ_CONST_CARDS_NUM)
		temp = cards[i]
		cards[i] = cards[x]
		cards[x] = temp
	end

	--写入服务端牌组
	return cards
end

--不洗牌模式
function DDZ_NoShuffle(tCardsPile)
	local tCardsReturn = {}
	--不洗牌模式随机打乱几张牌
	local nShuffleNum = 5

	local temp
	local x
	for i = 1, nShuffleNum do
		x = math.random(i, DDZ_CONST_CARDS_NUM)
		temp = tCardsPile[i]
		tCardsPile[i] = tCardsPile[x]
		tCardsPile[x] = temp
	end

	--切牌逻辑，随机指定一个值为发牌起点
	local r = math.random(1, DDZ_CONST_CARDS_NUM)
	for i = 1, DDZ_CONST_CARDS_NUM do
		local n = r + i
		if n > DDZ_CONST_CARDS_NUM then
			n = n - DDZ_CONST_CARDS_NUM
		end
		tCardsReturn[i] = tCardsPile[n]
	end

	return tCardsReturn
end

function DDZ_CardsValue2LaiziValue(allCards, laizi)
	local nLaiziNum = 0
	if type(allCards) ~= "table" or (laizi == 0) or (not allCards) or (not laizi) then
		return allCards, nLaiziNum
	end

	for i = 1, #allCards do
		--判断allCards[i]是否为赖子牌
		if GetCardValueFromLaiziCard(allCards[i]) == GetCardValueFromLaiziCard(laizi) then
			--cards本身带了花色信息，直接修改最高两位既可
			if laizi > 0x80 then
				allCards[i] = allCards[i] + 0x80
			elseif laizi > 0x40 then
				allCards[i] = allCards[i] + 0x40
			end
			nLaiziNum = nLaiziNum + 1
		end
	end

	return allCards, nLaiziNum
end

function RandomLaizi()
	--随机两个赖子
	local cards = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D}

	local temp
	--当前只随机两个赖子，随机好后交换位置写入cards前两位
	for i = 1, 2 do
		local x = math.random(i, #cards)
		temp = cards[i]
		cards[i] = cards[x]
		cards[x] = temp
	end

	local laizi = {}
	laizi[1] = cards[1] + math.random(4, 7) * 0x10  --天赖子byte前两位为01
	laizi[2] = cards[2] + math.random(8, 11) * 0x10 --地赖子byte前两位为10

	return laizi
end

function AnalysebCardData(tCurOperateCards, tAnalyResult)
	local operateCards = {
		[0x01] = 0,
		[0x02] = 0,
		[0x03] = 0,
		[0x04] = 0,
		[0x05] = 0,
		[0x06] = 0,
		[0x07] = 0,
		[0x08] = 0,
		[0x09] = 0,
		[0x0A] = 0,
		[0x0B] = 0,
		[0x0C] = 0,
		[0x0D] = 0,
		[0x0E] = 0,
		[0x0F] = 0
	}
	-- 分析牌型
	for k, v in pairs(tCurOperateCards) do
		local card = GetCardValueFromLaiziCard(v)
		if CheckNumLegal(card) then
			operateCards[card] = operateCards[card] + 1
		end
	end

	for k, v in pairs(operateCards) do
		if v > 0 then
			table.insert(tAnalyResult[v], k)
		end
	end

	local sortFunc = function (a, b)
		return a < b
	end

	for k, v in pairs(tAnalyResult) do
		table.sort(v, sortFunc)
	end

end

function DDZ_ChairManCompare(tCurOperateCards, laizi)
	local operateCards = {
		[0x01] = 0,
		[0x02] = 0,
		[0x03] = 0,
		[0x04] = 0,
		[0x05] = 0,
		[0x06] = 0,
		[0x07] = 0,
		[0x08] = 0,
		[0x09] = 0,
		[0x0A] = 0,
		[0x0B] = 0,
		[0x0C] = 0,
		[0x0D] = 0,
		[0x0E] = 0,
		[0x0F] = 0
	}
	local nChairManCompare = 0
	local nCompareLaizi = 0
	--增加返回值，用于地主优先级判断，王炸：(54) > 赖子炸（天>地）：(53、52) > 2炸：(51) > 炸弹多（10-40）> 大王（5）> 小王（4）> 随机（1-3）+  赖子多（1-8）

	-- 分析牌型
	for k, v in pairs(tCurOperateCards) do
		if v > 0x40 then
			nCompareLaizi = nCompareLaizi + 1	--赖子牌数量
		end
		local card = GetCardValueFromLaiziCard(v)
		if CheckNumLegal(card) then
			operateCards[card] = operateCards[card] + 1	--根据牌值加总写入operateCards
		end
	end

	for k, v in pairs(operateCards) do
		if v == 4 then
			if nChairManCompare < 50 then  --17张手牌，最多4个炸弹
				nChairManCompare = nChairManCompare + 10
			end

			if k == 0x0D then
				--2炸51
				nChairManCompare = math.max(nChairManCompare, 51)

			elseif k == GetCardValueFromLaiziCard(laizi[2]) then
				--地赖子炸52
				nChairManCompare = math.max(nChairManCompare, 52)

			elseif k == GetCardValueFromLaiziCard(laizi[1]) then
				--天赖子炸53
				nChairManCompare = math.max(nChairManCompare, 53)
			end
		end
	end

	--小王4
	if operateCards[0x0E] == 1 then
		nChairManCompare = 4
	end

	--大王5
	if operateCards[0x0F] == 1 then
		nChairManCompare = 5
	end

	if (operateCards[0x0E] == 1) and (operateCards[0x0F] == 1) then
		--王炸54
		nChairManCompare = 54
	end

	if nChairManCompare == 0 then
		nChairManCompare = math.random(1, 3)
	end

	--癞子多为复合条件：nCompareLaizi 后可以增加癞子的权重系数
	nChairManCompare = nChairManCompare + nCompareLaizi * 2

	return nChairManCompare
end

--牌型结构体定义
DDZ_CONST_CARD_TYPE_TYPEID = 1 --牌型
DDZ_CONST_CARD_TYPE_FIRST_CARD = 2 --牌首
DDZ_CONST_CARD_TYPE_LEN = 3 --牌型长度

function AssembleCardType(type, firstCard, len)
	local cardType = {0, 0, 0}
	cardType[DDZ_CONST_CARD_TYPE_TYPEID] = type
	cardType[DDZ_CONST_CARD_TYPE_FIRST_CARD] = firstCard
	cardType[DDZ_CONST_CARD_TYPE_LEN] = len
	return cardType
end

--分析牌型
function DDZ_GetCardType(tCurOperateCards)
	if type(tCurOperateCards) ~= "table" then
		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0) --数量异常
	end

	local nCardCount = #tCurOperateCards
	if nCardCount > 20 then
		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0) --数量异常
	end
	--简单牌型
	local cardType = {0, 0, 0}
	if nCardCount == 0 then
		return AssembleCardType(DDZ_CONST_CARD_TYPE_DUMP, 0, 0) --空牌
	elseif nCardCount == 1 then
		return AssembleCardType(DDZ_CONST_CARD_TYPE_SINGLE, GetCardValueFromLaiziCard(tCurOperateCards[1]), 1) --单牌
	elseif nCardCount == 2 then
		local temp = GetCardValueFromLaiziCard(tCurOperateCards[1])
		if temp == GetCardValueFromLaiziCard(tCurOperateCards[2]) then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_DOUBLE, temp, 1) --对牌
		elseif tCurOperateCards[1] == 0x0E and tCurOperateCards[2] == 0x0F then
			cardType[DDZ_CONST_CARD_TYPE_TYPEID] = DDZ_CONST_CARD_TYPE_ROCKET
			cardType[DDZ_CONST_CARD_TYPE_FIRST_CARD] = 0x0F
			cardType[DDZ_CONST_CARD_TYPE_LEN] = 1
			return AssembleCardType(DDZ_CONST_CARD_TYPE_ROCKET, 0x0F, 1) --王炸
		elseif tCurOperateCards[1] == 0x0F and tCurOperateCards[2] == 0x0E then
			cardType[DDZ_CONST_CARD_TYPE_TYPEID] = DDZ_CONST_CARD_TYPE_ROCKET
			cardType[DDZ_CONST_CARD_TYPE_FIRST_CARD] = 0x0F
			cardType[DDZ_CONST_CARD_TYPE_LEN] = 1
			return AssembleCardType(DDZ_CONST_CARD_TYPE_ROCKET, 0x0F, 1) --王炸
		else
			return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0) --对牌异常
		end
	elseif nCardCount == 3 then
		local temp = GetCardValueFromLaiziCard(tCurOperateCards[1])
		if GetCardValueFromLaiziCard(tCurOperateCards[2]) == temp and GetCardValueFromLaiziCard(tCurOperateCards[3]) == temp then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE, temp, 1) --纯三张
		end
		--	elseif nCardCount == 4 then --需要检测癞子炸，所以再analysis之后判断
		--		local temp = GetCardValueFromLaiziCard(tCurOperateCards[1])
		--		if temp == GetCardValueFromLaiziCard(tCurOperateCards[2]) and temp == GetCardValueFromLaiziCard(tCurOperateCards[3]) and temp == GetCardValueFromLaiziCard(tCurOperateCards[4]) then
		--		end
		--			return --四星炸
		--		end
	end

	--复杂类型
	local tAnalyResult = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {},
		[9] = {},
		[10] = {},
		[11] = {},
		[12] = {}
	}
	AnalysebCardData(tCurOperateCards, tAnalyResult)

	local analyse1Count = #(tAnalyResult[1])
	local analyse2Count = #(tAnalyResult[2])
	local analyse3Count = #(tAnalyResult[3])
	local analyse4Count = #(tAnalyResult[4])
	if analyse4Count > 0 then
		if analyse4Count == 1 then
			if nCardCount == 4 then
				--硬软炸弹逻辑，牌型中没有癞子，为硬炸弹
				local BombType = true
				local nLaiZiID = GetLaziIDFromLaiziCard(tCurOperateCards[1])
				for k, v in pairs(tCurOperateCards) do
					local temp = GetLaziIDFromLaiziCard(v)
					if nLaiZiID ~= temp then
						BombType = false
						break
					end
				end
				if BombType then
					return AssembleCardType(DDZ_CONST_CARD_TYPE_BOMB4_BIG, tAnalyResult[4][1], 1) --四星硬炸弹
				else
					return AssembleCardType(DDZ_CONST_CARD_TYPE_BOMB4, tAnalyResult[4][1], 1) --四星炸弹
				end
			end
			if (analyse2Count == 1 or analyse1Count == 2) and nCardCount == 6 then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_BOMB4_SINGLE, tAnalyResult[4][1], 1) --四带2单
			end
			if analyse2Count == 2 and nCardCount == 8 then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE, tAnalyResult[4][1], 1) --四带2对
			end
		end
		--特殊的的顺牌，44445555 = 444555 + 45 炸弹视为3带1
		local lineData = {}
		for k, v in pairs(tAnalyResult[4]) do
			table.insert(tAnalyResult[3], v)
		end
		table.sort(tAnalyResult[3])		--将炸弹分解为3带1 加入3张的排表并排序
		local isAllInLine = CheckInLine(tAnalyResult[3], 3, lineData)

		if lineData[DDZ_CONST_LINE_COUNT] * 4 == nCardCount then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, tAnalyResult[3][1], analyse3Count + analyse4Count) --飞机带单翅3334
		end

		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0) --Error 四炸异常
	end

	if analyse3Count > 0 then
		--考虑222可以单打，需要将非连牌飞机单独处理
		if analyse3Count == 1 and nCardCount == 3 then
			--三张，222
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_LINE, tAnalyResult[3][1], analyse3Count)
		end

		if analyse3Count == 1 and analyse1Count == 1 and nCardCount == 4 then
			--三带一单，2224
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, tAnalyResult[3][1], analyse3Count)
		end

		if analyse3Count == 1 and analyse2Count == 1 and nCardCount == 5 then
			--三带一对，22244
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, tAnalyResult[3][1], analyse3Count)
		end

		--三带一的特殊牌型，3张中算单牌,思路为剔除其中的一张牌，看看剩下的牌是否可以组成连牌
		for i = 1, 3 do
			if nCardCount == (8 + i * 4) and analyse3Count == (i + 3) then
				for j = 1, #tAnalyResult[3] do
					local temp = tAnalyResult[3][j]
					local lineData3Count = {}
					local tAnalyResult3Count = {}
					for k, v in pairs(tAnalyResult[3]) do
						if v ~= temp then
							table.insert(tAnalyResult3Count, v)
						end
					end
					local is3CountInLine = CheckInLine(tAnalyResult3Count, 3, lineData3Count)
					if is3CountInLine and lineData3Count[DDZ_CONST_LINE_COUNT] == (i + 2) then
						return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, tAnalyResult3Count[i + 2], i + 2) --飞机带单翅3334
					end
				end
			end
		end

		local lineData = {}
		local isAllInLine = CheckInLine(tAnalyResult[3], 3, lineData)

		if analyse3Count > 1 then
			if (not isAllInLine) and lineData[DDZ_CONST_LINE_COUNT] < 3 then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0) --Error 三顺不连续
			end
		end

		if lineData[DDZ_CONST_LINE_COUNT] * 3 == nCardCount then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_LINE, tAnalyResult[3][1], analyse3Count) --三顺：333
		end

		if lineData[DDZ_CONST_LINE_COUNT] * 4 == nCardCount then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, tAnalyResult[3][1], analyse3Count) --飞机带单翅3334
		end

		if lineData[DDZ_CONST_LINE_COUNT] * 5 == nCardCount and (analyse3Count == analyse2Count or analyse3Count == analyse4Count * 2 or analyse3Count == (#tAnalyResult[6]) * 2)then
			return AssembleCardType(DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, tAnalyResult[3][1], analyse3Count) --飞机带双翅33344
		end

		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, tAnalyResult[3][1], analyse3Count) --Error 飞机异常
	end

	if analyse2Count > 2 then
		local lineData = {}
		local result = CheckInLine(tAnalyResult[2], 2, lineData)
		if result then
			if lineData[DDZ_CONST_LINE_START] == 0 then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, tAnalyResult[2][1], analyse2Count) --Error 二联不连续3355
			end
			if analyse2Count * 2 == nCardCount then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_DOUBLE_LINE, tAnalyResult[2][1], analyse2Count) --连对
			end
		end
		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, tAnalyResult[2][1], analyse2Count) --Error 连对异常
	end

	if analyse1Count > 4 then
		local lineData = {}
		local result = CheckInLine(tAnalyResult[1], 1, lineData)
		if result then
			if lineData[DDZ_CONST_LINE_START] == 0 then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, tAnalyResult[1][1], analyse1Count) --Error 连牌异常
			end
			if analyse1Count == nCardCount then
				return AssembleCardType(DDZ_CONST_CARD_TYPE_SINGLE_LINE, tAnalyResult[1][1], analyse1Count) --连牌
			end
		end
		return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, tAnalyResult[1][1], analyse1Count) --Error 连牌异常
	end

	--多星癞子炸
	if nCardCount > 4 then
		local sameCardCount = 0
		local cardValue = 0
		for k, v in pairs(tAnalyResult) do
			if #v > 0 then
				cardValue = v[1]
				sameCardCount = sameCardCount + #v
			end
		end
		if sameCardCount == 1 then
			return AssembleCardType(DDZ_CONST_BIG_BOMB[nCardCount], cardValue, sameCardCount)--多星炸弹
		end
	end

	--没有满足的情况，返回错误提示
	return AssembleCardType(DDZ_CONST_CARD_TYPE_ERROR, 0, 0)
end
-----------------------------
--[[
 //两张类型
         if(AnalyseResult.cbDoubleCount>=3)
         {
                   //变量定义
                   BYTE cbCardData=AnalyseResult.cbDoubleCardData[0];
                   BYTE cbFirstLogicValue=GetCardLogicValue(cbCardData);

                   //错误过虑
                   if(cbFirstLogicValue>=15) return CT_ERROR;

                   //连牌判断
                   for(BYTE i=1;i<AnalyseResult.cbDoubleCount;i++)
                   {
                            BYTE cbCardData=AnalyseResult.cbDoubleCardData[i*2];
                            if(cbFirstLogicValue!=(GetCardLogicValue(cbCardData)+i)) returnCT_ERROR;
                   }

                   //二连判断
                   if((AnalyseResult.cbDoubleCount*2)==cbCardCount)returnCT_DOUBLE_LINE;

                   returnCT_ERROR;
         }

--]]
-----------------------------

DDZ_CONST_LINE_START = 1
DDZ_CONST_LINE_COUNT = 2 --连牌张数
DDZ_CONST_LINE_MULTI = 3 --相同牌张数，如333，为3顺，连对223344为2顺

function CheckInLine(tCards, multi, tLineData)
	tLineData[DDZ_CONST_LINE_START] = 0
	tLineData[DDZ_CONST_LINE_COUNT] = 0
	tLineData[DDZ_CONST_LINE_MULTI] = multi
	local curCard = 0
	local allInLine = true
	for k, v in pairs(tCards) do
		if v > 0x0C then
			allInLine = false
			break
		end
		if curCard == 0 then
			curCard = v
			tLineData[DDZ_CONST_LINE_START] = curCard
		else
			curCard = curCard + 1
			if not(curCard == v) then
				allInLine = false
				break
			end
		end
		tLineData[DDZ_CONST_LINE_COUNT] = tLineData[DDZ_CONST_LINE_COUNT] + 1
	end
	return allInLine
end

--对比两个牌形，如果CompareType大则返回true，即cardType为比较对象，cardType < CompareType
function DDZ_CompareCardType(cardType, CompareType)
	if cardType[DDZ_CONST_CARD_TYPE_TYPEID] == DDZ_CONST_CARD_TYPE_ERROR or CompareType[DDZ_CONST_CARD_TYPE_TYPEID] == DDZ_CONST_CARD_TYPE_ERROR then
		return false --牌值类型有误报错
	end

	--牌形一致，比较牌首，注意需保证连牌的牌数一致
	if CompareType[DDZ_CONST_CARD_TYPE_TYPEID] == cardType[DDZ_CONST_CARD_TYPE_TYPEID] then
		if CompareType[DDZ_CONST_CARD_TYPE_FIRST_CARD] > cardType[DDZ_CONST_CARD_TYPE_FIRST_CARD] then
			if cardType[DDZ_CONST_CARD_TYPE_LEN] == 0 or CompareType[DDZ_CONST_CARD_TYPE_LEN] == cardType[DDZ_CONST_CARD_TYPE_LEN]  then
				return true
			end
		end
	end

	--炸弹，比较牌型，不比较牌首
	if CompareType[DDZ_CONST_CARD_TYPE_TYPEID] > cardType[DDZ_CONST_CARD_TYPE_TYPEID] then
		if CompareType[DDZ_CONST_CARD_TYPE_TYPEID] >= DDZ_CONST_CARD_TYPE_BOMB4 then
			return true
		end
	end

	--其他情况则均为小
	return false
end

--获取癞子牌的avart牌
function GetCardValueFromLaiziCard(laiziCard)
	return laiziCard % 0x10
end

function GetCardColorFromLaiziCard(laiziCard)
	laiziCard = math.floor(laiziCard / 0x10)
	return laiziCard % 0x04
end

--获取癞子牌数组的index
function GetLaziIDFromLaiziCard(laiziCard)
	return math.floor(laiziCard / 0x40)
end

--获取除了牌值的高位
function GetLaiziHIghBitFromLaiziCard(laiziCard)
	return laiziCard - GetCardValueFromLaiziCard(laiziCard)
end

--获取真实牌值（癞子牌取原值）：获取赖子牌花色、将赖子牌index 花色、牌值组合为原赖子牌
function GetRealValueFromLaiziCard(laiziCard, severlaizi)
	local nLaiziIndex = GetLaziIDFromLaiziCard(laiziCard)
	if nLaiziIndex > 0 then
		--赖子值组合: 高两位天地赖子标识＋客户端上传的赖子花色＋服务端记录的赖子值
		local laizi = nLaiziIndex * 0x40 + GetCardColorFromLaiziCard(laiziCard) * 0x10 + GetCardValueFromLaiziCard(severlaizi[nLaiziIndex])
		return laizi
	else
		return laiziCard
	end
end

--check牌值(数字)是否合法
function CheckNumLegal(num)
	if num < 0x01 then
		return false
	end
	if num > 0x0F then
		return false
	end
	return true
end

--check牌值(color)是否合法
function CheckColorLegal(color)
	if color < 0x00 then
		return false
	end
	if color > 0x03 then
		return false
	end
	return true
end

--check牌值(laizi)是否合法
function CheckLaiziIDLegal(laizi)
	if not (laizi == 0x01 or laizi == 0x02) then
		return false
	end
	return true
end

--check牌值是否合法
function CheckCardLegal(card)
	if not CheckNumLegal(GetCardValueFromLaiziCard(card)) then
		return false
	end

	if not CheckColorLegal(GetCardColorFromLaiziCard(card)) then
		return false
	end

	if not CheckLaiziIDLegal(GetLaziIDFromLaiziCard(card)) then
		return false
	end

	return true
end

--UI用比较函数
function DDZ_CompareCardTypeForUI(tUICards1, tUICards2)
	local tCards = {}
	tCards[1] = {}
	tCards[2] = {}

	tCards[1].MSG = DDZ_UICards2Server(tUICards1)
	tCards[2].MSG = DDZ_UICards2Server(tUICards2)

	for i = 1, 2 do
		tCards[i].Server = DDZ_CardMSG2Talbe(tCards[i].MSG[1], tCards[i].MSG[2], tCards[i].MSG[3], tCards[i].MSG[4], tCards[i].MSG[5])
		tCards[i].Type = DDZ_GetCardType(tCards[i].Server)
	end

	return DDZ_CompareCardType(tCards[1].Type, tCards[2].Type)
end

function DDZ_CardMSG2Talbe(nValue2, nValue3, nValue4, nValue5, nValue6)
	--一个牌为两位的16位数据，通过四张牌组合为一个Value传给服务器，需要将Value1-5反解会出牌列表
	local tCardMSG = {}
	local tReturn = {}
	local math = math

	if nValue2 > 0 then
		tCardMSG[1] = math.floor(nValue2 / 0x1000000)
		tCardMSG[2] = math.floor(nValue2 / 0x10000) - (tCardMSG[1] * 0x100)
		tCardMSG[3] = math.floor(nValue2 / 0x100) - (tCardMSG[1] * 0x10000) - (tCardMSG[2] * 0x100)
		tCardMSG[4] = math.floor(nValue2 % 0x100)
	end

	if nValue3 > 0 then
		tCardMSG[5] = math.floor(nValue3 / 0x1000000)
		tCardMSG[6] = math.floor(nValue3 / 0x10000) - (tCardMSG[5] * 0x100)
		tCardMSG[7] = math.floor(nValue3 / 0x100) - (tCardMSG[5] * 0x10000) - (tCardMSG[6] * 0x100)
		tCardMSG[8] = math.floor(nValue3 % 0x100)
	end

	if nValue4 > 0 then
		tCardMSG[9] = math.floor(nValue4 / 0x1000000)
		tCardMSG[10] = math.floor(nValue4 / 0x10000) - (tCardMSG[9] * 0x100)
		tCardMSG[11] = math.floor(nValue4 / 0x100) - (tCardMSG[9] * 0x10000) - (tCardMSG[10] * 0x100)
		tCardMSG[12] = math.floor(nValue4 % 0x100)
	end

	if nValue5 > 0 then
		tCardMSG[13] = math.floor(nValue5 / 0x1000000)
		tCardMSG[14] = math.floor(nValue5 / 0x10000) - (tCardMSG[13] * 0x100)
		tCardMSG[15] = math.floor(nValue5 / 0x100) - (tCardMSG[13] * 0x10000) - (tCardMSG[14] * 0x100)
		tCardMSG[16] = math.floor(nValue5 % 0x100)
	end

	if nValue6 > 0 then
		tCardMSG[17] = math.floor(nValue6 / 0x1000000)
		tCardMSG[18] = math.floor(nValue6 / 0x10000) - (tCardMSG[17] * 0x100)
		tCardMSG[19] = math.floor(nValue6 / 0x100) - (tCardMSG[17] * 0x10000) - (tCardMSG[18] * 0x100)
		tCardMSG[20] = math.floor(nValue6 % 0x100)
	end

	for k, v in pairs(tCardMSG) do
		if v ~= 0 then
			table.insert(tReturn, v)
		end
	end

	return tReturn
end

function DDZ_ServerCards2UI(handCard)
	if type(handCard) ~= "table"  then
		return nil
	end
	local tReturn = {}
	local nNum = 0
	for k, v in pairs(handCard) do
		if v and v ~= 0 then
			local temp = {0, 0, 0} --UI需要的格式为，{癞子，花色，牌值（+2）}
			temp[1] = math.floor(v / 0x40)
			temp[2] = math.floor(v / 0x10) % 0x04
			temp[3] = v % 0x10 + 2 --与UI约定牌值 + 2
			table.insert(tReturn, temp)
			nNum = nNum + 1
		end
	end

	return tReturn, nNum
end

function DDZ_UICards2Server(handCard)
	local tNormalCards = {}
	local tLaiziCards = {}
	local tServerCards = {}
	local tReturn = {}
	local nCardValue = 0
	local n = 1
	local m = 1
	--将UI格式反向解析为服务器用数据格式
	for k, v in pairs(handCard) do
		nCardValue = v[1] * 0x40 + v[2] * 0x10 + v[3] - 2
		if nCardValue > 0x80 then
			--0x80的位数放在首位DDZ_CardTable2MSG的解析会使int超标，将0x80之上的位数设定在参数的最后几位
			table.insert(tLaiziCards, nCardValue)
		else
			table.insert(tNormalCards, nCardValue)
		end
	end

	for i = 1, 20 do
		--初始化tServerCards
		tServerCards[i] = 0
		if math.fmod(i, 4) == 0 then
			--优先将会溢出的牌值插入数据尾端
			if tLaiziCards[n] then
				tServerCards[i] = tLaiziCards[n]
				n = n + 1
			else
				if tNormalCards[m] then
					tServerCards[i] = tNormalCards[m]
					m = m + 1
				end
			end
		else
			if tNormalCards[m] then
				tServerCards[i] = tNormalCards[m]
				m = m + 1
			end
		end
	end

	--服务器用牌值解析为上传逻辑
	tReturn = DDZ_CardTable2MSG(tServerCards)

	return tReturn
end

function DDZ_CardTable2MSG(handCard)
	--将4张牌拼成一个INT的方法
	if type(handCard) ~= "table"  then
		return nil
	end
	local tCardMerge = {0, 0, 0, 0, 0}
	local n = 1
	for k, v in pairs(handCard) do
		n = math.ceil(k / 4)				--4个牌值封装在一个int内
		tCardMerge[n] = tCardMerge[n] + math.pow(0x100, 3 - math.fmod(k - 1, 4)) * v
		--k = 1, 3 - math.fmod(k-1, 4) = 3,  math.pow(0x100, 3) = 0x1000000
		--k = 2, 3 - math.fmod(k-1, 4) = 2,  math.pow(0x100, 2) = 0x10000
		--k = 3, 3 - math.fmod(k-1, 4) = 1,  math.pow(0x100, 1) = 0x100
		--k = 4, 3 - math.fmod(k-1, 4) = 0,  math.pow(0x100, 0) = 0x1
	end
	return tCardMerge
end

function DDZ_TableSum(table)
	if type(table) ~= "table" then
		return nil
	end
	local sum = 0
	for k, v in pairs(table) do
		sum = sum + v
	end
	return sum
end

function DDZ_OperateLaiziType(nType, nOperateCardsNum)
	--nType : 1 经典模式（无3带2、4带2、4带2对）  2 狂野无癞子 ，3 狂野单癞子，4狂野双癞子
	if not nType then
		return nil
	end

	if not nOperateCardsNum then
		return nil
	end

	if nType > 4 or nOperateCardsNum > 20 then
		return nil
	end

	local tCardtype = {
		[1] = {
			[0] = { {DDZ_CONST_CARD_TYPE_DUMP, 0, 0 } },
			[1] = { {DDZ_CONST_CARD_TYPE_SINGLE, 0, 0 } },
			[2] = { {DDZ_CONST_CARD_TYPE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_ROCKET, 0, 0 } },
			[3] = { {DDZ_CONST_CARD_TYPE_TRIPLE, 0, 0 } },
			[4] = {{DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_BIG, 0, 0 }},
			[5] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 } },
			[6] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[7] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 } },
			[8] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 } },
			[9] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[10] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 } },
			[11] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 } },
			[12] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }},
			[13] = {  },
			[14] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 } },
			[15] = { {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[16] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 } },
			[17] = {  },
			[18] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }},
			[19] = {  },
			[20] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }},
		},
		[2] = {
			[0] = { {DDZ_CONST_CARD_TYPE_DUMP, 0, 0 }},
			[1] = { {DDZ_CONST_CARD_TYPE_SINGLE, 0, 0 } },
			[2] = { {DDZ_CONST_CARD_TYPE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_ROCKET, 0, 0 } },
			[3] = { {DDZ_CONST_CARD_TYPE_TRIPLE, 0, 0 } },
			[4] = { {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_BIG, 0, 0 }},
			[5] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 } },
			[6] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_SINGLE, 0, 0 } },
			[7] = {{DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }  },
			[8] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE, 0, 0 } },
			[9] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[10] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 } },
			[11] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 } },
			[12] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }},
			[13] = {  },
			[14] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 } },
			[15] = { {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[16] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 } },
			[17] = {  },
			[18] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }},
			[19] = {  },
			[20] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }},
		},
		[3] = {
			[0] = { {DDZ_CONST_CARD_TYPE_DUMP, 0, 0 } },
			[1] = { {DDZ_CONST_CARD_TYPE_SINGLE, 0, 0 } },
			[2] = { {DDZ_CONST_CARD_TYPE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_ROCKET, 0, 0 } },
			[3] = { {DDZ_CONST_CARD_TYPE_TRIPLE, 0, 0 } },
			[4] = { {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_BIG, 0, 0 }},
			[5] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB5, 0, 0 } },
			[6] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB6, 0, 0 } },
			[7] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB7, 0, 0 } },
			[8] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB8, 0, 0 } },
			[9] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[10] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 } },
			[11] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 } },
			[12] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }},
			[13] = {  },
			[14] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 } },
			[15] = { {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[16] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 } },
			[17] = {  },
			[18] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }},
			[19] = {  },
			[20] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }},
		},

		[4] = {
			[0] = { {DDZ_CONST_CARD_TYPE_DUMP, 0, 0 } },
			[1] = { {DDZ_CONST_CARD_TYPE_SINGLE, 0, 0 } },
			[2] = { {DDZ_CONST_CARD_TYPE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_ROCKET, 0, 0 } },
			[3] = { {DDZ_CONST_CARD_TYPE_TRIPLE, 0, 0 } },
			[4] = { {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_BIG, 0, 0 }},
			[5] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB5, 0, 0 } },
			[6] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB6, 0, 0 } },
			[7] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB7, 0, 0 } },
			[8] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB8, 0, 0 } },
			[9] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB9, 0, 0 } },
			[10] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB10, 0, 0 } },
			[11] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB11, 0, 0 } },
			[12] = { {DDZ_CONST_CARD_TYPE_SINGLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_BOMB12, 0, 0 }},
			[13] = {  },
			[14] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 } },
			[15] = { {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 } },
			[16] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 } },
			[17] = {  },
			[18] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_LINE, 0, 0 }},
			[19] = {  },
			[20] = { {DDZ_CONST_CARD_TYPE_DOUBLE_LINE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE, 0, 0 }, {DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE, 0, 0 }},
		},
	}

	return tCardtype[nType][nOperateCardsNum]
end

function DDZ_OperateLaiziCard(tOperateType, nOperateCardsNum, tHandCards, nLaiZiA, nLaiZiB, nHint)
	local tBaseTable = DouDiZhuBase.TableCard(tHandCards)
	local tSolve = {}
	tSolve.tReturnCards = {}
	tSolve.tReturnType = {}
	tSolve.nLaiZiNum = 1
	nLaiZiA = GetCardValueFromLaiziCard(nLaiZiA)
	nLaiZiB = GetCardValueFromLaiziCard(nLaiZiB)

	--统计当前手牌的癞子数量
	if nLaiZiA > 0 and tBaseTable[nLaiZiA] then
		tSolve.nLaiZiNum = tSolve.nLaiZiNum + tBaseTable[nLaiZiA]
	end

	if nLaiZiB > 0 and tBaseTable[nLaiZiB] then
		tSolve.nLaiZiNum = tSolve.nLaiZiNum + tBaseTable[nLaiZiB]
	end

	if nOperateCardsNum == 0 then
		--当出牌时上家没有出牌，则牌型数量必须与手牌数量一致。如选择三带一时手牌必须是4张
		return nil
	end

	--单张
	if tOperateType[1] == DDZ_CONST_CARD_TYPE_SINGLE then
		tSolve.Base = DouDiZhuBase.SolveDanZhang(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_SINGLE_LINE then
		tSolve.Base = DouDiZhuBase.SolveShunZi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_DOUBLE then
		tSolve.Base = DouDiZhuBase.SolveDuiZi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_DOUBLE_LINE then
		tSolve.Base = DouDiZhuBase.SolveShuangShunZi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE then
		tSolve.Base = DouDiZhuBase.SolveSanzhangPai(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_LINE then
		tSolve.Base = DouDiZhuBase.SolveSanLianPai(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE and nOperateCardsNum == 4 then
		tSolve.Base = DouDiZhuBase.SolveSanDaiYi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE and nOperateCardsNum == 5 then
		tSolve.Base = DouDiZhuBase.SolveSanDaiEr(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_BOMB4_SINGLE then
		tSolve.Base = DouDiZhuBase.SolveSiDaiEr(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_BOMB4_DOUBLE then
		tSolve.Base = DouDiZhuBase.SolveSiDaiLiangDui(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_SINGLE and nOperateCardsNum > 4 then
		tSolve.Base = DouDiZhuBase.SolveFeiJiDaiDanChi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	elseif tOperateType[1] == DDZ_CONST_CARD_TYPE_TRIPLE_DOUBLE and nOperateCardsNum > 5 then
		tSolve.Base = DouDiZhuBase.SolveFeiJiDaiShuangChi(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
	end

	tSolve.UIResultOperate, tSolve.ServerResultOperate = DouDiZhuBase.TableReplace(tSolve.Base, tHandCards)
	if tSolve.ServerResultOperate and #tSolve.ServerResultOperate ~= 0 then
		tSolve.CardType = {}
		for i = 1, #tSolve.ServerResultOperate do
			if #tSolve.ServerResultOperate[i] ~= 0 then
				tSolve.CardType[i] = DDZ_GetCardType(tSolve.ServerResultOperate[i])
				if DDZ_CompareCardType(tOperateType, tSolve.CardType[i]) then
					table.insert(tSolve.tReturnCards, tSolve.UIResultOperate[i])
					table.insert(tSolve.tReturnType, tSolve.CardType[i])
				end
			end
		end
	end

	--单王判定
	if tOperateType[1] == DDZ_CONST_CARD_TYPE_SINGLE then
		--小王需要增加出牌不能是大王的判定
		if tBaseTable[14] == 1 and tOperateType[2] < 0x0e then
			local bHint = true
			if nHint == 0 then
				if  tBaseTable[15] and tBaseTable[15] ~= 0 then
					bHint = false
				end

				for k, v in pairs(tBaseTable) do
					if k < 14 and tBaseTable[k] ~= 0 then
						bHint = false
						break
					end
				end
			end

			if bHint then
				tSolve.SjorkerUI = DDZ_ServerCards2UI({0x0e})
				tSolve.SjorkerType = DDZ_GetCardType({0x0e})

				table.insert(tSolve.tReturnCards, tSolve.SjorkerUI)
				table.insert(tSolve.tReturnType, tSolve.SjorkerType)
			end
		end

		if tBaseTable[15] == 1 then
			local bHint = true
			if nHint == 0 then
				if  tBaseTable[14] and tBaseTable[14] ~= 0 then
					bHint = false
				end

				for k, v in pairs(tBaseTable) do
					if k < 14 and tBaseTable[k] ~= 0 then
						bHint = false
						break
					end
				end
			end

			if bHint then
				tSolve.BjorkerUI = DDZ_ServerCards2UI({0x0f})
				tSolve.BjorkerType = DDZ_GetCardType({0x0f})

				table.insert(tSolve.tReturnCards, tSolve.BjorkerUI)
				table.insert(tSolve.tReturnType, tSolve.BjorkerType)
			end
		end
	end

	--炸弹判定为成遍历的方式
	for i = 4, tSolve.nLaiZiNum + 3 do
		tSolve.Bomb = {}
		if nHint == 1 then
			--从nOperateCardsNum = 4开始遍历炸弹提示
			tSolve.Bomb = DouDiZhuBase.SolveZhaDan(tBaseTable, i, nLaiZiA, nLaiZiB, nHint)
		else
			--非提示只判断i == nOperateCardsNum的情况
			if i == nOperateCardsNum then
				tSolve.Bomb = DouDiZhuBase.SolveZhaDan(tBaseTable, nOperateCardsNum, nLaiZiA, nLaiZiB, nHint)
			end
		end

		tSolve.UIResultBomb, tSolve.ServerResultBomb = DouDiZhuBase.TableReplace(tSolve.Bomb, tHandCards)

		if tSolve.ServerResultBomb and #tSolve.ServerResultBomb ~= 0 then
			tSolve.CardType = {}

			for i = 1, #tSolve.ServerResultBomb do
				if #tSolve.ServerResultBomb[i] ~= 0 then
					tSolve.CardType[i] = DDZ_GetCardType(tSolve.ServerResultBomb[i])
					if DDZ_CompareCardType(tOperateType, tSolve.CardType[i]) then
						table.insert(tSolve.tReturnCards, tSolve.UIResultBomb[i])
						table.insert(tSolve.tReturnType, tSolve.CardType[i])
					end
				end
			end
		end
	end

	--王炸判定
	if tBaseTable[14] == 1 and tBaseTable[15] == 1 then
		--非替换下必须只能选择王炸，剩下牌均不能选择
		local bHint = true
		if nHint == 0 then
			for k, v in pairs(tBaseTable) do
				if k < 14 and tBaseTable[k] ~= 0 then
					bHint = false
					break
				end
			end
		end
		if bHint then
			tSolve.Rocket = DDZ_ServerCards2UI({0x0e, 0x0f})
			tSolve.RocketType = DDZ_GetCardType({0x0e, 0x0f})

			table.insert(tSolve.tReturnCards, tSolve.Rocket)
			table.insert(tSolve.tReturnType, tSolve.RocketType)
		end
	end

	if #tSolve.tReturnCards ~= 0 then
		return tSolve.tReturnType, tSolve.tReturnCards
	end

	return nil
end

--将服务器用数据结构转化为DouDiZhuBase所使用的数据结构{[3]=1,[4]=2}表示1张3，两张4
DouDiZhuBase.TableCard = function(tCards)
	local orig_type = type(tCards)
	local tReturn = {}
	for i = 1,15 do
		tReturn[i] = 0
	end
		
	if orig_type == "table" then
		for k, v in pairs(tCards) do
			local nCardValue = GetCardValueFromLaiziCard(v)
			if tReturn[nCardValue] == nil then
				tReturn[nCardValue] = 1
			else
				tReturn[nCardValue] = tReturn[nCardValue] + 1
			end
		end
	end
	return tReturn
end

--将tReturn的表连接在一起
DouDiZhuBase.TableConcat = function(tbOrig, tbConcat)
	if type(tbOrig) ~= "table" or type(tbConcat) ~= "table" then
		return
	end
	if #tbConcat == 0 then
		return
	end
	for k, v in pairs(tbConcat) do
		table.insert(tbOrig, v)
	end
	return
end

--将tBase的结果转化回tCard的格式，需要替换癞子牌牌值
DouDiZhuBase.TableReplace = function(tBase, tCards)
	--tBase为DouDiZhuBase的格式，tCards为服务器用牌型的数组格式,nType == 1 为UI用牌型模式，nType == 2 为服务器用牌型模式
	if type(tBase) ~= "table" or type(tCards) ~= "table" then
		return nil
	end

	if #tCards == 0 or #tBase == 0 then
		return nil
	end

	local tCardsIndex = {}
	local tUIReturn = {}
	local tServerReturn = {}
	for m = 1, #tBase do
		for n = 1, #tCards do
			tCardsIndex[n] = true
		end
		local tbUIResult = {}
		local tbServerResult = {}
		for k, v in pairs(tBase[m]) do
			for i = 1, #tCards do
				if tCards[i] and tCards[i] ~= 0 then
					local temp = {0, 0, 0} --UI需要的格式为，{癞子，花色，牌值（+2）}
					temp[1] = math.floor(tCards[i] / 0x40)
					temp[2] = math.floor(tCards[i] / 0x10) % 0x04
					temp[3] = tCards[i] % 0x10
					local nBaseLaizi = math.floor(v / 0x10)
					local bReplace = false
					--非癞子牌直接替换
					if tCardsIndex[i] and v == temp[3] and temp[1] == 0 then
						bReplace = true
					end
					--地癞子判定
					if tCardsIndex[i] and nBaseLaizi == 0xa and temp[1] == 1 then
						bReplace = true
					end
					--天癞子判定
					if tCardsIndex[i] and nBaseLaizi == 0xb and temp[1] == 2 then
						bReplace = true
					end
					if bReplace then
						temp[3] = v % 0x10 + 2
						tCardsIndex[i] = false
						--根据实际情况，调整返回值为nCardValue 还是 UI用temp
						table.insert(tbUIResult, temp)
						table.insert(tbServerResult, temp[1] * 0x40 + temp[2] * 0x10 + temp[3] - 2)
						break
					end
				end
			end
		end
		table.insert(tUIReturn, tbUIResult)
		table.insert(tServerReturn, tbServerResult)
	end
	return tUIReturn, tServerReturn
end

DouDiZhuBase.TableCopy = function(tbOrig)
	local orig_type = type(tbOrig)
	local tbCopy
	if orig_type == "table" then
		tbCopy = {}
		for key, value in pairs(tbOrig) do
			tbCopy[key] = DouDiZhuBase.TableCopy(value)
		end
	else
		tbCopy = tbOrig
	end
	return tbCopy
end

DouDiZhuBase.JudgeCount = function(tbCard, nNum)
	local nCount = 0
	for i = 1, DouDiZhuBase.KING_CARD_COUNT do
		if tbCard[i] then
			nCount = nCount + tbCard[i]
		end
	end

	if nCount < nNum then
		return nil
	end

	return 1
end

DouDiZhuBase.InsertValue = function(nIndex, nLaiZiA, nLaiZiB, nPos, tbResult)
	if (nIndex ~= nLaiZiA and nIndex ~= nLaiZiB) then
		tbResult[nPos] = DouDiZhuBase.NORMAL_CARD_VALUE[nIndex]
	elseif nIndex == nLaiZiA then
		tbResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[1][nIndex]
	else
		tbResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[2][nIndex]
	end
end

DouDiZhuBase.SolveDanZhang = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 1 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempResult = {}
			DouDiZhuBase.InsertValue(i, nLaiZiA, nLaiZiB, 1, tbTempResult)
			table.insert(tbResult, tbTempResult)
		end
	end

	return tbResult
end

DouDiZhuBase.SolveDuiZi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 2 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempResult = {}
			if DouDiZhuBase.SolveLianPai(i, 2, tbCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 1, 1) then
				table.insert(tbResult, tbTempResult)
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveLianPai = function(nIndex, nNum, tbCard, nLaiZiA, nLaiZiB, tbResult, nPos, nRecycle, nAllLaizi)
	local nIndexNum = tbCard[nIndex]
	local nANum = tbCard[nLaiZiA]
	local nBNum = tbCard[nLaiZiB]

	if nAllLaizi == 0 and (tbCard[nIndex] == nil or tbCard[nIndex] == 0) then
		return nil
	end

	for i = 1, nNum do
		if tbCard[nIndex] and tbCard[nIndex] > 0 then
			DouDiZhuBase.InsertValue(nIndex, nLaiZiA, nLaiZiB, nPos, tbResult)
			nPos = nPos + 1
			tbCard[nIndex] = tbCard[nIndex] - 1
		elseif tbCard[nLaiZiA] and tbCard[nLaiZiA] > 0 then
			tbResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[1][nIndex]
			nPos = nPos + 1
			tbCard[nLaiZiA] = tbCard[nLaiZiA] - 1
		elseif tbCard[nLaiZiB] and tbCard[nLaiZiB] > 0 then
			tbResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[2][nIndex]
			nPos = nPos + 1
			tbCard[nLaiZiB] = tbCard[nLaiZiB] - 1
		else
			tbCard[nIndex] = nIndexNum
			tbCard[nLaiZiA] = nANum
			tbCard[nLaiZiB] = nBNum
			return nil
		end
	end

	if nRecycle > 0 then
		tbCard[nIndex] = nIndexNum
		tbCard[nLaiZiA] = nANum
		tbCard[nLaiZiB] = nBNum
	end

	return 1
end

DouDiZhuBase.SolveShunZi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum < 5 or nNum > 12 then
		return nil
	end

	if nHint == 0 and tbCard[DouDiZhuBase.CARD_COUNT] and tbCard[DouDiZhuBase.CARD_COUNT] > 0 and nLaiZiA ~= DouDiZhuBase.CARD_COUNT and nLaiZiB ~= DouDiZhuBase.CARD_COUNT then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local nSize = DouDiZhuBase.CARD_COUNT - 1
	for i = 1, nSize do
		if nHint == 0 and i ~= nLaiZiA and i ~= nLaiZiB and tbCard[i] and tbCard[i] > 1 then
			return nil
		end
	end

	local tbResult = {}
	nSize = 13 - nNum
	for i = 1, nSize do
		local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
		local tbTempResult = {}
		local nPos = 1
		local nJSize = i + nNum - 1

		for j = i, nJSize do
			if tbTempCard[j] and tbTempCard[j] > 0 then
				DouDiZhuBase.InsertValue(j, nLaiZiA, nLaiZiB, nPos, tbTempResult)
				nPos = nPos + 1
				tbTempCard[j] = tbTempCard[j] - 1
			else
				if tbTempCard[nLaiZiA] and tbTempCard[nLaiZiA] > 0 then
					tbTempResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[1][j]
					nPos = nPos + 1
					tbTempCard[nLaiZiA] = tbTempCard[nLaiZiA] - 1
				elseif tbTempCard[nLaiZiB] and tbTempCard[nLaiZiB] > 0 then
					tbTempResult[nPos] = DouDiZhuBase.LAIZI_CARD_VALUE[2][j]
					nPos = nPos + 1
					tbTempCard[nLaiZiB] = tbTempCard[nLaiZiB] - 1
				else
					break
				end
			end
		end

		if nPos == nNum + 1 then
			table.insert(tbResult, tbTempResult)
		end
	end

	return tbResult
end

DouDiZhuBase.SolveShuangShunZi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum % 2 == 1 or nNum < 6 then
		return nil
	end

	if nHint == 0 and tbCard[DouDiZhuBase.CARD_COUNT] and tbCard[DouDiZhuBase.CARD_COUNT] > 0 and nLaiZiA ~= DouDiZhuBase.CARD_COUNT and nLaiZiB ~= DouDiZhuBase.CARD_COUNT then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local nSize = DouDiZhuBase.CARD_COUNT - 1
	for i = 1, nSize do
		if nHint == 0 and i ~= nLaiZiA and i ~= nLaiZiB and tbCard[i] and tbCard[i] > 2 then
			return nil
		end
	end

	local tbResult = {}
	nSize = 13 - nNum / 2
	for i = 1, nSize do
		local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
		local tbTempResult = {}
		local nFind = 0
		local nPos = 1
		local nJSize = i + nNum / 2 - 1

		for j = i, nJSize do
			if tbCard[j] and tbCard[j] > 0 then
				nFind = 1
				break
			end
		end

		if nFind == 1 then
			for j = i, nJSize do
				if DouDiZhuBase.SolveLianPai(j, 2, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, nPos, 0, 1) then
					nPos = nPos + 2
				end
			end

			if nPos == nNum + 1 then
				table.insert(tbResult, tbTempResult)
			end
		end

	end

	return tbResult
end

DouDiZhuBase.SolveSanzhangPai = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 3 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		local tbTempResult = {}
		if DouDiZhuBase.SolveLianPai(i, 3, tbCard, nLaiZiA, nLaiZiB, tbTempResult, 0, 1, 0) then
			table.insert(tbResult, tbTempResult)
		end
	end

	return tbResult
end

DouDiZhuBase.SolveSanLianPai = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum < 6 or nNum % 3 ~= 0 then
		return nil
	end

	if nHint == 0 and tbCard[DouDiZhuBase.CARD_COUNT] and tbCard[DouDiZhuBase.CARD_COUNT] > 0 and nLaiZiA ~= DouDiZhuBase.CARD_COUNT and nLaiZiB ~= DouDiZhuBase.CARD_COUNT then
		return nil
	end

	for i = 1, DouDiZhuBase.CARD_COUNT do
		if nHint == 0 and i ~= nLaiZiA and i ~= nLaiZiB and tbCard[i] and tbCard[i] > 3 then
			return nil
		end
	end

	local tbResult = {}
	local nSize = 13 - nNum / 3
	for i = 1, nSize do
		local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
		local nFind = 0
		local nPos = 1
		local nJSize = i + nNum / 3 - 1
		for j = 1, nJSize do
			if tbCard[j] and tbCard[j] > 0 then
				nFind = 1
			end
		end

		if nFind == 1 then
			local tbTempResult = {}
			for j = i, nJSize do
				if DouDiZhuBase.SolveLianPai(j, 3, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, nPos, 0, 1) then
					nPos = nPos + 3
				end
			end

			if nPos == nNum + 1 then
				table.insert(tbResult, tbTempResult)
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveSanDaiYi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 4 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local nPos = 1
			local tbTempResult = {}
			if DouDiZhuBase.SolveLianPai(i, 3, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 0, 1) then
				nPos = nPos + 3

				for j = 1, DouDiZhuBase.KING_CARD_COUNT do
					if i ~= j and tbTempCard[j] and tbTempCard[j] > 0 then
						DouDiZhuBase.InsertValue(j, nLaiZiA, nLaiZiB, nPos, tbTempResult)
						nPos = nPos + 1
						break
					end
				end

				if nPos == nNum + 1 then
					table.insert(tbResult, tbTempResult)
				end
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveSanDaiEr = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 5 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local tbTempResult = {}
			if DouDiZhuBase.SolveLianPai(i, 3, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 0, 1) then
				for j = 1, DouDiZhuBase.CARD_COUNT do
					if i ~= j and tbCard[j] and tbCard[j] > 0 then
						if DouDiZhuBase.SolveLianPai(j, 2, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 4, 1, 1) then
							table.insert(tbResult, tbTempResult)
							break
						end
					end
				end
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveSiDaiEr = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 6 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local tbTempResult = {}
			if DouDiZhuBase.SolveLianPai(i, 4, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 0, 1) then
				local nPos = 5
				for j = 1, DouDiZhuBase.KING_CARD_COUNT do
					if i ~= j and tbTempCard[j] and tbTempCard[j] > 0 then
						for k = 1, tbTempCard[j] do
							DouDiZhuBase.InsertValue(j, nLaiZiA, nLaiZiB, nPos, tbTempResult)
							nPos = nPos + 1
							if nPos == 7 then
								break
							end
						end
						if nPos == 7 then
							break
						end
					end
				end
				if nPos == 7 then
					table.insert(tbResult, tbTempResult)
				end
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveSiDaiLiangDui = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum ~= 8 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		if tbCard[i] and tbCard[i] > 0 then
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local tbTempResult = {}
			if DouDiZhuBase.SolveLianPai(i, 4, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 0, 1) then
				tbCard[i] = tbCard[i] - 1
				local nFind = 0
				for j = 1, DouDiZhuBase.CARD_COUNT do
					if i ~= j  and tbCard[j] and tbCard[j] > 0 then
						local nJNum = tbTempCard[j]
						local nANum = tbTempCard[nLaiZiA]
						local nBNum = tbTempCard[nLaiZiB]
						if DouDiZhuBase.SolveLianPai(j, 2, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 5, 0, 1) then
							tbCard[j] = tbCard[j] - 1
							for k = 1, DouDiZhuBase.CARD_COUNT do
								if tbCard[k] and tbCard[k] > 0 then
									if DouDiZhuBase.SolveLianPai(k, 2, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, 7, 1, 1) then
										table.insert(tbResult, tbTempResult)
										nFind = 1
										break
									end
								end
							end
							tbCard[j] = tbCard[j] + 1
							tbTempCard[j] = nJNum
							tbTempCard[nLaiZiA] = nANum
							tbTempCard[nLaiZiB] = nBNum
							if nFind == 1 then
								break
							end
						end
					end
				end
				tbCard[i] = tbCard[i] + 1
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveZhaDan = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum < 4 or nNum > 12 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	for i = 1, DouDiZhuBase.CARD_COUNT do
		local tbTempResult = {}
		if tbCard[i] and tbCard[i] > 0 then
			if DouDiZhuBase.SolveLianPai(i, nNum, tbCard, nLaiZiA, nLaiZiB, tbTempResult, 1, 1, 1) then
				table.insert(tbResult, tbTempResult)
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveFeiJiDaiDanChi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum % 4 > 0 or nNum < 8 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	local nSize = 13 - nNum / 4
	for i = 1, nSize do
		local nFind = 0
		local nJSize = i + nNum / 4 - 1
		for j = i, nJSize do
			if tbCard[j] and tbCard[j] > 0 then
				nFind = 1
				break
			end
		end

		if nFind == 1 then
			local tbTempResult = {}
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local nPos = 1
			for j = i, nJSize do
				if not DouDiZhuBase.SolveLianPai(j, 3, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, nPos, 0, 1) then
					break
				end
				nPos = nPos + 4
			end

			if nPos == nNum + 1 then
				nPos = 1
				for j = 1, DouDiZhuBase.KING_CARD_COUNT do
					if tbTempCard[j] and tbTempCard[j] > 0 then
						for k = 1, tbTempCard[j] do
							DouDiZhuBase.InsertValue(j, nLaiZiA, nLaiZiB, nPos + 3, tbTempResult)
							nPos = nPos + 4
							if nPos == nNum + 1 then
								break
							end
						end
						if nPos == nNum + 1 then
							break
						end
					end
				end
				table.insert(tbResult, tbTempResult)
			end
		end
	end

	return tbResult
end

DouDiZhuBase.SolveFeiJiDaiShuangChi = function(tbCard, nNum, nLaiZiA, nLaiZiB, nHint)
	if nNum % 5 > 0 or nNum < 10 then
		return nil
	end

	if nHint > 0 and not DouDiZhuBase.JudgeCount(tbCard, nNum) then
		return nil
	end

	local tbResult = {}
	local nSize = 13 - nNum / 5
	for i = 1, nSize do
		local nFind = 0
		local nJSize = i + nNum / 5 - 1
		for j = i, nJSize do
			if tbCard[j] and tbCard[j] > 0 then
				nFind = 1
				break
			end
		end

		if nFind == 1 then
			local tbTempResult = {}
			local tbTempCard = DouDiZhuBase.TableCopy(tbCard)
			local nPos = 1

			for j = i, nJSize do
				if not DouDiZhuBase.SolveLianPai(j, 3, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, nPos, 0, 1) then
					break
				end

				nPos = nPos + 5
			end

			if nPos == nNum + 1 then
				nPos = 1
				for j = 1, DouDiZhuBase.CARD_COUNT do
					if tbTempCard[j] and tbTempCard[j] > 0 then
						while (tbTempCard[j])
							do
							if not DouDiZhuBase.SolveLianPai(j, 2, tbTempCard, nLaiZiA, nLaiZiB, tbTempResult, nPos + 3, 0, 1) then
								break
							end
							nPos = nPos + 5
							if nPos == nNum + 1 then
								break
							end
						end
						if nPos == nNum + 1 then
							break
						end
					end
				end

				if nPos == nNum + 1 then
					table.insert(tbResult, tbTempResult)
				end
			end
		end
	end

	return tbResult
end
