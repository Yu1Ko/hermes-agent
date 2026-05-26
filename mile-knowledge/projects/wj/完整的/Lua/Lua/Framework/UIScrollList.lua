-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIScrollList
-- Date: 2023-01-13
-- Desc: 滚动列表
-- ---------------------------------------------------------------------------------

UIScrollList = { className = "UIScrollList" }
local M = UIScrollList
M.__index = M

local _tCellAnchor = cc.p(0, 1)
local _tZeroAnchor = cc.p(0, 0)
local _nMinPosOffset = 0.1
local _nDragSpeedGatherCount = 5
local _nSpeedFactor = 1.5
local _nMaxDragSpeed = 10
local _nFriction = 0.07
local _nReboundScale = 0.25
local _nReboundSpeedFactor = 0.3 -- 值越小速度越慢
local _nDragThreshold = 5
local _nDragThreshold2 = _nDragThreshold * _nDragThreshold
local _nScrollBarThick = 5
local _nScrollBarMaxOpacity = 128
local _nScrollBarOpacitySpeed = 8
local _fnAbs, _fnMin, _fnMax, _fnClamp = math.abs, math.min, math.max, cc.clampf

-- 创建列表对象
-- tArgs = {
--		listNode = node, -- 列表节点对象, 一般为layout或其子类（注意预制里Layout里的Type和Resize Mode都要设置为None）
-- 		bHorizontal = true, -- 不填就是竖向
--		bMinPosAlign = true, -- 优先对齐可视窗口和子节点的最小位置(例如自左向右布局中就是左对齐)
-- 		nSpace = 0, -- Cell间距
-- 		bSlowRebound = true, -- 不填就是立刻回弹
--		fnGetCellType = function(nIndex) return "XXXX" end, -- 填PREFAB_ID.XXXX中的XXXX
--		fnUpdateCell = function(cell, nIndex) end, -- 刷新cell的显示内容
-- }
function UIScrollList.Create(tArgs)
	assert(tArgs)
	assert(tArgs.listNode)
	assert(tArgs.fnGetCellType)
	assert(tArgs.fnUpdateCell)

	-- 默认值
	tArgs.nSpace = tArgs.nSpace or 0
	tArgs.nReboundScale = tArgs.nReboundScale or _nReboundScale

	local self = {}
	self.tArgs = tArgs
	setmetatable(self, M)

	self:_Init()

	return self
end

function UIScrollList:Destroy()
	self:_UnInit()
	self.tArgs = nil
end

function UIScrollList:ScrollToIndex(nIndex, nSpeed)
	if self.m.nCellTotal > 0 then
		nIndex = _fnMin(self.m.nCellTotal, _fnMax(1, nIndex))
		self.m.nModeOfScrollTo = 1
		self.m.nIndexOfScrollTo = nIndex
		self.m.nSpeedOfScrollTo = nSpeed or self.m.nMaxCellSize
	end
end

function UIScrollList:ScrollToIndexImmediately(nIndex)
	if self.m.nCellTotal > 0 then
		nIndex = _fnMin(self.m.nCellTotal, _fnMax(1, nIndex))
		self:ResetWithStartIndex(self.m.nCellTotal, nIndex)
	end
end

-- 增删指定index上的cell
function UIScrollList:ReloadWithStartIndex(nCellTotal, nStartIndex)
	local nIndex = _fnMax(nStartIndex, self.m.nMinIndexOfCells)
	while self.m.nMaxIndexOfCells >= nIndex do
		self:_RemoveMaxIndex()
	end

	self:SetCellTotal(nCellTotal)
end

function UIScrollList:Reload(nCellTotal)
	self:ReloadWithStartIndex(nCellTotal, 1)
end

-- 直接从指定index开始加载
function UIScrollList:ResetWithStartIndex(nCellTotal, nStartIndex)
	assert(nStartIndex > 0)

	local tCells = self.m.tCells
	if tCells then
		repeat
			local k = next(tCells)
			if not k then break end
			self:_RemoveCell(k)
		until false
	end
	self:_InitData()
	self:UpdateContentPos()
	if nCellTotal > 0 then
		local nIndex = _fnMin(nStartIndex, nCellTotal)
		self.m.nMinIndexOfCells = nIndex
		self.m.nMaxIndexOfCells = nIndex - 1
	end

	self:SetCellTotal(nCellTotal)
end

function UIScrollList:Reset(nCellTotal)
	self:ResetWithStartIndex(nCellTotal, 1)
	self:ResetDragState()
