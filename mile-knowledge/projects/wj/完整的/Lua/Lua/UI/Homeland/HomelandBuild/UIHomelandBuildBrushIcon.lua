-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBrushIcon
-- Date: 2024-01-22 10:15:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBrushIcon = class("UIHomelandBuildBrushIcon")

function UIHomelandBuildBrushIcon:OnEnter(dwFurnitureID, fPerc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwFurnitureID = dwFurnitureID
    self.fPerc = fPerc
    self:UpdateInfo()
end

function UIHomelandBuildBrushIcon:OnExit()
    self.bInit = false
end

function UIHomelandBuildBrushIcon:BindUIEvent()

end

function UIHomelandBuildBrushIcon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBrushIcon:UpdateInfo()
    if self.dwFurnitureID and self.dwFurnitureID > 0 then
        UIHelper.SetVisible(self.WidgetItem, true)
        UIHelper.SetVisible(self.ImgAdd, false)

        local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, self.dwFurnitureID)
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

            local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FOLIAGE_BRUSH, self.dwFurnitureID)
            if tUIInfo then
                self.scriptItemIcon:SetItemQualityBg((tUIInfo.nQuality or 1))
            else
                self.scriptItemIcon:SetItemQualityBg(1)
            end
            -- UIHelper.SetVisible(self.scriptItemIcon.ImgPolishCountBG, false)
        end

        if self.fPerc then
            UIHelper.SetVisible(self.LabelRatio, true)
            UIHelper.SetVisible(self.ImgBgRatio, true)
            UIHelper.SetString(self.LabelRatio, string.format("%.1f%%", self.fPerc))
        else
            UIHelper.SetVisible(self.LabelRatio, false)
            UIHelper.SetVisible(self.ImgBgRatio, false)
        end
    else
        UIHelper.SetVisible(self.ImgAdd, true)
        UIHelper.SetVisible(self.WidgetItem, false)
        UIHelper.SetVisible(self.LabelRatio, false)
        UIHelper.SetVisible(self.ImgBgRatio, false)
    end
end

function UIHomelandBuildBrushIcon:SetRecallCallback(funcCallback)
    if not self.scriptItemIcon then
        return
    end
    self.scriptItemIcon:SetRecallVisible(true)
    self.scriptItemIcon:SetRecallCallback(funcCallback)
end

return UIHomelandBuildBrushIcon