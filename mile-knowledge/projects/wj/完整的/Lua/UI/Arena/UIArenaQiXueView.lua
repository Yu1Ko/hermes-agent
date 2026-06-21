-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UIArenaQiXueView
-- Date: 2025-7-1 14:48:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIArenaQiXueView
local UIArenaQiXueView = class("UIArenaQiXueView")

function UIArenaQiXueView:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIArenaQiXueView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIArenaQiXueView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogQiXue, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSkill, false)
        self:UpdatePage(true, false)
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogQiXue, false)
        self:UpdatePage(false, true)
    end)
end

function UIArenaQiXueView:RegEvent()
end

function UIArenaQiXueView:UnRegEvent()
    Event.UnRegAll(self)
end

function UIArenaQiXueView:UpdateInfo()
    local tPlayerInfo = self.tInfo
    if tPlayerInfo then
        local scriptDataPage = UIHelper.GetBindScript(self.WidgetAllList)
        self.PageScript = scriptDataPage
        scriptDataPage:OnEnter(tPlayerInfo)
    end

    if ArenaTowerData.IsInArenaTowerMap() then
        UIHelper.SetString(self.LabelLeave, "返回扬刀大会")
    end
end

function UIArenaQiXueView:UpdatePage(bQiXue, bSkill)
    local scriptDataPage = self.PageScript
    scriptDataPage:OnUpdatePage(bQiXue, bSkill)
end

return UIArenaQiXueView