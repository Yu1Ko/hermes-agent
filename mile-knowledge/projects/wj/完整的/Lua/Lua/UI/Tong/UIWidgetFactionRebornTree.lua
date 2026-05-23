-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetFactionRebornTree
-- Date: 2023-03-06
-- Desc: 帮会天工树
-- Prefab: PREFAB_ID.WidgetFactionRebornTree
-- ---------------------------------------------------------------------------------

local UIWidgetFactionRebornTree = class("UIWidgetFactionRebornTree")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _DonateMax = 200000
local _MaxTongFund = 1000000
local _MaxTongLevel = TongData.GetMaxLevel()
local _MaxGoods = 100000
local _tNormalColor = cc.c3b(255, 255, 255)
local _tWarnColor = cc.c3b(255, 150, 100)

local _NodeNameArr = {
	"LabelTitle",
	"BtnScreen",
	"WidgetQualityFilterPop",
	"ScrollViewMemberInformation",
    "ScrollViewMemberInformationBig",
	"WidgetItemDetail",
	"LabelTreeType",
	"LabelState",
	"LabelTreeName",
	"WidgetTreeLevelBar",
	"LayoutRebornTreeState",
	"LabelTreeUpgradeCondiction",
	"LabelTreeUpgradeCost",
	"ImgOpenMoney",
	"BtnOpen",
	"BtnUpdate",
	"ImgBarDark",
	"ImgBarLight",
	"WidgetAnchorRight",
	"WidgetScrollViewTips",
	"LabelDemesneCondiction",
	"LayoutCondiction",
    "BtnLastWeekPlan",
    "BtnLastWeekPlanSure",
    "BtnLastWeekPlanCancel",
	"LabelWeeklyExplain",
	"WidgetDownload",
}



function UIWidgetFactionRebornTree:Init(nBranchType)
	self.m = {}
	self.m.tCells = {}
	self.m.nBranchType = nBranchType
	self.m.nFilterType = 1

	local tNodes = {}
	UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _NodeNameArr)
	self.m.tNodes = tNodes

	self.m.tBranchDataArr = TongData.GetBranchData(nBranchType)
	self.m.tFilterTypeArr = TongData.GetBranchFilterTypeArr(nBranchType)

    --- 是否在预览上周方案状态
    self.m.bPreviewState = false

	self:RegEvent()
	self:BindUIEvent()

	self:UpdateUI(true)

    -- 从服务器拉取是否拥有帮会领地
    if g_pClientPlayer.dwTongID ~= 0 then
        RemoteCallToServer("On_Tong_GetTongMap", g_pClientPlayer.dwTongID)
    end
end

function UIWidgetFactionRebornTree:UnInit()
	self:UnRegEvent()
	UIHelper.RemoveFromParent(self._rootNode, true)
	self.m = nil
end

function UIWidgetFactionRebornTree:OnShow()
    -- 涅槃分支切换回来的时候初始化预览状态
    if self.m.nBranchType == 2 then
        self:SetPreviewState(false)

        self:UpdateAllCell()
        self:UpdateDetail()
    end
end

function UIWidgetFactionRebornTree:BindUIEvent()
	local tNodes = self.m.tNodes
	UIHelper.BindUIEvent(tNodes.BtnOpen, EventType.OnClick, function()
		if TongData.IsInDemesne() then
			self:OnOpenClicked()
		else
            if TongData.IsDemesnePurchased() then
                local enterTongMap = function()
                    MapMgr.CheckTransferCDExecute(function()
                        UIMgr.Close(VIEW_ID.PanelFactionManagement)
                        RemoteCallToServer("On_Tong_ToTongMapDetection")
                    end)
                end


                --地图资源下载检测拦截
                if not PakDownloadMgr.UserCheckDownloadMapRes(TongData.DEMESNE_MAP_ID, enterTongMap) then
                    return
                end

                enterTongMap()
            else
                TongData.ShowDemesneNpcMenu(tNodes.WidgetScrollViewTips)
            end
		end
	end)
	UIHelper.BindUIEvent(tNodes.BtnScreen, EventType.OnClick, function()
		self:PopupFilterMenu()
	end)

    UIHelper.BindUIEvent(tNodes.BtnLastWeekPlan, EventType.OnClick, function()
        self:PreviewUseLastWeekReornTreePlan()
    end)
    UIHelper.BindUIEvent(tNodes.BtnLastWeekPlanSure, EventType.OnClick, function()
        self:ConfirmUseLastWeekReornTreePlan()
    end)
    UIHelper.BindUIEvent(tNodes.BtnLastWeekPlanCancel, EventType.OnClick, function()
        self:QuitPreview()
    end)
