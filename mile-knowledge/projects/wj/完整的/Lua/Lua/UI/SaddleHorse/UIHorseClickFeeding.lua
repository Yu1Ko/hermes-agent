-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHorseClickFeeding
-- Date: 2022-12-07 11:27:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHorseClickFeeding = class("UIHorseClickFeeding")

function UIHorseClickFeeding:OnEnter(dwCubTabType, dwCubTabIndex)
    UIHelper.SetTouchDownHideTips(self.ScrollViewList, false)
    if not dwCubTabType then 
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwCubTabType = dwCubTabType
    self.dwCubTabIndex = dwCubTabIndex
    self.tItemInfo = GetItemInfo(dwCubTabType, dwCubTabIndex)
    if self.tItemInfo then
        self:UpdateInfo(dwCubTabType, dwCubTabIndex)
    end
    
    --UIHelper.SetTouchDownHideTips(self.LayoutItemListSigleLine, false)
end

function UIHorseClickFeeding:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHorseClickFeeding:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function ()
        UIHelper.SetVisible(self._rootNode, false)
    end)
end

function UIHorseClickFeeding:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function (nBox, nIndex)
        self:UpdateInfo(self.dwCubTabType, self.dwCubTabIndex)
    end)
end

function UIHorseClickFeeding:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHorseClickFeeding:UpdateInfo(dwCubTabType, dwCubTabIndex)
    local player = GetClientPlayer()

    local bIsEmpty = true
    local tbFeedItemList = self:GetFeedList(dwCubTabType, dwCubTabIndex)

    local parent = self.ScrollViewList
    if #tbFeedItemList <= 4 then
        parent = self.LayoutItemListSigleLine
    end

    UIHelper.RemoveAllChildren(parent)

    for _, tFeedItem in ipairs(tbFeedItemList) do
        local bOwned = tFeedItem.dwBox and tFeedItem.dwX
        local tbItemInfo = ItemData.GetItemInfo(tFeedItem.dwTabType, tFeedItem.dwIndex)
        if tbItemInfo and self:HouseBagFilter(tbItemInfo, dwCubTabType, dwCubTabIndex) then
            --是马匹配的饲料
            local szName = UIHelper.GBKToUTF8(Table_GetItemName(tbItemInfo.nUiId))
            local nStackNum = ItemData.GetItemAllStackNum(tbItemInfo, false)
            local szItemDesc = "+"..tostring(tbItemInfo.nDetail)
            local itemIcon
            if not bOwned then
                itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, parent, szName, nStackNum, tFeedItem.dwTabType, tFeedItem.dwIndex, false)
            else
                itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, parent, szName, nStackNum, nil, nil, false)
                itemIcon:SetItemBoxAndX(tFeedItem.dwBox, tFeedItem.dwX)
            end
            if itemIcon then
                itemIcon:UpdateInfo()
                itemIcon:SetLabelText(szItemDesc)
                UIHelper.SetVisible(itemIcon.LabelTxt, true)
                itemIcon:SetClickCallback(function ()
                    if bOwned then                        
                        self.fCallBack(tFeedItem.dwBox, tFeedItem.dwX)
                    else
                        local bCanBuy = tFeedItem.dwGroup and tFeedItem.dwShopID and tFeedItem.dwGroup > 0 and tFeedItem.dwShopID > 0
                        local _,scriptItemTips = TipsHelper.ShowItemTips(itemIcon._rootNode, tFeedItem.dwTabType, tFeedItem.dwIndex, false)
                        local tbBtnState = {{
                            szName = "商店购买", OnClick = function ()
                                ShopData.OpenSystemShopGroup(tFeedItem.dwGroup, tFeedItem.dwShopID, tFeedItem.dwTabType, tFeedItem.dwIndex)
                                TipsHelper.DeleteAllHoverTips()
                            end
                        }}
                        if bCanBuy then
                            scriptItemTips:SetBtnState(tbBtnState or {})
                        else
                            TipsHelper.ShowNormalTip("该道具无法在商店中购买，请尝试其他获取途径")
                        end
                    end
                end)
                bIsEmpty = false
                UIHelper.SetNodeGray(itemIcon.scriptItemIcon.ImgIcon, not bOwned, true)
                if not bOwned then
                    UIHelper.SetColor(itemIcon.scriptItemIcon.ImgIcon, cc.c4b(120, 120, 120, 120))
                    UIHelper.SetColor(itemIcon.scriptItemIcon.ImgPolishCountBG, cc.c4b(120, 120, 120, 120))
                else
                    UIHelper.SetColor(itemIcon.scriptItemIcon.ImgIcon, cc.c4b(0xFF, 0xFF, 0xFF, 0xFF))
                    UIHelper.SetColor(itemIcon.scriptItemIcon.ImgPolishCountBG, cc.c4b(0xFF, 0xFF, 0xFF, 0xFF))
                end
                if nStackNum > 0 then
                    itemIcon:SetIconCount(nStackNum)
                end
                itemIcon:ShowBindIcon(tFeedItem.bBind)
                itemIcon:ClearItemClickCallback()
            end
        end
    end
    local szDesc = Table_GetItemDesc(self.tItemInfo.nUiId)
    szDesc = UIHelper.GBKToUTF8(string.pure_text(szDesc))
    local szFodder = "暂无可使用饲料，当前马驹/幼崽可食用饲料：\n"
    for szWord in string.gmatch(szDesc, "【.*】") do
        szFodder = szFodder .. szWord
    end
    UIHelper.SetVisible(self.WidgetEmpty, bIsEmpty)
    UIHelper.SetString(self.LabelEmpty, szFodder)

    if #tbFeedItemList > 4 then
        UIHelper.LayoutDoLayout(self.LayoutItemList)
        UIHelper.ScrollViewDoLayout(self.ScrollViewList)
        UIHelper.ScrollToTop(self.ScrollViewList,0)
    else
        UIHelper.LayoutDoLayout(self.LayoutItemListSigleLine)
    end
    UIHelper.SetVisible(self.WidgetScroll, #tbFeedItemList > 4)
    UIHelper.SetVisible(self.WidgetSigleLine, #tbFeedItemList <= 4)
end

function UIHorseClickFeeding:HouseBagFilter(pItem, dwCubTabType, dwCubTabIndex)
    return pItem and pItem.nGenre == ITEM_GENRE.FODDER and IsFodderMatchOfCub(dwCubTabType, dwCubTabIndex, pItem.nSub)
end

function UIHorseClickFeeding:SetClickCallback(fCallBack)
    self.fCallBack = fCallBack
end

function UIHorseClickFeeding:GetFeedList(dwCubTabType, dwCubTabIndex)
	local tFlag = {}
	local tFeedList = {}
	local pPlayer = GetClientPlayer()
	for _, dwBox in pairs(GetPackageIndex() or {}) do
		local nSize = pPlayer.GetBoxSize(dwBox)
		for dwX = 0, nSize - 1 do
			local pItem = ItemData.GetPlayerItem(pPlayer, dwBox, dwX)
			if pItem and self:HouseBagFilter(pItem, dwCubTabType, dwCubTabIndex) then
				local tIndex = {dwBox = dwBox, dwX = dwX, dwTabType = pItem.dwTabType, dwIndex = pItem.dwIndex, bBind = pItem.bBind}
                tIndex.nPriority = (100-pItem.nQuality)*100    -- 判定品质
                if tIndex.bBind then
                    tIndex.nPriority = tIndex.nPriority + 1
                end
				tFlag[pItem.dwIndex] = true

                local bHave = false
                for k, tFeed in ipairs(tFeedList) do
                    if tFeed.dwIndex == tIndex.dwIndex and tFeed.dwTabType == tIndex.dwTabType then
                        bHave = true
                    end
                end
                if not bHave then
                    table.insert(tFeedList, tIndex)
                end
			end
		end
	end
	local fnCmp = function(tA, tB)
		return tA.nPriority < tB.nPriority
	end
	table.sort(tFeedList, fnCmp)

	local tTemp = {}
    local tInfo = Table_GetFeedItemList()
	for i = 1, #tInfo do
		if not tFlag[tInfo[i].dwIndex] then
			local KItemInfo = GetItemInfo(tInfo[i].dwTabType, tInfo[i].dwIndex)
			if self:HouseBagFilter(KItemInfo, dwCubTabType, dwCubTabIndex) then
				table.insert(tTemp, tInfo[i])
			end
		end
	end

	table.sort(tTemp, fnCmp)
	for i = 1, #tTemp do
		table.insert(tFeedList, tTemp[i])
	end
	return tFeedList
end

function UIHorseClickFeeding:SetTitle(szTitle)
	UIHelper.SetString(self.LabelClickFeeding ,szTitle)
end

function UIHorseClickFeeding:ShowEmpty()
    UIHelper.SetVisible(self.WidgetEmpty ,true)
    UIHelper.SetVisible(self.WidgetSigleLine ,false)
    UIHelper.SetVisible(self.WidgetScroll ,true)
end

function UIHorseClickFeeding:HideFullScreenButton()
    UIHelper.SetVisible(self.ButtonClose ,false)
end

return UIHorseClickFeeding