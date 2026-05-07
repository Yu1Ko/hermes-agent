-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: self
-- Date: 2023-09-11 16:05:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

SwordMemoriesData = SwordMemoriesData or {className = "SwordMemoriesData"}
local self = SwordMemoriesData
-------------------------------- 消息定义 --------------------------------
SwordMemoriesData.Event = {}
SwordMemoriesData.Event.XXX = "SwordMemoriesData.Msg.XXX"

local QUEST_STATE_TO_CONTENT = {
    [-1] = "未接受",
    [QUEST_STATE.UNFINISHED] = "未完成",
    [QUEST_STATE.FINISHED] = "已完成",
}

local function ParseStringList(szList)
    local tRes = {}
    local t    = SplitString(szList, ";")
    for _, v in pairs(t) do
        local value = tonumber(v)
        if value then
            table.insert(tRes, value)
        end
    end
    return tRes
end

local function ParseStringReward(szReward)
    local tRes = {}
    local t    = SplitString(szReward, ";")
    for _, v in pairs(t) do
        local value = SplitString(v, "_")
        if value then
            local dwTabType = tonumber(value[1])
            local dwIndex = tonumber(value[2])
            local nCount = tonumber(value[3]) or 0
            local ItemInfo = GetItemInfo(dwTabType, dwIndex)
            if ItemInfo then
                local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo, nCount)
                szItemName = UIHelper.GBKToUTF8(szItemName)
                table.insert(tRes, {szItemName, nCount, dwTabType, dwIndex})
            end
        end
    end
    return tRes
end

function SwordMemoriesData.OnLogin()

end

function SwordMemoriesData.OnFirstLoadEnd()

end


function SwordMemoriesData.Init()
    self.tbSeasonList = Table_GetStorySeasonList()
    self.tbSectionList = Table_GetStorySectionList()
    self.tbChapterList = Table_GetStoryChapterList()

    for k, v in pairs(self.tbSectionList) do
        v.tQuestList = ParseStringList(v.szQuestList)
    end
    self.InitQuestList()
    self._registerEvent()
end

function SwordMemoriesData.UnInit()
    Event.UnRegAll(self)
    self.StopSound()
end

function SwordMemoriesData.InitQuestList()
    self.tbQuestList = {}
    for nIndex, nSeasonID in ipairs(SWORDMEMORIY_SEASONIDLIST) do
        local tbChapterList = self.GetChapterList(nSeasonID)
        for _, nChapterID in ipairs(tbChapterList) do
            local tSectionList = self.GetSectionList(nChapterID)
            local nTotal = #tSectionList
            if nTotal > 0 then
                local szSectionID = tSectionList[nTotal]
                local tbSection = self.GetSectionInfo(tonumber(szSectionID))
                local szQuestList = tbSection.szQuestList
                szQuestList = string.gsub(szQuestList, "%;$", "")
                local tbQuestIDList = string.split(szQuestList, ";")
                local nTotalQuestNum = #tbQuestIDList
                if nTotalQuestNum > 0 then
                    self.tbQuestList[tbQuestIDList[nTotalQuestNum]] = true
                end
            end
        end
    end
end

function SwordMemoriesData.IsForceMatch(nForceMask)
    if nForceMask == -1 then return true end
    return GetNumberBit(nForceMask, g_pClientPlayer.dwBitOPForceID + 1)
end

function SwordMemoriesData.IsLevelMatch(nLevel)
    return g_pClientPlayer.nLevel >= nLevel
end

function SwordMemoriesData.IsCampMatch(nCampMask)
    if nCampMask == -1 then return true end
    return GetNumberBit(nCampMask, g_pClientPlayer.nCamp + 1)
end

function SwordMemoriesData.GetOriginSectionList(nChapterID)
    if not nChapterID then return {} end
    -- if self.tbSectionMap and self.tbSectionMap[nChapterID] then
    --     return self.tbSectionMap[nChapterID]
    -- end

    local tSectionList = {}
    local tbSection = self.tbChapterList[nChapterID]
    if tbSection  then
        local szSection = tbSection.szSectionList
        tSectionList = string.split(szSection, ";")
    end
    return tSectionList
end

