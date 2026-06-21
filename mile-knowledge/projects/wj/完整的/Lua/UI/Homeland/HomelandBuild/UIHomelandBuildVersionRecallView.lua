-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildVersionRecallView
-- Date: 2023-06-05 11:09:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildVersionRecallView = class("UIHomelandBuildVersionRecallView")
local MAX_REVERT_NUM = 5

function UIHomelandBuildVersionRecallView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurSelectedIndex = 1
    self.tbCells = {}
    self:UpdateInfo()
    self:UpdateSelectedCell()
end

function UIHomelandBuildVersionRecallView:OnExit()
    self.bInit = false
end

function UIHomelandBuildVersionRecallView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_REVERT_BUILDING_CONFIRM, function ()
            HLBOp_Exit.DoRevert(self.nCurSelectedIndex)
            UIMgr.Close(self)
        end)
    end)
end

function UIHomelandBuildVersionRecallView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildVersionRecallView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    self.tbCells = {}

    for i = 1, MAX_REVERT_NUM do
        self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetVersionCell, self.ScrollViewContent)
        self.tbCells[i]:OnEnter(i, function ()
            self.nCurSelectedIndex = i
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupCell, self.tbCells[i].ToggleSelect)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIHomelandBuildVersionRecallView:UpdateSelectedCell()
    for i, cellScript in ipairs(self.tbCells) do
        UIHelper.SetSelected(cellScript.ToggleSelect, i == self.nCurSelectedIndex)
    end
end


return UIHomelandBuildVersionRecallView