-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFactionRenamePop
-- Date: 2023-03-02
-- Desc: ?
-- Prefab: PanelFactionRenamePop
-- ---------------------------------------------------------------------------------

---@class UIPanelFactionRenamePop
local UIPanelFactionRenamePop = class("UIPanelFactionRenamePop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelFactionRenamePop:_LuaBindList()
    self.LayoutCurrency = self.LayoutCurrency --- 通宝的layout
end

function UIPanelFactionRenamePop:OnEnter()
    self.m = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()
end

function UIPanelFactionRenamePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFactionRenamePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:OnConfirm()
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        self:OnBuy()
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxFactionName01, function()
        self:OnEditBoxEnded()
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxFactionName02, function()
        self:OnEditBoxEnded()
    end)
    UIHelper.BindUIEvent(self.TogHelp, EventType.OnClick, function()
        UIHelper.SetTouchLikeTips(self.WidgetTips, self._rootNode, function()
            UIHelper.SetSelected(self.TogHelp, false)
        end)
    end)

    -- 添加通宝信息
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false, nil, true)
end

function UIPanelFactionRenamePop:Close()
    UIMgr.Close(self)
end

function UIPanelFactionRenamePop:RegEvent()
    Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function()
        self:InitUI()
    end)

    Event.Reg(self, "TONG_EVENT_NOTIFY", function()
        if arg0 == TONG_EVENT_CODE.RENAME_SUCCESS then
            GetTongClient().ApplyTongInfo()
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelTopUpMain then
            UIMgr.HideView(self._nViewID)
            
            Event.Reg(self, EventType.OnViewClose, function()
                UIMgr.ShowView(self._nViewID)
            end)
        end
    end)
end

function UIPanelFactionRenamePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelFactionRenamePop:InitUI()
    -- 当前名称
    UIHelper.SetString(self.LabelFactionName, UIHelper.GBKToUTF8(TongData.GetName()))

    -- 乘余次数
    local nCount = TongData.GetRenameChanceCount()
    local szRich = string.format("<color=#%s>%d</c><color=#ffffff>次</color>", nCount > 0 and "f0dc82" or "ff0000", nCount)
    UIHelper.SetRichText(self.LabelFrequencyNum, szRich)

    self:UpdateBtn()
end

function UIPanelFactionRenamePop:OnConfirm()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "TongRename") then
        return
    end

    UIHelper.ShowConfirm(g_tStrings.STR_TONG_RENAME_CONFIRM, function()
        local szGuildName = UIHelper.GetString(self.EditBoxFactionName01)
        RemoteCallToServer("OnRenameTong", UIHelper.UTF8ToGBK(szGuildName))
    end)
end

function UIPanelFactionRenamePop:OnBuy()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "TongRename") then
        return
    end

    UIHelper.ShowConfirm(g_tStrings.STR_BUY_TONG_RENAME_CONFIRM, function()
        GetTongClient().BuyRenameChance(1)
    end)
end

function UIPanelFactionRenamePop:OnEditBoxEnded()
    self:UpdateBtn()
end

function UIPanelFactionRenamePop:UpdateBtn()
    local bTimesOK = TongData.GetRenameChanceCount() > 0

    local sz1      = UIHelper.GetString(self.EditBoxFactionName01)
    local sz2      = UIHelper.GetString(self.EditBoxFactionName02)
    local bNameOK  = sz1 ~= "" and sz1 == sz2

    local bEnable  = bTimesOK and bNameOK
    UIHelper.SetEnable(self.BtnConfirm, bEnable)
    UIHelper.SetNodeGray(self.BtnConfirm, not bEnable, true)
end

return UIPanelFactionRenamePop