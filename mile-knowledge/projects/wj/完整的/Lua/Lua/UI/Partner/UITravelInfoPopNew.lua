-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelInfoPopNew
-- Date: 2025-01-07 16:58:30
-- Desc: 出行事件详情页面
-- Prefab: WidgetTravelInfoPop1
-- ---------------------------------------------------------------------------------

---@class UITravelInfoPopNew
local UITravelInfoPopNew = class("UITravelInfoPopNew")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelInfoPopNew:_LuaBindList()
    self.LabelName        = self.LabelName --- 事件名称
    self.LabelTime        = self.LabelTime --- 事件状态
    self.LayoutCard       = self.LayoutCard --- 侠客卡片的layout
    self.ScrollViewReward = self.ScrollViewReward --- 奖励的scroll view

    self.LayoutBtn        = self.LayoutBtn --- 按钮的layout

    -- 出行中
    self.BtnDel           = self.BtnDel --- 取消出行

    -- 可领取
    self.BtnReward        = self.BtnReward --- 领取奖励

    -- 未出行
    self.BtnChange        = self.BtnChange --- 更改配置
    self.BtnReGo          = self.BtnReGo --- 再次出行
    self.WidgetBtnReset   = self.WidgetBtnReset --- 重置配置按钮的上层节点
    self.BtnReset         = self.BtnReset --- 重置配置

    self.BtnNone          = self.BtnNone --- 用来避免点击时触发全屏遮罩按钮的占位透明按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelInfoPopNew:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param uiPartnerTravelTargetCellNew UIPartnerTravelTargetCellNew
function UITravelInfoPopNew:OnEnter(nBoard, nQuestIndex, uiPartnerTravelTargetCellNew)
    self.nBoard                       = nBoard
    self.nQuestIndex                  = nQuestIndex
    self.uiPartnerTravelTargetCellNew = uiPartnerTravelTargetCellNew

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

function UITravelInfoPopNew:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelInfoPopNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        self:CancelTravel()
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        self:TakeReward()
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        self:ChangeTravelSetting()
    end)

    UIHelper.BindUIEvent(self.BtnReGo, EventType.OnClick, function()
        self:TravelWithLastConfig()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self:ResetTravelSetting()
    end)

    UIHelper.BindUIEvent(self.BtnNone, EventType.OnClick, function()
        Event.Dispatch(EventType.HideAllHoverTips)
    end)
end

function UITravelInfoPopNew:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelInfoPopNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelInfoPopNew:UpdateInfo()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    local tQuestInfo                                      = Table_GetPartnerTravelTask(nQuest)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tQuestInfo.szName))

    self:UpdateState()

    self:UpdatePartnerList(tHeroList)

    self:UpdatePreviewRewardListInfo(nQuest)
end

function UITravelInfoPopNew:UpdateState()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    local szState
    local szFontColor                                     = "#aed9e0"

    if bInTravel then
        local nCurTime       = GetCurrentTime()
        local nRemainingTime = nStart + nMinute * 60 - nCurTime
        local szTime         = TimeLib.GetTimeText(nRemainingTime, nil, true)
        szState              = string.format("剩余：%s", szTime)
        szFontColor          = "#ffe26e"
    elseif bFinished then
        szState     = "可领取"
        szFontColor = "#95ff95"
    elseif bKeepConfigAfterFinished then
        szState = "未出行"
    end

    UIHelper.SetString(self.LabelTime, szState)
    UIHelper.SetColor(self.LabelTime, UIHelper.ChangeHexColorStrToColor(szFontColor))

    UIHelper.SetVisible(self.BtnDel, bInTravel)

    UIHelper.SetVisible(self.BtnReward, bFinished)

    UIHelper.SetVisible(self.BtnChange, bKeepConfigAfterFinished)
    UIHelper.SetVisible(self.BtnReGo, bKeepConfigAfterFinished)
    UIHelper.SetVisible(self.BtnReset, bKeepConfigAfterFinished)

    UIHelper.LayoutDoLayout(self.LayoutBtn)

    UIHelper.SetVisible(self.WidgetBtnReset, bKeepConfigAfterFinished)
end

