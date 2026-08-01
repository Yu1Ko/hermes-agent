-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceIconCell
-- Date: 2023-09-20 20:13:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceIconCell = class("UIBuildFaceIconCell")

local IconType = {
    -- 妆容部位
    Makeup      = 1,
    -- 妆容颜色
    Color       = 2,
    -- 脸部整体预设
    FaceAll     = 3,
    -- 脸部细节预设
    FacePrefab  = 4,
    -- 体型预设
    BodyPrefab  = 5,
    -- 旧版脸部整体预设
    OldFaceAll  = 6,
    -- 旧版妆容部位
    OldMakeup   = 7,
    -- 妆容颜色
    OldColor    = 8,
    -- 旧版妆容装饰物
    OldMakeupDecoration = 9,
    -- 披风改色
    CloakColor = 10,
    -- 发型染色
    HairDyeColor = 11,
}

function UIBuildFaceIconCell:OnEnter(nIconType, ...)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIconType = nIconType

    if self.nIconType == IconType.Makeup or self.nIconType == IconType.OldMakeup or self.nIconType == IconType.OldMakeupDecoration then
        self.tUIInfo, self.tDecalInfo = ...
    elseif self.nIconType == IconType.Color or self.nIconType == IconType.OldColor then
        self.nColorID, self.nType, self.nShowID = ...
    elseif self.nIconType == IconType.FaceAll or self.nIconType == IconType.OldFaceAll then
        self.tbInfo = ...
    elseif self.nIconType == IconType.FacePrefab then
        self.tbInfo = ...
    elseif self.nIconType == IconType.BodyPrefab then
        self.tbInfo = ...
    elseif self.nIconType == IconType.CloakColor then
        self.tbInfo = ...
    elseif self.nIconType == IconType.HairDyeColor then
        self.tbInfo = ...
    end
    self:UpdateInfo()
end

function UIBuildFaceIconCell:OnExit()
    self.bInit = false
end

function UIBuildFaceIconCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if self.nIconType == IconType.Makeup then
            if self.tUIInfo and (self.tUIInfo.nType or self.tUIInfo.nDecorationType) and self.tUIInfo.nShowID then
                local bIsDecoration = not not self.tUIInfo.nDecorationType
                local nShowID = self.tUIInfo.nShowID
                if bIsDecoration then
                    GetFaceLiftManager().SetDecorationShowFlag(true)
                    BuildFaceData.UpdateNowFaceDecorationShow(self.tUIInfo.nDecorationType, nShowID)
                    Event.Dispatch(EventType.OnChangeBuildMakeupPrefab)
                    return
                end

                BuildFaceData.UpdateNowFaceDecal(self.tUIInfo.nType, nShowID)
                local tAdjustInfo = Table_GetDecalsAdjustV2(self.tUIInfo.nType)
                local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]
                local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType,
                                        self.tUIInfo.nType,
                                        nShowID,
                                        tDecal.nColorID,
                                        true)

                if tDecal.nColorID > 0 then
                    for i = 1, 3 do
                        local szStringNow = table.concat({"fNewValue", i})
                        local nNowValue   = tDetail[szStringNow]

                        local szString = table.concat({"bShowScroll", i})
                        local bShow = tAdjustInfo[szString]
                        if bShow then
                            local szStringValue = table.concat({"fValue", i})
                            tDecal[szStringValue] = nNowValue
                        end
                    end
                end

                if tAdjustInfo.bValueXY then
                    for i = 1, 2 do
                        local szStringNow = table.concat({"fNewValue", i + 1})
                        local nNowValue   = tDetail and tDetail[szStringNow] or tDecal[szStringValue]
                        local szStringValue = table.concat({"fValue", i + 1})
                        tDecal[szStringValue] = nNowValue
                    end
                end

                Event.Dispatch(EventType.OnChangeBuildMakeupPrefab)
            end
        elseif self.nIconType == IconType.OldMakeup then
            if self.tUIInfo and self.tUIInfo.nType and self.tUIInfo.nShowID then
                if BuildFaceData.GetChangeSide() and self.tUIInfo.nFlipID > 0 then
                    BuildFaceData.UpdateNowOldFaceDecal(self.tUIInfo.nType, self.tUIInfo.nFlipID)
                else
                    BuildFaceData.UpdateNowOldFaceDecal(self.tUIInfo.nType, self.tUIInfo.nShowID)
                end
                Event.Dispatch(EventType.OnChangeBuildOldMakeupPrefab)
            end
        elseif self.nIconType == IconType.OldMakeupDecoration then
            if self.tUIInfo and self.tUIInfo.nDecorationID then
                BuildFaceData.UpdateNowOldFaceDecoration(self.tUIInfo.nDecorationID)
                Event.Dispatch(EventType.OnChangeBuildOldMakeupDecoration)
            end
        elseif self.nIconType == IconType.Color then
            BuildFaceData.UpdateNowFaceDecal(self.nType, self.nShowID, self.nColorID)
            Event.Dispatch(EventType.OnChangeBuildMakeupColor, self.nType, self.nShowID, self.nColorID)
        elseif self.nIconType == IconType.OldColor then
            local nShowID = self.nShowID
            if BuildFaceData.GetChangeSide() then
                local tUIInfo = Table_GetDecal(BuildFaceData.nRoleType, self.nType, nShowID)
                nShowID = tUIInfo.nFlipID
            end
            BuildFaceData.UpdateNowOldFaceDecal(self.nType, nShowID, self.nColorID)
            Event.Dispatch(EventType.OnChangeBuildOldMakeupColor, self.nType, self.nShowID, self.nColorID)
        elseif self.nIconType == IconType.FaceAll then
            if not self.szFilePath or self.tbInfo.szFilePath ~= self.szFilePath then
                self.tFaceConfig = BuildFaceData.GetFaceByFile(self.tbInfo.szFilePath)
                self.szFilePath = self.tbInfo.szFilePath
            end
            local bCanOperate = BuildFaceData.bCanOperate
            BuildFaceData.NowFaceCloneData(self.tFaceConfig, true)
            Event.Dispatch(EventType.OnChangeBuildFaceDefault, bCanOperate ~= BuildFaceData.bCanOperate)

            if BuildFaceData.bPrice then
                local szName = UIHelper.GBKToUTF8(self.tbInfo.szName)
                if not string.is_nil(szName) then
                    local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.ToggleSelect, TipsLayoutDir.RIGHT_CENTER, szName)
                    local nWidth = UIHelper.GetUtf8RichTextWidth(szName, 26, "HYJinKaiJ")
                    nWidth = math.min(nWidth, 460)
                    tipScript:SetWidth(nWidth)

                    local tipsScript = UIMgr.GetViewScript(VIEW_ID.PanelHoverTips)
                    if tipsScript and tipsScript._scriptBG then
                        tipsScript._scriptBG:SetSwallowTouches(false)
                    end
                end
            end
        elseif self.nIconType == IconType.OldFaceAll then
            if not self.szFilePath or self.tbInfo.szPath ~= self.szFilePath then
                self.tFaceConfig = BuildFaceData.GetOldFaceByFile(self.tbInfo.szPath)
                self.szFilePath = self.tbInfo.szPath
            end
            local bCanOperate = BuildFaceData.bCanOperate
            BuildFaceData.NowFaceCloneData(self.tFaceConfig, false)
            Event.Dispatch(EventType.OnChangeBuildFaceDefault, true)

            local szName = UIHelper.GBKToUTF8(self.tbInfo.szName)
            local szDesc = UIHelper.GBKToUTF8(self.tbInfo.szDes)

            local szTips = ""

            if not string.is_nil(szName) and not string.is_nil(szDesc) then
                szTips = string.format("%s\n%s", szName, szDesc)
            else
                szTips = szName .. szDesc
            end

            if not string.is_nil(szTips) then
                local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.ToggleSelect, TipsLayoutDir.RIGHT_CENTER, szTips)
                local nWidth = UIHelper.GetUtf8RichTextWidth(szTips, 26, "HYJinKaiJ")
                nWidth = math.min(nWidth, 460)
                tipScript:SetWidth(nWidth)
            end
        elseif self.nIconType == IconType.FacePrefab then
            local tBoneParams  	= BuildFaceData.GetFacePartByFile(self.tbInfo.szFilePath)
            BuildFaceData.SetFacePartByFile(tBoneParams)
            Event.Dispatch(EventType.OnChangeBuildFaceSubPrefab)
        elseif self.nIconType == IconType.BodyPrefab then
			local tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(self.tbInfo.szFilePath)
            if not tBodyParams or table.is_empty(tBodyParams) then
                BuildBodyData.UpdateNowBodyData(tBodyParams)
                Event.Dispatch(EventType.OnChangeBuildBodyDefault)
            end
        elseif self.nIconType == IconType.CloakColor then
            if self.tbInfo.fnAction then
                self.tbInfo.fnAction()
            end
        elseif self.nIconType == IconType.HairDyeColor then
            if self.tbInfo.fnAction then
                self.tbInfo.fnAction()
            end
        end
    end)
