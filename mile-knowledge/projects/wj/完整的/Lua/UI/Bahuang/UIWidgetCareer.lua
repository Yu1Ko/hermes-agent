-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCareer
-- Date: 2024-01-01 19:32:31
-- Desc: 生涯
-- ---------------------------------------------------------------------------------

local UIWidgetCareer = class("UIWidgetCareer")

function UIWidgetCareer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetCareer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCareer:BindUIEvent()
    
end

function UIWidgetCareer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCareer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCareer:UpdateInfo()
    local tbExpData = BahuangData.GetExpProgressData()

    local nLevel = tbExpData.nLevel
    UIHelper.SetString(self.LabelLevelNow, nLevel)

    local nMaxLevel = tbExpData.nMaxLevel
    UIHelper.SetString(self.LabelLevelMax, nMaxLevel)

    local nExp = tbExpData.nExp
    local nMaxExp = tbExpData.nMaxExp
    local nPercent = (nExp ~= 0 and nMaxExp ~= 0) and (nExp / nMaxExp * 100) or 0

    UIHelper.SetString(self.LabelExp, tostring(nExp).."/"..tostring(nMaxExp))
    UIHelper.SetProgressBarPercent(self.ProgressBar01, nPercent)

    -- UIHelper.SetString(self.LabelWeekScore, szContent, nMaxLen)--取不到数据
    -- UIHelper.SetString(self.LabelTotalScore, szContent, nMaxLen)

    self:UpdateLevelAward()
    self:UpdateCommonAward()
end

function UIWidgetCareer:UpdateLevelAward()
    local tbLevelAwardList = BahuangData.GetExpLevelAwardInfo()
    local nCurrentLevel = BahuangData.GetExpProgressData().nLevel
    for nIndex, tbAwardInfo in ipairs(tbLevelAwardList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangAward, self.ScrollViewLevelAward, tbAwardInfo, nCurrentLevel, nIndex, true)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewLevelAward)
    UIHelper.ScrollToLeft(self.ScrollViewLevelAward)
end

function UIWidgetCareer:UpdateCommonAward()
    local tbCommonAwardList = BahuangData.GetCommonAwardList()
    local nCurrentLevel = BahuangData.GetCurrentCommonAwardLevel()
    for nIndex, tbAwardInfo in ipairs(tbCommonAwardList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangAward, self.ScrollViewScoreAward, tbAwardInfo, nCurrentLevel, nIndex, false)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewScoreAward)
    UIHelper.ScrollToLeft(self.ScrollViewScoreAward)
end


return UIWidgetCareer