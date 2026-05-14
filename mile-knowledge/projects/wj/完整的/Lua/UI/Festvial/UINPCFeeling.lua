-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINPCFeeling
-- Date: 2024-05-16 20:41:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINPCFeeling = class("UINPCFeeling")

local ACTION_MAX_COUNT = 6

function UINPCFeeling:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue) then
        UIHelper.SetVisible(self._rootNode, false)
    end
    self.tInfo = tInfo

    self:UpdateChapterProgress(tInfo)
    self:UpdateFate(tInfo)
    self:UpdateAction(tInfo)
end

function UINPCFeeling:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UINPCFeeling:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose1, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    for nActionID, v in ipairs(self.tbBtnAction) do
        UIHelper.BindUIEvent(v, EventType.OnClick, function ()
            RemoteCallToServer("On_Biography_XueXueAct", nActionID)
        end)
    end

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelPlotDialogue then
            UIHelper.SetVisible(self._rootNode, true)
        end
    end)
end

function UINPCFeeling:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINPCFeeling:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINPCFeeling:UpdateInfo()

end

function UINPCFeeling:UpdateChapterProgress(tInfo)
    local nChapter = tInfo.nChapter
	local nHappyness = tInfo.nHappyness
	local fPHappyness = nHappyness / tInfo.nHappynessTotal
	local fP = tInfo.nAttraction / tInfo.nAttractionTotal

    UIHelper.SetProgressBarPercent(self.Slider1, fP * 100)
    UIHelper.SetString(self.LabelSpeedNum, nHappyness .. "%")
    UIHelper.SetString(self.LabelBarNumExp1, tInfo.nAttraction .. "/" .. tInfo.nAttractionTotal)
    UIHelper.SetString(self.LabelBarNumExp2, nHappyness)
    UIHelper.SetProgressBarPercent(self.Slider2, fPHappyness * 100)

    for i, v in ipairs(self.tbPlotDone) do
        UIHelper.SetVisible(v, nChapter >= i + 1)
	end
end

function UINPCFeeling:UpdateFate(tInfo)
    local fFateL, fFateR = 0, 0
	if tInfo.nFate > 0 then
		fFateR = tInfo.nFate / tInfo.nFateTotal
	else
		fFateL = -tInfo.nFate / tInfo.nFateTotal
	end
	UIHelper.SetProgressBarPercent(self.SliderYi, fFateL * 100)
	UIHelper.SetProgressBarPercent(self.SliderChen, fFateR * 100)
end

function UINPCFeeling:UpdateAction(tInfo)
    local nUnLockCount = tInfo.nChapter * 2
    for nActionID, v in ipairs(self.tbBtnAction) do
        UIHelper.SetButtonState(v, nActionID > nUnLockCount and BTN_STATE.Disable or BTN_STATE.Normal)
    end
end

return UINPCFeeling