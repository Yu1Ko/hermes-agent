-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationCoverDetailView
-- Date: 2025-07-21 09:57:34
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_TAG_NUM = 3
local MAX_FACE_NAME_NUM = 8
local MAX_FACE_DESC_NUM = 50
local UIShareStationCoverDetailView = class("UIShareStationCoverDetailView")

function UIShareStationCoverDetailView:OnEnter(tInfo, nDataType, nPhotoSizeType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tInfo then
        self.bUseImage = tInfo.bUseImage
        self.pRetTexture = tInfo.picTexture
        self.pImage = tInfo.pImage
        --- upload
        self.nFaceType = tInfo.nFaceType
        self.szCoverPath = tInfo.szCoverPath
        self.szName = tInfo.szName
        self.szDesc = tInfo.szDesc
        self.szShareCode = tInfo.szShareCode
        self.tTag = clone(tInfo.tTag) or {}
    end

    self.nOpenStatus = tInfo.nOpenStatus or SHARE_OPEN_STATUS.PUBLIC
    if tInfo.nOpenStatus ~= SHARE_OPEN_STATUS.PRIVATE and tInfo.nOpenStatus ~= SHARE_OPEN_STATUS.PUBLIC then
        self.nOpenStatus = SHARE_OPEN_STATUS.PUBLIC
    end

    self.nDataType = nDataType
    self.nPhotoSizeType = nPhotoSizeType
    self.bIsUpdate = not not self.szShareCode
    self.bHaveNewCover = not not self.pImage

    self:UpdateInfo()

    Timer.AddFrame(self, 1, function ()
        if self.nOpenStatus == SHARE_OPEN_STATUS.PRIVATE then
            UIHelper.SetSelected(self.tbPublicStatusTog[1], false, false)
            UIHelper.SetSelected(self.tbPublicStatusTog[2], true, false)
        else
            UIHelper.SetSelected(self.tbPublicStatusTog[1], true, false)
            UIHelper.SetSelected(self.tbPublicStatusTog[2], false, false)
        end
    end)
end

function UIShareStationCoverDetailView:OnExit()
    if self.imgCoverData then
        self.imgCoverData:close()
    end

    if safe_check(self.pImage) then
        self.pImage:release()
    end

    if safe_check(self.pRetTexture) then
        self.pRetTexture:release()
    end

    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationCoverDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        local szName = UIHelper.GetText(self.EditBoxFaceName)
        local szDesc = UIHelper.GetText(self.EditBoxFaceDescribe)

        if szName ~= self.szName or szDesc ~= self.szDesc then
            UIHelper.ShowConfirm(g_tStrings.STR_SHARE_STATION_EXIT_CONFIRM, function ()
                UIMgr.Close(self)
            end)
            return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick , function ()
        self:DoUpdateFace()
    end)

    UIHelper.BindUIEvent(self.BtnUnload, EventType.OnClick , function ()
        self:DoUploadFace()
    end)

    UIHelper.BindUIEvent(self.BtnUnloadAndCopy, EventType.OnClick , function ()
        self:DoUploadFace(true)
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick , function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSingleTextTips, self.BtnTips, g_tStrings.STR_SHARE_STATION_PUBILC_TIP)
    end)

    UIHelper.BindUIEvent(self.BtnCropping, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    for index, tog in ipairs(self.tbPublicStatusTog) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.FameSelect)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged , function (tog, bSelected)
            if not bSelected then
                return
            end

            self.nOpenStatus = index == 1 and SHARE_OPEN_STATUS.PUBLIC or SHARE_OPEN_STATUS.PRIVATE
        end)
    end

    UIHelper.RegisterEditBoxChanged(self.EditBoxFaceName, function()
        if self.bIsUpdate then
            UIHelper.SetText(self.EditBoxFaceName, self.szName)
            TipsHelper.ShowNormalTip("作品名称上传后不可更改")
            return
        end

        local szName = UIHelper.GetText(self.EditBoxFaceName)
        local nLength = UIHelper.GetUtf8Len(szName)
        local szLimit = "%d/%d"
        if szName and nLength > MAX_FACE_NAME_NUM then
            szName = UIHelper.GetUtf8SubString(szName, 1, MAX_FACE_NAME_NUM)
            UIHelper.SetText(self.EditBoxFaceName, szName)
            nLength = MAX_FACE_NAME_NUM
        end
        UIHelper.SetString(self.LabelLimit_Name, string.format(szLimit, nLength, MAX_FACE_NAME_NUM))
        self:UpdateBtnState()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBoxFaceDescribe, function()
        local szDesc = UIHelper.GetText(self.EditBoxFaceDescribe)
        local nLength = UIHelper.GetUtf8Len(szDesc)
        local szLimit = "%d/%d"
        if szDesc and nLength > MAX_FACE_DESC_NUM then
            szDesc = UIHelper.GetUtf8SubString(szDesc, 1, MAX_FACE_DESC_NUM)
            UIHelper.SetText(self.EditBoxFaceDescribe, szDesc)
            nLength = MAX_FACE_DESC_NUM
        end
        UIHelper.SetString(self.LabelLimit_Desc, string.format(szLimit, nLength, MAX_FACE_DESC_NUM))
        self:UpdateBtnState()
    end)
