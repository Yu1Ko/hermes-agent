-- ---------------------------------------------------------------------------------
-- Name: UITimelyHintTip
-- Date: 2023-10-19
-- PanelHintTop WidgetTimelyHint
-- ---------------------------------------------------------------------------------

---@class UITimelyHintTip
local UITimelyHintTip = class("UITimelyHintTip")

local TimelyHintType = {
    Team      = 1,--队伍
    Like      = 2,--点赞
}

local nShowTime = 180
local LIKE_TYPE_TO_TITLE = {
    [0]     = "好团长",
    [1]     = "好师父",
    [2]     = "好镖师",
    [3]     = "群龙之首",
    [4]     = "一代军师",
    [5]     = "名剑名侠",
    [6]     = "沙场豪杰",
    [7]     = "侠者仁心",
}

local tViewBlackList = {
    [1] = VIEW_ID.PanelLoading,
    [2] = VIEW_ID.PanelInvitationMessagePop,
    [3] = VIEW_ID.PanelArenaConfirmPop
}

function UITimelyHintTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIHelper.SetVisible(self._rootNode, false)
        self.bInit = true

        self.nSmallTimer = {} -- 定时器ID
        self.nSmallRemain = {} -- 记录当前剩余time
        self.tSmallWidget = {
            [TipsHelper.GetEventOrder(EventType.ShowTradeTip)] = self.WidgetTrade,
            [TipsHelper.GetEventOrder(EventType.ShowTeamTip)] = self.WidgetTeam,
            [TipsHelper.GetEventOrder(EventType.ShowLikeTip)] = self.WidgetLike,
            [TipsHelper.GetEventOrder(EventType.ShowInteractTip)] = self.WidgetInteract,
        }
        self.tSmallSlider = {
            [TipsHelper.GetEventOrder(EventType.ShowTradeTip)] = self.SilderTradeTimely,
            [TipsHelper.GetEventOrder(EventType.ShowTeamTip)] = self.SilderTeamTimely,
            [TipsHelper.GetEventOrder(EventType.ShowLikeTip)] = self.SilderLikeTimely,
            [TipsHelper.GetEventOrder(EventType.ShowInteractTip)] = self.SilderInteractTimely,
        }
        self.tSmallBtn = {
            [TipsHelper.GetEventOrder(EventType.ShowTradeTip)] = self.BtnTradeHint,
            [TipsHelper.GetEventOrder(EventType.ShowTeamTip)] = self.BtnTeam,
            [TipsHelper.GetEventOrder(EventType.ShowLikeTip)] = self.BtnLikeSlider,
            [TipsHelper.GetEventOrder(EventType.ShowInteractTip)] = self.BtnInteractHint,
        }
        self.tSmallCount = {
            [TipsHelper.GetEventOrder(EventType.ShowTradeTip)] = self.LabelTradeCount,
            [TipsHelper.GetEventOrder(EventType.ShowTeamTip)] = self.LabelTeamCount,
            [TipsHelper.GetEventOrder(EventType.ShowLikeTip)] = self.LabelLikeCount,
            [TipsHelper.GetEventOrder(EventType.ShowInteractTip)] = self.LabelInteractCount,
        }
        self.tSmallBubbleType = {
            [TipsHelper.GetEventOrder(EventType.ShowTradeTip)] = "TradeInviteTip",
            [TipsHelper.GetEventOrder(EventType.ShowTeamTip)] = "TeamInvite",
            [TipsHelper.GetEventOrder(EventType.ShowRoomTip)] = "RoomInvite",
            [TipsHelper.GetEventOrder(EventType.ShowLikeTip)] = "AddLikeTip",
            [TipsHelper.GetEventOrder(EventType.ShowInteractTip)] = "InteractInvite",
        }
    end
end

function UITimelyHintTip:OnExit()
    self.bInit = false
end

function UITimelyHintTip:BindUIEvent()

end

function UITimelyHintTip:RegEvent()
    Event.Reg(self, EventType.OnCloseLikeTip, function (bClose)
        if bClose == true then
            self:funcCloseTip(self.WidgetLike)
        else
            UIHelper.SetVisible(self.WidgetLike, true)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        for _, nId in ipairs(tViewBlackList) do
            if nViewID == nId then
                self:UpdateVisible()
                return
            end
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        for _, nId in ipairs(tViewBlackList) do
            if nViewID == nId then
                if nViewID == VIEW_ID.PanelArenaConfirmPop then
                    if self.tInfo and self.tInfo[2].szType == "PKDuelInviteTip" then
                        self:funcCloseTip(self.WidgetTimelyLikeOnly)
                    end
                else
                    self:UpdateVisible()
                end
                return
            end
        end
    end)

    Event.Reg(self, EventType.OnTimelyHintTipsSwitchToSmall, function(b2Small, szEventName)
        local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
        if tEvent[1] == szEventName then
            if not TipsHelper.GetSmallEvent(szEventName) then
                local order = TipsHelper.GetEventOrder(szEventName)
                self.nSmallRemain[order] = self.nSmallRemain[order] or tEvent.nEndTime

                TipsHelper.SetSmallEvent(tEvent)
                self:SwitchToSmallOrBig(b2Small, szEventName)
            end
        end
    end)

    Event.Reg(self, EventType.TryCloseBubbleMsgOnly, function(szType)
        local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
        if tEvent and tEvent[2].szType and szType == tEvent[2].szType and self.WidgetBubbleMsgOnly then
            self:funcCloseTip(self.WidgetBubbleMsgOnly)
        end
    end)
end

function UITimelyHintTip:UpdateVisible()
    for _, nId in ipairs(tViewBlackList) do
        if UIMgr.IsViewOpened(nId) then
            UIHelper.SetVisible(self._rootNode, false)
            return
        end
    end
    UIHelper.SetVisible(self._rootNode, true)
