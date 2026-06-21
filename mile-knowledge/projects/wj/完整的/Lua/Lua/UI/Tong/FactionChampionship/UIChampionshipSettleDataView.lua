-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChampionshipSettleDataView
-- Date: 2024-08-01 16:47:27
-- Desc: 帮会联赛数据/结算界面
-- Prefab: PanelChampionshipSettleData
-- ---------------------------------------------------------------------------------

local ORDER_TYPE                   = {
    NONE = 1,
    DESCENDING = 2, --降序
    ASCENDING = 3, --升序
}

local RICHTEXT_COLOR               = "#ffe26e"

--- 经过筛选过滤后的玩家数据
---@type BattleFieldStatistics[]
local m_tbViewStatistics           = {}

--- 标题栏总数
local TOTAL_TITLE_COUNT            = 15

local tSortKey                     = {
    --[1] = "Name", --名字
    --[2] = "Excellent-TODO", --优秀表现
    [3] = PQ_STATISTICS_INDEX.KILL_COUNT, --协助击伤
    [4] = PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT, --最佳助攻
    [5] = PQ_STATISTICS_INDEX.DECAPITATE_COUNT, --击伤
    [6] = PQ_STATISTICS_INDEX.SOLO_COUNT, --单挑
    [7] = PQ_STATISTICS_INDEX.HARM_OUTPUT, --伤害量
    [8] = PQ_STATISTICS_INDEX.TREAT_OUTPUT, --治疗量
    [9] = PQ_STATISTICS_INDEX.INJURY, --受伤量
    [10] = PQ_STATISTICS_INDEX.DEATH_COUNT, --受重伤

    [11] = PQ_STATISTICS_INDEX.SPECIAL_OP_1, --身份

    --[12] = PQ_STATISTICS_INDEX.AWARD_1 | PQ_STATISTICS_INDEX.AWARD_2, --奖励

    [13] = PQ_STATISTICS_INDEX.SPECIAL_OP_2, --击退麒麟
    [14] = PQ_STATISTICS_INDEX.SPECIAL_OP_3, --麒麟珠
    [15] = PQ_STATISTICS_INDEX.SPECIAL_OP_4, --野怪
}

local tTongWarBattleInfoConfig     = {}

