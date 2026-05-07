HomelandCustomBrushData = HomelandCustomBrushData or {className = "HomelandCustomBrushData"}
local self = HomelandCustomBrushData

local MAX_PLAN = 3
local MAX_ITEM = 3
local GRASS_EFFECT_FURN = 0
local GRASS_NOT_EFFECT_FURN = 1

local BRUSH_TYPE = {
    FLOWER = 1,
    FLOOR = 2,
}

local CHOOSED_BRUSH_TYPE =
{
    NULL = 0,
    FLOOR = 1,
    SINGLE_FLOWER = 2,
    FLOWER_PLAN = 3,
    FLOOR_ERASER = 4,
    FLOWER_ERASER = 5,
}

local tWndCofig = {
    ["WndContainer_FlowerBrushContainer"] = BRUSH_TYPE.FLOWER,
    ["WndContainer_FloorBrushContainer"] = BRUSH_TYPE.FLOOR,
}

local SETTING_TYPE = {
    NULL = 0,
    FLOOR_ITEM = 1,
    FLOOR = 2,
    SINGLE_FLOWER = 3,
    FLOWER_PLAN = 4,
    FLOOR_ERASER = 5,
    FLOWER_ERASER = 6,
}
HomelandCustomBrushData.SETTING_TYPE = SETTING_TYPE

local tSettingConfig = {
    [SETTING_TYPE.SINGLE_FLOWER] = {
        {szValName = "nDensity", szWndName = "WndContainer_Density", nMax = 10, nMin = 1},
        {szValName = "nSize", szWndName = "WndContainer_Num", nMax = 2, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_SIZE},
        szControl = "WndContainer_FlowerBrushContainer/WndContainer_SingleFlowerBrush/WndContainer_EditSingleFlowerBrush",
    },
    [SETTING_TYPE.FLOWER_PLAN] = {
        {szValName = "nDensity", szWndName = "WndContainer_Density", nMax = 10, nMin = 1},
        {szValName = "nSize", szWndName = "WndContainer_Num", nMax = 2, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_SIZE,},
        szControl = "WndContainer_FlowerBrushContainer/WndContainer_Plan/CheckBox_Plan",
    },
    [SETTING_TYPE.FLOOR_ITEM] = {
        {szValName = "nEdge", szWndName = "WndContainer_Num", nMax = 4, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_EDGE},
        {szValName = "nStrength", szWndName = "WndContainer_Num", nMax = 4, nMin = 0,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_STRENGTH},
        szControl = "WndContainer_EditFloorBrush/WndContainer_FloorBrush",
    },
    [SETTING_TYPE.FLOOR] = {
        {szValName = "nSize", szWndName = "WndContainer_Num", nMax = 3, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_SIZE},
        szControl = "WndContainer_FloorBrushContainer/WndContainer_FloorBrush/CheckBox_FloorBrush",
    },
    [SETTING_TYPE.FLOWER_ERASER] = {
        {szValName = "nSize", szWndName = "WndContainer_Num", nMax = 2, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_SIZE},
        szControl = "WndContainer_FlowerBrushContainer/WndContainer_Btn_FlowerEraser/CheckBox_FlowerEraser",
    },
    [SETTING_TYPE.FLOOR_ERASER] = {
        {szValName = "nSize", szWndName = "WndContainer_Num", nMax = 3, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_SIZE},
        {szValName = "nEdge", szWndName = "WndContainer_Num", nMax = 4, nMin = 1,
        szUnit = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_OTHER_UNIT, szTitle = g_tStrings.STR_HOMELAND_BUILDING_BRUSH_EDGE},
        szControl = "WndContainer_FloorBrushContainer/WndContainer_Btn_FloorEraser/CheckBox_FloorEraser",
    },
}

local tDefaultPer = {
    [0] = {[1] = 0, [2] = 0, [3] = 0},
    [1] = {[1] = 100, [2] = 0, [3] = 0},
    [2] = {[1] = 50, [2] = 50, [3] = 0},
    [3] = {[1] = 33, [2] = 34, [3] = 33}
}

local STEP = 5

