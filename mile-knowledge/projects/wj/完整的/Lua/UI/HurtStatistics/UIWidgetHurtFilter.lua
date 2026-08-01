-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHurtFilter
-- Date: 2025-05-20 11:11:54
-- Desc: ?
-- ---------------------------------------------------------------------------------
local INDEX2STAT_TYPE = {
    [1] = STAT_TYPE.HATRED,
    [2] = STAT_TYPE.DAMAGE,
    [3] = STAT_TYPE.THERAPY,
    [4] = STAT_TYPE.BE_DAMAGE,
}

local STAT_TYPE2DESC = {
    [STAT_TYPE.HATRED] = "仇恨",
    [STAT_TYPE.DAMAGE] = "伤害统计",
    [STAT_TYPE.THERAPY] = "治疗统计",
    [STAT_TYPE.BE_DAMAGE] = "承伤统计",
}

local INDEX2SOR_TYPE = {
    STAT_TYPE.DAMAGE,
    STAT_TYPE.THERAPY,
    STAT_TYPE.BE_DAMAGE,
    STAT_TYPE.BE_THERAPY,
}

local SOR_TYPE2DESC = {
    [STAT_TYPE.DAMAGE] = "按伤害排序",
    [STAT_TYPE.THERAPY] = "按治疗排序",
    [STAT_TYPE.BE_DAMAGE] = "按承伤排序",
    [STAT_TYPE.BE_THERAPY] = "按承疗排序",
}

local INDEX_TO_PARTNER = {
    [1] = {szTitle = "仅显示自己侠客伤害", nType = PARTNER_FIGHT_LOG_TYPE.SELF},
    [2] = {szTitle = "显示全部侠客伤害", nType = PARTNER_FIGHT_LOG_TYPE.ALL},
}

local UIWidgetHurtFilter = class("UIWidgetHurtFilter")

function UIWidgetHurtFilter:Init(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nType = nType
    self:InitTogOptions()
end

function UIWidgetHurtFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHurtFilter:BindUIEvent()

end

function UIWidgetHurtFilter:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:Hide()
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        self:Hide()
    end)

    Event.Reg(self, EventType.OnHurtStatisticPartnerTypeChanged, function ()
        if not self.tbPartnerOptions or table.is_empty(self.tbPartnerOptions) then
            return
        end

        local bApply = Storage.HurtStatisticSettings.IsSeparatePartnerData
        local szApplyData = Storage.HurtStatisticSettings.ShowParnterType
        UIHelper.SetSelected(self.tbPartnerOptions.scriptTitle.TogMultiFunction, bApply, false)

        for nIndex, tbOptions in ipairs(INDEX_TO_PARTNER) do
            local tog = self.tbPartnerOptions[nIndex]
            local bSelected = szApplyData == tbOptions.nType
            UIHelper.SetEnable(tog, bApply)
            UIHelper.SetNodeGray(tog, not bApply, true)
            UIHelper.SetSelected(tog, bSelected, false)
        end
    end)
end

function UIWidgetHurtFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetHurtFilter:InitTogOptions()
    self.tbMainOptions = {}
    if self.nType == HURT_STAT_TYPE.BALL then
        self.tbMainOptions = self:Init_StatBall()
    elseif self.nType == HURT_STAT_TYPE.PANEL then
        self.tbMainOptions = self:Init_StatPanel()
    end

    self.tbPartnerOptions = self:Init_Partner()
end

function UIWidgetHurtFilter:Init_StatBall()
    local tbMainOptions = {}
    local nRowCount = math.ceil(#INDEX2STAT_TYPE / 2)
    local scriptTitle = self:AddTitle("显示", false)

    for i = 1, nRowCount, 1 do
        local scriptOption = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeMulti_S, self.ScrollViewType)
        for j = 1, 2 do
            local nIndex = (i - 1) * 2 + j
            local szOption = STAT_TYPE2DESC[INDEX2STAT_TYPE[nIndex]]
            local lable = scriptOption.tbLabelList[j]
            local tog = scriptOption.tbToggleList[j]

            UIHelper.SetString(lable, szOption)
            tbMainOptions[nIndex] = tog
        end
    end

    scriptTitle:RegisterSetApplyEvent(function (bSelected)
        for i = 1, #tbMainOptions do
            UIHelper.SetEnable(tbMainOptions[i], not bSelected)
            UIHelper.SetNodeGray(tbMainOptions[i], bSelected, true)
        end
    end)

    return tbMainOptions
end

