-- ---------------------------------------------------------------------------------
-- Name: UICharacterAvatarPage
-- Desc:
-- ---------------------------------------------------------------------------------
---@type UICharacterPendantPublicPage
---@class UICharacterAvatarPage : UICharacterPendantPublicPage
local UICharacterAvatarPage = class(UICharacterPendantPublicPage, "UICharacterAvatarPage")

---------------------------------------- Data -----------------------------------------

local MINGJIAO_FORCE_ID = 10
local EACH_PAGE_MAX_COUNT = 12
local MAX_COLLECTION_COUNT = 8 --收藏上限
local SCHOOL_GAINWAY_TYPE = -1
local REMOTE_PREFER_ROLEAVATAR = 1168 --收藏头像远程数据块
local PREFER_REMOTE_DATA_START = 0
local PREFER_REMOTE_DATA_END = 14
local PREFER_REMOTE_DATA_LEN = 2
local DEFAULT_AVATAR_ID = 65535 --默认的初始门派头像原本id为0，和收藏头像的远程数据块里默认值也是0冲突了，因此特判为两个字节所能存储的最大值
local DESIGNATION_PAGE_MAX_COUNT = 8
local TITLE = {
	-- CharacterAvartarData.TITLE
}

local CELL_TYPE = 
{
    NORMAL = 1,
    DESIGNATIONDECORATION = 2
}

local SourceTypeSearchIndex = {
	["tSourceProduce"] = ITEM_SOURCE_TYPE.CRAFT,
    ["tSourceCollectD"] = ITEM_SOURCE_TYPE.CRAFT,
	["tSourceCollectN"] = ITEM_SOURCE_TYPE.CRAFT,
	["tBoss"] = ITEM_SOURCE_TYPE.BOSS,
	["tSourceNpc"] = ITEM_SOURCE_TYPE.SHOP,
	["tItems"] = ITEM_SOURCE_TYPE.TREASURE_BOX,
	["tQuests"] = ITEM_SOURCE_TYPE.QUEST,
	["bTrades"] = ITEM_SOURCE_TYPE.TRADE,
	["tActivity"] = ITEM_SOURCE_TYPE.ACTIVITY,
	["tShop"] = ITEM_SOURCE_TYPE.SHOP,
	["tCoinShop"] = ITEM_SOURCE_TYPE.COINSHOP,
	["tReputation"] = ITEM_SOURCE_TYPE.REPUTATION,
	["tAchievement"] = ITEM_SOURCE_TYPE.ACHIEVEMENT,
	["tAdventure"] = ITEM_SOURCE_TYPE.ADVENTURE,
	["tLinkItem"] = ITEM_SOURCE_TYPE.TRADE,
	["tFunction"] = ITEM_SOURCE_TYPE.LINK,
	["tEventLink"] = ITEM_SOURCE_TYPE.LINK,
}

local tmpIndex2Search = {
    [0] = 0,
    [1] = SCHOOL_GAINWAY_TYPE,
    [2] = ITEM_SOURCE_TYPE.SHOP,
    [3] = ITEM_SOURCE_TYPE.TREASURE_BOX,
    [4] = ITEM_SOURCE_TYPE.TRADE,
    [5] = ITEM_SOURCE_TYPE.COINSHOP,
    [6] = ITEM_SOURCE_TYPE.LINK,
}

function ItemSource_GetSearchIndexList(dwItemType, dwItemIndex)
    if not dwItemType or not dwItemIndex then
        return
    end

    local tSearchIndex = {}
    local tSource = ItemData.GetItemSourceList(dwItemType, dwItemIndex)
    if not tSource then
		return tSearchIndex
	end

    for szSource, Data in pairs(tSource) do
        local nIndex
        if type(Data) == "table" then
            if Data and #Data > 0 then
                nIndex = SourceTypeSearchIndex[szSource]
            end
        elseif type(Data) == "boolean" then
            if Data then
                nIndex = SourceTypeSearchIndex[szSource]
            end
        end
        if nIndex and not tSearchIndex[nIndex] then
            tSearchIndex[nIndex] = true
        end
    end
    return tSearchIndex
end

function ItemSource_GetSourceName(szData)
    if not szData or szData == "" then
        return
    end

    return SourceTypeSearchIndex[szData] or ""
end

---------------------------------------- Data -----------------------------------------

local DataModel = {}

