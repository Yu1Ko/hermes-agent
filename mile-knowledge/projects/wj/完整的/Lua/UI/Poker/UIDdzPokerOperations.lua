-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerOperations
-- Date: 2023-08-10 17:26:05
-- Desc: 斗地主卡牌操作
-- ---------------------------------------------------------------------------------

local UIDdzPokerOperations = class("UIDdzPokerOperations")

function UIDdzPokerOperations:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerOperations:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerOperations:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRulesSetting , EventType.OnClick , function ()
        UIMgr.Open(VIEW_ID.PanelPokerRulesPop)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnReady , EventType.OnClick , function ()
        DdzPokerData.SendReadyStartGame(DdzPokerData.TABLE_SLOT_STATE.READY)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnShowReady , EventType.OnClick , function ()
        DdzPokerData.SendReadyStartGame(DdzPokerData.TABLE_SLOT_STATE.MINGPAI_READY)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnCancelPrepare , EventType.OnClick , function ()
        DdzPokerData.SendReadyStartGame(DdzPokerData.TABLE_SLOT_STATE.READY_TO_UNREADY)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnChupaiFirst , EventType.OnClick , function ()
        self.pokerView:PlayChuPaiCrad()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnChupai , EventType.OnClick , function ()
        self.pokerView:PlayChuPaiCrad()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnBuchu01 , EventType.OnClick , function ()
        self.pokerView:DownHandCards()
		self.pokerView:PassCard()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnBuchu00 , EventType.OnClick , function ()
        self.pokerView:DownHandCards()
		self.pokerView:PassCard()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnDemandNo , EventType.OnClick , function ()
        self.pokerView:CallDiZhu(DdzPokerData.DIZHU.BU_JIAO)
    end)

    UIHelper.BindUIEvent(self.BtnDemandYes , EventType.OnClick , function ()
        if DdzPokerData.DataModel.tGameData["Down"].nState == DdzPokerData.PLAYER_STATE.CAN_CALL then
            self.pokerView:CallDiZhu(DdzPokerData.DIZHU.JIAO_DIZHU)
		end
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnGrabNo , EventType.OnClick , function ()
        self.pokerView:CallDiZhu(DdzPokerData.DIZHU.BU_QIANG)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnGrabYes , EventType.OnClick , function ()
        if DdzPokerData.DataModel.tGameData["Down"].nState == DdzPokerData.PLAYER_STATE.CAN_QIANG then
            self.pokerView:CallDiZhu(DdzPokerData.DIZHU.QIANG_DIZHU)
		end
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnShowHandNo , EventType.OnClick , function ()
        self.pokerView:HideOp()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)
    

    UIHelper.BindUIEvent(self.BtnShowHand , EventType.OnClick , function ()
        self.pokerView:SetPlayerMingPai()
        self.pokerView:HideOp()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnBuJiabei , EventType.OnClick , function ()
        self.pokerView:CallDouble(DdzPokerData.DOUBLE.BU_JIABEI)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnSuperJiabei , EventType.OnClick , function ()
        self.pokerView:CallDouble(DdzPokerData.DOUBLE.SUPER_JIABEI)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnJiabei , EventType.OnClick , function ()
        self.pokerView:CallDouble(DdzPokerData.DOUBLE.JIABEI)
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)

    UIHelper.BindUIEvent(self.BtnTishi , EventType.OnClick , function ()
        self.pokerView:UpdateTishi()
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szChooseCard"))
    end)

    UIHelper.BindUIEvent(self.BtnFindGroup , EventType.OnClick , function ()
        local player = GetClientPlayer()
        if player.nLevel < 110 then
            TipsHelper.ShowNormalTip("侠士达到110级后方可发布招募")
        else
            UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, nil, 277)
        end
        SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szConfirm"))
    end)
end

function UIDdzPokerOperations:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerOperations:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerOperations:Init(pokerView)
    self:InitButtonDouble()
    self:HideOp()
    self.pokerView = pokerView
end

function UIDdzPokerOperations:UpdateInfo()
    
end


