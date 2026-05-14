-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestDescComp
-- Date: 2022-11-24 11:37:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestDescComp = class("UIQuestDescComp")

function UIQuestDescComp:OnEnter(tbQuestConfig)
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

function UIQuestDescComp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestDescComp:BindUIEvent()
    
end

function UIQuestDescComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestDescComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIQuestDescComp:Init(tbQuestConfig)
    self.tbQuestConfig = tbQuestConfig
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestDescComp:UpdateInfo()
    local szQuestDesc = ""
    if self.tbQuestConfig then
         szQuestDesc = self.tbQuestConfig.szDescription
    end
    szQuestDesc = ParseTextHelper.ParseQuestDesc(szQuestDesc)
    UIHelper.SetRichText(self.RichTextDetail, szQuestDesc)
    UIHelper.LayoutDoLayout(self.LayoutDetail)
end


return UIQuestDescComp