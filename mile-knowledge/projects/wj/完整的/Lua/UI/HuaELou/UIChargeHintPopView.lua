-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChargeHintPopView
-- Date: 2024-07-17 16:56:30
-- Desc: 充值时长提示
-- Prefab: PanelChargeHintPop
-- ---------------------------------------------------------------------------------

---@class UIChargeHintPopView
local UIChargeHintPopView = class("UIChargeHintPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChargeHintPopView:_LuaBindList()
    self.BtnOpenRecharge = self.BtnOpenRecharge --- 打开充值界面
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChargeHintPopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIChargeHintPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIChargeHintPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChargeHintPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOpenRecharge, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTopUpMain, true)
        UIMgr.Close(self)
    end)
end

function UIChargeHintPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChargeHintPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChargeHintPopView:UpdateInfo()

end

return UIChargeHintPopView