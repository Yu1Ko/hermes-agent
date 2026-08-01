-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetItemChoose
-- Date: 2024-04-10 20:19:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetItemChoose = class("UIWidgetItemChoose")
local NutrientType = {
	Fertilize = 1,
	Water = 2
}

local szLabelTitle = {
	[1] = "点击施肥",
	[2] = "点击浇水"
}
local ACTION_FERTILIZE = 1
local ACTION_WATERING = 2
local ACTION_PICK = 3

function UIWidgetItemChoose:OnEnter(nType)
	self.nType = nType
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWidgetItemChoose:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetItemChoose:BindUIEvent()
	UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function()
		Event.Dispatch("ON_REMOVE_NUTRIENT_ITEM_INFO")
	end)
end

function UIWidgetItemChoose:RegEvent()
	Event.Reg(self, "ON_UPDATE_FLOWERPANEL_INFO", function (tFlowerInfo)
		self:UpdateInfo()
	end)
end

function UIWidgetItemChoose:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetItemChoose:UpdateInfo()
	self:GetCanUseItemInfo()
	self:UpdateItemInfo()
end

function UIWidgetItemChoose:GetCanUseItemInfo()
	self.tbItemList = {}
	local tbBoxSet = ItemData.BoxSet.Bag
	for i, nBox in ipairs(tbBoxSet) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local item = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
			if item and self:IsNutrientItem(item) and self:IsNotContainItem(item) then
				table.insert(self.tbItemList, item)
			end
        end
    end
end

function UIWidgetItemChoose:IsNutrientItem(hItem)
	local bRes = false
	if hItem.nGenre == ITEM_GENRE.FODDER and hItem.nSub == DOMESTICATE_FODDER_SUB_TYPE.FERTILIZER then
        bRes = true
	end

	return bRes
end

function UIWidgetItemChoose:UpdateItemInfo()
	UIHelper.SetString(self.LabelClickFeeding, szLabelTitle[self.nType])
	UIHelper.RemoveAllChildren(self.LayoutItemListSigleLine)
	local itemInfo = NUTRIENT_ITEM[self.nType]
	for i, tInfo in ipairs(itemInfo) do
		local tbItemInfo = ItemData.GetItemInfo(tInfo.dwTabType, tInfo.dwIndex)
		local szName = UIHelper.GBKToUTF8(Table_GetItemName(tbItemInfo.nUiId))
		local nStackNum = ItemData.GetItemAllStackNum(tbItemInfo, false)
		local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.LayoutItemListSigleLine, szName, "+"..tInfo.nDetail, tInfo.dwTabType, tInfo.dwIndex, false)
		if itemIcon then
			itemIcon:SetClickCallback(function (dwTabType, dwIndex)
				if nStackNum > 0 then
					if self.nType == NutrientType.Fertilize then
						RemoteCallToServer("On_Activity_HZJClickButton", ACTION_FERTILIZE, tInfo.dwTabType, tInfo.dwIndex)
					else
						RemoteCallToServer("On_Activity_HZJClickButton", ACTION_WATERING, tInfo.dwTabType, tInfo.dwIndex)
					end
				else
					local tips, scriptItemTip = TipsHelper.ShowItemTips(itemIcon._rootNode, tInfo.dwTabType, tInfo.dwIndex, false)
				end
			end)
			Timer.AddFrame(self, 1, function ()
				if nStackNum > 0 then
					itemIcon:SetIconCount(nStackNum)
				end
				UIHelper.SetNodeGray(itemIcon._rootNode, nStackNum == 0 and true or false, true)
			end)

		end
	end
end

function UIWidgetItemChoose:IsNotContainItem(hItem)
	for k, item in pairs(self.tbItemList) do
		if item.dwTabType == hItem.dwTabType and item.dwIndex == hItem.dwIndex then
			return false
		end
	end
	return true
end

return UIWidgetItemChoose