function HomelandCustomBrushData.Init()
    HomelandCustomBrushData.tFloorBrushConfig = {}
    HomelandCustomBrushData.tFlowerBrushConfig = g_HomelandBuildingData.tFlowerBrushConfig

    if not HomelandCustomBrushData.tFlowerBrushConfig then
        HomelandCustomBrushData.tFlowerBrushConfig = {}
        --nDensity 滑条 nSize 两档
        for i = 1, MAX_PLAN do
            table.insert(HomelandCustomBrushData.tFlowerBrushConfig,
                {tBrushID = {[1] = 0, [2] = 0, [3] = 0},
                tBrushPer = {[1] = 0, [2] = 0, [3] = 0},
                nDensity = 5, nSize= 1})
        end
        HomelandCustomBrushData.tFlowerBrushConfig.tSingle = {nBrushID = 0, nDensity = 5, nSize= 1}
    else
        HomelandCustomBrushData.CheckFlowerPlanData()
    end

    HomelandCustomBrushData.nInMode = 0
    HomelandCustomBrushData.tFlowerEditInfo = {
        bInEdit = false,
        tBrushID = {},
        tBrushPer = {},
        nPlanIndex = 0,
        nItemIndex = 0
    }
    HomelandCustomBrushData.RefreshFloorInfo()
    HomelandCustomBrushData.tSettingInfo = {
        nSettingType = SETTING_TYPE.NULL,
        nFlowerPlanIndex = 0,
        nFloorIndex = 0,
        tFlowerEraser = {nSize = 1},
        tFloorEraser = {nSize = 1, nEdge = 1}
    }

    HomelandCustomBrushData.RegEvent()
end

local function GetFlowerItemCountInPlan(tBrushID)
    local nCount = 0
    for i = 1, MAX_ITEM do
        if tBrushID[i] ~= 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function HomelandCustomBrushData.CheckFlowerPlanData()
    local pHLMgr = HomelandCustomBrushData.GetHLMgr()
    if not pHLMgr then
        return
    end
    local tNeedClearIndex = {}
    for i = 1, MAX_PLAN do
        local tBrushID = HomelandCustomBrushData.tFlowerBrushConfig[i].tBrushID
        local tBrushPer = HomelandCustomBrushData.tFlowerBrushConfig[i].tBrushPer
        local bNeedClear = false
        for j = 1, MAX_ITEM do
            for k = j + 1, MAX_ITEM do
                if tBrushID[j] == tBrushID[k] then
                    bNeedClear = true
                    break
                end
            end
            if not (tBrushID[j] > 0 and (not bNeedClear) and pHLMgr.GetFoliageBrush(tBrushID[j])) then
                bNeedClear = true
            end
        end
        if bNeedClear then
            table.insert(tNeedClearIndex, i)
        end
    end
    local nBrushID = HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID
    if not (nBrushID > 0 and pHLMgr.GetFoliageBrush(nBrushID)) then
        HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID = 0
    end

    for i = 1, #tNeedClearIndex do
        local nIndex = tNeedClearIndex[i]
        local tBrushID = HomelandCustomBrushData.tFlowerBrushConfig[nIndex].tBrushID
        local tBrushPer = HomelandCustomBrushData.tFlowerBrushConfig[nIndex].tBrushPer
        for j = 1, MAX_ITEM do
            tBrushID[j] = 0
            tBrushPer[j] = 0
        end
    end
    HomelandCustomBrushData.SaveFlowerConfig()
end

function HomelandCustomBrushData.RefreshFloorInfo()
    local tInfo = HLBOp_Amount.GetRawFloorBrushInfo()
    HomelandCustomBrushData.tFloorBrushConfig = {}
    for i = 1, MAX_ITEM do
        local dwFurnitureID = 0
        if tInfo[i] then
            local dwModelID = tInfo[i].nModelID
            if dwModelID > 0 then
                local tLine = FurnitureData.GetFurnInfoByModelID(dwModelID)
                if tLine then
                    dwFurnitureID = tLine.dwFurnitureID
                end
            end
        end

        --nEdge 羽化四档 nStrength 四档
        table.insert(HomelandCustomBrushData.tFloorBrushConfig, {nBrushID = dwFurnitureID, nEdge = 1, nStrength = 1})
    end
    -- nSize 大小三档
    HomelandCustomBrushData.tFloorBrushConfig.nSize = 1
    --Homeland_Log("HomelandCustomBrushData.tFloorBrushPlan", HomelandCustomBrushData.tFloorBrushConfig)
