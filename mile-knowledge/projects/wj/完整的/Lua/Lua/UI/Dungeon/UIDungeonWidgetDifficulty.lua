local UIDungeonWidgetDifficulty = class("UIDungeonWidgetDifficulty")

local szDifficultyImgPath = {
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon01",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon02",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon03",
}
local ENUM_DUNGEON_TYPE = {
    SMALL_GROUP = 1, -- 小队秘境
    BIG_GROUP   = 2, -- 团队秘境
}

function UIDungeonWidgetDifficulty:OnEnter(tRecord, tDungeonMapInfo, tDungeonCopyID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local player = GetClientPlayer()
    if player then
        ApplyDungeonRoleProgress(tRecord.dwMapID, player.dwID)
    end
    
    self:UpdateInfo(tRecord, tDungeonMapInfo, tDungeonCopyID)
end

function UIDungeonWidgetDifficulty:OnExit()
    self.bInit = false
end

function UIDungeonWidgetDifficulty:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        if not self.tRecord then
            return
        end
		self:RequestResetMap(self.tRecord.dwMapID)
	end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        if not self.tRecord then
            return
        end
        
        if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonInfo, true) then
            UIMgr.Open(VIEW_ID.PanelDungeonInfo, self.tRecord)
        else
            UIMgr.CloseWithCallBack(VIEW_ID.PanelDungeonInfo, function ()
                UIMgr.Open(VIEW_ID.PanelDungeonInfo, self.tRecord)
            end)
        end	
	end)

    UIHelper.BindUIEvent(self.TogMemory, EventType.OnSelectChanged, function(_,bSelected)
        local bOldSelected = UIHelper.GetSelected(self.TogMemory)
        if bOldSelected == bSelected then
            return
        end
        if not TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetMemoryTips) then
            Timer.AddFrame(self, 1, function ()
                local nX = UIHelper.GetWorldPositionX(self.TogMemory)
                local nY = UIHelper.GetWorldPositionY(self.TogMemory)
                TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMemoryTips, nX, nY, g_tStrings.Dungeon.STR_DUNGEON_PAST_MODE_TIP)
            end)
        end
	end)

    UIHelper.BindUIEvent(self.TogWuShuang, EventType.OnSelectChanged, function(_,bSelected)
        local bOldSelected = UIHelper.GetSelected(self.TogWuShuang)
        if bOldSelected == bSelected then
            return
        end
        if not TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetMemoryTips) then
            Timer.AddFrame(self, 1, function ()
                local nX = UIHelper.GetWorldPositionX(self.TogWuShuang)
                local nY = UIHelper.GetWorldPositionY(self.TogWuShuang)
                TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMemoryTips, nX, nY, g_tStrings.Dungeon.STR_DUNGEON_RUSH_MODE_TIP)
            end)
        end
	end)

    UIHelper.BindUIEvent(self.TogRate, EventType.OnClick, function()
        if not TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetDefeatedBossTips) then
            local nX = UIHelper.GetWorldPositionX(self.TogRate)
            local nY = UIHelper.GetWorldPositionY(self.TogRate)
            TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetDefeatedBossTips, nX, nY, self.tRecord.dwMapID)
        end
	end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.fCallBack()
        end
	end)
end

function UIDungeonWidgetDifficulty:RegEvent()
    Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function ()
        local _,_,_,_,_,_,_,bIsDungeonRoleProgressMap = GetMapParams(self.tRecord.dwMapID)
        if bIsDungeonRoleProgressMap then
            local aProgressIDs = {}
            local aBossProcessInfoList = Table_GetCDProcessBoss(self.tRecord.dwMapID)
            for j = 1, #aBossProcessInfoList do
                table.insert(aProgressIDs, aBossProcessInfoList[j].dwProgressID)
            end
            local player = GetClientPlayer()
            local dwPlayerID = player and player.dwID
            if dwPlayerID then
                self:RefreshKillBossProgress(self.tRecord.dwMapID, dwPlayerID, aProgressIDs)
            end
        end
    end)

    Event.Reg(self, EventType.OnResetMapRespond, function ()
        ApplyDungeonRoleProgress(self.tRecord.dwMapID, UI_GetClientPlayerID())
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 1, function ()
            UIHelper.LayoutDoLayout(UIHelper.GetParent(self.TogWuShuang))
        end)
    end)
end

