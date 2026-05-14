-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPageProgress
-- Date: 2026-03-02 10:43:02
-- Desc: 扬刀大会-挑战进度分页 WidgetPageProgress (PanelYangDaoOverview)
-- ---------------------------------------------------------------------------------

local UIWidgetPageProgress = class("UIWidgetPageProgress")

local SCALE_DEFAULT = 0.5
local SCALE_MAX = 1
local SCALE_MIN = 0.5

-- 部分图标在地图上位置不太好看/重叠之类的，单独把WidgetTitle移到右侧显示
local tOverridePosX = {
    [5] = 70,
    [6] = 70,
    [8] = 70,
}

local tOverridePosY = {

}

function UIWidgetPageProgress:OnEnter(tLevelList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitTouchComponent()
        self.scriptDetail = UIHelper.GetBindScript(self.WidgetPageDetail)
        UIHelper.SetVisible(self.WidgetPageDetail, false) -- 默认关闭
    end

    local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
    self.nDiffMode = nDiffMode
    self.nLevelProgress = nLevelProgress

    self.tLevelList = tLevelList
    self.scriptDetail:OnInit(tLevelList)

    self:UpdateInfo()
end

function UIWidgetPageProgress:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindUIZoom()
    if self.TouchComponent then
        self.TouchComponent:Dispose()
    end
end

function UIWidgetPageProgress:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_RESET_PROGRESS_CONFIRM, function()
            ArenaTowerData.ResetProgress()
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnDifficultyDown, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_SWITCH_PRACTICE_CONFIRM, function()
            ArenaTowerData.DifficultyDown()
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchBegan, function(btn, nX, nY)
        self.TouchComponent:TouchBegin(nX, nY)
    end)
    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchMoved, function(btn, nX, nY)
        self.TouchComponent:TouchMoved(nX, nY)
    end)
    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchEnded, function(btn, nX, nY)
        self.TouchComponent:TouchEnded(nX, nY)
    end)
    UIHelper.BindUIEvent(self.BtnMapClose, EventType.OnTouchCanceled, function(btn)
        self.TouchComponent:TouchCanceled()
    end)

    UITouchHelper.BindUIZoom(self.WidgetTouch, function(delta)
        if self.TouchComponent then
            self.TouchComponent:Zoom(delta)
        end
    end)
end

function UIWidgetPageProgress:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerOverviewLevelDetail, function(nLevelIndex, bMapFlag)
        local bVisibleUpdate = not self.nLevelIndex ~= not nLevelIndex
        self.nLevelIndex = nLevelIndex
        if bVisibleUpdate then
            Timer.DelTimer(self, self.nAniTimerID)
            Timer.DelTimer(self, self.nVisTimerID)
            if nLevelIndex ~= nil then
                if bMapFlag then
                    --打开详情页同时会同步加载Detail界面的大图，会导致动画也跟着一起卡，这里等图加载完再播动画，保证动画顺畅
                    self.nAniTimerID = Timer.AddFrame(self, 1, function()
                        UIHelper.StopAni(self, self.scriptDetail.AniAll, "AniOverviewPageDetailHide")
                        UIHelper.PlayAni(self, self.scriptDetail.AniAll, "AniOverviewPageDetailShow")
                    end)
                    self.nVisTimerID = Timer.AddFrame(self, 2, function()
                        UIHelper.SetVisible(self.WidgetPageDetail, true)
                    end)
                else
                    UIHelper.SetVisible(self.WidgetPageDetail, true)
                end
            else
                self.TouchComponent:Scale(SCALE_DEFAULT)
                UIHelper.StopAni(self, self.scriptDetail.AniAll, "AniOverviewPageDetailShow")
                UIHelper.PlayAni(self, self.scriptDetail.AniAll, "AniOverviewPageDetailHide", function()
                    UIHelper.SetVisible(self.WidgetPageDetail, false)
                end)
            end
        end
    end)
    Event.Reg(self, EventType.OnArenaTowerDiffProgressUpdate, function()
        local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
        self.nDiffMode = nDiffMode
        self.nLevelProgress = nLevelProgress
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        local nMapHeight = UIHelper.GetHeight(self.WidgetMap)
        local nViewHeight = UIHelper.GetHeight(self._rootNode)
        local nScale = math.max(nViewHeight / nMapHeight, 0.2)
        SCALE_DEFAULT = nScale
        SCALE_MAX = 2 * nScale
        SCALE_MIN = nScale

        self.TouchComponent:SetScaleLimit(SCALE_MIN, SCALE_MAX)
        if self.TouchComponent.nScale < SCALE_MIN then
            self.TouchComponent:Scale(SCALE_MIN)
        elseif self.TouchComponent.nScale > SCALE_MAX then
            self.TouchComponent:Scale(SCALE_MAX)
        end
        self.TouchComponent:SetPosition(0, 0)

        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutBtn)
            UIHelper.LayoutDoLayout(self.LayoutLabel)
        end)
    end)