end

function UIScrollList:UpdateCell(nIndex)
	local cell = self.m.tCells[nIndex]
	if cell then
		self.tArgs.fnUpdateCell(cell, nIndex)
	end
end

function UIScrollList:UpdateAllCell()
	for k, _ in pairs(self.m.tCells) do
		self:UpdateCell(k)
	end
end

function UIScrollList:SetCellTotal(nTotal)
	assert(nTotal >= 0)
	self.m.nCellTotal = nTotal

	local nIndex = _fnMax(nTotal, self.m.nMinIndexOfCells)
	while self.m.nMaxIndexOfCells >= nIndex do
		self:_RemoveMaxIndex()
	end

	nIndex = _fnMax(nTotal, 1)
	if self.m.nMinIndexOfCells > nIndex then
		self.m.nMinIndexOfCells = nIndex
		self.m.nMaxIndexOfCells = nIndex - 1
	end

	self:_CheckRange()
end

function UIScrollList:UpdateListSize()
	assert(self.m)
	local list = self.tArgs.listNode
	assert(list)
	local tSize = list:getContentSize()
	self.m.tListSize = tSize
	self.m.nListSize = self.tArgs.bHorizontal and tSize.width or tSize.height
end

function UIScrollList:GetIndexRangeOfLoadedCells()
	return self.m.nMinIndexOfCells, self.m.nMaxIndexOfCells
end

function UIScrollList:SetScrollBarEnabled(bEnable)
	if not self.m.bScrollBarEnabled == not bEnable then return end
	self.m.bScrollBarEnabled = bEnable

	self:_UnInitScrollBar()

	if bEnable then
		self:_InitScrollBar()
	end
end

function UIScrollList:SetNestingEnabled(bEnable)
	self.m.bNestingEnabled = bEnable
end

function UIScrollList:OnReload()
	-- 用于调试
end

function UIScrollList:GetSizeOfCells()
	return self.m.nMaxPosOfCells - self.m.nMinPosOfCells
end

function UIScrollList:GetMaxVisableCellIndex()
	local nMaxVisableIndex = -1
	local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
	for nIndex, cell in pairs(self.m.tCells) do
		local nMinPos, nMaxPos = self:_GetRangeOfTargetCell(cell)
		if nMaxPos < nMaxPosOfView and nMaxVisableIndex < nIndex then
			nMaxVisableIndex = nIndex
		end
	end
	return nMaxVisableIndex
end








-- 内部函数 -----------------------------------------------------------

function UIScrollList:_OnUpdate()
	local nTime = GetTickCount()
	self.m.nDeltaTime = nTime - self.m.nTickTime
	self.m.nTickTime = nTime
	self:_UpdateStopScroll()
	self:_Scroll()
	self:_CheckRange()
	self:_UpdateScrollBar()
end

function UIScrollList:_Init()
	self.m = {}
	self.m.tCells = {}
	self:_InitData()

	self:UpdateListSize()
	self:_InitContentNode()
	self:_InitCellPool()

	-- touch
	self:_BindUIEvent()

	-- 运行期
	self.m.nCallID = Timer.AddFrameCycle(self, 1, function ()
		self:_OnUpdate()
	end)
end

function UIScrollList:_UnInit()
	if not self.m then return end

	if self.m.nCallID then
		Timer.DelTimer(self, self.m.nCallID)
		self.m.nCallID = nil
	end

	local tCells = self.m.tCells
	if tCells then
		repeat
			local k = next(tCells)
			if not k then break end
			self:_RemoveCell(k)
		until false
		self.m.tCells = nil
	end


	self:_UnInitCellPool()
	self:_UnInitContentNode()

	Timer.DelAllTimer(self)
	Event.UnRegAll(self)

	self.m = nil
end

function UIScrollList:_InitData()
	self.m.nPosOfContent = 0 -- 左上角位置
	self.m.nSpeed = 0
	self.m.nModeOfScrollTo = 0

	self.m.nTickTime = 0
	self.m.nDeltaTime = 0

	self.m.tDragDistDelta = {}
	self.m.tDragTimeDelta = {}

	self.m.nMinPosOfCells = 0
	self.m.nMaxPosOfCells = self.tArgs.nSpace
	self.m.nMinIndexOfCells = 1
	self.m.nMaxIndexOfCells = 0

	self.m.nMaxCellSize = 0

	self.m.nLastPosOfScrollBar = 0

	self.m.nCellTotal = 0
end

