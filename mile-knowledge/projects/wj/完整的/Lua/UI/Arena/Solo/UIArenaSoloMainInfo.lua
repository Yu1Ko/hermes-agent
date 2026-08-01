-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaSoloMainInfo
-- Date: 2025-03-11 16:32:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaSoloMainInfo = class("UIArenaSoloMainInfo")

function UIArenaSoloMainInfo:OnEnter(nPlayerID, nArenaType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerID = nPlayerID
    self.nArenaType = nArenaType
    self:UpdateInfo()
end

function UIArenaSoloMainInfo:OnExit()
    self.bInit = false
end

function UIArenaSoloMainInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelpRule, EventType.OnClick, function(btn)
        local nPlayerID = self.nPlayerID
        local nArenaType = self.nArenaType
        local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
        local nScore = tbArenaInfo.nMatchLevel or 1000
        local nPrestigeExtRemain = ArenaData.GetPrestigeExtRemain(nArenaType, nScore)

        UIMgr.Open(VIEW_ID.PanelPvPArenaIntegralPop, nPrestigeExtRemain)
    end)

    UIHelper.BindUIEvent(self.BtnXinFaHelp, EventType.OnClick, function(btn)
        local tSoloInfo = ArenaData.GetPlayerSoloInfo()
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

    UIHelper.BindUIEvent(self.BtnQixueHelp, EventType.OnClick, function(btn)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip)
        UIHelper.SetVisible(self.WidgetQixueHelpTip1, not UIHelper.GetVisible(self.WidgetQixueHelpTip1))
    end)
    UIHelper.SetTouchDownHideTips(self.BtnQixueHelp, false)
end

function UIArenaSoloMainInfo:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetQixueHelpTip, false)
        UIHelper.SetVisible(self.WidgetQixueHelpTip1, false)

        if self.tbWinRewardItem then
            for _, cell in ipairs(self.tbWinRewardItem) do
                cell:SetSelected(false)
            end
        end

        if self.scriptWinRewardItemTip then
            self.scriptWinRewardItemTip:OnInitWithTabID()
        end
    end)

    Event.Reg(self, "REMOTE_MASTER2V2_JJC1V1_EVENT", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.tbWinRewardItem then
            for _, cell in ipairs(self.tbWinRewardItem) do
                cell:SetSelected(false)
            end
        end

        if self.scriptWinRewardItemTip then
            self.scriptWinRewardItemTip:OnInitWithTabID()
        end
    end)
end

function UIArenaSoloMainInfo:UpdateInfo()
    local nPlayerID = self.nPlayerID
    local nArenaType = self.nArenaType
    local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
    local nScore = tbArenaInfo.nMatchLevel or 1000

    local _, _, nPrestigeRemainSpace = CurrencyData.GetCurCurrencyLimit(CurrencyType.Prestige)

    UIHelper.SetString(self.LabelSeasonScore, nScore)
    UIHelper.SetString(self.LabelWeiMingDianLimit, string.format("%d", nPrestigeRemainSpace))
    UIHelper.LayoutDoLayout(self.LayoutWeiMingLimit)


    local tSoloInfo = ArenaData.GetPlayerSoloInfo()
    local fPercentage = tSoloInfo and tSoloInfo.fPercentage or 0
    local dwCurKungfuID = tSoloInfo and tSoloInfo.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
    local dwForceID = PlayerData.GetPlayerForceID()
    local nKungfuID = TabHelper.GetMobileKungfuID(dwCurKungfuID)
    local tSkillInfo = TabHelper.GetUISkill(nKungfuID)
    local szSkillName = tSkillInfo and tSkillInfo.szName or ""
    szSkillName = szSkillName:match("^(.-)%·悟$") or szSkillName

    local nLeftDoubleCount, nMaxDoubleCount = ArenaData.GetDoubleRewardInfo(nArenaType)
    UIHelper.SetVisible(self.WidgetWinRewardFinished, nMaxDoubleCount == nLeftDoubleCount)

    UIHelper.SetSpriteFrame(self.ImgSoloKingSchool, PlayerSchoolArenaSoloImg[dwForceID] or "")
    UIHelper.SetSpriteFrame(self.ImgXinfa, PlayerKungfuImg[dwCurKungfuID] or "")
    UIHelper.SetString(self.LabelNum, szSkillName)
    UIHelper.SetString(self.LabelScoreExplain1, string.format("%s出场率%d%%", szSkillName, fPercentage))

    UIHelper.LayoutDoLayout(self.LayoutXinfa)

    self:UpdateBuff()
    self:UpdateWinRewardInfo()
    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule, nLeftDoubleCount)
