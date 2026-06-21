-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingData
-- Date: 2023-03-15 15:08:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

CrossingData = CrossingData or {className = "CrossingData"}
local self = CrossingData
-------------------------------- 消息定义 --------------------------------
CrossingData.Event = {}
CrossingData.Event.XXX = "CrossingData.Msg.XXX"
-------------------------------- String ---------------------------------
CrossingData.szChooseTotaleScoreName = "总得分  "
self.nMaxCellNumber = 20

self.CrossingTitleName = "试炼之地"
self.SiShiTitleName = "四时论武阵"

CrossingStateType =
{
    TestPlace = 1,
    SiShiLunWu = 2,
}

self.nState = CrossingStateType.TestPlace

CrossingData.WidgetTestPlaceCellPosionY = 0
CrossingData.CellSpacingAddPosionY = 30
--------------------------------  --------------------------------
function CrossingData.Init()
    require("Lua/UI/Crossing/CrossingExtraData.lua")
    self.tbProcessInfo = nil
end

function CrossingData.UnInit()

end

function CrossingData.OnLogin()

end

function CrossingData.OnFirstLoadEnd()

end

-----------------------------------------------------------------------------
---- 试炼之地数据
-----------------------------------------------------------------------------
self.tbTestPlaceData =
{
    nLevel  = 1,
    tbLevelData  = nil,
    nTotalScore  = 0
}
self.bIsWaitingOpenHint = false
self.nCurrentLevel = 1
self.nCurrentMission = 1
self.nFlopCardTime = 20
self.nFlopCardID = 1
self.nPreClickCardIndex = 0
self.szTaskTitleFormat = "第%s层第%s关 %s"
self.szCurMissionDesc = ""
self.szCurMissionName = ""
self.bInCrossing = false

self.bWaitSwitchTask = false
function CrossingData.GetMissionName(searchType)
    if CrossingLevelMissionName[searchType] then
        return CrossingLevelMissionName[searchType]
    end
    return CrossingLevelMissionName[1]
end

function CrossingData.GetMissionDesc(searchType)
    if CrossingLevelMissionDesc[searchType] then
        return CrossingLevelMissionDesc[searchType]
    end
    return CrossingLevelMissionDesc[1]
end

function CrossingData.GetMissionAwardItemList(nLevel)

    for k, v in pairs(CrossingMissionAwardItemTab) do
        if  nLevel >= v.nMinLevel and nLevel <= v.nMaxLevel then
            return v.tbAwardItemList
        end
    end

    return {}
end

function CrossingData.OpenChoosePanel(nLevel , tbData , nTotalScore)
    CrossingData.tbTestPlaceData.nLevel = nLevel
    CrossingData.tbTestPlaceData.tbLevelData = tbData
    CrossingData.tbTestPlaceData.nTotalScore = nTotalScore
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceEntrance) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceEntrance)
    else
        UIMgr.Open(VIEW_ID.PanelTestPlaceEntrance , CrossingStateType.TestPlace)
    end
end

function CrossingData.CloseChoosePanel()
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceInfoPop) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceInfoPop)
    end
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceEntrance) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceEntrance)
    end
end

function CrossingData.OpenProcessPanel(tbData)
    CrossingData.bInCrossing = true
    Event.Dispatch(EventType.On_Trial_OpenCProcess , tbData)
end

function CrossingData.CloseProcessPanel()
    CrossingData.bWaitSwitchTask = false
    CrossingData.bInCrossing = false
    Event.Dispatch(EventType.On_Trial_CloseCProcess)
end

function CrossingData.OpenFlopCard(nType)
    if not CrossingData.bInCrossing then return end
    self.nFlopCardID = nType
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceRewardSelect) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceRewardSelect)
    else
        UIMgr.Open(VIEW_ID.PanelTestPlaceRewardSelect)
    end
end

function CrossingData.CloseFlopCard()
    if not CrossingData.bInCrossing then return end
    self.nFlopCardID = 0
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceRewardSelect) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceRewardSelect)
    end
end

function CrossingData.MissionComplete()

end

function CrossingData.MissionFailed()
    CrossingData:RemoveUpdateTime()
end

function CrossingData.ScreenBlack()
    CrossingData.tbResultInfo = nil
    CrossingData:RemoveUpdateTime()
end

function CrossingData.OpenFinishPanel(tData, nXiuWei, bVisible)
    CrossingData.tbResultInfo = {}
    CrossingData.tbResultInfo.tbData = tData
    CrossingData.tbResultInfo.nXiuWei = nXiuWei
    CrossingData.tbResultInfo.bVisible = bVisible
    -- 结算通关面板 需要增加一个抽卡显示
    CrossingData.OpenFlopCard(1)
end

