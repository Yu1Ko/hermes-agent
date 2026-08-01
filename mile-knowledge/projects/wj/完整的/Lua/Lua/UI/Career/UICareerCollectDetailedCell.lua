-- WidgetBranchCell

local UICareerCollectDetailedCell = class("UICareerCollectDetailedCell")

function UICareerCollectDetailedCell:OnEnter(tData)
    self.tData = tData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerCollectDetailedCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCollectDetailedCell:BindUIEvent()
    --
end

function UICareerCollectDetailedCell:RegEvent()
    --
end

function UICareerCollectDetailedCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCollectDetailedCell:UpdateInfo()
    if self.tData then
        UIHelper.SetString(self.LabelTypeName, self.tData.szName)
        UIHelper.SetString(self.LabelTypeNum, self.tData.nNum)
    end
end

return UICareerCollectDetailedCell