function DataModel.Init()
    TITLE = CharacterAvartarData.TITLE
    DataModel.UnInit()
    DataModel.tAllAvatar     = Table_GetAllRoleAvatarList()
    table.insert(DataModel.tAllAvatar, {dwID = 0, dwForceID = 0})
	DataModel.nSelTitle		 = CharacterAvartarData.GetInitTitle()
    DataModel.nSelPage  	 = 1
    DataModel.nMaxPage       = 1
    DataModel.nEditPageNum   = nil
	DataModel.tDetail        = {}
    DataModel.szSearchText   = ""
	DataModel.bCheckCap	     = nil
	DataModel.nFilterHave    = 0
	DataModel.nFilterGainWay = 0
	-- DataModel.tGainWayMenu   = {}
	DataModel.bEnableCollect = nil
	DataModel.tCollection	 = {}

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

	local AvatarMgr = pPlayer.GetMiniAvatarMgr()
	if not AvatarMgr.bDataSynced then
		AvatarMgr.ApplyMiniAvatarData()
	end
    DataModel.UpdateAvatarDetailInfo()
	DataModel.UpdateCollectionData()
	-- DataModel.InitGainWayMenu()
    DataModel.InitDesignationGainWayMenu()
end

function DataModel.UnInit()
    DataModel.tAllAvatar     = nil
	DataModel.nSelTitle		 = nil
    DataModel.nSelPage       = nil
    DataModel.nMaxPage       = nil
    DataModel.nEditPageNum   = nil
	DataModel.tDetail        = nil -- 拥有数据
    DataModel.szSearchText   = nil
	DataModel.bCheckCap	     = nil
	DataModel.nFilterHave    = nil
	DataModel.nFilterGainWay = nil
	DataModel.tGainWayMenu   = nil
	DataModel.bEnableCollect = nil
	DataModel.tCollection	 = nil -- 收藏数据
    DataModel.tFilter 	 	 = nil -- 筛选数据
    DataModel.nFakeCount     = 0
    DataModel.tDesignationGainWayMenu = nil
	DataModel.tAlDecorationList = nil
end

function DataModel.GetGainWayMenu(tAllInfo)
	local tSearchList = {}
	for _, tInfo in ipairs(tAllInfo) do
		if tInfo.szLinkItem and tInfo.szLinkItem ~= "" then
			local tItemList = SplitString(tInfo.szLinkItem, "|")
			for k, v in pairs(tItemList) do
				local t = SplitString(v, ";")
				local dwItemType = tonumber(t[1])
				local dwItemIndex = tonumber(t[2])
				if dwItemType and dwItemType ~= 0 and dwItemIndex and dwItemIndex ~= 0 then
					local tSearchIndex = ItemSource_GetSearchIndexList(dwItemType, dwItemIndex)
					for nIndex, _ in pairs(tSearchIndex) do
						if not tSearchList[nIndex] then
							tSearchList[nIndex] = true
						end
					end
				end
			end
		end
	end
	return tSearchList
end

function DataModel.InitDesignationGainWayMenu()
	DataModel.GetAllDecoration()
	local tAllInfo 		= DataModel.tAlDecorationList
	local tSearchList 	= DataModel.GetGainWayMenu(tAllInfo)
	local tGainWayMenu 	= {}
	for nIndex, _ in pairs(tSearchList) do
		table.insert(tGainWayMenu, nIndex)
	end
	table.sort(tGainWayMenu)
	DataModel.tDesignationGainWayMenu = tGainWayMenu
end

function DataModel.SetSelPage(nPage)
    if nPage < 1 or nPage > DataModel.nMaxPage then
        return
    end
    DataModel.nSelPage = nPage
end

function DataModel.UpdateMaxPage()
    local tAllList = DataModel.tFilter
	local nMaxPage = 1
	local nLen = #tAllList
	if nLen > 0 then
		nMaxPage = math.floor((nLen - 1) / EACH_PAGE_MAX_COUNT) + 1
	end

    DataModel.nMaxPage = nMaxPage or 1
end

function DataModel.UpdateAvatarDetailInfo()
	local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    DataModel.tDetail = nil
	DataModel.tDetail = {}

	-- local szPath, nFrame = GetForceImage(pPlayer.dwForceID) --- todo
	DataModel.tDetail[0] = {
			dwID = 0,
			dwForceID = 0,
			isfree = true,
			bAnimate = false,
	}

	local AvatarMgr = pPlayer.GetMiniAvatarMgr()

	local t = AvatarMgr.GetAllMiniAvatar()
	table.sort(t,
		function(a, b)
			return (a.dwID > b.dwID)
		end
	)

	for _, info in ipairs(t) do
		local tLine = Table_GetRoleAvatarInfo(info.dwID)
		if tLine then
			if tLine.dwForceID ~= 0 then
				local bResult = DataModel.CanGetAvatar(tLine.nHat)
				if bResult then
					DataModel.tDetail[info.dwID] = tLine
				end
			else
				DataModel.tDetail[info.dwID] = tLine
			end
		end
	end
end

function DataModel.CanGetAvatar(nHat)
	local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

	if pPlayer.dwForceID == MINGJIAO_FORCE_ID and nHat ~= -1 then --明教兜帽判定
		local bIsSecondRepresent = pPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
		if DataModel.bCheckCap then
			if bIsSecondRepresent and nHat == 0 then
				return true
			elseif not bIsSecondRepresent and nHat == 1 then
				return true
			end
		else
			if bIsSecondRepresent and nHat == 1 then
				return true
			elseif not bIsSecondRepresent and nHat == 0 then
				return true
			end
		end

		return false
	end

	return true
