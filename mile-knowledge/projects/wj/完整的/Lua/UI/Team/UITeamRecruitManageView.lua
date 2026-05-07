-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitManageView
-- Date: 2023-02-10 10:27:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tbPostion2Name = {
    ["Heal"] = "治疗",
    ["T"] = "肉盾",
    ["Dps"] = "输出",
    ["Leader"] = "指挥",
    ["Pay"] = "老板",
}

local tbForceIdxMap = {}

local UITeamRecruitManageView = class("UITeamRecruitManageView")

function UITeamRecruitManageView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbApplyPlayerItems = {}

    local scriptChat = UIHelper.GetBindScript(self.BtnChat)
    if scriptChat then
        scriptChat:OnEnter(UI_Chat_Channel.Team)
    end
    self:UpdateFilterInfo()
    self:UpdateInfo()
end

function UITeamRecruitManageView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitManageView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAmend, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, TeamBuilding.tbSelfRecruitInfo)
    end)

    UIHelper.BindUIEvent(self.BtnRevocation, EventType.OnClick, function ()
        TeamBuilding.UnregisterTeamPushInfo()
    end)

    UIHelper.BindUIEvent(self.BtnAffirm, EventType.OnClick, function ()
        UIHelper.SetSelected(self.TogScreen, false)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        self:UpdateFilterInfo()
    end)

    UIHelper.BindUIEvent(self.TogScreen, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogScreen, TipsLayoutDir.BOTTOM_CENTER, FilterDef.TeamRecruit)
    end)

    UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function ()
        UIHelper.SetSelected(self.TogScreen, false)
    end)

    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function()
        local szTips = string.format("<color=#FEFEFE>%s</color>", g_tStrings.STR_TEAM_RECRUIT_HINT)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, szTips)
        local nWidth, nHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nWidth, nHeight)
        tips:UpdatePosByNode(self.BtnHint)
    end)

    UIHelper.BindUIEvent(self.BtnRelease, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, nil, nil)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        TeamBuilding.Share(false)
    end)
end

function UITeamRecruitManageView:RegEvent()
    Event.Reg(self, EventType.OnRecruitPushTeam, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSyncApplyPlayerList, function ()
        self:UpdateApplyPlayerList()
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function ()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function ()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_CREATE", function()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DESTROY", function()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:TryUpdateRecruitInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szkey, tbSelected)
        if szkey == FilterDef.TeamRecruit.Key then
            self:UpdateApplyPlayerList()
        end
    end)
end

function UITeamRecruitManageView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitManageView:UpdateInfo()
    local tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo
    if not tbSelfRecruitInfo or table_is_empty(tbSelfRecruitInfo) then
        UIHelper.SetString(self.LabelDescibeRecruitTeam, "尚未发布招募")
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.SetVisible(self.WidgetContentNotReleased, true)
        UIHelper.SetVisible(self.WidgetContentReleased, false)
        self:UpdateApplyPlayerList()
        return
    end

    UIHelper.SetString(self.LabelDescibeRecruitTeam, "暂未收到招募申请")
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.SetVisible(self.WidgetContentNotReleased, false)
    UIHelper.SetVisible(self.WidgetContentReleased, true)

    local dwID = tbSelfRecruitInfo["dwActivityID"]
    local tbTeamInfo = Table_GetTeamInfo(dwID)
    UIHelper.SetString(self.LabelDungeonTitle, UIHelper.GBKToUTF8(tbTeamInfo.szName))
    UIHelper.SetString(self.LabelTeamNum, tbSelfRecruitInfo["nCurrentMemberCount"] .. "/" .. tbTeamInfo.dwMaxPlayerNum)
    UIHelper.SetString(self.LabelGrade, tbTeamInfo.dwMinLevel .. "级")
    local szComment, szRealComment = TeamBuilding.GetTeamPushComment(tbSelfRecruitInfo)
    local nCharCount, szTopChars = TeamBuilding.GetStringCharCount(szComment, 23)
    if nCharCount > 23 then
        szComment = szTopChars.."……"
    end

    UIHelper.SetString(self.LabelTeamRemark, szComment)
    local dwCurrentTime = GetCurrentTime()
    local szTime = TeamBuilding.GetCreateTime(dwCurrentTime, tbSelfRecruitInfo["nCreateTime"])
    UIHelper.SetString(self.LabelTime, szTime)

    self:UpdateApplyPlayerList()
end

