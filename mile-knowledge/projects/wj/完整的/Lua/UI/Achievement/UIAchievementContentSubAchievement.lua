-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentSubAchievement
-- Date: 2023-02-21 11:16:48
-- Desc: 隐元秘鉴 - 类别成就详情 - 成就widget - 成就详细信息 - 子成就widget
-- Prefab: WidgetAchievementContentScheduleCell
-- ---------------------------------------------------------------------------------

local UIAchievementContentSubAchievement = class("UIAchievementContentSubAchievement")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentSubAchievement:_LuaBindList()
    self.LabelName                  = self.LabelName --- 子成就名称
    self.ImgFinishStatus            = self.ImgFinishStatus --- 完成状态（仅完成时显示）

    self.BtnShowAchievement         = self.BtnShowAchievement --- 跳转到对应成就
    self.LabelShortDesc             = self.LabelShortDesc --- 子成就描述

    self.WidgetTitleContent         = self.WidgetTitleContent --- 带描述的组件
    self.WidgetNavigation           = self.WidgetNavigation --- 导航箭头组件
    self.WidgetWithoutDesc          = self.WidgetWithoutDesc --- 不带描述的组件

    self.LabelNameWithoutDesc       = self.LabelNameWithoutDesc --- 名称-不带描述
    self.ImgFinishStatusWithoutDesc = self.ImgFinishStatusWithoutDesc --- 完成状态-不带描述
end

function UIAchievementContentSubAchievement:OnEnter(dwAchievementID)
    self.dwAchievementID = dwAchievementID

    self.aAchievement    = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentSubAchievement:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentSubAchievement:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShowAchievement, EventType.OnClick, function()
        local a = self.aAchievement
        if a.nVisible == 0 then
            return
        end

        local bJumpFromOtherSystem = AchievementData.bJumpFromOtherSystem

        UIMgr.SetCloseCallback(VIEW_ID.PanelAchievementContent, function ()
            AchievementData.bJumpFromOtherSystem = bJumpFromOtherSystem
        end)

        UIMgr.Open(VIEW_ID.PanelAchievementContent, a.dwGeneral, a.dwSub, a.dwDetail, a.dwID)

        Event.Dispatch(EventType.CloseSubOrSeriesAchievement)
    end)
end

function UIAchievementContentSubAchievement:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementContentSubAchievement:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentSubAchievement:UpdateInfo()
    local bFinish            = g_pClientPlayer.IsAchievementAcquired(self.dwAchievementID)

    -- 是否跳转到指定成就
    local bJumpToAchievement = self.aAchievement.nVisible ~= 0
    -- 是否有描述
    local bHasDesc           = self.aAchievement.szShortDesc and self.aAchievement.szShortDesc ~= ""

    if bHasDesc then
        -- 有描述的情况下，标题最多12+1字符，内容52+1字符
        local szName, szDesc = AchievementData.GetSubAchievementNameAndDesc(self.aAchievement, 12, 52)

        UIHelper.SetString(self.LabelName, szName)
        UIHelper.SetVisible(self.ImgFinishStatus, bFinish)

        UIHelper.SetString(self.LabelShortDesc, szDesc)
    else
        -- 仅标题的情况下，标题不限长度
        local szName = UIHelper.GBKToUTF8(self.aAchievement.szName)

        UIHelper.SetString(self.LabelNameWithoutDesc, szName)
        UIHelper.SetVisible(self.ImgFinishStatusWithoutDesc, bFinish)
    end

    UIHelper.SetVisible(self.WidgetTitleContent, bHasDesc)
    UIHelper.SetVisible(self.WidgetNavigation, bJumpToAchievement)
    UIHelper.SetVisible(self.WidgetWithoutDesc, not bHasDesc)

    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIAchievementContentSubAchievement