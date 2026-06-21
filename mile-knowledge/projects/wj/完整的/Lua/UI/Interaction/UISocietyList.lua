-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISocietyList
-- Date: 2024-01-30 16:16:25
-- Desc: WidgetInteractionContent/.../WidgetSocietyList
-- ---------------------------------------------------------------------------------

---@class UISocietyList
local UISocietyList = class("UISocietyList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UISocietyList:_LuaBindList()
    self.LableHelp            = self.LableHelp --- 帮会等级
    self.ImgCamp              = self.ImgCamp --- 帮会阵营图标
    self.LableCut             = self.LableCut --- 帮会名称
    self.LayoutContent_Big    = self.LayoutContent_Big --- 帮会成员列表的layout
    self.WidgetSocietyList    = self.WidgetSocietyList --- 根节点的layout
    self.WidgetSocietyMessage = self.WidgetSocietyMessage --- 帮会信息组件兼按钮
    self.LableEmptyGuide      = self.LableEmptyGuide --- 跨服提示语
    self.BtnOpenTongWhisper   = self.BtnOpenTongWhisper --- 打开帮会群密界面
end

function UISocietyList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.LayoutDoLayout(self.WidgetSocietyList)
end

function UISocietyList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISocietyList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOpenTongWhisper, EventType.OnClick, function()
        self:OpenTongWhisper()
    end)
end

function UISocietyList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISocietyList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISocietyList:UpdateInfo()

end

function UISocietyList:OpenTongWhisper()
    JX_TongWhisper.OpenTongWhisper()
end

return UISocietyList