-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFaceCodeMainView
-- Date: 2024-03-15 09:51:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFaceCodeMainView = class("UIFaceCodeMainView")

local MAX_PAGE_NUMBER = 6
local MAX_DATA_COUNT = 30
local FilterIndex2RoleType =
{
    [1] = -1,
    [2] = ROLE_TYPE.STANDARD_MALE,
    [3] = ROLE_TYPE.STANDARD_FEMALE,
    [4] = ROLE_TYPE.LITTLE_BOY,
    [5] = ROLE_TYPE.LITTLE_GIRL,
}

local FacePageType = {
    OldFace = 1,
    NewFace = 2,
}

function UIFaceCodeMainView:OnEnter(bIsLogin)
    self.bIsLogin = bIsLogin
    self.nFacePageType = bIsLogin and FacePageType.NewFace or FacePageType.OldFace

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitView()
    self:UpdateInfo()
end

function UIFaceCodeMainView:OnExit()
    self.bInit = false
    FaceCodeData.UnInit()

    if self.funcCloseCallback then
        self.funcCloseCallback()
    end
end

function UIFaceCodeMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function(btn)
        self.bEnterDelMode = true

        self.bJustShowCanUse = false
        self.nJustShowRoleType = -1
        local tbFilterDefSelected = FilterDef.FaceCodeType.tbRuntime
        if tbFilterDefSelected then
            tbFilterDefSelected[1][1] = 1
            tbFilterDefSelected[2][1] = 1
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_CENTER, FilterDef.FaceCodeType)
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入脸型，请稍候")
            return
        end

        FaceCodeData.ReqGetFace(self.szCurSelectFaceCode)
        self.bUseBusy = true
        TipsHelper.ShowNormalTip("正在导入脸型，请稍候")
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable, "正在导入脸型，请稍候")
    end)

    UIHelper.BindUIEvent(self.BtnDeleteExit, EventType.OnClick, function(btn)
        self.bEnterDelMode = false

        self.bJustShowCanUse = true
        self.nJustShowRoleType = -1
        local tbFilterDefSelected = FilterDef.FaceCodeType.tbRuntime
        if tbFilterDefSelected then
            tbFilterDefSelected[1][1] = 2
            tbFilterDefSelected[2][1] = 1
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入脸型，请稍候")
            return
        end

        local tbDelFaceCodes = {}
        for szCode, _ in pairs(self.tbSelectDelFaceCode) do
            table.insert(tbDelFaceCodes, szCode)
        end
        FaceCodeData.ReqDelBatchFace(tbDelFaceCodes)
        self.tbSelectDelFaceCode = {}
    end)

    UIHelper.BindUIEvent(self.TogCanUseOnly, EventType.OnClick, function(btn)
        self.bJustShowCanUse = UIHelper.GetSelected(self.TogCanUseOnly)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        if self.nCurPageIndex >= self.nMaxPageCount then
            return
        end

        self.nCurPageIndex = self.nCurPageIndex + 1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        if self.nCurPageIndex <= 1 then
            return
        end

        self.nCurPageIndex = self.nCurPageIndex - 1
        self:UpdateInfo()
    end)

    for nType, tog in ipairs(self.tbTogPage) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nFacePageType = nType
            self.nCurPageIndex = 1
            self.szSearchText = ""
            UIHelper.SetText(self.EditKindSearch, self.szSearchText)
            self:UpdateInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupTab, tog)
    end
    UIHelper.SetToggleGroupSelected(self.TogGroupTab, self.nFacePageType - 1)


    UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected then
            self.nCurPageIndex = 1
            self.szSearchText = ""
            UIHelper.SetText(self.EditKindSearch, self.szSearchText)
            self:UpdateInfo()
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local szIndex = UIHelper.GetString(self.EditPaginate)
            local nIndex = tonumber(szIndex)
            self.nCurPageIndex = nIndex or self.nCurPageIndex
            self:UpdateInfo()
        end)

        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            local szSearch = UIHelper.GetString(self.EditKindSearch)
            self.nCurPageIndex = 1
            self.szSearchText = szSearch or ""
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local szIndex = UIHelper.GetString(self.EditPaginate)
            local nIndex = tonumber(szIndex)
            self.nCurPageIndex = nIndex or self.nCurPageIndex
            self:UpdateInfo()
        end)

        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            local szSearch = UIHelper.GetString(self.EditKindSearch)
            self.nCurPageIndex = 1
            self.szSearchText = szSearch or ""
            self:UpdateInfo()
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIFaceCodeMainView:RegEvent()
    Event.Reg(self, EventType.OnFaceCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT" then
            if FaceCodeData.szSessionID then
                self.bLoginWeb = true
                FaceCodeData.ReqGetConfig()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "GET_FACE_LIST" then
        elseif szKey == "GET_FACE" then
        elseif szKey == "FACES_LIST_BY_PAGING" then
            if tInfo and tInfo.code and tInfo.code ~= 1 then
                self.bUseBusy = false
                self:UpdateBtnState()
            end
        elseif szKey == "DEL_FACE" or szKey == "DEL_BATCH_FACE" then
            self:UpdateBtnState()
            self:DelayReqGetFaceList()
        end
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szFaceCode, szFilePath, nDataType)
        if bSuccess and szFaceCode == self.szCurSelectFaceCode then
            self.bUseBusy = false
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, EventType.OnUpdateSelfShareCodeList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnUpdateShareCodeListCell, function ()
        self:DelayUpdateList()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.FaceCodeType.Key then
            self.bJustShowCanUse = tbSelected[1][1] == 2
            self.nJustShowRoleType = FilterIndex2RoleType[tbSelected[2][1]]
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectFaceCodeListCell, function (bSelected, szFaceCode)
        if bSelected then
            self.szCurSelectFaceCode = szFaceCode
        elseif self.szCurSelectFaceCode == szFaceCode then
            self.szCurSelectFaceCode = nil
        end

        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnSelectDelFaceCodeListCell, function (bSelected, szFaceCode)
        if bSelected then
            self.tbSelectDelFaceCode[szFaceCode] = bSelected
        else
            self.tbSelectDelFaceCode[szFaceCode] = nil
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

