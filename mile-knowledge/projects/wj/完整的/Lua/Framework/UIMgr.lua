UIMgr = UIMgr or {className = "UIMgr"}
local self = UIMgr


-- 在 UIMgr.CloseAllInLayer(szLayerName, tbIgnoreViewIDs)
-- 这个接口里 不能关闭的界面
local tbCanNotCloseViewID =
{
	[VIEW_ID.PanelRevive] = true,
}

-- 所有包含MiniScene冲突的界面，用来保证MiniScene的独立性。
local tbAllMiniScenceViewIDs = {
	VIEW_ID.PanelOtherPlayer,
	VIEW_ID.PanelRenownRewordList,
}

--部分单独控制主场景显示隐藏的界面，如组队
local tbPauseMainSceneViewID = {
	[VIEW_ID.PanelCameraVertical] = true,
	[VIEW_ID.PanelTeam] = true,
	[VIEW_ID.PanelConstructionMain] = true,
}

--部分不能直接关闭得界面
local tbCloseViewFunc = {
	[VIEW_ID.PanelConstructionMain] = "HLBOp_Exit.DoExit()",
}

function UIMgr.Init()
	if self.bInit then return end

	self.tMapLayers = {}
	self.tMapLayerStacks = {}
	self.tOpenQueue = {}
	self.tCloseQueue = {}
	self.tPrefabCaches = {}								-- 加载窗口预制缓存
	self.tLayerHideCounter = {}							-- 隐藏Layer的计数, 解决多次隐藏的冲突
	self.tCloseCallBackMap = {}							-- 注册过的界面关闭回调

	self.bPlayShowAnim = true
	self.bPlayHideAnim = true

	self.scriptColorBg = nil	-- 颜色遮罩节点

	self.tbRecentOpenedIDs = {}
	self.tbReportOpenedIDs = {}

	self.tbSidePageViewIDs = {}
	self.tbNotPlayColorBgHideAnimViewIDs = {}
	for k, v in pairs(UISidePageViewTab) do
		table.insert(self.tbSidePageViewIDs, k)
	end
	table.insert_tab(self.tbNotPlayColorBgHideAnimViewIDs, self.tbSidePageViewIDs)
	table.insert_tab(self.tbNotPlayColorBgHideAnimViewIDs, IGNORE_TEACH_VIEW_IDS)

	ccui.Widget:setDefaultClickSoundFileName(UIHelper.UTF8ToGBK("data/sound/界面/Button.wav"))

	self.sceneGame = cc.Scene:create()
	for szLayerName, nLayer in pairs(UILayer.NameToLayer) do
		local layer = cc.Layer:create()
		self.sceneGame:addChild(layer, nLayer, szLayerName)
		self.tMapLayers[szLayerName] = layer
		self.tMapLayerStacks[szLayerName] = {}

		if szLayerName == UILayer.Cache then
			UIHelper.SetVisible(layer, false)
		end
	end

	cc.Director:getInstance():runWithScene(self.sceneGame)

	self.bInit = true

	UIMgr.Open(VIEW_ID.PanelTouchMask)

	UIMgr.RegEvent()
end


function UIMgr.LogInfo(szFormat, ...)
	LOG.INFO(szFormat, ...)
end

function UIMgr.LogError(szFormat, ...)
	LOG.ERROR(szFormat, ...)
end


function UIMgr.RegEvent()
	-- 定时清理缓存, 每隔一秒清理一次
	Timer.AddCycle(self, 1, self._clearPrefabCache)

	Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
		self.bIsEnterBg = true
	end)

	Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
		self.bIsEnterBg = false
		self._removeFromBgList()
	end)

	Event.Reg(self, EventType.OnEnterPowerSaveMode, function()
		self.bIsEnterBg = true
	end)

	Event.Reg(self, EventType.OnExitPowerSaveMode, function()
		self.bIsEnterBg = false
		self._removeFromBgList()
	end)
end

function UIMgr.UnInit()
	if not self.bInit then return end

	for szLayerName, layer in pairs(self.tMapLayers or {}) do
		self.CloseAllInLayer(szLayerName)
		--layer:removeAllChildren()
	end

	if self.sceneGame then
		if self.scriptColorBg then
			UIHelper.SetParent(self.scriptColorBg._rootNode, self.sceneGame)
			self.scriptColorBg._keepmt = false
			self.scriptColorBg._donotdestroy = false
			if self.scriptColorBg._widgetMgr.setClearAdaptWhenCleanup then
				self.scriptColorBg._widgetMgr:setClearAdaptWhenCleanup(true)
			end
		end

		self.sceneGame:removeAllChildren()
		self.scriptColorBg = nil
		self.sceneGame = nil
	end

	self._clearPrefabCache()
	Timer.DelAllTimer(self)
	Timer.DelAllWait(self)

	self.tMapLayers = {}
	self.tMapLayerStacks = {}
	self.tOpenQueue = {}
	self.tCloseQueue = {}
	self.tCloseCallBackMap = {}

	self.bInit = false
end

function UIMgr.GetCurrentScene()
	return self.sceneGame
end

--[[
	异步打开界面

	并不是真正的异步，而是等做完动画后再开界面
	目的是为了让开界面前的动画更加丝滑，不被卡掉
]]
function UIMgr.OpenAsync(nViewID, ...)
	local tbArgs = {...}
	local _doOpen = function()
		self.bIsAsyncOpening = false
		UIHelper.HideTouchMask()

		self.bNotMainCityAnim = true
		self.bNotCaptureScreen = true
		self.bNotRelocate = true
		if not SceneMgr.IsLoading() then
			UIMgr.Open(nViewID, unpack(tbArgs))
		else
			-- 如果正在过图，那么就还原之前播放的MainCity的动画
			LOG.WARN("UIMgr.OpenAsync, scene is loading when open nViewID = "..tostring(nViewID))
			local conf = TabHelper.GetUIViewTab(nViewID)
			if conf then
				local bPlayMainCityAnim = conf.nPlayMainCityAnimType > 0
				if bPlayMainCityAnim then
					UIHelper.PlayMainCityAnimShow(conf.nPlayMainCityAnimType)
				end
			end
		end
		self.bNotMainCityAnim = false
		self.bNotCaptureScreen = false
		self.bNotRelocate = false
	end

	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then
		UIMgr.LogError("UIMgr.OpenAsync, view conf is not exist. nViewID = %s", tostring(nViewID))
		return
	end

	if Config.bOptickLuaSample then BeginSample("UIMgr.OpenViewAsync."..tostring(nViewID)) end

	self.bIsAsyncOpening = true
	UIHelper.ShowTouchMask()

	local bPlayMainCityAnim = conf.nPlayMainCityAnimType > 0
	if bPlayMainCityAnim then
		UIHelper.PlayMainCityAnimHide(conf.nPlayMainCityAnimType)
	end

	UIHelper.BlackMaskEnter(nViewID, _doOpen)

	if Config.bOptickLuaSample then EndSample() end
