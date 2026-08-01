-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoSettlementView
-- Date: 2026-03-05 19:44:16
-- Desc: 扬刀大会-胜利/失败界面 PanelYangDaoSettlement
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoSettlementView = class("UIPanelYangDaoSettlementView")

-- nResult: ArenaTowerSettleResult
function UIPanelYangDaoSettlementView:OnEnter(nResult, fnCallback, nDiffMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nResult = nResult
    self.fnCallback = fnCallback
    self.nDiffMode = nDiffMode
    self:UpdateInfo()
end

function UIPanelYangDaoSettlementView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoSettlementView:BindUIEvent()

end

function UIPanelYangDaoSettlementView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelYangDaoSettlementView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoSettlementView:UpdateInfo()
    local nDuration = self.nResult == ArenaTowerSettleResult.DefeatAndLevelDown and 4.5 or 3
    UIHelper.SetVisible(self.WidgetVictory, self.nResult == ArenaTowerSettleResult.Victory)
    UIHelper.SetVisible(self.WidgetDefeat, self.nResult == ArenaTowerSettleResult.Defeat)
    UIHelper.SetVisible(self.WidgetLevelDown, self.nResult == ArenaTowerSettleResult.DefeatAndLevelDown)
    UIHelper.SetVisible(self.WidgetCleared, self.nResult == ArenaTowerSettleResult.AllClear)

    UIHelper.SetVisible(self.WidgetPractice, self.nDiffMode == ArenaTowerDiffMode.Practice)
    UIHelper.SetVisible(self.WidgetChallenge, self.nDiffMode == ArenaTowerDiffMode.Challenge)

    Timer.DelAllTimer(self)
    self.nTimerID = Timer.Add(self, nDuration, function()
        UIMgr.Close(self)
        if self.fnCallback then
            self.fnCallback()
        end
    end)
end


return UIPanelYangDaoSettlementView