function SwordMemoriesData.GetSectionList(nChapterID)
    if not nChapterID then return {} end

    local tSectionList = {}
    local tbSection = self.tbChapterList[nChapterID]
    if tbSection  then
        local szSection = tbSection.szSectionList
        tSectionList = string.split(szSection, ";")
    end

    for nIndex = #tSectionList, 1, -1 do
        local szSectionID = tSectionList[nIndex]
        if not self.CanSectionShow(tonumber(szSectionID)) then
            table.remove(tSectionList, nIndex)
        end
    end

    return tSectionList
end

function SwordMemoriesData.GetSectionInfo(nSectionID)
    return self.tbSectionList[nSectionID]
end

function SwordMemoriesData.GetSectionIDByChapterID(nChapterID)
    if not nChapterID then return nil end
    for nIndex, nSeasonID in ipairs(SWORDMEMORIY_SEASONIDLIST) do
        local tbChapterList = self.GetChapterList(nSeasonID)
        for _, dwChapterID in ipairs(tbChapterList) do
            if tonumber(dwChapterID) == nChapterID then
                return nSeasonID
            end
        end
    end
    return nil
end

function SwordMemoriesData.GetChapterList(nSeasonID)
    if not nSeasonID then return {} end
    if self.tbChapterMap and self.tbChapterMap[nSeasonID] then
        return self.tbChapterMap[nSeasonID]
    end
    local tbChapterList = {}
    local tbSeason = self.tbSeasonList[nSeasonID]
    if tbSeason then
        local szChapterList = tbSeason.szChapterList
        tbChapterList = string.split(szChapterList, ";")
    end
    if not self.tbChapterMap then self.tbChapterMap = {} end
    self.tbChapterMap[nSeasonID] = tbChapterList
    return tbChapterList
end

function SwordMemoriesData.GetSeasonDesc(nSeasonID)
    local szDesc = ""
    -- local tbSeason = self.tbSeasonList[nSeasonID]
    -- if tbSeason then
    --     szDesc = UIHelper.GBKToUTF8(tbSeason.szDesc)
    -- end
    return szDesc
end

function SwordMemoriesData.GetSeasonName(nSeasonID)
    local szName = ""
    local tbSeason = self.tbSeasonList[nSeasonID]
    if tbSeason then
        szName = UIHelper.GBKToUTF8(tbSeason.szName)
    end
    return szName
end

function SwordMemoriesData.HasGetReward(nSeasonID)
    local tbSeason = self.tbSeasonList[nSeasonID]
    if tbSeason then
        nQuestID = tbSeason.dwQuestID
        local nQuestState = g_pClientPlayer.GetQuestPhase(tbSeason.dwQuestID)
        return nQuestState == QUEST_PHASE.FINISH
    end
    return false
end

function SwordMemoriesData.HasRewardList(nSeasonID)
    local tbSeason = self.tbSeasonList[nSeasonID]
    if tbSeason then
        return tbSeason.szReward ~= ""
    end
    return false
end

function SwordMemoriesData.GetFinishedSectionCount(nChapterID)
    local tbSectionList = self.GetSectionList(nChapterID)
    local nCount = 0
    for nIndex, nSectionID in ipairs(tbSectionList) do
        local tbInfo = self.GetSectionInfo(nSectionID)
        local bFinished = self.IsSectionFinished(tbInfo)
        nCount = nCount + (bFinished and 1 or 0)
    end
    return nCount, #tbSectionList
end

function SwordMemoriesData.IsSectionFinished(tInfo)
    local tSectionInfo = tInfo
    if not tSectionInfo then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local bResult   = true
    local dwQuestID = nil

    --先判最后一个任务
    local nLen = #tSectionInfo.tQuestList
    local dwID = tSectionInfo.tQuestList[nLen]
    if hPlayer.GetQuestState(dwID) ~= QUEST_STATE.FINISHED then
        bResult = false
    end

    --没完成再判任务线
    if not bResult then
        for _, v in pairs(tSectionInfo.tQuestList) do
            if hPlayer.GetQuestState(v) ~= QUEST_STATE.FINISHED then
                dwQuestID = v
                break
            end
        end
    end
    return bResult, dwQuestID
