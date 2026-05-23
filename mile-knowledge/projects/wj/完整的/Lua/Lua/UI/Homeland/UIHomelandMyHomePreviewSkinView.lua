-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePreviewSkinView
-- Date: 2023-04-10 11:26:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePreviewSkinView = class("UIHomelandMyHomePreviewSkinView")

local DEFAULT_SKINID = 0
local CHANGE_SKIN_CD = 20000
local BIG_SKIN_PATH = "mui/Resource/JYMap/SeparateMapSkinAll"

function UIHomelandMyHomePreviewSkinView:OnEnter(nMapID, nCopyIndex, dwSkinID)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.dwSkinID = dwSkinID

	self.nCurIndex = 1

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	if not self.nMapID and not self.nCopyIndex then
    	local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
		self.nMapID = dwMapID
    	self.nCopyIndex = nCopyIndex
		GetHomelandMgr().ApplyPrivateHomeInfo(dwMapID, nCopyIndex)
		return
	elseif not self.dwSkinID then
		local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
		if tPrivateInfo then
			self.dwSkinID = tPrivateInfo.dwSkinID
		end
	end

	self:InitView()
end

function UIHomelandMyHomePreviewSkinView:OnExit()
    self.bInit = false
end

function UIHomelandMyHomePreviewSkinView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
		UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnVisit, EventType.OnClick, function ()
        local nMapID = self.nMapID
        local dwSkinID = self.tbInfo.dwSkinID

        local function _goPrivateLand()
            HomelandData.GoPrivateLand(nMapID, nil, dwSkinID, 2)
            UIMgr.Close(VIEW_ID.PanelPreviewHome)
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
		-- TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
        UIMgr.Close(VIEW_ID.PanelPreviewHome)
        UIMgr.Close(VIEW_ID.PanelHome)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
        local dwGoodsID = self.tbInfo.dwGoodsID
        Event.Dispatch("EVENT_LINK_NOTIFY", "Exterior/4/" .. dwGoodsID)
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function ()
		local uSkinID = self.tbStateInfo.uSkinID
		local dwMapID, dwSkinID = GetHomelandMgr().ConvertMapSkinID(uSkinID)

		local function _changeMapSkin()
			HomelandBuildData.nLastChangeSkinTime = GetTickCount()
			GetHomelandMgr().ApplyChangeMapSkin(uSkinID)
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PRIVATEHOUSE_CHANGESKIN)
			UIMgr.Close(VIEW_ID.PanelPreviewHome)
			UIMgr.Close(VIEW_ID.PanelHome)
			UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(dwMapID, dwSkinID, _changeMapSkin) then
            _changeMapSkin()
        end
    end)
end

function UIHomelandMyHomePreviewSkinView:RegEvent()
	Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function (nResultType, ...)
		if nResultType == HOMELAND_RESULT_CODE.APPLY_PRIVATE_HOME_INFO_RESPOND then --申请个人家园信息
			local nMapID, nCopyIndex = ...
			if nMapID == self.nMapID and nCopyIndex == self.nCopyIndex then
				local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(nMapID, nCopyIndex)
				if not tPrivateInfo then
					return
				end

				self.dwSkinID = tPrivateInfo.dwSkinID
				self:InitView()
			end
		end
    end)

	Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        if nResultType == HOMELAND_RESULT_CODE.CHANGE_SKIN_SUCCEED then --换肤成功
            UIMgr.Close(self)
        end
    end)
end

function UIHomelandMyHomePreviewSkinView:InitView()
	self:UpdateInfo()
end

function UIHomelandMyHomePreviewSkinView:SortSkinList(tSkinUIInfo)
	local function fnCmp(a, b)
		local tbStateA = self.tSkinInfo[a.dwSkinID]
		local tbStateB = self.tSkinInfo[b.dwSkinID]
		if tbStateA and tbStateB then
            return a.dwSkinID > b.dwSkinID
		elseif tbStateA then
			return true
		elseif tbStateB then
			return false
		else
			if a.dwPriority > b.dwPriority then
				return true
			elseif a.dwPriority < b.dwPriority then
				return false
			else
				return a.dwSkinID > b.dwSkinID
			end
		end
	end

	table.sort(tSkinUIInfo, fnCmp)
	self.tSkinUIInfo = tSkinUIInfo
end

function UIHomelandMyHomePreviewSkinView:UpdateInfo()
    local tRetSkin = GetHomelandMgr().GetAllPrivateHomeSkin()
	self.tSkinInfo = {}
	local uSkinID = GetHomelandMgr().GetMapSkinID(self.nMapID, DEFAULT_SKINID) --默认皮肤
	self.tSkinInfo[DEFAULT_SKINID] = {uSkinID = uSkinID}
	if self.dwSkinID == DEFAULT_SKINID then
		self.tSkinInfo[DEFAULT_SKINID].bUsing = true
	end

	for k, v in ipairs(tRetSkin) do
		local nMapID, dwSkinID = GetHomelandMgr().ConvertMapSkinID(v)
		if nMapID == self.nMapID then
			self.tSkinInfo[dwSkinID] = {uSkinID = v}
			if dwSkinID == self.dwSkinID then
				self.tSkinInfo[dwSkinID].bUsing = true
			end
		end
	end

	if not self.tSkinUIInfo then
		local tSkinUIInfo = Table_GetPrivateHomeSkinList(self.nMapID)
		self:SortSkinList(tSkinUIInfo)
	end
	UIHelper.RemoveAllChildren(self.ScrollViewSkin)

	local nCount = #self.tSkinUIInfo
	self.tbCells = self.tbCells or {}
	for i = 1, nCount do
		local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetPreviewHomeCell2, self.ScrollViewSkin)
		self.tbCells[i] = scriptCell
		local tSkinUI = self.tSkinUIInfo[i]
        scriptCell:OnEnter(self.nMapID, self.nCopyIndex, tSkinUI, self.tSkinInfo[tSkinUI.dwSkinID])
		UIHelper.SetToggleGroupIndex(scriptCell.ToggleSkin, ToggleGroupIndex.HomelandOrderItem)
		UIHelper.BindUIEvent(scriptCell.ToggleSkin, EventType.OnSelectChanged, function (_, bSelected)
			if bSelected then
				self.nCurIndex = i
				self:UpdateCurSelectedInfo()
				self:DownloadCheck(tSkinUI)
			end
		end)
	end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkin)
	self:UpdateCurSelectedInfo()
