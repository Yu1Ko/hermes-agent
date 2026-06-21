HomelandFlowerPriceData = HomelandFlowerPriceData or {className = "HomelandFlowerPriceData"}
local self = HomelandFlowerPriceData

-- 家园花价
local tFlowerPriceRankList = { --各个地图对应的排行榜typeID
	[455] = {257, "广陵邑"},
	[471] = {258, "枫叶泊·乐苑"},
	[486] = {259, "枫叶泊·天苑"},
	[462] = {261, "九寨沟·镜海"},
	[674] = {296, "浣花水榭"},
}

function HomelandFlowerPriceData.Init()
    self.nLastApplyTime = 0
    self.tPriceInfo = {}
    self.tFlowerPriceRankListConvert = {}
    self.tSeedInfo = GDAPI_LandGetSeedInfoList()
    self.tChengPin = GDAPI_LandGetProductInfoList()
    self.RegEvent()
end

function HomelandFlowerPriceData.UnInit()
    self.nLastApplyTime = 0
    self.tPriceInfo = {}
    self.tFlowerPriceRankListConvert = {}
end

function HomelandFlowerPriceData.RegEvent()
    Event.Reg(HomelandFlowerPriceData, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
            self.tPriceInfo = {}
            HomelandFlowerPriceData.bInitRankPriceData = false
		end
    end)

    Event.Reg(HomelandFlowerPriceData, "PLAYER_ENTER_SCENE", function(nEvent)
		if not HomelandFlowerPriceData.bInitRankPriceData then
            HomelandFlowerPriceData.bInitRankPriceData = true
			HomelandFlowerPriceData.GetRankPriceInfo()
		end
    end)

	Event.Reg(HomelandFlowerPriceData, "CUSTOM_RANK_UPDATE", function (bShow)
        if self.tFlowerPriceRankListConvert[arg0] then
            local t = GetCustomRankList(arg0)
            if t then
                FireUIEvent("PLUGIN_FLOWER_PRICE_DATA", self.tFlowerPriceRankListConvert[arg0], t)
            end
            self.tFlowerPriceRankListConvert[arg0] = nil
            for k, _ in pairs(self.tFlowerPriceRankListConvert) do -- 申请一个
                ApplyCustomRankList(k)
                return
            end
        end
	end)

    Event.Reg(HomelandFlowerPriceData, "PLUGIN_FLOWER_PRICE_DATA", function ()
        local nMapID = arg0
        local tInfo = arg1
        self.tPriceInfo[nMapID] = {} --只重置这个地图的
        for _, v in ipairs(tInfo) do
            self.tPriceInfo[nMapID][v.dwID] = {}
            for _, v2 in ipairs(v) do
                table.insert(
                    self.tPriceInfo[nMapID][v.dwID],
                    {nCenterID = v2[2], nLineID = v2[1], nCopyIndex = v2[3]}
                )
            end
        end

        Event.Dispatch("UPDATE_FLOWER_PRICE_DATA")
	end)
end

--scripts/Map/家园系统/include/家园种植参数表.lh--数据
--scripts/Map/家园系统/家园管理/花价查询.lua--排序
function HomelandFlowerPriceData.LoadSeedInfo()
    local tSeed = HomelandFlowerPriceData.tSeedInfo
    local tTempTable = {}
    for k, v in pairs(tSeed) do
        if v.nType == 1 then
            table.insert(tTempTable, k)
        end
    end
    table.sort(tTempTable, function(t1, t2)
        return t1 < t2
    end)

    local tTempFlowerTable = {}
    for k, v in pairs(tTempTable) do
        table.insert(tTempFlowerTable, v)
    end
    local tTempPlantTable = {}
    for k, v in pairs(tSeed) do
        if v.nType == 2 then
            table.insert(tTempPlantTable, k)
        end
    end
    table.sort(tTempPlantTable)
    return tSeed, tTempFlowerTable, tTempPlantTable
end

function HomelandFlowerPriceData.ApplyRankPrice()
    self.tFlowerPriceRankListConvert = {}
	for k, v in pairs(tFlowerPriceRankList) do
		self.tFlowerPriceRankListConvert[v[1]] = k
	end

	for k, _ in pairs(self.tFlowerPriceRankListConvert) do -- 申请一个
		ApplyCustomRankList(k)
		return
	end
end

function HomelandFlowerPriceData.GetRankPriceInfo()
    local nCurTime = GetCurrentTime()
    if JX.CheckPassSevenTime(self.nLastApplyTime, nCurTime) then
        self.tPriceInfo = {} -- 过7点则重置
        self.nLastApplyTime = 0
    end
    if nCurTime - self.nLastApplyTime > 10 then
        self.nLastApplyTime = nCurTime
        HomelandFlowerPriceData.ApplyRankPrice() -- 花价排行榜申请
    end

    return Lib.copyTab(self.tPriceInfo)
end

function HomelandFlowerPriceData.GoToSellFlower(nMapID, nCopyIndex, nSellType)
    MapMgr.BeforeTeleport()
	local bSafeCity = GDAPI_Homeland_SafeCity()
	local dwMapID = HomelandBuildData.GetMapInfo()
	if bSafeCity or nMapID == dwMapID then
		RemoteCallToServer("On_HomeLand_GoToSellFlower", nMapID, nCopyIndex, nSellType)
		return
	end

	MapMgr.CheckTransferCDExecute(function()
		RemoteCallToServer("On_HomeLand_BackToLand", nMapID, nCopyIndex, nSellType)
	end)
end