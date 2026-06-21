-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidegtFocusManagePanel
-- Date: 2024-5-11
-- Desc: ?
-- ---------------------------------------------------------------------------------
local sgsub, sformat, sfind = string.gsub, string.format, string.find
local tinsert = table.insert
local _L = JX.LoadLangPack

---@class UIWidgetFocusCustomPanel
local UIWidgetFocusCustomPanel = class("UIWidgetFocusCustomPanel")

function UIWidgetFocusCustomPanel:OnEnter()
    if not self.bInit then
        if not Storage.FocusList._tCustomModData then
            return
        end
        
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
       
        local _tCustomModData = Storage.FocusList._tCustomModData
        local tCustom = _tCustomModData.default -- 1.名字，2.帮会，3.门派
        tCustom[2].forceData = tCustom[2].forceData or {}
        
        self.tScrollLists = { self.ScrollViewListPlayer, self.ScrollViewListTongID, self.ScrollViewPermanentSchool }
        
        UIHelper.SetSelected(self.ToggleHidePlayer, tCustom[1].enable)
        UIHelper.SetSelected(self.ToggleHideTong,  tCustom[2].enable)
        UIHelper.SetSelected(self.ToggleHideSchool, tCustom[3].enable)
        UIHelper.SetSelected(self.ToggleHideSchoolFilter, tCustom[2].forceFilter)
        
        UIHelper.SetTouchDownHideTips(self.ToggleHideSchoolFilter, false)
        
        ----------筛选门派---------------
       
        UIHelper.RemoveAllChildren(self.ScrollViewPermanentSchool)
        local tList = Table_GetAllForceUI()
        for k, v in pairs(tList) do
            if not self.tRowScript or self.tRowScript:IsFull() then
                self.tRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanentCustomAdd, self.ScrollViewPermanentSchool)
            end
            if tCustom[3].data[k] == nil then
                tCustom[3].data[k] = false
            end
            local bSelected = tCustom[3].data[k]
            self.tRowScript:AddSchool(v.szName, bSelected, function()
                tCustom[3].data[k] = not tCustom[3].data[k]
                Storage.FocusList.Flush()
            end)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPermanentSchool)

        ----------帮会-筛选门派---------------
        self.tRowScript = nil
        UIHelper.RemoveAllChildren(self.ScrollViewSchoolFilter)
        local tList = Table_GetAllForceUI()
        for k, v in pairs(tList) do
            if not self.tRowScript or self.tRowScript:IsFull() then
                self.tRowScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanentCustomAdd, self.ScrollViewSchoolFilter)
            end
            if tCustom[2].forceData[k] == nil then
                tCustom[2].forceData[k] = false
            end
            local bSelected = tCustom[2].forceData[k]
            self.tRowScript:AddSchool(v.szName, bSelected, function()
                tCustom[2].forceData[k] = not tCustom[2].forceData[k]
                Storage.FocusList.Flush()
            end, false)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSchoolFilter)
        
        self:UpdateInfo()
    end
end

function UIWidgetFocusCustomPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFocusCustomPanel:BindUIEvent()
    local _tCustomModData = Storage.FocusList._tCustomModData
    
    UIHelper.BindUIEvent(self.BtnPlayerAdd, EventType.OnClick, function()
        self:AddBtnClick(1)
    end)
    UIHelper.BindUIEvent(self.BtnTongAdd, EventType.OnClick, function()
        self:AddBtnClick(2)
    end)

    UIHelper.BindUIEvent(self.TogScreen, EventType.OnSelectChanged, function(tog, bSelected)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSchoolFilter)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogScreen, false)
    end)

    UIHelper.BindUIEvent(self.ToggleHidePlayer, EventType.OnClick, function()
        _tCustomModData.default[1].enable = not _tCustomModData.default[1].enable
        Storage.FocusList.Flush()
    end)
    UIHelper.BindUIEvent(self.ToggleHideTong, EventType.OnClick, function()
        _tCustomModData.default[2].enable = not _tCustomModData.default[2].enable
        Storage.FocusList.Flush()
    end)
    UIHelper.BindUIEvent(self.ToggleHideSchool, EventType.OnClick, function()
        _tCustomModData.default[3].enable = not _tCustomModData.default[3].enable
        Storage.FocusList.Flush()
    end)
    UIHelper.BindUIEvent(self.ToggleHideSchoolFilter, EventType.OnClick, function()
        _tCustomModData.default[2].forceFilter = not _tCustomModData.default[2].forceFilter
        Storage.FocusList.Flush()
    end)
