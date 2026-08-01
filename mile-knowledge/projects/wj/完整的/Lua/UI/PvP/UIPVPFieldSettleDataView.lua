-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPVPFieldDataView
-- Date: 2022-12-13 11:57:15
-- Desc: 战场实时/结算数据界面 PanelPVPFieldSettleData
-- ---------------------------------------------------------------------------------

---@class UIPVPFieldSettleDataView
local UIPVPFieldSettleDataView = class("UIPVPFieldSettleDataView")

local ORDER_TYPE = {
    NONE = 1,
    DESCENDING = 2, --降序
    ASCENDING = 3, --升序
}

local RICHTEXT_COLOR = "#ffd778"
local m_tbViewStatistics = {}

local tSortKey =	{
    [1] 	= "ForceID",
    [2] 	= "Name",                                       --名字
    [3] 	= PQ_STATISTICS_INDEX.KILL_COUNT,               --协助击伤
    [4] 	= PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT,   --最佳助攻
    [5] 	= PQ_STATISTICS_INDEX.DECAPITATE_COUNT,         --击伤
    [6] 	= PQ_STATISTICS_INDEX.SOLO_COUNT,               --单挑
    [7] 	= PQ_STATISTICS_INDEX.HARM_OUTPUT,              --伤害量
    [8] 	= PQ_STATISTICS_INDEX.TREAT_OUTPUT,             --治疗量
    [9] 	= PQ_STATISTICS_INDEX.INJURY,                   --受伤量
    [10] 	= PQ_STATISTICS_INDEX.DEATH_COUNT,              --受重伤

    --自定义11-14
    [11] 	= PQ_STATISTICS_INDEX.SPECIAL_OP_1,
    [12] 	= PQ_STATISTICS_INDEX.SPECIAL_OP_2,
    [13] 	= PQ_STATISTICS_INDEX.SPECIAL_OP_3,
    [14] 	= PQ_STATISTICS_INDEX.SPECIAL_OP_4,

    --奖励
}

function UIPVPFieldSettleDataView:OnEnter(bBattleFieldEnd, tInfo, tGroupInfo)
    self.bBattleFieldEnd = bBattleFieldEnd
    self.bPageFlag = bBattleFieldEnd --结算后打开默认显示奖励
    self.bReportFlag = false
    self.bNewPlayerBF = MapHelper.GetBattleFieldType() == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE --是否为拭剑园战场
    self.tInfo = tInfo --BattleFieldData: tBattleFieldInfo
    self.tGroupInfo = tGroupInfo or {}
    self.nBanishTime = tInfo.nBanishTime
    self.tStatistics = tInfo.tStatistics

    --print_table(tInfo)

    self.nTeamIndex = 0 -- 0-所有、1-我方阵营、2-敌方阵营...
    self.nSortIndex = 0
    self.nOrder = ORDER_TYPE.NONE

    if not self.bInit then
        local aTitleChildrenLeft = UIHelper.GetChildren(self.LayoutTitleLeft)
        local aTitleChildrenRight = UIHelper.GetChildren(self.LayoutTitleRight)
        self.nTitleChildCountLeft = #aTitleChildrenLeft
        self.nTitleChildCount = #aTitleChildrenLeft + #aTitleChildrenRight

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.m_liveWidgets = {}
        self.m_widgetPlayerPool = self.m_widgetPlayerPool or PrefabPool.New(PREFAB_ID.WidgetPlayer)
    end

    UIHelper.SetSwallowTouches(self.BtnBg, true)
    UIHelper.SetSwallowTouches(self.BtnMask, false)

    self:UpdateInfo()
    self:UpdateSortIconState()
    self:UpdateStatisticsPage()
    self:HideWidgetPlayerTips()

    UIMgr.HideLayer(UILayer.Main)
end

function UIPVPFieldSettleDataView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIMgr.ShowLayer(UILayer.Main)

    if self.m_widgetPlayerPool then self.m_widgetPlayerPool:Dispose() end
    self.m_widgetPlayerPool = nil
end

