-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: QingmingSoulData
-- Date: 2026-03-10 11:54:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

QingmingSoulData = QingmingSoulData or {className = "QingmingSoulData"}
local self = QingmingSoulData

local TASK_COUNT = 4
local DEFAULT_NPC_ID = 1

local tbNpcInfo = {
    dwCurrentNpcID = 0,
    tNpcData = nil,
    tTaskStatus = {},
    bChapterComplete = false,
}

function QingmingSoulData.Init()
    tbNpcInfo.tTaskStatus = {}
    tbNpcInfo.bChapterComplete = false
end

function QingmingSoulData.UnInit()
    tbNpcInfo.dwCurrentNpcID = 0
    tbNpcInfo.tNpcData = nil
    tbNpcInfo.tTaskStatus = {}
end

function QingmingSoulData.LoadNpcData(dwNpcID)
    tbNpcInfo.dwCurrentNpcID = dwNpcID
    tbNpcInfo.tNpcData = Table_GetQMSoulInfoByNpcID(dwNpcID)
    return tbNpcInfo.tNpcData ~= nil
end

function QingmingSoulData.UpdateTaskStatus()
    if not tbNpcInfo.tNpcData then
        return
    end

    local player = GetClientPlayer()
	if not player then 
		return
	end
    
    for i = 1, TASK_COUNT do
        local dwQuestID = tbNpcInfo.tNpcData["dwQuestID" .. i]
        if dwQuestID and dwQuestID > 0 then
            local nQusetState = player.GetQuestPhase(dwQuestID)
            tbNpcInfo.tTaskStatus[i] = nQusetState == QUEST_PHASE.FINISH
        else
            tbNpcInfo.tTaskStatus[i] = false
        end
    end
    
    local nCompleted = 0
    for i = 1, TASK_COUNT do
        if tbNpcInfo.tTaskStatus[i] then
            nCompleted = nCompleted + 1
        end
    end
    tbNpcInfo.bChapterComplete = (nCompleted == TASK_COUNT)
end

function QingmingSoulData.MarkEffectShown(nIndex)
    Storage.QingMingEffect.tShownEffect[nIndex] = true
    Storage.QingMingEffect.Flush()
end

function QingmingSoulData.GetNpcInfo()
    return tbNpcInfo
end