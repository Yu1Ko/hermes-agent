-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraSeqListItem
-- Date: 
-- Desc: 连续运镜选择节点
-- ---------------------------------------------------------------------------------
local UISelfieCameraSeqListItem = class("UISelfieCameraSeqListItem")
local IMG_CUSTOM_CAMERA_ANI_PATH = "ui/Image/UICommon/Camera6.UITex"
local IMG_CUSTOM_CAMERA_ANI_FRAME = 0
function UISelfieCameraSeqListItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISelfieCameraSeqListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieCameraSeqListItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft , EventType.OnClick , function ()
        self.fnLeft(self.nPos)
    end)

    UIHelper.BindUIEvent(self.BtnRight , EventType.OnClick , function ()
        self.fnRight(self.nPos)
    end)
end

function UISelfieCameraSeqListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieCameraSeqListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieCameraSeqListItem:UpdateInfo(tInfo, nMaxPos)
    self.tInfo = tInfo
    local nType = tInfo.nType
    if nType then
        if nType == SelfieData.CAMERA_ANI_TYPE.DEFAULT then
            local nCamAniID = tInfo.nID
            local tCamInfo = Table_GetSelfieCameraAniData(nCamAniID)
            if tCamInfo and tCamInfo.szPreviewImgPath and tCamInfo.szPreviewImgPath ~= "" then
                UIHelper.SetTexture(self.ImgCameraMovementCont, UIHelper.FixDXUIImagePath(tCamInfo.szPreviewImgPath))
            end
            UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tCamInfo.szName))
        elseif nType == SelfieData.CAMERA_ANI_TYPE.CUSTOM then
            --UIHelper.SetSpriteFrame(self.ImgCameraMovementCont, IMG_CUSTOM_CAMERA_ANI_PATH,IMG_CUSTOM_CAMERA_ANI_FRAME)
        end
       
        UIHelper.SetVisible(self.ImgCameraMovementCont, true)
        UIHelper.SetVisible(self.BtnLeft, self.nPos > 1)
        UIHelper.SetVisible(self.BtnRight, self.nPos < nMaxPos)
        UIHelper.SetVisible(self.LabelName, true)
    else
        UIHelper.SetVisible(self.ImgCameraMovementCont, false)
        UIHelper.SetVisible(self.BtnLeft, false)
        UIHelper.SetVisible(self.BtnRight, false)
        UIHelper.SetVisible(self.ImgDeleteBg, false)
        UIHelper.SetVisible(self.LabelName, false)
    end
    UIHelper.SetVisible(self.ImgNum, true)
end

function UISelfieCameraSeqListItem:SetPos(nPos)
    self.nPos = nPos
end

function UISelfieCameraSeqListItem:SetLRClickCallback(fnLeft, fnRight)
    self.fnLeft = fnLeft
    self.fnRight = fnRight
end

function UISelfieCameraSeqListItem:UpdateSimpleInfo(tInfo)
    UIHelper.SetVisible(self.BtnLeft, false)
    UIHelper.SetVisible(self.BtnRight, false)
    UIHelper.SetVisible(self.ImgNum, false)

    self.tInfo = tInfo
    if tInfo then
        local nCamAniID = tInfo.nID
        local tCamInfo = Table_GetSelfieCameraAniData(nCamAniID)
        if tCamInfo and tCamInfo.szPreviewImgPath and tCamInfo.szPreviewImgPath ~= "" then
            UIHelper.SetTexture(self.ImgCameraMovementCont, UIHelper.FixDXUIImagePath(tCamInfo.szPreviewImgPath))
        end
        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tCamInfo.szName))
        UIHelper.SetVisible(self.ImgCameraMovementCont, true)
        UIHelper.SetVisible(self.LabelName, true)
    else
        UIHelper.SetVisible(self.ImgCameraMovementCont, false)
        UIHelper.SetVisible(self.LabelName, false)
    end
end

return UISelfieCameraSeqListItem