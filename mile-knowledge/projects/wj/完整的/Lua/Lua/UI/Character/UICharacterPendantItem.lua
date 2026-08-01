-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantItem
-- Date: 2023-03-06 15:25:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantItem = class("UICharacterPendantItem")
function UICharacterPendantItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
        self.ToggleSelect = self.scriptItemIcon.ToggleSelect
        self.ImgIcon = self.scriptItemIcon.ImgIcon
    end
end

function UICharacterPendantItem:OnInitWithTabID(nTabType, nTabID)
    self.nTabType = nTabType
    self.nTabID = nTabID
    self:UpdateInfo(nTabType, nTabID)
    self:UpdateDownloadEquipRes()
end

function UICharacterPendantItem:OnInitWithDXSkillSkin(nSkillID, nSkinID, bHave)
    self.nSkillID = nSkillID
    self.nSkinID = nSkinID
    self:UpdateDXSkillSkin(nSkillID, nSkinID, bHave)
end

function UICharacterPendantItem:OnExit()
    self.bInit = false

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UICharacterPendantItem:BindUIEvent()
    Event.Reg(self, EventType.OnCharacterPendantPageItemSelected, function(nTabID)
        self.nCurSelectedItemID = nTabID
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
    end)
end

function UICharacterPendantItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterPendantItem:UpdateInfo(nTabType, nTabID)
    local itemInfo = ItemData.GetItemInfo(nTabType, nTabID)
    if itemInfo then
        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(itemInfo.szName), 8)
    end
    self.scriptItemIcon:OnInitWithTabID(nTabType, nTabID)
end

function UICharacterPendantItem:UpdateDXSkillSkin(nSkillID, nSkinID, bHave)
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbInfo = {}
    local szName = ""
    local bIsActivityOn = false
    local bHaveActSkin = false
    local dwGroupID = CharacterSkillSkinData.GetGroupID(nSkillID)
    local dwActSkinID = player.GetActiveSkillSkinByGroupID(dwGroupID)
    if dwActSkinID and dwActSkinID > 0 then
        bHaveActSkin = true
    end
    if nSkinID and nSkinID > 0 then
        bIsActivityOn = player.IsSkillSkinActive(nSkinID)
        tbInfo = Table_GetSkillSkinInfo(nSkinID)
        szName = UIHelper.GBKToUTF8(tbInfo.szName)
    else
        bIsActivityOn = not bHaveActSkin
        szName = Table_GetSkillName(nSkillID, 1)
        szName = UIHelper.GBKToUTF8(szName).."·".."默认"
    end

    if not self.scriptItemIcon then
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
        self.ToggleSelect = self.scriptItemIcon.ToggleSelect
        self.ImgIcon = self.scriptItemIcon.ImgIcon
    end

    if szName then
        UIHelper.SetString(self.LabelName, szName, 8)
    end

    if tbInfo and tbInfo.nIconID then
        self.scriptItemIcon:OnInitWithIconID(tbInfo.nIconID)
    else
        self.scriptItemIcon:OnInitWithIconID(17603)
    end

    UIHelper.SetNodeGray(self.ImgIcon, not bHave)
    UIHelper.SetVisible(self.ImgEquipped, bIsActivityOn)
    UIHelper.SetVisible(self.ImgMask, not bHave)
    UIHelper.LayoutDoLayout(self.LayoutIcon)

    if bHave then
        UIHelper.SetOpacity(self.WidgetItem, 255)
    else
        UIHelper.SetOpacity(self.WidgetItem, 120)
    end
end

function UICharacterPendantItem:SetSelected(bSelected)
    if not self.scriptItemIcon then
        return
    end

    self.scriptItemIcon:SetSelected(bSelected)
end

function UICharacterPendantItem:SetClickCallback(funcCallback)
    if not self.scriptItemIcon then
        return
    end

    self.scriptItemIcon:SetClickCallback(funcCallback)
end

function UICharacterPendantItem:SetLongPressCallback(funcCallback)
    if not self.scriptItemIcon then
        return
    end

    self.scriptItemIcon:SetLongPressCallback(funcCallback)
    UIHelper.SetLongPressDelay(self.scriptItemIcon.ToggleSelect, 0.5)
end

function UICharacterPendantItem:SetDownloadEnabled(bEnable)
    self.bDownloadEnabled = bEnable
end

function UICharacterPendantItem:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not self.nTabID then
        return
    end
    local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, {{nSource=COIN_SHOP_GOODS_SOURCE.ITEM_TAB, dwID=self.nTabID}})
    local tConfig = {}
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetShowCondition(function ()
        return self.bDownloadEnabled and self.nTabID and self.nCurSelectedItemID == self.nTabID
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UICharacterPendantItem