end

function UIWidgetFactionRebornTree:RegEvent()
	Event.Reg(self, "SET_TONG_TECH_TREE_RESPOND", function (...)
		self:OnSetTongTechTreeRespond(...)
	end)
    Event.Reg(self, "SET_TONG_TECH_TREE_BY_LIST_RESPOND", function (tNodeList, bResult, nError)
        if self.m.nBranchType ~= 2 then
            return
        end

        self:OnUseLastWeekReornTreePlanRespond(tNodeList, bResult, nError)
    end)
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		self:UpdateAllCell()
		self:UpdateDetail()
	end)
	Event.Reg(self, "Tong_SetSelectedRebornTreeNodeID", function (nNodeID)
		local nIndex = self:NodeID2Index(nNodeID)
		if not nIndex then return end

		self.m.nSelectIndex = nIndex
		self:UpdateAllCell()
		self:UpdateDetail()
		if self.m.nSelectIndex > 15 then
			UIHelper.ScrollToBottom(self.m.tNodes.ScrollViewMemberInformation)
		end
	end)
end

function UIWidgetFactionRebornTree:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFactionRebornTree:UpdateUI(bInit)
	local tNodes = self.m.tNodes
	if bInit then
		-- title
		UIHelper.SetString(tNodes.LabelTitle, self.m.nBranchType == 1 and g_tStrings.STR_GUILD_TREE_TRUNK or g_tStrings.STR_GUILD_TREE_REBORN)

        UIHelper.SetVisible(tNodes.LabelWeeklyExplain, self.m.nBranchType == 2)

        self:SetPreviewState(false)

		--资源下载Widget
		local scriptDownload = UIHelper.GetBindScript(tNodes.WidgetDownload)
		local nPackID = PakDownloadMgr.GetMapResPackID(TongData.DEMESNE_MAP_ID)
		scriptDownload:OnInitWithPackID(nPackID)
	end
	self:UpdateList()
	if #self.m.tIDArr > 0 then
		self:OnCellClicked(1)
	else
		self:UpdateDetail()
	end
end

function UIWidgetFactionRebornTree:UpdateList()
	local tNodes = self.m.tNodes

    UIHelper.SetVisible(tNodes.ScrollViewMemberInformationBig, self.m.nBranchType == 1)
    UIHelper.SetVisible(tNodes.ScrollViewMemberInformation, self.m.nBranchType == 2)

	local list
    if self.m.nBranchType == 1 then
        list = tNodes.ScrollViewMemberInformationBig
    else
        list = tNodes.ScrollViewMemberInformation
    end

	assert(list)
	UIHelper.RemoveAllChildren(list)
	self.m.nSelectIndex = nil

	local tNodeIDArr = TongData.GetBranchData(self.m.nBranchType)
	local tIDArr = TongData.GetSearchNode(self.m.nFilterType, tNodeIDArr)
	tIDArr = TongData.SortNode(tIDArr)
	self.m.tIDArr = tIDArr
	self.m.tCells = {}
	for i, _ in ipairs(tIDArr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRebornTreeIcon, list)
		assert(cell)
		self.m.tCells[i] = cell
		self:UpdateCell(i)
	end

    UIHelper.ScrollViewDoLayout(list)
    UIHelper.ScrollToTop(list, 0, false)
end


function UIWidgetFactionRebornTree:UpdateCell(nIndex)
	local cell = self.m.tCells[nIndex]
	assert(cell)
	local nID = self.m.tIDArr[nIndex]
	assert(nID)

    local tong = GetTongClient()
    local nGroupID = tong.GetGroupID(g_pClientPlayer.dwID)
    local bHasPermission = TongData.CheckBaseOperationGroup(nGroupID, 3) -- 管理天工树
    local bHideRedPoint = not bHasPermission
	TongData.UpdateTreeCell(cell, nID, nIndex == self.m.nSelectIndex, bHideRedPoint, self.m.bPreviewState)

	UIHelper.BindUIEvent(UIHelper.FindChildByName(cell, "Button"), EventType.OnClick, function()
		self:OnCellClicked(nIndex)
	end)
