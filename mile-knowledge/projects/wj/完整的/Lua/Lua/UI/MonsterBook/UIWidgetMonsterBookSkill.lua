local UIWidgetMonsterBookSkill = class("UIWidgetMonsterBookSkill")

function UIWidgetMonsterBookSkill:OnEnter(dwPlayerID, dwCenterID, szGlobalID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwPlayerID = dwPlayerID or UI_GetClientPlayerID()
    self.dwCenterID = dwCenterID or GetCenterID() or 0
    self.szGlobalID = szGlobalID
    if not szGlobalID then
        local hPlayer = GetPlayer(self.dwPlayerID)
        if hPlayer then
            self.dwCenter = GetCenterID() or 0
            self.szGlobalID = hPlayer.GetGlobalID()
        end
    end
    if self.dwPlayerID ~= UI_GetClientPlayerID() then
        self:TryShowOtherPlayer()
    else
        self:InitMonsterBookSkill()
        self:UpdateImpart()
        self:UpdateSpiritEndurance()
        self:UpdateCollectList()
    end
end

function UIWidgetMonsterBookSkill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkill:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnActivate, EventType.OnClick, function ()
        self:ActiveSkill(true)
    end)

    UIHelper.BindUIEvent(self.BtnInactivate, EventType.OnClick, function ()
        self:ActiveSkill(false)
    end)

    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function ()
        local tSkillCollected = self:GetSkillCollected()
        local nLevel = tSkillCollected[self.dwSkillID] or 0
        local bHasActiveBook = MonsterBookData.IsHaveActiveBook(self.dwSkillID, nLevel + 1)
        local bHasBook, bHasReplaceBook = MonsterBookData.IsHaveCommonActiveBook(nLevel + 1)
        if bHasActiveBook then
            UIMgr.Open(VIEW_ID.PanelBaiZhanSkillBag, self.dwSkillID, nLevel, function (item, dwBox, dwIndex)
                self:UpgradeSkill(item, dwBox, dwIndex)
            end)
        elseif bHasReplaceBook then
            local szLevel = g_tStrings.tChineseNumber[nLevel + 1]
            local szTextNum, szName, szReplaceName = MonsterBookData.GetActiveBookReplaceCost(nLevel + 1)
            local tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
            local szSkillName = UIHelper.GBKToUTF8(tSkillInfo.szSkillName)
            szName = UIHelper.GBKToUTF8(szName)
            szReplaceName = UIHelper.GBKToUTF8(szReplaceName)
            local szMessage = string.format("是否确定抄写1本%s为%s本%s，并用于提升招式[%s]至%s重?", szReplaceName, szTextNum, szName, szSkillName, szLevel)
            UIHelper.ShowConfirm(szMessage, function ()
                RemoteCallToServer("On_MonsterBook_CollectSkill", self.dwSkillID)
            end, nil, true)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        self.bNeedRebuild = true
        self:UpdateCollectList()
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.MonsterBook)
    end)

    UIHelper.BindUIEvent(self.BtnSort, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSort, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.MonsterBookSkillSort)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 42)
    end)

    UIHelper.BindUIEvent(self.WidgetJingShenNaiLi, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelJingShenNaiLiDetailPop, self.tCollectData)
        Storage.MonsterBook.bCheckSEDetailRedDot = true
        UIHelper.SetVisible(self.ImgSERedDot, not Storage.MonsterBook.bCheckSEDetailRedDot)
    end)

    UIHelper.BindUIEvent(self.BtnScheme, EventType.OnClick, function ()
        self:ShowSchemePanel()
    end)

    UIHelper.BindUIEvent(self.BtnSaveScheme, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelSaveBZSkillPop)
    end)
end

function UIWidgetMonsterBookSkill:RegEvent()
    Event.Reg(self, "ON_UPDATE_SKILL_COLLECTION", function ()
        self.bGetSkillData = true
        self:DoShowOtherPlayer()
        self:InitMonsterBookSkill()
        self:UpdateImpart()
        self:UpdateSpiritEndurance()
        self:UpdateCollectList()
    end)

    Event.Reg(self, "On_MonsterBook_ActiveCallBack", function (bResult)
        if bResult and MonsterBookData.bIsPlaying then
            Event.Dispatch(EventType.OnEnterMonsterBookScene)
        end
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (dwPlayerID)
        if dwPlayerID == self.dwPlayerID then
            self.bTargetLeave = true
        end
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tFilter)
        if szKey == FilterDef.MonsterBook.Key or szKey == FilterDef.MonsterBookSkillSort.Key then
            self:ApplyFilter()
            self:ApplySort()
            self:UpdateCollectList()
        end
    end)