function UIDungeonWidgetDifficulty:UpdateInfo(tRecord, tDungeonMapInfo, tDungeonCopyID)
    self.tRecord = tRecord or self.tRecord
    self.tDungeonMapInfo = tDungeonMapInfo or self.tDungeonMapInfo
    self.tDungeonCopyID = tDungeonCopyID or self.tDungeonCopyID

    tRecord = self.tRecord

    if tRecord.dwClassID == 1 or tRecord.dwClassID == 2 then
        self.nDungeonType = ENUM_DUNGEON_TYPE.SMALL_GROUP
    else
        self.nDungeonType = ENUM_DUNGEON_TYPE.BIG_GROUP
    end
    -- 前尘/无双图标
    UIHelper.SetVisible(self.TogMemory, false)
    UIHelper.SetSwallowTouches(self.TogMemory, true)
    UIHelper.SetVisible(self.TogWuShuang, false)
    UIHelper.SetSwallowTouches(self.TogWuShuang, true)
    if tRecord.bIsPast then
        UIHelper.SetVisible(self.TogMemory, true)
    elseif tRecord.bRushmode then
        UIHelper.SetVisible(self.TogWuShuang, true)
    end
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.TogMemory))

    -- 难度
    local nDifficultyID = DungeonData.GetDungeonDifficultyID(tRecord.szLayer3Name)
    local szLayer3Name = tRecord.szLayer3Name
    UIHelper.SetString(self.LabelDifficultyName, szLayer3Name)
    UIHelper.SetSpriteFrame(self.ImgIconDifficulty, szDifficultyImgPath[nDifficultyID])
    
    -- 推荐等级
    local player = GetClientPlayer()
    local tSwitchMapInfo = Table_GetDungeonSwitchMapInfo(tRecord.dwMapID) or {
        nMinLevelLimit = player.nMaxLevel,
    }

    local bMinLevelLimit = tSwitchMapInfo and tSwitchMapInfo.nMinLevelLimit > 0 and tSwitchMapInfo.nMinLevelLimit > player.nLevel
    local szFitLevel = tostring(tSwitchMapInfo.nMinLevelLimit)
    szFitLevel = szFitLevel..g_tStrings.STR_LEVEL
    UIHelper.SetString(self.LabelLevelNum, szFitLevel)
    local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(0xFF, 0XFF, 0XFF)
    if bMinLevelLimit then
        UIHelper.SetTextColor(self.LabelLevelNum, colorRed)
    else
        UIHelper.SetTextColor(self.LabelLevelNum, colorWhite)
    end
    -- 剩余刷新时间
    local tMapInfo = self.tDungeonMapInfo[tRecord.dwMapID]
    if not tMapInfo or tMapInfo.nRefreshTime <= 0 then
        UIHelper.SetString(self.LabelTimeNum, g_tStrings.Dungeon.STR_DUNGEON_REFRESHED)
    else
        local szLeftTime = UIHelper.GetHeightestTimeText(tMapInfo.nRefreshTime)
        UIHelper.SetString(self.LabelTimeNum, szLeftTime)
    end

    -- 剩余进入次数
    local szEnterTimes = self:GetEnterTimesString(tRecord.dwMapID)
    UIHelper.SetString(self.LabelDegreeNum, szEnterTimes)

    -- 刷新副本进度/副本编号
    local _,_,_,_,_,_,bCanReset,bIsDungeonRoleProgressMap = GetMapParams(tRecord.dwMapID)
    local bIsItemReset, nItemType, nItemID, nItemCount = CanResetMap(tRecord.dwMapID)
    self.bResetAward = self.nDungeonType == ENUM_DUNGEON_TYPE.SMALL_GROUP or bIsItemReset
    if self.bResetAward then
        UIHelper.SetString(self.LabelReset, "重置秘境")
    else
        UIHelper.SetString(self.LabelReset, "刷新场景")
    end
    bCanReset = self:CanResetDungeon(tRecord.dwMapID, szLayer3Name)
    UIHelper.SetVisible(self.TogRate, bIsDungeonRoleProgressMap)
    UIHelper.SetVisible(self.WidgetDungeonID, not bIsDungeonRoleProgressMap)
    UIHelper.SetVisible(self.WidgetBtnReset, bCanReset)
    if bIsDungeonRoleProgressMap then
        local aProgressIDs = {}
        local aBossProcessInfoList = Table_GetCDProcessBoss(tRecord.dwMapID)
        for j = 1, #aBossProcessInfoList do
            table.insert(aProgressIDs, aBossProcessInfoList[j].dwProgressID)
        end
        local player = GetClientPlayer()
        local dwPlayerID = player and player.dwID
        if dwPlayerID then
            self:RefreshKillBossProgress(tRecord.dwMapID, dwPlayerID, aProgressIDs)
        end
    else
        if tDungeonCopyID[tRecord.dwMapID] then
            UIHelper.SetString(self.LabelDungeonIDNum, tostring(tDungeonCopyID[tRecord.dwMapID]))
        else
            UIHelper.SetString(self.LabelDungeonIDNum, g_tStrings.STR_NONE)
        end        
    end
    UIHelper.SetVisible(self.LabelResetTip, not self.bResetAward and self.nKillCount and self.nKillCount > 0)
    UIHelper.SetVisible(self.WidgetDaily, DungeonData.tbFlagMap[tRecord.dwMapID] == 1)
    UIHelper.SetVisible(self.WidgetWeekly, DungeonData.tbFlagMap[tRecord.dwMapID] == 2)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIDungeonWidgetDifficulty:RefreshKillBossProgress(dwMapID, dwPlayerID, aProgressIDs)
    self.aKillingState = {}
    self.nKillCount = 0
    for nIndex, imgPoint in ipairs(self.ImgPoints) do
        local nodeParent = UIHelper.GetParent(imgPoint)
        UIHelper.SetVisible(nodeParent, false)
    end
    for i = 1, #aProgressIDs do
		local nProgressID = aProgressIDs[i]
		local bHasKilled = GetDungeonRoleProgress(dwMapID, dwPlayerID, nProgressID)
		table.insert(self.aKillingState, bHasKilled)

        if bHasKilled then self.nKillCount = self.nKillCount + 1 end 
        local nodeParent = UIHelper.GetParent(self.ImgPoints[i])
        UIHelper.SetVisible(nodeParent, true)
        UIHelper.SetVisible(self.ImgPoints[i], bHasKilled)
        UIHelper.SetVisible(self.ImgUnkilledPoints[i], not bHasKilled)
	end
    UIHelper.LayoutDoLayout(self.WidgetPoints)