function UIFaceCodeMainView:InitView()
    self.bEnterDelMode = false

    local tbFilterDefSelected = FilterDef.FaceCodeType.tbRuntime
    if tbFilterDefSelected then
        self.bJustShowCanUse = tbFilterDefSelected[1][1] == 2
        self.nJustShowRoleType = FilterIndex2RoleType[tbFilterDefSelected[2][1]]
    else
        self.bJustShowCanUse = true
        self.nJustShowRoleType = -1
    end
    self.tbSelectDelFaceCode = {}
    FaceCodeData.Init()
    FaceCodeData.LoginAccount(self.bIsLogin)

    self.nCurPageIndex = 1
    self.szSearchText = ""
    -- UIHelper.SetVisible(self.WidgetStepStart, self.bIsLogin)
    -- UIHelper.SetVisible(self.LayoutRightTop, not self.bIsLogin)

    -- if self.bIsLogin then
    --     self.bJustShowCanUse = true
    --     UIHelper.SetSelected(self.TogCanUseOnly, self.bJustShowCanUse)
    -- end
end

function UIFaceCodeMainView:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UIFaceCodeMainView:UpdateBtnState()
    UIHelper.SetVisible(self.BtnDeleteExit, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnDelete, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnUse, not self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnManage, not self.bEnterDelMode)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    for _, cell in ipairs(self.tbCells or {}) do
        cell:SetEnterDelMode(self.bEnterDelMode)
    end

    if self.szCurSelectFaceCode then
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable)
    end

    if table.get_len(self.tbSelectDelFaceCode) > 0 then
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Disable)
    end

    if self.bJustShowCanUse or self.nJustShowRoleType ~= -1 then
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing.png")
    else
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen.png")
    end
end

