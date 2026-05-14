-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityLeftBottom
-- Date: 2023-11-27 15:25:06
-- Desc: ?
-- ---------------------------------------------------------------------------------
local BTN_TYPE = {
	COMMON = 1,
	ATHLETICS = 2,
	SECRETAREA = 3,
    PARTNER = 4
}

local UIMainCityLeftBottom = class("UIMainCityLeftBottom")

function UIMainCityLeftBottom:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local nVersion = 1
    if not IsNumber(Storage.CustomBtn.nVersion) or Storage.CustomBtn.nVersion ~= nVersion then
        self:ResetCustomStorageData(nVersion)
    end
    self:UpdateInfo()
    --self:UpdateDefaultScale()
end

function UIMainCityLeftBottom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMainCityLeftBottom:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnLeftBottonSetting, EventType.OnClick, function()
        local script = UIMgr.GetViewScript(VIEW_ID.PanelQuickOperation)
        if not script then
        	script = UIMgr.Open(VIEW_ID.PanelQuickOperation)
		end
        script:UpdateModifyStateInfo(true)
	end)

    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.CUSTOMBTN, self.nMode)
    end)
end

function UIMainCityLeftBottom:RegEvent()
    Event.Reg(self, EventType.OnUpdateMainCityLeftBottom, function(nType)
        self:UpdateInfo(nType)
    end)

    Event.Reg(self, EventType.OnCameraHidePlayer, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function (dwPlayerID)
        self:UpdateInfo()
    end)

    Event.Reg(self, "LOADING_END", function ()
        local player = GetClientPlayer()
        if player then
            local tPet = player.GetFellowPet()
            if tPet then
                local hPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
                if hPetIndex and hPetIndex ~= 0 then
                    Storage.CustomBtn.bHaveFellowPet = true
                end
            else
                Storage.CustomBtn.bHaveFellowPet = false
            end
        end
        local nBtnType = self:GetBtnDataListType()
        self:SetStorageCustomBtnType(nBtnType)
        Storage.CustomBtn.Dirty()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (tbFontShow, nNodeType)
        if nNodeType == CUSTOM_TYPE.CUSTOMBTN then
            for k, label in pairs(self.tbLabelList) do
                UIHelper.SetVisible(label, tbFontShow[nNodeType])
            end
        end
    end)

    --Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (bVisible)
	--	for k, label in pairs(self.tbLabelList) do
	--		UIHelper.SetVisible(label, bVisible)
	--	end
    --end)

    Event.Reg(self,"ON_HIDE_LEFT_CHANGE_BTN",function (bVisible)
        UIHelper.SetVisible(self.BtnLeftBottonSetting, bVisible)
    end)

    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        --在秘境召唤侠客
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SUMMON_SUCCESS and Storage.CustomBtn.nCurType ~= BTN_TYPE.PARTNER then
            -- todo: 这里就是召请和召回成功的实际
            local player = GetClientPlayer()
            if player then
                local dwMapID = player.GetMapID()
                local _, nMapType = GetMapParams(dwMapID)
                if nMapType == 1 then    --在秘境
                    local tSummonedList = PartnerData.GetSummonedList()
                    local nBtnType = nil
                    if #tSummonedList > 0 then
                        nBtnType = BTN_TYPE.PARTNER
                    else
                        nBtnType = BTN_TYPE.SECRETAREA
                    end
                    self:SetStorageCustomBtnType(nBtnType)
                    self:UpdateInfo()
                end
            end
        end
    end)

end

function UIMainCityLeftBottom:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMainCityLeftBottom:UpdateInfo(nType)
    self:_getDataList(nType)

    for _, widget in ipairs(self.tbWidgetList) do
        UIHelper.SetVisible(widget, false)
    end

    for k, tbData in ipairs(self.tbDataList) do
        self:_updateOneBtn(k, tbData)
    end

    if g_pClientPlayer then
        UIHelper.SetVisible(self.BtnLeftBottonSetting, g_pClientPlayer.nLevel >= 103)
    end

    UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)
    for k, label in pairs(self.tbLabelList) do
        UIHelper.SetVisible(label, Storage.ControlMode.tbFontShow[CUSTOM_TYPE.CUSTOMBTN])
    end
end

