-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldNormalSmall_ButtonList
-- Date: 2022-12-27 16:01:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldNormalSmall_ButtonList = class("UIPlotDialogueOldNormalSmall_ButtonList")

function UIPlotDialogueOldNormalSmall_ButtonList:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIPlotDialogueOldNormalSmall_ButtonList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormalSmall_ButtonList:BindUIEvent()
    
end

function UIPlotDialogueOldNormalSmall_ButtonList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlotDialogueOldNormalSmall_ButtonList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormalSmall_ButtonList:UpdateInfo()
    for index, value in ipairs(self.tbData.tbSmallButtonList) do
        UIHelper.SetVisible(self.tbSmallButton[index], true)
        local scriptView = UIHelper.GetBindScript(self.tbSmallButton[index])
        scriptView:OnEnter(value)
    end
    UIHelper.LayoutDoLayout(self.LayoutOldDialogueContent)
end


return UIPlotDialogueOldNormalSmall_ButtonList