end

function DataModel.GetFilterAllRoleAvatar()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

    DataModel.tFilter = nil
    DataModel.tFilter = {}
    local tAllList = {}
    if DataModel.nSelTitle == TITLE.COLLECTION then
        local tCollection = DataModel.tCollection
        for dwID, _ in pairs(tCollection) do
            local tInfo = Table_GetRoleAvatarInfo(dwID)
            if DataModel.IsMingjiaoForceAvatar(dwID) then
                if not DataModel.CanGetAvatar(tInfo.nHat) then
                    local nRelateID = tInfo.nRelateID
                    tInfo = Table_GetRoleAvatarInfo(nRelateID)
                end
            end
            if tInfo then
                table.insert(tAllList, tInfo)
            end
        end
    elseif DataModel.nSelTitle == TITLE.NORMAL then
        tAllList = DataModel.tAllAvatar
    end
    if not tAllList then
        return
    end

    local tRes = {}
    local nHaveOfFilter = 0
    DataModel.nHaveOfFilter = 0
    for _, tInfo in ipairs(tAllList) do
        local dwID = tInfo.dwID
        if DataModel.tDetail[dwID] then
            tInfo.bHave = true
        else
            tInfo.bHave = false
        end

        if DataModel.nSelTitle == TITLE.COLLECTION then
            tInfo.bCollect = true
        elseif DataModel.nSelTitle == TITLE.NORMAL then
            tInfo.bCollect = DataModel.IsAvatarInCollection(dwID)
        end

		local bSelfForceAvatar
		if tInfo.dwForceID == 0 then
			bSelfForceAvatar = true
		elseif tInfo.dwForceID == pPlayer.dwForceID then
			if pPlayer.dwForceID == MINGJIAO_FORCE_ID then
				bSelfForceAvatar = DataModel.CanGetAvatar(tInfo.nHat)
			else
				bSelfForceAvatar = true
			end
		end

		local nFilterHave = DataModel.nFilterHave
		local bFilterHave = false
		if nFilterHave == 0 then
			bFilterHave = true
		elseif nFilterHave == 1 then
			bFilterHave = tInfo.bHave
		elseif nFilterHave == 2 then
			bFilterHave = not tInfo.bHave
		end

		local bFilterGainWay = DataModel.IsFilteredGainWay(dwID)
		local bFilterSearch = DataModel.IsAvatarInSearchResult(tInfo)
		local bFilter = bFilterHave and bFilterGainWay and bFilterSearch

		if bFilter and (tInfo.bHave or (bSelfForceAvatar and tInfo.bShow)) then
			table.insert(tRes, tInfo)
            if tInfo.bHave then
                nHaveOfFilter = nHaveOfFilter + 1
            end
		end
    end

	local function fnSort(t1, t2)
        if t1.bHave and not t2.bHave then
            return true
        elseif not t1.bHave and t2.bHave then
            return false
        else
            if t1.bCollect and not t2.bCollect then
                return true
            elseif not t1.bCollect and t2.bCollect then
                return false
            else
                return t1.dwID > t2.dwID
            end
        end
    end
    table.sort(tRes, fnSort)

    DataModel.tFilter = tRes
    DataModel.nHaveOfFilter = nHaveOfFilter
    DataModel.UpdateMaxPage()
    -- return tRes
end

function DataModel.GetAllDecoration()
	if not DataModel.tAlDecorationList then
		DataModel.tAlDecorationList = Table_GetAllDesignationDecorationList()
	end
end

function DataModel.GetFilterHave(tInfo)
	local nFilterHave = DataModel.nFilterHave
	local bFilterHave = false
	if nFilterHave == 0 then
		bFilterHave = true
	elseif nFilterHave == 1 then
		bFilterHave = tInfo.bHave
	elseif nFilterHave == 2 then
		bFilterHave = not tInfo.bHave
	end
	return bFilterHave
end

function DataModel.GetFilterAllDecoration()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	DataModel.GetAllDecoration()
    DataModel.tFilter = nil
    DataModel.tFilter = {}
    local tAllList 		= DataModel.tAlDecorationList
    local tRes 			= {}
    local nHaveOfFilter = 0
    DataModel.nHaveOfFilter = 0
    for _, tInfo in ipairs(tAllList) do
        local dwID 			= tInfo.dwID
		tInfo.bHave 		= pPlayer.IsDesignationDecorationAcquired(dwID)
		local bFilterHave 	= DataModel.GetFilterHave(tInfo)

		local bFilterGainWay = DataModel.IsFilteredDesignationGainWay(tInfo)
		local bFilterSearch = DataModel.IsAvatarInSearchResult(tInfo)
		local bFilter = bFilterHave and bFilterGainWay and bFilterSearch
		if bFilter and (tInfo.bHave or tInfo.bShow) then
			table.insert(tRes, tInfo)
            if tInfo.bHave then
                nHaveOfFilter = nHaveOfFilter + 1
            end
		end
    end

	local function fnSort(t1, t2)
        if t1.bHave and not t2.bHave then
            return true
        elseif not t1.bHave and t2.bHave then
            return false
        else
            return t1.dwID > t2.dwID
        end
    end
    table.sort(tRes, fnSort)
	
   
    DataModel.tFilter = tRes
    DataModel.nHaveOfFilter = nHaveOfFilter
    DataModel.UpdateMaxPage()