end

function UIMgr.Open(nViewID, ...)
	if not self.bInit then
		return
	end

	if not IsNumber(nViewID) then
		UIMgr.LogError(string.format("UIMgr.Open, invalid nViewID = %s", tostring(nViewID)))
		return
	end

	if not AppReviewMgr.SpecialCheck(nViewID, ...) then
		return
	end

	if AppReviewMgr.CheckForbidView(nViewID, true, ...) then
		return
	end

	if not CrossMgr.IsViewCanOpen(nViewID, true) then
		return
	end

	if not SystemOpen.IsViewOpen(nViewID, true) then
		return
	end

	if self.bIsEnterBg and nViewID ~= VIEW_ID.PanelRevive then
		self._appendToBgList(nViewID, ...)
		return
	end

	if UIMgr.SholudHandleKeyboardMode(nViewID) then
		return
	end

	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then
		UIMgr.LogError("UIMgr.Open, view conf is not exist. nViewID = %s", tostring(nViewID))
		return
	end

	if self.nCloseingViewID == nViewID then
		self.bIsCloseing = false
		self.nCloseingViewID = nil
	end

	if self.bIsOpening and UIMgr.IsNeedInQueen(nViewID) then
		--if self._getIndexInOpenQueue(nViewID) then
			UIMgr.LogInfo(string.format("UIMgr.Open, isOpening insert to queue nViewID = %s", tostring(nViewID)))
			table.insert(self.tOpenQueue, {["nViewID"] = nViewID, ["tbParams"] = {...}})
		--end
		return
	end

	-- 需要淡入的 界面重定向到 "异步" 打开
	if conf.tbBlackFadeIn and not self.bNotRelocate then
		UIMgr.OpenAsync(nViewID, unpack({...}))
		return
	end

	if Config.bOptickLuaSample then BeginSample("UIMgr.OpenView."..tostring(nViewID)) end

	self._closeTips(conf)

	self.bIsOpening = true
	self.nOpeningViewID = nViewID

	self._appendToRecentOpened(nViewID)

	UIMgr.LogInfo(string.format("UIMgr.Open, nViewID = %s, szName = %s", tostring(nViewID), tostring(table.get_key(VIEW_ID, nViewID))))

	local scriptView = self._createView(nViewID, ...) -- 返回对应的界面Lua脚本对象
	if scriptView == nil then
		self.bIsOpening = false
		self.nOpeningViewID = nil
		UIMgr.LogError("UIMgr.Open, nViewID = %s craete view failed.", tostring(nViewID))
		return nil
	end

	Event.Dispatch(EventType.OnViewOpen, nViewID)
	UIMgr.CloseEditBox(nViewID)
	UIMgr.SetAnnouncementVisible(nViewID, false)

	if Config.bOptickLuaSample then EndSample() end

	return scriptView
end

function UIMgr.ToggleView(nViewID, ...)
	if UIMgr.GetView(nViewID) then
		UIMgr.Close(nViewID)
	else
		UIMgr.Open(nViewID, ...)
	end
end

function UIMgr.AddPrefab(nPrefabID, parent, ...)
	if Config.bOptickLuaSample then BeginSample("UIMgr.AddPrefab."..tostring(nPrefabID)) end
	local ret = self._addPrefabView(nPrefabID, parent, ...)
	if Config.bOptickLuaSample then EndSample() end
	return ret
end

function UIMgr.New3DScene(nFlag, nSceneID)
	UIMgr.LogInfo("UIMgr.New3DScene, nFlag = %s nSceneID = %s", tostring(nFlag), tostring(nSceneID))

	local scene = cc.CC3DScene:create(nFlag, nSceneID)
	if not scene then
		UIMgr.LogError("UIMgr.New3DScene failed!, nFlag = %s nSceneID = %s", tostring(nFlag), tostring(nSceneID))
		return
	end

	-- 场景Node名称需要和SceneMgr中的保持一致
	scene:setName(string.format("3DScene_%s", nSceneID));

	local layer = self.tMapLayers[UILayer.Scene]
	if layer then
		layer:addChild(scene)

		local tbStack = self.tMapLayerStacks[UILayer.Scene]
		table.insert(tbStack, {
			["node"] = scene,
		})
	else
		UIMgr.LogError("UIMgr.New3DScene, scene layer is not exist")
	end
end

function UIMgr.RemoveAllScene()
	local tbStack = self.tMapLayerStacks[UILayer.Scene]
	local nCount = #tbStack
	for i = nCount, 1 , -1 do
		local one = tbStack[i]
		if one.node then
			one.node:removeFromParent()
			table.remove(tbStack, i)
		end
	end
end

function UIMgr.CloseImmediately(nViewID)
	local temp = self.bPlayHideAnim
	UIMgr.SetPlayHideAnim(false)
	UIMgr.Close(nViewID)
	UIMgr.SetPlayHideAnim(temp)
end

