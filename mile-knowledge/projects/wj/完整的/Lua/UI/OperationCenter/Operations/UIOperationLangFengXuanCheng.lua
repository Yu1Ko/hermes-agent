-- ---------------------------------------------------------------------------------
-- Author: Kscc
-- Name: UIOperationLangFengXuanCheng
-- Date: 2026-04-03
-- Desc: 唐简传
-- ---------------------------------------------------------------------------------

local UIOperationLangFengXuanCheng = class("UIOperationLangFengXuanCheng")

function UIOperationLangFengXuanCheng:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    local tScriptTop = tComponentContext and tComponentContext.tScriptLayoutTop
    self.scriptTaskList = tScriptTop and tScriptTop[3] -- WidgetTaskList100
    if self.scriptTaskList and self.scriptTaskList.BtnTaskList then
        UIHelper.SetName(self.scriptTaskList.BtnTaskList, "BtnTaskList80_LangFeng")
        UIHelper.SetVisible(self.scriptTaskList.ImgRedPoint, not Storage.HuaELou.bClickTask_LangFengXuanCheng)
        UIHelper.BindUIEvent(self.scriptTaskList.BtnTaskList, EventType.OnTouchEnded, function()
            Storage.HuaELou.bClickTask_LangFengXuanCheng = true
            Storage.HuaELou.Dirty()
            UIHelper.SetVisible(self.scriptTaskList.ImgRedPoint, false)
            Event.Dispatch(EventType.OnClickLangFengXuanChengTask) -- 更新红点4401
        end)
    end
end

function UIOperationLangFengXuanCheng:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLangFengXuanCheng:BindUIEvent()

end

function UIOperationLangFengXuanCheng:RegEvent()

end

function UIOperationLangFengXuanCheng:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationLangFengXuanCheng:UpdateInfo()

end

return UIOperationLangFengXuanCheng
