-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionQuickRollPoint
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionQuickRollPoint = class("UIAuctionQuickRollPoint")

function UIAuctionQuickRollPoint:OnEnter()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIAuctionQuickRollPoint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAuctionQuickRollPoint:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNeedAll, EventType.OnClick, function ()
        if self.fNeedAll then
            self.fNeedAll()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancelAll, EventType.OnClick, function ()
        if self.fCancelAll then
            self.fCancelAll()
        end
    end)
end

function UIAuctionQuickRollPoint:RegEvent()
    Event.Reg(self, EventType.OnLootInfoChanged, function (tLootInfo)
        self:RefreshButtons()
    end)
end

function UIAuctionQuickRollPoint:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAuctionQuickRollPoint:UpdateInfo()
    
end

function UIAuctionQuickRollPoint:SetNeedAllCallBack(fNeedAll)
    self.fNeedAll = fNeedAll
end

function UIAuctionQuickRollPoint:SetCancelAllCallBack(fCancelAll)
    self.fCancelAll = fCancelAll
end

function UIAuctionQuickRollPoint:SetNeedAllEnableFunc(fCheckNeedAllEnable)
    self.fCheckNeedAllEnable = fCheckNeedAllEnable
    self:RefreshButtons()
end

function UIAuctionQuickRollPoint:SetCancelAllEnableFunc(fCheckCancelAllEnable)
    self.fCheckCancelAllEnable = fCheckCancelAllEnable
    self:RefreshButtons()
end

function UIAuctionQuickRollPoint:RefreshButtons()
    if self.fCheckNeedAllEnable then
        local bEnable = self.fCheckNeedAllEnable()
        if bEnable then
            UIHelper.SetButtonState(self.BtnNeedAll, BTN_STATE.Normal)
        else
            UIHelper.SetButtonState(self.BtnNeedAll, BTN_STATE.Disable, "暂无可需求道具")
        end
    end

    if self.fCheckCancelAllEnable then
        local bEnable = self.fCheckCancelAllEnable()
        if bEnable then
            UIHelper.SetButtonState(self.BtnCancelAll, BTN_STATE.Normal)
        else
            UIHelper.SetButtonState(self.BtnCancelAll, BTN_STATE.Disable, "暂无可放弃道具")
        end
    end
end

return UIAuctionQuickRollPoint