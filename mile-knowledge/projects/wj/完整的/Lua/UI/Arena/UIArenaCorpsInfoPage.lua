-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaCorpsInfoPage
-- Date: 2024-04-10 11:12:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaCorpsInfoPage = class("UIArenaCorpsInfoPage")

local ARENA_MODE_TYPE = {
    ARENA_2V2           = 1,
    ARENA_3V3           = 2,
    ARENA_5V5           = 3,
    ARENA_MASTER_3V3    = 5,
    ARENA_1V1           = 6,
}

local ARENA_MODE_TO_NAME = {
    [ARENA_MODE_TYPE.ARENA_2V2] = "个人战绩（2对2）",
    [ARENA_MODE_TYPE.ARENA_3V3] = "个人战绩（3对3）",
    [ARENA_MODE_TYPE.ARENA_5V5] = "个人战绩（5对5）",
    [ARENA_MODE_TYPE.ARENA_1V1] = "个人战绩（1对1）",
}

function UIArenaCorpsInfoPage:OnEnter(nCurSelectMode, nPlayerID)
    self.nPlayerID = nPlayerID
    self.nCurSelectMode = nCurSelectMode or ARENA_MODE_TYPE.ARENA_2V2
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaCorpsInfoPage:OnExit()
    self.bInit = false
end

function UIArenaCorpsInfoPage:BindUIEvent()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandings, self.TogMartial01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandings, self.TogMartial02)

    UIHelper.BindUIEvent(self.WidgetBtnTeamStandingsEmpty, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPArenaTeamNamePop, self:GetCurArenaType())
    end)

    UIHelper.BindUIEvent(self.BtnHelpHonor, EventType.OnClick, function(btn)
        local szDesc = string.pure_text(g_tStrings.STR_JJC_MOBILE_HONOR_COUNT)
		local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnHelpHonor, TipsLayoutDir.BOTTOM_CENTER, szDesc)
	end)
end

function UIArenaCorpsInfoPage:RegEvent()
    Event.Reg(self, "SYNC_CORPS_LIST", function (nPeekID)
        local nPlayerID = self:GetPlayerID()
        if nPlayerID then
            local crosID = ArenaData.GetCorpsID(0, nPlayerID)
            if crosID and crosID ~= 0 then
                SyncCorpsBaseData(crosID, false, nPlayerID)
            end
        end

        self:UpdateInfo()
	end)

	Event.Reg(self, "REQUEST_ARENA_CORPS", function (nPeekID)
		-- ArenaData.SyncAllCorpsBaseInfo()
	end)

    Event.Reg(self, "SYNC_CORPS_MEMBER_DATA", function (nCorpsID, nCorpsType, nPlayerID)
        self:UpdateInfo()
	end)

    Event.Reg(self, "CORPS_OPERATION", function(nType, nRetCode, dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName, szCorpsName)
		if nRetCode == CORPS_OPERATION_RESULT_CODE.SUCCESS then
            ArenaData.SyncAllCorpsBaseInfo()
            self:UpdateInfo()
		end
    end)
end

function UIArenaCorpsInfoPage:UpdateInfo()
    self:UpdateDataInfo()
    self:UpdateTeamInfo()
end