end

function DataModel.IsAvatarInSearchResult(tInfo)
	local szSearchText = DataModel.szSearchText
	if not szSearchText or szSearchText == "" then
		return true
	end

	if not tInfo then
		return
	end

	local bMatch = false
	local tItemList = SplitString(tInfo.szLinkItem, "|")
	for k, v in pairs(tItemList) do
		local t = SplitString(v, ";")
		local dwItemType = tonumber(t[1])
		local dwItemIndex = tonumber(t[2])
		if dwItemType and dwItemType ~= 0 and dwItemIndex and dwItemIndex ~= 0 then
            local itemInfo = GetItemInfo(dwItemType, dwItemIndex)
            local szName
            if itemInfo then
                szName = ItemData.GetItemNameByItemInfo(itemInfo)
            end
            if not szSearchText or string.find(UIHelper.GBKToUTF8(szName), szSearchText) then -- StringMatchW(szName, szSearchText)
                bMatch = true
				break
            end
		end
	end
	return bMatch
end

function DataModel.IsFilteredItemGainWay(tInfo)
	local bFilter = false
	local tItemList = SplitString(tInfo.szLinkItem, "|")
	for k, v in pairs(tItemList) do
		local t = SplitString(v, ";")
		local dwItemType = tonumber(t[1])
		local dwItemIndex = tonumber(t[2])
		if dwItemType and dwItemType ~= 0 and dwItemIndex and dwItemIndex ~= 0 then
			local tSearchIndex = ItemSource_GetSearchIndexList(dwItemType, dwItemIndex)
			if tSearchIndex and tSearchIndex[DataModel.nFilterGainWay] then
				bFilter = true
				break
			end
		end
	end
	return bFilter
end

function DataModel.IsFilteredDesignationGainWay(tInfo)
	local nFilterGainWay = DataModel.nFilterGainWay
	if nFilterGainWay == 0 then
		return true
	end

	local bFilter = DataModel.IsFilteredItemGainWay(tInfo)
	return bFilter
end

function DataModel.IsFilteredGainWay(dwRoleAvatarID)
	local nFilterGainWay = DataModel.nFilterGainWay
	if nFilterGainWay == 0 then
		return true
	end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	if not dwRoleAvatarID then
		return
	end


	local tInfo = Table_GetRoleAvatarInfo(dwRoleAvatarID)
	if nFilterGainWay == SCHOOL_GAINWAY_TYPE then
		if dwRoleAvatarID == 0 or tInfo.dwForceID == pPlayer.dwForceID then
			return true
		end
	end
	return DataModel.IsFilteredItemGainWay(tInfo)
end

function DataModel.UpdateCollectionData()
	DataModel.bEnableCollect = false
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

	local dwPlayerID = pPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		return
	end

	if not pPlayer.HaveRemoteData(REMOTE_PREFER_ROLEAVATAR) then
		pPlayer.ApplyRemoteData(REMOTE_PREFER_ROLEAVATAR)
		return
	end

	local tCollection = {}
	-- local dwCount = pPlayer.GetRemoteSetSize(REMOTE_PREFER_ROLEAVATAR)
	-- for i = 1, dwCount do
	-- 	local dwRoleAvatarID = pPlayer.GetRemoteDWordArray(REMOTE_PREFER_ROLEAVATAR, i - 1)
	-- 	if dwRoleAvatarID then
	-- 		tCollection[dwRoleAvatarID] = true
	-- 	end
	-- end
    for i = PREFER_REMOTE_DATA_START, PREFER_REMOTE_DATA_END, PREFER_REMOTE_DATA_LEN do
		local dwRoleAvatarID = pPlayer.GetRemoteArrayUInt(REMOTE_PREFER_ROLEAVATAR, i, PREFER_REMOTE_DATA_LEN)
		if dwRoleAvatarID and dwRoleAvatarID ~= 0 then
			if dwRoleAvatarID == DEFAULT_AVATAR_ID then
                tCollection[0] = true
            else
                tCollection[dwRoleAvatarID] = true
            end
		end
	end

    DataModel.tCollection = tCollection
	DataModel.bEnableCollect = true
end

