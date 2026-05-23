-- ---------------------------------------------------------------------------------
-- Name: UIPanelNominateConductor
-- Desc: 分配本周攻防指挥页面
-- Prefab:PanelNominateConductor
-- ---------------------------------------------------------------------------------
local UIPanelNominateConductor = class("UIPanelNominateConductor")

-- ---------------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------------
local DataModel = {}
local tEditCommanderEndTime = {
	[1] = {["weekday"] = 6, ["hour"] = 12, ["minute"] = 0},--第一场指挥
	[2] = {["weekday"] = 6, ["hour"] = 18, ["minute"] = 0},
	[3] = {["weekday"] = 7, ["hour"] = 12, ["minute"] = 0},
	[4] = {["weekday"] = 7, ["hour"] = 18, ["minute"] = 0},
}

local function EarlierThan(LValue, RValue)
	LValue.weekday = LValue.weekday == 0 and 7 or LValue.weekday
	RValue.weekday = RValue.weekday == 0 and 7 or RValue.weekday

	if LValue.weekday < RValue.weekday then
		return true
	elseif LValue.weekday > RValue.weekday then
		return false
	else
		if LValue.hour < RValue.hour then
			return true
		elseif LValue.hour > RValue.hour then
			return false
		else
			if LValue.minute > RValue.minute then
				return false
			else
				return true
			end
		end
	end
end

function DataModel.Init(tPlayer)
	-- DataModel.tGroupMember  = {}
    -- DataModel.tIDToName = {}
	-- DataModel.tIDToForceID = {}
	DataModel.tInfo = {}
	DataModel.tCurCmdSetting = {}
    DataModel.tCanEdit = {}
	DataModel.InitGroupMember(tPlayer)
	DataModel.InitCommanderSetting()
	DataModel.InitEditStatus()
end

function DataModel.InitGroupMember(tPlayer)
	for dwID, tAllInfo in pairs(tPlayer) do
		if tAllInfo.tNumberInfo.DeputyInfo[6] == TEAM_MEMBER_TYPE.leader or tAllInfo.tNumberInfo.DeputyInfo[6] == TEAM_MEMBER_TYPE.member then
			-- DataModel.tGroupMember[tAllInfo.tStringInfo.szName] = dwID
			-- DataModel.tIDToName[dwID] = tAllInfo.tStringInfo.szName
			-- DataModel.tIDToForceID[dwID] = tAllInfo.tStringInfo.nForceID
			DataModel.tInfo[dwID] = {}
			DataModel.tInfo[dwID].dwID = dwID
			DataModel.tInfo[dwID].szName = tAllInfo.tStringInfo and tAllInfo.tStringInfo.szName
			DataModel.tInfo[dwID].nForceID = tAllInfo.tStringInfo and tAllInfo.tStringInfo.nForceID
		end
	end
end

function DataModel.GetGroupMember()
	return DataModel.tGroupMember
end

function DataModel.InitCommanderSetting()
	local CP = GetCampPlantManager()
	local j = 1
	local dwID
	local tCurCmdSetting = {}
	for i = 16, 19 do
		dwID = CP.GetCustomData(0, i)
		if dwID ~= 0 then 
			DataModel.tCurCmdSetting[j] = dwID
			tCurCmdSetting[j] = dwID
			j = j + 1
		end
	end
	return tCurCmdSetting
end

function DataModel.GetCurCmdSetting()
	return DataModel.tCurCmdSetting
end

function DataModel.GetPlayerName(dwID)
	return DataModel.tIDToName[dwID]
end

function DataModel.GetPlayerForceID(dwID)
	return DataModel.tIDToForceID[dwID]
end

function DataModel.SetEditState(bEditable, nIndex)
    DataModel.tCanEdit[nIndex] = bEditable
end

function DataModel.GetEditStatu(nIndex)
	return DataModel.tCanEdit[nIndex]
end

