-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelInfoPop
-- Date: 2024-12-13 15:11:03
-- Desc: 侠客出行信息组件
-- Prefab: WidgetTravelInfoPop
-- ---------------------------------------------------------------------------------

---@class UITravelInfoPop
local UITravelInfoPop = class("UITravelInfoPop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelInfoPop:_LuaBindList()
    self.BtnClose              = self.BtnClose --- 关闭按钮
    self.LayoutCard            = self.LayoutCard --- 侠客卡片的layout
    self.ScrollViewReward      = self.ScrollViewReward --- 奖励的scroll view
    self.LabelTime             = self.LabelTime --- 事件状态
    self.BtnReward             = self.BtnReward --- 领取奖励按钮
    self.BtnCancel             = self.BtnCancel --- 取消委托按钮
    self.LabelName             = self.LabelName --- 事件名称

    self.WidgetAchievement     = self.WidgetAchievement --- 成就奖励的上层节点
    self.ScrollViewAchievement = self.ScrollViewAchievement --- 成就的scroll view
    self.LabelAchievementHint  = self.LabelAchievementHint --- 无成就奖励时的提示
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelInfoPop:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UITravelInfoPop:OnEnter(uiPartnerTravelInfoPopView)
    if not uiPartnerTravelInfoPopView then
        return
    end

    ---@type UIPartnerTravelInfoPopView
    self.parent = uiPartnerTravelInfoPopView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateState()
    end)
end

function UITravelInfoPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelInfoPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self.parent)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:CancelTravel()
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        self:TakeReward()
    end)
end

function UITravelInfoPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelInfoPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelInfoPop:UpdateInfo()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(self.parent.tQuestInfo)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    if not (bInTravel or bFinished) then
        -- 本界面仅展示出行中和已完成的状态，这里保底检查下
        UIMgr.Close(self.parent)
        return
    end

    local tQuestInfo = Table_GetPartnerTravelTask(nQuest)

    UIHelper.RemoveAllChildren(self.LayoutCard)

    for idx, nPartnerID in ipairs(tHeroList) do
        local tInfo  = Table_GetPartnerNpcInfo(nPartnerID)

        ---@type UITravelInfoRoleCard
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoRoleCard, self.LayoutCard, tInfo)

        UIHelper.SetAnchorPoint(script._rootNode, 0, 0.5)
        if table.get_len(tHeroList) == 3 then
            local deltaY = 0
            if idx == 1 or idx == 3 then
                deltaY = -30
            elseif idx == 2 then
                deltaY = 20
            end
            UIHelper.SetPositionY(script._rootNode, deltaY)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutCard)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tQuestInfo.szName))

    self:UpdatePreviewRewardListInfo(nQuest)

    self:UpdateState()

    UIHelper.SetVisible(self.BtnCancel, bInTravel)
    UIHelper.SetVisible(self.BtnReward, bFinished)
end

function UITravelInfoPop:UpdatePreviewRewardListInfo(nQuest)
    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    local tQuest  = Table_GetPartnerTravelTask(nQuest)

    local tReward = SplitString(tQuest.szGiftItem, ";")
    for _, v in pairs(tReward) do
        local tInfo                   = SplitString(v, "_")
        local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
        nCount                        = nCount or 0

        if tInfo[1] ~= "COIN" then
            local hItemInfo = GetItemInfo(dwType, dwIndex)
            local szName    = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo))
            szName          = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

            ---@type UIQuestAwardView
            local script    = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                    szName, nCount, dwType, dwIndex, nil, nil, nil, true
            )
            script:OnEnter(szName, nCount, dwType, dwIndex, nil, nil, nil, true)
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
            script:SetIconCount(nCount)

            script:SetSingleClickCallback(function(nItemType, nItemIndex)
                TipsHelper.DeleteAllHoverTips()
                local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script._rootNode, nItemType, nItemIndex)
                uiItemTipScript:SetBtnState({})
            end)
        else
            local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
            local szName = CurrencyNameToType[tbLine.szName]
            szName       = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

            ---@type UIQuestAwardView
            local script = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                    szName, nCount, nil, nil, nil, nil, nil, true
            )
            script:OnEnter(szName, nCount, nil, nil, nil, nil, nil, true)
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
            UIHelper.SetSpriteFrame(script.scriptItemIcon.ImgIcon, CurrencyData.tbImageBigIcon[CurrencyNameToType[tbLine.szName]])

            script:SetIconCount(nCount)
        end
    end

    -- 声望
    local tReputationReward = SplitString(tQuest.szReputation, ";")
    for _, v in pairs(tReputationReward) do
        local tInfo              = SplitString(v, "_")
        local nForceId, nDelta   = tonumber(tInfo[1]), tonumber(tInfo[2])

        local tRepuInfo          = Table_GetReputationForceInfo(nForceId)
        local szOriginalRepuName = UIHelper.GBKToUTF8(tRepuInfo.szName)
        local szRepuName         = UIHelper.TruncateStringReturnOnlyResult(szOriginalRepuName, 3)

        ---@type UIQuestAwardView
        local script             = UIHelper.AddPrefab(
                PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
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

    -- 名望
    local tFameReward = SplitString(tQuest.szFame, ";")
    for _, v in pairs(tFameReward) do
        local tInfo              = SplitString(v, "_")
        local nFameId, nDelta    = tonumber(tInfo[1]), tonumber(tInfo[2])

        local tFameInfo          = FameData.GetFameInfo(nFameId)

        local szOriginalFameName = UIHelper.GBKToUTF8(tFameInfo.szName)
        local szFameName         = UIHelper.TruncateStringReturnOnlyResult(szOriginalFameName, 3)

        ---@type UIQuestAwardView
        local script             = UIHelper.AddPrefab(
                PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                szFameName, nDelta, nil, nil, nil, nil, nil, true
        )
        script:OnEnter(szFameName, nDelta, nil, nil, nil, nil, nil, true)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
        UIHelper.SetSpriteFrame(script.scriptItemIcon.ImgIcon, tFameInfo.szVKImagePath)

        script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
            local szDesc = string.format("【%s】名望增加 %d ", szOriginalFameName, nDelta)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, script._rootNode, TipsLayoutDir.BOTTOM_CENTER, szDesc)
        end)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewReward)