---@class UIChampionshipSettleDataView
local UIChampionshipSettleDataView = class("UIChampionshipSettleDataView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChampionshipSettleDataView:_LuaBindList()
    self.BtnClose                    = self.BtnClose                     --- 关闭按钮
    self.BtnLeave                    = self.BtnLeave                     --- 离开战场按钮
    self.LabelLeave                  = self.LabelLeave                   --- 离开战场的label
    self.LabelPastTime               = self.LabelPastTime                --- 已用时间（结束）/剩余时间（玩法中）的RichText
    self.RichTextTime                = self.RichTextTime                 --- 结束时自动传出战场的倒计时
    self.WidgetVictory               = self.WidgetVictory                --- 胜利的图片
    self.ImgVictoryBgLight           = self.ImgVictoryBgLight            --- 胜利的高光背景图
    self.WidgetDefeat                = self.WidgetDefeat                 --- 失败的图片
    self.ImgDefeatBgLight            = self.ImgDefeatBgLight             --- 失败的高光背景图
    self.ScrollViewDataList          = self.ScrollViewDataList           --- 玩家数据组件的scroll view
    self.WidgetLeftDown              = self.WidgetLeftDown               --- 左下角的筛选项的上层widget（toggle group和layout）
    self.TogAll                      = self.TogAll                       --- 左下角toggle - 全部
    self.TogTeamBlue                 = self.TogTeamBlue                  --- 左下角toggle -蓝方
    self.TogTeamRed                  = self.TogTeamRed                   --- 左下角toggle - 红方
    self.TogSchoolAccount            = self.TogSchoolAccount             --- 左下角toggle - 门派统计
    self.WidgetPlayerDataList        = self.WidgetPlayerDataList         --- 玩家数据的最上层组件
    self.WidgetSchoolDataList        = self.WidgetSchoolDataList         --- 门派统计的最上层组件
    self.LabelPlayerNumBlue          = self.LabelPlayerNumBlue           --- 蓝方人数
    self.LabelPlayerNumRed           = self.LabelPlayerNumRed            --- 红方人数
    self.LabelFactionBlue            = self.LabelFactionBlue             --- 蓝方帮会名称
    self.LabelFactionRed             = self.LabelFactionRed              --- 红方帮会名称
    self.ScrollViewSchoolDataList    = self.ScrollViewSchoolDataList     --- 门派人数统计的scroll view
    self.WidgetWarLevel              = self.WidgetWarLevel               --- 比赛级别的组件
    self.LabelWarLevel               = self.LabelWarLevel                --- 比赛级别的label
    self.BtnExportData               = self.BtnExportData                --- 导出数据
    self.BtnRecord                   = self.BtnRecord                    --- 我的战绩
    self.WidgetFront                 = self.WidgetFront                  --- 用于隐藏优秀表现tips的组件
    self.BtnMask                     = self.BtnMask                      --- 用于隐藏优秀表现tips的按钮
    self.WidgetTitle                 = self.WidgetTitle                  --- 所有标题栏上层的节点
    self.BtnOthers                   = self.BtnOthers                    --- 切换数据栏
    self.LayoutTitle                 = self.LayoutTitle                  --- 数据栏1
    self.LayoutTitle2                = self.LayoutTitle2                 --- 数据栏2
    self.RichTextScoreAndRank        = self.RichTextScoreAndRank         --帮会积分和排名
    self.RichTextBattlePointAndLabel = self.RichTextBattlePointAndLabel  -- 个人战勋点和帮会战勋牌
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChampionshipSettleDataView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tInfo BattleFieldInfo 战场信息
---@param tGroupInfo string[] 当前地图的战场中不同阵营（1-4）的名称
function UIChampionshipSettleDataView:OnEnter(bBattleFieldEnd, tInfo, tGroupInfo)
    self.bBattleFieldEnd = bBattleFieldEnd
    self.tInfo           = tInfo
    self.tGroupInfo      = tGroupInfo or {}
    self.nBanishTime     = tInfo.nBanishTime
    self.tStatistics     = tInfo.tStatistics

    --- 筛选的阵营类别
    self.nTeamIndex      = 0 -- 0-所有、1-蓝方阵营、2-红方阵营...
    --- 排序的列的序号
    self.nSortIndex      = 0
    --- 排序的顺序（不排序、升序、降序）
    self.nOrder          = ORDER_TYPE.NONE

    self.tTeamToggleList = {
        [0] = self.TogAll,
        [1] = self.TogTeamBlue,
        [2] = self.TogTeamRed,
    }

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.BtnBg, true)
    UIHelper.SetSwallowTouches(self.BtnMask, false)

    self:UpdateInfo()
end

function UIChampionshipSettleDataView:OnExit()
    TongData.tTongScore = nil
    self.bInit = false
    self:UnRegEvent()
end

