---@class UIDungeonEntranceView
local UIDungeonEntranceView = class("UIDungeonEntranceView")
local ENUM_DUNGEON_TYPE = {
    SMALL_GROUP = 1, -- 小队秘境
    BIG_GROUP   = 2, -- 团队秘境
}

local DAILY_TEAM_FB = 29   --大战活动ID
local WEEKLY_TEAM_FB = 501 --五人本周常活动ID
local WEEKLY_RAID_FB = 502 --十人本周常活动ID
local COLLECTION_MAX_COUNT = 8  --秘境收藏上限

local ImgButtonPath = {
    ["Yellow"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_tuijian",
    ["Blue"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_Normal"
}

local function IsRaidFB(szName)
	local bRaid = false
    local tRaidName =
	{
		"10人",
		"25人",
	}
	for k, v in pairs(tRaidName) do
		local nStart, nEnd = string.find(szName, v)
		if nStart then
			bRaid = true
			break
		end
	end

	return bRaid
end

local function MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

local function GetDungeonTypeByMapID(dwMapID)
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    if not tDungeonInfo then return end

    if tDungeonInfo.dwClassID == 1 or tDungeonInfo.dwClassID == 2 then
        return ENUM_DUNGEON_TYPE.SMALL_GROUP
    else
        return ENUM_DUNGEON_TYPE.BIG_GROUP
    end
end

local function IsDungeonCollected(dwMapID)
	return Storage.Dungeon.tCollection[dwMapID] ~= nil
end

local function IsCollectionFull(nDungeonType)
    local nCount = 0
    for k, v in pairs(Storage.Dungeon.tCollection) do
        local nType = GetDungeonTypeByMapID(k)
        if nDungeonType == nType then
            nCount = nCount + 1
        end
    end
    return nCount >= COLLECTION_MAX_COUNT
end

local function UpdateDungeonCollection(dwMapID, nDungeonType, bCollect)
    if bCollect then
        if IsCollectionFull(nDungeonType) then
            return
        end

        Storage.Dungeon.tCollection[dwMapID] = true
    else
        Storage.Dungeon.tCollection[dwMapID] = nil
    end
end

local function IsDungeonCollection(dwMapID)
    local bCollect = Storage.Dungeon.tCollection[dwMapID] ~= nil
    return bCollect
end

function UIDungeonEntranceView:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
    end

    self:InitDungeonData()
    self:InitDungeonView(tParam)
    self:UpdateInfo()
    self:GetMapCopyProgress()
    RemoteCallToServer("OnApplyEnterMapInfoRequest")
    self.bChooseDailyOrWeekly = true

    Timer.AddFrame(self, 5, function ()
        self:OnFrameBreathe()
    end)

    Timer.AddFrame(self, 2, function ()
        if tParam then
            if tParam.bLinkWeeklyTeamDungeon then
                self:LinkWeeklyTeamDungeon()
            elseif tParam.bRaid then
                UIHelper.SetSelected(self.TogTabRaid, true, true)
            end
        end
    end)

    UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Show")
end

function UIDungeonEntranceView:OnExit()
    Storage.Dungeon.bRecommendOnly = self.bOldRecommendOnly or Storage.Dungeon.bRecommendOnly
    self.bInit = false
end

function UIDungeonEntranceView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonEntrance)
	end)

    UIHelper.BindUIEvent(self.BtnFindGroup, EventType.OnClick, function()
        local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwCurSelectMapID)
        if tRecruitInfo then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
        end
	end)

    UIHelper.BindUIEvent(self.BtnSingleMode, EventType.OnClick, function()
        self:OnTryEnterDungeonButtonCheckReset(true)
	end)

    UIHelper.BindUIEvent(self.BtnAssist, EventType.OnClick, function()
        if not self.dwCurSelectMapID then return end

        local szContent = string.format(g_tStrings.Dungeon.STR_ASSIST_RELEASE_TIP, AssistNewbieBase.GetReleaseCount(), AssistNewbieBase.RELEASE_MAX_COUNT)
        UIHelper.ShowConfirm(szContent, function ()
            AssistNewbieBase.Release(self.dwCurSelectMapID, ASSIST_NEWBIE_TYPE.DUNGEON)
        end)
	end)

    UIHelper.BindUIEvent(self.BtnNormalMode, EventType.OnClick, function()
        self:OnClickEnterDungeonButton()
	end)

    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function()
        self:StartGuide()
	end)

    UIHelper.BindUIEvent(self.BtnAchievements, EventType.OnClick, function()
        self:LinkToAchievements()
	end)

    UIHelper.BindUIEvent(self.TogTabTeam, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected and self.nDungeonType ~= ENUM_DUNGEON_TYPE.SMALL_GROUP then
            self.nDungeonType = ENUM_DUNGEON_TYPE.SMALL_GROUP
            self:UpdateDungeonInfo()
        end
	end)

    UIHelper.BindUIEvent(self.TogTabRaid, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected and self.nDungeonType ~= ENUM_DUNGEON_TYPE.BIG_GROUP then
            self.nDungeonType = ENUM_DUNGEON_TYPE.BIG_GROUP
            self:UpdateDungeonInfo()
        end
	end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function(_, bSelected)
		Storage.Dungeon.bRecommendOnly = bSelected
        self.bOldRecommendOnly = nil
        self:UpdateDungeonInfo()
	end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        if self.dwCurSelectMapID then
            local tDungeonInfo = Table_GetDungeonInfo(self.dwCurSelectMapID)
            local szName = UIHelper.GBKToUTF8(tDungeonInfo.szLayer3Name .. tDungeonInfo.szOtherName)
            local szLinkInfo = string.format("FBlist/%d", self.dwCurSelectMapID)
            ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
        end
	end)

    UIHelper.BindUIEvent(self.BtnPartner, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelPartner, nil, PartnerViewOpenType.Assist)
    end)

    UIHelper.BindUIEvent(self.BtnTeamProgress, EventType.OnClick, function ()
        if not self.dwCurSelectMapID then return end
        UIMgr.Open(VIEW_ID.PanelDungeonProgressPop, self.dwCurSelectMapID)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
        self.szSearchKey = UIHelper.GetText(self.EditKindSearch)
        self:UpdateDungeonInfo()
        self:AutoSkipEmptyPanel()
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnClick, function(toggle)
        local bSelect = UIHelper.GetSelected(self.TogLike)
        if bSelect and IsCollectionFull(self.nDungeonType) then
            TipsHelper.ShowImportantRedTip(g_tStrings.Dungeon.STR_COLLECT_FULL)
            UIHelper.SetSelected(self.TogLike, false, false)
            return
        end
        UpdateDungeonCollection(self.dwCurSelectMapID, self.nDungeonType, bSelect)
        self:Refresh()
    end)
end

