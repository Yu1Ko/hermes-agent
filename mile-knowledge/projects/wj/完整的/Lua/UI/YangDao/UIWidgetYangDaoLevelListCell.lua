-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetYangDaoLevelListCell
-- Date: 2026-03-02 10:56:37
-- Desc: 扬刀大会-挑战进度分页-关卡详情 按钮 WidgetYangDaoLevelListCell (PanelYangDaoOverview/WidgetPageProgress)
-- ---------------------------------------------------------------------------------

local UIWidgetYangDaoLevelListCell = class("UIWidgetYangDaoLevelListCell")

function UIWidgetYangDaoLevelListCell:OnEnter(nLevelIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLevelIndex = nLevelIndex
    self:UpdateInfo()
end

function UIWidgetYangDaoLevelListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYangDaoLevelListCell:BindUIEvent()
    UIHelper.SetClickInterval(self.TogCell, 0)
    UIHelper.BindUIEvent(self.TogCell, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and self.fnCallback then
            self.fnCallback()
        end
    end)
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function()
        if self.bSelected then
            UIHelper.SetSelected(self.TogCell, true, false)
        end
    end)
end

function UIWidgetYangDaoLevelListCell:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerOverviewLevelDetail, function(nLevelIndex, bMapFlag)
        self:SetSelected(nLevelIndex == self.nLevelIndex, false)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 4, function()
            UIHelper.LayoutDoLayout(self.LayoutContent)
        end)
    end)
end

function UIWidgetYangDaoLevelListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetYangDaoLevelListCell:UpdateInfo()
    local tLevelConfig = ArenaTowerData.GetLevelConfig(self.nLevelIndex)
    if not tLevelConfig then
        return
    end

    UIHelper.SetString(self.LabelNum, self.nLevelIndex)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tLevelConfig.szName))
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIWidgetYangDaoLevelListCell:SetCurrent(bCurrent)
    UIHelper.SetVisible(self.ImgIconCurrent, bCurrent)
end

function UIWidgetYangDaoLevelListCell:SetUnlock(bUnlock)
    UIHelper.SetVisible(self.ImgIconLocked, not bUnlock)
end

function UIWidgetYangDaoLevelListCell:SetSpecial(bSpecial)
    UIHelper.SetVisible(self.ImgSpecialIcon, bSpecial)
end

function UIWidgetYangDaoLevelListCell:SetProgressState(bClearLevel, bCurrentLevel)
    UIHelper.SetVisible(self.ImgBg01, not bClearLevel and not bCurrentLevel)
    UIHelper.SetVisible(self.ImgBg02, bClearLevel or bCurrentLevel)
    UIHelper.SetVisible(self.ImgCheck, bClearLevel)
end

-- ArenaTowerLevelState
function UIWidgetYangDaoLevelListCell:SetLevelState(nLevelState)
    if nLevelState == ArenaTowerLevelState.Incomplete then
        UIHelper.SetVisible(self.ImgIconLocked, true)
        -- UIHelper.SetVisible(self.LayoutRewardIcon, false)
    else
        UIHelper.SetVisible(self.ImgIconLocked, false)
        -- UIHelper.SetVisible(self.LayoutRewardIcon, true)
    end
    local szPracticeIconPath, szChallengeIconPath = ArenaTowerData.GetDiffIcon(nLevelState)
    UIHelper.SetSpriteFrame(self.ImgIconPractice, szPracticeIconPath)
    UIHelper.SetSpriteFrame(self.ImgIconChallenge, szChallengeIconPath)
end

function UIWidgetYangDaoLevelListCell:SetSelectedCallback(fnCallback)
    self.fnCallback = fnCallback
end

function UIWidgetYangDaoLevelListCell:SetSelected(bSelected, bCallback)
    self.bSelected = bSelected
    UIHelper.SetSelected(self.TogCell, bSelected, bCallback)
end

return UIWidgetYangDaoLevelListCell