end

function UIShareStationCoverDetailView:RegEvent()
    Event.Reg(self, EventType.OnShareCodeRsp, function (szKey, tInfo)
        if szKey == "SHARE_UPDATE_DATA_INFO" or szKey == "SHARE_UPLOAD_DATA_WITH_INFO" then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewFaceContent, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFaceContent)
        end)
    end)
end

function UIShareStationCoverDetailView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationCoverDetailView:UpdateInfo()
    if self.bIsUpdate then
        UIHelper.SetText(self.EditBoxFaceName, self.szName)
        UIHelper.SetText(self.EditBoxFaceDescribe, self.szDesc)
    else
        self.szName = ""
        self.szDesc = g_tStrings.STR_SHARE_STATION_UPLOAD_DEFAULT_DESC
        UIHelper.SetText(self.EditBoxFaceName, "未命名作品")
        UIHelper.SetText(self.EditBoxFaceDescribe, g_tStrings.STR_SHARE_STATION_UPLOAD_DEFAULT_DESC)
    end

    if self.nDataType then
        local nWidth, nHeight = ShareStationData.GetStandardSize(self.nDataType, self.nPhotoSizeType)
        UIHelper.SetContentSize(self.ImgRegionTipsBg, nWidth, nHeight)
        UIHelper.SetContentSize(self.WidgetFaceSC, nWidth, nHeight)
        -- UIHelper.SetContentSize(self.ImgFace, nWidth, nHeight)
        UIHelper.SetVisible(self.ImgFaceLine, self.nDataType == SHARE_DATA_TYPE.FACE)
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgFace)
        UIHelper.WidgetFoceDoAlign(self)
    end

    if self.bHaveNewCover then
        UIHelper.SetTextureWithBlur(self.ImgFace, self.pRetTexture)
    elseif self.szCoverPath then
        UIHelper.SetTexture(self.ImgFace, self.szCoverPath)
    end

    local szLimit = "%d/%d"
    local szNameText = UIHelper.GetText(self.EditBoxFaceName) or ""
    local szDescText = UIHelper.GetText(self.EditBoxFaceDescribe) or ""
    UIHelper.SetString(self.LabelLimit_Name, string.format(szLimit, UIHelper.GetUtf8Len(szNameText), MAX_FACE_NAME_NUM))
    UIHelper.SetString(self.LabelLimit_Desc, string.format(szLimit, UIHelper.GetUtf8Len(szDescText), MAX_FACE_DESC_NUM))
    UIHelper.SetVisible(self.BtnEdit, self.bIsUpdate)
    UIHelper.SetVisible(self.BtnCropping, self.bHaveNewCover)
    UIHelper.SetVisible(self.BtnUnload, not self.bIsUpdate)
    UIHelper.SetVisible(self.BtnUnloadAndCopy, not self.bIsUpdate)
    self:UpdateTag()
    self:UpdateBtnState()
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewFaceContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFaceContent)
end

function UIShareStationCoverDetailView:UpdateBtnState()
    local szNameText = UIHelper.GetText(self.EditBoxFaceName) or ""
    local szDescText = UIHelper.GetText(self.EditBoxFaceDescribe) or ""
    local nNameLen = UIHelper.GetUtf8Len(szNameText)
    local nDescLen = UIHelper.GetUtf8Len(szDescText)

    local bNameEmpty = string.is_nil(szNameText)
    local bDescEmpty = string.is_nil(szDescText)
    local bCanClick = not bNameEmpty and not bDescEmpty and nNameLen <= MAX_FACE_NAME_NUM and nDescLen <= MAX_FACE_DESC_NUM
    local szTips = bNameEmpty and "请输入作品名称" or bDescEmpty and "请输入作品描述"

    UIHelper.SetButtonState(self.BtnUnload, bCanClick and BTN_STATE.Normal or BTN_STATE.Disable, szTips)
    UIHelper.SetButtonState(self.BtnEdit, bCanClick and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnUnloadAndCopy, bCanClick and BTN_STATE.Normal or BTN_STATE.Disable, szTips)

    local szTagTips = string.format("标签（%d/%d）", table.GetCount(self.tTag), MAX_TAG_NUM)
    UIHelper.SetString(self.LabelShareFlagTitle, szTagTips)