end


function UIHomelandMyHomePreviewSkinView:UpdateCurSelectedInfo()
	if not self.tSkinUIInfo then
		local tSkinUIInfo = Table_GetPrivateHomeSkinList(self.nMapID)
		self:SortSkinList(tSkinUIInfo)
	end

    local tSkinUIInfo = self.tSkinUIInfo
	self.tbInfo = tSkinUIInfo[self.nCurIndex]
	self.tbStateInfo = self.tSkinInfo[self.tbInfo.dwSkinID]
	local szBigPath = BIG_SKIN_PATH.."/"..self.tbInfo.szImgName..".png"
	UIHelper.SetTexture(self.ImgPreviewHome, szBigPath)

	local szName = UIHelper.GBKToUTF8(self.tbInfo.szSkinName)
	UIHelper.SetSpriteFrame(self.ImgTilteBg, HomelandSkinNameImg[szName], false)

	if self.tbStateInfo then
        UIHelper.SetVisible(self.BtnVisit, true)
        UIHelper.SetVisible(self.BtnBuy, false)

        local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
        UIHelper.SetVisible(self.BtnChange, not self.tbStateInfo.bUsing)

		local nThisTime = GetTickCount() - HomelandBuildData.nLastChangeSkinTime
		if dwMapID == self.nMapID and nCopyIndex == self.nCopyIndex and nThisTime > CHANGE_SKIN_CD then
			UIHelper.SetButtonState(self.BtnChange, BTN_STATE.Normal)
		else
			if nThisTime < CHANGE_SKIN_CD then
				self.nCheckChangeSkinTimerID = Timer.AddCycle(self, 0.5, function()
					local nThisTime = GetTickCount() - HomelandBuildData.nLastChangeSkinTime
					if nThisTime < CHANGE_SKIN_CD then
						local m_nCDTime = math.modf((CHANGE_SKIN_CD - nThisTime) / 1000)
						UIHelper.SetString(self.LabelChange, string.format("更换(%d秒)", m_nCDTime))
					else
						UIHelper.SetString(self.LabelChange, string.format("更换"))
					end
					if nThisTime > CHANGE_SKIN_CD then
						self:UpdateCurSelectedInfo()
						Timer.DelTimer(self, self.nCheckChangeSkinTimerID)
						self.nCheckChangeSkinTimerID = nil
					end
				end)
			end
			UIHelper.SetButtonState(self.BtnChange, BTN_STATE.Disable, function()
				local nThisTime = GetTickCount() - HomelandBuildData.nLastChangeSkinTime
				if nThisTime < CHANGE_SKIN_CD then
					local m_nCDTime = math.modf((CHANGE_SKIN_CD - nThisTime) / 1000)
					TipsHelper.ShowNormalTip(string.format("更换皮肤冷却中，剩余%d秒", m_nCDTime))
				else
					TipsHelper.ShowNormalTip("请先前往私邸宅园")
				end
			end)
		end
    else
        UIHelper.SetVisible(self.BtnVisit, true)
        UIHelper.SetVisible(self.BtnBuy, self.tbInfo.dwGoodsID and self.tbInfo.dwGoodsID > 0 and CoinShop_RewardsCanBuy(self.tbInfo.dwGoodsID))
        UIHelper.SetVisible(self.BtnChange, false)
    end

	UIHelper.LayoutDoLayout(self.WidgetBotton)

	for nIndex, scriptCell in ipairs(self.tbCells) do
		scriptCell:SetSelected(nIndex == self.nCurIndex)
	end

	UIHelper.SetRichText(self.LabelPage, string.format("<color=#D7F6FF>%d</c><color=#aed9e0>/%d</color>", self.nCurIndex, #self.tbCells))
end

function UIHomelandMyHomePreviewSkinView:DownloadCheck(tSkinUI)
	local nSkinMapID = tSkinUI and tSkinUI.dwSkinID and MapHelper.GetHomelandSkinResMapID(self.nMapID, tSkinUI.dwSkinID)
	if nSkinMapID then
		local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
		local nPackID = PakDownloadMgr.GetMapResPackID(nSkinMapID)
		scriptDownload:OnInitWithPackID(nPackID)
		UIHelper.SetVisible(self.WidgetDownload, true)
	else
		UIHelper.SetVisible(self.WidgetDownload, false)
	end
end

return UIHomelandMyHomePreviewSkinView