-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopFilterTitle
-- Date: 2022-12-22 20:36:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopFilterTitle = class("UICoinShopFilterTitle")

function UICoinShopFilterTitle:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.tScriptList = {}

    self:UpdateInfo()
end

function UICoinShopFilterTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopFilterTitle:BindUIEvent()

end

function UICoinShopFilterTitle:RegEvent()
end

function UICoinShopFilterTitle:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopFilterTitle:UpdateInfo()
    UIHelper.SetString(self.LabelCategory, self.tData.szTitle)
    for i, tConfig in ipairs(self.tData) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitEquip, self.LayoutCategory)
        script:OnEnter(tConfig)
        table.insert(self.tScriptList, script)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, script.TogPitchBg)
        if tConfig.bCheck then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, script.TogPitchBg)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutCategory)
    UIHelper.LayoutDoLayout(self.WidgetSuitCategory)
end

function UICoinShopFilterTitle:Confirm()
    for _, script in ipairs(self.tScriptList) do
        if UIHelper.GetSelected(script.TogPitchBg) then
            self.tData.fnConfirm(script.tData.UserData)
            break
        end
    end
end

function UICoinShopFilterTitle:Reset()
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, 0)
end

return UICoinShopFilterTitle