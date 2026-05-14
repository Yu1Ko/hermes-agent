-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraSettingTog
-- Date: 2023-05-04 17:20:08
-- Desc: 幻境云图--基础模块Toggle
-- ---------------------------------------------------------------------------------

local UISelfieCameraSettingTog = class("UISelfieCameraSettingTog")
local MIN_FACE_COUNT = 8

local PendantShowType =
{
    [Selfie_BaseSettingType.Pendant_Head] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
    [Selfie_BaseSettingType.Pendant_Face] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    [Selfie_BaseSettingType.Pendant_Glasses] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    [Selfie_BaseSettingType.Pendant_BackCloak] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    [Selfie_BaseSettingType.Pendant_PendantPet] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    [Selfie_BaseSettingType.Pendant_Bag] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    [Selfie_BaseSettingType.Pendant_LShoulder] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    [Selfie_BaseSettingType.Pendant_RShoulder] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [Selfie_BaseSettingType.Pendant_LHand] =  EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    [Selfie_BaseSettingType.Pendant_RHand] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    [Selfie_BaseSettingType.Pendant_Back] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [Selfie_BaseSettingType.Pendant_Waist] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [Selfie_BaseSettingType.Pendant_Weapon] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    [Selfie_BaseSettingType.Pendant_BigSword] = EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    [Selfie_BaseSettingType.Pendant_Head2] = EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    [Selfie_BaseSettingType.Pendant_Head3] = EQUIPMENT_REPRESENT.HEAD_EXTEND2,
}

function UISelfieCameraSettingTog:OnEnter(nType , szName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szName = szName
    self.nType = nType
    self:UpdateInfo()
end

function UISelfieCameraSettingTog:OnExit()
    if self.nType == Selfie_BaseSettingType.ShowSelf then
        SelfieData.g_ShowSelf = true
    elseif self.nType == Selfie_BaseSettingType.ShowNPC then
        SelfieData.g_ShowNPC = true
    elseif self.nType == Selfie_BaseSettingType.ShowAllPlayer then
        SelfieData.g_ShowPlayer = true
    elseif self.nType == Selfie_BaseSettingType.ShowTeam then
        SelfieData.g_ShowPartyPlayer = true
    elseif self.nType == Selfie_BaseSettingType.CameraFoucs then
        SelfieData.bCameraSmoothing = false
        KG3DEngine.SetPostRenderDofAutoFocus(false)
    elseif self.nType == Selfie_BaseSettingType.EyeFoucs then
        SelfieData.bEyeFollow = false
    elseif self.nType == Selfie_BaseSettingType.ShowFaceCount then
        SelfieData.bShowFaceCount = true
    elseif self.nType == Selfie_BaseSettingType.AdvancedDof then
        KG3DEngine.SetPostRenderAdvancedDofEnable(false)
    elseif self.nType == Selfie_BaseSettingType.LightPos then
        SelfieData.bOpenLightPos = false
    elseif self.nType == Selfie_BaseSettingType.WindEnable then
        rlcmd("enable local cloth wind 0")
        SelfieData.bWindEnable = false
    -- elseif PendantShowType[self.nType] then
    --     if self.bDefaultShow ~= self.bShow then
    --         rlcmd(string.format("set player control visible by rep index %d %d", PendantShowType[self.nType], self.bDefaultShow and 0 or 1))
    --     end
    end
    self.bInit = false

    rlcmd("clear player control visible state")

    self:UnRegEvent()
end

function UISelfieCameraSettingTog:BindUIEvent()
    UIHelper.SetSwallowTouches(self.TogSelect, false)
    UIHelper.SetClickInterval(self.TogSelect, 0)
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnClick, function()
        if self.nType == Selfie_BaseSettingType.ShowNPC and GetCameraCaptureState() == CAMERA_CAPTURE_STATE.Capturing then
            TipsHelper.ShowNormalTip("当前增强现实模式下不支持该选项")
            UIHelper.SetSelected(self.TogSelect, false)
            return
        end

        self.bShow = not self.bShow
        if self.nType == Selfie_BaseSettingType.ShowAllPlayer then
            SelfieData.g_ShowPlayer = not SelfieData.g_ShowPlayer
        elseif self.nType == Selfie_BaseSettingType.ShowTeam then
            SelfieData.g_ShowPartyPlayer = not SelfieData.g_ShowPartyPlayer
        end
        self:UpdateToggleSelect()

        if self.onChangedCallback then
            self.onChangedCallback(self.bShow)
        end
    end)