end

function UIWidgetPageProgress:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPageProgress:InitTouchComponent()
    local nMapHeight = UIHelper.GetHeight(self.WidgetMap)
    local nViewHeight = UIHelper.GetHeight(self._rootNode)
    local nScale = math.max(nViewHeight / nMapHeight, 0.2)
    SCALE_DEFAULT = nScale
    SCALE_MAX = 2 * nScale
    SCALE_MIN = nScale

    -- ReloadScript.Reload("Lua/UI/Map/Component/UIMapScrollComponent")
    -- self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent = require("Lua/UI/Map/Component/UIMapScrollComponent"):CreateInstance()
    self.TouchComponent:Init(self.WidgetMap)
    self.TouchComponent:SetScaleLimit(SCALE_MIN, SCALE_MAX)
    self.TouchComponent:SetReboundScale(0.2, 0.1)
    self.TouchComponent:RegisterScaleEvent(function(nScale)
        Event.Dispatch(EventType.OnArenaTowerOverviewMapScale, nScale)
    end)
    self.TouchComponent:Scale(SCALE_DEFAULT)
end

function UIWidgetPageProgress:UpdateInfo()
    -- 第0关表示驿站
    for i = 0, ArenaTowerData.MAX_LEVEL_COUNT do
        local widgetLevel = UIHelper.GetChildByName(self.WidgetCityIcon, string.format("WidgetLevel%02d", i))
        if widgetLevel then
            UIHelper.RemoveAllChildren(widgetLevel)
            local tLevelData = self.tLevelList and self.tLevelList[i]
            local nLevelIndex = tLevelData and tLevelData.nLevelIndex or 0
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoLevelIconCell, widgetLevel, nLevelIndex)
            local bCurrent = nLevelIndex == self.nLevelProgress
            local bSpecial = tLevelData and tLevelData.bSpecial or false
            local nLevelState = tLevelData and tLevelData.nLevelState or nil
            script:SetProgressState(self.nDiffMode, nLevelIndex < self.nLevelProgress + 1, nLevelIndex == self.nLevelProgress + 1)
            script:SetLevelState(nLevelState)
            script:SetCurrent(bCurrent)
            script:SetSpecial(bSpecial)
            if nLevelIndex == self.nLevelProgress + 1 then
                script:SetUnlock(true) -- 解锁下一关
            end
            script:UpdateMapScale(SCALE_DEFAULT)
            if nLevelIndex > 0 then
                -- 非驿站才可点击
                script:SetClickCallback(function()
                    self:TweenToLevel(nLevelIndex, function()
                        Event.Dispatch(EventType.OnArenaTowerOverviewLevelDetail, nLevelIndex, true)
                    end)
                end)
            end

            local nOverridePosX = tOverridePosX[nLevelIndex]
            if nOverridePosX then
                UIHelper.SetPositionX(script.WidgetTitle, nOverridePosX)
            end
            local nOverridePosY = tOverridePosY[nLevelIndex]
            if nOverridePosY then
                UIHelper.SetPositionY(script.WidgetTitle, nOverridePosY)
            end
        end
    end

    self:UpdateCurrentLevel(self.nDiffMode, self.nLevelProgress)
end

function UIWidgetPageProgress:TweenToLevel(nLevelIndex, fnCallback)
    local widgetLevel = nLevelIndex and UIHelper.GetChildByName(self.WidgetCityIcon, string.format("WidgetLevel%02d", nLevelIndex))
    if not widgetLevel then
        return
    end

    self.TouchComponent:MoveToNodeWithScale(widgetLevel, SCALE_MAX)
    Timer.DelTimer(self, self.nTweenTimerID)
    if self.TouchComponent.nTweenTime then
        self.nTweenTimerID = Timer.Add(self, self.TouchComponent.nTweenTime, function()
            if fnCallback then
                fnCallback()
            end
        end)
    elseif fnCallback then
        fnCallback()
    end
end

function UIWidgetPageProgress:UpdateCurrentLevel(nDiffMode, nLevelIndex)
    local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelIndex)
    if not tLevelConfig then
        return
    end

    UIHelper.SetVisible(self.WidgetBgPractice, nDiffMode == ArenaTowerDiffMode.Practice)
    UIHelper.SetVisible(self.WidgetBgChallenge, nDiffMode == ArenaTowerDiffMode.Challenge)
    UIHelper.SetVisible(self.LabelTitle, nLevelIndex > 0)
    UIHelper.SetString(self.LabelTitle, string.format("第 %d 关", nLevelIndex))
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tLevelConfig.szName))
    UIHelper.LayoutDoLayout(self.LayoutLabel)

    UIHelper.SetVisible(self.WidgetReset, nLevelIndex > 0)
    UIHelper.SetVisible(self.WidgetDifficultyDown, nDiffMode == ArenaTowerDiffMode.Challenge and nLevelIndex < ArenaTowerData.MAX_LEVEL_COUNT)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

return UIWidgetPageProgress