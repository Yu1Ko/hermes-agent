-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILieXingDataSettleListWidget
-- Date: 2024-01-31 16:05:37
-- Desc: 列星虚境玩家数据组件
-- Prefab: WidgetDataSettleListLeft / WidgetDataSettleListRight
-- ---------------------------------------------------------------------------------

local MAX_EQUIP_COUNT               = 6
local MAX_EXCELLENT_COUNT           = 6

---@class UILieXingDataSettleListWidget
local UILieXingDataSettleListWidget = class("UILieXingDataSettleListWidget")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILieXingDataSettleListWidget:_LuaBindList()
    self.LabelName         = self.LabelName --- 名字
    self.LabelLevel        = self.LabelLevel --- 等级

    self.LabelKill         = self.LabelKill --- 击伤
    self.LabelDeath        = self.LabelDeath --- 重伤
    self.LabelAssistKill   = self.LabelAssistKill --- 协伤

    self.LabelDamageNum    = self.LabelDamageNum --- 伤害量
    self.LabelToppleTowers = self.LabelToppleTowers --- 推塔
    self.LabelMoney        = self.LabelMoney --- 星露（对局货币）

    self.WidgetHead        = self.WidgetHead --- 头像组件
    self.ImgSchool         = self.ImgSchool --- 头像图片

    self.LayoutState       = self.LayoutState --- 特殊评价的列表
    self.ImgIcon01         = self.ImgIcon01 --- 特殊评价1
    self.ImgIcon02         = self.ImgIcon02 --- 特殊评价2
    self.ImgIcon03         = self.ImgIcon03 --- 特殊评价3
    self.ImgIcon04         = self.ImgIcon04 --- 特殊评价4
    self.ImgIcon05         = self.ImgIcon05 --- 特殊评价5
    self.ImgIcon06         = self.ImgIcon06 --- 特殊评价6

    self.ImgMvp            = self.ImgMvp --- MVP
    self.LabelMvp          = self.LabelMvp --- MVP分数

    self.LayoutItem        = self.LayoutItem --- 装备列表

    self.ImgSelectBg       = self.ImgSelectBg --- 自己的高亮背景图
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UILieXingDataSettleListWidget:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UILieXingDataSettleListWidget:OnEnter(dwPlayerID, tData, nClientPlayerSide)
    self.dwPlayerID        = dwPlayerID
    self.tData             = tData
    self.nClientPlayerSide = nClientPlayerSide

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UILieXingDataSettleListWidget:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILieXingDataSettleListWidget:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetHead, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.dwID == self.dwPlayerID then
            return
        end

        if self.nClientPlayerSide ~= self.tData.BattleFieldSide then
            return
        end

        local szName     = self.tData.Name
        local dwPlayerID = self.dwPlayerID

        local tbBtnInfo  = { {
                                 szName = "信誉举报",
                                 bDisabled = not BattleFieldData.IsCanReportPlayer(szName),
                                 szDisableTip = "目标侠士已退出，无法举报",
                                 OnClick = function()
                                     RemoteCallToServer("On_XinYu_Jubao", dwPlayerID)
                                 end
                             } }

        local nTipsDir   = TipsLayoutDir.AUTO
        if self.tData.BattleFieldSide == 0 then
            nTipsDir = TipsLayoutDir.LEFT_CENTER
        elseif self.tData.BattleFieldSide == 1 then
            nTipsDir = TipsLayoutDir.RIGHT_CENTER
        end

        local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipMoreOper, self.WidgetHead, nTipsDir)
        script:OnEnter(tbBtnInfo)

        local x, y = UIHelper.GetContentSize(script.LayoutMoreOper)
        tips:SetSize(x, y)
        tips:Update()
    end)
end

function UILieXingDataSettleListWidget:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "MOBA_EQUIP_UPDATE", function()
        self:UpdateEquipInfo()
    end)
end

function UILieXingDataSettleListWidget:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--- note: 这段代码是从 scripts/Map/列星岛/include/CommonFunction.lua 复制而来，在require.lua中直接引用好像不行，先暂时复制过来，后面再看看怎么共用一份
local tMobaCommonFunc         = {}

tMobaCommonFunc.tMobaLevelExp = {
    [1] = 0,
    [2] = 300,
    [3] = 600,
    [4] = 900,
    [5] = 1300,
    [6] = 1800,
    [7] = 2400,
    [8] = 3100,
    [9] = 3900,
    [10] = 4800,
    [11] = 5800,
    [12] = 6900,
    [13] = 8100,
    [14] = 9400,
    [15] = 10800,
}

