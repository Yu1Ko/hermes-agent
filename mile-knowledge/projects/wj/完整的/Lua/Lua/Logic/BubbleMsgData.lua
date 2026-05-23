
BubbleMsgData = BubbleMsgData or {
	className = "BubbleMsgData",
	Def = {
		BarTime = 5,
	}
}

local self = BubbleMsgData

-- 白名单注册表：{ [szViewKey] = { [szType] = true, ... }, ... }
-- 任一白名单激活时，只允许白名单内的 szType 通过
local tWhiteListRegistry = {
	["PanelFBShow"] = {
		["NewAddFellowshipTips"] = true,	-- 好友申请
		["TeamBuildingApplyTips"] = true,	-- 招募入队申请
		["TongInviteTips"] = true,			-- 邀请入帮
		["MapQueueTips"] = true,			-- 地图排队中
		["ApprenticeInviteTip"] = true,		-- 收徒申请
		["MentorInviteTip"] = true,			-- 拜师申请
		["AddFeudInvite"] = true,			-- 宿敌模式申请
		["AuctionOpening"] = true,			-- 掉落分配
		["DungeonLive"] = true,				-- 副本观战观众管理
		["refresh_copy"] = true,		-- 副本重置
	},
}

-- 白名单激活条件：szViewKey → VIEW_ID
local tWhiteListTrigger = {
	["PanelFBShow"] = VIEW_ID.PanelFBShow,
}

-- 检查 szType 是否被当前活跃的白名单过滤（任一白名单激活且该类型不在其中则返回 true）
local function IsTypeFiltered(szType)
	for szKey, _ in pairs(tWhiteListTrigger) do
		if UIMgr.IsViewOpened(tWhiteListTrigger[szKey]) then
			local tList = tWhiteListRegistry[szKey]
			if tList and not tList[szType] then
				return true
			end
		end
	end
	return false
end

function BubbleMsgData.Init()
	self.m = {}
	self.m.tMsgArr = {}
end

function BubbleMsgData.UnInit()
	self.StopUpdate()
	self.m = nil
end

--[[
tMsg = {
	szType = "EquipDurabilityTips", 		-- 类型(用于排重)
	szTitle = "装备耐久度不足, 需要XXXX",	 -- 显示在信息列表项中的标题, 支持回调函数(返回相应文本, 下次调用间隔)
	szBarTitle = "装备耐久度不足", 			 -- 显示在小地图旁边的气泡栏的短标题(若与szTitle一样, 可以不填)
	nBarTime = 5, 							-- 显示在气泡栏的时长, 单位为秒
	szIcon = "UIAtlas2_XXXX.png", 			-- 显示在信息列表项中的SpriteFrameName
	szMainCityIcon = "UIAtlas2_XXXX.png"	-- 主界面图标(需要设置bShowMainCityIcon)
	szContent = "详细内容文本",				 -- 支持富文本, 支持回调函数(返回相应文本, 下次调用间隔)
	szAction = "PanelGM|222|333", 			-- 点击后执行的动作(打开界面的ViewID名称|参数1|参数2), 支持回调函数
	bCanRemove = true, 						-- 是否可以手动删除, 支持回调函数(返回是否可以手动删除)
	bMultiMsg = false						-- 是否显示多人消息，需要传入szSrcPlayerName
	bShowMainCityIcon = false				-- 是否在主界面显示图标
	nLifeTime = 60, 						-- 存在时长, 单位为秒
	nPriority = 10, 						-- 排序优先级, 值越大级别越高
	nPosIndex = 1,							-- 装备posINDEX,"EquipDurabilityWarning"类型
	nRank = 1,								-- 切场景排队等待人数
	nEndTime = nLifeTime + GetCurrentTime(),-- 结束时长, 单位为秒
	fnAutoClose = fnAutoClose				-- 当返回True时自动从气泡队列中删除
}
--]]
function BubbleMsgData.PushMsg(tMsg)
	assert(tMsg)
	local arr = self.m.tMsgArr
	assert(arr)

	-- 读配置
	self.FillWithConfig(tMsg)

	-- 排重
	local tOld = self.GetMsgByType(tMsg.szType)
	if tOld and not tOld.bRemove then
		-- 刷新旧消息

		for k, v in pairs(tMsg) do
			tOld[k] = v
		end
	else
		table.insert(arr, tMsg)
	end

	-- sort
	Global.SortStably(arr, function (a, b)
		local nA = a and a.nPriority or 0
		local nB = b and b.nPriority or 0
		return nA >= nB
	end)

	local nNow = Timer.RealtimeSinceStartup()
	if tMsg.nLifeTime and tMsg.nLifeTime > 0 then
		tMsg.nLifeEndTime = nNow + tMsg.nLifeTime
	end

	BubbleMsgData.SetHasRedPoint(true)

	Event.Dispatch(EventType.BubbleMsg, tMsg)

	if nNow - (self.nLastPlayTime or 0) > 0.3 then
		self.nLastPlayTime = nNow
	end


	self:StartUpdate()
end

function BubbleMsgData.PushMsgWithType(szType, tbMgr, szSrcPlayerName)
	if IsTypeFiltered(szType) then
		return
	end

	local tbGetMgr = clone(UIBubbleMsgTab[szType])
	if not tbGetMgr then
		LOG.ERROR("PushMsgWithType Error: %s", tostring(szType))
		return
	end
	for key, value in pairs(tbMgr) do
		tbGetMgr[key] = value
	end
	if tbGetMgr.bMultiMsg then
		tbGetMgr.szType = szType..szSrcPlayerName
	end
	BubbleMsgData.PushMsg(tbGetMgr)
