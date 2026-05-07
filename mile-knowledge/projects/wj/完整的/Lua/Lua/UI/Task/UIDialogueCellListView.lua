-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDialogueCellList
-- Date: 2022-11-29 10:31:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDialogueCellList = class("UIDialogueCellList")

function UIDialogueCellList:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIDialogueCellList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDialogueCellList:BindUIEvent()

end

function UIDialogueCellList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDialogueCellList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDialogueCellList:UpdateInfo()
    
    UIHelper.SetVisible(self.ScrollViewDialogueContent, true)
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetDialogueCell, self.LayoutDialogue, self.tbData)

    UIHelper.LayoutDoLayout(self.LayoutDialogue)
    UIHelper.ScrollViewDoLayout(self.ScrollViewDialogueContent)
    local nButtonCount = PlotMgr.GetItemTypeCount(PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON)
    if nButtonCount >= 3 then
        UIHelper.ScrollToTop(self.ScrollViewDialogueContent, 0)
    else
        UIHelper.ScrollToPercent(self.ScrollViewDialogueContent, 100, 0)
    end
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
end


return UIDialogueCellList