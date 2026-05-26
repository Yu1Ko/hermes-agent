-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIWidgetScoreLimit
-- Date: 2025-01-14 20:10:10
-- Desc: 年兽陶罐-自动砸罐 分数选择 PanelNianShouTaobaoGuanSetting-WidgetScoreLimit
-- ---------------------------------------------------------------------------------

local UIWidgetScoreLimit = class("UIWidgetScoreLimit")

function UIWidgetScoreLimit:OnEnter(szTitle, nScore)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetLabel(self.LabelSettingsMultipleChoiceTitle, szTitle)
    UIHelper.SetLabel(self.RichTextSettingsMultipleChoice, nScore)
end

function UIWidgetScoreLimit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetScoreLimit:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnClick, function()
        if self.fnCallback then
            self.fnCallback()
        end
    end)
end

function UIWidgetScoreLimit:RegEvent()
    Event.Reg(self, EventType.OnMYTaoguanScoreLimitChanged, function(szID, nScore)
        if self.szID == szID then
            UIHelper.SetLabel(self.RichTextSettingsMultipleChoice, nScore)
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:RawSetSelected(false)
        end
    end)
end

function UIWidgetScoreLimit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetScoreLimit:UpdateInfo()
    
end

function UIWidgetScoreLimit:SetID(szID)
    self.szID = szID
end

function UIWidgetScoreLimit:BindCallback(fnCallback)
    self.fnCallback = fnCallback
end

function UIWidgetScoreLimit:SetItemIcon(dwTabType, dwIndex)
    self.scriptIcon = self.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItemIcon)
    self.scriptIcon:OnInitWithTabID(dwTabType, dwIndex)
    self.scriptIcon:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
        if bSelected then
            local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemIcon, TipsLayoutDir.LEFT_CENTER)
            scriptTip:OnInitWithTabID(dwTabType, dwIndex)
        end
    end)
end


return UIWidgetScoreLimit