end

function SwordMemoriesData.GetLockSectionContent(tInfo)
    local pPlayer = g_pClientPlayer
    if pPlayer and tInfo then
        local szQuestList = tInfo.szQuestList
        szQuestList = string.gsub(szQuestList, "%;$", "")
        local tbQuestIDList = string.split(szQuestList, ";")
        local nCount = 0
        local nTotal = #tbQuestIDList
        for nIndex, szQuestID in ipairs(tbQuestIDList) do
            local nQuestID = tonumber(szQuestID)
            local nState = pPlayer.GetQuestState(nQuestID)
            if nQuestID and nState ~= QUEST_STATE.FINISHED then
                if nIndex == #tbQuestIDList then
                    return string.format("完成【%s】后解锁该小节", QuestData.GetQuestName(nQuestID))
                else
                    return string.format("完成【%s】后解锁【%s】", QuestData.GetQuestName(nQuestID), QuestData.GetQuestName(tostring(tbQuestIDList[nIndex + 1])))
                end
            end
        end
    end
    return ""
end

function SwordMemoriesData.IsChapterFinished(nChapterID, bNotDetail)
    local bFinished = false
    -- local tSectionList = self.GetSectionList(nChapterID)
    -- local nTotal = #tSectionList
    -- if nTotal > 0 then
    --     local tInfo = self.GetSectionInfo(tonumber(tSectionList[nTotal]))
    --     if self.IsSectionFinished(tInfo) then
    --         bFinished = true
    --     end
    -- end

    local nCount, nTotal = self.GetSectionFinishedCount(nChapterID)

    return nCount == nTotal
end

function SwordMemoriesData.GetSectionFinishedCount(nChapterID)
    local nCount = 0
    local tSectionList = self.GetSectionList(nChapterID)
    for _, szSectionID in ipairs(tSectionList) do
        local tbInfo = self.GetSectionInfo(tonumber(szSectionID))
        if self.IsSectionFinished(tbInfo) then
            nCount = nCount + 1
        end
    end
    return nCount, #tSectionList
end



function SwordMemoriesData.CanChapterShow(dwChapterID)
    local tChapterInfo = self.GetChapterInfo(dwChapterID)
    if not tChapterInfo then
        return
    end

    local bResult = true
    local tbSectionList =self.GetOriginSectionList(dwChapterID)
    local nCount  = #tbSectionList
    local nShow   = 0
    for _, v in pairs(tbSectionList) do
        if not self.CanSectionShow(tonumber(v)) then
            nShow = nShow + 1
        end
    end
    bResult = not (nShow ~= 0 and nShow == nCount)
    return bResult
end

function SwordMemoriesData.CanSectionShow(dwSectionID)
    local tSectionInfo = SwordMemoriesData.GetSectionInfo(dwSectionID)
    if not tSectionInfo then
        return
    end

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local nLevel      = hPlayer.nLevel
    local nBitCamp    = hPlayer.nCamp + 1
    local nBitForce   = hPlayer.dwBitOPForceID + 1
    local bCampLegal  = tSectionInfo.nCampMask == -1 or GetNumberBit(tSectionInfo.nCampMask, nBitCamp)
    local bForceLegal = tSectionInfo.nForceMask == "-1" or GetNumberBit(tonumber(tSectionInfo.nForceMask), nBitForce)
    local bLevelLegal = nLevel >= tSectionInfo.nLevel

    return bCampLegal and bForceLegal and bLevelLegal
end


function SwordMemoriesData.GetChapterInfo(nChapterID)
    return self.tbChapterList[nChapterID]
end


function SwordMemoriesData.GetChapterProgress(nChapterID)
    local nCount, nTotal = 0, 0
    local tSectionList = self.GetSectionList(nChapterID)
    if tSectionList then
        for nIndex, szSectionID in ipairs(tSectionList) do
            local tInfo = self.GetSectionInfo(tonumber(szSectionID))
            -- if self.IsSectionVisible(tInfo) then
                local bFinished, bLock = self.IsSectionFinished(tInfo)
                if bFinished then
                    nCount = nCount + 1
                end
                nTotal = nTotal + 1
            -- end
        end
    end
    return nCount, nTotal
