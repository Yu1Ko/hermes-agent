-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfiePhotoCodeCell
-- Date: 2024-03-15 09:52:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfiePhotoCodeCell = class("UISelfiePhotoCodeCell")

local RoleType2Img = {
    [ROLE_TYPE.STANDARD_MALE] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ChengNan.png",
    [ROLE_TYPE.STANDARD_FEMALE] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ChengNv.png",
    [ROLE_TYPE.LITTLE_BOY] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ShaoNan.png",
    [ROLE_TYPE.LITTLE_GIRL] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ShaoNv.png",
}

function UISelfiePhotoCodeCell:OnEnter(tbInfo, bBody)
    if not tbInfo then return end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tbInfo.bIsEmpty then
        self.bIsEmpty = true
        UIHelper.SetVisible(self.WidgetContent, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.LayoutDoLayout(self._rootNode)
        return
    else
        self.bIsEmpty = nil
        UIHelper.SetVisible(self.WidgetContent, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.LayoutDoLayout(self._rootNode)
    end

    UIHelper.SetSelected(self.TogCodeList, false)
    UIHelper.SetSelected(self.TogCodeList_Delete, false)

    self.bEnterDelMode = false
    self.tbInfo = tbInfo.tbInfo
    self.bIsLogin = tbInfo.bIsLogin
    self:UpdateInfo()
end

function UISelfiePhotoCodeCell:OnInitWithLocalInfo(nIndex, szPath)
    self.bLocal = true
    self.nIndex = nIndex
    self.szPath = szPath

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo_Local()
end

function UISelfiePhotoCodeCell:OnExit()
    self.bInit = false
end

function UISelfiePhotoCodeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        SetClipboard(self.tbInfo.szShareCode)
        TipsHelper.ShowNormalTip("已复制拍照分享码")
    end)

    UIHelper.BindUIEvent(self.TogCodeList, EventType.OnClick, function(btn)
        if not self.bValid then return end
        local bSelected = UIHelper.GetSelected(self.TogCodeList)
        if self.bLocal then
            -- Event.Dispatch(EventType.OnSelectPhotoCodeListCell, bSelected, self.tbInfo.szPath)
            if self.funcCallback then
                self.funcCallback()
            end
        else
            Event.Dispatch(EventType.OnSelectPhotoCodeListCell, bSelected, self.tbInfo.szShareCode)
        end
    end)

    UIHelper.BindUIEvent(self.TogCodeList_Delete, EventType.OnClick, function(btn)
        local bSelected = UIHelper.GetSelected(self.TogCodeList_Delete)

        Event.Dispatch(EventType.OnSelectDelPhotoCodeListCell, bSelected, self.tbInfo.szShareCode)
    end)

    UIHelper.SetSwallowTouches(self.TogCodeList, false)
    UIHelper.SetSwallowTouches(self.TogCodeList_Delete, false)
end

function UISelfiePhotoCodeCell:RegEvent()
    Event.Reg(self, EventType.OnUpdateShareCodeListCell, function (szShareCode)
        if not self.bIsEmpty and self.tbInfo.szShareCode == szShareCode then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectPhotoCodeListCell, function (bSelected, szShareCode)
        if not self.bIsEmpty and self.tbInfo.szShareCode ~= szShareCode and bSelected then
            UIHelper.SetSelected(self.TogCodeList, false)
        end
    end)
end

function UISelfiePhotoCodeCell:UpdateInfo()
    if self.bLocal then
        self:UpdateLocalInfo()
    else
        self:UpdateCodeInfo()
    end

end

local tbFindStr = {
    "photosettings_mobile/",
    "photosettings_mobile\\",
}

function UISelfiePhotoCodeCell:UpdateInfo_Local()
    self.bValid = true

    local _, nIndex
    for index, szFindStr in ipairs(tbFindStr) do
        _, nIndex = string.find(self.szPath, szFindStr)
        if nIndex then
            break
        end
    end
    local szName = self.szPath
    if nIndex and nIndex > 0 then
        local nEndIndex = string.find(self.szPath, ".ini", 1, true)
        if not nEndIndex then
            nEndIndex = string.find(self.szPath, ".dat", 1, true) or 1
        end
        szName = string.sub(szName, nIndex + 1, nEndIndex - 1)
    end

    -- 这里是文件名
    if Platform.IsWindows() then
        szName = UIHelper.GBKToUTF8(szName)
    end

    local tbInfo = LoadLUAData(self.szPath, false, true, nil, true)
    if tbInfo then
        local tData = {
            szName = tbInfo.szName,
            szFileName = szName,
            nRoleType = tbInfo.tPlayerParam.nRoleType 
        }
        self.tbInfo = tData
        -- todo初始化
    end

    UIHelper.SetString(self.LabelTitle, UIHelper.LimitUtf8Len(szName, 9))
end

function UISelfiePhotoCodeCell:UpdateCodeInfo()
    if self.bIsEmpty then return end

    self.bValid = true
    local tbData = self.tbInfo
    if tbData then
        UIHelper.SetString(self.LabelTitle, tbData.szName)
        UIHelper.SetSpriteFrame(self.ImgBody, RoleType2Img[tbData.nRoleType])
        UIHelper.LayoutDoLayout(self.LayoutTitleBody)
    end
    UIHelper.SetString(self.LabelRankNum, self.tbInfo.nIndex)
    UIHelper.SetString(self.LabelCode, self.tbInfo.szShareCode)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetVisible(self.WidgetForbidden, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetNoUse, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetTogState, self.bValid)

    UIHelper.SetVisible(self.TogCodeList, not self.bEnterDelMode)
    UIHelper.SetVisible(self.TogCodeList_Delete, self.bEnterDelMode)
end

function UISelfiePhotoCodeCell:SetEnterDelMode(bEnterDelMode, bSelected)
    self.bEnterDelMode = bEnterDelMode
    self:UpdateInfo()
    UIHelper.SetSelected(self.TogCodeList_Delete, bSelected, false)
end

function UISelfiePhotoCodeCell:UpdateLocalInfo()
    local tbData = self.tbInfo
    UIHelper.SetVisible(self.WidgetForbidden, false)
    UIHelper.SetVisible(self.LabelState, false)
    UIHelper.SetVisible(self.BtnCopy, false)
    UIHelper.SetString(self.LabelTitle, tbData.szName)
    UIHelper.SetString(self.LabelCode, tbData.szFileName)
    UIHelper.SetSpriteFrame(self.ImgBody, RoleType2Img[tbData.nRoleType])
    UIHelper.SetVisible(self.WidgetNoUse, false)
end

function UISelfiePhotoCodeCell:SetSelectedCallback(funcCallback)
    if self.bLocal then
        self.funcCallback = funcCallback
    end
end

function UISelfiePhotoCodeCell:SetSelected(bSelected)
    if self.bLocal then
        UIHelper.SetSelected(self.TogCodeList, bSelected)
    end
end

function UISelfiePhotoCodeCell:SetEditMode(bInEditMode)
    self.bEnterDelMode = bInEditMode
    self:UpdateInfo()
    UIHelper.SetSelected(self.TogCodeList_Delete, false, false)
end

return UISelfiePhotoCodeCell