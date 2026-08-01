-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWuLinTongJianView
-- Date: 2023-05-15 16:34:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWuLinTongJianView = class("UIWuLinTongJianView")

local WuLinTongJianType = {
    ["Quest"] = "任务数量",
    ["Other"] = "其他成就",
    ["Dungeon"] = "秘境通关",
    ["Reputation"] = "声望钦佩",
}

function UIWuLinTongJianView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    self:InitDLCTabInfo()
    self:UpdateDLCScore()
end

function UIWuLinTongJianView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    UIMgr.Close(VIEW_ID.PanelUID)
    WulintongjianDate.bFirstOpenWuLingTongJianView = true
    Event.Dispatch(EventType.OnUpdateWuLinTongJianRedpoint)
end

function UIWuLinTongJianView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(VIEW_ID.PanelWuLinTongJianInner)
        UIMgr.Close(self)
    end)

    for nDLCID, Btn in pairs(self.tbDLCSelected) do
        UIHelper.BindUIEvent(Btn,EventType.OnClick,function ()
            if self.nCurrentDLCID ~= nDLCID then
                self.nCurrentDLCID = nDLCID
                self:UpdateDLCCellSelected()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnLeft ,EventType.OnClick,function ()
        if self.nCurrentDLCID > 1  then
            self.nCurrentDLCID = self.nCurrentDLCID - 1
            UIHelper.SetSelected(self.tbDLCSelected[self.nCurrentDLCID], true)
            self:UpdateDLCCellSelected()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick,function ()
        if self.nCurrentDLCID < WulintongjianDate.nDLCCount then
            self.nCurrentDLCID = self.nCurrentDLCID + 1
            UIHelper.SetSelected(self.tbDLCSelected[self.nCurrentDLCID], true)
            self:UpdateDLCCellSelected()
        end
    end)

    UIHelper.BindUIEvent(self.PageViewList, EventType.OnTurningPageView, function ()
        local nCurIndex = UIHelper.GetPageIndex(self.PageViewList) + 1
        if self.bSetPostion then
            self.nCurrentDLCID = nCurIndex
            UIHelper.SetSelected(self.tbDLCSelected[self.nCurrentDLCID], true)
            self:UpdateDLCCellSelected()
        else
            self.bSetPostion = true
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwordMemories, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelSwordMemories)
        UIMgr.CloseImmediately(self)
    end)
end

function UIWuLinTongJianView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "QUEST_FINISHED", function ()
        self:UpdateAwardState()
        WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
        self:UpdateCurMapInfo(self.viewScript)
        self:UpdateDLCInfoPage()
    end)

    Event.Reg(self, "SET_QUEST_STATE", function ()
        if not self.nAlllAward then
            self:UpdateAwardState()
            WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
            Timer.AddFrame(self, 4, function ()
                self:UpdateMapListRed()
            end)
            -- self:UpdateCurMapInfo(self.viewScript)
        end
    end)

    Event.Reg(self, EventType.OnWindowsMouseWheel, function ()
        if UIMgr.GetView(VIEW_ID.PanelWuLinTongJianInner) then
            return
        end
        local nCurIndex = UIHelper.GetPageIndex(self.PageViewList) + 1
        if self.nCurrentDLCID ~= nCurIndex then
            self.nCurrentDLCID = nCurIndex
            UIHelper.SetSelected(self.tbDLCSelected[self.nCurrentDLCID], true)
            self:UpdateDLCCellSelected()
        end
    end)
end

function UIWuLinTongJianView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWuLinTongJianView:InitDLCTabInfo()
    self.nCurrentDLCID = WulintongjianDate.nCurrentSelectedDLCID
    self.tDLCCellScript = {}

    self:UpdateDlcCell()

    Timer.AddFrameCycle(self, 1, function ()
        self:UpdateCellScale()
    end)
end

