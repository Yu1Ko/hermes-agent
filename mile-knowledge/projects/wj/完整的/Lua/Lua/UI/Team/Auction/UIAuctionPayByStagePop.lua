-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionPayByStagePop
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionPayByStagePop = class("UIAuctionPayByStagePop")

local MIN_PAY_GOLD = 500000
function UIAuctionPayByStagePop:OnEnter(tParam)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tParam = tParam
    self:UpdateInfo(tParam)
    self:RefreshButtons()
end

function UIAuctionPayByStagePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAuctionPayByStagePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        self.nZhuan = 0
        self.nGold = 0
        self:RefreshButtons()
    end)

    UIHelper.BindUIEvent(self.BtnPay, EventType.OnClick, function ()
        self.nZhuan = self.nZhuan or 0
        self.nGold = self.nGold or 0
        local nTotalGold = self.nZhuan * 10000 + self.nGold
        local teamBidMgr = GetTeamBiddingMgr()
        local nRetCode = teamBidMgr.CanRiseMoney(self.tParam.nBidInfoIndex, nTotalGold)
        if nRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
			teamBidMgr.RiseMoney(self.tParam.nBidInfoIndex, nTotalGold)
            UIMgr.Close(self)
		else
            TipsHelper.ShowNormalTip(g_tStrings.GOLD_TEAM_BID_ITEM_FAIL, false)
		end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxZhuan, function ()
        local szZhuan = UIHelper.GetText(self.EditBoxZhuan)
        self.nZhuan = tonumber(szZhuan) or 0
        self:RefreshButtons()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxGold, function ()
        local szGold = UIHelper.GetText(self.EditBoxGold)
        self.nGold = tonumber(szGold) or 0
        self:RefreshButtons()
    end)
end

function UIAuctionPayByStagePop:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditBoxZhuan then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxZhuan, 0, 9999)
        elseif editbox == self.EditBoxGold then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxGold, 0, 9999)
        end        
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBoxZhuan then
            local szZhuan = UIHelper.GetText(self.EditBoxZhuan)
            self.nZhuan = tonumber(szZhuan) or 0
            self:RefreshButtons()
        elseif editbox == self.EditBoxGold then
            local szGold = UIHelper.GetText(self.EditBoxGold)
            self.nGold = tonumber(szGold) or 0
            self:RefreshButtons()
        end
    end)
end

function UIAuctionPayByStagePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAuctionPayByStagePop:UpdateInfo(tParam)    
    local nRemainZhuan = math.floor(tParam.nTotalGold / 10000)
    local nRemainGold = tParam.nTotalGold - nRemainZhuan * 10000

    UIHelper.SetString(self.LabelZhuan, nRemainZhuan)
    UIHelper.SetString(self.LabelGold, nRemainGold)
end

function UIAuctionPayByStagePop:RefreshButtons()
    self.nZhuan = self.nZhuan or 0
    self.nGold = self.nGold or 0
    local nTotalGold = self.nZhuan * 10000 + self.nGold
    if nTotalGold > self.tParam.nTotalGold then
        nTotalGold = self.tParam.nTotalGold
        self.nZhuan = math.floor(nTotalGold / 10000)
        self.nGold = nTotalGold - self.nZhuan * 10000        
    end
    UIHelper.SetText(self.EditBoxZhuan, self.nZhuan)
    UIHelper.SetText(self.EditBoxGold, self.nGold)
    if nTotalGold < MIN_PAY_GOLD then
        UIHelper.SetButtonState(self.BtnPay, BTN_STATE.Disable, "请输入足够的扣款数额")
    else
        UIHelper.SetButtonState(self.BtnPay, BTN_STATE.Normal)
    end

    UIHelper.SetVisible(self.BtnReset, self.nZhuan > 0 or self.nGold > 0)
    UIHelper.LayoutDoLayout(self.LayoutBtns)
end

return UIAuctionPayByStagePop