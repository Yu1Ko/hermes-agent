-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangResultData
-- Date: 2024-01-25 19:24:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangResultData = class("UIWidgetBahuangResultData")

function UIWidgetBahuangResultData:OnEnter(szTitle, szNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = szTitle
    self.szNum = szNum
    self:UpdateInfo()
end

function UIWidgetBahuangResultData:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangResultData:BindUIEvent()
    
end

function UIWidgetBahuangResultData:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangResultData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangResultData:UpdateInfo()
    UIHelper.SetString(self.LabelResultTitle, self.szTitle)
    UIHelper.SetString(self.LabelResultContent, self.szNum)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIWidgetBahuangResultData