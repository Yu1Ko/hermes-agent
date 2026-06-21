-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationFaceCell
-- Date: 2025-07-20 14:49:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbStatus = {
    [SHARE_OPEN_STATUS.PRIVATE] = {szName = "私密", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH04"},
    [SHARE_OPEN_STATUS.PUBLIC] = {szName = "公开", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH08"},
    [SHARE_OPEN_STATUS.FILE_ILLEGAL] = {szName = "未通过", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH02"},
    [SHARE_OPEN_STATUS.COVER_ILLEGAL] = {szName = "未通过", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH02"},
    [SHARE_OPEN_STATUS.INVISIBLE] = {szName = "未通过", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH02"},
    [SHARE_OPEN_STATUS.CHECKING_TO_PRIVATE] = {szName = "审核中", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH01"},
    [SHARE_OPEN_STATUS.CHECKING_TO_PUBLIC] = {szName = "审核中", szImgBg = "UIAtlas2_Public_PublicItem_PublicItem1_Img_TabH01"},
}

local COVER_BASE_HEIGHT = 124

local UIShareStationFaceCell = class("UIShareStationFaceCell")

function UIShareStationFaceCell:OnEnter(nDataType, tbData, bRecommend)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDataType = nDataType
    self.tbData = tbData
    self.bRecommend = bRecommend -- 推荐数据
    self.nPhotoSizeType = tbData and tbData.nPhotoSizeType or nil
    self:UpdateInfo()
    self:AdjustCellHeight()
end

function UIShareStationFaceCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationFaceCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFaceCell, EventType.OnSelectChanged, function(tog, bSelect)
        -- UIHelper.SetEnable(self.TogFaceCell, ShareStationData.bDelMode or not bSelect)
        if self.szTip and bSelect then
            TipsHelper.ShowNormalTip(self.szTip)
        end

        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelect)
            return
        end

        if not ShareStationData.bDelMode then
            Event.Dispatch(EventType.OnSelectShareStationCell, self.tbData, bSelect)
        end

        if ShareStationData.bDelMode then
            ShareStationData.OnSelectBatchDel(self.tbData, bSelect)
        end
    end)

    UIHelper.SetSwallowTouches(self.TogLike, true)
    UIHelper.BindUIEvent(self.TogLike, EventType.OnSelectChanged, function(tog, bSelected)
        if not self.tbData then
            return
        end

        local bIsLogin = not GetClientPlayer()

        if bSelected then
            ShareCodeData.CollectData(bIsLogin, self.nDataType, self.tbData.szShareCode)
        else
            ShareCodeData.UnCollectData(bIsLogin, self.nDataType, self.tbData.szShareCode)
        end
    end)
end

function UIShareStationFaceCell:RegEvent()
    Event.Reg(self, EventType.OnDownloadShareCodeCover, function (bSuccess, szShareCode, szFilePath)
        if bSuccess and szShareCode == self.tbData.szShareCode then
            local szCoverPath = self.tbData.szCoverPath --封面路径
            UIHelper.ClearTexture(self.ImgFace)
            UIHelper.ReloadTexture(szCoverPath)
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnUpdateCollectShareCodeList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnUpdateSelfShareCodeList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnStartBatchDelShareCode, function ()
        self:SetBatchSelecte(true)
    end)

    Event.Reg(self, EventType.OnEndBatchDelShareCode, function ()
        self:SetBatchSelecte(false)
    end)

    Event.Reg(self, EventType.OnShareCodeRsp, function ()
        -- 收藏状态由 OnUpdateCollectShareCodeList → UpdateInfo 统一处理，避免重复设置导致爱心显示异常
    end)
end

function UIShareStationFaceCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationFaceCell:UpdateInfo()
    local tInfo = self.tbData
    local szShareCode = tInfo.szShareCode
    local szFileLink = tInfo.szFileLink --数据文件下载链接
    local nRoleType = tInfo.nRoleType --体型
    local szCoverLink = tInfo.szCoverLink --封面下载链接
    local szCoverPath = tInfo.szCoverPath --封面路径
    local dwCreateTime = tInfo.dwCreateTime --上传时间
    local szDesc = tInfo.szDesc --描述
    local szName = tInfo.szName --名字
    local nOpenStatus = tInfo.nOpenStatus --作品状态，包括：公开、私密、隐藏、审核中、审核失败、已删除
    local nHeat = tInfo.nHeat --总热度
    local szUser = tInfo.szUser --作者
    local tTags = tInfo.tTags --风格标签
    local nVersion = tInfo.nVersion --版本号
    local szUploadSource = tInfo.szUploadSource --上传来源
    local nRewards = tInfo.nRewards --打赏金额
    local bCertified = tInfo.bCertified --是否认证
    local nPos = tInfo.nPos --位置

    -- 捏脸站
    local szSuffix = tInfo.szSuffix
    -- 搭配站
    local dwForceID = tInfo.dwForceID
    -- 拍照站
    local nPhotoSizeType = tInfo.nPhotoSizeType
    local nPhotoMapType = tInfo.nPhotoMapType
    local dwPhotoMapID = tInfo.dwPhotoMapID

    local tbStatu = tbStatus[nOpenStatus] or {}
    local szStatus = tbStatu.szName
    local szImgBg = tbStatu.szImgBg
    local bHaveCover = szCoverPath and szCoverPath ~= "" and Lib.IsFileExist(szCoverPath, false)
    local bOwner = ShareStationData.IsSelfShare(szShareCode)
    local bHaveCollect = ShareStationData.IsCollectShare(szShareCode)
    UIHelper.SetString(self.LabelFaceName, szName, 5)
    UIHelper.SetString(self.LabelHeat, nHeat)
    UIHelper.SetString(self.LabelPublic, szStatus)
    UIHelper.SetSpriteFrame(self.ImgPublic, szImgBg)
    if bHaveCover then
        UIHelper.SetTexture(self.ImgFace, szCoverPath, false)
    end

    -- UIHelper.SetVisible(self.ImgFace, bHaveCover)
    UIHelper.SetVisible(self.TogLike, self.bRecommend and not bOwner)
    UIHelper.SetSelected(self.TogLike, bHaveCollect and self.bRecommend, false)

    UIHelper.SetVisible(self.ImgCollcet, bHaveCollect and not self.bRecommend)
    UIHelper.SetVisible(self.ImgUpload, bOwner)
    UIHelper.SetVisible(self.WidgetImgFaceEmpty, not bHaveCover and self.nDataType == SHARE_DATA_TYPE.FACE)

    UIHelper.SetVisible(self.ImgPC, szUploadSource == "dx")
    UIHelper.SetVisible(self.ImgPhone, szUploadSource == "vk")
    UIHelper.SetVisible(self.ImgCertified, bCertified)
    UIHelper.SetVisible(self.ImgUnseemliness, not self.bRecommend and nRoleType ~= ShareStationData.nRoleType)
    UIHelper.LayoutDoLayout(self.WidgetTypeIcons)
end

function UIShareStationFaceCell:AdjustCellHeight()
    if self.nDataType == SHARE_DATA_TYPE.PHOTO and self.nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
        return
    end

    local nBaseWeight, nBaseHeight = ShareStationData.GetStandardSize(self.nDataType, self.nPhotoSizeType)
    if not nBaseHeight or not nBaseWeight then
        return
    end

    local ratio = COVER_BASE_HEIGHT / nBaseWeight
    local nHeight = math.floor(nBaseHeight * ratio)

    local nTotalHeight = UIHelper.GetHeight(self._rootNode)
    UIHelper.SetHeight(self._rootNode, nTotalHeight + (nHeight - COVER_BASE_HEIGHT))
    UIHelper.SetHeight(self.ImgBg, nTotalHeight + (nHeight - COVER_BASE_HEIGHT))
    UIHelper.SetHeight(self.ImgBgFace, nHeight)
    -- UIHelper.SetHeight(self.ImgFace, nHeight)

    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgBg)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgBgFace)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgFace)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIShareStationFaceCell:GetSelected()
    return UIHelper.GetSelected(self.TogFaceCell)
end

function UIShareStationFaceCell:SetBatchSelecte(bSet)
    UIHelper.SetVisible(self.ImgChooseBg, bSet)
end

function UIShareStationFaceCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogFaceCell, bSelected)
end

function UIShareStationFaceCell:SetSelectedCallback(fnCallback)
    self.fnSelectedCallback = fnCallback
end

function UIShareStationFaceCell:UpdateInvisible(szPage)
    if not self.tbData or not self.tbData.nOpenStatus then
        return
    end

    local bShowCover = true
    local nOpenStatus = self.tbData.nOpenStatus
    if szPage == "Rank" then
        self.szTip = nil
        bShowCover = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif szPage == "Like" then
        self.szTip = nil
        bShowCover = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif szPage == "Self" then
        self.bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
                                or nOpenStatus == SHARE_OPEN_STATUS.PRIVATE
                                or nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL
    end

    if bShowCover then
        bShowCover = nOpenStatus ~= SHARE_OPEN_STATUS.COVER_ILLEGAL and nOpenStatus ~= SHARE_OPEN_STATUS.FILE_ILLEGAL
    end

    UIHelper.SetVisible(self.ImgFaceHide, not self.bEnablePreview or not bShowCover)
    if not self.bEnablePreview or not bShowCover then
        UIHelper.ClearTexture(self.ImgFace)
    end
end

return UIShareStationFaceCell