end

function UITimelyHintTip:HideCurEvent(szEventName, bStore)
    if TipsHelper.CheckCanSmall(TipsHelper.Def.Queue3, szEventName) then
        if bStore then
            local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
            if tEvent then
                TipsHelper.SetSmallEvent(tEvent)
            end
        end
        self:SwitchToSmallOrBig(true, szEventName)
    else
        TipsHelper.DispatchCloseEvent(szEventName)
    end
end

function UITimelyHintTip:UpdateBubbleMsgBar()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowMessageBubble then
        return
    end

    UIHelper.SetVisible(self._rootNode, true)
    if not self.scriptBubbleMsgBar then
        self.scriptBubbleMsgBar = UIHelper.GetBindScript(self.WidgetBubbleMsgOnly)
        self.scriptBubbleMsgBar:OnEnter()
    end
    self.scriptBubbleMsgBar:UpdateInfo(tEvent[2])
end

function UITimelyHintTip:UpdateBubbleMsgIcon(szEventName)
    local order = TipsHelper.GetEventOrder(szEventName)
    local tEvent = TipsHelper.GetSmallEvent(szEventName)
    local nLeftTime = self.nSmallRemain[order] or 0
    local nTotalTime = nShowTime
    local nEndTime = nLeftTime + GetCurrentTime()
    if szEventName == EventType.ShowTeamTip then
        nLeftTime, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.Team)
        self.nSmallRemain[order] = nLeftTime
    elseif szEventName == EventType.ShowAssistNewbieInviteTip then
        nLeftTime, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.AssistNewbie)
        self.nSmallRemain[order] = nLeftTime
    elseif szEventName == EventType.ShowRoomTip then
        nLeftTime, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.Room)
        self.nSmallRemain[order] = nLeftTime
    elseif szEventName == EventType.ShowTradeTip then
        nTotalTime = TradeData.GetTimelyHintMaxExistTime()
    end
    local szBubbleType = self.tSmallBubbleType[order]
    BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
    BubbleMsgData.PushMsgWithType(szBubbleType, {
        szType = szBubbleType, 		                        -- 类型(用于排重)
        nBarTime = 0, 							            -- 显示在气泡栏的时长, 单位为秒
        nLeftTime = nLeftTime or 0,
        nTotalTime = nTotalTime or 0,
        fnAutoClose = tEvent[2].fnAutoClose or nil,
        szAction = function ()
            if szEventName == EventType.ShowTeamTip then
                TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Team)
            elseif szEventName == EventType.ShowAssistNewbieInviteTip then
                TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.AssistNewbie)
            elseif szEventName == EventType.ShowRoomTip then
                TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Room)
            elseif szEventName == EventType.ShowLikeTip and #tEvent[2] > 1 then
                local scriptView = UIMgr.Open(VIEW_ID.PanelInvitationMessagePop)
                if scriptView then
                    local nLeftTime1 = nEndTime - GetCurrentTime()
                    nLeftTime1 = math.max(0, nLeftTime1)
                    scriptView:UpdateLikeMore(tEvent[3], nLeftTime1, tEvent[2], function ()
                        Timer.DelTimer(self, self.nTimer)
                        self.nTimer = nil
                        local OldEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
                        if OldEvent then
                            self:HideCurEvent(OldEvent[1], true)
                        end
                        BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
                        TipsHelper.ClearSmallEvent(szEventName)
                    end)
                end
            else
                Timer.DelTimer(self, self.nTimer)
                self.nTimer = nil
                local OldEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
                if OldEvent then
                    self:HideCurEvent(OldEvent[1], true)
                end
                BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
                tEvent.nEndTime = nLeftTime + GetCurrentTime()
                tEvent.nRemain = nil
                tEvent[2].bFromBubbleIcon = true
                TipsHelper.PushEvent(TipsHelper.Def.Queue3, tEvent)
                TipsHelper.ClearSmallEvent(szEventName)
                Event.Dispatch(unpack(tEvent))
            end
        end,
    })

    if self.nSmallTimer[order] then
        Timer.DelTimer(self, self.nSmallTimer[order])
        self.nSmallTimer[order] = nil
    end

    local nFrameRemain = (self.nSmallRemain[order] or 0) + GetCurrentTime()
    -- UIHelper.SetProgressBarPercent(self.tSmallSlider[order],  self.nSmallRemain[order] / nFrameTotal * 100)
    self.nSmallTimer[order] = Timer.AddFrameCycle(self, 3, function ()
        local nCurTime = GetCurrentTime()
        self.nSmallRemain[order] = nFrameRemain - nCurTime
        -- UIHelper.SetProgressBarPercent(self.tSmallSlider[order],  nFrameRemain / nFrameTotal * 100)

        if nFrameRemain <= nCurTime then
            -- UIHelper.SetVisible(self.tSmallWidget[order], false)
            BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
            Timer.DelTimer(self, self.nSmallTimer[order])
            self.nSmallTimer[order] = nil
            TipsHelper.ClearSmallEvent(szEventName)
            if tEvent[2] and tEvent[2].fnCancelAction then
                tEvent[2].fnCancelAction()
            end
            TipsHelper.NextTip(TipsHelper.Def.Queue3)
        end
    end)
end

