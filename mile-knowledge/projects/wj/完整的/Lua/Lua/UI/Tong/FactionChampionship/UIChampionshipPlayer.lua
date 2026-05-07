-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIChampionshipPlayer
-- Date: 2024-08-02 16:13:28
-- Desc: 帮会联赛-结算-玩家数据
-- Prefab: WidgetChampionshipPlayer
-- ---------------------------------------------------------------------------------

local MAX_EXCELLENT_COUNT  = 6
local LABEL_CUSTOM_COUNT   = 4

local COLOR_BLUE           = cc.c3b(174, 217, 224) --#aed9e0
local COLOR_RED            = cc.c3b(255, 133, 125)
local COLOR_YELLOW         = cc.c3b(240, 220, 130)
local COLOR_WHITE          = cc.c3b(255, 255, 255) --#ffffff

local COLOR_SELF_YELLOW    = cc.c3b(255, 226, 110) --#ffe26e

---@class UIChampionshipPlayer
local UIChampionshipPlayer = class("UIChampionshipPlayer")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIChampionshipPlayer:_LuaBindList()
    self.ImgHead                         = self.ImgHead --- 头像
    self.LabelPlayerName                 = self.LabelPlayerName --- 名称
    self.ImgLogin                        = self.ImgLogin --- 登录客户端图标
    self.ImgSelf                         = self.ImgSelf --- 自己的标记

    self.ImgMvp                          = self.ImgMvp --- mvp图标

    self.LabelAssistNum                  = self.LabelAssistNum --- 协助击伤
    self.LabelBestAssistNum              = self.LabelBestAssistNum --- 最佳助攻
    self.LabelWoundNum                   = self.LabelWoundNum --- 击伤
    self.Label1v1Num                     = self.Label1v1Num --- 单挑
    self.LabelDamageNum                  = self.LabelDamageNum --- 伤害量
    self.LabelTreatNum                   = self.LabelTreatNum --- 治疗量
    self.LabelInjuredNum                 = self.LabelInjuredNum --- 受伤量
    self.LabelSevereInjuredNum           = self.LabelSevereInjuredNum --- 受重伤

    self.LayoutAward                     = self.LayoutAward --- 奖励的layout
    self.LayoutAward1                    = self.LayoutAward1 --- 奖励1的layout
    self.ImgMoneyIcon1                   = self.ImgMoneyIcon1 --- 奖励1的图标
    self.LabelNum1                       = self.LabelNum1 --- 奖励1的数目
    self.LayoutAward2                    = self.LayoutAward2 --- 奖励2的layout
    self.ImgMoneyIcon2                   = self.ImgMoneyIcon2 --- 奖励2的图标
    self.LabelNum2                       = self.LabelNum2 --- 奖励2的数目

    self.LabelDouble1                    = self.LabelDouble1 --- 奖励1的倍率
    self.ImgDouble1                      = self.ImgDouble1 --- 奖励1的倍率
    self.LabelDouble2                    = self.LabelDouble2 --- 奖励2的倍率
    self.ImgDouble2                      = self.ImgDouble2 --- 奖励2的倍率

    self.ImgPlayerRedBg                  = self.ImgPlayerRedBg --- 红色玩家背景图
    self.ImgCurrentPlayerHighlightRedBg  = self.ImgCurrentPlayerHighlightRedBg --- 红色当前玩家高亮背景图
    self.ImgPlayerBlueBg                 = self.ImgPlayerBlueBg --- 蓝色玩家背景图
    self.ImgCurrentPlayerHighlightBlueBg = self.ImgCurrentPlayerHighlightBlueBg --- 蓝色当前玩家高亮背景图

    self.BtnMark                         = self.BtnMark --- 优秀表现上层的按钮
    self.LayoutTips                      = self.LayoutTips --- 优秀表现tip的layout

    self.BtnPlayerInfo                   = self.BtnPlayerInfo --- 显示玩家弹窗的按钮

    self.WidgetSwitch1                   = self.WidgetSwitch1 --- 数据栏1
    self.WidgetSwitch2                   = self.WidgetSwitch2 --- 数据栏2
    self.LabelKillQiLin                  = self.LabelKillQiLin --- 击退麒麟
    self.LabelQiLinZhu                   = self.LabelQiLinZhu --- 麒麟珠
    self.LabelYeGuai                     = self.LabelYeGuai --- 野怪
    self.LabelIdentity                   = self.LabelIdentity --- 身份

end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIChampionshipPlayer:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tStat BattleFieldStatistics 玩家数据
---@param m_uiView UIChampionshipSettleDataView 结算界面脚本
function UIChampionshipPlayer:OnEnter(tStat, m_uiView)
    self.tStat    = tStat
    self.m_uiView = m_uiView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChampionshipPlayer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChampionshipPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMark, EventType.OnClick, function()
        if not UIHelper.GetVisible(self.LayoutTips) then
            self:UpdateTipsItem()
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlayerInfo, EventType.OnClick, function()
        self:ShowPlayerInfo()
    end)
