-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetCollectionBoxCell = class("UIWidgetCollectionBoxCell")

function UIWidgetCollectionBoxCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetCollectionBoxCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCollectionBoxCell:BindUIEvent()

end

function UIWidgetCollectionBoxCell:RegEvent()
   
end

function UIWidgetCollectionBoxCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCollectionBoxCell:SetName(szName)
    UIHelper.SetString(self.LabelNormal,szName)
    UIHelper.SetString(self.LabelSelect,szName)
end

function UIWidgetCollectionBoxCell:SetName(szName)
    UIHelper.SetString(self.LabelNormal,szName)
    UIHelper.SetString(self.LabelSelect,szName)
end

function UIWidgetCollectionBoxCell:SetSelectChangeCallback(fnCallBack)
    UIHelper.BindUIEvent(self.Toggle, EventType.OnSelectChanged, fnCallBack)
end

return UIWidgetCollectionBoxCell