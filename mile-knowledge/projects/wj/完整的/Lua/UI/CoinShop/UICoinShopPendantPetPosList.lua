-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPendantPetPosList
-- Date: 2023-04-04 20:42:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

-- WidgetPetPlaceGroup
-- LayoutPetPlace

local UICoinShopPendantPetPosList = class("UICoinShopPendantPetPosList")

function UICoinShopPendantPetPosList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tScriptList = {}

    self:UpdateInfo()
end

function UICoinShopPendantPetPosList:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopPendantPetPosList:BindUIEvent()
    Event.Reg(self, "ON_PREVIEW_PENDANT_PET", function ()
        self:OnUpdatePendantPet()
    end)

    Event.Reg(self, "ON_PREVIEW_PENDANT_PET_POS", function()
        local tPendantPet = ExteriorCharacter.GetPreviewPendantPet()
        for _, scriptPos in ipairs(self.tScriptList) do
            UIHelper.SetSelected(scriptPos.TogImgPetPlace, scriptPos.tInfo.nPos == tPendantPet.nPos, false)
        end
    end)

    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function ()
        local tPendantPet = ExteriorCharacter.GetPreviewPendantPet()
        self:SetVisible(tPendantPet.dwPendantIndex > 0)
    end)

    Event.Reg(self, "COINSHOPVIEW_RIDE_DATA_UPDATE", function ()
        self:SetVisible(false)
    end)

    Event.Reg(self, "COINSHOPVIEW_PET_DATA_UPDATE", function ()
        self:SetVisible(false)
    end)

    Event.Reg(self, "COINSHOPVIEW_FURNITURE_DATA_UPDATE", function ()
        self:SetVisible(false)
    end)

    Event.Reg(self, "COINSHOP_SHOW_VIEW", function (szViewPage)
        szViewPage = szViewPage or "Role"
        if szViewPage == "Role" then
            local tPendantPet = ExteriorCharacter.GetPreviewPendantPet()
            self:SetVisible(tPendantPet.dwPendantIndex > 0)
        else
            self:SetVisible(false)
        end
    end)
end

function UICoinShopPendantPetPosList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopPendantPetPosList:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopPendantPetPosList:UpdateInfo()
    local tPendantPet = ExteriorCharacter.GetPreviewPendantPet()
    self:SetVisible(tPendantPet.dwPendantIndex > 0)
    if tPendantPet.dwPendantIndex > 0 then
        self:OnUpdatePendantPet()
    end
end

function UICoinShopPendantPetPosList:OnUpdatePendantPet()
    local tPendantPet = ExteriorCharacter.GetPreviewPendantPet()
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetPetPlaceGroup)
    UIHelper.RemoveAllChildren(self.LayoutPetPlace)
    self.tScriptList = {}
    local tPosList = CoinShop_GetPendantPetByItem(tPendantPet.dwPendantIndex)
    for _, tPos in ipairs(tPosList) do
        local scriptPos = UIHelper.AddPrefab(PREFAB_ID.WidgetPetPlace, self.LayoutPetPlace, tPos)
        table.insert(self.tScriptList, scriptPos)
        UIHelper.ToggleGroupAddToggle(self.WidgetPetPlaceGroup, scriptPos.TogImgPetPlace)
        UIHelper.SetSelected(scriptPos.TogImgPetPlace, tPos.nPos == tPendantPet.nPos, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutPetPlace)
    UIHelper.SetSelected(self._rootNode, true)  -- 挂宠显示时默认打开
end

function UICoinShopPendantPetPosList:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
    Event.Dispatch(EventType.OnCoinShopLayoutPetUpdate)
end

return UICoinShopPendantPetPosList