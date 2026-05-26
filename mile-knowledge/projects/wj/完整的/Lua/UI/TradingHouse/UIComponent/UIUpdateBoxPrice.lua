-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIUpdateBoxPrice
-- Date: 2023-03-29 20:02:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIUpdateBoxPrice = class("UIUpdateBoxPrice")

function UIUpdateBoxPrice:OnEnter(nMoney, szTitle, funcPriceChangeCallBack, nMaxPrice, funcOverPrice, bUpdateInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nMoney = nMoney
    self.szTitle = szTitle
    self.funcPriceChangeCallBack = funcPriceChangeCallBack
    self.nMaxPrice = nMaxPrice
    self.funcOverPrice = funcOverPrice--输入价格大于最大价格时的回调

    if bUpdateInfo == nil then
        bUpdateInfo = true
    end

    if bUpdateInfo then
        self:UpdateInfo()
    end
end

function UIUpdateBoxPrice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIUpdateBoxPrice:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxZhuan, function()
            self:OnEditBoxEnded()
        end)
        UIHelper.RegisterEditBoxEnded(self.EditBoxJin, function()
            self:OnEditBoxEnded()
        end)
        UIHelper.RegisterEditBoxEnded(self.EditBoxYin, function()
            self:OnEditBoxEnded()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxZhuan, function()
            self:OnEditBoxEnded()
        end)
        UIHelper.RegisterEditBoxReturn(self.EditBoxJin, function()
            self:OnEditBoxEnded()
        end)
        UIHelper.RegisterEditBoxReturn(self.EditBoxYin, function()
            self:OnEditBoxEnded()
        end)
    end
end

function UIUpdateBoxPrice:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBoxZhuan then
            self:OnEditBoxEnded()
        elseif editbox == self.EditBoxJin then
            self:OnEditBoxEnded()
        elseif editbox == self.EditBoxYin then
            self:OnEditBoxEnded()
        end
    end)
end

function UIUpdateBoxPrice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIUpdateBoxPrice:OnEditBoxEnded()
    if self.funcPriceChangeCallBack then
        local nMoney = self:GetNMoney()
        local nBullion, nGold, nSilver = self:GetTBMoney()
        if self.nMaxPrice and nMoney >= self.nMaxPrice then
            self:UpdatePrice(self.nMaxPrice)
            nBullion, nGold, nSilver = self:GetTBMoney()
            nMoney = self:GetNMoney()
            if self.funcOverPrice then
                self.funcOverPrice()
            end
        end
        self.funcPriceChangeCallBack(nBullion, nGold, nSilver, nMoney)
    end
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIUpdateBoxPrice:UpdatePrice(nMoney)
    self.nMoney = nMoney
    self:UpdateInfo()
end

function UIUpdateBoxPrice:UpdateInfo()

    if self.Title and self.szTitle then
        UIHelper.SetString(self.Title, self.szTitle)
    end
    -- local nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(self.nMoney)
    local nBullion, nGold, nSilver, nCopper = UIHelper.MoneyToBullionGoldSilverAndCopper(self.nMoney)
    self:SaveOriginData(nBullion, nGold, nSilver, nCopper)
    UIHelper.SetText(self.EditBoxZhuan, nBullion)
    UIHelper.SetText(self.EditBoxJin, nGold)
    UIHelper.SetText(self.EditBoxYin, nSilver)
    UIHelper.CascadeDoLayoutDoWidget(self.Layout)
end

function UIUpdateBoxPrice:GetTBMoney()
    local szBullion = self.EditBoxZhuan and UIHelper.GetText(self.EditBoxZhuan) or ""
    local szGold = self.EditBoxJin and UIHelper.GetText(self.EditBoxJin) or ""
    local szSilver = self.EditBoxYin and UIHelper.GetText(self.EditBoxYin) or ""

    local nBullion = szBullion ~= "" and tonumber(szBullion) or (self.EditBoxZhuan and 0 or self.nBullion)
    local nGold = szGold ~= "" and tonumber(szGold) or (self.EditBoxJin and 0 or self.nGold)
    local nSilver = szSilver ~= "" and tonumber(szSilver) or (self.EditBoxYin and 0 or self.nSilver)
    return nBullion, nGold, nSilver
end

function UIUpdateBoxPrice:GetNMoney()
    local nBullion, nGold, nSilver = self:GetTBMoney()
    return UIHelper.BullionGoldSilverAndCopperToMoney(nBullion, nGold, nSilver, self.nCopper)
end

function UIUpdateBoxPrice:SaveOriginData(nBullion, nGold, nSilver, nCopper)
    self.nBullion = nBullion
    self.nGold = nGold
    self.nSilver = nSilver
    self.nCopper = nCopper
end

return UIUpdateBoxPrice