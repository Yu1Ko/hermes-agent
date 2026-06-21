-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelInfoSelectType
-- Date: 2025-01-07 15:36:21
-- Desc: 侠客出行 为槽位选择出行事件类型
-- Prefab: WidgetTravelInfoSelectType
-- ---------------------------------------------------------------------------------

---@class UITravelInfoSelectType
local UITravelInfoSelectType = class("UITravelInfoSelectType")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelInfoSelectType:_LuaBindList()
    self.ScrollViewSelectType = self.ScrollViewSelectType --- 事件类别的scroll view
    self.WidgetArrow          = self.WidgetArrow --- 超过一屏时的提示箭头
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelInfoSelectType:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UITravelInfoSelectType:OnEnter(nBoard, nQuestIndex)
    self.nBoard      = nBoard
    self.nQuestIndex = nQuestIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITravelInfoSelectType:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelInfoSelectType:BindUIEvent()

end

function UITravelInfoSelectType:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelInfoSelectType:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelInfoSelectType:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewSelectType)

    local tClassList = PartnerData.GetPartnerTravelClassList()
    for nIndex, nClass in ipairs(tClassList) do
        ---@see UITravelInfoSelectTypeList#OnEnter
        UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoSelectTypeList, self.ScrollViewSelectType, self.nBoard, self.nQuestIndex, nClass)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSelectType)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewSelectType, self.WidgetArrow)
end

return UITravelInfoSelectType