function UIChampionshipSettleDataView:BindUIEvent()
    --点击左下阵营按钮筛选
    for nIndex, toggleTeam in pairs(self.tTeamToggleList) do
        UIHelper.BindUIEvent(toggleTeam, EventType.OnSelectChanged, function(toggle, bSelected)
            if bSelected then
                self.nTeamIndex = nIndex

                self:SwitchPlayerStatsAndSchoolPage(true)
            end
        end)

        UIHelper.SetSelected(toggleTeam, false)
        UIHelper.SetToggleGroupIndex(toggleTeam, ToggleGroupIndex.TongMemberFilter)
    end

    UIHelper.BindUIEvent(self.TogSchoolAccount, EventType.OnSelectChanged, function(toggle, bSelected)
        if bSelected then
            self:SwitchPlayerStatsAndSchoolPage(false)
        end
    end)
    UIHelper.SetSelected(self.TogSchoolAccount, false)
    UIHelper.SetToggleGroupIndex(self.TogSchoolAccount, ToggleGroupIndex.TongMemberFilter)

    --点击标题栏排序
    for i = 1, TOTAL_TITLE_COUNT do
        local nIndex = i

        local btn    = UIHelper.FindChildByName(self.WidgetTitle, "BtnTitle" .. nIndex)
        if btn then
            self["Title" .. nIndex]      = btn
            local label                  = UIHelper.FindChildByName(btn, "LabelTitle" .. nIndex)
            self["LabelTitle" .. nIndex] = label

            local widgetSort             = UIHelper.FindChildByName(btn, "WidgetSort")
            if widgetSort then
                local imgSortUp               = UIHelper.FindChildByName(widgetSort, "ImgUp")
                local imgSortDown             = UIHelper.FindChildByName(widgetSort, "ImgDown")

                self["WidgetSort" .. nIndex]  = widgetSort
                self["ImgSortUp" .. nIndex]   = imgSortUp
                self["ImgSortDown" .. nIndex] = imgSortDown
            end

            UIHelper.BindUIEvent(btn, EventType.OnClick, function()
                if self.nSortIndex ~= nIndex then
                    self.nSortIndex = nIndex
                    self.nOrder     = ORDER_TYPE.DESCENDING
                else
                    --降序 -> 升序 -> 默认 循环
                    self.nOrder = self.nOrder % 3 + 1
                end
                self:UpdateStatisticsPage()
                self:UpdateSortIconState()
            end)
        else
            local widget = UIHelper.FindChildByName(self.WidgetTitle, "WidgetTitle" .. nIndex)
            if widget then
                self["Title" .. nIndex]      = widget
                self["LabelTitle" .. nIndex] = UIHelper.FindChildByName(widget, "LabelTitle" .. nIndex)

                --- 前几个不能排序
                local widgetSort             = UIHelper.FindChildByName(widget, "WidgetSort")
                UIHelper.SetVisible(widgetSort, false)
            end
        end
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        --退出战场
        if self.bBattleFieldEnd then
            BattleFieldData.LeaveBattleField()
        else
            UIHelper.ShowConfirm(g_tStrings.STR_SURE_LEAVE_BATTLE, BattleFieldData.LeaveBattleField)
        end
    end)

    UIHelper.BindUIEvent(self.BtnExportData, EventType.OnClick, function()
        self:ExportData()
    end)

    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        BattleFieldData.OpenMyRecord()
        if self.tInfo.bUpdateRecord then
            UIHelper.SetVisible(self.ImgRedDot, false)
            self.tInfo.bUpdateRecord = nil
        end
    end)

    UIHelper.BindUIEvent(self.BtnMask, EventType.OnTouchBegan, function()
        self:HideWidgetPlayerTips()
    end)

    UIHelper.BindUIEvent(self.BtnOthers, EventType.OnClick, function()
        UIHelper.SetVisible(self.LayoutTitle, not UIHelper.GetVisible(self.LayoutTitle))
        UIHelper.SetVisible(self.LayoutTitle2, not UIHelper.GetVisible(self.LayoutTitle2))

        Event.Dispatch("ChampionshipSettleDataToggleTitle")
    end)
end

function UIChampionshipSettleDataView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            self:UpdateSchoolStatistics()
        end)
    end)
end

function UIChampionshipSettleDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

---@param tInfo BattleFieldInfo 战场信息
function UIChampionshipSettleDataView:Update(tInfo)
    self.tInfo       = tInfo
    self.nBanishTime = tInfo.nBanishTime
    self.tStatistics = tInfo.tStatistics

    self:UpdateInfo()
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChampionshipSettleDataView:UpdateInfo()
    UIHelper.SetVisible(self.BtnClose, not self.bBattleFieldEnd)

    if self.bBattleFieldEnd then
        local _, _, nBeginTime, nEndTime = BattleFieldData.GetBattleFieldPQInfo()
        local nCurrentTime               = GetCurrentTime()
        if nBeginTime and nBeginTime > 0 then
            local nTime = 0
            if nEndTime ~= 0 and nCurrentTime > nEndTime then
                nTime = nEndTime - nBeginTime
            else
                nTime = nCurrentTime - nBeginTime
            end
            local szTime = self:GetFormatTime(nTime)
            szTime       = string.format(g_tStrings.STR_BATTLEFIELD_TIME_USED .. " <color=%s>%s</color>", RICHTEXT_COLOR, szTime)
            UIHelper.SetRichText(self.LabelPastTime, szTime)
        end
    end

    self:UpdateTitleState()

    if self.bBattleFieldEnd then
        UIHelper.SetString(self.LabelLeave, g_tStrings.STR_LEAVE_BATTLEFIELD) --退出战场按钮文字: "离开战场"

        local bWin = self.tInfo.bWin
        UIHelper.SetVisible(self.WidgetVictory, bWin)
        UIHelper.SetVisible(self.ImgVictoryBgLight, bWin)
        UIHelper.SetVisible(self.WidgetDefeat, not bWin)
        UIHelper.SetVisible(self.ImgDefeatBgLight, not bWin)

        self:SetCountDown(self.nBanishTime)
    else
        UIHelper.SetString(self.LabelLeave, g_tStrings.STR_FORCE_LEAVE_BATTLEFIELD) --退出战场按钮文字: "强制离开战场"

        UIHelper.SetVisible(self.WidgetVictory, false)
        UIHelper.SetVisible(self.ImgVictoryBgLight, false)
        UIHelper.SetVisible(self.WidgetDefeat, false)
        UIHelper.SetVisible(self.ImgDefeatBgLight, false)

        local _, _, _, nEndTime = BattleFieldData.GetBattleFieldPQInfo()
        self:SetCountDown(nEndTime)
    end

    local nDefaultSelectSide = 0
    if self.bBattleFieldEnd then
        self.nTeamIndex    = self.tInfo.nClientPlayerSide or 0
        nDefaultSelectSide = self.nTeamIndex
    end
    local toggle = self.tTeamToggleList[nDefaultSelectSide]
    UIHelper.SetSelected(toggle, true)

    UIHelper.SetVisible(self.RichTextTime, self.bBattleFieldEnd)
    UIHelper.SetVisible(self.BtnRecord, self.bBattleFieldEnd)
    UIHelper.SetVisible(self.ImgRedDot, self.tInfo.bUpdateRecord or false)

    local szLevelName = BattleFieldData.GetTongFightMapLevel()

    UIHelper.SetVisible(self.WidgetWarLevel, not self.bBattleFieldEnd)
    UIHelper.SetRichText(self.LabelWarLevel, string.format("武林争霸赛—<color=#ffd778>%s</color>", szLevelName))

    self:UpdateSortIconState()
    self:UpdateStatisticsPage()
    self:UpdateSchoolStatistics()
    self:HideWidgetPlayerTips()
    self:UpdateTongRankAndScore()
    self:UpdateTongBattlePointAndLabel()
