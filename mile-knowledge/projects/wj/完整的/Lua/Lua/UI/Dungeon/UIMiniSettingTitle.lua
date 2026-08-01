local UIMiniSettingTitle = class("UIMiniSettingTitle")

function UIMiniSettingTitle:OnEnter(tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIMiniSettingTitle:OnExit()
    self.bInit = false
end

function UIMiniSettingTitle:BindUIEvent()

end

function UIMiniSettingTitle:RegEvent()
    Event.Reg(self, EventType.OnMiniSettingAllUpdate, function ()
        self:UpdateInfo()
    end)
end

function UIMiniSettingTitle:UpdateInfo()
    local tbConfig = self.tbConfig
    if not tbConfig then return end

    UIHelper.SetString(self.LabelTitle, tbConfig.szName)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.RemoveAllChildren(self.LayoutOptions)

    local nDataCount = 0
    for _, tClass in ipairs(tbConfig.tbClassList) do
        local scriptCell
        if tClass.nType == MINI_SETTING_COM_TYPE.SWITCH then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAutoGetBookSettingSwitch, self.LayoutOptions, tClass)
        elseif tClass.nType == MINI_SETTING_COM_TYPE.OPTION_S then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAutoGetOption, self.LayoutOptions, tClass)
        elseif tClass.nType == MINI_SETTING_COM_TYPE.OPTION_L then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAutoGetCell, self.LayoutOptions, tClass)
        end
        if tClass.bHideAllChild and scriptCell then
            local tChildren = UIHelper.GetChildren(scriptCell._rootNode)
            for _, nodeChild in ipairs(tChildren) do
                UIHelper.SetVisible(nodeChild, false)
            end
        end
        nDataCount = nDataCount + 1
    end

    if tbConfig.fnGetDataList then
        for _, tData in ipairs(tbConfig.fnGetDataList()) do
            UIHelper.AddPrefab(tData.nPrefabID, self.LayoutOptions, tData)
            nDataCount = nDataCount + 1
        end
    end
    UIHelper.SetVisible(self.WidgetEmpty, nDataCount == 0)
    UIHelper.SetVisible(self.TogSearch, tbConfig.fnOnSearchConfirm ~= nil)
end

return UIMiniSettingTitle