end

function HomelandCustomBrushData.RefreshFlowerEdit(nPlanIndex)
    HomelandCustomBrushData.tFlowerEditInfo.tBrushID = HomelandCustomBrushData.tFlowerBrushConfig[nPlanIndex].tBrushID
    HomelandCustomBrushData.tFlowerEditInfo.tBrushPer = HomelandCustomBrushData.tFlowerBrushConfig[nPlanIndex].tBrushPer
    HomelandCustomBrushData.tFlowerEditInfo.nPlanIndex = nPlanIndex
end

function HomelandCustomBrushData.SaveOnePlan()
    local tEditInfo = HomelandCustomBrushData.tFlowerEditInfo
    if not tEditInfo.bInEdit then
        return
    end
    local tOnePlan = HomelandCustomBrushData.tFlowerBrushConfig[tEditInfo.nPlanIndex]
    for i = 1, MAX_ITEM do
        tOnePlan.tBrushID[i] = tEditInfo.tBrushID[i]
        tOnePlan.tBrushPer[i] = tEditInfo.tBrushPer[i]
    end
    HomelandCustomBrushData.SaveFlowerConfig()
end

function HomelandCustomBrushData.SaveFlowerConfig()
    g_HomelandBuildingData.tFlowerBrushConfig = HomelandCustomBrushData.tFlowerBrushConfig
end

function HomelandCustomBrushData.GetSettingData(nType)
    if nType == SETTING_TYPE.FLOOR_ITEM then
        return HomelandCustomBrushData.tFloorBrushConfig[HomelandCustomBrushData.tSettingInfo.nFloorIndex]
    elseif nType == SETTING_TYPE.FLOOR then
        return HomelandCustomBrushData.tFloorBrushConfig
    elseif nType == SETTING_TYPE.SINGLE_FLOWER then
        return HomelandCustomBrushData.tFlowerBrushConfig.tSingle
    elseif nType == SETTING_TYPE.FLOWER_PLAN then
        return HomelandCustomBrushData.tFlowerBrushConfig[HomelandCustomBrushData.tSettingInfo.nFlowerPlanIndex]
    elseif nType == SETTING_TYPE.FLOOR_ERASER then
        return HomelandCustomBrushData.tSettingInfo.tFloorEraser
    elseif nType == SETTING_TYPE.FLOWER_ERASER then
        return HomelandCustomBrushData.tSettingInfo.tFlowerEraser
    end
end

function HomelandCustomBrushData.UnInit()
    HomelandCustomBrushData.tFloorBrushConfig = nil
    HomelandCustomBrushData.tFlowerBrushConfig = nil
    HomelandCustomBrushData.nInMode = 0
    HomelandCustomBrushData.tFlowerEditInfo = nil
    HomelandCustomBrushData.nChooseType = CHOOSED_BRUSH_TYPE.NULL

    Event.UnRegAll(HomelandCustomBrushData)
end

function HomelandCustomBrushData.RegEvent()
    Event.Reg(self, "HOMELANDBUILDING_ON_CLOSE", function ()
        HomelandCustomBrushData.Close()
    end)

    Event.Reg(self, "LUA_HOMELAND_CREATE_CUSTOM_BRUSH", function ()
        HomelandCustomBrushData.OnPickBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_CANCEL_CUSTOM_BRUSH", function ()

    end)
end

function HomelandCustomBrushData.OnPickBrush()
    local nType = HomelandCustomBrushData.tSettingInfo.nSettingType
    if nType == SETTING_TYPE.NULL then
        return
    end
    local nIndex = nil
    local szControl = tSettingConfig[nType].szControl
    if nType == SETTING_TYPE.FLOOR_ITEM then
        nIndex = HomelandCustomBrushData.tSettingInfo.nFloorIndex
        szControl = szControl .. nIndex
    elseif nType == SETTING_TYPE.FLOWER_PLAN then
        nIndex = HomelandCustomBrushData.tSettingInfo.nFlowerPlanIndex
        szControl = szControl .. nIndex
    end
    -- local hWndBrush = Station.Lookup(szUiTreePath)
    -- local hControl = hWndBrush:Lookup(szControl)
    -- View.ShowSetting(hControl, nType)
    -- if nType == SETTING_TYPE.FLOOR then
    --     View.UpdateFloorFillBtn(true)
    -- end
