HomelandIdentity = HomelandIdentity or {className = "HomelandIdentity"}
local self = HomelandIdentity
local tFishSkillGroup = {[0] = 1111, 1111, 1141, 1141, 1141, 1141, 1142, 1142, 1142, 1143, 1143, 1143, 1144, 1144, 1144, 1144, 1144}--钓鱼等级和动态技能栏
local HLIDENTITY =
{
	FISH   = 1, --渔夫
	FLOWER = 2, --花匠
	COOK   = 3, --掌柜
}
local TOY_TYPE = {
	NORMAL = 1,
	COUNT = 2,
	LEVEL = 3,
	COMPOSITE = 4,
}
local tToyInfo = {
    [76] = {dwIdentityID = HLIDENTITY.FLOWER, nLevel = 3},
    [85] = {dwIdentityID = HLIDENTITY.COOK, nLevel = 5},
}

local CD_FISH = 2773

-- Form scripts\Map\家园身份\掌柜\include\掌柜_data.lua
local tPackgeList = { --交订单的对应道具信息
	[34924] = 66089,
	[34925] = 66090,
	[34926] = 66091,
	[34927] = 66092,
	[34928] = 66093,
	[34929] = 66094,
	[34930] = 66095,
	[34931] = 66096,
	[34932] = 66097,
	[35111] = 66278,
	[35112] = 66279,
	[35113] = 66280,
	[35114] = 66281,
	[35120] = 66282,
	[35121] = 66283,
	[35122] = 66284,
	[35123] = 66285,
	[35129] = 66286,
	[35130] = 66287,
	[35131] = 66288,
	[35132] = 66289,
	[35138] = 66290,
	[35139] = 66291,
	[35140] = 66292,
	[35141] = 66293,
	[35147] = 66294,
	[35148] = 66295,
	[35149] = 66296,
	[35150] = 66297,
	[35156] = 66298,
	[35157] = 66299,
	[35158] = 66300,
	[35159] = 66301,
	[35165] = 66302,
	[35166] = 66303,
	[35167] = 66304,
	[35168] = 66305,
}
function HomelandIdentity.Init()
	self.tbAssistOrderList = {}
	self.RegEvent()
end

function HomelandIdentity.UnInit()
	self.tbAssistOrderList = nil
end

function HomelandIdentity.RegEvent()
	Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function(bEnter, nGroupID)
		if not table.contain_value(tFishSkillGroup, nGroupID) then
			UIMgr.Close(VIEW_ID.PanelFish)
			return
		end
		if bEnter then
			if UIMgr.IsViewOpened(VIEW_ID.PanelFish) then
				local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelFish)
				scriptView:Init()
			else
				UIMgr.Open(VIEW_ID.PanelFish, nGroupID)
			end
		end
    end)

	Event.Reg(self, EventType.OnViewClose, function (nViewID)
		if nViewID ~= VIEW_ID.PanelFish then
			return
		end

		local player = g_pClientPlayer
		if player then
			-- 保证在退出钓鱼界面时退出钓鱼状态
			local nGroupID = player.GetDynamicSkillGroup()
			if table.contain_value(tFishSkillGroup, nGroupID) then
				player.SetDynamicSkillGroup(0)
			end
		end
	end)
end

function HomelandIdentity.MarkChatOrder(tbInfo, dwTalkerID)
	tbInfo.nMarkTime = GetCurrentTime()
	if not dwTalkerID then
		return
	end
	self.tbAssistOrderList[dwTalkerID] = tbInfo

	-- self.nClearTimerID = self.nClearTimerID or Timer.AddCycle(self, 300, function ()
	-- 	local nCurTime = GetCurrentTime()
	-- 	for key, tOrder in pairs(self.tbAssistOrderList) do
	-- 		if (nCurTime - tbInfo.nMarkTime) > 240 then
	-- 			self.tbAssistOrderList[key] = nil
	-- 		end
	-- 	end
	-- end)
end

function HomelandIdentity.GetChatOrder(dwTalkerID)
	local tbOrder = self.tbAssistOrderList[dwTalkerID] or {}
	return tbOrder
end

-- 家园身份相关
-------------------------------- Public --------------------------------
function HomelandIdentity.OpenPanelHomeOrder(nOwnerID, nTypeIndex)
	local pHomelandMgr = GetHomelandMgr()
    if not pHomelandMgr then
        OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
        return
    end

    local tLandHash    = pHomelandMgr.GetAllMyLand()
    local tPrivateHash = pHomelandMgr.GetAllMyPrivateHome()
    if IsTableEmpty(tLandHash) and IsTableEmpty(tPrivateHash) then
		if UIMgr.IsViewOpened(VIEW_ID.PanelHome) then
			HomelandData.OpenHomelandPanel()
		else
			UIMgr.Open(VIEW_ID.PanelHome, 1)
		end
		TipsHelper.ShowNormalTip("完成家园订单需求拥有家园，点击【免费获取】获取私邸宅园")
        return
    end

	if UIMgr.IsViewOpened(VIEW_ID.PanelHomeOrder) then
		return UIMgr.GetView(VIEW_ID.PanelHomeOrder)
	end
	UIMgr.Open(VIEW_ID.PanelHomeOrder, nOwnerID, nTypeIndex)