function UIMgr.Close(nViewID)
	if not self.bInit then
		return
	end

	local scriptView = nil
	if IsTable(nViewID) then
		if IsNumber(nViewID._nViewID) then
			scriptView = nViewID
			nViewID = nViewID._nViewID -- 在对应的UI界面里可以用 UIMgr.Close(self) 这种写法
		end

	end

	if not IsNumber(nViewID) then
		UIMgr.LogError("UIMgr.Close, invalid nViewID = %s", tostring(nViewID))
		return
	end

	if self.bIsEnterBg and self._closeFromBgList(nViewID) then
		return
	end

	if not UIMgr.GetView(nViewID) then
		if #self.tCloseQueue > 0 then
			local nNextCloseViewID = table.remove(self.tCloseQueue, 1)
			UIMgr.Close(nNextCloseViewID)
		end
		return
	end

	if self.nOpeningViewID == nViewID then
		self.bIsOpening = false
		self.nOpeningViewID = nil
	end

	if self.bIsCloseing --[[and self.nCloseingViewID ~= nViewID]] then
		--先从待打开的UI列表中查找是否存在该UI，若存在则直接移除
		local nIndex = self._getIndexInOpenQueue(nViewID)
		if nIndex then
			UIMgr.LogInfo(string.format("UIMgr.Close, nViewID = %s", tostring(nViewID)))
			table.remove(self.tOpenQueue, nIndex)
			return
		end

		UIMgr.LogInfo("UIMgr.Close, is Closeing insert to queue nViewID = %s", tostring(nViewID))
		table.insert(self.tCloseQueue, scriptView or nViewID)
		return
	end

	self.bIsCloseing = true
	self.nCloseingViewID = nViewID

	UIMgr.LogInfo(string.format("UIMgr.Close, nViewID = %s, szName = %s", tostring(nViewID), tostring(table.get_key(VIEW_ID, nViewID))))

	local function _doClose(nViewID)
		UIHelper.HideTouchMask()
		--先从待打开的UI列表中查找是否存在该UI，若存在则移除
		local nIndex = self._getIndexInOpenQueue(nViewID)
		if nIndex then
			table.remove(self.tOpenQueue, nIndex)
		else
			self._destroyView(nViewID, scriptView)
		end

		self.bIsCloseing = false
		self.nCloseingViewID = nil

		Event.Dispatch(EventType.OnViewClose, nViewID)

		if UIMgr.tCloseCallBackMap and UIMgr.tCloseCallBackMap[nViewID] then
			UIMgr.tCloseCallBackMap[nViewID]()
			UIMgr.tCloseCallBackMap[nViewID] = nil
		end

		local conf = TabHelper.GetUIViewTab(nViewID)
		if conf and conf.szCloseViewSound ~= "None" then
			SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound[conf.szCloseViewSound])
		end

		if #self.tCloseQueue > 0 then
			local nNextCloseViewID = table.remove(self.tCloseQueue, 1)
			UIMgr.Close(nNextCloseViewID)
		elseif #self.tOpenQueue > 0 then
			local tNextOpen = table.remove(self.tOpenQueue, 1)
			local nNextOpenViewID = tNextOpen.nViewID
			local tNextOpenParams = tNextOpen.tbParams
			UIMgr.Open(nNextOpenViewID, table.unpack(tNextOpenParams))
		end
	end

	UIHelper.ShowTouchMask()

	-- 在这一步去掉 Color 遮罩
	local conf = TabHelper.GetUIViewTab(nViewID)
	if conf.tbBlackFadeOut then
		UIHelper.BlackMaskExit(nViewID, function()
			self._playColorBgHideAnim(nViewID)
			self._playHideAnim(nViewID, function()
				self._removeColorBgFromParent(nViewID, scriptView)
				_doClose(nViewID)
			end)
		end)
	else
		self._playColorBgHideAnim(nViewID)
		self._playHideAnim(nViewID, function()
			self._removeColorBgFromParent(nViewID, scriptView)
			_doClose(nViewID)
		end)
	end

	UIMgr.SetAnnouncementVisible(nViewID, true)
	UIMgr.SetSceneLayerVisible(nViewID, true)

	--local bResult = self._playHideAnim(nViewID, function() _doClose(nViewID) end)
end

function UIMgr.CloseAllInLayer(szLayerName, tbIgnoreViewIDs)
	if szLayerName == UILayer.Scene or
		szLayerName == UILayer.Mask then
		return
	end

	local layer = self.tMapLayers[szLayerName]
	if layer then
		local tbStack = self.tMapLayerStacks[szLayerName]
		local nCount = #tbStack
		for i = nCount, 1 , -1 do
			local one = tbStack[i]
			if one then
				local nViewID = one.nViewID
				if tbIgnoreViewIDs == nil or not table.contain_value(tbIgnoreViewIDs, nViewID) then

					if not tbCanNotCloseViewID[nViewID] then
						UIMgr.Close(nViewID)
					end

				end
			end
		end
	end

	-- 删除在打开队列里的
	for i = #self.tOpenQueue, 1, -1 do
		local nView = self.tOpenQueue[i].nViewID
		local tbConf = UIViewTab[nView]
		if tbConf then
			if UIMgr.GetViewLayerByViewID(nViewID) == szLayerName then
				if tbIgnoreViewIDs == nil or not table.contain_value(tbIgnoreViewIDs, one.nViewID) then
					table.remove(self.tOpenQueue, i)
					break
				end
			end
		end
	end
end

function UIMgr.CloseAllMiniSceneView(nIgnoreViewID)
	for _, nViewID in ipairs(tbAllMiniScenceViewIDs) do
		if nIgnoreViewID == nil or nViewID ~= nIgnoreViewID then
			UIMgr.Close(nViewID)
		end
	end
end

function UIMgr.CloseAll()
	for szLayerName, nLayer in pairs(UILayer.NameToLayer) do
		UIMgr.CloseAllInLayer(szLayerName)
	end
end

function UIMgr.CloseWithCallBack(nViewID, fCallBack)
	if nViewID and fCallBack then
		UIMgr.tCloseCallBackMap = {}
		UIMgr.tCloseCallBackMap[nViewID] = fCallBack
	end
	UIMgr.Close(nViewID)
end

function UIMgr.SetCloseCallback(nViewID, fCallBack)
	if nViewID and fCallBack then
		UIMgr.tCloseCallBackMap = {}
		UIMgr.tCloseCallBackMap[nViewID] = fCallBack
	end
end

function UIMgr.Reset()

end

function UIMgr.SetViewShow(nViewID, bShow)
	if IsTable(nViewID) then
		nViewID = nViewID._nViewID
	end

	if not IsNumber(nViewID) then
		UIMgr.LogError("UIMgr.Close, invalid nViewID = %s", tostring(nViewID))
		return
	end

	local tbViewInfo = UIMgr.GetView(nViewID)
	if tbViewInfo then
		UIHelper.SetVisible(tbViewInfo.node, bShow)
	end
end


function UIMgr.SetShowAllInLayer(szLayerName, bShow , tbIgnoreViewIDs)
	if szLayerName == UILayer.Scene then return end

	local layer = self.tMapLayers[szLayerName]
	if layer then
		local tbStack = self.tMapLayerStacks[szLayerName]
		local nCount = #tbStack
		for i = nCount, 1 , -1 do
			local one = tbStack[i]
			if one then
				if tbIgnoreViewIDs == nil or not table.contain_value(tbIgnoreViewIDs, one.nViewID) then
					self.SetViewShow(one.nViewID, bShow)
				end
			end
		end
	end
end


function UIMgr.GetView(nViewID)
	return self._getView(nViewID)
end

function UIMgr.GetViewScript(nViewID)
	local view = self._getView(nViewID)
	return view and view.scriptView
end

function UIMgr.ShowView(nViewID)
	local view = self._getView(nViewID)
	local node = view and view.node
	if node then
		node:setVisible(true)
		self._onViewVisible(view.scriptView, true)
	end
end

function UIMgr.HideView(nViewID)
	local view = self._getView(nViewID)
	local node = view and view.node
	if node then
		node:setVisible(false)
		self._onViewVisible(view.scriptView, false)
	end
end

function UIMgr.ShowLayer(szLayerName, tbIgnoreViewIDs, bForce)
	if UILayer.Cache == szLayerName then
		return
	end

	if bForce then
		self.tLayerHideCounter[szLayerName] = 0
	end

	local nLen = tbIgnoreViewIDs and #tbIgnoreViewIDs or 0
	if nLen <= 0 then
		local nCounter = self.tLayerHideCounter[szLayerName]
		if not nCounter then
			UIMgr.LogInfo("layer[%s] has not been hided", szLayerName)
			return
		end

		nCounter = math.max(nCounter - 1, 0)
		self.tLayerHideCounter[szLayerName] = nCounter
		if nCounter == 0 then
			local layer = self.GetLayer(szLayerName)
			UIHelper.SetVisible(layer, true)
			self.bHideAllLayer = false
		end
	else
		local tbStack = self.tMapLayerStacks[szLayerName]
		if tbStack then
			for _, v in ipairs(tbStack) do
				if not table.contain_value(tbIgnoreViewIDs, v.nViewID) then
					UIHelper.SetVisible(v.node, true)
				end
			end
		end
		self.bHideAllLayer = false
	end