function DataModel.IsAvatarInCollection(dwRoleAvatarID)
	local tCollection = DataModel.tCollection or {}
    local tInfo = Table_GetRoleAvatarInfo(dwRoleAvatarID)
    if DataModel.IsMingjiaoForceAvatar(dwRoleAvatarID) then
        return tCollection[dwRoleAvatarID] or tCollection[tInfo.nRelateID]
    end
	return tCollection[dwRoleAvatarID]
end


function DataModel.IsLikeAvatarbFull()
    local nNum = GetTableCount(DataModel.tCollection)
    if nNum < MAX_COLLECTION_COUNT then
        return false
    else
        return true
    end
end

function DataModel.IsMingjiaoForceAvatar(dwRoleAvatarID)
    if not g_pClientPlayer then
        return
    end

    local dwForceID = g_pClientPlayer.dwForceID
    local tInfo = Table_GetRoleAvatarInfo(dwRoleAvatarID)
    if dwForceID == MINGJIAO_FORCE_ID and tInfo.nHat ~= -1 then
        return true
    end

    return false
end

---------------------挂饰秘鉴通用界面配置函数-----------------------

function DataModel.SetCurrentPage(dwCurrentPage)
    DataModel.nSelPage = dwCurrentPage
end

function DataModel.SetSelectType(dwPart)
    DataModel.nSelTitle = dwPart
    DataModel.EmptyAllFilter()
end

function DataModel.SetSearchText(szSearchText)
    DataModel.szSearchText = szSearchText
end

function DataModel.GetSearchText()
    return DataModel.szSearchText
end

function DataModel.GetCollectionProgressTips()
    local nTotalNum = GetTableCount(DataModel.tFilter)
	local nHaveNum = DataModel.nHaveOfFilter

	return nTotalNum, nHaveNum
end

function DataModel.GetCollectedNum()
    local nTotalNum = MAX_COLLECTION_COUNT
	local nHaveNum = GetTableCount(DataModel.tCollection)

	return nTotalNum, nHaveNum
end

function DataModel.GetCurPageInfo()
	return DataModel.nMaxPage, DataModel.nSelPage
end

function DataModel.EmptyAllFilter()
	DataModel.szSearchText = ""
    DataModel.nFilterHave    = 0
    DataModel.nFilterGainWay = 0
end

function DataModel.UpdateFilterList()
    if DataModel.nSelTitle  == TITLE.DESIGNATIONDECORATION then
        DataModel.GetFilterAllDecoration()
    else
        DataModel.GetFilterAllRoleAvatar()
    end
    
end
---------------------------------------- UI -----------------------------------------
function UICharacterAvatarPage:Init()
    self:BindMainPageIndex(AccessoryMainPageIndex.Avatar)
    self:BindDataModel(DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:InitView()

    UIHelper.SetSelected(self.TogCollectNav, DataModel.nSelTitle == TITLE.COLLECTION)
    UIHelper.SetSelected(self.TogHeadNav, DataModel.nSelTitle == TITLE.NORMAL)
    UIHelper.SetSelected(self.TogPersonalTitleDecorationNav, DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION)

    UIHelper.SetVisible(self.TogPersonalTitleDecorationNav, Const.EnableDesignationDecoration)

    -- self:InitFilter()
end

function UICharacterAvatarPage:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UICharacterAvatarPage:BindUIEvent()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, self.TogCollectNav)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, self.TogHeadNav)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, self.TogPersonalTitleDecorationNav)
    UIHelper.BindUIEvent(self.TogHeadNav, EventType.OnClick, function()
        self:SetNowCollectPage(false)
        Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, TITLE.NORMAL)
    end)

    UIHelper.BindUIEvent(self.TogCollectNav, EventType.OnClick, function()
        self:SetNowCollectPage(true)
        Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, TITLE.COLLECTION)
    end)

    UIHelper.BindUIEvent(self.TogPersonalTitleDecorationNav, EventType.OnClick, function()
        self:SetNowCollectPage(false)
        Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, TITLE.DESIGNATIONDECORATION)
    end)
end

