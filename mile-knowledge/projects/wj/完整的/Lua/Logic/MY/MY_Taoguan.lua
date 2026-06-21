-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: MY_Taoguan
-- Date: 2025-01-09 14:43:10
-- Desc: 茗伊插件搬运 年兽陶罐-自动砸罐 管理
-- ---------------------------------------------------------------------------------

--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 自动砸年兽陶罐
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------

MY_Taoguan = MY_Taoguan or {className = "MY_Taoguan"}
local self = MY_Taoguan

local X = MY

local FILTER_ITEM, FILTER_ITEM_DEFAULT, O, D
local TAOGUAN, XIAOJINCHUI, XIAOYINCHUI, MEILIANGYUQIAN, XINGYUNXIANGNANG, XINGYUNJINNANG, RUYIXIANGNANG, RUYIJINNANG, JIYOUGU, ZUISHENG
local ITEM_CD = 1 * GLOBAL.GAME_FPS + 8 -- 吃药CD
local HAMMER_CD = 5 * GLOBAL.GAME_FPS + 8 -- 锤子CD
local MAX_POINT_POW = 16 -- 分数最高倍数（2^n）

function MY_Taoguan.Init()
	self.RegEvent()

	-- 幸运香囊 -- 下一次有一点五倍几率砸中年兽陶罐
	-- 幸运锦囊 -- 下一次砸年兽陶罐失败则保留两点五成积分
	-- 如意香囊 -- 下一次有两点五倍几率砸中年兽陶罐
	-- 如意锦囊 -- 下一次砸年兽陶罐失败则保留一半积分
	-- 寄忧谷 -- 下一次有五倍几率砸中年兽陶罐
	-- 醉生 -- 下一次砸年兽陶罐失败则不损失积分

	local function GetItemNameByItemInfo(itemInfo, nBookInfo)
		if not itemInfo then
			return ""
		end
		return ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
	end

	FILTER_ITEM = {
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6072))), bFilter = true }, -- 鞭炮
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6069))), bFilter = true }, -- 火树银花
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6068))), bFilter = true }, -- 龙凤呈祥
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6067))), bFilter = true }, -- 彩云逐月
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6076))), bFilter = true }, -- 熠熠生辉
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6073))), bFilter = true }, -- 焰火棒
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6070))), bFilter = true }, -- 窜天猴
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6077))), bFilter = true }, -- 彩云逐月
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 8025), 1168)), bFilter = true }, -- 剪纸：龙腾
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 8025), 1170)), bFilter = true }, -- 剪纸：凤舞
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6066))), bFilter = true }, -- 元宝灯
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6067))), bFilter = true }, -- 桃花灯
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6024))), bFilter = true }, -- 年年有鱼灯
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6048))), bFilter = false }, -- 桃木牌·马
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6049))), bFilter = true }, -- 桃木牌·年
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6050))), bFilter = true }, -- 桃木牌·吉
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6051))), bFilter = true }, -- 桃木牌·祥
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6200))), bFilter = true }, -- 图样：彩云逐月
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6203))), bFilter = true }, -- 图样：熠熠生辉
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6258))), bFilter = false }, -- 监本印文兑换券
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 31599))), bFilter = false }, -- 战魂佩
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 30692))), bFilter = false }, -- 豪侠贡
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 20959))), bFilter = false }, -- 年兽陶罐
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6027))), bFilter = false }, -- 幸运香囊
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6030))), bFilter = false }, -- 幸运锦囊
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6028))), bFilter = false }, -- 如意香囊
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6031))), bFilter = false }, -- 如意锦囊
		-- { szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(GetItemInfo(5, 6043))), bFilter = false }, -- 锁住的月光宝盒

		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 27845))), bFilter = true }, -- 薛婷娥的花灯
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 27846))), bFilter = true }, -- 薛婷娥的烟花
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 6032))), bFilter = false }, -- 醉生
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 6038))), bFilter = false }, -- 梅良玉签
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 6058))), bFilter = false }, -- 小银锤
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 6060))), bFilter = false }, -- 小金锤
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 6043))), bFilter = false }, -- 损坏的月光宝盒
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(8, 36046))), bFilter = false }, -- 2026马年宠物
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(8, 36201))), bFilter = false }, -- 毛茸茸的皮袋·丙午
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(8, 45728))), bFilter = false }, -- 马上福来
		{ szName = UIHelper.GBKToUTF8(GetItemNameByItemInfo(GetItemInfo(5, 20959))), bFilter = false }, -- 年兽陶罐
	}
	FILTER_ITEM_DEFAULT = {}
	for _, p in ipairs(FILTER_ITEM) do
		FILTER_ITEM_DEFAULT[p.szName] = p.bFilter
	end
	
	-- 年兽陶罐-自动砸罐（茗伊插件）
	MY_Taoguan.O = {
		nPausePoint = 327680, 				-- 停砸分数线
		bUseTaoguan = true, 				-- 必要时使用背包的陶罐
		bNoYinchuiUseJinchui = false, 		-- 没小银锤时使用小金锤
		nUseXiaojinchui = 320, 				-- 优先使用小金锤的分数
		bPauseNoXiaojinchui = true, 		-- 缺少小金锤时停砸
		nUseXingyunXiangnang = 80, 			-- 开始吃幸运香囊的分数
		bPauseNoXingyunXiangnang = false, 	-- 缺少幸运香囊时停砸
		nUseXingyunJinnang = 80, 			-- 开始吃幸运锦囊的分数
		bPauseNoXingyunJinnang = false, 	-- 缺少幸运锦囊时停砸
		nUseRuyiXiangnang = 80, 			-- 开始吃如意香囊的分数
		bPauseNoRuyiXiangnang = false, 		-- 缺少如意香囊时停砸
		nUseRuyiJinnang = 80, 				-- 开始吃如意锦囊的分数
		bPauseNoRuyiJinnang = false, 		-- 缺少如意锦囊时停砸
		nUseJiyougu = 1280, 				-- 开始吃寄忧谷的分数
		bPauseNoJiyougu = true, 			-- 缺少寄忧谷时停砸
		nUseZuisheng = 1280, 				-- 开始吃醉生的分数
		bPauseNoZuisheng = true, 			-- 缺少醉生时停砸
		tFilterItem = FILTER_ITEM_DEFAULT,
	}
	MY_Taoguan.O_DEFAULT = clone(MY_Taoguan.O)
	CustomData.Register(CustomDataType.Role, "MY_Taoguan", MY_Taoguan.O)

	TAOGUAN = UIHelper.GBKToUTF8(Table_GetItemName(74224)) -- 年兽陶罐
	XIAOJINCHUI = UIHelper.GBKToUTF8(Table_GetItemName(65611)) -- 小金锤
	XIAOYINCHUI = UIHelper.GBKToUTF8(Table_GetItemName(65609)) -- 小银锤
	MEILIANGYUQIAN = UIHelper.GBKToUTF8(Table_GetItemName(65589)) -- 梅良玉签
	XINGYUNXIANGNANG = UIHelper.GBKToUTF8(Table_GetItemName(65578)) -- 幸运香囊
	XINGYUNJINNANG = UIHelper.GBKToUTF8(Table_GetItemName(65581)) -- 幸运锦囊
	RUYIXIANGNANG = UIHelper.GBKToUTF8(Table_GetItemName(65579)) -- 如意香囊
	RUYIJINNANG = UIHelper.GBKToUTF8(Table_GetItemName(65582)) -- 如意锦囊
	JIYOUGU = UIHelper.GBKToUTF8(Table_GetItemName(65580)) -- 寄忧谷
	ZUISHENG = UIHelper.GBKToUTF8(Table_GetItemName(65583)) -- 醉生

	MY_Taoguan.D = {
		bEnable = false, -- 启用状态
		nPoint = 0, -- 当前总分数
		nUseItemLFC = 0, -- 上次吃药的逻辑帧
		nUseHammerLFC = 0, -- 上次用锤子的逻辑帧
		dwDoodadID = 0, -- 自动拾取过滤的交互物件ID
		aUseItemPS = { -- 设置界面的物品使用条件
			{ szName = XIAOJINCHUI, szID = 'Xiaojinchui', dwItemIndex = 6060 },
			-- { szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang', dwItemIndex = 6027 },
			-- { szName = XINGYUNJINNANG, szID = 'XingyunJinnang', dwItemIndex = 6030 },
			-- { szName = RUYIXIANGNANG, szID = 'RuyiXiangnang', dwItemIndex = 6028 },
			-- { szName = RUYIJINNANG, szID = 'RuyiJinnang', dwItemIndex = 6031 },
			-- { szName = JIYOUGU, szID = 'Jiyougu', dwItemIndex = 6029 },
			{ szName = ZUISHENG, szID = 'Zuisheng', dwItemIndex = 6032 },
		},
		aUseItemOrder = { -- 状态转移函数中物品与BUFF判断逻辑
			{
				-- { szName = JIYOUGU, szID = 'Jiyougu', dwBuffID = 1660, nBuffLevel = 3 },
				-- { szName = RUYIXIANGNANG, szID = 'RuyiXiangnang', dwBuffID = 1660, nBuffLevel = 2 },
				-- { szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang', dwBuffID = 1660, nBuffLevel = 1 },
			},
			{
				{ szName = ZUISHENG, szID = 'Zuisheng', dwBuffID = 1661, nBuffLevel = 3 },
				-- { szName = RUYIJINNANG, szID = 'RuyiJinnang', dwBuffID = 1661, nBuffLevel = 2 },
				-- { szName = XINGYUNJINNANG, szID = 'XingyunJinnang', dwBuffID = 1661, nBuffLevel = 1 },
			},
		},
	}

	O = MY_Taoguan.O
	D = MY_Taoguan.D
	MY_Taoguan.FILTER_ITEM = FILTER_ITEM
	MY_Taoguan.MAX_POINT_POW = MAX_POINT_POW
end

function MY_Taoguan.UnInit()
	Event.UnRegAll(self)
	Timer.DelAllTimer(self)
end

function MY_Taoguan.RegEvent()
	Event.Reg(self, EventType.ShowImportantTip, function(tbEvent)
		local Text = tbEvent[3]
		self.MonitorZP(Text)
	end)
	Event.Reg(self, "LOADING_END", function()
		RemoteCallToServer("On_Activity_GetPotPoint")
	end)
	Event.Reg(self, "On_Activity_GetPotPoint", function(nPoint)
		LOG.INFO("[MY_Taoguan] On_Activity_GetPotPoint %s", tostring(nPoint))
		self.D.nPoint = nPoint
	end)
	Event.Reg(self, "SCENE_BEGIN_LOAD", function()
		self.Stop()
	end)
	Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
		if dwActivityID == 33 and not bOpen then
			self.Stop()
		end
	end)
end

-- 使用背包物品
function MY_Taoguan.UseBagItem(szName, bWarn)
	local me = GetClientPlayer()
	for i = 1, 6 do
		for j = 0, me.GetBoxSize(i) - 1 do
		local it = GetPlayerItem(me, i, j)
			if it and UIHelper.GBKToUTF8(it.szName) == szName then
				if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
					return
				end
				LOG.INFO("[MY_Taoguan] UseItem: " .. i .. "," .. j .. " " .. szName)
				ItemData.UseItem(i, j)
				return true
			end
		end
	end
	if bWarn then
		TipsHelper.ShowImportantYellowTip(string.format("陶罐助手：缺少[%s]！", szName))
	end
end

-- 砸罐子状态机转移函数
function MY_Taoguan.BreakCanStateTransfer()
	local me = GetClientPlayer()
	if not me or not D.bEnable then
		return
	end

	--若角色状态非静止或移动，则自动停止
	if 	me.nMoveState ~= MOVE_STATE.ON_STAND and me.nMoveState ~= MOVE_STATE.ON_WALK and 
		me.nMoveState ~= MOVE_STATE.ON_RUN and me.nMoveState ~= MOVE_STATE.ON_JUMP
	then
		self.Stop()
		return
	end

	--骑马和战斗也拦一下
	local bOnHorse = me.bOnHorse or me.bHoldHorse or me.nFollowType == FOLLOW_TYPE.RIDE or me.nFollowType == FOLLOW_TYPE.HOLDHORSE
	if me.bFightState or bOnHorse then
		self.Stop()
		return
	end

	if D.nPoint >= O.nPausePoint then
		self.Stop()
		TipsHelper.ShowImportantYellowTip("陶罐助手：已达设置上限！")
		return
	end

	local nLFC = GetLogicFrameCount()
	-- 确认掉砸金蛋确认框 在RemoteFunction.OnMessageBoxRequest中自动执行

	-- 吃药还在CD则等待
	if nLFC - D.nUseItemLFC < ITEM_CD then
		return
	end
	-- 检查吃药BUFF满足情况
	for _, aItem in ipairs(D.aUseItemOrder) do
		-- 每个分组优先级顺序处理
		for _, item in ipairs(aItem) do
			-- 符合吃药分数条件
			if D.nPoint >= O['nUse' .. item.szID] then
				-- 如果已经有BUFF，即吃过药了，则跳出循环
				if me.GetBuff(item.dwBuffID, item.nBuffLevel) then
					break
				end
				-- 否则尝试吃药
				if self.UseBagItem(item.szName, O['bPauseNo' .. item.szID]) then
					D.nUseItemLFC = nLFC
					-- 吃成功了，等待下次状态机转移函数调用
					return
				end
				if O['bPauseNo' .. item.szID] then
					-- 吃失败了，暂停砸罐子
					self.Stop()
					return
				end
			end
		end
	end
	-- 锤子还在CD则等待
	if nLFC - D.nUseHammerLFC < HAMMER_CD then
		return
	end
	-- 寻找能砸的陶罐
	local npcTaoguan
	for _, npc in ipairs(X.GetNearNpc()) do
		if npc and npc.dwTemplateID == 6820 then
			if X.GetDistance(npc) < 4 then
				npcTaoguan = npc
				break
			end
		end
	end
	-- 没有能砸的陶罐考虑自己放一个
	if not npcTaoguan and O.bUseTaoguan then
		if self.UseBagItem(TAOGUAN) then
			D.nUseItemLFC = nLFC
		end
	end
	-- 还是没有找到罐子则等待
	if not npcTaoguan then
		if not D.bNeedTaoguan then
			D.bNeedTaoguan = true
			TipsHelper.ShowNormalTip("陶罐助手：附近或背包没有年兽陶罐，无法自动砸罐")
		end
		return
	end
	-- 找到罐子了，设为目标
	D.bNeedTaoguan = false
	SetTarget(TARGET.NPC, npcTaoguan.dwID)
	-- 需要用小金锤，砸他丫的
	if D.nPoint >= O.nUseXiaojinchui then
		if self.UseBagItem(XIAOJINCHUI, O.bPauseNoXiaojinchui) then
			-- 砸成功了，等锤子CD
			D.nUseHammerLFC = nLFC
			return
		end
		if O.bPauseNoXiaojinchui then
			-- 砸失败了，暂停砸罐子
			self.Stop()
			return
		end
	end
	-- 需要用小银锤，砸他丫的
	if self.UseBagItem(XIAOYINCHUI) then
		-- 砸成功了，等锤子CD
		D.nUseHammerLFC = nLFC
		return
	end
	-- 没有小银锤时使用小金锤？
	if O.bNoYinchuiUseJinchui and self.UseBagItem(XIAOJINCHUI) then
		-- 砸成功了，等锤子CD
		D.nUseHammerLFC = nLFC
		return
	end
	-- 没有金锤也没有银锤，凉了呀
	self.UseBagItem(XIAOYINCHUI, true)
	self.Stop()
end

-------------------------------------
-- 事件处理
-------------------------------------
function MY_Taoguan.MonitorZP(szMsg)
	local _, _, nP = string.find(szMsg, "目前的总积分为：(%d+)")
	if nP then
		D.nPoint = tonumber(nP)
		if D.bEnable then
			if D.nPoint >= O.nPausePoint then
				self.Stop()
				D.bReachLimit = true
				TipsHelper.ShowImportantYellowTip("陶罐助手：已达设置上限！")
			end
			D.nUseHammerLFC = GetLogicFrameCount()
		end
	end
end

function MY_Taoguan.OnLootItem(dwPlayerID, dwItemID, dwCount)
	if dwPlayerID == GetClientPlayer().dwID and dwCount > 2 and UIHelper.GBKToUTF8(GetItem(dwItemID).szName) == MEILIANGYUQIAN then
		D.nPoint = 0
		TipsHelper.ShowNormalTip("陶罐助手：积分换光清零！")
	end
end

function MY_Taoguan.OnDoodadEnter(dwDoodadID)
	if D.bEnable or D.bReachLimit then
		local d = GetDoodad(dwDoodadID)
		if d and UIHelper.GBKToUTF8(d.szName) == TAOGUAN and d.CanDialog(GetClientPlayer()) and X.GetDistance(d) < 4.1 then
			D.dwDoodadID = dwDoodadID
			Timer.Add(self, 520 / 1000, function()
				LOG.INFO("[MY_Taoguan] Open Doodad " .. dwDoodadID .. " at " .. GetLogicFrameCount() .. ".")
				X.InteractDoodad(D.dwDoodadID)
			end)
		end
	end
end

function MY_Taoguan.OnOpenDoodad(dwDoodadID, dwPlayerID)
	local me = GetClientPlayer()
	local scene = me and me.GetScene()
	if not scene then return end

	if D.bEnable and D.dwDoodadID ~= 0 and dwPlayerID == me.dwID and dwDoodadID == D.dwDoodadID then
		if D.bEnable or D.bReachLimit then
			local d = GetDoodad(D.dwDoodadID)
			if d and UIHelper.GBKToUTF8(d.szName) == TAOGUAN then
				local nQ, nM = 1, scene.GetLootMoney(D.dwDoodadID)
				if nM > 0 then
					LootMoney(d.dwID)
				end

				local tLootInfoList = scene.GetLootList(D.dwDoodadID)
				local nLootItemCount = tLootInfoList and tLootInfoList.nItemCount or 0
				for i = 0, tLootInfoList.nItemCount - 1 do
					local it = tLootInfoList[i] and tLootInfoList[i].Item
					if it then
						local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(it))
						if it.nQuality >= nQ and not O.tFilterItem[szName]then
							LootItem(d.dwID, it.dwID)
						else
							TipsHelper.ShowNormalTip(string.format("陶罐助手：过滤 [%s]。", szName))
						end
					end
				end
			end
			D.bReachLimit = nil
		end
		D.dwDoodadID = 0
	end