end

function UIMgr.HideLayer(szLayerName, tbIgnoreViewIDs)
	if UILayer.Cache == szLayerName then
		return
	end

	local nLen = tbIgnoreViewIDs and #tbIgnoreViewIDs or 0
	if nLen <= 0 then
		local layer = self.GetLayer(szLayerName)
		self.tLayerHideCounter[szLayerName] = (self.tLayerHideCounter[szLayerName] or 0) + 1
		UIHelper.SetVisible(layer, false)
	else
		local tbStack = self.tMapLayerStacks[szLayerName]
		if tbStack then
			for _, v in ipairs(tbStack) do
				if not table.contain_value(tbIgnoreViewIDs, v.nViewID) then
					UIHelper.SetVisible(v.node, false)
				end
			end
		end
	end
end

function UIMgr.ShowAllLayer()
	self.bHideAllLayer = false
	for l in pairs(UILayer.NameToLayer) do
		if l ~= UILayer.Scene then
			self.ShowLayer(l)
		end
	end
end

function UIMgr.HideAllLayer(tbIgnoreLayer)
	self.bHideAllLayer = true
	for l in pairs(UILayer.NameToLayer) do
		if l ~= UILayer.Scene then
			if tbIgnoreLayer == nil or not table.contain_value(tbIgnoreLayer, l) then
				self.HideLayer(l)
			else
				self.bHideAllLayer = false
			end
		end
	end
end

function UIMgr.IsHideAllLayer()
	return self.bHideAllLayer
end

function UIMgr.IsLayerVisible(szLayerName)
	local layer = self.GetLayer(szLayerName)
	if layer then
		return layer:isVisible()
	end
	return false
end

function UIMgr.IsViewVisible(nViewID)
	local view = self._getView(nViewID)
	local node = view and view.node
	if node then
		return node:isVisible()
	end
end

function UIMgr.IsViewOpened(nViewID, bCheckOpenQueue)
	if self.bIsOpening then
		if self.nOpeningViewID == nViewID then
			return true
		elseif bCheckOpenQueue then
			--判断是否在等待打开的队列中
			for _, tOpen in pairs(self.tOpenQueue) do
				if tOpen.nViewID == nViewID then
					return true
				end
			end
		end
	end

	local view = self._getView(nViewID)
	return view ~= nil
end

function UIMgr.GetLayerStackLength(szLayerName, tbIgnoreViewIDs)
	local nLength = 0
	local tbStack = self.tMapLayerStacks[szLayerName]
	if tbStack then
		if tbIgnoreViewIDs then
			for _, v in ipairs(tbStack) do
				if not table.contain_value(tbIgnoreViewIDs, v.nViewID) then
					nLength = nLength + 1
				end
			end
		else
			nLength = #tbStack
		end
	end
	return nLength
end

function UIMgr.GetLayerTopViewID(szLayerName, tbIgnoreViewIDs)
	local tbStack = self.tMapLayerStacks[szLayerName]
	if tbStack then
		if tbIgnoreViewIDs then
			for i = #tbStack, 1, -1 do
				if not table.contain_value(tbIgnoreViewIDs, tbStack[i].nViewID) then
					return tbStack[i].nViewID
				end
			end
		else
			local nTop = #tbStack
			if nTop > 0 then
				return tbStack[nTop].nViewID
			end
		end
	end
end

function UIMgr.GetLayer(szLayerName)
	return self.tMapLayers[szLayerName]
end

function UIMgr.RemoveOpenQueue(nViewID)
	local nIndex = self._getIndexInOpenQueue(nViewID)
	if nIndex then
		table.remove(self.tOpenQueue, nIndex)
		return
	end
end

function UIMgr.GetViewLayerByViewID(nViewID)
	local conf = TabHelper.GetUIViewTab(nViewID)
	return conf and conf.szLayerName and UILayer[conf.szLayerName]
end

function UIMgr._getView(nViewID)
	local szLayerName = self.GetViewLayerByViewID(nViewID)
	local layer = self.tMapLayers and self.tMapLayers[szLayerName]
	if layer then
		local tbStack = self.tMapLayerStacks[szLayerName]
		local nCount = #tbStack
		for i = nCount, 1 , -1 do
			local one = tbStack[i]
			if one.nViewID == nViewID then
				return one
			end
		end
	end
end

function UIMgr._addViewToLayer(nViewID, conf, node, compLuaBind, scriptView)
	if node == nil then return end
	if not conf then
		UIMgr.LogError(string.format("UIMgr._addToLayer, view conf is not exist. nViewID = %s", tostring(nViewID)))
		return
	end

	if conf.bTouchMask then
		local scriptBG = UIMgr.AddPrefab(PREFAB_ID.WidgetTouchBackGround, node, conf.bTouchMaskCloseView, scriptView)
		if scriptView then
			scriptView._scriptBG = scriptBG
		end
	end

	local bAlreadyHasViewInStack = UIMgr.GetView(nViewID) ~= nil
	local szViewName = conf.szViewName
	local szLayerName = UILayer[conf.szLayerName]
	local layer = self.tMapLayers[szLayerName]
	if layer then
		if not string.is_nil(szViewName) then
			node:setName(szViewName)
		end

		if conf.szOpenViewSound ~= "None" then
			SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound[conf.szOpenViewSound])
		end

		local tbStack = self.tMapLayerStacks[szLayerName]
		table.insert(tbStack, {
			["nViewID"] = nViewID,
			["szViewName"] = szViewName,
			["node"] = node,
			["compLuaBind"] = compLuaBind,
			["scriptView"] = scriptView,
		})

		UIMgr.LockInput()

		layer:addChild(node)

		if scriptView and scriptView._aniMgr then
			scriptView._aniMgr:playOnLoad()
		end

		UIHelper.ShowTouchMask(0.6) -- 与nAutoDisableOpeningTimerID的时间保持一致

		function _onPlayShowAnimEnd()
			if self.bShowAnimEndByTimer then
				return
			end

			Timer.DelTimer(self, self.nAutoDisableOpeningTimerID)

			UIHelper.HideTouchMask()
			self.bIsOpening = false
			self.nOpeningViewID = nil

			if #self.tOpenQueue > 0 then
				local tNextOpen = table.remove(self.tOpenQueue, 1)
				local nNextOpenViewID = tNextOpen.nViewID
				local tNextOpenParams = tNextOpen.tbParams
				UIMgr.Open(nNextOpenViewID, table.unpack(tNextOpenParams))
			end
		end

		self.bShowAnimEndByTimer = false
		Timer.DelTimer(self, self.nAutoDisableOpeningTimerID)
		self.nAutoDisableOpeningTimerID = Timer.Add(self, 0.6, function()
			_onPlayShowAnimEnd()
			self.bShowAnimEndByTimer = true
		end)

		local bResult = self._playShowAnim(nViewID, _onPlayShowAnimEnd, bAlreadyHasViewInStack)

		return scriptView
	else
		UIMgr.LogError(string.format("UIMgr._addToLayer, layer is not exist. szLayerName = %s", tostring(szLayerName)))
	end
