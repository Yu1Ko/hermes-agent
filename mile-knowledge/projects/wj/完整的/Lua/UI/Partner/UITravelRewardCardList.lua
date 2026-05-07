-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelRewardCardList
-- Date: 2025-01-08 22:12:35
-- Desc: 侠客出行 奖励
-- Prefab: WidgetTravelRewardCardList
-- ---------------------------------------------------------------------------------

---@class UITravelRewardCardList
local UITravelRewardCardList = class("UITravelRewardCardList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelRewardCardList:_LuaBindList()
    self.LabelName           = self.LabelName --- 事件名称
    self.LabelPartnerName    = self.LabelPartnerName --- 侠客名称
    self.LabelPartnerTime    = self.LabelPartnerTime --- 时长
    self.LayoutReward        = self.LayoutReward --- 奖励
    self.LayoutAchieve       = self.LayoutAchieve --- 成就
    self.LabelAchieveNon     = self.LabelAchieveNon --- 无成就时的文本提示

    self.ScrollViewInfo      = self.ScrollViewInfo --- 上层的scroll view
    self.WidgetQiYuNon       = self.WidgetQiYuNon --- 未触发奇遇时的组件
    self.WidgetIAchieveTitle = self.WidgetIAchieveTitle --- 成就标题的上层组件

    self.ImgBgLightQiYu      = self.ImgBgLightQiYu --- 出奇遇时的背景
    self.WidgetQiYu          = self.WidgetQiYu --- 触发奇遇时显示的组件
    self.ImgQiYu             = self.ImgQiYu --- 奇遇的图片

    self.ImgBgNormal         = self.ImgBgNormal --- 未出奇遇时的背景
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelRewardCardList:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UITravelRewardCardList:OnEnter(tInfo)
    self.tInfo = tInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITravelRewardCardList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelRewardCardList:BindUIEvent()

end

function UITravelRewardCardList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelRewardCardList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelRewardCardList:UpdateInfo()
    local nQuest, tHero, nMinute, tReward = table.unpack(self.tInfo)

    local fnRemoveZeroHero                = function(tPartnerIDList)
        local tRes = {}
        for _, nHeroID in ipairs(tPartnerIDList) do
            if nHeroID ~= 0 then
                table.insert(tRes, nHeroID)
            end
        end
        return tRes
    end
    tHero                                 = fnRemoveZeroHero(tHero)

    local tQuestInfo                      = Table_GetPartnerTravelTask(nQuest)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tQuestInfo.szName))

    -- 出行信息
    local tPartnerNameList = {}
    for idx, nPartnerID in ipairs(tHero) do
        local tPartnerInfo = Table_GetPartnerNpcInfo(nPartnerID)

        table.insert(tPartnerNameList, UIHelper.GBKToUTF8(tPartnerInfo.szName))
    end

    local szPartnerNameList = table.concat(tPartnerNameList, "、")
    local szCostTime        = TimeLib.GetTimeText(nMinute * 60, nil, true)

    UIHelper.SetString(self.LabelPartnerName, string.format("出行侠客：%s", szPartnerNameList))
    UIHelper.SetString(self.LabelPartnerTime, string.format("出行时长：%s", szCostTime))

    -- 道具奖励
    UIHelper.RemoveAllChildren(self.LayoutReward)

    for _, v in ipairs(tReward.item) do
        local dwType, dwIndex, nCount = table.unpack(v)

        local hItemInfo               = GetItemInfo(dwType, dwIndex)
        local szName                  = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo, nCount))
        szName                        = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

        ---@type UIQuestAwardView
        local script                  = UIHelper.AddPrefab(
                PREFAB_ID.WidgetAwardItemPartner, self.LayoutReward,
                szName, nCount, dwType, dwIndex, nil, nil, nil, true
        )
        script:OnEnter(szName, nCount, dwType, dwIndex, nil, nil, nil, true)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

        local bIsBook = hItemInfo.nGenre == ITEM_GENRE.BOOK

        if not bIsBook and nCount > 1 then
            script:SetIconCount(nCount)
        end

        script:SetSingleClickCallback(function(nItemType, nItemIndex)
            TipsHelper.DeleteAllHoverTips()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script._rootNode, nItemType, nItemIndex)

            if bIsBook then
                uiItemTipScript:SetBookID(nCount)
                uiItemTipScript:OnInitWithTabID(nItemType, nItemIndex)
            end

            uiItemTipScript:SetBtnState({})
        end)
    end

    -- 声望
    if table.get_len(tReward.sw) > 0 then
        local tRenowList = {}
        for _, v in ipairs(tReward.sw) do
            local nForceId, nDelta   = table.unpack(v)

            local tRepuInfo          = Table_GetReputationForceInfo(nForceId)
            local szOriginalRepuName = UIHelper.GBKToUTF8(tRepuInfo.szName)
            local szRepuName         = UIHelper.TruncateStringReturnOnlyResult(szOriginalRepuName, 3)

            ---@type UIQuestAwardView
            local script             = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.LayoutReward,
                    szRepuName, nDelta, nil, nil, nil, nil, nil, true
            )
            script:OnEnter(szRepuName, nDelta, nil, nil, nil, nil, nil, true)
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
            UIHelper.SetTexture(script.scriptItemIcon.ImgIcon, tRepuInfo.szIconPath)

            script:SetIconCount(nDelta)

            script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
                local szDesc = string.format("【%s】声望增加 %d ", szOriginalRepuName, nDelta)
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, script._rootNode, TipsLayoutDir.BOTTOM_CENTER, szDesc)
            end)
        end
    end

    -- 名望
    if table.get_len(tReward.mw) > 0 then
        local tFameList = {}
        for _, v in ipairs(tReward.mw) do
            local nFameId, nDelta    = table.unpack(v)

            local tFameInfo          = FameData.GetFameInfo(nFameId)

            local szOriginalFameName = UIHelper.GBKToUTF8(tFameInfo.szName)
            local szFameName         = UIHelper.TruncateStringReturnOnlyResult(szOriginalFameName, 3)

            ---@type UIQuestAwardView
            local script             = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.LayoutReward,
                    szFameName, nDelta, nil, nil, nil, nil, nil, true
            )
            script:OnEnter(szFameName, nDelta, nil, nil, nil, nil, nil, true)
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
            UIHelper.SetSpriteFrame(script.scriptItemIcon.ImgIcon, tFameInfo.szVKImagePath)

            script:SetIconCount(nDelta)

            script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
                local szDesc = string.format("【%s】名望增加 %d ", szOriginalFameName, nDelta)
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, script._rootNode, TipsLayoutDir.BOTTOM_CENTER, szDesc)
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)

    -- 成就计数奖励
    local bHasAchieveReward = table.get_len(tReward.achi) > 0
    UIHelper.SetVisible(self.WidgetIAchieveTitle, bHasAchieveReward)
    UIHelper.SetVisible(self.LayoutAchieve, bHasAchieveReward)
    UIHelper.SetVisible(self.LabelAchieveNon, false)

    if bHasAchieveReward then
        UIHelper.RemoveAllChildren(self.LayoutAchieve)

        for _, v in ipairs(tReward.achi) do
            local dwBaseAchievementID, nAddCount = table.unpack(v)

            -- 外部传入的原本的成就信息
            local aBaseAchievement               = Table_GetAchievement(dwBaseAchievementID)

            -- 由于成就可能是系列成就，而系列成就将展示当前阶段的成就的信息，所以这里另行计算实际用于展示的成就
            local dwCurrentAchievementID         = dwBaseAchievementID

            local szSeries                       = aBaseAchievement.szSeries
            if szSeries and string.len(szSeries) > 0 then
                dwCurrentAchievementID = AchievementData.GetCurrentStageSeriesAchievementID(dwBaseAchievementID)
            end

            -- 当前实际展示的成就（仅系列成就可能与外部传入的成就不同）
            local dwAchievementID = dwCurrentAchievementID
            local aAchievement    = Table_GetAchievement(dwCurrentAchievementID)

            local szName          = UIHelper.GBKToUTF8(aAchievement.szName)
            szName                = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

            ---@type UIQuestAwardView
            local script          = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.LayoutAchieve,
                    szName, nAddCount, nil, nil, nil, nil, aAchievement.nIconID, true
            )
            script:OnEnter(szName, nAddCount, nil, nil, nil, nil, aAchievement.nIconID, true)
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

            script:SetIconCount(nAddCount)

            script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
                UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
            end)
        end

        UIHelper.LayoutDoLayout(self.LayoutAchieve)
    end

    --- 处理奇遇的情况
    local bIsQiYu = tQuestInfo.dwAdventureID > 0
    if bIsQiYu then
        --- 奇遇时应该没有成就部分，将这部分隐藏掉
        UIHelper.SetVisible(self.WidgetIAchieveTitle, false)
        UIHelper.SetVisible(self.LayoutAchieve, false)
        UIHelper.SetVisible(self.LabelAchieveNon, false)

        local bHasTrigger = false
        if tReward.pet then
            local nAdvenID, bPetMeet = table.unpack(tReward.pet)
            if nAdvenID == tQuestInfo.dwAdventureID then
                bHasTrigger = bPetMeet
            end
        end

        UIHelper.SetVisible(self.WidgetQiYuNon, not bHasTrigger)

        UIHelper.SetVisible(self.ImgBgLightQiYu, bHasTrigger)
        UIHelper.SetVisible(self.ImgBgNormal, not bHasTrigger)
        UIHelper.SetVisible(self.WidgetQiYu, bHasTrigger)
        if bHasTrigger then
            local tAdv   = Table_GetAdventureByID(tQuestInfo.dwAdventureID)
            local szPath = AdventureData.GetOpenRewardPath(tAdv)
            UIHelper.SetTexture(self.ImgQiYu, szPath, false)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewInfo)
end

return UITravelRewardCardList