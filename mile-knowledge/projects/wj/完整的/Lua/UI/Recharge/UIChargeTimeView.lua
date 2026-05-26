-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChargeTimeView
-- Date: 2024-04-29 19:33:29
-- Desc: 充值提示界面
-- Prefab: PanelChargeTime
-- ---------------------------------------------------------------------------------

---@class UIChargeTimeView
local UIChargeTimeView = class("UIChargeTimeView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChargeTimeView:_LuaBindList()
    self.BtnClose                   = self.BtnClose --- 关闭界面

    self.BtnRecharge                = self.BtnRecharge --- 充值页面
    self.BtnFirstRechargeActivity   = self.BtnFirstRechargeActivity --- 首充有礼
    self.BtnMonthlyRechargeActivity = self.BtnMonthlyRechargeActivity --- 月度冲销
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChargeTimeView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIChargeTimeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChargeTimeView:OnExit()
    BubbleMsgData.PushMsgWithType("ChargeTimeTips", {
        nBarTime = 0,
        szAction = function()
            UIMgr.OpenSingle(false, VIEW_ID.PanelChargeTime)
        end,
    })

    self.bInit = false
    self:UnRegEvent()
end

function UIChargeTimeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRecharge, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTopUpMain, true)
    end)

    UIHelper.BindUIEvent(self.BtnFirstRechargeActivity, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBenefits)
    end)

    UIHelper.BindUIEvent(self.BtnMonthlyRechargeActivity, EventType.OnClick, function()
        local dwOperatActID = 39
        UIMgr.Open(VIEW_ID.PanelOperationCenter, dwOperatActID)
    end)
end

function UIChargeTimeView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChargeTimeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--- 是否是iOS => 是否是试玩账号 => 左侧的图片
--- todo: 等待实际资源，替换到下面
local tIsIosToIsLimitAccountToLeftImg = {
    [true] = {
        -- ios 试玩
        [true] = "UIAtlas2_Shopping_ChargeTime_img_title.png",
        -- ios 普通
        [false] = "UIAtlas2_Shopping_ChargeTime_img_title3.png",
    },
    [false] = {
        -- 其他 试玩
        [true] = "UIAtlas2_Shopping_ChargeTime_img_title2.png",
        -- 其他 普通
        [false] = "UIAtlas2_Shopping_ChargeTime_img_title4.png",
    },
}

function UIChargeTimeView:UpdateInfo()
    if not g_pClientPlayer then
        return
    end

    local bIos          = Platform.IsIos()
    local bLimitAccount = IsLimitAccount(g_pClientPlayer)

    --- 不同状态下，左侧标题的图片不同
    local szLeftImg     = tIsIosToIsLimitAccountToLeftImg[bIos][bLimitAccount]
    local imgTitle      = UIHelper.FindChildByName(self._rootNode, "ImgTitle")
    UIHelper.SetSpriteFrame(imgTitle, szLeftImg)

    --- 仅试玩玩家显示 首充有礼
    local layout              = UIHelper.FindChildByName(self._rootNode, "LayoutActivity")
    local widgetFirstRecharge = UIHelper.FindChildByName(layout, "WidgetActivity1")
    UIHelper.SetVisible(widgetFirstRecharge, bLimitAccount)
    UIHelper.LayoutDoLayout(layout)
end

return UIChargeTimeView