end

function SwordMemoriesData.IsSeasonFinished(nSeasonID)
    local nCount, nTotal = self.GetSeasonProgress(nSeasonID)
    return nCount == nTotal
end

function SwordMemoriesData.CanGetReward(nSeasonID)
    local bHasReward = SwordMemoriesData.HasRewardList(nSeasonID)
    if not bHasReward then return false end -- 没有奖励
    local nCount, nTotal = self.GetSeasonProgress(nSeasonID, true)
    return nCount == nTotal and nTotal ~= 0 and not self.HasGetReward(nSeasonID)
end

function SwordMemoriesData.GetSeasonProgress(nSeasonID)
    local tChapterList = self.GetChapterList(nSeasonID)
    local nFinish = 0
    local nTotal = 0
    if tChapterList then
        for _, szChapterID in ipairs(tChapterList) do
            if self.CanChapterShow(tonumber(szChapterID)) then
                if self.IsChapterFinished(tonumber(szChapterID)) then
                    nFinish = nFinish + 1
                end
                nTotal = nTotal + 1
            end
        end
    end
    return nFinish, nTotal
end

function SwordMemoriesData.GetSeasonRewardList(nSeasonID)
    if not self.tbRewardMap then self.tbRewardMap = {} end
    if not self.tbRewardMap[nSeasonID] then
        local tbSeason = self.tbSeasonList[nSeasonID]
        local szReward = tbSeason.szReward
        self.tbRewardMap[nSeasonID] = ParseStringReward(szReward)
    end
    return self.tbRewardMap[nSeasonID]

end

function SwordMemoriesData.GetFirstUnFinishQuestID(nChapterID)
    local bFinish = self.IsChapterFinished(nChapterID)
    if bFinish then return 0 end
    local tSectionList = self.GetSectionList(nChapterID)
    if tSectionList then
        for nIndex, szSectionID in ipairs(tSectionList) do
           local tbSection = self.GetSectionInfo(tonumber(szSectionID))
           local szQuestList = tbSection.szQuestList
           local tbQuestIDList = string.split(szQuestList, ";")
           for nIndex, szQuestID in ipairs(tbQuestIDList) do
               local nQuestID = tonumber(szQuestID)
               if nQuestID and g_pClientPlayer and g_pClientPlayer.GetQuestState(nQuestID) ~= QUEST_STATE.FINISHED then
                   return nQuestID
               end
           end
        end
    end
    return 0
end

function SwordMemoriesData.GetCurrentMapQuest(dwMapID)
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    if not dwMapID then
        dwMapID = hPlayer.GetMapID()
    end

    for nIndex, nSeasonID in ipairs(SWORDMEMORIY_SEASONIDLIST) do
        local tbChapterList = self.GetChapterList(nSeasonID)
        for _, szChapterID in ipairs(tbChapterList) do
            local dwChapterID = tonumber(szChapterID)
            if self.CanChapterShow(dwChapterID) then
                local nQuestID = self.GetFirstUnFinishQuestID(dwChapterID)
                if nQuestID and nQuestID ~= 0 then
                    local nMapID, tbPoints = QuestData.GetQuestMapIDAndPoints(nQuestID)
                    if nMapID == dwMapID then
                        return nQuestID, nMapID, tbPoints
                    end
                end
            end
        end
    end
    return nil, nil, nil
end


function SwordMemoriesData.GetFirstSoundID(szSoundList)
    local nFirstSoundID = nil
    self.tbSoundList = SplitString(szSoundList, ";")
    -- if self.IsSoundPlaying() then
        for i, v in ipairs(self.tbSoundList) do
            self.tbSoundList[i] = tonumber(v)
        end
        nFirstSoundID = self.tbSoundList[1]
    -- end
    return nFirstSoundID
end

function SwordMemoriesData.GetNextSoundID(nLastSoundID)
    local nNextSoundIndex = nil
    -- if self.IsSoundPlaying() then
        for nIndex, nSoundID in ipairs(self.tbSoundList) do
            if nSoundID == nLastSoundID then
                nNextSoundIndex = nIndex + 1
            end
        end
        if nNextSoundIndex then
            local nNextSoundID = self.tbSoundList[nNextSoundIndex]
            return nNextSoundID
        end
    -- end
    return nil
