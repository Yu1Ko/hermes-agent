-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantFilter
-- Date: 2023-03-06 15:20:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterPendantFilter = class("UICharacterPendantFilter")

function UICharacterPendantFilter:OnEnter(funcCallback)
    self.funcCallback = funcCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterPendantFilter:OnExit()
    self.bInit = false
end

function UICharacterPendantFilter:BindUIEvent()
    local i = 1
    while self["tbTogSubType"..i] do
        for index, tog in ipairs(self["tbTogSubType"..i]) do
            local szTypeName = "nCurType"..i
            UIHelper.ToggleGroupAddToggle(self.tbTogGroup[i], tog)
            UIHelper.SetTouchDownHideTips(tog, false)
            UIHelper.BindUIEvent(tog, EventType.OnClick, function()
                self[szTypeName] = index - 1
            end)
        end
        self["nCurType"..i] = 0
        UIHelper.SetToggleGroupSelected(self.tbTogGroup[i], self["nCurType"..i])
        i = i + 1
    end

    UIHelper.SetTouchDownHideTips(self.BtnReset, false)
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self:Reset()
    end)

    UIHelper.SetTouchDownHideTips(self.BtnAffirm, false)
    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function()
        if self.funcCallback then
            local tb = {}
            local i = 1
            while self["nCurType"..i] do
                table.insert(tb, self["nCurType"..i])
                i = i + 1
            end
            self.funcCallback(table.unpack(tb))
        end
    end)

    UIHelper.SetTouchDownHideTips(self.ScrollViewFilterTips, false)
end

function UICharacterPendantFilter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterPendantFilter:UpdateInfo()
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilterTips)
    UIHelper.ScrollToTop(self.ScrollViewFilterTips, 0)
end

function UICharacterPendantFilter:Reset()
    for i, togGroup in ipairs(self.tbTogGroup) do
        self["nCurType"..i] = 0
        UIHelper.SetToggleGroupSelected(togGroup, 0)
    end
end


return UICharacterPendantFilter