-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFacePrintLocalCell
-- Date: 2023-10-18 19:59:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFacePrintLocalCell = class("UIBuildFacePrintLocalCell")

function UIBuildFacePrintLocalCell:OnEnter(nIndex, szPath)
    self.nIndex = nIndex
    self.szPath = szPath

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIBuildFacePrintLocalCell:OnExit()
    self.bInit = false
end

function UIBuildFacePrintLocalCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBluePrintListCell, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback()
        end
    end)
end

function UIBuildFacePrintLocalCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

local tbFindStr = {
    "newfacedata/",
    "newfacedata\\",
    "hairdyeingdatadir/",
    "hairdyeingdatadir\\",
}

function UIBuildFacePrintLocalCell:UpdateInfo()
    local _, nIndex
    for index, szFindStr in ipairs(tbFindStr) do
        _, nIndex = string.find(self.szPath, szFindStr)
        if nIndex then
            break
        end
    end
    local szName = self.szPath
    if nIndex and nIndex > 0 then
        local nEndIndex = string.find(self.szPath, ".ini", 1, true)
        if not nEndIndex then
            nEndIndex = string.find(self.szPath, ".dat", 1, true) or 1
        end
        szName = string.sub(szName, nIndex + 1, nEndIndex - 1)
    end

    if Platform.IsWindows() then
        szName = UIHelper.GBKToUTF8(szName)
    end
    UIHelper.SetString(self.LabelName, szName)
end

function UIBuildFacePrintLocalCell:SetSelectedCallback(funcCallback)
    self.funcCallback = funcCallback
end

function UIBuildFacePrintLocalCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogBluePrintListCell, bSelected)
end

function UIBuildFacePrintLocalCell:SetEditMode(bInEditMode)
    for i, widget in ipairs(self.tbWidgetSingleChoose) do
        UIHelper.SetVisible(widget, not bInEditMode)
    end

    for i, widget in ipairs(self.tbWidgetMultiChoose) do
        UIHelper.SetVisible(widget, bInEditMode)
    end
end


return UIBuildFacePrintLocalCell