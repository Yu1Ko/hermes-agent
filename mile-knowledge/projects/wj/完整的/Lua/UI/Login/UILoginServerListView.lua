local UILoginServerListView = class("UILoginServerListView")

function UILoginServerListView:OnEnter(bAutoConnect)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self.bAutoConnect = bAutoConnect

	self.moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
	self.moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
	self.moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)

	self.tServerList = clone(g_tbLoginData.aServerList)

	-- 这里打开的时候去请求一次，因为手机端有弱网络情况，比如之前没请求到，这里补救一次
    self.moduleServerList.ForceRequestServerList()

	self:InitList()
end

function UILoginServerListView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UILoginServerListView:RegEvent()
	Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
		if LoginMgr.IsWaiting() then
			return
		end

		if nKeyCode == cc.KeyCode.KEY_ENTER then
			if UIHelper.GetHierarchyVisible(self.BtnStart) then
				UIHelper.SimulateClick(self.BtnStart)
			end
		end
	end)

	Event.Reg(self, EventType.OnServerListReqSuccessed, function()
		--self:InitList()
	end)
end

function UILoginServerListView:UnRegEvent()

end

function UILoginServerListView:BindUIEvent()
	--确定选服
	UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function()
		self:doConfirm()
	end)

	--取消选服
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.BtnRoleCheck, EventType.OnClick, function()
		UIHelper.OpenWeb(tUrl.SearchPlayer, false, true)
	end)

	UIHelper.BindUIEvent(self.BtnServerCheck, EventType.OnClick, function()
		UIHelper.OpenWeb(tUrl.SearchServer, false, true)
	end)
end

function UILoginServerListView:InitList()
	--初始化选中
	local tbSeleteServer = self.moduleServerList.GetSelectServer()
	local nRegionIndex, nServerIndex = 1, 1
	local nAreanCount = #self.tServerList

	if tbSeleteServer then
		local bDone = false
		for i = 1, #self.tServerList do
			local tbRegion = self.tServerList[i]
			--不判断大区名字，优先从推荐/最近登录服务器搜索目标服务器
			for j = 1, #tbRegion do
				if tbRegion[j].szServer == tbSeleteServer.szServer then
					nRegionIndex = i
					nServerIndex = j
					bDone = true
					break
				end
			end
			if bDone then
				break
			end
		end
	end

	--初始化AreanPrefab数量，CellPrefab数量在每次选中Region时刷新
	UIHelper.RemoveAllChildren(self.ScrollViewAreanList)
	for i = 1, nAreanCount do
		UIHelper.AddPrefab(PREFAB_ID.WidgetAreanServerList, self.ScrollViewAreanList, i, self)
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAreanList)

	Timer.AddFrame(self, 1, function()
		self:SetRegionSelect(nRegionIndex)
		self:SetServerSelect(nServerIndex)
	end)
end

function UILoginServerListView:doConfirm()
	if LoginMgr.IsWaiting() or not UIHelper.GetHierarchyVisible(self.BtnStart) then
		return
	end

	local tbRegion = self:GetSelectRegion()
	if tbRegion then
		local nServerIndex = self:GetSelectServerIndex()
		local tbServer = tbRegion[nServerIndex]
		if tbServer then
			self.moduleServerList.SetSelectServer(tbServer.szRegion, tbServer.szServer)
		end
	end

	if self.bAutoConnect then
		g_tbLoginData.bNotLogout = false
		self.moduleAccount.ClearLogin()
		self.moduleGateway.ConnectGateway()
	end

	UIMgr.Close(self)
end

--选择大区
function UILoginServerListView:OnRegionSelected(nIndex)
	self.nCurRegionIndex = nIndex
	local tbRegion = self:GetSelectRegion() or {}
	local nServerCount = #tbRegion
	UIHelper.RemoveAllChildren(self.ScrollViewServerList)
	for i = 1, nServerCount, 4 do
		UIHelper.AddPrefab(PREFAB_ID.WidgetServerListCell, self.ScrollViewServerList, i, self)
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewServerList)

	Event.Dispatch(EventType.Login_RegionUpdate, nIndex)

	self:SetServerSelect(1)
end

--选中大区
function UILoginServerListView:SetRegionSelect(nIndex)
	UIHelper.SetToggleGroupSelected(self.AreanToggleGroup, nIndex - 1)
	self:OnRegionSelected(nIndex)
end

--选择服务器
function UILoginServerListView:OnServerSelected(nIndex)
	local tbRegion = self:GetSelectRegion()
	if tbRegion then
		local tbServer = tbRegion[nIndex]
		--self:UpdateServerType(tbServer)
		UIHelper.SetString(self.LabelServerInfo, "当前选择：" .. tbServer.szDisplayServer)
	end
end

function UILoginServerListView:OnServerSelectedConfirm()
	self:doConfirm()
end

--选中服务器
function UILoginServerListView:SetServerSelect(nIndex)
	UIHelper.SetToggleGroupSelected(self.CellToggleGroup, nIndex - 1)
	self:OnServerSelected(nIndex)
end

--更新服务器类型显示（点卡服/月卡服/点月卡服）
function UILoginServerListView:UpdateServerType(tbServer)
	local nServerType = self:GetTypeByString(tbServer.szDisplayServer)
	local szDesc = ""
	if nServerType == 1 then --点卡服
		szDesc = g_tStrings.SERVER_LIST_DIANKA_DESC .. "服"
	elseif nServerType == 2 then --点月卡服
		szDesc = g_tStrings.SERVER_LIST_DIANYUKA_DESC .. "服"
	end
	UIHelper.SetString(self.LabelServerInfo, "当前选择：" .. szDesc)
end

function UILoginServerListView:GetTypeByString(szValue)
	if not szValue then return 0 end

	if string.find(szValue, g_tStrings.SERVER_LIST_DIANKA_DESC) then --点卡
		return 1
	elseif string.find(szValue, g_tStrings.SERVER_LIST_DIANYUKA_DESC) then --点月卡
		return 2
	end
	return 0
end

--获取选中的大区
function UILoginServerListView:GetSelectRegion()
	return self.tServerList[self.nCurRegionIndex]
end

--获取选中的服务器索引
function UILoginServerListView:GetSelectServerIndex()
	return UIHelper.GetToggleGroupSelectedIndex(self.CellToggleGroup) + 1
end

return UILoginServerListView