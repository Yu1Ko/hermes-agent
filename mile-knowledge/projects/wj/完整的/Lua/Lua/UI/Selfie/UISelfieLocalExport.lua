-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UISelfieLocalExport
-- Date: 2025-10-20 10:51:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieLocalExport = class("UISelfieLocalExport")
local MAX_FACE_NAME_NUM = 8

function UISelfieLocalExport:OnEnter(OnHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.OnHideCallback = OnHideCallback
end

function UISelfieLocalExport:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieLocalExport:Open(tPhotoData, picTexture, pImage, funcCallback, funcCallDetail, OnHideCallback)
    if not tPhotoData then
        return
    end
    self.tData = tPhotoData
    self.pImage = pImage
    self.picTexture = picTexture
    self.funcCallback = funcCallback
    self.funcCallDetail = funcCallDetail
    self.OnHideCallback = OnHideCallback
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
    self:UpdateInfo()
    self:UpdateEdit()
end

function UISelfieLocalExport:Hide(bShowDetail)
    self.bIsOpen = false
    UIHelper.SetVisible(self._rootNode , false)
    SelfieTemplateBase.SetTemplateImportState(false)
    if self.OnHideCallback and not bShowDetail then
        self.OnHideCallback()
    end
end

function UISelfieLocalExport:Show()
    UIHelper.SetVisible(self._rootNode , true)
end

function UISelfieLocalExport:IsOpen()
    return self.bIsOpen
end

function UISelfieLocalExport:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.LocalExportEditBox, function()
        self:UpdateEdit()
    end)

    UIHelper.BindUIEvent(self.BtnLocalExportClose, EventType.OnClick, function(btn)
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.BtnLocalExportMore, EventType.OnClick, function(btn)
        -- 详细信息
        local szFileName = UIHelper.GetText(self.LocalExportEditBox)
        self.funcCallDetail(szFileName)
        -- self:Hide()
        -- if self.DetailScript then
        --     self.DetailScript:OnEnter(self.tData, function ()
        --         self:Show()
        --     end)
        -- end
        -- self.DetailScript:Open()
    end)

    UIHelper.BindUIEvent(self.BtnLocalExportSave, EventType.OnClick, function(btn)
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        local bIsPortrait = UIHelper.GetScreenPortrait()
        local szFileName  = UIHelper.GetText(self.LocalExportEditBox)
        local bSucc, szMsg
        bSucc, szMsg = SelfieTemplateBase.ExportData(szFileName, self.tData, Player_GetRoleType(pPlayer), bIsPortrait)
        if not bSucc and szMsg then
            TipsHelper.ShowNormalTip(szMsg)
        end
        self:Hide()
    end)

    Event.Reg(self, EventType.OnFinishHotPhoto, function (pImage)
        UIHelper.SetTextureWithBlur(self.ImgPhoto, pImage)
    end)

    UIHelper.RegisterEditBoxChanged(self.LocalExportEditBox, function()
        local szName = UIHelper.GetText(self.LocalExportEditBox)
        local nLength = UIHelper.GetUtf8Len(szName)
        if szName and nLength > MAX_FACE_NAME_NUM then
            szName = UIHelper.GetUtf8SubString(szName, 1, MAX_FACE_NAME_NUM)
            UIHelper.SetText(self.LocalExportEditBox, szName)
            nLength = MAX_FACE_NAME_NUM
        end
        self:UpdateEditTextLength(nLength)
    end)
end

function UISelfieLocalExport:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieLocalExport:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------
function UISelfieLocalExport:UpdateEditTextLength(nLength)
    local szLimit = "%d/%d"
    UIHelper.SetString(self.LabelTextNum, string.format(szLimit, nLength, MAX_FACE_NAME_NUM))
end

function UISelfieLocalExport:UpdateInfo()
    local tPlace              = self.tData.tPlayerParam.tPlace
    local dwMapID             = tPlace.dwMapID
    local bIsHomelandMap      = SelfieTemplateBase.IsHomelandMap(dwMapID)
    local nMapType, dwPlaceID = SelfieTemplateBase.GetPhotoMapTypeAndID(self.tData)
    local szMap               = SelfieTemplateBase.GetPhotoMapName(nMapType, dwPlaceID)
    UIHelper.SetString(self.LabelLocalExportPlace, szMap)

    local szRoleType = g_tStrings.tShareDataRoleType[self.tData.tPlayerParam.nRoleType]
    local szRoleText = FormatString(g_tStrings.STR_ALL_PARENTHESES, szRoleType)
    local szContent  = string.format("角色参数<color=#ffea88>%s</color>", szRoleText)
    UIHelper.SetRichText(self.LabelLocalExportRoleType, szContent)
    self:UpdateImage()
    UIHelper.SetText(self.LocalExportEditBox, "照片模板")
    self:UpdateEditTextLength(4)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTem)
end

function UISelfieLocalExport:UpdateImage()
    local nTargetWidth, nTargetHeight = UIHelper.GetWidth(self.ImgPhoto), UIHelper.GetHeight(self.ImgPhoto)
    -- UIHelper.CompressImage(function()
        UIHelper.SetTextureWithBlur(self.ImgPhoto, self.picTexture)
    -- end, self.picTexture, nTargetWidth, nTargetHeight)

    self.funcCallback()
end

function UISelfieLocalExport:UpdateEdit()
    local szFileName = UIHelper.GetText(self.LocalExportEditBox)
    if not string.is_nil(szFileName) then
        UIHelper.SetButtonState(self.BtnLocalExportSave, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnLocalExportSave, BTN_STATE.Disable, "请先输入文件名")
    end
end

return UISelfieLocalExport