end

-- 砸罐子开始（注册事件）
function MY_Taoguan.Start()
	if D.bEnable then
		return
	end
	D.bEnable = true
	D.bNeedTaoguan = false
	Timer.AddFrameCycle(self, 1, self.BreakCanStateTransfer)
	Event.Reg(self, "LOOT_ITEM", self.OnLootItem)
	Event.Reg(self, "DOODAD_ENTER_SCENE", self.OnDoodadEnter)
	Event.Reg(self, "OPEN_DOODAD", self.OnOpenDoodad)
	TipsHelper.ShowNormalTip("陶罐助手：开。")

	Event.Dispatch(EventType.OnMYTaoguanStateChanged, true)
end

-- 砸罐子关闭（注销事件）
function MY_Taoguan.Stop()
	if not D.bEnable then
		return
	end
	D.bEnable = false
	D.bNeedTaoguan = false
	Timer.DelAllTimer(self)
	Event.UnReg(self, "LOOT_ITEM")
	Event.UnReg(self, "DOODAD_ENTER_SCENE")
	Event.UnReg(self, "HELP_EVENT")
	TipsHelper.ShowNormalTip("陶罐助手：关。")

	Event.Dispatch(EventType.OnMYTaoguanStateChanged, false)
end

-- 砸罐子开关
function MY_Taoguan.Switch()
	if D.bEnable then
		self.Stop()
	else
		self.Start()
	end
end