end

function UIDungeonWidgetDifficulty:GetEnterTimesString(dwMapID)
	local tInfo = self.tDungeonMapInfo[dwMapID]
	local szEnterTimes = ""
	if not tInfo then
		return szEnterTimes
	end
	
	local _, _, _, _, _, _, bCanReset = GetMapParams(dwMapID)
	if bCanReset then
        szEnterTimes = g_tStrings.Dungeon.STR_DUNGEON_NO_LIMITED_TIMES--不限次数
    else
        if self.tDungeonCopyID[dwMapID] then
            szEnterTimes = "0" .. g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_ENTER_TIME
        else
            szEnterTimes = "1" .. g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_ENTER_TIME
        end
    end
	return szEnterTimes
end

function UIDungeonWidgetDifficulty:RequestResetMap(dwMapID)
    local tDungeonInfo = Table_GetDungeonInfo(dwMapID)
    local szName = UIHelper.GBKToUTF8(tDungeonInfo.szOtherName)
    local msg
    local bIsItemReset, nItemType, nItemID, nItemCount = CanResetMap(dwMapID)
    local hPlayer = GetClientPlayer()
    if not bIsItemReset then
        local _, _, _, _, _, nCostVigor = GetMapParams(dwMapID)
		if not hPlayer.IsVigorAndStaminaEnough(nCostVigor) then
            local szTips = g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_RESET_FAILED_VIGOR..tostring(nCostVigor)..g_tStrings.Dungeon.STR_TYPE_POINT
			TipsHelper.ShowNormalTip(szTips, false)
			return
		end
        
        msg = string.format("重置%s，需要消耗%d精力，是否确认重置？该操作仅能重置自己的秘境进度。", szName, nCostVigor)
    elseif nItemType > 0 and nItemID > 0 then
        local itemInfo = ItemData.GetItemInfo(nItemType, nItemID)
        local szItemName = ItemData.GetItemNameByItemInfo(itemInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
        szItemName = GetFormatText(szItemName, nil, nDiamondR, nDiamondG, nDiamondB)
        msg = string.format("重置%s秘境，需要消耗%d个道具%s ，是否确认重置？该操作仅能重置自己的秘境进度。", szName, nItemCount, szItemName)
    end
    if self.bResetAward then
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，再次击败后可以继续获得奖励）"
    else
        msg = msg .. "（重置后重新进入场景，秘境进度及首领会重新生成，但是已经击败过的首领不会再产生掉落，可在秘境大全-领奖记录查看）"
        msg = string.gsub(msg, "重置", "刷新")
    end

    UIHelper.ShowConfirm(msg, function ()
        RemoteCallToServer("OnResetMapRequest", dwMapID)
        OnCheckAddAchievement(982, "Dungeon_First_Refresh")
        Timer.AddFrame(self, 5, function ()
            ApplyDungeonRoleProgress(dwMapID, UI_GetClientPlayerID())
        end)
    end, nil, true)
	OnCheckAddAchievement(982, "Dungeon_First_Refresh")
end

function UIDungeonWidgetDifficulty:SetSelectChangeCallback(fCallBack)
    self.fCallBack = fCallBack
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

function UIDungeonWidgetDifficulty:CanResetDungeon(dwMapID, szName)
	local bRaid = IsRaidFB(szName)
	local _, _, _, _, _, _, bCanReset = GetMapParams(dwMapID)
	if not bCanReset then
		return false
	end
	if not bRaid then
		return self.tDungeonCopyID[dwMapID] ~= nil
    else
        return true
	end
end

return UIDungeonWidgetDifficulty