
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetGetItemHintArea
-- Date: 2022-11-17
-- Desc: 获取物品提示区
-- ---------------------------------------------------------------------------------
local UIWidgetGetItemHintArea = class("UIWidgetGetItemHintArea")


local Def = {
	CellLife = 5, -- 秒
	MaxCellCount = 6,
}


function UIWidgetGetItemHintArea:OnEnter()
	self.m = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:Init()
end

function UIWidgetGetItemHintArea:OnExit()
	self.bInit = false
	self:StopCall()
	self:UnRegEvent()
	self.m = nil
end

function UIWidgetGetItemHintArea:StartCall()
	if not self.m.nCallId then
		self.m.nCallId = Timer.AddFrameCycle(self, 1, function ()
			self:OnUpdate()
		end)
	end
end
function UIWidgetGetItemHintArea:StopCall()
	if self.m.nCallId then
		Timer.DelTimer(self, self.m.nCallId)
		self.m.nCallId = nil
	end
end

function UIWidgetGetItemHintArea:BindUIEvent()
	-- UIHelper.BindUIEvent(self.TakeAllBtn, EventType.OnClick, function()
	-- 	print("----> self.TakeAllBtn, EventType.OnClick")
	-- end)
end

function UIWidgetGetItemHintArea:RegEvent()
	Event.Reg(self, EventType.OnClientPlayerEnter, function()
		self:InitOldValue()
	end)
	Event.Reg(self, "MONEY_UPDATE", function ()
		if arg3 then
			local tMoney = PackMoney(arg0, arg1, arg2)
			self:OnGetMoney(tMoney)
		end
	end)
	Event.Reg(self, "LOOT_ITEM", function (...)
		self:OnLootEvent("LOOT_ITEM", ...)
	end)
	Event.Reg(self, "PLAYER_EXPERIENCE_UPDATE", function ()
		-- 阅历
		local nPlayerId = arg0
		local player = g_pClientPlayer
		if player and player.dwID == nPlayerId then
			self:OnExpUpdate(player)
		end
	end)
	Event.Reg(self, "UPDATE_VIGOR", function ()
		-- 精力
		local szType = CurrencyType.Vigor
		local nOld = arg0
		local nAdd = g_pClientPlayer.nVigor - nOld
		if nAdd > 0 then
			self:PushOtherCell(szType, nAdd)
		end
	end)
	Event.Reg(self, "UPDATE_TONG_CACHE", function ()
		-- 可能帮会资金有变化, 拉新数据
		GetTongClient().ApplyTongInfo()
	end)
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		-- 检测帮会资金变化
		local szType = CurrencyType.GangFunds
		local nOld = self.m.tOld[szType]
		local nNow = CurrencyData.GetCurCurrencyCount(szType)
		if nOld then
			local nAdd = nNow - nOld
			if nAdd > 0 then
				--self:PushOtherCell(szType, nAdd)
			end
		end
		self.m.tOld[szType] = nNow
	end)
	Event.Reg(self, "UI_TRAIN_VALUE_UPDATE", function ()
		-- 修为
		local nAdd = arg0
		if nAdd > 0 then
			self:PushOtherCell(CurrencyType.Train, nAdd)
		end
	end)
	Event.Reg(self, "TITLE_POINT_UPDATE", function (nNewTitlePoint, nAdd)
		-- 战阶积分
		if nAdd > 0 then
			self:PushOtherCell(CurrencyType.TitlePoint, nAdd)
		end
	end)
	Event.Reg(self, "SYNC_COIN", function ()
		-- 通宝
		local szType = CurrencyType.Coin
		local nOld = self.m.tOld[szType]
		local nNow = CurrencyData.GetCurCurrencyCount(szType)
		if nOld then
			local nAdd = nNow - nOld
			if nAdd > 0 then
				self:PushOtherCell(szType, nAdd)
			end
		end
		self.m.tOld[szType] = nNow
	end)
	Event.Reg(self, "暂时没有适合的事件通知", function ()
		-- 商城积分
		local szType = CurrencyType.StorePoint
		local nOld = self.m.tOld[szType]
		local nNow = CurrencyData.GetCurCurrencyCount(szType)
		if nOld then
			local nAdd = nNow - nOld
			if nAdd > 0 then
				self:PushOtherCell(szType, nAdd)
			end
		end
		self.m.tOld[szType] = nNow
	end)
	Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
		-- 佟仁银票
		local szType = CurrencyType.CoinShopVoucher
		local nOld = self.m.tOld[szType]
		local nNow = CurrencyData.GetCurCurrencyCount(szType)
		if nOld then
			local nAdd = nNow - nOld
			if nAdd > 0 then
				self:PushOtherCell(szType, nAdd)
			end
		end
		self.m.tOld[szType] = nNow
	end)
	Event.Reg(self, EventType.OnGetFishTips, function(tFish, nExp)
		self:OnGetFish(tFish, nExp)
	end)

	local tCurrencyUpdateEvent = Currency_Base.GetCurrencyList()
	for _, szCurrency in ipairs(tCurrencyUpdateEvent) do
		local szEvent = ("UPDATE_" .. szCurrency):upper()
		if szEvent then
			Event.Reg(self, szEvent, function()
				local nOld = arg0
				local nAdd = CurrencyData.GetCurCurrencyCount(szCurrency) - nOld
				if nAdd > 0 then
					self:PushOtherCell(szCurrency, nAdd)
				end
			end)
		end
	end
