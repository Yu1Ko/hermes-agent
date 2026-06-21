-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILeaveForTipsBtn
-- Date: 2023-05-24 17:48:00
-- Desc: 帮会-导航按钮
-- Prefab: WidgetLeaveForTipsBtn
-- ---------------------------------------------------------------------------------

local UILeaveForTipsBtn = class("UILeaveForTipsBtn")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILeaveForTipsBtn:_LuaBindList()
    self.LableLeaveFor = self.LableLeaveFor --- 目标名称
    self.BtnLeaveFor   = self.BtnLeaveFor --- 打开导航按钮
end

function UILeaveForTipsBtn:OnEnter(szTargetName)
    self.szTargetName = szTargetName
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UILeaveForTipsBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILeaveForTipsBtn:BindUIEvent()

end

function UILeaveForTipsBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILeaveForTipsBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILeaveForTipsBtn:UpdateInfo()
    UIHelper.SetString(self.LableLeaveFor, self.szTargetName)
end

return UILeaveForTipsBtn