function DataModel.InitEditStatus()
	local tCurrentTime = TimeToDate(GetCurrentTime())

	for i = 1, 4 do
        DataModel.SetEditState(true, i)
	end

    local dwID = GetClientPlayer().dwID
    local bTeamMember = CommandBaseData.tPlayerInfo and CommandBaseData.tPlayerInfo[dwID] and 
		CommandBaseData.tPlayerInfo[dwID]["tNumberInfo"]["DeputyInfo"][6]

	if bTeamMember ~= TEAM_MEMBER_TYPE.leader then
		for i = 1, 4 do
			DataModel.SetEditState(false, i)
		end
		return
	end

	if EarlierThan(tCurrentTime, tEditCommanderEndTime[1]) then
		return
	elseif EarlierThan(tCurrentTime, tEditCommanderEndTime[2]) then
		DataModel.SetEditState(false, 1)
		return
	elseif EarlierThan(tCurrentTime, tEditCommanderEndTime[3]) then
		for i = 1, 2 do
			DataModel.SetEditState(false, i)
		end
		return
	elseif EarlierThan(tCurrentTime, tEditCommanderEndTime[4]) then
		for i = 1, 3 do
			DataModel.SetEditState(false, i)
		end
		return
	else
		for i = 1, 4 do
			DataModel.SetEditState(false, i)
		end
		return
	end
end

-- ---------------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------------

function UIPanelNominateConductor:_LuaBindList()
    self.BtnClose                     = self.BtnClose

	self.WidgetTogNominateConductor   = self.WidgetTogNominateConductor -- 四个tog数组 包含以下四个
    self.WidgetTogNominateConductor01 = self.WidgetTogNominateConductor01 -- 第1场tog widget
    self.WidgetTogNominateConductor02 = self.WidgetTogNominateConductor02 -- 第2场tog widget
    self.WidgetTogNominateConductor03 = self.WidgetTogNominateConductor03 -- 第3场tog widget
    self.WidgetTogNominateConductor04 = self.WidgetTogNominateConductor04 -- 第4场tog widget

    self.WidgetAnchorRight            = self.WidgetAnchorRight -- 右侧弹出widget WidgetChooseConductor
end

function UIPanelNominateConductor:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
	self:UpdateInfo()
end

function UIPanelNominateConductor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelNominateConductor:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelNominateConductor:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        local bVisible = UIHelper.GetVisible(self.rightScript._rootNode)
		if bVisible then
			UIHelper.SetVisible(self.rightScript._rootNode, false)
			self.rightScript:Hide()
		end
		if self.tScriptCell then
			for _, script in pairs(self.tScriptCell) do
				script:SetSelectedRaw(false)
			end
		end
    end)
end

function UIPanelNominateConductor:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelNominateConductor:UpdateInfo()
	CommandBaseData.InitManagerList()
	DataModel.Init(CommandBaseData.tPlayerInfo)
	self:InitTogCell()
	self:UpdateTogCell()
	self.rightScript = UIHelper.AddPrefab(PREFAB_ID.WidgetChooseConductor, self.WidgetAnchorRight)
	UIHelper.SetVisible(self.rightScript._rootNode, false)
	self.rightScript:SetClickCallBack(function(nIndex, dwID)
		self:UpdateTogCellSingle(nIndex, dwID)
	end)
end

function UIPanelNominateConductor:InitTogCell()
	self.tScriptCell = {}
	for nIndex, widget in ipairs(self.WidgetTogNominateConductor) do
		local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogNominateConductor, widget)
		assert(script)
		self.tScriptCell[nIndex] = script
		script:SetIndex(nIndex)
		script:SetEditState(DataModel.GetEditStatu(nIndex))
		script:SetSelectedRaw(false)
		script:SetClickCallBack(function(index)
			self:ShowRightPop(index)
		end)
	end
end

function UIPanelNominateConductor:UpdateTogCell()
	local tSetting = DataModel.InitCommanderSetting()
	for nIndex = 1, 4 do
		local dwID = tSetting[nIndex]
		self:UpdateTogCellSingle(nIndex, dwID)
	end
end

function UIPanelNominateConductor:UpdateTogCellSingle(nIndex, dwID)
	local script = self.tScriptCell[nIndex]
	assert(script)

	if dwID then
		local tInfo = DataModel.tInfo[dwID]
		script:UpdateInfo(tInfo)
	else
		script:UpdateInfo()
	end
end

function UIPanelNominateConductor:ShowRightPop(nIndex)
	local tInfo = DataModel.tInfo
	if self.nBeforeID then
		self.tScriptCell[self.nBeforeID]:SetSelectedRaw(false)
	end
	self.nBeforeID = nIndex

	local tSetting = DataModel.InitCommanderSetting()
	local dwID = tSetting and tSetting[nIndex]
	self.rightScript:UpdateInfo(nIndex, dwID, tInfo)
	UIHelper.SetVisible(self.rightScript._rootNode, true)
end

return UIPanelNominateConductor