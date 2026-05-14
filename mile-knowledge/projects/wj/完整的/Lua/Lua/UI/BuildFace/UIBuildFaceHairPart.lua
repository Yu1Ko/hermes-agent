-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceHairPart
-- Date: 2023-09-20 20:13:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceHairPart = class("UIBuildFaceHairPart")
local PageMaxCount = 6

function UIBuildFaceHairPart:OnEnter(nClassIndex, nSubClassIndex , nRoleType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local bJustUpdateState = false
    if self.nClassIndex ~= nClassIndex or self.nSubClassIndex ~= nSubClassIndex or not self.nCurPage then
        self.nCurPage = 1
    else
        bJustUpdateState = true
    end
    self.nRoleType = nRoleType
    self.nClassIndex = nClassIndex
    self.nSubClassIndex = nSubClassIndex
    self:UpdateInfo(bJustUpdateState)
end

function UIBuildFaceHairPart:OnExit()
    self.bInit = false
end

function UIBuildFaceHairPart:BindUIEvent()
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
end

function UIBuildFaceHairPart:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceHairPart:UpdateInfo(bJustUpdateState)
    self:UpdateListInfo(bJustUpdateState)
    self:UpdateEditBoxInfo()
end

function UIBuildFaceHairPart:UpdateListInfo(bJustUpdateState)
    local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDefault)
    end

    local nMinIndex = (self.nCurPage - 1) * PageMaxCount + 1
    local nMaxIndex = self.nCurPage * PageMaxCount

    local nPrefabID = PREFAB_ID.WidgetBulidFacePreview_Hair
    if BuildHairData.bPrice then
        nPrefabID = PREFAB_ID.WidgetCoinHairCell
    end

    self.tbCells = self.tbCells or {}
    for nIndex, tbInfo in ipairs(tbConfig) do
        if nIndex >= nMinIndex and nIndex <= nMaxIndex then
            if BuildHairData.bPrice then
                if not self.tbCells[nIndex] then
                    self.tbCells[nIndex] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewDefault)
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
            else
                if not self.tbCells[nIndex] then
                    self.tbCells[nIndex] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewDefault)
                end

                if not bJustUpdateState then
                    UIHelper.SetVisible(self.tbCells[nIndex]._rootNode, true)
                end
                tbInfo.szName = tbInfo.szName or "默认"
                tbInfo.szIconPath = UIHelper.UTF8ToGBK(string.format("Texture/NieLian/Hair/%s/%s_%s.png",tRoleFileSuffix[self.nRoleType],tRoleFileSuffix[self.nRoleType],tbInfo.szName))
                self.tbCells[nIndex]:OnEnter(0 , nIndex , tbInfo, function (nType , nCellIndex , script , bSelected)
                    BuildHairData.bChangeHairPat = true
                    BuildPresetData.nCurSelectHairIndex = nIndex
                    BuildHairData.SetClassIndexValue(tbConfig[nCellIndex].nClassIndex, tbConfig[nCellIndex].nID)
                    Event.Dispatch(EventType.OnChangeBuildHairValue, tbConfig[nCellIndex].nClassIndex)
                end)
                self.tbCells[nIndex]:UpdateToggleSelect(nIndex == BuildPresetData.nCurSelectHairIndex)
            end
        end
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
    end

    local nSelectIndex = BuildHairData.GetClassIndexValue(self.nClassIndex, self.nSubClassIndex)
    if nSelectIndex >= nMinIndex and nSelectIndex <= nMaxIndex then
        UIHelper.SetToggleGroupSelected(self.TogGroupCell, nSelectIndex - 1)
    else
        UIHelper.SetToggleGroupSelected(self.TogGroupCell, 0)
        UIHelper.SetSelected(self.tbCells[1].TogHair, false)
    end
end

function UIBuildFaceHairPart:UpdateEditBoxInfo()
    local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nClassIndex, self.nSubClassIndex)
    local nMaxPage = math.ceil(#tbConfig / PageMaxCount)
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", nMaxPage))

    UIHelper.SetVisible(self.WidgetPaginate, nMaxPage > 1)
end


return UIBuildFaceHairPart