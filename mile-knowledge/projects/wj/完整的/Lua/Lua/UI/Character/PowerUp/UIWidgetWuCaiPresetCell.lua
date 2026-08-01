-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetWuCaiPresetManageItem
-- Date: 2023/11/9
-- Desc: UIWidgetWuCaiPresetManageItem
-- ---------------------------------------------------------------------------------

---@class UIWidgetWuCaiPresetCell
local UIWidgetWuCaiPresetCell = class("UIWidgetWuCaiPresetCell")

function UIWidgetWuCaiPresetCell:OnEnter(bShowArrow, bIsDeactivate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bShowArrow = bShowArrow
    end
end

function UIWidgetWuCaiPresetCell:OnExit()
    self.bInit = false
end

function UIWidgetWuCaiPresetCell:BindUIEvent()
end

function UIWidgetWuCaiPresetCell:RegEvent()
end

function UIWidgetWuCaiPresetCell:OnInit(dwTabType, dwIndex)
    if dwTabType and dwIndex then
        if not self.itemScript then
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem)
        end
        self.itemScript:OnInitWithTabID(dwTabType, dwIndex)
        self.itemScript:SetSelectEnable(false)
        UIHelper.SetVisible(self.ImgInlaidFrame, true)
    else
        self.itemScript = nil
        UIHelper.RemoveAllChildren(self.WidgetItem)
        UIHelper.SetVisible(self.ImgInlaidFrame, false)
    end
end

function UIWidgetWuCaiPresetCell:OnInitCancelBtn(dwTabType, dwIndex)
    if dwTabType and dwIndex then
        if not self.itemScript then
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem)
        end
        self.itemScript:OnInitWithTabID(dwTabType, dwIndex)
        self.itemScript:SetSelectEnable(false)
        UIHelper.SetVisible(self.ImgInlaidFrame, true)
        UIHelper.SetVisible(self.WidgetButtonDeactivateAll, false)
        UIHelper.SetVisible(self.TogPreset, true)
        UIHelper.SetVisible(self.ImgOldWuCaiIcon, true)
    else
        self.itemScript = nil
        UIHelper.RemoveAllChildren(self.WidgetItem)

        UIHelper.SetVisible(self.ImgInlaidFrame, false)
        UIHelper.SetVisible(self.WidgetButtonDeactivateAll, true)
        UIHelper.SetVisible(self.TogPreset, false)
        UIHelper.SetVisible(self.ImgOldWuCaiIcon, false)
    end
end

function UIWidgetWuCaiPresetCell:SetActive(bActive)
    UIHelper.SetVisible(self.ImgActivated, bActive)
end

function UIWidgetWuCaiPresetCell:SetFusion(bActive)
    UIHelper.SetVisible(self.ImgInlaidFrame, bActive)
end

function UIWidgetWuCaiPresetCell:AddToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.TogPreset)
end

function UIWidgetWuCaiPresetCell:BindClickFunc(fnFunc)
    if IsFunction(fnFunc) then
        UIHelper.BindUIEvent(self.TogPreset, EventType.OnSelectChanged, function(tog, bSelected)
            if bSelected then
                fnFunc()
            end
            if self.bShowArrow then
                UIHelper.SetVisible(self.ImgUpArrow, bSelected)
            end
        end)
    end
end

function UIWidgetWuCaiPresetCell:BindDeactivateFunc(fnFunc)
    if IsFunction(fnFunc) then
        UIHelper.BindUIEvent(self.BtnDeactivateAll, EventType.OnClick, fnFunc)
    end
end

return UIWidgetWuCaiPresetCell