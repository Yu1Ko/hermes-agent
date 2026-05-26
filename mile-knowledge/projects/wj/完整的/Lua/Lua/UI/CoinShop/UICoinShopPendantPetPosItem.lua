-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPendantPetPosItem
-- Date: 2023-04-04 20:28:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

--TogImgPetPlace
--ImgPetPlaceIcon

local UICoinShopPendantPetPosItem = class("UICoinShopPendantPetPosItem")

function UICoinShopPendantPetPosItem:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self:UpdateInfo()
end

function UICoinShopPendantPetPosItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopPendantPetPosItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogImgPetPlace, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            FireUIEvent("PREVIEW_PENDANT_PET_POS", self.tInfo.nPos)
        end
    end)
end

function UICoinShopPendantPetPosItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopPendantPetPosItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopPendantPetPosItem:UpdateInfo()
    UIHelper.SetSpriteFrame(self.ImgPetPlaceIcon, self.tInfo.szMobileIconPath)
    local szName = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(self.tInfo.szName), 1, 2)
    UIHelper.SetString(self.LabelPlace, szName)
end

return UICoinShopPendantPetPosItem