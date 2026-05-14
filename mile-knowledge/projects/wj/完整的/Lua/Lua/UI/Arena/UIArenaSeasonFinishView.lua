-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaSeasonFinishView
-- Date: 2024-04-20 20:26:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaSeasonFinishView = class("UIArenaSeasonFinishView")

local TITLE_OLD = "二十七届名剑大会段位结算"
local TITLE_NEW = "二十八届名剑大会段位继承"

function UIArenaSeasonFinishView:OnEnter(aOldLevels, aNewLevels)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nStep = 1

    self.aOldLevels = aOldLevels
    self.aNewLevels = aNewLevels
    self:UpdateInfo()
end

function UIArenaSeasonFinishView:OnExit()
    self.bInit = false
end

function UIArenaSeasonFinishView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function(btn)
        if self.nStep == 1 then
            self.nStep = 2
            UIHelper.SetButtonState(self.BtnContinue, BTN_STATE.Disable)
            Timer.Add(self, 1, function ()
                UIHelper.SetButtonState(self.BtnContinue, BTN_STATE.Normal)
            end)

            self:UpdateInfo()
            UIHelper.PlayAni(self, self.AniAll, "AniBaizhanChooseBuff_Show")
        else
            UIMgr.Close(self)
        end
    end)

end

function UIArenaSeasonFinishView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaSeasonFinishView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, TITLE_OLD)

    local tLevels = self.aOldLevels
    if self.nStep == 2 then
        tLevels = self.aNewLevels
        UIHelper.SetString(self.LabelTitle, TITLE_NEW)
    end

    for i, widget in ipairs(self.tbWidgetMode) do
        local label = self.tbLabelMode[i]
        local img = self.tbImgModeIcon[i]

        local nLevel = tLevels[i] or 0
        if nLevel > 0 then
            UIHelper.SetVisible(widget, true)
            local tLevelInfo = TabHelper.GetUIArenaRankLevelTab(nLevel)
            if tLevelInfo then
                UIHelper.SetString(label, string.format("%d%s%s%s", nLevel, g_tStrings.STR_DUAN, g_tStrings.STR_CONNECT, tLevelInfo.szTitle))
                UIHelper.SetSpriteFrame(img, tLevelInfo.szBigIcon)
            end
        else
            UIHelper.SetVisible(widget, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutJJCScoreList)
end


return UIArenaSeasonFinishView