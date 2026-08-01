-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRuleView
-- Date: 2023-02-17 16:28:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRuleView = class("UIRuleView")

function UIRuleView:OnEnter(nRuleID)
    self.nRuleID = nRuleID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRuleView:OnExit()
    self.bInit = false
end

function UIRuleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIRuleView:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function (szUrl, node)
        if szUrl == "GoServiceHelp" then
            ServiceCenterData.OpenServiceWeb()
        end
    end)
end

function UIRuleView:UpdateInfo()
    local tbConfig = TabHelper.GetUIRuleTab(self.nRuleID)
    if not tbConfig then
        return
    end

    UIHelper.SetString(self.LabelTitle, tbConfig.szTitle)

    local i = 1
    while tbConfig["nPrefabID"..i] and tbConfig["szDesc"..i] and tbConfig["nPrefabID"..i] > 0 and tbConfig["szDesc"..i] ~= "" do
        local cell = UIHelper.AddPrefab(tbConfig["nPrefabID"..i], self.ScrollViewActivityHelp)
        cell:OnEnter(tbConfig["szDesc"..i])
        i = i + 1
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityHelp)
    UIHelper.ScrollToTop(self.ScrollViewActivityHelp, 0)
end


return UIRuleView