end

function UIChampionshipPlayer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.BF_WidgetPlayerHideTips, function()
        UIHelper.SetVisible(self.LayoutTips, false)
    end)

    Event.Reg(self, "ChampionshipSettleDataToggleTitle", function()
        self:UpdateColumnVisibleByTitle()
    end)
end

function UIChampionshipPlayer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChampionshipPlayer:UpdateInfo()
    local selfPlayer = GetClientPlayer()
    if not selfPlayer then return end

    local tData = self.tStat
    if not tData then return end

    local bBattleFieldEnd = self.m_uiView.bBattleFieldEnd
    local tExcellentData  = self.m_uiView.tInfo.tExcellentData or {}

    --阵营图标
    local szForceIconPath = PlayerForceID2SchoolImg2[tData.ForceID]
    UIHelper.SetSpriteFrame(self.ImgHead, szForceIconPath)

    PlayerData.SetPlayerLogionSite(self.ImgLogin, tData.ClientVersionType, tData.dwPlayerID)

    UIHelper.SetString(self.LabelPlayerName, GBKToUTF8(tData.Name), 7)                                            --1名字 限制最大六个字
    UIHelper.SetString(self.LabelAssistNum, tostring(tData[PQ_STATISTICS_INDEX.KILL_COUNT] or 0))                       --3协助击伤
    UIHelper.SetString(self.LabelBestAssistNum, tostring(tData[PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT] or 0))       --4最佳助攻
    UIHelper.SetString(self.LabelWoundNum, tostring(tData[PQ_STATISTICS_INDEX.DECAPITATE_COUNT] or 0))                  --5击伤
    UIHelper.SetString(self.Label1v1Num, tostring(tData[PQ_STATISTICS_INDEX.SOLO_COUNT] or 0))                          --6单挑
    UIHelper.SetString(self.LabelDamageNum, tostring(tData[PQ_STATISTICS_INDEX.HARM_OUTPUT] or 0))                      --7伤害量
    UIHelper.SetString(self.LabelTreatNum, tostring(tData[PQ_STATISTICS_INDEX.TREAT_OUTPUT] or 0))                      --8治疗量
    UIHelper.SetString(self.LabelInjuredNum, tostring(tData[PQ_STATISTICS_INDEX.INJURY] or 0))                          --9受伤量
    UIHelper.SetString(self.LabelSevereInjuredNum, tostring(tData[PQ_STATISTICS_INDEX.DEATH_COUNT] or 0))               --10受重伤

    -- 11 身份
    local szIdentity = self.m_uiView:GetIdentityName(self.tStat)
    UIHelper.SetString(self.LabelIdentity, szIdentity)

    -- 12 奖励在下面单独处理

    -- 其他数据
    UIHelper.SetString(self.LabelKillQiLin, tostring(tData[PQ_STATISTICS_INDEX.SPECIAL_OP_2] or 0))                     --13击退麒麟
    UIHelper.SetString(self.LabelQiLinZhu, tostring(tData[PQ_STATISTICS_INDEX.SPECIAL_OP_3] or 0))                      --14麒麟珠
    UIHelper.SetString(self.LabelYeGuai, tostring(tData[PQ_STATISTICS_INDEX.SPECIAL_OP_4] or 0))                        --15野怪

    self:UpdateColumnVisibleByTitle()

    --tips
    UIHelper.SetVisible(self.LayoutTips, false)

    --reward
    if UIHelper.GetVisible(self.m_uiView.Title12) then
        UIHelper.SetVisible(self.LayoutAward, true)

        --威名点加成倍率
        local nMultiRestige = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_8] or 0
        if nMultiRestige and nMultiRestige > 100 then
            UIHelper.SetVisible(self.LabelDouble1, true)
            UIHelper.SetString(self.LabelDouble1, (nMultiRestige - 100) .. "%")
            UIHelper.SetVisible(self.ImgDouble1, true)

            UIHelper.SetVisible(self.LabelDouble2, true)
            UIHelper.SetString(self.LabelDouble2, (nMultiRestige - 100) .. "%")
            UIHelper.SetVisible(self.ImgDouble2, true)

            UIHelper.SetVisible(self.LabelDouble3, true)
            UIHelper.SetString(self.LabelDouble3, (nMultiRestige - 100) .. "%")
            UIHelper.SetVisible(self.ImgDouble3, true)
        else
            UIHelper.SetVisible(self.LabelDouble1, false)
            UIHelper.SetVisible(self.ImgDouble1, false)

            UIHelper.SetVisible(self.LabelDouble2, false)
            UIHelper.SetVisible(self.ImgDouble2, false)

            UIHelper.SetVisible(self.LabelDouble3, false)
            UIHelper.SetVisible(self.ImgDouble3, false)
        end

        local nAward1 = tData[PQ_STATISTICS_INDEX.AWARD_1]
        local nAward2 = tData[PQ_STATISTICS_INDEX.AWARD_2]
        local nAward3 = tData[PQ_STATISTICS_INDEX.AWARD_3]

        UIHelper.SetVisible(self.LayoutAward1, nAward1 ~= 0)
        UIHelper.SetVisible(self.LayoutAward2, nAward2 ~= 0)
        UIHelper.SetVisible(self.LayoutAward3, nAward3 ~= 0)
        UIHelper.SetString(self.LabelNum1, tostring(nAward1)) --威名点
        UIHelper.SetString(self.LabelNum2, tostring(nAward2)) --战阶积分
        UIHelper.SetString(self.LabelNum3, tostring(nAward3)) --个人货币

        UIHelper.CascadeDoLayoutDoWidget(self.LayoutAward, true, true)
    else
        UIHelper.SetVisible(self.LayoutAward, false)
    end

    local player = GetClientPlayer()
    if not player then return end

    --字体颜色
    local bSelf       = tData.dwPlayerID == player.dwID
    local color       = bSelf and COLOR_SELF_YELLOW or COLOR_BLUE
    local colorDouble = bSelf and COLOR_SELF_YELLOW or COLOR_YELLOW

    UIHelper.SetVisible(self.ImgPlayerBlueBg, tData.nBattleFieldSide == 1)
    UIHelper.SetVisible(self.ImgPlayerRedBg, tData.nBattleFieldSide == 2)
    UIHelper.SetVisible(self.ImgCurrentPlayerHighlightBlueBg, bSelf)
    UIHelper.SetVisible(self.ImgCurrentPlayerHighlightRedBg, bSelf)

    UIHelper.SetVisible(self.ImgSelf, bSelf)

    UIHelper.SetColor(self.LabelPlayerName, color)
    UIHelper.SetColor(self.LabelAssistNum, color)
    UIHelper.SetColor(self.LabelBestAssistNum, color)
    UIHelper.SetColor(self.LabelWoundNum, color)
    UIHelper.SetColor(self.Label1v1Num, color)
    UIHelper.SetColor(self.LabelDamageNum, color)
    UIHelper.SetColor(self.LabelTreatNum, color)
    UIHelper.SetColor(self.LabelInjuredNum, color)
    UIHelper.SetColor(self.LabelSevereInjuredNum, color)

    UIHelper.SetColor(self.LabelIdentity, color)

    UIHelper.SetColor(self.LabelNum1, color)
    UIHelper.SetColor(self.LabelNum2, color)
    UIHelper.SetColor(self.LabelDouble1, colorDouble)
    UIHelper.SetColor(self.LabelDouble2, colorDouble)

    --结算
    UIHelper.SetVisible(self.ImgMvp, false)

    UIHelper.SetVisible(self.BtnMark, bBattleFieldEnd)

    if not self.bInitImgTab then
        self:InitImgTab()
    end

    self.bHasExcellent = false
    if bBattleFieldEnd then
        --优秀表现和MVP
        local tExcellent = tExcellentData[tData.dwPlayerID] or {}
        local bMVP       = false
        local nTabIndex  = 1
        for i = 1, MAX_EXCELLENT_COUNT do
            local iconTab = self["ImgTab" .. i]
            UIHelper.SetVisible(iconTab, false)
        end
        for i = 1, MAX_EXCELLENT_COUNT do
            local dwID    = tExcellent[i]
            local tLine   = dwID and g_tTable.BFArenaExcellent:Search(dwID)
            local iconTab = self["ImgTab" .. nTabIndex]
            if tLine then
                if dwID == EXCELLENT_ID.BEST_COURSE then
                    bMVP = true
                else
                    --设置优秀表现图标
                    UIHelper.SetVisible(iconTab, true)
                    UIHelper.SetSpriteFrame(iconTab, tLine.szMobileImagePath)
                    nTabIndex = nTabIndex + 1
                end
            end
        end
        UIHelper.SetVisible(self.ImgMvp, bMVP)
    end
