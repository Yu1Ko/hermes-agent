-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChampionshipData
-- Date: 2024-07-31 17:27:12
-- Desc: 帮会联赛-指挥面板-数据条目
-- Prefab: WidgetChampionshipData
-- ---------------------------------------------------------------------------------

---@class UIChampionshipData
local UIChampionshipData = class("UIChampionshipData")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChampionshipData:_LuaBindList()
    self.LabelTitle = self.LabelTitle --- 标题
    self.LabelBlue  = self.LabelBlue --- 蓝方数值
    self.LabelRed   = self.LabelRed --- 红方数值
    self.ImgIcon    = self.ImgIcon --- 图标
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChampionshipData:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIChampionshipData:OnEnter(szTitle, szIcon, szBlue, szRed)
    self.szTitle = szTitle
    self.szIcon  = szIcon
    self.szBlue  = szBlue
    self.szRed   = szRed

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChampionshipData:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChampionshipData:BindUIEvent()

end

function UIChampionshipData:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChampionshipData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChampionshipData:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetString(self.LabelBlue, self.szBlue)
    UIHelper.SetString(self.LabelRed, self.szRed)

    UIHelper.SetSpriteFrame(self.ImgIcon, self.szIcon)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIChampionshipData