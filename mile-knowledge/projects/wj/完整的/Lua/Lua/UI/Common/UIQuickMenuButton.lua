-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIQuickMenuButton
-- Date: 2023-06-08 10:00:12
-- Desc: UI PageView 上快速打开系统菜单的按钮
-- ---------------------------------------------------------------------------------

local UIQuickMenuButton = class("UIQuickMenuButton")

function UIQuickMenuButton:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIQuickMenuButton:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuickMenuButton:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMenuChange, EventType.OnClick, function(btn)
        -- local script = UIHelper.GetBindScript(self.root)
        -- local nViewID = script and script._nViewID
        
        -- UIMgr.Open(VIEW_ID.PanelSystemMenuOpenByQuickBtn, true, nViewID)
    end)
end

function UIQuickMenuButton:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuickMenuButton:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickMenuButton:UpdateInfo()
    
end


return UIQuickMenuButton