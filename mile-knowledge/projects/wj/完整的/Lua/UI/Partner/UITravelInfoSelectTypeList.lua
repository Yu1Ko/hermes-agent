-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelInfoSelectTypeList
-- Date: 2025-01-07 15:47:32
-- Desc: 侠客出行 选择类别 具体的类别
-- Prefab: WidgetTravelInfoSelectTypeList
-- ---------------------------------------------------------------------------------

---@class UITravelInfoSelectTypeList
local UITravelInfoSelectTypeList = class("UITravelInfoSelectTypeList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelInfoSelectTypeList:_LuaBindList()
    self.ImgIcon           = self.ImgIcon --- 图标
    self.LabelTitle        = self.LabelTitle --- 名称
    self.LabelLimitInfo    = self.LabelLimitInfo --- 周期限制信息
    self.BtnSelectTypeList = self.BtnSelectTypeList --- 按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelInfoSelectTypeList:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UITravelInfoSelectTypeList:OnEnter(nBoard, nQuestIndex, nClass)
    self.nBoard      = nBoard
    self.nQuestIndex = nQuestIndex
    self.nClass      = nClass

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITravelInfoSelectTypeList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelInfoSelectTypeList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelectTypeList, EventType.OnClick, function()
        self:OpenTravelSettingView()
    end)
end

function UITravelInfoSelectTypeList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelInfoSelectTypeList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelInfoSelectTypeList:UpdateInfo()
    local tInfo           = Table_GetPartnerTravelClass(self.nClass)

    local szTypeName      = UIHelper.GBKToUTF8(tInfo.szClassName)

    local _, nCount, nMax = PartnerData.GetTravelCountInfo(tInfo.nDataIndex)
    local szLimitType
    if tInfo.nLimitType == 1 then
        szLimitType = "今日"
    else
        szLimitType = "本周"
    end
    local szLimitInfo = string.format("%s%d/%d", szLimitType, nCount, nMax)

    if PartnerTravelClassToIconPath[self.nClass] then
        local szIconPath = PartnerTravelClassToIconPath[self.nClass]
        UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)
    end

    UIHelper.SetString(self.LabelTitle, szTypeName)
    UIHelper.SetString(self.LabelLimitInfo, szLimitInfo)
end

function UITravelInfoSelectTypeList:OpenTravelSettingView()
    ---@see UIPartnerTravelSettingView
    UIMgr.Open(VIEW_ID.PanelPartnerTravelSetting, self.nBoard, self.nQuestIndex, self.nClass)
end

return UITravelInfoSelectTypeList