function UIPVPFieldSettleDataView:BindUIEvent()
    --点击左下阵营按钮筛选
    UIHelper.SetSelected(self.TogAll, true)
    UIHelper.BindUIEvent(self.TogAll, EventType.OnSelectChanged, function(toggle, bSelected)
        if bSelected then
            self.nTeamIndex = 0
            self:UpdateStatisticsPage()
        end
    end)

    for i = 1, BattleFieldData.MAX_BATTLE_FIELD_SIDE_COUNT do
        local toggelTeam = self["TogTeam" .. i]
        local nIndex = i
        UIHelper.BindUIEvent(toggelTeam, EventType.OnSelectChanged, function(toggle, bSelected)
            if bSelected then
                self.nTeamIndex = nIndex
                self:UpdateStatisticsPage()
            end
        end)
        UIHelper.SetSelected(toggelTeam, false)
    end

    local function _initNode(parent, nIndex)
        local btn = parent:getChildByName("BtnTitle" .. nIndex)
        if btn then
            self["Title" .. nIndex] = btn
            local label = btn:getChildByName("LabelTitle" .. nIndex)
            self["LabelTitle" .. nIndex] = label


            --点击标题栏排序
            UIHelper.BindUIEvent(btn, EventType.OnClick, function()
                if self.nSortIndex ~= nIndex then
                    self.nSortIndex = nIndex
                    self.nOrder = ORDER_TYPE.DESCENDING
                else
                    --降序 -> 升序 -> 默认 循环
                    self.nOrder = self.nOrder % 3 + 1
                end
                self:UpdateStatisticsPage()
                self:UpdateSortIconState(btn, label, nIndex)
            end)
        else
            local widget = parent:getChildByName("WidgetTitle" .. nIndex)
            if widget then
                self["Title" .. nIndex] = widget
                self["LabelTitle" .. nIndex] = widget:getChildByName("LabelTitle" .. nIndex)
            end
        end
    end

    for i = 1, self.nTitleChildCountLeft do
        _initNode(self.LayoutTitleLeft, i)
    end
    for i = self.nTitleChildCountLeft + 1, self.nTitleChildCount do
        _initNode(self.LayoutTitleRight, i)
    end

    self:UpdateTitleBasePos()

    --结算时退出战场按钮
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        self:CheckLeaveBattleField()
    end)
    UIHelper.BindUIEvent(self.BtnLeave2, EventType.OnClick, function()
        self:CheckLeaveBattleField()
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAward, EventType.OnClick, function()
        self.bPageFlag = not self.bPageFlag
        self:UpdateTitleState()
        self:UpdateStatisticsPage()
    end)

    UIHelper.BindUIEvent(self.BtnOthers, EventType.OnClick, function()
        self.bPageFlag = not self.bPageFlag
        self:UpdateTitleState()
        self:UpdateStatisticsPage()
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        self.bReportFlag = not self.bReportFlag
        self:UpdateTitleState()
        Event.Dispatch(EventType.BF_WidgetPlayerReportSwitch, self.bReportFlag)
    end)

    UIHelper.BindUIEvent(self.BtnMask, EventType.OnTouchBegan, function()
        self:HideWidgetPlayerTips()
    end)

    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        BattleFieldData.OpenMyRecord()
        if self.tInfo.bUpdateRecord then
            UIHelper.SetVisible(self.ImgRedDot, false)
            self.tInfo.bUpdateRecord = nil
        end
    end)

    UIHelper.BindUIEvent(self.BtnBack2, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPraiseAll, EventType.OnClick, function()
        BattleFieldData.ReqPraiseAll()
    end)
end

function UIPVPFieldSettleDataView:RegEvent()
    Event.Reg(self, "Update_FriendPraiseList", function(nType, tList)
        self:UpdatePraiseAllBtn()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function(nPlayerID)
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetPersonalCard1, false)
    end)
end

function UIPVPFieldSettleDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPVPFieldSettleDataView:Update(tInfo)
    self.tInfo = tInfo
    self.nBanishTime = tInfo.nBanishTime
    self.tStatistics = tInfo.tStatistics
    self:UpdateInfo()
    self:UpdateStatisticsPage()
end

function UIPVPFieldSettleDataView:CheckLeaveBattleField()
    --退出战场
    if self.bBattleFieldEnd then
        BattleFieldData.LeaveBattleField()
    else
        UIHelper.ShowConfirm(g_tStrings.STR_SURE_LEAVE_BATTLE, BattleFieldData.LeaveBattleField)
    end
end

