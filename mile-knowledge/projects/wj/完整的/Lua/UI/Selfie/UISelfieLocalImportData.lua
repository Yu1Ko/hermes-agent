-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieLocalImportData
-- Date: 2025-10-25 20:46:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieLocalImportData = class("UISelfieLocalImportData")


local SELECT_SET =
{
	["tBase"]       = {fnSet=function(tSelfie) SelfieTemplateBase.SetBaseData(tSelfie.tBase) end},
	["tWind"]       = {fnSet=function(tSelfie) SelfieTemplateBase.SetWindData(tSelfie.tWind) end},
	["tLight"]      = {fnSet=function(tSelfie) SelfieTemplateBase.SetLightData(tSelfie.tLight) end},
	["tFilter"]     = {fnSet=function(tSelfie) SelfieTemplateBase.SetFilterData(tSelfie.tFilter) end}, 

    ["tAction"]     = {fnSet = function(tPlayer) SelfieTemplateBase.SetActionData(tPlayer.tAction) end},
    ["tFaceAction"] = {fnSet = function(tFaceAction) SelfieTemplateBase.SetFaceActionData(tFaceAction) end},
    ["tFace"]       = {fnSet = function(tPlayer) SelfieTemplateBase.SetFaceData(tPlayer.tFace) end}, 
    ["tBody"]       = {fnSet = function(tPlayer) SelfieTemplateBase.SetBodyData(tPlayer.tBody) end}, 
    ["tExterior"]   = {fnSet = function(tPlayer) SelfieTemplateBase.SetPlayerExteriorRes(tPlayer.tExterior) end}, 
    ["tPendant"]    = {fnSet = function(tPlayer) SelfieTemplateBase.SetPlayerPendantRes(tPlayer.tExterior) end}, 
    ["tSFXPendant"] = {fnSet = function(tPlayer) SelfieTemplateBase.SetPlayerSFXPendantRes(tPlayer.tExterior) end}, 
}

local ITEM_SORT = {
    [0] = "tAll",
    [1] = "tHave",
    [2] = "tBagHave", -- 不可交易
    [3] = "tBagHave", -- 可交易
    [4] = "tCoinShop",
    [5] = "tOther",
}

function UISelfieLocalImportData:OnEnter(OnHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.OnHideCallback = OnHideCallback
    self:Hide()
end

function UISelfieLocalImportData:OnExit(bForce)
    self.bInit = false
    self:UnRegEvent()

    if self.OnHideCallback then
        self.OnHideCallback()
    end
end

function UISelfieLocalImportData:Open(tData, OnHideCallback)
    self.bIsOpen = true
    self.tData = tData
    self.OnHideCallback = OnHideCallback
    self.tSelfieGroup = {}
    self.tPlayerGroup = {}
    self:Show()
    self:UpdateInfo()
end

function UISelfieLocalImportData:Show()
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
end

function UISelfieLocalImportData:Hide()
    self.bIsOpen = false
    SelfieTemplateBase.SetTemplateImportState(false)
    if self.OnHideCallback then
        self.OnHideCallback()
    end
    UIHelper.SetVisible(self._rootNode , false)
end

function UISelfieLocalImportData:IsOpen()
    return self.bIsOpen
end

function UISelfieLocalImportData:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRightClose, EventType.OnClick, function(btn)
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.TogSelfieSetting , EventType.OnClick , function (tog, bSelected)
        -- if self.bNoSelfie then
        --     UIHelper.SetSelected(self.TogPlayerSetting , true)
            -- OutputMessage("MSG_ANNOUNCE_RED", "非移动端数据，幻境云图参数不可用")
        --     return
        -- end
        -- UIHelper.SetSelected(self.TogPlayerSetting , false)
        self:TogSwitch(false)
    end)

    UIHelper.BindUIEvent(self.TogPlayerSetting , EventType.OnClick , function ()
        -- if self.bNoPlayer then
        --     UIHelper.SetSelected(self.TogSelfieSetting , true)
            -- OutputMessage("MSG_ANNOUNCE_RED", "体型不一致或角色数据为空，角色参数不可用")
        --     return
        -- end
        -- UIHelper.SetSelected(self.TogSelfieSetting , false)
        self:TogSwitch(true)
    end)

    UIHelper.BindUIEvent(self.BtnGo , EventType.OnClick , function ()
        SelfieTemplateBase.SavePhotoDataByCloud(clone(self.tData))
        local tPlace = self.tData.tPlayerParam.tPlace
        if SelfieData.IsStudioMap(tPlace.dwMapID) then
            SelfieTemplateBase.GuildToStudio(tPlace)
        else
            SelfieTemplateBase.SetPlaceGuild(tPlace)
        end
    end)

    UIHelper.BindUIEvent(self.BtnApplication , EventType.OnClick , function ()
        if not self.bNoSelfie then
            for szTitle, cell in pairs(self.tSelfieGroup) do
                if szTitle == "tBase" then
                    if cell:IsGroupDataSelected() then
                        self:UpdatePlayerBaseDirection() 
                    end
                end
                cell:SetGroup()
            end
        end

        if not self.bNoPlayer then
            for szTitle, cell in pairs(self.tPlayerGroup) do
                cell:SetGroup()
            end
        end
    end)
