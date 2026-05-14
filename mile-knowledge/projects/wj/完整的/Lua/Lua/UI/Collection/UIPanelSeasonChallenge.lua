-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSeasonChallenge
-- Date: 2026-03-17 19:18:30
-- Desc: ?
-- ---------------------------------------------------------------------------------
-- UIMgr.Open(VIEW_ID.PanelSeasonChallenge)
--szExSceneFile = "data\\source\\maps\\界面使用场景\\界面使用场景.jsonmap",
local CLASS_LIST =
{
	[1] = { 
        szName = g_tStrings.STR_ITEM_EQUIP_PVX, 
        szCurrencyName = "SeasonHonorXiuXian" ,
        nCurrencyCode = ShopData.CurrencyCode.SeasonHonorXiuXian,
        szCurrencyType = CurrencyType.SeasonHonorXiuXian,
        szRewardType = "HonorPanelPVX"
    },
	[2] = { 
        szName = g_tStrings.STR_FT_DUNGEON, 
        szCurrencyName = "SeasonHonorMiJing" ,
        nCurrencyCode = ShopData.CurrencyCode.SeasonHonorMiJing,
        szCurrencyType = CurrencyType.SeasonHonorMiJing,
        szRewardType = "HonorPanelPVE"
    },
	[3] = { 
        szName = g_tStrings.STR_PVP, 
        szCurrencyName = "SeasonHonorPVP" ,
        nCurrencyCode = ShopData.CurrencyCode.SeasonHonorPVP,
        szCurrencyType = CurrencyType.SeasonHonorPVP,
        szRewardType = "HonorPanelPVP"
    },
}

local CLASS2PAGE = {
    [1] = COLLECTION_PAGE_TYPE.REST,
    [2] = COLLECTION_PAGE_TYPE.SECRET,
    [3] = COLLECTION_PAGE_TYPE.ATHLETICS,
}

local tbScoreItemInfo = {
    [1] = {nTabID = 5, nIndex = 86066},
    [2] = {nTabID = 5, nIndex = 86067},
    [3] = {nTabID = 5, nIndex = 86068},
}

local tbFragmentItemInfo = {
    [1] = {nTabID = 5, nIndex = 86063},
    [2] = {nTabID = 5, nIndex = 86064},
    [3] = {nTabID = 5, nIndex = 86065},
}

local UIPanelSeasonChallenge = class("UIPanelSeasonChallenge")

function UIPanelSeasonChallenge:OnEnter(nType)
    self.nType = nType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbCurrentTaskList = self.tbCurrentTaskList or {}
    self:InitTaskScrollList()

    self:UpdateInfo()

    -- if not self.modelManager then
    --     self.modelManager = CommonStoreModelManager.CreateInstance(CommonStoreModelManager)
    -- end
    -- self.modelManager:Init(self.MiniScene, self.TouchContainer, Const.SHOP_SCENE, {-4,0,0})
end

function UIPanelSeasonChallenge:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:UnInitTaskScrollList()

    -- if self.modelManager then
    --     self.modelManager:ClearModelInfo()
    --     self.modelManager = nil
    -- end

    -- UITouchHelper.UnBindModel()
end

function UIPanelSeasonChallenge:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonChallengeBuyPop, self.nClass)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        self.nRideIndex = math.max(1, self.nRideIndex - 1)
        self:UpdateHorseModel()
        -- self:UpdateRideCost(self.nClass, self.nRideIndex)
        self:UpdateSwitchBtnVisible()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        local nCount = self.tMountList and #self.tMountList or 0
        self.nRideIndex = math.min(nCount, self.nRideIndex + 1)
        self:UpdateHorseModel()
        -- self:UpdateRideCost(self.nClass, self.nRideIndex)
        self:UpdateSwitchBtnVisible()
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelChatSocial)
    end)
end

