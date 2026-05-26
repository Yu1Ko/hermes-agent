-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UILoginServerListCell
-- Date: 2022-11-07 15:18:32
-- Desc: 登录选服界面：服务器 WidgetServerListCell
-- ---------------------------------------------------------------------------------

local UILoginServerListCell = class("UILoginServerListCell")

local tFontSize = {26, 24, 20} --从大到小顺序填
local DOUBLE_CLICK_INTERVAL = 500--毫秒

function UILoginServerListCell:OnEnter(nIndex, uiView)
	if not nIndex or not uiView then
		return
	end

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()

		self.bInit = true
	end

	self.m_nIndex = nIndex
	self.m_uiView = uiView
	self:UpdateInfo()
	UIHelper.ToggleGroupAddToggle(self.m_uiView.CellToggleGroup, self.TogServerList)
end

function UILoginServerListCell:OnExit()
	self.bInit = false
	self:UnRegEvent()

	if self.m_uiView then
		UIHelper.ToggleGroupRemoveToggle(self.m_uiView.CellToggleGroup, self.TogServerList)
	end
end

function UILoginServerListCell:BindUIEvent()
	-- UIHelper.BindUIEvent(self.TogServerList, EventType.OnSelectChanged, function(toggle, bSelected)
	-- 	if bSelected then
	-- 		self.m_uiView:OnServerSelected(self.m_nIndex)
	-- 	end
	-- end)


	UIHelper.BindUIEvent(self.TogServerList, EventType.OnClick, function()
		local nNow = Timer.RealMStimeSinceStartup()
		local nInterval = nNow - (self.nClickTime or 0)
		if nInterval <= DOUBLE_CLICK_INTERVAL then
			self.m_uiView:OnServerSelectedConfirm()
		else
			self.m_uiView:OnServerSelected(self.m_nIndex)
		end

        self.nClickTime = nNow
    end)

end

function UILoginServerListCell:RegEvent()
	Event.Reg(self, EventType.Login_RegionUpdate, function()
		self:UpdateInfo()
	end)

	Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szVKName)
		if nKeyCode == cc.KeyCode.KEY_CTRL then
			self:ShowIp(true)
		end
	end)

	Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szVKName)
		if nKeyCode == cc.KeyCode.KEY_CTRL then
			self:ShowIp(false)
		end
	end)

	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		self:UpdateInfo()
	end)
end

function UILoginServerListCell:UnRegEvent()
	Event.UnRegAll(self)
end

function UILoginServerListCell:UpdateInfo()
	UIHelper.SetClickInterval(self.TogServerList, 0)

	local tbRegion = self.m_uiView:GetSelectRegion()
	local tbServer = tbRegion and tbRegion[self.m_nIndex]
	if tbServer then
		UIHelper.SetVisible(self._rootNode, true)

		local szServer = tbServer.szServer
		szServer = Version.IsBVT() and szServer or UIHelper.TruncateStringReturnOnlyResult(szServer, 10)

		if LoginMgr.IsLogin() then
			local moduleAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
			local szAccountKey = moduleAccount.GetStorageAccountKey()
			if szAccountKey then
				local tbRoleCount = Storage.ServerRoleCount.tbRoleCount[szAccountKey]
				local nRoleCount = tbRoleCount and tbRoleCount[tbServer.szServer] or 0
				if nRoleCount > 0 then
					szServer = szServer .. " (" .. nRoleCount .. ")"
				end
			end
		end

		--自动设置字号
		local nMaxWidth = UIHelper.GetWidth(self._rootNode) - 50
		local nFontSize = tFontSize[#tFontSize]
		for _, nSize in ipairs(tFontSize) do
			local nWidth = UIHelper.GetUtf8RichTextWidth(szServer, nSize)
			if nWidth <= nMaxWidth then
				nFontSize = nSize
				break
			end
		end

		UIHelper.SetFontSize(self.LabelNormal, nFontSize)
		UIHelper.SetFontSize(self.LabelSelect, nFontSize)
		UIHelper.SetString(self.LabelNormal, szServer)
		UIHelper.SetString(self.LabelSelect, szServer)

		--根据Server原本的Region去找szDisplayRegion，排除掉推荐/最近登录区名不含新服
		local tbOriginRegion = self.m_uiView.moduleServerList.GetRegionByDisplay(tbServer.szDisplayRegion)
		if tbOriginRegion and string.find(tbOriginRegion.szDisplayRegion, "新服") then
			UIHelper.SetVisible(self.ImgCornerMarkBg, true)
			UIHelper.SetVisible(self.ImgCornerMain, false)
		else
			UIHelper.SetVisible(self.ImgCornerMarkBg, false)
			UIHelper.SetVisible(self.ImgCornerMain, tbServer.nServerMark > 0) --主服
		end

		UIHelper.SetVisible(self.ImgServerMarkFluency,
		tbServer.nState == LoginServerStatus.IDLE --空闲
		or tbServer.nState == LoginServerStatus.SMOOTHLY --流畅
		or tbServer.nState == LoginServerStatus.GOOD) --良好

		if Version.IsBVT() then
			if tbServer.nState == 1 then
				UIHelper.SetVisible(self.ImgServerMarkFluency, true)
			end
		end

		UIHelper.SetVisible(self.ImgServerMarkBuzy, tbServer.nState == LoginServerStatus.BUSY) --繁忙
		UIHelper.SetVisible(self.ImgServerMarkCrowd, tbServer.nState == LoginServerStatus.FULL) --拥挤
		UIHelper.SetVisible(self.ImgServerMarkBreak, tbServer.nState == LoginServerStatus.SERVICING) --维护

		-- IP
		UIHelper.SetVisible(self.LabelIP, false)
	else
		UIHelper.SetVisible(self._rootNode, false)
	end
end

function UILoginServerListCell:ShowIp(bVisible)
	if not Config.bGM then
		return
	end

	if bVisible then
		local tbRegion = self.m_uiView:GetSelectRegion()
		local tbServer = tbRegion and tbRegion[self.m_nIndex]

		UIHelper.SetString(self.LabelIP, tbServer and tbServer.szIP or "")
		UIHelper.SetVisible(self.LabelIP, true)
	else
		UIHelper.SetVisible(self.LabelIP, false)
	end
end

return UILoginServerListCell