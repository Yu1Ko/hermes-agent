-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelSettingBanner
-- Date: 2025-02-14 17:03:11
-- Desc: 侠客出行 奇遇轮播页 单个页面
-- Prefab: WidgetPartnerTravelSettingBanner
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelSettingBanner
local UIPartnerTravelSettingBanner = class("UIPartnerTravelSettingBanner")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingBanner:_LuaBindList()
    self.ImgBanner = self.ImgBanner --- 奇遇图片
    self.ImgGet    = self.ImgGet --- 已触发的标记
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingBanner:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelSettingBanner:OnEnter(dwAdventureID)
    if not dwAdventureID then
        return
    end


    self.dwAdventureID = dwAdventureID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerTravelSettingBanner:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelSettingBanner:BindUIEvent()

end

function UIPartnerTravelSettingBanner:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelSettingBanner:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelSettingBanner:UpdateInfo()
    local tAdv   = Table_GetAdventureByID(self.dwAdventureID)
    local szPath = AdventureData.GetOpenRewardPath(tAdv)
    UIHelper.SetTexture(self.ImgBanner, szPath, false)

    local bHasTrigger = PartnerData.IsAdventureTriggered(self.dwAdventureID)
    UIHelper.SetVisible(self.ImgGet, bHasTrigger)
end

return UIPartnerTravelSettingBanner