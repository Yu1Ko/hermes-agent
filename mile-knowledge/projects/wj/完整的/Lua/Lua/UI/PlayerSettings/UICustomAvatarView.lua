-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomAvatarView
-- Date: 2022-12-19 10:23:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomAvatarView = class("UICustomAvatarView")

local nPageAvatarCount = 5

function UICustomAvatarView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	self.bSelJianghu = false
    self:UpdateInfo()
end

function UICustomAvatarView:OnExit()
    self.bInit = false
	Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UICustomAvatarView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick,function ()
        local eRetCode = g_pClientPlayer.SetMiniAvatar(self.dwID)
		if eRetCode then
			TipsHelper.ShowNormalTip(g_tStrings.STR_CHANGE_MINI_AVATAR_SUCCESS)
		end
    end)

	UIHelper.BindUIEvent(self.BtnBg, EventType.OnClick,function ()
		Event.Dispatch(EventType.PreviewAvator,g_pClientPlayer.dwMiniAvatarID,g_pClientPlayer.dwID)
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick,function ()
		Event.Dispatch(EventType.PreviewAvator,g_pClientPlayer.dwMiniAvatarID,g_pClientPlayer.dwID)
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick,function ()
		Event.Dispatch(EventType.PreviewAvator,g_pClientPlayer.dwMiniAvatarID,g_pClientPlayer.dwID)
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.TogJianghu, EventType.OnSelectChanged,function (_, bSelected)
		if bSelected then
			self.bSelJianghu = true
			self.nPageIndex = 1
			UIHelper.SetString(self.EditPaginate, self.nPageIndex)
			self:UpdateList()
		end
	end)

	UIHelper.BindUIEvent(self.TogSchool, EventType.OnSelectChanged,function (_, bSelected)
		if bSelected then
			self.bSelJianghu = false
			self.nPageIndex = 1
			UIHelper.SetString(self.EditPaginate, self.nPageIndex)
			self:UpdateList()
		end
	end)

	UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPageAvatarCount + 1
            self:UpdateList()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPageAvatarCount + 1
            self:UpdateList()
        end
    end)

	UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self.nCurIndex = self.nPageIndex * nPageAvatarCount + 1
            self:UpdateList()
        end
    end)
end

function UICustomAvatarView:RegEvent()
    Event.Reg(self,"CURRENT_PLAYER_FORCE_CHANGED",function ()
        self:UpdateAllMiniAvatar()
    end)

    Event.Reg(self,"SYNC_MINI_AVATAR_DATA",function ()
        self:UpdateAllMiniAvatar()
    end)

    Event.Reg(self,"ACQUIRE_MINI_AVATAR",function (dwID)
        --self:UpdateAllMiniAvatar()
		local dwMiniAvatarID = dwID or g_pClientPlayer.dwMiniAvatarID
		local tLine = g_tTable.RoleAvatar:Search(dwMiniAvatarID)
		local bInHat = g_pClientPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
		if tLine.nRelateID > 0 and ( (tLine.nHat == 0 and bInHat) or (tLine.nHat == 1 and not bInHat) ) then
			g_pClientPlayer.SetMiniAvatar(tLine.nRelateID)
		end
    end)

	Event.Reg(self, "SET_MINI_AVATAR", function (dwID)
        if self.dwID == dwID then
			UIHelper.SetButtonState(self.BtnChange,BTN_STATE.Disable)
        end
    end)

    Event.Reg(self, EventType.PreviewAvator, function (dwID)
		if dwID == g_pClientPlayer.dwMiniAvatarID then
			UIHelper.SetButtonState(self.BtnChange,BTN_STATE.Disable)
		else
			UIHelper.SetButtonState(self.BtnChange,BTN_STATE.Normal)
		end
        self.dwID = dwID
    end)

	Event.Reg(self, EventType.OnSceneTouchNothing, function()
		Event.Dispatch(EventType.PreviewAvator,g_pClientPlayer.dwMiniAvatarID,g_pClientPlayer.dwID)
		UIMgr.Close(self)
	end)

	Event.Reg(self, EventType.PLAYER_MINI_AVATAR_UPDATE, function ()
        Timer.Add(self, 0.2, function()
			self:UpdateInfo()
		end)
    end)
end

function UICustomAvatarView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICustomAvatarView:UpdateInfo()
    local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
	if not AvatarMgr.bDataSynced then
		AvatarMgr.ApplyMiniAvatarData()
	end

    UIHelper.SetButtonState(self.BtnChange,BTN_STATE.Disable)
    self:UpdateAllMiniAvatar()
end

function UICustomAvatarView:UpdateAllMiniAvatar()
    self:GetAllMiniAvatar()
    self:UpdateList()
end

