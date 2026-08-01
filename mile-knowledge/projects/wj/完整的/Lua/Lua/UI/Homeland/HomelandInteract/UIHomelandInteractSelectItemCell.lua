-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractSelectItemCell
-- Date: 2023-08-07 10:43:28
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MIN_LABEL_HEIGHT = 80
local UIHomelandInteractSelectItemCell = class("UIHomelandInteractSelectItemCell")

function UIHomelandInteractSelectItemCell:OnEnter(tbInfo, bModule1)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bModule1 = bModule1
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomelandInteractSelectItemCell:OnExit()
    self.bInit = false
end

function UIHomelandInteractSelectItemCell:BindUIEvent()

end

function UIHomelandInteractSelectItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandInteractSelectItemCell:UpdateInfo()
    if self.tbInfo.szTitle then
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(self.tbInfo.szTitle))
        UIHelper.SetString(self.LabelTitle2, UIHelper.GBKToUTF8(self.tbInfo.szTitle))
        UIHelper.SetVisible(self.WidgetTitle, self.bModule1)
        UIHelper.SetVisible(self.WidgetTitle2, not self.bModule1)
    else
        UIHelper.SetString(self.LabelCellContent, "")
    end

    local szInfo = ""
    if self.tbInfo.szInfo then
        szInfo = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(self.tbInfo.szInfo), true)

        -- 特判餐盘展示额外提示
        if self.tbInfo.nModuleID == 25 and self.tbInfo.tSlot then
            local tSlotSelectionItem = HomelandMiniGameData.tSlotSelectionItem or {}
            local tItemInfo = tSlotSelectionItem[self.tbInfo.tSlot.nID]
            if tItemInfo then
                szInfo = szInfo .. "\n可补充相同餐品至250份"
            end
        end
    end
    UIHelper.SetString(self.LabelCellContent, szInfo)
    while UIHelper.GetHeight(self.LabelCellContent) < MIN_LABEL_HEIGHT do
        -- 如果文本太少会导致Layout无法将ItemIcon包住，所以限最低高度
        szInfo = szInfo.."\n"
        UIHelper.SetString(self.LabelCellContent, szInfo)
    end

    if self.nCountdownTimerID then
        Timer.DelTimer(self, self.nCountdownTimerID)
        self.nCountdownTimerID = nil
    end

    local nTime = self.tbInfo.nTime
    local nCountdownType = self.tbInfo.nCountdownType
    local szCountdownTip = UIHelper.GBKToUTF8(self.tbInfo.szCountdownTip or "")
    local szTxt = ""
    if nCountdownType and nCountdownType > 0 and nTime then
        local fnCountdown = function()
            local nCurrTime = GetCurrentTime()
            local nDiffTime = 0
            if nCountdownType == 2 then --倒计时
                nDiffTime = nTime - nCurrTime
            elseif nCountdownType == 1 then  --正计时
                nDiffTime = nCurrTime - nTime
            end

            if nDiffTime < 0 then
                nDiffTime = 0
            end
            szTxt = self:GetCDTimeText(nDiffTime)

            szTxt = string.format("%s%s", szCountdownTip, szTxt)
            UIHelper.SetString(self.LabelCellContent, string.format("%s\n%s", szInfo, szTxt))

            if nCountdownType == 2 and nDiffTime < 1 then
                Timer.DelTimer(self, self.nCountdownTimerID)
                self.nCountdownTimerID = nil
            end
        end

        self.nCountdownTimerID = Timer.AddCycle(self, 0.5, function ()
            fnCountdown()
        end)
        fnCountdown()
	end

    local nIconIndex = 1
    if self.tbInfo.tSlot then
        self.scriptNcessaryItemIcon = self.scriptNcessaryItemIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetNcessaryItemIcon, self.WidgetNcessaryItemIcon)
        local tbInfo = clone(self.tbInfo.tSlot)
        tbInfo.nModuleID = self.tbInfo.nModuleID
        self.scriptNcessaryItemIcon:OnEnter(1, tbInfo)
        UIHelper.SetName(self.scriptNcessaryItemIcon._rootNode, "WidgetNcessaryItemIcon"..nIconIndex)
        nIconIndex = nIconIndex + 1
    end

    if self.tbInfo.tSlots then
        UIHelper.SetVisible(self.WidgetNcessary, false)
        UIHelper.SetVisible(self.LayoutItem, true)
        UIHelper.SetVisible(self.WidgetLine, true)

        self.tbSlotCell = self.tbSlotCell or {}
        for i, tSlot in ipairs(self.tbInfo.tSlots) do
            if tSlot and tSlot.nHorseBoxId and tSlot.nHorseBoxId > 0 then
                local tItem = {dwIndex = tSlot.nHorseBoxId, dwTabType = 8, nStackNum = 1, bIsProduct = true}
                HomelandMiniGameData.AddItemToSlot(tSlot, tItem)
            end

            if not self.tbSlotCell[i] then
                self.tbSlotCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetNcessaryItemIcon, self.LayoutItem)
            end
            tSlot.nModuleID = self.tbInfo.nModuleID
            self.tbSlotCell[i]:OnEnter(i, tSlot)
            UIHelper.SetName(self.tbSlotCell[i]._rootNode, "WidgetNcessaryItemIcon"..nIconIndex)
            nIconIndex = nIconIndex + 1
        end

        UIHelper.LayoutDoLayout(self.LayoutItem)
    else
        UIHelper.SetVisible(self.WidgetNcessary, true)
        UIHelper.SetVisible(self.LayoutItem, false)
        UIHelper.SetVisible(self.WidgetLine, false)
    end

    UIHelper.LayoutDoLayout(self.WidgetNcessary)
    UIHelper.LayoutDoLayout(self.LayoutItemAll)
    UIHelper.LayoutDoLayout(self.WidgetItemNcessary)
    UIHelper.WidgetFoceDoAlign(self)
