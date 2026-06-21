-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelTargetCell
-- Date: 2024-11-21 15:45:25
-- Desc: 侠客出行事件大类别
-- Prefab: WidgetPartnerTravelTargetCell
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelTargetCell
local UIPartnerTravelTargetCell = class("UIPartnerTravelTargetCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelTargetCell:_LuaBindList()
    self.ImgIcon   = self.ImgIcon --- 类别图标
    self.LabelName = self.LabelName --- 名称
    self.ImgLock   = self.ImgLock --- 未解锁时的图标
    self.BtnQuest  = self.BtnQuest --- 按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelTargetCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelTargetCell:OnEnter(nClass)
    self.nClass = nClass

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerTravelTargetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelTargetCell:BindUIEvent()

end

function UIPartnerTravelTargetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelTargetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local tClassToIconPath = {
    [1] = "UIAtlas2_Partner_ParterTravel_IconQiyu.png", -- 摸宠
    [2] = "UIAtlas2_Partner_ParterTravel_IconMijing.png", -- 秘境
    [3] = "UIAtlas2_Partner_ParterTravel_IconMingwang.png", -- 名望
    [4] = "UIAtlas2_Partner_ParterTravel_IconTongjian.png", -- 公共任务
    [5] = "UIAtlas2_Partner_ParterTravel_IconXiuxian.png", -- 茶馆
}

function UIPartnerTravelTargetCell:UpdateInfo()
    local tInfo           = Table_GetPartnerTravelClass(self.nClass)

    local szTypeName      = UIHelper.GBKToUTF8(tInfo.szClassName)
    local _, nCount, nMax = PartnerData.GetTravelCountInfo(tInfo.nDataIndex)
    local szLimitType
    if tInfo.nLimitType == 1 then
        szLimitType = "今日"
    else
        szLimitType = "本周"
    end

    UIHelper.SetString(self.LabelName, string.format("%s（%s%d/%d）", szTypeName, szLimitType, nCount, nMax))

    if tClassToIconPath[self.nClass] then
        local szIconPath = tClassToIconPath[self.nClass]
        UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)
    end

    -- todo: 需要增加解锁相关的配置
end

return UIPartnerTravelTargetCell