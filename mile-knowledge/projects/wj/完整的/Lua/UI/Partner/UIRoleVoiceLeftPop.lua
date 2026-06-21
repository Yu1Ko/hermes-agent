-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIRoleVoiceLeftPop
-- Date: 2023-04-06 15:30:40
-- Desc: 侠客-传记左侧栏
-- Prefab: WidgetRoleVoiceLeftPop
-- ---------------------------------------------------------------------------------

local UIRoleVoiceLeftPop = class("UIRoleVoiceLeftPop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIRoleVoiceLeftPop:_LuaBindList()
    self.LabelTitle        = self.LabelTitle --- 标题
    self.LabelContent      = self.LabelContent --- 内容

    self.BtnMask           = self.BtnMask --- 遮罩按钮，点击后隐藏侧边栏

    self.ScrollViewContent = self.ScrollViewContent --- 内容的scrollview

    self.BtnCloseLeft      = self.BtnCloseLeft --- 点击后隐藏侧边栏
end

function UIRoleVoiceLeftPop:OnEnter(dwID, szTitle, szContent)
    self.dwID      = dwID
    self.szTitle   = szTitle
    self.szContent = szContent

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRoleVoiceLeftPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoleVoiceLeftPop:BindUIEvent()

end

function UIRoleVoiceLeftPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRoleVoiceLeftPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoleVoiceLeftPop:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetString(self.LabelContent, self.szContent)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

return UIRoleVoiceLeftPop