-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UICustomRechargeCoinView
-- Date: 2024-09-06 16:16:40
-- Desc: 自定义档位充值通宝 / 补差价
-- Prefab: PanelQuickPop
-- ---------------------------------------------------------------------------------

---@class UICustomRechargeCoinView
local UICustomRechargeCoinView = class("UICustomRechargeCoinView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UICustomRechargeCoinView:_LuaBindList()
    self.LabelTitle                 = self.LabelTitle --- 标题

    self.BtnClose                   = self.BtnClose --- 关闭
    self.BtnCancel                  = self.BtnCancel --- 取消
    self.BtnOK                      = self.BtnOK --- 确认充值

    self.LayoutRightTop             = self.LayoutRightTop --- 右上角的通宝区域的layout

    -- ---------- 自定义充值
    self.WidgetCustomRecharge       = self.WidgetCustomRecharge --- 自定义充值组件

    self.EditBoxRechargeRMB         = self.EditBoxRechargeRMB --- 充值人民币的输入框
    self.LabelRechargeCoin          = self.LabelRechargeCoin --- 对应充值的通宝数目


    -- ---------- 补差价
    self.WidgetBuChaJia             = self.WidgetBuChaJia --- 补差价组件

    self.RichTextCurrentAndNeedCoin = self.RichTextCurrentAndNeedCoin --- 当前与所需通宝的richtext
    self.LabelMissingCoin           = self.LabelMissingCoin --- 缺少通宝数目的label
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UICustomRechargeCoinView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UICustomRechargeCoinView:OnEnter(nCustomRechargeMode, nNeedTargetCoin)
    ---@see PayData.tCustomRechargeMode
    self.nCustomRechargeMode = nCustomRechargeMode

    --- 补差价所需的目标通宝数目
    self.nNeedTargetCoin     = nNeedTargetCoin

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICustomRechargeCoinView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICustomRechargeCoinView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOK, EventType.OnClick, function()
        if self.nCustomRechargeMode == PayData.tCustomRechargeMode.Custom then
            self:ConfirmCustomRecharge()
        else
            self:ConfirmBuChaJiaRecharge()
        end
    end)

    self.EditBoxRechargeRMB:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" then
            if Platform.IsWindows() or Platform.IsMac() then
                self:UpdateInfo()
            end
        elseif szType == "return" then
            if not Platform.IsWindows() then
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(numKeyBoardEditbox, num)
        if numKeyBoardEditbox ~= self.EditBoxRechargeRMB then return end

        self:UpdateInfo()
    end)
end

function UICustomRechargeCoinView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(Global, "SYNC_COIN", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "OnCoinRechargeSuccess", function()
        --- 充值成功后关闭界面
        UIMgr.Close(self)
    end)
end

function UICustomRechargeCoinView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICustomRechargeCoinView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetCustomRecharge, self.nCustomRechargeMode == PayData.tCustomRechargeMode.Custom)
    UIHelper.SetVisible(self.WidgetBuChaJia, self.nCustomRechargeMode == PayData.tCustomRechargeMode.BuChaJia)

    UIHelper.SetString(self.LabelTitle, self.nCustomRechargeMode == PayData.tCustomRechargeMode.Custom and "通宝自定义购买" or "通宝购买")

    -- 添加通宝信息
    local bAddBtnVisible = false
    UIHelper.RemoveAllChildren(self.LayoutRightTop)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutRightTop, CurrencyType.Coin, bAddBtnVisible)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)

    if self.nCustomRechargeMode == PayData.tCustomRechargeMode.Custom then
        self:UpdateCustomRechargeInfo()
    else
        self:UpdateBuChaJiaRechargeInfo()
    end
end

function UICustomRechargeCoinView:UpdateCustomRechargeInfo()
    local nRMB  = self:GetRechargeRMB()

    local nCoin = nRMB * 100
    UIHelper.SetString(self.LabelRechargeCoin, string.format("获得%d通宝", nCoin))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelRechargeCoin))
end

