local UIDungeonDifficultyHead = class("UIDungeonDifficultyHead")

function UIDungeonDifficultyHead:OnEnter(tRecord)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tRecord = tRecord
    self:UpdateInfo()
end

function UIDungeonDifficultyHead:OnExit()
    self.bInit = false
end

function UIDungeonDifficultyHead:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fOnSelectedCallBack then
            self.fOnSelectedCallBack(true)
        end
    end)
end

function UIDungeonDifficultyHead:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonDifficultyHead:UpdateInfo()
    local tRecord = self.tRecord
    local szLayer3Name = tRecord.szLayer3Name

    UIHelper.SetString(self.LabelNormal, szLayer3Name)
    UIHelper.SetString(self.LabelUp, szLayer3Name)
    UIHelper.SetVisible(self.WidgetDaily, DungeonData.tbFlagMap[tRecord.dwMapID] == 1)
    UIHelper.SetVisible(self.WidgetWeekly, DungeonData.tbFlagMap[tRecord.dwMapID] == 2)
end

function UIDungeonDifficultyHead:SetSelectedCallBack(fOnSelectedCallBack)
    self.fOnSelectedCallBack = fOnSelectedCallBack
end

return UIDungeonDifficultyHead