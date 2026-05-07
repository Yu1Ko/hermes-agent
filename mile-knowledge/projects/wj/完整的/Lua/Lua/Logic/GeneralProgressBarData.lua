-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: GeneralProgressBarData
-- Date: 2023-05-08 11:07:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

GeneralProgressBarData = GeneralProgressBarData or {className = "GeneralProgressBarData"}
local self = GeneralProgressBarData
-------------------------------- 消息定义 --------------------------------
GeneralProgressBarData.Event = {}
GeneralProgressBarData.Event.XXX = "GeneralProgressBarData.Msg.XXX"

local tbProgressBar = {}

function GeneralProgressBarData.Init()
    self._registerEvent()
end

function GeneralProgressBarData.UnInit()

end

function GeneralProgressBarData.OnLogin()

end

function GeneralProgressBarData.OnFirstLoadEnd()

end

function GeneralProgressBarData.AddProgressBar(szName, nID, szTitle, szDiscrible, nMolecular, nDenominator, nTime)
    local tbInfo, nIndex = self.GetProgressBarInfoByName(szName)

    if not tbInfo then
        tbInfo = {}
        table.insert(tbProgressBar, tbInfo)
    end

    tbInfo.szName = szName
    tbInfo.nID = nID
    tbInfo.szTitle = szTitle
    tbInfo.szDiscrible = szDiscrible
    tbInfo.nMolecular = nMolecular
    tbInfo.nDenominator = nDenominator
    tbInfo.nTime = nTime

    if nTime then
        local nCurrentTime = GetCurrentTime()
		tbInfo.nEndTime = nTime + nCurrentTime
		tbInfo.nStartTime = nCurrentTime
    end

    local tbLine = Table_GetProgressBar(nID)
    tbInfo.tbLine = tbLine
    tbInfo.nWay = tbLine.nWay
    tbInfo.szTip = tbLine.szTip

    Event.Dispatch(EventType.On_Update_GeneralProgressBar, tbInfo)
end

function GeneralProgressBarData.UpdateProgressBar(szName, nID)

    local tbInfo, nIndex = self.GetProgressBarInfoByName(szName)

    local tbLine = Table_GetProgressBar(nID)
    tbInfo.tbLine = tbLine
    tbInfo.nWay = tbLine.nWay or tbInfo.nWay
    tbInfo.szTip = tbLine.szTip

    Event.Dispatch(EventType.On_Update_GeneralProgressBar, tbInfo)
end

function GeneralProgressBarData.DeleteProgressBar(szName)
    local tbInfo, nIndex = self.GetProgressBarInfoByName(szName)
    table.remove(tbProgressBar, nIndex)
    Event.Dispatch(EventType.On_Delete_GeneralProgressBar, szName)
end

function GeneralProgressBarData.GetProgresBarList()
    return tbProgressBar
end

function GeneralProgressBarData.GetProgressBarInfoByName(szName)
    for nIndex, tbInfo in ipairs(tbProgressBar) do
        if tbInfo.szName == szName then
            return tbInfo, nIndex
        end
    end
    return nil, 0
end

function GeneralProgressBarData.ClearProgressBar()
    for nIndex, tbInfo in ipairs(tbProgressBar) do
        Event.Dispatch(EventType.On_Delete_GeneralProgressBar, tbInfo.szName)
    end
    tbProgressBar = {}
end

function GeneralProgressBarData.GetStringValue(tbInfo)
    local nWay = tbInfo.nWay
	local nMolecular = tbInfo.nMolecular
	local nDenominator = tbInfo.nDenominator
	if nWay == 1 then
        local fProportion = nMolecular / nDenominator
        return math.floor(fProportion * 100) .. "%"
   	elseif nWay == 2 then
        return nMolecular .. "/" .. nDenominator
   	elseif nWay == 3 then
   		return ""
	elseif nWay == 4 then
        return tostring(nMolecular)
   	end
end

function GeneralProgressBarData._registerEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function() --退出浪客行场景清空进度条
        GeneralProgressBarData.ClearProgressBar()
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if tbInfo.szName == "tianyimiyao" then
            local tParam = {
                szType = "Normal",                                           -- 类型: Normal/Skill
                szFormat = UIHelper.GBKToUTF8(tbInfo.szDiscrible), -- 格式化显示文本
                nDuration = tbInfo.nTime / 1000,                          -- 持续时长, 单位为秒
                bReverse = true,
            }
            TipsHelper.PlayProgressBar(tParam)
        end
    end)
end