-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetContentCityHistory
-- Date: 2023-07-31 11:35:03
-- Desc: WidgetContentCityHistory 据点历史/阵营大事记-具体内容
-- ---------------------------------------------------------------------------------

local UIWidgetContentCityHistory = class("UIWidgetContentCityHistory")

function UIWidgetContentCityHistory:OnEnter(szTime, szContent)
    self.szTime = szTime or ""
    self.szContent = szContent or ""

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetContentCityHistory:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetContentCityHistory:BindUIEvent()
    
end

function UIWidgetContentCityHistory:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetContentCityHistory:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetContentCityHistory:UpdateInfo()
    local szTime = self.szTime
    local szContent = self.szContent

    UIHelper.SetString(self.LabelCityTime, szTime)
    UIHelper.SetRichText(self.LabelCityTeam, szContent)
end


return UIWidgetContentCityHistory