function CrossingData.CloseFinishPanel()
    CrossingData.tbResultInfo = nil
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceResult) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceResult)
    end
end

function CrossingData.OpenMobileHelpTips(tbData)
    -- 策划山寨寻找当前关卡名称
    -- local helpTip = UIHelper.GBKToUTF8(tbData.szHelp)
    -- -- nShowType   1：试炼之地  2：四时论武阵
    -- if tbData.nShowType == 2 then
    --     CrossingData.szCurMissionDesc = helpTip
    --     CrossingData.szCurMissionName = ""
    -- else
    --     LOG.ERROR(helpTip)
    --     for i, v in ipairs(CrossingLevelMissionDesc) do
    --         if string.find(helpTip, v) then
    --             CrossingData.szCurMissionDesc = CrossingLevelMissionDesc[i]
    --             CrossingData.szCurMissionName = v
    --            break
    --         end
    --     end
    -- end
    -- if UIMgr.GetView(VIEW_ID.PanelTestPlaceHint) then
    --     UIMgr.Close(VIEW_ID.PanelTestPlaceHint)
    -- else
    --     UIMgr.Open(VIEW_ID.PanelTestPlaceHint , tbData)
    -- end
    CrossingData:AddUpdateTime()
end

function CrossingData:AddUpdateTime()
    Timer.DelTimer(self, self.nUpdateTimerID)
    self.nUpdateTimerID = Timer.AddCycle(self, 1, function ()
        self:UpdateTime()
    end)
end

function CrossingData:UpdateTime()
    local szTime = ""
    local szTimeColor = "#FFFFFF"
    if self.nEndTime and self.nEndTime >= 0 then
        local nLeftTime = self.nEndTime - GetCurrentTime()
        local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeftTime, false)
        if nH > 0 then
            szTime = szTime..string.format(g_tStrings.tCrossing.CROSSING_TIME_HOUR, nH)
        end
        if nM > 0 then
            szTime = szTime..string.format(g_tStrings.tCrossing.CROSSING_TIME_MINUTE, nM)
        end

        if nM <= 0 then
            szTimeColor = "#FF7676"
        elseif nM < 2 then
            szTimeColor = "#FFE26E"
        end

        szTime = szTime..string.format(g_tStrings.tCrossing.CROSSING_TIME_SECOND, nS)
    else
        szTime = " -- "
    end
    szTime = UIHelper.AttachTextColor(szTime, szTimeColor)

    local tCrossingHandler = TraceInfoData.GetInfoHandler(TraceInfoType.CrossingProgress)
    if tCrossingHandler then
        tCrossingHandler.UpdateCrossingTime(szTime)
    end
end

function CrossingData:RemoveUpdateTime()
    Timer.DelTimer(self, self.nUpdateTimerID)
end

function CrossingData:UpdateCrossingProgressInfo(tbData)--(widgetParent, tbData)
    self.nCurrentMission = tbData.nCurrentMission
    self.nCurrentLevel = tbData.nLevel
    local szTipContent = ""
    if self.szCurMissionName ~= "" then
        szTipContent = self.szCurMissionName.."\n"
    end

    local nTipCount = #tbData.tTips
	for i = 1, nTipCount do
		local tTip = tbData.tTips[i]
        if i == 1 then
            szTipContent = szTipContent..UIHelper.GBKToUTF8(tTip[1])..":    "..tTip[2].."/"..tTip[3]
        else
            szTipContent = szTipContent.."\n"..UIHelper.GBKToUTF8(tTip[1])..":    "..tTip[2].."/"..tTip[3]
        end
	end
    local szMissionName = ""
    if tbData.nMaxMission == 1 then
        szMissionName = string.format("第%s层" , UIHelper.NumberToChinese(tbData.nLevel))
    else
        szMissionName = string.format(self.szTaskTitleFormat , UIHelper.NumberToChinese(tbData.nLevel) , UIHelper.NumberToChinese(tbData.nCurrentMission) ,  "")
    end
    local szRecord = ""
    if tbData.nCurrentPoint then
        szRecord = string.format("%s%d",g_tStrings.tCrossing.CROSSING_CURRENT_RECORD,tbData.nCurrentPoint)
    end
    szTipContent  = szTipContent.."\n"..szRecord

    -- 设置时间
    if tbData.nEndTime then
		self.nEndTime =  GetCurrentTime() + tbData.nEndTime
	else
		self.nEndTime = -1
	end
    self:UpdateTime()

    local tCrossingHandler = TraceInfoData.GetInfoHandler(TraceInfoType.CrossingProgress)
    if tCrossingHandler then
        tCrossingHandler.UpdateCrossingProgressInfo(szMissionName, szTipContent)
        if not CrossingData.bWaitSwitchTask then
            Event.Dispatch(EventType.OnSetTraceInfoPriority, TraceInfoType.CrossingProgress)
            CrossingData.bWaitSwitchTask = true
        end
    end