function UIScrollList:_InitContentNode()
	local contentNode = cc.Node:create()
	assert(contentNode)
	self.m.contentNode = contentNode
	contentNode:setName("Content")
	self.tArgs.listNode:addChild(contentNode)
	contentNode:setAnchorPoint(_tZeroAnchor)
	contentNode:setCascadeOpacityEnabled(true)
	UIHelper.SetCombinedBatchEnabled(contentNode, true)
	self:UpdateContentPos()
end
function UIScrollList:_UnInitContentNode()
	if self.m.contentNode then
		self.m.contentNode:removeFromParent(true)
		self.m.contentNode = nil
	end
end

function UIScrollList:_InitCellPool()
	self.m.tCellPool = {}
end

function UIScrollList:_UnInitCellPool()
	if self.m.tCellPool then
		for _, tCellArr in pairs(self.m.tCellPool) do
			for _, cell in ipairs(tCellArr) do
				if cell.OnUnInit then
					cell:OnUnInit()
				end
			end
		end
		self.m.tCellPool = nil
	end
end

function UIScrollList:_BindUIEvent()
	local list = self.tArgs.listNode
	list:setTouchEnabled(true)
	list:setClippingEnabled(true)

	UIHelper.BindUIEvent(list, EventType.OnTouchBegan, function(node, x, y)
		self:_OnTouchBegan(node, x, y)
		Event.Dispatch(EventType.HideAllHoverTips)
		Event.Dispatch(EventType.OnUIScrollListTouchBegan, x, y, self)
	end)
	UIHelper.BindUIEvent(list, EventType.OnTouchMoved, function(node, x, y)
		self:_OnTouchMoved(node, x, y)
		Event.Dispatch(EventType.OnUIScrollListTouchMove, x, y)
	end)
	UIHelper.BindUIEvent(list, EventType.OnTouchEnded, function(node, x, y)
		self:_OnTouchEnded(node, x, y)
		Event.Dispatch(EventType.OnUIScrollListTouchEnd, x, y)
	end)
	UIHelper.BindUIEvent(list, EventType.OnTouchCanceled, function(node, x, y)
		self:_OnTouchCanceled(node)
		Event.Dispatch(EventType.OnUIScrollListTouchEnd, x, y)
	end)
	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		Timer.AddFrame(self, 2, function()
			self:UpdateListSize()
			self:UpdateContentPos()
		end)
	end)
	Event.Reg(self, EventType.OnWindowsMouseWheelForScrollList, function(nDelta, bHandled)
		if bHandled then return end

		local list = self.tArgs.listNode
		if list.getMouseIn and not list:getMouseIn() then
			return
		end

		if list.isEnabled and not list:isEnabled() then
			return
		end

		if not UIHelper.GetHierarchyVisible(list) then
			return
		end

		if self.m.bDragFailed then
			return
		end

		if not self:_IsCanDrag() then
			self.m.bDragFailed = true
			return
		end

		local nMaxOutside = self.m.nListSize * 0.3 -- 最大移出距离
		nDelta = _fnClamp(nDelta, -nMaxOutside, nMaxOutside)

		self.m.bDragging = true
		self:_SetContentPosWithOffset(nDelta, true)
		self:_GatherDragDelta(nDelta)

		self.m.nSpeed = 0
		self.m.nStopScrollWaitFrameCount = 10
		cc.utils:setMouseWheelHandled(true)

		Event.Dispatch(EventType.OnUIScrollListMouseWhell)
	end)
end

function UIScrollList:_OnTouchBegan(node, x, y)
	y = -y

	self.m.nTouchBeganX, self.m.nTouchBeganY = x, y
	self.m.bDragging = false
	self.m.bDragFailed = false
	self.m.tDragDistDelta = {}
	self.m.tDragTimeDelta = {}
	self.m.nSpeed = 0
	self.m.nModeOfScrollTo = 0
end

