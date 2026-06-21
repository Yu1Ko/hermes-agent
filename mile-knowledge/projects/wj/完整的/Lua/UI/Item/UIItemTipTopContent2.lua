-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipTopContent2
-- Date: 2023-02-21 09:33:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipTopContent2 = class("UIItemTipTopContent2")

function UIItemTipTopContent2:OnEnter(item, bItem, szBindSource)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(item, bItem, szBindSource)
end

function UIItemTipTopContent2:OnInitWithFurniture(nFurnitureType, dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateFurnitureInfo(nFurnitureType, dwFurnitureID)
end

function UIItemTipTopContent2:OnExit()
    self.bInit = false
end

function UIItemTipTopContent2:BindUIEvent()

end

function UIItemTipTopContent2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipTopContent2:UpdateInfo(item, bItem, szBindSource)
    local nFurnitureType, dwFurnitureID = FurnitureData.GetTypeAndIDWithItem(item, self.bItem)
    self:UpdateBindInfo(item, bItem, szBindSource)
    self:UpdateFurnitureInfo(nFurnitureType, dwFurnitureID)
end

function UIItemTipTopContent2:UpdateBindInfo(item, bItem, szBindSource)
    local szBind = ItemData.GetBindInfo(item, bItem, szBindSource)
    UIHelper.SetString(self.LabelType2, szBind)
end

function UIItemTipTopContent2:UpdateFurnitureInfo(nFurnitureType, dwFurnitureID)
    if not dwFurnitureID then
        LOG.ERROR("[UIItemTipTopContent2.:UpdateFurnitureInfo] error get dwFurnitureID failed!")
        return
    end

    local tFurnitureConfig = FurnitureData.GetFurnitureConfig(nFurnitureType, dwFurnitureID)
    local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
    local tCatg1UIInfo = FurnitureData.GetCatg1Info(tUIInfo.nCatg1Index)
	local tCatg2UIInfo = FurnitureData.GetCatg2Info(tUIInfo.nCatg1Index, tUIInfo.nCatg2Index)

    UIHelper.SetString(self.LabelType,
        string.format("%s-%s-%s",
            g_tStrings.STR_FURNITURE_TIP_NAME,
            UIHelper.GBKToUTF8(tCatg1UIInfo.szName),
            UIHelper.GBKToUTF8(tCatg2UIInfo.szName)))

    UIHelper.SetString(self.LabelLimit, FormatString(g_tStrings.STR_FURNITURE_TIP_ILLUSTRATE7, tFurnitureConfig.nMaxAmountPerLand or 1))

    if tUIInfo and tUIInfo.bInteract then
        UIHelper.SetVisible(self.LayoutIconCapability1, true)
    else
        UIHelper.SetVisible(self.LayoutIconCapability1, false)
    end

    if FurnitureData.FurnCanDye(tUIInfo.dwModelID) then
        UIHelper.SetVisible(self.LayoutIconCapability2, true)
    else
        UIHelper.SetVisible(self.LayoutIconCapability2, false)
    end

    UIHelper.LayoutDoLayout(self.WidgetIconLabel1)
    UIHelper.LayoutDoLayout(self.LayoutRow3)
    UIHelper.LayoutDoLayout(self.LayoutRow1)
end


return UIItemTipTopContent2