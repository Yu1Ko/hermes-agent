-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractionMoreBtn
-- Date: 2022-11-16 15:29:56
-- Desc: 这个脚本仅用于将 button和 label 绑定到脚本对象上，实际数据变更在 UIPlayerPop 中去处理
-- ---------------------------------------------------------------------------------

local UIInteractionMoreBtn = class("UIInteractionMoreBtn")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIInteractionMoreBtn:_LuaBindList()
    self.Btn = self.Btn --- 按钮
    self.LableMpore = self.LableMpore --- 按钮文字
end

function UIInteractionMoreBtn:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIInteractionMoreBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractionMoreBtn:BindUIEvent()
    
end

function UIInteractionMoreBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInteractionMoreBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionMoreBtn:UpdateInfo()
end


return UIInteractionMoreBtn