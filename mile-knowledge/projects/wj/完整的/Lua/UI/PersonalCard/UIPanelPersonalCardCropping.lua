-- ---------------------------------------------------------------------------------
-- Name: UIPanelPersonalCardCropping
-- Desc: 名片形象裁剪
-- ---------------------------------------------------------------------------------

local UIPanelPersonalCardCropping = class("UIPanelPersonalCardCropping")

function UIPanelPersonalCardCropping:OnEnter(picTexture, pImage, closeCallback)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.closeCallback = closeCallback
    self.picTexture = picTexture
    self.pImage = pImage
    self:UpdateInfo()
end

function UIPanelPersonalCardCropping:OnExit()
    if self.closeCallback then
        self.closeCallback()
    end

    if safe_check(self.pImage) then
        self.pImage:release()
    end

    self.bInit = false
    self:UnRegEvent()
end

function UIPanelPersonalCardCropping:BindUIEvent()
    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.ImgPerson)
    self.TouchComponent:SetScaleLimit(0.8, 2)
    self.TouchComponent:SetPosition(0, 0)
    self.TouchComponent:Scale(1)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)

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
        self.TouchComponent:Scale(1)
    end)

    UIHelper.BindUIEvent(self.BtnComplete, EventType.OnClick , function ()
        local tCropSize = self:GetPos()
        UIHelper.CropImage(function (pRetTexture, pImage)
            local nViewID = VIEW_ID.PanelPersonalCardAdorn
            local tInfo = {
                bUseImage = false,
                picTexture = pRetTexture,
                pImage = pImage,
            }
            if not UIMgr.GetView(nViewID) then
                UIMgr.Open(nViewID, tInfo, self.nPersonalCardIndex)
            end
            end, self.pImage, tCropSize.nLeft, tCropSize.nRight, -tCropSize.nTop, -tCropSize.nBottom, true)
    end)
end

function UIPanelPersonalCardCropping:RegEvent()
end

function UIPanelPersonalCardCropping:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelPersonalCardCropping:UploadImageDataTest(pImage)
    local hManager = GetShowCardCacheManager()
    if hManager then
        local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("personalcard/")))
        CPath.MakeDir(folder)
        local fileName = folder.. string.format("selfof%02d.png", self.nPersonalCardIndex)
        UIHelper.SaveImageToLocalFile(fileName, pImage, function()
            local pData = Lib.GetStringFromFile(fileName)
            local nSize = string.len(pData)
            hManager.CacheUploadImageDataForMobile(1, pData, nSize)
            hManager.UploadShowCardImage(self.nPersonalCardIndex)
        end)
    end
end

function UIPanelPersonalCardCropping:UploadImageDataNotSave(pImage)
    UIHelper.GetPngDataFromImage(function(pData, nSize)
        local hManager = GetShowCardCacheManager()
        if hManager then
            hManager.CacheUploadImageDataForMobile(1, pData, nSize)
            hManager.UploadShowCardImage(self.nPersonalCardIndex)
            if safe_check(pImage) then
                pImage:release()
            end
        end
    end, pImage)
end

function UIPanelPersonalCardCropping:UpdateInfo()
    self.scriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard)
    self.scriptCard:SetPlayerId(g_pClientPlayer.dwID)
    assert(self.scriptCard)
    self.scriptCard:SetBtnMaskFalse()
    Timer.AddFrame(self, 10, function()
        self.scriptCard:SetHeadBtnUnEnabled()
    end)
    self:UpdateImageByPic()
end

function UIPanelPersonalCardCropping:UpdateImageByPic()
    UIHelper.SetTextureWithBlur(self.ImgPerson, self.picTexture)
    local size = UIHelper.GetCurResolutionSize()
    UIHelper.SetContentSize(self.ImgPerson, size.width, size.height)
    self.sx, self.sy = UIHelper.GetScreenToResolutionScale()
    Timer.AddFrame(self, 1, function()
        local nodeW , nodeH =  UIHelper.GetContentSize(self.ImgPerson)
        self.TouchComponent:SetMoveRegion(-nodeW, nodeW, -nodeH, nodeH)
        self.TouchComponent:SetPosition(0, 0)
        self.TouchComponent:Scale(1)
    end)
end

function UIPanelPersonalCardCropping:AdjustViewScale()
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

function UIPanelPersonalCardCropping:GetPos()
    local tTempSize = {}
    local tCropSize = {}
    local width, height, scale
    local x, y = UIHelper.GetPosition(self.WidgetPersonalCard)
    -- width, height = UIHelper.GetContentSize(self.WidgetPersonalCard)
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

    -- LOG("===========" .. tCropSize.nLeft .. ",".. tCropSize.nRight .. "," .. tCropSize.nBottom .. "," .. tCropSize.nTop)
    return tCropSize
end

function UIPanelPersonalCardCropping:SetPersonalCardIndex(nIndex)
    self.nPersonalCardIndex = nIndex
end

return UIPanelPersonalCardCropping