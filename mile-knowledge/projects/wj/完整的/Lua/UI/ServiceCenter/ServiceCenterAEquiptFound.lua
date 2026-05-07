-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterAEquiptFound
-- Date: 2023-06-20 14:58:58
-- Desc: 客服中心 - 装备找回
-- ---------------------------------------------------------------------------------

local ServiceCenterAEquiptFound = class("ServiceCenterAEquiptFound")
local LIMIT_SEARCH_TIME = 10*60 -- 10分钟
local MAX_SELECT_ITEM = 16
function ServiceCenterAEquiptFound:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function ServiceCenterAEquiptFound:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function ServiceCenterAEquiptFound:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRenovate, EventType.OnClick , function ()
        if self.bRefreshTime then
            TipsHelper.ShowNormalTip("刷新冷却中")
            return
        end
        if CheckPlayerIsRemote() then
			return
		end
        ApplyItemRestoreList()
     end)

     UIHelper.BindUIEvent(self.BtnRecovery, EventType.OnClick , function ()
        if CheckPlayerIsRemote() then
            return
        end
        if self.bWaitRecovery then
            return
        end

        if table_is_empty(self.tbSelectItems) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_SELECT_ITEMS_TIP)
            return
        end
        if #self.tbSelectItems > MAX_SELECT_ITEM then
            TipsHelper.ShowNormalTip(g_tStrings.MAX_SELECT_ITEM)
            return
        end
        local hPlayer = GetClientPlayer()
        if self.nRecoveryCostMoney <= hPlayer.nCoin then
            self.bWaitRecovery = true
            hPlayer.RestoreItem(unpack(self.tbSelectItems))
        else
            TipsHelper.ShowNormalTip("通宝不足")
        end
     end)

     if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function ()
            self:UpdateSearchItems()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.WidgetEdit, function ()
            self:UpdateSearchItems()
        end)
    end

     UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick , function ()
        self:UpdateSearchItems()
     end)

     UIHelper.BindUIEvent(self.BtnFiltrate, EventType.OnClick , function ()
        local tbConfig = FilterDef.ServerEquipFound
        tbConfig[1].tbDefault = {  self.nSelectQualityIndex or 1 }
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFiltrate, TipsLayoutDir.Right, FilterDef.ServerEquipFound)
     end)

     UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick , function ()
        UIHelper.SetText(self.WidgetEdit , "")
        self:UpdateSearchItems()
     end)

end

function ServiceCenterAEquiptFound:RegEvent()
    Event.Reg(self, "ON_ITEM_RESTORE_SYNC_BEGIN", function ()
        self.bRefreshTime = true
        ServiceCenterData.nLastSearchTime = Timer.GetPassTime()
        UIHelper.SetString(self.LabelTime , g_tStrings.STR_REFRESHING)
        if arg0 == 0 then
            if not self.nTimerID then
                self:UpdateRefreshTime(LIMIT_SEARCH_TIME)
                TipsHelper.ShowNormalTip(g_tStrings.STR_NO_RESTORE_ITEMS)
            end
        end
        self:ReApply()
    end)

    Event.Reg(self, "ON_ITEM_RESTORE_SYNC_FINISH", function ()
        self:UpdateRefreshTime(LIMIT_SEARCH_TIME)
        self.bReApply = true
        self:UpdateRenewEx()
    end)

    Event.Reg(self, "ON_ITEM_RESTORE_RESULT", function ()
        if arg0 == RESTORE_ITEM_RESULT.SUCCESS then
			self.tbSelectItems = {}
            self.bReApply = true
            self.curSelectItem = nil
			self:UpdateRenewEx()
			self:UpdateSelectCount()
            local hPlayer = GetClientPlayer()
            local nTotal = hPlayer.nRestoreCount + hPlayer.nAdvanceRestoreCount
            if not UIMgr.GetView(VIEW_ID.PanelNormalConfirmation) then
                local confirmView = UIHelper.ShowConfirm(FormatString(g_tStrings.STR_RESTORE_MSG, nTotal))
                confirmView:HideCancelButton()
            end
		elseif g_tStrings.STR_RESTORE_TIP[arg0] then
            local confirmView = UIHelper.ShowConfirm(g_tStrings.STR_RESTORE_TIP[arg0])
	        confirmView:HideCancelButton()
		end
        self.bWaitRecovery = false
    end)

    Event.Reg(self , EventType.OnFilter, function (defKey, tbSelectIndex)
        self.nSelectQualityIndex = tbSelectIndex[1][1]
        self:UpdateSearchItems()
    end)


    Event.Reg(self , EventType.HideAllHoverTips , function ()
        if self.curSelectItem then
            self.curSelectItem:SetSelected(false)
        end

        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
        end
     end)
