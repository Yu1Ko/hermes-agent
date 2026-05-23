-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PublicQuestData
-- Date: 2023-02-23 16:17:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

PublicQuestData = PublicQuestData or {className = "PublicQuestData"}
local self = PublicQuestData
-------------------------------- 消息定义 --------------------------------
PublicQuestData.Event = {}
PublicQuestData.Event.XXX = "PublicQuestData.Msg.XXX"
local LIMIT_CD = 15
PublicQuestData.FIELD_PQ_STATE_NOT_START = 1
PublicQuestData.FIELD_PQ_STATE_UNDER_WAY = 2
PublicQuestData.FIELD_PQ_STATE_FAIL = 3
PublicQuestData.FIELD_PQ_STATE_FINISH = 4
local FIELD_TIME_SECOND = 1000
local FIELD_TIME_MINUTE = 60

function PublicQuestData.Init()
    self.tbPQNpcTemplateID = Table_GetNewPQ_NPC_Template()
    self.tbEnterNpcTemplateID = {}
    self.tbNPCIDToPQID = {}
    self._registerEvent()
end

function PublicQuestData.UnInit()

end

function PublicQuestData.OnLogin()

end

function PublicQuestData.OnFirstLoadEnd()

end

function PublicQuestData.GetPQID(dwTemplateID)
    local dwPQID = 0
	for k, v in pairs(self.tbPQNpcTemplateID) do
		if v == dwTemplateID then
			dwPQID = k
			break
		end
	end
	return dwPQID
end


function PublicQuestData.OnNpcLeave(nNpcID)

	local dwPQID = self.tbNPCIDToPQID[nNpcID]

    if not dwPQID then return end

    if self.tbEnterNpcTemplateID[dwPQID] then
		self.tbEnterNpcTemplateID[dwPQID] = self.tbEnterNpcTemplateID[dwPQID] - 1
		if self.tbEnterNpcTemplateID[dwPQID] == 0 then
			self.tbEnterNpcTemplateID[dwPQID] = nil
		end
	end

    self.ApplyPQ(false)
end


function PublicQuestData.OnNpcEnter(nNpcID)

    local npc = GetNpc(nNpcID)
    if not npc then return end
    local dwTemplateID = npc.dwTemplateID

	local dwPQID = self.GetPQID(dwTemplateID)
	if dwPQID == 0 then
		return
	end

	if not self.tbEnterNpcTemplateID[dwPQID] then
		self.tbEnterNpcTemplateID[dwPQID] = 0
	end
	self.tbEnterNpcTemplateID[dwPQID] = self.tbEnterNpcTemplateID[dwPQID] + 1

    if not self.tbNPCIDToPQID[nNpcID] then
        self.tbNPCIDToPQID[nNpcID] = {}
    end
    self.tbNPCIDToPQID[nNpcID] = dwPQID
    self.ApplyPQ(false)
end


