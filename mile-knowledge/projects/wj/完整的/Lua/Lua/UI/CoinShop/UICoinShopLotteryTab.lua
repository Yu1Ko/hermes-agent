-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryTab
-- Date: 2023-08-16 10:53:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopLotteryTab = class("UICoinShopLotteryTab")

function UICoinShopLotteryTab:OnEnter(fnSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnSelected = fnSelected
end

function UICoinShopLotteryTab:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopLotteryTab:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTab01, EventType.OnSelectChanged, function (_, bSelected)
        if self.fnSelected then
            self.fnSelected(bSelected)
        end
    end)
end

function UICoinShopLotteryTab:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopLotteryTab:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryTab:UpdateInfo()

end


return UICoinShopLotteryTab