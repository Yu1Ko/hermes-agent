-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAchievementGetCell
-- Date: 2023-11-30 17:39:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAchievementGetCell = class("UIWidgetAchievementGetCell")

function UIWidgetAchievementGetCell:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self.nStartTimer = nil
    self.nLastTimer = nil
    self:UpdateInfo()
end

function UIWidgetAchievementGetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAchievementGetCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseAchievementGet, EventType.OnClick, function()
        -- UIMgr.Close(self)
        Timer.DelAllTimer(self)
        self.tbData.callback(self._rootNode)
    end)
    UIHelper.BindUIEvent(self.BtnAchievement, EventType.OnClick, function()
        local aAchievement = self.tbData.aAchievement
        if not aAchievement then
            return
        end

        UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
        self.tbData.callback(self._rootNode)
    end)
end

function UIWidgetAchievementGetCell:RegEvent()
    Event.Reg(self, EventType.ShowQuickEquipTip, function(tbEquipItem)
        self:StopTimer()
    end)

    Event.Reg(self, EventType.OnQuickEquipTipClosed, function()
        self:StartTimer()
    end)
end

function UIWidgetAchievementGetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAchievementGetCell:UpdateInfo()
    local tbData = self.tbData
    UIHelper.SetString(self.LabelName, tbData.szName)
    UIHelper.SetString(self.LabelAchievementNum, tbData.nPoint)

    UIHelper.PlayAni(self, self.AniAchievementGet, "AniAchievementGetShow", function()
        self:StartTimer()
    end)
end

function UIWidgetAchievementGetCell:StartTimer()
    self.nStartTimer = Timer.RealMStimeSinceStartup()
    local callback = self.tbData.callback
    self.nTimer = Timer.Add(self, self.nLastTimer or 5, function()
        callback(self._rootNode)
    end)
    UIHelper.SetVisible(self._rootNode, true)
end

function UIWidgetAchievementGetCell:StopTimer()
    if self.nTimer then
        self.nLastTimer = math.floor((Timer.RealMStimeSinceStartup() - self.nStartTimer) / 1000)
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
    UIHelper.SetVisible(self._rootNode, false)
end


return UIWidgetAchievementGetCell