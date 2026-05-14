-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPublicLabelTips
-- Date: 2023-02-27 16:43:33
-- Desc: 通用文本提示widget
-- Prefab: WidgetPublicLabelTips
-- ---------------------------------------------------------------------------------

---@class UIPublicLabelTips
local UIPublicLabelTips = class("UIPublicLabelTips")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPublicLabelTips:_LuaBindList()
    self.LabelTips = self.LabelTips --- 文本内容
end

function UIPublicLabelTips:OnEnter(szName)
    self.szName = szName

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetTouchEnabled(self._rootNode , true)
    UIHelper.SetTouchDownHideTips(self._rootNode , false)
    self:UpdateInfo()
end

function UIPublicLabelTips:OnExit()
    if self.fnExit then
        self.fnExit()
    end
    self.bInit = false
    self:UnRegEvent()
end

function UIPublicLabelTips:BindUIEvent()

end

function UIPublicLabelTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPublicLabelTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPublicLabelTips:UpdateInfo()
    UIHelper.SetRichText(self.LabelTips, self.szName)
    UIHelper.LayoutDoLayout(self.ImgPublicLabelTips)
    UIHelper.LayoutDoLayout(self.WidgetPublicLabelTips)
end

function UIPublicLabelTips:BindExitFunc(fnFunc)
    if IsFunction(fnFunc) then
        self.fnExit = fnFunc
    end
    
end
return UIPublicLabelTips