end

function UIBuildFaceIconCell:RegEvent()
    Event.Reg(self, EventType.OnChangeBuildMakeupColor, function (nType, nShowID, nColorID)
        if self.nIconType == IconType.Color then
            self:UpdateColorInfo(true)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupColor, function (nType, nShowID, nColorID)
        if self.nIconType == IconType.ColorOld then
            self:UpdateColorInfo(true)
        end
    end)
end

function UIBuildFaceIconCell:UpdateInfo()
    UIHelper.SetVisible(self.ImgColor, false)
    UIHelper.SetVisible(self.WidgetPrice, false)
    UIHelper.SetVisible(self.ImgNew, false)
    if self.nIconType == IconType.Makeup then
        self:UpdateMakeupInfo()
    elseif self.nIconType == IconType.Color then
        self:UpdateColorInfo()
    elseif self.nIconType == IconType.FaceAll then
        self:UpdateFaceAllInfo()
    elseif self.nIconType == IconType.FacePrefab then
        self:UpdateFacePrefabInfo()
    elseif self.nIconType == IconType.BodyPrefab then
        self:UpdateBodyPrefabInfo()
    elseif self.nIconType == IconType.OldFaceAll then
        self:UpdateOldFaceAllInfo()
    elseif self.nIconType == IconType.OldMakeup then
        self:UpdateOldMakeupInfo()
    elseif self.nIconType == IconType.OldColor then
        self:UpdateOldColorInfo()
    elseif self.nIconType == IconType.OldMakeupDecoration then
        self:UpdateOldMakeupDecorationInfo()
    elseif self.nIconType == IconType.CloakColor then
        self:UpdateCloakColorInfo()
    elseif self.nIconType == IconType.HairDyeColor then
        self:UpdateHairDyeColorInfo()
    end
end

function UIBuildFaceIconCell:UpdateColorInfo(bJustUpdateState)
	local tAdjustInfo = Table_GetDecalsAdjustV2(self.nType)
    if not tAdjustInfo then
        return
    end

    if not bJustUpdateState then
        if BuildFaceData.IsFit(self.nColorID, self.nType) or tAdjustInfo.bValueXY then
            local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType, self.nType, self.nShowID, self.nColorID, true)
            if self.nColorID ~= 0 and r and g and b and a then
                r = r * 255
                g = g * 255
                b = b * 255
                UIHelper.SetColor(self.ImgColor, cc.c3b(r, g, b))
            else
                UIHelper.SetColor(self.ImgColor, cc.c3b(255, 255, 255))
            end
        end
    end

    UIHelper.SetVisible(self.ImgColor, true)
end

function UIBuildFaceIconCell:UpdateMakeupInfo()
    if self.tUIInfo.dwIconID and self.tUIInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tUIInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]
    if self.tUIInfo.nDecorationType then
        tDecal = BuildFaceData.tNowFaceData.tDecoration[self.tUIInfo.nDecorationType]
    end

    if tDecal.nShowID == self.tUIInfo.nShowID then
        UIHelper.SetSelected(self.ToggleSelect, true)
    else
        UIHelper.SetSelected(self.ToggleSelect, false)
    end

    local bNew = false

    if BuildFaceData.bPrice then
        local nPrice = math.max(self.tDecalInfo.nCoinPrice, 0)
        local bFree = CoinShopData.GetFreeChance(true)
		if bFree then
			nPrice = 0
		end

		local bDis = CoinShop_IsDis(self.tDecalInfo)
		if bDis and not bFree then
			nPrice = math.floor(nPrice * self.tDecalInfo.nDiscount / 100)
		end

        local nLabel = self.tUIInfo.nLabel
        if nLabel then
            if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then

            elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                bNew = true
            end
        end

        UIHelper.SetVisible(self.WidgetPrice, true)
        UIHelper.SetString(self.LabelPrice, nPrice)
        UIHelper.LayoutDoLayout(self.LayoutPrice)
    end

    UIHelper.SetVisible(self.ImgNew, bNew)
