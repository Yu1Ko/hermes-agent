-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionActivityTitle
-- Date: 2023-05-16 16:33:58
-- Desc: 帮会活动-概览-状态标题
-- Prefab: WidgetFactionActivityTitle
-- ---------------------------------------------------------------------------------

local UIFactionActivityTitle = class("UIFactionActivityTitle")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionActivityTitle:_LuaBindList()
    self.LabelActivityState = self.LabelActivityState --- 活动状态标题
end

function UIFactionActivityTitle:OnEnter(szState)
    self.szState = szState

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFactionActivityTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionActivityTitle:BindUIEvent()

end

function UIFactionActivityTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFactionActivityTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionActivityTitle:UpdateInfo()
    UIHelper.SetString(self.LabelActivityState, self.szState)
end

return UIFactionActivityTitle