end

function UIHomelandInteractSelectItemCell:GetCDTimeText(nTime)
	local szTxt = ""
	local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime)
	if nH > 0 then
		szTxt = szTxt .. nH .. g_tStrings.STR_BUFF_H_TIME_H
	end
	if nM > 0 then
		szTxt = szTxt .. nM .. g_tStrings.STR_BUFF_H_TIME_M
	end
	szTxt = szTxt .. nS .. g_tStrings.STR_BUFF_H_TIME_S
	return szTxt
end


local function GetHouseBagNum(tItem)
	local tFilter = HomelandMiniGameData.tFilterCheck[tItem.dwClassType]
	local nClassBagNum = GetClientPlayer().GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (tItem.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
	return nClassBagNum
end
function UIHomelandInteractSelectItemCell:UpdateHistoryItem(scriptIcon, nIndex, tSlot)
    if not HomelandMiniGameData.tData.bSaveHistory or not Storage.HomeLandBuild.tHistorySelectionItem then
		return
	end

	local nGameID = HomelandMiniGameData.tData.nGameID
	local nGameState = HomelandMiniGameData.tData.nGameState

	if not Storage.HomeLandBuild.tHistorySelectionItem[nGameID] then
		return
	end

	local tItemDatas = Storage.HomeLandBuild.tHistorySelectionItem[nGameID][nGameState] or {}
	local tItem = tItemDatas[nIndex]
	if not tItem then
		return
	end

	local nCount = GetClientPlayer().GetItemAmountInPackage(tItem.dwTabType, tItem.dwIndex)
	local tHouseBagLine = Table_GetHomelandLockerInfoByItem(tItem.dwIndex)
	if tHouseBagLine then
		nCount = nCount + GetHouseBagNum(tHouseBagLine)
	end

	if nCount >= tItem.nStackNum then
		HomelandMiniGameData.AddItemToSlot(tSlot, tItem)
        scriptIcon:OnEnter(scriptIcon.nIndex, tSlot)
	else
		TipsHelper.ShowNormalTip(g_tStrings.STR_HOUSE_NOT_ENOUGH_ITEM)
	end
end

return UIHomelandInteractSelectItemCell