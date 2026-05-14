-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementMainView
-- Date: 2023-02-10 11:02:51
-- Desc: 成就概况（首页）
-- Prefab: PanelAchievementMian
-- ---------------------------------------------------------------------------------

local UIAchievementMainView = class("UIAchievementMainView")

local l_fAchievementRank    = 0
local l_bAchieveRankInited  = false

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementMainView:_LuaBindList()
    self.LabelAchievementPoint     = self.LabelAchievementPoint --- 资历（成就点数）
    self.LabelNextPointAwardTips   = self.LabelNextPointAwardTips --- 下一阶段资历奖励所需资历的提示
    self.LabelAchievementProgress  = self.LabelAchievementProgress --- 成就进度
    self.LabelTopRecordProgress    = self.LabelTopRecordProgress --- 五甲进度
    self.LabelRewardProgress       = self.LabelRewardProgress --- 奖励收集进度

    self.BtnClose                  = self.BtnClose --- 关闭界面
    self.BtnAchievementAward       = self.BtnAchievementAward --- 打开界面 - 资历奖励
    self.BtnAchievement            = self.BtnAchievement --- 打开界面 - 成就
    self.BtnTopRecord              = self.BtnTopRecord --- 打开界面 - 五甲
    self.BtnDocumentInfo           = self.BtnDocumentInfo --- 打开界面 - 隐元秘档
    self.BtnReward                 = self.BtnReward --- 打开界面 - 奖励收集

    self.LabelRankProgress         = self.LabelRankProgress --- 已超过多少玩家
    self.LabelAchievementLevelName = self.LabelAchievementLevelName --- 资历阶段名称
    self.ImgAchievementLevel       = self.ImgAchievementLevel --- 资历阶段图标

    self.LabelProgressCount        = self.LabelProgressCount --- 成就进度数目
end

function UIAchievementMainView:OnEnter(dwPlayerId)
    self.dwPlayerID = dwPlayerId
    self.hPlayer    = GetClientPlayer()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        --AchievementData.InitAllGift()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    if self.dwPlayerID then
        self.hPlayer = GetPlayer(self.dwPlayerID)
    else
        self:UpdateInfo()
    end

    self:UpdateSelfRankInfo()
    local bRemote = CheckPlayerIsRemote()
    if not l_bAchieveRankInited and not bRemote then
        RemoteCallToServer("On_Rank_GetAchievementRank")
    end
end

function UIAchievementMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.Close(VIEW_ID.PanelUID)
end

function UIAchievementMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAchievementAward, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelAchievementAward, self:GetPointAwardList(), self.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.BtnAchievement, EventType.OnClick, function()
        ---@see UIAchievementListView#OnEnter
        UIMgr.Open(VIEW_ID.PanelAchievementList, self.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.BtnTopRecord, EventType.OnClick, function()
        ---@see UIAchievementCategoryDetailView#OnEnter
        local bOpenFromAchievementSystem = true
        UIMgr.Open(VIEW_ID.PanelAchievementContent, ACHIEVEMENT_PANEL_TYPE.TOP_RECORD, ACHIEVEMENT_CATEGORY_TYPE.SHOW_ALL, nil, nil, self.dwPlayerID, bOpenFromAchievementSystem)
    end)

    UIHelper.BindUIEvent(self.BtnDocumentInfo, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelAchievementReport)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        --AchievementData.ResetSearchAndFilter()
        UIMgr.Open(VIEW_ID.PanelAwardGather, self.dwPlayerID)
    end)
end

function UIAchievementMainView:RegEvent()
    Event.Reg(self, "SYNC_ACHIEVEMENT_DATA", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_ACHIEVEMENT_RANK", function(fRank)
        l_fAchievementRank = fRank
        self:UpdateSelfRankInfo()

        if not l_bAchieveRankInited then
            l_bAchieveRankInited = true
        end
    end)
end

function UIAchievementMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementMainView:UpdateInfo()
    local nAllFinishPoint = self.hPlayer.GetAchievementRecord()
    local nNextStagePoint = AchievementData.GetNextStagePoint(nAllFinishPoint)
    local tCurrentStage   = AchievementData.GetCurrentStagePointAward(nAllFinishPoint)

    UIHelper.SetString(self.LabelAchievementPoint, nAllFinishPoint)
    if nNextStagePoint then
        UIHelper.SetString(self.LabelNextPointAwardTips, string.format("下阶段需资历达到%d", nNextStagePoint))
    else
        UIHelper.SetString(self.LabelNextPointAwardTips, "已达最高资历阶段")
    end
    if tCurrentStage then
        local szImgAward = string.format("UIAtlas2_Achievement_AchievementAward_icon_%d", tCurrentStage.nFrame)

        UIHelper.SetString(self.LabelAchievementLevelName, UIHelper.GBKToUTF8(tCurrentStage.szName))
        UIHelper.SetSpriteFrame(self.ImgAchievementLevel, szImgAward)
    end

    self:UpdateAchievementAndTopRecordProgress()
    self:UpdateRewardProgress()
end

function UIAchievementMainView:UpdateAchievementAndTopRecordProgress()
    local nCountA, nFinishA     = AchievementData.GetALLCount(1, self.dwPlayerID)
    local nCountTR, nFinishTR   = AchievementData.GetALLCount(2, self.dwPlayerID)
    local nAllCount, nAllFinish = nCountA + nCountTR, nFinishA + nFinishTR

    local nAchievementPercent   = math.floor(nAllFinish / nAllCount * 100)
    local nTopRecordPercent     = math.floor(nFinishTR / nCountTR * 100)

    UIHelper.SetString(self.LabelAchievementProgress, nAchievementPercent .. "%")
    UIHelper.SetString(self.LabelTopRecordProgress, nTopRecordPercent .. "%")

    UIHelper.SetString(self.LabelProgressCount, string.format("%d/%d", nAllFinish, nAllCount))
end

function UIAchievementMainView:UpdateRewardProgress()
    --local hPlayer         = GetClientPlayer()
    local tHaveGift       = {}

    local tSearchGiftList = AchievementData.tGiftList
    for k, v in pairs(tSearchGiftList) do
        local bFinish = self.hPlayer.IsAchievementAcquired(v.dwAchievement)
        if bFinish then
            table.insert(tHaveGift, v)
        end
    end

    local nHaveCount     = #tHaveGift
    local nRewardPercent = math.floor(nHaveCount / #AchievementData.tGiftList * 100)

    UIHelper.SetString(self.LabelRewardProgress, nRewardPercent .. "%")
end

function UIAchievementMainView:GetPointAwardList()
    if #AchievementData.tPointAward <= 0 then
        AchievementData.ReadPointAward()
    end

    return AchievementData.tPointAward
end

function UIAchievementMainView:UpdateSelfRankInfo()
    local bRemote = CheckPlayerIsRemote()
    local szMessage = ""
    if l_fAchievementRank <= 0 and bRemote then
        szMessage = string.format("<color=#e2f6fb>%s</c>", g_tStrings.STR_ACHIEVEMENT_RANK_UP_REMOTE)
    else
        szMessage = string.format("<color=#e2f6fb>%s</c><color=#FFe26e>%s%%</c><color=#e2f6fb>%s</color>",
                                    g_tStrings.STR_ACHIEVEMENT_RANK_UP_MESSAGE_1,
                                    GetRoundedNumber(100 * l_fAchievementRank, 1),
                                    g_tStrings.STR_ACHIEVEMENT_RANK_UP_MESSAGE_2
    )
    end


    UIHelper.SetRichText(self.LabelRankProgress, szMessage)
end

return UIAchievementMainView