end

function UIArenaSoloMainInfo:UpdateWeekTotalInfo(tbImg, nTotalCount)
    for i, img in ipairs(tbImg) do
        if i <= #tbImg - (nTotalCount or 0) then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double1.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double2.png")
        end
    end
end


function UIArenaSoloMainInfo:UpdateWinRewardInfo()
    local tbRewardItems = GDAPI_JJC5WinItem() --dwTabType, dwIndex, nCount

    UIHelper.HideAllChildren(self.WidgetWinRewardFinished)
    if not tbRewardItems then
        return
    end

    self.tbWinRewardItem = self.tbWinRewardItem or {}
    for i, tbItemInfo in ipairs(tbRewardItems) do
        if not self.tbWinRewardItem[i] then
            self.tbWinRewardItem[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutWinReward)
            UIHelper.SetAnchorPoint(self.tbWinRewardItem[i]._rootNode, 0, 0)
        end

        self.tbWinRewardItem[i]:OnInitWithTabID(tbItemInfo[1], tbItemInfo[2])
        self.tbWinRewardItem[i]:SetClickNotSelected(true)
        self.tbWinRewardItem[i]:SetClickCallback(function(nTabType, nTabID)
            if not self.scriptWinRewardItemTip then
                self.scriptWinRewardItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip2)
            end
            self.scriptWinRewardItemTip:OnInitWithTabID(nTabType, nTabID)
            local tbBtnInfo = {}
            local nBoxID = TreasureBoxData.GetBoxIDByTab(nTabType, nTabID)
            if nBoxID then
                local tBoxInfo = Tabel_GetTreasureBoxListByID(nBoxID)
                if tBoxInfo and tBoxInfo.nGroupID and tBoxInfo.nGroupID == 1 then
                    table.insert(tbBtnInfo, {
                        szName = "查看奖励",
                        OnClick = function ()
                            UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, nBoxID)
                        end
                    })
                end
            end
            self.scriptWinRewardItemTip:SetBtnState(tbBtnInfo)
        end)
        self.tbWinRewardItem[i]:SetLabelCount(tbItemInfo[3])

        UIHelper.SetVisible(self.tbWidgetWinRewardFinished[i], true)
    end

    UIHelper.LayoutDoLayout(self.LayoutWinReward)
end

function UIArenaSoloMainInfo:UpdateBuff()
	local tSoloInfo = ArenaData.GetPlayerSoloInfo()
    local dwKungfuID = tSoloInfo and tSoloInfo.dwKungfuID or PlayerData.GetPlayerMountKungfuID()

    local tDynamic, tDisable = Table_GetArenaSkillAdjust(dwKungfuID)

    for i, tBuff in ipairs(tDynamic) do
        local script = UIHelper.GetBindScript(self.tbScriptBuff[i])
        if script then
            UIHelper.BindUIEvent(script.BtnBuff, EventType.OnClick, function()
                local tbBuffList = {}
                for index, tbBuffInfo in ipairs(tDynamic) do
                    local tbInfo = {}
                    tbInfo.dwID = tbBuffInfo[1]
                    tbInfo.nLevel = tbBuffInfo[2]
                    tbInfo.nStackNum = 1
                    tbInfo.bShowTime = false
                    table.insert(tbBuffList, tbInfo)
                end

                local nX = UIHelper.GetWorldPositionX(script.BtnBuff)
                local nY = UIHelper.GetWorldPositionY(script.BtnBuff)
                if #tbBuffList > 0 then
                    local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
                    script:UpdatePlayerInfo(g_pClientPlayer.dwID, tbBuffList)
                end
            end)
            script:UpdateArenaBuffImage(tBuff[1], tBuff[2], PlayerData.GetClientPlayer())
        end
    end

    UIHelper.SetVisible(self.WidgetSoloKingQixue, #tDynamic > 0)

end

return UIArenaSoloMainInfo