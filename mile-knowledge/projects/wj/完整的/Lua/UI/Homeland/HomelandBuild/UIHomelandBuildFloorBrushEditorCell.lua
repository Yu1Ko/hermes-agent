-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFloorBrushEditorCell
-- Date: 2024-01-19 11:42:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFloorBrushEditorCell = class("UIHomelandBuildFloorBrushEditorCell")

local tbIndex2Title = {
    [1] = "底层",
    [2] = "第二层",
    [3] = "第三层",
}

function UIHomelandBuildFloorBrushEditorCell:OnEnter(nIndex, dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.dwFurnitureID = dwFurnitureID
    self:UpdateInfo()
end

function UIHomelandBuildFloorBrushEditorCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildFloorBrushEditorCell:BindUIEvent()

end

function UIHomelandBuildFloorBrushEditorCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFloorBrushEditorCell:UpdateInfo()
    if self.dwFurnitureID and self.dwFurnitureID > 0 then
        UIHelper.SetVisible(self.WidgetItem, true)
        UIHelper.SetVisible(self.ImgAdd, false)

        local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, self.dwFurnitureID)
        local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
        if tAddInfo then
            local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
            szPath = string.gsub(szPath, ".tga", ".png")

            if not self.scriptItemIcon then
                self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
                self.scriptItemIcon:RegEvent()
                self.scriptItemIcon:BindUIEvent()
                self.scriptItemIcon.bInit = true
                self.scriptItemIcon:SetSelectEnable(false)
                self.scriptItemIcon:SetLabelCountVisible(false)
            end

            self.scriptItemIcon:SetIconByTexture(szPath)

            local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.APPLIQUE_BRUSH, self.dwFurnitureID)
            if tUIInfo then
                self.scriptItemIcon:SetItemQualityBg((tUIInfo.nQuality or 1))
            else
                self.scriptItemIcon:SetItemQualityBg(1)
            end
            -- UIHelper.SetVisible(self.scriptItemIcon.ImgPolishCountBG, false)
        end
    else
        UIHelper.SetVisible(self.ImgAdd, true)
        UIHelper.SetVisible(self.WidgetItem, false)
    end

    UIHelper.SetString(self.LabelLayer, tbIndex2Title[self.nIndex])
end

function UIHomelandBuildFloorBrushEditorCell:SetRecallCallback(funcCallback)
    if not self.scriptItemIcon then
        return
    end
    self.scriptItemIcon:SetRecallVisible(true)
    self.scriptItemIcon:SetRecallCallback(funcCallback)
end


return UIHomelandBuildFloorBrushEditorCell