function UIWuLinTongJianView:UpdateDlcCell()
    for i = 1, WulintongjianDate.nDLCCount, 1 do
        local cellScript = UIHelper.PageViewAddPage(self.PageViewList, PREFAB_ID.WidgetWuLinTongJianCell, i <= 0 or i == WulintongjianDate.nDLCCount + 1)
        if cellScript then
            if i > 0 and i ~= WulintongjianDate.nDLCCount + 1 then
                if WulintongjianDate.tDLCImage[i] then
                    UIHelper.SetSpriteFrame(cellScript.ImgBg, WulintongjianDate.tDLCImage[i].szMobileNameImage)
                end
                UIHelper.SetVisible(cellScript.WidgetClose, i == WulintongjianDate.nDLCCount)
                UIHelper.BindUIEvent(cellScript.TogSelect, EventType.OnClick, function ()
                    self.nCurrentDLCID = i
                    if self.nCurrentDLCID == WulintongjianDate.nDLCCount then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_COMING_SOON)
                    else
                        self.bSetPostion = false
                        WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
                        self:UpdateDLCInfoPage()
                    end
                end)

                table.insert(self.tDLCCellScript, cellScript)
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.PageViewList)

    Timer.Add(self, 0.05, function ()
        self.bSetPostion = true
        UIHelper.SetPageIndex(self.PageViewList, self.nCurrentDLCID - 1)
    end)

    self:UpdateDLCCellSelected()
end

local ScaleSize = 0.5
function UIWuLinTongJianView:UpdateCellScale()
    local sceneSize = UIHelper.GetCurResolutionSize()
    local nCenterX = sceneSize.width / 2
    for i, cell in ipairs(self.tDLCCellScript) do
        local x, y = UIHelper.GetWorldPosition(cell._rootNode)
        local width, height = UIHelper.GetContentSize(cell._rootNode)
        local aX, aY = UIHelper.GetAnchorPoint(cell._rootNode)
        local sX, sY = UIHelper.GetScale(cell._rootNode)

        local fRealX = x + sX * width * (0.5 - aX)
        local fScale = math.abs(nCenterX - fRealX) / nCenterX
        fScale = math.min(1, fScale)
        local nFixX, nFixY = width * fScale * ScaleSize / 2, height * fScale * ScaleSize / 2

        fScale = (1 - fScale * ScaleSize)
        UIHelper.SetScale(cell._rootNode, fScale, fScale)
        UIHelper.SetPosition(cell._rootNode, nFixX, nFixY)
        -- local nOpacity = 255 * fScale * fScale * fScale
        -- UIHelper.SetOpacity(cell.WidgetCellScale, nOpacity)
    end
end

function UIWuLinTongJianView:UpdateDLCCellSelected()
    for i, cellScript in pairs(self.tDLCCellScript) do
        if WulintongjianDate.tDLCImage[i] then
            if self.nCurrentDLCID == i and self.nCurrentDLCID ~= WulintongjianDate.nDLCCount then
                UIHelper.SetSpriteFrame(cellScript.ImgBg, WulintongjianDate.tDLCImage[i].szMobileNameImage)
            else
                UIHelper.SetSpriteFrame(cellScript.ImgBg, WulintongjianDate.tDLCImage[i].szMobileNameImageBlack)
            end
        end
    end

    UIHelper.SetVisible(self.BtnLeft, self.nCurrentDLCID > 1)
    UIHelper.SetVisible(self.BtnRight, self.nCurrentDLCID < WulintongjianDate.nDLCCount)

    Timer.AddFrame(self, 1, function ()
        UIHelper.SetPageIndex(self.PageViewList, self.nCurrentDLCID - 1)
        UIHelper.SetSelected(self.tbDLCSelected[self.nCurrentDLCID], true)
    end)

    WulintongjianDate.SetCurDLCID(self.nCurrentDLCID)
end

function UIWuLinTongJianView:UpdateDLCScore()
    WulintongjianDate.GetDLCScore()
    local bRotPoint = false

    for nDLCID = 1, WulintongjianDate.nDLCCount - 1 do
        UIHelper.SetString(self.tDLCCellScript[nDLCID].LabelNum, WulintongjianDate.tDLCScore[nDLCID].nFinishNum .. "/" .. WulintongjianDate.tDLCScore[nDLCID].nTotal)
        UIHelper.SetVisible(self.tDLCCellScript[nDLCID].WidgetDone, WulintongjianDate.tDLCScore[nDLCID].nFinishNum == WulintongjianDate.tDLCScore[nDLCID].nTotal)
        UIHelper.SetVisible(self.tbDLCComplete[nDLCID], WulintongjianDate.tDLCScore[nDLCID].nFinishNum == WulintongjianDate.tDLCScore[nDLCID].nTotal)

        bRotPoint = table.contain_value(WulintongjianDate.tDLCRedPoint[nDLCID], true)
        if not bRotPoint then
            bRotPoint = self:CheckMapCanRedPoint(nDLCID)
        end

        UIHelper.SetVisible(self.tDLCCellScript[nDLCID].ImgRedDot, bRotPoint)
        UIHelper.SetVisible(self.tbRedDot[nDLCID], bRotPoint)
    end

    UIHelper.SetString(self.tDLCCellScript[WulintongjianDate.nDLCCount].LabelNum, g_tStrings.STR_COMING_SOON)