--[[
elseif event == "BEGIN_ROLL_ITEM" then
	OnLootEvent(event)
elseif event == "LOOT_ITEM" then
	OnLootEvent(event)
elseif event == "DISTRIBUTE_ITEM" then
	OnLootEvent(event)
elseif event == "ROLL_ITEM" then
	OnLootEvent(event)
elseif event == "CANCEL_ROLL_ITEM" then
	OnLootEvent(event)
elseif event == "OPEN_DOODAD" then
	OnLootEvent(event)
--]]

end

function UIWidgetGetItemHintArea:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

function UIWidgetGetItemHintArea:OnUpdate()
	if UIMgr.GetView(VIEW_ID.PanelVideoPlayer) then
		return
	end
	UIHelper.SetVisible(self._rootNode, Global.CanShowLeftRewardTips())
	local now = Timer.RealtimeSinceStartup()
	-- life
	local arr = self.m.tScriptArr
	for i = #arr, 1, -1 do
		local tScript = arr[i]
		if not tScript.bUnused and now > tScript.nEndTime then
			self:RecycleCell(tScript)
		end
	end

	--
	if #self.m.tEventArr > 0 then
		--if #arr < Def.MaxCellCount then
		local tEvent = table.remove(self.m.tEventArr, 1)
		if tEvent.szType == "money" then
			self:AddMoneyCell(tEvent.tMoney)
		elseif tEvent.szType == "exp" then
			self:AddExpCell(tEvent.nCount)
		elseif tEvent.szType == "item" then
			self:AddItemCell(tEvent.nItemId, tEvent.nCount, tEvent.dwTabType, tEvent.dwIndex)
		elseif tEvent.szType == "fish" then
			self:AddFishCell(tEvent.nFishIndex, tEvent.nCount)
		else
			self:AddOtherCell(tEvent.szType, tEvent.nCount)
		end
		--end
	end
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetGetItemHintArea:Init()
	self.m.tScriptArr = {}
	self.m.tEventArr = {}

	-- 预取一次初值
	self.m.tOld = {}
	Timer.Add(self, 1, function ()
		self:InitOldValue()
	end)
end


function UIWidgetGetItemHintArea:InitCellPos(tScript)
	local cell = tScript._rootNode
	UIHelper.SetAnchorPoint(cell, 0, 0)
	UIHelper.SetPosition(cell, 0, 0)
end

function UIWidgetGetItemHintArea:InitOldValue()
	if not g_pClientPlayer then
		return
	end

	if self.bInitOldValue then
		return
	end

	self.bInitOldValue = true

	Event.Dispatch("SYNC_COIN")
	Event.Dispatch("UPDATE_ARCHITECTURE", g_pClientPlayer.nArchitecture)
	Event.Dispatch("ON_COIN_SHOP_VOUCHER_CHANGED")
	if TongData.HavePlayerJoinedTong() then
		Event.Dispatch("UPDATE_TONG_CACHE")
	end
end

