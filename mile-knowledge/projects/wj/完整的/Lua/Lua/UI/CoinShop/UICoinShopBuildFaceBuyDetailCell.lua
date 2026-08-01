-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBuildFaceBuyDetailCell
-- Date: 2023-11-10 10:23:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBuildFaceBuyDetailCell = class("UICoinShopBuildFaceBuyDetailCell")

function UICoinShopBuildFaceBuyDetailCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICoinShopBuildFaceBuyDetailCell:OnExit()
    self.bInit = false
end

function UICoinShopBuildFaceBuyDetailCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRemove, EventType.OnClick, function(btn)
        if self.tbInfo and self.tbInfo.funcDel then
            self.tbInfo.funcDel()
        end
    end)

end

function UICoinShopBuildFaceBuyDetailCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopBuildFaceBuyDetailCell:UpdateInfo()
    UIHelper.SetString(self.LabelTittle, self.tbInfo.szName)
    UIHelper.SetVisible(self.BtnRemove, self.tbInfo.bShowRemoveBtn)
    UIHelper.SetVisible(self.LayoutPrice, not self.tbInfo.bUseFreeTimes and self.tbInfo.bShowCost)
    UIHelper.SetVisible(self.LayoutFree, self.tbInfo.bUseFreeTimes)
    UIHelper.SetVisible(self.ImgDiscount, self.tbInfo.bDis)

    UIHelper.SetString(self.LabelMoney, self.tbInfo.nPrice or 0)
    UIHelper.SetString(self.LabelFreeTimes, self.tbInfo.szFreeTimes)
    UIHelper.SetString(self.LabelDiscount, self.tbInfo.szDisCount)
end


return UICoinShopBuildFaceBuyDetailCell