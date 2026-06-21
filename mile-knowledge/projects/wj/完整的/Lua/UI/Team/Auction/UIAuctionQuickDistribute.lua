-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionQuickDistribute
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionQuickDistribute = class("UIAuctionQuickDistribute")

function UIAuctionQuickDistribute:OnEnter()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    self.nTimerID = self.nTimerID or Timer.AddCycle(self, 1, function ()
        self:OnUpdateTime()
    end)
end

function UIAuctionQuickDistribute:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAuctionQuickDistribute:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnStartAuction, EventType.OnClick, function ()
        if self.fStartAuction then
            self.fStartAuction()
        end
        AuctionData.nQuickAuctionCDEndTime = GetGSCurrentTime() + 2
        self:OnUpdateTime()
    end)

    UIHelper.BindUIEvent(self.BtnDistribute, EventType.OnClick, function ()
        if self.fDistribute then
            self.fDistribute()
        end
    end)

    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function ()
        local szText = "可以批量以0金把下列某一类型的物品全部分配给同一个人\n1.所有剩余材料：\n包括所有未被分配出去的五行石、五彩石、生活技能材料（不包括珍贵材料）等。"..
        "\n2.所有剩余散件：\n包括所有未被分配出去的装备（不包含兑换牌）。\n3.所有剩余物品：\n包括所有未出价的待分配物品。"
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHint, szText)
    end)
end

function UIAuctionQuickDistribute:RegEvent()
    Event.Reg(self, EventType.OnLootInfoChanged, function (tLootInfo)
        self:RefreshButtons()
    end)
end

function UIAuctionQuickDistribute:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAuctionQuickDistribute:UpdateInfo()
    
end

function UIAuctionQuickDistribute:OnUpdateTime()
    if AuctionData.nQuickAuctionCDEndTime then
        local nLeftTime = AuctionData.nQuickAuctionCDEndTime - GetGSCurrentTime()
        if nLeftTime > 0 then
            UIHelper.SetString(self.LabelStartAuction, string.format("一键开拍(%d)", nLeftTime))
            UIHelper.SetButtonState(self.BtnStartAuction, BTN_STATE.Disable, "该操作正在冷却中")
        else
            UIHelper.SetString(self.LabelStartAuction, "一键开拍")
            if nLeftTime < 0 then
                AuctionData.nQuickAuctionCDEndTime = nil
            end
            self:RefreshButtons()
        end
    end
end

function UIAuctionQuickDistribute:SetDistributeCallBack(fDistribute)
    self.fDistribute = fDistribute
end

function UIAuctionQuickDistribute:SetStartAuctionCallBack(fStartAuction)
    self.fStartAuction = fStartAuction
end

function UIAuctionQuickDistribute:SetStartAuctionEnableFunc(fCheckStartAcutionEnable)
    self.fCheckStartAcutionEnable = fCheckStartAcutionEnable
    self:RefreshButtons()
end

function UIAuctionQuickDistribute:RefreshButtons()
    if self.fCheckStartAcutionEnable then
        local bEnable = self.fCheckStartAcutionEnable()
        if bEnable then
            UIHelper.SetButtonState(self.BtnStartAuction, BTN_STATE.Normal)
        else
            UIHelper.SetButtonState(self.BtnStartAuction, BTN_STATE.Disable, "暂无已预设价格且可以拍卖的道具")
        end
    end
end

return UIAuctionQuickDistribute