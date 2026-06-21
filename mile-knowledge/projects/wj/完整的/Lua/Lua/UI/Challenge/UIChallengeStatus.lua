-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIChallengeStatus
-- Date: 2023-10-10 10:15:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChallengeStatus = class("UIChallengeStatus")

function UIChallengeStatus:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIChallengeStatus:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChallengeStatus:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnAoutSellUp, EventType.OnClick, function() --在线
        RemoteCallToServer("On_PK_Break", false)
        Timer.Add(self , 0.2 , function ()
            --self:UpdateState()
            --self:UpdateBreakCD()
			Event.Dispatch("ON_LEITAI_UPDATESTATE")
			self:UpdateBreakCD()
        end)
        UIHelper.SetVisible(self.WidgetTips,false)
    end)

    UIHelper.BindUIEvent(self.BtnAoutSellBelow, EventType.OnClick, function() --暂离
        local player 	= GetClientPlayer()
        local nCDLeft 	= player.GetCDLeft(ChallengeData.BREAK_CD_ID)
        local nState 	= player.GetPKState()
        if nCDLeft > 0 then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.IS_IN_BREAK_CD)
        elseif nState == PK_STATE.DUELING or nState == PK_STATE.PREPARE_DUEL then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.IS_IN_PK)
        else
            local szMessage = g_tStrings.PK_OFF_LINE_MSG
            local fnConfirmAction = function()
                RemoteCallToServer("On_PK_Break", true)
                Timer.Add(self , 0.2 , function ()
                    --self:UpdateState()
                    --self:UpdateBreakCD()
					Event.Dispatch("ON_LEITAI_UPDATESTATE")
					self:UpdateBreakCD()
                end)
                UIHelper.SetVisible(self.WidgetTips,false)
            end
            local fnCancelAction = function() UIHelper.SetVisible(self.WidgetTips,false) end
        
            local dialog = UIHelper.ShowConfirm(szMessage, fnConfirmAction, fnCancelAction)
            dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
            dialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
        end

    end)
end

function UIChallengeStatus:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIChallengeStatus:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChallengeStatus:UpdateInfo()
	UIHelper.SetTouchDownHideTips(self.BtnAoutSellUp, false)
	UIHelper.SetTouchDownHideTips(self.BtnAoutSellBelow, false)
	self:UpdateBreakCD()
end

function UIChallengeStatus:UpdateBreakCD()
	local player = GetClientPlayer()
	local nCDLeft = player.GetCDLeft(ChallengeData.BREAK_CD_ID)
    if nCDLeft > 0 then
        UIHelper.SetEnable(self.BtnAoutSellBelow,false)
        UIHelper.SetButtonState(self.BtnAoutSellBelow,BTN_STATE.Disable)
        local szTime = ChallengeData:GetTimeToMinuteDesc(nCDLeft, true)
        UIHelper.SetString(self.LabAoutSellBelow,string.format("暂离(%d分钟)", math.ceil(szTime/60)))
        self.nTimerID4 = Timer.AddCountDown(self, szTime, function(deltaTime)
            UIHelper.SetString(self.LabAoutSellBelow,string.format("暂离(%d分钟)", math.ceil(deltaTime/60)))
        end,
        function()
            Timer.DelTimer(self,self.nTimerID4)
            UIHelper.SetEnable(self.BtnAoutSellBelow,true)
            UIHelper.SetString(self.LabAoutSellBelow,"暂离")
            UIHelper.SetButtonState(self.BtnAoutSellBelow,BTN_STATE.Normal)
        end)
    end
end

return UIChallengeStatus