end

function UIMgr._removeViewFromLayer(nViewID, scriptView)
	local szLayerName = UIMgr.GetViewLayerByViewID(nViewID)
	local layer = self.tMapLayers[szLayerName]
	if layer then
		local tbStack = self.tMapLayerStacks[szLayerName]
		local nCount = #tbStack

		for i = nCount, 1 , -1 do
			local one = tbStack[i]
			if one.nViewID == nViewID and (scriptView == nil or scriptView == one.scriptView) then
				-- 延迟销毁窗口对象，避免空指针访问
				DelayDestoryCocosNode(one.node)
				-- 从窗口树中删除
				layer:removeChild(one.node, true)
				table.remove(tbStack, i)

				UIMgr.LockInput()

				local conf = TabHelper.GetUIViewTab(nViewID)
				UIHelper.PlayMainCityAnimShow(conf.nPlayMainCityAnimType or 0)

				Event.Dispatch(EventType.OnViewDestroy, nViewID)

				UITouchHelper.SetTouchDispatchByPriority(nViewID, false)
				return
			end
		end
	end
end

function UIMgr._clearPrefabCache()
	-- 客户端5秒一次心跳，防止卡死的时候分不清楚是逻辑卡死还是渲染卡死
	local nNow = os.time()
	if (nNow - (self.nLastTickTime or 0)) >= 5 then
		LOG.INFO("UIMgr -- client heartbeat --")
		self.nLastTickTime = nNow
	end

	for _, r in pairs(self.tPrefabCaches) do
		r:release()
	end
	self.tPrefabCaches = {}

	UIHelper.ClearCacheLayer()
end

-- crator对象的容器, 延迟到时再释放GC
function UIMgr._loadCreatorReader(szFilePath)
	local reader = self.tPrefabCaches[szFilePath]
	if reader then
		return reader
	end

	reader = creator.CreatorReader:createWithFilename(szFilePath)
	if not reader then
		return
	end

	reader:retain()
	self.tPrefabCaches[szFilePath] = reader
	return reader
end

function UIMgr._createView(nViewID, ...)
	local bCaptureScreen = false
	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then
		UIMgr.LogError("UIMgr._createView, view conf is not exist. nViewID = %s", tostring(nViewID))
		return
	end

	UITouchHelper.SetTouchDispatchByPriority(nViewID, true)

	local creatorReader = self._loadCreatorReader(conf.szFilePath)
	if not creatorReader then
		UIMgr.LogError("UIMgr._createView, load prefab failed. nViewID = %s, prefab:%s",
				tostring(nViewID), conf.szFilePath)
		return
	end

	creatorReader:setup()

	local node = creatorReader:getNodeGraph()
	if not node then return end

	local aniManager = creatorReader:getAnimationManager()
	aniManager:retain()
	aniManager:removeFromParent(false)
	node:addChild(aniManager)
	aniManager:setVisible(false)
	aniManager:release()

	local widgetManager = creatorReader:getWidgetManager()
	widgetManager:retain()
	widgetManager:removeFromParent(false)
	node:addChild(widgetManager)
	widgetManager:setVisible(false)
	widgetManager:release()

	local compLuaBind = node:getComponent("LuaBind")
	local scriptView = compLuaBind and compLuaBind:getScriptObject()
	if scriptView then
		local tbOnEnterParams = {...}
		scriptView._tbOnEnterParams = (table.get_len(tbOnEnterParams) > 0) and tbOnEnterParams or nil
		scriptView._nViewID = nViewID
		scriptView._aniMgr = aniManager
		scriptView._widgetMgr = widgetManager
	end

	local bAlreadyHasViewInStack = false
	if conf.bColorMask then
		local viewScript = UIMgr.GetViewScript(nViewID)
		bAlreadyHasViewInStack = viewScript ~= nil

		if not bAlreadyHasViewInStack and not self.bNotCaptureScreen then
			bCaptureScreen = true
		else
			self._addColorBgToParent(node, nViewID, bAlreadyHasViewInStack)
		end
	end

	if UILayer[conf.szLayerName] == UILayer.Page or UILayer[conf.szLayerName] == UILayer.Popup then
		UIHelper.ExitHideAllUIMode()
	end

	local bPlayMainCityAnim = (conf.nPlayMainCityAnimType > 0) and (not self.bNotMainCityAnim)
	if bPlayMainCityAnim then
		UIHelper.PlayMainCityAnimHide(conf.nPlayMainCityAnimType)
	end

	if bCaptureScreen then
		UIHelper.SetVisible(node, false)
		UIMgr._beforeCaptureScreen(nViewID)
		UIHelper.CaptureNode(self.sceneGame, function(pRetTexture)
			self._afterCaptureScreen(nViewID)
			self._addColorBgToParent(node, nViewID, bAlreadyHasViewInStack, pRetTexture)
			UIHelper.SetVisible(node, true)
			self._onViewVisible(scriptView, true)
			UIMgr.SetSceneLayerVisible(nViewID, false)
		end)
	else
		self._onViewVisible(scriptView, true)
		UIMgr.SetSceneLayerVisible(nViewID, false)
	end

	self._addViewToLayer(nViewID, conf, node, compLuaBind, scriptView)

	return scriptView--self._addViewToLayer(nViewID, conf, node, compLuaBind, scriptView)
end

