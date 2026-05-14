-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoStatsView
-- Date: 2026-04-15 10:55:41
-- Desc: 扬刀大会 最终通关结算数据统计界面 PanelYangDaoStats
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoStatsView = class("UIPanelYangDaoStatsView")

function UIPanelYangDaoStatsView:OnEnter(tBattleFieldInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitTogPlayer()
        self.scriptSideDetail = UIHelper.GetBindScript(self.WidgetRightSidePanel)
        UIHelper.SetTouchDownHideTips(self.BtnBlock, false)
    end

    self.tBattleFieldInfo = tBattleFieldInfo
    self:UpdateInfo()

    UIMgr.HideView(VIEW_ID.PanelRevive)
    UIMgr.HideLayer(UILayer.Main)
end

function UIPanelYangDaoStatsView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIMgr.ShowLayer(UILayer.Main)
    UIMgr.ShowView(VIEW_ID.PanelRevive)
end

function UIPanelYangDaoStatsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnRest, EventType.OnClick, function()
        UIMgr.Close(self)
        ArenaTowerData.PlayerRest()
    end)
    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_LEAVE_CONFIRM, function()
            ArenaTowerData.LeaveArenaTower()
            UIMgr.Close(self)
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnElementDetail, EventType.OnClick, function()
        if UIHelper.GetVisible(self.WidgetRightSidePanel) then
            return
        end
        UIHelper.SetVisible(self.WidgetRightSidePanel, true)
        UIHelper.StopAni(self, self.AniRight, "AniRightShow")
        UIHelper.StopAni(self, self.AniRight, "AniRightHide")
        UIHelper.PlayAni(self, self.AniRight, "AniRightShow")
    end)
    UIHelper.BindUIEvent(self.BtnBlessList, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelYangDaoOverview, 2, self.tPlayerStats, self.nSelPlayerID)
    end)

end

function UIPanelYangDaoStatsView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if not UIHelper.GetVisible(self.WidgetRightSidePanel) then
            return
        end
        UIHelper.StopAni(self, self.AniRight, "AniRightShow")
        UIHelper.StopAni(self, self.AniRight, "AniRightHide")
        UIHelper.PlayAni(self, self.AniRight, "AniRightHide", function()
            UIHelper.SetVisible(self.WidgetRightSidePanel, false)
        end)
    end)
    -- 打开持有祝福界面会导致选中的Toggle被取消选中，这里恢复一下
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelYangDaoOverview then
            if self.selectedTog then
                UIHelper.SetSelected(self.selectedTog, true)
            end
        end
    end)
end

function UIPanelYangDaoStatsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- self.tTogPlayer
function UIPanelYangDaoStatsView:InitTogPlayer()
    self.tWidgetHead = {}
    self.tLabelNameNormal = {}
    self.tLabelNameUp = {}

    for i, togPlayer in ipairs(self.tTogPlayer or {}) do
        UIHelper.SetTouchDownHideTips(togPlayer, false)
        local widgetHead = UIHelper.GetChildByName(togPlayer, "WidgetHead")
        local labelNameNormal = UIHelper.GetChildByPath(togPlayer, "WidgetNormal/LabelName")
        local labelNameUp = UIHelper.GetChildByPath(togPlayer, "WidgetUp/LabelName")
        self.tWidgetHead[i] = widgetHead
        self.tLabelNameNormal[i] = labelNameNormal
        self.tLabelNameUp[i] = labelNameUp
    end
end

function UIPanelYangDaoStatsView:UpdateInfo()
    self:InitPlayerStats()

    local nDiffMode, _, _, _ = ArenaTowerData.GetBaseInfo()
    UIHelper.SetVisible(self.LabelNumPractice, nDiffMode == ArenaTowerDiffMode.Practice)
    UIHelper.SetVisible(self.LabelNumChallenge, nDiffMode == ArenaTowerDiffMode.Challenge)

    self.tScriptHead = self.tScriptHead or {}
    for i = 1, #self.tTogPlayer do
        local togPlayer = self.tTogPlayer[i]
        local tStats = self.tPlayerStats and self.tPlayerStats[i]
        if tStats then
            local _, szName = UIHelper.TruncateString(tStats.szName, 5, nil, 4)
            UIHelper.SetString(self.tLabelNameNormal[i], szName)
            UIHelper.SetString(self.tLabelNameUp[i], szName)
            if not self.tScriptHead[i] then
                self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
            end
            self.tScriptHead[i]:SetHeadWithImg(PlayerKungfuImg[tStats.dwMountKungfuID])
            self.tScriptHead[i]:SetHeadContentSize(96, 96)
            self.tScriptHead[i]:SetTouchEnabled(false)
            UIHelper.UnBindUIEvent(togPlayer, EventType.OnSelectChanged)
            UIHelper.BindUIEvent(togPlayer, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.selectedTog = togPlayer
                    self.nSelPlayerID = tStats.dwPlayerID
                    self:UpdateStatsInfo()
                end
            end)
        else
            UIHelper.SetString(self.tLabelNameNormal[i], "")
            UIHelper.SetString(self.tLabelNameUp[i], "")
            UIHelper.RemoveAllChildren(self.tWidgetHead[i]) -- 清除头像，只保留头像框，不知道为啥ClearTexture无效，所以这里重刷一下
            self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
            self.tScriptHead[i]:SetTouchEnabled(false)
            UIHelper.UnBindUIEvent(togPlayer, EventType.OnSelectChanged)
        end
    end

    UIHelper.SetSelected(self.tTogPlayer[1], true)
    UIHelper.LayoutDoLayout(self.WidgetPlayerList)