function UIDungeonEntranceView:RegEvent()
    Event.Reg(self, EventType.OnMapEnterInfoNotify, function (tData, tData1)
        self:OnMapEnterInfoNotify(tData, tData1)
        if self.scriptDetail and self.scriptDetail.tRecord then self.scriptDetail:UpdateInfo(nil, self.tDungeonMapInfo, self.tDungeonCopyID) end
    end)

    Event.Reg(self, EventType.OnApplyPlayerSavedCopysRespond, function (tData)
        self:OnApplyPlayerSavedCopysRespond(tData)
        if self.scriptDetail and self.scriptDetail.tRecord then self.scriptDetail:UpdateInfo(nil, self.tDungeonMapInfo, self.tDungeonCopyID) end
    end)

    Event.Reg(self, EventType.OnResetMapRespond, function ()
        self:GetMapCopyProgress()
        if self.scriptDetail and self.scriptDetail.tRecord then self.scriptDetail:UpdateInfo(nil, self.tDungeonMapInfo, self.tDungeonCopyID) end
    end)

    Event.Reg(self, EventType.OnDungeonFliterSelectChanged, function (szName)
        self:OnDungeonFliterSelectChanged(szName)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        UIHelper.ScrollViewDoLayout(self.WidgetAutoToping)
        UIHelper.ScrollToTop(self.WidgetAutoToping, 0)
        UIHelper.ScrollViewDoLayout(self.ScrollViewTask)
        Timer.AddFrame(self, 1, function ()
            self:RedirectToDungeonPosition()
        end)

        Timer.AddFrame(self, 5, function ()
            for _, tContainer in ipairs(self.scriptDungeonList.tContainerList) do
                local scriptContainer = tContainer.scriptContainer
                for _, scriptCell in ipairs(scriptContainer.tItemScripts) do
                    local bVisible = UIHelper.GetVisible(scriptCell._rootNode)
                    if bVisible then UIHelper.LayoutDoLayout(scriptCell.LayoutTags) end
                end
            end
        end)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetTipMoreOperShell, false)
    end)

    Event.Reg(self, "UPDATE_VIGOR", function ()
        if self.VigorScript then
            local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
            local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
            self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function()
        Timer.AddFrame(self, 10, function () -- 队伍数据刷新实在是太慢了
            self:RefreshButtons()
        end)
    end)

    Event.Reg(self, "PARTY_MESSAGE_NOTIFY", function()
        Timer.AddFrame(self, 10, function ()
            self:RefreshButtons()
        end)
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        Timer.AddFrame(self, 10, function ()
            self:RefreshButtons()
        end)
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        Timer.AddFrame(self, 10, function ()
            self:RefreshButtons()
        end)
    end)
end

function UIDungeonEntranceView:InitDungeonView(tParam)
    tParam = tParam or {}
    self.tDungeonCopyID = {}
    self.tDungeonMapInfo = {}
    self.nDungeonType = ENUM_DUNGEON_TYPE.SMALL_GROUP
    self.tScriptDifficultyList = {}

    self.dwDefaultSelectMapID = tParam.dwTargetMapID
    tParam.bRecommendOnly = false -- 策划暂定全部强制取消推荐秘境
    if tParam.bRecommendOnly ~= nil then
        self.bOldRecommendOnly = Storage.Dungeon.bRecommendOnly
        Storage.Dungeon.bRecommendOnly = tParam.bRecommendOnly
    end

    self.scriptDungeonList = UIHelper.GetBindScript(self.WidgetContentDungeonList)
    self.scriptTipMoreOper = self.scriptTipMoreOper or UIHelper.AddPrefab(PREFAB_ID.WidgetTipMoreOper, self.WidgetTipMoreOperShell)

    if DungeonData.tDungeonMapDataBuffer1 or DungeonData.tDungeonMapDataBuffer2 then
        Event.Dispatch(EventType.OnMapEnterInfoNotify, DungeonData.tDungeonMapDataBuffer1, DungeonData.tDungeonMapDataBuffer2)
    end
    -- 右侧难度选项
    for nIndex, WidgetDifficulty in ipairs(self.WidgetDifficultyList) do
        self.tScriptDifficultyList[nIndex] = UIHelper.GetBindScript(WidgetDifficulty)
    end
    self.scriptDetail = UIHelper.GetBindScript(self.WidgetDifficultyDetail)
    UIHelper.SetSelected(self.TogRecommend, Storage.Dungeon.bRecommendOnly, false)

    if self.dwDefaultSelectMapID then
        local nDungeonType = GetDungeonTypeByMapID(self.dwDefaultSelectMapID)
        self:SetDungeonType(nDungeonType)
    end
end

function UIDungeonEntranceView:UpdateCollection(dwMapID, bCollect)
    Storage.Dungeon.tCollection[dwMapID] = bCollect
end

function UIDungeonEntranceView:BuildCollectionHeadData()
    local tDailyQuest = DungeonData.GetQuestIDByActivityID(DAILY_TEAM_FB)
	local tTeamQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_TEAM_FB)
	local tRaidQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_RAID_FB)

    local tHeadInfoList = {}
    local tHeadInfoMap = {}

    for _, szVersionName in pairs(self.tVersionOrderNames) do
        local tVersionInfo = self.tVesionDungeonMap[szVersionName]
        for _, tHeadInfo in ipairs(tVersionInfo.tHeadInfoList) do
            for _, tRecord in ipairs(tHeadInfo.tRecordList) do
                if IsDungeonCollected(tRecord.dwMapID) then
                    if not tHeadInfoMap[tRecord.szName] then
                        tHeadInfoMap[tRecord.szName] = {
                            dwFirstMapID = tRecord.dwMapID,
                            szName = tRecord.szName,
                            tRecordList = {tRecord},
                        }
                    else
                        table.insert(tHeadInfoMap[tRecord.szName].tRecordList, tRecord)
                    end
                end
            end
        end
    end

    local fnSortTDungeon = function(tLeft, tRight)
        return (tLeft.dwMapID or tLeft.dwFirstMapID) > (tRight.dwMapID or tRight.dwFirstMapID)
	end

    for _, tHeadInfo in pairs(tHeadInfoMap) do
        self:GetHeadInfoSortIndex(tHeadInfo, tTeamQuest, tRaidQuest, tDailyQuest)
        table.insert(tHeadInfoList, tHeadInfo)
        table.sort(tHeadInfo.tRecordList, fnSortTDungeon)
    end
    table.sort(tHeadInfoList, fnSortTDungeon)

    return tHeadInfoList, tHeadInfoMap
end

function UIDungeonEntranceView:GetHeadInfoSortIndex(tHeadInfo, tTeamQuest, tRaidQuest, tDailyQuest)
    tHeadInfo.nSortIndex = 999
    for _, tRecord in ipairs(tHeadInfo.tRecordList) do
        -- 推荐副本
        if tRecord.bIsRecommend then
            tHeadInfo.nSortIndex = tHeadInfo.nSortIndex or 4
        end
        -- 祈愿副本
        if DungeonData.tWishItemSource[tRecord.dwMapID] then
            if not tHeadInfo.nSortIndex or tHeadInfo.nSortIndex > 3 then
                tHeadInfo.nSortIndex = 3
            end
        end
        -- 五人周常
        if table.contain_value(tTeamQuest, tRecord.dwQuestID) then
            tHeadInfo.nSortIndex = 2
        end
        -- 十人周常
        if table.contain_value(tRaidQuest, tRecord.dwQuestID) then
            tHeadInfo.nSortIndex = 2
        end
        -- 大战日常
        if table.contain_value(tDailyQuest, tRecord.dwQuestID) then
            tHeadInfo.nSortIndex = 1
        end
    end
end

