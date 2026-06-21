-- WidgetCareerCompeteListCell

local UICareerCompeteListCell = class("UICareerCompeteListCell")

function UICareerCompeteListCell:OnEnter(tData)
    self.tData = tData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if self.tData then
        self:UpdateInfo()
    end
end

function UICareerCompeteListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCompeteListCell:BindUIEvent()
    --
end

function UICareerCompeteListCell:RegEvent()
    --
end

function UICareerCompeteListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCompeteListCell:UpdateInfo()
    if self.tData.szTitle then
        UIHelper.SetString(self.LabeCompetelTitle, self.tData.szTitle)
    end

    if self.tData.imgPath then
        UIHelper.SetSpriteFrame(self.ImgDanGradingIcon, self.tData.imgPath)
    end

    if self.tData.szGrade then
        UIHelper.SetString(self.LabelCompeteDan, self.tData.szGrade)
    else
        UIHelper.SetString(self.LabelCompeteDan, "")
    end

    if self.tData.szScore then
        UIHelper.SetString(self.LabelCompeteGrade, self.tData.szScore)
    end
    
    if self.tData.nScore then
        UIHelper.SetString(self.LabelGradeNum, self.tData.nScore)
    else
        UIHelper.SetString(self.LabelGradeNum, "0")
    end

    if self.tData.szTotal then
        UIHelper.SetString(self.LabelSessionTitle, self.tData.szTotal)
    end

    if self.tData.nTotal then
        UIHelper.SetString(self.LabelSessionNum, self.tData.nTotal)
    else
        UIHelper.SetString(self.LabelSessionNum, "0")
    end

    if self.tData.szPerson then
        UIHelper.SetString(self.LabelWinsTitle, self.tData.szPerson)
    end

    if self.tData.nPerson then
        UIHelper.SetString(self.LabelWins, self.tData.nPerson)
    else
        UIHelper.SetString(self.LabelWins, "0")
    end
end

return UICareerCompeteListCell