end

function UITravelInfoPop:UpdateState()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(self.parent.tQuestInfo)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    local szState
    if bInTravel then
        local nCurTime       = GetCurrentTime()
        local nRemainingTime = nStart + nMinute * 60 - nCurTime
        local szTime         = TimeLib.GetTimeText(nRemainingTime, nil, true)
        szState              = string.format("剩余：%s", szTime)
    else
        szState = "已完成"
    end

    UIHelper.SetString(self.LabelTime, szState)

    UIHelper.SetVisible(self.BtnCancel, bInTravel)
    UIHelper.SetVisible(self.BtnReward, bFinished)
end

function UITravelInfoPop:CancelTravel()
    LOG.TABLE({
                  "DEBUG: 本地测试 取消出行",
                  self.parent.nCurrentBoard, self.parent.nQuestIndex,
              })

    local dialog = UIHelper.ShowConfirm(string.trim([[
您要取消委托，并返还出行消耗么？
    ]]), function()
        UIHelper.RemoteCallToServer("On_Hero_CancelTravel", {
            { self.parent.nCurrentBoard, self.parent.nQuestIndex }
        })

        UIMgr.Close(self.parent)
    end)

    if dialog then
        dialog:SetConfirmButtonContent("取消委托")
        dialog:SetCancelButtonContent("继续委托")
    end
end

function UITravelInfoPop:TakeReward()
    LOG.TABLE({
                  "DEBUG: 本地测试 领取出行奖励",
                  self.parent.nCurrentBoard, self.parent.nQuestIndex,
              })
    UIHelper.RemoteCallToServer("On_Hero_FinishTravel", {
        { self.parent.nCurrentBoard, self.parent.nQuestIndex }
    })
end

function UITravelInfoPop:ShowFinishRewardDetail(tInfo)
    local nQuest, tHero, nMinute, tReward = table.unpack(tInfo)

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

    -- 隐藏一些展示奖励用时不需要的元素
    UIHelper.SetVisible(self.BtnClose, false)
    UIHelper.SetVisible(self.BtnCancel, false)
    UIHelper.SetVisible(self.BtnReward, false)
    UIHelper.SetVisible(self.LabelTime, false)

    UIHelper.SetVisible(self.WidgetAchievement, true)

    local tQuestInfo = Table_GetPartnerTravelTask(nQuest)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tQuestInfo.szName))

    UIHelper.RemoveAllChildren(self.LayoutCard)

    for idx, nPartnerID in ipairs(tHero) do
        local tPartnerInfo = Table_GetPartnerNpcInfo(nPartnerID)

        ---@type UITravelInfoRoleCard
        local script       = UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoRoleCard, self.LayoutCard, tPartnerInfo)

        UIHelper.SetAnchorPoint(script._rootNode, 0, 0.5)
        if table.get_len(tHeroList) == 3 then
            local deltaY = 0
            if idx == 1 or idx == 3 then
                deltaY = -30
            elseif idx == 2 then
                deltaY = 20
            end
            UIHelper.SetPositionY(script._rootNode, deltaY)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutCard)

    -- 道具奖励
    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    for _, v in ipairs(tReward.item) do
        local dwType, dwIndex, nCount = table.unpack(v)

        local hItemInfo               = GetItemInfo(dwType, dwIndex)
        local szName                  = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo))
        szName                        = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

        ---@type UIQuestAwardView
        local script                  = UIHelper.AddPrefab(
                PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                szName, nCount, dwType, dwIndex, nil, nil, nil, true
        )
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
        script:SetIconCount(nCount)

        script:SetSingleClickCallback(function(nItemType, nItemIndex)
            TipsHelper.DeleteAllHoverTips()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script._rootNode, nItemType, nItemIndex)
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
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                    szRepuName, nDelta, nil, nil, nil, nil, nil, true
            )
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
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                    szFameName, nDelta, nil, nil, nil, nil, nil, true
            )
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
            UIHelper.SetSpriteFrame(script.scriptItemIcon.ImgIcon, tFameInfo.szVKImagePath)

            script:SetIconCount(nDelta)

            script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
                local szDesc = string.format("【%s】名望增加 %d ", szOriginalFameName, nDelta)
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, script._rootNode, TipsLayoutDir.BOTTOM_CENTER, szDesc)
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewReward)

    -- 成就计数奖励
    UIHelper.SetVisible(self.LabelAchievementHint, table.get_len(tReward.achi) == 0)
    if table.get_len(tReward.achi) > 0 then
        UIHelper.RemoveAllChildren(self.ScrollViewAchievement)

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
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewAchievement,
                    szName, nAddCount, nil, nil, nil, nil, aAchievement.nIconID, true
            )
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

            script:SetIconCount(nAddCount)

            script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
                UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
            end)
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewAchievement)
    end
end

return UITravelInfoPop