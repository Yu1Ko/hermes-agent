-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishDealCell
-- Date: 2024-01-25 20:59:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishDealCell = class("UIHomeIdentityFishDealCell")

function UIHomeIdentityFishDealCell:OnEnter(tInfo, nMaxNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self.nMaxNum = nMaxNum
    self:UpdateInfo()
end

function UIHomeIdentityFishDealCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishDealCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        if self.fnOnClickCancel then
            self.fnOnClickCancel()
        end
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetText(self.EditPaginate)) + 1
        if nCount > self.nMaxNum then
            nCount = self.nMaxNum
        end
        UIHelper.SetText(self.EditPaginate, nCount)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
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
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nCount = tonumber(UIHelper.GetText(self.EditPaginate))
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCount)
        end
    end)
end

function UIHomeIdentityFishDealCell:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function (editbox, nCurNum)
        if editbox ~= self.EditPaginate then
            return
        end

        if nCurNum < 0 then
            nCurNum = 0
        end
        UIHelper.SetText(self.EditPaginate, nCurNum)
        if self.fnChangeEditCount then
            self.fnChangeEditCount(nCurNum)
        end
    end)
end

function UIHomeIdentityFishDealCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishDealCell:UpdateInfo()
    local tInfo = self.tInfo
    local nMaxNum = self.nMaxNum
    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    local nQuality = tInfo.nQuality
    local nIconID = tInfo.dwIconID

    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetText(self.EditPaginate, nMaxNum)
    self.scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
    self.scriptIcon:OnInitWithIconID(nIconID, nQuality)
    self.scriptIcon:SetClearSeletedOnCloseAllHoverTips(true)
    self.scriptIcon:SetClickCallback(function ()
        Event.Dispatch(EventType.OnFishDealOpenFishTips, tInfo, nMaxNum)
    end)
end

function UIHomeIdentityFishDealCell:SetOnClickCancelCallBack(fnOnClickCancel)
    self.fnOnClickCancel = fnOnClickCancel
end

function UIHomeIdentityFishDealCell:OnChangeEditCount(fnChangeEditCount)
    self.fnChangeEditCount = fnChangeEditCount
end

function UIHomeIdentityFishDealCell:ToggleGroupAddToggle(ToggleGroup)
    self.scriptIcon:SetToggleGroup(ToggleGroup)
end

return UIHomeIdentityFishDealCell