function UIWidgetHurtFilter:Init_StatPanel()
    local tbMainOptions = {}
    local nRowCount = math.ceil(#INDEX2SOR_TYPE / 2)
    local scriptTitle = self:AddTitle("排序", false)

    for i = 1, nRowCount, 1 do
        local scriptOption = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_S, self.ScrollViewType)
        for j = 1, 2 do
            local nIndex = (i - 1) * 2 + j
            local szOption = SOR_TYPE2DESC[INDEX2SOR_TYPE[nIndex]]
            local lable = scriptOption.tbLabelList[j]
            local tog = scriptOption.tbToggleList[j]

            UIHelper.SetString(lable, szOption)
            UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.HurtStat)
            tbMainOptions[nIndex] = tog
        end
    end

    return tbMainOptions
end

function UIWidgetHurtFilter:Init_Partner()
    local tbPartnerOptions = {}
    local nRowCount = #INDEX_TO_PARTNER
    local bApply = Storage.HurtStatisticSettings.IsSeparatePartnerData
    local szApplyData = Storage.HurtStatisticSettings.ShowParnterType

    local scriptTitle = self:AddTitle("侠客伤害", true)
    tbPartnerOptions.scriptTitle = scriptTitle
    UIHelper.SetString(scriptTitle.LabelMultiFunction, "显示")
    UIHelper.SetSelected(scriptTitle.TogMultiFunction, bApply)

    for nIndex = 1, nRowCount, 1 do
        local scriptOption = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_L, self.ScrollViewType)
        local tbOptions = INDEX_TO_PARTNER[nIndex]
        local bSelected = szApplyData == tbOptions.nType
        local szOption = tbOptions.szTitle
        local lable = scriptOption.LabelTogName
        local tog = scriptOption.TogType

        UIHelper.SetString(lable, szOption)
        UIHelper.SetSelected(tog, bSelected)
        UIHelper.SetEnable(tog, bApply)
        UIHelper.SetNodeGray(tog, not bApply, true)
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.HurtStat - 1)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
            if not bSelected then
                return
            end
            Storage.HurtStatisticSettings.ShowParnterType = tbOptions.nType
            Storage.HurtStatisticSettings.Dirty()
            Event.Dispatch(EventType.OnHurtStatisticPartnerTypeChanged)
        end)
        tbPartnerOptions[nIndex] = tog
    end

    scriptTitle:RegisterSetApplyEvent(function (bSelected)
        Storage.HurtStatisticSettings.IsSeparatePartnerData = bSelected
        Storage.HurtStatisticSettings.Dirty()
        Event.Dispatch(EventType.OnHurtStatisticPartnerTypeChanged)

        local bAllEmpty = true
        for i = 1, #tbPartnerOptions do
            local tog = tbPartnerOptions[i]
            UIHelper.SetEnable(tog, bSelected)
            UIHelper.SetNodeGray(tog, not bSelected, true)
            if UIHelper.GetSelected(tog) then
                bAllEmpty = false
            end
        end

        if bAllEmpty then
            UIHelper.SetSelected(tbPartnerOptions[1], true, true)
        end
    end)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType)
    return tbPartnerOptions
end

function UIWidgetHurtFilter:AddTitle(szTitle, bShowMulti)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTittleCell, self.ScrollViewType, false)
    UIHelper.SetString(script.LabelTittle, szTitle)
    UIHelper.SetVisible(script.TogMultiFunction, bShowMulti)
    UIHelper.SetSwallowTouches(script.TogMultiFunction, true)
    UIHelper.SetTouchDownHideTips(script.TogMultiFunction, false)

    return script
end

function UIWidgetHurtFilter:GetMainOptions()
    return self.tbMainOptions
end

function UIWidgetHurtFilter:BindMainOptionsCallBack(fnSelectedCallback)
    if not self.tbMainOptions or not fnSelectedCallback then
        return
    end

    for index, tog in ipairs(self.tbMainOptions) do
        if IsFunction(fnSelectedCallback) then
            UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
                fnSelectedCallback(index, bSelected)
            end)
        end
    end
end

function UIWidgetHurtFilter:Show()
    if UIHelper.GetVisible(self._rootNode) then
        return
    end
    UIHelper.SetVisible(self._rootNode, true)
end

function UIWidgetHurtFilter:Hide()
    if not UIHelper.GetVisible(self._rootNode) then
        return
    end
    UIHelper.SetVisible(self._rootNode, false)
end

return UIWidgetHurtFilter