end

function HomelandIdentity.OpenFoodCartPanel(dwOwnerID, dwNpcID, bFurniture)
	if UIMgr.IsViewOpened(VIEW_ID.PanelDiningCar) then
		return UIMgr.GetView(VIEW_ID.PanelDiningCar)
	end
	UIMgr.Open(VIEW_ID.PanelDiningCar, dwOwnerID, dwNpcID, bFurniture)
end

function HomelandIdentity.OpenFishBagPanel()
	if UIMgr.IsViewOpened(VIEW_ID.PanelHomeFishDeal) then
		return UIMgr.GetView(VIEW_ID.PanelHomeFishDeal)
	end
	UIMgr.Open(VIEW_ID.PanelHomeFishDeal)
end

-- 调香界面
function HomelandIdentity.OpenConfigurationPop()
	UIMgr.Close(VIEW_ID.PanelHome)
	UIMgr.Close(VIEW_ID.PanelHomeIdentity)
	Event.Reg(self, EventType.OnViewClose, function(nViewID)
		UIMgr.Close(VIEW_ID.PanelSystemMenu)
		UIMgr.Close(VIEW_ID.PanelHalfBag)
		UIMgr.Open(VIEW_ID.PanelConfigurationPop)
	end, true)
end

function HomelandIdentity.GetOrderViewScript()
	return UIMgr.GetViewScript(VIEW_ID.PanelHomeOrder)
end

function HomelandIdentity.UpdatePanelHomeOrderInfo(bNotPeek)
	Event.Dispatch(EventType.OnHomelandOrderUpdate, bNotPeek)
	Event.Dispatch(EventType.OnHomelandIdentityUpdate)	-- 顺便更新身份界面
end

function HomelandIdentity.On_Tong_CompleteOrder(nIndex, dwID, nTimes)
	local script = self.GetOrderViewScript()
	if script then
		script:OnFinishTongOrder(nIndex, dwID, nTimes)
	end
end

function HomelandIdentity.On_Tong_GetOrder(tInfo)
	Event.Dispatch(EventType.OnGetTongOrder, tInfo)
end

function HomelandIdentity.OpenAssistOrderDetails(dwTalkerID)
	local tbLinkData = HomelandIdentity.GetChatOrder(dwTalkerID)
	UIMgr.Open(VIEW_ID.PanelSentHomeOrderDetails, tbLinkData)
end

function HomelandIdentity.CanChangeManSkin()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    local cd_left = hPlayer.GetCDLeft(CD_FISH)
	if cd_left == 0 then
        return true
    end

    return false
end

function HomelandIdentity.UseToyBoxSkill(dwID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tLine = Table_GetToyBox(dwID)
    if not tLine then
        return
    end

	local tHLToyInfo = tToyInfo[dwID]
    if tHLToyInfo then
        local dwIdentityID = tHLToyInfo.dwIdentityID
        local nLevel = tHLToyInfo.nLevel
        local tHLIdenInfo = Table_GetHLIdentity(dwIdentityID)
        local tExpData = GDAPI_GetHLIdentityExp(dwIdentityID)
        local nCurLevel = tExpData.nLevel
        if nCurLevel < nLevel then
			TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_HOMELAND_IDENTITY_LEVEL_LIMIT, UIHelper.GBKToUTF8(tHLIdenInfo.szName) .. nLevel))
			return
        end
    end

    local bIsHave = GDAPI_IsToyHave(hPlayer, dwID, tLine.nCountDataIndex)
	if not bIsHave then
		TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_HOMELAND_TOY_NOT_GET, UIHelper.GBKToUTF8(tLine.szName)))
	end
    local nCount  = GDAPI_GetToyUseCount(hPlayer, dwID, tLine.nCountDataIndex)
    if (bIsHave and tLine.nToyType ~= TOY_TYPE.COUNT) or
       (tLine.nToyType == TOY_TYPE.COUNT and nCount and nCount > 0) then
        local tLine = Table_GetToyBox(dwID)
        OnUseSkill(tLine.nSkillID, tLine.nSkillID * (tLine.nSkillID % 10 + 1))
    end
end

function HomelandIdentity.GetPackItem(dwOrderItemIndex)
    return tPackgeList[dwOrderItemIndex]
end

OrderPanel = OrderPanel or {}
function OrderPanel.Open(nOwnerID, szPage)
	local nIndex = 1
	if szPage then
		if szPage == "Page_Cook" then
			nIndex = 2
		end
	end
	HomelandIdentity.OpenPanelHomeOrder(nOwnerID, nIndex)
end

PerfumePanel = PerfumePanel or {}
function PerfumePanel.Open()
	UIMgr.Open(VIEW_ID.PanelConfigurationPop)
end

HLIdentity = HLIdentity or {}
function HLIdentity.Close()
	UIMgr.Close(VIEW_ID.PanelHomeIdentity)
end