function UIPanelSeasonChallenge:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
        self:CloseCurrencyTip()
        if self.tbSelectedScript then
            self.tbSelectedScript:SetSelected(false)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        
    end)

    Event.Reg(self, "CB_SH_TaskRewardGranted", function(szKey)
        if self.nClass then
            self:UpdateRewardProgress(self.nClass)
            self:UpdateCurrency(self.nClass)
        end

        if self.tTaskScrollList then
            self.tTaskScrollList:UpdateAllCell()
        end

        self:UpdateRedDot()
    end)
  
    Event.Reg(self, "CB_SH_SetPersonReward", function()
        if self.nClass then
            self:UpdateRewardProgress(self.nClass)
            self:UpdateCurrency(self.nClass)
            self:UpdateRedDot()
        end
    end)

    Event.Reg(self, "OnUpdateSimpleReward", function(tSendList) --领奖成功
        if tSendList and tSendList.tItem then
            local tNewInfo = {}
            for _, tItem in ipairs(tSendList.tItem) do
                local tData = {}
                tData.nTabType = tItem[1]
                tData.nTabID = tItem[2]
                tData.nCount = tItem[3]
                table.insert(tNewInfo, tData)
            end
            TipsHelper.ShowRewardList(tNewInfo)
        end
        if self.nClass then
            self:UpdateRewardProgress(self.nClass)
        end
    end)

    Event.Reg(self, "CB_SH_ExchangeMount", function(nSlot)
        if self.nClass then
            self:UpdateCurrency(self.nClass)
            self:UpdateRedDot()
        end
    end)

    Event.Reg(self, "ChallengeHorseRedDotChange", function()
        self:UpdateRedDot()
    end)
end

function UIPanelSeasonChallenge:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSeasonChallenge:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.ToggleTypeGroup, self.TogWeek)
    UIHelper.ToggleGroupAddToggle(self.ToggleTypeGroup, self.TogSeason)

    local tData = {}
    for k, v in pairs(CLASS_LIST) do
        v = self:FormatData(v, k)
        local Info = {}
        Info.tArgs = {szName = v.szName, nChildCount = v.tbSub and table.get_len(v.tbSub) or 0, nClass = k}
        if v.tbSub and table.get_len(v.tbSub)  > 0 then
			Info.tItemList = {}
		end
        
        if v.tbSub and table.get_len(v.tbSub)  > 0 then
			Info.tItemList = {}
		end
        for Index, tbData in pairs(v.tbSub) do
            local szSubName = tbData.szSubName ~= "全场挑战" and tbData.szSubName or nil
            local bShowRedDot = CollectionData.ChallengeHasCanGet(k, szSubName)
            table.insert(Info.tItemList, {tArgs = {szName = tbData.szSubName, toggleGroup = self.ToggleGroup, bLast = Index == table.get_len(v.tbSub), bShowRedDot = bShowRedDot, funcCallBack = function(scriptSubNav, scriptContain, bSelect)
				if bSelect then
					if self.tbItemScript then
						UIHelper.SetSelected(self.tbItemScript.TogSubNav ,false)
					end
					self.tbItemScript = scriptSubNav
					UIHelper.SetSelected(self.tbItemScript.TogSubNav ,true)
                    local tbChallengeList = tbData.tbChallengeList
                    if tbChallengeList then
                        self:UpdateNromalTask(tbChallengeList, k)
                    end
				end
			end}})
        end

        Info.fnOnCickCallBack = function(bSelect, scriptContainer)
			if bSelect then
				local tbItemScripts =  scriptContainer:GetItemScript()
				if self.tbItemScript then
					UIHelper.SetSelected(self.tbItemScript.TogSubNav ,false)
				end
				if table.get_len(tbItemScripts) ~= 0 then
					self.tbItemScript = tbItemScripts[1]
					self.tbItemScript:OnSelectChanged(true)
					UIHelper.SetSelected(self.tbItemScript.TogSubNav ,true)
				end
                self.nClass = k
                self.nRideIndex = 1
                self:UpdateRewardProgress(k)
                self:UpdateCurrency(k)
                self:UpdateHorseModel()
                -- self:UpdateRideCost(k, self.nRideIndex)
                self:UpdateSwitchBtnVisible()
                local bShowHorseRed = CollectionData.CheckChallengeHorseRedDot(self.nClass)
                UIHelper.SetVisible(self.ImgRedPoint, bShowHorseRed)
			end
		end
        table.insert(tData, Info)
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelNormalAll01, tArgs.szName)
        UIHelper.SetString(scriptContainer.LabelUpAll01, tArgs.szName)
		UIHelper.SetVisible(scriptContainer.WidgetSelecctImgTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIconTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.WidgetSelecctImg, tArgs.nChildCount == 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIcon, tArgs.nChildCount == 0)
        local bShowRedDot = CollectionData.ChallengeHasCanGet(tArgs.nClass) or CollectionData.ChallengeHasCanGetReward(tArgs.nClass) or CollectionData.CheckChallengeHorseRedDot(tArgs.nClass)
        UIHelper.SetVisible(scriptContainer.ImgNormalRedDot, bShowRedDot)
        UIHelper.SetVisible(scriptContainer.ImgSelectedRedDot, bShowRedDot)
    end

    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    scriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetLeftNavTabList, PREFAB_ID.WidgetSubNav, func, tData)

    scriptScrollViewTree.fnScrollViewMovedCallback = function(eventType)
        local nPercent = UIHelper.GetScrollPercent(scriptScrollViewTree.ScrollViewContent)
        UIHelper.SetVisible(self.WidgetArrow, nPercent < 98 and scriptScrollViewTree.scriptCurContainer ~= nil)
    end

    local nType = self.nType or 1
    Timer.AddFrame(self, 2, function()
		scriptScrollViewTree:SetContainerSelected(nType, true)
        local scriptContainer = scriptScrollViewTree.tContainerList[nType] and scriptScrollViewTree.tContainerList[nType].scriptContainer
        if scriptContainer then
            scriptContainer:CallOnClickCallBack(true)
        end
    end)