end

function UIBuildFaceIconCell:UpdateFaceAllInfo()
	BeginSample("UIBuildFaceIconCell.UpdateFaceAllInfo")
    if self.tbInfo.dwIconID and self.tbInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tbInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    if not self.szFilePath or self.tbInfo.szFilePath ~= self.szFilePath or not self.tFaceConfig then
        self.szFilePath = self.tbInfo.szFilePath
        self.tFaceConfig = nil
        BuildFaceData.GetFaceByFileAsync(self.tbInfo.szFilePath, function (tFaceConfig)
            self.tFaceConfig = tFaceConfig
            local tNowFaceData 	= BuildFaceData.tNowFaceData
            if BuildFaceData.IsEqualFace(self.tFaceConfig, tNowFaceData) then
                UIHelper.SetSelected(self.ToggleSelect, true)
            else
                UIHelper.SetSelected(self.ToggleSelect, false)
            end
        end)
    else
        local tNowFaceData 	= BuildFaceData.tNowFaceData
        if BuildFaceData.IsEqualFace(self.tFaceConfig, tNowFaceData) then
            UIHelper.SetSelected(self.ToggleSelect, true)
        else
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    end
	EndSample()
end

function UIBuildFaceIconCell:UpdateFacePrefabInfo()
    if self.tbInfo.dwIconID and self.tbInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tbInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    local tNowFaceData 	= BuildFaceData.tNowFaceData
    local tBoneParams = BuildFaceData.GetFacePartByFile(self.tbInfo.szFilePath)
    if tNowFaceData and BuildFaceData.IsEqualPartFace(tNowFaceData.tBone, tBoneParams) then
        UIHelper.SetSelected(self.ToggleSelect, true)
    else
        UIHelper.SetSelected(self.ToggleSelect, false)
    end
end

function UIBuildFaceIconCell:UpdateBodyPrefabInfo()

end

function UIBuildFaceIconCell:UpdateOldFaceAllInfo()
    if self.tbInfo.dwIconID and self.tbInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tbInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    local tNowFaceData 	= BuildFaceData.tNowFaceData
    if not self.szFilePath or self.tbInfo.szPath ~= self.szFilePath then
        self.tFaceConfig = BuildFaceData.GetOldFaceByFile(self.tbInfo.szPath)
        self.szFilePath = self.tbInfo.szPath
    end
    if BuildFaceData.IsEqualFace(self.tFaceConfig, tNowFaceData) then
        UIHelper.SetSelected(self.ToggleSelect, true)
    else
        UIHelper.SetSelected(self.ToggleSelect, false)
    end
end

function UIBuildFaceIconCell:UpdateOldMakeupInfo()
    if self.tUIInfo.dwIconID and self.tUIInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tUIInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    if BuildFaceData.tNowFaceData then
        local tDecal = BuildFaceData.tNowFaceData.tFaceData.tDecal[self.tUIInfo.nType]
        if tDecal.nShowID == self.tUIInfo.nShowID or tDecal.nShowID == self.tUIInfo.nFlipID then
            UIHelper.SetSelected(self.ToggleSelect, true)
        else
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    else
        UIHelper.SetSelected(self.ToggleSelect, false)
    end

    local bNew = false

    if BuildFaceData.bPrice then
        local nPrice = math.max(self.tDecalInfo.nCoinPrice, 0)
        local bFree = CoinShopData.GetFreeChance(false)
		if bFree then
			nPrice = 0
		end

		local bDis = CoinShop_IsDis(self.tDecalInfo)
		if bDis and not bFree then
			nPrice = math.floor(nPrice * self.tDecalInfo.nDiscount / 100)
		end

        UIHelper.SetVisible(self.WidgetPrice, true)
        UIHelper.SetString(self.LabelPrice, nPrice)
        UIHelper.LayoutDoLayout(self.LayoutPrice)

        local nLabel = self.tUIInfo.nLabel
        if nLabel then
            if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then

            elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                bNew = true
            end
        end
    end

    UIHelper.SetVisible(self.ImgNew, bNew)