-- other beg --------------------------------------------------
function UIWidgetGetItemHintArea:PushOtherCell(szType, nCount)
	local tScript = self:GetItemCell(szType)
	if tScript then
		tScript.nCount = tScript.nCount + nCount
		self:UpdateOtherCell(tScript)
	else
		self:PushEvent({szType = szType, nCount = nCount})
	end

	self:StartCall()
end
function UIWidgetGetItemHintArea:UpdateOtherCell(tScript)
	assert(tScript)
	local tCurrencyInfo = Table_GetCurrencyInfoByIndex(tScript.szType)
	local szCurrencyName = tCurrencyInfo and UIHelper.GBKToUTF8(tCurrencyInfo.szDescription)
	
	-- label
	UIHelper.RemoveAllChildren(tScript.LabelItem)
	UIHelper.SetString(tScript.LabelItem, (szCurrencyName or tScript.szType) .. "：" .. tScript.nCount)
	-- icon
	local tItemScript = tScript.tItemScrip
	if not tItemScript then
		tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgetItemIcon)
	end
	assert(tItemScript)
	local szFrameName = CurrencyData.tbImageSmallIcon[tScript.szType]
	assert(szFrameName, "no found szFrameName by: " .. tScript.szType)
	tItemScript:SetIconBySpriteFrameName(szFrameName)
	tItemScript:HideLabelCount()
end
function  UIWidgetGetItemHintArea:AddOtherCell(szType, nCount)
	assert(szType)
	self:MoveCell()

	local tScript = self:GetUnusedCell()
	assert(tScript)
	tScript.szType = szType
	tScript.nCount = nCount or 1
	tScript.nEndTime = Timer.RealtimeSinceStartup() + Def.CellLife

	self:UpdateOtherCell(tScript)
	self:InitCellPos(tScript)
end
-- other end --------------------------------------------------

-- exp beg --------------------------------------------------
function UIWidgetGetItemHintArea:OnExpUpdate()
	local player = GetClientPlayer()
	local nDelta = player.nExperience - (self.m.nLastExp or player.nExperience)
	self.m.nLastExp = player.nExperience
	if nDelta > 0 then
		self:PushExpCell(nDelta)
	end
end
function UIWidgetGetItemHintArea:PushExpCell(nCount)
	local tScript = self:GetItemCell("exp")
	if tScript then
		tScript.nCount = tScript.nCount + nCount
		self:UpdateExpCell(tScript)
	else
		self:PushEvent({szType = "exp", nCount = nCount})
	end

	self:StartCall()
end
function UIWidgetGetItemHintArea:UpdateExpCell(tScript)
	assert(tScript)
	-- label
	UIHelper.RemoveAllChildren(tScript.LabelItem)
	UIHelper.SetString(tScript.LabelItem, g_tStrings.STR_COMBATMSG_EXP .. tScript.nCount)
	-- icon
	local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgetItemIcon)
	assert(tItemScript)
	UIHelper.InitItemIcon_Exp(tItemScript)
	tItemScript:HideLabelCount()
end
function  UIWidgetGetItemHintArea:AddExpCell(nCount)
	self:MoveCell()

	local tScript = self:GetUnusedCell()
	assert(tScript)
	tScript.szType = "exp"
	tScript.nCount = nCount
	tScript.nEndTime = Timer.RealtimeSinceStartup() + Def.CellLife

	self:UpdateExpCell(tScript)
	self:InitCellPos(tScript)
end
-- exp end --------------------------------------------------

-- money beg --------------------------------------------------
function UIWidgetGetItemHintArea:OnGetMoney(tMoney)
	if MoneyOptCmp(tMoney, 0) > 0 then
		self:PushMoneyCell(tMoney)
	end
end
function UIWidgetGetItemHintArea:PushMoneyCell(tMoney)
	local tScript = self:GetItemCell("money")
	if tScript then
		tScript.tMoney = MoneyOptAdd(tScript.tMoney, tMoney)
		self:UpdateMoneyCell(tScript)
	else
		self:PushEvent({szType = "money", tMoney = tMoney})
	end

	self:StartCall()
end
function UIWidgetGetItemHintArea:UpdateMoneyCell(tScript)
	assert(tScript)
	local tMoney = tScript.tMoney
	assert(tMoney)

	-- label
	UIHelper.SetString(tScript.LabelItem, "")
	UIHelper.SetMoneyText(tScript.LabelItem, tMoney, 24, false, "金币：", cc.c4b(215, 246, 255, 255))

	-- icon
	local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgetItemIcon)
	assert(tItemScript)
	UIHelper.InitItemIcon_Money(tItemScript, tMoney)
	tItemScript:HideLabelCount()
