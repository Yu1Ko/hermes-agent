-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieSetting
-- Date: 2023-04-23 16:21:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieSetting = class("UISelfieSetting")

local TogType =
{
    Base = 1 ,
    Filter = 2,
    Servant = 3,
    Light = 4,
    Show = 5,
    Wind = 6,
    CamAni = 7,
    BGM = 8,
    AIAni = 9,
}

function UISelfieSetting:OnEnter(onHideCallback, bNameCard)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.onHideCallback = onHideCallback
    self.bNameCard = bNameCard
    self:UpdateInfo()
    -- if self.ScrollLightSetting then
    --     self:UpdateLightPage()
    -- end
end

function UISelfieSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieSetting:BindUIEvent()
    for k, v in pairs(self.tbToggle) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            self:UpdateToggleState(k)
        end)
        if  k == TogType.BGM or k == TogType.CamAni or k == TogType.AIAni then
            UIHelper.SetVisible(v, false)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollTitleTog)

    UIHelper.BindUIEvent(self.BtnRightClose , EventType.OnClick , function ()
        self:Hide()
    end)
end

function UISelfieSetting:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieSetting:UpdateInfo()
    self.curToggleIndex = nil
    self.tbPageScript = {}
    self:Hide()
    if self.bNameCard then
        UIHelper.SetVisible(self.tbToggle[3], false)
    end

    local filterScript = UIHelper.GetBindScript(self.CameraFilter)
    if filterScript then
        UIHelper.SetVisible(filterScript.ScrollViewSetting , false)
    end
end

function UISelfieSetting:Open(nToggleIndex)
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
    for k, v in pairs(self.tbScrollView) do
        UIHelper.SetVisible(v , false)
    end
    -- 灯光暂时不支持
    --UIHelper.SetCanSelect(self.tbToggle[TogType.Light], false, "无界端暂未开放", true)

    -- 提审屏蔽灯光页签
    if AppReviewMgr.IsReview() then
        local togLight = self.tbToggle[TogType.Light]
        UIHelper.SetVisible(togLight, false)
        UIHelper.SetVisible(UIHelper.GetChildByName(UIHelper.GetParent(togLight), "ImgRightLine03"), false)
        UIHelper.SetVisible(UIHelper.GetChildByName(UIHelper.GetParent(togLight), "ImgRightLine04"), false)
    end

    self:UpdateToggleState(nToggleIndex or 1)
end

function UISelfieSetting:Hide()
    if self.curToggleIndex == TogType.Filter and self.tbPageScript[TogType.Filter]:IsHideSettingPanel() then
        self.tbPageScript[TogType.Filter]:HideSettingPanel()
    else
        UIHelper.SetVisible(self._rootNode , false)
        self.bIsOpen = false
        if self.onHideCallback then
            self.onHideCallback()
        end
    end
end

function UISelfieSetting:IsOpen()
    return self.bIsOpen
end

function UISelfieSetting:UpdateDefaultScript()
    self:UpdateToggleState(TogType.Base)
    self:UpdateToggleState(TogType.Show)
    self:UpdateToggleState(TogType.Wind)
    for _, nType in pairs(TogType) do
        if nType ~= 3 and nType ~= 5 and nType ~= 1 then
            self:UpdateToggleState(nType)
        end
        if nType ~= 3 then
            UIHelper.SetSelected(self.tbToggle[self.curToggleIndex], false)
            UIHelper.SetVisible(self.tbScrollView[self.curToggleIndex] , false)
            if self.tbPageScript[self.curToggleIndex] then
                self.tbPageScript[self.curToggleIndex]:Hide()
            end
        end
    end
    
    self.curToggleIndex = 1
    self:UpdateToggleState(1)
    UIHelper.SetSelected(self.tbToggle[self.curToggleIndex], false)
    UIHelper.SetVisible(self.tbScrollView[1] , false)
    self.tbPageScript[1]:Hide()
end

