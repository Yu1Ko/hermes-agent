-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGuideNew
-- Date: 2026-04-02 20:21:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationGuideNew = class("UIOperationGuideNew")

function UIOperationGuideNew:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    local tScriptTop = tComponentContext and tComponentContext.tScriptLayoutTop
    local tScriptBottom = tComponentContext and tComponentContext.tScriptLayoutBottom
    self.scriptQRCode = tScriptTop and tScriptTop[3] --WidgetQRcode's script
    self.scriptRewardList = tScriptBottom and tScriptBottom[1] --WidgetLayOutRewardList's script
    self.scriptNewReward =  tScriptBottom and tScriptBottom[2] --WidgetMengXinReward's script

    self:UpdateInfo()
end

function UIOperationGuideNew:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationGuideNew:BindUIEvent()

end

function UIOperationGuideNew:RegEvent()
end

function UIOperationGuideNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationGuideNew:UpdateInfo()
    if not Platform.IsMobile() then
        local scriptCenter = self.tComponentContext and self.tComponentContext.scriptCenter
        scriptCenter:HideButton()
    end
end

return UIOperationGuideNew