function UITimelyHintTip:SwitchToSmallOrBig(b2Small, szEventName)
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end
    local beforeEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    local order = TipsHelper.GetEventOrder(szEventName)
    local tEvent = TipsHelper.GetSmallEvent(szEventName)
    local bMore = false
    if szEventName == EventType.ShowTeamTip
    or szEventName == EventType.ShowRoomTip
    or szEventName == EventType.ShowAssistNewbieInviteTip
    or (szEventName == EventType.ShowLikeTip and #tEvent[2] > 1) then
        bMore = true
    end

    if b2Small then
        self:UpdateBubbleMsgIcon(szEventName)
        if bMore == true then
            UIHelper.SetVisible(self.WidgetTimelyMore, false)
        else
            UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
            UIHelper.SetString(self.tSmallCount[order], 1)
            UIHelper.BindUIEvent(self.tSmallBtn[order], EventType.OnClick, function ()
                self:SwitchToSmallOrBig(false, szEventName)
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutTimelyHintSmall)
    else
        -- local beforeEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
        -- if beforeEvent then
        --     self:HideCurEvent(beforeEvent[1], true)
        -- end
        -- UIHelper.SetVisible(self.tSmallWidget[order], false)
        BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
        if self.nSmallTimer[order] then
            Timer.DelTimer(self, self.nSmallTimer[order])
            self.nSmallTimer[order] = nil
        end

        tEvent.nRemain = self.nSmallRemain[order]
        TipsHelper.SetCurEvent(TipsHelper.Def.Queue3, tEvent)
        TipsHelper.ClearSmallEvent(szEventName)
        Event.Dispatch(unpack(tEvent))
        UIHelper.LayoutDoLayout(self.LayoutTimelyHintSmall)
    end
end

function UITimelyHintTip:funcCloseTip(node)
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end
    UIHelper.SetVisible(node, false)
    TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
    TipsHelper.NextTip(TipsHelper.Def.Queue3)
    -- UIHelper.SetVisible(self._rootNode, false)
end

function UITimelyHintTip:SetSliderCountDown(bMore, nCountDown, szEventName, fnCancelAction, customSliderTimelyLikeBar)
    -- 10 = 30 / 3 30 = nFrameCount
    local order = TipsHelper.GetEventOrder(szEventName)
    if self.nSmallTimer[order] then
        Timer.DelTimer(self, self.nSmallTimer[order])
        self.nSmallTimer[order] = nil
    end
    local nTotalTime = nShowTime
    if szEventName == EventType.ShowTeamTip then
        nCountDown, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.Team)
    elseif szEventName == EventType.ShowAssistNewbieInviteTip then
        nCountDown, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.AssistNewbie)
    elseif szEventName == EventType.ShowMobaSurrenderTip then
        nTotalTime = nCountDown
    elseif szEventName == EventType.ShowTeamReadyConfirmTip then
        nTotalTime = nCountDown
    elseif szEventName == EventType.ShowRoomTip then
        nCountDown, nTotalTime = TimelyMessagesBtnData.GetMaxLeftTime(TimelyMessagesType.Room)
    elseif szEventName == EventType.ShowTradeTip then
        nTotalTime = TradeData.GetTimelyHintMaxExistTime()
    end
    local nCurTime = GetTickCount()
    local nEndTime = nCountDown * 1000 + nCurTime

    local slider = self.SliderTimelyLikeBar
    if customSliderTimelyLikeBar then
        --- WidgetHintBubbleMsgOnly 需要使用单独的slider
        slider = customSliderTimelyLikeBar
    end

    UIHelper.SetProgressBarPercent(slider, nCountDown / nTotalTime * 100)
    if not self.nTimer then
        self.nTimer = Timer.AddFrameCycle(self, 3, function()
            local nCurrentTime = GetTickCount()
            self.nRemain = math.floor((nEndTime - nCurrentTime) / 1000)
            self.nSmallRemain[order] = self.nRemain
            local fPercent = (nEndTime - nCurrentTime) / 1000 / nTotalTime
            if bMore == true then
                UIHelper.SetProgressBarPercent(self.SliderTimelyMoreBar, fPercent * 100)
                UIHelper.SetProgressBarPercent(self.SilderLikeTimely, fPercent * 100)
            else
                UIHelper.SetProgressBarPercent(slider, fPercent * 100)
            end

            if fPercent <= 0 then
                if bMore == true then
                    -- UIHelper.SetVisible(self.WidgetLike, false)
                    UIHelper.SetVisible(self.WidgetTimelyMore, false)
                else
                    local widgetParent = self.WidgetTimelyLikeOnly
                    if customSliderTimelyLikeBar then
                        widgetParent = UIHelper.GetParent(customSliderTimelyLikeBar)
                    end
                    UIHelper.SetVisible(widgetParent, false)
                end

                if fnCancelAction then
                    fnCancelAction()
                end
                Timer.DelTimer(self, self.nTimer)
                self.nTimer = nil
                TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
                TipsHelper.NextTip(TipsHelper.Def.Queue3)
            end
        end)
    end
end

function UITimelyHintTip:SetAutoConfirmCountDown(szTitle, nCountDown, szEventName, fnConfirmAction)
    local order = TipsHelper.GetEventOrder(szEventName)
    if self.nSmallTimer[order] then
        Timer.DelTimer(self, self.nSmallTimer[order])
        self.nSmallTimer[order] = nil
    end
    local nTotalTime = nCountDown
    local nCurTime = GetTickCount()
    local nEndTime = nCountDown * 1000 + nCurTime

    UIHelper.SetProgressBarPercent(self.SliderTimelyLikeBar, nCountDown / nTotalTime * 100)
    UIHelper.SetLabel(self.LabelLikeType, string.format("%s<color=#FFEA88>(%ds后同意)</color>", szTitle, nCountDown))
    if not self.nTimer then
        self.nTimer = Timer.AddFrameCycle(self, 3, function()
            local nCurrentTime = GetTickCount()
            self.nRemain = math.floor((nEndTime - nCurrentTime) / 1000)
            self.nSmallRemain[order] = self.nRemain
            local fPercent = (nEndTime - nCurrentTime) / 1000 / nTotalTime
            UIHelper.SetLabel(self.LabelLikeType, string.format("%s<color=#FFEA88>(%ds后同意)</color>", szTitle, self.nRemain))
            UIHelper.SetProgressBarPercent(self.SliderTimelyLikeBar, fPercent * 100)

            if fPercent <= 0 then
                UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
                if fnConfirmAction then
                    fnConfirmAction()
                end
                Timer.DelTimer(self, self.nTimer)
                self.nTimer = nil
                TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
                TipsHelper.NextTip(TipsHelper.Def.Queue3)
            end
        end)
    end
