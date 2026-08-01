-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIItemMultiPurchasePopView
-- Date: 2024-05-23 15:36:05
-- Desc: 家园购买物品
-- Prefab: PanelItemMultiPurchasePop
-- ---------------------------------------------------------------------------------

---@class UIItemMultiPurchasePopView
local UIItemMultiPurchasePopView = class("UIItemMultiPurchasePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIItemMultiPurchasePopView:_LuaBindList()
    self.BtnClose              = self.BtnClose --- 关闭按钮

    self.LabelTitle            = self.LabelTitle --- 标题
    self.LabelContentLine1     = self.LabeContentLine1 --- 内容1
    self.LabelContentLine2     = self.LabeContentLine2 --- 内容2

    self.LabelCostArchitecture = self.LabelCostArchitecture --- 园宅币价格

    -- 园宅币不够时，混合购买
    self.LayoutMixed           = self.LayoutMixed --- layout
    self.LabelMixedMoney_Tong  = self.LabelMixedMoney_Tong --- 铜币
    self.LabelMixedMoney_Yin   = self.LabelMixedMoney_Yin --- 银币
    self.LabelMixedMoney_Jin   = self.LabelMixedMoney_Jin --- 金币
    self.LabelMixedMoney_Zhuan = self.LabelMixedMoney_Zhuan --- 金砖

    -- 使用金币来购买
    self.LayoutCurrency        = self.LayoutCurrency --- layout
    self.LabelMoney_Tong       = self.LabelMoney_Tong --- 铜币
    self.LabelMoney_Yin        = self.LabelMoney_Yin --- 银币
    self.LabelMoney_Jin        = self.LabelMoney_Jin --- 金币
    self.LabelMoney_Zhuan      = self.LabelMoney_Zhuan --- 金砖

    self.BtnPurchase           = self.BtnPurchase --- 购买按钮
    self.TogBuyByMixed         = self.TogBuyByMixed --- 使用园宅币购买的toggle
    self.TogBuyByMoney         = self.TogBuyByMoney --- 使用金币购买的toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIItemMultiPurchasePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIItemMultiPurchasePopView:OnEnter(nCostArchitecture, szTitle, szContent1, szContent2, fnBuyCallback)
    --- 购买所需的园宅币
    self.nCostArchitecture                       = nCostArchitecture

    --- 标题栏
    self.szTitle                                 = szTitle
    --- 内容1
    self.szContent1                              = szContent1
    --- 内容2
    self.szContent2                              = szContent2

    --- 购买回调
    --- @type fun(nCostArch: number, tMoney: table)
    self.fnBuyCallback                           = fnBuyCallback

    local tConfig                                = GetHomelandMgr().GetConfig()
    self.nArchMoneyRate                          = tConfig.nBuyFurnitureMoneyRate

    -- 预先计算不同方式购买所需要的货币数目
    self.tAllMoney                               = self:GetBuyByMoneyCostMoney()
    self.nMixedCostArchitecture, self.tDiffMoney = self:GetBuyByMixedCostArchitectureAndMoney()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemMultiPurchasePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemMultiPurchasePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function()
        self:Purchase()
    end)
end

function UIItemMultiPurchasePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemMultiPurchasePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemMultiPurchasePopView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetString(self.LabelContentLine1, self.szContent1)
    UIHelper.SetString(self.LabelContentLine2, self.szContent2)

    self:UpdateBuyByMixedInfo()
    self:UpdateBuyByMoneyInfo()
end

function UIItemMultiPurchasePopView:UpdateBuyByMixedInfo()
    -- 园宅币不够时，显示混合购买选项
    local bShowMixed = self:NeedMixedBuy()
    UIHelper.SetVisible(self.LayoutMixed, bShowMixed)
    if not bShowMixed then
        -- 仅使用园宅币
        UIHelper.SetString(self.LabelCostArchitecture, self.nCostArchitecture)
    else
        -- 使用金币补足
        UIHelper.SetString(self.LabelCostArchitecture, self.nMixedCostArchitecture)

        local nZhuan, nGold, nSilver = table.unpack(self.tDiffMoney)
        UIHelper.SetString(self.LabelMixedMoney_Zhuan, nZhuan)
        UIHelper.SetString(self.LabelMixedMoney_Jin, nGold)
        UIHelper.SetString(self.LabelMixedMoney_Yin, nSilver)

        UIHelper.CascadeDoLayoutDoWidget(self.LayoutMixed, true, true)
    end
end

