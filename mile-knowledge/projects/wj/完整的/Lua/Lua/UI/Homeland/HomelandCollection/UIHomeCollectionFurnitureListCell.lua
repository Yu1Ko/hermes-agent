-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionFurnitureListCell
-- Date: 2023-08-03 20:54:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionFurnitureListCell = class("UIHomeCollectionFurnitureListCell")

local ARCHITECTURE_INDEX = 1
local COIN_INDEX = 2
local DEFAULT_INDEX = 0

function UIHomeCollectionFurnitureListCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIHomeCollectionFurnitureListCell:OnExit()
    self.bInit = false
end

function UIHomeCollectionFurnitureListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFurnitureSift, EventType.OnClick, function ()
        self.funcSelectCallback()
    end)

    UIHelper.BindUIEvent(self.BtnFurnitureListCell, EventType.OnClick, function ()
        if self.funcClickCallback then
            if self.nSourceIndex ~= ARCHITECTURE_INDEX then
                self.bBuy = false
            elseif self.nSourceIndex == ARCHITECTURE_INDEX then
                self.bBuy = true
            end
            self.funcClickCallback(self.tUiInfo, self.bBuy)
        end
    end)
end

function UIHomeCollectionFurnitureListCell:RegEvent()
    Event.Reg(self, "LUA_HOMELAND_BUY_FURNITURE_END", function()
		self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function()
		self:UpdateInfo()
    end)
end

function UIHomeCollectionFurnitureListCell:UpdateInfo()
    local dwFurnitureID = self.tInfo.ID
    local pHlMgr = GetHomelandMgr()
    local bCollected = HomelandEventHandler.IsFurnitureCollected(dwFurnitureID)
    local dwFurnitureUiId = pHlMgr.MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
    local tFurnitureConfig = pHlMgr.GetFurnitureConfig(dwFurnitureID)
    local tUiAddInfo = Table_GetFurnitureAddInfo(dwFurnitureUiId)

    self.tUiInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
    self.nFinalArchitecture = tFurnitureConfig.nFinalArchitecture
    self.nSourceIndex = self:GetSourceIndex(dwFurnitureID)
    self:SetSelected(false)

    if tUiAddInfo and self.tUiInfo then
        local szPath = string.gsub(tUiAddInfo.szPath, "ui/Image", "mui/Resource")
        local szName = UIHelper.GBKToUTF8(self.tUiInfo.szName)
        szPath = string.gsub(szPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgFurniture, szPath)
        UIHelper.SetString(self.LabelFurnitureTitle, szName)
    end

    if self.nSourceIndex ~= ARCHITECTURE_INDEX then
        UIHelper.SetVisible(self.ImgLock, true)
        UIHelper.SetVisible(self.TogFurnitureSift, false)
        self.bCanBuy = false
    else
        self.bCanBuy = true
    end

    if bCollected then
        self.bCanBuy = false
        UIHelper.SetVisible(self.ImgLock, false)
        UIHelper.SetVisible(self.TogFurnitureSift, false)
        -- UIHelper.SetNodeGray(self.ImgFurniture, false, true)
        UIHelper.SetOpacity(self.ImgFurniture, 255)
    else
        UIHelper.SetVisible(self.ImgLock, true)
        UIHelper.SetVisible(self.TogFurnitureSift, false)
        -- UIHelper.SetNodeGray(self.ImgFurniture, true, true)
        UIHelper.SetOpacity(self.ImgFurniture, 100)
    end
end

function UIHomeCollectionFurnitureListCell:GetSourceIndex(dwFurnitureID)
    local aSourceTypeTexts = g_tStrings.tStrHomelandFurnitureFilterSourceTypes
	local dwUIFurnitureID = GetHomelandMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
	local tItemAddInfo = Table_GetFurnitureAddInfo(dwUIFurnitureID)
	local szSource = UIHelper.GBKToUTF8(tItemAddInfo.szSource)
	for nIndex, tSource in ipairs(aSourceTypeTexts) do
		if string.find(szSource, tSource[1]) then
			return nIndex
		end
	end
	nIndex = DEFAULT_INDEX
	return nIndex
end

function UIHomeCollectionFurnitureListCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogFurnitureSift, bSelected)
end

function UIHomeCollectionFurnitureListCell:SetClickCallback(funcCallback)
    self.funcClickCallback = funcCallback
end

function UIHomeCollectionFurnitureListCell:SetSelectCallback(funcCallback)
    self.funcSelectCallback = funcCallback
end

function UIHomeCollectionFurnitureListCell:GetSelected()
    return UIHelper.GetSelected(self.TogFurnitureSift)
end

function UIHomeCollectionFurnitureListCell:SetCanBuy(bCanBuy)
    if self.bCanBuy then
        UIHelper.SetVisible(self.ImgLock, not bCanBuy)
        UIHelper.SetVisible(self.TogFurnitureSift, bCanBuy)
    end
end

return UIHomeCollectionFurnitureListCell