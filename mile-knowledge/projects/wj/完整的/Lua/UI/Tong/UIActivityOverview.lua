-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIActivityOverview
-- Date: 2023-05-18 11:09:34
-- Desc: 帮会活动-活动概览
-- Prefab: WidgetActivityOverview
-- ---------------------------------------------------------------------------------

---@class UIActivityOverview
local UIActivityOverview = class("UIActivityOverview")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIActivityOverview:_LuaBindList()
    self.TogCompare                 = self.TogCompare --- 控制右侧详情区域是否显示的toggle

    self.LabelActivityState         = self.LabelActivityState --- 状态（正在进行中、尚未开启、已结束）
    self.LabelParticipantLevel      = self.LabelParticipantLevel --- 参与等级（仅在等级不满足时显示）
    self.LabelActivityName          = self.LabelActivityName --- 名称

    self.ImgActivityFrequency       = self.ImgActivityFrequency --- 周期背景（仅在需要展示周期时显示）
    self.LabelActivityFrequency     = self.LabelActivityFrequency --- 周期描述

    self.LayoutActivityTimeAndPlace = self.LayoutActivityTimeAndPlace --- 时间地点的顶层layout
    self.LabelActivityTime          = self.LabelActivityTime --- 时间
    self.LabelActivityPlace         = self.LabelActivityPlace --- 地点

    self.BtnAttend                  = self.BtnAttend --- 前往参与 按钮
    self.BtnStartActivity           = self.BtnStartActivity --- 开启活动 按钮

    self.ScrollViewAward            = self.ScrollViewAward --- 奖励的ScrollView

    self.ScrollViewActivityDetail   = self.ScrollViewActivityDetail --- 详情区域的ScrollView

    self.WidgetScrollViewTips       = self.WidgetScrollViewTips --- 多个导航的组件
    self.ScrollViewActivity         = self.ScrollViewActivity --- 导航单元的ScrollView
    self.BtnCloseTips               = self.BtnCloseTips --- 隐藏导航组件

    self.ImgFactionActivityIcon     = self.ImgFactionActivityIcon --- 活动图标

    self.WidgetRightSideDetail      = self.WidgetRightSideDetail --- 右侧详情的顶层widget

    self.ImgJingxingzhong           = self.ImgJingxingzhong --- 状态背景图-正在进行中
    self.ImgWeikaishi               = self.ImgWeikaishi --- 状态背景图-未开启
    self.ImgDengdaikaiqi            = self.ImgDengdaikaiqi --- 状态背景图-前往开启

    self.WidgetArrow                = self.WidgetArrow --- 超过一屏时的提示箭头
end

function UIActivityOverview:OnEnter(tClass, bShowDetail)
    self.tClass      = tClass
    self.bShowDetail = bShowDetail

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIActivityOverview:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIActivityOverview:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnStartActivity, EventType.OnClick, function()
        self:StartActivity()
    end)

    UIHelper.BindUIEvent(self.BtnAttend, EventType.OnClick, function()
        self:AttendActivity()
    end)

    UIHelper.BindUIEvent(self.BtnCloseTips, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetScrollViewTips, false)
    end)
end

function UIActivityOverview:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "On_Tong_GetActivityTimeRespond", function()
        self:UpdateInfo()
    end)

    -- Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
    --     UIHelper.SetPosition(self._rootNode, 0, 0)
    -- end)
end

function UIActivityOverview:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local tClassID2State        = {
    [1] = "正在进行中",
    [4] = "正在进行中",
    [5] = "需前往领地开启",
    [6] = "尚未开始",
    [7] = "需前往领地开启",
    [8] = "需前往领地开启",
    [9] = "世界首领击败后开启",
    [11] = "前往对应地图开启",
}

local tStateImg             = {
    Opening = 1, -- 正在进行中
    NotOpen = 2, -- 前往开启
    GoOpen = 3, -- 未开启
}

local tClassID2StateImg     = {
    [1] = tStateImg.Opening,
    [4] = tStateImg.Opening,
    [5] = tStateImg.GoOpen,
    [6] = tStateImg.NotOpen,
    [7] = tStateImg.GoOpen,
    [8] = tStateImg.GoOpen,
    [9] = tStateImg.GoOpen,
    [11] = tStateImg.GoOpen,
}

local MAX_PLACE_SHOW_LENGTH = 22
local MAX_PLACE_TRUNCATION  = "..."

function UIActivityOverview:UpdateInfo()
    self:UpdateInfoBasic()

    UIHelper.SetVisible(self.WidgetRightSideDetail, self.bShowDetail)
    if self.bShowDetail then
        self:UpdateInfoDetail()
    end
end

function UIActivityOverview:UpdateInfoBasic()
    local tClass = self.tClass
    if not tClass then
        return
    end

    local nClassID    = tClass.tInfo.dwClassID
    local nSubClassID = tClass.tInfo.dwSubClassID

    local tRecord     = Table_GetTongActivityContent(nClassID, nSubClassID, 0)

    UIHelper.SetItemIconByIconID(self.ImgFactionActivityIcon, tRecord.dwIconID)

    local szName = string.format("【%s】", UIHelper.GBKToUTF8(tRecord.szName))
    UIHelper.SetString(self.LabelActivityName, szName)

    if tRecord.szTime ~= "" then
        UIHelper.SetString(self.LabelActivityTime, UIHelper.GBKToUTF8(tRecord.szTime))
    end

    if tRecord.szPlace ~= "" then
        local szFullPlace         = UIHelper.GBKToUTF8(tRecord.szPlace)
        local bTruncated, szPlace = UIHelper.TruncateString(szFullPlace, MAX_PLACE_SHOW_LENGTH, MAX_PLACE_TRUNCATION)

        UIHelper.SetString(self.LabelActivityPlace, szPlace)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutActivityTimeAndPlace, true, true)

    local bShowFrequency = tRecord.szCycle ~= ""
    UIHelper.SetVisible(self.ImgActivityFrequency, bShowFrequency)
    UIHelper.SetVisible(self.LabelActivityFrequency, bShowFrequency)
    UIHelper.SetString(self.LabelActivityFrequency, UIHelper.GBKToUTF8(tRecord.szCycle))

    -- 正在进行中、尚未开启、已结束
    local szState   = ""
    local nStateImg = nil

    -- 若有服务器下发的活动信息中，任意一个该类别的活动处于开启状态，则显示为正在进行中
    local bAnyOpen  = TongData.IsAnyActivityOpenOfClassID(nClassID)
    if bAnyOpen then
        szState   = "正在进行中"
        nStateImg = tStateImg.Opening
    end

    -- 若均未开启，且下发的数据中有该类别的主活动，则使用该状态
    local tActivityTimeData = TongData.GetActivityTimeDataByClassID(nClassID, nSubClassID)
    if tActivityTimeData and szState == "" then
        local nFlag = tActivityTimeData.nFlag
        if nFlag == TongData.ACTIVITY_STATE.NotOpen then
            szState   = "尚未开启"
            nStateImg = tStateImg.NotOpen
        elseif nFlag == TongData.ACTIVITY_STATE.Opening then
            szState   = "正在进行中"
            nStateImg = tStateImg.Opening
        elseif nFlag == TongData.ACTIVITY_STATE.Closed then
            szState   = "已结束"
            nStateImg = nil
        end
    end

    -- 如果没有相关信息，则使用主活动的默认状态
    if szState == "" then
        local szDefaultState = tClassID2State[nClassID]
        if szDefaultState then
            szState = szDefaultState
        else
            szState = "正在进行中"
        end

        nStateImg = tClassID2StateImg[nClassID]
    end

    UIHelper.SetString(self.LabelActivityState, szState)

    if nStateImg == tStateImg.GoOpen or nStateImg == tStateImg.Opening then
        UIHelper.SetTextColor(self.LabelActivityState, cc.c3b(255, 255, 255))
    elseif nStateImg == tStateImg.NotOpen then
        UIHelper.SetTextColor(self.LabelActivityState, cc.c3b(215, 246, 255))
    end

    UIHelper.SetVisible(self.ImgJingxingzhong, nStateImg == tStateImg.Opening)
    UIHelper.SetVisible(self.ImgWeikaishi, nStateImg == tStateImg.NotOpen)
    UIHelper.SetVisible(self.ImgDengdaikaiqi, nStateImg == tStateImg.GoOpen)

    local nJoinLevel = tonumber(tRecord.szJoinlevelMobile)
    local nLevel     = g_pClientPlayer.nLevel
    if nLevel < nJoinLevel then
        UIHelper.SetVisible(self.LabelParticipantLevel, true)
        UIHelper.SetString(self.LabelParticipantLevel, string.format("%d级开启", nJoinLevel))
    else
        UIHelper.SetVisible(self.LabelParticipantLevel, false)
    end
end

