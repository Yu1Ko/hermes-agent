-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPriceListCell
-- Date: 2023-03-13 19:38:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPriceListCell = class("UIWidgetPriceListCell")

function UIWidgetPriceListCell:OnEnter(tbMoney, nCount, nPeople, bSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMoney = tbMoney
    self.nCount = nCount
    self.nPeople = nPeople
    self.bSelect = bSelect
    self:UpdateInfo()
end

function UIWidgetPriceListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPriceListCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, select)
        if select then
            Event.Dispatch(EventType.OnSelectPriceListCell, self.tbMoney)
        end
    end)
end

function UIWidgetPriceListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPriceListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPriceListCell:UpdateInfo()
    local scriptView = UIHelper.GetBindScript(self.WidgetPriceListNormal)
    scriptView:OnEnter(CovertMoneyToCopper(self.tbMoney))
    UIHelper.SetString(self.LabelOnSaleNum, self.nCount)
    UIHelper.SetString(self.LabelSalePeopleNum, self.nPeople..g_tStrings.STR_PERSON)

    local scriptViewSelect = UIHelper.GetBindScript(self.WidgetPriceListSelect)
    scriptViewSelect:OnEnter(CovertMoneyToCopper(self.tbMoney))
    UIHelper.SetString(self.LabelOnSaleNumSelect, self.nCount)
    UIHelper.SetString(self.LabelSalePeopleNumSelect, self.nPeople..g_tStrings.STR_PERSON)

    UIHelper.SetSelected(self._rootNode, self.bSelect)
end


return UIWidgetPriceListCell