function UIPVPFieldSettleDataView:UpdateWidgetPos()
    --非结算上移一点
    if not self.bBattleFieldEnd == not self.bMove then
        local nOffset = 48
        local nPosY = UIHelper.GetPositionY(self.WidgetAnchorMiddle)
        local nTimePosY = UIHelper.GetPositionY(self.WidgetRemainTime)
        local nBtnPosY = UIHelper.GetPositionY(self.BtnReport)
        if not self.bBattleFieldEnd then
            UIHelper.SetPositionY(self.WidgetAnchorMiddle, nPosY + nOffset)
            UIHelper.SetPositionY(self.WidgetRemainTime, nTimePosY - nOffset)
            UIHelper.SetPositionY(self.BtnReport, nBtnPosY + nOffset)
        else
            UIHelper.SetPositionY(self.WidgetAnchorMiddle, nPosY - nOffset)
            UIHelper.SetPositionY(self.WidgetRemainTime, nTimePosY + nOffset)
            UIHelper.SetPositionY(self.BtnReport, nBtnPosY - nOffset)
        end
        self.bMove = not self.bMove
    end
end

function UIPVPFieldSettleDataView:UpdateInfo()
    --copy端游ACC_BFShowFinal.lua: 822

    self:UpdateWidgetPos()

    --已用时间
    if self.bNewPlayerBF then
        UIHelper.SetVisible(self.WidgetPastTime, false)
        UIHelper.SetVisible(self.WidgetRemainTime, false)
    else
        UIHelper.SetVisible(self.WidgetPastTime, self.bBattleFieldEnd)
        UIHelper.SetVisible(self.WidgetRemainTime, not self.bBattleFieldEnd)
        if self.bBattleFieldEnd then
            local _, _, nBeginTime, nEndTime  = GetBattleFieldPQInfo()
            local nCurrentTime = GetCurrentTime()
            if nBeginTime and nBeginTime > 0 then
                local nTime = 0
                if nEndTime ~= 0 and nCurrentTime > nEndTime then
                    nTime = nEndTime - nBeginTime
                else
                    nTime = nCurrentTime - nBeginTime
                end
                local szTime = self:GetFormatTime(nTime)
                szTime = string.format(g_tStrings.STR_BATTLEFIELD_TIME_USED .. " <color=%s>%s</color>", RICHTEXT_COLOR, szTime)
                UIHelper.SetRichText(self.LabelPastTime, szTime)
            end
        end
    end


    --标题栏
    self:UpdateTitleState()

    --更新左下阵营筛选按钮文字
    for i = 1, BattleFieldData.MAX_BATTLE_FIELD_SIDE_COUNT do
        self:UpdateTogTeamText(i)
    end

    --阵营与排序图标显示
    if (not self.bBattleFieldEnd and self.bNewPlayerBF) or BattleFieldData.IsInFBBattleFieldMap() then
        UIHelper.SetVisible(self.TogAll, false)
    end

    if self.bBattleFieldEnd then
        UIHelper.SetString(self.LabelLeave, g_tStrings.STR_LEAVE_BATTLEFIELD) --退出战场按钮文字: "离开战场"

        --胜利/失败
        local bWin = self.tInfo.bWin
        UIHelper.SetVisible(self.ImgVictoryBgLight, bWin)
        UIHelper.SetVisible(self.ImgVictory, bWin)
        UIHelper.SetVisible(self.ImgDefeatBgLight, not bWin)
        UIHelper.SetVisible(self.ImgDefeat, not bWin)

        --Toggle选中玩家所在阵营
        self.nTeamIndex = self.tInfo.nClientPlayerSide or 0
        UIHelper.SetToggleGroupSelected(self.WidgetLeftDown, self.nTeamIndex)

        --倒计时
        self:SetCountDown(self.nBanishTime)
    else
        UIHelper.SetString(self.LabelLeave, g_tStrings.STR_FORCE_LEAVE_BATTLEFIELD) --退出战场按钮文字: "强制离开战场"

        UIHelper.SetVisible(self.ImgVictoryBgLight, false)
        UIHelper.SetVisible(self.ImgDefeatBgLight, false)
        UIHelper.SetVisible(self.ImgVictory, false)
        UIHelper.SetVisible(self.ImgDefeat, false)

        local _, _, _, nEndTime  = GetBattleFieldPQInfo()
        self:SetCountDown(nEndTime)
    end

    --UIHelper.SetVisible(self.LabelTime, self.bBattleFieldEnd)
    UIHelper.SetVisible(self.RichTextTime, self.bBattleFieldEnd)
    UIHelper.SetVisible(self.BtnBack, not self.bBattleFieldEnd)
    UIHelper.SetVisible(self.BtnLeave, not self.bBattleFieldEnd)
    UIHelper.SetVisible(self.BtnBack2, self.bBattleFieldEnd and not self.bNewPlayerBF and not BattleFieldData.IsInTongWarFieldMap() and not BattleFieldData.IsInFBBattleFieldMap())
    UIHelper.SetVisible(self.BtnRecord, self.bBattleFieldEnd and not self.bNewPlayerBF)
    UIHelper.SetVisible(self.BtnLeave2, self.bBattleFieldEnd)

    UIHelper.SetVisible(self.ImgRedDot, self.tInfo.bUpdateRecord or false)

    self:UpdatePraiseAllBtn()