end

function UIWidgetMonsterBookSkill:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonsterBookSkill:InitMonsterBookSkill()
    self.nImpartSkillID    = 0
    self.nImpartLevel      = 0
    self.tImpartSkillList  = {}
    self.nImpartCounts     = 0
    self.nMaxImpartCounts  = 0
    self.nBeImpartedCounts = 0
    self.nMaxBeImpCounts   = 0
    self.bEnableLevelChange = true
    self.tSkillScriptList = {}
    self.tActivedScriptList = {}

    FilterDef.MonsterBook.Reset()

    self.scriptBZSkillSchemeSide = self.scriptBZSkillSchemeSide or UIHelper.AddPrefab(PREFAB_ID.WidgetBZSkillSchemeSide, self.WidgetAnchorRightPanel, {
        fHidePanelCallback = function ()
            self:HideSchemePanel()
        end
    })
    UIHelper.SetVisible(self.WidgetAnchorRightPanel, false)

    self:ApplyFilter()
    self:ApplySort()
    self:InitCollectData()

    UIHelper.SetVisible(self.ImgSERedDot, not Storage.MonsterBook.bCheckSEDetailRedDot)
end

function UIWidgetMonsterBookSkill:InitCollectData()
    local player = self:GetPlayer()
    if not player then return end

    local nSpiritMaxValue, nEnduranceMaxValue =  GDAPI_SpiritEndurance_GetMaxValue(player)
    local tSEInfoList = MonsterBookData.GetBossExtraSEInfoList(player)
    local nRoleType = player.nRoleType
    self.tCollectData = {
        nSpiritMaxValue = nSpiritMaxValue,
        nEnduranceMaxValue = nEnduranceMaxValue,
        tSEInfoList = tSEInfoList,
        nRoleType = nRoleType
    }
end

function UIWidgetMonsterBookSkill:ApplyFilter(nFiltType, nFiltID)
    -- 筛选
    if not self.tSearchFilter then
        self.tSearchFilter = {1,1,1,1,1}
    end
    for nIndex, tSelected in ipairs(FilterDef.MonsterBook.GetRunTime() or {}) do
        self.tSearchFilter[nIndex] = tSelected[1]
    end
    if nFiltType and nFiltID then
        self.tSearchFilter[nFiltType] = nFiltID
    end
    local nType = self.tSearchFilter[1]
    self.tTypeFiltedList = self:GetFiltedList(nType, self.tSearchFilter, nil, self.dwPlayerID)
end

function UIWidgetMonsterBookSkill:ApplySort()
    -- 筛选
    local tSelected = FilterDef.MonsterBookSkillSort.GetRunTime() or {{1}}
    self.nSortType = tSelected[1][1] or 1

    local tSkillCollected = self:GetSkillCollected()

    local fSort
    if self.nSortType == 1 then -- 重数
        fSort = function (tSkillInfo1, tSkillInfo2)
            local nLevel1 = tSkillCollected[tSkillInfo1.dwOutSkillID] or 0
            local nLevel2 = tSkillCollected[tSkillInfo2.dwOutSkillID] or 0
            return nLevel1 > nLevel2
        end
    elseif self.nSortType == 2 then -- 颜色
        fSort = function (tSkillInfo1, tSkillInfo2)
            return tSkillInfo1.nColor > tSkillInfo2.nColor
        end
    elseif self.nSortType == 3 then -- 首领
        fSort = function (tSkillInfo1, tSkillInfo2)
            local nValue1 = MonsterBookData.tBossNameHashMap[tSkillInfo1.szBossName]
            local nValue2 = MonsterBookData.tBossNameHashMap[tSkillInfo2.szBossName]
            return nValue1 < nValue2
        end
    end
    table.sort(self.tTypeFiltedList, fSort)
    self.bNeedRebuild = true
