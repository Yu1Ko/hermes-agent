-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintImportLocalView
-- Date: 2023-06-06 17:40:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintImportLocalView = class("UIHomelandBuildBlueprintImportLocalView")

function UIHomelandBuildBlueprintImportLocalView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bInEditMode = false
    self.szCurPath = nil
    self.tbSelectedPath = {}
    self.szLocalBlueprintDir = Homeland_GetExportedBlpFolder()
    self.tbCells = {}
    self:UpdatePaths()
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintImportLocalView:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintImportLocalView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function ()
        if self.szCurPath == nil then
            return
        end

        if not HLBOp_Check.Check() then
			return
		end

        HLBOp_Select.ClearSelect()
        HLBOp_Blueprint.QueryIsGlobalBlueprint(UIHelper.UTF8ToGBK(GetFullPath(self.szCurPath)))

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        for i, szFile in pairs(self.tbSelectedPath) do
            Lib.RemoveFile(szFile)
        end
        self.tbSelectedPath = {}
        self:UpdatePaths()
        self:UpdateInfo()

        TipsHelper.ShowNormalTip("已成功删除选择的蓝图文件")
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        self.bInEditMode = not self.bInEditMode
        self.szCurPath = nil
        self.tbSelectedPath = {}
        self:ClearSelected()
        self:UpdateBtnInfo()
    end)
end

function UIHomelandBuildBlueprintImportLocalView:RegEvent()

end

function UIHomelandBuildBlueprintImportLocalView:UpdatePaths()
    local tbFilePaths = Lib.ListFiles(self.szLocalBlueprintDir) or {}
    local i = #tbFilePaths
    while i > 0 do
        local szPath = tbFilePaths[i]
        if not string.find(szPath, ".blueprintx", 1, true) and not string.find(szPath, ".blueprint", 1, true) then
            table.remove(tbFilePaths, i)
        end
        i = i - 1
    end

    self.tbFilePaths = tbFilePaths
end

function UIHomelandBuildBlueprintImportLocalView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewBluePrintList)
    self.tbCells = {}
    for i, szPath in ipairs(self.tbFilePaths) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBluePrintListCell, self.ScrollViewBluePrintList)
        end

        self.tbCells[i]:OnEnter(i, szPath)
        self.tbCells[i]:SetSelectedCallback(function ()
            if not self.bInEditMode then
                self:ClearSelected()
                self.tbCells[i]:SetSelected(true)
                self.szCurPath = szPath
            else
                if self.tbSelectedPath[i] then
                    self.tbSelectedPath[i] = nil
                    self.tbCells[i]:SetSelected(false)
                else
                    self.tbSelectedPath[i] = szPath
                    self.tbCells[i]:SetSelected(true)
                end
            end
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBluePrintList)

    self:UpdateBtnInfo()
end

function UIHomelandBuildBlueprintImportLocalView:UpdateBtnInfo()
    UIHelper.SetVisible(self.BtnInput, not self.bInEditMode)
    UIHelper.SetVisible(self.BtnDelete, self.bInEditMode)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    if self.bInEditMode then
        UIHelper.SetString(self.LabelEdit, "完成")
    else
        UIHelper.SetString(self.LabelEdit, "编辑")
    end

    for i, cell in ipairs(self.tbCells) do
        cell:SetEditMode(self.bInEditMode)
    end
end

function UIHomelandBuildBlueprintImportLocalView:ClearSelected()
    for i, cell in ipairs(self.tbCells) do
        cell:SetSelected(false)
    end
end

return UIHomelandBuildBlueprintImportLocalView