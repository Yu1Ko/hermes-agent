-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPRankView
-- Date: 2023-04-06 16:11:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPRankView = class("UIHomelandPVPRankView")

function UIHomelandPVPRankView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nRankType = 1
    GetHomelandMgr().ApplyMyHomelandRank(self.nRankType)
    HomelandPVPData.GetHLRankList(self.nRankType, 0, 99)
    self:UpdateInfo()
end

function UIHomelandPVPRankView:OnExit()
    self.bInit = false
end

function UIHomelandPVPRankView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogBefore, EventType.OnClick, function ()
        self.nRankType = 0
        HomelandPVPData.GetHLRankList(self.nRankType, 0, 99)
        GetHomelandMgr().ApplyMyHomelandRank(self.nRankType)
    end)

    UIHelper.BindUIEvent(self.TogNow, EventType.OnClick, function ()
        self.nRankType = 1
        HomelandPVPData.GetHLRankList(self.nRankType, 0, 99)
        GetHomelandMgr().ApplyMyHomelandRank(self.nRankType)
    end)

    UIHelper.ToggleGroupAddToggle(self.TogGroupWeek, self.TogNow)
    UIHelper.ToggleGroupAddToggle(self.TogGroupWeek, self.TogBefore)
end

function UIHomelandPVPRankView:RegEvent()
    Event.Reg(self, "SYNC_HOMELAND_RANK_LIST", function(nRankType, dwBeginIndex, dwEndIndex)
        if nRankType == self.nRankType then
            self:UpdateInfo()
        end
	end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function(nRetCode, ...)
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_HL_RANK_INFO_RESPOND then
			local nRankType, nIndex, nInfo, nTotalScore = ...
            if nRankType == self.nRankType then
                self:UpdateSelfInfo(nIndex, nInfo, nTotalScore)
                self:UpdateInfo()
			end
		end
	end)
end

function UIHomelandPVPRankView:UpdateInfo()
    local tbRankList = HomelandPVPData.tWeekRankList[self.nRankType]
    self.tbCells = self.tbCells or {}
    for i, cell in ipairs(self.tbCells) do
        UIHelper.SetVisible(cell._rootNode, false)
    end

    for i, tbInfo in ipairs(tbRankList.tRankList) do
        local cell = self.tbCells[i]
        if not cell then
            cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopRanking, self.ScrollViewRanking)
            self.tbCells[i] = cell
            UIHelper.SetVisible(cell._rootNode, false)

            UIHelper.ToggleGroupAddToggle(self.TogGroupCell, cell.TogRanking)
        end

        UIHelper.SetVisible(cell._rootNode, true)
        cell:OnEnter(i, tbInfo)
    end

    for i, cell in ipairs(self.tbCells) do
        UIHelper.SetSelected(cell.TogGroupCell, false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRanking)
    UIHelper.ScrollToTop(self.ScrollViewRanking, 0)
end

function UIHomelandPVPRankView:UpdateSelfInfo(nIndex, nInfo, nTotalScore)
    self.scriptSelfCell = self.scriptSelfCell or UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopRanking, self.WidgetRightPopRanking)

    UIHelper.SetVisible(self.scriptSelfCell.ImgTag, false)
    UIHelper.SetTouchEnabled(self.scriptSelfCell.TogRanking, false)
    UIHelper.SetString(self.scriptSelfCell.LabelPlayerName, UIHelper.GBKToUTF8(PlayerData.GetPlayerName()))
    if nIndex == 0 then
        UIHelper.SetString(self.scriptSelfCell.LabelRank, "-")
    else
        UIHelper.SetString(self.scriptSelfCell.LabelRank, string.format("%d", nIndex))
    end

    local szRank = ""
    if nInfo == 0 then
		szRank = "-"
	elseif nIndex ~= 0 then
		szRank = tostring(nIndex)
	else
		szRank = FormatString(g_tStrings.STR_HOMELAND_PVP_RANK_PERCENTAGE, nInfo)
	end
    UIHelper.SetString(self.scriptSelfCell.LabelRank, szRank)
    UIHelper.SetString(self.scriptSelfCell.LabelYiRong, tostring(nTotalScore))
end


return UIHomelandPVPRankView