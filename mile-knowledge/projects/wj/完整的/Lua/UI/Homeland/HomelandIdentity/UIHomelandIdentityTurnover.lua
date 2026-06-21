-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityTurnover
-- Date: 2024-01-18 20:14:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityTurnover = class("UIHomelandIdentityTurnover")

function UIHomelandIdentityTurnover:OnEnter(bOnlyShowTotal)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOnlyShowTotal = bOnlyShowTotal or false
    self:UpdateInfo()
end

function UIHomelandIdentityTurnover:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityTurnover:BindUIEvent()
    
end

function UIHomelandIdentityTurnover:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityTurnover:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityTurnover:UpdateInfo()
    local dwPlayerID = UI_GetClientPlayerID()
    local nTotalMoney = GDAPI_GetTotalTurnover(dwPlayerID)
    local nWeekMoney = GDAPI_GetTurnover(dwPlayerID)

    local tbTotalMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nTotalMoney)}
    local tbWeekMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nWeekMoney)}
    for i = 1, 3, 1 do
        UIHelper.SetString(self.tbTotalMoneyLabel[i], tbTotalMoney[i])
        UIHelper.SetString(self.tbWeekMoneyLabel[i], tbWeekMoney[i])
    end

    if self.bOnlyShowTotal then
        UIHelper.SetVisible(self.WidgetWeekRurnoverNum, false)
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end


return UIHomelandIdentityTurnover