end

function HomelandCustomBrushData.EnterFlowerBrush()
    HomelandCustomBrushData.Init()
    if HomelandCustomBrushData.nInMode == BRUSH_TYPE.FLOWER then
        return
    end
    HomelandCustomBrushData.CancelBrush()
    -- View.EnterFlowerBrush()
    HomelandCustomBrushData.nInMode = BRUSH_TYPE.FLOWER
end

function HomelandCustomBrushData.EnterFlowerEdit(nPlanIndex)
    HomelandCustomBrushData.CancelBrush()
    -- View.CheckOneEdit(nPlanIndex)
    HomelandCustomBrushData.RefreshFlowerEdit(nPlanIndex)
    HomelandCustomBrushData.tFlowerEditInfo.bInEdit = true
    HomelandCustomBrushData.tFlowerEditInfo.nItemIndex = 1
    -- View.EnterFlowerEdit(nPlanIndex)
    HomelandCustomBrushData.SelectItem(HomelandCustomBrushData.tFlowerEditInfo.tBrushID[HomelandCustomBrushData.tFlowerEditInfo.nItemIndex])
end

function HomelandCustomBrushData.Close()
    HomelandCustomBrushData.CancelBrush()
    HomelandCustomBrushData.nInMode = 0
    HomelandCustomBrushData.UnInit()
end

function HomelandCustomBrushData.ExitFlowerEdit()
    -- View.CheckOneEdit(0)
    HomelandCustomBrushData.SaveOnePlan()
    -- View.ExitFlowerEdit()
    HomelandCustomBrushData.tFlowerEditInfo.bInEdit = false
    HomelandCustomBrushData.SelectItem()
end

function HomelandCustomBrushData.AddOneFlowerEditItem(dwFurnitureID)
    local nItemIndex = HomelandCustomBrushData.tFlowerEditInfo.nItemIndex
    local tBrushID = HomelandCustomBrushData.tFlowerEditInfo.tBrushID
    local tBrushPer = HomelandCustomBrushData.tFlowerEditInfo.tBrushPer

    for i = 1, MAX_ITEM do
        if tBrushID[i] == dwFurnitureID then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH_CAN_NOT_CHOOSE)
            return
        end
    end

    local bIsExist = tBrushID[nItemIndex] ~= 0

    tBrushID[nItemIndex] = dwFurnitureID

    if not bIsExist then
        local nCount = GetFlowerItemCountInPlan(tBrushID)
        for i = 1, MAX_ITEM do
            tBrushPer[i] = tDefaultPer[nCount][i]
        end
    end
    HomelandCustomBrushData.SelectItem(dwFurnitureID)
    -- View.UpdateFlowerItemList()
    Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)

    HomelandCustomBrushData.SaveOnePlan()
end

function HomelandCustomBrushData.DelOneFlowerEditItem(nIndex)
    local tBrushID = HomelandCustomBrushData.tFlowerEditInfo.tBrushID
    local tBrushPer = HomelandCustomBrushData.tFlowerEditInfo.tBrushPer
    tBrushID[nIndex] = 0
    tBrushPer[nIndex] = 0

    for i = 1, MAX_ITEM - 1 do
        if i >= nIndex then
            tBrushID[i] = tBrushID[i + 1]
            tBrushPer[i] = tBrushPer[i + 1]
        end
    end

    tBrushID[MAX_ITEM] = 0
    tBrushPer[MAX_ITEM] = 0

    local nItemIndex = HomelandCustomBrushData.tFlowerEditInfo.nItemIndex
    if nItemIndex - 1 > 0 and tBrushID[nItemIndex - 1] == 0 then
        HomelandCustomBrushData.tFlowerEditInfo.nItemIndex = nItemIndex - 1
    end

    HomelandCustomBrushData.SelectItem(tBrushID[HomelandCustomBrushData.tFlowerEditInfo.nItemIndex])

    local nCount = GetFlowerItemCountInPlan(tBrushID)
    for i = 1, MAX_ITEM do
        tBrushPer[i] = tDefaultPer[nCount][i]
    end
    -- View.UpdateFlowerItemList()
    Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)

    HomelandCustomBrushData.SaveOnePlan()
