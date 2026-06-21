-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelTongManager
-- Date: 2023-01-05
-- Desc: 帮会管理主界面
-- Prefab: PanelFactionManagement
-- ---------------------------------------------------------------------------------

---@class UIPanelTongManager
local UIPanelTongManager = class("UIPanelTongManager")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelTongManager:_LuaBindList()
    self.BtnClose                = self.BtnClose --- 关闭按钮
    self.BtnFactionActivityDetailReturn = self.BtnFactionActivityDetailReturn --- 返回帮会活动列表按钮（活动详情页时替换关闭按钮出现）
end

function UIPanelTongManager:OnEnter()
	self.m = {}
	self.m.tSubScripts = {}

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:InitInfo()
	self:InitMainTab()

    if not TongData.bUpdateActivity then
        Timer.AddFrame(self, 8, function()
            -- 与端游一样，打开帮会界面后，若 bUpdateActivity 未设置，则8帧后尝试重新更新活动数据
            RemoteCallToServer("On_Tong_GetActivityTimeRequest")
        end)
    end
end

function UIPanelTongManager:OnExit()
	self.bInit = false
	self:UnRegEvent()

	self:UnInitMainTab()
	self:UnInitSubTab()

	UIHelper.ClearTouchLikeTips()

    TongData.bUpdateActivity = nil

	self.m = nil
end

function UIPanelTongManager:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		self:Close()
	end)
    UIHelper.BindUIEvent(self.BtnFactionActivityDetailReturn, EventType.OnClick, function()
        Event.Dispatch(EventType.OnClickBtnFactionActivityDetailReturn)
    end)

	self.ToggleGroupNavigation:addEventListener(function (toggle, nIndexBaseZero)
		self:SwitchMainTab(nIndexBaseZero + 1)
    end)
    self.ToggleGroupTab:addEventListener(function (toggle, nIndexBaseZero)
		print("-------------",UIHelper.GetSelected(toggle))
		self:SwitchSubTab(nIndexBaseZero + 1)
    end)
    self.ToggleGroupRecordTab:addEventListener(function (toggle, nIndexBaseZero)
		self:SwitchRecordTab(nIndexBaseZero + 1)
    end)
	local layout = UIHelper.GetParent(self.LabelMemberFundNum)
	UIHelper.BindUIEvent(layout, EventType.OnClick, function()
		CurrencyData.ShowCurrencyHoverTips(layout, CurrencyType.TotalGangFunds)
    end)
    UIHelper.SetTouchEnabled(layout, true)
end

function UIPanelTongManager:RegEvent()
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		self:InitInfo()
        
        self:CheckForceRenameTongName()
	end)
	Event.Reg(self, "CHANGE_TONG_NOTIFY", function ()
		if arg1 == TONG_CHANGE_REASON.DISBAND
		or arg1 == TONG_CHANGE_REASON.QUIT
		or arg1 == TONG_CHANGE_REASON.FIRED
		then
			self:Close()
	 	end
	end)
	Event.Reg(self, "TONG_MASTER_CHANGE", function ()
		TongData.RequestBaseData()
	end)
	Event.Reg(self, "TONG_MASTER_CHANGE_START", function ()
		TongData.RequestBaseData()
	end)
	Event.Reg(self, "TONG_MASTER_CHANGE_CANCEL", function ()
		TongData.RequestBaseData()
	end)
	Event.Reg(self, "ON_TONG_ADD_TONGLEVEL", function ()
		TongData.RequestBaseData()
		RemoteCallToServer("OnSyncTongCustomData")
	end)
	Event.Reg(self, "Tong_SwitchTab", function (nMainTab, nSubTab, ...)
		UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, nMainTab - 1)
		UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, nSubTab - 1)

		-- 天工树
		if nMainTab == 3 then
			Event.Dispatch("Tong_SetSelectedRebornTreeNodeID", ...)
		end
	end)

    Event.Reg(self, "SwitchToTongActivityPage", function(nClassID)
        -- 活动页
        local nActivityTab = 5

        UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, nActivityTab - 1)
        self:SwitchMainTab(nActivityTab)

        Timer.AddFrame(self, 8, function()
            self.m.tMainScript:ScrollToClass(nClassID)
        end)
    end)

    Event.Reg(self, EventType.TongClickOpenActivity, function()
        -- 点击开启活动后，由于没有是否开启成功的事件，为了确保界面刷新，这里关闭下界面，让玩家自己重新打开
        UIMgr.Close(self)
    end)
    
    Event.Reg(self, EventType.SwitchFactionSpecificActivityShowStatus, function(bShow)
        --- 根据是否在帮会活动详情页，确定是否要替换右上角的关闭按钮为返回活动列表按钮
        UIHelper.SetVisible(self.BtnClose, not bShow)
        UIHelper.SetVisible(self.BtnFactionActivityDetailReturn, bShow)
    end)
end

