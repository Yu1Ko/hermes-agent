-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPersonalTitleContentDoubleTog
-- Date: 2023-03-09 09:57:17
-- Desc: WidgetPersonalTitleContentTog
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalTitleContentDoubleTog = class("UIWidgetPersonalTitleContentDoubleTog")

function UIWidgetPersonalTitleContentDoubleTog:OnEnter(tDataLeft, tDataRight, fnSelectedCallbackLeft, fnSelectedCallbackRight)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptTog1 = UIHelper.GetBindScript(self.WidgetPersonalTitleContentTog1)
        self.scriptTog2 = UIHelper.GetBindScript(self.WidgetPersonalTitleContentTog2)
        self.scriptTog3 = UIHelper.GetBindScript(self.WidgetPersonalTitleContentTog3)
    end
end

function UIWidgetPersonalTitleContentDoubleTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPersonalTitleContentDoubleTog:BindUIEvent()
    
end

function UIWidgetPersonalTitleContentDoubleTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPersonalTitleContentDoubleTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPersonalTitleContentDoubleTog:UpdateInfo(tData1, tData2, tData3, fnSelectedCallback1, fnSelectedCallback2, fnSelectedCallback3)
    if tData1 and self.scriptTog1 then
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog1, true)
        self.scriptTog1:OnEnter(tData1, fnSelectedCallback1)
    else
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog1, false)
    end
    if tData2 and self.scriptTog2 then
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog2, true)
        self.scriptTog2:OnEnter(tData2, fnSelectedCallback2)
    else
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog2, false)
    end
    if tData3 and self.scriptTog3 then
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog3, true)
        self.scriptTog3:OnEnter(tData3, fnSelectedCallback3)
    else
        UIHelper.SetVisible(self.WidgetPersonalTitleContentTog3, false)
    end
end


return UIWidgetPersonalTitleContentDoubleTog