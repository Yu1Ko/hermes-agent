-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILieXingDataView
-- Date: 2024-01-30 19:46:55
-- Desc: 列星虚境数据
-- Prefab: PanelLieXingData / PanelLieXingSettle
-- ---------------------------------------------------------------------------------

---@class UILieXingDataView
local UILieXingDataView = class("UILieXingDataView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILieXingDataView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭界面
    self.BtnLeave               = self.BtnLeave --- 离开战场

    self.LabelTime              = self.LabelTime --- 开局时间

    self.LayoutSettleListLeft   = self.LayoutSettleListLeft --- 左侧红方队员列表
    self.LabelAllKillLeft       = self.LabelAllKillLeft --- 左侧累计击杀
    self.LabelAllPushTowerLeft  = self.LabelAllPushTowerLeft --- 左侧累计推塔
    self.LabelAllMoneyLeft      = self.LabelAllMoneyLeft --- 左侧累计星露

    self.LayoutSettleListRight  = self.LayoutSettleListRight --- 右侧蓝方队员列表
    self.LabelAllKillRight      = self.LabelAllKillRight --- 右侧累计击杀
    self.LabelAllPushTowerRight = self.LabelAllPushTowerRight --- 右侧累计推塔
    self.LabelAllMoneyRight     = self.LabelAllMoneyRight --- 右侧累计星露

    self.RichTextTime           = self.RichTextTime --- 多少秒后自动离开战场 richtext

    self.ImgVictory             = self.ImgVictory --- 胜利图片
    self.ImgDefeat              = self.ImgDefeat --- 失败图片
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UILieXingDataView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UILieXingDataView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    RemoteCallToServer("On_Moba_GetEquip")

    Timer.AddCycle(self, 0.5, function()
        self:UpdateTime()
    end)
end

function UILieXingDataView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILieXingDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        --退出战场
        if BattleFieldData.BattleField_IsEnd() then
            BattleFieldData.LeaveBattleField()
        else
            UIHelper.ShowConfirm(g_tStrings.STR_SURE_LEAVE_BATTLE, BattleFieldData.LeaveBattleField)
        end
    end)
end

function UILieXingDataView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function()
        self:UpdateInfo()
    end)
end

function UILieXingDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILieXingDataView:UpdateInfo()
    self:UpdateTime()

    self:UpdatePlayerInfoList()

    if BattleFieldData.BattleField_IsEnd() then
        local tBattleFieldInfo = BattleFieldData.GetBattleFieldInfo()
        UIHelper.SetVisible(self.ImgVictory, tBattleFieldInfo.bWin)
        UIHelper.SetVisible(self.ImgDefeat, not tBattleFieldInfo.bWin)
    end
end

function UILieXingDataView:UpdateTime()
    local szPassTime = BattleFieldData.GetMobaShowPassTime()

    UIHelper.SetString(self.LabelTime, szPassTime)

    local bEnd = BattleFieldData.BattleField_IsEnd()
    UIHelper.SetVisible(self.RichTextTime, bEnd)
    if bEnd then
        local tInfo       = BattleFieldData.GetBattleFieldInfo()
        local nBanishTime = tInfo.nBanishTime
        local nCurTime    = GetCurrentTime()

        if nBanishTime and nBanishTime >= nCurTime then
            local nTime = nBanishTime - nCurTime
            UIHelper.SetRichText(self.RichTextTime, string.format("<color=#d7f6ff>将在<color=#ffe26e>%d秒</c>后传出战场</c>", nTime))
        end
    end
end

function UILieXingDataView:UpdatePlayerInfoList()
    self:UpdateClientPlayerSide()
    self:UpdateOneSide(1)
    self:UpdateOneSide(2)
end

function UILieXingDataView:UpdateClientPlayerSide()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nClientPlayerSide
    local tStatistics = GetBattleFieldStatistics()
    for dwPlayerID, tData in pairs(tStatistics or {}) do
        if hPlayer.dwID == dwPlayerID then
            nClientPlayerSide = tData.BattleFieldSide
        end
    end

    self.nClientPlayerSide = nClientPlayerSide
end

function UILieXingDataView:UpdateOneSide(nSide)
    local layout, nPrefabID, labelAllKill, labelAllPushTower, labelAllMoney
    if nSide == 1 then
        layout, nPrefabID, labelAllKill, labelAllPushTower, labelAllMoney = self.LayoutSettleListLeft, PREFAB_ID.WidgetDataSettleListLeft, self.LabelAllKillLeft, self.LabelAllPushTowerLeft, self.LabelAllMoneyLeft
    else
        layout, nPrefabID, labelAllKill, labelAllPushTower, labelAllMoney = self.LayoutSettleListRight, PREFAB_ID.WidgetDataSettleListRight, self.LabelAllKillRight, self.LabelAllPushTowerRight, self.LabelAllMoneyRight
    end

    UIHelper.RemoveAllChildren(layout)

    local nAllKill, nAllPushTower, nAllMoney = 0, 0, 0

    local tStatistics                        = GetBattleFieldStatistics()

    for dwPlayerID, tData in pairs(tStatistics) do
        local nNowSide = tData.BattleFieldSide
        if nNowSide == (nSide - 1) then
            ---@see UILieXingDataSettleListWidget
            UIHelper.AddPrefab(nPrefabID, layout, dwPlayerID, tData, self.nClientPlayerSide)

            nAllKill      = nAllKill + tData[PQ_STATISTICS_INDEX.DECAPITATE_COUNT]
            nAllPushTower = nAllPushTower + tData[PQ_STATISTICS_INDEX.SPECIAL_OP_1]
            nAllMoney     = nAllMoney + tData[PQ_STATISTICS_INDEX.SPECIAL_OP_2]
        end
    end

    local szMoney = tostring(math.floor(nAllMoney / 100) / 10) .. "k"

    UIHelper.SetString(labelAllKill, nAllKill)
    UIHelper.SetString(labelAllPushTower, nAllPushTower)
    UIHelper.SetString(labelAllMoney, szMoney)

    UIHelper.LayoutDoLayout(layout)
end

return UILieXingDataView