end

function UIWidgetMonsterBookSkill:ActiveSkill(bActive)
    if not self.dwSkillID then
        return
    end
    if bActive then
        MonsterBookData.PreActiveSkill(self.dwSkillID)
    end
    RemoteCallToServer("On_MonsterBook_ActiveSkill", self.dwSkillID, bActive)
end

function UIWidgetMonsterBookSkill:UpgradeSkill(item, dwBox, dwIndex)
    local scriptSkill = self.tSkillScriptList[self.dwSkillID]
    if not scriptSkill then
        return
    end
    
    local bCommon = item.dwIndex == 45845 or item.dwIndex == 50769 or item.dwIndex == 66154 or item.dwIndex == 75452
    if bCommon then
        local tSkillCollected = self:GetSkillCollected()
        local dwSkillID = scriptSkill.dwSkillID
        local tSkillInfo = Table_GetMonsterSkillInfo(dwSkillID)
        local szSkillName = UIHelper.GBKToUTF8(tSkillInfo.szSkillName)
        local nLevel = tSkillCollected[dwSkillID] or 0
        nLevel = nLevel + 1
        local szLevel = g_tStrings.STR_NUMBER[nLevel]
        local szTextNum, szBookName = MonsterBookData.GetActiveBookCost(nLevel)
        local szMessage = string.format("升级%s至%s重，需要消耗%s本%s\n是否确定升级？", szSkillName, szLevel, szTextNum, szBookName)
        UIHelper.ShowConfirm(szMessage, function ()
            RemoteCallToServer("On_MonsterBook_CollectSkill", dwSkillID)
        end)
    else
        ItemData.UseItem(dwBox, dwIndex)
    end 
end

function UIWidgetMonsterBookSkill:TryShowOtherPlayer()
    PeekOtherPlayerSkillCollection(self.dwCenterID, self.szGlobalID)
    UIHelper.SetVisible(self.BtnHelp, false)
    local nodeParent = UIHelper.GetParent(self.ScrollViewSkillInfo)
    local nTotalHeight = UIHelper.GetHeight(nodeParent)
    local nOffset = UIHelper.GetPositionY(self.ScrollViewSkillInfo) or 0
    nOffset = nTotalHeight / 2 - math.abs(nOffset)
    UIHelper.SetHeight(self.ScrollViewSkillInfo, nTotalHeight - nOffset - 4)

    self.bGetSkillData = false
    UIHelper.SetString(self.LabelCheckData, "正在查询玩家百战信息...")
    UIHelper.SetVisible(self.WidgetCheckFailed, true)
    UIHelper.SetVisible(self.WidgetAniLeft, false)
    UIHelper.SetVisible(self.WidgetAniRightTop, false)
    UIHelper.SetVisible(self.WidgetAniRight, false)

    self.nTimerID = Timer.Add(self, 10, function ()
        self:DoShowOtherPlayer()
    end)
end

function UIWidgetMonsterBookSkill:DoShowOtherPlayer()
    if not self.bGetSkillData then
        UIHelper.SetString(self.LabelCheckData, "查询玩家百战信息失败，对方或已离线")
    end
    UIHelper.SetVisible(self.WidgetCheckFailed, not self.bGetSkillData)
    UIHelper.SetVisible(self.WidgetAniLeft, self.bGetSkillData)
    UIHelper.SetVisible(self.WidgetAniRight, self.bGetSkillData)
    UIHelper.SetVisible(self.WidgetAniRightTop, self.bGetSkillData)
end

-------------------------------------表现-------------------------------------------
function UIWidgetMonsterBookSkill:UpdateImpart()
    self:UpdateImpartSkill()
    self:UpdateImpartCostPoints()
end

function UIWidgetMonsterBookSkill:UpdateImpartSkill()
    local player = self:GetPlayer()
    if not player then
        return
    end
    local nImpartSkillID = self.nImpartSkillID
    local nLevel = self.nImpartLevel
    local bSelectedSkill = nImpartSkillID and nLevel and nImpartSkillID ~= 0 and nLevel ~= 0
    if bSelectedSkill then

        local nMaxLevel = self.tImpartSkillList[nImpartSkillID]
        if nMaxLevel then
            nLevel = math.min(nLevel, nMaxLevel)
            self:SetImpartSkillLevel(nLevel)
        end
    end
