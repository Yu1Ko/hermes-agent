-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildZoneListCell
-- Date: 2023-05-15 11:02:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildZoneListCell = class("UIHomelandBuildZoneListCell")

function UIHomelandBuildZoneListCell:OnEnter(nIndex, tbConfig, bUnlock, bDemolish, bGrass, onClickCallback)
    self.nIndex = nIndex
    self.tbConfig = tbConfig
    self.bUnlock = bUnlock
    self.bDemolish = bDemolish
    self.bGrass = bGrass
    self.onClickCallback = onClickCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildZoneListCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildZoneListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogZoneListCell, EventType.OnClick, function ()
        if self.onClickCallback then
            self.onClickCallback()
        end
    end)
end

function UIHomelandBuildZoneListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildZoneListCell:UpdateInfo()
    UIHelper.SetString(self.LabelZoneNum, UIHelper.GBKToUTF8(self.tbConfig.szAreaName))

    UIHelper.SetVisible(self.LayoutStatus, not self.bUnlock)
    UIHelper.SetVisible(self.LayoutLine1, self.bUnlock)
    UIHelper.SetVisible(self.LayoutLine2, self.bUnlock)

    UIHelper.SetVisible(self.LabelPlainedNot, not self.bDemolish)
    UIHelper.SetVisible(self.LabelPlained, self.bDemolish)
    UIHelper.SetVisible(self.ImgSwitch1, self.bNewDemolish ~= nil and self.bDemolish ~= self.bNewDemolish)
    UIHelper.SetVisible(self.WidgetRight1, self.bNewDemolish ~= nil and self.bDemolish ~= self.bNewDemolish)
    UIHelper.SetVisible(self.LabelPlain, self.bNewDemolish ~= nil and self.bNewDemolish)
    UIHelper.SetVisible(self.LabelPlainReverse, self.bNewDemolish ~= nil and not self.bNewDemolish)

    UIHelper.SetVisible(self.LabelWeededOutNot, not self.bGrass)
    UIHelper.SetVisible(self.LabelWeededOut, self.bGrass)
    UIHelper.SetVisible(self.ImgSwitch2, self.bNewGrass ~= nil and self.bGrass ~= self.bNewGrass)
    UIHelper.SetVisible(self.WidgetRight2, self.bNewGrass ~= nil and self.bGrass ~= self.bNewGrass)
    UIHelper.SetVisible(self.LabelWeedOut, self.bNewGrass ~= nil and self.bNewGrass)
    UIHelper.SetVisible(self.LabelWeedReverse, self.bNewGrass ~= nil and not self.bNewGrass)

    UIHelper.SetVisible(self.ImgEditing, self.bUnlock and self.bDemolish)

    UIHelper.LayoutDoLayout(self.LayoutLine1)
    UIHelper.LayoutDoLayout(self.LayoutLine2)
    UIHelper.LayoutDoLayout(self.LayoutStatus)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIHomelandBuildZoneListCell:SetChange(bNewDemolish, bNewGrass)
    self.bNewDemolish = bNewDemolish
    self.bNewGrass = bNewGrass

    self:UpdateInfo()
end

return UIHomelandBuildZoneListCell