function UIFaceCodeMainView:UpdateListInfo()
    local nUploadLimit = MAX_DATA_COUNT
    if FaceCodeData.tbFaceListConfig then
        nUploadLimit = FaceCodeData.tbFaceListConfig.nUploadLimit
    end
    UIHelper.SetString(self.LabelTitleSize, string.format("%d/%d", #(FaceCodeData.tbFaceList or {}), nUploadLimit))

    local tbData = {}
    local nPrefabID1 = PREFAB_ID.WidgetVisionTitle
    local nPrefabID2 = PREFAB_ID.WidgetFaceCodeCell

    local tbFaceList = {}
    local tbFaceCount = {0, 0}
    for _, tbInfo in ipairs(FaceCodeData.tbFaceList or {}) do
        local bValid = false
        local bValidRoleType = false
        local tbFaceData = FaceCodeData.GetFaceData(tbInfo.szFaceCode)
        if tbFaceData then
            bValidRoleType = tbFaceData.nRoleType == self.nJustShowRoleType
            bValid = tbFaceData.nRoleType == BuildFaceData.nRoleType and
                            -- (not self.bIsLogin or not tbFaceData.bShop) and
                            (not self.bIsLogin or tbFaceData.bNewFace)

            if not self.bIsLogin then
                local bNewFace = ExteriorCharacter.IsNewFace()
                if (not bNewFace) ~= (not tbFaceData.bNewFace) then
                    bValid = false
                end
            end

            if tbFaceData.bNewFace then
                tbFaceCount[2] = tbFaceCount[2] + 1
            else
                tbFaceCount[1] = tbFaceCount[1] + 1
            end
        end

        if (not self.bJustShowCanUse or bValid) and (self.nJustShowRoleType == -1 or bValidRoleType) then
            table.insert(tbFaceList, tbInfo)
        end
    end

    table.sort(tbFaceList, function (a, b)
        local nNumA = a.nCreateTime or 100
        local nNumB = b.nCreateTime or 100
        if not a then
            nNumA = 0
            return nNumA > nNumB
        end

        if not b then
            nNumB = 0
            return nNumA > nNumB
        end

        local tbDataA = FaceCodeData.GetFaceData(a.szFaceCode)
        local tbDataB = FaceCodeData.GetFaceData(b.szFaceCode)
        if tbDataA and tbDataB then
            local bValidA = tbDataA.nRoleType == BuildFaceData.nRoleType and
                            (not self.bIsLogin or not tbDataA.bShop) and
                            (not self.bIsLogin or tbDataA.bNewFace)

            local bValidB = tbDataB.nRoleType == BuildFaceData.nRoleType and
            (not self.bIsLogin or not tbDataB.bShop) and
            (not self.bIsLogin or tbDataB.bNewFace)

            if bValidA and bValidB then
                return nNumA > nNumB
            elseif bValidA and not bValidB then
            nNumB = 0
                return nNumA > nNumB
            elseif not bValidA and bValidB then
                nNumA = 0
                return nNumA > nNumB
            end
        elseif tbDataA and not tbDataB then
            nNumB = 0
            return nNumA > nNumB
        elseif not tbDataA and tbDataB then
            nNumA = 0
            return nNumA > nNumB
        end
        return nNumA > nNumB
    end)

    local tbItemList = {{},{}}
    for _, tbInfo in ipairs(tbFaceList) do
        local tbInfo1 = Lib.copyTab(tbInfo)
        local tbTempInfo ={tbInfo = tbInfo1, bIsLogin = self.bIsLogin}
        local tbFaceData = FaceCodeData.GetFaceData(tbInfo1.szFaceCode)

        if string.is_nil(self.szSearchText) or (tbFaceData and string.find(tbFaceData.szFileName, self.szSearchText, 1, true)) then
            if tbInfo1.szSuffix == "dat" then
                tbInfo1.nIndex = #tbItemList[1] + 1
                table.insert(tbItemList[1], tbTempInfo)
            elseif tbInfo1.szSuffix == "ini" then
                tbInfo1.nIndex = #tbItemList[2] + 1
                table.insert(tbItemList[2], tbTempInfo)
            end
        end
    end
    self.szCurSelectFaceCode = nil
    self.tbSelectDelFaceCode = {}

    UIHelper.HideAllChildren(self.ScrollViewTab)
    local tbShowItemList = tbItemList[self.nFacePageType]

    self.tbCells = self.tbCells or {}
    self.nMaxPageCount = math.ceil(#tbShowItemList / MAX_PAGE_NUMBER)
    self.nCurPageIndex = math.min(self.nMaxPageCount, self.nCurPageIndex)
    self.nCurPageIndex = math.max(1, self.nCurPageIndex)

    local nStartIndex = (self.nCurPageIndex - 1) * MAX_PAGE_NUMBER + 1
    local nEndIndex = self.nCurPageIndex * MAX_PAGE_NUMBER
    if nEndIndex > #tbShowItemList then
        nEndIndex = #tbShowItemList
    end
    local nCellIndex = 1
    for nIndex = nStartIndex, nEndIndex do
        if not self.tbCells[nCellIndex] then
            self.tbCells[nCellIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceCodeCell, self.ScrollViewTab, tbShowItemList[nIndex], false)
        end
        self.tbCells[nCellIndex]:OnEnter(tbShowItemList[nIndex], true)
        UIHelper.SetVisible(self.tbCells[nCellIndex]._rootNode, true)
        nCellIndex = nCellIndex + 1
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)

    UIHelper.SetText(self.EditPaginate, self.nCurPageIndex)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", math.max(self.nMaxPageCount, 1)))

    for i, nCount in ipairs(tbFaceCount) do
        for _, label in ipairs(self["tbLabelPage"..i] or {}) do
            if i == 1 then
                UIHelper.SetString(label, string.format("写意\n(%d)", nCount))
            elseif i == 2 then
                UIHelper.SetString(label, string.format("写实\n(%d)", nCount))
            end
        end
    end
end

function UIFaceCodeMainView:DelayUpdateList()
    if self.nDelayUpdateListTimerID then
        Timer.DelTimer(self, self.nDelayUpdateListTimerID)
        self.nDelayUpdateListTimerID = nil
    end
    self.nDelayUpdateListTimerID = Timer.Add(self, 1, function ()
        FaceCodeData.ReqGetFaceList()
    end)
end

function UIFaceCodeMainView:DelayReqGetFaceList()
    if self.nDelayReqGetFaceListTimerID then
        Timer.DelTimer(self, self.nDelayReqGetFaceListTimerID)
        self.nDelayReqGetFaceListTimerID = nil
    end
    self.nDelayReqGetFaceListTimerID = Timer.Add(self, 1, function ()
        FaceCodeData.ReqGetFaceList()
    end)
end

function UIFaceCodeMainView:SetCloseCallback(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback
end

return UIFaceCodeMainView