function UIPanelTongManager:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTongManager:InitInfo()
    -- 挪到 WidgetlFactionMain 中了
    UIHelper.SetVisible(self.BtnApplicationList, false)

	-- 阵营
	UIHelper.SetString(self.LabelCamp, g_tStrings.STR_CAMP_TITLE[TongData.GetCamp()])
	-- 等级
	local nLevel = TongData.GetLevel()
	local nMaxLevel = TongData.GetMaxLevel()
	--UIHelper.SetProgressBarPercent(self.ProgressBarLevel, nLevel * 100 / nMaxLevel)
 	UIHelper.SetString(self.LabelLevel, string.format("%d/%d", nLevel, nMaxLevel))
	-- 资金
	UIHelper.SetString(self.LabelMemberFundNum, tostring(TongData.GetFund()))
	UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelMemberFundNum))

    -- 右上角的最上层layout排版下，避免资金数目变动好几位时会错位
    UIHelper.LayoutDoLayout(self.WidgetContentRightTop)
end

function UIPanelTongManager:InitMainTab()
	local root = self.LayoutNavigation
	assert(root)

	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupNavigation)
	local children = UIHelper.GetChildren(root)
	for i, child in ipairs(children) do
		if child.isTouchEnabled then
			UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, child)
		end
	end

	-- 先隐藏SubTab
	UIHelper.SetVisible(self.LayoutTab, false)

	--
	self:SwitchMainTab(1)
end

local _tTabConfig = {
	-- 总览
	{ 	Prefab = "WidgetlFactionMain" },
	-- 管理
	{
		Prefab = function(self)
			local tScript = {}
			tScript.Init = function(self)
			end
			tScript.UnInit = function(self)
				UIHelper.RemoveAllChildren(self.WidgetAnchorMid)
			end
			return tScript
		end,
		tSubTab = {
			{Title = "成员信息", Prefab = "WidgetFactionManagementMember"},
			{Title = "帮会信息", Prefab = "WidgetFactionManagementFaction"},
			{Title = "权限管理", Prefab = "WidgetFactionManagementPermissions"},
			{Title = "资金管理", Prefab = "WidgetFactionManagementMoney"},
			{Title = "帮会记录", Prefab = "WidgetFactionManagementRecord"},
		},
	},
	-- 天工树
	{
		Prefab = function(self)
			local tScript = {}
			tScript.Init = function(self)
			end
			tScript.UnInit = function(self)
				UIHelper.RemoveAllChildren(self.WidgetAnchorMid)
			end
			return tScript
		end,
		tSubTab = {
			{Title = "主干", Prefab = "WidgetFactionRebornTree" },
			{Title = "涅槃", Prefab = "WidgetFactionRebornTree" },
		},
	},
	-- 外交
	{
		Prefab = function(self)
			local tScript = {}
			tScript.Init = function(self)
			end
			tScript.UnInit = function(self)
				UIHelper.RemoveAllChildren(self.WidgetAnchorMid)
			end
			return tScript
		end,
		tSubTab = {
			{Title = "帮会宣战", Prefab = "WidgetFactionWar" },
			{Title = "帮会约战", Prefab = "WidgetFactionCompetition" },
			{Title = "帮会同盟", Prefab = "WidgetLeagueFaction" },
		},
	},
	-- 活动
	{ 	Prefab = "WidgetFactionActivity" },
}
local _tSubTabNodeNameArr = {
	"LabelNormal",
	"LabelUp",
}
local _tSubTabNodes = {}
function UIPanelTongManager:InitSubTab(nMainIndex)
	local root = self.ScrollViewContent
	assert(root)
	local tCfg = _tTabConfig[nMainIndex]
	if not tCfg or not tCfg.tSubTab then
		UIHelper.SetVisible(root, false)
		return
	end
	UIHelper.SetVisible(root, true)

	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupTab)
	local children = UIHelper.GetChildren(root)
	local nIndex = 1
	for _, child in ipairs(children) do
		if child.isTouchEnabled then
			local tSubCfg = tCfg.tSubTab[nIndex]
			if tSubCfg then
				UIHelper.SetVisible(child, true)
				UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, child)

				UIHelper.FindNodeByNameArr(child, _tSubTabNodes, _tSubTabNodeNameArr)
				UIHelper.SetString(_tSubTabNodes.LabelNormal, tSubCfg.Title)
				UIHelper.SetString(_tSubTabNodes.LabelUp, tSubCfg.Title)
			else
				UIHelper.SetVisible(child, false)
			end
			---[[ 支持响应重复点击
				local btnForToggle = UIHelper.FindChildByName(child, "BtnForToggle")
				if btnForToggle then
					local nClickIndex = nIndex
					UIHelper.BindUIEvent(btnForToggle, EventType.OnClick, function()
						UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, nClickIndex - 1)
					end)
				end
			--]]

			nIndex = nIndex + 1
		end
	end
	UIHelper.ScrollViewDoLayout(root)
	UIHelper.ScrollToTop(root, 0, false)

	-- 默认选中
	self.m.nCurSubIndex = nil
	self:SwitchSubTab(1)
end

function UIPanelTongManager:UnInitSubTab()
	local tScripts = self.m.tSubScripts
	repeat
		local k, tScript = next(tScripts)
		if not tScript then break end
		tScript:UnInit()
		tScripts[k] = nil
	until false

	UIHelper.SetVisible(self.LayoutTab, false)
