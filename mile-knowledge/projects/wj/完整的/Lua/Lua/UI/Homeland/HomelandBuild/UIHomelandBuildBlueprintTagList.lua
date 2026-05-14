-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintTagList
-- Date: 2024-10-10 19:56:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintTagList = class("UIHomelandBuildBlueprintTagList")

function UIHomelandBuildBlueprintTagList:OnEnter(szTitle, tbTagList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.tbTagList = tbTagList
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintTagList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuildBlueprintTagList:BindUIEvent()

end

function UIHomelandBuildBlueprintTagList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBlueprintTagList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ¡ý¡ý¡ý
-- ----------------------------------------------------------

function UIHomelandBuildBlueprintTagList:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    self.tbTagCell = {}
    local tbTagList = self.tbTagList
    for index, tbTag in ipairs(tbTagList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetTagCell, self.LayoutTag)
        scriptCell:OnEnter(index, tbTag)
        table.insert(self.tbTagCell, scriptCell)
    end

    UIHelper.LayoutDoLayout(self.LayoutTag)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIHomelandBuildBlueprintTagList:IsFullSelected(tbTag)
    for index, scriptCell in ipairs(self.tbTagCell) do
        local bCanSelect = #tbTag < 5 or table.contain_value(tbTag, scriptCell.tbTag.szName)
        UIHelper.SetCanSelect(scriptCell.TogCell, bCanSelect, nil, true)
    end
end

return UIHomelandBuildBlueprintTagList