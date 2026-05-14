-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPvPCampMoraleView
-- Date: 2023-03-01 19:13:53
-- Desc: PanelPvPCampMorale
-- ---------------------------------------------------------------------------------

local UIPvPCampMoraleView = class("UIPvPCampMoraleView")

function UIPvPCampMoraleView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()
    self:InitTraceNpcInfo()
    self:UpdateInfo()
    RemoteCallToServer("On_Camp_GetCampReverseInfo")
end

function UIPvPCampMoraleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPvPCampMoraleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnAwardTips1, EventType.OnClick, function()
        self:SetTraceAndOpenMap(self.tbPersonNpcTraceData)
    end)
    UIHelper.BindUIEvent(self.BtnAwardTips2, EventType.OnClick, function()
        self:SetTraceAndOpenMap(self.tbTongNpcTraceData)
    end)
end

function UIPvPCampMoraleView:RegEvent()
    Event.Reg(self, "ON_CAMP_GETCAMPREVERSEINFO", function(nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
        print("[Camp] ON_CAMP_GETCAMPREVERSEINFO", nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
        self:OnGetCampReverseInfo(nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
    end)
end

function UIPvPCampMoraleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPvPCampMoraleView:InitUI()
    UIHelper.SetVisible(self.LabelChange1, false)
    UIHelper.SetVisible(self.LabelChange2, false)
end

function UIPvPCampMoraleView:UpdateInfo()
    local nGoodCampScore, nEvilCampScore, fPercentage = CampData.GetMoraleInfo()
    local _, nCurrentKillBossCountGood, nAwardPrestigeGrowthRateGood = self:GetCampInfo(CAMP.GOOD)
    local _, nCurrentKillBossCountEvil, nAwardPrestigeGrowthRateEvil = self:GetCampInfo(CAMP.EVIL)

    --士气条
    UIHelper.SetProgressBarPercent(self.ProgressBarGradeProgress, 100 * fPercentage)

    local nLeft, nRight = -127, 127
    local nPosX = nLeft + (nRight - nLeft) * fPercentage
    UIHelper.SetPositionX(self.ImgBarBg02, nPosX)

    UIHelper.SetString(self.LabelHqMoraleNum, tostring(nGoodCampScore))
    UIHelper.SetString(self.LabelHqMoraleBoss, tostring(nCurrentKillBossCountGood))
    UIHelper.SetString(self.LabelHqMoraleSpeed, nAwardPrestigeGrowthRateGood .. "%")
    UIHelper.SetString(self.LabelErMoraleNum, tostring(nEvilCampScore))
    UIHelper.SetString(self.LabelErMoraleBoss, tostring(nCurrentKillBossCountEvil))
    UIHelper.SetString(self.LabelErMoraleSpeed, nAwardPrestigeGrowthRateEvil .. "%")

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCampMorale, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCampMorale)
    UIHelper.ScrollToTop(self.ScrollViewCampMorale, 0)
end

function UIPvPCampMoraleView:InitTraceNpcInfo()
    self.tbPersonNpcTraceData = {}
    self.tbTongNpcTraceData = {}
    local nPersonNpcID = 7820
    local nTongNpcID = 1349
    local nMapID = 6 --固定扬州
    local tNpcMap = Table_GetNpcTypeInfoMap()

    local function GetNpcData(tLine)
        return {
            szName = UIHelper.GBKToUTF8(tLine.szTypeName),
            nMapID = tLine.dwMapID,
            tbPoint = tLine.tPoint
        }
    end

    for _, tNpc in pairs(tNpcMap) do
        if tNpc.dwMapID == nMapID then
            for _, v in pairs(tNpc.tNpcList) do
                if v.dwNpcID == nPersonNpcID then
                    self.tbPersonNpcTraceData = GetNpcData(v)
                elseif v.dwNpcID == nTongNpcID then
                    self.tbTongNpcTraceData = GetNpcData(v)
                end
            end
        end
    end
end

function UIPvPCampMoraleView:SetTraceAndOpenMap(tbNpcData)
    MapMgr.SetTracePoint(tbNpcData.szName, tbNpcData.nMapID, tbNpcData.tbPoint)
    UIMgr.Open(VIEW_ID.PanelMiddleMap, tbNpcData.nMapID, 0)

    UIMgr.HideView(self._nViewID)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelMiddleMap then
            UIMgr.ShowView(self._nViewID)
            Event.UnReg(self, EventType.OnViewClose)
        end
    end)
end

--nPersonalReverseRet/nTongReverseRet: 0 恶人浩气持平，都不能转; 1 浩气可以转恶人; 2 恶人可以转浩气
function UIPvPCampMoraleView:OnGetCampReverseInfo(nPersonalReverseRet, nTongReverseRet, tCanJoinCamp)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    -- "可\n"、"不可\n"
    local szCan = g_tStrings.STR_CAN .. "\n"
    local szCanNot = g_tStrings.STR_CAN_NOT .. "\n"

    -- self.szJoinCamp = ""
    -- if tCanJoinCamp then
    --     local szJoinGood = szCan
    --     local szJoinEvil = szCan
    --     if not tCanJoinCamp[CAMP.GOOD] then
    --         szJoinGood = szCanNot
    --     end

    --     if not tCanJoinCamp[CAMP.EVIL] then
    --         szJoinEvil = szCanNot
    --     end
    --     --local szJoinCamp = FormatLinkString(g_tStrings.STR_JOIN_CAMP_TIP, "font=" .. FONT_TEXT, GetFormatText(szJoinEvil, FONT_TITLE), GetFormatText(szJoinGood, FONT_TITLE))
    --     local szJoinCamp = string.format("个人加入恶人谷：%s个人加入浩气盟：%s", szJoinEvil, szJoinGood)
    --     self.szJoinCamp = g_tStrings.STR_JOIN_CAMP_TIP_TITLE .. szJoinCamp
    -- end
    -- -- szJoinCamp: "中立玩家加入阵营动态信息：\n个人加入恶人谷：可/不可\n个人加入浩气盟：可/不可\n"
    
    --self.szReverseCamp = ""
    
    local szReverse = ""
    if hPlayer.nCamp == CAMP.GOOD then
        szReverse = g_tStrings.TIP_CAMP_EVIL
    elseif hPlayer.nCamp == CAMP.EVIL then
        szReverse = g_tStrings.TIP_CAMP_GOOD
    end
    
    local sztip = FormatString(g_tStrings.STR_CAMP_PERSON_REVERSE_CAMP, szReverse)
    local szState = ""
    if hPlayer.nCamp == CAMP.GOOD then
        if nPersonalReverseRet == 1 then
            szState = szCan
        elseif nPersonalReverseRet == 0 or nPersonalReverseRet == 2 then
            szState = szCanNot
        end
        --self.szReverseCamp = sztip .. szState
    elseif hPlayer.nCamp == CAMP.EVIL then
        if nPersonalReverseRet == 0 or nPersonalReverseRet == 1 then
            szState = szCanNot
        elseif nPersonalReverseRet == 2 then
            szState = szCan
        end
        --self.szReverseCamp = sztip .. szState
    end
    -- szReverseCamp: "个人转阵营至XX：可/不可\n"
    if szState ~= "" then
        UIHelper.SetVisible(self.LabelChange1, true)
        UIHelper.SetString(self.LabelExplain1_1, sztip)
        UIHelper.SetString(self.LabelExplain1_2, szState)
    else
        UIHelper.SetVisible(self.LabelChange1, false)
    end

    if not hPlayer.dwTongID or hPlayer.dwTongID == 0 then
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCampMorale, true, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewCampMorale)
        UIHelper.ScrollToTop(self.ScrollViewCampMorale, 0)
        return
    end
    
    local hGuild = GetTongClient()
    sztip = FormatString(g_tStrings.STR_CAMP_TONG_REVERSE_CAMP, szReverse)
    szState = ""
    if hGuild.nCamp == CAMP.GOOD then
        if nTongReverseRet == 1 then
            szState = szCan
        elseif nTongReverseRet == 0 or nTongReverseRet == 2 then
            szState = szCanNot
        end
        --self.szReverseCamp = self.szReverseCamp .. sztip .. szState
    elseif hGuild.nCamp == CAMP.EVIL then
        if nTongReverseRet == 0 or nTongReverseRet == 1 then
            szState = szCanNot
        elseif nTongReverseRet == 2 then
            szState = szCan
        end
        --self.szReverseCamp = self.szReverseCamp .. sztip .. szState
    end
    -- szReverseCamp: "个人转阵营至XX：可/不可\n帮会转阵营至XX：可/不可\n"
    if szState ~= "" then
        UIHelper.SetVisible(self.LabelChange2, true)
        UIHelper.SetString(self.LabelExplain2_1, sztip)
        UIHelper.SetString(self.LabelExplain2_2, szState)
    else
        UIHelper.SetVisible(self.LabelChange2, false)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCampMorale, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCampMorale)
    UIHelper.ScrollToTop(self.ScrollViewCampMorale, 0)