end

function UIChampionshipPlayer:UpdateTipsItem()
    local tData = self.tStat
    if not tData then return end

    local tExcellentData = self.m_uiView.tInfo.tExcellentData or {}
    local tExcellent     = tExcellentData[tData.dwPlayerID] or {}

    local bHasExcellent  = false

    UIHelper.RemoveAllChildren(self.LayoutTips)

    for i = 1, MAX_EXCELLENT_COUNT do
        local dwID  = tExcellent[i]
        local tLine = dwID and g_tTable.BFArenaExcellent:Search(dwID)
        if tLine then
            --Tips
            self:CreateTipsItem(self.LayoutTips, tLine.szMobileImagePath, UIHelper.GBKToUTF8(tLine.szName))
            bHasExcellent = true
        end
    end

    if bHasExcellent then
        UIHelper.LayoutDoLayout(self.LayoutTips)
        UIHelper.SetVisible(self.LayoutTips, true)
        self.m_uiView:SetWidgetPlayerTipsShowState()
    end
end

function UIChampionshipPlayer:CreateTipsItem(parent, szIconPath, szName)
    if not szName or not szIconPath then return end

    local tipsItem = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsItem, parent)
    local img      = tipsItem:getChildByName("ImgTipsIcon")
    local label    = tipsItem:getChildByName("LabelTips")
    UIHelper.SetSpriteFrame(img, szIconPath)
    UIHelper.SetString(label, szName)
