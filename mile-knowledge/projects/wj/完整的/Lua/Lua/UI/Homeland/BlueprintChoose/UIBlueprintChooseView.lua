-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBlueprintChooseView
-- Date: 2024-04-29 20:08:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBlueprintChooseView = class("UIBlueprintChooseView")

local PAGE_PER_COUNT = 6

function UIBlueprintChooseView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurPage = 1
    self:UpdateInfo()
end

function UIBlueprintChooseView:OnExit()
    self.bInit = false
end

function UIBlueprintChooseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrevious, EventType.OnClick, function(btn)
        self.nCurPage = self.nCurPage - 1
        self.nCurPage = math.max(1, self.nCurPage)
        self:UpdateListInfo()
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function(btn)
        self.nCurPage = self.nCurPage + 1
        self.nCurPage = math.min(self.nMaxPage, self.nCurPage)
        self:UpdateListInfo()
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if not self.tbCurSelectedConfig then return end

        UIHelper.ShowConfirm(string.format("你确定要选择【%s】的蓝图【%s】吗？\n选择之后不可更换哦！", UIHelper.GBKToUTF8(self.tbCurSelectedConfig.szAuthor), UIHelper.GBKToUTF8(self.tbCurSelectedConfig.szName)), function()
            RemoteCallToServer("On_Item_BluePrint", self.tbCurSelectedConfig.nIndex)
            UIMgr.Close(self)
        end)
    end)

    UIHelper.SetVisible(self.BtnRule, false)
end

function UIBlueprintChooseView:RegEvent()
    Event.Reg(self, EventType.OnChoiceBlueprintCell, function(tbConfig)
        self.tbCurSelectedConfig = tbConfig
    end)
end

function UIBlueprintChooseView:UpdateInfo()
    self:UpdateListInfo()

    UIHelper.SetString(self.LabelRule, g_tStrings.STR_HOMELAND_BLUEPRINT_CHOICE)
end

function UIBlueprintChooseView:UpdateListInfo()
    local tLists = Table_GetAllHomelandBlueprintsChoice()
    local nStart = (self.nCurPage - 1) * PAGE_PER_COUNT + 1
    local nEnd = nStart + PAGE_PER_COUNT - 1
    local nCount = #tLists

    self.nMaxPage = math.ceil(#tLists / PAGE_PER_COUNT)

    if nStart > nCount then
        self.nCurPage = 1
        nStart = (self.nCurPage - 1) * PAGE_PER_COUNT + 1
        nEnd = nStart + PAGE_PER_COUNT - 1
    end

    nEnd = math.min(nEnd, nCount)

    local nCellIndex = 1
    self.tbCells = self.tbCells or {}

    UIHelper.HideAllChildren(self.LayoutBlueprintList)

    for i = nStart, nEnd do
        local tbConfig = tLists[i]

        if nCellIndex == 1 then
            self.tbCurSelectedConfig = tbConfig
        end

        if not self.tbCells[nCellIndex] then
            self.tbCells[nCellIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetBluePrintChooseItem, self.LayoutBlueprintList)
            UIHelper.ToggleGroupAddToggle(self.TogGroupListCell, self.tbCells[nCellIndex].TogItem)
        end
        self.tbCells[nCellIndex]:OnEnter(nCellIndex, tbConfig)
        UIHelper.SetVisible(self.tbCells[nCellIndex]._rootNode, true)
        nCellIndex = nCellIndex + 1
    end

    UIHelper.LayoutDoLayout(self.LayoutBlueprintList)
    UIHelper.SetToggleGroupSelected(self.TogGroupListCell, 0)

    UIHelper.SetString(self.LabelPage, string.format("%d/%d", self.nCurPage, self.nMaxPage))
end


return UIBlueprintChooseView