end

--------------------------------点赞--------------------------------
function UITimelyHintTip:UpdateLikeInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowLikeTip then
        return
    end
    self:HideAllWidgets()
    self.tInfo = tEvent -- szEventname, tInfo, ntype, hideevent
    if self.tInfo then
        if self.tInfo[4] then
            self:HideCurEvent(self.tInfo[4])
        end

        if #self.tInfo[2] > 1 then
            self:UpdateLikeMore()
        else
            self:UpdateLikeOne()
        end
    end
end

function UITimelyHintTip:UpdateLikeOne()

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
    UIHelper.SetVisible(self.WidgetLikeHead, true)
    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetVisible(self.WidgetHeadInfo, true)
    UIHelper.SetVisible(self.BtnLike, true)
    UIHelper.SetVisible(self.BtnGet, false)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    local tLike = self.tInfo[2][1]
    local nType = self.tInfo[3]
    local szTitle = LIKE_TYPE_TO_TITLE[nType]
    UIHelper.SetLabel(self.LabelLikeType, szTitle .. "点赞")
    UIHelper.SetString(self.LabelLikeName, UIHelper.GBKToUTF8(tLike.szName))
    CampData.SetUICampImg(self.ImgGroup, nil)
    UIHelper.LayoutDoLayout(self.LayoutName)
    UIHelper.SetProgressBarPercent(self.SliderTimelyLikeBar, 100)

    local scriptHeadInfo = UIHelper.GetBindScript(self.WidgetHeadInfo)
    scriptHeadInfo:SetPlayerID(tLike.dwID)
    local dwMiniAvatarID = tLike.dwMiniAvatarID or 0
    if dwMiniAvatarID < 0 then
        dwMiniAvatarID = 0
    end
    scriptHeadInfo:SetHeadInfo(tLike.dwID, dwMiniAvatarID, tLike.nRoleType or 0, tLike.dwForceID or 0)

    local order = TipsHelper.GetEventOrder(self.tInfo[1])
    if self.tInfo.nRemain and self.tInfo.nRemain < nShowTime then
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(false, self.tInfo.nRemain, self.tInfo[1])
    else
        self.nSmallRemain[order] = nShowTime
        self:SetSliderCountDown(false, nShowTime, self.tInfo[1])
    end

    UIHelper.BindUIEvent(self.BtnLike, EventType.OnClick, function ()
        if g_pClientPlayer and g_pClientPlayer.dwID then
            RemoteCallToServer("On_FriendPraise_AddRequest", g_pClientPlayer.dwID, tLike.dwID, nType, tLike.szGID)
        end
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function ()
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
    end)
end

