local UIDungeonDifficultyView = class("UIDungeonDifficultyView")

local tImageDiffculty = {
    "UIAtlas_Dungeon_Dungeon01_img_difficulty_01.png",
    "UIAtlas_Dungeon_Dungeon01_img_difficulty_02.png",
    "UIAtlas_Dungeon_Dungeon01_img_difficulty_03.png",
}


function UIDungeonDifficultyView:OnEnter(dwWindowID, tMapInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIHelper.RemoveAllChildren(self.WidgetTabList)
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetSkillConfiguration, self.WidgetSkillConfiguration)
    end

    self:InitDungeonView(dwWindowID)
    self:UpdateInfo(tMapInfo)
    self:GetMapCopyProgress()
    RemoteCallToServer("OnApplyEnterMapInfoRequest")

    Timer.AddFrameCycle(self, 10, function ()
        self:CheckAssistNewbie()
    end)
end

function UIDungeonDifficultyView:OnExit()
    self.bInit = false
end

function UIDungeonDifficultyView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelDungeonDetail)
	end)

    UIHelper.BindUIEvent(self.BtnTrace01, EventType.OnClick, function()
        self:TryEnterDungeon(false)
	end)

    UIHelper.BindUIEvent(self.BtnTrace02, EventType.OnClick, function()
        self:TryEnterDungeon(true)
	end)

    UIHelper.BindUIEvent(self.BtnAssist, EventType.OnClick, function()
        if not self.nDungeonIndex then return end
        local dwMapID = self.tMapIDList[self.nDungeonIndex]        
        local szContent = string.format(g_tStrings.Dungeon.STR_ASSIST_RELEASE_TIP, AssistNewbieBase.GetReleaseCount(), AssistNewbieBase.RELEASE_MAX_COUNT)
        UIHelper.ShowConfirm(szContent, function ()
            AssistNewbieBase.Release(dwMapID, ASSIST_NEWBIE_TYPE.DUNGEON)
        end)
	end)

    UIHelper.BindUIEvent(self.BtnDungeonPedia, EventType.OnClick, function()
        local dwMapID = self.tMapIDList[self.nDungeonIndex]
        UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {dwTargetMapID = dwMapID})
	end)
end

function UIDungeonDifficultyView:RegEvent()
    Event.Reg(self, EventType.OnMapEnterInfoNotify, function (tData, tData1)
        self:UpdateDungeonEnterMapInfo(tData, tData1)
        self:UpdateInfo(self.tMapInfo)
    end)

    Event.Reg(self, EventType.OnApplyPlayerSavedCopysRespond, function (tData)
        self:OnApplyPlayerSavedCopysRespond(tData)
    end)
    
    Event.Reg(self, EventType.OnDungeonDifficultySelectChanged, function (nDungeonIndex)
        self.nDungeonIndex = nDungeonIndex
        self:UpdateDetailInfo()
    end)

    Event.Reg(self, EventType.OnResetMapRespond, function ()
        local dwMapID = self.tMapIDList[self.nDungeonIndex]
        ApplyDungeonRoleProgress(dwMapID, UI_GetClientPlayerID())
        self:GetMapCopyProgress()
    end)

    Event.Reg(self, "CloseCrossMapPanel", function (...)
        UIMgr.Close(VIEW_ID.PanelDungeonDetail)
    end)

    -- 李树钦定，任何自定义进度条弹出都会关闭秘境入口界面
    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)
end

