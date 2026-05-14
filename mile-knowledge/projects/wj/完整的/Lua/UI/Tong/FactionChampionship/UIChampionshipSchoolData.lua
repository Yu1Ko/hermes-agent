-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChampionshipSchoolData
-- Date: 2024-08-02 19:31:07
-- Desc: 帮会联赛-结算-单个门派统计数据
-- Prefab: WidgetChampionshipSchoolData
-- ---------------------------------------------------------------------------------

---@class UIChampionshipSchoolData
local UIChampionshipSchoolData = class("UIChampionshipSchoolData")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChampionshipSchoolData:_LuaBindList()
    self.LabelSchoolTitle = self.LabelSchoolTitle --- 门派名称
    self.LabelBlueCount   = self.LabelBlueCount --- 蓝方人数
    self.LabelRedCount    = self.LabelRedCount --- 红方人数

    self.LayoutTop        = self.LayoutTop --- 最上层的layout

    self.ImgBgBlue1       = self.ImgBgBlue1 --- 蓝色奇数行背景
    self.ImgBgBlue2       = self.ImgBgBlue2 --- 蓝色偶数行背景
    self.ImgBgRed1        = self.ImgBgRed1 --- 红色奇数行背景
    self.ImgBgRed2        = self.ImgBgRed2 --- 红色偶数行背景
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChampionshipSchoolData:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIChampionshipSchoolData:OnEnter(szSchoolTitle, nBlueCount, nRedCount, nIndex)
    self.szSchoolTitle = szSchoolTitle
    self.nBlueCount    = nBlueCount
    self.nRedCount     = nRedCount
    self.nIndex        = nIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChampionshipSchoolData:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChampionshipSchoolData:BindUIEvent()

end

function UIChampionshipSchoolData:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChampionshipSchoolData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChampionshipSchoolData:UpdateInfo()
    UIHelper.SetString(self.LabelSchoolTitle, self.szSchoolTitle)
    UIHelper.SetString(self.LabelBlueCount, self.nBlueCount)
    UIHelper.SetString(self.LabelRedCount, self.nRedCount)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTop, true, true)
    
    local bSingle = self.nIndex % 2 == 1
    UIHelper.SetVisible(self.ImgBgBlue1, bSingle)
    UIHelper.SetVisible(self.ImgBgRed1, bSingle)

    UIHelper.SetVisible(self.ImgBgBlue2, not bSingle)
    UIHelper.SetVisible(self.ImgBgRed2, not bSingle)
end

return UIChampionshipSchoolData