function UITimelyHintTip:UpdateLikeMore()

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetTimelyMore, true)
    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetSpriteFrame(self.ImgTimelyMoreIcon, "UIAtlas2_MainCity_BubbleInfomation_icon_07")

    local tLikes = self.tInfo[2]
    local nType = self.tInfo[3]
    local szTitle = string.format(g_tStrings.STR_LIKE_MORE, #tLikes, LIKE_TYPE_TO_TITLE[nType])
    UIHelper.SetRichText(self.LabelTimeLyInfo, szTitle)
    UIHelper.SetString(self.LabelLikeCount, #tLikes)

    UIHelper.SetProgressBarPercent(self.SliderTimelyMoreBar, 100)
    UIHelper.SetProgressBarPercent(self.SilderTimely, 100)

    local order = TipsHelper.GetEventOrder(self.tInfo[1])
    if self.tInfo.nRemain and self.tInfo.nRemain < nShowTime then
        UIHelper.SetProgressBarPercent(self.SliderTimelyMoreBar, self.tInfo.nRemain * 10)
        UIHelper.SetProgressBarPercent(self.SilderTimely, self.tInfo.nRemain * 10)
        self.nRemain = self.tInfo.nRemain
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(true, self.tInfo.nRemain, self.tInfo[1])
    else
        UIHelper.SetProgressBarPercent(self.SliderTimelyMoreBar, 100)
        UIHelper.SetProgressBarPercent(self.SilderTimely, 100)
        self.nRemain = nShowTime
        self.nSmallRemain[order] = nShowTime
        self:SetSliderCountDown(true, nShowTime, self.tInfo[1])
    end

    UIHelper.BindUIEvent(self.BtnLikeSlider, EventType.OnClick, function ()
        if self.nRemain > 0 then
            local scriptView = UIMgr.Open(VIEW_ID.PanelInvitationMessagePop)
            if scriptView then
                scriptView:UpdateLikeMore(nType, self.nRemain, tLikes)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(self.tInfo)
        self:SwitchToSmallOrBig(true, self.tInfo[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        if self.nRemain > 0 then
            TipsHelper.SetSmallEvent(self.tInfo)
            self:SwitchToSmallOrBig(true, self.tInfo[1])
            TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
            local scriptView = UIMgr.Open(VIEW_ID.PanelInvitationMessagePop)
            if scriptView then
                scriptView:UpdateLikeMore(nType, self.nRemain, tLikes, function ()
                    Timer.DelTimer(self, self.nTimer)
                    self.nTimer = nil
                    local OldEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
                    local szEventName = self.tInfo[1]
                    if OldEvent then
                        self:HideCurEvent(OldEvent[1], true)
                    end
                    local order = TipsHelper.GetEventOrder(EventType.ShowLikeTip)
                    BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
                    TipsHelper.ClearSmallEvent(szEventName)
                end)
            end
        end
    end)
end

--------------------------------组队--------------------------------
function UITimelyHintTip:UpdateTeamInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowTeamTip then
        return
    end
    if tEvent[3] then
        self:HideCurEvent(tEvent[3])
    end
    
    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Team)
    if TipsHelper.JudgeSmallEventExist(tEvent[1]) then
        if #tbInfos > 0 then
            self:UpdateBubbleMsgIcon(tEvent[1])
        else
            local order = TipsHelper.GetEventOrder(EventType.ShowTeamTip)
            BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
            Timer.DelTimer(self, self.nSmallTimer[order])
            self.nSmallTimer[order] = nil
            TipsHelper.ClearSmallEvent(tEvent[1])
        end
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)

    if #tbInfos == 1 then
        local szInviteSrc, dwSrcCamp = table.unpack(tbInfos[1].tbParams)
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
        UIHelper.SetVisible(self.WidgetLikeHead, true)
        UIHelper.SetVisible(self.ImgInteractTipIcon, false)
        UIHelper.SetVisible(self.WidgetHeadInfo, true)
        UIHelper.SetVisible(self.BtnLike, false)
        UIHelper.SetVisible(self.BtnGet, true)
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
        UIHelper.SetLabel(self.LabelLikeType, "组队邀请")
        UIHelper.SetLabel(self.LabelLikeName, UIHelper.GBKToUTF8(szInviteSrc), 5)
        CampData.SetUICampImg(self.ImgGroup, dwSrcCamp)
        UIHelper.LayoutDoLayout(self.LayoutName)
        local scriptHeadInfo = UIHelper.GetBindScript(self.WidgetHeadInfo)
        scriptHeadInfo:SetTeamInfo(tbInfos[1].tbParams)
    elseif #tbInfos > 1 then
        local szRichText = string.format("<color=#D7F6FF>你有</c><color=#ffe26e>%d个</color><color=#D7F6FF>组队邀请</c>", #tbInfos)
        UIHelper.SetRichText(self.LabelTimeLyInfo, szRichText)
        UIHelper.SetVisible(self.WidgetTimelyMore, true)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        UIHelper.SetVisible(self.ImgInteractTipIcon, false)
        UIHelper.SetSpriteFrame(self.ImgTimelyMoreIcon, "UIAtlas2_MainCity_BubbleInfomation_icon_06")
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    if #tbInfos > 0 then
        self:SetSliderCountDown(#tbInfos > 1, 0, tEvent[1])
    else
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Team)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Team)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcConfirm then
                tbInfo.funcConfirm()
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Team)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcCancel then
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
                tbInfo.funcCancel()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Team)
    end)
end

--------------------------------新手援助--------------------------------
function UITimelyHintTip:UpdateAssistNewbieInvite()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowAssistNewbieInviteTip then
        return
    end
    if tEvent[3] then
        self:HideCurEvent(tEvent[3])
    end

    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.AssistNewbie)
    if TipsHelper.JudgeSmallEventExist(tEvent[1]) then
        if #tbInfos > 0 then
            self:UpdateBubbleMsgIcon(tEvent[1])
        else
            local order = TipsHelper.GetEventOrder(EventType.ShowAssistNewbieInviteTip)
            BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
            Timer.DelTimer(self, self.nSmallTimer[order])
            self.nSmallTimer[order] = nil
            TipsHelper.ClearSmallEvent(tEvent[1])
        end
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)

    if #tbInfos == 1 then
        local tAssistInfo = tbInfos[1].tbParams.tAssistInfo
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
        UIHelper.SetVisible(self.WidgetLikeHead, true)
        UIHelper.SetVisible(self.ImgInteractTipIcon, false)
        UIHelper.SetVisible(self.WidgetHeadInfo, true)
        UIHelper.SetVisible(self.BtnLike, false)
        UIHelper.SetVisible(self.BtnGet, true)
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
        UIHelper.SetLabel(self.LabelLikeType, "新人援助邀请")
        UIHelper.SetLabel(self.LabelLikeName, UIHelper.GBKToUTF8(tAssistInfo.szName))
        UIHelper.SetVisible(self.ImgGroup, false)
        UIHelper.LayoutDoLayout(self.LayoutName)
        local scriptHeadInfo = UIHelper.GetBindScript(self.WidgetHeadInfo)
        scriptHeadInfo:SetAssistHeadInfo(tAssistInfo.dwPlayerID, tAssistInfo.dwMiniAvatarID, tAssistInfo.nRoleType, tAssistInfo.dwForceID)
    elseif #tbInfos > 1 then
        local szRichText = string.format("<color=#D7F6FF>你有</c><color=#ffe26e>%d个</color><color=#D7F6FF>新人援助邀请</c>", #tbInfos)
        UIHelper.SetRichText(self.LabelTimeLyInfo, szRichText)
        UIHelper.SetVisible(self.WidgetTimelyMore, true)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        UIHelper.SetVisible(self.ImgInteractTipIcon, false)
        UIHelper.SetSpriteFrame(self.ImgTimelyMoreIcon, "UIAtlas2_MainCity_BubbleInfomation_icon_06")
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    if #tbInfos > 0 then
        self:SetSliderCountDown(#tbInfos > 1, 0, tEvent[1])
    else
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.AssistNewbie)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.AssistNewbie)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcConfirm then
                tbInfo.funcConfirm()
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.AssistNewbie)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcCancel then
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
                tbInfo.funcCancel()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.AssistNewbie)
    end)
end

