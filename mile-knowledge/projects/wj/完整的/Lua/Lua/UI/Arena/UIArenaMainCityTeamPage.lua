-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMainCityTeamPage
-- Date: 2022-12-30 15:10:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMainCityTeamPage = class("UIArenaMainCityTeamPage")
function UIArenaMainCityTeamPage:OnEnter(nArenaType, dwPlayerID)
    self.nArenaType = nArenaType
    self.dwPlayerID = dwPlayerID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaMainCityTeamPage:OnExit()
    self.bInit = false
end

function UIArenaMainCityTeamPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCreationTeam, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelPvPArenaTeamNamePop, self.nArenaType)
    end)

    UIHelper.BindUIEvent(self.BtnDissolveTeam, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.ARENA, "") then
            return
        end

        local nPlayerID = self.dwPlayerID
        local nCorpsID = ArenaData.GetCorpsID(self.nArenaType, nPlayerID)

        if not nCorpsID or nCorpsID <= 0 then
            TipsHelper.ShowNormalTip("你当前暂无战队")
            return
        end

        local szContent = FormatString(g_tStrings.STR_ARENA_EXIT_TIP, g_tStrings.tCorpsType[self.nArenaType])
        local fnConfirm = function ()
            ArenaData.CorpsDelMember(nPlayerID, nCorpsID)
        end
        local scriptDialog = UIHelper.ShowConfirm(ParseTextHelper.ParseNormalText(szContent, false), fnConfirm, nil, true)
    end)
end

function UIArenaMainCityTeamPage:RegEvent()
    Event.Reg(self, EventType.OnArenaStateUpdate, function(nPlayerID)
        self:UpdateInfo()
    end)

    Event.Reg(self, "SYNC_CORPS_LIST", function (nPeekID)
        self:UpdateInfo()
	end)
end

function UIArenaMainCityTeamPage:UpdateInfo()
    local nPlayerID = self.dwPlayerID
    local bSelf = self.dwPlayerID == PlayerData.GetPlayerID()
    local nCorpsID = ArenaData.GetCorpsID(self.nArenaType, nPlayerID)
    if not nCorpsID or nCorpsID <= 0 then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetTeamDetail, false)

        if bSelf then
            UIHelper.SetString(self.LabelDescibe, string.format("暂无%s名剑队伍，加入其他名剑队或点击下方按钮创建。", g_tStrings.tCorpsType[self.nArenaType]))
        else
            UIHelper.SetString(self.LabelDescibe, string.format("该侠士暂无%s名剑队伍。", g_tStrings.tCorpsType[self.nArenaType]))
        end
        UIHelper.SetString(self.LabelCreationTeam, string.format("创建%s队伍", g_tStrings.tCorpsType[self.nArenaType]))
    else
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.SetVisible(self.WidgetTeamDetail, true)

        local tbTeamData = ArenaData.tbCorpsInfo[self.nArenaType] or {}
        if not table_is_empty(tbTeamData) then
            UIHelper.SetString(self.LabelTeamName, UIHelper.GBKToUTF8(tbTeamData.szCorpsName), 12)
            UIHelper.SetString(self.LabelPeopleNum, string.format("%d/%d", tbTeamData.nMemberCount or 0, ArenaData.CorpsMemberMaxCount[self.nArenaType]))
            UIHelper.LayoutDoLayout(self.LayoutTitle)
        else
            ArenaData.SyncAllCorpsBaseInfo()
        end

        UIHelper.HideAllChildren(self.ScrollViewArenaTeamDetail)
        self.tbCells = self.tbCells or {}
        self.tbCells[self.nArenaType] = self.tbCells[self.nArenaType] or {}
        self.tbMemberData = ArenaData.tbCorpsMemberInfo[self.nArenaType] or {}
        if not table_is_empty(self.tbMemberData) then
            for i = 1, ArenaData.CorpsMemberMaxCount[self.nArenaType], 1 do
                if not self.tbCells[self.nArenaType][i] then
                    self.tbCells[self.nArenaType][i] = UIHelper.AddPrefab(PREFAB_ID.WidgetArenaTeamDetail, self.ScrollViewArenaTeamDetail)
                end

                self.tbCells[self.nArenaType][i]:OnEnter(self.nArenaType, self.tbMemberData[i])
                UIHelper.SetVisible(self.tbCells[self.nArenaType][i]._rootNode, self.tbMemberData[i] ~= nil or bSelf)
            end
        else
            ArenaData.SyncAllCorpsBaseInfo()
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewArenaTeamDetail)
        UIHelper.ScrollToTop(self.ScrollViewArenaTeamDetail, 0)
    end

    UIHelper.SetVisible(self.BtnCreationTeam, bSelf)
    UIHelper.SetVisible(self.BtnDissolveTeam, bSelf)
end


return UIArenaMainCityTeamPage