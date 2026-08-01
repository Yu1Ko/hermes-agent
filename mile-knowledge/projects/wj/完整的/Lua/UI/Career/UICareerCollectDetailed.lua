--WidgetCollectDetailedPendant

local UICareerCollectDetailed = class("UICareerCollectDetailed")
local maxDetailedNum = 11

function UICareerCollectDetailed:OnEnter(tName, tNum)
    self.tName = tName
    self.tNum = tNum
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerCollectDetailed:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCollectDetailed:Init()

end

function UICareerCollectDetailed:BindUIEvent()

end

function UICareerCollectDetailed:RegEvent()
    --
end

function UICareerCollectDetailed:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCollectDetailed:UpdateInfo()
    if self.tName and self.tNum then
        local totalInfo = {szName = self.tName.total, nNum = self.tNum.total}
        UIHelper.AddPrefab(PREFAB_ID.WidgetCareerCollectCell, self.WidgetCareerCollect, totalInfo)

        local nDetailSize = #self.tNum.detail
        local nAdd = math.modf(maxDetailedNum / nDetailSize)
        local nWidgetIndex = 1
        for i = 1, nDetailSize do
            local detailSript = UIHelper.AddPrefab(PREFAB_ID.WidgetBranchCell, self.tbWidgetCollect[nWidgetIndex]) assert(detailSript)
            nWidgetIndex = nWidgetIndex + nAdd
            local detailInfo = {szName = self.tName.detail[i], nNum = self.tNum.detail[i]}
            detailSript:OnEnter(detailInfo)
        end
    end
end

return UICareerCollectDetailed