end

function UISelfieLocalImportData:TogSwitch(bPlayer)
    local bPlayer = bPlayer or false
    -- if not self.bNoSelfie then
        for _, cell in pairs(self.tSelfieGroup) do
            cell:Show(not bPlayer)
        end
    -- end


    -- if not self.bNoPlayer then
        for _, cell in pairs(self.tPlayerGroup) do
            cell:Show(bPlayer) 
        end
    -- end

    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

function UISelfieLocalImportData:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.PhotoExteriorData.Key then
            local nCurPercent = UIHelper.GetScrollPercent(self.ScrollViewData)
            Timer.AddFrame(self, 1, function()
                UIHelper.ScrollViewDoLayout(self.ScrollViewData)
                UIHelper.ScrollToPercent(self.ScrollViewData, nCurPercent)
            end)
        end
    end)
end

function UISelfieLocalImportData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieLocalImportData:UpdatePlayerBaseDirection()
    local tPlace = self.tData.tPlayerParam.tPlace
    SelfieTemplateBase.SetPlayerDirection(tPlace)
end




-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieLocalImportData:UpdateInfo()
    local hPlayer             = GetClientPlayer()
    local tPlace              = self.tData.tPlayerParam.tPlace
    local dwMapID             = tPlace.dwMapID
    local bIsHomelandMap      = SelfieTemplateBase.IsHomelandMap(dwMapID)
    local nMapType, dwPlaceID = SelfieTemplateBase.GetPhotoMapTypeAndID(self.tData)
    local szMap               = SelfieTemplateBase.GetPhotoMapName(nMapType, dwPlaceID)
    UIHelper.SetString(self.LabelLocate, UIHelper.LimitUtf8Len(szMap, 10))
    if bIsHomelandMap then
        UIHelper.SetButtonState(self.BtnGo, BTN_STATE.Disable, "家园地图拍摄地点不可追踪")
    else
        UIHelper.SetButtonState(self.BtnGo, BTN_STATE.Normal)
    end
    local szRoleType = g_tStrings.tShareDataRoleType[self.tData.tPlayerParam.nRoleType]
    local szRoleText = szRoleType .. "-"
    UIHelper.SetString(self.LabelLocalImportRoleType, szRoleText)

    local bIsMobile = self.tData.bIsMobile
    local nSelfRole = Player_GetRoleType(hPlayer)
    self.bNoSelfie  = not bIsMobile
    self.bNoPlayer  = (nSelfRole ~= self.tData.tPlayerParam.nRoleType)
    UIHelper.RemoveAllChildren(self.LayoutData)

    self:UpdateSelfieParam()
    self:UpdatePlayerParam()
    
    UIHelper.SetSelected(self.TogSelfieSetting , true)
    self:TogSwitch(false)
    if self.bNoSelfie and self.bNoPlayer then
        OutputMessage("MSG_ANNOUNCE_RED", "模板数据不可用")
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Disable, "模板数据不可用")
    elseif self.bNoSelfie then
        UIHelper.SetSelected(self.TogSelfieSetting , false)
        UIHelper.SetSelected(self.TogPlayerSetting , true)
        self:TogSwitch(true)
    end
