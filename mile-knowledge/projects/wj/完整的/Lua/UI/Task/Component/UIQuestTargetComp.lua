-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestTargetComp
-- Date: 2022-11-24 11:33:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestTargetComp = class("UIQuestTargetComp")

function UIQuestTargetComp:OnEnter(tbQuestConfig, bShowObjective)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbQuestConfig then
        self:Init(tbQuestConfig, bShowObjective)
        self:UpdateInfo()
    end
end

function UIQuestTargetComp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestTargetComp:BindUIEvent()

end

function UIQuestTargetComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestTargetComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UIQuestTargetComp:Init(tbQuestConfig, bShowObjective)
    self.tbQuestConfig = tbQuestConfig
    self.bShowObjective = bShowObjective or false
    self:UpdateTarget(self.tbQuestConfig.nID)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestTargetComp:UpdateInfo()
    if self.tbQuestConfig then

        local szQuestMessage = ""
        if self.bShowObjective then 
            szQuestMessage = ParseTextHelper.ParseQuestDesc(self.tbQuestConfig.szObjective)
        end

        local szTarget = QuestData.GetQuestTime(self.tbQuestConfig.nID)
        local szNewLine = string.is_nil(szTarget) and "" or "\n"
        szTarget = szQuestMessage..(string.is_nil(szQuestMessage) and "" or "\n")..szTarget..szNewLine..self.szTarget

        local szItemTip = QuestData.GetQuestItemTip(self.tbQuestConfig.nID)
        if not string.is_nil(szItemTip) then
            szTarget = szTarget .. "\n" .. szItemTip
        end
        
        UIHelper.SetRichText(self.RichTextTarget, szTarget)
        UIHelper.SetVisible(self.LayoutTarget, szTarget ~= "")
    end

    UIHelper.LayoutDoLayout(self.LayoutTargetText)
    UIHelper.LayoutDoLayout(self.LayoutTarget)
end

function UIQuestTargetComp:UpdateTarget(nQuestID)
    -- if self.nCurQuestID == nil or self.nCurQuestID ~= nQuestID then 
        self.nCurQuestID = nQuestID
        self.szTarget = QuestData.GetQuestTargetStringList(self.nCurQuestID)
    -- end
end

return UIQuestTargetComp