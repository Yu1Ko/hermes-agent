-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceBodyPart
-- Date: 2023-09-20 20:13:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceBodyPart = class("UIBuildFaceBodyPart")
local PageMaxCount = 6

function UIBuildFaceBodyPart:OnEnter(nRoleType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nRoleType = nRoleType
    self.nCurPage = 1
    self:UpdateInfo()
end

function UIBuildFaceBodyPart:OnExit()
    self.bInit = false
end

function UIBuildFaceBodyPart:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
        self.nCurPage = math.max(1, self.nCurPage - 1)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        local nMaxPage = math.ceil(#BuildBodyData.tBodyList / PageMaxCount)
        self.nCurPage = math.min(nMaxPage, self.nCurPage + 1)
        self:UpdateInfo()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
			local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#BuildBodyData.tBodyList / PageMaxCount)
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
			local szPage = UIHelper.GetText(self.EditPaginate)
			local nPage = tonumber(szPage)
            if nPage then
                local nMaxPage = math.ceil(#BuildBodyData.tBodyList / PageMaxCount)
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

function UIBuildFaceBodyPart:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceBodyPart:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateEditBoxInfo()
end

function UIBuildFaceBodyPart:UpdateListInfo()
    UIHelper.HideAllChildren(self.ScrollViewDefault)
    local nSelectIndex
    local tbClassConfig = Lib.copyTab(BuildBodyData.tBodyList)
	local tBody 		= BuildBodyData.tNowBodyData
    self.tbDefaultCell = self.tbDefaultCell or {}

    local nMinIndex = (self.nCurPage - 1) * PageMaxCount + 1
    local nMaxIndex = self.nCurPage * PageMaxCount

    local nPrefabID = PREFAB_ID.WidgetBulidFaceDefault_Body
    if BuildBodyData.bPrice then
        nPrefabID = PREFAB_ID.WidgeBodyCellCoin
    end

    for i, tInfo in ipairs(tbClassConfig) do
        if BuildBodyData.bPrice then
            if i >= nMinIndex and i <= nMaxIndex then

                if not self.tbDefaultCell[i] then
                    self.tbDefaultCell[i] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewDefault)
                    self.tbDefaultCell[i]:AddTogGroup(self.TogGroupCell)
                end
                UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode, true)
                tInfo.szName = UIHelper.GBKToUTF8(tInfo.szName)

                if tInfo.szName == "" then
                    tInfo.szName = string.format("体型（%d）", i - 1)
                end

                self.tbDefaultCell[i]:OnEnter(tInfo)
                self.tbDefaultCell[i]:SetClickCallback(function (tbInfo)
                    local tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(tbInfo.szFilePath)

                    if not tBodyParams or table.is_empty(tBodyParams) then
                        tBodyParams = {}
                        for i = 0, 29, 1 do
                            tBodyParams[i] = 0
                        end
                    end

                    BuildBodyData.UpdateNowBodyData(tBodyParams)
                    Event.Dispatch(EventType.OnChangeBuildBodyDefault)
                end)

                local tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(tInfo.szFilePath)
                if BuildBodyData.IsTableEqual(tBodyParams, tBody) then
                    nSelectIndex = i
                elseif #tBodyParams == 0 then
                    local bEqual = true
                    for _, nValue in pairs(tBody) do
                        if nValue ~= 0 then
                            bEqual = false
                            break
                        end
                    end

                    nSelectIndex = i
                end
            end
        else
            if not self.tbDefaultCell[i] then
                self.tbDefaultCell[i] = UIHelper.AddPrefab(nPrefabID, self.ScrollViewDefault)
            end
            tInfo.szName = UIHelper.GBKToUTF8(tInfo.szName)

            if tInfo.szName == "" then
                tInfo.szName = string.format("体型（%d）", i - 1)
                tInfo.szIconPath = string.format("体型%d", i-1)
            else
                tInfo.szIconPath = tInfo.szName
            end
            tInfo.szIconPath = UIHelper.UTF8ToGBK(string.format("Texture/NieLian/Body/%s/%s%s.png",tRoleFileSuffix[self.nRoleType],tRoleFileSuffix[self.nRoleType],tInfo.szIconPath))

            self.tbDefaultCell[i]:OnEnter(0 , i , tInfo, function (nType , nCellIndex , script , bSelected)
                local tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(tbClassConfig[nCellIndex].szFilePath)

                if not tBodyParams or table.is_empty(tBodyParams) then
                    tBodyParams = {}
                    for i = 0, 29, 1 do
                        tBodyParams[i] = 0
                    end
                end

                BuildBodyData.UpdateNowBodyData(tBodyParams)
                Event.Dispatch(EventType.OnChangeBuildBodyDefault)
            end)
            UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode , true)

            local tBodyParams = KG3DEngine.GetBodyDefinitionFromINIFile(tInfo.szFilePath)
            if BuildBodyData.IsTableEqual(tBodyParams, tBody) then
                nSelectIndex = i
            elseif #tBodyParams == 0 then
                local bEqual = true
                for _, nValue in pairs(tBody) do
                    if nValue ~= 0 then
                        bEqual = false
                        break
                    end
                end

                nSelectIndex = i
            end

        end


    end

    if not BuildBodyData.bPrice then
        self.curBodySelectCell =  self.tbDefaultCell[nSelectIndex]
        self.curBodySelectCell:UpdateToggleSelect(true)
    else

        if nSelectIndex then
            UIHelper.SetToggleGroupSelected(self.TogGroupCell, nSelectIndex - 1)
        else
            for _, cell in ipairs(self.tbDefaultCell) do
                UIHelper.SetSelected(cell.TogHair, false)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)

end

function UIBuildFaceBodyPart:UpdateEditBoxInfo()
    local nMaxPage = math.ceil(#BuildBodyData.tBodyList / PageMaxCount)
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", nMaxPage))
end


return UIBuildFaceBodyPart