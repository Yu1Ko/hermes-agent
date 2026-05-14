-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIChallengePop
-- Date: 2023-04-07 11:40:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChallengePop = class("UIChallengePop")

local tImageState = {
    "UIAtlas2_Arena_Arena_Img_In.png",
    "UIAtlas2_Arena_Arena_Img_Busy.png",
}

function UIChallengePop:OnEnter(tChallengeInfo)
    self.tChallengeInfo = tChallengeInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChallengePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIChallengePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBegin, EventType.OnClick, function() --开始擂台
        local player = GetClientPlayer()
        if player.nMoveState == MOVE_STATE.ON_STAND then
			self:DoModifyInfo()
            UIMgr.Close(self)
		else
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.BAI_LEI_NOT_IN_STAND)
		end
    end)

    UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function() --停止擂台
        if Player_IsBuffExist(ChallengeData.PK_BUFF_ID) then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CAN_NOT_RETRACT)
		else
			RemoteCallToServer("On_PK_PackUp")
            UIMgr.Close(self)
		end
    end)

    UIHelper.BindUIEvent(self.BtnChallenge, EventType.OnClick, function() --挑战
        local targetPlayer = GetPlayer(self.tChallengeInfo.nPlayerId)
        if targetPlayer then
            if not Player_IsBuffExist(ChallengeData.PK_BUFF_ID, targetPlayer) then
                if ChallengeData:GetBreakLeftTime(self.tChallengeInfo.dwBreakStartTime) == 0 then
                    RemoteCallToServer("On_PK_AskPK", self.tChallengeInfo.nPlayerId)
                else
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_TARGET_OFF_LINE)
                end
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_TARGET_IS_IN_PK)
            end
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_TARGET_NOT_EXIST)
        end
        UIMgr.Close(self)
    end)


    UIHelper.BindUIEvent(self.BtnModify, EventType.OnClick, function() --口号
        self.tbSloganScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsDeclaration, self.WidgetLeftBotton, self.tbSloganInfo)

    end)
end

function UIChallengePop:RegEvent()
    Event.Reg(self , "Modify_Slogan" , function (szSlogan,nIndex)
        UIHelper.SetString(self.LabelSlogan,string.format("%s", szSlogan))
        self.tChallengeInfo.nTitle = nIndex
        self:DoModifyInfo(true)
        UIHelper.RemoveFromParent(self.tbSloganScript._rootNode, true)
        self.tbSloganScript = nil
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.tbSloganScript then
            UIHelper.RemoveFromParent(self.tbSloganScript._rootNode, true)
            self.tbSloganScript = nil
        end

        if self.tbStateScript then
            UIHelper.RemoveFromParent(self.tbStateScript._rootNode, true)
            self.tbStateScript = nil
        end
    end)

    Event.Reg(self , "ON_LEITAI_UPDATESTATE" , function ()
        self:UpdateState()
        self:UpdateBreakCD()
    end)
end

function UIChallengePop:UnRegEvent()
    Event.UnReg(self, "Modify_Slogan")
    Event.UnReg(self, EventType.HideAllHoverTips)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChallengePop:UpdateInfo()
    self:UpdateAvatar()
    self:UpdatePkInfo()
    self:UpdateBottomBtn()
    self:UpdateSloganInfo()
    self:UpdateState()
    self:UpdateBreakCD()
    Timer.Add(self , 0.2 , function ()
        self:UpdateTotalTime()
    end)

    --self:UpdateLeiTaiState()
end

function UIChallengePop:UpdateAvatar()
    local headScript =  UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead,self.tChallengeInfo.nPlayerId)
    if headScript then
        headScript:SetClickCallback(function ()
            if GetClientPlayer().dwID == self.tChallengeInfo.nPlayerId then
                if not Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID	) then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CAN_NOT_OFF_LINE)
                else
                    self.tbStateScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsStatus, self.WidgetLeftTop)
                end
            end
        end)
    end
end