function UICharacterAvatarPage:RegEvent()
    Event.Reg(self, "CURRENT_PLAYER_FORCE_CHANGED", function()
        DataModel.UpdateAvatarDetailInfo()
        if self:IsNowActivity() then
            self:InitView()
        end
    end)

    Event.Reg(self, "SYNC_MINI_AVATAR_DATA", function()
        DataModel.UpdateAvatarDetailInfo()
        if self:IsNowActivity() then
            self:InitView()
        end
    end)

    Event.Reg(self, "ACQUIRE_MINI_AVATAR", function(dwMiniAvatarID)
        DataModel.UpdateAvatarDetailInfo()
        if self:IsNowActivity() then
            self:InitView()
        end
    end)

    Event.Reg(self, "CHECK_CAP_ONPLAYER", function()
        DataModel.bCheckCap = true
        DataModel.UpdateAvatarDetailInfo()
        if self:IsNowActivity() then
            self:InitView()
        end
    end)

    Event.Reg(self, "ON_NEW_PROXY_SKILL_LIST_NOTIFY", function()

    end)

    Event.Reg(self, "REMOTE_PREFER_ROLEAVATTAR_EVENT", function()
        DataModel.UpdateCollectionData()
        if self:IsNowActivity() then
            self:InitView()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if not self.tbFilter or szKey ~= self.tbFilter.Key then
            return
        end

        local nFilterHave = tbInfo[1][1] - 1
        local nFilterGainWay = tbInfo[2][1] - 1

        DataModel.nFilterHave    = nFilterHave
	    DataModel.nFilterGainWay = tmpIndex2Search[nFilterGainWay]
        DataModel.UpdateFilterList()
        DataModel.SetCurrentPage(1)
        -- self:UpdateNum()
        -- self:UpdateMaxPage()
        -- self:UpdateCurrentPage()
        self:UpdateAvatarList()
        self:UpdateButtonInfo()
    end)

    Event.Reg(self, "DESIGNATION_DECORATION_ACQUIRED", function()
        self:UpdateAvatarList()
    end)
    Event.Reg(self, "SET_CURRENT_DESIGNATION", function()
        self:UpdateAvatarList()
    end)

end

function UICharacterAvatarPage:InitFilter() -- 已在UICharacterPendantPublicPage.lua中处理
    self.scriptFilterTip = UIHelper.GetBindScript(self.WidgetAnchorSuitAccessoryTips)
    self.scriptFilterTip:OnEnter(function(nFilterHave, nFilterGainWay)
        DataModel.nFilterHave    = nFilterHave
	    DataModel.nFilterGainWay = tmpIndex2Search[nFilterGainWay]
        if DataModel.nFilterHave ~= 0 or nFilterGainWay ~= 0 then
            UIHelper.SetVisible(self.ImgSift, false)
            UIHelper.SetVisible(self.ImgFiltered, true)
        else
            UIHelper.SetVisible(self.ImgSift, true)
            UIHelper.SetVisible(self.ImgFiltered, false)
        end
        DataModel.UpdateFilterList()
        self:UpdateNum()
        self:UpdateMaxPage()
        self:UpdateCurrentPage()
        self:UpdateAvatarList()
        UIHelper.SetSelected(self.TogSift, false)
    end)
    UIHelper.SetVisible(self.ImgSift, true)
    UIHelper.SetVisible(self.ImgFiltered, false)
end

function UICharacterAvatarPage:ReSetMiniAvatar(dwMiniAvatarID)
	local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

	if pPlayer.dwForceID ~= MINGJIAO_FORCE_ID then --只有明教需要重置头像
		return
	end

	dwMiniAvatarID = dwMiniAvatarID or pPlayer.dwMiniAvatarID

	local tLine = Table_GetRoleAvatarInfo(dwMiniAvatarID)
	local bInHat = pPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
	if tLine.nRelateID > 0 and ( (tLine.nHat == 0 and bInHat) or (tLine.nHat == 1 and not bInHat) ) then
		pPlayer.SetMiniAvatar(tLine.nRelateID)
	end

    -- local hBtn = Station.Lookup("Normal/Player/Btn_RoleChange")
	-- FireHelpEvent("OnCommontToSomeWhere", "AcquireMiniAvatar", hBtn) todo
end

function UICharacterAvatarPage:InitView()

    DataModel.UpdateFilterList()
    self:UpdateTitle()
    self:UpdateAvatarList()
end

function UICharacterAvatarPage:UpdateInfo()
    self:InitView()
end

function UICharacterAvatarPage:UpdateTitle()
    if DataModel.nSelTitle == TITLE.NORMAL then
        self:SetImgTitle("UIAtlas2_Character_Accessory_Img_Head_T")
    elseif DataModel.nSelTitle == TITLE.COLLECTION then
        self:SetImgTitle("UIAtlas2_Character_Accessory_Img_Liked_T")
    elseif DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION then
        self:SetImgTitle("UIAtlas2_Character_Accessory_Img_Decoration_T")
    end
end

function UICharacterAvatarPage:UpdateNum()
    if DataModel.nSelTitle == TITLE.NORMAL then

        -- local tAllList = DataModel.tAllAvatar
        -- local nMaxCount = 1
        -- for _, tInfo in ipairs(tAllList) do
        --     local dwID = tInfo.dwID
        --     if tInfo.bShow or DataModel.tDetail[dwID] then
        --         nMaxCount = nMaxCount + 1
        --     end
        -- end
        -- local nHaveCount = GetTableCount(DataModel.tDetail)
        local nHaveCount = DataModel.nHaveOfFilter
        local szHavetCount = "已拥有：" .. nHaveCount .. "/" .. GetTableCount(DataModel.tFilter)
        UIHelper.SetString(self.LabelHeadNumber, szHavetCount)
    elseif DataModel.nSelTitle == TITLE.COLLECTION then
        -- local tCollection = DataModel.tCollection or {}
        -- local nCollectCount = GetTableCount(tCollection)
        local nCollectCount = DataModel.nHaveOfFilter
        local szCollectCount = "收藏：" .. nCollectCount .. "/" .. GetTableCount(DataModel.tFilter)
        UIHelper.SetString(self.LabelHeadNumber, szCollectCount)
    end