end

function UIWidgetMonsterBookSkill:UpdateImpartCostPoints()
    local nLevel = self.nImpartLevel

    local szCost = ""
    local tCostPoints = GDAPI_MonsterBook_GetImpartCostPoints()
    local nCost = tCostPoints[nLevel]
    if nCost then
        szCost = FormatString(g_tStrings.MONSTER_BOOK_IMPART_COST_POINTS, nCost)
    end

end

function UIWidgetMonsterBookSkill:UpdateSpiritEndurance()
    local player = self:GetPlayer()
    if player then
        self.nSpirit, self.nEndurance = GDAPI_SpiritEndurance_GetMaxValue(player)
    end
    local nSpirit = self.nSpirit or 0
    local nEndurance = self.nEndurance or 0

    UIHelper.SetString(self.LabelJingshenNum, tostring(nSpirit))
    UIHelper.SetString(self.LabelNailiNum, tostring(nEndurance))
    UIHelper.LayoutDoLayout(self.WidgetJingshenLimit)
end

function UIWidgetMonsterBookSkill:UpdateCollectList()
    local szSearch = UIHelper.GetText(self.EditBoxSearch)
    local tFiltedList = MonsterBookData.GetSearchList(UIHelper.UTF8ToGBK(szSearch), self.tTypeFiltedList) or {}
    tFiltedList = self:FilterImpartList(tFiltedList, self.tSearchFilter[5])
    self.tFiltedList = tFiltedList
    local tSkillCollected = self:GetSkillCollected()
    
    if self.bNeedRebuild or not self:TryRefresh(tSkillCollected, tFiltedList) then
        self:TryRebuild(tSkillCollected, tFiltedList)
    end

    self:UpdateActivedSkillList()
    local bNull = #tFiltedList == 0
    UIHelper.SetVisible(self.WidgetEmpty, bNull)

    self:RedirectSkillPosition()
    Timer.AddFrame(self, 1, function ()
        self:UpdateSkillDetail()
    end)
end

