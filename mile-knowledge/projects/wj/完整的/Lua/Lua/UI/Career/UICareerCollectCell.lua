-- WidgetCareerCollectCell

local UICareerCollectCell = class("UICareerCollectCell")

function UICareerCollectCell:OnEnter(tData, nIndex)
    self.tData = tData
    self.nIndex = nIndex
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerCollectCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCollectCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCareerCollect, EventType.OnClick, function ()
        if self.nIndex then
            FireUIEvent("CareerCollectCellClick", self.nIndex)
        end
    end)
end

function UICareerCollectCell:RegEvent()
    --
end

function UICareerCollectCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCollectCell:UpdateInfo()
    if self.tData then
        UIHelper.SetString(self.LabelCareerCollect, self.tData.szName)
        UIHelper.SetString(self.LabelCareerCollectNum, self.tData.nNum)
    end
    if not self.nIndex then
        UIHelper.SetVisible(self.BtnCareerCollect, false)
    end
end

return UICareerCollectCell