-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CollectionBossData
-- Date: 2024-02-22 16:00:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

CollectionBossData = CollectionBossData or {className = "CollectionBossData"}
local self = CollectionBossData
-------------------------------- 消息定义 --------------------------------
CollectionBossData.Event = {}
CollectionBossData.Event.XXX = "CollectionBossData.Msg.XXX"

local BOSS_CLASS = 
{
    {nClass = 1, szName = g_tStrings.STR_CAMP_BOSS_CLASS_MAIN},
    {nClass = 2, szName = g_tStrings.STR_CAMP_BOSS_CLASS_RANDOM},
    {nClass = 3, szName = g_tStrings.STR_CAMP_BOSS_CLASS_BORN},
}

function CollectionBossData.UnInit()
    
end

function CollectionBossData.OnLogin()
    
end

function CollectionBossData.OnFirstLoadEnd()
    
end

function CollectionBossData.Init()
    if not self.bInit then
        self.tbBossInfo   = self.ParseBossInfo()
        self.bInit = true
    end
end

function CollectionBossData.ParseBossInfo()
    local tbRes  = {}
    local tInfo = Table_GetAllCampBossDetail()
    tbRes[CAMP.GOOD] = {}
    tbRes[CAMP.EVIL] = {}
    for _, v in pairs(BOSS_CLASS) do
        tbRes[CAMP.GOOD][v.nClass] = {}
        tbRes[CAMP.EVIL][v.nClass] = {}
    end
    for _, v in pairs(tInfo) do
        local nCamp  = v.nCamp
        local nClass = v.nClass
        if nCamp and nClass then
            table.insert(tbRes[nCamp][nClass], v)
        end
    end
    tbRes[CAMP.GOOD][3] = nil
    tbRes[CAMP.EVIL][3] = nil
    return tbRes
end


function CollectionBossData.GetBossListByCamp(nCamp)
    if nCamp then
        return self.tbBossInfo[nCamp]
    end
end

function CollectionBossData.GetBossListByClass(nCamp, nClass)
    if nCamp and nClass then
        return self.tbBossInfo[nCamp][nClass]
    end
end

function CollectionBossData.GetBossByID(dwID)
    for nCamp, tList in pairs(self.tbBossInfo) do
        for nClass, tBossList in pairs(tList) do
            for _, v in pairs(tBossList) do
                if v.dwID == dwID then
                    return v
                end
            end
        end
    end
end

function CollectionBossData.GetBossTypeName(nClass)
    for _, v in pairs(BOSS_CLASS) do
        if v.nClass == nClass then
            return v.szName
        end
    end
end
