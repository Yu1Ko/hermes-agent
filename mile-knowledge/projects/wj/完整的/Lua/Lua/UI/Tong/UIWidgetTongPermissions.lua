-- ---------------------------------------------------------------------------------
-- Author: hanyu
-- Name: UIWidgetTongPermissions
-- Date: 2023-01-06
-- Desc: 帮会权限页
-- ---------------------------------------------------------------------------------

local UIWidgetTongPermissions = class("UIWidgetTongPermissions")

local WidgetCenterIndex = {
	[1] = {1},
	[2] = {2},
	[3] = {3, 4, 5, 6, 7, 8},
	[4] = {9, 10, 11, 12, 13, 14},
	[5] = {15},
	[6] = {16},
}

local function cmpA(infoA, infoB)
	return infoA.nEquipScore < infoB.nEquipScore
end
local function cmpB(infoA, infoB)
	return infoA.nEquipScore > infoB.nEquipScore
end

function UIWidgetTongPermissions:OnShow()
	self:SwitchToGroupList()
end

function UIWidgetTongPermissions:Init()
	self.m = {}	
	self:RegEvent()
	self:BindUIEvent()

	self:InitData()
	self:InitUI()
end

function UIWidgetTongPermissions:UnInit()
	self:UnRegEvent()
	UIHelper.RemoveFromParent(self._rootNode)
	self.m = nil
end

function UIWidgetTongPermissions:BindUIEvent()
	
	for nIndex = 1, TongData.TOTAL_GROUP_CNT do
		UIHelper.BindUIEvent(self.tbBtn[nIndex], EventType.OnClick, function()
			self.nGroupIndex = nIndex
			self.nSelectNum = 0
			self:SwitchToGroupInfo()
		end)
	end
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		self:SwitchToGroupList()
	end)
	UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function()
		self.nCurSort = self.nCurSort == 1 and 2 or 1
		self:UpdateGroupMemberList()
	end)
	UIHelper.BindUIEvent(self.TogPermissions, EventType.OnSelectChanged, function(toggle, bState)
		if bState then
			-- self:UpdateScrollViewMemberPermissions()
			UIHelper.SetVisible(self.WidgetAnchorPermissions, true)
			UIHelper.SetVisible(self.WidgetAnchorMember, false)
		end
	end)

	UIHelper.BindUIEvent(self.TogMember, EventType.OnSelectChanged, function(toggle, bState)
		if bState then
			-- self:UpdateGroupMemberList()
			UIHelper.SetVisible(self.WidgetAnchorPermissions, false)
			UIHelper.SetVisible(self.WidgetAnchorMember, true)
		end
	end)

	UIHelper.BindUIEvent(self.BtnMove, EventType.OnClick, function()
		UIHelper.SetSelected(self.TogManagement, false)
		local tbSelectIDList = self:GetSelectIDList()
		UIMgr.Open(VIEW_ID.PanelFactionManagementFilterScreen, TongData.tFilterScreenType.Permissions, tbSelectIDList, self.nGroupIndex - 1, nil)
	end)

	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
		UIHelper.SetSelected(self.TogManagement, false)
	end)

	UIHelper.RegisterEditBoxEnded(self.EditBoxMember, function()
        self.szSearchkey = UIHelper.GetString(self.EditBoxMember)
        self:UpdateGroupMemberList()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBoxMember, function()
        self.szSearchkey = UIHelper.GetString(self.EditBoxMember)
        self:UpdateGroupMemberList()
    end)

	UIHelper.BindUIEvent(self.TogManagement, EventType.OnSelectChanged, function(toggle, bState)
		self:SwitchGroupMemberCheck(bState)
		self:UpdateWidgetTips(bState)
	end)

	UIHelper.BindUIEvent(self.TogAllSelect, EventType.OnSelectChanged, function(toggle, bState)
		self.bSelectAllPeople = bState
		self:SelectAllPeople(bState)
	end)

	UIHelper.BindUIEvent(self.BtnModify, EventType.OnClick, function()
		--UIMgr.Open(VIEW_ID.PanelModifyNamePop, self.nGroupIndex - 1)
		local nGroupIndex = self.nGroupIndex - 1
		UIHelper.ShowModifyNamePanel(
			g_tStrings.STR_GUILD_MODIFY_GROUP_NAME,
			UIHelper.GBKToUTF8(TongData.GetGroupInfoByID(nGroupIndex).szName),
			function (szName)
				if szName then				
					TongData.ModifyGroupName(nGroupIndex, UIHelper.UTF8ToGBK(szName))
				end
			end,7
		)
	end)

	UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function()				
		UIHelper.SetTouchLikeTips(self.WidgetTips, self._rootNode, function ()
			UIHelper.SetSelected(self.TogHelp, false)
		end)
	end)	
	UIHelper.BindUIEvent(self.TogHelp, EventType.OnLongPress, function()				
		-- print("-------BindUIEvent----------")
	end)	
end


