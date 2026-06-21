-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingChoose_FourFightView
-- Date: 2023-03-28 17:00:07
-- Desc: 四时论武
-- ---------------------------------------------------------------------------------
CrossingChoose_FourFightView = class("CrossingChoose_FourFightView")

function CrossingChoose_FourFightView:OnEnter(tbRoot)
    self.tbRoot = tbRoot
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    GetClientPlayer().ApplyRemoteData(NewTrialValley.tbCustomData.REMOTE_NEWTRIAL_CUSTOM)
    self:UpdateInfo()
    self:UpdateBaseUI()
end

function CrossingChoose_FourFightView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CrossingChoose_FourFightView:BindUIEvent()
    for index = 1, table.get_len(self.tbRoot.tbBottomTogList) do
        UIHelper.BindUIEvent(self.tbRoot.tbBottomTogList[index], EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                if self.selectTog then
                    UIHelper.SetSelected(self.selectTog, false)
                end
                self.selectTog = btn
                self.nSelectType = index
                self:UpdateCellInfo(index)
            end
        end)

    end
end

function CrossingChoose_FourFightView:RegEvent()
    Event.Reg(self , "CAREER_TRAIN_GYM_CUSTOM_DATA" , function (arg0 , arg1)
        if arg0 ~= GetClientPlayer().dwID or arg1 ~= NewTrialValley.tbCustomData.REMOTE_NEWTRIAL_CUSTOM then
			return
        end
        if not IsUITableRegister("TrialValley") then
            local tData =
            {
                KeyNum = 2,
                Path = "\\UI\\Scheme\\Case\\TrialValley.tab",
                Title =
                {
                    {f = "i", t = "nType"},
                    {f = "i", t = "nLevel"},
                    {f = "s", t = "szTypeName"},
                    {f = "p", t = "szTypePath"},
                    {f = "i", t = "nNormalFrame"},
                    {f = "i", t = "nHighFrame"},
                    {f = "i", t = "nPassNormal"},
                    {f = "i", t = "nPassHigh"},
                    {f = "i", t = "nDisableNormal"},
                    {f = "i", t = "nDisableHigh"},
                    {f = "S", t = "szDesc"},
                }
            }
            RegisterUITable("TrialValley", tData.Path, tData.Title, tData.KeyNum)
        end
        NewTrialValley:UpdateDataModel(GetClientPlayer())
        self.tbModelData = NewTrialValley.tbModelData
        self:UpdateToggleInfo()
    end)
end

function CrossingChoose_FourFightView:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingChoose_FourFightView:UpdateInfo()
    self.cellscriptViews = {}
    self.currentBottomTog = nil
    self.selectTog = nil
end

function CrossingChoose_FourFightView:UpdateBaseUI()
    -- 试炼之地内容隐藏
    UIHelper.SetVisible(self.tbRoot.LayoutTestPlaceScore,false)
    UIHelper.SetVisible(self.tbRoot.LayoutTog,false)
    UIHelper.SetVisible(self.tbRoot.WidgetLine,false)
    UIHelper.SetVisible(self.tbRoot.LabelTestPlaceWeek,false)
    UIHelper.SetVisible(self.tbRoot.ImgBtnLine,false)

    -- 开启四时论武内容
    UIHelper.SetVisible(self.tbRoot.WidgetAnchorBottom,true)
    self:UpdatePanelTitle()
    self:LoadCell()
end

function CrossingChoose_FourFightView:UpdatePanelTitle()
    if self.tbRoot.LabelTitle then
        UIHelper.SetString(self.tbRoot.LabelTitle, CrossingData.SiShiTitleName)
    end
end

function CrossingChoose_FourFightView:LoadCell()
    UIHelper.RemoveAllChildren(self.tbRoot.ScrollViewTestPlace)
    UIHelper.RemoveAllChildren(self.tbRoot.LayoutTestPlaceLess5)
    for nIndex = 1, CrossingData.nMaxCellNumber do
        table.insert(self.cellscriptViews, UIHelper.AddPrefab(PREFAB_ID.WidgetTestPlaceCell, self.tbRoot.ScrollViewTestPlace))
    end
    UIHelper.ScrollViewDoLayout(self.tbRoot.ScrollViewTestPlace)
end

function CrossingChoose_FourFightView:UpdateCellInfo(togIndex)
    local tbTypeData = self.tbModelData[togIndex]
    local maxLevel =  math.min(tbTypeData.nTopLevel + 1, self.tbModelData.nMaxLevel)
    for nLevel, v in ipairs( self.cellscriptViews) do
        local bVisible = nLevel <= maxLevel
        if nLevel == 1 then
            CrossingData.WidgetTestPlaceCellPosionY =  UIHelper.GetPositionY(v.WidgetTestPlaceCellPosion)
        end
        v:OnEnter(nLevel ,  nLevel , tbTypeData , bVisible , togIndex)
    end
    UIHelper.ScrollViewDoLayout(self.tbRoot.ScrollViewTestPlace)
    Timer.Add(self , 0.2 , function ()
        local index = (tbTypeData.nCurrentLevel -1) % tbTypeData.nTopLevel
        if tbTypeData.nCurrentLevel >= tbTypeData.nTopLevel then
            index = tbTypeData.nTopLevel
        end
        UIHelper.ScrollToIndex(self.tbRoot.ScrollViewTestPlace, index)
    end)
end

function CrossingChoose_FourFightView:UpdateToggleInfo()
    local nCount = 0
    for nType, v in pairs(self.tbRoot.tbBottomTogList) do
        if self.tbModelData[nType] then
            nCount = nCount + 1
            UIHelper.SetVisible(self.tbRoot.tbBottomTogList[nType] ,true)
            UIHelper.SetString(self.tbRoot.tbBottomTogLabelList[nType],TRAIL_TYPE_NAME[nType])
            UIHelper.SetString(self.tbRoot.tbBottomLabelSelectList[nType],TRAIL_TYPE_NAME[nType])
        else
            UIHelper.SetVisible(self.tbRoot.tbBottomTogList[nType] , false)
        end
    end
    UIHelper.LayoutDoLayout(self.tbRoot.LayoutNavigationSishi)
    UIHelper.SetVisible(self.tbRoot.WidgetAnchorBottom , nCount > 1)
    UIHelper.SetSelected(self.tbRoot.tbBottomTogList[self.tbModelData.nCurrentType], true)
end