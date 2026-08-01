-- ---------------------------------------------------------------------------------
-- Name: UIMapAchievementCell
-- Prefab: WidgetMapAchievementCell
-- ---------------------------------------------------------------------------------

local UIMapAchievementCell = class("UIMapAchievementCell")

function UIMapAchievementCell:_LuaBindList()
    --- 有一份normal 有一份selecet（带select后缀
    self.LabelTitle                      = self.LabelTitle --- 成就名称
    self.LabelCount                      = self.LabelCount --- 成就进度
    self.LabelContent1                   = self.LabelContent1 --- 成就描述
    self.ImgSeal                         = self.ImgSeal --- 成就完成状态图标，仅已完成时显示
    self.LabelAchievementProgress        = self.LabelAchievementProgress -- 子成就进度
    self.WidgetLabelContentList          = self.WidgetLabelContentList --- 顶层子成就widget
    self.LayoutTitle                     = self.LayoutTitle --- 名称和进度的 layout，用于在长度变更后保证排版

    self.LayoutAward                     = self.LayoutAward --- 奖励道具的layout
    self.BtnMohe                         = self.BtnMohe
    self.ImgIcon                         = self.ImgIcon -- 图标
end

function UIMapAchievementCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMapAchievementCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMapAchievementCell:BindUIEvent()

    UIHelper.BindUIEvent(self.TogMapAchievementCell, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected or not self.OnTogClick then
            return
        end
        self.OnTogClick()
    end)
end

function UIMapAchievementCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMapAchievementCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local MAX_ACHIEVEMENT_DESCRIPTION_SHOW_LENGTH = 38
local MAX_ACHIEVEMENT_DESCRIPTION_TRUNCATION  = "..."

function UIMapAchievementCell:UpdateData( dwAchievementID, dwPlayerID, bFinish)
    self.dwPlayerID              = dwPlayerID
    -- 外部传入的原本的成就信息
    self.dwBaseAchievementID     = dwAchievementID
    self.aBaseAchievement        = Table_GetAchievement(dwAchievementID)

    -- 由于成就可能是系列成就，而系列成就将展示当前阶段的成就的信息，所以这里另行计算实际用于展示的成就
    local dwCurrentAchievementID = dwAchievementID

    local szSeries               = self.aBaseAchievement.szSeries
    if szSeries and string.len(szSeries) > 0 then
        dwCurrentAchievementID = AchievementData.GetCurrentStageSeriesAchievementID(dwAchievementID, self.dwPlayerID) 
    end

    -- 当前实际展示的成就（仅系列成就可能与外部传入的成就不同）
    self.dwAchievementID = dwCurrentAchievementID
    self.aAchievement    = Table_GetAchievement(dwCurrentAchievementID)

    UIHelper.SetVisible(self.ImgSealSelect, bFinish)
    UIHelper.SetVisible(self.ImgSeal, bFinish)

    self:UpdateInfo()
end

function UIMapAchievementCell:UpdateInfo()
    local _, nPoint                              = Table_GetAchievementInfo(self.dwAchievementID)
    local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(self.aAchievement.szCounters)

    local szFullDescription             = UIHelper.GBKToUTF8(self.aAchievement.szDesc)
    local _, szDescription              = UIHelper.TruncateString(szFullDescription, MAX_ACHIEVEMENT_DESCRIPTION_SHOW_LENGTH, MAX_ACHIEVEMENT_DESCRIPTION_TRUNCATION)

    local bResult = UIHelper.SetItemIconByIconID(self.ImgIcon, self.aAchievement.nIconID)
    if not bResult then
        LOG.ERROR("UIMapAchievementCell:UpdateInfo, icon cfg not found, id = %d", self.aAchievement.nIconID)
        UIHelper.SetTexture(self.ImgIcon, "")
    end

    UIHelper.SetString(self.LabelTitleSelect, UIHelper.GBKToUTF8(self.aAchievement.szName))

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(self.aAchievement.szName))

    if self.aAchievement.szSubAchievements ~= "" then
        UIHelper.SetVisible(self.WidgetLabelContentList, true)
        UIHelper.SetVisible(self.WidgetLabelContentListSelect, true)
        UIHelper.SetString(self.LabelContent2Select, szDescription, 15)
        UIHelper.SetString(self.LabelContent2, szDescription, 15)
        UIHelper.SetString(self.LabelContent1Select, "")
        UIHelper.SetString(self.LabelContent1, "")
        local szProgressSeries = self:GetSubAchievementsFinishState(self.aAchievement.szSubAchievements)
        UIHelper.SetString(self.LabelAchievementProgressSelect, szProgressSeries)
        UIHelper.SetString(self.LabelAchievementProgress, szProgressSeries)
    else
        UIHelper.SetVisible(self.WidgetLabelContentList, false)
        UIHelper.SetVisible(self.WidgetLabelContentListSelect, false)
        UIHelper.SetString(self.LabelContent1Select, szDescription)
        UIHelper.SetString(self.LabelContent1, szDescription)
    end

    if bFoundCounter then
        local szProgress = string.format("%d/%d", nProgress, nMaxProgress)
        UIHelper.SetString(self.LabelCountSelect, szProgress)
        UIHelper.SetString(self.LabelCount, szProgress)
    else
        UIHelper.SetString(self.LabelCountSelect, "")
        UIHelper.SetString(self.LabelCount, "")
    end
    UIHelper.LayoutDoLayout(self.LayoutTitleSelect)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.RemoveAllChildren(self.LayoutAward)

    --- 奖励的资历点数
    local tPointItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutAward)
    tPointItemScript:OnInitCurrency(CurrencyType.AchievementPoint, nPoint)
    tPointItemScript:SetClickNotSelected(true)
    UIHelper.SetVisible(tPointItemScript.LabelPolishCount, false)
    tPointItemScript:SetClickCallback(function(nItemType, nItemIndex)
        CurrencyData.ShowCurrencyHoverTips(tPointItemScript._rootNode, CurrencyType.AchievementPoint)
    end)

    -- 奖励的道具
    if self.aAchievement.dwItemType ~= 0 and self.aAchievement.dwItemID ~= 0 then
        local tRewardItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutAward)

        tRewardItemScript:OnInitWithTabID(self.aAchievement.dwItemType, self.aAchievement.dwItemID)

        UIHelper.SetToggleGroupIndex(tRewardItemScript.ToggleSelect, ToggleGroupIndex.AchievementContentReward)

        tRewardItemScript:SetClickCallback(function(nItemType, nItemIndex)
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowItemTips(tRewardItemScript._rootNode, self.aAchievement.dwItemType, self.aAchievement.dwItemID, false)
            end)
        end)
    end

    if AchievementData.HasPrefixOrPostfix(self.dwAchievementID) then
        local scriptDesignationIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetDesignationIcon, self.LayoutAward,
                           self.dwAchievementID)
    end

    UIHelper.LayoutDoLayout(self.LayoutAward)
end

function UIMapAchievementCell:SetClickFunc(func)
    self.OnTogClick = func
end

function UIMapAchievementCell:GetSubAchievementsFinishState(szSubAchievements)
    if szSubAchievements ~= "" then
        local nFinish = 0
        local nAll = 0
        for s1 in string.gmatch(szSubAchievements, "%d+") do
            local dwAchievement1 = tonumber(s1)
            local bFinish        = g_pClientPlayer.IsAchievementAcquired(dwAchievement1)
            if bFinish then
                nFinish          = nFinish + 1
            end
            nAll                 = nAll + 1
        end
        return nFinish .. "/" .. nAll
    else
        return ""
    end  
end

return UIMapAchievementCell