function UIDungeonEntranceView:InitDungeonData()
    self.tVesionDungeonMap, self.tVersionOrderNames = Table_GetVersionName2DungeonHeadList()

    DungeonData.tWishItemSource = {}
    local tSource = DungeonData.GetWishItemSourceList()
    for _, tData in ipairs(tSource) do
        local dwMapID = tData[1]
        DungeonData.tWishItemSource[dwMapID] = true
    end

    local tDailyQuest = DungeonData.GetQuestIDByActivityID(DAILY_TEAM_FB)
	local tTeamQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_TEAM_FB)
	local tRaidQuest  = DungeonData.GetQuestIDByActivityID(WEEKLY_RAID_FB)

    local tRecommendHeadMap = {}
    local tRecommendHeadList = {}

    local tCollectionHeadMap = {}
    local tCollectionHeadList = {}

    DungeonData.tbFlagMap = {} -- 0-无标记/1-日常标记/2-周常标记
    self.tRecordMap = {}
    for _, szVersionName in pairs(self.tVersionOrderNames) do
        local tVersionInfo = self.tVesionDungeonMap[szVersionName]
        for _, tHeadInfo in ipairs(tVersionInfo.tHeadInfoList) do
            local bRecommondHead = false
            tHeadInfo.nSortIndex = 999
            for _, tRecord in ipairs(tHeadInfo.tRecordList) do
                local bHasRecommond = false
                local bNeedHide = false
                DungeonData.tbFlagMap[tRecord.dwMapID] = 0
                -- 推荐副本
                if tRecord.bIsRecommend then
                    bHasRecommond = true
                    tHeadInfo.nSortIndex = tHeadInfo.nSortIndex or 4
                end
                -- 祈愿副本
                if DungeonData.tWishItemSource[tRecord.dwMapID] then
                    bHasRecommond = true
                    if not tHeadInfo.nSortIndex or tHeadInfo.nSortIndex > 3 then
                        tHeadInfo.nSortIndex = 3
                    end
                end
                -- 五人周常
                if table.contain_value(tTeamQuest, tRecord.dwQuestID) then
                    bHasRecommond = CommonDef.FB.RECOMMEND_WEEKLY_RAID
                    DungeonData.tbFlagMap[tRecord.dwMapID] = 2
                    tHeadInfo.nSortIndex = 2
                    bNeedHide = not CommonDef.FB.RECOMMEND_WEEKLY_RAID
                end
                -- 十人周常
                if table.contain_value(tRaidQuest, tRecord.dwQuestID) then
                    bHasRecommond = CommonDef.FB.RECOMMEND_WEEKLY_TEAM
                    DungeonData.tbFlagMap[tRecord.dwMapID] = 2
                    tHeadInfo.nSortIndex = 2
                    bNeedHide = not CommonDef.FB.RECOMMEND_WEEKLY_TEAM
                end
                -- 大战日常
                if table.contain_value(tDailyQuest, tRecord.dwQuestID) then
                    bHasRecommond = true
                    DungeonData.tbFlagMap[tRecord.dwMapID] = 1
                    tHeadInfo.nSortIndex = 1
                    self.dwDailyMapID = tRecord.dwMapID
                end

                bRecommondHead = bRecommondHead or (bHasRecommond and not bNeedHide)
                self.tRecordMap[tRecord.dwMapID] = tRecord
            end
            if bRecommondHead then
                table.insert(tRecommendHeadList, tHeadInfo)
                tRecommendHeadMap[tHeadInfo.szName] = tHeadInfo
            end
        end
    end

    tCollectionHeadList, tCollectionHeadMap = self:BuildCollectionHeadData()

    local function fSortHeadList(tHeadInfo1, tHeadInfo2)
        return tHeadInfo1.nSortIndex < tHeadInfo2.nSortIndex or (tHeadInfo1.nSortIndex == tHeadInfo2.nSortIndex and tHeadInfo1.dwFirstMapID > tHeadInfo2.dwFirstMapID)
    end
    table.sort(tRecommendHeadList, fSortHeadList)
    table.sort(tCollectionHeadList, fSortHeadList)

    -- 构造推荐栏
    self.tVesionDungeonMap["推荐"] = {
        tHeadInfoMap = tRecommendHeadMap,
        tHeadInfoList = tRecommendHeadList,
    }

    -- 收藏
    self.tVesionDungeonMap["收藏"] = {
        tHeadInfoMap = tCollectionHeadMap,
        tHeadInfoList = tCollectionHeadList,
    }

    table.insert(self.tVersionOrderNames, 1, "推荐")
    if #tCollectionHeadList > 0 then
        table.insert(self.tVersionOrderNames, 1, "收藏")
    end
end

function UIDungeonEntranceView:OnFrameBreathe()
    self:CheckAssistNewbie()
end

function UIDungeonEntranceView:Refresh()
    self.bRefresh = true
    self:InitDungeonData()
    self:UpdateDungeonInfo()
    self.bRefresh = false
end

function UIDungeonEntranceView:UpdateInfo()
    self:UpdateDungeonInfo()
    self:UpdateCurrency()
end

function UIDungeonEntranceView:UpdateDungeonInfo()
    self.bHasBigGroup = false
    self.bHasSmallGroup = false

    if not self.bRefresh then
        self.dwCurSelectMapID = nil
    end

    self.scriptDungeonList:ClearContainer()
    self.scriptDungeonList:OnInit(PREFAB_ID.WidgetDungeonTaskTitle, function (scriptContainer, szVersionName) -- 初始化标题
        local bCollection = szVersionName == "收藏"
        scriptContainer.szVersionName = szVersionName
        self.szCurVersionName = szVersionName
        UIHelper.SetVisible(scriptContainer.LayoutLike, bCollection)
        UIHelper.SetString(scriptContainer.LabelFolded, szVersionName)
        UIHelper.SetString(scriptContainer.LabelStretched, szVersionName)
    end)

    local nDefaultSelectedIndex, nDefaultLootIndex = 1, 1
    local bHasFirstMatchDefault = false
    local nTitleCount = 1
    for nVersionIndex, szVersionName in ipairs(self.tVersionOrderNames) do
        local tVersionInfo = self.tVesionDungeonMap[szVersionName]
        local tDungeonItemList = {}        
        for _, tHeadInfo in ipairs(tVersionInfo.tHeadInfoList) do
            local bMatchRecommend = not Storage.Dungeon.bRecommendOnly or szVersionName == "推荐"
            local bCollection = szVersionName == "收藏"
            local bMatchEnterMap = self:IsHeadMatchEnterMapID(tHeadInfo)
            local bIsMatchSearchKey = self:IsMatchSearchKey(tHeadInfo.szName)
            local bIsMatchTitle = not self.szTargetTitle or self.szTargetTitle == szVersionName
            local bMatchDungeonType = self:IsHeadMatchDungeonType(tHeadInfo)
            if (bMatchRecommend or bCollection) and bMatchEnterMap and bIsMatchSearchKey and bIsMatchTitle and bMatchDungeonType then --策划要求仅显示推荐的时候也强制限制收藏，具体可以询问PP
                if self.nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP then self.bHasBigGroup = true end
                if self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP then self.bHasSmallGroup = true end
                table.insert(tDungeonItemList, {
                    nPrefabID = PREFAB_ID.WidgetDungeonTaskToggle,
                    tArgs = {
                        tHeadInfo = tHeadInfo,
                        fCallBack = function (tNewHeadInfo)
                            self:UpdateDetailInfo(tNewHeadInfo, true, bCollection)
                        end
                    }
                })

                -- 收藏刷新的重定向，由于可能有异常，为了不影响默认重定向功能所以这里将收藏刷新的重定向优先级拉到最低
                if not bHasFirstMatchDefault and self.bRefresh and self.dwCurSelectMapID and self:IsHeadContainMapID(tHeadInfo, self.dwCurSelectMapID) and self.szCurVersionName == szVersionName then
                    nDefaultSelectedIndex, nDefaultLootIndex = nTitleCount, #tDungeonItemList
                end

                if not bHasFirstMatchDefault and self.dwDefaultSelectMapID and self:IsHeadContainMapID(tHeadInfo, self.dwDefaultSelectMapID) then
                    bHasFirstMatchDefault = true
                    nDefaultSelectedIndex, nDefaultLootIndex = nTitleCount, #tDungeonItemList
                end
            end
        end
        if #tDungeonItemList > 0 then
            nTitleCount = nTitleCount + 1
            self.scriptDungeonList:AddContainer(szVersionName, tDungeonItemList, function (bSelected, scriptContainer) -- 标题选中事件

            end,function () -- 标题点击事件

            end, Platform.IsIos())
        end
    end

    self.scriptDungeonList:UpdateInfo()

    if #self.scriptDungeonList.tContainerList > 0 then
        Timer.AddFrame(self, 2, function ()
                local scriptContainer = self.scriptDungeonList.tContainerList[nDefaultSelectedIndex].scriptContainer
                scriptContainer:SetSelected(true)

                local scriptCell = scriptContainer.tItemScripts[nDefaultLootIndex]
                UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                scriptCell.fCallBack(scriptCell.tHeadInfo)

                self:UpdateEmptyHeadState()
            end)
    else
        self:UpdateEmptyHeadState()
        self:RefreshButtons()
    end
    UIHelper.CascadeDoLayoutDoWidget(self.scriptDungeonList._rootNode, true, true)

    -- 没有任何符合条件的秘境或小队模式没有符合条件的秘境，自动跳转到团队模式
    if not self.bAutoJumpOnce and self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP and not self.bHasSmallGroup then
        self.bAutoJumpOnce = true -- 外部跳转导致的筛选只跳一次
        Timer.AddFrame(self, 1, function ()
            UIHelper.SetSelected(self.TogTabTeam, false, false)
            UIHelper.SetSelected(self.TogTabRaid, true, false)
            self.nDungeonType = ENUM_DUNGEON_TYPE.BIG_GROUP
            self:UpdateDungeonInfo()
        end)
    end
