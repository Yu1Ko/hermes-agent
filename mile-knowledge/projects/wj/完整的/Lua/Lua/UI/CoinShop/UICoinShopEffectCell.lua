-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopEffectCell
-- Date: 2026-01-30 16:22:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopEffectCell = class("UICoinShopEffectCell")

function UICoinShopEffectCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICoinShopEffectCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopEffectCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSpecialEffect, EventType.OnClick, function ()
        -- if self.funcClickCallback then
        --     self.funcClickCallback(self.tbInfo)
        -- end
        -- FireUIEvent("PREVIEW_PENDANT_EFFECT_SFX", tbInfo.nType, tbInfo.dwEffectID)
        local bPreview = ExteriorCharacter.IsPreviewEffect(self.tbInfo.nType, self.tbInfo.dwEffectID)
        if bPreview then
            FireUIEvent("RESET_ONE_EFFECT_SFX", self.tbInfo.nType)
        else
            FireUIEvent("PREVIEW_PENDANT_EFFECT_SFX", self.tbInfo.nType, self.tbInfo.dwEffectID)
        end
    end)
end

function UICoinShopEffectCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopEffectCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopEffectCell:UpdateInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local szPath = self.tbInfo.szImgPath
    szPath = string.gsub(szPath, "ui/Image/item_pic/", "mui/Resource/item_pic/")
    szPath = string.gsub(szPath, ".tga", ".png")

    UIHelper.SetTexture(self.ImgCard, szPath)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.tbInfo.szName))

    if CharacterEffectData.IsEffectUsing(self.tbInfo.dwEffectID, PlayerData.GetClientPlayer()) then
        UIHelper.SetVisible(self.ImgEquipped, true)
    else
        UIHelper.SetVisible(self.ImgEquipped, false)
    end

    local bPreview = ExteriorCharacter.IsPreviewEffect(self.tbInfo.nType, self.tbInfo.dwEffectID)
    UIHelper.SetSelected(self.TogSpecialEffect, bPreview, false)
end

function UICoinShopEffectCell:SetClickCallback(funcClickCallback)
    self.funcClickCallback = funcClickCallback
end

function UICoinShopEffectCell:UpdateItemState()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if CharacterEffectData.IsEffectUsing(self.tbInfo.dwEffectID, PlayerData.GetClientPlayer()) then
        UIHelper.SetVisible(self.ImgEquipped, true)
    else
        UIHelper.SetVisible(self.ImgEquipped, false)
    end

    local bPreview = ExteriorCharacter.IsPreviewEffect(self.tbInfo.nType, self.tbInfo.dwEffectID)
    UIHelper.SetSelected(self.TogSpecialEffect, bPreview, false)
end

return UICoinShopEffectCell