end

function UIPanelSeasonChallenge:UpdateTaskCellInfo(script, tbInfo, nClass)
    if not script or not tbInfo then
        return
    end
    local nProcess = tbInfo.nProcess or 0
    local nMaxProgress = tbInfo.nMaxProgress or 0
    local nStatus = GDAPI_SH_GetAllTaskRewardInfo(nClass, tbInfo.szTaskKey)
    local bCanGet = nStatus == 1
    local bFinished = nStatus == 2
    local bLock = tbInfo.bLock
    local szLockTime = tbInfo.szLockTime or ""
    tbInfo.szDesc = FormatString(tbInfo.szDesc, nProcess)
    
    UIHelper.SetString(script.LabelTaskTitle, tbInfo.szTitle)
    UIHelper.SetString(script.LabelTask, tbInfo.szDesc)
    UIHelper.SetVisible(script.imgBgFinish, bFinished)
    UIHelper.SetVisible(script.imgBgHint, not bFinished and not bCanGet)
    UIHelper.SetVisible(script.ImgRewardGet, bCanGet)
    UIHelper.SetEnable(script._rootNode, not bFinished)
    UIHelper.SetVisible(script.imgBgWeekTaskLock, bLock)
    UIHelper.SetString(script.LabelWeekTaskLock, szLockTime)

    if not script.tbScoreScript then
        script.tbScoreScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, script.LayoutReward)
    end
    local nScoreTabType, nScoreTabID = tbScoreItemInfo[nClass].nTabID, tbScoreItemInfo[nClass].nIndex
    script.tbScoreScript:OnInitWithTabID(nScoreTabType, nScoreTabID, tbInfo.nScore)
    script.tbScoreScript:SetToggleSwallowTouches(true)
    script.tbScoreScript:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
        TipsHelper.DeleteAllHoverTips()
        local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script.tbScoreScript._rootNode, dwItemTabType, dwItemTabIndex)
        uiItemTipScript:SetBtnState({})
        self.tbSelectedScript = script.tbScoreScript
    end)
    script.tbScoreScript:SetToggleGroupIndex(ToggleGroupIndex.SeasonFragment)

    if not script.tFragmentScript then
        script.tFragmentScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, script.LayoutReward)
    end
    local szCurrencyName = CLASS_LIST[nClass].szCurrencyName
    local nFragmentTabType, nFragmentTabID = tbFragmentItemInfo[nClass].nTabID, tbFragmentItemInfo[nClass].nIndex
    script.tFragmentScript:OnInitWithTabID(nFragmentTabType, nFragmentTabID, tbInfo.nFragment)
    script.tFragmentScript:SetToggleSwallowTouches(true)
    script.tFragmentScript:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
        TipsHelper.DeleteAllHoverTips()
        local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script.tFragmentScript._rootNode, dwItemTabType, dwItemTabIndex)
        uiItemTipScript:SetBtnState({})
        self.tbSelectedScript = script.tFragmentScript
    end)
    script.tFragmentScript:SetToggleGroupIndex(ToggleGroupIndex.SeasonFragment)

    UIHelper.LayoutDoLayout(script.LayoutReward)
    UIHelper.BindUIEvent(script._rootNode, EventType.OnClick, function ()
        if bCanGet then
            RemoteCallToServer("On_SH_CompleteTask", tbInfo.szTaskKey)
        elseif bLock then
            TipsHelper.ShowNormalTip("暂未开启,敬请期待")
        else
            if tbInfo.szMobileFunction and tbInfo.szMobileFunction ~= "" then
                CollectionFuncList.Excute(tbInfo.szMobileFunction)
            elseif tbInfo.szEventLink and tbInfo.szEventLink ~= "" then
                Event.Dispatch("EVENT_LINK_NOTIFY", tbInfo.szEventLink)
            end
        end
    end)
    -- Timer.AddFrame(self, 1, function()
    --     UIHelper.WidgetFoceDoAlign(script)
    -- end)
    
