-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationCenterData
-- Date: 2026-03-18 16:02:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

-- 运营活动中心，新花萼楼

OperationCenterData = OperationCenterData or {className = "OperationCenterData"}
local self = OperationCenterData
-------------------------------- 消息定义 --------------------------------
local DEFAULT_OPERATION_ID = 16  -- 默认选第一个
local SEASONS_OPERATION_ID = 236 -- 赛季第一次选这个总览

self.tCategoryDef = {
    HuaELou = 1,
}

self.tCategories = {}
self.tOperations = {}
self.tOperationByID = {}
self.tChildOperations = {}
--默认打开签到了
self.nCurOperationID = nil

local function CompareOperationByPriorityAndID(a, b)
    local nAPriority = a.nPriority or 0
    local nBPriority = b.nPriority or 0
    if nAPriority ~= nBPriority then
        return nAPriority < nBPriority
    end

    local nAID = a.dwID or a.nCategoryID or 0
    local nBID = b.dwID or b.nCategoryID or 0
    return nAID < nBID
end

function OperationCenterData.Init()
    self.LoadConfig()

    --新角色默认回到签到
    Event.Reg(self, EventType.OnAccountLogout, function()
        self.nCurOperationID = nil
    end)
end

function OperationCenterData.UnInit()

end

function OperationCenterData.OnLogin()

end

function OperationCenterData.OnFirstLoadEnd()

end

function OperationCenterData.GetCurOperationID()
    if self.nCurOperationID then
        return self.nCurOperationID
    end

    -- 先检查赛季的，赛季第一次先选中这个总览，但是不存盘
    -- ? 这里有个问题，怎么去检查赛季呢？
    local szKeySeason = "OPERATION_CENTER_SEASONS_SHOW"
    if not APIHelper.AccountIsDid(szKeySeason) then
        APIHelper.AccountDo(szKeySeason)
        return SEASONS_OPERATION_ID
    end

    -- 没有就设置成默认的
    self.nCurOperationID = DEFAULT_OPERATION_ID
    return DEFAULT_OPERATION_ID
end

function OperationCenterData.SetCurOperationID(nOperationID)
    if nOperationID and self.nCurOperationID ~= nil then
        self.nCurOperationID = nOperationID
    end
end

function OperationCenterData.LoadConfig()
    self.tCategories = {}
    local tRawCategories = Table_GetOperationCategory() or {}
    for _, v in pairs(tRawCategories) do
        table.insert(self.tCategories, v)
    end
    table.sort(self.tCategories, CompareOperationByPriorityAndID)

    self.tOperations = {}
    self.tOperationByID = {}
    self.tChildOperations = {}

    local tRawOperations = Table_GetOperationActivity() or {}
    for _, v in pairs(tRawOperations) do
        if v.dwID then
            self.tOperationByID[v.dwID] = v
        end

        local nCategoryID = v.nCategoryID or 0
        if not self.tOperations[nCategoryID] then
            self.tOperations[nCategoryID] = {}
        end
        table.insert(self.tOperations[nCategoryID], v)

        -- 收集子活动
        local nParentID = v.dwParentID
        if nParentID and nParentID > 0 then
            if not self.tChildOperations[nParentID] then
                self.tChildOperations[nParentID] = {}
            end
            table.insert(self.tChildOperations[nParentID], v)
        end
    end

    for _, tList in pairs(self.tOperations) do
        table.sort(tList, CompareOperationByPriorityAndID)
    end

    for _, tList in pairs(self.tChildOperations) do
        table.sort(tList, CompareOperationByPriorityAndID)
    end
end

function OperationCenterData.GetCategories()
    if not self.tCategories then
        self.LoadConfig()
    end
    return self.tCategories
end

function OperationCenterData.GetCategoriesByID(nCategoryID)
    local tCategories = self.GetCategories()
    for _, tInfo in ipairs(tCategories) do
        if tInfo.nCategoryID == nCategoryID then
            return tInfo
        end
    end
    return nil
end

function OperationCenterData.GetOperations(nCategoryID)
    if not self.tOperations then
        self.LoadConfig()
    end
    return self.tOperations[nCategoryID] or {}
end

function OperationCenterData.GetOperationInfo(nOperationID)
    if not self.tOperationByID then
        self.LoadConfig()
    end
    return self.tOperationByID[nOperationID]
end

function OperationCenterData.IsOperationInCategory(nOperationID, nCategoryID)
    local tInfo = self.GetOperationInfo(nOperationID)
    return tInfo and tInfo.nCategoryID == nCategoryID
end

