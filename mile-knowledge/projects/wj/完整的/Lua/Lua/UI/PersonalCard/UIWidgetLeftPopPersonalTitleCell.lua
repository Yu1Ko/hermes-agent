-- ---------------------------------------------------------------------------------
-- Name: UIWidgetLeftPopPersonalTitleCell
-- Desc: 名片形象 - 称号选择 - cell
-- ---------------------------------------------------------------------------------

local UIWidgetLeftPopPersonalTitleCell = class("UIWidgetLeftPopPersonalTitleCell")

function UIWidgetLeftPopPersonalTitleCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetLeftPopPersonalTitleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLeftPopPersonalTitleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPersonalTitleVontent, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(self.tData)
        end
    end)
end

function UIWidgetLeftPopPersonalTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLeftPopPersonalTitleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLeftPopPersonalTitleCell:UpdateInfo(tData)
    if not tData then return end
    self.tData = tData
    UIHelper.SetVisible(self.Icon1, tData.bDisable)
    UIHelper.SetVisible(self.Icon2, tData.bTimeLimit)
    UIHelper.SetVisible(self.Icon3, tData.bIsEffect)
    UIHelper.LayoutDoLayout(self.LayoutIcon)

    UIHelper.SetString(self.LabelSelect, tData.szName)
    UIHelper.SetSpriteFrame(self.ImgQuality, PersonalTitleQualityBGColor[tData.nQuality + 1])
    -- self:RawSetSelected(tData.bEquip)
    UIHelper.SetVisible(self.ImgTips, tData.bEquip)
    UIHelper.SetVisible(self.ImgSelect, tData.bSel)
    -- UIHelper.SetVisible(self.ImgMask, not tData.bHave)
end

function UIWidgetLeftPopPersonalTitleCell:RawSetSelected(bSelected)
    UIHelper.SetSelected(self.TogPersonalTitleVontent, bSelected, false)
end

function UIWidgetLeftPopPersonalTitleCell:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

return UIWidgetLeftPopPersonalTitleCell