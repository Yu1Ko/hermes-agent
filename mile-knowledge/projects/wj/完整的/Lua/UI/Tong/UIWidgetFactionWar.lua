-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetFactionWar
-- Date: 2023-03-06
-- Desc: 帮会外交宣战
-- Prefab: PREFAB_ID.WidgetFactionWar
-- ---------------------------------------------------------------------------------

local UIWidgetFactionWar = class("UIWidgetFactionWar")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _NodeNameArr = {
	"BtnBefightList",
	"EditBox",

    "LayoutType",
    "ToggleGroupType",
    "LayoutTime",
	"ToggleGroupTime",

    "LabelCDTime",
	"LabelCostDifferent",
	"LabelCostSame",
    "ImgStateNormal",

	"WidgetFightState",
	"LabelFactionName",
	"LabelFightState",
	"LabelFightLength",
    "ImgStateFight",

	"BtnComfirm",
	"TogFightRules",
	"WidgetTips01",

}



function UIWidgetFactionWar:Init()
	self.m = {}
	self.m.nTimeType = 1
	self.m.szTargetName = ""
	self.m.nNextDiplomacyWarTime = TongData.GetNextDiplomacyWarTime()

	local tNodes = {}
	UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _NodeNameArr)
	self.m.tNodes = tNodes

	self:RegEvent()
	self:BindUIEvent()

	self.m.nCallID = Timer.AddDelayCycle(self, 1, 0.3, function ()
		self:Update()
	end)

	self:UpdateUI(true)
end

function UIWidgetFactionWar:UnInit()
	self:UnRegEvent()

	if self.m.nCallID then
		Timer.DelTimer(self, self.m.nCallID)
		self.m.nCallID = nil
	end

	UIHelper.RemoveFromParent(self._rootNode, true)
	self.m = nil
end

function UIWidgetFactionWar:BindUIEvent()
	local tNodes = self.m.tNodes
	UIHelper.BindUIEvent(tNodes.BtnComfirm, EventType.OnClick, function()
		local szText = FormatString(g_tStrings.GUILD_DIPLOMACY_SURE, self.m.szTargetName)
		UIHelper.ShowConfirm(szText, function ()
			self:RequestDeclareWar()
		end)
	end)
	UIHelper.BindUIEvent(tNodes.BtnBefightList, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelBefightListPop)
	end)
	UIHelper.BindUIEvent(tNodes.TogFightRules, EventType.OnClick, function()
		UIHelper.SetTouchLikeTips(tNodes.WidgetTips01, UIMgr.GetLayer(UILayer.Page), function ()
			UIHelper.SetSelected(tNodes.TogFightRules, false)
		end)
	end)

	UIHelper.RegisterEditBoxEnded(tNodes.EditBox, function()
		self.m.szTargetName = UIHelper.GetText(tNodes.EditBox)
		self:UpdateUI()
	end)

    tNodes.ToggleGroupType:addEventListener(function (toggle, nIndexBaseZero)
        -- todo: 需要新增支持领地宣战，稍后处理
        self.m.nType = nIndexBaseZero + 1
        self:UpdateUI()
    end)

	tNodes.ToggleGroupTime:addEventListener(function (toggle, nIndexBaseZero)
		self.m.nTimeType = nIndexBaseZero + 1
		self:UpdateUI()
    end)

end

function UIWidgetFactionWar:RegEvent()
	Event.Reg(self, "ON_TONG_WAR_COST_RESPOND", function ()
		self:UpdateUI()
	end)
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		local nNextTime = TongData.GetNextDiplomacyWarTime()
		-- 有新的CD产生表明操作成功
		if nNextTime ~= self.m.nNextDiplomacyWarTime then
			self.m.nNextDiplomacyWarTime = nNextTime
			local tData = Storage.Tong.WarData
			local tParamArr = TongData.GetDeclarationParam()
			local tParam = tParamArr[self.m.nTimeType]
			tData.szTargetName = self.m.szTargetName
			tData.nWarEndTime =  tParam.time * 60 * 60 + GetCurrentTime()
		end
		self:UpdateUI()
	end)

end

function UIWidgetFactionWar:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFactionWar:Update()
	self:UpdateTime()
end