end

function UIPanelSeasonChallenge:UpdateNromalTask(tbChallengeList, nClass)
    UIHelper.SetVisible(self.ScrollViewNormalTask, true)
    UIHelper.SetVisible(self.WidgetToggle, false)

    self.tbCurrentTaskList = tbChallengeList or {}
    self.nCurrentTaskClass = nClass

    self:RefreshTaskScrollList()
end

function UIPanelSeasonChallenge:UpdateHorseModel()
    local tMountList = CollectionData.GetMountList(self.nClass)
    self.tMountList = tMountList
    if tMountList then 
        local tbRide = tMountList[self.nRideIndex]
        if not tbRide then
            return
        end
        local szRewardType = CLASS_LIST[self.nClass] and CLASS_LIST[self.nClass].szRewardType or ""
        local tbInfoList = Table_GetSeasonReward(szRewardType)
        if tbInfoList then
            local tbInfo = tbInfoList[self.nRideIndex]
            UIHelper.SetTexture(self.ImgBigItem, tbInfo.szMobilePath)
        end
    end
end

function UIPanelSeasonChallenge:FormatData(tInfo, nClass)
    local Info = {}
    Info.szName = tInfo.szName or ""
    Info.tbSub = {}
    local tOperationList = self:BuildOperationList(nClass)
    for k, tbData in pairs(tOperationList) do
        local szCatgName = tbData.szCatgName
        local tbChallengeList = self:GetTaskList(nClass, szCatgName)
        table.insert(Info.tbSub, {szSubName = szCatgName or tbData.szText, tbChallengeList = tbChallengeList})
    end

    return Info
end

local function GetTaskConfigList(nClass)
    return Table_GetSeasonHonorTaskConfig(nClass) or {}
end

local OPERATION_ALL_INFO = {
    nID = 1,
    szText = "全场挑战",
}