end

function UIDungeonEntranceView:UpdateCurrency()
    UIHelper.RemoveAllChildren(self.LayoutMoneyShell)
    local scriptContribution = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutMoneyShell, ShopData.CurrencyCode.Contribution)
    scriptContribution:SetCurrencyType(CurrencyType.Contribution)
    scriptContribution:SetLableCount(g_pClientPlayer.nContribution)
    local scriptJustice = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutMoneyShell, ShopData.CurrencyCode.Justice)
    scriptJustice:SetCurrencyType(CurrencyType.Justice)
    scriptJustice:SetLableCount(g_pClientPlayer.nJustice)

    self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutMoneyShell)
    self.VigorScript:SetCurrencyType(CurrencyType.Vigor)
    local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
    local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
    self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorRightTop, true, true)
end

function UIDungeonEntranceView:AutoSkipEmptyPanel()
    if self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP and not self.bHasSmallGroup then
        Timer.AddFrame(self, 1, function ()
            UIHelper.SetSelected(self.TogTabRaid, true, false)
            UIHelper.SetSelected(self.TogTabTeam, false, false)
            self.nDungeonType = ENUM_DUNGEON_TYPE.BIG_GROUP
            self:UpdateDungeonInfo()
        end)
    elseif self.nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP and not self.bHasBigGroup then
        Timer.AddFrame(self, 1, function ()
            UIHelper.SetSelected(self.TogTabTeam, true, false)
            UIHelper.SetSelected(self.TogTabRaid, false, false)
            self.nDungeonType = ENUM_DUNGEON_TYPE.SMALL_GROUP
            self:UpdateDungeonInfo()
        end)
    end
end

function UIDungeonEntranceView:SetDungeonType(nDungeonType)
    if self.nDungeonType ~= nDungeonType then
        if nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP then
            UIHelper.SetSelected(self.TogTabRaid, true, false)
            UIHelper.SetSelected(self.TogTabTeam, false, false)
            self.nDungeonType = ENUM_DUNGEON_TYPE.BIG_GROUP
        else
            UIHelper.SetSelected(self.TogTabTeam, true, false)
            UIHelper.SetSelected(self.TogTabRaid, false, false)
            self.nDungeonType = ENUM_DUNGEON_TYPE.SMALL_GROUP
        end
    end
end

local function IsShowDungeon(tData, bCollection)
    if bCollection then --收藏优先级最高，仅显示推荐的时候也显示，PP的需求
        return Storage.Dungeon.tCollection[tData.dwMapID]
    end
    return ( not Storage.Dungeon.bRecommendOnly or tData.bIsRecommend or DungeonData.tbFlagMap[tData.dwMapID] ~= 0)
end