end

function CrossingData:CloseCrossingProgressInfo()
    CrossingData:RemoveUpdateTime()

    local tCrossingHandler = TraceInfoData.GetInfoHandler(TraceInfoType.CrossingProgress)
    if tCrossingHandler then
        tCrossingHandler.CloseCrossingProgressInfo()
    end
end

function CrossingData.IsInCrossing()
    local player = GetClientPlayer()
    if not player then
        return false
    end

    local nMapID = player.GetMapID()
    local tbMapList = {
        [143] = true,
        [144] = true,
        [145] = true,
        [146] = true,
        [147] = true,
        [446] = true,
    }
    if tbMapList[nMapID] then
        return true
    end

    -- return self.bInCrossing --可能会有漏初始化的问题，改用当前地图判断
end
-----------------------------------------------------------------------------
---- 四时论武数据
-----------------------------------------------------------------------------

TRAIL_TYPE = {
    TANK = 1,
    DPS = 2,
    HEAL = 3
}

TRAIL_TYPE_NAME = {
    [TRAIL_TYPE.TANK] = "防御",
    [TRAIL_TYPE.DPS] = "攻击",
    [TRAIL_TYPE.HEAL] = "治疗"
}

NewTrialValley = {}

NewTrialValley.tbCustomData =
{
    REMOTE_NEWTRIAL_CUSTOM = 1036,

    MAXLEVEL = 20,	--最大关卡数
    NEW_TRIALCUSTOM = {
        TEMP_CURRENTLEVEL = 1,	--[1,1]当前关卡等级
        TEMP_CURRENTTYPE = 2,	--[2,2]当前关卡类型
        TEMP_CURRENTMISSION = 11,	--[11,11]当前关卡任务编号
        TEMP_CURRENTSTATE = 3,	--[3,3]当前关卡状态。0：未开始；1：进行中；2：即将开始；3：暂停；4：完成
        TEMP_CURRENTENDTIME = 4, --当前关卡的结束时间	更新UI用到；结算时间分数用到
        SAVE_CURRENTLEVEL = {
            [TRAIL_TYPE.TANK] = 5,	--[5,5]存档：T关卡当前等级
            [TRAIL_TYPE.DPS] = 6,	--[6,6]存档：DPS关卡当前等级
            [TRAIL_TYPE.HEAL] = 7,	--[7,7]存档：治疗关卡当前等级
        },
        SAVE_CURRENTSTATE = {
            [TRAIL_TYPE.TANK] = 8,	--[8,8]存档：T关卡状态
            [TRAIL_TYPE.DPS] = 9,	--[9,9]存档：DPS关卡状态
            [TRAIL_TYPE.HEAL] = 10,	--[10,10]存档：治疗关卡状态
        },
        SAVE_MAXLEVEL = {
            [TRAIL_TYPE.TANK] = 12,	--[8,8]存档：T关卡状态
            [TRAIL_TYPE.DPS] = 13,	--[9,9]存档：DPS关卡状态
            [TRAIL_TYPE.HEAL] = 14,	--[10,10]存档：治疗关卡状态
        },
        DATA_CLEARMARK = 15, --资料片清除存档标记
        TEMP_TONGIN = 16, --从帮会领地进入标记
    },
    tKungfu_Type = {
        [1] = {TRAIL_TYPE.TANK, TRAIL_TYPE.DPS},	--少林
        [2] = {TRAIL_TYPE.DPS, TRAIL_TYPE.HEAL},		--万花
        [3] = {TRAIL_TYPE.DPS, TRAIL_TYPE.TANK},	--天策
        [5] = {TRAIL_TYPE.HEAL, TRAIL_TYPE.DPS},		--七秀
        [6] = {TRAIL_TYPE.DPS, TRAIL_TYPE.HEAL},		--五毒
        [10] = {TRAIL_TYPE.DPS, TRAIL_TYPE.TANK},	--明教
        [21] = {TRAIL_TYPE.TANK, TRAIL_TYPE.DPS},	--苍云
        [22] = {TRAIL_TYPE.DPS, TRAIL_TYPE.HEAL},	--长歌门
        [212] = {TRAIL_TYPE.DPS, TRAIL_TYPE.HEAL},	--北天药宗
    }
}

NewTrialValley.tbModelData = {}

function NewTrialValley.Open()
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceEntrance) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceEntrance)
    else
        UIMgr.Open(VIEW_ID.PanelTestPlaceEntrance , CrossingStateType.SiShiLunWu)
    end
end

function NewTrialValley.Close()
    UIMgr.Close(VIEW_ID.PanelTestPlaceInfoPop)
    UIMgr.Close(VIEW_ID.PanelTestPlaceEntrance)
