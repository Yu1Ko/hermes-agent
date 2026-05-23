-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITaskTarceSelectView
-- Date: 2023-06-01 14:56:06
-- Desc: 目标栏追踪界面 UITaskTarceSelectView
-- ---------------------------------------------------------------------------------

local UITaskTarceSelectView = class("UITaskTarceSelectView")

function UITaskTarceSelectView:OnEnter(tInfoItem)
    self.tInfoItem = tInfoItem

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayout(self.ScrollView)
        UIHelper.ScrollToLeft(self.ScrollView, 0)
    end)
end

function UITaskTarceSelectView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITaskTarceSelectView:BindUIEvent()
    
end

function UITaskTarceSelectView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITaskTarceSelectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UITaskTarceSelectView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollView)
    UIHelper.RemoveAllChildren(self.LayoutCardLess4)

    --print_table(self.tInfoItem)

    local nInfoCount = 0
    for szKey, tData in pairs(self.tInfoItem or {}) do
        if szKey == TraceInfoType.ActivityTip then
            nInfoCount = nInfoCount + #tData
        else
            nInfoCount = nInfoCount + 1
        end
    end

    local bLess = nInfoCount <= 4
    local layout

    if bLess then
        layout = self.LayoutCardLess4
    else
        layout = self.LayoutCard
    end

    for szKey, tData in pairs(self.tInfoItem or {}) do
        if szKey == TraceInfoType.ActivityTip then
            for _, dwActivityID in ipairs(tData) do
                local script = UIMgr.AddPrefab(PREFAB_ID.WidgetTaskTarceSelectCard, layout, szKey, {dwActivityID = dwActivityID})
                if not bLess then
                    UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
                end
            end
        else
            local script = UIMgr.AddPrefab(PREFAB_ID.WidgetTaskTarceSelectCard, layout, szKey, tData)
            if not bLess then
                UIHelper.SetAnchorPoint(script._rootNode, 0, 0) --不设Anch位置会歪，不知道为啥
            end
        end
    end

    if bLess then
        --数量少于4就不用ScrollView
        UIHelper.LayoutDoLayout(self.LayoutCardLess4)
    else
        UIHelper.LayoutDoLayout(self.LayoutCard)
        UIHelper.ScrollViewDoLayout(self.ScrollView)
        UIHelper.ScrollToLeft(self.ScrollView, 0)
    end

    UIHelper.SetVisible(self.ScrollView, not bLess)
    UIHelper.SetVisible(self.LayoutCardLess4, bLess)
end


return UITaskTarceSelectView