end

function UIPanelYangDaoStatsView:UpdateStatsInfo()
    local dwPlayerID = self.nSelPlayerID
    local tStats = nil
    for _, v in ipairs(self.tPlayerStats or {}) do
        if v.dwPlayerID == dwPlayerID then
            tStats = v
            break
        end
    end

    UIHelper.RemoveAllChildren(self.WidgetAnchorPersonalCardShell)
    if tStats then
        -- local nHDKungFuID = TabHelper.GetHDKungfuID(tStats.dwMountKungfuID)
        -- local nPosType = PlayerKungfuPosition[nHDKungFuID]
        -- UIHelper.SetVisible(self.WidgetStatDamage, nPosType == KUNGFU_POSITION.DPS)
        -- UIHelper.SetVisible(self.WidgetStatHeal, nPosType == KUNGFU_POSITION.Heal)

        -- TODO 这个版本还拿不到伤害数据，这里先不显示了
        -- UIHelper.SetVisible(self.WidgetStatDamage, (tStats.nDamage or 0) >= (tStats.nHeal or 0))
        -- UIHelper.SetVisible(self.WidgetStatHeal, (tStats.nDamage or 0) < (tStats.nHeal or 0))

        local szDamage = tStats.nDamage and (tStats.nDamage .. "万") or "-"
        local szHeal = tStats.nHeal and (tStats.nHeal .. "万") or "-"
        UIHelper.SetString(self.LabelNumDamage, szDamage)
        UIHelper.SetString(self.LabelNumHeal, szHeal)

        local szTime = "--:--:--"
        if tStats.nTime then
            szTime = UIHelper.GetTimeText(tStats.nTime)
        end
        UIHelper.SetString(self.LabelNumTime, szTime)

        local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetAnchorPersonalCardShell, tStats.szGlobalID)
        if tipsScriptView then
            tipsScriptView:OnEnter(tStats.szGlobalID)
            tipsScriptView:SetPlayerId(tStats.dwPlayerID)
            local tInfo = {
                szName = tStats.szName,
                dwPlayerID = tStats.dwPlayerID,
                dwForceID = tStats.dwForceID,
                szHeadIconPath = PlayerForceID2SchoolImg2[tStats.dwForceID],
            }
            tipsScriptView:SetPersonalInfo(tInfo)
        end
    else
        UIHelper.SetVisible(self.WidgetStatDamage, true)
        UIHelper.SetVisible(self.WidgetStatHeal, false)
        UIHelper.SetString(self.LabelNumDamage, "-")
        UIHelper.SetString(self.LabelNumTime, "--:--:--")
    end

    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    local tElementPoint = tStats and tStats.tElementPoint
    for _, nType in pairs(BlessElementType) do
        UIHelper.SetString(self.tLabelElement[nType], tElementPoint and tElementPoint[nType] or 0)
    end

    self.scriptSideDetail:OnEnter(tElementPoint)
end

function UIPanelYangDaoStatsView:InitPlayerStats()
    if not self.tBattleFieldInfo then
        return
    end

    local tStatistics = self.tBattleFieldInfo.tStatistics
    local nClientPlayerSide = self.tBattleFieldInfo.nClientPlayerSide

    self.tScriptHead = self.tScriptHead or {}

    local tPlayerList = {}
    for _, tData in ipairs(tStatistics or {}) do
        if tData.nBattleFieldSide == nClientPlayerSide then
            table.insert(tPlayerList, tData)
        end
    end

    self.tPlayerStats = {}
    for _, tData in ipairs(tPlayerList) do
        local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
        local tBlessCardList = ArenaTowerData.GetCardListInfo()
        local nTotalTime, nTotalDamage, nTotalTherapy = ArenaTowerData.GetStatsInfo()

        local tStats = {
            dwPlayerID = tData.dwPlayerID,
            dwForceID = tData.ForceID,
            dwMountKungfuID = tData.dwMountKungfuID,
            szGlobalID = tData.GlobalID,
            szName = UIHelper.GBKToUTF8(tData.Name),
            tElementPoint = tElementPoint,
            tBlessCardList = tBlessCardList,
            nTime = nTotalTime,
            nDamage = nTotalDamage,
            nHeal = nTotalTherapy,
        }
        table.insert(self.tPlayerStats, tStats)
    end

    -- 排序 自己在前 后面按ID排
    local player = GetClientPlayer()
    local dwSelfPlayerID = player and player.dwID
    table.sort(self.tPlayerStats, function(a, b)
        if a.dwPlayerID == dwSelfPlayerID then
            return true
        end
        if b.dwPlayerID == dwSelfPlayerID then
            return false
        end
        return a.dwPlayerID < b.dwPlayerID
    end)
end

return UIPanelYangDaoStatsView