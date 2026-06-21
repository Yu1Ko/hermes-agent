-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopHairPage
-- Date: 2024-03-26 17:20:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopHairPage = class("UICoinShopHairPage")
local PageMaxCount = 6

function UICoinShopHairPage:OnEnter(nClassIndex, nSubClassIndex, nPage)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local player = PlayerData.GetClientPlayer()
        if player then
            local nRoleType = player.nRoleType
            local playerKungFuID = player.GetActualKungfuMount().dwSkillID

            BuildHairData.UnInit()
            BuildHairData.Init({
                nRoleType = nRoleType,
                nKungfuID = playerKungFuID,
                bPrice = true,
            })
        end
    end

    self.nCurPage = nPage
    local bJustUpdateState = false
    if self.nClassIndex ~= nClassIndex or self.nSubClassIndex ~= nSubClassIndex or not self.nCurPage then
        self.nCurPage = 1
    else
        bJustUpdateState = true
    end

    self.nClassIndex = nClassIndex or 1
    self.nSubClassIndex = nSubClassIndex or 1
    self:UpdateInfo(bJustUpdateState)
end

function UICoinShopHairPage:OnExit()
    self.bInit = false
end

function UICoinShopHairPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
        self.nCurPage = math.max(1, self.nCurPage - 1)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
        local nMaxPage = math.ceil(#tbConfig / PageMaxCount)
        self.nCurPage = math.min(nMaxPage, self.nCurPage + 1)
        self:UpdateInfo()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
            local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
            local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#tbConfig / PageMaxCount)
                self.nCurPage = math.min(nMaxPage, nPage)
                self.nCurPage = math.max(1, self.nCurPage)
            else
                UIHelper.SetText(self.EditPaginate, self.nCurPage)
                return
            end
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
            local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
			local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#tbConfig / PageMaxCount)
                self.nCurPage = math.min(nMaxPage, nPage)
                self.nCurPage = math.max(1, self.nCurPage)
            else
                UIHelper.SetText(self.EditPaginate, self.nCurPage)
                return
            end
            self:UpdateInfo()
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

    for i, tog in ipairs(self.tbTogSubClass) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nSubClassIndex = i
            self:UpdateInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupSubClass, tog)
    end
    UIHelper.SetVisible(self.LayoutTypeList, false)
end

function UICoinShopHairPage:RegEvent()
    Event.Reg(self, EventType.OnChangeBuildHairValue, function (nClassIndex)
        self:UpdateModleInfo()
    end)
end

function UICoinShopHairPage:UpdateInfo(bJustUpdateState)
    self:UpdateListInfo(bJustUpdateState)
    self:UpdateEditBoxInfo()

    UIHelper.SetToggleGroupSelected(self.TogGroupSubClass, self.nSubClassIndex - 1)
end


function UICoinShopHairPage:UpdateListInfo(bJustUpdateState)
    local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewHairList)
    end

    local nMinIndex = (self.nCurPage - 1) * PageMaxCount + 1
    local nMaxIndex = self.nCurPage * PageMaxCount

    local nPrefabID = PREFAB_ID.WidgetHairCell
    if BuildHairData.bPrice then
        nPrefabID = PREFAB_ID.WidgetCoinHairCell
    end

    local bEmpty = true
    self.tbCells = self.tbCells or {}
    for nIndex, tbInfo in ipairs(tbConfig) do
        if nIndex >= nMinIndex and nIndex <= nMaxIndex then
            bEmpty = false
            if not self.tbCells[nIndex] then
                self.tbCells[nIndex] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewHairList)
                self.tbCells[nIndex]:AddTogGroup(self.TogGroupCell)
            end

            if not bJustUpdateState then
                UIHelper.SetVisible(self.tbCells[nIndex]._rootNode, true)
            end

            tbInfo.szName = tbInfo.szName or "默认"
            self.tbCells[nIndex]:OnEnter(tbInfo)
            self.tbCells[nIndex]:SetClickCallback(function (tbInfo)
                BuildHairData.SetClassIndexValue(tbInfo.nClassIndex, tbInfo.nID)
                Event.Dispatch(EventType.OnChangeBuildHairValue, tbInfo.nClassIndex)
            end)
            local nHairID = BuildHairData.GetHairStyleByClassIndexValue(tbInfo.nClassIndex, tbInfo.nID)
            if nHairID then
                self.tbCells[nIndex]:UpdateDownloadEquipRes(nHairID)
            end
        end
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHairList)
    end

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, bEmpty)
    local nSelectIndex = BuildHairData.GetClassIndexValue(self.nClassIndex, self.nSubClassIndex)
    if nSelectIndex >= nMinIndex and nSelectIndex <= nMaxIndex then
        UIHelper.SetToggleGroupSelected(self.TogGroupCell, nSelectIndex - 1)
    else
        UIHelper.SetToggleGroupSelected(self.TogGroupCell, 0)
        UIHelper.SetSelected(self.tbCells[1].TogHair, false)
    end
end

function UICoinShopHairPage:UpdateEditBoxInfo()
    local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
    local nMaxPage = math.ceil(#tbConfig / PageMaxCount)
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", nMaxPage))
end

function UICoinShopHairPage:UpdateModleInfo()
    local nHairID = BuildHairData.GetSelectedHairStyle()
    ExteriorCharacter.PreviewHair(nHairID, nil, true, true, false)
end

return UICoinShopHairPage