end

function UISelfieCameraSettingTog:RegEvent()
    Event.Reg(self, EventType.OnSelfieFrameFreezeState, function (bFree)
        if PendantShowType[self.nType] then
            if bFree then
                UIHelper.SetCanSelect(self.TogSelect, false, "动作暂停中")
                UIHelper.SetNodeGray(self.LabelDesc, true)
            else
                UIHelper.SetCanSelect(self.TogSelect, self.bDefaultShow, self.szDefaultTips)
                UIHelper.SetNodeGray(self.LabelDesc, not self.bDefaultShow)
                UIHelper.SetSelected(self.TogSelect , self.bShow)
            end
        end
        if self.nType == Selfie_BaseSettingType.FabricEnable then
            if QualityMgr.CanEnableClothSimulation() then
                if bFree then
                    UIHelper.SetCanSelect(self.TogSelect,false,"当前角色动作暂停中")
                else
                    UIHelper.SetCanSelect(self.TogSelect,true)
                end
            else
                UIHelper.SetCanSelect(self.TogSelect,false,"当前设备不兼容布料效果")
            end
        end
    end)

    Event.Reg(self, EventType.OnSelfieFabricEnableEnable, function (bEnable)
        if  self.nType == Selfie_BaseSettingType.WindEnable then
            self.bShow = false
            SelfieData.bWindEnable = self.bShow
            UIHelper.SetSelected(self.TogSelect , self.bShow)
            UIHelper.SetCanSelect(self.TogSelect, bEnable, g_tStrings.STR_SELFIE_WIND_CANNOT_TIP2)
            Event.Dispatch(EventType.OnSelfieWindSwitchEnable, self.bShow)
        end
    end)
end

function UISelfieCameraSettingTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieCameraSettingTog:UpdateInfo()
    UIHelper.SetString(self.LabelDesc , self.szName)
    self.bShow = false
    self.bCanSelect = true
    if self.nType == Selfie_BaseSettingType.ShowSelf then
        self.bShow = SelfieData.g_ShowSelf
    elseif self.nType == Selfie_BaseSettingType.ShowNPC then
        self.bShow = SelfieData.g_ShowNPC
    elseif self.nType == Selfie_BaseSettingType.ShowAllPlayer then
        self.bShow =  SelfieData.g_ShowPlayer
        if SelfieData.IsInStudioMap() then
            self.bShow = false
            self.bCanSelect = false
            SelfieData.g_ShowPlayer = false
            UIHelper.SetCanSelect(self.TogSelect ,false)
        end
    elseif self.nType == Selfie_BaseSettingType.ShowTeam then
        self.bShow = SelfieData.g_ShowPartyPlayer
    elseif self.nType == Selfie_BaseSettingType.CameraFoucs then
        self.bShow = SelfieData.bCameraSmoothing
    elseif self.nType == Selfie_BaseSettingType.EyeFoucs then
        self.bShow = SelfieData.bEyeFollow
    elseif self.nType == Selfie_BaseSettingType.ShowFaceCount then
        self.bShow = SelfieData.bShowFaceCount
    elseif self.nType == Selfie_BaseSettingType.AdvancedDof then
        self.bShow = SelfieData.bOpenAdvancedDof
    elseif self.nType == Selfie_BaseSettingType.LightPos then
        self.bShow = SelfieData.bOpenLightPos
    elseif self.nType == Selfie_BaseSettingType.BloomEnbale then
        local tbEngineOption = KG3DEngine.GetMobileEngineOption()
        self.bShow = tbEngineOption.bEnableBloom
    elseif self.nType == Selfie_BaseSettingType.WindEnable then
        local hPlayer = GetClientPlayer()
        self.bShow = false
        SelfieData.bWindEnable = self.bShow
        UIHelper.SetCanSelect(self.TogSelect, QualityMgr.IsEnbaleApexClothing() and (not hPlayer.IsHaveBuff(12024, 1) ),g_tStrings.STR_SELFIE_WIND_CANNOT_TIP2)
    elseif self.nType == Selfie_BaseSettingType.FabricEnable then
        self.bShow = false
        local hPlayer = GetClientPlayer()
        if QualityMgr.CanEnableClothSimulation() then
            if hPlayer.IsHaveBuff(12024, 1) then
                UIHelper.SetCanSelect(self.TogSelect,false,"当前角色动作暂停中")
            else
                self.bShow = QualityMgr.IsEnbaleApexClothing()
                UIHelper.SetCanSelect(self.TogSelect,true)
            end
        else
            UIHelper.SetCanSelect(self.TogSelect,false,"当前设备不兼容布料效果")
        end
    elseif PendantShowType[self.nType] then
        local hPlayer = GetClientPlayer()
        if  hPlayer then
            local tRepresentID = hPlayer.GetRepresentID()
            self.bShow = tRepresentID[PendantShowType[self.nType]] ~= 0
            local bChecked = self.bShow
			if PendantShowType[self.nType] == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
				bChecked = bChecked and not hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)
			end

            bChecked = self:SpecialSelectedHandle(bChecked)
            self.bDefaultShow = bChecked
            local bCanSelect = self.bShow
            local bIsPandent = self.nType ~= Selfie_BaseSettingType.Pendant_Weapon or self.nType ~= Selfie_BaseSettingType.Pendant_BigSword
            self.szDefaultTips = bIsPandent and "当前部位没有挂件" or "当前部位没有装备"
            local szTips = self.szDefaultTips
            if hPlayer.IsHaveBuff(12024, 1) and self.bDefaultShow then
                bCanSelect = false
                szTips = "动作暂停中"
            end
            self:ResetVisible(true)

            UIHelper.SetSelected(self.TogSelect , bChecked)
            UIHelper.SetCanSelect(self.TogSelect, bCanSelect, szTips)
            UIHelper.SetNodeGray(self.LabelDesc, not bCanSelect)
            if self.bShow then
                rlcmd(string.format("set player control visible by rep index %d %d", PendantShowType[self.nType], bChecked and 0 or 1))
                SelfieData.tRoleBoxCheck[self.nType] = self.bShow
            end
            self.bShow = bChecked
        end
    end
    self:UpdateCommonToggleSelect()
end

function UISelfieCameraSettingTog:SpecialSelectedHandle(bChecked)
    if not self.bHasUpdated then
        self.bHasUpdated = true

        if PendantShowType[self.nType] == EQUIPMENT_REPRESENT.WEAPON_STYLE or
            PendantShowType[self.nType] == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then

                local bHideWeapon = g_pClientPlayer and g_pClientPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.IDLE_WEAPON)
                if bHideWeapon then
                    if self.bShow then
                        UIHelper.SetSelected(self.TogSelect , false)
                        bChecked = false
                    end
                end
        end
    end

    return bChecked
end

function UISelfieCameraSettingTog:UpdateCommonToggleSelect()
    UIHelper.SetSelected(self.TogSelect , self.bShow)
    if not self.bCanSelect then
        return
    end
    if self.nType == Selfie_BaseSettingType.ShowSelf then
        RLEnv.GetActiveVisibleCtrl():ShowSelf(self.bShow)
    elseif self.nType == Selfie_BaseSettingType.ShowNPC then
        RLEnv.GetActiveVisibleCtrl():ShowNpc(self.bShow)
    elseif self.nType == Selfie_BaseSettingType.ShowAllPlayer or self.nType == Selfie_BaseSettingType.ShowTeam then
        if not SelfieData.g_ShowPlayer then
            if SelfieData.g_ShowPartyPlayer then
                RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kParter)
            else
                RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kNone)
            end
        else
            RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kAll)
        end
    elseif self.nType == Selfie_BaseSettingType.ShowFaceCount then
        if self.bShow then
            self:SetFaceCount(-1)
        else
            self:SetFaceCount(MIN_FACE_COUNT)
        end
    elseif self.nType == Selfie_BaseSettingType.AdvancedDof then
        KG3DEngine.SetPostRenderAdvancedDofEnable(self.bShow)
        SelfieData.bOpenAdvancedDof = self.bShow
        Event.Dispatch(EventType.On_UI_OpenAdvancedDof)
    end