end

function UIPVPFieldSettleDataView:UpdatePraiseAllBtn()
    UIHelper.SetVisible(self.BtnPraiseAll, self.bBattleFieldEnd and table.get_len(self.tInfo.tPraiseList) > 0 and not self.bNewPlayerBF)
    UIHelper.SetButtonState(self.BtnPraiseAll, table.get_len(BattleFieldData.GetPraisePlayerTable()) > 0 and BTN_STATE.Normal or BTN_STATE.Disable, "我方暂无优秀表现侠士")
end

function UIPVPFieldSettleDataView:UpdateTogTeamText(nIndex)
    local togTeam = self["TogTeam" .. nIndex]
    local szName = self.tGroupInfo[nIndex] or ""
    if not togTeam then
        return
    end
    if (not self.bBattleFieldEnd and self.bNewPlayerBF) or szName == "" then
        UIHelper.SetVisible(togTeam, false)
    else
        UIHelper.SetVisible(togTeam, true)
        local labelTeam = togTeam:getChildByName("LabelData")
        local labelTeamUp = togTeam:getChildByName("WidgetUp/LabelDataUp")
        UIHelper.SetString(labelTeam, UIHelper.GBKToUTF8(szName))
        UIHelper.SetString(labelTeamUp, UIHelper.GBKToUTF8(szName))
    end
end

function UIPVPFieldSettleDataView:UpdateStatisticsPage()
    if not self.tStatistics then return end

    local player = GetClientPlayer()
    if not player then return end

    m_tbViewStatistics = {}
    local dwPlayerID = player.dwID
    local dwLeaderID = self.tInfo.dwLeaderID

    --按阵营显示
    for i = 1, #self.tStatistics do
        local tLine = self.tStatistics[i]
        if self.nTeamIndex == 0 or tLine.nBattleFieldSide == self.nTeamIndex then
            table.insert(m_tbViewStatistics, tLine)
        end
    end

    --排序
    if self.nOrder ~= ORDER_TYPE.NONE and self.nSortIndex > 0 then
        local funcSort = function(tLeft, tRight)
            if not tLeft or not tRight then
                return false
            end
            if not tSortKey[self.nSortIndex] then
                return
            end
            local key = tSortKey[self.nSortIndex]
            if self.nOrder == ORDER_TYPE.ASCENDING then
                return tLeft[key] < tRight[key]
            else
                return tLeft[key] > tRight[key]
            end
        end
        table.sort(m_tbViewStatistics, funcSort)
    else
        --自己第一，团长第二
        local funcSort = function(tLeft, tRight)
            if not tLeft or not tRight then
                return false
            end
            if tLeft.dwPlayerID == dwPlayerID then
                return true
            end
            if tRight.dwPlayerID == dwPlayerID then
                return false
            end
            if tLeft.dwPlayerID == dwLeaderID then
                return true
            end
            if tRight.dwPlayerID == dwLeaderID then
                return false
            end
            local nLeft = tLeft.nExcellentCount or 0
            local nRight = tRight.nExcellentCount or 0
            return nLeft > nRight
        end
        table.sort(m_tbViewStatistics, funcSort)
    end

    self:RefreshPrefabCount(#m_tbViewStatistics, self.m_liveWidgets, self.m_widgetPlayerPool, self.ScrollViewDataList)
    Event.Dispatch(EventType.BF_WidgetPlayerUpdate)
    --LOG.TABLE(m_tbViewStatistics)
end

--根据索引获取统计数据
function UIPVPFieldSettleDataView:GetViewStatisticsData(nIndex)
    return m_tbViewStatistics[nIndex]
end

function UIPVPFieldSettleDataView:GetItemKey(nIndex)
    return tSortKey[nIndex]
end

function UIPVPFieldSettleDataView:HideWidgetPlayerTips()
    self.bWidgetPlayerTipsShow = false
    UIHelper.SetVisible(self.WidgetFront, false)
    Event.Dispatch(EventType.BF_WidgetPlayerHideTips)
end

function UIPVPFieldSettleDataView:SetWidgetPlayerTipsShowState()
    UIHelper.SetVisible(self.WidgetFront, true)
    self.bWidgetPlayerTipsShow = true
end

function UIPVPFieldSettleDataView:CreateTipsItem(parent, szIconPath, szName)
    if not szName or not szIconPath then return end

    local tipsItem = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsItem, parent)
    local img = tipsItem:getChildByName("ImgTipsIcon")
    local label = tipsItem:getChildByName("LabelTips")
    UIHelper.SetSpriteFrame(img, szIconPath)
    UIHelper.SetString(label, szName)
