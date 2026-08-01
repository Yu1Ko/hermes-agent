-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIConductorNoticeTips
-- Date: 2024-07-30 17:40:56
-- Desc: 帮会联赛指挥面板
-- Prefab: WidgetConductorNoticeTips
-- ---------------------------------------------------------------------------------

local BLUE_INDEX            = 0
local RED_INDEX             = 1

---@class UIConductorNoticeTips
local UIConductorNoticeTips = class("UIConductorNoticeTips")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIConductorNoticeTips:_LuaBindList()
    self.BtnClose            = self.BtnClose --- 关闭按钮

    self.BtnMoraleUp         = self.BtnMoraleUp --- 士气提升按钮
    self.LabelMoney_MoraleUp = self.LabelMoney_MoraleUp --- 士气提升所需资源
    self.BtnFixFlag          = self.BtnFixFlag --- 大旗修复按钮
    self.LabelMoney_FixFlag  = self.LabelMoney_FixFlag --- 大旗修复所需资源
    self.BtnViewUp           = self.BtnViewUp --- 视野提升按钮
    self.LabelMoney_ViewUp   = self.LabelMoney_ViewUp --- 视野提升所需资源

    self.LabelMoraleUp       = self.LabelMoraleUp --- 士气提升按钮的文本
    self.LabelFixFlag        = self.LabelFixFlag --- 大旗修复按钮的文本
    self.LabelViewUp         = self.LabelViewUp --- 视野提升按钮的文本

    self.LabelResource       = self.LabelResource --- 可用/累计资源
    self.LayoutResource      = self.LayoutResource --- 资源上层的layout

    self.LabelMoraleUpLevel  = self.LabelMoraleUpLevel --- 士气值
    self.LabelBloodCount     = self.LabelBloodCount --- 大旗血量

    self.BtnTeach            = self.BtnTeach --- 教学按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIConductorNoticeTips:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    ---@class TongFightInfo 帮会联赛信息
    ---@field szTongName string 帮会名字
    ---@field nFlagBloodPer number 当前大旗手血量百分比,10000=100%
    ---@field nCurResource number 当前资源
    ---@field nAllResource number 累计资源
    ---@field nKill number 对应nKill, 击杀数
    ---@field nCurTower number 剩余箭塔数量
    ---@field nEncourageLv number 鼓舞士气等级
    ---@field nCenterID number 对应的centerID
    ---@field nEquipAvg number 平均装分
    ---@field nCurMan number 在场人数
    ---@field nFlagTreatNextTime number 修复大旗的下次可用时间点
    ---@field nOpenFogNextTime number 视野提升的下次可用时间点
    ---@field nEncourageNextTime number 士气提升的下次可用时间点
    ---@field EncourageCost number 士气提升 需要消耗的资源数
    ---@field FixFlagCost number 大旗修复 需要消耗的资源数
    ---@field OpenFogCost number 视野提升 需要消耗的资源数
    ---@field nDragonTime number 大龙buff的结束时间点
    ---@field nFogTime number 全局视野的结束时间

    ---@class TongFightGlobalInfo 帮会联赛整体信息
    ---@field EndTime number 比赛结束的时间戳
    ---@field nMapLevel number 比赛等级
    ---@field nVipLevel number TONG_LEAGUE_KEYPERSONNEL_TYPE 0=普通人,1=核心人员,2=总指挥
end

function UIConductorNoticeTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddFrameCycle(self, 1, function()
        self:UpdateButtonState()
    end)
end

function UIConductorNoticeTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

local tLeaderOperation = {
    MoraleUp = 1, --- 士气提升
    FixFlag = 2, --- 大旗修复
    ViewUp = 3, --- 视野提升
}

local function doLeaderOperate(nOperation)
    UIHelper.RemoteCallToServer("On_TongWar_LeaderOperate", nOperation)
    LOG.DEBUG("On_TongWar_LeaderOperate %d", nOperation)
end

function UIConductorNoticeTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIHelper.RemoveFromParent(self._rootNode, true)
    end)

    UIHelper.BindUIEvent(self.BtnMoraleUp, EventType.OnClick, function()
        doLeaderOperate(tLeaderOperation.MoraleUp)
    end)

    UIHelper.BindUIEvent(self.BtnFixFlag, EventType.OnClick, function()
        doLeaderOperate(tLeaderOperation.FixFlag)
    end)

    UIHelper.BindUIEvent(self.BtnViewUp, EventType.OnClick, function()
        doLeaderOperate(tLeaderOperation.ViewUp)
    end)

    UIHelper.BindUIEvent(self.BtnTeach, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesLittle, 689)
    end)
end

function UIConductorNoticeTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_SYNC_SCENE_TEMP_CUSTOM_DATA", function()
        self:UpdateInfo()
    end)
end

function UIConductorNoticeTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function GetCenterNameByID(tCenterList, dwCenterID)
    if (not tCenterList) or IsTableEmpty(tCenterList) then
        return
    end

    for _, v in pairs(tCenterList) do
        if v.dwCenterID == dwCenterID then
            return v.szCenterName
        end
    end
end

function UIConductorNoticeTips:UpdateInfo()
    self:UpdateDetailInfo()

    self:UpdateLeaderOperationCostInfo()

    self:UpdateButtonState()
end

function UIConductorNoticeTips:UpdateDetailInfo()
    local tInfo          = BattleFieldData.GetTongFight2024Info()
    local nSide          = g_pClientPlayer.nBattleFieldSide

    local tSideInfo      = tInfo[nSide]

    local szResource     = string.format("%d/%d", tSideInfo.nCurResource, tSideInfo.nAllResource)
    local nMoraleUpLevel = tSideInfo.nEncourageLv
    local szBloodCount   = string.format("%.0f%%", tSideInfo.nFlagBloodPer / 100)

    UIHelper.SetString(self.LabelResource, szResource)
    UIHelper.LayoutDoLayout(self.LayoutResource)

    UIHelper.SetString(self.LabelMoraleUpLevel, nMoraleUpLevel)
    UIHelper.SetString(self.LabelBloodCount, szBloodCount)
end

function UIConductorNoticeTips:UpdateLeaderOperationCostInfo()
    local tInfo     = BattleFieldData.GetTongFight2024Info()
    local nSide     = g_pClientPlayer.nBattleFieldSide

    local tSideInfo = tInfo[nSide]

    UIHelper.SetString(self.LabelMoney_MoraleUp, tSideInfo.EncourageCost)
    UIHelper.SetString(self.LabelMoney_FixFlag, tSideInfo.FixFlagCost)
    UIHelper.SetString(self.LabelMoney_ViewUp, tSideInfo.OpenFogCost)
end

function UIConductorNoticeTips:UpdateButtonState()
    local tInfo       = BattleFieldData.GetTongFight2024Info()
    local nSide       = g_pClientPlayer.nBattleFieldSide

    local tSideInfo   = tInfo[nSide]

    local fnUpdateBtn = function(label, btn, szNormalText, nNextCanUseTime)
        local nCurrentTime = GetGSCurrentTime()
        local nCD          = nNextCanUseTime - nCurrentTime

        if nCD > 0 then
            UIHelper.SetString(label, string.format("%d%s", nCD, g_tStrings.STR_BUFF_H_TIME_S_SHORT))
            UIHelper.SetButtonState(btn, BTN_STATE.Disable)
        else
            local bCanOperate = self:GetIdentity() ~= TONG_LEAGUE_KEYPERSONNEL_TYPE.ORDINARY

            UIHelper.SetString(label, szNormalText)
            UIHelper.SetButtonState(btn, bCanOperate and BTN_STATE.Normal or BTN_STATE.Disable)
        end
    end

    fnUpdateBtn(self.LabelMoraleUp, self.BtnMoraleUp, "提升", tSideInfo.nEncourageNextTime)
    fnUpdateBtn(self.LabelFixFlag, self.BtnFixFlag, "修复", tSideInfo.nFlagTreatNextTime)
    fnUpdateBtn(self.LabelViewUp, self.BtnViewUp, "使用", tSideInfo.nOpenFogNextTime)
end

function UIConductorNoticeTips:GetIdentity()
    local tInfo = BattleFieldData.GetTongFight2024Info()

    ---@see TONG_LEAGUE_KEYPERSONNEL_TYPE
    return tInfo.nVipLevel or TONG_LEAGUE_KEYPERSONNEL_TYPE.ORDINARY
end

return UIConductorNoticeTips