function UIChallengePop:UpdatePkInfo()
    UIHelper.SetString(self.LabelName,string.format("%s", UIHelper.GBKToUTF8(self.tChallengeInfo.szName)))
    UIHelper.SetString(self.LabelNum,string.format("%d", self.tChallengeInfo.nCurCombo ))
    UIHelper.SetString(self.LabelTodayPKNum,string.format("%d场", self.tChallengeInfo.nCurTotal ))
    UIHelper.SetString(self.LabelHistoryPKNum,string.format("%d场", self.tChallengeInfo.nTotal))
    UIHelper.SetString(self.LabelBestWinNum,string.format("%d场", self.tChallengeInfo.nCombo))
    UIHelper.SetString(self.LabelTodayWinNum,string.format("%d场", self.tChallengeInfo.nCurWin))
    UIHelper.SetString(self.LabelHistoryWinNum,string.format("%d场", self.tChallengeInfo.nWin))
end

function UIChallengePop:UpdateBottomBtn()
    local player = GetClientPlayer()
    local bInBaiLei = Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID)
    if self.tChallengeInfo.nPlayerId == player.dwID then
        UIHelper.SetVisible(self.BtnChallenge,false)
        UIHelper.SetVisible(self.BtnModify,true)
        UIHelper.SetVisible(self.LayoutTime,true)
        UIHelper.SetVisible(self.BtnStop,bInBaiLei)
        UIHelper.SetVisible(self.BtnBegin,not bInBaiLei)
    else
        UIHelper.SetVisible(self.BtnChallenge,not bInBaiLei)
        UIHelper.SetVisible(self.BtnModify,false)
		UIHelper.SetVisible(self.BtnBegin,false)
		UIHelper.SetVisible(self.BtnStop,false)
        UIHelper.SetVisible(self.LayoutTime,false)
    end
end

function UIChallengePop:UpdateSloganInfo()
    self.tbSloganInfo = ChallengeData.UpdateSloganInfo()
    if self.tbSloganInfo[self.tChallengeInfo.nTitle+1].szOption == '' then
        UIHelper.SetString(self.LabelSlogan,string.format("%s", UIHelper.GBKToUTF8(self.tbSloganInfo[2].szOption)))
    else
        UIHelper.SetString(self.LabelSlogan,string.format("%s", UIHelper.GBKToUTF8(self.tbSloganInfo[self.tChallengeInfo.nTitle+1].szOption)))
    end
end

function UIChallengePop:UpdateState()
    local player = GetClientPlayer()
    
    if player.dwID == self.tChallengeInfo.nPlayerId then
		if Player_IsBuffExist(ChallengeData.BREAK_BUFF_ID) then
            local nCDLeft = ChallengeData:GetBreakBuffLeftTime(ChallengeData.BREAK_BUFF_ID)
            local nTime = ChallengeData:GetTimeToMinuteDesc(nCDLeft, true)
            UIHelper.SetString(self.LabelTimeLeave,string.format("暂离[%02d:%02d]", nTime/60,nTime%60))
            UIHelper.LayoutDoLayout(self.LayoutState)
            self.nTimerID = Timer.AddCycle(self, 1, function ()
                nCDLeft = ChallengeData:GetBreakBuffLeftTime(ChallengeData.BREAK_BUFF_ID)
                if nCDLeft > 0 then
                    nTime = ChallengeData:GetTimeToMinuteDesc(nCDLeft, true)
                    UIHelper.SetString(self.LabelTimeLeave,string.format("暂离[%02d:%02d]", nTime/60,nTime%60))
                else
                    UIHelper.SetString(self.LabelTimeLeave,string.format("在线"))
                    --UIHelper.SetVisible(self.WidgetTips,false)
                    if self.tbStateScript then
                        UIHelper.RemoveFromParent(self.tbStateScript._rootNode, true)
                        self.tbStateScript = nil
                    end
                    UIHelper.SetSpriteFrame(self.ImgState, tImageState[1])
                    UIHelper.LayoutDoLayout(self.LayoutState)
                    Timer.DelTimer(self,self.nTimerID)
                end
                
            end)
        else
            UIHelper.SetString(self.LabelTimeLeave,string.format("在线"))
            UIHelper.LayoutDoLayout(self.LayoutState)
		end
	else
        local nBreakLeft = ChallengeData:GetBreakLeftTime(self.tChallengeInfo.dwBreakStartTime)
		if nBreakLeft > 0 then
            
            UIHelper.SetSpriteFrame(self.ImgState, tImageState[2])
            UIHelper.SetString(self.LabelTimeLeave,string.format("暂离[%02d:%02d]", nBreakLeft/60,nBreakLeft%60))
            UIHelper.LayoutDoLayout(self.LayoutState)
            self.nTimerID2 = Timer.AddCycle(self, 1, function()
                local nLeft = ChallengeData:GetBreakLeftTime(self.tChallengeInfo.dwBreakStartTime)
                if nLeft > 0 then
                    UIHelper.SetString(self.LabelTimeLeave,string.format("暂离[%02d:%02d]", nLeft/60,nLeft%60))
                else
                    Timer.DelTimer(self,self.nTimerID2)
                    UIHelper.SetString(self.LabelTimeLeave,string.format("在线"))
                    UIHelper.SetSpriteFrame(self.ImgState, tImageState[1])
                    UIHelper.LayoutDoLayout(self.LayoutState)
                end
                
            end)
		else
			UIHelper.SetSpriteFrame(self.ImgState, tImageState[1])
            UIHelper.SetString(self.LabelTimeLeave,string.format("在线"))
            UIHelper.LayoutDoLayout(self.LayoutState)
		end
        
	end
