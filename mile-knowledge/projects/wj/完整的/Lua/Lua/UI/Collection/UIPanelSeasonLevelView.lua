-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSeasonLevelView
-- Date: 2026-03-12 15:41:06
-- Desc: ?
-- ---------------------------------------------------------------------------------
--UIMgr.Open(VIEW_ID.PanelSeasonLevel)
local UIPanelSeasonLevelView = class("UIPanelSeasonLevelView")

function UIPanelSeasonLevelView:OnEnter(nClass)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    self:UpdateRedPoint()
    
    local bHaveReward = self:HasCanGetReward()
    if bHaveReward then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.TogReward)
    else
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.TogTask)
    end

    if nClass and self.WidgetAnchorTask then
        local tbScript = UIHelper.GetBindScript(self.WidgetAnchorTask)
        tbScript:SetClass(nClass)
    end
end

function UIPanelSeasonLevelView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSeasonLevelView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
       UIMgr.Open(VIEW_ID.PanelChatSocial)
    end)

    UIHelper.BindUIEvent(self.BtnSeasonRewardAll, EventType.OnClick, function()
       UIMgr.Open(VIEW_ID.PanelSeasonRewardList)
    end)
end

function UIPanelSeasonLevelView:RegEvent()
    Event.Reg(self, "CB_SA_TaskUpdate", function()
        self:UpdateRedPoint()
    end)
    
    Event.Reg(self, "CB_SA_SetPersonReward", function()
        self:UpdateRedPoint()
    end)
end

function UIPanelSeasonLevelView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSeasonLevelView:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogReward)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogTask)
end

function UIPanelSeasonLevelView:HasCanGetReward()
    local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then 
        return false 
    end
    
    for nClass, tClassInfo in pairs(tRankInfo) do
        if tClassInfo.tList then
            for nRankLv, nState in pairs(tClassInfo.tList) do
                if nState == 1 then
                    return true
                end
            end
        end
    end
    
    return false
end

function UIPanelSeasonLevelView:UpdateRedPoint()
    local bRed = CollectionData.AllSeasonLevelHasCanGet()
    UIHelper.SetVisible(self.ImgRedPoint, bRed)
end

return UIPanelSeasonLevelView