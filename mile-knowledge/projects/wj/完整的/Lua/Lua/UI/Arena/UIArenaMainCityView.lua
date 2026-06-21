-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMainCityView
-- Date: 2022-12-30 14:45:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMainCityView = class("UIArenaMainCityView")

local ARENA_MODE_TYPE = {
    ARENA_2V2           = 1,
    ARENA_3V3           = 2,
    ARENA_5V5           = 3,
    ARENA_MASTER_3V3    = 5,
    ARENA_1V1           = 6,
}

local tbMode2TogIndex = {
    [ARENA_MODE_TYPE.ARENA_2V2] = 1,
    [ARENA_MODE_TYPE.ARENA_3V3] = 2,
    [ARENA_MODE_TYPE.ARENA_5V5] = 3,
    [ARENA_MODE_TYPE.ARENA_MASTER_3V3] = 4,
    [ARENA_MODE_TYPE.ARENA_1V1] = 5,
}

function UIArenaMainCityView:OnEnter(dwPlayerID, nCurSelectMode)
    self.nCurSelectMode = nCurSelectMode or ARENA_MODE_TYPE.ARENA_2V2
    self.dwPlayerID = dwPlayerID or PlayerData.GetPlayerID()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        ArenaData.SetPlayerIDByPeek(self.dwPlayerID)
        SyncCorpsList(self.dwPlayerID)
        ArenaData.SyncAllCorpsBaseInfo()
        self.bInit = true
    end
    self:InitToggleGroup()
    self:UpdateCurrencyInfo()
    self:UpdateWinRewardInfo()
    self:UpdateInfo()

    UIHelper.SetToggleGroupSelected(self.ToggleGroupMode, tbMode2TogIndex[self.nCurSelectMode] - 1)
end

function UIArenaMainCityView:OnExit()
    self.bInit = false
end

function UIArenaMainCityView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUpperLimit, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop)
    end)

    UIHelper.BindUIEvent(self.BtnHelp2, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop)
    end)

    UIHelper.BindUIEvent(self.BtnWrite, EventType.OnClick, function()
        local nArenaType = self:GetCurArenaType()
        UIMgr.Open(VIEW_ID.PanelPvPArenaReward, nArenaType)
    end)

    for i, tog in ipairs(self.tbTogMode) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self.nCurSelectMode = table.get_key(tbMode2TogIndex, i)
            -- ArenaData.SyncAllCorpsBaseInfo()
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(self.BtnMoney1, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.BtnMoney1, CurrencyType.Prestige)
    end)

    UIHelper.BindUIEvent(self.BtnMoney2, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.BtnMoney2, CurrencyType.TitlePoint)
    end)

    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function()
        -- TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetNPCGuideTips, self.BtnLeaveFor, TipsLayoutDir.BOTTOM_CENTER, self.tNpcArr)
        UIMgr.Open(VIEW_ID.PanelPvPMatching)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelpRule, EventType.OnClick, function(btn)
        local nArenaType = self:GetCurArenaType()
        local tbArenaInfo = ArenaData.GetCorpsRoleInfo(self.dwPlayerID, nArenaType)
        local nScore = tbArenaInfo.nMatchLevel or 1000
        local nPrestigeExtRemain = ArenaData.GetPrestigeExtRemain(nArenaType, nScore)

        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop, nPrestigeExtRemain)
    end)

    UIHelper.BindUIEvent(self.BtnXinFaHelp, EventType.OnClick, function(btn)
        local tSoloInfo = ArenaData.GetPlayerSoloInfo(self.dwPlayerID)
        local fPercentage = tSoloInfo and tSoloInfo.fPercentage or 0
        local dwCurKungfuID = tSoloInfo and tSoloInfo.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
        local nKungfuID = TabHelper.GetMobileKungfuID(dwCurKungfuID)
        local tSkillInfo = TabHelper.GetUISkill(nKungfuID)
        local szSkillName = tSkillInfo and tSkillInfo.szName or ""
        szSkillName = szSkillName:match("^(.-)%·悟$") or szSkillName

        local szIconPath = PlayerKungfuImg[dwCurKungfuID]
        szIconPath = string.gsub(szIconPath, ".png", "")
        local szTips = string.format("<img src='%s' width='50' height='50' /><color=#FFEA88>%s 出场率%d%%</>\n\n", szIconPath, szSkillName, fPercentage)
        szTips = szTips .. ParseTextHelper.ParseNormalText(g_tStrings.STR_ARENA_SOLO_KUNGFU_TIP2, false)

        UIMgr.Open(VIEW_ID.PanelPvPSoloKingPop, "玩法规则", szTips)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnXinFaHelp, false)
