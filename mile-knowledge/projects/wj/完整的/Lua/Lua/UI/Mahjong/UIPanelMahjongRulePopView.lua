-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelMahjongRulePopView
-- Date: 2023-08-08 15:02:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelMahjongRulePopView = class("UIPanelMahjongRulePopView")
local TitleList ={
    "基本规则",
    "基本番型",
    "特殊规则",
    "结算",
}

function UIPanelMahjongRulePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelMahjongRulePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelMahjongRulePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelMahjongRulePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelMahjongRulePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMahjongRulePopView:UpdateInfo()
    for nIndex, szTitle in ipairs(TitleList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetRuleListLeft, self.ScrollViewRuleListLeft, szTitle, nIndex, self)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRuleListLeft)
end

function UIPanelMahjongRulePopView:UpdateText(szText)
    UIHelper.SetString(self.LabelRule, szText)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRuleList)
    UIHelper.SetVisible(self.ScrollViewRuleList, true)
    UIHelper.SetVisible(self.ScrollViewSpecialRule, false)
end

function UIPanelMahjongRulePopView:ShowSpecialRule()
    UIHelper.SetVisible(self.ScrollViewRuleList, false)
    UIHelper.SetVisible(self.ScrollViewSpecialRule, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSpecialRule)
end


return UIPanelMahjongRulePopView