-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISetCodeListView
-- Date: 2024-07-25 09:51:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISetCodeListView = class("UISetCodeListView")

local MAX_DATA_COUNT = 30

function UISetCodeListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsLogin = false

    self:InitView()
    self:UpdateInfo()
end

function UISetCodeListView:OnExit()
    self.bInit = false
end

function UISetCodeListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function(btn)
        self.bEnterDelMode = true
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function(btn)
        local bHadEditView = UIMgr.IsViewOpened(VIEW_ID.PanelCustomizedSet)
        if bHadEditView then
            EquipCodeData.ReqGetEquip(self.szCurSelectCode)
            TipsHelper.ShowNormalTip("正在导入配装方案，请稍候")
            UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable, "正在导入配装方案，请稍候")
        else
            local tMyEquips = EquipCodeData.tMyEquips or {}
            local tSelectInfo
            for _, tbInfo in ipairs(tMyEquips) do
                if tbInfo.share_id == self.szCurSelectCode then
                    tSelectInfo = tbInfo
                    break
                end
            end

            if not tSelectInfo then
                TipsHelper.ShowNormalTip("请先选择需要导入的配装方案")
                return
            end

            local dwForceID, dwKungfuID
            local szForceName = tSelectInfo.force
            local dwBelongSchoolID = Table_GetSkillSchoolIDByName(UIHelper.UTF8ToGBK(szForceName))
            dwForceID = Table_SchoolToForce(dwBelongSchoolID)
            -- dwForceID = table.get_key(PlayerForceIDToName, szForceName)
            if not dwForceID then
                dwForceID = FORCE_TYPE.CHUN_YANG
            end
            dwKungfuID = tonumber(tSelectInfo.kungfu_id)

            local hPlayer = GetClientPlayer()
            local bForceLegal = dwForceID == PlayerData.GetPlayerForceID() or (dwForceID == FORCE_TYPE.WU_XIANG and hPlayer.GetSkillLevel(102393) > 0)
            if not bForceLegal then
                TipsHelper.ShowNormalTip("当前配装方案与自身门派不一致或未学习该流派，无法保存")
                return
            end

            local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(tSelectInfo, false)

            local tbSetData = EquipCodeData.ExportCustomizedSetEquip(tEquip, dwKungfuID)
            if not tbSetData then
                return
            end

            UIMgr.Open(VIEW_ID.PanelCustomSetInputPop, dwKungfuID, tbSetData)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDeleteExit, EventType.OnClick, function(btn)
        self.bEnterDelMode = false
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入配装方案，请稍候")
            return
        end

        local tbDelCodes = {}
        for szCode, _ in pairs(self.tbSelectDelCode) do
            table.insert(tbDelCodes, szCode)
        end
        EquipCodeData.ReqDelEquip(tbDelCodes)
        self.tbSelectDelCode = {}
    end)
end

function UISetCodeListView:RegEvent()
    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT_EQUIPCODE" then
            if EquipCodeData.szSessionID then
                self.bLoginWeb = true
                EquipCodeData.ReqGetMyEquipList()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "MY_EQUIPS_LIST" then

        elseif szKey == "GET_EQUIPS" then
            self:UpdateBtnState()
        elseif szKey == "DEL_EQUIPS" then
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, EventType.OnUpdateEquipCodeList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectEquipCodeListCell, function (bSelected, szCode)
        if bSelected then
            self.szCurSelectCode = szCode
        elseif self.szCurSelectCode == szCode then
            self.szCurSelectCode = nil
        end

        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnSelectDelEquipCodeListCell, function (bSelected, szCode)
        if bSelected then
            self.tbSelectDelCode[szCode] = bSelected
        else
            self.tbSelectDelCode[szCode] = nil
        end
        self:UpdateBtnState()
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UISetCodeListView:InitView()
    self.bEnterDelMode = false

    self.tbSelectDelCode = {}
    EquipCodeData.LoginAccount(false)
end

function UISetCodeListView:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UISetCodeListView:UpdateBtnState()
    UIHelper.SetVisible(self.BtnDeleteExit, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnDelete, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnUse, not self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnManage, not self.bEnterDelMode)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    for _, cell in pairs(self.tbSetCell or {}) do
        cell:SetEnterDelMode(self.bEnterDelMode)
    end

    if self.szCurSelectCode then
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable)
    end

    if table.get_len(self.tbSelectDelCode) > 0 then
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Disable)
    end
end

function UISetCodeListView:UpdateListInfo()
    UIHelper.SetString(self.LabelTitleSize, string.format("%d/%d", #(EquipCodeData.tMyEquips or {}), MAX_DATA_COUNT))

    local tMyEquips = EquipCodeData.tMyEquips or {}

    self.szCurSelectCode = nil
    UIHelper.HideAllChildren(self.ScrollViewList)
    self.tbSetCell = self.tbSetCell or {}
    for i, tbInfo in ipairs(tMyEquips) do
        if not self.tbSetCell[i] then
            self.tbSetCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCloudSetCodeCell, self.ScrollViewList)
        end

        UIHelper.SetVisible(self.tbSetCell[i]._rootNode, true)
        self.tbSetCell[i]:OnEnter(tbInfo)
    end

    UIHelper.SetVisible(self.WidgetEmpty, #tMyEquips == 0)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UISetCodeListView:SetCloseCallback(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback
end

return UISetCodeListView