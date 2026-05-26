-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantEffectCell
-- Date: 2023-03-01 10:18:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantEffectCell = class("UICharacterPendantEffectCell")

function UICharacterPendantEffectCell:OnEnter(tbInfo, nCurSelectedIndex)
    self.tbInfo = tbInfo
    self.nCurSelectedIndex = nCurSelectedIndex
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterPendantEffectCell:InitWithIdleAction(tbInfo)
    self.tbInfo = tbInfo
    if not self.bInit then
        Event.Reg(self, EventType.ON_UPDATE_IDLEACTION_NEW, function()
            self:UpdateIdleActionInfo()
        end)
        self:BindUIEvent()
        self.bInit = true
    end


    self:UpdateIdleActionInfo()
end

function UICharacterPendantEffectCell:InitWithSkillSkin(tbInfo)
    self.tbInfo = tbInfo
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateSkillSkinInfo()
end

function UICharacterPendantEffectCell:OnExit()
    self.bInit = false
end

function UICharacterPendantEffectCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAccessoryEffect, EventType.OnClick, function()
        if self.funcClickCallback then
            self.funcClickCallback(self)
        end
    end)

    UIHelper.SetLongPressDelay(self.TogAccessoryEffect, 0.5)
    UIHelper.BindUIEvent(self.TogAccessoryEffect, EventType.OnLongPress, function()
        if self.funcLongPressCallback then
            self.funcLongPressCallback()
        end
    end)
end

function UICharacterPendantEffectCell:RegEvent()
    Event.Reg(self, EventType.OnCharacterPendantSelected, function()
        self:UpdateNew()
    end)
end

function UICharacterPendantEffectCell:UpdateInfo()
    UIHelper.SetVisible(self.TogAccessoryEffect, true)
    UIHelper.SetVisible(self.BtnFastTakeOff, false)

    local szPath = self.tbInfo.szImgPath
    szPath = string.gsub(szPath, "ui/Image/item_pic/", "mui/Resource/item_pic/")
    szPath = string.gsub(szPath, ".tga", ".png")

    UIHelper.SetTexture(self.ImgEffect, szPath)
    UIHelper.SetVisible(self.ImgCollectIcon, CharacterEffectData.IsPreferEffect(self.tbInfo.dwEffectID))

    UIHelper.SetString(self.LabelEffectName, UIHelper.GBKToUTF8(self.tbInfo.szName))

    if not CharacterEffectData.IsEffectAcquired(self.tbInfo.dwEffectID) then
        UIHelper.SetOpacity(self.ImgEffect, 128)
    else
        UIHelper.SetOpacity(self.ImgEffect, 255)
    end

    if CharacterEffectData.IsEffectUsing(self.tbInfo.dwEffectID, PlayerData.GetClientPlayer()) then
        UIHelper.SetVisible(self.ImgEquipped, true)
        UIHelper.SetVisible(self.Eff_Rectangle, true)
    else
        UIHelper.SetVisible(self.ImgEquipped, false)
        UIHelper.SetVisible(self.Eff_Rectangle, false)
    end

    -- 新
    self:UpdateNew()

    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UICharacterPendantEffectCell:UpdateIdleActionInfo()
    UIHelper.SetVisible(self.TogAccessoryEffect, true)
    UIHelper.SetVisible(self.BtnFastTakeOff, false)
    UIHelper.SetVisible(self.ImgCollectIcon, false)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local szPath = CharacterIdleActionData.GetPreviewImgByID(self.tbInfo.dwID, player.nRoleType)
    UIHelper.SetTexture(self.ImgEffect_standby, szPath)
    UIHelper.SetString(self.LabelEffectName, UIHelper.GBKToUTF8(self.tbInfo.szActionName))
    UIHelper.SetVisible(self.ImgCollectIcon, self.tbInfo.bCollect)

    if not self.tbInfo.bHave then
        UIHelper.SetOpacity(self.ImgEffect_standby, 128)
    else
        UIHelper.SetOpacity(self.ImgEffect_standby, 255)
    end

    local dwIdleActionID = player.GetDisplayIdleAction(CharacterIdleActionData.GetCurSelectedType())
    if dwIdleActionID == self.tbInfo.dwID then
        UIHelper.SetVisible(self.ImgEquipped, true)
    else
        UIHelper.SetVisible(self.ImgEquipped, false)
    end

    local bNew = RedpointHelper.IdleAction_IsNew(self.tbInfo.dwID)
    UIHelper.SetVisible(self.ImgNew, bNew)
    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UICharacterPendantEffectCell:UpdateSkillSkinInfo()
    UIHelper.SetVisible(self.TogAccessoryEffect, true)
    UIHelper.SetVisible(self.BtnFastTakeOff, false)
    UIHelper.SetVisible(self.ImgCollectIcon, false)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nSkillID = self.tbInfo.nSkillID
    if nSkillID == 9002 then
        nSkillID = 100004 -- 扶摇特判处理
    end
    if self.tbInfo.bConfSkin then
        local dwGroupID = CharacterSkillSkinData.GetGroupID(nSkillID)
        local szImgPath = SKILL_SKIN_CONFIG_IMG[nSkillID]
        local nActivitySkinID = player.GetActiveSkillSkinByGroupID(dwGroupID)

        UIHelper.SetVisible(self.ImgNew, false)
        UIHelper.SetOpacity(self.ImgEffect, 255)
        UIHelper.SetString(self.LabelEffectName, "默认")
        UIHelper.SetVisible(self.ImgEquipped, not nActivitySkinID or nActivitySkinID <= 0)
        UIHelper.SetTexture(self.ImgEffect, szImgPath)
        UIHelper.LayoutDoLayout(self.LayoutIcon)
        return
    end

    local tbSkinInfo = CharacterSkillSkinData.GetSkinInfo(self.tbInfo.nSkinID)
    if not tbSkinInfo then
        return
    end

    local tbUISkinInfo = TabHelper.GetUISkillSkinInfo(nSkillID, self.tbInfo.nSkinID) or {}
    UIHelper.SetTexture(self.ImgEffect, tbUISkinInfo.szImgPath)
    UIHelper.SetString(self.LabelEffectName, tbUISkinInfo.szSkinName)
    UIHelper.SetVisible(self.ImgCollectIcon, CharacterSkillSkinData.GetSkinLike(self.tbInfo.nSkinID))

    if not self.tbInfo.bHave then
        UIHelper.SetOpacity(self.ImgEffect, 128)
    else
        UIHelper.SetOpacity(self.ImgEffect, 255)
    end

    local bUsing = player.IsSkillSkinActive(self.tbInfo.nSkinID)
    UIHelper.SetVisible(self.ImgEquipped, bUsing)

    local bNew = RedpointHelper.SkillSkin_IsNew(self.tbInfo.nSkinID)
    UIHelper.SetVisible(self.ImgNew, bNew)
    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UICharacterPendantEffectCell:SetClickCallback(callback)
    self.funcClickCallback = callback
end

function UICharacterPendantEffectCell:SetLongPressCallback(callback)
    self.funcLongPressCallback = callback
end

function UICharacterPendantEffectCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogAccessoryEffect, bSelected)
end

function UICharacterPendantEffectCell:UpdateNew()
    if not CharacterEffectData.bEffectUIIsShow then
        return
    end

    local bIsNew = RedpointHelper.Effect_IsNew(self.nCurSelectedIndex, self.tbInfo.dwEffectID)
    UIHelper.SetVisible(self.ImgNew, bIsNew)

    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

return UICharacterPendantEffectCell