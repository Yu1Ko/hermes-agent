-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHintBubbleMsgOnly
-- Date: 2024-04-25 15:34:00
-- Desc: ?
-- ---------------------------------------------------------------------------------
--- @class UIWidgetHintBubbleMsgOnly
local UIWidgetHintBubbleMsgOnly = class("UIWidgetHintBubbleMsgOnly")

function UIWidgetHintBubbleMsgOnly:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fnConfirmAction = nil
    self.fnCancelAction = nil
end

function UIWidgetHintBubbleMsgOnly:OnExit()
    self.bInit = false
    self.tCurMsg = nil
    self:UnRegEvent()
end

function UIWidgetHintBubbleMsgOnly:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function()
        if self.tCurMsg and self.tCurMsg.fnConfirmAction then
            self.tCurMsg.fnConfirmAction()
        end
        self.tCurMsg = nil
        UIHelper.SetVisible(self._rootNode, false)
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnLikeRefuse, EventType.OnClick, function()
        if self.tCurMsg and self.tCurMsg.fnCancelAction then
            self.tCurMsg.fnCancelAction()
        end
        UIHelper.SetVisible(self._rootNode, false)
        self.tCurMsg = nil
        TipsHelper.ClearCurEvent(TipsHelper.Def.Queue3)
        TipsHelper.NextTip(TipsHelper.Def.Queue3)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        if self.tCurMsg and self.tCurMsg.fnCancelAction then
            self.tCurMsg.fnMoreAction()
        end
    end)
end

function UIWidgetHintBubbleMsgOnly:RegEvent()
    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
        if not self.bFinishApply and self.tCurMsg and self.tCurMsg.szGlobalID == szGlobalID then
            self:UpdateFellowshipInfo(szGlobalID)
        end
    end)

    Event.Reg(self, "PEEK_OTHER_PLAYER", function (nResult, dwID)
        if nResult == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
            if not self.bFinishApply and self.tCurMsg and self.tCurMsg.nPlayerID == dwID then
                if self.bUpdatePlayerInfoWithMore then
                    self.bUpdatePlayerInfoWithMore = nil
                    self:UpdatePlayerInfoWithMore(dwID)
                else
                    self:UpdatePlayerInfo(dwID)
                end
            end
        end
    end)

    Event.Reg(self, EventType.CloseTimelyMessageBubble, function()
        BubbleMsgData.PushMsg(self.tCurMsg)
    end)


end

function UIWidgetHintBubbleMsgOnly:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHintBubbleMsgOnly:UpdateInfo(tMsg)
    if not tMsg and not self.tCurMsg then
        UIHelper.SetVisible(self._rootNode, false)
        return
    elseif self.tCurMsg and tMsg.szType ~= self.tCurMsg.szType then
        BubbleMsgData.PushMsg(self.tCurMsg)
    end
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetVisible(self.WidgetHeadInfo, false)
    UIHelper.SetVisible(self.ImgGroup, false)
    UIHelper.SetVisible(self.ImgInteractTipIcon, true)

    self.tCurMsg = tMsg
    self.bFinishApply = false   -- 防止串事件导致重复刷新

    local nPlayerID = tMsg.nPlayerID
    local szGlobalID = tMsg.szGlobalID
    local szPlayerName = tMsg.szPlayerName or ""
    local szTitle = tMsg.szShortTitle or ""

    if szTitle == "邀请入帮" then
        UIHelper.SetString(self.LabelLabelHintType, szTitle .. tMsg.szContent, 12)
        UIHelper.SetVisible(self.LayoutName, false)
        UIHelper.SetVisible(self.LabelLikeType, false)
        UIHelper.SetVisible(self.WidgetHeadInfo, false)
        UIHelper.SetVisible(self.WidgetLabelHint, true)
        self:UpdatePlayerInfoWithMore(nPlayerID)
        Timer.AddFrame(self, 3, function()
            self:UpdatePlayerInfoWithMore(nPlayerID)
        end)
    elseif szTitle == "召唤请求" then
        UIHelper.SetString(self.LabelLabelHintType, tMsg.szContent, 12)
        UIHelper.SetVisible(self.LayoutName, false)
        UIHelper.SetVisible(self.LabelLikeType, false)
        UIHelper.SetVisible(self.WidgetHeadInfo, false)
        UIHelper.SetVisible(self.WidgetLabelHint, true)
        self:UpdatePlayerInfoWithMore(nPlayerID)
        Timer.AddFrame(self, 3, function()
            self:UpdatePlayerInfoWithMore(nPlayerID)
        end)
    else
        UIHelper.SetVisible(self.ImgGroup, false)
        UIHelper.SetVisible(self.LabelLikeType, true)
        UIHelper.SetVisible(self.WidgetLabelHint, false)
        UIHelper.SetVisible(self.LayoutName, not string.is_nil(szPlayerName))
        UIHelper.SetLabel(self.LabelLikeType, szTitle)
        UIHelper.SetString(self.LabelLikeName, szPlayerName, 6)
        UIHelper.SetSpriteFrame(self.ImgInteractTipIcon, tMsg.szIcon)
        UIHelper.LayoutDoLayout(self.LayoutName)

        if szGlobalID then
            self:UpdateFellowshipInfo(szGlobalID)
        elseif nPlayerID then
            self:UpdatePlayerInfo(nPlayerID)
        end
    end

    if tMsg.fnConfirmAction then
        self.fnConfirmAction = tMsg.fnConfirmAction
    end

    if tMsg.fnCancelAction then
        self.fnCancelAction = tMsg.fnCancelAction
    end
    UIHelper.SetVisible(self.BtnMore, tMsg.fnMoreAction ~= nil)