end

function HomelandCustomBrushData.UpdatePercentage(nIndex, nFlag)
    -- local hWndBrush = Station.Lookup(szUiTreePath)
    -- local hWndEdit = hWndBrush:Lookup("WndContainer_EditFlowerBrush")

    local tBrushPer = HomelandCustomBrushData.tFlowerEditInfo.tBrushPer
    local nTemp1 = tBrushPer[nIndex] + nFlag * STEP
    local nTemp2 = tBrushPer[nIndex + 1] - nFlag * STEP
    if nTemp1 <= 0 or nTemp2 <= 0 then
        return
    end
    tBrushPer[nIndex] = nTemp1
    tBrushPer[nIndex + 1] = nTemp2
    -- View.UpdateFlowerItemList()
    Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)
end

function HomelandCustomBrushData.UseFlowerPlanBrush(nIndex)
    HomelandCustomBrushData.tSettingInfo.nSettingType = SETTING_TYPE.FLOWER_PLAN
    HomelandCustomBrushData.tSettingInfo.nFlowerPlanIndex = nIndex
    HomelandCustomBrushData.CreateBrush()
end

function HomelandCustomBrushData.UseFloorBrush()
    HomelandCustomBrushData.tSettingInfo.nSettingType = SETTING_TYPE.FLOOR
    HomelandCustomBrushData.CreateBrush()
end

function HomelandCustomBrushData.UseSingleFlowerBrush(nBrushID)
    if nBrushID then
        HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID = nBrushID
        Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)
    end
end

function HomelandCustomBrushData.StartSingleFlowerBrush()
    if HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH_BOTTOM_CHOOSE)
        return
    end

    HomelandCustomBrushData.tSettingInfo.nSettingType = SETTING_TYPE.SINGLE_FLOWER
    HomelandCustomBrushData.CreateBrush()
    -- local nSingleFlowerBrushID = HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID
    -- HomelandCustomBrushData.SelectItem(nSingleFlowerBrushID)
end

function HomelandCustomBrushData.EnterFloorBrush()
    HomelandCustomBrushData.Init()
    if HomelandCustomBrushData.nInMode == BRUSH_TYPE.FLOOR then
        return
    end
    HomelandCustomBrushData.CancelBrush()
    HomelandCustomBrushData.RefreshFloorInfo()
    -- View.EnterFloorBrush()
    -- View.UpdateFloorFillBtn(false)
    -- View.CheckFloorEdit(false)
    HomelandCustomBrushData.nInMode = BRUSH_TYPE.FLOOR
end

function HomelandCustomBrushData.EnterFloorEdit()
    HomelandCustomBrushData.CancelBrush()
    HomelandCustomBrushData.tSettingInfo.nFloorIndex = 1
    HomelandCustomBrushData.SelectItem(HomelandCustomBrushData.tFloorBrushConfig[HomelandCustomBrushData.tSettingInfo.nFloorIndex].nBrushID)
    if HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.FLOOR then
        HomelandCustomBrushData.tSettingInfo.nSettingType = HomelandCustomBrushData.SETTING_TYPE.FLOOR_ITEM
        Event.Dispatch(EventType.OnSelectCustomBrushFloorItem, HomelandCustomBrushData.tSettingInfo.nFloorIndex)
    end
end

function HomelandCustomBrushData.ExitFloorEdit()
    HomelandCustomBrushData.tSettingInfo.nFloorIndex = 0
    -- View.CheckFloorEdit(false)
    -- View.ExitFloorEdit()
    -- View.HideSetting()
    HomelandCustomBrushData.SelectItem()
end