end

function ServiceCenterAEquiptFound:UnRegEvent()

end


function ServiceCenterAEquiptFound:UpdateRenewEx()
    if self.bReApply then
		self:ReApply()
		self.bReApply = false
	end
end

function ServiceCenterAEquiptFound:ReApply()
    local hPlayer = GetClientPlayer()
	self.tbSysItems = hPlayer.GetItemRestoreList()
    self.tbItemLuas = {}
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    for k, item in pairs(self.tbSysItems) do
        local itemLua = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName , self.ScrollViewContent)
		local r, g, b = GetItemFontColorByQuality(item.nQuality)
        itemLua.item = item
        itemLua:SetItemQualityBg(item.nQuality)
        itemLua:SetTextColor(cc.c4b(r, g, b, 255))
        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item))
		itemLua:SetLabelItemName(szItemName)
		itemLua:SetImgIconByIconID(Table_GetItemIconID(item.nUiId))
        itemLua:RegisterSelectEvent(function (bSelected)
            if self.curSelectItem then
                self.curSelectItem:SetSelected(false)
            end
            self.curSelectItem = itemLua
            self.curSelectItem:SetSelected(bSelected)
            if self.scriptItemTip then
                self.scriptItemTip:OnInit()
            end
            if not bSelected then
                return
            end
            self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
            self.scriptItemTip:OnInitWithTabID(item.dwTabType, item.dwIndex)
            UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0.5, 1)
			UIHelper.SetPosition(self.scriptItemTip._rootNode, 0, 0)
            self.scriptItemTip:SetForbidAutoShortTip(true)
            self:UpdateItemTipState(k)
        end)
		local nCount = 1
		if item.nGenre == ITEM_GENRE.EQUIPMENT then
			if item.nSub == EQUIPMENT_SUB.ARROW then
				nCount = item.nCurrentDurability
			end
		elseif item.bCanStack then
			nCount = item.nStackNum
		end
		if nCount == 1 then
			itemLua:SetLableCount("")
		else
			itemLua:SetLableCount(nCount)
		end
        self.tbItemLuas[k] = itemLua
	end
    UIHelper.SetVisible(self.ImgEmpty , table.get_len(self.tbItemLuas) == 0)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function ServiceCenterAEquiptFound:UpdateItemTipState(nIndex)
    local bSelect = table.contain_value(self.tbSelectItems , nIndex)
    local szButtonName = bSelect and "取消选择" or "选择"
    self.scriptItemTip:SetBtnState(
        {
            [1] =
            {
                OnClick = function()
                    if table.contain_value(self.tbSelectItems , nIndex) then
                        table.remove_value(self.tbSelectItems , nIndex)
                        UIHelper.SetVisible(self.tbItemLuas[nIndex].ToggleMultiSelect , false)
                    else
                        table.insert(self.tbSelectItems , nIndex)
                        UIHelper.SetVisible(self.tbItemLuas[nIndex].ToggleMultiSelect , true)
                    end
                    self:UpdateItemTipState(nIndex)
                    self:UpdateSelectCount()
                end,
                szName = szButtonName
            }
        }
    )
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterAEquiptFound:UpdateInfo()
    self.bRefreshTime = false
    self.tbSelectItems = {}
    self.tbSysItems = {}
    self:UpdateSelectCount(0)
    UIHelper.SetString(self.LabelTime , "")
    local bSearchItenList = false
    self.nSelectFiltIndex = 1
    self.nSelectQualityIndex = 1
    if not ServiceCenterData.nLastSearchTime then
		bSearchItenList = true
    else
        local nRefreshTime = LIMIT_SEARCH_TIME - (Timer.GetPassTime() - ServiceCenterData.nLastSearchTime)
        if nRefreshTime <= 0 then
            bSearchItenList = true
        else
           self:UpdateRefreshTime(nRefreshTime)
        end
	end
    if bSearchItenList then
        if CheckPlayerIsRemote() then
            return
        end
        ApplyItemRestoreList(0)
    else
        self:ReApply()
    end