end

function UIShareStationCoverDetailView:UpdateTag()
    UIHelper.RemoveAllChildren(self.LayoutFlag)
    self.scriptTagList = {}
    local tAllTag = Table_GetShareStationTagList(self.nDataType)
    for _, v in ipairs(tAllTag) do
        local nTagID = v.nTagID
        local szName = UIHelper.GBKToUTF8(v.szName)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShareStationFlag, self.LayoutFlag)
        script.nTagID = nTagID
        table.insert(self.scriptTagList, script)

        UIHelper.SetString(script.LabelFlag, szName)
        UIHelper.SetString(script.LabelFlagCheck, szName)
        UIHelper.SetSelected(script.TogFlag, table.contain_value(self.tTag, nTagID))
        UIHelper.SetToggleGroupIndex(script.TogFlag, -1)
        UIHelper.BindUIEvent(script.TogFlag, EventType.OnSelectChanged, function(tog, bSelected)
            if bSelected then
                AppendWhenNotExist(self.tTag, nTagID)
            else
                table.remove_value(self.tTag, nTagID)
            end

            local bFull = table.GetCount(self.tTag) >= MAX_TAG_NUM
            for _, scriptCell in ipairs(self.scriptTagList) do
                local bEnable = not bFull or table.contain_value(self.tTag, scriptCell.nTagID)
                UIHelper.SetEnable(scriptCell.TogFlag, bEnable)
                UIHelper.SetNodeGray(scriptCell.TogFlag, not bEnable, true)
            end
            self:UpdateBtnState()
        end)
    end

    local bFull = table.GetCount(self.tTag) >= MAX_TAG_NUM
    for _, scriptCell in ipairs(self.scriptTagList) do
        local bEnable = not bFull or table.contain_value(self.tTag, scriptCell.nTagID)
        UIHelper.SetEnable(scriptCell.TogFlag, bEnable)
        UIHelper.SetNodeGray(scriptCell.TogFlag, not bEnable, true)
    end
    UIHelper.LayoutDoLayout(self.LayoutFlag)
end

function UIShareStationCoverDetailView:DoUpdateFace()
    local szName = UIHelper.GetText(self.EditBoxFaceName)
    local szDesc = UIHelper.GetText(self.EditBoxFaceDescribe)
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szDesc)) then
        TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_DESC_ERROR)
        return
    end

    local fnSaveCover = function(fnCallBack)
        local nLimitWidth, nLimitHeight = ShareStationData.GetStandardSize(self.nDataType, self.nPhotoSizeType)
        local folder = ShareCodeData.GetShareFolderDir(true)
        local szCoverPath = folder.."\\"..ShareCodeData.GetCoverFileName()
        UIHelper.SaveImageToLocalFile(szCoverPath, self.pImage, function(nCaptureRet)
            UIHelper.SetButtonState(self.BtnUnload, BTN_STATE.DISABLED, g_tStrings.STR_SHARE_STATION_UPLOAD_COVER_BUSY)
            UIHelper.SetButtonState(self.BtnUnloadAndCopy, BTN_STATE.DISABLED, g_tStrings.STR_SHARE_STATION_UPLOAD_COVER_BUSY)
            if fnCallBack then
                fnCallBack(szCoverPath)
            end
        end, nLimitWidth, nLimitHeight)
    end

    local szTips = ""
    local tModifyInfo = {
        szName = szName,
        szDesc = szDesc,
        nOpenStatus = self.nOpenStatus,
        nRoleType = BuildFaceData.nRoleType or g_pClientPlayer.nRoleType,
        szUploadSource = "vk",
        tTag = self.tTag,
    }

    if self.nDataType == SHARE_DATA_TYPE.FACE then
        tModifyInfo.szSuffix = ShareCodeData.GetSuffixByFaceType(self.nFaceType)
    else
        tModifyInfo.szSuffix = "dat"
    end

    if self.bHaveNewCover then
        szTips = ShareCodeData.UpdateData(self.bIsLogin, self.nDataType, self.szShareCode, tModifyInfo, fnSaveCover)
    else
        szTips = ShareCodeData.UpdateData(self.bIsLogin, self.nDataType, self.szShareCode, tModifyInfo)
    end
    TipsHelper.ShowNormalTip(szTips)