function UIPanelSeasonChallenge:BuildOperationList(nClass)
    local tConfigList = GetTaskConfigList(nClass)
    local tOperationList = {
        {
            nID = OPERATION_ALL_INFO.nID,
            szText = OPERATION_ALL_INFO.szText,
        },
    }
    local tCategoryMap = {}
    local nNextID = OPERATION_ALL_INFO.nID

    for _, tTask in ipairs(tConfigList) do
        local szCatgName = tTask.szCatgName or ""
        if tTask.bShow and szCatgName ~= "" and not tCategoryMap[szCatgName] then
            nNextID = nNextID + 1
            tCategoryMap[szCatgName] = true
            table.insert(tOperationList, {
                nID = nNextID,
                szText = UIHelper.GBKToUTF8(szCatgName),
                szCatgName = UIHelper.GBKToUTF8(szCatgName),
            })
        end
    end

    return tOperationList
end

function UIPanelSeasonChallenge:GetTaskList(nClass, szCatgName)
    local tConfigList = GetTaskConfigList(nClass)
    local tProgressMap = GDAPI_SH_GetTaskListProgress(nClass) or {}
    local tVisible = {}

    for _, tTask in ipairs(tConfigList) do
        if tTask.bShow and (not szCatgName or UIHelper.GBKToUTF8(tTask.szCatgName) == szCatgName) then
            local tProgress = tProgressMap[tTask.szTaskKey] or {}
            local nMaxProgress = tTask.nMaxProgress or 0
            local nProcess = tProgress.nProcess or 0
            if nMaxProgress > 0 and nProcess > nMaxProgress then
                nProcess = nMaxProgress
            end
            local nStatus = GDAPI_SH_GetAllTaskRewardInfo(nClass, tTask.szTaskKey)
            table.insert(tVisible, {
                nTaskID = tTask.nTaskID,
                szTaskKey = tTask.szTaskKey,
                szTitle = UIHelper.GBKToUTF8(tTask.szTitle) or "",
                szDesc = UIHelper.GBKToUTF8(tTask.szDesc) or "",
                nProcess = nProcess,
                nMaxProgress = nMaxProgress,
                bCanGet = nMaxProgress > 0 and nProcess >= nMaxProgress,
                nScore = tTask.nScore,
                nFragment = tTask.nFragment,
                nStatus = nStatus,
                szMobileFunction = tTask.szMobileFunction,
                szEventLink = tTask.szEventLink,
                nSort = tTask.nSort,
                bLock = tTask.bLock,
                szLockTime = UIHelper.GBKToUTF8(tTask.szLockTime) or ""
            })
        end
    end

    table.sort(tVisible, function(a, b)
        local weightA = a.nStatus == 1 and 1 or (a.nStatus == 2 and 3 or 2)
        local weightB = b.nStatus == 1 and 1 or (b.nStatus == 2 and 3 or 2)
        
        if weightA ~= weightB then
            return weightA < weightB
        end

        local bLockA = a.bLock == true
        local bLockB = b.bLock == true
        if bLockA ~= bLockB then
            return not bLockA
        end

        local idA = a.nSort or 0
        local idB = b.nSort or 0
        
        return idA < idB
    end)


    return tVisible
end

local function GetRewardState(tRewardCfg, nScore, tRewardLv)
    local nStage = tRewardCfg and tRewardCfg.nStage or 0
    if nStage <= 0 then
        return false, false
    end

    local bReceived = tRewardLv and tRewardLv[nStage] == 1 or false
    local bCanGet = (not bReceived) and (nScore or 0) >= (tRewardCfg.nScore or 0)
    return bReceived, bCanGet
end

