-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITravelAchieveTip
-- Date: 2024-12-16 18:40:21
-- Desc: 侠客出行奖励 成就信息
-- Prefab: WidgetTravelAchieveTip
-- ---------------------------------------------------------------------------------

---@class UITravelAchieveTip
local UITravelAchieveTip = class("UITravelAchieveTip")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITravelAchieveTip:_LuaBindList()
    self.LabelAchievee = self.LabelAchievee --- 成就描述
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UITravelAchieveTip:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UITravelAchieveTip:OnEnter(dwAchievementID, nAddCount)
    self.nAddCount = nAddCount
    
    -- 外部传入的原本的成就信息
    self.dwBaseAchievementID     = dwAchievementID
    self.aBaseAchievement        = Table_GetAchievement(dwAchievementID)

    -- 由于成就可能是系列成就，而系列成就将展示当前阶段的成就的信息，所以这里另行计算实际用于展示的成就
    local dwCurrentAchievementID = dwAchievementID

    local szSeries               = self.aBaseAchievement.szSeries
    if szSeries and string.len(szSeries) > 0 then
        dwCurrentAchievementID = AchievementData.GetCurrentStageSeriesAchievementID(dwAchievementID, self.dwPlayerID)
    end

    -- 当前实际展示的成就（仅系列成就可能与外部传入的成就不同）
    self.dwAchievementID = dwCurrentAchievementID
    self.aAchievement    = Table_GetAchievement(dwCurrentAchievementID)
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UITravelAchieveTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITravelAchieveTip:BindUIEvent()

end

function UITravelAchieveTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITravelAchieveTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITravelAchieveTip:UpdateInfo()
    local aAchievement = self.aAchievement
    
    local szName = UIHelper.GBKToUTF8(aAchievement.szName)
    
    local szProgress = ""
    local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(aAchievement.szCounters)
    if bFoundCounter then
        szProgress = string.format(" %d/%d", nProgress, nMaxProgress)
    end
    
    local szInfo = string.format("%s %s(+%d)", szName, szProgress, self.nAddCount)
    UIHelper.SetString(self.LabelAchievee, szInfo)
end

return UITravelAchieveTip