end

function UISelfieLocalImportData:UpdateSelfieParam()
    local tTitle = {
        [1] = "tBase",
        [2] = "tWind",
        [3] = "tLight",
        [4] = "tFilter",
    }

    for _, szTitle in ipairs(tTitle) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportGroup, self.LayoutData)
        self.tSelfieGroup[szTitle] = cell   
        if szTitle == "tBase" then
            if szTitle == "tBase" then
                cell:OnEnter(szTitle, nil, nil, self.tData.tSelfieParam[szTitle], nil, not self.bNoSelfie, function()
                    self:UpdatePlayerBaseDirection()
                end)
            end
        else
            cell:OnEnter(szTitle, nil, nil, self.tData.tSelfieParam[szTitle], nil, not self.bNoSelfie)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

function UISelfieLocalImportData:UpdatePlayerParam()
    self:UpdateData()

    local tTitle = {
        [1] = "tAction",
        [2] = "tFaceAction",
        [3] = "tExterior",
        [4] = "tPendant",
        [5] = "tSFXPendant",
        [6] = "tFace",
        [7] = "tBody",
    }

    for _, szTitle in ipairs(tTitle) do
        if self.tExteriorType[szTitle] then
            if self.tExteriorType[szTitle] and not IsTableEmpty(self.tExteriorType[szTitle]) then
                local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportGroup, self.LayoutData)
                self.tPlayerGroup[szTitle] = cell   
                cell:OnEnter(szTitle, self.tItemInfo, self.tExteriorType[szTitle], self.tData.tPlayerParam.tExterior, self.tSort, not self.bNoPlayer)
            end
        elseif self.tData.tPlayerParam[szTitle] then
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportGroup, self.LayoutData)
            self.tPlayerGroup[szTitle] = cell   
            cell:OnEnter(szTitle, nil, nil, self.tData.tPlayerParam, nil, not self.bNoPlayer)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

function UISelfieLocalImportData:UpdateData()
    self.tExteriorAll = self.tData.tPlayerParam.tExterior
    if not self.tExteriorType then
        self:UpdateTitleItemList()
    end
    if not self.tItemInfo then
        self:UpdateItemInfo()
    end
end

function UISelfieLocalImportData:UpdateTitleItemList()
    self.tExteriorType = {
        ["tPendant"] = {},
        ["tSFXPendant"] = {},
        ["tExterior"] = {},
    }
    if self.tExteriorAll and not IsTableEmpty(self.tExteriorAll) then
        local tExteriorID = self.tData.tPlayerParam.tExterior.tExteriorID
        if not tExteriorID then
            return
        end
        for nResSub, v in pairs(g_tStrings.tPlayerParam) do
            local dwID = tExteriorID[nResSub]
            if dwID and dwID > 0 then
                if SelfieTemplateBase.IsSelfiePendant(nResSub) or nResSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then
                    self.tExteriorType.tPendant[nResSub] = dwID
                elseif SelfieTemplateBase.IsSelfieSFXPendant(nResSub) then
                    self.tExteriorType.tSFXPendant[nResSub] = dwID
                else
                    self.tExteriorType.tExterior[nResSub] = dwID
                end
            end

        end
    end
end

function UISelfieLocalImportData:UpdateItemInfo()
    self.tItemInfo = {}
    self.tSort = {
        tHave = {},
        tBagHave = {},
        tCoinShop = {},
        tOther = {},
    }

    if not IsTableEmpty(self.tExteriorAll) then
        local tSortList = ShareExteriorData.GetSortDataByExteriorData(self.tExteriorAll)
        for nSort = 1, 5 do
            local tList = tSortList[nSort]
            for _, tInfo in ipairs(tList) do
                self.tItemInfo[tInfo.nSub] = tInfo
                self.tSort[ITEM_SORT[nSort]][tInfo.nSub] = true
            end
        end
    end
end

return UISelfieLocalImportData