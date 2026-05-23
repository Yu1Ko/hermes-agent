-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICycleProgressBar
-- Date: 2022-12-28 21:11:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICycleProgressBar = class("UICycleProgressBar")

function UICycleProgressBar:OnEnter(tParam, nRefCount)
    if not self.bInit then
        self:RegEvent()        
        self:BindUIEvent()
        self.bInit = true
        self.nRefCount = 0
    end
    self:Init(tParam)
    if nRefCount then
        self.nMaxRefCount = nRefCount
        self.nRefCount = nRefCount
    end

    self.nCycleTimeID = self.nCycleTimeID or Timer.AddFrameCycle(self, 1, function ()
        self:OnFrameBreathe()
    end)
end

function UICycleProgressBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICycleProgressBar:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        if self.tDataOfProgressBar and self.tDataOfProgressBar.fnCancel then
            self.tDataOfProgressBar.fnCancel()
        end
        self:StopProgressBar(false)
    end)
end

function UICycleProgressBar:RegEvent()
    Event.Reg(self, "DO_SKILL_HOARD_SUCCESS", function()
        self:StopProgressBar(false)
    end)

    Event.Reg(self, "OT_ACTION_PROGRESS_BREAK", function()
        if arg0 ~= GetClientPlayer().dwID then return end
        self:StopProgressBar(false)
    end)
end

function UICycleProgressBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICycleProgressBar:OnFrameBreathe()
    if self.dwFadeOutFrame and self.dwFadeOutFrame < GetTickCount() then
        if not self.tDataOfProgressBar then
            UIMgr.Close(VIEW_ID.PanelCycleProgressBar)
        else
            self:StopProgressBar(false)
        end
    end
end

function UICycleProgressBar:Init(tParam)
    local tData = {}
    self.dwFadeOutFrame = nil
    self.tParam = tParam
    tData.fnStop = tParam.fnStop
    tData.fnCancel = tParam.fnCancel
    tData.nStartTime = tParam.nStartTime or Timer.RealtimeSinceStartup()
    tData.nEndTime = tData.nStartTime + tParam.nDuration

    self.tDataOfProgressBar = tData
    tData.nCallId = tData.nCallId or Timer.AddFrameCycle(self, 1, function ()        
        local tData = self.tDataOfProgressBar 
        if tData then
            if tData.bCompleted then
                self:StopProgressBar(true)
            else
                self:UpdateProgressBar(self.tParam, tData)
            end
        end
    end)

    local bHasItem = not (not tParam.dwTabType or not tParam.dwIndex)    
    UIHelper.SetVisible(self.WidgetItem, bHasItem)
    if bHasItem then
        self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.scriptItem:OnInitWithTabID(tParam.dwTabType, tParam.dwIndex)        
    end
    UIHelper.SetProgressBarStarPercentPt(self.ImgNormalProgress, 0, 0)
    UIHelper.SetProgressBarPercent(self.ImgNormalProgress, 0)
    if tParam.bTouchClose then
        self.TryBackGroundTouchClose = function ()
            return false
        end
    end
end

function UICycleProgressBar:UpdateProgressBar(tParam, tData)
    local now = Timer.RealtimeSinceStartup()
    local nPercent, nVal
    local nCostTime = now - tData.nStartTime
    if nCostTime > tParam.nDuration then nCostTime = tParam.nDuration end
    if now >= tData.nEndTime then
        -- 结束
        tData.bCompleted = true
        nPercent = 1
        if tParam.nEndVal then
            nVal = tParam.nEndVal
        end
    else        
        nPercent = nCostTime / tParam.nDuration
        if tParam.nStartVal and tParam.nEndVal then
            nVal = tParam.nStartVal + math.floor((tParam.nEndVal - tParam.nStartVal) * nPercent)
        end
    end
        
    UIHelper.SetProgressBarPercent(self.ImgNormalProgress, nPercent * 50)
    UIHelper.SetString(self.LabelProgressName, 
        nVal and string.format(tParam.szFormat, nVal, tParam.nEndVal) or tParam.szFormat)

    local szTitle = tParam.szTitle or ""
    local nFinishCount = self.nMaxRefCount - self.nRefCount
    local szTime = string.format("%s(%d/%d)...(%.2f/%.2f)", szTitle, nFinishCount, self.nMaxRefCount, nCostTime, tParam.nDuration)
    UIHelper.SetString(self.LabelTime, szTime)

    UIHelper.SetVisible(self.ImgIcon, false)
    if tParam.szIconPath then
        UIHelper.SetVisible(self.ImgIcon, true)
        UIHelper.SetSpriteFrame(self.ImgIcon, tParam.szIconPath)
    end
end

function UICycleProgressBar:StopProgressBar(bSuccess)
    local tData = self.tDataOfProgressBar
    if not tData then return end
    self.tDataOfProgressBar = nil

    if tData.nCallId then
        Timer.DelTimer(self, tData.nCallId)
        tData.nCallId = nil
    end

    if tData.fnStop then
        tData.fnStop(tData.bCompleted == true)
    end

    if bSuccess then
        self.nRefCount = self.nRefCount - 1
        self.dwFadeOutFrame = GetTickCount() + 800
    end

    if not bSuccess or self.nRefCount <= 0 then
        UIMgr.Close(VIEW_ID.PanelCycleProgressBar)
    end
end


return UICycleProgressBar