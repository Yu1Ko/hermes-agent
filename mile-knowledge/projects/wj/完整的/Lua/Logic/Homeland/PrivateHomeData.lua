PrivateHomeData = PrivateHomeData or {className = "PrivateHomeData"}
local self = PrivateHomeData

function PrivateHomeData.Init()
    self.RegEvent()
    self.tbPSubLandConditions = {}
end

function PrivateHomeData.UnInit()

end

function PrivateHomeData.RegEvent()
    Event.Reg(PrivateHomeData, "Home_OnGetPSubLandCons", function(tConditions, dwMapID)
        self.tbPSubLandConditions[dwMapID] = GDAPI_Homeland_UnlockAreaCond(dwMapID)
    end)
end

function PrivateHomeData.GetLandSeasonScore(dwMapID, nCopyIndex, nLandIndex)
    return GetHomelandMgr().GetLandSeasonData(dwMapID, nCopyIndex, nLandIndex, 8, 2) or 0
end

function PrivateHomeData.GetPSubLandCondition(dwMapID)
    self.tbPSubLandConditions[dwMapID] = GDAPI_Homeland_UnlockAreaCond(dwMapID)
    return self.tbPSubLandConditions[dwMapID]
end