-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementAward
-- Date: 2023-02-13 19:19:28
-- Desc: 隐元秘鉴 - 资历奖励 - 小部件
-- Prefab: WidgetAchievementAward
-- ---------------------------------------------------------------------------------

local UIAchievementAward = class("UIAchievementAward")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementAward:_LuaBindList()
    self.LabelAwardTitle       = self.LabelAwardTitle --- 奖励标题
    self.LabelAchievementPoint = self.LabelAchievementPoint --- 所需资历
    self.ImgAwardBadge         = self.ImgAwardBadge --- 图标
    self.ImgFinishStatus       = self.ImgFinishStatus --- 完成状态图标，仅完成时需要显示
    self.WidgetItem            = self.WidgetItem --- 奖励道具widget
end

function UIAchievementAward:OnEnter(szTitle, szAwardImagePath, nRequiredAchievementPoint, nCurrentAchievementPoint, nItemType, nItemID)
    self.szTitle                   = szTitle
    self.szAwardImagePath          = szAwardImagePath
    self.nRequiredAchievementPoint = nRequiredAchievementPoint
    self.nCurrentAchievementPoint  = nCurrentAchievementPoint
    self.nItemType                 = nItemType
    self.nItemID                   = nItemID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementAward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementAward:BindUIEvent()

end

function UIAchievementAward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:HideItemTip()
    end)
end

function UIAchievementAward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementAward:UpdateInfo()
    local bFinish = self.nCurrentAchievementPoint >= self.nRequiredAchievementPoint

    UIHelper.SetString(self.LabelAwardTitle, self.szTitle)
    UIHelper.SetString(self.LabelAchievementPoint, self.nRequiredAchievementPoint)
    UIHelper.SetSpriteFrame(self.ImgAwardBadge, self.szAwardImagePath)
    UIHelper.SetVisible(self.ImgFinishStatus, bFinish)

    local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    widgetItem:OnInitWithTabID(self.nItemType, self.nItemID)
    UIHelper.SetToggleGroupIndex(widgetItem.ToggleSelect, ToggleGroupIndex.AchievementAward)

    widgetItem:SetClickCallback(function(nItemType, nItemIndex)
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowItemTips(widgetItem._rootNode, self.nItemType, self.nItemID, false)
        end)
    end)

    if not bFinish then
        Timer.AddFrame(self, 1, function()
            UIHelper.SetNodeGray(widgetItem._rootNode, true, true)
        end)
    end

    self.widgetItem = widgetItem
end

function UIAchievementAward:HideItemTip()
    if self.widgetItem then
        self.widgetItem:SetSelected(false)
    end
end

return UIAchievementAward