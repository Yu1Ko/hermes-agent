-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationPublicTogFrist
-- Date: 2026-03-19 20:17:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationPublicTogFrist = class("UIOperationPublicTogFrist")

function UIOperationPublicTogFrist:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateRedPoint()
    end)
end

function UIOperationPublicTogFrist:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationPublicTogFrist:BindUIEvent()

end

function UIOperationPublicTogFrist:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationPublicTogFrist:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationPublicTogFrist:UpdateInfo()
    local tInfo = self.tInfo
    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    UIHelper.SetString(self.LabelTitleNormal, szName)
    UIHelper.SetString(self.LabelTitleSelect, szName)

    UIHelper.SetToggleGroupIndex(self._rootNode, ToggleGroupIndex.OperationCenterTogFirst)

    self:UpdateRedPoint()
end

function UIOperationPublicTogFrist:UpdateRedPoint()
    local tOpenOperations = OperationCenterData.GetOpenOperations(self.tInfo.nCategoryID)
    local bHasRedPoint = false
    local bHasNewPoint = false
    for _, tOperationInfo in ipairs(tOpenOperations) do
        local tActivity = TabHelper.GetHuaELouActivityByOperationID(tOperationInfo.dwID)
        if tActivity and tActivity.nRedPointID ~= 0 then
            local condition = RedpoingConditions["Excute_" .. tActivity.nRedPointID]
            if IsFunction(condition) then
                local bResult = condition(tActivity.nRedPointID)
                if bResult then
                    bHasRedPoint = true
                    break
                end
            end
        end
        if OperationCenterData.IsShowNew(tOperationInfo.dwID) then
            bHasNewPoint = true
            break
        end
    end
    UIHelper.SetVisible(self.ImgRedPoint, bHasRedPoint or bHasNewPoint)
end


return UIOperationPublicTogFrist