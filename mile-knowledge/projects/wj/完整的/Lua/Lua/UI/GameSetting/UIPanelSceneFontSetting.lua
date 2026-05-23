-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIPanelSceneFontSetting
-- Date: 2024-07-15 11:17:33
-- Desc: UIPanelSceneFontSetting
-- ---------------------------------------------------------------------------------

local tColors = {
    0x000000, 0x060606, 0x0c0c0c, 0x121212, 0x181818, 0x1e1e1e, 0x242424, 0x2a2a2a,
    0x303030, 0x363636, 0x3c3c3c, 0x424242, 0x484848, 0x4e4e4e, 0x545454, 0x5a5a5a,
    0x606060, 0x666666, 0x6b6b6b, 0x727272, 0x787878, 0x7e7e7e, 0x848484, 0x8a8a8a,
    0x909090, 0x969696, 0x9c9c9c, 0xa2a2a2, 0xa8a8a8, 0xaeaeae, 0xb4b4b4, 0xbababa,
    0xc0c0c0, 0xc6c6c6, 0xcccccc, 0xd2d2d2, 0xd8d8d8, 0xdedede, 0xe4e4e4, 0xeaeaea,
    0xf0f0f0, 0xf6f6f6, 0xfcfcfc,
}

local tFontTitleData = {
    ["字体设置"] = { "nFontLevel", "nBorderWidth", "nSpan" },
    ["血条设置"] = { "nHealthBarSize" },
}

local tTopBuffTitleData = {
    ["图标设置"] = { "nIconSize", "nIconPosition" },
}

local UIPanelSceneFontSetting = class("UIPanelSceneFontSetting")

local tSettingType = {
    HeadTopBarSetting = "HeadTopBarSetting",
    TopBuffSetting = "TopBuffSetting",
}

function UIPanelSceneFontSetting:OnEnter(szSettingType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szSettingType = szSettingType
    assert(szSettingType)
    assert(Storage[szSettingType])

    self.tTempSetting = clone(Storage[szSettingType])
    if szSettingType == tSettingType.HeadTopBarSetting then
        self.tDefaultInfo = HeadTopDefaultInfo
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.NAME, true) -- 打开自身名字显示
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.LIFE, true) -- 打开自身血条显示
        Global_UpdateHeadTopPosition()
        UIHelper.SetString(self.LabelTitle, "头顶文字血条效果")
    elseif szSettingType == tSettingType.TopBuffSetting then
        self.tDefaultInfo = TopBuffDefaultInfo
        TopBuffData.SetSettingMode(true)
        UIHelper.SetString(self.LabelTitle, "头顶增减益效果")
    end
    assert(self.tDefaultInfo)

    self:UpdateInfo()
end

function UIPanelSceneFontSetting:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.szSettingType == tSettingType.HeadTopBarSetting then
        local bOpenLife = GameSettingData.GetNewValue(UISettingKey.ShowSelfHealthBar)
        local bOpenName = GameSettingData.GetNewValue(UISettingKey.ShowSelfName)
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.NAME, bOpenName) -- 还原自身血条显示
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.LIFE, bOpenLife) -- 还原自身血条显示
        Global_UpdateHeadTopPosition()
    elseif self.szSettingType == tSettingType.TopBuffSetting then
        TopBuffData.SetSettingMode(false)
    end
end

function UIPanelSceneFontSetting:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        local bChanged = false
        for szKey, nVal in pairs(self.tTempSetting) do
            if Storage[self.szSettingType][szKey] ~= nVal then
                bChanged = true
                break
            end
        end
    
        if bChanged then
            local dialog = UIHelper.ShowConfirm("当前效果发生修改，是否保存并退出?", function()
                self:ConfirmSetting()
                UIMgr.Close(self)
            end)
            dialog:SetOtherButtonClickedCallback(function()
                if self.szSettingType == tSettingType.HeadTopBarSetting then
                    SetModelTopBarSize(Storage[self.szSettingType])
                elseif self.szSettingType == tSettingType.TopBuffSetting then
                    TopBuffData.SetTopBuffSetting(Storage[self.szSettingType])
                end
                UIMgr.Close(self)
            end)
            dialog:SetConfirmButtonContent("是")
            dialog:SetCancelButtonContent("取消")
            dialog:SetOtherButtonContent("否")
            dialog:ShowOtherButton()
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:ConfirmSetting()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:ResetToDefault()
    end)