function UICustomRechargeCoinView:UpdateBuChaJiaRechargeInfo()
    local nCurrentCoin    = g_pClientPlayer.nCoin
    local nNeedTargetCoin = self.nNeedTargetCoin

    local nMissingCoin    = math.max(nNeedTargetCoin - nCurrentCoin, 0)

    UIHelper.SetRichText(self.RichTextCurrentAndNeedCoin, string.format("<color=#ff7676>%d</c>/%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='38' height='38' />", nCurrentCoin, nNeedTargetCoin))
    UIHelper.SetString(self.LabelMissingCoin, nMissingCoin)

    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.RichTextCurrentAndNeedCoin))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelMissingCoin))
end

function UICustomRechargeCoinView:ConfirmCustomRecharge()
    local nRMB = self:GetRechargeRMB()
    --- 输入类似 0060 之类的数值，报错
    local szRMB = UIHelper.GetString(self.EditBoxRechargeRMB)
    if szRMB and szRMB ~= "" and szRMB ~= tostring(nRMB) then
        TipsHelper.ShowImportantYellowTip("当前输入金额有误，请输入正确的数值")
        return
    end
    if nRMB <= 0 then
        TipsHelper.ShowImportantYellowTip("输入数字异常，请检查后再输入")
        return
    end
    if nRMB > 30000 then
        TipsHelper.ShowImportantYellowTip("当前不支持该金额的充值，单笔充值请低于3万元")
        return
    end
    if nRMB % 10 ~= 0 then
        TipsHelper.ShowImportantYellowTip("自定义金额必须是10的倍数")
        return
    end

    local szProductId = PayData.tCustomRechargeProduct.szProductId
    local nBuyCount   = nRMB / 10

    local nCoin = nRMB * 100

    local fnBuy = function()
        LOG.DEBUG("自定义购买 人民币%d元，对应%d通宝，将买入%d份商品%s",
                  nRMB, nCoin, nBuyCount, szProductId
        )

        PayData.Pay(szProductId, nil, nil, nBuyCount)
    end

    if nRMB < 2000 then
        fnBuy()
    else
        local szTips = string.format("本次充值金额较大，请确认充值%d元人民币，购买%d通宝\n（充值成功后将无法退款，请您仔细确认充值金额！）", nRMB, nCoin)
        local confirmDialog = UIHelper.ShowConfirm(szTips, function()
            fnBuy()
        end)
        confirmDialog:SetButtonCountDown(5)
    end
end

function UICustomRechargeCoinView:ConfirmBuChaJiaRecharge()
    local nCurrentCoin    = g_pClientPlayer.nCoin
    local nNeedTargetCoin = self.nNeedTargetCoin

    local nMissingCoin    = math.max(nNeedTargetCoin - nCurrentCoin, 0)
    if nMissingCoin <= 0 then
        TipsHelper.ShowImportantYellowTip("当前通宝充足，无需额外购买")
        return
    end

    local szProductId = PayData.tBuChaJiaRechargeProduct.szProductId

    --- 计算补齐缺失部分通宝所需的人民币
    local nRMB        = math.ceil(nMissingCoin / 100)
    --- 每份为1元，计算所需购买的份数
    local nBuyCount   = nRMB / 1

    local fnBuy = function()
        LOG.DEBUG("补差价 %d通宝(%d-%d)，对应 人民币%d元，将买入%d份商品%s",
                  nMissingCoin, nNeedTargetCoin, nCurrentCoin,
                  nRMB, nBuyCount, szProductId
        )

        PayData.Pay(szProductId, nil, nil, nBuyCount)
    end

    if nRMB < 2000 then
        fnBuy()
    else
        local nCoin = nRMB * 100
        local szTips = string.format("本次充值金额较大，请确认充值%d元人民币，购买%d通宝\n（充值成功后将无法退款，请您仔细确认充值金额！）", nRMB, nCoin)
        local confirmDialog = UIHelper.ShowConfirm(szTips, function()
            fnBuy()
        end)
        confirmDialog:SetButtonCountDown(5)
    end

end

function UICustomRechargeCoinView:GetRechargeRMB()
    local szRMB = UIHelper.GetString(self.EditBoxRechargeRMB)
    local nRMB  = szRMB and szRMB ~= "" and tonumber(szRMB) or 0

    return nRMB
end

return UICustomRechargeCoinView