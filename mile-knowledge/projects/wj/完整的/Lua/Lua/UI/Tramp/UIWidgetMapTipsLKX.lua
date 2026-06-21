-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMapTipsLKX
-- Date: 2023-04-17 10:55:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMapTipsLKX = class("UIWidgetMapTipsLKX")

function UIWidgetMapTipsLKX:OnEnter(szTitle, szDesc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = szTitle
    self.szDesc = szDesc
    self:UpdateInfo()
end

function UIWidgetMapTipsLKX:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMapTipsLKX:BindUIEvent()
    
end

function UIWidgetMapTipsLKX:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMapTipsLKX:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMapTipsLKX:UpdateInfo()
    UIHelper.SetVisible(self.WidgetTitle, self.szTitle ~= nil)
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetRichText(self.RichTextMessage, self.szDesc)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutDetail, true, true)
end


return UIWidgetMapTipsLKX