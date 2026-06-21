-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickPayView
-- Date: 2022-12-15 19:08:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickPayView = class("UIQuickPayView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIQuickPayView:_LuaBindList()
    self.LabelLackCoin = self.LabelLackCoin --- 缺少的通宝数量
    self.LabelBuyCoin = self.LabelBuyCoin --- 推荐购买的通宝档位
    self.BtnGoPayCenter = self.BtnGoPayCenter --- 前往充值中心
    self.BtnPay = self.BtnPay --- 购买按钮
    self.LabelPayPrice = self.LabelPayPrice --- 购买按钮上面显示的价格
    self.LabelPayProductName = self.LabelPayProductName --- 充值商品名称
    self.BtnClose = self.BtnClose --- 关闭按钮
end

function UIQuickPayView:OnEnter(nLackCoin, tbBuyProductCfg)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLackCoin = nLackCoin
    self.tbBuyProductCfg = tbBuyProductCfg

    self:UpdateInfo()
end

function UIQuickPayView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuickPayView:BindUIEvent()
    -- 支付
    UIHelper.BindUIEvent(self.BtnPay, EventType.OnClick, function ()
        if self.tbBuyProductCfg then
            PayData.Pay(self.tbBuyProductCfg.szProductId)
        end
        UIMgr.Close(self)
    end)

    -- 充值中心
    UIHelper.BindUIEvent(self.BtnGoPayCenter, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
        UIMgr.Close(self)
    end)

    -- 关闭
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIQuickPayView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuickPayView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickPayView:UpdateInfo()
    UIHelper.SetRichText(self.LabelLackCoin, tostring(self.nLackCoin))

    UIHelper.SetString(self.LabelBuyCoin, tostring(self.tbBuyProductCfg.nGainCoin))
    UIHelper.SetString(self.LabelPayPrice, string.format("%d%s", self.tbBuyProductCfg.nPrice, g_tStrings.CHARGE_YUAN))
    UIHelper.SetString(self.LabelPayProductName, self.tbBuyProductCfg.szProductName)
end

return UIQuickPayView
