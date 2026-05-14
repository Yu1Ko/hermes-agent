-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionPresetCell
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionPresetCell = class("UIWidgetAuctionPresetCell")

function UIWidgetAuctionPresetCell:OnEnter(tCellInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tCellInfo.szName, tCellInfo.nStartPrice, tCellInfo.nStepPrice)
end

function UIWidgetAuctionPresetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAuctionPresetCell:BindUIEvent()
    UIHelper.RegisterEditBoxEnded(self.EditBoxStartBrick, function ()
        self:OnPriceChanged()
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxStartGold, function ()
        self:OnPriceChanged()
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxStepBrick, function ()
        self:OnPriceChanged()
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxStepGold, function ()
        self:OnPriceChanged()
    end)
end

function UIWidgetAuctionPresetCell:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editbox, num)
        if editbox == self.EditBoxStartBrick or editbox == self.EditBoxStartGold or editbox == self.EditBoxStepBrick or editbox == self.EditBoxStepGold then
            self:OnPriceChanged()
        end
    end)
end

function UIWidgetAuctionPresetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetAuctionPresetCell:UpdateInfo(szName, nStartPrice, nStepPrice)
    self.szName = szName or self.szName
    UIHelper.SetString(self.LabelType, self.szName)
    UIHelper.SetString(self.LabelStartBrick, math.floor(nStartPrice / 10000))
    UIHelper.SetString(self.LabelStartGold,  nStartPrice % 10000)
    UIHelper.SetString(self.LabelStepBrick,  math.floor(nStepPrice / 10000))
    UIHelper.SetString(self.LabelStepGold,   nStepPrice % 10000)
    UIHelper.SetText(self.EditBoxStartBrick, math.floor(nStartPrice / 10000))
    UIHelper.SetText(self.EditBoxStartGold,  nStartPrice % 10000)
    UIHelper.SetText(self.EditBoxStepBrick,  math.floor(nStepPrice / 10000))
    UIHelper.SetText(self.EditBoxStepGold,   nStepPrice % 10000)

    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelStartBrick))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelStepBrick))
end

function UIWidgetAuctionPresetCell:OnPriceChanged()
    local nStartPrice, nStepPrice = self:GetPrice()
    if nStepPrice <= 0 then nStepPrice = 1 end

    self:UpdateInfo(self.szName, nStartPrice, nStepPrice)
end

function UIWidgetAuctionPresetCell:GetPrice()
    local szStartBrick, szStartGold, szStepBrick, szStepGold = UIHelper.GetText(self.EditBoxStartBrick), UIHelper.GetText(self.EditBoxStartGold),
    UIHelper.GetText(self.EditBoxStepBrick), UIHelper.GetText(self.EditBoxStepGold)

    local nStartPrice = (tonumber(szStartBrick) or 0) * 10000 + (tonumber(szStartGold) or 0)
    local nStepPrice = (tonumber(szStepBrick) or 0) * 10000 + (tonumber(szStepGold) or 0)

    return nStartPrice, nStepPrice
end

function UIWidgetAuctionPresetCell:SetEditState(bEdit)
    UIHelper.SetVisible(self.WidgetEdit, bEdit)
    UIHelper.SetVisible(self.WidgetShow, not bEdit)
end

return UIWidgetAuctionPresetCell