function UIDungeonEntranceView:UpdateDetailInfo(tHeadInfo, bChooseDailyOrWeekly, bCollection)
    local player = GetClientPlayer()
	if not player then return end

    -- 描述
    local szTitle = tHeadInfo.szName
    UIHelper.SetString(self.LabelDetailTitle, szTitle)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelDetailTitle))

    if self.dwDefaultSelectMapID then
        local tDefaultRecord = Table_GetDungeonInfo(self.dwDefaultSelectMapID)
        if tDefaultRecord then
            local szOtherName = UIHelper.GBKToUTF8(tDefaultRecord.szOtherName)
            local szLayer3Name = UIHelper.GBKToUTF8(tDefaultRecord.szLayer3Name)
            if szOtherName == szTitle then
                self.dwCurSelectMapID = self.dwDefaultSelectMapID
                self.szLastLayer3Name = szLayer3Name
                self.dwDefaultSelectMapID = nil
            end
        end
    end
    if self.dwCurSelectMapID then
        local tSelectRecord = Table_GetDungeonInfo(self.dwCurSelectMapID)
        local szOtherName = UIHelper.GBKToUTF8(tSelectRecord.szOtherName)
        if tSelectRecord and szOtherName ~= szTitle then
            self.dwCurSelectMapID = nil
        end
    end

    -- 各难度副本
    for k, v in ipairs(self.tScriptDifficultyList) do
        UIHelper.SetVisible(v._rootNode, false)
    end

    local nLastSelectValue = 0
    local bScrollViewVisable = false
    local tDataList = tHeadInfo.tRecordList

    if tDataList then
        local tDifficultyList = {}
        local nScriptCount = 0
        local dwNeedSelectMapID = nil
        local nMaxWeight = 0
        for nIdx, tData in ipairs(tDataList) do
            if not tData.bHideDetail and IsShowDungeon(tData, bCollection) then
                if not dwNeedSelectMapID then dwNeedSelectMapID = tData.dwMapID end

                local nWeight = 0
                nScriptCount = nScriptCount + 1
                if not self.dwCurSelectMapID and nScriptCount == 1 then nWeight = nWeight + 1 end
                local szLayer3Name = tData.szLayer3Name
                if bChooseDailyOrWeekly then
                    if self.szLastLayer3Name and self.szLastLayer3Name == szLayer3Name then nWeight = nWeight + 1000 end
                    if self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP then
                        local nStart,_ = string.find(szLayer3Name, "英雄")
                        if nStart ~= nil then nWeight = nWeight + 100 end
                    else
                        local nStart,_ = string.find(szLayer3Name, "10人普通")
                        if nStart ~= nil then nWeight = nWeight + 100 end
                    end
                end
                if nMaxWeight < nWeight then
                    nMaxWeight = nWeight
                    dwNeedSelectMapID = tData.dwMapID
                end
                table.insert(tDifficultyList, tData)
            end

        end

        self.dwCurSelectMapID = dwNeedSelectMapID or self.dwCurSelectMapID
        for nIdx, tData in ipairs(tDifficultyList) do
            local script = self.tScriptDifficultyList[nIdx]
            script:OnEnter(tData, self.tDungeonMapInfo, self.tDungeonCopyID)
            script:SetSelectedCallBack(function (bManualSelected)
                if self.bChooseDailyOrWeekly and bManualSelected then
                    self.szLastLayer3Name =  tData.szLayer3Name
                end
                self.dwCurSelectMapID = tData.dwMapID
                local tSwitchMapInfo = Table_GetDungeonSwitchMapInfo(tData.dwMapID)
                local bMinLevelLimit = tSwitchMapInfo and tSwitchMapInfo.nMinLevelLimit > 0 and tSwitchMapInfo.nMinLevelLimit > player.nLevel
                if bMinLevelLimit then
                    UIHelper.SetButtonState(self.BtnNormalMode,BTN_STATE.Disable, g_tStrings.Dungeon.STR_MIN_LEVEL_LIMIT)
                else
                    UIHelper.SetButtonState(self.BtnNormalMode, BTN_STATE.Normal)
                end

                self:UpdateDropItemInfo() -- 耗时15ms
                self:RefreshButtons()   -- 耗时45ms TODO:现在看着速度还行，有时间优化一下看看
                UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
                self.scriptDetail:OnEnter(tData, self.tDungeonMapInfo, self.tDungeonCopyID)
            end)
            local bNeedSelect = self.dwCurSelectMapID == tData.dwMapID
            if bNeedSelect then script.fOnSelectedCallBack(false) end
            UIHelper.SetSelected(script.ToggleSelect, bNeedSelect, false)
            UIHelper.SetVisible(script._rootNode, true)
            bScrollViewVisable = true
        end
    end

    local szDetailText = ""
    local szPath = GetMapParams(self.dwCurSelectMapID or tHeadInfo.dwFirstMapID)
    if szPath then
        szPath = szPath .. "minimap_mb\\information.tab"
        local tInfo = KG_Table.Load(szPath, {{f="S", t="szRecommend"}, {f="S", t="szDesc"}}, TABLE_FILE_OPEN_MODE.NORMAL)
        if tInfo then
			local tRow = tInfo:GetRow(1)
			if tRow then
				szDetailText = tRow.szDesc
			end
		end
        szDetailText = szDetailText or ""
    end
    szDetailText = UIHelper.GBKToUTF8(szDetailText)
    szDetailText = string.pure_text(szDetailText)
    szDetailText = string.gsub(szDetailText, " ", "")
    szDetailText = string.gsub(szDetailText, "　　", "")    -- 策划配置里的奇葩字符，不让改表，人工补偿一下
    szDetailText = "\t\t"..szDetailText
    UIHelper.SetString(self.LabelDetail, szDetailText)

    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail, 0)
    if self.dwCurSelectMapID then ApplyDungeonRoleProgress(self.dwCurSelectMapID, player.dwID) end

    self:UpdateEmptyDiffcultState()
    UIHelper.SetVisible(self.WidgetEmptyDifficulty, not bScrollViewVisable)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
    UIHelper.LayoutDoLayout(self.LayoutDifficultyHead)
end

function UIDungeonEntranceView:UpdateTogLikeState()
    local bCollection = IsDungeonCollection(self.dwCurSelectMapID)
    UIHelper.SetSelected(self.TogLike, bCollection, false)
end

function UIDungeonEntranceView:UpdateEmptyHeadState()
    local bIsEmpty = not self.dwCurSelectMapID
    UIHelper.SetVisible(self.scriptDetail._rootNode, not bIsEmpty)
    UIHelper.SetVisible(self.scriptDetail.BtnDetail, not bIsEmpty)
    UIHelper.SetVisible(self.scriptDungeonList._rootNode, not bIsEmpty)

    UIHelper.SetVisible(self.WidgetEmpty, bIsEmpty)
    UIHelper.SetVisible(self.WidgetAnchorRight, not bIsEmpty)
    UIHelper.SetVisible(self.WidgetContent, not bIsEmpty)
    UIHelper.SetVisible(self.ImgDecoBgSmall, not bIsEmpty and self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP)
    UIHelper.SetVisible(self.ImgDecoBgBig, not bIsEmpty and self.nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP)
    UIHelper.SetVisible(self.ScrollViewReward, not bIsEmpty)
    UIHelper.SetVisible(self.BtnSendToChat, not bIsEmpty)
    UIHelper.SetVisible(self.BtnTrace, not bIsEmpty)
    UIHelper.SetVisible(self.BtnAchievements, not bIsEmpty)
end

function UIDungeonEntranceView:UpdateEmptyDiffcultState()
    local bIsEmpty = not self.dwCurSelectMapID
    UIHelper.SetVisible(self.scriptDetail._rootNode, not bIsEmpty)
    UIHelper.SetVisible(self.scriptDetail.BtnDetail, not bIsEmpty)

    UIHelper.SetVisible(self.WidgetAnchorButton, not bIsEmpty)
    UIHelper.SetVisible(self.ScrollViewReward, not bIsEmpty)
    UIHelper.SetVisible(self.BtnSendToChat, not bIsEmpty)
    UIHelper.SetVisible(self.BtnTrace, not bIsEmpty)
    UIHelper.SetVisible(self.BtnAchievements, not bIsEmpty)
end

