-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationLabelContent
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationLabelContent = class("UIOperationLabelContent")

function UIOperationLabelContent:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationLabelContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationLabelContent:BindUIEvent()

end

function UIOperationLabelContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationLabelContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ---------------------------------------------------------

function UIOperationLabelContent:UpdateInfo()
    local tActivity = UIHuaELouActivityTab[self.nID]
    if not tActivity then
        return
    end

    local nMaxWidth = tActivity.nLayoutStyle == 1 and 420 or 540
    local tInfo = OperationCenterData.GetOperationInfo(self.nOperationID)
    local szText = ParseTextHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(tInfo.szBriefDesc), true)
    UIHelper.SetWidth(self.WidgetLabelContent, nMaxWidth)
    UIHelper.SetRichText(self.WidgetLabelContent, szText)
end

function UIOperationLabelContent:SetContent(text)
    if text then
        UIHelper.SetRichText(self.WidgetLabelContent, text)
    end
end


return UIOperationLabelContent
