-- ---------------------------------------------------------------------------------
-- Author: Kscc
-- Name: UIOperationTangJianZhuan
-- Date: 2026-04-03
-- Desc: 唐简传
-- ---------------------------------------------------------------------------------

local UIOperationTangJianZhuan = class("UIOperationTangJianZhuan")

function UIOperationTangJianZhuan:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    local tScriptBottom = tComponentContext and tComponentContext.tScriptLayoutBottom
    self.scriptTaskList = tScriptBottom and tScriptBottom[1] -- WidgetLayOutRewardList

    self:UpdateInfo()
end

function UIOperationTangJianZhuan:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationTangJianZhuan:BindUIEvent()

end

function UIOperationTangJianZhuan:RegEvent()

end

function UIOperationTangJianZhuan:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationTangJianZhuan:UpdateInfo()
    if not self.scriptTaskList then
        return
    end

    local nCurValue, nTotalValue = GDAPI_GetTJGJQuestProgress(GetClientPlayer())
    local szProgress = nCurValue .. "/" .. nTotalValue

    UIHelper.SetString(self.scriptTaskList.LabelMiniTitle, "唐简传任务进度")
    UIHelper.SetString(self.scriptTaskList.LabelMiniTitleCountOrHint, szProgress)
    UIHelper.SetVisible(self.scriptTaskList.LabelMiniTitleCountOrHint, true)
end

return UIOperationTangJianZhuan
