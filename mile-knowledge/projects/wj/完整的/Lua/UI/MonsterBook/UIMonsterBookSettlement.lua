local UIMonsterBookSettlement = class("UIMonsterBookSettlement")

function UIMonsterBookSettlement:OnEnter(tInfo, bCanDistribute)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:InitData(tInfo, bCanDistribute)
    self:UpdateInfo()
end

function UIMonsterBookSettlement:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookSettlement:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function ()
        if self.bCanDistribute then
            RemoteCallToServer("On_MonsterBook_CloseSettlement")
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp,
        "团队参与级别：由所有玩家持续参与战斗的时间决定；级别越高，掉落技能书概率越高。\n最终战斗得分：由战斗时长和击破首领破绽的次数决定；战斗时越短击破首领破绽次数越多，分数越高，获得临时技能的概率也将大大提升。")
    end)
end

function UIMonsterBookSettlement:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelLoading then
            UIMgr.Close(self)
        end
    end)
end

function UIMonsterBookSettlement:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookSettlement:InitData(tInfo, bCanDistribute)
    self.nLevel         = tInfo.nLevel or 0
    self.dwBossID       = tInfo.dwBossID or 0
    self.nTime          = tInfo.nTime or 0
    self.nScore         = tInfo.nScore or 0
    self.nMaxScore      = tInfo.nMaxScore or 0
    self.szAwardType    = tInfo.szAwardType or ""
    self.tPlayer        = tInfo.tPlayer or {}
    self.bCanDistribute = bCanDistribute or false    
end

function UIMonsterBookSettlement:UpdateInfo()
    local szLevel = FormatString(g_tStrings.NEW_TRIAL_VALLEY_LEVEL, self.nLevel)
    local szAvatarPath, nAvatarFrame = Table_GetFBCDBossAvatar(self.dwBossID)
    szAvatarPath = string.gsub(szAvatarPath, "ui/Image/UITga/", "Resource/DungeonBossHead/")
    szAvatarPath = string.gsub(szAvatarPath, ".UITex", "")
    szAvatarPath = string.format("%s/%02d.png", szAvatarPath, nAvatarFrame)
    local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecond(self.nTime)
    local szTime = string.format(g_tStrings.STR_TIME_14, nHour, nMinute, nSecond)
    local szScore = string.format("<color=#ffe26e>%d</c><color=#AED9E0>/%d</color>", self.nScore, self.nMaxScore)
    local szAwardType = UIHelper.GBKToUTF8(self.szAwardType)
    local szBossName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(self.dwBossID))

    UIHelper.SetString(self.LabelLevelNum, szLevel)
    UIHelper.SetTexture(self.WidgetHeadBoss72, szAvatarPath)
    UIHelper.SetString(self.LabelTimeNum, szTime)
    UIHelper.SetRichText(self.RichTextScore, szScore)
    UIHelper.SetString(self.LabelTeamRankNum, szAwardType)
    UIHelper.SetString(self.LabelBossName, szBossName)
    UIHelper.RemoveAllChildren(self.LayoutPlayerList)
    for nIndex = 1, 3 do
        local tPlayerInfo = self.tPlayer[nIndex] or {}
        UIHelper.AddPrefab(PREFAB_ID.WidgetBZSettlementPlayerCell, self.LayoutPlayerList, tPlayerInfo, nIndex)
    end
end

return UIMonsterBookSettlement