function UIPanelSeasonChallenge:UpdateRewardProgress(nClass)
    self.tbPointRewardItems = self.tbPointRewardItems or {}

    local nScore, tRewardLv = GDAPI_SH_GetBaseInfo(nClass)
    local tRewardList = Table_GetSeasonHonorRewardConfig(nClass) or {}
    local nRewardCount = #tRewardList
    local nMaxScore = nRewardCount > 0 and (tRewardList[nRewardCount].nScore or 0) or 0
    local szTitle = CLASS_LIST[nClass].szName
    local tCanGet = GDAPI_SH_GetLevelRewardState(nClass)
    UIHelper.SetString(self.LabeNum, tostring(nScore))
    UIHelper.SetString(self.LabeTitle, szTitle)
    UIHelper.SetSpriteFrame(self.ImgIcon, SEASONCHALLENGE_SCORE[nClass])
    -- if nMaxScore > 0 then
    --     UIHelper.SetProgressBarPercent(self.ProgressBar, math.min((10 or 0) / 20, 1) * 100)
    -- else
    --     UIHelper.SetProgressBarPercent(self.ProgressBar, 0)
    -- end
    for i = 1, nRewardCount - 1 do
        local tRewardCfg = tRewardList[i]
        local bReceived, bCanGet = GetRewardState(tRewardCfg, nScore, tRewardLv)
        bCanGet = bCanGet and tCanGet[i] == 1
        local scriptView, scriptItem
        if not self.tbPointRewardItems[i] then
            scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonChallengeRewardItem, self.ScrollChallengePointReward)
            if scriptView then
                UIHelper.SetAnchorPoint(scriptView._rootNode, 0, 0)
                scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, scriptView.WidgetItem20)
                self.tbPointRewardItems[i] = { view = scriptView, item = scriptItem }
            end
        else
            scriptView = self.tbPointRewardItems[i].view
            scriptItem = self.tbPointRewardItems[i].item
            UIHelper.SetVisible(scriptView._rootNode, true)
        end
        
        if scriptView and scriptItem then
            local tbReward = CollectionData.GetItemRewardList(tRewardCfg)
            local tbItem = tbReward[1]
            if tbItem then
                self:InitItem(scriptItem, scriptView, tbItem, bCanGet, nClass, i)
            end

            UIHelper.SetString(scriptView.Label20, tRewardCfg.nScore)
            UIHelper.SetVisible(scriptView.WidgetGet20, bReceived)
            UIHelper.SetVisible(scriptView.ImgAvailable20, bCanGet)
        end
    end

    for i = nRewardCount, #self.tbPointRewardItems do
        if self.tbPointRewardItems[i] then
            UIHelper.SetVisible(self.tbPointRewardItems[i].view._rootNode, false)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollChallengePointReward)

    if nRewardCount > 0 then
        local tLastReward = tRewardList[nRewardCount]
        local bReceived, bCanGet = GetRewardState(tLastReward, nScore, tRewardLv)
        bCanGet = bCanGet and tCanGet and tCanGet[nRewardCount] == 1
        if tLastReward.tReward then
            if not self.tbLastRewardItem then
                local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonChallengeRewardItem, self.WidgetItemReward)
                if scriptView then
                    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, scriptView.WidgetItem20)
                    self.tbLastRewardItem = { view = scriptView, item = scriptItem }
                end
            else
                UIHelper.SetVisible(self.tbLastRewardItem.view._rootNode, true)
            end

            if self.tbLastRewardItem then
                local scriptView = self.tbLastRewardItem.view
                local scriptItem = self.tbLastRewardItem.item

                local tbReward = CollectionData.GetItemRewardList(tLastReward)
                local tbItem = tbReward[1]
                if tbItem then
                    self:InitItem(scriptItem, scriptView, tbItem, bCanGet, nClass, nRewardCount)
                    scriptItem:SetToggleSwallowTouches(true)
                end
                
                UIHelper.SetString(scriptView.Label20, tLastReward.nScore)
                UIHelper.SetVisible(scriptView.WidgetGet20, bReceived)
                UIHelper.SetVisible(scriptView.ImgAvailable20, bCanGet)
            end
        else
            if self.tbLastRewardItem then
                UIHelper.SetVisible(self.tbLastRewardItem.view._rootNode, false)
            end
        end
    else
        -- 若没有奖励时，藏起最后节点
        if self.tbLastRewardItem then
            UIHelper.SetVisible(self.tbLastRewardItem.view._rootNode, false)
        end
    end
end

