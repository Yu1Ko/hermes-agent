-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldNormalSmall_Button
-- Date: 2022-12-27 15:56:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldNormalSmall_Button = class("UIPlotDialogueOldNormalSmall_Button")

function UIPlotDialogueOldNormalSmall_Button:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIPlotDialogueOldNormalSmall_Button:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormalSmall_Button:BindUIEvent()
    if self.ToggleSelect then
        UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(btn, bSelected)
            self.tbData.callback()
        end)
    else
        UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function(btn)
            self.tbData.callback()
        end)
        UIHelper.SetSwallowTouches(self._rootNode, false)
    end
end

function UIPlotDialogueOldNormalSmall_Button:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlotDialogueOldNormalSmall_Button:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormalSmall_Button:UpdateInfo()
    UIHelper.SetTexture(self.ImgIcon, self.tbData.szIconName)
end


return UIPlotDialogueOldNormalSmall_Button