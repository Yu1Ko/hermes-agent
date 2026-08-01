-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIWidgetAutoCleanUpCell
-- Date: 2024-01-24 19:54:43
-- Desc: WidgetAutoCleanUpCell 资源清理标题栏
-- ---------------------------------------------------------------------------------

local UIWidgetAutoCleanUpCell = class("UIWidgetAutoCleanUpCell")

local szCategory = SettingCategory.Resources
local szAutoCleanName = "自动清理"

function UIWidgetAutoCleanUpCell:OnEnter(nMainCategory)
    self.nMainCategory = nMainCategory

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetAutoCleanUpCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAutoCleanUpCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetBtnHelp, TipsLayoutDir.RIGHT_CENTER, self.szHelpText)
    end)
end

function UIWidgetAutoCleanUpCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAutoCleanUpCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAutoCleanUpCell:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutType)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    if not self.nMainCategory then
        return
    end

    local lst = UIGameSettingConfigTab[szCategory][self.nMainCategory]
    for index, tCellInfo in ipairs(lst) do
        if tCellInfo.szName == szAutoCleanName then
            UIHelper.SetString(self.LabelAutoTitle, tCellInfo.szName)
            
            local bSelected = GameSettingData.GetNewValue(tCellInfo.szKey)
            UIHelper.SetSelected(self.ToggleAuto, bSelected, false)
            UIHelper.BindUIEvent(self.ToggleAuto, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    UIHelper.ShowConfirm("是否开启" .. UIHelper.GetString(self.LabelTitle) .. "自动清理？", function()
                        GameSettingData.ApplyNewValue(tCellInfo.szKey, bSelected)
                    end, function()
                        UIHelper.SetSelected(self.ToggleAuto, false, false)
                    end)
                else
                    GameSettingData.ApplyNewValue(tCellInfo.szKey, bSelected)
                end
            end)
        else
            UIHelper.SetString(self.LabelTitle, tCellInfo.szName)

            self.szHelpText = tCellInfo.szHelpText
            UIHelper.SetVisible(self.BtnHelp, not string.is_nil(tCellInfo.szHelpText))

            --GameSettingCellType.DropBox
            for _, v in ipairs(tCellInfo.options) do
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_XS, self.LayoutType)
                UIHelper.SetString(script.tbLabelList[1], v.szDec)

                local toggle = script.tbToggleList[1]

                UIHelper.ToggleGroupAddToggle(self.ToggleGroup, toggle)
                UIHelper.SetToggleGroupIndex(toggle, -1)

                local tVal = GameSettingData.GetNewValue(tCellInfo.szKey)
                local bSelected = tVal and tVal.szDec == v.szDec or false
                if bSelected then
                    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, toggle)
                end

                UIHelper.SetSwallowTouches(toggle, false)
                UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected then
                        GameSettingData.ApplyNewValue(tCellInfo.szKey, v)
                        Event.Dispatch(EventType.OnCleanResourcesUpdate)
                    end
                end)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutType)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

return UIWidgetAutoCleanUpCell