end

function UIPanelTongManager:UnInitMainTab()
	-- 清理
	if self.m.tMainScript then
		self.m.tMainScript:UnInit()
		self.m.tMainScript = nil
	end
end

function UIPanelTongManager:SwitchMainTab(nMainIndex)
	if nMainIndex == self.m.nCurMainIndex then return end
	self.m.nCurMainIndex = nMainIndex

	-- 清理
	self:UnInitMainTab()

	-- 创建当前script
	local tScript = self:CreateMainScript(nMainIndex)
	assert(tScript)
	tScript:Init()
	self.m.tMainScript = tScript

	-- 重置SubTab
	self:UnInitSubTab()
	self:InitSubTab(nMainIndex)
end

function UIPanelTongManager:CreateMainScript(nMainIndex)
	local tCfg = _tTabConfig[nMainIndex]
	assert(tCfg)
	local tScript
	if type(tCfg.Prefab) == "function" then
		tScript = tCfg.Prefab(self)
	else
		tScript = UIHelper.AddPrefab(PREFAB_ID[tCfg.Prefab], self.WidgetAnchorMid)
	end
	assert(tScript, "fail to create srcipt by: " .. nMainIndex)

	return tScript
end

function UIPanelTongManager:SwitchSubTab(nSubIndex)
	if nSubIndex ~= self.m.nCurSubIndex then
		self.m.nCurSubIndex = nSubIndex

		local tSubScripts = self.m.tSubScripts
		-- 隐藏非当前
		for i, tScript in pairs(tSubScripts) do
			if i ~= nSubIndex then
				UIHelper.SetVisible(tScript._rootNode, false)
			end
		end
		-- 显示当前
		local tScript = tSubScripts[nSubIndex]
		if not tScript then
			tScript = self:CreateSubScript(self.m.nCurMainIndex, nSubIndex)
			tScript:Init(nSubIndex)
			tSubScripts[nSubIndex] = tScript
		end
		UIHelper.SetVisible(tScript._rootNode, true)
		if tScript.OnShow then
			tScript:OnShow()
		end
	end

	-- 帮会记录特殊处理
	if nSubIndex == 5 and not self.m.bShowTongRecord then
		self:InitTongRecordTab()
	else
		self:UnInitTongRecordTab(nSubIndex)
	end

end

function UIPanelTongManager:InitTongRecordTab()
	local list = self.ScrollViewContent
	UIHelper.SetVisible(self.LayoutChildNavigation, true)
	UIHelper.SetVisible(self.ImgNavigationLine, true)
	UIHelper.SetVisible(self.WidgettImgFoldTree, false)
	UIHelper.SetVisible(self.AniLoop, true)
	UIHelper.SetVisible(self.Eff_MenuSelect, false)
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToBottom(list, 0, false)

	UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupRecordTab)
	local children = UIHelper.GetChildren(self.LayoutChildNavigation)
	for i, child in ipairs(children) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroupRecordTab, child)
	end
	UIHelper.SetToggleGroupSelected(self.ToggleGroupRecordTab, (self.m.nRecordTabIndex or 1) - 1)

	self.m.bShowTongRecord = true
end

function UIPanelTongManager:UnInitTongRecordTab(nSubIndex)
	local list = self.ScrollViewContent
	UIHelper.SetVisible(self.LayoutChildNavigation, false)
	UIHelper.SetVisible(self.ImgNavigationLine, false)
	UIHelper.SetVisible(self.WidgettImgFoldTree, true)
	UIHelper.SetVisible(self.Eff_MenuSelect, nSubIndex == 5)
	UIHelper.SetVisible(self.AniLoop, false)
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)

	self.m.bShowTongRecord = false
end

function UIPanelTongManager:SwitchRecordTab(nIndex)
	self.m.nRecordTabIndex = nIndex
	Event.Dispatch("SwitchTongRecordTab", nIndex)
end

function UIPanelTongManager:CreateSubScript(nMainIndex, nSubIndex)
	local tMainCfg = _tTabConfig[nMainIndex]
	assert(tMainCfg)
	local tSubCfg = tMainCfg.tSubTab[nSubIndex]
	assert(tSubCfg)
	local szPrefab = tSubCfg.Prefab
	assert(szPrefab)
	local tScript = UIHelper.AddPrefab(PREFAB_ID[szPrefab], self.WidgetFactionSub)
	assert(tScript, "fail to create sub script: " .. szPrefab)
	return tScript
end

function UIPanelTongManager:Close()
	UIMgr.Close(self)
end

function UIPanelTongManager:CheckForceRenameTongName()
    local player = GetClientPlayer()
    local guild = GetTongClient()

    if not player or not guild then
        return
    end

    if guild.dwMaster == player.dwID and string.find(guild.szTongName, "@") then
        Timer.Add(self, 1.5, function()
            UIMgr.Open(VIEW_ID.PanelConstraintRenamePop)
        end)
    end
end


return UIPanelTongManager