-- 判断是否是子活动（有dwParentID）
function OperationCenterData.IsChildOperation(nOperationID)
    local tInfo = self.GetOperationInfo(nOperationID)
    return tInfo and tInfo.dwParentID and tInfo.dwParentID > 0
end

-- 判断是否是父活动（有子活动依赖它）
function OperationCenterData.IsParentOperation(nOperationID)
    if not self.tChildOperations then
        self.LoadConfig()
    end
    local tChildren = self.tChildOperations[nOperationID]
    return tChildren and #tChildren > 0
end

-- 判断两个活动是否是父子关系
function OperationCenterData.IsParentChild(nID1, nID2)
    local tInfo1 = self.GetOperationInfo(nID1)
    local tInfo2 = self.GetOperationInfo(nID2)
    if not tInfo1 or not tInfo2 then
        return false
    end
    return (tInfo1.dwParentID == nID2) or (tInfo2.dwParentID == nID1)
end

-- 获取子活动的父活动信息
function OperationCenterData.GetParentOperation(nOperationID)
    local tInfo = self.GetOperationInfo(nOperationID)
    if tInfo and tInfo.dwParentID and tInfo.dwParentID > 0 then
        return self.GetOperationInfo(tInfo.dwParentID)
    end
    return nil
end

-- 获取指定父活动的所有子活动（配置数据）
function OperationCenterData.GetChildOperations(nParentID)
    if not self.tChildOperations then
        self.LoadConfig()
    end
    return self.tChildOperations[nParentID] or {}
end

-- 当前主界面要显示的活动
self.tOpenOperations = {}
self.tOpenChildOperations = {}

function OperationCenterData.InitOpenOperations()
    HuaELouData.GetAllCheckActive()
    self.tOpenOperations = {}
    self.tOpenChildOperations = {}
    for nCategoryID, tList in pairs(self.tOperations) do
        for _, tInfo in ipairs(tList) do
            local tActivity = TabHelper.GetHuaELouActivityByOperationID(tInfo.dwID)
            if tActivity then
                local bShow = HuaELouData.CheackActivityOpen(tInfo.dwID, tActivity.dwID)
                if bShow then
                    if not self.tOpenOperations[nCategoryID] then
                        self.tOpenOperations[nCategoryID] = {}
                    end
                    table.insert(self.tOpenOperations[nCategoryID], tInfo)
                    -- 收集开放的子活动
                    local nParentID = tInfo.dwParentID
                    if nParentID and nParentID > 0 then
                        if not self.tOpenChildOperations[nParentID] then
                            self.tOpenChildOperations[nParentID] = {}
                        end
                        table.insert(self.tOpenChildOperations[nParentID], tInfo)
                    end
                end
            end
        end
    end
end

function OperationCenterData.GetOpenOperations(nCategoryID)
    return self.tOpenOperations[nCategoryID] or {}
end

-- 获取当前主界面父活动下开放着的子活动
function OperationCenterData.GetOpenChildOperations(nParentID)
    return self.tOpenChildOperations[nParentID] or {}
end

function OperationCenterData.OpenCenterView(nCurOperationID)
    local script = UIMgr.GetViewScript(VIEW_ID.PanelOperationCenter)
    if not script then
        UIMgr.Open(VIEW_ID.PanelOperationCenter, nCurOperationID)
    else
        script:SelectOperation(nCurOperationID)
    end
end

function OperationCenterData.GetViewComponentContext()
    local script = UIMgr.GetViewScript(VIEW_ID.PanelOperationCenter)
    return script and script.tComponentContext or {}
end

function OperationCenterData.IsShowNew(dwID)
    if self.IsParentOperation(dwID) then
        for _, tInfo in ipairs(self.GetOpenChildOperations(dwID)) do
            if self.IsShowNew(tInfo.dwID) then
                return true
            end
        end
        return false
    end
    local tInfo = self.GetOperationInfo(dwID)
    if not tInfo then
        return false
    end
    local nVersion = Storage.OperationCenter.tRedDotVersion[dwID]
    return nVersion ~= tInfo.nRedDotVersion
end

function OperationCenterData.SetClickNew(dwID)
    if self.IsParentOperation(dwID) then
        for _, tInfo in ipairs(self.GetOpenChildOperations(dwID)) do
            self.SetClickNew(tInfo.dwID)
        end
    end
    local tInfo = self.GetOperationInfo(dwID)
    if not tInfo then
        return
    end
    if Storage.OperationCenter.tRedDotVersion[dwID] ~= tInfo.nRedDotVersion then
        Storage.OperationCenter.tRedDotVersion[dwID] = tInfo.nRedDotVersion
        Storage.OperationCenter.Dirty()
        Event.Dispatch(EventType.OnUpdateHuaELouRedPoint)
    end
end

