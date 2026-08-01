-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetFengYunLuDesignationPanel
-- ---------------------------------------------------------------------------------

---@class UIFengYunLuDesignationPanel
local UIFengYunLuDesignationPanel = class("UIFengYunLuDesignationPanel")

function UIFengYunLuDesignationPanel:OnEnter(szPreFix)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local szTruPrefix, dwForceID = string.match(szPreFix, "([%d;]+)-([%d;]+)")
    szTruPrefix = szTruPrefix or szPreFix
    self.tPreFix = SplitString(szTruPrefix, ";")
    self.dwForceID = dwForceID
   
    self:UpdateInfo()
end

function UIFengYunLuDesignationPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFengYunLuDesignationPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIFengYunLuDesignationPanel:RegEvent()

end

function UIFengYunLuDesignationPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIFengYunLuDesignationPanel:UpdateInfo()
    if self.tPreFix then
        local tVisited = {}
        for i = 1, #self.tPreFix do
            if not table.contain_value(tVisited, self.tPreFix[i]) then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFengYunLuRewardTitleCell, self.ScrollViewRewardTitle, self.tPreFix[i], self.dwForceID)
                table.insert(tVisited, self.tPreFix[i])
            end
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewRewardTitle)
        UIHelper.ScrollToTop(self.ScrollViewRewardTitle, 0)
    end
end

return UIFengYunLuDesignationPanel