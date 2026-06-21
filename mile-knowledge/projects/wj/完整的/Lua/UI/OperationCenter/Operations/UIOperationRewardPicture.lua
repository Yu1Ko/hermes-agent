-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationRewardPicture
-- Date: 2026-04-16 10:10:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationRewardPicture = class("UIOperationRewardPicture")

function UIOperationRewardPicture:OnEnter(szMoblieImagePath, dwWeaponIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwWeaponIndex = dwWeaponIndex
    self:UpdateInfo(szMoblieImagePath)
end

function UIOperationRewardPicture:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationRewardPicture:BindUIEvent()
    UIHelper.BindUIEvent(self.Btn_ShowTip, EventType.OnClick, function()
        TipsHelper.ShowItemTips(nil, ITEM_TABLE_TYPE.CUST_WEAPON, self.dwWeaponIndex)
    end)
end

function UIOperationRewardPicture:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationRewardPicture:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationRewardPicture:UpdateInfo(szMoblieImagePath)
    UIHelper.SetTexture(self.ImgPage_1, szMoblieImagePath, true)
end


return UIOperationRewardPicture