end


function NewTrialValley.OpenReward(tbData)
    local onConfirm = function()
        RemoteCallToServer("On_NewTrial_Continue")
    end

    local onCancel = function()
        RemoteCallToServer("On_NewTrial_QuitBattle")
    end

    local szTitleContent = (tbData.tItems ~= nil and " ") or  "已领取过本层的首次通关奖励"
    -- local scriptView = UIMgr.Open(VIEW_ID.PanelRewardHint, REWARD_TYPE.GOLDEN, szTitleContent, tbData.tItems, nil ,onConfirm , onCancel , "退出挑战","继续挑战")
    -- scriptView:SetButtonShowOrHide("BtnSure", tbData.bCanContinue ~= nil)

    TipsHelper.ShowRewardHint(REWARD_TYPE.GOLDEN, szTitleContent, tbData.tItems, nil ,onConfirm , onCancel , "退出挑战","继续挑战", nil, tbData.bCanContinue ~= nil)
end

function NewTrialValley.CloseReward()
    UIMgr.Close(VIEW_ID.PanelRewardHint)
end


function NewTrialValley:UpdateDataModel(player)
	local tData = {
		nCurrentType = TRAIL_TYPE.DPS,
		nMaxLevel = NewTrialValley.tbCustomData.MAXLEVEL,
	}
    local tbCustomData = NewTrialValley.tbCustomData
	local nTempType = player.GetRemoteDWordArray(tbCustomData.REMOTE_NEWTRIAL_CUSTOM, tbCustomData.NEW_TRIALCUSTOM.TEMP_CURRENTTYPE)
	if nTempType >= 1 and nTempType <= 3 then
		tData.nCurrentType = nTempType
	end
	tData[tData.nCurrentType] = {
        nType = tData.nCurrentType,
		nTopLevel = player.GetRemoteDWordArray(tbCustomData.REMOTE_NEWTRIAL_CUSTOM, tbCustomData.NEW_TRIALCUSTOM.SAVE_MAXLEVEL[tData.nCurrentType]),
		nCurrentLevel = player.GetRemoteDWordArray(tbCustomData.REMOTE_NEWTRIAL_CUSTOM, tbCustomData.NEW_TRIALCUSTOM.TEMP_CURRENTLEVEL),
	}
	local tTypeList = tbCustomData.tKungfu_Type[player.dwForceID]
	if not tTypeList then
		NewTrialValley.tbModelData = tData
        return
	end
	for i = 1, #tTypeList do
		if tTypeList[i] ~= tData.nCurrentType then
			local nIndex = tTypeList[i]
			tData[nIndex] = {
                nType = nIndex,
				nTopLevel = player.GetRemoteDWordArray(tbCustomData.REMOTE_NEWTRIAL_CUSTOM, tbCustomData.NEW_TRIALCUSTOM.SAVE_MAXLEVEL[nIndex]),
				nCurrentLevel = player.GetRemoteDWordArray(tbCustomData.REMOTE_NEWTRIAL_CUSTOM, tbCustomData.NEW_TRIALCUSTOM.SAVE_CURRENTLEVEL[nIndex]),
			}
		end
	end
	NewTrialValley.tbModelData = tData
end

function NewTrialValley.GetMissionAwardList(nType , nLevel)
    if NewTrialValleyMissionAwardItemTab[nType] then
        return NewTrialValleyMissionAwardItemTab[nType][nLevel] or {}
    end
    return {}
end


function CrossingData.CallFinishedFunction()
    Timer.Add(CrossingData ,0.5 , function ()
        if CrossingData.tbResultInfo ~= nil then
            if UIMgr.GetView(VIEW_ID.PanelTestPlaceResult) then
                UIMgr.Close(VIEW_ID.PanelTestPlaceResult)
            else
                UIMgr.Open(VIEW_ID.PanelTestPlaceResult,CrossingData.tbResultInfo.tbData,CrossingData.tbResultInfo.nXiuWei, CrossingData.tbResultInfo.bVisible)
            end
        end
    end)
end

function CrossingData.On_NewTrial_AllpyEnter()
    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.Crossing)
    local tMapIDList = {}
    for _, nPackID in ipairs(tPackIDList) do
        local _, nMapID = PakDownloadMgr.IsMapRes(nPackID)
        if nMapID and not table.contain_value(tMapIDList, nMapID) then
            table.insert(tMapIDList, nMapID)
        end
    end

    -- 地图资源下载检测拦截
    if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, nil, nil, true, "试炼之地") then
        return
    end

    UIHelper.ShowConfirm("是否前往试炼之地？", function()
        RemoteCallToServer("On_NewTrial_AllpyEnter")
    end)
end