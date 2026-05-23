-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaFinishBattleDataCell
-- Date: 2022-12-15 10:28:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaFinishBattleDataCell = class("UIArenaFinishBattleDataCell")


function UIArenaFinishBattleDataCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaFinishBattleDataCell:OnExit()
    self.bInit = false
end

function UIArenaFinishBattleDataCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPriaise, EventType.OnClick, function()
        if self.bPraised then
            return
        end

        ArenaData.ReqPraise(self.tbInfo.nRoleID)

        self.bPraised = true
        UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.PraisedIconPath)
        Event.Dispatch(EventType.OnUpdateArenaFinishDataFriendPraiseList)
    end)

    UIHelper.BindUIEvent(self.BtnShield, EventType.OnClick, function()
        if self.bShield then
            return
        end

        local nSelfPlayerID = PlayerData.GetPlayerID()
        if not nSelfPlayerID then return end
        local szRoleName = UIHelper.GBKToUTF8(self.tbInfo.szPlayerName)

        local szMessage = FormatString(g_tStrings.STR_JJC_BLACK_TIP, szRoleName)
        local fnConfirm = function()
            RemoteCallToServer("On_FriendPraise_AddBlacklist", self.tbInfo.nRoleID, 1)
            UIHelper.SetNodeGray(self.BtnShield, true, true)
        end
        UIHelper.ShowConfirm(szMessage, fnConfirm)
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        RemoteCallToServer("On_XinYu_Jubao", self.tbInfo.nRoleID, self.tbInfo.szPlayerName)
        Event.Dispatch(EventType.OnArenaFinishDataReport, self.tbInfo.nRoleID)
    end)
end

function UIArenaFinishBattleDataCell:RegEvent()
    Event.Reg(self, EventType.OnUpdateArenaFinishDataFriendPraiseList, function (szEvent)
        self:UpdateBtnState()
    end)

    Event.Reg(self, "ON_ARENA_ADD_PLAYER_TO_BLACK_LIST", function (dwPlayerID, nResultCode)
        if dwPlayerID == self.tbInfo.nRoleID and nResultCode == ARENA_RESULT_CODE.ADD_PLAYER_TO_BLACK_LIST_SUCCESS then
            self.bShield = true
            UIHelper.SetNodeGray(self.BtnShield, true, true)
        end
    end)

    Event.Reg(self, EventType.OnArenaFinishDataReportSwitch, function(bReportFlag)
        self.bReportFlag = bReportFlag
        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnArenaFinishDataReport, function(nRoleID)
        if self.tbInfo and self.tbInfo.nRoleID and nRoleID == self.tbInfo.nRoleID then
            UIHelper.SetButtonState(self.BtnReport, BTN_STATE.Disable, "已举报过该玩家")
        end
    end)
end