end

function UIWuLinTongJianView:CheckMapCanRedPoint(nDLCID)
    local tLine = Table_GetDLCInfo(nDLCID)
    local bDone
    if tLine then
        local nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID1)
        if (nAwardState ~= QUEST_PHASE.FINISH) and WulintongjianDate.tDLCScore[nDLCID].nFinishNum >= tLine.nRewardScore1 then
            return true
        end

        nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID2)
        if (nAwardState ~= QUEST_PHASE.FINISH) and WulintongjianDate.tDLCScore[nDLCID].nFinishNum >= tLine.nRewardScore2 then
            return true
        end

        nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID3)
        if (nAwardState ~= QUEST_PHASE.FINISH) and WulintongjianDate.tDLCScore[nDLCID].nFinishNum >= tLine.nRewardScore3 then
            return true
        end

        nAwardState = WulintongjianDate.GetAwardState(tLine.nRewardQuestID4)
        if (nAwardState ~= QUEST_PHASE.FINISH) and WulintongjianDate.tDLCScore[nDLCID].nFinishNum >= tLine.nRewardScore4 then
            return true
        end
    end

    return false
end

function UIWuLinTongJianView:UpdateRecommendMapList()
    local nFirstMap
	for nMapID, tMapInfo in pairs(self.tDLCMapInfo) do
		if tMapInfo.nLastRecomMap ~= 0 then
			if tMapInfo.nLastRecomMap == -1 then
				nFirstMap = nMapID
			else
				self.tDLCMapInfo[tMapInfo.nLastRecomMap].nNextRecomMap = nMapID
			end
		end
	end

	while nFirstMap do
		self.nCurrentRecomMap = nFirstMap
		if self.tDLCMapInfo[nFirstMap].tQuestInfo.nNum == self.tDLCMapInfo[nFirstMap].tQuestInfo.nFinishNum then
			nFirstMap = self.tDLCMapInfo[nFirstMap].nNextRecomMap
			if nFirstMap == nil then
				self.nCurrentRecomMap = nil
			end
		else
			nFirstMap = nil
		end
	end
end


function UIWuLinTongJianView:UpdateAwardState()
    for i = 1,4,1 do
        WulintongjianDate.tRewardInfo[i].nAwardState = WulintongjianDate.GetAwardState(WulintongjianDate.tRewardInfo[i].nRewardQuestID)
    end
end

function UIWuLinTongJianView:UpdateDLCInfoPage()
    -- self.viewScript = UIMgr.GetViewScript(VIEW_ID.PanelWuLinTongJianInner)
    -- if not self.bFirstOpenPanelWuLinTongJianInner or not self.viewScript then
    --     self.bFirstOpenPanelWuLinTongJianInner = true
    self.viewScript = UIMgr.GetViewScript(VIEW_ID.PanelWuLinTongJianInner)
    if not self.viewScript then
        self.viewScript = UIMgr.Open(VIEW_ID.PanelWuLinTongJianInner)
        if not self.viewScript then
            Event.Reg(self, EventType.OnViewOpen, function (nViewID)
                if nViewID == VIEW_ID.PanelWuLinTongJianInner then
                    self:UpdateDLCInfoPageDetailedBindUIEvent()
                    self:UpdateDLCInfoPageDetailed()
                end
            end)
        else
            self:UpdateDLCInfoPageDetailedBindUIEvent()
            self:UpdateDLCInfoPageDetailed(true)
        end
    else
        self:UpdateDLCInfoPageDetailed()
    end
end

