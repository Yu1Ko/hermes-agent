-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ActionBarData
-- Date: 2024-01-15 16:29:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

ActionBarData = ActionBarData or {}
local self = ActionBarData
-------------------------------- 消息定义 --------------------------------
ActionBarData.Event = {}
ActionBarData.Event.XXX = "ActionBarData.Msg.XXX"

local tbActionBar = {}

local function ParseVlaueList(szList)	-- x;y;z|
    local tList = {}
    local tResult = SplitString(szList, "|")
    for nIndex, szParam in ipairs(tResult) do
        tList[nIndex] = {}
        for s in string.gmatch(szParam, "%d+") do
            local dwID = tonumber(s)
            if dwID then
                table.insert(tList[nIndex], dwID)
            end
        end
    end
	return tList
end

function ActionBarData.Init()

end

function ActionBarData.UnInit()

end

function ActionBarData.OnLogin()

end

function ActionBarData.OnFirstLoadEnd()
end

function ActionBarData.LoadExtendActionBar(dwIndex)
    local tbInfo = self.GetActionBarInfo(dwIndex)
    if not tbInfo then
        tbInfo = {}
        tbActionBar[dwIndex] = tbInfo
    end
    local szActionBarName = "ActionBar" .. dwIndex ..  "_Page1"
    tbInfo.dwIndex = dwIndex
    tbInfo.szName = szActionBarName
    tbInfo.tbParams = {}
    local nCount, nMobileCount, bMobileShowInPage = Table_GetLocalActionBarData(szActionBarName)
    local bMobile = false
    if nMobileCount > 0 then
        nCount = nMobileCount
        bMobile = true
    end
    if bMobileShowInPage then
        tbInfo.bMobileShowInPage = bMobileShowInPage
    end
    for i = 1, nCount do
        local szParam = Table_GetLocalActionBarParam(szActionBarName, i, bMobile)
        local tbList = ParseVlaueList(szParam)
        table.insert(tbInfo.tbParams, tbList)
    end
    Event.Dispatch(EventType.OnOpenActionBar, clone(tbInfo))
end

function ActionBarData.CloseActionBar(dwIndex)
    tbActionBar[dwIndex] = nil
    Event.Dispatch(EventType.OnCloseActionBar, dwIndex)
end

function ActionBarData.GetActionBarInfo(dwIndex)
    if not dwIndex then return end
    return tbActionBar[dwIndex]
end