function UIWidgetMonsterBookSkill:UpdateSkillDetail()
    UIHelper.SetVisible(self.WidgetAnchorRight, self.dwSkillID ~= nil)
    UIHelper.SetVisible(self.WidgetEmptyDetail, self.dwSkillID == nil)
    if not self.dwSkillID then
        return
    end

    local scriptSkill = self.tSkillScriptList[self.dwSkillID]
    if scriptSkill then
        UIHelper.SetSelected(scriptSkill.ToggleSelect, true, false)
    end
    local scriptActive = self.tActivedScriptList[self.dwSkillID]
    if scriptActive then
        UIHelper.SetSelected(scriptActive.ToggleSelect, true, false)
    end

    local tSkillCollected = self:GetSkillCollected()

    local tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
    local nLevel = tSkillCollected[self.dwSkillID] or 0
    local nOriginLevel = nLevel
    if nLevel == 0 then
        nLevel = 1
    end
    local tSkill = Table_GetSkill(self.dwSkillID, nLevel) or {}
    local szSkillName = UIHelper.GBKToUTF8(tSkillInfo.szSkillName)
    local szBossName = UIHelper.GBKToUTF8(tSkillInfo.szBossName)
    szBossName = "首领："..szBossName
    local szColorPath, szColorName = MonsterBookData.GetEdgeColorPath(tSkillInfo.nColor)
    local szActive = "未激活"
    local bActive = MonsterBookData.IsActiveSkill(self.dwSkillID)
    if bActive then
        szActive = "已激活"
    end
    local bHasActiveBook = MonsterBookData.IsHaveActiveBook(self.dwSkillID, nOriginLevel + 1)
    local bHasBook, bHasReplaceBook = MonsterBookData.IsHaveCommonActiveBook(nOriginLevel + 1)
    bHasActiveBook = bHasActiveBook or bHasBook or bHasReplaceBook

    local bCheckOther = self.dwPlayerID and self.dwPlayerID ~= UI_GetClientPlayerID()
    UIHelper.SetString(self.LabelSkillName, szSkillName)
    UIHelper.SetString(self.LabelColor, szColorName or "")
    UIHelper.SetString(self.LabelSkillStatus, szActive)
    if szColorPath then
        UIHelper.SetSpriteFrame(self.ImgColorBar, szColorPath)
    end
    UIHelper.SetVisible(self.ImgColorBar, szColorPath ~= nil)
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnActivate), not bActive and not bCheckOther)
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnInactivate), bActive and not bCheckOther)
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnUpgrade), bHasActiveBook and not bCheckOther)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
    UIHelper.RemoveAllChildren(self.LayoutSkillInfo)
    -- 类型描述
    local player = self:GetPlayer()
    if player then
        self.tRecipeKeyMap[self.dwSkillID] = player.GetSkillRecipeKey(self.dwSkillID, nLevel)
    end
    local tRecipeKey = self.tRecipeKeyMap[self.dwSkillID]
    UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContentBaiZhanTop, self.ScrollViewSkillInfo, tRecipeKey)
    if szBossName then
        local scriptBossName = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptBossName:OnEnter({szBossName})
    end
    -- 获取渠道
    local szText = UIHelper.AttachTextColor(g_tStrings.ITEM_TIP_SOURCE_TRADE, FontColorID.ValueChange_Yellow)
    local dwItemTabType = 5
    for nBookLevel = nLevel, MonsterBookData.MAX_SKILL_LEVEL do
        local dwItemIndex = MonsterBookData.GetMonsterBookItemIndex(self.dwSkillID, nBookLevel)
        local itemInfo = GetItemInfo(dwItemTabType, dwItemIndex)
        if itemInfo and itemInfo.nQuality >= 4 then
            local szLinkInfo = string.format("SourceTradeWithName/%s", szSkillName)
            local tInfo = {}
            table.insert(tInfo, { szText = szText, szLinkInfo = szLinkInfo })
            local scriptSource = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10, self.ScrollViewSkillInfo)
            scriptSource:OnEnter({tInfo})
            break
        end
    end

    -- 技能描述
    local szDesc = Table_GetSkillSpecialDesc(self.dwSkillID, nLevel)
    szDesc = UIHelper.GBKToUTF8(szDesc)    
    if szDesc and szDesc ~= "" then
        szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    szDesc = GetSkillDesc(self.dwSkillID, nLevel)
    szDesc = UIHelper.GBKToUTF8(szDesc)    
    if szDesc and szDesc ~= "" then
        szDesc = ParseTextHelper.DevideFormatText(szDesc, "<color=#AED9E0>%s</c>")
        -- szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    szDesc = UIHelper.GBKToUTF8(tSkill.szHelpDesc)
    if szDesc and szDesc ~= "" then
        szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    local szUpgrade = "提升"
    if nOriginLevel == 0 then szUpgrade = "收集" end
    UIHelper.SetString(self.LabelUpgrade, szUpgrade)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillInfo)

    Timer.AddFrame(self, 1, function ()
        self:AutoFixScrollViewSkillInfo()
    end)
end

function UIWidgetMonsterBookSkill:AutoFixScrollViewSkillInfo()
    local nTotalHeight = UIHelper.GetHeight(self.ScrollViewSkillInfo)
    local nodeChildren = UIHelper.GetChildren(self.ScrollViewSkillInfo) or {}
    if #nodeChildren == 0 then return end

    local nSpacingY = 4
    local nChildrenHeight = nSpacingY * (#nodeChildren - 1)
    for _, nodeChild in ipairs(nodeChildren) do
        nChildrenHeight = nChildrenHeight + UIHelper.GetHeight(nodeChild)
    end

    local nSpaceHeight = nTotalHeight - nChildrenHeight
    if nSpaceHeight > 0 then
        local nWidgetContentBase = 54 -- 文字标签基础高度
        local nWidgetContentStep = 34 -- 文字标签每多一行增加的高度
        local nStepCount = math.ceil((nSpaceHeight-nWidgetContentBase)/nWidgetContentStep)
        if nStepCount <= 0 then nStepCount = 1 end
        local szDesc = ""
        for i = 1, nStepCount do
            szDesc = szDesc .. "\n"
        end
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillInfo)
    end
end