end

function BubbleMsgData.RemoveMsg(szType)
	local tRemoveMsg = self.GetMsgByType(szType)
	if tRemoveMsg then
		tRemoveMsg.bRemove = true
		local arr = self.m.tMsgArr
		assert(arr)
		for i = #arr, 1, -1 do
			local tMsg = arr[i]
			if tMsg.bRemove and tMsg.szType == szType then
				table.remove(arr, i)
				break
			end
		end
	end
	Event.Dispatch(EventType.BubbleMsgRemove, szType, tRemoveMsg and tRemoveMsg.bShowTimelyHintBar or false)
end

function BubbleMsgData.RemoveMsgWithSrcPlayerName(szType, szSrcPlayerName)
	if not szSrcPlayerName then
		return
	end
	szType = szType..szSrcPlayerName
	local tMsg = self.GetMsgByType(szType)
	if not tMsg then
		LOG.ERROR("RemoveMsg Error: Can Not Found %s", tostring(szType))
		return
	end
	self.RemoveMsg(szType)
end

function BubbleMsgData.GetMsgByType(szType)
	local arr = self.m and self.m.tMsgArr
	assert(arr)
	for _, v in pairs(arr) do
		if not v.bRemove and v.szType == szType then
			return v
		end
	end
end

function BubbleMsgData.StartUpdate()
	if not self.m.nCallId then
		self.m.nCallId = Timer.AddCycle(self, 0.3, self.OnUpdate)
	end
end

function BubbleMsgData.StopUpdate()
	if self.m.nCallId then
		Timer.DelTimer(self, self.m.nCallId)
		self.m.nCallId = nil
	end
end

function BubbleMsgData.OnUpdate()
	local nTime = Timer.RealtimeSinceStartup()
	local nCurrentTime = GetCurrentTime()
	local arr = self.m.tMsgArr
	assert(arr)
	local bHaveRemove = false
	for i = #arr, 1, -1 do
		local tMsg = arr[i]
		-- 标记已过期的消息
		if tMsg.nLifeEndTime and tMsg.nLifeEndTime < nTime then
			tMsg.bRemove = true
		end

		-- 检测是否触发自动删除
		if not tMsg.bRemove and tMsg.fnAutoClose and tMsg.fnAutoClose() then
			tMsg.bRemove = true
		end

		-- 移除被标记的消息
		if tMsg.bRemove then
			table.remove(arr, i)
			bHaveRemove = true
		end
	end

	if bHaveRemove then
		Event.Dispatch(EventType.BubbleMsgRemove)
	end

	if #arr == 0 then
		self:StopUpdate()
	end
end

function BubbleMsgData.ClearTimelyHintMsg()
	local bClear = false
	if not self.m or not self.m.tMsgArr then
		return bClear
	end

	for index, tMsg in ipairs(self.m.tMsgArr) do
		if tMsg.bShowTimelyHintBar then
			bClear = true
			self.m.tMsgArr[index].bShowTimelyHintBar = nil
		end
	end
	return bClear
end

function BubbleMsgData.GetMsgArr()
	local arr = self.m and self.m.tMsgArr or {}
	local tFiltered = {}
	for _, v in ipairs(arr) do
		if not IsTypeFiltered(v.szType) then
			table.insert(tFiltered, v)
		end
	end
	return tFiltered
end

function BubbleMsgData.GetMsgCount(bIgnoreIcon)
	local nCount = 0
	local arr = self.m and self.m.tMsgArr or {}
	for _, v in ipairs(arr) do
		if not IsTypeFiltered(v.szType) then
			if bIgnoreIcon then
				if not v.bShowMainCityIcon then
					nCount = nCount + 1
				end
			else
				nCount = nCount + 1
			end
		end
	end
	return nCount
end

function BubbleMsgData.OpenMsgPanel()
	UIMgr.Open(VIEW_ID.PanelBubbleInformation)
end

function BubbleMsgData.Reset()
	self.UnInit()
	self.Init()
end

function BubbleMsgData.FillWithConfig(tMsg)
	assert(tMsg)
	if not tMsg.nID then return end

	local tCfg = UIBubbleMsgTab[tMsg.nID]
	assert(tCfg, "fail to get bubble msg config by id: " .. tMsg.nID)

	for k, v in pairs(tCfg) do
		local val = tMsg[k]
		if val == nil and v ~= "" then
			tMsg[k] = v
		end
	end
end

function BubbleMsgData.SetHasRedPoint(bValue)
	if not bValue then
		self.bHasRedPoint = false
		Event.Dispatch("BubbleRedPointUpdate")
		return
	end

	local script = UIMgr.GetViewScript(VIEW_ID.PanelBubbleInformation)
	if script then
		return
	end

	self.bHasRedPoint = true
end

function BubbleMsgData.GetHasRedPoint()
	return self.bHasRedPoint
end


function BubbleMsgData.SetGoldLimitValue(nLimitType, nLimitValue)
	self.nLimitType  = nLimitType
	self.nLimitValue = nLimitValue
end

function BubbleMsgData.GetGoldLimitState()
	if self.nLimitType and self.nLimitValue and self.nLimitValue > 0 then
		return true
	end
	return false
end

Event.Reg(self, EventType.OnRoleLogin, function()
	self.nLimitType  = nil
	self.nLimitValue = nil
end)