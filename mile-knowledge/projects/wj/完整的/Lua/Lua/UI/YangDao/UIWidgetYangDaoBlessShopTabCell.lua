-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetYangDaoBlessShopTabCell
-- Date: 2026-02-28 16:44:14
-- Desc: 扬刀大会-祝福商店界面 Tab栏 WidgetYangDaoBlessShopTabCell (PanelYangDaoBlessShop)
-- ---------------------------------------------------------------------------------

local UIWidgetYangDaoBlessShopTabCell = class("UIWidgetYangDaoBlessShopTabCell")

function UIWidgetYangDaoBlessShopTabCell:OnEnter(szText, fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:SetText(szText)
    self:SetSelectedCallback(fnCallback)
end

function UIWidgetYangDaoBlessShopTabCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYangDaoBlessShopTabCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTabCell, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and self.fnCallback then
            self.fnCallback()
        end
    end)  
end

function UIWidgetYangDaoBlessShopTabCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetYangDaoBlessShopTabCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetYangDaoBlessShopTabCell:SetText(szText)
    UIHelper.SetString(self.LabelContent, szText)
    UIHelper.SetString(self.LabelContentUp, szText)
end

function UIWidgetYangDaoBlessShopTabCell:SetSelectedCallback(fnCallback)
    self.fnCallback = fnCallback
end

function UIWidgetYangDaoBlessShopTabCell:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.TogTabCell, bSelected, bCallback)
end

return UIWidgetYangDaoBlessShopTabCell