end
function UIWidgetGetItemHintArea:AddMoneyCell(tMoney)
	self:MoveCell()

	local tScript = self:GetUnusedCell()
	assert(tScript)
	tScript.szType = "money"
	tScript.tMoney = tMoney
	tScript.nEndTime = Timer.RealtimeSinceStartup() + Def.CellLife

	self:UpdateMoneyCell(tScript)
	self:InitCellPos(tScript)
end
-- money end --------------------------------------------------

-- item beg --------------------------------------------------
function UIWidgetGetItemHintArea:OnLootEvent(event, nPlayerId, nItemId, nCount)
	local player = g_pClientPlayer
	if not player then return end

	if event == "LOOT_ITEM" then
		if  nPlayerId ==  player.dwID then
			self:PushItemCell(nItemId, nCount or 1)
		end
--[[
	elseif event == "BEGIN_ROLL_ITEM" then

		local dwFrame = GetLogicFrameCount()
		if not CreateLootRoll(dwFrame, arg0, arg1, arg2) then
			CreateLootRollMini(dwFrame, arg0, arg1, arg2)
		end
	elseif event == "DISTRIBUTE_ITEM" then
		local player = GetPlayer(arg0)
		local item = GetItem(arg1)
		if not (player and item) then
			return Log('[DISTRIBUTE_ITEM] Warning: cannot get player-' .. arg0 .. ' and item-' .. arg1)
		end
		local szItemName = GetItemNameByItem(item)
		local szFont = GetMsgFontString("MSG_ITEM")
		local szItemLink = MakeItemLink("["..szItemName.."]", szFont..GetItemFontColorByQuality(item.nQuality, true), arg1)

		if GetClientPlayer().dwID == player.dwID then
			playerName = g_tStrings.STR_NAME_YOU
			FireHelpEvent("OnGetItem", arg1)
			if IsBigBagFull() then
				FireHelpEvent("OnBagFull")
			end
		else
			playerName = player.szName
		end

		OutputMessage("MSG_ITEM", FormatString(g_tStrings.STR_DISTRIBUTE_ITEM, szItemLink, szFont, playerName), true)
	elseif event == "ROLL_ITEM" then
		local player = GetPlayer(arg0)
		local item = GetItem(arg1)
		if not (player and item) then
			return Log('[ROLL_ITEM] Warning: cannot get player-' .. arg0 .. ' and item-' .. arg1)
		end
		local playerName
		local szItemName = GetItemNameByItem(item)
		if GetClientPlayer().dwID == player.dwID then
			playerName = g_tStrings.STR_NAME_YOU
		else
			playerName = player.szName
		end
		local szMode = g_tStrings.LOOT_MODE_NEED
		if arg2 == ROLL_ITEM_CHOICE.GREED then
			szMode = g_tStrings.LOOT_MODE_GREED
		end
		local szFont = GetMsgFontString("MSG_ITEM")
		local szItemLink = MakeItemLink("["..szItemName.."]", szFont..GetItemFontColorByQuality(item.nQuality, true), arg1)
		OutputMessage("MSG_ITEM", FormatString(g_tStrings.STR_PLAYER_ROLL_POINTS_RICH, playerName, szFont, szItemLink, szMode, arg3), true)
	elseif event == "CANCEL_ROLL_ITEM" then
		local player = GetPlayer(arg0)
		local item = GetItem(arg1)
		if not (player and item) then
			return Log('[CANCEL_ROLL_ITEM] Warning: cannot get player-' .. arg0 .. ' and item-' .. arg1)
		end
		local playerName
		local szItemName = GetItemNameByItem(item)
		if GetClientPlayer().dwID == player.dwID then
			playerName = g_tStrings.STR_NAME_YOU
		else
			playerName = player.szName
		end
		local szFont = GetMsgFontString("MSG_ITEM")
		local szItemLink = MakeItemLink("["..szItemName.."]", szFont..GetItemFontColorByQuality(item.nQuality, true), arg1)
		OutputMessage("MSG_ITEM", FormatString(g_tStrings.STR_PLAYER_CANCEL_ROLL_RICH, playerName, szFont, szItemLink), true)

	elseif event == "OPEN_DOODAD" then
		--- arg0~arg1: dwDoodadID, dwPlayerID
		if arg1 == UI_GetClientPlayerID() then
			local clientTeam = GetClientTeam()
			if clientTeam and clientTeam.nLootMode == PARTY_LOOT_MODE.BIDDING then
				OpenGoldTeamLootList(arg0)
			else
				OpenLootList(arg0)
			end
		end
--]]
	end