function UIWuLinTongJianView:UpdateDLCInfoPageDetailedBindUIEvent()
    self.viewScript = UIMgr.GetViewScript(VIEW_ID.PanelWuLinTongJianInner)

    UIHelper.BindUIEvent(self.viewScript.BtnLeft,EventType.OnClick,function ()
        if self.nCurrentDLCID > 1 then
            self.nCurrentDLCID = self.nCurrentDLCID - 1
            WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
            self.nCurMapID = nil
            self.nAlllAward = nil
            self:UpdateDLCInfoPage()
        end
    end)

    UIHelper.BindUIEvent(self.viewScript.BtnRight,EventType.OnClick,function ()
        if self.nCurrentDLCID < WulintongjianDate.nDLCCount - 1 then
            self.nCurrentDLCID = self.nCurrentDLCID + 1
            WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
            self.nCurMapID = nil
            self.nAlllAward = nil
            self:UpdateDLCInfoPage()
        end
    end)

    UIHelper.BindUIEvent(self.viewScript.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(VIEW_ID.PanelWuLinTongJianInner)
        -- UIMgr.HideView(VIEW_ID.PanelWuLinTongJianInner)
        self.nAlllAward = nil
        self:UpdateDLCCellSelected()
        self:UpdateDLCScore()
    end)

    UIHelper.BindUIEvent(self.viewScript.WidgetRaward,EventType.OnClick,function ()
        local tAwardInfo = {}
        for i = 1,4 do
            local info = {
                ["szTitle"] = WulintongjianDate.tRewardInfo[i].szRewardName,
                ["szPath"] = WulintongjianDate.tRewardInfo[i].szRewardImage,
                ["nFinishNum"] = WulintongjianDate.tDLCScore[self.nCurrentDLCID].nFinishNum,
                ["tRewardInfo"] = WulintongjianDate.tRewardInfo[i],
                ["nCurrentDLCID"] = self.nCurrentDLCID,
                ["nRewardNum"] = i,
                ["bDone"] = WulintongjianDate.tRewardInfo[i].nAwardState == QUEST_PHASE.FINISH,
                ["dwAvatarID"] = WulintongjianDate.tRewardInfo[i].dwAvatarID,
            }
            table.insert(tAwardInfo,info)
        end
        local AwardScript =  UIMgr.Open(VIEW_ID.PanelFurnitureReward,tAwardInfo)
        AwardScript:UpdateWuLinTongJianAward(tAwardInfo)
    end)

    UIHelper.BindUIEvent(self.viewScript.BtnGetAll,EventType.OnClick,function ()
        self:GetAllAward()
    end)

    UIHelper.BindUIEvent(self.viewScript.ScrollViewTongJianLeft, EventType.OnChangeSliderPercent, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)
end

function UIWuLinTongJianView:GetAllAward()
    self.nAwardQueue = {}
    for i, nMapID in ipairs(WulintongjianDate.tSortDLCMap) do
        local tMapInfo = WulintongjianDate.tDLCMapInfo[tonumber(nMapID)]
        local bRedPoint = self:IsDLCMapRedPoint(tMapInfo)
        if bRedPoint then
            table.insert(self.nAwardQueue, nMapID)
        end
    end

    for i = 1, 4 do
        local bDone = WulintongjianDate.tRewardInfo[i].nAwardState == QUEST_PHASE.FINISH
        if (not bDone) and WulintongjianDate.tDLCScore[self.nCurrentDLCID].nFinishNum >= WulintongjianDate.tRewardInfo[i].nRewardScore then
            table.insert(self.nAwardQueue, i)
        end
    end

    self:GetAllAwardQueue()
end

function UIWuLinTongJianView:GetAllAwardQueue()
    self.nAlllAward = self.nAlllAward or 1
    if self.nAwardQueue[self.nAlllAward] then
        if IsString(self.nAwardQueue[self.nAlllAward]) then
            RemoteCallToServer("On_DLC_GetDLCMapReward", self.nCurrentDLCID, tonumber(self.nAwardQueue[self.nAlllAward]))
        else
            RemoteCallToServer("On_DLC_GetDLCReward", self.nCurrentDLCID, self.nAwardQueue[self.nAlllAward])
        end

        self.nAlllAward = self.nAlllAward + 1
        self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 1, function ()
            self:GetAllAwardQueue()
        end)
    else
        self.nAwardQueue = {}
        Timer.DelTimer(self, self.nTimerID)
        self.nTimerID = nil

        Timer.Add(self, 1, function ()
            self:UpdateAwardState()
            WulintongjianDate.UpdateDLCInfo(self.nCurrentDLCID)
            self:UpdateCurMapInfo(self.viewScript)
            self:UpdateDLCInfoPage()
            self:UpdateMapListRed()
            self.nAlllAward = nil
        end)
    end