function UIWidgetFactionWar:RequestDeclareWar()
	local szTargetName = self.m.szTargetName
	local nTimeType = self.m.nTimeType
    local tParamArr = TongData.GetDeclarationParam()
	local tParam = tParamArr[nTimeType]
	assert(tParam)

    RemoteCallToServer("On_Tong_DeclareWarRequest", u2g(szTargetName), tParam.nIndex)
end

function UIWidgetFactionWar:UpdateUI(bInit)
	local tNodes = self.m.tNodes
	if bInit then
        do
            -- type group
            UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupType)
            local children = UIHelper.GetChildren(tNodes.LayoutType)
            for _, child in ipairs(children) do
                if child.isTouchEnabled then
                    UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupType, child)
                end
            end
            UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupType, 0)
        end

        do
            -- time group
            UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupTime)
            local children = UIHelper.GetChildren(tNodes.LayoutTime)
            for _, child in ipairs(children) do
                if child.isTouchEnabled then
                    UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupTime, child)
                end
            end
            UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupTime, 0)
        end

		-- editbox
		UIHelper.SetText(tNodes.EditBox, self.m.szTargetName)
	end

	self:UpdateTime()
	self:UpdateWarState()
	self:UpdateDevelopmentPoint()
	self:UpdateDeclarationBtn()

end

function UIWidgetFactionWar:OnShow()
	self:UpdateUI()
end

function UIWidgetFactionWar:UpdateWarState()
	local tNodes = self.m.tNodes
	local tWarData = Storage.Tong.WarData

	local now = GetCurrentTime()
	local nLeftTime = math.max((tWarData.nWarEndTime or 0) - now, 0)

    local bInFight = nLeftTime > 0
    UIHelper.SetVisible(tNodes.WidgetFightState, bInFight)
    UIHelper.SetVisible(tNodes.ImgStateFight, bInFight)
    UIHelper.SetVisible(tNodes.ImgStateNormal, not bInFight)

	if nLeftTime > 0 then
		local szTime = TongData.GetTimeText(nLeftTime)
		UIHelper.SetString(tNodes.LabelFightLength, szTime)
		UIHelper.SetString(tNodes.LabelFactionName, tWarData.szTargetName)
	end

end

function UIWidgetFactionWar:UpdateTime()
	local tNodes = self.m.tNodes
	do
		local nCDTime = TongData.GetWarCDTime()
		if nCDTime ~= self.m.nCDTime then
			self.m.nCDTime = nCDTime
			local szTime = TongData.GetTimeText(nCDTime)
			UIHelper.SetString(tNodes.LabelCDTime, szTime)
			if nCDTime == 0 then
				self:UpdateDeclarationBtn()
				RemoteCallToServer("On_Tong_TongWarCost") --> ON_TONG_WAR_COST_RESPOND
			end
		end
	end

	do
		if UIHelper.GetVisible(tNodes.WidgetFightState) then
			local nWarEndTime = Storage.Tong.WarData.nWarEndTime or 0
			local nLeftTime = math.max(nWarEndTime - GetCurrentTime(), 0)
			if nLeftTime ~= self.m.nWarLeftTime then
				self.m.nWarLeftTime = nLeftTime
				local szTime = TongData.GetTimeText(nLeftTime)
				UIHelper.SetString(tNodes.LabelFightLength, szTime)
			end
		end
	end

end

function UIWidgetFactionWar:UpdateDeclarationBtn()
	local tNodes = self.m.tNodes
	local guild = GetTongClient()
	local player = g_pClientPlayer
	if player and guild then
		local szText = self.m.szTargetName
		local nLeftTime = TongData.GetWarCDTime()
		local info = guild.GetMemberInfo(player.dwID)
		local bEnable = info and guild.CanBaseOperate(info.nGroupID, TONG_OPERATION_INDEX.DIPLOMACY)
			and szText and szText ~= ""
			and nLeftTime == 0
		UIHelper.SetEnable(tNodes.BtnComfirm, bEnable)
		UIHelper.SetNodeGray(tNodes.BtnComfirm, not bEnable, true)
	end
end

function UIWidgetFactionWar:UpdateDevelopmentPoint()
	local tNodes = self.m.tNodes
	local tParamArr = TongData.GetDeclarationParam()
	local tParam = tParamArr[self.m.nTimeType]
	assert(tParam)
	UIHelper.SetString(tNodes.LabelCostDifferent, tostring(tParam.cost))
	UIHelper.SetString(tNodes.LabelCostSame, tostring(tParam.cost1))
end

return UIWidgetFactionWar

