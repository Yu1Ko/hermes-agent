-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopRewardsDetailPic
-- Date: 2023-08-25 11:02:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopRewardsDetailPic = class("UICoinShopRewardsDetailPic")

function UICoinShopRewardsDetailPic:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICoinShopRewardsDetailPic:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopRewardsDetailPic:BindUIEvent()

end

function UICoinShopRewardsDetailPic:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopRewardsDetailPic:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopRewardsDetailPic:UpdateInfo()
    UIHelper.SetTouchEnabled(self.BtnSpecialItemPic, false)
end

return UICoinShopRewardsDetailPic