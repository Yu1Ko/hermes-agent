-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementListItem
-- Date: 2023-02-16 11:16:26
-- Desc: 隐元秘鉴 - 成就类别列表 - 单个类别
-- Prefab: WidgetAchievementListEntrance
-- ---------------------------------------------------------------------------------

local UIAchievementListItem = class("UIAchievementListItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementListItem:_LuaBindList()
    self.BtnOpenCategoryView   = self.BtnOpenCategoryView --- 打开该类别的成就界面
    self.ImgCategory           = self.ImgCategory --- 该类别的图片
    self.LabelCategoryName     = self.LabelCategoryName --- 类别名称
    self.LabelCategoryProgress = self.LabelCategoryProgress --- 类别进度
end

function UIAchievementListItem:OnEnter(nPanelType, nCategoryType, szCategoryName, nFinished, nTotal, dwPlayerID)
    self.nPanelType     = nPanelType --- 枚举 ACHIEVEMENT_PANEL_TYPE
    self.nCategoryType  = nCategoryType
    self.szCategoryName = szCategoryName
    self.nFinished      = nFinished
    self.nTotal         = nTotal
    self.dwPlayerID     = dwPlayerID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementListItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOpenCategoryView, EventType.OnClick, function()
        ---@see UIAchievementCategoryDetailView#OnEnter
        local bOpenFromAchievementSystem = not AchievementData.bJumpFromOtherSystem
        local bDoNotResetFilterData = true
        UIMgr.Open(VIEW_ID.PanelAchievementContent, self.nPanelType, self.nCategoryType, nil, nil, self.dwPlayerID, bOpenFromAchievementSystem, bDoNotResetFilterData)
    end)
end

function UIAchievementListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementListItem:UpdateInfo()
    local szImgCategory = string.format("UIAtlas2_Achievement_AchievementTog_tog_%d.png", self.nCategoryType)
    UIHelper.SetSpriteFrame(self.ImgCategory, szImgCategory)

    UIHelper.SetString(self.LabelCategoryName, self.szCategoryName)
    UIHelper.SetString(self.LabelCategoryProgress, string.format("%d/%d", self.nFinished, self.nTotal))
end

return UIAchievementListItem