-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueContent12
-- Date: 2024-06-11 10:45:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueContent12 = class("UIWidgetOldDialogueContent12")

function UIWidgetOldDialogueContent12:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetOldDialogueContent12:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOldDialogueContent12:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnContent_1, EventType.OnClick, function()
        self.tbData.callback()
    end)
end

function UIWidgetOldDialogueContent12:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self.scriptView:RawSetSelected(false)
    end)
end

function UIWidgetOldDialogueContent12:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOldDialogueContent12:UpdateInfo()
    local tbInfo = self.tbData
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80Shell)
    scriptView:OnInitWithTabID(tbInfo.dwTabType, tbInfo.dwTabIndex, tbInfo.nCount)
    scriptView:SetClickCallback(function(nTabType, nTabID)
        local _, itemTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.LEFT_CENTER)
        itemTips:OnInitWithTabID(nTabType, nTabID)
        itemTips:SetBtnState({})
    end)
    scriptView:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem)
    scriptView:SetToggleSwallowTouches(false)
    if tbInfo.szIconName ~= "" then
        scriptView:SetIconByTexture(tbInfo.szIconName)
        scriptView:SetIconVisible(true)
    end
    UIHelper.SetRichText(self.RichTextContent, tbInfo.szContent)
    self.scriptView = scriptView

    UIHelper.SetSwallowTouches(self.BtnContent_1, false)
end


return UIWidgetOldDialogueContent12