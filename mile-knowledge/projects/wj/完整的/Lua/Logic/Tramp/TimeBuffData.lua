-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TimeBuffData
-- Date: 2023-05-08 15:53:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

TimeBuffData = TimeBuffData or {className = "TimeBuffData"}
local self = TimeBuffData
-------------------------------- 消息定义 --------------------------------
TimeBuffData.Event = {}
TimeBuffData.Event.XXX = "TimeBuffData.Msg.XXX"

local DataModel = {}

function TimeBuffData.Init(tTimeBuffList)

    self._registerEvent()
    self.InitTimeBuffList(tTimeBuffList)
end

function TimeBuffData.UnInit()

end

function TimeBuffData.OnLogin()

end

function TimeBuffData.OnFirstLoadEnd()

end

function TimeBuffData.GetCustomBuffInfo(tTimeBuffInfo)
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    local tInfo, tCustomBuffInfo = {}
	for i = 1, pPlayer.GetBuffCount() do
        Buffer_Get(pPlayer, i - 1, tInfo)
        if tInfo.dwID and tInfo.dwID == tTimeBuffInfo.dwBuffID then
            tCustomBuffInfo = {}
            tCustomBuffInfo.nBuffID = tInfo.dwID
            tCustomBuffInfo.nBuffLevel = tInfo.nLevel
            tCustomBuffInfo.bCanCancel = tInfo.bCanCancel
            tCustomBuffInfo.nLeftTime = tTimeBuffInfo.nTime
            tCustomBuffInfo.nStackNum = tInfo.nStackNum
            tCustomBuffInfo.nIconID = Table_GetBuffIconID(tInfo.dwID, tInfo.nLevel)
            tCustomBuffInfo.szName = Table_GetBuffName(tInfo.dwID, tInfo.nLevel)
            --tCustomBuffInfo.szDesc = GetBuffDesc(tInfo.dwID, tInfo.nLevel, "desc")
            break
		end
    end
    return tCustomBuffInfo
end

function TimeBuffData.InitTimeBuffList(tTimeBuffList)
    DataModel.tTimeBuffList = {}
    if tTimeBuffList then
        self.UpdateTimeBuffList(tTimeBuffList)
    end
end

function TimeBuffData.UpdateTimeBuffList(tTimeBuffList)
    for _, tTimeBuffInfo in ipairs(tTimeBuffList) do
        local nIndex = self.GetTimeBuffListIndex(tTimeBuffInfo.dwBuffID)
        if not tTimeBuffInfo.nTime or tTimeBuffInfo.nTime == 0 then
            if nIndex then
                table.remove(DataModel.tTimeBuffList, nIndex)
            end
        else
            local tCustomBuffInfo = self.GetCustomBuffInfo(tTimeBuffInfo)
            if nIndex then 
                DataModel.tTimeBuffList[nIndex] = tCustomBuffInfo
            else
                table.insert(DataModel.tTimeBuffList, tCustomBuffInfo)
            end
        end
    end
    Event.Dispatch(EventType.On_TimeBuffData_Update, DataModel.tTimeBuffList)
end

function TimeBuffData.GetBuffList()
    return DataModel.tTimeBuffList or {}
end

function TimeBuffData.GetTimeBuffListIndex(dwBuffID)
    for index, tCustomBuffInfo in ipairs(DataModel.tTimeBuffList) do
        if tCustomBuffInfo.nBuffID == dwBuffID then
            return index
        end
    end
end

function TimeBuffData.Close()
    Event.Dispatch(EventType.On_TimeBuffData_Update, {})
end

function TimeBuffData._registerEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        TimeBuffData.Close()
    end)
end