function UIItemMultiPurchasePopView:UpdateBuyByMoneyInfo()
    local nZhuan, nGold, nSilver = table.unpack(self.tAllMoney)
    UIHelper.SetString(self.LabelMoney_Zhuan, nZhuan)
    UIHelper.SetString(self.LabelMoney_Jin, nGold)
    UIHelper.SetString(self.LabelMoney_Yin, nSilver)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
end

--- 全部使用金币购买所需要的 金币
function UIItemMultiPurchasePopView:GetBuyByMoneyCostMoney()
    local nPrice                 = self.nCostArchitecture
    local nTotalSilver           = self:TransformArchToSilver(nPrice)
    local nZhuan, nGold, nSilver = self:GetMoneyDetail(nTotalSilver)

    local tAllMoney              = { nZhuan, nGold, nSilver }
    tAllMoney.nTotalSilver       = nTotalSilver

    return tAllMoney
end

--- 使用园宅币购买，并使用金币补足所需要的 园宅币 和 金币
function UIItemMultiPurchasePopView:GetBuyByMixedCostArchitectureAndMoney()
    local nPrice      = self.nCostArchitecture

    local nCostArch
    local tDiffMoney

    local nPlayerArch = g_pClientPlayer.nArchitecture
    if nPlayerArch >= nPrice then
        nCostArch  = nPrice
        tDiffMoney = nil
    else
        local nDiffArch              = nPrice - nPlayerArch
        local nTotalSilver           = self:TransformArchToSilver(nDiffArch)
        local nZhuan, nGold, nSilver = self:GetMoneyDetail(nTotalSilver)

        nCostArch                    = nPlayerArch
        tDiffMoney                   = { nZhuan, nGold, nSilver }
        tDiffMoney.nTotalSilver      = nTotalSilver
    end

    return nCostArch, tDiffMoney
end

function UIItemMultiPurchasePopView:TransformArchToSilver(nArch)
    return math.ceil(nArch * 100 / self.nArchMoneyRate)
end

function UIItemMultiPurchasePopView:GetMoneyDetail(nMoney)
    local nZhuan  = math.floor(nMoney / 10000 / 100)
    local nGlod   = math.floor((nMoney - nZhuan * 10000 * 100) / 100)
    local nSilver = nMoney % 100
    return nZhuan, nGlod, nSilver
end

function UIItemMultiPurchasePopView:Purchase()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
        return
    end
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return
    end
    local bAllGoldBuy = self:IsAllGoldBuy()
    if bAllGoldBuy then
        --- 使用金币购买
        self:OpenGoldBuySure()
    else
        --- 使用园宅币购买
        if self:NeedMixedBuy() then
            --- 需要金币补齐
            self:OpenGoldBuySure()
        else
            --- 完全使用园宅币购买
            self.fnBuyCallback(self.nCostArchitecture, nil)
            self:CloseSelfAndBuyView()
        end
    end
end

function UIItemMultiPurchasePopView:IsAllGoldBuy()
    return UIHelper.GetSelected(self.TogBuyByMoney)
end

function UIItemMultiPurchasePopView:NeedMixedBuy()
    return self.tDiffMoney ~= nil
end

function UIItemMultiPurchasePopView:OpenGoldBuySure()
    local bAllGoldBuy = self:IsAllGoldBuy()
    
    local nCostArch
    local tMoney
    if bAllGoldBuy then
        nCostArch = 0
        tMoney = self.tAllMoney
    else
        nCostArch = self.nMixedCostArchitecture
        tMoney = self.tDiffMoney
    end

    local szCost = ""
    if nCostArch > 0 then
        szCost = string.format("<color=#FFE26E>%d</c>园宅币和", nCostArch)
    end
    if tMoney[1] > 0 then
        szCost = szCost .. string.format("<color=#FFE26E>%d</c>砖", tMoney[1])
    end
    if tMoney[2] > 0 then
        szCost = szCost .. string.format("<color=#FFE26E>%d</c>金", tMoney[2])
    end
    if tMoney[3] > 0 then
        szCost = szCost .. string.format("<color=#FFE26E>%d</c>银", tMoney[3])
    end

    local szInfo = string.format("确定要花费%s购买吗？", szCost)
    ---@type UIConfirmView
    local scriptView = UIHelper.ShowConfirm(szInfo, function()
        self.fnBuyCallback(nCostArch, tMoney)
        self:CloseSelfAndBuyView()
    end, nil, true)
    
    scriptView:SetButtonCountDown(5)
end

function UIItemMultiPurchasePopView:CloseSelfAndBuyView()
    UIMgr.Close(self)
    UIMgr.Close(VIEW_ID.PanelPartnerBuy)
end

return UIItemMultiPurchasePopView