-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContent
-- Date: 2023-02-20 14:38:21
-- Desc: 隐元秘鉴 - 类别成就详情 - 成就widget
-- Prefab: WidgetAchievementContent
-- ---------------------------------------------------------------------------------

---@class UIAchievementContent
local UIAchievementContent = class("UIAchievementContent")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContent:_LuaBindList()
    self.ImgIcon                         = self.ImgIcon --- 成就图标
    self.LabelName                       = self.LabelName --- 成就名称
    self.LabelProgress                   = self.LabelProgress --- 成就进度
    self.LabelDescription                = self.LabelDescription --- 成就描述
    self.ImgFinishStatus                 = self.ImgFinishStatus --- 成就完成状态图标，仅已完成时显示

    self.LayoutNameAndProgress           = self.LayoutNameAndProgress --- 名称和进度的 layout，用于在长度变更后保证排版

    self.BtnShowDetail                   = self.BtnShowDetail --- 查看详情的按钮

    self.BtnShowRanking                  = self.BtnShowRanking --- 查看排名信息的按钮

    self.LayoutRewardItem                = self.LayoutRewardItem --- 奖励道具的layout

    self.BtnTopLevel                     = self.BtnTopLevel --- 最上层的按钮，目前用于描述文本过长时点击显示完整内容

    self.ImgAchievementContentBg         = self.ImgAchievementContentBg --- 背景图片（未选中）
    self.ImgAchievementContentBgSelected = self.ImgAchievementContentBgSelected --- 背景图片（选中）

    self.WidgetContentNormal             = self.WidgetContentNormal --- 有子成就时效果
    self.WidgetContentSkip               = self.WidgetContentSkip --- 选中时有子成就效果
    self.BtnMohe                         = self.BtnMohe --- 魔盒
    self.BtnGo                           = self.BtnGo --- 前往
end

function UIAchievementContent:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

--- 由于目前该组件是通过table view来使用，会被无参数调用OnEnter，因此将一些逻辑放到这里来处理，避免因未传参而报错
function UIAchievementContent:OnManualEnter(nPanelType, dwAchievementID, dwPlayerID)
    self.nPanelType              = nPanelType
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

    self:UpdateInfo()
end

function UIAchievementContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContent:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShowDetail, EventType.OnClick, function()
        local szSeries = self.aBaseAchievement.szSeries

        if szSeries and string.len(szSeries) > 0 then
            --一系列的成就
            UIMgr.Open(VIEW_ID.PanelAchievementContentListPop, self.dwBaseAchievementID, self.dwPlayerID)
        else
            -- 普通成就
            UIMgr.Open(VIEW_ID.PanelAchievementContentSchedulePop, self.dwBaseAchievementID, self.dwPlayerID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnShowRanking, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelAchievementContentRankPop, self.dwBaseAchievementID)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        ChatHelper.SendAchievementToChat(self.dwBaseAchievementID)
    end)

    UIHelper.BindUIEvent(self.BtnMohe, EventType.OnClick, function()
        local szMoHeBaseUrl = "https://www.jx3box.com/cj/view/"
        if Platform.IsMobile() then
            szMoHeBaseUrl = "https://www.jx3box.com/wujie/cj/view/"
        end
        local szUrl = szMoHeBaseUrl .. self.dwBaseAchievementID
        UIHelper.OpenWeb(szUrl)
    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        if self.fnGotoMap then
            self.fnGotoMap()
        end
    end)

end

function UIAchievementContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:AdjustSize()
    end)
end

function UIAchievementContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local MAX_ACHIEVEMENT_DESCRIPTION_SHOW_LENGTH = 40
local MAX_ACHIEVEMENT_DESCRIPTION_TRUNCATION  = "..."

