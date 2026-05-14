-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetQteSkill
-- Date: 2023-01-03 15:19:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetQteSkill = class("UIWidgetQteSkill")

function UIWidgetQteSkill:OnEnter(tbSkillInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbSkillInfo then
        self.tbSkillInfo = tbSkillInfo
        self:UpdateInfo()
    end
end

function UIWidgetQteSkill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetQteSkill:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnClick, function()
        if self.tbSkillInfo then
            self.tbSkillInfo.callback()
        end
    end)
end

function UIWidgetQteSkill:RegEvent()
    Event.Reg(self, EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, function(nSkillID, bHighlight)
        if not self.tbSkillInfo then return end
        if nSkillID == self.tbSkillInfo.nSkillID then
            self:UpdateButtonState(bHighlight)
            if not bHighlight then 
                self.tbSkillInfo = nil--不高亮后清除数据
            end
        end
    end)

end

function UIWidgetQteSkill:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQteSkill:UpdateInfo()
    local szImgPath =  self.tbSkillInfo.szImgPath
    UIHelper.SetTexture(self.ImgSkillIcon, szImgPath)
    self:UpdateButtonState(true)
end

function UIWidgetQteSkill:UpdateButtonState(bHighlight)
    UIHelper.SetVisible(self.WidgetAniLight, bHighlight)
    UIHelper.SetVisible(self._rootNode, bHighlight)
end

return UIWidgetQteSkill