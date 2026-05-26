local UIInjuryHintView = class("UIInjuryHintView")

function UIInjuryHintView:OnEnter()
    self.nTimerID = self.nTimerID or Timer.AddCycle(self, 1, function ()
        local nPageCount = UIMgr.GetLayerStackLength(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
        local nMBCount = 0 --UIMgr.GetLayerStackLength(UILayer.MessageBox, IGNORE_TEACH_VIEW_IDS)
        local bFight = g_pClientPlayer and g_pClientPlayer.bFightState
        UIHelper.SetVisible(self.WidgetInjuryHint, bFight and (nPageCount > 0 or nMBCount > 0))
    end)
end

function UIInjuryHintView:OnExit()
    Timer.DelAllTimer(self)
end

function UIInjuryHintView:UpdateInfo()

end


return UIInjuryHintView