function PublicQuestData.ApplyPQ(bTimer)
    local tbApply = {}
    for index, value in pairs(self.tbEnterNpcTemplateID) do
        table.insert(tbApply, index)
    end
    if (bTimer and #tbApply == 0) or (self.bInFieldPQState) then return end
    if not bTimer and self._isSameTable(tbApply) then return end

    RemoteCallToServer("On_PQ_RequestData", tbApply)
end


function PublicQuestData.On_PQ_RequestDataReturn(tbPQID)

    if Config.bOptickLuaSample then BeginSample("_updatetbPQInfo") end
    local bUpdate = self._updatetbPQInfo(tbPQID)
    if Config.bOptickLuaSample then EndSample() end

    if bUpdate then
        Event.Dispatch(EventType.On_PQ_RequestDataReturn, self.tbPQInfoList, false)
    end
end

function PublicQuestData.FieldPQStateUpdate(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
    self.bInFieldPQState = true
    self._initFieldPQInfo(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
    Event.Dispatch(EventType.On_PQ_RequestDataReturn, self.tbFieldPQInfo, true)
    if not self.nUpdateFPQTimer then
        self.nUpdateFPQTimer = Timer.AddFrameCycle(self, 1, function()
            self._updateFieldPQInfo()
        end)
    end
end


function PublicQuestData.CloseFieldPQPanel(dwPQTemplateID)
    self.bInFieldPQState = false
    self.tbFieldPQInfo = {}
    Event.Dispatch(EventType.On_PQ_RequestDataReturn, self.tbFieldPQInfo, true)
end

function PublicQuestData.HavePublicQuest()
    return self.tbPQInfoList and #self.tbPQInfoList > 0
end

function PublicQuestData.GetShowQuestList()
    return self.tbShowList
end

function PublicQuestData._updateFieldPQInfo()
    if self.tbFieldPQInfo.nStartTime then
		local bUpdate = false
		local nPasTime = (GetTickCount() - self.tbFieldPQInfo.nStartTime) / FIELD_TIME_SECOND
		if self.tbFieldPQInfo.nTime then
			self.tbFieldPQInfo.nLeftTime = self.tbFieldPQInfo.nTime - nPasTime
			bUpdate = self._isRefreshTime(self.tbFieldPQInfo.nLeftTime, self.tbFieldPQInfo.nShowTime)
		elseif self.tbFieldPQInfo.nNextTime then
			self.tbFieldPQInfo.nLeftNextTime = self.tbFieldPQInfo.nNextTime - nPasTime
			bUpdate = self._isRefreshTime(self.tbFieldPQInfo.nLeftNextTime, self.tbFieldPQInfo.nNextShowTime)
		end

        if bUpdate then
            local szTime, nNextShowTime, nShowTime
            szTime, nNextShowTime = self._formatTime(self.tbFieldPQInfo.nLeftNextTime)
            self.tbFieldPQInfo.nNextShowTime = nNextShowTime
            szTime, nShowTime = self._formatTime(self.tbFieldPQInfo.nLeftTime)
            self.tbFieldPQInfo.nShowTime = nShowTime

            local nState = self.tbFieldPQInfo.nState
            szTime = nState == self.FIELD_PQ_STATE_UNDER_WAY and szTime or ""
            self.tbFieldPQInfo.szPQState = UIHelper.AttachTimeTextColor(g_tStrings.tFieldPQState[nState], self.tbFieldPQInfo.nLeftTime, FIELD_TIME_MINUTE, TIME_TEXT_STATE.MINUTE, FontColorID.ImportantYellow, FontColorID.ImportantRed)
            Event.Dispatch(EventType.On_PQ_RequestDataReturn, self.tbFieldPQInfo, true)
        end
	end
end

function PublicQuestData._isRefreshTime(nTime, nShowTime)
	local nNowTime = math.ceil(nTime / FIELD_TIME_MINUTE)
	if nNowTime == nShowTime then
		return false
	end

	return true
end

function PublicQuestData._initFieldPQInfo(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
    local tFieldPQ = Table_GetFieldPQ(dwPQTemplateID)
    local tPQTraceString = Table_GetFieldPQString(dwPQTemplateID, nStepID)

    self.tbFieldPQInfo = {}
    self.tbFieldPQInfo.tbPQValues = {}
    self.tbFieldPQInfo.bFieldPQ = true
    self.tbFieldPQInfo.nState = nState
    self.tbFieldPQInfo.nStartTime = GetTickCount()
    self.tbFieldPQInfo.nNextTime = nNextTime
    self.tbFieldPQInfo.nLeftNextTime = nNextTime
    self.tbFieldPQInfo.nScore = nScore
    self.tbFieldPQInfo.nLeftTime = nTime
    self.tbFieldPQInfo.nTime = nTime

    local szTime, nShowTime = self._formatTime(self.tbFieldPQInfo.nLeftTime)
    self.tbFieldPQInfo.nShowTime = nShowTime

    szTime = nState == self.FIELD_PQ_STATE_UNDER_WAY and szTime or ""
    self.tbFieldPQInfo.szPQState = UIHelper.AttachTimeTextColor(g_tStrings.tFieldPQState[nState], self.tbFieldPQInfo.nLeftTime, FIELD_TIME_MINUTE, TIME_TEXT_STATE.MINUTE, FontColorID.ImportantYellow, FontColorID.ImportantRed)

    self.tbFieldPQInfo.szPQStep = nState == self.FIELD_PQ_STATE_NOT_START and g_tStrings.FIELD_PQ_STATE .. "_/_"
    or UIHelper.AttachTargetTextColor(g_tStrings.FIELD_PQ_STATE, nStepID, tFieldPQ.nTotalStep, FontColorID.ValueChange_Green, FontColorID.Text_Level1_Backup, FontColorID.Text_Level3_Gray)

    self.tbFieldPQInfo.szTraceTitle = g_tStrings.FIELD_PQ_TRACE


    if tPQTrace then
        local szColor = UIDialogueColorTab[FontColorID.ImportantYellow].Color
        for nIndex, nHave in ipairs(tPQTrace.KillNpc) do
            local szName = Table_GetNpcTemplateName(tPQTraceString["nKillNpcTemplateID" .. nIndex])
            local nNeed = tPQTraceString["nAmount" .. nIndex]
            nHave = math.min(nHave, nNeed)
            -- local szText = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(GetFormatText(szName .. " " .. nHave .. "/" .. nNeed, 27)), FontColorID.ImportantYellow)
            local szText = UIHelper.AttachTargetTextColor(UIHelper.GBKToUTF8(szName), nHave, nNeed, FontColorID.ValueChange_Green, FontColorID.Text_Level1_Backup, FontColorID.Text_Level3_Gray)
            table.insert(self.tbFieldPQInfo.tbPQValues, szText)
        end

        for nIndex, nHave in ipairs(tPQTrace.PQValue) do
            local szName = tPQTraceString["szPQValueStr" .. nIndex]
            local nNeed = tPQTraceString["nPQvalue" .. nIndex]
            nHave = math.min(nHave, nNeed)
            -- local szText = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(GetFormatText(szName .. " " .. nHave .. "/" .. nNeed, 27)), FontColorID.ImportantYellow)
            local szText = UIHelper.AttachTargetTextColor(UIHelper.GBKToUTF8(szName), nHave, nNeed, FontColorID.ValueChange_Green, FontColorID.Text_Level1_Backup, FontColorID.Text_Level3_Gray)
            table.insert(self.tbFieldPQInfo.tbPQValues, szText)
        end
    end

end

function PublicQuestData._formatTime(nTime)
    if not nTime then return "", -1 end
    local szTime = ""

	local nShowTime = math.ceil(nTime / FIELD_TIME_MINUTE)
	if nShowTime <= 1 then
		szTime = "<1"
	else
		szTime = nShowTime
	end
	szTime = szTime .. g_tStrings.STR_BUFF_H_TIME_M

	return szTime, nShowTime
end

function PublicQuestData._isSameTable(tbApply)
    if not self.tbLastApply then
        self.tbLastApply = tbApply
        return false
    end
    if #self.tbLastApply ~= #tbApply then
        self.tbLastApply = tbApply
        return false
    end
    for nIndex, nApplyID in ipairs(tbApply) do
        if not table.contain_value(self.tbLastApply, nApplyID) then
            self.tbLastApply = tbApply
            return false
        end
    end
    return true
end

function PublicQuestData._updateQuestList(tbPQID)
    local tbShowList = {}

    for dwPQID, tbValue in pairs(tbPQID) do
        local tbPQInfo = Table_GetNewPQ(dwPQID)
        local tbQuestList = string.split(tbPQInfo.szQuestList, "|")
        for k, v in pairs(tbQuestList) do
            local dwQuestID = tonumber(v)
            if QuestData.IsQuestExist(dwQuestID) then
                if not table.contain_value(tbShowList, dwQuestID) then
                    table.insert(tbShowList, dwQuestID)
                end
            end
        end
    end
    return tbShowList
end

function PublicQuestData._updatetbPQInfo(tbPQID)

    if not self.tbPQInfoMap then self.tbPQInfoMap = {} end
    if not self.tbPQInfoList then self.tbPQInfoList = {} end
    if not self.tbShowList then self.tbShowList = {} end

    local bUpdateUI = false
    local tbPQInfoList = {}
    local tbPQIDList = {}

    if g_pClientPlayer then
        
        local tbShowList = self._updateQuestList(tbPQID)
        bUpdateUI = not self.IsTableEqual(tbShowList, self.tbShowList)
        self.tbShowList = tbShowList

        local nPlayerLevel = g_pClientPlayer.nLevel
        for dwPQID, tbValue in pairs(tbPQID) do
            local tbPQInfo = Table_GetNewPQ(dwPQID)
            if nPlayerLevel >= tbPQInfo.nMinShowLevel then

                local tbLastValues = self.tbPQInfoMap[dwPQID] and self.tbPQInfoMap[dwPQID].tbPQValues
                local nLastSelf = self.tbPQInfoMap[dwPQID] and self.tbPQInfoMap[dwPQID].nSelf

                --比对数据是否一致
                local bValueEqual = self.IsTableEqual(tbValue.tPQValues, tbLastValues)
                local bSelfEqual = nLastSelf == tbValue.nSelf
                local bEqual = bValueEqual and bSelfEqual

                if not bUpdateUI and not bEqual then
                    bUpdateUI = true--数据已经不同，需要更新UI
                end

                tbPQInfo.tbPQValues = tbValue.tPQValues
                tbPQInfo.nSelf = tbValue.nSelf
                tbPQInfo.nPQID = dwPQID
                table.insert(tbPQInfoList, tbPQInfo)

                --当前tbPQInfoMap未保存此PQID的信息，则保存(注意保存的是引用)
                if not self.tbPQInfoMap[dwPQID] then
                    self.tbPQInfoMap[dwPQID] = tbPQInfo
                end
                table.insert(tbPQIDList, dwPQID)
            end
        end
    end

    --去掉已经消失的PQID的信息
    for dwPQID, tbPQInfo in pairs(self.tbPQInfoMap) do
        if not table.contain_value(tbPQIDList, dwPQID) then
            self.tbPQInfoMap[dwPQID] = nil
            if not bUpdateUI then bUpdateUI = true end
        end
    end

    if bUpdateUI then
        self.tbPQInfoList = tbPQInfoList
    end

    return bUpdateUI
end

function PublicQuestData.IsInCampPQ()
    local bInCampPQ = false
    if self.tbPQInfoList then
        for nIndex, tbPQInfo in ipairs(self.tbPQInfoList) do
            if table.contain_value(CAMP_PQID, tbPQInfo.dwPQID) then
                bInCampPQ = true
                break
            end
        end
    end
    return bInCampPQ
end

function PublicQuestData.IsTableEqual(tbA, tbB)

    if (not tbA) or (not tbB) then return false end
    if type(tbA) ~= "table" or type(tbB) ~= "table" then return false end

    local nLenA = table.get_len(tbA)
    local nLenB = table.get_len(tbB)
    if nLenA ~= nLenB then return false end

    for key, value_a in pairs(tbA) do
        local value_b = tbB[key]
        if type(value_a) ~= type(value_b) then
            return false
        end
        if type(value_a) == "number" and value_a ~= value_b then
             return false
        end
        if type(value_a) == "table" and (not self.IsTableEqual(value_a, value_b)) then
            return false
        end
        if type(value_a) == "string" and value_a ~= value_b then
            return false
        end
        if type(value_a) == "userdata" and value_a ~= value_b then
            return false
        end
        if type(value_a) == "boolean" and value_a ~= value_b then
            return false
        end
    end

    return true
end

function PublicQuestData._registerEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.ApplyPQ(false)--防止进入场景后任务界面没刷新的问题
        self.nTimer = Timer.AddFrameCycle(self, 1, function()
            local dwCurrentTime = GetCurrentTime()
            if not self.dwStartTime then
                self.dwStartTime = dwCurrentTime
            end
            if dwCurrentTime - self.dwStartTime > LIMIT_CD then
                self.ApplyPQ(true)
                self.dwStartTime = dwCurrentTime
            end
        end)
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        Timer.DelTimer(self, self.nTimer)
        Timer.DelTimer(self, self.nUpdateFPQTimer)
        self.dwStartTime = nil
        self.nUpdateFPQTimer = nil
        self.On_PQ_RequestDataReturn({})--离开场景时手动清空PQ信息，remotecommand的On_PQ_RequestDataReturn看起来不靠谱
    end)

    Event.Reg(self, "ON_PQ_REQUEST_DATA", function(tbPQID)
        self.On_PQ_RequestDataReturn(tbPQID)
    end)

    Event.Reg(self, "FIELD_PQ_STATE_UPDATE", function(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
        self.FieldPQStateUpdate(dwPQTemplateID, nStepID, nState, nTime, tPQTrace, tPQStatistic, nScore, nNextTime)
    end)

    Event.Reg(self, "CLOSE_FIELD_PQ_PANEL", function(dwPQTemplateID)
        self.CloseFieldPQPanel(dwPQTemplateID)
    end)
end
