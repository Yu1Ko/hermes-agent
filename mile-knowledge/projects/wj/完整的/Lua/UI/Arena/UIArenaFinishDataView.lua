-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaFinishDataView
-- Date: 2022-12-14 21:23:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaFinishDataView = class("UIArenaFinishDataView")

local LEAVE_LEFT_TIME = 5

function UIArenaFinishDataView:OnEnter(tbData, funcClickBackMvpCallback)
    self.tbData = tbData
    self.funcClickBackMvpCallback = funcClickBackMvpCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bReportFlag = false
    self:UpdateInfo()

    UIMgr.HideView(VIEW_ID.PanelRevive)
    UIMgr.HideLayer(UILayer.Main)
end

function UIArenaFinishDataView:OnExit()
    self.bInit = false
    UIMgr.ShowLayer(UILayer.Main)
    UIMgr.ShowView(VIEW_ID.PanelRevive)
end

function UIArenaFinishDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        ArenaData.LogOutArena()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBack2, EventType.OnClick, function(btn)
        if self.funcClickBackMvpCallback then
            self.funcClickBackMvpCallback()
        end
    end)
    UIHelper.SetVisible(self.BtnBack2, not not self.funcClickBackMvpCallback)
    UIHelper.LayoutDoLayout(self.WidgetRightDown)

    UIHelper.BindUIEvent(self.TogAll, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogData, false)
    end)

    UIHelper.BindUIEvent(self.TogData, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogAll, false)
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        self.bReportFlag = not self.bReportFlag

        local tbArenaInfo = ArenaData.tbArenaBattleData
        local bShowPraise = tbArenaInfo and tbArenaInfo.tbPraiseList and table.get_len(tbArenaInfo.tbPraiseList) > 0
        local bShowBlack =  tbArenaInfo and tbArenaInfo.tbBlackList and table.get_len(tbArenaInfo.tbBlackList) > 0
        if self.bReportFlag then
            if bShowPraise then
                UIHelper.SetString(self.LabelReport, "队友点赞")
            elseif bShowBlack then
                UIHelper.SetString(self.LabelReport, "队友屏蔽")
            end
            UIHelper.SetSpriteFrame(self.ImgReport, "UIAtlas2_Public_PublicButton_PublicButton1_btn_Recall")
        else
            UIHelper.SetString(self.LabelReport, "信誉举报")
            UIHelper.SetSpriteFrame(self.ImgReport, "UIAtlas2_Public_PublicButton_PublicButton1_btn_warning")
        end
        Event.Dispatch(EventType.OnArenaFinishDataReportSwitch, self.bReportFlag)
    end)

    UIHelper.BindUIEvent(self.BtnPraiseAll, EventType.OnClick, function()
        ArenaData.ReqPraiseAll()
    end)
end

function UIArenaFinishDataView:RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetPersonalCardLeft, false)
        UIHelper.SetVisible(self.WidgetPersonalCardRight, false)
    end)

    self.scriptShare = self.scriptShare or UIHelper.GetBindScript(self.WidgetShare)
    self.scriptShare:OnEnter(nil, true)
end

function UIArenaFinishDataView:UpdateInfo()
    self.tbFinishData = self:ParseData()

    self:UpdateFinishDataInfo()
    self:UpdateBattleDataInfo()

    local bWin = self.tbFinishData.bWin
    local bInValid = self.tbFinishData.bNotValid -- 平局

    UIHelper.SetVisible(self.LabelTeam1, not bInValid)
    UIHelper.SetVisible(self.LabelTeam2, not bInValid)
    UIHelper.SetVisible(self.WidgetInValid, bInValid)
    UIHelper.SetVisible(self.WidgetVictory, not bInValid and bWin)
    UIHelper.SetVisible(self.WidgetDefeat, not bInValid and not bWin)
    if not bInValid then
        UIHelper.SetString(self.LabelTeam1, UIHelper.GBKToUTF8(self.tbFinishData.szTeamName1))
        UIHelper.SetString(self.LabelTeam2, UIHelper.GBKToUTF8(self.tbFinishData.szTeamName2))
    end

    local tbArenaInfo = ArenaData.tbArenaBattleData
    local bShowPraise = tbArenaInfo and tbArenaInfo.tbPraiseList and table.get_len(tbArenaInfo.tbPraiseList) > 0
    local bShowBlack =  tbArenaInfo and tbArenaInfo.tbBlackList and table.get_len(tbArenaInfo.tbBlackList) > 0
    UIHelper.SetVisible(self.BtnReport, bShowBlack)
    UIHelper.SetVisible(self.BtnPraiseAll, bShowPraise)

    if ArenaData.nBattleGameTime and ArenaData.nBattleGameTime > 0 then
        local szTime = UIHelper.GetDeltaTimeText(ArenaData.nBattleGameTime, false)
        UIHelper.SetString(self.LabelBattleTotalTime, string.format("%s%s", g_tStrings.STR_BATTLEFIELD_TIME_USED, szTime))
    else
        UIHelper.SetString(self.LabelBattleTotalTime, string.format("%s0秒", g_tStrings.STR_BATTLEFIELD_TIME_USED, szTime))
    end

    Timer.DelAllTimer(self)
    if self.tbFinishData.nBanishTime > 0 then
        self:UpdateBanishTimeInfo()
        Timer.AddCycle(self, 0.5, function()
            self:UpdateBanishTimeInfo()
        end)
    end

    if self.tbData.bWin then
        self.nStartTime = self.nStartTime or GetTickCount()
        UIHelper.SetButtonState(self.BtnLeave, BTN_STATE.Disable, function ()
            TipsHelper.ShowNormalTip(string.format("剩余倒计时:%d秒", LEAVE_LEFT_TIME - math.floor((GetTickCount() - self.nStartTime) / 1000.0)))
        end)
        Timer.AddCycle(self, 0.5, function ()
            UIHelper.SetString(self.LabelLeave, string.format("离开名剑(%d秒)", LEAVE_LEFT_TIME - math.floor((GetTickCount() - self.nStartTime) / 1000.0)))
            if GetTickCount() - self.nStartTime >= LEAVE_LEFT_TIME * 1000 then
                UIHelper.SetButtonState(self.BtnLeave, BTN_STATE.Normal)
                UIHelper.SetString(self.LabelLeave, "离开名剑大会")
            end
        end)
    end