end

function UIWidgetFactionRebornTree:UpdateAllCell()
	local arr = self.m.tIDArr
	for i, _ in ipairs(arr) do
		self:UpdateCell(i)
	end
end

function UIWidgetFactionRebornTree:OnCellClicked(nIndex)
	assert(nIndex)
	local nLastIndex = self.m.nSelectIndex
	if nLastIndex == nIndex then return end
	self.m.nSelectIndex = nIndex

	if nLastIndex then
		self:UpdateCell(nLastIndex)
	end

	self:UpdateCell(nIndex)
	self:UpdateDetail()
end

function UIWidgetFactionRebornTree:OnOpenClicked()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end

    local nIndex = self.m.nSelectIndex
	local nID = self.m.tIDArr[nIndex]
	assert(nID)
	local nLevel = TongData.GetNodeLevel(nID)
	local tNodeInfo = Table_GetTongTechTreeNodeInfo(nID, nLevel)
	local nNeedFund = TongData.GetTongTechTreeNodeCost(nID, nLevel + 1)

	local szText = string.format("确定要消耗%s帮会资金将[%s]升级到第%s重吗?",
		UIHelper.GetFundText(nNeedFund, 24),
		g2u(tNodeInfo.szName),
		g_tStrings.STR_NUMBER[nLevel + 1])
	UIHelper.ShowConfirm(szText, function ()
		RemoteCallToServer("OnSetTongTechTreeRequest", nID, nLevel + 1)
	end, nil, true)

end

function UIWidgetFactionRebornTree:UpdateDetail()
	local node
	local tNodes = self.m.tNodes

	local nIndex = self.m.nSelectIndex
	UIHelper.SetVisible(tNodes.WidgetAnchorRight, nIndex ~= nil)
	if not nIndex then return end

	local nID = self.m.tIDArr[nIndex]
	assert(nID)
	local nLevel = TongData.GetNodeLevel(nID)
	local nMaxLevel = TongData.GetTreeNodeMaxLevel(nID)
	local nNeedTongLevel = nLevel < nMaxLevel and TongData.GetTongTechTreeNodeLevelLimit(nID, nLevel + 1) or 0
	local nNeedFund = nLevel < nMaxLevel and TongData.GetTongTechTreeNodeCost(nID, nLevel + 1) or 0
	local nNodeType = TongData.GetNodeType(nID)
	local tTypeConfig = TongData.GetTreeTypeConfig(nNodeType)
	local tNodeInfo = Table_GetTongTechTreeNodeInfo(nID, nLevel)
	assert(tNodeInfo)

	local szIcon = TongData.GetNodeIconFrame(tNodeInfo)
	UIHelper.SetSpriteFrame(tNodes.WidgetItemDetail, szIcon)
	UIHelper.SetNodeGray(tNodes.WidgetItemDetail, nLevel == 0)

	UIHelper.SetString(tNodes.LabelTreeName, g2u(tNodeInfo.szName))
	UIHelper.SetString(tNodes.LabelTreeType, tTypeConfig.Title .. "分支")
	UIHelper.SetHeight(tNodes.ImgBarDark, (nMaxLevel - 1) * 84)
	UIHelper.SetHeight(tNodes.ImgBarLight, math.max(nLevel - 1, 0) * 84)

	UIHelper.SetVisible(tNodes.LabelDemesneCondiction, not TongData.IsInDemesne())
	UIHelper.SetVisible(tNodes.LayoutCondiction, false)
	UIHelper.SetVisible(tNodes.BtnOpen, nNeedFund > 0)
	if nNeedFund > 0 then
		local nFund = TongData.GetFund()
		local nTongLevel = TongData.GetLevel()

		UIHelper.SetVisible(tNodes.LayoutCondiction, true)
		UIHelper.SetString(tNodes.LabelTreeUpgradeCost, tostring(nNeedFund))
		UIHelper.SetColor(tNodes.LabelTreeUpgradeCost, nNeedFund <= nFund and _tNormalColor or _tWarnColor)
		UIHelper.SetString(tNodes.LabelTreeUpgradeCondiction, string.format("需要帮会等级%d级", nNeedTongLevel))
		UIHelper.SetColor(tNodes.LabelTreeUpgradeCondiction, nNeedTongLevel <= nTongLevel and _tNormalColor or _tWarnColor)

		local bEnable = not TongData.IsInDemesne()
			or (nNeedFund > 0 and nNeedFund <= nFund and nNeedTongLevel > 0 and nNeedTongLevel <= nTongLevel)
		local szLabel = not TongData.IsInDemesne() and "前往领地配置" or (nLevel == 0 and "开启" or "升级")
		UIHelper.SetEnable(tNodes.BtnOpen, bEnable)
		UIHelper.SetNodeGray(tNodes.BtnOpen, not bEnable, true)
		UIHelper.SetString(UIHelper.FindChildByName(tNodes.BtnOpen, "LabelOpen"), szLabel)
	end

	local children = UIHelper.GetChildren(tNodes.LayoutRebornTreeState)
	for i, child in ipairs(children) do
		local LabelLevelNum = UIHelper.FindChildByName(child, "LabelLevelNum")
		local LabelDetail = UIHelper.FindChildByName(child, "LabelDetail")
		local WidgetLevelDot = UIHelper.FindChildByName(tNodes.WidgetTreeLevelBar, "WidgetLevelDot0" .. i)
		UIHelper.SetVisible(LabelLevelNum, i <= nMaxLevel)
		UIHelper.SetVisible(LabelDetail, i <= nMaxLevel)
		UIHelper.SetVisible(WidgetLevelDot, i <= nMaxLevel)
		if i <= nMaxLevel then
			UIHelper.SetOpacity(LabelLevelNum, i <= nLevel and 255 or 128)
			UIHelper.SetOpacity(LabelDetail, i <= nLevel and 255 or 128)
			UIHelper.SetVisible(UIHelper.FindChildByName(WidgetLevelDot, "ImgDotLight"), i <= nLevel)
			tNodeInfo = Table_GetTongTechTreeNodeInfo(nID, i)
			UIHelper.SetRichText(LabelDetail, g2u(string.pure_text(tNodeInfo.szDesc)))
		end
	end

	-- 主干: level ==1为已开启 >1为已升级 条件够为可开启和可升级, 涅槃: level>0为已开启
	local szState = ""
	if self.m.nBranchType == 1 then
		-- 是否达到条件
		if false then
			szState = nLevel > 0 and "可升级" or "可开启"
		else
			if nLevel == 1 then
				szState = "已开启"
			elseif nLevel > 1 then
				szState = "已升级"
			end
		end
	else
		szState = nLevel > 0 and "已开启" or ""
	end
	UIHelper.SetString(tNodes.LabelState, szState)