function UITravelInfoPopNew:UpdatePartnerList(tHeroList)
    UIHelper.RemoveAllChildren(self.LayoutCard)

    for idx, nPartnerID in ipairs(tHeroList) do
        local tInfo  = Table_GetPartnerNpcInfo(nPartnerID)

        ---@type UITravelInfoRoleCard
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoRoleCard, self.LayoutCard, tInfo)

        UIHelper.SetAnchorPoint(script._rootNode, 0, 0.5)
    end

    UIHelper.LayoutDoLayout(self.LayoutCard)
end

local tReputationLevelToName = {
    [0] = "仇恨",
    [1] = "敌视",
    [2] = "疏远",
    [3] = "中立",
    [4] = "友好",
    [5] = "亲密",
    [6] = "敬重",
    [7] = "尊敬",
    [8] = "钦佩",
    [9] = "显赫",
    [10] = "崇敬",
    [11] = "崇拜",
    [12] = "传说",
}

function UITravelInfoPopNew:UpdatePreviewRewardListInfo(nQuest)
    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    local tQuest  = Table_GetPartnerTravelTask(nQuest)

    local tReward = SplitString(tQuest.szGiftItem, ";")
    for _, v in pairs(tReward) do
        local tInfo                   = SplitString(v, "_")
        local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
        nCount                        = nCount or 0

        if tInfo[1] ~= "COIN" then
            --- 道具
            local hItemInfo = GetItemInfo(dwType, dwIndex)
            local szName    = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo, nCount))
            szName          = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

            ---@type UIQuestAwardView
            local script    = UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
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
        else
            --- 货币
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
        local tInfo                       = SplitString(v, "_")
        local nForceId, nMaxLevel, nDelta = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])

        local tRepuInfo                   = Table_GetReputationForceInfo(nForceId)
        local szOriginalRepuName          = UIHelper.GBKToUTF8(tRepuInfo.szName)
        local szRepuName                  = UIHelper.TruncateStringReturnOnlyResult(szOriginalRepuName, 3)

        local szMaxLevelName              = tReputationLevelToName[nMaxLevel]

        ---@type UIQuestAwardView
        local script                      = UIHelper.AddPrefab(
                PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                szRepuName, nDelta, nil, nil, nil, nil, nil, true
        )
        script:OnEnter(szRepuName, nDelta, nil, nil, nil, nil, nil, true)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

        UIHelper.SetTexture(script.scriptItemIcon.ImgIcon, tRepuInfo.szIconPath)

        script:SetIconCount(nDelta)

        script:SetSingleClickCallback(function(nTabType, nTabID, nCount)
            local szDesc = string.format("【%s】声望每次增加%d，直至【%s】", szOriginalRepuName, nDelta, szMaxLevelName)
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

function UITravelInfoPopNew:CancelTravel()
    local dialog = UIHelper.ShowConfirm(string.trim([[
您要取消委托，并返还出行消耗么？
    ]]), function()
        UIHelper.RemoteCallToServer("On_Hero_CancelTravel", {
            { self.nBoard, self.nQuestIndex }
        })

        UIHelper.RemoveAllChildren(self.uiPartnerTravelTargetCellNew.uiPartnerTravelNew.widgetCardInfoAnchor)
    end)

    if dialog then
        dialog:SetConfirmButtonContent("取消委托")
        dialog:SetCancelButtonContent("继续委托")
    end
end

function UITravelInfoPopNew:TakeReward()
    UIHelper.RemoteCallToServer("On_Hero_FinishTravel", {
        { self.nBoard, self.nQuestIndex }
    })
end

function UITravelInfoPopNew:ChangeTravelSetting()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)
    local tQuestInfo                                      = Table_GetPartnerTravelTask(nQuest)

    local nClass                                          = tQuestInfo.nClass

    ---@see UIPartnerTravelSettingView
    UIMgr.Open(VIEW_ID.PanelPartnerTravelSetting, self.nBoard, self.nQuestIndex, nClass)
end

function UITravelInfoPopNew:TravelWithLastConfig()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

    local tCanTravelAgainList                             = {
        { self.nBoard, self.nQuestIndex, nQuest, tHeroList },
    }

    if not PartnerData.CheckTravelCost({ nQuest }) then
        return
    end

    PartnerData.TravelAgain(tCanTravelAgainList)
end

function UITravelInfoPopNew:ResetTravelSetting()
    local tClearList = {
        { self.nBoard, self.nQuestIndex }
    }
    UIHelper.RemoteCallToServer("On_Hero_ClearTravel", tClearList)
end

return UITravelInfoPopNew