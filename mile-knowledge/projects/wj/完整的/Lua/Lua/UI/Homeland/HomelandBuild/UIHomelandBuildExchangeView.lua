-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildExchangeView
-- Date: 2024-02-04 15:51:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildExchangeView = class("UIHomelandBuildExchangeView")

function UIHomelandBuildExchangeView:OnEnter(dwModelID, nCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwModelID = dwModelID
    self.nCount = nCount

    self:InitData()
    self:UpdateInfo()
end

function UIHomelandBuildExchangeView:OnExit()
    self.bInit = false
end

function UIHomelandBuildExchangeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChangeAll, EventType.OnClick, function(btn)
        self:OnClickChange(true)
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function(btn)
        self:OnClickChange(false)
    end)
end

function UIHomelandBuildExchangeView:RegEvent()
    Event.Reg(self, EventType.OnSelectedHomelandBuildExchangeListCell, function (tbInfo)
        self.tbCurSelectedInfo = tbInfo
        self:UpdateBtnState()
    end)
end

function UIHomelandBuildExchangeView:InitData()
    local aModels = FurnitureData.GetReplaceableModelIDs(self.dwModelID)
	local aModelInfos = {}
	local nMode = HLBOp_Main.GetBuildMode()
	local bInEditMode = (nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE)
	for nIndex, dwModelID in ipairs(aModels) do
        local tbInfo = self:GetFurnInfoByModelID(nIndex, dwModelID)
		table.insert(aModelInfos, tbInfo)
	end

	local _fnCompare = function(L, R)
		if L == R then
			return false
		end

		if bInEditMode then
			local bLHasCount = L.nCount > 0
			local bRHasCount = R.nCount > 0

			if bLHasCount ~= bRHasCount then
				return bLHasCount
			end
		end

		if L.nLevel ~= R.nLevel then
			return L.nLevel < R.nLevel
		else
			return L.nIndex < R.nIndex
		end
	end

	table.sort(aModelInfos, _fnCompare)

    self.tbData = aModelInfos
end

function UIHomelandBuildExchangeView:UpdateInfo()
    UIHelper.HideAllChildren(self.ScrollViewJiMuSkinList)

    self.tbCells = self.tbCells or {}
    for i, tbInfo in ipairs(self.tbData) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetJiMuSkinCell, self.ScrollViewJiMuSkinList)
            UIHelper.ToggleGroupAddToggle(self.TogGroupCell, self.tbCells[i].TogCell)
        end

        self.tbCells[i]:OnEnter(tbInfo)
        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewJiMuSkinList)

    if not self.scriptCurCell then
        self.scriptCurCell = UIHelper.AddPrefab(PREFAB_ID.WidgetJiMuSkinCell, self.WidgetCurrentJiMuSkin)
    end

    local tbInfo = self:GetFurnInfoByModelID(-1, self.dwModelID)
    self.scriptCurCell:OnEnter(tbInfo)

    self:ClearSelected()
    self:UpdateBtnState()
end

function UIHomelandBuildExchangeView:UpdateBtnState()
    if self.tbCurSelectedInfo then
        UIHelper.SetButtonState(self.BtnChange, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnChangeAll, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnChange, BTN_STATE.Disable, "请先选择替换的积木")
        UIHelper.SetButtonState(self.BtnChangeAll, BTN_STATE.Disable, "请先选择替换的积木")
    end
end

function UIHomelandBuildExchangeView:GetFurnInfoByModelID(nIndex, dwModelID)
    local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
    assert(tInfo)
    local nFurnitureType = tInfo.nFurnitureType
    local dwFurnitureID = tInfo.dwFurnitureID
    local hlMgr = GetHomelandMgr()
    local nLeftAmount = hlMgr.BuildGetFurnitureCanUse(nFurnitureType, dwFurnitureID)

    local tConfig
    if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
        tConfig = GetHomelandMgr().GetFurnitureConfig(dwFurnitureID)
    elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
        tConfig = GetHomelandMgr().GetPendantConfig(dwFurnitureID)
    end

    local nMode = HLBOp_Main.GetBuildMode()
	local bInEditMode = (nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE)

    local nRequiredLevel = tConfig.nLevelLimit or 0
    local tbInfo = {
        dwModelID = dwModelID,
        nType = nFurnitureType,
        dwFurnitureID = dwFurnitureID,
        nIndex = nIndex,
        nLevel = nRequiredLevel,
        nCount = nLeftAmount,
        bInEditMode = bInEditMode,
    }

    return tbInfo
end

function UIHomelandBuildExchangeView:OnClickChange(bAll)
    if not self.tbCurSelectedInfo then
        return
    end

    local nRealCount = self.tbCurSelectedInfo.nCount
    local dwSrcModelID = self.tbCurSelectedInfo.dwModelID
    if self.nCount and nRealCount and self.nCount > nRealCount then
        local dialog = UIHelper.ShowConfirm(string.format("替换的目标物件数量不足%d个，无法替换。", self.nCount))
        dialog:HideCancelButton()
    else
        if bAll then
            HLBOp_MultiItemOp.Replace(self.dwModelID, dwSrcModelID)
        else
            HLBOp_SingleItemOp.Replace(self.dwModelID, dwSrcModelID)
        end

        UIMgr.Close(self)
    end
end

function UIHomelandBuildExchangeView:ClearSelected()
    UIHelper.SetToggleGroupSelected(self.TogGroupCell, 0)
    UIHelper.SetSelected(self.tbCells[1].TogCell, false)
    self.tbCurSelectedInfo = nil
end

return UIHomelandBuildExchangeView