end


function SwordMemoriesData.IsSoundPlaying()
    return self.tbSoundInfo ~= nil
end

function SwordMemoriesData.IsSameSound(nSoundIndex)
    return self.tbSoundInfo and self.tbSoundInfo.nIndex == nSoundIndex
end

function SwordMemoriesData.StartPlaySoundBySoundID(nSoundIndex)

    local func = function()
        self.StopSound()
        self.nCurSoundIndex = nSoundIndex
        self.PlaySound()
    end
    local bIsLoading = SceneMgr.IsLoading()
    if bIsLoading then
        self.funcRemotePlaySound = func--没进入场景,延迟播放
    else
        func()
    end
end

function SwordMemoriesData.StartPlaySound(szSoundList)
    -- self.StopSound()
    local nSoundIndex = self.GetFirstSoundID(szSoundList)
    if self.IsSameSound(nSoundIndex) then return end
    self.nCurSoundIndex =  nSoundIndex
    self.PlaySound()
end

function SwordMemoriesData.PlayNextSound()
    self.nCurSoundIndex = self.GetNextSoundID(self.nCurSoundIndex)
    self.PlaySound()
end

function SwordMemoriesData.PlaySound()
    if self.nCurSoundIndex then
        self.tbSoundInfo = Table_GetSoundInfo(self.nCurSoundIndex)
        SoundMgr.PlaySound(SOUND.CHARACTER_SPEAK, self.tbSoundInfo.szSoundPath, nil, true)
    else
        self.tbSoundInfo = nil
    end
    Event.Dispatch(EventType.OnSwordMemoriesSoundChanged)
end

function SwordMemoriesData.ShowAllSection(bShowAllSection)
    if IsDebugClient() then
        self.bShowAllSection = bShowAllSection
        Event.Dispatch(EventType.OnShowAllSection)
    end
end

function SwordMemoriesData.IsShowAllSection()
    return self.bShowAllSection
end

function SwordMemoriesData.IsShowRedPoint()
    for nIndex, nSeasonID in ipairs(SWORDMEMORIY_SEASONIDLIST) do
        if self.CanGetReward(nSeasonID) then
            return true
        end
    end
    return false
end

function SwordMemoriesData.StopSound()

    if self.nSoundID then SoundMgr.StopSound(self.nSoundID, true) end

    self.tbSoundList = nil
    self.nCurSoundIndex = nil
    self.tbSoundInfo = nil
    self.nSoundID = nil
    Event.Dispatch(EventType.OnSwordMemoriesSoundChanged)
end


function SwordMemoriesData._registerEvent()
    Event.Reg(self, "PLAY_SOUND_FINISHED", function()
        if self.nSoundID and arg0 == self.nSoundID then
            -- if self.IsSoundPlaying() then
                self.PlayNextSound()
            -- end
		end
    end)

    Event.Reg(self, "SYNC_SOUND_ID", function()
        if self.tbSoundInfo and arg1 == self.tbSoundInfo.szSoundPath then
			self.nSoundID = arg0
            if arg0 == 0 then self.StopSound() end--等于0为播放失败
		end
    end)

    Event.Reg(self, "LOADING_END", function()
        if self.funcRemotePlaySound then
            Timer.Add(self, 1, function()
                self.funcRemotePlaySound()
                self.funcRemotePlaySound = nil
            end)
        end
    end)

    Event.Reg(self, "OnClientPlayerLeave", function()
        self.StopSound()
    end)

    Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
		if self.tbQuestList[nQuestID] then
            Event.Dispatch(EventType.OnRewardStateChanged)
        end
	end)

	Event.Reg(self, "SUCCESSIVE_QUEST_FINISHED", function(nQuestID, nNextQuestID)
		if self.tbQuestList[nQuestID] then
            Event.Dispatch(EventType.OnRewardStateChanged)
        end
	end)

    Event.Reg(self, EventType.UpdateMainStoryReward, function()
        Event.Dispatch(EventType.OnRewardStateChanged)
    end)
end