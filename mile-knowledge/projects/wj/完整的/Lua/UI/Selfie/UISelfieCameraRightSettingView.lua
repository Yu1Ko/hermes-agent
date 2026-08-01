-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraRightSettingView
-- Date: PanelCameraSettingRight   
-- Desc: 幻境云图右侧面板
-- ---------------------------------------------------------------------------------
local UISelfieCameraRightSettingView = class("UISelfieCameraRightSettingView")

function UISelfieCameraRightSettingView:OnEnter(onHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.onHideCallback = onHideCallback
end

function UISelfieCameraRightSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieCameraRightSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.TogCustom, EventType.OnSelectChanged, function (_,bSelected)
        if self.nTagType == SELFIE_CAMERA_RIGHT_TAG.CUSTOM then
            return
        end
        self:UpdateSelectModle(SELFIE_CAMERA_RIGHT_TAG.CUSTOM)
    end)

    UIHelper.BindUIEvent(self.TogDefault, EventType.OnSelectChanged, function (_,bSelected)
        if self.nTagType == SELFIE_CAMERA_RIGHT_TAG.DEFAULT then
            return
        end
        self:UpdateSelectModle(SELFIE_CAMERA_RIGHT_TAG.DEFAULT)
    end)
    
    UIHelper.BindUIEvent(self.BtnJuBao, EventType.OnClick, function (_,bSelected)
        local tbSelectInfo =
        {
            nSelectIndex = 5,
            tbParams = {}
        }
        local tbScript = UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
    end)

    UIHelper.BindUIEvent(self.BtnXieYi, EventType.OnClick, function (_,bSelected)
        AiBodyMotionData.OpenAgreeStatement()
    end)
end

function UISelfieCameraRightSettingView:RegEvent()
    Event.Reg(self, EventType.OnSelfieCameraBGMEditor, function (bEnter)
        if bEnter then
            UIHelper.SetVisible(self._rootNode, false)
        else
            UIHelper.SetVisible(self._rootNode, true)
        end
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMCustomSaved, function ()
        local szDesc = SelfieMusicData.GetCustomCountDesc()
        UIHelper.SetString(self.LabelCustomNum, szDesc)
        UIHelper.SetString(self.LabelCustomNumSelect, szDesc)
    end)

    Event.Reg(self, EventType.OnSelfieCameraBGMCustomDeleted, function ()
        local szDesc = SelfieMusicData.GetCustomCountDesc()
        UIHelper.SetString(self.LabelCustomNum, szDesc)
        UIHelper.SetString(self.LabelCustomNumSelect, szDesc)
    end)
end

function UISelfieCameraRightSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieCameraRightSettingView:Open(nType)
    self.bIsOpen = true
    self:UpdateInfo(nType)
    UIHelper.SetVisible(self._rootNode, true)
end

function UISelfieCameraRightSettingView:Hide()
    self.bIsOpen = false
    if self.onHideCallback then
        self.onHideCallback()
    end
    Event.Dispatch("ON_SELFIE_RIGHT_PANEL_HIDE")
    --UIHelper.SetVisible(self._rootNode, false)
    UIMgr.Close(self)
end

function UISelfieCameraRightSettingView:Close()
    -- for k, v in pairs(self.tScript_ContentList) do
    --     v:Close()
    -- end
    UIMgr.Close(self)
end

function UISelfieCameraRightSettingView:IsOpen()
    return self.bIsOpen
end

function UISelfieCameraRightSettingView:UpdateInfo(nType)
    self.tScript_ContentList = self.tScript_ContentList or {}
    self.nType = nType
   
    if not self.tScript_ContentList[nType] then
        if self.nType == SELFIE_CAMERA_RIGHT_TYPE.MUSIC then
            self.tScript_ContentList[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetVideoMusic, self.WIdgetContent)
            self.script_content = self.tScript_ContentList[nType]
            self:UpdateSelectModle(SELFIE_CAMERA_RIGHT_TAG.DEFAULT)
        elseif self.nType == SELFIE_CAMERA_RIGHT_TYPE.MOVIE then
            self.tScript_ContentList[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraMoveSetting, self.WIdgetContent)
            self.script_content = self.tScript_ContentList[nType]
            self:ExcuteEnter()
        elseif self.nType == SELFIE_CAMERA_RIGHT_TYPE.AIGC then
            self.tScript_ContentList[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraAIGenerated, self.WIdgetContent)
            self.script_content = self.tScript_ContentList[nType]
            self:ExcuteEnter()
        end
    end
    UIHelper.SetVisible(self.LayoutAIBtn, false)
    UIHelper.SetString(self.LabelCustomNum, "")
    UIHelper.SetString(self.LabelCustomNumSelect, "")
    if self.nType == SELFIE_CAMERA_RIGHT_TYPE.MUSIC then
        self:ShowSelectTab(true)
        local szDesc = SelfieMusicData.GetCustomCountDesc()
        UIHelper.SetString(self.LabelCustomNum, szDesc)
        UIHelper.SetString(self.LabelCustomNumSelect, szDesc)
    elseif self.nType == SELFIE_CAMERA_RIGHT_TYPE.MOVIE then
        self:ShowSelectTab(false)
    elseif self.nType == SELFIE_CAMERA_RIGHT_TYPE.AIGC then
     
        self:ShowSelectTab(false)
        UIHelper.SetVisible(self.LayoutAIBtn, true)
    end

    for k, v in pairs(self.tScript_ContentList) do
        UIHelper.SetVisible(v._rootNode, k == nType)
    end
    self:SetLabelTitleText(SELFIE_CAMERA_RIGHT_TYPE_NAME[self.nType])
end

function UISelfieCameraRightSettingView:UpdateSelectModle(nTag)
    self.nTagType = nTag
    local bIsDefault = nTag == SELFIE_CAMERA_RIGHT_TAG.DEFAULT
    UIHelper.SetSelected(self.TogDefault, bIsDefault)
    UIHelper.SetSelected(self.TogCustom, not bIsDefault)
    UIHelper.SetTouchEnabled(self.TogDefault, not bIsDefault)
    UIHelper.SetTouchEnabled(self.TogCustom, bIsDefault)
    if self.script_content then
        self.script_content:UpdateSelectModle(nTag)
    end
end

function UISelfieCameraRightSettingView:ExcuteEnter()
    if self.script_content then
        self.script_content:OnEnter()
    end
end

function UISelfieCameraRightSettingView:ShowSelectTab(bShow)
    UIHelper.SetVisible(self.WidgetTab, bShow)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UISelfieCameraRightSettingView:SetLabelTitleText(content)
    UIHelper.SetString(self.LabelTitle, content)
end


return UISelfieCameraRightSettingView