--------------------------------Moba投降--------------------------------
function UITimelyHintTip:UpdateMobaSurrenderInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowMobaSurrenderTip then
        return
    end

    local tInfo = BattleFieldData.tSurrenderData

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetBubbleMsgOnly, true)

    ---@type UIWidgetHintBubbleMsgOnly
    local script = UIHelper.GetBindScript(self.WidgetBubbleMsgOnly)

    UIHelper.SetVisible(UIHelper.GetParent(script.WidgetHeadInfo), false)
    UIHelper.SetVisible(script.LayoutName, false)
    UIHelper.SetVisible(script.LabelLikeType, false)
    UIHelper.SetVisible(script.WidgetLabelHint, true)

    --UIHelper.SetString(script.LabelLabelHintType, UIHelper.GBKToUTF8(tInfo.szMessage))
    --UIHelper.SetVisible(script.LayoutLabelHintName, false)
    UIHelper.SetString(script.LabelLabelHintType, "我方队友发起投降")
    UIHelper.SetString(script.LabelLabelHintName, "是否投降（超时则拒绝投降）")
    UIHelper.SetVisible(script.ImgLabelHintGroup, false)
    UIHelper.LayoutDoLayout(script.LayoutLabelHintName)

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    local fnOK = function()
        RemoteCallToServer("OnMessageBoxRequest", tInfo.nMessageID, true, tInfo.param1)

        UIHelper.SetVisible(self.WidgetBubbleMsgOnly, false)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    local fnCancel = function()
        RemoteCallToServer("OnMessageBoxRequest", tInfo.nMessageID, false, tInfo.param1)

        UIHelper.SetVisible(self.WidgetBubbleMsgOnly, false)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end

    local sliderTimelyLikeBar = UIHelper.GetChildByName(self.WidgetBubbleMsgOnly, "SliderTimelyLikeBar")
    self:SetSliderCountDown(false, tInfo.nCancel, tEvent[1], fnCancel, sliderTimelyLikeBar)

    UIHelper.BindUIEvent(script.BtnGet, EventType.OnClick, function()
        fnOK()
    end)

    UIHelper.BindUIEvent(script.BtnLikeRefuse, EventType.OnClick, function()
        fnCancel()
    end)
end

------------------------------就位确认------------------------------
function UITimelyHintTip:UpdateTeamReadyConfirmInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowTeamReadyConfirmTip then
        return
    end
    if tEvent[3] then
        self:HideCurEvent(tEvent[3])
    end

    local tInfo = tEvent[2]

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetBubbleMsgOnly, true)

    local script = UIHelper.GetBindScript(self.WidgetBubbleMsgOnly)

    UIHelper.SetVisible(UIHelper.GetParent(script.WidgetHeadInfo), false)
    UIHelper.SetVisible(script.LayoutName, false)
    UIHelper.SetVisible(script.LabelLikeType, false)
    UIHelper.SetVisible(script.WidgetLabelHint, true)

    UIHelper.SetString(script.LabelLabelHintType, "发起就位确认？")
    UIHelper.SetString(script.LabelLabelHintName, "你已经准备好了吗？")
    UIHelper.SetVisible(script.ImgLabelHintGroup, false)
    UIHelper.SetVisible(script.BtnMore, false)
    UIHelper.LayoutDoLayout(script.LayoutLabelHintName)

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    local fnOK = function()
        RemoteCallToServer("OnVerifyReady", tInfo.dwLeaderID, RAID_READY_CONFIRM_STATE.Ok)
        self:funcCloseTip(self.WidgetBubbleMsgOnly)
    end

    local fnCancel = function()
        RemoteCallToServer("OnVerifyReady", tInfo.dwLeaderID, RAID_READY_CONFIRM_STATE.NotYet)
        self:funcCloseTip(self.WidgetBubbleMsgOnly)
    end

    local sliderTimelyLikeBar = UIHelper.GetChildByName(self.WidgetBubbleMsgOnly, "SliderTimelyLikeBar")
    self:SetSliderCountDown(false, tInfo.nCancel, tEvent[1], fnCancel, sliderTimelyLikeBar)

    UIHelper.BindUIEvent(script.BtnGet, EventType.OnClick, function()
        fnOK()
    end)

    UIHelper.BindUIEvent(script.BtnLikeRefuse, EventType.OnClick, function()
        fnCancel()
    end)
end