end

function UIChampionshipSettleDataView:UpdateTongRankAndScore()
    if not self.bBattleFieldEnd then
        UIHelper.SetVisible(self.RichTextScoreAndRank, false)
        return
    end

    local nSide = g_pClientPlayer.nBattleFieldSide
    local tBattleFieldData = BattleFieldData.GetBattleFieldInfo()
    local nScore = tBattleFieldData and tBattleFieldData.nTongScore or 0
    local szRank = g_tStrings.STR_GUILD_NOT_IN_RANK
    local tInfo = BattleFieldData.GetTongFight2024Info() or {}
    if tInfo and tInfo[nSide] and tInfo[nSide].nRank and tInfo[nSide].nRank ~= 0 then
        szRank = tInfo[nSide].nRank
    end
    UIHelper.SetVisible(self.RichTextScoreAndRank, true)
    UIHelper.SetRichText(self.RichTextScoreAndRank, FormatString(g_tStrings.STR_GUILD_TONG_RANK_AND_SCORE, nScore, szRank))
end

-- 帮会战勋牌
function UIChampionshipSettleDataView:UpdateTongBattlePointAndLabel()
    if not self.bBattleFieldEnd then
        UIHelper.SetVisible(self.RichTextBattlePointAndLabel, false)
        return
    end

    local tBattleFieldData = BattleFieldData.GetBattleFieldInfo()
    local nTongCurrency = tBattleFieldData.nTongCurrency or 0
    UIHelper.SetVisible(self.RichTextBattlePointAndLabel, true)
    UIHelper.SetRichText(self.RichTextBattlePointAndLabel, FormatString(g_tStrings.STR_GUILD_TONG_POINT_AND_LABEL, nTongCurrency))
end

function UIChampionshipSettleDataView:SetCountDown(nEndTime)
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

function UIChampionshipSettleDataView:UpdateTimeView()
    if self.bBattleFieldEnd then
        UIHelper.SetRichText(self.RichTextTime, string.format("<color=#d7f6ff>将在<color=#ffe26e>%d秒</c>后传出战场</c>", self.m_nLeftTimer))
    else
        local _, _, nBeginTime, nEndTime = BattleFieldData.GetBattleFieldPQInfo()
        local nCurrentTime               = GetCurrentTime()
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
            UIHelper.SetVisible(self.LabelPastTime, true)
        else
            UIHelper.SetVisible(self.LabelPastTime, false)
        end
    end
end

function UIChampionshipSettleDataView:GetFormatTime(nTime)
    local nM         = math.floor(nTime / 60)
    local nS         = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText = szTimeText .. nM .. "分"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText .. "0"
    end

    szTimeText = szTimeText .. nS .. "秒"

    return szTimeText
