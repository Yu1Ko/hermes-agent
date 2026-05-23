-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieStudioLineCell
-- Date: 2025-03-12 09:58:48
-- Desc: 
-- ---------------------------------------------------------------------------------

local UISelfieStudioLineCell = class("UISelfieStudioLineCell")

function UISelfieStudioLineCell:OnEnter(nLineIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nLineIndex = nLineIndex
    self:UpdateInfo()
end

function UISelfieStudioLineCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieStudioLineCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogtCameraStudioLine1 , EventType.OnClick , function ()
        if self.bSelect then
            return
        end
        Event.Dispatch(EventType.OnSelfieStudioLineCellSelect, self.nLineIndex)
        self:SetSelected(true)
    end)
    
end

function UISelfieStudioLineCell:RegEvent()
    Event.Reg(self, EventType.OnSelfieStudioLineCellSelect, function (nLineIndex, bUpdate)
        if self.bSelect and nLineIndex ~= self.nLineIndex then
            self:SetSelected(false)
        end
        if nLineIndex == self.nLineIndex and bUpdate then
            self:SetSelected(true)
        end
    end)

    Event.Reg(self, EventType.OnSelfieStudioLineCellEnable, function (bEnable)
        self:SetEnable(bEnable)
    end)
end

function UISelfieStudioLineCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieStudioLineCell:UpdateInfo()
    if self.nLineIndex then
        UIHelper.SetString(self.LabelNormalDefault,  string.format(g_tStrings.STR_SELFIE_STUDIO_LINE, self.nLineIndex) )
        UIHelper.SetString(self.LabelDefault01,  string.format(g_tStrings.STR_SELFIE_STUDIO_LINE, self.nLineIndex) )
    else
        UIHelper.SetString(self.LabelNormalDefault,  g_tStrings.STR_SELFIE_STUDIO_RANDOM)
    UIHelper.SetString(self.LabelDefault01,  g_tStrings.STR_SELFIE_STUDIO_RANDOM)
    end
    
end

function UISelfieStudioLineCell:SetSelected(bSelect)
    self.bSelect = bSelect
    for k, v in pairs(self.tbSelectedObj) do
        UIHelper.SetVisible(v, bSelect)
    end
end

function UISelfieStudioLineCell:SetEnable(bEnable)
    UIHelper.SetCanSelect(self.TogtCameraStudioLine1, bEnable)
end
return UISelfieStudioLineCell