end

function UIShareStationCoverDetailView:DoUploadFace(bCopyToClip)
    local szName = UIHelper.GetText(self.EditBoxFaceName)
    local szDesc = UIHelper.GetText(self.EditBoxFaceDescribe)
    local nNameLength = UIHelper.GetUtf8Len(szName)
    if nNameLength > MAX_FACE_NAME_NUM then
        TipsHelper.ShowNormalTip(string.format("名称长度不能超过%d个字", MAX_FACE_NAME_NUM))
        return
    end

    if MonsterBookData.MatchString(szName, " ") then
        TipsHelper.ShowNormalTip(g_tStrings.FACE_LIFT_CLOUD_EXPORT_NULL2)
        return
    end

    if not szName or szName == "" then
        TipsHelper.ShowNormalTip(g_tStrings.FACE_LIFT_CLOUD_EXPORT_NULL)
        return
    end

    --过滤文字
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szName)) then
        TipsHelper.ShowNormalTip(g_tStrings.FACE_LIFT_CLOUD_NAME_ERROR)
        return
    end

    if not TextFilterCheck(UIHelper.UTF8ToGBK(szDesc)) then
        TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_UPLOAD_DESC_ERROR)
        return
    end

    local fnSaveCover = function(fnCallBack)
        local nLimitWidth, nLimitHeight = ShareStationData.GetStandardSize(self.nDataType, self.nPhotoSizeType)
        local folder = ShareCodeData.GetShareFolderDir(true)
        local szCoverPath = folder.."\\"..ShareCodeData.GetCoverFileName()
        UIHelper.SaveImageToLocalFile(szCoverPath, self.pImage, function(nCaptureRet)
            UIHelper.SetButtonState(self.BtnUnload, BTN_STATE.DISABLED, g_tStrings.STR_SHARE_STATION_UPLOAD_COVER_BUSY)
            UIHelper.SetButtonState(self.BtnUnloadAndCopy, BTN_STATE.DISABLED, g_tStrings.STR_SHARE_STATION_UPLOAD_COVER_BUSY)
            if fnCallBack then
                fnCallBack(szCoverPath)
            end
        end, nLimitWidth, nLimitHeight)
    end

    local tPreviewData = ShareStationData.tPreviewData
    local tUploadInfo = {
        szName = szName,
        szDesc = szDesc,
        nOpenStatus = self.nOpenStatus,
        nRoleType = BuildFaceData.nRoleType or g_pClientPlayer.nRoleType,
        szSuffix = tPreviewData.bNewFace and "ini" or "dat",
        szUploadSource = "vk",
        tTag = self.tTag,
    }

    local nDataType = self.nDataType
    if nDataType == SHARE_DATA_TYPE.EXTERIOR then
        tUploadInfo.dwForceID = ShareExteriorData.GetForceID(tPreviewData) --只有穿了门派相关外观才会有有效的ForceID

        local tFilterData = clone(tPreviewData.tExteriorID)
        if not tFilterData then
            ShareCodeData.ShowMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SHARE_STATION_INVALID_EXTERIOR_DATA)
            return
        end
        ShareExteriorData.ParseCustomFilterFlag(tFilterData, tPreviewData.tDetail)
        tUploadInfo.tFilterData = tFilterData
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        local nPhotoMapType, dwPhotoMapID = SelfieTemplateBase.GetPhotoMapTypeAndID(tPreviewData)
        if not nPhotoMapType or not dwPhotoMapID then
            TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_INVALID_EXTERIOR_DATA)
            return
        end
        tPreviewData.szName = szName
        local tExteriorData = SelfieTemplateBase.GetPartPhotoDataByType(tPreviewData, SHARE_DATA_TYPE.PHOTO) --从一份完整的拍照数据里单独取出脸型/体型/穿搭数据
        tUploadInfo.dwForceID = ShareExteriorData.GetForceID(tExteriorData)
        tUploadInfo.nPhotoMapType = nPhotoMapType
        tUploadInfo.dwPhotoMapID = dwPhotoMapID
        tUploadInfo.nPhotoSizeType = self.nPhotoSizeType
    end

    local szTip = ShareCodeData.UploadData(self.bIsLogin, self.nDataType, tPreviewData, tUploadInfo, fnSaveCover, bCopyToClip)
    TipsHelper.ShowNormalTip(szTip)
end

return UIShareStationCoverDetailView