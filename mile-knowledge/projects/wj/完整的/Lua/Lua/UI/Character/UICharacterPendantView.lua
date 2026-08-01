-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantView
-- Date: 2023-02-27 11:12:46
-- Desc: ?
-- ---------------------------------------------------------------------------------
local OptionEnum = {
    ["HideAppearance"] = 1,
    ["HideHat"] = 2,
    ["HideFaceDeco"] = 3,
    ["HideFaceHanging"] = 4,
    ["HideCloak"] = 5,
}

local UICharacterPendantView = class("UICharacterPendantView")
require("Lua/UI/Character/UICharacterPendantPublicPage.lua")

function UICharacterPendantView:OnEnter(bCloseBefore, dwType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitTogOptions()

    self:UpdateDownloadEquipRes()
    self:UpdateInfo()
    UIMgr.HideView(VIEW_ID.PanelCharacter)
    self.bCloseBefore = bCloseBefore
    if dwType and dwType > 1 and dwType < 5 then
        UIHelper.SetSelected(self.tbTogPage[dwType], true)
        UIHelper.SetSelected(self.tbTogPage[1], false)
    end

    Timer.Add(self, 0.1, function()
        self:UpdateRedPointArrow()
        Event.Dispatch(EventType.OnCharacterPendantSelected, dwType or 1)
    end)

    Timer.AddCycle(self, 0.1, function()
        UIHelper.LayoutDoLayout(self.WidgetTogFoldEffect)
        UIHelper.LayoutDoLayout(self.WidgetTogFoldAccessory)
    end)
end

function UICharacterPendantView:OnExit()
    self.bInit = false
    UIMgr.ShowView(VIEW_ID.PanelCharacter)
    Event.Dispatch(EventType.OnCharacterPendantSelected, 0)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
    if self.bCloseBefore then
        UIMgr.Close(VIEW_ID.PanelCharacter)
    end

    if CharacterAvartarData.bOpenThisAfterCloseAccessory then
        UIMgr.Open(VIEW_ID.PanelPersonalTitle)
    end
end

function UICharacterPendantView:BindUIEvent()
    for i, tog in ipairs(self.tbTogPage) do
        if i == AccessoryMainPageIndex.IdleAction then
            UIHelper.SetVisible(tog, IsDebugClient() or UI_IsActivityOn(ACTIVITY_ID.ACTION))
        end
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                Event.Dispatch(EventType.OnCharacterPendantSelected, i)
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogFoldFoldEffect, EventType.OnClick, function(btn)
        local bSelected = UIHelper.GetSelected(self.TogFoldFoldEffect)
        UIHelper.SetVisible(self.WidgetJoystickAnchor, bSelected)
        UIHelper.LayoutDoLayout(self.WidgetTogFoldEffect)
        UIHelper.LayoutDoLayout(self.WidgetTogFoldAccessory)
    end)

    for nIndex, tog in ipairs(self.tbToggleOptions) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            if nIndex == OptionEnum.HideAppearance then
                if not UIHelper.GetSelected(tog) then
                    RemoteCallToServer("OnUnApplyExterior")
                    TipsHelper.ShowNormalTip("已隐藏外观显示")
                else
                    RemoteCallToServer("OnApplyExterior")
                    TipsHelper.ShowNormalTip("已开启外观显示")
                end
            elseif nIndex == OptionEnum.HideHat then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    PlayerData.HideHat(not bSelected)
                    FireUIEvent("PLAYER_HIDE_HAT_CHANGE")
                    if bSelected then
                        TipsHelper.ShowNormalTip("已开启帽子显示")
                    else
                        TipsHelper.ShowNormalTip("已隐藏帽子显示")
                    end
                end
            elseif nIndex == OptionEnum.HideFaceDeco then
                local bSelected = UIHelper.GetSelected(tog)
                GetFaceLiftManager().SetDecorationShowFlag(bSelected)
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启面饰显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏面饰显示")
                end
            elseif nIndex == OptionEnum.HideFaceHanging then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    player.SetFacePendentHideFlag(not bSelected)
                end
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启面挂显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏面挂显示")
                end
            elseif nIndex == OptionEnum.HideCloak then
                local bSelected = UIHelper.GetSelected(tog)
                local player = PlayerData.GetClientPlayer()
                if player then
                    player.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, not bSelected)
                end
                if bSelected then
                    TipsHelper.ShowNormalTip("已开启披风显示")
                else
                    TipsHelper.ShowNormalTip("已隐藏披风显示")
                end
            end
        end)
    end

	UIHelper.BindUIEvent(self.ScrollViewTogList, EventType.OnChangeSliderPercent, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)

    self.scriptJoyStick = UIHelper.AddPrefab(PREFAB_ID.WidgetPerfabJoystick, self.WidgetJoystick)
end

function UICharacterPendantView:RegEvent()
    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
        if arg0 == g_pClientPlayer.dwID then
            self:UpdateDownloadEquipRes()
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
    end)

    Event.Reg(self, "ON_UPDATE_REPRESENT_HIDE_FLAG_NOTIFY", function(dwPlayerID, nType)
        if dwPlayerID == UI_GetClientPlayerID() then
            if nType == PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL then
                self:UpdateHideCloakCheck()
            elseif nType == PLAYER_REPRESENT_HIDE_TYPE.IDLE_WEAPON then
                self:UpdateHideWeaponCheck()
            end
        end
    end)
end

function UICharacterPendantView:UpdateHideCloakCheck()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideCloak], not hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL), false)
end

function UICharacterPendantView:UpdateHideWeaponCheck()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideWeapon], not hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.IDLE_WEAPON), false)
end

function UICharacterPendantView:UpdateInfo()

    local bDxSkill = SkillData.IsUsingHDKungFu()
    UIHelper.SetVisible(self.tbTogPage[7], bDxSkill)

    local bWXLSkinSkillLearn = SkillData.GetWXLSkinSkillLearn()
    UIHelper.SetVisible(self.tbTogPage[8], bWXLSkinSkillLearn)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTogList)
end

function UICharacterPendantView:InitTogOptions()
    local player = PlayerData.GetClientPlayer()
    if not player then return end

    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideAppearance], player.IsApplyExterior())
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideHat], not player.bHideHat)
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideFaceDeco], GetFaceLiftManager().GetDecorationShowFlag())
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideFaceHanging], not player.bHideFacePendent)
    UIHelper.SetSelected(self.tbToggleOptions[OptionEnum.HideCloak], not player.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL))
end

function UICharacterPendantView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not g_pClientPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UICharacterPendantView:CalcScrollPosY()
	local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewTogList, 0, 0)
	self.nScrollViewY = nWorldY
end

function UICharacterPendantView:HasRedPointBelow()
	local bHasRedPointBelow = false

	if not self.nScrollViewY then
		self:CalcScrollPosY()
	end

	for k, v in ipairs(self.tbLeftTogListRedPoint) do
		if UIHelper.GetVisible(v) then
			local nHeight = UIHelper.GetHeight(v)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v, 0, nHeight)
			if _nWorldY < self.nScrollViewY then
				bHasRedPointBelow = true
				break
			end
		end
	end
	return bHasRedPointBelow
end

function UICharacterPendantView:UpdateRedPointArrow()
	local bHasRedPointBelow = self:HasRedPointBelow()
	UIHelper.SetActiveAndCache(self, self.ImgRedPointArrow, bHasRedPointBelow)
end

return UICharacterPendantView