function UIDungeonEntranceView:UpdateDropItemInfo()
    if not self.dwCurSelectMapID then
        return
    end

    local tRecord = self.tRecordMap[self.dwCurSelectMapID]
    tRecord = tRecord or Table_GetDungeonInfo(self.dwCurSelectMapID)
    if not tRecord then
        return
    end
    UIHelper.RemoveAllChildren(self.LayoutItemListOrdinary)
    if #tRecord.szReward > 0 then
        local tReward = SplitString(tRecord.szReward, ";")
        for _, v in pairs(tReward) do
            local tInfo = SplitString(v, "_")
            local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
            nCount = nCount or 0
            local tItemInfo = ItemData.GetItemInfo(dwType, dwIndex)
            local bIsBook = tItemInfo.nGenre == ITEM_GENRE.BOOK
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItemListOrdinary)
            if scriptItem then
                scriptItem:OnInitWithTabID(dwType, dwIndex)
                if not bIsBook and nCount > 1 then scriptItem:SetLabelCount(nCount) end
                scriptItem:SetClickCallback(function (nTabType, nTabID)
                    local _, scriptItemTips = TipsHelper.ShowItemTips(scriptItem._rootNode, nTabType, nTabID, false)
                    if bIsBook then
                        scriptItemTips:SetBookID(nCount)
                        scriptItemTips:OnInitWithTabID(nTabType, nTabID)
                        scriptItemTips:SetBtnState({})
                    end
                end)
                local bShowWishTag = DungeonData.IsWishItemByItemInfo(dwType, dwIndex)
                scriptItem:ShowNowIcon(bShowWishTag)
                scriptItem:SetNowDesc("祈愿")
                scriptItem:SetClearSeletedOnCloseAllHoverTips(true)
                UIHelper.SetTouchDownHideTips(scriptItem.ToggleSelect, false)
                UIHelper.SetSwallowTouches(scriptItem.ToggleSelect)
            end
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutItemListOrdinary, true, true)

    UIHelper.RemoveAllChildren(self.LayoutItemListExtra)
    local bShowExtraAward = #tRecord.szExtReward > 0 and DungeonData.tbFlagMap[tRecord.dwMapID] ~= 0
    if bShowExtraAward then
        if DungeonData.tbFlagMap[tRecord.dwMapID] == 1 then UIHelper.SetString(self.LabelAwardType, "日常额外奖励") end
        if DungeonData.tbFlagMap[tRecord.dwMapID] == 2 then UIHelper.SetString(self.LabelAwardType, "周常额外奖励") end
        local tReward = SplitString(tRecord.szExtReward, ";")
        for _, v in pairs(tReward) do
            local tInfo = SplitString(v, "_")
            local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
            nCount = nCount or 0
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItemListExtra)
            if tInfo[1] ~= "COIN" then
                scriptItem:OnInitWithTabID(dwType, dwIndex)
                local tItemInfo = ItemData.GetItemInfo(dwType, dwIndex)
                local bIsBook = tItemInfo.nGenre == ITEM_GENRE.BOOK
                if not bIsBook and nCount > 1 then scriptItem:SetLabelCount(nCount) end
                scriptItem:SetClickCallback(function (nTabType, nTabID)
                    local _, scriptItemTips = TipsHelper.ShowItemTips(scriptItem._rootNode, nTabType, nTabID, false)
                    if bIsBook then
                        scriptItemTips:SetBookID(nCount)
                        scriptItemTips:OnInitWithTabID(nTabType, nTabID)
                        scriptItemTips:SetBtnState({})
                    end
                end)
                local bShowWishTag = DungeonData.IsWishItemByItemInfo(dwType, dwIndex)
                scriptItem:ShowNowIcon(bShowWishTag)
                scriptItem:SetNowDesc("祈愿")
            else
                local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
                local szName = CurrencyNameToType[tbLine.szName]
                scriptItem:OnInitCurrency(szName, nCount * 10000)
                scriptItem:SetLabelCount(nCount)
                scriptItem:SetClickCallback(function (nTabType, nTabID)
                    TipsHelper.ShowItemTips(scriptItem._rootNode, "CurrencyType", szName, false)
                end)
            end
            scriptItem:SetClearSeletedOnCloseAllHoverTips(true)
            UIHelper.SetTouchDownHideTips(scriptItem.ToggleSelect, false)
            UIHelper.SetSwallowTouches(scriptItem.ToggleSelect)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutItemListExtra, true, true)
    UIHelper.SetVisible(self.LayoutExtra, bShowExtraAward)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetReward, true, true)

    UIHelper.SetHeight(self.WidgetRewardContent, UIHelper.GetHeight(self.LayoutContentReward))
    UIHelper.SetPositionY(self.LayoutContentReward, 0, self.WidgetRewardContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
end

function UIDungeonEntranceView:UpdateDungeonEnterMapInfo(tEnterMapInfo, tLeftRefTime)
    self.tDungeonMapInfo = {}
    for dwMapID, v in pairs(tEnterMapInfo) do
        local _, nMapType, nMaxPlayerCount, nLimitedTimes = GetMapParams(dwMapID)
        local nType, tInfo = nil, nil
        if nMapType and nMapType == MAP_TYPE.DUNGEON then
            local nRefreshCycle = GetMapRefreshInfo(dwMapID)
            local nCanEnterTimes = nLimitedTimes - v
            local nRefreshTime = tLeftRefTime[dwMapID] or 0
            if nRefreshCycle == 0 and nMaxPlayerCount <= 5 then
                self.tDungeonMapInfo[dwMapID] =
                {
                    nEnterTimes = nCanEnterTimes,
                    nLimitedTimes = nLimitedTimes,
                    nRefreshTime = nRefreshTime
                }
            elseif nRefreshCycle ~= 0 and nMaxPlayerCount <= 5 then
                --local nRefreshTime = tLeftRefTime[dwMapID] or 0
                self.tDungeonMapInfo[dwMapID] =
                {
                    nEnterTimes = nCanEnterTimes,
                    nLimitedTimes = nLimitedTimes,
                    nRefreshCycle = nRefreshCycle,
                    nRefreshTime = nRefreshTime
                }
            elseif nRefreshCycle ~= 0 and nMaxPlayerCount > 5 then
                --local nRefreshTime = tLeftRefTime[dwMapID] or 0
                self.tDungeonMapInfo[dwMapID] =
                {
                    nRefreshCycle = nRefreshCycle,
                    nRefreshTime = nRefreshTime
                }
            end
        end
    end
    if self.scriptDetail and self.scriptDetail.tRecord then
        self.scriptDetail:OnEnter(self.scriptDetail.tRecord, self.tDungeonMapInfo, self.tDungeonCopyID)
    end
end

function UIDungeonEntranceView:OnMapEnterInfoNotify(tData, tData1)
    DungeonData.tDungeonMapDataBuffer1 = clone(tData)
    DungeonData.tDungeonMapDataBuffer2 = clone(tData1)
    self:UpdateDungeonEnterMapInfo(tData, tData1)
end

function UIDungeonEntranceView:GetMapCopyProgress()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tData = hPlayer.GetMapCopyProgress()
	self:OnApplyPlayerSavedCopysRespond(tData)
end

function UIDungeonEntranceView:OnApplyPlayerSavedCopysRespond(tData)
    if not tData then
        self.tDungeonCopyID = {}
        tData = {}
    end
    for dwMapID, v in pairs(tData) do
        self.tDungeonCopyID[dwMapID] = v[1]
    end
end

function UIDungeonEntranceView:RefreshButtons()
    local tSwitchMapInfo = Table_GetDungeonSwitchMapInfo(self.dwCurSelectMapID or 0)
    local _,_,_,_,_,_,_,bIsDungeonRoleProgressMap = GetMapParams(self.dwCurSelectMapID or 0)
    local dwEntranceMapID = Table_GetCopyMapTrackPoints(self.dwCurSelectMapID or 0)

    if TeamData.IsPlayerInTeam() then
        UIHelper.SetSpriteFrame(self.ImgNormalMode, ImgButtonPath["Yellow"])
    else
        UIHelper.SetSpriteFrame(self.ImgNormalMode, ImgButtonPath["Blue"])
    end

    UIHelper.SetVisible(self.BtnTrace, self.dwCurSelectMapID ~= nil and dwEntranceMapID ~= nil)
    UIHelper.SetVisible(self.BtnSendToChat, self.dwCurSelectMapID ~= nil)
    UIHelper.SetVisible(self.BtnAchievements, self.dwCurSelectMapID ~= nil and tSwitchMapInfo ~= nil)
    UIHelper.SetVisible(self.BtnNormalMode, self.dwCurSelectMapID ~= nil and tSwitchMapInfo ~= nil)
    UIHelper.SetVisible(self.BtnFindGroup, self.dwCurSelectMapID ~= nil and (not TeamData.IsPlayerInTeam() or TeamData.IsTeamLeader()))
    UIHelper.SetVisible(self.WidgetTeamProgress, self.dwCurSelectMapID ~= nil and TeamData.IsPlayerInTeam() and bIsDungeonRoleProgressMap)
    UIHelper.SetVisible(self.BtnAssist, self.dwCurSelectMapID ~= nil and not TeamData.IsPlayerInTeam() and AssistNewbieBase.CanShowAssistButton(self.dwCurSelectMapID))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.WidgetTeamProgress))

    --资源下载Widget
    local nStoryMode = 0
    if self.dwCurSelectMapID then
        local tDungeonInfo = Table_GetDungeonInfo(self.dwCurSelectMapID)
        nStoryMode = tDungeonInfo and tDungeonInfo.nStoryMode
        UIHelper.SetVisible(self.BtnSingleMode, nStoryMode > 0)

        local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        local nPackID = PakDownloadMgr.GetMapResPackID(self.dwCurSelectMapID)
        scriptDownload:OnInitWithPackID(nPackID)
        UIHelper.SetVisible(self.WidgetDownload, true)
    else
        UIHelper.SetVisible(self.WidgetDownload, false)
        UIHelper.SetVisible(self.BtnSingleMode, false)
    end
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.WidgetDownload))

    local scene = GetClientPlayer().GetScene()
    if not scene then return end

    local tDungeonInfo = Table_GetDungeonInfo(scene.dwMapID)
    local tCurDungeonInfo = Table_GetDungeonInfo(self.dwCurSelectMapID or 0)
    local bHasRecruit = Table_GetTeamInfoByMapID(self.dwCurSelectMapID or 0) ~= nil
    local bDisable = false
    local bBtnFindGroupDisable = false
    if tDungeonInfo then
        UIHelper.SetButtonState(self.BtnNormalMode, BTN_STATE.Disable, "秘境中不能进行此操作")
        UIHelper.SetButtonState(self.BtnSingleMode, BTN_STATE.Disable, "秘境中不能进行此操作")
        UIHelper.SetButtonState(self.BtnFindGroup, BTN_STATE.Disable, "秘境中不能进行此操作")
        bDisable = true
        bBtnFindGroupDisable = true
    end

    if not bHasRecruit then
        UIHelper.SetButtonState(self.BtnFindGroup, BTN_STATE.Disable, "当前秘境暂不支持招募")
        bBtnFindGroupDisable = true
    end

    if not bDisable and tCurDungeonInfo then
        if tCurDungeonInfo.nStoryMode == 2 then
            UIHelper.SetButtonState(self.BtnSingleMode, BTN_STATE.Disable, g_tStrings.Dungeon.STR_FB_STORY_MODE_DIABLE)
            bDisable = true
        elseif tCurDungeonInfo.nStoryMode == 1 and TeamData.IsPlayerInTeam() then
            UIHelper.SetButtonState(self.BtnSingleMode, BTN_STATE.Disable, g_tStrings.Dungeon.STR_FBLIST_NO_IN_PARTY)
            bDisable = true
        end
    end

    if not bDisable then
        UIHelper.SetButtonState(self.BtnNormalMode, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnSingleMode, BTN_STATE.Normal)
    end

    if not bBtnFindGroupDisable then
        UIHelper.SetButtonState(self.BtnFindGroup, BTN_STATE.Normal)
    end

    local LayoutContent = UIHelper.GetParent(self.BtnAssist)
    UIHelper.LayoutDoLayout(LayoutContent)

    if self.dwCurSelectMapID then
        local nTotalCount, nFinishCount = self:FindAchievementCount(self.dwCurSelectMapID)
        UIHelper.SetString(self.LabelAchievements, string.format("成就(%d/%d)", nFinishCount, nTotalCount))
        UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelAchievements))

        self:UpdateTogLikeState()
    end
