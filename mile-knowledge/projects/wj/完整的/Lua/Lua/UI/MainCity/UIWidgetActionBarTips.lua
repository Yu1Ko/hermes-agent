-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetActionBarTips
-- Date: 2023-12-06 16:49:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetActionBarTips = class("UIWidgetActionBarTips")

function UIWidgetActionBarTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Close()
end

function UIWidgetActionBarTips:Show(tbStates, nCurState, scriptParent)
    self.nCurState = nCurState
    self.tbStates = tbStates
    self.scriptParent = scriptParent
    self:UpdateInfo()
end


function UIWidgetActionBarTips:Close()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetActionBarTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetActionBarTips:BindUIEvent()

end

function UIWidgetActionBarTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetActionBarTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetActionBarTips:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    self.tbScript = {}
    UIHelper.RemoveAllChildren(self.LabyOutTips)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    for nIndex, nState in ipairs(self.tbStates) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetActionBarTipsTog, self.LabyOutTips, self.ToggleGroup, nState, function()
            self.scriptParent:EnterState(nState)
            self:Close()
        end)
        self.tbScript[nState] = script
    end

    UIHelper.LayoutDoLayout(self.LabyOutTips)

    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
    self.nTimer = Timer.AddFrame(self, 1, function()
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.tbScript[self.nCurState]._rootNode)
    end)
end


return UIWidgetActionBarTips