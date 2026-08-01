-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDayTaskCell
-- Date: 2026-03-09 16:35:10
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbBgList = {
    [1] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardShejiao",
    [2] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardJiyuan",
    [3] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardWaiguan",
    [4] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardQiyuan",
    [5] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardJiyi",
    [6] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardXiuxian",
    [7] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardMijing",
    [8] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardZhenying",
    [9] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardJingji",
    [10] = "UIAtlas2_Collection_CollectionNewIcon_MiniCardHuoyue",
}

local UIWidgetDayTaskCell = class("UIWidgetDayTaskCell")

function UIWidgetDayTaskCell:OnEnter(tbCardInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbCardInfo = tbCardInfo
    self.nIndex = nIndex
    self:UpdateQuestInfo()
end

function UIWidgetDayTaskCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDayTaskCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReFresh, EventType.OnClick, function()
        UIHelper.PlayAni(self, self._rootNode, "AniDayTaskList")
        Timer.Add(self, 0.2, function ()
            Event.Dispatch("ON_COLLECTION_CARD_FRESH")
            RemoteCallToServer("On_Daily_FreshCourse", self.nIndex)
        end)
    end)

    UIHelper.BindUIEvent(self.WidgetDayTask, EventType.OnClick, function()
        CollectionData.OnClickCard(self.tbCardInfo)
    end)
end

function UIWidgetDayTaskCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetDayTaskCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDayTaskCell:UpdateQuestInfo()
    UIHelper.SetVisible(self.ImgComplete, self.tbCardInfo[2])
    UIHelper.SetEnable(self.WidgetDayTask, not self.tbCardInfo[2])

    self.tbCardInfo = CollectionDailyData.GetDailyQuestInfo(self.tbCardInfo[1])
    UIHelper.SetString(self.LabelDayTaskName, UIHelper.GBKToUTF8(self.tbCardInfo.szTypeName))
    local szImageBgPath = self.tbCardInfo.szImageBgPath
    if szImageBgPath then
        local szPath = DailyQuestBgPath[UIHelper.GBKToUTF8(szImageBgPath)]
        UIHelper.SetSpriteFrame(self.ImgDayTaskLevel, szPath)
    end
    UIHelper.SetString(self.LabelDayTaskInfo, UIHelper.GBKToUTF8(self.tbCardInfo.szDesc))

    local nType = self.tbCardInfo.nType
    if nType then
        UIHelper.SetSpriteFrame(self.ImgDayTaskBg, tbBgList[nType])
    end
end


return UIWidgetDayTaskCell