function UIAchievementContent:UpdateInfo()
    local bFinish                                = AchievementData.IsAchievementAcquired(self.dwAchievementID, self.aAchievement, self.dwPlayerID)
    local _, nPoint                              = Table_GetAchievementInfo(self.dwAchievementID)
    local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(self.aAchievement.szCounters)

    local szFullDescription                      = UIHelper.GBKToUTF8(self.aAchievement.szDesc)
    local bTruncated, szDescription              = UIHelper.TruncateString(szFullDescription, MAX_ACHIEVEMENT_DESCRIPTION_SHOW_LENGTH, MAX_ACHIEVEMENT_DESCRIPTION_TRUNCATION)
    if bTruncated then
        -- 同时此时点击按钮弹出完整提示
        UIHelper.BindUIEvent(self.BtnTopLevel, EventType.OnClick, function()
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self._rootNode,
                                             szFullDescription
                )
            end)
        end)
    end

    local bResult = UIHelper.SetItemIconByIconID(self.ImgIcon, self.aAchievement.nIconID)
    if not bResult then
        LOG.ERROR("UIAchievementContent:UpdateInfo, icon cfg not found, id = %d", self.aAchievement.nIconID)
        UIHelper.SetTexture(self.ImgIcon, "")
    end

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.aAchievement.szName))
    UIHelper.SetString(self.LabelDescription, szDescription)
    UIHelper.SetVisible(self.ImgFinishStatus, bFinish)

    if bFoundCounter then
        local szProgress = string.format("%d/%d", nProgress, nMaxProgress)
        UIHelper.SetString(self.LabelProgress, szProgress)
    else
        UIHelper.SetString(self.LabelProgress, "")
    end
    UIHelper.LayoutDoLayout(self.LayoutNameAndProgress)

    UIHelper.RemoveAllChildren(self.LayoutRewardItem)

    --- 奖励的资历点数
    --- @type UIItemIcon
    local tPointItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItem)
    tPointItemScript:OnInitCurrency(CurrencyType.AchievementPoint, nPoint)
    tPointItemScript:SetClickNotSelected(true)
    UIHelper.SetVisible(tPointItemScript.LabelPolishCount, false)
    tPointItemScript:SetClickCallback(function(nItemType, nItemIndex)
        CurrencyData.ShowCurrencyHoverTipsInDir(tPointItemScript._rootNode, TipsLayoutDir.TOP_LEFT, CurrencyType.AchievementPoint)
    end)

    -- 奖励的道具
    if self.aAchievement.dwItemType ~= 0 and self.aAchievement.dwItemID ~= 0 then
        local tRewardItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItem)

        tRewardItemScript:OnInitWithTabID(self.aAchievement.dwItemType, self.aAchievement.dwItemID)

        UIHelper.SetToggleGroupIndex(tRewardItemScript.ToggleSelect, ToggleGroupIndex.AchievementContentReward)

        tRewardItemScript:SetClickCallback(function(nItemType, nItemIndex)
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowItemTips(tRewardItemScript._rootNode, self.aAchievement.dwItemType, self.aAchievement.dwItemID, false)
            end)
        end)
    end

    if AchievementData.HasPrefixOrPostfix(self.dwAchievementID) then
        UIHelper.AddPrefab(PREFAB_ID.WidgetDesignationIcon, self.LayoutRewardItem,
                           self.dwAchievementID
        )
    end

    UIHelper.LayoutDoLayout(self.LayoutRewardItem)

    -- 仅有子成就，或者是系列成就时显示详情按钮
    if self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT
        and (self.aBaseAchievement.szSeries ~= "" or self.aBaseAchievement.szSubAchievements ~= "") then
        UIHelper.SetVisible(self.BtnShowDetail, true)
        UIHelper.SetVisible(self.WidgetContentNormal, true)
    else
        UIHelper.SetVisible(self.BtnShowDetail, false)
        UIHelper.SetVisible(self.WidgetContentNormal, false)
    end

    UIHelper.SetVisible(self.BtnShowRanking, self.nPanelType == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD)

    
    local bShowGoBtn = self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT
    if bShowGoBtn then
        bShowGoBtn = false
        for s1 in string.gmatch(self.aBaseAchievement.szSceneID, "%d+") do
            local dwMapID = tonumber(s1)
            if dwMapID ~= 0 then
                local _, nMapType = GetMapParams(dwMapID)
                local bGotoType = nMapType and (nMapType == MAP_TYPE.DUNGEON or nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.TONG_DUNGEON)
                if bGotoType then
                    bShowGoBtn = true
                    break
                end
            end
        end
    end
    UIHelper.SetVisible(self.BtnGo, bShowGoBtn)
end

function UIAchievementContent:SetGotoMapFunc(func)
    self.fnGotoMap = func
end

function UIAchievementContent:SetContentClickVisible()
    if self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT
        and (self.aBaseAchievement.szSeries ~= "" or self.aBaseAchievement.szSubAchievements ~= "") then
        UIHelper.SetVisible(self.WidgetContentSkip, true)
    else
        UIHelper.SetVisible(self.WidgetContentSkip, false)
    end
end

function UIAchievementContent:AdjustSize()

    local nOldWidth = UIHelper.GetWidth(self._rootNode)

    local nodeShell = UIHelper.GetParent(self._rootNode)
    if not nodeShell then return end
    local nodeLayout = UIHelper.GetParent(nodeShell)
    local nWidth = UIHelper.GetWidth(nodeLayout)
    UIHelper.SetWidth(nodeShell, nWidth)
    UIHelper.SetWidth(self._rootNode, nWidth)
    Timer.AddFrame(self, 1, function ()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)
end

return UIAchievementContent