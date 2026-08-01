-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIViewName
-- Date: 2024-04-10 11:27:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIViewName = class("UIViewName")
local NutrientType = {
	Fertilize = 1,
	Water = 2
}
local FIRST_DEMARCATION_POINT = 0.3

local tbColor = {
	[1] = "<color=#ff9696>%s</color>",
	[2] = "<color=#ffcf65>%s</color>",
	[3] = "<color=#70ffbb>%s</color>"
}
local ACTION_PICK = 3

function UIViewName:OnEnter(tFlowerInfo, dwTargetType, dwTargetId)
	self.dwTargetType = dwTargetType
	self.dwTargetId = dwTargetId
	self.tFlowerInfo = tFlowerInfo
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo(tFlowerInfo)
end

function UIViewName:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIViewName:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnFertilizer, EventType.OnClick, function()
		self:UpdateNutrientItemInfo(NutrientType.Fertilize)

	end)

	UIHelper.BindUIEvent(self.BtnWatering, EventType.OnClick, function()
		self:UpdateNutrientItemInfo(NutrientType.Water)
	end)

	UIHelper.BindUIEvent(self.BtnHarvest, EventType.OnClick, function()
		RemoteCallToServer("On_Activity_HZJClickButton", ACTION_PICK)
	end)
end

function UIViewName:RegEvent()
	Event.Reg(self, "ON_UPDATE_FLOWERPANEL_INFO", function (tFlowerInfo)
		self:UpdateInfo(tFlowerInfo)
	end)

	Event.Reg(self, "ON_REMOVE_NUTRIENT_ITEM_INFO", function ()
		UIHelper.RemoveAllChildren(self.WidgetClickUsing)
		self.tbItemListScript = nil
	end)

	Event.Reg(self, EventType.OnSceneTouchNothing, function()
        UIMgr.Close(VIEW_ID.PanelFlowerFestival)
    end)
end

function UIViewName:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIViewName:UpdateInfo(tFlowerInfo)
	self:UpdateCultivateInfo(tFlowerInfo)
	self:UpdateEventInfo(tFlowerInfo)
end

function UIViewName:UpdateCultivateInfo(tFlowerInfo)
	self.tbFeedItem = nil
	self.tbWaterItem = nil
	--self:GetBagFertilizerItem()
	--更新按钮状态
	--self:UpdateBtnState()
	--更新花名
	local szFlowerName = UIHelper.GBKToUTF8(tFlowerInfo.szFlowerName) 
	if not g_pClientPlayer then
		return
	end
	local szPlayerName = UIHelper.GBKToUTF8(g_pClientPlayer.szName) 
	UIHelper.SetString(self.LabelTitle, szFlowerName)

	UIHelper.SetString(self.LabelTitlePlayer, string.format("%s的%s", szPlayerName, szFlowerName))
	--更新植物的阶段名及其经验值
	UIHelper.SetString(self.LabelBarTitleExp, UIHelper.GBKToUTF8(tFlowerInfo.szPlantLevel)) 
	UIHelper.SetString(self.LabelBarNumExp, string.format("%d/%d", tFlowerInfo.nCurExp, tFlowerInfo.nMaxExp))
	local nExpPercent = 100 * tFlowerInfo.nCurExp / tFlowerInfo.nMaxExp
	UIHelper.SetString(self.LabelBarNumExpPercentage, string.format("(%d%%)", nExpPercent))
	UIHelper.LayoutDoLayout(self.LayoutExpLabel)
	--更新植物的经验进度条
	UIHelper.SetProgressBarPercent(self.SliderHealth, nExpPercent)

	--更新施肥经验进度条
	self:UpdateProgressBar(NutrientType.Fertilize, tFlowerInfo)

	--更新浇水经验进度条
	self:UpdateProgressBar(NutrientType.Water, tFlowerInfo)
end