end

function ServiceCenterAEquiptFound:UpdateSelectCount()
    self.nSelectCount = #self.tbSelectItems
    UIHelper.SetString(self.LabelNum , self.nSelectCount)

    local hPlayer = GetClientPlayer()
    UIHelper.SetRichText(self.RichTextRecovery , string.format( "<color=#d7f6ff>本季度已恢复%d件蓝色及以上物品",hPlayer.nAdvanceRestoreCount))
    local nCostEx = 0
    local nAdvanceSelected = self:GetAdvanceSelectCount()
	local nLeftAdvance = hPlayer.nMaxAdvanceRestoreCount - hPlayer.nAdvanceRestoreCount
	local nRestoreCost = GetItemRestoreCost()


	if nAdvanceSelected > nLeftAdvance then
		if nLeftAdvance >= 0 then
			nCostEx = nCostEx + (nAdvanceSelected - nLeftAdvance ) * nRestoreCost
		else
			nCostEx = nCostEx + nAdvanceSelected * nRestoreCost
		end
	end
    UIHelper.SetString(self.LabelMoneyToatal , nCostEx)
    self.nRecoveryCostMoney = nCostEx
end

function ServiceCenterAEquiptFound:GetAdvanceSelectCount()
    if not self.tbSelectItems then
		return 0
	end

	local count = 0
	for _, index in pairs(self.tbSelectItems) do
		if self.tbSysItems[index].nQuality >= 3  then
			count = count + 1
		end
	end
	return count
end

function ServiceCenterAEquiptFound:UpdateRefreshTime(nRefreshTime)
    if self.nTimerID then
        Timer.DelTimer(self, self.nTimerID)
    end
    self.bRefreshTime = true
    UIHelper.SetString(self.LabelTime , Timer.Format2Minute(nRefreshTime))
    self.nTimerID = Timer.AddCountDown(self, nRefreshTime , function (deltaTime)
        UIHelper.SetString(self.LabelTime , Timer.Format2Minute(deltaTime))
    end , function ()
        ServiceCenterData.nLastSearchTime = 0
        UIHelper.SetString(self.LabelTime , "")
        self.bRefreshTime = false
    end)
end

function ServiceCenterAEquiptFound:UpdateSearchItems()
    local szFiler = UIHelper.GetText(self.WidgetEdit)
    local count = 0
    for k, itemLua in pairs(self.tbItemLuas) do
		local szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(itemLua.item))
		local bFilterKey = self:MatchFilter(szName, szFiler)
        local bFilterQuelity = false
        if self.nSelectQualityIndex == 1 or (self.nSelectQualityIndex - 2) == itemLua.item.nQuality then
            bFilterQuelity = true
        end
        local bShow = bFilterKey and bFilterQuelity
        if bShow then
            count = count + 1
        end
        UIHelper.SetVisible(itemLua._rootNode , bShow)
	end
    UIHelper.SetVisible(self.ImgEmpty , count == 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function ServiceCenterAEquiptFound:MatchFilter(szInput, szFiler)
	if szFiler == "" then
		return true
	end
    local result = string.find(szInput, szFiler)
	return result and true or false
end

return ServiceCenterAEquiptFound