end

function UIWuLinTongJianView:UpdateDLCInfoPageDetailed(bFirst)
    self.viewScript = UIMgr.GetViewScript(VIEW_ID.PanelWuLinTongJianInner)

    if self.viewScript then
        UIHelper.SetString(self.viewScript.LabelTitle, UIHelper.GBKToUTF8(WulintongjianDate.szDLCName))
        self:UpdateProgressBar(self.viewScript)
        self:UpdateMapList(self.viewScript, bFirst)
        self:DetectPageTurning(self.viewScript)
        UIHelper.SetVisible(self.viewScript.ImgRedDot, false)

        for i = 1, 4 do
            local bDone = WulintongjianDate.tRewardInfo[i].nAwardState == QUEST_PHASE.FINISH
            if (not bDone) and WulintongjianDate.tDLCScore[self.nCurrentDLCID].nFinishNum >= WulintongjianDate.tRewardInfo[i].nRewardScore then
                UIHelper.SetVisible(self.viewScript.ImgRedDot, true)
                break
            end
        end

        local nIndex = 1
        for i, nMapID in ipairs(WulintongjianDate.tSortDLCMap) do
            local tMapInfo = WulintongjianDate.tDLCMapInfo[tonumber(nMapID)]
            local bRedPoint = self:IsDLCMapRedPoint(tMapInfo)
            if bRedPoint then
                nIndex = i
                break
            end
        end

        local bVisible = table.contain_value(WulintongjianDate.tDLCRedPoint[self.nCurrentDLCID], true)
        if not bVisible then
            bVisible = self:CheckMapCanRedPoint(self.nCurrentDLCID)
        end
        UIHelper.SetButtonState(self.viewScript.BtnGetAll, bVisible and BTN_STATE.Normal or BTN_STATE.Disable)

        UIHelper.SetSelected(self.tDLCMapInfoScript[tonumber(WulintongjianDate.tSortDLCMap[nIndex])].TogPlace,true)

        self:UpdateRedPointArrow()
    end
end

function UIWuLinTongJianView:UpdateRedPointArrow()
    local bHasRedPointBelow = false
	local nWorldX, nScrollViewY = UIHelper.ConvertToWorldSpace(self.viewScript.ScrollViewTongJianLeft, 0, 0)

    for i, nMapID in ipairs(WulintongjianDate.tSortDLCMap) do
        local v = self.tDLCMapInfoScript[tonumber(nMapID)]
        if UIHelper.GetVisible(v.ImgRedDot) then
            local nHeight = UIHelper.GetHeight(v.ImgRedDot)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedDot, 0, nHeight)
            if _nWorldY < nScrollViewY then
				bHasRedPointBelow = true
                break
			end
        end
    end

	UIHelper.SetVisible(self.viewScript.WidgetRedPointArrow, bHasRedPointBelow)
end

function UIWuLinTongJianView:UpdateProgressBar(viewScript)
    local nFinishNum, nTotal = WulintongjianDate.tDLCScore[self.nCurrentDLCID].nFinishNum, WulintongjianDate.tDLCScore[self.nCurrentDLCID].nTotal
    local nProgress = 100

    UIHelper.SetString(viewScript.LabslCount, nFinishNum)
    UIHelper.SetString(viewScript.LabslCountTotal,"/"..nTotal)
    UIHelper.SetProgressBarPercent(viewScript.ProgressBarVersionsCount, nFinishNum * nProgress / nTotal)
    UIHelper.LayoutDoLayout(viewScript.LayoutCount)
end

function UIWuLinTongJianView:IsDLCMapAllDone(tMapInfo)
    if tMapInfo.tQuestInfo.nNum ~= tMapInfo.tQuestInfo.nFinishNum then
        return false
    end
    if tMapInfo.tDungeonInfo.nNum ~= tMapInfo.tDungeonInfo.nFinishNum then
        return false
    end
    if tMapInfo.tOtherInfo.nNum ~= tMapInfo.tOtherInfo.nFinishNum then
        return false
    end
    for _, bFinish in ipairs(tMapInfo.tReputationInfo.tResult) do
        if not bFinish then
            return false
        end
    end
    return true
end

