-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintImportLocalCell
-- Date: 2023-06-07 14:31:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintImportLocalCell = class("UIHomelandBuildBlueprintImportLocalCell")

function UIHomelandBuildBlueprintImportLocalCell:OnEnter(nIndex, szPath)
    self.nIndex = nIndex
    self.szPath = szPath

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildBlueprintImportLocalCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintImportLocalCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBluePrintListCell, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback()
        end
    end)
end

function UIHomelandBuildBlueprintImportLocalCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

local tbFindStr = {
    "homelanddir/blueprints/homelandblueprinttotal_",
    "homelanddir/blueprints/homelandblueprint_",
    "homelanddir/blueprints/homelandblueprint",
    "homelanddir/blueprints/",
}

function UIHomelandBuildBlueprintImportLocalCell:UpdateInfo()
    -- "homelanddir/blueprints/homelandblueprintTotal_20230606-205441.blueprintx"
    -- "homelanddir/blueprints/homelandblueprint_20230605-140431.blueprintx"
    local _, nIndex
    for index, szFindStr in ipairs(tbFindStr) do
        _, nIndex = string.find(string.lower(self.szPath), szFindStr)
        if nIndex then
            break
        end
    end
    local szName = self.szPath
    if nIndex and nIndex > 0 then
        local nEndIndex = string.find(self.szPath, ".blueprintx") or string.find(self.szPath, ".blueprint", 1, true) or 1
        szName = string.sub(szName, nIndex + 1, nEndIndex - 1)
    end

    if Platform.IsWindows() then
        szName = UIHelper.GBKToUTF8(szName)
    end
    UIHelper.SetString(self.LabelName, szName)
end

function UIHomelandBuildBlueprintImportLocalCell:SetSelectedCallback(funcCallback)
    self.funcCallback = funcCallback
end

function UIHomelandBuildBlueprintImportLocalCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogBluePrintListCell, bSelected)
end

function UIHomelandBuildBlueprintImportLocalCell:SetEditMode(bInEditMode)
    for i, widget in ipairs(self.tbWidgetSingleChoose) do
        UIHelper.SetVisible(widget, not bInEditMode)
    end

    for i, widget in ipairs(self.tbWidgetMultiChoose) do
        UIHelper.SetVisible(widget, bInEditMode)
    end
end

return UIHomelandBuildBlueprintImportLocalCell