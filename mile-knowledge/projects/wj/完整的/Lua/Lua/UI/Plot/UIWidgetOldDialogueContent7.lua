-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueContent7
-- Date: 2023-05-15 16:18:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueContent7 = class("UIWidgetOldDialogueContent7")

function UIWidgetOldDialogueContent7:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetOldDialogueContent7:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOldDialogueContent7:BindUIEvent()
    
end

function UIWidgetOldDialogueContent7:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOldDialogueContent7:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetOldDialogueContent7:Init()
    if not self.nLen then 
        self.nLen = 500
    end
end

function UIWidgetOldDialogueContent7:AddPrefab(nPrefabID, ...)
    self:Init()

    if nPrefabID == PREFAB_ID.WidgetOldDialogueItemShell then 
        self:OnGetItem()
    end

    local scriptView = UIHelper.AddPrefab(nPrefabID, self.LayoutContent, ...)

    if nPrefabID == PREFAB_ID.WidgetOldDialogueContent1 and self:GetHasItem() then
        UIHelper.SetPositionY(scriptView._rootNode, -27, self.LayoutContent)
    end

    local nChildWidth = scriptView.GetWidth and scriptView:GetWidth() or PlotMgr.GetPrefabIDWidthByItemType(nPrefabID)
    self.nLen = self.nLen - nChildWidth

    return scriptView
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOldDialogueContent7:UpdateInfo()

end

function UIWidgetOldDialogueContent7:GetRemainLen()
    return self.nLen
end

function UIWidgetOldDialogueContent7:GetMaxLen()
    return 500
end

function UIWidgetOldDialogueContent7:GetHasItem()
    return self.bHasItem
end

function UIWidgetOldDialogueContent7:OnGetItem()
    if not self.bHasItem then
        self.bHasItem = true
        UIHelper.SetHeight(self.LayoutContent, 80)
        UIHelper.SetPositionY(self.LayoutContent, -40)
    end
end


return UIWidgetOldDialogueContent7