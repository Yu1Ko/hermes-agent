-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieMyTemplateCloudList
-- Date: 2024-03-15 09:51:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieMyTemplateCloudList = class("UISelfieMyTemplateCloudList")
local DataModel = {}

function DataModel.Init()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    DataModel.tDataList         = nil
    DataModel.nDataCount        = 0
    DataModel.nUploadLimitCount = nil
    DataModel.szSearchText      = ""

    ShareCodeData.ApplyAccountConfig(false, SHARE_DATA_TYPE.PHOTO, true)
end

function DataModel.UnInit()
    for k, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[k] = nil
        end
    end
end

function DataModel.GetFilterList(tDataList)
    local szSearch = DataModel.szSearchText
    if szSearch and szSearch ~= "" then
        local tFilterList = {}
        for k, v in pairs(tDataList) do
            if szSearch ~= "" and string.find(v.szName, szSearch) then
                table.insert(tFilterList, v)
            end
        end
        return tFilterList
    else
        return clone(tDataList)
    end
end

function UISelfieMyTemplateCloudList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()

    self:InitView()
end

function UISelfieMyTemplateCloudList:OnExit()
    self.bInit = false

    if self.funcCloseCallback then
        self.funcCloseCallback()
    end
end

function UISelfieMyTemplateCloudList:BindUIEvent()
    self.scriptScrollViewTab = UIHelper.GetBindScript(self.WidgetList)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function(btn)
        self.bEnterDelMode = true

        self.nJustShowRoleType = -1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入拍照，请稍候。")
            return
        end

        local szChannel, szMsg = ShareCodeData.ApplyData(false, SHARE_DATA_TYPE.PHOTO, self.szCurSelectPhotoCode)
        self.bUseBusy = true
        TipsHelper.ShowNormalTip(szMsg)
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable, szMsg)
    end)

    UIHelper.BindUIEvent(self.BtnDeleteExit, EventType.OnClick, function(btn)
        self.bEnterDelMode = false

        self.nJustShowRoleType = -1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入拍照，请稍候。")
            return
        end

        local tbDelPhotoCodes = {}
        for szCode, _ in pairs(self.tbSelectDelPhotoCode) do
            table.insert(tbDelPhotoCodes, szCode)
        end
        UIHelper.ShowConfirm(g_tStrings.STR_SHARE_STATION_DELETE_CONFIRM, function ()
            ShareCodeData.ApplyDelDataList(false, SHARE_DATA_TYPE.PHOTO, tbDelPhotoCodes)
        end)
        self.tbSelectDelPhotoCode = {}
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)
    end
end

function UISelfieMyTemplateCloudList:RegEvent()
    Event.Reg(self, EventType.OnShareCodeRsp, function (szKey, tInfo)
        self.bUseBusy = false
        if szKey == "SHARE_GET_DATA" then
            if tInfo and tInfo.code and tInfo.code ~= 1 then
                self:UpdateBtnState()
            end
        elseif szKey == "SHARE_DEL_DATA" then
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            Timer.AddFrame(self, 1, function ()
                UIMgr.Close(self)
            end)
        else
            self.bUseBusy = false
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnUpdateSelfShareCodeList, function (nDataType, tDataList)
        if nDataType ~= SHARE_DATA_TYPE.PHOTO then
            return
        end

        DataModel.tDataList = clone(tDataList)
        DataModel.nDataCount = #DataModel.tDataList
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectPhotoCodeListCell, function (bSelected, szPhotoCode)
        if bSelected then
            self.szCurSelectPhotoCode = szPhotoCode
        elseif self.szCurSelectPhotoCode == szPhotoCode then
            self.szCurSelectPhotoCode = nil
        end

        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnSelectDelPhotoCodeListCell, function (bSelected, szPhotoCode)
        if bSelected then
            self.tbSelectDelPhotoCode[szPhotoCode] = bSelected
        else
            self.tbSelectDelPhotoCode[szPhotoCode] = nil
        end
        self:UpdateBtnState()
    end)
end

function UISelfieMyTemplateCloudList:InitView()
    self.bEnterDelMode = false

    self.nJustShowRoleType = -1
    self.tbSelectDelPhotoCode = {}
end

function UISelfieMyTemplateCloudList:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UISelfieMyTemplateCloudList:UpdateBtnState()
    UIHelper.SetVisible(self.BtnDeleteExit, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnDelete, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnUse, not self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnManage, not self.bEnterDelMode)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    for _, cell in pairs(self.tbPhotoCell or {}) do
        local bSelected = self.tbSelectDelPhotoCode[cell.tbInfo.szShareCode]
        cell:SetEnterDelMode(self.bEnterDelMode, bSelected)
    end

    if self.szCurSelectPhotoCode then
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable)
    end

    if table.get_len(self.tbSelectDelPhotoCode) > 0 then
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Disable)
    end

    if self.nJustShowRoleType ~= -1 then
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing.png")
    else
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen.png")
    end
end

function UISelfieMyTemplateCloudList:UpdateListInfo()
    local tConfig = ShareCodeData.GetAccountConfig(SHARE_DATA_TYPE.PHOTO)
    if not tConfig then
        ShareCodeData.ShowMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SHARE_STATION_GET_CONFIG_FAIL)
        return
    end

    UIHelper.SetString(self.LabelTitleSize, string.format("%d/%d", DataModel.nDataCount, tConfig.nUploadLimit or 0))

    local tbPhotoList = DataModel.GetFilterList(DataModel.tDataList)

    self.szCurSelectPhotoCode = nil
    UIHelper.HideAllChildren(self.ScrollViewPhotoList)
    self.tbPhotoCell = self.tbPhotoCell or {}
    for i, tbInfo in ipairs(tbPhotoList) do
        if not self.tbPhotoCell[i] then
            self.tbPhotoCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraCodeCell, self.ScrollViewPhotoList)
            self.tbPhotoCell[i]:OnEnter({tbInfo = tbInfo, bPhoto = true})
        end

        UIHelper.SetVisible(self.tbPhotoCell[i]._rootNode, true)
        self.tbPhotoCell[i]:OnEnter({tbInfo = tbInfo, bPhoto = true})
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPhotoList)
end

function UISelfieMyTemplateCloudList:SetCloseCallback(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback
end

function UISelfieMyTemplateCloudList:OnSearch(szSearch)
    DataModel.szSearchText = szSearch
    self:UpdateInfo()
end

return UISelfieMyTemplateCloudList