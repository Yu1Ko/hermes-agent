-- ---------------------------------------------------------------------------------
-- Name: UICharacterAvatarCell
-- Desc: WidgetHeadListItem
-- ---------------------------------------------------------------------------------

local UICharacterAvatarCell = class("UICharacterAvatarCell")

function UICharacterAvatarCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICharacterAvatarCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICharacterAvatarCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHead, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            if self.func then
                self.func(self.dwID, self.bIsDesignation)
            end
            -- Event.Dispatch(EventType.PreviewAvator, self.dwID, g_pClientPlayer.dwID)
        end
    end)
end

function UICharacterAvatarCell:RegEvent()

end

function UICharacterAvatarCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterAvatarCell:UpdateInfo(dwID, bIsDesignation)
    self.dwID = dwID
    self.bIsDesignation = bIsDesignation
    if not bIsDesignation then
        self:UpdateAvatar()
        local tAvaInfo = Table_GetRoleAvatarInfo(dwID)
        local szName
        local tItemList = SplitString(tAvaInfo.szLinkItem, "|")

        if #tItemList < 1 then
            if tAvaInfo.dwForceID ~= 0 or dwID == 0 then
                szName = "门派头像"
            else
                szName = "江湖头像"
            end
        else
            local tItem = SplitString(tItemList[1], ";")
            local item = ItemData.GetItemInfo(tonumber(tItem[1]), tonumber(tItem[2]))
            szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(item, nil))
        end

        UIHelper.SetString(self.LabelName, szName)
        UIHelper.SetVisible(self.LabelName, not string.is_nil(szName))
        UIHelper.SetVisible(self.ImgNameBg, not string.is_nil(szName))
    else
        local tAvaInfo = Table_GetDesignationDecorationInfo(dwID)

        local tItemList = SplitString(tAvaInfo.szLinkItem, "|")
        local szName = "称号装饰"
        if #tItemList >= 1 then
            local tItem = SplitString(tItemList[1], ";")
            local nTabType = tonumber(tItem[1])
            local nTabID = tonumber(tItem[2])
            local item = ItemData.GetItemInfo(nTabType, nTabID)
            szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(item))
        end
        UIHelper.SetString(self.LabelName, szName)
        local scriptNode = UIHelper.AddPrefab(PREFAB_ID.WidgetDecorationCell, self.WidgetHeadShell)
        scriptNode:OnEnter(tAvaInfo)
    end
    
end

function UICharacterAvatarCell:UpdateAvatar()
    UIHelper.RoleChange_UpdateAvatar(self.ImgPlayer, self.dwID, self.SFXPlayerIcon, self.AnimatePlayer, nil, nil, true,false, nil, false)
    UIHelper.UpdateAvatarFarme(self.tbImgFrame, self.dwID, self.SFXFrameBgAll, self.SFXFrameBg1, self.SFXFrameBg3)
    -- UIHelper.SetNodeSwallowTouches(self.WidgetMainCityPlayer, false, true)
    -- UIHelper.SetNodeSwallowTouches(self.WidgetPlayerNormal, false, true)
end

function UICharacterAvatarCell:SetEquipmentState(bEquipment)
    UIHelper.SetVisible(self.ImgEquipped, bEquipment)
    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UICharacterAvatarCell:SetLikeState(bLike)
    UIHelper.SetVisible(self.ImgLikeIcon, bLike)
    UIHelper.LayoutDoLayout(self.LayoutIcon)
end

function UICharacterAvatarCell:SetGottenState(bHave)
    UIHelper.SetVisible(self.ImgNotGottenMask, not bHave)
end

function UICharacterAvatarCell:SetClickCallback(func)
    self.func = func
end

function UICharacterAvatarCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogHead, bSelected, false)
end

function UICharacterAvatarCell:SetNewState(bIsNew)
    UIHelper.SetVisible(self.ImgNew, bIsNew)
end

function UICharacterAvatarCell:UpdateBoxReward(dwID)
    self.dwID = dwID
    self:UpdateAvatar()
    local ImgBg = UIHelper.GetChildByName(self.TogHead, "ImgBg")
    UIHelper.SetVisible(ImgBg, false)
    UIHelper.SetVisible(self.ImgNameBg, false)
    UIHelper.SetVisible(self.LabelName, false)
    UIHelper.SetTouchEnabled(self.TogHead, false)
end

return UICharacterAvatarCell