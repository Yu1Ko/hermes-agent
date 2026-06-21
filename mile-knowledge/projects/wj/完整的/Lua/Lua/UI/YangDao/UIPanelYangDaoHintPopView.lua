-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoHintPopView
-- Date: 2026-03-09 19:32:24
-- Desc: 扬刀大会-报名界面提示窗口 PanelYangDaoHintPop
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoHintPopView = class("UIPanelYangDaoHintPopView")

function UIPanelYangDaoHintPopView:OnEnter(tTeamData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tTeamData = tTeamData
    self:UpdateInfo()
end

function UIPanelYangDaoHintPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoHintPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelYangDaoHintPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelYangDaoHintPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoHintPopView:UpdateInfo()
    -- local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo() -- 以玩家当前的作为基准
    -- if nLevelProgress <= 0 then
    --     nDiffMode = ArenaTowerData.GetSelDiffMode()
    -- end
    local nDpsCount, nHealCount = 0, 0
    for _, tData in ipairs(self.tTeamData or {}) do
        if tData.nPosType == KUNGFU_POSITION.DPS then
            nDpsCount = nDpsCount + 1
        elseif tData.nPosType == KUNGFU_POSITION.Heal then
            nHealCount = nHealCount + 1
        end
        -- if nLevelProgress ~= tData.nLevelProgress or (tData.nLevelProgress > 0 and nDiffMode ~= tData.nDiffMode) then
        --     self:UpdateProgressInfo()
        --     return
        -- end
    end

    if nDpsCount ~= ArenaTowerData.TEAM_DPS_REQUIRE or nHealCount ~= ArenaTowerData.TEAM_HEAL_REQUIRE then
        self:UpdateTeamInfo()
    end
end

function UIPanelYangDaoHintPopView:UpdateProgressInfo()
    --szName/dwForceID/nDiffMode/nLevelProgress/nPosType
    UIHelper.SetRichText(self.RichTextDescription, g_tStrings.ARENA_TOWER_MEMBER_PROGRESS_REQUIRE)
    UIHelper.RemoveAllChildren(self.WidgetPlayerList)
    for _, tData in ipairs(self.tTeamData or {}) do
        local szCenterName = GetCenterNameByCenterID(tData.dwCenterID)
        local szName = szCenterName and (tData.szName .. "@" .. UIHelper.GBKToUTF8(szCenterName)) or tData.szName
        local dwForceID = tData.dwForceID
        local nDiffMode = tData.nDiffMode
        local nLevelProgress = tData.nLevelProgress
        local szDiffMode = ""
        if nDiffMode == ArenaTowerDiffMode.Practice then
            szDiffMode = "普通模式"
        elseif nDiffMode == ArenaTowerDiffMode.Challenge then
            szDiffMode = "挑战模式"
        end
        local szProgress
        if nLevelProgress > 0 then
            szProgress = string.format("%s-第%d层", szDiffMode, nLevelProgress)
        else
            szProgress = szDiffMode
            local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelProgress)
            if tLevelConfig then
                szProgress = szProgress .. "-" .. UIHelper.GBKToUTF8(tLevelConfig.szName)
            end
        end
        UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoHintPlayerCell, self.WidgetPlayerList, szName, dwForceID, szProgress)
    end
    UIHelper.LayoutDoLayout(self.WidgetPlayerList)
end

function UIPanelYangDaoHintPopView:UpdateTeamInfo()
    --szName/dwForceID/nDiffMode/nLevelProgress/nPosType
    UIHelper.SetRichText(self.RichTextDescription, g_tStrings.ARENA_TOWER_MEMBER_KUNGFU_REQUIRE)
    UIHelper.RemoveAllChildren(self.WidgetPlayerList)
    for _, tData in ipairs(self.tTeamData or {}) do
        local szName = (not string.is_nil(tData.szCenterName)) and (tData.szName .. "@" .. tData.szCenterName) or tData.szName
        local dwForceID = tData.dwForceID
        local szText = ""
        if tData.nPosType == KUNGFU_POSITION.DPS then
            szText = "输出心法"
        elseif tData.nPosType == KUNGFU_POSITION.Heal then
            szText = "治疗心法"
        elseif tData.nPosType == KUNGFU_POSITION.T then
            szText = "防御心法"
        end
        UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoHintPlayerCell, self.WidgetPlayerList, szName, dwForceID, szText)
    end
    UIHelper.LayoutDoLayout(self.WidgetPlayerList)
end

return UIPanelYangDaoHintPopView