-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIActivityDetailCell
-- Date: 2023-05-23 14:54:25
-- Desc: 帮会活动-详情子条目组件
-- Prefab: WidgetActivityDetailCell
-- ---------------------------------------------------------------------------------

---@class UIActivityDetailCell
local UIActivityDetailCell = class("UIActivityDetailCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIActivityDetailCell:_LuaBindList()
    self.LabelTargetTitle = self.LabelTargetTitle --- 标题
    self.RichTextDesc     = self.RichTextDesc --- 具体内容
end

function UIActivityDetailCell:OnEnter(szTitle, szRichTextDesc, nSubClassID)
    self.szTitle        = szTitle
    self.szRichTextDesc = szRichTextDesc
    self.nSubClassID    = nSubClassID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIActivityDetailCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIActivityDetailCell:BindUIEvent()

end

function UIActivityDetailCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIActivityDetailCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIActivityDetailCell:UpdateInfo()
    UIHelper.SetString(self.LabelTargetTitle, self.szTitle)
    UIHelper.SetRichText(self.RichTextDesc, self.szRichTextDesc)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIActivityDetailCell