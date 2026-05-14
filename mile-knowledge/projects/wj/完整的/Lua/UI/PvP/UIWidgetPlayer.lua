-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPlayer
-- Date: 2022-12-15 10:02:16
-- Desc: 战场结算界面，每个玩家项 WidgetPlayer
-- ---------------------------------------------------------------------------------

local UIWidgetPlayer = class("UIWidgetPlayer")

local MAX_EXCELLENT_COUNT = 6
local LABEL_CUSTOM_COUNT = 4
local ADD_SHOW_TIME = 1

local COLOR_BLUE = cc.c3b(174, 217, 224) --#aed9e0
local COLOR_RED = cc.c3b(255, 133, 125)
local COLOR_YELLOW = cc.c3b(240, 220, 130)
local COLOR_ORANGE = cc.c3b(255, 226, 110) --#ffe26e

local szCanPraiseIconPath = "UIAtlas2_Pvp_PvpList_Btn_Praise03.png"
local szPraisedIconPath = "UIAtlas2_Pvp_PvpList_Btn_Praise04.png"

function UIWidgetPlayer:OnEnter()

end

function UIWidgetPlayer:OnExit()

end

function UIWidgetPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPriaise, EventType.OnClick, function()
        if self.bPraised then
            return
        end

        local selfPlayer = GetClientPlayer()
        if not selfPlayer then return end

        local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
        if not tData then return end

        BattleFieldData.ReqPraise(tData.dwPlayerID) --返回Add_FriendPraiseShow
        self.bPraised = true
        self:UpdateBtnState()
    end)
    UIHelper.BindUIEvent(self.BtnMark, EventType.OnClick, function()
        if not UIHelper.GetVisible(self.LayoutTips) then
            self:UpdateTipsItem()
        end
    end)
    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
        if not tData then return end

        RemoteCallToServer("On_XinYu_Jubao", tData.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.WidgetHead, EventType.OnClick, function()
        local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
        if not tData then return end

        if self.m_uiView.WidgetPersonalCard1 then
            UIHelper.RemoveAllChildren(self.m_uiView.WidgetPersonalCard1)
            UIHelper.SetVisible(self.m_uiView.WidgetPersonalCard1, true)
            local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.m_uiView.WidgetPersonalCard1, tData.GlobalID)
            if tipsScriptView then
                tipsScriptView:OnEnter(tData.GlobalID)
                tipsScriptView:SetPlayerId(tData.dwPlayerID)
                local tInfo = {
                    szName = UIHelper.GBKToUTF8(tData.Name),
                    dwPlayerID = tData.dwPlayerID,
                    dwForceID = tData.ForceID,
                    szHeadIconPath = PlayerForceID2SchoolImg2[tData.ForceID],
                }
                tipsScriptView:SetPersonalInfo(tInfo)
            end
        end
    end)
end

function UIWidgetPlayer:RegEvent()
    Event.Reg(self, EventType.BF_WidgetPlayerUpdate, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.BF_WidgetPlayerReportSwitch, function(bReportFlag)
        self:UpdateBtnState()
        Timer.DelTimer(self, self.nReportTimerID)
        if bReportFlag then
            self.nReportTimerID = Timer.AddFrameCycle(self, 1, function()
                self:UpdateReportBtnState()
            end)
        end
    end)
    Event.Reg(self, EventType.BF_WidgetPlayerHideTips, function()
        UIHelper.SetVisible(self.LayoutTips, false)
    end)
    Event.Reg(self, EventType.BF_WidgetPlayerUpdatePraiseInfo, function()
        local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
        if not tData then return end

        self.bPraised = BattleFieldData.IsAddPraise(tData.dwPlayerID)
        self:UpdateBtnState()
    end)
end

function UIWidgetPlayer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--OnPoolAllocated/OnPoolRecycled 仅由PrefabPool调用
function UIWidgetPlayer:OnPoolAllocated(nIndex, uiView)
    if not self.bInit then
        --LOG.INFO("UIWidgetPlayer:OnPoolAllocated", nIndex, uiView)
        self.m_nIndex = nIndex
        self.m_uiView = uiView

        self.bPraised = false
        self.nAddShowTimerID = nil
        self.nNum = nil

        self:RegEvent()
        self:BindUIEvent()

        self.bInit = true
    end
end

function UIWidgetPlayer:OnPoolRecycled()
    --LOG.INFO("UIWidgetPlayer:OnPoolRecycled", self.m_nIndex)
    self.bInit = false
    self:UnRegEvent()

    self.m_uiView:RemoveTipsItem(self.LayoutTips)

    Timer.DelAllTimer(self)
end

function UIWidgetPlayer:InitImgTab()
    --ImgTab1 ~ ImgTab6
    local tChildren = UIHelper.GetChildren(self.BtnMark)
    for _, child in ipairs(tChildren) do
        local szName = child:getName()
        self[szName] = child
    end
    self.bInitImgTab = true
end

function UIWidgetPlayer:UpdateInfo()
    local selfPlayer = GetClientPlayer()
    if not selfPlayer then return end

    local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
    if not tData then return end

    local bBattleFieldEnd = self.m_uiView.bBattleFieldEnd
    local tExcellentData = self.m_uiView.tInfo.tExcellentData or {}

    --阵营图标
    local szForceIconPath = PlayerForceID2SchoolImg2[tData.ForceID]
    if tData.dwMountKungfuID and IsNoneSchoolKungfu(tData.dwMountKungfuID) then
        szForceIconPath = PlayerKungfuImg[tData.dwMountKungfuID]
    end
    UIHelper.SetSpriteFrame(self.ImgHead, szForceIconPath)

    UIHelper.SetString(self.LabelPlayerName,        GBKToUTF8(tData.Name), 7)                                           --1名字 限制最大六个字
    UIHelper.SetString(self.LabelAssistNum,         tostring(tData[PQ_STATISTICS_INDEX.KILL_COUNT] or 0))               --3协助击伤
    UIHelper.SetString(self.LabelBestAssistNum,     tostring(tData[PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] or 0))   --4最佳助攻
    UIHelper.SetString(self.LabelWoundNum,          tostring(tData[PQ_STATISTICS_INDEX.DECAPITATE_COUNT] or 0))         --5击伤
    UIHelper.SetString(self.Label1v1Num,            tostring(tData[PQ_STATISTICS_INDEX.SOLO_COUNT] or 0))               --6单挑
    UIHelper.SetString(self.LabelDamageNum,         self:NumberToTenThousand(tData[PQ_STATISTICS_INDEX.HARM_OUTPUT] or 0, 1))  --7伤害量
    UIHelper.SetString(self.LabelTreatNum,          self:NumberToTenThousand(tData[PQ_STATISTICS_INDEX.TREAT_OUTPUT] or 0, 1)) --8治疗量
    UIHelper.SetString(self.LabelInjuredNum,        self:NumberToTenThousand(tData[PQ_STATISTICS_INDEX.INJURY] or 0, 1))       --9受伤量
    UIHelper.SetString(self.LabelSevereInjuredNum,  tostring(tData[PQ_STATISTICS_INDEX.DEATH_COUNT] or 0))              --10受重伤

    --伤害量、治疗量、受伤量、受重伤随奖励一起显示
    --UIHelper.SetVisible(self.LabelPlayerName, UIHelper.GetVisible(self.m_uiView.Title1))
    UIHelper.SetVisible(self.LabelAssistNum,        UIHelper.GetVisible(self.m_uiView.Title3))
    UIHelper.SetVisible(self.LabelBestAssistNum,    UIHelper.GetVisible(self.m_uiView.Title4))
    UIHelper.SetVisible(self.LabelWoundNum,         UIHelper.GetVisible(self.m_uiView.Title5))
    UIHelper.SetVisible(self.Label1v1Num,           UIHelper.GetVisible(self.m_uiView.Title6))
    UIHelper.SetVisible(self.LabelDamageNum,        UIHelper.GetVisible(self.m_uiView.Title7))
    UIHelper.SetVisible(self.LabelTreatNum,         UIHelper.GetVisible(self.m_uiView.Title8))
    UIHelper.SetVisible(self.LabelInjuredNum,       UIHelper.GetVisible(self.m_uiView.Title9))
    UIHelper.SetVisible(self.LabelSevereInjuredNum, UIHelper.GetVisible(self.m_uiView.Title10))

    --tips
    UIHelper.SetVisible(self.LayoutTips, false)

    -- pq option
    for i = 1, LABEL_CUSTOM_COUNT do
        local bVisible = UIHelper.GetVisible(self.m_uiView["Title" .. (i + 10)])
        local nKey = self.m_uiView:GetItemKey(i + 10)
        local nData = tData[nKey]
        local label = self["LabelCustom" .. i]
        UIHelper.SetString(label, g_tStrings.STR_MUL .. nData)
        if bVisible then
            UIHelper.SetVisible(label, true)
        else
            UIHelper.SetVisible(label, false)
        end
    end

    --reward
    if UIHelper.GetVisible(self.m_uiView.Title15) then
        UIHelper.SetVisible(self.LayoutAward, true)

        --威名点加成倍率
        local nMultiRestige = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_8] or 0
        if nMultiRestige and nMultiRestige > 100 then
            UIHelper.SetVisible(self.LabelDouble1, true)
            UIHelper.SetVisible(self.LabelDouble2, true)
            UIHelper.SetString(self.LabelDouble1, (nMultiRestige - 100) .. "%")
            UIHelper.SetString(self.LabelDouble2, (nMultiRestige - 100) .. "%")
        else
            UIHelper.SetVisible(self.LabelDouble1, false)
            UIHelper.SetVisible(self.LabelDouble2, false)
        end

        if BattleFieldData.IsInFBBattleFieldMap() then
            --- 飞火论锋也使用这个结算界面，但是货币不一样，这里替换下图标
            UIHelper.SetSpriteFrame(self.ImgMoneyIcon1, CurrencyData.tbImageSmallIcon[CurrencyType.LeYouBi])
            UIHelper.SetSpriteFrame(self.ImgMoneyIcon2, CurrencyData.tbImageSmallIcon[CurrencyType.Reputation])
        end

        UIHelper.SetVisible(self.ImgMoneyIcon1, tData[PQ_STATISTICS_INDEX.AWARD_1] ~= 0)
        UIHelper.SetVisible(self.ImgMoneyIcon2, tData[PQ_STATISTICS_INDEX.AWARD_2] ~= 0)
        UIHelper.SetString(self.LabelNum1, tostring(tData[PQ_STATISTICS_INDEX.AWARD_1])) --威名点
        UIHelper.SetString(self.LabelNum2, tostring(tData[PQ_STATISTICS_INDEX.AWARD_2])) --战阶积分


        UIHelper.LayoutDoLayout(self.LayoutAward)
    else
        UIHelper.SetVisible(self.LayoutAward, false)
    end


    --Layout
    local tPosX = self.m_uiView.tTitlePosX
    local _, nPosY = UIHelper.GetWorldPosition(self.LabelPlayerName)
    UIHelper.SetWorldPosition(self.BtnPriaise,              tPosX[1] - 140, nPosY)
    UIHelper.SetWorldPosition(self.BtnReport,               tPosX[1] - 140, nPosY)
    UIHelper.SetWorldPosition(self.WidgetHead,              tPosX[1] - 78,  nPosY - 1)
    UIHelper.SetWorldPosition(self.LabelPlayerName,         tPosX[1] - 40,  nPosY)
    UIHelper.SetWorldPosition(self.ImgMvp,                  tPosX[2] - 30,  nPosY)
    UIHelper.SetWorldPosition(self.BtnMark,                 tPosX[2] + 20,  nPosY - 4)
    UIHelper.SetWorldPosition(self.LabelAssistNum,          tPosX[3],       nPosY)
    UIHelper.SetWorldPosition(self.LabelBestAssistNum,      tPosX[4],       nPosY)
    UIHelper.SetWorldPosition(self.LabelWoundNum,           tPosX[5],       nPosY)
    UIHelper.SetWorldPosition(self.Label1v1Num,             tPosX[6],       nPosY)
    UIHelper.SetWorldPosition(self.LabelDamageNum,          tPosX[7],       nPosY)
    UIHelper.SetWorldPosition(self.LabelTreatNum,           tPosX[8],       nPosY)
    UIHelper.SetWorldPosition(self.LabelInjuredNum,         tPosX[9],       nPosY)
    UIHelper.SetWorldPosition(self.LabelSevereInjuredNum,   tPosX[10],      nPosY)
    for i = 1, LABEL_CUSTOM_COUNT do
        UIHelper.SetWorldPosition(self["LabelCustom" .. i], tPosX[10 + i],  nPosY)
    end
    UIHelper.SetWorldPosition(self.LayoutAward,   tPosX[10 + LABEL_CUSTOM_COUNT + 1],      nPosY)

    local player = GetClientPlayer()
    if not player then return end

    --字体颜色
    local bSelf = tData.dwPlayerID == player.dwID
    local color = bSelf and COLOR_ORANGE or COLOR_BLUE

    UIHelper.SetVisible(self.ImgPlayerBuleBg, tData.nBattleFieldSide == 1)
    UIHelper.SetVisible(self.ImgPlayerRedBg, tData.nBattleFieldSide == 2)
    -- UIHelper.SetVisible(self.ImgPlayerBuleBg1, bSelf)
    -- UIHelper.SetVisible(self.ImgPlayerRedBg1, bSelf)
    UIHelper.SetVisible(self.ImgSelf1, bSelf)

    UIHelper.SetColor(self.LabelPlayerName,         color)
    UIHelper.SetColor(self.LabelAssistNum,          color)
    UIHelper.SetColor(self.LabelBestAssistNum,      color)
    UIHelper.SetColor(self.LabelWoundNum,           color)
    UIHelper.SetColor(self.Label1v1Num,             color)
    UIHelper.SetColor(self.LabelDamageNum,          color)
    UIHelper.SetColor(self.LabelTreatNum,           color)
    UIHelper.SetColor(self.LabelInjuredNum,         color)
    UIHelper.SetColor(self.LabelSevereInjuredNum,   color)
    for i = 1, LABEL_CUSTOM_COUNT do
        UIHelper.SetColor(self["LabelCustom" .. i], color)
    end
    UIHelper.SetColor(self.LabelNum1,               color)
    UIHelper.SetColor(self.LabelNum2,               color)
    UIHelper.SetColor(self.LabelDouble1,            COLOR_YELLOW)
    UIHelper.SetColor(self.LabelDouble2,            COLOR_YELLOW)

    --结算
    UIHelper.SetVisible(self.ImgMvp, false)
    UIHelper.SetVisible(self.LabelNum, false)
    UIHelper.SetVisible(self.BtnMark, bBattleFieldEnd)

    self.bPraised = false
    self.bShowPraise = false

    if not self.bInitImgTab then
        self:InitImgTab()
    end

    self.bHasExcellent = false
    if bBattleFieldEnd then
        --点赞相关
        if BattleFieldData.CanAddPraise(tData.dwPlayerID) then
            self.bShowPraise = true
            if BattleFieldData.IsAddPraise(tData.dwPlayerID) then
                self.bPraised = true
            end
        end

        --优秀表现和MVP
        local tExcellent = tExcellentData[tData.dwPlayerID] or {}
        local bMVP = false
        local nTabIndex = 1
        for i = 1, MAX_EXCELLENT_COUNT do
            local iconTab = self["ImgTab" .. i]
            UIHelper.SetVisible(iconTab, false)
        end
        for i = 1, MAX_EXCELLENT_COUNT do
            local dwID = tExcellent[i]
            local tLine = dwID and g_tTable.BFArenaExcellent:Search(dwID)
            local iconTab = self["ImgTab" .. nTabIndex]
            if tLine then
                if dwID == EXCELLENT_ID.BEST_COURSE then
                    bMVP = true
                else
                    --设置优秀表现图标
                    UIHelper.SetVisible(iconTab, true)
                    UIHelper.SetSpriteFrame(iconTab, tLine.szMobileImagePath)
                    nTabIndex = nTabIndex + 1
                end
            end
        end
        UIHelper.SetVisible(self.ImgMvp, bMVP)
    end

    self:UpdateBtnState()
end

function UIWidgetPlayer:UpdateTipsItem()
    local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
    if not tData then return end

    local tExcellentData = self.m_uiView.tInfo.tExcellentData or {}
    local tExcellent = tExcellentData[tData.dwPlayerID] or {}

    local bHasExcellent = false
    self.m_uiView:RemoveTipsItem(self.LayoutTips)
    for i = 1, MAX_EXCELLENT_COUNT do
        local dwID = tExcellent[i]
        local tLine = dwID and g_tTable.BFArenaExcellent:Search(dwID)
        if tLine then
            --Tips
            self.m_uiView:CreateTipsItem(self.LayoutTips, tLine.szMobileImagePath, UIHelper.GBKToUTF8(tLine.szName))
            bHasExcellent = true
        end
    end

    if bHasExcellent then
        UIHelper.LayoutDoLayout(self.LayoutTips)
        UIHelper.SetVisible(self.LayoutTips, true)
        self.m_uiView:SetWidgetPlayerTipsShowState()
    end
end

function UIWidgetPlayer:UpdateBtnState()
    local bReportFlag = self.m_uiView.bReportFlag
    UIHelper.SetVisible(self.BtnPriaise, not bReportFlag and self.bShowPraise)
    UIHelper.SetSpriteFrame(self.ImgPraise, self.bPraised and szPraisedIconPath or szCanPraiseIconPath)

    local selfPlayer = GetClientPlayer()
    if not selfPlayer then return end

    local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
    if not tData then return end

    local nClientPlayerSide = self.m_uiView.tInfo.nClientPlayerSide

    --除自身的队友显示举报按钮
    UIHelper.SetVisible(self.BtnReport, bReportFlag and selfPlayer.dwID ~= tData.dwPlayerID and nClientPlayerSide == tData.nBattleFieldSide)

    self:UpdateReportBtnState()
