-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractionMoreTog
-- Date: 2022-11-16 19:03:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractionMoreTog = class("UIInteractionMoreTog")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIInteractionMoreTog:_LuaBindList()
    self.Toggle = self.Toggle --- 可展开按钮组件
    self.LableMpore = self.LableMpore --- 按钮文字
end

function UIInteractionMoreTog:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIInteractionMoreTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractionMoreTog:BindUIEvent()
    
end

function UIInteractionMoreTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInteractionMoreTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionMoreTog:UpdateInfo()
    
end


return UIInteractionMoreTog