end

function UIPvPCampMoraleView:GetCampInfo(nCamp)
    local hCampInfo = GetCampInfo()
    
    --local szText = g_tStrings.STR_CAMP_TITLE[nCamp] .. "\n"
    local nScore = 0
    local nCurrentKillBossCount = 0
    --local nLastKillBossCount = 0
    local nAwardPrestigeGrowthRate = 0
    
    nScore = hCampInfo.GetNewCampFightValue(NEW_CAMP_FIGHT_VALUE_TYPE.CAMP_SCORE, nCamp)
    nCurrentKillBossCount = hCampInfo.GetNewCampFightValue(NEW_CAMP_FIGHT_VALUE_TYPE.CURRENT_KILL_BOSS_COUNT, nCamp)
    nAwardPrestigeGrowthRate = hCampInfo.GetNewCampFightValue(NEW_CAMP_FIGHT_VALUE_TYPE.LAST_ADD_PRESTIGE_SPEED, nCamp)
        
    local nCurrentTime = GetCurrentTime()
    local tData = TimeToDate(nCurrentTime)
    if tData.weekday == 6 or tData.weekday == 0 then
        nAwardPrestigeGrowthRate = 0
    end
    
    -- szText = szText .. g_tStrings.STR_CAMP_SCORE --士气值：
    -- szText = szText .. nScore .. "\n"
    -- szText = szText .. g_tStrings.STR_CAMP_KILL_BOSS_COUNT .. nCurrentKillBossCount .. "\n"
    -- szText = szText .. g_tStrings.STR_CAMP_AWARD_PRESTIGE_ADD .. nAwardPrestigeGrowthRate .."%"
    return nScore, nCurrentKillBossCount, nAwardPrestigeGrowthRate
end


return UIPvPCampMoraleView