end

function UIChampionshipPlayer:InitImgTab()
    --ImgTab1 ~ ImgTab6
    local tChildren = UIHelper.GetChildren(self.BtnMark)
    for _, child in ipairs(tChildren) do
        local szName = child:getName()
        self[szName] = child
    end
    self.bInitImgTab = true
end

function UIChampionshipPlayer:ShowPlayerInfo()
    local nPlayerID = self.tStat.dwPlayerID
    if nPlayerID == UI_GetClientPlayerID() then
        --- 自己不弹窗
        return
    end

    local szName           = UIHelper.GBKToUTF8(self.tStat.Name)
    local nForceID         = self.tStat.ForceID
    local szGlobalID       = self.tStat.GlobalID

    local nPlayerIdentity  = self:GetIdentity()

    local nBattleFieldSide = self.tStat.BattleFieldSide
    if nBattleFieldSide ~= g_pClientPlayer.nBattleFieldSide then
        --- 对方阵营不弹窗
        return
    end

    local tips
    ---@type UIWidgetTongMemberMenu
    local script

    tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFactionManagementMemberPlayerPop, self.WidgetPlayerInfo, TipsLayoutDir.BOTTOM_RIGHT)
    script:InitForTongWar(nPlayerID, szName, nForceID, szGlobalID, nPlayerIdentity)
end

function UIChampionshipPlayer:GetIdentity()
    local tData = self.tStat
    if not tData then
        return TONG_LEAGUE_KEYPERSONNEL_TYPE.ORDINARY
    end

    local nIdentity = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_1]
    return nIdentity
end

--- 根据对应标题是否显示，来确定该列数据是否显示
function UIChampionshipPlayer:UpdateColumnVisibleByTitle()
    UIHelper.SetVisible(self.WidgetSwitch1, UIHelper.GetVisible(self.m_uiView.LayoutTitle))
    UIHelper.SetVisible(self.WidgetSwitch2, UIHelper.GetVisible(self.m_uiView.LayoutTitle2))

    --UIHelper.SetVisible(self.LabelPlayerName, UIHelper.GetVisible(self.m_uiView.Title1))
    UIHelper.SetVisible(self.LabelAssistNum, UIHelper.GetVisible(self.m_uiView.Title3))
    UIHelper.SetVisible(self.LabelBestAssistNum, UIHelper.GetVisible(self.m_uiView.Title4))
    UIHelper.SetVisible(self.LabelWoundNum, UIHelper.GetVisible(self.m_uiView.Title5))
    UIHelper.SetVisible(self.Label1v1Num, UIHelper.GetVisible(self.m_uiView.Title6))
    UIHelper.SetVisible(self.LabelDamageNum, UIHelper.GetVisible(self.m_uiView.Title7))
    UIHelper.SetVisible(self.LabelTreatNum, UIHelper.GetVisible(self.m_uiView.Title8))
    UIHelper.SetVisible(self.LabelInjuredNum, UIHelper.GetVisible(self.m_uiView.Title9))
    UIHelper.SetVisible(self.LabelSevereInjuredNum, UIHelper.GetVisible(self.m_uiView.Title10))

    UIHelper.SetVisible(self.LabelIdentity, UIHelper.GetVisible(self.m_uiView.Title11))

    UIHelper.SetVisible(self.LabelKillQiLin, UIHelper.GetVisible(self.m_uiView.Title13))
    UIHelper.SetVisible(self.LabelQiLinZhu, UIHelper.GetVisible(self.m_uiView.Title14))
    UIHelper.SetVisible(self.LabelYeGuai, UIHelper.GetVisible(self.m_uiView.Title15))
end

return UIChampionshipPlayer