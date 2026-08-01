-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITouchBackGround
-- Date: 2022-11-22 10:25:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITouchBackGround = class("UITouchBackGround")

function UITouchBackGround:OnEnter(bTouchMaskCloseView, scriptView)
    self.bTouchMaskCloseView = bTouchMaskCloseView
    self.scriptView = scriptView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITouchBackGround:OnExit()
    self.bInit = false
end

function UITouchBackGround:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBackGround, EventType.OnClick, function()
        if self.scriptView.TryBackGroundTouchClose and not self.scriptView:TryBackGroundTouchClose() then
            return
        end

        if self.bTouchMaskCloseView and self.scriptView then
            UIHelper.RemoveFromParent(self._rootNode) -- 特殊需求（如仓库）需要在界面关闭时移除WidgetTouchBackGround
            UIMgr.Close(self.scriptView)
        end

        Event.Dispatch(EventType.OnTouchViewBackGround, self.scriptView)
    end)

    UIHelper.SetButtonClickSound(self.BtnBackGround, "")
end

function UITouchBackGround:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITouchBackGround:UpdateInfo()

end

function UITouchBackGround:SetTouchDownHideTips(nPrefabID)
    UIHelper.SetTouchDownHideTips(self.BtnBackGround, false)
    UIHelper.BindUIEvent(self.BtnBackGround, EventType.OnClick, function()
        TipsHelper.DeleteHoverTips(nPrefabID)
    end)
    self.bInit = true
end

function UITouchBackGround:SetSwallowTouches(bSwallowTouch)
    UIHelper.SetSwallowTouches(self.BtnBackGround, bSwallowTouch)
    UIHelper.SetVisible(self.BtnBackGroundUseLess, bSwallowTouch)
end

return UITouchBackGround