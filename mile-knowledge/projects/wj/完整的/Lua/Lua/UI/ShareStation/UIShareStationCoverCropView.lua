-- ---------------------------------------------------------------------------------
-- Name: UIShareStationCoverCropView
-- Desc: 名片形象裁剪
-- ---------------------------------------------------------------------------------
local INDEX_TO_SIZE_TYPE = {
    [1] = SHARE_PHOTO_SIZE_TYPE.HORIZONTAL,
    [2] = SHARE_PHOTO_SIZE_TYPE.VERTICAL,
}
local UIShareStationCoverCropView = class("UIShareStationCoverCropView")

function UIShareStationCoverCropView:OnEnter(picTexture, pImage, nDataType, nPhotoSizeType, tUploadInfo, closeCallback)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end

    ShareCodeData.Init()
    self.closeCallback = closeCallback
    self.picTexture = picTexture
    self.pImage = pImage
    self.bIsLogin = false -- 创角界面无法上传
    self.tUploadInfo = tUploadInfo
    self.nDataType = nDataType
    self.nPhotoSizeType = nPhotoSizeType

    self:UpdateInfo()
end

function UIShareStationCoverCropView:OnExit()
    UITouchHelper._onUIZoomCallback = nil
    if self.closeCallback then
        self.closeCallback()
    end

    if self.imgCoverData then
        self.imgCoverData:close()
    end

    if safe_check(self.pImage) then
        self.pImage:release()
    end

    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationCoverCropView:BindUIEvent()
    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.ImgPerson)
    self.TouchComponent:SetScaleLimit(0.64, 1)
    self.TouchComponent:SetPosition(0, 0)
    self.TouchComponent:Scale(0.7)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)

    for nIndex, tog in ipairs(self.tbSizeTypeTogs) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            if UIHelper.GetScreenPortrait() then
                Timer.AddFrame(self, 1, function ()
                    self.nPhotoSizeType = INDEX_TO_SIZE_TYPE[2]
                    UIHelper.SetSelected(self.tbSizeTypeTogs[1], false)
                    UIHelper.SetSelected(self.tbSizeTypeTogs[2], true)
                    TipsHelper.ShowNormalTip("当前不可选择横屏模式")
                end)
                return
            end
            self.TouchComponent:SetPosition(0, 0)
            self.TouchComponent:Scale(0.7)
            self.nPhotoSizeType = INDEX_TO_SIZE_TYPE[nIndex]
            self:UpdateMask()
        end)
    end

    UIHelper.SetTouchDownHideTips(self.BtnChangeImg, false)
    UIHelper.SetSwallowTouches(self.BtnChangeImg, true)
    UIHelper.BindUIEvent(self.BtnChangeImg, EventType.OnTouchBegan, function(btn, nX, nY)
        self.TouchComponent:TouchBegin(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnChangeImg, EventType.OnTouchMoved, function(btn, nX, nY)
        self.TouchComponent:TouchMoved(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick , function ()
        self.TouchComponent:SetPosition(0, 0)
        self.TouchComponent:Scale(0.7)
    end)

    UIHelper.BindUIEvent(self.BtnComplete, EventType.OnClick , function ()
        local tCropSize = self:GetPos()
        UIHelper.CropImage(function (pRetTexture, pImage)
            pRetTexture:retain()
            local tInfo = {
                bUseImage = false,
                picTexture = pRetTexture,
                pImage = pImage,
            }
            self.tCropInfo = tInfo
            Timer.AddFrame(self, 5, function ()
                if self.nDataType == SHARE_DATA_TYPE.FACE then
                    self:CheckVaild()
                else
                    Event.Dispatch(EventType.OnFaceCheckValidSuccess)
                end
            end)
        end, self.pImage, tCropSize.nLeft, tCropSize.nRight, -tCropSize.nTop, -tCropSize.nBottom, true)
    end)
end

function UIShareStationCoverCropView:RegEvent()
    Event.Reg(self, EventType.OnFaceCheckValidSuccess, function ()
        local nViewID = VIEW_ID.PanelEditFaceDetail
        if not UIMgr.GetView(nViewID) then
            if self.tUploadInfo then
                for k, v in pairs(self.tUploadInfo) do
                    self.tCropInfo[k] = v
                end
            end
            UIMgr.Open(nViewID, self.tCropInfo, self.nDataType, self.nPhotoSizeType)
        end
    end)

    Event.Reg(self, EventType.OnShareCodeRsp, function (szKey, tInfo)
        if szKey == "SHARE_UPDATE_DATA_INFO" or szKey == "SHARE_UPLOAD_DATA_WITH_INFO" then
            UIMgr.Close(self)
        end
    end)
end

function UIShareStationCoverCropView:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShareStationCoverCropView:CheckVaild()
    local folder = ShareCodeData.GetShareFolderDir(true)
    CPath.MakeDir(folder)
    local szCoverPath = folder.."\\"..ShareCodeData.GetCoverFileName()

    UIHelper.SaveImageToLocalFile(szCoverPath, self.tCropInfo.pImage, function(nCaptureRet)
        Timer.AddFrame(self, 1, function ()
            ShareCodeData.CheckValid(szCoverPath)
        end)
    end)
end

function UIShareStationCoverCropView:UpdateInfo()
    self:UpdateSizeTypeTog()
    self:UpdateMask()
    self:UpdateImageByPic()
end

function UIShareStationCoverCropView:UpdateSizeTypeTog()
    UIHelper.SetVisible(self.WidgetTogTypeScreen, self.nDataType == SHARE_DATA_TYPE.PHOTO and self.nPhotoSizeType ~= SHARE_PHOTO_SIZE_TYPE.CARD)
    if self.nPhotoSizeType and self.nPhotoSizeType ~= SHARE_PHOTO_SIZE_TYPE.CARD then
        for k, v in pairs(INDEX_TO_SIZE_TYPE) do
            UIHelper.SetSelected(self.tbSizeTypeTogs[k], v == self.nPhotoSizeType, false)
        end
    end
end

function UIShareStationCoverCropView:UpdateMask()
    if not self.nDataType then
        return
    end

    local nWidth, nHeight = ShareStationData.GetStandardSize(self.nDataType, self.nPhotoSizeType)
    UIHelper.SetContentSize(self.ImgRegionTipsBg, nWidth, nHeight)
    UIHelper.SetContentSize(self.WidgetFaceSC, nWidth, nHeight)
    UIHelper.SetContentSize(self.Mask, nWidth, nHeight)
    UIHelper.SetContentSize(self.ImgRangeSC, nWidth, nHeight)
    UIHelper.SetVisible(self.ImgFaceLine, self.nDataType == SHARE_DATA_TYPE.FACE)
    UIHelper.WidgetFoceDoAlign(self)
    self.TouchComponent:SetRangeWidget(self.WidgetFaceSC)
end

function UIShareStationCoverCropView:UpdateImageByPic()
    UIHelper.SetTextureWithBlur(self.ImgPerson, self.picTexture)
    local size = UIHelper.GetCurResolutionSize()
    UIHelper.SetContentSize(self.ImgPerson, size.width, size.height)
    self.sx, self.sy = UIHelper.GetScreenToResolutionScale()
    Timer.AddFrame(self, 1, function()
        local nodeW, nodeH =  UIHelper.GetContentSize(self.ImgPerson)
        self.TouchComponent:SetMoveRegion(-nodeW / 2, nodeW / 2, -nodeH / 2, nodeH / 2)
        self.TouchComponent:SetRangeWidget(self.ImgRegionTipsBg)
        self.TouchComponent:SetPosition(0, 0)
        self.TouchComponent:Scale(0.7)
    end)
end

function UIShareStationCoverCropView:AdjustViewScale()
    local tbScreenSize = UIHelper.DeviceScreenSize()
    local nodeW , nodeH =  UIHelper.GetContentSize(self.ImgPerson)

    local newNodeW = nodeH / tbScreenSize.height * tbScreenSize.width
    if newNodeW < nodeW then
        nodeH = nodeW / tbScreenSize.width * tbScreenSize.height
    else
        nodeW = newNodeW
    end
    UIHelper.SetContentSize(self.ImgPerson, nodeW , nodeH)
end

function UIShareStationCoverCropView:GetPos()
    local tTempSize = {}
    local tCropSize = {}
    local width, height, scale
    local x, y = UIHelper.GetPosition(self.WidgetFaceSC)
    -- width, height = UIHelper.GetContentSize(self.WidgetFaceSC)
    tTempSize.nLeft = x
    tTempSize.nRight = 0 - x
    tTempSize.nBottom = y
    tTempSize.nTop = 0 - y

    width, height = UIHelper.GetPosition(self.ImgPerson) -- 以img中心（0.5，0.5）为原点
    tCropSize.nLeft = tTempSize.nLeft - width
    tCropSize.nRight = tTempSize.nRight - width
    tCropSize.nBottom = tTempSize.nBottom - height
    tCropSize.nTop = tTempSize.nTop - height

    if self.TouchComponent then
        scale = self.TouchComponent:GetScale()
    else
        scale = 1
    end

    tCropSize.nLeft = tCropSize.nLeft / scale * self.sx
    tCropSize.nRight = tCropSize.nRight / scale * self.sx
    tCropSize.nBottom = tCropSize.nBottom / scale * self.sy
    tCropSize.nTop = tCropSize.nTop / scale * self.sy

    LOG("===========" .. tCropSize.nLeft .. ",".. tCropSize.nRight .. "," .. tCropSize.nBottom .. "," .. tCropSize.nTop)
    return tCropSize
end

return UIShareStationCoverCropView