function UIWidgetTongPermissions:RegEvent()
	Event.Reg(self, "ON_GET_APPLY_JOININ_TONGLIST", function ()
	end)
	Event.Reg(self, EventType.TongGroupSelectPeople, function (bSelect)
		self.nSelectNum = self.nSelectNum + (bSelect and 1 or -1)
		self:UpdateWidgetTipsNum()
	end)
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		self:InitUI()
		self:UpdateWidgetCenter()
	end)
	Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function ()
		self:InitUI()
		self:UpdateWidgetCenter()
		self:UpdateGroupMemberList()
	end)
	Event.Reg(self, "TONG_EVENT_NOTIFY", function()
		if arg0 == TONG_EVENT_CODE.MODIFY_GROUP_NAME_SUCCESS then
			TongData.ApplyTongInfo()
		elseif arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_GROUP_SUCCESS then
			TongData.ApplyTongRoster()
		end
	end)
end

function UIWidgetTongPermissions:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongPermissions:InitData()
	self.nCurSort = 1
	self.szSearchkey = ""
	self.tbGroupMemberScriptView = {}
	self.nSelectNum = 0
	self.nMemberNum = 0
	self.tbRulerInfo = TongData.GetMemberListByKey("", 1)[1]
end

function UIWidgetTongPermissions:InitUI()
	self.tbGroupInfo = TongData.GetGroupInfo()
	for nIndex = 1, TongData.TOTAL_GROUP_CNT do
		local info = self.tbGroupInfo[nIndex]
		if nIndex == 1 then
			UIHelper.SetString(self.tbLabelName[nIndex], UIHelper.GBKToUTF8(info.szName))--帮主不是richText
		else
			UIHelper.SetRichText(self.tbLabelName[nIndex], string.format("<color=%s>%s</c>", TONG_PERMISSION_MEMBER_COLOR_RICHTEXT[nIndex], UIHelper.GBKToUTF8(info.szName)))
		end
		UIHelper.SetString(self.tbLabelCount[nIndex], FormatString(g_tStrings.STR_PLAYER_COUNT, info.nNumber))
		if nIndex ~= 1 then
			UIHelper.SetVisible(self.tbLock[nIndex-1], not info.bEnable)
			UIHelper.SetEnable(self.tbBtn[nIndex], info.bEnable)
			UIHelper.SetNodeGray(self.tbBtn[nIndex], not info.bEnable,true)--button置灰
			UIHelper.SetNodeGray(self.tbLock[nIndex-1], false)--锁不置灰
			-- UIHelper.SetVisible(self.tbBtn[nIndex], info.bEnable)--不能操作的暂时隐藏
		else
			local nMasterName = TongData.GetMasterInfo().szName
			UIHelper.SetString(self.tbLabelCount[nIndex], UIHelper.GBKToUTF8(nMasterName))
		end
		UIHelper.SetVisible(self.tbImgself[nIndex], info.bSelfGroup)
		local imgDot = self.tbImgDot[nIndex - 1]
		if imgDot then
			UIHelper.SetVisible(imgDot, info.bEnable)
		end
	end
	self:UpdatePlayerAvatar(self.ImgPlayerIcon, self.SFXPlayerIcon, self.AnimatePlayerIcon)
end


------------------------------------UpdateGroupList------------------------
function UIWidgetTongPermissions:SwitchToGroupList()
	UIHelper.SetVisible(self.WidgetPermissions, true)
	UIHelper.SetVisible(self.WidgetPermissionsManagement, false)
	UIHelper.SetSelected(self.TogManagement, false)
end




------------------------------------UpdateGroupInfo---------------------

function UIWidgetTongPermissions:SwitchToGroupInfo()
	UIHelper.SetVisible(self.WidgetPermissions, false)
	UIHelper.SetVisible(self.WidgetPermissionsManagement, true)
	UIHelper.SetSelected(self.TogMember, true)--切到显示组内信息的面板，默认选择人员
	self:UpdateGroupMemberList()
	self:UpdateWidgetCenter()
	self:UpdateScrollViewMemberPermissions()
	self:UpdateTogManagement()--选择移动人员的按钮
	self:UpdateBtnModify()--改名按钮
end

function UIWidgetTongPermissions:UpdateGroupMemberList()
	local tbInfo = TongData.GetMemberListByKey(self.szSearchkey, self.nGroupIndex)
	local comp = self.nCurSort == 1 and cmpA or cmpB
	table.sort(tbInfo, comp)
	for index, info in ipairs(tbInfo) do
		local scriptView = self.tbGroupMemberScriptView[index]
		if scriptView then
			scriptView:OnEnter(info)
		else
			scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPermissionsManagementMember, self.LayoutMemberPermissions, info)
			table.insert(self.tbGroupMemberScriptView, scriptView)
		end
	end

	for index = #tbInfo + 1, #self.tbGroupMemberScriptView do
		self.tbGroupMemberScriptView[index]:OnRecycled()
	end

	self.nSelectNum = 0
	self.nMemberNum = #tbInfo
	
	UIHelper.LayoutDoLayout(self.LayoutMemberPermissions)
	UIHelper.ScrollViewDoLayout(self.ScrollViewMemberPermissions)
	UIHelper.ScrollToTop(self.ScrollViewMemberPermissions, 0)