function HomelandCustomBrushData.AddOneFloorEditItem(dwFurnitureID)
    local tBrushInfo = HomelandCustomBrushData.tFloorBrushConfig
    local nItemIndex = HomelandCustomBrushData.tSettingInfo.nFloorIndex
    for i = 1, MAX_ITEM do
        if tBrushInfo[i].nBrushID == dwFurnitureID then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_CAN_NOT_CHOOSE)
            return
        end
    end
    local function fnAdd()
        HomelandCustomBrushData.SelectItem(dwFurnitureID)
        tBrushInfo[nItemIndex].nBrushID = dwFurnitureID
        -- View.UpdateFloorItemList()
        Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)
    end
    if tBrushInfo[nItemIndex].nBrushID ~= 0 then
        local scriptDialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_EXCHANGE_CONFIRM, fnAdd)
        scriptDialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_EXCHANGE)
        scriptDialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
    else
        fnAdd()
    end
end

function HomelandCustomBrushData.DelOneFloorEditItem(nIndex)
    local tBrushInfo = HomelandCustomBrushData.tFloorBrushConfig
    tBrushInfo[nIndex].nBrushID = 0

    for i = 1, MAX_ITEM - 1 do
        if i >= nIndex then
            tBrushInfo[i].nBrushID = tBrushInfo[i + 1].nBrushID
        end
    end
    tBrushInfo[MAX_ITEM].nBrushID = 0
    local nItemIndex = HomelandCustomBrushData.tSettingInfo.nFloorIndex
    if nItemIndex - 1 > 0 and tBrushInfo[nItemIndex - 1].nBrushID == 0 then
        HomelandCustomBrushData.tSettingInfo.nFloorIndex = nItemIndex - 1
    end

    if tBrushInfo[HomelandCustomBrushData.tSettingInfo.nFloorIndex] then
        HomelandCustomBrushData.SelectItem(tBrushInfo[HomelandCustomBrushData.tSettingInfo.nFloorIndex].nBrushID)
    end
    -- View.UpdateFloorItemList()
    Event.Dispatch(EventType.OnChangeHomelandBuildCustomBrushData)
end

function HomelandCustomBrushData.SelectItem(nBrushID)
    if nBrushID and nBrushID > 0 then
        -- HLBView_FurnitureList.SetSelectBrush(nBrushID)
    else
        -- HLBView_FurnitureList.DelSelectBrush()
    end
end

function HomelandCustomBrushData.GetHLMgr()
    if not hlMgr then
        hlMgr = GetHomelandMgr()
    end
    return hlMgr
end