function UIDungeonDifficultyView:UpdateInfo(tMapInfo)
    self.tMapInfo = tMapInfo

    self.tMapIDList = tMapInfo.tMapIDList
    for i = 1, #tMapInfo.tMapIDList do
        local tRecord = Table_GetDungeonInfo(tMapInfo.tMapIDList[i])
        local tDungeonInfo = DungeonData.tDungeonMapInfo[tRecord.dwMapID]
        local nDungeonCopyID = self.tDungeonCopyID[tRecord.dwMapID]
        local tSwitchMapInfo = Table_GetSwitchMapInfo(tRecord.dwMapID, self.dwWindowID)
        local szLayer3Name = UIHelper.GBKToUTF8(tRecord.szLayer3Name)
        local nDifficulty = DungeonData.GetDungeonDifficultyID(szLayer3Name)
        if tDungeonInfo then
            self.tbScriptTranscript = self.tbScriptTranscript or {}
            if not self.tbScriptTranscript[i] then
                self.tbScriptTranscript[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetTranscript, self.WidgetTabList, i, nDifficulty, tRecord, tDungeonInfo, nDungeonCopyID, tSwitchMapInfo)
            else
                self.tbScriptTranscript[i]:OnEnter(i, nDifficulty, tRecord, tDungeonInfo, nDungeonCopyID, tSwitchMapInfo)
            end

            local scriptTrans = self.tbScriptTranscript[i]
            if scriptTrans then
                if not self.nDungeonIndex then
                    self.nDungeonIndex = i
                    UIHelper.SetSelected(scriptTrans.TogTranscript, true)
                elseif self.nDungeonIndex ~= i then
                    UIHelper.SetSelected(scriptTrans.TogTranscript, false)
                elseif self.nDungeonIndex == i then
                    UIHelper.SetSelected(scriptTrans.TogTranscript, true)
                end
            end
        end
    end
    
    UIHelper.LayoutDoLayout(self.WidgetTabList)
    self:UpdateDetailInfo()
end

function UIDungeonDifficultyView:UpdateDetailInfo()
    if not self.nDungeonIndex then
        return
    end
    local player = GetClientPlayer()
    local dwMapID = self.tMapIDList[self.nDungeonIndex]
    local tRecord = Table_GetDungeonInfo(dwMapID)
    if not tRecord then
        return
    end
    -- 名称
    local szDungeonName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
    szDungeonName = DungeonData.GetChineseNumText(szDungeonName)
    UIHelper.SetString(self.LabelTitle, szDungeonName)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelTitle))
    -- 难度
    local szLayer3Name = UIHelper.GBKToUTF8(tRecord.szLayer3Name)
    szLayer3Name = DungeonData.GetChineseNumText(szLayer3Name)
    UIHelper.SetString(self.LabelDifficulty, szLayer3Name)
    local nDifficulty = DungeonData.GetDungeonDifficultyID(szLayer3Name)
    UIHelper.SetSpriteFrame(self.ImgDifficulty, tImageDiffculty[nDifficulty])

    -- 按钮状态
    local tSwitchMapInfo = Table_GetSwitchMapInfo(dwMapID, self.dwWindowID)
    local bMinLevelLimit = tSwitchMapInfo.nMinLevelLimit > 0 and tSwitchMapInfo.nMinLevelLimit > player.nLevel
    if bMinLevelLimit then
        UIHelper.SetButtonState(self.BtnTrace01, BTN_STATE.Disable, g_tStrings.Dungeon.STR_MIN_LEVEL_LIMIT)
    else
        UIHelper.SetButtonState(self.BtnTrace01, BTN_STATE.Normal)
    end

    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    local nStoryMode = tDungeonInfo and tDungeonInfo.nStoryMode
    UIHelper.SetVisible(self.BtnTrace02, nStoryMode > 0)
    if nStoryMode == 2 then
        UIHelper.SetButtonState(self.BtnTrace02, BTN_STATE.Disable, g_tStrings.Dungeon.STR_FB_STORY_MODE_DIABLE)
    elseif TeamData.IsPlayerInTeam() then
        UIHelper.SetButtonState(self.BtnTrace02, BTN_STATE.Disable, g_tStrings.Dungeon.STR_FBLIST_NO_IN_PARTY)
    else
        UIHelper.SetButtonState(self.BtnTrace02, BTN_STATE.Normal)
    end

    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnTrace01))

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutInfo, true, true)
end

function UIDungeonDifficultyView:CheckAssistNewbie()
    if not self.nDungeonIndex then
        return
    end
    local dwMapID = self.tMapIDList[self.nDungeonIndex]

    local bNeedCheck = dwMapID ~= nil and not TeamData.IsPlayerInTeam() and AssistNewbieBase.CanShowAssistButton(dwMapID)
    UIHelper.SetVisible(self.BtnAssist, bNeedCheck)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnAssist))
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
------------------------------数据处理---------------------------------
function UIDungeonDifficultyView:InitDungeonView(dwWindowID)
    self.dwWindowID = dwWindowID
    self.tDungeonCopyID = {}
    if not DungeonData.tDungeonMapInfo then
        DungeonData.tDungeonMapInfo = {}
    end