function tMobaCommonFunc.GetExpLevel(nExp)
    if nExp >= tMobaCommonFunc.tMobaLevelExp[#tMobaCommonFunc.tMobaLevelExp] then
        return #tMobaCommonFunc.tMobaLevelExp
    end
    for i = 2, #tMobaCommonFunc.tMobaLevelExp do
        if nExp < tMobaCommonFunc.tMobaLevelExp[i] then
            return i - 1
        end
    end
    return 1
end

function UILieXingDataSettleListWidget:UpdateInfo()
    self:UpdateBasicInfo()
    self:UpdateExcellentInfo()
    self:UpdateEquipInfo()
end

function UILieXingDataSettleListWidget:UpdateBasicInfo()
    local tData         = self.tData

    local szName        = UIHelper.GBKToUTF8(tData.Name)

    local nExp          = tData[PQ_STATISTICS_INDEX.AWARD_EXP]
    local nLevel        = tMobaCommonFunc.GetExpLevel(nExp)

    local nKill         = tData[PQ_STATISTICS_INDEX.DECAPITATE_COUNT]
    local nDeath        = tData[PQ_STATISTICS_INDEX.DEATH_COUNT]
    local nAssistKill   = tData[PQ_STATISTICS_INDEX.KILL_COUNT]

    local nDamageNum    = tData[PQ_STATISTICS_INDEX.HARM_OUTPUT]
    local nToppleTowers = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_1]
    local nMoney        = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_2]

    local szSchoolImg   = PlayerForceID2SchoolImg[tData.ForceID]
    if tData.dwMountKungfuID and IsNoneSchoolKungfu(tData.dwMountKungfuID) then
        szSchoolImg = PlayerKungfuImg[tData.dwMountKungfuID]
    end

    szName              = UIHelper.TruncateStringReturnOnlyResult(szName, 6)

    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetString(self.LabelLevel, nLevel)

    UIHelper.SetString(self.LabelKill, nKill)
    UIHelper.SetString(self.LabelDeath, nDeath)
    UIHelper.SetString(self.LabelAssistKill, nAssistKill)

    UIHelper.SetString(self.LabelDamageNum, nDamageNum)
    UIHelper.SetString(self.LabelToppleTowers, nToppleTowers)
    UIHelper.SetString(self.LabelMoney, nMoney)

    UIHelper.SetSpriteFrame(self.ImgSchool, szSchoolImg)

    local bCanReport = true
    if (g_pClientPlayer and g_pClientPlayer.dwID == self.dwPlayerID) or self.nClientPlayerSide ~= self.tData.BattleFieldSide then
        bCanReport = false
    end
    UIHelper.SetTouchEnabled(self.WidgetHead, bCanReport)

    UIHelper.SetVisible(self.ImgSelectBg, self.dwPlayerID == UI_GetClientPlayerID())
end

function UILieXingDataSettleListWidget:UpdateExcellentInfo()
    local tData = self.tData

    local bEnd  = BattleFieldData.BattleField_IsEnd()

    UIHelper.SetVisible(self.LayoutState, bEnd)
    UIHelper.SetVisible(self.ImgMvp, bEnd)

    if bEnd then
        local tBFInfo    = BattleFieldData.GetBattleFieldInfo()

        local tExcellent = tBFInfo.tExcellentData[self.dwPlayerID] or {}
        local bMVP       = false

        for i = 1, MAX_EXCELLENT_COUNT do
            local iconTab = self["ImgIcon0" .. i]
            UIHelper.SetVisible(iconTab, false)
        end

        local nTabIndex = 1
        for k, dwID in ipairs(tExcellent) do
            if nTabIndex > 6 then
                break
            end

            if dwID == EXCELLENT_ID.BEST_COURSE then
                bMVP = true
            else
                --设置优秀表现图标
                local tLine = g_tTable.BFArenaExcellent:Search(dwID)
                if tLine then
                    local iconTab = self["ImgIcon0" .. nTabIndex]

                    UIHelper.SetVisible(iconTab, true)
                    local szIconPath = tLine.szMobileImagePath
                    UIHelper.SetSpriteFrame(iconTab, szIconPath)
                    nTabIndex = nTabIndex + 1
                end
            end
        end

        UIHelper.LayoutDoLayout(self.LayoutState)

        UIHelper.SetVisible(self.ImgMvp, bMVP)

        local nMVPScore = tData[PQ_STATISTICS_INDEX.SPECIAL_OP_7]
        UIHelper.SetString(self.LabelMvp, nMVPScore)
    end
end

function UILieXingDataSettleListWidget:UpdateEquipInfo()
    UIHelper.RemoveAllChildren(self.LayoutItem)

    local tList  = BattleFieldData.GetMobaEquip()

    local tEquip = tList[self.dwPlayerID] or {}

    for j = 1, MAX_EQUIP_COUNT do
        if tEquip[j] then
            local dwItemType, dwItemIndex = table.unpack(tEquip[j])

            local widgetItem              = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
            UIHelper.SetAnchorPoint(widgetItem._rootNode, 0, 0)

            widgetItem:OnInitWithTabID(dwItemType, dwItemIndex)
            widgetItem:SetClickNotSelected(true)

            widgetItem:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowItemTips(widgetItem._rootNode, dwItemType, dwItemIndex)
                end)
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutItem)
end

return UILieXingDataSettleListWidget