end

function UIPVPFieldSettleDataView:RemoveTipsItem(parent)
    local tipsItems = UIHelper.GetChildren(parent)
    if tipsItems then
        local nChildCount = #tipsItems
        for i = nChildCount, 1, -1 do
            local tipsItem = tipsItems[i]
            UIHelper.RemoveFromParent(tipsItem)
        end
    end
end

--更新排序图标显示位置
function UIPVPFieldSettleDataView:UpdateSortIconState(btn, label, nIndex)
    if not btn or not nIndex then
        self.nOrder = ORDER_TYPE.NONE
    end
    if self.nOrder == ORDER_TYPE.NONE then
        UIHelper.SetVisible(self.ImgIconBg, false)
        self.bImgIconBgVisible = false
        return
    end

    local nTxtPosX = UIHelper.GetPosition(label)
    local nTxtSizeX, _ = UIHelper.GetContentSize(label)
    local nAnchX, _ = UIHelper.GetAnchorPoint(label)
    local nPosX = nTxtPosX + nTxtSizeX * (1 - nAnchX) --文字最右边缘的x值
    local nOffsetX, nOffsetY = 10, -2 --显示偏移
    local nRotate = 0
    if self.nOrder == ORDER_TYPE.ASCENDING then
        nOffsetY = -nOffsetY
        nRotate = 180
    end

    UIHelper.SetVisible(self.ImgIconBg, true)
    UIHelper.SetParent(self.ImgIconBg, btn)
    UIHelper.SetPosition(self.ImgIconBg, nPosX + nOffsetX, nOffsetY)
    UIHelper.SetRotation(self.ImgIconBg, nRotate)
    self.bImgIconBgVisible = true
end

function UIPVPFieldSettleDataView:UpdateTitleState()
    --未结束不显示优秀表现和奖励按钮
    UIHelper.SetVisible(self.BtnAward, self.bBattleFieldEnd and not self.bNewPlayerBF)
    UIHelper.SetVisible(self.BtnReport, not self.bNewPlayerBF)
    UIHelper.SetVisible(self.Title2, self.bBattleFieldEnd)

    UIHelper.SetVisible(self.Title15, self.bPageFlag and self.bBattleFieldEnd and not self.bNewPlayerBF)
    if self.bPageFlag then
        UIHelper.SetString(self.LabelAward, "查看详情")
    else
        UIHelper.SetString(self.LabelAward, "查看奖励")
    end

    if self.bReportFlag then
        UIHelper.SetSpriteFrame(self.ImgReport, "UIAtlas2_Public_PublicButton_PublicButton1_btn_Recall")
        if self.bBattleFieldEnd then
            UIHelper.SetString(self.LabelReport, "队友点赞")
        else
            UIHelper.SetString(self.LabelReport, "取消举报")
        end
    else
        UIHelper.SetSpriteFrame(self.ImgReport, "UIAtlas2_Public_PublicButton_PublicButton1_btn_warning")
        UIHelper.SetString(self.LabelReport, "信誉举报")
    end

    --1: 门派+名字；2: 优秀表现；3~10: 基础数据；11~14: 自定义数据；15: 奖励

    --伤害量、治疗量、受伤量、受重伤随奖励一起显示
    for i = 7, 10 do
        local title = self["Title" .. i]
        UIHelper.SetVisible(title, self.bPageFlag or not self.bBattleFieldEnd or self.bNewPlayerBF)
    end

    local nSpecialCount = 0
    local tPQOptionInfo = Table_GetBattleFieldPQOptionInfo(self.tInfo.dwMapID)
    for i = 1, 4 do
        local title = self["Title" .. (10 + i)]
        local labelTitle = self["LabelTitle" .. (10 + i)]
        local szTitle = tPQOptionInfo and UIHelper.GBKToUTF8(tPQOptionInfo["szPQOptionName" .. i])
        if szTitle and #szTitle > 0 then
            UIHelper.SetString(labelTitle, szTitle)
            UIHelper.SetVisible(title, not self.bPageFlag or self.BattleFieldEnd)
            nSpecialCount = nSpecialCount + 1
        else
            UIHelper.SetVisible(title, false)
        end
    end

    --特殊处理，若未结算且自定义数据大于等于3，则也做切页；否则标题栏会叠起来
    if nSpecialCount >= 3 and not self.bBattleFieldEnd and not self.bNewPlayerBF then
        UIHelper.SetVisible(self.BtnOthers, true)
        if self.bPageFlag then
            UIHelper.SetString(self.LabelOthers, "上一页")
        else
            UIHelper.SetString(self.LabelOthers, "下一页")
        end

        for i = 3, 10 + nSpecialCount do
            local title = self["Title" .. i]
            UIHelper.SetVisible(title, not self.bPageFlag)
        end

        for i = 11, 10 + nSpecialCount do
            local title = self["Title" .. i]
            UIHelper.SetVisible(title, self.bPageFlag)
        end
    else
        UIHelper.SetVisible(self.BtnOthers, false)
    end

    --cocos自己的问题，当设置Button的Visible状态时，会将其所有子节点设为相同显隐状态；
    --所以这里恢复一下升序降序图标的显隐状态
    UIHelper.SetVisible(self.ImgIconBg, self.bImgIconBgVisible)

    --重置下y轴位置，DoLayout只会刷x轴
    UIHelper.SetPositionY(self.BtnReport, 0)
    UIHelper.SetPositionY(self.BtnAward, 0)
    UIHelper.SetPositionY(self.BtnOthers, 0)

    --Layout
    UIHelper.LayoutDoLayout(self.LayoutTitleLeft)
    UIHelper.LayoutDoLayout(self.LayoutTitleRight)
    UIHelper.WidgetFoceDoAlign(self)
    self:UpdateTitleBasePos()