function UIViewName:UpdateProgressBar(nType, tFlowerInfo)
	local nCurExp = 0
	local nMaxExp = 0
	local nTxtIndex = 1
	if nType == NutrientType.Fertilize then
		nCurExp = tFlowerInfo.nCurFertilizeExp
		nMaxExp = tFlowerInfo.nMaxFertilizeExp
		nTxtIndex = 1
	else
		nCurExp = tFlowerInfo.nCurWaterExp
		nMaxExp = tFlowerInfo.nMaxWaterExp
		nTxtIndex = 2
	end

	local nTableIndex = nil
	if nCurExp == 0 then
		nTableIndex = 1
	elseif (nCurExp / nMaxExp) < FIRST_DEMARCATION_POINT then
		nTableIndex = 2
	else
		nTableIndex = 3
	end
	local szLable = g_tStrings.tFeedProgressBarText[nTableIndex].text[nTxtIndex]
	UIHelper.SetRichText(self.tbLabelState[nTxtIndex], string.format(tbColor[nTableIndex], szLable))

	UIHelper.SetString(self.tbLabelNumList[nTxtIndex], string.format("%d/%d", nCurExp, nMaxExp))

	local nExpPercent = 100 * nCurExp / nMaxExp
	UIHelper.SetString(self.tbPercentList[nTxtIndex], string.format("(%d%%)", nExpPercent))

	UIHelper.SetProgressBarPercent(self.tbSliderList[nTxtIndex], nExpPercent)
	UIHelper.LayoutDoLayout(self.tbLayoutLabel[nTxtIndex])
end

function UIViewName:UpdateEventInfo(tFlowerInfo)
	if tFlowerInfo.szDayEvent ~= nil then
		UIHelper.SetVisible(self.WidgetEmpty, false)
		UIHelper.SetVisible(self.LabelSpecialEvent, true)
		local szContent = UIHelper.GBKToUTF8(tFlowerInfo.szDayEvent)
		UIHelper.SetString(self.LabelSpecialEvent, szContent)
	else
		UIHelper.SetVisible(self.WidgetEmpty, true)
		UIHelper.SetVisible(self.LabelSpecialEvent, false)
	end
	UIHelper.SetVisible(self.BtnHarvest, false)
	UIHelper.SetVisible(self.WidgetItem_80, false)
	if tFlowerInfo.nFruitType and tFlowerInfo.nFruitItemId then
		UIHelper.SetVisible(self.LabelSpecialEvent, false)
		UIHelper.SetVisible(self.WidgetEmpty, false)
		UIHelper.SetVisible(self.BtnHarvest, true)
		UIHelper.SetEnable(self.BtnHarvest, true)
		UIHelper.SetVisible(self.WidgetItem_80, true)
		self:UpdateFruitItem(tFlowerInfo.nFruitType, tFlowerInfo.nFruitItemId)
	end

	UIHelper.SetNodeGray(self.BtnHarvest, false)
	if self.tbScript then
		self.tbScript:SetItemReceived(tFlowerInfo.bGot)
	end
	if tFlowerInfo.bGot then
		UIHelper.SetNodeGray(self.BtnHarvest, true, true)
		UIHelper.SetEnable(self.BtnHarvest, false)
	end
end

function UIViewName:UpdateNutrientItemInfo(nType)
	UIHelper.RemoveAllChildren(self.WidgetClickUsing)
	self.tbItemListScript = UIHelper.AddPrefab(PREFAB_ID.WidgetClickUsing, self.WidgetClickUsing, nType)
end

function UIViewName:UpdateFruitItem(dwTabType, dwIndex)
	UIHelper.RemoveAllChildren(self.WidgetItem_80)
	local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
	tbScript:OnInitWithTabID(dwTabType, dwIndex)
	tbScript:SetClickCallback(function(nItemType, nItemIndex)
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowItemTips(tbScript._rootNode, dwTabType, dwIndex, false)
        end)
    end)
	self.tbScript = tbScript
end

return UIViewName