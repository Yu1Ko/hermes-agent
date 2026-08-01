-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildZoneUnlockView
-- Date: 2023-05-16 17:24:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildZoneUnlockView = class("UIHomelandBuildZoneUnlockView")
local DataModel = {}

function DataModel.Init(tConditions)
	DataModel.nMaxIndex = 0
	local nMapID, nCopyIndex, nLandIndex = DataModel.GetMapInfo()
	DataModel.nCurCopyIndex = nCopyIndex
	DataModel.nCurMapID = nMapID
	DataModel.nCurLandIndex = nLandIndex
	DataModel.tUnLockState = {}
	DataModel.tDemolishState = {}
	DataModel.tGrassState = {}
	DataModel.nUnlockSubLand = 0
	DataModel.uDemolishSubLand = 0
	DataModel.uGrass = 0
	DataModel.nNowCheck = 0
	DataModel.tConditions = tConditions
end

function DataModel.UnInit()
	DataModel.nMaxIndex = 0
	DataModel.nCurCopyIndex = 0
	DataModel.nCurMapID = 0
	DataModel.nCurLandIndex = 0
	DataModel.tUnLockState = nil
	DataModel.tDemolishState = nil
	DataModel.tGrassState = nil
	DataModel.nUnlockSubLand = 0
	DataModel.uDemolishSubLand = 0
	DataModel.uGrass = 0
	DataModel.nNowCheck = 0
	DataModel.tConditions = nil
end

function DataModel.GetMapInfo()
    local scene = GetClientScene()
    local nLandIndex = GetHomelandMgr().GetNowLandIndex()
	return scene.dwMapID, scene.nCopyIndex, nLandIndex
end

function DataModel.Update()
	local pHLMgr = GetHomelandMgr()
	if not pHLMgr then
		return
	end
	local tInfo = nil
	tInfo = pHLMgr.GetHLLandInfo(DataModel.nCurLandIndex)
	if not tInfo then
		return
	end
	local scene = GetClientScene()
	local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex
	DataModel.nUnlockSubLand = tInfo.uUnlockSubLand
	DataModel.uDemolishSubLand = tInfo.uDemolishSubLand
    DataModel.uGrass = HomelandEventHandler.GetGrass()
	DataModel.nMaxIndex = pHLMgr.GetMaxSubLandIndex(dwCurMapID, DataModel.nCurLandIndex)
	for i = 1, DataModel.nMaxIndex do
		DataModel.tUnLockState[i] = GetNumberBit(DataModel.nUnlockSubLand, i)
		DataModel.tDemolishState[i] = GetNumberBit(DataModel.uDemolishSubLand, i)
		DataModel.tGrassState[i] = GetNumberBit(DataModel.uGrass, i)
	end
end

function DataModel.UpdateCondition()
	local scene = GetClientScene()
	local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex
	local tConditions = GDAPI_Homeland_UnlockAreaCond(dwCurMapID)

	DataModel.tConditions = tConditions
end

function UIHomelandBuildZoneUnlockView:OnEnter()
    if not self.bInit then
		DataModel.Init()
		self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end


    -- RemoteCallToServer("On_HomeLand_PSubLandRequire", dwCurMapID)
    --申请解锁数据 用于解锁界面
	GetHomelandMgr().ApplyLandInfo(DataModel.GetMapInfo())
	DataModel.Update()
	DataModel.UpdateCondition()
	self:UpdateInfo()
end

function UIHomelandBuildZoneUnlockView:OnExit()
    self.bInit = false
    DataModel.UnInit()
end

function UIHomelandBuildZoneUnlockView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBg, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUnlock, EventType.OnClick, function ()
        local tbAreaInfo = Table_GetPrivateHomeArea(DataModel.nCurMapID, DataModel.nCurLandIndex, DataModel.nCurZoneIndex)
        if not tbAreaInfo then
            return
        end

        local fnUnlock = function ()
            local pHLMgr = GetHomelandMgr()
            if not pHLMgr then
                return
            end
            local nEventID = 2
            local nLandID = DataModel.nCurLandIndex
			local nSubLand = DataModel.nCurZoneIndex
            pHLMgr.SendCustomEvent(nEventID, nLandID, nSubLand)
        end

        if tbAreaInfo["nMoney"] == 0 or GDAPI_Homeland_FreeUnlockArea() then
            fnUnlock()
        else
			if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
				return
			end
            local szMoneyText = UIHelper.GetFundText(tbAreaInfo["nMoney"], 26, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin")
            local szTip = string.format(g_tStrings.STR_PRIVATE_HOME_AREA_UNLOCK, szMoneyText, DataModel.nCurZoneIndex)
            UIHelper.ShowConfirm(szTip, fnUnlock, nil, true)
        end
    end)

	UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function ()
        local tAllLinkInfo = Table_GetCareerGuideAllLink(2498)
		if #tAllLinkInfo > 0 then
			local tbTravel = tAllLinkInfo[1]
			MapMgr.SetTracePoint("何千千", tbTravel.dwMapID, {tbTravel.fX, tbTravel.fY, tbTravel.fZ})
			UIMgr.Open(VIEW_ID.PanelMiddleMap, tbTravel.dwMapID, 0)
		end
    end)
end

function UIHomelandBuildZoneUnlockView:RegEvent()
    Event.Reg(self, "Home_OnGetPSubLandCons", function(tConditions, dwMapID)
        DataModel.Init(tConditions)
        DataModel.Update()
        self:UpdateInfo()
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO or nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then  --申请某块地详情
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if DataModel.nCurMapID == dwMapID and DataModel.nCurCopyIndex == nCopyIndex and DataModel.nCurLandIndex == nLandIndex then
				DataModel.Update()
				self:UpdateInfo()
			end
		elseif nRetCode == HOMELAND_RESULT_CODE.SET_SUB_LAND_UNLOCK_SUCCEED then
			local pHLMgr = GetHomelandMgr()
			if not pHLMgr then
				return
			end
			pHLMgr.ApplyHLLandInfo(DataModel.nCurLandIndex)
			-- View.UnLockSuccess()
		end
    end)