function UIScrollList:_OnTouchMoved(node, x, y)
	y = -y

	if self.m.bDragFailed then
		return
	end

	-- 不允许拖动
	if self.m.bDragEnabled ~= nil and not self.m.bDragEnabled then
		return
	end

	if not self:_IsCanDrag() then
		self.m.bDragFailed = true
		return
	end

	if not self.m.bDragging and self.m.nTouchBeganX and self.m.nTouchBeganY then
		local dx = x - self.m.nTouchBeganX
		local dy = y - self.m.nTouchBeganY
		local dx2 = dx * dx
		local dy2 = dy * dy
		if dx2 + dy2 > _nDragThreshold2 then
			-- 支持嵌套时, 通过移动方向判断是否拖动失败
			if self.m.bNestingEnabled then
				if self.tArgs.bHorizontal then
					if dy2 > dx2 then
						self.m.bDragFailed = true
					end
				else
					if dx2 > dy2 then
						self.m.bDragFailed = true
					end
				end
			end
			if not self.m.bDragFailed then
				-- 成功触发拖动
				self.m.bDragging = true
				self.m.nLastTouchMovedX = self.m.nTouchBeganX
				self.m.nLastTouchMovedY = self.m.nTouchBeganY
			end
		end
	end

	if self.m.bDragging and self.m.nLastTouchMovedX and self.m.nLastTouchMovedY then
		local dx = x - self.m.nLastTouchMovedX
		local dy = y - self.m.nLastTouchMovedY
		self.m.nLastTouchMovedX = x
		self.m.nLastTouchMovedY = y

		local nDrag = self.tArgs.bHorizontal and dx or dy
		self:_SetContentPosWithOffset(nDrag)
		self:_GatherDragDelta(nDrag)
	end

end

function UIScrollList:_OnTouchEnded(node, x, y)
	y = -y

	if self.m and self.m.bDragging then
		self.m.nSpeed = self:_CalcDragSpeed()
		self.m.bDragging = false
		self.m.tDragDistDelta = {}
		self.m.tDragTimeDelta = {}
	end

end

function UIScrollList:_OnTouchCanceled(node)
	if self.m and self.m.bDragging then
		self.m.nSpeed = self:_CalcDragSpeed()
		self.m.bDragging = false
		self.m.tDragDistDelta = {}
		self.m.tDragTimeDelta = {}
	end
end

-- cell左上角的位置
function UIScrollList:_SetCellPos(cell, nPos)
	cell:setAnchorPoint(_tCellAnchor)
	if self.tArgs.bHorizontal then
		cell:setPosition(nPos, 0)
	else
		cell:setPosition(0, -nPos)
	end
end

function UIScrollList:_GetCellPos(cell)
	local x, y = 0, 0
	if safe_check(cell) then
		x, y = cell:getPosition()
	end
	return self.tArgs.bHorizontal and x or -y
end

function UIScrollList:_LimitOutsideOffset(nOffset)
	local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
	local nMaxOutside = self.m.nListSize * 0.3 -- 最大移出距离
	local nAbsOffset = _fnAbs(nOffset)

	-- 根据移出距离进一步减速
	if nOffset < 0 then
		if nMaxPosOfView > self.m.nMaxPosOfCells then
			local nDelta = nMaxPosOfView - self.m.nMaxPosOfCells
			nOffset = nOffset * _fnMax(0, nMaxOutside - nDelta) / nMaxOutside
		end
	else
		if nMinPosOfView < self.m.nMinPosOfCells then
			local nDelta = self.m.nMinPosOfCells - nMinPosOfView
			nOffset = nOffset * _fnMax(0, nMaxOutside - nDelta) / nMaxOutside
		end
	end

	return nOffset
end

function UIScrollList:_SetContentPosWithOffset(nOffset, bLimit)
	if bLimit == nil or bLimit == true then
		nOffset = self:_LimitOutsideOffset(nOffset)
	end

	self.m.nPosOfContent = self.m.nPosOfContent + nOffset
	self:UpdateContentPos()
end

function UIScrollList:UpdateContentPos()
	if self.tArgs.bHorizontal then
		self.m.contentNode:setPosition(self.m.nPosOfContent, self.m.tListSize.height)
	else
		self.m.contentNode:setPosition(0, self.m.tListSize.height - self.m.nPosOfContent)
	end

	Event.Dispatch(EventType.OnUIScrollListScroll, self)
end

