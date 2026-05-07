-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISystemPrograssBar
-- Date: 2022-12-28 21:11:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISystemPrograssBar = class("UISystemPrograssBar")

function UISystemPrograssBar:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:Init(tParam)
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISystemPrograssBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISystemPrograssBar:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        if self.tDataOfProgressBar.fnCancel then
            self.tDataOfProgressBar.fnCancel()
        end
        self:StopProgressBar()
    end)
end

function UISystemPrograssBar:RegEvent()
    Event.Reg(self, "DO_SKILL_HOARD_SUCCESS", function()
        self:StopProgressBar()
    end)

    Event.Reg(self, "OT_ACTION_PROGRESS_BREAK", function(arg0)
        local nPlayerId = arg0
        if g_pClientPlayer and nPlayerId == g_pClientPlayer.dwID then
            self:StopProgressBar()
        end
    end)
end

function UISystemPrograssBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISystemPrograssBar:UpdateInfo()

end

function UISystemPrograssBar:Init(tParam)
    local tData = {}
    tData.fnStop = tParam.fnStop
    tData.fnCancel = tParam.fnCancel
    tData.nStartTime = tParam.nStartTime or Timer.RealtimeSinceStartup()
    tData.nEndTime = tData.nStartTime + tParam.nDuration
    tData.bShowCancel = tParam.bShowCancel == nil and true or tParam.bShowCancel

    if tParam.nSize then
        UIHelper.SetContentSize(self.ImgIcon, tParam.nSize,tParam.nSize)
    end
    
    self.tDataOfProgressBar = tData
    tData.nCallId = Timer.AddFrameCycle(self, 1, function()
        local tData = self.tDataOfProgressBar
        if tData then
            if tData.bCompleted then
                self:StopProgressBar()
            else
                self:UpdateProgressBar(tParam, tData)
            end
        end
    end)

    UIHelper.SetVisible(self.BtnCancel, tData.bShowCancel)

    local bHasItem = not (not tParam.dwTabType or not tParam.dwIndex)
    UIHelper.SetVisible(self.WidgetItem, bHasItem)
    if bHasItem then
        self.scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
        self.scriptItem:OnInitWithTabID(tParam.dwTabType, tParam.dwIndex)
    end

    UIHelper.SetVisible(self.ImgIcon, false)
    if tParam.szIconPath then
        UIHelper.SetVisible(self.ImgIcon, true)
        UIHelper.SetSpriteFrame(self.ImgIcon, tParam.szIconPath)
    end

    UIHelper.SetProgressBarStarPercentPt(self.ImgNormalProgress, 0, 0)
    UIHelper.SetProgressBarPercent(self.ImgNormalProgress, 0)
    if tParam.bTouchClose then
        self.TryBackGroundTouchClose = function()
            return false
        end
    end
end

function UISystemPrograssBar:UpdateProgressBar(tParam, tData)
    local now = Timer.RealtimeSinceStartup()
    local nPercent, nVal, szTime

    if now >= tData.nEndTime then
        -- 结束
        tData.bCompleted = true
        nPercent = 1
        if tParam.nEndVal then
            nVal = tParam.nEndVal
        end
    else
        nPercent = (now - tData.nStartTime) / tParam.nDuration
        if tParam.nStartVal and tParam.nEndVal then
            nVal = tParam.nStartVal + math.floor((tParam.nEndVal - tParam.nStartVal) * nPercent)
        end
    end

    UIHelper.SetProgressBarPercent(self.ImgNormalProgress, nPercent * 50)
    UIHelper.SetString(self.LabelProgressName,
            nVal and string.format(tParam.szFormat, nVal, tParam.nEndVal) or tParam.szFormat)
    if tParam.bNotShowDescribe then
        szTime = string.format("(%.2f/%.2f)", now - tData.nStartTime, tParam.nDuration)
    else
        szTime = string.format("%s...(%.2f/%.2f)", tParam.szLabel or "打开", now - tData.nStartTime, tParam.nDuration)
    end
   
    UIHelper.SetString(self.LabelTime, szTime)
end

function UISystemPrograssBar:StopProgressBar()
    local tData = self.tDataOfProgressBar
    if not tData then
        return
    end
    self.tDataOfProgressBar = nil

    if tData.nCallId then
        Timer.DelTimer(self, tData.nCallId)
        tData.nCallId = nil
    end

    if tData.fnStop then
        tData.fnStop(tData.bCompleted == true)
    end
    UIMgr.Close(VIEW_ID.PanelSystemPrograssBar)
end

return UISystemPrograssBar