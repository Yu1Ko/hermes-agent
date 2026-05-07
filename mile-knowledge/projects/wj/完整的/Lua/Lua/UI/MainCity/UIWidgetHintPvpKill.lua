-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIWidgetHintPvpKill
-- Date: 2024-03-19 15:39:46
-- Desc: moba局内消息
-- Prefab: WidgetHintPvpKill
-- ---------------------------------------------------------------------------------

---@class UIWidgetHintPvpKill
local UIWidgetHintPvpKill = class("UIWidgetHintPvpKill")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetHintPvpKill:_LuaBindList()
    self.LabelNameLeft  = self.LabelNameLeft --- 左侧名字
    self.LabelNameRight = self.LabelNameRight --- 右侧名字
    self.SfxHint        = self.SfxHint --- 特效组件
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIWidgetHintPvpKill:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIWidgetHintPvpKill:OnEnter(szLeft, szRight, szSfxPath)
    self.szLeft    = szLeft
    self.szRight   = szRight
    self.szSfxPath = szSfxPath

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetHintPvpKill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHintPvpKill:BindUIEvent()

end

function UIWidgetHintPvpKill:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHintPvpKill:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHintPvpKill:UpdateInfo()
    UIHelper.SetString(self.LabelNameLeft, UIHelper.LimitUtf8Len(self.szLeft, 6))
    UIHelper.SetString(self.LabelNameRight, UIHelper.LimitUtf8Len(self.szRight, 6))

    UIHelper.SetSFXPath(self.SfxHint, self.szSfxPath)
end

return UIWidgetHintPvpKill