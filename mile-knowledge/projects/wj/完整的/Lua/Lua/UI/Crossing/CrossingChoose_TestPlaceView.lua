-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingChoose_TestPlaceView
-- Date: 2023-03-28 16:56:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

CrossingChoose_TestPlaceView = class("CrossingChoose_TestPlaceView")

function CrossingChoose_TestPlaceView:OnEnter(tbRoot)
    self.tbRoot = tbRoot
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    self:UpdateUI()
end

function CrossingChoose_TestPlaceView:OnExit()
    self.bInit = false
    self:UnRegEvent()

end
function CrossingChoose_TestPlaceView:BindUIEvent()
    for index = 1, table.get_len(self.tbRoot.tbTogTab) do
        UIHelper.BindUIEvent(self.tbRoot.tbTogTab[index], EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                if self.currentTog then
                    UIHelper.SetSelected(self.currentTog, false)
                end
                self.currentTog = btn
                self.nCurInitChooseIndex = index
                RemoteCallToServer("On_Trial_InitCChoose", (index - 1) * 20 , index * 20 )
            end
        end)

        UIHelper.ToggleGroupAddToggle(self.tbRoot.TogGroupLine, self.tbRoot.tbTogTab[index])
    end

end

function CrossingChoose_TestPlaceView:RegEvent()
    Event.Reg(self, EventType.On_Trial_GetWeekRemainCard, function (nWeekResetCard)
        UIHelper.SetString(self.tbRoot.LabelTestPlaceWeek, string.format("周翻牌次数:%d次", nWeekResetCard) )
    end)

    Event.Reg(self, EventType.On_Trial_InitCChooseReturn, function (tLevelData)
        self:ChangeCellInfo(self.nCurInitChooseIndex)
    end)
end

function CrossingChoose_TestPlaceView:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingChoose_TestPlaceView:UpdateInfo()

    self.cellscriptViews = {}
    self.currentTog = nil
    self.tbData = CrossingData.tbTestPlaceData
    -- 获取层数区间
	self.nLevelInteral = math.floor((self.tbData.nLevel - 1) / CrossingData.nMaxCellNumber) * CrossingData.nMaxCellNumber --0、20、40、60、80
    -- 获取当前层级
    self.nDetailShowLevel = self.tbData.tbLevelData.nCurrentLevel
    if self.nDetailShowLevel > self.nLevelInteral and self.nDetailShowLevel <= self.nLevelInteral + CrossingData.nMaxCellNumber then
        self.tbCurrentLevelData = self.tbData.tbLevelData.tCurrentLevelData
    end
    -- 预览区域ID
    self.nOpenAreaID =  math.ceil(self.tbData.tbLevelData.nTopLevel / CrossingData.nMaxCellNumber)
    if self.nOpenAreaID == 0 then
        self.nOpenAreaID = 1
    end
    self.nPreAreaID = math.ceil(self.nDetailShowLevel / CrossingData.nMaxCellNumber)
    if self.nPreAreaID == 0 then
        self.nPreAreaID = 1
    end
end

function CrossingChoose_TestPlaceView:UpdateUI()
    UIHelper.SetVisible(self.tbRoot.LayoutTog,true)
    UIHelper.SetVisible(self.tbRoot.LayoutTestPlaceScore,true)
    UIHelper.SetVisible(self.tbRoot.WidgetAnchorBottom,false)
    self:UpdateTotalScore()
    self:UpdatePanelTitle()
    self:UpdateLevelTog()
    self:UpdateCell()
    self:ChangeCellInfo(self.nPreAreaID)
    UIHelper.SetString(self.tbRoot.LabelTestPlaceWeek, "")
    RemoteCallToServer("On_Trial_GetWeekRemainCard")
end

--试炼之地
function CrossingChoose_TestPlaceView:UpdateTotalScore()
    UIHelper.SetString(self.tbRoot.LabelTestPlaceScore,string.format("%s %d", CrossingData.szChooseTotaleScoreName,  self.tbData.nTotalScore))
end

function CrossingChoose_TestPlaceView:UpdatePanelTitle()
    if self.tbRoot.LabelTitle then
        UIHelper.SetString(self.tbRoot.LabelTitle, CrossingData.CrossingTitleName)
    end
end

function CrossingChoose_TestPlaceView:UpdateCell()
    UIHelper.RemoveAllChildren(self.tbRoot.ScrollViewTestPlace)
    UIHelper.RemoveAllChildren(self.tbRoot.LayoutTestPlaceLess5)
    local startIndex = (self.nPreAreaID - 1)* CrossingData.nMaxCellNumber
    local layout = self.tbData.tbLevelData.nTopLevel > 5 and self.tbRoot.ScrollViewTestPlace or self.tbRoot.LayoutTestPlaceLess5
    for nIndex = 1, CrossingData.nMaxCellNumber do
        local nLevel = nIndex + startIndex
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTestPlaceCell, layout)
        if scriptView then
            if nIndex == 1 then
                CrossingData.WidgetTestPlaceCellPosionY =  UIHelper.GetPositionY(scriptView.WidgetTestPlaceCellPosion)
            end

            scriptView:OnEnter(nIndex, nLevel , self.tbData.tbLevelData)
            table.insert(self.cellscriptViews, scriptView)
        end
    end
    UIHelper.LayoutDoLayout(self.tbRoot.LayoutTestPlaceLess5)
    UIHelper.ScrollViewDoLayout(self.tbRoot.ScrollViewTestPlace)
    Timer.Add(self , 0.2 , function ()
        local scrollToIndex = (self.nDetailShowLevel -1) % CrossingData.nMaxCellNumber
        UIHelper.ScrollToIndex(self.tbRoot.ScrollViewTestPlace, scrollToIndex)
    end)
end

function CrossingChoose_TestPlaceView:ChangeCellInfo(togIndex)
    local startIndex = (togIndex - 1)* CrossingData.nMaxCellNumber
    for k, v in ipairs( self.cellscriptViews) do
        v:OnEnter(k , startIndex + k , self.tbData.tbLevelData)
    end
    UIHelper.ScrollViewDoLayout(self.tbRoot.ScrollViewTestPlace)
    -- 当前挑战的ID 在此Toggle 区域内
    Timer.Add(self , 0.2 , function ()
        if togIndex == self.nPreAreaID then
            local scrollToIndex = (self.nDetailShowLevel -1) % CrossingData.nMaxCellNumber
            UIHelper.ScrollToIndex(self.tbRoot.ScrollViewTestPlace, scrollToIndex)
        else
            UIHelper.ScrollToLeft(self.tbRoot.ScrollViewTestPlace)
        end
    end)
end

function CrossingChoose_TestPlaceView:UpdateLevelTog()
    for i, v in ipairs(self.tbRoot.tbTogTab) do
        UIHelper.SetVisible(v , i <= self.nOpenAreaID and self.nOpenAreaID > 1)
    end

    for i, v in ipairs(self.tbRoot.tbTogLine) do
        UIHelper.SetVisible(v , i+1 <= self.nOpenAreaID)
    end

    UIHelper.LayoutDoLayout(self.LayoutTog)
    self.currentTog = self.tbRoot.tbTogTab[self.nPreAreaID ]
    UIHelper.SetToggleGroupSelectedToggle(self.tbRoot.TogGroupLine, self.currentTog)
end