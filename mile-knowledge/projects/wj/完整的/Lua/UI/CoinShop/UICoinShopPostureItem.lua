-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPostureItem
-- Date: 2024-09-09 11:15:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopPostureItem = class("UICoinShopPostureItem")

function UICoinShopPostureItem:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = tInfo.dwID
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UICoinShopPostureItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopPostureItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogShoppingStandby, EventType.OnClick, function()
        local bPreview = ExteriorCharacter.GetPreviewAniID() == self.dwID
        if bPreview then
            FireUIEvent("PREVIEW_IDLE_ACTION", 0)
        else
            FireUIEvent("PREVIEW_IDLE_ACTION", self.dwID, self.tInfo.dwRepresentID, false)
        end
        if RedpointHelper.IdleAction_IsNew(self.dwID) then
            RedpointHelper.IdleAction_SetNew(self.dwID, false)
        end
        UIHelper.SetVisible(self.ImgNew, false)
        UIHelper.LayoutDoLayout(self.LayoutIcon)
    end)
end

function UICoinShopPostureItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopPostureItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopPostureItem:UpdateItemState()
    self:UpdateInfo()
end

function UICoinShopPostureItem:UpdateInfo()
    local dwID = self.dwID
    local tInfo = self.tInfo
    local tConf = Table_GetIdleAction(dwID)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local bEquipped = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP) == dwID
    local bPreview = ExteriorCharacter.GetPreviewAniID() == dwID

    UIHelper.SetString(self.LabelName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tConf.szActionName), 6))
    UIHelper.SetVisible(self.ImgEquipped, bEquipped)
    UIHelper.SetSelected(self.TogShoppingStandby, bPreview, false)
    UIHelper.SetVisible(self.ImgNew, RedpointHelper.IdleAction_IsNew(dwID))

    local szPath = CharacterIdleActionData.GetPreviewImgByID(self.tInfo.dwID, hPlayer.nRoleType)
    UIHelper.SetTexture(self.ImgCard, szPath)

    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

return UICoinShopPostureItem