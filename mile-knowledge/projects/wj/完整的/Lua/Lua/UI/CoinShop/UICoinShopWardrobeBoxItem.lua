-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopWardrobeBoxItem
-- Date: 2022-12-24 09:51:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopWardrobeBoxItem = class("UICoinShopWardrobeBoxItem")

function UICoinShopWardrobeBoxItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopWardrobeBoxItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UICoinShopWardrobeBoxItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLock, EventType.OnClick, function ()
        if self.szDisableTip then
            local szItemName
            for text in self.szDisableTip:gmatch("【(.-)】") do
                szItemName = text
                break
            end
            if szItemName then
                UIHelper.ShowConfirm(string.format("是否前往交易行购买【%s】扩展栏位?", szItemName), function()
                    local szLinkInfo = string.format("SourceTradeWithName/%s", szItemName)
                    Event.Dispatch("EVENT_LINK_NOTIFY", szLinkInfo)
                end)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", self.szDisableTip)
            end
        end
    end)
end

function UICoinShopWardrobeBoxItem:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownload()
    end)
end

function UICoinShopWardrobeBoxItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopWardrobeBoxItem:UpdateItemState()
    if self.tbPendant and self.itemIcon then
        local tbItem = {}
        tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
        tbItem.dwIndex = self.tbPendant.dwItemIndex
        tbItem.tColorID = {self.tbPendant.nColorID1, self.tbPendant.nColorID2, self.tbPendant.nColorID3}
        local bPreview = ExteriorCharacter.IsPendantPreview(tbItem)
        self.itemIcon:SetSelected(bPreview)
        local bSelected = ExteriorCharacter.IsPendantSelected(tbItem)
        UIHelper.SetVisible(self.ImgDressed, bSelected)
    elseif self.tbPendantPet and self.itemIcon then
        local tbItem = {}
        tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
        tbItem.dwIndex = self.tbPendantPet.dwItemIndex
        local bPreview = ExteriorCharacter.IsPendantPetPreview(tbItem)
        self.itemIcon:SetSelected(bPreview)
        local bSelected = ExteriorCharacter.IsPendantPetSelected(tbItem)
        UIHelper.SetVisible(self.ImgDressed, bSelected)
    end
end

function UICoinShopWardrobeBoxItem:OnInitWithPendant(tbPendant)
    local bOnEnter = not self.bInit
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbPendant = tbPendant
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.BtnLock, false)
    UIHelper.SetVisible(self.ImgDressed, false)
    UIHelper.SetVisible(self.WidgetItem, true)
    if not self.itemIcon then
        self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
        self.itemIcon:SetClickCallback(function ()
            self:OnSelectPendant(self.tbPendant)
        end)
    end
    self.itemIcon:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, tbPendant.dwItemIndex)
    self.itemIcon:SetTouchDownHideTips(false)

    local tbItem = {}
    tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    tbItem.dwIndex = self.tbPendant.dwItemIndex
    tbItem.tColorID = {self.tbPendant.nColorID1, self.tbPendant.nColorID2, self.tbPendant.nColorID3}
    local bPreview = ExteriorCharacter.IsPendantPreview(tbItem)
    self.itemIcon:SetSelected(bPreview, false)
    local bSelected = ExteriorCharacter.IsPendantSelected(tbItem)
    UIHelper.SetVisible(self.ImgDressed, bSelected)

    if bOnEnter then
        self:UpdateDownloadEquipRes({{nSource=COIN_SHOP_GOODS_SOURCE.ITEM_TAB, dwID=tbItem.dwIndex, tColorID=tbItem.tColorID}})
    end

    local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, self.tbPendant.dwItemIndex)
	if tItemInfo then
		local nPendantType = CharacterPendantData.GetRedPointPendantType(tItemInfo.nSub)
        if nPendantType then
            UIHelper.SetVisible(self.ImgRedPoint, RedpointHelper.Pendant_IsNew(nPendantType, self.tbPendant.dwItemIndex))
        end
	end
end