end

function UIPanelSceneFontSetting:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelSceneFontSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelSceneFontSetting:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollSetting)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)

    if self.szSettingType == tSettingType.HeadTopBarSetting then

        local tConfig = self.tDefaultInfo.bCareMode
        if tConfig.bButton then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSwitch_HalfPanel, self.ScrollSetting)
            script:SetName(tConfig.szTitle)
            script:SetSelected(tConfig.fnGetState and tConfig.fnGetState())
            script:AddToggleFunc(tConfig.fnSwitch)
        end

        local fnSlideEnd = function(tbInfo, nVal)
            if tbInfo.szKey and Storage[self.szSettingType][tbInfo.szKey] ~= nil then
                self.tTempSetting[tbInfo.szKey] = nVal
                SetModelTopBarSize(self.tTempSetting)
            end
        end

        for szName, lst in pairs(tFontTitleData) do
            local titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFontSettingTitleCell, self.ScrollSetting, szName)
            for _, szKey in ipairs(lst) do
                local tConfig = self.tDefaultInfo[szKey]
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetAdjustCell_FontSetting, titleScript.LayoutContent)
                script:OnEnter(self.tTempSetting[szKey], { szTitle = tConfig.szTitle, nMin = tConfig.nMin, nMax = tConfig.nMax,
                                                                fnCallback = fnSlideEnd, szKey = szKey })
            end
        end

        local titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFontSettingTitleCell, self.ScrollSetting, "边框颜色")
        for nIndex, nColor in ipairs(tColors) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, titleScript.LayoutContent)
            script:InitFontColor(cc.c3b(nColor / (256 * 256), (nColor / 256) % 256, nColor % 256), self.ToggleGroup, function()
                self.tTempSetting.nBorderColorRGB = nColor
                SetModelTopBarSize(self.tTempSetting)
            end)

            if nColor == Storage[self.szSettingType].nBorderColorRGB then
                UIHelper.SetToggleGroupSelected(self.ToggleGroup, nIndex - 1)
            end
        end

    elseif self.szSettingType == tSettingType.TopBuffSetting then

        local fnSlideEnd = function(tbInfo, nVal)
            if tbInfo.szKey and Storage[self.szSettingType][tbInfo.szKey] ~= nil then
                self.tTempSetting[tbInfo.szKey] = nVal
                TopBuffData.SetTopBuffSetting(self.tTempSetting)
            end
        end
    
        for szName, lst in pairs(tTopBuffTitleData) do
            local titleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFontSettingTitleCell, self.ScrollSetting, szName)
            for _, szKey in ipairs(lst) do
                local tConfig = self.tDefaultInfo[szKey]
                if tConfig then
                    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetAdjustCell_FontSetting, titleScript.LayoutContent)
                    script:OnEnter(self.tTempSetting[szKey], { szTitle = tConfig.szTitle, nMin = tConfig.nMin, nMax = tConfig.nMax,
                                                                    fnCallback = fnSlideEnd, szKey = szKey })
                end
            end
        end

    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollSetting, true, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollSetting)
end

function UIPanelSceneFontSetting:ResetToDefault()
    for szKey, tInfo in pairs(self.tDefaultInfo) do
        if tInfo and tInfo.nDefault ~= nil then
            self.tTempSetting[szKey] = tInfo.nDefault
        end
    end
    if self.szSettingType == tSettingType.HeadTopBarSetting then
        SetModelTopBarSize(self.tTempSetting)
    elseif self.szSettingType == tSettingType.TopBuffSetting then
        TopBuffData.SetTopBuffSetting(self.tTempSetting)
    end
    self:UpdateInfo()
end

function UIPanelSceneFontSetting:ConfirmSetting()
    for szKey, nVal in pairs(self.tTempSetting) do
        Storage[self.szSettingType][szKey] = nVal
    end
    Storage[self.szSettingType].Flush()
end

return UIPanelSceneFontSetting