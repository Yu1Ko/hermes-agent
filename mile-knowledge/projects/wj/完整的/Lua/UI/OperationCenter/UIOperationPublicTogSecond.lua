-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationPublicTogSecond
-- Date: 2026-03-19 17:43:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationPublicTogSecond = class("UIOperationPublicTogSecond")

function UIOperationPublicTogSecond:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = TabHelper.GetHuaELouActivityByOperationID(tInfo.dwID)
    local nRedPointID = tActivity.nRedPointID
    if nRedPointID and nRedPointID > 0 then
        RedpointMgr.RegisterRedpoint(self.ImgRedDot, nil, {nRedPointID})
        RedpointMgr.RegisterRedpoint(self.ImgRedDotSelect, nil, {nRedPointID})
    end

    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    UIHelper.SetString(self.LabelNormal, szName)
    UIHelper.SetString(self.LabelSelect, szName)

    local szSub = UIHelper.GBKToUTF8(tInfo.szTitle)
    UIHelper.SetString(self.LabelSubNormal, szSub)
    UIHelper.SetVisible(self.LabelSubNormal, szSub ~= "")
    UIHelper.SetVisible(self.ImgBgTitleLine, szSub ~= "")
    UIHelper.LayoutDoLayout(self.LayoutNameNormalTitle)
    UIHelper.LayoutDoLayout(self.LayoutNameNormal)

    UIHelper.SetString(self.LabelSubSelect, szSub)
    UIHelper.SetVisible(self.LabelSubSelect, szSub ~= "")
    UIHelper.SetVisible(self.ImgBgTitleLineSelect, szSub ~= "")
    UIHelper.LayoutDoLayout(self.LayoutNameSelectTitle)
    UIHelper.LayoutDoLayout(self.LayoutNameSelect)

    UIHelper.SetToggleGroupIndex(self.TogSecondNav, ToggleGroupIndex.OperationCenterTogSecond)

    Timer.AddCycle(self, 0.1, function()
        local bHasRedPoint = UIHelper.GetVisible(self.ImgRedDot) or UIHelper.GetVisible(self.ImgRedDotSelect)
        if not bHasRedPoint then
            local bHasNewPoint = OperationCenterData.IsShowNew(tInfo.dwID)
            self:SetNewVisible(bHasNewPoint)
        end

        --UIHelper.SetVisible(self.ImgRedDot, not bHasRedPoint)
        --UIHelper.SetVisible(self.ImgRedDotSelect, not bHasRedPoint)

        UIHelper.LayoutDoLayout(self.LayoutNameNormalTitle)
        UIHelper.LayoutDoLayout(self.LayoutNameNormal)
        UIHelper.LayoutDoLayout(self.LayoutNameSelectTitle)
        UIHelper.LayoutDoLayout(self.LayoutNameSelect)
    end)
end

function UIOperationPublicTogSecond:OnExit()
    self.bInit = false
    self:UnRegEvent()

     RedpointMgr.UnRegisterRedpoint(self.ImgRedDot)
     RedpointMgr.UnRegisterRedpoint(self.ImgRedDotSelect)
end

function UIOperationPublicTogSecond:BindUIEvent()

end

function UIOperationPublicTogSecond:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationPublicTogSecond:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationPublicTogSecond:UpdateInfo()

end

function UIOperationPublicTogSecond:SetNewVisible(bNew)
    UIHelper.SetVisible(self.ImgNewDot, bNew)
    UIHelper.SetVisible(self.ImgNewDotSelect, bNew)
    UIHelper.LayoutDoLayout(self.LayoutNameNormalTitle)
    UIHelper.LayoutDoLayout(self.LayoutNameSelectTitle)
    UIHelper.LayoutDoLayout(self.LayoutNameNormal)
    UIHelper.LayoutDoLayout(self.LayoutNameSelect)
end


return UIOperationPublicTogSecond


