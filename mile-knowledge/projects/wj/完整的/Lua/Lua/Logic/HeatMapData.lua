-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HeatMapData
-- Date: 2025-03-20 15:35:04
-- Desc: 大攻防热力图
-- ---------------------------------------------------------------------------------

HeatMapData = HeatMapData or {className = "HeatMapData"}
local self = HeatMapData

local AUTO_APPLY_INTERVAL = 3
local HURT_LEVEL_DATA_OFFSET = 11   --策划tCommanderBoardValue中，Boss易伤等级数据相对于HP数据的偏移
local EFFECT_PER_HURT_LEVEL = 30    --每1层易伤等级，效果增加30%
local TONG_COMMAND_BUFF = 18954
local HEAT_MAP_MAX_COUNT = 425

CELL_LENGTH = 32	--逻辑Region中一个Cell的长度
REGION_GRID_WIDTH = 64	--逻辑Region中X轴最多Cell个数
REGION_GRID_HEIGHT = 64	--逻辑Region中Y轴最多Cell个数

HEAT_MAP_REFRESH_CD = {	--热力图刷新CD
    NORMAL      = 3061, --普通人（暂时弃用）
    COMMANDER   = 3062, --指挥（全用指挥CD）
}

HeatMapData.nHeatMapMode = HEAT_MAP_MODE.SHOW_ALL
HeatMapData.bCanShowHeatMap = false

function HeatMapData.Init()
    self.RegEvent()
    -- HeatMapData.EnableDebugMode(true)

    Timer.AddFrameCycle(self, 1, self.OnUpdate)
end

function HeatMapData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function HeatMapData.RegEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local player = GetClientPlayer()
        if not player then
            return
        end

        if self.bDebugMode then
            Event.Dispatch(EventType.OnSwitchCampRightTopState, true)
        end

        local dwMapID = player.GetMapID()
        self.bCanShowHeatMap = self.CanShowHeatMap(dwMapID)
        if self.bCanShowHeatMap then
            self.SetHeatMapMode(HEAT_MAP_MODE.SHOW_ALL)
            self.OnHeatMapEnable()
        end
    end)
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self.bCanShowHeatMap = false
        self.OnHeatMapDisable()
    end)
    Event.Reg(self, "ON_SYNC_SCENE_HEAT_MAP" ,function()
        self.UpdateHeatMapData()
        Event.Dispatch(EventType.OnHeatMapDataUpdate)
    end)
    Event.Reg(self, EventType.OnSelectHeatMapMode, function(nIndex)
        HeatMapData.SetHeatMapMode(nIndex)
    end)
end

function HeatMapData.OnHeatMapEnable()
    self.UpdateHeatMapData()
end

function HeatMapData.OnHeatMapDisable()

end

function HeatMapData.OnUpdate()
    self.UpdateHeatMapEnable()
    self.AutoApplyHeatMapData()
end

function HeatMapData.UpdateHeatMapEnable()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local dwMapID = player.GetMapID()
    local bCanShowHeatMap = self.CanShowHeatMap(dwMapID)
    if bCanShowHeatMap ~= self.bCanShowHeatMap then
        self.bCanShowHeatMap = bCanShowHeatMap
        if bCanShowHeatMap then
            self.OnHeatMapEnable()
        else
            self.OnHeatMapDisable()
        end
    end
end

function HeatMapData.CanAutoApplyHeatMapData()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local dwMapID = hPlayer.GetMapID()
    if Table_IsTongWarFieldMap(dwMapID) then
        local bHaveBuff = Buff_Have(hPlayer, TONG_COMMAND_BUFF)
        return bHaveBuff
    end

    local bIsCommander = MapMgr.IsPlayerCanDraw()
    return bIsCommander
end

function HeatMapData.AutoApplyHeatMapData()
    if not self.bCanShowHeatMap then
        return
    end

    local bCanAutoApply = self.CanAutoApplyHeatMapData()
    if not bCanAutoApply then
        return
    end

    local nTime = GetCurrentTime()
    if self.nHeatMapDataTime and nTime - self.nHeatMapDataTime < AUTO_APPLY_INTERVAL then return end
    self.nHeatMapDataTime = nTime
    self.DoApplyHeatMapInfo()
end

function HeatMapData.UpdateHeatMapData()
    self.tbHeatMapInfo = {}
    self.tbCampCount = {}

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local function UpdateCampHeatMapData(nCamp)
        local hScene = GetClientScene()
        if not hScene then
            return
        end

        local tInfo, nCount = hScene.GetMapHeatInfo(nCamp)
        if not tInfo then
            return
        end

        if self.bDebugMode then
            tInfo, nCount = self.GenerateDebugData()
        end

        self.tbCampCount[nCamp] = math.min(HEAT_MAP_MAX_COUNT, nCount)

        for k, v in pairs(tInfo) do
            local nRegionX, nRegionY = v.nRegionX, v.nRegionY
            if not self.tbHeatMapInfo[nRegionX] then
                self.tbHeatMapInfo[nRegionX] = {}
            end
            if not self.tbHeatMapInfo[nRegionX][nRegionY] then
                self.tbHeatMapInfo[nRegionX][nRegionY] = {}
            end
            self.tbHeatMapInfo[nRegionX][nRegionY][nCamp] = {
                nCamp        = nCamp,
                nRegionX     = nRegionX,
                nRegionY     = nRegionY,
                nLiveCount   = v.nLiveCount,
                nPlayerCount = v.nPlayerCount,
            }
        end
    end

    local dwMapID = hPlayer.GetMapID()
    if Table_IsTongWarFieldMap(dwMapID) then
        UpdateCampHeatMapData(hPlayer.nBattleFieldSide + 1)
    else
        UpdateCampHeatMapData(CAMP.GOOD)
        UpdateCampHeatMapData(CAMP.EVIL)
    end