function UIWidgetMonsterBookSkill:UpdateActivedSkillList()
    local tActiveList = self:GetActiveSkillList()
    local tSkillCollected = self:GetSkillCollected()
    local nTotalCost = 0
    self.tActivedScriptList = {}
    for nIndex, nodeParent in ipairs(self.WidgetActivedSkillItems) do
        UIHelper.RemoveAllChildren(nodeParent)
        local bVisable = nIndex <= #tActiveList
        if bVisable then
            local dwSkillID = tActiveList[nIndex]
            local nLevel = tSkillCollected[dwSkillID] or 0
            local scriptActive = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, nodeParent, dwSkillID, nLevel, function ()
                self.dwSkillID = dwSkillID
                self:ClearAllSkillSelectState()
                self:UpdateSkillDetail()
                self:RedirectSkillPosition()
            end)
            scriptActive:SetDisableSkillTip(true)
            scriptActive:SetActived(true)
            self.tActivedScriptList[dwSkillID] = scriptActive            
            local tSkillInfo = Table_GetMonsterSkillInfo(dwSkillID)
            nTotalCost = nTotalCost + tSkillInfo.nCost
            UIHelper.SetAnchorPoint(scriptActive._rootNode, 0.5, 0)
            UIHelper.SetToggleGroupIndex(scriptActive.ToggleSelect, ToggleGroupIndex.MonsterBookActiveSkill)
        end
        local nodeEmpty = self.WidgetActiveEmptyList[nIndex]
        UIHelper.SetVisible(nodeEmpty, not bVisable)
    end

    for nPoints, WidgetPoint in ipairs(self.WidgetActiveCostPoints) do
        UIHelper.SetVisible(WidgetPoint, nPoints <= nTotalCost)
    end

    for dwSkillID, scriptSkill in pairs(self.tSkillScriptList) do
        scriptSkill:SetActived(self.tActivedScriptList[dwSkillID] ~= nil)
    end

    UIHelper.LayoutDoLayout(self.LayoutCostAll)
end

function UIWidgetMonsterBookSkill:ClearAllSkillSelectState()
    for _, scriptSkill in pairs(self.tSkillScriptList) do
        UIHelper.SetSelected(scriptSkill.ToggleSelect, false, false)
    end
end

