-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceDetailAdjustPart
-- Date: 2023-10-08 16:00:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceDetailAdjustPart = class("UIBuildFaceDetailAdjustPart")

function UIBuildFaceDetailAdjustPart:OnEnter(szClassName, tDecalInfo, tUIInfo, tCacheSetting, bIsOldFace)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szClassName = szClassName
    self.tDecalInfo = tDecalInfo
    self.tUIInfo = tUIInfo
    self.tCacheSetting = tCacheSetting
    self.bIsOldFace = bIsOldFace

    self.nCurSelectColorIndex = 1

    self.tCurDecal = BuildFaceData.tNowFaceData.tDecal
    if self.bIsOldFace then
        self.tCurDecal = BuildFaceData.tNowFaceData.tFaceData.tDecal
    end

    self:UpdateInfo()
end

function UIBuildFaceDetailAdjustPart:OnExit()
    self.bInit = false
end

function UIBuildFaceDetailAdjustPart:BindUIEvent()

end

function UIBuildFaceDetailAdjustPart:RegEvent()
    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValue, function (tbInfo, nValue)
        local tDecal = self.tCurDecal[self.tUIInfo.nType]

        tDecal.bChangeValue = true
        if self.bIsOldFace then
            local szStringValue = table.concat({"fValue", tbInfo.nIndex})
            tDecal[szStringValue] = nValue / 100

            Event.Dispatch(EventType.OnChangeBuildOldMakeupValue)
        else
            local szStringValue = table.concat({"fValue", tbInfo.nIndex})
            tDecal[szStringValue] = nValue / 100

            BuildFaceData.CopyRightType(self.tUIInfo.nType)

            Event.Dispatch(EventType.OnChangeBuildMakeupValue)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupColor, function (nType, nShowID, nColorID)
        if self.tUIInfo.nType ~= nType or self.tUIInfo.nShowID ~= nShowID then
            return
        end

        self.nCurSelectColorIndex = table.get_key(self.tDecalInfo.tColorID, nColorID)
        self:InitData()
        self:UpdateCurColorInfo()
        self:UpdateDetailAdjustInfo()
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupColor, function (nType, nShowID, nColorID)
        if self.tUIInfo.nType ~= nType or self.tUIInfo.nShowID ~= nShowID then
            return
        end

        self.nCurSelectColorIndex = table.get_key(self.tDecalInfo.tColorID, nColorID)
        self:InitData()
        self:UpdateCurColorInfo()
        self:UpdateOldDetailAdjustInfo()
    end)
end

function UIBuildFaceDetailAdjustPart:InitData()
    local nType = self.tUIInfo.nDecalType or self.tUIInfo.nDecorationType
    if not nType then
        nType = self.tUIInfo.nType
    end
    local tDecal = self.tCurDecal[nType]
    self.nCurSelectColorIndex = table.get_key(self.tDecalInfo.tColorID, tDecal.nColorID)

    self.nCurSelectColorID = self.tDecalInfo.tColorID[self.nCurSelectColorIndex]
    local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType,
                                        nType,
                                        self.tUIInfo.nShowID,
                                        self.nCurSelectColorID,
                                        not self.bIsOldFace)
    self.tDetail = tDetail
end

function UIBuildFaceDetailAdjustPart:UpdateInfo()
    UIHelper.SetString(self.LabelDefault, UIHelper.GBKToUTF8(self.szClassName).."调整")

    self:InitData()
    self:UpdateColorInfo()
    self:UpdateCurColorInfo()

    if self.bIsOldFace then
        self:UpdateOldDetailAdjustInfo()
    else
        self:UpdateDetailAdjustInfo()
    end
end

function UIBuildFaceDetailAdjustPart:UpdateColorInfo()
    UIHelper.HideAllChildren(self.ScrollViewColorList)

    local nIconType = 2
    if self.bIsOldFace then
        nIconType = 8
    end
    self.tbColorCells = self.tbColorCells or {}
    for i, nColorID in ipairs(self.tDecalInfo.tColorID) do
        if not self.tbColorCells[i] then
            self.tbColorCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewColorList)
            UIHelper.ToggleGroupAddToggle(self.TogGroupColorCell, self.tbColorCells[i].ToggleSelect)
        end

        UIHelper.SetVisible(self.tbColorCells[i]._rootNode, true)
        local nType = self.tUIInfo.nDecalType or self.tUIInfo.nDecorationType
        if not nType then
            nType = self.tUIInfo.nType
        end
        self.tbColorCells[i]:OnEnter(nIconType, nColorID, nType, self.tUIInfo.nShowID)

        if nColorID == 0 then
            local tbColorValue = string.split(self.tUIInfo.szDefaultRGBA, ";")
            UIHelper.SetColor(self.tbColorCells[i].ImgColor, cc.c3b(tbColorValue[1], tbColorValue[2], tbColorValue[3]))
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewColorList)

    local nType = self.tUIInfo.nDecalType or self.tUIInfo.nDecorationType
    if not nType then
        nType = self.tUIInfo.nType
    end
    local tDecal = self.tCurDecal[nType]
    for i, nColorID in ipairs(self.tDecalInfo.tColorID) do
        if tDecal.nColorID == nColorID then
            UIHelper.SetToggleGroupSelected(self.TogGroupColorCell, i - 1)
            break
        end
    end
end

function UIBuildFaceDetailAdjustPart:UpdateCurColorInfo()
    local tDecal = self.tCurDecal[self.tUIInfo.nType]

    local c3bCurColor = cc.c3b(255, 255, 255)
    for i, nColorID in ipairs(self.tDecalInfo.tColorID) do

        if nColorID == 0 then
            local tbColorValue = string.split(self.tUIInfo.szDefaultRGBA, ";")
            if tDecal.nColorID == nColorID then
                c3bCurColor = cc.c3b(tbColorValue[1], tbColorValue[2], tbColorValue[3])
            end
        end

        if tDecal.nColorID == nColorID then
            if self.bIsOldFace then
	            local tUIInfo = Table_GetDecal(BuildFaceData.nRoleType, self.tUIInfo.nType, self.tUIInfo.nShowID)
                local nR = tUIInfo.tRGBA[1] or 255
                local nG = tUIInfo.tRGBA[2] or 255
                local nB = tUIInfo.tRGBA[3] or 255
                local nA = tUIInfo.tRGBA[4] or 255

                if nColorID ~= 0 then
                    local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType, self.tUIInfo.nType, self.tUIInfo.nShowID, nColorID)
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
                c3bCurColor = cc.c3b(nR, nG, nB)
            else
                local tAdjustInfo = Table_GetDecalsAdjustV2(self.tUIInfo.nType)
                if BuildFaceData.IsFit(nColorID, self.tUIInfo.nType) or tAdjustInfo.bValueXY then
                    local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType, self.tUIInfo.nType, self.tUIInfo.nShowID, nColorID, not self.bIsOldFace)
                    if nColorID ~= 0 and r and g and b and a then
                        r = r * 255
                        g = g * 255
                        b = b * 255
                        c3bCurColor = cc.c3b(r, g, b)
                    end
                end
            end

        end
    end

    UIHelper.SetColor(self.ImgColor_Now, c3bCurColor)
end

local tbXYAdjustName = {
    [1] = "X坐标",
    [2] = "Y坐标",
}
function UIBuildFaceDetailAdjustPart:UpdateDetailAdjustInfo()
    UIHelper.HideAllChildren(self.LayoutAdjustCell)
    local tAdjustInfo = Table_GetDecalsAdjustV2(self.tUIInfo.nType)
    local tDecal = self.tCurDecal[self.tUIInfo.nType]

    local nIndex = 1
    local bFixValue = false
    self.tbAdjustCell = self.tbAdjustCell or {}

    if self.tDetail then
        -- if self.nCurSelectColorID > 0 then
            for i = 1, 3 do
                local szStringMin = table.concat({"fValue", i, "Min"})
                local szStringMax = table.concat({"fValue", i, "Max"})
                local szStringNow = table.concat({"fValue", i})
                local nNowValue   = math.floor(tDecal[szStringNow] * 100 + 0.5)
                local nValueMin = self.tDetail[szStringMin] * 100
                local nValueMax = self.tDetail[szStringMax] * 100

                if tDecal.bChangeValue == false or nNowValue < nValueMin or nNowValue > nValueMax then
                    local szStringNewNow = table.concat({"fNewValue", i})
                    nNowValue   = math.floor(self.tDetail[szStringNewNow] * 100 + 0.5)

                    local szStringValue = table.concat({"fValue", i})
                    tDecal[szStringValue] = nNowValue / 100

                    bFixValue = true
                end

                local szString = table.concat({"bShowScroll", i})
                local bShow = tAdjustInfo[szString]
                local szName = tAdjustInfo[table.concat({"szName", i})]
                if i == 1 then
                    bShow = bShow and self.nCurSelectColorID ~= 0
                else
                    bShow = bShow and BuildFaceData.IsFit(self.nCurSelectColorID, self.tUIInfo.nType)
                end
                if bShow then
                    if not self.tbAdjustCell[nIndex] then
                        local nPrefabID = PREFAB_ID.WidgetAdjustCell
                        if BuildFaceData.bPrice then
                            nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                        end
                        self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.LayoutAdjustCell)
                    end

                    local tLine = Table_GetFaceDecalsAdjustExpandV2Info(BuildFaceData.nRoleType, self.tUIInfo.nType, self.tUIInfo.nShowID)
                    if tLine then
                        szName = tLine.szName or szName
                    end

                    UIHelper.SetVisible(self.tbAdjustCell[nIndex]._rootNode, true)
                    self.tbAdjustCell[nIndex]:OnEnter(2, {
                        nIndex = i,
                        szName = szName,
                        nValueMin = nValueMin,
                        nValueMax = nValueMax,
                    }, nNowValue)
                    nIndex = nIndex + 1
                end
            end
        -- end

        if tAdjustInfo.bValueXY then
            for i = 1, 2 do
                if not self.tbAdjustCell[nIndex] then
                    local nPrefabID = PREFAB_ID.WidgetAdjustCell
                    if BuildFaceData.bPrice then
                        nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                    end
                    self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.LayoutAdjustCell)
                end

                local szStringNow = table.concat({"fValue", i + 1})
                local nNowValue   = math.floor(tDecal[szStringNow] * 100 + 0.5)
                UIHelper.SetVisible(self.tbAdjustCell[nIndex]._rootNode, true)
                self.tbAdjustCell[nIndex]:OnEnter(2, {
                    nIndex = i + 1,
                    szName = UIHelper.UTF8ToGBK(tbXYAdjustName[i]),
                    nValueMin = 0,
                    nValueMax = 200,
                }, nNowValue)
                nIndex = nIndex + 1
            end
        end
    end

    if BuildFaceData.bPrice then
        UIHelper.ScrollViewDoLayoutAndToTop(self.LayoutAdjustCell)
    else
        UIHelper.LayoutDoLayout(self.LayoutAdjustCell)
    end

    if bFixValue then
        BuildFaceData.CopyRightType(self.tUIInfo.nType)
        Event.Dispatch(EventType.OnChangeBuildMakeupValue)
    end
