-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueItemShell
-- Date: 2024-04-29 15:06:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueItemShell = class("UIWidgetOldDialogueItemShell")

function UIWidgetOldDialogueItemShell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo(tbInfo)
end

function UIWidgetOldDialogueItemShell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOldDialogueItemShell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShell, EventType.OnClick, function()
        if self.tbInfo.nTipID then
            Event.Dispatch("SHOW_OLDDIALOGUE_TIP", false, self.scriptView, nil, nil, self.tbInfo.nTipID)
        else
            Event.Dispatch("SHOW_OLDDIALOGUE_TIP", true, self.scriptView, self.tbInfo.dwTabType, self.tbInfo.dwTabIndex, nil)
        end
    end)
end

function UIWidgetOldDialogueItemShell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOldDialogueItemShell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOldDialogueItemShell:UpdateInfo(tbInfo)
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WIdgetItem80)
    scriptView:OnInitWithTabID(tbInfo.dwTabType, tbInfo.dwTabIndex, tbInfo.nCount)
    scriptView:SetClickCallback(function(nTabType, nTabID)
        tbInfo.callback()
    end)
    scriptView:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem)
    if tbInfo.szIconName ~= "" then
        scriptView:SetIconByTexture(tbInfo.szIconName)
        scriptView:SetIconVisible(true)
    end

    if tbInfo.nTipID then 
        scriptView:SetLongPressCallback(function()
            Event.Dispatch("SHOW_OLDDIALOGUE_TIP", false, scriptView, nil, nil, tbInfo.nTipID)
        end)
    end
    self.scriptView = scriptView
end


return UIWidgetOldDialogueItemShell