end

function UIArenaMainCityView:RegEvent()
    Event.Reg(self, EventType.OnArenaStateUpdate, function(nPlayerID)
        -- self:UpdateInfo()
    end)

    Event.Reg(self, "SYNC_CORPS_LIST", function (nPeekID)
		local crosID = ArenaData.GetCorpsID(0, self.dwPlayerID)
		if crosID and crosID ~= 0 then
            SyncCorpsBaseData(crosID, false, self.dwPlayerID)
        end
        self:UpdateCurrencyInfo()
        self:UpdateWinRewardInfo()
        self:UpdateInfo()
	end)

	Event.Reg(self, "REQUEST_ARENA_CORPS", function (nPeekID)
		-- ArenaData.SyncAllCorpsBaseInfo()
	end)

    Event.Reg(self, "SYNC_CORPS_MEMBER_DATA", function (nCorpsID, nCorpsType, nPlayerID)
        self:UpdateCurrencyInfo()
        self:UpdateWinRewardInfo()
        self:UpdateInfo()
	end)

    Event.Reg(self, "CORPS_OPERATION", function(nType, nRetCode, dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName, szCorpsName)
		if nRetCode == CORPS_OPERATION_RESULT_CODE.SUCCESS then
            ArenaData.SyncAllCorpsBaseInfo()
            self:InitToggleGroup()
            self:UpdateCurrencyInfo()
            self:UpdateWinRewardInfo()
            self:UpdateInfo()
		end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptWinRewardItem then
            self.scriptWinRewardItem:SetSelected(false)
        end
        if self.scriptWinRewardItemTip then
            UIHelper.SetVisible(self.scriptWinRewardItemTip._rootNode, false)
        end

        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnUpdateArenaSeasonHighestRankScore, function (nPlayerID, tbInfo)
        if nPlayerID == self.dwPlayerID then
            self.tbSeasonHighestRankScore = tbInfo
        end
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.scriptWinRewardItem then
            self.scriptWinRewardItem:SetSelected(false)
        end
        if self.scriptWinRewardItemTip then
            self.scriptWinRewardItemTip:OnInit()
        end

        UIHelper.SetSelected(self.TogHelp3, false)

        UIHelper.SetVisible(self.LayoutRankRewardInfo, false)
    end)

    Event.Reg(self, "REMOTE_MASTER2V2_JJC1V1_EVENT", function ()
        self:UpdateSoloInfo()
    end)
end

function UIArenaMainCityView:InitToggleGroup()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandings, self.TogMartial01)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandings, self.TogMartial02)

    for i, tog in ipairs(self.tbTogMode) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupMode, tog)
    end
end

function UIArenaMainCityView:UpdateInfo()
    self:UpdateRewardInfo()
    self:UpdateArenaInfo()
    self:UpdateSoloInfo()
    self:UpdateDataInfo()
    self:UpdateTeamInfo()
    self:UpdateNavigationInfo()
end

function UIArenaMainCityView:UpdateWinRewardInfo()
    local tbRewardItems = GDAPI_JJC5WinItem() --dwTabType, dwIndex, nCount

    if not tbRewardItems then
        return
    end

    local tbItemInfo = tbRewardItems[1]
    if not tbItemInfo then
        return
    end

    if not self.scriptWinRewardItem then
        self.scriptWinRewardItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetWinReward)
    end

    self.scriptWinRewardItem:OnInitWithTabID(tbItemInfo[1], tbItemInfo[2])
    self.scriptWinRewardItem:SetClickCallback(function(nTabType, nTabID)
        if not self.scriptWinRewardItemTip then
            self.scriptWinRewardItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
        end
        self.scriptWinRewardItemTip:OnInitWithTabID(nTabType, nTabID)
        self.scriptWinRewardItemTip:SetBtnState({})
    end)
    self.scriptWinRewardItem:SetLabelCount(tbItemInfo[3])