--------------------------------房间--------------------------------
function UITimelyHintTip:UpdateRoomInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowRoomTip then
        return
    end
    if tEvent[3] then
        self:HideCurEvent(tEvent[3])
    end

    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Room)
    if TipsHelper.JudgeSmallEventExist(tEvent[1]) then
        if #tbInfos > 0 then
            self:UpdateBubbleMsgIcon(tEvent[1])
        else
            local order = TipsHelper.GetEventOrder(EventType.ShowRoomTip)
            BubbleMsgData.RemoveMsg(self.tSmallBubbleType[order])
            Timer.DelTimer(self, self.nSmallTimer[order])
            self.nSmallTimer[order] = nil
            TipsHelper.ClearSmallEvent(tEvent[1])
        end
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)

    if #tbInfos == 1 then
        local nJoinType, szSrcName, szGlobalID, szRoomID, dwCenterID = table.unpack(tbInfos[1].tbParams)
        local szName = RoomData.GetGlobalName(szSrcName, dwCenterID, true)
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
        UIHelper.SetVisible(self.WidgetLikeHead, true)
        UIHelper.SetVisible(self.ImgInteractTipIcon, true)
        UIHelper.SetSpriteFrame(self.ImgInteractTipIcon, "UIAtlas2_MainCity_BubbleInfomation_icon_10")
        UIHelper.SetVisible(self.WidgetHeadInfo, false)
        UIHelper.SetVisible(self.BtnLike, false)
        UIHelper.SetVisible(self.BtnGet, true)
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
        UIHelper.SetLabel(self.LabelLikeType, "房间邀请")
        UIHelper.SetLabel(self.LabelLikeName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 5))
        CampData.SetUICampImg(self.ImgGroup, nil)
        UIHelper.LayoutDoLayout(self.LayoutName)
    elseif #tbInfos > 1 then
        local szRichText = string.format("<color=#D7F6FF>你有</c><color=#ffe26e>%d个</color><color=#D7F6FF>房间邀请</c>", #tbInfos)
        UIHelper.SetRichText(self.LabelTimeLyInfo, szRichText)
        UIHelper.SetVisible(self.WidgetTimelyMore, true)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        UIHelper.SetVisible(self.WidgetBubbleMsgOnly, false)
        UIHelper.SetVisible(self.ImgInteractTipIcon, false)
        UIHelper.SetSpriteFrame(self.ImgTimelyMoreIcon, "UIAtlas2_MainCity_BubbleInfomation_icon_10")
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    if #tbInfos > 0 then
        self:SetSliderCountDown(#tbInfos > 1, 0, tEvent[1])
    else
        UIHelper.SetVisible(self.WidgetTimelyMore, false)
        UIHelper.SetVisible(self.WidgetBubbleMsgOnly, false)
        UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
        return
    end

    UIHelper.BindUIEvent(self.BtnSmall, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        TipsHelper.SetSmallEvent(tEvent)
        self:SwitchToSmallOrBig(true, tEvent[1])
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Room)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Room)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcConfirm then
                tbInfo.funcConfirm()
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function()
        local tbInfos = TimelyMessagesBtnData.GetBtnInfos(TimelyMessagesType.Room)
        if #tbInfos > 0 then
            local tbInfo = tbInfos[1]
            if tbInfo.funcCancel then
                TimelyMessagesBtnData.RemoveBtnInfo(tbInfo.nType, tbInfo, false)
                tbInfo.funcCancel()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
        TimelyMessagesBtnData.OnClickBtn(TimelyMessagesType.Room)
    end)
end

--------------------------------交互--------------------------------
function UITimelyHintTip:UpdateInteractInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        BubbleMsgData.RemoveMsg("InteractInvite")
        return
    end
    self.tInfo = tEvent
    if self.tInfo[1] ~= EventType.ShowInteractTip then
        return
    end
    if self.tInfo[3] then
        self:HideCurEvent(self.tInfo[3])
    end
    
    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
    
    UIHelper.SetVisible(self.WidgetLikeHead, true)
    UIHelper.SetVisible(self.ImgInteractTipIcon, true)
    UIHelper.SetVisible(self.WidgetHeadInfo, false)
    UIHelper.SetVisible(self.BtnLike, false)
    UIHelper.SetVisible(self.BtnGet, true)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    if self.nInteractTimeID then
        Timer.DelTimer(self, self.nInteractTimeID)
        self.nInteractTimeID = nil
    end

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    -- local szTitle = self.tInfo[2].szTitle or "邀请交互"
    local szTitle = "邀请交互"
    local szIconPath = "UIAtlas2_MainCity_MainCitySkill1_icon_qinggong_main06.png"
    local szInviterName = UIHelper.GBKToUTF8(self.tInfo[2].szInviterName)
    if self.tInfo[2].szType == "FollowInviteTip" then
        if self.tInfo[2].nFollowType == FOLLOW_TYPE.GROUPRIDE then
            szTitle = "邀请同骑"
            UIHelper.SetVisible(self.WidgetLikeHead, false)
            UIHelper.LayoutDoLayout(self.LayoutContent)
        end
        if self.tInfo[2].nFollowType == FOLLOW_TYPE.RIDE then
            szTitle = "邀请同骑"
            szIconPath = "UIAtlas2_MainCity_MainCitySkill1_icon_qinggong_main02.png"
        end
    elseif self.tInfo[2].szType == "PKDuelInviteTip" then
        szTitle = "切磋邀请"
        szIconPath = "UIAtlas2_MainCity_BubbleInfomation_icon_12.png"
    end

    UIHelper.SetSpriteFrame(self.ImgInteractTipIcon, szIconPath)
    UIHelper.SetLabel(self.LabelLikeType, szTitle)
    UIHelper.SetLabel(self.LabelLikeName, szInviterName, 5)
    CampData.SetUICampImg(self.ImgGroup, nil)
    UIHelper.LayoutDoLayout(self.LayoutName)
    -- UIHelper.SetProgressBarPercent(self.SliderTimelyLikeBar, 100)

    local order = TipsHelper.GetEventOrder(self.tInfo[1])
    local nCurTime = GetCurrentTime()
    if self.tInfo[2].nAutoConfirmTime then
        self.tInfo.nRemain = self.tInfo[2].nAutoConfirmTime
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetAutoConfirmCountDown(szTitle, self.tInfo.nRemain, self.tInfo[1], self.tInfo[2].fnConfirmAction)
    elseif self.tInfo.nRemain and self.tInfo.nRemain < nShowTime then
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(false, self.tInfo.nRemain, self.tInfo[1], self.tInfo[2].fnCancelAction)
    elseif self.tInfo.nEndTime and self.tInfo.nEndTime > nCurTime then
        self.tInfo.nRemain = self.tInfo.nEndTime - nCurTime
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(false, self.tInfo.nRemain, self.tInfo[1], self.tInfo[2].fnCancelAction)
    else
        self.nSmallRemain[order] = nShowTime
        self:SetSliderCountDown(false, nShowTime, self.tInfo[1], self.tInfo[2].fnCancelAction)
    end

    if self.tInfo[2].fnAutoClose then
        self.nAutoCloseTimerID = Timer.AddCycle(self, 0.1, function ()
            if self.tInfo[2].fnAutoClose() then
                self.tInfo[2].fnCancelAction()
                self:funcCloseTip(self.WidgetTimelyLikeOnly)
                Timer.DelTimer(self, self.nAutoCloseTimerID)
                self.nAutoCloseTimerID = nil
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        self.tInfo[2].fnConfirmAction()
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function ()
        self.tInfo[2].fnCancelAction()
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
    end)
