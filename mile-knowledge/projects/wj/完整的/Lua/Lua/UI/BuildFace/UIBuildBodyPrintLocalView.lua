-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildBodyPrintLocalView
-- Date: 2023-10-18 19:59:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildBodyPrintLocalView = class("UIBuildBodyPrintLocalView")

function UIBuildBodyPrintLocalView:OnEnter(funcCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bInEditMode = false
    self.szCurPath = nil
    self.tbSelectedPath = {}
    self.szLocalDir = BuildFaceData.ExportedFolder()
    self.tbFilePaths = Lib.ListFiles(self.szLocalDir) or {}
    self.tbCells = {}

    self.funcCallback = funcCallback

    self:UpdateInfo()
end

function UIBuildBodyPrintLocalView:OnExit()
    self.bInit = false
end

function UIBuildBodyPrintLocalView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function ()
        if self.szCurPath == nil then
            return
        end

        UIMgr.Close(self)
        if self.funcCallback then
            self.funcCallback(self.szCurPath)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        for i, szFile in pairs(self.tbSelectedPath) do
            Lib.RemoveFile(szFile)
        end
        self.tbFilePaths = Lib.ListFiles(self.szLocalDir) or {}
        self.tbSelectedPath = {}
        self:UpdateInfo()

        TipsHelper.ShowNormalTip("已成功删除选择的文件")
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        self.bInEditMode = not self.bInEditMode
        self.szCurPath = nil
        self.tbSelectedPath = {}
        self:ClearSelected()
        self:UpdateBtnInfo()
    end)
end

function UIBuildBodyPrintLocalView:RegEvent()

end

function UIBuildBodyPrintLocalView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewBluePrintList)
    self.tbCells = {}
    for i, szPath in ipairs(self.tbFilePaths) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetFacePrintListCell, self.ScrollViewBluePrintList)
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

    UIHelper.SetVisible(self.WidgetEmpty, #self.tbFilePaths <= 0)
    if #self.tbFilePaths <= 0 then
        UIHelper.SetButtonState(self.BtnInput, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnInput, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Normal)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBluePrintList)

    self:UpdateBtnInfo()
end

function UIBuildBodyPrintLocalView:UpdateBtnInfo()
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

function UIBuildBodyPrintLocalView:ClearSelected()
    for i, cell in ipairs(self.tbCells) do
        cell:SetSelected(false)
    end
end


return UIBuildBodyPrintLocalView