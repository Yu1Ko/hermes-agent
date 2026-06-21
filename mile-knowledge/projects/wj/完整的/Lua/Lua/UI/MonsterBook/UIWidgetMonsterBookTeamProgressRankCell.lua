local UIWidgetMonsterBookTeamProgressRankCell = class("UIWidgetMonsterBookTeamProgressRankCell")

function UIWidgetMonsterBookTeamProgressRankCell:OnEnter(szText, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szText = szText
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookTeamProgressRankCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookTeamProgressRankCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then self.fCallBack() end
    end)
end

function UIWidgetMonsterBookTeamProgressRankCell:RegEvent()

end

function UIWidgetMonsterBookTeamProgressRankCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookTeamProgressRankCell:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, self.szText)
    UIHelper.SetString(self.LabelUp, self.szText)
end

return UIWidgetMonsterBookTeamProgressRankCell