function UIMgr._addPrefabView(nPrefabID, parent, ...)
	local conf = TabHelper.GetUIPrefabTab(nPrefabID)
	if not conf then
		return
	end

	local creatorReader = self._loadCreatorReader(conf.szFilePath)
	if not creatorReader then
		UIMgr.LogError("UIMgr._addPrefabView, load prefab failed. prefab:%s", conf.szFilePath)
		return
	end

	creatorReader:setup()

	local node = creatorReader:getNodeGraph()
	if not node then return end

	local aniManager = creatorReader:getAnimationManager()
	aniManager:retain()
	aniManager:removeFromParent(false)
	node:addChild(aniManager)
	aniManager:setVisible(false)
	aniManager:release()

	local widgetManager = creatorReader:getWidgetManager()
	widgetManager:retain()
	widgetManager:removeFromParent(false)
	node:addChild(widgetManager)
	widgetManager:setVisible(false)
	widgetManager:release()

	local compLuaBind = node:getComponent("LuaBind")
	local scriptView = compLuaBind and compLuaBind:getScriptObject()
	if scriptView then
		if scriptView._bFirstOnEnter then
			local tbOnEnterParams = {...}
			scriptView._tbOnEnterParams = (table.get_len(tbOnEnterParams) > 0) and tbOnEnterParams or nil
		end

		scriptView._nPrefabID = nPrefabID
		scriptView._aniMgr = aniManager
		scriptView._widgetMgr = widgetManager

		--scriptView._rootNode
		--scriptView._scriptPath
	end

	if nPrefabID == PREFAB_ID.WidgetTouchBackGround then
		parent:addChild(node, -1)
	else
		parent:addChild(node)
	end

	UIHelper.SetPosition(node, 0, 0)

	if not node:isHadSafeArea() then
		if scriptView then
			UIHelper.WidgetFoceDoAlign(scriptView)
		elseif widgetManager then
			widgetManager:forceDoAlign()
		end
	end


	if aniManager then
		aniManager:playOnLoad()
	end
	Event.Dispatch(EventType.OnPrefabAdd, nPrefabID, scriptView or node)
	return scriptView or node
end

function UIMgr._destroyView(nViewID, scriptView)
	self._removeViewFromLayer(nViewID, scriptView) -- auto release
end

function UIMgr._getIndexInOpenQueue(nViewID)
	for i = #self.tOpenQueue, 1, -1 do
		if self.tOpenQueue[i].nViewID == nViewID then
			return i
		end
	end
end

function UIMgr._onViewVisible(scriptView, bVisible)
	if not scriptView then
		return
	end

	if bVisible then
		if IsFunction(scriptView.OnShow) then
			scriptView:OnShow()
		end
	else
		if IsFunction(scriptView.OnHide) then
			scriptView:OnHide()
		end
	end
end

function UIMgr._addColorBgToParent(parent, nParentViewID, bAlreadyHasViewInStack, pRetTexture)
	if not safe_check(parent) then
		return
	end

	-- 因为有可能存在一帧内打开又关闭的界面，截屏回来的消息是下一帧，这里就会导致黑屏，所以要加个判断
	if not UIMgr.GetView(nParentViewID) then
		return
	end

	local conf = TabHelper.GetUIViewTab(nParentViewID)
	if not conf then return end
	if not conf.bColorMask then return end

	if not self.scriptColorBg then
		self.scriptColorBg = UIHelper.AddPrefab(PREFAB_ID.WidgetColorBackGround, self.sceneGame)
		self.scriptColorBg:Init()
	end

	local bIsReplace = bAlreadyHasViewInStack
	self.scriptColorBg:AddToParent(parent, nParentViewID, bIsReplace, pRetTexture)
end

function UIMgr._removeColorBgFromParent(nViewID, scriptView)
	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then return end
	if not conf.bColorMask then return end

	local script = scriptView or UIMgr.GetViewScript(nViewID)
	local parent = script and script._rootNode

	if not safe_check(parent) then
		return
	end

	if not self.scriptColorBg then
		return
	end

	self.scriptColorBg:RemoveFromParent(parent)
end

function UIMgr._playColorBgHideAnim(nViewID)
	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then return end
	if not conf.bColorMask then return end
	if not conf.bColorMaskAnim then return end
	if UILayer[conf.szLayerName] ~= UILayer.Page then return end

	local nPageLen = UIMgr.GetFullPageViewCount()
	if nPageLen > 1 then
		return
	end

	if not self.scriptColorBg then
		return
	end

	self.scriptColorBg:PlayHideAnim()
end

-- 播放淡入动画
function UIMgr._playShowAnim(nViewID, callback, bToEndFrame)
	local bResult = false
	local bHasAnimPlay = false

	if self.bPlayShowAnim then
		local viewScript = UIMgr.GetViewScript(nViewID)
		if viewScript and viewScript._fadeInOutInfo then
			local animNode = viewScript._fadeInOutInfo.animNode
			local fadeInClipNames = viewScript._fadeInOutInfo.fadeInClipNames
			if animNode and fadeInClipNames and #fadeInClipNames > 0 then
				for k, v in ipairs(fadeInClipNames) do
					if k == 1 then
						Event.Dispatch(EventType.OnViewPlayShowAnimBegin, nViewID)
						UIHelper.PlayAni(viewScript, animNode, v, function()
							Event.Dispatch(EventType.OnViewPlayShowAnimFinish, nViewID)
							if callback then callback() end
						end, 0, bToEndFrame)
						bHasAnimPlay = true
					else
						UIHelper.PlayAni(viewScript, animNode, v, nil, 0, bToEndFrame)
					end
				end

				bResult = true
			end
		end
	end

	if not bHasAnimPlay then
		if callback then callback() end
	end

	return bResult
end

-- 播放淡出动画
function UIMgr._playHideAnim(nViewID, callback)
	local bResult = false
	local bHasAnimPlay = false

	if self.bPlayHideAnim then
		local viewScript = UIMgr.GetViewScript(nViewID)
		if viewScript and viewScript._fadeInOutInfo then
			local animNode = viewScript._fadeInOutInfo.animNode
			local fadeOutClipNames = viewScript._fadeInOutInfo.fadeOutClipNames
			if animNode and fadeOutClipNames and #fadeOutClipNames > 0 then
				for k, v in ipairs(fadeOutClipNames) do
					if k == 1 then
						Event.Dispatch(EventType.OnViewPlayHideAnimBegin, nViewID)
						UIHelper.PlayAni(viewScript, animNode, v, function()
							Event.Dispatch(EventType.OnViewPlayHideAnimFinish, nViewID)
							if callback then callback() end
						end)
						bHasAnimPlay = true
					else
						UIHelper.PlayAni(viewScript, animNode, v)
					end
				end

				bResult = true
			end
		end
	end

	if not bHasAnimPlay then
		if callback then callback() end
	end

	return bResult
end

