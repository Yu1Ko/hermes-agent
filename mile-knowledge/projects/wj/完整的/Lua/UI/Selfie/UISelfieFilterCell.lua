-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieFilterCell
-- Date: 2023-05-04 15:14:10
-- Desc: 幻境云图 -- 滤镜节点 WidgetCameraFilterOption
-- ---------------------------------------------------------------------------------

local UISelfieFilterCell = class("UISelfieFilterCell")

function UISelfieFilterCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISelfieFilterCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieFilterCell:BindUIEvent()
    UIHelper.BindUIEvent(self.button, EventType.OnClick, function()
        Timer.Add(self, 0.2, function ()
            if GetTickCount() - self.fClickEditTime >= 1000 then
                if self.clickCallback then
                    self.clickCallback(self.nFilterIndex, self)
                end
                self:ShowSelectState(true)
            end
        end)
    end)
    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        self.fClickEditTime = GetTickCount()
        if self.editorCallback then
            self.editorCallback()
        end
    end)
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self.fClickEditTime = GetTickCount()
        if self.resetCallback then
            self.resetCallback()
        end
    end)
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self.fClickEditTime = GetTickCount()
        if self.deleteCallback then
            self.deleteCallback()
        end
    end)
    UIHelper.BindUIEvent(self.BtnRename, EventType.OnClick, function()
        self.fClickEditTime = GetTickCount()
        if self.renameCallback then
            self.renameCallback()
        end
    end)
end

function UISelfieFilterCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieFilterCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieFilterCell:UpdateInfo(tFilterParams, clickCallback, editorCallback, resetCallback)
    self.clickCallback = clickCallback
    self.editorCallback = editorCallback
    self.resetCallback = resetCallback
    self.nFilterIndex = tFilterParams.nLogicIndex
    self.fClickEditTime = 0
    local szName = UIHelper.GBKToUTF8(tFilterParams.szName)
    UIHelper.SetString(self.LabelCamerFilterOption, szName)
    local imageFrame = "Resource/CameraFilter/"..tFilterParams.szName..".png"
    UIHelper.SetTexture(self.ImgCamerFilterOption, imageFrame)
    UIHelper.SetSwallowTouches(self.button, false)
    UIHelper.SetSwallowTouches(self.TogCameraFitterOption, false)
    
end

function UISelfieFilterCell:UpdatePresetInfo(tFilterParams, tCustomParams, clickCallback, editorCallback, deleteCallback, renameCallback)
    self.clickCallback = clickCallback
    self.editorCallback = editorCallback
    self.deleteCallback = deleteCallback
    self.renameCallback = renameCallback
    self.nFilterIndex = tFilterParams.nLogicIndex
    self.fClickEditTime = 0
    UIHelper.SetString(self.LabelCamerFilterOption, tCustomParams.szName)
    local imageFrame = "Resource/CameraFilter/"..tFilterParams.szName..".png"
    UIHelper.SetTexture(self.ImgCamerFilterOption, imageFrame)
    UIHelper.SetSwallowTouches(self.button, false)
    UIHelper.SetSwallowTouches(self.TogCameraFitterOption, false)
end

function UISelfieFilterCell:ShowSelectState(bShow)
    self.SelectState = bShow
    UIHelper.SetVisible(self.BtnSetting, self.editorCallback ~= nil and not self.bEditMode)--self.nFilterIndex ~= 0)
    UIHelper.SetVisible(self.WidgetCameraFilterOptionSelect, bShow)
end

function UISelfieFilterCell:SetModifyState(bModified)
    UIHelper.SetVisible(self.BtnReset, bModified and not self.bEditMode)
    UIHelper.SetVisible(self.WidgetChanged, bModified and not self.bEditMode)
end

function UISelfieFilterCell:SetEditMode(bEditMode)
    self.bEditMode = bEditMode
    UIHelper.SetVisible(self.WidgetEditButton, bEditMode)
    UIHelper.SetVisible(self.BtnSetting, self.SelectState and not bEditMode)
end


return UISelfieFilterCell