end

function HeatMapData.GetCampCount(nCamp)
    return self.tbCampCount and self.tbCampCount[nCamp] or 0
end

function HeatMapData.GetHeatMapAreaInfo()
    return self.tbHeatMapInfo or {}
end

function HeatMapData.GetGFAreaNumInfo(dwMapID)
    local tbGFAreaInfo = Table_GetHeatMapAreaInfo(dwMapID)
    if not tbGFAreaInfo then return nil end

    local tbDetail = {}
    for _, v in ipairs(tbGFAreaInfo) do
        local tPoint = SplitString(v.szRegionPoint, ";")
        local nStartX= tonumber(tPoint[1])
        local nStartY= tonumber(tPoint[2])
        local nEndX = nStartX + 2 * (v.nRegionW - 1)
        local nEndY = nStartY + 2 * (v.nRegionH - 1)
        local t = {
            nPQID           = v.nPQID,
            nGoodLiveCount  = 0,
            nGoodTotalCount = 0,
            nEvilLiveCount  = 0,
            nEvilTotalCount = 0,
            nType           = v.nType,
            tAreaInfo       = v
        }
        for i = nStartX, nEndX, 2 do
            for j = nStartY, nEndY, 2 do
                if self.tbHeatMapInfo and self.tbHeatMapInfo[i] and self.tbHeatMapInfo[i][j] then
                    local tInfo = self.tbHeatMapInfo[i][j]
                    t.nGoodLiveCount  = t.nGoodLiveCount + (tInfo[CAMP.GOOD] and tInfo[CAMP.GOOD].nLiveCount or 0)
                    t.nEvilLiveCount  = t.nEvilLiveCount + (tInfo[CAMP.EVIL] and tInfo[CAMP.EVIL].nLiveCount or 0)
                    t.nGoodTotalCount = t.nGoodTotalCount + (tInfo[CAMP.GOOD] and tInfo[CAMP.GOOD].nPlayerCount or 0)
                    t.nEvilTotalCount = t.nEvilTotalCount + (tInfo[CAMP.EVIL] and tInfo[CAMP.EVIL].nPlayerCount or 0)
                end
            end
        end
        table.insert(tbDetail, t)
    end

    return tbDetail

end

--大攻防热力图显示判断
function HeatMapData.CanShowHeatMap(dwMapID)
    if self.bDebugMode then
        return true
    end

    if IsVersionExp() then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local dwCurrentMapID = hPlayer.GetMapID()
    if dwCurrentMapID ~= dwMapID then
        return
    end

    if (dwMapID == 25 and IsActivityOn(706)) or (dwMapID == 27 and IsActivityOn(707)) then
        return true
    end

    if Table_IsTongWarFieldMap(dwMapID) then
        return true
    end
end

function HeatMapData.DoApplyHeatMapInfo()
    if self.bDebugMode then
        Event.Dispatch("ON_SYNC_SCENE_HEAT_MAP")
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nTime = GetCurrentTime()
    local nLeftFrame = hPlayer.GetCDLeft(HEAT_MAP_REFRESH_CD.COMMANDER)
    if nLeftFrame > 0 then
        return
    end
    hPlayer.ApplySceneHeatMap()
end


function HeatMapData.SetHeatMapMode(nHeatMapMode)
    self.nHeatMapMode = nHeatMapMode
end

function HeatMapData.EnableDebugMode(bEnabled)
    self.bDebugMode = bEnabled
    self.UpdateHeatMapData()
end

function HeatMapData.GenerateDebugData()
    --随机数据测试
    local tInfo = {}
    local nCount = 0
    for n = 1, 20 do
        local nRegionX, nRegionY
        local x = Random(6) % 2
        if x == 1 then
            nRegionX = Random(5, 17)
            nRegionY = Random(29, 41)
        else
            nRegionX = Random(27, 41)
            nRegionY = Random(9, 15)
        end
        if nRegionX % 2 == 0 then
            nRegionX = nRegionX + 1
        end
        if nRegionY % 2 == 0 then
            nRegionY = nRegionY + 1
        end
        local nLiveCount = Random(1, 20)
        local nPlayerCount = nLiveCount + Random(1, 10)
        table.insert(tInfo, {
            nRegionX     = nRegionX,
            nRegionY     = nRegionY,
            nLiveCount   = nLiveCount,
            nPlayerCount  = nPlayerCount,
        })
        nCount = nCount + nPlayerCount
    end
    return tInfo, nCount
end