-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFaceCodeMainCell
-- Date: 2024-03-15 09:52:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFaceCodeMainCell = class("UIFaceCodeMainCell")

local RoleType2Img = {
    [ROLE_TYPE.STANDARD_MALE] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ChengNan.png",
    [ROLE_TYPE.STANDARD_FEMALE] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ChengNv.png",
    [ROLE_TYPE.LITTLE_BOY] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ShaoNan.png",
    [ROLE_TYPE.LITTLE_GIRL] = "UIAtlas2_NieLian_FaceCode_FaceCode_BodyTag_ShaoNv.png",
}

function UIFaceCodeMainCell:OnEnter(tbInfo, bBody)
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
    self.bBody = tbInfo.bBody
    self:UpdateInfo()
end

function UIFaceCodeMainCell:OnExit()
    self.bInit = false
end

function UIFaceCodeMainCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        if self.bBody then
            SetClipboard(self.tbInfo.szBodyCode)
            TipsHelper.ShowNormalTip("已复制体型码")
        else
            SetClipboard(self.tbInfo.szFaceCode)
            TipsHelper.ShowNormalTip("已复制捏脸码")
        end
    end)

    UIHelper.BindUIEvent(self.TogCodeList, EventType.OnClick, function(btn)
        if not self.bValid then return end
        local bSelected = UIHelper.GetSelected(self.TogCodeList)

        if self.bBody then
            Event.Dispatch(EventType.OnSelectBodyCodeListCell, bSelected, self.tbInfo.szBodyCode)
        else
            Event.Dispatch(EventType.OnSelectFaceCodeListCell, bSelected, self.tbInfo.szFaceCode)
        end
    end)

    UIHelper.BindUIEvent(self.TogCodeList_Delete, EventType.OnClick, function(btn)
        local bSelected = UIHelper.GetSelected(self.TogCodeList_Delete)

        if self.bBody then
            Event.Dispatch(EventType.OnSelectDelBodyCodeListCell, bSelected, self.tbInfo.szBodyCode)
        else
            Event.Dispatch(EventType.OnSelectDelFaceCodeListCell, bSelected, self.tbInfo.szFaceCode)
        end
    end)

    UIHelper.SetSwallowTouches(self.TogCodeList, false)
    UIHelper.SetSwallowTouches(self.TogCodeList_Delete, false)
end

function UIFaceCodeMainCell:RegEvent()
    Event.Reg(self, EventType.OnUpdateShareCodeListCell, function (szFaceCode)
        if not self.bIsEmpty and self.tbInfo.szFaceCode == szFaceCode then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectFaceCodeListCell, function (bSelected, szFaceCode)
        if not self.bIsEmpty and self.tbInfo.szFaceCode ~= szFaceCode and bSelected then
            UIHelper.SetSelected(self.TogCodeList, false)
        end
    end)

    Event.Reg(self, EventType.OnUpdateBodyCodeListCell, function (szCode)
        if not self.bIsEmpty and self.tbInfo.szBodyCode == szCode then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectBodyCodeListCell, function (bSelected, szCode)
        if not self.bIsEmpty and self.tbInfo.szBodyCode ~= szCode and bSelected then
            UIHelper.SetSelected(self.TogCodeList, false)
        end
    end)
end

function UIFaceCodeMainCell:UpdateInfo()
    if self.bBody then
        self:UpdateBodyCodeInfo()
    else
        self:UpdateFaceCodeInfo()
    end
end
function UIFaceCodeMainCell:UpdateFaceCodeInfo()
    if self.bIsEmpty then return end

    self.bValid = false
    local tbData = ShareCodeData.GetShareCodeData(self.tbInfo.szFaceCode)
    if tbData then
        self.bValid = tbData.nRoleType == BuildFaceData.nRoleType and
                        (not self.bIsLogin or tbData.bNewFace)

        if not self.bIsLogin then
            local bNewFace = ExteriorCharacter.IsNewFace()
            if (not bNewFace) ~= (not tbData.bNewFace) then
                self.bValid = false
            end
        end

        UIHelper.SetString(self.LabelTitle, tbData.szFileName)
        UIHelper.SetSpriteFrame(self.ImgBody, RoleType2Img[tbData.nRoleType])
        UIHelper.LayoutDoLayout(self.LayoutTitleBody)

        if self.bIsLogin and not tbData.bNewFace then
            UIHelper.SetString(self.LabelState, "类型不符")
        elseif tbData.nRoleType ~= BuildFaceData.nRoleType then
            UIHelper.SetString(self.LabelState, "体型不符")
        elseif not self.bValid then
            UIHelper.SetString(self.LabelState, "类型不符")
        end
    end
    UIHelper.SetString(self.LabelRankNum, self.tbInfo.nIndex)
    UIHelper.SetString(self.LabelCode, self.tbInfo.szFaceCode)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetVisible(self.WidgetForbidden, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetNoUse, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetTogState, self.bValid)

    UIHelper.SetVisible(self.TogCodeList, not self.bEnterDelMode)
    UIHelper.SetVisible(self.TogCodeList_Delete, self.bEnterDelMode)
end

function UIFaceCodeMainCell:UpdateBodyCodeInfo()
    if self.bIsEmpty then return end

    self.bValid = false
    local tbData = BodyCodeData.GetBodyData(self.tbInfo.szBodyCode)
    if tbData then
        self.bValid = tbData.nRoleType == BuildFaceData.nRoleType
        UIHelper.SetString(self.LabelTitle, tbData.szFileName)
        UIHelper.SetSpriteFrame(self.ImgBody, RoleType2Img[tbData.nRoleType])
        UIHelper.LayoutDoLayout(self.LayoutTitleBody)

        if tbData.nRoleType ~= BuildFaceData.nRoleType then
            UIHelper.SetString(self.LabelState, "体型不符")
        end
    end
    UIHelper.SetString(self.LabelRankNum, self.tbInfo.nIndex)
    UIHelper.SetString(self.LabelCode, self.tbInfo.szBodyCode)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetVisible(self.WidgetForbidden, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetNoUse, not self.bValid and not self.bEnterDelMode)
    UIHelper.SetVisible(self.WidgetTogState, self.bValid)

    UIHelper.SetVisible(self.TogCodeList, not self.bEnterDelMode)
    UIHelper.SetVisible(self.TogCodeList_Delete, self.bEnterDelMode)
end

function UIFaceCodeMainCell:SetEnterDelMode(bEnterDelMode)
    self.bEnterDelMode = bEnterDelMode
    self:UpdateInfo()
end

return UIFaceCodeMainCell