end

function UIChampionshipSettleDataView:UpdateTitleState()
    --未结束不显示部分列
    -- 奖励 列
    UIHelper.SetVisible(self.Title12, self.bBattleFieldEnd)

    --1: 门派+名字；2: 优秀表现；3~10: 基础数据；11: 身份；12: 奖励

    --Layout
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetTitle, true, true)
end

function UIChampionshipSettleDataView:UpdateStatisticsPage()
    if not self.tStatistics then return end

    local player = GetClientPlayer()
    if not player then return end

    m_tbViewStatistics       = {}
    tTongWarBattleInfoConfig = {}

    local dwPlayerID         = player.dwID
    local dwLeaderID         = self.tInfo.dwLeaderID

    --按阵营显示
    for i = 1, #self.tStatistics do
        local tLine = self.tStatistics[i]
        if self.nTeamIndex == 0 or tLine.nBattleFieldSide == self.nTeamIndex then
            table.insert(m_tbViewStatistics, tLine)
        end

        self:InitTongWarBattleInfo(i, tLine)
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
            local nLeft  = tLeft.nExcellentCount or 0
            local nRight = tRight.nExcellentCount or 0
            return nLeft > nRight
        end
        table.sort(m_tbViewStatistics, funcSort)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewDataList)

    for _, tStat in ipairs(m_tbViewStatistics) do
        ---@see UIChampionshipPlayer
        UIMgr.AddPrefab(PREFAB_ID.WidgetChampionshipPlayer, self.ScrollViewDataList, tStat, self)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDataList)
end

function UIChampionshipSettleDataView:SwitchPlayerStatsAndSchoolPage(bPlayerStats)
    UIHelper.SetVisible(self.WidgetPlayerDataList, bPlayerStats)
    UIHelper.SetVisible(self.WidgetSchoolDataList, not bPlayerStats)

    if bPlayerStats then
        self:UpdateStatisticsPage()
    else
        self:UpdateSchoolStatistics()
    end
end

function UIChampionshipSettleDataView:UpdateSchoolStatistics()
    local tInfo     = BattleFieldData.GetTongFight2024Info()

    local tBlueInfo = tInfo[0]
    local tRedInfo  = tInfo[1]

    UIHelper.SetString(self.LabelFactionBlue, UIHelper.GBKToUTF8(tBlueInfo.szTongName))
    UIHelper.SetString(self.LabelFactionRed, UIHelper.GBKToUTF8(tRedInfo.szTongName))

    local tForceCount = { {}, {}, {}, {} }
    local aSideTotal  = { 0, 0, 0, 0 }
    for nIndex, tData in ipairs(self.tStatistics) do
        local nForceID = tData.ForceID
        local dwMountKungfuID = tData.dwMountKungfuID
        local nSide    = tData.nBattleFieldSide
        if nForceID and type(nForceID) == "number" and nSide then
            if not tForceCount[nSide] then
                tForceCount[nSide] = {}
            end
            if dwMountKungfuID and type(dwMountKungfuID) == "number" and IsNoneSchoolKungfu(dwMountKungfuID) then -- 流派
				nForceID = Kungfu_GetType(dwMountKungfuID)
			end
            if not tForceCount[nSide][nForceID] then
                tForceCount[nSide][nForceID] = 0
            end
            tForceCount[nSide][nForceID] = tForceCount[nSide][nForceID] + 1
            aSideTotal[nSide]            = aSideTotal[nSide] + 1
        end
    end

    local nBlueTotal = aSideTotal[1]
    local nRedTotal  = aSideTotal[2]

    UIHelper.SetString(self.LabelPlayerNumBlue, FormatString(g_tStrings.STR_PLAYER_COUNT, nBlueTotal))
    UIHelper.SetString(self.LabelPlayerNumRed, FormatString(g_tStrings.STR_PLAYER_COUNT, nRedTotal))

    UIHelper.RemoveAllChildren(self.ScrollViewSchoolDataList)

    local tForceList = Table_GetForceList()
	local tForceToSchool = Table_GetForceToSchoolList()
	for _, tInfo in pairs(tForceToSchool) do  -- 补全流派
		local ForceID = tInfo.dwForceID
		local tInfo = Table_GetMountKungfuByForce(ForceID) or {}
		if IsTableEmpty(tInfo) then
			table.insert(tForceList, ForceID)
		end
	end

    for nIndex, nForceID in pairs(tForceList) do
        local szForceName = Table_GetForceName(nForceID, true)
        if not szForceName then
			local nSchoolID = Table_ForceToSchool(nForceID)
			szForceName = Table_GetSkillSchoolName(nSchoolID)
            szForceName = GBKToUTF8(szForceName)
		end
        local nBlueCount    = tForceCount[1][nForceID] or 0
        local nRedCount     = tForceCount[2][nForceID] or 0

        ---@see UIChampionshipSchoolData
        local script        = UIMgr.AddPrefab(PREFAB_ID.WidgetChampionshipSchoolData, self.ScrollViewSchoolDataList, szForceName, nBlueCount, nRedCount, nIndex)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSchoolDataList)
