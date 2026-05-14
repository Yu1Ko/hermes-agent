-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieAIGeneratedModuleView
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
local UISelfieAIGeneratedModuleView = class("UISelfieAIGeneratedModuleView")

function UISelfieAIGeneratedModuleView:OnEnter(motionType, fnSelect, fnPlay, fnDeleted)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.motionType = motionType
    self.fnSelect = fnSelect
    self.fnPlay = fnPlay
    self.fnDeleted = fnDeleted
    self:UpdateInfo()
    
end

function UISelfieAIGeneratedModuleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    AiBodyMotionData.StopAIAction()
    AiBodyMotionData.StopFaceMotion()
end

function UISelfieAIGeneratedModuleView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCheckBox, EventType.OnSelectChanged, function (_,bSelected)
        if self.fnSelect then
            self.fnSelect(self.motionType,bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlay, EventType.OnClick, function ()
        if self.fnPlay then
            self.fnPlay(self.motionType)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        if self.fnDeleted then
            self.fnDeleted(self.motionType, self.szName)
        end
    end)
end

function UISelfieAIGeneratedModuleView:RegEvent()

end

function UISelfieAIGeneratedModuleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieAIGeneratedModuleView:UpdateInfo()
    if self.motionType ==  AI_MOTION_TYPE.BODY then
        UIHelper.SetString(self.LabelName, g_tStrings.STR_SELFIE_AI_BODY_ACT)
        UIHelper.SetSpriteFrame(self.ImgIcon, SelfieOneClickModeData.szBodyActionSprite)
    elseif self.motionType ==  AI_MOTION_TYPE.FACE then
        UIHelper.SetString(self.LabelName, g_tStrings.STR_SELFIE_AI_FACE_ACT)
        UIHelper.SetSpriteFrame(self.ImgIcon, SelfieOneClickModeData.szFaceActionSprite)
    end
    UIHelper.SetSelected(self.TogCheckBox, true)
end

function UISelfieAIGeneratedModuleView:SetTogCheckBoxVisible(bVisible)
    UIHelper.SetVisible(self.TogCheckBox, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UISelfieAIGeneratedModuleView:SetLabelName(szName)
    self.szName = szName
    UIHelper.SetString(self.LabelName, szName)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UISelfieAIGeneratedModuleView:SetDeletedVisible(bVisible)
    UIHelper.SetVisible(self.BtnDelete, bVisible)
end

function UISelfieAIGeneratedModuleView:SetPlayVisible(bVisible)
    UIHelper.SetVisible(self.BtnPlay, bVisible)
end
return UISelfieAIGeneratedModuleView