end

function UIArenaFinishDataView:UpdateFinishDataInfo()
    local scriptFinishDataPage = UIHelper.GetBindScript(self.WidgetAllList)
    scriptFinishDataPage:OnEnter(self.tbFinishData)
end

function UIArenaFinishDataView:UpdateBattleDataInfo()
    local scriptBattleDataPage = UIHelper.GetBindScript(self.WidgetDataList)
    scriptBattleDataPage:OnEnter(self.tbFinishData)
end

function UIArenaFinishDataView:UpdateBanishTimeInfo()
    local nCurTime = GetTickCount()
    local nTime = math.floor((self.tbFinishData.nBanishTime - nCurTime) / 1000)
    nTime = math.max(nTime, 0)
    UIHelper.SetRichText(self.RichTextTime, string.format("将在<color=#F0DC82>%d</c>秒后传出名剑大会", nTime))
end

function UIArenaFinishDataView:ParseData()
    local player = PlayerData.GetClientPlayer()
    local nSelfSide = player.nBattleFieldSide
    local nEnemySide = nSelfSide == 0 and 1 or 0

    local tbData = {
        bWin = self.tbData.bWin,
        szTeamName1 = "",
        szTeamName2 = "",
        nSelfSide = nSelfSide,
        nEnemySide = nEnemySide,
        nBanishTime = self.tbData.nBanishTime,
        tbPlayerInfo = {},
        bNotValid = not self.tbData.bValidCount
    }

	local tForceIDList = {}
    for k, v in pairs(self.tbData.tbArenaStat) do
        if v.nGroupID == 0 then
            tbData.szTeamName1 = v.szCorpsName
        elseif v.nGroupID == 1 then
            tbData.szTeamName2 = v.szCorpsName
        end
        tbData.tbPlayerInfo[v.nGroupID] = tbData.tbPlayerInfo[v.nGroupID] or {}
        tForceIDList[v.nGroupID] = tForceIDList[v.nGroupID] or {}

        if v.bWin and v.bValidCount then
            v.dwMobileStreakWinCount = v.dwMobileStreakWinCount + 1
        else
            v.dwMobileStreakWinCount = 0
        end

        table.insert(tForceIDList[v.nGroupID], {dwForceID = v.dwForceID})

        local tbInfo = {
            nRoleID = v.dwRoleID,
            nForceID = v.dwForceID,
            dwMountKungfuID = v.dwMountKungfuID,
            szPlayerName = v.szPlayerName,
            szGlobalRoleID = v.szGlobalRoleID,
            nKillCount = v.nKillCount or "-",
            nDamge = v.nDamge or "-",
            nHealth = v.nHealth or "-",
            nNearDeath = v.nNearDeath or "-",
            nLevel = (v.nMatchLevel or 0) + (v.nDeltaMatchLevel or 0),
            nScore = v.nDeltaMatchLevel or 0,
            bMVP = v.bMVP,
            bShowWinCount = v.dwMobileStreakWinCount >= ArenaData.MIN_SHOW_WIN_COUNT,
            nMVPCount = v.dwMVPCount,
            nStreakWinCount = v.dwMobileStreakWinCount,
            bJJCScoreProtected = v.bJJCScoreProtected,
        }

        if v.nCorpsType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
            local nPlacementCount = GetArenaPlacementNumber()
            if v.dwSeasonTotalCount < nPlacementCount then
                tbInfo.nLevel = g_tStrings.STR_ARENA_FINAL_UNNO
                tbInfo.nScore = g_tStrings.STR_ARENA_FINAL_UNNO
            else
                tbInfo.nLevel = (v.nCorpsLevel or 0) + (v.nDeltaCorpsLevel or 0)
                tbInfo.nScore = (v.nDeltaCorpsLevel or 0)
            end
        elseif v.nCorpsType == ARENA_UI_TYPE.ARENA_1V1 then
            tbInfo.nLevel = (v.nGrowupLevel or 0) + (v.nDeltaMatchLevel or 0)
        end

        table.insert(tbData.tbPlayerInfo[v.nGroupID], tbInfo)
    end

    if not tbData.szTeamName1 or tbData.szTeamName1 == "" then
        tbData.szTeamName1 = ArenaData.GetAutoName(tForceIDList[0] or {})
    end

    if not tbData.szTeamName2 or tbData.szTeamName2 == "" then
        tbData.szTeamName2 = ArenaData.GetAutoName(tForceIDList[1] or {})
    end

    return tbData
end

return UIArenaFinishDataView