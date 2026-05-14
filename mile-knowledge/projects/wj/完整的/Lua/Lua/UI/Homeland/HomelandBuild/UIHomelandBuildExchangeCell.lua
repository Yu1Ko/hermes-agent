-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildExchangeCell
-- Date: 2024-02-04 15:53:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildExchangeCell = class("UIHomelandBuildExchangeCell")

function UIHomelandBuildExchangeCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomelandBuildExchangeCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildExchangeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectedHomelandBuildExchangeListCell, self.tbInfo)
    end)

end

function UIHomelandBuildExchangeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildExchangeCell:UpdateInfo()
    local tInfo = self.tbInfo
    local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(tInfo.nType, tInfo.dwFurnitureID)
    local tAddInfo = Table_GetFurnitureAddInfo(dwFurnitureUiId)
    if tAddInfo then
        UIHelper.SetTexture(self.ImgItemIcon, UIHelper.FixDXUIImagePath(tAddInfo.szPath))
    end
    local tUiInfo = FurnitureData.GetFurnInfoByTypeAndID(tInfo.nType, tInfo.dwFurnitureID)
    UIHelper.SetTextColor(self.LabelJiMuName, ItemQualityColorC4b[(self.tbInfo.nQuality or 1) + 1])
    UIHelper.SetString(self.LabelJiMuName, UIHelper.GBKToUTF8(tUiInfo.szName), 8)

    local nRealCount = tInfo.nCount
    if tInfo.bInEditMode then
        UIHelper.SetString(self.LabelJiMuNum, math.max(0, nRealCount))
        UIHelper.SetVisible(self.WidgetNum, true)
    else
        UIHelper.SetVisible(self.WidgetNum, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)

    local bEnabled = self.tbInfo.nIndex > 0 and nRealCount > 0
    UIHelper.SetTouchEnabled(self.TogCell, bEnabled)
    UIHelper.SetVisible(self.ImgMask, not bEnabled)
end


return UIHomelandBuildExchangeCell