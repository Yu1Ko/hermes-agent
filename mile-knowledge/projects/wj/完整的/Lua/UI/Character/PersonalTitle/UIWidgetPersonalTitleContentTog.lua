-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPersonalTitleContentTog
-- Date: 2023-03-09 09:57:17
-- Desc: WidgetPersonalTitleContentTog
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalTitleContentTog = class("UIWidgetPersonalTitleContentTog")

function UIWidgetPersonalTitleContentTog:OnEnter(tData, fnSelectedCallback)
    if not tData or type(tData) ~= "table" then return end

    self.tData = tData
    self.fnSelectedCallback = fnSelectedCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetPersonalTitleContentTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPersonalTitleContentTog:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPersonalTitleVontent, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end

        
        local nType = self.tData and self.tData.nType
        local dwID = self.tData and self.tData.dwID

        if nType == DESIGNATION_TYPE.COURTESY then
            RedpointHelper.PersonalTitle_SetNew(nil, nil, true, false)
        elseif nType == DESIGNATION_TYPE.POSTFIX then
            RedpointHelper.PersonalTitle_SetNew(nil, dwID, false, false)
        else
            RedpointHelper.PersonalTitle_SetNew(dwID, nil, false, false)
        end
    end)
end

function UIWidgetPersonalTitleContentTog:RegEvent()
    Event.Reg(self, EventType.OnDesignationNewUpdate, function()
        if not self.tData then
            return
        end
        
        local bIsNew = RedpointHelper.PersonalTitle_IsNew(self.tData)
        UIHelper.SetVisible(self.ImgRedPoint, bIsNew)
    end)
end

function UIWidgetPersonalTitleContentTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPersonalTitleContentTog:UpdateInfo()
    local tData = self.tData
    if not tData then return end

    UIHelper.SetVisible(self.Icon1, tData.bDisable)
    UIHelper.SetVisible(self.Icon2, tData.bTimeLimit)
    UIHelper.SetVisible(self.Icon3, tData.bIsEffect)
    UIHelper.LayoutDoLayout(self.LayoutIcon)

    UIHelper.SetString(self.LabelSelect, tData.szName)
    UIHelper.SetSpriteFrame(self.ImgQuality, PersonalTitleQualityBGColor[tData.nQuality + 1])
    UIHelper.SetVisible(self.ImgTips, tData.bEquip)
    UIHelper.SetVisible(self.ImgMask, not tData.bHave)
    self:RawSetSelected(tData.bSel)

    -- 红点
    local bIsNew = RedpointHelper.PersonalTitle_IsNew(tData)
    UIHelper.SetVisible(self.ImgRedPoint, bIsNew)
end

function UIWidgetPersonalTitleContentTog:RawSetSelected(bSelected)
    UIHelper.SetSelected(self.TogPersonalTitleVontent, bSelected, false)
end

return UIWidgetPersonalTitleContentTog