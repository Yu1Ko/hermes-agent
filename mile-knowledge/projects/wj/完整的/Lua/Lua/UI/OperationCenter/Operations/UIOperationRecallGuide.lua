-- ---------------------------------------------------------------------------------
-- Author: Kscc
-- Name: UIOperationRecallGuide
-- Date: 2026-04-03
-- Desc: 回归接引人活动（dwOperatActID=229）
-- 手机端显示"前往微信添加"按钮，Windows端显示二维码
-- ---------------------------------------------------------------------------------

local UIOperationRecallGuide = class("UIOperationRecallGuide")

function UIOperationRecallGuide:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    local tScriptTop = tComponentContext and tComponentContext.tScriptLayoutTop
    self.scriptLabelContent = tScriptTop and tScriptTop[2] -- WidgetLabelContent
    self.scriptQRCode = tScriptTop and tScriptTop[3]       -- WidgetQRcode

    self:UpdateInfo()
end

function UIOperationRecallGuide:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationRecallGuide:BindUIEvent()

end

function UIOperationRecallGuide:RegEvent()

end

function UIOperationRecallGuide:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationRecallGuide:UpdateInfo()
    if not Platform.IsMobile() then
        local scriptCenter = self.tComponentContext and self.tComponentContext.scriptCenter
        scriptCenter:HideButton()
    end
end

return UIOperationRecallGuide