end

function UIDungeonDifficultyView:UpdateDungeonEnterMapInfo(tEnterMapInfo, tLeftRefTime)
    DungeonData.tDungeonMapInfo = {}
    for dwMapID, v in pairs(tEnterMapInfo) do
        local _, nMapType, nMaxPlayerCount, nLimitedTimes = GetMapParams(dwMapID)
        local nType, tInfo = nil, nil
        if nMapType and nMapType == MAP_TYPE.DUNGEON then
            local nRefreshCycle = GetMapRefreshInfo(dwMapID)
            local nCanEnterTimes = nLimitedTimes - v
            local nRefreshTime = tLeftRefTime[dwMapID] or 0
            if nRefreshCycle == 0 and nMaxPlayerCount <= 5 then
                DungeonData.tDungeonMapInfo[dwMapID] =
                {
                    nEnterTimes = nCanEnterTimes,
                    nLimitedTimes = nLimitedTimes,
                    nRefreshTime = nRefreshTime
                }
            elseif nRefreshCycle ~= 0 and nMaxPlayerCount <= 5 then
                --local nRefreshTime = tLeftRefTime[dwMapID] or 0
                DungeonData.tDungeonMapInfo[dwMapID] =
                {
                    nEnterTimes = nCanEnterTimes,
                    nLimitedTimes = nLimitedTimes,
                    nRefreshCycle = nRefreshCycle,
                    nRefreshTime = nRefreshTime
                }
            elseif nRefreshCycle ~= 0 and nMaxPlayerCount > 5 then
                --local nRefreshTime = tLeftRefTime[dwMapID] or 0
                DungeonData.tDungeonMapInfo[dwMapID] =
                {
                    nRefreshCycle = nRefreshCycle,
                    nRefreshTime = nRefreshTime
                }
            end
        end
    end
end

function UIDungeonDifficultyView:GetMapCopyProgress()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tData = hPlayer.GetMapCopyProgress()
	self:OnApplyPlayerSavedCopysRespond(tData)
end

function UIDungeonDifficultyView:OnApplyPlayerSavedCopysRespond(tData)
    if not tData then
        self.tDungeonCopyID = {}
        tData = {}
    end
    for dwMapID, v in pairs(tData) do
        self.tDungeonCopyID[dwMapID] = v[1]
    end
end

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

function UIDungeonDifficultyView:CanResetDungeon(dwMapID, szName)
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

function UIDungeonDifficultyView:TryEnterDungeon(bStoryMode)
    local player = GetClientPlayer()
	local bInParty = player.IsInParty()
    local dwMapID = self.tMapIDList[self.nDungeonIndex]

    -- 地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(dwMapID, nil, nil, true) then
        return
    end

    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    local bResetAuth = (bInParty and DungeonData.IsLeader()) or not bInParty
    local bCanReset = self:CanResetDungeon(dwMapID, UIHelper.GBKToUTF8(tDungeonInfo.szLayer3Name)) and bResetAuth

    if bCanReset then
        DungeonData.RequestResetMap(dwMapID, function ()
            self:DoEnterDungeon(dwMapID, bStoryMode)
        end)
    else
        self:DoEnterDungeon(dwMapID, bStoryMode)
    end
end

function UIDungeonDifficultyView:DoEnterDungeon(dwMapID, bStoryMode)
    local bInParty = g_pClientPlayer.IsInParty()
    if not bInParty and not bStoryMode then
        local scriptConfirm = UIHelper.ShowConfirm("该模式难度较大，建议侠士组队前往，你准备好了吗？", function ()
            local tRecruitInfo = Table_GetTeamInfoByMapID(dwMapID)
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
                DungeonData.TryEnterDungeon(dwMapID, bStoryMode, true, self.dwWindowID)
                UIMgr.Close(VIEW_ID.PanelDungeonDetail)
            end)
        end
    else
        DungeonData.TryEnterDungeon(dwMapID, bStoryMode, true, self.dwWindowID)
        UIMgr.Close(VIEW_ID.PanelDungeonDetail)
    end    
end

return UIDungeonDifficultyView