end

function UIBuildFaceIconCell:UpdateOldColorInfo(bJustUpdateState)
	local tAdjustInfo = Table_GetDecalsAdjust(self.nType)
	local tUIInfo = Table_GetDecal(BuildFaceData.nRoleType, self.nType, self.nShowID)

    if not bJustUpdateState then
        local nR = tUIInfo.tRGBA[1] or 255
        local nG = tUIInfo.tRGBA[2] or 255
        local nB = tUIInfo.tRGBA[3] or 255
        local nA = tUIInfo.tRGBA[4] or 255

        if self.nColorID ~= 0 then
            local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType, self.nType, self.nShowID, self.nColorID)
            r = r or 1
            g = g or 1
            b = b or 1
            a = a or 1

            if not tUIInfo.tRGBA or r ~= 1 or g ~= 1 or b ~= 1 then
                nR = r * 255
                nG = g * 255
                nB = b * 255
                nA = a * 255
            end
        end
        UIHelper.SetColor(self.ImgColor, cc.c3b(nR, nG, nB))
    end

    UIHelper.SetVisible(self.ImgColor, true)
end

function UIBuildFaceIconCell:UpdateOldMakeupDecorationInfo()
    if self.tUIInfo.dwIconID and self.tUIInfo.dwIconID > 0 then
        UIHelper.SetItemIconByIconID(self.ImgIcon, self.tUIInfo.dwIconID)
        UIHelper.SetVisible(self.ImgIcon, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
    end

    if BuildFaceData.tNowFaceData then
        local nDecorationID = BuildFaceData.tNowFaceData.tFaceData.nDecorationID
        if nDecorationID == self.tUIInfo.nDecorationID then
            UIHelper.SetSelected(self.ToggleSelect, true)
        else
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    else
        UIHelper.SetSelected(self.ToggleSelect, false)
    end

    if BuildFaceData.bPrice then
        local nPrice = math.max(self.tDecalInfo.nCoinPrice, 0)
        local bFree = CoinShopData.GetFreeChance(false)
		if bFree then
			nPrice = 0
		end

		local bDis = CoinShop_IsDis(self.tDecalInfo)
		if bDis and not bFree then
			nPrice = math.floor(nPrice * self.tDecalInfo.nDiscount / 100)
		end

        UIHelper.SetVisible(self.WidgetPrice, true)
        UIHelper.SetString(self.LabelPrice, nPrice)
        UIHelper.LayoutDoLayout(self.LayoutPrice)
    end
end

function UIBuildFaceIconCell:UpdateCloakColorInfo()
    UIHelper.SetVisible(self.ImgColor, true)
    local tColor = self.tbInfo.tColor
    UIHelper.SetColor(self.ImgColor, cc.c3b(tColor[2], tColor[3], tColor[4]))

end

function UIBuildFaceIconCell:UpdateHairDyeColorInfo()
    local tColor = self.tbInfo.tColor
    local szName = self.tbInfo.szName
    UIHelper.SetVisible(self.ImgColor, true)
    UIHelper.SetVisible(self.ImgBgName, not not szName)
    
    UIHelper.SetColor(self.ImgColor, cc.c3b(tColor.nR, tColor.nG, tColor.nB))
    UIHelper.SetString(self.LabelName, szName)
end


function UIBuildFaceIconCell:InitFontColor(tValue, toggleGroup, fnCallBack)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleSelect)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(toggle, bSelected)
        if bSelected and fnCallBack then
            fnCallBack()
        end
    end)

    if tValue then
        local r, g, b = tValue.r, tValue.g, tValue.b
        if r and g and b then
            UIHelper.SetColor(self.ImgColor, cc.c3b(r, g, b))
        else
            UIHelper.SetColor(self.ImgColor, cc.c3b(255, 255, 255))
        end
    end

    UIHelper.SetVisible(self.ImgColor, true)
end

return UIBuildFaceIconCell