end

function UIWidgetFactionRebornTree:NodeID2Index(nNodeID)
	for i, nID in ipairs(self.m.tIDArr) do
		if nID == nNodeID then
			return i
		end
	end
end

function UIWidgetFactionRebornTree:OnSetTongTechTreeRespond(nNodeID, nLevel, bResult, nError)
	local nIndex = self:NodeID2Index(nNodeID)
	if not nIndex then return end

	local tNodeInfo = Table_GetTongTechTreeNodeInfo(nNodeID, nLevel)
	assert(tNodeInfo)
	if bResult then
		local nCost = TongData.GetTongTechTreeNodeCost(nNodeID, nLevel)
		local szMsg = FormatString(g_tStrings.TONG_TECH_TREE_SUCCESS_COST_POINT, g2u(tNodeInfo.szName), nLevel, nCost)
		OutputMessage("MSG_SYS", szMsg)

		-- 刷新外部, 如资金数值等
		GetTongClient().ApplyTongInfo()
	else
		local szMsg = g_tStrings.tTongTechTreeError[nError]
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
	end
end

function UIWidgetFactionRebornTree:IsActived()
	return UIHelper.GetVisible(self._rootNode)
end

function UIWidgetFactionRebornTree:PopupFilterMenu()
	local tips, tScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetRebornTreeFilterPop, self.m.tNodes.BtnScreen)
	assert(tScript)
	tScript:Init(
		self.m.nBranchType,
		self.m.nFilterType,
		function (nFilterType)
			self.m.nFilterType = nFilterType
			self:UpdateUI()
		end)
end

function UIWidgetFactionRebornTree:PreviewUseLastWeekReornTreePlan()
    if self.m.nBranchType ~= 2 then
        return
    end

    local tLastWeekPlan = TongData.GetLastWeekRebornTreePlan()
    if table.get_len(tLastWeekPlan) == 0 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TONG_TECH_TREE_USE_LAST_POINT_NO_HAVE)
        return
    end

    self:SetPreviewState(true)

    self:UpdateAllCell()
    self:UpdateDetail()
