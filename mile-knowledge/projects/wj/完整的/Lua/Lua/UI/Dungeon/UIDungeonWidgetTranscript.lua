local UIDungeonWidgetTranscript = class("UIDungeonWidgetTranscript")

local tImageDifficutyIcon = {
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_01.png",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_02.png",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_03.png"
}

local tImageEntraceBg = {
    "UIAtlas2_Dungeon_Dungeon01_Img_EntraceBg01.png",
    "UIAtlas2_Dungeon_Dungeon01_Img_EntraceBg02.png",
    "UIAtlas2_Dungeon_Dungeon01_Img_EntraceBg03.png",
    "UIAtlas2_Dungeon_Dungeon01_Img_EntraceBg04.png"
}

local szDifficultySmallGroup = "UIAtlas2_Dungeon_Dungeon01_img_title_icon_04.png"
local szDifficultyBigGroup = "UIAtlas2_Dungeon_Dungeon01_img_title_icon_03.png"

function UIDungeonWidgetTranscript:OnEnter(nDungeonIndex, nDifficulty, tRecord, tMapInfo, nDungeonCopyID, tSwitchMapInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local player = GetClientPlayer()
    if player then
        ApplyDungeonRoleProgress(tRecord.dwMapID, player.dwID)
    end
    
    self:UpdateInfo(nDungeonIndex, nDifficulty, tRecord, tMapInfo, nDungeonCopyID, tSwitchMapInfo)
end

function UIDungeonWidgetTranscript:OnExit()
    self.bInit = false
end

function UIDungeonWidgetTranscript:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTranscript, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected then
            Event.Dispatch(EventType.OnDungeonDifficultySelectChanged, self.nDungeonIndex)
        end
	end)

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
end

function UIDungeonWidgetTranscript:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonWidgetTranscript:UpdateInfo(nDungeonIndex, nDifficulty, tRecord, tMapInfo, nDungeonCopyID, tSwitchMapInfo)
    self.nDungeonIndex = nDungeonIndex
    self.tRecord = tRecord
    local player = GetClientPlayer()
    UIHelper.SetSpriteFrame(self.ImgNormalAll, tImageDifficutyIcon[nDifficulty])
    UIHelper.SetSpriteFrame(self.ImgNormal, tImageEntraceBg[nDungeonIndex])
    if tRecord.nClassID == 1 then
        UIHelper.SetSpriteFrame(self.ImgIconNormal, szDifficultySmallGroup)
    else
        UIHelper.SetSpriteFrame(self.ImgIconNormal, szDifficultyBigGroup)
    end

    local szLayer3Name = UIHelper.GBKToUTF8(tRecord.szLayer3Name)
    szLayer3Name = DungeonData.ExtractChineseNumText(szLayer3Name)
    UIHelper.SetString(self.LabelNormal, szLayer3Name)

    -- 最低等级
    local szFitLevel = tostring(tSwitchMapInfo.nMinLevelLimit)
    szFitLevel = "需求等级："..szFitLevel..g_tStrings.STR_LEVEL
    local bMinLevelLimit = tSwitchMapInfo.nMinLevelLimit > 0 and tSwitchMapInfo.nMinLevelLimit > player.nLevel
    local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(0xAE, 0XD9, 0XE0)
    if bMinLevelLimit then
        UIHelper.SetString(self.LabelLevel, szFitLevel)
        UIHelper.SetTextColor(self.LabelLevel, colorRed)
    else
        UIHelper.SetString(self.LabelLevel, "可进入")
        UIHelper.SetTextColor(self.LabelLevel, colorWhite)
    end
    --UIHelper.SetVisible(self.LabelLevel, bMinLevelLimit)
    -- 剩余刷新时间
    if not tMapInfo or tMapInfo.nRefreshTime <= 0 then
        UIHelper.SetString(self.LabelTimeNum, g_tStrings.Dungeon.STR_DUNGEON_REFRESHED)
    else
        local szLeftTime = UIHelper.GetHeightestTimeText(tMapInfo.nRefreshTime)
        UIHelper.SetString(self.LabelTimeNum, szLeftTime)
    end

    -- 剩余进入次数
    local szEnterTimes = self:GetEnterTimesString(tRecord.dwMapID, nDungeonCopyID)
    UIHelper.SetString(self.LabelDegreeNum, szEnterTimes)

    -- 刷新副本进度/副本编号
    local player = GetClientPlayer()
    local _,_,_,_,_,_,_,bIsDungeonRoleProgressMap = GetMapParams(tRecord.dwMapID)
    UIHelper.SetVisible(self.WidgetKillProgress, bIsDungeonRoleProgressMap)
    UIHelper.SetVisible(self.WidgetDungeonID, not bIsDungeonRoleProgressMap)
    if bIsDungeonRoleProgressMap then
        local aProgressIDs = {}
        local aBossProcessInfoList = Table_GetCDProcessBoss(tRecord.dwMapID)
        for j = 1, #aBossProcessInfoList do
            table.insert(aProgressIDs, aBossProcessInfoList[j].dwProgressID)
        end
        local dwPlayerID = player and player.dwID
        if dwPlayerID then
            self:RefreshKillBossProgress(tRecord.dwMapID, dwPlayerID, aProgressIDs)
        end
    else
        if nDungeonCopyID then
            UIHelper.SetString(self.LabelDungeonID, tostring(nDungeonCopyID))
        else
            UIHelper.SetString(self.LabelDungeonID, g_tStrings.STR_NONE)
        end
    end

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(tRecord.dwMapID)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UIDungeonWidgetTranscript:RefreshKillBossProgress(dwMapID, dwPlayerID, aProgressIDs)
    self.aKillingState = {}
    for i = 1, #self.tProgressPoints do
        UIHelper.SetVisible(self.tProgressPoints[i], false)
        local nodeParent = UIHelper.GetParent(self.tProgressPoints[i])
        UIHelper.SetVisible(nodeParent, false)
    end
    for i = 1, #aProgressIDs do
        if i <= #self.tProgressPoints then
            local nProgressID = aProgressIDs[i]
            local bHasKilled = GetDungeonRoleProgress(dwMapID, dwPlayerID, nProgressID)
            local nodeParent = UIHelper.GetParent(self.tProgressPoints[i])
            UIHelper.SetVisible(nodeParent, true)
            UIHelper.SetVisible(self.tProgressPoints[i], bHasKilled)
            UIHelper.SetVisible(self.tUnkilledPoints[i], not bHasKilled)
            table.insert(self.aKillingState, bHasKilled)
        end
	end
    UIHelper.LayoutDoLayout(self.WidgetPoints)
end

function UIDungeonWidgetTranscript:GetEnterTimesString(dwMapID, nDungeonCopyID)
	local szEnterTimes = ""

	local _, _, _, _, _, _, bCanReset = GetMapParams(dwMapID)
	if bCanReset then
        szEnterTimes = g_tStrings.Dungeon.STR_DUNGEON_NO_LIMITED_TIMES--不限次数
    else
        if nDungeonCopyID then
            szEnterTimes = "0" .. g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_ENTER_TIME
        else
            szEnterTimes = "1" .. g_tStrings.Dungeon.CYCLOPAEDIA_DUNGEON_ENTER_TIME
        end
    end
	return szEnterTimes
end

return UIDungeonWidgetTranscript