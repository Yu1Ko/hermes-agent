-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureTryBookDesc
-- Date: 2024-05-21 15:00:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function SimpleDate(nData)
	local szData = ""
	if nData >= 10000 then
		if nData % 10000 == 0 then
			szData = nData / 10000 .. g_tStrings.DIGTABLE.tCharDiH[2]
		else
			szData = string.format("%.1f", nData / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
		end
	else
		szData = tostring(nData)
	end
	return szData
end

local function IsShowItem(tItem)
	local itemInfo = GetItemInfo(tItem[1], tItem[2])
	if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		return IsItemFitPlayerForce(itemInfo)
	end

	return true
end

local UIAdventureTryBookDesc = class("UIAdventureTryBookDesc")

function UIAdventureTryBookDesc:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIAdventureTryBookDesc:OnExit()
    self.bInit = false
    self:UnRegEvent()

    for _, widget in pairs(self.tRetainWidget) do
        widget:release()
    end
    self.tRetainWidget = nil
end

function UIAdventureTryBookDesc:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTrade, EventType.OnClick, function()
        if self.tAdv and self.tAdv.tPet then
            AdventureData.GoToAcquirePet(self.tAdv.tPet)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMoHe, EventType.OnClick, function()
        if self.tAdv  then
			UIHelper.OpenWeb("https://www.jx3box.com/adventure/" .. self.tAdv.dwID)
		end
    end)
end

function UIAdventureTryBookDesc:RegEvent()
    Event.Reg(self, EventType.OnSelectAdventureTryBookCell, function(tAdv, bZhenQi)
        self.tAdv = tAdv
        self.bZhenQi = bZhenQi
        self:UpdateInfo()
    end)
end

function UIAdventureTryBookDesc:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventureTryBookDesc:UpdateInfo()
    if not self.tAdv then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.ScrollViewContent, false)
        UIHelper.SetVisible(self.BtnMoHe, false)
        UIHelper.SetVisible(self.BtnTrade, false)
        return
    end

    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.ScrollViewContent, true)
    UIHelper.SetVisible(self.BtnMoHe, true)
    UIHelper.SetVisible(self.BtnTrade, true)

    self.tRetainWidget = self.tRetainWidget or {}
    self:RemoveWidget(self.WidgetQiYuWarning)
    self:RemoveWidget(self.WidgetQiYuDemand)
    self:RemoveWidget(self.WidgetQiYuDaily)
    self:RemoveWidget(self.WidgetQiYuWeekly)

    self:UpdateBaseInfo()
    self:UpdateRewardItem()
    self:UpdateChance()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIAdventureTryBookDesc:UpdateBaseInfo()
    local tAdv = self.tAdv
    local szPath
    UIHelper.SetVisible(self.ImgAward, self.bZhenQi)
    UIHelper.SetVisible(self.ImgAward_Poem, not self.bZhenQi)
    if self.bZhenQi then
        szPath = AdventureData.GetOpenRewardPath(tAdv)
        UIHelper.SetTexture(self.ImgAward, szPath, false)
    else
        szPath = AdventureData.GetRewardPath(tAdv)
        UIHelper.SetTexture(self.ImgAward_Poem, szPath, false)
    end
    UIHelper.SetString(self.LabelAwardName, UIHelper.GBKToUTF8(tAdv.szName))
    UIHelper.SetVisible(self.BtnTrade, self.bZhenQi)
    UIHelper.SetVisible(self.ImgNotNow, tAdv.nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE)
    UIHelper.SetVisible(self.ImgNoResources, tAdv.nChanceState == ADVENTURE_CHANCE_STATE.EXPLORED)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAwardPic, true, true)
end

function UIAdventureTryBookDesc:UpdateRewardItem()
    if self.bZhenQi then
        UIHelper.SetVisible(self.WidgetQiYuAward, false)
        return
    end

    local tAdv = self.tAdv
    if not tAdv.tItemList then
        tAdv.tItemList  = {}
        local tList = SplitString(tAdv.szRewardItemList, ";")
        for _, szItem in ipairs(tList) do
            local t = SplitString(szItem, "_")
            for k, v in ipairs(t) do
                t[k] = tonumber(v or "")
            end
            table.insert(tAdv.tItemList, t)
        end
    end
    self.tItemScript = self.tItemScript or {}
    UIHelper.HideAllChildren(self.LayoutAwardList)
    local bShowReward = false
    for i, tItem in ipairs(tAdv.tItemList) do
        if IsShowItem(tItem) then
            self.tItemScript[i] = self.tItemScript[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutAwardList)
            self.tItemScript[i]:SetClickNotSelected(true)
            UIHelper.InitItemIcon(self.tItemScript[i], {
                dwTabType = tItem[1],
                dwIndex = tItem[2],
            }, tItem[3], true)
            UIHelper.SetVisible(self.tItemScript[i]._rootNode, true)
            bShowReward = true
        end
    end
    UIHelper.SetVisible(self.WidgetQiYuAward, bShowReward)
    UIHelper.LayoutDoLayout(self.LayoutAwardList)
    UIHelper.LayoutDoLayout(self.WidgetQiYuAward)
