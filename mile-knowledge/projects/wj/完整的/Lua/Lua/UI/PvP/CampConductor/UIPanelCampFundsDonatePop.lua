-- ---------------------------------------------------------------------------------
-- Name: UIPanelCampFundsDonatePop
-- Desc: 追加资金弹出框
-- Prefab:PanelCampFundsDonatePop
-- ---------------------------------------------------------------------------------

local UIPanelCampFundsDonatePop = class("UIPanelCampFundsDonatePop")

function UIPanelCampFundsDonatePop:_LuaBindList()
    self.BtnClose          = self.BtnClose

    self.EditBoxJin        = self.EditBoxJin -- 金
    self.EditBoxZhuan      = self.EditBoxZhuan -- 金砖

    self.BtnConfirm        = self.BtnConfirm -- 确认
end

function UIPanelCampFundsDonatePop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelCampFundsDonatePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCampFundsDonatePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local nJin, nZhuan = self:GetMoneyCount()
        if nJin > 0 or nZhuan > 0 then
            RemoteCallToServer("On_Camp_GFAddMoney", nJin + nZhuan * 10000)
        end
		UIMgr.Close(self)
    end)
end

function UIPanelCampFundsDonatePop:RegEvent()

end

function UIPanelCampFundsDonatePop:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCampFundsDonatePop:UpdateInfo()
    self.nHaveMoney = g_pClientPlayer.GetMoney().nGold

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxJin, function()
            self:EditChangeHandle()
        end)

        UIHelper.RegisterEditBoxEnded(self.EditBoxZhuan, function()
            self:EditChangeHandle()
        end)
    else
        UIHelper.RegisterEditBoxEnded(self.EditBoxJin, function()
            self:EditChangeHandle()
        end)

        UIHelper.RegisterEditBoxEnded(self.EditBoxZhuan, function()
            self:EditChangeHandle()
        end)
    end
end

function UIPanelCampFundsDonatePop:GetMoneyCount()
    local szJin = UIHelper.GetText(self.EditBoxJin)
    local szZhuan = UIHelper.GetText(self.EditBoxZhuan)
    local nJin = 0
    local nZhuan = 0
    if szJin ~= "" and szJin ~= nil then
        nJin = tonumber(szJin)
    end
    if szZhuan ~= "" and szZhuan ~= nil then
        nZhuan = tonumber(szZhuan)
    end
    return nJin, nZhuan
end

function UIPanelCampFundsDonatePop:EditChangeHandle()
    local nJin, nZhuan = self:GetMoneyCount()
    local nNowMoney = nJin + nZhuan * 10000
    if nNowMoney > self.nHaveMoney then
        nNowMoney = self.nHaveMoney
        nZhuan = math.modf(nNowMoney / 10000)
        nJin = nNowMoney - nZhuan * 10000
        UIHelper.SetText(self.EditBoxZhuan, nZhuan)
        UIHelper.SetText(self.EditBoxJin, nJin)
    end
end

return UIPanelCampFundsDonatePop