end

function UIChampionshipSettleDataView:UpdateSortIconState()
    for nIndex = 1, TOTAL_TITLE_COUNT do
        local widgetSort  = self["WidgetSort" .. nIndex]
        local imgSortUp   = self["ImgSortUp" .. nIndex]
        local imgSortDown = self["ImgSortDown" .. nIndex]
        if widgetSort and imgSortUp and imgSortDown then
            local nOpacityUp   = 70
            local nOpacityDown = 70

            if self.nSortIndex == nIndex then
                if self.nOrder == ORDER_TYPE.ASCENDING then
                    nOpacityUp = 255
                elseif self.nOrder == ORDER_TYPE.DESCENDING then
                    nOpacityDown = 255
                end
            end

            UIHelper.SetOpacity(imgSortUp, nOpacityUp)
            UIHelper.SetOpacity(imgSortDown, nOpacityDown)
        end
    end
end

local function getFilePath(szFileName)
    local p  = string.format("tong_war/%s", szFileName)

    local wp = cc.FileUtils:getInstance():getWritablePath()
    if wp and wp ~= "" then
        if wp:sub(#wp, 1) == '/' or p:sub(1, 1) == '/' then
            return string.format("%s/%s", wp, p)
        end
        return string.format("%s%s", wp, p)
    end
    return p
end

local function ExportData(t)
    local szContent = ''
    local szLine    = ''
    for _, v in pairs(t) do
        local szForceName = Table_GetForceName(v.ForceID)
        szLine =  v.szName .. "\t" .. szForceName .. "\t" .. v.nBattleFieldSide .. "\t" .. v.nKillCount .. "\t" ..v.nDeathCount .. "\t" ..
                v.nDecapitateCount .. "\t" .. v.nSolo .. "\t" ..v.nHarm .. "\t" .. v.nTreat .. "\t" ..
                v.nInjury .. "\t" .. v.nBestAssistKillCount .. "\t" .. v.nSpecial_OP_1 .. "\t" .. v.nSpecial_OP_2 .. "\t" .. v.nSpecial_OP_3 .. "\t" ..
                v.nSpecial_OP_4 .. "\t"

        if szContent == "" then
            szContent = szContent .. szLine
        else
            szContent = szContent .. "\n" .. szLine
        end
    end
    return szContent
end

local function SaveDataToFile(szText, file)
    -- 创建目录
    local dirPath  = string.sub(file, 1, string.find(file, "/[^/]*$"))
    local fileUtil = cc.FileUtils:getInstance()
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end

    fileUtil:writeStringToFile(szText, file)
end

-- 帮会联赛战场数据导出表格
function UIChampionshipSettleDataView:ExportData()
    local szTitles = g_tStrings.BATTLE_FIELD_SORT[2] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[1] ..
            "\t" .. g_tStrings.STR_TONGWAR_BATTLEINFO_EXPORT_HONGLANFANG_INFO .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[3] ..
            "\t" .. g_tStrings.BATTLE_FIELD_SORT[10] ..
            "\t" .. g_tStrings.BATTLE_FIELD_SORT[5] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[6] ..
            "\t" .. g_tStrings.BATTLE_FIELD_SORT[7] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[8] ..
            "\t" .. g_tStrings.BATTLE_FIELD_SORT[9] .."\t" .. g_tStrings.BATTLE_FIELD_SORT[4] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[11] ..
            "\t" .. g_tStrings.BATTLE_FIELD_SORT[12] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[13] .. "\t" .. g_tStrings.BATTLE_FIELD_SORT[14]

    local szSaveDataTime = string.format(os.date("%Y_%m_%d_%H_%M_%S", GetCurrentTime()))
    local szFileName     = "battleFieldData_" .. szSaveDataTime .. ".txt"
    local file           = getFilePath(szFileName)
    local szContent      = ExportData(tTongWarBattleInfoConfig)

    local szText         = szTitles .. "\n" .. szContent
    SaveDataToFile(szText, file)

    local szMsg = FormatString(g_tStrings.STR_TONGWAR_BATTLEINFO_EXPORT_FILE_SUCCESS, file)

    if Platform.IsWindows() then
        local dialog = UIHelper.ShowConfirm(szMsg, function()
            local dirPath = string.sub(file, 1, string.find(file, "/[^/]*$"))

            OpenFolder(dirPath)
        end)
        dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
    else
        ---@type UIConfirmView
        local dialog = UIHelper.ShowConfirm(szMsg)
        dialog:HideCancelButton()
    end
end

---@param tData BattleFieldStatistics
function UIChampionshipSettleDataView:InitTongWarBattleInfo(nIndex, tData)
    tTongWarBattleInfoConfig[nIndex]                      = {}
    tTongWarBattleInfoConfig[nIndex].nBattleFieldSide     = tData.nBattleFieldSide
    tTongWarBattleInfoConfig[nIndex].szName               = UIHelper.GBKToUTF8(tData.Name)
    tTongWarBattleInfoConfig[nIndex].ForceID              = tData.ForceID
    tTongWarBattleInfoConfig[nIndex].nKillCount           = tData[0]
    tTongWarBattleInfoConfig[nIndex].nDeathCount          = tData[9]
    tTongWarBattleInfoConfig[nIndex].nDecapitateCount     = tData[1]
    tTongWarBattleInfoConfig[nIndex].nSolo                = tData[2]
    tTongWarBattleInfoConfig[nIndex].nHarm                = tData[3]
    tTongWarBattleInfoConfig[nIndex].nTreat               = tData[4]
    tTongWarBattleInfoConfig[nIndex].nInjury              = tData[5]
    tTongWarBattleInfoConfig[nIndex].nBestAssistKillCount = tData[6]

    local szIdentity                                      = self:GetIdentityName(tData)

    tTongWarBattleInfoConfig[nIndex].nSpecial_OP_1        = szIdentity
    tTongWarBattleInfoConfig[nIndex].nSpecial_OP_2        = tData[11]
    tTongWarBattleInfoConfig[nIndex].nSpecial_OP_3        = tData[12]
    tTongWarBattleInfoConfig[nIndex].nSpecial_OP_4        = tData[13]
end

---@param tData BattleFieldStatistics
function UIChampionshipSettleDataView:GetIdentityName(tData)
    local szIdentity

    --- 普通身份用一个空格，否则这个label大小会是0，导致界面显示很奇怪
    local szEmptyIdentity                = " "

    local nTargetSideAdjust              = tData.BattleFieldSide % 2
    local nClientPlayerSideAdjust        = g_pClientPlayer.nBattleFieldSide % 2

    local bHideTongWarBattleKeyPeosonnel = nTargetSideAdjust ~= nClientPlayerSideAdjust

    if bHideTongWarBattleKeyPeosonnel then
        --- 隐藏对方阵营的身份信息
        szIdentity = szEmptyIdentity
    else
        local nIdentity = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_1]

        if nIdentity == TONG_LEAGUE_KEYPERSONNEL_TYPE.KEYPERSONNEL then
            szIdentity = g_tStrings.STR_TONGWAR_KEYPERSONNEL_INFOR
        elseif nIdentity == TONG_LEAGUE_KEYPERSONNEL_TYPE.COMMANDER then
            szIdentity = g_tStrings.STR_TONGWAR_COMMANDER_INFOR
        else
            szIdentity = szEmptyIdentity
        end
    end

    return szIdentity
end

function UIChampionshipSettleDataView:HideWidgetPlayerTips()
    self.bWidgetPlayerTipsShow = false
    UIHelper.SetVisible(self.WidgetFront, false)
    Event.Dispatch(EventType.BF_WidgetPlayerHideTips)
end

function UIChampionshipSettleDataView:SetWidgetPlayerTipsShowState()
    UIHelper.SetVisible(self.WidgetFront, true)
    self.bWidgetPlayerTipsShow = true
end

return UIChampionshipSettleDataView