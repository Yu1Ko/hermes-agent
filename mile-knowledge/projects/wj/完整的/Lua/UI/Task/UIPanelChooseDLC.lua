-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelChooseDLC
-- Date: 2022-11-14 14:58:20
-- Desc: ?
-- ---------------------------------------------------------------------------------
local QuestType = {
    All             = 1,--全部
    Course          = 2,--历程(主线)
    Activity        = 3,--活动
    Daily           = 4,--日常
    Branch          = 5,--支线
    Other           = 6,--其它
}

local UIPanelChooseDLC = class("UIPanelChooseDLC")

function UIPanelChooseDLC:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.ScrollViewDoLayout(self.ScrollView_DLCList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentRight)

end

function UIPanelChooseDLC:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelChooseDLC:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function()
        local nID = 6
        RemoteCallToServer("On_UIQuest_Accept", "StartDLC", nID)
        UIMgr.Close(self)
        --LOG.INFO("BtnStart UIPanelChooseDLC clicked")
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for _, toggleNode in ipairs(self.DLCToggles) do
        if _ == 1 then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, toggleNode)
            UIHelper.BindUIEvent(toggleNode, EventType.OnSelectChanged, function(bSelected)
                if bSelected then
                    LOG.INFO("Index %d is selected.",_)
                end
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollView_DLCList)
    UIHelper.ScrollToTop(self.ScrollView_DLCList, 0)
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, 0)

end

function UIPanelChooseDLC:RegEvent()

end

function UIPanelChooseDLC:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelChooseDLC:UpdateDetail()
    --Event.UnReg(self, EventType.XXX)
end

return UIPanelChooseDLC