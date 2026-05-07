-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMapInfoCell
-- Date: 2023-04-11 10:33:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMapInfoCell = class("UIHomelandMapInfoCell")

function UIHomelandMapInfoCell:OnEnter(nIndex, tbInfo)
    self.nIndex = nIndex
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMapInfoCell:OnExit()
    self.bInit = false
end

function UIHomelandMapInfoCell:BindUIEvent()

end

function UIHomelandMapInfoCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMapInfoCell:UpdateInfo()
    UIHelper.SetString(self.LabelHome, tostring(self.nIndex))
    UIHelper.SetString(self.LabelFigure, tostring(self.tbInfo.nAllyCount))

    UIHelper.SetVisible(self.ImgHomeSell, self.tbInfo.bIsSelling)
    UIHelper.SetVisible(self.ImgHomePreSell, self.tbInfo.bPrepareToSale)

    UIHelper.SetVisible(self.LayoutIcon, not self.tbInfo.bIsSelling and not self.tbInfo.bPrepareToSale)
    UIHelper.SetVisible(self.ImgHomeModel, not self.tbInfo.bIsSelling and not self.tbInfo.bPrepareToSale)
    UIHelper.SetVisible(self.Eff_UIbutterfly, self.tbInfo.bMyLandFlag)
    UIHelper.SetVisible(self.WidgetFigure, self.tbInfo.nAllyCount > 0)

    local bDigital = Homeland_IsDigitalBlueprint(self.tbInfo["eMarketType1"] or 0)
    UIHelper.SetVisible(self.ImgCangPin, bDigital)

    local nLevel = self.tbInfo.nLevel
    nLevel = math.min(3, math.max(1, nLevel))
    if not self.tbInfo.bIsOpen then
        nLevel = nLevel + 8
    elseif self.tbInfo.bMyLandFlag then
        nLevel = nLevel * 2 - 1
    else
        nLevel = nLevel * 2
    end
    UIHelper.SetSpriteFrame(self.ImgHomeModel, HomelandHouseImg[nLevel])
end


return UIHomelandMapInfoCell