-- 锁操作
function UIMgr.LockInput()
	local tbIgnoreViewIDs = IGNORE_CAMERA_VIEW_IDS
	local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, tbIgnoreViewIDs)
	local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup, tbIgnoreViewIDs)
	local nSysPopLen = UIMgr.GetLayerStackLength(UILayer.SystemPop, tbIgnoreViewIDs)
	local nMsgLen = UIMgr.GetLayerStackLength(UILayer.MessageBox, tbIgnoreViewIDs)
	local nLen = nPageLen + nPopLen + nSysPopLen + nMsgLen

	local bLock = nLen > 0

	-- 锁镜头，只锁缩放
	InputHelper.LockCamera(bLock)

	-- 2024.6.10 chenpengyu说手机上打开全屏界面也不锁移动
	-- if Platform.IsMobile() then
	-- 	InputHelper.LockMove(bLock)
	-- end

	-- -- 处理键盘相关
	-- local tbKeyboardIgnoreViewIDs = IGNORE_KEYBOARD_VIEW_IDS
	-- --local nKeyboardPageLen = UIMgr.GetLayerStackLength(UILayer.Page, tbKeyboardIgnoreViewIDs)
	-- local nKeyboardPageLen = 0
	-- local tbStack = self.tMapLayerStacks[UILayer.Page]
	-- for _, v in ipairs(tbStack) do
	-- 	-- 2024.5.7 VK-PC端的侧窗口界面下，支持可以进行主界面右下角区域的按钮快捷键操作
	-- 	if not table.contain_value(tbKeyboardIgnoreViewIDs, v.nViewID) and not UIMutexMgr.IsSidePageView(v.nViewID) then
	-- 		nKeyboardPageLen = nKeyboardPageLen + 1
	-- 	end
	-- end
	-- local bLockKeyBoard = nKeyboardPageLen > 0
	-- InputHelper.LockKeyBoard(bLockKeyBoard)

	-- 特殊处理的逻辑，当有MessageBox在的时候，要隐藏Popup，不然会出现重叠的情况
	-- 放在这可以省去计算LayerStackLength的开销
	do
		local layerPop = self.GetLayer(UILayer.Popup)
		local layerMsg = self.GetLayer(UILayer.MessageBox)

		local bPopVisible = nMsgLen <= 0 and nSysPopLen <= 0
		local bMsgVisible = nSysPopLen <= 0

		UIHelper.SetOpacity(layerPop, bPopVisible and 255 or 0)
		UIHelper.SetOpacity(layerMsg, bMsgVisible and 255 or 0)
	end
end

function UIMgr.SetPlayShowAnim(bPlayShowAnim)
	self.bPlayShowAnim = bPlayShowAnim
end

function UIMgr.SetPlayHideAnim(bPlayHideAnim)
	self.bPlayHideAnim = bPlayHideAnim
end

function UIMgr.GetAllOpenViewID()
	local tbViewID = {}
	for szLayerName, tbStack in pairs(self.tMapLayerStacks) do
		for nIndex, tbInfo in ipairs(tbStack) do
			table.insert(tbViewID, tbInfo["nViewID"])
		end
	end
	return tbViewID
end

function UIMgr.IsOpening()
	return (self.bIsOpening or self.bIsAsyncOpening)
end

function UIMgr.IsCloseing()
	return self.bIsCloseing
end

function UIMgr.IsViewInQueue(nViewID)
	return self._getIndexInOpenQueue(nViewID) ~= nil
end

-- 排队暂时还是先加上，因为目前截屏和暂停场景等接口，有问题，如果又需要高斯模糊的话，这个还是暂时先保留
function UIMgr.IsNeedInQueen(nViewID)
	local bResult = true

	local conf = TabHelper.GetUIViewTab(nViewID)
	if conf then
		local szLayer = UILayer[conf.szLayerName]
		-- 这些层级下的界面不需要排队
		if szLayer == UILayer.Tips or
			szLayer == UILayer.HoverTips or
			szLayer == UILayer.Mask or
			szLayer == UILayer.Loading or
			szLayer == UILayer.Main or
			szLayer == UILayer.Debug or
			szLayer == UILayer.Battle or
			szLayer == UILayer.Web or
			szLayer == UILayer.Guide then
			bResult = false
		end
	end

	return false--bResult
end

-- 只打开唯一一个，如果已经打开了，就不再打开，或者关闭之前的再打开
function UIMgr.OpenSingle(bCloseOpened, nViewID, ...)
	local viewScript = UIMgr.GetViewScript(nViewID)
	if viewScript then
		if bCloseOpened then
			UIMgr.CloseImmediately(nViewID)
		else
			return viewScript
		end
	end

	return UIMgr.Open(nViewID, ...)
end

function UIMgr.OpenSingleWithOnEnter(bCloseOpened, nViewID, ...)
	local viewScript = UIMgr.GetViewScript(nViewID)
	if viewScript then
		if bCloseOpened then
			UIMgr.Close(nViewID)
		else
			viewScript:OnEnter(...)
			return viewScript
		end
	end

	return UIMgr.Open(nViewID, ...)
end

function UIMgr.SetSceneLayerVisible(nViewID, bVisible)
	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then
		return
	end

	if not conf.bPauseScene then
		return
	end

	-- if not self.tbSLVisibleMap then self.tbSLVisibleMap = {} end
	-- if not self.tbSLVisibleMap[nViewID] then self.tbSLVisibleMap[nViewID] = 0 end

	-- -- 这里做计数是为了保证，如果顺序不对的情况下，这里可保证至少场景不会黑
	-- if bVisible then
	-- 	self.tbSLVisibleMap[nViewID] = self.tbSLVisibleMap[nViewID] + 1
	-- else
	-- 	self.tbSLVisibleMap[nViewID] = self.tbSLVisibleMap[nViewID] - 1
	-- end

	-- LOG.INFO("UIMgr.SetSceneLayerVisible, nViewID = %s, bVisible = %s, nVisibleCount = %s", tostring(nViewID), tostring(bVisible), tostring(self.tbSLVisibleMap[nViewID]))
	LOG.INFO("UIMgr.SetSceneLayerVisible, nViewID = %s, bVisible = %s", tostring(nViewID), tostring(bVisible))

	-- if self.tbSLVisibleMap[nViewID] >= 0 then
	if bVisible then
		UIMgr.ShowLayer(UILayer.Scene)
	else
		UIMgr.HideLayer(UILayer.Scene)
	end
end

function UIMgr._closeTips(uiViewConf)
	if not uiViewConf then
		return
	end

	if string.is_nil(uiViewConf.szLayerName) then
		return
	end

	if uiViewConf.nID == 29 then	--暂时特殊处理
		return
	end

	local szLayer = UILayer[uiViewConf.szLayerName]
	if szLayer == UILayer.Popup or
		szLayer == UILayer.MessageBox or
		szLayer == UILayer.Page or
		szLayer == UILayer.SystemPop then
			TipsHelper.DeleteAllHoverTips()
	end
end

function UIMgr._appendToBgList(nViewID, ...)
	if not self.bIsEnterBg then
		return false
	end

	if not self.tbBgOpenList then
		self.tbBgOpenList = {}
	end

	local tbView = {nViewID = nViewID, tbArgs = {...}}
	table.insert(self.tbBgOpenList, tbView)

	return true
end

function UIMgr._closeFromBgList(nViewID)
	if not self.bIsEnterBg then
		return false
	end

	if not self.tbBgOpenList then
		return false
	end

	for i, tbView in pairs(self.tbBgOpenList) do
		if tbView.nViewID == nViewID then
			table.remove(self.tbBgOpenList, i)
			return true
		end
	end

	return  false
end

function UIMgr._removeFromBgList()
	if self.bIsEnterBg then
		return
	end

	Timer.Add(self, 0.2, function()
		for i, v in ipairs(self.tbBgOpenList or {}) do
			local nViewID = v.nViewID
			local tbArgs = v.tbArgs
			UIMgr.Open(nViewID, unpack(tbArgs))
		end

		self.tbBgOpenList = {}
	end)