end

function UIHomelandBuildZoneUnlockView:UpdateInfo()
    self.tbCells = self.tbCells or {}

    UIHelper.HideAllChildren(self.ScrollViewZoneList)

    local nDefaultIndex
    for i = 1, DataModel.nMaxIndex do
        local bLocked = not DataModel.tUnLockState[i]
        local cell = self.tbCells[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetZoneUnlockCell, self.ScrollViewZoneList)
            self.tbCells[i] = cell
            UIHelper.ToggleGroupAddToggle(self.TogGroupCell, cell.TogZoneListCell)
        end
        UIHelper.SetVisible(cell._rootNode, bLocked)
        if bLocked then
            nDefaultIndex = nDefaultIndex or i
        end

        local tAreaInfo = Table_GetPrivateHomeArea(DataModel.nCurMapID, DataModel.nCurLandIndex, i)
        cell:OnEnter(i, tAreaInfo, function ()
            self:SetSelectedZone(i)
        end)
	end

    if nDefaultIndex then
        self:SetSelectedZone(nDefaultIndex)
		UIHelper.SetVisible(self.WidgetAnchorRight, true)
		UIHelper.SetVisible(self.WidgetEmpty, false)
	else
		UIHelper.SetVisible(self.WidgetAnchorRight, false)
		UIHelper.SetVisible(self.WidgetEmpty, true)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewZoneList)
    UIHelper.ScrollToTop(self.ScrollViewZoneList, 0)
end

function UIHomelandBuildZoneUnlockView:SetSelectedZone(nCurZoneIndex)
    DataModel.nCurZoneIndex = nCurZoneIndex

    UIHelper.SetToggleGroupSelected(self.TogGroupCell, nCurZoneIndex - 1)

	local tAreaInfo = Table_GetPrivateHomeArea(DataModel.nCurMapID, DataModel.nCurLandIndex, nCurZoneIndex)

    local pHLMgr = GetHomelandMgr()
	if not pHLMgr then
		return
	end

    local szText = ""
	local tPrivateLandInfo = pHLMgr.GetLandInfo(DataModel.nCurMapID, DataModel.nCurCopyIndex, DataModel.nCurLandIndex)
	local nLessCount = 0
	local pPlayer = GetClientPlayer()
	local nRecord = pPlayer.GetHomelandRecord()
	if nRecord >= tAreaInfo["nLockScore"] then
		szText = szText .. GetFormatText(FormatString(g_tStrings.STR_PRIVATEHOUSE_UNLOCK_SCORE, nRecord,tAreaInfo["nLockScore"]), nil, 90,227,162)
	else
		nLessCount = nLessCount + 1
		szText = szText .. GetFormatText(FormatString(g_tStrings.STR_PRIVATEHOUSE_UNLOCK_SCORE, nRecord,tAreaInfo["nLockScore"]), nil, 196,61,61)
	end

	local bShowMoney = true
	if tAreaInfo["nMoney"] == 0 or GDAPI_Homeland_FreeUnlockArea() then
		bShowMoney = false
	end

	if bShowMoney then
		local tbMyMoney = ItemData.GetMoney()
		local nMyMoney = UIHelper.BullionGoldSilverAndCopperToMoney(tbMyMoney.nBullion, tbMyMoney.nGold, tbMyMoney.nSilver, tbMyMoney.nCopper)
		local szMoney = UIHelper.GetFundText(tAreaInfo["nMoney"], 26, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin")
		if tAreaInfo["nMoney"] * 10000 > nMyMoney then
			szText = szText .. string.format("<color=#FF7676>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..szMoney)
			nLessCount = nLessCount + 1
		else
			szText = szText .. string.format("<color=#5AE3A2>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..szMoney)
		end
	else
		szText = szText .. string.format("<color=#5AE3A2>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..g_tStrings.STR_MENTOR_TRANSFORM)
	end

	UIHelper.SetVisible(self.WidgetTrace, false)

    --消耗
	local tConditions = DataModel.tConditions
	if tConditions then
		local tCons = tConditions[DataModel.nCurLandIndex][nCurZoneIndex]
		if tCons then
			for i, tCon in ipairs(tCons) do
				if tCon.bCan then
					szText = szText .. GetFormatText(FormatString(g_tStrings.tActivation.COLOR_CONDITION,i)..g_tStrings.STR_HOMELAND_UNLOCK_CONDITION[tCon.nStrIndex].."\n",nil,90,227,162)
				else
					UIHelper.SetVisible(self.WidgetTrace, true)
					nLessCount = nLessCount + 1
					szText = szText .. GetFormatText(FormatString(g_tStrings.tActivation.COLOR_CONDITION,i)..g_tStrings.STR_HOMELAND_UNLOCK_CONDITION[tCon.nStrIndex].."\n",nil,196,61,61)
				end
			end
		end
	end

    UIHelper.SetRichText(self.RichTextUnlockCondition, szText)
    UIHelper.SetString(self.LabelZone, UIHelper.GBKToUTF8(tAreaInfo.szAreaName))
    UIHelper.SetString(self.LabelSquare, string.format("面积：%d平", tAreaInfo.nArea))

    if nLessCount > 0 then
        UIHelper.SetButtonState(self.BtnUnlock, BTN_STATE.Disable, "解锁条件未达成")
    else
        UIHelper.SetButtonState(self.BtnUnlock, BTN_STATE.Normal)
    end
end


return UIHomelandBuildZoneUnlockView