function UICustomAvatarView:UpdateList()
	-- UIHelper.RemoveAllChildren(self.LayoutCustomAvatar)

	if self.bSelJianghu then
		self.nPageCount = math.ceil(#self.tNormal / nPageAvatarCount) or 0
		UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)
	else
		self.nPageCount = math.ceil(#self.tSchool / nPageAvatarCount) or 0
		UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)
	end

	self.nPageIndex = self.nPageIndex or 1
    UIHelper.SetString(self.EditPaginate, self.nPageIndex)
	UIHelper.SetVisible(self.WidgetPaginate, self.nPageCount > 1)

    local nIndex1 = nPageAvatarCount * (self.nPageIndex - 1) + 1
    local nIndex2 = nIndex1 + nPageAvatarCount - 1

	for i = 1, 5, 1 do
		UIHelper.RemoveAllChildren(self.tbWidgetCustomAvatarContent[i])
	end

	if self.bSelJianghu then
		self:UpdateJianghuList(nIndex1, nIndex2)
	else
		self:UpdateSchoolList(nIndex1, nIndex2)
	end

	UIHelper.LayoutDoLayout(self.LayoutCustomAvatar)
end

function UICustomAvatarView:UpdateJianghuList(nIndex1, nIndex2)
	local index, nContentIndex = 0, nil
	for nIndex = nIndex1, nIndex2, 1 do
		local info = self.tNormal[nIndex]
		if info then
			local line = UIAvatarNameTab[info.dwID]
			if not line then index = index + 1 nContentIndex = index else nContentIndex = nil end
			-- local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent,self.LayoutCustomAvatar,info.dwID,self.tDetail[info.dwID],false,nContentIndex)
			local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent,self.tbWidgetCustomAvatarContent[nIndex - nIndex1 + 1],info.dwID,self.tDetail[info.dwID],false,nContentIndex)
			UIHelper.SetNodeSwallowTouches(itemicon._rootNode, false, true)
		end
	end
end

function UICustomAvatarView:UpdateSchoolList(nIndex1, nIndex2)
	local index, nContentIndex = 0, nil
	for nIndex = nIndex1, nIndex2, 1 do
		local info = self.tSchool[nIndex]
		if info then
			local line = UIAvatarNameTab[info.dwID]
			if not line then index = index + 1 nContentIndex = index else nContentIndex = nil end
			local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent,self.tbWidgetCustomAvatarContent[nIndex - nIndex1 + 1],info.dwID,self.tDetail[info.dwID],true,nContentIndex)
			UIHelper.SetNodeSwallowTouches(itemicon._rootNode, false, true)
		end
	end
end

function UICustomAvatarView:SelectAvatar(dwID)
    Event.Dispatch(EventType.PREVIEW_AVATAR,dwID)
end

function UICustomAvatarView:GetAllMiniAvatar()
	self.tSchool = {{dwID = 0}}
	self.tNormal = {}
	self.tDetail = {}

	local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
	local t = AvatarMgr.GetAllMiniAvatar()
	table.sort(t,
		function(a, b)
			return (a.dwID > b.dwID)
		end
	)

	for _, info in ipairs(t) do
		local tLine = g_tTable.RoleAvatar:Search(info.dwID)
		if tLine then
			self.tDetail[info.dwID] = tLine
			if tLine.dwForceID ~= 0 then
				local bResult = self:CanGetAvatar(tLine.nHat)
				if bResult then
					table.insert(self.tSchool, info)
				end
			else
				table.insert(self.tNormal, info)
			end
		end
	end

	self.bCheckCap = false

	if not self.bFirst then
		self.bFirst = true
		self:GetCurEquipMiniAvatarPos()
	end
end

function UICustomAvatarView:GetCurEquipMiniAvatarPos()
	for nIndex, info in ipairs(self.tNormal) do
		if info.dwID ==  g_pClientPlayer.dwMiniAvatarID then
			self.bSelJianghu = true

			Timer.AddFrame(self, 1, function ()
				UIHelper.SetSelected(self.TogJianghu, true)
				self.nPageIndex = math.ceil(nIndex / nPageAvatarCount)
				self:UpdateList()
			end)

			return
		end
	end

	for nIndex, info in ipairs(self.tSchool) do
		if info.dwID ==  g_pClientPlayer.dwMiniAvatarID then
			self.bSelJianghu = false

			Timer.AddFrame(self, 1, function ()
				UIHelper.SetSelected(self.TogSchool, true)
				self.nPageIndex = math.ceil(nIndex / nPageAvatarCount)
				self:UpdateList()
			end)

			return
		end
	end

end

function UICustomAvatarView:CanGetAvatar(nHat)
	local hPlayer = g_pClientPlayer
	if hPlayer.dwForceID == 10 then
		local bIsSecondRepresent = hPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
		if self.bCheckCap then
			if bIsSecondRepresent and nHat == 0 then
				return true
			elseif not bIsSecondRepresent and nHat == 1 then
				return true
			end
		else
			if bIsSecondRepresent and nHat == 1 then
				return true
			elseif not bIsSecondRepresent and nHat == 0 then
				return true
			end
		end
		return false
	end
	return true
end

return UICustomAvatarView