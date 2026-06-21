-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIPageBottomBar
-- Date: 2023-11-14 15:55:18
-- Desc: 该脚本可以监听OnShowPageBottomBar、OnHidePageBottomBar事件，显示和隐藏界面底部导航UI
-- ---------------------------------------------------------------------------------

local UIPageBottomBar = class("UIPageBottomBar")

function UIPageBottomBar:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nHideAnimCount = 0
    self.scriptRoot = UIHelper.GetBindScript(self.RootNode)
end

function UIPageBottomBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPageBottomBar:BindUIEvent()

end

function UIPageBottomBar:RegEvent()
    Event.Reg(self, EventType.OnShowPageBottomBar, function(callback)
        self:PlayShow(callback)
    end)

    Event.Reg(self, EventType.OnHidePageBottomBar, function(callback)
        self:PlayHide(callback)
    end)
end

function UIPageBottomBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPageBottomBar:UpdateInfo()

end

function UIPageBottomBar:PlayShow(callback)
    if not self.AniAll then
        Lib.SafeCall(callback)
        return
    end

    if not self.scriptRoot then
        Lib.SafeCall(callback)
        return
    end

    self.nHideAnimCount = self.nHideAnimCount - 1
    if self.nHideAnimCount > 0 then
        Lib.SafeCall(callback)
        return
    end

    UIHelper.PlayAni(self.scriptRoot, self.AniAll, "AniBottomShow", callback)
end

function UIPageBottomBar:PlayHide(callback)
    if not self.AniAll then
        Lib.SafeCall(callback)
        return
    end

    if not self.scriptRoot then
        Lib.SafeCall(callback)
        return
    end

    self.nHideAnimCount = self.nHideAnimCount + 1
    if self.nHideAnimCount > 1 then
        Lib.SafeCall(callback)
        return
    end

    UIHelper.PlayAni(self.scriptRoot, self.AniAll, "AniBottomHide", callback)
end


return UIPageBottomBar