end
function UIWidgetGetItemHintArea:PushItemCell(nItemId, nCount)
	local item = GetItem(nItemId) assert(item, "fail to get item by id: " .. tostring(nItemId))

	SoundMgr.PlayItemSound(item.nUiId)

	local tScript = self:GetItemCell("item", item.dwTabType, item.dwIndex)
	if tScript then
		tScript.nCount = tScript.nCount + nCount
		self:UpdateItemCell(tScript)
	else
		self:PushEvent({
			szType = "item",
			nItemId = nItemId,
			dwTabType = item.dwTabType,
			dwIndex = item.dwIndex,
			nCount = nCount,
		})
	end

	self:StartCall()
end
function UIWidgetGetItemHintArea:UpdateItemCell(tScript)
	assert(tScript)
	local nItemId = tScript.nItemId
	local nCount = tScript.nCount

	local item = GetItem(nItemId) assert(item, "fail to get item by id: " .. nItemId)

	-- label
	UIHelper.RemoveAllChildren(tScript.LabelItem)
	local szItemName = ItemData.GetItemNameByItem(item)
	local szText = UIHelper.GBKToUTF8(szItemName)
	UIHelper.SetString(tScript.LabelItem, szText .. " x" .. nCount)
	-- icon
	local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgetItemIcon)
	assert(tItemScript)
	UIHelper.InitItemIcon(tItemScript, item, 1)
	tItemScript:HideLabelCount()
end
function UIWidgetGetItemHintArea:AddItemCell(nItemId, nCount, dwTabType, dwIndex)
	assert(nItemId)
	self:MoveCell()

	local tScript = self:GetUnusedCell()
	assert(tScript)
	tScript.szType = "item"
	tScript.nItemId = nItemId
	tScript.nCount = nCount
	tScript.dwTabType = dwTabType
	tScript.dwIndex = dwIndex
	tScript.nEndTime = Timer.RealtimeSinceStartup() + Def.CellLife

	self:UpdateItemCell(tScript)
	self:InitCellPos(tScript)
end

-- item end --------------------------------------------------

-- fishing --------------------------------------------------