function UISelfieSetting:UpdateToggleState(index)
    if self.curToggleIndex then
        UIHelper.SetSelected(self.tbToggle[self.curToggleIndex], false)
        UIHelper.SetVisible(self.tbScrollView[self.curToggleIndex] , false)
        -- 对原先的脚本进行关闭处理
        if self.tbPageScript[self.curToggleIndex] then
            self.tbPageScript[self.curToggleIndex]:Hide()
        end
    end
    self.curToggleIndex = index
    if self.curToggleIndex == TogType.Light then
        if self.ScrollLightSetting == nil then
            if self.ScrollViewCameraLightSetting then
                self.ScrollLightSetting = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraLightSetting , self.ScrollViewCameraLightSetting)
                UIHelper.SetPosition(self.ScrollLightSetting._rootNode , 0,0)
            else
                self.ScrollLightSetting = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraLightSetting , self.WidgetAnchorRight)
            end
    
            self.tbScrollView[self.curToggleIndex] = self.ScrollLightSetting._rootNode
        end
    elseif (not self.tbScrollView[self.curToggleIndex] ) then
        if self.curToggleIndex == TogType.Wind then
            local nPrefabID = PREFAB_ID.WidgetScrollViewWindSetting
            if UIHelper.GetScreenPortrait() then
                nPrefabID = PREFAB_ID.WidgetScrollViewWindSettingPortrait
            end
            if self.ScrollViewCameraLightSetting then
                self.windSettingScript =  UIHelper.AddPrefab(nPrefabID , self.ScrollViewCameraLightSetting)
                UIHelper.SetPosition(self.windSettingScript._rootNode , 0,0)
            else
                self.windSettingScript =  UIHelper.AddPrefab(nPrefabID , self.WidgetAnchorRight)
            end
            self.tbScrollView[self.curToggleIndex] =  self.windSettingScript._rootNode

        -- elseif self.curToggleIndex == TogType.CamAni then
        --     local nPrefabID = PREFAB_ID.WidgetCameraMoveSetting
        --     if UIHelper.GetScreenPortrait() then
        --         nPrefabID = PREFAB_ID.WidgetCameraMoveSettingPortrait
        --     end
        --     if self.ScrollViewCameraLightSetting then
        --         self.camAniScript =  UIHelper.AddPrefab(nPrefabID , self.ScrollViewCameraLightSetting)
        --         UIHelper.SetPosition(self.camAniScript._rootNode , 0,0)
        --     else
        --         self.camAniScript =  UIHelper.AddPrefab(nPrefabID , self.WidgetAnchorRight)
        --     end
        --     self.tbScrollView[self.curToggleIndex] =  self.camAniScript._rootNode
        -- elseif self.curToggleIndex == TogType.BGM then
        --     local nPrefabID = PREFAB_ID.WidgetCameraBgmSetting
        --     if UIHelper.GetScreenPortrait() then
        --         nPrefabID = PREFAB_ID.WidgetCameraBgmSettingPortrait
        --     end
        --     if self.ScrollViewCameraLightSetting then
        --         self.camBGMScript =  UIHelper.AddPrefab(nPrefabID , self.ScrollViewCameraLightSetting)
        --         UIHelper.SetPosition(self.camBGMScript._rootNode , 0,0)
        --     else
        --         self.camBGMScript =  UIHelper.AddPrefab(nPrefabID , self.WidgetAnchorRight)
        --     end
        --     self.tbScrollView[self.curToggleIndex] =  self.camBGMScript.ScrollViewRoot

        -- elseif self.curToggleIndex == TogType.AIAni then
        --     local nPrefabID = PREFAB_ID.WidgetCameraAIGenerated
        --     if UIHelper.GetScreenPortrait() then
        --         nPrefabID = PREFAB_ID.WidgetCameraAIGeneratedPortrait
        --     end
        --     if self.ScrollViewCameraLightSetting then
        --         self.camAIScript =  UIHelper.AddPrefab(nPrefabID , self.ScrollViewCameraLightSetting)
        --         UIHelper.SetPosition(self.camAIScript._rootNode , 0,0)
        --     else
        --         self.camAIScript =  UIHelper.AddPrefab(nPrefabID , self.WidgetAnchorRight)
        --     end
        --     self.tbScrollView[self.curToggleIndex] =  self.camAIScript.ScrollViewRoot
        elseif self.curToggleIndex == TogType.Show then
            self.tbScrollView[self.curToggleIndex] = self.tbScrollView[TogType.Base]
        end
    end
    UIHelper.SetSelected(self.tbToggle[index], true)
    UIHelper.SetVisible(self.tbScrollView[self.curToggleIndex] , true)
    if self.tbPageScript[self.curToggleIndex] == nil then
        if self.curToggleIndex == TogType.Base or self.curToggleIndex == TogType.Show then
            self.tbPageScript[self.curToggleIndex] = UIHelper.GetBindScript(self.CameraSetting)
        elseif self.curToggleIndex == TogType.Filter then
            self.tbPageScript[self.curToggleIndex] = UIHelper.GetBindScript(self.CameraFilter)
        elseif self.curToggleIndex == TogType.Servant then
            self.tbPageScript[self.curToggleIndex] = UIHelper.GetBindScript(self.RenownFriend)
        elseif self.curToggleIndex == TogType.Light then
            self.tbPageScript[self.curToggleIndex] = self.ScrollLightSetting
        elseif self.curToggleIndex == TogType.Wind then
            self.tbPageScript[self.curToggleIndex] = self.windSettingScript
        -- elseif self.curToggleIndex == TogType.CamAni then
        --     self.tbPageScript[self.curToggleIndex] = self.camAniScript
        -- elseif self.curToggleIndex == TogType.BGM then
        --     self.tbPageScript[self.curToggleIndex] = self.camBGMScript
        -- elseif self.curToggleIndex == TogType.AIAni then
        --     self.tbPageScript[self.curToggleIndex] = self.camAIScript
        end
        if self.tbPageScript[self.curToggleIndex] then
            self.tbPageScript[self.curToggleIndex]:OnEnter(self.bNameCard,self.curToggleIndex)
        end
    else
        self.tbPageScript[self.curToggleIndex]:Open(self.curToggleIndex)
    end

    if self.curToggleIndex ~= TogType.Servant then
        UIHelper.ScrollViewDoLayoutAndToTop(self.tbScrollView[self.curToggleIndex])
    end
end

function UISelfieSetting:UpdateWindPage(tWind)
    local tWind = tWind or SelfieData.GetClothWind()
    local script = self.windSettingScript
    if not script then
        return
    end
    script:SetPhotoScript(tWind)
end

function UISelfieSetting:UpdateLightPage()
    local tLight = SelfieData.GetLightData()
    local script = self.ScrollLightSetting
    if not script then
        return
    end
    script:SetPhotoScript(tLight)
end

function UISelfieSetting:UpdateBasePage()
    local tBase = SelfieData.GetBaseData()
    local script = UIHelper.GetBindScript(self.CameraSetting)
    if not script then
        return
    end
    script:SetPhotoScript(tBase)
end

function UISelfieSetting:UpdateFilterPage(tFilter)
    local tFilter = tFilter or SelfieData.GetFilterData()
    local script = UIHelper.GetBindScript(self.CameraFilter)
    script:SetPhotoScript(tFilter)
end

function UISelfieSetting:GetCamerAniIndex()
    return TogType.CamAni
end

return UISelfieSetting