end

function UICharacterAvatarPage:UpdateMaxPage()
    local tAllList = DataModel.tFilter
	local nMaxPage = 1
	local nLen = #tAllList
	if nLen > 0 then
		nMaxPage = math.floor((nLen - 1) / EACH_PAGE_MAX_COUNT) + 1
	end

    DataModel.nMaxPage = nMaxPage or 1
end

-- 弃用 已在UICharacterPendantPublicPage.lua中处理
function UICharacterAvatarPage:UpdateCurrentPage()
    local nPage = DataModel.nSelPage
    if nPage < 1 then
        nPage = 1
    elseif nPage > DataModel.nMaxPage then
        nPage = DataModel.nMaxPage
    end
    DataModel.nSelPage = nPage
    UIHelper.SetString(self.EditPaginate, tostring(DataModel.nSelPage))

    if DataModel.nMaxPage == 1 then
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Disable)
        return
    end

    if nPage == 1 then
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Normal)
    elseif nPage == DataModel.nMaxPage then
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Normal)
    end
end

function UICharacterAvatarPage:UpdateAvatarList()

    local tAllList = DataModel.tFilter
	local nLen = #tAllList
	if nLen > 0 then
        UIHelper.SetVisible(self.ScrollViewHeadList, true)
        self:ShowWidgetEmpty(false)
    else
        UIHelper.SetVisible(self.ScrollViewHeadList, false)
        self:ShowWidgetEmpty(true)
        if DataModel.nSelTitle == TITLE.NORMAL then
            self:SetLabelEmpty("暂无头像")
        elseif DataModel.nSelTitle == TITLE.COLLECTION then
            self:SetLabelEmpty("暂无收藏的头像")
        elseif DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION then
            self:SetLabelEmpty("暂无称号装饰")
        end
        return
	end

    local dwMaxNum = nLen
    local dwPage = DataModel.nSelPage
	local dwStart = (dwPage - 1) * EACH_PAGE_MAX_COUNT + 1
	local dwEnd = dwPage * EACH_PAGE_MAX_COUNT

    local cellType = CELL_TYPE.NORMAL

    if DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION then
        cellType = CELL_TYPE.DESIGNATIONDECORATION
    end

    self.tbScriptItemIcon = self.tbScriptItemIcon or {}
    self.tbScriptItemIcon[cellType] = self.tbScriptItemIcon[cellType] or {}

    for i, tScriptItems in ipairs(self.tbScriptItemIcon) do
        for _, scriptItem in ipairs(tScriptItems) do
            UIHelper.SetVisible(scriptItem._rootNode, false)
        end
    end
    local fnLoadCell = function(nIndex, nCellIndex)
        if nIndex > dwMaxNum or nIndex > dwEnd then
            return
        end

        local tbInfo = tAllList[nIndex]
        tbInfo.nSubTitleType = DataModel.nSelTitle
        local bDesignationTag = DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION
        local scriptItem = self.tbScriptItemIcon[cellType][nCellIndex]
        if not scriptItem then
            if bDesignationTag then
                scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetTitleDecorationItem, self.ScrollViewHeadList)
            else
                scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetHeadListItem, self.ScrollViewHeadList)
            end
            table.insert(self.tbScriptItemIcon[cellType], scriptItem)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupHeadList, scriptItem.TogHead)
            UIHelper.SetSwallowTouches(scriptItem.TogHead, false)
            scriptItem:OnEnter()
        end
        
        UIHelper.SetVisible(scriptItem._rootNode, true)
        if bDesignationTag then
            scriptItem:SetGottenState(tbInfo.bHave)
            scriptItem:SetEquipmentState(g_pClientPlayer.GetDesignationDecoration()  == tbInfo.dwID)
        else
            if DataModel.tDetail[tbInfo.dwID] then
                scriptItem:SetGottenState(true)
            else
                scriptItem:SetGottenState(false)
            end
            scriptItem:SetLikeState(tbInfo.bCollect)
            scriptItem:SetEquipmentState(g_pClientPlayer.dwMiniAvatarID == tbInfo.dwID)
        end
       
        local bIsNew = RedpointHelper.Avatar_IsNew(tbInfo.dwID)
        if bIsNew then
            scriptItem:SetNewState(true)
        else
            scriptItem:SetNewState(false)
        end

        scriptItem:SetClickCallback(function(dwID, bIsDesignation)
            if RedpointHelper.Avatar_IsNew(dwID) then
                RedpointHelper.Avatar_SetNew(dwID, false)
                scriptItem:SetNewState(false)
            end
            local tAvaInfo = nil
            if bIsDesignation then
                tAvaInfo = Table_GetDesignationDecorationInfo(dwID)
            else
                tAvaInfo = Table_GetRoleAvatarInfo(dwID)
            end
            local tItemList = SplitString(tAvaInfo.szLinkItem, "|")
            local scriptTmp
            if #tItemList < 1 then
                if not self.scriptItemTip then
                    self.scriptItemTip = self:GetItemTips()
                end
                self.scriptItemTip:OnInitRoleAvatarTip(dwID, bIsDesignation)
                scriptTmp = self.scriptItemTip
            else
                if self.scriptItemTip2 then
                    UIHelper.SetVisible(self.scriptItemTip2._rootNode, false)
                end
                local tItem = SplitString(tItemList[1], ";")
                if not self.scriptItemTip then
                    self.scriptItemTip = self:GetItemTips()
                end
                -- self.scriptItemTip1:OnInitWithTabID(tonumber(tItem[1]), tonumber(tItem[2]))
                self.scriptItemTip:OnInitSpecialRoleAvatarTip(dwID, tonumber(tItem[1]), tonumber(tItem[2]), bIsDesignation)
                scriptTmp = self.scriptItemTip
            end
            local tbBtnState = {}
            if not bIsDesignation then
                if DataModel.IsAvatarInCollection(dwID) then
                    table.insert(tbBtnState, {szName = "取消收藏", OnClick = function ()
                        local nID = tAvaInfo.dwID
                        if tAvaInfo.dwID == 0 then
                            nID = DEFAULT_AVATAR_ID
                        end
                        RemoteCallToServer("On_HeadEmotion_UnstarRoleavatar", nID)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end})
                else
                    table.insert(tbBtnState, {szName = "加入收藏", OnClick = function ()
                        if DataModel.IsLikeAvatarbFull() then
                            return OutputMessage("MSG_ANNOUNCE_NORMAL",  "请先取消其他头像的收藏")
                        end
                        local nID = tAvaInfo.dwID
                        if tAvaInfo.dwID == 0 then
                            nID = DEFAULT_AVATAR_ID
                        end
                        RemoteCallToServer("On_HeadEmotion_StarRoleavatar", nID)
                        Event.Dispatch(EventType.HideAllHoverTips)
                    end})
                end
                if DataModel.tDetail[tAvaInfo.dwID] and g_pClientPlayer.dwMiniAvatarID ~= tAvaInfo.dwID then
                    table.insert(tbBtnState, {szName = "使用", OnClick = function ()
                        Event.Dispatch(EventType.HideAllHoverTips)
                        local eRetCode = g_pClientPlayer.SetMiniAvatar(tAvaInfo.dwID)
                        if eRetCode then
                            TipsHelper.ShowNormalTip(g_tStrings.STR_CHANGE_MINI_AVATAR_SUCCESS)
                            Timer.AddFrame(self, 5, function()
                                self:UpdateAvatarList()
                            end)
                        end
                    end})
                end
            else
                if tAvaInfo.bHave then
                    if g_pClientPlayer.GetDesignationDecoration() == tAvaInfo.dwID then
                        table.insert(tbBtnState, {szName = "卸下", OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            g_pClientPlayer.EquipDesignationDecoration(0)
                        end})
                    else
                        table.insert(tbBtnState, {szName = "穿戴", OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            g_pClientPlayer.EquipDesignationDecoration(tAvaInfo.dwID)
                        end})
                    end
                end
            end
            scriptTmp:SetBtnState(tbBtnState)
        end)
        scriptItem:UpdateInfo(tbInfo.dwID, bDesignationTag)
    end

    local fnLoadFinish = function()
        Timer.DelTimer(self, self.nLoadTimerID)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHeadList)
        UIHelper.ScrollViewSetupArrow(self.ScrollViewHeadList, self.WidgetArrow)
        self:ClearSelect()
    end

    Timer.DelTimer(self, self.nLoadTimerID)
    local nIndex = dwStart
    local nCellIndex = 1
    self.nLoadTimerID = Timer.AddFrameCycle(self, 1, function()
        if nIndex > dwMaxNum or nIndex > dwEnd then
            fnLoadFinish()
        else
            local nOneFrameCount = 4
            for i = 1, nOneFrameCount do
                fnLoadCell(nIndex, nCellIndex)
                nIndex = nIndex + 1
                nCellIndex = nCellIndex + 1
            end
        end
    end)
end

function UICharacterAvatarPage:ClearSelect()
    local cellType = (DataModel.nSelTitle == TITLE.DESIGNATIONDECORATION) and CELL_TYPE.DESIGNATIONDECORATION or CELL_TYPE.NORMAL
    if self.tbScriptItemIcon and self.tbScriptItemIcon[cellType] then
        for _, scriptItem in ipairs(self.tbScriptItemIcon[cellType]) do
            scriptItem:SetSelected(false)
        end
    end
end


return UICharacterAvatarPage