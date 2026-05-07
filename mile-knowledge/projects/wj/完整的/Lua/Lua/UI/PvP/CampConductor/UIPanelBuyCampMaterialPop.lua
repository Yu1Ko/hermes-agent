-- ---------------------------------------------------------------------------------
-- Name: UIPanelBuyCampMaterialPop
-- Desc: 购买装置弹出框
-- Prefab:PanelBuyCampMaterialPop
-- ---------------------------------------------------------------------------------

local UIPanelBuyCampMaterialPop = class("UIPanelBuyCampMaterialPop")

function UIPanelBuyCampMaterialPop:_LuaBindList()
    self.BtnClose          = self.BtnClose

    self.WidgetItem_80     = self.WidgetItem_80 -- 加载装备图像
    self.LabelMaterialName = self.LabelMaterialName -- 装备name

    self.EditPaginate      = self.EditPaginate -- 文本编辑框
    self.ButtonAdd         = self.ButtonAdd
    self.ButtonDecrease    = self.ButtonDecrease

    self.LabelMoney_Tong   = self.LabelMoney_Tong-- 铜
    self.LabelMoney_Yin    = self.LabelMoney_Yin -- 银
    self.LabelMoney_Jin    = self.LabelMoney_Jin -- 金
    self.LabelMoney_Zhuan  = self.LabelMoney_Zhuan -- 金砖

    self.BtnBuy            = self.BtnBuy -- 购买
end

function UIPanelBuyCampMaterialPop:OnEnter(nIndex, item)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self:UpdateInfo(nIndex, item)
end

function UIPanelBuyCampMaterialPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBuyCampMaterialPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        self:BuyMaterial()
        UIMgr.Close(self)
    end)
end

function UIPanelBuyCampMaterialPop:RegEvent()

end

function UIPanelBuyCampMaterialPop:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBuyCampMaterialPop:UpdateInfo(nIndex, item)
    self.nIndex = nIndex

    local tConstData = CommandBaseData.tGoodsInitSetting[nIndex]
    local tInfo = CommandBaseData.tGoodsSetting[nIndex]
    local nMaxCanBuy = math.modf(CommandBaseData.GetMoney() / tConstData.nMoney)
    nMaxCanBuy = math.min(nMaxCanBuy, tInfo.nCanBuy or 0)

    UIHelper.SetString(self.LabelMaterialName, CommandBaseData.tGoodsTypeToName[nIndex])
    self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    self.scriptItemIcon:UpdateInfo(item)
    UIHelper.SetTouchEnabled(self.scriptItemIcon.ToggleSelect, false)

    self:RefreshMoney(0)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local szNum = UIHelper.GetText(self.EditPaginate)
            if szNum ~= nil and szNum ~= "" then
                local nNum = tonumber(szNum)
                if nNum > nMaxCanBuy then
                    nNum = nMaxCanBuy
                    local szWrongMsg = "资金最多只能支持购买" .. nMaxCanBuy .. "个"
                    TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.EditPaginate, TipsLayoutDir.RIGHT_CENTER, szWrongMsg)
                end
                UIHelper.SetText(self.EditPaginate, nNum)
                self:RefreshMoney(nNum * tConstData.nMoney)
            else
                UIHelper.SetText(self.EditPaginate, 0)
                self:RefreshMoney(0)
            end
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local szNum = UIHelper.GetText(self.EditPaginate)
            if szNum ~= nil and szNum ~= "" then
                local nNum = tonumber(szNum)
                if nNum > nMaxCanBuy then
                    nNum = nMaxCanBuy
                    local szWrongMsg = "资金最多只能支持购买" .. nMaxCanBuy .. "个"
                    TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.EditPaginate, TipsLayoutDir.RIGHT_CENTER, szWrongMsg)
                end
                UIHelper.SetText(self.EditPaginate, nNum)
                self:RefreshMoney(nNum * tConstData.nMoney)
            else
                UIHelper.SetText(self.EditPaginate, 0)
                self:RefreshMoney(0)
            end
        end)
    end
end

function UIPanelBuyCampMaterialPop:RefreshMoney(nMoney)
    local nGoldB, nGold = ConvertGoldToGBrick(nMoney)
    UIHelper.SetString(self.LabelMoney_Zhuan, nGoldB)
    UIHelper.SetString(self.LabelMoney_Jin, nGold)
end

function UIPanelBuyCampMaterialPop:BuyMaterial()
    local szNum = UIHelper.GetText(self.EditPaginate)
    if szNum ~= nil and szNum ~= "" then
        local nNum = tonumber(szNum)
        RemoteCallToServer("On_Camp_GFBuyItem", self.nIndex, nNum)
    end
end

return UIPanelBuyCampMaterialPop