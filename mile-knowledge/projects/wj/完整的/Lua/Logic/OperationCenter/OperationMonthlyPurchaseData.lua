-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationMonthlyPurchaseData
-- Date: 2026-04-09 17:49:45
-- Desc: 月度充消活动数据模块，提供公共数据接口供 UIOperationPublicTitle 等组件调用
-- ---------------------------------------------------------------------------------

OperationMonthlyPurchaseData = OperationMonthlyPurchaseData or {className = "OperationMonthlyPurchaseData"}
local self = OperationMonthlyPurchaseData

local tOperationIDs = {
    OPERACT_ID.CHARGE_MONTHLY,
}

local m_bIsCurrent = true

function OperationMonthlyPurchaseData.InitOperation()
    for _, dwID in ipairs(tOperationIDs) do
        HuaELouData.RegisterProcessor(dwID, self)
    end
end

function OperationMonthlyPurchaseData.CheckID(dwID)
    return table.contain_value(tOperationIDs, dwID)
end

function OperationMonthlyPurchaseData.HasRedPoint(dwID)
    return false
end

function OperationMonthlyPurchaseData.SetIsCurrent(bIsCurrent)
    m_bIsCurrent = bIsCurrent
end

function OperationMonthlyPurchaseData.GetCurrentData()
    local tChongXiaoMon = Table_GetChongXiaoMonthly()
    if not tChongXiaoMon then
        return nil
    end
    local nCurTime = GetCurrentTime()
    for _, tPageInfo in ipairs(tChongXiaoMon) do
        if nCurTime >= tPageInfo[1].nStartTime and nCurTime < tPageInfo[1].nEndTime then
            return tPageInfo[1]
        end
    end
    return nil
end

function OperationMonthlyPurchaseData.GetTimeText()
    local tChongXiaoMon = Table_GetChongXiaoMonthly()
    if not tChongXiaoMon then
        return ""
    end

    -- 找到当期索引
    local nCurTime = GetCurrentTime()
    local nCurPage = 0
    local nDefaultPage = 0
    for nIndex, tPageInfo in ipairs(tChongXiaoMon) do
        if nCurTime >= tPageInfo[1].nStartTime and nCurTime < tPageInfo[1].nEndTime then
            nCurPage = nIndex
            break
        end
        if tPageInfo[1].nEndTime <= nCurTime then
            nDefaultPage = nIndex
        end
    end
    if nCurPage == 0 then
        nCurPage = nDefaultPage
    end

    if m_bIsCurrent then
        local tCurPage = tChongXiaoMon[nCurPage]
        return tCurPage and tCurPage[1] and UIHelper.GBKToUTF8(tCurPage[1].szActivityTime) or ""
    else
        -- 往期 = 当期索引 - 1
        local nPrevPage = nCurPage - 1
        if nPrevPage < 1 then
            nPrevPage = #tChongXiaoMon
        end
        local tPrevPage = tChongXiaoMon[nPrevPage]
        return tPrevPage and tPrevPage[1] and UIHelper.GBKToUTF8(tPrevPage[1].szActivityTime) or ""
    end
end
