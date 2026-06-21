-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIEquipSchemePopView
-- Date: 2024-02-01 17:26:20
-- Desc: 列星虚境选择预设装备方案
-- Prefab: PanelEquipSchemePop
-- ---------------------------------------------------------------------------------

---@class UIEquipSchemePopView
local UIEquipSchemePopView = class("UIEquipSchemePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIEquipSchemePopView:_LuaBindList()
    self.BtnClose         = self.BtnClose --- 关闭界面

    self.LayoutSchemeList = self.LayoutSchemeList --- 预设方案列表的layout
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIEquipSchemePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIEquipSchemePopView:OnEnter()
    if not self.bInit then
        LieXingXuJingData.InitPrePurchase(false)

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIEquipSchemePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquipSchemePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    Event.Reg(self, "Moba_SelectPrePurchasePlan", function()
        UIMgr.Close(self)
    end)
end

function UIEquipSchemePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEquipSchemePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local MAX_PREPURCHASE_NUM = 3

function UIEquipSchemePopView:UpdateInfo()
    self.nKungfuMountID = LieXingXuJingData.GetKungFuMountID()

    UIHelper.RemoveAllChildren(self.LayoutSchemeList)

    for i = 1, MAX_PREPURCHASE_NUM do
        ---@see UISchemeListCell#OnEnter
        UIHelper.AddPrefab(PREFAB_ID.WidgetSchemeListCell, self.LayoutSchemeList, i, self.nKungfuMountID)
    end

    UIHelper.LayoutDoLayout(self.LayoutSchemeList)
end

return UIEquipSchemePopView