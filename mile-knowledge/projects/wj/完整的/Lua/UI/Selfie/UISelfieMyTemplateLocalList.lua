-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieMyTemplateLocalList
-- Date: 2023-10-18 19:59:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieMyTemplateLocalList = class("UISelfieMyTemplateLocalList")

function UISelfieMyTemplateLocalList:OnEnter(funcCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bInEditMode = false
    self.szCurPath = nil
    self.tbSelectedPath = {}
    self.szLocalDir = SelfieTemplateBase.ExportedFolder()
    self.tbFilePaths = Lib.ListFiles(self.szLocalDir) or {}
    self.tbCells = {}

    self.funcCallback = funcCallback

    self:UpdateInfo()
end

function UISelfieMyTemplateLocalList:OnExit()
    self.bInit = false
end

function UISelfieMyTemplateLocalList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function ()
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

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function ()
        self.bInEditMode = not self.bInEditMode
        self.szCurPath = nil
        self.tbSelectedPath = {}
        self:ClearSelected()
        self:UpdateBtnInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDeleteExit, EventType.OnClick, function(btn)
        self.bInEditMode = false

        self:ClearSelected()
        self:UpdateBtnInfo()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)
    end
end

function UISelfieMyTemplateLocalList:RegEvent()

end

function UISelfieMyTemplateLocalList:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewPhotoList)
    self.tbCells = {}
    for i, szPath in ipairs(self.tbFilePaths) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraCodeCell, self.ScrollViewPhotoList)
        end

        self.tbCells[i]:OnInitWithLocalInfo(i, szPath)
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

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewPhotoList)

    self:UpdateBtnInfo()
end

function UISelfieMyTemplateLocalList:UpdateBtnInfo()
    UIHelper.SetVisible(self.BtnDeleteExit, self.bInEditMode)
    UIHelper.SetVisible(self.BtnDelete, self.bInEditMode)
    UIHelper.SetVisible(self.BtnUse, not self.bInEditMode)
    UIHelper.SetVisible(self.BtnManage, not self.bInEditMode)
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

function UISelfieMyTemplateLocalList:ClearSelected()
    for i, cell in ipairs(self.tbCells) do
        cell:SetSelected(false)
    end
end

function UISelfieMyTemplateLocalList:OnSearch(szSearch)
    self.szSearchText = szSearch
    self:UpdateInfo()
end

return UISelfieMyTemplateLocalList