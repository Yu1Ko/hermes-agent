-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildZoneListView
-- Date: 2023-05-15 11:04:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildZoneListView = class("UIHomelandBuildZoneListView")

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

function UIHomelandBuildZoneListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local scene = GetClientScene()
    local dwCurMapID, nCurCopyIndex = scene.dwMapID, scene.nCopyIndex
    --申请解锁数据 用于解锁界面
    RemoteCallToServer("On_HomeLand_PSubLandRequire", dwCurMapID)

    DataModel.Init({})
    DataModel.Update()
    self:UpdateInfo()
end

function UIHomelandBuildZoneListView:OnExit()
    self.bInit = false
    for i = 1, DataModel.nMaxIndex do   -- 先都清除一波
        rlcmd(("homeland -play subland sfx %d 0"):format(i - 1))
    end
    DataModel.UnInit()
end

function UIHomelandBuildZoneListView:BindUIEvent()
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

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        local function DoConfirm()
            for i = 1, DataModel.nMaxIndex do   -- 先都清除一波
                rlcmd(("homeland -play subland sfx %d 0"):format(i - 1))
            end
            local nNewDemolish, nNewGrass = self:GetNewDemolishAndGrassSubLand()
            if nNewDemolish ~= DataModel.uDemolishSubLand or nNewGrass ~= DataModel.uGrass then
                if nNewGrass ~= DataModel.uGrass then
                    HomelandEventHandler.SetGrass(nNewGrass)
                end

                if nNewDemolish ~= DataModel.uDemolishSubLand then
                    HLBOp_Save.DoDemolish(nNewDemolish)
                else
                    HLBOp_Exit.DoExit()
                end
            end

            UIMgr.Close(self)
        end

        self:ShowConfirmCheck(DoConfirm)
    end)

    UIHelper.BindUIEvent(self.TogLandscape, EventType.OnClick, function ()
        self:UpdateToggleChange()
    end)

    UIHelper.BindUIEvent(self.TogLawn, EventType.OnClick, function ()
        local bDemolish, bNewGrass = UIHelper.GetSelected(self.TogLandscape), UIHelper.GetSelected(self.TogLawn)
        if not bDemolish then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_NO_DEMOLISH_GRASS)
            UIHelper.SetSelected(self.TogLawn, not bNewGrass)
            return
        end

        self:UpdateToggleChange()
    end)
end

function UIHomelandBuildZoneListView:RegEvent()
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

function UIHomelandBuildZoneListView:UpdateInfo()
    self.tbCells = self.tbCells or {}
    for i = 1, DataModel.nMaxIndex do
        local cell = self.tbCells[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetZoneListCell, self.ScrollViewZoneList)
            self.tbCells[i] = cell
            UIHelper.ToggleGroupAddToggle(self.TogGroupCell, cell.TogZoneListCell)
        end

        local tAreaInfo = Table_GetPrivateHomeArea(DataModel.nCurMapID, DataModel.nCurLandIndex, i)
        cell:OnEnter(i, tAreaInfo,
                    not not DataModel.tUnLockState[i],
                    not not DataModel.tDemolishState[i],
                    not DataModel.tGrassState[i], function ()
            self:SetSelectedZone(i)
            self:UpdateToggleChange()
        end)
	end
    self:SetSelectedZone(1, true)
    self:UpdateToggleChange()
    UIHelper.ScrollViewDoLayout(self.ScrollViewZoneList)
    UIHelper.ScrollToTop(self.ScrollViewZoneList, 0)
end

