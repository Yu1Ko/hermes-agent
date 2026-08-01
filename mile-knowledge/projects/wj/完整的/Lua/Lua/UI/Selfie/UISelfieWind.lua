-- ---------------------------------------------------------------------------------
-- Author: 幻境云图 - 风场
-- Name: UISelfieWind
-- Date: 2025-03-04 16:08:59
-- Desc: zeng zi peng
-- ---------------------------------------------------------------------------------

local UISelfieWind = class("UISelfieWind")
local  tChildNodeInfo = 
{
    [Selfie_BaseSettingType.WindEnable]  = {szName = "角色风场", UIType = Selfie_BaseSettingCellType.Toggle, key = "bWind"},
    [Selfie_BaseSettingType.FabricEnable]  = {szName = "布料效果", UIType = Selfie_BaseSettingCellType.Toggle, key = "bCloth"},
    [Selfie_BaseSettingType.WindStrength]  = {szName = "强度", UIType = Selfie_BaseSettingCellType.Slider, key = "nStrength"},
    [Selfie_BaseSettingType.WindFrequency]  = {szName = "频率", UIType = Selfie_BaseSettingCellType.Slider, key = "nFrequency"},
    [Selfie_BaseSettingType.WindVecX]  = {szName = "X轴", UIType = Selfie_BaseSettingCellType.Slider, key = "nX"},
    [Selfie_BaseSettingType.WindVecY]  = {szName = "Y轴", UIType = Selfie_BaseSettingCellType.Slider, key = "nY"},
    [Selfie_BaseSettingType.WindVecZ]  = {szName = "Z轴", UIType = Selfie_BaseSettingCellType.Slider, key = "nZ"},
}   
function UISelfieWind:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    -- if SelfieData.Wind_CurrentData then
        self.bUpdate = SelfieData.Wind_CurrentData.bImportPhotoData
        self.tWind = clone(SelfieData.Wind_CurrentData)
    -- else
    --     SelfieData.Wind_CurrentData = SelfieData.Wind_DefaultData 
    -- end

    self:UpdateInfo()
    -- UILog("self.bUpdate self.tWind", self.bUpdate, self.tWind)
    if self.bUpdate then
        self:SetPhotoScript(self.tWind)
    end
end

function UISelfieWind:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieWind:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHide , EventType.OnClick , function ()
        SelfieData.ShowClothWind(not SelfieData.bShowClothWindArror)
        self:_UpdateHideVecText()
    end)

    UIHelper.BindUIEvent(self.BtnRefresh , EventType.OnClick , function ()
        UIHelper.ShowConfirm(g_tStrings.STR_SELFIE_RESET_WIND_SURE, function ()
            SelfieData.ResetClothWindData()
        end)
    end)
end

function UISelfieWind:RegEvent()
    Event.Reg(self, EventType.OnSelfieWindSwitchEnable, function (bEnable)
        UIHelper.SetButtonState(self.BtnHide, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnRefresh, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
        if not bEnable then
            SelfieData.ShowClothWind(false)
            self:_UpdateHideVecText()
        end
    end)
end

function UISelfieWind:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieWind:Open()
    
end

function UISelfieWind:Hide()
   
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieWind:UpdateInfo()
    self:_InitBindScript(self.WidgetCameraSettingTogWind, Selfie_BaseSettingType.WindEnable)
    self:_InitBindScript(self.WidgetCameraSettingTogFabric, Selfie_BaseSettingType.FabricEnable)
    self:_InitBindScript(self.WidgetSliderCameraSettingStrength, Selfie_BaseSettingType.WindStrength)
    self:_InitBindScript(self.WidgetSliderCameraSettingFrequency, Selfie_BaseSettingType.WindFrequency)
    self:_InitBindScript(self.WidgetSliderWindVecX, Selfie_BaseSettingType.WindVecX)
    self:_InitBindScript(self.WidgetSliderWindVecY, Selfie_BaseSettingType.WindVecY)
    self:_InitBindScript(self.WidgetSliderWindVecZ, Selfie_BaseSettingType.WindVecZ)
    self:_UpdateHideVecText()
    UIHelper.SetButtonState(self.BtnHide, BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnRefresh, BTN_STATE.Disable)
end

function UISelfieWind:_InitBindScript(node, nType)
    local script = UIHelper.GetBindScript(node)
    if script then
        script:OnEnter(nType, tChildNodeInfo[nType].szName)
        tChildNodeInfo[nType].cellScript = script
    end
  
end

function UISelfieWind:_UpdateHideVecText()
    UIHelper.SetString(self.LabelHide, SelfieData.bShowClothWindArror and "隐藏风向" or "显示风向")
end

function UISelfieWind:SetCell(tInfo, value)
    local script = tInfo.cellScript
    if not script then
        return
    end
    if tInfo.UIType == Selfie_BaseSettingCellType.Slider then
        script:UpdateSliderValue(value)
    elseif tInfo.UIType == Selfie_BaseSettingCellType.Toggle then
        script.bShow = value
        script:UpdateToggleSelect()
    end
end

function UISelfieWind:SetPhotoScript(tWind)
    local tWind = tWind or SelfieData.GetClothWind()

    local tFabric = tChildNodeInfo[Selfie_BaseSettingType.FabricEnable]
    local value = tWind[tFabric.key]
    self:SetCell(tFabric, value)

    local tWindEnable = tChildNodeInfo[Selfie_BaseSettingType.WindEnable]
    local value = tWind[tWindEnable.key]
    self:SetCell(tWindEnable, value)

    for nType, v in pairs(tChildNodeInfo) do
        if v.UIType == Selfie_BaseSettingCellType.Slider then
            local value = tWind[v.key]
            self:SetCell(v, value)
        end
    end
    SelfieData.Wind_CurrentData.bImportPhotoData = nil
end

return UISelfieWind