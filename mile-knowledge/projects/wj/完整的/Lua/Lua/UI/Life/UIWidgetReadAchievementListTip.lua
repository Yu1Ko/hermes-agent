-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetReadAchievementListTip
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetReadAchievementListTip = class("UIWidgetReadAchievementListTip")
function UIWidgetReadAchievementListTip:OnEnter(tAchievements)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tAchievements = tAchievements or {}
    UIHelper.SetSwallowTouches(self.BtnBg, true)
    UIHelper.SetTouchDownHideTips(self.BtnBg, false)
    UIHelper.SetTouchDownHideTips(self.LayoutAchievementList, false)
    for _, BtnTrace in ipairs(self.tbTraceAchievement) do
        UIHelper.SetTouchDownHideTips(BtnTrace, false)
    end
    local nodeChildren = UIHelper.GetChildren(self.LayoutAchievementList) or {}
    for nIndex, node in ipairs(nodeChildren) do
        UIHelper.SetVisible(node, nIndex <= #self.tAchievements)
    end    
    self:UpdateInfo()
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutAchievementList, true, true)
end

function UIWidgetReadAchievementListTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetReadAchievementListTip:BindUIEvent()
    for nIndex, BtnTrace in ipairs(self.tbTraceAchievement) do
        UIHelper.BindUIEvent(BtnTrace, EventType.OnClick, function ()
            if nIndex > #self.tAchievements then return end
            local aAchievement = Table_GetAchievement(self.tAchievements[nIndex])
            UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
        end)
    end
end

function UIWidgetReadAchievementListTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetReadAchievementListTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetReadAchievementListTip:UpdateInfo()
    for nIndex, LabelName in ipairs(self.tbReadAchievementListName) do
        local LabelCount = self.tbAchievementCount[nIndex]
        local LabelState = self.tbAchievementState[nIndex]
        local aAchievement = Table_GetAchievement(self.tAchievements[nIndex]) 
        local szName = Table_GetAchievementName(aAchievement.dwID)
        szName = UIHelper.GBKToUTF8(szName)
        local _, nPoint = Table_GetAchievementInfo(aAchievement.dwID)
        local szPoint = tostring(nPoint or 0)
        local szState = "未完成"
        if g_pClientPlayer.IsAchievementAcquired(aAchievement.dwID) then szState = "<color=#00ff00>已完成</color>" end

        UIHelper.SetString(LabelName, szName)
        UIHelper.SetString(LabelCount, szPoint)
        UIHelper.SetRichText(LabelState, szState)
        UIHelper.LayoutDoLayout(UIHelper.GetParent(LabelCount))
    end    
end

return UIWidgetReadAchievementListTip