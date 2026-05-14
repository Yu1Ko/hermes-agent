-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCompeteReward
-- Date: 2024-02-05 10:12:02
-- Desc: PanelCompete WidgetReward
-- ---------------------------------------------------------------------------------

local UIWidgetCompeteReward = class("UIWidgetCompeteReward")

--From UIQuestAwardView.lua
local CurrencyNameToType =
{
    ["战阶"] = CurrencyType.TitlePoint,
    -- ["金钱"] = CurrencyType.Money,
    -- ["修为"] = CurrencyType.Train,
    -- ["精力"] = CurrencyType.Vigor,
    ["威名"] = CurrencyType.Prestige,
    -- ["威望"] = CurrencyType.Prestige,
    -- ["侠行点"] = CurrencyType.Justice,
    -- ["通宝"] = CurrencyType.Coin,
    -- ["商城积分"] = CurrencyType.StorePoint,
    -- ["帮会资金"] = CurrencyType.GangFunds,
    -- ["侠义值"] = CurrencyType.Justice,
    -- ["声望"] = CurrencyType.Reputation,
    -- ["载具资源"] = CurrencyType.TongResource,
    -- ["方士身份阅历"] = CurrencyType.IdentityExp,
}

function UIWidgetCompeteReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetCompeteReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCompeteReward:BindUIEvent()
    
end

function UIWidgetCompeteReward:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItem then
            self.scriptItem:SetSelected(false)
        end
    end)
end

function UIWidgetCompeteReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCompeteReward:UpdateInfo(tbAward)
    local szItemName = tbAward[1]
    local nCount = tbAward[2]
    local nItemTabType = tbAward[3]
    local nItemIndex = tbAward[4]

    UIHelper.SetString(self.LabelNameItem, UIHelper.TruncateStringReturnOnlyResult(szItemName, 3, "..."))
    UIHelper.SetString(self.LabelNumItem, nCount)
    UIHelper.SetVisible(self.LabelNumItem, nCount ~= 0)

    self.scriptItem = self.scriptItem or UIHelper.GetBindScript(self.WidgetItem)
    if not self.scriptItem then
        return
    end

    if nItemTabType and nItemIndex then
        self.scriptItem:OnInitWithTabID(nItemTabType, nItemIndex)
    else
        self.scriptItem:OnInitCurrency(CurrencyNameToType[szItemName] or szItemName, nCount)
    end
    self.scriptItem:SetLabelCount(nil)

    self.scriptItem:SetClickCallback(function(nTabType, nTabID , nCount)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItem, TipsLayoutDir.TOP_LEFT)

        if self.scriptItem.bItem then
            scriptItemTip:OnInit(nTabType, nTabID)
        elseif self.scriptItem.bIsCurrencyType then
            scriptItemTip:OnInitCurrency(nTabID, nCount, self.scriptItem.bIsReputation)
        else
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        end
        scriptItemTip:SetBtnState({})
    end)
end


return UIWidgetCompeteReward