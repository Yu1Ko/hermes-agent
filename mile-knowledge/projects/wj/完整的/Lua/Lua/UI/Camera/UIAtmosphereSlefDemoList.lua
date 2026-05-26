-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIAtmosphereSlefDemoList
-- Date: 2026-01-23 14:39:00
-- Desc: 时光漫游 “选择需要替换的原有预设”的列表 PanelAtmosphereSlefDemoList
-- ---------------------------------------------------------------------------------

local UIAtmosphereSlefDemoList = class("UIAtmosphereSlefDemoList")

function UIAtmosphereSlefDemoList:OnEnter(nDefaultPresetIndex, funcOnSelected, fnOnClose)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDefaultPresetIndex = nDefaultPresetIndex
    self.funcOnSelected = funcOnSelected
    self.fnOnClose = fnOnClose
    self:UpdateInfo()
end

function UIAtmosphereSlefDemoList:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.fnOnClose then
        self.fnOnClose()
    end
end

function UIAtmosphereSlefDemoList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.funcOnSelected then
            self.funcOnSelected(self.nPresetIndex)
        end
        UIMgr.Close(self)
    end)
end

function UIAtmosphereSlefDemoList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAtmosphereSlefDemoList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIAtmosphereSlefDemoList:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutCameraFilterOption)

    local firstNode
    for i, tbCustomParams in ipairs(Storage.FilterParam.tbCustomPresets) do
        local nPresetIndex = i
        local tbParams = SelfieData.GetFilterParamsByFilterIndex(tbCustomParams.nFilterIndex)
        if tbParams then
            local node = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraFilterOption, self.LayoutCameraFilterOption)
            node:UpdatePresetInfo(tbParams, tbCustomParams, function(nFilterIndex, cellNode)
                self:SelectPreset(nPresetIndex, node)
            end)

            if nPresetIndex == self.nDefaultPresetIndex then
                node:ShowSelectState(true)
                self:SelectPreset(nPresetIndex, node)
            end
        end
    end

    if not self.nPresetIndex then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
    end

    UIHelper.LayoutDoLayout(self.LayoutCameraFilterOption)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilter)
end

function UIAtmosphereSlefDemoList:SelectPreset(nPresetIndex, cellNode)
    if self.gLastSelectCell then
        self.gLastSelectCell:ShowSelectState(false)
        self.gLastSelectCell:SetModifyState(false)
    end
    self.nPresetIndex = nPresetIndex
    self.gLastSelectCell = cellNode
    UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
end


return UIAtmosphereSlefDemoList