function UIWidgetMonsterBookSkill:RedirectSkillPosition()
    local MAX_COLUMN_COUNT = 8  -- 每行有8个技能
    local nMaxRowCount = math.ceil(#self.tFiltedList / MAX_COLUMN_COUNT)
    if nMaxRowCount <= 4 then return end -- 没有超过一屏就不用重定位
    local nTargetIndex = 1
    for nIndex, tSkillInfo in ipairs(self.tFiltedList) do
        if tSkillInfo.dwOutSkillID == self.dwSkillID then
            nTargetIndex = nIndex
            break
        end
    end
    local nRow = math.ceil(nTargetIndex / MAX_COLUMN_COUNT)
    if nRow < MAX_COLUMN_COUNT / 2 then
        nRow = nRow - (nMaxRowCount - nRow + 1) / nMaxRowCount
    else
        nRow = nRow
    end
    local nPercent = nRow/nMaxRowCount * 100
    if nPercent > 100 then
        nPercent = 100
    elseif nPercent < 0 then
        nPercent = 0
    end
    UIHelper.ScrollToPercent(self.ScrollViewSkillList, nPercent)
end

-------------------------------------数据-------------------------------------------
function UIWidgetMonsterBookSkill:UpdateImpartSkillList()
    local player = self:GetPlayer()
    if player then
        self.tMonsterBookImpartSkillList =  GDAPI_MonsterBook_GetImpartSkill(player)
    end
    local tSkillList =  self.tMonsterBookImpartSkillList
    if not tSkillList then
        return
    end
    for _, tSkill in ipairs(tSkillList) do
        local dwSkillID = tSkill[1]
        local nMaxImpartLevel = tSkill[2]
        if dwSkillID and nMaxImpartLevel and dwSkillID > 0 and nMaxImpartLevel > 0 then
            self.tImpartSkillList[dwSkillID] = nMaxImpartLevel
        end
    end
end

function UIWidgetMonsterBookSkill:SetImpartSkillLevel(nLevel)
    local dwSkillID = self.nImpartSkillID
    local tImpartSkillList = self.tImpartSkillList
    local nMaxLevel = tImpartSkillList[dwSkillID]
    if not nMaxLevel or not nLevel or nLevel < 0 or nLevel > nMaxLevel then
        nLevel = 0
    end
    self.nImpartLevel = nLevel
end

function UIWidgetMonsterBookSkill:FilterImpartList(tSkillList, nFilterIndex)
    if nFilterIndex == 1 then
        return tSkillList
    end
    self:UpdateImpartSkillList()
    local tFilterCanImpart = {}
    local tFilterCannotImpart = {}
    local tImpartSkillList = self.tImpartSkillList
    for _, tLine in ipairs(tSkillList) do
        local dwSkillID = tLine.dwOutSkillID
        if tImpartSkillList[dwSkillID] and tImpartSkillList[dwSkillID] > 0 then
            table.insert(tFilterCanImpart, tLine)
        else
            table.insert(tFilterCannotImpart, tLine)
        end
    end
    if nFilterIndex == 2 then
        return tFilterCanImpart
    elseif nFilterIndex == 3 then
        return tFilterCannotImpart
    end
end

function UIWidgetMonsterBookSkill:TryRefresh(tSkillCollected, tFiltedList)
    if #tFiltedList ~= table.GetCount(self.tSkillScriptList) then
        return false
    end
    local tRefreshScriptList = {}
    for nIndex, v in ipairs(tFiltedList) do
        local dwSkillID = v.dwOutSkillID
        local nLevel = tSkillCollected[dwSkillID] or 0
        local scriptSkill = self.tSkillScriptList[dwSkillID]
        if not scriptSkill then
            return false
        elseif nLevel ~= scriptSkill.nLevel then
            scriptSkill.dwSkillID = dwSkillID
            scriptSkill.nLevel = nLevel
            table.insert(tRefreshScriptList, scriptSkill)
        end
    end

    for _, scriptSkill in ipairs(tRefreshScriptList) do
        scriptSkill:OnEnter(scriptSkill.dwSkillID, scriptSkill.nLevel, scriptSkill.fCallBack)
        scriptSkill:SetActived(false)
        local scriptActive = self.tActivedScriptList[scriptSkill.dwSkillID]
        if scriptActive then
            scriptActive:OnEnter(scriptActive.dwSkillID, scriptActive.nLevel, scriptActive.fCallBack)
            scriptActive:SetActived(true)
            scriptSkill:SetActived(true)
        end
    end
    return true
end

function UIWidgetMonsterBookSkill:TryRebuild(tSkillCollected, tFiltedList)
    local player = self:GetPlayer()
    self.bNeedRebuild = false
    local bHasRedirect = false
    local scriptFirst
    self.tSkillScriptList = {}
    self.tRecipeKeyMap = {}
    UIHelper.RemoveAllChildren(self.LayoutSkillList)
    for nIndex, v in ipairs(tFiltedList) do
        local dwSkillID = v.dwOutSkillID
        local nLevel = tSkillCollected[dwSkillID] or 0
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, self.ScrollViewSkillList, dwSkillID, nLevel, function ()
            self.dwSkillID = dwSkillID
            self:UpdateSkillDetail()
            local scriptActive = self.tActivedScriptList[dwSkillID]
            if not scriptActive then
                for _, scriptActive in pairs(self.tActivedScriptList) do
                    UIHelper.SetSelected(scriptActive.ToggleSelect, false)
                end
            end
        end)
        scriptSkill:SetDisableSkillTip(true)
        self.tSkillScriptList[dwSkillID] = scriptSkill
        if not self.dwSkillID then
            self.dwSkillID = dwSkillID
            scriptFirst = scriptSkill
        end
        UIHelper.SetSelected(scriptSkill.ToggleSelect, self.dwSkillID == dwSkillID)
        bHasRedirect = bHasRedirect or self.dwSkillID == dwSkillID
        if player then self.tRecipeKeyMap[dwSkillID] = player.GetSkillRecipeKey(dwSkillID, nLevel) end
    end
    if not bHasRedirect and scriptFirst then
        UIHelper.SetSelected(scriptFirst.ToggleSelect, true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UIWidgetMonsterBookSkill:GetSkillCollected()
    local player = self:GetPlayer()
    if player then
        self.tSkillCollected = player.GetAllSkillInCollection()
    end
    
    return self.tSkillCollected or {}
end

function UIWidgetMonsterBookSkill:GetActiveSkillList()
    local player = self:GetPlayer()
    if player then
        self.tActiveList = player.GetAllActiveSkillInCollection()
    end

    local tActiveList = self.tActiveList or {}
    table.sort(tActiveList, MonsterBookData.SortActiveSkill)
    return tActiveList
end

function UIWidgetMonsterBookSkill:GetFiltedList(nType, tSearchFilter, tSkillID, dwPlayerID)
    nType = nType - 1
    local nCost = tSearchFilter[2] - 1 or 0
    local nColor = tSearchFilter[3] - 1 or 0
    local nLevel = tSearchFilter[4] - 1 or 0
    local tSkillLevel = self:GetSkillCollected()
    local tSkillAll = {}
    if tSkillID then
        for nIndex, dwSkillID in pairs(tSkillID) do
            local tLine = Table_GetMonsterSkillInfo(dwSkillID)
            tLine.nLevel = tSkillLevel[tLine.dwOutSkillID]
            table.insert(tSkillAll, tLine)
        end
    else
        tSkillAll = Table_GetAllMonsterSkill()
        for _, tLine in pairs(tSkillAll) do
            tLine.nLevel = tSkillLevel[tLine.dwOutSkillID]
        end
    end

    local tSkillFilt = {}
    for _, tLine in pairs(tSkillAll) do
        local bAdd = true
        if tLine.bDeprecated
        or (nCost and nCost ~= 0 and nCost ~= tLine.nCost)
        or (nColor and nColor ~= 0 and nColor ~= tLine.nColor)
        or (nLevel and nLevel ~= 0 and nLevel ~= tLine.nLevel)
        then
            bAdd = false
        elseif nType and nType ~= 0 then
            local bSameType = false
            local tType = SplitString(tLine.szType, ";")
            for _, v in ipairs(tType) do
                if tonumber(v) == nType then
                    bSameType = true
                    break
                end
            end
            if bSameType == false then
                bAdd = false
            end
        end
        if bAdd then
            table.insert(tSkillFilt, tLine)
        end
    end
    return tSkillFilt
end

function UIWidgetMonsterBookSkill:GetPlayer()
    if self.bTargetLeave then return nil end

    return GetPlayer(self.dwPlayerID)
end

function UIWidgetMonsterBookSkill:RedirectSkill(dwSkillID)
    self.dwSkillID = dwSkillID
    UIHelper.SetText(self.EditBoxSearch, "")
    self.bNeedRebuild = true
    FilterDef.MonsterBook.Reset()
    self.tSearchFilter = {1,1,1,1,1}
    self:ApplyFilter()
    self:ApplySort()
    self:UpdateCollectList()
end

function UIWidgetMonsterBookSkill:ShowSchemePanel()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBaizhanMain)
    UIHelper.SetVisible(scriptView.BtnClose, false)

    UIHelper.PlayAni(scriptView, scriptView.AniAll, "AniBottomHide", function ()        
        UIHelper.SetVisible(scriptView.WidgetAniBottom, false)
    end)

    UIHelper.SetVisible(self.WidgetAnchorRightPanel, true)
    UIHelper.PlayAni(self.scriptBZSkillSchemeSide, self.scriptBZSkillSchemeSide.AniAll, "AniRightShow")
end

function UIWidgetMonsterBookSkill:HideSchemePanel()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBaizhanMain)
    UIHelper.SetVisible(scriptView.WidgetAniBottom, true)
    UIHelper.PlayAni(scriptView, scriptView.AniAll, "AniBottomShow")
    
    UIHelper.PlayAni(self.scriptBZSkillSchemeSide, self.scriptBZSkillSchemeSide.AniAll, "AniRightHide", function ()
        UIHelper.SetVisible(scriptView.BtnClose, true)
        UIHelper.SetVisible(self.WidgetAnchorRightPanel, false)
    end)
end

return UIWidgetMonsterBookSkill