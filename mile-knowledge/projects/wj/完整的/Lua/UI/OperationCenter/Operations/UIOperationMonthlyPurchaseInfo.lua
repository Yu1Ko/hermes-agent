-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationMonthlyPurchaseInfo
-- Date: 2026-04-03 10:00:00
-- Desc: 月度充消信息区（消费金额 + 充值时间查询）
-- ---------------------------------------------------------------------------------

local UIOperationMonthlyPurchaseInfo = class("UIOperationMonthlyPurchaseInfo")

function UIOperationMonthlyPurchaseInfo:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tData)
end

function UIOperationMonthlyPurchaseInfo:OnExit()
    self.bInit = false
end

function UIOperationMonthlyPurchaseInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTimeLink, EventType.OnClick, function ()
        UIHelper.OpenWeb(tUrl.Recharge)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSingleTextTips, self.BtnHelp,
            TipsLayoutDir.BOTTOM_RIGHT, "注:充值游戏时间或充值通宝并消费后才能获得充值消耗，单次充值消费金额将四舍五入至整数。")
    end)

    UIHelper.SetVisible(self.BtnTimeLink, false)
end

function UIOperationMonthlyPurchaseInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationMonthlyPurchaseInfo:UpdateInfo(tData)
    if not tData then
        return
    end

    self.nMonthID = tData.nMonthID

    local nMoney = tData.nMoney or 0
    UIHelper.SetString(self.LabelPurchaseConsunption, string.format("充时消费%d元", nMoney))
end

return UIOperationMonthlyPurchaseInfo