end

--移动人员按钮状态
function UIWidgetTongPermissions:UpdateTogManagement()
	-- body
	UIHelper.SetVisible(self.TogManagement, TongData.CanChangeMemberGroup(self.nGroupIndex - 1))
end
--改名按钮
function UIWidgetTongPermissions:UpdateBtnModify()
	-- body
	UIHelper.SetVisible(self.BtnModify, TongData.CanChangeGroupName(self.nGroupIndex - 1))
end

function UIWidgetTongPermissions:SwitchGroupMemberCheck(bOpen)
	if not self.tbGroupMemberScriptView then return end
	for nIndex = 1, self.nMemberNum do
		local scriptView = self.tbGroupMemberScriptView[nIndex]
		if scriptView then
			scriptView:SwitchToggleSelect(bOpen)
		end
	end
end

function UIWidgetTongPermissions:UpdateWidgetTips(bState)
	if bState then
		self:UpdateWidgetTipsNum()
	end
end

function UIWidgetTongPermissions:UpdateWidgetTipsNum()
	-- local nCount = 0
	-- for index, scriptView in ipairs(self.tbGroupMemberScriptView) do
	-- 	local bSelect = scriptView:GetSelected()
	-- 	nCount = nCount + (bSelect and 1 or 0)
	-- end
	local szCount = string.format("(%s/%s)", self.nSelectNum, self.nMemberNum)
	UIHelper.SetString(self.LabelSelectedNum, szCount)
    UIHelper.LayoutDoLayout(self.LayoutLabelSelected)

	self.bSelectAllPeople = self.nSelectNum == self.nMemberNum
	UIHelper.SetSelected(self.TogAllSelect, self.bSelectAllPeople, false)
end

function UIWidgetTongPermissions:SelectAllPeople(bSelect)
	for nIndex = 1, self.nMemberNum do
		local scriptView = self.tbGroupMemberScriptView[nIndex]
		if scriptView and scriptView:GetSelected() ~= bSelect then
			scriptView:SetSelect(bSelect)
		end
	end
end


function UIWidgetTongPermissions:UpdateWidgetCenter()
	for index, tbGroupIndex in ipairs(WidgetCenterIndex) do
		if table.contain_value(tbGroupIndex, self.nGroupIndex) then
			UIHelper.SetVisible(self.tbWidgetCenter[index], true)
			UIHelper.SetString(self.tbGroupInfoLabelTitle[index], UIHelper.GBKToUTF8(self.tbGroupInfo[self.nGroupIndex].szName))
			UIHelper.SetColor(self.tbGroupInfoLabelTitle[index], TONG_PERMISSION_MEMBER_COLOR_LABEL[self.nGroupIndex])
			UIHelper.SetString(self.tbGroupInfoLabelCount[index], FormatString(g_tStrings.STR_PLAYER_COUNT, self.tbGroupInfo[self.nGroupIndex].nNumber))
			if index ~= 1 then
				UIHelper.SetVisible(self.tbGroupInfoImgLock[index-1], not self.tbGroupInfo[self.nGroupIndex].bEnable)
			else
				local nMasterName = TongData.GetMasterInfo().szName
				UIHelper.SetString(self.tbGroupInfoLabelCount[index], UIHelper.GBKToUTF8(nMasterName))
				self:UpdatePlayerAvatar(self.ImgPlayerIcon1, self.SFXPlayerIcon1, self.AnimatePlayerIcon1)
			end
		else
			UIHelper.SetVisible(self.tbWidgetCenter[index], false)
		end
	end
end

function UIWidgetTongPermissions:UpdatePlayerAvatar(ImgPlayerIcon, SFXPlayerIcon, AnimatePlayerIcon)
	local dwMiniAvatarID = 0
    local nRoleType      = nil
    local dwForceID      = self.tbRulerInfo.nForceID

    UIHelper.RoleChange_UpdateAvatar(ImgPlayerIcon, dwMiniAvatarID, SFXPlayerIcon, AnimatePlayerIcon, nRoleType, dwForceID, true)
end

-----------------------------------UpdateAuthority----------------------------------

function UIWidgetTongPermissions:UpdateScrollViewMemberPermissions()
	local scriptView = UIHelper.GetBindScript(self.WidgetAnchorPermissions)
	if scriptView then
		scriptView:OnEnter(self.nGroupIndex - 1)
	end
end





-----------------------------------Data获取------------------------------------

function UIWidgetTongPermissions:GetSelectIDList()
	local tbSelectIDList = {}
	for nIndex = 1, self.nMemberNum do
		local scriptView = self.tbGroupMemberScriptView[nIndex]
		if scriptView and scriptView:GetSelected() then
			table.insert(tbSelectIDList, scriptView:GetID())
		end
	end
	return tbSelectIDList
end



return UIWidgetTongPermissions