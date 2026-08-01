local UIMiniSettingPopView = class("UIMiniSettingPopView")

local ImgButtonPath = {
    ["Yellow"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_tuijian",
    ["Blue"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_Normal"
}

function UIMiniSettingPopView:OnEnter(tbSetting, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbSetting.ReloadTempData then
        tbSetting.ReloadTempData()
    end
    self.bFirstEnter = true
    self.tbSetting = tbSetting
    self.tSectionScriptList = self.tSectionScriptList or {}
    self:UpdateInfo()

    if nIndex then
        local tSection = self.tbSetting[nIndex]
        local tSectionScript = self.tSectionScriptList[nIndex]
        if tSection and (not tSection.fnGetVisible or tSection.fnGetVisible()) and tSectionScript then
            Timer.AddFrame(self, 1, function()
                UIHelper.SetSelected(tSectionScript._rootNode, true)
            end)
        end
    end
end

function UIMiniSettingPopView:OnExit()
    self.bInit = false
end

function UIMiniSettingPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

    for nBtnIndex, Button in ipairs(self.tbButtonList) do
        UIHelper.BindUIEvent(Button, EventType.OnClick, function()
            local tSection = self.tbSetting[self.nCurIndex]
            if not tSection then return end

            local tbBtnConfig = tSection.tbButtonList[nBtnIndex]
            if not tbBtnConfig or not tbBtnConfig.fnBtnCallBack then return end

            tbBtnConfig.fnBtnCallBack(tSection.tbGroupList)
        end)
    end
end

function UIMiniSettingPopView:RegEvent()
    Event.Reg(self, EventType.OnMiniSettingRefreshButton, function ()
        self:RefreshButtons()
    end)
end

function UIMiniSettingPopView:UpdateInfo()
    self.nCurIndex = 1
    self.tSectionScriptList = {}
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)
    for nIndex, tSection in ipairs(self.tbSetting) do
        local tSectionScript = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingToggle, self.ScrollViewLeftList)
        tSectionScript:OnEnter(nIndex, tSection.szName, nIndex == 1, nil, function ()
            self.nCurIndex = nIndex
            UIHelper.RemoveAllChildren(self.ScrollViewRightList)
            for _, tGroup in ipairs(tSection.tbGroupList) do
                UIHelper.AddPrefab(PREFAB_ID.WidgetAutoGetTitle, self.ScrollViewRightList, tGroup)
            end

            self:RefreshButtons()
            
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
            if self.bFirstEnter then
                self.bFirstEnter = false
                Timer.AddFrame(self, 1, function ()
                    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
                end)
            end
        end)
        table.insert(self.tSectionScriptList, tSectionScript)

        if tSection.fnGetVisible and not tSection.fnGetVisible() then
            UIHelper.SetVisible(tSectionScript._rootNode, false)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
end

function UIMiniSettingPopView:RefreshButtons()
    local tSection = self.tbSetting[self.nCurIndex]
    for _, Button in ipairs(self.tbButtonList) do
        UIHelper.SetVisible(Button, false)
    end

    if not tSection then return end

    local nBtnCount = 1
    for _, tbBtnConfig in ipairs(tSection.tbButtonList) do
        local Button = self.tbButtonList[nBtnCount]
        local bVisible = not tbBtnConfig.fnGetVisible or tbBtnConfig.fnGetVisible()
        if bVisible then
            UIHelper.SetVisible(Button, true)
            UIHelper.SetString(self.tbBtnTextList[nBtnCount], tbBtnConfig.szName)
            UIHelper.SetSpriteFrame(self.tbBtnBgList[nBtnCount], ImgButtonPath[tbBtnConfig.szBgColor])
        end
        nBtnCount = nBtnCount + 1
    end
    UIHelper.LayoutDoLayout(self.LayoutBtnList)
end

return UIMiniSettingPopView