function UIPanelSeasonChallenge:OpenTip(scriptView, tbRewardInfo1, tbRewardInfo2, tbRewardInfo3)
    self:CloseTip()

    local szType      = tbRewardInfo1
    local dwTabType   = tonumber(tbRewardInfo1) or 0
    local dwID        = tonumber(tbRewardInfo2)
    local nCount      = tonumber(tbRewardInfo3)
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.TOP_CENTER)
    -- scriptItemTip:SetBtnState({})

    if szType == "COIN" then
        local tbLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
        local szName = CurrencyNameToType[tbLine.szName]
        scriptItemTip:OnInitCurrency(szName, nCount)
    else
        scriptItemTip:OnInitWithTabID(dwTabType, dwID)
    end
    self.scriptIcon = scriptView
end

function UIPanelSeasonChallenge:CloseTip()
    if self.scriptIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptIcon:RawSetSelected(false)
        self.scriptIcon = nil
    end
end

function UIPanelSeasonChallenge:OpenCurrencyTip(tFragmentScript, nClass)
    self:CloseCurrencyTip()
    local nCurrencyCode = CLASS_LIST[nClass].nCurrencyCode
    CurrencyData.ShowCurrencyHoverTips(tFragmentScript._rootNode, ShopData.GetCurrencyCodeToType(nCurrencyCode))
    self.scriptCurrencyIcon = tFragmentScript
end

function UIPanelSeasonChallenge:CloseCurrencyTip()
    if self.scriptCurrencyIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptCurrencyIcon:RawSetSelected(false)
        self.scriptCurrencyIcon = nil
    end
end

function UIPanelSeasonChallenge:UpdateCurrency(nClass)
    UIHelper.RemoveAllChildren(self.LayoutRideCurrency)
    local nCurrencyCode = CLASS_LIST[nClass].nCurrencyCode
    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutRideCurrency, nCurrencyCode)
end

-- function UIPanelSeasonChallenge:UpdateRideCost(nClass, nRideIndex)
--     if not nClass or not nRideIndex then
--         return
--     end
--     UIHelper.RemoveAllChildren(self.LayoutRideCurrency)
--     local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutRideCurrency)
--     local nCurrencyCode = CLASS_LIST[nClass].szCurrencyType
--     local tMountList = CollectionData.GetMountList(nClass)
--     local tMount = tMountList[nRideIndex]
--     local nCost = tMount.nCost
--     tbScript:SetSpriteFrame(nCurrencyCode)
--     tbScript:SetLableCount(nCost)
-- end

function UIPanelSeasonChallenge:UpdateSwitchBtnVisible()
    UIHelper.SetVisible(self.BtnSwitchLeft, self.nRideIndex ~= 1)
    UIHelper.SetVisible(self.BtnSwitchRight, self.nRideIndex ~= 3)
end

function UIPanelSeasonChallenge:InitTaskScrollList()
    self:UnInitTaskScrollList()

    self.tTaskScrollList = UIScrollList.Create({
        listNode = self.ScrollViewNormalTask,
        nSpace = 6,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetSeasonChallengeTaskList
        end,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateOneTaskCell(cell, nIndex)
        end,
    })
    local nWidth, _ = UIHelper.GetContentSize(self.ScrollViewNormalTask)
    UIHelper.SetContentSize(self.tTaskScrollList.m.contentNode, nWidth, 0)
end

function UIPanelSeasonChallenge:UnInitTaskScrollList()
    if self.tTaskScrollList then
        self.tTaskScrollList:Destroy()
        self.tTaskScrollList = nil
    end
end

