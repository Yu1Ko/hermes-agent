-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIHintFactionChampionship
-- Date: 2024-08-12 15:49:57
-- Desc: 帮会联赛进图提示
-- Prefab: WidgetHintFactionChampionship
-- ---------------------------------------------------------------------------------

local tMapLevelToName           = {
    [0] = "巅峰场",
    [1] = "大师场",
    [2] = "精英场",
}

---@class UIHintFactionChampionship
local UIHintFactionChampionship = class("UIHintFactionChampionship")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIHintFactionChampionship:_LuaBindList()
    self.LabelLevelName = self.LabelLevelName --- 比赛级别名称
    self.ImgLevel       = self.ImgLevel --- 级别图片
    self.ImgBgLihgt     = self.ImgBgLihgt --- 背景光图片
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIHintFactionChampionship:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIHintFactionChampionship:OnEnter(nMapLevel)
    self.nMapLevel = nMapLevel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHintFactionChampionship:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHintFactionChampionship:BindUIEvent()

end

function UIHintFactionChampionship:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHintFactionChampionship:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHintFactionChampionship:UpdateInfo()
    local szName = tMapLevelToName[self.nMapLevel]

    UIHelper.SetString(self.LabelLevelName, szName)
end

return UIHintFactionChampionship