end

function UIBuildFaceDetailAdjustPart:UpdateOldDetailAdjustInfo()
    UIHelper.HideAllChildren(self.LayoutAdjustCell)
    local tAdjustInfo = Table_GetDecalsAdjust(self.tUIInfo.nType)
    local tDecal = self.tCurDecal[self.tUIInfo.nType]

    local nIndex = 1
    local bFixValue = false
    self.tbAdjustCell = self.tbAdjustCell or {}

    if self.tDetail then
        if self.nCurSelectColorID > 0 then
            for i = 1, 3 do
                local szStringMin = table.concat({"fValue", i, "Min"})
                local szStringMax = table.concat({"fValue", i, "Max"})
                local szStringNow = table.concat({"fValue", i})
                local nNowValue   = math.floor(tDecal[szStringNow] * 100 + 0.5)
                local nValueMin = self.tDetail[szStringMin] * 100
                local nValueMax = self.tDetail[szStringMax] * 100

                if tDecal.bChangeValue == false or nNowValue < nValueMin or nNowValue > nValueMax then
                    local szStringNewNow = table.concat({"fValue", i})
                    if self.tUIInfo.nType == FACE_LIFT_DECAL_TYPE.BASE then
                        szStringNewNow = table.concat({"fBaseValue", i})
                    elseif self.tUIInfo.nType >= FACE_LIFT_DECAL_TYPE.LIP_FLASH then
                        szStringNewNow = table.concat({"fNewValue", i})
                    end
                    nNowValue   = math.floor(self.tDetail[szStringNewNow] * 100 + 0.5)

                    local szStringValue = table.concat({"fValue", i})
                    tDecal[szStringValue] = nNowValue / 100

                    bFixValue = true
                end

                local szString = table.concat({"bShowHDV", i})
                local bShow = tAdjustInfo[szString]
                local szName = tAdjustInfo[table.concat({"szName", i})]
                if bShow then
                    if not self.tbAdjustCell[nIndex] then
                        local nPrefabID = PREFAB_ID.WidgetAdjustCell
                        if BuildFaceData.bPrice then
                            nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                        end
                        self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.LayoutAdjustCell)
                    end

                    UIHelper.SetVisible(self.tbAdjustCell[nIndex]._rootNode, true)
                    self.tbAdjustCell[nIndex]:OnEnter(7, {
                        nIndex = i,
                        szName = szName,
                        nValueMin = nValueMin,
                        nValueMax = nValueMax,
                    }, nNowValue)
                    nIndex = nIndex + 1
                end
            end
        end

        if tAdjustInfo.bValueXY then
            for i = 1, 2 do
                if not self.tbAdjustCell[nIndex] then
                    local nPrefabID = PREFAB_ID.WidgetAdjustCell
                    if BuildFaceData.bPrice then
                        nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                    end
                    self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.LayoutAdjustCell)
                end

                local szStringNow = table.concat({"fValue", i + 1})
                local nNowValue   = math.floor(tDecal[szStringNow] * 100 + 0.5)
                UIHelper.SetVisible(self.tbAdjustCell[nIndex]._rootNode, true)
                self.tbAdjustCell[nIndex]:OnEnter(2, {
                    nIndex = i + 1,
                    szName = UIHelper.UTF8ToGBK(tbXYAdjustName[i]),
                    nValueMin = 0,
                    nValueMax = 200,
                }, nNowValue)
                nIndex = nIndex + 1
            end
        end
    end

    if BuildFaceData.bPrice then
        UIHelper.ScrollViewDoLayoutAndToTop(self.LayoutAdjustCell)
    else
        UIHelper.LayoutDoLayout(self.LayoutAdjustCell)
    end

    if bFixValue then
        BuildFaceData.CopyRightType(self.tUIInfo.nType)
        Event.Dispatch(EventType.OnChangeBuildMakeupValue)
    end
end

return UIBuildFaceDetailAdjustPart