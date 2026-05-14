-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFurnitureReward
-- Date: 2023-05-22 17:10:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFurnitureReward = class("UIFurnitureReward")

function UIFurnitureReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIFurnitureReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFurnitureReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnMask,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSkip,EventType.OnClick,function ()
        local tAllLinkInfo = Table_GetCareerGuideAllLink(2333)
		if #tAllLinkInfo > 0 then
			local tbTravel = tAllLinkInfo[1]
			MapMgr.SetTracePoint("阎矩", tbTravel.dwMapID, {tbTravel.fX, tbTravel.fY, tbTravel.fZ})
			HomelandData.CheckIsHomelandMapTeleportGo(2333, tbTravel.dwMapID, nil, nil, function ()
				UIMgr.Close(VIEW_ID.PanelFurnitureReward)
				UIMgr.Close(VIEW_ID.PanelHome)
			end)
		end
    end)

    UIHelper.BindUIEvent(self.BtnLeftPaging,EventType.OnClick,function ()
        if self.bIsHomelandPage then
            self:ScrollOnePage(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRightPaging,EventType.OnClick,function ()
        if self.bIsHomelandPage then
            self:ScrollOnePage(true)
        end
    end)
end

function UIFurnitureReward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFurnitureReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFurnitureReward:UpdateInfo()

end

function UIFurnitureReward:UpdateWuLinTongJianAward(tAwardInfo)
    UIHelper.SetString(self.LabelFurnitureRewardTitle,"奖励预览")
    UIHelper.SetVisible(self.WidgetAnchorBottonLabel,false)
    UIHelper.SetVisible(self.WidgteAnchorFurnitureCount,false)
    UIHelper.SetVisible(self.WidgetAnchorHome,false)
    UIHelper.SetVisible(self.WidgetAnchorWuLinTongJian,true)
    for i = 1,4 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetWLTJAward,self.LayoutFurnitureReward,tAwardInfo[i])
    end
    UIHelper.LayoutDoLayout(self.LayoutFurnitureReward)
end

function UIFurnitureReward:UpdateFurnitureRewardInfo(DataModel)
    self.bIsHomelandPage = true

    UIHelper.SetVisible(self.WidgetAnchorHome, true)
    UIHelper.SetVisible(self.WidgetAnchorWuLinTongJian, false)
    local nTotalPoints = DataModel.GetTotalCollectPoints()
    local aAllRewardInfos = DataModel.GetAllCollectPointsLevelAwardInfos()
	for nIndex, tInfo in ipairs(aAllRewardInfos) do
        local nTotalCollectPoints = DataModel.GetTotalCollectPoints()
	    local nCPLevel, nPointsInLevel, nDestPointsInLevel = DataModel.GetLevelValuesByTotalCollectPoints(nTotalCollectPoints)
        scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureRewardCell, self.ScrollViewFurnitureReward)
        scriptCell:OnEnter(nIndex, tInfo, nCPLevel, nPointsInLevel, nDestPointsInLevel, nIndex == #aAllRewardInfos)
    end
    UIHelper.SetString(self.LabelFurnitureCountNum, tostring(nTotalPoints))
    UIHelper.ScrollViewDoLayout(self.ScrollViewFurnitureReward)
    UIHelper.ScrollToLeft(self.ScrollViewFurnitureReward, 0)
end

function UIFurnitureReward:UpdateHomeIdentityAward(dwID)
    local tRewardState   = GDAPI_GetHLIdentityRewardInfo(dwID)
    local tRewardType    = Table_GetHLRewardType(dwID)
    local tAllRewardInfo = Table_GetAllHLReward(dwID)
    for i = 1, #tAllRewardInfo do
        local tbInfo = {tRewardInfo = tAllRewardInfo[i], nRewardState = tRewardState[i]}
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeIdentityRewardCell, self.LayoutFurnitureReward)
        script:OnEnter(tbInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutFurnitureReward)
    UIHelper.SetVisible(self.WidgetAnchorBottonLabel,false)
    UIHelper.SetVisible(self.WidgteAnchorFurnitureCount,false)
    UIHelper.SetVisible(self.WidgetAnchorHome,false)
    UIHelper.SetVisible(self.WidgetAnchorWuLinTongJian,true)
    -- UIHelper.SetString(self.LabelFurnitureRewardTitle,UIHelper.GBKToUTF8(tRewardType.szName))
end

function UIFurnitureReward:ScrollOnePage(bAdd)
    local layout = self.ScrollViewFurnitureReward:getInnerContainer()
    if not layout then
        return
    end

    local nLayoutWidth, _ = UIHelper.GetContentSize(layout)
    local nScreenWidth, _ = UIHelper.GetContentSize(self.ScrollViewFurnitureReward)
    local nOnePagePercent = nScreenWidth / nLayoutWidth * 100

    local nCurPercent = UIHelper.GetScrollPercent(self.ScrollViewFurnitureReward)
    local nNewPercent
    if bAdd then
        nNewPercent = nCurPercent + nOnePagePercent
    else
        nNewPercent = nCurPercent - nOnePagePercent
    end
    if nNewPercent <= 1 then    --nOnePagePercent不被整数，接近直接到底
        UIHelper.ScrollToPercent(self.ScrollViewFurnitureReward, 0)
    elseif nNewPercent >= 99 then
        UIHelper.ScrollToPercent(self.ScrollViewFurnitureReward, 100)
    else
        UIHelper.ScrollToPercent(self.ScrollViewFurnitureReward, nNewPercent)
    end
end

return UIFurnitureReward