function UIScrollList:_Scroll()
	-- 拖动时, 跳过
	if self.m.bDragging then
		return
	end

	-- ScrollTo
	if self.m.nModeOfScrollTo ~= 0 then
		self:_ScrollTo()
		return
	end

	local nSpeed = self.m.nSpeed
	if nSpeed ~= 0 then
		self:_CheckRange() -- 边界减速前要先调一次_CheckRange，否则低帧率下有时会因为Range数据不匹配导致Limit后速度降为0
		nSpeed = self:_LimitOutsideOffset(nSpeed) -- 边界减速
		-- 外力滚动
		self:_SetContentPosWithOffset(nSpeed * self.m.nDeltaTime) -- 混合时间增量, 避免帧率变化导致的抖动

		local nAbsSpeed = _fnAbs(nSpeed)
		local nFriction = _nFriction * self.m.nDeltaTime
		if nAbsSpeed > _nFriction then
            if nSpeed < 0 then
                nSpeed = nSpeed + _nFriction
            else
                nSpeed = nSpeed - _nFriction
            end
		elseif nAbsSpeed > _nMinPosOffset then
			nSpeed = nSpeed * (1 - self.tArgs.nReboundScale)
		else
			nSpeed = 0
		end
		self.m.nSpeed = nSpeed

	else
		-- 回弹修复
		local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
		local nMaxOutside = self.m.nListSize * 0.3
		local nDelta
		if self.m.nMinIndexOfCells == 1 and nMinPosOfView < self.m.nMinPosOfCells then
			nDelta = nMinPosOfView - self.m.nMinPosOfCells ---- 头部回弹
		elseif self.m.nMaxIndexOfCells == self.m.nCellTotal and nMaxPosOfView > self.m.nMaxPosOfCells then
			-- 尾部回弹 需要考虑内容填不满列表的情况, (nMinIndex > 1)的判断是为了自动下拉触发向前加载
			if self.m.nMinIndexOfCells > 1 or nMinPosOfView > self.m.nMinPosOfCells then
				nDelta = nMaxPosOfView - self.m.nMaxPosOfCells
			end
		end

		if nDelta then
			local nFinalOffset
			if self.tArgs.bSlowRebound then
				local nOffset = nDelta * _fnMax(0, nMaxOutside + _fnAbs(nDelta)) / nMaxOutside
				nFinalOffset = nOffset * _nReboundSpeedFactor
				if _fnAbs(nDelta) < 1 then
					nFinalOffset = nDelta -- 距离较小时直接归位
				end
			else
				if _fnAbs(nDelta) > _nMinPosOffset then
					nFinalOffset = nDelta * self.tArgs.nReboundScale
				end
			end
			if nFinalOffset then
				self:_SetContentPosWithOffset(nFinalOffset, false)
			end
		end
	end

end

function UIScrollList:_GatherDragDelta(nDelta)
	while table.get_len(self.m.tDragDistDelta) >= _nDragSpeedGatherCount do
		table.remove(self.m.tDragDistDelta, 1)
		table.remove(self.m.tDragTimeDelta, 1)
	end
	table.insert(self.m.tDragDistDelta, nDelta)
	table.insert(self.m.tDragTimeDelta, self.m.nDeltaTime)
end

-- unit per ms
function UIScrollList:_CalcDragSpeed()
	local nTotalDist = 0
	for _, nDelta in ipairs(self.m.tDragDistDelta or {}) do
		nTotalDist = nTotalDist + nDelta
	end

	local nTotalTime = 0
	for _, nDeltaTime in ipairs(self.m.tDragTimeDelta or {}) do
		nTotalTime = nTotalTime + nDeltaTime
	end

	local nSpeed = nTotalTime > 0 and nTotalDist * _nSpeedFactor / nTotalTime or 0
	nSpeed = _fnClamp(nSpeed, -_nMaxDragSpeed, _nMaxDragSpeed)
	return nSpeed
end

function UIScrollList:_GetRangeOfView()
	local nMinPos = 0 - self.m.nPosOfContent
	local nMaxPos = nMinPos + self.m.nListSize
	return nMinPos, nMaxPos
end

function UIScrollList:_CheckRange()
	local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
	local tCells = self.m.tCells
	local nSpace = self.tArgs.nSpace

	-- 若尾部需要移除
	while self.m.nMaxIndexOfCells > self.m.nMinIndexOfCells
	and nMaxPosOfView < self.m.nMaxPosOfCells - self.m.nMaxCellSize - nSpace
	do
		local cell = self:_RemoveCell(self.m.nMaxIndexOfCells)
		assert(cell)
		local nSize = self:_GetCellSize(cell)

		self.m.nMaxPosOfCells = self.m.nMaxPosOfCells - nSpace - nSize
		self.m.nMaxIndexOfCells = self.m.nMaxIndexOfCells - 1
	end

	-- 若头部需要移除
	while self.m.nMinIndexOfCells < self.m.nMaxIndexOfCells
	and nMinPosOfView > self.m.nMinPosOfCells + self.m.nMaxCellSize + nSpace
	do
		local cell = self:_RemoveCell(self.m.nMinIndexOfCells)
		assert(cell)
		local nSize = self:_GetCellSize(cell)

		self.m.nMinPosOfCells = self.m.nMinPosOfCells + nSpace + nSize
		self.m.nMinIndexOfCells = self.m.nMinIndexOfCells + 1
	end

	-- 若尾部需要添加
	while self.m.nMaxIndexOfCells < self.m.nCellTotal
	and nMaxPosOfView > self.m.nMaxPosOfCells
	do
		local nIndex = self.m.nMaxIndexOfCells + 1
		local cell = self:_AddCell(nIndex)
		assert(cell)
		self:_SetCellPos(cell, self.m.nMaxPosOfCells)
		local nSize = self:_GetCellSize(cell)
		self:_MarkMaxCellSize(nSize)

		self.m.nMaxPosOfCells = self.m.nMaxPosOfCells + nSize + nSpace
		self.m.nMaxIndexOfCells = nIndex

		Event.Dispatch(EventType.OnUIScrollListAddCell, self)
	end

	-- 若头部需要添加
	while self.m.nMinIndexOfCells > 1
	and nMinPosOfView < self.m.nMinPosOfCells
	do
		local nIndex = self.m.nMinIndexOfCells - 1
		local cell = self:_AddCell(nIndex)
		assert(cell)
		local nSize = self:_GetCellSize(cell)
		self:_MarkMaxCellSize(nSize)
		local nPos = self.m.nMinPosOfCells - nSize
		self:_SetCellPos(cell, nPos)

		self.m.nMinPosOfCells = nPos - nSpace
		self.m.nMinIndexOfCells = nIndex
		Event.Dispatch(EventType.OnUIScrollListAddCell, self)
	end
end

function UIScrollList:_CreateCell(szCellType, nIndex)
	-- 通过回调创建, 不使用默认方式
	local fnCreateCell = self.tArgs.fnCreateCell
	if fnCreateCell then
		local cell = fnCreateCell(szCellType, nIndex)
		assert(cell)
		self.m.contentNode:addChild(cell)
		return cell
	end

	-- 使用默认方式创建
	local nPrefabID = IsNumber(szCellType) and szCellType or PREFAB_ID[szCellType]
	assert(nPrefabID, "no found prefab id: " .. szCellType)
	return UIHelper.AddPrefab(nPrefabID, self.m.contentNode)
end

function UIScrollList:_AddCell(nIndex)
	assert(nIndex and nIndex >= 1 and nIndex <= self.m.nCellTotal)
	local szCellType = self.tArgs.fnGetCellType(nIndex)
	assert(szCellType, "fail to get cell type: " .. nIndex)

	-- 从池中取
	local tCellArr = self.m.tCellPool[szCellType]
	local cell = tCellArr and table.remove(tCellArr)
	-- 取不到就新建
	if not cell then
		cell = self:_CreateCell(szCellType, nIndex)
		assert(cell, "fail to create cell: " .. szCellType)
		cell._UIScrollList_szCellType = szCellType

		-- 不吞没touch事件
		UIHelper.SetNodeSwallowTouches(cell._rootNode or cell, false, true)

		xpcall(
			function() if cell.OnInit then cell:OnInit() end end,
			function(err)
				LOG.ERROR(debug.traceback("UIScrollList:_AddCell OnInit Error"))
			end
		)
	end

	-- 可见
	self.m.tCells[nIndex] = cell
	local node = cell._rootNode or cell
	node:setVisible(true)

	xpcall(
		function() if cell.OnEnter then cell:OnEnter() end end,
		function(err)
			LOG.ERROR(debug.traceback("UIScrollList:_AddCell OnEnter Error"))
		end
	)

	-- 刷新cell的显示内容
	xpcall(
		function() self.tArgs.fnUpdateCell(cell, nIndex) end,
		function(err)
			LOG.ERROR(debug.traceback("UIScrollList:_AddCell fnUpdateCell Error"))
		end
	)
	return node
end
function UIScrollList:_RemoveCell(nIndex)
	assert(nIndex)
	local cell = self.m.tCells[nIndex]
	assert(cell, "no found cell by index: " .. nIndex)

	if cell.OnExit then
		cell:OnExit(nIndex)
	end

	local node = cell._rootNode or cell
	node:setVisible(false)

	self.m.tCells[nIndex] = nil
	local szCellType = cell._UIScrollList_szCellType
	assert(szCellType)
	local tCellArr = self.m.tCellPool[szCellType]
	if not tCellArr then
		tCellArr = {}
		self.m.tCellPool[szCellType] = tCellArr
	end
	table.insert(tCellArr, cell)

	return node