function UIHomelandBuildZoneListView:SetSelectedZone(nCurZoneIndex, bFirstOpen)
    DataModel.nCurZoneIndex = nCurZoneIndex
    if DataModel.nCurZoneIndex and DataModel.nCurZoneIndex == nCurZoneIndex then
        -- UIHelper.SetSelected(self.TogLandscape, DataModel.tDemolishState[nCurZoneIndex])
        UIHelper.SetSelected(self.TogLandscape, true)
        UIHelper.SetSelected(self.TogLawn, not DataModel.tGrassState[nCurZoneIndex])
        self:ClearToggleChange()
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupCell, nCurZoneIndex - 1)

	-- local tAreaInfo = Table_GetPrivateHomeArea(DataModel.nCurMapID, DataModel.nCurLandIndex, nCurZoneIndex)
    local bLocked = not DataModel.tUnLockState[nCurZoneIndex]

    UIHelper.SetVisible(self.LayoutOperTogs, not bLocked)
    UIHelper.SetVisible(self.WidgetLockedNotice, bLocked)

    UIHelper.SetVisible(self.BtnUnlock, false)
    UIHelper.SetVisible(self.BtnConfirm, not bLocked)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    if bFirstOpen then
        return
    end

    for i = 1, DataModel.nMaxIndex do   -- 先都清除一波
        rlcmd(("homeland -play subland sfx %d 0"):format(i - 1))
    end

    if DataModel.nCurZoneIndex ~= -1 then
        rlcmd(("homeland -play subland sfx %d 0"):format(DataModel.nCurZoneIndex - 1))
    end
    --表现聚焦子地功能
    rlcmd(("homeland -focus %d 2 -90 1.0"):format(DataModel.nCurZoneIndex - 1))
    rlcmd(("homeland -play subland sfx %d 1"):format(DataModel.nCurZoneIndex - 1))

    -- UIHelper.WidgetFoceDoAlign(self)
end

function UIHomelandBuildZoneListView:UpdateToggleChange()
    local bNewDemolish, bNewGrass = UIHelper.GetSelected(self.TogLandscape), UIHelper.GetSelected(self.TogLawn)
    local cell = self.tbCells[DataModel.nCurZoneIndex]
    if not bNewDemolish then
        UIHelper.SetSelected(self.TogLawn, false)
        bNewGrass = false
    end
    if not cell then
        return
    end

    cell:SetChange(bNewDemolish, bNewGrass)

    local nNewDemolish, nNewGrass = self:GetNewDemolishAndGrassSubLand()
    -- LOG.TABLE({
    --     nNewDemolish,
    --     DataModel.uDemolishSubLand,
    --     nNewGrass,
    --     DataModel.uGrass,
    -- })
    if nNewDemolish ~= DataModel.uDemolishSubLand or nNewGrass ~= DataModel.uGrass then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, g_tStrings.STR_HOMELAND_DEMOLISH_NO_CHANGE)
    end
end

function UIHomelandBuildZoneListView:ClearToggleChange()
    local cell = self.tbCells[DataModel.nCurZoneIndex]

    if not cell then
        return
    end

    cell:SetChange()
end

function UIHomelandBuildZoneListView:GetNewDemolishAndGrassSubLand()
    local nNewGrass = 0
	local nNewDemolish = 0
    for nIndex, cell in ipairs(self.tbCells) do
        if cell.bNewDemolish ~= nil then
            nNewDemolish = SetNumberBit(nNewDemolish, nIndex, cell.bNewDemolish and 1 or 0)
        else
            nNewDemolish = SetNumberBit(nNewDemolish, nIndex, cell.bDemolish and 1 or 0)
        end

        if cell.bNewGrass ~= nil then
            nNewGrass = SetNumberBit(nNewGrass, nIndex, cell.bNewGrass and 0 or 1)
        else
            nNewGrass = SetNumberBit(nNewGrass, nIndex, cell.bGrass and 0 or 1)
        end
    end

    return nNewDemolish, nNewGrass
end

function UIHomelandBuildZoneListView:ShowConfirmCheck(funcConfirm)
    local bNewDemolish, bNewGrass = UIHelper.GetSelected(self.TogLandscape), UIHelper.GetSelected(self.TogLawn)
    local szContent = nil
    if bNewDemolish then
        szContent = g_tStrings.STR_HOMELAND_DEMOLISH_DESTROY_MSG
    elseif not bNewDemolish then
        szContent = g_tStrings.STR_HOMELAND_DEMOLISH_REVERT_MSG
    else
        return
    end
    UIHelper.ShowConfirm(szContent,funcConfirm)
end

return UIHomelandBuildZoneListView