end

function UISelfieCameraSettingTog:UpdateToggleSelect()
    self:UpdateCommonToggleSelect()
    if self.nType == Selfie_BaseSettingType.CameraFoucs then
        self:_updateCameraFoucs()
    elseif self.nType == Selfie_BaseSettingType.EyeFoucs then
        self:_updateEyeFoucs()
    elseif self.nType == Selfie_BaseSettingType.LightPos then
        SelfieData.bOpenLightPos = self.bShow
        Event.Dispatch("SelfieLightPosOpen")
    elseif self.nType == Selfie_BaseSettingType.BloomEnbale then
        local tbEngineOption = KG3DEngine.GetMobileEngineOption()
        tbEngineOption.bEnableBloom = self.bShow
        KG3DEngine.SetMobileEngineOption(tbEngineOption)
        SelfieData.bEnableBloom = self.bShow
    elseif self.nType == Selfie_BaseSettingType.FabricEnable then
        GameSettingData.ApplyNewValue(UISettingKey.ClothSimulation, self.bShow)
        Event.Dispatch(EventType.OnSelfieFabricEnableEnable, self.bShow)
        SelfieData.bClothEnable = self.bShow
    elseif self.nType == Selfie_BaseSettingType.WindEnable then
        SelfieData.bWindEnable = self.bShow
        local nSet = self.bShow and 1 or 0
		rlcmd(string.format("enable local cloth wind %d",nSet))
        SelfieData.SetClothWind()
        Event.Dispatch(EventType.OnSelfieWindSwitchEnable, self.bShow)
    elseif PendantShowType[self.nType] then
        rlcmd(string.format("set player control visible by rep index %d %d", PendantShowType[self.nType], self.bShow and 0 or 1))
        SelfieData.tRoleBoxCheck[self.nType] = self.bShow
    end
end

function UISelfieCameraSettingTog:_updateCameraFoucs()
    SelfieData.bCameraSmoothing = self.bShow
    Event.Dispatch("SelfieCameraFocusOpen" , self.bShow)
end

function UISelfieCameraSettingTog:_updateEyeFoucs()
    SelfieData.bEyeFollow = self.bShow
    Event.Dispatch("SelfieEyeFocusOpen")
end

function UISelfieCameraSettingTog:SetFaceCount(nCount)
    RLEnv.GetActiveVisibleCtrl():SetHDFaceCount(nCount)
end

function UISelfieCameraSettingTog:SetNameCardSetting()
    -- UIHelper.UnBindUIEvent(self.TogSelect, EventType.OnClick)
    -- UIHelper.SetTouchEnabled(self.TogSelect, false)
    UIHelper.BindUIEvent(self.TogSelect , EventType.OnClick , function ()
        local sTip = "当前名片拍摄模式下不支持该选项"
        TipsHelper.ShowNormalTip(sTip)
        self:UpdateNameCardSelect()
    end)
end

function UISelfieCameraSettingTog:UpdateNameCardSelect()
    UIHelper.SetSelected(self.TogSelect , self.bShow)
end

function UISelfieCameraSettingTog:ResetVisible(bShow)
    local hPlayer = GetClientPlayer()
    if hPlayer and PendantShowType[self.nType] == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE and (hPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and hPlayer.dwForceID ~= 0) then
        UIHelper.SetVisible(self._rootNode,false)
        self.bShow = false
    else
        UIHelper.SetVisible(self._rootNode,bShow)
    end
end

function UISelfieCameraSettingTog:SetToggleChangeCallback(onChangedCallback)
    self.onChangedCallback = onChangedCallback
end

function UISelfieCameraSettingTog:SetResetCallback(onResetCallback)
    if not self.BtnReset then
        self.BtnReset = UIHelper.GetChildByName(self._rootNode, "BtnReset")
        UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
           if onResetCallback then
                onResetCallback()
            end
        end)
        UIHelper.SetVisible(self.BtnReset, true)
    end

end

function UISelfieCameraSettingTog:SetWindCell(value)
    self.bShow = value
    self:UpdateToggleSelect()

end


return UISelfieCameraSettingTog