function UIWuLinTongJianView:IsDLCMapRedPoint(tMapInfo)
    local tStageRewardInfo = tMapInfo.tQuestInfo.tStageRewardInfo
    for i = 1,tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tStageRewardInfo.tStageQuestID[i])
        local bCanRevice = tMapInfo.tQuestInfo.nFinishNum >= tStageRewardInfo.tStageNum[i] and nQuestState ~= QUEST_PHASE.FINISH
        if bCanRevice then
            return true
        end
    end

    tStageRewardInfo = tMapInfo.tOtherInfo.tStageRewardInfo
    for i = 1,tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tStageRewardInfo.tStageQuestID[i])
        local bCanRevice = tMapInfo.tOtherInfo.nFinishNum >= tStageRewardInfo.tStageNum[i] and nQuestState ~= QUEST_PHASE.FINISH
        if bCanRevice then
            return true
        end
    end

    tStageRewardInfo = tMapInfo.tDungeonInfo.tStageRewardInfo
    for i = 1,tStageRewardInfo.nSize,1 do
        local nQuestState = WulintongjianDate.GetAwardState(tStageRewardInfo.tStageQuestID[i])
        local bCanRevice = tMapInfo.tDungeonInfo.nFinishNum >= tStageRewardInfo.tStageNum[i] and nQuestState ~= QUEST_PHASE.FINISH
        if bCanRevice then
            return true
        end
    end

    return false
end

function UIWuLinTongJianView:UpdateMapList(viewScript, bFirst)
    UIHelper.RemoveAllChildren(viewScript.ScrollViewTongJianLeft)

    self.tDLCMapInfoScript = {}
    for i, nMapID in ipairs(WulintongjianDate.tSortDLCMap) do
        local tMapInfo, k = WulintongjianDate.tDLCMapInfo[tonumber(nMapID)], tonumber(nMapID)
        local LeftCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTongJianLeftCell, viewScript.ScrollViewTongJianLeft)

        self.tDLCMapInfoScript[k] = LeftCellScript
        local name = Table_GetMapName(k)
        UIHelper.SetString(LeftCellScript.LabelContent1, UIHelper.GBKToUTF8(name))
        UIHelper.SetString(LeftCellScript.LabelContent2, UIHelper.GBKToUTF8(name))
        local bIsDLCMapAllDone = self:IsDLCMapAllDone(tMapInfo)
        UIHelper.SetVisible(LeftCellScript.ImgTag, bIsDLCMapAllDone)
        local bRedPoint = self:IsDLCMapRedPoint(tMapInfo)
        UIHelper.SetVisible(LeftCellScript.ImgRedDot, bRedPoint)

        UIHelper.BindUIEvent(LeftCellScript.TogPlace,EventType.OnSelectChanged,function (_,bSelected)
            if bSelected then
                self.nCurMapID = k
                self:UpdateCurMapInfo(viewScript)
            end
        end)
    end

    local nIndex = 1
    for i, nMapID in ipairs(WulintongjianDate.tSortDLCMap) do
        local tMapInfo = WulintongjianDate.tDLCMapInfo[tonumber(nMapID)]
        local bRedPoint = self:IsDLCMapRedPoint(tMapInfo)
        if bRedPoint then
            nIndex = i
            break
        end
    end

    if bFirst then
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayout(viewScript.ScrollViewTongJianLeft)
            UIHelper.ScrollToIndex(viewScript.ScrollViewTongJianLeft, nIndex - 1)
        end)
    else
        UIHelper.ScrollViewDoLayout(viewScript.ScrollViewTongJianLeft)
        UIHelper.ScrollToIndex(viewScript.ScrollViewTongJianLeft, nIndex - 1)
    end
end

function UIWuLinTongJianView:UpdateMapListRed()
    local LeftCellScript = self.tDLCMapInfoScript[self.nCurMapID]
    local tMapInfo = WulintongjianDate.tDLCMapInfo[self.nCurMapID]
    local bRedPoint = self:IsDLCMapRedPoint(tMapInfo)
    UIHelper.SetVisible(LeftCellScript.ImgRedDot, bRedPoint)
end

