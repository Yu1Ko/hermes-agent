-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetYaoZongMonitor
-- Date: 2025-08-26 16:56:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetYaoZongMonitor = class("UIWidgetYaoZongMonitor")
local nCycleTime = 1 / 8

local function IsIn33Arena()
    if ArenaData.IsInArena() then
        local nCorpsType = ArenaData.GetBattleArenaType()
        if nCorpsType and nCorpsType == ARENA_UI_TYPE.ARENA_3V3 then --33竞技场默认云剑斧
            return true
        end
    end
end

function UIWidgetYaoZongMonitor:OnEnter(bCustom)
    if bCustom then
        UIHelper.SetVisible(self._rootNode, true)
    else
        self.tbScriptList = {}
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
        end
    end
end

function UIWidgetYaoZongMonitor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYaoZongMonitor:BindUIEvent()
    
end

function UIWidgetYaoZongMonitor:RegEvent()
    Event.Reg(self, "LOADING_END", function ()
        if not IsIn33Arena() then
            UIHelper.SetVisible(self._rootNode, false)
            Timer.DelAllTimer(self)
        end
    end)

    Event.Reg(self, "PARTY_SET_MARK", function ()
        if not IsIn33Arena() then
            self:RefreshAllMonitorTarget()
        end
    end)

    Event.Reg(self, "RefreshAllMonitorTarget", function (tMonitorList)
        self.tMonitorList = tMonitorList
        UIHelper.SetVisible(self._rootNode, true)
        self:RefreshAllMonitorTarget()
    end)
end

function UIWidgetYaoZongMonitor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function SortByTeamMark(tMonitorList)
    for k, v in ipairs(tMonitorList) do
        v.nIndex = k
    end

    local player = GetClientPlayer()
    if not player or not player.IsInParty() then
        return tMonitorList
    end

    for k, v in ipairs(tMonitorList) do
        local nMarkID = GetClientTeam().GetMarkIndex(v.nSrcTargetID) or 0
        v.nMarkID = nMarkID
    end

    local function fnSortMark(a, b)
        if a.nMarkID ~= 0 and b.nMarkID ~= 0 then
            return a.nMarkID < b.nMarkID
        elseif a.nMarkID ~= 0 then
            return true
        elseif b.nMarkID ~= 0 then
            return false
        else
            return a.nIndex < b.nIndex
        end
    end
    table.sort(tMonitorList, fnSortMark)

    if IsIn33Arena() then
        local tMarkList = GetClientTeam().GetTeamMark() or {}
        local function GetTargetByMark(nMarkID)
            for dwID, v in pairs(tMarkList) do
                if nMarkID == v then
                    return dwID
                end
            end
        end

        for i = 1, 3 do
            local tInfo = tMonitorList[i]
            if not tInfo or tInfo.nMarkID ~= i then
                local dwTargetID = GetTargetByMark(i)
                table.insert(tMonitorList, i, {nMarkID = i, nSrcTargetID = dwTargetID, bPlace = true})
            end
        end
    end

    return tMonitorList
end

local function GetTargetName(dwID)
    local hTarget = GetPlayer(dwID)
    local dwFullyType
    if hTarget then
        return hTarget.szName
    else
        hTarget = GetNpc(dwID)
        if hTarget then
            return hTarget.szName
        else
            return ""
        end
    end
end

function UIWidgetYaoZongMonitor:RefreshAllMonitorTarget()
    local tMonitorList = clone(self.tMonitorList)
    tMonitorList = SortByTeamMark(tMonitorList)

    local nMaxNum = BuffMonitorForceBase.GetMaxNum()
    for i, node in ipairs(self.tbCellList) do
        if i > nMaxNum then
            break
        end

        local tbScript = UIHelper.GetBindScript(node)
        tbScript.nIndex = nil
        local tInfo = tMonitorList[i]
        if tInfo then
            UIHelper.SetVisible(node, true)
            UIHelper.SetVisible(tbScript.ImgBarBg, not tInfo.bPlace)
            UIHelper.SetVisible(tbScript.ImgDu, not tInfo.bPlace)
            UIHelper.SetVisible(tbScript.LabelPlayerCD, not tInfo.bPlace)
            UIHelper.SetVisible(tbScript.barYaoZongBuff, not tInfo.bPlace)
            if tInfo.bPlace then    --jjc
                local szIconPath = TeamData.TargetMarkIcon[tInfo.nMarkID]
                UIHelper.SetSpriteFrame(tbScript.ImgPlayer, szIconPath)

                if tInfo.nSrcTargetID then
                    local szName = GetTargetName(tInfo.nSrcTargetID)
                    UIHelper.SetString(tbScript.LabelPlayerName, UIHelper.GBKToUTF8(szName), 4)
                else
                    UIHelper.SetString(tbScript.LabelPlayerName, "暂未标记\n")
                end
            else
                local tLine = tInfo.tLine
                UIHelper.SetString(tbScript.LabelPlayerName, UIHelper.GBKToUTF8(tInfo.szSrcName), 4)
                local szImgPath = BuffMonitorForceBase.GetImagePath(tInfo.dwFullyType, tInfo.hSrcTarget, tInfo.nSrcTargetID, "")
                UIHelper.SetSpriteFrame(tbScript.ImgPlayer, szImgPath)
                UIHelper.SetString(tbScript.LabelDuLevel, tostring(tInfo.nStackNum))
                tbScript.nIndex = tInfo.nIndex
            end
        else
            UIHelper.SetVisible(node, false)
        end
        self.tbScriptList[i] = tbScript
    end

    UIHelper.LayoutDoLayout(self.LayoutYaoZongBuff)

    Timer.DelAllTimer(self)
    self:RefreshTime()
    Timer.AddCycle(self, nCycleTime, function()
        self:RefreshTime()
    end)
end

function UIWidgetYaoZongMonitor:RefreshTime()
    local bNeeUpdateList, nListSize = BuffMonitorForceBase.CheckList()

    if nListSize == 0 and not IsIn33Arena() then
        self.tMonitorList = nil
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    if bNeeUpdateList then
        self:RefreshAllMonitorTarget()
        return
    end

    if not self.tMonitorList then
        return
    end

    for i, node in ipairs(self.tbCellList) do
        local tbScript = self.tbScriptList[i]
        if tbScript.nIndex then
            local tInfo = self.tMonitorList[tbScript.nIndex]
            local nHour, nMinute, nSecond, nTenthSec = TimeLib.GetTimeToHourMinuteSecondTenthSec(tInfo.nLeftFrame, true)
            local szTimeText = tostring(nHour * 3600 + nMinute * 60 + nSecond) .. '.' .. tostring(nTenthSec)
            UIHelper.SetString(tbScript.LabelPlayerCD, szTimeText)
            local fPercentage = tInfo.nLeftFrame / tInfo.nTotalFrame
            UIHelper.SetProgressBarPercent(tbScript.barYaoZongBuff, fPercentage * 100)
        end
    end
end


return UIWidgetYaoZongMonitor