function UITeamRecruitManageView:UpdateApplyPlayerList()
    local fnCallback = function (dwRoleID, szGlobalID)
        for i, item in ipairs(self.tbApplyPlayerItems) do
            if item.tbPlayerInfo["szGlobalID"] then
                if item.tbPlayerInfo["szGlobalID"] == szGlobalID then
                    table.remove(self.tbApplyPlayerItems, i)
                    UIHelper.RemoveFromParent(item._rootNode, true)
                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTeam)
                    break
                end
            else
                if item.tbPlayerInfo["dwRoleID"] == dwRoleID then
                    table.remove(self.tbApplyPlayerItems, i)
                    UIHelper.RemoveFromParent(item._rootNode, true)
                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTeam)
                    break
                end
            end
        end
        UIHelper.SetVisible(self.ScrollViewTeam, #self.tbApplyPlayerItems > 0)
        UIHelper.SetVisible(self.WidgetEmptyRecruitTeam, #self.tbApplyPlayerItems <= 0)
    end

    local tbRuntime = FilterDef.TeamRecruit.tbRuntime
    local nSortType = tbRuntime and tbRuntime[1][1] or FilterDef.TeamRecruit[1].tbDefault[1]
    local tForceIdxList = tbRuntime and tbRuntime[2] or FilterDef.TeamRecruit[2].tbDefault
    local tPosList = tbRuntime and tbRuntime[3] or FilterDef.TeamRecruit[3].tbDefault

    local tbApplyPlayerList = TeamBuilding.tbAppliedPlayerList
    local tbSortFilterList = {}
    for _, tbPlayerInfo in ipairs(tbApplyPlayerList) do
        local bForce = false
        for _, i in ipairs(tForceIdxList) do
            local nForceID = tbForceIdxMap[i]
            if nForceID == tbPlayerInfo["nForceID"] then
                bForce = true
                break
            end
        end
        local bPos = false
        for _, i in ipairs(tPosList) do
            local bBit = GetNumberBit(tbPlayerInfo["nPosition"], i)
            if bBit then
                bPos = true
                break
            end
        end
        if bForce and bPos then
            table.insert(tbSortFilterList, tbPlayerInfo)
        end
    end

    if nSortType == 1 then
		table.sort(tbSortFilterList, function(a, b) return a["nEquipScore"] > b["nEquipScore"] end)
	else
		table.sort(tbSortFilterList, function(a, b) return a["nEquipScore"] < b["nEquipScore"] end)
	end
    self.tbApplyPlayerItems = {}
    UIHelper.RemoveAllChildren(self.ScrollViewTeam)
    for _, tbPlayerInfo in ipairs(tbSortFilterList) do
        local item = UIHelper.AddPrefab(PREFAB_ID.WidgetRecruitTeamCell, self.ScrollViewTeam, tbPlayerInfo, fnCallback)
        table.insert(self.tbApplyPlayerItems, item)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewTeam)
    UIHelper.ScrollToTop(self.ScrollViewTeam, 0)
    UIHelper.SetVisible(self.ScrollViewTeam, #tbSortFilterList > 0)
    UIHelper.SetVisible(self.WidgetEmptyRecruitTeam, #tbSortFilterList <= 0)
end

function UITeamRecruitManageView:UpdateFilterInfo()
    local count = 1
    FilterDef.TeamRecruit[2].tbList = {}
    FilterDef.TeamRecruit[2].tbDefault = {}
    local tForceList = Table_GetAllForceUI()
    for nForceID, v in pairs(tForceList) do
        table.insert(FilterDef.TeamRecruit[2].tbList, v.szName)
        table.insert(FilterDef.TeamRecruit[2].tbDefault, count)
        tbForceIdxMap[count] = nForceID
        count = count + 1
    end
    FilterDef.TeamRecruit[3].tbList = {}
    FilterDef.TeamRecruit[3].tbDefault = {}
    for i = 1, 5 do
        local tbInfo = Table_GetTeamRecruitMask(i)
        table.insert(FilterDef.TeamRecruit[3].tbList, tbPostion2Name[tbInfo.szPosition])
        table.insert(FilterDef.TeamRecruit[3].tbDefault, i)
    end
end

function UITeamRecruitManageView:TryUpdateRecruitInfo()
    local tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo
    if table_is_empty(tbSelfRecruitInfo) then
        return
    end
    local dwApplyID = tbSelfRecruitInfo["dwRoleID"]
    local szRoomID = tbSelfRecruitInfo["szRoomID"]
    if dwApplyID then
        ApplyTeamPushSingle(dwApplyID)
    elseif szRoomID then
        GetGlobalRoomPushClient().ApplyRoomPushSingle(szRoomID)
    end
end

return UITeamRecruitManageView