end

function UIWidgetFocusCustomPanel:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips,function()
        if UIHelper.GetSelected(self.TogScreen) then
            UIHelper.SetSelected(self.TogScreen, false)
        end
    end)
end

function UIWidgetFocusCustomPanel:UnRegEvent()

end

function UIWidgetFocusCustomPanel:UpdateInfo()
    local _tCustomModData = Storage.FocusList._tCustomModData

    for i = 1, 2 do
        local layout = self.tScrollLists[i]
        UIHelper.RemoveAllChildren(layout)
        for k, v in pairs(_tCustomModData.default[i].data) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanentIDAdd, layout)
            local bSelected = v == 1
            UIHelper.SetSelected(script.TogName, bSelected)
            UIHelper.SetString(script.LabelName, k)
            UIHelper.BindUIEvent(script.TogName, EventType.OnSelectChanged, function(tog, bSelected)
                _tCustomModData.default[i].data[k] = bSelected and 1 or 2
                Storage.FocusList.Flush()
                self:UpdateInfo()
            end)
            UIHelper.BindUIEvent(script.BtnDelete, EventType.OnClick, function()
                _tCustomModData.default[i].data[k] = nil
                Storage.FocusList.Flush()
                self:UpdateInfo()
            end)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(layout)
    end
end

function UIWidgetFocusCustomPanel:AddBtnClick(nType)
    local tTips = {
        [1] = UIHelper.GBKToUTF8(_L["please input player name:"]),
        [2] = UIHelper.GBKToUTF8(_L["please input tong name:"]),
    }
    local szTips = tTips[nType]
    
    local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "", szTips, function(szText)
        if szText == "" then
            TipsHelper.ShowNormalTip("内容不能为空")
            return
        end

        if TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then
            Storage.FocusList._tCustomModData.default[nType].data[szText] = 1
            Storage.FocusList.Flush()
            self:UpdateInfo()
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
        end
    end)
    editBox:SetTitle("添加自定义数据")
    editBox:SetMaxLength(10)
end

function UIWidgetFocusCustomPanel:DelItemList(szText, nType, script, tScrollView)
    if not szText then
        return
    end
    if nType == 3 then
        Storage.FocusList._tFocusTargetData['NPC_' .. szText] = nil
    else
        Storage.FocusList._tFocusTargetData[szText] = nil
    end
    Storage.FocusList.Flush()
    local tar
    if nType == 1 then
        tar = JX.GetPlayerByName(szText)
    elseif nType == 2 then
        tar = GetPlayer(szText)
    elseif nType == 3 then
        tar = JX.GetNpcByName(szText)
    end
    if tar then
        _JX_TargetList.ChangeFocusTable(false, 1, tar.dwID)
    end

    --UIHelper.RemoveFromParent(script._rootNode, true)
    --UIHelper.ScrollViewDoLayout(tScrollView)
end

function UIWidgetFocusCustomPanel:AddCell(szName, nType, tScrollView)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanenAdd, tScrollView)
    local szProcessedName = UIHelper.LimitUtf8Len(szName, 6)
    UIHelper.SetString(script.LabelName, szProcessedName)
    UIHelper.BindUIEvent(script.BtnDelete, EventType.OnClick, function()
        self:DelItemList(szName, nType, script, tScrollView)
        self:UpdateInfo()
    end)
end


return UIWidgetFocusCustomPanel