end

function UIWidgetHintBubbleMsgOnly:UpdateFellowshipInfo(szGlobalID)
    -- 兼容好友系统的PlayerEntryInfo数据，确保FELLOWSHIP_ROLE_ENTRY_UPDATE事件有效
    local player = GetPlayerByGlobalID(szGlobalID)
    if not player then
        player = FellowshipData.GetRoleEntryInfo(szGlobalID)
        if not player or table.is_empty(player) then
            LOG.INFO("============UpdateFellowshipInfo  Player Is Not Found !==========")
            return
        end
    end
    local scriptHeadInfo = UIHelper.GetBindScript(self.WidgetHeadInfo)
    local szCampIcon = CampData.GetCampImgPath(player.nCamp, false, true)
    local dwPlayerID = player.dwID or player.dwPlayerID
    local dwForceID = player.dwForceID or player.nForceID

    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetVisible(self.WidgetHeadInfo, true)
    UIHelper.SetVisible(self.LayoutName, true)
    UIHelper.SetVisible(self.ImgGroup, true)

    LOG.INFO("============UpdateFellowshipInfo  LayoutName:%s LabelLikeName:%s  PlayerName: %s==========", tostring(UIHelper.GetVisible(self.LayoutName)),
        tostring(UIHelper.GetVisible(self.LabelLikeName)), tostring(UIHelper.GBKToUTF8(player.szName)))
    scriptHeadInfo:SetHeadInfo(dwPlayerID, player.dwMiniAvatarID, player.nRoleType, dwForceID)
    UIHelper.SetString(self.LabelLikeName, UIHelper.GBKToUTF8(player.szName), 6)
    UIHelper.SetSpriteFrame(self.ImgGroup, szCampIcon)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutName, true, true)
    self.bFinishApply = true
end

function UIWidgetHintBubbleMsgOnly:UpdatePlayerInfo(nPlayerID)
    local player = GetPlayer(nPlayerID)
    if not player then
        self.bUpdatePlayerInfoWithMore = nil
        PeekOtherPlayer(nPlayerID)
        return
    end
    local scriptHeadInfo = UIHelper.GetBindScript(self.WidgetHeadInfo)
    local szCampIcon = CampData.GetCampImgPath(player.nCamp, false, true)

    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetVisible(self.WidgetHeadInfo, true)
    UIHelper.SetVisible(self.ImgGroup, true)
    scriptHeadInfo:SetPlayerID(nPlayerID)

    local szPlayerName = UIHelper.GBKToUTF8(player.szName)
    UIHelper.SetString(self.LabelLikeName, szPlayerName, 6)
    UIHelper.SetSpriteFrame(self.ImgGroup, szCampIcon)
    UIHelper.SetVisible(self.LayoutName, not string.is_nil(szPlayerName))
    UIHelper.LayoutDoLayout(self.LayoutName)
    self.bFinishApply = true
end

function UIWidgetHintBubbleMsgOnly:UpdatePlayerInfoWithMore(nPlayerID)
    local player = GetPlayer(nPlayerID)
    if not player then
        self.bUpdatePlayerInfoWithMore = true
        PeekOtherPlayer(nPlayerID)
        return
    end

    UIHelper.SetVisible(self.LayoutName, false)
    UIHelper.SetVisible(self.LabelLikeType, false)
    UIHelper.SetVisible(self.WidgetHeadInfo, false)
    UIHelper.SetVisible(self.ImgInteractTipIcon, false)
    UIHelper.SetVisible(self.WidgetLabelHint, true)

    local szCampIcon = CampData.GetCampImgPath(player.nCamp, false, true)
    local szPlayerName = UIHelper.GBKToUTF8(player.szName)
    UIHelper.SetString(self.LabelLabelHintName, szPlayerName, 6)
    UIHelper.SetSpriteFrame(self.ImgLabelHintGroup, szCampIcon)
    UIHelper.SetVisible(self.LayoutLabelHintName, not string.is_nil(szPlayerName))
    UIHelper.LayoutDoLayout(self.LayoutLabelHintName)
    self.bFinishApply = true
end


return UIWidgetHintBubbleMsgOnly