function UIDdzPokerOperations:InitButtonDouble()
    UIHelper.SetString(self.LabelPrepareTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_MINGPAI_STATE_INIT])
    UIHelper.SetString(self.LabelShowHandTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_MINGPAI_STATE_SHUFFLE])
    UIHelper.SetString(self.LabelSuperJiabeiTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_SUPER])
    UIHelper.SetString(self.LabelJiabeiTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_DOUBLE_TYPE_NORMAL])
    UIHelper.SetString(self.LabelDemandYesTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_CHAIRMAN_CALL])
    UIHelper.SetString(self.LabelGrabYesTimes , g_tStrings.STR_MUL .. DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_CHAIRMAN_ROB])
end

function UIDdzPokerOperations:HideOp()
    UIHelper.SetVisible(self._rootNode , false)
end

function UIDdzPokerOperations:ShowOp()
    UIHelper.SetVisible(self._rootNode , true)
end

function UIDdzPokerOperations:UpdateReadyButtom()
    if DdzPokerData.DownIsReady() then
		self:ShowCanelReady()
		return
	end
	if DdzPokerData.DownIsHost() then
		self:ShowHostReady()
	else
		self:ShowNormalReady()
	end
end

function UIDdzPokerOperations:ShowCanelReady()
    if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateReadyButton(false, true)
end

function UIDdzPokerOperations:ShowNormalReady()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateReadyButton(false, false)
end

function UIDdzPokerOperations:ShowHostReady()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateReadyButton(true, false)
end

function UIDdzPokerOperations:UpdateReadyButton(bSetting, bIsReady)
	self:UpdateButtonParent(false, true, false, false, false, false)
    UIHelper.SetVisible(self.BtnShowReady ,not bIsReady)
    UIHelper.SetVisible(self.BtnRulesSetting ,bSetting)
    UIHelper.SetVisible(self.BtnReady ,not bIsReady)
    UIHelper.SetVisible(self.BtnFindGroup ,not bIsReady)
    UIHelper.SetVisible(self.BtnCancelPrepare ,bIsReady)
end

function UIDdzPokerOperations:UpdateButtonParent(bPlay, bReady, bDemand, bGrab, bMingPai, bJiaBei)
	self:ShowOp()
    UIHelper.SetVisible(self.WidgetPlaying , bPlay)
    UIHelper.SetVisible(self.WidgetPrepare , bReady)
    UIHelper.SetVisible(self.WidgetGrabDizhu , bGrab)
    UIHelper.SetVisible(self.WidgetDemandDizhu , bDemand)
    UIHelper.SetVisible(self.WidgetJiabei , bJiaBei)
    UIHelper.SetVisible(self.WidgetShowHand , bMingPai)
    
end

function UIDdzPokerOperations:UpdateBuchuTip(bShow)
	UIHelper.SetVisible(self.WidgetBuChuTips , bShow)

end

function UIDdzPokerOperations:UpdatePlayingButton(bNextChu, bFreeChu, bBuChu)
	self:UpdateButtonParent(true, false, false, false, false, false)
    UIHelper.SetVisible(self.BtnBuchu01 , bBuChu)
    UIHelper.SetVisible(self.WidgetAffordable , bNextChu)
    UIHelper.SetVisible(self.BtnChupaiFirst , bFreeChu)
end

function UIDdzPokerOperations:ShowNextChuButton()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdatePlayingButton(true, false, false)
end

function UIDdzPokerOperations:ShowFreeChuButton()
	if DdzPokerData.DownIsHosting()  then
		return
	end
	self:UpdatePlayingButton(false, true, false)
end

function UIDdzPokerOperations:ShowBuChuButton()
	if DdzPokerData.DownIsHosting()  then
		return
	end
	self:UpdatePlayingButton(false, false, true)
end

function UIDdzPokerOperations:ShowGrabButton()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateButtonParent(false, false, false, true, false, false)
end

function UIDdzPokerOperations:ShowDemandButton()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateButtonParent(false, false, true, false, false, false)
end

function UIDdzPokerOperations:ShowMingPiaButton()
	if DdzPokerData.DownIsHosting() then
		return
	end
	self:UpdateButtonParent(false, false, false, false, true, false)
end

function UIDdzPokerOperations:ShowJiaBeiButton()
	if DdzPokerData.DownIsHosting() then
		return
	end
    self:UpdateButtonParent(false, false, false, false, false, true)
end



return UIDdzPokerOperations