end

function UIWidgetFactionRebornTree:ConfirmUseLastWeekReornTreePlan()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end

    if self.m.nBranchType ~= 2 then
        return
    end

    local nError = self:CheckUseLastWeekReornTreePlan()
    if nError > 0 then
        local szMsg = g_tStrings.tTongTechTreeError[nError]
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        return
    end

    local nCost = TongData.GetPreviewCost()
    local szTips = g_tStrings.TONG_TECH_TREE_NEED_COST .. nCost..g_tStrings.STR_TONG_TECH_TREE_USE_LAST_POINT

    UIHelper.ShowConfirm(szTips, function()
        local tLastWeekPlan = TongData.GetLastWeekRebornTreePlan()
        if table.get_len(tLastWeekPlan) == 0 then
            return
        end

        local tRequestData = TongData.GetPreviewNode()
        RemoteCallToServer("On_Tong_SetRebornNodeRequest", tRequestData)
        LOG.TABLE({
                      "使用上周数据，差异部分如下",
                      tRequestData,
                  })
    end)
end

local TONG_TECH_TREE_NODE_CLICK_SUCCESS 				= 10
local TONG_TECH_TREE_NODE_CLICK_NOT_ENOUGH_CONDITION 	= 1
local TONG_TECH_TREE_NODE_CLICK_NOT_ENOUGH_COST 		= 2
local TONG_TECH_TREE_NODE_CLICK_NOT_ENOUGH_POINT 		= 3
local TONG_TECH_TREE_NODE_CLICK_NOT_OPERATE 			= 5
local TONG_TECH_TREE_NODE_CLICK_NOT_TIME 				= 6
local TONG_TECH_TREE_NODE_CLICK_NOT_NPC					= 11
local TONG_TECH_TREE_NODE_CLICK_NOT_NODE				= 12

function UIWidgetFactionRebornTree:CheckUseLastWeekReornTreePlan()
    local nError = 0
    local TongClient = GetTongClient()
    if not TongClient then
        return -1
    end

    if not TongData.IsInDemesne() then
        nError = TONG_TECH_TREE_NODE_CLICK_NOT_NPC
    end

    local nCost = TongData.GetPreviewCost()
    if nCost > 0 and TongClient.nFund < nCost then
        nError = TONG_TECH_TREE_NODE_CLICK_NOT_ENOUGH_COST
    end

    local tNode = TongData.GetPreviewNode()
    if table.get_len(tNode) == 0 then
        nError = TONG_TECH_TREE_NODE_CLICK_NOT_NODE
    end

    return nError
end

function UIWidgetFactionRebornTree:OnUseLastWeekReornTreePlanRespond(tNodeList, bResult, nError)
    if not bResult then
        local szMsg = g_tStrings.tTongTechTreeError[nError]
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        return
    end

    local nCost = TongData.GetPreviewCost()
    local szMsg = FormatString(g_tStrings.TONG_TECH_TREE_SUCCESS_SCHEME_COST_POINT .. "\n", nCost)
    OutputMessage("MSG_SYS", szMsg)
    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

    self:SetPreviewState(false)

    local TongClient = GetTongClient()
    if TongClient then
        TongClient.ApplyTongInfo()
    end
end

function UIWidgetFactionRebornTree:QuitPreview()
    if self.m.nBranchType ~= 2 then
        return
    end

    self:SetPreviewState(false)

    self:UpdateAllCell()
    self:UpdateDetail()

    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TONG_TECH_TREE_USE_LAST_POINT_NO_EFFECT)
end

function UIWidgetFactionRebornTree:SetPreviewState(bPreviewState)
    self.m.bPreviewState = bPreviewState

    local tNodes = self.m.tNodes

    UIHelper.SetVisible(tNodes.BtnLastWeekPlan, self.m.nBranchType == 2 and not bPreviewState)

    UIHelper.SetVisible(tNodes.BtnLastWeekPlanSure, self.m.nBranchType == 2 and bPreviewState)
    UIHelper.SetVisible(tNodes.BtnLastWeekPlanCancel, self.m.nBranchType == 2 and bPreviewState)
end

return UIWidgetFactionRebornTree

