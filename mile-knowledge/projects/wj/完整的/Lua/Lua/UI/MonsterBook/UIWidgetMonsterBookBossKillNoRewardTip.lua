local UIWidgetMonsterBookBossKillNoRewardTip = class("UIWidgetMonsterBookBossKillNoRewardTip")

function UIWidgetMonsterBookBossKillNoRewardTip:OnEnter(tBossParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tBossParam)
end

function UIWidgetMonsterBookBossKillNoRewardTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookBossKillNoRewardTip:BindUIEvent()

end

function UIWidgetMonsterBookBossKillNoRewardTip:RegEvent()

end

function UIWidgetMonsterBookBossKillNoRewardTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookBossKillNoRewardTip:UpdateInfo(tBossParam)
    if not tBossParam.dwNpcID then
        local dwNpcIndex = tBossParam.dwNpcIndex
        local tBossNpcInfo = Table_GetDungeonBossModel(dwNpcIndex)
        tBossParam.dwNpcID = tBossNpcInfo.dwNpcID
    end
    local szBossName = tBossParam.szBossName
    UIHelper.RemoveAllChildren(self.ScrollViewList)
    for _, dwPlayerID in ipairs(tBossParam.tKillerList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetNoRewardTipPlayerCell, self.ScrollViewList)
        local szPlayerName = TeamData.GetTeammateName(dwPlayerID)
        szPlayerName = UIHelper.GBKToUTF8(szPlayerName)
        UIHelper.SetString(scriptCell.LabelName, szPlayerName, 8)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    UIHelper.SetVisible(self.WidgetEmpty, #tBossParam.tKillerList == 0)
    UIHelper.SetString(self.LabelBossName, szBossName)
end

return UIWidgetMonsterBookBossKillNoRewardTip