function UIActivityOverview:UpdateInfoDetail()
    local tClass = self.tClass
    if not tClass then
        return
    end

    local nClassID    = tClass.tInfo.dwClassID
    local nSubClassID = tClass.tInfo.dwSubClassID

    local tRecord     = Table_GetTongActivityContent(nClassID, nSubClassID, 0)

    UIHelper.SetVisible(self.BtnAttend, false)
    UIHelper.SetVisible(self.BtnStartActivity, false)
    local bNotOpening = TongData.IsAnyActivityInStateOfClassID(nClassID, TongData.ACTIVITY_STATE.NotOpen)
    if tRecord.bCanOpen and bNotOpening then
        UIHelper.SetVisible(self.BtnStartActivity, true)
    else
        if bNotOpening then
            UIHelper.SetVisible(self.BtnAttend, true)

            --- 在帮会领地内时，隐藏前往参与的按钮
            if nClassID == 1 and TongData.IsInDemesne() then
                UIHelper.SetVisible(self.BtnAttend, false)
            end
        elseif tRecord.szLinkIDList ~= "" then
            UIHelper.SetVisible(self.BtnAttend, true)
        end
    end

    self:UpdateRewardList()

    self:UpdateDetail()
end

function UIActivityOverview:StartActivity()
    local nClassID    = self.tClass.tInfo.dwClassID
    local nSubClassID = self.tClass.tInfo.dwSubClassID

    TongData.StartActivity(nClassID, nSubClassID)
end

function UIActivityOverview:AttendActivity()
    local nClassID     = self.tClass.tInfo.dwClassID
    local nSubClassID  = self.tClass.tInfo.dwSubClassID

    -- 世界BOSS打开千里伐逐界面，与其他的不同
    local nIDWorldBoss = 9
    if nClassID == nIDWorldBoss then
        ---@see UIPVPFieldView#OnEnter
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu, true)
        return
    end

    local tRecord = Table_GetTongActivityContent(nClassID, nSubClassID, 0)
    local player  = GetClientPlayer()
    if player and player.nLevel < 110 and nClassID == 4 then
        --特判钓鱼活动玩家等级
        TipsHelper.ShowNormalTip("侠士达到110级后方可参与帮会钓鱼")
        return
    end

    local bOpening = TongData.IsAnyActivityOpenOfClassID(nClassID)
    if not bOpening and not tRecord.bCanOpen then
        if nClassID == 1 then
            --- 帮会家园特殊处理下，引导前往帮会领地
            if TongData.IsDemesnePurchased() then
                local enterTongMap = function()
                    MapMgr.CheckTransferCDExecute(function()
                        UIMgr.Close(VIEW_ID.PanelFactionManagement)
                        RemoteCallToServer("On_Tong_ToTongMapDetection")
                    end)
                end

                --地图资源下载检测拦截
                if not PakDownloadMgr.UserCheckDownloadMapRes(TongData.DEMESNE_MAP_ID, enterTongMap) then
                    return
                end

                enterTongMap()
            else
                TongData.ShowDemesneNpcMenu(self.WidgetScrollViewTips)
            end
            return
        end

        -- 未开启的自动开启活动在活动的详情界面内 点击按键浮动提示“活动暂未开启”
        TipsHelper.ShowNormalTip("活动暂未开启")
        return
    end

    if tRecord.szLinkIDList == "" then
        return
    end

    local tLinkIDList = string.split(tRecord.szLinkIDList, ";")

    local tTargetList = {}
    for _, szID in ipairs(tLinkIDList) do
        local nLinkID      = tonumber(szID)
        local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
        for _, tInfo in pairs(tAllLinkInfo) do
            table.insert(tTargetList, tInfo)
        end
    end

    if #tTargetList == 1 then
        local tLink  = tTargetList[1]

        local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
        MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
    else
        UIHelper.SetVisible(self.WidgetScrollViewTips, true)

        UIHelper.RemoveAllChildren(self.ScrollViewActivity)

        for _, tLink in ipairs(tTargetList) do
            local szNpcName    = UIHelper.GBKToUTF8(tLink.szNpcName)
            local szMapName    = UIHelper.GBKToUTF8(Table_GetMapName(tLink.dwMapID))
            local szTargetName = string.format("%s (%s)", szNpcName, szMapName)

            local script       = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForTipsBtn, self.ScrollViewActivity)
            script:OnEnter(szTargetName)

            UIHelper.BindUIEvent(script.BtnLeaveFor, EventType.OnClick, function()
                local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
                MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
                UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
            end)
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewActivity)
        UIHelper.ScrollToTop(self.ScrollViewActivity, 0, false)
    end
end

