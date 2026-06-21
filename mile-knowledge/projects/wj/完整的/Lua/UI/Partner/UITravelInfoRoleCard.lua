-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelInfoRoleCard
-- Date: 2024-12-14 22:14:49
-- Desc: 侠客出行的侠客卡片
-- Prefab: WidgetTravelInfoRoleCard
-- ---------------------------------------------------------------------------------

---@class UITravelInfoRoleCard
local UITravelInfoRoleCard = class("UITravelInfoRoleCard")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelInfoRoleCard:_LuaBindList()
    self.ImgRoleIcon         = self.ImgRoleIcon --- 侠客图标
    self.ImgRarityBackGround = self.ImgRarityBackGround --- 侠客稀有度背景
    self.ImgKungfu           = self.ImgKungfu --- 心法图标
    self.LabelName           = self.LabelName --- 侠客名称

    self.ImgLimit            = self.ImgLimit --- 限定标记
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelInfoRoleCard:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tInfo PartnerNpcInfo
function UITravelInfoRoleCard:OnEnter(tInfo)
    self.tInfo = tInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITravelInfoRoleCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelInfoRoleCard:BindUIEvent()

end

function UITravelInfoRoleCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelInfoRoleCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelInfoRoleCard:UpdateInfo()
    local tInfo = self.tInfo
    if tInfo then
        local szImgPath = tInfo.szAvatarImg
        UIHelper.SetSpriteFrame(self.ImgRoleIcon, szImgPath)

        local nQuality  = tInfo.nQuality
        local szBgImage = PartnerRarityToTravelBgImage[nQuality]
        UIHelper.SetSpriteFrame(self.ImgRarityBackGround, szBgImage)

        local nKungfuIndex = tInfo.nKungfuIndex
        UIHelper.SetSpriteFrame(self.ImgKungfu, PartnerKungfuIndexToImg[nKungfuIndex])

        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tInfo.szName))
        
        UIHelper.SetVisible(self.ImgLimit, PartnerData.NeedShowLimitedTips(tInfo.dwID))
    end
end

return UITravelInfoRoleCard