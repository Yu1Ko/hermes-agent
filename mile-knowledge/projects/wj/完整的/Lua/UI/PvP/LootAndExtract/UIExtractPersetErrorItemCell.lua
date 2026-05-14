-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetErrorItemCell
-- Date: 2024-01-25 20:59:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractPersetErrorItemCell = class("UIExtractPersetErrorItemCell")

function UIExtractPersetErrorItemCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIExtractPersetErrorItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetErrorItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        if self.fnOnClickCancel then
            self.fnOnClickCancel()
            return
        end

        local nCount = 0
        UIHelper.SetText(self.EditPaginate, nCount)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
        self:UpdateCost()
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local nMaxNum = self.tInfo and self.tInfo[3] or 0
        local nCount = tonumber(UIHelper.GetText(self.EditPaginate)) + 1
        if nCount > nMaxNum then
            nCount = nMaxNum
        end
        UIHelper.SetText(self.EditPaginate, nCount)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
        self:UpdateCost()
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetText(self.EditPaginate)) - 1
        if nCount < 0 then
            nCount = 0
        end
        UIHelper.SetText(self.EditPaginate, nCount)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
        self:UpdateCost()
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function ()
        local nCount = self.tInfo and self.tInfo[3] or 0
        if nCount < 0 then
            nCount = 0
        end
        UIHelper.SetText(self.EditPaginate, nCount)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
        self:UpdateCost()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local nCount = tonumber(UIHelper.GetText(self.EditPaginate))
            local nMaxNum = self.tInfo and self.tInfo[3] or 0
            if nCount > nMaxNum then
                nCount = nMaxNum
                UIHelper.SetText(self.EditPaginate, nCount)
            elseif nCount < 0 then
                nCount = 0
                UIHelper.SetText(self.EditPaginate, nCount)
            end

            if self.fnChangeEditCount then
                self.fnChangeEditCount(nCount)
            end
            self:UpdateCost()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local nCount = tonumber(UIHelper.GetText(self.EditPaginate))
            local nMaxNum = self.tInfo and self.tInfo[3] or 0
            if nCount > nMaxNum then
                nCount = nMaxNum
                UIHelper.SetText(self.EditPaginate, nCount)
            elseif nCount < 0 then
                nCount = 0
                UIHelper.SetText(self.EditPaginate, nCount)
            end

            if self.fnChangeEditCount then
                self.fnChangeEditCount(nCount)
            end
            self:UpdateCost()
        end)
    end
end

function UIExtractPersetErrorItemCell:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function (editbox, nCurNum)
        if editbox ~= self.EditPaginate then
            return
        end

        local nMaxNum = self.tInfo and self.tInfo[3] or 0
        if nCurNum < 0 then
            nCurNum = 0
        elseif nCurNum >= nMaxNum then
            nCurNum = nMaxNum
        end

        UIHelper.SetText(self.EditPaginate, nCurNum)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCurNum)
        end
        self:UpdateCost()
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardClose, function(editbox)
        if editbox ~= self.EditPaginate then
            return
        end

        local nCurNum = tonumber(UIHelper.GetText(self.EditPaginate))
        local nMaxNum = self.tInfo and self.tInfo[3] or 0
        if nCurNum < 0 then
            nCurNum = 0
        elseif nCurNum >= nMaxNum then
            nCurNum = nMaxNum
        end

        UIHelper.SetText(self.EditPaginate, nCurNum)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCurNum)
        end
        self:UpdateCost()
    end)
end

function UIExtractPersetErrorItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractPersetErrorItemCell:UpdateInfo()
    local tInfo = self.tInfo
    local nType, dwIndex, nMaxNum = tInfo[1], tInfo[2], tInfo[3]
    local nCoin, nMoney = tInfo[4], tInfo[5]
    local nCount = self.tInfo.nCount

    local iteminfo = GetItemInfo(nType, dwIndex)
    if not iteminfo then
        return
    end
    local szName = iteminfo.szName

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName), 9)
    UIHelper.SetString(self.LabelLackNum, tostring(nMaxNum))
    UIHelper.SetText(self.EditPaginate, nMaxNum)
    self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
    self.scriptIcon:OnInitWithTabID(nType, dwIndex)
    self.scriptIcon:SetClearSeletedOnCloseAllHoverTips(true)
    self.scriptIcon:SetClickCallback(function ()
        TipsHelper.ShowItemTips(self.scriptIcon._rootNode, nType, dwIndex, false)
    end)

    self:UpdateCost()
end

function UIExtractPersetErrorItemCell:UpdateCost()
    local tInfo = self.tInfo
    local nType, dwIndex, nMaxNum = tInfo[1], tInfo[2], tInfo[3]
    local nCoin, nMoney = tInfo[4], tInfo[5]
    local nCount = self.tInfo.nCount

    if nCoin > 0 then
        local bEnough = nCount * nCoin <= CurrencyData.GetCurCurrencyCount(CurrencyType.ExamPrint)
        UIHelper.SetString(self.LabelCoinNum, nCount * nCoin)
        UIHelper.SetColor(self.LabelCoinNum, bEnough and cc.WHITE or cc.c3b(255, 118, 118))
    else
        UIHelper.SetVisible(self.LabelCoinNum, false)
        UIHelper.SetVisible(self.WidgetCoin, false)
    end

    if nMoney > 0 then
        local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nCount * nMoney * 10000))
        local bEnough = MoneyOptCmp(g_pClientPlayer.GetMoney(), tPrice) > 0
        UIHelper.SetString(self.LabelMoneyNum, nCount * nMoney)
        UIHelper.SetColor(self.LabelMoneyNum, bEnough and cc.WHITE or cc.c3b(255, 118, 118))
    else
        UIHelper.SetVisible(self.LabelMoneyNum, false)
        UIHelper.SetVisible(self.WidgetMoney, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutCost)
end

function UIExtractPersetErrorItemCell:SetOnClickCancelCallBack(fnOnClickCancel)
    self.fnOnClickCancel = fnOnClickCancel
end

function UIExtractPersetErrorItemCell:SetOnChangeEditCountCallBack(fnChangeEditCount)
    self.fnChangeEditCount = fnChangeEditCount
end

return UIExtractPersetErrorItemCell