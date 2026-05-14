-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandFlowerPriceLandCell
-- Date: 2024-07-02 11:11:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandFlowerPriceLandCell = class("UIHomelandFlowerPriceLandCell")

function UIHomelandFlowerPriceLandCell:OnEnter(tbArg)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tbArg.bMerchant then
        self.tbInfo = tbArg
        self:UpdateMerchantInfo()
        return
    end

    self.tbInfo = tbArg.tbInfo
    self:UpdateInfo()
end

function UIHomelandFlowerPriceLandCell:OnExit()
    self.bInit = false
end

function UIHomelandFlowerPriceLandCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFlowerCommunity, EventType.OnClick, function(btn)
        self:OnTransmit()
    end)
    UIHelper.SetSwallowTouches(self.BtnFlowerCommunity, false)
end

function UIHomelandFlowerPriceLandCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandFlowerPriceLandCell:UpdateMerchantInfo()
    local szCenterName = GetCenterNameByCenterID(GetCenterID())
    UIHelper.SetString(self.LabelFuWuQi, UIHelper.GBKToUTF8(szCenterName))

    local szMapName = ""
    if self.tbInfo.nIndex > 0 then
        local szName = Homeland_GetHomeName(self.tbInfo.nMapID, self.tbInfo.nLandIndex)
        szName = UIHelper.GBKToUTF8(szName)
        szName = FormatString(g_tStrings.STR_LINK_LAND, szName, self.tbInfo.nIndex)
        szMapName = szName
    else
        szMapName = g_tStrings.STR_BLUEPRINT_PANEL_PRIVATEHOUSE
    end
    UIHelper.SetString(self.LabelLine, szMapName)
end

function UIHomelandFlowerPriceLandCell:UpdateInfo()
    local szCenterName = GetCenterNameByCenterID(self.tbInfo.nCenterID)
    UIHelper.SetString(self.LabelFuWuQi, UIHelper.GBKToUTF8(szCenterName))

    local szMapName = Table_GetMapName(self.tbInfo.nMapID)
    szMapName = string.format("%s-%d线", UIHelper.GBKToUTF8(szMapName), self.tbInfo.nLineID)
    UIHelper.SetString(self.LabelLine, szMapName)
end

function UIHomelandFlowerPriceLandCell:GetMapName()
    local szMapName = ""
    if self.tbInfo.bMerchant then
        if self.tbInfo.nIndex > 0 then
            local szName = Homeland_GetHomeName(self.tbInfo.nMapID, self.tbInfo.nLandIndex)
            szName = UIHelper.GBKToUTF8(szName)
            szName = FormatString(g_tStrings.STR_LINK_LAND, szName, self.tbInfo.nIndex)
            szMapName = szName
        else
            szMapName = g_tStrings.STR_BLUEPRINT_PANEL_PRIVATEHOUSE
        end
    else
        szMapName = Table_GetMapName(self.tbInfo.nMapID)
        szMapName = string.format("%s-%d线", UIHelper.GBKToUTF8(szMapName), self.tbInfo.nLineID)
    end
    return szMapName
end

function UIHomelandFlowerPriceLandCell:OnTransmit()
    local function fnTrans()
        if self.tbInfo.bMerchant then
            if self.tbInfo.nIndex > 0 then
                HomelandData.BackCommunityHome(self.tbInfo.nMapID, self.tbInfo.nCopyIndex, self.tbInfo.nLandIndex)
            else
                HomelandData.GoPrivateLand(self.tbInfo.nMapID, self.tbInfo.nCopyIndex, 0, 3)
            end
            UIMgr.Close(VIEW_ID.PanelMerchant)
        else
            HomelandFlowerPriceData.GoToSellFlower(self.tbInfo.nMapID, self.tbInfo.nCopyIndex, self.tbInfo.nTogType)
            UIMgr.Close(VIEW_ID.PanelFlowerPrice)
        end
        UIMgr.Close(VIEW_ID.PanelHomeOverview)
    end

    local szMapName = self:GetMapName()
    local szTitle = string.format(g_tStrings.STR_HOMELAND_TRANSMIT_CONFIRM, szMapName)
    UIHelper.ShowConfirm(szTitle, fnTrans)
end

return UIHomelandFlowerPriceLandCell