function UIPanelSeasonChallenge:UpdateRedDot()
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
    if not scriptScrollViewTree then return end
    
    for _, tContainerInfo in ipairs(scriptScrollViewTree.tContainerList or {}) do
        local scriptContainer = tContainerInfo.scriptContainer
        if scriptContainer then
            local tArgs = scriptContainer.tArgs
            if tArgs and tArgs.nClass then
                local bShowRedDot = CollectionData.ChallengeHasCanGet(tArgs.nClass) or CollectionData.ChallengeHasCanGetReward(tArgs.nClass) or CollectionData.CheckChallengeHorseRedDot(tArgs.nClass)
                UIHelper.SetVisible(scriptContainer.ImgNormalRedDot, bShowRedDot)
                UIHelper.SetVisible(scriptContainer.ImgSelectedRedDot, bShowRedDot)
                
                if scriptContainer.GetItemScript then
                    local tbItemScripts = scriptContainer:GetItemScript()
                    if tbItemScripts then
                        for _, scriptSubNav in ipairs(tbItemScripts) do
                            local szRawName = scriptSubNav:GetName()
                            local szSubName = szRawName ~= "全场挑战" and szRawName or nil
                            local bSubShowRedDot = CollectionData.ChallengeHasCanGet(tArgs.nClass, szSubName)
                            scriptSubNav.bShowRedDot = bSubShowRedDot
                            UIHelper.SetVisible(scriptSubNav.ImgNormalRedDot, bSubShowRedDot)
                            UIHelper.SetVisible(scriptSubNav.ImgSelectedRedDot, bSubShowRedDot)
                        end
                    end
                end
            end
        end
    end

    if scriptScrollViewTree.scriptTopContainer then
        local scriptCurContainer = scriptScrollViewTree.scriptCurContainer
        if scriptCurContainer then
            local tArgs = scriptCurContainer.tArgs
            if tArgs and tArgs.nClass then
                local bShowRedDot = CollectionData.ChallengeHasCanGet(tArgs.nClass) or CollectionData.ChallengeHasCanGetReward(tArgs.nClass) or CollectionData.CheckChallengeHorseRedDot(tArgs.nClass)
                UIHelper.SetVisible(scriptScrollViewTree.scriptTopContainer.ImgNormalRedDot, bShowRedDot)
                UIHelper.SetVisible(scriptScrollViewTree.scriptTopContainer.ImgSelectedRedDot, bShowRedDot)
            end
        end
    end

    local bShowHorseRed = CollectionData.CheckChallengeHorseRedDot(self.nClass)
    UIHelper.SetVisible(self.ImgRedPoint, bShowHorseRed)
end

function UIPanelSeasonChallenge:UpdateOneTaskCell(cell, nIndex)
    if not cell then
        return
    end
    cell._keepmt = true

    local tbInfo = self.tbCurrentTaskList and self.tbCurrentTaskList[nIndex]
    if not tbInfo then
        return
    end

    self:UpdateTaskCellInfo(cell, tbInfo, self.nCurrentTaskClass)
end

function UIPanelSeasonChallenge:RefreshTaskScrollList()
    if not self.tTaskScrollList then
        return
    end

    local nCount = table.get_len(self.tbCurrentTaskList or {})
    if nCount <= 0 then
        self.tTaskScrollList:Reset(0)
    else
        -- 从顶部开始显示
        self.tTaskScrollList:ResetWithStartIndex(nCount, 1)
    end
end

function UIPanelSeasonChallenge:InitItem(scriptItem, scriptView, tbRewardInfo, bCanGet, nClass, nLv)
    local szType      = tbRewardInfo[1]
    local dwTabType   = tonumber(tbRewardInfo[1])
    local dwID        = tonumber(tbRewardInfo[2])
    local nCount      = tonumber(tbRewardInfo[3])

    if szType == "COIN" then
        nCount = nCount or 0
        local tbLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
        local szName = CurrencyNameToType[tbLine.szName]
        scriptItem:OnInitCurrency(szName, nCount)
        if nCount ~= 0 then
            scriptItem:SetLabelCount(nCount)
        else
            scriptItem:SetLabelCount()
        end
    else
        scriptItem:OnInitWithTabID(dwTabType, dwID, nCount)
        if nCount == 1 then
            scriptItem:SetLabelCount()
        end
    end
    scriptItem:SetClickCallback(function(nClickTabType, nClickTabID)
        if bCanGet then
            RemoteCallToServer("On_SH_GetReward", nClass, nLv)
        else
            self:OpenTip(scriptItem, tbRewardInfo[1], tbRewardInfo[2], tbRewardInfo[3])
        end
    end)

    scriptItem:SetToggleSwallowTouches(false)
end

return UIPanelSeasonChallenge