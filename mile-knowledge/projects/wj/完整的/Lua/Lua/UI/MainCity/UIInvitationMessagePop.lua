-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInvitationMessagePop
-- Date: 2023-03-24 09:24:58
-- Desc: PanelInvitationMessagePop
-- ---------------------------------------------------------------------------------

local UIInvitationMessagePop = class("UIInvitationMessagePop")

function UIInvitationMessagePop:OnEnter(nType)
    self.nType = nType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfos = TimelyMessagesBtnData.GetBtnInfos(self.nType)
    self:UpdateInfo()
end

function UIInvitationMessagePop:OnExit()
    self.bInit = false
    if self.nLikePopTimer then
        Timer.DelTimer(self, self.nLikePopTimer)
    end

    if self.nLike and self.nLike > 0 and self.tShow and self.tLikes then
        for i = self.nLike, 1, -1 do
            if self.tShow[i] ~= 0 then
                table.remove(self.tLikes, i)
            end
        end
    end
end

function UIInvitationMessagePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.bLikeMsg == true then
            Event.Dispatch(EventType.OnCloseLikeTip, false)
        end
        UIMgr.Close(self)
    end)
end

function UIInvitationMessagePop:RegEvent()
    Event.Reg(self, EventType.OnUpdateMessageBtnInfo, function (nType)
        if self.nType ~= nType then
            return
        end

        self.tbInfos = TimelyMessagesBtnData.GetBtnInfos(self.nType)
        if table_is_empty(self.tbInfos) then
            if self.nType == TimelyMessagesType.Team then
                BubbleMsgData.RemoveMsg("TeamInvite")
            end
            if self.nType == TimelyMessagesType.Room then
                BubbleMsgData.RemoveMsg("RoomInvite")
            end
            UIMgr.Close(self)
            return
        end

        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnUpdateLikeMessage, function (bDelete, tLike)
        self:UpdateLikeType(bDelete, tLike)
        self:JudgeNeedClose()
    end)
end

function UIInvitationMessagePop:UpdateInfo()
    UIHelper.HideAllChildren(self.ScrollViewInvitationList)

    local szTitle = "消息列表"
    self.tbCell = self.tbCell or {}
    for i, tbInfo in ipairs(self.tbInfos) do
        self.tbCell[i] = self.tbCell[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetAnchorInvitationList, self.ScrollViewInvitationList)
        UIHelper.SetVisible(self.tbCell[i]._rootNode, true)
        self.tbCell[i]:OnEnter(tbInfo, self.nType)
        szTitle = tbInfo.szTitle
    end

    UIHelper.SetString(self.LabelTitle, szTitle)

    UIHelper.ScrollViewDoLayout(self.ScrollViewInvitationList)
    UIHelper.ScrollToTop(self.ScrollViewInvitationList, 0)
end

function UIInvitationMessagePop:SetInvitationInfo(tbInfos)
    self.nType = TimelyMessagesType.Friend
    self.tbInfos = tbInfos
    if table_is_empty(self.tbInfos) then
        UIMgr.Close(self)
        return
    end

    self:UpdateInfo()
end

-- like more
--[[ self.tShow[i] = {
    0 未处理
    1 已点赞
    2 已删除
} ]]

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

local szCountDown = "(倒计时:%s秒)"

function UIInvitationMessagePop:UpdateLikeMore(nType, nCountDown, tLikes, funcFinishCallback)
    self.bLikeMsg = true
    self.tbCell = nil

    self.tLikes = tLikes
    self.tShow = {}
    self.nLike = #self.tLikes
    self.nLikeType = nType
    self.funcFinishCallback = funcFinishCallback
    for i = 1, self.nLike do
        self.tShow[i] = 0
    end
    local szTitle = LIKE_TYPE_TO_TITLE[nType] .. "点赞"
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetVisible(self.LabelTime, true)
    UIHelper.SetString(self.LabelTime, string.format(szCountDown, nCountDown))
    self:UpdateLikeData()
    self:SetCountDown(nCountDown)
end

function UIInvitationMessagePop:SetCountDown(nCountDown)
    if not self.nLikePopTimer then
        self.nLikePopTimer = Timer.AddCountDown(self, nCountDown, function(nRemain)
            UIHelper.SetString(self.LabelTime, string.format(szCountDown, nRemain))
        end, function()
            UIMgr.Close(self)
        end
    )
    end
end

function UIInvitationMessagePop:UpdateLikeType(bDelete, tLike)
    for i = 1, self.nLike do
        if self.tLikes[i] == tLike then
            if bDelete == true then
                self.tShow[i] = 2
                self:UpdateLikeData()
            else
                self.tShow[i] = 1
                -- RemoteCallToServer("On_FriendPraise_AddRequest", g_pClientPlayer.dwID, tLike.dwID, self.nLikeType)
            end
            return
        end
    end
end

function UIInvitationMessagePop:UpdateLikeData()
    UIHelper.RemoveAllChildren(self.ScrollViewInvitationList)
    for i = 1, self.nLike do
        if self.tShow[i] == 1 then
            local scriptCell =  UIHelper.AddPrefab(PREFAB_ID.WidgetInvitationLikeCell, self.ScrollViewInvitationList)
            scriptCell:UpdateInfo(self.tLikes[i], true, self.nLikeType)
        elseif self.tShow[i] == 0 then
            local scriptCell =  UIHelper.AddPrefab(PREFAB_ID.WidgetInvitationLikeCell, self.ScrollViewInvitationList)
            scriptCell:UpdateInfo(self.tLikes[i], false, self.nLikeType)
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewInvitationList)
    UIHelper.ScrollToTop(self.ScrollViewInvitationList, 0)
end

function UIInvitationMessagePop:JudgeNeedClose()
    local bNeedClose = true
    for i = 1, self.nLike do
        if self.tShow[i] == 0 then
            bNeedClose = false
        end
    end
    if bNeedClose == true then
        if self.funcFinishCallback then
            self.funcFinishCallback()
        end
        Event.Dispatch(EventType.OnCloseLikeTip, true)
        UIMgr.Close(self)
    end
end

return UIInvitationMessagePop