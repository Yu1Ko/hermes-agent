-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerXunFangFrameTog
-- Date: 2024-02-29 20:01:58
-- Desc: 侠客抽卡-小头像
-- Prefab: WidgetPartnerXunFangFrameTog
-- ---------------------------------------------------------------------------------

---@class UIPartnerXunFangFrameTog
local UIPartnerXunFangFrameTog = class("UIPartnerXunFangFrameTog")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerXunFangFrameTog:_LuaBindList()
    self.ToggleSelect        = self.ToggleSelect --- 选择的toggle
    self.ImgPartnerIcon      = self.ImgPartnerIcon --- 侠客头像
    self.ImgPartnerMeetState = self.ImgPartnerMeetState --- 侠客是否已结缘的标记图片
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerXunFangFrameTog:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tDrawInfo PartnerDrawInfo
function UIPartnerXunFangFrameTog:OnEnter(tDrawInfo)
    self.tDrawInfo = tDrawInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerXunFangFrameTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerXunFangFrameTog:BindUIEvent()

end

function UIPartnerXunFangFrameTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerXunFangFrameTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerXunFangFrameTog:UpdateInfo()
    local tDrawInfo = self.tDrawInfo
    local tInfo     = Table_GetPartnerNpcInfo(self.tDrawInfo.dwID)

    local szImgPath = tInfo.szSmallAvatarImg
    UIHelper.SetTexture(self.ImgPartnerIcon, szImgPath)

    local bInTaskOrMeet = tDrawInfo.nState == PartnerDrawState.InTask or tDrawInfo.nState == PartnerDrawState.Meet
    UIHelper.SetVisible(self.ImgPartnerMeetState, bInTaskOrMeet)
end

return UIPartnerXunFangFrameTog