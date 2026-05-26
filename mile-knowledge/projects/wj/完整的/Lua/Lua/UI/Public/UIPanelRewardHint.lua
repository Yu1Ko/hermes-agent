-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelRewardHint
-- Date: 2023-02-28 09:09:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

--此界面金钱单位为铜
local UIPanelRewardHint = class("UIPanelRewardHint")
local tCustomImg = {
    [1] = "<img src='UIAtlas2_Public_PublicHint_PublicHintReward_icon_yz' width='32' height='32'/>",
    [2] = "<img src='UIAtlas2_Public_PublicHint_PublicHintReward_icon_jz' width='32' height='32'/>",
}

function UIPanelRewardHint:OnEnter(nRewardType, szTitle, tbItems, tbOtherReward, funcConfirm, funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(nRewardType, szTitle, tbItems, tbOtherReward, funcConfirm, funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    self:UpdateInfo()
end

function UIPanelRewardHint:Init(nRewardType, szTitle, tbItems, tbOtherReward, funcConfirm, funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    self.nRewardType = nRewardType
    self.szTitle = szTitle
    self.tbItems = tbItems
    self.tbOtherReward = tbOtherReward
    self.funcConfirm = funcConfirm
    self.funcCancel = funcCancel
    self.szCancel = szCancel or g_tStrings.STR_CANCEL 
    self.szConfirm = szConfirm or g_tStrings.STR_QUEST_SURE 
    self.bShowBtnSure = bShowBtnSure
    self.bShowBtnCancel = bShowBtnCancel
    self.tCustomTip = tCustomTip
end

function UIPanelRewardHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelRewardHint:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        -- UIMgr.Close(self)
        UIHelper.SetVisible(self._rootNode, false)
        self:StopTimer()
        if self.funcConfirm then
            self.funcConfirm()
        end
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        -- UIMgr.Close(self)
        UIHelper.SetVisible(self._rootNode, false)
        self:StopTimer()
        if self.funcCancel then
            self.funcCancel()
        end
    end)

    UIHelper.BindUIEvent(self.BtnMask, EventType.OnClick, function()
        if self.SelectIconScript then
            self.SelectIconScript:RawSetSelected(false)
            self.SelectIconScript = nil
        end
    end)
end

function UIPanelRewardHint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
   
end

function UIPanelRewardHint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelRewardHint:GetMoneyText(nCount)
    local nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nCount)
    if nGold > 0 then return nGold end
    if nSilver > 0 then return nSilver end
    if nCopper > 0 then return nCopper end
end

function UIPanelRewardHint:UpdateInfo()
    for index, UI in ipairs(self.WidgetRewardType) do
        UIHelper.SetVisible(UI, index == self.nRewardType)
    end
    for index, UI in ipairs(self.ImgRewardTipsType) do
        UIHelper.SetVisible(UI, index == self.nRewardType)
    end

    UIHelper.RemoveAllChildren(self.LayoutRewardHind)
    --tbItems = {{dwTabType, dwIndex, nStackNum}, {dwTabType, dwIndex, nStackNum} },

    if self.tbOtherReward then 
        for szName, nCount in pairs(self.tbOtherReward) do
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardHind)
            if scriptView then
                scriptView:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                scriptView:OnInitCurrency(CurrencyData.GetCurrencyTypeByName(szName), nCount)
                scriptView:SetClickCallback(function(nTabType, nTabID)
                    TipsHelper.ShowCurrencyTips(scriptView._rootNode, CurrencyNameToType[szName])
                    self.SelectIconScript = scriptView
                end)
                if szName == "money" and nCount > 0 then
                    local nMoney = self:GetMoneyText(nCount)
                    scriptView:SetLabelCount(nMoney)
                end
            end
        end
    end

    if self.tbItems and #self.tbItems ~= 0 then
        for index, value in ipairs(self.tbItems) do
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRewardHind)
            if scriptView then
                scriptView:SetToggleGroupIndex(ToggleGroupIndex.BagItem)
                scriptView:OnInitWithTabID(value[1], value[2], value[3])
                scriptView:SetClickCallback(function(nTabType, nTabID)
                    TipsHelper.ShowItemTips(scriptView._rootNode, nTabType, nTabID)
                    self.SelectIconScript = scriptView
                end)
            end
        end
    end
    
    local tRichText = {
        [1] = self.RichTextRewradTips1,
        [2] = self.RichTextRewradTips2,
        [3] = self.RichTextRewradTips3,
    }
    for i = 1, #tRichText do
        if self.tCustomTip and self.tCustomTip[i] and self.tCustomTip[i].szText then
            local szImg = tCustomImg[self.tCustomTip[i].rank] or tCustomImg[1]
            UIHelper.SetRichText(tRichText[i], UIHelper.GBKToUTF8(self.tCustomTip[i].szText) .. szImg)
            UIHelper.SetVisible(tRichText[i], true)
        else
            UIHelper.SetVisible(tRichText[i], false)
        end
    end
 
    UIHelper.SetString(self.LabelRewradTips, self.szTitle)
    UIHelper.SetString(self.LabelSure, self.szConfirm)
    UIHelper.SetString(self.LabelCancel, self.szCancel)

    UIHelper.LayoutDoLayout(self.LayoutRewardHind)
    UIHelper.LayoutDoLayout(self.LayoutRewardMiddle)
    UIHelper.LayoutDoLayout(self.LayoutRewardButton)

    if self.bShowBtnSure ~= nil then
        UIHelper.SetVisible(self.BtnSure, self.bShowBtnSure)
    end

    UIHelper.SetVisible(self.BtnCancel, self.bShowBtnCancel)

    UIHelper.SetVisible(self._rootNode, true)
    self:StartTimer()
end

-- function UIPanelRewardHint:SetButtonShowOrHide(szButtonName, bShow)
--     local button = szButtonName == "BtnSure" and self.BtnSure or self.BtnCancel
--     UIHelper.SetVisible(button, bShow)
-- end

function UIPanelRewardHint:StopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function UIPanelRewardHint:StartTimer()
    self:StopTimer()
    self.nTimer = Timer.Add(self, 15, function()
        UIHelper.SetVisible(self._rootNode, false)
        self.nTimer = nil
    end)
end

return UIPanelRewardHint