end

function UIAdventureTryBookDesc:UpdateChance()
    local tAdv = self.tAdv
    local tTryBook = tAdv.tTryBook
    local tDaily = {}
    local tWeekly = {}
    for _, tTry in ipairs(tTryBook) do
        if tTry.nFreshType == 1 then
            table.insert(tDaily, tTry)
        else
            table.insert(tWeekly, tTry)
        end
    end
    local szDailyTip = ""
    if #tDaily ~= 0 then
        for _, tTry in ipairs(tDaily) do
            if tTry.nTryMax == -1 then
                szDailyTip = szDailyTip .. string.format("<color=#5d5639>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc))
            else
                if tTry.nHasTry >= tTry.nTryMax then
                    szDailyTip = szDailyTip .. string.format("<color=#4e804e>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc) .."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax))
                else
                    szDailyTip = szDailyTip .. string.format("<color=#5d5639>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc) .."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax))
                end
            end
        end
    end
    local szWeeklyTip = ""
    if #tWeekly ~= 0 then
        for _, tTry in ipairs(tWeekly) do
            if tTry.nTryMax == -1 then
                szWeeklyTip = szWeeklyTip .. string.format("<color=#5d5639>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc))
            else
                if tTry.nHasTry >= tTry.nTryMax then
                    szWeeklyTip = szWeeklyTip .. string.format("<color=#4e804e>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc).."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax))
                else
                    szWeeklyTip = szWeeklyTip .. string.format("<color=#5d5639>%s</color>\n", UIHelper.GBKToUTF8(tTry.szDesc).."："..SimpleDate(tTry.nHasTry).."/"..SimpleDate(tTry.nTryMax))
                end
            end
        end
    end
    local szFrontTip = ""
    if tAdv.szFront ~= "" then
        local tHasChance = tAdv.tHasChance
        local tFront = SplitString(UIHelper.GBKToUTF8(tAdv.szFront), "\n")
        for i, szText in ipairs(tFront) do
            if tHasChance[i] then
                szFrontTip = szFrontTip .. string.format("<color=#4e804e>%s</color>\n", szText)
            else
                szFrontTip = szFrontTip .. string.format("<color=#5d5639>%s</color>\n", szText)
            end
        end
    end

    if tAdv.bTrigger or tAdv.bHasChance then
        if szDailyTip ~= "" then
            self:AddWidget(self.WidgetQiYuDaily)
        end
        if szWeeklyTip ~= "" then
            self:AddWidget(self.WidgetQiYuWeekly)
        end
        if szFrontTip ~= "" then
            self:AddWidget(self.WidgetQiYuDemand)
        end
    else
        if szFrontTip ~= "" then
            self:AddWidget(self.WidgetQiYuDemand)
        end
        if szDailyTip ~= "" or szWeeklyTip ~= "" then
            self:AddWidget(self.WidgetQiYuWarning)
        end
        if szDailyTip ~= "" then
            self:AddWidget(self.WidgetQiYuDaily)
        end
        if szWeeklyTip ~= "" then
            self:AddWidget(self.WidgetQiYuWeekly)
        end
    end

    if szDailyTip ~= "" then
        szDailyTip = szDailyTip:gsub("\n$", "")
        local label = UIHelper.GetChildByName(self.WidgetQiYuDaily, "LabelContent")
        UIHelper.SetRichText(label, szDailyTip)
        local btnGo = UIHelper.GetChildByName(self.WidgetQiYuDaily, "BtnGo")
        UIHelper.BindUIEvent(btnGo, EventType.OnClick, function ()
            if self.tAdv and self.tAdv.tPet then
                AdventureData.TeleportGoPet(self.tAdv.tPet)
            end
        end)
        UIHelper.SetVisible(btnGo, self.bZhenQi)
        UIHelper.LayoutDoLayout(self.WidgetQiYuDaily)
    end

    if szWeeklyTip ~= "" then
        szWeeklyTip = szWeeklyTip:gsub("\n$", "")
        local label = UIHelper.GetChildByName(self.WidgetQiYuWeekly, "LabelContent")
        UIHelper.SetRichText(label, szWeeklyTip)
        UIHelper.LayoutDoLayout(self.WidgetQiYuWeekly)
    end

    if szFrontTip ~= "" then
        szFrontTip = szFrontTip:gsub("\n$", "")
        local label = UIHelper.GetChildByName(self.WidgetQiYuDemand, "LabelContent")
        UIHelper.SetRichText(label, szFrontTip)
        UIHelper.LayoutDoLayout(self.WidgetQiYuDemand)
    end
end

function UIAdventureTryBookDesc:AddWidget(widget)
    local szName = widget:getName()
    if not self.tRetainWidget[szName] then
        return
    end
    self.ScrollViewContent:addChild(widget)
    widget:release()
    self.tRetainWidget[szName] = nil
end

function UIAdventureTryBookDesc:RemoveWidget(widget)
    local szName = widget:getName()
    if self.tRetainWidget[szName] then
        return
    end
    widget:retain()
    widget:removeFromParent(false)
    self.tRetainWidget[szName] = widget
end

return UIAdventureTryBookDesc