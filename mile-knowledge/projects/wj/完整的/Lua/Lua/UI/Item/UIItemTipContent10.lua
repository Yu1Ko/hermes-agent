-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent10
-- Date: 2023-11-30 19:53:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent10 = class("UIItemTipContent10")

function UIItemTipContent10:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIItemTipContent10:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent10:BindUIEvent()
    
end

function UIItemTipContent10:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent10:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipContent10:UpdateInfo()
    local bShow = false
    if self.tbInfo then
        UIHelper.RemoveAllChildren(self.LayoutTrace)
        UIHelper.SetTouchDownHideTips(self.LayoutTrace, false)
        
        if self.tbInfo and self.tbInfo[1] then
            for i, tbInfo in ipairs(self.tbInfo[1]) do
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10TraceCell, self.LayoutTrace)
                script:OnEnter(tbInfo)
                bShow = true
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutTrace)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode,true,true)
    end
    UIHelper.SetVisible(self._rootNode, bShow)
end

function UIItemTipContent10:UpdateUseInfo(tbUse)
    local bShow = false
    UIHelper.RemoveAllChildren(self.LayoutTrace)
    UIHelper.SetTouchDownHideTips(self.LayoutTrace, false)
    if tbUse then
        for i, tbInfo in ipairs(tbUse) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10TraceCell, self.LayoutTrace)
            script:OnEnter(tbInfo)
            bShow = true
        end
    end
    UIHelper.SetVisible(self._rootNode, bShow)
    UIHelper.SetLabel(self.LabelAttachStatus, "使用途径")
    UIHelper.LayoutDoLayout(self.LayoutTrace)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode,true,true)
end


return UIItemTipContent10