-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationSimpleTmplData
-- Date: 2026-04-03 10:46:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

OperationSimpleTmplData = OperationSimpleTmplData or {className = "OperationSimpleTmplData"}
local self = OperationSimpleTmplData
-------------------------------- 消息定义 --------------------------------
OperationSimpleTmplData.Event = {}
OperationSimpleTmplData.Event.XXX = "OperationSimpleTmplData.Msg.XXX"

function OperationSimpleTmplData.InitOperation()
    OperationCenterData.GetSupportedOperationIDs()
end

function OperationSimpleTmplData.CheckID(dwID)
    return table.contain_value(self.GetSupportedOperationIDs(), dwID)
end

function OperationSimpleTmplData.GetSupportedOperationIDs()
    if self.tSupportedOperationIDs then
        return self.tSupportedOperationIDs
    end

    local tSupportedOperationIDs = {}
    for _, tInfo in ipairs(Table_GetOperationActivity() or {}) do
        if tInfo.dwID and tInfo.nOperatMode == OPERACT_MODE.SIMPLE_OPERATION then
            table.insert(tSupportedOperationIDs, tInfo.dwID)
        end
    end

    self.tSupportedOperationIDs = tSupportedOperationIDs
    return self.tSupportedOperationIDs
end

function OperationSimpleTmplData.GetConfig(nOperationID)
    return Table_GetSimpleOperationConfigByID(nOperationID) or Table_GetSimpleOperationConfigByID(0)
end

function OperationSimpleTmplData.GetButtonList(nOperationID)
    local tConfig = self.GetConfig(nOperationID)
    if not tConfig then
        return {}
    end

    local tButtonList = {}
    for nIndex = 1, 3 do
        local szText = tConfig["szBtn" .. nIndex .. "Text"] or ""
        local szLink = tConfig["szBtn" .. nIndex .. "Link"] or ""
        if szText ~= "" then
            table.insert(tButtonList, {
                szText = szText,
                szLink = szLink,
            })
        end
    end
    return tButtonList
end

function OperationSimpleTmplData.ParseReward(szReward)
    if not szReward or szReward == "" then
        return {}
    end

    local tRewardList = {}
    local tRawList = {}
    local szFieldSplit = "_"

    tRawList = SplitString(szReward, ";")

    for _, szItem in ipairs(tRawList) do
        if szItem and szItem ~= "" then
            local tInfo = SplitString(szItem, szFieldSplit)
            if #tInfo >= 3 then
                table.insert(tRewardList, {
                    dwTabType = tonumber(tInfo[1]),
                    dwIndex = tonumber(tInfo[2]),
                    nCount = tonumber(tInfo[3]),
                })
            end
        end
    end

    return tRewardList
end

function OperationSimpleTmplData.GetRewardInfo(nOperationID)
    local tConfig = self.GetConfig(nOperationID)
    local tRewardInfo = {
        szTitle = tConfig and tConfig.szRewardTitle or "",
        szHint = tConfig and tConfig.szRewardTitleDetail or "",
        tRewardList = {},
    }

    if not tConfig or not tConfig.szReward or tConfig.szReward == "" then
        return tRewardInfo
    end

    tRewardInfo.tRewardList = self.ParseReward(tConfig.szReward)
    return tRewardInfo
end
