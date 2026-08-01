-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetDaoZongPoZhan
-- Date: 2025-07-24 15:00:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nCycleTime = 1 / 8

local UIWidgetDaoZongPoZhan = class("UIWidgetDaoZongPoZhan")

function UIWidgetDaoZongPoZhan:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.m_tMonitorList = nil
        self.nShortcutIndexStart = nil

        self.tCellList = {}
        local nShortcutIndexStart = 120
        for i = 1, 3 do
            local nShortcut = nShortcutIndexStart - 1 + i
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPoZhanCell, self.LayoutDaoZongPoZhan)
            script.nShortcut = nShortcut
            script.nSlotID = i

            local keyScript = UIHelper.GetBindScript(script.WidgetKeyBoardKey)
            keyScript:SetID(nShortcut, nil, true)
            script.keyScript = keyScript

            UIHelper.SetActiveAndCache(self, script._rootNode, false)
            table.insert(self.tCellList, script)

            UIHelper.BindUIEvent(script.BtnClick, EventType.OnClick, function()
                self:SelectCellTarget(script.nSlotID)
            end)
        end
        UIHelper.SetActiveAndCache(self, self.ImgBg, false)
    end
end

function UIWidgetDaoZongPoZhan:BindUIEvent()

end

function UIWidgetDaoZongPoZhan:RegEvent()
    Event.Reg(self, "RefreshAllMonitorTarget", function(tMonitorList)
        self.m_tMonitorList = tMonitorList
        self:RefreshAllMonitorTarget()
        --print("RefreshAllMonitorTarget", #tMonitorList)
    end)

    Event.Reg(self, DX_DAOZONG_EVENT, function(nSlotID)
        self:SelectCellTarget(nSlotID)
    end)
end

function UIWidgetDaoZongPoZhan:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetDaoZongPoZhan:OnExit()

end

function UIWidgetDaoZongPoZhan:RefreshAllMonitorTarget()
    if not self.m_tMonitorList then
        return
    end

    local bFlag = false
    for i = 1, 3 do
        local script = self.tCellList[i]
        local tInfo = self.m_tMonitorList[i]
        if tInfo then
            local tLine = tInfo.tLine
            local szSuffix = tLine.szSuffix
            local szName = UIHelper.GBKToUTF8(tInfo.szSrcName)
            szName = UIHelper.LimitUtf8Len(szName, 4)
            local szImgPath = BuffMonitorForceBase.GetImagePath(tInfo.dwFullyType, tInfo.hSrcTarget, tInfo.nSrcTargetID, szSuffix)
            script.dwFullyType = tInfo.dwFullyType
            script.nSrcTargetID = tInfo.nSrcTargetID
            script.tLine = tLine

            UIHelper.SetSpriteFrame(script.ImgTarget, szImgPath)
            bFlag = true

            ShortcutInteractionData.ChangeSkillShortcutInfo(script.nShortcut, szName, DX_DAOZONG_EVENT .. script.nSlotID)
            script.keyScript:UpdateInfo()
        else
            script.nSrcTargetID = nil
            script.dwFullyType = nil
        end
        script.bVisible = tInfo ~= nil
        UIHelper.SetActiveAndCache(self, script._rootNode, tInfo ~= nil)
    end

    UIHelper.SetActiveAndCache(self, self.ImgBg, bFlag)
    UIHelper.LayoutDoLayout(self.LayoutDaoZongPoZhan)

    Timer.DelAllTimer(self)
    if bFlag then
        self:RefreshTime()
        Timer.AddCycle(self, nCycleTime, function()
            self:RefreshTime()
        end)
    end
end

function UIWidgetDaoZongPoZhan:SelectCellTarget(nSlotID)
    local tInfo = nSlotID and self.tCellList[nSlotID]
    if tInfo then
        local dwFullyType = tInfo.dwFullyType
        local nSrcTargetID = tInfo.nSrcTargetID
        if dwFullyType and nSrcTargetID then
            SetTarget(dwFullyType, nSrcTargetID)
        end
    end
end

function UIWidgetDaoZongPoZhan:RefreshTime()
    local bNeeUpdateList, nListSize = BuffMonitorForceBase.CheckList()

    if bNeeUpdateList then
        self:RefreshAllMonitorTarget()
        return
    end

    if not self.m_tMonitorList then
        return
    end

    for i = 1, 3 do
        local script = self.tCellList[i]
        local tInfo = self.m_tMonitorList[i]
        if script.bVisible then
            local tLine = script.tLine
            local nMaxLevel = tLine.nMaxLevel

            local fPercentage = tInfo.nLeftFrame / tInfo.nTotalFrame * (1 / nMaxLevel) + (tInfo.nStackNum - 1) * (1 / nMaxLevel)
            local nHour, nMinute, nSecond, nTenthSec = TimeLib.GetTimeToHourMinuteSecondTenthSec(tInfo.nLeftFrame, true)
            local szTimeText = tostring(nHour * 3600 + nMinute * 60 + nSecond) .. '.' .. tostring(nTenthSec)
            local nShowNum = tInfo.nStackNum
            UIHelper.SetProgressBarPercent(script.ImgPoZhanBar, fPercentage * 100)
            for i = 1, 4 do
                local tLabel = script.tLabels[i]
                UIHelper.SetActiveAndCache(self, tLabel, nShowNum == i)
                if nShowNum == i then
                    UIHelper.SetLabel(tLabel, szTimeText)
                end
            end
        end
    end
end

return UIWidgetDaoZongPoZhan