end

function UIDungeonEntranceView:StartGuide()
    if not self.dwCurSelectMapID then return end

    local tDungeonInfo = Table_GetDungeonInfo(self.dwCurSelectMapID)
    if not tDungeonInfo then return end

    local szMapName = UIHelper.GBKToUTF8(tDungeonInfo.szOtherName)

    local dwCurTrackingMapID = Table_GetCanTrackingMapIDWithName(szMapName) or 0

    local fnDoGuide = function ()
        local dwEntranceMapID, x, y, z = Table_GetCopyMapTrackPoints(dwCurTrackingMapID)
        if not dwEntranceMapID then return end

        local tbTagIconTab = MapHelper.GetMiddleMapTagIconTab(7)
        local szFrame = tbTagIconTab and tbTagIconTab.szFrame or ""
        MapMgr.SetTracePoint(szMapName, dwEntranceMapID, {x, y, z}, nil, szFrame)

        MapMgr.TryTransfer(dwCurTrackingMapID, nil, true)
    end
    --地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(dwCurTrackingMapID, fnDoGuide, "秘境地图资源文件下载完成，是否前往[" .. szMapName .. "入口]？") then
        return
    end

    fnDoGuide()
end

function UIDungeonEntranceView:OnClickEnterDungeonButton()
    if RoomData.IsApplyGlobalDungeon(self.dwCurSelectMapID) then
        MapMgr.BeforeTeleport()
        self.scriptTipMoreOper:ClearAllBtns()
        self.scriptTipMoreOper:OnEnter({
            {
                szName = "前往本服",
                OnClick = function ()
                    self:OnTryEnterDungeonButtonCheckReset(false)
                end
            },
            {
                szName = "前往跨服",
                OnClick = function ()
                    RoomData.ApplyGlobalDungeon(self.dwCurSelectMapID)
                    UIMgr.Close(VIEW_ID.PanelDungeonEntrance)
                    UIMgr.Close(VIEW_ID.PanelRoadCollection)
                    UIMgr.Close(VIEW_ID.PanelSystemMenu)
                end
            }
        })
        UIHelper.SetVisible(self.WidgetTipMoreOperShell, true)
    else
        self:OnTryEnterDungeonButtonCheckReset(false)
        UIHelper.SetVisible(self.WidgetTipMoreOperShell, false)
    end
end

function UIDungeonEntranceView:OnTryEnterDungeonButtonCheckReset(bStoryMode)
    local dwMapID = self.dwCurSelectMapID
    local bInParty = g_pClientPlayer.IsInParty()
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    local bResetAuth = (bInParty and DungeonData.IsLeader()) or not bInParty
    local bCanReset = self:CanResetDungeon(dwMapID, UIHelper.GBKToUTF8(tDungeonInfo.szLayer3Name)) and bResetAuth

    if bCanReset and bResetAuth then
        DungeonData.RequestResetMap(dwMapID, function ()
            self:OnTryEnterDungeonButtonCheckTeam(bStoryMode)
        end)
    else
        self:OnTryEnterDungeonButtonCheckTeam(bStoryMode)
    end
end

function UIDungeonEntranceView:OnTryEnterDungeonButtonCheckTeam(bStoryMode)
    local bInParty = g_pClientPlayer.IsInParty()
    if not bInParty and not bStoryMode then
        local scriptConfirm = UIHelper.ShowConfirm("该模式难度较大，建议侠士组队前往，你准备好了吗？", function ()
            local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwCurSelectMapID)
            if tRecruitInfo then
                UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
            end
        end,function ()

        end)
        if scriptConfirm then
            scriptConfirm:SetButtonContent("Confirm", "快捷组队")
            scriptConfirm:SetButtonContent("Other", "确定前往")
            scriptConfirm:SetButtonContent("Cancel", "取消")
            scriptConfirm:SetButtonColor("Confirm", "Yellow")
            scriptConfirm:SetButtonColor("Other", "Yellow")
            scriptConfirm:SetButtonColor("Cancel", "Blue")
            scriptConfirm:ShowOtherButton()
            scriptConfirm:SetOtherButtonClickedCallback(function()
                DungeonData.TryEnterDungeon(self.dwCurSelectMapID, bStoryMode)
            end)
        end
    else
        DungeonData.TryEnterDungeon(self.dwCurSelectMapID, bStoryMode)
    end
end

function UIDungeonEntranceView:CanResetDungeon(dwMapID, szName)
	local bRaid = IsRaidFB(szName)
	local _, _, _, _, _, nCostVigor, bCanReset = GetMapParams(dwMapID)
    local bIsItemReset, nItemType, nItemID, nItemCount = CanResetMap(dwMapID)
    local player = GetClientPlayer()
	if not bCanReset then return false end
    if not bIsItemReset and not player.IsVigorAndStaminaEnough(nCostVigor) then return false end

	if not bRaid then
		if self.tDungeonCopyID[dwMapID] then
			return true
		end
	end
end

function UIDungeonEntranceView:FindAchievementCount(dwMapID)
    local nTotalCount, nFinishCount = 0,0

    local fnCustomFilterDataCallback = function()
        AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(dwMapID)
    end

    AchievementData.TraverseTree(
        ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT,
        function(dwGeneral, nAllCount, nAllFinish)

        end,
        function(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)

        end,
        function(dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish)
            if dwGeneral == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
                nTotalCount = nTotalCount + nSubCategoryCount
                nFinishCount = nFinishCount + nSubCategoryFinish
            end
        end,
        UI_GetClientPlayerID(),
        fnCustomFilterDataCallback
    )

    return nTotalCount, nFinishCount
end

function UIDungeonEntranceView:LinkToAchievements()
    local fnCustomFilterDataCallback = function()
        AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(self.dwCurSelectMapID)
    end

    if UIMgr.IsViewOpened(VIEW_ID.PanelAchievementList, true) then
        UIMgr.CloseWithCallBack(VIEW_ID.PanelAchievementList, function ()
            UIMgr.Open(VIEW_ID.PanelAchievementList, g_pClientPlayer.dwID, fnCustomFilterDataCallback)
        end)
    else
        UIMgr.Open(VIEW_ID.PanelAchievementList, g_pClientPlayer.dwID, fnCustomFilterDataCallback)
    end
end

function UIDungeonEntranceView:IsMatchDungeonType(dwClassID)
    if self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP then
        if dwClassID == 1 or dwClassID == 2 then
            return true
        end
    elseif self.nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP then
        if dwClassID == 3 then
            return true
        end
    end
    return false
end

function UIDungeonEntranceView:IsHeadMatchDungeonType(tHeadInfo)
    if #tHeadInfo.tRecordList == 0 then return false end

    local dwClassID = tHeadInfo.tRecordList[1].dwClassID
    if self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP then
        if dwClassID == 1 or dwClassID == 2 then
            return true
        end
    elseif self.nDungeonType == ENUM_DUNGEON_TYPE.BIG_GROUP then
        if dwClassID == 3 then
            return true
        end
    end
    return false
end

function UIDungeonEntranceView:IsMatchSearchKey(szMapName)
    return MatchString(szMapName, self.szSearchKey)
end


function UIDungeonEntranceView:IsHeadMatchEnterMapID(tHeadInfo)
    if #tHeadInfo.tRecordList == 0 or not self.nTargetEnterMapID then
        return true
    end

    for _, tRecord in ipairs(tHeadInfo.tRecordList) do
        if self.nTargetEnterMapID == tRecord.nEnterMapID then
            return true
        end
    end

    return false
end

function UIDungeonEntranceView:IsHeadContainMapID(tHeadInfo, dwMapID)
    for _, tRecord in ipairs(tHeadInfo.tRecordList) do
        if dwMapID == tRecord.dwMapID then
            return true
        end
    end

    return false
end

function UIDungeonEntranceView:SetEnterMapID(nTargetEnterMapID)
    self.nTargetEnterMapID = nTargetEnterMapID
    UIHelper.SetVisible(self.TogRecommend, self.nTargetEnterMapID == nil or self.nTargetEnterMapID == 0)
    self:UpdateDungeonInfo()
end

function UIDungeonEntranceView:SetTargetTitle(szTargetTitle)
    self.szTargetTitle = szTargetTitle

    self:UpdateDungeonInfo()
end

function UIDungeonEntranceView:LogCostTime(szTag, bStart, bTotal)
    local nTimeNow = os.time() * 1000 + math.floor(os.clock() * 1000)
    if bStart then
        self.nStartLogTime = nTimeNow
        self.nLastLogTime = nTimeNow
        LOG(string.format("[%s] Start log cost time ...", szTag))
        return
    end

    local nCostTime = nTimeNow - self.nLastLogTime
    if bTotal then nCostTime = nTimeNow - self.nStartLogTime end
    self.nLastLogTime = nTimeNow
    LOG(string.format("[%s] Cost time=%d ms", szTag, nCostTime))
end

----------------------------界面定位/筛选--------------------------------
function UIDungeonEntranceView:CheckAssistNewbie()
    local bNeedCheck = self.dwCurSelectMapID ~= nil and not TeamData.IsPlayerInTeam() and AssistNewbieBase.CanShowAssistButton(self.dwCurSelectMapID)
    if not bNeedCheck then return end

    local bSatisfy, szErrMsg = AssistNewbieBase.CheckReleaseCondition()
    if bSatisfy then
        UIHelper.SetButtonState(self.BtnAssist, BTN_STATE.Normal)
        UIHelper.SetString(self.LabelAssist, "发布援助")
    else
        UIHelper.SetButtonState(self.BtnAssist, BTN_STATE.Disable, szErrMsg)
        local nCDLeft = g_pClientPlayer.GetCDLeft(AssistNewbieBase.RELEASE_CD_ID)
        nCDLeft = nCDLeft / GLOBAL.GAME_FPS
        if nCDLeft > 0 then
            UIHelper.SetString(self.LabelAssist, string.format("发布援助(%s)", UIHelper.GetDeltaTimeShortText(nCDLeft)))
        end
    end
end

function UIDungeonEntranceView:SelectCurDungeonMapByMapID(dwMapID)
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    if not tDungeonInfo then
        return
    end

    self.dwDefaultSelectMapID = dwMapID
    local bIsMatch = self:IsMatchDungeonType(tDungeonInfo.dwClassID)
    if not bIsMatch then
        local bSelected1 = UIHelper.GetSelected(self.TogTabTeam)
        local bSelected2 = UIHelper.GetSelected(self.TogTabRaid)
        UIHelper.SetSelected(self.TogTabTeam, not bSelected1)
        UIHelper.SetSelected(self.TogTabRaid, not bSelected2)
    end

    Timer.AddFrame(self, 10, function ()
        self:RedirectToDungeonPosition()
    end)
end

function UIDungeonEntranceView:RedirectToDungeonPosition()
    if not self.dwCurSelectMapID then return end

    for _, tContainer in ipairs(self.scriptDungeonList.tContainerList) do
        local scriptContainer = tContainer.scriptContainer
        for _, scriptCell in ipairs(scriptContainer.tItemScripts) do
            local tHeadInfo = scriptCell.tHeadInfo
            for _, tRecord in ipairs(tHeadInfo.tRecordList) do
                if tRecord.dwMapID == self.dwCurSelectMapID then
                    scriptContainer:SetSelected(true)
                    UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                    scriptCell.fCallBack(scriptCell.tHeadInfo)
                    return
                end
            end
        end
    end
end

function UIDungeonEntranceView:LinkWeeklyTeamDungeon()
    for _, szVersionName in ipairs(self.tVersionOrderNames) do
        local tVersionInfo = self.tVesionDungeonMap[szVersionName]
        for _, tHeadInfo in ipairs(tVersionInfo.tHeadInfoList) do
            for _, tRecord in ipairs(tHeadInfo.tRecordList) do
                local dwClassID = tRecord.dwClassID
                if DungeonData.tbFlagMap[tRecord.dwMapID] == 2 and (dwClassID == 1 or dwClassID == 2) then
                    self:SelectCurDungeonMapByMapID(tRecord.dwMapID)
                    break
                end
            end
        end
    end
end

return UIDungeonEntranceView