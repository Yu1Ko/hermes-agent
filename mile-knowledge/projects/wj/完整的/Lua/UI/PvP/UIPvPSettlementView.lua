-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPvPSettlementView
-- Date: 2023-01-03 14:32:41
-- Desc: 战场胜利/失败界面 PanelPvPSettlement
-- ---------------------------------------------------------------------------------

local UIPvPSettlementView = class("UIPvPSettlementView")

local nDuration = 3

function UIPvPSettlementView:OnEnter(bWin, fnCompleteCallback, bArena, bNotValid)
    self.bWin = bWin
    self.fnCompleteCallback = fnCompleteCallback
    self.bArena = bArena
    self.bNotValid = bNotValid

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPvPSettlementView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPvPSettlementView:BindUIEvent()
    
end

function UIPvPSettlementView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPvPSettlementView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPvPSettlementView:UpdateInfo()
    local bInValid = self.bArena and self.bNotValid or false
    UIHelper.SetVisible(self.ImgInValid, bInValid) -- 竞技场平局
    UIHelper.SetVisible(self.ImgVictory, self.bWin and not bInValid)
    UIHelper.SetVisible(self.ImgDefeat, not self.bWin and not bInValid)

    --TODO 动画播放相关

    Timer.Add(self, nDuration, function()
        UIMgr.Close(self)
        if self.fnCompleteCallback then
            self.fnCompleteCallback()
        end
    end)
end


return UIPvPSettlementView