function UIArenaFinishBattleDataCell:UpdateInfo()
    UIHelper.SetString(self.LabelPraiseNum, 0)
    UIHelper.SetString(self.LabelHarmNum, self.tbInfo.nDamge or "-")
    UIHelper.SetString(self.LabelTreatNum, self.tbInfo.nHealth or "-")
    local szName = UIHelper.GBKToUTF8(self.tbInfo.szPlayerName)
    UIHelper.SetString(self.LabelPlayerName, szName, 6)

    -- UIHelper.SetSpriteFrame(self.ImgPraise, "")

    local bSelf = self.tbInfo.nRoleID == PlayerData.GetPlayerID()

    -- UIHelper.SetVisible(self.ImgSelf, bSelf)
    UIHelper.SetVisible(self.ImgMvp, self.tbInfo.bMVP)
    -- UIHelper.SetVisible(self.ImgWinCount, self.tbInfo.bShowWinCount)

    if bSelf then
        UIHelper.SetTextColor(self.LabelPlayerName, ArenaFinishDataColor.SelfColor)
        UIHelper.SetTextColor(self.LabelTreatNum, ArenaFinishDataColor.SelfColor)
        UIHelper.SetTextColor(self.LabelHarmNum, ArenaFinishDataColor.SelfColor)
    else
        UIHelper.SetTextColor(self.LabelPlayerName, ArenaFinishDataColor.OtherColor)
        UIHelper.SetTextColor(self.LabelTreatNum, ArenaFinishDataColor.OtherColor)
        UIHelper.SetTextColor(self.LabelHarmNum, ArenaFinishDataColor.OtherColor)
    end

    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, self.tbInfo.nRoleID)
    Timer.AddFrame(self, 1, function ()
        self.scriptHead:SetHeadInfo(0, 0, nil, self.tbInfo.nForceID)
        self.scriptHead:SetHeadWithMountKungfuID(self.tbInfo.dwMountKungfuID)
        self.scriptHead:SetShowSelf(bSelf)
        self.scriptHead:SetShowPvPConstantlyWin(self.tbInfo.bShowWinCount)
    end)
    self.scriptHead:SetClickCallback(function ()
        if self.WidgetPersonalCard then
            UIHelper.RemoveAllChildren(self.WidgetPersonalCard)
            UIHelper.SetVisible(self.WidgetPersonalCard, true)
            local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, self.tbInfo.szGlobalRoleID)
			tipsScriptView:SetPlayerId(self.tbInfo.nRoleID)
            if tipsScriptView then
                tipsScriptView:OnEnter(self.tbInfo.szGlobalRoleID)
                local tInfo = {
                    szName = szName,
                    dwPlayerID = self.tbInfo.nRoleID,
                    dwMiniAvatarID = 0,
                    nRoleType = nil,
                    dwForceID = self.tbInfo.nForceID,
                }
                tipsScriptView:SetPersonalInfo(tInfo)
            end
        end
    end)

    self:UpdateBtnState()
end

function UIArenaFinishBattleDataCell:UpdateBtnState()
    local tbArenaInfo = ArenaData.tbArenaBattleData
    local bShowPraise = false
    local bShowShield = false
    if tbArenaInfo.tbPraiseList and tbArenaInfo.tbPraiseList[self.tbInfo.nRoleID] then
        bShowPraise = true
    end
    if tbArenaInfo.tbBlackList and tbArenaInfo.tbBlackList[self.tbInfo.nRoleID] then
        bShowShield = true
    end

    local nPraiseCount = ArenaData.GetPraiseCount(self.tbInfo.nRoleID)
    UIHelper.SetVisible(self.BtnPriaise, (bShowPraise or nPraiseCount > 0) and not self.bReportFlag)
    UIHelper.SetVisible(self.BtnReport, (bShowPraise or bShowShield) and self.bReportFlag)
    UIHelper.SetVisible(self.BtnShield, bShowShield and not self.bReportFlag)

    self.bPraised = ArenaData.IsPraised(self.tbInfo.nRoleID) or not ArenaData.CanAddPraise(self.tbInfo.nRoleID)
    self.bMutualPraise = ArenaData.IsMutualPraise(self.tbInfo.nRoleID)

    if self.bPraised then
        UIHelper.SetTouchEnabled(self.BtnPriaise, false)
    end

    if self.bMutualPraise then
        UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.MutualPraisedIconPath)
    elseif ArenaData.IsAddPraise(self.tbInfo.nRoleID) then
        if self.bPraised then
            UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.PraisedIconPath)
        else
            UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.CanPraiseIconPath)
        end
    else
        UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.CanPraiseIconPath)
    end

    if nPraiseCount > 0 then
        UIHelper.SetVisible(self.LabelPraiseNum, true)
        UIHelper.SetString(self.LabelPraiseNum, nPraiseCount)
    else
        UIHelper.SetVisible(self.LabelPraiseNum, false)
    end
end


function UIArenaFinishBattleDataCell:SetWidgetPersonalCard(WidgetPersonalCard)
    self.WidgetPersonalCard = WidgetPersonalCard
end

return UIArenaFinishBattleDataCell