end

function UIWidgetPlayer:UpdateReportBtnState()
    local tData = self.m_uiView:GetViewStatisticsData(self.m_nIndex)
    if not tData then return end

    local bCanReport = BattleFieldData.IsCanReportPlayer(tData.Name)
    UIHelper.SetButtonState(self.BtnReport, bCanReport and BTN_STATE.Normal or BTN_STATE.Disable, "目标侠士已退出，无法举报")
end

function UIWidgetPlayer:NumberToTenThousand(szContent, nDecimal)
    local numVal = tonumber(szContent)
    local strVal = tostring(szContent)
    local szResult = strVal
    if numVal then
        if not IsNumber(nDecimal) or nDecimal < 0 then
            nDecimal = 0
        end
        nDecimal = math.floor(nDecimal)

        local nFloor = math.floor(numVal)
        local len = string.len(nFloor)
        -- if len > 8 then
        --     local szTemp = string.sub(strVal, 1, len - 8 + nDecimal)
        --     if nDecimal > 0 then
        --         local nTempLen = string.len(szTemp)
        --         szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
        --     end
        --     szResult = szTemp .. "亿"
        -- elseif len > 4 then
        if len > 4 then
            local szTemp = string.sub(strVal, 1, len - 4 + nDecimal)
            if nDecimal > 0 then
                local nTempLen = string.len(szTemp)
                szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
            end
            szResult = szTemp .. "万"
        else
            -- return string.format("%.1f", numVal)
            return string.format("%.0f", numVal)
        end
    end

    return szResult
end

return UIWidgetPlayer