function UICoinShopWardrobeBoxItem:OnSelectPendant(tbPendant)
    local tbItem = {}
    tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    tbItem.dwIndex = tbPendant.dwItemIndex
    tbItem.tColorID = {tbPendant.nColorID1, tbPendant.nColorID2, tbPendant.nColorID3}
    local bPreview = ExteriorCharacter.IsPendantPreview(tbItem)
    if bPreview then
        FireUIEvent("CANCEL_PREVIEW_PENDANT", tbItem, false, false, true)
    else
        FireUIEvent("PREVIEW_PENDANT", tbItem, false, false, true)
    end

    local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, tbPendant.dwItemIndex)
    if tItemInfo then
        local nPendantType = CharacterPendantData.GetRedPointPendantType(tItemInfo.nSub)
        if nPendantType then
            if RedpointHelper.Pendant_IsNew(nPendantType, tbPendant.dwItemIndex) then
                RedpointHelper.Pendant_SetNew(nPendantType, tbPendant.dwItemIndex, false)
            end
            UIHelper.SetVisible(self.ImgRedPoint, false)
        end
    end
end

function UICoinShopWardrobeBoxItem:OnInitWithPendantPet(tbPendantPet)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbPendantPet = tbPendantPet
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.BtnLock, false)
    UIHelper.SetVisible(self.ImgDressed, false)
    UIHelper.SetVisible(self.WidgetItem, true)
    if not self.itemIcon then
        self.itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
        self.itemIcon:SetClickCallback(function ()
            self:OnSelectPendantPet(self.tbPendantPet)
        end)
    end
    self.itemIcon:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, tbPendantPet.dwItemIndex)
    self.itemIcon:SetTouchDownHideTips(false)

    local tbItem = {}
    tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    tbItem.dwIndex = self.tbPendantPet.dwItemIndex
    local bPreview = ExteriorCharacter.IsPendantPetPreview(tbItem)
    self.itemIcon:SetSelected(bPreview, false)
    local bSelected = ExteriorCharacter.IsPendantPetSelected(tbItem)
    UIHelper.SetVisible(self.ImgDressed, bSelected)

    UIHelper.SetVisible(self.ImgRedPoint, RedpointHelper.PendantPet_IsNew(tbPendantPet.dwItemIndex))
end

function UICoinShopWardrobeBoxItem:OnSelectPendantPet(tbPendantPet)
    local tbItem = {}
    tbItem.dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET
    tbItem.dwIndex = tbPendantPet.dwItemIndex
    local bPreview = ExteriorCharacter.IsPendantPetPreview(tbItem)
    if bPreview then
        FireUIEvent("CANCEL_PREVIEW_PENDANT_PET", tbItem, false, false)
    else
        FireUIEvent("PREVIEW_PENDANT_PET", tbItem, false, false)
    end

    if RedpointHelper.PendantPet_IsNew(tbPendantPet.dwItemIndex) then
        RedpointHelper.PendantPet_SetNew(tbPendantPet.dwItemIndex, false)
    end
    UIHelper.SetVisible(self.ImgRedPoint, false)
end

function UICoinShopWardrobeBoxItem:OnInitWithEmpty()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.BtnLock, false)
    UIHelper.SetVisible(self.ImgDressed, false)
    UIHelper.SetVisible(self.WidgetItem, false)
end

function UICoinShopWardrobeBoxItem:OnInitWithLock(szDisableTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szDisableTip = szDisableTip
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.BtnLock, true)
    UIHelper.SetVisible(self.ImgDressed, false)
    UIHelper.SetVisible(self.WidgetItem, false)
end

function UICoinShopWardrobeBoxItem:UpdateDownloadEquipRes(tList)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, tList)
    self.tEquipList, self.tEquipSfxList = tEquipList, tEquipSfxList
    self:UpdateDownload()
end

function UICoinShopWardrobeBoxItem:UpdateDownload()
    local tEquipList, tEquipSfxList = self.tEquipList, self.tEquipSfxList
    if not tEquipList or not tEquipSfxList then
        return
    end
    if not self.itemIcon then
        return
    end
    local tConfig = {}
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.itemIcon.WidgetDownloadShell)
    scriptMask:SetShowCondition(function ()
        return UIHelper.GetSelected(self.itemIcon.ToggleSelect)
    end)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UICoinShopWardrobeBoxItem