end

--------------------------------交易--------------------------------
function UITimelyHintTip:UpdateTradeInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        BubbleMsgData.RemoveMsg("TradeInviteTip")
        return
    end
    self.tInfo = tEvent
    if self.tInfo[1] ~= EventType.ShowTradeTip then
        return
    end
    if self.tInfo[3] then
        self:HideCurEvent(self.tInfo[3])
    end
    
    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetTimelyLikeOnly, true)
    
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetLikeHead, true)
    UIHelper.SetVisible(self.ImgInteractTipIcon, true)
    UIHelper.SetVisible(self.WidgetHeadInfo, false)
    UIHelper.SetVisible(self.BtnLike, false)
    UIHelper.SetVisible(self.BtnGet, true)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    local szTitle = "交易邀请"
    local szIconPath = "UIAtlas2_MainCity_BubbleInfomation_icon_09.png"
    local szInviterName = UIHelper.GBKToUTF8(self.tInfo[2].szInviterName)

    UIHelper.SetSpriteFrame(self.ImgInteractTipIcon, szIconPath)
    UIHelper.SetLabel(self.LabelLikeType, szTitle)
    UIHelper.SetLabel(self.LabelLikeName, szInviterName, 5)
    CampData.SetUICampImg(self.ImgGroup, nil)
    UIHelper.LayoutDoLayout(self.LayoutName)
    UIHelper.SetProgressBarPercent(self.SliderTimelyLikeBar, 100)

    -- local order = TipsHelper.GetEventOrder(self.tInfo[1])
    local order = TipsHelper.GetEventOrder(self.tInfo[1])
    local nCurTime = GetCurrentTime()
    if self.tInfo.nRemain and self.tInfo.nRemain < TradeData.GetTimelyHintMaxExistTime() then
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(false, self.tInfo.nRemain, self.tInfo[1], self.tInfo[2].fnCancelAction)
    elseif self.tInfo.nEndTime and self.tInfo.nEndTime > nCurTime then
        self.tInfo.nRemain = self.tInfo.nEndTime - nCurTime
        self.nSmallRemain[order] = self.tInfo.nRemain
        self:SetSliderCountDown(false, self.tInfo.nRemain, self.tInfo[1], self.tInfo[2].fnCancelAction)
    else
        self.nSmallRemain[order] = TradeData.GetTimelyHintMaxExistTime()
        self:SetSliderCountDown(false, TradeData.GetTimelyHintMaxExistTime(), self.tInfo[1], self.tInfo[2].fnCancelAction)
    end

    if self.tInfo[2].fnAutoClose then
        self.nAutoCloseTimerID = Timer.AddCycle(self, 0.1, function ()
            if self.tInfo[2].fnAutoClose() then
                self.tInfo[2].fnCancelAction()
                self:funcCloseTip(self.WidgetTimelyLikeOnly)
                Timer.DelTimer(self, self.nAutoCloseTimerID)
                self.nAutoCloseTimerID = nil
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        local me = GetClientPlayer()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return false
        end
        me.TradingInviteRespond(true)
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function ()
        self.tInfo[2].fnCancelAction()
        self:funcCloseTip(self.WidgetTimelyLikeOnly)
    end)

    UIHelper.BindUIEvent(self.BtnTimelyOnly, EventType.OnClick, function()
    end)
end

--------------------------------录制Optick--------------------------------
function UITimelyHintTip:UpdateOptickRecordTipInfo()
    local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
    if not tEvent then
        return
    end
    if tEvent[1] ~= EventType.ShowOptickRecordTip then
        return
    end

    if tEvent[3] then
        self:HideCurEvent(tEvent[3])
    end

    self:HideAllWidgets()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetHintSettingRecordTime, true)
    UIHelper.SetVisible(self.BtnGet, true)

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    if self.nAutoCloseTimerID then
        Timer.DelTimer(self, self.nAutoCloseTimerID)
        self.nAutoCloseTimerID = nil
    end

    local script = UIHelper.GetBindScript(self.WidgetHintSettingRecordTime)
    self.nTimer = Timer.AddCycle(self, 0.05, function()
        UIHelper.SetActiveAndCache(self, script.WidgetRecording, GetOptickCaptureState() == OptickCaptureState.Started)
        UIHelper.SetActiveAndCache(self, script.WidgetSaving, GetOptickCaptureState() == OptickCaptureState.Stopped)
    end)

    if tEvent[2].fnAutoClose then
        self.nAutoCloseTimerID = Timer.AddCycle(self, 0.1, function()
            if tEvent[2].fnAutoClose() then
                GameSettingData.UploadOptick()
                self:funcCloseTip(self.WidgetHintSettingRecordTime)
                Timer.DelTimer(self, self.nAutoCloseTimerID)
                self.nAutoCloseTimerID = nil
            end
        end)
    end

    UIHelper.BindUIEvent(script.BtnStop, EventType.OnClick, function()
        OptickStopCapture()
    end)
end


function UITimelyHintTip:HideAllWidgets()
    UIHelper.SetVisible(self.WidgetBubbleMsgOnly, false)
    UIHelper.SetVisible(self.WidgetTimelyMore, false)
    UIHelper.SetVisible(self.WidgetTimelyLikeOnly, false)
    UIHelper.SetVisible(self.WidgetHintSettingRecordTime, false)
end

return UITimelyHintTip