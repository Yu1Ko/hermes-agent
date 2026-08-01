-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookCommitCell
-- Date: 2022-12-02 14:55:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookCommitCell = class("UIBookCommitCell")

function UIBookCommitCell:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tParam = tParam.tBookInfo
    self.fCallBack = tParam.tBookInfo.fCallBack
    self:UpdateInfo(self.tParam)
end

function UIBookCommitCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookCommitCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function ()
        if self.fCallBack then self.fCallBack() end
    end)
end

function UIBookCommitCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBookCommitCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBookCommitCell:UpdateInfo(tParam)
    self.scriptItem = self.scriptItem or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemIcon)
    self.scriptItem:OnInitWithTabID(tParam.dwTabType, tParam.dwIndex)
    UIHelper.SetCanSelect(self.scriptItem.ToggleSelect, false, nil, false)
    UIHelper.SetRichText(self.RichTextItemName, tParam.szBookName)
    UIHelper.SetVisible(self.LabelRead, not tParam.bHasRead)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end


return UIBookCommitCell