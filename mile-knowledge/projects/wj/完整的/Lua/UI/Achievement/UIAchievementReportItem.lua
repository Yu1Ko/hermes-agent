-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementReportItem
-- Date: 2023-02-15 17:03:39
-- Desc: 隐元秘鉴 - 隐元秘档 - 单条信息widget
-- Prefab: WidgetAchievementReportContent
-- ---------------------------------------------------------------------------------

local UIAchievementReportItem = class("UIAchievementReportItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementReportItem:_LuaBindList()
    self.RichTextContent = self.RichTextContent --- 信息内容
end

function UIAchievementReportItem:OnEnter(szRichTextContent)
    self.szRichTextContent = szRichTextContent
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIAchievementReportItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementReportItem:BindUIEvent()

end

function UIAchievementReportItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementReportItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementReportItem:UpdateInfo()
    UIHelper.SetRichText(self.RichTextContent, self.szRichTextContent)
end

return UIAchievementReportItem