end

function UIScrollList:_RemoveMaxIndex()
	if self.m.nMaxIndexOfCells >= self.m.nMinIndexOfCells then
		local cell = self:_RemoveCell(self.m.nMaxIndexOfCells)
		assert(cell)
		local nSize = self:_GetCellSize(cell)

		self.m.nMaxPosOfCells = self.m.nMaxPosOfCells - self.tArgs.nSpace - nSize
		self.m.nMaxIndexOfCells = self.m.nMaxIndexOfCells - 1
	end
end

function UIScrollList:_GetCellSize(cell)
	local node = cell._rootNode or cell
	local tSize = node:getContentSize()
	return self.tArgs.bHorizontal and tSize.width or tSize.height
end


function UIScrollList:_IsCanDrag()
	-- 已全部加载
	if self.m.nMinIndexOfCells == 1 and self.m.nMaxIndexOfCells == self.m.nCellTotal then
		-- 内容比列表小
		if self:GetSizeOfCells() < self.m.nListSize then
			return false
		end
	end
	return true
end

function UIScrollList:_MarkMaxCellSize(nSize)
	if nSize > self.m.nMaxCellSize then
		self.m.nMaxCellSize = nSize
	end
end

function UIScrollList:_ScrollTo()
	local nMode = self.m.nModeOfScrollTo
	-- 目标cell未加载, 推动加载
	if 1 == nMode then
		local nIndex = self.m.nIndexOfScrollTo
		local cell = self.m.tCells[nIndex]
		-- 目标cell已加载, 为逼近做初始化
		if cell then
			self.m.nModeOfScrollTo = 2
			-- 计算目标位置
			local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
			local nMinPos, nMaxPos = self:_GetRangeOfTargetCell(cell)
			if not self.tArgs.bMinPosAlign then
				if nMinPos < nMinPosOfView then
					self.m.nPosOfScrollTo = self.m.nPosOfContent + (nMinPosOfView - nMinPos)
				elseif nMaxPos > nMaxPosOfView then
					self.m.nPosOfScrollTo = self.m.nPosOfContent - (nMaxPos - nMaxPosOfView)
				else
					-- 已进行显示范围, 无需再滚动
					self.m.nModeOfScrollTo = 0
				end
			else
				self.m.nPosOfScrollTo = self.m.nPosOfContent + (nMinPosOfView - nMinPos)
			end
		-- 目标cell未加载
		else
			-- 推动方向
			local nDir =  nIndex < self.m.nMinIndexOfCells and 1 or -1
			self:_SetContentPosWithOffset(self.m.nSpeedOfScrollTo * nDir, false)
		end

	-- 有目标位置, 逼近
	elseif 2 == nMode then
		local nOffset = self.m.nPosOfScrollTo - self.m.nPosOfContent
		if _fnAbs(nOffset) > _nMinPosOffset then
			nOffset = nOffset * self.tArgs.nReboundScale
		else
			self.m.nModeOfScrollTo = 0
		end
		self:_SetContentPosWithOffset(nOffset, false)

	end

end

function UIScrollList:_GetRangeOfTargetCell(cell)
	assert(cell)
	local node = cell._rootNode or cell
	local nPos = self:_GetCellPos(node)
	local nSize = self:_GetCellSize(node)
	local nSpace = self.tArgs.nSpace
	return nPos - nSpace, nPos + nSize + nSpace
end

function UIScrollList:_InitScrollBar()
	-- 创建
	local szFrameName = "UIAtlas2_Public_PublicItem_PublicItem1_Mask.png"
	UIHelper.PreloadSpriteFrame(szFrameName)
	local bar = cc.Sprite:createWithSpriteFrameName(szFrameName)
	assert(bar)
	self.m.scrollBarNode = bar
	bar:setName("ScrollBar")
	bar:setAnchorPoint(self.tArgs.bHorizontal and cc.p(0, 0) or cc.p(1, 1))
	self.tArgs.listNode:addChild(bar)

	-- 初始隐藏
	UIHelper.SetOpacity(bar, 0)
	self.m.nScrollBarOpacity = 0
end

function UIScrollList:_UnInitScrollBar()
	if self.m.scrollBarNode then
		self.m.scrollBarNode:removeFromParent(true)
		self.m.scrollBarNode = nil
	end
end

