-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestMessageComp
-- Date: 2022-11-24 11:40:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestMessageComp = class("UIQuestMessageComp")

function UIQuestMessageComp:OnEnter(tbQuestConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbQuestConfig then
        self:Init(tbQuestConfig)
        self:UpdateInfo()
    end
end

function UIQuestMessageComp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestMessageComp:BindUIEvent()

end

function UIQuestMessageComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestMessageComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIQuestMessageComp:Init(tbQuestConfig)
    self.tbQuestConfig = tbQuestConfig
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestMessageComp:UpdateInfo()
    local szQuestMessage = ""
    if self.tbQuestConfig then
        szQuestMessage = self.tbQuestConfig.szObjective
    end
    szQuestMessage = ParseTextHelper.ParseQuestDesc(szQuestMessage)
    local szIdentityDesc = QuestData.GetIdentityDesc(self.tbQuestConfig.nID)
    if not string.is_nil(szIdentityDesc) then
        szQuestMessage = szQuestMessage .. "\n\n" .. szIdentityDesc
    end
    UIHelper.SetRichText(self.RichTextMessage, szQuestMessage, true)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIQuestMessageComp