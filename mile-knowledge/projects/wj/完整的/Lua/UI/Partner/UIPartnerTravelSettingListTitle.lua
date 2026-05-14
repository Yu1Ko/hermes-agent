-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelSettingListTitle
-- Date: 2024-11-22 11:13:56
-- Desc: 侠客出行设置界面 左侧的事件 大类
-- Prefab: WidgetPartnerTravelSettingListTitle
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelSettingListTitle
local UIPartnerTravelSettingListTitle = class("UIPartnerTravelSettingListTitle")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingListTitle:_LuaBindList()
    self.LabelTitle1 = self.LabelTitle1 --- 折叠时的名字
    self.LabelTitle2 = self.LabelTitle2 --- 展开时的名字
    self.ToggleTitle = self.ToggleTitle --- toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingListTitle:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelSettingListTitle:OnEnter(szTitle)
    self.szTitle = szTitle

    if not self.szTitle then
        return
    end
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIPartnerTravelSettingListTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelSettingListTitle:BindUIEvent()

end

function UIPartnerTravelSettingListTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelSettingListTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelSettingListTitle:UpdateInfo()
    UIHelper.SetString(self.LabelTitle1, self.szTitle)
    UIHelper.SetString(self.LabelTitle2, self.szTitle)
end

return UIPartnerTravelSettingListTitle