-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopFilter
-- Date: 2023-03-27 14:23:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopFilter = class("UICoinShopFilter")

function UICoinShopFilter:OnInit(tData)
    self.tData = tData
    self.bChanged = true
end

function UICoinShopFilter:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopFilter:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function ()
        for _, script in ipairs(self.tScriptList) do
            script:Confirm()
        end
        self.tData.fnConfirm()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        for _, script in ipairs(self.tScriptList) do
            script:Reset()
        end
    end)
end

function UICoinShopFilter:RegEvent()
end

function UICoinShopFilter:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopFilter:UpdateInfo()
    if not self.bChanged then
        return
    end
    UIHelper.RemoveAllChildren(self.ScrollViewFilter)
    self.tScriptList = {}
    for _, tConfig in ipairs(self.tData) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitCategory, self.ScrollViewFilter)
        script:OnEnter(tConfig)
        table.insert(self.tScriptList, script)

        for _, script in ipairs(script.tScriptList) do
            UIHelper.SetTouchDownHideTips(script.TogPitchBg, false)
        end
    end

    UIHelper.SetTouchDownHideTips(self.ScrollViewFilter, false)
    -- UIHelper.SetTouchDownHideTips(self.BtnAffirm, false)
    UIHelper.SetTouchDownHideTips(self.BtnReset, false)
    self.bChanged = false
end

function UICoinShopFilter:Refresh()
    self:UpdateInfo()
    Timer.AddFrame(self, 1, function ()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilter)
    end)
end

return UICoinShopFilter