-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetLingXueMonitor
-- Date: 2025-08-27 14:44:48
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nCycleTime = 1/ 8
local UIWidgetLingXueMonitor = class("UIWidgetLingXueMonitor")

function UIWidgetLingXueMonitor:OnEnter(bCustom)
    if bCustom then
        UIHelper.SetActiveAndCache(self, self._rootNode, true)
    else
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
        end
        self.tCellList = {}
        for i = 1, 2 do
            table.insert(self.tCellList, UIHelper.GetBindScript(self.tbPlayerNode[i]))
        end
        UIHelper.SetActiveAndCache(self, self._rootNode, false)
    end

end

function UIWidgetLingXueMonitor:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetLingXueMonitor:BindUIEvent()
    
end

function UIWidgetLingXueMonitor:RegEvent()
    Event.Reg(self, "RefreshAllMonitorTarget", function(tMonitorList)
        self.m_tMonitorList = tMonitorList
        self:RefreshAllMonitorTarget()
        print("RefreshAllMonitorTarget")
    end)
end

function UIWidgetLingXueMonitor:UnRegEvent()
   
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLingXueMonitor:RefreshAllMonitorTarget()
    local bFlag = false
    for i = 1, 2 do
        local script = self.tCellList[i]
        local tInfo = self.m_tMonitorList[i]
        if tInfo then
            local szName = UIHelper.GBKToUTF8(tInfo.szSrcName)
            szName = UIHelper.LimitUtf8Len(szName, 6)
            local szImgPath = BuffMonitorForceBase.GetImagePath(tInfo.dwFullyType, tInfo.hSrcTarget, tInfo.nSrcTargetID)
            UIHelper.SetSpriteFrame(script.ImgPlayer, szImgPath)
            UIHelper.SetLabel(script.LabelPlayerName, szName)            
            bFlag = true
        end
        script.bVisible = tInfo ~= nil
        UIHelper.SetActiveAndCache(self, script._rootNode, script.bVisible)
    end

    UIHelper.SetActiveAndCache(self, self._rootNode, bFlag)
    UIHelper.LayoutDoLayout(self.LayoutLingXueBuff)

    Timer.DelAllTimer(self)
    if bFlag then
        self:RefreshTime()
        Timer.AddCycle(self, nCycleTime, function()
            self:RefreshTime()
        end)
    end
end

function UIWidgetLingXueMonitor:RefreshTime()
    local bNeeUpdateList, nListSize = BuffMonitorForceBase.CheckList()

    if bNeeUpdateList then
        self:RefreshAllMonitorTarget()
        return
    end

    if not self.m_tMonitorList then
        return
    end

    for i = 1, 2 do
        local script = self.tCellList[i]
        local tInfo = self.m_tMonitorList[i]
        if script.bVisible and tInfo then
            local fPercentage = tInfo.nLeftFrame / tInfo.nTotalFrame
            local nHour, nMinute, nSecond, nTenthSec = TimeLib.GetTimeToHourMinuteSecondTenthSec(tInfo.nLeftFrame, true)
            local szTimeText = tostring(nHour * 3600 + nMinute * 60 + nSecond) .. '.' .. tostring(nTenthSec)
            UIHelper.SetProgressBarPercent(script.barLingxue, fPercentage * 100)
            UIHelper.SetLabel(script.LabelPlayerCD, szTimeText)
        end
    end
end

return UIWidgetLingXueMonitor