function UIMainCityLeftBottom:_updateOneBtn(nIndex, tbData)
    local widget = self.tbWidgetList[nIndex]
    local script = UIHelper.GetBindScript(widget)
    if script then
        UIHelper.SetVisible(widget, true)
        UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)

        local bHasMutexState = tbData.bHasMutexState
        local szGlobalKey = tbData.szGlobalKey
        local szMutexCheckFun = tbData.szMutexCheckFun
        local tbUpdateEvents = tbData.tbUpdateEvents
        local bIsInMutexState = false
        if bHasMutexState then
            if not string.is_nil(szGlobalKey) then
                bIsInMutexState = _G[szGlobalKey]
            elseif not string.is_nil(szMutexCheckFun) then
                bIsInMutexState = string.execute(szMutexCheckFun)
            end
        end

        local szLabelName = bIsInMutexState and tbData.szLabelName_mutex or tbData.szLabelName
        local szIcon = bIsInMutexState and tbData.szIcon_mutex or tbData.szIcon
        local nVIewID = bIsInMutexState and tbData.nVIewID_mutex or tbData.nVIewID
        local szAction = bIsInMutexState and tbData.szAction_mutex or tbData.szAction
        local szActionEvent = tbData.szActionEvent

        UIHelper.SetSpriteFrame(script.Img, szIcon)
        UIHelper.SetString(script.Label, szLabelName)

        if not string.is_nil(szActionEvent) then
            Event.Dispatch(szActionEvent, script.Img, script.Label)
        end

        UIHelper.BindUIEvent(script.Btn, EventType.OnClick, function()
            -- 摇杆正在操作的时就不能点击
            --if SprintData.IsDragging() then
            --    return
            --end

            if bHasMutexState then
                if not string.is_nil(szGlobalKey) then
                    _G[szGlobalKey] = not _G[szGlobalKey]
                end
            end

            if nVIewID and nVIewID > 0 then
                UIMgr.Open(nVIewID)
            elseif not string.is_nil(szAction) then
                string.execute(szAction)
            end
        end)

        -- 刷新事件
        Event.UnRegAll(script)
        if not table.is_empty(tbUpdateEvents) then
            for k, v in ipairs(tbUpdateEvents) do
                Event.Reg(script, v, function()
                    Timer.Add(self, 0.1, function ()
                        self:_updateOneBtn(nIndex, tbData)
                    end)
                end)
            end

        end
    end
end

function UIMainCityLeftBottom:_getDataList(nType)
    self.tbDataList = {}

    --for k, v in ipairs(UIMainCityLeftBottomTab) do
    --    local szCondition = v.szCondition
    --    local bCondition = string.is_nil(szCondition) or string.execute(szCondition)
    --    if bCondition then
    --        table.insert(self.tbDataList, v)
    --    end
    --end

    local nBtnType = self:GetStorageCustomBtnType()
    local tbBtnDataList = clone(Storage.CustomBtn.tbBtnDataList[nBtnType])
    if nType then
        tbBtnDataList = clone(Storage.CustomBtn.tbBtnDataList[nType])
    end

    for i, nID in pairs(tbBtnDataList) do
        local tbData = self:GetBtnDataById(nID)
        local szCondition = tbData.szCondition
        local bCondition = string.is_nil(szCondition) or string.execute(szCondition)
        if bCondition then
            table.insert(self.tbDataList, tbData)
        end
    end

    return self.tbDataList
end

function UIMainCityLeftBottom:GetBtnDataById(nID)
    local tbData = nil
    for i, v in pairs(UIMainCityLeftBottomTab) do
        if v.nID == nID then
            tbData = v
            break
        end
    end

    return tbData
end

function UIMainCityLeftBottom:GetBtnDataListType()
    local tbCommonMapType = {0, 3, 4, 5}
    local tbAthleticsMapType = {2}
    local tbSecretAreaMapType = {1}
    local player = GetClientPlayer()
    if player then
        local dwMapID = player.GetMapID()
        local _, nMapType = GetMapParams(dwMapID)
        if table.contain_value(tbCommonMapType, nMapType) then
            return BTN_TYPE.COMMON
        elseif table.contain_value(tbAthleticsMapType, nMapType) then
            return BTN_TYPE.ATHLETICS
        elseif table.contain_value(tbSecretAreaMapType, nMapType) then
            local tSummonedList = PartnerData.GetSummonedList()
            if #tSummonedList > 0 then
                return BTN_TYPE.PARTNER
            else
                return BTN_TYPE.SECRETAREA
            end
        end
    end
end

function UIMainCityLeftBottom:UpdateDefaultScale()
    if Platform.IsWindows() or Platform.IsMac() then
        if not Channel.Is_WLColud() then
            local tbSizeInfo = TabHelper.GetUIFontSizeTab(DEVICE_TYPE.PC)
            local nSize = tbSizeInfo.nMediumSize
            UIHelper.SetScale(self._rootNode, nSize, nSize)
        end
    end
end

function UIMainCityLeftBottom:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIMainCityLeftBottom:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIMainCityLeftBottom:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

function UIMainCityLeftBottom:SetStorageCustomBtnType(nType)
    local nType = nType or BTN_TYPE.COMMON
    Storage.CustomBtn.nCurType = nType
    Storage.CustomBtn.Flush()
end

function UIMainCityLeftBottom:GetStorageCustomBtnType()
    return clone(Storage.CustomBtn.nCurType) or BTN_TYPE.COMMON
end

function UIMainCityLeftBottom:ResetCustomStorageData(nVersion)
    Storage.CustomBtn.tbBtnDataList = {
        [1] = { 15, 16, 12 },
        [2] = { 15, 16, 12 },
        [3] = { 5, 12, 7 },
        [4] = { 5, 23, 26 },
        }
    Storage.CustomBtn.nVersion = nVersion
    Storage.CustomBtn.Dirty()
end

return UIMainCityLeftBottom