end

function UIArenaMainCityView:UpdateRewardInfo()
    local nArenaType = self:GetCurArenaType()

    if not nArenaType or nArenaType >= ARENA_UI_TYPE.ARENA_END then
        return
    end

    local nPrestigeExtRemain = ArenaData.GetPrestigeExtRemain(nArenaType)
    local nLeftDoubleCount, nMaxDoubleCount = ArenaData.GetDoubleRewardInfo(nArenaType)
    UIHelper.SetRichText(self.LabelUpperLimit, string.format("<u>%d</u>", nPrestigeExtRemain))

    nLeftDoubleCount = nMaxDoubleCount - nLeftDoubleCount
    for i, img in ipairs(self.tbImgSchedule) do
        if nLeftDoubleCount > 0 then
            UIHelper.SetVisible(img, true)
        else
            UIHelper.SetVisible(img, false)
        end
        nLeftDoubleCount = nLeftDoubleCount - 1
    end

end

function UIArenaMainCityView:UpdateArenaInfo()
    local nPlayerID = self.dwPlayerID
    local nArenaType = self:GetCurArenaType()

    if not nArenaType or nArenaType >= ARENA_UI_TYPE.ARENA_END then
        return
    end

    local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
    local nTeamScore = ArenaData.GetCorpsLevel(nPlayerID, nArenaType)
    local nArenaLevel = ArenaData.GetArenaLevel(nPlayerID, nArenaType)

    local tbArenaLevelConfig = ArenaData.GetLevelInfo(nArenaLevel)
    local tbArenaNextLevelConfig = ArenaData.GetLevelInfo(nArenaLevel + 1) or tbArenaLevelConfig
	local szLevel = Conversion2ChineseNumber(nArenaLevel)

    local tbUIConfig = TabHelper.GetUIArenaRankLevelTab(nArenaLevel)
    if tbUIConfig then
        UIHelper.SetSpriteFrame(self.ImgGradeIcon, tbUIConfig.szBigIcon)
    end

    local nScore = tbArenaInfo.nMatchLevel or 1000
    UIHelper.SetString(self.LabelPersonageScore, nScore)
    if self.tbSeasonHighestRankScore and self.tbSeasonHighestRankScore[nArenaType] then
        UIHelper.SetString(self.LabelSeasonScore, self.tbSeasonHighestRankScore[nArenaType])
    else
        UIHelper.SetString(self.LabelSeasonScore, nScore)
    end
    UIHelper.SetString(self.LabelTeamScore, nTeamScore)

    local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
    local bEmpty = not nCorpsID or nCorpsID <= 0
    UIHelper.SetVisible(self.BtnWidgetGrade2, nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)
    UIHelper.SetVisible(self.BtnWidgetGrade3, not bEmpty and nArenaType ~= ARENA_UI_TYPE.ARENA_1V1)
    UIHelper.LayoutDoLayout(self.WidgetJJCScore)

    local nPrestigeRemainSpace = 0
    local player = GetPlayer(nPlayerID)
    if player then
        nPrestigeRemainSpace = player.GetPrestigeRemainSpace()
    end
    UIHelper.SetRichText(self.LabelWeiMingDianLimit, string.format("%d", nPrestigeRemainSpace))

    -- UIHelper.SetVisible(self.TogHelp3, nScore >= 2400)
    UIHelper.SetVisible(self.TogHelp3, false)
    UIHelper.SetVisible(self.WidgetMasterInfo1, nScore >= 2400 and nScore < 2500)
    UIHelper.SetVisible(self.WidgetMasterInfo2, nScore >= 2500)

    for i, img in ipairs(self.tbImgDoubleSchedule1) do
        if i <= (tbArenaInfo.dwWeekTotalCount or 0) then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double1.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double2.png")
        end
    end

    for i, img in ipairs(self.tbImgDoubleSchedule2) do
        if i <= (tbArenaInfo.dwWeekTotalCount or 0) then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double1.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double2.png")
        end
    end

    if not tbArenaLevelConfig then return end
    UIHelper.SetProgressBarPercent(self.ImgSliderExperience, math.min(100 - (tbArenaNextLevelConfig.score - nScore), 100))
    UIHelper.SetString(self.LabelExperience, string.format("%d/%d", nScore, tbArenaNextLevelConfig.score))
    UIHelper.SetString(self.LabelArenaGrade, string.format("%s%s%s%s", szLevel, g_tStrings.STR_DUAN, g_tStrings.STR_CONNECT, UIHelper.GBKToUTF8(tbArenaLevelConfig.title)))