end

--记录每个Title的基准位置
function UIPVPFieldSettleDataView:UpdateTitleBasePos()
    if not self.tTitlePosX then
        self.tTitlePosX = {}
    end

    for i = 1, self.nTitleChildCount do
        local node = self["Title" .. i]
        if node then
            local nPosX, _ = UIHelper.GetWorldPosition(node)
            self.tTitlePosX[i] = nPosX
        end
    end
end

function UIPVPFieldSettleDataView:SetCountDown(nEndTime)
    Timer.DelAllTimer(self)
    if not nEndTime then
        return
    end

    self.m_nLeftTimer = nEndTime - GetCurrentTime()
    if self.m_nLeftTimer < 0 then
        self.m_nLeftTimer = 0
    end
    self:UpdateTimeView()

    --倒计时
    if self.m_nLeftTimer > 0 then
        Timer.AddCountDown(self, self.m_nLeftTimer, function()
            self.m_nLeftTimer = self.m_nLeftTimer - 1
            self:UpdateTimeView()
        end)
    end
end

function UIPVPFieldSettleDataView:UpdateTimeView()
    if self.bBattleFieldEnd then
        --UIHelper.SetString(self.LabelNum, tostring(self.m_nLeftTimer))
        UIHelper.SetRichText(self.RichTextTime, string.format("<color=#d7f6ff>将在<color=#ffe26e>%d秒</c>后传出战场</c>", self.m_nLeftTimer))
    else
        local szTime = self:GetFormatTime(self.m_nLeftTimer)
        szTime = string.format(g_tStrings.STR_BATTLEFIELD_TIME_LEFT .. " <color=%s>%s</color>", RICHTEXT_COLOR, szTime)
        UIHelper.SetRichText(self.LabelRemainTime, szTime)
    end
end

function UIPVPFieldSettleDataView:GetFormatTime(nTime)
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText..nM.."分"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS.."秒"

    return szTimeText
end

--刷新Prefab数量
function UIPVPFieldSettleDataView:RefreshPrefabCount(nCount, aLiveNodes, pool, scrollView)
    --刷新ScrollView
    local function _scrollViewRefresh(sv)
        UIHelper.ScrollViewDoLayout(sv)
        UIHelper.ScrollToTop(sv)
    end

    if #aLiveNodes < nCount then
        while #aLiveNodes < nCount do
            local node = pool:Allocate(scrollView, #aLiveNodes + 1, self)
            table.insert(aLiveNodes, node)
        end
        _scrollViewRefresh(scrollView)
    elseif #aLiveNodes > nCount then
        while #aLiveNodes > nCount do
            local node = table.remove(aLiveNodes)
            pool:Recycle(node)
        end
        _scrollViewRefresh(scrollView)
    end
end

return UIPVPFieldSettleDataView