function UIScrollList:_UpdateScrollBar()
	if not self.m.bScrollBarEnabled then return end

	local bHorizontal = self.tArgs.bHorizontal

	-- 最小位置
	local nMinPos = self.m.nMinPosOfCells
	if self.m.nMinIndexOfCells > 1 then
		local nDistance = (self.m.nMinIndexOfCells - 1) * (self.m.nMaxCellSize + self.tArgs.nSpace)
		nMinPos = nMinPos - nDistance
	end

	-- 最大位置
	local nMaxPos = self.m.nMaxPosOfCells
	if self.m.nMaxIndexOfCells < self.m.nCellTotal then
		local nDistance = (self.m.nCellTotal - self.m.nMaxIndexOfCells) * (self.m.nMaxCellSize + self.tArgs.nSpace)
		nMaxPos = nMaxPos + nDistance
	end

	-- bar大小
	local bar = self.m.scrollBarNode
	local nSize = self.m.nListSize
	local nTotalSize = nMaxPos - nMinPos
	local nBarLenght = nSize * nSize / nTotalSize
	local w = bHorizontal and nBarLenght or _nScrollBarThick
	local h = bHorizontal and _nScrollBarThick or nBarLenght
	bar:setContentSize(cc.size(w, h))

	-- bar位置
	local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
	local nCellsRange = nTotalSize - nSize
	local nPercentage = (nMinPosOfView - nMinPos) / nCellsRange
	local nBarRange = self.m.nListSize - nBarLenght
	local nPos = nBarRange * nPercentage

	if bHorizontal then
		bar:setPosition(nPos, 0)
	else
		bar:setPosition(self.m.tListSize.width, self.m.tListSize.height - nPos)
	end

	-- 移动显示, 停止隐藏
	local nScrollBarOpacity = self.m.nScrollBarOpacity
	if self.m.bDragging or self.m.nLastPosOfScrollBar ~= nPos then
		nScrollBarOpacity = _nScrollBarMaxOpacity
	else
		if nScrollBarOpacity > 0 then
			nScrollBarOpacity = nScrollBarOpacity - _nScrollBarOpacitySpeed
		end
	end
	if self.m.nScrollBarOpacity ~= nScrollBarOpacity then
		UIHelper.SetOpacity(bar, nScrollBarOpacity)
		self.m.nScrollBarOpacity = nScrollBarOpacity
	end

	self.m.nLastPosOfScrollBar = nPos
end

function UIScrollList:_UpdateStopScroll()
	if self.m.nStopScrollWaitFrameCount and self.m.nStopScrollWaitFrameCount > 0 then
		self.m.nStopScrollWaitFrameCount = self.m.nStopScrollWaitFrameCount - 1
		if self.m.nStopScrollWaitFrameCount <= 0 then
			--self.m.nSpeed = self:_CalcDragSpeed()
			self.m.bDragging = false
			self.m.tDragDistDelta = {}
			self.m.tDragTimeDelta = {}
		end
	end
end

function UIScrollList:GetPercentage()
	-- 最小位置
	local nMinPos = self.m.nMinPosOfCells
	if self.m.nMinIndexOfCells > 1 then
		local nDistance = (self.m.nMinIndexOfCells - 1) * (self.m.nMaxCellSize + self.tArgs.nSpace)
		nMinPos = nMinPos - nDistance
	end

	-- 最大位置
	local nMaxPos = self.m.nMaxPosOfCells
	if self.m.nMaxIndexOfCells < self.m.nCellTotal then
		local nDistance = (self.m.nCellTotal - self.m.nMaxIndexOfCells) * (self.m.nMaxCellSize + self.tArgs.nSpace)
		nMaxPos = nMaxPos + nDistance
	end

	-- bar大小
	local nTotalSize = nMaxPos - nMinPos

	-- bar位置
	local nMinPosOfView, nMaxPosOfView = self:_GetRangeOfView()
	local nSize = self.m.nListSize
	local nCellsRange = nTotalSize - nSize
	local nPercentage = (nMinPosOfView - nMinPos) / nCellsRange
	return nPercentage
end

function UIScrollList:SetScrollEnabled(bState)
	self.m.bDragEnabled = bState
end

function UIScrollList:ResetDragState()
	self.m.nTouchBeganX = nil
	self.m.nTouchBeganY = nil
	self.m.bDragging = false
	self.m.bDragFailed = false
	self.m.tDragDistDelta = {}
	self.m.tDragTimeDelta = {}
	self.m.nSpeed = 0
	self.m.nModeOfScrollTo = 0
end