function UIWuLinTongJianView:UpdateCurMapInfo(viewScript)
    UIHelper.RemoveAllChildren(viewScript.ScrollViewTongJianRight)

    self.rightTitleScript = {}

    local tMapInfo = WulintongjianDate.tDLCMapInfo[self.nCurMapID]
    if tMapInfo.szQuestStageNum ~= "" then
        local tInfo = tMapInfo.tQuestInfo
        self:UpdateCurMapList(WuLinTongJianType.Quest.."（"..tInfo.nFinishNum.."/"..tInfo.nNum.."）",tInfo,WuLinTongJianType.Quest,viewScript)
    end
    if tMapInfo.szOtherStageNum ~= "" then
        local tInfo = tMapInfo.tOtherInfo
        self:UpdateCurMapList(WuLinTongJianType.Other.."（"..tInfo.nFinishNum.."/"..tInfo.nNum.."）",tInfo,WuLinTongJianType.Other,viewScript)
    end
    if tMapInfo.szDungeonStageNum ~= "" then
        local tInfo = tMapInfo.tDungeonInfo
        self:UpdateCurMapList(WuLinTongJianType.Dungeon.."（"..tInfo.nFinishNum.."/"..tInfo.nNum.."）",tInfo,WuLinTongJianType.Dungeon,viewScript)
    end
    if tMapInfo.szReputationIcon ~= "" then
        local tInfo = tMapInfo.tReputationInfo
        self:UpdateCurMapList(WuLinTongJianType.Reputation.."（"..tInfo.nFinishNum.."/"..tInfo.nNum.."）",tInfo,WuLinTongJianType.Reputation,viewScript)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(viewScript.ScrollViewTongJianRight)

    for k, v in ipairs(self.rightTitleScript) do
        UIHelper.SetSelected(v.ToggleTitle, true)
    end
end

function UIWuLinTongJianView:UpdateCurMapList(szTitle, tInfo, szKeyText, viewScript)
    local rightTitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTongJianRightTitle, viewScript.ScrollViewTongJianRight)
    UIHelper.SetString(rightTitleScript.LabelTitle3,szTitle)
    UIHelper.SetString(rightTitleScript.LabelTitle,szTitle)

    rightTitleScript:UpdateDLCMapCell(tInfo.tStageRewardInfo,szKeyText,tInfo.nFinishNum,self.nCurMapID,self.nCurrentDLCID)

    UIHelper.BindUIEvent(rightTitleScript.ToggleTitle,EventType.OnSelectChanged,function (_,bSelected)
        UIHelper.SetVisible(rightTitleScript.LayoutTongJianRightTitleCell,bSelected)
        UIHelper.LayoutDoLayout(rightTitleScript.LayoutTongJianRightTitleCell)
        UIHelper.LayoutDoLayout(rightTitleScript.WidgetTongJianRightTitle)
        UIHelper.ScrollViewDoLayoutAndToTop(viewScript.ScrollViewTongJianRight)
    end)

    table.insert(self.rightTitleScript,rightTitleScript)
end

function UIWuLinTongJianView:DetectPageTurning(viewScript)
    UIHelper.SetVisible(viewScript.BtnLeft, self.nCurrentDLCID > 1)
    UIHelper.SetVisible(viewScript.BtnRight, self.nCurrentDLCID < WulintongjianDate.nDLCCount - 1)
end

function UIWuLinTongJianView:OpenRewardView(nDLCID)
    local nSelectDLCID = nDLCID or self.nCurrentDLCID
    local tAwardInfo = {}
        for i = 1,4 do
            local info = {
                ["szTitle"] = WulintongjianDate.tRewardInfo[i].szRewardName,
                ["szPath"] = WulintongjianDate.tRewardInfo[i].szRewardImage,
                ["nFinishNum"] = WulintongjianDate.tDLCScore[nSelectDLCID].nFinishNum,
                ["tRewardInfo"] = WulintongjianDate.tRewardInfo[i],
                ["nCurrentDLCID"] = nSelectDLCID,
                ["nRewardNum"] = i,
                ["bDone"] = WulintongjianDate.tRewardInfo[i].nAwardState == QUEST_PHASE.FINISH,
                ["dwAvatarID"] = WulintongjianDate.tRewardInfo[i].dwAvatarID,
            }
            table.insert(tAwardInfo,info)
        end
        local AwardScript =  UIMgr.Open(VIEW_ID.PanelFurnitureReward,tAwardInfo)
        AwardScript:UpdateWuLinTongJianAward(tAwardInfo)
end

return UIWuLinTongJianView