function HomelandCustomBrushData.CreateBrush()
    HomelandCustomBrushData.CancelBrush()
    if HomelandCustomBrushData.tSettingInfo.nSettingType == SETTING_TYPE.SINGLE_FLOWER then
        local dwFurnitureID = HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nBrushID
        local nSize = HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nSize == 1 and 2 or 4
        local fDensity = HomelandCustomBrushData.tFlowerBrushConfig.tSingle.nDensity / 10
        local dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, dwFurnitureID)
        local tInfo = {HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH, nSize, fDensity, 1, dwModelID, 1, 0}
        -- View.UpdateSingleFlowerItem(true)
        Homeland_Log("SINGLE_FLOWER", tInfo)
        HLBOp_CustomBrush.CreateFlowerBrush(tInfo)
    elseif HomelandCustomBrushData.tSettingInfo.nSettingType == SETTING_TYPE.FLOWER_PLAN then
        local nIndex = HomelandCustomBrushData.tSettingInfo.nFlowerPlanIndex
        local nSize = HomelandCustomBrushData.tFlowerBrushConfig[nIndex].nSize == 1 and 2 or 4
        local fDensity = HomelandCustomBrushData.tFlowerBrushConfig[nIndex].nDensity / 10
        local tInfo = {HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH, nSize, fDensity, 3}
        for i = 1, MAX_ITEM do
            local dwModelID
            if HomelandCustomBrushData.tFlowerBrushConfig[nIndex].tBrushID[i] > 0 then
                dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, HomelandCustomBrushData.tFlowerBrushConfig[nIndex].tBrushID[i])
            else
                dwModelID = 0
            end
            table.insert(tInfo, dwModelID)
        end
        for i = 1, MAX_ITEM do
            table.insert(tInfo, HomelandCustomBrushData.tFlowerBrushConfig[nIndex].tBrushPer[i] / 100)
        end
        table.insert(tInfo, 0)
        -- View.CheckOnePlan(nIndex)
        Homeland_Log("FLOWER_PLAN", tInfo)
        HLBOp_CustomBrush.CreateFlowerBrush(tInfo)
    elseif HomelandCustomBrushData.tSettingInfo.nSettingType == SETTING_TYPE.FLOWER_ERASER then
        local tInfo = {HOMELAND_BUILD_OP.USE_FOLIAGE_COVER_BRUSH, HomelandCustomBrushData.tSettingInfo.tFlowerEraser.nSize, 1, 1, 100000, 1, 0}
        -- View.CheckFlowerEraser(true)
        Homeland_Log("FLOWER_ERASER", tInfo)
        HLBOp_CustomBrush.CreateFlowerBrush(tInfo)
    elseif HomelandCustomBrushData.tSettingInfo.nSettingType == SETTING_TYPE.FLOOR then
        local nSize = HomelandCustomBrushData.tFloorBrushConfig.nSize - 1
        local tInfo = {HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH, nSize}
        for i = 1, MAX_ITEM do
            local dwModelID
            if HomelandCustomBrushData.tFloorBrushConfig[i].nBrushID > 0 then
                dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, HomelandCustomBrushData.tFloorBrushConfig[i].nBrushID)
            else
                dwModelID = 0
            end
            table.insert(tInfo, dwModelID)
            local fEdge = HomelandCustomBrushData.tFloorBrushConfig[i].nEdge * 0.25
            table.insert(tInfo, fEdge)
            local nStrength = HomelandCustomBrushData.tFloorBrushConfig[i].nStrength
            table.insert(tInfo, nStrength)
        end
        table.insert(tInfo, 0)
        -- View.CheckFloorBrush(true)
        Homeland_Log("FLOOR", tInfo)
        HLBOp_CustomBrush.CreateFloorBrush(tInfo)
    elseif HomelandCustomBrushData.tSettingInfo.nSettingType == SETTING_TYPE.FLOOR_ERASER then
        local nSize = HomelandCustomBrushData.tSettingInfo.tFloorEraser.nSize - 1
        local tInfo = {HOMELAND_BUILD_OP.USE_APPLIQUE_BRUSH, nSize}
        for i = 1, MAX_ITEM do
            local dwModelID
            if HomelandCustomBrushData.tFloorBrushConfig[i].nBrushID > 0 then
                dwModelID = FurnitureData.GetModelIDByTypeAndID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, HomelandCustomBrushData.tFloorBrushConfig[i].nBrushID)
            else
                dwModelID = 0
            end
            table.insert(tInfo, dwModelID)
            local fEdge = HomelandCustomBrushData.tSettingInfo.tFloorEraser.nEdge * 0.25
            table.insert(tInfo, fEdge)
            local nStrength = -4
            table.insert(tInfo, nStrength)
        end
        table.insert(tInfo, 0)
        -- View.CheckFloorEraser(true)
        Homeland_Log("FLOOR_ERASER", tInfo)
        HLBOp_CustomBrush.CreateFloorBrush(tInfo)
    end
end

function HomelandCustomBrushData.CancelBrush()
    HLBOp_CustomBrush.CancelCustomBrush()
end

function HomelandCustomBrushData.SelectOneFlowerBrush(dwFurnitureID)
    if not HomelandCustomBrushData.tFlowerEditInfo.bInEdit then
        HomelandCustomBrushData.UseSingleFlowerBrush(dwFurnitureID)
        return
    end
    HomelandCustomBrushData.AddOneFlowerEditItem(dwFurnitureID)
end

function HomelandCustomBrushData.SelectOneFloorBrush(dwFurnitureID)
    if HomelandCustomBrushData.tSettingInfo.nFloorIndex == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CHOOSE_FLOOR_BRUSH)
        return
    end
    HomelandCustomBrushData.AddOneFloorEditItem(dwFurnitureID)
end