end

function UIMgr.SetKeyboardMode(bKeyboardMode)
	self.bKeyboardMode = bKeyboardMode
end

function UIMgr.SholudHandleKeyboardMode(nViewID)
	if self.bKeyboardMode then
		if UIMgr.GetView(nViewID) and UIMgr.IsViewVisible(nViewID) then
			UIMgr.Close(nViewID)
			return true
		end

		if ShortcutInteractionData._hasPageOrPop() then
			return true
		end
	end

	return false
end

function UIMgr._appendToRecentOpened(nViewID)
	local nMax = 5
	local nLen = #self.tbRecentOpenedIDs

	if nLen >= nMax then
		table.remove(self.tbRecentOpenedIDs, 1)
	end

	table.insert(self.tbRecentOpenedIDs, nViewID)
	table.insert(self.tbReportOpenedIDs, nViewID)

	if #self.tbReportOpenedIDs > 100 then
		self.ReportOpenedViewList(100)
	end

	local szKey = "UIRecentOpenedIDs"
	local szValue = table.concat(self.tbRecentOpenedIDs, ",")

	AddCrasheyeExtraData(szKey, szValue)
end

function UIMgr.ReportOpenedViewList(nCountLimit)
	local tbReportList = {}
	local tbLeftList = {}

	if nCountLimit and nCountLimit < #self.tbReportOpenedIDs then
		for i = 1, nCountLimit do
			table.insert(tbReportList, self.tbReportOpenedIDs[i])
		end

		for i = nCountLimit + 1,  #self.tbReportOpenedIDs do
			table.insert(tbLeftList, self.tbReportOpenedIDs[i])
		end
	else
		tbReportList = self.tbReportOpenedIDs
	end

	local bReported = ReportOpenedViewList(tbReportList)
	if bReported then
		self.tbReportOpenedIDs = tbLeftList
	end
end

-- 获取全屏界面的数量
function UIMgr.GetFullPageViewCount()
	return UIMgr.GetLayerStackLength(UILayer.Page, self.tbNotPlayColorBgHideAnimViewIDs)
end

function UIMgr.IsInLayer(nViewID, szLayer)
	local bResult = false
	local conf = TabHelper.GetUIViewTab(nViewID)
	if conf then
		bResult = (UILayer[conf.szLayerName] == szLayer)
	end
	return bResult
end

function UIMgr._beforeCaptureScreen(nViewID)
	self.bForceShowLayerScene = false

	local conf = TabHelper.GetUIViewTab(nViewID)
	local bImmediatelyCaptureNode = conf and conf.bImmediatelyCaptureNode

	if UIMgr.IsInLayer(nViewID, UILayer.Page) and not bImmediatelyCaptureNode then
		-- 避免频繁隐藏显示某些节点，会闪一下的问题
		if self.scriptColorBg then
			if safe_check(self.scriptColorBg.pFirstTexture) then
				return
			end
		end

		UIMgr.HideLayer(UILayer.Page) -- 隐藏所有Page层
		UIMgr.HideLayer(UILayer.Main) -- 隐藏所有Page层

		-- 强行打开场景层，用于截屏
		local layerScene = self.GetLayer(UILayer.Scene)
		if not UIHelper.GetVisible(layerScene) then
			UIHelper.SetVisible(layerScene, true)
			self.bForceShowLayerScene = true
		end
	end

	Event.Dispatch(EventType.BeforeCaptureScreen, nViewID)
end

function UIMgr._afterCaptureScreen(nViewID)
	if UIMgr.IsInLayer(nViewID, UILayer.Page) then
		UIMgr.ShowLayer(UILayer.Page) -- 显示所有Page层
		UIMgr.ShowLayer(UILayer.Main) -- 显示所有Page层

		if self.bForceShowLayerScene then
			local layerScene = self.GetLayer(UILayer.Scene)
			UIHelper.SetVisible(self.GetLayer(UILayer.Scene), false)
		end
	end

	Event.Dispatch(EventType.AfterCaptureScreen, nViewID)
end

function UIMgr.CloseEditBox(nViewID)
	if not Platform.IsWindows() then
		return
	end

	if nViewID == nil or
		UIMgr.IsInLayer(nViewID, UILayer.Page) or
		UIMgr.IsInLayer(nViewID, UILayer.Popup) or
		UIMgr.IsInLayer(nViewID, UILayer.MessageBox) or
		UIMgr.IsInLayer(nViewID, UILayer.SystemPop) then

		KMUICloseEditBox()
	end
end

function UIMgr.SetAnnouncementVisible(nViewID, bVisible)
	local conf = TabHelper.GetUIViewTab(nViewID)
	if not conf then return end

	local szLayer = UILayer[conf.szLayerName]
	if HIDE_ANNOUNCEMENT_VIEW_IDS[nViewID] or
	szLayer == UILayer.Page or
	szLayer == UILayer.Popup or
	szLayer == UILayer.Loading or
	szLayer == UILayer.MessageBox or
	szLayer == UILayer.SystemPop then
		if bVisible then
			UIHelper.ShowAnnouncement()
		else
			UIHelper.HideAnnouncement()
		end
	end

	local bForce = nil
	for k, v in ipairs(FORCE_SHOW_ANNOUNCEMENT_VIEW_IDS) do
		if UIMgr.GetView(v) then
			bForce = true
			break
		end
	end

	if bForce then
		UIHelper.ShowAnnouncement(true)
	end
end

function UIMgr.IsViewCloseing(nViewID)
	return self.bIsCloseing and nViewID == self.nCloseingViewID
end

function UIMgr.StopClose(nViewID)
	if self.IsViewCloseing(nViewID) then
		local viewScript = UIMgr.GetViewScript(nViewID)
		if viewScript then
			if viewScript._fadeInOutInfo then
				local animNode = viewScript._fadeInOutInfo.animNode
				local fadeOutClipNames = viewScript._fadeInOutInfo.fadeOutClipNames
				if animNode and fadeOutClipNames and #fadeOutClipNames > 0 then
					for k, v in ipairs(fadeOutClipNames) do
						UIHelper.StopAni(viewScript, animNode, v)--会自动触发_doClose回调
					end
				end
			end
		end
	end
end


function UIMgr.CloseAllPauseSceneView()
	for szLayerName, tbStack in pairs(self.tMapLayerStacks) do
		for nIndex, tbInfo in ipairs(tbStack) do
			local nViewID = tbInfo["nViewID"]
			if nViewID then
				local conf = TabHelper.GetUIViewTab(nViewID)
				if conf.bPauseScene or tbPauseMainSceneViewID[nViewID] then
					local funcExit = tbCloseViewFunc[nViewID]
					if funcExit then
						string.execute(funcExit)
					else
						UIMgr.Close(nViewID)
					end
				end
			end
		end
	end
end





