local function GetFishInfo(dwID)
    local tFishInfo = Table_GetAllFishInfo()
    for _, v in pairs(tFishInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end
function UIWidgetGetItemHintArea:OnGetFish(tFish, nExp)
	if nExp and nExp > 0 then
		self:PushOtherCell(CurrencyType.FishExp, nExp)
	end

	--在家园里钓鱼能收到LOOT_ITEM事件，所以在家园里不单独显示鱼的Tips
	if MapHelper.GetMapID() == 565 then
		return
	end

	for _, v in ipairs(tFish) do
		local nFishIndex = v.nFishIndex or 0
		local nCount = v.num or 0
		if nFishIndex > 0 and nCount > 0 then
			local tInfo = GetFishInfo(nFishIndex)
			if not tInfo.bHideBook then
				self:PushFishCell(nFishIndex, nCount)
			end
		end
	end
end
function UIWidgetGetItemHintArea:PushFishCell(nFishIndex, nCount)
	local tScript = self:GetItemCell("fish", nFishIndex)
	if tScript then
		tScript.nCount = tScript.nCount + nCount
		self:UpdateFishCell(tScript)
	else
		self:PushEvent({
			szType = "fish",
			nFishIndex = nFishIndex,
			nCount = nCount,
		})
	end

	self:StartCall()
end
function UIWidgetGetItemHintArea:UpdateFishCell(tScript)
	assert(tScript)
	local nFishIndex = tScript.nFishIndex
	local nCount = tScript.nCount

	local tInfo = GetFishInfo(nFishIndex) assert(tInfo, "fail to get fish by id: " .. nFishIndex)

	-- label
	UIHelper.RemoveAllChildren(tScript.LabelItem)
	local szText = UIHelper.GBKToUTF8(tInfo.szName)
	UIHelper.SetString(tScript.LabelItem, szText .. " x" .. nCount)
	-- icon
	local tItemScript = UIHelper.AddItemIconPrefab_Small(tScript.WidgetItemIcon)
	assert(tItemScript)
	tItemScript:OnInitWithIconID(tInfo.dwIconID, tInfo.nQuality)
	tItemScript:HideLabelCount()
end
function UIWidgetGetItemHintArea:AddFishCell(nFishIndex, nCount)
	assert(nFishIndex)
	self:MoveCell()

	local tScript = self:GetUnusedCell()
	assert(tScript)
	tScript.szType = "fish"
	tScript.nFishIndex = nFishIndex
	tScript.nCount = nCount
	tScript.nEndTime = Timer.RealtimeSinceStartup() + Def.CellLife

	self:UpdateFishCell(tScript)
	self:InitCellPos(tScript)
end

-- fishing end --------------------------------------------------

function UIWidgetGetItemHintArea:PushEvent(tNewEvent)
    assert(tNewEvent)
    -- 事件合并
    for _, tOldEvent in ipairs(self.m.tEventArr) do
        if tOldEvent.szType == tNewEvent.szType then
            -- 若有相同类型的事件，检查是否可以合并
            local bMerged = false

            if tNewEvent.szType == "item" then
                -- 道具类型和index相同，则合并
                if tNewEvent.dwTabType == tOldEvent.dwTabType and tNewEvent.dwIndex == tOldEvent.dwIndex then
                    tOldEvent.nCount = tOldEvent.nCount + tNewEvent.nCount
                    bMerged          = true
                end
            elseif tNewEvent.szType == "fish" then
                -- 钓鱼的鱼的index相同，则合并
                if tNewEvent.nFishIndex == tOldEvent.nFishIndex then
                    tOldEvent.nCount = tOldEvent.nCount + tNewEvent.nCount
                    bMerged          = true
                end
            elseif tNewEvent.szType == "money" then
                -- 货币直接合并
                tOldEvent.tMoney = MoneyOptAdd(tOldEvent.tMoney, tNewEvent.tMoney)
                bMerged          = true
            else
                -- 其他类型的事件，约定仅有nCount差异，可直接合并
                tOldEvent.nCount = tOldEvent.nCount + tNewEvent.nCount
                bMerged          = true
            end

            if bMerged then
                -- 事件合并成功，可直接返回
                return
            end
        end
    end

    -- 无同类事件, 入队
    table.insert(self.m.tEventArr, tNewEvent)
end

function UIWidgetGetItemHintArea:MoveCell()
	-- 所有cell上移
	for _, tScript in ipairs(self.m.tScriptArr) do
		if not tScript.bUnused then
			local cell = tScript._rootNode
			local y = cell:getPositionY()
			cell:setPositionY(y + 52)
		end
	end
end

function UIWidgetGetItemHintArea:GetItemCell(szType, dwTabType, dwIndex)
	for _, tScript in ipairs(self.m.tScriptArr) do
		if not tScript.bUnused and tScript.szType == szType then
			if dwTabType then
				if szType == "item" then
					if tScript.dwTabType == dwTabType and tScript.dwIndex == dwIndex then
						return tScript
					end
				elseif szType == "fish" then
					if tScript.nFishIndex == dwTabType then
						return tScript
					end
				end
			else
				return tScript
			end
		end
	end
end

function UIWidgetGetItemHintArea:GetUnusedCell()
	for _, tScript in ipairs(self.m.tScriptArr) do
		if tScript.bUnused then
			tScript.bUnused = nil
			UIHelper.SetVisible(tScript._rootNode, true)
			return tScript
		end
	end
	-- 新创建
	local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetGetItemHint, self._rootNode)
	assert(tScript)
	table.insert(self.m.tScriptArr, tScript)
	return tScript
end

function UIWidgetGetItemHintArea:RecycleCell(tScript)
	assert(tScript)
	tScript.bUnused = true
	UIHelper.SetVisible(tScript._rootNode, false)
end


return UIWidgetGetItemHintArea