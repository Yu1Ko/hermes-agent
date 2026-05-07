-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBahuangResultView
-- Date: 2024-01-25 19:00:40
-- Desc: ?
-- ---------------------------------------------------------------------------------
local LEAVE_TIME = 3 * 60 * 1000
local m_nWaringLeaveScore = 4000
local UIPanelBahuangResultView = class("UIPanelBahuangResultView")


function UIPanelBahuangResultView:OnEnter(tbFinalData, bLastData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbFinalData = tbFinalData
    self.bLastData = bLastData
    self.nStartTime = GetTickCount()
    if not self.bLastData then
        self:StartTimer()
    end
    self:UpdateInfo()
end

function UIPanelBahuangResultView:OnExit()
    self.bInit = false
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    self:UnRegEvent()
end

function UIPanelBahuangResultView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleGroup, EventType.OnToggleGroupSelectedChanged, function(toggle, nIndex)
        UIHelper.SetVisible(self.WidgetAnchorTogData, nIndex == 0)
        UIHelper.SetVisible(self.WidgetAnchorTogSkill, nIndex == 1)
    end)

    UIHelper.BindUIEvent(self.BtnEsc, EventType.OnClick, function()
        self:CheckLeaveWithOutAward(function()
            RemoteCallToServer("On_EightWastes_PlayerLeaveScene")
			UIMgr.Close(self)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnReStart, EventType.OnClick, function()
        self:CheckLeaveWithOutAward(function()
            RemoteCallToServer("On_EightWastes_AgainPlay", self.nCurrentLevel)
			UIMgr.Close(self)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnNextLevel, EventType.OnClick, function()
        self:CheckLeaveWithOutAward(function()
            RemoteCallToServer("On_EightWastes_AgainPlay", self.nCurrentLevel + 1)
			UIMgr.Close(self)
        end)
    end)
end

function UIPanelBahuangResultView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnStartEvent, function()
        UIMgr.Close(self)
    end)
end

function UIPanelBahuangResultView:UnRegEvent()
    
end

function UIPanelBahuangResultView:StartTimer()
    self:StopTimer()
    self.nTimer = Timer.AddFrameCycle(self, 1, function()
        self:OnUpdate()
    end)
end

function UIPanelBahuangResultView:StopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function UIPanelBahuangResultView:OnUpdate()
    self:UpdateLeaveTime()
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBahuangResultView:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogData)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogSkill)
    
    local tbFinalData = self.tbFinalData

    -- local szResImgPath = tbFinalData.bWin and "UIAtlas2_TestPlace_TestPlace_RewardImg_Txt_01" or ""
    -- UIHelper.SetSpriteFrame(self.ImgBg1, szResImgPath)
    -- UIHelper.SetSpriteFrame(self.ImgBgLight2, szResImgPath)

    UIHelper.SetVisible(self.ImgBg, tbFinalData.bWin)
    UIHelper.SetVisible(self.ImgBg1, tbFinalData.bWin)
    UIHelper.SetVisible(self.ImgBg1Defeat, not tbFinalData.bWin)
    UIHelper.SetVisible(self.ImgBgDefeat, not tbFinalData.bWin)

    --积分
    UIHelper.SetString(self.LabelProgressScore, FormatString(g_tStrings.STR_ADD_VALUE, tbFinalData.nPointAccrue or 0))
    UIHelper.SetString(self.LabelHistoryScore, tbFinalData.nPointTotal)
    UIHelper.SetVisible(self.WidgetProgressScore, not self.bLastData)

    UIHelper.SetVisible(self.BtnRank, not self.bLastData)
    UIHelper.SetVisible(self.BtnClose, true)
    UIHelper.SetVisible(self.LabelExpAdd, not self.bLastData)

    --击杀数
    UIHelper.SetString(self.LabelKillNum, tbFinalData.nKillNum)

    --经验、等级
    UIHelper.SetString(self.LabelExp, FormatString(g_tStrings.STR_ROUGELIKE_DATA_EXP, tbFinalData.nExp, tbFinalData.nMaxExp))
    UIHelper.SetString(self.LabelLevelNow, tbFinalData.nLevel.."/")
    UIHelper.SetString(self.LabelLevelMax, tbFinalData.nMaxLevel)
    UIHelper.SetString(self.LabelExpAdd, FormatString(g_tStrings.STR_ADD_VALUE, tbFinalData.nAddExp))
    UIHelper.SetProgressBarPercent(self.ProgressBar01, tbFinalData.nExp / tbFinalData.nMaxExp * 100)
    UIHelper.LayoutDoLayout(self.LayoutExp)


    local tbFinalInfoList = {
        {"击败首领", tbFinalData.nBossNum},
        {"武技修习", tbFinalData.nSkillNum},
        {"日晷识历", tbFinalData.nAltarNum},
        {"荒地之宝", tbFinalData.nSceneChest or 0},
        {"幻境魂灯", tbFinalData.nGainNum},
        {"微光存续", Timer.FormatInChinese4(tbFinalData.nPassTime)},
        {"助战次数", tbFinalData.tPlayerList[1][3] or 0},
        {"灯火值", tbFinalData.nReviveNum},
    }
    for nIndex, tbFinalInfo in ipairs(tbFinalInfoList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangResultData, self.LayoutBahuangResultData, tbFinalInfo[1], tbFinalInfo[2])
    end
    UIHelper.LayoutDoLayout(self.LayoutBahuangResultData)

    --玩家头像
    UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangPlayer, self.WidgetBahuangPlayer, tbFinalData.tPlayerList[1])

    local tbSkillList = self.bLastData and BahuangData.GetLastSkillList() or BahuangData.GetSkillList()
    for nIndex, WidgetBahuangBuffCell in ipairs(self.tbWidgetBahuangBuffCell) do--秘术
        if tbSkillList[4] and tbSkillList[4][nIndex] then
            UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangBuffCell, WidgetBahuangBuffCell, self.ToggleGroupBuffCell, tbSkillList[4][nIndex], false)
        else
            UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangBuffCell, WidgetBahuangBuffCell, self.ToggleGroupBuffCell, nil, false)
        end
    end

    for nIndex, WidgetBahuangSkillCell in ipairs(self.tbWidgetBahuangSkillCell) do--秘技
        if tbSkillList[2] and tbSkillList[2][nIndex] then
            UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, WidgetBahuangSkillCell, tbSkillList[2][nIndex], self.ToggleGroupBuffCell, nil, nIndex + 1)
        else
            UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, WidgetBahuangSkillCell, nil, self.ToggleGroupBuffCell, "", nIndex + 1)
        end
    end

    if tbSkillList[1] and tbSkillList[1][1] then--心决
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, self.WidgetBahuangSkillCellNormalAttack, tbSkillList[1][1], self.ToggleGroupBuffCell, nil, 1)
    else
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, self.WidgetBahuangSkillCellNormalAttack, nil, self.ToggleGroupBuffCell, "", 1)
    end

    if tbSkillList[3] and tbSkillList[3][1] then --绝学
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, self.WidgetBahuangSkillCellUltra, tbSkillList[3][1], self.ToggleGroupBuffCell, nil, 6)
    else
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, self.WidgetBahuangSkillCellUltra, nil, self.ToggleGroupBuffCell, "", 6)
    end

    UIHelper.LayoutDoLayout(self.LayoutBahuangBuff)
    UIHelper.LayoutDoLayout(self.LayoutBahuangSkill)

    UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangBuffCell, self.WidgetBahuangNormalZengyi, self.ToggleGroupBuffCell, nil, true)

    self:SetCurrentLevel(tbFinalData.nSceneLevel > 0 and tbFinalData.nSceneLevel or 1)

    UIHelper.SetVisible(self.LabelExitCountdown, not self.bLastData)
    UIHelper.SetVisible(self.BtnEsc, not self.bLastData)
    UIHelper.SetVisible(self.BtnReStart, not self.bLastData and tbFinalData.bLeader)

    local nMaxSceneLevel = BahuangData.GetMaxSceneLevel()
    UIHelper.SetVisible(self.BtnNextLevel, not self.bLastData and (self.nCurrentLevel < nMaxSceneLevel) and not TeamData.IsInParty())
    UIHelper.SetString(self.LabelTitleCount, g_tStrings.tRougeLikeLevel[self.nCurrentLevel])
    UIHelper.LayoutDoLayout(self.LayoutButton)

    self:UpdateLeaveTime()
    UIHelper.SetVisible(self.BtnRank, false)
end

function UIPanelBahuangResultView:UpdateSceneLevel()
    
end

 
function UIPanelBahuangResultView:UpdateLeaveTime()
    local nTime = GetTickCount() - self.nStartTime
	local nLeaveTime = math.max(LEAVE_TIME - nTime, 0)
	nLeaveTime =  math.floor(nLeaveTime/ 1000)
	local szText = FormatString(g_tStrings.STR_ROUGELIKE_LEAVE_TIME, nLeaveTime)
    UIHelper.SetString(self.LabelExitCountdown, szText)
end

function UIPanelBahuangResultView:CheckLeaveWithOutAward(fnAction)
    local tbFinalData = self.tbFinalData
    if tbFinalData.nKillNum >= m_nWaringLeaveScore and tbFinalData.nRewardState == 1 and tbFinalData.nSceneLevel == 2 then
        UIHelper.ShowConfirm(g_tStrings.STR_ROUGELIKE_LEAVE_AWARD_TIP, function()
            fnAction()
        end)
	else
		fnAction()
	end
end

function UIPanelBahuangResultView:SetCurrentLevel(nCurrentLevel)
    self.nCurrentLevel = nCurrentLevel
    self:UpdateSceneLevel()
end

return UIPanelBahuangResultView