function UIArenaCorpsInfoPage:UpdateDataInfo()
    local nPlayerID = self:GetPlayerID()
    if not nPlayerID then
        return
    end
    local nArenaType = self:GetCurArenaType()
    local tbSelfData = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)

    UIHelper.SetVisible(self.WidgetAnchorStandingsTitle, nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)
    if nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
        UIHelper.SetVisible(self.WidgetPersonageStandings, false)
    else
        UIHelper.SetVisible(self.WidgetPersonageStandings, true)
    end

    UIHelper.LayoutDoLayout(self.WidgetPersonageStandings)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStandings)

    local tbSelfInfo = {
        [1] = {
            nTotalCount = tbSelfData.dwSeasonTotalCount or 0,
            nWinCount = tbSelfData.dwSeasonWinCount or 0,
            szTitle = "赛季总计",
            bVK = false,
        },
        [2] = {
            nTotalCount = tbSelfData.dwWeekTotalCount or 0,
            nWinCount = tbSelfData.dwWeekWinCount or 0,
            szTitle = "本周总计",
            bVK = false,
        },
        [3] = {
            nTotalCount = tbSelfData.dwLastWeekTotalCount or 0,
            nWinCount = tbSelfData.dwLastWeekWinCount or 0,
            szTitle = "上周总计",
            bVK = false,
        },
        [4] = {
            nTotalCount = tbSelfData.dwMobileSeasonTotalCount or 0,
            nWinCount = tbSelfData.dwMobileSeasonWinCount or 0,
        },
        [5] = {
            nTotalCount = tbSelfData.dwMobileWeekTotalCount or 0,
            nWinCount = tbSelfData.dwMobileWeekWinCount or 0,
        },
        [6] = {
            nTotalCount = tbSelfData.dwMobileLastWeekTotalCount or 0,
            nWinCount = tbSelfData.dwMobileLastWeekWinCount or 0,
        },
        [7] = {
            nTotalCount = tbSelfData.dwMobileHonorTotalCount or 0,
            nWinCount = tbSelfData.dwMobileHonorWinCount or 0,
        },
    }

    if nArenaType == ARENA_UI_TYPE.ARENA_1V1 then
        tbSelfInfo = {
            [1] = {
                nTotalCount = tbSelfData.dwMobileSeasonTotalCount or 0,
                nWinCount = tbSelfData.dwMobileSeasonWinCount or 0,
                szTitle = "     赛季",
                bVK = true,
            },
            [2] = {
                nTotalCount = tbSelfData.dwMobileWeekTotalCount or 0,
                nWinCount = tbSelfData.dwMobileWeekWinCount or 0,
                szTitle = "     本周",
                bVK = true,
            },
            [3] = {
                nTotalCount = tbSelfData.dwMobileLastWeekTotalCount or 0,
                nWinCount = tbSelfData.dwMobileLastWeekWinCount or 0,
                szTitle = "     上周",
                bVK = true,
            },
        }

        UIHelper.SetToggleGroupSelected(self.ToggleGroupStandings, 0)
    end

    for i, cell in ipairs(self.tbScriptPersonageDataCell) do
        local script = UIHelper.GetBindScript(cell)
        script:OnEnter(tbSelfInfo[i] or {})

        UIHelper.SetVisible(cell, not not tbSelfInfo[i])
    end
    UIHelper.SetVisible(self.tbScriptPersonageDataCell[7], false)
    if tbSelfData.dwMobileHonorTotalCount and tbSelfData.dwMobileHonorTotalCount > 0 then
        UIHelper.SetVisible(self.tbScriptPersonageDataCell[7], true)
    end
    UIHelper.SetVisible(self.ImgBgPersonageStandingsTitle, table.get_len(tbSelfInfo) > 3)
    UIHelper.SetVisible(self.ImgBgPersonageStandingsTitle2, table.get_len(tbSelfInfo) == 3)

    local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
    local tbTeamInfo = {}
    if nCorpsID and nCorpsID > 0 then
        local tbTeamData = ArenaData.tbCorpsInfo[nArenaType] or {}
        tbTeamInfo = {
            [1] = {
                nTotalCount = tbTeamData.dwSeasonTotalCount or 0,
                nWinCount = tbTeamData.dwSeasonWinCount or 0,
            },
            [2] = {
                nTotalCount = tbTeamData.dwWeekTotalCount or 0,
                nWinCount = tbTeamData.dwWeekWinCount or 0,
            },
            [3] = {
                nTotalCount = tbTeamData.dwLastWeekTotalCount or 0,
                nWinCount = tbTeamData.dwLastWeekWinCount or 0,
            },
            -- [4] = {
            --     nTotalCount = tbTeamData.dwMobileSeasonTotalCount or 0,
            --     nWinCount = tbTeamData.dwMobileSeasonWinCount or 0,
            -- },
            -- [5] = {
            --     nTotalCount = tbTeamData.dwMobileWeekTotalCount or 0,
            --     nWinCount = tbTeamData.dwMobileWeekWinCount or 0,
            -- },
            -- [6] = {
            --     nTotalCount = tbTeamData.dwMobileLastWeekTotalCount or 0,
            --     nWinCount = tbTeamData.dwMobileLastWeekWinCount or 0,
            -- },
        }

        if nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
            tbTeamInfo = {
                [1] = {
                    nTotalCount = tbTeamData.dwSeasonTotalCount or 0,
                    nWinCount = tbTeamData.dwSeasonWinCount or 0,
                },
                [2] = {
                    nTotalCount = tbTeamData.dwWeekTotalCount or 0,
                    nWinCount = tbTeamData.dwWeekWinCount or 0,
                },
                [3] = {
                    nTotalCount = tbTeamData.dwLastWeekTotalCount or 0,
                    nWinCount = tbTeamData.dwLastWeekWinCount or 0,
                },
            }
        end
    end

    local bEmpty = not nCorpsID or nCorpsID <= 0
    UIHelper.SetVisible(self.WidgetTeamStandingsContent, not bEmpty)
    UIHelper.SetVisible(self.WidgetTeamStandingsEmpty, bEmpty)
    UIHelper.SetVisible(self.ImgBgTeamStandingsTitle, not bEmpty and #tbTeamInfo > 3)
    UIHelper.SetVisible(self.ImgBgTeamStandingsTitle2, not bEmpty and #tbTeamInfo == 3)
    UIHelper.SetVisible(self.WidgetTeamStandingsTitle, not bEmpty)
    UIHelper.SetVisible(self.WidgetBtnTeamStandingsEmpty, bEmpty)

    UIHelper.SetVisible(self.WidgetTeamStandings, nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)

    -- UIHelper.SetString(self.LabelPersonageStandings, ARENA_MODE_TO_NAME[self.nCurSelectMode])

    for i, cell in ipairs(self.tbScriptTeamDataCell) do
        local script = UIHelper.GetBindScript(cell)
        script:OnEnter(tbTeamInfo[i] or {})

        UIHelper.SetVisible(cell, not not tbTeamInfo[i])
    end
    UIHelper.LayoutDoLayout(self.WidgetTeamStandings)

    UIHelper.ScrollViewDoLayout(self.ScrollViewStandings)
    UIHelper.ScrollToTop(self.ScrollViewStandings, 0)

    UIHelper.RemoveAllChildren(self.WidgetArrow)
    self.WidgetArrow._widgetArrow = nil
    UIHelper.ScrollViewSetupArrow(self.ScrollViewStandings, self.WidgetArrow)
end

function UIArenaCorpsInfoPage:UpdateTeamInfo()
    local nPlayerID = self:GetPlayerID()
    if not nPlayerID then
        return
    end
    local nArenaType = self:GetCurArenaType()
    if not self.scriptTeamPage then
        self.scriptTeamPage = UIHelper.GetBindScript(self.WidgetAnchorTeam)
    end

    self.scriptTeamPage:OnEnter(nArenaType, nPlayerID)
end

function UIArenaCorpsInfoPage:GetCurArenaType()
    return ArenaData.tbCorpsList[self.nCurSelectMode]
end

function UIArenaCorpsInfoPage:GetPlayerID()
    return self.nPlayerID or PlayerData.GetPlayerID()
end

return UIArenaCorpsInfoPage