end

function UIArenaMainCityView:UpdateDataInfo()
    local nPlayerID = self.dwPlayerID
    local nArenaType = self:GetCurArenaType()

    if not self.scriptCorpsInfoPage then
        self.scriptCorpsInfoPage = UIHelper.GetBindScript(self.WidgetAnchorRight)
    end

    self.scriptCorpsInfoPage:OnEnter(self.nCurSelectMode, self.dwPlayerID)
end

function UIArenaMainCityView:UpdateTeamInfo()
    local nArenaType = self:GetCurArenaType()
    if not self.scriptTeamPage then
        self.scriptTeamPage = UIHelper.GetBindScript(self.WidgetAnchorTeam)
    end

    self.scriptTeamPage:OnEnter(nArenaType, self.dwPlayerID)
end

function UIArenaMainCityView:UpdateNavigationInfo()
    local tNpcMap = Table_GetNpcTypeInfoMap()
    self.tNpcArr = {}

    for _, tNpc in pairs(tNpcMap) do
        for _, tNpc in pairs(tNpc.tNpcList) do
            if ArenaData.ArenaMatchNpcID[tNpc.dwNpcID] and tNpc.dwMapID ~= 13 then
                table.insert(self.tNpcArr, tNpc)
                tNpc.szNpcName = string.gsub(tNpc.szTypeName, UIHelper.UTF8ToGBK("名剑大会报名·"), "")
                tNpc.szNpcName = string.gsub(tNpc.szNpcName, UIHelper.UTF8ToGBK("名剑大会报名人·"), "")
                -- UIHelper.SetTouchDownHideTips(cell.BtnLeaveFor, false)
            end
        end
    end
    -- UIHelper.SetTouchDownHideTips(self.ScrollViewActivityDetail, false)
    -- UIHelper.ScrollViewDoLayout(self.ScrollViewActivityDetail)
    -- UIHelper.ScrollToTop(self.ScrollViewActivityDetail, 0)
    -- UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
end

function UIArenaMainCityView:UpdateCurrencyInfo()
    UIHelper.RemoveAllChildren(self.WidgetPVPMoney)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.Prestige)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.TitlePoint)

    UIHelper.LayoutDoLayout(self.WidgetPVPMoney)
end

function UIArenaMainCityView:UpdateSoloInfo()
    local nArenaType = self:GetCurArenaType()
    if nArenaType ~= ARENA_UI_TYPE.ARENA_1V1 then
        return
    end

    local nPlayerID = self.dwPlayerID
    local tSoloInfo = ArenaData.GetPlayerSoloInfo(nPlayerID)
    local fPercentage = tSoloInfo and tSoloInfo.fPercentage or 0
    local dwCurKungfuID = tSoloInfo and tSoloInfo.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
    local dwForceID = PlayerData.GetPlayerForceID()
    local nKungfuID = TabHelper.GetMobileKungfuID(dwCurKungfuID)
    local tSkillInfo = TabHelper.GetUISkill(nKungfuID)
    local szSkillName = tSkillInfo and tSkillInfo.szName or ""
    szSkillName = szSkillName:match("^(.-)%·悟$") or szSkillName

    UIHelper.SetSpriteFrame(self.ImgXinfa, PlayerKungfuImg[dwCurKungfuID] or "")
    UIHelper.SetString(self.LabelXinfaName, szSkillName)
    -- UIHelper.SetString(self.LabelScoreExplain1, string.format("%s出场率%d%%", szSkillName, fPercentage))

    UIHelper.LayoutDoLayout(self.LayoutXinfa)
end

function UIArenaMainCityView:GetCurArenaType()
    return ArenaData.tbCorpsList[self.nCurSelectMode]
end

return UIArenaMainCityView