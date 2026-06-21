-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIManufactureFilter
-- Date: 2022-11-28 19:35:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIManufactureFilter = class("UIManufactureFilter")

function UIManufactureFilter:OnEnter(nIndexID)
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndexID = nIndexID
end

function UIManufactureFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIManufactureFilter:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetManufactureFilter, EventType.OnSelectChanged, function (_, bSelected)
        local bHasSelected = UIHelper.GetSelected(self.ToggleSelect)
        Event.Dispatch(EventType.OnManufactureTitleSelect, self.nIndexID, bSelected, bHasSelected)
    end) 
end

function UIManufactureFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIManufactureFilter:UpdateInfo()
    
end

function UIManufactureFilter:SetLabelTittle(value, color)
    UIHelper.SetString(self.LabelTittle, UIHelper.GBKToUTF8(value))
    UIHelper.SetString(self.LabelTittleSelected, UIHelper.GBKToUTF8(value))
    if color then
        UIHelper.SetColor(self.LabelTittle, color)
        UIHelper.SetColor(self.LabelTittleSelected, color)
    end
end

function UIManufactureFilter:SetVisible(value)
    UIHelper.SetVisible(self._rootNode, value)
end


return UIManufactureFilter