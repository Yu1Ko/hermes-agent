-- ---------------------------------------------------------------------------------
-- Author: zeng zipeng
-- Name: UISelfieBaseSetting
-- Date: 2023-05-04 16:29:11
-- Desc: 幻境云图 -- 基础设置
-- ---------------------------------------------------------------------------------
local tbBaseSettingContent = 
{
    ["Function"] = 
    {
        [1] = {nType = Selfie_BaseSettingType.CameraFoucs , szName = "镜头焦点" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bIsFocus"},
        [2] = {nType = Selfie_BaseSettingType.EyeFoucs , szName = "眼睛焦点" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bIsLookAt"},
        [3] = {nType = Selfie_BaseSettingType.BloomEnbale , szName = "泛光效果" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bEnableBloom"}
    },
    ["Camera"] = 
    {
        [1] = {nType = Selfie_BaseSettingType.AngleSize , szName = "广角大小" , UIType = Selfie_BaseSettingCellType.Slider, key = "nWidAngle"},
        [2] = {nType = Selfie_BaseSettingType.FouceDistance , szName = "对焦距离" , UIType = Selfie_BaseSettingCellType.Slider, key = "nDistanceOfFocus"},
        [3] = {nType = Selfie_BaseSettingType.DOF , szName = "景深范围" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nDepthOfField"},
        [4] = {nType = Selfie_BaseSettingType.DOFDegree , szName = "景深程度" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nDepthOfFieldDegree"},
        [5] = {nType = Selfie_BaseSettingType.AdvancedDof , szName = "高级景深" , UIType = Selfie_BaseSettingCellType.ToggleLong, bHideOnARMode = true, key = "bAdvancedDOFChecked"},
        [6] = {nType = Selfie_BaseSettingType.BokehShape , szName = "形状" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nBokehShape"},
        [7] = {nType = Selfie_BaseSettingType.BokehSize , szName = "大小" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nBokehSize"},
        [8] = {nType = Selfie_BaseSettingType.BokehFalloff , szName = "亮度" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nBokehFalloff"},
        [9] = {nType = Selfie_BaseSettingType.BokehBrightness , szName = "密度" , UIType = Selfie_BaseSettingCellType.Slider, bHideOnARMode = true, key = "nBokehBrightness"},
    },
    ["Light"] = {
        [1] = {nType = Selfie_BaseSettingType.ModelBrightness , szName = "角色模型亮度" , UIType = Selfie_BaseSettingCellType.Slider, key = "nModelBrightness"},
        [2] = {nType = Selfie_BaseSettingType.HeadingAngle , szName = "角色倒影方向" , UIType = Selfie_BaseSettingCellType.Slider, key = "nHeadingAngle"},
        [3] = {nType = Selfie_BaseSettingType.AltitudeAngle , szName = "角色倒影高度" , UIType = Selfie_BaseSettingCellType.Slider, key = "nAltitudeAngle"},
    },
}

local tbShowSettingContent = 
{
    ["Show"] =
    {
        [1] = {nType = Selfie_BaseSettingType.ShowSelf , szName = "自己" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bHideSelf"},
        [2] = {nType = Selfie_BaseSettingType.ShowNPC , szName = "NPC" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bHideNPC"},
        [3] = {nType = Selfie_BaseSettingType.ShowAllPlayer , szName = "全部玩家" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bShowAllPlayers"},
        [4] = {nType = Selfie_BaseSettingType.ShowTeam , szName = "队友" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bOnlyTeammates"},
        [5] = {nType = Selfie_BaseSettingType.ShowFaceCount , szName = "自定义脸型" , UIType = Selfie_BaseSettingCellType.Toggle, key = "bShowFeature"},
    },
    ["Pandent"] = 
    {
            [1] = {nType = Selfie_BaseSettingType.Pendant_Head, szName = "头饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [2] = {nType = Selfie_BaseSettingType.Pendant_Head2, szName = "头饰二" , UIType = Selfie_BaseSettingCellType.Toggle},
            [3] = {nType = Selfie_BaseSettingType.Pendant_Head3, szName = "头饰三" , UIType = Selfie_BaseSettingCellType.Toggle},
            [4] = {nType = Selfie_BaseSettingType.Pendant_Face, szName = "面挂" , UIType = Selfie_BaseSettingCellType.Toggle},
            [5] = {nType = Selfie_BaseSettingType.Pendant_Glasses, szName = "眼饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [6] = {nType = Selfie_BaseSettingType.Pendant_BackCloak, szName = "披风" , UIType = Selfie_BaseSettingCellType.Toggle},
            [7] = {nType = Selfie_BaseSettingType.Pendant_PendantPet, szName = "挂宠" , UIType = Selfie_BaseSettingCellType.Toggle},
            [8] = {nType = Selfie_BaseSettingType.Pendant_Bag, szName = "佩囊" , UIType = Selfie_BaseSettingCellType.Toggle},
            [9] = {nType = Selfie_BaseSettingType.Pendant_LShoulder, szName = "左肩饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [10] = {nType = Selfie_BaseSettingType.Pendant_RShoulder, szName = "右肩饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [11] = {nType = Selfie_BaseSettingType.Pendant_LHand, szName = "左手饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [12] = {nType = Selfie_BaseSettingType.Pendant_RHand, szName = "右手饰" , UIType = Selfie_BaseSettingCellType.Toggle},
            [13] = {nType = Selfie_BaseSettingType.Pendant_Back, szName = "背挂" , UIType = Selfie_BaseSettingCellType.Toggle},
            [14] = {nType = Selfie_BaseSettingType.Pendant_Waist, szName = "腰挂" , UIType = Selfie_BaseSettingCellType.Toggle},
    },
    ["Equipment"] = 
    {
        [1] = {nType = Selfie_BaseSettingType.Pendant_Weapon, szName = "武器" , UIType = Selfie_BaseSettingCellType.Toggle},
        [2] = {nType = Selfie_BaseSettingType.Pendant_BigSword, szName = "重剑" , UIType = Selfie_BaseSettingCellType.Toggle},
    },
}
local UISelfieBaseSetting = class("UISelfieBaseSetting")

local SettingType = 
{
    Base = 1,
    Show = 5
}


function UISelfieBaseSetting:OnEnter(bNameCard, nSettingType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSettingType = nSettingType
    self.bNameCard = bNameCard
    self.tbSettingCells = self.tbSettingCells or {}
    if nSettingType == SettingType.Base then
        UIHelper.RemoveAllChildren(self.LayoutFunctionSetting)
        UIHelper.RemoveAllChildren(self.LayoutFunction2Setting)
        UIHelper.RemoveAllChildren(self.LayoutCameraSetting)
        UIHelper.RemoveAllChildren(self.LayoutDisplaySetting)
        UIHelper.RemoveAllChildren(self.LayoutLightSetting)
    end
    self:UpdateInfo()
end

function UISelfieBaseSetting:OnExit()
    self.bInit = false
    self.tbSettingCells = {}
    self:UnRegEvent()
    
end

function UISelfieBaseSetting:BindUIEvent()
    
end

function UISelfieBaseSetting:RegEvent()
    Event.Reg(self, EventType.OnCameraCaptureStateChanged, function(nState)
        self:UpdateARModeInfo()
        UIHelper.LayoutDoLayout(self.LayoutDisplaySetting)
        UIHelper.LayoutDoLayout(self.LayoutFunctionSetting)
        UIHelper.LayoutDoLayout(self.LayoutCameraSetting)
        UIHelper.LayoutDoLayout(self.LayoutLightSetting)
        UIHelper.LayoutDoLayout(self.LayoutViewCameraSetting)
    end)
end

function UISelfieBaseSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UISelfieBaseSetting:Hide()

end

function UISelfieBaseSetting:Open(nSettingType)
    self.nSettingType = nSettingType
    self:UpdateInfo()
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieBaseSetting:UpdateInfo()
    local bBaseType = self.nSettingType == SettingType.Base
    self.tbSettingCells[self.nSettingType] = self.tbSettingCells[self.nSettingType] or {}
    UIHelper.SetVisible(self.WidgetDisplaySwitchTitle, not bBaseType)
    UIHelper.SetVisible(self.WidgetFunction_2_SettingTitle, not bBaseType)
    UIHelper.SetVisible(self.WidgetLightSettingTitle,  bBaseType)
    UIHelper.SetVisible(self.WidgetCameraSettingTitle,  bBaseType)
    UIHelper.SetVisible(self.LayoutDisplaySetting, not bBaseType)
    UIHelper.SetVisible(self.LayoutLightSetting,  bBaseType)
    UIHelper.SetVisible(self.LayoutFunction2Setting, not  bBaseType)
    UIHelper.SetVisible(self.LayoutCameraSetting,  bBaseType)

    for k, v in pairs(self.tbSettingCells) do
        for _, cell in pairs(v) do
            cell:ResetVisible(k == self.nSettingType)
        end
    end


    if bBaseType then
        UIHelper.SetString(self.tbLabelTitle[2],"功能设置")
        if table.get_len(self.tbSettingCells[self.nSettingType]) <= 0 then
            for i, v in ipairs(tbBaseSettingContent.Function) do
                local cell = self:createCell(v.UIType , self.LayoutFunctionSetting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
            for i, v in ipairs(tbBaseSettingContent.Camera) do
                local cell = self:createCell(v.UIType , self.LayoutCameraSetting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
            for i, v in ipairs(tbBaseSettingContent.Light) do
                local cell = self:createCell(v.UIType , self.LayoutLightSetting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
        end
        self:UpdateARModeInfo()
    else
        UIHelper.SetString(self.tbLabelTitle[2],"挂件显示")
        UIHelper.SetString(self.tbLabelTitle[5],"装备显示")
        if table.get_len(self.tbSettingCells[self.nSettingType]) <= 0 then
            for i, v in ipairs(tbShowSettingContent.Show) do
                local cell = self:createCell(v.UIType , self.LayoutDisplaySetting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                if self.bNameCard then
                    cell:SetNameCardSetting()
                end
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
            for i, v in ipairs(tbShowSettingContent.Pandent) do
                local cell = self:createCell(v.UIType , self.LayoutFunctionSetting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
            for i, v in ipairs(tbShowSettingContent.Equipment) do
                local cell = self:createCell(v.UIType , self.LayoutFunction2Setting)
                v.cellScript = cell
                cell:OnEnter(v.nType , v.szName)
                table.insert(self.tbSettingCells[self.nSettingType], cell)
            end
        end
    end




    UIHelper.LayoutDoLayout(self.LayoutDisplaySetting)
    UIHelper.LayoutDoLayout(self.LayoutFunctionSetting)
    UIHelper.LayoutDoLayout(self.LayoutCameraSetting)
    UIHelper.LayoutDoLayout(self.LayoutLightSetting)
    UIHelper.LayoutDoLayout(self.LayoutViewCameraSetting)
end

function UISelfieBaseSetting:createCell(uiType , layout)
    if uiType == Selfie_BaseSettingCellType.Slider then
        return UIHelper.AddPrefab(PREFAB_ID.WidgetSliderCameraSetting , layout)
    elseif uiType == Selfie_BaseSettingCellType.Toggle then
        return UIHelper.AddPrefab(PREFAB_ID.WidgetCameraSettingTog , layout)
    else
        return UIHelper.AddPrefab(PREFAB_ID.WidgetCameraSettingTogLong , layout)
    end
end

function UISelfieBaseSetting:UpdateARModeInfo()
    local nState = GetCameraCaptureState()
    UIHelper.SetVisible(self.WidgetLightSettingTitle, nState == CAMERA_CAPTURE_STATE.Capturing)
    UIHelper.SetVisible(self.LayoutLightSetting, nState == CAMERA_CAPTURE_STATE.Capturing)

    for _A, tSetting in pairs(tbBaseSettingContent) do
        for _B, v in pairs(tSetting) do
            if v.cellScript then
                local node = v.cellScript._rootNode
                if v.bHideOnARMode and node and safe_check(node) then
                    UIHelper.SetVisible(node, nState ~= CAMERA_CAPTURE_STATE.Capturing)
                end
                if v.nType == Selfie_BaseSettingType.ShowNPC then
                    SelfieData.g_ShowNPC = nState ~= CAMERA_CAPTURE_STATE.Capturing
                    v.cellScript:UpdateInfo()
                end
            end
        end
    end
end

function UISelfieBaseSetting:SetCell(tInfo, value)
    local script = tInfo.cellScript
    if tInfo.UIType == Selfie_BaseSettingCellType.Slider then
        script:UpdateSliderValue(value)
    elseif tInfo.UIType == Selfie_BaseSettingCellType.Toggle then
        if tInfo.nType == Selfie_BaseSettingType.ShowSelf or tInfo.nType == Selfie_BaseSettingType.ShowNPC then
            script.bShow = not value
        else
            script.bShow = value
        end
        script:UpdateToggleSelect()
    elseif tInfo.UIType == Selfie_BaseSettingCellType.ToggleLong then
        script.bShow = value
        script:UpdateToggleSelect()
    end
end

function UISelfieBaseSetting:SetPhotoScript(tBase)
    for i, v in ipairs(tbBaseSettingContent.Function) do
        local value = tBase[v.key]
        self:SetCell(v, value)
    end

    local tSelfieCamera = tBase.tSelfieCamera
    for i, v in ipairs(tbBaseSettingContent.Camera) do
        local value = tSelfieCamera[v.key]
        self:SetCell(v, value)
    end
    for i, v in ipairs(tbBaseSettingContent.Light) do
        local value = tSelfieCamera[v.key]
        self:SetCell(v, value)
    end

    local tShowHide = tBase.tShowHide
    for i, v in ipairs(tbShowSettingContent.Show) do
        local value = tShowHide[v.key]
        self:SetCell(v, value)
    end

    if SelfieData.IsInFreeAnimation() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_PHOTO_TITLE_BASE_USE_FAILED)
    else
        local tRoleBoxCheck = tShowHide.tRoleBoxCheck
        for i, v in ipairs(tbShowSettingContent.Pandent) do
            local value = tRoleBoxCheck[v.nType]
            self:SetCell(v, value)
        end
        
        for i, v in ipairs(tbShowSettingContent.Equipment) do
            local value = tRoleBoxCheck[v.nType]
        self:SetCell(v, value)
    end
    end
end

return UISelfieBaseSetting