end


function UIChallengePop:UpdateTotalTime()
    local player = GetClientPlayer()
	if self.tChallengeInfo.nPlayerId ~= player.dwID then return end
	if Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID) then
		local nCDLeft = ChallengeData:GetBreakBuffLeftTime(ChallengeData.LEI_TAI_BUFF_ID)
        local nTime = ChallengeData:GetTimeToMinuteDesc(nCDLeft, true)
        UIHelper.SetString(self.LabelTime,string.format("%02d:%02d", nTime/60,nTime%60))
        self.nTimerID3 = Timer.AddCountDown(self, nTime, function(deltaTime)
            UIHelper.SetString(self.LabelTime,string.format("%02d:%02d", deltaTime/60,deltaTime%60))
        end,
        function()
            Timer.DelTimer(self,self.nTimerID3)
            if Player_IsBuffExist(ChallengeData.PK_BUFF_ID) then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CAN_NOT_RETRACT)
            else
                RemoteCallToServer("On_PK_PackUp")
                UIMgr.Close(self)
            end
        end)
	else
        local nTime = ChallengeData:GetTimeToMinuteDesc(ChallengeData.LEI_TAI_TOTAL_TIME, true)
        UIHelper.SetString(self.LabelTime,string.format("%02d:%02d", nTime/60,nTime%60))
	end
end

function UIChallengePop:UpdateBreakCD() --10min
    local player = GetClientPlayer()
    if player.dwID ~= self.tChallengeInfo.nPlayerId then return end
    if not Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID) then return end
    if Player_IsBuffExist(ChallengeData.PK_BUFF_ID) then return end

    if Player_IsBuffExist(ChallengeData.BREAK_BUFF_ID) then
        UIHelper.SetSpriteFrame(self.ImgState, tImageState[2])
    else
        UIHelper.SetSpriteFrame(self.ImgState, tImageState[1])
    end
end

function UIChallengePop:UpdateLeiTaiState()
    self.nTimerID5 = Timer.AddFrameCycle(self, 1, function()
        local player = GetClientPlayer()
        if player.dwID == self.tChallengeInfo.nPlayerId then
            if Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID) then
                self:AutoCloseByDistance()
            end
        else
            self:AutoCloseByDistance()
        end
    end)
end

function UIChallengePop:AutoCloseByDistance()
    local player = GetClientPlayer()
	local npc = GetNpc(self.tChallengeInfo.dwNpcID)
    if npc then
		local distance = (player.nX - npc.nX) * (player.nX - npc.nX) + (player.nY - npc.nY) * (player.nY - npc.nY)
		if distance > ChallengeData.AUTO_CLOSE_DISTANCE then
			UIMgr.Close(self)
		end
	else
		UIMgr.Close(self)
	end
end

function UIChallengePop:DoModifyInfo(bCheckBuff)
    if bCheckBuff then
		if not Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID	) then
			return
		end
	end
    RemoteCallToServer("On_PK_BaiTan", {
		nTitle 	= self.tChallengeInfo.nTitle,
		nHide 	= self.tChallengeInfo.nHide,
	})
end


return UIChallengePop