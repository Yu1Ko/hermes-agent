-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamVoicePop
-- Date: 2023-09-25 14:38:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamVoicePop = class("UITeamVoicePop")

function UITeamVoicePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetTouchDownHideTips(self.BtnMask, false)
    UIHelper.SetTouchDownHideTips(self.TogMicSpeaker, false)
    UIHelper.SetTouchDownHideTips(self.TogSpeaker, false)
    UIHelper.SetTouchDownHideTips(self.TogClose, false)

    UIHelper.ToggleGroupRemoveToggle(self._rootNode, self.TogMicSpeaker)
    UIHelper.ToggleGroupRemoveToggle(self._rootNode, self.TogSpeaker)
    UIHelper.ToggleGroupRemoveToggle(self._rootNode, self.TogClose)

    UIHelper.ToggleGroupAddToggle(self._rootNode, self.TogMicSpeaker)
    UIHelper.ToggleGroupAddToggle(self._rootNode, self.TogSpeaker)
    UIHelper.ToggleGroupAddToggle(self._rootNode, self.TogClose)

    self:UpdateInfo()
end

function UITeamVoicePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamVoicePop:BindUIEvent()
    UIHelper.BindUIEvent(self.TogMicSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerAndMic()
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetVoiceTips)
        end
    end)

    UIHelper.BindUIEvent(self.TogSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerCloseMic()
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetVoiceTips)
        end
    end)

    UIHelper.BindUIEvent(self.TogClose, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.CloseSpeakerAndMic()
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetVoiceTips)
        end
    end)
end

function UITeamVoicePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamVoicePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamVoicePop:UpdateInfo()
    if GVoiceMgr.IsOpenSpeakerAndMic() then
        UIHelper.SetToggleGroupSelectedToggle(self._rootNode, self.TogMicSpeaker)
    elseif GVoiceMgr.IsOpenSpeakerCloseMic()then
        UIHelper.SetToggleGroupSelectedToggle(self._rootNode, self.TogSpeaker)
    elseif GVoiceMgr.IsCloseSpeakerAndMic() then
        UIHelper.SetToggleGroupSelectedToggle(self._rootNode, self.TogClose)
    end
end


return UITeamVoicePop