--- 奖励相关的字段名称列表
local tAwardKeyNameList = {
    "money",
    "experience",
    "justice",
    "prestige",
    "titlepoint",
    "exteriorpiece",
    "train",
    "vigor",
    "tongfund",
    "tongresource",
    "exitem1",
    "exitem2",
    "exitem3",
    "exitem4",
}

function UIActivityOverview:UpdateRewardList()
    UIHelper.RemoveAllChildren(self.ScrollViewAward)

    local nClassID    = self.tClass.tInfo.dwClassID
    local nSubClassID = self.tClass.tInfo.dwSubClassID

    local tRecord     = Table_GetTongActivityContent(nClassID, nSubClassID, 0)

    -- 过滤出所有配置了值的奖励字段
    local tbAwardInfo = {}
    for _, szAwardName in ipairs(tAwardKeyNameList) do
        local value = tRecord[szAwardName]
        if (type(value) == "number" and value > 0) or (type(value) == "string" and value ~= "") then
            table.insert(tbAwardInfo, { ["szType"] = szAwardName, ["szCount"] = value })
        end
    end

    for _, AwardInfo in ipairs(tbAwardInfo) do
        local script

        if type(AwardInfo.szCount) == "number" then
            local tLine  = Table_GetCalenderActivityAwardIcon(AwardInfo.szType)
            local szName = UIHelper.GBKToUTF8(tLine.szDes)
            local nCount = AwardInfo.szCount
            if szName == g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY then
                nCount = nCount * 10000
            end
            script = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.ScrollViewAward, szName, nCount)
        elseif type(AwardInfo.szCount) == "string" then
            local tBox         = string.split(AwardInfo.szCount, ";")
            local nItemTabType = tBox[1]
            local nItemIndex   = tBox[2]
            local nCount       = tonumber(tBox[3]) or 0
            local ItemInfo     = GetItemInfo(nItemTabType, nItemIndex)
            if ItemInfo then
                local szName = UIHelper.GBKToUTF8(ItemInfo.szName)
                script       = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.ScrollViewAward, szName, nCount, nItemTabType, nItemIndex)
            end
        end

        if script then
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

            script:SetClickCallback(function(nTabType, nTabID)
                TipsHelper.ShowItemTips(script._rootNode, nTabType, nTabID, false)
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    UIHelper.ScrollToLeft(self.ScrollViewAward, 0)
end

function UIActivityOverview:UpdateDetail()
    UIHelper.RemoveAllChildren(self.ScrollViewActivityDetail)

    local nClassID     = self.tClass.tInfo.dwClassID
    local nSubClassID  = self.tClass.tInfo.dwSubClassID

    local tRecord      = Table_GetTongActivityContent(nClassID, nSubClassID, 0)

    ---@class TongActivityUIInfo
    ---@field szName string
    ---@field szDesc string
    ---@field nSubClassID number

    ---@type TongActivityUIInfo[]
    local tActInfoList = {}

    if tRecord.szJoinNPC ~= "" then
        table.insert(tActInfoList, {
            szName = "报名地点",
            szDesc = UIHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(tRecord.szJoinNPC)),
        })
    end

    table.insert(tActInfoList, {
        szName = "内容",
        szDesc = UIHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(tRecord.szContent)),
    })

    -- 子活动
    local tTongActivity = Table_GetTongActivityList()
    local tClass        = tTongActivity[nClassID]
    if tClass and tClass.tList then
        for _, tSub in ipairs(tClass.tList) do
            local tSubRecord = Table_GetTongActivityContent(tSub.tInfo.dwClassID, tSub.tInfo.dwSubClassID, 0)

            local szName     = UIHelper.GBKToUTF8(tSubRecord.szName)
            local szDesc     = UIHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(tSubRecord.szContent))

            table.insert(tActInfoList, {
                szName = szName,
                szDesc = szDesc,
                nSubClassID = tSub.tInfo.dwSubClassID,
            })
        end
    end

    for _, tAct in ipairs(tActInfoList) do
        -- note: 这里不使用FirstOnEnter来传入参数并自动调用OnEnter，是因为这个机制会延迟一帧，这样的话，延迟一帧排版scroll view才可以。
        -- note: 但是这样会很晦涩，所以改为取消这个选项，并手动调用OnEnter，确保代码更直观，没有隐藏的规则
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityDetailCell, self.ScrollViewActivityDetail)
        script:OnEnter(tAct.szName, tAct.szDesc, tAct.nSubClassID)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivityDetail)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewActivityDetail, self.WidgetArrow)
end

return UIActivityOverview