-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementPartnerItem
-- Date: 2024-12-20 18:40:21
-- Desc: 侠客出行奖励 成就信息
-- Prefab: WidgetAchievementPartnerItem
-- ---------------------------------------------------------------------------------

---@class UIAchievementPartnerItem
local UIAchievementPartnerItem = class("UIAchievementPartnerItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementPartnerItem:_LuaBindList()
    self.ImgIcon    = self.ImgIcon --- 图标
    self.LabelName  = self.LabelName --- 名称
    self.LabelCount = self.LabelCount --- 当前计数进度
    self.BtnGo      = self.BtnGo --- 跳转到对应成就
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIAchievementPartnerItem:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param uiPartnerTravelAchievePopView UIPartnerTravelAchievePopView
function UIAchievementPartnerItem:OnEnter(dwAchievementID, uiPartnerTravelAchievePopView)
    self.uiPartnerTravelAchievePopView = uiPartnerTravelAchievePopView

    -- 外部传入的原本的成就信息
    self.dwBaseAchievementID           = dwAchievementID
    self.aBaseAchievement              = Table_GetAchievement(dwAchievementID)

    -- 由于成就可能是系列成就，而系列成就将展示当前阶段的成就的信息，所以这里另行计算实际用于展示的成就
    local dwCurrentAchievementID       = dwAchievementID

    local szSeries                     = self.aBaseAchievement.szSeries
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

function UIAchievementPartnerItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementPartnerItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        UIHelper.TempHideCurrentViewOnSomeViewOpen(self.uiPartnerTravelAchievePopView, {
            VIEW_ID.PanelAchievementContent,
        })

        local a = self.aAchievement
        UIMgr.Open(VIEW_ID.PanelAchievementContent, a.dwGeneral, a.dwSub, a.dwDetail, a.dwID, self.dwPlayerID)
    end)
end

function UIAchievementPartnerItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementPartnerItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementPartnerItem:UpdateInfo()
    local aAchievement                           = self.aAchievement

    local szName                                 = UIHelper.GBKToUTF8(aAchievement.szName)
    local szColor = "#D7F6FF"

    local szProgress                             = ""
    if AchievementData.IsAchievementAcquired(self.dwBaseAchievementID, self.aBaseAchievement) then
        szProgress = "已完成"
        szColor = FontColorID.ImportantGreen
    else
        local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(aAchievement.szCounters)
        if bFoundCounter then
            szProgress = string.format(" %d/%d", nProgress, nMaxProgress)
        end
    end

    UIHelper.SetItemIconByIconID(self.ImgIcon, aAchievement.nIconID)
    UIHelper.SetString(self.LabelName, UIHelper.TruncateStringReturnOnlyResult(szName, 9, "…", 8))
    UIHelper.SetString(self.LabelCount, szProgress)
    
    UIHelper.SetTextColor(self.LabelCount, UIHelper.ChangeHexColorStrToColor(szColor))
end

return UIAchievementPartnerItem