-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceDetailAdjustView
-- Date: 2023-10-08 16:00:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceDetailAdjustView = class("UIBuildFaceDetailAdjustView")

function UIBuildFaceDetailAdjustView:OnEnter(szClassName, tDecalInfo, tUIInfo, tCacheSetting)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szClassName = szClassName
    self.tDecalInfo = tDecalInfo
    self.tUIInfo = tUIInfo
    self.tCacheSetting = tCacheSetting

    self.nCurSelectColorIndex = 1

    self:UpdateInfo()

    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    --scriptDownload:OnInitBasic()
    if scriptDownload then
        scriptDownload:OnInitTotal()
    end
end

function UIBuildFaceDetailAdjustView:OnExit()
    self.bInit = false
end

function UIBuildFaceDetailAdjustView:BindUIEvent()
    local function Close()
        UIMgr.Close(self)
        UIMgr.ShowView(VIEW_ID.PanelBuildFace_Step2)
    end
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]
        if BuildFaceData.IsEqualPartFace(self.tCacheSetting, tDecal) then
            Close()
        else
            UIHelper.ShowConfirm("是否放弃当前细节调整修改并返回？", function ()
                BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType] = self.tCacheSetting
                BuildFaceData.CopyRightType(self.tUIInfo.nType)
                Event.Dispatch(EventType.OnChangeBuildMakeupValue)
                Close()
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevertAll, EventType.OnClick, function ()

    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function ()
        Close()
    end)
end

function UIBuildFaceDetailAdjustView:RegEvent()
    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValue, function (tbInfo, nValue)
        local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]

        local szStringValue = table.concat({"fValue", tbInfo.nIndex})
        tDecal[szStringValue] = nValue / 100

        BuildFaceData.CopyRightType(self.tUIInfo.nType)

        Event.Dispatch(EventType.OnChangeBuildMakeupValue)
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupColor, function (nType, nShowID, nColorID)
        if self.tUIInfo.nType ~= nType or self.tUIInfo.nShowID ~= nShowID then
            return
        end

        self.nCurSelectColorIndex = table.get_key(self.tDecalInfo.tColorID, nColorID)
        self:InitData()
        self:UpdateDetailAdjustInfo()
    end)
end

function UIBuildFaceDetailAdjustView:InitData()
    local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]
    self.nCurSelectColorIndex = table.get_key(self.tDecalInfo.tColorID, tDecal.nColorID)

    self.nCurSelectColorID = self.tDecalInfo.tColorID[self.nCurSelectColorIndex]
    local r, g, b, a, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType,
                                        self.tUIInfo.nType,
                                        self.tUIInfo.nShowID,
                                        self.nCurSelectColorID,
                                        true)
    self.tDetail = tDetail
end

function UIBuildFaceDetailAdjustView:UpdateInfo()
    UIHelper.SetString(self.LabelDefault, UIHelper.GBKToUTF8(self.szClassName).."调整")

    self:InitData()
    self:UpdateColorInfo()
    self:UpdateDetailAdjustInfo()
end

function UIBuildFaceDetailAdjustView:UpdateColorInfo()
    UIHelper.HideAllChildren(self.ScrollViewColorList)

    self.tbColorCells = self.tbColorCells or {}
    for i, nColorID in ipairs(self.tDecalInfo.tColorID) do
        if not self.tbColorCells[i] then
            self.tbColorCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewColorList)
        end

        UIHelper.SetVisible(self.tbColorCells[i]._rootNode, true)
        self.tbColorCells[i]:OnEnter(2, nColorID, self.tUIInfo.nType, self.tUIInfo.nShowID)

        if nColorID == 0 then
            local tbColorValue = string.split(self.tUIInfo.szDefaultRGBA, ";")
            UIHelper.SetColor(self.tbColorCells[i].ImgColor, cc.c3b(tbColorValue[1], tbColorValue[2], tbColorValue[3]))
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewColorList)
end

local tbXYAdjustName = {
    [1] = "X坐标",
    [2] = "Y坐标",
}
function UIBuildFaceDetailAdjustView:UpdateDetailAdjustInfo()
    UIHelper.HideAllChildren(self.ScrollViewAdjust)
    local tAdjustInfo = Table_GetDecalsAdjustV2(self.tUIInfo.nType)
    local tDecal = BuildFaceData.tNowFaceData.tDecal[self.tUIInfo.nType]

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
                    local szStringNewNow = table.concat({"fNewValue", i})
                    nNowValue   = math.floor(self.tDetail[szStringNewNow] * 100 + 0.5)

                    local szStringValue = table.concat({"fValue", i})
                    tDecal[szStringValue] = nNowValue / 100

                    bFixValue = true
                end

                local szString = table.concat({"bShowScroll", i})
                local bShow = tAdjustInfo[szString]
                local szName = tAdjustInfo[table.concat({"szName", i})]
                if bShow then
                    if not self.tbAdjustCell[nIndex] then
                        local nPrefabID = PREFAB_ID.WidgetAdjustCell
                        if BuildFaceData.bPrice then
                            nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                        end
                        self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewAdjust)
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
        end

        if tAdjustInfo.bValueXY then
            for i = 1, 2 do
                if not self.tbAdjustCell[nIndex] then
                    local nPrefabID = PREFAB_ID.WidgetAdjustCell
                    if BuildFaceData.bPrice then
                        nPrefabID = PREFAB_ID.WidgetCoinAdjustCell
                    end
                    self.tbAdjustCell[nIndex] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewAdjust)
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

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)

    if bFixValue then
        BuildFaceData.CopyRightType(self.tUIInfo.nType)
        Event.Dispatch(EventType.OnChangeBuildMakeupValue)
    end
end

return UIBuildFaceDetailAdjustView